import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/tutor/domain/texto_falavel.dart';

/// A narração do Prof. Dash não pode ler markdown nem soletrar código.
void main() {
  test('bloco de código vira convite pra olhar o chat', () {
    final falado = textoFalavel(
        'O map transforma:\n```dart\nvar d = [1].map((n) => n * 2);\n```\nViu?');
    expect(falado, contains('exemplo de código aqui no chat'));
    expect(falado, isNot(contains('=>')));
    expect(falado, isNot(contains('```')));
  });

  test('marcação inline e emoji somem da fala', () {
    expect(textoFalavel('O `where` é **top** 🐦✨!'), 'O where é top !');
  });

  test('espaços se acomodam', () {
    expect(textoFalavel('a\n\n  b'), 'a b');
  });
}
