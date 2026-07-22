import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// Console que "compila": ocioso enquanto digita, sucesso ao concluir.
class ConsoleView extends StatelessWidget {
  final bool concluido;
  final String out;
  final VoidCallback onProximo;
  const ConsoleView({super.key, required this.concluido, required this.out, required this.onProximo});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: concluido ? Mixart.brand : Mixart.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('CONSOLE',
              style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.textMuted)
                  .copyWith(letterSpacing: 2)),
        ]),
        const SizedBox(height: 6),
        if (!concluido)
          Text('Digite o código acima para compilar…',
              style: Mixart.ui(size: 13, color: Mixart.textHint).copyWith(fontStyle: FontStyle.italic))
        else ...[
          Text('✓ Compilado com sucesso', style: Mixart.mono(size: 13, color: Mixart.textMuted)),
          if (out.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: RichText(
                text: TextSpan(style: Mixart.mono(size: 13), children: [
                  TextSpan(text: '→ ', style: TextStyle(color: Mixart.brand)),
                  TextSpan(text: out),
                ]),
              ),
            ),
          const SizedBox(height: 6),
          _EnterProximo(onTap: onProximo),
        ],
      ]),
    );
  }
}

class _EnterProximo extends StatefulWidget {
  final VoidCallback onTap;
  const _EnterProximo({required this.onTap});
  @override
  State<_EnterProximo> createState() => _EnterProximoState();
}

class _EnterProximoState extends State<_EnterProximo> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1150))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween(begin: 1.0, end: .5).animate(_c),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Mixart.brandDim),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('↵', style: Mixart.mono(size: 12, color: Mixart.brand)),
            ),
            const SizedBox(width: 8),
            Text('Enter para o próximo',
                style: Mixart.ui(size: 13, weight: FontWeight.w600, color: Mixart.brand)),
            const SizedBox(width: 6),
            Icon(Icons.arrow_forward, size: 14, color: Mixart.brand),
          ]),
        ),
      );
}
