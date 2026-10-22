// 📖 ProgressoHistoria: o que já foi visto da história do English Turismo e as prefs do player.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/progresso_historia.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('chaves com prefixo en_ (só o inglês) e ids i/f/c por pista', () {
    for (final c in const [
      ProgressoHistoria.chaveVistos,
      ProgressoHistoria.chaveTraducao,
      ProgressoHistoria.chaveVoz,
      ProgressoHistoria.chaveAuto,
      ProgressoHistoria.chaveLenta,
      ProgressoHistoria.chavePerdidos,
    ]) {
      expect(c, startsWith('en_turismo_historia_'));
    }
    expect(ProgressoHistoria.id(7, ParteDoCapitulo.intro), 'i7');
    expect(ProgressoHistoria.id(7, ParteDoCapitulo.fim), 'f7');
    expect(ProgressoHistoria.id(30, ParteDoCapitulo.fim), 'f30');
    expect(ProgressoHistoria.idAssistido(30), 'c30');
  });

  test('começa sem nada visto e com as prefs no padrão', () async {
    expect(await ProgressoHistoria.vistos(), isEmpty);
    expect(await ProgressoHistoria.traducao(), isTrue);
    expect(await ProgressoHistoria.voz(), isTrue);
    expect(await ProgressoHistoria.auto(), isTrue);
    expect(await ProgressoHistoria.lenta(), isFalse, reason: 'a 🐢 da história começa desligada');
    expect(await ProgressoHistoria.perdidosAvisado(), isFalse);
  });

  test('marcarVisto: abertura e chegada; só a chegada ASSISTIDA ganha o c', () async {
    await ProgressoHistoria.marcarVisto(1, ParteDoCapitulo.intro);
    expect(await ProgressoHistoria.vistos(), {'i1'});
    await ProgressoHistoria.marcarVisto(1, ParteDoCapitulo.intro, assistido: true);
    expect(await ProgressoHistoria.vistos(), {'i1'}, reason: 'abertura assistida não vira c1');
    await ProgressoHistoria.marcarVisto(1, ParteDoCapitulo.fim);
    expect(await ProgressoHistoria.vistos(), {'i1', 'f1'}, reason: 'pular a chegada não conta como assistida');
    await ProgressoHistoria.marcarVisto(30, ParteDoCapitulo.fim, assistido: true);
    expect(await ProgressoHistoria.vistos(), {'i1', 'f1', 'f30', 'c30'});
  });

  test('marcarVisto não duplica e preserva o que já estava gravado', () async {
    SharedPreferences.setMockInitialValues({
      ProgressoHistoria.chaveVistos: ['i3', 'f3'],
    });
    await ProgressoHistoria.marcarVisto(3, ParteDoCapitulo.fim);
    await ProgressoHistoria.marcarVisto(3, ParteDoCapitulo.fim);
    await ProgressoHistoria.marcarVisto(4, ParteDoCapitulo.intro);
    final p = await SharedPreferences.getInstance();
    expect(p.getStringList(ProgressoHistoria.chaveVistos), ['i3', 'f3', 'i4']);
    await ProgressoHistoria.marcarVisto(3, ParteDoCapitulo.fim, assistido: true);
    expect(p.getStringList(ProgressoHistoria.chaveVistos), ['i3', 'f3', 'i4', 'c3']);
  });

  test('cada pref grava e lê de volta, na sua chave', () async {
    await ProgressoHistoria.salvarTraducao(false);
    await ProgressoHistoria.salvarVoz(false);
    await ProgressoHistoria.salvarAuto(false);
    await ProgressoHistoria.salvarLenta(true);
    await ProgressoHistoria.marcarPerdidosAvisado();
    expect(await ProgressoHistoria.traducao(), isFalse);
    expect(await ProgressoHistoria.voz(), isFalse);
    expect(await ProgressoHistoria.auto(), isFalse);
    expect(await ProgressoHistoria.lenta(), isTrue);
    expect(await ProgressoHistoria.perdidosAvisado(), isTrue);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(ProgressoHistoria.chaveTraducao), isFalse);
    expect(p.getBool(ProgressoHistoria.chaveVoz), isFalse);
    expect(p.getBool(ProgressoHistoria.chaveAuto), isFalse);
    expect(p.getBool(ProgressoHistoria.chaveLenta), isTrue);
    expect(p.getBool(ProgressoHistoria.chavePerdidos), isTrue);
    await ProgressoHistoria.salvarTraducao(true);
    await ProgressoHistoria.salvarAuto(true);
    expect(await ProgressoHistoria.traducao(), isTrue);
    expect(await ProgressoHistoria.auto(), isTrue);
  });

  test('as prefs da história não mexem nas do curso nem nas do Turismo', () async {
    SharedPreferences.setMockInitialValues({'turismo_pista_max': 4, 'en_lenta': true});
    await ProgressoHistoria.salvarLenta(true);
    await ProgressoHistoria.marcarVisto(2, ParteDoCapitulo.intro);
    final p = await SharedPreferences.getInstance();
    expect(p.getInt('turismo_pista_max'), 4);
    expect(p.getBool('en_lenta'), isTrue);
    expect(p.getKeys(), containsAll(['turismo_pista_max', 'en_lenta', ProgressoHistoria.chaveLenta, ProgressoHistoria.chaveVistos]));
    expect(p.getKeys(), hasLength(4));
  });
}
