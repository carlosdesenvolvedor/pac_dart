import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import 'cenario.dart';
import 'perspectiva.dart';

/// ⚽ O gol em PSEUDO-3D, visto da marca do pênalti: gramado listrado em
/// perspectiva com as linhas da área, arquibancada lotada no fundo, trave
/// com rede em profundidade, goleiro desenhado que mergulha pro canto e a
/// bola que voa em ARCO diminuindo até o gol — com a sombra correndo no
/// gramado. O mundo da fase muda o céu (e a luz do estádio).
class Gol3D extends StatelessWidget {
  final int fase;

  /// Canto onde a bola vai (0 esquerdo · 1 meio · 2 direito); null = parada
  /// na marca do pênalti.
  final int? zonaBola;

  /// Onde o goleiro está/pula (0/1/2 — 1 é o centro).
  final int zonaGoleiro;

  /// A cobrança já foi batida (goleiro mergulha).
  final bool revelado;

  /// Muda a cada cobrança pra reanimar a bola.
  final int chuteId;

  const Gol3D({
    super.key,
    required this.fase,
    required this.zonaBola,
    required this.zonaGoleiro,
    required this.revelado,
    required this.chuteId,
  });

  static const altura = 216.0;

  static const dMarca = 1.16;
  static const dGol = 1.95;
  static const dRede = 2.5;

  /// Altura do gol e meia-largura (meias-larguras do campo perto).
  static const hGol = 1.15;
  static const meiaLarguraGol = .62;

  static const _lateralZona = [-.42, 0.0, .42];
  static const _alturaZona = [.82, .42, .82];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: SizedBox(
        height: altura,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final p = Perspectiva(largura: w, altura: h, horizonte: h * .36, meiaLargura: w * .5);
          final tema = chaoDaFase(fase);
          final escuro = fase % 6 == 3 || fase % 6 == 5 || fase % 6 == 0; // cidade, vulcão, espaço

          return Stack(children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: p.horizonte + 2,
              child: CenarioFase(fase: fase),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _CampoPainter(p: p, tema: tema, noturno: escuro)),
            ),
            _goleiro(p),
            _bola(p),
          ]);
        }),
      ),
    );
  }

  Widget _goleiro(Perspectiva p) {
    final alturaPx = p.alturaChao * 1.0 / dGol;
    final larguraPx = alturaPx * .9;
    final mergulho = revelado ? zonaGoleiro - 1 : 0; // -1, 0, 1
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _lateralZona[zonaGoleiro]),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOut,
      builder: (_, lateral, child) {
        final pe = p.ponto(dGol, lateral);
        return Positioned(
          left: pe.dx - larguraPx / 2,
          top: pe.dy - alturaPx,
          width: larguraPx,
          height: alturaPx + alturaPx * .12,
          child: Stack(alignment: Alignment.bottomCenter, children: [
            Sombra(largura: larguraPx * .9, altura: alturaPx * .16, opacidade: .4),
            Positioned(
              bottom: alturaPx * .06,
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOut,
                turns: mergulho * .09,
                alignment: Alignment.bottomCenter,
                child: CustomPaint(
                  size: Size(larguraPx, alturaPx),
                  painter: _GoleiroPainter(mergulho: mergulho),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _bola(Perspectiva p) {
    const base = 30.0;
    final zona = zonaBola;
    if (zona == null) {
      return _bolaEm(p, dMarca, 0, 0, base, 0);
    }
    final lz = _lateralZona[zona];
    final hz = _alturaZona[zona] * hGol;
    return TweenAnimationBuilder<double>(
      key: ValueKey('chute$chuteId'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, t, _) {
        final d = dMarca + (dGol - dMarca) * t;
        final l = lz * t;
        final hb = hz * t + .38 * math.sin(math.pi * t);
        return _bolaEm(p, d, l, hb, base, t * 6);
      },
    );
  }

  /// Bola (com sombra no gramado) a distância [d], lateral [l] e altura [hb].
  Widget _bolaEm(Perspectiva p, double d, double l, double hb, double base, double giro) {
    final tam = base * dMarca / d;
    final chao = p.ponto(d, l);
    final centro = p.acima(d, l, hb);
    final sombraW = tam * 1.1 * (1 - hb * .35).clamp(.4, 1);
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(children: [
          Positioned(
            left: chao.dx - sombraW / 2,
            top: chao.dy - sombraW * .13,
            child: Sombra(largura: sombraW, altura: sombraW * .26, opacidade: .38),
          ),
          Positioned(
            left: centro.dx - tam / 2,
            top: centro.dy - tam / 2,
            child: Transform.rotate(
              angle: giro,
              child: CustomPaint(size: Size.square(tam), painter: _BolaPainter()),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Gramado, linhas, arquibancada, trave e rede.
class _CampoPainter extends CustomPainter {
  final Perspectiva p;
  final TemaChao tema;
  final bool noturno;
  _CampoPainter({required this.p, required this.tema, required this.noturno});

  @override
  void paint(Canvas c, Size s) {
    _arquibancada(c);
    final grama = noturno ? (const Color(0xFF3F7D3C), const Color(0xFF366D34)) : (const Color(0xFF63AC57), const Color(0xFF57A04C));
    pintarChaoEmFaixas(c, p, claro: grama.$1, escuro: grama.$2, segmento: .26, ate: 14);
    _linhas(c);
    _rede(c);
    pintarNeblina(c, p, tema.neblina, ate: .35);
    _trave(c);
  }

  void _arquibancada(Canvas c) {
    final topo = p.horizonte * .58;
    final r = Rect.fromLTRB(0, topo, p.largura, p.horizonte + 2);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2B2F3A), Color(0xFF1C2028)],
        ).createShader(r),
    );
    // a torcida: pontinhos coloridos em fileiras (estável entre frames)
    const cores = [Color(0xFFF2555A), Color(0xFF4FC3F7), Color(0xFFF4F1EA), Color(0xFFFFC73B), Color(0xFF9E9E9E)];
    var fila = 0;
    for (var y = topo + 3; y < p.horizonte - 6; y += 4.2, fila++) {
      for (var x = 2.0 + (fila.isEven ? 0 : 2); x < p.largura; x += 4.4) {
        final k = ((x * 7).round() + fila * 13) % 11;
        if (k == 0) continue; // cadeiras vazias
        c.drawCircle(Offset(x, y), 1.25, Paint()..color = cores[k % cores.length].withValues(alpha: .85));
      }
    }
    // placa de publicidade na beira do gramado
    final placa = Rect.fromLTRB(0, p.horizonte - 6, p.largura, p.horizonte + 1);
    c.drawRect(placa, Paint()..color = const Color(0xFF10131A));
    for (var x = 0.0; x < p.largura; x += 70) {
      c.drawRect(Rect.fromLTWH(x + 8, p.horizonte - 5, 34, 5), Paint()..color = Mixart.brand.withValues(alpha: .85));
      c.drawRect(Rect.fromLTWH(x + 46, p.horizonte - 5, 18, 5), Paint()..color = const Color(0xFF4FC3F7).withValues(alpha: .8));
    }
  }

  void _linhas(Canvas c) {
    final linha = Paint()
      ..color = Colors.white.withValues(alpha: .88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    // linha de fundo
    c.drawLine(p.ponto(Gol3D.dGol, -2.2), p.ponto(Gol3D.dGol, 2.2), linha);
    // pequena área
    c.drawPath(p.faixa(Gol3D.dGol - .34, Gol3D.dGol, -.98, .98), linha);
    // grande área (o lado de cá some fora da tela — como no estádio)
    c.drawPath(p.faixa(Gol3D.dGol - .92, Gol3D.dGol, -1.62, 1.62), linha);
    // marca do pênalti
    final marca = p.ponto(Gol3D.dMarca, 0);
    c.drawOval(Rect.fromCenter(center: marca, width: 9, height: 4), Paint()..color = Colors.white);
  }

  void _rede(Canvas c) {
    final malha = Paint()
      ..color = Colors.white.withValues(alpha: .34)
      ..strokeWidth = 1;
    const mg = Gol3D.meiaLarguraGol;
    const df = Gol3D.dGol, dr = Gol3D.dRede, hg = Gol3D.hGol;
    // fundo da rede
    for (var l = -mg; l <= mg + 1e-6; l += mg / 6) {
      c.drawLine(p.ponto(dr, l), p.acima(dr, l, hg), malha);
    }
    for (var k = 0; k <= 6; k++) {
      final hh = hg * k / 6;
      c.drawLine(p.acima(dr, -mg, hh), p.acima(dr, mg, hh), malha);
    }
    // laterais e teto (linhas que fogem da trave pro fundo)
    for (var k = 0; k <= 6; k++) {
      final hh = hg * k / 6;
      c.drawLine(p.acima(df, -mg, hh), p.acima(dr, -mg, hh), malha);
      c.drawLine(p.acima(df, mg, hh), p.acima(dr, mg, hh), malha);
    }
    for (var l = -mg; l <= mg + 1e-6; l += mg / 6) {
      c.drawLine(p.acima(df, l, hg), p.acima(dr, l, hg), malha);
    }
    for (var k = 1; k <= 3; k++) {
      final dd = df + (dr - df) * k / 3;
      c.drawLine(p.ponto(dd, -mg), p.acima(dd, -mg, hg), malha);
      c.drawLine(p.ponto(dd, mg), p.acima(dd, mg, hg), malha);
      c.drawLine(p.acima(dd, -mg, hg), p.acima(dd, mg, hg), malha);
    }
    // fundo da rede um pouco mais denso (sombra do gol)
    c.drawPath(
      Path()
        ..moveTo(p.ponto(dr, -mg).dx, p.ponto(dr, -mg).dy)
        ..lineTo(p.ponto(dr, mg).dx, p.ponto(dr, mg).dy)
        ..lineTo(p.acima(dr, mg, hg).dx, p.acima(dr, mg, hg).dy)
        ..lineTo(p.acima(dr, -mg, hg).dx, p.acima(dr, -mg, hg).dy)
        ..close(),
      Paint()..color = Colors.black.withValues(alpha: .12),
    );
  }

  void _trave(Canvas c) {
    const mg = Gol3D.meiaLarguraGol;
    const df = Gol3D.dGol, hg = Gol3D.hGol;
    final esq = p.ponto(df, -mg), dir = p.ponto(df, mg);
    final esqT = p.acima(df, -mg, hg), dirT = p.acima(df, mg, hg);
    final grossura = math.max(3.0, 7.0 / df);
    final sombra = Paint()
      ..color = Colors.black.withValues(alpha: .25)
      ..strokeWidth = grossura + 2
      ..strokeCap = StrokeCap.round;
    final poste = Paint()
      ..color = const Color(0xFFF4F6F8)
      ..strokeWidth = grossura
      ..strokeCap = StrokeCap.round;
    for (final tinta in [sombra, poste]) {
      c.drawLine(esq, esqT, tinta);
      c.drawLine(dir, dirT, tinta);
      c.drawLine(esqT, dirT, tinta);
    }
    // luz nos postes (cilindro)
    final luz = Paint()
      ..color = Colors.white.withValues(alpha: .6)
      ..strokeWidth = grossura * .3
      ..strokeCap = StrokeCap.round;
    c.drawLine(esq.translate(-grossura * .2, 0), esqT.translate(-grossura * .2, 0), luz);
    c.drawLine(dir.translate(-grossura * .2, 0), dirT.translate(-grossura * .2, 0), luz);
  }

  @override
  bool shouldRepaint(_CampoPainter old) =>
      old.tema != tema || old.noturno != noturno || old.p.largura != p.largura || old.p.altura != p.altura;
}

/// Goleiro estilizado: camisa com luz, luvas amarelas, mergulho pro canto.
class _GoleiroPainter extends CustomPainter {
  /// -1 esquerda · 0 parado · 1 direita.
  final int mergulho;
  _GoleiroPainter({required this.mergulho});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final cx = w / 2;
    final pele = Paint()..color = const Color(0xFFE0AC7E);
    // pernas
    final perna = Paint()
      ..color = const Color(0xFF1F2933)
      ..strokeWidth = w * .11
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - w * .12, h * .62), Offset(cx - w * .2, h * .97), perna);
    c.drawLine(Offset(cx + w * .12, h * .62), Offset(cx + w * .2, h * .97), perna);
    // calção
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - w * .19, h * .52, w * .38, h * .16), Radius.circular(w * .05)),
        Paint()..color = const Color(0xFF263241));
    // camisa com luz
    final camisa = Rect.fromLTWH(cx - w * .22, h * .26, w * .44, h * .32);
    c.drawRRect(
      RRect.fromRectAndRadius(camisa, Radius.circular(w * .09)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4FE0C1), Color(0xFF17A589), Color(0xFF0E7A66)],
        ).createShader(camisa),
    );
    pintarTexto(c, '1', Offset(cx, h * .42), tamanho: h * .14, cor: Colors.white.withValues(alpha: .85));
    // braços + luvas
    final braco = Paint()
      ..color = const Color(0xFF17A589)
      ..strokeWidth = w * .1
      ..strokeCap = StrokeCap.round;
    final luva = Paint()..color = const Color(0xFFFFC73B);
    final ombroE = Offset(cx - w * .2, h * .3), ombroD = Offset(cx + w * .2, h * .3);
    late Offset maoE, maoD;
    switch (mergulho) {
      case -1:
        maoE = Offset(cx - w * .5, h * .02);
        maoD = Offset(cx - w * .12, h * .0);
      case 1:
        maoE = Offset(cx + w * .12, h * .0);
        maoD = Offset(cx + w * .5, h * .02);
      default:
        maoE = Offset(cx - w * .46, h * .46);
        maoD = Offset(cx + w * .46, h * .46);
    }
    c.drawLine(ombroE, maoE, braco);
    c.drawLine(ombroD, maoD, braco);
    c.drawCircle(maoE, w * .085, luva);
    c.drawCircle(maoD, w * .085, luva);
    // cabeça
    c.drawCircle(Offset(cx, h * .16), h * .11, pele);
    c.drawArc(Rect.fromCircle(center: Offset(cx, h * .155), radius: h * .112), math.pi, math.pi, true,
        Paint()..color = const Color(0xFF3B2A20));
    c.drawCircle(Offset(cx - h * .04, h * .17), h * .015, Paint()..color = const Color(0xFF1B1F27));
    c.drawCircle(Offset(cx + h * .04, h * .17), h * .015, Paint()..color = const Color(0xFF1B1F27));
  }

  @override
  bool shouldRepaint(_GoleiroPainter old) => old.mergulho != mergulho;
}

/// Bola de futebol com volume: esfera branca iluminada e gomos escuros.
class _BolaPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = s.width / 2;
    final centro = Offset(r, r);
    final rect = Rect.fromCircle(center: centro, radius: r);
    c.drawCircle(
      centro,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.4, -.45),
          radius: .95,
          colors: [Colors.white, Color(0xFFE8ECF0), Color(0xFF9AA4AE)],
          stops: [0, .55, 1],
        ).createShader(rect),
    );
    c.save();
    c.clipPath(Path()..addOval(rect));
    final gomo = Paint()..color = const Color(0xFF1B1F27).withValues(alpha: .9);
    for (final (fx, fy, fr) in [(.5, .5, .21), (.08, .28, .17), (.92, .34, .16), (.28, .96, .17), (.78, .92, .16), (.5, .02, .14)]) {
      c.drawCircle(Offset(fx * 2 * r, fy * 2 * r), fr * r, gomo);
    }
    c.restore();
    c.drawCircle(
        centro,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, r * .08)
          ..color = const Color(0xFF6B7681).withValues(alpha: .6));
    c.drawOval(
      Rect.fromCenter(center: Offset(r * .62, r * .55), width: r * .5, height: r * .3),
      Paint()
        ..color = Colors.white.withValues(alpha: .55)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, r * .12),
    );
  }

  @override
  bool shouldRepaint(_BolaPainter old) => false;
}
