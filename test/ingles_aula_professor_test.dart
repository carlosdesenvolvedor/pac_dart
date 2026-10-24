// 🎓 Aula do professor: o formato (tolerante), a lousa, o repositório com aulas fixas e a tela (toca as falas em
// ordem, pausa, avança, lousa e legenda, "Ler a aula", sair).
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
  @override
  Future<FimDaFala> falarNaAula(String texto, {required bool ingles, double fator = 1}) async {
    falas.add((texto, ingles));
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

    test('o professor tem rosto', () => expect(ElencoIngles.de(quemProfessor), ElencoIngles.prof));
  });

  test('AulasRepo com aulas fixas', () async {
    AulasRepo.fixas = {_licao.id: _aula};
    expect(await AulasRepo.daLicao(_licao.id), _aula);
    expect(await AulasRepo.daLicao('outra.licao'), isNull);
    expect(AulasRepo.temAulaNaTrilha('primeiro-contato'), isTrue);
  });

  Future<_VozFake> abrir(WidgetTester tester, {bool tocar = true, Size tamanho = const Size(390, 844)}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _VozFake();
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: AulaProfessorPage(licao: _licao, aula: _aula, voz: voz, tocarAoAbrir: tocar, primeiraVez: true),
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
    await tester.ensureVisible(find.byKey(const Key('aula-auto')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('aula-auto')));
    await tester.pump();
    expect(await PrefsAula.autoLigada(), isFalse);
  });
}
