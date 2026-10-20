// 🔊 A voz dos jogos (VozDoJogo): fala a palavra no inglês, sem repetir a mesma em 1,5 s, muda na pausa,
// no fim, desligada, antes do 1º gesto e no Dart/C#; a chave fica salva.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/presentation/voz_jogo.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fala implements FalanteDoJogo {
  final ditas = <String>[];
  int paradas = 0;
  @override
  bool liberado = true;
  @override
  void falar(String palavra) => ditas.add(palavra);
  @override
  void parar() => paradas++;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Fala fala;
  late DateTime agora;
  VozDoJogo voz({bool ingles = true}) => VozDoJogo(falante: fala, agora: () => agora, ingles: () => ingles);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VozDoJogo.ligada = true;
    fala = _Fala();
    agora = DateTime(2026, 10, 20, 12);
  });
  tearDown(() {
    VozDoJogo.ligada = true;
    Linguagem.atual = Linguagem.dart;
  });

  test('fala a palavra; a mesma em menos de 1,5 s não repete, outra palavra sim', () {
    final v = voz();
    expect(v.falar('apple'), isTrue);
    agora = agora.add(const Duration(milliseconds: 600));
    expect(v.falar('apple'), isFalse, reason: 'repetida dentro da janela');
    expect(v.falar(' bread '), isTrue, reason: 'outra palavra corta a anterior');
    expect(v.falar('apple'), isTrue, reason: 'a última falada foi bread');
    agora = agora.add(const Duration(milliseconds: 1600));
    expect(v.falar('apple'), isTrue, reason: 'passou a janela');
    expect(fala.ditas, ['apple', 'bread', 'apple', 'apple']);
    expect(v.falar('   '), isFalse);
  });

  test('forcar: repete dentro da janela (a palavra que a pausa cortou), mas segue muda se não pode', () {
    final v = voz();
    expect(v.falar('apple'), isTrue);
    agora = agora.add(const Duration(milliseconds: 300));
    expect(v.falar('apple', forcar: true), isTrue);
    expect(v.falar('apple', forcar: true, pausado: true), isFalse);
    expect(fala.ditas, ['apple', 'apple']);
  });

  test('desligada, pausada, no fim de jogo, antes do 1º gesto: muda', () {
    final v = voz();
    VozDoJogo.ligada = false;
    expect(v.ativa, isFalse);
    expect(v.falar('tea'), isFalse);
    VozDoJogo.ligada = true;
    expect(v.falar('tea', pausado: true), isFalse);
    expect(v.falar('tea', acabou: true), isFalse);
    fala.liberado = false;
    expect(v.falar('tea'), isFalse);
    fala.liberado = true;
    expect(v.falar('tea'), isTrue, reason: 'nada do que ficou mudo conta para a janela');
    expect(fala.ditas, ['tea']);
  });

  test('Dart/C#: nunca fala (o padrão segue a linguagem em uso)', () {
    expect(voz(ingles: false).falar('void'), isFalse);
    Linguagem.atual = Linguagem.dart;
    final dart = VozDoJogo(falante: fala);
    expect(dart.ativa, isFalse);
    expect(dart.falar('class'), isFalse);
    Linguagem.atual = Linguagem.csharp;
    expect(VozDoJogo(falante: fala).falar('class'), isFalse);
    Linguagem.atual = Linguagem.ingles;
    expect(VozDoJogo(falante: fala).falar('class'), isTrue);
    expect(fala.ditas, ['class']);
  });

  test('calar só mexe na voz depois de falar; encerrar cala e emudece de vez', () {
    final v = voz();
    v.calar();
    expect(fala.paradas, 0, reason: 'nada falado: não corta a voz de ninguém');
    v.falar('milk');
    v.calar();
    expect(fala.paradas, 1);
    v.falar('cake');
    v.encerrar();
    expect(fala.paradas, 2);
    expect(v.falar('soup'), isFalse);
  });

  test('a chave: alternar desliga (cortando a fala), salva e carrega', () async {
    final v = voz();
    v.falar('rice');
    await v.alternar();
    expect(VozDoJogo.ligada, isFalse);
    expect(fala.paradas, 1);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool(VozDoJogo.prefFalar), isFalse);
    VozDoJogo.ligada = true;
    expect(await VozDoJogo.carregarPreferencia(), isFalse);
    await v.alternar();
    expect(VozDoJogo.ligada, isTrue);
    expect(p.getBool(VozDoJogo.prefFalar), isTrue);
  });

  test('sem nada salvo, a voz nasce ligada', () async {
    VozDoJogo.ligada = false;
    expect(await VozDoJogo.carregarPreferencia(), isTrue);
  });

  test('o falante de teste vale para as vozes criadas sem um', () {
    VozDoJogo.falanteDeTeste = () => fala;
    addTearDown(() => VozDoJogo.falanteDeTeste = null);
    expect(VozDoJogo(ingles: () => true).falar('juice'), isTrue);
    expect(fala.ditas, ['juice']);
  });
}
