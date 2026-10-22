import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/perspectiva.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/velocimetro.dart';

/// Guarda de desempenho (22/out): o velocímetro fica por cima da vista 3D do
/// Turismo e repinta a cada km/h. Antes cada repintura refazia o layout de 2
/// textos ("km/h" e o número); agora o `pintarTexto` reaproveita o que já mediu.
/// O cache só vale no curso de inglês (no Dart e no C# o Arcade fica como estava).
void main() {
  setUp(() => Linguagem.atual = Linguagem.ingles);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('velocímetro: repintar com km/h já vistos não refaz layout de texto', (tester) async {
    Future<void> mostra(double fracao, int kmh) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RepaintBoundary(child: Velocimetro(fracao: fracao, kmh: kmh))),
      ));
    }

    final antes = debugLayoutsPintarTexto;
    await mostra(.50, 187); // "187" e "km/h"
    await mostra(.51, 188); // só o "188" é novo
    await mostra(.50, 187);
    await mostra(.51, 188);
    await mostra(.50, 187);
    // sem o cache seriam 2 layouts por repintura (10 aqui)
    expect(debugLayoutsPintarTexto - antes, lessThanOrEqualTo(3));
  });

  testWidgets('pintarTexto: o cache é limitado e não troca um texto por outro', (tester) async {
    // muitos textos diferentes (a pista 2D desenha placas de tamanhos contínuos)
    for (var i = 0; i < 200; i++) {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Velocimetro(fracao: i / 200, kmh: 1000 + i)),
      ));
    }
    expect(tester.takeException(), isNull);
    // um número que já saiu do cache volta a ser medido (e desenhado) normalmente
    final antes = debugLayoutsPintarTexto;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: Velocimetro(fracao: .3, kmh: 1000)),
    ));
    expect(debugLayoutsPintarTexto - antes, 1);
  });

  testWidgets('fora do inglês (Dart/C#) não há cache: cada repintura mede de novo, como antes', (tester) async {
    Linguagem.atual = Linguagem.dart;
    Future<void> mostra(double fracao, int kmh) => tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: RepaintBoundary(child: Velocimetro(fracao: fracao, kmh: kmh))),
        ));
    await mostra(.50, 187);
    final antes = debugLayoutsPintarTexto;
    await mostra(.51, 188);
    await mostra(.50, 187);
    expect(debugLayoutsPintarTexto - antes, 4);
  });
}
