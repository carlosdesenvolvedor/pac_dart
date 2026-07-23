import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/mixart.dart';

/// A marca do PAC·DART: o Pac comendo dois pontos — os mesmos pontos que
/// viram o "·" do nome. Desenhada (não é imagem), então fica nítida em
/// qualquer tamanho e acompanha a paleta.
///
/// Geometria (caixa lógica de 100×100, a mesma dos ícones em `web/`):
/// disco de raio 42 no centro, boca de 54° apontando para a direita, ponto
/// grande em x=76 e ponto menor, mais apagado, em x=93.
class LogoPacDart extends StatelessWidget {
  /// Largura total da marca (o disco ocupa ~84% disso).
  final double tamanho;

  /// Cor da marca (padrão: o amarelo da paleta atual).
  final Color? cor;

  /// Moldura arredondada em volta — a versão "selo", usada nos ícones de app.
  final bool selo;

  const LogoPacDart({super.key, this.tamanho = 38, this.cor, this.selo = false});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: tamanho,
        height: selo ? tamanho : tamanho * 0.84,
        child: CustomPaint(
          painter: _LogoPainter(cor: cor ?? Mixart.brand, selo: selo, fundo: Mixart.surface),
        ),
      );
}

class _LogoPainter extends CustomPainter {
  final Color cor;
  final Color fundo;
  final bool selo;
  _LogoPainter({required this.cor, required this.fundo, required this.selo});

  /// Meia-boca: 27° dá a mordida clássica sem virar "queijo".
  static const _meiaBoca = 27 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()..color = cor;

    if (selo) {
      final k = size.shortestSide / 100;
      final quadro = Rect.fromLTWH(1.5 * k, 1.5 * k, 97 * k, 97 * k);
      final rrect = RRect.fromRectAndRadius(quadro, Radius.circular(24 * k));
      canvas.drawRRect(rrect, Paint()..color = fundo);
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = cor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3 * k,
      );
      _pac(canvas, k, centro: Offset(50 * k, 52 * k), raio: 30 * k, tinta: tinta, pontos: [
        (72.0, 4.4, 1.0),
      ]);
      return;
    }

    // marca solta: a caixa tem 100 de largura por 84 de altura
    final k = size.width / 100;
    _pac(canvas, k, centro: Offset(46 * k, 42 * k), raio: 40 * k, tinta: tinta, pontos: [
      (74.0, 5.5, 1.0),
      (92.0, 3.6, 0.62),
    ]);
  }

  /// Desenha o disco mordido + os pontos sendo comidos.
  void _pac(
    Canvas canvas,
    double k, {
    required Offset centro,
    required double raio,
    required Paint tinta,
    required List<(double, double, double)> pontos, // x, raio, opacidade
  }) {
    canvas.drawArc(
      Rect.fromCircle(center: centro, radius: raio),
      _meiaBoca,
      2 * math.pi - _meiaBoca * 2,
      true,
      tinta,
    );
    for (final (x, r, opacidade) in pontos) {
      canvas.drawCircle(
        Offset(x * k, centro.dy),
        r * k,
        Paint()..color = cor.withValues(alpha: opacidade),
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.cor != cor || old.selo != selo || old.fundo != fundo;
}
