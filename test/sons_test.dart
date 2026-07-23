import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/som/sons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fora da web o som é um no-op silencioso — mas o liga/desliga persiste
/// e `toca` jamais pode lançar (som é tempero, não dependência).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('toca é inofensivo na VM, para todos os efeitos', () {
    Sons.ligado = true;
    for (final s in Som.values) {
      expect(() => Sons.toca(s), returnsNormally);
    }
  });

  test('alternar persiste a escolha entre sessões', () async {
    SharedPreferences.setMockInitialValues({});
    await Sons.carregar();
    expect(Sons.ligado, isTrue); // padrão: ligado

    await Sons.alternar();
    expect(Sons.ligado, isFalse);

    Sons.ligado = true; // simula outra sessão carregando do zero
    await Sons.carregar();
    expect(Sons.ligado, isFalse); // veio do storage

    await Sons.alternar();
    expect(Sons.ligado, isTrue);
  });

  test('desligado, toca não faz nada (nem lança)', () {
    Sons.ligado = false;
    expect(() => Sons.toca(Som.fanfarra), returnsNormally);
    Sons.ligado = true;
  });
}
