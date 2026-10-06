import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/palavras_csharp.dart';
import 'banco_arcade.dart';
import '../domain/personagem.dart';
import '../domain/tiro_engine.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/avatares.dart';
import 'widgets/campanha.dart';
import 'widgets/campo_teclas.dart';
import 'widgets/cenario.dart';
import 'widgets/perspectiva.dart';

/// ☄️ Chuva de Código — palavras do Dart caem do céu; digite a primeira
/// letra pra travar a mira e cada letra certa sai como TIRO da boca do Pac.
/// Palavra que toca o chão custa uma vida (são 3). Douradas valem 4x.
/// COMBO de palavras sem erro multiplica os pontos (x2 aos 5, x3 aos 10).
/// Largada 3-2-1, palavra explode em estilhaços, chão treme ao perder vida,
/// mira desenhada até o alvo, Esc pausa.
class ChuvaPage extends StatefulWidget {
  /// Semente do sorteio (fixa nos testes; null = aleatório de verdade).
  final int? semente;
  const ChuvaPage({super.key, this.semente});

  @override
  State<ChuvaPage> createState() => _ChuvaPageState();
}

/// Tiro voando do Pac até a palavra (coordenadas em fração da arena).
class _Tiro {
  final double x1, y1;
  double t = 0;
  _Tiro(this.x1, this.y1);
}

/// Aviso de pontos que sobe quando a palavra explode.
class _Premio {
  final double x, y;
  final String texto;
  final bool ouro;
  double t = 0;
  _Premio(this.x, this.y, this.texto, this.ouro);
}

/// Estilhaços da palavra destruída (vivem ~0,6s).
class _Explosao {
  final double x, y;
  final bool ouro;
  final int semente;
  double t = 0;
  _Explosao(this.x, this.y, this.ouro, this.semente);
}

class _ChuvaPageState extends State<ChuvaPage>
    with WidgetsBindingObserver, PausaDeJogo<ChuvaPage>, SingleTickerProviderStateMixin {
  RankingCubit? _ranking;
  late TiroEngine _engine = _novoEngine();
  late final Ticker _ticker = createTicker(_tick);

  /// Motor com as palavras da vertente em uso (Dart ou C#).
  TiroEngine _novoEngine() {
    final v = vocabularioDe();
    return TiroEngine(rnd: math.Random(widget.semente), curtas: v.curtas, medias: v.medias, longas: v.longas);
  }
  Duration _ultimo = Duration.zero;

  final List<_Tiro> _tiros = [];
  final List<_Premio> _premios = [];
  final List<_Explosao> _explosoes = [];
  int _flashErro = 0; // frames restantes do aviso de tecla errada
  double _chaoFlash = 0; // segundos restantes do chão vermelho (palavra caiu)
  int _tremor = 0; // sacode a arena a cada vida perdida

  /// Aviso no topo da arena ("NÍVEL 2 — Deserto…", "COMBO x2"), some sozinho.
  String _aviso = '';
  double _avisoTempo = 0;

  /// Largada 3-2-1 (nada cai ainda).
  bool _contagem = true;
  bool _acabou = false;
  bool _novoRecorde = false;
  bool _pontuado = false;

  @override
  bool get podePausar => !_contagem && !_acabou;

  @override
  void initState() {
    super.initState();
    _ranking = RankingCubit.de(context);
    PersonagemStore.carregar().then((_) {
      if (mounted) setState(() {});
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    // fechou no meio: o que já foi destruído vale ponto mesmo assim
    if (!_pontuado && _engine.pontos > 0) _ranking?.arcadeJogado('chuva', _engine.pontos);
    super.dispose();
  }

  void _reiniciar() {
    setState(() {
      _engine = _novoEngine();
      _tiros.clear();
      _premios.clear();
      _explosoes.clear();
      _flashErro = 0;
      _chaoFlash = 0;
      _aviso = '';
      _avisoTempo = 0;
      _contagem = true;
      _acabou = false;
      _novoRecorde = false;
      _pontuado = false;
      pausado = false;
    });
  }

  void _largada() {
    if (!mounted || _acabou) return;
    setState(() => _contagem = false);
    pausarSeEscondido();
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _ultimo).inMicroseconds / 1e6;
    _ultimo = elapsed;
    if (_acabou || !mounted || _contagem || pausado) return;
    if (dt > 0.1) dt = 0.1; // aba dormiu: não deixa tudo despencar de uma vez
    final nivelAntes = _engine.nivel;
    final vidasAntes = _engine.vidas;
    setState(() {
      _engine.tick(dt);
      if (_engine.vidas < vidasAntes) {
        Sons.toca(Som.defesa);
        _tremor++;
        _chaoFlash = .7;
      }
      if (_engine.nivel != nivelAntes) {
        Sons.toca(Som.fase);
        // passou de nível: cenário novo lá atrás + aviso na tela
        _mostraAviso(
            '${emojiDaFase(_engine.nivel)} NÍVEL ${_engine.nivel} — ${nomeDaFase(_engine.nivel)}!',
            2.8);
      }
      if (_avisoTempo > 0) _avisoTempo -= dt;
      if (_chaoFlash > 0) _chaoFlash -= dt;
      for (final t in _tiros) {
        t.t += dt * 6;
      }
      _tiros.removeWhere((t) => t.t >= 1);
      for (final p in _premios) {
        p.t += dt * 1.4;
      }
      _premios.removeWhere((p) => p.t >= 1);
      for (final x in _explosoes) {
        x.t += dt / .7;
      }
      _explosoes.removeWhere((x) => x.t >= 1);
      if (_flashErro > 0) _flashErro--;
    });
    if (_engine.fim) _fim();
  }

  void _mostraAviso(String texto, double segundos) {
    _aviso = texto;
    _avisoTempo = segundos;
  }

  void _tecla(String ch) {
    if (_acabou || _contagem || pausado || ch.trim().isEmpty) return;
    final multAntes = _engine.multiplicador;
    final (resultado, palavra) = _engine.teclar(ch);
    setState(() {
      switch (resultado) {
        case TiroResultado.avancou:
          _tiros.add(_Tiro(palavra!.x, palavra.y));
          Sons.toca(Som.tiro);
        case TiroResultado.destruiu:
          _tiros.add(_Tiro(palavra!.x, palavra.y));
          _premios.add(_Premio(palavra.x, palavra.y, '+${_engine.ultimoGanho}', palavra.ouro));
          _explosoes.add(_Explosao(palavra.x, palavra.y, palavra.ouro, palavra.id));
          Sons.toca(Som.explosao);
          if (_engine.multiplicador > multAntes) {
            Sons.toca(Som.combo);
            _mostraAviso('🔥 COMBO x${_engine.multiplicador} — pontos multiplicados!', 2.2);
          }
        case TiroResultado.errou:
          _flashErro = 10;
          Sons.toca(Som.erro);
          if (multAntes > 1) _mostraAviso('💔 Combo perdido', 1.4);
        case TiroResultado.nada:
          break;
      }
    });
  }

  Future<void> _fim() async {
    if (_pontuado) return;
    _pontuado = true;
    setState(() {
      _acabou = true;
      _tiros.clear();
      pausado = false;
    });
    Sons.toca(Som.defesa);
    final recorde = await _ranking?.arcadeJogado('chuva', _engine.pontos);
    if (mounted && recorde == true) setState(() => _novoRecorde = true);
  }

  String get _comboTexto {
    final e = _engine;
    return switch (e.multiplicador) {
      3 => 'x3 🔥',
      2 => 'x2 · ${e.combo}',
      _ => '${e.combo}/5',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Focus(
        onKeyEvent: (_, ev) => teclaDePausa(ev) ? KeyEventResult.handled : KeyEventResult.ignored,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Stack(children: [
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                    child: CabecalhoJogo(
                      rotulo: 'ARCADE · DIGITAÇÃO',
                      titulo: BancoArcade.soDigitacao ? '☄️ Chuva de Palavras' : '☄️ Chuva de Código',
                      chips: [
                        ChipPlacar('VIDAS', '❤️' * _engine.vidas + '·' * (3 - _engine.vidas)),
                        ChipPlacar('NÍVEL', '${_engine.nivel}'),
                        ChipPlacar('COMBO', _comboTexto,
                            cor: _engine.multiplicador > 1 ? Mixart.brand : null),
                        ChipPlacar('PONTOS', '${_engine.pontos}', cor: Mixart.brand),
                        ChipPlacar('ERROS', '${_engine.erros}',
                            cor: _flashErro > 0 ? Mixart.danger : null),
                      ],
                      acao: BotaoPausa(onTap: podePausar ? pausar : null),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Tremor(gatilho: _tremor, child: _arena()),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      '⌨️ digite a 1ª letra pra travar a mira — cada letra certa é um tiro. '
                      'Douradas valem 4x · 5 palavras sem erro = COMBO x2 · Esc pausa',
                      textAlign: TextAlign.center,
                      style: Mixart.ui(size: 11.5, color: Mixart.textFaint),
                    ),
                  ),
                  CampoTeclas(onChar: _tecla),
                ]),
                if (_contagem)
                  ContagemRegressiva(
                    onFim: _largada,
                    grito: 'VAI!',
                    legenda: 'digite a 1ª letra pra travar a mira',
                  ),
                if (pausado)
                  PausaOverlay(onContinuar: retomar, onSair: () => Navigator.of(context).pop()),
                if (_acabou)
                  FimDeJogo(
                    emoji: _engine.destruidas >= 24 ? '🏆' : '☄️',
                    titulo: _engine.destruidas >= 24 ? 'CHUVA DOMINADA!' : 'FIM DE JOGO',
                    subtitulo:
                        'Você destruiu ${_engine.destruidas} palavras e chegou ao nível ${_engine.nivel}.',
                    pontos: _engine.pontos,
                    novoRecorde: _novoRecorde,
                    celebrar: _novoRecorde,
                    noRanking: _ranking != null,
                    stats: [
                      ('PALAVRAS', '${_engine.destruidas}'),
                      ('NÍVEL', '${_engine.nivel}'),
                      ('MELHOR COMBO', '${_engine.melhorCombo}'),
                      ('ERROS', '${_engine.erros}'),
                    ],
                    onDeNovo: _reiniciar,
                    onSair: () => Navigator.of(context).pop(),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _arena() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
            color: _flashErro > 0 ? Mixart.danger : Mixart.border,
            width: _flashErro > 0 ? 1.6 : 1),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        // 200 = folga pro chip mais largo (GestureDetector dourado) não vazar
        double px(double x) => x * (w - 200);
        double py(double y) => y * (h - 116);
        final pacX = w / 2;
        final pacY = h - 62;
        final alvo = _engine.alvo;
        final chaoQuente = (_chaoFlash / .7).clamp(0.0, 1.0);

        return Stack(children: [
          // palco 3D da fase (muda a cada nível): céu + chão em perspectiva
          Positioned.fill(child: PalcoFase(fase: _engine.nivel, horizonte: .58)),
          Positioned.fill(child: Container(color: const Color(0x3806070B))),
          // linha do chão (esquenta quando uma palavra cai)
          Positioned(
            left: 12,
            right: 12,
            bottom: 40,
            child: Container(
              height: 1.4 + chaoQuente * 1.6,
              decoration: BoxDecoration(
                color: Color.lerp(Mixart.brandDim, Mixart.danger, chaoQuente),
                boxShadow: chaoQuente > 0
                    ? [BoxShadow(color: Mixart.danger.withValues(alpha: chaoQuente * .6), blurRadius: 10)]
                    : const [],
              ),
            ),
          ),
          // a mira: linha fina do Pac até o alvo travado
          if (alvo != null)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _MiraPainter(
                    de: Offset(pacX, pacY - 14),
                    ate: Offset(px(alvo.x) + 44, py(alvo.y) + 30),
                    cor: alvo.ouro ? Mixart.brand : Mixart.brandDim,
                  ),
                ),
              ),
            ),
          // tiros (da boca do Pac até a palavra), com rastro luminoso
          if (_tiros.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _TirosPainter(
                    tiros: [
                      for (final t in _tiros)
                        (
                          Offset(pacX, pacY - 14),
                          Offset(px(t.x1) + 44, py(t.y1) + 14),
                          t.t,
                        ),
                    ],
                    cor: Mixart.brand,
                  ),
                ),
              ),
            ),
          // palavras caindo
          for (final p in _engine.ativas)
            Positioned(left: px(p.x), top: py(p.y), child: _palavra(p)),
          // estilhaços das destruídas
          for (final x in _explosoes)
            Positioned(
              left: px(x.x) + 44 - 44,
              top: py(x.y) + 16 - 44,
              child: Estilhacos(
                cor: x.ouro ? Mixart.brand : Mixart.text,
                pedacos: x.ouro ? 16 : 11,
                semente: x.semente,
              ),
            ),
          // prêmios subindo
          for (final pr in _premios)
            Positioned(
              left: px(pr.x) + 20,
              top: py(pr.y) - pr.t * 34,
              child: Opacity(
                opacity: (1 - pr.t).clamp(0, 1),
                child: Text('${pr.texto}${pr.ouro ? ' ✨' : ''}',
                    style: Mixart.display(size: 16, color: Mixart.brand)),
              ),
            ),
          // o atirador: seu personagem de boca (ou bico) pra cima, com sombra
          Positioned(
            left: pacX - 30,
            top: pacY + 14,
            child: const Sombra(largura: 60, altura: 16, opacidade: .45),
          ),
          Positioned(
            left: pacX - 23,
            top: pacY - 23,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: const IgnorePointer(child: AvatarPersonagem(tamanho: 46)),
            ),
          ),
          // aviso (nível novo, combo)
          if (_avisoTempo > 0)
            Positioned(
              top: 14,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xE010131A),
                    border: Border.all(color: Mixart.brandDim),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(_aviso, style: Mixart.display(size: 14, color: Mixart.brand)),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  Widget _palavra(PalavraCaindo p) {
    final ehAlvo = _engine.alvoId == p.id;
    final perigo = !ehAlvo && p.y > .78;
    final corFundo = p.ouro ? Mixart.brand : Mixart.surfaceHi;
    final corTexto = p.ouro ? Mixart.onBrand : Mixart.text;
    final corFeita = p.ouro ? Mixart.onBrand.withValues(alpha: .45) : Mixart.brand;
    final n = p.digitadas;
    final len = p.texto.length;
    final feitas = p.texto.substring(0, n);
    final prox = n < len ? p.texto[n] : '';
    final resto = n + 1 < len ? p.texto.substring(n + 1) : '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ehAlvo
              ? (p.ouro ? Mixart.text : Mixart.brand)
              : perigo
                  ? Mixart.danger
                  : Mixart.border,
          width: ehAlvo ? 2 : 1,
        ),
        boxShadow: [
          // flutua sobre o palco
          const BoxShadow(color: Color(0x80000000), blurRadius: 10, offset: Offset(0, 5)),
          if (ehAlvo) BoxShadow(color: Mixart.brandDim, blurRadius: 12),
          if (perigo) BoxShadow(color: Mixart.danger.withValues(alpha: .35), blurRadius: 10),
        ],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (p.ouro)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Text('4X',
                style: Mixart.ui(size: 9, weight: FontWeight.w800, color: Mixart.onBrand)
                    .copyWith(letterSpacing: 1)),
          ),
        Text.rich(
          TextSpan(children: [
            // já atingidas: preenchem de amarelo (nada de riscar — atrapalha ler)
            TextSpan(
                text: feitas,
                style: TextStyle(color: corFeita, fontWeight: FontWeight.w800)),
            // a próxima letra do alvo ganha um cursor
            TextSpan(
              text: prox,
              style: ehAlvo
                  ? TextStyle(
                      color: p.ouro ? Mixart.brand : Mixart.onBrand,
                      backgroundColor: p.ouro ? Mixart.onBrand : Mixart.brand,
                      fontWeight: FontWeight.w800,
                    )
                  : TextStyle(color: corTexto),
            ),
            TextSpan(text: resto, style: TextStyle(color: corTexto)),
          ]),
          style: Mixart.mono(size: 15.5, weight: FontWeight.w600),
        ),
      ]),
    );
  }
}

/// Tiros com rastro: cabeça brilhante e cauda que esmaece.
class _TirosPainter extends CustomPainter {
  final List<(Offset, Offset, double)> tiros;
  final Color cor;
  _TirosPainter({required this.tiros, required this.cor});

  @override
  void paint(Canvas c, Size s) {
    for (final (de, ate, t) in tiros) {
      final pos = Offset.lerp(de, ate, t)!;
      final cauda = Offset.lerp(de, ate, (t - .14).clamp(0, 1))!;
      c.drawLine(
        cauda,
        pos,
        Paint()
          ..shader = ui.Gradient.linear(cauda, pos, [cor.withValues(alpha: 0), cor.withValues(alpha: .9)])
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(pos, 7, Paint()..color = cor.withValues(alpha: .35)..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5));
      c.drawCircle(pos, 4.2, Paint()..color = cor);
      c.drawCircle(pos - const Offset(1.2, 1.2), 1.6, Paint()..color = Colors.white.withValues(alpha: .9));
    }
  }

  @override
  bool shouldRepaint(_TirosPainter old) => true;
}

/// Linha tracejada e discreta do atirador até a palavra travada.
class _MiraPainter extends CustomPainter {
  final Offset de, ate;
  final Color cor;
  _MiraPainter({required this.de, required this.ate, required this.cor});

  @override
  void paint(Canvas c, Size s) {
    final tinta = Paint()
      ..color = cor.withValues(alpha: .55)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final total = (ate - de).distance;
    if (total < 1) return;
    final dir = (ate - de) / total;
    const traco = 7.0, vao = 6.0;
    for (double d = 0; d < total; d += traco + vao) {
      final fim = math.min(d + traco, total);
      c.drawLine(de + dir * d, de + dir * fim, tinta);
    }
  }

  @override
  bool shouldRepaint(_MiraPainter old) => old.de != de || old.ate != ate || old.cor != cor;
}
