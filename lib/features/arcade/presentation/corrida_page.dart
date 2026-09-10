import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../domain/banco_desafios.dart';
import '../domain/baralho.dart';
import '../domain/corrida_engine.dart';
import '../domain/desafio.dart';
import '../domain/dicas_dart.dart';
import '../domain/personagem.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/campanha.dart';
import 'widgets/cenario.dart';

/// 🏎️ Corrida do Código — campanha em FASES de LÓGICA: preveja o resultado
/// pra acelerar (resposta dentro da janela de 6s = turbo, e a janela é
/// VISÍVEL). Largada 3-2-1, medidor mostrando quando a CPU vai andar, pausa
/// com Esc. Venceu? Fase nova, cenário novo, desafios mais difíceis e CPU
/// mais rápida — os pontos acumulam até o rival te pegar.
class CorridaPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const CorridaPage({super.key, this.semente});

  @override
  State<CorridaPage> createState() => _CorridaPageState();
}

class _CorridaPageState extends State<CorridaPage>
    with
        WidgetsBindingObserver,
        PausaDeJogo<CorridaPage>,
        CampanhaDeFases<CorridaPage>,
        TickerProviderStateMixin {
  Dificuldade? _dificuldade;
  CorridaEngine? _engine;
  late math.Random _rnd;
  BaralhoDesafios? _baralho;
  Desafio? _desafio;

  int _acertosRun = 0;
  int _errosRun = 0;
  int _turbosRun = 0;

  /// Largada 3-2-1 rolando (relógios ainda parados).
  bool _contagem = false;
  bool _respondido = false;
  int? _escolhida;
  bool _foiTurbo = false;

  /// 🔥 atrás do jogador na pista (some sozinho).
  bool _chama = false;

  /// Relógio do rival: quando completa, a CPU anda um passo.
  late final AnimationController _cpuCtrl = AnimationController(vsync: this)
    ..addStatusListener(_cpuCompletou);

  /// Janela do turbo: 6s escoando desde que a pergunta apareceu.
  late final AnimationController _turboCtrl =
      AnimationController(vsync: this, duration: CorridaEngine.limiteTurbo);

  Timer? _avancoTimer;
  Timer? _chamaTimer;

  @override
  String get jogoId => 'corrida';

  @override
  int get pontosDoMotor => _engine?.pontos ?? 0;

  @override
  bool get emPartida => _engine != null && !_contagem;

  @override
  void initState() {
    super.initState();
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _avancoTimer?.cancel();
    _chamaTimer?.cancel();
    _cpuCtrl.dispose();
    _turboCtrl.dispose();
    super.dispose();
  }

  // ---------- campanha ----------

  /// A CPU acelera 8% por fase (nunca abaixo de 1,7s).
  Duration _intervaloCpu() {
    final base = _dificuldade!.intervaloCpu.inMilliseconds;
    final ms = (base * math.pow(0.92, fase - 1)).round();
    return Duration(milliseconds: math.max(1700, ms));
  }

  void _comecarRun(Dificuldade d) {
    _avancoTimer?.cancel();
    setState(() {
      _dificuldade = d;
      _rnd = math.Random(widget.semente);
      _baralho = BaralhoDesafios(rnd: _rnd, tipo: TipoDesafio.logica, banco: bancoDesafios);
      zerarCampanha();
      _acertosRun = 0;
      _errosRun = 0;
      _turbosRun = 0;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _avancoTimer?.cancel();
    _cpuCtrl.stop();
    _turboCtrl.stop();
    setState(() {
      _engine = CorridaEngine(dificuldade: _dificuldade!);
      _desafio = _baralho!.proximo(fase);
      _respondido = false;
      _escolhida = null;
      _foiTurbo = false;
      _chama = false;
      _contagem = true;
      _turboCtrl.value = 0;
    });
  }

  /// Fim da largada: os relógios ligam.
  void _largada() {
    if (!mounted || acabou || _engine == null) return;
    setState(() => _contagem = false);
    _cpuCtrl.duration = _intervaloCpu();
    _cpuCtrl.forward(from: 0);
    _turboCtrl.forward(from: 0);
    pausarSeEscondido();
  }

  void _cpuCompletou(AnimationStatus s) {
    if (s != AnimationStatus.completed) return;
    final e = _engine;
    if (e == null || acabou || faseVencida || pausado || _contagem) return;
    setState(e.tickCpu);
    if (e.terminou) {
      _fimDeJogo();
      return;
    }
    _cpuCtrl.forward(from: 0);
  }

  @override
  void aoPausar() {
    _cpuCtrl.stop();
    _turboCtrl.stop();
  }

  @override
  void aoRetomar() {
    if (_engine == null || acabou || faseVencida) return;
    _cpuCtrl.forward();
    if (!_respondido) _turboCtrl.forward();
  }

  void _acumula(CorridaEngine e) {
    _acertosRun += e.acertos;
    _errosRun += e.erros;
    _turbosRun += e.turbos;
  }

  void _venceuFase() {
    _cpuCtrl.stop();
    _turboCtrl.stop();
    _avancoTimer?.cancel();
    _acumula(_engine!);
    registrarFaseVencida();
  }

  void _proximaFase() {
    avancarFase();
    _comecarFase();
  }

  Future<void> _fimDeJogo({bool somaFaseAtual = true}) {
    if (pontuado) return Future.value();
    _cpuCtrl.stop();
    _turboCtrl.stop();
    _avancoTimer?.cancel();
    if (somaFaseAtual) _acumula(_engine!);
    return encerrar(somaFaseAtual: somaFaseAtual);
  }

  // ---------- a corrida ----------

  void _responder(int i) {
    final e = _engine;
    final d = _desafio;
    if (e == null || d == null || _respondido || acabou || faseVencida || pausado || _contagem) {
      return;
    }
    final certa = i == d.certa;
    final rapida = !_turboCtrl.isCompleted;
    _turboCtrl.stop();
    setState(() {
      _respondido = true;
      _escolhida = i;
      _foiTurbo = certa && rapida;
      _chama = _foiTurbo;
      e.responder(certa: certa, turbo: rapida);
    });
    Sons.toca(certa ? (_foiTurbo ? Som.turbo : Som.blip) : Som.erro);
    if (_foiTurbo) {
      _chamaTimer?.cancel();
      _chamaTimer = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _chama = false);
      });
    }
    if (e.terminou) {
      e.venceu ? _venceuFase() : _fimDeJogo();
      return;
    }
    _avancoTimer = Timer(Duration(milliseconds: certa ? 900 : 2600), _proximaPergunta);
  }

  void _proximaPergunta() {
    if (!mounted || acabou || faseVencida || _engine == null) return;
    setState(() {
      _desafio = _baralho!.proximo(fase);
      _respondido = false;
      _escolhida = null;
      _turboCtrl.value = 0;
    });
    if (!pausado) _turboCtrl.forward(from: 0);
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (teclaDePausa(e)) return KeyEventResult.handled;
    if (e is! KeyDownEvent || _engine == null || pausado) return KeyEventResult.ignored;
    final digito = switch (e.logicalKey) {
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => 0,
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => 1,
      LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => 2,
      _ => null,
    };
    final d = _desafio;
    if (digito == null || d == null || digito >= d.opcoes.length) return KeyEventResult.ignored;
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
                      titulo: '🚗 Corrida do Código',
                      chips: e == null
                          ? const []
                          : [
                              ChipPlacar('FASE', '$fase'),
                              ChipPlacar('TOTAL', '$pontosParciais', cor: Mixart.brand),
                              ChipPlacar('TURBOS', '${e.turbos}'),
                              ChipPlacar('RIVAL', e.dificuldade.emoji),
                            ],
                      acao: e == null ? null : BotaoPausa(onTap: podePausar ? pausar : null),
                    ),
                    const SizedBox(height: 16),
                    if (e == null) _escolheDificuldade() else ..._corrida(e),
                  ],
                ),
                if (_contagem)
                  ContagemRegressiva(
                    onFim: _largada,
                    legenda: '${emojiDaFase(fase)} FASE $fase · ${nomeDaFase(fase)}',
                  ),
                if (pausado)
                  PausaOverlay(onContinuar: retomar, onSair: () => Navigator.of(context).pop()),
                if (faseVencida)
                  FaseVencida(
                    fase: fase,
                    pontosFase: comFator(pontosDoMotor),
                    pontosTotal: pontosTotal,
                    dica: dicaDaFase(fase),
                    aviso: fase == 1
                        ? 'entram desafios de nível 2 e a CPU pisa fundo!'
                        : fase == 2
                            ? 'chegam os chefões de nível 3 — e a CPU acelera!'
                            : 'a CPU pisa fundo — responda rápido pros turbos salvarem você!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                  ),
                if (acabou && e != null)
                  FimDeJogo(
                    emoji: fasesVencidas > 0 ? '🏆' : '🤖',
                    titulo: fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'A CPU VENCEU…',
                    subtitulo: fasesVencidas > 0
                        ? 'Você venceu $fasesVencidas fase${fasesVencidas > 1 ? 's' : ''} de pura lógica Dart.'
                        : 'Responda enquanto a barra do TURBO está cheia pra dobrar o passo — e tente de novo!',
                    pontos: pontosTotal,
                    novoRecorde: novoRecorde,
                    celebrar: fasesVencidas > 0,
                    noRanking: ranking != null,
                    stats: [
                      ('FASES', '$fasesVencidas'),
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
          'Preveja o resultado do código para ACELERAR. Resposta certa com a barra '
          'do TURBO ainda cheia (6s) anda 2 casas. Errou? Derrapou — e o rival anda '
          'um passo. O medidor sob a CPU mostra quando ela vai andar. Cada fase '
          'vencida traz cenário novo, desafios mais difíceis e CPU mais rápida. '
          'Responda no toque ou nas teclas 1, 2 e 3 · Esc pausa.',
          style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.5),
        ),
      ),
      const SizedBox(height: 16),
      SeletorDificuldade(onEscolher: _comecarRun),
    ]);
  }

  List<Widget> _corrida(CorridaEngine e) {
    final d = _desafio!;
    return [
      PistaPro(
        posJogador: e.posJogador,
        posCpu: e.posCpu,
        pista: e.pista,
        fase: fase,
        turbo: _chama,
        cargaCpu: _cpuCtrl,
      ),
      const SizedBox(height: 12),
      _barraTurbo(),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(d.pergunta,
                style: Mixart.ui(size: 14.5, weight: FontWeight.w600).copyWith(height: 1.5)),
          ),
          const SizedBox(width: 10),
          SeloNivel(d.nivel),
        ]),
      ),
      const SizedBox(height: 12),
      if (d.codigo.isNotEmpty) ...[
        CartaoCodigo(d.codigo),
        const SizedBox(height: 12),
      ],
      for (var i = 0; i < d.opcoes.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BotaoOpcao(
            indice: i,
            codigo: d.opcoes[i],
            revelado: _respondido,
            ehCerta: i == d.certa,
            ehEscolhida: i == _escolhida,
            onTap: () => _responder(i),
          ),
        ),
      SizedBox(height: 44, child: _feedback(d)),
    ];
  }

  /// A janela do turbo escoando à vista: cheia = passo dobrado garantido.
  Widget _barraTurbo() {
    return AnimatedBuilder(
      animation: _turboCtrl,
      builder: (_, _) {
        final resta = (1 - _turboCtrl.value).clamp(0.0, 1.0);
        final viva = resta > 0 && !_respondido && !_contagem;
        final segundos = (resta * CorridaEngine.limiteTurbo.inMilliseconds / 1000).ceil();
        final cor = viva ? Mixart.brand : Mixart.textFaint;
        return Row(children: [
          SizedBox(
            width: 92,
            child: Text(
              _respondido
                  ? (_foiTurbo ? '🔥 TURBO!' : '💨 sem turbo')
                  : (viva ? '🔥 TURBO' : '💨 turbo foi'),
              style: Mixart.ui(size: 11, weight: FontWeight.w800, color: cor)
                  .copyWith(letterSpacing: 1),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _contagem ? 1 : resta,
                minHeight: 7,
                backgroundColor: Mixart.surfaceHi,
                color: viva ? Mixart.brand : Mixart.border,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 26,
            child: Text(viva ? '${segundos}s' : '—',
                textAlign: TextAlign.right, style: Mixart.mono(size: 12, color: cor)),
          ),
        ]);
      },
    );
  }

  Widget _feedback(Desafio d) {
    if (!_respondido) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⌨️ teclas 1 · 2 · 3 respondem na hora · Esc pausa',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      );
    }
    final acertou = _escolhida == d.certa;
    if (acertou) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(_foiTurbo ? '🔥 TURBO! Passo dobrado!' : '⚡ Acelerou!',
            style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Text('💨 Derrapou! ${d.explica}',
          style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.danger)
              .copyWith(height: 1.4)),
    );
  }
}
