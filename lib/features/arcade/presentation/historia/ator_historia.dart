import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ingles/domain/boca.dart';
import '../../../ingles/domain/expressao.dart';
import '../../../ingles/presentation/widgets/elenco_ingles.dart';
import '../../domain/historia_turismo.dart';
import 'elenco_turismo.dart';
import 'props_historia.dart';

/// A pose de um ator num quadro: a ação em curso ([progresso] 0..1) e os estados que persistem.
class PoseAtor {
  final AcaoAtor acao;

  /// Progresso 0..1 da ação.
  final double progresso;

  /// Relógio do idle (respiração/piscada), em segundos.
  final double tempo;
  final bool sentado, dormindo, noCarro, falando;

  const PoseAtor({
    this.acao = AcaoAtor.parado,
    this.progresso = 0,
    this.tempo = 0,
    this.sentado = false,
    this.dormindo = false,
    this.noCarro = false,
    this.falando = false,
  });

  @override
  bool operator ==(Object other) =>
      other is PoseAtor &&
      other.acao == acao &&
      other.progresso == progresso &&
      other.tempo == tempo &&
      other.sentado == sentado &&
      other.dormindo == dormindo &&
      other.noCarro == noCarro &&
      other.falando == falando;

  @override
  int get hashCode => Object.hash(acao, progresso, tempo, sentado, dormindo, noCarro, falando);
}

// ───────────────────────── medidas do corpo (frações da altura H) ─────────────────────────
//
// A caixa do ator tem `.62H × H`. A cabeça (o [RostoPersonagem], que já traz pescoço e ombros) ocupa um
// quadrado de `.58H` no alto; o corpo chibi vem embaixo. Coordenadas "locais": x a partir do centro da caixa,
// y a partir do topo, tudo em H, com o ator **de pé** e olhando para a direita (o espelho vem por fora).

const _rosto = .58;
const _ombroX = .165, _ombroY = .495;
const _braco1 = .125, _braco2 = .12;
const _quadrilX = .065, _quadrilY = .74;
const _maoIdle = Offset(.205, .705);
const _contorno = Color(0xFF3A2A33);
const _corPerna = Color(0xFF3B3F58);
const _corSapato = Color(0xFF2B2B2B);

/// Lugar do prop que o ator segura.
enum _OndeProp { maoDireita, maoEsquerda, acima }

double _suave(double x) {
  final t = x.clamp(0.0, 1.0);
  return t * t * (3 - 2 * t);
}

/// Sobe nos primeiros [r] e desce nos últimos [r] do progresso (ação que começa e termina no idle).
double _envelope(double p, double r) => math.min(1.0, math.min(p / r, (1 - p) / r)).clamp(0.0, 1.0);

/// Sobe nos primeiros [r] e fica (ação que dura a fala).
double _subida(double p, double r) => (p / r).clamp(0.0, 1.0);

/// A geometria de um quadro do ator, calculada só a partir da [PoseAtor] (o corpo, a cabeça, os props e os
/// emotes leem a mesma conta).
class _Quadro {
  /// Deslocamento do corpo inteiro (em H; dy > 0 = para baixo).
  double dx = 0, dy = 0;

  /// Rotação do corpo (rad, horário) em torno do [pivo] (em H, coordenadas da caixa).
  double rot = 0;
  Offset pivo = const Offset(0, 1);

  /// Achatar/esticar (1 = normal), em torno dos pés.
  double escalaY = 1;

  /// A cabeça: deslocamento extra (H), inclinação (`balanco` do rosto) e olhar extra.
  double cabecaDx = 0, cabecaDy = 0, balanco = 0;
  Offset olhar = Offset.zero;

  /// Mãos (coordenadas locais, H).
  Offset maoD = _maoIdle, maoE = Offset(-_maoIdle.dx, _maoIdle.dy);

  /// Passada (-1..1) e quanto está sentado (0..1).
  double passo = 0, agacha = 0;
  bool noCarro = false, dormindo = false, dedo = false, caneta = false, estrelinhas = false;
  double carroDy = 0;
  _OndeProp ondeProp = _OndeProp.maoDireita;

  static const _levantam = {
    AcaoAtor.pula,
    AcaoAtor.comemora,
    AcaoAtor.anda,
    AcaoAtor.corre,
    AcaoAtor.sai,
    AcaoAtor.entra,
    AcaoAtor.danca,
  };

  _Quadro.de(PoseAtor pose, {required double altura, required bool reduzir}) {
    final p = pose.progresso.isNaN ? 0.0 : pose.progresso.clamp(0.0, 1.0);
    final t = reduzir ? 0.0 : pose.tempo;
    final acao = pose.acao;
    noCarro = pose.noCarro;
    dormindo = pose.dormindo || acao == AcaoAtor.dorme;

    // idle: respiração e balanço da cabeça (mais vivo enquanto fala)
    final resp = math.sin(2 * math.pi * t / 3.4);
    cabecaDy = .004 * resp;
    balanco = pose.falando ? math.sin(t * 2.4) * .7 : math.sin(t * .9) * .25;
    maoD = _maoIdle + Offset(0, .004 * resp);
    maoE = Offset(-maoD.dx, maoD.dy);
    final idleD = maoD, idleE = maoE;

    if (pose.sentado && !noCarro && !_levantam.contains(acao)) agacha = 1;
    if (noCarro) {
      // só o busto aparece: o corpo afunda no carro, mãos no volante, o carro balança
      dy = .12;
      carroDy = reduzir ? 0 : math.sin(t * 9) * .006;
      dy += carroDy;
      maoD = const Offset(.11, .56);
      maoE = const Offset(-.11, .56);
    }

    switch (acao) {
      case AcaoAtor.parado:
        break;
      case AcaoAtor.acena:
        final e = _envelope(p, .15);
        final onda = reduzir ? 0.0 : math.sin(p * 3 * 2 * math.pi);
        maoD = Offset.lerp(maoD, Offset(.27 + .05 * onda, .27), e)!;
      case AcaoAtor.pula:
        agacha = 0;
        final h = _pulo(p, reduzir, .18);
        maoD = Offset.lerp(maoD, const Offset(.3, .4), h.$2)!;
        maoE = Offset.lerp(maoE, const Offset(-.3, .4), h.$2)!;
      case AcaoAtor.comemora:
        agacha = 0;
        final k = p >= 1 ? 1.0 : (p * 2) % 1;
        _pulo(k, reduzir, .14);
        final e = _envelope(p, .1);
        final mexe = reduzir ? 0.0 : math.sin(p * 8 * math.pi) * .02;
        maoD = Offset.lerp(maoD, Offset(.22 + mexe, .2), e)!;
        maoE = Offset.lerp(maoE, Offset(-.22 - mexe, .2), e)!;
      case AcaoAtor.aponta:
        final e = _subida(p, .08);
        maoD = Offset.lerp(maoD, const Offset(.4, .47), e)!;
        dedo = e > .5;
      case AcaoAtor.entra || AcaoAtor.sai || AcaoAtor.anda || AcaoAtor.corre:
        agacha = 0;
        final corre = acao == AcaoAtor.corre;
        if (noCarro) {
          // sai/entra dirigindo: só o carro balança mais
          if (!reduzir) carroDy += math.sin(p * 10 * math.pi) * .008;
        } else {
          passo = reduzir ? 0 : math.sin(p * (corre ? 4 : 3) * 2 * math.pi);
          dy -= (corre ? .02 : .012) * passo.abs();
          if (corre) {
            if (!reduzir) rot = .12 * math.sin(math.pi * p).clamp(0.0, 1.0).toDouble();
            maoD = Offset(.17 + .03 * passo, .6 - .03 * passo);
            maoE = Offset(-.17 + .03 * passo, .6 + .03 * passo);
          } else {
            maoD = maoD + Offset(.03 * passo, -.03 * passo);
            maoE = maoE + Offset(.03 * passo, .03 * passo);
          }
        }
      case AcaoAtor.danca:
        agacha = 0;
        final s = reduzir ? .5 : math.sin(2 * math.pi * 1.5 * t);
        dx = .03 * s;
        rot = .07 * s;
        passo = .5 * s;
        maoD = Offset(.24, .36 + .12 * s);
        maoE = Offset(-.24, .36 - .12 * s);
      case AcaoAtor.treme:
        // ±2 px a 12 Hz (em px, não em H)
        if (!reduzir && altura > 0) dx = 2 / altura * math.sin(2 * math.pi * 12 * t);
        final e = _subida(p, .08);
        maoD = Offset.lerp(maoD, const Offset(.09, .6), e)!;
        maoE = Offset.lerp(maoE, const Offset(-.09, .6), e)!;
      case AcaoAtor.cai:
        // tomba 80° (0.3 s de 1.2), fica 0.4 s, levanta 0.5 s; estrelinhas
        final f = p < .25
            ? _suave(p / .25)
            : p < .583
                ? 1.0
                : 1 - _suave((p - .583) / .417);
        if (!reduzir) rot = -1.4 * f;
        estrelinhas = p > .2 && p < .95;
        maoD = Offset.lerp(maoD, const Offset(.3, .42), f)!;
        maoE = Offset.lerp(maoE, const Offset(-.3, .42), f)!;
      case AcaoAtor.abraca:
        final e = math.sin(math.pi * p);
        maoD = Offset.lerp(maoD, const Offset(.33, .5), e)!;
        maoE = Offset.lerp(maoE, const Offset(.18, .53), e)!;
      case AcaoAtor.pensa:
        final e = _subida(p, .1);
        maoD = Offset.lerp(maoD, const Offset(.05, .47), e)!;
        maoE = Offset.lerp(maoE, const Offset(.07, .62), e)!;
        olhar += Offset(.3, -.7) * e;
      case AcaoAtor.palmas:
        final e = _envelope(p, .1);
        final abre = reduzir ? .05 : .025 + .06 * (.5 + .5 * math.cos(p * 8 * math.pi));
        maoD = Offset.lerp(maoD, Offset(abre, .6), e)!;
        maoE = Offset.lerp(maoE, Offset(-abre, .6), e)!;
      case AcaoAtor.concorda:
        if (!reduzir) cabecaDy += .022 * (1 - math.cos(p * 6 * math.pi)) / 2;
      case AcaoAtor.nega:
        final s = reduzir ? 0.0 : math.sin(p * 6 * math.pi);
        cabecaDx += .025 * s;
        olhar += Offset(.8 * s, 0);
      case AcaoAtor.mostra:
        final e = _envelope(p, .15);
        maoD = Offset.lerp(maoD, const Offset(.24, .25), e)!;
        maoE = Offset.lerp(maoE, const Offset(-.22, .45), e * .5)!;
        if (e > .5) ondeProp = _OndeProp.acima;
      case AcaoAtor.dirige || AcaoAtor.desce:
        agacha = 0;
        // pulinho para dentro/para fora do carro
        if (!reduzir) dy -= .08 * math.sin(math.pi * p);
      case AcaoAtor.olha:
        olhar += Offset(.8 * _envelope(p, .3), 0);
      case AcaoAtor.arremessa:
        const atras = Offset(.1, .3), solta = Offset(.38, .42);
        if (p < .4) {
          maoD = Offset.lerp(idleD, atras, _suave(p / .4))!;
        } else if (p < .6) {
          maoD = Offset.lerp(atras, solta, _suave((p - .4) / .2))!;
        } else {
          maoD = Offset.lerp(solta, idleD, _suave((p - .6) / .4))!;
        }
        if (noCarro) maoD = Offset(maoD.dx, math.min(maoD.dy, .56));
      case AcaoAtor.escreve:
        caneta = true;
        ondeProp = _OndeProp.maoEsquerda;
        final rabisco = reduzir ? Offset.zero : Offset(.015 * math.sin(t * 13), .008 * math.cos(t * 9));
        maoD = const Offset(.08, .6) + rabisco;
        maoE = const Offset(-.04, .6);
      case AcaoAtor.rodopia:
        agacha = 0;
        pivo = const Offset(0, .55);
        if (!reduzir) rot = 2 * math.pi * _suave(p);
        estrelinhas = p > .2;
      case AcaoAtor.senta:
        if (!noCarro) agacha = reduzir ? 1 : _suave(p);
      case AcaoAtor.dorme:
        break;
    }

    if (dormindo) {
      cabecaDy += .025;
      balanco = .8;
      if (acao == AcaoAtor.parado || acao == AcaoAtor.dorme) {
        maoD = Offset.lerp(maoD, idleD + const Offset(-.015, .015), noCarro ? 0 : 1)!;
        maoE = Offset.lerp(maoE, idleE + const Offset(.015, .015), noCarro ? 0 : 1)!;
      }
    }
    // sentado: o corpo desce (as mãos vão junto; as pernas dobram)
    dy += .2 * agacha;
  }

  /// Agacha, sobe e aterrissa; devolve (altura 0..1, quanto está no ar 0..1).
  (double, double) _pulo(double p, bool reduzir, double altura) {
    if (reduzir) return (0, 0);
    if (p < .2) {
      escalaY = 1 - .1 * math.sin(math.pi * p / .2);
      return (0, 0);
    }
    if (p < .8) {
      final h = math.sin(math.pi * (p - .2) / .6);
      dy -= altura * h;
      escalaY = 1 + .05 * h;
      return (h, math.min(1.0, h * 1.6));
    }
    escalaY = 1 - .08 * math.sin(math.pi * (p - .8) / .2);
    return (0, 0);
  }

  /// A matriz do corpo (rotação + achatamento + deslocamento) na caixa de [w] × [h] px.
  Matrix4 matriz(double w, double h) {
    final piv = Offset(w / 2 + pivo.dx * h, pivo.dy * h);
    final pes = Offset(w / 2, h);
    return Matrix4.identity()
      ..translateByDouble(dx * h, 0, 0, 1)
      ..translateByDouble(piv.dx, piv.dy, 0, 1)
      ..rotateZ(rot)
      ..translateByDouble(-piv.dx, -piv.dy, 0, 1)
      ..translateByDouble(pes.dx, pes.dy, 0, 1)
      ..scaleByDouble(1 + (1 - escalaY) * .5, escalaY, 1, 1)
      ..translateByDouble(-pes.dx, -pes.dy, 0, 1);
  }
}

/// O cotovelo/joelho de um membro de dois segmentos de [l1] e [l2] indo de [a] até [b], dobrando para o lado
/// [lado] (+1 = para a direita / para fora). Se [b] estiver longe demais, o membro fica esticado na direção dele.
Offset _junta(Offset a, Offset b, double l1, double l2, double lado, {bool paraBaixo = false}) {
  final d = b - a;
  final dist = d.distance;
  if (dist < 1e-6) return a + Offset(lado * l1, 0);
  final u = d / dist;
  if (dist >= l1 + l2) return a + u * l1;
  final dd = math.max(dist, (l1 - l2).abs() + 1e-6);
  final x = (l1 * l1 - l2 * l2 + dd * dd) / (2 * dd);
  final h = math.sqrt(math.max(0, l1 * l1 - x * x));
  final base = a + u * x;
  final perp = Offset(-u.dy, u.dx);
  final c1 = base + perp * h, c2 = base - perp * h;
  if (paraBaixo) return c1.dy >= c2.dy ? c1 : c2;
  final s1 = c1.dx * lado, s2 = c2.dx * lado;
  if ((s1 - s2).abs() < 1e-9) return c1.dy >= c2.dy ? c1 : c2;
  return s1 > s2 ? c1 : c2;
}

/// 🧍 O corpo chibi do ator (tronco, braços, pernas, sapatos, jaleco, cachecol). [frente] = camada da frente
/// (braços, mãos, caneta); senão a de trás (pernas e tronco). A cabeça é o [RostoPersonagem], por cima da de trás.
class CorpoPainter extends CustomPainter {
  CorpoPainter({
    required this.aparencia,
    required this.pose,
    required this.frente,
    this.reduzir = false,
  });

  final Aparencia aparencia;
  final PoseAtor pose;
  final bool frente;
  final bool reduzir;

  late double _h, _cx, _cw;
  Offset _l(Offset o) => Offset(_cx + o.dx * _h, o.dy * _h);

  Color get _roupa => aparencia.jaleco ? Colors.white : aparencia.roupa;

  Paint _traco(Color cor, double largura) => Paint()
    ..color = cor
    ..style = PaintingStyle.stroke
    ..strokeWidth = largura
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    _h = size.height;
    _cx = size.width / 2;
    _cw = (_h * .012).clamp(1.2, 3.0);
    final q = _Quadro.de(pose, altura: _h, reduzir: reduzir);
    canvas.save();
    canvas.translate(0, q.dy * _h);
    if (frente) {
      _bracos(canvas, q);
    } else {
      if (!q.noCarro) _pernas(canvas, q);
      _tronco(canvas);
    }
    canvas.restore();
  }

  // ───────────────────────── pernas ─────────────────────────

  void _pernas(Canvas c, _Quadro q) {
    final larg = _h * .075;
    for (final lado in [-1.0, 1.0]) {
      final quadril = Offset(lado * _quadrilX, _quadrilY);
      // de pé: perna reta, a passada balança o pé; sentado: joelhos para fora e pés na frente (no chão)
      final passo = q.passo * lado;
      final pePe = Offset(lado * .07 + .06 * passo, .965 - .025 * math.max(0, passo));
      final peSentado = Offset(lado * .16, .79);
      final pe = Offset.lerp(pePe, peSentado, q.agacha)!;
      final joelhoPe = Offset.lerp(quadril, pePe, .5)!;
      final joelhoSentado = Offset(lado * .13, .7);
      final joelho = Offset.lerp(joelhoPe, joelhoSentado, q.agacha)!;
      final caminho = Path()
        ..moveTo(_l(quadril).dx, _l(quadril).dy)
        ..lineTo(_l(joelho).dx, _l(joelho).dy)
        ..lineTo(_l(pe).dx, _l(pe).dy);
      c.drawPath(caminho, _traco(_contorno, larg + _cw * 2));
      c.drawPath(caminho, _traco(_corPerna, larg));
      // sapato, apontando para a frente (direita)
      final sapato = Rect.fromCenter(center: _l(pe + const Offset(.015, .012)), width: _h * .095, height: _h * .05);
      c.drawOval(sapato.inflate(_cw), Paint()..color = _contorno);
      c.drawOval(sapato, Paint()..color = _corSapato);
      c.drawOval(
        Rect.fromCenter(center: sapato.center + Offset(-_h * .015, -_h * .01), width: _h * .03, height: _h * .012),
        Paint()..color = Colors.white.withValues(alpha: .25),
      );
    }
  }

  // ───────────────────────── tronco ─────────────────────────

  void _tronco(Canvas c) {
    final baixo = aparencia.jaleco ? .8 : .765;
    final tronco = Path()
      ..moveTo(_l(const Offset(-.15, .47)).dx, _l(const Offset(-.15, .47)).dy)
      ..lineTo(_l(const Offset(.15, .47)).dx, _l(const Offset(.15, .47)).dy)
      ..quadraticBezierTo(_cx + .17 * _h, (baixo - .1) * _h, _cx + .175 * _h, (baixo - .02) * _h)
      ..quadraticBezierTo(_cx + .175 * _h, baixo * _h, _cx + .15 * _h, baixo * _h)
      ..lineTo(_cx - .15 * _h, baixo * _h)
      ..quadraticBezierTo(_cx - .175 * _h, baixo * _h, _cx - .175 * _h, (baixo - .02) * _h)
      ..quadraticBezierTo(_cx - .17 * _h, (baixo - .1) * _h, _cx - .15 * _h, .47 * _h)
      ..close();
    c.drawPath(tronco, _traco(_contorno, _cw * 2));
    c.drawPath(tronco, Paint()..color = _roupa);
    // uma faixa de sombreamento (luz vem da esquerda)
    c.save();
    c.clipPath(tronco);
    c.drawRect(
      Rect.fromLTRB(_cx + .085 * _h, .4 * _h, _cx + .2 * _h, baixo * _h),
      Paint()..color = Color.lerp(_roupa, Colors.black, .12)!,
    );
    c.drawRect(
      Rect.fromLTRB(_cx - .2 * _h, (baixo - .035) * _h, _cx + .2 * _h, baixo * _h),
      Paint()..color = Color.lerp(_roupa, Colors.black, .18)!,
    );
    if (aparencia.jaleco) {
      // jaleco aberto na frente, bolso e a blusa por baixo
      c.drawRect(Rect.fromLTRB(_cx - .03 * _h, .46 * _h, _cx + .03 * _h, (baixo - .1) * _h), Paint()..color = aparencia.roupa);
      final linha = _traco(const Color(0xFFC9D1DA), _cw);
      c.drawLine(Offset(_cx - .03 * _h, .47 * _h), Offset(_cx - .03 * _h, baixo * _h), linha);
      c.drawLine(Offset(_cx + .03 * _h, .47 * _h), Offset(_cx + .03 * _h, baixo * _h), linha);
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(_cx - .13 * _h, .62 * _h, .07 * _h, .055 * _h),
          Radius.circular(_h * .01),
        ),
        linha,
      );
    }
    c.restore();
    _estampa(c);
  }

  /// Detalhes por personagem: cachecol do Ben, raio do Max, estrela do Team Star no aluno.
  void _estampa(Canvas c) {
    final d = aparencia.detalhe;
    if (aparencia.gorro && d != null) {
      // a ponta do cachecol caindo no peito
      final ponta = RRect.fromRectAndRadius(
        Rect.fromLTRB(_cx + .05 * _h, .5 * _h, _cx + .1 * _h, .66 * _h),
        Radius.circular(_h * .015),
      );
      c.drawRRect(ponta.inflate(_cw * .6), Paint()..color = _contorno);
      c.drawRRect(ponta, Paint()..color = d);
      final franja = _traco(Color.lerp(d, Colors.white, .3)!, _cw * .7);
      for (var i = 0; i < 3; i++) {
        final x = _cx + (.06 + i * .017) * _h;
        c.drawLine(Offset(x, .66 * _h), Offset(x, .685 * _h), franja);
      }
    }
    if (identical(aparencia, ElencoTurismo.max) && d != null) {
      // raio laranja do Team Thunder
      // (no lado direito do peito, longe do crachá que o rosto desenha no meio)
      final raio = Path()
        ..moveTo(_cx + .1 * _h, .6 * _h)
        ..lineTo(_cx + .05 * _h, .68 * _h)
        ..lineTo(_cx + .08 * _h, .68 * _h)
        ..lineTo(_cx + .06 * _h, .75 * _h)
        ..lineTo(_cx + .125 * _h, .655 * _h)
        ..lineTo(_cx + .095 * _h, .655 * _h)
        ..close();
      c.drawPath(raio, _traco(_contorno, _cw * 1.2));
      c.drawPath(raio, Paint()..color = d);
    }
    if (identical(aparencia, ElencoIngles.voce)) {
      // estrela branca do Team Star
      final estrela = _estrela(Offset(_cx - .085 * _h, .64 * _h), _h * .05);
      c.drawPath(estrela, _traco(_contorno, _cw));
      c.drawPath(estrela, Paint()..color = Colors.white);
    }
  }

  // ───────────────────────── braços ─────────────────────────

  void _bracos(Canvas c, _Quadro q) {
    final larg = _h * .07;
    final rMao = _h * .042;
    for (final lado in [-1.0, 1.0]) {
      final ombro = Offset(lado * _ombroX, _ombroY);
      final mao = lado > 0 ? q.maoD : q.maoE;
      final cotovelo = _junta(ombro, mao, _braco1, _braco2, lado);
      final pMao = _l(_alcance(ombro, mao));
      final caminho = Path()
        ..moveTo(_l(ombro).dx, _l(ombro).dy)
        ..lineTo(_l(cotovelo).dx, _l(cotovelo).dy)
        ..lineTo(pMao.dx, pMao.dy);
      c.drawPath(caminho, _traco(_contorno, larg + _cw * 2));
      c.drawPath(caminho, _traco(_roupa, larg));
      // punho da manga
      c.drawCircle(pMao, larg * .5, Paint()..color = Color.lerp(_roupa, Colors.black, .15)!);
      if (lado > 0 && q.dedo) {
        // dedo apontando, na direção do antebraço
        final dir = pMao - _l(cotovelo);
        final u = dir.distance < 1e-6 ? const Offset(1, 0) : dir / dir.distance;
        final ponta = pMao + u * (_h * .07);
        c.drawLine(pMao, ponta, _traco(_contorno, _h * .028 + _cw * 2));
        c.drawLine(pMao, ponta, _traco(aparencia.pele, _h * .028));
      }
      c.drawCircle(pMao, rMao + _cw, Paint()..color = _contorno);
      c.drawCircle(pMao, rMao, Paint()..color = aparencia.pele);
      if (lado > 0 && q.caneta) _caneta(c, pMao);
    }
  }

  /// A mão alcança o alvo ou fica esticada na direção dele.
  Offset _alcance(Offset ombro, Offset mao) {
    final d = mao - ombro;
    final max = _braco1 + _braco2;
    return d.distance <= max ? mao : ombro + d / d.distance * max;
  }

  /// Caneta (a Ana usa pincel, com a ponta molhada de tinta).
  void _caneta(Canvas c, Offset mao) {
    final pincel = identical(aparencia, ElencoIngles.ana);
    final ponta = mao + Offset(_h * .05, _h * .045);
    final cabo = mao + Offset(-_h * .03, -_h * .03);
    c.drawLine(cabo, ponta, _traco(_contorno, _h * .02 + _cw * 2));
    c.drawLine(cabo, ponta, _traco(pincel ? const Color(0xFFB07A4A) : const Color(0xFF3D6FD9), _h * .02));
    c.drawCircle(ponta, _h * .014, Paint()..color = pincel ? const Color(0xFFFF5D8F) : _contorno);
    c.drawCircle(mao, _h * .042, Paint()..color = aparencia.pele);
  }

  @override
  bool shouldRepaint(CorpoPainter old) =>
      old.aparencia != aparencia || old.pose != pose || old.frente != frente || old.reduzir != reduzir;
}

Path _estrela(Offset centro, double r, {int pontas = 5, double dentro = .45}) {
  final p = Path();
  for (var i = 0; i < pontas * 2; i++) {
    final raio = i.isEven ? r : r * dentro;
    final ang = -math.pi / 2 + i * math.pi / pontas;
    final pt = centro + Offset(math.cos(ang), math.sin(ang)) * raio;
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// ✨ Os extras da emoção em volta da cabeça: brilhos (radiante), lágrima (triste), veia 💢 (bravo), "…"
/// (pensativo), gota de suor (nervoso), "Z Z Z" (dormindo) e estrelinhas (tombo e rodopio).
///
/// Pinta na caixa do ator **sem espelho** (o texto do "Z" não vira ao contrário): [espelhado] só troca o lado.
/// [cabeca] = deslocamento da cabeça em px (o corpo e o balanço dela).
class EmotesPainter extends CustomPainter {
  EmotesPainter({
    required this.expressao,
    this.tempo = 0,
    this.dormindo = false,
    this.estrelinhas = false,
    this.espelhado = false,
    this.cabeca = Offset.zero,
    this.reduzir = false,
  });

  final Expressao expressao;
  final double tempo;
  final bool dormindo, estrelinhas, espelhado, reduzir;
  final Offset cabeca;

  /// Há algo a pintar?
  static bool temAlgo(Expressao e, {bool dormindo = false, bool estrelinhas = false}) =>
      dormindo ||
      estrelinhas ||
      const {Expressao.radiante, Expressao.triste, Expressao.bravo, Expressao.pensativo, Expressao.nervoso}
          .contains(e);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final h = size.height;
    final t = reduzir ? 0.0 : tempo;
    final lado = espelhado ? -1.0 : 1.0;
    final cw = (h * .01).clamp(1.0, 2.6);
    // centro da cabeça (o rosto é um quadrado de .58H centrado no alto da caixa)
    final hc = Offset(size.width / 2, .278 * h) + cabeca;
    final contorno = Paint()
      ..color = _contorno
      ..style = PaintingStyle.stroke
      ..strokeWidth = cw
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    switch (expressao) {
      case Expressao.radiante:
        for (var i = 0; i < 4; i++) {
          final ang = -math.pi + .35 + i * (math.pi - .7) / 3;
          final c = hc + Offset(math.cos(ang) * .25 * h, math.sin(ang) * .23 * h);
          final pisca = .7 + .3 * math.sin(t * 5 + i * 1.7);
          final p = _estrela(c, h * .035 * pisca, pontas: 4, dentro: .3);
          canvas.drawPath(p, Paint()..color = const Color(0xFFFFE066));
          canvas.drawPath(p, contorno..strokeWidth = cw * .6);
        }
      case Expressao.triste:
        // lágrima descendo do olho do lado do rosto
        final ciclo = (t / 1.4) % 1;
        final x = hc.dx + lado * .075 * h;
        final y = .33 * h + cabeca.dy + ciclo * .08 * h;
        final gota = _gota(Offset(x, y), h * .022);
        canvas.drawPath(gota, Paint()..color = const Color(0xFF6EC1FF).withValues(alpha: 1 - ciclo * .6));
        canvas.drawPath(gota, contorno..strokeWidth = cw * .5);
      case Expressao.bravo:
        // veia "💢" no canto da cabeça
        final c = hc + Offset(lado * .15 * h, -.13 * h);
        final r = h * .036;
        final veia = Paint()
          ..color = const Color(0xFFE53935)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.4, h * .011)
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final ang = math.pi / 4 + i * math.pi / 2;
          final u = Offset(math.cos(ang), math.sin(ang));
          final perp = Offset(-u.dy, u.dx);
          final a = c + u * r * .45 + perp * r * .55;
          final b = c + u * r * .45 - perp * r * .55;
          canvas.drawPath(
            Path()
              ..moveTo(a.dx, a.dy)
              ..quadraticBezierTo(c.dx + u.dx * r * 1.3, c.dy + u.dy * r * 1.3, b.dx, b.dy),
            veia,
          );
        }
      case Expressao.pensativo:
        // balãozinho com "…"
        final c = hc + Offset(lado * .22 * h, -.22 * h);
        final balao = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: .15 * h, height: .075 * h),
          Radius.circular(.0375 * h),
        );
        canvas.drawRRect(balao, Paint()..color = Colors.white);
        canvas.drawRRect(balao, contorno);
        for (final (k, r) in [(.55, .014), (.78, .009)]) {
          final b = Offset.lerp(c, hc + Offset(lado * .12 * h, -.12 * h), k)!;
          canvas.drawCircle(b, r * h, Paint()..color = Colors.white);
          canvas.drawCircle(b, r * h, contorno);
        }
        for (var i = -1; i <= 1; i++) {
          canvas.drawCircle(c + Offset(i * .035 * h, 0), .009 * h, Paint()..color = _contorno);
        }
      case Expressao.nervoso:
        final bob = math.sin(t * 4) * .006 * h;
        final gota = _gota(hc + Offset(lado * .17 * h, -.08 * h + bob), h * .026);
        canvas.drawPath(gota, Paint()..color = const Color(0xFF7FD4FF));
        canvas.drawPath(gota, contorno..strokeWidth = cw * .6);
      case Expressao.neutro ||
            Expressao.feliz ||
            Expressao.surpreso ||
            Expressao.timido ||
            Expressao.determinado ||
            Expressao.cansado:
        break;
    }

    if (dormindo) {
      final sobe = (t * .25) % 1;
      for (var i = 0; i < 3; i++) {
        final k = (sobe + i / 3) % 1;
        final c = hc + Offset(lado * (.14 + .06 * k + .02 * i) * h, -(.16 + .16 * k) * h);
        final s = h * (.03 + .02 * k);
        final z = Path()
          ..moveTo(c.dx - s / 2, c.dy - s / 2)
          ..lineTo(c.dx + s / 2, c.dy - s / 2)
          ..lineTo(c.dx - s / 2, c.dy + s / 2)
          ..lineTo(c.dx + s / 2, c.dy + s / 2);
        final alfa = reduzir ? 1.0 : (1 - k).clamp(.2, 1.0);
        canvas.drawPath(
          z,
          Paint()
            ..color = const Color(0xFF5B6BC9).withValues(alpha: alfa)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1.4, s * .2)
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }

    if (estrelinhas) {
      for (var i = 0; i < 3; i++) {
        final ang = t * 6 + i * 2 * math.pi / 3;
        final c = hc + Offset(math.cos(ang) * .17 * h, -.17 * h + math.sin(ang) * .04 * h);
        final p = _estrela(c, h * .028);
        canvas.drawPath(p, Paint()..color = const Color(0xFFFFD45C));
        canvas.drawPath(p, contorno..strokeWidth = cw * .6);
      }
    }
  }

  /// Uma gota com a ponta para cima, centrada em [c].
  Path _gota(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r * 1.6)
    ..quadraticBezierTo(c.dx + r * 1.1, c.dy - r * .2, c.dx + r, c.dy + r * .3)
    ..arcToPoint(Offset(c.dx - r, c.dy + r * .3), radius: Radius.circular(r))
    ..quadraticBezierTo(c.dx - r * 1.1, c.dy - r * .2, c.dx, c.dy - r * 1.6)
    ..close();

  @override
  bool shouldRepaint(EmotesPainter old) =>
      old.expressao != expressao ||
      old.tempo != tempo ||
      old.dormindo != dormindo ||
      old.estrelinhas != estrelinhas ||
      old.espelhado != espelhado ||
      old.cabeca != cabeca ||
      old.reduzir != reduzir;
}

/// A sombra elíptica no chão (não sobe com o pulo; encolhe).
class _SombraPainter extends CustomPainter {
  _SombraPainter({required this.largura, required this.altura, required this.dx});

  final double largura, altura, dx;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || largura <= 0) return;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2 + dx, size.height - size.height * .008),
        width: largura,
        height: altura,
      ),
      Paint()..color = Colors.black.withValues(alpha: .18),
    );
  }

  @override
  bool shouldRepaint(_SombraPainter old) => old.largura != largura || old.altura != altura || old.dx != dx;
}

/// 🧍 Um personagem de corpo inteiro no palco (caixa `.62 × altura` por `altura`).
///
/// Camadas: sombra no chão → corpo (pernas e tronco) → cabeça ([RostoPersonagem] com emoção, olhar e lip-sync)
/// → carro (se [PoseAtor.noCarro]; só o busto aparece) → braços e mãos → prop na mão → emotes da emoção.
/// O desenho olha para a direita; [espelhado] = olha para a esquerda. Pulos, quedas, braços esticados e o
/// carro podem passar da caixa (nada é cortado).
class AtorHistoria extends StatelessWidget {
  const AtorHistoria({
    super.key,
    required this.aparencia,
    required this.altura,
    required this.pose,
    this.visema = Visema.x,
    this.olhos = 1,
    this.expressao = Expressao.neutro,
    this.olhar = Offset.zero,
    this.espelhado = false,
    this.segura,
    this.carro,
    this.capitulo = 1,
    this.reduzir = false,
  });

  final Aparencia aparencia;
  final double altura;
  final PoseAtor pose;
  final Visema visema;

  /// 1 aberto, 0 fechado (piscada). Dormindo, os olhos ficam fechados de qualquer jeito.
  final double olhos;
  final Expressao expressao;
  final Offset olhar;
  final bool espelhado;

  /// O prop na mão (`nada`/null = mãos vazias).
  final PropHistoria? segura;

  /// Qual carro desenhar quando [PoseAtor.noCarro] (null → [PropHistoria.carro]); fora do carro é ignorado.
  final PropHistoria? carro;

  /// Capítulo (a pintura do carro muda com ele).
  final int capitulo;
  final bool reduzir;

  /// Largura da caixa do ator para a [altura].
  static double largura(double altura) => altura * .62;

  /// Ponto (relativo à caixa do ator, desenho sem espelho, de pé e parado) da boca, para o rabicho do balão.
  static Offset boca(double altura) => Offset(largura(altura) / 2, altura * _rosto * .67);

  /// Ponto (relativo à caixa do ator, desenho sem espelho, de pé e parado) da mão, para props e efeitos.
  /// Espelhado, use `largura(altura) - x`.
  static Offset mao(double altura, {bool direita = true}) =>
      Offset(largura(altura) / 2 + (direita ? 1 : -1) * _maoIdle.dx * altura, _maoIdle.dy * altura);

  /// O tamanho em que um prop aparece na mão (os grandes são reduzidos para caber).
  static Size tamanhoNaMao(PropHistoria p, double altura) {
    final s = PropPainter.tamanho(p, altura);
    final maior = math.max(s.width, s.height);
    final limite = altura * .3;
    return maior <= limite || maior == 0 ? s : s * (limite / maior);
  }

  @override
  Widget build(BuildContext context) {
    final h = altura.isFinite && altura > 0 ? altura : 0.0;
    final w = largura(h);
    final q = _Quadro.de(pose, altura: h, reduzir: reduzir);
    final lado = h * _rosto;
    final cabeca = Offset(q.cabecaDx * h, (q.dy + q.cabecaDy) * h);
    final fechados = q.dormindo ? 0.0 : olhos;

    Offset local(Offset o) => Offset(w / 2 + o.dx * h, (o.dy + q.dy) * h);

    final filhos = <Widget>[
      Positioned.fill(child: CustomPaint(painter: CorpoPainter(aparencia: aparencia, pose: pose, frente: false, reduzir: reduzir))),
      Positioned(
        left: (w - lado) / 2 + cabeca.dx,
        top: cabeca.dy,
        width: lado,
        height: lado,
        child: RostoPersonagem(
          aparencia: aparencia,
          tamanho: lado,
          visema: visema,
          olhos: fechados,
          balanco: q.balanco.clamp(-1.0, 1.0),
          expressao: expressao,
          olhar: olhar + q.olhar,
        ),
      ),
    ];

    if (q.noCarro) {
      final prop = carro ?? PropHistoria.carro;
      final s = PropPainter.tamanho(prop, h) * .8;
      filhos.add(Positioned(
        left: (w - s.width) / 2,
        top: h - s.height + q.carroDy * h,
        width: s.width,
        height: s.height,
        child: CustomPaint(painter: PropPainter(prop: prop, t: reduzir ? 0 : pose.tempo, capitulo: capitulo)),
      ));
    }

    final bracos = Positioned.fill(
      child: CustomPaint(painter: CorpoPainter(aparencia: aparencia, pose: pose, frente: true, reduzir: reduzir)),
    );
    // segurando, o prop fica na frente da mão; escrevendo, a mão com a caneta fica por cima dele
    final propAntes = q.ondeProp == _OndeProp.maoEsquerda;
    if (!propAntes) filhos.add(bracos);

    final prop = segura;
    if (prop != null && prop != PropHistoria.nada) {
      final s = tamanhoNaMao(prop, h);
      final centro = switch (q.ondeProp) {
        _OndeProp.maoDireita => local(q.maoD) + Offset(s.width * .2, -s.height * .15),
        _OndeProp.maoEsquerda => local(q.maoE) + Offset(s.width * .25, -s.height * .1),
        _OndeProp.acima => local(q.maoD) + Offset(0, -s.height * .45),
      };
      filhos.add(Positioned(
        left: centro.dx - s.width / 2,
        top: centro.dy - s.height / 2,
        width: s.width,
        height: s.height,
        child: CustomPaint(painter: PropPainter(prop: prop, t: reduzir ? 0 : pose.tempo, capitulo: capitulo)),
      ));
    }
    if (propAntes) filhos.add(bracos);

    final corpo = Transform.flip(
      flipX: espelhado,
      child: Stack(clipBehavior: Clip.none, children: filhos),
    );

    final temEmote = EmotesPainter.temAlgo(expressao, dormindo: q.dormindo, estrelinhas: q.estrelinhas);
    final noAr = (-(q.dy - .2 * q.agacha - (q.noCarro ? .12 + q.carroDy : 0))).clamp(0.0, .2);
    final larguraSombra = (q.noCarro ? .8 : .44) * h * (1 - noAr * 2.2);

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SombraPainter(largura: larguraSombra, altura: h * .06 * (1 - noAr * 2.2), dx: q.dx * h),
            ),
          ),
          Positioned.fill(
            child: Transform(
              transform: q.matriz(w, h),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: corpo),
                  if (temEmote)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: EmotesPainter(
                          expressao: expressao,
                          tempo: pose.tempo,
                          dormindo: q.dormindo,
                          estrelinhas: q.estrelinhas,
                          espelhado: espelhado,
                          cabeca: Offset(espelhado ? -cabeca.dx : cabeca.dx, cabeca.dy),
                          reduzir: reduzir,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
