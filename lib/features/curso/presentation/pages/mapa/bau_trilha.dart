// O baú do fim de cada unidade do PAC·ENGLISH: trancado até a última lição, pronto (balança e brilha) e
// aberto depois de treinar as palavras da unidade. Abrir mostra a tampa subindo, confete, fanfarra e as
// palavras em leque; "Treinar as palavras" leva à sessão de treino.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/som/sons.dart';
import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../../ingles/domain/palavras_novas.dart';
import '../../../domain/mapa_regras.dart';
import 'no_3d.dart' show FocoDeTeclado;

/// O baú no caminho. Toque: pronto → abre; trancado/aberto → [onTap] decide (o mapa mostra um aviso ou
/// deixa treinar de novo).
class BauTrilha extends StatefulWidget {
  final EstadoBau estado;
  final int palavras;
  final Color cor;
  final VoidCallback onTap;

  /// Pronto e [balancar]: balança chamando. Só um baú do mapa balança (os outros prontos ficam parados,
  /// só com o brilho), para não deixar dezenas de animações rodando sem parar.
  final bool balancar;

  const BauTrilha({
    super.key,
    required this.estado,
    required this.palavras,
    required this.cor,
    required this.onTap,
    this.balancar = true,
  });

  static const largura = 84.0, altura = 72.0;

  @override
  State<BauTrilha> createState() => _BauTrilhaState();
}

class _BauTrilhaState extends State<BauTrilha> with SingleTickerProviderStateMixin {
  AnimationController? _balanco; // só enquanto está pronto (e é o baú que balança)
  bool _foco = false; // anel de foco do teclado

  @override
  void initState() {
    super.initState();
    _ajustar();
  }

  @override
  void didUpdateWidget(covariant BauTrilha old) {
    super.didUpdateWidget(old);
    _ajustar();
  }

  void _ajustar() {
    if (widget.estado == EstadoBau.pronto && widget.balancar) {
      _balanco ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    } else if (_balanco != null) {
      _balanco!.dispose();
      _balanco = null;
    }
  }

  @override
  void dispose() {
    _balanco?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = widget.estado;
    final legenda = switch (estado) {
      EstadoBau.trancado => '🔒 ${widget.palavras} palavras',
      EstadoBau.pronto => 'ABRIR BAÚ!',
      EstadoBau.aberto => '✓ ${widget.palavras} palavras',
    };
    // camada própria: o balanço só recompõe a camada, sem repintar o baú a cada quadro
    Widget bau = RepaintBoundary(
      child: CustomPaint(
        size: const Size(BauTrilha.largura, BauTrilha.altura),
        painter: BauPainter(
          trancado: estado == EstadoBau.trancado,
          abertura: estado == EstadoBau.aberto ? .85 : 0,
          brilho: estado == EstadoBau.pronto ? 1 : 0,
        ),
      ),
    );
    if (estado == EstadoBau.trancado) bau = Opacity(opacity: .7, child: bau);
    final b = _balanco;
    if (b != null) {
      final base = bau;
      // balança 3 vezes e descansa (como um presente chamando)
      bau = AnimatedBuilder(
        animation: b,
        builder: (context, child) {
          final v = b.value;
          final giro = v < .45 ? math.sin(v / .45 * math.pi * 3) * .09 * (1 - v / .45) : 0.0;
          final pulo = v < .45 ? -3 * math.sin(v / .45 * math.pi).abs() : 0.0;
          return Transform.translate(
            offset: Offset(0, pulo),
            child: Transform.rotate(angle: giro, alignment: Alignment.bottomCenter, child: child),
          );
        },
        child: base,
      );
      bau = RepaintBoundary(child: bau);
    }
    final pronto = estado == EstadoBau.pronto;
    void tocar() {
      Sons.toca(pronto ? Som.fase : Som.blip);
      widget.onTap();
    }

    return Semantics(
      button: true,
      label: switch (estado) {
        EstadoBau.trancado => 'Baú da unidade, trancado',
        EstadoBau.pronto => 'Abrir o baú da unidade',
        EstadoBau.aberto => 'Baú da unidade, aberto',
      },
      child: FocoDeTeclado(
        onAtivar: tocar,
        onFoco: (v) => setState(() => _foco = v),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: tocar,
          child: ExcludeSemantics(
            child: Stack(clipBehavior: Clip.none, children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              bau,
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: pronto ? CoresFesta.ouro : Mixart.surface,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: pronto ? const Color(0xFFC98F12) : Mixart.border),
                ),
                child: Text(
                  legenda,
                  style: Mixart.ui(
                    size: 10.5,
                    weight: FontWeight.w800,
                    color: pronto ? const Color(0xFF3A2500) : Mixart.textMuted,
                  ).copyWith(letterSpacing: pronto ? .8 : 0),
                ),
              ),
            ]),
            // anel de foco do teclado (por fora, sem mexer no tamanho)
            if (_foco)
              Positioned(
                left: -6,
                top: -6,
                right: -6,
                bottom: -6,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Mixart.text, width: 2.5),
                    ),
                  ),
                ),
              ),
          ]),
          ),
        ),
      ),
    );
  }
}

/// Abre o baú: tampa sobe, confete, fanfarra, 'Unidade dominada!' e as [palavras] em leque. Devolve true
/// quando a pessoa escolheu "Treinar as palavras" (quem chama abre a sessão).
Future<bool> abrirBauTrilha(
  BuildContext context, {
  required String unidade,
  required List<PalavraNova> palavras,
  required Color cor,
  bool jaAberto = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: .6),
    builder: (_) => _DialogoBau(unidade: unidade, palavras: palavras, cor: cor, jaAberto: jaAberto),
  );
  return r == true;
}

class _DialogoBau extends StatefulWidget {
  final String unidade;
  final List<PalavraNova> palavras;
  final Color cor;
  final bool jaAberto;
  const _DialogoBau({required this.unidade, required this.palavras, required this.cor, required this.jaAberto});

  @override
  State<_DialogoBau> createState() => _DialogoBauState();
}

class _DialogoBauState extends State<_DialogoBau> with SingleTickerProviderStateMixin {
  late final AnimationController _abre =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();

  @override
  void initState() {
    super.initState();
    if (!widget.jaAberto) Sons.toca(Som.fanfarra);
  }

  @override
  void dispose() {
    _abre.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mostrar = widget.palavras.take(12).toList();
    return Dialog(
      backgroundColor: Mixart.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        side: BorderSide(color: Mixart.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Stack(children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AnimatedBuilder(
                animation: _abre,
                builder: (context, _) {
                  final a = Curves.easeOutBack.transform(((_abre.value - .1) / .35).clamp(0.0, 1.0));
                  return CustomPaint(
                    size: const Size(150, 128),
                    painter: BauPainter(abertura: a.clamp(0.0, 1.0), brilho: 1 - a * .4),
                  );
                },
              ),
              const SizedBox(height: 6),
              Text(widget.jaAberto ? 'Palavras da unidade' : 'Unidade dominada!',
                  textAlign: TextAlign.center, style: Mixart.display(size: 22)),
              const SizedBox(height: 4),
              Text(
                '${widget.unidade} · ${widget.palavras.length} palavras novas. Treine e elas vão para os seus jogos do Arcade 🎮',
                textAlign: TextAlign.center,
                style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < mostrar.length; i++)
                    AnimatedBuilder(
                      animation: _abre,
                      builder: (context, child) {
                        final ini = .35 + i * .04;
                        final v = Curves.easeOutBack.transform(((_abre.value - ini) / .3).clamp(0.0, 1.0));
                        return Opacity(
                          opacity: v.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - v)),
                            child: Transform.rotate(angle: (i.isEven ? -1 : 1) * .06 * (1 - v), child: child),
                          ),
                        );
                      },
                      child: _CartaPalavra(palavra: mostrar[i], cor: widget.cor),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Botao3D(
                key: const Key('bau-treinar'),
                rotulo: '🎯 Treinar as palavras',
                cor: widget.cor,
                onTap: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Depois', style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.textMuted)),
              ),
            ]),
          ),
          if (!widget.jaAberto)
            Positioned.fill(child: Confete(quantidade: 46, origem: const Alignment(0, -.55), duracao: const Duration(milliseconds: 1700))),
        ]),
      ),
    );
  }
}

class _CartaPalavra extends StatelessWidget {
  final PalavraNova palavra;
  final Color cor;
  const _CartaPalavra({required this.palavra, required this.cor});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(11, 7, 11, 8),
        decoration: BoxDecoration(
          color: Mixart.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: cor, width: 1.5),
            top: BorderSide(color: cor, width: 1.5),
            right: BorderSide(color: cor, width: 1.5),
            bottom: BorderSide(color: cor, width: 3.5),
          ),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(palavra.en, style: Mixart.mono(size: 14, weight: FontWeight.w700, color: Mixart.text)),
          if (palavra.pt.isNotEmpty)
            Text(palavra.pt, style: Mixart.ui(size: 11, color: Mixart.textMuted)),
        ]),
      );
}
