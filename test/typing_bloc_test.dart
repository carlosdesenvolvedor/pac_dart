import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';

void main() {
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
