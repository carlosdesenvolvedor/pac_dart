import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../preview/preview_engine.dart';
import '../../domain/curriculo.dart';

class _TagModo extends StatelessWidget {
  final PreviewModo modo;
  const _TagModo({required this.modo});

  @override
  Widget build(BuildContext context) {
    final (rotulo, cor) = switch (modo) {
      PreviewModo.vivo => ('AO VIVO', const Color(0xFF5FC66E)),
      PreviewModo.demo => ('DEMO REAL', const Color(0xFF64B5F6)),
      PreviewModo.conceito => ('CONCEITO', Mixart.brand),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: .14),
        border: Border.all(color: cor.withValues(alpha: .3)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(rotulo, style: Mixart.mono(size: 10, weight: FontWeight.w600, color: cor)),
    );
  }
}

/// Moldura de celular com a prévia do widget — aparece ao compilar
/// (só nos exercícios da trilha Flutter).
class PreviewPanel extends StatelessWidget {
  final Trecho trecho;
  const PreviewPanel({super.key, required this.trecho});

  @override
  Widget build(BuildContext context) {
    final res = PreviewEngine.gerar(trecho.cod, trecho.dicaPlana);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Mixart.slide,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, -10 * (1 - t)), child: child),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Mixart.bg,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          // cabeçalho estilo janela
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: Mixart.surface,
              border: Border(bottom: BorderSide(color: Mixart.border)),
              borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusMd)),
            ),
            child: Row(children: [
              for (final c in const [Color(0xFFF2555A), Color(0xFFFFC73B), Color(0xFF3FB950)])
                Container(
                    width: 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text('Prévia Flutter', style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted)),
              const Spacer(),
              _TagModo(modo: res.modo),
            ]),
          ),
          // o "celular"
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
            child: Container(
              width: 300,
              constraints: const BoxConstraints(minHeight: 210, maxHeight: 440),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF1B1B1B), width: 7),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF333333), blurRadius: 0, spreadRadius: 1),
                  BoxShadow(color: Colors.black87, blurRadius: 50, offset: Offset(0, 26)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17),
                child: Theme(
                  data: ThemeData(
                    brightness: Brightness.light,
                    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
                    useMaterial3: true,
                  ),
                  child: Material(
                    color: const Color(0xFFFAFAFA),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: DefaultTextStyle(
                          style: const TextStyle(color: Color(0xFF212121), fontSize: 14),
                          child: res.widget,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
