import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// Um aviso curto por cima do jogo (ex.: '💡 "because" escapou 2x — anotei pra revanche'): aparece, fica
/// uns segundos e some sozinho — uma animação de uma vez só, sem Timer. Trocou o [texto], toca de novo.
/// É um [Positioned]: vai direto num [Stack].
class AvisoArcade extends StatefulWidget {
  final String texto;

  /// Distância do topo do Stack e das laterais (o aviso centraliza no meio delas).
  final double top;
  final double esquerda;
  final double direita;

  /// Quanto tempo fica na tela (com a entrada e a saída).
  final Duration duracao;

  const AvisoArcade(
    this.texto, {
    super.key,
    this.top = 56,
    this.esquerda = 12,
    this.direita = 12,
    this.duracao = const Duration(milliseconds: 3400),
  });

  @override
  State<AvisoArcade> createState() => _AvisoArcadeState();
}

class _AvisoArcadeState extends State<AvisoArcade> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duracao)..forward();

  @override
  void didUpdateWidget(AvisoArcade old) {
    super.didUpdateWidget(old);
    if (old.texto != widget.texto) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Entra nos primeiros 8%, fica, e sai nos últimos 18%.
  static double _opacidade(double t) => t < .08 ? t / .08 : (t > .82 ? ((1 - t) / .18).clamp(0.0, 1.0) : 1.0);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.top,
      left: widget.esquerda,
      right: widget.direita,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, filho) {
            if (_c.isCompleted) return const SizedBox.shrink();
            final o = _opacidade(_c.value);
            return Opacity(
              opacity: o,
              child: Transform.translate(offset: Offset(0, -6 * (1 - o)), child: filho),
            );
          },
          child: Center(
            child: Container(
              key: const Key('aviso-arcade'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              // O fundo é sempre escuro: texto e borda em amarelo Mixart fixo (o azul da paleta clara não lê
              // aqui). Raio 14, não pílula: no celular o aviso quebra em 2-3 linhas e a pílula vira bolha.
              decoration: BoxDecoration(
                color: const Color(0xE010131A),
                border: Border.all(color: const Color(0x99FFC73B)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(widget.texto,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Mixart.display(size: 14, color: const Color(0xFFFFC73B))),
            ),
          ),
        ),
      ),
    );
  }
}
