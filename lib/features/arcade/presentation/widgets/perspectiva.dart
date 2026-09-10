import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Projeção pseudo-3D de um plano de chão visto por uma câmera que olha pro
/// horizonte (o truque dos jogos de corrida clássicos).
///
/// Distância `d` = 1 é a borda de BAIXO da área; o horizonte fica em
/// [horizonte] px. Um ponto do chão a distância `d` e deslocamento lateral
/// `l` (em meias-larguras do chão perto, ou seja, `l = 1` é a beira da
/// pista na distância 1) cai na tela em
/// `(fugaX + l·meiaLargura/d, horizonte + alturaChao/d)`.
/// Tudo que está a distância `d` aparece com escala `1/d`.
class Perspectiva {
  final double largura;
  final double altura;
  final double horizonte;
  final double fugaX;
  final double meiaLargura;

  const Perspectiva({
    required this.largura,
    required this.altura,
    required this.horizonte,
    required this.meiaLargura,
    double? fugaX,
  }) : fugaX = fugaX ?? largura / 2;

  double get alturaChao => altura - horizonte;

  double y(double d) => horizonte + alturaChao / d;
  double x(double d, double lateral) => fugaX + lateral * meiaLargura / d;
  double escala(double d) => 1 / d;

  /// Ponto do chão.
  Offset ponto(double d, double lateral) => Offset(x(d, lateral), y(d));

  /// Ponto a [alturaRelativa] (em alturas da câmera) acima do chão.
  Offset acima(double d, double lateral, double alturaRelativa) =>
      Offset(x(d, lateral), y(d) - alturaRelativa * alturaChao / d);

  /// Trapézio do chão entre as distâncias [d1] (perto) e [d2] (longe), da
  /// lateral [a] à [b].
  Path faixa(double d1, double d2, double a, double b) => Path()
    ..moveTo(x(d1, a), y(d1))
    ..lineTo(x(d1, b), y(d1))
    ..lineTo(x(d2, b), y(d2))
    ..lineTo(x(d2, a), y(d2))
    ..close();
}

/// Sombra elíptica e macia no chão, sob um personagem/objeto.
class Sombra extends StatelessWidget {
  final double largura;
  final double altura;
  final double opacidade;
  const Sombra({super.key, required this.largura, this.altura = 0, this.opacidade = .38});

  @override
  Widget build(BuildContext context) {
    final h = altura > 0 ? altura : largura * .28;
    return IgnorePointer(
      child: CustomPaint(
        size: Size(largura, h),
        painter: _SombraPainter(opacidade),
      ),
    );
  }
}

class _SombraPainter extends CustomPainter {
  final double opacidade;
  _SombraPainter(this.opacidade);

  @override
  void paint(Canvas c, Size s) {
    c.drawOval(
      Rect.fromLTWH(s.width * .08, s.height * .1, s.width * .84, s.height * .8),
      Paint()
        ..color = Colors.black.withValues(alpha: opacidade)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s.height * .35),
    );
  }

  @override
  bool shouldRepaint(_SombraPainter old) => old.opacidade != opacidade;
}

/// Neblina atmosférica: o que está perto do horizonte clareia (profundidade).
void pintarNeblina(Canvas c, Perspectiva p, Color cor, {double ate = .45}) {
  final r = Rect.fromLTWH(0, p.horizonte, p.largura, p.alturaChao * ate);
  c.drawRect(
    r,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [cor.withValues(alpha: .55), cor.withValues(alpha: 0)],
      ).createShader(r),
  );
}

/// Chão em faixas horizontais alternadas (as linhas de mesma distância são
/// horizontais na tela) — quanto mais perto do horizonte, mais finas: a
/// sensação de profundidade nasce daí. [linha] opcional pinta a divisória
/// de cada faixa (grade neon do Espaço, asfalto molhado da Cidade).
void pintarChaoEmFaixas(
  Canvas c,
  Perspectiva p, {
  required Color claro,
  required Color escuro,
  Color? linha,
  double segmento = .3,
  double ate = 16,
}) {
  c.drawRect(Rect.fromLTWH(0, p.horizonte, p.largura, p.alturaChao), Paint()..color = escuro);
  var i = 0;
  for (var d = 1.0; d < ate; d += segmento, i++) {
    final y1 = p.y(d);
    final y2 = p.y(d + segmento);
    if (y1 - y2 < .6) break;
    c.drawRect(
      Rect.fromLTRB(0, y2, p.largura, y1),
      Paint()..color = i.isEven ? claro : escuro,
    );
    if (linha != null) {
      c.drawLine(Offset(0, y1), Offset(p.largura, y1),
          Paint()
            ..color = linha.withValues(alpha: (.5 / d).clamp(.06, .5))
            ..strokeWidth = 1);
    }
  }
}

/// Linhas que fogem pro ponto de fuga (grade do chão).
void pintarLinhasDeFuga(Canvas c, Perspectiva p, Color cor, {double passo = .35, int n = 7}) {
  for (var k = -n; k <= n; k++) {
    final l = k * passo;
    final perto = Offset(p.x(1, l), p.y(1));
    // prolonga até o horizonte
    final longe = Offset(p.x(60, l), p.y(60));
    c.drawLine(
        perto,
        longe,
        Paint()
          ..color = cor
          ..strokeWidth = 1);
  }
}

/// Faixa quadriculada (largada/chegada) sobre a pista em perspectiva.
void pintarQuadriculado(Canvas c, Perspectiva p, double d, double a, double b,
    {double profundidade = .12, int colunas = 8}) {
  final claro = Paint()..color = Colors.white;
  final escuro = Paint()..color = const Color(0xFF16191E);
  final meio = d + profundidade / 2;
  for (var lin = 0; lin < 2; lin++) {
    final d1 = lin == 0 ? d : meio;
    final d2 = lin == 0 ? meio : d + profundidade;
    for (var col = 0; col < colunas; col++) {
      final la = a + (b - a) * col / colunas;
      final lb = a + (b - a) * (col + 1) / colunas;
      c.drawPath(p.faixa(d1, d2, la, lb), (lin + col).isEven ? claro : escuro);
    }
  }
}

/// Texto pintado direto no canvas (placas, faixas de chegada).
void pintarTexto(Canvas c, String texto, Offset centro,
    {double tamanho = 12, Color cor = Colors.white, FontWeight peso = FontWeight.w800, double espaco = 1}) {
  final tp = TextPainter(
    text: TextSpan(
        text: texto,
        style: TextStyle(color: cor, fontSize: tamanho, fontWeight: peso, letterSpacing: espaco)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centro - Offset(tp.width / 2, tp.height / 2));
}

/// Escurece/clareia uma cor (sombra e luz do mesmo material).
Color tom(Color c, double fator) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness * fator).clamp(0, 1).toDouble()).toColor();
}

/// Ângulo (rad) entre dois pontos — pra alinhar rastros e mira.
double angulo(Offset de, Offset ate) => math.atan2(ate.dy - de.dy, ate.dx - de.dx);
