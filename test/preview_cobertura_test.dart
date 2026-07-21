import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/preview/preview_engine.dart';

void main() {
  test('PreviewEngine não quebra em nenhum exercício do currículo', () {
    final raw = File('assets/curriculo.json').readAsStringSync();
    final trilhas = (jsonDecode(raw) as List)
        .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
        .toList();

    var total = 0, vivo = 0, demo = 0, conceito = 0;
    for (final t in trilhas.where((t) => t.nivel == 'Flutter')) {
      for (final l in t.licoes) {
        for (final tr in l.trechos) {
          total++;
          final r = PreviewEngine.gerar(tr.cod, tr.dicaPlana); // não pode lançar
          switch (r.modo) {
            case PreviewModo.vivo:
              vivo++;
            case PreviewModo.demo:
              demo++;
            case PreviewModo.conceito:
              conceito++;
          }
        }
      }
    }
    // ignore: avoid_print
    print('Prévia Flutter: $vivo ao vivo · $demo demos · $conceito conceitos '
        '(${((vivo + demo) * 100 / total).round()}% com Flutter real)');
    expect(total, greaterThan(200));
    expect(vivo + demo, greaterThan(total * 3 ~/ 4)); // grande maioria roda de verdade
  });
}
