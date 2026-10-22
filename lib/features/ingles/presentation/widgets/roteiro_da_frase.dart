import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../arcade/domain/historia_turismo.dart';
import '../../../arcade/domain/simulacao_historia.dart';
import '../../../arcade/presentation/historia/roteiro_historia.dart' show EstadoRoteiro;
import '../../../arcade/presentation/historia/roteiro_visivel.dart';
import '../../domain/assistir/compasso_assistir.dart';
import '../../domain/assistir/historia_licao.dart';

/// 🎬 O roteiro da CENA DA FRASE (o cartão da lição de inglês): mostra o passo da historinha ancorado na frase
/// que a pessoa está digitando — quem fala, o cenário, as posições, a ação e a emoção — sem voz própria e sem
/// avançar sozinho. A lição revisita as frases fora de ordem (a escada D1..D5): [irPara] SALTA para o estado
/// da âncora pela linha do tempo da [SimulacaoCena] (a linha já tem as entradas e posições de todos os passos
/// de antes), sem repassar a história inteira; a ação daquele passo anima uma vez.
///
/// Sem balão (o EN não pode aparecer; o palco recebe `semBalao`), sem PT e sem véu. A boca mexe SÓ com a voz
/// da lição ([falaComVoz]): o palco compara a `FalaEmCurso` com o [en] da âncora.
class RoteiroDaFrase extends ChangeNotifier implements RoteiroVisivel {
  RoteiroDaFrase({bool reduzir = false}) : _reduzir = reduzir;

  /// Depois da ação do passo, quanto ainda se repinta (s): a fala que abre, o efeito, a câmera (a mesma
  /// margem do `RoteiroSeguidor`).
  static const margemDeAnimacao = .4;

  HistoriaLicao? _h;
  List<List<EstadoCena>> _linhas = const [];
  int _cena = 0, _passo = 0;
  double _tPasso = 0;
  double _animacao = 0;
  bool _reduzir;

  /// A história e a âncora na tela (null antes do 1º [irPara]).
  HistoriaLicao? get historia => _h;
  (int, int)? get ancora => _h == null ? null : (_cena, _passo);

  /// O EN da âncora (o que a voz da lição fala): a boca só mexe com ele.
  String? get en => _fala?.en;

  /// Quanto dura a animação deste passo (s); depois disso o palco fica parado na pose final.
  double get animacao => _animacao;

  /// A ação do passo ainda anima (o relógio precisa andar).
  bool get animando => _h != null && _tPasso < _animacao;

  bool get reduzir => _reduzir;
  set reduzir(bool v) {
    if (v == _reduzir) return;
    _reduzir = v;
    if (v && animando) {
      _tPasso = _animacao; // já no estado final
      notifyListeners();
    }
  }

  /// Vai para a âncora [a] de [h] (cena, passo) com o tempo zerado: a ação recomeça uma vez (também na mesma
  /// âncora, a mesma frase revisitada). No reduzir, já no estado final.
  void irPara(HistoriaLicao h, (int, int) a) {
    if (!identical(h, _h)) {
      _h = h;
      _linhas = [for (final c in h.cenas) SimulacaoCena.linhaDoTempo(c)];
    }
    _cena = a.$1.clamp(0, math.max(0, h.cenas.length - 1));
    final falas = h.cenas.isEmpty ? const <FalaHistoria>[] : h.cenas[_cena].falas;
    _passo = falas.isEmpty ? 0 : a.$2.clamp(0, falas.length - 1);
    final f = _fala;
    // o efeito some em 2,6 s (palco_historia); a ação/reação/objeto, pela conta dos mudos
    _animacao = (f == null ? 0.0 : math.max(CompassoAssistir.duracaoMuda(f), 2.6)) + margemDeAnimacao;
    _tPasso = _reduzir ? _animacao : 0;
    notifyListeners();
  }

  /// O relógio da cena. Só notifica enquanto a ação anima (e no 1º tique depois dela, para fechar na pose
  /// final); devolve se notificou.
  bool tick(double dt) {
    if (dt <= 0 || !animando) return false;
    _tPasso = math.min(_tPasso + dt, _animacao);
    notifyListeners();
    return true;
  }

  // ───────────────────────── RoteiroVisivel

  FalaHistoria? get _fala {
    final h = _h;
    if (h == null || _cena >= h.cenas.length) return null;
    final falas = h.cenas[_cena].falas;
    return _passo >= 0 && _passo < falas.length ? falas[_passo] : null;
  }

  List<EstadoCena> get _linha => _linhas.isEmpty ? const [] : _linhas[_cena.clamp(0, _linhas.length - 1)];

  static EstadoCena _vazio() => EstadoCena(
        cenario: CenarioHistoria.casa,
        hora: HoraHistoria.dia,
        clima: [],
        atores: {},
        objetos: [],
      );

  @override
  EstadoRoteiro get estadoVisivel {
    final f = _fala;
    if (f == null || f.mudo || f.en == null) return EstadoRoteiro.entrando;
    return EstadoRoteiro.lendo;
  }

  @override
  FalaHistoria? get falaAtual => _fala;

  @override
  FalaHistoria? get falaAnterior {
    final h = _h;
    if (h == null || _cena >= h.cenas.length || _passo <= 0) return null;
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
    return l.isEmpty ? _vazio() : l[(_passo + 1).clamp(0, l.length - 1)];
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
  int get letrasVisiveis => en?.length ?? 0;

  @override
  bool get mostrarPt => false;

  @override
  bool get noTitulo => false;

  @override
  double get duracaoTituloAtual => 0;

  @override
  bool get falaComVoz => true;

  @override
  bool get esconderEn => true;

  @override
  String? get iconeDaFala => null;

  @override
  double get escurecimento => 0;
}
