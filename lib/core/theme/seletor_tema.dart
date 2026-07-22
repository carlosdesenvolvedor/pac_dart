import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'mixart.dart';
import 'theme_cubit.dart';

/// Botão que abre um menu para trocar a paleta de cores do app.
class SeletorTema extends StatelessWidget {
  /// Se true, mostra só o ícone (para a tela de login); senão, um botão pílula.
  final bool compacto;
  const SeletorTema({super.key, this.compacto = false});

  @override
  Widget build(BuildContext context) {
    final atual = context.watch<ThemeCubit>().state;
    return PopupMenuButton<Paleta>(
      tooltip: 'Trocar tema',
      color: atual.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        side: BorderSide(color: Mixart.border),
      ),
      offset: const Offset(0, 46),
      onSelected: (p) => context.read<ThemeCubit>().trocar(p),
      itemBuilder: (context) => [
        for (final p in Paleta.todas)
          PopupMenuItem<Paleta>(
            value: p,
            child: Row(children: [
              _Amostra(paleta: p),
              const SizedBox(width: 11),
              Text(p.nome,
                  style: Mixart.ui(
                      size: 13,
                      weight: p == atual ? FontWeight.w700 : FontWeight.w500,
                      color: Mixart.text)),
              const Spacer(),
              if (p == atual) Icon(Icons.check, size: 16, color: Mixart.brand),
            ]),
          ),
      ],
      child: compacto
          ? Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Mixart.surface,
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(999),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.palette_outlined, size: 18, color: Mixart.textMuted),
            )
          : Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Mixart.surfaceHi,
                border: Border.all(color: Mixart.border),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.palette_outlined, size: 17, color: Mixart.textMuted),
                const SizedBox(width: 7),
                Text('Tema', style: Mixart.ui(size: 13, weight: FontWeight.w500, color: Mixart.textMuted)),
              ]),
            ),
    );
  }
}

/// Mini-amostra da paleta: fundo + acento.
class _Amostra extends StatelessWidget {
  final Paleta paleta;
  const _Amostra({required this.paleta});

  @override
  Widget build(BuildContext context) => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: paleta.bg,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Mixart.border),
        ),
        alignment: Alignment.center,
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: paleta.brand, shape: BoxShape.circle),
        ),
      );
}
