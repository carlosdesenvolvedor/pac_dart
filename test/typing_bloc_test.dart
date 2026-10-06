import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';

void main() {
  _deadKeys();
  group('TypingBloc — motor de digitação', () {
    late TypingBloc bloc;

    setUp(() => bloc = TypingBloc());
    tearDown(() => bloc.close());

    Future<void> digita(String texto) async {
      for (final ch in texto.split('')) {
        bloc.add(TeclaDigitada(ch));
      }
      await Future<void>.delayed(Duration.zero);
    }

    test('tecla correta avança, errada conta erro e não avança', () async {
      bloc.add(const TrechoCarregado('var x = 1;'));
      await digita('var');
      expect(bloc.state.idx, 3);
      bloc.add(const TeclaDigitada('X')); // errado: esperado ' '
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.idx, 3);
      expect(bloc.state.errosTrecho, 1);
      expect(bloc.state.ultimoErrou, isTrue);
    });

    test('após Enter pula TODA a indentação (armadilha nº 1)', () async {
      bloc.add(const TrechoCarregado('if (a) {\n  print(1);\n}'));
      await digita('if (a) {\n');
      // idx deve estar no "p" de print (pulou os 2 espaços)
      expect(bloc.state.chars[bloc.state.idx], 'p');
      expect(bloc.state.idx, 11);
    });

    test('indentação profunda (4+ espaços) também é pulada', () async {
      bloc.add(const TrechoCarregado('a {\n    b;\n}'));
      await digita('a {\n');
      expect(bloc.state.chars[bloc.state.idx], 'b');
    });

    test('Backspace volta toda a indentação auto-consumida até o \\n', () async {
      bloc.add(const TrechoCarregado('if (a) {\n  print(1);\n}'));
      await digita('if (a) {\np');
      bloc.add(const BackspaceApertado()); // volta o p
      bloc.add(const BackspaceApertado()); // volta indentação inteira até o \n
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.chars[bloc.state.idx], '\n');
    });

    test('conclui o trecho e trava a digitação', () async {
      bloc.add(const TrechoCarregado('var a;'));
      await digita('var a;');
      expect(bloc.state.concluido, isTrue);
      final idxAntes = bloc.state.idx;
      bloc.add(const TeclaDigitada('x'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.idx, idxAntes);
    });

    test('trecho terminando em } após \\n conclui ao digitar a última tecla', () async {
      bloc.add(const TrechoCarregado('a {\n  b;\n}'));
      await digita('a {\nb;\n}');
      expect(bloc.state.concluido, isTrue);
    });

    test('score acumula e ganha bônus na conclusão', () async {
      bloc.add(const TrechoCarregado('ab'));
      await digita('ab');
      expect(bloc.state.score, greaterThanOrEqualTo(2 + 5));
    });

    test('precisão considera erros da sessão', () async {
      bloc.add(const TrechoCarregado('ab'));
      bloc.add(const TeclaDigitada('x')); // erro
      await digita('ab');
      expect(bloc.state.precisao, lessThan(100));
    });

    test('reiniciar trecho zera posição mas mantém sessão', () async {
      bloc.add(const TrechoCarregado('abc'));
      await digita('ab');
      final acertos = bloc.state.acertosSessao;
      bloc.add(const TrechoReiniciado());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.idx, 0);
      expect(bloc.state.acertosSessao, acertos);
    });
  });
}

// ── tecla morta do teclado ABNT (~ ^ ´ `) ───────────────────────────────
void _deadKeys() {
  group('acento morto (ABNT)', () {
    late TypingBloc bloc;
    setUp(() => bloc = TypingBloc());
    tearDown(() => bloc.close());

    Future<void> digita(List<String> teclas) async {
      for (final t in teclas) {
        bloc.add(TeclaDigitada(t));
      }
      await Future<void>.delayed(Duration.zero);
    }

    test('o espaço que solta o ~ não conta erro', () async {
      bloc.add(const TrechoCarregado('a ~/ b'));
      await digita(['a', ' ', '~', ' ', '/']);
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.idx, 4);
    });

    test('espaço ANTES do ~ chegar também é engolido', () async {
      bloc.add(const TrechoCarregado('a ~/ b'));
      await digita(['a', ' ', ' ', '~']);
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.idx, 3);
    });

    test('erro comum continua sendo cobrado', () async {
      bloc.add(const TrechoCarregado('a b'));
      await digita(['a', 'x']);
      expect(bloc.state.errosTrecho, 1);
    });
  });

  group('tecla morta do US-International', () {
    late TypingBloc bloc;
    setUp(() => bloc = TypingBloc());
    tearDown(() => bloc.close());

    Future<void> digita(List<String> teclas) async {
      for (final t in teclas) {
        bloc.add(TeclaDigitada(t));
      }
      await Future<void>.delayed(Duration.zero);
    }

    test("' + c virou ç: vale pelo apóstrofo e pelo c (o'clock)", () async {
      bloc.add(const TrechoCarregado("It's ten o'clock."));
      await digita("It's ten o".split(''));
      await digita(['ç', 'l', 'o', 'c', 'k', '.']);
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
    });

    test("' + a virou á numa string do Dart", () async {
      bloc.add(const TrechoCarregado("x = 'abc';"));
      await digita('x = '.split(''));
      await digita(['á', 'b', 'c', "'", ';']);
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
    });

    test('letra fundida que não bate com o texto continua errada', () async {
      bloc.add(const TrechoCarregado("o'clock"));
      await digita(['o', 'á']); // o texto espera ' + c, não ' + a
      expect(bloc.state.errosTrecho, 1);
      expect(bloc.state.idx, 1);
    });

    test('acento legítimo do português não é desdobrado', () async {
      bloc.add(const TrechoCarregado('pé'));
      await digita(['p', 'é']);
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
    });
  });

  group('frases de inglês', () {
    late TypingBloc bloc;
    setUp(() => bloc = TypingBloc());
    tearDown(() => bloc.close());

    Future<void> digita(Object teclas) async {
      final lista = teclas is String ? teclas.split('') : teclas as List<String>;
      for (final t in lista) {
        bloc.add(TeclaDigitada(t));
      }
      await Future<void>.delayed(Duration.zero);
    }

    test('acento ´ no lugar do apóstrofo vale (hábito do ABNT2: "don´t")', () async {
      bloc.add(const TrechoCarregado("I don't know."));
      await digita(['I', ' ', 'd', 'o', 'n', '´', 't', ' ', 'k', 'n', 'o', 'w', '.']);
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
    });

    test('´ só vale como apóstrofo onde o texto espera apóstrofo', () async {
      bloc.add(const TrechoCarregado('dont'));
      await digita(['d', 'o', 'n', '´']);
      expect(bloc.state.errosTrecho, 1);
    });

    test('espaço repetido e NBSP não contam erro', () async {
      bloc.add(const TrechoCarregado('I am here.'));
      await digita(['I', ' ', ' ', 'a', 'm', '\u00A0', 'h', 'e', 'r', 'e', '.']);
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
    });

    test('reticências unicode valem pelos três pontos', () async {
      bloc.add(const TrechoCarregado('Well...'));
      await digita(['W', 'e', 'l', 'l', '…']);
      expect(bloc.state.concluido, isTrue);
      expect(bloc.state.errosTrecho, 0);
    });

    test('texto-alvo com aspas curvas é normalizado ao carregar', () async {
      bloc.add(const TrechoCarregado('It’s ok.'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.chars.join(), "It's ok.");
    });

    test('tolerante: pontuação preenchida sozinha e 1ª maiúscula livre', () async {
      bloc.add(const TrechoCarregado("Hi, I'm Ana. Nice to meet you!", tolerante: true));
      await digita("hi I'm Ana Nice to meet you");
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
    });

    test('tolerante: digitar a pontuação mesmo assim não duplica nem erra', () async {
      bloc.add(const TrechoCarregado('Yes, please.', tolerante: true));
      await digita('Yes, please.');
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
    });

    test('tolerante: maiúscula que é conteúdo (I, dias) continua exigida', () async {
      bloc.add(const TrechoCarregado('See you on Monday.', tolerante: true));
      await digita('see you on m');
      expect(bloc.state.errosTrecho, 1);
    });

    test('tolerante: apóstrofo e números com : no meio continuam exigidos', () async {
      bloc.add(const TrechoCarregado("It's 7:30.", tolerante: true));
      await digita('Its');
      expect(bloc.state.errosTrecho, 1);
      bloc.add(const TrechoCarregado("It's 7:30.", tolerante: true));
      await digita("It's 730");
      expect(bloc.state.errosPorPosicao.keys, [6]);
    });

    test('erros contados por posição', () async {
      bloc.add(const TrechoCarregado('cat'));
      await digita(['c', 'x', 'y', 'a', 't']);
      expect(bloc.state.errosPorPosicao, {1: 2});
      expect(bloc.state.concluido, isTrue);
    });

    test('Backspace volta pela pontuação preenchida sozinha', () async {
      bloc.add(const TrechoCarregado('Hi, Tom.', tolerante: true));
      await digita('Hi');
      expect(bloc.state.idx, 3); // a vírgula entrou sozinha
      bloc.add(const BackspaceApertado());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.idx, 1);
    });
  });

  group('alternativas e maiúsculas', () {
    late TypingBloc bloc;
    setUp(() => bloc = TypingBloc());
    tearDown(() => bloc.close());

    Future<void> digita(String texto) async {
      for (final t in texto.split('')) {
        bloc.add(TeclaDigitada(t));
      }
      await Future<void>.delayed(Duration.zero);
    }

    test('forma plena aceita no lugar da contração: o alvo troca na 1ª divergência', () async {
      bloc.add(const TrechoCarregado("I'm not sure.", tolerante: true, alternativas: ['I am not sure.']));
      await digita('I am not sure');
      expect(bloc.state.errosTrecho, 0);
      expect(bloc.state.concluido, isTrue);
      expect(bloc.state.chars.join(), 'I am not sure.');
    });

    test('sem alternativa declarada, a divergência é erro', () async {
      bloc.add(const TrechoCarregado("I'm not sure.", tolerante: true));
      await digita('I a');
      expect(bloc.state.errosTrecho, 2); // o espaço e o "a" no lugar do apóstrofo
      expect(bloc.state.idx, 1);
    });

    test('erro só de maiúscula vai para errosDeCaixa (não derruba a palavra)', () async {
      bloc.add(const TrechoCarregado('See you on Monday.', tolerante: true));
      await digita('See you on mMonday');
      expect(bloc.state.errosDeCaixa, {11: 1});
      expect(bloc.state.errosPorPosicao, isEmpty);
      expect(bloc.state.concluido, isTrue);
    });
  });
}

