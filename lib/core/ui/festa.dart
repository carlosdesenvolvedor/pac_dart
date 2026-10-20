// O "kit festa" do PAC·ENGLISH: confete, botão 3D, baú, chama do combo e as
// cores das etapas. Só AnimationControllers de uma vez (nada de Timer, nada
// repetindo): `pumpAndSettle` sempre assenta.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../som/sons.dart';
import '../theme/mixart.dart';

/// Os acentos que o app já usa além da marca.
abstract final class CoresFesta {
  static const verde = Color(0xFF4CD08A);
  static const ambar = Color(0xFFE0A030);
  static const azul = Color(0xFF4FC3F7);
  static const violeta = Color(0xFFB388FF);
  static const coral = Color(0xFFFF7E6B);
  static const ouro = Color(0xFFFFC73B);
}

/// [c] mais escuro ([quanto] da luminosidade, 0–1). Com [soNoClaro], só escurece quando a paleta em uso
/// é clara (acento claro em fundo branco some; em fundo escuro ele fica como está).
Color escurecer(Color c, {double quanto = .25, bool soNoClaro = false}) {
  if (soNoClaro && !Mixart.atual.ehClaro) return c;
  final hsl = HSLColor.fromColor(c);
  // um pouco menos saturada também: só baixar a luz deixa coral/violeta "berrando"
  return hsl
      .withLightness((hsl.lightness * (1 - quanto)).clamp(0.0, 1.0))
      .withSaturation((hsl.saturation * (1 - quanto * .35)).clamp(0.0, 1.0))
      .toColor();
}

/// A cor de uma etapa do curso de inglês ("A1 · Fundação", "B2 · …", "DEV · …"): A1 verde, A2 céu, B1
/// âmbar, B2 violeta, C1 coral, DEV a cor da marca. Escurecida 25% nas paletas claras.
Color corDaEtapa(String etapa) {
  final nivel = etapa.trim().split(RegExp(r'[ ·—-]')).first.toUpperCase();
  final base = switch (nivel) {
    'A1' => CoresFesta.verde,
    'A2' => CoresFesta.azul,
    'B1' => CoresFesta.ambar,
    'B2' => CoresFesta.violeta,
    'C1' => CoresFesta.coral,
    _ => null,
  };
  return base == null ? Mixart.brand : escurecer(base, soNoClaro: true);
}

/// Texto legível sobre [fundo] (preto ou branco, pelo brilho).
Color corSobre(Color fundo) => fundo.computeLuminance() > .45 ? const Color(0xFF111111) : Colors.white;

// ---------------------------------------------------------------------------
// Confete
// ---------------------------------------------------------------------------

/// Uma chuva de confete que estoura UMA vez ao aparecer e some (não bloqueia toques). Ocupa o espaço do
/// pai: use dentro de um `Stack` com `Positioned.fill`. Para estourar de novo, troque a `key`.
class Confete extends StatefulWidget {
  final int quantidade;
  final Duration duracao;

  /// Sorteio fixo (o mesmo desenho a cada vez; testes estáveis).
  final int semente;

  /// De onde sai, no espaço do pai (padrão: um pouco acima do centro).
  final Alignment origem;
  final List<Color>? cores;
  final VoidCallback? aoTerminar;

  const Confete({
    super.key,
    this.quantidade = 40,
    this.duracao = const Duration(milliseconds: 1500),
    this.semente = 7,
    this.origem = const Alignment(0, -.2),
    this.cores,
    this.aoTerminar,
  });

  @override
  State<Confete> createState() => _ConfeteState();
}

class _Particula {
  final double angulo, velocidade, giro, tamanho, atraso;
  final Color cor;
  final bool redonda;
  _Particula(this.angulo, this.velocidade, this.giro, this.tamanho, this.atraso, this.cor, this.redonda);
}

class _ConfeteState extends State<Confete> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duracao)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        if (mounted) setState(() {});
        widget.aoTerminar?.call();
      }
    })
    ..forward();

  late final List<_Particula> _ps = () {
    final rnd = math.Random(widget.semente);
    final cores = widget.cores ??
        [CoresFesta.ouro, CoresFesta.verde, CoresFesta.azul, CoresFesta.coral, CoresFesta.violeta, Colors.white];
    return [
      for (var i = 0; i < widget.quantidade; i++)
        _Particula(
          -math.pi / 2 + (rnd.nextDouble() - .5) * math.pi * .95, // leque para cima
          .55 + rnd.nextDouble() * .75,
          (rnd.nextDouble() - .5) * 14,
          4 + rnd.nextDouble() * 5,
          rnd.nextDouble() * .12,
          cores[i % cores.length],
          rnd.nextBool(),
        ),
    ];
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_c.isCompleted) return const IgnorePointer(child: SizedBox.expand());
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _ConfetePainter(_c, _ps, widget.origem),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ConfetePainter extends CustomPainter {
  final Animation<double> t;
  final List<_Particula> ps;
  final Alignment origem;
  _ConfetePainter(this.t, this.ps, this.origem) : super(repaint: t);

  @override
  void paint(Canvas canvas, Size size) {
    final o = origem.alongSize(size);
    final escala = math.max(size.shortestSide, 160.0);
    final tinta = Paint();
    for (final p in ps) {
      final tt = ((t.value - p.atraso) / (1 - p.atraso)).clamp(0.0, 1.0);
      if (tt <= 0) continue;
      final v = p.velocidade * escala * 1.1;
      final x = o.dx + math.cos(p.angulo) * v * tt;
      final y = o.dy + math.sin(p.angulo) * v * tt + .9 * escala * tt * tt; // gravidade
      final alpha = tt < .7 ? 1.0 : (1 - (tt - .7) / .3);
      tinta.color = p.cor.withValues(alpha: alpha.clamp(0.0, 1.0));
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.giro * tt);
      if (p.redonda) {
        canvas.drawCircle(Offset.zero, p.tamanho * .45, tinta);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: p.tamanho, height: p.tamanho * .5),
              const Radius.circular(1)),
          tinta,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfetePainter old) => old.ps != ps || old.origem != origem;
}

// ---------------------------------------------------------------------------
// Botão 3D
// ---------------------------------------------------------------------------

/// O botão "de apertar" (estilo Duolingo): uma face sobre um lábio mais escuro, que afunda ao tocar e
/// faz um blip. Sem [onTap], fica apagado. Foco pelo Tab e Enter/Espaço ativam (nunca rouba o foco
/// num toque).
class Botao3D extends StatefulWidget {
  final String rotulo;
  final VoidCallback? onTap;

  /// Cor da face (padrão: a marca) e do texto (padrão: legível sobre a face).
  final Color? cor;
  final Color? corTexto;

  /// Botão secundário: face da superfície, borda e texto na cor da marca.
  final bool contorno;
  final IconData? icone;
  final double altura;

  /// Largura toda do pai (padrão) ou só o conteúdo.
  final bool expandir;
  final double tamanhoTexto;
  final bool som;
  final FocusNode? focusNode;
  final bool autofocus;

  const Botao3D({
    super.key,
    required this.rotulo,
    this.onTap,
    this.cor,
    this.corTexto,
    this.contorno = false,
    this.icone,
    this.altura = 50,
    this.expandir = true,
    this.tamanhoTexto = 15,
    this.som = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Altura do lábio (o "degrau" sob a face).
  static const labio = 5.0;

  @override
  State<Botao3D> createState() => _Botao3DState();
}

class _Botao3DState extends State<Botao3D> {
  bool _apertado = false;
  bool _foco = false;

  bool get _ativo => widget.onTap != null;

  void _ativar() {
    if (!_ativo) return;
    if (widget.som) Sons.toca(Som.blip);
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    final Color face, labio, texto;
    if (!_ativo) {
      face = Mixart.surfaceHi;
      labio = escurecer(Mixart.surfaceHi, quanto: Mixart.atual.ehClaro ? .12 : .35);
      texto = Mixart.textFaint;
    } else if (widget.contorno) {
      face = Mixart.surface;
      labio = Mixart.atual.ehClaro ? escurecer(Mixart.border, quanto: .15) : Mixart.surfaceHi;
      texto = widget.corTexto ?? widget.cor ?? Mixart.brand;
    } else {
      face = widget.cor ?? Mixart.brand;
      labio = escurecer(face, quanto: .32);
      texto = widget.corTexto ?? corSobre(face);
    }
    final desce = _apertado ? Botao3D.labio - 1 : 0.0;
    final raio = BorderRadius.circular(Mixart.radiusMd);
    final rotulo = Text(
      widget.rotulo,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: Mixart.ui(size: widget.tamanhoTexto, weight: FontWeight.w800, color: texto).copyWith(letterSpacing: .4),
    );
    final conteudo = Row(
      mainAxisSize: widget.expandir ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icone != null) ...[
          Icon(widget.icone, size: widget.tamanhoTexto + 3, color: texto),
          const SizedBox(width: 8),
        ],
        if (widget.expandir) Flexible(child: rotulo) else rotulo,
      ],
    );
    return Semantics(
      button: true,
      enabled: _ativo,
      label: widget.rotulo,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _ativo,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        mouseCursor: _ativo ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onShowFocusHighlight: (v) => setState(() => _foco = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => _ativar())},
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _ativo ? (_) => setState(() => _apertado = true) : null,
          onTapCancel: _ativo ? () => setState(() => _apertado = false) : null,
          onTapUp: _ativo
              ? (_) {
                  setState(() => _apertado = false);
                  _ativar();
                }
              : null,
          // o lábio (escuro) começa onde a face está; a face desce até [labio] ao apertar e o lábio
          // visível encolhe na mesma medida — a altura total nunca muda
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            width: widget.expandir ? double.infinity : null,
            margin: EdgeInsets.only(top: desce),
            padding: EdgeInsets.only(bottom: Botao3D.labio - desce),
            decoration: BoxDecoration(color: labio, borderRadius: raio),
            child: Container(
              key: const ValueKey('botao3d-face'),
              height: widget.altura,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              // sem [expandir], nada de alignment: com ele o Container ocupa toda a largura que o pai
              // deixar (Wrap, Column, Align); o Row (mainAxisSize.min) já centraliza o conteúdo
              alignment: widget.expandir ? Alignment.center : null,
              decoration: BoxDecoration(
                color: face,
                borderRadius: raio,
                border: widget.contorno || _foco
                    ? Border.all(
                        color: _foco ? Mixart.text : (Mixart.atual.ehClaro ? Mixart.border : Mixart.surfaceHi),
                        width: _foco ? 2 : 1.5)
                    : null,
              ),
              child: conteudo,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Baú
// ---------------------------------------------------------------------------

/// Um baú de tesouro visto de frente. [abertura] 0 (fechado) → 1 (tampa erguida, brilho saindo);
/// [brilho] 0–1 acende o contorno (baú pronto para abrir); [trancado] põe o cadeado cinza.
class BauPainter extends CustomPainter {
  final double abertura;
  final double brilho;
  final bool trancado;
  final Color madeira;
  final Color metal;

  const BauPainter({
    this.abertura = 0,
    this.brilho = 0,
    this.trancado = false,
    this.madeira = const Color(0xFFB0662A),
    this.metal = CoresFesta.ouro,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final a = abertura.clamp(0.0, 1.0);
    final corMadeira = trancado ? const Color(0xFF6E6A66) : madeira;
    final corMetal = trancado ? const Color(0xFF9A9A9A) : metal;
    final escura = escurecer(corMadeira, quanto: .35);
    final corpo = Rect.fromLTWH(w * .08, h * .46, w * .84, h * .48);
    final dobradica = Offset(corpo.left, corpo.top);

    // brilho em volta (pronto)
    if (brilho > 0 && !trancado) {
      canvas.drawCircle(
        Offset(w / 2, h * .62),
        w * .55,
        Paint()
          ..shader = RadialGradient(colors: [
            corMetal.withValues(alpha: .45 * brilho),
            corMetal.withValues(alpha: 0),
          ]).createShader(Rect.fromCircle(center: Offset(w / 2, h * .62), radius: w * .55)),
      );
    }

    // sombra no chão
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h * .95), width: w * .9, height: h * .08),
      Paint()..color = Colors.black.withValues(alpha: .22),
    );

    // interior + luz (aparece com a tampa erguida)
    if (a > 0) {
      final boca = Rect.fromLTWH(corpo.left + w * .04, corpo.top - h * .06 * a, corpo.width - w * .08, h * .1 + h * .06 * a);
      canvas.drawRRect(RRect.fromRectAndRadius(boca, Radius.circular(w * .03)), Paint()..color = const Color(0xFF2A1608));
      final luz = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [const Color(0xFFFFF2B0).withValues(alpha: .95 * a), const Color(0x00FFF2B0)],
        ).createShader(Rect.fromLTWH(0, 0, w, corpo.top + h * .04));
      final raios = Path()
        ..moveTo(boca.left + boca.width * .1, boca.center.dy)
        ..lineTo(w * -.05, 0)
        ..lineTo(w * 1.05, 0)
        ..lineTo(boca.right - boca.width * .1, boca.center.dy)
        ..close();
      canvas.drawPath(raios, luz);
    }

    // corpo
    final rCorpo = RRect.fromRectAndCorners(corpo,
        bottomLeft: Radius.circular(w * .06), bottomRight: Radius.circular(w * .06));
    canvas.drawRRect(rCorpo, Paint()..color = corMadeira);
    // tábuas
    final linha = Paint()
      ..color = escura
      ..strokeWidth = math.max(1, w * .012);
    for (final f in [.38, .7]) {
      canvas.drawLine(Offset(corpo.left, corpo.top + corpo.height * f), Offset(corpo.right, corpo.top + corpo.height * f), linha);
    }
    // cintas de metal
    final cinta = Paint()..color = corMetal;
    for (final x in [corpo.left + corpo.width * .14, corpo.right - corpo.width * .14 - w * .07]) {
      canvas.drawRect(Rect.fromLTWH(x, corpo.top, w * .07, corpo.height), cinta);
    }
    canvas.drawRRect(rCorpo, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * .025)
      ..color = escura);

    // tampa: gira pela dobradiça de trás (de frente, sobe e encurta)
    canvas.save();
    canvas.translate(dobradica.dx, dobradica.dy);
    canvas.translate(0, -h * .1 * a);
    canvas.scale(1, 1 - .55 * a);
    canvas.translate(-dobradica.dx, -dobradica.dy);
    final tampa = Rect.fromLTWH(corpo.left - w * .02, h * .22, corpo.width + w * .04, corpo.top - h * .22 + h * .02);
    final rTampa = RRect.fromRectAndCorners(tampa,
        topLeft: Radius.circular(w * .2), topRight: Radius.circular(w * .2),
        bottomLeft: Radius.circular(w * .02), bottomRight: Radius.circular(w * .02));
    canvas.drawRRect(rTampa, Paint()..color = escurecer(corMadeira, quanto: -.08));
    for (final x in [tampa.left + tampa.width * .15, tampa.right - tampa.width * .15 - w * .07]) {
      canvas.drawRect(Rect.fromLTWH(x, tampa.top + h * .015, w * .07, tampa.height - h * .015), cinta);
    }
    canvas.drawRRect(rTampa, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.5, w * .025)
      ..color = escura);
    canvas.restore();

    // fechadura (só com a tampa baixa)
    if (a < .5) {
      final c = Offset(w / 2, corpo.top + h * .02);
      final placa = RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: w * .17, height: h * .18), Radius.circular(w * .03));
      canvas.drawRRect(placa, Paint()..color = corMetal.withValues(alpha: 1 - a * 2));
      canvas.drawCircle(c.translate(0, -h * .015), w * .022, Paint()..color = escura.withValues(alpha: 1 - a * 2));
      canvas.drawRect(Rect.fromCenter(center: c.translate(0, h * .025), width: w * .016, height: h * .05),
          Paint()..color = escura.withValues(alpha: 1 - a * 2));
    }
  }

  @override
  bool shouldRepaint(covariant BauPainter old) =>
      old.abertura != abertura || old.brilho != brilho || old.trancado != trancado || old.madeira != madeira ||
      old.metal != metal;
}

// ---------------------------------------------------------------------------
// Chama do combo
// ---------------------------------------------------------------------------

/// 🔥 + o número de acertos seguidos. Some abaixo de [minimo]; a chama cresce com o combo e dá um
/// pulinho (uma vez) a cada acerto.
class ChamaCombo extends StatefulWidget {
  final int n;
  final double tamanho;
  final int minimo;

  const ChamaCombo({super.key, required this.n, this.tamanho = 26, this.minimo = 3});

  @override
  State<ChamaCombo> createState() => _ChamaComboState();
}

class _ChamaComboState extends State<ChamaCombo> with SingleTickerProviderStateMixin {
  // criado já no initState: preguiçoso, um ChamaCombo que saísse da árvore sem nunca acender o
  // criaria no dispose (ticker num contexto desativado → exceção)
  late final AnimationController _pulo;

  @override
  void initState() {
    super.initState();
    _pulo = AnimationController(vsync: this, duration: const Duration(milliseconds: 260), value: 1);
  }

  @override
  void didUpdateWidget(covariant ChamaCombo old) {
    super.didUpdateWidget(old);
    if (widget.n > old.n && widget.n >= widget.minimo) _pulo.forward(from: 0);
  }

  @override
  void dispose() {
    _pulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.n < widget.minimo) return const SizedBox.shrink();
    final forca = ((widget.n - widget.minimo) / 7).clamp(0.0, 1.0);
    final t = widget.tamanho * (1 + .25 * forca);
    final corNumero = escurecer(CoresFesta.ambar, quanto: .2, soNoClaro: true);
    return Semantics(
      label: '${widget.n} acertos seguidos',
      child: AnimatedBuilder(
        animation: _pulo,
        builder: (_, child) {
          final p = Curves.easeOut.transform(_pulo.value);
          final s = 1 + .3 * math.sin(p * math.pi);
          return Transform.scale(scale: s, child: child);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomPaint(size: Size(t * .78, t), painter: _ChamaPainter(forca)),
            const SizedBox(width: 3),
            Text('${widget.n}', style: Mixart.display(size: widget.tamanho * .72, weight: FontWeight.w800, color: corNumero)),
          ],
        ),
      ),
    );
  }
}

class _ChamaPainter extends CustomPainter {
  final double forca;
  _ChamaPainter(this.forca);

  Path _gota(Size s, double escala, double dy) {
    final w = s.width * escala, h = s.height * escala;
    final x0 = (s.width - w) / 2, y0 = s.height - h + dy;
    return Path()
      ..moveTo(x0 + w * .5, y0)
      ..cubicTo(x0 + w * .62, y0 + h * .25, x0 + w * 1.02, y0 + h * .45, x0 + w * .95, y0 + h * .7)
      ..cubicTo(x0 + w * .9, y0 + h * .95, x0 + w * .7, y0 + h, x0 + w * .5, y0 + h)
      ..cubicTo(x0 + w * .3, y0 + h, x0 + w * .1, y0 + h * .95, x0 + w * .05, y0 + h * .7)
      ..cubicTo(x0 - w * .02, y0 + h * .45, x0 + w * .3, y0 + h * .35, x0 + w * .5, y0)
      ..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fora = Color.lerp(const Color(0xFFFF7A1A), const Color(0xFFFF3D3D), forca)!;
    canvas.drawPath(
      _gota(size, 1, 0),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [fora, const Color(0xFFFFB020)],
        ).createShader(rect),
    );
    canvas.drawPath(_gota(size, .55, -size.height * .04), Paint()..color = const Color(0xFFFFE680));
  }

  @override
  bool shouldRepaint(covariant _ChamaPainter old) => old.forca != forca;
}
