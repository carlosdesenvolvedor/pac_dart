import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/historia_turismo.dart';
import 'props_historia.dart';

/// Um efeito pontual em curso ([inicio] no relógio do palco, em segundos).
class EfeitoAtivo {
  final EfeitoHistoria efeito;
  final Offset origem;
  final double inicio;

  const EfeitoAtivo(this.efeito, this.origem, this.inicio);
}

/// O projétil do `arremessa` (bola de neve em neve/lago; bolinha de papel nos outros).
class ProjetilAtivo {
  final Offset de, para;
  final double inicio;
  final bool neve;

  const ProjetilAtivo(this.de, this.para, this.inicio, {this.neve = false});
}

/// ✨ A camada dos efeitos (confete, fogos, relâmpago, corações…) e dos projéteis.
///
/// [origem] dos efeitos e as pontas dos projéteis estão em pixels da própria camada; [t] é o mesmo relógio de
/// [EfeitoAtivo.inicio]. Os efeitos marcados com * na seção 5.3 (corações, brilho, notas, interrogação,
/// exclamação, suor, zzz) nascem em [origem] (a cabeça do dono); `estrelaCadente` risca o céu inteiro.
///
/// Fotossensibilidade (WCAG 2.3.1): o clarão do `relampago` nunca passa de [opacidadeMaxFlash] (.25) e nunca
/// pisca mais de 2 vezes em qualquer janela de 1 s, mesmo com vários relâmpagos seguidos (ver [pulsosRelampago]).
/// Com [reduzir]: cada efeito vira um ícone parado por 0,8 s, o relâmpago vira um clarão suave de .15 por 300 ms
/// (sem raio e sem tremida) e o projétil aparece parado no alvo.
class EfeitoHistoriaLayer extends StatelessWidget {
  const EfeitoHistoriaLayer({
    super.key,
    required this.efeitos,
    required this.projeteis,
    required this.t,
    this.reduzir = false,
  });

  final List<EfeitoAtivo> efeitos;
  final List<ProjetilAtivo> projeteis;
  final double t;
  final bool reduzir;

  /// Opacidade máxima do clarão branco (normal).
  static const opacidadeMaxFlash = .25;

  /// Opacidade do clarão suave (reduzir animações / tremor desligado).
  static const opacidadeFlashSuave = .15;

  /// Duração de cada pulso do relâmpago (normal) e do clarão suave.
  static const duracaoPulso = .12;
  static const duracaoPulsoSuave = .3;

  /// Distância entre os 2 pulsos de um relâmpago.
  static const intervaloPulsos = .35;

  /// Voo do projétil e o respingo no alvo.
  static const vooProjetil = .55;
  static const duracaoProjetil = .8;

  /// Quanto tempo o efeito fica na tela (s). Fora disso a camada não pinta nada dele.
  static double duracao(EfeitoHistoria e, {bool reduzir = false}) {
    if (e == EfeitoHistoria.relampago) return reduzir ? duracaoPulsoSuave : intervaloPulsos + duracaoPulso;
    if (reduzir) return .8;
    return switch (e) {
      EfeitoHistoria.fogos => 1.4,
      EfeitoHistoria.estalo => .6,
      _ => 1.2,
    };
  }

  /// O efeito ainda aparece no instante [t]? (o palco pode podar a lista com isto)
  static bool ativo(EfeitoAtivo e, double t, {bool reduzir = false}) {
    final idade = t - e.inicio;
    return idade >= 0 && idade < duracao(e.efeito, reduzir: reduzir);
  }

  /// Inícios dos pulsos de clarão que de fato acontecem, já com os limites: pulsos que se sobrepõem viram um, e
  /// um pulso só entra se o penúltimo aceito começou há pelo menos 1 s (logo, ≤ 2 pulsos em qualquer 1 s).
  static List<double> pulsosRelampago(List<EfeitoAtivo> efeitos, {bool reduzir = false}) {
    final dur = reduzir ? duracaoPulsoSuave : duracaoPulso;
    final brutos = <double>[
      for (final e in efeitos)
        if (e.efeito == EfeitoHistoria.relampago) ...[e.inicio, if (!reduzir) e.inicio + intervaloPulsos],
    ]..sort();
    final aceitos = <double>[];
    for (final p in brutos) {
      if (aceitos.isNotEmpty && p < aceitos.last + dur) continue;
      if (aceitos.length >= 2 && p - aceitos[aceitos.length - 2] < 1.0) continue;
      aceitos.add(p);
    }
    return aceitos;
  }

  /// Opacidade do clarão branco em [t] (0 = sem clarão). Nunca passa de [opacidadeMaxFlash].
  static double opacidadeFlash(List<EfeitoAtivo> efeitos, double t, {bool reduzir = false}) {
    final dur = reduzir ? duracaoPulsoSuave : duracaoPulso;
    for (final p in pulsosRelampago(efeitos, reduzir: reduzir)) {
      final f = (t - p) / dur;
      if (f < 0 || f >= 1) continue;
      if (reduzir) return opacidadeFlashSuave * math.sin(f * math.pi);
      // sobe na hora, segura e apaga no último terço
      return opacidadeMaxFlash * (f < .66 ? 1.0 : (1 - f) / .34);
    }
    return 0;
  }

  /// A tremida da câmera do relâmpago (o palco soma isto ao `Transform`). Zero com [reduzir].
  static Offset tremor(List<EfeitoAtivo> efeitos, double t, {bool reduzir = false}) {
    if (reduzir) return Offset.zero;
    var o = Offset.zero;
    for (final e in efeitos) {
      if (e.efeito != EfeitoHistoria.relampago) continue;
      final idade = t - e.inicio;
      if (idade < 0 || idade >= .4) continue;
      final a = 4 * (1 - idade / .4);
      o += Offset(math.sin(idade * 90) * a, math.cos(idade * 70) * a * .6);
    }
    return o;
  }

  @override
  Widget build(BuildContext context) {
    if (efeitos.isEmpty && projeteis.isEmpty) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: EfeitosHistoriaPainter(efeitos: efeitos, projeteis: projeteis, t: t, reduzir: reduzir),
      ),
    );
  }
}

/// O painter da [EfeitoHistoriaLayer] (público para os testes medirem o clarão).
class EfeitosHistoriaPainter extends CustomPainter {
  EfeitosHistoriaPainter({required this.efeitos, required this.projeteis, required this.t, this.reduzir = false});

  final List<EfeitoAtivo> efeitos;
  final List<ProjetilAtivo> projeteis;
  final double t;
  final bool reduzir;

  static const _contorno = Color(0xFF3A2A33);
  static const _festa = [
    Color(0xFFFF5A5A),
    Color(0xFFFFD166),
    Color(0xFF4DD68C),
    Color(0xFF3DA9FF),
    Color(0xFFB07CFF),
    Color(0xFFFF9EC7),
  ];

  static double _h(int i, int k) {
    final v = math.sin(i * 12.9898 + k * 78.233) * 43758.5453;
    return v - v.floorToDouble();
  }

  static double _sai(double x) => 1 - math.pow(1 - x.clamp(0.0, 1.0), 3).toDouble();

  late double _k;
  late double _lw;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;
    _k = (size.shortestSide / 400).clamp(.6, 2.4);
    _lw = (2 * _k).clamp(1.5, 3.0);
    for (final p in projeteis) {
      _projetil(canvas, size, p);
    }
    for (var i = 0; i < efeitos.length; i++) {
      final e = efeitos[i];
      if (e.efeito == EfeitoHistoria.relampago) continue; // o clarão é pintado uma vez só, por cima
      final idade = t - e.inicio;
      final dur = EfeitoHistoriaLayer.duracao(e.efeito, reduzir: reduzir);
      if (idade < 0 || idade >= dur) continue;
      // reduzir: um ícone parado num quadro representativo
      final p = reduzir ? .45 : idade / dur;
      final alfa = reduzir ? 1.0 : (p < .8 ? 1.0 : (1 - p) / .2);
      _efeito(canvas, size, e, p, alfa.clamp(0.0, 1.0), i);
    }
    // relâmpago: raio (só sem reduzir) e o clarão limitado
    if (!reduzir) {
      for (final e in efeitos) {
        if (e.efeito != EfeitoHistoria.relampago) continue;
        for (final p in [e.inicio, e.inicio + EfeitoHistoriaLayer.intervaloPulsos]) {
          final f = (t - p) / EfeitoHistoriaLayer.duracaoPulso;
          if (f >= 0 && f < 1) _raio(canvas, size, e, p);
        }
      }
    }
    final flash = EfeitoHistoriaLayer.opacidadeFlash(efeitos, t, reduzir: reduzir);
    if (flash > 0) {
      canvas.drawRect(
        (Offset.zero & size).inflate(size.shortestSide * .2),
        Paint()..color = Colors.white.withValues(alpha: math.min(flash, EfeitoHistoriaLayer.opacidadeMaxFlash)),
      );
    }
  }

  Paint get _traco => Paint()
    ..color = _contorno
    ..style = PaintingStyle.stroke
    ..strokeWidth = _lw
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _forma(Canvas c, Path p, Color cor, double alfa) {
    c.drawPath(p, Paint()..color = cor.withValues(alpha: cor.a * alfa));
    c.drawPath(p, _traco..color = _contorno.withValues(alpha: alfa));
  }

  void _efeito(Canvas c, Size s, EfeitoAtivo e, double p, double alfa, int semente) {
    final o = e.origem;
    switch (e.efeito) {
      case EfeitoHistoria.confete:
        _confete(c, o, p, alfa, semente);
      case EfeitoHistoria.fogos:
        _fogos(c, s, o, p, alfa, semente);
      case EfeitoHistoria.relampago:
        break;
      case EfeitoHistoria.coracoes:
        for (var i = 0; i < 5; i++) {
          final q = ((p * 1.25) - i * .1).clamp(0.0, 1.0);
          if (q <= 0) continue;
          final pos = o + Offset((i - 2) * 14 * _k + math.sin(q * 6 + i) * 8 * _k, -q * 70 * _k);
          final r = (6 + (i % 2) * 3) * _k * _sai(q * 4);
          _forma(c, PropPainter.coracao(pos, r), const Color(0xFFFF5A8A), alfa);
        }
      case EfeitoHistoria.brilho:
        for (var i = 0; i < 6; i++) {
          final a = i * math.pi / 3 + p * 1.5;
          final pos = o + Offset(math.cos(a), math.sin(a) * .7) * (30 + 12 * _sai(p)) * _k;
          final r = (4 + 5 * math.sin((p * 3 + i * .17) * math.pi).abs()) * _k;
          _brilhinho(c, pos, r, const Color(0xFFFFF0A0), alfa);
        }
      case EfeitoHistoria.fumaca:
        for (var i = 0; i < 6; i++) {
          final q = ((p * 1.3) - i * .06).clamp(0.0, 1.0);
          if (q <= 0) continue;
          final pos = o + Offset((_h(i, 1) - .5) * 30 * _k + q * 12 * _k, -q * 60 * _k);
          final r = (8 + q * 18) * _k;
          c.drawCircle(pos, r, Paint()..color = const Color(0xFF9A9AA6).withValues(alpha: .6 * alfa * (1 - q * .7)));
        }
      case EfeitoHistoria.notas:
        for (var i = 0; i < 3; i++) {
          final q = ((p * 1.3) - i * .15).clamp(0.0, 1.0);
          if (q <= 0) continue;
          final pos = o + Offset((i - 1) * 18 * _k + math.sin(q * 7 + i) * 7 * _k, -q * 60 * _k);
          _nota(c, pos, 7 * _k, _festa[(i + 3) % _festa.length], alfa);
        }
      case EfeitoHistoria.interrogacao:
        _sinal(c, o, p, alfa, interrogacao: true);
      case EfeitoHistoria.exclamacao:
        _sinal(c, o, p, alfa, interrogacao: false);
      case EfeitoHistoria.suor:
        for (var i = 0; i < 2; i++) {
          final q = ((p * 1.2) - i * .3).clamp(0.0, 1.0);
          if (q <= 0) continue;
          final pos = o + Offset((22 + i * 12) * _k, (-10 + i * 6 + q * 24) * _k);
          _gota(c, pos, (6.5 - i * 1.5) * _k, alfa * (1 - q * .6));
        }
      case EfeitoHistoria.zzz:
        for (var i = 0; i < 3; i++) {
          final q = ((p * 1.3) - i * .18).clamp(0.0, 1.0);
          if (q <= 0) continue;
          final pos = o + Offset((14 + i * 15 + q * 10) * _k, -(i * 17 + q * 26) * _k);
          _z(c, pos, (5 + i * 2.5) * _k, alfa * (1 - q * .5));
        }
      case EfeitoHistoria.estalo:
        _estalo(c, o, p, alfa, 1);
      case EfeitoHistoria.estrelaCadente:
        _estrelaCadente(c, s, p, alfa);
    }
  }

  // ───────────────────────── efeitos ─────────────────────────

  void _confete(Canvas c, Offset o, double p, double alfa, int semente) {
    final idade = p * 1.2;
    for (var i = 0; i < 36; i++) {
      final a = -math.pi * (.17 + _h(i, semente + 1) * .66);
      final v = (220 + _h(i, semente + 2) * 220) * _k;
      final g = 520 * _k;
      final pos = reduzir
          ? o + Offset((_h(i, 3) - .5) * 120 * _k, -_h(i, 4) * 90 * _k)
          : o + Offset(math.cos(a) * v * idade, math.sin(a) * v * idade + .5 * g * idade * idade);
      c.save();
      c.translate(pos.dx, pos.dy);
      c.rotate(i + idade * (4 + _h(i, 5) * 6));
      c.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 7 * _k, height: 3.5 * _k),
        Paint()..color = _festa[i % _festa.length].withValues(alpha: alfa),
      );
      c.restore();
    }
  }

  void _fogos(Canvas c, Size s, Offset o, double p, double alfa, int semente) {
    final idade = p * 1.4;
    for (var j = 0; j < 3; j++) {
      final centro = Offset(
        (o.dx + (j - 1) * s.width * .2).clamp(s.width * .1, s.width * .9),
        s.height * (.16 + (j % 2) * .1),
      );
      final q = reduzir ? .7 : ((idade - j * .25) / .9);
      if (q <= 0 || q >= 1) continue;
      final cor = _festa[(j * 2 + semente) % _festa.length];
      final raio = 70 * _k * _sai(q);
      final tinta = Paint()..color = cor.withValues(alpha: alfa * (reduzir ? 1 : (1 - q * q)));
      const raios = 14;
      for (var i = 0; i < raios; i++) {
        final a = i * 2 * math.pi / raios + j;
        final pos = centro + Offset(math.cos(a) * raio, math.sin(a) * raio + q * q * 18 * _k);
        c.drawCircle(pos, 2.6 * _k, tinta);
        c.drawLine(
          centro + Offset(math.cos(a), math.sin(a)) * raio * .6,
          pos,
          Paint()
            ..color = tinta.color.withValues(alpha: tinta.color.a * .5)
            ..strokeWidth = 1.4 * _k,
        );
      }
    }
  }

  void _raio(Canvas c, Size s, EfeitoAtivo e, double inicioPulso) {
    final x0 = e.origem.dx.clamp(s.width * .1, s.width * .9);
    final p = Path()..moveTo(x0, 0);
    var x = x0;
    const passos = 6;
    for (var i = 1; i <= passos; i++) {
      x += (_h(i, (inicioPulso * 100).round()) - .5) * 50 * _k;
      p.lineTo(x, s.height * .55 * i / passos);
    }
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFFFF6B0).withValues(alpha: .6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7 * _k
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * _k),
    );
    c.drawPath(
      p,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4 * _k
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  void _brilhinho(Canvas c, Offset o, double r, Color cor, double alfa) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final rr = i.isEven ? r : r * .3;
      final a = -math.pi / 2 + i * math.pi / 4;
      final q = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    p.close();
    c.drawPath(p, Paint()..color = cor.withValues(alpha: alfa));
    c.drawPath(p, _traco..color = _contorno.withValues(alpha: alfa * .6)..strokeWidth = _lw * .6);
  }

  void _nota(Canvas c, Offset o, double r, Color cor, double alfa) {
    final cabeca = Path()
      ..addOval(Rect.fromCenter(center: o, width: r * 1.6, height: r * 1.1));
    _forma(c, cabeca, cor, alfa);
    final topo = o + Offset(r * .75, -r * 2.6);
    c.drawLine(o + Offset(r * .75, 0), topo, _traco..color = _contorno.withValues(alpha: alfa));
    final bandeira = Path()
      ..moveTo(topo.dx, topo.dy)
      ..quadraticBezierTo(topo.dx + r * 1.2, topo.dy + r * .6, topo.dx + r * .7, topo.dy + r * 1.5);
    c.drawPath(bandeira, _traco..color = _contorno.withValues(alpha: alfa));
  }

  /// "?" ou "!" de gibi, com pop de escala.
  void _sinal(Canvas c, Offset o, double p, double alfa, {required bool interrogacao}) {
    final pop = reduzir ? 1.0 : (p < .15 ? _sai(p / .15) * 1.2 : 1.2 - .2 * ((p - .15) / .15).clamp(0.0, 1.0));
    final bob = reduzir ? 0.0 : math.sin(p * math.pi * 3) * 3 * _k;
    final h = 30 * _k * pop;
    final centro = o + Offset(0, -h * .6 + bob);
    final cor = interrogacao ? const Color(0xFFFFD166) : const Color(0xFFFF5A5A);
    if (interrogacao) {
      final gancho = Path()
        ..moveTo(centro.dx - h * .22, centro.dy - h * .22)
        ..cubicTo(centro.dx - h * .22, centro.dy - h * .55, centro.dx + h * .3, centro.dy - h * .55,
            centro.dx + h * .26, centro.dy - h * .18)
        ..cubicTo(centro.dx + h * .22, centro.dy + h * .02, centro.dx, centro.dy - h * .02, centro.dx, centro.dy + h * .18);
      c.drawPath(
        gancho,
        _traco
          ..color = _contorno.withValues(alpha: alfa)
          ..strokeWidth = h * .2 + _lw * 2,
      );
      c.drawPath(
        gancho,
        Paint()
          ..color = cor.withValues(alpha: alfa)
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * .2
          ..strokeCap = StrokeCap.round,
      );
    } else {
      final haste = Path()
        ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(center: centro + Offset(0, -h * .12), width: h * .24, height: h * .62),
          Radius.circular(h * .12),
        ));
      _forma(c, haste, cor, alfa);
    }
    final ponto = Path()..addOval(Rect.fromCircle(center: centro + Offset(0, h * .42), radius: h * .12));
    _forma(c, ponto, cor, alfa);
  }

  void _gota(Canvas c, Offset o, double r, double alfa) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r * 1.6)
      ..cubicTo(o.dx + r * .4, o.dy - r * .9, o.dx + r * 1.1, o.dy + r * .1, o.dx, o.dy + r)
      ..cubicTo(o.dx - r * 1.1, o.dy + r * .1, o.dx - r * .4, o.dy - r * .9, o.dx, o.dy - r * 1.6)
      ..close();
    _forma(c, p, const Color(0xFF7CC8F5), alfa);
  }

  void _z(Canvas c, Offset o, double r, double alfa) {
    final p = Path()
      ..moveTo(o.dx - r, o.dy - r)
      ..lineTo(o.dx + r, o.dy - r)
      ..lineTo(o.dx - r, o.dy + r)
      ..lineTo(o.dx + r, o.dy + r);
    c.drawPath(
      p,
      _traco
        ..color = _contorno.withValues(alpha: alfa)
        ..strokeWidth = r * .45 + _lw,
    );
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFDCE6FF).withValues(alpha: alfa)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * .45
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// "POW" de gibi: estrela espetada amarela que estoura.
  void _estalo(Canvas c, Offset o, double p, double alfa, double escala) {
    final pop = reduzir ? 1.0 : (p < .25 ? _sai(p / .25) : 1 - (p - .25) * .4);
    final r = 22 * _k * pop * escala;
    if (r <= 0) return;
    final pts = Path();
    const pontas = 10;
    for (var i = 0; i < pontas * 2; i++) {
      final rr = i.isEven ? r : r * .55;
      final a = i * math.pi / pontas + .2;
      final q = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? pts.moveTo(q.dx, q.dy) : pts.lineTo(q.dx, q.dy);
    }
    pts.close();
    _forma(c, pts, const Color(0xFFFFD166), alfa);
    c.drawCircle(o, r * .32, Paint()..color = Colors.white.withValues(alpha: alfa));
  }

  void _estrelaCadente(Canvas c, Size s, double p, double alfa) {
    final q = reduzir ? .5 : _sai(p / .85);
    final de = Offset(-s.width * .05, s.height * .08);
    final ate = Offset(s.width * 1.05, s.height * .3);
    final cabeca = Offset.lerp(de, ate, q)!;
    final rastro = Offset.lerp(de, ate, (q - .22).clamp(0.0, 1.0))!;
    c.drawLine(
      rastro,
      cabeca,
      Paint()
        ..shader = LinearGradient(colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: .9 * alfa)])
            .createShader(Rect.fromPoints(rastro, cabeca))
        ..strokeWidth = 3 * _k
        ..strokeCap = StrokeCap.round,
    );
    _brilhinho(c, cabeca, 8 * _k, const Color(0xFFFFF6D5), alfa);
  }

  // ───────────────────────── projéteis ─────────────────────────

  void _projetil(Canvas c, Size s, ProjetilAtivo pr) {
    final idade = t - pr.inicio;
    if (idade < 0) return;
    if (reduzir) {
      if (idade >= .5) return;
      _bola(c, pr.para, pr.neve, 0, 1);
      return;
    }
    if (idade >= EfeitoHistoriaLayer.duracaoProjetil) return;
    if (idade < EfeitoHistoriaLayer.vooProjetil) {
      final q = idade / EfeitoHistoriaLayer.vooProjetil;
      final dist = (pr.para - pr.de).distance;
      final arco = math.max(40 * _k, dist * .35);
      final pos = Offset.lerp(pr.de, pr.para, q)! + Offset(0, -arco * 4 * q * (1 - q));
      _bola(c, pos, pr.neve, idade * 12, 1);
      return;
    }
    // respingo no alvo
    final q = (idade - EfeitoHistoriaLayer.vooProjetil) /
        (EfeitoHistoriaLayer.duracaoProjetil - EfeitoHistoriaLayer.vooProjetil);
    final cor = pr.neve ? Colors.white : const Color(0xFFF3EFE6);
    for (var i = 0; i < 7; i++) {
      final a = -math.pi * (.1 + .8 * i / 6);
      final pos = pr.para + Offset(math.cos(a), math.sin(a)) * (6 + 18 * _sai(q)) * _k;
      c.drawCircle(pos, (pr.neve ? 3.2 : 2.2) * _k * (1 - q * .6), Paint()..color = cor.withValues(alpha: 1 - q));
    }
    _estalo(c, pr.para, q, 1 - q, .45);
  }

  void _bola(Canvas c, Offset o, bool neve, double giro, double alfa) {
    final r = (neve ? 7.0 : 6.0) * _k;
    if (neve) {
      c.drawCircle(o, r, Paint()..color = Colors.white.withValues(alpha: alfa));
      c.drawCircle(o + Offset(r * .25, r * .25), r * .6, Paint()..color = const Color(0xFFDCEBFA).withValues(alpha: alfa));
      c.drawCircle(o, r, _traco..color = const Color(0xFF6D8BB0).withValues(alpha: alfa)..strokeWidth = _lw * .7);
    } else {
      // bolinha de papel amassado, girando
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(giro);
      final p = Path();
      for (var i = 0; i < 9; i++) {
        final rr = r * (i.isEven ? 1.0 : .82);
        final a = i * 2 * math.pi / 9;
        final q = Offset(math.cos(a) * rr, math.sin(a) * rr);
        i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
      }
      p.close();
      _forma(c, p, const Color(0xFFF3EFE6), alfa);
      c.drawLine(Offset(-r * .5, -r * .2), Offset(r * .4, r * .3), _traco..strokeWidth = _lw * .5);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(EfeitosHistoriaPainter old) =>
      old.t != t || old.reduzir != reduzir || old.efeitos != efeitos || old.projeteis != projeteis;
}
