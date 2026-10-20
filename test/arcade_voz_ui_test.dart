// 🔊 Arcade no inglês, na tela: o jogo FALA a palavra que a pessoa vai digitar — o Rali a cada palavra
// da vez (a 1ª só depois do 3-2-1; no modo memória só DEPOIS de digitada), o Turismo quando ela trava
// num portal (e na de combustível), a Chuva quando trava a mira. O chip "🔊 Voz" desliga; o Dart nunca fala.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/tiro_engine.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/banco_arcade.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
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

/// Digita [palavra] letra a letra no campo invisível (continuando [antes]).
Future<String> _digitar(WidgetTester tester, String palavra, {String antes = ''}) async {
  var texto = antes;
  for (final ch in palavra.split('')) {
    texto += ch;
    await tester.enterText(find.byType(TextField), texto);
    await tester.pump();
  }
  return texto;
}

Finder _rich(String texto) => find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == texto);

/// O vocabulário de reserva do inglês (arcade solto, sem o curso).
VocabularioJogo get _reserva => VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  late _Fala fala;

  setUp(() {
    SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true});
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

  testWidgets('Rali no inglês: a 1ª palavra só depois do 3-2-1; cada nova da vez é falada', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget, reason: 'o chip na tela de início');
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    expect(fala.ditas, isEmpty, reason: 'na contagem, nada');
    await _largada(tester);

    final fila = BancoArcade.baralhoDoVocabulario(_reserva, Random(3));
    expect(fala.ditas, [fila[0]]);
    expect(_rich(fila[0]), findsOneWidget, reason: 'a falada é a da vez');

    await _digitar(tester, fila[0]);
    expect(find.text('PALAVRA 2'), findsOneWidget);
    expect(fala.ditas, [fila[0], fila[1]]);
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget, reason: 'o chip segue na corrida');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('Rali modo memória: nada antes de digitar (entregaria a resposta); a lembrada é falada depois',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rali-memoria')));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    expect(find.text('PALAVRA 1 · 🧠 DE MEMÓRIA'), findsOneWidget);
    expect(fala.ditas, isEmpty);

    final v = _reserva;
    final fila = [for (final w in BancoArcade.baralhoDoVocabulario(v, Random(3))) if (v.traducao(w) != null) w];
    final texto = await _digitar(tester, fila[0].substring(0, fila[0].length - 1));
    expect(fala.ditas, isEmpty, reason: 'pela metade, ainda não');
    await _digitar(tester, fila[0].substring(fila[0].length - 1), antes: texto);
    expect(find.text('PALAVRA 2 · 🧠 DE MEMÓRIA'), findsOneWidget);
    expect(fala.ditas, [fila[0]], reason: 'só a recém-lembrada, nunca a próxima');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('Rali: o chip "🔊 Voz" desliga (salvo) e a partida fica muda', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    expect(find.bySemanticsLabel('voz das palavras ligada'), findsOneWidget);
    await tester.tap(find.byKey(const Key('arcade-voz')));
    await tester.pump();
    expect(VozDoJogo.ligada, isFalse);
    expect(find.bySemanticsLabel('voz das palavras desligada'), findsOneWidget);
    expect(find.text('🔇 Voz'), findsOneWidget);
    final p = await tester.runAsync(SharedPreferences.getInstance);
    expect(p!.getBool(VozDoJogo.prefFalar), isFalse);

    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    final fila = BancoArcade.baralhoDoVocabulario(_reserva, Random(3));
    await _digitar(tester, fila[0]);
    expect(find.text('PALAVRA 2'), findsOneWidget);
    expect(fala.ditas, isEmpty);

    // religou no meio da corrida: a próxima palavra volta a ser falada
    await tester.tap(find.byKey(const Key('arcade-voz')));
    await tester.pump();
    await _digitar(tester, fila[1], antes: fila[0]);
    expect(fala.ditas, [fila[2]]);
    semantica.dispose();
    await tester.pumpWidget(Container());
  });

  testWidgets('Rali: na pausa, nada é falado e a fala em curso é cortada', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    expect(fala.ditas, hasLength(1));
    await tester.tap(find.byType(BotaoPausa));
    await tester.pump();
    expect(find.byType(PausaOverlay), findsOneWidget);
    expect(fala.paradas, 1, reason: 'pausou: a voz para');
    final fila = BancoArcade.baralhoDoVocabulario(_reserva, Random(3));
    // retomou sem ter começado a palavra: a que a pausa cortou volta (mesmo dentro de 1,5 s)
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(fala.ditas, [fila[0], fila[0]]);
    // começada, a pausa não repete ao voltar
    await _digitar(tester, fila[0].substring(0, 1));
    await tester.tap(find.byType(BotaoPausa));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(fala.ditas, hasLength(2));
    await tester.pumpWidget(Container());
  });

  testWidgets('Rali: aba escondida quando o 3-2-1 acaba — a 1ª palavra é falada ao retomar', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    await _largada(tester);
    expect(find.byType(PausaOverlay), findsOneWidget);
    expect(fala.ditas, isEmpty, reason: 'escondida: nada');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    final fila = BancoArcade.baralhoDoVocabulario(_reserva, Random(3));
    expect(fala.ditas, [fila[0]]);
    await tester.pumpWidget(Container());
  });

  testWidgets('Rali modo memória: retomar a pausa não entrega a palavra', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rali-memoria')));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    await tester.tap(find.byType(BotaoPausa));
    await tester.pump();
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(fala.ditas, isEmpty);
    await tester.pumpWidget(Container());
  });

  testWidgets('o chip tem a ação de toque no leitor de tela', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    final semantica = tester.ensureSemantics();
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    final no = tester.getSemantics(find.byKey(const Key('arcade-voz')));
    expect(no.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(no.label, 'voz das palavras ligada');
    tester.semantics.tap(find.semantics.byLabel('voz das palavras ligada'));
    await tester.pump();
    expect(VozDoJogo.ligada, isFalse, reason: 'o toque do leitor de tela desliga');
    semantica.dispose();
    await tester.pumpWidget(Container());
  });

  testWidgets('Turismo no inglês: fala ao TRAVAR no portal (não quando ele aparece) e na de combustível (idem)',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 40));
    }
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget, reason: 'o chip no HUD da corrida');
    expect(fala.ditas, isEmpty, reason: 'o portal à vista não é falado');

    final p = pistasGt[0];
    final v = _reserva;
    final replica = TurismoEngine(pista: p, rnd: Random(3), vocabulario: p.vocabularioCom(v), traducoes: v.traducoes);
    final palavra = replica.portais.first.palavras.first;
    await _digitar(tester, palavra[0]);
    expect(fala.ditas, [palavra], reason: 'travou: a palavra é falada');
    final texto = await _digitar(tester, palavra.substring(1, palavra.length - 1), antes: palavra[0]);
    expect(fala.ditas, [palavra], reason: 'cada letra não repete');
    final completo = await _digitar(tester, palavra.substring(palavra.length - 1), antes: texto);
    // completou: entra a de combustível, mas NÃO é falada ainda (cortaria a do portal, ainda soando)
    for (final ch in palavra.split('')) {
      replica.teclar(ch);
    }
    final gas = replica.palavraGas!;
    expect(_rich(gas), findsOneWidget, reason: 'a de combustível na tela');
    expect(fala.ditas, [palavra]);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pump(const Duration(milliseconds: 40));
    expect(fala.ditas, [palavra], reason: 'aparecer não é falar');
    // a 1ª letra certa trava nela: falada uma vez
    final g1 = await _digitar(tester, gas[0], antes: completo);
    expect(fala.ditas, [palavra, gas]);
    await _digitar(tester, gas[1], antes: g1);
    await tester.pump(const Duration(milliseconds: 40));
    expect(fala.ditas, [palavra, gas], reason: 'cada letra (e o tick) não repete');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('Turismo: chip na tela do campeonato (junto do 🎸) e, desligado, travar não fala', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const TurismoPage(semente: 3)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.textContaining('🎸 Rock'), findsOneWidget);
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget);
    expect(find.text('🔊 Falar palavras ligado'), findsOneWidget, reason: 'por extenso, como os vizinhos');
    await tester.tap(find.byKey(const Key('arcade-voz')));
    await tester.pump();
    expect(VozDoJogo.ligada, isFalse);
    expect(find.text('🔇 Falar palavras desligado'), findsOneWidget);
    await tester.pumpWidget(Container());

    await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    final p = pistasGt[0];
    final v = _reserva;
    final replica = TurismoEngine(pista: p, rnd: Random(3), vocabulario: p.vocabularioCom(v), traducoes: v.traducoes);
    await _digitar(tester, replica.portais.first.palavras.first);
    expect(fala.ditas, isEmpty);
    await tester.pumpWidget(Container());
  });

  testWidgets('Chuva no inglês: fala quando trava a mira (não a cada palavra que cai)', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    telaGrande(tester);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget);
    expect(fala.ditas, isEmpty, reason: 'cair não é falar');

    final replica = TiroEngine(rnd: Random(5), curtas: palavrasCurtasEn, medias: palavrasMediasEn, longas: palavrasLongasEn)
      ..tick(0.06);
    final caindo = replica.ativas.first.texto;
    await _digitar(tester, caindo.substring(0, min(2, caindo.length)));
    expect(fala.ditas, [caindo], reason: 'travou: falada uma vez');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('celular 360: o chip cabe no cabeçalho do Rali, da Chuva e do Turismo', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    expect(tester.takeException(), isNull, reason: 'Rali, tela de início');
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Rali, corrida');
    await tester.pumpWidget(Container());

    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Chuva');
    await tester.pumpWidget(Container());

    await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const Key('arcade-voz')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'Turismo');
    await tester.pumpWidget(Container());
  });

  testWidgets('Dart: nenhum jogo fala e o chip não aparece', (tester) async {
    expect(Linguagem.atual, Linguagem.dart);
    telaGrande(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    expect(find.byKey(const Key('arcade-voz')), findsNothing);
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    expect(find.byKey(const Key('arcade-voz')), findsNothing);
    final fila = baralhoRaliDe(Random(3));
    await _digitar(tester, fila[0]);
    expect(find.text('PALAVRA 2'), findsOneWidget);
    await tester.pumpWidget(Container());

    await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    expect(find.byKey(const Key('arcade-voz')), findsNothing);
    final replica = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
    await _digitar(tester, replica.portais.first.palavras.first);
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(Container());

    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(const Key('arcade-voz')), findsNothing);
    final v = VocabularioJogo.deListas(vocabularioDe());
    final chuva = TiroEngine(rnd: Random(5), curtas: v.curtas, medias: v.medias, longas: v.longas)..tick(0.06);
    await _digitar(tester, chuva.ativas.first.texto.substring(0, 1));
    expect(fala.ditas, isEmpty);
    expect(fala.paradas, 0, reason: 'nem mexe na voz');
    await tester.pumpWidget(Container());
  });
}
