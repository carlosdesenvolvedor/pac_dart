import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'ambiente_turismo.dart';
import 'cenario.dart';

/// Em que camada o clima 2D pinta: o do CÉU (estrelas, aurora, fogos) fica atrás da estrada, junto
/// do cenário; o resto (chuva, neve, folhas, areia, brasas, neblina, vagalumes e o clarão do
/// relâmpago) cai por cima dela. [tudo] = as duas numa caixa só (o céu nos 46% de cima).
enum CamadaClima { tudo, ceu, frente }

extension Clima2DCamada on Clima2D {
  /// Este clima mora no céu (pinta atrás da estrada)?
  bool get doCeu => this == Clima2D.estrelas || this == Clima2D.aurora || this == Clima2D.fogos;
}

/// 🌍 O pano de fundo de uma pista do Turismo no fallback 2D: o mundo [AmbienteTurismo.base] de
/// `cenario.dart` + o véu de cor do céu ([AmbienteTurismo.tintaCeu]) + o clima. Nos temas 1–6 é
/// exatamente o `CenarioFase` de sempre.
class CenarioTurismo extends StatelessWidget {
  final int tema;

  /// Relógio da corrida em segundos (o clima anda com ele — sem Ticker próprio).
  final double t;

  /// Reduzir animações: clima parado (quadro fixo) e sem clarão.
  final bool reduzir;

  /// [CamadaClima.ceu] quando a estrada pinta o resto por cima ([CamadaClima2D] na frente).
  final CamadaClima camada;

  const CenarioTurismo({super.key, required this.tema, this.t = 0, this.reduzir = false, this.camada = CamadaClima.tudo});

  @override
  Widget build(BuildContext context) {
    final a = AmbienteTurismo.de(tema);
    final veu = a.tintaCeu != null && a.tintaForca > 0;
    final clima = a.clima != Clima2D.nenhum && (camada != CamadaClima.ceu || a.clima.doCeu);
    if (!veu && !clima) return CenarioFase(fase: a.base);
    return Stack(fit: StackFit.expand, alignment: Alignment.topLeft, children: [
      CenarioFase(fase: a.base),
      if (veu)
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  a.tintaCeu!.withValues(alpha: a.tintaForca),
                  a.tintaCeu!.withValues(alpha: a.tintaForca * .6),
                ],
              ),
            ),
          ),
        ),
      if (clima)
        CamadaClima2D(
          clima: a.clima,
          t: t,
          noturno: a.noturno,
          reduzir: reduzir,
          camada: camada,
          relampago: camada != CamadaClima.ceu && a.relampago,
        ),
    ]);
  }
}

/// 🌧️ O clima do fallback 2D (chuva, neve, folhas, areia, estrelas, brasas, fogos, neblina,
/// aurora, vagalumes) num CustomPainter SEM Ticker próprio: quem anima é o [t] que a vista passa
/// (o relógio da corrida). Posições determinísticas (hash do índice); [reduzir] = quadro fixo e
/// sem clarão. O relâmpago ([relampago]) pisca no máximo 2 vezes por segundo e nunca passa de
/// opacidade .25 ([PintorClima2D.opacidadeRelampago]).
class CamadaClima2D extends StatelessWidget {
  final Clima2D clima;
  final double t;
  final bool noturno;
  final bool reduzir;
  final CamadaClima camada;
  final bool relampago;

  const CamadaClima2D({
    super.key,
    required this.clima,
    required this.t,
    this.noturno = false,
    this.reduzir = false,
    this.camada = CamadaClima.tudo,
    this.relampago = false,
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: PintorClima2D(
            clima: clima,
            t: t,
            noturno: noturno,
            reduzir: reduzir,
            camada: camada,
            relampago: relampago,
          ),
          size: Size.infinite,
        ),
      );
}

/// O pintor da [CamadaClima2D] (público pros testes medirem o clarão).
class PintorClima2D extends CustomPainter {
  final Clima2D clima;
  final double t;
  final bool noturno;
  final bool reduzir;
  final CamadaClima camada;
  final bool relampago;

  PintorClima2D({
    required this.clima,
    required this.t,
    this.noturno = false,
    this.reduzir = false,
    this.camada = CamadaClima.tudo,
    this.relampago = false,
  });

  /// Período do relâmpago 2D (s): um clarão + eco a cada ciclo.
  static const periodoRelampago = 7.0;

  /// Opacidade do clarão branco no instante [t]: pico .22 por 90 ms e eco .14 de 60 ms, uma vez a
  /// cada [periodoRelampago] — ≤ .25 e ≤ 2 pulsos por segundo (WCAG 2.3.1). [reduzir] = nunca.
  static double opacidadeRelampago(double t, {bool reduzir = false}) {
    if (reduzir) return 0;
    final u = t % periodoRelampago;
    if (u >= 2.0 && u < 2.09) return .22;
    if (u >= 2.21 && u < 2.27) return .14;
    return 0;
  }

  /// Hash determinístico em [0, 1) (mesma partícula, mesmo lugar em todo quadro).
  static double _h(int i, int k) {
    final v = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  void paint(Canvas c, Size s) {
    if (s.isEmpty) return;
    final tt = reduzir ? 0.0 : t;
    final w = s.width, h = s.height;
    // a faixa do céu: a caixa inteira na camada do céu, os 46% de cima no "tudo"
    final ceuH = camada == CamadaClima.ceu ? h : h * .46;
    final pintaCeu = camada != CamadaClima.frente;
    final pintaFrente = camada != CamadaClima.ceu;
    c.save();
    c.clipRect(Offset.zero & s);
    if (pintaCeu) {
      switch (clima) {
        case Clima2D.estrelas:
          _estrelas(c, w, ceuH, tt, 70);
        case Clima2D.aurora:
          _estrelas(c, w, ceuH, tt, 40);
          _aurora(c, w, ceuH, tt);
        case Clima2D.fogos:
          _fogos(c, w, ceuH, tt);
        default:
          break;
      }
    }
    if (pintaFrente) {
      switch (clima) {
        case Clima2D.chuva:
          _chuva(c, w, h, tt);
        case Clima2D.neve:
          _neve(c, w, h, tt);
        case Clima2D.folhas:
          _folhas(c, w, h, tt);
        case Clima2D.areia:
          _areia(c, w, h, tt);
        case Clima2D.brasas:
          _brasas(c, w, h, tt);
        case Clima2D.neblina:
          _neblina(c, w, h, tt);
        case Clima2D.vagalumes:
          _vagalumes(c, w, h, tt);
        default:
          break;
      }
      if (relampago) {
        final o = opacidadeRelampago(t, reduzir: reduzir);
        if (o > 0) c.drawRect(Offset.zero & s, Paint()..color = Colors.white.withValues(alpha: o));
      }
    }
    c.restore();
  }

  void _estrelas(Canvas c, double w, double ceuH, double tt, int n) {
    final p = Paint();
    for (var i = 0; i < n; i++) {
      final brilho = reduzir ? .8 : .35 + .65 * (.5 + .5 * math.sin(tt * 2 + i * 1.7));
      p.color = Colors.white.withValues(alpha: brilho);
      c.drawCircle(Offset(_h(i, 0) * w, _h(i, 1) * ceuH * .9), .6 + _h(i, 2) * 1.2, p);
    }
  }

  void _aurora(Canvas c, double w, double ceuH, double tt) {
    const cores = [Color(0xFF3DFFA0), Color(0xFF9A6BFF)];
    for (var k = 0; k < 2; k++) {
      final base = ceuH * (.28 + k * .16);
      final alto = ceuH * (.22 - k * .05);
      final onda = Path()..moveTo(0, base);
      for (var x = 0.0; x <= w; x += w / 24) {
        onda.lineTo(x, base + math.sin(x / w * 6 + tt * .6 + k * 2) * ceuH * .06);
      }
      onda
        ..lineTo(w, base - alto)
        ..lineTo(0, base - alto)
        ..close();
      final forca = .32 + .12 * math.sin(tt * .9 + k);
      c.drawPath(
        onda,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [cores[k].withValues(alpha: forca), cores[1 - k].withValues(alpha: 0)],
          ).createShader(Rect.fromLTRB(0, base - alto, w, base + ceuH * .06)),
      );
    }
  }

  void _fogos(Canvas c, double w, double ceuH, double tt) {
    const paleta = [Color(0xFFFF3B3B), Color(0xFFFFD54F), Color(0xFF4FC3FF), Color(0xFF7DFF6A), Color(0xFFFF6AF0)];
    const periodo = 2.4;
    final p = Paint();
    for (var k = 0; k < 3; k++) {
      final tempo = tt + k * .8;
      final ciclo = (tempo / periodo).floor();
      final fase = (tempo - ciclo * periodo) / 1.6;
      // quadro fixo (reduzir) mostra a explosão aberta pela metade
      final pr = reduzir ? .45 : fase;
      if (pr >= 1) continue;
      final centro = Offset((.15 + .7 * _h(ciclo * 3 + k, 5)) * w, (.18 + .45 * _h(ciclo * 3 + k, 6)) * ceuH);
      final raio = pr * math.min(w, ceuH * 2) * .14;
      p.color = paleta[(ciclo + k) % paleta.length].withValues(alpha: math.pow(1 - pr, 1.3).toDouble());
      for (var i = 0; i < 18; i++) {
        final a = i / 18 * math.pi * 2;
        c.drawCircle(centro + Offset(math.cos(a), math.sin(a) + pr * .35) * raio, 1.6, p);
      }
    }
  }

  void _chuva(Canvas c, double w, double h, double tt) {
    final p = Paint()
      ..color = (noturno ? const Color(0xFFB8C6D6) : Colors.white).withValues(alpha: .38)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 90; i++) {
      final y = (_h(i, 1) * h + tt * h * 1.6 * (.8 + _h(i, 2) * .4)) % h;
      final x = (_h(i, 0) * (w + 40) - y * .18) % (w + 40) - 20;
      c.drawLine(Offset(x, y), Offset(x - 3, y + 14), p);
    }
  }

  void _neve(Canvas c, double w, double h, double tt) {
    final p = Paint()..color = Colors.white.withValues(alpha: .85);
    for (var i = 0; i < 80; i++) {
      final y = (_h(i, 1) * h + tt * 40 * (.6 + _h(i, 2))) % h;
      final x = (_h(i, 0) * w + math.sin(tt * 1.3 + i) * 8) % w;
      c.drawCircle(Offset(x, y), 1.2 + _h(i, 3) * 1.8, p);
    }
  }

  void _folhas(Canvas c, double w, double h, double tt) {
    const cores = [Color(0xFFD9531E), Color(0xFFF2A03D), Color(0xFFB83A1B), Color(0xFFE8C547)];
    final p = Paint();
    for (var i = 0; i < 40; i++) {
      final y = (_h(i, 1) * h + tt * 50 * (.7 + _h(i, 2) * .6)) % h;
      final x = (_h(i, 0) * w + math.sin(tt * 1.1 + i) * 20) % w;
      p.color = cores[i % cores.length].withValues(alpha: .9);
      c.save();
      c.translate(x, y);
      c.rotate(tt * 2 + i);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: 7, height: 3.6), p);
      c.restore();
    }
  }

  void _areia(Canvas c, double w, double h, double tt) {
    c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFD9A35C).withValues(alpha: .16));
    final p = Paint()
      ..color = const Color(0xFFE8C08A).withValues(alpha: .38)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 60; i++) {
      final x = (_h(i, 0) * (w + 60) + tt * 220 * (.6 + _h(i, 2))) % (w + 60) - 30;
      final y = _h(i, 1) * h;
      c.drawLine(Offset(x, y), Offset(x + 26, y + 2), p);
    }
  }

  void _brasas(Canvas c, double w, double h, double tt) {
    final p = Paint();
    for (var i = 0; i < 50; i++) {
      final y = h - (_h(i, 1) * h + tt * 45 * (.5 + _h(i, 2))) % h;
      final x = (_h(i, 0) * w + math.sin(tt * 1.7 + i) * 10) % w;
      final pisca = reduzir ? .8 : .45 + .55 * (.5 + .5 * math.sin(tt * 6 + i * 2.3));
      p.color = const Color(0xFFFF7A2A).withValues(alpha: .25 * pisca);
      c.drawCircle(Offset(x, y), 4, p);
      p.color = const Color(0xFFFFC46A).withValues(alpha: pisca);
      c.drawCircle(Offset(x, y), 1.4, p);
    }
  }

  void _neblina(Canvas c, double w, double h, double tt) {
    final cor = noturno ? const Color(0xFF9AA4AE) : const Color(0xFFE6ECF2);
    c.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = cor.withValues(alpha: .12));
    for (var k = 0; k < 3; k++) {
      final centroY = h * (.38 + k * .14);
      final faixa = Rect.fromLTWH(-w * .2 + math.sin(tt * .25 + k * 2) * w * .1, centroY - h * .08, w * 1.4, h * .16);
      c.drawRect(
        faixa,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cor.withValues(alpha: 0), cor.withValues(alpha: .28), cor.withValues(alpha: 0)],
          ).createShader(faixa),
      );
    }
  }

  void _vagalumes(Canvas c, double w, double h, double tt) {
    final p = Paint();
    for (var i = 0; i < 30; i++) {
      final x = (_h(i, 0) * w + math.sin(tt * .7 + i) * 14) % w;
      final y = h * (.5 + .45 * _h(i, 1)) + math.cos(tt * .9 + i * 1.3) * 6;
      final b = math.max(0.0, math.sin(tt * 2.2 + _h(i, 2) * 18));
      final a = reduzir ? .7 : b * b;
      if (a <= .01) continue;
      p.color = const Color(0xFFD8FF6A).withValues(alpha: .25 * a);
      c.drawCircle(Offset(x, y), 5, p);
      p.color = const Color(0xFFF4FFC0).withValues(alpha: a);
      c.drawCircle(Offset(x, y), 1.5, p);
    }
  }

  @override
  bool shouldRepaint(PintorClima2D old) =>
      old.t != t ||
      old.clima != clima ||
      old.noturno != noturno ||
      old.reduzir != reduzir ||
      old.camada != camada ||
      old.relampago != relampago;
}
