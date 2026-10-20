// A "estrada" do caminho do PAC·ENGLISH: 10 px de largura, o trecho já percorrido na cor da etapa com
// brilho, o que falta em traços arredondados. Um trecho pode estar "enchendo" (a comemoração da volta).
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';

class TrilhoIngles extends CustomPainter {
  /// Centro de cada item do caminho, de cima para baixo.
  final List<Offset> pontos;

  /// [feitos][i] = o trecho do item i até o i+1 já foi percorrido.
  final List<bool> feitos;
  final Color cor;

  /// O trecho que está enchendo (0–1 em [progressoUltimo]); null = nenhum.
  final int? indiceUltimo;
  final double progressoUltimo;

  /// Modo claro (traços e brilho mais suaves).
  final bool claro;

  const TrilhoIngles({
    required this.pontos,
    required this.feitos,
    required this.cor,
    this.indiceUltimo,
    this.progressoUltimo = 1,
    this.claro = false,
  });

  static const largura = 10.0;

  Path _trecho(Offset a, Offset b) {
    final meioY = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, meioY, b.dx, meioY, b.dx, b.dy);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (pontos.length < 2) return;
    final brilho = Paint()
      ..color = cor.withValues(alpha: claro ? .22 : .35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura + 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final feito = Paint()
      ..color = cor
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura
      ..strokeCap = StrokeCap.round;
    final pendente = Paint()
      ..color = claro ? const Color(0xFFD5D8DE) : const Color(0xFF2A2C31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < pontos.length - 1; i++) {
      final caminho = _trecho(pontos[i], pontos[i + 1]);
      final enchendo = indiceUltimo == i && progressoUltimo < 1;
      if (feitos.length > i && feitos[i] && !enchendo) {
        canvas.drawPath(caminho, brilho);
        canvas.drawPath(caminho, feito);
      } else if (enchendo) {
        _tracejado(canvas, caminho, pendente);
        for (final m in caminho.computeMetrics()) {
          final parte = m.extractPath(0, m.length * progressoUltimo.clamp(0.0, 1.0));
          canvas.drawPath(parte, brilho);
          canvas.drawPath(parte, feito);
        }
      } else {
        _tracejado(canvas, caminho, pendente);
      }
    }
  }

  /// Traços curtos de ponta redonda (parecem pílulas), sem encostar nos nós.
  void _tracejado(Canvas canvas, Path caminho, Paint p) {
    for (final m in caminho.computeMetrics()) {
      const traco = 6.0, passo = 20.0;
      // começa e termina longe do centro do nó (o nó cobre ~32 px)
      var d = 34.0;
      final fim = m.length - 34;
      while (d < fim) {
        canvas.drawPath(m.extractPath(d, math.min(d + traco, fim)), p);
        d += passo;
      }
    }
  }

  @override
  bool shouldRepaint(covariant TrilhoIngles old) =>
      !listEquals(old.pontos, pontos) ||
      !listEquals(old.feitos, feitos) ||
      old.cor != cor ||
      old.indiceUltimo != indiceUltimo ||
      old.progressoUltimo != progressoUltimo ||
      old.claro != claro;
}

/// A estrada usando os tokens da paleta em uso.
TrilhoIngles trilhoDaPaleta({
  required List<Offset> pontos,
  required List<bool> feitos,
  required Color cor,
  int? indiceUltimo,
  double progressoUltimo = 1,
}) =>
    TrilhoIngles(
      pontos: pontos,
      feitos: feitos,
      cor: cor,
      indiceUltimo: indiceUltimo,
      progressoUltimo: progressoUltimo,
      claro: Mixart.atual.ehClaro,
    );
