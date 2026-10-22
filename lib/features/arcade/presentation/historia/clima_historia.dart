import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/historia_turismo.dart';
import 'fundo_historia.dart';

/// 🌧️ O clima da cena (chuva, neve, neblina, estrelas, aurora, arco-íris…), em duas passadas: a de trás
/// ([frente] = false: estrelas, aurora, arco-íris) e a da frente.
///
/// Passada de trás (camada 3, entre o fundo distante e o chão): estrelas, aurora, arco-íris, letreiros de neon,
/// neve e chuva distantes, neblina no horizonte e o brilho das brasas. Passada da frente (camada 7, sobre os
/// atores): chuva, neve, neblina, areia, folhas, brasas, vento e o reflexo do neon.
///
/// Nos **interiores** (`interioresHistoria`), chuva e neve só aparecem "na janela": vão na passada de trás,
/// recortadas acima da linha do chão, e nada na frente. O neon da `estacao` (interior) é o mesmo dos exteriores.
///
/// Sem estado: cada partícula é função do índice e de [t] (hash determinístico). [estatico] (reduzir animações)
/// congela tudo num quadro fixo, com o arco-íris já inteiro. O arco-íris aparece com fade de 1 s contado de
/// `t = 0`: quem quer o fade a partir da troca de clima passa [t] relativo a essa troca.
class ClimaHistoriaPainter extends CustomPainter {
  ClimaHistoriaPainter({
    required this.clima,
    required this.frente,
    required this.t,
    required this.hora,
    required this.cenario,
    this.estatico = false,
  });

  final List<ClimaHistoria> clima;
  final bool frente;
  final double t;
  final HoraHistoria hora;
  final CenarioHistoria cenario;

  /// Reduzir animações: um quadro fixo.
  final bool estatico;

  /// O que cada clima pinta em cada passada (exterior/interior). Público para o palco e os testes.
  static bool pintaNaPassada(ClimaHistoria cl, {required bool frente, required bool interior}) {
    if (interior && (cl == ClimaHistoria.chuva || cl == ClimaHistoria.neve)) return !frente;
    return switch (cl) {
      ClimaHistoria.estrelas || ClimaHistoria.aurora || ClimaHistoria.arcoIris => !frente,
      ClimaHistoria.areia || ClimaHistoria.folhas || ClimaHistoria.vento => frente,
      ClimaHistoria.chuva ||
      ClimaHistoria.neve ||
      ClimaHistoria.neblina ||
      ClimaHistoria.brasas ||
      ClimaHistoria.neon =>
        true,
    };
  }

  /// Hash determinístico 0..1 (sem `Random`, para o painter não ter estado).
  static double _h(int i, int k) {
    final v = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _fr(double v) => v - v.floorToDouble();

  static Path _coracao(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy + r * .95)
    ..cubicTo(c.dx - r * 1.5, c.dy + r * .1, c.dx - r * .9, c.dy - r * 1.1, c.dx, c.dy - r * .35)
    ..cubicTo(c.dx + r * .9, c.dy - r * 1.1, c.dx + r * 1.5, c.dy + r * .1, c.dx, c.dy + r * .95)
    ..close();

  static Path _estrela(Offset c, double rFora, double rDentro) {
    final p = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? rFora : rDentro;
      final a = -math.pi / 2 + i * math.pi / 5;
      final o = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  late double _k; // escala de tamanho (px por "unidade" de 400 px de palco)
  late double _chao; // y da linha do chão
  late double _tt;
  late bool _noite;

  @override
  void paint(Canvas canvas, Size size) {
    if (clima.isEmpty || size.isEmpty || !size.isFinite) return;
    final interior = interioresHistoria.contains(cenario);
    _k = (size.shortestSide / 400).clamp(.6, 2.4);
    _chao = size.height * FundoHistoriaPainter.linhaDoChao(cenario).clamp(.3, 1.0);
    _tt = estatico ? 0 : t;
    _noite = hora == HoraHistoria.noite;
    final janela = interior && !frente;
    if (janela) {
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(0, 0, size.width, _chao));
    }
    for (final cl in clima) {
      if (!pintaNaPassada(cl, frente: frente, interior: interior)) continue;
      switch (cl) {
        case ClimaHistoria.chuva:
          _chuva(canvas, size, perto: frente, janela: janela);
        case ClimaHistoria.neve:
          _neve(canvas, size, perto: frente, janela: janela);
        case ClimaHistoria.neblina:
          _neblina(canvas, size);
        case ClimaHistoria.areia:
          _areia(canvas, size);
        case ClimaHistoria.folhas:
          _folhas(canvas, size);
        case ClimaHistoria.estrelas:
          _estrelas(canvas, size, interior: interior);
        case ClimaHistoria.brasas:
          _brasas(canvas, size);
        case ClimaHistoria.aurora:
          _aurora(canvas, size);
        case ClimaHistoria.vento:
          _vento(canvas, size);
        case ClimaHistoria.neon:
          _neon(canvas, size);
        case ClimaHistoria.arcoIris:
          _arcoIris(canvas, size);
      }
    }
    if (janela) canvas.restore();
  }

  // ───────────────────────── climas ─────────────────────────

  void _chuva(Canvas c, Size s, {required bool perto, required bool janela}) {
    final n = perto ? 90 : (janela ? 60 : 50);
    final comp = (perto ? 26.0 : 14.0) * _k;
    final vel = perto ? 1.5 : .9; // alturas de tela por segundo
    final altura = (janela ? _chao : s.height) + comp * 2;
    final cor = (_noite ? const Color(0xFFB8C8F0) : const Color(0xFFDDEBFF))
        .withValues(alpha: perto ? .6 : (janela ? .55 : .3));
    final p = Path();
    for (var i = 0; i < n; i++) {
      final x = (_h(i, 1) * 1.2 - .1) * s.width;
      final y = _fr(_h(i, 2) + _tt * vel * (.85 + _h(i, 3) * .3)) * altura - comp;
      final dx = x - (y / s.height) * 20 * _k; // um pouco inclinada pelo vento
      p
        ..moveTo(dx, y)
        ..lineTo(dx - comp * .22, y + comp);
    }
    c.drawPath(
      p,
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = (perto ? 1.8 : 1.1) * _k
        ..strokeCap = StrokeCap.round,
    );
    if (perto) {
      // respingos no chão
      final resp = Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * _k;
      for (var i = 0; i < 14; i++) {
        final f = _fr(_h(i, 7) + _tt * 2.2);
        final x = _h(i, 8) * s.width;
        final y = _chao + (_h(i, 9) * (s.height - _chao)) * .8;
        final r = (2 + f * 9) * _k;
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 2, height: r * .7),
            resp..color = cor.withValues(alpha: cor.a * (1 - f)));
      }
    }
  }

  void _neve(Canvas c, Size s, {required bool perto, required bool janela}) {
    final n = perto ? 60 : 45;
    final altura = (janela ? _chao : s.height) + 10 * _k;
    final tinta = Paint()..color = Colors.white.withValues(alpha: perto ? .92 : .65);
    for (var i = 0; i < n; i++) {
      final r = (perto ? 1.8 + _h(i, 4) * 2.2 : .9 + _h(i, 4) * 1.0) * _k;
      final vel = (perto ? .16 : .09) * (.8 + _h(i, 5) * .5);
      final y = _fr(_h(i, 2) + _tt * vel) * altura - 5 * _k;
      final x = _h(i, 1) * s.width + math.sin(_tt * 1.3 + i) * 10 * _k + _tt * 8 * _k % s.width;
      c.drawCircle(Offset(x % s.width, y), r, tinta);
    }
  }

  Color get _corNeblina => switch (hora) {
        HoraHistoria.amanhecer => const Color(0xFFFFE6D5),
        HoraHistoria.dia => const Color(0xFFF2F5FA),
        HoraHistoria.tarde => const Color(0xFFF4D9E6),
        HoraHistoria.noite => const Color(0xFF8A96B8),
      };

  void _neblina(Canvas c, Size s) {
    final cor = _corNeblina;
    if (!frente) {
      // véu no horizonte
      final faixa = Rect.fromLTRB(0, _chao - s.height * .35, s.width, _chao + 4);
      c.drawRect(
        faixa,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cor.withValues(alpha: 0), cor.withValues(alpha: .75)],
          ).createShader(faixa),
      );
      return;
    }
    // bancos de neblina passando devagar na frente
    final tinta = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, 18 * _k);
    for (var i = 0; i < 5; i++) {
      final w = s.width * (.45 + _h(i, 1) * .35);
      final x = _fr(_h(i, 2) + _tt * (.012 + _h(i, 3) * .01)) * (s.width + w) - w;
      final y = s.height * (.45 + _h(i, 4) * .4);
      c.drawOval(Rect.fromLTWH(x, y, w, s.height * .16), tinta..color = cor.withValues(alpha: .35));
    }
    c.drawRect(Offset.zero & s, Paint()..color = cor.withValues(alpha: .12));
  }

  void _areia(Canvas c, Size s) {
    final poeira = _noite ? const Color(0xFF8A5A3A) : const Color(0xFFE8A85A);
    c.drawRect(Offset.zero & s, Paint()..color = poeira.withValues(alpha: .28));
    // nuvens de poeira passando
    final nuvem = Paint()
      ..color = const Color(0xFFF2C98A).withValues(alpha: .35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 22 * _k);
    for (var i = 0; i < 3; i++) {
      final w = s.width * (.5 + _h(i, 8) * .3);
      final x = _fr(_h(i, 9) + _tt * (.06 + _h(i, 10) * .04)) * (s.width + w) - w;
      c.drawOval(Rect.fromLTWH(x, s.height * (.35 + i * .18), w, s.height * .2), nuvem);
    }
    final grao = Paint()..color = const Color(0xFFF6D9A8).withValues(alpha: .85);
    final risco = Paint()
      ..color = const Color(0xFFFBE7C4).withValues(alpha: .55)
      ..strokeWidth = 2 * _k
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 90; i++) {
      final vel = .55 + _h(i, 3) * .5;
      final x = _fr(_h(i, 1) + _tt * vel) * (s.width * 1.2) - s.width * .1;
      final y = _h(i, 2) * s.height + math.sin(_tt * 3 + i) * 4 * _k;
      if (i % 3 == 0) {
        c.drawLine(Offset(x, y), Offset(x - 40 * _k, y + 3 * _k), risco);
      } else {
        c.drawCircle(Offset(x, y), (1 + _h(i, 4) * 1.4) * _k, grao);
      }
    }
  }

  static const _coresFolha = [Color(0xFFE8752A), Color(0xFFD9442B), Color(0xFFF2B33D), Color(0xFFB5562A)];

  void _folhas(Canvas c, Size s) {
    final contorno = Paint()
      ..color = const Color(0xFF3A2A33).withValues(alpha: .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8 * _k;
    for (var i = 0; i < 18; i++) {
      final vel = .1 + _h(i, 3) * .08;
      final y = _fr(_h(i, 2) + _tt * vel) * (s.height + 30 * _k) - 15 * _k;
      final x = _fr(_h(i, 1) + _tt * .03) * s.width + math.sin(_tt * 1.6 + i * 2) * 26 * _k;
      final tam = (7 + _h(i, 4) * 5) * _k;
      c.save();
      c.translate(x, y);
      c.rotate(_tt * (1.5 + _h(i, 5) * 2) + i);
      final folha = Path()
        ..moveTo(-tam, 0)
        ..quadraticBezierTo(0, -tam * .7, tam, 0)
        ..quadraticBezierTo(0, tam * .7, -tam, 0)
        ..close();
      c.drawPath(folha, Paint()..color = _coresFolha[i % _coresFolha.length]);
      c.drawPath(folha, contorno);
      c.restore();
    }
  }

  void _estrelas(Canvas c, Size s, {required bool interior}) {
    final ceu = interior ? _chao * .8 : _chao * .78;
    final n = interior ? 45 : 70;
    final tinta = Paint()..color = Colors.white;
    for (var i = 0; i < n; i++) {
      final x = _h(i, 1) * s.width;
      final y = _h(i, 2) * ceu;
      final pisca = estatico ? .8 : .55 + .45 * math.sin(_tt * (1.5 + _h(i, 3) * 2.5) + i);
      final r = (.7 + _h(i, 4) * 1.3) * _k;
      c.drawCircle(Offset(x, y), r, tinta..color = Colors.white.withValues(alpha: pisca.clamp(.2, 1.0)));
      if (i % 9 == 0) {
        // estrela maior em cruz
        final l = r * 3.2 * pisca;
        final cruz = Paint()
          ..color = const Color(0xFFFFF6D5).withValues(alpha: .85)
          ..strokeWidth = .9 * _k
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(x - l, y), Offset(x + l, y), cruz);
        c.drawLine(Offset(x, y - l), Offset(x, y + l), cruz);
      }
    }
  }

  void _brasas(Canvas c, Size s) {
    if (!frente) {
      // brilho avermelhado no horizonte
      final faixa = Rect.fromLTRB(0, _chao - s.height * .3, s.width, _chao);
      c.drawRect(
        faixa,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0x00FF5A1F), const Color(0xFFFF5A1F).withValues(alpha: .28)],
          ).createShader(faixa),
      );
      return;
    }
    final brilho = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * _k);
    final miolo = Paint();
    for (var i = 0; i < 34; i++) {
      final vel = .1 + _h(i, 3) * .12;
      final f = _fr(_h(i, 2) + _tt * vel);
      final y = s.height * (1.02 - f * 1.05);
      final x = _h(i, 1) * s.width + math.sin(_tt * 2 + i * 1.3) * 14 * _k;
      final vida = (1 - f) * (.6 + .4 * math.sin(_tt * 7 + i).abs());
      final r = (2 + _h(i, 4) * 2.5) * _k;
      c.drawCircle(Offset(x, y), r * 3, brilho..color = const Color(0xFFFF7A1F).withValues(alpha: .45 * vida));
      c.drawCircle(Offset(x, y), r, miolo..color = const Color(0xFFFFD27A).withValues(alpha: vida.clamp(0, 1)));
    }
  }

  void _aurora(Canvas c, Size s) {
    const cores = [Color(0xFF4DFFB0), Color(0xFF3DD6E0), Color(0xFFB07CFF)];
    for (var b = 0; b < cores.length; b++) {
      final base = s.height * (.12 + b * .07);
      final alto = s.height * (.12 + b * .03);
      final p = Path()..moveTo(0, base);
      const passos = 24;
      for (var i = 0; i <= passos; i++) {
        final x = s.width * i / passos;
        final y = base + math.sin(i * .55 + _tt * .5 + b * 1.7) * s.height * .035;
        p.lineTo(x, y);
      }
      for (var i = passos; i >= 0; i--) {
        final x = s.width * i / passos;
        final y = base - alto + math.sin(i * .4 - _tt * .35 + b) * s.height * .03;
        p.lineTo(x, y);
      }
      p.close();
      final r = p.getBounds();
      c.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [cores[b].withValues(alpha: .5), cores[b].withValues(alpha: 0)],
          ).createShader(r)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * _k),
      );
    }
  }

  void _vento(Canvas c, Size s) {
    final traco = Paint()
      ..color = Colors.white.withValues(alpha: _noite ? .35 : .6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * _k
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 9; i++) {
      final comp = s.width * (.12 + _h(i, 3) * .12);
      final x = _fr(_h(i, 1) + _tt * (.35 + _h(i, 4) * .25)) * (s.width + comp * 2) - comp;
      final y = s.height * (.15 + _h(i, 2) * .7);
      final p = Path()
        ..moveTo(x - comp, y)
        ..cubicTo(x - comp * .6, y - 8 * _k, x - comp * .3, y + 8 * _k, x, y);
      if (i % 3 == 0) {
        // voltinha no fim do traço
        p.relativeArcToPoint(Offset(0, -10 * _k), radius: Radius.circular(5 * _k), clockwise: false);
      }
      c.drawPath(p, traco);
    }
    // ciscos levados pelo vento
    final cisco = Paint()..color = const Color(0xFFD9C9A8).withValues(alpha: .8);
    for (var i = 0; i < 10; i++) {
      final x = _fr(_h(i, 6) + _tt * .6) * s.width;
      final y = _chao - _h(i, 7) * s.height * .3 + math.sin(_tt * 4 + i) * 6 * _k;
      c.drawCircle(Offset(x, y), 1.4 * _k, cisco);
    }
  }

  static const _coresNeon = [Color(0xFFFF4FD8), Color(0xFF3DE8FF), Color(0xFFB07CFF), Color(0xFFFFE14F)];

  void _neon(Canvas c, Size s) {
    if (!frente) {
      // letreiros de neon no alto dos prédios (piscam devagar, nunca apagam de vez)
      for (var i = 0; i < 5; i++) {
        final cor = _coresNeon[i % _coresNeon.length];
        final liga = estatico ? 1.0 : .75 + .25 * math.sin(_tt * (1.2 + i * .3) + i);
        final centro = Offset(s.width * (.1 + i * .2), _chao * (.42 + _h(i, 2) * .3));
        final r = (14 + _h(i, 3) * 8) * _k;
        final forma = switch (i % 4) {
          0 => Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: centro, width: r * 3, height: r), Radius.circular(r / 2))),
          1 => _coracao(centro, r),
          2 => _estrela(centro, r, r * .45),
          _ => Path()
            ..moveTo(centro.dx - r * 1.3, centro.dy - r * .6)
            ..lineTo(centro.dx, centro.dy - r * .6)
            ..lineTo(centro.dx, centro.dy - r)
            ..lineTo(centro.dx + r * 1.3, centro.dy)
            ..lineTo(centro.dx, centro.dy + r)
            ..lineTo(centro.dx, centro.dy + r * .6)
            ..lineTo(centro.dx - r * 1.3, centro.dy + r * .6)
            ..close(),
        };
        c.drawPath(
          forma,
          Paint()
            ..color = cor.withValues(alpha: .7 * liga)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 7 * _k
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6 * _k),
        );
        c.drawPath(
          forma,
          Paint()
            ..color = Color.lerp(cor, Colors.white, .45)!.withValues(alpha: liga)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 * _k
            ..strokeJoin = StrokeJoin.round,
        );
      }
      return;
    }
    // reflexos coloridos no chão e um véu de cor embaixo
    final faixa = Rect.fromLTRB(0, _chao, s.width, s.height);
    c.drawRect(
      faixa,
      Paint()
        ..shader = LinearGradient(
          colors: [
            _coresNeon[0].withValues(alpha: .14),
            _coresNeon[1].withValues(alpha: .14),
            _coresNeon[2].withValues(alpha: .14),
          ],
        ).createShader(faixa),
    );
    for (var i = 0; i < 6; i++) {
      final cor = _coresNeon[i % _coresNeon.length];
      final x = s.width * (.1 + i * .16);
      final y = _chao + (s.height - _chao) * (.3 + _h(i, 5) * .5);
      final w = (20 + _h(i, 6) * 30) * _k;
      final ondula = estatico ? 0.0 : math.sin(_tt * 2 + i) * 3 * _k;
      c.drawLine(
        Offset(x - w / 2 + ondula, y),
        Offset(x + w / 2 + ondula, y),
        Paint()
          ..color = cor.withValues(alpha: .4)
          ..strokeWidth = 2 * _k
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _arcoIris(Canvas c, Size s) {
    final alfa = estatico ? 1.0 : (t / 1.0).clamp(0.0, 1.0);
    if (alfa <= 0) return;
    const cores = [
      Color(0xFFFF5A5A),
      Color(0xFFFF9F43),
      Color(0xFFFFE14F),
      Color(0xFF4DD68C),
      Color(0xFF3DA9FF),
      Color(0xFF7A6CFF),
    ];
    final centro = Offset(s.width * .62, _chao * 1.02);
    final raio = math.min(s.width * .36, _chao * .72);
    final faixa = raio * .045;
    for (var i = 0; i < cores.length; i++) {
      final r = raio - i * faixa;
      c.drawArc(
        Rect.fromCircle(center: centro, radius: r),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = cores[i].withValues(alpha: .45 * alfa)
          ..style = PaintingStyle.stroke
          ..strokeWidth = faixa + .5,
      );
    }
  }

  @override
  bool shouldRepaint(ClimaHistoriaPainter old) =>
      old.frente != frente ||
      (old.t != t && !(estatico && old.estatico)) ||
      old.hora != hora ||
      old.cenario != cenario ||
      old.estatico != estatico ||
      old.clima.length != clima.length ||
      !Iterable.generate(clima.length).every((i) => old.clima[i] == clima[i]);
}
