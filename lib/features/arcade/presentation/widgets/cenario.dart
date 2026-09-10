import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'perspectiva.dart';

/// Os 6 cenários que os jogos percorrem ao passar de fase (depois ciclam).
const _temas = [
  ('🌅', 'Campina ao Amanhecer'),
  ('🏜️', 'Deserto Escaldante'),
  ('🌃', 'Cidade à Noite'),
  ('❄️', 'Montanha Nevada'),
  ('🌋', 'Vulcão Furioso'),
  ('🌌', 'Espaço Sideral'),
];

String nomeDaFase(int fase) => _temas[(fase - 1) % _temas.length].$2;
String emojiDaFase(int fase) => _temas[(fase - 1) % _temas.length].$1;

/// Material do CHÃO de cada mundo (o plano em perspectiva dos jogos 3D):
/// duas cores pra faixas alternadas, a neblina do horizonte, a cor da linha
/// de grade (só nos mundos que têm) e o adereço da beira da estrada.
class TemaChao {
  final Color claro;
  final Color escuro;
  final Color neblina;
  final Color? linha;
  final Adereco adereco;
  const TemaChao({
    required this.claro,
    required this.escuro,
    required this.neblina,
    this.linha,
    required this.adereco,
  });
}

enum Adereco { arvore, cacto, poste, pinheiro, rocha, cristal }

const _chaos = [
  TemaChao(
      claro: Color(0xFF6FAE5E),
      escuro: Color(0xFF5E9B4F),
      neblina: Color(0xFFFFE2B0),
      adereco: Adereco.arvore),
  TemaChao(
      claro: Color(0xFFE2B276),
      escuro: Color(0xFFD1A063),
      neblina: Color(0xFFFFE6C2),
      adereco: Adereco.cacto),
  TemaChao(
      claro: Color(0xFF2B3542),
      escuro: Color(0xFF232C38),
      neblina: Color(0xFF6C8BB5),
      linha: Color(0xFF4FC3F7),
      adereco: Adereco.poste),
  TemaChao(
      claro: Color(0xFFEAF4FB),
      escuro: Color(0xFFD6E6F2),
      neblina: Color(0xFFFFFFFF),
      adereco: Adereco.pinheiro),
  TemaChao(
      claro: Color(0xFF4A2A22),
      escuro: Color(0xFF3B1F1A),
      neblina: Color(0xFFFF8A65),
      adereco: Adereco.rocha),
  TemaChao(
      claro: Color(0xFF151C33),
      escuro: Color(0xFF0E1326),
      neblina: Color(0xFF7C4DFF),
      linha: Color(0xFF80DEEA),
      adereco: Adereco.cristal),
];

TemaChao chaoDaFase(int fase) => _chaos[(fase - 1) % _chaos.length];

/// Pano de fundo pintado da fase — céu, astro, morros e adereços mudam a
/// cada fase pra dar a sensação de viagem.
class CenarioFase extends StatelessWidget {
  final int fase;
  const CenarioFase({super.key, required this.fase});

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(
          painter: _CenarioPainter((fase - 1) % _temas.length),
          size: Size.infinite,
        ),
      );
}

class _CenarioPainter extends CustomPainter {
  final int tema;
  _CenarioPainter(this.tema);

  @override
  void paint(Canvas c, Size s) {
    switch (tema) {
      case 0:
        _amanhecer(c, s);
      case 1:
        _deserto(c, s);
      case 2:
        _cidade(c, s);
      case 3:
        _neve(c, s);
      case 4:
        _vulcao(c, s);
      case 5:
        _espaco(c, s);
    }
  }

  // ---------- peças reutilizadas ----------

  void _ceu(Canvas c, Size s, List<Color> cores) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cores)
            .createShader(Offset.zero & s),
    );
  }

  void _astro(Canvas c, Size s, double fx, double fy, double raio, Color cor,
      {double halo = 0}) {
    final centro = Offset(s.width * fx, s.height * fy);
    if (halo > 0) {
      c.drawCircle(centro, raio * (1 + halo), Paint()..color = cor.withValues(alpha: .25));
    }
    c.drawCircle(centro, raio, Paint()..color = cor);
  }

  /// Cadeia de morros: uma onda senoidal preenchida até o chão.
  void _morros(Canvas c, Size s, double base, double amplitude, Color cor,
      {double ondas = 2.2, double desloca = 0}) {
    final p = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += 6) {
      final y = s.height * base -
          math.sin((x / s.width) * math.pi * ondas + desloca) * amplitude;
      p.lineTo(x, y);
    }
    p
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(p, Paint()..color = cor);
  }

  void _nuvem(Canvas c, double x, double y, double t, Color cor) {
    final tinta = Paint()..color = cor;
    c.drawOval(Rect.fromCenter(center: Offset(x, y), width: t * 2.2, height: t), tinta);
    c.drawOval(
        Rect.fromCenter(center: Offset(x + t * 0.9, y + t * 0.12), width: t * 1.6, height: t * 0.8),
        tinta);
    c.drawOval(
        Rect.fromCenter(center: Offset(x - t * 0.9, y + t * 0.15), width: t * 1.4, height: t * 0.7),
        tinta);
  }

  void _estrelas(Canvas c, Size s, int n, {double ateY = 1}) {
    final tinta = Paint()..color = Colors.white.withValues(alpha: .85);
    for (var i = 0; i < n; i++) {
      // pseudo-aleatório estável (sem Random: pinta igual em todo frame)
      final x = ((i * 73) % 97) / 97 * s.width;
      final y = ((i * 41) % 89) / 89 * s.height * ateY;
      c.drawCircle(Offset(x, y), i % 3 == 0 ? 1.6 : 0.9, tinta);
    }
  }

  void _triangulo(Canvas c, double x, double base, double larg, double alt, Color cor) {
    final p = Path()
      ..moveTo(x - larg / 2, base)
      ..lineTo(x, base - alt)
      ..lineTo(x + larg / 2, base)
      ..close();
    c.drawPath(p, Paint()..color = cor);
  }

  // ---------- os seis mundos ----------

  void _amanhecer(Canvas c, Size s) {
    _ceu(c, s, const [Color(0xFFFFCF8A), Color(0xFF8ED0F0)]);
    _astro(c, s, .82, .30, s.height * .13, const Color(0xFFFFE082), halo: .6);
    _nuvem(c, s.width * .22, s.height * .22, s.height * .07, Colors.white.withValues(alpha: .85));
    _nuvem(c, s.width * .55, s.height * .38, s.height * .05, Colors.white.withValues(alpha: .7));
    _morros(c, s, .78, s.height * .10, const Color(0xFF7CB56B));
    _morros(c, s, .90, s.height * .07, const Color(0xFF5B9A50), desloca: 1.8);
    for (final (fx, esc) in [(.12, 1.0), (.38, .8), (.68, 1.1), (.9, .9)]) {
      _arvore(c, s.width * fx, s.height * .93, s.height * .14 * esc);
    }
  }

  /// Árvore redonda com copa iluminada de um lado (lê bem em qualquer escala).
  void _arvore(Canvas c, double x, double base, double alt) {
    final tronco = alt * .12;
    c.drawRect(Rect.fromLTWH(x - tronco / 2, base - alt * .45, tronco, alt * .45),
        Paint()..color = const Color(0xFF6D4C2F));
    final copa = Rect.fromCircle(center: Offset(x, base - alt * .62), radius: alt * .4);
    c.drawOval(
        copa,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.35, -.4),
            radius: .9,
            colors: [Color(0xFF6DBB5B), Color(0xFF3E7B39), Color(0xFF2E5F2B)],
            stops: [0, .6, 1],
          ).createShader(copa));
    c.drawCircle(Offset(x - alt * .18, base - alt * .78), alt * .2,
        Paint()..color = const Color(0xFF7FCB6B).withValues(alpha: .55));
  }

  void _deserto(Canvas c, Size s) {
    _ceu(c, s, const [Color(0xFFFF9E4F), Color(0xFFFFD9A0)]);
    _astro(c, s, .18, .26, s.height * .14, const Color(0xFFFFF3C4), halo: .5);
    _morros(c, s, .80, s.height * .09, const Color(0xFFE0A96D), ondas: 1.6);
    _morros(c, s, .92, s.height * .06, const Color(0xFFC98F4E), ondas: 2.4, desloca: 2);
    // cactos
    for (final fx in [.28, .62, .86]) {
      final x = s.width * fx;
      final base = s.height * .93;
      final tinta = Paint()
        ..color = const Color(0xFF4E8F4A)
        ..strokeWidth = s.height * .035
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(x, base), Offset(x, base - s.height * .16), tinta);
      c.drawLine(Offset(x, base - s.height * .09), Offset(x - s.width * .022, base - s.height * .13), tinta);
      c.drawLine(Offset(x, base - s.height * .07), Offset(x + s.width * .022, base - s.height * .12), tinta);
    }
  }

  void _cidade(Canvas c, Size s) {
    _ceu(c, s, const [Color(0xFF0D1B2A), Color(0xFF27405C)]);
    _estrelas(c, s, 26, ateY: .55);
    _astro(c, s, .85, .2, s.height * .10, const Color(0xFFEBF2F7), halo: .4);
    // prédios com janelas acesas
    final larguras = [.10, .07, .12, .08, .11, .09, .13, .08];
    var x = 0.0;
    for (var i = 0; i < larguras.length && x < s.width; i++) {
      final w = s.width * larguras[i];
      final h = s.height * (.28 + ((i * 37) % 40) / 100);
      final topo = s.height - h;
      c.drawRect(Rect.fromLTWH(x, topo, w, h), Paint()..color = const Color(0xFF15202E));
      final janela = Paint()..color = const Color(0xFFFFD54F).withValues(alpha: .85);
      for (var l = 0; l < 5; l++) {
        for (var col = 0; col < 3; col++) {
          if ((i * 7 + l * 3 + col) % 3 == 0) continue; // algumas apagadas
          c.drawRect(
              Rect.fromLTWH(x + w * (.18 + col * .28), topo + h * (.08 + l * .17), w * .14,
                  h * .07),
              janela);
        }
      }
      x += w + s.width * .015;
    }
  }

  void _neve(Canvas c, Size s) {
    _ceu(c, s, const [Color(0xFF9FD4EE), Color(0xFFE8F6FD)]);
    _astro(c, s, .8, .22, s.height * .10, Colors.white, halo: .3);
    _morros(c, s, .74, s.height * .12, const Color(0xFFF4FAFF));
    _morros(c, s, .88, s.height * .08, const Color(0xFFDDEBF5), desloca: 2.1);
    for (final fx in [.15, .45, .72, .92]) {
      _triangulo(c, s.width * fx, s.height * .9, s.width * .04, s.height * .16,
          const Color(0xFF2F5D46));
      _triangulo(c, s.width * fx, s.height * .84, s.width * .028, s.height * .07, Colors.white);
    }
    // floquinhos
    final flo = Paint()..color = Colors.white;
    for (var i = 0; i < 22; i++) {
      c.drawCircle(
          Offset(((i * 53) % 101) / 101 * s.width, ((i * 29) % 71) / 71 * s.height * .7),
          1.4,
          flo);
    }
  }

  void _vulcao(Canvas c, Size s) {
    _ceu(c, s, const [Color(0xFF2A0E0B), Color(0xFF7B2A16)]);
    _astro(c, s, .16, .2, s.height * .08, const Color(0xFFFF8A65), halo: .8);
    _morros(c, s, .72, s.height * .14, const Color(0xFF3B1F1A), ondas: 1.4);
    // o vulcão com lava
    final vx = s.width * .68;
    final base = s.height * .95;
    _triangulo(c, vx, base, s.width * .3, s.height * .5, const Color(0xFF241311));
    _triangulo(c, vx, base - s.height * .42, s.width * .075, s.height * .08,
        const Color(0xFFFF7043));
    final lava = Paint()
      ..color = const Color(0xFFFF5722)
      ..strokeWidth = s.height * .018
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(vx, base - s.height * .42), Offset(vx - s.width * .04, base - s.height * .18), lava);
    c.drawLine(Offset(vx, base - s.height * .40), Offset(vx + s.width * .05, base - s.height * .22), lava);
    _morros(c, s, .93, s.height * .05, const Color(0xFF1A0D0B), ondas: 2.6, desloca: 1);
  }

  void _espaco(Canvas c, Size s) {
    _ceu(c, s, const [Color(0xFF05060F), Color(0xFF141B33)]);
    _estrelas(c, s, 46);
    // planeta com anel
    final centro = Offset(s.width * .78, s.height * .34);
    final raio = s.height * .13;
    c.drawCircle(centro, raio, Paint()..color = const Color(0xFFB388FF));
    c.drawCircle(centro.translate(-raio * .3, -raio * .25), raio * .3,
        Paint()..color = const Color(0xFFD1C4E9).withValues(alpha: .6));
    c.save();
    c.translate(centro.dx, centro.dy);
    c.rotate(-.4);
    c.drawOval(
        Rect.fromCenter(center: Offset.zero, width: raio * 3.1, height: raio * .7),
        Paint()
          ..color = const Color(0xFF80DEEA).withValues(alpha: .7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = raio * .14);
    c.restore();
    // a Terra pequenina lá longe
    c.drawCircle(Offset(s.width * .16, s.height * .68), s.height * .05,
        Paint()..color = const Color(0xFF4FC3F7));
  }

  @override
  bool shouldRepaint(_CenarioPainter old) => old.tema != tema;
}


/// Palco em PSEUDO-3D de um mundo: céu e morros do cenário até o horizonte
/// (em [horizonte], fração da altura) e, dali pra baixo, o chão da fase em
/// faixas de profundidade com grade que foge pro ponto de fuga, neblina e
/// brilho na linha do horizonte. Usado na arena da Chuva e na faixa do
/// Caça-Bug.
class PalcoFase extends StatelessWidget {
  final int fase;
  final double horizonte;

  /// Grade do chão (linhas de fuga + divisórias) — cara de palco digital.
  final bool grade;
  const PalcoFase({super.key, required this.fase, this.horizonte = .56, this.grade = true});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final h = box.maxHeight;
      final p = Perspectiva(largura: w, altura: h, horizonte: h * horizonte, meiaLargura: w * .5);
      return Stack(children: [
        Positioned(left: 0, right: 0, top: 0, height: p.horizonte + 3, child: CenarioFase(fase: fase)),
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _PalcoPainter(p: p, tema: chaoDaFase(fase), grade: grade)),
          ),
        ),
      ]);
    });
  }
}

class _PalcoPainter extends CustomPainter {
  final Perspectiva p;
  final TemaChao tema;
  final bool grade;
  _PalcoPainter({required this.p, required this.tema, required this.grade});

  @override
  void paint(Canvas c, Size s) {
    pintarChaoEmFaixas(
      c,
      p,
      claro: tom(tema.claro, .8),
      escuro: tom(tema.escuro, .74),
      linha: grade ? (tema.linha ?? Colors.white.withValues(alpha: .35)) : null,
      segmento: .28,
    );
    if (grade) {
      pintarLinhasDeFuga(c, p, (tema.linha ?? Colors.white).withValues(alpha: .10), passo: .26, n: 10);
    }
    pintarNeblina(c, p, tema.neblina, ate: .5);
    // brilho na linha do horizonte
    c.drawRect(
      Rect.fromLTWH(0, p.horizonte - 1.5, p.largura, 3),
      Paint()
        ..color = tema.neblina.withValues(alpha: .75)
        ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, 3),
    );
  }

  @override
  bool shouldRepaint(_PalcoPainter old) =>
      old.tema != tema || old.grade != grade || old.p.largura != p.largura || old.p.altura != p.altura;
}
