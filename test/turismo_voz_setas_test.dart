// 🔊 Turismo no inglês, modo SETAS: ninguém digita (nada "trava"), então a palavra do portal é falada
// quando ele vira o alvo à frente do carro — o 1º na largada, cada seguinte ao cruzar o anterior —, uma
// vez só por portal. O chip "🔊 Voz" aparece no HUD (a mesma chave e a mesma pref da digitação); a pausa
// e a saída calam; o Dart nas setas segue mudo e sem chip.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/presentation/turismo_page.dart';
import 'package:pac_dart/features/arcade/presentation/voz_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Fala implements FalanteDoJogo {
  final ditas = <String>[];
  int paradas = 0;
  @override
  bool get liberado => true;
  @override
  void falar(String palavra) => ditas.add(palavra);
  @override
  void parar() => paradas++;
}

Widget _app(Widget home) => MaterialApp(theme: Mixart.tema(), home: home);

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

/// A palavra do portal no cartão das setas ('word (tradução)  ·  portal em 80 m  ·  a seguir: ⬅'); null
/// na reta final.
String? _palavraNoCartao(WidgetTester tester) {
  final t = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('·  portal em '));
  if (t.evaluate().isEmpty) return null;
  final linha = tester.widget<Text>(t).data!.split('  ·  ').first;
  final i = linha.indexOf(' (');
  return i < 0 ? linha : linha.substring(0, i);
}

/// Segura ↑ até o cartão mostrar outra palavra (o carro cruzou o portal); devolve a nova.
Future<String?> _acelerarAteOutroPortal(WidgetTester tester, String antes) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
  String? agora = antes;
  for (var i = 0; i < 300 && agora == antes; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    agora = _palavraNoCartao(tester);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
  await tester.pump();
  return agora;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  late _Fala fala;

  setUp(() {
    SharedPreferences.setMockInitialValues({'turismo_modo': true, 'turismo_tutorial_setas': true});
    VozDoJogo.ligada = true;
    fala = _Fala();
    VozDoJogo.falanteDeTeste = () => fala;
  });
  tearDown(() {
    VozDoJogo.falanteDeTeste = null;
    VozDoJogo.ligada = true;
    Linguagem.atual = Linguagem.dart;
  });

  void telaGrande(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> abrirCorrida(WidgetTester tester) async {
    await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20)); // prefs (modo setas) carregadas
  }

  testWidgets('inglês nas setas: chip no HUD; o portal é falado ao virar o alvo, uma vez só', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await abrirCorrida(tester);
    expect(find.textContaining('segure ↑ pra acelerar'), findsOneWidget, reason: 'é o modo setas');
    await tester.pump(const Duration(milliseconds: 900));
    expect(fala.ditas, isEmpty, reason: 'na contagem, nada');
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byType(TextField), findsNothing);
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget, reason: 'o chip 🔊 no HUD das setas');
    final p1 = _palavraNoCartao(tester);
    expect(p1, isNotNull);
    expect(fala.ditas, [p1], reason: 'largou: a palavra do 1º portal (a do cartão), sem a tradução');

    // parado, os ticks não repetem
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(fala.ditas, [p1]);

    // cruzou o 1º: o 2º vira o alvo e é falado na hora (com o portal ainda lá na frente)
    final p2 = await _acelerarAteOutroPortal(tester, p1!);
    expect(p2, isNotNull);
    expect(p2, isNot(p1));
    expect(fala.ditas, [p1, p2]);
    final texto = tester
        .widget<Text>(find.byWidgetPredicate((w) => w is Text && (w.data ?? '').contains('·  portal em ')))
        .data!;
    final metros = int.parse(RegExp(r'portal em (\d+) m').firstMatch(texto)!.group(1)!);
    expect(metros, greaterThan(20), reason: 'falado com tempo de ouvir antes de chegar');
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(fala.ditas, [p1, p2], reason: 'o mesmo portal nunca de novo');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês nas setas: a pausa cala e não repete ao voltar; sair cala', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await abrirCorrida(tester);
    await _largada(tester);
    final p1 = _palavraNoCartao(tester);
    expect(fala.ditas, [p1]);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.byType(PausaOverlay), findsOneWidget);
    expect(fala.paradas, 1, reason: 'pausou: a voz para');
    await tester.pump(const Duration(milliseconds: 300));
    expect(fala.ditas, [p1], reason: 'na pausa, nada');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(fala.ditas, [p1], reason: 'o mesmo portal não é falado de novo');

    // o 2º portal falado; sair pela pausa volta ao campeonato sem falar mais nada
    final p2 = await _acelerarAteOutroPortal(tester, p1!);
    expect(fala.ditas, [p1, p2]);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(fala.paradas, 2);
    await tester.tap(find.text('Sair do jogo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('COMO DIRIGIR'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
    expect(fala.ditas, [p1, p2]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês nas setas: fechar a página no meio da fala cala a voz', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await abrirCorrida(tester);
    await _largada(tester);
    expect(fala.ditas, hasLength(1));
    expect(fala.paradas, 0);
    await tester.pumpWidget(Container());
    expect(fala.paradas, 1);
  });

  testWidgets('inglês nas setas: chip desligado = mudo; religado no meio, o portal da vez fala', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    // a página relê a pref ao abrir: desligada lá
    SharedPreferences.setMockInitialValues(
        {'turismo_modo': true, 'turismo_tutorial_setas': true, VozDoJogo.prefFalar: false});
    await abrirCorrida(tester);
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('🔇 Voz'), findsOneWidget);
    expect(fala.ditas, isEmpty);

    await tester.tap(find.byKey(const Key('arcade-voz')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(VozDoJogo.ligada, isTrue);
    expect(find.text('🔊 Voz'), findsOneWidget);
    final p1 = _palavraNoCartao(tester);
    expect(fala.ditas, [p1], reason: 'religou: o portal da vez ainda é falado');
    await tester.pump(const Duration(milliseconds: 200));
    expect(fala.ditas, [p1]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('celular 360: o chip cabe no HUD das setas', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await abrirCorrida(tester);
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('Dart nas setas: sem chip e sem voz', (tester) async {
    expect(Linguagem.atual, Linguagem.dart);
    telaGrande(tester);
    await abrirCorrida(tester);
    await _largada(tester);
    final p1 = _palavraNoCartao(tester);
    expect(find.byKey(const Key('arcade-voz')), findsNothing);
    await _acelerarAteOutroPortal(tester, p1!);
    expect(fala.ditas, isEmpty);
    expect(fala.paradas, 0, reason: 'nem mexe na voz');
    await tester.pumpWidget(Container());
  });
}
