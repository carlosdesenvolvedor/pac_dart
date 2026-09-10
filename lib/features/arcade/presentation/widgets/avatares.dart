import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/personagem.dart';

/// O personagem escolhido, pronto pra entrar em cena (olhando pra DIREITA —
/// o sentido da corrida), com sombreamento de esfera, brilho e contraluz:
/// cara de boneco 3D, tudo desenhado em CustomPainter (nada de imagem).
class AvatarPersonagem extends StatelessWidget {
  final double tamanho;

  /// null = usa o escolhido em [PersonagemStore.atual].
  final Personagem? personagem;

  const AvatarPersonagem({super.key, required this.tamanho, this.personagem});

  @override
  Widget build(BuildContext context) {
    final p = personagem ?? PersonagemStore.atual;
    return switch (p) {
      Personagem.pac => Pac3D(tamanho: tamanho),
      Personagem.dash => CustomPaint(
          size: Size.square(tamanho),
          painter: _DashPainter(),
        ),
    };
  }
}

/// Pac com volume: esfera iluminada de cima-esquerda, boca com lábio em
/// sombra, brilho especular e olho com reflexo — e mastigando, claro.
class Pac3D extends StatefulWidget {
  final double tamanho;
  const Pac3D({super.key, required this.tamanho});

  @override
  State<Pac3D> createState() => _Pac3DState();
}

class _Pac3DState extends State<Pac3D> with SingleTickerProviderStateMixin {
  late final _boca = AnimationController(vsync: this, duration: const Duration(milliseconds: 280))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _boca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _boca,
        builder: (_, _) => CustomPaint(
          size: Size.square(widget.tamanho),
          painter: _Pac3DPainter(abertura: .12 + _boca.value * .5),
        ),
      );
}

class _Pac3DPainter extends CustomPainter {
  final double abertura;
  _Pac3DPainter({required this.abertura});

  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    final centro = Offset(r, r);
    final rect = Rect.fromCircle(center: centro, radius: r);
    final base = Mixart.brand;
    final hsl = HSLColor.fromColor(base);
    final claro = hsl.withLightness((hsl.lightness + .18).clamp(0, 1)).toColor();
    final escuro = hsl.withLightness((hsl.lightness - .22).clamp(0, 1)).toColor();
    final maisEscuro = hsl.withLightness((hsl.lightness - .36).clamp(0, 1)).toColor();

    final corpo = Path()
      ..moveTo(r, r)
      ..arcTo(rect, abertura, 2 * math.pi - abertura * 2, false)
      ..close();

    // esfera: luz de cima-esquerda, sombra na borda de baixo-direita
    c.drawPath(
      corpo,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.38, -.42),
          radius: .95,
          colors: [claro, base, escuro],
          stops: const [0, .55, 1],
        ).createShader(rect),
    );
    // contraluz fininho na borda (rim light)
    c.drawPath(
      corpo,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .06
        ..color = maisEscuro.withValues(alpha: .55),
    );
    // lábios da boca em sombra (dá profundidade ao corte)
    final labio = Paint()
      ..color = maisEscuro.withValues(alpha: .65)
      ..strokeWidth = r * .09
      ..strokeCap = StrokeCap.round;
    c.drawLine(centro, centro + Offset(math.cos(abertura), math.sin(abertura)) * r * .96, labio);
    c.drawLine(centro, centro + Offset(math.cos(-abertura), math.sin(-abertura)) * r * .96, labio);
    // brilho especular
    c.drawOval(
      Rect.fromCenter(center: Offset(r * .62, r * .5), width: r * .5, height: r * .3),
      Paint()..color = Colors.white.withValues(alpha: .38),
    );
    // olho com reflexo
    c.drawCircle(Offset(r * .95, r * .40), r * .15, Paint()..color = const Color(0xFF1B1F27));
    c.drawCircle(Offset(r * .90, r * .35), r * .05, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_Pac3DPainter old) => old.abertura != abertura;
}

/// Dash — homenagem ao mascote do Flutter: corpo azul redondo com luz,
/// olhões, topete, biquinho, barriga escura, brilho e contraluz.
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

    // corpo com luz (esfera)
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.42),
          radius: .95,
          colors: [Color(0xFFA6E1FB), Color(0xFF55B8EE), Color(0xFF1E7FBF)],
          stops: [0, .55, 1],
        ).createShader(corpoRect),
    );
    // contraluz
    c.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = r * .06
          ..color = const Color(0xFF14557F).withValues(alpha: .5));

    // barriga escura (só a parte de baixo, recortada pelo corpo)
    c.save();
    c.clipPath(Path()..addOval(corpoRect));
    c.drawOval(
        Rect.fromCenter(
            center: Offset(cx, cy + r * 0.78), width: r * 1.9, height: r * 1.15),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4B5763), Color(0xFF2B333B)],
          ).createShader(corpoRect));
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

    // bico apontando pra direita (com sombra embaixo)
    final bico = Path()
      ..moveTo(cx + r * 0.20, cy - r * 0.06)
      ..lineTo(cx + r * 0.80, cy + r * 0.10)
      ..lineTo(cx + r * 0.16, cy + r * 0.28)
      ..close();
    c.drawPath(
        bico,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE6EDF1), Color(0xFFB2BEC6)],
          ).createShader(corpoRect));

    // brilho especular no alto da cabeça
    c.drawOval(
      Rect.fromCenter(center: Offset(cx - r * .3, cy - r * .55), width: r * .5, height: r * .26),
      Paint()..color = Colors.white.withValues(alpha: .35),
    );

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

/// 🤖 O rival: robô metálico com visor e olhos acesos — desenhado com
/// gradientes pra parecer de verdade ao lado dos personagens 3D.
class RoboCpu extends StatelessWidget {
  final double tamanho;
  const RoboCpu({super.key, required this.tamanho});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(tamanho), painter: _RoboPainter());
}

class _RoboPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final cabeca = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .12, w * .18, w * .76, w * .58), Radius.circular(w * .16));
    // antena
    c.drawLine(Offset(w * .5, w * .18), Offset(w * .5, w * .05),
        Paint()
          ..color = const Color(0xFF9AA5B1)
          ..strokeWidth = w * .05
          ..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(w * .5, w * .05), w * .07, Paint()..color = const Color(0xFFFF5252));
    c.drawCircle(Offset(w * .48, w * .035), w * .025, Paint()..color = Colors.white70);
    // orelhas
    final orelha = Paint()..color = const Color(0xFF7A8794);
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .04, w * .36, w * .1, w * .22), Radius.circular(w * .04)),
        orelha);
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .86, w * .36, w * .1, w * .22), Radius.circular(w * .04)),
        orelha);
    // cabeça metálica
    c.drawRRect(
      cabeca,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3E9EF), Color(0xFFAAB6C2), Color(0xFF6E7C8A)],
          stops: [0, .5, 1],
        ).createShader(cabeca.outerRect),
    );
    c.drawRRect(
        cabeca,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .03
          ..color = const Color(0xFF4A5663));
    // visor
    final visor = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .2, w * .3, w * .6, w * .28), Radius.circular(w * .1));
    c.drawRRect(visor, Paint()..color = const Color(0xFF141A22));
    // olhos acesos
    final olho = Paint()..color = const Color(0xFF4FF2FF);
    final halo = Paint()
      ..color = const Color(0xFF4FF2FF).withValues(alpha: .35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .05);
    for (final ox in [.36, .64]) {
      c.drawCircle(Offset(w * ox, w * .44), w * .09, halo);
      c.drawCircle(Offset(w * ox, w * .44), w * .06, olho);
    }
    // brilho no topo
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * .2, w * .21, w * .4, w * .06), Radius.circular(w * .03)),
      Paint()..color = Colors.white.withValues(alpha: .45),
    );
    // pescoço + corpo
    c.drawRect(Rect.fromLTWH(w * .42, w * .76, w * .16, w * .07), Paint()..color = const Color(0xFF6E7C8A));
    final corpo = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * .22, w * .82, w * .56, w * .18), Radius.circular(w * .07));
    c.drawRRect(
      corpo,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB9C4CF), Color(0xFF7C8996)],
        ).createShader(corpo.outerRect),
    );
    c.drawCircle(Offset(w * .5, w * .91), w * .04, Paint()..color = const Color(0xFFFFC73B));
  }

  @override
  bool shouldRepaint(_RoboPainter old) => false;
}
