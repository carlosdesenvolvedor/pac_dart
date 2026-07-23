import 'package:flutter/material.dart';

import '../../../curso/presentation/widgets/pacman.dart';
import '../../domain/personagem.dart';

/// O personagem escolhido, pronto pra entrar em cena (olhando pra DIREITA —
/// o sentido da corrida). Pac é o CustomPainter animado do app; Dash é o
/// passarinho azul do Flutter, desenhado aqui (nada de imagem externa).
class AvatarPersonagem extends StatelessWidget {
  final double tamanho;

  /// null = usa o escolhido em [PersonagemStore.atual].
  final Personagem? personagem;

  const AvatarPersonagem({super.key, required this.tamanho, this.personagem});

  @override
  Widget build(BuildContext context) {
    final p = personagem ?? PersonagemStore.atual;
    return switch (p) {
      Personagem.pac => Pacman(tamanho: tamanho),
      Personagem.dash => CustomPaint(
          size: Size.square(tamanho),
          painter: _DashPainter(),
        ),
    };
  }
}

/// Dash — homenagem ao mascote do Flutter: corpo azul redondo, olhões,
/// topete, biquinho e barriga escura.
class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final cx = w / 2, cy = w / 2;
    final r = w * 0.46;
    final corpoRect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // topete
    final azulEscuro = Paint()..color = const Color(0xFF2196D9);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(cx - r * 0.10, cy - r * 0.95), width: r * 0.55, height: r * 0.45),
        azulEscuro);
    c.drawOval(
        Rect.fromCenter(
            center: Offset(cx + r * 0.28, cy - r * 0.92), width: r * 0.4, height: r * 0.34),
        azulEscuro);

    // corpo com luz
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [Color(0xFF7BD0F5), Color(0xFF43ADE8)],
        ).createShader(corpoRect),
    );

    // barriga escura (só a parte de baixo, recortada pelo corpo)
    c.save();
    c.clipPath(Path()..addOval(corpoRect));
    c.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + r * 0.78), width: r * 1.9, height: r * 1.15),
        Paint()..color = const Color(0xFF3A444E));
    c.restore();

    // asa (à esquerda — o Dash corre pra direita)
    c.drawOval(
        Rect.fromCenter(
            center: Offset(cx - r * 0.78, cy + r * 0.05), width: r * 0.55, height: r * 0.85),
        azulEscuro);

    // olhos grandões
    final branco = Paint()..color = Colors.white;
    final pupila = Paint()..color = const Color(0xFF20262B);
    final brilho = Paint()..color = Colors.white.withValues(alpha: .9);
    c.drawCircle(Offset(cx - r * 0.16, cy - r * 0.22), r * 0.27, branco);
    c.drawCircle(Offset(cx + r * 0.34, cy - r * 0.24), r * 0.30, branco);
    c.drawCircle(Offset(cx - r * 0.10, cy - r * 0.20), r * 0.13, pupila);
    c.drawCircle(Offset(cx + r * 0.41, cy - r * 0.22), r * 0.14, pupila);
    c.drawCircle(Offset(cx - r * 0.06, cy - r * 0.26), r * 0.045, brilho);
    c.drawCircle(Offset(cx + r * 0.45, cy - r * 0.28), r * 0.05, brilho);

    // bico apontando pra direita (claro, pra saltar do corpo)
    final bico = Path()
      ..moveTo(cx + r * 0.20, cy - r * 0.06)
      ..lineTo(cx + r * 0.80, cy + r * 0.10)
      ..lineTo(cx + r * 0.16, cy + r * 0.28)
      ..close();
    c.drawPath(bico, Paint()..color = const Color(0xFFCBD5DB));

    // pezinhos
    final pe = Paint()
      ..color = const Color(0xFF2B333B)
      ..strokeWidth = w * 0.05
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - r * 0.3, cy + r * 0.94), Offset(cx - r * 0.3, cy + r * 1.05), pe);
    c.drawLine(Offset(cx + r * 0.18, cy + r * 0.94), Offset(cx + r * 0.18, cy + r * 1.05), pe);
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}
