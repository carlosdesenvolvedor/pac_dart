import 'dart:math' as math;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/voz_ingles.dart';
import '../../domain/boca.dart';

/// Os cabelos que o desenho sabe fazer.
enum Cabelo { curto, lateral, franja, cacheado, longo, rabo, coque, bob }

/// A cara de um personagem do curso de inglês: cores, cabelo e acessórios.
class Aparencia {
  final Color pele, cabelo, roupa;
  final Cabelo estilo;
  final bool oculos, gorro, brincos, sardas, jaleco, flor, cilios, fone;
  final Color? detalhe;

  const Aparencia({
    required this.pele,
    required this.cabelo,
    required this.roupa,
    required this.estilo,
    this.oculos = false,
    this.gorro = false,
    this.brincos = false,
    this.sardas = false,
    this.jaleco = false,
    this.flor = false,
    this.cilios = false,
    this.fone = false,
    this.detalhe,
  });
}

/// O elenco fixo (ver `tools/ingles/dados/DESIGN.md` §5.5) e os papéis genéricos.
abstract final class ElencoIngles {
  static const _peleClara = Color(0xFFFFDCC4);
  static const _peleRosada = Color(0xFFFCD3BC);
  static const _peleMorena = Color(0xFFD9A07A);
  static const _peleMarrom = Color(0xFFB57A55);
  static const _peleAmarelada = Color(0xFFF7D9B5);

  static const mike = Aparencia(
    pele: _peleClara,
    cabelo: Color(0xFF6B4630),
    roupa: Color(0xFF34558B),
    estilo: Cabelo.curto,
    oculos: true,
    detalhe: Color(0xFF263F69),
  );
  static const sarah = Aparencia(
    pele: _peleRosada,
    cabelo: Color(0xFFF2C46B),
    roupa: Color(0xFFFF7F6E),
    estilo: Cabelo.rabo,
    brincos: true,
    cilios: true,
  );
  static const ana = Aparencia(
    pele: _peleMarrom,
    cabelo: Color(0xFF2E1E1A),
    roupa: Color(0xFFFFC233),
    estilo: Cabelo.cacheado,
    flor: true,
    brincos: true,
    cilios: true,
  );
  static const ben = Aparencia(
    pele: _peleClara,
    cabelo: Color(0xFFD9692E),
    roupa: Color(0xFFC0392B),
    estilo: Cabelo.curto,
    gorro: true,
    sardas: true,
    detalhe: Color(0xFF2F8F5B),
  );
  static const emma = Aparencia(
    pele: _peleRosada,
    cabelo: Color(0xFF9A4A2A),
    roupa: Color(0xFF2BA39A),
    estilo: Cabelo.bob,
    brincos: true,
    cilios: true,
  );
  static const lucas = Aparencia(
    pele: _peleMorena,
    cabelo: Color(0xFF1E1A1A),
    roupa: Color(0xFF4CAF6E),
    estilo: Cabelo.lateral,
  );
  static const julia = Aparencia(
    pele: _peleMorena,
    cabelo: Color(0xFF4A2C20),
    roupa: Color(0xFFB98AE0),
    estilo: Cabelo.longo,
    cilios: true,
  );
  static const draLee = Aparencia(
    pele: _peleAmarelada,
    cabelo: Color(0xFF1C1B22),
    roupa: Color(0xFF7FB8E8),
    estilo: Cabelo.coque,
    jaleco: true,
    cilios: true,
  );
  /// O aluno (as falas `voce`): dev brasileiro de fone, estudando.
  static const voce = Aparencia(
    pele: _peleMorena,
    cabelo: Color(0xFF2B1E18),
    roupa: Color(0xFF6C5CE7),
    estilo: Cabelo.curto,
    fone: true,
  );
  static const ela = Aparencia(
    pele: _peleAmarelada,
    cabelo: Color(0xFF5B3A29),
    roupa: Color(0xFF8D99AE),
    estilo: Cabelo.franja,
    cilios: true,
  );
  static const ele = Aparencia(
    pele: _peleRosada,
    cabelo: Color(0xFF3B2A22),
    roupa: Color(0xFF8D99AE),
    estilo: Cabelo.lateral,
  );

  static const _porNome = {
    'mike': mike,
    'sarah': sarah,
    'ana': ana,
    'ben': ben,
    'emma': emma,
    'lucas': lucas,
    'julia': julia,
    'dra-lee': draLee,
  };

  /// Papéis genéricos femininos (o mesmo critério da voz em `tools/ingles/vozes_google.py`).
  static const _femininos = {
    'recrutadora', 'diretora', 'moradora', 'engenheira', 'corretora', 'passageira', 'estagiaria', 'gestora',
    'recepcionista', 'atendente', 'guia', 'enfermeira', 'professora', 'vizinha', 'amiga', 'chefe', 'medica',
  };

  /// A cara de [quem] (o campo `quem` da frase); null = ninguém (sem rosto).
  static Aparencia? de(String quem) {
    if (quem.isEmpty) return null;
    if (quem == 'voce') return voce;
    return _porNome[quem] ?? (_femininos.contains(quem) ? ela : ele);
  }

  static const nomes = ['mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee'];
}

/// O rosto de um personagem, do peito para cima, com a boca no formato [visema]. [olhos] = 1 aberto, 0 fechado
/// (piscar); [balanco] de -1 a 1 inclina de leve a cabeça (respiração/idle).
class RostoPersonagem extends StatelessWidget {
  final Aparencia aparencia;
  final Visema visema;
  final double olhos, balanco, tamanho;

  const RostoPersonagem({
    super.key,
    required this.aparencia,
    required this.tamanho,
    this.visema = Visema.x,
    this.olhos = 1,
    this.balanco = 0,
  });

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(tamanho),
    painter: PersonagemPainter(aparencia, visema: visema, olhos: olhos, balanco: balanco),
  );
}

/// Personagem fofo (chibi): cabeça grande, olhos com brilho, bochechas rosadas. Tudo em vetor.
class PersonagemPainter extends CustomPainter {
  final Aparencia a;
  final Visema visema;
  final double olhos, balanco;

  PersonagemPainter(this.a, {this.visema = Visema.x, this.olhos = 1, this.balanco = 0});

  static const _contorno = Color(0xFF3A2A33);
  static const _bocaDentro = Color(0xFF7A2638);
  static const _lingua = Color(0xFFF26D7D);
  static const _bochecha = Color(0xFFFF7E95);

  late double _s;
  Offset _p(double x, double y) => Offset(x * _s, y * _s);
  Rect _oval(double cx, double cy, double rx, double ry) =>
      Rect.fromCenter(center: _p(cx, cy), width: rx * 2 * _s, height: ry * 2 * _s);

  Color _escurece(Color c, double q) => Color.lerp(c, Colors.black, q)!;
  Color _clareia(Color c, double q) => Color.lerp(c, Colors.white, q)!;

  @override
  void paint(Canvas canvas, Size size) {
    _s = math.min(size.width, size.height);
    _corpo(canvas);
    canvas.save();
    // a cabeça balança em torno do pescoço
    canvas.translate(_s * .5, _s * .78);
    canvas.rotate(balanco * .04);
    canvas.translate(-_s * .5, -_s * .78);
    _cabeloAtras(canvas);
    _orelhas(canvas);
    _cabeca(canvas);
    _rosto(canvas);
    _boca(canvas);
    _cabeloFrente(canvas);
    _acessoriosCabeca(canvas);
    canvas.restore();
  }

  // ───────────────────────── corpo ─────────────────────────

  void _corpo(Canvas c) {
    final pele = Paint()..color = a.pele;
    // pescoço
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(_s * .43, _s * .68, _s * .57, _s * .86), Radius.circular(_s * .04)),
        pele);
    c.drawRect(Rect.fromLTRB(_s * .43, _s * .74, _s * .57, _s * .8), Paint()..color = _escurece(a.pele, .12));
    // ombros (a blusa)
    final ombros = Path()
      ..moveTo(_s * .12, _s * 1.02)
      ..cubicTo(_s * .12, _s * .86, _s * .26, _s * .79, _s * .5, _s * .79)
      ..cubicTo(_s * .74, _s * .79, _s * .88, _s * .86, _s * .88, _s * 1.02)
      ..close();
    final roupa = a.jaleco ? Colors.white : a.roupa;
    c.drawPath(
      ombros,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_clareia(roupa, .12), _escurece(roupa, .08)],
        ).createShader(Rect.fromLTRB(0, _s * .79, _s, _s)),
    );
    if (a.jaleco) {
      // blusa azul por baixo do jaleco, lapelas e estetoscópio
      final decote = Path()
        ..moveTo(_s * .4, _s * .8)
        ..lineTo(_s * .5, _s * .95)
        ..lineTo(_s * .6, _s * .8)
        ..close();
      c.drawPath(decote, Paint()..color = a.roupa);
      final lapela = Paint()
        ..color = const Color(0xFFDDE3EA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * .012
        ..strokeCap = StrokeCap.round;
      c.drawLine(_p(.4, .8), _p(.5, .97), lapela);
      c.drawLine(_p(.6, .8), _p(.5, .97), lapela);
      final est = Paint()
        ..color = const Color(0xFF55606E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * .013
        ..strokeCap = StrokeCap.round;
      final tubo = Path()
        ..moveTo(_s * .36, _s * .81)
        ..cubicTo(_s * .3, _s * .9, _s * .36, _s * .97, _s * .44, _s * .95);
      c.drawPath(tubo, est);
      c.drawCircle(_p(.455, .945), _s * .022, Paint()..color = const Color(0xFFB8C2CC));
      c.drawCircle(_p(.455, .945), _s * .022, est..strokeWidth = _s * .008);
    } else {
      // gola
      final gola = Path()
        ..moveTo(_s * .41, _s * .795)
        ..quadraticBezierTo(_s * .5, _s * .87, _s * .59, _s * .795);
      c.drawPath(
        gola,
        Paint()
          ..color = _escurece(a.roupa, .22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s * .014
          ..strokeCap = StrokeCap.round,
      );
      if (a.detalhe case final d? when a.gorro) {
        // cachecol do Ben
        final cachecol = RRect.fromRectAndRadius(Rect.fromLTRB(_s * .33, _s * .79, _s * .67, _s * .86), Radius.circular(_s * .035));
        c.drawRRect(cachecol, Paint()..color = d);
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(_s * .55, _s * .82, _s * .62, _s * .97), Radius.circular(_s * .03)),
          Paint()..color = _escurece(d, .08),
        );
      } else if (a.detalhe case final d?) {
        // cordão de crachá do Mike
        final cordao = Paint()
          ..color = d
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s * .012;
        c.drawLine(_p(.42, .81), _p(.47, .95), cordao);
        c.drawLine(_p(.58, .81), _p(.53, .95), cordao);
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(_s * .45, _s * .93, _s * .55, _s * 1.0), Radius.circular(_s * .012)),
          Paint()..color = Colors.white,
        );
      }
    }
  }

  // ───────────────────────── cabeça ─────────────────────────

  void _orelhas(Canvas c) {
    for (final x in [.175, .825]) {
      c.drawOval(_oval(x, .52, .05, .062), Paint()..color = a.pele);
      c.drawOval(_oval(x, .52, .025, .035), Paint()..color = _escurece(a.pele, .1));
    }
    if (a.brincos) {
      for (final x in [.175, .825]) {
        c.drawCircle(_p(x, .6), _s * .016, Paint()..color = const Color(0xFFFFD45C));
        c.drawCircle(_p(x - .005, .595), _s * .006, Paint()..color = Colors.white.withValues(alpha: .8));
      }
    }
  }

  void _cabeca(Canvas c) {
    final cabeca = _oval(.5, .48, .325, .305);
    c.drawOval(
      cabeca,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.25, -.35),
          radius: .9,
          colors: [_clareia(a.pele, .18), a.pele, _escurece(a.pele, .06)],
          stops: const [0, .6, 1],
        ).createShader(cabeca),
    );
  }

  void _rosto(Canvas c) {
    // bochechas
    for (final x in [.31, .69]) {
      c.drawOval(
        _oval(x, .615, .058, .034),
        Paint()
          ..color = _bochecha.withValues(alpha: .42)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, _s * .008),
      );
    }
    if (a.sardas) {
      final sarda = Paint()..color = _escurece(a.pele, .28).withValues(alpha: .7);
      for (final (x, y) in [(.29, .585), (.32, .6), (.27, .605), (.71, .585), (.68, .6), (.73, .605)]) {
        c.drawCircle(_p(x, y), _s * .006, sarda);
      }
    }
    // sobrancelhas
    final sob = Paint()
      ..color = _escurece(a.cabelo, .15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _s * .016
      ..strokeCap = StrokeCap.round;
    for (final lado in [-1.0, 1.0]) {
      final cx = .5 + lado * .125;
      final p = Path()
        ..moveTo(_s * (cx - lado * .045), _s * .445)
        ..quadraticBezierTo(_s * cx, _s * .42, _s * (cx + lado * .045), _s * .44);
      c.drawPath(p, sob);
    }
    // olhos
    for (final x in [.375, .625]) {
      if (olhos < .25) {
        // piscando: um arquinho
        final p = Path()
          ..moveTo(_s * (x - .042), _s * .525)
          ..quadraticBezierTo(_s * x, _s * .55, _s * (x + .042), _s * .525);
        c.drawPath(
          p,
          Paint()
            ..color = _contorno
            ..style = PaintingStyle.stroke
            ..strokeWidth = _s * .014
            ..strokeCap = StrokeCap.round,
        );
        continue;
      }
      final ry = .07 * olhos;
      final olho = _oval(x, .53, .05, ry);
      c.drawOval(
        olho,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1F2D), Color(0xFF4B3550)],
          ).createShader(olho),
      );
      // brilhos
      c.drawCircle(_p(x + .016, .53 - ry * .45), _s * .019, Paint()..color = Colors.white);
      c.drawCircle(_p(x - .016, .53 + ry * .45), _s * .009, Paint()..color = Colors.white.withValues(alpha: .85));
      if (a.cilios) {
        // dois cílios no canto de fora
        final lado = x < .5 ? -1.0 : 1.0;
        final cilio = Paint()
          ..color = const Color(0xFF2A1F2D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s * .01
          ..strokeCap = StrokeCap.round;
        final canto = _p(x + lado * .042, .53 - ry * .62);
        c.drawLine(canto, canto + Offset(lado * .03, -.018) * _s, cilio);
        c.drawLine(canto + Offset(-lado * .012, -.012) * _s, canto + Offset(lado * .014, -.036) * _s, cilio);
      }
    }
    // nariz
    final nariz = Path()
      ..moveTo(_s * .487, _s * .6)
      ..quadraticBezierTo(_s * .5, _s * .612, _s * .513, _s * .6);
    c.drawPath(
      nariz,
      Paint()
        ..color = _escurece(a.pele, .3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * .01
        ..strokeCap = StrokeCap.round,
    );
    if (a.oculos) {
      final aro = Paint()
        ..color = const Color(0xFF3B3B4F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * .013;
      for (final x in [.375, .625]) {
        c.drawCircle(_p(x, .53), _s * .078, Paint()..color = Colors.white.withValues(alpha: .12));
        c.drawCircle(_p(x, .53), _s * .078, aro);
      }
      final ponte = Path()
        ..moveTo(_s * .453, _s * .525)
        ..quadraticBezierTo(_s * .5, _s * .505, _s * .547, _s * .525);
      c.drawPath(ponte, aro);
      c.drawLine(_p(.297, .52), _p(.2, .5), aro);
      c.drawLine(_p(.703, .52), _p(.8, .5), aro);
    }
  }

  // ───────────────────────── boca ─────────────────────────

  void _boca(Canvas c) {
    c.save();
    // a boca inteira 35% maior que o desenho-base: lê bem até nos rostos pequenos
    c.translate(_s * .5, _s * .67);
    c.scale(1.35);
    c.translate(-_s * .5, -_s * .67);
    _formatoBoca(c);
    c.restore();
  }

  void _formatoBoca(Canvas c) {
    const cx = .5, cy = .67;
    final labio = Paint()
      ..color = _contorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = _s * .011
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final dentro = Paint()..color = _bocaDentro;
    final dente = Paint()..color = Colors.white;
    final lingua = Paint()..color = _lingua;

    /// Boca aberta: um "D" deitado (topo quase reto, fundo redondo) de meia-largura [rx] e altura [h].
    Path aberta(double rx, double h, {double topo = .012}) => Path()
      ..moveTo(_s * (cx - rx), _s * (cy - h * .35))
      ..quadraticBezierTo(_s * cx, _s * (cy - h * .35 - topo), _s * (cx + rx), _s * (cy - h * .35))
      ..cubicTo(_s * (cx + rx), _s * (cy + h * .5), _s * (cx + rx * .4), _s * (cy + h * .65), _s * cx, _s * (cy + h * .65))
      ..cubicTo(_s * (cx - rx * .4), _s * (cy + h * .65), _s * (cx - rx), _s * (cy + h * .5), _s * (cx - rx), _s * (cy - h * .35))
      ..close();

    void desenhaAberta(Path p, {double dentes = 0, double linguaY = .6, double linguaR = .5, bool linguaEmCima = false}) {
      c.save();
      c.clipPath(p);
      c.drawPath(p, dentro);
      final r = p.getBounds();
      if (linguaEmCima) {
        c.drawOval(
          Rect.fromCenter(center: Offset(r.center.dx, r.top + r.height * .38), width: r.width * .5, height: r.height * .45),
          lingua,
        );
      } else {
        c.drawOval(
          Rect.fromCenter(
            center: Offset(r.center.dx, r.top + r.height * (linguaY + .35)),
            width: r.width * (linguaR + .3),
            height: r.height * linguaR * 1.3,
          ),
          lingua,
        );
      }
      if (dentes > 0) c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, r.height * dentes), dente);
      c.restore();
      c.drawPath(p, labio);
    }

    switch (visema) {
      case Visema.x:
        final p = Path()
          ..moveTo(_s * (cx - .04), _s * (cy - .006))
          ..quadraticBezierTo(_s * cx, _s * (cy + .03), _s * (cx + .04), _s * (cy - .006));
        c.drawPath(p, labio);
      case Visema.a:
        final p = Path()
          ..moveTo(_s * (cx - .032), _s * cy)
          ..quadraticBezierTo(_s * cx, _s * (cy + .008), _s * (cx + .032), _s * cy);
        c.drawPath(p, labio..strokeWidth = _s * .014);
        // lábio inferior apertado
        c.drawPath(
          Path()
            ..moveTo(_s * (cx - .018), _s * (cy + .014))
            ..quadraticBezierTo(_s * cx, _s * (cy + .022), _s * (cx + .018), _s * (cy + .014)),
          Paint()
            ..color = _escurece(a.pele, .18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = _s * .008
            ..strokeCap = StrokeCap.round,
        );
      case Visema.b:
        desenhaAberta(aberta(.042, .03, topo: .004), dentes: .55, linguaR: .3);
      case Visema.c:
        desenhaAberta(aberta(.042, .055), dentes: .22, linguaR: .45);
      case Visema.d:
        desenhaAberta(aberta(.048, .085), dentes: .16, linguaR: .5);
      case Visema.e:
        desenhaAberta(
          Path()..addOval(_oval(cx, cy + .008, .03, .036)),
          dentes: .12,
          linguaR: .45,
        );
      case Visema.f:
        final p = Path()..addOval(_oval(cx, cy + .006, .017, .02));
        c.drawPath(p, dentro);
        c.drawPath(p, labio..strokeWidth = _s * .014);
      case Visema.g:
        desenhaAberta(aberta(.038, .03, topo: .004), dentes: .7, linguaR: .2);
        // lábio de baixo encostando nos dentes
        c.drawPath(
          Path()
            ..moveTo(_s * (cx - .03), _s * (cy + .012))
            ..quadraticBezierTo(_s * cx, _s * (cy + .004), _s * (cx + .03), _s * (cy + .012)),
          Paint()
            ..color = _escurece(a.pele, .2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = _s * .01
            ..strokeCap = StrokeCap.round,
        );
      case Visema.h:
        desenhaAberta(aberta(.04, .055), dentes: .18, linguaEmCima: true);
    }
  }

  // ───────────────────────── cabelo ─────────────────────────

  Paint get _tinta => Paint()..color = a.cabelo;
  Paint get _tintaClara => Paint()..color = _clareia(a.cabelo, .14);

  void _cabeloAtras(Canvas c) {
    switch (a.estilo) {
      case Cabelo.longo:
        final p = Path()
          ..moveTo(_s * .17, _s * .4)
          ..cubicTo(_s * .1, _s * .7, _s * .12, _s * .9, _s * .2, _s * .95)
          ..lineTo(_s * .8, _s * .95)
          ..cubicTo(_s * .88, _s * .9, _s * .9, _s * .7, _s * .83, _s * .4)
          ..close();
        c.drawPath(p, _tinta);
      case Cabelo.bob:
        final p = Path()
          ..moveTo(_s * .15, _s * .42)
          ..cubicTo(_s * .11, _s * .6, _s * .12, _s * .74, _s * .2, _s * .77)
          ..quadraticBezierTo(_s * .5, _s * .82, _s * .8, _s * .77)
          ..cubicTo(_s * .88, _s * .74, _s * .89, _s * .6, _s * .85, _s * .42)
          ..close();
        c.drawPath(p, _tinta);
      case Cabelo.rabo:
        // rabo de cavalo saindo atrás, para a direita
        final p = Path()
          ..moveTo(_s * .74, _s * .26)
          ..cubicTo(_s * .98, _s * .24, _s * 1.0, _s * .5, _s * .9, _s * .72)
          ..cubicTo(_s * .86, _s * .6, _s * .84, _s * .45, _s * .74, _s * .4)
          ..close();
        c.drawPath(p, _tinta);
        c.drawOval(_oval(.79, .27, .035, .03), Paint()..color = const Color(0xFFFF5D8F));
      case Cabelo.coque:
        c.drawCircle(_p(.5, .13), _s * .1, _tinta);
        c.drawCircle(_p(.47, .1), _s * .035, _tintaClara);
      case Cabelo.cacheado:
        // volume de cachos em volta da cabeça
        final cachos = <(double, double, double)>[
          (.18, .5, .09), (.15, .38, .09), (.2, .26, .095), (.31, .16, .1), (.44, .11, .1), (.57, .11, .1),
          (.7, .16, .1), (.8, .26, .095), (.85, .38, .09), (.82, .5, .09), (.19, .62, .08), (.81, .62, .08),
        ];
        for (final (x, y, r) in cachos) {
          c.drawCircle(_p(x, y), _s * r, _tinta);
        }
      case Cabelo.curto || Cabelo.lateral || Cabelo.franja:
        break;
    }
  }

  void _cabeloFrente(Canvas c) {
    // touca: cobre o alto da cabeça, das têmporas para cima
    Path touca(Path Function(Path) borda) {
      final p = Path()
        ..moveTo(_s * .165, _s * .5)
        ..cubicTo(_s * .13, _s * .2, _s * .32, _s * .12, _s * .5, _s * .12)
        ..cubicTo(_s * .68, _s * .12, _s * .87, _s * .2, _s * .835, _s * .5);
      return borda(p)..close();
    }

    switch (a.estilo) {
      case Cabelo.curto:
        final p = touca((p) => p
          ..quadraticBezierTo(_s * .8, _s * .36, _s * .74, _s * .34)
          ..quadraticBezierTo(_s * .7, _s * .3, _s * .64, _s * .33)
          ..quadraticBezierTo(_s * .58, _s * .27, _s * .52, _s * .32)
          ..quadraticBezierTo(_s * .45, _s * .26, _s * .4, _s * .32)
          ..quadraticBezierTo(_s * .33, _s * .28, _s * .28, _s * .35)
          ..quadraticBezierTo(_s * .2, _s * .36, _s * .165, _s * .5));
        c.drawPath(p, _tinta);
        // topete
        final topete = Path()
          ..moveTo(_s * .42, _s * .14)
          ..quadraticBezierTo(_s * .5, _s * .04, _s * .6, _s * .1)
          ..quadraticBezierTo(_s * .52, _s * .1, _s * .5, _s * .16)
          ..close();
        c.drawPath(topete, _tinta);
        _brilhoCabelo(c);
      case Cabelo.lateral:
        final p = touca((p) => p
          ..quadraticBezierTo(_s * .82, _s * .38, _s * .72, _s * .3)
          ..quadraticBezierTo(_s * .55, _s * .3, _s * .4, _s * .24)
          ..quadraticBezierTo(_s * .34, _s * .34, _s * .24, _s * .38)
          ..quadraticBezierTo(_s * .18, _s * .42, _s * .165, _s * .5));
        c.drawPath(p, _tinta);
        _brilhoCabelo(c);
      case Cabelo.franja || Cabelo.bob || Cabelo.longo:
        final p = touca((p) => p
          ..quadraticBezierTo(_s * .84, _s * .4, _s * .78, _s * .38)
          ..quadraticBezierTo(_s * .72, _s * .4, _s * .66, _s * .36)
          ..quadraticBezierTo(_s * .6, _s * .4, _s * .54, _s * .37)
          ..quadraticBezierTo(_s * .48, _s * .4, _s * .42, _s * .37)
          ..quadraticBezierTo(_s * .36, _s * .4, _s * .3, _s * .37)
          ..quadraticBezierTo(_s * .22, _s * .4, _s * .165, _s * .5));
        c.drawPath(p, _tinta);
        if (a.estilo != Cabelo.franja) {
          // mechas laterais caindo na frente das orelhas
          for (final lado in [-1.0, 1.0]) {
            final x = .5 + lado * .33;
            final m = Path()
              ..moveTo(_s * (x - lado * .02), _s * .3)
              ..quadraticBezierTo(_s * (x + lado * .04), _s * .55, _s * (x - lado * .01), _s * (a.estilo == Cabelo.bob ? .72 : .8))
              ..quadraticBezierTo(_s * (x - lado * .05), _s * .55, _s * (x - lado * .07), _s * .36)
              ..close();
            c.drawPath(m, _tinta);
          }
        }
        _brilhoCabelo(c);
      case Cabelo.rabo:
        // puxado para trás, com risca
        final p = touca((p) => p
          ..quadraticBezierTo(_s * .8, _s * .32, _s * .66, _s * .27)
          ..quadraticBezierTo(_s * .5, _s * .26, _s * .44, _s * .2)
          ..quadraticBezierTo(_s * .4, _s * .3, _s * .27, _s * .33)
          ..quadraticBezierTo(_s * .19, _s * .38, _s * .165, _s * .5));
        c.drawPath(p, _tinta);
        _brilhoCabelo(c);
      case Cabelo.coque:
        final p = touca((p) => p
          ..quadraticBezierTo(_s * .8, _s * .3, _s * .6, _s * .26)
          ..quadraticBezierTo(_s * .5, _s * .25, _s * .5, _s * .2)
          ..quadraticBezierTo(_s * .5, _s * .25, _s * .4, _s * .26)
          ..quadraticBezierTo(_s * .2, _s * .3, _s * .165, _s * .5));
        c.drawPath(p, _tinta);
        _brilhoCabelo(c);
      case Cabelo.cacheado:
        // franja de cachinhos
        for (final (x, y, r) in [(.27, .3, .07), (.36, .24, .075), (.46, .22, .075), (.56, .22, .075), (.65, .25, .075), (.74, .31, .07)]) {
          c.drawCircle(_p(x, y), _s * r, _tinta);
        }
        for (final (x, y) in [(.35, .2), (.55, .18), (.72, .27)]) {
          c.drawCircle(_p(x, y), _s * .018, Paint()..color = _clareia(a.cabelo, .08));
        }
    }
  }

  void _brilhoCabelo(Canvas c) {
    final p = Path()
      ..moveTo(_s * .3, _s * .22)
      ..quadraticBezierTo(_s * .4, _s * .15, _s * .52, _s * .155);
    c.drawPath(
      p,
      Paint()
        ..color = Colors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _s * .022
        ..strokeCap = StrokeCap.round,
    );
  }

  void _acessoriosCabeca(Canvas c) {
    if (a.gorro) {
      final cor = a.detalhe ?? const Color(0xFF2F8F5B);
      final gorro = Path()
        ..moveTo(_s * .16, _s * .36)
        ..cubicTo(_s * .14, _s * .06, _s * .86, _s * .06, _s * .84, _s * .36)
        ..close();
      c.drawPath(gorro, Paint()..color = cor);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(_s * .14, _s * .3, _s * .86, _s * .39), Radius.circular(_s * .045)),
        Paint()..color = _escurece(cor, .15),
      );
      final listra = Paint()
        ..color = _clareia(cor, .25)
        ..strokeWidth = _s * .012
        ..strokeCap = StrokeCap.round;
      for (var x = .22; x < .8; x += .07) {
        c.drawLine(_p(x, .315), _p(x, .375), listra);
      }
      c.drawCircle(_p(.5, .07), _s * .055, Paint()..color = _clareia(cor, .55));
      // franjinha ruiva saindo do gorro
      for (final (x, y) in [(.3, .4), (.38, .41), (.62, .41), (.7, .4)]) {
        c.drawOval(_oval(x, y, .04, .025), _tinta);
      }
    }
    if (a.fone) {
      // fone de ouvido: o arco por cima do cabelo e as conchas nas orelhas
      final arco = Path()
        ..moveTo(_s * .15, _s * .5)
        ..cubicTo(_s * .1, _s * .02, _s * .9, _s * .02, _s * .85, _s * .5);
      c.drawPath(
        arco,
        Paint()
          ..color = const Color(0xFF3D3D52)
          ..style = PaintingStyle.stroke
          ..strokeWidth = _s * .035
          ..strokeCap = StrokeCap.round,
      );
      for (final x in [.155, .845]) {
        final concha = RRect.fromRectAndRadius(_oval(x, .53, .055, .08), Radius.circular(_s * .05));
        c.drawRRect(concha, Paint()..color = const Color(0xFF3D3D52));
        c.drawRRect(concha.deflate(_s * .015), Paint()..color = const Color(0xFFFFC233));
      }
    }
    if (a.flor) {
      final centro = _p(.25, .27);
      final petala = Paint()..color = const Color(0xFFFF6F91);
      for (var i = 0; i < 5; i++) {
        final ang = i * 2 * math.pi / 5 - math.pi / 2;
        c.drawCircle(centro + Offset(math.cos(ang), math.sin(ang)) * (_s * .03), _s * .025, petala);
      }
      c.drawCircle(centro, _s * .018, Paint()..color = const Color(0xFFFFD45C));
    }
  }

  @override
  bool shouldRepaint(PersonagemPainter old) =>
      old.a != a || old.visema != visema || old.olhos != olhos || old.balanco != balanco;
}

/// O personagem de [quem] mexendo a boca com a voz do app ([VozIngles.falando]) e piscando de vez em quando.
/// Só anima enquanto fala (fora disso, nenhum quadro por segundo).
class PersonagemFalante extends StatefulWidget {
  final String quem;
  final double tamanho;

  /// Mexe a boca só com esta frase (e com palavras dela, no toque na palavra); null = com qualquer fala.
  final String? frase;

  const PersonagemFalante({super.key, required this.quem, required this.tamanho, this.frase});

  @override
  State<PersonagemFalante> createState() => _PersonagemFalanteState();
}

class _PersonagemFalanteState extends State<PersonagemFalante> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_quadro);
  final _sorte = math.Random();
  Visema _visema = Visema.x;
  double _balanco = 0;
  bool _piscando = false;
  Timer? _proximaPiscada, _abreOlho;

  @override
  void initState() {
    super.initState();
    VozIngles.falando.addListener(_mudouFala);
    _mudouFala();
    _agendarPiscada();
  }

  bool _ehMinha(FalaEmCurso? f) {
    if (f == null) return false;
    final minha = widget.frase;
    return minha == null || f.frase == minha || minha.contains(f.frase);
  }

  void _mudouFala() {
    if (_ehMinha(VozIngles.falando.value)) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      if (_ticker.isActive) _ticker.stop();
      if (_visema != Visema.x || _balanco != 0) {
        setState(() {
          _visema = Visema.x;
          _balanco = 0;
        });
      }
    }
  }

  void _quadro(Duration decorrido) {
    final f = VozIngles.falando.value;
    if (!_ehMinha(f)) return;
    final v = f!.visema(DateTime.now());
    final b = math.sin(decorrido.inMilliseconds / 1000 * 2.4) * .7;
    if (v != _visema || (b - _balanco).abs() > .02) {
      setState(() {
        _visema = v;
        _balanco = b;
      });
    }
  }

  void _agendarPiscada() {
    _proximaPiscada = Timer(Duration(milliseconds: 2600 + _sorte.nextInt(2800)), () {
      if (!mounted) return;
      setState(() => _piscando = true);
      _abreOlho = Timer(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        setState(() => _piscando = false);
        _agendarPiscada();
      });
    });
  }

  @override
  void didUpdateWidget(PersonagemFalante old) {
    super.didUpdateWidget(old);
    if (old.frase != widget.frase) _mudouFala();
  }

  @override
  void dispose() {
    VozIngles.falando.removeListener(_mudouFala);
    _proximaPiscada?.cancel();
    _abreOlho?.cancel();
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = ElencoIngles.de(widget.quem);
    if (a == null) return SizedBox.square(dimension: widget.tamanho);
    return RepaintBoundary(
      child: RostoPersonagem(
        aparencia: a,
        tamanho: widget.tamanho,
        visema: _visema,
        olhos: _piscando ? 0 : 1,
        balanco: _balanco,
      ),
    );
  }
}
