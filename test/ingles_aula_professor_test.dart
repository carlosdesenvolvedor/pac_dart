// 🎓 Aula do professor: o formato (tolerante, com partes, figuras e desafios), a lousa, o repositório com aulas
// fixas e a tela (toca as falas em ordem, pausa, avança, lousa, figura e legenda, as partes, o "sua vez" do
// desafio, continuar de onde parou, "Ler a aula", sair).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/aulas_repo.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/aula_professor.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/presentation/aula_professor_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _VozFake extends VozIngles {
  final falas = <(String, bool)>[];
  final trilhas = <String>{};
  @override
  Future<FimDaFala> falarNaAula(String texto, {required bool ingles, double fator = 1, String trilha = ''}) async {
    falas.add((texto, ingles));
    trilhas.add(trilha);
    return FimDaFala.acabou;
  }

  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

const _aula = AulaLicao(titulo: 'O tudo bem? dos americanos', falas: [
  FalaAula(pt: 'Hoje é a sua primeira chamada com o time.'),
  FalaAula(pt: 'Repare na lousa.', quadro: 'Good morning = Bom dia'),
  FalaAula(en: 'Good morning, Mike!', tr: 'Bom dia, Mike!'),
  FalaAula(pt: 'Agora é com você.'),
]);
const _longa = AulaLicao(titulo: 'Aula longa', falas: [
  FalaAula(pt: 'Abrindo a aula na cena.', secao: 'A cena', img: '💻👋'),
  FalaAula(pt: 'Continua a cena.'),
  FalaAula(pt: 'A regra na lousa.', secao: 'A regra', quadro: "I'm = I am"),
  FalaAula(en: "I'm good, thanks.", tr: 'Tudo bem, obrigado.', img: '😊👍'),
  FalaAula(pt: 'Como você responderia?', secao: 'Desafio', pausa: 2),
  FalaAula(en: "I'm good, thanks.", tr: 'Tudo bem, obrigado.'),
  FalaAula(pt: 'Agora é com você.'),
]);
const _licao = Licao(nome: 'Oi, tudo bem?', emoji: '👋', id: 'primeiro-contato.oi-tudo-bem', trechos: []);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    AulasRepo.fixas = null;
    AulasRepo.limpar();
  });

  group('formato', () {
    test('fala estragada some; aula sem falas some; trilha da lição', () {
      final t = AulasDaTrilha.fromJson({
        'versao': 1,
        'trilha': 'x',
        'licoes': {
          'x.a': {
            'titulo': 'A',
            'falas': [
              {'pt': 'oi'},
              {'pt': 'e', 'en': 'and'},
              {'en': 'Hi!', 'tr': 'Oi!'},
              42,
            ],
          },
          'x.b': {'titulo': 'B', 'falas': []},
        },
      });
      expect(t.licoes.keys, ['x.a']);
      expect(t.licoes['x.a']!.falas.map((f) => f.texto), ['oi', 'Hi!']);
      expect(trilhaDaLicao('primeiro-contato.oi-tudo-bem'), 'primeiro-contato');
    });

    test('a lousa guarda o último quadro/exemplo', () {
      expect(lousaAte(_aula.falas, 0), isNull);
      expect(lousaAte(_aula.falas, 1)!.quadro, 'Good morning = Bom dia');
      expect(lousaAte(_aula.falas, 2)!.en, 'Good morning, Mike!');
      expect(lousaAte(_aula.falas, 3)!.en, 'Good morning, Mike!');
    });

    test('o exemplo da pasta de ferramentas lê inteiro', () {
      final j = jsonDecode(File('tools/ingles/aulas/exemplo_aula.json').readAsStringSync());
      final t = AulasDaTrilha.fromJson(j);
      expect(t.licoes['primeiro-contato.oi-tudo-bem']!.falas.length, greaterThanOrEqualTo(7));
    });

    test('partes, figuras e desafios: lê, agrupa e calcula o tempo', () {
      final f = FalaAula.fromJson({'pt': 'Pense.', 'secao': 'Desafio', 'img': '🤔', 'pausa': 4})!;
      expect((f.secao, f.img, f.pausa), ('Desafio', '🤔', 4));
      expect(FalaAula.fromJson({'pt': 'x', 'pausa': 'muito'})!.pausa, 0);
      expect(_longa.secoes.map((s) => (s.nome, s.inicio)), [('A cena', 0), ('A regra', 2), ('Desafio', 4)]);
      expect([for (var i = 0; i < _longa.falas.length; i++) _longa.secaoDe(i)], [0, 0, 1, 1, 2, 2, 2]);
      // sem partes marcadas: uma parte só, com o título
      expect(_aula.secoes.map((s) => s.nome), ['O tudo bem? dos americanos']);
      expect(_longa.segundosDesde(0), _longa.segundos);
      expect(_longa.segundosDesde(4), lessThan(_longa.segundos));
      expect(_longa.segundosDesde(_longa.falas.length), 0);
      expect(_longa.segundos - _longa.segundosDesde(5), greaterThan(2), reason: 'a pausa do desafio conta');
    });

    test('a figura fica até a lousa escrever outra coisa', () {
      final fs = _longa.falas;
      expect(figuraAte(fs, 0), '💻👋');
      expect(figuraAte(fs, 1), '💻👋');
      expect(figuraAte(fs, 2), '', reason: 'o quadro novo apaga a figura antiga');
      expect(figuraAte(fs, 3), '😊👍', reason: 'a fala que escreve e traz figura mostra as duas');
      expect(figuraAte(fs, 4), '😊👍');
      expect(figuraAte(fs, 5), '');
    });

    test('o professor tem rosto', () => expect(ElencoIngles.de(quemProfessor), ElencoIngles.prof));
  });

  test('AulasRepo com aulas fixas', () async {
    AulasRepo.fixas = {_licao.id: _aula};
    expect(await AulasRepo.daLicao(_licao.id), _aula);
    expect(await AulasRepo.daLicao('outra.licao'), isNull);
    expect(AulasRepo.temAulaNaTrilha('primeiro-contato'), isTrue);
  });

  Future<_VozFake> abrir(WidgetTester tester,
      {bool tocar = true, Size tamanho = const Size(390, 844), AulaLicao aula = _aula}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _VozFake();
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: AulaProfessorPage(licao: _licao, aula: aula, voz: voz, tocarAoAbrir: tocar, primeiraVez: true),
    ));
    await tester.pump();
    return voz;
  }

  // o AnimatedSwitcher mantém a legenda anterior saindo: a atual é a última
  String legenda(WidgetTester t) => t.widget<Text>(find.byKey(const Key('aula-legenda')).last).data!;

  testWidgets('toca as falas em ordem (português e inglês), a lousa acompanha e no fim "Começar a lição"', (tester) async {
    final voz = await abrir(tester);
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(voz.falas, [
      ('Hoje é a sua primeira chamada com o time.', false),
      ('Repare na lousa.', false),
      ('Good morning, Mike!', true),
      ('Agora é com você.', false),
    ]);
    expect(legenda(tester), 'Agora é com você.');
    expect(find.byKey(const Key('aula-lousa-en')), findsOneWidget);
    expect(find.text('Bom dia, Mike!'), findsWidgets);
    expect(find.text('Começar a lição →'), findsOneWidget);
    expect(find.byKey(const Key('aula-auto')), findsOneWidget);
    expect(voz.trilhas, {'primeiro-contato'}, reason: 'a voz procura as falas na trilha da lição');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem tocar ao abrir: ▶ começa, → avança parado, "Ler a aula" mostra o texto, Esc sai', (tester) async {
    final voz = await abrir(tester, tocar: false, tamanho: const Size(1280, 900));
    expect(voz.falas, isEmpty);
    expect(find.text('Toque em ▶ para o professor começar a aula'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(legenda(tester), 'Repare na lousa.');
    expect(find.byKey(const Key('aula-lousa-quadro')), findsOneWidget);
    expect(voz.falas, isEmpty, reason: 'parado, avançar não fala');
    await tester.tap(find.byKey(const Key('aula-ler')));
    await tester.pump();
    expect(find.byKey(const Key('aula-texto')), findsOneWidget);
    await tester.tap(find.byKey(const Key('aula-tocar')));
    await tester.pump(const Duration(milliseconds: 50));
    expect(voz.falas.first.$1, 'Repare na lousa.');
    await tester.tap(find.byKey(const Key('aula-tocar'))); // pausa
    await tester.pump(const Duration(seconds: 2));
    final faladas = voz.falas.length;
    await tester.pump(const Duration(seconds: 2));
    expect(voz.falas.length, faladas, reason: 'pausado não segue');
  });

  testWidgets('desligar "abrir sozinha" grava a preferência', (tester) async {
    await abrir(tester, tocar: false);
    await tester.pump();
    // a lista monta só o que está perto da tela: rola até o rodapé
    await tester.scrollUntilVisible(find.byKey(const Key('aula-auto')), 200);
    await tester.pump();
    await tester.tap(find.byKey(const Key('aula-auto')));
    await tester.pump();
    expect(await PrefsAula.autoLigada(), isFalse);
  });

  testWidgets('aula longa: partes, figura na lousa, o "sua vez" do desafio e o tempo', (tester) async {
    final voz = await abrir(tester, aula: _longa, tamanho: const Size(1280, 900));
    expect(find.byKey(const Key('aula-figura')), findsWidgets);
    expect(find.text('Parte 1 de 3 · A cena'), findsOneWidget);
    expect(find.byKey(const Key('aula-parte-2')), findsOneWidget);
    expect(find.textContaining('≈ 1 min'), findsOneWidget);
    var viuPensando = false;
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(const Key('aula-pensando')).evaluate().isNotEmpty) {
        viuPensando = true;
        expect(legenda(tester), 'Como você responderia?');
        expect(voz.falas.length, 5, reason: 'no silêncio do desafio, ele não fala');
      }
    }
    expect(viuPensando, isTrue);
    expect(voz.falas.length, _longa.falas.length);
    expect(find.text('Começar a lição →'), findsOneWidget);
    expect(await PrefsAula.posicao(_licao.id), 0, reason: 'terminou: a próxima vez começa do começo');
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar numa parte pula para ela', (tester) async {
    await abrir(tester, aula: _longa, tocar: false, tamanho: const Size(1280, 900));
    await tester.tap(find.byKey(const Key('aula-parte-1')));
    await tester.pump();
    expect(legenda(tester), 'A regra na lousa.');
    expect(find.text('Parte 2 de 3 · A regra'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400)); // a figura anterior termina de sair
    expect(find.byKey(const Key('aula-lousa-quadro')), findsOneWidget);
    expect(find.byKey(const Key('aula-figura')), findsNothing);
  });

  testWidgets('continua de onde parou; "Do começo" volta e esquece', (tester) async {
    SharedPreferences.setMockInitialValues({PrefsAula.chavePosicoes: '{"${_licao.id}": 3}'});
    await abrir(tester, aula: _longa, tocar: false, tamanho: const Size(1280, 900));
    await tester.pump();
    expect(legenda(tester), "I'm good, thanks.");
    expect(find.text('Continuando de onde você parou'), findsOneWidget);
    await tester.tap(find.byKey(const Key('aula-do-comeco')));
    await tester.pump();
    expect(legenda(tester), 'Abrindo a aula na cena.');
    expect(find.byKey(const Key('aula-do-comeco')), findsNothing);
    expect(await PrefsAula.posicao(_licao.id), 0);
  });

  testWidgets('sair no meio guarda onde parou', (tester) async {
    await abrir(tester, aula: _longa, tocar: false, tamanho: const Size(1280, 900));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(await PrefsAula.posicao(_licao.id), 2);
  });
}
