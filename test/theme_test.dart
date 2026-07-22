import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/core/theme/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => Mixart.atual = Paleta.mixart);

  test('há 3 paletas e o Mixart começa como padrão', () {
    expect(Paleta.todas.length, 3);
    expect(Paleta.todas.map((p) => p.nome), containsAll(['Mixart', 'Flutter claro', 'Flutter escuro']));
    expect(Paleta.flutterClaro.ehClaro, isTrue);
    expect(Paleta.flutterEscuro.ehClaro, isFalse);
  });

  test('trocar aplica em Mixart.atual, emite e persiste', () async {
    SharedPreferences.setMockInitialValues({});
    final c = ThemeCubit();
    await Future<void>.delayed(Duration.zero);
    expect(Mixart.atual, Paleta.mixart);

    await c.trocar(Paleta.flutterClaro);
    expect(c.state, Paleta.flutterClaro);
    expect(Mixart.atual, Paleta.flutterClaro);
    expect(Mixart.bg, Paleta.flutterClaro.bg); // getters seguem a paleta

    final p = await SharedPreferences.getInstance();
    expect(p.getString('paleta'), 'Flutter claro');
    await c.close();
  });

  test('carrega a paleta salva ao iniciar', () async {
    SharedPreferences.setMockInitialValues({'paleta': 'Flutter escuro'});
    final c = ThemeCubit();
    await Future<void>.delayed(Duration.zero);
    expect(c.state, Paleta.flutterEscuro);
    expect(Mixart.atual, Paleta.flutterEscuro);
    await c.close();
  });
}
