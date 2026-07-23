import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';

/// Teclados reais soltam variantes do ASCII: no Mac, `~`+espaço vira U+02DC
/// (˜); celulares trocam aspas retas por curvas e hífen por travessão.
/// O motor precisa aceitar tudo isso como a tecla "de verdade".
void main() {
  Future<void> tecla(TypingBloc b, String ch) async {
    b.add(TeclaDigitada(ch));
    await Future<void>.delayed(Duration.zero);
  }

  test('˜ do Mac conta como ~ (e não como erro)', () async {
    final b = TypingBloc()..add(const TrechoCarregado('~x'));
    await Future<void>.delayed(Duration.zero);
    await tecla(b, '˜'); // U+02DC
    expect(b.state.idx, 1);
    expect(b.state.errosSessao, 0);
    await tecla(b, 'x');
    expect(b.state.concluido, isTrue);
    await b.close();
  });

  test('fluxo completo do Mac: ˜ + espaço que solta o acento + resto', () async {
    final b = TypingBloc()..add(const TrechoCarregado('a ~/ 2'));
    await Future<void>.delayed(Duration.zero);
    await tecla(b, 'a');
    await tecla(b, ' ');
    await tecla(b, '˜'); // o til "do Mac"
    await tecla(b, ' '); // espaço que solta a tecla morta: engolido, sem erro
    expect(b.state.errosSessao, 0);
    expect(b.state.chars[b.state.idx], '/');
    await tecla(b, '/');
    await tecla(b, ' ');
    await tecla(b, '2');
    expect(b.state.concluido, isTrue);
    expect(b.state.errosSessao, 0);
    await b.close();
  });

  test('aspas curvas e travessão de autocorreção valem como os retos', () async {
    final b = TypingBloc()..add(const TrechoCarregado("'a-b'"));
    await Future<void>.delayed(Duration.zero);
    await tecla(b, '’'); // aspa curva
    await tecla(b, 'a');
    await tecla(b, '–'); // en-dash
    await tecla(b, 'b');
    await tecla(b, '‘');
    expect(b.state.concluido, isTrue);
    expect(b.state.errosSessao, 0);
    await b.close();
  });

  test('tecla realmente errada continua contando erro', () async {
    final b = TypingBloc()..add(const TrechoCarregado('~'));
    await Future<void>.delayed(Duration.zero);
    await tecla(b, 'x');
    expect(b.state.errosSessao, 1);
    expect(b.state.idx, 0);
    await b.close();
  });
}
