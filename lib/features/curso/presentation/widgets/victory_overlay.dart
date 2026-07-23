import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../bloc/curso_bloc.dart';
import '../bloc/typing_bloc.dart';

/// Overlay de vitória ao concluir a lição. Emenda direto no quiz: mostra o
/// placar e uma barrinha de contagem enquanto o quiz não abre sozinho — dá
/// para começar na hora (Enter), pular o quiz ou repetir a lição.
class VictoryOverlay extends StatelessWidget {
  /// Tempo até o quiz abrir sozinho (null = a lição não tem quiz).
  final Duration? esperaAuto;

  /// Quantos projetos "Mão na Massa" vêm depois do quiz.
  final int projetosDepois;

  final VoidCallback onQuiz, onPularQuiz, onRepetir;

  const VictoryOverlay({
    super.key,
    required this.esperaAuto,
    required this.projetosDepois,
    required this.onQuiz,
    required this.onPularQuiz,
    required this.onRepetir,
  });

  bool get _temQuiz => esperaAuto != null;

  @override
  Widget build(BuildContext context) {
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
          padding: const EdgeInsets.all(20),
          // rola quando o palco é baixo (celular / lição curta)
          child: Center(child: SingleChildScrollView(child: _conteudo(context))),
        ),
      ),
    );
  }

  Widget _conteudo(BuildContext context) {
    final typing = context.watch<TypingBloc>().state;
    final curso = context.watch<CursoBloc>().state;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text('LIÇÃO CONCLUÍDA!', style: Mixart.display(size: 30, color: Mixart.brand)),
      const SizedBox(height: 8),
      Text('${curso.licao.emoji}  ${curso.licao.nome} — ${curso.trilha.nivel}',
          style: Mixart.ui(size: 13, color: Mixart.textMuted)),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
        _Placar('PPM', '${typing.ppm(DateTime.now())}'),
        _Placar('PRECISÃO', '${typing.precisao}%'),
        _Placar('SCORE', '${typing.score}'),
      ]),
      if (_temQuiz) ...[
        const SizedBox(height: 18),
        _Contagem(espera: esperaAuto!),
      ],
      const SizedBox(height: 16),
      Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
          ),
          onPressed: _temQuiz ? onQuiz : onPularQuiz,
          child: Text(_temQuiz ? 'Fazer o quiz agora →' : 'Continuar →'),
        ),
        if (_temQuiz)
          OutlinedButton(style: _contorno(), onPressed: onPularQuiz, child: const Text('Pular quiz')),
        OutlinedButton(style: _contorno(), onPressed: onRepetir, child: const Text('Repetir')),
      ]),
      if (projetosDepois > 0) ...[
        const SizedBox(height: 14),
        Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.construction, size: 14, color: Mixart.brand),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              projetosDepois == 1
                  ? 'Trilha no fim! Depois vem 1 app do Mão na Massa.'
                  : 'Trilha no fim! Depois vêm $projetosDepois apps do Mão na Massa.',
              textAlign: TextAlign.center,
              style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.brand),
            ),
          ),
        ]),
      ],
      const SizedBox(height: 14),
      Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Mixart.brandDim),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('↵', style: Mixart.mono(size: 12, color: Mixart.brand)),
        ),
        const SizedBox(width: 8),
        Text(_temQuiz ? 'Enter começa o quiz agora' : 'Enter para a próxima lição',
            style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted)),
      ]),
    ]);
  }

  ButtonStyle _contorno() => OutlinedButton.styleFrom(
        foregroundColor: Mixart.text,
        side: BorderSide(color: Mixart.border),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        textStyle: Mixart.ui(size: 13),
      );
}

/// Barrinha que esvazia até o quiz abrir sozinho.
class _Contagem extends StatelessWidget {
  final Duration espera;
  const _Contagem({required this.espera});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Column(children: [
          Text('O quiz da lição começa em seguida…',
              style: Mixart.ui(size: 12, color: Mixart.textMuted)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: espera,
              curve: Curves.linear,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 5,
                backgroundColor: Mixart.surfaceHi,
                color: Mixart.brand,
              ),
            ),
          ),
        ]),
      );
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
