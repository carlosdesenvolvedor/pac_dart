import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/historia_turismo.dart';

/// As 3 camadas do fundo (a câmera e a paralaxe mexem em cada uma de um jeito).
enum CamadaFundo { ceu, distante, chao }

/// 🖼️ O fundo pintado de um cenário da história, com a paleta da hora.
///
/// Cada um dos 37 cenários é **uma** pintura em 3 camadas (não 100 quadros); a hora do dia entra como
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
        CenarioHistoria.videochamada ||
        CenarioHistoria.escritorio ||
        CenarioHistoria.casa ||
        CenarioHistoria.restaurante ||
        CenarioHistoria.loja ||
        CenarioHistoria.copa ||
        CenarioHistoria.recepcaoHotel ||
        CenarioHistoria.salaDeEstar ||
        CenarioHistoria.dentroDoCarro ||
        CenarioHistoria.cozinha ||
        CenarioHistoria.bar ||
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
        CenarioHistoria.videochamada ||
        CenarioHistoria.escritorio ||
        CenarioHistoria.casa ||
        CenarioHistoria.restaurante ||
        CenarioHistoria.loja ||
        CenarioHistoria.copa ||
        CenarioHistoria.recepcaoHotel ||
        CenarioHistoria.salaDeEstar ||
        CenarioHistoria.dentroDoCarro ||
        CenarioHistoria.cozinha ||
        CenarioHistoria.bar =>
          .64,
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
      case CenarioHistoria.videochamada:
        _dVideochamada(p);
      case CenarioHistoria.escritorio:
        _dEscritorio(p);
      case CenarioHistoria.casa:
        _dCasa(p);
      case CenarioHistoria.restaurante:
        _dRestaurante(p);
      case CenarioHistoria.loja:
        _dLoja(p);
      case CenarioHistoria.copa:
        _dCopa(p);
      case CenarioHistoria.recepcaoHotel:
        _dRecepcaoHotel(p);
      case CenarioHistoria.salaDeEstar:
        _dSalaDeEstar(p);
      case CenarioHistoria.dentroDoCarro:
        _dDentroDoCarro(p);
      case CenarioHistoria.cozinha:
        _dCozinha(p);
      case CenarioHistoria.quintal:
        _dQuintal(p);
      case CenarioHistoria.bar:
        _dBar(p);
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
      case CenarioHistoria.videochamada:
        _cVideochamada(p);
      case CenarioHistoria.escritorio:
        _cEscritorio(p);
      case CenarioHistoria.casa:
        _cCasa(p);
      case CenarioHistoria.restaurante:
        _cRestaurante(p);
      case CenarioHistoria.loja:
        _cLoja(p);
      case CenarioHistoria.copa:
        _cCopa(p);
      case CenarioHistoria.recepcaoHotel:
        _cRecepcaoHotel(p);
      case CenarioHistoria.salaDeEstar:
        _cSalaDeEstar(p);
      case CenarioHistoria.dentroDoCarro:
        _cDentroDoCarro(p);
      case CenarioHistoria.cozinha:
        _cCozinha(p);
      case CenarioHistoria.quintal:
        _cQuintal(p);
      case CenarioHistoria.bar:
        _cBar(p);
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

// ═════════════════════════ interiores das lições (📺 Escutar assistindo) ═════════════════════════
//
// Os 5 cenários do dia a dia das lições (plano §8.1), todos interiores e com as 4 horas: a hora muda o que se
// vê pela janela, a luz geral e as lâmpadas (acesas à tarde e à noite). Sem marca nenhuma: o "código" dos
// monitores são linhas coloridas, o cardápio é ilegível e os preços da loja são números genéricos.
// Tudo periódico na largura (paralaxe sem emenda); nas telas estreitas (celular em pé) os módulos encolhem.

/// Janelas iguais espaçadas na largura (periódicas: repetem sem emenda na paralaxe). [arco] = topo em arco.
List<RRect> _janelasDoInterior(_Pincel p, double passo, double meia, double topo, double fundo, {bool arco = false}) {
  final u = p.u;
  final janelas = <RRect>[];
  final n = p.vezes(passo);
  final canto = Radius.circular(1.2 * u);
  final alto = arco ? Radius.circular(meia) : canto;
  for (var i = 0; i < n; i++) {
    p.laco((i + .5) * p.w / n, meia + u, (x) {
      janelas.add(RRect.fromLTRBAndCorners(x - meia, topo, x + meia, fundo,
          topLeft: alto, topRight: alto, bottomLeft: canto, bottomRight: canto));
    });
  }
  return janelas;
}

/// Os segmentos (a..g) de cada algarismo no mostrador de 7 segmentos; o '$' é o 5 com a barra no meio.
const _seteSegmentos = {
  '0': 'abcdef',
  '1': 'bc',
  '2': 'abged',
  '3': 'abgcd',
  '4': 'fgbc',
  '5': 'afgcd',
  '6': 'afgedc',
  '7': 'abc',
  '8': 'abcdefg',
  '9': 'abcdfg',
  r'$': 'afgcd',
};

/// Largura de [texto] em [_digitos] com altura [alt].
double _larguraDosDigitos(String texto, double alt) {
  final e = alt * .16;
  var w = 0.0;
  for (final ch in texto.split('')) {
    w += (ch == ':' || ch == '.') ? e * 2.4 : alt * .56 + e * 1.4;
  }
  return w;
}

/// Algarismos de 7 segmentos (o relógio do app de chamada, os preços da loja): '0'–'9', ':', '.' e '$'.
/// [origem] = canto de cima à esquerda; [alt] = altura dos algarismos. Sem fonte: pinta igual em qualquer lugar.
void _digitos(_Pincel p, String texto, Offset origem, double alt, Color cor, {bool emite = true}) {
  final tinta = p.tinta(cor, emite: emite);
  final e = alt * .16, lw = alt * .56;
  var x = origem.dx;
  final t = origem.dy, b = origem.dy + alt, m = origem.dy + alt / 2;
  RRect seg(double x0, double y0, double x1, double y1) => RRect.fromLTRBR(x0, y0, x1, y1, Radius.circular(e / 2));
  for (final ch in texto.split('')) {
    if (ch == ':' || ch == '.') {
      final cx = x + e * .9;
      if (ch == ':') p.c.drawCircle(Offset(cx, t + alt * .3), e * .62, tinta);
      p.c.drawCircle(Offset(cx, t + alt * (ch == ':' ? .72 : .9)), e * .62, tinta);
      x += e * 2.4;
      continue;
    }
    final s = _seteSegmentos[ch];
    if (s != null) {
      final l = x, r = x + lw;
      final mapa = {
        'a': seg(l + e * .6, t, r - e * .6, t + e),
        'b': seg(r - e, t + e * .6, r, m - e * .1),
        'c': seg(r - e, m + e * .1, r, b - e * .6),
        'd': seg(l + e * .6, b - e, r - e * .6, b),
        'e': seg(l, m + e * .1, l + e, b - e * .6),
        'f': seg(l, t + e * .6, l + e, m - e * .1),
        'g': seg(l + e * .6, m - e / 2, r - e * .6, m + e / 2),
      };
      for (final k in s.split('')) {
        p.c.drawRRect(mapa[k]!, tinta);
      }
      if (ch == r'$') p.c.drawRRect(seg((l + r) / 2 - e * .38, t - e * .9, (l + r) / 2 + e * .38, b + e * .9), tinta);
    }
    x += lw + e * 1.4;
  }
}

/// A hora "do relógio" de cada [HoraHistoria] (h, min): o relógio de parede e o do app de chamada.
(int, int) _horaDoRelogio(HoraHistoria h) => switch (h) {
      HoraHistoria.amanhecer => (7, 30),
      HoraHistoria.dia => (9, 0),
      HoraHistoria.tarde => (17, 30),
      HoraHistoria.noite => (21, 0),
    };

/// Relógio de parede redondo: os ponteiros seguem a hora do cenário (7h30, 9h, 17h30, 21h).
void _relogioDeParede(_Pincel p, Offset o, double r) {
  final (hh, mm) = _horaDoRelogio(p.hora);
  p.circ(o, r * 1.14, const Color(0xFF3A4152), contorno: .7);
  p.circ(o, r, const Color(0xFFFDFBF5), contorno: .35);
  final marca = Paint()
    ..color = p.luz(const Color(0xFF3A2A33))
    ..strokeWidth = math.max(.8, r * .08)
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6;
    final d = Offset(math.sin(a), -math.cos(a));
    p.c.drawLine(o + d * r * (i % 3 == 0 ? .66 : .78), o + d * r * .88, marca);
  }
  final aH = (hh % 12 + mm / 60) * math.pi / 6, aM = mm * math.pi / 30;
  p.c.drawLine(o, o + Offset(math.sin(aH), -math.cos(aH)) * r * .48, marca..strokeWidth = math.max(1.2, r * .16));
  p.c.drawLine(o, o + Offset(math.sin(aM), -math.cos(aM)) * r * .74, marca..strokeWidth = math.max(1.0, r * .1));
  p.c.drawCircle(o, r * .1, p.tinta(const Color(0xFFE53935)));
}

/// Planta num vaso, com folhas largas em leque. [alt] = do chão ao topo das folhas.
void _planta(_Pincel p, double x, double base, double alt, {Color vaso = const Color(0xFFE07B39), int semente = 0}) {
  final vasoH = alt * .3, vasoW = alt * .36;
  final boca = Offset(x, base - vasoH);
  for (var i = 0; i < 7; i++) {
    final ang = -math.pi / 2 + (i - 3) * .36 + (_ruido(semente * 17 + i) - .5) * .22;
    final comp = alt * (.5 + .22 * _ruido(semente * 17 + i + 9));
    final ponta = boca + Offset(math.cos(ang), math.sin(ang)) * comp;
    final meio = Offset.lerp(boca, ponta, .55)!;
    final n = Offset(-math.sin(ang), math.cos(ang)) * comp * .24;
    final folha = Path()
      ..moveTo(boca.dx, boca.dy)
      ..quadraticBezierTo(meio.dx + n.dx, meio.dy + n.dy, ponta.dx, ponta.dy)
      ..quadraticBezierTo(meio.dx - n.dx, meio.dy - n.dy, boca.dx, boca.dy)
      ..close();
    p.forma(folha, i.isEven ? const Color(0xFF3E9A4A) : const Color(0xFF58B562), contorno: .45);
  }
  final v = Path()
    ..moveTo(x - vasoW / 2, base - vasoH)
    ..lineTo(x + vasoW / 2, base - vasoH)
    ..lineTo(x + vasoW * .36, base)
    ..lineTo(x - vasoW * .36, base)
    ..close();
  p.forma(v, vaso, contorno: .7);
  p.sombra(v, Rect.fromLTRB(x + vasoW * .05, base - vasoH, x + vasoW, base), alfa: .16);
  p.ret(Rect.fromLTRB(x - vasoW * .58, base - vasoH - alt * .045, x + vasoW * .58, base - vasoH + alt * .05), vaso,
      contorno: .6, raio: alt * .02);
}

/// Luminária pendente: fio do teto, cúpula de [cor] e a lâmpada (acesa à tarde e à noite).
void _pendente(_Pincel p, double x, double comp, Color cor, {double largura = 3.2}) {
  final u = p.u;
  p.c.drawLine(Offset(x, -2), Offset(x, comp), p.traco(.4));
  _luzQuente(p, Offset(x, comp + 3 * u), 24 * u, forca: .9);
  final l = largura * u;
  p.forma(
      Path()
        ..moveTo(x - l * .3, comp)
        ..lineTo(x + l * .3, comp)
        ..quadraticBezierTo(x + l, comp + .4 * u, x + l, comp + 2.6 * u)
        ..lineTo(x - l, comp + 2.6 * u)
        ..quadraticBezierTo(x - l, comp + .4 * u, x - l * .3, comp)
        ..close(),
      cor,
      contorno: .7);
  p.c.drawOval(Rect.fromCenter(center: Offset(x, comp + 2.75 * u), width: l * .9, height: .9 * u),
      Paint()..color = p.acesas ? const Color(0xFFFFF3C4) : p.luz(const Color(0xFFF2EEE2)));
}

// ─────────────────────────── videochamada (a tela de um app de chamada, sem marca) ───────────────────────────
//
// Só a "tela" do app: barra de cima (● e o relógio), o fundo em grade e a barra de baixo com 🎤 📷 ⬆ 💬 e o ☎
// vermelho. Os participantes NÃO são pintados aqui: cada ator presente ganha a sua moldura de webcam
// ([MolduraWebcamPainter], desenhada pelo palco atrás dele). O app segue o modo claro/escuro do sistema: de
// dia a tela é um ardósia mais clara; à noite, quase preta.

/// (fundo, linhas da grade) do app pela hora.
(Color, Color) _temaDaChamada(HoraHistoria h) => switch (h) {
      HoraHistoria.amanhecer => (const Color(0xFF414A66), const Color(0xFF576084)),
      HoraHistoria.dia => (const Color(0xFF4B5874), const Color(0xFF63718F)),
      HoraHistoria.tarde => (const Color(0xFF4A3F5A), const Color(0xFF645879)),
      HoraHistoria.noite => (const Color(0xFF141824), const Color(0xFF242A3A)),
    };

const _corBarraDaChamada = Color(0xFF0F121C);
const _corIconeDaChamada = Color(0xFFEFF2F8);

/// O fundo em grade do app entre [y0] e [y1] (as linhas continuam iguais entre a camada distante e o chão).
void _gradeDaChamada(_Pincel p, double y0, double y1) {
  final u = p.u;
  final (fundo, linha) = _temaDaChamada(p.hora);
  p.c.drawRect(Rect.fromLTRB(-2, y0, p.w + 2, y1), p.tinta(fundo, emite: true));
  final tr = Paint()
    ..color = linha
    ..strokeWidth = math.max(1.0, .14 * u);
  final passo = 7 * u;
  final n = p.vezes(passo);
  for (var i = 0; i < n; i++) {
    final x = i * p.w / n;
    p.c.drawLine(Offset(x, y0), Offset(x, y1), tr);
  }
  for (var k = (y0 / passo).ceil(); k * passo < y1; k++) {
    p.c.drawLine(Offset(-2, k * passo), Offset(p.w + 2, k * passo), tr);
  }
}

/// A unidade dos ícones do app: 1% da altura, mas menor no celular em pé (a barra não engole a tela).
double _unidadeDoApp(_Pincel p) => math.min(p.u, p.w / 60);

void _dVideochamada(_Pincel p) {
  final u = _unidadeDoApp(p);
  _gradeDaChamada(p, -2, p.hz);
  // barra de cima: ● (pisca devagar) e o relógio; no meio, o nome da reunião (ilegível); à direita, participantes
  p.faixa(-2, 7 * u, _corBarraDaChamada, contorno: 0, emite: true);
  p.c.drawLine(Offset(-2, 7 * u), Offset(p.w + 2, 7 * u), Paint()
    ..color = const Color(0xFF2C3346)
    ..strokeWidth = math.max(1.0, .2 * u));
  final (hh, mm) = _horaDoRelogio(p.hora);
  final relogio = '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  final larg = _larguraDosDigitos(relogio, 2.6 * u);
  p.laco(p.w * .03 + 5 * u, 5 * u + larg, (x) {
    final pisca = .55 + .45 * (.5 + .5 * math.sin(p.t * 2.4));
    p.brilho(Offset(x - 3 * u, 3.5 * u), 2.6 * u, const Color(0xFFFF5A4F), alfa: .35 * pisca);
    p.circ(Offset(x - 3 * u, 3.5 * u), 1.1 * u, const Color(0xFFE53935), contorno: 0, emite: true);
    _digitos(p, relogio, Offset(x - .4 * u, 2.2 * u), 2.6 * u, const Color(0xFFDCE3EE));
  });
  p.laco(p.w * .5, 9 * u, (x) {
    final pilula = Rect.fromCenter(center: Offset(x, 3.5 * u), width: 17 * u, height: 4 * u);
    p.ret(pilula, const Color(0xFF232A3B), contorno: 0, raio: 2 * u, emite: true);
    // cadeado (chamada protegida) + o nome em tracinhos
    final cad = Offset(pilula.left + 2.4 * u, 3.7 * u);
    p.c.drawArc(Rect.fromCenter(center: cad.translate(0, -.7 * u), width: 1.3 * u, height: 1.5 * u), math.pi, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .3 * u
          ..color = const Color(0xFF6FD39A));
    p.c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: cad.translate(0, .3 * u), width: 1.9 * u, height: 1.4 * u),
        Radius.circular(.3 * u)), Paint()..color = const Color(0xFF6FD39A));
    final traco = Paint()..color = const Color(0xFFB9C2D3);
    p.c.drawRRect(RRect.fromLTRBR(pilula.left + 4.4 * u, 3.1 * u, pilula.left + 10.6 * u, 3.9 * u, Radius.circular(.4 * u)), traco);
    p.c.drawRRect(RRect.fromLTRBR(pilula.left + 11.4 * u, 3.1 * u, pilula.right - 2 * u, 3.9 * u, Radius.circular(.4 * u)),
        traco..color = const Color(0xFF7D879B));
  });
  p.laco(p.w * .97 - 6 * u, 7 * u, (x) {
    // dois bonequinhos (participantes) e as barras do sinal
    final pessoa = Paint()..color = const Color(0xFFB9C2D3);
    for (final (dx, cor) in [(-4.6, const Color(0xFF7D879B)), (-3.2, const Color(0xFFB9C2D3))]) {
      pessoa.color = cor;
      p.c.drawCircle(Offset(x + dx * u, 2.7 * u), .75 * u, pessoa);
      p.c.drawArc(Rect.fromCenter(center: Offset(x + dx * u, 5.2 * u), width: 2.4 * u, height: 2.6 * u), math.pi, math.pi, true,
          pessoa);
    }
    for (var i = 0; i < 4; i++) {
      final hB = (1 + i * .7) * u;
      p.c.drawRRect(RRect.fromLTRBR(x + (.6 + i * 1.1) * u, 5 * u - hB, x + (1.4 + i * 1.1) * u, 5 * u, Radius.circular(.2 * u)),
          Paint()..color = i < 3 ? const Color(0xFF6FD39A) : const Color(0xFF4A5468));
    }
  });
}

/// Um botão redondo da barra de baixo, com o ícone de [tipo] (0 microfone, 1 câmera, 2 compartilhar, 3 chat).
void _botaoDaChamada(_Pincel p, Offset o, double r, int tipo) {
  final u = _unidadeDoApp(p);
  p.c.drawCircle(o, r, Paint()..color = const Color(0xFF2E3548));
  p.c.drawCircle(o, r, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, .18 * u)
    ..color = const Color(0xFF3F475C));
  final ic = Paint()..color = _corIconeDaChamada;
  final linha = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, r * .14)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = _corIconeDaChamada;
  switch (tipo) {
    case 0: // microfone
      p.c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o.translate(0, -r * .18), width: r * .5, height: r * .82),
          Radius.circular(r * .25)), ic);
      p.c.drawArc(Rect.fromCenter(center: o.translate(0, -r * .12), width: r * .9, height: r * .9), .15, math.pi - .3, false, linha);
      p.c.drawLine(o.translate(0, r * .34), o.translate(0, r * .52), linha);
    case 1: // câmera
      p.c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o.translate(-r * .14, 0), width: r * .8, height: r * .6),
          Radius.circular(r * .12)), ic);
      p.c.drawPath(
          Path()
            ..moveTo(o.dx + r * .26, o.dy)
            ..lineTo(o.dx + r * .54, o.dy - r * .24)
            ..lineTo(o.dx + r * .54, o.dy + r * .24)
            ..close(),
          ic);
    case 2: // compartilhar a tela
      p.c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: r * 1.1, height: r * .8), Radius.circular(r * .1)),
          linha);
      p.c.drawLine(o.translate(0, r * .22), o.translate(0, -r * .2), linha);
      p.c.drawPath(
          Path()
            ..moveTo(o.dx - r * .2, o.dy - r * .02)
            ..lineTo(o.dx, o.dy - r * .24)
            ..lineTo(o.dx + r * .2, o.dy - r * .02),
          linha);
    default: // chat
      p.c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o.translate(0, -r * .06), width: r * 1.04, height: r * .72),
          Radius.circular(r * .2)), ic);
      p.c.drawPath(
          Path()
            ..moveTo(o.dx - r * .2, o.dy + r * .24)
            ..lineTo(o.dx - r * .34, o.dy + r * .5)
            ..lineTo(o.dx + r * .04, o.dy + r * .26)
            ..close(),
          ic);
      final ponto = Paint()..color = const Color(0xFF2E3548);
      for (final dx in [-.26, 0.0, .26]) {
        p.c.drawCircle(o.translate(r * dx, -r * .06), r * .07, ponto);
      }
  }
}

void _cVideochamada(_Pincel p) {
  final u = _unidadeDoApp(p);
  _gradeDaChamada(p, p.hz, p.h + 1);
  // barra de baixo: 🎤 📷 ⬆ 💬 e o ☎ vermelho, numa pílula escura no meio da tela
  final yb = math.min(p.hz + 26 * p.u, p.h - 4.5 * u);
  final r = 2.5 * u;
  p.laco(p.w * .5, 19 * u, (x) {
    final pilula = Rect.fromCenter(center: Offset(x, yb), width: 37 * u, height: 7.2 * u);
    p.c.drawRRect(RRect.fromRectAndRadius(pilula.shift(Offset(0, .6 * u)), Radius.circular(3.6 * u)),
        Paint()..color = const Color(0x55000000));
    p.ret(pilula, _corBarraDaChamada, contorno: .5, raio: 3.6 * u, emite: true);
    for (var i = 0; i < 4; i++) {
      _botaoDaChamada(p, Offset(x - 13.4 * u + i * 6.4 * u, yb), r, i);
    }
    // desligar: pílula vermelha com o fone deitado
    final des = Rect.fromCenter(center: Offset(x + 13.6 * u, yb), width: 6.6 * u, height: 2 * r);
    p.c.drawRRect(RRect.fromRectAndRadius(des, Radius.circular(r)), Paint()..color = const Color(0xFFE53935));
    final fone = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .75 * u
      ..strokeCap = StrokeCap.round
      ..color = _corIconeDaChamada;
    p.c.drawArc(Rect.fromCenter(center: des.center.translate(0, .55 * u), width: 3.6 * u, height: 2.2 * u), math.pi * 1.12,
        math.pi * .76, false, fone);
    for (final dx in [-1.55, 1.55]) {
      p.c.drawCircle(des.center.translate(dx * u, .15 * u), .55 * u, Paint()..color = _corIconeDaChamada);
    }
  });
}

// ─────────────────────────── escritório (aberto, com a vista de Chicago) ───────────────────────────

/// Quadro branco com post-its, um gráfico subindo e os marcadores na bandeja.
void _quadroBranco(_Pincel p, Rect r) {
  final u = p.u;
  p.ret(r.inflate(.6 * u), const Color(0xFFB8C0CA), contorno: .7, raio: .5 * u);
  p.ret(r, const Color(0xFFFBFCFD), contorno: .35);
  const notas = [Color(0xFFFFE066), Color(0xFFFF9EC7), Color(0xFF8FD3FF), Color(0xFFB5E58C)];
  for (var i = 0; i < 4; i++) {
    final nota = Rect.fromLTWH(r.left + r.width * (.06 + (i % 2) * .17), r.top + r.height * (.1 + (i ~/ 2) * .4),
        r.width * .14, r.height * .32);
    p.ret(nota, notas[i], contorno: .25);
    p.c.drawLine(Offset(nota.left + nota.width * .2, nota.center.dy), Offset(nota.right - nota.width * .2, nota.center.dy),
        Paint()
          ..color = const Color(0x553A2A33)
          ..strokeWidth = math.max(.6, .15 * u));
  }
  final grafico = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, .32 * u)
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = p.luz(const Color(0xFF1E88E5));
  final g0 = Offset(r.left + r.width * .5, r.bottom - r.height * .18);
  p.c.drawPath(
      Path()
        ..moveTo(g0.dx, g0.dy)
        ..lineTo(g0.dx + r.width * .1, g0.dy - r.height * .22)
        ..lineTo(g0.dx + r.width * .2, g0.dy - r.height * .14)
        ..lineTo(g0.dx + r.width * .3, g0.dy - r.height * .45)
        ..lineTo(g0.dx + r.width * .42, g0.dy - r.height * .62),
      grafico);
  final eixo = Paint()
    ..strokeWidth = math.max(.8, .18 * u)
    ..color = p.luz(const Color(0xFF3A2A33));
  p.c.drawLine(Offset(g0.dx - r.width * .03, r.top + r.height * .12), Offset(g0.dx - r.width * .03, g0.dy), eixo);
  p.c.drawLine(Offset(g0.dx - r.width * .03, g0.dy), Offset(r.right - r.width * .04, g0.dy), eixo);
  p.ret(Rect.fromLTRB(r.left + r.width * .2, r.bottom + .6 * u, r.right - r.width * .2, r.bottom + 1.3 * u),
      const Color(0xFF8D99A8), contorno: .4);
  for (final (i, cor) in [(0, const Color(0xFFE53935)), (1, const Color(0xFF1E88E5)), (2, const Color(0xFF43A047))]) {
    p.ret(Rect.fromLTWH(r.left + r.width * (.3 + i * .12), r.bottom + .1 * u, r.width * .09, .6 * u), cor, contorno: .3,
        raio: .2 * u);
  }
}

/// Monitor com "código" (linhas coloridas, sem marca); a tela acende de verdade à tarde e à noite.
void _monitor(_Pincel p, Rect tela, int semente) {
  final u = p.u;
  p.tubos([
    Path()
      ..moveTo(tela.center.dx, tela.bottom)
      ..lineTo(tela.center.dx, tela.bottom + 2.2 * u)
  ], .9 * u, const Color(0xFF59636E), contorno: .5);
  p.ret(Rect.fromCenter(center: Offset(tela.center.dx, tela.bottom + 2.4 * u), width: 4.2 * u, height: .7 * u),
      const Color(0xFF59636E), contorno: .5, raio: .3 * u);
  p.ret(tela, const Color(0xFF263244), contorno: .7, raio: .5 * u);
  final dentro = tela.deflate(.55 * u);
  p.ret(dentro, const Color(0xFF17202E), contorno: 0, emite: true);
  const cores = [Color(0xFF4DD0E1), Color(0xFFFFB74D), Color(0xFFB39DDB), Color(0xFF81C784), Color(0xFFF06292)];
  final linhas = math.max(2, (dentro.height / (1.1 * u)).floor());
  final alto = dentro.height / linhas;
  for (var j = 0; j < linhas; j++) {
    final recuo = (_ruido(semente * 31 + j) * 3).floor() * .9 * u;
    final comp = (dentro.width - recuo - 1 * u) * (.35 + .6 * _ruido(semente * 31 + j + 7));
    final y = dentro.top + (j + .3) * alto;
    p.c.drawRRect(
        RRect.fromLTRBR(dentro.left + .6 * u + recuo, y, dentro.left + .6 * u + recuo + comp, y + alto * .42,
            Radius.circular(.2 * u)),
        Paint()..color = cores[(semente + j * 3) % cores.length]);
  }
  if (p.acesas) p.brilho(tela.center, tela.width * .9, const Color(0xFF7FD0FF), alfa: p.noite ? .28 : .16);
}

/// Cadeira de escritório vista de costas (a pessoa estaria de frente para a mesa).
void _cadeiraDeEscritorio(_Pincel p, double x, double base, Color cor) {
  final u = p.u;
  p.tubos([
    Path()
      ..moveTo(x, base - 6.4 * u)
      ..lineTo(x, base - 1.4 * u)
  ], .8 * u, const Color(0xFF59636E), contorno: .5);
  final pes = <Path>[];
  for (final dx in [-3.2, -1.2, 1.2, 3.2]) {
    pes.add(Path()
      ..moveTo(x, base - 1.4 * u)
      ..lineTo(x + dx * u, base - .5 * u));
  }
  p.tubos(pes, .55 * u, const Color(0xFF3F4652), contorno: .4);
  for (final dx in [-3.2, -1.2, 1.2, 3.2]) {
    p.circ(Offset(x + dx * u, base - .3 * u), .5 * u, const Color(0xFF2B2B2B), contorno: .3);
  }
  final encosto = Rect.fromLTRB(x - 4 * u, base - 14.5 * u, x + 4 * u, base - 6.2 * u);
  p.ret(encosto, cor, contorno: .9, raio: 2 * u);
  p.sombra(Path()..addRRect(RRect.fromRectAndRadius(encosto, Radius.circular(2 * u))),
      Rect.fromLTRB(encosto.left, encosto.bottom - 2 * u, encosto.right, encosto.bottom), alfa: .2);
  p.ret(Rect.fromLTRB(x - 4.6 * u, base - 7 * u, x + 4.6 * u, base - 5.8 * u), Color.lerp(cor, const Color(0xFF000000), .25)!,
      contorno: .6, raio: .6 * u);
}

/// Uma mesa do escritório: tampo de madeira clara, monitor com código, teclado, caneca e a cadeira na frente.
void _mesaDeTrabalho(_Pincel p, double x, double base, int semente) {
  final u = p.u;
  final tampo = Rect.fromLTRB(x - 13 * u, base - 8 * u, x + 13 * u, base - 6.8 * u);
  p.ret(Rect.fromLTRB(x - 11 * u, base - 6.8 * u, x + 11 * u, base - 3.4 * u), const Color(0xFFC3CCD6), contorno: .5);
  p.tubos([
    for (final dx in [-11.6, 11.6])
      Path()
        ..moveTo(x + dx * u, base - 6.8 * u)
        ..lineTo(x + dx * u, base),
  ], .7 * u, const Color(0xFF59636E), contorno: .5);
  _monitor(p, Rect.fromLTRB(x - 6.5 * u, base - 17.6 * u, x + 4.5 * u, base - 10.6 * u), semente);
  p.ret(tampo, const Color(0xFFDDBD92), contorno: .8, raio: .3 * u);
  p.ret(Rect.fromLTRB(x - 5 * u, base - 8.7 * u, x + 2.6 * u, base - 8 * u), const Color(0xFFE6EAEE), contorno: .4, raio: .2 * u);
  p.c.drawOval(Rect.fromLTRB(x + 3.6 * u, base - 8.8 * u, x + 4.9 * u, base - 8 * u), p.tinta(const Color(0xFFE6EAEE)));
  // caneca ou planta pequena (alternando)
  if (semente.isEven) {
    final cor = _publico[(semente * 3 + 2) % 6];
    p.c.drawArc(Rect.fromLTWH(x + 9.4 * u, base - 10 * u, 1.4 * u, 1.4 * u), -math.pi / 2, math.pi, false, p.traco(.4));
    p.ret(Rect.fromLTWH(x + 7.6 * u, base - 10.4 * u, 2.2 * u, 2.4 * u), cor, contorno: .5, raio: .4 * u);
  } else {
    _planta(p, x + 9 * u, base - 8 * u, 4.4 * u, vaso: const Color(0xFFF4F1EA), semente: semente);
  }
  _cadeiraDeEscritorio(p, x + 1 * u, base + 4.6 * u, semente.isEven ? const Color(0xFF37404F) : const Color(0xFF3F5E8C));
}

void _dEscritorio(_Pincel p) {
  final u = p.u;
  // lá fora (pelas janelas): o centro de Chicago, com a torre preta das duas antenas
  const cores = [Color(0xFF7D8BA6), Color(0xFF94A0B8), Color(0xFF6E7F99), Color(0xFF8C8FA8)];
  final fundoFora = p.hz - 18 * u;
  final m = p.vezes(9 * u);
  for (var i = 0; i < m; i++) {
    final passo = p.w / m;
    final larg = passo * (.72 + .24 * _ruido(i * 5 + 701));
    final alt = (12 + 22 * _ruido(i * 5 + 702)) * u;
    _predio(p, Rect.fromLTWH(i * passo + (passo - larg) / 2, fundoFora - alt, larg, alt + 1 * u), cores[i % 4],
        semente: i + 40);
  }
  p.laco(p.w * .3, 5 * u, (x) {
    final torre = Rect.fromLTRB(x - 4.2 * u, 12 * u, x + 4.2 * u, fundoFora + 1 * u);
    p.ret(torre, const Color(0xFF3B4254), contorno: .7);
    p.ret(Rect.fromLTRB(x - 3 * u, 9 * u, x + 3 * u, 12.4 * u), const Color(0xFF3B4254), contorno: .6);
    for (final dx in [-1.6, 1.6]) {
      p.c.drawLine(Offset(x + dx * u, 9 * u), Offset(x + dx * u, 3.5 * u), p.traco(.5));
    }
    final janela = p.noite ? Paint() : p.tinta(const Color(0xFF55607A));
    for (var j = 0; j < 7; j++) {
      for (var k = 0; k < 3; k++) {
        if (p.noite) janela.color = _ruido(j * 7 + k + 900) > .45 ? const Color(0xFFFFD866) : const Color(0xFF2A3346);
        p.c.drawRect(Rect.fromLTWH(x - 3.2 * u + k * 2.3 * u, 14 * u + j * 3.6 * u, 1.6 * u, 1.8 * u), janela);
      }
    }
  });
  final passoJ = 46 * u;
  final janelas = _janelasDoInterior(p, passoJ, 15 * u, 6 * u, p.hz - 20 * u);
  _parede(p, const Color(0xFFE3E8EE), janelas);
  for (final j in janelas) {
    // persiana meio enrolada no alto
    final r = j.outerRect;
    p.c.save();
    p.c.clipRRect(j);
    p.c.drawRect(Rect.fromLTRB(r.left, r.top, r.right, r.top + 5.5 * u), p.tinta(const Color(0xFFEFF2F5)));
    final lamina = p.traco(.22);
    for (var y = r.top + 1.1 * u; y < r.top + 5.5 * u; y += 1.1 * u) {
      p.c.drawLine(Offset(r.left, y), Offset(r.right, y), lamina);
    }
    p.c.restore();
    _moldura(p, j, const Color(0xFF5E6975), cruz: false);
    p.tubos([
      Path()
        ..moveTo(r.center.dx, r.top)
        ..lineTo(r.center.dx, r.bottom),
      Path()
        ..moveTo(r.left, r.top + r.height * .68)
        ..lineTo(r.right, r.top + r.height * .68),
    ], .7 * u, const Color(0xFF5E6975), contorno: .4);
    p.ret(Rect.fromLTRB(r.left - 1.4 * u, r.bottom + .7 * u, r.right + 1.4 * u, r.bottom + 1.8 * u), const Color(0xFFF3F5F7),
        contorno: .6);
  }
  // teto com as placas de luz
  p.faixa(-2, 3 * u, const Color(0xFFF5F6F8), contorno: .5);
  final k = p.vezes(24 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .5) * p.w / k, 5 * u, (x) {
      final placa = Rect.fromCenter(center: Offset(x, 1.6 * u), width: 9 * u, height: 1.4 * u);
      p.ret(placa, const Color(0xFFFFF8E4), contorno: .4, emite: true, raio: .3 * u);
      if (p.acesas) p.brilho(placa.center, 9 * u, const Color(0xFFFFF2CC), alfa: .3);
    });
  }
  // entre as janelas: o relógio e o quadro branco; embaixo, o armário baixo com pastas, impressora e plantas
  final n = p.vezes(passoJ);
  final passo = p.w / n;
  for (var i = 0; i < n; i++) {
    p.laco(i * passo, 8 * u, (x) {
      _relogioDeParede(p, Offset(x, 11 * u), 2.4 * u);
      _quadroBranco(p, Rect.fromLTWH(x - 6.5 * u, 16 * u, 13 * u, 10 * u));
    });
  }
  final base = p.hz - 9 * u;
  p.faixa(base, p.hz, const Color(0xFFAAB6C3), contorno: .6, baixo: false);
  p.faixa(base - .9 * u, base, const Color(0xFF7F8C9A), contorno: .5);
  final gav = p.vezes(9 * u);
  for (var i = 0; i < gav; i++) {
    final x = i * p.w / gav;
    p.c.drawLine(Offset(x, base), Offset(x, p.hz), p.traco(.3));
    p.c.drawRRect(RRect.fromLTRBR(x + p.w / gav * .38, base + 2 * u, x + p.w / gav * .62, base + 2.6 * u, Radius.circular(.3 * u)),
        p.tinta(const Color(0xFF59636E)));
  }
  for (var i = 0; i < n; i++) {
    p.laco(i * passo, 3 * u, (x) => _planta(p, x, base - .9 * u, 9 * u, vaso: const Color(0xFFF4F1EA), semente: i + 3));
    p.laco((i + .5) * passo - 8 * u, 4 * u, (x) {
      for (var b = 0; b < 4; b++) {
        p.ret(Rect.fromLTWH(x - 3.6 * u + b * 1.8 * u, base - 5.2 * u, 1.6 * u, 4.3 * u), _publico[(b + i * 2) % 6],
            contorno: .4, raio: .2 * u);
      }
    });
    p.laco((i + .5) * passo + 8 * u, 4 * u, (x) {
      p.ret(Rect.fromLTRB(x - 3.4 * u, base - 4.4 * u, x + 3.4 * u, base - .9 * u), const Color(0xFFE6EAEE), contorno: .6,
          raio: .4 * u);
      p.ret(Rect.fromLTRB(x - 2.4 * u, base - 5.4 * u, x + 2.4 * u, base - 4.4 * u), _branco, contorno: .4);
      p.c.drawCircle(Offset(x + 2.2 * u, base - 2.6 * u), .35 * u, Paint()..color = const Color(0xFF4CD964));
    });
  }
  p.faixa(p.hz - 1 * u, p.hz, const Color(0xFF6F7C8A), contorno: .5);
}

void _cEscritorio(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF9FAABA), Color(0xFF808DA0)]);
  final junta = Paint()
    ..strokeWidth = math.max(1.0, .22 * u)
    ..color = const Color(0x2E3A2A33);
  for (final f in [3.0, 7.0, 12.5, 19.5, 28.0]) {
    p.c.drawLine(Offset(-2, p.hz + f * u), Offset(p.w + 2, p.hz + f * u), junta);
  }
  final k = p.vezes(14 * u);
  for (var i = 0; i < k; i++) {
    final x = i * p.w / k;
    p.c.drawLine(Offset(x, p.hz), Offset(x - 4 * u, p.h), junta);
  }
  final m = p.vezes(40 * u);
  for (var i = 0; i < m; i++) {
    p.laco(i * p.w / m, 4 * u, (x) => _planta(p, x, p.hz + 12 * u, 15 * u, vaso: const Color(0xFFF4F1EA), semente: i * 7 + 1));
    p.laco((i + .5) * p.w / m, 15 * u, (x) => _mesaDeTrabalho(p, x, p.hz + 9 * u, i));
  }
}

// ─────────────────────────── casa (sala com cozinha americana) ───────────────────────────

/// A cozinha encostada na parede, de [l] até [l] + [larg]: geladeira, armários, coifa, fogão e a bancada.
void _cozinha(_Pincel p, double l, double larg) {
  final u = p.u;
  final r = l + larg;
  final fw = math.min(9 * u, larg * .3);
  final bancada = p.hz - 10 * u;
  // azulejos atrás da bancada
  final azulejo = Rect.fromLTRB(l + fw, 22 * u, r, bancada);
  p.c.drawRect(azulejo, p.tinta(const Color(0xFFE6F0EE)));
  final rejunte = Paint()
    ..color = p.luz(const Color(0xFFC6D6D2))
    ..strokeWidth = math.max(.6, .15 * u);
  for (var y = azulejo.top + 2 * u; y < azulejo.bottom; y += 2 * u) {
    p.c.drawLine(Offset(azulejo.left, y), Offset(azulejo.right, y), rejunte);
  }
  for (var x = azulejo.left + 3 * u; x < azulejo.right; x += 3 * u) {
    p.c.drawLine(Offset(x, azulejo.top), Offset(x, azulejo.bottom), rejunte);
  }
  // coifa e armários de cima
  final sx = r - math.max(4.5 * u, larg * .22);
  p.forma(
      Path()
        ..moveTo(sx - 1.4 * u, 12 * u)
        ..lineTo(sx + 1.4 * u, 12 * u)
        ..lineTo(sx + 1.4 * u, 18 * u)
        ..lineTo(sx + 4 * u, 21.5 * u)
        ..lineTo(sx - 4 * u, 21.5 * u)
        ..lineTo(sx - 1.4 * u, 18 * u)
        ..close(),
      const Color(0xFFC3CBD3),
      contorno: .7);
  p.c.drawLine(Offset(sx - 3.4 * u, 20.6 * u), Offset(sx + 3.4 * u, 20.6 * u), p.traco(.3));
  final armL = l + fw + .8 * u, armR = sx - 4.4 * u;
  if (armR - armL > 2 * u) {
    final arm = Rect.fromLTRB(armL, 10 * u, armR, 22 * u);
    p.ret(arm, const Color(0xFF8DB8A0), contorno: .8, raio: .3 * u);
    final portas = math.max(1, (arm.width / (6 * u)).round());
    for (var i = 0; i < portas; i++) {
      final a = arm.left + arm.width * i / portas, b = arm.left + arm.width * (i + 1) / portas;
      if (i > 0) p.c.drawLine(Offset(a, arm.top), Offset(a, arm.bottom), p.traco(.4));
      p.c.drawRRect(RRect.fromLTRBR((a + b) / 2 - .25 * u, arm.bottom - 3.4 * u, (a + b) / 2 + .25 * u, arm.bottom - 1.2 * u,
          Radius.circular(.25 * u)), p.tinta(const Color(0xFF59636E)));
    }
    // prateleira aberta com potes e pratos
    final ys = 31 * u;
    var px = armL + .6 * u;
    var k = 0;
    while (px < armR - 2 * u) {
      if (k.isEven) {
        p.ret(Rect.fromLTRB(px, ys - 3 * u, px + 2 * u, ys), const Color(0xFFF4ECD8), contorno: .4, raio: .4 * u);
        p.ret(Rect.fromLTRB(px - .1 * u, ys - 3.6 * u, px + 2.1 * u, ys - 2.9 * u), [const Color(0xFFE5533D),
          const Color(0xFF3E8AE0), const Color(0xFFF2A541)][(k ~/ 2) % 3], contorno: .3);
        px += 2.8 * u;
      } else {
        p.c.drawOval(Rect.fromLTRB(px, ys - 3.4 * u, px + 3 * u, ys), p.tinta(_branco));
        p.c.drawOval(Rect.fromLTRB(px, ys - 3.4 * u, px + 3 * u, ys), p.traco(.4));
        px += 3.6 * u;
      }
      k++;
    }
    p.ret(Rect.fromLTRB(armL - .4 * u, ys, armR + .4 * u, ys + .8 * u), const Color(0xFFA6784F), contorno: .5);
  }
  // em cima da bancada: chaleira no fogão, fruteira
  p.c.drawArc(Rect.fromLTWH(sx - 1.6 * u, bancada - 5.4 * u, 3.2 * u, 2.4 * u), math.pi, math.pi, false, p.traco(.6));
  p.forma(
      Path()
        ..moveTo(sx - 2.4 * u, bancada)
        ..quadraticBezierTo(sx - 2.6 * u, bancada - 4.2 * u, sx, bancada - 4.2 * u)
        ..quadraticBezierTo(sx + 2.6 * u, bancada - 4.2 * u, sx + 2.4 * u, bancada)
        ..close(),
      const Color(0xFFE5533D),
      contorno: .7);
  p.tubos([
    Path()
      ..moveTo(sx + 2 * u, bancada - 2 * u)
      ..lineTo(sx + 3.6 * u, bancada - 3.4 * u)
  ], .5 * u, const Color(0xFFE5533D), contorno: .4);
  final fx = (l + fw + sx) / 2;
  if (sx - (l + fw) > 9 * u) {
    for (final (dx, cor) in [(-1.2, const Color(0xFFF2A541)), (0.0, const Color(0xFFE5533D)), (1.2, const Color(0xFF7CC160))]) {
      p.circ(Offset(fx + dx * u, bancada - 2.2 * u - (dx == 0 ? .8 * u : 0)), 1.05 * u, cor, contorno: .4);
    }
    p.forma(
        Path()
          ..moveTo(fx - 2.8 * u, bancada - 2 * u)
          ..lineTo(fx + 2.8 * u, bancada - 2 * u)
          ..quadraticBezierTo(fx + 2.4 * u, bancada, fx, bancada)
          ..quadraticBezierTo(fx - 2.4 * u, bancada, fx - 2.8 * u, bancada - 2 * u)
          ..close(),
        const Color(0xFFF4F1EA),
        contorno: .5);
  }
  // bancada e armários de baixo (com os botões do fogão)
  p.ret(Rect.fromLTRB(l + fw, bancada, r + .6 * u, bancada + 1.2 * u), const Color(0xFF5E4B40), contorno: .7);
  final baixo = Rect.fromLTRB(l + fw + .4 * u, bancada + 1.2 * u, r, p.hz);
  p.ret(baixo, const Color(0xFF7FAA92), contorno: .7);
  final portas = math.max(1, (baixo.width / (5.5 * u)).round());
  for (var i = 1; i < portas; i++) {
    final a = baixo.left + baixo.width * i / portas;
    p.c.drawLine(Offset(a, baixo.top), Offset(a, baixo.bottom), p.traco(.4));
  }
  for (var i = 0; i < 3; i++) {
    p.circ(Offset(sx - 2 * u + i * 2 * u, baixo.top + 1.2 * u), .45 * u, const Color(0xFF3A4152), contorno: .25);
  }
  // geladeira (com ímãs e um desenho de criança)
  final gel = Rect.fromLTRB(l, 13 * u, l + fw, p.hz);
  p.ret(gel, const Color(0xFFDDE4EA), contorno: 1, raio: .9 * u);
  p.sombra(Path()..addRRect(RRect.fromRectAndRadius(gel, Radius.circular(.9 * u))),
      Rect.fromLTRB(gel.right - fw * .2, gel.top, gel.right, gel.bottom), alfa: .12);
  final corte = gel.top + gel.height * .34;
  p.c.drawLine(Offset(gel.left, corte), Offset(gel.right, corte), p.traco(.5));
  p.tubos([
    Path()
      ..moveTo(gel.right - 1.3 * u, corte - 4.6 * u)
      ..lineTo(gel.right - 1.3 * u, corte - 1.4 * u),
    Path()
      ..moveTo(gel.right - 1.3 * u, corte + 1.4 * u)
      ..lineTo(gel.right - 1.3 * u, corte + 7 * u),
  ], .5 * u, const Color(0xFF8D99A8), contorno: .4);
  final desenho = Rect.fromLTWH(gel.left + fw * .16, corte + 2.4 * u, fw * .48, fw * .44);
  p.ret(desenho, _branco, contorno: .35);
  p.c.drawCircle(Offset(desenho.left + desenho.width * .3, desenho.top + desenho.height * .32), desenho.height * .16,
      p.tinta(const Color(0xFFFFC928)));
  p.c.drawRect(Rect.fromLTRB(desenho.left, desenho.bottom - desenho.height * .22, desenho.right, desenho.bottom),
      p.tinta(const Color(0xFF7CC160)));
  p.circ(Offset(gel.left + fw * .3, gel.top + 3 * u), .6 * u, const Color(0xFFE5533D), contorno: .25);
  p.circ(Offset(gel.left + fw * .5, gel.top + 5.2 * u), .6 * u, const Color(0xFF3E8AE0), contorno: .25);
}

/// Estante de livros (com um vaso e um porta-retrato no alto).
void _estante(_Pincel p, double x, double topo, double base, double meia) {
  final u = p.u;
  final r = Rect.fromLTRB(x - meia, topo, x + meia, base);
  p.ret(r, const Color(0xFFA6784F), contorno: 1, raio: .3 * u);
  final dentro = r.deflate(.8 * u);
  p.c.drawRect(dentro, p.tinta(const Color(0xFF8A5F3C)));
  const prateleiras = 4;
  final alto = dentro.height / prateleiras;
  for (var s = 0; s < prateleiras; s++) {
    final y = dentro.top + (s + 1) * alto;
    var bx = dentro.left + .3 * u;
    var k = 0;
    while (bx < dentro.right - 1.2 * u) {
      final seed = s * 37 + k * 5 + x.round();
      final bw = (.9 + .7 * _ruido(seed)) * u;
      final bh = alto * (.55 + .32 * _ruido(seed + 1));
      if (s == 0 && k == 2) {
        // um vaso no meio dos livros
        p.circ(Offset(bx + 1.4 * u, y - 1.4 * u), 1.3 * u, const Color(0xFF6FC3C9), contorno: .4);
        p.circ(Offset(bx + 1.4 * u, y - 3.4 * u), .9 * u, const Color(0xFFFF8FB1), contorno: .3);
        bx += 3 * u;
      } else {
        p.ret(Rect.fromLTRB(bx, y - bh, math.min(bx + bw, dentro.right), y), _publico[seed % 6], contorno: .35);
        bx += bw + .1 * u;
      }
      k++;
    }
    p.ret(Rect.fromLTRB(r.left, y - .2 * u, r.right, y + .6 * u), const Color(0xFFA6784F), contorno: .5);
  }
  // porta-retrato em cima
  final foto = Rect.fromLTWH(x - 2.4 * u, topo - 4.2 * u, 4.8 * u, 4 * u);
  p.ret(foto, const Color(0xFFF2D49B), contorno: .6, raio: .2 * u);
  final img = foto.deflate(.6 * u);
  p.c.drawRect(img, p.tinta(const Color(0xFF9FD3F5)));
  p.c.drawCircle(Offset(img.center.dx - .6 * u, img.bottom - .9 * u), .7 * u, p.tinta(const Color(0xFF7B4FA0)));
  p.c.drawCircle(Offset(img.center.dx + .7 * u, img.bottom - .8 * u), .6 * u, p.tinta(const Color(0xFFE5533D)));
}

/// Cortinas de pano dos dois lados da janela [j], com o varão; e um cacto no peitoril.
void _cortinas(_Pincel p, RRect j, Color cor) {
  final u = p.u;
  final r = j.outerRect;
  final topo = r.top - 1.8 * u;
  p.tubos([
    Path()
      ..moveTo(r.left - 4.5 * u, topo)
      ..lineTo(r.right + 4.5 * u, topo)
  ], .6 * u, const Color(0xFF8A5A3A), contorno: .5);
  for (final lado in [-1.0, 1.0]) {
    final xa = lado < 0 ? r.left - 4 * u : r.right + 4 * u;
    final xb = lado < 0 ? r.left + 1.6 * u : r.right - 1.6 * u;
    final pano = Path()
      ..moveTo(xa, topo)
      ..lineTo(xb, topo)
      ..quadraticBezierTo(xb + lado * 1.4 * u, r.center.dy, xa - lado * .2 * u, r.bottom + 4 * u)
      ..lineTo(xa, r.bottom + 4 * u)
      ..close();
    p.forma(pano, cor, contorno: .7);
    final dobra = p.traco(.25);
    p.c.drawLine(Offset((xa * 2 + xb) / 3, topo + u), Offset((xa * 2 + xb) / 3, r.bottom + 3 * u), dobra);
  }
  final cx = r.center.dx, base = r.bottom + .2 * u;
  p.ret(Rect.fromLTRB(r.left - 1 * u, base, r.right + 1 * u, base + 1 * u), _branco, contorno: .5);
  p.ret(Rect.fromLTRB(cx - 1.1 * u, base - 1.6 * u, cx + 1.1 * u, base), const Color(0xFFE07B39), contorno: .4);
  p.forma(Path()..addRRect(RRect.fromLTRBR(cx - .6 * u, base - 4.4 * u, cx + .6 * u, base - 1.5 * u, Radius.circular(.6 * u))),
      const Color(0xFF4E9A4E),
      contorno: .4);
}

/// A planta da sala (UMA sala em qualquer largura; a casa não se repete): onde fica cada coisa, em px.
///
/// - estreita (< 70u, o celular em pé no ⛶): cozinha à esquerda, janela com o sofá, a mesa do notebook na frente da
///   cozinha e um porta-retrato no canto;
/// - larga: cozinha à esquerda · (mesa de jantar) · janela com o sofá · (planta, porta) · estante com a mesa do
///   notebook à direita. O que sobra de parede ganha a mesa de jantar e a porta, não outra cozinha.
typedef _SalaCasa = ({
  bool larga,
  double kl, // começo da cozinha
  double kw, // largura da cozinha
  double xj, // meio da janela (e do sofá)
  double jMeia, // meia largura da janela
  double xr, // estante + mesa do notebook (larga) / porta-retrato (estreita)
  double? quadros, // os dois quadrinhos
  double? jantar, // mesa de jantar com pendente
  double? planta, // planta no chão
  double? porta, // porta da sala
});

_SalaCasa _salaDaCasa(_Pincel p) {
  final u = p.u, w = p.w;
  final kw = math.min(34 * u, w * .44);
  if (w < 70 * u) {
    return (
      larga: false,
      kl: w * .03,
      kw: kw,
      xj: w * .62,
      jMeia: math.min(10 * u, w * .14),
      xr: w * .9,
      quadros: null,
      jantar: null,
      planta: null,
      porta: null,
    );
  }
  final kl = math.min(w * .03, 4 * u);
  final kr = kl + kw;
  final xr = w - math.min(w * .12, 22 * u);
  final livreL = kr, livreR = xr - 13 * u; // a parede entre a cozinha e a estante
  final meio = livreR - livreL;
  final jMeia = (meio * .1).clamp(math.min(10 * u, w * .14), 14 * u).toDouble();
  // a janela vai para a direita do meio quando sobra parede para a mesa de jantar
  final comJantar = meio >= 110 * u;
  final xj = comJantar ? livreL + meio * .56 : livreL + meio * .5;
  final borda = 5 * u; // as cortinas
  final gapL = (xj - jMeia - borda) - livreL, gapR = livreR - (xj + jMeia + borda);
  double? jantar, quadros, planta, porta;
  if (comJantar && gapL >= 30 * u) {
    jantar = livreL + gapL * .5;
  } else if (gapL >= 10 * u) {
    quadros = livreL + gapL * .5;
  }
  if (gapR >= 34 * u) {
    porta = livreR - gapR * .42;
    planta = xj + jMeia + borda + 6 * u;
  } else if (gapR >= 12 * u) {
    planta = livreR - gapR * .5;
  }
  return (
    larga: true,
    kl: kl,
    kw: kw,
    xj: xj,
    jMeia: jMeia,
    xr: xr,
    quadros: quadros,
    jantar: jantar,
    planta: planta,
    porta: porta,
  );
}

/// Dois quadrinhos na parede, em volta de [x].
void _quadrinhos(_Pincel p, double x) {
  final u = p.u;
  for (final (dx, dy, w, cor) in [(-3.2, 18.0, 4.6, const Color(0xFFF2A541)), (2.6, 21.0, 3.8, const Color(0xFF6FC3C9))]) {
    final q = Rect.fromLTWH(x + dx * u - w * u / 2, dy * u, w * u, w * 1.2 * u);
    p.ret(q, const Color(0xFF3A2A33), contorno: .4);
    p.c.drawRect(q.deflate(.5 * u), p.tinta(cor));
    p.c.drawCircle(q.center, q.width * .18, p.tinta(_branco));
  }
}

/// A porta da sala (de madeira, com dois painéis, a maçaneta e o batente).
void _portaDaSala(_Pincel p, double x) {
  final u = p.u;
  final batente = Rect.fromLTRB(x - 7 * u, 15 * u, x + 7 * u, p.hz);
  p.ret(batente, const Color(0xFFFAF6EE), contorno: .8);
  final folha = Rect.fromLTRB(x - 5.8 * u, 16.4 * u, x + 5.8 * u, p.hz);
  p.ret(folha, const Color(0xFFC08A5B), contorno: .8);
  p.sombra(Path()..addRect(folha), Rect.fromLTRB(folha.right - 2 * u, folha.top, folha.right, folha.bottom), alfa: .1);
  final alto = folha.height;
  for (final (a, b) in [(.06, .42), (.5, .94)]) {
    p.ret(Rect.fromLTRB(folha.left + 1.4 * u, folha.top + alto * a, folha.right - 1.4 * u, folha.top + alto * b),
        const Color(0xFFB07C50), contorno: .45, raio: .3 * u);
  }
  p.circ(Offset(folha.right - 1.6 * u, folha.top + alto * .48), .6 * u, const Color(0xFFE9B949), contorno: .3);
}

/// A mesa de jantar redondinha (de lado) com duas cadeiras e um vaso de flor.
void _mesaDeJantar(_Pincel p, double x, double base) {
  final u = p.u;
  for (final lado in [-1.0, 1.0]) {
    final cx = x + lado * 8.2 * u;
    final encosto = lado < 0 ? cx - 2.2 * u : cx + 1.4 * u;
    p.ret(Rect.fromLTRB(encosto, base - 12.4 * u, encosto + .8 * u, base), const Color(0xFF9A6B44), contorno: .5);
    p.ret(Rect.fromLTRB(cx - 2.4 * u, base - 6.2 * u, cx + 2.4 * u, base - 5.2 * u), const Color(0xFFB07C50), contorno: .5);
    final pe = lado < 0 ? cx + 1.6 * u : cx - 2.4 * u;
    p.ret(Rect.fromLTRB(pe, base - 5.2 * u, pe + .8 * u, base), const Color(0xFF9A6B44), contorno: .4);
  }
  p.ret(Rect.fromLTRB(x - .6 * u, base - 7 * u, x + .6 * u, base - .8 * u), const Color(0xFF7A5232), contorno: .4);
  p.ret(Rect.fromLTRB(x - 3 * u, base - 1 * u, x + 3 * u, base), const Color(0xFF7A5232), contorno: .4, raio: .4 * u);
  p.ret(Rect.fromLTRB(x - 6.4 * u, base - 8 * u, x + 6.4 * u, base - 6.8 * u), const Color(0xFFC89B6C), contorno: .8, raio: .5 * u);
  // vaso com flor e dois pratos
  p.ret(Rect.fromLTRB(x - .8 * u, base - 10.6 * u, x + .8 * u, base - 8 * u), const Color(0xFF6FC3C9), contorno: .4, raio: .5 * u);
  p.c.drawLine(Offset(x, base - 10.6 * u), Offset(x, base - 12.4 * u), p.traco(.35));
  p.circ(Offset(x, base - 12.8 * u), .8 * u, const Color(0xFFFF8FB1), contorno: .3);
  for (final dx in [-4.0, 4.0]) {
    p.c.drawOval(Rect.fromCenter(center: Offset(x + dx * u, base - 8.2 * u), width: 3.6 * u, height: .8 * u), p.tinta(_branco));
    p.c.drawOval(Rect.fromCenter(center: Offset(x + dx * u, base - 8.2 * u), width: 3.6 * u, height: .8 * u), p.traco(.3));
  }
}

void _dCasa(_Pincel p) {
  final u = p.u;
  final s = _salaDaCasa(p);
  final jMeia = s.jMeia;
  // lá fora: o quintal, um morrinho e a árvore do vizinho
  _Onda(p, p.hz - 22 * u, 4 * u, const [(1.3, 1.0, .7), (3.1, .4, .2)]).pinta(const Color(0xFF8CC47A), fundo: p.hz, contorno: .3);
  p.laco(s.xj + jMeia * .4, 6 * u, (x) => _arvore(p, x, p.hz - 19 * u, 15 * u));
  final janelas = <RRect>[];
  p.laco(s.xj, jMeia + u,
      (x) => janelas.add(RRect.fromLTRBR(x - jMeia, 12 * u, x + jMeia, p.hz - 22 * u, Radius.circular(.8 * u))));
  _parede(p, const Color(0xFFF3E6D0), janelas);
  for (final j in janelas) {
    _moldura(p, j, _branco);
    _cortinas(p, j, const Color(0xFFE9B949));
  }
  final kw = s.kw;
  p.laco(s.kl + kw / 2, kw / 2 + u, (c) => _cozinha(p, c - kw / 2, kw));
  p.laco(s.kl + kw * .45, 3 * u, (x) => _pendente(p, x, 6 * u, const Color(0xFF3F7A5A)));
  if (s.larga) {
    p.laco(s.xr, 7 * u, (x) => _estante(p, x, 20 * u, p.hz, 6 * u));
    final q = s.quadros;
    if (q != null) p.laco(q, 6 * u, (x) => _quadrinhos(p, x));
    final jantar = s.jantar;
    if (jantar != null) {
      p.laco(jantar, 4 * u, (x) => _pendente(p, x, math.max(14 * u, p.hz - 34 * u), const Color(0xFFE9B949), largura: 3.6));
      p.laco(jantar - 9 * u, 6 * u, (x) => _quadrinhos(p, x));
    }
    final porta = s.porta;
    if (porta != null) p.laco(porta, 8 * u, (x) => _portaDaSala(p, x));
  } else {
    // tela estreita: um porta-retrato e a luminária de pé no canto
    p.laco(s.xr, 3 * u, (x) {
      final q = Rect.fromLTWH(x - 2 * u, 18 * u, 4 * u, 5 * u);
      p.ret(q, const Color(0xFF3A2A33), contorno: .4);
      p.c.drawRect(q.deflate(.5 * u), p.tinta(const Color(0xFF6FC3C9)));
    });
  }
  p.faixa(p.hz - 1.2 * u, p.hz, const Color(0xFFFAF6EE), contorno: .5);
}

/// Sofá de 2 lugares com almofadas.
void _sofa(_Pincel p, double x, double base, double meia) {
  final u = p.u;
  const cor = Color(0xFF3F8F8A);
  final costas = Rect.fromLTRB(x - meia + 1 * u, base - 11 * u, x + meia - 1 * u, base - 4 * u);
  p.ret(costas, cor, contorno: .9, raio: 1.6 * u);
  p.ret(Rect.fromLTRB(x - meia + 1.5 * u, base - 5.6 * u, x + meia - 1.5 * u, base - 2 * u), const Color(0xFF4FA39D), contorno: .8,
      raio: 1 * u);
  p.c.drawLine(Offset(x, base - 5.6 * u), Offset(x, base - 2 * u), p.traco(.4));
  for (final lado in [-1.0, 1.0]) {
    final braco = Rect.fromLTRB(lado < 0 ? x - meia : x + meia - 3 * u, base - 7.4 * u, lado < 0 ? x - meia + 3 * u : x + meia,
        base - 1.6 * u);
    p.ret(braco, cor, contorno: .9, raio: 1.4 * u);
    p.ret(Rect.fromLTRB(braco.center.dx - .4 * u, base - 1.6 * u, braco.center.dx + .4 * u, base), const Color(0xFF5A3D2B),
        contorno: .3);
  }
  // almofadas
  for (final (dx, cor2) in [(-.5, const Color(0xFFF2A541)), (.42, const Color(0xFFF07C6C))]) {
    final c = Offset(x + dx * meia, base - 7.4 * u);
    p.forma(
        Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 4.4 * u, height: 3.6 * u), Radius.circular(1.2 * u))),
        cor2,
        contorno: .6);
  }
}

/// A mesa do aluno (ele trabalha de casa): notebook aberto, caneca, abajur e a cadeira.
void _mesaComNotebook(_Pincel p, double x, double base) {
  final u = p.u;
  // cadeira de madeira, ao lado
  final cx = x - 9.4 * u;
  p.ret(Rect.fromLTRB(cx - 2.4 * u, base - 13 * u, cx - 1.6 * u, base), const Color(0xFF9A6B44), contorno: .5);
  p.ret(Rect.fromLTRB(cx - 2.4 * u, base - 13 * u, cx + 1.6 * u, base - 11 * u), const Color(0xFFB07C50), contorno: .5, raio: .3 * u);
  p.ret(Rect.fromLTRB(cx - 2.6 * u, base - 6.4 * u, cx + 2.8 * u, base - 5.4 * u), const Color(0xFFB07C50), contorno: .5);
  p.ret(Rect.fromLTRB(cx + 2 * u, base - 5.4 * u, cx + 2.8 * u, base), const Color(0xFF9A6B44), contorno: .4);
  // a mesa
  final tampo = Rect.fromLTRB(x - 7 * u, base - 7.6 * u, x + 7 * u, base - 6.4 * u);
  for (final dx in [-6.0, 6.0]) {
    p.ret(Rect.fromLTRB(x + dx * u - .45 * u, base - 6.4 * u, x + dx * u + .45 * u, base), const Color(0xFF7A5232), contorno: .4);
  }
  p.ret(Rect.fromLTRB(x - 6 * u, base - 6.4 * u, x + 1 * u, base - 4 * u), const Color(0xFFB98A5A), contorno: .5);
  p.c.drawCircle(Offset(x - 2.5 * u, base - 5.2 * u), .3 * u, p.tinta(const Color(0xFF3A2A33)));
  p.ret(tampo, const Color(0xFFC89B6C), contorno: .8, raio: .3 * u);
  // notebook (a tela acende à tarde e à noite)
  final tela = Rect.fromLTRB(x - 4.2 * u, base - 12.6 * u, x + 1.8 * u, base - 8.4 * u);
  p.ret(tela, const Color(0xFF3A3F4B), contorno: .7, raio: .4 * u);
  final dentro = tela.deflate(.45 * u);
  p.ret(dentro, const Color(0xFF3D7BD9), contorno: 0, emite: true);
  for (var i = 0; i < 3; i++) {
    p.c.drawRRect(
        RRect.fromLTRBR(dentro.left + .5 * u, dentro.top + (.7 + i * 1.1) * u, dentro.left + (2 + 1.2 * i) * u,
            dentro.top + (1.2 + i * 1.1) * u, Radius.circular(.2 * u)),
        Paint()..color = const Color(0xCCFFFFFF));
  }
  if (p.acesas) p.brilho(tela.center, 7 * u, const Color(0xFF7FB6FF), alfa: p.noite ? .32 : .18);
  p.ret(Rect.fromLTRB(x - 5 * u, base - 8.4 * u, x + 2.6 * u, base - 7.6 * u), const Color(0xFFB8C0CA), contorno: .5,
      raio: .3 * u);
  // caneca e abajur
  p.c.drawArc(Rect.fromLTWH(x + 4.2 * u, base - 9.6 * u, 1.3 * u, 1.3 * u), -math.pi / 2, math.pi, false, p.traco(.4));
  p.ret(Rect.fromLTWH(x + 2.6 * u, base - 9.9 * u, 2 * u, 2.3 * u), const Color(0xFFF07C6C), contorno: .5, raio: .4 * u);
  final ax = x + 5.6 * u;
  p.tubos([
    Path()
      ..moveTo(ax, base - 7.6 * u)
      ..lineTo(ax - 1.2 * u, base - 11.5 * u)
      ..lineTo(ax + .6 * u, base - 14 * u)
  ], .45 * u, const Color(0xFF3A4152), contorno: .4);
  final cupula = Path()
    ..moveTo(ax - .6 * u, base - 15 * u)
    ..lineTo(ax + 1.6 * u, base - 14.6 * u)
    ..lineTo(ax + 2.6 * u, base - 12.2 * u)
    ..lineTo(ax - .9 * u, base - 12.6 * u)
    ..close();
  if (p.acesas) _luzQuente(p, Offset(ax + .8 * u, base - 11.5 * u), 16 * u, forca: 1.2);
  p.forma(cupula, p.acesas ? const Color(0xFFFFE08A) : const Color(0xFFF2A541), contorno: .6, emite: p.acesas);
}

/// Banqueta alta (do balcão da cozinha).
void _banqueta(_Pincel p, double x, double base) {
  final u = p.u;
  p.tubos([
    for (final dx in [-1.6, 1.6])
      Path()
        ..moveTo(x + dx * .4 * u, base - 8 * u)
        ..lineTo(x + dx * u, base),
  ], .45 * u, const Color(0xFF3A4152), contorno: .4);
  p.c.drawLine(Offset(x - 1.3 * u, base - 3 * u), Offset(x + 1.3 * u, base - 3 * u), p.traco(.5));
  p.ret(Rect.fromCenter(center: Offset(x, base - 8.3 * u), width: 4.6 * u, height: 1.3 * u), const Color(0xFFB07C50), contorno: .7,
      raio: .6 * u);
}

void _cCasa(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFCFA273), Color(0xFFB2865A)]);
  final tabua = p.traco(.22);
  var y0 = p.hz;
  for (var i = 1; i < 9; i++) {
    final y = p.hz + i * i * .55 * u;
    p.c.drawLine(Offset(-2, y), Offset(p.w + 2, y), tabua);
    final juntas = p.vezes(11 * u);
    for (var k = 0; k < juntas; k++) {
      final x = (k + (i.isOdd ? .5 : 0) + .3 * _ruido(i * 13 + k)) * p.w / juntas;
      p.c.drawLine(Offset(x, y0), Offset(x, y), tabua);
    }
    y0 = y;
  }
  final s = _salaDaCasa(p);
  final kw = s.kw;
  final sofaMeia = math.min(12 * u, p.w * .17);
  // tapete e sofá embaixo da janela
  p.laco(s.xj, sofaMeia + 6 * u, (x) {
    final tapete = Path()..addOval(Rect.fromCenter(center: Offset(x, p.hz + 13 * u), width: sofaMeia * 2 + 10 * u, height: 7 * u));
    p.forma(tapete, const Color(0xFFD9674F), contorno: .6);
    p.c.drawOval(Rect.fromCenter(center: Offset(x, p.hz + 13 * u), width: sofaMeia * 2 + 6 * u, height: 4.6 * u),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .45 * u
          ..color = p.luz(const Color(0xFFF2C95C)));
    _sofa(p, x, p.hz + 8 * u, sofaMeia);
  });
  if (s.larga) {
    for (final f in [.45, .8]) {
      p.laco(s.kl + kw * f, 3 * u, (x) => _banqueta(p, x, p.hz + 5 * u));
    }
    p.laco(s.xr, 12 * u, (x) => _mesaComNotebook(p, x, p.hz + 9 * u));
    final jantar = s.jantar;
    if (jantar != null) p.laco(jantar, 11 * u, (x) => _mesaDeJantar(p, x, p.hz + 6 * u));
    final planta = s.planta;
    if (planta != null) p.laco(planta, 5 * u, (x) => _planta(p, x, p.hz + 4 * u, 14 * u, semente: 5));
  } else {
    // celular em pé: a mesa do notebook fica na frente da cozinha
    p.laco(s.kl + kw * .55, 12 * u, (x) => _mesaComNotebook(p, x, p.hz + 9 * u));
  }
}

// ─────────────────────────── restaurante (café e restaurante; a rua pela janela, sem pista) ───────────────────────────

/// Varal de lampadinhas de ponta a ponta (curvas entre os ganchos; acesas à tarde e à noite).
void _varalDeLuzes(_Pincel p, double y, double queda) {
  final u = p.u;
  final n = p.vezes(14 * u);
  final passo = p.w / n;
  const cores = [Color(0xFFFFD27F), Color(0xFFFF9E6B), Color(0xFFFFF0B3), Color(0xFF9FE0C8)];
  for (var i = 0; i < n; i++) {
    final a = i * passo, b = (i + 1) * passo;
    final ctrl = Offset((a + b) / 2, y + queda * 2);
    p.c.drawPath(
        Path()
          ..moveTo(a, y)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, b, y),
        p.traco(.3));
    for (var k = 1; k < 5; k++) {
      final s = k / 5;
      final pt = Offset((1 - s) * (1 - s) * a + 2 * (1 - s) * s * ctrl.dx + s * s * b,
          (1 - s) * (1 - s) * y + 2 * (1 - s) * s * ctrl.dy + s * s * y);
      final cor = cores[(i * 5 + k) % cores.length];
      p.laco(pt.dx, 2 * u, (x) {
        final o = Offset(x, pt.dy + .9 * u);
        if (p.acesas) p.brilho(o, 2.6 * u, cor, alfa: .55);
        p.c.drawOval(Rect.fromCenter(center: o, width: 1 * u, height: 1.4 * u),
            p.acesas ? (Paint()..color = cor) : p.tinta(Color.lerp(cor, const Color(0xFFFFFFFF), .4)!));
      });
    }
  }
}

/// Quadro-negro de cardápio: moldura de madeira, rabiscos de giz ilegíveis, uma xícara e um coração.
void _quadroNegro(_Pincel p, Rect r) {
  final u = p.u;
  p.ret(r.inflate(.8 * u), const Color(0xFF9A6B44), contorno: .8, raio: .4 * u);
  p.ret(r, const Color(0xFF2E3B33), contorno: .4);
  final giz = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(.8, .2 * u)
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xDDECE7D8);
  // título ondulado
  final t = Path()..moveTo(r.left + r.width * .2, r.top + 1.6 * u);
  for (var i = 1; i <= 6; i++) {
    t.lineTo(r.left + r.width * (.2 + i * .1), r.top + (1.6 + (i.isOdd ? -.5 : .3)) * u);
  }
  p.c.drawPath(t, giz..strokeWidth = math.max(.9, .3 * u));
  giz.strokeWidth = math.max(.7, .17 * u);
  final linhas = math.max(2, ((r.height - 5 * u) / (1.6 * u)).floor());
  for (var j = 0; j < linhas; j++) {
    final y = r.top + 3.6 * u + j * 1.6 * u;
    final comp = r.width * (.38 + .22 * _ruido(j * 3 + r.left.round()));
    final w = Path()..moveTo(r.left + 1 * u, y);
    for (var x = r.left + 1.6 * u; x < r.left + 1 * u + comp; x += .9 * u) {
      w.lineTo(x, y + ((x / u).round().isOdd ? -.25 : .2) * u);
    }
    p.c.drawPath(w, giz);
    p.c.drawCircle(Offset(r.right - 1.4 * u, y), .28 * u, Paint()..color = const Color(0xFFFFD27F));
  }
  // xícara e coração de giz
  final xc = Offset(r.right - r.width * .26, r.bottom - 2.4 * u);
  p.c.drawPath(
      Path()
        ..moveTo(xc.dx - 1.2 * u, xc.dy - 1 * u)
        ..lineTo(xc.dx + 1.2 * u, xc.dy - 1 * u)
        ..quadraticBezierTo(xc.dx + 1.1 * u, xc.dy + 1 * u, xc.dx, xc.dy + 1 * u)
        ..quadraticBezierTo(xc.dx - 1.1 * u, xc.dy + 1 * u, xc.dx - 1.2 * u, xc.dy - 1 * u),
      giz);
  p.c.drawArc(Rect.fromCenter(center: xc.translate(1.3 * u, -.2 * u), width: 1 * u, height: 1 * u), -math.pi / 2, math.pi, false, giz);
  final cor = Path()
    ..moveTo(r.left + r.width * .2, r.bottom - 1.2 * u)
    ..cubicTo(r.left + r.width * .2 - 1.6 * u, r.bottom - 2.2 * u, r.left + r.width * .2 - .6 * u, r.bottom - 3.6 * u,
        r.left + r.width * .2, r.bottom - 2.6 * u)
    ..cubicTo(r.left + r.width * .2 + .6 * u, r.bottom - 3.6 * u, r.left + r.width * .2 + 1.6 * u, r.bottom - 2.2 * u,
        r.left + r.width * .2, r.bottom - 1.2 * u);
  p.c.drawPath(cor, Paint()..color = const Color(0xFFF07C8C));
}

/// Prateleira de parede com garrafas e potes.
void _prateleiraDeGarrafas(_Pincel p, double x, double y0) {
  final u = p.u;
  const vidros = [Color(0xFF4E9A6A), Color(0xFFC77D3A), Color(0xFF7FB2C9), Color(0xFF9A3D4E), Color(0xFFE6C15A)];
  for (var s = 0; s < 2; s++) {
    final y = y0 + s * 7.5 * u;
    for (var k = 0; k < 4; k++) {
      final bx = x - 4.8 * u + k * 3.2 * u;
      final cor = vidros[(k + s * 2) % vidros.length];
      if ((k + s).isEven) {
        p.forma(
            Path()
              ..addRRect(RRect.fromLTRBR(bx - .9 * u, y - 4.4 * u, bx + .9 * u, y, Radius.circular(.5 * u)))
              ..addRect(Rect.fromLTRB(bx - .35 * u, y - 6 * u, bx + .35 * u, y - 4.2 * u)),
            cor,
            contorno: .45);
        p.c.drawRect(Rect.fromLTRB(bx - .9 * u, y - 3 * u, bx + .9 * u, y - 1.8 * u), p.tinta(const Color(0xFFF4ECD8)));
      } else {
        p.ret(Rect.fromLTRB(bx - 1.1 * u, y - 2.8 * u, bx + 1.1 * u, y), cor, contorno: .45, raio: .4 * u);
        p.ret(Rect.fromLTRB(bx - 1.2 * u, y - 3.4 * u, bx + 1.2 * u, y - 2.7 * u), const Color(0xFF9A6B44), contorno: .35);
      }
    }
    p.ret(Rect.fromLTRB(x - 6.6 * u, y, x + 6.6 * u, y + .9 * u), const Color(0xFF7A4E2E), contorno: .5);
  }
}

void _dRestaurante(_Pincel p) {
  final u = p.u;
  // lá fora: a calçada e as lojinhas do outro lado da rua, com toldos listrados
  final calcada = p.hz - 20 * u;
  const fachadas = [Color(0xFFE9C8A0), Color(0xFFB9D4E4), Color(0xFFF2D6DE), Color(0xFFCFE3C2)];
  const toldos = [Color(0xFF2EAD5B), Color(0xFFE5533D), Color(0xFF3E8AE0), Color(0xFFF2A541)];
  final m = p.vezes(16 * u);
  for (var i = 0; i < m; i++) {
    final passo = p.w / m;
    final x = i * passo;
    final topo = (13 + 6 * _ruido(i * 3 + 300)) * u;
    final f = Rect.fromLTRB(x + .2 * u, topo, x + passo - .2 * u, calcada);
    p.ret(f, fachadas[i % 4], contorno: .5);
    final vitrine = Rect.fromLTRB(f.left + passo * .14, calcada - 8 * u, f.right - passo * .14, calcada - 1 * u);
    p.ret(vitrine, p.acesas ? const Color(0xFFFFE6A8) : const Color(0xFF9CC7E0), contorno: .4, emite: p.acesas);
    final toldo = Path()
      ..moveTo(f.left + passo * .08, calcada - 10.5 * u)
      ..lineTo(f.right - passo * .08, calcada - 10.5 * u)
      ..lineTo(f.right - passo * .02, calcada - 7.6 * u)
      ..lineTo(f.left + passo * .02, calcada - 7.6 * u)
      ..close();
    p.forma(toldo, toldos[i % 4], contorno: .5);
    p.c.save();
    p.c.clipPath(toldo);
    for (var k = 0; k < 8; k++) {
      p.c.drawRect(Rect.fromLTWH(f.left + k * passo / 8, calcada - 11 * u, passo / 16, 4 * u), p.tinta(_branco));
    }
    p.c.restore();
    for (var j = 0; j < 2; j++) {
      p.c.drawRect(Rect.fromLTWH(f.left + passo * (.22 + j * .36), topo + 2 * u, passo * .2, 2.2 * u),
          p.noite && _ruido(i * 5 + j) > .4 ? (Paint()..color = const Color(0xFFFFD866)) : p.tinta(const Color(0xFF8FB7D4)));
    }
  }
  p.faixa(calcada, p.hz, const Color(0xFFBFBAB2), contorno: .5);
  final k = p.vezes(42 * u);
  for (var i = 0; i < k; i++) {
    p.laco((i + .1) / k * p.w, 4 * u, (x) => _poste(p, x, calcada + 1 * u, 18 * u, aceso: p.acesas));
  }
  // a parede: reboco cor de pêssego, janelas em arco e o lambri de tijolinho
  final passoJ = 42 * u;
  final janelas = _janelasDoInterior(p, passoJ, 10.5 * u, 11 * u, p.hz - 17 * u, arco: true);
  _parede(p, const Color(0xFFF6DCC6), janelas);
  for (final j in janelas) {
    _moldura(p, j, const Color(0xFF7A3E2E));
    final r = j.outerRect;
    p.ret(Rect.fromLTRB(r.left - 1.4 * u, r.bottom + .7 * u, r.right + 1.4 * u, r.bottom + 1.9 * u), const Color(0xFF7A3E2E),
        contorno: .6);
    // vasinho de ervas no peitoril
    p.ret(Rect.fromLTRB(r.center.dx + 3 * u, r.bottom - 1.6 * u, r.center.dx + 6 * u, r.bottom + .7 * u), const Color(0xFFE07B39),
        contorno: .4);
    p.blob([Rect.fromCircle(center: Offset(r.center.dx + 4.5 * u, r.bottom - 2.6 * u), radius: 1.6 * u)], const Color(0xFF58B562),
        contorno: .4, sombra: .1);
  }
  final n = p.vezes(passoJ);
  final passo = p.w / n;
  for (var i = 0; i < n; i++) {
    p.laco(i * passo, 8 * u, (x) {
      if (i.isEven || n == 1) {
        _pendente(p, x, 7 * u, const Color(0xFFB8432A));
        _quadroNegro(p, Rect.fromLTWH(x - 6.5 * u, 15 * u, 13 * u, 17 * u));
      } else {
        _pendente(p, x, 7 * u, const Color(0xFFB8432A));
        _prateleiraDeGarrafas(p, x, 22 * u);
      }
    });
  }
  _varalDeLuzes(p, 3 * u, 1.6 * u);
  final topo = p.hz - 14 * u;
  p.faixa(topo, p.hz, const Color(0xFFB65A40), contorno: .6, baixo: false);
  final rejunte = Paint()
    ..color = p.luz(const Color(0xFFE7CDB8))
    ..strokeWidth = math.max(.7, .22 * u);
  final fiada = 1.75 * u;
  var fila = 0;
  for (var y = topo + fiada; y < p.hz; y += fiada, fila++) {
    p.c.drawLine(Offset(-2, y), Offset(p.w + 2, y), rejunte);
    final tij = p.vezes(4.2 * u);
    for (var t = 0; t < tij; t++) {
      final x = (t + (fila.isOdd ? .5 : 0)) * p.w / tij;
      p.c.drawLine(Offset(x, y - fiada), Offset(x, y), rejunte);
    }
  }
  p.faixa(topo - 1.1 * u, topo, const Color(0xFF6E3A2A), contorno: .5);
}

/// Cadeira de bistrô (encosto redondo de madeira curvada).
void _cadeiraBistro(_Pincel p, double x, double base, {bool virada = false}) {
  final u = p.u;
  final s = virada ? -1.0 : 1.0;
  const madeira = Color(0xFF5A3426);
  final encosto = Path()
    ..moveTo(x - s * 1.6 * u, base - 5.4 * u)
    ..lineTo(x - s * 2 * u, base - 11 * u)
    ..quadraticBezierTo(x - s * 2.2 * u, base - 13.4 * u, x, base - 13.2 * u)
    ..quadraticBezierTo(x + s * 2.2 * u, base - 13 * u, x + s * 1.8 * u, base - 10.6 * u);
  p.tubos([
    encosto,
    Path()
      ..moveTo(x - 1.8 * u, base - 5.4 * u)
      ..lineTo(x - 2.2 * u, base),
    Path()
      ..moveTo(x + 1.8 * u, base - 5.4 * u)
      ..lineTo(x + 2.2 * u, base),
  ], .55 * u, madeira, contorno: .45);
  p.c.drawOval(Rect.fromCenter(center: Offset(x, base - 2.4 * u), width: 4 * u, height: .8 * u),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .35 * u
        ..color = p.luz(madeira));
  p.ret(Rect.fromCenter(center: Offset(x, base - 5.7 * u), width: 5.4 * u, height: 1.2 * u), const Color(0xFF7A4A34), contorno: .6,
      raio: .6 * u);
}

/// Mesa redonda com toalha xadrez, pratos, copos e uma vela (ou um vasinho de flor).
void _mesaDeRestaurante(_Pincel p, double x, double base, int semente) {
  final u = p.u;
  _cadeiraBistro(p, x - 9.4 * u, base + 1.4 * u);
  _cadeiraBistro(p, x + 9.4 * u, base + 1.4 * u, virada: true);
  p.tubos([
    Path()
      ..moveTo(x, base - 6 * u)
      ..lineTo(x, base)
  ], .9 * u, const Color(0xFF3A3A40), contorno: .5);
  p.c.drawOval(Rect.fromCenter(center: Offset(x, base), width: 6 * u, height: 1.1 * u), p.tinta(const Color(0xFF3A3A40)));
  final toalha = Path()
    ..moveTo(x - 8.6 * u, base - 9 * u)
    ..lineTo(x + 8.6 * u, base - 9 * u)
    ..lineTo(x + 9.4 * u, base - 4.6 * u);
  for (var i = 6; i >= 0; i--) {
    final xa = x - 9.4 * u + i * (18.8 * u / 6);
    toalha.quadraticBezierTo(xa + 18.8 * u / 12, base - 3.8 * u, xa, base - 4.6 * u);
  }
  toalha.close();
  final cor = semente.isEven ? const Color(0xFFD94F4F) : const Color(0xFF3E8AE0);
  p.forma(toalha, _branco, contorno: .8);
  p.c.save();
  p.c.clipPath(toalha);
  final xadrez = p.tinta(cor, alfa: .55);
  for (var i = 0; i < 12; i++) {
    p.c.drawRect(Rect.fromLTWH(x - 9.6 * u + i * 1.6 * u, base - 9.2 * u, .8 * u, 6 * u), xadrez);
  }
  for (var j = 0; j < 4; j++) {
    p.c.drawRect(Rect.fromLTWH(x - 10 * u, base - 9 * u + j * 1.6 * u, 20 * u, .8 * u), xadrez);
  }
  p.c.restore();
  p.sombra(toalha, Rect.fromLTRB(x - 10 * u, base - 6 * u, x + 10 * u, base - 3 * u), alfa: .12);
  // em cima: dois pratos, um copo e a vela ou a flor
  for (final dx in [-5.0, 4.6]) {
    p.c.drawOval(Rect.fromCenter(center: Offset(x + dx * u, base - 9.3 * u), width: 4.4 * u, height: 1.1 * u), p.tinta(_branco));
    p.c.drawOval(Rect.fromCenter(center: Offset(x + dx * u, base - 9.3 * u), width: 4.4 * u, height: 1.1 * u), p.traco(.4));
    p.c.drawOval(Rect.fromCenter(center: Offset(x + dx * u, base - 9.7 * u), width: 2.2 * u, height: .9 * u),
        p.tinta(semente.isEven ? const Color(0xFFF2A541) : const Color(0xFF8BC34A)));
  }
  p.ret(Rect.fromLTRB(x + 1.4 * u, base - 11.6 * u, x + 2.6 * u, base - 9.2 * u), const Color(0xFFCDEBF7), contorno: .4,
      alfa: .85);
  if (semente % 3 == 0) {
    p.ret(Rect.fromLTRB(x - 1.6 * u, base - 11.4 * u, x - .4 * u, base - 9.2 * u), const Color(0xFF6FC3C9), contorno: .4,
        raio: .3 * u);
    p.c.drawLine(Offset(x - 1 * u, base - 11.4 * u), Offset(x - 1.2 * u, base - 13.6 * u), p.traco(.35));
    p.circ(Offset(x - 1.2 * u, base - 14 * u), .8 * u, const Color(0xFFFF6F91), contorno: .3);
  } else {
    p.ret(Rect.fromLTRB(x - 1.7 * u, base - 11.8 * u, x - .3 * u, base - 9.2 * u), const Color(0xFFFFF3D6), contorno: .4,
        raio: .2 * u);
    final chama = Offset(x - 1 * u, base - 12.6 * u + math.sin(p.t * 7 + semente) * .1 * u);
    if (p.acesas) p.brilho(chama, 4 * u, const Color(0xFFFFC46B), alfa: .6);
    p.c.drawOval(Rect.fromCenter(center: chama, width: .7 * u, height: 1.2 * u), Paint()..color = const Color(0xFFFFB13D));
  }
}

/// O balcão do restaurante: frente de madeira, tampo claro, caixa registradora, pão e a campainha.
void _balcaoDoRestaurante(_Pincel p, double x, double base) {
  final u = p.u;
  final frente = Rect.fromLTRB(x - 13 * u, base - 9 * u, x + 13 * u, base);
  p.ret(Rect.fromLTRB(x - 11 * u, base - 14 * u, x - 4 * u, base - 10.3 * u), const Color(0xFF59636E), contorno: .7, raio: .5 * u);
  p.ret(Rect.fromLTRB(x - 10 * u, base - 13.4 * u, x - 6.6 * u, base - 11.8 * u), const Color(0xFF8BE0C8), contorno: .4,
      emite: true);
  p.forma(
      Path()
        ..moveTo(x + 2 * u, base - 10.3 * u)
        ..quadraticBezierTo(x + 2.4 * u, base - 13.4 * u, x + 5.6 * u, base - 13.4 * u)
        ..quadraticBezierTo(x + 8.8 * u, base - 13.4 * u, x + 9.2 * u, base - 10.3 * u)
        ..close(),
      const Color(0xFFD9A066),
      contorno: .6);
  for (var i = 0; i < 3; i++) {
    p.c.drawLine(Offset(x + (3.8 + i * 1.8) * u, base - 12.6 * u), Offset(x + (4.6 + i * 1.8) * u, base - 11 * u), p.traco(.3));
  }
  p.c.drawArc(Rect.fromCenter(center: Offset(x + 11 * u, base - 10.3 * u), width: 2 * u, height: 2 * u), math.pi, math.pi, true,
      p.tinta(const Color(0xFFFFC83D)));
  p.ret(Rect.fromLTRB(x - 14 * u, base - 10.3 * u, x + 14 * u, base - 9 * u), const Color(0xFFEDE6DA), contorno: .8);
  p.ret(frente, const Color(0xFF8A4F35), contorno: 1);
  final painel = p.traco(.35);
  for (var i = 0; i < 4; i++) {
    p.c.drawRect(Rect.fromLTWH(frente.left + 1 * u + i * 6.25 * u, frente.top + 1.2 * u, 5.25 * u, frente.height - 2.4 * u), painel);
  }
  p.sombra(Path()..addRect(frente), Rect.fromLTRB(frente.left, frente.bottom - 1.6 * u, frente.right, frente.bottom));
}

void _cRestaurante(_Pincel p) {
  final u = p.u;
  // lajotas de terracota em xadrez (fundo chapado por baixo: as emendas não vazam)
  p.solo(const [Color(0xFFC7845E), Color(0xFFC7845E)], contorno: 0);
  const linhas = 6;
  final altura = p.h - p.hz;
  var y = p.hz;
  final cols = p.vezesPar(6 * u);
  for (var l = 0; l < linhas; l++) {
    final hL = altura * (l + 1) / (linhas * (linhas + 1) / 2);
    for (var c = 0; c < cols; c++) {
      p.c.drawRect(Rect.fromLTWH(c * p.w / cols, y, p.w / cols + .5, hL + .5),
          p.tinta((c + l).isEven ? const Color(0xFFD08F67) : const Color(0xFFB8704C)));
    }
    y += hL;
  }
  p.c.drawLine(Offset(-2, p.hz), Offset(p.w + 2, p.hz), p.traco(.5));
  final m = p.vezes(36 * u);
  for (var i = 0; i < m; i++) {
    p.laco((i + .5) * p.w / m, 16 * u, (x) {
      if (m >= 3 && i == 0) {
        _balcaoDoRestaurante(p, x, p.hz + 9 * u);
      } else {
        _mesaDeRestaurante(p, x, p.hz + 9 * u, i);
      }
    });
  }
}

// ─────────────────────────── loja (prateleiras, caixa com maquininha, cartazes de preço) ───────────────────────────

/// O módulo da loja (n ≥ 1 por tela): gôndola, porta de vidro, cartaz/gôndola.
(int, double) _modulosDaLoja(_Pincel p) {
  final n = p.vezes(80 * p.u);
  return (n, p.w / n);
}

/// O módulo da entrada (a porta de vidro, o cartaz "$5" e o caixa): UM por tela, no meio. Os outros módulos
/// trocam a porta por mais uma gôndola e o caixa por uma banca de frutas (a loja não repete a entrada inteira).
int _entradaDaLoja(int n) => n ~/ 2;

/// Etiqueta de preço amarela com "$" e algarismos genéricos.
void _etiqueta(_Pincel p, Offset o, String preco, double alt) {
  final u = p.u;
  final w = _larguraDosDigitos(preco, alt) + 1 * u;
  final r = Rect.fromLTWH(o.dx - w / 2, o.dy, w, alt + .8 * u);
  p.ret(r, const Color(0xFFFFE066), contorno: .35, raio: .2 * u);
  _digitos(p, preco, Offset(r.left + .5 * u, r.top + .4 * u), alt, const Color(0xFFD33A2C), emite: false);
}

/// Gôndola de parede com 4 prateleiras de produtos (caixas, garrafas, potes e latas) e as etiquetas.
void _gondola(_Pincel p, double x, double meia, double topo, double base, int semente) {
  final u = p.u;
  final r = Rect.fromLTRB(x - meia, topo, x + meia, base);
  p.ret(r, const Color(0xFFDCE3E6), contorno: .9, raio: .3 * u);
  p.ret(Rect.fromLTRB(r.left, topo - 3 * u, r.right, topo), const Color(0xFF2BB3A3), contorno: .7);
  const prateleiras = 4;
  final alto = (r.height - 1 * u) / prateleiras;
  const cores = [
    Color(0xFFE5533D), Color(0xFFF2A541), Color(0xFF3E8AE0), Color(0xFF7CC160), Color(0xFF8E44AD), Color(0xFFFF8FB1),
  ];
  for (var s = 0; s < prateleiras; s++) {
    final y = r.top + (s + 1) * alto;
    var bx = r.left + .6 * u;
    var k = 0;
    while (bx < r.right - 2 * u) {
      final seed = semente * 97 + s * 29 + k * 7;
      final tipo = (_ruido(seed) * 4).floor();
      final cor = cores[(seed * 3 + k) % cores.length];
      switch (tipo) {
        case 0: // caixa
          final bw = 2.6 * u, bh = alto * .62;
          p.ret(Rect.fromLTRB(bx, y - bh, math.min(bx + bw, r.right - .4 * u), y), cor, contorno: .4, raio: .2 * u);
          p.c.drawRect(Rect.fromLTRB(bx + .4 * u, y - bh * .62, math.min(bx + bw - .4 * u, r.right - .8 * u), y - bh * .4),
              p.tinta(_branco, alfa: .8));
          bx += bw + .3 * u;
        case 1: // garrafa
          p.forma(
              Path()
                ..addRRect(RRect.fromLTRBR(bx, y - alto * .55, bx + 1.5 * u, y, Radius.circular(.5 * u)))
                ..addRect(Rect.fromLTRB(bx + .45 * u, y - alto * .72, bx + 1.05 * u, y - alto * .5)),
              cor,
              contorno: .4);
          bx += 1.9 * u;
        case 2: // pote
          p.ret(Rect.fromLTRB(bx, y - alto * .4, bx + 2.2 * u, y), Color.lerp(cor, _branco, .5)!, contorno: .4, raio: .4 * u);
          p.ret(Rect.fromLTRB(bx - .1 * u, y - alto * .48, bx + 2.3 * u, y - alto * .38), cor, contorno: .3);
          bx += 2.6 * u;
        default: // latas empilhadas
          for (var l = 0; l < 2; l++) {
            p.ret(Rect.fromLTRB(bx, y - (l + 1) * alto * .26, bx + 1.6 * u, y - l * alto * .26), cor, contorno: .35, raio: .2 * u);
          }
          bx += 2 * u;
      }
      k++;
    }
    p.ret(Rect.fromLTRB(r.left, y, r.right, y + .9 * u), const Color(0xFF8D99A8), contorno: .5);
    if (meia > 5 * u) {
      final preco = '${r'$'}${1 + (_ruido(semente * 13 + s) * 9).floor()}';
      _etiqueta(p, Offset(r.left + meia * (.5 + .9 * _ruido(semente * 11 + s)), y + .2 * u), preco, 1.3 * u);
    }
  }
}

/// Cartaz de oferta com o preço em algarismos grandes.
void _cartazDePreco(_Pincel p, Rect r, String preco) {
  final u = p.u;
  p.ret(r, const Color(0xFFFFE066), contorno: .8, raio: .5 * u);
  p.ret(Rect.fromLTRB(r.left, r.top, r.right, r.top + r.height * .26), const Color(0xFFE5533D), contorno: .6, raio: .5 * u);
  // estrelinha de "oferta" (sem palavras)
  final c = Offset(r.center.dx, r.top + r.height * .13);
  final estrela = Path();
  for (var i = 0; i < 10; i++) {
    final rr = i.isEven ? r.height * .1 : r.height * .045;
    final a = -math.pi / 2 + i * math.pi / 5;
    final o = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? estrela.moveTo(o.dx, o.dy) : estrela.lineTo(o.dx, o.dy);
  }
  p.c.drawPath(estrela..close(), p.tinta(_branco));
  final alt = math.min(r.height * .42, (r.width - 1.6 * u) / (_larguraDosDigitos(preco, 1) + .01));
  final w = _larguraDosDigitos(preco, alt);
  _digitos(p, preco, Offset(r.center.dx - w / 2, r.top + r.height * .38), alt, const Color(0xFFD33A2C), emite: false);
}

void _dLoja(_Pincel p) {
  final u = p.u;
  final (n, mw) = _modulosDaLoja(p);
  // lá fora, pela porta de vidro: o céu, o prédio da frente (com janelas) e a calçada
  p.faixa(30 * u, p.hz - 6 * u, const Color(0xFFD9B99A), contorno: .4, baixo: false);
  final jan = p.vezes(6 * u);
  for (var i = 0; i < jan; i++) {
    for (final y in [33.0, 41.0]) {
      p.c.drawRect(Rect.fromLTWH(i * p.w / jan + 1.5 * u, y * u, 2.6 * u, 4 * u),
          p.noite && _ruido(i * 3 + y.round()) > .4 ? (Paint()..color = const Color(0xFFFFD866)) : p.tinta(const Color(0xFF8FB7D4)));
    }
  }
  p.faixa(p.hz - 6 * u, p.hz, const Color(0xFFB9B9B4), contorno: .4);
  // a porta de vidro de cada módulo (vazada na parede)
  final dMeia = math.min(6.5 * u, mw * .14);
  final portas = <RRect>[];
  final entrada = _entradaDaLoja(n);
  p.laco(entrada * mw + mw * .56, dMeia + u,
      (x) => portas.add(RRect.fromLTRBR(x - dMeia, 18 * u, x + dMeia, p.hz, Radius.circular(.4 * u))));
  _parede(p, const Color(0xFFE6F3EF), portas);
  // faixa colorida no alto e as bandeirinhas
  p.faixa(3 * u, 6.4 * u, const Color(0xFF2BB3A3), contorno: .6);
  p.faixa(-2, 3 * u, const Color(0xFFF7F8F8), contorno: .4);
  final tubos = p.vezes(20 * u);
  for (var i = 0; i < tubos; i++) {
    p.laco((i + .5) * p.w / tubos, 5 * u, (x) {
      final t = Rect.fromCenter(center: Offset(x, 1.5 * u), width: 9 * u, height: .9 * u);
      p.ret(t, const Color(0xFFF4FBFF), contorno: .35, emite: true, raio: .4 * u);
      if (p.acesas) p.brilho(t.center, 8 * u, const Color(0xFFE6F6FF), alfa: .3);
    });
  }
  final band = p.vezes(4 * u);
  for (var i = 0; i < band; i++) {
    final x = i * p.w / band;
    p.forma(
        Path()
          ..moveTo(x + .3 * u, 6.4 * u)
          ..lineTo(x + p.w / band - .3 * u, 6.4 * u)
          ..lineTo(x + p.w / band / 2, 9.2 * u)
          ..close(),
        _publico[i % 6],
        contorno: .35);
  }
  for (final j in portas) {
    final r = j.outerRect;
    p.c.save();
    p.c.clipRRect(j);
    p.c.drawRect(r, Paint()..color = const Color(0x2E9FD8F0));
    p.c.drawPath(
        Path()
          ..moveTo(r.left + r.width * .2, r.top)
          ..lineTo(r.left + r.width * .45, r.top)
          ..lineTo(r.left + r.width * .1, r.bottom)
          ..lineTo(r.left - r.width * .15, r.bottom)
          ..close(),
        Paint()..color = const Color(0x30FFFFFF));
    p.c.restore();
    _moldura(p, j, const Color(0xFF8D99A8), cruz: false);
    p.c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), p.traco(.5));
    p.tubos([
      Path()
        ..moveTo(r.left + 1.2 * u, r.center.dy + 2 * u)
        ..lineTo(r.right - 1.2 * u, r.center.dy + 2 * u)
    ], .6 * u, const Color(0xFFB8C0CA), contorno: .4);
    // plaquinha pendurada (aberto = verde)
    final placa = Rect.fromCenter(center: Offset(r.center.dx, r.top + 6 * u), width: 6 * u, height: 3 * u);
    p.c.drawLine(Offset(placa.left + 1 * u, placa.top), Offset(r.center.dx, r.top + 2.6 * u), p.traco(.3));
    p.c.drawLine(Offset(placa.right - 1 * u, placa.top), Offset(r.center.dx, r.top + 2.6 * u), p.traco(.3));
    p.ret(placa, const Color(0xFF2EAD5B), contorno: .5, raio: .4 * u);
    p.c.drawRRect(RRect.fromLTRBR(placa.left + 1 * u, placa.center.dy - .3 * u, placa.right - 1 * u, placa.center.dy + .3 * u,
        Radius.circular(.3 * u)), Paint()..color = const Color(0xFFEFFFF4));
  }
  for (var i = 0; i < n; i++) {
    final x0 = i * mw;
    final gMeia = math.min(12 * u, mw * .18);
    p.laco(x0 + mw * .22, gMeia + u, (x) => _gondola(p, x, gMeia, 16 * u, p.hz, i * 2));
    if (mw >= 64 * u) {
      p.laco(x0 + mw * .86, gMeia + u, (x) => _gondola(p, x, gMeia, 16 * u, p.hz, i * 2 + 1));
    } else {
      p.laco(x0 + mw * .86, 5 * u, (x) => _cartazDePreco(p, Rect.fromLTWH(x - 4.4 * u, 16 * u, 8.8 * u, 12 * u), r'$9.99'));
    }
    if (i != entrada) {
      final m = math.min(gMeia, mw * .13);
      p.laco(x0 + mw * .56, m + u, (x) => _gondola(p, x, m, 16 * u, p.hz, i * 2 + 7));
    } else if (mw >= 64 * u) {
      p.laco(x0 + mw * .56, 6 * u, (x) => _cartazDePreco(p, Rect.fromLTWH(x - 5 * u, 10.5 * u, 10 * u, 6.6 * u), r'$5'));
    }
  }
  p.faixa(p.hz - 1 * u, p.hz, const Color(0xFF8D99A8), contorno: .5);
}

/// O caixa: balcão, telinha, a maquininha de cartão, a esteira e o expositor de balas.
void _caixaDaLoja(_Pincel p, double x, double base, double meia) {
  final u = p.u;
  final frente = Rect.fromLTRB(x - meia, base - 9 * u, x + meia, base);
  // telinha do caixa
  p.tubos([
    Path()
      ..moveTo(x - meia + 5 * u, base - 10.2 * u)
      ..lineTo(x - meia + 5 * u, base - 13 * u)
  ], .6 * u, const Color(0xFF59636E), contorno: .4);
  final tela = Rect.fromLTRB(x - meia + 2 * u, base - 17 * u, x - meia + 8 * u, base - 12.6 * u);
  p.ret(tela, const Color(0xFF263244), contorno: .7, raio: .4 * u);
  p.ret(tela.deflate(.5 * u), const Color(0xFF8BE0C8), contorno: 0, emite: true);
  _digitos(p, r'$12', Offset(tela.left + .9 * u, tela.top + 1.2 * u), 1.8 * u, const Color(0xFF17473C));
  // a maquininha de cartão (teclado e telinha) e um cartão encostado
  final maq = Rect.fromLTRB(x + meia - 7 * u, base - 14.2 * u, x + meia - 3.6 * u, base - 10.2 * u);
  p.ret(maq, const Color(0xFF3A3F4B), contorno: .7, raio: .6 * u);
  p.ret(Rect.fromLTRB(maq.left + .6 * u, maq.top + .6 * u, maq.right - .6 * u, maq.top + 1.8 * u), const Color(0xFF9FE0C8),
      contorno: 0, emite: true);
  final tecla = Paint()..color = const Color(0xFFDCE3EE);
  for (var a = 0; a < 3; a++) {
    for (var b = 0; b < 3; b++) {
      p.c.drawCircle(Offset(maq.left + (1 + a * .7) * u, maq.top + (2.5 + b * .55) * u), .2 * u, tecla);
    }
  }
  p.ret(Rect.fromLTRB(maq.right + .3 * u, base - 12.6 * u, maq.right + 2.6 * u, base - 10.2 * u), const Color(0xFF3E8AE0),
      contorno: .4, raio: .2 * u);
  // tampo e esteira
  p.ret(Rect.fromLTRB(x - meia - .6 * u, base - 10.2 * u, x + meia + .6 * u, base - 9 * u), const Color(0xFFDCE3EE), contorno: .8);
  p.c.drawRect(Rect.fromLTRB(x - meia + 9.5 * u, base - 10.5 * u, x + meia - 9 * u, base - 10 * u),
      p.tinta(const Color(0xFF2B2B2B)));
  p.ret(frente, const Color(0xFF2BB3A3), contorno: 1);
  p.ret(Rect.fromLTRB(frente.left, frente.top + 1.6 * u, frente.right, frente.top + 2.4 * u), _branco, contorno: .3);
  p.sombra(Path()..addRect(frente), Rect.fromLTRB(frente.left, frente.bottom - 1.6 * u, frente.right, frente.bottom));
  // expositor de balas na frente do caixa
  final ex = x - meia * .35;
  p.ret(Rect.fromLTRB(ex - 3 * u, base - 7.6 * u, ex + 3 * u, base - .6 * u), const Color(0xFFDCE3E6), contorno: .6);
  for (var s = 0; s < 3; s++) {
    for (var k = 0; k < 4; k++) {
      p.circ(Offset(ex - 2.1 * u + k * 1.4 * u, base - 6.4 * u + s * 2.2 * u), .55 * u, _publico[(s * 4 + k) % 6], contorno: .25);
    }
  }
}

/// Pilha de cestinhas vermelhas.
void _cestas(_Pincel p, double x, double base) {
  final u = p.u;
  for (var i = 0; i < 3; i++) {
    final y = base - i * 1.3 * u;
    final cesta = Path()
      ..moveTo(x - 3.2 * u, y - 3.6 * u)
      ..lineTo(x + 3.2 * u, y - 3.6 * u)
      ..lineTo(x + 2.6 * u, y)
      ..lineTo(x - 2.6 * u, y)
      ..close();
    p.forma(cesta, const Color(0xFFE5533D), contorno: .6);
    p.c.drawLine(Offset(x - 2.4 * u, y - 1.8 * u), Offset(x + 2.4 * u, y - 1.8 * u), p.traco(.25));
  }
  final topo = base - 2 * 1.3 * u - 3.6 * u;
  p.c.drawArc(Rect.fromLTRB(x - 2.6 * u, topo - 2.6 * u, x + 2.6 * u, topo + 1 * u), math.pi, math.pi, false, p.traco(.6));
}

void _cLoja(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFE2E7EA), Color(0xFFC3CDD3)]);
  final r = Rect.fromLTRB(-2, p.hz, p.w + 2, p.hz + 9 * u);
  p.c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_branco.withValues(alpha: p.noite ? .1 : .35), const Color(0x00FFFFFF)],
        ).createShader(r));
  final junta = Paint()
    ..strokeWidth = math.max(1.0, .22 * u)
    ..color = const Color(0x2A3A2A33);
  for (final f in [4.0, 9.5, 16.0, 24.0]) {
    p.c.drawLine(Offset(-2, p.hz + f * u), Offset(p.w + 2, p.hz + f * u), junta);
  }
  final k = p.vezes(12 * u);
  for (var i = 0; i < k; i++) {
    final x = i * p.w / k;
    p.c.drawLine(Offset(x, p.hz), Offset(x + 3 * u, p.h), junta);
  }
  final (n, mw) = _modulosDaLoja(p);
  final entrada = _entradaDaLoja(n);
  for (var i = 0; i < n; i++) {
    final x0 = i * mw;
    if (i == entrada) {
      final cMeia = math.min(15 * u, mw * .3);
      p.laco(x0 + mw * .3, cMeia + 2 * u, (x) => _caixaDaLoja(p, x, p.hz + 9 * u, cMeia));
      p.laco(x0 + mw * .78, 4 * u, (x) => _cestas(p, x, p.hz + 11 * u));
    } else {
      p.laco(x0 + mw * .45, 9 * u, (x) => _bancaDeFrutas(p, x, p.hz + 10 * u, i));
    }
  }
}

/// Banca de frutas (caixotes de madeira com laranjas, maçãs e limões) e a plaquinha de preço.
void _bancaDeFrutas(_Pincel p, double x, double base, int semente) {
  final u = p.u;
  const frutas = [Color(0xFFF2A541), Color(0xFFE5533D), Color(0xFF7CC160)];
  for (var k = 0; k < 3; k++) {
    final cx = x + (k - 1) * 5.4 * u;
    final caixa = Rect.fromLTRB(cx - 2.6 * u, base - 5.4 * u, cx + 2.6 * u, base);
    final cor = frutas[(k + semente) % 3];
    for (var a = 0; a < 3; a++) {
      p.circ(Offset(cx - 1.6 * u + a * 1.6 * u, base - 5.6 * u), .9 * u, cor, contorno: .3);
    }
    p.circ(Offset(cx - .8 * u, base - 6.9 * u), .9 * u, cor, contorno: .3);
    p.circ(Offset(cx + .8 * u, base - 6.9 * u), .9 * u, cor, contorno: .3);
    p.ret(caixa, const Color(0xFFC89B6C), contorno: .6);
    p.c.drawLine(Offset(caixa.left, caixa.center.dy), Offset(caixa.right, caixa.center.dy), p.traco(.3));
  }
  _etiqueta(p, Offset(x, base - 3.4 * u), r'$' '${1 + semente % 3}', 1.6 * u);
}

// ─────────────────────────── 2ª leva das lições (pedidos de arte dos lotes) ───────────────────────────
//
// Como a `casa` e a `loja`: cada cenário é UM cômodo em qualquer largura. As peças principais (o balcão, o
// telão, o sofá…) aparecem uma vez só; o que sobra de parede numa tela larga vira janela, quadro ou planta
// ([_vaosDaParede]), nunca outra cópia do cômodo.

/// Os vãos de parede (centro, meia largura) entre as peças [ocupadas] (centro, meia largura), dando a volta na
/// largura (a pintura é periódica): só os de meia largura ≥ [minimo].
List<(double, double)> _vaosDaParede(_Pincel p, List<(double, double)> ocupadas, {double minimo = 0}) {
  if (ocupadas.isEmpty) return [(p.w / 2, p.w / 2)];
  final ord = [...ocupadas]..sort((a, b) => (a.$1 - a.$2).compareTo(b.$1 - b.$2));
  final vaos = <(double, double)>[];
  for (var i = 0; i < ord.length; i++) {
    final fim = ord[i].$1 + ord[i].$2;
    final prox = i + 1 < ord.length ? ord[i + 1].$1 - ord[i + 1].$2 : ord[0].$1 - ord[0].$2 + p.w;
    // o vão que passa pela borda vira dois (um de cada lado): nada fica cortado ao meio na tela parada
    for (final (a, b) in fim < p.w && prox > p.w ? [(fim, p.w), (p.w, prox)] : [(fim, prox)]) {
      final meia = (b - a) / 2;
      if (meia >= minimo && meia > 0) vaos.add(((a + meia) % p.w, meia));
    }
  }
  return vaos;
}

/// Quadro de paisagem com moldura dourada (enfeite de parede de hotel e de sala).
void _quadroDePaisagem(_Pincel p, Rect r, int semente) {
  final u = p.u;
  p.ret(r.inflate(.9 * u), const Color(0xFFD9A441), contorno: .7, raio: .2 * u);
  final dentro = r;
  p.c.save();
  p.c.clipRect(dentro);
  const ceus = [Color(0xFF9FD3F5), Color(0xFFFFC9A0), Color(0xFFB9C9EC)];
  p.c.drawRect(dentro, p.tinta(ceus[semente % 3]));
  p.c.drawCircle(Offset(dentro.left + dentro.width * (.25 + .5 * _ruido(semente + 3)), dentro.top + dentro.height * .3),
      dentro.height * .12, p.tinta(const Color(0xFFFFE08A)));
  final morro = Path()
    ..moveTo(dentro.left, dentro.bottom)
    ..lineTo(dentro.left, dentro.top + dentro.height * .62)
    ..quadraticBezierTo(dentro.left + dentro.width * .3, dentro.top + dentro.height * .38, dentro.left + dentro.width * .6,
        dentro.top + dentro.height * .6)
    ..quadraticBezierTo(dentro.left + dentro.width * .8, dentro.top + dentro.height * .72, dentro.right, dentro.top + dentro.height * .55)
    ..lineTo(dentro.right, dentro.bottom)
    ..close();
  p.c.drawPath(morro, p.tinta(semente.isEven ? const Color(0xFF6DB36A) : const Color(0xFF4F9A8A)));
  p.c.restore();
  p.c.drawRect(dentro, p.traco(.35));
}

// ─────────────────────────── copa (a copa do escritório: café, micro-ondas e a vista de Chicago) ───────────────────────────

/// A planta da copa: o balcão (geladeira, cafeteira, pia, micro-ondas) à esquerda, uma vez só; a janela grande
/// com a mesa alta na frente; na tela larga, a parede de vidro da sala de reunião, o mural e o bebedouro.
typedef _PlantaCopa = ({
  double kl, // começo do balcão
  double kw, // largura do balcão (com a geladeira)
  double xj, // meio da janela (e da mesa alta)
  double jMeia,
  double? vidro, // a sala de reunião de vidro
  double? mural,
  double? galao, // o bebedouro
});

_PlantaCopa _plantaDaCopa(_Pincel p) {
  final u = p.u, w = p.w;
  if (w < 70 * u) {
    final kw = math.min(40 * u, w * .55);
    final kl = w * .03;
    final livre = w - kl - kw;
    return (
      kl: kl,
      kw: kw,
      xj: kl + kw + livre / 2,
      jMeia: math.max(3 * u, math.min(9 * u, livre / 2 - 2.5 * u)),
      vidro: null,
      mural: null,
      galao: null,
    );
  }
  final kl = math.min(w * .03, 4 * u);
  final kw = math.min(46 * u, w * .4);
  final vidro = w >= 125 * u ? w - 19 * u : null;
  final livreL = kl + kw + 3 * u, livreR = (vidro != null ? vidro - 16 * u : w - 2 * u) - 2 * u;
  final livre = livreR - livreL;
  final jMeia = (livre * .32).clamp(9 * u, 34 * u).toDouble();
  final xj = livreL + livre * .5;
  final gapL = xj - jMeia - 1.5 * u - livreL, gapR = livreR - (xj + jMeia + 1.5 * u);
  return (
    kl: kl,
    kw: kw,
    xj: xj,
    jMeia: jMeia,
    vidro: vidro,
    mural: gapL >= 12 * u ? livreL + gapL / 2 : null,
    galao: gapR >= 8 * u ? livreR - gapR / 2 : null,
  );
}

/// A vista pelas janelas da copa: os prédios de Chicago (as luzes acendem à noite).
void _vistaDaCopa(_Pincel p, double fundoFora) {
  final u = p.u;
  const cores = [Color(0xFF8796B0), Color(0xFF9EA9BF), Color(0xFF75859F), Color(0xFFA19CB5)];
  final m = p.vezes(8 * u);
  for (var i = 0; i < m; i++) {
    final passo = p.w / m;
    final larg = passo * (.7 + .26 * _ruido(i * 7 + 811));
    final alt = (10 + 26 * _ruido(i * 7 + 812)) * u;
    _predio(p, Rect.fromLTWH(i * passo + (passo - larg) / 2, fundoFora - alt, larg, alt + 1 * u), cores[i % 4],
        semente: i + 90);
  }
}

/// O balcão da copa, de [l] até [l] + [larg]: geladeira de inox, azulejo de metrô, armários, a cafeteira
/// (com a luzinha), a pia, as canecas penduradas e o micro-ondas com o relógio da hora.
void _balcaoDaCopa(_Pincel p, double l, double larg) {
  final u = p.u;
  final r = l + larg;
  final fw = math.min(9 * u, larg * .24);
  final bancada = p.hz - 10 * u;
  // azulejo de metrô atrás da bancada
  final azulejo = Rect.fromLTRB(l + fw, 23 * u, r, bancada);
  p.c.drawRect(azulejo, p.tinta(const Color(0xFFF4F6F7)));
  final rejunte = Paint()
    ..color = p.luz(const Color(0xFFCBD3D8))
    ..strokeWidth = math.max(.6, .15 * u);
  var linha = 0;
  for (var y = azulejo.top; y < azulejo.bottom; y += 1.6 * u, linha++) {
    p.c.drawLine(Offset(azulejo.left, y), Offset(azulejo.right, y), rejunte);
    for (var x = azulejo.left + (linha.isOdd ? 1.8 * u : 0); x < azulejo.right; x += 3.6 * u) {
      p.c.drawLine(Offset(x, y), Offset(x, math.min(y + 1.6 * u, azulejo.bottom)), rejunte);
    }
  }
  // armários de cima (brancos, puxadores de madeira)
  final arm = Rect.fromLTRB(l + fw + .6 * u, 9 * u, r, 21.5 * u);
  p.ret(arm, const Color(0xFFE9EDF0), contorno: .8, raio: .3 * u);
  final portas = math.max(1, (arm.width / (7 * u)).round());
  for (var i = 0; i < portas; i++) {
    final a = arm.left + arm.width * i / portas, b = arm.left + arm.width * (i + 1) / portas;
    if (i > 0) p.c.drawLine(Offset(a, arm.top), Offset(a, arm.bottom), p.traco(.4));
    p.ret(Rect.fromLTRB((a + b) / 2 - 1.2 * u, arm.bottom - 1.6 * u, (a + b) / 2 + 1.2 * u, arm.bottom - 1 * u),
        const Color(0xFFB07C50), contorno: .25, raio: .2 * u);
  }
  // canecas penduradas embaixo do armário
  final nCanecas = math.max(2, ((r - l - fw) / (4.2 * u)).floor() ~/ 2);
  for (var i = 0; i < nCanecas; i++) {
    final x = l + fw + 2.4 * u + i * 3.4 * u;
    if (x > r - 14 * u) break;
    p.c.drawLine(Offset(x + .8 * u, arm.bottom), Offset(x + .8 * u, arm.bottom + 1.2 * u), p.traco(.25));
    p.ret(Rect.fromLTWH(x, arm.bottom + 1.2 * u, 1.7 * u, 2 * u), _publico[(i * 2 + 1) % 6], contorno: .4, raio: .3 * u);
  }
  // a cafeteira (a máquina de café do escritório)
  final xc = l + fw + math.max(5 * u, (r - l - fw) * .26);
  final maquina = Rect.fromLTRB(xc - 3.6 * u, bancada - 10 * u, xc + 3.6 * u, bancada);
  p.ret(maquina, const Color(0xFF2E3238), contorno: .8, raio: .6 * u);
  p.ret(Rect.fromLTRB(maquina.left, maquina.top, maquina.right, maquina.top + 2 * u), const Color(0xFFB8C0CA), contorno: .6,
      raio: .6 * u);
  p.ret(Rect.fromLTRB(xc - 2.4 * u, bancada - 5.6 * u, xc + 2.4 * u, bancada - .4 * u), const Color(0xFF17191D), contorno: .4);
  p.ret(Rect.fromLTRB(xc - 1.8 * u, bancada - 7 * u, xc + 1.8 * u, bancada - 5.6 * u), const Color(0xFF8D99A8), contorno: .4);
  p.ret(Rect.fromLTRB(xc - 1 * u, bancada - 2.6 * u, xc + 1 * u, bancada - .4 * u), _branco, contorno: .4, raio: .2 * u);
  final pisca = (p.t * .8) % 2 < 1.4;
  p.circ(Offset(xc + 2.4 * u, maquina.top + 3.4 * u), .45 * u, pisca ? const Color(0xFF4CD964) : const Color(0xFF2E7D32),
      contorno: .2, emite: true);
  p.circ(Offset(xc + .9 * u, maquina.top + 3.4 * u), .45 * u, const Color(0xFFE53935), contorno: .2);
  // pia com a torneira
  final xp = l + fw + (r - l - fw) * .55;
  p.tubos([
    Path()
      ..moveTo(xp, bancada)
      ..lineTo(xp, bancada - 4 * u)
      ..quadraticBezierTo(xp, bancada - 5.2 * u, xp + 1.4 * u, bancada - 5.2 * u)
      ..lineTo(xp + 2.6 * u, bancada - 4.4 * u),
  ], .45 * u, const Color(0xFFB8C0CA), contorno: .4);
  // micro-ondas com o relógio
  final mw = math.min(10 * u, (r - l - fw) * .3);
  final micro = Rect.fromLTRB(r - mw - .8 * u, bancada - 6 * u, r - .8 * u, bancada);
  p.ret(micro, const Color(0xFFDCE3E6), contorno: .8, raio: .4 * u);
  p.ret(Rect.fromLTRB(micro.left + .7 * u, micro.top + .8 * u, micro.right - mw * .32, micro.bottom - .8 * u),
      const Color(0xFF3A4152), contorno: .5, raio: .3 * u);
  final visor = Rect.fromLTRB(micro.right - mw * .28, micro.top + .9 * u, micro.right - .6 * u, micro.top + 2.4 * u);
  p.ret(visor, const Color(0xFF17202E), contorno: .3, emite: true);
  final (hh, mm) = _horaDoRelogio(p.hora);
  final hora = '$hh:${mm.toString().padLeft(2, '0')}';
  final alt = math.min(1 * u, (visor.width - .4 * u) / (_larguraDosDigitos(hora, 1) + .01));
  if (alt > 0) _digitos(p, hora, Offset(visor.left + .2 * u, visor.center.dy - alt / 2), alt, const Color(0xFF7CF2D0));
  // bancada e armários de baixo
  p.ret(Rect.fromLTRB(l + fw, bancada, r + .6 * u, bancada + 1.2 * u), const Color(0xFF4A4F57), contorno: .7);
  final baixo = Rect.fromLTRB(l + fw + .4 * u, bancada + 1.2 * u, r, p.hz);
  p.ret(baixo, const Color(0xFFB98A5A), contorno: .7);
  final nb = math.max(1, (baixo.width / (6 * u)).round());
  for (var i = 0; i < nb; i++) {
    final a = baixo.left + baixo.width * i / nb, b = baixo.left + baixo.width * (i + 1) / nb;
    if (i > 0) p.c.drawLine(Offset(a, baixo.top), Offset(a, baixo.bottom), p.traco(.4));
    p.ret(Rect.fromLTRB((a + b) / 2 - 1.2 * u, baixo.top + 1.2 * u, (a + b) / 2 + 1.2 * u, baixo.top + 1.8 * u),
        const Color(0xFF59636E), contorno: .2, raio: .2 * u);
  }
  // geladeira de inox (com a garrafinha de água na porta e um ímã)
  final gel = Rect.fromLTRB(l, 11 * u, l + fw, p.hz);
  p.ret(gel, const Color(0xFFCDD5DD), contorno: 1, raio: .8 * u);
  p.sombra(Path()..addRRect(RRect.fromRectAndRadius(gel, Radius.circular(.8 * u))),
      Rect.fromLTRB(gel.right - fw * .25, gel.top, gel.right, gel.bottom), alfa: .14);
  final corte = gel.top + gel.height * .38;
  p.c.drawLine(Offset(gel.left, corte), Offset(gel.right, corte), p.traco(.5));
  p.tubos([
    Path()
      ..moveTo(gel.left + 1.2 * u, corte - 5 * u)
      ..lineTo(gel.left + 1.2 * u, corte - 1.4 * u),
    Path()
      ..moveTo(gel.left + 1.2 * u, corte + 1.4 * u)
      ..lineTo(gel.left + 1.2 * u, corte + 8 * u),
  ], .5 * u, const Color(0xFF8D99A8), contorno: .4);
  final bilhete = Rect.fromLTWH(gel.left + fw * .35, corte + 2.2 * u, fw * .44, fw * .5);
  p.ret(bilhete, const Color(0xFFFFE066), contorno: .3);
  for (var i = 0; i < 2; i++) {
    final y = bilhete.top + bilhete.height * (.35 + i * .3);
    p.c.drawLine(Offset(bilhete.left + bilhete.width * .15, y), Offset(bilhete.right - bilhete.width * .2, y),
        Paint()
          ..color = const Color(0x553A2A33)
          ..strokeWidth = math.max(.6, .15 * u));
  }
  p.circ(Offset(bilhete.center.dx, bilhete.top), .45 * u, const Color(0xFFE53935), contorno: .2);
}

/// O mural de cortiça com os avisos (papéis presos com tachinhas).
void _muralDeAvisos(_Pincel p, double x, double meia) {
  final u = p.u;
  final r = Rect.fromLTRB(x - meia, 18 * u, x + meia, 31 * u);
  p.ret(r.inflate(.8 * u), const Color(0xFF9A6B44), contorno: .7, raio: .3 * u);
  p.ret(r, const Color(0xFFD2A26C), contorno: .3);
  const papeis = [Color(0xFFFFFFFF), Color(0xFFFFE066), Color(0xFF8FD3FF), Color(0xFFFF9EC7), Color(0xFFB5E58C)];
  final n = (r.width / (3.2 * u)).floor().clamp(2, 5);
  for (var i = 0; i < n; i++) {
    final w = math.min(3.4 + 1.6 * _ruido(i + 401), r.width / u / n * 1.25) * u, h = (3.6 + 2 * _ruido(i + 411)) * u;
    final cx = r.left + r.width * (i + .5) / n, cy = r.top + r.height * (i.isEven ? .36 : .62);
    final papel = Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
    p.c.save();
    p.c.translate(cx, cy);
    p.c.rotate((_ruido(i + 421) - .5) * .25);
    p.c.translate(-cx, -cy);
    p.ret(papel, papeis[i], contorno: .3);
    for (var k = 0; k < 2; k++) {
      final y = papel.top + papel.height * (.4 + k * .25);
      p.c.drawLine(Offset(papel.left + .5 * u, y), Offset(papel.right - .6 * u, y),
          Paint()
            ..color = const Color(0x553A2A33)
            ..strokeWidth = math.max(.6, .14 * u));
    }
    p.c.restore();
    p.circ(Offset(cx, papel.top + .4 * u), .4 * u, _publico[i % 6], contorno: .2);
  }
}

/// O bebedouro de garrafão (a água azul no garrafão de cima, as torneiras e os copinhos).
void _bebedouro(_Pincel p, double x, double base) {
  final u = p.u;
  final corpo = Rect.fromLTRB(x - 2.6 * u, base - 13 * u, x + 2.6 * u, base);
  p.ret(corpo, const Color(0xFFE9EDF0), contorno: .8, raio: .5 * u);
  p.ret(Rect.fromLTRB(x - 1.8 * u, base - 9.6 * u, x + 1.8 * u, base - 7 * u), const Color(0xFFB8C0CA), contorno: .4, raio: .3 * u);
  p.circ(Offset(x - .8 * u, base - 10.2 * u), .45 * u, const Color(0xFF3E8AE0), contorno: .25);
  p.circ(Offset(x + .8 * u, base - 10.2 * u), .45 * u, const Color(0xFFE53935), contorno: .25);
  final garrafao = Path()
    ..addRRect(RRect.fromLTRBR(x - 2.4 * u, base - 21 * u, x + 2.4 * u, base - 14 * u, Radius.circular(1.6 * u)))
    ..addRect(Rect.fromLTRB(x - .9 * u, base - 14.2 * u, x + .9 * u, base - 13 * u));
  p.forma(garrafao, const Color(0xFF9FD8F0), contorno: .6, alfa: .9);
  p.c.drawRect(Rect.fromLTRB(x - 1.7 * u, base - 19.6 * u, x - 1.1 * u, base - 15 * u), Paint()..color = const Color(0x66FFFFFF));
  // copinhos ao lado
  p.ret(Rect.fromLTRB(x + 2.6 * u, base - 12 * u, x + 3.8 * u, base - 8 * u), _branco, contorno: .4);
}

/// A parede de vidro da sala de reunião ao lado: a faixa jateada, a porta, a mesa e o telão lá dentro.
void _salaDeVidro(_Pincel p, double x) {
  final u = p.u;
  final r = Rect.fromLTRB(x - 15 * u, 11 * u, x + 15 * u, p.hz);
  p.c.drawRect(r, p.tinta(const Color(0xFFC9D8DE)));
  // lá dentro: o telão aceso, a mesa comprida e as cadeiras
  final tela = Rect.fromLTRB(x - 7 * u, 17 * u, x + 5 * u, 26 * u);
  p.ret(tela, const Color(0xFF2B2F3A), contorno: .5, raio: .3 * u);
  p.ret(tela.deflate(.5 * u), const Color(0xFF2F6FD0), contorno: 0, emite: true, alfa: .9);
  for (var i = 0; i < 3; i++) {
    p.c.drawRect(Rect.fromLTWH(tela.left + (1.4 + i * 2.6) * u, tela.bottom - (2 + i * 1.6) * u, 1.8 * u, (1.4 + i * 1.6) * u),
        Paint()..color = const Color(0xCCFFD166));
  }
  final mesa = p.hz - 9 * u;
  for (var i = 0; i < 4; i++) {
    final cx = x - 9 * u + i * 6 * u;
    p.ret(Rect.fromLTRB(cx - 1.8 * u, mesa - 4.6 * u, cx + 1.8 * u, mesa), const Color(0xFF37404F), contorno: .4, raio: .8 * u);
  }
  p.ret(Rect.fromLTRB(x - 12 * u, mesa, x + 12 * u, mesa + 1.2 * u), const Color(0xFFF4F6F7), contorno: .5);
  p.ret(Rect.fromLTRB(x - 1 * u, mesa + 1.2 * u, x + 1 * u, p.hz), const Color(0xFF8D99A8), contorno: .4);
  // o vidro: reflexos, a faixa jateada e os montantes
  p.c.save();
  p.c.clipRect(r);
  for (final f in [.15, .62]) {
    p.c.drawPath(
        Path()
          ..moveTo(r.left + r.width * f, r.top)
          ..lineTo(r.left + r.width * (f + .12), r.top)
          ..lineTo(r.left + r.width * (f - .06), r.bottom)
          ..lineTo(r.left + r.width * (f - .18), r.bottom)
          ..close(),
        Paint()..color = const Color(0x30FFFFFF));
  }
  p.c.restore();
  p.c.drawRect(Rect.fromLTRB(r.left, 33 * u, r.right, 37 * u), Paint()..color = const Color(0xA6F4F8FA));
  p.c.drawRect(r, p.traco(.9));
  for (final f in [1 / 3, 2 / 3]) {
    p.tubos([
      Path()
        ..moveTo(r.left + r.width * f, r.top)
        ..lineTo(r.left + r.width * f, r.bottom)
    ], .5 * u, const Color(0xFF8D99A8), contorno: .3);
  }
  // o puxador da porta (o terço da direita)
  p.tubos([
    Path()
      ..moveTo(r.left + r.width * 2 / 3 + 1.6 * u, r.top + r.height * .45)
      ..lineTo(r.left + r.width * 2 / 3 + 1.6 * u, r.top + r.height * .7)
  ], .5 * u, const Color(0xFFB8C0CA), contorno: .35);
}

void _dCopa(_Pincel p) {
  final u = p.u;
  final s = _plantaDaCopa(p);
  final fundoFora = p.hz - 14 * u;
  _vistaDaCopa(p, fundoFora);
  p.faixa(fundoFora, p.hz, const Color(0xFF9AA3AE), contorno: .4, baixo: false);
  final janelas = <RRect>[];
  p.laco(s.xj, s.jMeia + u,
      (x) => janelas.add(RRect.fromLTRBR(x - s.jMeia, 9 * u, x + s.jMeia, p.hz - 15 * u, Radius.circular(.6 * u))));
  _parede(p, const Color(0xFFD9E7E3), janelas);
  for (final j in janelas) {
    final r = j.outerRect;
    _moldura(p, j, const Color(0xFF4F5B66), cruz: false);
    final nv = math.max(1, (r.width / (14 * u)).round());
    p.tubos([
      for (var i = 1; i < nv; i++)
        Path()
          ..moveTo(r.left + r.width * i / nv, r.top)
          ..lineTo(r.left + r.width * i / nv, r.bottom),
    ], .7 * u, const Color(0xFF4F5B66), contorno: .4);
    p.ret(Rect.fromLTRB(r.left - 1.2 * u, r.bottom + .6 * u, r.right + 1.2 * u, r.bottom + 1.8 * u), const Color(0xFFF3F5F7),
        contorno: .6);
    // vaso de ervas no peitoril
    p.laco(r.left + 4 * u, 2 * u, (x) => _planta(p, x, r.bottom + .6 * u, 4.6 * u, vaso: const Color(0xFFF4F1EA), semente: 11));
  }
  // teto e as duas luminárias pendentes sobre a mesa alta
  p.faixa(-2, 2.6 * u, const Color(0xFFF5F6F8), contorno: .5);
  for (final dx in [-.45, .45]) {
    p.laco(s.xj + dx * math.min(s.jMeia, 9 * u), 4 * u,
        (x) => _pendente(p, x, math.max(10 * u, p.hz - 36 * u), const Color(0xFF2E3238), largura: 2.6));
  }
  p.laco(s.kl + s.kw / 2, s.kw / 2 + u, (c) => _balcaoDaCopa(p, c - s.kw / 2, s.kw));
  final v = s.vidro;
  if (v != null) p.laco(v, 16 * u, (x) => _salaDeVidro(p, x));
  final m = s.mural;
  if (m != null) {
    p.laco(m, 9 * u, (x) {
      _muralDeAvisos(p, x, math.min(8 * u, (m - s.kl - s.kw - 3 * u) - 1 * u));
      _relogioDeParede(p, Offset(x, 11.5 * u), 2.6 * u);
    });
  } else if (s.galao == null) {
    // tela estreita: o relógio fica em cima da janela
    p.laco(s.xj, 3 * u, (x) => _relogioDeParede(p, Offset(x, 5.6 * u), 2.2 * u));
  }
  final g = s.galao;
  if (g != null) p.laco(g, 4 * u, (x) => _bebedouro(p, x, p.hz));
  p.faixa(p.hz - 1 * u, p.hz, const Color(0xFF6F7C8A), contorno: .5);
}

/// A mesa alta redonda da copa, com duas banquetas.
void _mesaAlta(_Pincel p, double x, double base) {
  final u = p.u;
  for (final dx in [-7.5, 7.5]) {
    _banqueta(p, x + dx * u, base + 1.4 * u);
  }
  p.tubos([
    Path()
      ..moveTo(x, base - 12 * u)
      ..lineTo(x, base - .6 * u)
  ], .7 * u, const Color(0xFF3A4152), contorno: .5);
  p.ret(Rect.fromLTRB(x - 3.4 * u, base - .9 * u, x + 3.4 * u, base), const Color(0xFF3A4152), contorno: .5, raio: .4 * u);
  p.ret(Rect.fromLTRB(x - 6.6 * u, base - 13.2 * u, x + 6.6 * u, base - 12 * u), const Color(0xFFF4F6F7), contorno: .8,
      raio: .6 * u);
  // duas canecas e um pratinho de biscoitos
  for (final (dx, cor) in [(-4.0, const Color(0xFFE5533D)), (3.2, const Color(0xFF3E8AE0))]) {
    p.c.drawArc(Rect.fromLTWH(x + (dx + 1.6) * u, base - 15.4 * u, 1.2 * u, 1.2 * u), -math.pi / 2, math.pi, false, p.traco(.35));
    p.ret(Rect.fromLTWH(x + dx * u, base - 15.6 * u, 1.9 * u, 2.4 * u), cor, contorno: .45, raio: .35 * u);
  }
  p.c.drawOval(Rect.fromCenter(center: Offset(x - .4 * u, base - 13.4 * u), width: 3.6 * u, height: .8 * u), p.tinta(_branco));
  p.c.drawOval(Rect.fromCenter(center: Offset(x - .4 * u, base - 13.4 * u), width: 3.6 * u, height: .8 * u), p.traco(.3));
  for (final dx in [-1.2, .2]) {
    p.circ(Offset(x + dx * u, base - 14.2 * u), .7 * u, const Color(0xFFC88A4A), contorno: .3);
  }
}

/// Lixeiras de reciclagem (azul e verde) no canto do balcão.
void _lixeiras(_Pincel p, double x, double base) {
  final u = p.u;
  for (final (dx, cor) in [(-1.6, const Color(0xFF3E8AE0)), (1.6, const Color(0xFF2EAD5B))]) {
    final r = Rect.fromLTRB(x + (dx - 1.5) * u, base - 6 * u, x + (dx + 1.5) * u, base);
    p.ret(r, cor, contorno: .6, raio: .3 * u);
    p.ret(Rect.fromLTRB(r.left - .3 * u, r.top - .8 * u, r.right + .3 * u, r.top + .2 * u), Color.lerp(cor, _branco, .25)!,
        contorno: .5, raio: .3 * u);
  }
}

void _cCopa(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFFB9C2C9), Color(0xFF98A3AE)]);
  // piso de placas quadradas
  final junta = Paint()
    ..strokeWidth = math.max(1.0, .2 * u)
    ..color = const Color(0x2A3A2A33);
  for (final f in [3.5, 8.5, 15.0, 23.5, 34.0]) {
    p.c.drawLine(Offset(-2, p.hz + f * u), Offset(p.w + 2, p.hz + f * u), junta);
  }
  final k = p.vezes(10 * u);
  for (var i = 0; i < k; i++) {
    final x = i * p.w / k;
    p.c.drawLine(Offset(x, p.hz), Offset(x + (x - p.w / 2) * .25, p.h), junta);
  }
  final s = _plantaDaCopa(p);
  p.laco(s.xj, 16 * u, (x) => _mesaAlta(p, x, p.hz + 8 * u));
  if (s.vidro != null || s.mural != null) {
    p.laco(s.kl + s.kw + 4 * u, 4 * u, (x) => _lixeiras(p, x, p.hz + 6 * u));
  }
}

// ─────────────────────────── recepção do hotel (o balcão do check-in, o elevador e a porta da rua) ───────────────────────────

/// A planta da recepção: o balcão no meio (com o escaninho das chaves atrás), o elevador à direita; na tela
/// larga, a porta de vidro da rua à esquerda e o resto da parede com quadros e plantas.
typedef _PlantaRecepcao = ({
  double xb, // meio do balcão
  double bMeia,
  double? xe, // o elevador
  double? xp, // a porta de vidro da rua
  List<(double, double)> vaos, // o que sobra de parede (quadros, arandelas)
});

_PlantaRecepcao _plantaDaRecepcao(_Pincel p) {
  final u = p.u, w = p.w;
  const eMeia = 6.0;
  if (w < 70 * u) {
    final bMeia = math.min(19 * u, w * .34);
    final xb = math.max(bMeia + 1.5 * u, w * .4);
    final xe = w - (eMeia + 1) * u;
    final temElevador = xe - eMeia * u > xb + bMeia - 6 * u;
    return (xb: xb, bMeia: bMeia, xe: temElevador ? xe : null, xp: null, vaos: const []);
  }
  final bMeia = math.min(24 * u, w * .2);
  final xb = w * .5;
  final xe = xb + bMeia + 15 * u;
  final xp = xb - bMeia - 19 * u;
  final ocupadas = <(double, double)>[(xb, bMeia + 2 * u)];
  final comElevador = xe + (eMeia + 2) * u < w;
  if (comElevador) ocupadas.add((xe, (eMeia + 2) * u));
  final comPorta = xp - 12 * u > 0;
  if (comPorta) ocupadas.add((xp, 12 * u));
  return (
    xb: xb,
    bMeia: bMeia,
    xe: comElevador ? xe : null,
    xp: comPorta ? xp : null,
    vaos: _vaosDaParede(p, ocupadas, minimo: 7 * u),
  );
}

/// A rua lá fora, pela porta de vidro: o prédio da frente e a calçada.
void _ruaDaRecepcao(_Pincel p, double x) {
  final u = p.u;
  _predio(p, Rect.fromLTRB(x - 12 * u, 30 * u, x + 2 * u, p.hz - 6 * u), const Color(0xFFB98A7A), semente: 7);
  _predio(p, Rect.fromLTRB(x + 2 * u, 36 * u, x + 12 * u, p.hz - 6 * u), const Color(0xFF8FA3B8), semente: 8);
  p.ret(Rect.fromLTRB(x - 14 * u, p.hz - 6 * u, x + 14 * u, p.hz), const Color(0xFFB9B9B4), contorno: .4);
  _poste(p, x - 6 * u, p.hz - 3 * u, 22 * u, aceso: p.acesas);
}

/// O escaninho das chaves atrás do balcão: a grade de nichos com chaves e envelopes, e a placa das estrelas.
void _escaninho(_Pincel p, double x, double meia) {
  final u = p.u;
  final r = Rect.fromLTRB(x - meia, 21 * u, x + meia, 36 * u);
  p.ret(r.inflate(.8 * u), const Color(0xFF6B4A32), contorno: .8, raio: .3 * u);
  p.c.drawRect(r, p.tinta(const Color(0xFF4E3424)));
  final cols = math.max(3, (r.width / (3.2 * u)).floor()), lins = 4;
  final cw = r.width / cols, ch = r.height / lins;
  final grade = Paint()
    ..color = p.luz(const Color(0xFF8A6446))
    ..strokeWidth = math.max(1.0, .45 * u);
  for (var i = 1; i < cols; i++) {
    p.c.drawLine(Offset(r.left + i * cw, r.top), Offset(r.left + i * cw, r.bottom), grade);
  }
  for (var j = 1; j < lins; j++) {
    p.c.drawLine(Offset(r.left, r.top + j * ch), Offset(r.right, r.top + j * ch), grade);
  }
  for (var i = 0; i < cols; i++) {
    for (var j = 0; j < lins; j++) {
      final o = Offset(r.left + (i + .5) * cw, r.top + (j + .5) * ch);
      final q = _ruido(i * 13 + j * 7 + 501);
      if (q > .62) {
        // envelope
        p.c.drawRect(Rect.fromCenter(center: o + Offset(0, ch * .12), width: cw * .6, height: ch * .38), p.tinta(_branco));
      } else if (q > .2) {
        // a chave com o chaveiro dourado pendurada
        p.c.drawLine(o - Offset(0, ch * .3), o, p.traco(.25));
        p.c.drawCircle(o + Offset(0, ch * .12), math.min(cw, ch) * .16, p.tinta(const Color(0xFFE9B949)));
      }
    }
  }
  // a placa com as estrelas do hotel (sem nome)
  final placa = Rect.fromCenter(center: Offset(x, 15.5 * u), width: math.min(meia * 1.4, 22 * u), height: 6 * u);
  p.ret(placa, const Color(0xFF2B2F3A), contorno: .7, raio: .5 * u);
  final n = 4;
  for (var i = 0; i < n; i++) {
    final c = Offset(placa.left + placa.width * (i + .5) / n, placa.center.dy);
    final e = Path();
    for (var k = 0; k < 10; k++) {
      final rr = k.isEven ? 1.6 * u : .7 * u;
      final a = -math.pi / 2 + k * math.pi / 5;
      final pt = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      k == 0 ? e.moveTo(pt.dx, pt.dy) : e.lineTo(pt.dx, pt.dy);
    }
    p.c.drawPath(e..close(), p.tinta(const Color(0xFFFFC83D), emite: p.acesas));
  }
}

/// A porta do elevador: as duas folhas de inox, o mostrador do andar e o botão de chamar.
void _elevador(_Pincel p, double x) {
  final u = p.u;
  final batente = Rect.fromLTRB(x - 6 * u, 16 * u, x + 6 * u, p.hz);
  p.ret(batente, const Color(0xFF6B4A32), contorno: .8);
  final porta = Rect.fromLTRB(x - 4.8 * u, 18.5 * u, x + 4.8 * u, p.hz);
  p.ret(porta, const Color(0xFFC9D1D9), contorno: .7);
  p.c.drawLine(Offset(x, porta.top), Offset(x, porta.bottom), p.traco(.5));
  for (final dx in [-2.4, 2.4]) {
    p.c.drawLine(Offset(x + dx * u, porta.top + 2 * u), Offset(x + dx * u - 1 * u, porta.bottom - 2 * u),
        Paint()
          ..color = const Color(0x40FFFFFF)
          ..strokeWidth = .6 * u);
  }
  final visor = Rect.fromCenter(center: Offset(x, 13.6 * u), width: 5 * u, height: 3 * u);
  p.ret(visor, const Color(0xFF17202E), contorno: .5, raio: .3 * u, emite: true);
  final andar = '${1 + (p.t / 3).floor() % 5}';
  _digitos(p, andar, Offset(visor.center.dx - .6 * u, visor.top + .6 * u), 1.8 * u, const Color(0xFFFF9E40));
  p.ret(Rect.fromLTRB(x - 8.6 * u, 34 * u, x - 7 * u, 37.6 * u), const Color(0xFFC9D1D9), contorno: .5, raio: .3 * u);
  p.circ(Offset(x - 7.8 * u, 35.8 * u), .5 * u, p.acesas ? const Color(0xFFFFD866) : const Color(0xFFF4F6F7), contorno: .25);
}

/// A arandela dourada de parede (acesa à tarde e à noite).
void _arandela(_Pincel p, double x, double y) {
  final u = p.u;
  if (p.acesas) _luzQuente(p, Offset(x, y), 12 * u, forca: .9);
  p.ret(Rect.fromLTRB(x - .5 * u, y, x + .5 * u, y + 3 * u), const Color(0xFFD9A441), contorno: .4);
  p.forma(
      Path()
        ..moveTo(x - 1.6 * u, y - 2.6 * u)
        ..lineTo(x + 1.6 * u, y - 2.6 * u)
        ..lineTo(x + 1 * u, y)
        ..lineTo(x - 1 * u, y)
        ..close(),
      p.acesas ? const Color(0xFFFFE6A8) : const Color(0xFFF4ECD8),
      contorno: .5,
      emite: p.acesas);
}

void _dRecepcaoHotel(_Pincel p) {
  final u = p.u;
  final s = _plantaDaRecepcao(p);
  final portas = <RRect>[];
  final xp = s.xp;
  if (xp != null) {
    p.laco(xp, 12 * u, (x) => _ruaDaRecepcao(p, x));
    p.laco(xp, 11 * u, (x) => portas.add(RRect.fromLTRBR(x - 10 * u, 13 * u, x + 10 * u, p.hz, Radius.circular(.4 * u))));
  }
  _parede(p, const Color(0xFFF1E4CC), portas);
  // lambri de madeira na metade de baixo, com os painéis
  final lambri = 40 * u;
  final vaos = Path();
  for (final j in portas) {
    vaos.addRRect(j);
  }
  Path semPorta(Rect r) => Path.combine(PathOperation.difference, Path()..addRect(r), vaos);
  p.c.drawPath(semPorta(Rect.fromLTRB(-2, lambri, p.w + 2, p.hz)), p.tinta(const Color(0xFFB98A5A)));
  p.c.save();
  p.c.clipPath(semPorta(Rect.fromLTRB(-2, lambri - 2 * u, p.w + 2, p.hz + 1)));
  p.faixa(lambri - 1.2 * u, lambri, const Color(0xFF8A5F3C), contorno: .5);
  final paineis = p.vezes(9 * u);
  for (var i = 0; i < paineis; i++) {
    final x = i * p.w / paineis;
    p.ret(Rect.fromLTRB(x + 1.2 * u, lambri + 2 * u, x + p.w / paineis - 1.2 * u, p.hz - 2.6 * u), const Color(0xFFC89B6C),
        contorno: .35, raio: .3 * u);
  }
  p.c.restore();
  // sanca do teto e o lustre
  p.faixa(-2, 3 * u, const Color(0xFFFAF3E6), contorno: .5);
  p.faixa(3 * u, 4 * u, const Color(0xFFD9A441), contorno: .4);
  p.laco(s.xb, 8 * u, (x) {
    p.c.drawLine(Offset(x, 4 * u), Offset(x, 8 * u), p.traco(.4));
    _luzQuente(p, Offset(x, 10 * u), 20 * u, forca: 1.1);
    p.ret(Rect.fromLTRB(x - 5 * u, 8 * u, x + 5 * u, 9 * u), const Color(0xFFD9A441), contorno: .5, raio: .4 * u);
    for (var i = 0; i < 5; i++) {
      final cx = x - 4 * u + i * 2 * u;
      p.forma(
          Path()
            ..moveTo(cx - .7 * u, 9 * u)
            ..lineTo(cx + .7 * u, 9 * u)
            ..lineTo(cx, 11.6 * u)
            ..close(),
          p.acesas ? const Color(0xFFFFF0C2) : const Color(0xFFE6F4FF),
          contorno: .3,
          emite: p.acesas);
    }
  });
  for (final j in portas) {
    final r = j.outerRect;
    p.c.save();
    p.c.clipRRect(j);
    p.c.drawRect(r, Paint()..color = const Color(0x269FD8F0));
    p.c.restore();
    _moldura(p, j, const Color(0xFF3A3F4B), cruz: false);
    p.c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), p.traco(.6));
    for (final dx in [-1.4, 1.4]) {
      p.tubos([
        Path()
          ..moveTo(r.center.dx + dx * u, r.top + r.height * .45)
          ..lineTo(r.center.dx + dx * u, r.top + r.height * .7)
      ], .5 * u, const Color(0xFFD9A441), contorno: .35);
    }
    // o toldo da entrada, por cima
    p.ret(Rect.fromLTRB(r.left - 2 * u, r.top - 3 * u, r.right + 2 * u, r.top - .6 * u), const Color(0xFF7A1F2B), contorno: .7,
        raio: .4 * u);
  }
  p.laco(s.xb, s.bMeia + u, (x) => _escaninho(p, x, s.bMeia * .78));
  p.laco(s.xb + s.bMeia * .78 + 5 * u, 3 * u, (x) => _relogioDeParede(p, Offset(x, 16 * u), 2.6 * u));
  final xe = s.xe;
  if (xe != null) p.laco(xe, 9 * u, (x) => _elevador(p, x));
  var k = 0;
  for (final (x0, meia) in s.vaos) {
    if (meia >= 11 * u) {
      final w = math.min(meia * 1.2, 16 * u);
      p.laco(x0, w / 2 + 2 * u, (x) {
        _quadroDePaisagem(p, Rect.fromCenter(center: Offset(x, 25 * u), width: w, height: w * .7), k);
        for (final d in [-1.0, 1.0]) {
          if (meia >= w / 2 + 6 * u) _arandela(p, x + d * (w / 2 + 3.4 * u), 24 * u);
        }
      });
    } else {
      p.laco(x0, 3 * u, (x) => _arandela(p, x, 25 * u));
    }
    k++;
  }
  p.faixa(p.hz - 1.2 * u, p.hz, const Color(0xFF6B4A32), contorno: .5);
}

/// O balcão da recepção: tampo de mármore, frente de madeira com frisos, o monitor (de costas), o sino,
/// o porta-folhetos e uma orquídea.
void _balcaoDaRecepcao(_Pincel p, double x, double base, double meia) {
  final u = p.u;
  final topo = base - 11 * u;
  // em cima: o monitor de costas, a orquídea, os folhetos e o sino
  final mx = x - meia * .45;
  p.ret(Rect.fromLTRB(mx - .6 * u, topo - 3 * u, mx + .6 * u, topo), const Color(0xFF3A3F4B), contorno: .4);
  p.ret(Rect.fromLTRB(mx - 5 * u, topo - 9.6 * u, mx + 5 * u, topo - 2.8 * u), const Color(0xFF3A3F4B), contorno: .7, raio: .5 * u);
  if (p.acesas) p.brilho(Offset(mx, topo - 6 * u), 6 * u, const Color(0xFF7FB6FF), alfa: .18);
  final ox = x + meia * .62;
  p.ret(Rect.fromLTRB(ox - 1.2 * u, topo - 2.4 * u, ox + 1.2 * u, topo), _branco, contorno: .45, raio: .4 * u);
  p.c.drawPath(
      Path()
        ..moveTo(ox, topo - 2.4 * u)
        ..quadraticBezierTo(ox + .4 * u, topo - 7 * u, ox + 2.2 * u, topo - 8 * u),
      p.traco(.35));
  for (final (dx, dy) in [(1.0, 6.4), (2.2, 7.8), (2.6, 5.8)]) {
    p.circ(Offset(ox + dx * u, topo - dy * u), .75 * u, const Color(0xFFF2A3D0), contorno: .25);
  }
  final fx = x + meia * .2;
  p.ret(Rect.fromLTRB(fx - 2 * u, topo - 3.6 * u, fx + 2 * u, topo), const Color(0xFFDCE3E6), contorno: .45);
  for (var i = 0; i < 3; i++) {
    p.ret(Rect.fromLTRB(fx - 1.7 * u + i * 1.2 * u, topo - 4.6 * u + i * .3 * u, fx - .7 * u + i * 1.2 * u, topo - 1.4 * u),
        _publico[i * 2 % 6], contorno: .25);
  }
  // o sino
  final sx = x - meia * .05;
  p.forma(
      Path()
        ..moveTo(sx - 1.6 * u, topo - .4 * u)
        ..quadraticBezierTo(sx - 1.6 * u, topo - 2.6 * u, sx, topo - 2.6 * u)
        ..quadraticBezierTo(sx + 1.6 * u, topo - 2.6 * u, sx + 1.6 * u, topo - .4 * u)
        ..close(),
      const Color(0xFFE9B949),
      contorno: .5);
  p.circ(Offset(sx, topo - 2.9 * u), .35 * u, const Color(0xFFE9B949), contorno: .25);
  p.ret(Rect.fromLTRB(sx - 2 * u, topo - .5 * u, sx + 2 * u, topo), const Color(0xFF3A3F4B), contorno: .3);
  // o tampo e a frente
  p.ret(Rect.fromLTRB(x - meia - .8 * u, topo, x + meia + .8 * u, topo + 1.6 * u), const Color(0xFFF2EEE6), contorno: .8,
      raio: .3 * u);
  final frente = Rect.fromLTRB(x - meia, topo + 1.6 * u, x + meia, base);
  p.ret(frente, const Color(0xFF7A4E30), contorno: 1);
  final n = math.max(2, (frente.width / (8 * u)).round());
  for (var i = 0; i < n; i++) {
    final a = frente.left + frente.width * i / n, b = frente.left + frente.width * (i + 1) / n;
    p.ret(Rect.fromLTRB(a + .9 * u, frente.top + 1.4 * u, b - .9 * u, frente.bottom - 1.4 * u), const Color(0xFF8E5D3A),
        contorno: .35, raio: .3 * u);
  }
  p.ret(Rect.fromLTRB(frente.left, frente.top + .2 * u, frente.right, frente.top + 1 * u), const Color(0xFFD9A441), contorno: .25);
  p.sombra(Path()..addRect(frente), Rect.fromLTRB(frente.left, frente.bottom - 1.6 * u, frente.right, frente.bottom));
}

/// O carrinho de bagagem dourado com duas malas.
void _carrinhoDeBagagem(_Pincel p, double x, double base) {
  final u = p.u;
  const ouro = Color(0xFFE0B341);
  p.tubos([
    for (final dx in [-4.4, 4.4])
      Path()
        ..moveTo(x + dx * u, base - 1.6 * u)
        ..lineTo(x + dx * u, base - 17 * u),
    Path()
      ..moveTo(x - 4.4 * u, base - 17 * u)
      ..quadraticBezierTo(x, base - 21 * u, x + 4.4 * u, base - 17 * u),
  ], .55 * u, ouro, contorno: .4);
  p.ret(Rect.fromLTRB(x - 5.6 * u, base - 2.4 * u, x + 5.6 * u, base - 1.4 * u), const Color(0xFF8A2432), contorno: .5);
  p.ret(Rect.fromLTRB(x - 3.8 * u, base - 9.4 * u, x + 1.6 * u, base - 2.4 * u), const Color(0xFF3E8AE0), contorno: .6, raio: .6 * u);
  p.ret(Rect.fromLTRB(x - 1 * u, base - 13.4 * u, x + 3.6 * u, base - 9.4 * u), const Color(0xFFE5533D), contorno: .6, raio: .6 * u);
  p.c.drawLine(Offset(x - 2 * u, base - 9.4 * u), Offset(x - 2 * u, base - 10.6 * u), p.traco(.4));
  for (final dx in [-4.6, 4.6]) {
    p.circ(Offset(x + dx * u, base - .7 * u), .8 * u, const Color(0xFF2B2B2B), contorno: .3);
  }
}

/// Poltrona de veludo com a mesinha e o abajur.
void _poltrona(_Pincel p, double x, double base) {
  final u = p.u;
  const cor = Color(0xFF7A1F2B);
  p.ret(Rect.fromLTRB(x - 5 * u, base - 13 * u, x + 5 * u, base - 4 * u), cor, contorno: .9, raio: 2 * u);
  p.ret(Rect.fromLTRB(x - 4.4 * u, base - 6 * u, x + 4.4 * u, base - 2.4 * u), const Color(0xFF962A38), contorno: .8, raio: 1 * u);
  for (final dx in [-5.6, 5.6]) {
    p.ret(Rect.fromLTRB(x + dx * u - 1.4 * u, base - 8 * u, x + dx * u + 1.4 * u, base - 2 * u), cor, contorno: .8, raio: 1 * u);
    p.ret(Rect.fromLTRB(x + dx * u - .4 * u, base - 2 * u, x + dx * u + .4 * u, base), const Color(0xFF5A3D2B), contorno: .3);
  }
  final mx = x + 10 * u;
  p.ret(Rect.fromLTRB(mx - 2.4 * u, base - 7 * u, mx + 2.4 * u, base - 6 * u), const Color(0xFF6B4A32), contorno: .5);
  p.ret(Rect.fromLTRB(mx - .4 * u, base - 6 * u, mx + .4 * u, base), const Color(0xFF6B4A32), contorno: .4);
  p.ret(Rect.fromLTRB(mx - .3 * u, base - 11 * u, mx + .3 * u, base - 7 * u), const Color(0xFFD9A441), contorno: .3);
  if (p.acesas) _luzQuente(p, Offset(mx, base - 12 * u), 12 * u, forca: 1.1);
  p.forma(
      Path()
        ..moveTo(mx - 1.4 * u, base - 13.8 * u)
        ..lineTo(mx + 1.4 * u, base - 13.8 * u)
        ..lineTo(mx + 2.4 * u, base - 11 * u)
        ..lineTo(mx - 2.4 * u, base - 11 * u)
        ..close(),
      p.acesas ? const Color(0xFFFFE6A8) : const Color(0xFFF4ECD8),
      contorno: .5,
      emite: p.acesas);
}

void _cRecepcaoHotel(_Pincel p) {
  final u = p.u;
  // piso de mármore em xadrez na diagonal, com o tapete vermelho até o balcão
  p.solo(const [Color(0xFFEDE4D6), Color(0xFFD9CDBB)]);
  final s = _plantaDaRecepcao(p);
  final losango = Paint()..color = p.luz(const Color(0x1F6B4A32));
  final n = p.vezes(8 * u);
  final passo = p.w / n;
  for (var i = 0; i < n; i++) {
    for (var j = 0; j < 4; j++) {
      if ((i + j).isOdd) continue;
      final y0 = p.hz + j * 9 * u;
      final cx = (i + .5) * passo;
      p.c.drawPath(
          Path()
            ..moveTo(cx, y0)
            ..lineTo(cx + passo / 2, y0 + 4.5 * u)
            ..lineTo(cx, y0 + 9 * u)
            ..lineTo(cx - passo / 2, y0 + 4.5 * u)
            ..close(),
          losango);
    }
  }
  p.laco(s.xb, s.bMeia + 2 * u, (x) {
    p.forma(
        Path()
          ..moveTo(x - s.bMeia * .55, p.hz + 9 * u)
          ..lineTo(x + s.bMeia * .55, p.hz + 9 * u)
          ..lineTo(x + s.bMeia * .8, p.h + 2)
          ..lineTo(x - s.bMeia * .8, p.h + 2)
          ..close(),
        const Color(0xFFA8323F),
        contorno: .5);
    _balcaoDaRecepcao(p, x, p.hz + 9 * u, s.bMeia);
  });
  final xp = s.xp;
  if (xp != null) {
    p.laco(xp + 14 * u, 7 * u, (x) => _carrinhoDeBagagem(p, x, p.hz + 10 * u));
    if (xp - 22 * u > 0) p.laco(xp - 18 * u, 14 * u, (x) => _poltrona(p, x, p.hz + 8 * u));
  }
  final xe = s.xe;
  if (xe != null && s.xp != null) p.laco(xe + 11 * u, 4 * u, (x) => _planta(p, x, p.hz + 5 * u, 16 * u, semente: 4));
}

// ─────────────────────────── sala de estar (o sofá grande e a TV, para o filme e o jogo) ───────────────────────────

/// A planta da sala: a TV (com o painel e o rack) à esquerda do meio e o sofá embaixo da janela à direita,
/// uma vez só; o que sobra de parede ganha a estante, a luminária de pé, quadros e plantas.
typedef _PlantaSala = ({
  double xt, // a TV
  double tMeia,
  double xs, // o sofá (e a janela)
  double sMeia,
  List<(double, double)> vaos,
});

_PlantaSala _plantaDaSala(_Pincel p) {
  final u = p.u, w = p.w;
  if (w < 70 * u) {
    final tMeia = math.min(13 * u, w * .27);
    final sMeia = math.min(12 * u, w * .2);
    return (xt: w * .29, tMeia: tMeia, xs: w * .76, sMeia: sMeia, vaos: const []);
  }
  final tMeia = math.min(17 * u, w * .17);
  final sMeia = math.min(15 * u, w * .14);
  // a TV no meio (acima das cabeças; quase nunca há alguém no `centro`) e o sofá perto da borda direita, entre
  // o `centroDireita` e a `direita`, onde os atores de uma cena a dois não o tampam
  final xt = w * .5;
  final xs = math.max(xt + tMeia + sMeia + 6 * u, math.min(w - sMeia - 3 * u, w * .86));
  return (
    xt: xt,
    tMeia: tMeia,
    xs: xs,
    sMeia: sMeia,
    vaos: _vaosDaParede(p, [(xt, tMeia + 1 * u), (xs, sMeia + 6 * u)], minimo: 5 * u),
  );
}

/// A TV grande na parede (passando o jogo: o gramado, as linhas e o placar), o painel de ripas atrás e o rack.
void _tvDaSala(_Pincel p, double x, double meia) {
  final u = p.u;
  // painel de ripas de madeira
  final painel = Rect.fromLTRB(x - meia, 8 * u, x + meia, p.hz);
  p.ret(painel, const Color(0xFF6B4F3A), contorno: .8);
  final ripas = math.max(4, (painel.width / (2.2 * u)).round());
  for (var i = 1; i < ripas; i++) {
    final rx = painel.left + painel.width * i / ripas;
    p.c.drawLine(Offset(rx, painel.top), Offset(rx, painel.bottom), p.traco(.25));
  }
  // a TV
  final tw = meia * .82;
  final tela = Rect.fromLTRB(x - tw, 15 * u, x + tw, 15 * u + tw * 1.1);
  p.ret(tela.inflate(.7 * u), const Color(0xFF1C1E24), contorno: .8, raio: .4 * u);
  if (p.acesas) p.brilho(tela.center, tw * 1.8, const Color(0xFF7FD0FF), alfa: p.noite ? .2 : .14);
  p.c.save();
  p.c.clipRect(tela);
  p.c.drawRect(tela, Paint()..color = const Color(0xFF3FAE4F));
  final faixas = 6;
  for (var i = 0; i < faixas; i += 2) {
    p.c.drawRect(Rect.fromLTRB(tela.left + tela.width * i / faixas, tela.top, tela.left + tela.width * (i + 1) / faixas, tela.bottom),
        Paint()..color = const Color(0xFF4CBB5C));
  }
  final giz = Paint()
    ..color = const Color(0xE6FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, .3 * u);
  p.c.drawLine(Offset(tela.center.dx, tela.top), Offset(tela.center.dx, tela.bottom), giz);
  p.c.drawCircle(tela.center, tela.height * .2, giz);
  p.c.drawRect(Rect.fromLTRB(tela.left - 1, tela.center.dy - tela.height * .25, tela.left + tela.width * .1, tela.center.dy + tela.height * .25), giz);
  p.c.drawRect(Rect.fromLTRB(tela.right - tela.width * .1, tela.center.dy - tela.height * .25, tela.right + 1, tela.center.dy + tela.height * .25), giz);
  // os jogadores (dois times) e a bola, mexendo devagar
  for (var i = 0; i < 6; i++) {
    final fx = .2 + .6 * _ruido(i + 601) + math.sin(p.t * .7 + i) * .03;
    final fy = .25 + .55 * _ruido(i + 611);
    p.c.drawCircle(Offset(tela.left + tela.width * fx, tela.top + tela.height * fy), math.max(1.0, .6 * u),
        Paint()..color = i.isEven ? const Color(0xFFE53935) : const Color(0xFF1E6FD9));
  }
  p.c.drawCircle(Offset(tela.left + tela.width * (.5 + math.sin(p.t * .9) * .12), tela.top + tela.height * .55),
      math.max(.8, .4 * u), Paint()..color = _branco);
  // placar
  p.c.drawRRect(RRect.fromLTRBR(tela.left + .6 * u, tela.top + .6 * u, tela.left + 7.6 * u, tela.top + 2.6 * u, Radius.circular(.3 * u)),
      Paint()..color = const Color(0xE617202E));
  p.c.drawRect(Rect.fromLTWH(tela.left + 1 * u, tela.top + 1 * u, 1.2 * u, 1.2 * u), Paint()..color = const Color(0xFFE53935));
  p.c.drawRect(Rect.fromLTWH(tela.left + 5.8 * u, tela.top + 1 * u, 1.2 * u, 1.2 * u), Paint()..color = const Color(0xFF1E6FD9));
  _digitos(p, '1:0', Offset(tela.left + 2.7 * u, tela.top + .95 * u), 1.2 * u, _branco);
  p.c.restore();
  // o rack baixo com as gavetas, a caixinha de som e um vaso
  final rack = Rect.fromLTRB(x - meia * .92, p.hz - 8.6 * u, x + meia * .92, p.hz - 2 * u);
  for (final dx in [-.82, .82]) {
    p.ret(Rect.fromLTRB(x + dx * meia - .4 * u, rack.bottom, x + dx * meia + .4 * u, p.hz), const Color(0xFF3A2A22), contorno: .3);
  }
  p.ret(rack, const Color(0xFFC89B6C), contorno: .8, raio: .3 * u);
  final gav = 3;
  for (var i = 0; i < gav; i++) {
    final a = rack.left + rack.width * i / gav, b = rack.left + rack.width * (i + 1) / gav;
    if (i > 0) p.c.drawLine(Offset(a, rack.top), Offset(a, rack.bottom), p.traco(.35));
    p.ret(Rect.fromLTRB((a + b) / 2 - 1.4 * u, rack.center.dy - .3 * u, (a + b) / 2 + 1.4 * u, rack.center.dy + .3 * u),
        const Color(0xFF3A2A22), contorno: 0);
  }
  p.ret(Rect.fromLTRB(x - meia * .4, rack.top - 1.6 * u, x + meia * .4, rack.top), const Color(0xFF2B2F3A), contorno: .5, raio: .5 * u);
  _planta(p, x + meia * .72, rack.top, 6 * u, vaso: const Color(0xFFF4F1EA), semente: 21);
  p.ret(Rect.fromLTRB(x - meia * .8, rack.top - 3 * u, x - meia * .55, rack.top), const Color(0xFF3E8AE0), contorno: .4, raio: .3 * u);
}

/// A luminária de pé em arco (acesa à tarde e à noite).
void _luminariaDePe(_Pincel p, double x, double base) {
  final u = p.u;
  p.ret(Rect.fromLTRB(x - 2.4 * u, base - .9 * u, x + 2.4 * u, base), const Color(0xFF3A4152), contorno: .5, raio: .4 * u);
  p.tubos([
    Path()
      ..moveTo(x, base - .9 * u)
      ..lineTo(x, base - 22 * u)
      ..quadraticBezierTo(x, base - 27 * u, x + 5 * u, base - 26 * u),
  ], .45 * u, const Color(0xFF3A4152), contorno: .4);
  final cx = x + 6 * u, cy = base - 25 * u;
  if (p.acesas) _luzQuente(p, Offset(cx, cy + 3 * u), 13 * u, forca: .9);
  p.forma(
      Path()
        ..moveTo(cx - 1.6 * u, cy - 1.6 * u)
        ..lineTo(cx + 1.6 * u, cy - 1.6 * u)
        ..lineTo(cx + 3 * u, cy + 1.6 * u)
        ..lineTo(cx - 3 * u, cy + 1.6 * u)
        ..close(),
      p.acesas ? const Color(0xFFFFE08A) : const Color(0xFFF2EEE2),
      contorno: .6,
      emite: p.acesas);
}

void _dSalaDeEstar(_Pincel p) {
  final u = p.u;
  final s = _plantaDaSala(p);
  final jMeia = math.max(4 * u, s.sMeia * .78);
  // lá fora: os prédios baixos do outro lado da rua e uma árvore
  for (var i = 0; i < 3; i++) {
    p.laco(s.xs - jMeia + (i + .5) * jMeia * 2 / 3, jMeia / 2, (x) {
      final alt = (10 + 6 * _ruido(i + 701)) * u;
      _predio(p, Rect.fromLTRB(x - jMeia / 3, p.hz - 22 * u - alt, x + jMeia / 3, p.hz - 21 * u),
          [const Color(0xFFD9A08A), const Color(0xFFB9C4D6), const Color(0xFFE6CFA0)][i], semente: i + 70);
    });
  }
  p.laco(s.xs + jMeia * .6, 5 * u, (x) => _arvore(p, x, p.hz - 21 * u, 12 * u, copa: _verdePinheiro));
  final janelas = <RRect>[];
  p.laco(s.xs, jMeia + u, (x) => janelas.add(RRect.fromLTRBR(x - jMeia, 11 * u, x + jMeia, p.hz - 22 * u, Radius.circular(.6 * u))));
  _parede(p, const Color(0xFFD3DEE8), janelas);
  for (final j in janelas) {
    _moldura(p, j, _branco);
    _cortinas(p, j, const Color(0xFF8E6BBF));
  }
  // rodameio de madeira e o teto
  p.faixa(-2, 2.4 * u, const Color(0xFFF4F6F8), contorno: .5);
  p.laco(s.xt, s.tMeia + u, (x) => _tvDaSala(p, x, s.tMeia));
  var k = 0;
  for (final (x0, meia) in s.vaos) {
    if (k == 0 && meia >= 8 * u) {
      p.laco(x0, 7 * u, (x) => _estante(p, x, 22 * u, p.hz, math.min(6 * u, meia - 1.5 * u)));
    } else if (meia >= 9 * u) {
      p.laco(x0, 7 * u, (x) => _quadrinhos(p, x));
    } else {
      p.laco(x0, 3 * u, (x) => _quadroDePaisagem(p, Rect.fromCenter(center: Offset(x, 22 * u), width: 5 * u, height: 4 * u), k));
    }
    k++;
  }
  p.faixa(p.hz - 1.2 * u, p.hz, const Color(0xFFFAF6EE), contorno: .5);
}

/// O sofá grande de 3 lugares (mostarda), com almofadas e a manta dobrada no braço.
void _sofaGrande(_Pincel p, double x, double base, double meia) {
  final u = p.u;
  const cor = Color(0xFFD99A2B), claro = Color(0xFFE8AE45);
  final costas = Rect.fromLTRB(x - meia + 1.6 * u, base - 13 * u, x + meia - 1.6 * u, base - 4 * u);
  p.ret(costas, cor, contorno: .9, raio: 2 * u);
  final assento = Rect.fromLTRB(x - meia + 2 * u, base - 6.4 * u, x + meia - 2 * u, base - 2 * u);
  p.ret(assento, claro, contorno: .8, raio: 1 * u);
  for (final f in [1 / 3, 2 / 3]) {
    final dx = assento.left + assento.width * f;
    p.c.drawLine(Offset(dx, assento.top), Offset(dx, assento.bottom), p.traco(.4));
  }
  for (final lado in [-1.0, 1.0]) {
    final braco = Rect.fromLTRB(lado < 0 ? x - meia : x + meia - 3.6 * u, base - 8.6 * u, lado < 0 ? x - meia + 3.6 * u : x + meia,
        base - 1.6 * u);
    p.ret(braco, cor, contorno: .9, raio: 1.6 * u);
    p.ret(Rect.fromLTRB(braco.center.dx - .4 * u, base - 1.6 * u, braco.center.dx + .4 * u, base), const Color(0xFF3A2A22), contorno: .3);
  }
  // almofadas e a manta
  for (final (f, c2) in [(-.55, const Color(0xFF3F8F8A)), (0.0, const Color(0xFFF2EEE2)), (.5, const Color(0xFFE5533D))]) {
    final c = Offset(x + f * meia, base - 8.6 * u);
    p.forma(
        Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 4.6 * u, height: 4 * u), Radius.circular(1.3 * u))),
        c2,
        contorno: .6);
  }
  final mx = x + meia - 1.8 * u;
  p.ret(Rect.fromLTRB(mx - 2.2 * u, base - 9.4 * u, mx + 2.2 * u, base - 4.6 * u), const Color(0xFF6FC3C9), contorno: .5, raio: .4 * u);
  for (var i = 0; i < 2; i++) {
    p.c.drawLine(Offset(mx - 2.2 * u, base - (8 - i * 1.8) * u), Offset(mx + 2.2 * u, base - (8 - i * 1.8) * u),
        Paint()
          ..color = p.luz(_branco)
          ..strokeWidth = .4 * u);
  }
}

/// A mesinha de centro com o balde de pipoca e o controle remoto.
void _mesinhaDeCentro(_Pincel p, double x, double base) {
  final u = p.u;
  p.ret(Rect.fromLTRB(x - 7 * u, base - 5 * u, x + 7 * u, base - 4 * u), const Color(0xFF8A5F3C), contorno: .7, raio: .4 * u);
  for (final dx in [-6.0, 6.0]) {
    p.ret(Rect.fromLTRB(x + dx * u - .4 * u, base - 4 * u, x + dx * u + .4 * u, base), const Color(0xFF6B4A32), contorno: .3);
  }
  // balde de pipoca listrado
  final bx = x - 2 * u;
  final balde = Path()
    ..moveTo(bx - 2.2 * u, base - 9.6 * u)
    ..lineTo(bx + 2.2 * u, base - 9.6 * u)
    ..lineTo(bx + 1.6 * u, base - 5 * u)
    ..lineTo(bx - 1.6 * u, base - 5 * u)
    ..close();
  for (var i = 0; i < 5; i++) {
    p.circ(Offset(bx - 1.8 * u + i * .9 * u, base - 10 * u - (i.isOdd ? .6 * u : 0)), .8 * u, const Color(0xFFFFF4D6), contorno: .25);
  }
  p.forma(balde, _branco, contorno: .6);
  p.c.save();
  p.c.clipPath(balde);
  for (var i = 0; i < 3; i++) {
    p.c.drawRect(Rect.fromLTWH(bx - 2.2 * u + i * 1.6 * u, base - 9.6 * u, .8 * u, 4.6 * u), p.tinta(const Color(0xFFE53935)));
  }
  p.c.restore();
  p.c.drawPath(balde, p.traco(.6));
  p.ret(Rect.fromLTRB(x + 2 * u, base - 5.6 * u, x + 5 * u, base - 5 * u), const Color(0xFF2B2B2B), contorno: .3, raio: .2 * u);
}

void _cSalaDeEstar(_Pincel p) {
  final u = p.u;
  // assoalho escuro em tábuas compridas
  p.solo(const [Color(0xFFA0704A), Color(0xFF83593A)]);
  final tabua = p.traco(.2);
  var y0 = p.hz;
  for (var i = 1; i < 8; i++) {
    final y = p.hz + i * i * .62 * u;
    p.c.drawLine(Offset(-2, y), Offset(p.w + 2, y), tabua);
    final juntas = p.vezes(18 * u);
    for (var k = 0; k < juntas; k++) {
      final x = (k + .37 * i % 1 + .5 * _ruido(i * 11 + k + 50)) * p.w / juntas;
      p.c.drawLine(Offset(x, y0), Offset(x, y), tabua);
    }
    y0 = y;
  }
  final s = _plantaDaSala(p);
  // tapete, sofá e a mesinha de centro na frente
  p.laco(s.xs, s.sMeia + 8 * u, (x) {
    p.forma(Path()..addRRect(RRect.fromLTRBR(x - s.sMeia - 5 * u, p.hz + 9 * u, x + s.sMeia + 5 * u, p.hz + 17 * u, Radius.circular(.6 * u))),
        const Color(0xFF5B6FA8),
        contorno: .6);
    p.c.drawRRect(
        RRect.fromLTRBR(x - s.sMeia - 3.6 * u, p.hz + 10.2 * u, x + s.sMeia + 3.6 * u, p.hz + 15.8 * u, Radius.circular(.4 * u)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .45 * u
          ..color = p.luz(const Color(0xFFF2C95C)));
    _sofaGrande(p, x, p.hz + 8 * u, s.sMeia);
  });
  p.laco(s.xs - s.sMeia * .45, 8 * u, (x) => _mesinhaDeCentro(p, x, p.hz + 14 * u));
  p.laco(s.xs - s.sMeia - 2.6 * u, 10 * u, (x) => _luminariaDePe(p, x, p.hz + 8 * u));
  // tela larga: um pufe perto da TV
  if (s.vaos.isNotEmpty) {
    p.laco(s.xt + s.tMeia + 4 * u, 3 * u, (x) {
      p.ret(Rect.fromLTRB(x - 3 * u, p.hz + 6 * u, x + 3 * u, p.hz + 11 * u), const Color(0xFF8E6BBF), contorno: .7, raio: 1.6 * u);
    });
  }
}

// ═══════════════════════ 3ª leva das lições (pedidos de arte que sobraram da 2ª leva) ═══════════════════════

/// [x] andando para a esquerda a [vel] px/s com o relógio, dentro do ciclo da largura (a paisagem que passa).
double _rola(_Pincel p, double x, double vel) => (x - p.t * vel) % p.w;

/// Polígono fechado pelos [pontos].
Path _poligono(List<Offset> pontos) {
  final path = Path()..moveTo(pontos.first.dx, pontos.first.dy);
  for (final o in pontos.skip(1)) {
    path.lineTo(o.dx, o.dy);
  }
  return path..close();
}

// ─────────────────────────── dentroDoCarro (o carro por dentro: bancos, painel e a rua passando) ───────────────────────────
//
// O carro visto de lado, por dentro (a porta do nosso lado não aparece): a frente fica à direita (coluna A, para-brisa,
// painel com o volante, o retrovisor e o pinheirinho cheiroso), a traseira à esquerda (o vidro de trás e a coluna C), os
// vidros laterais com a rua passando (prédios, árvores e postes andando para a esquerda com o relógio) e os 2 bancos
// de perfil nos lugares das duplas (`centroEsquerda` e `centroDireita`): quem fica ali parece sentado. Serve para
// carro, táxi e carona. NÃO é o carro do Turismo (proibido nas lições): só o interior, sem pista.

/// A planta do carro: onde acaba a traseira, onde começa a frente, os vidros laterais e os bancos (px).
typedef _PlantaCarro = ({
  double tras, // fim da traseira (vidro de trás e coluna C)
  double frente, // começo da frente (coluna A, para-brisa e painel)
  List<(double, double)> vidros, // (esquerda, direita) de cada vidro lateral, de trás para a frente
  List<double> bancos, // x de cada banco (o de trás e o do motorista)
});

const _topoDoVidro = 13.0, _cintaDoCarro = 40.0, _prateleiraDoCarro = 33.0;

_PlantaCarro _plantaDoCarro(_Pincel p) {
  final u = p.u, w = p.w;
  final frente = w - (w * .24).clamp(16 * u, 34 * u).toDouble();
  final tras = (w * .12).clamp(7 * u, 20 * u).toDouble();
  final livre = frente - tras;
  final n = (livre / (46 * u)).round().clamp(1, 3);
  final coluna = 2.6 * u;
  final vao = (livre - (n - 1) * coluna) / n;
  final retrato = p.h > w;
  return (
    tras: tras,
    frente: frente,
    vidros: [for (var i = 0; i < n; i++) (tras + i * (vao + coluna), tras + i * (vao + coluna) + vao)],
    bancos: [w * (retrato ? .33 : .31), w * (retrato ? .67 : .69)],
  );
}

/// A coluna A (do teto ao painel, inclinada para a frente) e a coluna C (inclinada para trás), em px: (topo, base).
(Offset, Offset) _colunaA(_Pincel p, _PlantaCarro s) =>
    (Offset(s.frente + 1.4 * p.u, _topoDoVidro * p.u), Offset(s.frente + (p.w - s.frente) * .46, _cintaDoCarro * p.u));
(Offset, Offset) _colunaC(_Pincel p, _PlantaCarro s) =>
    (Offset(s.tras - 1.4 * p.u, _topoDoVidro * p.u), Offset(s.tras * .4, _prateleiraDoCarro * p.u));

/// x da reta [a]–[b] na altura [y].
double _xNaReta(Offset a, Offset b, double y) => a.dx + (b.dx - a.dx) * (y - a.dy) / (b.dy - a.dy);

/// Os vidros do carro (o de trás, os laterais e o para-brisa), como polígonos em px.
List<Path> _vidrosDoCarro(_Pincel p, _PlantaCarro s) {
  final u = p.u;
  final topo = _topoDoVidro * u, cinta = _cintaDoCarro * u, prat = _prateleiraDoCarro * u;
  final (at, ab) = _colunaA(p, s);
  final (ct, cb) = _colunaC(p, s);
  final vidros = <Path>[
    // o de trás (até a prateleira) e o para-brisa (até o painel), abertos para as bordas: fecham o ciclo
    _poligono([Offset(-2, topo - 1 * u), Offset(ct.dx - 1.6 * u, topo - 1 * u), Offset(cb.dx - 1.6 * u, prat), Offset(-2, prat)]),
    _poligono([
      Offset(at.dx + 1.6 * u, topo - 1 * u),
      Offset(p.w + 2, topo - 1 * u),
      Offset(p.w + 2, cinta),
      Offset(ab.dx + 1.6 * u, cinta),
    ]),
  ];
  for (var i = 0; i < s.vidros.length; i++) {
    final (l, r) = s.vidros[i];
    final primeiro = i == 0, ultimo = i == s.vidros.length - 1;
    // o 1º segue a coluna C e o último a coluna A (cantos de cima arredondados por um chanfro)
    final lt = primeiro ? _xNaReta(ct, cb, topo) + 1.6 * u : l;
    final lb = primeiro ? _xNaReta(ct, cb, cinta) + 1.6 * u : l;
    final rt = ultimo ? _xNaReta(at, ab, topo) - 1.6 * u : r;
    final rb = ultimo ? _xNaReta(at, ab, cinta) - 1.6 * u : r;
    final ch = 2.2 * u;
    vidros.add(_poligono([
      Offset(lt, topo + ch),
      Offset(lt + ch * .6, topo),
      Offset(rt - (ultimo ? 0 : ch * .6), topo),
      Offset(rt, topo + (ultimo ? 0 : ch)),
      Offset(rb, cinta),
      Offset(lb, cinta),
    ]));
  }
  return vidros;
}

/// A rua passando pelos vidros: o perfil da cidade longe (devagar), prédios e casas (médio) e, perto, árvores e
/// postes (rápido). Tudo anda para a esquerda com o relógio e fecha o ciclo na largura.
void _ruaPassando(_Pincel p) {
  final u = p.u;
  final base = 46 * u; // a calçada fica abaixo da linha da porta (não aparece)
  // longe: o perfil da cidade, em azul-acinzentado
  final longe = p.tinta(const Color(0xFFAFBBD0));
  final janelinha = Paint()..color = const Color(0xCCFFE08A);
  final n1 = p.vezes(7 * u);
  for (var i = 0; i < n1; i++) {
    final passo = p.w / n1;
    final alt = (16 + 12 * _ruido(i * 5 + 900)) * u;
    p.laco(_rola(p, (i + .5) * passo, 2.2 * u), passo / 2 + 1, (x) {
      final r = Rect.fromLTRB(x - passo * .49, base - 4 * u - alt, x + passo * .49, base);
      p.c.drawRect(r, longe);
      if (p.noite) {
        for (var j = 0; j < 4; j++) {
          if (_ruido(i * 29 + j) > .5) p.c.drawRect(Rect.fromLTWH(r.left + passo * .3, r.top + (2 + j * 3) * u, passo * .25, .9 * u), janelinha);
        }
      }
    });
  }
  // médio: prédios e lojas com toldo
  const cores = [Color(0xFFD9A08A), Color(0xFF8FA6C8), Color(0xFFE6CFA0), Color(0xFFA7C7B0), Color(0xFFC9A7C7)];
  final n2 = p.vezes(15 * u);
  for (var i = 0; i < n2; i++) {
    final passo = p.w / n2;
    final larg = passo * (.72 + .22 * _ruido(i * 7 + 910));
    final alt = (11 + 14 * _ruido(i * 7 + 911)) * u;
    p.laco(_rola(p, (i + .5) * passo, 8 * u), larg / 2 + 1, (x) {
      _predio(p, Rect.fromLTWH(x - larg / 2, base - alt, larg, alt), cores[i % cores.length], semente: i + 300);
    });
  }
  // perto: árvores da calçada e postes (acesos à tarde e à noite), passando rápido
  final n3 = p.vezes(26 * u);
  for (var i = 0; i < n3; i++) {
    final passo = p.w / n3;
    p.laco(_rola(p, (i + .25) * passo, 30 * u), 6 * u, (x) => _arvore(p, x, base + 2 * u, 21 * u, contorno: .8));
    if (i.isOdd || n3 == 1) {
      p.laco(_rola(p, (i + .75) * passo, 30 * u), 5 * u, (x) => _poste(p, x, base + 2 * u, 26 * u, aceso: p.acesas));
    }
  }
}

/// O volante de perfil (o aro inclinado com os raios) e a coluna da direção, com o centro em [o].
void _volante(_Pincel p, Offset o) {
  final u = p.u;
  p.tubos([
    Path()
      ..moveTo(o.dx, o.dy)
      ..lineTo(o.dx + 5 * u, o.dy + 1.8 * u)
  ], 1.3 * u, const Color(0xFF2B2E35), contorno: .5);
  p.c.save();
  p.c.translate(o.dx, o.dy);
  p.c.rotate(.32);
  final aro = Rect.fromCenter(center: Offset.zero, width: 3.2 * u, height: 12 * u);
  p.c.drawOval(aro, p.traco(1)..strokeWidth = 1.6 * u + 2 * p.k);
  p.c.drawOval(aro, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6 * u
    ..color = p.luz(const Color(0xFF2B2E35)));
  p.c.drawLine(Offset(0, -5 * u), Offset(0, 5 * u), Paint()
    ..strokeWidth = .7 * u
    ..color = p.luz(const Color(0xFF4A4F57)));
  p.circ(Offset.zero, 1.2 * u, const Color(0xFF4A4F57), contorno: .4);
  p.c.restore();
}

/// O painel: o capô do quadro de instrumentos (velocímetro e conta-giros, acesos à noite), a saída de ar, o celular
/// no suporte com o mapa do GPS, o porta-luvas e o volante. Vai de [l] até a borda direita (e um pouco além).
void _painelDoCarro(_Pincel p, double l) {
  final u = p.u;
  final topo = 36 * u;
  final painel = Path()
    ..moveTo(l, p.hz)
    ..lineTo(l, topo + 7 * u)
    ..quadraticBezierTo(l, topo, l + 5 * u, topo)
    ..lineTo(p.w + 2, topo - 1 * u)
    ..lineTo(p.w + 2, p.hz)
    ..close();
  p.forma(painel, const Color(0xFF3A3F4B), contorno: .9);
  p.sombra(painel, Rect.fromLTRB(l, topo + 9 * u, p.w + 2, p.hz), alfa: .2);
  // o capô do quadro de instrumentos: uma telinha com o arco do velocímetro e a velocidade (acesa à tarde e à noite)
  final capo = Rect.fromLTRB(l + 1.4 * u, topo - 2.2 * u, l + 11 * u, topo + 1 * u);
  p.ret(capo, const Color(0xFF2B2E35), contorno: .7, raio: 1.4 * u);
  final aceso = p.acesas;
  final quadro = Rect.fromLTRB(l + 2 * u, topo + .2 * u, l + 10.4 * u, topo + 4.6 * u);
  p.ret(quadro, const Color(0xFF123447), contorno: .5, raio: .8 * u, emite: true);
  if (aceso) p.brilho(quadro.center, 5 * u, const Color(0xFF4DD0E1), alfa: .3);
  final arco = Rect.fromCenter(center: Offset(quadro.left + 2.4 * u, quadro.bottom - .6 * u), width: 3.4 * u, height: 3.4 * u);
  p.c.drawArc(arco, math.pi, math.pi, false, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, .4 * u)
    ..color = const Color(0xFF4DD0E1));
  p.c.drawLine(arco.center, arco.center + Offset(math.cos(-.9), math.sin(-.9)) * 1.5 * u, Paint()
    ..strokeWidth = math.max(1.0, .3 * u)
    ..strokeCap = StrokeCap.round
    ..color = const Color(0xFFFF5A3C));
  _digitos(p, '60', Offset(quadro.left + 4.6 * u, quadro.top + 1 * u), 2 * u, const Color(0xFF7CF2D0));
  // saída de ar, celular com o GPS e o porta-luvas
  final xa = l + 13.5 * u;
  final ar = Rect.fromLTRB(xa, topo + 1.4 * u, xa + 4.4 * u, topo + 4 * u);
  p.ret(ar, const Color(0xFF22252C), contorno: .5, raio: .5 * u);
  for (var i = 1; i < 3; i++) {
    p.c.drawLine(Offset(ar.left + .4 * u, ar.top + ar.height * i / 3), Offset(ar.right - .4 * u, ar.top + ar.height * i / 3),
        p.traco(.25));
  }
  final cel = Rect.fromLTRB(xa + .4 * u, topo - 6.6 * u, xa + 4 * u, topo - .6 * u);
  p.ret(Rect.fromLTRB(cel.center.dx - .4 * u, cel.bottom, cel.center.dx + .4 * u, ar.top), const Color(0xFF22252C), contorno: .3);
  p.ret(cel, const Color(0xFF17191D), contorno: .6, raio: .5 * u);
  final tela = cel.deflate(.35 * u);
  p.ret(tela, const Color(0xFFDDEFD9), contorno: 0, emite: true);
  p.c.save();
  p.c.clipRect(tela);
  final rua = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, .35 * u)
    ..color = const Color(0xFFFFFFFF);
  p.c.drawLine(Offset(tela.left, tela.top + tela.height * .3), Offset(tela.right, tela.top + tela.height * .45), rua);
  p.c.drawLine(Offset(tela.left + tela.width * .6, tela.top), Offset(tela.left + tela.width * .4, tela.bottom), rua);
  p.c.drawPath(
      Path()
        ..moveTo(tela.center.dx - .2 * u, tela.bottom)
        ..lineTo(tela.center.dx - .1 * u, tela.center.dy)
        ..lineTo(tela.right, tela.top + tela.height * .42),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.0, .5 * u)
        ..color = const Color(0xFF2F80ED));
  p.c.restore();
  p.circ(Offset(tela.center.dx - .1 * u, tela.center.dy + .3 * u), .45 * u, const Color(0xFFE53935), contorno: .2, emite: true);
  if (p.w - xa > 14 * u) {
    final luvas = Rect.fromLTRB(xa + 6 * u, topo + 6 * u, math.min(p.w - 1 * u, xa + 15 * u), topo + 11 * u);
    p.ret(luvas, const Color(0xFF444A57), contorno: .5, raio: .6 * u);
    p.ret(Rect.fromCenter(center: Offset(luvas.center.dx, luvas.top + 1.2 * u), width: 2.4 * u, height: .6 * u),
        const Color(0xFF8D99A8), contorno: .2);
  }
  _volante(p, Offset(l - 2.4 * u, topo + 6.6 * u));
}

void _dDentroDoCarro(_Pincel p) {
  final u = p.u;
  final s = _plantaDoCarro(p);
  final topo = _topoDoVidro * u, cinta = _cintaDoCarro * u;
  _ruaPassando(p);
  final vidros = _vidrosDoCarro(p, s);
  // o vidro: um véu azulado e dois reflexos em cada um
  for (final v in vidros) {
    p.c.drawPath(v, Paint()..color = const Color(0x1A9FD3F5));
    final b = v.getBounds();
    p.c.save();
    p.c.clipPath(v);
    for (final f in [.2, .62]) {
      p.c.drawPath(
          _poligono([
            Offset(b.left + b.width * f, b.top),
            Offset(b.left + b.width * f + 3 * u, b.top),
            Offset(b.left + b.width * f - 5 * u, b.bottom),
            Offset(b.left + b.width * f - 8 * u, b.bottom),
          ]),
          Paint()..color = const Color(0x22FFFFFF));
    }
    p.c.restore();
  }
  // a lataria por dentro: tudo menos os vidros
  final lataria = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTRB(-2, -2, p.w + 2, p.hz));
  for (final v in vidros) {
    lataria.addPath(v, Offset.zero);
  }
  p.c.drawPath(lataria, p.tinta(const Color(0xFFCFC6B8)));
  for (final v in vidros) {
    p.c.drawPath(v, p.traco(.8)..strokeWidth = 1.2 * u);
    p.c.drawPath(v, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7 * u
      ..strokeJoin = StrokeJoin.round
      ..color = p.luz(const Color(0xFF2B2E35)));
  }
  // o forro do teto (com o corte da lataria em cima), a luz de cortesia (acesa à tarde e à noite) e as alças
  p.faixa(-2, topo - 2.6 * u, const Color(0xFFE6DFD2), contorno: .5);
  p.faixa(-2, 1.2 * u, _corDoCarro, contorno: .6);
  final xl = (s.tras + s.frente) / 2;
  p.laco(xl, 3 * u, (x) {
    if (p.acesas) _luzQuente(p, Offset(x, 4 * u), 20 * u, forca: .8);
    p.ret(Rect.fromLTRB(x - 2.6 * u, 2.4 * u, x + 2.6 * u, 4.4 * u), p.acesas ? const Color(0xFFFFF3C4) : const Color(0xFFF4F1EA),
        contorno: .5, raio: .6 * u, emite: p.acesas);
  });
  for (var i = 0; i < s.vidros.length - 1; i++) {
    final (l, r) = s.vidros[i];
    final cx = (l + r) / 2;
    p.c.drawArc(Rect.fromCenter(center: Offset(cx, topo - 2.6 * u), width: 6 * u, height: 3 * u), 0, math.pi, false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8 * u
          ..strokeCap = StrokeCap.round
          ..color = p.luz(const Color(0xFF8A8478)));
  }
  // as colunas B (entre os vidros), com o cinto de segurança
  for (var i = 1; i < s.vidros.length; i++) {
    final x = (s.vidros[i - 1].$2 + s.vidros[i].$1) / 2;
    p.tubos([
      Path()
        ..moveTo(x + .6 * u, topo + 1 * u)
        ..lineTo(x - .2 * u, cinta + 6 * u)
    ], .9 * u, const Color(0xFF59606C), contorno: .3);
    p.ret(Rect.fromCenter(center: Offset(x + .6 * u, topo + 1 * u), width: 1.8 * u, height: 1.2 * u), const Color(0xFF8D99A8),
        contorno: .3, raio: .3 * u);
  }
  // as portas: a cinta, os painéis com o apoio de braço, a maçaneta e o alto-falante
  p.faixa(cinta - .4 * u, cinta + 1.2 * u, const Color(0xFF6F6A63), contorno: .5);
  for (final (l, r) in s.vidros) {
    final porta = Rect.fromLTRB(l + .8 * u, cinta + 2.2 * u, r - .8 * u, p.hz - 1.2 * u);
    if (porta.width < 4 * u) continue;
    p.ret(porta, const Color(0xFFBDB4A6), contorno: .6, raio: 1.2 * u);
    p.ret(Rect.fromLTRB(porta.left + 1.4 * u, porta.top + 1.4 * u, porta.right - 1.4 * u, porta.top + 8 * u), const Color(0xFF8E8794),
        contorno: .4, raio: .8 * u);
    p.ret(Rect.fromLTRB(porta.left + 2 * u, porta.top + 9 * u, porta.right - 2 * u, porta.top + 10.6 * u), const Color(0xFF59606C),
        contorno: .45, raio: .6 * u);
    p.ret(Rect.fromLTRB(porta.right - 6 * u, porta.top + 3.6 * u, porta.right - 3 * u, porta.top + 5 * u), const Color(0xFFC9CED6),
        contorno: .35, raio: .5 * u);
    final sp = Offset(porta.left + math.min(5 * u, porta.width * .25), porta.bottom - 4.6 * u);
    if (porta.height > 12 * u) {
      p.circ(sp, 2.4 * u, const Color(0xFF4A4F57), contorno: .5);
      p.circ(sp, 1.2 * u, const Color(0xFF2B2E35), contorno: .3);
    }
  }
  // a prateleira de trás (com o alto-falante) e a coluna C
  final prat = _prateleiraDoCarro * u;
  final (_, cb) = _colunaC(p, s);
  p.ret(Rect.fromLTRB(-2, prat, cb.dx + 1 * u, prat + 2 * u), const Color(0xFF4A4F57), contorno: .6);
  // a frente: o quebra-sol, o retrovisor com o pinheirinho cheiroso e o painel
  final (at, ab) = _colunaA(p, s);
  final quebra = _poligono([
    Offset(at.dx + 2.4 * u, topo - 2.2 * u),
    Offset(at.dx + 11 * u, topo - 2.2 * u),
    Offset(at.dx + 10.4 * u, topo + 1.4 * u),
    Offset(at.dx + 3.6 * u, topo + 2.2 * u),
  ]);
  p.forma(quebra, const Color(0xFFD9D1C2), contorno: .5);
  final xr = math.min(p.w - 4 * u, s.frente + (p.w - s.frente) * .7);
  p.ret(Rect.fromLTRB(xr - .3 * u, topo - 2.4 * u, xr + .3 * u, topo), const Color(0xFF2B2E35), contorno: .2);
  p.ret(Rect.fromLTRB(xr - 3 * u, topo, xr + 2 * u, topo + 1.8 * u), const Color(0xFF2B2E35), contorno: .5, raio: .7 * u);
  final balanco = math.sin(p.t * 2.2) * .18;
  p.c.save();
  p.c.translate(xr - 1 * u, topo + 1.8 * u);
  p.c.rotate(balanco);
  p.c.drawLine(Offset.zero, Offset(0, 2 * u), p.traco(.25));
  p.forma(_poligono([Offset(0, 1.8 * u), Offset(1.3 * u, 4.6 * u), Offset(.5 * u, 4.6 * u), Offset(.5 * u, 5.2 * u),
    Offset(-.5 * u, 5.2 * u), Offset(-.5 * u, 4.6 * u), Offset(-1.3 * u, 4.6 * u)]), const Color(0xFF2EAD5B), contorno: .35);
  p.c.restore();
  _painelDoCarro(p, s.frente + (ab.dx - s.frente) * .35);
}

/// Um banco do carro de perfil (de frente para a direita): encosto inclinado, encosto de cabeça e o assento.
void _bancoDoCarro(_Pincel p, double x, double base) {
  final u = p.u;
  const couro = Color(0xFF9C6A3E), claro = Color(0xFFB98552);
  // o trilho e o pé do banco
  p.ret(Rect.fromLTRB(x - 5 * u, base - 4 * u, x + 4 * u, base - 1 * u), const Color(0xFF2B2E35), contorno: .5);
  // encosto de cabeça (com as hastes)
  for (final dx in [-6.4, -4.6]) {
    p.ret(Rect.fromLTRB(x + (dx - .25) * u, base - 36 * u, x + (dx + .25) * u, base - 33 * u), const Color(0xFF8D99A8), contorno: .3);
  }
  p.ret(Rect.fromLTRB(x - 8.6 * u, base - 41 * u, x - 2.8 * u, base - 35.6 * u), couro, contorno: .8, raio: 1.6 * u);
  // encosto (um pouco deitado para trás)
  final encosto = _poligono([
    Offset(x - 9.4 * u, base - 33 * u),
    Offset(x - 2.6 * u, base - 33.4 * u),
    Offset(x - .6 * u, base - 8 * u),
    Offset(x - 7.6 * u, base - 6 * u),
  ]);
  p.forma(encosto, couro, contorno: .9);
  p.c.save();
  p.c.clipPath(encosto);
  final costura = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(.8, .2 * u)
    ..color = p.luz(claro);
  for (final f in [.32, .64]) {
    p.c.drawLine(Offset(x - 9.4 * u + 7 * u * .1, base - 33 * u + 27 * u * f), Offset(x - .6 * u, base - 33 * u + 26 * u * f),
        costura);
  }
  p.c.restore();
  // o assento
  p.ret(Rect.fromLTRB(x - 8 * u, base - 9.4 * u, x + 6 * u, base - 4 * u), claro, contorno: .9, raio: 2 * u);
  p.sombra(Path()..addRRect(RRect.fromLTRBR(x - 8 * u, base - 9.4 * u, x + 6 * u, base - 4 * u, Radius.circular(2 * u))),
      Rect.fromLTRB(x - 8 * u, base - 6 * u, x + 6 * u, base - 4 * u), alfa: .18);
}

void _cDentroDoCarro(_Pincel p) {
  final u = p.u;
  // o carpete do assoalho e a soleira de metal
  p.solo(const [Color(0xFF4A4E57), Color(0xFF34373F)]);
  // a lataria cortada do nosso lado (embaixo), como numa maquete: o carro é de verdade, só sem a porta da frente
  final corte = math.max(p.pe + 5 * u, p.h - 7 * u);
  p.faixa(p.hz, p.hz + 1.4 * u, const Color(0xFFB8C0CA), contorno: .5);
  final risco = Paint()
    ..strokeWidth = math.max(.6, .15 * u)
    ..color = const Color(0x1AFFFFFF);
  for (var i = 0; i < p.vezes(2.4 * u); i++) {
    final x = (i + .5) * p.w / p.vezes(2.4 * u);
    p.c.drawLine(Offset(x, p.hz + 2 * u), Offset(x + (x - p.w / 2) * .1, p.h), risco);
  }
  final s = _plantaDoCarro(p);
  for (final x in s.bancos) {
    p.laco(x, 11 * u, (x) => _bancoDoCarro(p, x, p.hz + 12 * u));
  }
  // os pedais embaixo do painel
  final (_, ab) = _colunaA(p, s);
  final l = s.frente + (ab.dx - s.frente) * .35;
  for (final dx in [1.0, 4.0]) {
    p.ret(Rect.fromLTRB(l + dx * u, p.hz + 1 * u, l + (dx + 2) * u, p.hz + 4 * u), const Color(0xFF2B2E35), contorno: .4, raio: .4 * u);
  }
  p.faixa(corte, p.h + 2, _corDoCarro, contorno: .8);
  p.faixa(corte + 1.2 * u, corte + 2 * u, const Color(0xFFDDE3EA), contorno: .3);
}

/// A pintura do carro (o corte da lataria em cima e embaixo).
const _corDoCarro = Color(0xFF2F7D8C);


// ─────────────────────────── cozinha (a cozinha de casa: geladeira vermelha, pia na janela e o fogão) ───────────────────────────
//
// Diferente do canto de cozinha da `casa` (que é sala): aqui a parede inteira é cozinha. A geladeira retrô vermelha
// (com a lista e o desenho presos por ímãs) fica na borda esquerda; a pia embaixo da janela; o fogão com a panela
// fumegando e a coifa no meio (acima das cabeças, onde quase nunca há alguém); na tela larga, a despensa, o calendário
// e o relógio à direita e a mesinha com duas cadeiras no chão. Um cômodo só em qualquer largura.

typedef _PlantaCozinha = ({
  double gl, // começo da geladeira
  double gw, // largura da geladeira
  double xj, // meio da janela (e da pia)
  double jMeia,
  double xf, // meio do fogão
  double fim, // fim da bancada
  double? despensa,
  double? mesa,
  List<(double, double)> vaos,
});

_PlantaCozinha _plantaDaCozinha(_Pincel p) {
  final u = p.u, w = p.w;
  if (w < 70 * u) {
    final gw = math.min(11 * u, w * .19);
    final gl = w * .03;
    return (
      gl: gl,
      gw: gw,
      xj: gl + gw + (w * .78 - 8 * u - gl - gw) / 2,
      jMeia: math.min(8 * u, (w * .78 - 8 * u - gl - gw) / 2 - 1.5 * u),
      xf: w * .78,
      fim: w - 1 * u,
      despensa: null,
      mesa: null,
      vaos: const [],
    );
  }
  final gl = math.min(w * .03, 4 * u), gw = 13 * u;
  final xf = w * .5;
  final xj = (gl + gw + xf - 9 * u) / 2;
  final jMeia = ((xf - 9 * u - gl - gw) / 2 - 3 * u).clamp(6 * u, 16 * u).toDouble();
  final fim = xf + math.max(16 * u, w * .14);
  final despensa = w - 8 * u > fim + 14 * u ? w - 8 * u : null;
  final ocupadas = <(double, double)>[((gl + fim) / 2, (fim - gl) / 2), if (despensa != null) (despensa, 7 * u)];
  return (
    gl: gl,
    gw: gw,
    xj: xj,
    jMeia: jMeia,
    xf: xf,
    fim: fim,
    despensa: despensa,
    mesa: despensa != null && despensa - fim > 30 * u ? (fim + despensa) / 2 : null,
    vaos: _vaosDaParede(p, ocupadas, minimo: 5 * u),
  );
}

/// A geladeira retrô vermelha (cantos redondos, puxadores cromados, a lista de compras e um desenho presos por ímãs).
void _geladeiraRetro(_Pincel p, double l, double larg) {
  final u = p.u;
  final r = Rect.fromLTRB(l, 12 * u, l + larg, p.hz);
  final corpo = Path()..addRRect(RRect.fromRectAndRadius(r, Radius.circular(2.2 * u)));
  p.forma(corpo, const Color(0xFFD9473F), contorno: 1);
  p.sombra(corpo, Rect.fromLTRB(r.right - larg * .22, r.top, r.right, r.bottom), alfa: .16);
  p.c.drawRect(Rect.fromLTRB(r.left + larg * .12, r.top + 1.2 * u, r.left + larg * .2, r.top + r.height * .3),
      Paint()..color = const Color(0x40FFFFFF));
  final corte = r.top + r.height * .36;
  p.c.drawLine(Offset(r.left, corte), Offset(r.right, corte), p.traco(.6));
  p.tubos([
    Path()
      ..moveTo(r.right - 1.6 * u, corte - 6 * u)
      ..lineTo(r.right - 1.6 * u, corte - 2 * u),
    Path()
      ..moveTo(r.right - 1.6 * u, corte + 2 * u)
      ..lineTo(r.right - 1.6 * u, corte + 8 * u),
  ], .6 * u, const Color(0xFFDDE3EA), contorno: .4);
  // a lista (papel pautado) e o desenho de criança
  final lista = Rect.fromLTWH(r.left + larg * .14, corte + 3 * u, larg * .42, larg * .55);
  p.ret(lista, _branco, contorno: .35);
  for (var i = 0; i < 4; i++) {
    final y = lista.top + lista.height * (.25 + i * .18);
    p.c.drawLine(Offset(lista.left + lista.width * .14, y), Offset(lista.right - lista.width * (.15 + .2 * _ruido(i + 950)), y),
        Paint()
          ..color = const Color(0x803A2A33)
          ..strokeWidth = math.max(.6, .16 * u));
  }
  p.circ(Offset(lista.center.dx, lista.top), .55 * u, const Color(0xFF3E8AE0), contorno: .25);
  final des = Rect.fromLTWH(r.left + larg * .3, r.top + 3 * u, larg * .4, larg * .36);
  p.ret(des, const Color(0xFFFFF4D6), contorno: .3);
  p.c.drawCircle(Offset(des.left + des.width * .7, des.top + des.height * .3), des.height * .16, p.tinta(const Color(0xFFFFC928)));
  p.c.drawRect(Rect.fromLTRB(des.left, des.bottom - des.height * .25, des.right, des.bottom), p.tinta(const Color(0xFF7CC160)));
  p.circ(Offset(des.left + .6 * u, des.top + .5 * u), .5 * u, const Color(0xFFFFC928), contorno: .2);
  // os pés
  for (final f in [.2, .8]) {
    p.ret(Rect.fromLTRB(r.left + larg * f - .6 * u, p.hz - .8 * u, r.left + larg * f + .6 * u, p.hz), const Color(0xFF8D99A8), contorno: .3);
  }
}

/// O fogão de [x]: o forno com a porta de vidro (acesa à noite), os botões, a panela fumegando, a frigideira e a coifa.
void _fogaoComCoifa(_Pincel p, double x) {
  final u = p.u;
  final bancada = p.hz - 10 * u;
  // a coifa de inox com a chaminé
  p.ret(Rect.fromLTRB(x - 2.2 * u, -2, x + 2.2 * u, 14 * u), const Color(0xFFB8C0CA), contorno: .7);
  p.forma(
      _poligono([Offset(x - 2.6 * u, 14 * u), Offset(x + 2.6 * u, 14 * u), Offset(x + 8 * u, 21 * u), Offset(x - 8 * u, 21 * u)]),
      const Color(0xFFC9D0D8),
      contorno: .8);
  p.ret(Rect.fromLTRB(x - 8.4 * u, 21 * u, x + 8.4 * u, 22.4 * u), const Color(0xFF8D99A8), contorno: .6);
  if (p.acesas) p.brilho(Offset(x, 24 * u), 8 * u, const Color(0xFFFFE6A8), alfa: .4);
  // a panela e a frigideira no fogo, com o vapor subindo
  final ox = x - 3 * u;
  for (var i = 0; i < 3; i++) {
    final fase = (p.t * .5 + i / 3) % 1;
    final y = bancada - 6 * u - fase * 9 * u;
    final dx = math.sin(fase * 6 + i) * 1.2 * u;
    p.c.drawCircle(Offset(ox + dx + (i - 1) * .9 * u, y), (1 + fase * 1.4) * u, Paint()..color = Color.fromRGBO(255, 255, 255, .55 * (1 - fase)));
  }
  p.ret(Rect.fromLTRB(ox - 3.2 * u, bancada - 5 * u, ox + 3.2 * u, bancada - .2 * u), const Color(0xFF3E8AE0), contorno: .7, raio: .6 * u);
  p.ret(Rect.fromLTRB(ox - 3.6 * u, bancada - 5.6 * u, ox + 3.6 * u, bancada - 4.6 * u), const Color(0xFF2F6FB8), contorno: .5, raio: .4 * u);
  for (final lado in [-1.0, 1.0]) {
    p.ret(Rect.fromLTRB(ox + lado * 3.2 * u - (lado < 0 ? 1.2 : 0) * u, bancada - 4.2 * u, ox + lado * 3.2 * u + (lado > 0 ? 1.2 : 0) * u,
        bancada - 3.4 * u), const Color(0xFF2F6FB8), contorno: .3);
  }
  p.ret(Rect.fromLTRB(x + 1.6 * u, bancada - 1.6 * u, x + 6 * u, bancada - .2 * u), const Color(0xFF3A3F4B), contorno: .5, raio: .5 * u);
  p.tubos([
    Path()
      ..moveTo(x + 6 * u, bancada - 1 * u)
      ..lineTo(x + 9.4 * u, bancada - 1.4 * u)
  ], .5 * u, const Color(0xFF3A3F4B), contorno: .35);
  // o fogão: tampo, painel com os botões e o forno
  final corpo = Rect.fromLTRB(x - 7 * u, bancada, x + 7 * u, p.hz);
  p.ret(corpo, const Color(0xFFF4F6F7), contorno: .9, raio: .4 * u);
  p.ret(Rect.fromLTRB(x - 7.4 * u, bancada - .4 * u, x + 7.4 * u, bancada + .8 * u), const Color(0xFF3A3F4B), contorno: .6);
  for (var i = 0; i < 4; i++) {
    p.circ(Offset(x - 4.5 * u + i * 3 * u, bancada + 2.2 * u), .65 * u, const Color(0xFF3A3F4B), contorno: .3);
  }
  final forno = Rect.fromLTRB(x - 5.6 * u, bancada + 4 * u, x + 5.6 * u, p.hz - 1.4 * u);
  p.ret(forno, p.acesas ? const Color(0xFFE8A64A) : const Color(0xFF2B2F3A), contorno: .6, raio: .6 * u, emite: p.acesas);
  if (p.acesas) p.brilho(forno.center, 6 * u, const Color(0xFFFFB347), alfa: .35);
  p.tubos([
    Path()
      ..moveTo(forno.left + 1 * u, forno.top - 1.1 * u)
      ..lineTo(forno.right - 1 * u, forno.top - 1.1 * u)
  ], .45 * u, const Color(0xFFB8C0CA), contorno: .3);
}

/// A pia de inox com a torneira, o escorredor e o pano de prato.
void _pia(_Pincel p, double x) {
  final u = p.u;
  final bancada = p.hz - 10 * u;
  p.tubos([
    Path()
      ..moveTo(x, bancada)
      ..lineTo(x, bancada - 4.4 * u)
      ..quadraticBezierTo(x, bancada - 6 * u, x + 1.8 * u, bancada - 6 * u)
      ..lineTo(x + 2.6 * u, bancada - 5 * u),
  ], .55 * u, const Color(0xFFB8C0CA), contorno: .4);
  // o escorredor com dois pratos e um copo
  final ex = x - 7 * u;
  for (var i = 0; i < 2; i++) {
    p.c.drawOval(Rect.fromLTWH(ex + i * 1.6 * u, bancada - 5 * u, 1.2 * u, 4.6 * u), p.tinta(_branco));
    p.c.drawOval(Rect.fromLTWH(ex + i * 1.6 * u, bancada - 5 * u, 1.2 * u, 4.6 * u), p.traco(.35));
  }
  p.ret(Rect.fromLTRB(ex + 3.4 * u, bancada - 3 * u, ex + 4.8 * u, bancada - .3 * u), const Color(0xFFCDEBF7), contorno: .35, alfa: .9);
  p.ret(Rect.fromLTRB(ex - .6 * u, bancada - .6 * u, ex + 5.6 * u, bancada), const Color(0xFF8D99A8), contorno: .4);
}

/// Prateleira aberta com potes de vidro (macarrão, feijão, café) e uma planta pendente.
void _prateleiraDePotes(_Pincel p, double l, double r, double y) {
  final u = p.u;
  const recheios = [Color(0xFFF2D27A), Color(0xFF7A4A2E), Color(0xFFE8E2D6), Color(0xFFD9473F), Color(0xFF6B4A32)];
  var x = l + .8 * u;
  var k = 0;
  while (x + 2.6 * u < r - .6 * u) {
    final alt = (3 + 1.4 * _ruido(k + 960)) * u;
    final pote = Rect.fromLTRB(x, y - alt, x + 2.4 * u, y);
    p.ret(pote, const Color(0xFFE6F4FF), contorno: .4, raio: .4 * u, alfa: .85);
    p.c.drawRect(Rect.fromLTRB(pote.left + .3 * u, pote.top + alt * .35, pote.right - .3 * u, pote.bottom - .3 * u),
        p.tinta(recheios[k % recheios.length]));
    p.ret(Rect.fromLTRB(pote.left - .1 * u, pote.top - .7 * u, pote.right + .1 * u, pote.top), const Color(0xFFB07C50), contorno: .3);
    x += 3.2 * u;
    k++;
  }
  p.ret(Rect.fromLTRB(l, y, r, y + .9 * u), const Color(0xFFA6784F), contorno: .5);
}

/// O calendário de parede (a folha do mês, com um dia marcado de vermelho).
void _calendario(_Pincel p, double x, double y) {
  final u = p.u;
  final r = Rect.fromLTWH(x - 3.4 * u, y, 6.8 * u, 8 * u);
  p.ret(r, _branco, contorno: .5);
  p.ret(Rect.fromLTRB(r.left, r.top, r.right, r.top + 2 * u), const Color(0xFFE5533D), contorno: .4);
  final ponto = p.tinta(const Color(0xFF8D99A8));
  for (var i = 0; i < 4; i++) {
    for (var j = 0; j < 5; j++) {
      p.c.drawRect(Rect.fromLTWH(r.left + (.6 + j * 1.2) * u, r.top + (2.8 + i * 1.2) * u, .7 * u, .6 * u), ponto);
    }
  }
  p.c.drawCircle(Offset(r.left + 3.3 * u, r.top + 4.4 * u), .8 * u, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(.8, .22 * u)
    ..color = const Color(0xFFE53935));
  p.circ(Offset(x, y - .2 * u), .4 * u, const Color(0xFF3A4152), contorno: .2);
}

/// A porta da despensa (de madeira clara, com a janelinha de veneziana).
void _despensa(_Pincel p, double x) {
  final u = p.u;
  final folha = Rect.fromLTRB(x - 6 * u, 15 * u, x + 6 * u, p.hz);
  p.ret(folha.inflate(.9 * u), const Color(0xFFF4F1EA), contorno: .7);
  p.ret(folha, const Color(0xFFD8B27E), contorno: .8);
  final ven = Rect.fromLTRB(folha.left + 1.6 * u, folha.top + 2 * u, folha.right - 1.6 * u, folha.top + 14 * u);
  p.ret(ven, const Color(0xFFC89B6C), contorno: .5);
  for (var y = ven.top + 1.4 * u; y < ven.bottom; y += 1.4 * u) {
    p.c.drawLine(Offset(ven.left, y), Offset(ven.right, y), p.traco(.25));
  }
  p.ret(Rect.fromLTRB(folha.left + 1.6 * u, folha.top + 17 * u, folha.right - 1.6 * u, folha.bottom - 2 * u), const Color(0xFFC89B6C),
      contorno: .45, raio: .3 * u);
  p.circ(Offset(folha.right - 1.6 * u, folha.top + 16 * u), .6 * u, const Color(0xFFE9B949), contorno: .3);
}

void _dCozinha(_Pincel p) {
  final u = p.u;
  final s = _plantaDaCozinha(p);
  // lá fora: o quintal com a cerca e uma árvore
  _Onda(p, p.hz - 24 * u, 3 * u, const [(1.1, 1.0, .3), (2.7, .4, 1.1)]).pinta(const Color(0xFF8CC47A), fundo: p.hz, contorno: .3);
  p.laco(s.xj - s.jMeia * .3, 6 * u, (x) => _arvore(p, x, p.hz - 22 * u, 16 * u, copa: _verdeArvore));
  final janelas = <RRect>[];
  p.laco(s.xj, s.jMeia + u,
      (x) => janelas.add(RRect.fromLTRBR(x - s.jMeia, 12 * u, x + s.jMeia, p.hz - 24 * u, Radius.circular(.8 * u))));
  _parede(p, const Color(0xFFF6E2A6), janelas);
  for (final j in janelas) {
    _moldura(p, j, _branco);
    final r = j.outerRect;
    // a cortininha de café (meia janela) e o peitoril com o manjericão
    p.c.save();
    p.c.clipRect(Rect.fromLTRB(r.left, r.center.dy, r.right, r.bottom));
    final pano = Path()..moveTo(r.left - u, r.center.dy);
    pano.lineTo(r.right + u, r.center.dy);
    pano.lineTo(r.right + u, r.bottom - 1.6 * u);
    final ondas = math.max(2, (r.width / (3 * u)).round());
    for (var i = ondas; i > 0; i--) {
      final xa = r.left + r.width * i / ondas, xb = r.left + r.width * (i - 1) / ondas;
      pano.quadraticBezierTo((xa + xb) / 2, r.bottom + .4 * u, xb, r.bottom - 1.6 * u);
    }
    pano.close();
    p.forma(pano, const Color(0xFFFFFFFF), contorno: .5);
    p.c.save();
    p.c.clipPath(pano);
    for (var x = r.left; x < r.right; x += 1.6 * u) {
      p.c.drawRect(Rect.fromLTWH(x, r.center.dy, .8 * u, r.height), p.tinta(const Color(0xFFE5533D), alfa: .55));
    }
    p.c.restore();
    p.c.restore();
    p.tubos([
      Path()
        ..moveTo(r.left - 1 * u, r.center.dy)
        ..lineTo(r.right + 1 * u, r.center.dy)
    ], .4 * u, const Color(0xFF8A5A3A), contorno: .3);
    p.ret(Rect.fromLTRB(r.left - 1.2 * u, r.bottom + .6 * u, r.right + 1.2 * u, r.bottom + 1.8 * u), _branco, contorno: .5);
    _planta(p, r.right - 3 * u, r.bottom + .6 * u, 4.4 * u, vaso: const Color(0xFFE07B39), semente: 31);
  }
  p.faixa(-2, 2.4 * u, const Color(0xFFFBF7EC), contorno: .5);
  // azulejo branco atrás da bancada, armários azul-marinho embaixo e o tampo de madeira
  final bancada = p.hz - 10 * u;
  final l0 = s.gl + s.gw;
  p.laco((l0 + s.fim) / 2, (s.fim - l0) / 2 + u, (c) {
    final l = c - (s.fim - l0) / 2, r = c + (s.fim - l0) / 2;
    final az = Rect.fromLTRB(l, bancada - 9 * u, r, bancada);
    p.c.drawRect(az, p.tinta(const Color(0xFFF7F9FA)));
    final rej = Paint()
      ..color = p.luz(const Color(0xFFD5DCE0))
      ..strokeWidth = math.max(.6, .15 * u);
    for (var y = az.top; y < az.bottom; y += 2.2 * u) {
      p.c.drawLine(Offset(az.left, y), Offset(az.right, y), rej);
    }
    for (var x = az.left; x < az.right; x += 2.2 * u) {
      p.c.drawLine(Offset(x, az.top), Offset(x, az.bottom), rej);
    }
    p.c.drawLine(Offset(az.left, az.top), Offset(az.right, az.top), p.traco(.4));
    p.ret(Rect.fromLTRB(l, bancada, r + .4 * u, bancada + 1.4 * u), const Color(0xFFC8955A), contorno: .7);
    final baixo = Rect.fromLTRB(l + .3 * u, bancada + 1.4 * u, r, p.hz);
    p.ret(baixo, const Color(0xFF2F4B7C), contorno: .7);
    final n = math.max(1, (baixo.width / (6 * u)).round());
    for (var i = 0; i < n; i++) {
      final a = baixo.left + baixo.width * i / n, b = baixo.left + baixo.width * (i + 1) / n;
      if (i > 0) p.c.drawLine(Offset(a, baixo.top), Offset(a, baixo.bottom), p.traco(.4));
      p.circ(Offset((a + b) / 2, baixo.top + 1.6 * u), .45 * u, const Color(0xFFE9B949), contorno: .25);
    }
  });
  p.laco(s.xj, 9 * u, (x) => _pia(p, x));
  // a prateleira de potes e o porta-temperos entre a pia e o fogão (se couber), e depois do fogão
  final l1 = s.xj + s.jMeia + 2 * u, r1 = s.xf - 9.5 * u;
  if (r1 - l1 > 6 * u) p.laco((l1 + r1) / 2, (r1 - l1) / 2, (c) => _prateleiraDePotes(p, c - (r1 - l1) / 2, c + (r1 - l1) / 2, 30 * u));
  final l2 = s.xf + 9.5 * u, r2 = s.fim - 1 * u;
  if (r2 - l2 > 6 * u) {
    p.laco((l2 + r2) / 2, (r2 - l2) / 2, (c) {
      _prateleiraDePotes(p, c - (r2 - l2) / 2, c + (r2 - l2) / 2, 26 * u);
      // a fruteira na bancada
      for (final (dx, cor) in [(-1.2, const Color(0xFFF2A541)), (0.0, const Color(0xFFE5533D)), (1.2, const Color(0xFF7CC160))]) {
        p.circ(Offset(c + dx * u, bancada - 2.2 * u - (dx == 0 ? .8 * u : 0)), 1.05 * u, cor, contorno: .4);
      }
      p.forma(
          Path()
            ..moveTo(c - 2.8 * u, bancada - 2 * u)
            ..lineTo(c + 2.8 * u, bancada - 2 * u)
            ..quadraticBezierTo(c + 2.4 * u, bancada, c, bancada)
            ..quadraticBezierTo(c - 2.4 * u, bancada, c - 2.8 * u, bancada - 2 * u)
            ..close(),
          const Color(0xFFF4F1EA),
          contorno: .5);
    });
  }
  p.laco(s.xf, 9 * u, (x) => _fogaoComCoifa(p, x));
  p.laco(s.gl + s.gw / 2, s.gw / 2 + u, (c) => _geladeiraRetro(p, c - s.gw / 2, s.gw));
  final d = s.despensa;
  if (d != null) p.laco(d, 8 * u, (x) => _despensa(p, x));
  var k = 0;
  for (final (x0, meia) in s.vaos) {
    p.laco(x0, 5 * u, (x) {
      if (k == 0) {
        _calendario(p, x, 17 * u);
        _relogioDeParede(p, Offset(x, 11 * u), 2.4 * u);
      } else {
        _quadroDePaisagem(p, Rect.fromCenter(center: Offset(x, 20 * u), width: math.min(8 * u, meia), height: 6 * u), k);
      }
    });
    k++;
  }
  if (s.vaos.isEmpty) p.laco(s.xj, 3 * u, (x) => _relogioDeParede(p, Offset(x, 6.6 * u), 2.2 * u));
  p.faixa(p.hz - .8 * u, p.hz, const Color(0xFF2F4B7C), contorno: .4);
}

void _cCozinha(_Pincel p) {
  final u = p.u;
  // piso xadrez preto e branco (com o fundo chapado por baixo: as emendas não vazam)
  p.solo(const [Color(0xFFE9E6DF), Color(0xFFE9E6DF)], contorno: 0);
  const linhas = 6;
  final altura = p.h - p.hz;
  var y = p.hz;
  final cols = p.vezesPar(5 * u);
  for (var l = 0; l < linhas; l++) {
    final hL = altura * (l + 1) / (linhas * (linhas + 1) / 2);
    for (var c = 0; c < cols; c++) {
      if ((c + l).isOdd) p.c.drawRect(Rect.fromLTWH(c * p.w / cols, y, p.w / cols + .5, hL + .5), p.tinta(const Color(0xFF3A4152)));
    }
    y += hL;
  }
  p.c.drawLine(Offset(-2, p.hz), Offset(p.w + 2, p.hz), p.traco(.5));
  final s = _plantaDaCozinha(p);
  // o tapetinho na frente da pia e a tigela do gato perto da geladeira
  p.laco(s.xj, 8 * u, (x) {
    final t = RRect.fromLTRBR(x - 7 * u, p.hz + 2 * u, x + 7 * u, p.hz + 6 * u, Radius.circular(2 * u));
    p.c.drawRRect(t, p.tinta(const Color(0xFF6FA8A0)));
    p.c.drawRRect(t, p.traco(.4));
  });
  p.laco(s.gl + s.gw + 3 * u, 2 * u, (x) {
    p.forma(
        Path()
          ..moveTo(x - 1.8 * u, p.hz + 3 * u)
          ..lineTo(x + 1.8 * u, p.hz + 3 * u)
          ..lineTo(x + 1.3 * u, p.hz + 4.6 * u)
          ..lineTo(x - 1.3 * u, p.hz + 4.6 * u)
          ..close(),
        const Color(0xFFE5533D),
        contorno: .4);
  });
  final m = s.mesa;
  if (m != null) p.laco(m, 11 * u, (x) => _mesaDeJantar(p, x, p.hz + 7 * u));
}

// ─────────────────────────── quintal (o quintal com churrasqueira: o churrasco de domingo) ───────────────────────────
//
// Exterior (o céu e o clima de fora valem). Os fundos da casa à esquerda (parede de tábuas, a porta de vidro, a janela
// e a arandela, com o deque de madeira), a cerca alta de tábuas, a árvore grande à direita e o varal de lampadinhas
// (acesas à tarde e à noite) da casa até a árvore. A churrasqueira de tijolinho, com a fumaça subindo e as brasas,
// fica no meio (onde quase nunca há alguém); na tela larga, a mesa de piquenique com a toalha xadrez e o cooler.

typedef _PlantaQuintal = ({
  double cw, // largura da casa (de 0 até cw)
  double xg, // a churrasqueira
  double xa, // a árvore
  double? mesa,
});

_PlantaQuintal _plantaDoQuintal(_Pincel p) {
  final u = p.u, w = p.w;
  if (w < 70 * u) return (cw: w * .2, xg: w * .52, xa: w * .86, mesa: null);
  final cw = math.min(w * .2, 34 * u);
  // a árvore (copa de ~17u de raio) inteira dentro da tela
  return (cw: cw, xg: w * .5, xa: w - math.max(w * .1, 19 * u), mesa: w >= 110 * u ? w * .8 : null);
}

/// Os fundos da casa (de 0 até [cw]): tábuas azul-claras, o beiral, a porta de vidro de correr e a arandela.
void _fundosDaCasa(_Pincel p, double cw) {
  final u = p.u;
  final r = Rect.fromLTRB(-2, 14 * u, cw, p.hz);
  p.c.drawRect(r, p.tinta(const Color(0xFFB9D3E3)));
  final tabua = p.traco(.22);
  for (var y = r.top + 2 * u; y < r.bottom; y += 2 * u) {
    p.c.drawLine(Offset(r.left, y), Offset(r.right, y), tabua);
  }
  p.c.drawLine(Offset(r.right, r.top), Offset(r.right, r.bottom), p.traco(.8));
  // o beiral do telhado
  p.forma(_poligono([Offset(-2, 8 * u), Offset(cw + 1 * u, 8 * u), Offset(cw + 3 * u, 14.6 * u), Offset(-2, 14.6 * u)]),
      const Color(0xFF8A4A3A), contorno: .8);
  p.ret(Rect.fromLTRB(-2, 14.6 * u, cw + 3 * u, 15.6 * u), _branco, contorno: .5);
  // a porta de vidro (luz de dentro à noite) e a janela
  final porta = Rect.fromLTRB(cw * .48, 24 * u, cw * .48 + math.min(14 * u, cw * .44), p.hz);
  p.ret(porta.inflate(.9 * u), _branco, contorno: .7);
  p.ret(porta, p.acesas ? const Color(0xFFFFE3A0) : const Color(0xFF9FC8E0), contorno: .6, emite: p.acesas);
  p.c.drawLine(Offset(porta.center.dx, porta.top), Offset(porta.center.dx, porta.bottom), p.traco(.6));
  p.c.drawRect(Rect.fromLTRB(porta.left + 1 * u, porta.top + 1 * u, porta.left + 2 * u, porta.bottom - 2 * u),
      Paint()..color = const Color(0x40FFFFFF));
  if (cw > 22 * u) {
    final jan = Rect.fromLTRB(cw * .1, 22 * u, cw * .1 + math.min(8 * u, cw * .3), 32 * u);
    p.ret(jan.inflate(.8 * u), _branco, contorno: .6);
    p.ret(jan, p.acesas ? const Color(0xFFFFE3A0) : const Color(0xFF9FC8E0), contorno: .4, emite: p.acesas);
    p.c.drawLine(Offset(jan.center.dx, jan.top), Offset(jan.center.dx, jan.bottom), p.traco(.4));
  }
  // a arandela ao lado da porta
  final ar = Offset(porta.right + 2.4 * u, 26 * u);
  if (p.acesas) p.brilho(ar, 9 * u, const Color(0xFFFFD08A), alfa: .5);
  p.ret(Rect.fromCenter(center: ar, width: 1.8 * u, height: 2.6 * u), p.acesas ? const Color(0xFFFFE08A) : const Color(0xFFF2EEE2),
      contorno: .5, raio: .5 * u, emite: p.acesas);
}

/// A cerca alta de tábuas, de [l] até [r] (ripas de alturas um pouco diferentes, com a travessa).
void _cercaDeTabuas(_Pincel p, double l, double r) {
  final u = p.u;
  final topo = p.hz - 16 * u;
  final n = math.max(1, ((r - l) / (3 * u)).round());
  final passo = (r - l) / n;
  for (var i = 0; i < n; i++) {
    final x = l + i * passo;
    final alt = topo - (_ruido(i * 3 + 980) * .8) * u;
    p.forma(_poligono([Offset(x, p.hz), Offset(x, alt + .8 * u), Offset(x + passo / 2, alt), Offset(x + passo, alt + .8 * u), Offset(x + passo, p.hz)]),
        i.isEven ? const Color(0xFFC9935E) : const Color(0xFFBF8A55),
        contorno: .45);
  }
  p.ret(Rect.fromLTRB(l, topo + 3 * u, r, topo + 4.2 * u), const Color(0xFFA9773F), contorno: .4);
}

/// A churrasqueira de tijolinho: a boca com a grelha, as linguiças e a carne, as brasas e a chaminé com a fumaça.
void _churrasqueira(_Pincel p, double x, double base) {
  final u = p.u;
  const tijolo = Color(0xFFC8643F);
  final rejunte = Paint()
    ..color = p.luz(const Color(0xFFE8C7A8))
    ..strokeWidth = math.max(.6, .18 * u);
  void tijolos(Rect r) {
    p.ret(r, tijolo, contorno: .8);
    var fila = 0;
    for (var y = r.top + 1.5 * u; y < r.bottom; y += 1.5 * u, fila++) {
      p.c.drawLine(Offset(r.left, y), Offset(r.right, y), rejunte);
      for (var xx = r.left + (fila.isOdd ? 1.6 * u : 0); xx < r.right; xx += 3.2 * u) {
        p.c.drawLine(Offset(xx, y), Offset(xx, math.min(y + 1.5 * u, r.bottom)), rejunte);
      }
    }
  }

  // a fumaça subindo da chaminé
  for (var i = 0; i < 4; i++) {
    final fase = (p.t * .35 + i / 4) % 1;
    final y = base - 40 * u - fase * 16 * u;
    p.c.drawCircle(Offset(x + 1 * u + math.sin(fase * 5 + i) * 1.6 * u + fase * 3 * u, y), (1.4 + fase * 2.6) * u,
        Paint()..color = Color.fromRGBO(235, 235, 240, .6 * (1 - fase)));
  }
  tijolos(Rect.fromLTRB(x - 2.6 * u, base - 40 * u, x + 2.6 * u, base - 26 * u));
  p.ret(Rect.fromLTRB(x - 3.4 * u, base - 41 * u, x + 3.4 * u, base - 39.6 * u), const Color(0xFF8A4A3A), contorno: .5);
  // o capelo
  p.forma(_poligono([Offset(x - 2.6 * u, base - 26 * u), Offset(x + 2.6 * u, base - 26 * u), Offset(x + 10 * u, base - 19 * u),
    Offset(x - 10 * u, base - 19 * u)]), tijolo, contorno: .8);
  // o corpo com a boca
  final corpo = Rect.fromLTRB(x - 10 * u, base - 19 * u, x + 10 * u, base);
  tijolos(corpo);
  final boca = Rect.fromLTRB(x - 7.6 * u, base - 16.4 * u, x + 7.6 * u, base - 9 * u);
  p.ret(boca, const Color(0xFF2B1E1A), contorno: .7, raio: .4 * u);
  // as brasas (brilham mais à noite)
  for (var i = 0; i < 7; i++) {
    final bx = boca.left + 1.2 * u + i * 2 * u;
    final pisca = .6 + .4 * math.sin(p.t * 3 + i * 1.7);
    p.c.drawCircle(Offset(bx, boca.bottom - .9 * u), .9 * u, Paint()..color = Color.lerp(const Color(0xFFB8432A), const Color(0xFFFFB238), pisca)!);
  }
  p.brilho(Offset(x, boca.bottom - 1 * u), (p.acesas ? 12 : 6) * u, const Color(0xFFFF8A3D), alfa: p.acesas ? .55 : .3);
  // a grelha com as linguiças e a picanha
  final gy = boca.top + 3.4 * u;
  p.c.drawLine(Offset(boca.left, gy), Offset(boca.right, gy), Paint()
    ..strokeWidth = math.max(1.0, .3 * u)
    ..color = p.luz(const Color(0xFF8D99A8)));
  for (var i = 0; i < 3; i++) {
    p.ret(Rect.fromLTRB(boca.left + 1 * u + i * 2.4 * u, gy - 1.3 * u, boca.left + 3 * u + i * 2.4 * u, gy), const Color(0xFFA8432E),
        contorno: .3, raio: .6 * u);
  }
  p.forma(
      Path()
        ..moveTo(x + 1 * u, gy)
        ..quadraticBezierTo(x + 1.4 * u, gy - 2.4 * u, x + 4.2 * u, gy - 2.2 * u)
        ..quadraticBezierTo(x + 6.6 * u, gy - 2 * u, x + 6.6 * u, gy)
        ..close(),
      const Color(0xFF9A4A35),
      contorno: .4);
  p.c.drawLine(Offset(x + 1.6 * u, gy - 1.4 * u), Offset(x + 6.2 * u, gy - 1.6 * u), Paint()
    ..strokeWidth = math.max(.8, .35 * u)
    ..color = p.luz(const Color(0xFFF2E6D2)));
  // a bancada de granito em cima da gaveta de lenha
  p.ret(Rect.fromLTRB(x - 11 * u, base - 8.6 * u, x + 11 * u, base - 7.4 * u), const Color(0xFF5E5A57), contorno: .6);
  final lenha = Rect.fromLTRB(x - 7.6 * u, base - 6.4 * u, x + 7.6 * u, base - 1 * u);
  p.ret(lenha, const Color(0xFF3A2A22), contorno: .5);
  for (var i = 0; i < 5; i++) {
    p.circ(Offset(lenha.left + 1.6 * u + i * 3 * u, lenha.center.dy + (i.isOdd ? .8 : -.6) * u), 1.2 * u, const Color(0xFFB07C50),
        contorno: .3);
  }
}

/// O varal de lampadinhas de [a] até [b] (uma curva só, caindo no meio), na altura [y].
void _varalEntre(_Pincel p, Offset a, Offset b, double queda) {
  final u = p.u;
  final ctrl = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + queda * 2);
  p.c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, b.dx, b.dy),
      p.traco(.3));
  const cores = [Color(0xFFFFD27F), Color(0xFFFF9E6B), Color(0xFFFFF0B3), Color(0xFF9FE0C8)];
  final n = math.max(3, ((b.dx - a.dx) / (5 * u)).round());
  for (var k = 1; k < n; k++) {
    final s = k / n;
    final pt = Offset((1 - s) * (1 - s) * a.dx + 2 * (1 - s) * s * ctrl.dx + s * s * b.dx,
        (1 - s) * (1 - s) * a.dy + 2 * (1 - s) * s * ctrl.dy + s * s * b.dy);
    final cor = cores[k % cores.length];
    final o = pt.translate(0, .9 * u);
    if (p.acesas) p.brilho(o, 2.6 * u, cor, alfa: .6);
    p.c.drawOval(Rect.fromCenter(center: o, width: 1 * u, height: 1.4 * u),
        p.acesas ? (Paint()..color = cor) : p.tinta(Color.lerp(cor, _branco, .4)!));
  }
}

void _dQuintal(_Pincel p) {
  final u = p.u;
  final s = _plantaDoQuintal(p);
  // lá longe: os telhados dos vizinhos e as copas atrás da cerca
  final n = p.vezes(22 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) * p.w / n;
    final alt = (6 + 3 * _ruido(i + 990)) * u;
    p.laco(x, 8 * u, (x) {
      p.ret(Rect.fromLTRB(x - 7 * u, p.hz - 15 * u - alt, x + 7 * u, p.hz - 14 * u), const Color(0xFFE6D4BE), contorno: .4);
      p.forma(_poligono([Offset(x - 8.4 * u, p.hz - 15 * u - alt), Offset(x, p.hz - 20 * u - alt), Offset(x + 8.4 * u, p.hz - 15 * u - alt)]),
          const Color(0xFFA85A44), contorno: .5);
    });
    p.laco(x + p.w / n * .5, 5 * u, (x) => _arvore(p, x, p.hz - 13 * u, 13 * u, copa: _verdePinheiro, contorno: .6));
  }
  // a árvore grande do quintal, a cerca e os fundos da casa
  p.laco(s.xa, 16 * u, (x) {
    p.ret(Rect.fromLTRB(x - 1.8 * u, p.hz - 30 * u, x + 1.8 * u, p.hz), _tronco, contorno: 1);
    p.blob([
      Rect.fromCircle(center: Offset(x, 18 * u), radius: 12 * u),
      Rect.fromCircle(center: Offset(x - 9 * u, 25 * u), radius: 8 * u),
      Rect.fromCircle(center: Offset(x + 9 * u, 25 * u), radius: 8.5 * u),
      Rect.fromCircle(center: Offset(x, 29 * u), radius: 8 * u),
    ], _verdeArvore);
  });
  _cercaDeTabuas(p, s.cw, p.w + 1);
  _fundosDaCasa(p, s.cw);
  // o varal de lampadinhas: do beiral até a árvore
  _varalEntre(p, Offset(s.cw + 2 * u, 15 * u), Offset(s.xa - 6 * u, 22 * u), 2.4 * u);
}

void _cQuintal(_Pincel p) {
  final u = p.u;
  p.solo(const [Color(0xFF86C46E), Color(0xFF5E9E4E)]);
  final s = _plantaDoQuintal(p);
  // o canteiro de flores na frente da cerca
  _tufos(p, p.hz + .6 * u, p.hz + 3 * u, const Color(0xFF3E7A36), flores: true, semente: 77);
  // o deque de madeira na frente da casa
  final deque = Rect.fromLTRB(-2, p.hz, s.cw + 4 * u, p.hz + 7 * u);
  p.ret(deque, const Color(0xFFC08A5B), contorno: .7);
  for (var y = deque.top + 1.75 * u; y < deque.bottom; y += 1.75 * u) {
    p.c.drawLine(Offset(deque.left, y), Offset(deque.right, y), p.traco(.25));
  }
  // as pedras do caminho até a churrasqueira
  for (var i = 0; i < 4; i++) {
    final x = s.cw + 6 * u + i * (s.xg - s.cw - 14 * u) / 4;
    p.c.drawOval(Rect.fromCenter(center: Offset(x, p.hz + 6 * u + i * .6 * u), width: 4.4 * u, height: 1.8 * u), p.tinta(const Color(0xFFCFC8BC)));
    p.c.drawOval(Rect.fromCenter(center: Offset(x, p.hz + 6 * u + i * .6 * u), width: 4.4 * u, height: 1.8 * u), p.traco(.3));
  }
  _tufos(p, p.hz + 9 * u, p.h, const Color(0xFF4E8A42), semente: 13);
  p.laco(s.xg, 12 * u, (x) => _churrasqueira(p, x, p.hz + 6 * u));
  final m = s.mesa;
  if (m != null) {
    p.laco(m, 14 * u, (x) {
      // o cooler vermelho e a mesa de piquenique com os bancos
      p.ret(Rect.fromLTRB(x - 16 * u, p.hz + 4 * u, x - 10 * u, p.hz + 9 * u), const Color(0xFFE5533D), contorno: .6, raio: .6 * u);
      p.ret(Rect.fromLTRB(x - 16.4 * u, p.hz + 3.2 * u, x - 9.6 * u, p.hz + 4.4 * u), _branco, contorno: .5, raio: .4 * u);
      for (final dx in [-6.0, 6.0]) {
        p.tubos([
          Path()
            ..moveTo(x + dx * u - 2 * u, p.hz + 12 * u)
            ..lineTo(x + dx * u + 2 * u, p.hz + 3 * u),
          Path()
            ..moveTo(x + dx * u + 2 * u, p.hz + 12 * u)
            ..lineTo(x + dx * u - 2 * u, p.hz + 3 * u),
        ], .8 * u, const Color(0xFFA9773F), contorno: .4);
      }
      p.ret(Rect.fromLTRB(x - 11 * u, p.hz + 8 * u, x + 11 * u, p.hz + 9 * u), const Color(0xFFB98552), contorno: .5);
      final toalha = Rect.fromLTRB(x - 10 * u, p.hz + 1.6 * u, x + 10 * u, p.hz + 5 * u);
      p.ret(toalha, _branco, contorno: .7);
      p.c.save();
      p.c.clipRect(toalha);
      for (var i = 0; i < 14; i++) {
        p.c.drawRect(Rect.fromLTWH(toalha.left + i * 1.6 * u, toalha.top, .8 * u, toalha.height), p.tinta(const Color(0xFFE5533D), alfa: .55));
      }
      p.c.drawRect(Rect.fromLTRB(toalha.left, toalha.top + 1.2 * u, toalha.right, toalha.top + 2 * u), p.tinta(const Color(0xFFE5533D), alfa: .55));
      p.c.restore();
      // em cima: a travessa de pão de alho, a jarra de suco e os copos
      p.c.drawOval(Rect.fromCenter(center: Offset(x - 3 * u, p.hz + 1.4 * u), width: 6 * u, height: 1.4 * u), p.tinta(_branco));
      p.c.drawOval(Rect.fromCenter(center: Offset(x - 3 * u, p.hz + 1.4 * u), width: 6 * u, height: 1.4 * u), p.traco(.3));
      for (var i = 0; i < 3; i++) {
        p.ret(Rect.fromLTRB(x - 5.4 * u + i * 1.7 * u, p.hz - .2 * u, x - 4 * u + i * 1.7 * u, p.hz + 1 * u), const Color(0xFFE9B949),
            contorno: .3, raio: .4 * u);
      }
      p.ret(Rect.fromLTRB(x + 2 * u, p.hz - 3 * u, x + 4.4 * u, p.hz + 1.6 * u), const Color(0xFFF2A541), contorno: .5, raio: .6 * u, alfa: .9);
      p.ret(Rect.fromLTRB(x + 5.6 * u, p.hz - .8 * u, x + 6.8 * u, p.hz + 1.6 * u), const Color(0xFFCDEBF7), contorno: .35, alfa: .9);
    });
  }
}

// ─────────────────────────── bar (o happy hour: balcão, garrafas, o jogo na TV e o neon) ───────────────────────────
//
// A parede de tijolo aparente com o lambri escuro; no meio, a cristaleira das garrafas (com o espelho e a luz de baixo,
// acesa à tarde e à noite), o neon de uma taça e de uma estrela em cima e as duas TVs do jogo; o balcão com as
// torneiras de chope e as banquetas fica ENTRE as posições da dupla (quem conversa fica nas pontas, nas banquetas).
// A vitrine da frente à esquerda mostra a rua e a hora; na tela larga, o quadro de giz com os drinques, o alvo de
// dardos e as mesinhas altas nas pontas. Um cômodo só em qualquer largura.

typedef _PlantaBar = ({
  double xb, // o meio do balcão (e da cristaleira)
  double bMeia, // meia largura do balcão
  double xv, // a vitrine da rua
  double vMeia,
  List<(double, double)> vaos,
  bool larga,
});

_PlantaBar _plantaDoBar(_Pincel p) {
  final u = p.u, w = p.w;
  final retrato = p.h > w;
  // o balcão cabe entre quem está no centroEsquerda e no centroDireita (meia largura de ator ≈ 14u de cada lado)
  final bMeia = (w * (retrato ? .17 : .19) - 9 * u).clamp(6 * u, 26 * u).toDouble();
  if (w < 70 * u) return (xb: w * .5, bMeia: bMeia, xv: w * .12, vMeia: math.min(6 * u, w * .1), vaos: const [], larga: false);
  final (cMeia, tw) = _cristaleiraETv(p, bMeia);
  final (xv, vMeia) = _vitrineDoBar(p);
  return (
    xb: w * .5,
    bMeia: bMeia,
    xv: xv,
    vMeia: vMeia,
    vaos: _vaosDaParede(p, [(w * .5, cMeia + 2 * tw + 3 * u), (xv, vMeia + 2 * u)], minimo: 6 * u),
    larga: true,
  );
}

/// Meia largura da cristaleira e meia largura de cada TV (0 = não cabe) para o balcão de meia largura [bMeia].
(double, double) _cristaleiraETv(_Pincel p, double bMeia) {
  final u = p.u, w = p.w;
  final cMeia = math.max(bMeia + 2 * u, 9 * u);
  // no celular em pé não cabem as TVs ao lado do neon; no largo, cada TV cabe entre a vitrine e a cristaleira
  if (w < 70 * u) return (cMeia, 0.0);
  final (xv, vMeia) = _vitrineDoBar(p);
  final tw = math.min(9 * u, (w * .5 - cMeia - (xv + vMeia + 2 * u) - 1.5 * u) / 2);
  return (cMeia, tw >= 4 * u ? tw : 0.0);
}

/// O meio e a meia largura da vitrine da rua (na tela larga).
(double, double) _vitrineDoBar(_Pincel p) {
  final vMeia = math.min(13 * p.u, p.w * .09);
  return (math.max(vMeia + 3 * p.u, p.w * .14), vMeia);
}

/// A TV do bar passando o jogo (gramado, jogadores e o placar), presa na parede pelo suporte.
void _tvDoBar(_Pincel p, Rect tela) {
  final u = p.u;
  p.ret(Rect.fromLTRB(tela.center.dx - .5 * u, -2, tela.center.dx + .5 * u, tela.top), const Color(0xFF2B2E35), contorno: .3);
  p.ret(tela.inflate(.7 * u), const Color(0xFF1C1E24), contorno: .7, raio: .4 * u);
  p.brilho(tela.center, tela.width * .9, const Color(0xFF7FD0FF), alfa: p.acesas ? .2 : .1);
  p.c.save();
  p.c.clipRect(tela);
  p.c.drawRect(tela, Paint()..color = const Color(0xFF3FAE4F));
  final giz = Paint()
    ..color = const Color(0xE6FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, .25 * u);
  p.c.drawLine(Offset(tela.center.dx, tela.top), Offset(tela.center.dx, tela.bottom), giz);
  p.c.drawCircle(tela.center, tela.height * .22, giz);
  for (var i = 0; i < 6; i++) {
    final fx = .15 + .7 * _ruido(i + 1001 + tela.left.round()) + math.sin(p.t * .8 + i) * .03;
    p.c.drawCircle(Offset(tela.left + tela.width * fx, tela.top + tela.height * (.25 + .55 * _ruido(i + 1011))), math.max(1.0, .5 * u),
        Paint()..color = i.isEven ? const Color(0xFFF2C94C) : const Color(0xFF7B4FD6));
  }
  p.c.drawRect(Rect.fromLTWH(tela.left + .5 * u, tela.top + .5 * u, 5 * u, 1.6 * u), Paint()..color = const Color(0xE617202E));
  _digitos(p, '2:1', Offset(tela.left + 1.2 * u, tela.top + .75 * u), 1.1 * u, _branco);
  p.c.restore();
}

/// O neon em cima da cristaleira: uma taça de coquetel (rosa) e uma estrela (azul), que piscam de leve.
void _neonDoBar(_Pincel p, double x, double y) {
  final u = p.u;
  final liga = p.acesas || p.hora == HoraHistoria.amanhecer ? 1.0 : .75;
  final pisca = (p.t * .9) % 4 < 3.7 ? 1.0 : .55;
  Paint neon(Color c, double largura) => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = largura
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..color = c.withValues(alpha: liga * pisca);
  final taca = Path()
    ..moveTo(x - 6 * u, y - 4 * u)
    ..lineTo(x + 0 * u, y + 2 * u)
    ..lineTo(x + 6 * u, y - 4 * u)
    ..close()
    ..moveTo(x, y + 2 * u)
    ..lineTo(x, y + 6 * u)
    ..moveTo(x - 3 * u, y + 6 * u)
    ..lineTo(x + 3 * u, y + 6 * u);
  const rosa = Color(0xFFFF4FA3), azul = Color(0xFF4DD0E1);
  p.brilho(Offset(x, y), 12 * u, rosa, alfa: .35 * liga * pisca);
  p.c.drawPath(taca, neon(rosa.withValues(alpha: .4), 1.6 * u));
  p.c.drawPath(taca, neon(const Color(0xFFFFD1EA), .5 * u));
  p.c.drawCircle(Offset(x + 3.4 * u, y - 5.2 * u), 1.2 * u, neon(const Color(0xFFB8F5A0), .45 * u));
  for (final lado in [-1.0, 1.0]) {
    final c = Offset(x + lado * 12 * u, y);
    final estrela = Path();
    for (var i = 0; i < 10; i++) {
      final r = (i.isEven ? 3 : 1.3) * u;
      final a = -math.pi / 2 + i * math.pi / 5;
      final o = c + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? estrela.moveTo(o.dx, o.dy) : estrela.lineTo(o.dx, o.dy);
    }
    estrela.close();
    p.brilho(c, 6 * u, azul, alfa: .3 * liga * pisca);
    p.c.drawPath(estrela, neon(azul.withValues(alpha: .4), 1.3 * u));
    p.c.drawPath(estrela, neon(const Color(0xFFD7FAFF), .4 * u));
  }
}

/// A cristaleira atrás do balcão: o espelho, as prateleiras de garrafas (com a luz de baixo) e os copos.
void _cristaleira(_Pincel p, double x, double meia) {
  final u = p.u;
  final r = Rect.fromLTRB(x - meia, 22 * u, x + meia, p.hz);
  p.ret(r, const Color(0xFF4A2E22), contorno: 1);
  final espelho = Rect.fromLTRB(r.left + 1.2 * u, r.top + 1.2 * u, r.right - 1.2 * u, p.hz - 12 * u);
  p.ret(espelho, const Color(0xFF7D8FA0), contorno: .5);
  p.c.save();
  p.c.clipRect(espelho);
  for (final f in [.2, .7]) {
    p.c.drawPath(
        _poligono([
          Offset(espelho.left + espelho.width * f, espelho.top),
          Offset(espelho.left + espelho.width * f + 4 * u, espelho.top),
          Offset(espelho.left + espelho.width * f - 3 * u, espelho.bottom),
          Offset(espelho.left + espelho.width * f - 7 * u, espelho.bottom),
        ]),
        Paint()..color = const Color(0x30FFFFFF));
  }
  p.c.restore();
  const vidros = [Color(0xFF4E9A6A), Color(0xFFC77D3A), Color(0xFF7FB2C9), Color(0xFF9A3D4E), Color(0xFFE6C15A), Color(0xFF6A4FB5)];
  for (var s = 0; s < 2; s++) {
    final y = espelho.top + (s + 1) * espelho.height / 2 - .8 * u;
    if (p.acesas) {
      p.c.drawRect(Rect.fromLTRB(espelho.left, y - 6 * u, espelho.right, y),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [const Color(0x66FFC46B), const Color(0x00FFC46B)],
            ).createShader(Rect.fromLTRB(espelho.left, y - 6 * u, espelho.right, y)));
    }
    var bx = espelho.left + 1.4 * u;
    var k = 0;
    while (bx < espelho.right - 1.4 * u) {
      final cor = vidros[(k * 5 + s * 3) % vidros.length];
      final alta = (k + s).isEven;
      final hb = (alta ? 5.6 : 4.4) * u;
      p.forma(
          Path()
            ..addRRect(RRect.fromLTRBR(bx - .9 * u, y - hb * .72, bx + .9 * u, y, Radius.circular(.5 * u)))
            ..addRect(Rect.fromLTRB(bx - .35 * u, y - hb, bx + .35 * u, y - hb * .7)),
          cor,
          contorno: .4);
      p.c.drawRect(Rect.fromLTRB(bx - .9 * u, y - hb * .48, bx + .9 * u, y - hb * .3), p.tinta(const Color(0xFFF4ECD8)));
      bx += 2.6 * u;
      k++;
    }
    p.ret(Rect.fromLTRB(espelho.left - .4 * u, y, espelho.right + .4 * u, y + .8 * u), const Color(0xFF7A4E2E), contorno: .4);
  }
  // o gaveteiro de baixo
  final baixo = Rect.fromLTRB(r.left + 1.2 * u, p.hz - 11 * u, r.right - 1.2 * u, p.hz - 1 * u);
  p.ret(baixo, const Color(0xFF5E3A2A), contorno: .6);
  final n = math.max(2, (baixo.width / (7 * u)).round());
  for (var i = 1; i < n; i++) {
    p.c.drawLine(Offset(baixo.left + baixo.width * i / n, baixo.top), Offset(baixo.left + baixo.width * i / n, baixo.bottom), p.traco(.35));
  }
}

/// O alvo de dardos (com dois dardos espetados).
void _alvoDeDardos(_Pincel p, Offset o) {
  final u = p.u;
  p.circ(o, 4.2 * u, const Color(0xFF2B2E35), contorno: .7);
  for (var i = 0; i < 12; i++) {
    final a0 = i * math.pi / 6;
    p.c.drawArc(Rect.fromCircle(center: o, radius: 3.4 * u), a0, math.pi / 6, true,
        p.tinta(i.isEven ? const Color(0xFFF2E6D2) : const Color(0xFF2B2E35)));
  }
  p.c.drawCircle(o, 3.4 * u, Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = .5 * u
    ..color = p.luz(const Color(0xFFD9473F)));
  p.circ(o, .7 * u, const Color(0xFFD9473F), contorno: .3);
  for (final (dx, dy) in [(.8, -1.2), (-1.6, .6)]) {
    final ponta = o + Offset(dx * u, dy * u);
    p.c.drawLine(ponta, ponta + Offset(2 * u, -1.4 * u), Paint()
      ..strokeWidth = math.max(1.0, .35 * u)
      ..color = p.luz(const Color(0xFF8D99A8)));
    p.circ(ponta + Offset(2.2 * u, -1.5 * u), .5 * u, const Color(0xFF3E8AE0), contorno: .2);
  }
}

void _dBar(_Pincel p) {
  final u = p.u;
  final s = _plantaDoBar(p);
  // lá fora, pela vitrine: a calçada e a loja da frente
  p.laco(s.xv, s.vMeia + 1 * u, (x) {
    p.ret(Rect.fromLTRB(x - s.vMeia - 1 * u, 20 * u, x + s.vMeia + 1 * u, p.hz - 22 * u), const Color(0xFFB9C4D6), contorno: .4);
    p.ret(Rect.fromLTRB(x - s.vMeia - 1 * u, p.hz - 22 * u, x + s.vMeia + 1 * u, p.hz - 17 * u), const Color(0xFFBFBAB2), contorno: .4);
    for (var j = 0; j < 3; j++) {
      p.c.drawRect(Rect.fromLTWH(x - s.vMeia + (1 + j * 3.6) * u, 23 * u, 2.2 * u, 3 * u),
          p.noite ? (Paint()..color = const Color(0xFFFFD866)) : p.tinta(const Color(0xFF8FB7D4)));
    }
  });
  final janelas = <RRect>[];
  p.laco(s.xv, s.vMeia + u, (x) => janelas.add(RRect.fromLTRBR(x - s.vMeia, 10 * u, x + s.vMeia, p.hz - 18 * u, Radius.circular(.4 * u))));
  // a parede de tijolo aparente
  _parede(p, const Color(0xFF9E4A35), janelas);
  p.c.save();
  final semVitrine = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTRB(-2, -2, p.w + 2, p.hz));
  for (final j in janelas) {
    semVitrine.addRRect(j);
  }
  p.c.clipPath(semVitrine);
  final rej = Paint()
    ..color = p.luz(const Color(0xFF7E3A2A))
    ..strokeWidth = math.max(.7, .22 * u);
  var fila = 0;
  for (var y = 3 * u; y < p.hz - 16 * u; y += 2 * u, fila++) {
    p.c.drawLine(Offset(-2, y), Offset(p.w + 2, y), rej);
    final tij = p.vezes(4.6 * u);
    for (var t = 0; t < tij; t++) {
      final x = (t + (fila.isOdd ? .5 : 0)) * p.w / tij;
      p.c.drawLine(Offset(x, y), Offset(x, y + 2 * u), rej);
    }
  }
  // à noite o bar fica na penumbra (só o neon, as TVs, as garrafas e as lampadinhas brilham)
  if (p.noite) p.c.drawRect(Rect.fromLTRB(-2, -2, p.w + 2, p.hz), Paint()..color = const Color(0x66120A1C));
  p.c.restore();
  for (final j in janelas) {
    // a faixa de "aberto" sem letras: um coração de neon na vitrine
    _moldura(p, j, const Color(0xFF2B2E35), cruz: false);
    p.c.drawPath(_coracao(j.outerRect.center.translate(0, 2 * u), 2.4 * u), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .5 * u
      ..color = const Color(0xFFFF4F6D));
    p.brilho(j.outerRect.center.translate(0, 2 * u), 5 * u, const Color(0xFFFF4F6D), alfa: .3);
  }
  // o teto escuro com o varal de lampadinhas
  p.faixa(-2, 2.4 * u, const Color(0xFF2B2124), contorno: .5);
  _varalDeLuzes(p, 3 * u, 1.4 * u);
  // a cristaleira, o neon e as duas TVs do jogo
  final (cMeia, tw) = _cristaleiraETv(p, s.bMeia);
  p.laco(s.xb, cMeia + u, (x) {
    _cristaleira(p, x, cMeia);
    _neonDoBar(p, x, 14 * u);
  });
  if (tw > 4 * u) {
    for (final lado in [-1.0, 1.0]) {
      final cx = s.xb + lado * (cMeia + tw + 1.5 * u);
      p.laco(cx, tw + u, (x) => _tvDoBar(p, Rect.fromCenter(center: Offset(x, 13 * u), width: tw * 2, height: tw * 1.15)));
    }
  }
  // o lambri escuro
  final topo = p.hz - 16 * u;
  p.c.save();
  final fora = Path()
    ..fillType = PathFillType.evenOdd
    ..addRect(Rect.fromLTRB(-2, topo, p.w + 2, p.hz));
  p.laco(s.xb, cMeia + u, (x) => fora.addRect(Rect.fromLTRB(x - cMeia, topo, x + cMeia, p.hz)));
  p.c.clipPath(fora);
  p.faixa(topo, p.hz, const Color(0xFF4A2E22), contorno: .6);
  final n = p.vezes(5 * u);
  for (var i = 0; i < n; i++) {
    final x = (i + .5) * p.w / n;
    p.c.drawLine(Offset(x, topo + 1.2 * u), Offset(x, p.hz), p.traco(.25));
  }
  p.faixa(topo - 1 * u, topo + .2 * u, const Color(0xFF6E4532), contorno: .5);
  p.c.restore();
  // o resto da parede: o quadro de giz dos drinques e o alvo de dardos
  var k = 0;
  for (final (x0, meia) in s.vaos) {
    p.laco(x0, 8 * u, (x) {
      if (k == 0 && meia >= 8 * u) {
        _quadroNegro(p, Rect.fromLTWH(x - math.min(6.5 * u, meia - 1.5 * u), 15 * u, math.min(13 * u, 2 * meia - 3 * u), 17 * u));
      } else if (k <= 1) {
        _alvoDeDardos(p, Offset(x, 22 * u));
      } else {
        _quadroDePaisagem(p, Rect.fromCenter(center: Offset(x, 20 * u), width: math.min(8 * u, meia), height: 6 * u), k);
      }
    });
    k++;
  }
}

/// A banqueta alta do bar (assento redondo de couro vermelho, pés de metal e o apoio).
void _banquetaDoBar(_Pincel p, double x, double base) {
  final u = p.u;
  p.tubos([
    for (final dx in [-1.8, 1.8])
      Path()
        ..moveTo(x + dx * .4 * u, base - 11 * u)
        ..lineTo(x + dx * u, base),
  ], .5 * u, const Color(0xFF8D99A8), contorno: .4);
  p.c.drawLine(Offset(x - 1.4 * u, base - 4 * u), Offset(x + 1.4 * u, base - 4 * u), p.traco(.5));
  p.ret(Rect.fromCenter(center: Offset(x, base - 11.4 * u), width: 5 * u, height: 1.6 * u), const Color(0xFFB8432A), contorno: .7,
      raio: .8 * u);
}

/// O balcão do bar entre [x] ± [meia]: frente de madeira com o friso de latão, o tampo, as torneiras de chope, os
/// copos e a tigela de amendoim; uma banqueta em cada ponta.
void _balcaoDoBar(_Pincel p, double x, double meia, double base) {
  final u = p.u;
  final topo = base - 17 * u;
  for (final lado in [-1.0, 1.0]) {
    _banquetaDoBar(p, x + lado * (meia + 1 * u), base + 2 * u);
  }
  // as torneiras de chope e os copos em cima
  final nt = math.max(1, math.min(3, (meia / (4 * u)).floor()));
  for (var i = 0; i < nt; i++) {
    final tx = x - (nt - 1) * 1.6 * u + i * 3.2 * u;
    p.ret(Rect.fromLTRB(tx - .45 * u, topo - 6 * u, tx + .45 * u, topo - 1.2 * u), [const Color(0xFFE5533D), const Color(0xFF2EAD5B),
      const Color(0xFF3E8AE0)][i % 3], contorno: .35, raio: .3 * u);
  }
  p.ret(Rect.fromLTRB(x - (nt * 1.6 + .8) * u, topo - 1.6 * u, x + (nt * 1.6 + .8) * u, topo), const Color(0xFFD9A441), contorno: .5,
      raio: .3 * u);
  if (meia > 9 * u) {
    for (final dx in [-1.0, 1.0]) {
      final cx = x + dx * (meia - 4 * u);
      final copo = Rect.fromLTRB(cx - 1.1 * u, topo - 3.6 * u, cx + 1.1 * u, topo);
      p.ret(copo, const Color(0xFFF2B83D), contorno: .45, raio: .2 * u, alfa: .92);
      p.ret(Rect.fromLTRB(copo.left, copo.top, copo.right, copo.top + .9 * u), const Color(0xFFFFF8E8), contorno: .3);
    }
    p.c.drawOval(Rect.fromCenter(center: Offset(x + meia * .45, topo - .6 * u), width: 3.4 * u, height: 1.2 * u), p.tinta(const Color(0xFFC88A4A)));
    p.c.drawOval(Rect.fromCenter(center: Offset(x + meia * .45, topo - .6 * u), width: 3.4 * u, height: 1.2 * u), p.traco(.3));
  }
  // o tampo e a frente
  p.ret(Rect.fromLTRB(x - meia - 1 * u, topo, x + meia + 1 * u, topo + 1.4 * u), const Color(0xFF3A2620), contorno: .8);
  final frente = Rect.fromLTRB(x - meia, topo + 1.4 * u, x + meia, base);
  p.ret(frente, const Color(0xFF7A4A32), contorno: 1);
  final n = math.max(1, (frente.width / (6 * u)).round());
  for (var i = 0; i < n; i++) {
    p.c.drawRect(
        Rect.fromLTWH(frente.left + frente.width * i / n + .8 * u, frente.top + 2 * u, frente.width / n - 1.6 * u, frente.height - 5 * u),
        p.traco(.35));
  }
  p.tubos([
    Path()
      ..moveTo(frente.left + .6 * u, base - 2 * u)
      ..lineTo(frente.right - .6 * u, base - 2 * u)
  ], .5 * u, const Color(0xFFD9A441), contorno: .3);
  p.sombra(Path()..addRect(frente), Rect.fromLTRB(frente.left, frente.bottom - 2 * u, frente.right, frente.bottom));
}

/// Mesinha alta redonda do bar com duas banquetas e uma vela.
void _mesinhaAltaDoBar(_Pincel p, double x, double base) {
  final u = p.u;
  for (final dx in [-6.0, 6.0]) {
    _banquetaDoBar(p, x + dx * u, base + 1.4 * u);
  }
  p.tubos([
    Path()
      ..moveTo(x, base - 14 * u)
      ..lineTo(x, base - .6 * u)
  ], .7 * u, const Color(0xFF2B2E35), contorno: .5);
  p.ret(Rect.fromLTRB(x - 3 * u, base - .9 * u, x + 3 * u, base), const Color(0xFF2B2E35), contorno: .5, raio: .4 * u);
  p.ret(Rect.fromLTRB(x - 5.6 * u, base - 15.2 * u, x + 5.6 * u, base - 14 * u), const Color(0xFF5E3A2A), contorno: .7, raio: .5 * u);
  final chama = Offset(x, base - 17.4 * u + math.sin(p.t * 7) * .1 * u);
  p.ret(Rect.fromLTRB(x - .8 * u, base - 16.6 * u, x + .8 * u, base - 15.2 * u), const Color(0xFFB8432A), contorno: .3, raio: .3 * u);
  if (p.acesas) p.brilho(chama, 4 * u, const Color(0xFFFFC46B), alfa: .6);
  p.c.drawOval(Rect.fromCenter(center: chama, width: .6 * u, height: 1 * u), Paint()..color = const Color(0xFFFFB13D));
}

void _cBar(_Pincel p) {
  final u = p.u;
  // assoalho escuro em tábuas
  p.solo(const [Color(0xFF6B4532), Color(0xFF4E3124)]);
  final tabua = p.traco(.2);
  var y0 = p.hz;
  for (var i = 1; i < 8; i++) {
    final y = p.hz + i * i * .62 * u;
    p.c.drawLine(Offset(-2, y), Offset(p.w + 2, y), tabua);
    final juntas = p.vezes(14 * u);
    for (var k = 0; k < juntas; k++) {
      final x = (k + (i.isOdd ? .5 : 0) + .3 * _ruido(i * 17 + k + 70)) * p.w / juntas;
      p.c.drawLine(Offset(x, y0), Offset(x, y), tabua);
    }
    y0 = y;
  }
  if (p.noite) p.c.drawRect(Rect.fromLTRB(-2, p.hz, p.w + 2, p.h + 1), Paint()..color = const Color(0x66120A1C));
  final s = _plantaDoBar(p);
  p.laco(s.xb, s.bMeia + 6 * u, (x) => _balcaoDoBar(p, x, s.bMeia, p.hz + 7 * u));
  if (s.larga && p.w >= 110 * u) {
    for (final f in [.06, .94]) {
      p.laco(p.w * f, 9 * u, (x) => _mesinhaAltaDoBar(p, x, p.hz + 6 * u));
    }
  }
}

/// Coração centrado em [c], de largura ~2·[r] (o neon da vitrine do bar).
Path _coracao(Offset c, double r) => Path()
  ..moveTo(c.dx, c.dy + r * .95)
  ..cubicTo(c.dx - r * 1.5, c.dy + r * .1, c.dx - r * .9, c.dy - r * 1.1, c.dx, c.dy - r * .35)
  ..cubicTo(c.dx + r * .9, c.dy - r * 1.1, c.dx + r * 1.5, c.dy + r * .1, c.dx, c.dy + r * .95)
  ..close();
