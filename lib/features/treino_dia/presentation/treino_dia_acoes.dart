import 'package:flutter/material.dart';

import 'treino_dia_cubit.dart';
import 'treino_dia_page.dart';

/// Abre o "⚡ Treino do dia" (HUD e cartão do mapa). Sem [TreinoDiaCubit] (testes de tela antigos)
/// não faz nada.
Future<void> abrirTreinoDoDia(BuildContext c) async {
  if (TreinoDiaCubit.de(c) == null) return;
  await Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => const TreinoDiaPage()));
}
