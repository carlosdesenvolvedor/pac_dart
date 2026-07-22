import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/preview/preview_engine.dart';

void main() {
  test('projetos das trilhas: contagem, campos e prévia Flutter', () {
    final raw = File('assets/curriculo.json').readAsStringSync();
    final trilhas = (jsonDecode(raw) as List)
        .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
        .toList();

    var totalProj = 0, flutterProj = 0, flutterVivo = 0;
    for (final t in trilhas) {
      for (final p in t.projetos) {
        totalProj++;
        expect(p.nome, isNotEmpty);
        expect(p.cod.trim(), isNotEmpty);
        expect(p.cod, isNot(contains(RegExp(r'[\u{1F000}-\u{1FAFF}]', unicode: true))),
            reason: 'código não pode ter emoji: ${t.nivel}/${p.nome}');
        if (p.flutter) {
          flutterProj++;
          final r = PreviewEngine.gerar(p.cod, p.descricao); // não pode lançar
          if (r.aoVivo) flutterVivo++;
        }
      }
    }
    // ignore: avoid_print
    print('Projetos: $totalProj (Flutter $flutterProj, prévia viva $flutterVivo)');
    expect(totalProj, greaterThanOrEqualTo(18));
  });

  test('Teste Master: 30+ apps Flutter que renderizam', () {
    final master = File('assets/master.json').existsSync()
        ? (jsonDecode(File('assets/master.json').readAsStringSync()) as List)
            .map((e) => Projeto.fromJson(e as Map<String, dynamic>))
            .toList()
        : <Projeto>[];
    if (master.isEmpty) return; // ainda não integrado
    var vivo = 0;
    final nomes = <String>{};
    for (final p in master) {
      expect(p.flutter, isTrue);
      expect(p.cod.trim(), isNotEmpty);
      expect(p.cod, isNot(contains(RegExp(r'[\u{1F000}-\u{1FAFF}]', unicode: true))));
      expect(nomes.add(p.nome), isTrue, reason: 'nome duplicado: ${p.nome}');
      final r = PreviewEngine.gerar(p.cod, p.descricao); // não pode lançar
      if (r.aoVivo) vivo++;
    }
    // ignore: avoid_print
    print('Master: ${master.length} apps, prévia viva $vivo');
    expect(master.length, greaterThanOrEqualTo(30));
    expect(vivo, greaterThanOrEqualTo((master.length * 0.85).floor())); // maioria renderiza
  });
}
