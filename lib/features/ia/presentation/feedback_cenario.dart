import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ingles/domain/cartoes_texto.dart';
import '../../ingles/presentation/revisao_cubit.dart';

/// Salva [c] em "Meus cartões" pelo mesmo caminho do "Novo cartão" (a mesma frente só troca o
/// verso, nunca duplica) e, no 1º cartão, liga o inglês → português do baralho.
Future<void> salvarCartaoDoCenario(BuildContext context, CartaoEscrito c) async {
  final bloc = context.read<CursoBloc>();
  final revisao = RevisaoCubit.de(context);
  final primeiraVez = !bloc.state.trilhas.any((t) => t.textoId == idCartoesAvulsos);
  bool noBaralho(CursoState s) => s.trilhas.any((t) =>
      t.textoId == idCartoesAvulsos &&
      t.licoes.any((l) => l.trechos.any((x) => x.cod.toLowerCase() == c.en.toLowerCase() && x.dica == c.pt)));
  // o mesmo cartão (frente e verso) já está lá: o bloc não emite nada — não fica 5 s em "Salvando…"
  final jaEstava = noBaralho(bloc.state);
  bloc.add(CartaoAdicionado(c));
  // espera o cartão aparecer no baralho (o bloc grava antes de atualizar)
  if (!jaEstava) {
    try {
      await bloc.stream.firstWhere(noBaralho).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
  if (primeiraVez && revisao != null) {
    await revisao.mudarConfig(revisao.state.config.comReversos(['txt:$idCartoesAvulsos'], ligar: true));
  }
}

/// Dá para salvar cartões daqui? (sem o [CursoBloc] na árvore — testes de tela — o botão nem aparece)
bool podeSalvarCartao(BuildContext context) {
  try {
    context.read<CursoBloc>();
    return true;
  } catch (_) {
    return false;
  }
}
