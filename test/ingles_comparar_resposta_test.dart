import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/comparar_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';

List<String> certas(List<Segmento> s) => [for (final x in s) if (x.acerto == true) x.texto];
List<String> erradas(List<Segmento> s) => [for (final x in s) if (x.acerto == false) x.texto];

void main() {
  group('compararResposta: o que conta como acerto', () {
    test('a resposta igual passa — mesmo sem maiúscula, acento e pontuação', () {
      final c = compararResposta('Eu gostaria de um café, por favor.', 'eu gostaria de um CAFE por favor');
      expect(c.exata, isTrue);
      expect(c.cobertura, 1);
      expect(c.precisao, 1);
      expect(c.sugerida, Rating.good);
      expect(c.acertadas, c.totalEsperadas);
      expect(erradas(c.esperada), isEmpty);
      expect(erradas(c.digitada), isEmpty);
    });

    test('um errinho de digitação em palavra comprida é perdoado; em palavra curta, não', () {
      final c = compararResposta('Era uma vez um fazendeiro e sua esposa.', 'Era uma vez um fazendero e sua esposa');
      expect(c.cobertura, 1, reason: '"fazendero" ≈ "fazendeiro" (1 letra)');
      expect(c.exata, isFalse, reason: 'mas não é igual: o card diz que houve um erro');
      expect(c.sugerida, Rating.good);

      final curta = compararResposta('Eu vi uma casa', 'Eu vi um casa');
      expect(erradas(curta.esperada), ['uma'], reason: '"um" e "uma" são palavras diferentes');
    });

    test('dois erros só valem em palavras de 9+ letras', () {
      expect(compararResposta('extraordinário', 'extraordinaro').cobertura, 1, reason: '1 a menos');
      expect(compararResposta('extraordinário', 'extrordinaro').cobertura, 1, reason: '2 de diferença em 14 letras');
      expect(compararResposta('esposa', 'esposta').cobertura, 1, reason: '1 de diferença');
      expect(compararResposta('esposa', 'espoxta').cobertura, 0, reason: '2 de diferença em 6 letras: demais');
    });

    test('a ordem das palavras diferente ainda acerta (tradução livre)', () {
      final c = compararResposta('Eu estava muito cansado ontem', 'Ontem eu estava muito cansado');
      expect(c.cobertura, 1);
      expect(c.precisao, 1);
      expect(c.exata, isFalse);
      expect(c.sugerida, Rating.good);
    });

    test('palavras repetidas casam uma vez cada', () {
      final c = compararResposta('a casa da casa', 'casa');
      expect(c.cobertura, .25, reason: '1 de 4 palavras ("a", "casa", "da", "casa"): só uma das duas "casa" foi escrita');
      expect(certas(c.esperada), ['casa']);
      expect(erradas(c.esperada), ['a', 'da', 'casa']);
    });

    test('números e hífen: cada trecho é uma palavra', () {
      final c = compararResposta('Ele tem 25 anos e um guarda-chuva', 'ele tem 25 anos e um guarda chuva');
      expect(c.cobertura, 1);
      expect(compararResposta('São 25 anos', 'São 52 anos').cobertura, closeTo(2 / 3, 1e-9));
    });
  });

  group('compararResposta: a nota sugerida', () {
    test('faltou pouco → bom; faltou bastante → difícil; quase nada → errei', () {
      // 8 palavras esperadas
      const esperada = 'Nós fomos ao mercado comprar frutas e verduras';
      expect(compararResposta(esperada, 'Nós fomos ao mercado comprar frutas e verduras').sugerida, Rating.good);
      expect(compararResposta(esperada, 'Nós fomos ao mercado comprar frutas e').sugerida, Rating.good, reason: '7 de 8 = 87%');
      expect(compararResposta(esperada, 'Nós fomos ao mercado comprar').sugerida, Rating.hard, reason: '5 de 8 = 62%');
      expect(compararResposta(esperada, 'Nós fomos ao').sugerida, Rating.again, reason: '3 de 8');
      expect(compararResposta(esperada, 'banana azul chove hoje').sugerida, Rating.again);
    });

    test('palavra a mais pesa: acertou tudo mas escreveu muito além → não é "bom"', () {
      const esperada = 'Eu gosto de café';
      final c = compararResposta(esperada, 'Eu gosto de café e também de chá e de leite e de pão');
      expect(c.cobertura, 1);
      expect(c.precisao, lessThan(.5));
      expect(c.sugerida, Rating.again);
      final pouco = compararResposta(esperada, 'Eu gosto muito de café');
      expect(pouco.precisao, .8);
      expect(pouco.sugerida, Rating.good);
    });

    test('vazio, só espaços ou só pontuação: errei; nunca sugere "fácil"', () {
      for (final t in ['', '   ', '...', '?!']) {
        final c = compararResposta('Eu gosto de café', t);
        expect(c.sugerida, Rating.again, reason: '"$t"');
        expect(c.cobertura, 0);
      }
      for (final t in ['Eu gosto de café', 'eu gosto de café.']) {
        expect(compararResposta('Eu gosto de café', t).sugerida, isNot(Rating.easy));
      }
    });

    test('resposta esperada sem palavra nenhuma não quebra', () {
      final c = compararResposta('...', 'qualquer coisa');
      expect(c.cobertura, 0);
      expect(c.exata, isFalse);
      expect(c.totalEsperadas, 0);
    });
  });

  group('compararResposta: os pedaços para mostrar', () {
    test('mantém a grafia, a pontuação e os espaços originais, só marca as palavras', () {
      final c = compararResposta('Olá, tudo bem?', 'ola tudo mal');
      expect(c.esperada.map((s) => s.texto).join(), 'Olá, tudo bem?');
      expect(c.digitada.map((s) => s.texto).join(), 'ola tudo mal');
      expect(c.esperada, const [
        Segmento('Olá', true),
        Segmento(', '),
        Segmento('tudo', true),
        Segmento(' '),
        Segmento('bem', false),
        Segmento('?'),
      ]);
      expect(c.digitada, const [
        Segmento('ola', true),
        Segmento(' '),
        Segmento('tudo', true),
        Segmento(' '),
        Segmento('mal', false),
      ]);
      expect(c.acertadas, 2);
      expect(c.totalEsperadas, 3);
    });

    test('o que a pessoa escreveu a mais fica marcado como errado; o que faltou, na resposta', () {
      final c = compararResposta('Eu amo Roma', 'Eu amo muito Roma');
      expect(erradas(c.digitada), ['muito']);
      expect(erradas(c.esperada), isEmpty);
      final f = compararResposta('Eu amo muito Roma', 'Eu amo Roma');
      expect(erradas(f.esperada), ['muito']);
    });

    test('texto vazio dá lista vazia de segmentos', () {
      final c = compararResposta('Oi', '');
      expect(c.digitada, isEmpty);
      expect(c.esperada, const [Segmento('Oi', false)]);
    });

    test('acentos, ç e til são tratados como a letra simples nos dois lados', () {
      final c = compararResposta('Coração de ação, não é? Pão!', 'coracao de acao nao e pao');
      expect(c.cobertura, 1);
      expect(c.exata, isTrue);
    });
  });
}
