import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// Botão discreto de "pular esta etapa" — usado no quiz e nos projetos
/// quando eles vêm emendados depois da lição.
class BotaoPular extends StatelessWidget {
  final String rotulo;
  final VoidCallback onTap;
  const BotaoPular({super.key, required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Mixart.surfaceHi,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(rotulo,
                style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted)),
            const SizedBox(width: 5),
            Icon(Icons.skip_next, size: 15, color: Mixart.textMuted),
          ]),
        ),
      );
}
