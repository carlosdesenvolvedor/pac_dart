import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../habito/presentation/habito_cubit.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/revisao.dart';
import '../domain/revisao_mista.dart';
import 'revisao_cubit.dart';
import 'revisao_mista_page.dart';
import 'widgets/frase_view.dart';

/// As lições já concluídas, na ordem do curso: de onde a "🔁 Revisão até aqui" tira as frases.
List<Licao> licoesEstudadas(CursoState st) => [
      for (var t = 0; t < st.trilhas.length; t++)
        for (var l = 0; l < st.trilhas[t].licoes.length; l++)
          if (st.licaoConcluida(t, l)) st.trilhas[t].licoes[l],
    ];

/// O peso de sorteio de uma frase pela memória dela: a que a pessoa tem menos chance de lembrar sai mais
/// (até 3×), e cada erro antigo soma um pouco. Sem cartão (nunca entrou na revisão), um pouco acima do normal.
double pesoNaRevisaoMista(RevisaoCubit? revisao, Trecho f) {
  final c = revisao?.state.cartoes[RevisaoCubit.chaveDe(f)];
  if (revisao == null) return 1;
  if (c == null) return 1.5;
  if (c.suspenso) return .2;
  final chance = revisao.agendador.retrievabilidade(c, revisao.hoje).clamp(0.0, 1.0);
  return 1 + 2 * (1 - chance) + .4 * min(c.lapsos, 3);
}

/// Abre a "🔁 Revisão até aqui": 10 exercícios misturados (✍️ 🧩 👂 🎤) com frases das lições já feitas.
/// Cada exercício conta para o hábito do dia. Na repetição espaçada: escrever e falar (lembrar o inglês a
/// partir do português) contam como uma revisão de verdade; blocos e escutar mostram ou dizem a frase, então só
/// o ERRO conta — como "difícil", para a frase voltar um pouco antes sem zerar a memória dela.
Future<void> abrirRevisaoMista(BuildContext context, {Random? rnd}) async {
  final nav = Navigator.of(context);
  final revisao = RevisaoCubit.de(context);
  final habito = HabitoCubit.de(context);
  final ranking = RankingCubit.de(context);
  final st = context.read<CursoBloc>().state;
  final estudadas = licoesEstudadas(st);
  if (estudadas.isEmpty) return;
  final r = rnd ?? Random();
  final falarNoAparelho = FraseView.fabricaReconhecedor().suportado;
  // blocos de enfeite: frases de outras lições estudadas
  final extra = [for (final l in estudadas) for (final f in l.trechos) f.cod]..shuffle(r);

  while (nav.mounted) {
    final pausa = await PrefsRevisaoMista.carregar();
    final exercicios = montarRevisaoMista(
      estudadas,
      peso: (f) => pesoNaRevisaoMista(revisao, f),
      podeEscutar: pausa.semAudio == null,
      podeFalar: falarNoAparelho && pausa.semFala == null,
      rnd: r,
    );
    if (exercicios.isEmpty || !nav.mounted) return;
    final saida = await nav.push<SaidaRevisaoMista>(MaterialPageRoute<SaidaRevisaoMista>(
      builder: (_) => RevisaoMistaPage(
        exercicios: exercicios,
        extraMontagem: extra.take(40).toList(),
        onDesligar: PrefsRevisaoMista.desligar,
        onResultado: (res) {
          habito?.praticou();
          if (revisao == null) return;
          final tipo = res.exercicio.tipo;
          if (tipo == TipoExercicio.escrever || tipo == TipoExercicio.falar) {
            revisao.registrar(res.exercicio.trecho, res.resultado);
          } else if (res.resultado == ResultadoRevisao.errou) {
            revisao.registrar(res.exercicio.trecho, ResultadoRevisao.hesitou);
          }
        },
        onFim: (rs) {
          final validos = [for (final x in rs) if (!x.exercicio.repeticao) x];
          ranking?.quizRespondido(
              validos.where((x) => x.resultado == ResultadoRevisao.acertou).length, validos.length);
        },
      ),
    ));
    if (saida != SaidaRevisaoMista.maisUma) return;
  }
}
