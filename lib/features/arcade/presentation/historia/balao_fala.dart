import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/historia_turismo.dart';

const _corTexto = Color(0xFF1E1E28);
const _corPt = Color(0xFF5A5A6A);
const _contorno = Color(0xFF3A2A33);

/// O texto da máquina de escrever: as [n] primeiras letras visíveis e o resto transparente (ocupa o lugar).
TextSpan _digitado(String en, int n, TextStyle estilo) => TextSpan(
      style: estilo,
      children: [
        TextSpan(text: en.substring(0, n)),
        if (n < en.length)
          TextSpan(text: en.substring(n), style: estilo.copyWith(color: estilo.color!.withValues(alpha: 0))),
      ],
    );

/// 💬 O balão de fala: chip com o nome, inglês com máquina de escrever ([letras] visíveis) e o PT quando o
/// inglês termina. [via] = fala remota (rádio: borda tracejada, 📻 e chiado; celular: 📱).
///
/// [alvoRabicho]: para onde o rabicho aponta, em coordenadas do próprio balão (0,0 = canto de cima à
/// esquerda). Só o `dx` decide a ponta; o rabicho sai sempre de baixo. null = sem rabicho.
///
/// Acessibilidade: o texto que digita fica em `ExcludeSemantics`; um único `Semantics(liveRegion)` por
/// fala lê "nome: inglês. português" de uma vez. O inglês sabe quebrar linha e o corpo rola por dentro
/// se a altura acabar (texto grande / tela baixa).
class BalaoFala extends StatelessWidget {
  const BalaoFala({
    super.key,
    required this.nome,
    required this.cor,
    required this.en,
    required this.pt,
    required this.letras,
    required this.mostrarPt,
    this.via,
    this.alvoRabicho,
    this.escala = 1,
  });

  final String nome, en, pt;
  final Color cor;
  final int letras;
  final bool mostrarPt;
  final ViaRemota? via;
  final Offset? alvoRabicho;
  final double escala;

  @override
  Widget build(BuildContext context) {
    final completo = letras >= en.length;
    final visivel = en.substring(0, letras.clamp(0, en.length));
    final rabicho = 14.0 * escala;
    final corBorda = via == ViaRemota.radio ? const Color(0xFF5B6B7A) : _contorno;
    final icone = _icone(via);
    final corpo = Padding(
      padding: EdgeInsets.fromLTRB(14 * escala, 10 * escala, 14 * escala, 12 * escala),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: cor, borderRadius: BorderRadius.circular(Mixart.radiusChip)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8 * escala, vertical: 2 * escala),
                child: Text(
                  '$icone$nome',
                  style: _estiloChip(escala, textoNoChip(cor)),
                ),
              ),
            ),
            SizedBox(height: 6 * escala),
            // o resto ainda não digitado fica transparente: o balão não "cresce" nem quebra linha diferente
            Text.rich(
              key: const Key('historia-balao-en'),
              _digitado(en, visivel.length, _estiloEn(escala)),
            ),
            if (mostrarPt && pt.isNotEmpty)
              AnimatedOpacity(
                opacity: completo ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: Padding(
                  padding: EdgeInsets.only(top: 4 * escala),
                  child: Text(
                    pt,
                    key: const Key('historia-balao-pt'),
                    style: _estiloPt(escala),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Semantics(
      liveRegion: true,
      label: '$nome: $en${mostrarPt && pt.isNotEmpty ? '. $pt' : ''}',
      child: ExcludeSemantics(
        child: CustomPaint(
          key: const Key('historia-balao'),
          painter: _BalaoPainter(
            borda: corBorda,
            tracejado: via == ViaRemota.radio,
            chiado: via == ViaRemota.radio,
            celular: via == ViaRemota.celular,
            rabicho: alvoRabicho == null ? 0 : rabicho,
            pontaX: alvoRabicho?.dx,
            escala: escala,
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: alvoRabicho == null ? 0 : rabicho),
            child: corpo,
          ),
        ),
      ),
    );
  }

  static String _icone(ViaRemota? via) => switch (via) {
        ViaRemota.radio => '📻 ',
        ViaRemota.celular => '📱 ',
        null => '',
      };

  static TextStyle _estiloChip(double escala, Color cor) => Mixart.ui(size: 12 * escala, weight: FontWeight.w800, color: cor);

  static TextStyle _estiloEn(double escala) =>
      Mixart.ui(size: math.min(24, 18 * escala), weight: FontWeight.w700, color: _corTexto).copyWith(height: 1.25);

  static TextStyle _estiloPt(double escala) =>
      Mixart.ui(size: math.min(16, 13.5 * escala), color: _corPt).copyWith(fontStyle: FontStyle.italic, height: 1.25);

  /// A cor do nome no chip: branco ou o texto escuro, o que tiver MAIS contraste (WCAG) com a cor do chip.
  static Color textoNoChip(Color c) => contraste(Colors.white, c) >= contraste(_corTexto, c) ? Colors.white : _corTexto;

  /// Contraste WCAG entre duas cores (1–21).
  static double contraste(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
  }

  /// O tamanho natural do balão (sem rolar) cabendo em [maxLargura]: o mesmo layout do [build] — chip,
  /// inglês inteiro, PT quando [mostrarPt], paddings e o rabicho — medido com `TextPainter` no estilo de
  /// texto e no [textScaler] (padrão: o do `MediaQuery`) de [context]. O palco usa para centrar o balão
  /// em quem fala (o rabicho aponta certo) e para encolher o texto grande antes de precisar rolar.
  static Size medir(
    BuildContext context, {
    required String nome,
    required String en,
    required String pt,
    required bool mostrarPt,
    ViaRemota? via,
    required bool comRabicho,
    required double escala,
    required double maxLargura,
    TextScaler? textScaler,
  }) {
    final base = DefaultTextStyle.of(context).style;
    final scaler = textScaler ?? MediaQuery.textScalerOf(context);
    final direcao = Directionality.maybeOf(context) ?? TextDirection.ltr;
    final padH = 28 * escala;
    final maxConteudo = math.max(1.0, maxLargura - padH);
    final pintores = <TextPainter>[];
    TextPainter medida(String texto, TextStyle estilo, double max) {
      final tp = TextPainter(text: TextSpan(text: texto, style: base.merge(estilo)), textDirection: direcao, textScaler: scaler)
        ..layout(maxWidth: math.max(1.0, max));
      pintores.add(tp);
      return tp;
    }

    final chip = medida('${_icone(via)}$nome', _estiloChip(escala, _corTexto), maxConteudo - 16 * escala);
    final ingles = medida(en, _estiloEn(escala), maxConteudo);
    final temPt = mostrarPt && pt.isNotEmpty;
    final portugues = temPt ? medida(pt, _estiloPt(escala), maxConteudo) : null;
    final conteudo = math.min(
      maxConteudo,
      math.max(chip.width + 16 * escala, math.max(ingles.width, portugues?.width ?? 0)),
    );
    final altura = 10 * escala +
        chip.height +
        4 * escala +
        6 * escala +
        ingles.height +
        (portugues == null ? 0 : 4 * escala + portugues.height) +
        12 * escala +
        (comRabicho ? 14 * escala : 0);
    for (final tp in pintores) {
      tp.dispose();
    }
    return Size(conteudo + padH, altura);
  }
}

/// O corpo branco do balão, o contorno de desenho, o rabicho e, no rádio, a borda tracejada e o chiado.
class _BalaoPainter extends CustomPainter {
  _BalaoPainter({
    required this.borda,
    required this.tracejado,
    required this.chiado,
    required this.celular,
    required this.rabicho,
    required this.pontaX,
    required this.escala,
  });

  final Color borda;
  final bool tracejado, chiado, celular;
  final double rabicho, escala;
  final double? pontaX;

  @override
  void paint(Canvas canvas, Size size) {
    final corpo = Rect.fromLTWH(0, 0, size.width, math.max(0, size.height - rabicho));
    if (corpo.isEmpty) return;
    final raio = Radius.circular(18 * escala);
    final rr = RRect.fromRectAndRadius(corpo, raio);
    final path = Path()..addRRect(rr);
    if (rabicho > 0 && pontaX != null) {
      final base = pontaX!.clamp(28 * escala, math.max(28 * escala, size.width - 28 * escala));
      final ponta = Offset(pontaX!.clamp(10.0, math.max(10.0, size.width - 10)), size.height);
      final cauda = Path()
        ..moveTo(base - 10 * escala, corpo.bottom - 1)
        ..quadraticBezierTo(base - 2, corpo.bottom + rabicho * .4, ponta.dx, ponta.dy)
        ..quadraticBezierTo(base + 4, corpo.bottom + rabicho * .3, base + 10 * escala, corpo.bottom - 1)
        ..close();
      path.addPath(cauda, Offset.zero);
    }
    canvas.drawShadow(path, Colors.black, 3, false);
    canvas.drawPath(path, Paint()..color = Colors.white);
    if (celular) {
      canvas.drawRRect(
        rr.deflate(3),
        Paint()
          ..color = const Color(0xFF4FC3F7).withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    if (chiado) {
      // linhas de chiado do rádio no canto de cima à direita
      final p = Paint()
        ..color = const Color(0xFF9AA7B4)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 3; i++) {
        final y = corpo.top + (10 + i * 6) * escala;
        final x0 = corpo.right - (46 - i * 4) * escala;
        for (var k = 0; k < 4; k++) {
          final x = x0 + k * 8 * escala;
          canvas.drawLine(Offset(x, y), Offset(x + 4 * escala, y + ((k + i).isEven ? -2 : 2)), p);
        }
      }
    }
    final contorno = Paint()
      ..color = borda
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    if (tracejado) {
      for (final m in path.computeMetrics()) {
        var d = 0.0;
        while (d < m.length) {
          canvas.drawPath(m.extractPath(d, math.min(d + 9, m.length)), contorno);
          d += 15;
        }
      }
    } else {
      canvas.drawPath(path, contorno);
    }
  }

  @override
  bool shouldRepaint(_BalaoPainter old) =>
      old.borda != borda ||
      old.tracejado != tracejado ||
      old.chiado != chiado ||
      old.celular != celular ||
      old.rabicho != rabicho ||
      old.pontaX != pontaX ||
      old.escala != escala;
}

/// 🎙️ A fala do narrador: faixa escura translúcida embaixo do palco.
class LegendaNarrador extends StatelessWidget {
  const LegendaNarrador({super.key, required this.en, required this.pt, required this.letras, required this.mostrarPt});

  final String en, pt;
  final int letras;
  final bool mostrarPt;

  @override
  Widget build(BuildContext context) {
    final completo = letras >= en.length;
    final visivel = en.substring(0, letras.clamp(0, en.length));
    final largura = MediaQuery.maybeSizeOf(context)?.width ?? 800;
    final escala = (largura / 1280).clamp(1.0, 1.4);
    final estiloEn = Mixart.ui(size: math.min(22, 17 * escala), weight: FontWeight.w600, color: Colors.white)
        .copyWith(fontStyle: FontStyle.italic, height: 1.25);
    return Semantics(
      liveRegion: true,
      label: 'Narrador: $en${mostrarPt && pt.isNotEmpty ? '. $pt' : ''}',
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(16, 10 * escala, 16, 12 * escala),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x991E1E28), Color(0xE61E1E28)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                key: const Key('historia-legenda-en'),
                _digitado(en, visivel.length, estiloEn),
                textAlign: TextAlign.center,
              ),
              if (mostrarPt && pt.isNotEmpty)
                AnimatedOpacity(
                  opacity: completo ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      pt,
                      key: const Key('historia-legenda-pt'),
                      textAlign: TextAlign.center,
                      style: Mixart.ui(size: math.min(16, 13.5 * escala), color: Colors.white70)
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
