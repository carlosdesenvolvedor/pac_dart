// O vocabulário dos jogos do Arcade no PAC·ENGLISH, montado com o que o aluno
// estudou: as palavras em treino, as que vencem/estão fracas, as das últimas
// lições, as dele e uma amostra das lições antigas — com a tradução de cada
// uma (aparece embaixo da palavra no jogo). Dart puro e determinístico.
import 'dart:math';

import '../../arcade/domain/palavras_ingles.dart';
import '../../arcade/domain/vocabulario_jogo.dart';
import '../../curso/domain/curriculo.dart';
import 'banco_palavras.dart';
import 'cartoes_texto.dart';
import 'palavras_novas.dart';

final _reJogo = RegExp(r'^[A-Za-z]{3,14}$');

/// O vocabulário de uma partida. Cada faixa (3–5, 6–8, 9–14 letras) é enchida nesta ordem de
/// prioridade, sem repetir e com no máximo [maxPorFaixa] palavras:
/// 1. as "em treino" (o foco: vêm primeiro no Rali);
/// 2. as que vencem hoje e as fracas do banco;
/// 3. as da lição atual e das últimas [recentes] lições concluídas (na ordem do curso);
/// 4. as que a pessoa adicionou ou guardou lendo, e as palavras soltas de "Meus cartões";
/// 5. uma amostra (sorteada pelo dia [hoje]) das lições concluídas mais antigas — inclusive as das
///    trilhas que o nivelamento marcou, sem inundar (o teto segura);
/// 6. as listas fixas de sempre, até cada faixa ter pelo menos [minPorFaixa].
/// Ficam de fora as que a pessoa tirou dos jogos ou apagou. Toda palavra sai com tradução.
///
/// Com [licoesEscolhidas] (a pessoa escolheu de quais lições vêm as palavras), o 2, o 3 e o 5 saem: no
/// lugar do 3 entram as palavras das lições escolhidas ([IndicePalavras.palavrasDeJogo]), revezando entre
/// as lições numa ordem sorteada pelo dia [hoje] (e as palavras de cada lição também sorteadas, as novas
/// primeiro) — assim, com muitas lições e o teto de [maxPorFaixa], cada dia entram palavras de lições
/// diferentes, do começo ao fim da escolha. O foco continua na frente e o 4 só entra com [incluirMinhas]:
/// aí as da pessoa têm reservado até 1/3 de cada faixa ANTES das lições (senão as lições enchem as faixas e
/// elas nunca entram) e o resto delas entra depois, se sobrar lugar. Uma escolha vazia joga só com o foco
/// (e as da pessoa) e o enchimento.
VocabularioJogo montarVocabularioIngles({
  required List<Trilha> trilhas,
  required Set<String> concluidas,
  required IndicePalavras indice,
  BancoPalavras banco = BancoPalavras.vazio,
  required int hoje,
  String? licaoAtualId,
  int recentes = 5,
  int maxPorFaixa = 40,
  int minPorFaixa = 12,
  Iterable<String>? licoesEscolhidas,
  bool incluirMinhas = true,
  int agoraMs = 0,
}) {
  final escolhidas = licoesEscolhidas?.toSet();
  final curtas = <String>[], medias = <String>[], longas = <String>[];
  final traducoes = <String, String>{};
  final foco = <String>{};
  final usadas = <String>{};
  final fora = {
    for (final p in banco.palavras.values)
      if (p.removida || !p.noJogo) p.chave,
  };

  List<String> faixaDe(int n) => n <= 5 ? curtas : (n <= 8 ? medias : longas);

  String? traducaoDe(String w, String? dada) {
    final k = w.toLowerCase();
    for (final t in [
      dada,
      banco[k]?.pt,
      indice.traducao(k),
      traducaoCurta(indice.dic.literal(k)),
      traducoesEn[k],
    ]) {
      if (t != null && t.trim().isNotEmpty) return traducaoCurta(t.trim(), max: 18);
    }
    return null;
  }

  /// Põe [w] na faixa dele (ou em [faixa], no enchimento), até [teto] por faixa. Devolve se entrou.
  bool por(String w, {String? pt, List<String>? faixa, int? teto}) {
    final palavra = w.trim();
    if (!_reJogo.hasMatch(palavra)) return false;
    final k = palavra.toLowerCase();
    if (fora.contains(k) || usadas.contains(k)) return false;
    final destino = faixa ?? faixaDe(palavra.length);
    if (destino.length >= (teto ?? maxPorFaixa)) return false;
    final t = traducaoDe(palavra, pt);
    if (t == null) return false;
    usadas.add(k);
    destino.add(palavra);
    traducoes[palavra] = t;
    return true;
  }

  String formaDe(String k) => banco[k]?.en ?? indice.formaDe(k);

  // as palavras das lições escolhidas (null = automático) e as chaves delas
  final daEscolha = escolhidas == null ? null : _revezadas(trilhas, escolhidas, indice, hoje);
  final chavesEscolha = {for (final (w, _) in daEscolha ?? const <(String, String)>[]) w.toLowerCase()};

  // 4 (a função): as da pessoa (mais novas primeiro) e as palavras soltas de "Meus cartões". Com [cota], no
  // máximo tantas por faixa nesta passada. Conta em [minhasPostas] as que entraram e não vêm das lições.
  final comMinhas = escolhidas == null || incluirMinhas;
  final minhas = [
    for (final p in banco.ativas)
      if (comMinhas && p.origem != OrigemPalavra.licao) p,
  ]..sort((a, b) {
      final c = b.criadaEm.compareTo(a.criadaEm);
      return c != 0 ? c : a.chave.compareTo(b.chave);
    });
  var minhasPostas = 0;
  void porMinhas({int? cota, int? total}) {
    if (!comMinhas) return;
    final porFaixa = [0, 0, 0];
    void tenta(String w, String? pt) {
      final palavra = w.trim();
      final f = palavra.length <= 5 ? 0 : (palavra.length <= 8 ? 1 : 2);
      if (cota != null && porFaixa[f] >= cota) return;
      if (total != null && minhasPostas >= total) return;
      if (!por(palavra, pt: pt)) return;
      porFaixa[f]++;
      if (!chavesEscolha.contains(palavra.toLowerCase())) minhasPostas++;
    }

    for (final p in minhas) {
      tenta(p.en, p.pt);
    }
    for (final t in trilhas) {
      if (t.textoId != idCartoesAvulsos) continue;
      for (final l in t.licoes) {
        for (final tr in l.trechos) {
          final alvo = (tr.alvo.isNotEmpty ? tr.alvo : tr.cod).trim().replaceAll(RegExp(r'^[^A-Za-z]+|[^A-Za-z]+$'), '');
          if (_reJogo.hasMatch(alvo)) tenta(alvo, tr.alvo.isNotEmpty ? tr.alvoPt : tr.dicaPlana);
        }
      }
    }
  }

  // 1. em treino. Com lições escolhidas, só as delas — ou todas, se o foco é de agora há pouco (o
  // "jogar com elas" das teimosas): o treino de palavras novas de outra lição não invade a escolha.
  final focoRecente = agoraMs > 0 && agoraMs - banco.emTreinoEm < focoRecenteMs;
  for (final k in banco.emTreino) {
    if (daEscolha != null && !focoRecente && !chavesEscolha.contains(k)) continue;
    final w = formaDe(k);
    if (por(w)) foco.add(w);
  }

  // 3'. as lições escolhidas pela pessoa (no lugar do 2, do 3 e do 5): primeiro TODAS as palavras delas
  // (as de conteúdo, depois as de função — how, you, about), e só então um punhado das da pessoa
  var daLicao = 0;
  if (daEscolha != null) {
    // com muitas lições as faixas lotam: guarda [reservaMinhas] lugares por faixa para as da pessoa e
    // depois completa com o que sobrou das lições
    final reserva = comMinhas && minhas.isNotEmpty ? reservaMinhas : 0;
    final daLista = [...daEscolha, ..._comunsDaEscolha(trilhas, escolhidas!, indice)];
    void porDaLista(int teto) {
      for (final (w, pt) in daLista) {
        // a tradução que a pessoa editou no banco vale mais que a do dicionário
        final editada = banco[w]?.pt.trim() ?? '';
        if (por(w, pt: editada.isNotEmpty ? null : pt, teto: teto)) daLicao++;
      }
    }

    porDaLista(maxPorFaixa - reserva);
    porMinhas(total: max(reservaMinhas, daLicao ~/ 4));
    porDaLista(maxPorFaixa);
  }

  // 2. vencem hoje, depois as fracas
  for (final p in escolhidas != null ? const <PalavraDoBanco>[] : [...banco.devidas(hoje), ...banco.fracas(hoje)]) {
    por(p.en);
  }

  // 3. lição atual + últimas concluídas, na ordem do curso
  final ordemCurso = [
    for (final t in trilhas)
      if (!t.propria)
        for (final l in t.licoes)
          if (l.id.isNotEmpty) l.id,
  ];
  final feitas = [for (final id in ordemCurso) if (concluidas.contains(id)) id];
  final ultimas = escolhidas != null
      ? const <String>[]
      : (feitas.length <= recentes ? feitas : feitas.sublist(feitas.length - recentes));
  for (final id in [if (escolhidas == null) ?licaoAtualId, ...ultimas.reversed]) {
    for (final w in indice.poolPorLicao[id] ?? const <String>[]) {
      por(w);
    }
  }

  // 4. as da pessoa (mais novas primeiro) e as palavras soltas de "Meus cartões" (com a escolha, já
  // entrou o punhado delas lá em cima)
  if (daEscolha == null) porMinhas();

  // 5. amostra das lições antigas (sorteio fixo para o dia)
  final recentesSet = {...ultimas, ?licaoAtualId};
  final antigas = <String>[];
  final vistasAntigas = <String>{};
  for (final id in escolhidas != null ? const <String>[] : feitas) {
    if (recentesSet.contains(id)) continue;
    for (final w in indice.poolPorLicao[id] ?? const <String>[]) {
      if (vistasAntigas.add(w.toLowerCase())) antigas.add(w);
    }
  }
  antigas.shuffle(Random(hoje));
  for (final w in antigas) {
    if (curtas.length >= maxPorFaixa && medias.length >= maxPorFaixa && longas.length >= maxPorFaixa) break;
    por(w);
  }

  // 6'. com a escolha, a faixa curta demais pega as palavras DA ESCOLHA das outras faixas (a pista de
  // palavras curtas mostra também as médias da lição) em vez de palavras de fora; a lista fixa só entra se
  // a escolha inteira tiver menos de [minDaEscolha] palavras
  if (daEscolha != null && usadas.length >= minDaEscolha) {
    final todas = [...curtas, ...medias, ...longas];
    for (final faixa in [curtas, medias, longas]) {
      final alvo = min(minPorFaixa, todas.length);
      for (final w in todas) {
        if (faixa.length >= alvo) break;
        if (!faixa.contains(w)) faixa.add(w);
      }
    }
  }

  // 6. enchimento com as listas fixas
  var enchimento = 0, enchimentoLongas = 0;
  for (final (faixa, reserva) in [
    (curtas, palavrasCurtasEn),
    (medias, palavrasMediasEn),
    (longas, palavrasLongasEn),
  ]) {
    for (final w in reserva) {
      if (faixa.length >= minPorFaixa || (daEscolha != null && usadas.length >= minDaEscolha && faixa.isNotEmpty)) break;
      if (por(w, faixa: faixa)) {
        enchimento++;
        if (identical(faixa, longas)) enchimentoLongas++;
      }
    }
  }

  return VocabularioJogo(
    curtas: List.unmodifiable(curtas),
    medias: List.unmodifiable(medias),
    longas: List.unmodifiable(longas),
    traducoes: Map.unmodifiable(traducoes),
    foco: Set.unmodifiable(foco),
    enchimento: enchimento,
    enchimentoLongas: enchimentoLongas,
    minhas: minhasPostas,
  );
}

/// Foco "de agora há pouco": até quanto tempo depois do "jogar com elas" o em-treino vale mesmo com
/// lições escolhidas. E o mínimo de palavras da escolha para os jogos não completarem com as listas fixas.
const focoRecenteMs = 30 * 60 * 1000;
const minDaEscolha = 4;

/// Com lições escolhidas: lugares por faixa guardados para as palavras da pessoa (com "incluir minhas").
const reservaMinhas = 4;

/// As palavras de função das lições [escolhidas] ([IndicePalavras.comunsDeJogo]), na ordem do curso.
List<(String, String)> _comunsDaEscolha(List<Trilha> trilhas, Set<String> escolhidas, IndicePalavras indice) => [
      for (final t in trilhas)
        for (final l in t.licoes)
          if (l.id.isNotEmpty && escolhidas.contains(l.id)) ...indice.comunsDeJogo(l),
    ];

/// As palavras das lições [escolhidas] para os jogos, (como se escreve, tradução), sem repetir: uma de cada
/// lição por rodada. A ordem das lições e as palavras de cada uma ([IndicePalavras.palavrasDeJogo]: as
/// novas primeiro, depois o resto) são sorteadas pelo dia [hoje] — com muitas lições escolhidas o teto das
/// faixas acaba na 1ª rodada, então sem o sorteio só as primeiras lições do curso entrariam (e sempre as
/// mesmas palavras); assim cada dia entram lições diferentes, de toda a escolha.
List<(String, String)> _revezadas(List<Trilha> trilhas, Set<String> escolhidas, IndicePalavras indice, int hoje) {
  final listas = <List<(String, String)>>[];
  var n = 0;
  for (final t in trilhas) {
    for (final l in t.licoes) {
      if (l.id.isEmpty || !escolhidas.contains(l.id)) continue;
      final todas = indice.palavrasDeJogo(l);
      final chavesNovas = {for (final p in indice.novasDe(l.id)) p.chave};
      final sorteio = Random(hoje * 31 + n++);
      final novas = [for (final p in todas) if (chavesNovas.contains(p.$1.toLowerCase())) p]..shuffle(sorteio);
      final resto = [for (final p in todas) if (!chavesNovas.contains(p.$1.toLowerCase())) p]..shuffle(sorteio);
      listas.add([...novas, ...resto]);
    }
  }
  listas.shuffle(Random(hoje));
  final r = <(String, String)>[];
  final vistas = <String>{};
  for (var i = 0;; i++) {
    var algum = false;
    for (final ls in listas) {
      if (i >= ls.length) continue;
      algum = true;
      if (vistas.add(ls[i].$1.toLowerCase())) r.add(ls[i]);
    }
    if (!algum) break;
  }
  return r;
}

/// Todas as palavras que as lições [escolhidas] dão aos jogos (sem as que a pessoa tirou dos jogos ou
/// apagou), sem repetir — o total que a tela "Lições das palavras" mostra. Os jogos usam até 40 por faixa.
List<(String, String)> palavrasDasLicoesEscolhidas({
  required List<Trilha> trilhas,
  required Iterable<String> escolhidas,
  required IndicePalavras indice,
  BancoPalavras banco = BancoPalavras.vazio,
  int hoje = 0,
}) {
  final fora = {
    for (final p in banco.palavras.values)
      if (p.removida || !p.noJogo) p.chave,
  };
  final vistas = <String>{};
  return [
    for (final p in [..._revezadas(trilhas, escolhidas.toSet(), indice, hoje), ..._comunsDaEscolha(trilhas, escolhidas.toSet(), indice)])
      if (!fora.contains(p.$1.toLowerCase()) && vistas.add(p.$1.toLowerCase())) p,
  ];
}
