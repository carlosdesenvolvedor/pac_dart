import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/som/sons.dart';
import '../../../core/theme/mixart.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/personagem.dart';
import '../domain/tiro_engine.dart';
import 'widgets/arcade_ui.dart';
import 'widgets/avatares.dart';
import 'widgets/campo_teclas.dart';
import 'widgets/cenario.dart';

/// ☄️ Chuva de Código — palavras do Dart caem do céu; digite a primeira
/// letra pra travar a mira e cada letra certa sai como TIRO da boca do Pac.
/// Palavra que toca o chão custa uma vida (são 3). Douradas valem 4x.
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

class _ChuvaPageState extends State<ChuvaPage> with SingleTickerProviderStateMixin {
  RankingCubit? _ranking;
  late TiroEngine _engine = TiroEngine(rnd: math.Random(widget.semente));
  late final Ticker _ticker = createTicker(_tick);
  Duration _ultimo = Duration.zero;

  final List<_Tiro> _tiros = [];
  final List<_Premio> _premios = [];
  int _flashErro = 0; // frames restantes do aviso de tecla errada

  /// Aviso de nível novo ("NÍVEL 2 — Deserto…"), some sozinho.
  String _avisoNivel = '';
  double _avisoTempo = 0;

  bool _acabou = false;
  bool _novoRecorde = false;
  bool _pontuado = false;

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
      _engine = TiroEngine(rnd: math.Random(widget.semente));
      _tiros.clear();
      _premios.clear();
      _flashErro = 0;
      _acabou = false;
      _novoRecorde = false;
      _pontuado = false;
    });
  }

  void _tick(Duration elapsed) {
    var dt = (elapsed - _ultimo).inMicroseconds / 1e6;
    _ultimo = elapsed;
    if (_acabou || !mounted) return;
    if (dt > 0.1) dt = 0.1; // aba dormiu: não deixa tudo despencar de uma vez
    final nivelAntes = _engine.nivel;
    final vidasAntes = _engine.vidas;
    setState(() {
      _engine.tick(dt);
      if (_engine.vidas < vidasAntes) Sons.toca(Som.defesa);
      if (_engine.nivel != nivelAntes) {
        Sons.toca(Som.fase);
        // passou de nível: cenário novo lá atrás + aviso na tela
        _avisoNivel =
            '${emojiDaFase(_engine.nivel)} NÍVEL ${_engine.nivel} — ${nomeDaFase(_engine.nivel)}!';
        _avisoTempo = 2.8;
      }
      if (_avisoTempo > 0) _avisoTempo -= dt;
      for (final t in _tiros) {
        t.t += dt * 6;
      }
      _tiros.removeWhere((t) => t.t >= 1);
      for (final p in _premios) {
        p.t += dt * 1.4;
      }
      _premios.removeWhere((p) => p.t >= 1);
      if (_flashErro > 0) _flashErro--;
    });
    if (_engine.fim) _fim();
  }

  void _tecla(String ch) {
    if (_acabou || ch.trim().isEmpty) return;
    final (resultado, palavra) = _engine.teclar(ch);
    setState(() {
      switch (resultado) {
        case TiroResultado.avancou:
          _tiros.add(_Tiro(palavra!.x, palavra.y));
          Sons.toca(Som.tiro);
        case TiroResultado.destruiu:
          _tiros.add(_Tiro(palavra!.x, palavra.y));
          final ganho = (10 + palavra.texto.length) * (palavra.ouro ? 4 : 1);
          _premios.add(_Premio(palavra.x, palavra.y, '+$ganho', palavra.ouro));
          Sons.toca(Som.explosao);
        case TiroResultado.errou:
          _flashErro = 10;
          Sons.toca(Som.erro);
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
    });
    Sons.toca(Som.defesa);
    final recorde = await _ranking?.arcadeJogado('chuva', _engine.pontos);
    if (mounted && recorde == true) setState(() => _novoRecorde = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Stack(children: [
              Column(children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                  child: CabecalhoJogo(
                    rotulo: 'ARCADE · DIGITAÇÃO',
                    titulo: '☄️ Chuva de Código',
                    chips: [
                      ChipPlacar('VIDAS', '❤️' * _engine.vidas + '·' * (3 - _engine.vidas)),
                      ChipPlacar('NÍVEL', '${_engine.nivel}'),
                      ChipPlacar('PONTOS', '${_engine.pontos}', cor: Mixart.brand),
                      ChipPlacar('ERROS', '${_engine.erros}',
                          cor: _flashErro > 0 ? Mixart.danger : null),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _arena(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    '⌨️ digite a 1ª letra pra travar a mira — cada letra certa é um tiro do Pac. Douradas valem 4x!',
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 11.5, color: Mixart.textFaint),
                  ),
                ),
                CampoTeclas(onChar: _tecla),
              ]),
              if (_acabou)
                FimDeJogo(
                  emoji: _engine.destruidas >= 24 ? '🏆' : '☄️',
                  titulo: _engine.destruidas >= 24 ? 'CHUVA DOMINADA!' : 'FIM DE JOGO',
                  subtitulo:
                      'Você destruiu ${_engine.destruidas} palavras e chegou ao nível ${_engine.nivel}.',
                  pontos: _engine.pontos,
                  novoRecorde: _novoRecorde,
                    celebrar: _novoRecorde,
                  stats: [
                    ('PALAVRAS', '${_engine.destruidas}'),
                    ('NÍVEL', '${_engine.nivel}'),
                    ('ERROS', '${_engine.erros}'),
                  ],
                  onDeNovo: _reiniciar,
                  onSair: () => Navigator.of(context).pop(),
                ),
            ]),
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
        double px(double x) => x * (w - 170);
        double py(double y) => y * (h - 116);
        final pacX = w / 2;
        final pacY = h - 62;

        return Stack(children: [
          // cenário da fase (muda a cada nível) + véu pra leitura
          Positioned.fill(child: CenarioFase(fase: _engine.nivel)),
          Positioned.fill(child: Container(color: const Color(0x4D06070B))),
          // linha do chão
          Positioned(
            left: 12,
            right: 12,
            bottom: 40,
            child: Container(height: 1.4, color: Mixart.brandDim),
          ),
          // tiros (da boca do Pac até a palavra)
          for (final t in _tiros)
            Positioned(
              left: lerpDouble(pacX - 4, px(t.x1) + 44, t.t)!,
              top: lerpDouble(pacY - 14, py(t.y1) + 14, t.t)!,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: Mixart.brand,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Mixart.brandDim, blurRadius: 8)],
                ),
              ),
            ),
          // palavras caindo
          for (final p in _engine.ativas)
            Positioned(left: px(p.x), top: py(p.y), child: _palavra(p)),
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
          // o atirador: seu personagem de boca (ou bico) pra cima
          Positioned(
            left: pacX - 23,
            top: pacY - 23,
            child: Transform.rotate(
              angle: -math.pi / 2,
              child: const IgnorePointer(child: AvatarPersonagem(tamanho: 46)),
            ),
          ),
          // aviso de nível novo
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
                  child: Text(_avisoNivel,
                      style: Mixart.display(size: 14, color: Mixart.brand)),
                ),
              ),
            ),
        ]);
      }),
    );
  }

  Widget _palavra(PalavraCaindo p) {
    final ehAlvo = _engine.alvoId == p.id;
    final corFundo = p.ouro ? Mixart.brand : Mixart.surfaceHi;
    final corTexto = p.ouro ? Mixart.onBrand : Mixart.text;
    final corFeita = p.ouro
        ? Mixart.onBrand.withValues(alpha: .38)
        : Mixart.textHint;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: corFundo,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: ehAlvo ? (p.ouro ? Mixart.text : Mixart.brand) : Mixart.border,
          width: ehAlvo ? 2 : 1,
        ),
        boxShadow: ehAlvo
            ? [BoxShadow(color: Mixart.brandDim, blurRadius: 12)]
            : const [],
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
            TextSpan(
              text: p.texto.substring(0, p.digitadas),
              style: TextStyle(
                color: corFeita,
                decoration: TextDecoration.lineThrough,
                decorationColor: corFeita,
              ),
            ),
            TextSpan(text: p.texto.substring(p.digitadas), style: TextStyle(color: corTexto)),
          ]),
          style: Mixart.mono(size: 15.5, weight: FontWeight.w600),
        ),
      ]),
    );
  }
}
