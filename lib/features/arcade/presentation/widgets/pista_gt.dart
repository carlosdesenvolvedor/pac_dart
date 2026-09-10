import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/personagem.dart';
import '../../domain/turismo.dart';
import 'cenario.dart';
import 'perspectiva.dart';
import 'velocimetro.dart';

/// 🏎️ A vista da corrida do Dart Turismo: estrada pseudo-3D que faz curvas
/// de verdade (a técnica dos racers clássicos: a curva acumula segmento a
/// segmento e dobra a pista), cenário com paralaxe, adereços e portais
/// passando, carros bloqueando as faixas, o SEU carro visto de trás
/// (inclina ao trocar de faixa, lanternas ao frear, chamas no boost, faróis
/// à noite), rastros de velocidade e velocímetro de ponteiro.
class VistaCorrida extends StatelessWidget {
  final TurismoEngine engine;

  /// Relógio de animação em segundos (piscar, rastros).
  final double relogio;
  const VistaCorrida({super.key, required this.engine, this.relogio = 0});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: LayoutBuilder(builder: (context, box) {
        final h = box.maxHeight;
        final horizonte = h * .46;
        // a curva empurra o horizonte pro lado oposto (paralaxe do fundo)
        final paralaxe = (-engine.curvaAtual * 16).clamp(-110.0, 110.0);
        final tema = chaoDaFase(engine.pista.tema);
        final t = (engine.pista.tema - 1) % 6;
        final noturno = t == 2 || t == 4 || t == 5;
        return Stack(children: [
          Positioned(
            left: -120 + paralaxe,
            right: -120 - paralaxe,
            top: 0,
            height: horizonte + 2,
            child: CenarioFase(fase: engine.pista.tema),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _EstradaGtPainter(
                engine: engine,
                horizonte: horizonte,
                relogio: relogio,
                tema: tema,
                noturno: noturno,
                piloto: PersonagemStore.atual,
              ),
            ),
          ),
        ]);
      }),
    );
  }
}

class _Proj {
  final double x, y, w, escala;
  const _Proj(this.x, this.y, this.w, this.escala);
}

class _SegProj {
  final Segmento seg;
  final _Proj p1, p2;
  final double neblina;
  const _SegProj(this.seg, this.p1, this.p2, this.neblina);
}

class _EstradaGtPainter extends CustomPainter {
  final TurismoEngine engine;
  final double horizonte;
  final double relogio;
  final TemaChao tema;
  final bool noturno;
  final Personagem piloto;

  _EstradaGtPainter({
    required this.engine,
    required this.horizonte,
    required this.relogio,
    required this.tema,
    required this.noturno,
    required this.piloto,
  });

  /// Meia largura da pista (3 faixas) em metros.
  static const meiaPista = TurismoEngine.larguraFaixa * 1.5;
  static const alturaCamera = 1.5;

  /// 1/tan(fov/2) — campo de visão ≈ 100°.
  static const profundidade = .84;
  static const distDesenho = 70;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final f = w / 2; // px por metro na escala 1
    const L = TurismoEngine.comprimentoSegmento;
    final segs = engine.segmentos;
    final pos = engine.posicao;
    final base = (pos / L).floor().clamp(0, segs.length - 1);
    final basePct = ((pos - base * L) / L).clamp(0.0, 1.0);
    final camX = engine.xAtual;

    c.drawRect(Rect.fromLTWH(0, horizonte, w, h - horizonte), Paint()..color = tema.escuro);

    // ---- projeção dos segmentos (a curva acumula e dobra a estrada)
    final visiveis = <_SegProj>[];
    var x = 0.0;
    var dx = -(segs[base].curva * basePct);
    var maxY = h;
    for (var n = 0; n < distDesenho; n++) {
      final idx = base + n;
      if (idx >= segs.length) break;
      final seg = segs[idx];
      final z1 = idx * L - pos;
      final z2 = z1 + L;
      // o segmento sob o carro começa atrás da câmera: corta no plano próximo
      final p1 = _projetar(math.max(z1, profundidade + .02), x - camX, f);
      final p2 = _projetar(z2, x + dx - camX, f);
      x += dx;
      dx += seg.curva;
      if (p1 == null || p2 == null || p2.y >= maxY) continue;
      final neblina = math.exp(-math.pow(n / distDesenho, 2) * 4.5);
      visiveis.add(_SegProj(seg, p1, p2, neblina));
      maxY = p2.y;
    }

    // ---- estrada, do mais perto pro mais longe? não: pintamos do mais LONGE
    // pro mais perto pra que o perto cubra o longe nas curvas fechadas
    for (final sp in visiveis.reversed) {
      _segmento(c, sp, w);
    }

    // ---- adereços e portais (sprites), do mais longe pro mais perto
    final portalPorIndice = {for (final p in engine.portais) p.indice: p};
    for (final sp in visiveis.reversed) {
      _adereco(c, sp, f);
      final portal = portalPorIndice[sp.seg.indice];
      if (portal != null) _portal(c, sp, portal, f);
    }

    _neblinaHorizonte(c, w);
    if (noturno) _farois(c, w, h);
    _rastros(c, w, h);
    _carro(
      c,
      Offset(w / 2, h * .965),
      (w * .24).clamp(120, 230).toDouble(),
      Mixart.brand,
      inclinacao: (engine.xAlvo - engine.xAtual) / TurismoEngine.larguraFaixa,
      freio: engine.velocidade > 0 && engine.boost == 0 && engine.correndo && _freando,
      boost: engine.boost,
      farol: noturno,
      capacete: piloto == Personagem.dash ? const Color(0xFF55B8EE) : Mixart.brand,
    );
    if (engine.impacto > 0) _impacto(c, w, h);
    _velocimetro(c, Offset(w - 62, h - 62), 46);
  }

  bool get _freando => engine.velocidade < engine.velMax * .3 || engine.impacto > .5;

  _Proj? _projetar(double z, double camXRel, double f) {
    if (z <= profundidade) return null;
    final escala = profundidade / z;
    return _Proj(
      f + escala * camXRel * f,
      horizonte + escala * alturaCamera * f,
      escala * meiaPista * f,
      escala,
    );
  }

  Color _neblina(Color cor, double fator) => Color.lerp(tema.neblina, cor, fator)!;

  Path _quad(double x1, double y1, double w1, double x2, double y2, double w2) => Path()
    ..moveTo(x1 - w1, y1)
    ..lineTo(x1 + w1, y1)
    ..lineTo(x2 + w2, y2)
    ..lineTo(x2 - w2, y2)
    ..close();

  void _segmento(Canvas c, _SegProj sp, double w) {
    final idx = sp.seg.indice;
    final claro = (idx ~/ 3).isEven;
    final p1 = sp.p1, p2 = sp.p2;
    final nb = sp.neblina;
    // chão do mundo
    c.drawRect(
      Rect.fromLTRB(0, p2.y, w, p1.y + .5),
      Paint()..color = _neblina(claro ? tema.claro : tema.escuro, nb),
    );
    // zebras
    final zebra = Paint()..color = _neblina(claro ? const Color(0xFFE53935) : Colors.white, nb);
    c.drawPath(_quad(p1.x - p1.w * 1.06, p1.y, p1.w * .07, p2.x - p2.w * 1.06, p2.y, p2.w * .07), zebra);
    c.drawPath(_quad(p1.x + p1.w * 1.06, p1.y, p1.w * .07, p2.x + p2.w * 1.06, p2.y, p2.w * .07), zebra);
    // asfalto
    final asfalto = noturno
        ? (claro ? const Color(0xFF2E333B) : const Color(0xFF292E35))
        : (claro ? const Color(0xFF3D444D) : const Color(0xFF373E47));
    c.drawPath(_quad(p1.x, p1.y, p1.w, p2.x, p2.y, p2.w), Paint()..color = _neblina(asfalto, nb));
    // largada (segmentos 2-3) e chegada quadriculadas
    final fim = (engine.pista.distancia / TurismoEngine.comprimentoSegmento).floor();
    if ((idx >= 2 && idx <= 3) || (idx >= fim && idx <= fim + 1)) {
      const colunas = 8;
      for (var col = 0; col < colunas; col++) {
        final a = -1 + 2 * col / colunas, b = -1 + 2 * (col + 1) / colunas;
        final tinta = Paint()..color = (col + idx).isEven ? Colors.white : const Color(0xFF16191E);
        c.drawPath(
          Path()
            ..moveTo(p1.x + p1.w * a, p1.y)
            ..lineTo(p1.x + p1.w * b, p1.y)
            ..lineTo(p2.x + p2.w * b, p2.y)
            ..lineTo(p2.x + p2.w * a, p2.y)
            ..close(),
          tinta,
        );
      }
      return;
    }
    // faixas tracejadas entre as 3 pistas
    if (claro) {
      final linha = Paint()..color = _neblina(Colors.white.withValues(alpha: .75), nb);
      for (final l in [-1 / 3, 1 / 3]) {
        c.drawPath(
          _quad(p1.x + p1.w * l, p1.y, p1.w * .022, p2.x + p2.w * l, p2.y, p2.w * .022),
          linha,
        );
      }
    }
  }

  /// Árvores, postes, cactos… na beira (sorteio estável por segmento).
  void _adereco(Canvas c, _SegProj sp, double f) {
    final idx = sp.seg.indice;
    final k = (idx * 7919) % 11;
    if (k > 5) return;
    final lado = k.isEven ? -1 : 1;
    final desloca = 1.55 + (k * .23);
    final esc = sp.p1.escala;
    final sx = sp.p1.x + esc * lado * desloca * meiaPista * f;
    final sy = sp.p1.y;
    final alt = esc * 4.2 * f; // ~4 m
    if (alt < 2) return;
    final nb = sp.neblina;
    final w = alt * .5;
    Color n(Color cor) => _neblina(cor, nb);
    switch (tema.adereco) {
      case Adereco.arvore:
        c.drawRect(Rect.fromLTWH(sx - w * .08, sy - alt * .42, w * .16, alt * .42), Paint()..color = n(const Color(0xFF6D4C2F)));
        c.drawCircle(Offset(sx, sy - alt * .64), w * .5, Paint()..color = n(const Color(0xFF2F6E33)));
        c.drawCircle(Offset(sx - w * .16, sy - alt * .74), w * .3, Paint()..color = n(const Color(0xFF4C9A4A)));
      case Adereco.pinheiro:
        c.drawRect(Rect.fromLTWH(sx - w * .07, sy - alt * .25, w * .14, alt * .25), Paint()..color = n(const Color(0xFF5B3B26)));
        for (final (base, larg, a, cor) in [(.22, 1.0, .5, const Color(0xFF2F5D46)), (.5, .75, .42, const Color(0xFF3C7357)), (.74, .5, .3, const Color(0xFFE9F4FA))]) {
          c.drawPath(
            Path()
              ..moveTo(sx - w * larg / 2, sy - alt * base)
              ..lineTo(sx, sy - alt * (base + a))
              ..lineTo(sx + w * larg / 2, sy - alt * base)
              ..close(),
            Paint()..color = n(cor),
          );
        }
      case Adereco.cacto:
        final tinta = Paint()
          ..color = n(const Color(0xFF4E8F4A))
          ..strokeWidth = math.max(1, w * .28)
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(sx, sy), Offset(sx, sy - alt * .9), tinta);
        c.drawLine(Offset(sx, sy - alt * .5), Offset(sx - w * .4, sy - alt * .7), tinta);
        c.drawLine(Offset(sx, sy - alt * .4), Offset(sx + w * .4, sy - alt * .64), tinta);
      case Adereco.poste:
        c.drawLine(Offset(sx, sy), Offset(sx, sy - alt), Paint()..color = n(const Color(0xFF8A96A3))..strokeWidth = math.max(1, w * .1));
        c.drawCircle(Offset(sx, sy - alt), w * .6, Paint()..color = const Color(0xFFFFE082).withValues(alpha: .3)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, math.max(1, w * .4)));
        c.drawCircle(Offset(sx, sy - alt), w * .16, Paint()..color = const Color(0xFFFFF3C4));
      case Adereco.rocha:
        c.drawOval(Rect.fromCenter(center: Offset(sx, sy - alt * .18), width: w * 1.3, height: alt * .4), Paint()..color = n(const Color(0xFF2A1613)));
        c.drawOval(Rect.fromCenter(center: Offset(sx - w * .15, sy - alt * .27), width: w * .7, height: alt * .18), Paint()..color = n(const Color(0xFF5A3A32)));
      case Adereco.cristal:
        final cor = idx.isEven ? const Color(0xFFB388FF) : const Color(0xFF80DEEA);
        final cristal = Path()
          ..moveTo(sx, sy - alt)
          ..lineTo(sx + w * .35, sy - alt * .45)
          ..lineTo(sx, sy)
          ..lineTo(sx - w * .35, sy - alt * .45)
          ..close();
        c.drawPath(cristal, Paint()..color = cor.withValues(alpha: .3)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, math.max(1, w * .3)));
        c.drawPath(cristal, Paint()..color = n(cor));
    }
  }

  static const _coresBloqueio = [Color(0xFFE53935), Color(0xFF4FC3F7), Color(0xFFF4F1EA), Color(0xFF9E9E9E), Color(0xFF57C765), Color(0xFFB388FF)];

  /// Pórtico com as placas das faixas + carros parados nas faixas bloqueadas.
  void _portal(Canvas c, _SegProj sp, Portal portal, double f) {
    final esc = sp.p1.escala;
    final px = sp.p1.x, py = sp.p1.y;
    final nb = sp.neblina;
    double lateral(double m) => px + esc * m * f;
    double altura(double m) => py - esc * m * f;
    final atual = engine.portalAtual == portal;

    // carros parados nas faixas bloqueadas (atrás do pórtico)
    for (var faixa = 0; faixa < 3; faixa++) {
      if (portal.faixas.contains(faixa)) continue;
      final cx = lateral((faixa - 1) * TurismoEngine.larguraFaixa);
      final larg = esc * 1.9 * f;
      if (larg < 3) continue;
      _carro(c, Offset(cx, py), larg, _neblina(_coresBloqueio[(portal.indice + faixa) % _coresBloqueio.length], nb), simples: true, farol: noturno);
    }

    // postes e viga
    final grosso = math.max(1.0, esc * .28 * f);
    final poste = Paint()
      ..color = _neblina(const Color(0xFFD9DEE3), nb)
      ..strokeWidth = grosso
      ..strokeCap = StrokeCap.round;
    for (final lado in [-1.22, 1.22]) {
      c.drawLine(Offset(lateral(lado * meiaPista), py), Offset(lateral(lado * meiaPista), altura(5.4)), poste);
    }
    final viga = Rect.fromLTRB(lateral(-1.22 * meiaPista), altura(5.4), lateral(1.22 * meiaPista), altura(4.7));
    c.drawRect(viga, Paint()..color = _neblina(const Color(0xFF232830), nb));
    c.drawRect(viga, Paint()..color = _neblina(const Color(0xFFD9DEE3), nb)..style = PaintingStyle.stroke..strokeWidth = math.max(.8, grosso * .5));

    // placas por faixa
    for (var faixa = 0; faixa < 3; faixa++) {
      final cx = lateral((faixa - 1) * TurismoEngine.larguraFaixa);
      final boxW = esc * 3.3 * f;
      final boxH = esc * 1.15 * f;
      if (boxW < 6) continue;
      final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, altura(3.9)), width: boxW, height: boxH), Radius.circular(boxH * .18));
      final i = portal.faixas.indexOf(faixa);
      if (i < 0) {
        c.drawRRect(r, Paint()..color = _neblina(const Color(0xFFB3261E), nb));
        if (boxH >= 9) pintarTexto(c, '✕', r.center, tamanho: boxH * .62, cor: Colors.white);
        continue;
      }
      final digitada = portal.digitado == i;
      final travada = atual && engine.palavraTravada == i;
      c.drawRRect(r, Paint()..color = _neblina(digitada ? const Color(0xFF1B5E20) : const Color(0xFF10131A), nb));
      c.drawRRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(.8, boxH * .07)
            ..color = _neblina(digitada ? const Color(0xFF57C765) : (travada ? Mixart.brand : const Color(0xFF57C765).withValues(alpha: .8)), nb));
      if (boxW >= 26) {
        final texto = digitada ? '✓' : portal.palavras[i];
        final tam = math.min(boxH * .6, boxW / (texto.length * .64 + .6));
        pintarTexto(c, texto, r.center, tamanho: tam, cor: digitada ? const Color(0xFF9CE99C) : Colors.white, peso: FontWeight.w700, espaco: .5);
      }
    }
  }

  void _neblinaHorizonte(Canvas c, double w) {
    final r = Rect.fromLTWH(0, horizonte - 2, w, 70);
    c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [tema.neblina.withValues(alpha: .55), tema.neblina.withValues(alpha: 0)],
        ).createShader(r),
    );
  }

  /// Faróis à noite: dois cones de luz projetados na pista.
  void _farois(Canvas c, double w, double h) {
    final larg = (w * .24).clamp(120.0, 230.0);
    final topoCarro = h * .965 - larg * .58;
    for (final lado in [-1, 1]) {
      final origem = Offset(w / 2 + lado * larg * .3, topoCarro);
      final cone = Path()
        ..moveTo(origem.dx - larg * .12, origem.dy)
        ..lineTo(origem.dx + larg * .12, origem.dy)
        ..lineTo(w / 2 + lado * w * .22, horizonte + 40)
        ..lineTo(w / 2 + lado * w * .02, horizonte + 40)
        ..close();
      c.drawPath(
        cone,
        Paint()
          ..shader = ui.Gradient.linear(
            origem,
            Offset(origem.dx, horizonte + 40),
            [const Color(0xFFFFF3C4).withValues(alpha: .26), const Color(0xFFFFF3C4).withValues(alpha: 0)],
          ),
      );
    }
  }

  /// Rastros de velocidade nas beiradas (aparecem acima de 35% da máxima).
  void _rastros(Canvas c, double w, double h) {
    final fr = engine.fracaoVel;
    if (fr < .35) return;
    final forca = ((fr - .35) / .65).clamp(0.0, 1.0);
    final fuga = Offset(w / 2, horizonte);
    final tinta = Paint()..strokeWidth = 1.2;
    const n = 22;
    for (var i = 0; i < n; i++) {
      final t = i / n;
      // ponto na borda: distribui pelos lados e pelo chão
      final borda = t < .5 ? Offset(0, h * (.2 + t * 1.6)) : Offset(w, h * (.2 + (t - .5) * 1.6));
      final pisca = .5 + .5 * math.sin(relogio * 26 + i * 1.7);
      tinta.color = Colors.white.withValues(alpha: forca * .35 * pisca);
      c.drawLine(Offset.lerp(fuga, borda, .55 + .1 * pisca)!, borda, tinta);
    }
  }

  void _impacto(Canvas c, double w, double h) {
    final r = Rect.fromLTWH(0, 0, w, h);
    c.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          radius: 1,
          colors: [Colors.transparent, const Color(0xFFF2555A).withValues(alpha: engine.impacto * .6)],
          stops: const [.45, 1],
        ).createShader(r),
    );
  }

  /// Carro visto de trás. [simples] = carro parado de outra cor (bloqueio).
  void _carro(
    Canvas c,
    Offset base,
    double larg,
    Color cor, {
    double inclinacao = 0,
    bool freio = false,
    double boost = 0,
    bool farol = false,
    bool simples = false,
    Color capacete = const Color(0xFFFFC73B),
  }) {
    final alt = larg * .58;
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(inclinacao * .11);
    // sombra
    c.drawOval(
      Rect.fromCenter(center: Offset(0, -alt * .02), width: larg * 1.12, height: alt * .2),
      Paint()
        ..color = Colors.black.withValues(alpha: .45)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, math.max(1, larg * .04)),
    );
    // chamas do boost (saem do escapamento)
    if (boost > 0) {
      for (final lado in [-1, 1]) {
        final ch = Rect.fromCenter(center: Offset(lado * larg * .3, alt * .12 * boost + alt * .02), width: larg * .12, height: alt * .28 * boost);
        c.drawOval(ch, Paint()..color = const Color(0xFFFF7043).withValues(alpha: .8 * boost)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, larg * .03));
        c.drawOval(ch.deflate(larg * .03), Paint()..color = const Color(0xFFFFE082).withValues(alpha: .9 * boost));
      }
    }
    // rodas
    final roda = Paint()..color = const Color(0xFF1B1F27);
    final pneu = RRect.fromRectAndRadius(Rect.fromLTWH(-larg * .5, -alt * .3, larg * .15, alt * .32), Radius.circular(larg * .03));
    c.drawRRect(pneu, roda);
    c.drawRRect(pneu.shift(Offset(larg * .85, 0)), roda);
    // para-choque
    final escuro = tom(cor, .45);
    final claro = tom(cor, 1.25);
    final choque = RRect.fromRectAndRadius(Rect.fromLTWH(-larg * .49, -alt * .36, larg * .98, alt * .36), Radius.circular(larg * .05));
    c.drawRRect(choque, Paint()..color = escuro);
    // carroceria
    final corpo = RRect.fromRectAndRadius(Rect.fromLTWH(-larg * .46, -alt * .68, larg * .92, alt * .46), Radius.circular(larg * .06));
    c.drawRRect(
      corpo,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [claro, cor, escuro],
          stops: const [0, .5, 1],
        ).createShader(corpo.outerRect),
    );
    // vidro traseiro + teto
    final vidro = Path()
      ..moveTo(-larg * .32, -alt * .66)
      ..lineTo(larg * .32, -alt * .66)
      ..lineTo(larg * .24, -alt * .92)
      ..lineTo(-larg * .24, -alt * .92)
      ..close();
    c.drawPath(vidro, Paint()..color = const Color(0xFF141A22));
    c.drawPath(
      vidro,
      Paint()
        ..shader = ui.Gradient.linear(Offset(-larg * .3, -alt * .9), Offset(larg * .3, -alt * .66),
            [Colors.white.withValues(alpha: .28), Colors.white.withValues(alpha: 0)]),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(-larg * .25, -alt * .98, larg * .5, alt * .08), Radius.circular(larg * .02)),
      Paint()..color = cor,
    );
    if (!simples) {
      // o piloto (capacete) atrás do vidro
      c.drawCircle(Offset(-larg * .08, -alt * .78), larg * .055, Paint()..color = capacete);
      c.drawRect(Rect.fromLTWH(-larg * .12, -alt * .79, larg * .08, alt * .03), Paint()..color = const Color(0xFF141A22));
      // aerofólio
      final aero = Paint()..color = escuro;
      c.drawRect(Rect.fromLTWH(-larg * .42, -alt * .8, larg * .84, alt * .06), aero);
      c.drawRect(Rect.fromLTWH(-larg * .36, -alt * .74, larg * .05, alt * .08), aero);
      c.drawRect(Rect.fromLTWH(larg * .31, -alt * .74, larg * .05, alt * .08), aero);
    }
    // lanternas
    final lanterna = Paint()..color = freio ? const Color(0xFFFF1744) : const Color(0xFFB71C1C);
    for (final lado in [-1, 1]) {
      final r = Rect.fromCenter(center: Offset(lado * larg * .33, -alt * .5), width: larg * .16, height: alt * .09);
      if (freio || farol) {
        c.drawRect(r.inflate(larg * .03), Paint()..color = const Color(0xFFFF1744).withValues(alpha: .5)..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, larg * .04));
      }
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(larg * .02)), lanterna);
    }
    // placa
    if (larg >= 40) {
      final placa = Rect.fromCenter(center: Offset(0, -alt * .2), width: larg * .22, height: alt * .09);
      c.drawRRect(RRect.fromRectAndRadius(placa, Radius.circular(2)), Paint()..color = const Color(0xFFE8ECF0));
      if (larg >= 90) pintarTexto(c, 'DART', placa.center, tamanho: alt * .07, cor: const Color(0xFF1B1F27), espaco: 1);
    }
    // escapamentos
    for (final lado in [-1, 1]) {
      c.drawCircle(Offset(lado * larg * .3, -alt * .05), larg * .03, Paint()..color = const Color(0xFF0E1116));
    }
    c.restore();
  }

  /// Velocímetro de ponteiro no canto.
  void _velocimetro(Canvas c, Offset centro, double r) =>
      pintarVelocimetro(c, centro, r, engine.fracaoVel, (engine.velocidade * 3.6).round());

  @override
  bool shouldRepaint(_EstradaGtPainter old) => true;
}
