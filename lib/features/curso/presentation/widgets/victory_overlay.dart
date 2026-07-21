import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../bloc/curso_bloc.dart';
import '../bloc/typing_bloc.dart';

/// Overlay de vitória ao concluir a lição.
class VictoryOverlay extends StatelessWidget {
  const VictoryOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final typing = context.watch<TypingBloc>().state;
    final curso = context.watch<CursoBloc>().state;
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Mixart.spring,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xED010101),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('LIÇÃO CONCLUÍDA!', style: Mixart.display(size: 30, color: Mixart.brand)),
            const SizedBox(height: 8),
            Text('${curso.licao.emoji}  ${curso.licao.nome} — ${curso.trilha.nivel}',
                style: Mixart.ui(size: 13, color: Mixart.textMuted)),
            const SizedBox(height: 22),
            Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
              _Placar('PPM', '${typing.ppm(DateTime.now())}'),
              _Placar('PRECISÃO', '${typing.precisao}%'),
              _Placar('SCORE', '${typing.score}'),
            ]),
            const SizedBox(height: 24),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Mixart.brand,
                  foregroundColor: Mixart.onBrand,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
                ),
                onPressed: () => context.read<CursoBloc>().add(const ProximaLicaoPedida()),
                child: const Text('Próxima lição →'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Mixart.text,
                  side: const BorderSide(color: Mixart.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: Mixart.ui(size: 13),
                ),
                onPressed: () => context.read<CursoBloc>().add(const LicaoRepetida()),
                child: const Text('Repetir'),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Placar extends StatelessWidget {
  final String k, v;
  const _Placar(this.k, this.v);
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 92),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          Text(k, style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.textMuted).copyWith(letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(v, style: Mixart.display(size: 19)),
        ]),
      );
}
