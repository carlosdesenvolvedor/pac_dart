// A conferência do modo Montar (Fase 7): a frase montada com blocos contra a frase certa — ordem EXATA, um erro por
// palavra fora do lugar, na chave que o `avaliarDigitacao` lê (onde a palavra começa no texto).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/avaliacao.dart';
import 'package:pac_dart/features/ingles/domain/montagem.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';

List<Bloco> blocos(String palavras) => [
      for (final (i, w) in palavras.split(' ').indexed) Bloco(i, w),
    ];

void main() {
  group('conferirMontagem', () {
    test('frase montada certa, na ordem: certa, sem erro, todas as pastilhas certas', () {
      final c = conferirMontagem('I like cats.', blocos('I like cats'));
      expect(c.certa, isTrue);
      expect(c.erros, isEmpty);
      expect(c.escolhidasCertas, [true, true, true]);
    });

    test('maiúscula, acento, apóstrofo e pontuação não pesam', () {
      expect(conferirMontagem("Don't worry, Mike!", blocos("don't WORRY mike")).certa, isTrue);
      expect(conferirMontagem('I like café.', blocos('i like cafe')).certa, isTrue);
      expect(conferirMontagem('See you at 7:30.', blocos('See you at 7 30')).certa, isTrue);
    });

    test('nada montado: não há o que conferir (sem erro, não conclui)', () {
      final c = conferirMontagem('I like cats.', const []);
      expect(c.certa, isFalse);
      expect(c.erros, isEmpty);
      expect(c, ConferenciaMontagem.nenhuma);
    });

    test('as palavras certas em OUTRA ordem não valem', () {
      final c = conferirMontagem('I like cats.', blocos('cats like I'));
      expect(c.certa, isFalse);
      expect(c.erros, isNotEmpty);
      expect(c.escolhidasCertas.contains(false), isTrue);
    });

    test('uma palavra trocada por outra: 1 erro, exatamente na posição dela', () {
      // "I like cats." — cats começa na posição 7
      final c = conferirMontagem('I like cats.', blocos('I like dogs'));
      expect(c.certa, isFalse);
      expect(c.erros, {7: 1});
      expect(c.escolhidasCertas, [true, true, false]);
    });

    test('faltou palavra (montou menos): cada palavra que faltou é 1 erro', () {
      final c = conferirMontagem('I like cats a lot.', blocos('I like cats'));
      expect(c.certa, isFalse);
      expect(c.erros, {12: 1, 14: 1}); // "a" e "lot"
      expect(c.escolhidasCertas, [true, true, true]);
    });

    test('enfeite no meio ou no fim: não está certa, mas só o enfeite fica vermelho e não soma erro', () {
      final meio = conferirMontagem('I like cats.', blocos('I house like cats'));
      expect(meio.certa, isFalse);
      expect(meio.escolhidasCertas, [true, false, true, true]);
      expect(meio.erros, isEmpty, reason: 'todas as palavras da frase estão no lugar; só sobrou um bloco');
      final fim = conferirMontagem('I like cats.', blocos('I like cats house'));
      expect(fim.certa, isFalse);
      expect(fim.escolhidasCertas, [true, true, true, false]);
      expect(fim.erros, isEmpty);
    });

    test('palavras repetidas: qualquer um dos blocos "very" vale, mas a conta fecha', () {
      expect(conferirMontagem('It is very very good.', blocos('It is very very good')).certa, isTrue);
      final c = conferirMontagem('It is very very good.', blocos('It is very good very'));
      expect(c.certa, isFalse);
      expect(c.erros.length, 1);
    });

    test('palavra com hífen é UMA palavra: as duas metades erradas somam um erro só, na chave da palavra', () {
      // "It is a well-known fact." — well-known começa na posição 8
      final c = conferirMontagem('It is a well-known fact.', blocos('It is a famous name fact'));
      expect(c.certa, isFalse);
      expect(c.erros, {8: 1});
      final metade = conferirMontagem('It is a well-known fact.', blocos('It is a well name fact'));
      expect(metade.erros, {8: 1});
      expect(conferirMontagem('It is a well-known fact.', blocos('It is a well known fact')).certa, isTrue);
    });

    test('frase de uma palavra só', () {
      expect(conferirMontagem('Hello!', blocos('hello')).certa, isTrue);
      final c = conferirMontagem('Hello!', blocos('bye'));
      expect(c.certa, isFalse);
      expect(c.erros, {0: 1});
    });

    test('frase sem palavra nenhuma nunca fica certa', () {
      expect(conferirMontagem('...', blocos('a')).certa, isFalse);
    });

    test('as chaves dos erros alimentam o avaliarDigitacao: 1 palavra errada 2× derruba a nota', () {
      const frase = 'I like cats.';
      final c = conferirMontagem(frase, blocos('I like dogs'));
      final erros = <int, int>{};
      for (var vez = 0; vez < 2; vez++) {
        c.erros.forEach((k, v) => erros[k] = (erros[k] ?? 0) + v);
      }
      final d = avaliarDigitacao(frase, errosPorPosicao: erros);
      expect(d.palavrasErradas, {2}, reason: 'a 3ª palavra (cats) passou do que a nota tolera');
    });

    test('frase de 25 palavras montada na ordem confere certa', () {
      final frase = List.generate(25, (i) => 'word${String.fromCharCode(97 + i % 26)}$i').join(' ');
      expect(conferirMontagem('$frase.', blocos(frase)).certa, isTrue);
    });
  });

  group('os blocos que a lição usa (montarBlocos com a reserva em inglês)', () {
    test('N blocos da frase + 2 a 5 de enfeite, que nunca repetem palavra da frase', () {
      for (final frase in ['Hi!', 'I like cats.', 'She is going to the market with her sister today.']) {
        final b = montarBlocos(frase, apoio: const ['The dog runs fast', 'Open the door'], aleatorio: Random(3), reserva: palavrasDeReservaEn);
        final certos = b.where((x) => !x.distrator).length;
        final enfeites = b.where((x) => x.distrator).map((x) => x.texto.toLowerCase()).toList();
        expect(certos, partirFrase(frase).where((p) => p.palavra).length, reason: frase);
        expect(enfeites.length, inInclusiveRange(2, 5), reason: frase);
        final daFrase = {for (final p in partirFrase(frase)) if (p.palavra) p.texto.toLowerCase()};
        expect(enfeites.any(daFrase.contains), isFalse, reason: frase);
      }
    });

    test('mesma semente, mesmos blocos', () {
      List<String> textos(int s) => [
            for (final x in montarBlocos('I like cats.', apoio: const ['Open the door'], aleatorio: Random(s), reserva: palavrasDeReservaEn)) x.texto
          ];
      expect(textos(5), textos(5));
    });
  });
}
