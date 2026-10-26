// O nó "de apertar" do mapa do PAC·ENGLISH (estilo Duolingo): uma face redonda sobre um lábio mais
// escuro, que afunda ao tocar. Só o nó atual tem animação contínua (pula e pulsa, de UM controlador); um
// nó recém-concluído dá um "pop" de uma vez só.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/som/sons.dart';
import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../domain/mapa_regras.dart';
import '../../widgets/pacman.dart';

class No3D extends StatefulWidget {
  final String emoji;
  final EstadoNo estado;

  /// A cor da etapa (A1 verde, A2 céu…): face do nó atual.
  final Color cor;

  /// Quantas palavras novas a lição apresenta (o selo '🆕 N' aparece com 2 ou mais, se não estiver feita).
  final int novas;

  /// Pop de comemoração (0,6 → 1,15 → 1) ao aparecer: a lição acabou de ser concluída.
  final bool celebrar;
  final VoidCallback onTap;

  /// Nome para leitores de tela (o rótulo lido junta o estado e as estrelas, ver [rotuloLido]).
  final String rotulo;

  /// Estrelas da nota do quiz (0–3); null = sem nota.
  final int? estrelas;

  /// 🪜 As partes (sub-lições) da lição e quantas já foram concluídas: o anel em volta do nó, um pedaço por parte
  /// (como o Duolingo). 0 ou 1 parte = sem anel.
  final int partes, partesFeitas;

  const No3D({
    super.key,
    required this.emoji,
    required this.estado,
    required this.cor,
    required this.onTap,
    this.novas = 0,
    this.celebrar = false,
    this.rotulo = '',
    this.estrelas,
    this.partes = 0,
    this.partesFeitas = 0,
  });

  /// O que o leitor de tela anuncia: o nome, o estado e as estrelas ("No café, concluída, 3 de 3 estrelas").
  String get rotuloLido {
    final partes = <String>[
      if (rotulo.isNotEmpty) rotulo,
      switch (estado) {
        EstadoNo.feita => 'concluída',
        EstadoNo.atual => 'lição atual',
        EstadoNo.disponivel => 'disponível',
        EstadoNo.trancada => 'mais adiante, trancada',
      },
      if (estrelas != null) '${estrelas!.clamp(0, 3)} de 3 estrelas',
      if (this.partes > 1 && estado != EstadoNo.feita && partesFeitas > 0) '$partesFeitas de ${this.partes} partes feitas',
      if (novas >= 2 && estado != EstadoNo.feita) '$novas palavras novas',
    ];
    return partes.join(', ');
  }

  /// Diâmetro da face e altura do lábio (o nó ocupa [tamanho] × ([tamanho] + [labio])).
  static const tamanho = 64.0;
  static const labio = 6.0;

  @override
  State<No3D> createState() => _No3DState();
}

class _No3DState extends State<No3D> with TickerProviderStateMixin {
  AnimationController? _vida; // pulo + anel (só o atual)
  AnimationController? _pop; // comemoração (uma vez)
  bool _apertado = false;
  bool _foco = false; // anel de foco do teclado

  bool get _atual => widget.estado == EstadoNo.atual;

  @override
  void initState() {
    super.initState();
    if (_atual) _ligarVida();
    if (widget.celebrar) _estourar();
  }

  void _ligarVida() {
    _vida ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  }

  void _estourar() {
    (_pop ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 700))).forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant No3D old) {
    super.didUpdateWidget(old);
    if (_atual && _vida == null) {
      _ligarVida();
    } else if (!_atual && _vida != null) {
      _vida!.dispose();
      _vida = null;
    }
    if (widget.celebrar && !old.celebrar) _estourar();
  }

  @override
  void dispose() {
    _vida?.dispose();
    _pop?.dispose();
    super.dispose();
  }

  void _tocar() {
    Sons.toca(Som.blip);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    const tam = No3D.tamanho;
    final claro = Mixart.atual.ehClaro;
    final estado = widget.estado;

    // cores da face e do lábio
    final Color face, labio;
    Gradient? gradiente;
    switch (estado) {
      case EstadoNo.feita:
        face = CoresFesta.ouro;
        labio = const Color(0xFFC98F12);
        gradiente = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFDC6E), CoresFesta.ouro],
        );
      case EstadoNo.atual:
        face = widget.cor;
        labio = escurecer(widget.cor, quanto: .32);
        gradiente = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(widget.cor, Colors.white, .18)!, widget.cor],
        );
      case EstadoNo.disponivel:
        face = claro ? const Color(0xFFE6E8EC) : const Color(0xFF34373D);
        labio = claro ? const Color(0xFFC3C7CF) : const Color(0xFF1E2024);
      case EstadoNo.trancada:
        face = claro ? const Color(0xFFEDEEF1) : const Color(0xFF26282C);
        labio = claro ? const Color(0xFFD3D6DC) : const Color(0xFF161719);
    }

    final Widget miolo = switch (estado) {
      EstadoNo.feita => Icon(Icons.check_rounded, size: 34, color: Colors.white, shadows: const [
          Shadow(color: Color(0x66A06A00), offset: Offset(0, 1.5), blurRadius: 0),
        ]),
      // o Pac-Man é sempre da cor da marca: um "furo" no fundo da tela por baixo garante o contraste em
      // qualquer cor de etapa (inclusive a trilha própria, que usa a própria cor da marca)
      EstadoNo.atual => Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Mixart.bg,
            shape: BoxShape.circle,
            border: Border.all(color: labio, width: 2),
          ),
          child: const Pacman(tamanho: 28),
        ),
      EstadoNo.disponivel => Text(widget.emoji, style: const TextStyle(fontSize: 26)),
      EstadoNo.trancada => Opacity(
          opacity: .45,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(_cinza),
            child: Text(widget.emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
    };

    final desce = _apertado ? 4.0 : 0.0;
    final rosto = AnimatedPositioned(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      left: 0,
      top: desce,
      child: Container(
        width: tam,
        height: tam,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: gradiente == null ? face : null,
          gradient: gradiente,
          shape: BoxShape.circle,
          border: estado == EstadoNo.disponivel || estado == EstadoNo.trancada
              ? Border.all(color: labio.withValues(alpha: claro ? .9 : .7), width: 1.5)
              : null,
        ),
        child: miolo,
      ),
    );

    Widget no = SizedBox(
      width: tam,
      height: tam + No3D.labio,
      child: Stack(clipBehavior: Clip.none, children: [
        // lábio: a "espessura" do botão
        Positioned(
          left: 0,
          top: No3D.labio,
          child: Container(
            width: tam,
            height: tam,
            decoration: BoxDecoration(color: labio, shape: BoxShape.circle),
          ),
        ),
        // 🪜 o anel das partes (só com 2+ partes, fora das trancadas e das feitas: a feita já é o ouro inteiro)
        if (widget.partes > 1 && estado != EstadoNo.trancada && estado != EstadoNo.feita)
          Positioned(
            left: -7,
            top: desce - 7,
            child: IgnorePointer(
              child: CustomPaint(
                key: const Key('no-partes'),
                size: const Size(tam + 14, tam + 14),
                painter: _AnelPartes(
                  partes: widget.partes,
                  feitas: widget.partesFeitas.clamp(0, widget.partes),
                  cor: estado == EstadoNo.atual ? widget.cor : CoresFesta.ouro,
                  fundo: claro ? const Color(0x22000000) : const Color(0x33FFFFFF),
                ),
              ),
            ),
          ),
        rosto,
        if (_foco)
          Positioned(
            left: -5,
            top: desce - 5,
            child: IgnorePointer(
              child: Container(
                width: tam + 10,
                height: tam + 10,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Mixart.text, width: 3)),
              ),
            ),
          ),
        if (estado == EstadoNo.trancada)
          Positioned(
            right: -4,
            bottom: -2,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Mixart.surface,
                shape: BoxShape.circle,
                border: Border.all(color: Mixart.border, width: 1.5),
              ),
              child: const Text('🔒', style: TextStyle(fontSize: 11)),
            ),
          ),
        if (widget.novas >= 2 && estado != EstadoNo.feita)
          Positioned(
            right: -12,
            top: -6,
            child: _SeloNovas(n: widget.novas, cor: estado == EstadoNo.trancada ? Mixart.textFaint : widget.cor),
          ),
      ]),
    );

    // atual: anel pulsante atrás + pulinho, do MESMO controlador
    final vida = _vida;
    if (vida != null) {
      final base = no;
      no = AnimatedBuilder(
        animation: vida,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(vida.value);
          final anel = tam + 16 + t * 12;
          return Stack(clipBehavior: Clip.none, alignment: Alignment.topCenter, children: [
            Positioned(
              top: (tam + No3D.labio) / 2 - anel / 2,
              left: tam / 2 - anel / 2,
              child: IgnorePointer(
                child: Container(
                  width: anel,
                  height: anel,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.cor.withValues(alpha: .55 - t * .4), width: 3),
                  ),
                ),
              ),
            ),
            Transform.translate(offset: Offset(0, -3 + 6 * (1 - t)), child: child),
          ]);
        },
        child: base,
      );
    }

    final pop = _pop;
    if (pop != null) {
      final base = no;
      no = AnimatedBuilder(
        animation: pop,
        builder: (context, child) => Transform.scale(scale: _escalaPop(pop.value), child: child),
        child: base,
      );
    }

    // o que anima sem parar (o nó atual) ou de uma vez (o pop) repinta só a própria camada, não o mapa
    if (vida != null || pop != null) no = RepaintBoundary(child: no);

    return Semantics(
      button: true,
      selected: _atual,
      label: widget.rotuloLido,
      child: FocoDeTeclado(
        onAtivar: _tocar,
        onFoco: (v) => setState(() => _foco = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _apertado = true),
          onTapCancel: () => setState(() => _apertado = false),
          onTapUp: (_) {
            setState(() => _apertado = false);
            _tocar();
          },
          // o rótulo acima já diz tudo; o toque e o foco continuam na semântica do botão
          child: ExcludeSemantics(child: no),
        ),
      ),
    );
  }

  /// 0,6 → 1,15 (60% do tempo) → 1.
  static double _escalaPop(double v) {
    if (v >= 1) return 1;
    if (v < .6) return .6 + .55 * Curves.easeOut.transform(v / .6);
    return 1.15 - .15 * Curves.easeInOut.transform((v - .6) / .4);
  }

  static const _cinza = <double>[
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    .2126, .7152, .0722, 0, 0, //
    0, 0, 0, 1, 0,
  ];
}

/// Deixa um botão do mapa alcançável pelo teclado (Tab; Enter/Espaço = [onAtivar]), com o cursor de
/// mãozinha, e avisa por [onFoco] quando o anel de foco deve aparecer (o mesmo padrão do Botao3D).
class FocoDeTeclado extends StatelessWidget {
  final VoidCallback onAtivar;
  final ValueChanged<bool> onFoco;
  final Widget child;
  const FocoDeTeclado({super.key, required this.onAtivar, required this.onFoco, required this.child});

  static const _atalhos = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
  };

  @override
  Widget build(BuildContext context) => FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        onShowFocusHighlight: onFoco,
        shortcuts: _atalhos,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
            onAtivar();
            return null;
          }),
        },
        child: child,
      );
}

class _SeloNovas extends StatelessWidget {
  final int n;
  final Color cor;
  const _SeloNovas({required this.n, required this.cor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Mixart.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: cor, width: 1.5),
        ),
        child: Text('🆕 $n', style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.text)),
      );
}

/// As 3 estrelas em arco (um sorriso) embaixo de um nó: [estrelas] cheias de 3.
class EstrelasArco extends StatelessWidget {
  final int estrelas;
  final double tamanho;
  const EstrelasArco({super.key, required this.estrelas, this.tamanho = 15});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$estrelas de 3 estrelas',
        child: CustomPaint(
          size: Size(tamanho * 3.6, tamanho * 1.35),
          painter: _EstrelasPainter(estrelas.clamp(0, 3), Mixart.atual.ehClaro),
        ),
      );
}

class _EstrelasPainter extends CustomPainter {
  final int n;
  final bool claro;
  _EstrelasPainter(this.n, this.claro);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.height / 1.35 / 2;
    final cx = size.width / 2;
    final posicoes = [
      (Offset(cx - r * 2.3, r * 1.0), -.3),
      (Offset(cx, r * 1.35), 0.0),
      (Offset(cx + r * 2.3, r * 1.0), .3),
    ];
    for (var i = 0; i < 3; i++) {
      final (c, giro) = posicoes[i];
      final cheia = i < n;
      final p = _estrela(r * (i == 1 ? 1.12 : 1));
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(giro);
      canvas.drawPath(
        p,
        Paint()..color = cheia ? CoresFesta.ouro : (claro ? const Color(0xFFD9DCE2) : const Color(0xFF2E3136)),
      );
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeJoin = StrokeJoin.round
          ..color = cheia ? const Color(0xFFC98F12) : (claro ? const Color(0xFFBFC4CC) : const Color(0xFF1C1E21)),
      );
      canvas.restore();
    }
  }

  Path _estrela(double r) {
    final p = Path();
    for (var k = 0; k < 10; k++) {
      final raio = k.isEven ? r : r * .48;
      final a = -math.pi / 2 + k * math.pi / 5;
      final o = Offset(math.cos(a) * raio, math.sin(a) * raio);
      k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  @override
  bool shouldRepaint(covariant _EstrelasPainter old) => old.n != n || old.claro != claro;
}

/// 🪜 O anel das partes da lição: um arco por parte, com um respiro entre eles; as feitas na cor, o resto apagado.
class _AnelPartes extends CustomPainter {
  final int partes, feitas;
  final Color cor, fundo;
  const _AnelPartes({required this.partes, required this.feitas, required this.cor, required this.fundo});

  @override
  void paint(Canvas canvas, Size size) {
    const espessura = 4.0;
    final r = Rect.fromLTWH(espessura / 2, espessura / 2, size.width - espessura, size.height - espessura);
    final fatia = 2 * math.pi / partes;
    final folga = math.min(.14, fatia * .18);
    for (var i = 0; i < partes; i++) {
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = espessura
        ..strokeCap = StrokeCap.round
        ..color = i < feitas ? cor : fundo;
      canvas.drawArc(r, -math.pi / 2 + i * fatia + folga / 2, fatia - folga, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _AnelPartes old) =>
      old.partes != partes || old.feitas != feitas || old.cor != cor || old.fundo != fundo;
}
