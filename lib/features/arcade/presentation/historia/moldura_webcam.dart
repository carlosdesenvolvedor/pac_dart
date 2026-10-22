import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/historia_turismo.dart';

/// 📺 A moldura de webcam atrás de cada ator presente no cenário `videochamada` (D8): cada participante "na
/// câmera", com a parede de uma casa ou escritório diferente pelo [indice]; apagada (com as iniciais) enquanto
/// a pessoa ainda não entrou na chamada, acesa depois do `entra`.
///
/// Opção (b) do spike (plano §8.1): o ator fica **de pé**, recortado na cintura pelo retângulo de [molduraDe]
/// (o palco faz o `ClipRRect` por ator, com o raio de [raioDe]). O corpo da cintura para cima continua, então
/// os gestos, o prop na mão e o lip-sync valem como no resto da história.
///
/// As 4 "paredes" (pelo `indice % 4`): 0 estante de livros, 1 planta grande, 2 quadro e prateleira, 3 janela
/// (com o céu da [hora]). A luz segue a [hora]: à tarde puxa para o laranja, à noite escurece e acende o
/// abajur do canto. Apagada: tela escura com um avatar redondo no centro (com as [iniciais], se vierem) e o
/// ícone de câmera desligada. [falando] acende a borda verde de "quem está falando", como nos apps de chamada.
///
/// Visual de desenho animado (contorno `0xFF3A2A33`, cores chapadas) e determinístico (sem `Random`).
class MolduraWebcamPainter extends CustomPainter {
  MolduraWebcamPainter({
    required this.indice,
    required this.acesa,
    required this.hora,
    this.iniciais,
    this.falando = false,
  });

  /// Qual "parede" de fundo (pelo id do ator); qualquer inteiro (usa `indice % 4`).
  final int indice;

  /// Acesa (a pessoa está na chamada) ou apagada.
  final bool acesa;
  final HoraHistoria hora;

  /// As iniciais no avatar da moldura apagada (até 2 letras; null = só o disco colorido).
  final String? iniciais;

  /// Borda verde de quem está falando agora.
  final bool falando;

  /// Quantas paredes diferentes existem.
  static const paredes = 4;

  /// Margem acima da cabeça, em alturas de ator (a mão do `acena`/`aponta` não é cortada).
  static const margemDeCima = .15;

  /// Onde a moldura corta o ator, em alturas de ator a partir do topo da caixa: logo abaixo do quadril
  /// (quadril em .74, mão parada em .705), então o prop na mão aparece.
  static const corteNaCintura = .8;

  /// Largura da moldura em larguras do corpo (sem vizinho perto).
  static const folgaLateral = 1.3;

  static const _contorno = Color(0xFF3A2A33);
  static const _corApagada = Color(0xFF262B38);
  static const _verdeFalando = Color(0xFF4CD964);

  /// A moldura de um ator cujo corpo (a caixa `.62H × H` do [AtorHistoria]) ocupa [corpoDoAtor] (coordenadas do
  /// palco): da margem acima da cabeça ([margemDeCima]) até a cintura ([corteNaCintura]), centrada no corpo e
  /// [folgaLateral] vezes mais larga que ele. [larguraMaxima] (ex.: `.92 ×` a menor distância entre as
  /// posições ocupadas) estreita a moldura para não invadir a vizinha, mas nunca abaixo da largura do corpo
  /// (que já cabe entre os vizinhos, `PalcoHistoria.alturaDosAtores`).
  static Rect molduraDe(Rect corpoDoAtor, {double? larguraMaxima}) {
    final w = corpoDoAtor.width, h = corpoDoAtor.height;
    var largura = w * folgaLateral;
    if (larguraMaxima != null && larguraMaxima.isFinite) largura = math.min(largura, larguraMaxima);
    largura = math.max(largura, w);
    final cx = corpoDoAtor.center.dx;
    return Rect.fromLTRB(
      cx - largura / 2,
      corpoDoAtor.top - h * margemDeCima,
      cx + largura / 2,
      corpoDoAtor.top + h * corteNaCintura,
    );
  }

  /// O raio dos cantos da moldura de tamanho [s] (o mesmo do recorte do ator).
  static double raioDe(Size s) => s.shortestSide * .07;

  /// A luz da hora (cor para onde a parede é puxada, e quanto).
  static (Color, double) _luzDa(HoraHistoria h) => switch (h) {
        HoraHistoria.amanhecer => (const Color(0xFFFF9E80), .08),
        HoraHistoria.dia => (const Color(0xFFFFFFFF), 0),
        HoraHistoria.tarde => (const Color(0xFFFF7043), .12),
        HoraHistoria.noite => (const Color(0xFF2A2344), .34),
      };

  // estado do desenho (válido só durante paint)
  late Canvas _c;
  late Size _s;
  late double _k;

  Color _luz(Color base) {
    final (cor, f) = _luzDa(hora);
    return f == 0 ? base : Color.lerp(base, cor, f)!;
  }

  Paint _tinta(Color cor, {bool emite = false}) => Paint()..color = emite ? cor : _luz(cor);

  Paint _traco([double largura = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(.8, _k * .012 * largura)
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = _contorno;

  void _forma(Path p, Color cor, {double contorno = 1, bool emite = false}) {
    _c.drawPath(p, _tinta(cor, emite: emite));
    if (contorno > 0) _c.drawPath(p, _traco(contorno));
  }

  void _ret(Rect r, Color cor, {double contorno = 1, double raio = 0, bool emite = false}) =>
      _forma(Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(raio))), cor, contorno: contorno, emite: emite);

  /// Frações da moldura → px.
  Offset _o(double x, double y) => Offset(x * _s.width, y * _s.height);
  Rect _r(double l, double t, double r, double b) => Rect.fromLTRB(l * _s.width, t * _s.height, r * _s.width, b * _s.height);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || !size.isFinite) return;
    _c = canvas;
    _s = size;
    _k = size.shortestSide;
    final caixa = RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(raioDe(size)));
    canvas.save();
    canvas.clipRRect(caixa);
    if (acesa) {
      switch (indice % paredes) {
        case 0:
          _paredeEstante();
        case 1:
          _paredePlanta();
        case 2:
          _paredeQuadro();
        default:
          _paredeJanela();
      }
      // o abajur fica do lado sem móvel (a estante é à esquerda; a planta e a janela, à direita)
      if (hora == HoraHistoria.noite || hora == HoraHistoria.tarde) _abajur(direita: indice % paredes == 0);
      // vinheta da câmera (cantos um pouco mais escuros) e o reflexo no alto
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = RadialGradient(
            radius: .9,
            colors: const [Color(0x00000000), Color(0x2A000000)],
            stops: const [.6, 1],
          ).createShader(Offset.zero & size),
      );
    } else {
      _apagada();
    }
    canvas.restore();
    // a borda: escura; verde e mais grossa em quem fala
    if (falando && acesa) {
      canvas.drawRRect(
        caixa.deflate(_k * .012),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, _k * .035)
          ..color = _verdeFalando,
      );
    }
    canvas.drawRRect(caixa, _traco(1.6));
  }

  // ───────────────────────── as 4 paredes ─────────────────────────

  /// 0: parede creme com estante de livros à esquerda e um vaso à direita.
  void _paredeEstante() {
    _c.drawRect(Offset.zero & _s, _tinta(const Color(0xFFF1E3CC)));
    _rodape(const Color(0xFFE2CFB0));
    final est = _r(-.04, .2, .2, 1.02);
    _ret(est, const Color(0xFFA6784F), raio: _k * .01);
    final dentro = est.deflate(_k * .025);
    _c.drawRect(dentro, _tinta(const Color(0xFF8A5F3C)));
    const cores = [Color(0xFFE5533D), Color(0xFF3E8AE0), Color(0xFFF2A541), Color(0xFF7CC160), Color(0xFF8E44AD)];
    final alto = dentro.height / 4;
    for (var s = 0; s < 4; s++) {
      final y = dentro.top + (s + 1) * alto;
      var x = dentro.left + _k * .01;
      var k = 0;
      while (x < dentro.right - _k * .02) {
        final bw = _k * (.03 + .015 * ((s * 3 + k) % 3));
        final bh = alto * (.6 + .1 * ((s + k) % 3));
        _ret(Rect.fromLTRB(x, y - bh, math.min(x + bw, dentro.right), y), cores[(s * 2 + k) % cores.length], contorno: .5);
        x += bw + _k * .004;
        k++;
      }
      _ret(Rect.fromLTRB(est.left, y - _k * .006, est.right, y + _k * .014), const Color(0xFFA6784F), contorno: .6);
    }
    // vaso com flor à direita, no alto
    final v = _o(.86, .28);
    _ret(Rect.fromCenter(center: v.translate(0, _k * .05), width: _k * .07, height: _k * .09), const Color(0xFF6FC3C9),
        raio: _k * .02, contorno: .7);
    for (var i = 0; i < 3; i++) {
      final a = -math.pi / 2 + (i - 1) * .5;
      final ponta = v + Offset(math.cos(a), math.sin(a)) * _k * .08;
      _c.drawLine(v, ponta, _traco(.6));
      _forma(Path()..addOval(Rect.fromCircle(center: ponta, radius: _k * .022)),
          [const Color(0xFFFF8FB1), const Color(0xFFFFD54F), const Color(0xFFFF8FB1)][i],
          contorno: .5);
    }
  }

  /// 1: parede verde-sálvia com uma costela-de-adão no vaso à direita e um quadrinho à esquerda.
  void _paredePlanta() {
    _c.drawRect(Offset.zero & _s, _tinta(const Color(0xFFD5E6D3)));
    // painel de ripas de madeira na metade de baixo
    final ripas = _r(0, .58, 1, 1);
    _c.drawRect(ripas, _tinta(const Color(0xFFC79A6B)));
    final ripa = _traco(.35);
    final n = math.max(4, (_s.width / (_k * .06)).round());
    for (var i = 1; i < n; i++) {
      final x = _s.width * i / n;
      _c.drawLine(Offset(x, ripas.top), Offset(x, ripas.bottom), ripa);
    }
    _c.drawLine(Offset(0, ripas.top), Offset(_s.width, ripas.top), _traco(.7));
    // quadrinho
    final q = _r(.06, .1, .2, .26);
    _ret(q, const Color(0xFF3A2A33), contorno: .5);
    _c.drawRect(q.deflate(_k * .012), _tinta(const Color(0xFFF2A541)));
    _c.drawCircle(q.center, q.shortestSide * .22, _tinta(const Color(0xFFFFF6E0)));
    // a planta grande
    final boca = _o(.9, .72);
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i - 2.5) * .42;
      final comp = _k * (.24 + .06 * (i % 2));
      final ponta = boca + Offset(math.cos(a), math.sin(a)) * comp;
      final meio = Offset.lerp(boca, ponta, .6)!;
      final nn = Offset(-math.sin(a), math.cos(a)) * comp * .32;
      final folha = Path()
        ..moveTo(boca.dx, boca.dy)
        ..quadraticBezierTo(meio.dx + nn.dx, meio.dy + nn.dy, ponta.dx, ponta.dy)
        ..quadraticBezierTo(meio.dx - nn.dx, meio.dy - nn.dy, boca.dx, boca.dy)
        ..close();
      _forma(folha, i.isEven ? const Color(0xFF3E9A4A) : const Color(0xFF58B562), contorno: .6);
      _c.drawLine(boca, Offset.lerp(boca, ponta, .85)!, _traco(.3));
    }
    final vaso = Path()
      ..moveTo(boca.dx - _k * .08, boca.dy)
      ..lineTo(boca.dx + _k * .08, boca.dy)
      ..lineTo(boca.dx + _k * .06, boca.dy + _k * .14)
      ..lineTo(boca.dx - _k * .06, boca.dy + _k * .14)
      ..close();
    _forma(vaso, const Color(0xFFF4F1EA), contorno: .8);
  }

  /// 2: parede lilás com um quadro abstrato à esquerda e uma prateleira com caneca e livros à direita.
  void _paredeQuadro() {
    _c.drawRect(Offset.zero & _s, _tinta(const Color(0xFFE2DDF2)));
    _rodape(const Color(0xFFCFC7E6));
    final q = _r(.04, .08, .26, .34);
    _ret(q.inflate(_k * .012), const Color(0xFFF7F3EA), contorno: .8);
    final dentro = q.deflate(_k * .006);
    _c.save();
    _c.clipRect(dentro);
    _c.drawRect(dentro, _tinta(const Color(0xFF6FC3C9)));
    _c.drawCircle(Offset(dentro.left + dentro.width * .3, dentro.top + dentro.height * .35), dentro.shortestSide * .28,
        _tinta(const Color(0xFFF2A541)));
    _c.drawRect(Rect.fromLTRB(dentro.left, dentro.top + dentro.height * .6, dentro.right, dentro.bottom),
        _tinta(const Color(0xFFE5533D)));
    _c.restore();
    // prateleira
    final y = _s.height * .36;
    _ret(Rect.fromLTRB(_s.width * .74, y, _s.width * 1.02, y + _k * .02), const Color(0xFF9A6B44), contorno: .7);
    final caneca = Rect.fromLTWH(_s.width * .78, y - _k * .07, _k * .06, _k * .07);
    _c.drawArc(Rect.fromLTWH(caneca.right - _k * .015, caneca.top + _k * .015, _k * .035, _k * .035), -math.pi / 2, math.pi,
        false, _traco(.8));
    _ret(caneca, const Color(0xFFF07C6C), contorno: .6, raio: _k * .01);
    for (var i = 0; i < 3; i++) {
      _ret(Rect.fromLTWH(_s.width * .88 + i * _k * .03, y - _k * (.08 + .01 * i), _k * .026, _k * (.08 + .01 * i)),
          [const Color(0xFF3E8AE0), const Color(0xFF7CC160), const Color(0xFFF2A541)][i],
          contorno: .5);
    }
    // varal de luzinhas no alto
    final fio = Path()
      ..moveTo(_s.width * .3, _s.height * .04)
      ..quadraticBezierTo(_s.width * .65, _s.height * .14, _s.width * 1.02, _s.height * .04);
    _c.drawPath(fio, _traco(.4));
    for (var i = 1; i < 6; i++) {
      final t = i / 6;
      final x = (1 - t) * (1 - t) * .3 + 2 * (1 - t) * t * .65 + t * t * 1.02;
      final yy = (1 - t) * (1 - t) * .04 + 2 * (1 - t) * t * .14 + t * t * .04;
      final o = _o(x, yy).translate(0, _k * .012);
      final acesas = hora == HoraHistoria.noite || hora == HoraHistoria.tarde;
      if (acesas) {
        _c.drawCircle(o, _k * .03,
            Paint()
              ..shader = RadialGradient(colors: [const Color(0x99FFD27F), const Color(0x00FFD27F)])
                  .createShader(Rect.fromCircle(center: o, radius: _k * .03)));
      }
      _c.drawCircle(o, _k * .01, acesas ? (Paint()..color = const Color(0xFFFFE6A0)) : _tinta(const Color(0xFFF6E7C1)));
    }
  }

  /// 3: parede cinza-azulada com uma janela à direita (o céu da hora) e a cortina.
  void _paredeJanela() {
    _c.drawRect(Offset.zero & _s, _tinta(const Color(0xFFDCE4EC)));
    _rodape(const Color(0xFFC6D1DC));
    final j = _r(.72, .08, 1.06, .5);
    _c.save();
    _c.clipRect(j);
    final ceu = switch (hora) {
      HoraHistoria.amanhecer => const [Color(0xFF8FB4EA), Color(0xFFFFC9A0)],
      HoraHistoria.dia => const [Color(0xFF4FA8F0), Color(0xFFBFE4FF)],
      HoraHistoria.tarde => const [Color(0xFF7A4F9E), Color(0xFFFFA054)],
      HoraHistoria.noite => const [Color(0xFF070D26), Color(0xFF2A3466)],
    };
    _c.drawRect(
        j,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: ceu).createShader(j));
    if (hora == HoraHistoria.noite) {
      _c.drawCircle(Offset(j.left + j.width * .4, j.top + j.height * .3), _k * .035, Paint()..color = const Color(0xFFF3EFD8));
      for (var i = 0; i < 6; i++) {
        _c.drawCircle(Offset(j.left + j.width * (.15 + .14 * i), j.top + j.height * (.15 + .35 * ((i * 7) % 3) / 3)), _k * .005,
            Paint()..color = const Color(0xFFFFFAE8));
      }
    } else {
      final sol = hora == HoraHistoria.dia ? const Color(0xFFFFF4B0) : const Color(0xFFFFB36B);
      _c.drawCircle(Offset(j.left + j.width * .45, j.top + j.height * (hora == HoraHistoria.dia ? .3 : .7)), _k * .04,
          Paint()..color = sol);
      _c.drawOval(Rect.fromCenter(center: Offset(j.left + j.width * .25, j.top + j.height * .55), width: _k * .1, height: _k * .035),
          Paint()..color = const Color(0xCCFFFFFF));
    }
    // prédios ao longe
    for (var i = 0; i < 4; i++) {
      final alto = j.height * (.18 + .12 * ((i * 5) % 3));
      _c.drawRect(Rect.fromLTRB(j.left + j.width * i * .26, j.bottom - alto, j.left + j.width * (i * .26 + .22), j.bottom),
          Paint()..color = hora == HoraHistoria.noite ? const Color(0xFF26304A) : const Color(0xFF8C9DB8));
    }
    _c.restore();
    final mold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _k * .022
      ..color = _luz(const Color(0xFFFFFFFF));
    _c.drawRect(j, mold);
    _c.drawLine(Offset(j.center.dx, j.top), Offset(j.center.dx, j.bottom), mold..strokeWidth = _k * .014);
    _c.drawRect(j.inflate(_k * .011), _traco(.7));
    // cortina à esquerda da janela
    final cortina = Path()
      ..moveTo(j.left - _k * .06, j.top - _k * .03)
      ..lineTo(j.left + _k * .03, j.top - _k * .03)
      ..quadraticBezierTo(j.left + _k * .04, j.center.dy, j.left - _k * .01, j.bottom + _k * .1)
      ..lineTo(j.left - _k * .06, j.bottom + _k * .1)
      ..close();
    _forma(cortina, const Color(0xFF7B8FD6), contorno: .7);
  }

  void _rodape(Color cor) {
    final r = _r(0, .9, 1, 1);
    _c.drawRect(r, _tinta(cor));
    _c.drawLine(Offset(0, r.top), Offset(_s.width, r.top), _traco(.5));
  }

  /// Abajur aceso num canto de baixo (tarde e noite): o halo quente ilumina a parede.
  void _abajur({required bool direita}) {
    final o = _o(direita ? .9 : .1, .74);
    final r = _k * (hora == HoraHistoria.noite ? .5 : .36);
    _c.drawCircle(
      o,
      r,
      Paint()
        ..shader = RadialGradient(colors: const [Color(0x66FFD08A), Color(0x00FFD08A)]).createShader(Rect.fromCircle(center: o, radius: r)),
    );
    final cupula = Path()
      ..moveTo(o.dx - _k * .04, o.dy - _k * .05)
      ..lineTo(o.dx + _k * .04, o.dy - _k * .05)
      ..lineTo(o.dx + _k * .065, o.dy + _k * .03)
      ..lineTo(o.dx - _k * .065, o.dy + _k * .03)
      ..close();
    _forma(cupula, const Color(0xFFFFE08A), contorno: .6, emite: true);
    _c.drawLine(Offset(o.dx, o.dy + _k * .03), Offset(o.dx, _s.height), _traco(1.4));
  }

  /// Ainda não entrou: tela escura, avatar com as iniciais e a câmera desligada.
  void _apagada() {
    _c.drawRect(Offset.zero & _s, Paint()..color = _corApagada);
    const avatares = [Color(0xFF6A5ACD), Color(0xFF2E86AB), Color(0xFFD9674F), Color(0xFF3F8F8A)];
    // no centro: o palco pode escrever as iniciais por cima (num Text) quando não as passa aqui
    final c = Offset(_s.width / 2, _s.height / 2);
    final r = _k * .2;
    _c.drawCircle(c, r, Paint()..color = avatares[indice.abs() % avatares.length]);
    _c.drawCircle(c, r, _traco(.8));
    final ini = (iniciais ?? '').trim();
    if (ini.isNotEmpty) {
      final tp = TextPainter(
        text: TextSpan(
          text: ini.characters.take(2).toString().toUpperCase(),
          style: TextStyle(color: Colors.white, fontSize: r * .82, fontWeight: FontWeight.w800, height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(_c, c - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
    // câmera desligada (com o risco) no canto de baixo
    final ic = Offset(_s.width * .14, _s.height * .86);
    final tam = _k * .05;
    final linha = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1, _k * .012)
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE6EAF2);
    _c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: ic.translate(-tam * .2, 0), width: tam * 1.3, height: tam),
        Radius.circular(tam * .2)), linha);
    _c.drawPath(
        Path()
          ..moveTo(ic.dx + tam * .45, ic.dy)
          ..lineTo(ic.dx + tam * .9, ic.dy - tam * .35)
          ..lineTo(ic.dx + tam * .9, ic.dy + tam * .35)
          ..close(),
        linha);
    _c.drawLine(ic.translate(-tam, -tam * .8), ic.translate(tam, tam * .8), linha..color = const Color(0xFFFF6B5E));
  }

  @override
  bool shouldRepaint(MolduraWebcamPainter old) =>
      old.indice != indice || old.acesa != acesa || old.hora != hora || old.iniciais != iniciais || old.falando != falando;
}
