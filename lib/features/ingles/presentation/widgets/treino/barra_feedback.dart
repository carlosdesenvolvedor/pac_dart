import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';

/// Como saiu a resposta: certa (verde), quase (âmbar: um errinho de digitação) ou errada (vermelha).
enum TomFeedback { certo, quase, errado }

/// A barra que sobe depois de cada resposta: "Mandou bem!" ou "Resposta: apple — maçã", e o botão
/// CONTINUAR (Enter também segue — quem cuida da tecla é a página).
class BarraFeedback extends StatelessWidget {
  final TomFeedback tom;
  final String titulo;
  final String? detalhe;
  final VoidCallback onContinuar;

  const BarraFeedback({
    super.key,
    required this.tom,
    required this.titulo,
    this.detalhe,
    required this.onContinuar,
  });

  @override
  Widget build(BuildContext context) {
    final cor = switch (tom) {
      TomFeedback.certo => escurecer(CoresFesta.verde, quanto: .2, soNoClaro: true),
      TomFeedback.quase => escurecer(CoresFesta.ambar, quanto: .2, soNoClaro: true),
      TomFeedback.errado => Mixart.danger,
    };
    final icone = switch (tom) {
      TomFeedback.certo => Icons.check_rounded,
      TomFeedback.quase => Icons.priority_high_rounded,
      TomFeedback.errado => Icons.close_rounded,
    };
    return TweenAnimationBuilder<double>(
      key: const Key('treino-feedback'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Mixart.spring,
      builder: (_, t, filho) => FractionalTranslation(translation: Offset(0, 1 - t), child: filho),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.alphaBlend(cor.withValues(alpha: .13), Mixart.surface),
          border: Border(top: BorderSide(color: cor.withValues(alpha: .7), width: 2)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: LayoutBuilder(builder: (context, c) {
              final estreito = c.maxWidth < 560;
              final textos = Row(children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
                  child: Icon(icone, color: corSobre(cor), size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(titulo, style: Mixart.display(size: 20, weight: FontWeight.w800, color: cor)),
                    if (detalhe != null && detalhe!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(detalhe!,
                          style: Mixart.ui(size: 14, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.35)),
                    ],
                  ]),
                ),
              ]);
              final botao = Botao3D(
                key: const Key('treino-continuar'),
                rotulo: 'CONTINUAR',
                cor: cor,
                altura: 48,
                onTap: onContinuar,
              );
              if (estreito) {
                return Column(mainAxisSize: MainAxisSize.min, children: [textos, const SizedBox(height: 14), botao]);
              }
              return Row(children: [
                Expanded(child: textos),
                const SizedBox(width: 20),
                SizedBox(width: 220, child: botao),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
