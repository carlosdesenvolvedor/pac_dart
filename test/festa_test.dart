// Kit festa: confete de uma vez, botão 3D, baú, chama do combo e cores das etapas — tudo assenta no
// pumpAndSettle (nada de Timer nem animação repetindo).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/core/ui/festa.dart';

Widget _app(Widget filho) => MaterialApp(home: Scaffold(body: Center(child: filho)));

void main() {
  setUp(() {
    Mixart.usarGoogleFonts = false;
    Mixart.atual = Paleta.mixart;
  });
  tearDown(() => Mixart.atual = Paleta.mixart);

  testWidgets('Confete estoura uma vez, assenta e não bloqueia toques', (tester) async {
    var tocou = 0;
    await tester.pumpWidget(_app(SizedBox(
      width: 300,
      height: 300,
      child: Stack(children: [
        Positioned.fill(child: TextButton(onPressed: () => tocou++, child: const Text('fundo'))),
        const Positioned.fill(child: Confete()),
      ]),
    )));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('fundo'));
    expect(tocou, 1, reason: 'o confete deixa o toque passar');
    await tester.pumpAndSettle();
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('Botao3D: onTap dispara, afunda ao apertar, assenta; sem onTap não faz nada', (tester) async {
    var n = 0;
    await tester.pumpWidget(_app(SizedBox(
      width: 280,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Botao3D(key: const Key('b1'), rotulo: '🎯 Treinar agora', onTap: () => n++),
        const SizedBox(height: 8),
        const Botao3D(key: Key('b2'), rotulo: 'Desligado'),
        // só o conteúdo, dentro de uma Row (largura sem limite)
        Row(children: [Botao3D(rotulo: 'Pequeno', expandir: false, onTap: () {})]),
      ]),
    )));
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('b1'))));
    await tester.pumpAndSettle();
    final face = find.descendant(of: find.byKey(const Key('b1')), matching: find.byKey(const ValueKey('botao3d-face')));
    expect(tester.getTopLeft(face).dy, greaterThan(tester.getTopLeft(find.byKey(const Key('b1'))).dy));
    await g.up();
    await tester.pumpAndSettle();
    expect(n, 1);
    await tester.tap(find.byKey(const Key('b2')));
    await tester.pumpAndSettle();
    expect(n, 1);
    expect(find.text('🎯 Treinar agora'), findsOneWidget);
  });

  testWidgets('Botao3D ativa pelo teclado quando focado (Tab), nunca no toque', (tester) async {
    var n = 0;
    final foco = FocusNode();
    addTearDown(foco.dispose);
    await tester.pumpWidget(_app(SizedBox(width: 200, child: Botao3D(rotulo: 'OK', onTap: () => n++, focusNode: foco))));
    await tester.tap(find.text('OK'));
    expect(foco.hasFocus, isFalse);
    foco.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(n, 2);
  });

  testWidgets('ChamaCombo some abaixo de 3, aparece com o número e assenta', (tester) async {
    await tester.pumpWidget(_app(const ChamaCombo(n: 2)));
    expect(find.text('2'), findsNothing);
    await tester.pumpWidget(_app(const ChamaCombo(n: 3)));
    await tester.pumpAndSettle();
    expect(find.text('3'), findsOneWidget);
    await tester.pumpWidget(_app(const ChamaCombo(n: 4)));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('ChamaCombo que nunca acendeu sai da árvore sem exceção', (tester) async {
    for (final n in [0, 1, 2]) {
      await tester.pumpWidget(_app(ChamaCombo(n: n)));
      await tester.pumpWidget(_app(const SizedBox()));
      expect(tester.takeException(), isNull, reason: 'n=$n');
    }
  });

  testWidgets('Botao3D sem expandir fica do tamanho do conteúdo mesmo com largura limitada', (tester) async {
    await tester.pumpWidget(_app(SizedBox(
      width: 320,
      child: Wrap(children: [Botao3D(rotulo: 'OK', expandir: false, onTap: () {})]),
    )));
    expect(tester.getSize(find.byKey(const ValueKey('botao3d-face'))).width, lessThan(160));
    await tester.pumpWidget(_app(SizedBox(width: 320, child: Botao3D(rotulo: 'OK', onTap: () {}))));
    expect(tester.getSize(find.byKey(const ValueKey('botao3d-face'))).width, 320, reason: 'expandir (padrão) ocupa tudo');
    // largura justa (pai força): o rótulo segue centralizado
    await tester.pumpWidget(_app(SizedBox(width: 240, child: Botao3D(rotulo: 'OK', expandir: false, onTap: () {}))));
    final face = tester.getRect(find.byKey(const ValueKey('botao3d-face')));
    expect((tester.getCenter(find.text('OK')).dx - face.center.dx).abs(), lessThan(1));
  });

  testWidgets('BauPainter pinta fechado, pronto, trancado e aberto', (tester) async {
    for (final p in const [
      BauPainter(),
      BauPainter(brilho: 1),
      BauPainter(trancado: true),
      BauPainter(abertura: 1, brilho: 1),
    ]) {
      await tester.pumpWidget(_app(CustomPaint(size: const Size(120, 110), painter: p)));
      expect(tester.takeException(), isNull);
    }
    expect(const BauPainter(abertura: .5).shouldRepaint(const BauPainter()), isTrue);
    expect(const BauPainter().shouldRepaint(const BauPainter()), isFalse);
  });

  test('corDaEtapa por nível; escurecida só na paleta clara; escurecer', () {
    expect(corDaEtapa('A1 · Fundação'), CoresFesta.verde);
    expect(corDaEtapa('A2 · Dia a dia'), CoresFesta.azul);
    expect(corDaEtapa('B1 · Independência'), CoresFesta.ambar);
    expect(corDaEtapa('B2 · Desenvoltura'), CoresFesta.violeta);
    expect(corDaEtapa('C1 · Domínio'), CoresFesta.coral);
    expect(corDaEtapa('DEV · Inglês profissional de dev'), Mixart.brand);
    expect(corDaEtapa('Meus textos'), Mixart.brand);
    Mixart.atual = Paleta.flutterClaro;
    final claro = corDaEtapa('A1 · Fundação');
    expect(claro, isNot(CoresFesta.verde));
    expect(claro.computeLuminance(), lessThan(CoresFesta.verde.computeLuminance()));
    expect(escurecer(CoresFesta.verde, soNoClaro: true), claro);
    Mixart.atual = Paleta.mixart;
    expect(escurecer(CoresFesta.verde, soNoClaro: true), CoresFesta.verde);
    expect(escurecer(CoresFesta.verde).computeLuminance(), lessThan(CoresFesta.verde.computeLuminance()));
  });
}
