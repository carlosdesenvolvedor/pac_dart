// O vocabulário dos jogos do Arcade no inglês, montado com o que o aluno estudou.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/vocabulario_aluno.dart';

void main() {
  final dic = Dicionario.fromJson(jsonDecode(File('assets/ingles/dicionario.json').readAsStringSync()));
  final curso = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
      .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
      .toList();
  final ind = IndicePalavras.de(curso, dic);
  final ids = [for (final t in curso) for (final l in t.licoes) l.id];
  const hoje = 20400;

  void conferir(VocabularioJogo v) {
    final todas = v.todas;
    expect(todas.map((w) => w.toLowerCase()).toSet().length, todas.length, reason: 'sem repetir');
    for (final w in todas) {
      expect(RegExp(r'^[A-Za-z]{3,14}$').hasMatch(w), isTrue, reason: w);
      expect(v.traducao(w), isNotNull, reason: 'sem tradução: $w');
    }
    for (final w in v.curtas) {
      if (!palavrasCurtasEn.contains(w)) expect(w.length, inInclusiveRange(3, 5), reason: w);
    }
    for (final w in v.medias) {
      if (!palavrasMediasEn.contains(w)) expect(w.length, inInclusiveRange(6, 8), reason: w);
    }
    for (final w in v.longas) {
      if (!palavrasLongasEn.contains(w)) expect(w.length, inInclusiveRange(9, 14), reason: w);
    }
    expect(v.curtas.length, inInclusiveRange(12, 40));
    expect(v.medias.length, inInclusiveRange(12, 40));
    expect(v.longas.length, inInclusiveRange(12, 40));
  }

  test('sem progresso: a reserva fixa, pelo menos 12 por faixa, com tradução', () {
    final v = montarVocabularioIngles(trilhas: curso, concluidas: const {}, indice: ind, hoje: hoje);
    conferir(v);
    expect(v.curtas.take(12), palavrasCurtasEn.take(12));
    expect(v.foco, isEmpty);
  });

  test('as palavras das lições concluídas entram (e as da lição atual)', () {
    final feitas = ids.take(10).toSet();
    final v = montarVocabularioIngles(
        trilhas: curso, concluidas: feitas, indice: ind, hoje: hoje, licaoAtualId: ids[10]);
    conferir(v);
    final pool = {for (final id in [...feitas, ids[10]]) ...ind.poolPorLicao[id]!};
    expect(v.todas.where(pool.contains).length, greaterThan(20));
    expect(v.todas, contains('morning'));
  });

  test('foco (em treino) vem primeiro; tiradas dos jogos e apagadas ficam de fora; as minhas entram', () {
    final banco = const BancoPalavras()
        .com(const PalavraDoBanco(en: 'umbrella', pt: 'guarda-chuva', origem: OrigemPalavra.minha, criadaEm: 1))
        .com(const PalavraDoBanco(en: 'good', pt: 'bom', noJogo: false))
        .com(const PalavraDoBanco(en: 'morning', pt: 'manhã', removida: true))
        .com(const PalavraDoBanco(en: 'kitten', pt: 'gatinho', origem: OrigemPalavra.minha, criadaEm: 2))
        .com(const PalavraDoBanco(
            en: 'thanks',
            pt: 'obrigado',
            cartao: CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: hoje - 3, proximoDia: hoje - 1)))
        .comEmTreino(['afternoon', 'pretty'], 5);
    final v = montarVocabularioIngles(
        trilhas: curso, concluidas: ids.take(5).toSet(), indice: ind, banco: banco, hoje: hoje);
    conferir(v);
    expect(v.foco, {'afternoon', 'pretty'});
    expect(v.longas.first, 'afternoon');
    expect(v.medias.first, 'pretty');
    expect(v.todas, isNot(contains('good')));
    expect(v.todas, isNot(contains('morning')));
    expect(v.todas, containsAll(['umbrella', 'kitten', 'thanks']));
    expect(v.traducao('umbrella'), 'guarda-chuva');
    expect(v.medias.indexOf('thanks'), lessThan(v.medias.indexOf('kitten')), reason: 'devidas antes das minhas');
  });

  test('palavras soltas de "Meus cartões" entram com a tradução do cartão', () {
    final cartoes = Trilha(nivel: tituloCartoesAvulsos, emoji: '📝', textoId: idCartoesAvulsos, licoes: const [
      Licao(nome: 'Parte 1', emoji: '📝', id: 'txt-cartoes-1', trechos: [
        Trecho(cod: 'serendipity', dica: 'acaso feliz', out: ''),
        Trecho(cod: 'I saw a kangaroo.', dica: 'Vi um canguru.', out: '', alvo: 'kangaroo', alvoPt: 'canguru'),
        Trecho(cod: 'two words', dica: 'duas palavras', out: ''),
      ]),
    ]);
    final v = montarVocabularioIngles(trilhas: [...curso, cartoes], concluidas: const {}, indice: ind, hoje: hoje);
    expect(v.traducao('serendipity'), 'acaso feliz');
    expect(v.traducao('kangaroo'), 'canguru');
    expect(v.todas, isNot(contains('two words')));
  });

  test('nivelamento de trilhas inteiras: teto de 40 por faixa', () {
    final v = montarVocabularioIngles(trilhas: curso, concluidas: ids.take(300).toSet(), indice: ind, hoje: hoje);
    conferir(v);
    expect(v.curtas.length, 40);
    expect(v.medias.length, 40);
  });

  test('determinístico (mesmo dia = mesmo vocabulário; outro dia muda a amostra antiga)', () {
    final feitas = ids.take(200).toSet();
    final a = montarVocabularioIngles(trilhas: curso, concluidas: feitas, indice: ind, hoje: hoje);
    final b = montarVocabularioIngles(trilhas: curso, concluidas: feitas, indice: ind, hoje: hoje);
    final c = montarVocabularioIngles(trilhas: curso, concluidas: feitas, indice: ind, hoje: hoje + 1);
    expect(a.todas, b.todas);
    expect(a.todas, isNot(c.todas));
  });

  test('VocabularioJogo.deListas guarda as MESMAS listas; níveis como a pista do Turismo', () {
    final fixo = vocabularioDe(Linguagem.dart);
    final v = VocabularioJogo.deListas(fixo);
    expect(identical(v.curtas, fixo.curtas), isTrue);
    expect(identical(v.longas, fixo.longas), isTrue);
    expect(v.poolDoNivel(1), fixo.curtas);
    expect(v.poolDoNivel(2), [...fixo.curtas, ...fixo.medias]);
    expect(v.poolDoNivel(3), [...fixo.medias, ...fixo.longas]);
    expect(v.traducao('void'), isNull);
  });

  test('traducoesEn cobre as 144 palavras da reserva; fichasIngles tem 12', () {
    for (final w in [...palavrasCurtasEn, ...palavrasMediasEn, ...palavrasLongasEn]) {
      final t = traducoesEn[w.toLowerCase()];
      expect(t != null && t.isNotEmpty && t.length <= 18, isTrue, reason: w);
    }
    expect(traducoesEn.length, 144);
    expect(fichasIngles.length, 12);
  });
}
