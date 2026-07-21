import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// Pac-Man que fica sobre o caractere atual, mastigando.
class Pacman extends StatefulWidget {
  final double tamanho;
  final bool venceu;
  const Pacman({super.key, this.tamanho = 22, this.venceu = false});

  @override
  State<Pacman> createState() => _PacmanState();
}

class _PacmanState extends State<Pacman> with TickerProviderStateMixin {
  late final _boca = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))
    ..repeat(reverse: true);
  late final _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  @override
  void didUpdateWidget(covariant Pacman old) {
    super.didUpdateWidget(old);
    if (widget.venceu && !old.venceu) _giro.forward(from: 0);
  }

  @override
  void dispose() {
    _boca.dispose();
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: Listenable.merge([_boca, _giro]),
        builder: (_, child) => Transform.rotate(
          angle: _giro.value * 2 * math.pi,
          child: CustomPaint(
            size: Size.square(widget.tamanho),
            painter: _PacPainter(abertura: .12 + _boca.value * .5),
          ),
        ),
      );
}

class _PacPainter extends CustomPainter {
  final double abertura; // meia-boca em radianos (aprox.)
  _PacPainter({required this.abertura});

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centro = Offset(r, r);
    final tinta = Paint()..color = Mixart.brand;
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: r),
      abertura,
      2 * math.pi - abertura * 2,
      true,
      tinta,
    );
    // olho
    canvas.drawCircle(Offset(r * .92, r * .38), r * .14, Paint()..color = Mixart.bg);
  }

  @override
  bool shouldRepaint(_PacPainter old) => old.abertura != abertura;
}
