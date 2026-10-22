import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ingles/domain/boca.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import '../../domain/historia_turismo.dart';

/// 🎒 Um prop da história (carro, troféu, mapa, celular com o rostinho do remoto…).
///
/// Desenho chapado de desenho animado: preenchimento, uma faixa de sombra e contorno `0xFF3A2A33`. Cada prop
/// tem a proporção de [tamanho] e fica centralizado na caixa recebida (sem esticar). Cores fixas no desenho.
///
/// O carro do Team Star ganha as pinturas da Ana pelo [capitulo], acumulando: estrela branca a partir do 7,
/// coração neon a partir do 22, os nomes da equipe a partir do 29 e a rodinha dourada no 30.
/// O carro é visto de lado, de frente para a direita, com o cockpit aberto (o busto do piloto aparece por trás).
class PropPainter extends CustomPainter {
  PropPainter({required this.prop, this.t = 0, this.rosto, this.visema = Visema.x, this.capitulo = 1});

  final PropHistoria prop;

  /// Relógio (s) das animações leves do próprio prop: vapor do café, bandeira ondulando, brilho da roda de ouro,
  /// luzinha do rádio. Não gira as rodas do carro (quem anda é o palco).
  final double t;

  /// O rosto de quem fala pelo celular (só no prop `celular`).
  final Aparencia? rosto;
  final Visema visema;

  /// Capítulo (a pintura do carro do Team Star muda: estrela no 7, coração neon no 22, nomes no 29…).
  final int capitulo;

  /// O tamanho do prop para um ator de [alturaAtor].
  static Size tamanho(PropHistoria p, double alturaAtor) {
    final (w, h) = _proporcao(p);
    return Size(alturaAtor * w, alturaAtor * h);
  }

  /// Largura × altura de cada prop, em alturas de ator.
  static (double, double) _proporcao(PropHistoria p) => switch (p) {
        PropHistoria.nada => (0, 0),
        PropHistoria.carro || PropHistoria.carroRival => (1.1, .45),
        PropHistoria.trofeu => (.26, .32),
        PropHistoria.rodaDeOuro => (.3, .3),
        PropHistoria.mapa => (.32, .22),
        PropHistoria.celular => (.16, .28),
        PropHistoria.bandeira => (.26, .42),
        PropHistoria.capacete => (.26, .22),
        PropHistoria.chave => (.26, .1),
        PropHistoria.mala => (.32, .27),
        PropHistoria.passaporte => (.13, .17),
        PropHistoria.cafe => (.15, .15),
        PropHistoria.medalha => (.14, .24),
        PropHistoria.guardaChuva => (.52, .48),
        PropHistoria.microfone => (.09, .24),
        PropHistoria.foguete => (.35, .9),
        PropHistoria.presente => (.24, .24),
        PropHistoria.livro => (.22, .17),
        PropHistoria.pneu => (.28, .28),
        PropHistoria.cachecol => (.32, .16),
        PropHistoria.garrafa => (.09, .26),
        PropHistoria.carta => (.22, .15),
        PropHistoria.radio => (.14, .26),
        PropHistoria.notebook => (.3, .22),
        PropHistoria.prato => (.26, .12),
        PropHistoria.sacola => (.2, .26),
        PropHistoria.documento => (.17, .22),
      };

  static const _contorno = Color(0xFF3A2A33);
  static const _ouro = Color(0xFFFFC83D);
  static const _ouroEscuro = Color(0xFFE09A1B);
  static const _roxo = Color(0xFF7B4FD6);
  static const _roxoEscuro = Color(0xFF5A35A8);
  static const _pneu = Color(0xFF2B2B2B);

  // Estado do desenho (válido só durante paint): o canvas está em unidades de "altura do prop" (h = 1).
  late Canvas _c;
  late double _lw;

  @override
  void paint(Canvas canvas, Size size) {
    if (prop == PropHistoria.nada || size.isEmpty || !size.isFinite) return;
    final (pw, ph) = _proporcao(prop);
    final aspecto = pw / ph;
    // a maior caixa com a proporção do prop, centralizada
    var h = size.height;
    var w = h * aspecto;
    if (w > size.width) {
      w = size.width;
      h = w / aspecto;
    }
    if (h <= 0) return;
    canvas.save();
    canvas.translate((size.width - w) / 2, (size.height - h) / 2);
    canvas.scale(h);
    _c = canvas;
    _lw = (h * .035).clamp(1.2, 3.0) / h;
    switch (prop) {
      case PropHistoria.nada:
        break;
      case PropHistoria.carro:
        _carro(aspecto, rival: false);
      case PropHistoria.carroRival:
        _carro(aspecto, rival: true);
      case PropHistoria.trofeu:
        _trofeu();
      case PropHistoria.rodaDeOuro:
        _rodaDeOuro();
      case PropHistoria.mapa:
        _mapa(aspecto);
      case PropHistoria.celular:
        _celular(aspecto);
      case PropHistoria.bandeira:
        _bandeira(aspecto);
      case PropHistoria.capacete:
        _capacete(aspecto);
      case PropHistoria.chave:
        _chave(aspecto);
      case PropHistoria.mala:
        _mala(aspecto);
      case PropHistoria.passaporte:
        _passaporte(aspecto);
      case PropHistoria.cafe:
        _cafe();
      case PropHistoria.medalha:
        _medalha(aspecto);
      case PropHistoria.guardaChuva:
        _guardaChuva(aspecto);
      case PropHistoria.microfone:
        _microfone(aspecto);
      case PropHistoria.foguete:
        _foguete(aspecto);
      case PropHistoria.presente:
        _presente();
      case PropHistoria.livro:
        _livro(aspecto);
      case PropHistoria.pneu:
        _pneuProp();
      case PropHistoria.cachecol:
        _cachecol(aspecto);
      case PropHistoria.garrafa:
        _garrafa(aspecto);
      case PropHistoria.carta:
        _carta(aspecto);
      case PropHistoria.radio:
        _radio(aspecto);
      case PropHistoria.notebook:
        _notebook(aspecto);
      case PropHistoria.prato:
        _prato(aspecto);
      case PropHistoria.sacola:
        _sacola(aspecto);
      case PropHistoria.documento:
        _documento(aspecto);
    }
    canvas.restore();
  }

  // ───────────────────────── ferramentas ─────────────────────────

  Paint _tinta(Color c) => Paint()
    ..color = c
    ..isAntiAlias = true;

  Paint get _traco => Paint()
    ..color = _contorno
    ..style = PaintingStyle.stroke
    ..strokeWidth = _lw
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// Preenche e contorna.
  void _forma(Path p, Color cor, {bool contorno = true}) {
    _c.drawPath(p, _tinta(cor));
    if (contorno) _c.drawPath(p, _traco);
  }

  void _linha(Offset a, Offset b, Color cor, double largura) {
    _c.drawLine(
      a,
      b,
      Paint()
        ..color = cor
        ..strokeWidth = largura
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _rr(double l, double t, double r, double b, double raio) =>
      Path()..addRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(raio)));

  Path _circ(double x, double y, double r) => Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

  /// Estrela de [pontas] pontas.
  Path _estrela(Offset c, double rFora, double rDentro, {int pontas = 5, double giro = 0}) {
    final p = Path();
    for (var i = 0; i < pontas * 2; i++) {
      final r = i.isEven ? rFora : rDentro;
      final a = -math.pi / 2 + giro + i * math.pi / pontas;
      final o = c + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  /// Coração centrado em [c], de largura ~2·[r].
  static Path coracao(Offset c, double r) {
    final p = Path()
      ..moveTo(c.dx, c.dy + r * .95)
      ..cubicTo(c.dx - r * 1.5, c.dy + r * .1, c.dx - r * .9, c.dy - r * 1.1, c.dx, c.dy - r * .35)
      ..cubicTo(c.dx + r * .9, c.dy - r * 1.1, c.dx + r * 1.5, c.dy + r * .1, c.dx, c.dy + r * .95)
      ..close();
    return p;
  }

  void _brilhinho(Offset c, double r) {
    _c.drawPath(_estrela(c, r, r * .3, pontas: 4), _tinta(Colors.white.withValues(alpha: .9)));
  }

  // ───────────────────────── carros ─────────────────────────

  void _roda(double x, double y, double r, {Color aro = const Color(0xFFC9CED6)}) {
    _forma(_circ(x, y, r), _pneu);
    _forma(_circ(x, y, r * .55), aro);
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5;
      _linha(Offset(x, y), Offset(x + math.cos(a) * r * .5, y + math.sin(a) * r * .5), _contorno, _lw * .7);
    }
    _forma(_circ(x, y, r * .14), _contorno, contorno: false);
  }

  void _carro(double w, {required bool rival}) {
    final cor = rival ? const Color(0xFF26262E) : _roxo;
    final sombra = rival ? const Color(0xFF15151B) : _roxoEscuro;
    // sombra no chão
    _c.drawOval(Rect.fromLTRB(w * .04, .86, w * .96, 1.0), _tinta(Colors.black.withValues(alpha: .18)));
    // aerofólio traseiro (à esquerda)
    _forma(_rr(w * .03, .2, w * .17, .29, .03), sombra);
    _forma(_rr(w * .08, .27, w * .12, .5, .01), sombra);
    // carroceria: baixa, bico comprido para a direita, cockpit aberto
    final corpo = Path()
      ..moveTo(w * .05, .78)
      ..lineTo(w * .05, .5)
      ..quadraticBezierTo(w * .06, .42, w * .14, .41)
      ..lineTo(w * .36, .39)
      ..quadraticBezierTo(w * .4, .39, w * .42, .44) // borda traseira do cockpit
      ..lineTo(w * .6, .44) // abertura do cockpit
      ..quadraticBezierTo(w * .64, .35, w * .7, .36) // para-brisa baixinho
      ..lineTo(w * .82, .45)
      ..quadraticBezierTo(w * .95, .5, w * .97, .62)
      ..quadraticBezierTo(w * .98, .74, w * .93, .78)
      ..close();
    _c.drawPath(corpo, _tinta(cor));
    // faixa de sombra embaixo
    _c.save();
    _c.clipPath(corpo);
    _c.drawRect(Rect.fromLTRB(0, .66, w, .8), _tinta(sombra));
    _c.restore();
    _c.drawPath(corpo, _traco);
    // para-brisa
    final vidro = Path()
      ..moveTo(w * .6, .44)
      ..quadraticBezierTo(w * .64, .3, w * .69, .3)
      ..lineTo(w * .7, .36)
      ..quadraticBezierTo(w * .64, .35, w * .6, .44)
      ..close();
    _forma(vidro, const Color(0xFFBFE6FF).withValues(alpha: .75));
    if (rival) {
      // raio laranja na lateral
      final raio = Path()
        ..moveTo(w * .18, .5)
        ..lineTo(w * .52, .48)
        ..lineTo(w * .47, .55)
        ..lineTo(w * .8, .54)
        ..lineTo(w * .43, .66)
        ..lineTo(w * .48, .6)
        ..lineTo(w * .16, .61)
        ..close();
      _forma(raio, const Color(0xFFFF8A1F));
    } else {
      // faixa clara de brilho
      _linha(Offset(w * .16, .47), Offset(w * .36, .45), Colors.white.withValues(alpha: .35), .025);
      _pinturas(w);
    }
    // rodas
    _roda(w * .22, .78, .2);
    _roda(w * .8, .78, .2);
  }

  /// As pinturas da Ana no carro do Team Star (acumulam pelo capítulo).
  void _pinturas(double w) {
    if (capitulo >= 7) {
      _forma(_estrela(Offset(w * .5, .56), .11, .045), Colors.white);
    }
    if (capitulo >= 22) {
      final c = Offset(w * .3, .56);
      _c.drawPath(
        coracao(c, .115),
        Paint()
          ..color = const Color(0xFFFF4FD8).withValues(alpha: .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, .03),
      );
      _forma(coracao(c, .1), const Color(0xFFFF4FD8));
      _c.drawPath(
        coracao(c, .055),
        Paint()
          ..color = Colors.white.withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _lw * .7,
      );
    }
    if (capitulo >= 29) {
      // os nomes da equipe: rabiscos coloridos de assinatura no bico
      const cores = [Color(0xFFFFD166), Color(0xFF7CF2D0), Color(0xFFFF9EC7), Color(0xFFFFFFFF)];
      for (var i = 0; i < cores.length; i++) {
        final y = .5 + i * .045;
        final x0 = w * (.63 + (i % 2) * .02);
        final p = Path()..moveTo(x0, y);
        for (var k = 1; k <= 6; k++) {
          p.relativeQuadraticBezierTo(w * .012, (k.isEven ? -.03 : .03), w * .024, 0);
        }
        _c.drawPath(
          p,
          Paint()
            ..color = cores[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = _lw * .8
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    if (capitulo >= 30) {
      // a rodinha dourada
      final c = Offset(w * .88, .55);
      _forma(_circ(c.dx, c.dy, .05), _ouro);
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 4;
        _linha(c - Offset(math.cos(a), math.sin(a)) * .04, c + Offset(math.cos(a), math.sin(a)) * .04, _ouroEscuro,
            _lw * .6);
      }
    }
  }

  // ───────────────────────── objetos ─────────────────────────

  void _trofeu() {
    const w = .26 / .32;
    final m = w / 2;
    // alças
    final alca = _traco
      ..color = _ouroEscuro
      ..strokeWidth = .07;
    _c.drawArc(Rect.fromCenter(center: Offset(m - .28, .28), width: .2, height: .26), math.pi * .5, math.pi, false, alca);
    _c.drawArc(Rect.fromCenter(center: Offset(m + .28, .28), width: .2, height: .26), -math.pi * .5, math.pi, false, alca);
    // taça
    final taca = Path()
      ..moveTo(m - .34, .08)
      ..lineTo(m + .34, .08)
      ..quadraticBezierTo(m + .32, .52, m + .06, .58)
      ..lineTo(m - .06, .58)
      ..quadraticBezierTo(m - .32, .52, m - .34, .08)
      ..close();
    _forma(taca, _ouro);
    _c.save();
    _c.clipPath(taca);
    _c.drawRect(Rect.fromLTRB(m + .12, 0, m + .4, .6), _tinta(_ouroEscuro));
    _c.restore();
    _c.drawPath(taca, _traco);
    // haste e base
    _forma(_rr(m - .05, .57, m + .05, .74, .01), _ouroEscuro);
    _forma(_rr(m - .22, .74, m + .22, .82, .02), _ouro);
    _forma(_rr(m - .28, .82, m + .28, .98, .03), const Color(0xFF6B4226));
    _forma(_estrela(Offset(m, .3), .1, .045), Colors.white);
    _brilhinho(Offset(m - .2, .18), .06 + .02 * math.sin(t * 3));
  }

  void _rodaDeOuro() {
    const c = Offset(.5, .5);
    _forma(_circ(c.dx, c.dy, .47), _ouroEscuro);
    _forma(_circ(c.dx, c.dy, .38), _ouro);
    _forma(_circ(c.dx, c.dy, .3), const Color(0xFFFFE08A));
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      _linha(c, c + Offset(math.cos(a), math.sin(a)) * .3, _ouroEscuro, .05);
    }
    _forma(_circ(c.dx, c.dy, .1), _ouro);
    // brilho que gira devagar
    final a = t * 1.4;
    _brilhinho(c + Offset(math.cos(a), math.sin(a)) * .42, .09 + .03 * math.sin(t * 5).abs());
    _brilhinho(const Offset(.3, .26), .06);
  }

  void _mapa(double w) {
    const papel = Color(0xFFF3E3B5);
    const dobra = Color(0xFFE2CC8F);
    final r = _rr(.02, .04, w - .02, .96, .04);
    _forma(r, papel);
    _c.save();
    _c.clipPath(r);
    _c.drawRect(Rect.fromLTRB(w / 3, 0, w * 2 / 3, 1), _tinta(dobra));
    _c.restore();
    _c.drawPath(r, _traco);
    // rota tracejada e o X
    final rota = Paint()
      ..color = const Color(0xFFE84A5F)
      ..strokeWidth = .05
      ..strokeCap = StrokeCap.round;
    final pts = [Offset(w * .12, .78), Offset(w * .3, .55), Offset(w * .5, .66), Offset(w * .68, .38)];
    for (var i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      for (var k = 0; k < 3; k++) {
        _c.drawLine(Offset.lerp(a, b, k / 3)!, Offset.lerp(a, b, k / 3 + .18)!, rota);
      }
    }
    final x = Offset(w * .8, .28);
    _c.drawLine(x - const Offset(.08, .08), x + const Offset(.08, .08), rota..strokeWidth = .07);
    _c.drawLine(x + const Offset(-.08, .08), x + const Offset(.08, -.08), rota);
  }

  void _celular(double w) {
    _forma(_rr(.04, .02, w - .04, .98, .1), const Color(0xFF2B2B35));
    final tela = Rect.fromLTRB(.1, .1, w - .1, .86);
    final rostoA = rosto;
    if (rostoA == null) {
      _c.drawRRect(RRect.fromRectAndRadius(tela, const Radius.circular(.04)), _tinta(const Color(0xFF9FD8FF)));
      // ícones da tela inicial
      for (var i = 0; i < 6; i++) {
        final x = tela.left + tela.width * (.25 + (i % 2) * .5);
        final y = tela.top + tela.height * (.18 + (i ~/ 2) * .25);
        _c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: .14, height: .14), const Radius.circular(.03)),
          _tinta(const [Color(0xFFFFD166), Color(0xFF7CF2D0), Color(0xFFFF9EC7)][i % 3]),
        );
      }
    } else {
      // videochamada: o rostinho de quem fala, com lip-sync
      _c.drawRRect(RRect.fromRectAndRadius(tela, const Radius.circular(.04)), _tinta(const Color(0xFFDFF3FF)));
      _c.save();
      _c.clipRRect(RRect.fromRectAndRadius(tela, const Radius.circular(.04)));
      // o rosto preenche a largura da tela, centralizado (o ombro sai pela borda de baixo)
      final lado = tela.width * 1.45;
      _c.translate(tela.center.dx - lado / 2, tela.center.dy - lado * .5);
      PersonagemPainter(rostoA, visema: visema).paint(_c, Size.square(lado));
      _c.restore();
      // bolinha verde de "ao vivo"
      _forma(_circ(tela.right - .05, tela.top + .05, .025), const Color(0xFF3DDC84), contorno: false);
    }
    _c.drawRRect(RRect.fromRectAndRadius(tela, const Radius.circular(.04)), _traco..strokeWidth = _lw * .6);
    _forma(_circ(w / 2, .92, .025), const Color(0xFF55556A), contorno: false);
  }

  void _bandeira(double w) {
    // mastro
    _forma(_rr(.02, .02, .07, .99, .02), const Color(0xFFB8BEC8));
    // pano quadriculado ondulando
    const cols = 4, lins = 3;
    final l = .07, r = w - .02, topo = .05, base = .52;
    double onda(double x) => math.sin(t * 5 + x * 9) * .03 * ((x - l) / (r - l));
    final cw = (r - l) / cols, ch = (base - topo) / lins;
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < lins; j++) {
        final x0 = l + i * cw, x1 = x0 + cw;
        final y0 = topo + j * ch, y1 = y0 + ch;
        final p = Path()
          ..moveTo(x0, y0 + onda(x0))
          ..lineTo(x1, y0 + onda(x1))
          ..lineTo(x1, y1 + onda(x1))
          ..lineTo(x0, y1 + onda(x0))
          ..close();
        _c.drawPath(p, _tinta((i + j).isEven ? Colors.white : const Color(0xFF1E1E28)));
      }
    }
    final borda = Path()
      ..moveTo(l, topo + onda(l))
      ..lineTo(r, topo + onda(r))
      ..lineTo(r, base + onda(r))
      ..lineTo(l, base + onda(l))
      ..close();
    _c.drawPath(borda, _traco);
  }

  void _capacete(double w) {
    final casco = Path()
      ..moveTo(w * .06, .86)
      ..quadraticBezierTo(w * .02, .12, w * .55, .08)
      ..quadraticBezierTo(w * .98, .1, w * .96, .62)
      ..lineTo(w * .96, .86)
      ..close();
    _forma(casco, _roxo);
    _c.save();
    _c.clipPath(casco);
    _c.drawRect(Rect.fromLTRB(0, .7, w, 1), _tinta(_roxoEscuro));
    _linha(Offset(w * .2, .2), Offset(w * .2, .9), Colors.white, .07);
    _c.restore();
    _c.drawPath(casco, _traco);
    // viseira
    _forma(_rr(w * .42, .36, w * .99, .62, .1), const Color(0xFF26407A));
    _linha(Offset(w * .5, .43), Offset(w * .7, .43), Colors.white.withValues(alpha: .6), .035);
  }

  void _chave(double w) {
    const metal = Color(0xFFB8BEC8);
    // cabo
    _forma(_rr(w * .2, .38, w * .78, .62, .1), metal);
    // anel (esquerda)
    _forma(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addOval(Rect.fromCircle(center: Offset(w * .14, .5), radius: .4))
        ..addOval(Rect.fromCircle(center: Offset(w * .14, .5), radius: .17)),
      metal,
    );
    // boca aberta (direita)
    final boca = Path()
      ..moveTo(w * .74, .22)
      ..lineTo(w * .86, .02)
      ..lineTo(w * .99, .12)
      ..lineTo(w * .9, .38)
      ..lineTo(w * .9, .62)
      ..lineTo(w * .99, .88)
      ..lineTo(w * .86, .98)
      ..lineTo(w * .74, .78)
      ..close();
    _forma(boca, metal);
    _linha(Offset(w * .3, .45), Offset(w * .62, .45), Colors.white.withValues(alpha: .55), .06);
  }

  void _mala(double w) {
    // alça
    _c.drawRRect(
      RRect.fromLTRBR(w * .36, .02, w * .64, .24, const Radius.circular(.06)),
      _traco..strokeWidth = .07,
    );
    final corpo = _rr(w * .02, .18, w * .98, .97, .08);
    _forma(corpo, const Color(0xFF2E86AB));
    _c.save();
    _c.clipPath(corpo);
    _c.drawRect(Rect.fromLTRB(0, .8, w, 1), _tinta(const Color(0xFF226985)));
    _c.restore();
    _c.drawPath(corpo, _traco);
    for (final x in [.28, .72]) {
      _forma(_rr(w * x - .04, .18, w * x + .04, .97, .01), const Color(0xFF6B4226));
    }
    // adesivos de viagem
    _forma(_circ(w * .5, .5, .1), const Color(0xFFFFD166));
    _forma(_estrela(Offset(w * .5, .5), .06, .025), Colors.white, contorno: false);
    _forma(_rr(w * .1, .62, w * .22, .74, .02), const Color(0xFFFF9EC7));
  }

  void _passaporte(double w) {
    _forma(_rr(.04, .02, w - .02, .98, .06), const Color(0xFF1F3B73));
    _linha(const Offset(.1, .06), const Offset(.1, .94), const Color(0xFF16294F), .03);
    final c = Offset(w * .55, .42);
    _c.drawCircle(
      c,
      .18,
      Paint()
        ..color = _ouro
        ..style = PaintingStyle.stroke
        ..strokeWidth = .04,
    );
    _c.drawPath(_estrela(c, .1, .04), _tinta(_ouro));
    _linha(Offset(w * .3, .76), Offset(w * .8, .76), _ouro, .04);
  }

  void _cafe() {
    const w = 1.0;
    // vapor ondulando
    final vapor = Paint()
      ..color = Colors.white.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .05
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final x = w * (.38 + i * .2);
      final fase = t * 3 + i * 1.7;
      final p = Path()..moveTo(x, .34);
      for (var k = 1; k <= 3; k++) {
        p.lineTo(x + math.sin(fase + k * 1.4) * .05, .34 - k * .1);
      }
      _c.drawPath(p, vapor);
    }
    // pires, xícara e alça
    _forma(_rr(.04, .86, .96, .96, .05), Colors.white);
    _c.drawArc(Rect.fromLTRB(.64, .44, .96, .74), -math.pi / 2, math.pi, false, _traco..strokeWidth = .07);
    final xicara = Path()
      ..moveTo(.14, .4)
      ..lineTo(.78, .4)
      ..quadraticBezierTo(.76, .86, .46, .86)
      ..quadraticBezierTo(.16, .86, .14, .4)
      ..close();
    _forma(xicara, Colors.white);
    _forma(Path()..addOval(Rect.fromLTRB(.16, .37, .76, .47)), const Color(0xFF7A4A2A));
  }

  void _medalha(double w) {
    // fita em V
    final fitaE = Path()
      ..moveTo(w * .1, 0)
      ..lineTo(w * .42, 0)
      ..lineTo(w * .62, .5)
      ..lineTo(w * .4, .52)
      ..close();
    final fitaD = Path()
      ..moveTo(w * .9, 0)
      ..lineTo(w * .58, 0)
      ..lineTo(w * .38, .5)
      ..lineTo(w * .6, .52)
      ..close();
    _forma(fitaE, const Color(0xFFE84A5F));
    _forma(fitaD, const Color(0xFF2E86AB));
    final c = Offset(w / 2, .7);
    _forma(_circ(c.dx, c.dy, .27), _ouro);
    _c.drawCircle(
      c,
      .2,
      Paint()
        ..color = _ouroEscuro
        ..style = PaintingStyle.stroke
        ..strokeWidth = .03,
    );
    _forma(_estrela(c, .13, .055), _ouroEscuro, contorno: false);
    _brilhinho(c + const Offset(-.12, -.12), .05);
  }

  void _guardaChuva(double w) {
    // cabo em J
    _linha(Offset(w / 2, .3), Offset(w / 2, .86), _contorno, .04);
    _c.drawArc(Rect.fromLTRB(w / 2 - .12, .78, w / 2, .98), 0, math.pi, false, _traco..strokeWidth = .04);
    // copa em gomos
    const gomos = 5;
    final l = w * .02, r = w * .98, base = .42;
    final copa = Path()
      ..moveTo(l, base)
      ..quadraticBezierTo(l, .04, w / 2, .04)
      ..quadraticBezierTo(r, .04, r, base);
    final gw = (r - l) / gomos;
    for (var i = gomos - 1; i >= 0; i--) {
      copa.quadraticBezierTo(l + gw * (i + .5), base - .07, l + gw * i, base);
    }
    copa.close();
    _c.drawPath(copa, _tinta(const Color(0xFFE84A5F)));
    _c.save();
    _c.clipPath(copa);
    for (var i = 1; i < gomos; i += 2) {
      _c.drawRect(Rect.fromLTRB(l + gw * i, 0, l + gw * (i + 1), 1), _tinta(Colors.white));
    }
    _c.restore();
    _c.drawPath(copa, _traco);
    _forma(_circ(w / 2, .04, .03), _contorno, contorno: false);
  }

  void _microfone(double w) {
    final m = w / 2, hw = m - .012;
    _forma(_rr(m - hw * .72, .32, m + hw * .72, .98, .06), const Color(0xFF26262E));
    _forma(_rr(m - hw, .3, m + hw, .38, .02), const Color(0xFF55556A));
    _forma(_circ(m, .17, hw * .98), const Color(0xFFB8BEC8));
    final grade = _traco..strokeWidth = _lw * .5;
    for (final dy in [-.08, 0.0, .08]) {
      _c.drawLine(Offset(m - hw * .75, .17 + dy), Offset(m + hw * .75, .17 + dy), grade);
    }
  }

  void _foguete(double w) {
    final m = w / 2;
    // aletas
    final aletaE = Path()
      ..moveTo(m - .12, .62)
      ..lineTo(m - .17, .9)
      ..lineTo(m - .1, .86)
      ..close();
    final aletaD = Path()
      ..moveTo(m + .12, .62)
      ..lineTo(m + .17, .9)
      ..lineTo(m + .1, .86)
      ..close();
    _forma(aletaE, const Color(0xFFE84A5F));
    _forma(aletaD, const Color(0xFFE84A5F));
    // corpo com nariz
    final corpo = Path()
      ..moveTo(m, .02)
      ..quadraticBezierTo(m + .14, .14, m + .12, .3)
      ..lineTo(m + .12, .86)
      ..lineTo(m - .12, .86)
      ..lineTo(m - .12, .3)
      ..quadraticBezierTo(m - .14, .14, m, .02)
      ..close();
    _forma(corpo, Colors.white);
    _c.save();
    _c.clipPath(corpo);
    _c.drawRect(Rect.fromLTRB(m - .2, 0, m + .2, .2), _tinta(const Color(0xFFE84A5F)));
    _c.drawRect(Rect.fromLTRB(m + .05, 0, m + .2, 1), _tinta(Colors.black.withValues(alpha: .08)));
    _c.restore();
    _c.drawPath(corpo, _traco);
    _forma(_circ(m, .42, .06), const Color(0xFF9FD8FF));
    _forma(_rr(m - .08, .86, m + .08, .93, .01), const Color(0xFF55556A));
  }

  void _presente() {
    final caixa = _rr(.08, .36, .92, .97, .04);
    _forma(caixa, const Color(0xFFFF9EC7));
    _forma(_rr(.04, .26, .96, .4, .04), const Color(0xFFFF7EB0));
    _forma(_rr(.43, .26, .57, .97, .01), const Color(0xFFFFD166));
    // laço
    final lacoE = Path()
      ..moveTo(.5, .26)
      ..quadraticBezierTo(.2, .0, .26, .2)
      ..quadraticBezierTo(.3, .3, .5, .26)
      ..close();
    final lacoD = Path()
      ..moveTo(.5, .26)
      ..quadraticBezierTo(.8, .0, .74, .2)
      ..quadraticBezierTo(.7, .3, .5, .26)
      ..close();
    _forma(lacoE, const Color(0xFFFFD166));
    _forma(lacoD, const Color(0xFFFFD166));
  }

  void _livro(double w) {
    _forma(_rr(w * .1, .1, w * .96, .94, .03), Colors.white);
    final capa = _rr(w * .04, .04, w * .9, .9, .04);
    _forma(capa, const Color(0xFF3FA34D));
    _linha(Offset(w * .14, .06), Offset(w * .14, .88), const Color(0xFF2E7A39), .04);
    _forma(_rr(w * .3, .3, w * .78, .46, .02), const Color(0xFFF3E3B5));
  }

  void _pneuProp() {
    _forma(_circ(.5, .5, .48), _pneu);
    // sulcos
    final sulco = Paint()
      ..color = const Color(0xFF4A4A4A)
      ..strokeWidth = .05
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final d = Offset(math.cos(a), math.sin(a));
      _c.drawLine(const Offset(.5, .5) + d * .38, const Offset(.5, .5) + d * .45, sulco);
    }
    _forma(_circ(.5, .5, .26), const Color(0xFFC9CED6));
    _forma(_circ(.5, .5, .09), const Color(0xFF8A8F98));
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * math.pi / 5 - math.pi / 2;
      _forma(_circ(.5 + math.cos(a) * .17, .5 + math.sin(a) * .17, .025), const Color(0xFF55556A), contorno: false);
    }
  }

  void _cachecol(double w) {
    final faixa = _rr(w * .02, .08, w * .98, .5, .12);
    _c.drawPath(faixa, _tinta(const Color(0xFFE84A5F)));
    _c.save();
    _c.clipPath(faixa);
    for (var i = 0; i < 8; i += 2) {
      _c.drawRect(Rect.fromLTRB(w * i / 8, 0, w * (i + 1) / 8, 1), _tinta(Colors.white));
    }
    _c.restore();
    _c.drawPath(faixa, _traco);
    // pontas penduradas
    final ponta = _rr(w * .62, .4, w * .78, .96, .04);
    _forma(ponta, const Color(0xFFE84A5F));
    for (var k = 0; k < 4; k++) {
      final x = w * (.64 + k * .04);
      _linha(Offset(x, .96), Offset(x, 1), _contorno, _lw * .6);
    }
    _linha(Offset(w * .62, .62), Offset(w * .78, .62), Colors.white, .06);
  }

  void _garrafa(double w) {
    final m = w / 2, hw = m - .015;
    _forma(_rr(m - hw * .62, .02, m + hw * .62, .14, .03), const Color(0xFF2E86AB));
    final corpo = Path()
      ..moveTo(m - hw * .5, .14)
      ..lineTo(m + hw * .5, .14)
      ..quadraticBezierTo(m + hw, .22, m + hw, .36)
      ..lineTo(m + hw, .92)
      ..quadraticBezierTo(m + hw, .98, m + hw * .8, .98)
      ..lineTo(m - hw * .8, .98)
      ..quadraticBezierTo(m - hw, .98, m - hw, .92)
      ..lineTo(m - hw, .36)
      ..quadraticBezierTo(m - hw, .22, m - hw * .5, .14)
      ..close();
    _forma(corpo, const Color(0xFFBFE6FF));
    _c.save();
    _c.clipPath(corpo);
    _c.drawRect(Rect.fromLTRB(0, .52, w, 1), _tinta(const Color(0xFF7CC8F5)));
    _c.restore();
    _c.drawPath(corpo, _traco);
    _linha(Offset(m - hw * .55, .3), Offset(m - hw * .55, .85), Colors.white.withValues(alpha: .7), .04);
  }

  void _carta(double w) {
    final env = _rr(w * .02, .04, w * .98, .96, .04);
    _forma(env, Colors.white);
    final aba = Path()
      ..moveTo(w * .03, .06)
      ..lineTo(w * .5, .56)
      ..lineTo(w * .97, .06);
    _c.drawPath(aba, _traco);
    _c.drawLine(Offset(w * .03, .94), Offset(w * .4, .5), _traco..strokeWidth = _lw * .6);
    _c.drawLine(Offset(w * .97, .94), Offset(w * .6, .5), _traco..strokeWidth = _lw * .6);
    _forma(coracao(Offset(w * .5, .56), .12), const Color(0xFFE84A5F));
  }

  // ── props das lições (📺) ──

  /// Notebook aberto (de frente): tela azul com linhas de código coloridas, câmera, teclado e touchpad.
  void _notebook(double w) {
    final tampa = _rr(w * .12, .02, w * .88, .7, .05);
    _forma(tampa, const Color(0xFF3A3F4B));
    final tela = _rr(w * .17, .08, w * .83, .64, .02);
    _forma(tela, const Color(0xFF2F6FD0), contorno: false);
    const cores = [Color(0xFF8BE9FD), Color(0xFFFFD166), Color(0xFFFF9EC7), Color(0xFFA5E887)];
    for (var i = 0; i < 4; i++) {
      final recuo = (i % 3) * w * .05;
      final y = .17 + i * .12;
      _linha(Offset(w * .23 + recuo, y), Offset(w * (.5 + .07 * ((i * 5) % 4)), y), cores[i], .05);
    }
    // reflexo na tela
    _c.save();
    _c.clipPath(tela);
    _c.drawPath(
      Path()
        ..moveTo(w * .55, .08)
        ..lineTo(w * .7, .08)
        ..lineTo(w * .48, .64)
        ..lineTo(w * .33, .64)
        ..close(),
      _tinta(Colors.white.withValues(alpha: .14)),
    );
    _c.restore();
    _c.drawCircle(Offset(w * .5, .05), .012, _tinta(const Color(0xFF8D99A8)));
    // base com o teclado
    final base = Path()
      ..moveTo(w * .12, .7)
      ..lineTo(w * .88, .7)
      ..lineTo(w * .98, .9)
      ..lineTo(w * .02, .9)
      ..close();
    _forma(base, const Color(0xFFC9D0D8));
    for (var r = 0; r < 2; r++) {
      final y = .75 + r * .055;
      final l = w * (.18 - r * .03), d = w * (.82 + r * .03);
      for (var k = 0; k < 9; k++) {
        final x = l + (d - l) * k / 9;
        _c.drawRRect(RRect.fromLTRBR(x + w * .006, y, x + (d - l) / 9 - w * .006, y + .035, const Radius.circular(.008)),
            _tinta(const Color(0xFF8D99A8)));
      }
    }
    _forma(_rr(w * .42, .85, w * .58, .89, .01), const Color(0xFFB2BBC6), contorno: false);
    _forma(_rr(w * .02, .89, w * .98, .98, .03), const Color(0xFFAAB3BE));
  }

  /// Prato fundo com macarrão ao molho, manjericão e o vapor subindo.
  void _prato(double w) {
    final vapor = Paint()
      ..color = Colors.white.withValues(alpha: .7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .045
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 2; i++) {
      final x = w * (.42 + i * .14);
      final fase = t * 3 + i * 1.9;
      final p = Path()..moveTo(x, .24);
      for (var k = 1; k <= 3; k++) {
        p.lineTo(x + math.sin(fase + k * 1.4) * .04, .24 - k * .075);
      }
      _c.drawPath(p, vapor);
    }
    _forma(Path()..addOval(Rect.fromLTRB(w * .02, .44, w * .98, .98)), Colors.white);
    _c.drawOval(Rect.fromLTRB(w * .16, .52, w * .84, .9), _tinta(const Color(0xFFEFF2F5)));
    // o macarrão: um montinho com os fios desenhados
    final monte = Path()
      ..moveTo(w * .24, .74)
      ..quadraticBezierTo(w * .24, .3, w * .5, .3)
      ..quadraticBezierTo(w * .76, .3, w * .76, .74)
      ..quadraticBezierTo(w * .5, .82, w * .24, .74)
      ..close();
    _forma(monte, const Color(0xFFF2C14E));
    _c.save();
    _c.clipPath(monte);
    final fio = Paint()
      ..color = const Color(0xFFD9A23A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .03
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      _c.drawArc(Rect.fromCenter(center: Offset(w * (.3 + i * .08), .56 + (i % 2) * .08), width: w * .14, height: .22), .3,
          math.pi * 1.3, false, fio);
    }
    _c.restore();
    _c.drawPath(monte, _traco);
    // molho e manjericão por cima
    _forma(Path()..addOval(Rect.fromLTRB(w * .38, .32, w * .62, .52)), const Color(0xFFD94F3B));
    _forma(Path()..addOval(Rect.fromLTRB(w * .52, .3, w * .64, .4)), const Color(0xFF4FA84A));
    _forma(Path()..addOval(Rect.fromLTRB(w * .58, .36, w * .7, .46)), const Color(0xFF5FBA58));
  }

  /// Sacola de papel pardo com alça de corda, um pão e folhas saindo por cima e uma etiqueta de coração.
  void _sacola(double w) {
    // o que está dentro (aparece por cima)
    _c.save();
    _c.translate(w * .34, .3);
    _c.rotate(-.35);
    _forma(_rr(-w * .1, -.28, w * .1, .06, .08), const Color(0xFFE2A85A));
    for (var i = 0; i < 3; i++) {
      _linha(Offset(-w * .06, -.2 + i * .08), Offset(w * .06, -.24 + i * .08), const Color(0xFFB87A34), .025);
    }
    _c.restore();
    _forma(Path()..addOval(Rect.fromLTRB(w * .5, .12, w * .78, .36)), const Color(0xFF58B562));
    _forma(Path()..addOval(Rect.fromLTRB(w * .62, .18, w * .86, .38)), const Color(0xFF3E9A4A));
    final alca = Paint()
      ..color = const Color(0xFF6B4226)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .045
      ..strokeCap = StrokeCap.round;
    _c.drawArc(Rect.fromLTRB(w * .3, .06, w * .74, .5), math.pi * 1.08, math.pi * .84, false, alca);
    // o corpo, com a dobra de cima e a lateral na sombra
    final corpo = Path()
      ..moveTo(w * .1, .3)
      ..lineTo(w * .9, .3)
      ..lineTo(w * .96, .98)
      ..lineTo(w * .04, .98)
      ..close();
    _forma(corpo, const Color(0xFFC89B6C));
    _c.save();
    _c.clipPath(corpo);
    _c.drawRect(Rect.fromLTRB(w * .76, .3, w, 1), _tinta(const Color(0x22301A10)));
    _c.drawRect(Rect.fromLTRB(0, .3, w, .4), _tinta(const Color(0xFFB4844F)));
    _c.restore();
    _c.drawPath(corpo, _traco);
    _linha(Offset(w * .09, .4), Offset(w * .91, .4), _contorno, _lw * .7);
    // etiqueta redonda com coração (sem marca)
    _forma(_circ(w * .46, .66, .13), const Color(0xFFFFF4E0));
    _forma(PropPainter.coracao(Offset(w * .46, .65), .07), const Color(0xFFE84A5F), contorno: false);
    _c.drawArc(Rect.fromLTRB(w * .26, .1, w * .7, .52), math.pi * 1.1, math.pi * .8, false, alca..strokeWidth = .055);
    _c.drawCircle(Offset(w * .29, .33), .025, _tinta(const Color(0xFF6B4226)));
    _c.drawCircle(Offset(w * .67, .33), .025, _tinta(const Color(0xFF6B4226)));
  }

  /// Prancheta com a folha (título, linhas, dois itens marcados e a assinatura).
  void _documento(double w) {
    _forma(_rr(w * .04, .06, w * .96, .98, .05), const Color(0xFFB07C50));
    _forma(_rr(w * .13, .14, w * .87, .93, .015), Colors.white);
    _linha(Offset(w * .24, .25), Offset(w * .66, .25), const Color(0xFF3E8AE0), .05);
    for (var i = 0; i < 3; i++) {
      final y = .38 + i * .11;
      _forma(_rr(w * .22, y - .035, w * .3, y + .035, .01), Colors.white);
      if (i < 2) {
        _c.drawPath(
          Path()
            ..moveTo(w * .225, y)
            ..lineTo(w * .26, y + .03)
            ..lineTo(w * .32, y - .05),
          Paint()
            ..color = const Color(0xFF2EAD5B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .03
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      _linha(Offset(w * .38, y), Offset(w * (.62 + .1 * ((i + 1) % 2)), y), const Color(0xFF8D99A8), .03);
    }
    // assinatura
    final ass = Path()..moveTo(w * .3, .8);
    for (var i = 1; i <= 5; i++) {
      ass.quadraticBezierTo(w * (.3 + i * .08 - .04), i.isOdd ? .7 : .86, w * (.3 + i * .08), .79);
    }
    _c.drawPath(
      ass,
      Paint()
        ..color = const Color(0xFF1F3B73)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .025
        ..strokeCap = StrokeCap.round,
    );
    // o prendedor de metal
    _forma(_rr(w * .3, .01, w * .7, .17, .04), const Color(0xFFB8C0CA));
    _forma(_circ(w * .5, .07, .03), const Color(0xFF8D99A8));
  }

  void _radio(double w) {
    final m = w / 2, hw = m - .015;
    // antena
    _forma(_rr(m + hw * .4, .0, m + hw * .68, .3, .03), const Color(0xFF26262E));
    final corpo = _rr(m - hw, .22, m + hw, .98, .07);
    _forma(corpo, const Color(0xFF3A3F4B));
    _c.save();
    _c.clipPath(corpo);
    _c.drawRect(Rect.fromLTRB(m + hw * .5, 0, w, 1), _tinta(const Color(0xFF2C303A)));
    _c.restore();
    _c.drawPath(corpo, _traco);
    // grade do alto-falante
    final grade = Paint()
      ..color = const Color(0xFF1E1E28)
      ..strokeWidth = .035
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final y = .5 + i * .08;
      _c.drawLine(Offset(m - hw * .62, y), Offset(m + hw * .62, y), grade);
    }
    // visor e luzinha que pisca
    _forma(_rr(m - hw * .68, .29, m + hw * .68, .41, .02), const Color(0xFF7CF2D0));
    final aceso = (t * 2).floor().isEven;
    _forma(_circ(m - hw * .55, .9, .035), aceso ? const Color(0xFFFF5A5A) : const Color(0xFF6B2A2A), contorno: false);
    _forma(_rr(m - hw * .2, .86, m + hw * .7, .93, .02), const Color(0xFFFFD166));
  }

  @override
  bool shouldRepaint(PropPainter old) =>
      old.prop != prop || old.t != t || old.rosto != rosto || old.visema != visema || old.capitulo != capitulo;
}
