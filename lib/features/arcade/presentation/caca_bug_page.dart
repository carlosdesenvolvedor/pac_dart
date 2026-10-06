import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import 'banco_arcade.dart';
import '../domain/baralho.dart';
import '../domain/caca_bug_engine.dart';
import '../domain/desafio.dart';
import '../domain/dicas_dart.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/campanha.dart';
import 'widgets/cenario.dart';

/// 🐞 Caça-Bug — campanha em FASES de 8 rodadas: ache a linha defeituosa
/// antes de o relógio zerar. 5+ bugs caçados avançam de fase — o cenário
/// muda, os bugs sobem de nível e o relógio fica 10% mais apressado. Bug
/// esmagado estilhaça, linha errada sacode, Esc pausa. Pontos acumulam.
class CacaBugPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const CacaBugPage({super.key, this.semente});

  @override
  State<CacaBugPage> createState() => _CacaBugPageState();
}

class _CacaBugPageState extends State<CacaBugPage>
    with WidgetsBindingObserver, PausaDeJogo<CacaBugPage>, CampanhaDeFases<CacaBugPage> {
  static const _rodadas = 8;
  static const _paraPassar = 5;

  late math.Random _rnd;
  late BaralhoBugs _baralho;
  late CacaBugEngine _engine;
  late DesafioBug _bug;
  int _numRodada = 1;
  int _tempoTotal = 14;
  int _restante = 14;

  int _acertosRun = 0;

  bool _revelado = false;
  bool _acertou = false;
  int? _linhaEscolhida;
  int _ganho = 0;

  /// Sacode o código quando a linha escolhida estava sã (ou o bug escapou).
  int _tremor = 0;

  Timer? _relogio;
  Timer? _avanco;

  @override
  String get jogoId => 'cacaBug';

  @override
  int get pontosDoMotor => _engine.pontos;

  @override
  bool get emPartida => true;

  @override
  void initState() {
    super.initState();
    _comecarRun();
  }

  @override
  void dispose() {
    _relogio?.cancel();
    _avanco?.cancel();
    super.dispose();
  }

  // ---------- campanha ----------

  void _comecarRun() {
    _rnd = math.Random(widget.semente);
    _baralho = BaralhoBugs(rnd: _rnd, banco: BancoArcade.bugs(context));
    setState(() {
      zerarCampanha();
      _acertosRun = 0;
    });
    _comecarFase();
  }

  void _comecarFase() {
    _relogio?.cancel();
    _avanco?.cancel();
    _engine = CacaBugEngine(rodadas: _baralho.sortear(_rodadas, fase));
    setState(() => _carregaRodada(1));
    _relogio = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    pausarSeEscondido();
  }

  void _venceuFase() {
    _relogio?.cancel();
    _avanco?.cancel();
    _acertosRun += _engine.acertos;
    registrarFaseVencida();
  }

  void _proximaFase() {
    avancarFase();
    _comecarFase();
  }

  Future<void> _fimDeJogo({bool somaFaseAtual = true}) {
    if (pontuado) return Future.value();
    _relogio?.cancel();
    _avanco?.cancel();
    if (somaFaseAtual) _acertosRun += _engine.acertos;
    return encerrar(somaFaseAtual: somaFaseAtual);
  }

  // ---------- rodadas ----------

  /// Lê a rodada ATUAL do engine para o estado da tela (o relógio aperta
  /// 10% por fase).
  void _carregaRodada(int numero) {
    _bug = _engine.atual;
    _numRodada = numero;
    _tempoTotal = (_engine.tempoRodada.inSeconds * math.pow(0.9, fase - 1))
        .round()
        .clamp(4, 20);
    _restante = _tempoTotal;
    _revelado = false;
    _acertou = false;
    _linhaEscolhida = null;
    _ganho = 0;
  }

  void _tick() {
    if (pausado || _revelado || acabou || faseVencida) return;
    setState(() => _restante--);
    if (_restante > 0) return;
    // relógio zerou: o bug escapou
    Sons.toca(Som.erro);
    setState(() {
      _engine.estourouTempo();
      _revelado = true;
      _acertou = false;
      _linhaEscolhida = null;
      _tremor++;
    });
    _agendaProxima(const Duration(milliseconds: 2600));
  }

  void _escolher(int linha) {
    if (_revelado || acabou || faseVencida || pausado) return;
    final sobra = _restante;
    setState(() {
      _acertou = _engine.escolher(linha, sobra);
      _ganho = _acertou ? 10 + sobra : 0;
      _linhaEscolhida = linha;
      _revelado = true;
      if (!_acertou) _tremor++;
    });
    Sons.toca(_acertou ? Som.explosao : Som.erro);
    _agendaProxima(Duration(milliseconds: _acertou ? 1400 : 2600));
  }

  void _agendaProxima(Duration espera) {
    _avanco = Timer(espera, () {
      if (!mounted) return;
      if (_engine.terminou) {
        _engine.acertos >= _paraPassar ? _venceuFase() : _fimDeJogo();
      } else {
        setState(() => _carregaRodada(_numRodada + 1));
      }
    });
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (teclaDePausa(e)) return KeyEventResult.handled;
    if (e is! KeyDownEvent || pausado) return KeyEventResult.ignored;
    const teclas = [
      [LogicalKeyboardKey.digit1, LogicalKeyboardKey.numpad1],
      [LogicalKeyboardKey.digit2, LogicalKeyboardKey.numpad2],
      [LogicalKeyboardKey.digit3, LogicalKeyboardKey.numpad3],
      [LogicalKeyboardKey.digit4, LogicalKeyboardKey.numpad4],
      [LogicalKeyboardKey.digit5, LogicalKeyboardKey.numpad5],
      [LogicalKeyboardKey.digit6, LogicalKeyboardKey.numpad6],
      [LogicalKeyboardKey.digit7, LogicalKeyboardKey.numpad7],
      [LogicalKeyboardKey.digit8, LogicalKeyboardKey.numpad8],
      [LogicalKeyboardKey.digit9, LogicalKeyboardKey.numpad9],
    ];
    for (var i = 0; i < teclas.length && i < _bug.linhas.length; i++) {
      if (teclas[i].contains(e.logicalKey)) {
        _escolher(i);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
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
                      rotulo: 'ARCADE · ATENÇÃO',
                      titulo: '🐞 Caça-Bug',
                      chips: [
                        ChipPlacar('FASE', '$fase'),
                        ChipPlacar('RODADA', '$_numRodada/$_rodadas'),
                        ChipPlacar('CAÇADOS', '${_engine.acertos}'),
                        ChipPlacar('TOTAL', '$pontosParciais', cor: Mixart.brand),
                      ],
                      acao: BotaoPausa(onTap: podePausar ? pausar : null),
                    ),
                    const SizedBox(height: 14),
                    _faixaCenario(),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Mixart.brandSub,
                        border: Border.all(color: Mixart.brandDim),
                        borderRadius: BorderRadius.circular(Mixart.radiusMd),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('🎯', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Missão: ${_bug.missao}.\nUma linha estraga tudo — clique nela! '
                            '(cace $_paraPassar+ bugs pra avançar de fase)',
                            style: Mixart.ui(size: 13.5, weight: FontWeight.w600)
                                .copyWith(height: 1.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SeloNivel(_bug.nivel),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    BarraTempo(restante: _restante, total: _tempoTotal, urgenteAte: 3),
                    const SizedBox(height: 14),
                    Tremor(gatilho: _tremor, child: _Monitor(child: _codigo())),
                    const SizedBox(height: 12),
                    SizedBox(height: 58, child: _veredito()),
                  ],
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
                        ? 'bugs de nível 2 entram na jogada e o relógio aperta 10%!'
                        : fase == 2
                            ? 'chegam os bugs de nível 3 — e o relógio aperta mais 10%!'
                            : 'o relógio fica 10% mais apressado — olho vivo!',
                    onProxima: _proximaFase,
                    onParar: () => _fimDeJogo(somaFaseAtual: false),
                  ),
                if (acabou)
                  FimDeJogo(
                    emoji: fasesVencidas > 0 ? '🏆' : '🐞',
                    titulo: fasesVencidas > 0 ? 'FIM DA CAMPANHA!' : 'OS BUGS ESCAPARAM…',
                    subtitulo:
                        'Você esmagou $_acertosRun bugs — cace $_paraPassar+ por fase pra seguir viagem.',
                    pontos: pontosTotal,
                    novoRecorde: novoRecorde,
                    celebrar: fasesVencidas > 0,
                    noRanking: ranking != null,
                    stats: [
                      ('FASES', '$fasesVencidas'),
                      ('CAÇADOS', '$_acertosRun'),
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

  /// Faixa fina de cenário: mostra o mundo da fase atual.
  Widget _faixaCenario() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: SizedBox(
        height: 96,
        child: Stack(children: [
          Positioned.fill(child: PalcoFase(fase: fase, horizonte: .62, grade: false)),
          Positioned.fill(child: Container(color: const Color(0x2906070B))),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xCC10131A),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${emojiDaFase(fase)} FASE $fase · ${nomeDaFase(fase)}',
                style: const TextStyle(
                    color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _codigo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(children: [
        for (var i = 0; i < _bug.linhas.length; i++) _linha(i),
      ]),
    );
  }

  Widget _linha(int i) {
    final ehBug = i == _bug.linhaComBug;
    final escolhidaErrada = _revelado && _linhaEscolhida == i && !ehBug;
    final esmagado = _revelado && ehBug && _acertou;

    Color? fundo;
    Color borda = Colors.transparent;
    if (_revelado && ehBug) {
      fundo = _acertou ? Mixart.brandSub : const Color(0x22F2555A);
      borda = _acertou ? Mixart.brand : Mixart.danger;
    } else if (escolhidaErrada) {
      borda = Mixart.danger;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: fundo ?? Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: _revelado ? null : () => _escolher(i),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: borda),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(clipBehavior: Clip.none, children: [
              Row(children: [
                SizedBox(
                  width: 26,
                  child: Text('${i + 1}',
                      style: Mixart.mono(size: 11.5, color: Mixart.textFaint)),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: CodigoRealcado(_bug.linhas[i], tamanho: 13.5),
                  ),
                ),
                if (_revelado && ehBug)
                  Text(_acertou ? '🐞 +$_ganho pts' : '🐞 era aqui',
                      style: Mixart.ui(
                          size: 11.5,
                          weight: FontWeight.w700,
                          color: _acertou ? Mixart.brand : Mixart.danger)),
              ]),
              // 💥 o bug estilhaça na linha esmagada
              if (esmagado)
                Positioned(
                  left: -30,
                  top: -32,
                  child: Estilhacos(cor: Mixart.brand, alcance: 40, semente: i),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _veredito() {
    if (!_revelado) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text('⌨️ os números 1–${_bug.linhas.length} escolhem a linha · Esc pausa',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
      );
    }
    final titulo = _acertou
        ? '🎉 Bug esmagado!'
        : (_linhaEscolhida == null ? '⏱ O bug escapou pelo relógio!' : '❌ Essa linha estava sã.');
    return Align(
      alignment: Alignment.topLeft,
      child: Text('$titulo ${_bug.explica}',
          style: Mixart.ui(
                  size: 12.5,
                  weight: FontWeight.w600,
                  color: _acertou ? Mixart.brand : Mixart.danger)
              .copyWith(height: 1.4),
          maxLines: 3,
          overflow: TextOverflow.ellipsis),
    );
  }
}

/// O trecho de código num MONITOR com profundidade: moldura metálica com
/// luz, tela com reflexo e scanlines sutis, LED e pé — o bug mora dentro.
class _Monitor extends StatelessWidget {
  final Widget child;
  const _Monitor({required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF394049), Color(0xFF232830), Color(0xFF14181E)],
            stops: [0, .55, 1],
          ),
          boxShadow: const [
            BoxShadow(color: Color(0x99000000), blurRadius: 26, offset: Offset(0, 14)),
          ],
          border: Border.all(color: const Color(0xFF4A525C), width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            child: Stack(children: [
              child,
              // reflexo de luz + scanlines por cima da tela (não bloqueia o clique)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _TelaPainter()),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 6),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Text('PAC·${BancoArcade.linguagem == 'C#' ? 'C#' : 'DART'} IDE',
                style: Mixart.ui(size: 8, weight: FontWeight.w700, color: const Color(0xFF8A96A3))
                    .copyWith(letterSpacing: 1.5)),
            const SizedBox(width: 8),
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF57C765),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x9957C765), blurRadius: 6)],
              ),
            ),
          ]),
        ]),
      ),
      // o pé do monitor
      CustomPaint(size: const Size(120, 22), painter: _PeDoMonitorPainter()),
    ]);
  }
}

class _TelaPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    // reflexo diagonal no canto de cima
    final r = Rect.fromLTWH(0, 0, s.width, s.height * .45);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomCenter,
          colors: [Color(0x14FFFFFF), Color(0x00FFFFFF)],
        ).createShader(r),
    );
    // scanlines
    final linha = Paint()..color = const Color(0x0DFFFFFF);
    for (double y = 0; y < s.height; y += 3) {
      c.drawRect(Rect.fromLTWH(0, y, s.width, 1), linha);
    }
  }

  @override
  bool shouldRepaint(_TelaPainter old) => false;
}

class _PeDoMonitorPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final pescoco = Rect.fromLTWH(cx - 12, 0, 24, s.height * .55);
    c.drawRect(
      pescoco,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF4A525C), Color(0xFF2A3038), Color(0xFF4A525C)],
        ).createShader(pescoco),
    );
    final base = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - s.width / 2, s.height * .5, s.width, s.height * .5), const Radius.circular(8));
    c.drawRRect(
      base,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B434C), Color(0xFF1B2026)],
        ).createShader(base.outerRect),
    );
    c.drawOval(
      Rect.fromLTWH(cx - s.width * .7, s.height * .8, s.width * 1.4, s.height * .5),
      Paint()
        ..color = Colors.black.withValues(alpha: .35)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(_PeDoMonitorPainter old) => false;
}
