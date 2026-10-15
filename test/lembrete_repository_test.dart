import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/data/lembrete_repository.dart';
import 'package:pac_dart/features/habito/domain/lembrete.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('sem nada gravado: o padrão (desligado, 20:00)', () async {
    expect(await LocalLembreteRepository(uid: 'a').carregar(), ConfigLembrete.padrao);
    expect(await LocalLembreteRepository().carregar(), ConfigLembrete.padrao);
  });

  test('ida e volta', () async {
    final r = LocalLembreteRepository(uid: 'a');
    await r.salvar(const ConfigLembrete(ligado: true, hora: 7, minuto: 30));
    expect(await LocalLembreteRepository(uid: 'a').carregar(), const ConfigLembrete(ligado: true, hora: 7, minuto: 30));
  });

  test('a chave leva o dono: duas contas no mesmo aparelho não se misturam', () async {
    await LocalLembreteRepository(uid: 'a').salvar(const ConfigLembrete(ligado: true, hora: 6, minuto: 0));
    await LocalLembreteRepository(uid: 'b').salvar(const ConfigLembrete(ligado: true, hora: 22, minuto: 15));
    expect((await LocalLembreteRepository(uid: 'a').carregar()).hora, 6);
    expect((await LocalLembreteRepository(uid: 'b').carregar()).hora, 22);
    expect(LocalLembreteRepository(uid: 'a').chave, 'lembrete_v1:a');
    expect(LocalLembreteRepository().chave, 'lembrete_v1');
    expect(await LocalLembreteRepository(uid: 'c').carregar(), ConfigLembrete.padrao);
  });

  test('JSON corrompido ou de outro tipo: volta ao padrão, sem lançar', () async {
    for (final lixo in ['', 'não é json', '[1,2', '42', 'null', '{"hora":"x"}']) {
      SharedPreferences.setMockInitialValues({'lembrete_v1:a': lixo});
      final c = await LocalLembreteRepository(uid: 'a').carregar();
      expect(c.hora, inInclusiveRange(0, 23), reason: lixo);
      expect(c.ligado, isFalse, reason: lixo);
    }
  });

  test('nada vai a outra chave (só lembrete_v1:{uid}) — o lembrete é do aparelho, não da nuvem', () async {
    await LocalLembreteRepository(uid: 'a').salvar(const ConfigLembrete(ligado: true));
    final p = await SharedPreferences.getInstance();
    expect(p.getKeys(), {'lembrete_v1:a'});
  });
}
