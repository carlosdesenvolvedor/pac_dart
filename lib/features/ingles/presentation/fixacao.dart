import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../habito/presentation/habito_cubit.dart';
import '../../ranking/presentation/ranking_cubit.dart';
import '../domain/baralhos.dart';
import '../domain/cartoes_texto.dart' show idCartoesAvulsos;
import '../domain/revisao.dart';
import 'revisao_cubit.dart';
import 'sessao_cartoes_page.dart';
import 'sessao_memoria_page.dart';
import 'widgets/audio_da_frase.dart';

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

/// O que a Revisão do dia vai mostrar: as [diretas] (de memória, português → inglês) e as
/// [invertidas] (cartões inglês → português: as que vencem primeiro, depois as [novas] que cabem na
/// cota do dia).
class ItensRevisao {
  final List<Trecho> diretas, invertidas, novas;
  const ItensRevisao({this.diretas = const [], this.invertidas = const [], this.novas = const []});

  bool get vazio => diretas.isEmpty && invertidas.isEmpty;
  int get total => diretas.length + invertidas.length;
}

/// A seleção de [abrirRevisao], pura (fora ler o estado do cubit). [invertidas] = as que vencem
/// primeiro, depois as novas que cabem na cota do dia. Com [limiteFrases] / [limiteCartoes] cada sentido
/// fica cortado nesse tanto (o "⚡ Treino do dia"); com [limiteCartoes], [novas] são só as novas que
/// couberam. Sem limites, a seleção de sempre.
ItensRevisao itensDaRevisao(RevisaoCubit revisao, List<Trilha> trilhas,
        {String? baralho, int? limiteFrases, int? limiteCartoes}) =>
    _itensDaRevisao(revisao, IndiceBaralhos.de(trilhas),
        baralho: baralho, limiteFrases: limiteFrases, limiteCartoes: limiteCartoes);

ItensRevisao _itensDaRevisao(RevisaoCubit revisao, IndiceBaralhos indice,
    {String? baralho, int? limiteFrases, int? limiteCartoes}) {
  bool doBaralho(String chave) => baralho == null || indice.pertence(chave, baralho);
  List<Trecho> corta(List<Trecho> l, int? limite) =>
      limite == null || l.length <= limite ? l : l.sublist(0, max(0, limite));

  final devidas = revisao.devidas();
  final diretas = [
    for (final k in devidas)
      if (!Revisao.ehReversa(k) && doBaralho(k) && indice.porChave[k] != null) indice.porChave[k]!,
  ];
  final invertidasDevidas = [
    for (final k in devidas)
      if (Revisao.ehReversa(k) && doBaralho(k) && indice.porChave[Revisao.baseDe(k)] != null)
        indice.porChave[Revisao.baseDe(k)]!,
  ];
  // novasReversas só lê a cota do dia (não grava nada): dá para chamar só para compor
  final novas = revisao.novasReversas([
    for (final f in indice.frasesDosLigados(revisao.state.config.reversos))
      if (doBaralho(chaveDaFrase(f))) f,
  ]);
  final invertidas = corta([...invertidasDevidas, ...novas], limiteCartoes);
  final cabem = invertidas.length - invertidasDevidas.length;
  return ItensRevisao(
    diretas: corta(diretas, limiteFrases),
    invertidas: invertidas,
    novas: cabem >= novas.length ? novas : novas.sublist(0, max(0, cabem)),
  );
}

/// Como a Revisão do dia terminou ("⚡ Treino do dia").
class FimDaRevisao {
  /// Frases e cartões respondidos (1ª tentativa).
  final int respondidas;

  /// Cada parte que tinha itens chegou ao fim (nada para revisar também conta como terminou).
  final bool terminou;

  /// As frases respondidas, na ordem (memória e depois cartões).
  final List<Trecho> revisadas;

  const FimDaRevisao({required this.respondidas, required this.terminou, this.revisadas = const []});
}

/// Abre a Revisão do dia: as frases que vencem hoje na repetição espaçada. Dois
/// sentidos, um depois do outro — primeiro as digitadas de memória (português →
/// inglês) e, nos baralhos com o sentido invertido ligado, os cartões de virar e
/// avaliar (inglês → português), com os novos que cabem na cota do dia. Com
/// [baralho] (`Trilha.baralhoId`) só o que é daquele baralho.
///
/// "⚡ Treino do dia": [limiteFrases] / [limiteCartoes] cortam cada sentido e [modoTreino] não abre nada
/// quando não há o que revisar (sem ele, abre a sessão vazia: "nenhuma frase vence hoje") e tira a oferta
/// das teimosas do fim das duas sessões. Devolve como terminou ([FimDaRevisao]).
Future<FimDaRevisao> abrirRevisao(BuildContext context,
    {String? baralho, int? limiteFrases, int? limiteCartoes, bool modoTreino = false}) async {
  final revisao = RevisaoCubit.de(context);
  if (revisao == null) return const FimDaRevisao(respondidas: 0, terminou: true);
  final st = context.read<CursoBloc>().state;
  final indice = IndiceBaralhos.de(st.trilhas);
  // a lição de onde veio cada frase (a cena volta junto)
  final licaoDe = {
    for (final tr in st.trilhas)
      for (final li in tr.licoes)
        for (final f in li.trechos) f.cod: li,
  };
  final itens = _itensDaRevisao(revisao, indice,
      baralho: baralho, limiteFrases: limiteFrases, limiteCartoes: limiteCartoes);
  final diretas = itens.diretas;
  final invertidas = itens.invertidas;
  final novas = itens.novas;
  if (modoTreino && itens.vazio) return const FimDaRevisao(respondidas: 0, terminou: true);
  final nome = baralho == null ? null : indice.baralho(baralho)?.nome;

  final ranking = RankingCubit.de(context);
  final habito = HabitoCubit.de(context);
  final nav = Navigator.of(context);
  // o que foi respondido (1ª tentativa), na ordem, e que partes chegaram ao fim
  final revisadas = <Trecho>[];
  var fimMemoria = false, fimCartoes = false;
  FimDaRevisao resultado() => FimDaRevisao(
        respondidas: revisadas.length,
        terminou: (diretas.isEmpty || fimMemoria) && (invertidas.isEmpty || fimCartoes),
        revisadas: List.unmodifiable(revisadas),
      );
  var seguir = true;
  // sem nada nos dois sentidos, abre a sessão vazia mesmo assim ("nenhuma frase vence hoje")
  if (diretas.isNotEmpty || invertidas.isEmpty) {
    seguir = await nav.push<bool>(MaterialPageRoute<bool>(
          builder: (_) => SessaoMemoriaPage(
            titulo: nome == null ? 'Revisão do dia' : 'Revisão · $nome',
            subtitulo: diretas.isEmpty
                ? 'nenhuma frase vence hoje'
                : '${diretas.length} frase${diretas.length == 1 ? '' : 's'} de lições anteriores, de memória',
            emoji: '🔁',
            itens: diretas,
            emSequencia: invertidas.isNotEmpty,
            semOferta: modoTreino,
            cenaDe: (f) => licaoDe[f.cod],
            // só a 1ª tentativa da frase chega aqui (a cópia e o esqueleto de reaprender não): 1 exercício
            onResultado: (r) {
              revisadas.add(r.trecho);
              habito?.praticou();
              revisao.registrar(r.trecho, r.resultado);
            },
            onFim: (rs) {
              fimMemoria = true;
              ranking?.quizRespondido(rs.where((r) => r.resultado == ResultadoRevisao.acertou).length, rs.length);
            },
          ),
        )) ??
        false;
  }
  if (!seguir || invertidas.isEmpty || !nav.mounted) return resultado();
  final chavesNovas = {for (final f in novas) RevisaoCubit.chaveReversaDe(f)};
  await nav.push<bool>(MaterialPageRoute<bool>(
    builder: (_) => SessaoCartoesPage(
      titulo: nome == null ? 'Cartões · inglês → português' : 'Cartões · $nome',
      subtitulo: '${invertidas.length} ${invertidas.length == 1 ? 'cartão' : 'cartões'}'
          '${novas.isEmpty ? '' : ' · ${novas.length} novo${novas.length == 1 ? '' : 's'}'}',
      emoji: '🔄',
      itens: invertidas,
      novas: chavesNovas,
      chaveDe: RevisaoCubit.chaveReversaDe,
      previsao: (f) => revisao.previsao(RevisaoCubit.chaveReversaDe(f)),
      // a nota do cartão (só a 1ª; o "DE NOVO" depois do Errei não chama isto) conta 1 exercício
      onNota: (frase, nota) {
        revisadas.add(frase);
        habito?.praticou();
        return revisao.registrarVirar(frase, nota);
      },
      onFim: (_) => fimCartoes = true,
      semOferta: modoTreino,
      cenaDe: (f) => licaoDe[f.cod],
      acaoExtra: (context, f) => BotaoAudioDaFrase(frase: f.cod),
      // só as frases de "Meus cartões" com palavra-alvo são lacunas da leitura (as do curso também têm `alvo`)
      lacunaDaLeitura: (f) => indice.baralhosDe[chaveDaFrase(f)]?.contains('txt:$idCartoesAvulsos') ?? false,
      apoio: indice.porChave.values.toList(),
    ),
  ));
  return resultado();
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
    // "Meus textos" (trilhas que a pessoa criou) não é um nível do curso
    if (!t.propria && t.etapa.isNotEmpty && !r.contains(t.etapa)) r.add(t.etapa);
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
