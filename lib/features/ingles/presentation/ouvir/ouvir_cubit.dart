import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/preferencias_ouvir.dart';
import '../../data/sessao_midia.dart';
import '../../domain/config_ouvir.dart';
import '../../domain/fila_ouvir.dart';
import '../../domain/saida_audio.dart';
import 'ouvir_state.dart';

/// Como terminou um passo do roteiro.
enum _FimPasso { ok, cortado, semSom, travou, saiu }

/// O motor do "🎧 Ouvir": toca a fila frase a frase (passos de [passosDa]), com pausa, pular,
/// repetir, timer e a sessão de mídia. Nunca toca sozinho: depois de recarregar fica `parado`.
///
/// Regras (FASE-8 §4.2):
/// - UM laço por [_token]: pausar/pular/fechar/tocar sobem o token e chamam `saida.parar()` antes — o
///   `cortada` que o próprio corte produz é ignorado (o laço velho vê o token trocado e sai).
/// - Cada passo corre contra um vigia (`segundos / v × 2,5 + 3 s`): estourou = para e pula a frase.
/// - `cortada` com o token vivo = outra fala do app entrou: `pausado` + [MotivoPausa.outraFala], e NUNCA
///   volta sozinho.
/// - 3 falas em inglês seguidas que "acabam" em menos de 150 ms = o som não está saindo:
///   `pausado` + [MotivoPausa.semSom].
/// - [continuar] sempre recomeça a frase atual do início.
class OuvirCubit extends Cubit<OuvirState> {
  final SaidaDeAudio saida;
  final PreferenciasOuvir? prefs;
  final SessaoMidia? midia;

  /// Espera injetável (testes) — o vigia de cada passo.
  final Future<void> Function(Duration) esperar;

  /// Relógio injetável (testes).
  final DateTime Function() agora;

  OuvirCubit({
    required this.saida,
    this.prefs,
    this.midia,
    this.esperar = _esperar,
    this.agora = DateTime.now,
  }) : super(const OuvirState()) {
    final p = prefs;
    if (p != null) {
      // a config salva entra quando a pref chega (se o aluno já mexeu, vale a dele)
      p.carregar().then((_) {
        if (!isClosed && !_configMexida && p.config != state.config) emit(state.copyWith(config: p.config));
      }, onError: (Object _) {});
    }
  }

  static Future<void> _esperar(Duration d) => Future<void>.delayed(d);

  /// null fora do curso de inglês.
  static OuvirCubit? de(BuildContext c) {
    try {
      return BlocProvider.of<OuvirCubit>(c, listen: false);
    } catch (_) {
      return null;
    }
  }

  /// Uma fala que "acaba" mais rápido que isto não saiu de verdade.
  static const instantanea = Duration(milliseconds: 150);

  /// Quantas instantâneas seguidas viram "sem som".
  static const maxInstantaneas = 3;

  /// Até quanto do começo da frase o ⏪ volta para a anterior.
  static const janelaAnterior = Duration(milliseconds: 1500);

  /// Salva a posição a cada tantas frases (e na pausa, ao fechar e na virada de lição).
  static const salvarACada = 5;

  int _token = 0;
  DateTime? _inicioFaixa;
  ({int indice, ConfigOuvir config})? _configDaFaixa;

  /// A config com que os passos da faixa [indice] foram fixados (a que está tocando "termina como começou",
  /// ver [configurar]). O 📺 usa para planejar o silêncio que toca de verdade, não o do chip trocado no meio.
  ({int indice, ConfigOuvir config})? get configDaFaixa => _configDaFaixa;
  int _instantaneas = 0;
  int _inicioInstantaneas = 0;
  int _desdeSalvo = 0;
  bool _configMexida = false;
  bool _acoesLigadas = false;
  Timer? _vigia;

  // ── tocar ───────────────────────────────────────────────────────────────

  /// Começa a tocar [fila] (de [fonte]) a partir de [inicio]. Volta logo depois de começar (o laço segue
  /// sozinho); fila vazia não faz nada.
  Future<void> tocar(FonteOuvir fonte, List<Faixa> fila, {int inicio = 0}) async {
    if (isClosed || fila.isEmpty) return;
    final t = _cortar();
    final i = inicio.clamp(0, fila.length - 1);
    _instantaneas = 0;
    _desdeSalvo = 0;
    _ligarAcoes();
    emit(state.copyWith(
      status: StatusOuvir.tocando,
      semMotivo: true,
      fonte: fonte,
      fila: List.unmodifiable(fila),
      indice: i,
      fase: FaseOuvir.ouvindo,
      vez: 1,
      de: 1,
      ouvidas: 0,
    ));
    unawaited(_rodar(t));
  }

  void pausar() {
    if (isClosed || state.status != StatusOuvir.tocando) return;
    _cortar();
    _pausa(MotivoPausa.usuario);
  }

  /// Recomeça a frase atual do início (de "acabou", volta ao começo da fila).
  Future<void> continuar() async {
    if (isClosed || state.fila.isEmpty || state.fonte == null) return;
    final t = _cortar();
    final doComeco = state.status == StatusOuvir.acabou;
    _instantaneas = 0;
    _ligarAcoes();
    emit(state.copyWith(
      status: StatusOuvir.tocando,
      semMotivo: true,
      indice: doComeco ? 0 : state.indice.clamp(0, state.fila.length - 1),
      ouvidas: doComeco ? 0 : null,
      fase: FaseOuvir.ouvindo,
    ));
    unawaited(_rodar(t));
  }

  void alternar() {
    if (state.status == StatusOuvir.tocando) {
      pausar();
    } else {
      unawaited(continuar());
    }
  }

  void proxima() {
    if (state.fila.isEmpty) return;
    final n = state.indice + 1;
    if (n < state.fila.length) return irPara(n);
    if (state.config.repetirTudo) return irPara(0);
    _cortar();
    _acabou();
  }

  /// Até 1,5 s do começo da frase volta para a anterior; depois, recomeça a atual.
  void anterior() {
    if (state.fila.isEmpty) return;
    irPara(_logoNoComeco() && state.indice > 0 ? state.indice - 1 : state.indice);
  }

  void repetirAtual() => irPara(state.indice);

  /// Toca a partir da frase [i] (pular, "Tocar daqui", a lista "A seguir").
  void irPara(int i) {
    if (isClosed || state.fila.isEmpty || state.fonte == null) return;
    final t = _cortar();
    _instantaneas = 0;
    _ligarAcoes();
    emit(state.copyWith(
      status: StatusOuvir.tocando,
      semMotivo: true,
      indice: i.clamp(0, state.fila.length - 1),
      fase: FaseOuvir.ouvindo,
    ));
    unawaited(_rodar(t));
  }

  void proximaLicao() {
    final fila = state.fila;
    if (fila.isEmpty) return;
    for (var j = state.indice + 1; j < fila.length; j++) {
      if (fila[j].primeiraDaLicao) return irPara(j);
    }
    // não há outra lição: como passar da última frase
    if (state.config.repetirTudo) return irPara(0);
    _cortar();
    _acabou();
  }

  /// No meio da lição, volta ao começo dela; na 1ª frase (até 1,5 s do começo), vai para a lição anterior.
  void licaoAnterior() {
    final fila = state.fila;
    if (fila.isEmpty) return;
    final inicio = _inicioDaLicao(state.indice);
    if (state.indice > inicio || !_logoNoComeco() || inicio == 0) return irPara(inicio);
    irPara(_inicioDaLicao(inicio - 1));
  }

  // ── ajustes ─────────────────────────────────────────────────────────────

  /// Vale a partir da próxima frase (a que está tocando termina como começou).
  void configurar(ConfigOuvir c) {
    if (isClosed) return;
    _configMexida = true;
    emit(state.copyWith(config: c));
    unawaited(prefs?.salvarConfig(c).catchError((Object _) {}));
  }

  void desligarEm(DesligarEm d) {
    if (isClosed) return;
    final minutos = switch (d) {
      DesligarEm.min15 => 15,
      DesligarEm.min30 => 30,
      DesligarEm.min60 => 60,
      DesligarEm.nunca || DesligarEm.fimDaLicao => 0,
    };
    emit(minutos > 0
        ? state.copyWith(desligar: d, desligaAs: agora().add(Duration(minutes: minutos)))
        : state.copyWith(desligar: d, semDesligaAs: true));
  }

  void telaCheia(bool aberta) {
    if (!isClosed) emit(state.copyWith(telaCheia: aberta));
  }

  /// Para e limpa a sessão; a posição salva fica.
  void fechar() {
    if (isClosed) return;
    // pausado/no fim, quem soa é outra voz do app (o palco, o arcade…): o ✕ não a corta
    _cortar(calar: state.status == StatusOuvir.tocando);
    // no fim o [_acabou] já salvou o 0 ("Continuar" recomeça do começo): não volta para a última frase
    if (state.status != StatusOuvir.acabou) _salvarPosicao(state.indice);
    midia?.limpar();
    _acoesLigadas = false;
    emit(OuvirState(config: state.config, telaCheia: state.telaCheia));
  }

  ({int i, String chave})? posicaoSalva(String fonteId) => prefs?.posicao(fonteId);

  @override
  Future<void> close() {
    _cortar(calar: state.status == StatusOuvir.tocando); // só cala a saída se o player é quem soa
    if (state.ativo && state.status != StatusOuvir.acabou) _salvarPosicao(state.indice);
    midia?.limpar();
    return super.close();
  }

  // ── o laço ──────────────────────────────────────────────────────────────

  /// Novo token (o laço velho sai) e cala a saída ([calar] = false: só o token — pausado não há laço, e o
  /// que soa é de outra voz). Devolve o token novo.
  int _cortar({bool calar = true}) {
    _vigia?.cancel();
    _vigia = null;
    final t = ++_token;
    if (calar) saida.parar();
    return t;
  }

  bool _vivo(int t) => t == _token && !isClosed;

  Future<void> _rodar(int t) async {
    while (_vivo(t)) {
      final fila = state.fila;
      final i = state.indice;
      if (i < 0 || i >= fila.length) return;
      final f = fila[i];
      final fimDeLicao = i + 1 >= fila.length || fila[i + 1].primeiraDaLicao;
      final r = await _tocarFaixa(t, f, i, fimDeLicao: fimDeLicao);
      if (!_vivo(t)) return;
      switch (r) {
        case _FimPasso.saiu:
          return;
        case _FimPasso.cortado:
          return _pausa(MotivoPausa.outraFala);
        case _FimPasso.semSom:
          emit(state.copyWith(indice: _inicioInstantaneas.clamp(0, fila.length - 1)));
          _instantaneas = 0;
          return _pausa(MotivoPausa.semSom);
        case _FimPasso.ok:
        case _FimPasso.travou:
          break;
      }
      // a frase acabou (ou travou e foi pulada)
      var proxima = i + 1;
      final viraLicao = proxima >= fila.length || fila[proxima].primeiraDaLicao;
      _desdeSalvo++;
      final ouvidas = state.ouvidas + 1;
      if (proxima >= fila.length) {
        if (!state.config.repetirTudo) {
          emit(state.copyWith(ouvidas: ouvidas));
          return _acabou();
        }
        proxima = 0;
      }
      if (_desdeSalvo >= salvarACada || viraLicao) _salvarPosicao(proxima);
      emit(state.copyWith(indice: proxima, ouvidas: ouvidas));
      // o timer só olha na virada de frase
      if (_timerVenceu(viraLicao)) {
        emit(state.copyWith(desligar: DesligarEm.nunca, semDesligaAs: true));
        return _pausa(MotivoPausa.timer);
      }
    }
  }

  bool _timerVenceu(bool viraLicao) => switch (state.desligar) {
        DesligarEm.nunca => false,
        DesligarEm.fimDaLicao => viraLicao,
        _ => state.desligaAs != null && !agora().isBefore(state.desligaAs!),
      };

  Future<_FimPasso> _tocarFaixa(int t, Faixa f, int i, {required bool fimDeLicao}) async {
    _inicioFaixa = agora();
    _atualizarMidia(f, tocando: true);
    // baixa as próximas enquanto esta toca
    final fila = state.fila;
    for (var j = i + 1; j <= i + 2 && j < fila.length; j++) {
      try {
        saida.preaquecer(fila[j].en);
      } catch (_) {}
    }
    final cfg = state.config;
    _configDaFaixa = (indice: i, config: cfg);
    final passos = passosDa(f, cfg, fimDeLicao: fimDeLicao);
    for (final p in passos) {
      if (!_vivo(t)) return _FimPasso.saiu;
      final r = await _passo(t, p, f, i);
      if (r != _FimPasso.ok) return r;
    }
    return _vivo(t) ? _FimPasso.ok : _FimPasso.saiu;
  }

  Future<_FimPasso> _passo(int t, PassoOuvir p, Faixa f, int i) async {
    final v = state.config.velocidade > 0 ? state.config.velocidade : 1.0;
    switch (p) {
      case FalaEn():
        emit(state.copyWith(fase: FaseOuvir.ouvindo, vez: p.vez, de: p.de));
        final seg = _segundosEn(f);
        final t0 = agora();
        final r = await _vigiado(t, () => saida.en(f.en, fator: p.fator), seg / p.fator,
            minimo: _temAudioDoAluno(f.en) ? vigiaAudioDoAluno : null);
        if (!_vivo(t)) return _FimPasso.saiu;
        if (r == null) return _travou();
        if (r == FimDaFala.cortada) return _FimPasso.cortado;
        if (agora().difference(t0) < instantanea || r == FimDaFala.semVoz) {
          if (_instantaneas == 0) _inicioInstantaneas = i;
          if (++_instantaneas >= maxInstantaneas) return _FimPasso.semSom;
        } else {
          _instantaneas = 0;
        }
        return _FimPasso.ok;
      case FalaPt():
        emit(state.copyWith(fase: FaseOuvir.traducao));
        final seg = _segundosPt(f) / v;
        FimDaFala? r;
        if (_ptMudo) {
          r = await _vigiado(t, () => saida.silencio(_dur(seg)), seg);
        } else {
          r = await _vigiado(t, () => saida.pt(f.pt, fator: v), seg);
          if (_vivo(t) && r == FimDaFala.semVoz) {
            // sem voz pt-BR: o tempo dela em silêncio (a tradução segue na tela)
            r = await _vigiado(t, () => saida.silencio(_dur(seg)), seg);
          }
        }
        if (!_vivo(t)) return _FimPasso.saiu;
        if (r == null) return _travou();
        if (r == FimDaFala.cortada) return _FimPasso.cortado;
        return _FimPasso.ok;
      case Silencio():
        emit(state.copyWith(fase: p.fase));
        final r = await _vigiado(t, () => saida.silencio(p.d), p.d.inMilliseconds / 1000);
        if (!_vivo(t)) return _FimPasso.saiu;
        if (r == null) return _travou();
        if (r == FimDaFala.cortada) return _FimPasso.cortado;
        return _FimPasso.ok;
    }
  }

  /// O vigia estourou: cala a saída e pula a frase.
  _FimPasso _travou() {
    saida.parar();
    _instantaneas = 0;
    return _FimPasso.travou;
  }

  /// O áudio que o aluno anexou à frase pode ser bem mais longo que a estimativa (e ainda baixar antes):
  /// o vigia dele dá no mínimo isto (a mesma rede de segurança do player nativo).
  static const vigiaAudioDoAluno = Duration(seconds: 30);

  bool _temAudioDoAluno(String en) {
    final s = saida;
    if (s is! SaidaComAudioDoAluno) return false;
    try {
      return (s as SaidaComAudioDoAluno).temAudioDoAluno(en);
    } catch (_) {
      return false;
    }
  }

  /// [fala] contra o vigia de `segundos × 2,5 + 3 s` (nunca menos que [minimo]); null = estourou.
  Future<FimDaFala?> _vigiado(int t, Future<FimDaFala> Function() fala, double segundos, {Duration? minimo}) async {
    var limite = _dur(segundos * 2.5 + 3);
    if (minimo != null && limite < minimo) limite = minimo;
    Future<FimDaFala> f;
    try {
      f = fala();
    } catch (_) {
      return FimDaFala.semVoz;
    }
    final r = await Future.any<FimDaFala?>([
      f.catchError((Object _) => FimDaFala.semVoz),
      _vigiar(limite).then((_) => null),
    ]);
    if (t == _token) {
      _vigia?.cancel();
      _vigia = null;
    }
    return r;
  }

  /// O padrão (`Future.delayed`) vira um Timer cancelável — não sobra timer pendurado entre os passos.
  Future<void> _vigiar(Duration d) {
    if (!identical(esperar, _esperar)) return esperar(d);
    _vigia?.cancel();
    final c = Completer<void>();
    _vigia = Timer(d, c.complete);
    return c.future;
  }

  static Duration _dur(double s) => Duration(milliseconds: (s * 1000).round());

  double _segundosEn(Faixa f) {
    if (f.segundos > 0) return f.segundos;
    try {
      return saida.duracaoDe(f.en);
    } catch (_) {
      return 3;
    }
  }

  /// O tempo da tradução na voz do sistema (~0,42 s por palavra, no mínimo 1 s).
  static double _segundosPt(Faixa f) {
    final palavras = f.pt.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).length;
    final s = palavras * .42;
    return s < 1 ? 1 : s;
  }

  /// No iPhone/iPad com a página escondida a voz do sistema não sai: o português vira silêncio.
  bool get _ptMudo => kIsWeb && defaultTargetPlatform == TargetPlatform.iOS && (midia?.oculta ?? false);

  bool _logoNoComeco() {
    final ini = _inicioFaixa;
    return ini != null && state.status == StatusOuvir.tocando && agora().difference(ini) < janelaAnterior;
  }

  int _inicioDaLicao(int i) {
    final fila = state.fila;
    for (var j = i.clamp(0, fila.length - 1); j > 0; j--) {
      if (fila[j].primeiraDaLicao) return j;
    }
    return 0;
  }

  void _pausa(MotivoPausa motivo) {
    if (isClosed) return;
    _salvarPosicao(state.indice);
    emit(state.copyWith(status: StatusOuvir.pausado, motivo: motivo));
    final f = state.atual;
    if (f != null) _atualizarMidia(f, tocando: false);
  }

  void _acabou() {
    if (isClosed) return;
    // "Continuar" depois do fim recomeça do começo
    if (state.fila.isNotEmpty) _salvarPosicao(0);
    emit(state.copyWith(status: StatusOuvir.acabou, semMotivo: true));
    final f = state.atual;
    if (f != null) _atualizarMidia(f, tocando: false);
  }

  void _salvarPosicao(int i) {
    final fonte = state.fonte;
    final fila = state.fila;
    if (fonte == null || fonte.id == 'avulso' || fila.isEmpty) return;
    final j = i.clamp(0, fila.length - 1);
    _desdeSalvo = 0;
    unawaited(prefs?.salvarPosicao(fonte.id, j, fila[j].chave).catchError((Object _) {}));
  }

  void _ligarAcoes() {
    final m = midia;
    if (m == null || _acoesLigadas) return;
    _acoesLigadas = true;
    try {
      m.acoes(
        play: () => unawaited(continuar()),
        pause: pausar,
        proxima: proxima,
        anterior: anterior,
        parar: fechar,
      );
      if (m is SessaoMidiaComRepetir) (m as SessaoMidiaComRepetir).aoRepetir(repetirAtual);
    } catch (_) {}
  }

  void _atualizarMidia(Faixa f, {required bool tocando}) {
    final m = midia;
    if (m == null) return;
    try {
      m.atualizar(
        titulo: f.en,
        artista: [f.quem, f.licaoNome].where((s) => s.isNotEmpty).join(' · '),
        album: 'Paclingo · ${state.fonte?.titulo ?? ''}',
        tocando: tocando,
      );
    } catch (_) {}
  }
}
