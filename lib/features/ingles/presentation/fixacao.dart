import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/revisao.dart';
import 'revisao_cubit.dart';
import 'sessao_memoria_page.dart';

/// Nota da fixação (0..10): de primeira vale 1, com tropeço vale meio.
int notaDaFixacao(List<ResultadoFrase> rs) {
  if (rs.isEmpty) return 0;
  var pontos = 0.0;
  for (final r in rs) {
    if (r.resultado == ResultadoRevisao.acertou) pontos += 1;
    if (r.resultado == ResultadoRevisao.hesitou) pontos += .5;
  }
  return (pontos * 10 / rs.length).round();
}

/// Abre o Treino de memória da lição [l] da trilha [t] (no mapa): todas as
/// frases da lição, embaralhadas, de memória. A nota só sobe (fica a melhor).
/// Devolve true se a pessoa terminou e quer seguir.
Future<bool?> abrirFixacao(BuildContext context, int t, int l, {bool emSequencia = false, Random? rnd}) {
  final bloc = context.read<CursoBloc>();
  final ranking = RankingCubit.de(context);
  final licao = bloc.state.trilhas[t].licoes[l];
  final itens = [...licao.trechos]..shuffle(rnd ?? Random());
  return Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
    builder: (_) => SessaoMemoriaPage(
      titulo: 'Treino de memória · ${licao.nome}',
      subtitulo: 'todas as frases da lição, de memória, fora de ordem',
      emoji: '🧠',
      itens: itens,
      emSequencia: emSequencia,
      cenaDe: (_) => licao,
      onFim: (rs) {
        if (bloc.isClosed) return;
        bloc.add(QuizFinalizado(t, l, notaDaFixacao(rs)));
        ranking?.quizRespondido(rs.where((r) => r.resultado == ResultadoRevisao.acertou).length, rs.length);
      },
    ),
  ));
}

/// Abre a Revisão do dia: as frases que vencem hoje na repetição espaçada.
Future<void> abrirRevisao(BuildContext context) async {
  final revisao = RevisaoCubit.de(context);
  if (revisao == null) return;
  final st = context.read<CursoBloc>().state;
  // chave (hash do inglês) → frase do currículo carregado (e a lição dela)
  final porChave = {
    for (final tr in st.trilhas)
      for (final li in tr.licoes)
        for (final f in li.trechos) RevisaoCubit.chaveDe(f): f,
  };
  final licaoDe = {
    for (final tr in st.trilhas)
      for (final li in tr.licoes)
        for (final f in li.trechos) f.cod: li,
  };
  final itens = [
    for (final k in revisao.state.devidas(revisao.hoje))
      if (porChave[k] != null) porChave[k]!,
  ];
  final ranking = RankingCubit.de(context);
  await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
    builder: (_) => SessaoMemoriaPage(
      titulo: 'Revisão do dia',
      subtitulo: itens.isEmpty
          ? 'nenhuma frase vence hoje'
          : '${itens.length} frase${itens.length == 1 ? '' : 's'} de lições anteriores, de memória',
      emoji: '🔁',
      itens: itens,
      cenaDe: (f) => licaoDe[f.cod],
      onResultado: (r) => revisao.registrar(r.trecho, r.resultado),
      onFim: (rs) =>
          ranking?.quizRespondido(rs.where((r) => r.resultado == ResultadoRevisao.acertou).length, rs.length),
    ),
  ));
}

/// Quantas frases o teste de nivelamento da trilha usa e quantas precisa
/// acertar limpas (dossiê 01 §5.5: 8 de 10).
const frasesDoTeste = 10;
const acertosDoTeste = .8;

/// As frases do teste da trilha [t]: espalhadas por todas as lições (uma
/// de cada, depois mais uma de cada…), embaralhadas.
List<Trecho> frasesDoTesteDaTrilha(Trilha trilha, {Random? rnd}) {
  final r = rnd ?? Random();
  // a frase que o autor marcou como "teste" de cada lição vem primeiro
  final porLicao = [
    for (final l in trilha.licoes)
      [...l.trechos.where((f) => f.teste).toList()..shuffle(r), ...l.trechos.where((f) => !f.teste).toList()..shuffle(r)],
  ];
  final escolhidas = <Trecho>[];
  for (var rodada = 0; escolhidas.length < frasesDoTeste; rodada++) {
    var algum = false;
    for (final fs in porLicao) {
      if (rodada < fs.length && escolhidas.length < frasesDoTeste) {
        escolhidas.add(fs[rodada]);
        algum = true;
      }
    }
    if (!algum) break;
  }
  return escolhidas..shuffle(r);
}

/// Teste de nivelamento da trilha [t]: passou (8 de 10 de memória, sem
/// erro), a trilha fica concluída e as frases vão para a revisão numa caixa
/// alta. Devolve se passou.
Future<bool> abrirTesteTrilha(BuildContext context, int t, {Random? rnd}) async {
  final bloc = context.read<CursoBloc>();
  final revisao = RevisaoCubit.de(context);
  final trilha = bloc.state.trilhas[t];
  final itens = frasesDoTesteDaTrilha(trilha, rnd: rnd);
  var passou = false;
  await Navigator.of(context).push<bool>(MaterialPageRoute<bool>(
    builder: (_) => SessaoMemoriaPage(
      titulo: 'Teste de nivelamento · ${trilha.nivel}',
      subtitulo: '${itens.length} frases de memória — acerte ${(itens.length * acertosDoTeste).ceil()} e pule a trilha',
      emoji: '⏭️',
      itens: itens,
      reaprender: false,
      onFim: (rs) {
        final limpas = rs.where((r) => r.resultado == ResultadoRevisao.acertou).length;
        passou = rs.isNotEmpty && limpas >= (rs.length * acertosDoTeste).ceil();
        if (!passou || bloc.isClosed) return;
        bloc.add(TrilhaTestada(t));
        revisao?.testadas([for (final l in trilha.licoes) ...l.trechos]);
      },
      resumoExtra: (rs) {
        final limpas = rs.where((r) => r.resultado == ResultadoRevisao.acertou).length;
        final precisa = (rs.length * acertosDoTeste).ceil();
        return limpas >= precisa
            ? '🎉 Passou! ${trilha.nivel} ficou concluída — as frases voltam na revisão daqui a uma semana.'
            : '$limpas de ${rs.length} limpas (precisava de $precisa). Melhor fazer as lições: elas vão rápido pro que você já sabe.';
      },
    ),
  ));
  return passou;
}


/// Frases por portão do nivelamento e quantas limpas para passar (12 de 15).
const frasesDoPortao = 15;
const acertosDoPortao = 12;

/// As etapas do curso na ordem ("A1 · Fundação", "A2 · Dia a dia"…).
List<String> etapasDoCurso(List<Trilha> trilhas) {
  final r = <String>[];
  for (final t in trilhas) {
    if (t.etapa.isNotEmpty && !r.contains(t.etapa)) r.add(t.etapa);
  }
  return r;
}

/// As frases de um portão: [n] frases espalhadas pelas trilhas da [etapa].
List<Trecho> frasesDaEtapa(List<Trilha> trilhas, String etapa, {int n = frasesDoPortao, Random? rnd}) {
  final r = rnd ?? Random();
  final pilhas = [
    for (final t in trilhas.where((t) => t.etapa == etapa)) [for (final l in t.licoes) ...l.trechos]..shuffle(r),
  ]..shuffle(r);
  final saida = <Trecho>[];
  for (var rodada = 0; saida.length < n; rodada++) {
    var algum = false;
    for (final p in pilhas) {
      if (rodada < p.length && saida.length < n) {
        saida.add(p[rodada]);
        algum = true;
      }
    }
    if (!algum) break;
  }
  return saida..shuffle(r);
}

/// Nivelamento: portão a portão (A2, B1, B2…), 15 frases de memória da
/// etapa ANTERIOR. Passou (12 limpas), a etapa anterior inteira fica
/// "testada" (trilhas concluídas, frases na revisão em caixa alta) e vem o
/// próximo portão; para no primeiro em que não passar. Devolve quantas
/// etapas foram liberadas.
Future<int> abrirNivelamento(BuildContext context, {Random? rnd}) async {
  final bloc = context.read<CursoBloc>();
  final revisao = RevisaoCubit.de(context);
  final nav = Navigator.of(context);
  final trilhas = bloc.state.trilhas;
  final etapas = etapasDoCurso(trilhas);
  var liberadas = 0;
  for (var g = 1; g < etapas.length; g++) {
    final anterior = etapas[g - 1];
    final itens = frasesDaEtapa(trilhas, anterior, rnd: rnd);
    if (itens.isEmpty) break;
    final precisa = itens.length < frasesDoPortao ? (itens.length * .8).ceil() : acertosDoPortao;
    var passou = false;
    final seguiu = await nav.push<bool>(MaterialPageRoute<bool>(
      builder: (_) => SessaoMemoriaPage(
        titulo: 'Nivelamento · portão do ${etapas[g].split(' ').first}',
        subtitulo: '${itens.length} frases do ${anterior.split(' ').first}, de memória — acerte $precisa e pule o nível',
        emoji: '🧭',
        itens: itens,
        reaprender: false,
        onFim: (rs) {
          final limpas = rs.where((r) => r.resultado == ResultadoRevisao.acertou).length;
          passou = limpas >= precisa;
          if (!passou || bloc.isClosed) return;
          for (var t = 0; t < trilhas.length; t++) {
            if (trilhas[t].etapa == anterior) bloc.add(TrilhaTestada(t));
          }
          revisao?.testadas([
            for (final t in trilhas.where((t) => t.etapa == anterior))
              for (final l in t.licoes) ...l.trechos,
          ]);
        },
        resumoExtra: (rs) {
          final limpas = rs.where((r) => r.resultado == ResultadoRevisao.acertou).length;
          if (limpas < precisa) {
            return '$limpas de ${rs.length} limpas (precisava de $precisa). Seu ponto de partida é o '
                '${anterior.split(' ').first} — o que você já sabe vai rápido nas lições.';
          }
          return g + 1 < etapas.length
              ? '🎉 ${anterior.split(' ').first} liberado! Continue para o portão seguinte.'
              : '🎉 ${anterior.split(' ').first} liberado! Você chegou ao último nível.';
        },
      ),
    ));
    if (!passou) break;
    liberadas++;
    if (seguiu != true || !nav.mounted) break;
  }
  // a próxima lição a estudar: a primeira ainda não concluída
  if (liberadas > 0 && !bloc.isClosed) {
    final st = bloc.state;
    for (var t = 0; t < st.trilhas.length; t++) {
      final l = [for (var i = 0; i < st.trilhas[t].licoes.length; i++) i].where((i) => !st.licaoConcluida(t, i));
      if (l.isNotEmpty) {
        bloc.add(TrilhaSelecionada(t));
        bloc.add(LicaoSelecionada(l.first));
        break;
      }
    }
  }
  return liberadas;
}
