import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../arcade/domain/historia_turismo.dart';
import '../../../../arcade/domain/simulacao_historia.dart';
import '../../../../arcade/presentation/historia/roteiro_historia.dart' show EstadoRoteiro;
import '../../../../arcade/presentation/historia/roteiro_visivel.dart';
import '../../../data/voz_ingles.dart';
import '../../../domain/assistir/compasso_assistir.dart';
import '../../../domain/assistir/historia_licao.dart';
import '../../../domain/config_ouvir.dart';
import '../../../domain/fila_ouvir.dart';
import '../mini_player.dart' show escondeIngles, mostraTraducao;
import '../ouvir_state.dart';
import 'memoria_assistir.dart';

/// 📺 O roteiro que SEGUE o 🎧 Ouvir (D2): o `OuvirCubit` decide o que se fala e quando; o seguidor só
/// traduz a posição da fila (`indice`, `fase`, `vez`, `status`) em passo da historinha para o
/// [PalcoHistoria] desenhar. Sem voz própria e sem avançar sozinho (plano §3.3–3.5).
///
/// - `ouvindo` → a âncora da faixa (o balão; máquina de escrever só na vez 1, com as letras pela voz, I3);
/// - `traducao`/`pense` → o balão completo (PT forçado no inglês→português; "…" no português→inglês);
/// - vão final (`CompassoAssistir.ehVaoFinal`, só logo depois de uma FalaEn desta faixa) → o plano do vão: o
///   balão fica .25 s (no eco, 70% do vão) e os mudos animam no resto, acelerados ou saltando para o fim;
/// - pausa congela; timer e fim seguram o estado final da faixa anterior;
/// - [aoFalar]: uma `FalaEmCurso` NOVA da frase da âncora (o "R" sem emit) recomeça a âncora (I4).
///
/// O véu ([escurecimento]) só aparece num corte de verdade (troca de lição, de cena ou abertura no vão): repetir
/// a âncora não escurece (D18). Partida a frio (D17): ao nascer fora de `ouvindo` sem a FalaEn desta faixa na
/// [memoria], fica na âncora com o balão completo e sem mudos até a próxima FalaEn. Ao ser descartado
/// ([dispose], o "Tocando agora" minimizado), guarda um retrato junto da [memoria]; o seguidor seguinte da
/// mesma faixa continua do mesmo passo.
class RoteiroSeguidor extends ChangeNotifier implements RoteiroVisivel {
  RoteiroSeguidor({
    required this.historiaDe,
    required this.memoria,
    bool reduzir = false,
    DateTime Function()? agora,
    this.configDaFaixa,
  })  : _reduzir = reduzir,
        agora = agora ?? DateTime.now;

  /// A história da faixa (null = sem desenho, D14). Pedida só numa faixa nova (e para a próxima, no vão):
  /// nunca troca no meio de uma faixa.
  final HistoriaLicao? Function(Faixa f) historiaDe;

  /// A memória do 📺 junto do cubit (D17), lida ao nascer.
  final MemoriaAssistir memoria;

  /// O relógio da voz (as letras pela posição da `FalaEmCurso`); trocável nos testes.
  final DateTime Function() agora;

  /// A config com que o cubit fixou os passos da faixa [indice] (`OuvirCubit.configDaFaixa`): o chip trocado
  /// no meio da faixa só vale a partir da próxima, e o vão, o `ehVaoFinal` e a velocidade das letras seguem os
  /// passos que tocam de verdade. null (ou sem retrato desta faixa) = a config do estado.
  final ConfigOuvir? Function(int indice)? configDaFaixa;

  /// Depois de um passo novo, quanto tempo além da ação dele ainda se repinta a cada tique (s): a fala que
  /// abre, o efeito e a câmera (o resto anda no relógio de 30 fps do palco).
  static const margemDeAnimacao = .4;

  /// Quanto o balão espera antes de os mudos começarem num vão comum (o balão "fecha").
  static const fechaBalao = .25;

  /// O esmaecer de um corte (s).
  static const duracaoCorte = .45;

  /// Sem `FalaEmCurso` da frase até aqui (s), as letras andam na velocidade do nível.
  static const esperaDaVoz = .6;

  static final _retratos = Expando<_Retrato>('RoteiroSeguidor');

  bool _reduzir;
  bool _nasceu = false, _descartado = false;

  // ── o Ouvir
  OuvirState? _estado;
  StatusOuvir _status = StatusOuvir.parado;
  int _indice = -1;
  String? _chave;
  Faixa? _faixa;

  /// A história e a âncora da faixa ACEITA ([_indice]).
  HistoriaLicao? _historiaDaFaixa;
  (int, int)? _ancora;

  /// A história pedida no vão para a próxima faixa (a mesma vale quando ela chegar).
  ({int indice, String chave, HistoriaLicao? historia})? _proxima;

  // ── o que o palco mostra
  HistoriaLicao? _h;
  List<List<EstadoCena>> _linhas = const [];
  int _cena = 0, _passo = 0;

  /// Só o estado `linha[passo]` (sem fala nem animação): abertura sem mudos, estado final de um vão saltado.
  bool _estatico = false;
  double _tPasso = 0;
  double? _tCorte;
  bool _mostrouAlgo = false;

  /// Até que `tPasso` o passo na tela ainda anima a cada tique (a ação, as reações, o balão abrindo).
  double _animacao = 0;

  /// Muda a cada [_mostrar] (o [tick] só notifica quando algo visível mudou).
  int _trocas = 0;

  // ── o texto da âncora
  bool _digitando = false;
  int _letras = 0;
  double _fatorFala = 1;
  FalaEmCurso? _ultimaFc, _fcAncora;
  bool _mostrarPt = false, _esconderEn = false, _pense = false;

  /// Partida a frio: sem mudos até a próxima FalaEn.
  bool _frio = false;

  _PlanoDoVao? _plano;

  // ───────────────────────── entradas

  /// A cada emit do OuvirCubit (também o 1º, com o estado atual: o PalcoAssistir chama no initState,
  /// porque o BlocListener não dispara para o estado inicial). Ao nascer, lê a [memoria]; sem memória
  /// da faixa e fora de `ouvindo` → partida a frio (âncora, balão completo, sem mudos até a próxima FalaEn).
  void aoEstado(OuvirState st) {
    if (_descartado) return;
    memoria.registrar(st); // idempotente: o mesmo que o stream já entregou (e o teste sem cubit)
    final primeiro = !_nasceu;
    _nasceu = true;
    if (primeiro && _restaurar(st) && st == _estado) {
      notifyListeners();
      return;
    }
    final anterior = _estado;
    _estado = st;
    _status = st.status;
    final f = st.atual;
    if (f == null) {
      _indice = st.indice;
      _chave = null;
      _faixa = null;
      _historiaDaFaixa = null;
      _ancora = null;
      _h = null;
      _plano = null;
      _digitando = false;
      notifyListeners();
      return;
    }
    final faixaNova = st.indice != _indice || f.chave != _chave;
    switch (st.status) {
      case StatusOuvir.acabou:
        if (faixaNova && !_mostrouAlgo) _aceitarFaixa(st);
        _completarPlano();
        _fecharTexto();
        _tCorte = null;
      case StatusOuvir.pausado || StatusOuvir.parado:
        if (faixaNova && !_mostrouAlgo) {
          // nasceu já pausado: a âncora (no timer, o estado de logo antes dela: a frase ainda não foi dita)
          _aceitarFaixa(st, semFala: st.motivo == MotivoPausa.timer);
          if (st.motivo != MotivoPausa.timer) _flagsDeTexto(st);
          _fecharTexto();
        } else if (faixaNova) {
          // o índice andou e o Ouvir pausou (timer, "fim da lição", sem som): segura o estado final da faixa
          // anterior, sem abrir o balão de uma frase que ainda não foi dita (P8). Se o vão já abriu a próxima
          // (o timer venceu no meio do silêncio, ou o "fim da lição" foi escolhido depois do vão começar),
          // volta ao fim desta faixa.
          _segurarFimDaFaixa();
          _fecharTexto();
        } else {
          _flagsDeTexto(st);
          if (_digitando) _fecharTexto();
        }
        // o esmaecer de um corte não sobrevive à pausa: no ⏯ (mesmo passo, sem corte novo) não volta a piscar
        _tCorte = null;
      case StatusOuvir.tocando:
        if (faixaNova) {
          // a virada natural de faixa emite o índice novo ainda com a fase do silêncio anterior (e o `vez`
          // velho): espera a FalaEn (ou a pausa do timer) sem mexer no palco
          final transitorio = !primeiro &&
              (st.fase == FaseOuvir.respiro || st.fase == FaseOuvir.suaVez) &&
              memoria.ultimaFalaEnIndice != st.indice;
          if (transitorio) {
            notifyListeners();
            return;
          }
          _aceitarFaixa(st);
          _frio = primeiro && st.fase != FaseOuvir.ouvindo && memoria.ultimaFalaEnIndice != st.indice;
        }
        final mudouPasso = faixaNova ||
            anterior == null ||
            anterior.status != st.status ||
            anterior.fase != st.fase ||
            anterior.vez != st.vez ||
            anterior.de != st.de ||
            !identical(anterior.fila, st.fila);
        _flagsDeTexto(st);
        if (mudouPasso) {
          _aplicarFase(st, primeiro: primeiro);
        } else if (anterior.desligar != st.desligar || anterior.desligaAs != st.desligaAs) {
          // o "Desligar em" mudou no meio do vão: se agora pausa nesta virada, não abre a próxima lição
          final p = _plano;
          if (p != null && _timerVaiPausar(st, p.fimDoVao, fimDeLicao: p.fimDeLicao)) _segurarFimDaFaixa(manterRabo: true);
        }
    }
    notifyListeners();
  }

  /// A cada mudança de VozIngles.falando: FalaEmCurso nova (!identical) da âncora = reancorar (I4);
  /// também alimenta as letras pela voz (I3).
  void aoFalar(FalaEmCurso? fc) {
    if (_descartado || identical(fc, _ultimaFc)) return;
    _ultimaFc = fc;
    final en = _enDaAncora;
    final st = _estado;
    if (fc != null && en != null && fc.frase == en && _status == StatusOuvir.tocando && st?.fase == FaseOuvir.ouvindo) {
      if (_fcAncora == null && !_estatico && _plano == null && _naAncora) {
        _fcAncora = fc; // a voz desta passada começou
      } else {
        // a mesma frase anunciada de novo sem emit do cubit (o "R" na vez 1 de 1): recomeça a âncora
        _reancorar(digitar: st!.vez <= 1);
        _fcAncora = fc;
      }
    } else if (_fcAncora != null && (fc == null || fc.frase != en)) {
      // a voz da âncora acabou: o texto completa
      if (_digitando) _fecharTexto();
    }
    notifyListeners();
  }

  /// A última fala da voz que o seguidor viu.
  @visibleForTesting
  FalaEmCurso? get ultimaFala => _ultimaFc;

  /// O relógio do PalcoAssistir. Pausado (ou no fim), nada anda.
  ///
  /// Só notifica quando algo visível muda: o esmaecer, um passo novo, as letras, ou o passo ainda animando
  /// ([_animacao]). Parado (o balão lido, o eco "Sua vez"), o idle anda só pelo relógio de 30 fps do palco.
  void tick(double dt) {
    if (_descartado || dt <= 0 || _h == null || _status != StatusOuvir.tocando) return;
    var mudou = false;
    final c = _tCorte;
    if (c != null) {
      _tCorte = c + dt >= duracaoCorte ? null : c + dt;
      mudou = true;
    }
    final trocas = _trocas;
    final tAntes = _tPasso;
    final p = _plano;
    if (p != null) {
      _andarPlano(p, dt);
    } else {
      _tPasso += dt;
    }
    if (_digitando) {
      final letras = _letras;
      _atualizarLetras();
      if (_letras != letras || !_digitando) mudou = true;
    }
    // o passo ainda anima (também o 1º quadro depois de a ação acabar, para fechar na pose final)
    if (trocas != _trocas || (tAntes < _animacao && tAntes != _tPasso)) mudou = true;
    if (mudou) notifyListeners();
  }

  /// A história da faixa atual (aceita); null = a faixa não tem desenho (D14). No vão, o palco já pode estar
  /// mostrando a abertura da próxima ([historiaNaTela]).
  HistoriaLicao? get historia => _faixa == null ? null : _historiaDaFaixa;

  /// O Ticker só precisa andar com isto true (tocando com desenho; esmaecer e mudos só andam tocando).
  bool get precisaDeRelogio => !_descartado && _status == StatusOuvir.tocando && _h != null;

  bool get reduzir => _reduzir;
  set reduzir(bool v) {
    if (v == _reduzir) return;
    _reduzir = v;
    if (v) {
      _tCorte = null;
      if (_digitando) _fecharTexto();
      final p = _plano;
      if (p != null && p.atual >= 0) _completarPlano();
    }
    notifyListeners();
  }

  /// Há um plano de vão (mudos) em curso.
  @visibleForTesting
  bool get noVao => _plano != null;

  /// Partida a frio em vigor (sem mudos até a próxima FalaEn).
  @visibleForTesting
  bool get frio => _frio;

  /// Só o estado de um passo, sem fala (abertura sem mudos / fim de um vão saltado).
  @visibleForTesting
  bool get estatico => _estatico;

  /// A história que o palco mostra agora (no vão pode já ser a da próxima lição).
  @visibleForTesting
  HistoriaLicao? get historiaNaTela => _h;

  @override
  void dispose() {
    if (!_descartado && _nasceu) _retratos[memoria] = _Retrato.de(this);
    _descartado = true;
    super.dispose();
  }

  // ───────────────────────── a faixa

  bool get _naAncora {
    final a = _ancora;
    return a != null && !_estatico && identical(_h, _historiaDaFaixa) && a.$1 == _cena && a.$2 == _passo;
  }

  String? get _enDaAncora {
    final h = _historiaDaFaixa, a = _ancora;
    if (h == null || a == null) return null;
    return h.cenas[a.$1].falas[a.$2].en;
  }

  /// A história de uma faixa: a pedida no vão para ela (a decisão fica), senão [historiaDe]; a mesma lição com
  /// o mesmo tipo (autoral/automática) reaproveita o objeto já na tela (sem corte à toa).
  HistoriaLicao? _historiaPara(int indice, Faixa f) {
    final px = _proxima;
    HistoriaLicao? h;
    if (px != null && px.indice == indice && px.chave == f.chave) {
      h = px.historia;
    } else {
      h = historiaDe(f);
    }
    final atual = _h;
    if (h != null &&
        atual != null &&
        !identical(h, atual) &&
        h.licaoId == atual.licaoId &&
        h.autoral == atual.autoral &&
        atual.ancoras.containsKey(f.chave)) {
      return atual;
    }
    return h;
  }

  /// Aceita a faixa do [st] como a atual e vai para a âncora dela (corte se a história ou a cena mudam).
  void _aceitarFaixa(OuvirState st, {bool semFala = false}) {
    final f = st.atual!;
    _indice = st.indice;
    _chave = f.chave;
    _faixa = f;
    _plano = null;
    _frio = false;
    final h = _historiaPara(st.indice, f);
    _proxima = null;
    _historiaDaFaixa = h;
    if (h == null) {
      _ancora = null;
      _h = null;
      _linhas = const [];
      _digitando = false;
      return;
    }
    final a = h.ancoras[f.chave];
    _ancora = a;
    if (a == null || a.$1 >= h.cenas.length) {
      // a frase não está nesta história (o serviço já cai na automática; aqui, só por segurança)
      _mostrar(h, 0, 0, estatico: true);
    } else {
      _mostrar(h, a.$1, a.$2, estatico: semFala);
    }
    _digitando = false;
    _letras = semFala ? 0 : _totalLetras;
    _fcAncora = null;
  }

  /// Põe na tela o passo ([cena], [passo]) de [h]; corte (esmaecer) se a história ou a cena mudam.
  void _mostrar(HistoriaLicao h, int cena, int passo, {required bool estatico, bool corte = false}) {
    final mudou = _mostrouAlgo && _h != null && (!identical(h, _h) || cena != _cena);
    if (!identical(h, _h)) {
      _h = h;
      _linhas = [for (final c in h.cenas) SimulacaoCena.linhaDoTempo(c)];
    }
    _cena = cena.clamp(0, math.max(0, h.cenas.length - 1));
    _passo = passo;
    _estatico = estatico;
    _tPasso = 0;
    if ((mudou || corte) && !_reduzir) _tCorte = 0;
    _mostrouAlgo = true;
    _trocas++;
    final falas = h.cenas.isEmpty ? const <FalaHistoria>[] : h.cenas[_cena].falas;
    final f = estatico || passo < 0 || passo >= falas.length ? null : falas[passo];
    // o efeito some em 2,6 s (palco_historia); a ação/reação/objeto, pela conta dos mudos
    _animacao = (f == null ? 0.0 : math.max(CompassoAssistir.duracaoMuda(f), 2.6)) + margemDeAnimacao;
  }

  /// O EN do balão, o PT e o "…" (português → inglês) pelo estado do Ouvir.
  void _flagsDeTexto(OuvirState st) {
    final f = st.atual;
    if (f == null) return;
    final temPt = f.pt.trim().isNotEmpty;
    final modo = temPt ? st.config.modo : ModoOuvir.soIngles;
    final tocando = st.status == StatusOuvir.tocando;
    _esconderEn = temPt && escondeIngles(st);
    _pense = _esconderEn && st.fase == FaseOuvir.pense;
    _mostrarPt = mostraTraducao(f, st.config) ||
        (temPt &&
            modo == ModoOuvir.inglesPortugues &&
            ((tocando && st.fase == FaseOuvir.traducao) || memoria.viuTraducao(st.indice)));
  }

  /// A config dos passos que tocam nesta faixa ([configDaFaixa]); sem ela, a do estado.
  ConfigOuvir _configDe(OuvirState st) => configDaFaixa?.call(st.indice) ?? st.config;

  /// O que a fase do Ouvir pede (a faixa já aceita).
  void _aplicarFase(OuvirState st, {required bool primeiro}) {
    if (_historiaDaFaixa == null) return;
    final f = st.atual!;
    final temPt = f.pt.trim().isNotEmpty;
    final cfg = _configDe(st);
    final modo = temPt ? cfg.modo : ModoOuvir.soIngles;
    switch (st.fase) {
      case FaseOuvir.ouvindo:
        _frio = false;
        final v = cfg.velocidade > 0 ? cfg.velocidade : 1.0;
        _fatorFala = st.vez >= 2 && cfg.segundaDevagar ? v * fatorDevagar : v;
        _reancorar(digitar: st.vez <= 1);
      case FaseOuvir.traducao:
        if (modo == ModoOuvir.portuguesIngles) {
          // a FalaPt do português→inglês começa a passada da frase: volta à âncora
          _reancorar(digitar: false);
        } else {
          _garantirAncora();
          _fecharTexto();
        }
      case FaseOuvir.pense:
        _garantirAncora();
        _fecharTexto();
      case FaseOuvir.respiro || FaseOuvir.suaVez:
        final depoisDaFalaEn = memoria.ultimaFalaEnIndice == st.indice;
        final fim = depoisDaFalaEn &&
            CompassoAssistir.ehVaoFinal(
              fase: st.fase,
              vez: st.vez,
              de: st.de,
              modo: cfg.modo,
              viuTraducao: memoria.viuTraducao(st.indice),
              temPt: temPt,
            );
        if (!fim || _frio) {
          _garantirAncora();
          _fecharTexto();
        } else {
          _fecharTexto();
          _comecarVao(st);
          // nasceu no meio do vão (com memória, sem retrato): não sabe quanto já passou — o estado final
          if (primeiro) _completarPlano();
        }
    }
  }

  /// Volta à âncora com o tempo zerado (a ação recomeça); [digitar] = máquina de escrever (vez 1).
  void _reancorar({required bool digitar}) {
    final a = _ancora, h = _historiaDaFaixa;
    if (a == null || h == null || a.$1 >= h.cenas.length) return;
    _plano = null;
    _mostrar(h, a.$1, a.$2, estatico: false);
    _fcAncora = null;
    _letras = 0;
    _digitando = digitar && !_reduzir && _totalLetras > 0;
    if (!_digitando) _letras = _totalLetras;
    // a voz desta frase já começou (o anúncio chegou antes do emit): as letras seguem ela
    final u = _ultimaFc;
    if (_digitando && u != null && u.frase == _enDaAncora && agora().difference(u.inicio) < _vozRecente) {
      _fcAncora = u;
    }
  }

  static const _vozRecente = Duration(milliseconds: 1500);

  /// Na âncora (sem zerar o tempo se já está nela).
  void _garantirAncora() {
    if (_naAncora && _plano == null) return;
    final a = _ancora, h = _historiaDaFaixa;
    if (a == null || h == null || a.$1 >= h.cenas.length) return;
    _plano = null;
    _mostrar(h, a.$1, a.$2, estatico: false);
    _fcAncora = null;
    _digitando = false;
    _letras = _totalLetras;
  }

  int get _totalLetras {
    final h = _historiaDaFaixa, a = _ancora;
    if (h == null || a == null || a.$1 >= h.cenas.length) return 0;
    return h.cenas[a.$1].falas[a.$2].en?.length ?? 0;
  }

  void _fecharTexto() {
    _digitando = false;
    _letras = _totalLetras;
  }

  /// As letras da vez 1: pela posição da voz (I3) ou, sem voz por [esperaDaVoz], pela velocidade do nível.
  void _atualizarLetras() {
    final total = _totalLetras;
    final h = _historiaDaFaixa;
    if (!_naAncora || h == null) return;
    final fc = _fcAncora;
    int n;
    final lps = CompassoAssistir.letrasPorSegundo(h.nivel, _fatorFala);
    if (fc != null) {
      final s = fc.segundo(agora());
      final seg = _faixa?.segundos ?? 0;
      n = CompassoAssistir.letrasPelaVoz(
            total: total,
            segundoDaVoz: s,
            segundosDaFaixa: seg > 0 ? seg : null,
            // a gravação já conta no tempo do mp3; a voz sintética, no relógio
            fator: fc.gravacao ? 1 : _fatorFala,
          ) ??
          (agora().difference(fc.inicio).inMicroseconds / 1e6 * lps).floor();
    } else if (_tPasso >= esperaDaVoz) {
      n = ((_tPasso - esperaDaVoz) * lps).floor();
    } else {
      n = 0;
    }
    n = n.clamp(0, total);
    if (n > _letras) _letras = n;
    if (_letras >= total) _digitando = false;
  }

  // ───────────────────────── o vão

  void _comecarVao(OuvirState st) {
    final h = _historiaDaFaixa, a = _ancora, f = st.atual;
    if (h == null || a == null || f == null || a.$1 >= h.cenas.length) return;
    final fila = st.fila;
    final i = st.indice;
    final fimDeLicao = i + 1 >= fila.length || fila[i + 1].primeiraDaLicao;
    final cfg = _configDe(st);
    final vao = CompassoAssistir.vaoFinal(f, cfg, fimDeLicao: fimDeLicao);
    // o cubit confere o timer na virada, DEPOIS do silêncio: conta o fim do vão
    final fimDoVao = agora().add(Duration(microseconds: (vao * 1e6).round()));
    // o "Desligar em" vai pausar nesta virada: o palco fica no estado final desta lição (P8), sem abrir a próxima
    final timerVaiPausar = _timerVaiPausar(st, fimDoVao, fimDeLicao: fimDeLicao);
    final j = timerVaiPausar
        ? null
        : (i + 1 < fila.length ? i + 1 : (st.config.repetirTudo && fila.isNotEmpty ? 0 : null));
    HistoriaLicao? hp;
    (int, int)? ap;
    if (j != null) {
      final fj = fila[j];
      hp = _historiaPara(j, fj);
      ap = hp?.ancoras[fj.chave];
      _proxima = (indice: j, chave: fj.chave, historia: hp);
    }
    final eco = st.fase == FaseOuvir.suaVez;
    final inicio = eco ? vao * CompassoAssistir.fracaoDoEco : math.min(fechaBalao, vao * .5);
    final util = math.max(0.0, vao - inicio);
    final trechos = CompassoAssistir.planoDoVao(
      atual: h,
      ancoraAtual: a,
      proxima: hp,
      ancoraProxima: ap,
      vao: util,
    );
    final passos = <_PassoDoVao>[];
    for (final t in trechos) {
      if (t.passos.isEmpty) {
        final d = t.destino;
        if (t.abreCena && d != null) {
          passos.add(_PassoDoVao(t.historia, d.$1, d.$2, corte: true, estatico: true, duracao: 0, abertura: true));
        }
        continue;
      }
      for (var k = 0; k < t.passos.length; k++) {
        final (c, p) = t.passos[k];
        passos.add(_PassoDoVao(
          t.historia,
          c,
          p,
          corte: t.abreCena && k == 0,
          estatico: false,
          duracao: CompassoAssistir.duracaoMuda(t.historia.cenas[c].falas[p]),
          abertura: t.destino != null,
        ));
      }
    }
    if (passos.isEmpty) {
      _plano = null; // nada a animar: o balão fica até a próxima faixa
      return;
    }
    final duracoes = [for (final p in passos) if (!p.estatico) p.duracao];
    _plano = _PlanoDoVao(passos, inicio, CompassoAssistir.fatorDeTempo(duracoes, util),
        fimDoVao: fimDoVao, fimDeLicao: fimDeLicao);
  }

  /// O Ouvir vai pausar na virada que acontece em [fimDoVao]? (a mesma conta do `_timerVenceu` do cubit)
  static bool _timerVaiPausar(OuvirState st, DateTime fimDoVao, {required bool fimDeLicao}) {
    final desligaAs = st.desligaAs;
    return (st.desligar == DesligarEm.fimDaLicao && fimDeLicao) ||
        (st.desligar != DesligarEm.nunca &&
            st.desligar != DesligarEm.fimDaLicao &&
            desligaAs != null &&
            !fimDoVao.isBefore(desligaAs));
  }

  /// Segura o fim DESTA faixa (P8): o plano perde a abertura do que vem depois (a próxima âncora, outra cena ou
  /// outra lição). Se ela já está na tela, volta ao estado depois do rabo (ou à âncora, com o balão de uma frase
  /// que já foi dita). [manterRabo] = ainda tocando: o rabo que falta continua animando.
  void _segurarFimDaFaixa({bool manterRabo = false}) {
    final p = _plano;
    if (p == null) return;
    final rabo = [for (final x in p.passos) if (!x.abertura) x];
    if (rabo.length == p.passos.length) {
      if (!manterRabo) _completarPlano();
      return;
    }
    final jaAbriu = p.atual >= rabo.length;
    if (manterRabo && !jaAbriu) {
      if (rabo.isEmpty) {
        _plano = null; // nada a animar: o balão fica até a virada
        return;
      }
      _plano = _PlanoDoVao(rabo, p.inicio, p.fator, fimDoVao: p.fimDoVao, fimDeLicao: p.fimDeLicao)
        ..t = p.t
        ..atual = p.atual
        ..saltou = p.saltou && p.atual >= rabo.length - 1;
      return;
    }
    _plano = null;
    if (rabo.isEmpty) {
      _garantirAncora();
    } else {
      final x = rabo.last;
      _mostrar(x.historia, x.cena, x.estatico ? x.passo : x.passo + 1, estatico: true);
      _digitando = false;
    }
  }

  void _andarPlano(_PlanoDoVao p, double dt) {
    p.t += dt;
    if (p.t < p.inicio) {
      if (p.atual < 0) _tPasso += dt; // o balão ainda na tela
      return;
    }
    if (_reduzir || p.fator.isInfinite) {
      if (!p.saltou) _saltarParaOFim(p);
      return;
    }
    final e = p.t - p.inicio;
    final escala = math.max(1.0, p.fator);
    var acc = 0.0;
    var k = p.passos.length - 1;
    var local = 0.0;
    for (var i = 0; i < p.passos.length; i++) {
      final d = p.passos[i].estatico ? 0.0 : p.passos[i].duracao / escala;
      if (e < acc + d || i == p.passos.length - 1) {
        k = i;
        local = e - acc;
        break;
      }
      acc += d;
    }
    if (k != p.atual) {
      // os cortes dos passos pulados (vários num tique só) também contam
      var corte = false;
      for (var i = p.atual + 1; i <= k; i++) {
        corte = corte || p.passos[i].corte;
      }
      final x = p.passos[k];
      _mostrar(x.historia, x.cena, x.passo, estatico: x.estatico, corte: corte);
      p.atual = k;
      _digitando = false;
    }
    _tPasso = math.max(0.0, local) * escala;
  }

  /// O estado final do plano, sem animação (vão curto demais, reduzir, timer, fim, retomada no meio).
  void _saltarParaOFim(_PlanoDoVao p) {
    if (p.passos.isEmpty) return;
    final corte = p.passos.skip(p.atual + 1).any((x) => x.corte);
    final x = p.passos.last;
    final passo = x.estatico ? x.passo : x.passo + 1; // o estado DEPOIS do último mudo
    _mostrar(x.historia, x.cena, passo, estatico: true, corte: corte);
    p.atual = p.passos.length - 1;
    p.saltou = true;
    _digitando = false;
  }

  void _completarPlano() {
    final p = _plano;
    if (p == null) return;
    if (!p.saltou) _saltarParaOFim(p);
    _plano = null;
  }

  // ───────────────────────── retrato (minimizar e reabrir)

  bool _restaurar(OuvirState st) {
    final r = _retratos[memoria];
    final f = st.atual;
    if (r == null || f == null || r.indice != st.indice || r.chave != f.chave) return false;
    _retratos[memoria] = null;
    r.aplicar(this);
    return true;
  }

  // ───────────────────────── RoteiroVisivel

  List<EstadoCena> get _linha => _linhas.isEmpty ? const [] : _linhas[_cena.clamp(0, _linhas.length - 1)];

  static EstadoCena _vazio() => EstadoCena(
        cenario: CenarioHistoria.casa,
        hora: HoraHistoria.dia,
        clima: [],
        atores: {},
        objetos: [],
      );

  FalaHistoria? get _fala {
    final h = _h;
    if (h == null || _estatico || _cena >= h.cenas.length) return null;
    final falas = h.cenas[_cena].falas;
    return _passo >= 0 && _passo < falas.length ? falas[_passo] : null;
  }

  @override
  EstadoRoteiro get estadoVisivel {
    final f = _fala;
    if (f == null || f.mudo) return EstadoRoteiro.entrando;
    return _digitando ? EstadoRoteiro.falando : EstadoRoteiro.lendo;
  }

  @override
  FalaHistoria? get falaAtual => _fala;

  @override
  FalaHistoria? get falaAnterior {
    final h = _h;
    if (h == null || _estatico || _cena >= h.cenas.length || _passo <= 0) return null;
    final falas = h.cenas[_cena].falas;
    return _passo - 1 < falas.length ? falas[_passo - 1] : null;
  }

  @override
  EstadoCena get antes {
    final l = _linha;
    return l.isEmpty ? _vazio() : l[_passo.clamp(0, l.length - 1)];
  }

  @override
  EstadoCena get depois {
    final l = _linha;
    if (l.isEmpty) return _vazio();
    return l[(_estatico ? _passo : _passo + 1).clamp(0, l.length - 1)];
  }

  @override
  int get cena => _cena;

  @override
  int get passo => _passo;

  @override
  double get tPasso => _tPasso;

  @override
  double? get tFala {
    final f = _fala;
    return f == null || f.mudo ? null : _tPasso;
  }

  @override
  double? get tSaida => null;

  @override
  int get letrasVisiveis {
    final f = _fala;
    if (f == null || f.mudo) return 0;
    final total = f.en?.length ?? 0;
    return _naAncora ? _letras.clamp(0, total) : total;
  }

  @override
  bool get mostrarPt => _mostrarPt;

  @override
  bool get noTitulo => false;

  @override
  double get duracaoTituloAtual => 0;

  @override
  bool get falaComVoz => true;

  @override
  bool get esconderEn => _esconderEn && _naAncora;

  @override
  String? get iconeDaFala {
    if (!_naAncora) return null;
    if (_pense) return '🤔';
    final f = _faixa;
    if (f == null) return null;
    if (f.quem == 'placa') return '🪧';
    final i = f.imagem.trim();
    return i.isEmpty ? null : i;
  }

  @override
  double get escurecimento {
    final c = _tCorte;
    if (c == null || _reduzir || _status != StatusOuvir.tocando) return 0;
    return (1 - c / duracaoCorte).clamp(0.0, 1.0);
  }
}

/// Um passo do plano do vão, já resolvido.
class _PassoDoVao {
  final HistoriaLicao historia;
  final int cena, passo;

  /// Corta (esmaecer) ao começar: a 1ª coisa de uma abertura.
  final bool corte;

  /// Abertura sem mudos: só o estado de logo antes da âncora [passo].
  final bool estatico;

  /// Segundos a 1× (0 no estático).
  final double duracao;

  /// Leva à próxima âncora (abertura de cena/lição), não é o rabo desta faixa.
  final bool abertura;

  const _PassoDoVao(this.historia, this.cena, this.passo,
      {required this.corte, required this.estatico, required this.duracao, this.abertura = false});
}

/// O plano de um vão em curso.
class _PlanoDoVao {
  _PlanoDoVao(this.passos, this.inicio, this.fator, {required this.fimDoVao, required this.fimDeLicao});

  /// Quando o silêncio acaba (a virada em que o cubit confere o "Desligar em").
  final DateTime fimDoVao;

  /// O vão é o do fim de uma lição.
  final bool fimDeLicao;

  final List<_PassoDoVao> passos;

  /// Segundos do vão em que os mudos começam (até aqui, o balão fica).
  final double inicio;

  /// `CompassoAssistir.fatorDeTempo`: ≤ 1 tempo real; > 1 acelera; infinity salta para o fim.
  final double fator;

  /// Segundos desde o começo do vão.
  double t = 0;

  /// O passo do plano na tela (-1 = ainda a âncora).
  int atual = -1;
  bool saltou = false;
}

/// O que o seguidor descartado deixa para o próximo da mesma faixa (minimizar e reabrir, D17).
class _Retrato {
  _Retrato.de(RoteiroSeguidor s)
      : estado = s._estado,
        indice = s._indice,
        chave = s._chave,
        faixa = s._faixa,
        historiaDaFaixa = s._historiaDaFaixa,
        ancora = s._ancora,
        proxima = s._proxima,
        h = s._h,
        linhas = s._linhas,
        cena = s._cena,
        passo = s._passo,
        estatico = s._estatico,
        tPasso = s._tPasso,
        animacao = s._animacao,
        mostrouAlgo = s._mostrouAlgo,
        letras = s._letras,
        fatorFala = s._fatorFala,
        mostrarPt = s._mostrarPt,
        esconderEn = s._esconderEn,
        pense = s._pense,
        frio = s._frio,
        plano = s._plano;

  final OuvirState? estado;
  final int indice;
  final String? chave;
  final Faixa? faixa;
  final HistoriaLicao? historiaDaFaixa, h;
  final (int, int)? ancora;
  final ({int indice, String chave, HistoriaLicao? historia})? proxima;
  final List<List<EstadoCena>> linhas;
  final int cena, passo, letras;
  final bool estatico, mostrouAlgo, mostrarPt, esconderEn, pense, frio;
  final double tPasso, fatorFala, animacao;
  final _PlanoDoVao? plano;

  void aplicar(RoteiroSeguidor s) {
    s._estado = estado;
    s._status = estado?.status ?? StatusOuvir.parado;
    s._indice = indice;
    s._chave = chave;
    s._faixa = faixa;
    s._historiaDaFaixa = historiaDaFaixa;
    s._ancora = ancora;
    s._proxima = proxima;
    s._h = h;
    s._linhas = linhas;
    s._cena = cena;
    s._passo = passo;
    s._estatico = estatico;
    s._tPasso = tPasso;
    s._animacao = animacao;
    s._mostrouAlgo = mostrouAlgo;
    // o texto que digitava completa (a voz seguiu enquanto o palco estava fechado)
    s._digitando = false;
    s._letras = math.max(letras, s._totalLetras);
    s._fatorFala = fatorFala;
    s._mostrarPt = mostrarPt;
    s._esconderEn = esconderEn;
    s._pense = pense;
    s._frio = frio;
    s._plano = plano;
  }
}
