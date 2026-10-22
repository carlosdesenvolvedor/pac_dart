import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/historia_turismo.dart';

/// As 3 camadas do fundo (a câmera e a paralaxe mexem em cada uma de um jeito).
enum CamadaFundo { ceu, distante, chao }

/// 🖼️ O fundo pintado de um cenário da história, com a paleta da hora.
///
/// Cada um dos 25 cenários é **uma** pintura em 3 camadas (não 100 quadros); a hora do dia entra como
/// paleta: o gradiente do céu, o astro (sol baixo no amanhecer e na tarde, alto no dia; lua e estrelas à
/// noite), uma "luz" que tinge tudo o que não emite luz e as luzes que acendem à tarde/noite (janelas,
/// postes, lanternas, holofotes, abajures). Nos interiores a hora muda a janela e a luz geral.
///
/// - [CamadaFundo.ceu]: opaca, cobre a tela inteira (vai atrás de tudo).
/// - [CamadaFundo.distante]: transparente acima das silhuetas (morros, prédios, serras…); nos interiores é a
///   parede, com as janelas vazadas para o céu.
/// - [CamadaFundo.chao]: do [horizonte] para baixo, mais os objetos de cena perto dos atores (cerca, tenda,
///   pódio, cama, balcão…). Cobre tudo da [linhaDoChao] para baixo.
///
/// [paralaxe] é o deslocamento horizontal da câmera em **larguras de tela** (0 = parado; pode ser negativo
/// ou passar de 1). Cada camada anda uma fração dele ([fatorParalaxe]: céu .1, distante .5, chão 1) e as
/// pinturas são periódicas na largura, então repetem sem emenda. [t] é o relógio do palco em segundos:
/// nuvens, ondas, fumaça, bandeira, público e luzes mexem devagar com ele; com [t] fixo o quadro fica
/// parado (reduzir animações). Sem `Random`: a mesma entrada pinta sempre igual.
///
/// Visual de desenho animado: preenchimentos chapados, contorno `0xFF3A2A33` (mais fino ao longe), uma faixa
/// de sombreamento por objeto. Cores fixas no desenho (nada de `Mixart` aqui).
class FundoHistoriaPainter extends CustomPainter {
  FundoHistoriaPainter({required this.cenario, required this.hora, required this.camada, this.t = 0, this.paralaxe = 0});

  final CenarioHistoria cenario;
  final HoraHistoria hora;
  final CamadaFundo camada;
  final double t, paralaxe;

  /// A linha do chão (0..1 da altura) onde os pés dos atores pisam, por cenário.
  static double linhaDoChao(CenarioHistoria c) => switch (c) {
        CenarioHistoria.hotel => .87,
        CenarioHistoria.aeroporto ||
        CenarioHistoria.garagem ||
        CenarioHistoria.cafe ||
        CenarioHistoria.clinica ||
        CenarioHistoria.estacao ||
        CenarioHistoria.podio =>
          .86,
        CenarioHistoria.cidade || CenarioHistoria.praia || CenarioHistoria.oasis || CenarioHistoria.autodromo => .85,
        CenarioHistoria.espaco => .83,
        _ => .84,
      };

  /// Onde o céu (ou a parede, nos interiores) encontra o chão, 0..1 da altura. Sempre acima da [linhaDoChao].
  static double horizonte(CenarioHistoria c) => switch (c) {
        CenarioHistoria.hotel || CenarioHistoria.clinica || CenarioHistoria.estacao => .66,
        CenarioHistoria.aeroporto || CenarioHistoria.garagem || CenarioHistoria.cafe => .64,
        CenarioHistoria.boxes || CenarioHistoria.praia || CenarioHistoria.vale || CenarioHistoria.autodromo => .58,
        CenarioHistoria.plataforma ||
        CenarioHistoria.deserto ||
        CenarioHistoria.cidade ||
        CenarioHistoria.vulcao ||
        CenarioHistoria.espaco ||
        CenarioHistoria.canion ||
        CenarioHistoria.lua ||
        CenarioHistoria.marte =>
          .62,
        _ => .60,
      };

  /// Quanto cada camada anda com [paralaxe] (o chão anda junto com a câmera; o céu quase não anda).
  static double fatorParalaxe(CamadaFundo c) => switch (c) {
        CamadaFundo.ceu => .1,
        CamadaFundo.distante => .5,
        CamadaFundo.chao => 1.0,
      };

  @override
  void paint(Canvas canvas, Size size) {
    if (!(size.width > 0 && size.height > 0) || !size.isFinite) return;
    final p = _Pincel(canvas, size, cenario, hora, t.isFinite ? t : 0);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (camada == CamadaFundo.ceu) _gradienteDoCeu(p);
    final desl = paralaxe.isFinite ? paralaxe * fatorParalaxe(camada) * size.width : 0.0;
    final dx = desl % size.width;
    // A pintura é periódica em [0, largura): com deslocamento, duas cópias lado a lado cobrem a tela, cada
    // uma recortada na sua faixa (sem antialias no recorte: nenhum pixel é pintado duas vezes na emenda).
    for (final x0 in dx == 0 ? const [0.0] : [0.0, size.width]) {
      canvas.save();
      if (dx != 0) {
        final emenda = size.width - dx;
        canvas.clipRect(
            x0 == 0 ? Rect.fromLTRB(0, 0, emenda, size.height) : Rect.fromLTRB(emenda, 0, size.width, size.height),
            doAntiAlias: false);
      }
      canvas.translate(x0 - dx, 0);
      switch (camada) {
        case CamadaFundo.ceu:
          _detalhesDoCeu(p);
        case CamadaFundo.distante:
          _distante(p);
        case CamadaFundo.chao:
          _chao(p);
      }
      canvas.restore();
    }
    canvas.restore();
  }

  void _distante(_Pincel p) {
    switch (cenario) {
      case CenarioHistoria.aeroporto:
        _dAeroporto(p);
      case CenarioHistoria.garagem:
        _dGaragem(p);
      case CenarioHistoria.boxes:
        _dBoxes(p);
      case CenarioHistoria.hotel:
        _dHotel(p);
      case CenarioHistoria.cafe:
        _dCafe(p);
      case CenarioHistoria.clinica:
        _dClinica(p);
      case CenarioHistoria.plataforma:
        _dPlataforma(p);
      case CenarioHistoria.podio:
        _dPodio(p);
      case CenarioHistoria.campina:
        _dCampina(p);
      case CenarioHistoria.deserto:
        _dDeserto(p);
      case CenarioHistoria.cidade:
        _dCidade(p);
      case CenarioHistoria.neve:
        _dNeve(p);
      case CenarioHistoria.vulcao:
        _dVulcao(p);
      case CenarioHistoria.espaco:
        _dEspaco(p);
      case CenarioHistoria.praia:
        _dPraia(p);
      case CenarioHistoria.ponte:
        _dPonte(p);
      case CenarioHistoria.canion:
        _dCanion(p);
      case CenarioHistoria.oasis:
        _dOasis(p);
      case CenarioHistoria.floresta:
        _dFloresta(p);
      case CenarioHistoria.vale:
        _dVale(p);
      case CenarioHistoria.lago:
        _dLago(p);
      case CenarioHistoria.lua:
        _dLua(p);
      case CenarioHistoria.marte:
        _dMarte(p);
      case CenarioHistoria.estacao:
        _dEstacao(p);
      case CenarioHistoria.autodromo:
        _dAutodromo(p);
    }
  }

  void _chao(_Pincel p) {
    switch (cenario) {
      case CenarioHistoria.aeroporto:
        _cAeroporto(p);
      case CenarioHistoria.garagem:
        _cGaragem(p);
      case CenarioHistoria.boxes:
        _cBoxes(p);
      case CenarioHistoria.hotel:
        _cHotel(p);
      case CenarioHistoria.cafe:
        _cCafe(p);
      case CenarioHistoria.clinica:
        _cClinica(p);
      case CenarioHistoria.plataforma:
        _cPlataforma(p);
      case CenarioHistoria.podio:
        _cPodio(p);
      case CenarioHistoria.campina:
        _cCampina(p);
      case CenarioHistoria.deserto:
        _cDeserto(p);
      case CenarioHistoria.cidade:
        _cCidade(p);
      case CenarioHistoria.neve:
        _cNeve(p);
      case CenarioHistoria.vulcao:
        _cVulcao(p);
      case CenarioHistoria.espaco:
        _cEspaco(p);
      case CenarioHistoria.praia:
        _cPraia(p);
      case CenarioHistoria.ponte:
        _cPonte(p);
      case CenarioHistoria.canion:
        _cCanion(p);
      case CenarioHistoria.oasis:
        _cOasis(p);
      case CenarioHistoria.floresta:
        _cFloresta(p);
      case CenarioHistoria.vale:
        _cVale(p);
      case CenarioHistoria.lago:
        _cLago(p);
      case CenarioHistoria.lua:
        _cLua(p);
      case CenarioHistoria.marte:
        _cMarte(p);
      case CenarioHistoria.estacao:
        _cEstacao(p);
      case CenarioHistoria.autodromo:
        _cAutodromo(p);
    }
  }

  @override
  bool shouldRepaint(FundoHistoriaPainter old) =>
      old.cenario != cenario || old.hora != hora || old.camada != camada || old.t != t || old.paralaxe != paralaxe;
}

// ═══════════════════════════════════════════ pincel e peças ═══════════════════════════════════════════

const _contorno = Color(0xFF3A2A33);
const _branco = Color(0xFFFFFFFF);
const _verdeArvore = Color(0xFF4F9A45);
const _verdePinheiro = Color(0xFF2F6B4A);
const _tronco = Color(0xFF7A5232);
const _metal = Color(0xFF8D99A8);
const _publico = [
  Color(0xFFE53935),
  Color(0xFFFFD54F),
  Color(0xFF1E88E5),
  Color(0xFF8E44AD),
  Color(0xFF43A047),
  Color(0xFFFF7043),
  Color(0xFFF5F5F5),
  Color(0xFF26C6DA),
];
const _outono = [Color(0xFFE5772E), Color(0xFFD2452B), Color(0xFFF2B33D), Color(0xFFB8432A)];

/// Hash determinístico 0..1 (sem `Random`: o quadro é função só da entrada).
double _ruido(int i) {
  final v = math.sin(i * 12.9898 + 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

/// A "luz" da hora: cor para onde tudo que não emite luz é puxado, e quanto.
(Color, double) _luzDa(HoraHistoria h, CenarioHistoria c) {
  if (c == CenarioHistoria.estacao) return (const Color(0xFF0E2238), .2);
  if (c == CenarioHistoria.espaco || c == CenarioHistoria.lua) return (const Color(0xFF151B45), .3);
  final dentro = interioresHistoria.contains(c);
  return switch (h) {
    HoraHistoria.amanhecer => (const Color(0xFFFF9E80), dentro ? .07 : .14),
    HoraHistoria.dia => (_branco, 0.0),
    HoraHistoria.tarde => (const Color(0xFFFF7043), dentro ? .1 : .2),
    HoraHistoria.noite => c == CenarioHistoria.vulcao
        ? (const Color(0xFF2E0E16), .5)
        : dentro
            ? (const Color(0xFF2A2344), .26)
            : (const Color(0xFF0F1940), .55),
  };
}

/// O que todas as pinturas usam: tela, medidas (u = 1% da altura), a luz da hora e as formas básicas.
class _Pincel {
  _Pincel(this.c, this.s, this.cenario, this.hora, this.t)
      : hz = s.height * FundoHistoriaPainter.horizonte(cenario),
        pe = s.height * FundoHistoriaPainter.linhaDoChao(cenario),
        u = s.height / 100,
        k = (s.height / 540).clamp(.7, 2.2).toDouble(),
        _luz = _luzDa(hora, cenario);

  final Canvas c;
  final Size s;
  final CenarioHistoria cenario;
  final HoraHistoria hora;
  final double t;

  /// Horizonte e linha dos pés, em px.
  final double hz, pe;

  /// 1% da altura e a escala do contorno.
  final double u, k;
  final (Color, double) _luz;

  double get w => s.width;
  double get h => s.height;
  bool get noite => hora == HoraHistoria.noite;

  /// Lâmpadas acesas (tarde e noite).
  bool get acesas => hora == HoraHistoria.noite || hora == HoraHistoria.tarde;

  Color luz(Color base) => _luz.$2 == 0 ? base : Color.lerp(base, _luz.$1, _luz.$2)!;

  Paint tinta(Color base, {bool emite = false, double alfa = 1}) {
    final cor = emite ? base : luz(base);
    return Paint()..color = alfa >= 1 ? cor : cor.withValues(alpha: cor.a * alfa.clamp(0, 1));
  }

  Paint traco([double largura = 1]) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2 * k * largura
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round
    ..color = _contorno;

  void forma(Path path, Color cor, {double contorno = 1, bool emite = false, double alfa = 1}) {
    c.drawPath(path, tinta(cor, emite: emite, alfa: alfa));
    if (contorno > 0) c.drawPath(path, traco(contorno));
  }

  void ret(Rect r, Color cor, {double contorno = 1, double raio = 0, bool emite = false, double alfa = 1}) => forma(
      Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(raio))), cor,
      contorno: contorno, emite: emite, alfa: alfa);

  void circ(Offset o, double r, Color cor, {double contorno = 1, bool emite = false, double alfa = 1}) =>
      forma(Path()..addOval(Rect.fromCircle(center: o, radius: r)), cor, contorno: contorno, emite: emite, alfa: alfa);

  /// Várias elipses que viram UMA forma (copa, nuvem, moita): contorno largo por baixo, recheio por cima.
  void blob(List<Rect> ovais, Color cor, {double contorno = 1, double sombra = .14, bool emite = false, double alfa = 1}) {
    final path = Path();
    for (final o in ovais) {
      path.addOval(o);
    }
    if (contorno > 0) c.drawPath(path, traco(contorno * 2));
    c.drawPath(path, tinta(cor, emite: emite, alfa: alfa));
    if (sombra > 0) {
      final b = path.getBounds();
      this.sombra(path, Rect.fromLTRB(b.left, b.top + b.height * .62, b.right, b.bottom), alfa: sombra);
    }
  }

  /// Traços grossos com contorno (troncos, postes, cabos, braços de cacto): borda por baixo, cor por cima.
  void tubos(List<Path> caminhos, double largura, Color cor, {double contorno = 1, bool emite = false}) {
    if (contorno > 0) {
      final borda = traco()..strokeWidth = largura + 4 * k * contorno;
      for (final cam in caminhos) {
        c.drawPath(cam, borda);
      }
    }
    final miolo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = largura
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = emite ? cor : luz(cor);
    for (final cam in caminhos) {
      c.drawPath(cam, miolo);
    }
  }

  /// Faixa horizontal da largura toda (sem bordas verticais, para não marcar a emenda da paralaxe).
  void faixa(double y0, double y1, Color cor, {double contorno = 1, bool emite = false, bool baixo = true, double alfa = 1}) {
    c.drawRect(Rect.fromLTRB(-2, y0, w + 2, y1), tinta(cor, emite: emite, alfa: alfa));
    if (contorno > 0) {
      final tr = traco(contorno);
      c.drawLine(Offset(-2, y0), Offset(w + 2, y0), tr);
      if (baixo) c.drawLine(Offset(-2, y1), Offset(w + 2, y1), tr);
    }
  }

  void degrade(Rect r, List<Color> cores, {List<double>? paradas, bool emite = false}) => c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [for (final x in cores) emite ? x : luz(x)],
            stops: paradas,
          ).createShader(r),
      );

  /// O chão de [de] (padrão: o horizonte) até embaixo, com a linha do horizonte.
  void solo(List<Color> cores, {double? de, double contorno = .5}) {
    final y = de ?? hz;
    degrade(Rect.fromLTRB(-2, y, w + 2, h + 1), cores);
    if (contorno > 0) c.drawLine(Offset(-2, y), Offset(w + 2, y), traco(contorno));
  }

  /// Faixa de sombreamento recortada pela forma.
  void sombra(Path forma, Rect faixa, {double alfa = .14}) {
    c.save();
    c.clipPath(forma);
    c.drawRect(faixa, Paint()..color = Color.fromRGBO(30, 14, 40, alfa));
    c.restore();
  }

  /// Halo radial (luz que emite; não é tingido pela hora).
  void brilho(Offset o, double r, Color cor, {double alfa = .5}) {
    if (!(r > 0)) return;
    c.drawCircle(
      o,
      r,
      Paint()
        ..shader = RadialGradient(colors: [cor.withValues(alpha: alfa.clamp(0, 1)), cor.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: o, radius: r)),
    );
  }

  /// Desenha em [x] e, se passar da borda, também do outro lado (a pintura fecha o ciclo na largura).
  void laco(double x, double meia, void Function(double x) f) {
    f(x);
    if (x - meia < 0) f(x + w);
    if (x + meia > w) f(x - w);
  }

  /// Quantas repetições de mais ou menos [passo] px cabem na largura (mínimo 1).
  int vezes(double passo) => math.max(1, (w / math.max(passo, 1)).round());

  /// Idem, sempre par (listras alternadas fecham o ciclo sem duas cores iguais na emenda).
  int vezesPar(double passo) => math.max(2, (w / math.max(passo, 1) / 2).round() * 2);
}

/// Silhueta ondulada periódica na largura (morros, dunas): soma de senos com nº inteiro de ciclos.
class _Onda {
  _Onda(this.p, this.base, this.amp, List<(double, double, double)> ondas, {this.fase = 0})
      : _ondas = [for (final (ciclos, peso, f) in ondas) (math.max(1, (ciclos * p.w / p.h).round()), peso, f)],
        _soma = ondas.fold(0.0, (a, o) => a + o.$2);

  final _Pincel p;
  final double base, amp, fase;
  final List<(int, double, double)> _ondas;
  final double _soma;

  double y(double x) {
    var v = 0.0;
    for (final (n, peso, f) in _ondas) {
      v += peso * (.5 + .5 * math.sin(2 * math.pi * n * x / p.w + f + fase));
    }
    return base - amp * v / _soma;
  }

  Path topo() {
    final passo = math.max(3.0, p.w / 160);
    final path = Path()..moveTo(-2, y(-2));
    for (var x = passo; x < p.w + 2; x += passo) {
      path.lineTo(x, y(x));
    }
    return path..lineTo(p.w + 2, y(p.w + 2));
  }

  Path corpo(double fundo) => Path.from(topo())
    ..lineTo(p.w + 2, fundo)
    ..lineTo(-2, fundo)
    ..close();

  void pinta(Color cor, {required double fundo, double contorno = .6, bool emite = false, double alfa = 1}) {
    p.c.drawPath(corpo(fundo), p.tinta(cor, emite: emite, alfa: alfa));
    if (contorno > 0) p.c.drawPath(topo(), p.traco(contorno));
  }

  void pintaDegrade(List<Color> cores, {required double fundo, double contorno = .6}) {
    final path = corpo(fundo);
    p.c.save();
    p.c.clipPath(path);
    p.degrade(Rect.fromLTRB(-2, base - amp, p.w + 2, fundo), cores);
    p.c.restore();
    if (contorno > 0) p.c.drawPath(topo(), p.traco(contorno));
  }
}

/// Serra com picos (periódica): devolve a borda de cima e, para cada pico, (pico, vale da esquerda, ombro).
(Path, List<(Offset, Offset, Offset)>) _serra(_Pincel p, double base, double alt, int n, int semente) {
  final passo = p.w / n;
  Offset vale(int i) => Offset(i * passo, base - alt * (.1 + .16 * _ruido(semente + (i % n) * 5)));
  final topo = Path()..moveTo(-2, vale(0).dy);
  final picos = <(Offset, Offset, Offset)>[];
  for (var i = 0; i < n; i++) {
    final a = vale(i), b = vale(i + 1);
    final pico = Offset((i + .32 + .3 * _ruido(semente + i * 5 + 2)) * passo,
        base - alt * (.62 + .38 * _ruido(semente + i * 5 + 3)));
    final ombro = Offset((pico.dx + b.dx) / 2 + passo * .04, (pico.dy + b.dy) / 2 - alt * .07 * _ruido(semente + i * 5 + 4));
    topo
      ..lineTo(pico.dx, pico.dy)
      ..lineTo(ombro.dx, ombro.dy)
      ..lineTo(b.dx, b.dy);
    picos.add((pico, a, ombro));
  }
  topo.lineTo(p.w + 2, vale(n).dy);
  return (topo, picos);
}

/// Pinta uma serra: corpo, encosta sombreada, (neve nos picos) e o contorno de cima.
void _pintaSerra(_Pincel p, double base, double alt, int n, int semente, Color cor,
    {double neve = 0, double contorno = .5, double fundo = 0}) {
  final (topo, picos) = _serra(p, base, alt, n, semente);
  final yFundo = fundo == 0 ? base + 3 * p.u : fundo;
  final corpo = Path.from(topo)
    ..lineTo(p.w + 2, yFundo)
    ..lineTo(-2, yFundo)
    ..close();
  p.c.drawPath(corpo, p.tinta(cor));
  p.c.save();
  p.c.clipPath(corpo);
  final escuro = Paint()..color = const Color(0x24301A40);
  for (final (pico, _, ombro) in picos) {
    // encosta da direita na sombra
    p.c.drawPath(
        Path()
          ..moveTo(pico.dx, pico.dy)
          ..lineTo(ombro.dx, ombro.dy)
          ..lineTo(ombro.dx + (ombro.dx - pico.dx), yFundo)
          ..lineTo(pico.dx, yFundo)
          ..close(),
        escuro);
    if (neve > 0) {
      final e = Offset.lerp(pico, Offset(pico.dx - (ombro.dx - pico.dx) * 1.2, ombro.dy), (neve / (ombro.dy - pico.dy + 1)).clamp(.2, .8))!;
      final d = Offset.lerp(pico, ombro, (neve / (ombro.dy - pico.dy + 1)).clamp(.2, .8))!;
      final cap = Path()
        ..moveTo(pico.dx, pico.dy - 2)
        ..lineTo(d.dx, d.dy);
      const m = 4;
      for (var j = 1; j < m; j++) {
        final q = Offset.lerp(d, e, j / m)!;
        cap.lineTo(q.dx, q.dy + (j.isOdd ? -neve * .3 : neve * .12));
      }
      cap
        ..lineTo(e.dx, e.dy)
        ..close();
      p.forma(cap, const Color(0xFFF7FBFF), contorno: .4);
    }
  }
  p.c.restore();
  p.c.drawPath(topo, p.traco(contorno));
}

void _arvore(_Pincel p, double x, double base, double alt, {Color copa = _verdeArvore, double contorno = 1}) {
  final tr = alt * .13;
  p.ret(Rect.fromLTWH(x - tr / 2, base - alt * .44, tr, alt * .44), _tronco, contorno: contorno);
  final r = alt * .3;
  p.blob([
    Rect.fromCircle(center: Offset(x, base - alt * .66), radius: r),
    Rect.fromCircle(center: Offset(x - r * .66, base - alt * .5), radius: r * .72),
    Rect.fromCircle(center: Offset(x + r * .66, base - alt * .52), radius: r * .76),
  ], copa, contorno: contorno);
  p.c.drawCircle(Offset(x - r * .35, base - alt * .76), r * .32, Paint()..color = const Color(0x33FFFFFF));
}

void _pinheiro(_Pincel p, double x, double base, double alt,
    {Color cor = _verdePinheiro, bool neve = false, double contorno = 1}) {
  final tr = alt * .1;
  p.ret(Rect.fromLTWH(x - tr / 2, base - alt * .2, tr, alt * .2), _tronco, contorno: contorno);
  for (var i = 0; i < 3; i++) {
    final yb = base - alt * (.14 + i * .24);
    final larg = alt * (.62 - i * .14);
    final topo = yb - alt * (i == 2 ? .5 : .4);
    final tri = Path()
      ..moveTo(x - larg / 2, yb)
      ..lineTo(x, topo)
      ..lineTo(x + larg / 2, yb)
      ..close();
    p.forma(tri, cor, contorno: contorno);
    p.sombra(tri, Rect.fromLTRB(x, topo, x + larg, yb), alfa: .12);
    if (neve) {
      final f = .45;
      final yN = topo + (yb - topo) * f;
      final cap = Path()
        ..moveTo(x, topo)
        ..lineTo(x + larg * f / 2, yN)
        ..lineTo(x + larg * f / 4, yN - alt * .03)
        ..lineTo(x, yN + alt * .02)
        ..lineTo(x - larg * f / 4, yN - alt * .03)
        ..lineTo(x - larg * f / 2, yN)
        ..close();
      p.forma(cap, const Color(0xFFF7FBFF), contorno: contorno * .6);
    }
  }
}

void _palmeira(_Pincel p, double x, double base, double alt, {double inclina = .18, double contorno = 1}) {
  final topo = Offset(x + alt * inclina, base - alt);
  final tronco = Path()
    ..moveTo(x, base)
    ..quadraticBezierTo(x + alt * inclina * .1, base - alt * .55, topo.dx, topo.dy);
  p.tubos([tronco], alt * .07, const Color(0xFFB0834F), contorno: contorno);
  final aneis = Paint()
    ..color = p.luz(const Color(0xFF8A6238))
    ..strokeWidth = alt * .012;
  for (var i = 1; i < 6; i++) {
    final s = i / 6;
    final px = (1 - s) * (1 - s) * x + 2 * (1 - s) * s * (x + alt * inclina * .1) + s * s * topo.dx;
    final py = (1 - s) * (1 - s) * base + 2 * (1 - s) * s * (base - alt * .55) + s * s * topo.dy;
    p.c.drawLine(Offset(px - alt * .032, py), Offset(px + alt * .032, py - alt * .01), aneis);
  }
  for (var i = 0; i < 6; i++) {
    final ang = -math.pi / 2 + (i - 2.5) * .62 + math.sin(p.t * 1.2 + i) * .04;
    final comp = alt * (.42 + .08 * (i % 2));
    final ponta = topo + Offset(math.cos(ang) * comp, math.sin(ang) * comp * .55 + comp * .38);
    final meio = topo + Offset(math.cos(ang) * comp * .5, math.sin(ang) * comp * .5 - comp * .1);
    final dir = ponta - topo;
    final n = Offset(-dir.dy, dir.dx) / math.max(dir.distance, 1) * comp * .13;
    final folha = Path()
      ..moveTo(topo.dx, topo.dy)
      ..quadraticBezierTo(meio.dx + n.dx, meio.dy + n.dy, ponta.dx, ponta.dy)
      ..quadraticBezierTo(meio.dx - n.dx, meio.dy - n.dy, topo.dx, topo.dy)
      ..close();
    p.forma(folha, i.isEven ? const Color(0xFF3E9A4A) : const Color(0xFF4FB05A), contorno: contorno * .8);
  }
  for (var i = 0; i < 3; i++) {
    p.circ(topo + Offset((i - 1) * alt * .035, alt * .03), alt * .028, const Color(0xFF6B4A2A), contorno: contorno * .5);
  }
}

void _cacto(_Pincel p, double x, double base, double alt, {double contorno = 1}) {
  final lw = alt * .2;
  final corpo = Path()
    ..moveTo(x, base)
    ..lineTo(x, base - alt + lw / 2);
  final bracoE = Path()
    ..moveTo(x, base - alt * .42)
    ..lineTo(x - lw * 1.3, base - alt * .42)
    ..lineTo(x - lw * 1.3, base - alt * .72);
  final bracoD = Path()
    ..moveTo(x, base - alt * .52)
    ..lineTo(x + lw * 1.25, base - alt * .52)
    ..lineTo(x + lw * 1.25, base - alt * .8);
  p.tubos([bracoE, bracoD, corpo], lw, const Color(0xFF4E9A4E), contorno: contorno);
  final risca = Paint()
    ..color = p.luz(const Color(0xFF3B7A3E))
    ..strokeWidth = math.max(1, lw * .08);
  p.c.drawLine(Offset(x - lw * .18, base - alt * .1), Offset(x - lw * .18, base - alt * .85), risca);
  p.c.drawLine(Offset(x + lw * .18, base - alt * .1), Offset(x + lw * .18, base - alt * .85), risca);
}

void _nuvem(_Pincel p, double x, double y, double r, Color cor, double alfa) {
  final path = Path()
    ..addOval(Rect.fromCenter(center: Offset(x, y), width: r * 4.2, height: r * 1.5))
    ..addOval(Rect.fromCircle(center: Offset(x - r * .9, y - r * .35), radius: r * .85))
    ..addOval(Rect.fromCircle(center: Offset(x + r * .3, y - r * .7), radius: r * 1.1))
    ..addOval(Rect.fromCircle(center: Offset(x + r * 1.3, y - r * .2), radius: r * .7));
  p.c.drawPath(path, Paint()..color = cor.withValues(alpha: alfa));
  p.c.save();
  p.c.clipPath(path);
  p.c.drawRect(Rect.fromLTRB(x - r * 2.2, y + r * .15, x + r * 2.2, y + r), Paint()..color = const Color(0x1C3A2A55));
  p.c.restore();
}

void _nuvens(_Pincel p, Color cor, {double alfa = .92, double qtd = 1, int semente = 0}) {
  final u = p.u;
  final n = math.max(2, (p.vezes(46 * u) * qtd).round());
  final topo = 5 * u;
  final fundo = math.max(topo + 4 * u, p.hz - 24 * u);
  for (var i = 0; i < n; i++) {
    final r = (3 + 2.8 * _ruido(semente + i * 7 + 1)) * u;
    final vel = (.25 + .45 * _ruido(semente + i * 7 + 2)) * u;
    final x = ((i + .6 * _ruido(semente + i * 7 + 3)) / n * p.w + p.t * vel) % p.w;
    final y = topo + (fundo - topo) * _ruido(semente + i * 7 + 4);
    p.laco(x, r * 2.4, (x) => _nuvem(p, x, y, r, cor, alfa));
  }
}

void _estrelas(_Pincel p, double densidade, {double? ate}) {
  final limite = ate ?? p.hz;
  final n = ((p.w / p.u) * (limite / p.u) / 14 * densidade).round().clamp(12, 520);
  final paint = Paint();
  final cruz = Paint()
    ..strokeWidth = .8 * p.k
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < n; i++) {
    final x = _ruido(i * 3 + 101) * p.w;
    final y = _ruido(i * 3 + 102) * limite * .97;
    final b = _ruido(i * 3 + 103);
    final pisca = .55 + .45 * math.sin(p.t * (1.2 + b * 2) + i);
    final r = (b > .93 ? 1.5 : b > .7 ? 1.0 : .65) * p.k;
    paint.color = Color.fromRGBO(255, 250, 232, (.3 + .65 * pisca * (.45 + b * .55)).clamp(0, 1));
    p.c.drawCircle(Offset(x, y), r, paint);
    if (b > .975) {
      final l = r * 3.4 * pisca;
      cruz.color = paint.color;
      p.c.drawLine(Offset(x - l, y), Offset(x + l, y), cruz);
      p.c.drawLine(Offset(x, y - l), Offset(x, y + l), cruz);
    }
  }
}

void _sol(_Pincel p, Offset o, double r, Color cor, Color halo) {
  p.laco(o.dx, r * 3.4, (x) {
    final c = Offset(x, o.dy);
    p.brilho(c, r * 3.4, halo, alfa: .5);
    p.c.drawCircle(c, r, Paint()..color = cor);
    p.c.drawCircle(c.translate(-r * .25, -r * .25), r * .55, Paint()..color = const Color(0x40FFFFFF));
  });
}

void _lua(_Pincel p, Offset o, double r) {
  p.laco(o.dx, r * 3, (x) {
    final c = Offset(x, o.dy);
    p.brilho(c, r * 3, const Color(0xFFDDE6FF), alfa: .28);
    p.c.drawCircle(c, r, Paint()..color = const Color(0xFFF3EFD8));
    final cratera = Paint()..color = const Color(0xFFDCD5B8);
    p.c.drawCircle(c.translate(-r * .3, -r * .2), r * .22, cratera);
    p.c.drawCircle(c.translate(r * .35, r * .1), r * .16, cratera);
    p.c.drawCircle(c.translate(-r * .05, r * .45), r * .12, cratera);
  });
}

/// A Terra vista de fora (lua, estação orbital).
void _terra(_Pincel p, Offset o, double r) {
  p.laco(o.dx, r * 1.6, (x) {
    final c = Offset(x, o.dy);
    p.brilho(c, r * 1.5, const Color(0xFF7FC8FF), alfa: .45);
    final disco = Path()..addOval(Rect.fromCircle(center: c, radius: r));
    p.c.drawCircle(
        c,
        r,
        Paint()
          ..shader = const RadialGradient(center: Alignment(-.3, -.3), colors: [Color(0xFF4DA3F0), Color(0xFF1D5FB0)])
              .createShader(Rect.fromCircle(center: c, radius: r)));
    p.c.save();
    p.c.clipPath(disco);
    final verde = Paint()..color = const Color(0xFF55A85A);
    p.c.drawOval(Rect.fromCenter(center: c.translate(-r * .35, -r * .15), width: r * .9, height: r * .7), verde);
    p.c.drawOval(Rect.fromCenter(center: c.translate(r * .3, r * .35), width: r * .6, height: r * .8), verde);
    p.c.drawOval(Rect.fromCenter(center: c.translate(r * .55, -r * .45), width: r * .45, height: r * .3), verde);
    final nuvem = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .1
      ..strokeCap = StrokeCap.round;
    p.c.drawArc(Rect.fromCircle(center: c.translate(-r * .1, r * .1), radius: r * .7), -.4, 1.4, false, nuvem);
    p.c.drawArc(Rect.fromCircle(center: c.translate(r * .2, -r * .3), radius: r * .5), 2.4, 1.2, false, nuvem);
    // lado da noite
    p.c.drawCircle(c.translate(r * .55, r * .3), r * 1.05, Paint()..color = const Color(0x660A1030));
    p.c.restore();
    p.c.drawPath(disco, p.traco(.6));
  });
}

void _nebulosa(_Pincel p) {
  final u = p.u;
  final n = p.vezes(70 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .3) / n * p.w;
    p.laco(x, 44 * u, (x) {
      p.brilho(Offset(x, 26 * u), 34 * u, const Color(0xFF7A3FD0), alfa: .22);
      p.brilho(Offset(x + 18 * u, 40 * u), 24 * u, const Color(0xFF1FB5C9), alfa: .14);
    });
  }
}

void _planetaComAnel(_Pincel p, Offset o, double r) {
  p.laco(o.dx, r * 1.8, (x) {
    final c = Offset(x, o.dy);
    final anel = Rect.fromCenter(center: c, width: r * 3.4, height: r * .9);
    final tr = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * .16
      ..color = const Color(0xFFE6C98A);
    p.c.save();
    p.c.translate(c.dx, c.dy);
    p.c.rotate(-.25);
    p.c.translate(-c.dx, -c.dy);
    p.c.drawArc(anel, math.pi, math.pi, false, tr);
    p.c.restore();
    p.c.drawCircle(
        c,
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2B27A), Color(0xFFD9825A), Color(0xFFF0C08E), Color(0xFFB8664A)],
            stops: [0, .4, .6, 1],
          ).createShader(Rect.fromCircle(center: c, radius: r)));
    p.c.drawCircle(c, r, p.traco(.5));
    p.c.save();
    p.c.translate(c.dx, c.dy);
    p.c.rotate(-.25);
    p.c.translate(-c.dx, -c.dy);
    p.c.drawArc(anel, 0, math.pi, false, tr);
    p.c.restore();
  });
}

void _poste(_Pincel p, double x, double base, double alt, {bool aceso = false, Color luz = const Color(0xFFFFE08A)}) {
  final cabeca = Offset(x + alt * .16, base - alt);
  if (aceso) {
    p.c.drawPath(
        Path()
          ..moveTo(cabeca.dx - alt * .04, cabeca.dy)
          ..lineTo(cabeca.dx + alt * .04, cabeca.dy)
          ..lineTo(cabeca.dx + alt * .22, base)
          ..lineTo(cabeca.dx - alt * .22, base)
          ..close(),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [luz.withValues(alpha: .28), luz.withValues(alpha: 0)],
          ).createShader(Rect.fromLTRB(cabeca.dx - alt * .22, cabeca.dy, cabeca.dx + alt * .22, base)));
  }
  p.tubos([
    Path()
      ..moveTo(x, base)
      ..lineTo(x, base - alt)
      ..lineTo(cabeca.dx, cabeca.dy)
  ], math.max(1.5, alt * .035), const Color(0xFF4A5060));
  p.ret(Rect.fromCenter(center: cabeca.translate(0, alt * .02), width: alt * .1, height: alt * .04),
      aceso ? luz : const Color(0xFFCFD6DE),
      contorno: .7, emite: aceso, raio: alt * .02);
  if (aceso) p.brilho(cabeca.translate(0, alt * .04), alt * .3, luz, alfa: .45);
}

void _pneus(_Pincel p, double x, double base, double r, int n, {double contorno = 1}) {
  for (var i = 0; i < n; i++) {
    final y = base - r * .45 - i * r * .8;
    final fora = Rect.fromCenter(center: Offset(x, y), width: r * 2.2, height: r * .9);
    p.forma(Path()..addRRect(RRect.fromRectAndRadius(fora, Radius.circular(r * .4))), const Color(0xFF2E2E34),
        contorno: contorno);
    p.c.drawOval(Rect.fromCenter(center: Offset(x, y - r * .08), width: r * 1.1, height: r * .3),
        p.tinta(const Color(0xFF15151A)));
    p.c.drawLine(Offset(x - r * .8, y - r * .28), Offset(x - r * .2, y - r * .32),
        Paint()
          ..color = const Color(0x44FFFFFF)
          ..strokeWidth = r * .08
          ..strokeCap = StrokeCap.round);
  }
}

/// Arquibancada com público (pontinhos coloridos que balançam).
void _arquibancada(_Pincel p, double x0, double x1, double topo, double base,
    {int fileiras = 4, bool cobertura = true, bool inteira = false, double contorno = .6}) {
  final u = p.u;
  final alt = (base - topo) / fileiras;
  for (var j = 0; j < fileiras; j++) {
    final r = Rect.fromLTRB(x0, topo + j * alt, x1, topo + (j + 1) * alt);
    p.c.drawRect(r, p.tinta(j.isEven ? const Color(0xFF6A7290) : const Color(0xFF58607C)));
    final passo = 1.5 * u;
    final n = math.max(1, ((x1 - x0) / passo).floor());
    final cabeca = Paint();
    for (var i = 0; i < n; i++) {
      final sem = j * 977 + i;
      if (_ruido(sem) < .12) continue;
      final pula = _ruido(sem + 3) > .8 ? math.max(0.0, math.sin(p.t * 5 + i * .7)) * .5 * u : 0.0;
      final x = x0 + (i + .5) * (x1 - x0) / n;
      final y = r.top + alt * .45 - pula;
      cabeca.color = p.luz(_publico[(sem * 7 + j) % _publico.length]);
      p.c.drawRect(Rect.fromCenter(center: Offset(x, y + alt * .25), width: passo * .7, height: alt * .4), cabeca);
      cabeca.color = p.luz(const Color(0xFFE0B48A));
      p.c.drawCircle(Offset(x, y - alt * .08), alt * .16, cabeca);
    }
    p.c.drawLine(Offset(x0, r.bottom), Offset(x1, r.bottom), p.traco(contorno * .6));
  }
  final tr = p.traco(contorno);
  p.c.drawLine(Offset(x0, topo), Offset(x1, topo), tr);
  if (!inteira) {
    p.c.drawLine(Offset(x0, topo), Offset(x0, base), tr);
    p.c.drawLine(Offset(x1, topo), Offset(x1, base), tr);
  }
  if (cobertura) {
    final teto = topo - 4 * u;
    if (inteira) {
      p.faixa(teto, teto + 1.6 * u, const Color(0xFFE4E7EC), contorno: contorno);
    } else {
      p.ret(Rect.fromLTRB(x0 - u, teto, x1 + u, teto + 1.6 * u), const Color(0xFFE4E7EC), contorno: contorno);
    }
    final n = math.max(2, ((x1 - x0) / (14 * u)).round());
    for (var i = 0; i <= n; i++) {
      final x = x0 + (x1 - x0) * i / n;
      if (inteira && i == n) break;
      p.c.drawLine(Offset(x, teto + 1.6 * u), Offset(x, topo), p.traco(contorno * .8));
    }
  }
}

/// Pista de corrida vista de lado: asfalto, faixa tracejada e zebra embaixo.
void _pista(_Pincel p, double y0, double y1, {Color asfalto = const Color(0xFF8A8D95), bool zebra = true}) {
  final u = p.u;
  p.faixa(y0, y1, asfalto);
  final n = p.vezes(9 * u);
  final passo = p.w / n;
  final ym = (y0 + y1) / 2;
  final tr = p.tinta(_branco, alfa: .85);
  for (var i = 0; i < n; i++) {
    p.c.drawRect(Rect.fromLTWH(i * passo + passo * .2, ym - .3 * u, passo * .45, .6 * u), tr);
  }
  if (zebra) {
    final m = p.vezesPar(3 * u);
    final pz = p.w / m;
    for (var i = 0; i < m; i++) {
      p.c.drawRect(Rect.fromLTWH(i * pz, y1 - 1.2 * u, pz + .5, 1.2 * u),
          p.tinta(i.isEven ? const Color(0xFFE53935) : const Color(0xFFF5F5F5)));
    }
    p.c.drawLine(Offset(-2, y1 - 1.2 * u), Offset(p.w + 2, y1 - 1.2 * u), p.traco(.4));
    p.c.drawLine(Offset(-2, y1), Offset(p.w + 2, y1), p.traco(.6));
  }
}

void _cerca(_Pincel p, double base, double alt, Color cor) {
  final u = p.u;
  final tabua = alt * .16;
  for (final f in [.32, .68]) {
    p.faixa(base - alt * f - tabua / 2, base - alt * f + tabua / 2, cor, contorno: .5);
  }
  final n = p.vezes(8 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) * p.w / n;
    p.ret(Rect.fromLTWH(x - tabua * .6, base - alt, tabua * 1.2, alt), cor, contorno: .6, raio: tabua * .3);
  }
}

void _tufos(_Pincel p, double y0, double y1, Color cor, {bool flores = false, int semente = 0}) {
  final n = p.vezes(3.2 * p.u) * 2;
  final tr = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .4 * p.u
    ..strokeCap = StrokeCap.round
    ..color = p.luz(cor);
  const cores = [Color(0xFFFFFFFF), Color(0xFFFFD54F), Color(0xFFF48FB1), Color(0xFFB39DDB)];
  for (var i = 0; i < n; i++) {
    final x = _ruido(semente + i * 5 + 1) * p.w;
    final y = y0 + (y1 - y0) * _ruido(semente + i * 5 + 2);
    final a = (1 + 1.2 * _ruido(semente + i * 5 + 3)) * p.u * (.6 + .6 * (y - y0) / math.max(1, y1 - y0));
    p.c.drawLine(Offset(x, y), Offset(x - a * .35, y - a), tr);
    p.c.drawLine(Offset(x, y), Offset(x, y - a * 1.2), tr);
    p.c.drawLine(Offset(x, y), Offset(x + a * .35, y - a), tr);
    if (flores && i % 3 == 0) p.circ(Offset(x + a * .2, y - a * 1.3), .5 * p.u, cores[i % 4], contorno: .3);
  }
}

/// Pedrinhas/rochas espalhadas numa faixa do chão.
void _pedras(_Pincel p, double y0, double y1, Color cor, {double tam = 1, int semente = 0, double densidade = 1}) {
  final n = (p.vezes(9 * p.u) * densidade).round();
  for (var i = 0; i < n; i++) {
    final x = _ruido(semente + i * 3 + 1) * p.w;
    final y = y0 + (y1 - y0) * _ruido(semente + i * 3 + 2);
    final r = (.5 + 1.2 * _ruido(semente + i * 3 + 3)) * p.u * tam * (.7 + .5 * (y - y0) / math.max(1, y1 - y0));
    p.laco(x, r * 1.6, (x) {
      p.blob([
        Rect.fromCenter(center: Offset(x, y - r * .4), width: r * 2.4, height: r * 1.3),
        Rect.fromCenter(center: Offset(x + r * .4, y - r * .7), width: r * 1.4, height: r * 1.1),
      ], cor, contorno: .5, sombra: .2);
    });
  }
}

/// Mesa rochosa (butte) de topo reto, com estratos.
void _mesa(_Pincel p, double x, double base, double larg, double alt, Color cor, {double contorno = .6}) {
  final topo = base - alt;
  final path = Path()
    ..moveTo(x - larg * .5, base)
    ..lineTo(x - larg * .38, topo + alt * .28)
    ..lineTo(x - larg * .3, topo)
    ..lineTo(x + larg * .27, topo)
    ..lineTo(x + larg * .35, topo + alt * .32)
    ..lineTo(x + larg * .5, base)
    ..close();
  p.forma(path, cor, contorno: contorno);
  p.c.save();
  p.c.clipPath(path);
  final faixa = Paint()..color = p.luz(Color.lerp(cor, const Color(0xFF7A3A20), .22)!);
  for (var i = 1; i < 4; i++) {
    final y = topo + alt * i / 4.2;
    p.c.drawRect(Rect.fromLTRB(x - larg, y, x + larg, y + alt * .06), faixa);
  }
  p.c.drawRect(Rect.fromLTRB(x + larg * .12, topo, x + larg, base), Paint()..color = const Color(0x22301020));
  p.c.restore();
}

/// Algarismo 1, 2 ou 3 em traço (pódio), dentro de [caixa].
Path _algarismo(int n, Rect caixa) {
  Offset m(double a, double b) => Offset(caixa.left + a * caixa.width, caixa.top + b * caixa.height);
  final path = Path();
  void mv(double a, double b) => path.moveTo(m(a, b).dx, m(a, b).dy);
  void ln(double a, double b) => path.lineTo(m(a, b).dx, m(a, b).dy);
  void cb(double a, double b, double c, double d, double e, double f) =>
      path.cubicTo(m(a, b).dx, m(a, b).dy, m(c, d).dx, m(c, d).dy, m(e, f).dx, m(e, f).dy);
  switch (n) {
    case 1:
      mv(.3, .25);
      ln(.55, .05);
      ln(.55, .95);
    case 2:
      mv(.2, .3);
      cb(.2, -.02, .82, -.02, .8, .3);
      cb(.78, .52, .4, .66, .2, .95);
      ln(.84, .95);
    default:
      mv(.22, .15);
      cb(.5, -.05, .86, .1, .76, .33);
      cb(.7, .47, .56, .5, .45, .5);
      cb(.96, .5, .92, 1.02, .5, .97);
      cb(.36, .96, .26, .9, .2, .84);
  }
  return path;
}

// ═══════════════════════════════════════════ céu ═══════════════════════════════════════════

List<Color> _coresDoCeu(CenarioHistoria c, HoraHistoria h) {
  if (espaciaisHistoria.contains(c)) return const [Color(0xFF03040B), Color(0xFF0A0F26), Color(0xFF1B2050)];
  if (c == CenarioHistoria.marte) {
    return switch (h) {
      HoraHistoria.amanhecer => const [Color(0xFF4E3F6E), Color(0xFF9E8AA8), Color(0xFFBFD3E6)],
      HoraHistoria.dia => const [Color(0xFFCF8A6E), Color(0xFFE9AE8C), Color(0xFFF6D2B4)],
      HoraHistoria.tarde => const [Color(0xFF3E3560), Color(0xFF8C7C9E), Color(0xFFA9C4DE)],
      HoraHistoria.noite => const [Color(0xFF0E0712), Color(0xFF22101C), Color(0xFF3E1E26)],
    };
  }
  var cores = switch (h) {
    HoraHistoria.amanhecer => const [Color(0xFF6FA8E8), Color(0xFFBCC9EC), Color(0xFFFFC9A0)],
    HoraHistoria.dia => const [Color(0xFF4FA8F0), Color(0xFF8FCBF7), Color(0xFFD4EEFF)],
    HoraHistoria.tarde => const [Color(0xFF5B3F9A), Color(0xFFC0607A), Color(0xFFFFA054)],
    HoraHistoria.noite => const [Color(0xFF070D26), Color(0xFF121B45), Color(0xFF2A3466)],
  };
  Color mistura(Color a, Color alvo, double f) => Color.lerp(a, alvo, f)!;
  final noite = h == HoraHistoria.noite;
  switch (c) {
    case CenarioHistoria.vulcao:
      cores = [
        mistura(cores[0], const Color(0xFF5A2A30), .25),
        mistura(cores[1], const Color(0xFFE0603A), .3),
        mistura(cores[2], noite ? const Color(0xFFB0381E) : const Color(0xFFFF7A44), .5),
      ];
    case CenarioHistoria.deserto ||
          CenarioHistoria.canion ||
          CenarioHistoria.oasis ||
          CenarioHistoria.plataforma ||
          CenarioHistoria.praia:
      if (!noite) cores = [cores[0], cores[1], mistura(cores[2], const Color(0xFFFFE6B8), .35)];
    case CenarioHistoria.neve || CenarioHistoria.lago || CenarioHistoria.vale:
      if (!noite) cores = [cores[0], cores[1], mistura(cores[2], const Color(0xFFF2F8FF), .35)];
    case CenarioHistoria.cidade || CenarioHistoria.autodromo || CenarioHistoria.podio:
      if (noite) cores = [cores[0], cores[1], const Color(0xFF4B3C7A)];
    default:
  }
  return cores;
}

void _gradienteDoCeu(_Pincel p) {
  final ate = math.max(p.hz, p.h * .5);
  p.c.drawRect(
    Offset.zero & p.s,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: _coresDoCeu(p.cenario, p.hora),
        stops: const [0, .55, 1],
      ).createShader(Rect.fromLTWH(0, 0, p.w, ate)),
  );
}

void _detalhesDoCeu(_Pincel p) {
  final c = p.cenario, u = p.u;
  if (espaciaisHistoria.contains(c)) {
    _nebulosa(p);
    _estrelas(p, 1.5, ate: p.h * .8);
    if (c == CenarioHistoria.espaco) {
      _planetaComAnel(p, Offset(p.w * .22, 20 * u), 8 * u);
      p.circ(Offset(p.w * .7, 11 * u), 2.4 * u, const Color(0xFFE57373), contorno: .4);
    } else {
      _terra(p, Offset(p.w * .74, 20 * u), (c == CenarioHistoria.lua ? 9 : 12) * u);
    }
    return;
  }
  if (c == CenarioHistoria.marte) {
    if (p.noite) {
      _estrelas(p, .8);
    } else {
      final dia = p.hora == HoraHistoria.dia;
      final x = p.hora == HoraHistoria.amanhecer ? .24 : (dia ? .62 : .76);
      _sol(p, Offset(p.w * x, dia ? 14 * u : p.hz - 14 * u), 2.4 * u, const Color(0xFFF4F8FF),
          dia ? const Color(0xFFFFE0C0) : const Color(0xFF9FC4F0));
    }
    // as duas luazinhas de Marte, sempre lá
    p.circ(Offset(p.w * .34, 12 * u), 1.5 * u, const Color(0xFFBFA79A), contorno: .4);
    p.circ(Offset(p.w * .56, 21 * u), 1.0 * u, const Color(0xFFA8968A), contorno: .4);
    return;
  }
  final seco = c == CenarioHistoria.deserto ||
      c == CenarioHistoria.canion ||
      c == CenarioHistoria.oasis ||
      c == CenarioHistoria.plataforma;
  final qtd = seco ? .5 : 1.0;
  Color nuvem(Color base) => c == CenarioHistoria.vulcao ? Color.lerp(base, const Color(0xFF9A8A88), .55)! : base;
  switch (p.hora) {
    case HoraHistoria.amanhecer:
      _sol(p, Offset(p.w * .2, p.hz - 10 * u), 7 * u, const Color(0xFFFFD27F), const Color(0xFFFFB380));
      _nuvens(p, nuvem(const Color(0xFFFFE6DA)), qtd: qtd);
    case HoraHistoria.dia:
      _sol(p, Offset(p.w * .8, 13 * u), 5.5 * u, const Color(0xFFFFF4B0), const Color(0xFFFFFBE0));
      _nuvens(p, nuvem(_branco), qtd: qtd);
    case HoraHistoria.tarde:
      _sol(p, Offset(p.w * .78, p.hz - 9 * u), 8.5 * u, const Color(0xFFFF9248), const Color(0xFFFF7A50));
      _nuvens(p, nuvem(const Color(0xFFFFC6A8)), qtd: qtd);
    case HoraHistoria.noite:
      _estrelas(p, 1);
      _lua(p, Offset(p.w * .8, 14 * u), 5 * u);
      _nuvens(p, nuvem(const Color(0xFF3B4677)), alfa: .55, qtd: .5);
  }
}

// ═══════════════════════════════════════════ exteriores ═══════════════════════════════════════════

void _dCampina(_Pincel p) {
  final u = p.u;
  final longe = _Onda(p, p.hz - 3 * u, 11 * u, const [(.8, 1.0, 0.0), (2.2, .45, 1.3)]);
  longe.pinta(const Color(0xFFA9D08C), fundo: p.hz + 2 * u, contorno: .4);
  final n = p.vezes(6 * u);
  for (var i = 0; i < n; i++) {
    if (_ruido(i * 11 + 5) < .45) continue;
    final x = (i + .5) / n * p.w;
    p.blob([Rect.fromCircle(center: Offset(x, longe.y(x) - 1.1 * u), radius: 1.4 * u)], const Color(0xFF6FA35A),
        contorno: .3, sombra: 0);
  }
  final perto = _Onda(p, p.hz - .5 * u, 5 * u, const [(1.3, 1.0, 2.2), (3.1, .35, .4)]);
  perto.pinta(const Color(0xFF86BF6E), fundo: p.hz + 2 * u, contorno: .6);
  final m = p.vezes(24 * u);
  for (var i = 0; i < m; i++) {
    final x = (i + .3 + .4 * _ruido(i * 7 + 1)) / m * p.w;
    final alt = (9 + 5 * _ruido(i * 7 + 2)) * u;
    p.laco(x, alt * .5, (x) => _arvore(p, x, perto.y(x) + .8 * u, alt, contorno: .7));
  }
}

void _cCampina(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF7DBE66), Color(0xFF5A9A4C)]);
  _pista(p, p.hz + 3 * u, p.hz + 10 * u);
  _cerca(p, p.hz + 17 * u, 5 * u, const Color(0xFFF2E6D2));
  _tufos(p, p.hz + 19 * u, p.h, const Color(0xFF4E8A42), flores: true);
}

void _dDeserto(_Pincel p) {
  final u = p.u;
  _Onda(p, p.hz - 1 * u, 5 * u, const [(.7, 1.0, .8), (1.9, .5, 2.0)])
      .pinta(const Color(0xFFF0CF98), fundo: p.hz + 2 * u, contorno: .4);
  p.laco(p.w * .7, 16 * u, (x) => _mesa(p, x, p.hz, 30 * u, 15 * u, const Color(0xFFCB7A4A)));
  p.laco(p.w * .22, 9 * u, (x) => _mesa(p, x, p.hz, 17 * u, 8 * u, const Color(0xFFD9925E), contorno: .5));
  final perto = _Onda(p, p.hz + .5 * u, 3 * u, const [(1.4, 1.0, 0.0), (3.3, .4, 1.0)]);
  perto.pinta(const Color(0xFFE5BC80), fundo: p.hz + 2 * u, contorno: .5);
  final n = p.vezes(30 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .45) / n * p.w;
    p.laco(x, 2 * u, (x) => _cacto(p, x, perto.y(x) + .5 * u, 5 * u, contorno: .4));
  }
}

void _cDeserto(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFEBC68C), Color(0xFFD7A766)]);
  _pista(p, p.hz + 3 * u, p.hz + 9 * u, asfalto: const Color(0xFF9C9088));
  final risco = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .35 * u
    ..strokeCap = StrokeCap.round
    ..color = p.luz(const Color(0x66FFF1D0));
  final n = p.vezes(7 * u);
  for (var i = 0; i < n; i++) {
    final x = _ruido(i * 4 + 31) * p.w;
    final y = p.hz + (12 + 22 * _ruido(i * 4 + 32)) * u;
    final a = (2 + 2 * _ruido(i * 4 + 33)) * u;
    p.c.drawPath(
        Path()
          ..moveTo(x - a, y)
          ..quadraticBezierTo(x, y - a * .35, x + a, y),
        risco);
  }
  _pedras(p, p.hz + 12 * u, p.h, const Color(0xFFB98A5A), semente: 7, densidade: .5);
  final m = p.vezes(50 * u);
  for (var i = 0; i < m; i++) {
    p.laco((i + .1) / m * p.w, 6 * u, (x) => _cacto(p, x, p.hz + 20 * u, 18 * u));
    p.laco((i + .62) / m * p.w, 3 * u, (x) => _cacto(p, x, p.hz + 13 * u, 9 * u, contorno: .8));
  }
}

void _dCidade(_Pincel p) {
  final u = p.u;
  final n = p.vezes(6 * u);
  final longe = p.tinta(const Color(0xFFA2B3CC));
  final janelinha = Paint()..color = const Color(0xCCFFE08A);
  for (var i = 0; i < n; i++) {
    final larg = p.w / n;
    final alt = (12 + 16 * _ruido(i * 13 + 3)) * u;
    final r = Rect.fromLTWH(i * larg, p.hz - alt, larg * .94 + 1, alt + 1);
    p.c.drawRect(r, longe);
    if (p.noite) {
      for (var j = 0; j < 4; j++) {
        if (_ruido(i * 31 + j) > .55) {
          p.c.drawRect(Rect.fromLTWH(r.left + larg * .3, r.top + (2 + j * 3) * u, larg * .25, .9 * u), janelinha);
        }
      }
    }
  }
  const cores = [Color(0xFF6C7A96), Color(0xFF8A7A9E), Color(0xFF5E8A9A), Color(0xFF9A8676)];
  final m = p.vezes(14 * u);
  for (var i = 0; i < m; i++) {
    final passo = p.w / m;
    final larg = passo * (.68 + .25 * _ruido(i * 7 + 1));
    final alt = (14 + 20 * _ruido(i * 7 + 2)) * u;
    final x = i * passo + (passo - larg) / 2;
    _predio(p, Rect.fromLTWH(x, p.hz - alt + .5 * u, larg, alt), cores[i % 4], semente: i);
  }
}

void _predio(_Pincel p, Rect r, Color cor, {required int semente}) {
  final u = p.u;
  final corpo = Path()..addRect(r);
  p.forma(corpo, cor, contorno: .7);
  p.sombra(corpo, Rect.fromLTRB(r.right - r.width * .2, r.top, r.right, r.bottom), alfa: .16);
  final cols = math.max(2, (r.width / (3.4 * u)).floor());
  final lins = math.max(2, ((r.height - 3 * u) / (4.2 * u)).floor());
  final jw = r.width / cols * .52, jh = 2.2 * u;
  final acesa = Paint()..color = const Color(0xFFFFD866);
  final apagada = p.tinta(p.noite ? const Color(0xFF2A3346) : const Color(0xFFA9D2F2));
  for (var i = 0; i < cols; i++) {
    for (var j = 0; j < lins; j++) {
      final x = r.left + (i + .24) * r.width / cols;
      final y = r.top + 2 * u + j * 4.2 * u;
      if (y + jh > r.bottom - u) continue;
      final ligada = p.noite && _ruido(semente * 131 + i * 17 + j * 7) > .42;
      p.c.drawRect(Rect.fromLTWH(x, y, jw, jh), ligada ? acesa : apagada);
    }
  }
  if (_ruido(semente * 3 + 9) > .5) {
    final ax = r.left + r.width * .7;
    p.c.drawLine(Offset(ax, r.top), Offset(ax, r.top - 5 * u), p.traco(.6));
    final pisca = (p.t * 1.2 + semente) % 2 < 1;
    if (p.noite && pisca) p.brilho(Offset(ax, r.top - 5 * u), 1.6 * u, const Color(0xFFFF3B30), alfa: .9);
  } else {
    p.ret(Rect.fromLTWH(r.left + r.width * .2, r.top - 3 * u, r.width * .25, 3 * u), const Color(0xFF8A6A50),
        contorno: .5, raio: .6 * u);
  }
}

void _cCidade(_Pincel p) {
  final u = p.u;
  p.faixa(p.hz, p.hz + 5 * u, const Color(0xFFBDBDC6), contorno: .6);
  final junta = p.traco(.3);
  final n = p.vezes(6 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, p.hz), Offset(x - u, p.hz + 5 * u), junta);
  }
  p.faixa(p.hz + 5 * u, p.hz + 6.2 * u, const Color(0xFF8E8E98), contorno: .6);
  p.degrade(Rect.fromLTRB(-2, p.hz + 6.2 * u, p.w + 2, p.h + 1), const [Color(0xFF555A66), Color(0xFF3E424C)]);
  final amarelo = p.tinta(const Color(0xFFF2C94C));
  final m = p.vezes(10 * u);
  for (var i = 0; i < m; i++) {
    p.c.drawRect(Rect.fromLTWH(i * p.w / m, p.hz + 12 * u, p.w / m * .5, .6 * u), amarelo);
  }
  p.laco(p.w * .5, 15 * u, (x) {
    final listra = p.tinta(_branco, alfa: .85);
    for (var i = 0; i < 6; i++) {
      final x0 = x - 13 * u + i * 4.6 * u;
      p.c.drawPath(
          Path()
            ..moveTo(x0, p.hz + 7.5 * u)
            ..lineTo(x0 + 2.4 * u, p.hz + 7.5 * u)
            ..lineTo(x0 + 2.4 * u + (x0 - x) * .08, p.h + 1)
            ..lineTo(x0 + (x0 - x) * .08 - .4 * u, p.h + 1)
            ..close(),
          listra);
    }
  });
  final k = p.vezes(40 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .22) / k * p.w, 6 * u, (x) => _poste(p, x, p.hz + 4 * u, 26 * u, aceso: p.acesas));
  }
}

void _dNeve(_Pincel p) {
  final u = p.u;
  _pintaSerra(p, p.hz + 1 * u, 30 * u, p.vezes(34 * u), 3, const Color(0xFF9AAFC8), neve: 9 * u, contorno: .4);
  _pintaSerra(p, p.hz + 1 * u, 15 * u, p.vezes(22 * u), 17, const Color(0xFF7F96B2), neve: 4.5 * u);
  final n = p.vezes(7 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5 * _ruido(i * 5 + 77)) / n * p.w;
    p.laco(x, 3 * u, (x) => _pinheiro(p, x, p.hz + 1.5 * u, (5 + 3 * _ruido(i * 5 + 78)) * u,
        neve: true, contorno: .45, cor: const Color(0xFF2F5D4A)));
  }
}

void _cNeve(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFF4F8FC), Color(0xFFD9E6F2)]);
  _pista(p, p.hz + 3 * u, p.hz + 9 * u, asfalto: const Color(0xFF8C95A2));
  final n = p.vezes(7 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) / n * p.w;
    for (final y in [p.hz + 3 * u, p.hz + 9.3 * u]) {
      p.laco(x, 3 * u, (x) => p.blob([
            Rect.fromCenter(center: Offset(x, y), width: (4 + 2 * _ruido(i * 3 + y.round())) * u, height: 1.6 * u),
          ], const Color(0xFFF7FBFF), contorno: .4, sombra: .08));
    }
  }
  final azul = p.tinta(const Color(0x30648CC8));
  final m = p.vezes(14 * u);
  for (var i = 0; i < m; i++) {
    final x = _ruido(i * 5 + 51) * p.w;
    final y = p.hz + (13 + 20 * _ruido(i * 5 + 52)) * u;
    p.c.drawOval(Rect.fromCenter(center: Offset(x, y), width: (6 + 6 * _ruido(i * 5 + 53)) * u, height: 1.2 * u), azul);
  }
  final k = p.vezes(40 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .08) / k * p.w, 8 * u, (x) => _pinheiro(p, x, p.hz + 21 * u, 24 * u, neve: true));
    p.laco((i + .9) / k * p.w, 5 * u, (x) => _pinheiro(p, x, p.hz + 16 * u, 15 * u, neve: true, contorno: .8));
  }
}

void _dVulcao(_Pincel p) {
  final u = p.u;
  _Onda(p, p.hz - 2 * u, 7 * u, const [(.9, 1.0, .3), (2.4, .4, 1.1)])
      .pinta(const Color(0xFF5A4440), fundo: p.hz + 2 * u, contorno: .4);
  p.laco(p.w * .62, 36 * u, (x) => _vulcao(p, x));
  _Onda(p, p.hz + .5 * u, 4 * u, const [(1.6, 1.0, 2.0), (3.4, .4, .3)])
      .pinta(const Color(0xFF3E2C2A), fundo: p.hz + 2 * u, contorno: .5);
}

void _vulcao(_Pincel p, double x) {
  final u = p.u;
  final base = p.hz + 1 * u, topo = math.max(4 * u, p.hz - 32 * u), boca = 5 * u;
  final cone = Path()
    ..moveTo(x - 34 * u, base)
    ..quadraticBezierTo(x - 12 * u, base - 10 * u, x - boca, topo)
    ..lineTo(x + boca, topo)
    ..quadraticBezierTo(x + 12 * u, base - 10 * u, x + 34 * u, base)
    ..close();
  p.forma(cone, const Color(0xFF6A4A44), contorno: .7);
  p.sombra(cone, Rect.fromLTRB(x + 2 * u, topo, x + 40 * u, base), alfa: .2);
  final pulso = .75 + .25 * math.sin(p.t * 2.2);
  p.brilho(Offset(x, topo), 14 * u, const Color(0xFFFF6A1A), alfa: .55 * pulso);
  p.c.save();
  p.c.clipPath(cone);
  final lava = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4 * u
    ..strokeCap = StrokeCap.round
    ..color = Color.lerp(const Color(0xFFFF7A1A), const Color(0xFFFFC14A), pulso * .5)!;
  p.c.drawPath(
      Path()
        ..moveTo(x - 1.5 * u, topo)
        ..quadraticBezierTo(x - 6 * u, topo + 10 * u, x - 4 * u, topo + 18 * u)
        ..quadraticBezierTo(x - 3 * u, topo + 24 * u, x - 9 * u, base - 2 * u),
      lava);
  p.c.drawPath(
      Path()
        ..moveTo(x + 2 * u, topo)
        ..quadraticBezierTo(x + 5 * u, topo + 9 * u, x + 9 * u, topo + 15 * u),
      lava..strokeWidth = 1 * u);
  p.c.restore();
  p.c.drawOval(Rect.fromCenter(center: Offset(x, topo), width: boca * 2.2, height: 1.6 * u),
      Paint()..color = const Color(0xFFFF8A2A));
  for (var i = 0; i < 6; i++) {
    final fase = (p.t * .12 + i / 6) % 1.0;
    final r = (2.5 + fase * 6) * u;
    final dx = math.sin(fase * 3 + i) * 3 * u + fase * 8 * u;
    p.blob([Rect.fromCircle(center: Offset(x + dx, topo - 2 * u - fase * 26 * u), radius: r)], const Color(0xFF8F8486),
        contorno: 0, sombra: 0, alfa: .75 * (1 - fase));
  }
}

void _cVulcao(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF55403A), Color(0xFF3A2A26)]);
  _pista(p, p.hz + 3 * u, p.hz + 9 * u, asfalto: const Color(0xFF4F494C));
  final pulso = .7 + .3 * math.sin(p.t * 2.2 + 1);
  final n = p.vezes(30 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .3 * _ruido(i * 9 + 3)) / n * p.w;
    final y = p.hz + (14 + 14 * _ruido(i * 9 + 4)) * u;
    final racha = Path()
      ..moveTo(x, y)
      ..lineTo(x + 3 * u, y + 1.2 * u)
      ..lineTo(x + 6 * u, y + .2 * u)
      ..lineTo(x + 9 * u, y + 1.6 * u)
      ..lineTo(x + 12 * u, y + .8 * u);
    p.laco(x + 6 * u, 7 * u, (xx) {
      final r = racha.shift(Offset(xx - x - 6 * u, 0));
      p.c.drawPath(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4 * u
            ..color = const Color(0xFFFF5A1A).withValues(alpha: .25 * pulso)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, u));
      p.c.drawPath(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .6 * u
            ..strokeJoin = StrokeJoin.round
            ..color = Color.lerp(const Color(0xFFFF6A1A), const Color(0xFFFFC14A), pulso - .7)!);
    });
  }
  _pedras(p, p.hz + 11 * u, p.h, const Color(0xFF2E2220), semente: 13, tam: 1.3, densidade: .6);
}

void _dEspaco(_Pincel p) {
  final u = p.u;
  // fita da pista flutuante ao longe
  final onda = _Onda(p, p.hz - 10 * u, 8 * u, const [(.6, 1.0, .5)]);
  final grossura = 2.6 * u;
  final passo = math.max(3.0, p.w / 160);
  final faixa = Path()..moveTo(-2, onda.y(-2));
  for (var x = passo; x < p.w + 2; x += passo) {
    faixa.lineTo(x, onda.y(x));
  }
  faixa.lineTo(p.w + 2, onda.y(p.w + 2));
  for (var x = p.w + 2; x > -2; x -= passo) {
    faixa.lineTo(x, onda.y(x) + grossura);
  }
  faixa
    ..lineTo(-2, onda.y(-2) + grossura)
    ..close();
  p.c.drawPath(faixa, p.tinta(const Color(0xFF5C6480)));
  final borda = Path()..moveTo(-2, onda.y(-2));
  final baixo = Path()..moveTo(-2, onda.y(-2) + grossura);
  for (var x = passo; x < p.w + 2; x += passo) {
    borda.lineTo(x, onda.y(x));
    baixo.lineTo(x, onda.y(x) + grossura);
  }
  for (final (cam, cor) in [(borda, const Color(0xFF22E6FF)), (baixo, const Color(0xFFFF4FD8))]) {
    p.c.drawPath(
        cam,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * u
          ..color = cor.withValues(alpha: .3));
    p.c.drawPath(
        cam,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .45 * u
          ..color = cor);
  }
  // asteroides
  final n = p.vezes(30 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) / n * p.w;
    final y = (8 + 30 * _ruido(i * 7 + 61)) * u + math.sin(p.t * .8 + i) * .6 * u;
    final r = (1.2 + 1.8 * _ruido(i * 7 + 62)) * u;
    p.laco(x, r * 1.5, (x) {
      final pedra = Path();
      for (var j = 0; j < 7; j++) {
        final a = j / 7 * 2 * math.pi;
        final rr = r * (.75 + .35 * _ruido(i * 50 + j));
        final o = Offset(x + math.cos(a) * rr, y + math.sin(a) * rr);
        j == 0 ? pedra.moveTo(o.dx, o.dy) : pedra.lineTo(o.dx, o.dy);
      }
      pedra.close();
      p.forma(pedra, const Color(0xFF7A7280), contorno: .5);
      p.sombra(pedra, Rect.fromLTRB(x, y - r * 2, x + r * 2, y + r * 2), alfa: .25);
    });
  }
}

void _cEspaco(_Pincel p) {
  final u = p.u;
  final y0 = p.hz + 3 * u;
  p.degrade(Rect.fromLTRB(-2, y0, p.w + 2, p.h + 1), const [Color(0xFF5A6380), Color(0xFF363C54)]);
  final junta = p.traco(.3);
  final n = p.vezes(12 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, y0 + 1.5 * u), Offset(x, p.h), junta);
  }
  p.c.drawLine(Offset(-2, y0 + 9 * u), Offset(p.w + 2, y0 + 9 * u), junta);
  for (final (y, cor) in [(y0, const Color(0xFF22E6FF)), (y0 + 1.5 * u, const Color(0xFFFF4FD8))]) {
    p.c.drawLine(
        Offset(-2, y),
        Offset(p.w + 2, y),
        Paint()
          ..strokeWidth = 1.6 * u
          ..color = cor.withValues(alpha: .3));
    p.c.drawLine(
        Offset(-2, y),
        Offset(p.w + 2, y),
        Paint()
          ..strokeWidth = .5 * u
          ..color = cor);
  }
  final m = p.vezes(7 * u);
  for (var i = 0; i < m; i++) {
    final liga = (math.sin(p.t * 3 - i * .8) + 1) / 2;
    final o = Offset((i + .5) * p.w / m, y0 + 5 * u);
    final cor = i.isEven ? const Color(0xFF22E6FF) : const Color(0xFFFF4FD8);
    p.brilho(o, 1.6 * u, cor, alfa: .4 + .5 * liga);
    p.c.drawCircle(o, .45 * u, Paint()..color = Color.lerp(cor, _branco, .5)!);
  }
}

void _veleiro(_Pincel p, double x, double base, double alt) {
  final casco = Path()
    ..moveTo(x - alt * .5, base - alt * .18)
    ..lineTo(x + alt * .5, base - alt * .18)
    ..lineTo(x + alt * .34, base)
    ..lineTo(x - alt * .36, base)
    ..close();
  p.c.drawLine(Offset(x, base - alt * .18), Offset(x, base - alt), p.traco(.5));
  p.forma(
      Path()
        ..moveTo(x + alt * .04, base - alt)
        ..lineTo(x + alt * .44, base - alt * .26)
        ..lineTo(x + alt * .04, base - alt * .26)
        ..close(),
      _branco,
      contorno: .5);
  p.forma(
      Path()
        ..moveTo(x - alt * .04, base - alt * .85)
        ..lineTo(x - alt * .04, base - alt * .26)
        ..lineTo(x - alt * .36, base - alt * .26)
        ..close(),
      const Color(0xFFFFD54F),
      contorno: .5);
  p.forma(casco, const Color(0xFFE53935), contorno: .5);
}

void _ondinhas(_Pincel p, double y0, double y1, {double alfa = .55}) {
  final u = p.u;
  final tr = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .35 * u
    ..strokeCap = StrokeCap.round
    ..color = p.luz(_branco).withValues(alpha: alfa);
  for (var j = 0; j < 5; j++) {
    final y = y0 + (y1 - y0) * (j + .5) / 5;
    final n = p.vezes((7 + j * 2.5) * u);
    final a = (1 + j * .4) * u;
    for (var i = 0; i < n; i++) {
      final x = ((i + .5 * (j % 2)) / n * p.w + p.t * (1 + j * .5) * u) % p.w;
      p.laco(x, a, (x) => p.c.drawPath(
          Path()
            ..moveTo(x - a, y)
            ..quadraticBezierTo(x, y - a * .55, x + a, y),
          tr));
    }
  }
}

void _dPraia(_Pincel p) {
  final u = p.u;
  final mar = p.hz - 5 * u;
  p.degrade(Rect.fromLTRB(-2, mar, p.w + 2, p.hz + 12 * u),
      const [Color(0xFF7FD0EE), Color(0xFF2E9BCF), Color(0xFF1F7FB6)], paradas: const [0, .35, 1]);
  p.c.drawLine(Offset(-2, mar), Offset(p.w + 2, mar), p.traco(.35));
  p.laco(p.w * .18, 9 * u, (x) {
    p.forma(
        Path()
          ..moveTo(x - 9 * u, mar + .2 * u)
          ..quadraticBezierTo(x - 3 * u, mar - 4 * u, x + 1 * u, mar - 3.6 * u)
          ..quadraticBezierTo(x + 5 * u, mar - 3.4 * u, x + 9 * u, mar + .2 * u)
          ..close(),
        const Color(0xFF5E9E5A),
        contorno: .4);
    _palmeira(p, x + 1 * u, mar - 3.4 * u, 6 * u, contorno: .4);
  });
  if (p.noite) {
    final reflexo = Paint()..color = const Color(0x99FFF3C4);
    for (var j = 0; j < 7; j++) {
      final y = mar + (1 + j * 2) * u;
      final l = (1.4 + j * .8) * u * (.7 + .3 * math.sin(p.t * 2 + j));
      p.c.drawRect(Rect.fromCenter(center: Offset(p.w * .8, y), width: l * 2, height: .45 * u), reflexo);
    }
  }
  _ondinhas(p, mar + 1 * u, p.hz + 10 * u);
  final bx = (p.w * .6 + p.t * .6 * u) % p.w;
  p.laco(bx, 3 * u, (x) => _veleiro(p, x, mar + 2.5 * u + math.sin(p.t * 1.6) * .3 * u, 5 * u));
}

void _cPraia(_Pincel p) {
  final u = p.u;
  final borda = _Onda(p, p.hz + 7 * u, 1.2 * u, const [(2.4, 1.0, 0.0), (5.0, .3, 1.0)], fase: math.sin(p.t * .7) * .3);
  // areia molhada, espuma e areia seca
  borda.pinta(const Color(0xFFD9BC88), fundo: p.h + 1, contorno: 0);
  p.c.drawPath(
      borda.topo(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * u
        ..strokeCap = StrokeCap.round
        ..color = p.luz(_branco).withValues(alpha: .9));
  _Onda(p, p.hz + 9.5 * u, 1 * u, const [(2.4, 1.0, 0.4), (5.0, .3, 1.0)])
      .pintaDegrade(const [Color(0xFFF3DDAE), Color(0xFFE6C88E)], fundo: p.h + 1, contorno: .3);
  final concha = p.tinta(const Color(0xFFFFF3E6));
  final n = p.vezes(5 * u);
  for (var i = 0; i < n; i++) {
    p.c.drawCircle(Offset(_ruido(i * 3 + 91) * p.w, p.hz + (13 + 24 * _ruido(i * 3 + 92)) * u), .4 * u, concha);
  }
  final m = p.vezes(64 * u);
  for (var i = 0; i < m; i++) {
    p.laco((i + .06) / m * p.w, 14 * u, (x) => _palmeira(p, x, p.hz + 19 * u, 34 * u, inclina: .16));
    p.laco((i + .94) / m * p.w, 14 * u, (x) => _palmeira(p, x, p.hz + 17 * u, 28 * u, inclina: -.18));
    p.laco((i + .72) / m * p.w, 9 * u, (x) => _guardaSol(p, x, p.hz + 15 * u, 15 * u));
  }
}

void _guardaSol(_Pincel p, double x, double base, double alt) {
  final u = p.u;
  p.forma(
      Path()
        ..moveTo(x - 6 * u, base + 1.5 * u)
        ..lineTo(x + 5 * u, base + 1.5 * u)
        ..lineTo(x + 7 * u, base - .3 * u)
        ..lineTo(x - 4 * u, base - .3 * u)
        ..close(),
      const Color(0xFF29B6F6),
      contorno: .6);
  p.tubos([
    Path()
      ..moveTo(x, base)
      ..lineTo(x + alt * .08, base - alt)
  ], .5 * u, const Color(0xFFEDE7E0), contorno: .6);
  final topo = Offset(x + alt * .08, base - alt);
  final r = alt * .5;
  final copa = Path()
    ..moveTo(topo.dx - r, topo.dy + r * .38)
    ..quadraticBezierTo(topo.dx, topo.dy - r * .5, topo.dx + r, topo.dy + r * .38)
    ..close();
  p.forma(copa, const Color(0xFFF5F5F5), contorno: .8);
  p.c.save();
  p.c.clipPath(copa);
  final vermelho = p.tinta(const Color(0xFFE53935));
  for (var i = 0; i < 6; i += 2) {
    final a = topo.dx - r + i * r / 3;
    p.c.drawPath(
        Path()
          ..moveTo(topo.dx, topo.dy - r)
          ..lineTo(a, topo.dy + r)
          ..lineTo(a + r / 3, topo.dy + r)
          ..close(),
        vermelho);
  }
  p.c.restore();
  p.c.drawPath(copa, p.traco(.8));
}

void _gaivotas(_Pincel p, double y0, double y1) {
  final u = p.u;
  final tr = p.traco(.55);
  final n = p.vezes(36 * u);
  for (var i = 0; i < n; i++) {
    final x = ((i + _ruido(i * 3 + 7)) / n * p.w + p.t * (1.5 + _ruido(i * 3 + 8)) * u) % p.w;
    final y = y0 + (y1 - y0) * _ruido(i * 3 + 9) + math.sin(p.t + i) * u;
    final asa = 1.4 * u;
    final bate = math.sin(p.t * 6 + i * 2) * .5 * u;
    p.laco(x, asa, (x) => p.c.drawPath(
        Path()
          ..moveTo(x - asa, y - bate)
          ..quadraticBezierTo(x - asa * .5, y - asa * .6, x, y)
          ..quadraticBezierTo(x + asa * .5, y - asa * .6, x + asa, y - bate),
        tr));
  }
}

void _dPonte(_Pincel p) {
  final u = p.u;
  final mar = p.hz - 6 * u;
  _Onda(p, mar, 4 * u, const [(1.0, 1.0, .5), (2.7, .4, 2.0)])
      .pinta(const Color(0xFF8FAFC4), fundo: mar + 1 * u, contorno: .3);
  p.degrade(Rect.fromLTRB(-2, mar, p.w + 2, p.h + 1), const [Color(0xFF6FC4E8), Color(0xFF2585BA)]);
  p.c.drawLine(Offset(-2, mar), Offset(p.w + 2, mar), p.traco(.35));
  _ondinhas(p, mar + 1 * u, p.hz + 6 * u, alfa: .45);
  final deck = p.hz + 4 * u;
  final n = p.vezes(64 * u);
  final passo = p.w / n;
  final topo = math.max(6 * u, p.hz - 50 * u);
  const vermelho = Color(0xFFD0533F);
  // cabos principais (parábolas entre torres) e pendurais
  final pendural = p.traco(.25);
  for (var i = -1; i < n; i++) {
    final x0 = (i + .5) * passo, x1 = x0 + passo;
    final yMeio = deck - 6 * u;
    final cy = 2 * yMeio - (topo + 1 * u);
    p.tubos([
      Path()
        ..moveTo(x0, topo + 1 * u)
        ..quadraticBezierTo((x0 + x1) / 2, cy, x1, topo + 1 * u)
    ], .5 * u, vermelho, contorno: .4);
    final m = math.max(4, (passo / (2.6 * u)).round());
    for (var j = 1; j < m; j++) {
      final s = j / m;
      final y = (1 - s) * (1 - s) * (topo + 1 * u) + 2 * (1 - s) * s * cy + s * s * (topo + 1 * u);
      p.c.drawLine(Offset(x0 + s * passo, y), Offset(x0 + s * passo, deck), pendural);
    }
  }
  // torres
  for (var i = 0; i < n; i++) {
    final x = (i + .5) * passo;
    p.laco(x, 4 * u, (x) {
      for (final lado in [-1.0, 1.0]) {
        p.ret(Rect.fromLTRB(x + lado * 2.4 * u - .8 * u, topo, x + lado * 2.4 * u + .8 * u, deck), vermelho,
            contorno: .6);
      }
      for (final y in [topo + 2 * u, topo + (deck - topo) * .45]) {
        p.ret(Rect.fromLTRB(x - 3.2 * u, y, x + 3.2 * u, y + 1.2 * u), vermelho, contorno: .6);
      }
      if (p.noite && (p.t * 1.1 + i) % 2 < 1.2) {
        p.brilho(Offset(x, topo - .5 * u), 1.8 * u, const Color(0xFFFF3B30), alfa: .9);
      }
    });
  }
  _gaivotas(p, 8 * u, p.hz - 22 * u);
}

void _cPonte(_Pincel p) {
  final u = p.u;
  final deck = p.hz + 4 * u;
  p.degrade(Rect.fromLTRB(-2, deck, p.w + 2, p.h + 1), const [Color(0xFF60646C), Color(0xFF484C54)]);
  p.faixa(deck, deck + 1.4 * u, const Color(0xFF9AA3AE), contorno: .6);
  final branco = p.tinta(_branco, alfa: .85);
  p.c.drawRect(Rect.fromLTRB(-2, deck + 2.4 * u, p.w + 2, deck + 2.9 * u), branco);
  final n = p.vezes(9 * u);
  for (var i = 0; i < n; i++) {
    p.c.drawRect(Rect.fromLTWH(i * p.w / n, deck + 10 * u, p.w / n * .45, .6 * u), branco);
  }
  // guarda-corpo
  p.faixa(p.hz + .2 * u, p.hz + 1 * u, const Color(0xFFE3E7ED), contorno: .5);
  p.faixa(p.hz + 2.2 * u, p.hz + 2.7 * u, const Color(0xFFE3E7ED), contorno: .4);
  final m = p.vezes(3.5 * u);
  for (var i = 0; i < m; i++) {
    final x = (i + .5) * p.w / m;
    p.c.drawRect(Rect.fromLTRB(x - .3 * u, p.hz + .2 * u, x + .3 * u, deck), p.tinta(const Color(0xFFCDD3DB)));
  }
  final k = p.vezes(36 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .3) / k * p.w, 5 * u, (x) => _poste(p, x, deck + .8 * u, 20 * u, aceso: p.acesas));
  }
}

void _paredao(_Pincel p, double x, double meia) {
  final u = p.u;
  final pts = <Offset>[
    Offset(meia * .3, -2),
    Offset(meia * .34, 16 * u),
    Offset(meia * .56, 19 * u),
    Offset(meia * .63, 34 * u),
    Offset(meia * .84, 37 * u),
    Offset(meia * .9, p.hz - 6 * u),
    Offset(meia, p.hz + 2 * u),
  ];
  final path = Path()..moveTo(x - meia, p.hz + 2 * u);
  for (final q in pts.reversed) {
    path.lineTo(x - q.dx, q.dy);
  }
  for (final q in pts) {
    path.lineTo(x + q.dx, q.dy);
  }
  path.close();
  p.c.drawPath(path, p.tinta(const Color(0xFFC0603A)));
  p.c.save();
  p.c.clipPath(path);
  const estratos = [Color(0xFFB4532F), Color(0xFFCF7448), Color(0xFFA9492A), Color(0xFFD98A5A)];
  for (var i = 0; i * 3.4 * u < p.hz; i++) {
    final y = i * 3.4 * u;
    p.c.drawRect(Rect.fromLTRB(x - meia - 2, y, x + meia + 2, y + 1.6 * u), p.tinta(estratos[i % 4]));
  }
  // sombra embaixo de cada degrau
  final sombra = Paint()..color = const Color(0x33301020);
  for (final q in [pts[1], pts[3], pts[5]]) {
    p.c.drawRect(Rect.fromLTRB(x - meia, q.dy, x + meia, q.dy + 1.6 * u), sombra);
  }
  p.c.restore();
  p.c.drawPath(path, p.traco(.7));
}

void _dCanion(_Pincel p) {
  final u = p.u;
  p.laco(p.w * .32, 12 * u, (x) => _mesa(p, x, p.hz, 22 * u, 9 * u, const Color(0xFFE3A57E), contorno: .4));
  p.laco(p.w * .64, 16 * u, (x) => _mesa(p, x, p.hz, 30 * u, 13 * u, const Color(0xFFD9926A), contorno: .4));
  final meia = math.min(p.w * .3, 40 * u);
  p.laco(0, meia, (x) => _paredao(p, x, meia));
}

void _cCanion(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFCB7A48), Color(0xFFAE5F30)]);
  _pista(p, p.hz + 3 * u, p.hz + 9 * u, asfalto: const Color(0xFF9A8078));
  _pedras(p, p.hz + 11 * u, p.h, const Color(0xFF9A4A2A), semente: 21, tam: 1.4, densidade: .7);
  final arbusto = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .35 * u
    ..strokeCap = StrokeCap.round
    ..color = p.luz(const Color(0xFF7A6A3A));
  final n = p.vezes(16 * u);
  for (var i = 0; i < n; i++) {
    final x = _ruido(i * 3 + 71) * p.w;
    final y = p.hz + (12 + 24 * _ruido(i * 3 + 72)) * u;
    for (var j = 0; j < 5; j++) {
      final a = -math.pi / 2 + (j - 2) * .45;
      p.c.drawLine(Offset(x, y), Offset(x + math.cos(a) * 2 * u, y + math.sin(a) * 2 * u), arbusto);
    }
  }
}

void _dOasis(_Pincel p) {
  final u = p.u;
  _Onda(p, p.hz - 6 * u, 6 * u, const [(.6, 1.0, .2), (1.5, .4, 2.0)])
      .pinta(const Color(0xFFF2D39C), fundo: p.hz + 2 * u, contorno: .3);
  _Onda(p, p.hz - 2 * u, 5 * u, const [(.9, 1.0, 1.4), (2.1, .4, .3)])
      .pinta(const Color(0xFFE8C084), fundo: p.hz + 2 * u, contorno: .4);
  _Onda(p, p.hz + .5 * u, 3 * u, const [(1.3, 1.0, 2.6), (2.9, .4, 1.0)])
      .pinta(const Color(0xFFDDB070), fundo: p.hz + 2 * u, contorno: .5);
}

void _cOasis(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFE9C487), Color(0xFFD6AB6A)]);
  final larg = math.min(p.w * .8, 66 * u);
  p.laco(p.w * .5, larg * .75, (x) {
    final centro = Offset(x, p.hz + 6 * u);
    p.c.drawOval(Rect.fromCenter(center: centro.translate(0, .4 * u), width: larg * 1.08, height: 11 * u),
        p.tinta(const Color(0xFF6FAE5E)));
    final lago = Rect.fromCenter(center: centro, width: larg, height: 9 * u);
    p.c.drawOval(
        lago,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.luz(const Color(0xFF5FC3E4)), p.luz(const Color(0xFF1F7FB0))],
          ).createShader(lago));
    p.c.drawOval(lago, p.traco(.6));
    final brilho = Paint()
      ..strokeWidth = .4 * u
      ..strokeCap = StrokeCap.round
      ..color = (p.noite ? const Color(0xCCFFF3C4) : const Color(0xB3FFFFFF));
    for (var i = 0; i < 6; i++) {
      final dx = (math.sin(p.t * .8 + i * 1.7)) * larg * .3;
      final y = centro.dy - 2.5 * u + i * u;
      p.c.drawLine(Offset(x + dx - 1.5 * u, y), Offset(x + dx + 1.5 * u, y), brilho);
    }
    final junco = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .35 * u
      ..strokeCap = StrokeCap.round
      ..color = p.luz(const Color(0xFF3E8A42));
    for (final lado in [-1.0, 1.0]) {
      final bx = x + lado * larg * .46;
      for (var j = 0; j < 5; j++) {
        p.c.drawLine(Offset(bx + j * .6 * u * lado, centro.dy + 2 * u),
            Offset(bx + (j - 2) * .9 * u * lado, centro.dy - (2 + j % 3) * u), junco);
      }
    }
    _palmeira(p, x - larg * .44, p.hz + 7 * u, 28 * u, inclina: -.14);
    _palmeira(p, x + larg * .4, p.hz + 6 * u, 24 * u, inclina: .16);
    _palmeira(p, x + larg * .2, p.hz + 2.5 * u, 15 * u, inclina: -.1, contorno: .7);
    for (final lado in [-1.0, 1.0]) {
      _lanterna(p, x + lado * larg * .62, p.hz + 16 * u, 14 * u, i: lado > 0 ? 1 : 0);
    }
  });
}

void _lanterna(_Pincel p, double x, double base, double alt, {int i = 0}) {
  final u = p.u;
  p.tubos([
    Path()
      ..moveTo(x, base)
      ..lineTo(x, base - alt)
      ..lineTo(x + 2.4 * u, base - alt)
  ], .45 * u, const Color(0xFF5A3E2A), contorno: .6);
  final o = Offset(x + 2.4 * u, base - alt + 2.4 * u);
  p.c.drawLine(Offset(o.dx, base - alt), Offset(o.dx, o.dy - 1.4 * u), p.traco(.4));
  final pisca = .85 + .15 * math.sin(p.t * 9 + i * 2);
  if (p.acesas) p.brilho(o, 6 * u, const Color(0xFFFFB04A), alfa: .55 * pisca);
  p.ret(Rect.fromCenter(center: o, width: 2.2 * u, height: 2.8 * u), p.acesas ? const Color(0xFFFFC46A) : const Color(0xFFE88A3A),
      contorno: .6, raio: 1 * u, emite: p.acesas);
  p.c.drawLine(Offset(o.dx - 1.1 * u, o.dy), Offset(o.dx + 1.1 * u, o.dy), p.traco(.3));
}

void _dFloresta(_Pincel p) {
  final u = p.u;
  final n = p.vezes(5 * u);
  final troncos = p.tinta(const Color(0xFF5A3E2A));
  for (var i = 0; i < n; i++) {
    final x = (i + .5 * _ruido(i * 3 + 1)) / n * p.w;
    p.c.drawRect(Rect.fromLTWH(x, p.hz - 8 * u, .9 * u, 9 * u), troncos);
  }
  for (final fileira in [0, 1]) {
    final m = p.vezes((fileira == 0 ? 7 : 9) * u);
    for (var i = 0; i < m; i++) {
      final sem = fileira * 1000 + i * 7;
      final x = (i + .5 * fileira + .3 * _ruido(sem + 1)) / m * p.w;
      final y = p.hz - (fileira == 0 ? 15 : 9) * u - 3 * u * _ruido(sem + 2);
      final r = (fileira == 0 ? 5 : 5.5 + 2 * _ruido(sem + 3)) * u;
      final cor = fileira == 0 ? const Color(0xFFC07444) : _outono[(i * 7 + 3) % 4];
      p.laco(x, r * 1.8, (x) => p.blob([
            Rect.fromCircle(center: Offset(x, y), radius: r),
            Rect.fromCircle(center: Offset(x - r * .8, y + r * .3), radius: r * .7),
            Rect.fromCircle(center: Offset(x + r * .8, y + r * .35), radius: r * .75),
          ], cor, contorno: fileira == 0 ? .3 : .55, sombra: .12));
    }
  }
}

void _cFloresta(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF9C7442), Color(0xFF73522E)]);
  _pista(p, p.hz + 3 * u, p.hz + 9 * u, asfalto: const Color(0xFF8A8478));
  final n = p.vezes(1.5 * u) * 3;
  for (var i = 0; i < n; i++) {
    final x = _ruido(i * 3 + 201) * p.w;
    final y = p.hz + 10 * u + (p.h - p.hz - 10 * u) * _ruido(i * 3 + 202);
    final f = .6 + .6 * (y - p.hz) / (p.h - p.hz);
    p.c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 1.6 * u * f, height: .8 * u * f),
        p.tinta(_outono[i % 4], alfa: .9));
  }
  p.laco(0, 20 * u, (x) {
    final tronco = Path()
      ..moveTo(x - 2.2 * u, p.hz + 18 * u)
      ..lineTo(x - 1.6 * u, 8 * u)
      ..lineTo(x + 1.6 * u, 8 * u)
      ..lineTo(x + 2.4 * u, p.hz + 18 * u)
      ..close();
    p.forma(tronco, const Color(0xFF6E4A2E), contorno: 1);
    p.sombra(tronco, Rect.fromLTRB(x + .4 * u, 0, x + 3 * u, p.h), alfa: .2);
    p.tubos([
      Path()
        ..moveTo(x + 1 * u, 22 * u)
        ..lineTo(x + 7 * u, 14 * u)
    ], 1.2 * u, const Color(0xFF6E4A2E));
    p.blob([
      Rect.fromCircle(center: Offset(x, 2 * u), radius: 13 * u),
      Rect.fromCircle(center: Offset(x + 11 * u, 9 * u), radius: 9 * u),
      Rect.fromCircle(center: Offset(x - 11 * u, 8 * u), radius: 9 * u),
      Rect.fromCircle(center: Offset(x + 4 * u, 14 * u), radius: 7 * u),
    ], const Color(0xFFE07A2A), contorno: 1, sombra: .16);
    p.c.drawCircle(Offset(x - 4 * u, -1 * u), 5 * u, Paint()..color = const Color(0x33FFE0A0));
  });
}

void _dVale(_Pincel p) {
  final u = p.u;
  const cores = [Color(0xFFB8CBD8), Color(0xFF9DB9B4), Color(0xFF86AE8E), Color(0xFF6E9E68)];
  const pinhos = [Color(0xFF8AA6A8), Color(0xFF5E8A78), Color(0xFF3F7056), Color(0xFF2F6046)];
  for (var i = 0; i < 4; i++) {
    final onda = _Onda(p, p.hz - (17 - i * 5) * u, (7 - i) * u,
        [(.7 + i * .35, 1.0, i * 1.7), (1.8 + i * .5, .4, i * .9)]);
    onda.pinta(cores[i], fundo: p.hz + 2 * u, contorno: .25 + i * .12);
    if (i >= 1) {
      final n = p.vezes((8 - i * 1.5) * u);
      for (var j = 0; j < n; j++) {
        if (_ruido(i * 500 + j) < .35) continue;
        final x = (j + .5) / n * p.w;
        final alt = (2.4 + i * 1.6) * u;
        p.laco(x, alt * .4, (x) => _pinheiro(p, x, onda.y(x) + .6 * u, alt, cor: pinhos[i], contorno: .2 + i * .12));
      }
    }
    if (i < 3) {
      final y = p.hz - (13.5 - i * 5) * u;
      final r = Rect.fromLTRB(-2, y - 2.5 * u, p.w + 2, y + 2.5 * u);
      final a = .28 + .08 * math.sin(p.t * .3 + i);
      p.c.drawRect(
          r,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0x00FFFFFF), _branco.withValues(alpha: a), const Color(0x00FFFFFF)],
            ).createShader(r));
    }
  }
}

void _cVale(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF86B86E), Color(0xFF5E8F50)]);
  _pista(p, p.hz + 3 * u, p.hz + 9.5 * u);
  _tufos(p, p.hz + 11 * u, p.h, const Color(0xFF3E7A3A), flores: true, semente: 300);
  final k = p.vezes(46 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .07) / k * p.w, 8 * u, (x) => _pinheiro(p, x, p.hz + 20 * u, 25 * u));
    p.laco((i + .93) / k * p.w, 5 * u, (x) => _pinheiro(p, x, p.hz + 15 * u, 16 * u, contorno: .8));
  }
}

void _dLago(_Pincel p) {
  final u = p.u;
  _pintaSerra(p, p.hz, 26 * u, p.vezes(30 * u), 29, const Color(0xFFA6B8D2), neve: 8 * u, contorno: .4);
  final n = p.vezes(4.5 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5 * _ruido(i * 7 + 13)) / n * p.w;
    p.laco(x, 2 * u, (x) => _pinheiro(p, x, p.hz + .8 * u, (4 + 3 * _ruido(i * 7 + 14)) * u,
        cor: const Color(0xFF2B4A3C), neve: true, contorno: .4));
  }
}

void _cLago(_Pincel p) {
  final u = p.u;
  p.faixa(p.hz, p.hz + 3 * u, const Color(0xFFF4F8FC), contorno: .5, baixo: false);
  p.degrade(Rect.fromLTRB(-2, p.hz + 3 * u, p.w + 2, p.h + 1), const [Color(0xFFD3EEFF), Color(0xFFA9D6F2)]);
  p.c.drawLine(Offset(-2, p.hz + 3 * u), Offset(p.w + 2, p.hz + 3 * u), p.traco(.4));
  final n = p.vezes(8 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) / n * p.w;
    p.laco(x, 3 * u, (x) => p.blob([
          Rect.fromCenter(center: Offset(x, p.hz + 3 * u), width: (4 + 2 * _ruido(i * 5 + 3)) * u, height: 1.6 * u),
        ], const Color(0xFFF7FBFF), contorno: .4, sombra: .06));
  }
  final reflexo = p.tinta(_branco, alfa: p.noite ? .18 : .35);
  final m = p.vezes(22 * u);
  for (var i = 0; i < m; i++) {
    final x = (i + .3) / m * p.w;
    p.c.drawPath(
        Path()
          ..moveTo(x, p.hz + 5 * u)
          ..lineTo(x + 3 * u, p.hz + 5 * u)
          ..lineTo(x - 2 * u, p.h)
          ..lineTo(x - 7 * u, p.h)
          ..close(),
        reflexo);
  }
  final racha = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .3 * u
    ..strokeJoin = StrokeJoin.round
    ..color = p.luz(const Color(0xFF6FA8D0));
  final k = p.vezes(26 * u);
  for (var i = 0; i < k; i++) {
    final x = (i + _ruido(i * 3 + 41) * .6) / k * p.w;
    final y = p.hz + (8 + 22 * _ruido(i * 3 + 42)) * u;
    final cam = Path()..moveTo(x, y);
    var yy = y;
    for (var j = 1; j <= 5; j++) {
      yy += (_ruido(i * 9 + j) - .5) * .5 * u + .25 * u;
      cam.lineTo(x + j * 3.4 * u, yy);
    }
    cam
      ..moveTo(x + 6.8 * u, y + .5 * u)
      ..lineTo(x + 8.4 * u, y + 2.2 * u)
      ..lineTo(x + 8.2 * u, y + 3.4 * u);
    p.laco(x + 8.5 * u, 9 * u, (xx) => p.c.drawPath(cam.shift(Offset(xx - x - 8.5 * u, 0)), racha));
  }
  final neve = p.tinta(const Color(0xFFF7FBFF), alfa: .9);
  final s = p.vezes(18 * u);
  for (var i = 0; i < s; i++) {
    p.c.drawOval(
        Rect.fromCenter(
            center: Offset(_ruido(i * 3 + 61) * p.w, p.hz + (10 + 26 * _ruido(i * 3 + 62)) * u),
            width: (4 + 5 * _ruido(i * 3 + 63)) * u,
            height: 1 * u),
        neve);
  }
}

void _dLua(_Pincel p) {
  final u = p.u;
  _pintaSerra(p, p.hz + 1 * u, 7 * u, p.vezes(12 * u), 41, const Color(0xFF8E9098), contorno: .4);
  final borda = p.traco(.3);
  final n = p.vezes(26 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) / n * p.w;
    p.c.drawArc(Rect.fromCenter(center: Offset(x, p.hz - .5 * u), width: 5 * u, height: 1.4 * u), math.pi, math.pi,
        false, borda);
  }
}

void _cratera(_Pincel p, double x, double y, double larg) {
  final r = Rect.fromCenter(center: Offset(x, y), width: larg, height: larg * .28);
  p.c.drawOval(r.inflate(larg * .04), p.tinta(const Color(0xFFC4C6CC)));
  p.c.drawOval(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.luz(const Color(0xFF5E6068)), p.luz(const Color(0xFF9C9EA6))],
        ).createShader(r));
  p.c.drawOval(r, p.traco(.5));
}

void _cLua(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFA9ABB3), Color(0xFF7C7E86)]);
  final n = p.vezes(18 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5 * _ruido(i * 3 + 11)) / n * p.w;
    final f = _ruido(i * 3 + 12);
    final y = p.hz + (5 + 30 * f) * u;
    final larg = (5 + 9 * _ruido(i * 3 + 13)) * u * (.6 + f * .8);
    p.laco(x, larg * .6, (x) => _cratera(p, x, y, larg));
  }
  _pedras(p, p.hz + 3 * u, p.h, const Color(0xFF6A6C74), semente: 33, densidade: .6);
}

void _dMarte(_Pincel p) {
  final u = p.u;
  p.laco(p.w * .28, 14 * u, (x) => _mesa(p, x, p.hz, 26 * u, 11 * u, const Color(0xFFC77A55), contorno: .4));
  p.laco(p.w * .74, 10 * u, (x) => _mesa(p, x, p.hz, 18 * u, 7 * u, const Color(0xFFBD6E4A), contorno: .4));
  final r = Rect.fromLTRB(-2, p.hz - 6 * u, p.w + 2, p.hz + 1 * u);
  p.c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x00E0A080), p.luz(const Color(0xFFE0A080)).withValues(alpha: .55)],
        ).createShader(r));
  _Onda(p, p.hz + .5 * u, 3 * u, const [(1.5, 1.0, .6), (3.6, .5, 2.0)])
      .pinta(const Color(0xFFA8502F), fundo: p.hz + 2 * u, contorno: .5);
}

void _cMarte(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFC8683E), Color(0xFF9E4626)]);
  final risco = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .35 * u
    ..strokeCap = StrokeCap.round
    ..color = p.luz(const Color(0x55FFC8A0));
  final n = p.vezes(6 * u);
  for (var i = 0; i < n; i++) {
    final x = _ruido(i * 4 + 131) * p.w;
    final y = p.hz + (4 + 30 * _ruido(i * 4 + 132)) * u;
    final a = (1.5 + 2 * _ruido(i * 4 + 133)) * u;
    p.c.drawPath(
        Path()
          ..moveTo(x - a, y)
          ..quadraticBezierTo(x, y - a * .3, x + a, y),
        risco);
  }
  _pedras(p, p.hz + 3 * u, p.h, const Color(0xFF7E3A22), semente: 55, tam: 1.3, densidade: .9);
}

// ═══════════════════════════════════════════ exteriores de evento ═══════════════════════════════════════════

void _foguete(_Pincel p, double x, double base) {
  final u = p.u;
  final alt = math.min(42 * u, base - 8 * u);
  const vermelho = Color(0xFFD9532E);
  // torre de lançamento
  final tx = x - 7.5 * u, topoT = base - alt * 1.08;
  p.tubos([
    Path()
      ..moveTo(tx - 1.8 * u, base)
      ..lineTo(tx - 1.8 * u, topoT),
    Path()
      ..moveTo(tx + 1.8 * u, base)
      ..lineTo(tx + 1.8 * u, topoT),
  ], .7 * u, vermelho, contorno: .5);
  final x1 = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .35 * u
    ..color = p.luz(vermelho);
  final passos = math.max(4, (alt / (4 * u)).round());
  for (var i = 0; i < passos; i++) {
    final y0 = base - i * (base - topoT) / passos, y1 = base - (i + 1) * (base - topoT) / passos;
    p.c.drawLine(Offset(tx - 1.8 * u, y0), Offset(tx + 1.8 * u, y1), x1);
    p.c.drawLine(Offset(tx + 1.8 * u, y0), Offset(tx - 1.8 * u, y1), x1);
  }
  p.tubos([
    Path()
      ..moveTo(tx + 1.8 * u, base - alt * .62)
      ..lineTo(x - 3 * u, base - alt * .62)
  ], .6 * u, vermelho, contorno: .5);
  // foguete
  final bw = 6.4 * u;
  final topoCorpo = base - alt + 9 * u;
  final corpo = Path()
    ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTRB(x - bw / 2, topoCorpo, x + bw / 2, base - 3 * u), Radius.circular(1 * u)));
  for (final lado in [-1.0, 1.0]) {
    p.forma(
        Path()
          ..moveTo(x + lado * bw / 2, base - 12 * u)
          ..lineTo(x + lado * (bw / 2 + 3.6 * u), base - 3 * u)
          ..lineTo(x + lado * (bw / 2 + 3.6 * u), base - 1.4 * u)
          ..lineTo(x + lado * bw / 2, base - 4.4 * u)
          ..close(),
        vermelho,
        contorno: .7);
  }
  p.forma(
      Path()
        ..moveTo(x - bw * .34, base - 3 * u)
        ..lineTo(x + bw * .34, base - 3 * u)
        ..lineTo(x + bw * .44, base)
        ..lineTo(x - bw * .44, base)
        ..close(),
      const Color(0xFF4A4E58),
      contorno: .7);
  p.forma(corpo, const Color(0xFFF5F5F5), contorno: .8);
  p.c.save();
  p.c.clipPath(corpo);
  final faixa = p.tinta(vermelho);
  final yCorpo = base - 3 * u - topoCorpo;
  p.c.drawRect(Rect.fromLTRB(x - bw, topoCorpo + yCorpo * .3, x + bw, topoCorpo + yCorpo * .3 + 1.6 * u), faixa);
  p.c.drawRect(Rect.fromLTRB(x - bw, topoCorpo + yCorpo * .72, x + bw, topoCorpo + yCorpo * .72 + 1.6 * u), faixa);
  p.c.drawRect(Rect.fromLTRB(x + bw * .18, topoCorpo, x + bw, base), Paint()..color = const Color(0x22301A40));
  p.c.restore();
  p.forma(
      Path()
        ..moveTo(x - bw / 2, topoCorpo + .2 * u)
        ..quadraticBezierTo(x - bw * .45, topoCorpo - 6 * u, x, topoCorpo - 9 * u)
        ..quadraticBezierTo(x + bw * .45, topoCorpo - 6 * u, x + bw / 2, topoCorpo + .2 * u)
        ..close(),
      vermelho,
      contorno: .8);
  p.circ(Offset(x, topoCorpo + 5 * u), 1.6 * u, const Color(0xFF6EC6F0), contorno: .7);
  p.c.drawCircle(Offset(x - .5 * u, topoCorpo + 4.5 * u), .5 * u, Paint()..color = const Color(0x99FFFFFF));
  if (p.acesas) {
    p.brilho(Offset(x, base - 2 * u), 16 * u, const Color(0xFFFFF0C0), alfa: .35);
    if ((p.t * 1.2) % 2 < 1.1) p.brilho(Offset(tx, topoT - .6 * u), 2 * u, const Color(0xFFFF3B30), alfa: .95);
  }
}

void _dPlataforma(_Pincel p) {
  final u = p.u;
  p.laco(p.w * .3, 11 * u, (x) => _mesa(p, x, p.hz, 20 * u, 6 * u, const Color(0xFFE3B88A), contorno: .35));
  _Onda(p, p.hz, 1.5 * u, const [(1.0, 1.0, 0.0), (2.3, .5, 1.0)])
      .pinta(const Color(0xFFEACB98), fundo: p.hz + 2 * u, contorno: .4);
  p.laco(p.w * .74, 14 * u, (x) => _foguete(p, x, p.hz + .5 * u));
}

void _cPlataforma(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFE8C48E), Color(0xFFD5A86C)]);
  final y0 = p.hz + 3 * u;
  p.degrade(Rect.fromLTRB(-2, y0, p.w + 2, p.h + 1), const [Color(0xFFC6C2BA), Color(0xFFA29E96)]);
  p.faixa(y0, y0 + 1.4 * u, const Color(0xFFFFC928), contorno: .5);
  final m = p.vezesPar(2.4 * u);
  final preto = p.tinta(const Color(0xFF2B2B30));
  for (var i = 0; i < m; i += 2) {
    final x = i * p.w / m;
    p.c.drawPath(
        Path()
          ..moveTo(x, y0 + 1.4 * u)
          ..lineTo(x + p.w / m, y0 + 1.4 * u)
          ..lineTo(x + 2 * p.w / m, y0)
          ..lineTo(x + p.w / m, y0)
          ..close(),
        preto);
  }
  final junta = p.traco(.3);
  final n = p.vezes(16 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, y0 + 1.4 * u), Offset(x - 2 * u, p.h), junta);
  }
  p.c.drawLine(Offset(-2, y0 + 10 * u), Offset(p.w + 2, y0 + 10 * u), junta);
  final k = p.vezes(48 * u);
  for (var i = 0; i < k; i++) {
    for (final f in [.08, .92]) {
      p.laco((i + f) / k * p.w, 2 * u, (x) {
        final base = p.hz + 17 * u;
        final cone = Path()
          ..moveTo(x - 1.6 * u, base)
          ..lineTo(x - .4 * u, base - 4 * u)
          ..lineTo(x + .4 * u, base - 4 * u)
          ..lineTo(x + 1.6 * u, base)
          ..close();
        p.forma(cone, const Color(0xFFFF7A1A), contorno: .6);
        p.c.save();
        p.c.clipPath(cone);
        p.c.drawRect(Rect.fromLTRB(x - 2 * u, base - 2.6 * u, x + 2 * u, base - 1.8 * u), p.tinta(_branco));
        p.c.restore();
      });
    }
  }
}

void _dBoxes(_Pincel p) {
  final u = p.u;
  final n = p.vezes(5 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) / n * p.w;
    final r = (2.4 + 1.6 * _ruido(i * 5 + 3)) * u;
    p.laco(x, r * 1.3, (x) => p.blob([Rect.fromCircle(center: Offset(x, p.hz - r * .5), radius: r)],
        const Color(0xFF6E9E5A), contorno: .35, sombra: .1));
  }
  p.laco(p.w * .7, 22 * u, (x) => _arquibancada(p, x - 20 * u, x + 20 * u, p.hz - 10 * u, p.hz + .5 * u,
      fileiras: 3, contorno: .5));
}

void _bandeiraQuadriculada(_Pincel p, double x, double base, double alt) {
  final u = p.u;
  p.tubos([
    Path()
      ..moveTo(x, base)
      ..lineTo(x, base - alt)
  ], .8 * u, const Color(0xFFD7DBE0));
  const cols = 6, lins = 4;
  final cw = 1.5 * u, ch = 1.5 * u;
  final topo = base - alt + .6 * u;
  double off(int c) => math.sin(p.t * 4 - c * .9) * .55 * u * (c / cols);
  final preto = p.tinta(const Color(0xFF1E1E24)), branco = p.tinta(_branco);
  for (var c = 0; c < cols; c++) {
    for (var l = 0; l < lins; l++) {
      p.c.drawPath(
          Path()
            ..moveTo(x + c * cw, topo + l * ch + off(c))
            ..lineTo(x + (c + 1) * cw, topo + l * ch + off(c + 1))
            ..lineTo(x + (c + 1) * cw, topo + (l + 1) * ch + off(c + 1))
            ..lineTo(x + c * cw, topo + (l + 1) * ch + off(c))
            ..close(),
          (c + l).isEven ? preto : branco);
    }
  }
  final borda = Path()..moveTo(x, topo + off(0));
  for (var c = 1; c <= cols; c++) {
    borda.lineTo(x + c * cw, topo + off(c));
  }
  for (var c = cols; c >= 0; c--) {
    borda.lineTo(x + c * cw, topo + lins * ch + off(c));
  }
  borda.close();
  p.c.drawPath(borda, p.traco(.7));
}

void _tenda(_Pincel p, double x, double base, double larg, double alt) {
  final u = p.u;
  final topo = base - alt;
  for (final lado in [-1.0, 1.0]) {
    p.tubos([
      Path()
        ..moveTo(x + lado * larg * .46, base)
        ..lineTo(x + lado * larg * .46, topo + 3 * u)
    ], .7 * u, const Color(0xFFCFD6DE), contorno: .7);
  }
  final teto = Path()
    ..moveTo(x - larg * .5, topo + 4 * u)
    ..lineTo(x - larg * .36, topo)
    ..lineTo(x + larg * .36, topo)
    ..lineTo(x + larg * .5, topo + 4 * u)
    ..close();
  p.forma(teto, _branco, contorno: 1);
  p.c.save();
  p.c.clipPath(teto);
  final roxo = p.tinta(const Color(0xFF6A3FB5));
  final n = 8;
  for (var i = 0; i < n; i += 2) {
    final a = x - larg * .5 + i * larg / n;
    p.c.drawRect(Rect.fromLTWH(a, topo, larg / n, 5 * u), roxo);
  }
  p.c.restore();
  p.c.drawPath(teto, p.traco(1));
  // franja recortada
  final franja = Path()..moveTo(x - larg * .5, topo + 4 * u);
  final m = 10;
  for (var i = 0; i < m; i++) {
    final a = x - larg * .5 + i * larg / m;
    franja.quadraticBezierTo(a + larg / m / 2, topo + 6.4 * u, a + larg / m, topo + 4 * u);
  }
  franja.close();
  p.forma(franja, const Color(0xFF6A3FB5), contorno: .7);
  // mesinha com notebook
  p.ret(Rect.fromLTWH(x - 6 * u, base - 6 * u, 12 * u, 1 * u), const Color(0xFFB0835A), contorno: .6);
  p.c.drawLine(Offset(x - 5 * u, base - 5 * u), Offset(x - 5 * u, base), p.traco(.7));
  p.c.drawLine(Offset(x + 5 * u, base - 5 * u), Offset(x + 5 * u, base), p.traco(.7));
  p.ret(Rect.fromLTWH(x - 2.6 * u, base - 9.4 * u, 5 * u, 3.4 * u), const Color(0xFF3A4152), contorno: .6, raio: .3 * u);
  p.ret(Rect.fromLTWH(x - 2.2 * u, base - 9 * u, 4.2 * u, 2.6 * u), const Color(0xFF7FD6FF), contorno: 0, emite: true);
}

void _cBoxes(_Pincel p) {
  final u = p.u;
  p.faixa(p.hz, p.hz + 2 * u, const Color(0xFF6FAE5E), contorno: .5, baixo: false);
  _pista(p, p.hz + 2 * u, p.hz + 8 * u, asfalto: const Color(0xFF6E727A));
  p.faixa(p.hz + 8 * u, p.hz + 11 * u, const Color(0xFFD8DCE2), contorno: .6);
  p.faixa(p.hz + 9.2 * u, p.hz + 9.9 * u, const Color(0xFF6A3FB5), contorno: 0);
  p.degrade(Rect.fromLTRB(-2, p.hz + 11 * u, p.w + 2, p.h + 1), const [Color(0xFF62666E), Color(0xFF52565E)]);
  final branco = p.tinta(_branco, alfa: .85);
  p.c.drawRect(Rect.fromLTRB(-2, p.hz + 13 * u, p.w + 2, p.hz + 13.5 * u), branco);
  final n = p.vezes(64 * u);
  for (var i = 0; i < n; i++) {
    p.laco((i + .2) / n * p.w, 16 * u, (x) => _tenda(p, x, p.hz + 17 * u, 30 * u, 26 * u));
    p.laco((i + .55) / n * p.w, 3 * u, (x) => _pneus(p, x, p.hz + 17 * u, 2.2 * u, 4));
    p.laco((i + .62) / n * p.w, 3 * u, (x) => _pneus(p, x, p.hz + 18 * u, 2.2 * u, 3));
    p.laco((i + .88) / n * p.w, 10 * u, (x) => _bandeiraQuadriculada(p, x, p.hz + 17 * u, 30 * u));
  }
}

void _holofotes(_Pincel p, double x, double topo, double base, {bool faixo = false}) {
  final u = p.u;
  p.tubos([
    Path()
      ..moveTo(x, base)
      ..lineTo(x, topo)
  ], .8 * u, const Color(0xFF7C8494), contorno: .5);
  final painel = Rect.fromCenter(center: Offset(x, topo), width: 6 * u, height: 3 * u);
  p.ret(painel, const Color(0xFF4A5060), contorno: .6, raio: .4 * u);
  final aceso = p.acesas;
  for (var i = 0; i < 3; i++) {
    for (var j = 0; j < 2; j++) {
      p.c.drawCircle(Offset(painel.left + (1 + i * 2) * u, painel.top + (.8 + j * 1.4) * u), .5 * u,
          Paint()..color = aceso ? const Color(0xFFFFF6D0) : p.luz(const Color(0xFFBFC6D0)));
    }
  }
  if (aceso) {
    p.brilho(Offset(x, topo), 10 * u, const Color(0xFFFFF0C0), alfa: .5);
    if (faixo) {
      final ang = math.sin(p.t * .5 + x * .01) * .35;
      final dir = Offset(math.sin(ang), math.cos(ang));
      final fim = Offset(x, topo) + dir * 60 * u;
      final lado = Offset(dir.dy, -dir.dx) * 9 * u;
      p.c.drawPath(
          Path()
            ..moveTo(x - 2 * u, topo)
            ..lineTo(x + 2 * u, topo)
            ..lineTo(fim.dx + lado.dx, fim.dy + lado.dy)
            ..lineTo(fim.dx - lado.dx, fim.dy - lado.dy)
            ..close(),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [const Color(0x40FFF6D0), const Color(0x00FFF6D0)],
            ).createShader(Rect.fromPoints(Offset(x, topo), fim)));
    }
  }
}

void _bandeirolas(_Pincel p, double y, double queda) {
  final u = p.u;
  final n = p.vezes(30 * u);
  final passo = p.w / n;
  for (var i = 0; i < n; i++) {
    final x0 = i * passo;
    final cy = y + queda * 2;
    p.c.drawPath(
        Path()
          ..moveTo(x0, y)
          ..quadraticBezierTo(x0 + passo / 2, cy, x0 + passo, y),
        p.traco(.35));
    final m = math.max(3, (passo / (2.6 * u)).round());
    for (var j = 0; j < m; j++) {
      final s = (j + .5) / m;
      final yy = (1 - s) * (1 - s) * y + 2 * (1 - s) * s * cy + s * s * y;
      final xx = x0 + s * passo;
      final balanca = math.sin(p.t * 2 + j + i) * .3 * u;
      p.forma(
          Path()
            ..moveTo(xx - .9 * u, yy)
            ..lineTo(xx + .9 * u, yy)
            ..lineTo(xx + balanca, yy + 2 * u)
            ..close(),
          _publico[(j + i * 3) % 6],
          contorno: .3);
    }
  }
}

void _dPodio(_Pincel p) {
  final u = p.u;
  final n = p.vezes(60 * u);
  for (var i = 0; i < n; i++) {
    p.laco((i + .1) / n * p.w, 5 * u, (x) => _holofotes(p, x, 8 * u, p.hz, faixo: true));
  }
  _arquibancada(p, -2, p.w + 2, p.hz - 20 * u, p.hz, fileiras: 6, inteira: true);
  _bandeirolas(p, 9 * u, 3 * u);
}

void _cPodio(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF4A3F63), Color(0xFF2E2742)]);
  final brilho = Paint()
    ..strokeWidth = .25 * u
    ..color = p.luz(const Color(0x40FFFFFF));
  for (var i = 1; i < 6; i++) {
    final y = p.hz + i * i * 1.1 * u;
    p.c.drawLine(Offset(-2, y), Offset(p.w + 2, y), brilho);
  }
  p.laco(p.w * .5, 20 * u, (x) => _podio123(p, x, p.hz + 15 * u));
  const cores = [Color(0xFFFFD54F), Color(0xFFE53935), Color(0xFF26C6DA), Color(0xFFF5F5F5), Color(0xFF8E44AD)];
  final m = p.vezes(1.6 * u) * 2;
  for (var i = 0; i < m; i++) {
    final x = _ruido(i * 3 + 401) * p.w;
    final y = p.hz + 16 * u + (p.h - p.hz - 16 * u) * _ruido(i * 3 + 402);
    p.c.save();
    p.c.translate(x, y);
    p.c.rotate(_ruido(i * 3 + 403) * math.pi);
    p.c.drawRect(Rect.fromCenter(center: Offset.zero, width: .9 * u, height: .45 * u), p.tinta(cores[i % 5]));
    p.c.restore();
  }
}

void _podio123(_Pincel p, double x, double base) {
  final u = p.u;
  final bw = math.min(12 * u, p.w * .22);
  final blocos = [
    (2, x - bw, 9 * u, const Color(0xFFC9D1DB)),
    (1, x, 13 * u, const Color(0xFFF2C14E)),
    (3, x + bw, 6.5 * u, const Color(0xFFD08A4E)),
  ];
  for (final (n, cx, alt, cor) in blocos) {
    final r = Rect.fromLTWH(cx - bw / 2, base - alt, bw, alt);
    final caixa = Path()..addRect(r);
    p.forma(caixa, cor, contorno: 1);
    p.sombra(caixa, Rect.fromLTRB(r.left, r.top + 1.2 * u, r.right, r.bottom), alfa: .14);
    p.c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 1.2 * u), p.tinta(Color.lerp(cor, _branco, .45)!));
    p.c.drawLine(Offset(r.left, r.top + 1.2 * u), Offset(r.right, r.top + 1.2 * u), p.traco(.5));
    final lado = math.min(alt - 2.4 * u, bw * .55);
    final dig = Rect.fromCenter(center: Offset(cx, r.top + 1.2 * u + (alt - 1.2 * u) / 2), width: lado * .62, height: lado);
    p.tubos([_algarismo(n, dig)], math.max(1.5, lado * .14), _branco, contorno: .6);
  }
}

void _dAutodromo(_Pincel p) {
  final u = p.u;
  final n = p.vezes(55 * u);
  for (var i = 0; i < n; i++) {
    p.laco((i + .35) / n * p.w, 5 * u, (x) => _holofotes(p, x, 5 * u, p.hz - 15 * u));
  }
  _arquibancada(p, -2, p.w + 2, p.hz - 17 * u, p.hz - .5 * u, fileiras: 5, inteira: true);
  p.faixa(p.hz - .5 * u, p.hz + 1 * u, const Color(0xFFB8BEC8), contorno: .5);
  p.laco(p.w * .82, 6 * u, (x) {
    final topo = math.max(5 * u, p.hz - 42 * u);
    p.ret(Rect.fromLTRB(x - 2.4 * u, topo + 6 * u, x + 2.4 * u, p.hz), const Color(0xFFD9DDE3), contorno: .7);
    final cab = Rect.fromLTRB(x - 5.5 * u, topo, x + 5.5 * u, topo + 6 * u);
    p.ret(cab, const Color(0xFFE4E7EC), contorno: .8, raio: .5 * u);
    p.ret(Rect.fromLTRB(cab.left + .8 * u, cab.top + 1.4 * u, cab.right - .8 * u, cab.bottom - 1.4 * u),
        p.acesas ? const Color(0xFFFFE08A) : const Color(0xFF7FB8E6),
        contorno: .4, emite: p.acesas);
    p.c.drawLine(Offset(x, topo), Offset(x, topo - 4 * u), p.traco(.5));
    if (p.noite && (p.t * 1.3) % 2 < 1.1) p.brilho(Offset(x, topo - 4 * u), 1.6 * u, const Color(0xFFFF3B30), alfa: .95);
  });
}

void _cAutodromo(_Pincel p) {
  final u = p.u;
  p.faixa(p.hz, p.hz + 1.5 * u, const Color(0xFF6FAE5E), contorno: .4, baixo: false);
  final m = p.vezesPar(4 * u);
  for (var i = 0; i < m; i++) {
    p.c.drawRect(Rect.fromLTWH(i * p.w / m, p.hz + 1.5 * u, p.w / m + .5, 2.5 * u),
        p.tinta(i.isEven ? const Color(0xFFE53935) : const Color(0xFFF5F5F5)));
  }
  p.c.drawLine(Offset(-2, p.hz + 1.5 * u), Offset(p.w + 2, p.hz + 1.5 * u), p.traco(.5));
  p.degrade(Rect.fromLTRB(-2, p.hz + 4 * u, p.w + 2, p.h + 1), const [Color(0xFF5A5E66), Color(0xFF44484F)]);
  p.c.drawLine(Offset(-2, p.hz + 4 * u), Offset(p.w + 2, p.hz + 4 * u), p.traco(.6));
  final branco = p.tinta(_branco, alfa: .85);
  final n = p.vezes(10 * u);
  for (var i = 0; i < n; i++) {
    p.c.drawRect(Rect.fromLTWH(i * p.w / n, p.hz + 11 * u, p.w / n * .5, .6 * u), branco);
  }
  p.laco(p.w * .5, 24 * u, (x) {
    // faixa de largada/chegada (quadriculada, abre em perspectiva)
    const lins = 10;
    final y0 = p.hz + 4 * u, y1 = p.h + 1;
    for (var l = 0; l < lins; l++) {
      final ya = y0 + (y1 - y0) * l / lins, yb = y0 + (y1 - y0) * (l + 1) / lins;
      final la = 2.5 * u + 2.5 * u * l / lins, lb = 2.5 * u + 2.5 * u * (l + 1) / lins;
      for (var c = 0; c < 2; c++) {
        final xa0 = x - la + c * la, xa1 = xa0 + la;
        final xb0 = x - lb + c * lb, xb1 = xb0 + lb;
        p.c.drawPath(
            Path()
              ..moveTo(xa0, ya)
              ..lineTo(xa1, ya)
              ..lineTo(xb1, yb)
              ..lineTo(xb0, yb)
              ..close(),
            p.tinta((l + c).isEven ? const Color(0xFF1E1E24) : _branco));
      }
    }
    // pórtico de largada com as 5 luzes
    final topo = p.hz - 28 * u;
    p.tubos([
      Path()
        ..moveTo(x - 22 * u, p.hz + 4 * u)
        ..lineTo(x - 22 * u, topo),
      Path()
        ..moveTo(x + 22 * u, p.hz + 4 * u)
        ..lineTo(x + 22 * u, topo),
    ], 1.1 * u, const Color(0xFFB8BEC8));
    final viga = Rect.fromLTRB(x - 23 * u, topo - 4 * u, x + 23 * u, topo);
    p.ret(viga, const Color(0xFF2E3240), contorno: 1, raio: .5 * u);
    for (var i = 0; i < 5; i++) {
      final o = Offset(x + (i - 2) * 3.4 * u, topo - 2 * u);
      p.circ(o, 1.1 * u, const Color(0xFFFF3B30), contorno: .4, emite: true);
      if (p.acesas) p.brilho(o, 3 * u, const Color(0xFFFF3B30), alfa: .5);
    }
  });
}

// ═══════════════════════════════════════════ interiores ═══════════════════════════════════════════

/// Parede de [cor] do topo até o horizonte, vazada nas [janelas] (o céu aparece por elas).
void _parede(_Pincel p, Color cor, List<RRect> janelas) {
  final path = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTRB(-2, -2, p.w + 2, p.hz));
  for (final j in janelas) {
    path.addRRect(j);
  }
  p.c.drawPath(path, p.tinta(cor));
}

/// Caixilho de janela: moldura grossa com contorno e, se [cruz], travessas no meio.
void _moldura(_Pincel p, RRect j, Color cor, {bool cruz = true}) {
  final u = p.u;
  final grossa = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4 * u
    ..color = p.luz(cor);
  p.c.drawRRect(j, grossa);
  p.c.drawRRect(j.inflate(.7 * u), p.traco(.6));
  p.c.drawRRect(j.deflate(.7 * u), p.traco(.4));
  if (cruz) {
    final r = j.outerRect;
    p.tubos([
      Path()
        ..moveTo(r.center.dx, r.top)
        ..lineTo(r.center.dx, r.bottom),
      Path()
        ..moveTo(r.left, r.center.dy)
        ..lineTo(r.right, r.center.dy),
    ], .8 * u, cor, contorno: .4);
  }
}

/// Luz geral de interior à noite (abajur/lâmpada): um halo quente.
void _luzQuente(_Pincel p, Offset o, double r, {double forca = 1}) {
  final alfa = p.noite ? .45 : (p.hora == HoraHistoria.tarde ? .28 : .14);
  p.brilho(o, r, const Color(0xFFFFD08A), alfa: alfa * forca);
}

void _aviao(_Pincel p, double x, double base, double comp) {
  final alt = comp * .16;
  const roxo = Color(0xFF6A3FB5);
  p.forma(
      Path()
        ..moveTo(x - comp * .02, base - alt * .55)
        ..lineTo(x - comp * .12, base - alt * 1.5)
        ..lineTo(x - comp * .2, base - alt * 1.5)
        ..lineTo(x - comp * .16, base - alt * .55)
        ..close(),
      const Color(0xFFB0B8C4),
      contorno: .5);
  p.forma(
      Path()
        ..moveTo(x - comp * .5, base - alt * .9)
        ..lineTo(x - comp * .5, base - alt * 2.5)
        ..lineTo(x - comp * .42, base - alt * 2.5)
        ..lineTo(x - comp * .3, base - alt * .9)
        ..close(),
      roxo,
      contorno: .5);
  final corpo = Path()
    ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - comp / 2, base - alt, comp, alt), Radius.circular(alt / 2)));
  p.forma(corpo, const Color(0xFFF5F7FA), contorno: .6);
  p.c.save();
  p.c.clipPath(corpo);
  p.c.drawRect(Rect.fromLTWH(x - comp / 2, base - alt * .42, comp, alt * .14), p.tinta(roxo));
  p.c.drawRect(Rect.fromLTWH(x - comp / 2, base - alt * .3, comp, alt * .3), Paint()..color = const Color(0x1A301A40));
  p.c.restore();
  final janela = p.tinta(const Color(0xFF3D5A80));
  for (var i = 0; i < 9; i++) {
    p.c.drawCircle(Offset(x - comp * .32 + i * comp * .07, base - alt * .66), alt * .09, janela);
  }
  p.c.drawPath(
      Path()
        ..moveTo(x + comp * .42, base - alt * .78)
        ..lineTo(x + comp * .48, base - alt * .6)
        ..lineTo(x + comp * .4, base - alt * .6)
        ..close(),
      janela);
  p.forma(
      Path()
        ..moveTo(x + comp * .04, base - alt * .4)
        ..lineTo(x - comp * .2, base + alt * .5)
        ..lineTo(x - comp * .28, base + alt * .5)
        ..lineTo(x - comp * .12, base - alt * .4)
        ..close(),
      const Color(0xFFC6CDD6),
      contorno: .5);
  for (final dx in [-.3, .3]) {
    p.circ(Offset(x + comp * dx, base + alt * .12), alt * .13, const Color(0xFF2E2E34), contorno: .3);
  }
}

void _painelEmbarque(_Pincel p, Rect r) {
  final u = p.u;
  p.c.drawLine(Offset(r.left + 2 * u, -2), Offset(r.left + 2 * u, r.top), p.traco(.4));
  p.c.drawLine(Offset(r.right - 2 * u, -2), Offset(r.right - 2 * u, r.top), p.traco(.4));
  p.ret(r, const Color(0xFF1F2636), contorno: .9, raio: .6 * u);
  final lins = 4;
  final ch = (r.height - 2 * u) / lins;
  for (var i = 0; i < lins; i++) {
    final y = r.top + u + i * ch + ch * .25;
    final pisca = i == ((p.t * .8).floor() % lins);
    p.c.drawRect(Rect.fromLTWH(r.left + u, y, ch * .5, ch * .5),
        Paint()..color = i.isEven ? const Color(0xFF4DD68C) : const Color(0xFFFFB13D));
    p.c.drawRect(Rect.fromLTWH(r.left + u + ch * .8, y, r.width * .48, ch * .5),
        Paint()..color = const Color(0xFFE8ECF2).withValues(alpha: pisca ? .55 : .9));
    p.c.drawRect(Rect.fromLTWH(r.right - u - r.width * .2, y, r.width * .2, ch * .5),
        Paint()..color = const Color(0xFFFFB13D));
  }
}

void _cadeiras(_Pincel p, double cx, double base, int n) {
  final u = p.u;
  final sw = 4.6 * u;
  final total = n * sw;
  final x0 = cx - total / 2;
  p.tubos([
    Path()
      ..moveTo(x0 + u, base)
      ..lineTo(x0 + u, base - 3.4 * u),
    Path()
      ..moveTo(x0 + total - u, base)
      ..lineTo(x0 + total - u, base - 3.4 * u),
  ], .6 * u, const Color(0xFF8D99A8), contorno: .6);
  p.ret(Rect.fromLTWH(x0, base - 3.6 * u, total, .8 * u), const Color(0xFF8D99A8), contorno: .6);
  for (var i = 0; i < n; i++) {
    final x = x0 + i * sw;
    p.ret(Rect.fromLTWH(x + .3 * u, base - 9.4 * u, sw - .6 * u, 5.4 * u), const Color(0xFF3E6FD0),
        contorno: .7, raio: .9 * u);
    p.ret(Rect.fromLTWH(x + .15 * u, base - 4.6 * u, sw - .3 * u, 1.4 * u), const Color(0xFF2F58AE),
        contorno: .7, raio: .5 * u);
  }
}

void _dAeroporto(_Pincel p) {
  final u = p.u;
  final topo = 9 * u, base = p.hz - 8 * u;
  _Onda(p, base - 4 * u, 3 * u, const [(1.1, 1.0, .4), (2.6, .4, 1.0)])
      .pinta(const Color(0xFF93BE8C), fundo: base, contorno: .3);
  p.faixa(base - 2.6 * u, base, const Color(0xFF8E939C), contorno: .3);
  final n = p.vezes(8 * u);
  for (var i = 0; i < n; i++) {
    p.c.drawRect(Rect.fromLTWH(i * p.w / n, base - 1.5 * u, p.w / n * .5, .4 * u), p.tinta(_branco, alfa: .8));
  }
  p.laco(p.w * .62, 9 * u, (x) => _aviao(p, x, base - 2.2 * u, 16 * u));
  _parede(p, const Color(0xFFE3EAF1), [RRect.fromLTRBR(-2, topo, p.w + 2, base, Radius.zero)]);
  final reflexo = Paint()..color = const Color(0x1CFFFFFF);
  final m = p.vezes(30 * u);
  for (var i = 0; i < m; i++) {
    final x = (i + .5) * p.w / m;
    p.laco(x, 9 * u, (x) => p.c.drawPath(
        Path()
          ..moveTo(x, topo)
          ..lineTo(x + 5 * u, topo)
          ..lineTo(x - 3 * u, base)
          ..lineTo(x - 8 * u, base)
          ..close(),
        reflexo));
  }
  p.faixa(topo - 1.2 * u, topo, _metal, contorno: .6);
  p.faixa(base, base + 1.4 * u, _metal, contorno: .6);
  final k = p.vezes(24 * u);
  for (var i = 0; i < k; i++) {
    p.laco(i * p.w / k, u, (x) => p.ret(Rect.fromLTWH(x - .7 * u, topo, 1.4 * u, base - topo), _metal, contorno: .6));
  }
  final luzes = p.vezes(18 * u);
  for (var i = 0; i < luzes; i++) {
    final o = Offset((i + .5) * p.w / luzes, 3.4 * u);
    p.c.drawOval(Rect.fromCenter(center: o, width: 4 * u, height: 1 * u), Paint()..color = const Color(0xFFFFF6DC));
    if (p.acesas) p.brilho(o, 5 * u, const Color(0xFFFFF0C0), alfa: .4);
  }
  p.laco(p.w * .26, 10 * u, (x) => _painelEmbarque(p, Rect.fromLTWH(x - 9 * u, 5 * u, 18 * u, 10 * u)));
  p.faixa(p.hz - 1 * u, p.hz, const Color(0xFF9AA6B4), contorno: .5);
}

void _cAeroporto(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFD9E1EA), Color(0xFFB2BECC)]);
  final r = Rect.fromLTRB(-2, p.hz, p.w + 2, p.hz + 8 * u);
  p.c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_branco.withValues(alpha: p.noite ? .12 : .4), const Color(0x00FFFFFF)],
        ).createShader(r));
  final junta = Paint()
    ..strokeWidth = .25 * u
    ..color = const Color(0x333A2A33);
  for (final f in [4.0, 9.0, 15.0, 22.0]) {
    p.c.drawLine(Offset(-2, p.hz + f * u), Offset(p.w + 2, p.hz + f * u), junta);
  }
  final n = p.vezes(16 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, p.hz), Offset(x, p.h), junta);
  }
  p.laco(p.w * .3, 11 * u, (x) => _cadeiras(p, x, p.hz + 7 * u, 4));
  if (p.w > 70 * u) p.laco(p.w * .78, 8 * u, (x) => _cadeiras(p, x, p.hz + 7 * u, 3));
}

void _lampadaPendurada(_Pincel p, double x, double comprimento) {
  final u = p.u;
  final ang = math.sin(p.t * 1.1) * .035;
  final ponta = Offset(x + math.sin(ang) * comprimento, math.cos(ang) * comprimento);
  p.c.drawLine(Offset(x, -2), ponta, p.traco(.45));
  _luzQuente(p, ponta.translate(0, 2 * u), 30 * u);
  p.forma(
      Path()
        ..moveTo(ponta.dx - 1 * u, ponta.dy)
        ..lineTo(ponta.dx + 1 * u, ponta.dy)
        ..lineTo(ponta.dx + 3.4 * u, ponta.dy + 2.6 * u)
        ..lineTo(ponta.dx - 3.4 * u, ponta.dy + 2.6 * u)
        ..close(),
      const Color(0xFF3F7A5A),
      contorno: .7);
  p.c.drawCircle(ponta.translate(0, 2.9 * u), .9 * u, Paint()..color = const Color(0xFFFFF3C4));
}

void _dGaragem(_Pincel p) {
  final u = p.u;
  final janelas = <RRect>[];
  final n = p.vezes(30 * u);
  for (var i = 0; i < n; i++) {
    p.laco((i + .5) * p.w / n, 6 * u,
        (x) => janelas.add(RRect.fromLTRBR(x - 6 * u, 5 * u, x + 6 * u, 11 * u, Radius.circular(.4 * u))));
  }
  _parede(p, const Color(0xFFAFB8C4), janelas);
  for (final j in janelas) {
    _moldura(p, j, const Color(0xFF7C8796));
  }
  p.faixa(p.hz - 14 * u, p.hz, const Color(0xFF8D97A5), contorno: .5, baixo: false);
  // porta de enrolar
  p.laco(p.w * .74, 16 * u, (x) {
    final r = Rect.fromLTRB(x - 15 * u, 15 * u, x + 15 * u, p.hz);
    p.ret(Rect.fromLTRB(r.left - 1.2 * u, r.top - 2.6 * u, r.right + 1.2 * u, r.bottom), const Color(0xFF6A7380),
        contorno: .8);
    p.ret(r, const Color(0xFFBCC3CB), contorno: .7);
    final friso = p.traco(.3);
    for (var y = r.top + 2 * u; y < r.bottom; y += 2.2 * u) {
      p.c.drawLine(Offset(r.left, y), Offset(r.right, y), friso);
    }
    p.ret(Rect.fromCenter(center: Offset(x, r.bottom - 3 * u), width: 6 * u, height: 1 * u), const Color(0xFF4A5060),
        contorno: .5, raio: .4 * u);
  });
  // quadro de ferramentas e bancada
  p.laco(p.w * .26, 15 * u, (x) {
    final quadro = Rect.fromLTWH(x - 13 * u, 17 * u, 26 * u, 14 * u);
    p.ret(quadro, const Color(0xFFD4A86C), contorno: .8, raio: .4 * u);
    final furo = p.tinta(const Color(0xFF9A7240));
    for (var i = 1; i < 13; i++) {
      for (var j = 1; j < 7; j++) {
        p.c.drawCircle(Offset(quadro.left + i * 2 * u, quadro.top + j * 2 * u), .18 * u, furo);
      }
    }
    // chave inglesa, martelo, chave de fenda
    p.tubos([
      Path()
        ..moveTo(quadro.left + 4 * u, quadro.top + 3 * u)
        ..lineTo(quadro.left + 4 * u, quadro.top + 11 * u)
    ], 1 * u, const Color(0xFFB8C0CA), contorno: .5);
    p.circ(Offset(quadro.left + 4 * u, quadro.top + 3 * u), 1.4 * u, const Color(0xFFB8C0CA), contorno: .5);
    p.tubos([
      Path()
        ..moveTo(quadro.left + 10 * u, quadro.top + 3.6 * u)
        ..lineTo(quadro.left + 10 * u, quadro.top + 12 * u)
    ], .9 * u, const Color(0xFF8A5A3A), contorno: .5);
    p.ret(Rect.fromLTWH(quadro.left + 7.6 * u, quadro.top + 2.4 * u, 4.8 * u, 1.8 * u), const Color(0xFF7C8494),
        contorno: .5, raio: .3 * u);
    p.tubos([
      Path()
        ..moveTo(quadro.left + 16 * u, quadro.top + 3 * u)
        ..lineTo(quadro.left + 16 * u, quadro.top + 7 * u)
    ], 1.3 * u, const Color(0xFFE53935), contorno: .5);
    p.c.drawLine(Offset(quadro.left + 16 * u, quadro.top + 7 * u), Offset(quadro.left + 16 * u, quadro.top + 11.5 * u),
        p.traco(.5));
    p.tubos([
      Path()
        ..moveTo(quadro.left + 21 * u, quadro.top + 3 * u)
        ..lineTo(quadro.left + 21 * u, quadro.top + 9 * u)
    ], 1.1 * u, const Color(0xFFB8C0CA), contorno: .5);
    p.circ(Offset(quadro.left + 21 * u, quadro.top + 10.5 * u), 1.6 * u, const Color(0xFFB8C0CA), contorno: .5);
    final tampo = Rect.fromLTWH(x - 14 * u, p.hz - 9 * u, 28 * u, 1.6 * u);
    p.tubos([
      Path()
        ..moveTo(tampo.left + 1.5 * u, tampo.bottom)
        ..lineTo(tampo.left + 1.5 * u, p.hz),
      Path()
        ..moveTo(tampo.right - 1.5 * u, tampo.bottom)
        ..lineTo(tampo.right - 1.5 * u, p.hz),
    ], .9 * u, const Color(0xFF4A5060), contorno: .5);
    p.ret(tampo, const Color(0xFFA0703E), contorno: .8);
    p.ret(Rect.fromLTWH(x - 11 * u, tampo.top - 3.6 * u, 7 * u, 3.6 * u), const Color(0xFFD9433A), contorno: .7,
        raio: .4 * u);
    p.ret(Rect.fromLTWH(x + 3 * u, tampo.top - 3 * u, 2.6 * u, 3 * u), const Color(0xFF3E8AE0), contorno: .6);
    p.ret(Rect.fromLTWH(x + 6.2 * u, tampo.top - 2.4 * u, 2.4 * u, 2.4 * u), const Color(0xFFFFC928), contorno: .6);
  });
  p.laco(p.w * .5, 4 * u, (x) => _lampadaPendurada(p, x, 11 * u));
  p.faixa(p.hz - 1 * u, p.hz, const Color(0xFF6A7380), contorno: .5);
}

void _cGaragem(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFA3A39F), Color(0xFF7F7F7B)]);
  final junta = p.traco(.3);
  final n = p.vezes(20 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, p.hz), Offset(x - 3 * u, p.h), junta);
  }
  p.c.drawLine(Offset(-2, p.hz + 10 * u), Offset(p.w + 2, p.hz + 10 * u), junta);
  p.laco(p.w * .58, 6 * u, (x) => p.c.drawOval(
      Rect.fromCenter(center: Offset(x, p.hz + 13 * u), width: 10 * u, height: 2.2 * u), Paint()..color = const Color(0x40201A1A)));
  final k = p.vezes(56 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .07) / k * p.w, 3 * u, (x) => _pneus(p, x, p.hz + 17 * u, 2.4 * u, 4));
    p.laco((i + .93) / k * p.w, 3 * u, (x) => _pneus(p, x, p.hz + 16 * u, 2.4 * u, 3));
  }
}

void _dHotel(_Pincel p) {
  final u = p.u;
  // lá fora: a cidade
  final n = p.vezes(5 * u);
  for (var i = 0; i < n; i++) {
    final alt = (8 + 12 * _ruido(i * 7 + 501)) * u;
    final r = Rect.fromLTWH(i * p.w / n, p.hz - 16 * u - alt, p.w / n * .92, alt + 2 * u);
    p.c.drawRect(r, p.tinta(const Color(0xFF8C9DB8)));
    if (p.noite) {
      for (var j = 0; j < 3; j++) {
        if (_ruido(i * 13 + j) > .5) {
          p.c.drawRect(Rect.fromLTWH(r.left + r.width * .3, r.top + (1.5 + j * 2.6) * u, r.width * .3, .9 * u),
              Paint()..color = const Color(0xDDFFE08A));
        }
      }
    }
  }
  final janelas = <RRect>[];
  p.laco(p.w * .64, 14 * u,
      (x) => janelas.add(RRect.fromLTRBR(x - 12 * u, 12 * u, x + 12 * u, p.hz - 14 * u, Radius.circular(.6 * u))));
  _parede(p, const Color(0xFFEBD9C2), janelas);
  // papel de parede listrado (fora das janelas)
  p.c.save();
  p.c.clipPath(Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTRB(-2, -2, p.w + 2, p.hz))
    ..addRRect(janelas.isEmpty ? RRect.zero : janelas.first)
    ..addRRect(janelas.length > 1 ? janelas[1] : RRect.zero));
  final listra = p.tinta(const Color(0xFFDCC4A6));
  final m = p.vezes(4 * u);
  for (var i = 0; i < m; i++) {
    p.c.drawRect(Rect.fromLTWH(i * p.w / m, -2, p.w / m * .35, p.hz + 2), listra);
  }
  p.c.restore();
  for (final j in janelas) {
    _moldura(p, j, _branco);
  }
  // cortinas
  p.laco(p.w * .64, 18 * u, (x) {
    p.tubos([
      Path()
        ..moveTo(x - 17 * u, 10 * u)
        ..lineTo(x + 17 * u, 10 * u)
    ], .7 * u, const Color(0xFF8A5A3A), contorno: .5);
    for (final lado in [-1.0, 1.0]) {
      final xa = x + lado * 11 * u, xb = x + lado * 17 * u;
      final cortina = Path()
        ..moveTo(xa, 10 * u)
        ..lineTo(xb, 10 * u)
        ..lineTo(xb, p.hz - 10 * u)
        ..quadraticBezierTo((xa + xb) / 2 + lado * u, p.hz - 12 * u, xa + lado * 1.6 * u, p.hz - 10 * u)
        ..quadraticBezierTo(xa - lado * .6 * u, (10 * u + p.hz) / 2, xa, 10 * u)
        ..close();
      p.forma(cortina, const Color(0xFF7B4FA0), contorno: .8);
      final dobra = p.traco(.3);
      for (var d = 1; d < 3; d++) {
        final xd = xa + (xb - xa) * d / 3;
        p.c.drawLine(Offset(xd, 11 * u), Offset(xd, p.hz - 11 * u), dobra);
      }
    }
  });
  // quadro na parede
  p.laco(p.w * .2, 7 * u, (x) {
    final q = Rect.fromLTWH(x - 6 * u, 16 * u, 12 * u, 9 * u);
    p.ret(q.inflate(.8 * u), const Color(0xFFB8893E), contorno: .8);
    p.c.drawRect(q, p.tinta(const Color(0xFF9FD3F5)));
    p.c.drawPath(
        Path()
          ..moveTo(q.left, q.bottom)
          ..lineTo(q.left + q.width * .35, q.top + q.height * .4)
          ..lineTo(q.left + q.width * .6, q.top + q.height * .7)
          ..lineTo(q.left + q.width * .8, q.top + q.height * .5)
          ..lineTo(q.right, q.bottom)
          ..close(),
        p.tinta(const Color(0xFF6FAE5E)));
    p.c.drawCircle(Offset(q.right - 2.4 * u, q.top + 2.2 * u), 1.2 * u, p.tinta(const Color(0xFFFFD54F)));
  });
  p.faixa(p.hz - 1.4 * u, p.hz, const Color(0xFF8A5A3A), contorno: .5);
}

void _cHotel(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFB98A5A), Color(0xFF9A6E44)]);
  final tabua = p.traco(.25);
  for (var i = 1; i < 8; i++) {
    final y = p.hz + i * i * .6 * u;
    p.c.drawLine(Offset(-2, y), Offset(p.w + 2, y), tabua);
  }
  final n = p.vezes(12 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5 * (i % 2)) * p.w / n;
    p.c.drawLine(Offset(x, p.hz + 3 * u), Offset(x, p.hz + 6 * u), tabua);
  }
  p.laco(p.w * .5, 24 * u, (x) => p.forma(
      Path()..addOval(Rect.fromCenter(center: Offset(x, p.hz + 15 * u), width: 44 * u, height: 7 * u)),
      const Color(0xFFC0504D),
      contorno: .6));
  // cama
  p.laco(p.w * .22, 20 * u, (x) {
    final cabeceira = Rect.fromLTWH(x - 17 * u, p.hz - 11 * u, 6 * u, 18 * u);
    p.ret(cabeceira, const Color(0xFF7A4E2E), contorno: 1, raio: 1.4 * u);
    final colchao = Rect.fromLTWH(x - 13 * u, p.hz + 1 * u, 30 * u, 6 * u);
    p.ret(colchao, const Color(0xFFF4F1EA), contorno: 1, raio: 1 * u);
    p.ret(Rect.fromLTWH(x - 12.5 * u, p.hz - 1.6 * u, 7 * u, 3 * u), _branco, contorno: .8, raio: 1.4 * u);
    final coberta = Path()
      ..moveTo(x - 5 * u, p.hz)
      ..lineTo(x + 17.5 * u, p.hz)
      ..lineTo(x + 17.5 * u, p.hz + 8.5 * u)
      ..lineTo(x - 4 * u, p.hz + 8.5 * u)
      ..close();
    p.forma(coberta, const Color(0xFF6A3FB5), contorno: 1);
    p.sombra(coberta, Rect.fromLTRB(x - 5 * u, p.hz + 6 * u, x + 18 * u, p.hz + 9 * u), alfa: .2);
    p.c.drawLine(Offset(x - 5 * u, p.hz + 2.2 * u), Offset(x + 17.5 * u, p.hz + 2.2 * u),
        Paint()
          ..strokeWidth = .7 * u
          ..color = p.luz(const Color(0xFFFFD54F)));
    p.ret(Rect.fromLTWH(x + 16 * u, p.hz + 7 * u, 1.2 * u, 2.4 * u), const Color(0xFF7A4E2E), contorno: .6);
    // criado-mudo e abajur
    final mx = x - 23 * u;
    p.ret(Rect.fromLTWH(mx - 3.5 * u, p.hz - 1 * u, 7 * u, 8 * u), const Color(0xFF8A5A3A), contorno: .9, raio: .4 * u);
    p.c.drawLine(Offset(mx - 3.5 * u, p.hz + 3 * u), Offset(mx + 3.5 * u, p.hz + 3 * u), p.traco(.4));
    p.c.drawCircle(Offset(mx, p.hz + 1.2 * u), .4 * u, p.tinta(const Color(0xFFFFD54F)));
    p.c.drawLine(Offset(mx, p.hz - 1 * u), Offset(mx, p.hz - 5 * u), p.traco(.6));
    final cupula = Path()
      ..moveTo(mx - 1.6 * u, p.hz - 9 * u)
      ..lineTo(mx + 1.6 * u, p.hz - 9 * u)
      ..lineTo(mx + 3 * u, p.hz - 5 * u)
      ..lineTo(mx - 3 * u, p.hz - 5 * u)
      ..close();
    if (p.acesas) _luzQuente(p, Offset(mx, p.hz - 6 * u), 22 * u, forca: 1.3);
    p.forma(cupula, p.acesas ? const Color(0xFFFFE6A8) : const Color(0xFFF2E2C4), contorno: .8, emite: p.acesas);
  });
  // mala
  p.laco(p.w * .84, 6 * u, (x) {
    final mala = Rect.fromLTWH(x - 3.6 * u, p.hz + 2 * u, 7.2 * u, 9 * u);
    p.c.drawPath(
        Path()
          ..moveTo(x - 1.4 * u, mala.top)
          ..lineTo(x - 1.4 * u, mala.top - 2 * u)
          ..lineTo(x + 1.4 * u, mala.top - 2 * u)
          ..lineTo(x + 1.4 * u, mala.top),
        p.traco(.8));
    p.ret(mala, const Color(0xFFE07B39), contorno: 1, raio: .8 * u);
    p.c.drawLine(Offset(mala.left, mala.top + 2.4 * u), Offset(mala.right, mala.top + 2.4 * u), p.traco(.4));
    p.circ(Offset(x + 1 * u, mala.top + 5.4 * u), 1.1 * u, const Color(0xFF29B6F6), contorno: .4);
    p.ret(Rect.fromLTWH(x - 2.8 * u, mala.top + 4 * u, 2.2 * u, 1.4 * u), const Color(0xFFFFD54F), contorno: .4);
  });
}

void _dCafe(_Pincel p) {
  final u = p.u;
  // lá fora: a pista
  p.faixa(p.hz - 30 * u, p.hz, const Color(0xFF7DBE66), contorno: 0);
  p.faixa(p.hz - 26 * u, p.hz - 20 * u, const Color(0xFF8A8D95), contorno: .3);
  final branco = p.tinta(_branco, alfa: .8);
  final m = p.vezes(8 * u);
  for (var i = 0; i < m; i++) {
    p.c.drawRect(Rect.fromLTWH(i * p.w / m, p.hz - 23.3 * u, p.w / m * .45, .5 * u), branco);
  }
  _Onda(p, p.hz - 30 * u, 3 * u, const [(1.2, 1.0, 0.0)]).pinta(const Color(0xFF9CC98A), fundo: p.hz - 26 * u, contorno: .3);
  _cerca(p, p.hz - 16 * u, 3 * u, const Color(0xFFF2E6D2));
  final janelas = <RRect>[];
  final n = p.vezes(50 * u);
  final passo = p.w / n;
  for (var i = 0; i < n; i++) {
    p.laco((i + .5) * passo, 12 * u,
        (x) => janelas.add(RRect.fromLTRBR(x - 11 * u, 9 * u, x + 11 * u, p.hz - 14 * u, Radius.circular(1.2 * u))));
  }
  _parede(p, const Color(0xFFF4E3C8), janelas);
  for (final j in janelas) {
    _moldura(p, j, const Color(0xFF8A5A3A));
  }
  // lambri
  p.faixa(p.hz - 12 * u, p.hz, const Color(0xFFA0703E), contorno: .6, baixo: false);
  final painel = p.traco(.3);
  final k = p.vezes(6 * u);
  for (var i = 0; i < k; i++) {
    final x = i * p.w / k;
    p.c.drawRect(Rect.fromLTWH(x + .8 * u, p.hz - 10.5 * u, p.w / k - 1.6 * u, 8.5 * u), painel);
  }
  // prateleiras com xícaras entre as janelas
  for (var i = 0; i < n; i++) {
    p.laco(i * passo, 8 * u, (x) {
      for (final y in [18 * u, 27 * u]) {
        p.ret(Rect.fromLTWH(x - 7 * u, y, 14 * u, .9 * u), const Color(0xFF8A5A3A), contorno: .5);
        for (var c = 0; c < 4; c++) {
          final cx = x - 5.2 * u + c * 3.4 * u;
          final cor = _publico[(c + (y > 20 * u ? 2 : 0)) % 6];
          p.ret(Rect.fromLTWH(cx - 1 * u, y - 2.2 * u, 2 * u, 2.2 * u), cor, contorno: .4, raio: .5 * u);
          p.c.drawArc(Rect.fromLTWH(cx + .6 * u, y - 1.8 * u, 1.2 * u, 1.2 * u), -math.pi / 2, math.pi, false, p.traco(.35));
        }
      }
    });
  }
  // luminárias pendentes
  for (var i = 0; i < n; i++) {
    p.laco((i + .5) * passo, 4 * u, (x) {
      p.c.drawLine(Offset(x, -2), Offset(x, 4 * u), p.traco(.4));
      _luzQuente(p, Offset(x, 7 * u), 22 * u);
      p.forma(
          Path()
            ..moveTo(x - 3 * u, 6.4 * u)
            ..quadraticBezierTo(x, 2.6 * u, x + 3 * u, 6.4 * u)
            ..close(),
          const Color(0xFFE07B39),
          contorno: .7);
      p.c.drawCircle(Offset(x, 6.8 * u), .7 * u, Paint()..color = const Color(0xFFFFF3C4));
    });
  }
}

void _cCafe(_Pincel p) {
  final u = p.u;
  // piso quadriculado (fundo chapado por baixo: as emendas entre ladrilhos não vazam)
  p.solo(const [Color(0xFFE0D3BC), Color(0xFFE0D3BC)], contorno: 0);
  const linhas = 6;
  final altura = p.h - p.hz;
  var y = p.hz;
  final cols = p.vezesPar(5 * u);
  for (var l = 0; l < linhas; l++) {
    final hL = altura * (l + 1) / (linhas * (linhas + 1) / 2);
    for (var c = 0; c < cols; c++) {
      p.c.drawRect(Rect.fromLTWH(c * p.w / cols, y, p.w / cols + .5, hL + .5),
          p.tinta((c + l).isEven ? const Color(0xFFEDE2CE) : const Color(0xFFD4C4AA)));
    }
    y += hL;
  }
  p.c.drawLine(Offset(-2, p.hz), Offset(p.w + 2, p.hz), p.traco(.5));
  // balcão e banquetas
  p.laco(p.w * .3, 24 * u, (x) {
    final frente = Rect.fromLTRB(x - 22 * u, p.hz + 3.4 * u, x + 22 * u, p.hz + 13 * u);
    // máquina de café e bolo em cima
    p.ret(Rect.fromLTWH(x - 19 * u, p.hz - 4 * u, 7 * u, 6 * u), const Color(0xFFB8C0CA), contorno: .8, raio: .6 * u);
    p.ret(Rect.fromLTWH(x - 17.6 * u, p.hz - 1 * u, 4.2 * u, 1 * u), const Color(0xFF3A4152), contorno: .4);
    p.circ(Offset(x - 15.5 * u, p.hz - 2.6 * u), .6 * u, const Color(0xFFE53935), contorno: .3);
    final cupula = Path()
      ..moveTo(x + 8 * u, p.hz + 2 * u)
      ..quadraticBezierTo(x + 8 * u, p.hz - 5 * u, x + 12 * u, p.hz - 5 * u)
      ..quadraticBezierTo(x + 16 * u, p.hz - 5 * u, x + 16 * u, p.hz + 2 * u)
      ..close();
    p.ret(Rect.fromLTWH(x + 9 * u, p.hz - 1 * u, 6 * u, 3 * u), const Color(0xFFF2C0D0), contorno: .6, raio: .5 * u);
    p.c.drawRect(Rect.fromLTWH(x + 9 * u, p.hz - .2 * u, 6 * u, .6 * u), p.tinta(const Color(0xFF8A4A3A)));
    p.forma(cupula, const Color(0x55DDF2FF), contorno: .6);
    for (var c = 0; c < 3; c++) {
      p.ret(Rect.fromLTWH(x - 6 * u + c * 3.2 * u, p.hz, 2 * u, 2 * u), _branco, contorno: .4, raio: .4 * u);
    }
    p.ret(Rect.fromLTRB(x - 23 * u, p.hz + 2 * u, x + 23 * u, p.hz + 3.4 * u), const Color(0xFF6E4A2E), contorno: .9);
    p.ret(frente, const Color(0xFFC0824A), contorno: 1);
    final painel = p.traco(.35);
    for (var i = 0; i < 4; i++) {
      p.c.drawRect(Rect.fromLTWH(frente.left + 1 * u + i * 11 * u, frente.top + 1 * u, 9 * u, frente.height - 2 * u), painel);
    }
    p.sombra(Path()..addRect(frente), Rect.fromLTRB(frente.left, frente.bottom - 1.5 * u, frente.right, frente.bottom));
    for (var i = 0; i < 3; i++) {
      final bx = x - 14 * u + i * 14 * u;
      final base = p.hz + 17 * u;
      p.tubos([
        Path()
          ..moveTo(bx, base)
          ..lineTo(bx, base - 6 * u)
      ], .7 * u, const Color(0xFF8D99A8), contorno: .6);
      p.c.drawOval(Rect.fromCenter(center: Offset(bx, base), width: 4 * u, height: 1 * u), p.tinta(const Color(0xFF6A7380)));
      p.ret(Rect.fromCenter(center: Offset(bx, base - 6.4 * u), width: 5 * u, height: 1.4 * u), const Color(0xFFD9433A),
          contorno: .8, raio: .7 * u);
    }
  });
}

void _dClinica(_Pincel p) {
  final u = p.u;
  // lá fora (aparece pela porta da tenda)
  p.faixa(p.hz - 10 * u, p.hz, const Color(0xFF7DBE66), contorno: 0);
  final portas = <RRect>[];
  p.laco(p.w * .82, 10 * u, (x) => portas.add(RRect.fromLTRBR(x - 7 * u, 16 * u, x + 7 * u, p.hz, Radius.zero)));
  final lona = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTRB(-2, -2, p.w + 2, p.hz));
  for (final r in portas) {
    final x = r.outerRect.center.dx;
    lona.addPath(
        Path()
          ..moveTo(x, 12 * u)
          ..lineTo(x + 7 * u, p.hz)
          ..lineTo(x - 7 * u, p.hz)
          ..close(),
        Offset.zero);
  }
  p.c.drawPath(lona, p.tinta(const Color(0xFFF0F2EA)));
  // costuras e mastros
  final costura = p.traco(.25);
  final n = p.vezes(14 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, 6 * u), Offset(x, p.hz), costura);
  }
  final k = p.vezes(44 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .02) / k * p.w, u, (x) => p.tubos([
          Path()
            ..moveTo(x, 5 * u)
            ..lineTo(x, p.hz)
        ], .8 * u, const Color(0xFF9AA3AE), contorno: .5));
  }
  // abas da porta
  for (final r in portas) {
    final x = r.outerRect.center.dx;
    for (final lado in [-1.0, 1.0]) {
      p.forma(
          Path()
            ..moveTo(x, 12 * u)
            ..lineTo(x + lado * 7 * u, p.hz)
            ..lineTo(x + lado * 10 * u, p.hz)
            ..close(),
          const Color(0xFFDDE3D2),
          contorno: .7);
    }
  }
  // sanefa verde recortada
  final recorte = Path()..moveTo(p.w + 2, 4 * u);
  final m = p.vezes(5 * u);
  recorte.lineTo(p.w, 4 * u);
  for (var i = m; i > 0; i--) {
    final a = i * p.w / m;
    recorte.quadraticBezierTo(a - p.w / m / 2, 7.4 * u, a - p.w / m, 4 * u);
  }
  recorte.lineTo(-2, 4 * u);
  final sanefa = Path.from(recorte)
    ..lineTo(-2, -2)
    ..lineTo(p.w + 2, -2)
    ..close();
  p.c.drawPath(sanefa, p.tinta(const Color(0xFF2EAD5B)));
  p.c.drawPath(recorte, p.traco(.7));
  // cruz verde
  p.laco(p.w * .4, 8 * u, (x) {
    final o = Offset(x, 22 * u);
    p.circ(o, 7 * u, _branco, contorno: .8);
    final b = 2.4 * u, l = 4.8 * u;
    final cruz = Path()
      ..addRect(Rect.fromCenter(center: o, width: b, height: l * 2))
      ..addRect(Rect.fromCenter(center: o, width: l * 2, height: b));
    p.c.drawPath(cruz, p.tinta(const Color(0xFF2EAD5B)));
    p.c.drawPath(
        Path.combine(PathOperation.union, Path()..addRect(Rect.fromCenter(center: o, width: b, height: l * 2)),
            Path()..addRect(Rect.fromCenter(center: o, width: l * 2, height: b))),
        p.traco(.6));
  });
  // armário de remédios
  p.laco(p.w * .1, 7 * u, (x) {
    final r = Rect.fromLTRB(x - 6 * u, p.hz - 22 * u, x + 6 * u, p.hz);
    p.ret(r, const Color(0xFFF7F8FA), contorno: 1, raio: .5 * u);
    for (final y in [r.top + 1 * u, r.top + 10.5 * u]) {
      p.ret(Rect.fromLTWH(r.left + 1 * u, y, r.width - 2 * u, 8.5 * u), const Color(0xFFCDEAF5), contorno: .5);
      for (var i = 0; i < 4; i++) {
        p.ret(Rect.fromLTWH(r.left + 1.6 * u + i * 2.4 * u, y + 4.5 * u, 1.4 * u, 3 * u), _publico[(i + (y > r.top + 2 * u ? 3 : 0)) % 8],
            contorno: .3, raio: .3 * u);
      }
      p.c.drawLine(Offset(r.left + 1 * u, y + 8 * u), Offset(r.right - 1 * u, y + 8 * u), p.traco(.3));
    }
  });
  _luzQuente(p, Offset(p.w * .5, 8 * u), 34 * u, forca: .8);
}

void _cClinica(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFCBD1BC), Color(0xFFAEB59E)]);
  final costura = p.traco(.25);
  final n = p.vezes(18 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, p.hz), Offset(x - 4 * u, p.h), costura);
  }
  // maca
  p.laco(p.w * .64, 14 * u, (x) {
    final base = p.hz + 12 * u;
    for (final dx in [-10.0, 10.0]) {
      p.tubos([
        Path()
          ..moveTo(x + dx * u, base - 1 * u)
          ..lineTo(x + dx * u, base - 7 * u)
      ], .6 * u, const Color(0xFFB8C0CA), contorno: .6);
      p.circ(Offset(x + dx * u, base - .5 * u), .8 * u, const Color(0xFF3A3A40), contorno: .4);
    }
    p.ret(Rect.fromLTRB(x - 12 * u, base - 8 * u, x + 12 * u, base - 6.8 * u), const Color(0xFFB8C0CA), contorno: .6);
    final colchao = Rect.fromLTRB(x - 12 * u, base - 10.5 * u, x + 12 * u, base - 8 * u);
    p.ret(colchao, const Color(0xFFF7F7F7), contorno: .9, raio: .8 * u);
    p.ret(Rect.fromLTRB(x - 3 * u, base - 10.8 * u, x + 12.2 * u, base - 7.8 * u), const Color(0xFF7FD3A8),
        contorno: .8, raio: .6 * u);
    p.ret(Rect.fromLTRB(x - 11 * u, base - 12.4 * u, x - 6 * u, base - 10 * u), _branco, contorno: .7, raio: 1 * u);
  });
  // maleta de primeiros socorros
  p.laco(p.w * .9, 4 * u, (x) {
    final r = Rect.fromLTWH(x - 3.2 * u, p.hz + 10 * u, 6.4 * u, 4.4 * u);
    p.c.drawArc(Rect.fromLTWH(x - 1.4 * u, r.top - 1.4 * u, 2.8 * u, 2.8 * u), math.pi, math.pi, false, p.traco(.6));
    p.ret(r, const Color(0xFFE53935), contorno: .9, raio: .6 * u);
    p.c.drawRect(Rect.fromCenter(center: r.center, width: .9 * u, height: 2.6 * u), p.tinta(_branco));
    p.c.drawRect(Rect.fromCenter(center: r.center, width: 2.6 * u, height: .9 * u), p.tinta(_branco));
  });
}

void _dEstacao(_Pincel p) {
  final u = p.u;
  final janelas = <RRect>[];
  final n = p.vezes(34 * u);
  for (var i = 0; i < n; i++) {
    p.laco((i + .5) * p.w / n, 10 * u, (x) => janelas.add(RRect.fromRectAndRadius(
        Rect.fromCircle(center: Offset(x, 30 * u), radius: 8 * u), Radius.circular(8 * u))));
  }
  _parede(p, const Color(0xFF39445C), janelas);
  // painéis com rebites
  final junta = p.traco(.35);
  final rebite = p.tinta(const Color(0xFF7C88A2));
  final furos = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTRB(-4 * p.w, -2, 5 * p.w, p.hz));
  for (final j in janelas) {
    furos.addOval(j.outerRect.inflate(1.2 * u));
  }
  final k = p.vezes(17 * u);
  for (var i = 0; i < k; i++) {
    final x = i * p.w / k;
    for (final (y0, y1) in [(10 * u, 44 * u), (46 * u, p.hz - 6 * u)]) {
      final r = Rect.fromLTRB(x + .6 * u, y0, x + p.w / k - .6 * u, y1);
      p.c.save();
      p.c.clipPath(furos);
      p.c.drawRect(r, p.tinta(const Color(0xFF424E68)));
      p.c.drawRect(r, junta);
      p.c.restore();
      for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
        p.c.drawCircle(c + Offset(c.dx > r.center.dx ? -1 : 1, c.dy > r.center.dy ? -1 : 1) * .8 * u, .3 * u, rebite);
      }
    }
  }
  for (final j in janelas) {
    final c = j.outerRect.center;
    p.c.drawCircle(
        c,
        8.8 * u,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6 * u
          ..color = p.luz(const Color(0xFF8C97AD)));
    p.c.drawCircle(c, 9.6 * u, p.traco(.7));
    p.c.drawCircle(c, 8 * u, p.traco(.5));
    for (var b = 0; b < 8; b++) {
      final a = b / 8 * 2 * math.pi;
      p.c.drawCircle(c + Offset(math.cos(a), math.sin(a)) * 8.8 * u, .3 * u, p.tinta(const Color(0xFF5A6478)));
    }
    p.c.drawArc(Rect.fromCircle(center: c, radius: 6.5 * u), 3.6, .9, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7 * u
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x55FFFFFF));
  }
  // faixas de neon (pulsam devagar)
  final pulso = .7 + .3 * math.sin(p.t * 1.6);
  for (final y in [7.5 * u, p.hz - 4 * u]) {
    p.faixa(y - 1.4 * u, y + 1.4 * u, const Color(0xFF22E6FF), contorno: 0, emite: true, alfa: .18 * pulso);
    p.faixa(y - .35 * u, y + .35 * u, const Color(0xFFB8F6FF), contorno: 0, emite: true, alfa: pulso);
  }
  // telinhas
  final m = p.vezes(34 * u);
  for (var i = 0; i < m; i++) {
    p.laco(i * p.w / m, 5 * u, (x) {
      final r = Rect.fromLTWH(x - 4 * u, 41 * u, 8 * u, 5 * u);
      p.ret(r, const Color(0xFF0E1A2A), contorno: .6, raio: .5 * u);
      final grafico = Path()..moveTo(r.left + .6 * u, r.bottom - 1 * u);
      for (var j = 1; j <= 6; j++) {
        grafico.lineTo(r.left + .6 * u + j * (r.width - 1.2 * u) / 6,
            r.bottom - 1 * u - (r.height - 2 * u) * (.5 + .5 * math.sin(p.t * 2 + j + i)));
      }
      p.c.drawPath(
          grafico,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = .3 * u
            ..color = i.isEven ? const Color(0xFF4DFFB0) : const Color(0xFF22E6FF));
    });
  }
}

void _cEstacao(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF4E5870), Color(0xFF363E52)]);
  final junta = p.traco(.3);
  final n = p.vezes(10 * u);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, p.hz), Offset(x - 2 * u, p.h), junta);
  }
  for (final f in [5.0, 12.0, 22.0]) {
    p.c.drawLine(Offset(-2, p.hz + f * u), Offset(p.w + 2, p.hz + f * u), junta);
  }
  final pulso = .7 + .3 * math.sin(p.t * 1.6);
  p.faixa(p.hz + 2 * u, p.hz + 3 * u, const Color(0xFF22E6FF), contorno: 0, emite: true, alfa: .35 * pulso);
  p.faixa(p.hz + 2.35 * u, p.hz + 2.65 * u, const Color(0xFFB8F6FF), contorno: 0, emite: true, alfa: pulso);
  // console
  p.laco(p.w * .14, 10 * u, (x) {
    final base = p.hz + 13 * u;
    final corpo = Path()
      ..moveTo(x - 8 * u, base)
      ..lineTo(x - 8 * u, base - 7 * u)
      ..lineTo(x - 5 * u, base - 11 * u)
      ..lineTo(x + 8 * u, base - 11 * u)
      ..lineTo(x + 8 * u, base)
      ..close();
    p.forma(corpo, const Color(0xFF5A6680), contorno: 1);
    p.sombra(corpo, Rect.fromLTRB(x - 8 * u, base - 3 * u, x + 8 * u, base));
    final tela = Rect.fromLTWH(x - 3.6 * u, base - 10.2 * u, 10.6 * u, 4 * u);
    p.ret(tela, const Color(0xFF0E1A2A), contorno: .6, raio: .4 * u);
    p.c.drawRect(tela.deflate(.6 * u), Paint()..color = const Color(0x5522E6FF));
    for (var i = 0; i < 5; i++) {
      final liga = (p.t * 2 + i) % 3 < 2;
      p.c.drawCircle(Offset(x - 5.4 * u + i * 2.8 * u, base - 4.2 * u), .6 * u,
          Paint()..color = liga ? _publico[i] : p.luz(const Color(0xFF3A4152)));
    }
  });
}
