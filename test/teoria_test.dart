import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';

void main() {
  test('todas as lições têm teoria em blocos válidos', () {
    final raw = File('assets/curriculo.json').readAsStringSync();
    final trilhas = (jsonDecode(raw) as List)
        .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
        .toList();

    const tiposValidos = {'h', 'p', 'code', 'tip', 'warn'};
    var licoes = 0, comTeoria = 0, blocos = 0;
    for (final t in trilhas) {
      for (final l in t.licoes) {
        licoes++;
        if (!l.temTeoria) continue;
        comTeoria++;
        expect(l.teoria.length, greaterThanOrEqualTo(2), reason: '${t.nivel}/${l.nome}');
        for (final b in l.teoria) {
          blocos++;
          expect(tiposValidos, contains(b.tipo), reason: '${t.nivel}/${l.nome}: tipo ${b.tipo}');
          expect(b.conteudo, isNotEmpty);
        }
        // toda teoria deve ter ao menos um bloco de código de exemplo
        expect(l.teoria.any((b) => b.tipo == 'code'), isTrue, reason: '${t.nivel}/${l.nome} sem exemplo');
      }
    }
    // ignore: avoid_print
    print('Teoria: $comTeoria/$licoes lições, $blocos blocos');
    expect(comTeoria, licoes); // 100% das lições com teoria
  });
}
