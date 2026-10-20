// Palavras novas de cada lição do inglês (o que a lição apresenta pela 1ª vez) e o pool digitável que
// alimenta os jogos do Arcade.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';

Trecho _t(String cod, {String dica = '', String alvo = '', String quem = '', String id = ''}) =>
    Trecho(cod: cod, dica: dica, out: '', alvo: alvo, quem: quem, id: id);

Licao _l(String id, List<Trecho> trechos) => Licao(nome: id, emoji: '📘', id: id, trechos: trechos);

const _dic = Dicionario({
  'i': 'eu',
  'work': 'trabalhar; trabalho',
  'works': 'trabalha (de work)',
  'worked': 'trabalhou (passado de work)',
  'on': 'em, sobre',
  'monday': 'segunda-feira',
  'mike': 'Mike (nome)',
  'chicago': 'Chicago (cidade)',
  'coffee': 'café',
  'tea': 'chá',
  'the': 'o, a',
  'is': 'é',
  "i'm": 'eu sou, eu estou (I am)',
  'tired': 'cansado',
  'very': 'muito',
  'apple': 'maçã',
  'banana': 'banana',
  'cherry': 'cereja',
  'grape': 'uva',
  'lemon': 'limão',
  'mango': 'manga',
  'melon': 'melão',
  'orange': 'laranja; cor de laranja',
  'peach': 'pêssego',
  'pear': 'pera',
  'love': 'amar, adorar',
  'thing': 'coisa',
  'even': 'até, mesmo',
  'evening': 'noite, fim de tarde',
  'forty-five': 'quarenta e cinco',
  'a-n-a': 'A-N-A (soletrado)',
  'stakeholder': 'parte interessada',
  'able': 'capaz, apto (be able to: conseguir)',
});

void main() {
  group('traducaoCurta', () {
    test('o 1º sentido, sem marcadores, com reticências no limite', () {
      expect(traducaoCurta('capaz, apto (be able to: conseguir)'), 'capaz');
      expect(traducaoCurta('foi, ia (passado de go)'), 'foi');
      expect(traducaoCurta('aceito, aceitou (de accept)'), 'aceito');
      expect(traducaoCurta('Mike (nome)'), 'Mike');
      expect(traducaoCurta("gato (+ 's: de Cat / Cat is)"), 'gato');
      expect(traducaoCurta('trabalhar; trabalho'), 'trabalhar');
      expect(traducaoCurta('responsabilidade compartilhada'), 'responsabilidade…');
      expect(traducaoCurta('responsabilidade compartilhada').length, lessThanOrEqualTo(18));
      expect(traducaoCurta('responsabilidade compartilhada', max: 40), 'responsabilidade compartilhada');
      expect(traducaoCurta(null), '');
      expect(traducaoCurta('(usado em perguntas) do'), isNotEmpty);
    });

    test('baseDoLema e ehNomeProprio', () {
      expect(baseDoLema('trabalha (de work)'), 'work');
      expect(baseDoLema('foi (passado de go)'), 'go');
      expect(baseDoLema('contas (plural de account)'), 'account');
      expect(baseDoLema('corredor (de avião, loja)'), isNull);
      expect(baseDoLema('café'), isNull);
      expect(ehNomeProprio('Chicago (cidade)'), isTrue);
      expect(ehNomeProprio('café'), isFalse);
      expect(ehNomeProprio('Texas (estado dos EUA)'), isTrue);
      expect(ehNomeProprio('carvalho; Oak (nome de rua)'), isFalse, reason: 'o 1º sentido é palavra comum');
      expect(ehNomeProprio('Flutter (framework de apps do Google); agitar'), isFalse);
    });
  });

  group('IndicePalavras (currículo de mentira)', () {
    final trilhas = [
      Trilha(nivel: 'T1', emoji: '1', licoes: [
        _l('t1.a', [
          _t('I work on Monday.', alvo: 'work', quem: 'voce', id: 'f-1'),
          _t("I'm tired, Mike.", quem: 'mike'),
          _t('Coffee is the thing.'),
          _t('I love the evening, even on Monday.'),
        ]),
        _l('t1.b', [
          _t('Mike works in Chicago.', quem: 'ana'),
          _t('I worked 45 days, forty-five days.'),
          _t('A-N-A. I love tea.', alvo: 'tea'),
          _t('The stakeholder is able.'),
        ]),
        _l('t1.c', [
          _t('Apple banana cherry grape lemon mango melon orange peach pear.', alvo: 'pear'),
        ]),
      ]),
      Trilha(nivel: 'Meu texto', emoji: '📝', textoId: 'k1', licoes: [
        _l('txt:k1-1', [_t('I love apple and coffee and banana.')]),
      ]),
    ];

    test('1ª aparição, alvo primeiro, Monday com maiúscula, filtros', () {
      final ind = IndicePalavras.de(trilhas, _dic);
      final a = ind.novasDe('t1.a').map((p) => p.en).toList();
      expect(a.first, 'work', reason: 'o alvo vem primeiro');
      expect(a, contains('Monday'));
      expect(a, containsAll(['tired', 'coffee', 'thing', 'love', 'evening', 'even']));
      // stopwords, contrações, nomes e palavras curtas ficam de fora
      expect(a, isNot(contains('the')));
      expect(a, isNot(contains('on')));
      expect(a, isNot(contains("i'm")));
      expect(a, isNot(contains('mike')));
      expect(a.map((e) => e.toLowerCase()), isNot(contains('i')));
      final b = ind.novasDe('t1.b').map((p) => p.en).toList();
      expect(b.first, 'tea');
      expect(b, isNot(contains('works')), reason: 'works vem de work, já apresentada');
      expect(b, isNot(contains('worked')));
      expect(b, isNot(contains('chicago')), reason: 'nome de cidade');
      expect(b, isNot(contains('45')));
      expect(b, isNot(contains('a-n-a')), reason: 'letras soletradas');
      expect(b, contains('forty-five'), reason: 'com hífen: treinável (mas não vai para os jogos)');
      expect(b, contains('stakeholder'), reason: 'é personagem de uma cena, mas é palavra comum');
      expect(b, contains('able'));
      final pf = ind.novasDe('t1.b').firstWhere((p) => p.en == 'forty-five');
      expect(pf.deJogo, isFalse);
      expect(ind.novasDe('t1.b').firstWhere((p) => p.en == 'able').pt, 'capaz');
    });

    test('teto de 8 por lição com o alvo primeiro', () {
      final c = IndicePalavras.de(trilhas, _dic).novasDe('t1.c');
      expect(c.length, 8);
      expect(c.first.en, 'pear');
    });

    test('pool dos jogos: só letras, com as de função, sem nomes', () {
      final ind = IndicePalavras.de(trilhas, _dic);
      final pool = ind.poolPorLicao['t1.a']!;
      expect(pool, containsAll(['work', 'Monday', 'the', 'coffee']));
      expect(pool, isNot(contains('mike')));
      expect(pool, isNot(contains("i'm")));
      expect(pool, isNot(contains('on')), reason: 'menos de 3 letras');
      expect(ind.poolPorLicao['t1.b'], contains('works'), reason: 'o pool não tem regra de 1ª vez');
      expect(ind.poolPorLicao['t1.b'], isNot(contains('forty-five')));
    });

    test('trilha própria fica de fora do índice; índice memorizado', () {
      final ind = IndicePalavras.de(trilhas, _dic);
      expect(ind.novasPorLicao.containsKey('txt:k1-1'), isFalse);
      expect(identical(IndicePalavras.de(trilhas, _dic), ind), isTrue);
      // a chave do memo são as trilhas do CURSO: lista nova, texto colado ou apagado não refazem
      expect(identical(IndicePalavras.de([...trilhas], _dic), ind), isTrue);
      expect(identical(IndicePalavras.de(trilhas.where((t) => !t.propria).toList(), _dic), ind), isTrue);
      expect(
          identical(
              IndicePalavras.de([
                ...trilhas,
                Trilha(nivel: 'Outro', emoji: '📝', textoId: 'k2', licoes: [
                  _l('txt:k2-1', [_t('Zebra.')]),
                ]),
              ], _dic),
              ind),
          isTrue);
      // trilha do curso trocada (outra instância), outra ordem ou outro dicionário: refaz
      final trocada = [Trilha(nivel: trilhas.first.nivel, emoji: trilhas.first.emoji, licoes: trilhas.first.licoes), ...trilhas.skip(1)];
      expect(identical(IndicePalavras.de(trocada, _dic), ind), isFalse);
      final ind2 = IndicePalavras.de(trilhas, _dic);
      expect(identical(ind2, ind), isFalse, reason: 'o memo guarda um só');
      expect(identical(IndicePalavras.de(trilhas, Dicionario({..._dic.entradas})), ind2), isFalse);
      expect(ind.primeiraLicao['works'], 't1.b');
      // palavra de função / nome de personagem
      expect(ind.ehFuncaoOuNome('The'), isTrue);
      expect(ind.ehFuncaoOuNome('mike'), isTrue);
      expect(ind.ehFuncaoOuNome('coffee'), isFalse);
      expect(ind.traducao('Coffee'), 'café');
      expect(ind.exemploDe('coffee')!.frase, 'Coffee is the thing.');
      expect(ind.formaDe('monday'), 'Monday');
      expect(ind.palavra('tired')!.licaoId, 't1.a');
    });

    test('novasDaTrilha: união das lições, sem repetir, até 12', () {
      final ind = IndicePalavras.de(trilhas, _dic);
      final n = ind.novasDaTrilha(trilhas.first);
      expect(n.length, 12);
      expect(n.map((p) => p.chave).toSet().length, 12);
      expect(ind.novasDaTrilha(trilhas.last), isEmpty);
    });

    test('lição de texto próprio: as que o curso ainda não apresentou à pessoa', () {
      final ind = IndicePalavras.de(trilhas, _dic);
      final licao = trilhas.last.licoes.first;
      expect(novasDaLicaoPropria(licao, ind).map((p) => p.en), containsAll(['love', 'apple', 'coffee', 'banana']));
      final comA = novasDaLicaoPropria(licao, ind, concluidas: {'t1.a'}).map((p) => p.en);
      expect(comA, isNot(contains('love')));
      expect(comA, isNot(contains('coffee')));
      expect(comA, containsAll(['apple', 'banana']));
    });
  });

  group('com o curso e o dicionário de verdade', () {
    final dic = Dicionario.fromJson(jsonDecode(File('assets/ingles/dicionario.json').readAsStringSync()));
    final trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
        .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
        .toList();
    final ind = IndicePalavras.de(trilhas, dic);

    test('mediana de 2 a 6 palavras novas por lição, no máximo 8', () {
      final ns = [for (final t in trilhas) for (final l in t.licoes) ind.novasDe(l.id).length]..sort();
      final mediana = ns[ns.length ~/ 2];
      final total = ns.fold<int>(0, (a, b) => a + b);
      // ignore: avoid_print
      print('lições ${ns.length} · mediana $mediana · máx ${ns.last} · total $total · zeros ${ns.where((n) => n == 0).length}');
      expect(mediana, inInclusiveRange(2, 6));
      expect(ns.last, lessThanOrEqualTo(8));
    });

    test('sem nomes de personagem nem cidades', () {
      final todas = {for (final l in ind.novasPorLicao.values) for (final p in l) p.chave};
      final pool = {for (final l in ind.poolPorLicao.values) for (final p in l) p.toLowerCase()};
      for (final nome in ['mike', 'ana', 'chicago', 'sarah', 'souza', 'texas', 'minas', 'gerais']) {
        expect(todas, isNot(contains(nome)));
        expect(pool, isNot(contains(nome)));
      }
      // palavras comuns que as regras de flexão confundiriam continuam sendo palavra nova
      expect(todas, containsAll(['thing', 'evening']));
    });

    test('todo o pool é só letras (3–14) e tem tradução curta de até 18', () {
      for (final lista in ind.poolPorLicao.values) {
        for (final w in lista) {
          expect(RegExp(r'^[A-Za-z]{3,14}$').hasMatch(w), isTrue, reason: w);
          final pt = ind.traducao(w);
          expect(pt, isNotNull, reason: w);
          expect(pt!.isNotEmpty && pt.length <= 18, isTrue, reason: '$w → $pt');
        }
      }
    });
  });
}
