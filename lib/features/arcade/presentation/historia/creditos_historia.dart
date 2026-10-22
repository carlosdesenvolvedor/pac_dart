import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/som/sons.dart';
import '../../../../core/theme/mixart.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import 'elenco_turismo.dart';
import 'roteiro_historia.dart';

/// 🎬 Os créditos do fim da história ("THE END"): o título cresce com a fanfarra e o elenco sobe devagar,
/// uma vez só (sem laço infinito). Com [reduzir], tudo parado e a lista rola na mão. O botão "Concluir ✓"
/// (ou Enter/Espaço) chama [onFim].
class CreditosHistoria extends StatefulWidget {
  const CreditosHistoria({super.key, required this.onFim, this.reduzir = false});

  final VoidCallback onFim;
  final bool reduzir;

  /// O elenco nos créditos: id, nome do papel (EN) e o papel em português.
  static const elenco = [
    ('voce', "Team Star's driver", 'o piloto do Team Star'),
    ('mike', 'Tech lead and navigator', 'tech lead e navegador'),
    ('sarah', 'Product manager and captain', 'product manager e capitã'),
    ('ana', 'Designer and car painter', 'designer e pintora do carro'),
    ('ben', 'Friend and hobby mechanic', 'amigo e mecânico por hobby'),
    ('emma', 'Neighbor and host', 'vizinha e anfitriã'),
    ('lucas', "Ben's apprentice", 'aprendiz do Ben'),
    ('julia', 'The brave sister', 'a irmã corajosa'),
    ('dra-lee', 'Team doctor', 'médica da equipe'),
    ('max', "Team Thunder's driver", 'piloto do Team Thunder'),
    ('kim', 'Tournament announcer', 'locutora do torneio'),
  ];

  @override
  State<CreditosHistoria> createState() => _CreditosHistoriaState();
}

class _CreditosHistoriaState extends State<CreditosHistoria> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(seconds: 18));
  final _rolagem = ScrollController();
  final _foco = FocusNode(debugLabel: 'creditos');
  bool _fechou = false;

  @override
  void initState() {
    super.initState();
    try {
      RoteiroHistoria.tocarSom(Som.fanfarra);
    } catch (_) {}
    if (!widget.reduzir) {
      _anim.addListener(_rolar);
      _anim.forward();
    } else {
      _anim.value = 1;
    }
  }

  void _rolar() {
    if (!_rolagem.hasClients) return;
    final max = _rolagem.position.maxScrollExtent;
    // o título fica 15% do tempo sozinho; depois a lista sobe até o fim
    final k = ((_anim.value - .15) / .85).clamp(0.0, 1.0);
    _rolagem.jumpTo(max * k);
  }

  void _concluir() {
    if (_fechou) return;
    _fechou = true;
    _anim.stop();
    widget.onFim();
  }

  @override
  void dispose() {
    _anim.dispose();
    _rolagem.dispose();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final escala = (largura / 1280).clamp(1.0, 1.4);
    return Focus(
      focusNode: _foco,
      autofocus: true,
      onKeyEvent: (_, e) {
        if (e is KeyDownEvent &&
            (e.logicalKey == LogicalKeyboardKey.enter ||
                e.logicalKey == LogicalKeyboardKey.space ||
                e.logicalKey == LogicalKeyboardKey.numpadEnter ||
                e.logicalKey == LogicalKeyboardKey.escape)) {
          _concluir();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: ColoredBox(
        color: const Color(0xFF0E0E14),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(child: CustomPaint(painter: _EstrelasPainter())),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, child) {
                    final k = widget.reduzir ? 1.0 : Curves.elasticOut.transform((_anim.value / .12).clamp(0.0, 1.0));
                    return Transform.scale(scale: .4 + .6 * k, child: child);
                  },
                  child: Semantics(
                    header: true,
                    label: 'THE END. The Golden Wheel. A Roda de Ouro.',
                    child: ExcludeSemantics(
                      child: Column(
                        children: [
                          Text('🏆', style: TextStyle(fontSize: 40 * escala)),
                          Text(
                            'THE END',
                            style: Mixart.display(size: 44 * escala, weight: FontWeight.w900, color: const Color(0xFFFFC73B))
                                .copyWith(letterSpacing: 6),
                          ),
                          Text(
                            'The Golden Wheel · A Roda de Ouro',
                            textAlign: TextAlign.center,
                            style: Mixart.ui(size: 15 * escala, color: Colors.white70).copyWith(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
                      stops: [0, .08, .9, 1],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: ListView(
                      controller: _rolagem,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      children: [
                        for (final (id, papel, papelPt) in CreditosHistoria.elenco) _linhaElenco(id, papel, papelPt),
                        const SizedBox(height: 24),
                        _linhaTexto('Story and drawings', 'História e desenhos: originais do Paclingo'),
                        _linhaTexto('Voices', 'Vozes da história: voz do sistema'),
                        _linhaTexto('Thank you for playing!', 'Obrigado por jogar!'),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    key: const Key('historia-concluir'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Mixart.brand,
                      foregroundColor: Mixart.onBrand,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
                    ),
                    onPressed: _concluir,
                    child: Text('Concluir ✓', style: Mixart.ui(size: 16, weight: FontWeight.w800, color: Mixart.onBrand)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaElenco(String id, String papel, String papelPt) {
    final ap = ElencoTurismo.de(id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (ap != null)
            SizedBox(
              width: 48,
              height: 48,
              child: RostoPersonagem(aparencia: ap, tamanho: 48),
            ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ElencoTurismo.nomeDe(id) == 'Você' ? 'You' : ElencoTurismo.nomeDe(id),
                    style: Mixart.ui(size: 16, weight: FontWeight.w800, color: Colors.white)),
                Text(papel, style: Mixart.ui(size: 13, color: Colors.white70)),
                Text(papelPt, style: Mixart.ui(size: 12, color: Colors.white38).copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaTexto(String en, String pt) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(en, textAlign: TextAlign.center, style: Mixart.ui(size: 16, weight: FontWeight.w800, color: const Color(0xFFFFC73B))),
            Text(pt, textAlign: TextAlign.center, style: Mixart.ui(size: 13, color: Colors.white70)),
          ],
        ),
      );
}

/// Céu estrelado parado atrás dos créditos.
class _EstrelasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(30);
    final p = Paint()..color = Colors.white;
    for (var i = 0; i < 90; i++) {
      final o = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      p.color = Colors.white.withValues(alpha: .25 + rnd.nextDouble() * .6);
      canvas.drawCircle(o, .6 + rnd.nextDouble() * 1.4, p);
    }
  }

  @override
  bool shouldRepaint(_EstrelasPainter old) => false;
}
