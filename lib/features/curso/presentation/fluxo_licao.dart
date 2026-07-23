import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/curriculo.dart';
import '../domain/quiz.dart';
import 'bloc/curso_bloc.dart';
import 'pages/projeto_page.dart';
import 'pages/quiz_page.dart';

/// O que vem DEPOIS de terminar de digitar uma lição, emendado:
///
/// 1. o **quiz da lição** (dá para pular);
/// 2. quando as lições da trilha acabam, os projetos **Mão na Massa** que
///    ainda faltam, um a um (cada um dá para pular);
/// 3. a próxima lição.
///
/// Cada etapa devolve `true` para seguir a sequência; sair (seta de voltar)
/// interrompe e deixa o jogador onde está.
Future<void> seguirDepoisDaLicao(BuildContext context, {bool comQuiz = true}) async {
  final bloc = context.read<CursoBloc>();
  final nav = Navigator.of(context);
  final t = bloc.state.trilhaIdx, l = bloc.state.licaoIdx;
  final trilha = bloc.state.trilhas[t];

  if (comQuiz && temQuiz(bloc.state, t, l)) {
    final seguiu = await nav.push<bool>(MaterialPageRoute<bool>(
      builder: (_) => QuizPage(
        trilhaIdx: t,
        licaoIdx: l,
        licao: trilha.licoes[l],
        poolTrilha: poolDaTrilha(trilha),
        emSequencia: true,
      ),
    ));
    if (seguiu != true || !nav.mounted) return;
  }

  // As lições da trilha acabaram? Então vêm os projetos que faltam.
  if (bloc.state.trilhaSemLicoesPendentes(t)) {
    final pendentes = bloc.state.projetosPendentes(t);
    for (var i = 0; i < pendentes.length; i++) {
      final seguiu = await nav.push<bool>(MaterialPageRoute<bool>(
        builder: (_) => ProjetoPage(
          nivel: trilha.nivel,
          projeto: trilha.projetos[pendentes[i]],
          chaveProgresso: CursoState.chaveProjeto(t, pendentes[i]),
          emSequencia: true,
          passo: i + 1,
          total: pendentes.length,
        ),
      ));
      if (seguiu != true || !nav.mounted) return;
    }
  }

  if (!bloc.isClosed) bloc.add(const ProximaLicaoPedida());
}

/// Todos os códigos da trilha — servem de distratores no quiz.
List<String> poolDaTrilha(Trilha trilha) =>
    trilha.licoes.expand((l) => l.trechos.map((tr) => tr.cod)).toList();

/// Semente do quiz: mantém as perguntas estáveis por lição.
int sementeQuiz(int t, int l) => t * 1000 + l;

/// A lição consegue gerar perguntas? (todas do currículo conseguem, mas o
/// fluxo não pode empurrar uma tela vazia se um dia isso mudar).
bool temQuiz(CursoState st, int t, int l) => gerarQuiz(
      st.trilhas[t].licoes[l],
      poolDaTrilha(st.trilhas[t]),
      seed: sementeQuiz(t, l),
    ).isNotEmpty;

/// Quantos projetos "Mão na Massa" entram na sequência depois da lição
/// atual (0 quando ainda faltam lições na trilha ou já foram todos feitos).
int projetosNaSequencia(CursoState st) => st.trilhaSemLicoesPendentes(st.trilhaIdx)
    ? st.projetosPendentes(st.trilhaIdx).length
    : 0;
