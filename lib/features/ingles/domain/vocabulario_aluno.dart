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
}) {
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

  /// Põe [w] na faixa dele (ou em [faixa], no enchimento). Devolve se entrou.
  bool por(String w, {String? pt, List<String>? faixa}) {
    final palavra = w.trim();
    if (!_reJogo.hasMatch(palavra)) return false;
    final k = palavra.toLowerCase();
    if (fora.contains(k) || usadas.contains(k)) return false;
    final destino = faixa ?? faixaDe(palavra.length);
    if (destino.length >= maxPorFaixa) return false;
    final t = traducaoDe(palavra, pt);
    if (t == null) return false;
    usadas.add(k);
    destino.add(palavra);
    traducoes[palavra] = t;
    return true;
  }

  String formaDe(String k) => banco[k]?.en ?? indice.formaDe(k);

  // 1. em treino
  for (final k in banco.emTreino) {
    final w = formaDe(k);
    if (por(w)) foco.add(w);
  }

  // 2. vencem hoje, depois as fracas
  for (final p in [...banco.devidas(hoje), ...banco.fracas(hoje)]) {
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
  final ultimas = feitas.length <= recentes ? feitas : feitas.sublist(feitas.length - recentes);
  for (final id in [?licaoAtualId, ...ultimas.reversed]) {
    for (final w in indice.poolPorLicao[id] ?? const <String>[]) {
      por(w);
    }
  }

  // 4. as da pessoa (mais novas primeiro) e as palavras soltas de "Meus cartões"
  final minhas = [
    for (final p in banco.ativas)
      if (p.origem != OrigemPalavra.licao) p,
  ]..sort((a, b) {
      final c = b.criadaEm.compareTo(a.criadaEm);
      return c != 0 ? c : a.chave.compareTo(b.chave);
    });
  for (final p in minhas) {
    por(p.en, pt: p.pt);
  }
  for (final t in trilhas) {
    if (t.textoId != idCartoesAvulsos) continue;
    for (final l in t.licoes) {
      for (final tr in l.trechos) {
        final alvo = (tr.alvo.isNotEmpty ? tr.alvo : tr.cod).trim().replaceAll(RegExp(r'^[^A-Za-z]+|[^A-Za-z]+$'), '');
        if (_reJogo.hasMatch(alvo)) por(alvo, pt: tr.alvo.isNotEmpty ? tr.alvoPt : tr.dicaPlana);
      }
    }
  }

  // 5. amostra das lições antigas (sorteio fixo para o dia)
  final recentesSet = {...ultimas, ?licaoAtualId};
  final antigas = <String>[];
  final vistasAntigas = <String>{};
  for (final id in feitas) {
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

  // 6. enchimento com as listas fixas
  for (final (faixa, reserva) in [
    (curtas, palavrasCurtasEn),
    (medias, palavrasMediasEn),
    (longas, palavrasLongasEn),
  ]) {
    for (final w in reserva) {
      if (faixa.length >= minPorFaixa) break;
      por(w, faixa: faixa);
    }
  }

  return VocabularioJogo(
    curtas: List.unmodifiable(curtas),
    medias: List.unmodifiable(medias),
    longas: List.unmodifiable(longas),
    traducoes: Map.unmodifiable(traducoes),
    foco: Set.unmodifiable(foco),
  );
}
