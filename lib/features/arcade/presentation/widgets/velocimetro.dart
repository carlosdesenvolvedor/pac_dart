import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import 'perspectiva.dart';

/// Velocímetro de ponteiro (arco amarelo → vermelho, km/h) — usado no HUD
/// da corrida, tanto sobre a vista 3D quanto na vista em Canvas.
class Velocimetro extends StatelessWidget {
  final double fracao;
  final int kmh;
  final double raio;
  const Velocimetro({super.key, required this.fracao, required this.kmh, this.raio = 46});

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(raio * 2),
        painter: _VelocimetroPainter(fracao: fracao, kmh: kmh),
      );
}

class _VelocimetroPainter extends CustomPainter {
  final double fracao;
  final int kmh;
  _VelocimetroPainter({required this.fracao, required this.kmh});

  @override
  void paint(Canvas c, Size s) => pintarVelocimetro(c, Offset(s.width / 2, s.height / 2), s.width / 2, fracao, kmh);

  @override
  bool shouldRepaint(_VelocimetroPainter old) => old.fracao != fracao || old.kmh != kmh;
}

/// Pinta o velocímetro num canvas qualquer (compartilhado com o painter 2D).
void pintarVelocimetro(Canvas c, Offset centro, double r, double fracao, int kmh) {
  final fr = fracao.clamp(0.0, 1.0);
  c.drawCircle(centro, r, Paint()..color = const Color(0xD910131A));
  c.drawCircle(centro, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white.withValues(alpha: .25));
  const inicio = math.pi * .75;
  const varredura = math.pi * 1.5;
  final rect = Rect.fromCircle(center: centro, radius: r * .8);
  c.drawArc(rect, inicio, varredura, false, Paint()..style = PaintingStyle.stroke..strokeWidth = r * .1..color = Colors.white.withValues(alpha: .12)..strokeCap = StrokeCap.round);
  if (fr > 0) {
    c.drawArc(
      rect,
      inicio,
      varredura * fr,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .1
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.sweep(centro, [Mixart.brand, Mixart.brand, const Color(0xFFFF5252)], [0, .55, .95], TileMode.clamp, inicio, inicio + varredura),
    );
  }
  for (var k = 0; k <= 10; k++) {
    final a = inicio + varredura * k / 10;
    final grande = k % 5 == 0;
    final p1 = centro + Offset(math.cos(a), math.sin(a)) * (r * (grande ? .58 : .64));
    final p2 = centro + Offset(math.cos(a), math.sin(a)) * (r * .7);
    c.drawLine(p1, p2, Paint()..color = Colors.white.withValues(alpha: grande ? .8 : .4)..strokeWidth = grande ? 1.6 : 1);
  }
  final a = inicio + varredura * fr;
  c.drawLine(centro, centro + Offset(math.cos(a), math.sin(a)) * (r * .62),
      Paint()..color = const Color(0xFFFF5252)..strokeWidth = r * .06..strokeCap = StrokeCap.round);
  c.drawCircle(centro, r * .09, Paint()..color = Colors.white);
  pintarTexto(c, '$kmh', centro + Offset(0, r * .28), tamanho: r * .38, cor: Colors.white, peso: FontWeight.w800, espaco: 0);
  pintarTexto(c, 'km/h', centro + Offset(0, r * .58), tamanho: r * .18, cor: Colors.white.withValues(alpha: .6), peso: FontWeight.w600, espaco: 1);
}
