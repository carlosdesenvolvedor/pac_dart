import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/brand/logo_pacdart.dart';
import 'package:pac_dart/core/theme/mixart.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  testWidgets('a marca desenha em qualquer tamanho, solta ou em selo', (tester) async {
    for (final tamanho in [16.0, 24.0, 42.0, 96.0, 512.0]) {
      for (final selo in [false, true]) {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            backgroundColor: Mixart.bg,
            body: Center(child: LogoPacDart(tamanho: tamanho, selo: selo)),
          ),
        ));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'tamanho $tamanho selo $selo');
      }
    }
  });

  testWidgets('a marca solta é mais larga que alta (o Pac + os pontos)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: LogoPacDart(tamanho: 100))),
    ));
    await tester.pump();
    final caixa = tester.getSize(find.byType(LogoPacDart));
    expect(caixa.width, 100);
    expect(caixa.height, lessThan(100)); // sem sobra em cima e embaixo
  });

  testWidgets('o selo é quadrado (vira ícone de app)', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: LogoPacDart(tamanho: 120, selo: true))),
    ));
    await tester.pump();
    expect(tester.getSize(find.byType(LogoPacDart)), const Size(120, 120));
  });
}
