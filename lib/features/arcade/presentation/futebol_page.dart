import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/banco_desafios.dart';
import '../domain/desafio.dart';
import '../domain/dicas_dart.dart';
import '../domain/futebol_engine.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/cenario.dart';

/// ⚽ Gol de Dart — campanha em FASES: séries de 5 pênaltis de SINTAXE.
/// Cada opção é um canto do gol; 3+ gols na série avançam de fase — o
/// estádio muda de clima e o relógio do chute aperta. Pontos acumulam.
class FutebolPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const FutebolPage({super.key, this.semente});

  @override
  State<FutebolPage> createState() => _FutebolPageState();
}

class _FutebolPageState extends State<FutebolPage> {
  static const _cantos = ['CANTO ESQUERDO', 'MEIO DO GOL', 'CANTO DIREITO'];

  RankingCubit? _ranking;
  late math.Random _rnd;
  late FutebolEngine _engine;
  late List<Desafio> _fila;
  int _idx = 0;

  int _fase = 1;
  int _fasesVencidas = 0;
  int _pontosTotal = 0;
  int _golsRun = 0;
  int _defesasRun = 0;

  final List<Chute> _historico = [];
  bool _revelado = false;
  int? _zonaBola; // null durante a espera (ou no estouro do relógio)
  int _zonaGoleiro = 1;
  bool _estourou = false;

  int _restante = 20;
  Timer? _relogio;
  Timer? _avanco;

  bool _faseVencida = false;
  bool _acabou = false;
  bool _novoRecorde = false;
  bool _pontuado = false;

  Desafio get _desafio => _fila[_idx];

  /// O relógio do chute aperta a cada fase (20s → … → 8s).
  int get _tempoDoChute => (20 - 2 * (_fase - 1)).clamp(8, 20);

  double get _fator => 1 + 0.1 * (_fase - 1);

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    _comecarRun();
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _avanco?.cancel();
    final resto = _pontosParciais();
    if (!_pontuado && resto > 0) _ranking?.arcadeJogado('futebol', resto);
    super.dispose();
  }

  int _pontosParciais() {
    final parcial =
        (!_faseVencida && !_acabou) ? (_engine.pontos * _fator).round() : 0;
    return _pontosTotal + parcial;
  }

  // ---------- campanha ----------

  void _comecarRun() {
    _rnd = math.Random(widget.semente);
    setState(() {
      _fase = 1;
      _fasesVencidas = 0;
      _pontosTotal = 0;
      _golsRun = 0;
      _defesasRun = 0;
      _acabou = false;
      _novoRecorde = false;
      _pontuado = false;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _relogio?.cancel();
    _avanco?.cancel();
    setState(() {
      _engine = FutebolEngine();
      _fila = sortearDesafios(
          tipo: TipoDesafio.sintaxe, quantidade: 5, rnd: _rnd, banco: bancoDesafios);
      _idx = 0;
      _historico.clear();
      _revelado = false;
      _zonaBola = null;
      _zonaGoleiro = 1;
      _estourou = false;
      _restante = _tempoDoChute;
      _faseVencida = false;
    });
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _venceuFase() {
    Sons.toca(Som.fase);
    _relogio?.cancel();
    _avanco?.cancel();
    setState(() {
      _fasesVencidas++;
      _pontosTotal += (_engine.pontos * _fator).round();
      _golsRun += _engine.gols;
      _defesasRun += _engine.defesas;
      _faseVencida = true;
    });
  }

  void _proximaFase() {
    setState(() => _fase++);
    _comecarFase();
  }

  Future<void> _fimDeJogo({bool somaFaseAtual = true}) async {
    if (_pontuado) return;
    _pontuado = true;
    _relogio?.cancel();
    _avanco?.cancel();
    setState(() {
      if (somaFaseAtual) {
        _pontosTotal += (_engine.pontos * _fator).round();
        _golsRun += _engine.gols;
        _defesasRun += _engine.defesas;
      }
      _faseVencida = false;
      _acabou = true;
    });
    Sons.toca(_fasesVencidas > 0 ? Som.fanfarra : Som.defesa);
    final recorde = await _ranking?.arcadeJogado('futebol', _pontosTotal);
    if (mounted && recorde == true) setState(() => _novoRecorde = true);
  }

  // ---------- a série ----------

  void _tick() {
    if (_revelado || _acabou || _faseVencida) return;
    setState(() => _restante--);
    if (_restante <= 0) _chutar(null);
  }

  /// [zona] é a opção escolhida (0/1/2); null = o relógio estourou.
  void _chutar(int? zona) {
    if (_revelado || _acabou || _faseVencida) return;
    final certa = zona != null && zona == _desafio.certa;
    final resultado = _engine.chutar(certa: certa);
    Sons.toca(resultado == Chute.gol ? Som.gol : Som.defesa);
    setState(() {
      _revelado = true;
      _estourou = zona == null;
      _zonaBola = zona;
      _historico.add(resultado);
      if (certa) {
        // goleiro pula num canto ERRADO — a bola morre no canto certo
        final outras = [0, 1, 2]..remove(zona);
        _zonaGoleiro = outras[_rnd.nextInt(outras.length)];
      } else {
        // defendeu: as luvas vão exatamente aonde a bola foi
        _zonaGoleiro = zona ?? 1;
      }
    });
    if (_engine.terminou) {
      _avanco = Timer(const Duration(milliseconds: 2000), () {
        _engine.gols >= 3 ? _venceuFase() : _fimDeJogo();
      });
    } else {
      _avanco = Timer(
        Duration(milliseconds: resultado == Chute.gol ? 1700 : 2900),
        () => setState(() {
          _idx++;
          _revelado = false;
          _zonaBola = null;
          _zonaGoleiro = 1;
          _estourou = false;
          _restante = _tempoDoChute;
        }),
      );
    }
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final zona = switch (e.logicalKey) {
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 || LogicalKeyboardKey.arrowLeft => 0,
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 || LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 || LogicalKeyboardKey.arrowRight => 2,
      _ => null,
    };
    if (zona == null) return KeyEventResult.ignored;
    _chutar(zona);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        autofocus: true,
        onKeyEvent: _tecla,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Stack(children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    CabecalhoJogo(
                      rotulo: 'ARCADE · SINTAXE',
                      titulo: '⚽ Gol de Dart',
                      chips: [
                        ChipPlacar('FASE', '$_fase'),
                        ChipPlacar('TOTAL', '${_pontosParciais()}', cor: Mixart.brand),
                        ChipPlacar('GOLS', '${_engine.gols}'),
                        ChipPlacar('COBRANÇA',
                            '${(_engine.rodada + (_acabou || _faseVencida ? 0 : 1)).clamp(1, _engine.cobrancas)}/${_engine.cobrancas}'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _gol(),
                    const SizedBox(height: 10),
                    _placarBolinhas(),
                    const SizedBox(height: 14),
                    _relogioBarra(),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Mixart.brandSub,
                        border: Border.all(color: Mixart.brandDim),
                        borderRadius: BorderRadius.circular(Mixart.radiusMd),
                      ),
                      child: Text(_desafio.pergunta,
                          style: Mixart.ui(size: 14.5, weight: FontWeight.w600)
                              .copyWith(height: 1.5)),
                    ),
                    const SizedBox(height: 12),
                    if (_desafio.codigo.isNotEmpty) ...[
                      CartaoCodigo(_desafio.codigo),
                      const SizedBox(height: 12),
                    ],
                    _opcoes(),
                    const SizedBox(height: 10),
                    SizedBox(height: 40, child: _feedback()),
                  ],
                ),
                if (_faseVencida)
                  FaseVencida(
                    fase: _fase,
                    pontosFase: (_engine.pontos * _fator).round(),
                    pontosTotal: _pontosTotal,
                    dica: dicaDaFase(_fase),
                    aviso:
                        'o relógio do chute aperta pra ${(20 - 2 * _fase).clamp(8, 20)}s!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                  ),
                if (_acabou)
                  FimDeJogo(
                    emoji: _fasesVencidas > 0 ? '🏆' : '🧤',
                    titulo: _fasesVencidas > 0
                        ? 'FIM DA CAMPANHA!'
                        : 'O GOLEIRO LEVOU A MELHOR…',
                    subtitulo:
                        'Você marcou $_golsRun gol${_golsRun == 1 ? '' : 's'} em ${_fasesVencidas + 1} série${_fasesVencidas == 0 ? '' : 's'} — 3+ gols avançam de fase.',
                    pontos: _pontosTotal,
                    novoRecorde: _novoRecorde,
                    celebrar: _fasesVencidas > 0,
                    stats: [
                      ('FASES', '$_fasesVencidas'),
                      ('GOLS', '$_golsRun'),
                      ('DEFESAS', '$_defesasRun'),
                    ],
                    onDeNovo: _comecarRun,
                    onSair: () => Navigator.of(context).pop(),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- pedaços ----------

  static const _alinhamentos = [-0.72, 0.0, 0.72];

  Widget _gol() {
    final gol = _revelado && _historico.isNotEmpty && _historico.last == Chute.gol;
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: SizedBox(
        height: 190,
        child: Stack(children: [
          // o estádio muda de clima a cada fase
          Positioned.fill(child: CenarioFase(fase: _fase)),
          Positioned.fill(child: Container(color: const Color(0x2E06070B))),
          // crachá da fase
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xCC10131A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${emojiDaFase(_fase)} FASE $_fase · ${nomeDaFase(_fase)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          // gramado
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(height: 26, color: const Color(0xB33E7B39)),
          ),
          // trave: dois postes + travessão
          Positioned(
            left: 26,
            right: 26,
            top: 30,
            bottom: 38,
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.white, width: 4),
                  top: BorderSide(color: Colors.white, width: 4),
                  right: BorderSide(color: Colors.white, width: 4),
                ),
              ),
            ),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOut,
            alignment: Alignment(_alinhamentos[_zonaGoleiro], -0.20),
            child: const Text('🧤', style: TextStyle(fontSize: 30)),
          ),
          AnimatedAlign(
            duration: const Duration(milliseconds: 430),
            curve: Curves.easeOutCubic,
            alignment: _zonaBola == null
                ? const Alignment(0, 0.92)
                : Alignment(_alinhamentos[_zonaBola!], -0.28),
            child: const Text('⚽', style: TextStyle(fontSize: 26)),
          ),
          if (_revelado)
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.4, end: 1),
                duration: const Duration(milliseconds: 320),
                curve: Mixart.spring,
                builder: (_, t, child) => Transform.scale(scale: t, child: child),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xE6010101),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _estourou ? '⏱ TEMPO ESGOTADO!' : (gol ? 'GOOOOL! 🎉' : 'DEFENDEU! 🧤'),
                    style: Mixart.display(
                        size: 24, color: gol ? Mixart.brand : Mixart.danger),
                  ),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _placarBolinhas() {
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      for (var i = 0; i < _engine.cobrancas; i++)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(
            i < _historico.length ? (_historico[i] == Chute.gol ? '⚽' : '🧤') : '·',
            style: TextStyle(fontSize: 17, color: Mixart.textFaint),
          ),
        ),
    ]);
  }

  Widget _relogioBarra() {
    final urgente = _restante <= 5;
    return Row(children: [
      Icon(Icons.timer_outlined, size: 15, color: urgente ? Mixart.danger : Mixart.textMuted),
      const SizedBox(width: 8),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (_restante / _tempoDoChute).clamp(0, 1),
            minHeight: 7,
            backgroundColor: Mixart.surfaceHi,
            color: urgente ? Mixart.danger : Mixart.brand,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text('${_restante.clamp(0, 99)}s',
          style: Mixart.mono(size: 12, color: urgente ? Mixart.danger : Mixart.textMuted)),
    ]);
  }

  Widget _opcoes() {
    final botoes = [
      for (var i = 0; i < _desafio.opcoes.length; i++)
        BotaoOpcao(
          indice: i,
          codigo: _desafio.opcoes[i],
          cantoRotulo: _cantos[i],
          revelado: _revelado,
          ehCerta: i == _desafio.certa,
          ehEscolhida: i == _zonaBola,
          onTap: () => _chutar(i),
        ),
    ];
    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= 680) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final b in botoes) ...[
            Expanded(child: b),
            if (b != botoes.last) const SizedBox(width: 10),
          ],
        ]);
      }
      return Column(children: [
        for (final b in botoes) Padding(padding: const EdgeInsets.only(bottom: 8), child: b),
      ]);
    });
  }

  Widget _feedback() {
    if (!_revelado) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⌨️ 1 · 2 · 3 (ou ← ↓ →) escolhem o canto',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      );
    }
    final gol = _historico.isNotEmpty && _historico.last == Chute.gol;
    if (gol) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⚽ No ângulo! O goleiro nem viu.',
            style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        _estourou
            ? '⏱ Demorou demais — o goleiro ficou com ela. ${_desafio.explica}'
            : '🧤 Defendeu! ${_desafio.explica}',
        style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.danger)
            .copyWith(height: 1.35),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
