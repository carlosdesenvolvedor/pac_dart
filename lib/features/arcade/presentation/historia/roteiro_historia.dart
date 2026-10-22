import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../core/som/sons.dart';
import '../../../ingles/data/voz_ingles.dart';
import '../../domain/historia_turismo.dart';
import '../../domain/simulacao_historia.dart';
import 'elenco_turismo.dart';

/// Em que ponto o roteiro está.
enum EstadoRoteiro { aguardandoGesto, entrando, falando, lendo, cartaoFinal, terminado, pausado }

/// 🎬 A máquina de estados do desenho: percorre as falas das [cenas] com a linha do tempo da
/// [SimulacaoCena], cuida da voz, dos tempos e dos sons.
///
/// Cada passo: `entrando` (a ação do falante anima; entradas e andanças terminam antes do balão) →
/// `falando` (máquina de escrever + voz do personagem) → `lendo` (tempo mínimo de leitura) → próximo.
/// Quem fala com `acao: sai` fala parado e só sai depois da leitura ([tSaida], o balão some).
/// Passo mudo: só `entrando`, com a duração da ação. O tempo anda só pelo [tick] (o relógio do player):
/// nenhum `Timer` aqui dentro — pausa, página oculta e testes com `pump(Duration)` ficam previsíveis.
/// Avança sozinho quando a voz, a máquina de escrever E a leitura mínima acabaram; o toque completa o texto
/// e, com o texto completo, corta a voz e vai ao próximo passo.
class RoteiroHistoria extends ChangeNotifier {
  RoteiroHistoria({
    required List<CenaHistoria> cenas,
    required NivelIngles nivel,
    required VozIngles? voz,
    required bool vozLigada,
    required bool lenta,
    required bool mostrarPt,
    required bool reduzir,
  })  : _cenas = cenas,
        _nivel = nivel,
        _voz = voz,
        _vozLigada = vozLigada,
        _lenta = lenta,
        _mostrarPt = mostrarPt,
        _reduzir = reduzir,
        _linhas = [for (final c in cenas) SimulacaoCena.linhaDoTempo(c)];

  /// Quem toca os efeitos sonoros (D19). Trocável nos testes.
  static void Function(Som som) tocarSom = Sons.toca;

  /// Duração do cartão de título no 1º passo (segundos; com reduzir, [tituloReduzido]).
  static const duracaoTitulo = 1.8;
  static const tituloReduzido = 1.0;

  /// Intervalo mínimo entre dois efeitos sonoros (s).
  static const intervaloSons = .15;

  final List<CenaHistoria> _cenas;
  final NivelIngles _nivel;
  final VozIngles? _voz;
  final List<List<EstadoCena>> _linhas;
  bool _vozLigada, _lenta, _mostrarPt;
  final bool _reduzir;

  int _cena = 0, _passo = 0;
  EstadoRoteiro _estado = EstadoRoteiro.aguardandoGesto;
  EstadoRoteiro _antesDaPausa = EstadoRoteiro.falando;
  double _tPasso = 0;

  /// Relógio total do roteiro (só para o limite dos sons).
  double _relogio = 0;
  double _ultimoSom = -1;

  // ── tempos do passo atual
  double _durEntrada = 0, _durMudo = 0, _leituraMin = 0;
  double? _inicioFala, _fimDigitacao, _inicioSaida;
  int _letras = 0;

  // ── voz do passo atual
  int _gerVoz = 0;
  bool _vozPronta = true, _retomarVoz = false;
  double _limiteVoz = 0;

  int get cena => _cena;
  int get passo => _passo;
  EstadoRoteiro get estado => _estado;

  /// O estado que o palco desenha: em pausa, o de antes da pausa.
  EstadoRoteiro get estadoVisivel => _estado == EstadoRoteiro.pausado ? _antesDaPausa : _estado;

  /// Segundos desde o início do passo.
  double get tPasso => _tPasso;

  NivelIngles get nivel => _nivel;
  VozIngles? get voz => _voz;
  bool get vozLigada => _vozLigada;
  bool get lenta => _lenta;
  bool get mostrarPt => _mostrarPt;
  bool get reduzir => _reduzir;
  List<CenaHistoria> get cenas => _cenas;

  /// Segundos de `entrando` do passo atual (o balão aparece depois disso).
  double get duracaoEntrada => _durEntrada;

  /// Segundos desde que o balão do passo atual apareceu (null = ainda não apareceu / passo mudo).
  double? get tFala => _inicioFala == null ? null : math.max(0, _tPasso - _inicioFala!);

  /// Quanto dura a saída de quem fala e depois sai (s; a mesma andança do `sai` no palco).
  static double get duracaoSaida => SimulacaoCena.duracaoDe(AcaoAtor.sai) ?? .9;

  /// A fala com texto cuja ação é `sai`: o personagem fala primeiro, parado, e só sai depois da leitura.
  static bool saiDepoisDeFalar(FalaHistoria f) =>
      !f.mudo && !f.ehNarrador && f.acao == AcaoAtor.sai && (f.en?.isNotEmpty ?? false);

  /// Segundos desde que quem falou começou a sair (null = ainda falando/lendo, ou o passo não sai depois).
  double? get tSaida => _inicioSaida == null ? null : math.max(0, _tPasso - _inicioSaida!);

  /// O cartão de título aparece no começo do 1º passo da 1ª cena.
  bool get noTitulo =>
      _cena == 0 && _passo == 0 && estadoVisivel == EstadoRoteiro.entrando && _tPasso < duracaoTituloAtual;
  double get duracaoTituloAtual => _reduzir ? tituloReduzido : duracaoTitulo;

  /// Caracteres por segundo da máquina de escrever (A1 22 · A2 26 · B1/B2 30).
  double get letrasPorSegundo => switch (_nivel) {
        NivelIngles.a1 => 22,
        NivelIngles.a2 => 26,
        NivelIngles.b1 || NivelIngles.b2 => 30,
      };

  /// Quantas falas com texto o roteiro tem e quantas já passaram (bolinhas da barra).
  int get totalFalas => _cenas.fold(0, (s, c) => s + c.falas.where((f) => !f.mudo).length);
  int get falasPassadas {
    var n = 0;
    for (var i = 0; i < _cenas.length && i <= _cena; i++) {
      final falas = _cenas[i].falas;
      final ate = i < _cena ? falas.length : math.min(_passo, falas.length);
      for (var j = 0; j < ate; j++) {
        if (!falas[j].mudo) n++;
      }
    }
    if (_estado == EstadoRoteiro.cartaoFinal || _estado == EstadoRoteiro.terminado) return totalFalas;
    return n;
  }

  /// A fala do passo atual (null depois da última).
  FalaHistoria? get falaAtual {
    if (_cena >= _cenas.length) return null;
    final falas = _cenas[_cena].falas;
    return _passo < falas.length ? falas[_passo] : null;
  }

  /// A fala do passo anterior na mesma cena (a câmera sai dela).
  FalaHistoria? get falaAnterior {
    if (_cena >= _cenas.length || _passo == 0) return null;
    final falas = _cenas[_cena].falas;
    return _passo - 1 < falas.length ? falas[_passo - 1] : null;
  }

  EstadoCena get antes => _linhas.isEmpty ? _vazio() : _linha[_passo.clamp(0, _linha.length - 1)];
  EstadoCena get depois => _linhas.isEmpty ? _vazio() : _linha[(_passo + 1).clamp(0, _linha.length - 1)];

  List<EstadoCena> get _linha => _linhas[_cena.clamp(0, _linhas.length - 1)];

  static EstadoCena _vazio() => EstadoCena(
        cenario: CenarioHistoria.campina,
        hora: HoraHistoria.dia,
        clima: [],
        atores: {},
        objetos: [],
      );

  /// Letras do `en` já "digitadas" no balão.
  int get letrasVisiveis => _letras;

  /// O texto do balão já terminou de aparecer?
  bool get textoCompleto => _letras >= (falaAtual?.en?.length ?? 0);

  // ───────────────────────── comandos

  void tocar() {
    if (_estado != EstadoRoteiro.aguardandoGesto) return;
    _irPara(0, 0);
  }

  void tocarOuAvancar() {
    switch (_estado) {
      case EstadoRoteiro.aguardandoGesto:
        tocar();
      case EstadoRoteiro.cartaoFinal:
        _estado = EstadoRoteiro.terminado;
        notifyListeners();
      case EstadoRoteiro.terminado:
        break;
      case EstadoRoteiro.pausado:
        continuar();
      case EstadoRoteiro.entrando:
        final f = falaAtual;
        if (f == null || f.mudo) {
          _avancar();
        } else {
          _comecarFala();
          _completarTexto();
          notifyListeners();
        }
      case EstadoRoteiro.falando:
        _completarTexto();
        notifyListeners();
      case EstadoRoteiro.lendo:
        _cortarVoz();
        _voz?.parar(); // sem fala desta voz em curso, não mexe em nada
        _avancar();
    }
  }

  void pular() {
    _cortarVoz();
    _estado = EstadoRoteiro.terminado;
    notifyListeners();
  }

  void pausar() {
    if (_estado == EstadoRoteiro.pausado ||
        _estado == EstadoRoteiro.terminado ||
        _estado == EstadoRoteiro.cartaoFinal ||
        _estado == EstadoRoteiro.aguardandoGesto) {
      return;
    }
    _antesDaPausa = _estado;
    // a voz não pausa no meio da palavra: corta e repete a fala ao continuar
    if (!_vozPronta) {
      _retomarVoz = true;
      _cortarVoz();
    }
    _estado = EstadoRoteiro.pausado;
    notifyListeners();
  }

  void continuar() {
    if (_estado != EstadoRoteiro.pausado) return;
    _estado = _antesDaPausa;
    if (_retomarVoz) {
      _retomarVoz = false;
      _falar();
    }
    notifyListeners();
  }

  /// Volta ao começo do passo atual (a fala toca de novo).
  void repetir() {
    if (_cenas.isEmpty ||
        _estado == EstadoRoteiro.terminado ||
        _estado == EstadoRoteiro.aguardandoGesto ||
        _estado == EstadoRoteiro.cartaoFinal) {
      return;
    }
    _cortarVoz();
    _retomarVoz = false;
    _irPara(_cena.clamp(0, _cenas.length - 1), _passo);
  }

  void alternarPt() {
    _mostrarPt = !_mostrarPt;
    final f = falaAtual;
    if (f != null && !f.mudo) _leituraMin = _leituraDe(f);
    notifyListeners();
  }

  void alternarVoz() {
    _vozLigada = !_vozLigada;
    if (!_vozLigada) {
      _cortarVoz();
      _retomarVoz = false;
    }
    notifyListeners();
  }

  void alternarLenta() {
    _lenta = !_lenta;
    notifyListeners();
  }

  /// O relógio do player: [dt] segundos se passaram.
  void tick(double dt) {
    if (dt <= 0 ||
        _estado == EstadoRoteiro.pausado ||
        _estado == EstadoRoteiro.terminado ||
        _estado == EstadoRoteiro.cartaoFinal ||
        _estado == EstadoRoteiro.aguardandoGesto) {
      return;
    }
    _relogio += dt;
    _tPasso += dt;
    final f = falaAtual;
    if (f == null) {
      _avancar();
      return;
    }
    switch (_estado) {
      case EstadoRoteiro.entrando:
        if (f.mudo) {
          if (_tPasso >= _durMudo) _avancar();
        } else if (_tPasso >= _durEntrada) {
          _comecarFala();
          notifyListeners();
        }
      case EstadoRoteiro.falando:
        final total = f.en?.length ?? 0;
        final n = _reduzir ? total : math.min(total, ((tFala ?? 0) * letrasPorSegundo).floor());
        _confereLimiteVoz();
        // `n >= total` também: a fala sem `en` (parse leniente) completa na hora em vez de travar aqui
        if (n != _letras || n >= total) {
          _letras = n;
          if (_letras >= total) _completarTexto();
          notifyListeners();
        }
      case EstadoRoteiro.lendo:
        _confereLimiteVoz();
        final saida = _inicioSaida;
        if (saida != null) {
          if (_tPasso - saida >= duracaoSaida) _avancar();
        } else if (_vozPronta && _tPasso - (_fimDigitacao ?? _tPasso) >= _leituraMin) {
          if (!_reduzir && saiDepoisDeFalar(f)) {
            // falou e leu: agora sai andando (o balão some), e só então o próximo passo
            _inicioSaida = _tPasso;
            notifyListeners();
          } else {
            _avancar();
          }
        }
      default:
        break;
    }
  }

  @override
  void dispose() {
    _gerVoz++;
    super.dispose();
  }

  // ───────────────────────── interno

  void _completarTexto() {
    _letras = falaAtual?.en?.length ?? 0;
    _fimDigitacao ??= _tPasso;
    _estado = EstadoRoteiro.lendo;
  }

  void _comecarFala() {
    final f = falaAtual;
    if (f == null || _inicioFala != null) return;
    _inicioFala = _tPasso;
    _letras = _reduzir ? (f.en?.length ?? 0) : 0;
    _estado = EstadoRoteiro.falando;
    _som(Som.tique);
    _falar();
    if (_reduzir || (f.en?.length ?? 0) == 0) _completarTexto();
  }

  /// Toca a fala do passo atual na voz do personagem (se a voz estiver ligada).
  void _falar() {
    final f = falaAtual;
    final en = f?.en;
    final voz = _voz;
    if (f == null || en == null || !_vozLigada || voz == null) {
      _vozPronta = true;
      return;
    }
    final g = ++_gerVoz;
    _vozPronta = false;
    _limiteVoz = (tFala ?? 0) + VozIngles.duracaoDe(en) * 2 + 5;
    void pronto(Object? _) {
      if (g != _gerVoz) return;
      _vozPronta = true;
    }

    try {
      voz
          .falarNoPlayer(en, fator: _lenta ? .8 : 1.0, perfil: ElencoTurismo.perfilDeVoz(f.quem))
          .then(pronto, onError: pronto);
    } catch (_) {
      _vozPronta = true;
    }
  }

  /// A voz que nunca responde não segura o desenho: passou do limite, segue.
  void _confereLimiteVoz() {
    if (!_vozPronta && (tFala ?? 0) > _limiteVoz) {
      _gerVoz++;
      _vozPronta = true;
    }
  }

  void _cortarVoz() {
    if (!_vozPronta) {
      _gerVoz++;
      _vozPronta = true;
      _voz?.parar();
    }
  }

  void _avancar() {
    _gerVoz++;
    _vozPronta = true;
    if (_cena >= _cenas.length) {
      _irParaCartao();
      return;
    }
    if (_passo + 1 < _cenas[_cena].falas.length) {
      _irPara(_cena, _passo + 1);
    } else if (_cena + 1 < _cenas.length) {
      _irPara(_cena + 1, 0);
    } else {
      _irParaCartao();
    }
  }

  void _irParaCartao() {
    _estado = EstadoRoteiro.cartaoFinal;
    _inicioFala = null;
    _som(Som.blip, forcar: true);
    notifyListeners();
  }

  void _irPara(int cena, int passo) {
    _cena = cena;
    _passo = passo;
    _tPasso = 0;
    _inicioFala = null;
    _fimDigitacao = null;
    _inicioSaida = null;
    _letras = 0;
    _vozPronta = true;
    if (_cenas.isEmpty || _cenas[cena].falas.isEmpty) {
      _irParaCartao();
      return;
    }
    final f = _cenas[cena].falas[passo];
    _durEntrada = _entradaDe(f, cena, passo);
    _durMudo = _mudoDe(f);
    _leituraMin = f.mudo ? 0 : _leituraDe(f);
    _estado = EstadoRoteiro.entrando;
    _sonsDoPasso(f);
    notifyListeners();
  }

  /// Ações que andam antes do balão. `sai` não está aqui: quem sai fala primeiro e sai depois
  /// ([saiDepoisDeFalar]); no passo mudo o `sai` usa a duração da ação.
  static const _acoesQueDeslocam = {
    AcaoAtor.entra,
    AcaoAtor.anda,
    AcaoAtor.corre,
    AcaoAtor.dirige,
    AcaoAtor.desce,
  };

  double _entradaDe(FalaHistoria f, int cena, int passo) {
    var d = _reduzir ? .15 : .25;
    if (passo == 0) d = _reduzir ? .2 : .5; // a cena abre (fade)
    if (f.cenario != null || f.hora != null) d = math.max(d, .45);
    if (!_reduzir && _acoesQueDeslocam.contains(f.acao)) {
      d = math.max(d, math.min(.9, SimulacaoCena.duracaoDe(f.acao) ?? 0));
    }
    if (cena == 0 && passo == 0) d += duracaoTituloAtual;
    return d;
  }

  double _mudoDe(FalaHistoria f) {
    if (!f.mudo) return 0;
    if (_reduzir) return .8;
    var d = SimulacaoCena.duracaoDe(f.acao) ?? 1.2;
    for (final r in f.reacoes) {
      final a = r.acao;
      if (a != null) d = math.max(d, SimulacaoCena.duracaoDe(a) ?? 0);
      if (r.efeito != null) d = math.max(d, 1.2);
    }
    if (f.efeito != null) d = math.max(d, 1.2);
    for (final m in f.objetos) {
      d = math.max(d, duracaoObjeto(m.acao));
    }
    if (_cena == 0 && _passo == 0) d += duracaoTituloAtual;
    return math.max(.8, d);
  }

  /// Duração da animação de um movimento de objeto (s): `passa` 1.6; `voa` 1.2; os outros .6.
  static double duracaoObjeto(AcaoObjeto a) => switch (a) {
        AcaoObjeto.passa => 1.6,
        AcaoObjeto.voa => 1.2,
        _ => .6,
      };

  /// Leitura mínima depois do texto completo: 600 ms + 30 ms por letra do PT (ou 45 ms por letra do EN sem
  /// o PT), teto 4 s.
  double _leituraDe(FalaHistoria f) {
    final pt = f.pt;
    final porLetra = _mostrarPt && pt != null ? .03 * pt.length : .045 * (f.en?.length ?? 0);
    return math.min(4, .6 + porLetra);
  }

  void _sonsDoPasso(FalaHistoria f) {
    final acoes = [if (!f.ehNarrador) f.acao, for (final r in f.reacoes) ?r.acao];
    final efeitos = [?f.efeito, for (final r in f.reacoes) ?r.efeito];
    Som? som;
    if (efeitos.contains(EfeitoHistoria.fogos) || efeitos.contains(EfeitoHistoria.relampago)) {
      som = Som.explosao;
    } else if (acoes.contains(AcaoAtor.comemora) || efeitos.contains(EfeitoHistoria.confete)) {
      som = Som.fase;
    } else if (acoes.contains(AcaoAtor.cai) || acoes.contains(AcaoAtor.rodopia)) {
      som = Som.defesa;
    } else if (efeitos.contains(EfeitoHistoria.estrelaCadente)) {
      som = Som.misterio;
    } else if (efeitos.contains(EfeitoHistoria.brilho)) {
      som = Som.combo;
    } else if (acoes.contains(AcaoAtor.pula)) {
      som = Som.blip;
    }
    if (som != null) _som(som);
  }

  void _som(Som s, {bool forcar = false}) {
    if (!forcar && _ultimoSom >= 0 && _relogio - _ultimoSom < intervaloSons) return;
    _ultimoSom = _relogio;
    try {
      tocarSom(s);
    } catch (_) {}
  }
}
