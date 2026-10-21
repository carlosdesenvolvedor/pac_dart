import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../arcade/presentation/arcade_page.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../habito/presentation/habito_cubit.dart';
import '../data/voz_ingles.dart';
import '../domain/palavras_novas.dart';
import '../domain/roteiro_treino.dart';
import 'acoes_teimosas.dart' show virarLicaoCom;
import 'ouvir/ouvir_acoes.dart' show rotaArcade;
import 'palavras_cubit.dart';
import 'treino_palavras_page.dart';

/// Abre a sessão de treino das [palavras] (até 8 por lote; mais que isso vira lotes) e, na volta,
/// registra o resultado: o cartão FSRS de cada palavra (no banco de palavras, nunca na revisão das
/// frases), os exercícios do dia (hábito) e, se veio, [chaveConclusao] como `ProjetoConcluido` (o
/// baú da unidade). "🎮 Jogar com essas palavras" põe as palavras em foco e abre o Arcade.
///
/// [jaNoArcade]: quem abriu É o hub do Arcade — "Jogar" só põe as palavras em foco e volta para ele
/// (sem empilhar um segundo hub).
///
/// [revanche]: a revanche das "🔥 teimosas" (sem "conhecer"; digitar sem dica e duas vezes). Cada rodada
/// é registrada AO TERMINAR (o resumo mostra o "🏆 DOMINADA!" e as ⭐ de cada palavra), e o resumo
/// oferece "📝 Virar lição".
///
/// [antesDaLicao]: o "🎯 Conhecer antes" de uma lição que ainda vai começar — o resumo não oferece "🎮
/// Jogar" (tiraria a pessoa da lição que ela escolheu preparar) e o botão principal diz "COMEÇAR A LIÇÃO →".
///
/// [voz]: injetável (testes).
Future<void> abrirTreinoPalavras(
  BuildContext context,
  List<PalavraNova> palavras, {
  String? titulo,
  String? chaveConclusao,
  bool jaNoArcade = false,
  VozIngles? voz,
  bool revanche = false,
  bool antesDaLicao = false,
}) async {
  if (palavras.isEmpty) return;
  // tudo capturado ANTES de empurrar a rota (o contexto pode sumir enquanto a sessão está aberta)
  final cubit = PalavrasCubit.de(context);
  final habito = HabitoCubit.de(context);
  CursoBloc? curso;
  try {
    curso = context.read<CursoBloc>();
  } catch (_) {}
  final nav = Navigator.of(context);
  final mensageiro = ScaffoldMessenger.maybeOf(context);
  // revanche: registra cada rodada quando ela termina (para o resumo saber o que foi dominado)
  final registraNaHora = revanche && cubit != null;
  final r = await nav.push(MaterialPageRoute<ResultadoTreino>(
    builder: (_) => TreinoPalavrasPage(
      palavras: palavras,
      reserva: _reserva(cubit, curso?.state, palavras),
      titulo: titulo,
      voz: voz,
      revanche: revanche,
      antesDaLicao: antesDaLicao,
      aoTerminarRodada: registraNaHora
          ? (rodada) {
              final dominadas = cubit.registrarTreino(rodada.paraRegistrar);
              final banco = cubit.state.banco;
              return RetornoRevanche(
                dominadas: dominadas,
                acertos: {for (final p in rodada.palavras) p.chave: banco[p.chave]?.acertosSeguidos ?? 0},
              );
            }
          : null,
    ),
  ));
  if (r == null) return;
  if (!registraNaHora) cubit?.registrarTreino(r.paraRegistrar);
  if (r.passos > 0) habito?.praticou(r.passos);
  if (chaveConclusao != null && chaveConclusao.isNotEmpty) curso?.add(ProjetoConcluido(chaveConclusao));
  if (r.licao) {
    virarLicaoCom(
      cubit: cubit,
      curso: curso,
      nav: nav,
      mensageiro: mensageiro,
      chaves: [for (final p in r.palavras) p.chave],
    );
    return;
  }
  if (r.jogar && !antesDaLicao) {
    cubit?.focar([for (final p in r.palavras) if (p.deJogo) p.en]);
    if (jaNoArcade) return;
    await nav.push(MaterialPageRoute<void>(
        builder: (_) => const ArcadePage(), settings: const RouteSettings(name: rotaArcade)));
  }
}

/// As opções erradas extras: as palavras novas da mesma trilha (a da 1ª palavra) — parecidas com as
/// da sessão, sem ser as mesmas.
List<PalavraNova> _reserva(PalavrasCubit? cubit, CursoState? st, List<PalavraNova> palavras) {
  final ind = cubit?.state.indice;
  if (ind == null || st == null) return const [];
  final licaoId = palavras.firstWhere((p) => p.licaoId.isNotEmpty, orElse: () => palavras.first).licaoId;
  if (licaoId.isEmpty) return const [];
  for (final t in st.trilhas) {
    if (t.licoes.any((l) => l.id == licaoId)) return ind.novasDaTrilha(t, max: 40);
  }
  return const [];
}
