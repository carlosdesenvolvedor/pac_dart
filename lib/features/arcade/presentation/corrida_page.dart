import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/banco_desafios.dart';
import '../domain/corrida_engine.dart';
import '../domain/desafio.dart';
import '../domain/dicas_dart.dart';
import '../domain/personagem.dart';
import 'widgets/arcade_ui.dart';

/// 🏎️ Corrida do Código — campanha em FASES de LÓGICA: preveja o resultado
/// pra acelerar (resposta em até 6s = turbo). Venceu? Fase nova, cenário
/// novo e CPU mais rápida — os pontos acumulam até o rival te pegar.
class CorridaPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const CorridaPage({super.key, this.semente});

  @override
  State<CorridaPage> createState() => _CorridaPageState();
}

class _CorridaPageState extends State<CorridaPage> {
  RankingCubit? _ranking;

  Dificuldade? _dificuldade;
  CorridaEngine? _engine;
  late math.Random _rnd;
  List<Desafio> _fila = const [];
  int _idx = 0;

  int _fase = 1;
  int _fasesVencidas = 0;
  int _pontosTotal = 0;
  int _acertosRun = 0;
  int _errosRun = 0;
  int _turbosRun = 0;

  bool _respondido = false;
  int? _escolhida;
  bool _foiTurbo = false;

  bool _faseVencida = false;
  bool _acabou = false;
  bool _novoRecorde = false;
  bool _pontuado = false;

  Timer? _cpuTimer;
  Timer? _avancoTimer;
  DateTime _inicioPergunta = DateTime.now();

  Desafio get _desafio => _fila[_idx % _fila.length];

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cpuTimer?.cancel();
    _avancoTimer?.cancel();
    final resto = _pontosParciais();
    if (!_pontuado && resto > 0) _ranking?.arcadeJogado('corrida', resto);
    super.dispose();
  }

  // ---------- campanha ----------

  double get _fator => 1 + 0.1 * (_fase - 1);

  Duration _intervaloCpu() {
    final base = _dificuldade!.intervaloCpu.inMilliseconds;
    final ms = (base * math.pow(0.92, _fase - 1)).round();
    return Duration(milliseconds: math.max(1700, ms));
  }

  int _pontosParciais() {
    final e = _engine;
    final parcial =
        (e != null && !_faseVencida && !_acabou) ? (e.pontos * _fator).round() : 0;
    return _pontosTotal + parcial;
  }

  void _comecarRun(Dificuldade d) {
    setState(() {
      _dificuldade = d;
      _rnd = math.Random(widget.semente);
      _fase = 1;
      _fasesVencidas = 0;
      _pontosTotal = 0;
      _acertosRun = 0;
      _errosRun = 0;
      _turbosRun = 0;
      _acabou = false;
      _novoRecorde = false;
      _pontuado = false;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _cpuTimer?.cancel();
    _avancoTimer?.cancel();
    setState(() {
      _engine = CorridaEngine(dificuldade: _dificuldade!);
      _fila = sortearDesafios(
          tipo: TipoDesafio.logica, quantidade: 40, rnd: _rnd, banco: bancoDesafios);
      _idx = 0;
      _respondido = false;
      _escolhida = null;
      _faseVencida = false;
      _inicioPergunta = DateTime.now();
    });
    _cpuTimer = Timer.periodic(_intervaloCpu(), (_) => _tickCpu());
  }

  void _tickCpu() {
    final e = _engine;
    if (e == null || _acabou || _faseVencida) return;
    setState(e.tickCpu);
    if (e.terminou) _fimDeJogo();
  }

  void _venceuFase() {
    Sons.toca(Som.fase);
    final e = _engine!;
    _cpuTimer?.cancel();
    _avancoTimer?.cancel();
    setState(() {
      _fasesVencidas++;
      _pontosTotal += (e.pontos * _fator).round();
      _acertosRun += e.acertos;
      _errosRun += e.erros;
      _turbosRun += e.turbos;
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
    _cpuTimer?.cancel();
    _avancoTimer?.cancel();
    final e = _engine!;
    setState(() {
      if (somaFaseAtual) {
        _pontosTotal += (e.pontos * _fator).round();
        _acertosRun += e.acertos;
        _errosRun += e.erros;
        _turbosRun += e.turbos;
      }
      _faseVencida = false;
      _acabou = true;
    });
    Sons.toca(_fasesVencidas > 0 ? Som.fanfarra : Som.defesa);
    final recorde = await _ranking?.arcadeJogado('corrida', _pontosTotal);
    if (mounted && recorde == true) setState(() => _novoRecorde = true);
  }

  void _responder(int i) {
    final e = _engine;
    if (e == null || _respondido || _acabou || _faseVencida) return;
    final certa = i == _desafio.certa;
    final rapida =
        DateTime.now().difference(_inicioPergunta) <= CorridaEngine.limiteTurbo;
    setState(() {
      _respondido = true;
      _escolhida = i;
      _foiTurbo = certa && rapida;
      e.responder(certa: certa, turbo: rapida);
    });
    Sons.toca(certa ? (_foiTurbo ? Som.turbo : Som.blip) : Som.erro);
    if (e.terminou) {
      e.venceu ? _venceuFase() : _fimDeJogo();
      return;
    }
    _avancoTimer = Timer(
      Duration(milliseconds: certa ? 900 : 2600),
      () => setState(() {
        _idx++;
        _respondido = false;
        _escolhida = null;
        _inicioPergunta = DateTime.now();
      }),
    );
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent || _engine == null) return KeyEventResult.ignored;
    final digito = switch (e.logicalKey) {
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => 0,
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => 1,
      LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => 2,
      _ => null,
    };
    if (digito == null || digito >= _desafio.opcoes.length) return KeyEventResult.ignored;
    _responder(digito);
    return KeyEventResult.handled;
  }

  // ---------- telas ----------

  @override
  Widget build(BuildContext context) {
    final e = _engine;
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
                      rotulo: 'ARCADE · LÓGICA',
                      titulo: '🏎️ Corrida do Código',
                      chips: e == null
                          ? const []
                          : [
                              ChipPlacar('FASE', '$_fase'),
                              ChipPlacar('TOTAL', '${_pontosParciais()}', cor: Mixart.brand),
                              ChipPlacar('TURBOS', '${e.turbos}'),
                              ChipPlacar('RIVAL', e.dificuldade.emoji),
                            ],
                    ),
                    const SizedBox(height: 16),
                    if (e == null) _escolheDificuldade() else ..._corrida(e),
                  ],
                ),
                if (_faseVencida)
                  FaseVencida(
                    fase: _fase,
                    pontosFase: (_engine!.pontos * _fator).round(),
                    pontosTotal: _pontosTotal,
                    dica: dicaDaFase(_fase),
                    aviso: 'a CPU pisa fundo — responda rápido pros turbos salvarem você!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                  ),
                if (_acabou && e != null)
                  FimDeJogo(
                    emoji: _fasesVencidas > 0 ? '🏆' : '🤖',
                    titulo: _fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'A CPU VENCEU…',
                    subtitulo: _fasesVencidas > 0
                        ? 'Você venceu $_fasesVencidas fase${_fasesVencidas > 1 ? 's' : ''} de pura lógica Dart.'
                        : 'Responda em até 6s pro TURBO dobrar o passo — e tente de novo!',
                    pontos: _pontosTotal,
                    novoRecorde: _novoRecorde,
                    celebrar: _fasesVencidas > 0,
                    stats: [
                      ('FASES', '$_fasesVencidas'),
                      ('ACERTOS', '$_acertosRun'),
                      ('TURBOS', '$_turbosRun'),
                      ('ERROS', '$_errosRun'),
                    ],
                    onDeNovo: () => _comecarRun(e.dificuldade),
                    onSair: () => Navigator.of(context).pop(),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _escolheDificuldade() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Text(
          'Preveja o resultado do código para ACELERAR. Resposta certa em até 6s '
          'liga o TURBO (anda 2). Errou? Derrapou — e o rival anda um passo. '
          'Cada fase vencida abre um cenário novo com a CPU mais rápida, '
          'acumulando pontos. Responda no toque ou nas teclas 1, 2 e 3.',
          style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.5),
        ),
      ),
      const SizedBox(height: 16),
      SeletorDificuldade(onEscolher: _comecarRun),
    ]);
  }

  List<Widget> _corrida(CorridaEngine e) {
    return [
      PistaPro(posJogador: e.posJogador, posCpu: e.posCpu, pista: e.pista, fase: _fase),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Text(_desafio.pergunta,
            style: Mixart.ui(size: 14.5, weight: FontWeight.w600).copyWith(height: 1.5)),
      ),
      const SizedBox(height: 12),
      if (_desafio.codigo.isNotEmpty) ...[
        CartaoCodigo(_desafio.codigo),
        const SizedBox(height: 12),
      ],
      for (var i = 0; i < _desafio.opcoes.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BotaoOpcao(
            indice: i,
            codigo: _desafio.opcoes[i],
            revelado: _respondido,
            ehCerta: i == _desafio.certa,
            ehEscolhida: i == _escolhida,
            onTap: () => _responder(i),
          ),
        ),
      SizedBox(height: 44, child: _feedback()),
    ];
  }

  Widget _feedback() {
    if (!_respondido) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⌨️ teclas 1 · 2 · 3 respondem na hora',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      );
    }
    final acertou = _escolhida == _desafio.certa;
    if (acertou) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(_foiTurbo ? '🔥 TURBO! Passo dobrado!' : '⚡ Acelerou!',
            style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text('💨 Derrapou! ${_desafio.explica}',
          style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.danger)
              .copyWith(height: 1.4)),
    );
  }
}
