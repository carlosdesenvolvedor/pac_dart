import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../domain/corrida_engine.dart';
import '../domain/dicas_dart.dart';
import '../domain/digitar_palavra.dart';
import '../domain/palavras_csharp.dart';
import '../domain/personagem.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/campanha.dart';
import 'widgets/campo_teclas.dart';
import 'widgets/cenario.dart';

/// 🏁 Rali de Digitação — campanha em FASES: cada palavra digitada faz seu
/// personagem andar (perfeita = turbo, anda 2). Largada 3-2-1, medidor da
/// CPU na pista, fila das próximas palavras à vista e pausa com Esc. Venceu
/// a corrida? Fase nova, cenário novo, CPU mais rápida — os pontos vão
/// ACUMULANDO até a CPU te pegar (ou você parar e guardar o que juntou).
class RaliPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const RaliPage({super.key, this.semente});

  @override
  State<RaliPage> createState() => _RaliPageState();
}

class _RaliPageState extends State<RaliPage>
    with
        WidgetsBindingObserver,
        PausaDeJogo<RaliPage>,
        CampanhaDeFases<RaliPage>,
        SingleTickerProviderStateMixin {
  Dificuldade? _dificuldade;
  CorridaEngine? _engine;
  late math.Random _rnd;
  List<String> _fila = const [];
  int _idx = 0;
  final _palavra = ProgressoPalavra();

  int _palavrasRun = 0;
  int _turbosRun = 0;

  int _errosTeclas = 0;
  int _charsCertos = 0;
  DateTime? _inicio;
  Duration _pausas = Duration.zero;
  DateTime? _pausaDesde;
  bool _ultimoErrou = false;
  String _feedback = '';

  bool _contagem = false;
  bool _chama = false;

  late final AnimationController _cpuCtrl = AnimationController(vsync: this)
    ..addStatusListener(_cpuCompletou);
  Timer? _relogio; // só pro PPM respirar
  Timer? _chamaTimer;

  @override
  String get jogoId => 'rali';

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
    _relogio?.cancel();
    _chamaTimer?.cancel();
    _cpuCtrl.dispose();
    super.dispose();
  }

  // ---------- campanha ----------

  Duration _intervaloCpu() {
    final base = _dificuldade!.intervaloCpu.inMilliseconds;
    final ms = (base * math.pow(0.92, fase - 1)).round();
    return Duration(milliseconds: math.max(1800, ms));
  }

  void _comecarRun(Dificuldade d) {
    setState(() {
      _dificuldade = d;
      _rnd = math.Random(widget.semente);
      zerarCampanha();
      _palavrasRun = 0;
      _turbosRun = 0;
      _errosTeclas = 0;
      _charsCertos = 0;
      _inicio = null;
      _pausas = Duration.zero;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _cpuCtrl.stop();
    _relogio?.cancel();
    setState(() {
      _engine = CorridaEngine(pista: 12, dificuldade: _dificuldade!);
      // fase 3 em diante entram as palavras compridas (StatelessWidget…)
      _fila = baralhoRaliDe(_rnd, comLongas: fase >= 3);
      _idx = 0;
      _palavra.carregar(_fila[0]);
      _ultimoErrou = false;
      _feedback = '';
      _chama = false;
      _contagem = true;
    });
  }

  void _largada() {
    if (!mounted || acabou || _engine == null) return;
    setState(() {
      _contagem = false;
      _inicio ??= DateTime.now();
    });
    _cpuCtrl.duration = _intervaloCpu();
    _cpuCtrl.forward(from: 0);
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !acabou && !faseVencida && !pausado) setState(() {});
    });
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
    _pausaDesde = DateTime.now();
  }

  @override
  void aoRetomar() {
    final desde = _pausaDesde;
    if (desde != null) _pausas += DateTime.now().difference(desde);
    _pausaDesde = null;
    if (_engine == null || acabou || faseVencida) return;
    _cpuCtrl.forward();
  }

  void _acumula(CorridaEngine e) {
    _palavrasRun += e.acertos;
    _turbosRun += e.turbos;
  }

  void _venceuFase() {
    _cpuCtrl.stop();
    _relogio?.cancel();
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
    _relogio?.cancel();
    if (somaFaseAtual) _acumula(_engine!);
    return encerrar(somaFaseAtual: somaFaseAtual);
  }

  /// Palavras por minuto (5 toques = 1 palavra), descontando as pausas.
  int get _ppm {
    final ini = _inicio;
    if (ini == null) return 0;
    var pausas = _pausas;
    final desde = _pausaDesde;
    if (desde != null) pausas += DateTime.now().difference(desde);
    final min = (DateTime.now().difference(ini) - pausas).inMilliseconds / 60000.0;
    if (min <= 0) return 0;
    return (_charsCertos / 5 / min).round();
  }

  void _tecla(String ch) {
    final e = _engine;
    if (e == null || acabou || faseVencida || pausado || _contagem || ch.trim().isEmpty) return;
    final certa = _palavra.teclar(ch);
    if (!certa) {
      Sons.toca(Som.erro);
      setState(() {
        _errosTeclas++;
        _ultimoErrou = true;
      });
      return;
    }
    setState(() {
      _charsCertos++;
      _ultimoErrou = false;
      if (_feedback.isNotEmpty && _palavra.idx == 1) _feedback = '';
      if (_palavra.completa) {
        final perfeita = _palavra.errosPalavra == 0;
        e.responder(certa: true, turbo: perfeita);
        Sons.toca(perfeita ? Som.turbo : Som.blip);
        _feedback = perfeita ? '🔥 Palavra perfeita — TURBO!' : '⚡ Acelerou!';
        _chama = perfeita;
        _idx++;
        _palavra.carregar(_fila[_idx % _fila.length]);
      }
    });
    if (_chama) {
      _chamaTimer?.cancel();
      _chamaTimer = Timer(const Duration(milliseconds: 1100), () {
        if (mounted) setState(() => _chama = false);
      });
    }
    if (e.terminou) {
      e.venceu ? _venceuFase() : _fimDeJogo();
    }
  }

  // ---------- telas ----------

  @override
  Widget build(BuildContext context) {
    final e = _engine;
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        onKeyEvent: (_, ev) => teclaDePausa(ev) ? KeyEventResult.handled : KeyEventResult.ignored,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Stack(children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    CabecalhoJogo(
                      rotulo: 'ARCADE · DIGITAÇÃO',
                      titulo: '🏁 Rali de Digitação',
                      chips: e == null
                          ? const []
                          : [
                              ChipPlacar('FASE', '$fase'),
                              ChipPlacar('TOTAL', '$pontosParciais', cor: Mixart.brand),
                              ChipPlacar('PPM', '$_ppm'),
                              ChipPlacar('ERROS', '$_errosTeclas',
                                  cor: _ultimoErrou ? Mixart.danger : null),
                            ],
                      acao: e == null ? null : BotaoPausa(onTap: podePausar ? pausar : null),
                    ),
                    const SizedBox(height: 16),
                    if (e == null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Mixart.brandSub,
                          border: Border.all(color: Mixart.brandDim),
                          borderRadius: BorderRadius.circular(Mixart.radiusMd),
                        ),
                        child: Text(
                          'Digite a palavra para ACELERAR: palavra completa é um passo, '
                          'sem nenhum erro é TURBO (anda 2). O medidor sob a CPU mostra '
                          'quando ela vai andar. Venceu? Vem outra fase com cenário novo e '
                          'CPU mais rápida — e os pontos vão somando até a CPU te pegar. '
                          'Palavras compridas entram na fase 3! Esc pausa.',
                          style: Mixart.ui(size: 13, color: Mixart.text).copyWith(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SeletorDificuldade(onEscolher: _comecarRun),
                    ] else ...[
                      PistaPro(
                        posJogador: e.posJogador,
                        posCpu: e.posCpu,
                        pista: e.pista,
                        fase: fase,
                        turbo: _chama,
                        cargaCpu: _cpuCtrl,
                      ),
                      const SizedBox(height: 18),
                      _cartaoPalavra(),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 26,
                        child: Text(
                          _feedback.isNotEmpty
                              ? _feedback
                              : '⌨️ é só digitar — errou, a letra não anda (e conta erro) · Esc pausa',
                          style: _feedback.isNotEmpty
                              ? Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)
                              : Mixart.ui(size: 11.5, color: Mixart.textFaint),
                        ),
                      ),
                      CampoTeclas(onChar: _tecla),
                    ],
                  ],
                ),
                if (_contagem)
                  ContagemRegressiva(
                    onFim: _largada,
                    legenda: '${emojiDaFase(fase)} FASE $fase · ${nomeDaFase(fase)} — dedos a postos',
                  ),
                if (pausado)
                  PausaOverlay(onContinuar: retomar, onSair: () => Navigator.of(context).pop()),
                if (faseVencida)
                  FaseVencida(
                    fase: fase,
                    pontosFase: comFator(pontosDoMotor),
                    pontosTotal: pontosTotal,
                    dica: dicaDaFase(fase),
                    aviso: fase + 1 == 3
                        ? 'a CPU acelera e entram as palavras COMPRIDAS!'
                        : 'a CPU fica ainda mais rápida!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                  ),
                if (acabou && e != null)
                  FimDeJogo(
                    emoji: fasesVencidas > 0 ? '🏆' : '🤖',
                    titulo: fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'A CPU VENCEU…',
                    subtitulo: fasesVencidas > 0
                        ? 'Você venceu $fasesVencidas fase${fasesVencidas > 1 ? 's' : ''} e digitou $_palavrasRun palavras.'
                        : 'Palavra perfeita dá TURBO — capriche e tente de novo!',
                    pontos: pontosTotal,
                    novoRecorde: novoRecorde,
                    celebrar: fasesVencidas > 0,
                    noRanking: ranking != null,
                    stats: [
                      ('FASES', '$fasesVencidas'),
                      ('PALAVRAS', '$_palavrasRun'),
                      ('TURBOS', '$_turbosRun'),
                      ('PPM', '$_ppm'),
                      ('ERROS', '$_errosTeclas'),
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

  Widget _cartaoPalavra() {
    final alvo = _palavra.alvo;
    final idx = _palavra.idx;
    final proximas = [
      for (var k = 1; k <= 2; k++) _fila[(_idx + k) % _fila.length],
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(
            color: _ultimoErrou ? Mixart.danger : Mixart.border, width: _ultimoErrou ? 1.6 : 1),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(children: [
        Text('PALAVRA ${_idx + 1}',
            style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.textFaint)
                .copyWith(letterSpacing: 2)),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            TextSpan(
              text: alvo.substring(0, idx),
              style: TextStyle(color: Mixart.brand, fontWeight: FontWeight.w700),
            ),
            if (idx < alvo.length)
              TextSpan(
                text: alvo[idx],
                style: TextStyle(
                  color: _ultimoErrou ? Colors.white : Mixart.text,
                  backgroundColor: _ultimoErrou ? Mixart.danger : Mixart.brandSub,
                ),
              ),
            if (idx + 1 < alvo.length)
              TextSpan(text: alvo.substring(idx + 1), style: TextStyle(color: Mixart.textMuted)),
          ]),
          style: Mixart.mono(size: 30).copyWith(letterSpacing: 1.5, height: 1.2),
        ),
        const SizedBox(height: 12),
        // a fila à vista: quem lê na frente digita sem tropeçar
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('a seguir: ', style: Mixart.ui(size: 11, color: Mixart.textFaint)),
          for (final p in proximas) ...[
            Text(p, style: Mixart.mono(size: 12.5, color: Mixart.textMuted)),
            if (p != proximas.last)
              Text('  ·  ', style: Mixart.ui(size: 11, color: Mixart.textFaint)),
          ],
        ]),
      ]),
    );
  }
}
