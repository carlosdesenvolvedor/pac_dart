// O balão "COMEÇAR" em cima do nó atual (estilo Duolingo): toca = praticar a lição.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/som/sons.dart';
import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import 'no_3d.dart' show FocoDeTeclado;

class BolhaComecar extends StatefulWidget {
  final String texto;
  final Color cor;
  final VoidCallback onTap;

  const BolhaComecar({super.key, required this.texto, required this.cor, required this.onTap});

  /// Altura total (balão + bico), para quem posiciona.
  static const altura = 44.0;

  @override
  State<BolhaComecar> createState() => _BolhaComecarState();
}

class _BolhaComecarState extends State<BolhaComecar> with SingleTickerProviderStateMixin {
  // flutua de leve (só existe um balão no mapa)
  late final AnimationController _boia =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  bool _foco = false; // anel de foco do teclado

  @override
  void dispose() {
    _boia.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final claro = Mixart.atual.ehClaro;
    final corTexto = claro ? escurecer(widget.cor, quanto: .1) : widget.cor;
    final face = claro ? Colors.white : const Color(0xFF17181B);
    final labio = escurecer(widget.cor, quanto: claro ? .1 : .3);
    final balao = Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.only(bottom: 3),
        decoration: BoxDecoration(color: labio, borderRadius: BorderRadius.circular(13)),
        child: Container(
          height: 33,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: face,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: _foco ? Mixart.text : widget.cor, width: _foco ? 3 : 2),
          ),
          child: Text(
            widget.texto,
            maxLines: 1,
            style: Mixart.ui(size: 13.5, weight: FontWeight.w900, color: corTexto).copyWith(letterSpacing: 1.1),
          ),
        ),
      ),
      CustomPaint(size: const Size(16, 8), painter: _BicoPainter(labio)),
    ]);
    void tocar() {
      Sons.toca(Som.blip);
      widget.onTap();
    }

    return Semantics(
      button: true,
      label: widget.texto,
      child: FocoDeTeclado(
        onAtivar: tocar,
        onFoco: (v) => setState(() => _foco = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tocar,
          // camada própria: a flutuação não repinta o mapa
          child: RepaintBoundary(
            child: AnimatedBuilder(
              animation: _boia,
              builder: (context, child) =>
                  Transform.translate(offset: Offset(0, -2 * math.sin(_boia.value * math.pi)), child: child),
              child: ExcludeSemantics(child: balao),
            ),
          ),
        ),
      ),
    );
  }
}

class _BicoPainter extends CustomPainter {
  final Color cor;
  _BicoPainter(this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = cor);
  }

  @override
  bool shouldRepaint(covariant _BicoPainter old) => old.cor != cor;
}
