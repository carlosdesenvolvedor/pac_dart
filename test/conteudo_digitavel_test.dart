import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// TODO caractere de `cod` precisa existir num teclado ABNT/US comum:
/// ASCII imprimível + quebra de linha + acentos do pt-BR. Nada de °, º,
/// →, ≠, emoji… — o jogador fica TRAVADO num caractere que não existe
/// no teclado (aconteceu com `°` no Card de Clima e `º` no Placar).
void main() {
  final digitaveis = <String>{
    for (var c = 0x20; c < 0x7F; c++) String.fromCharCode(c),
    '\n',
    ...'áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ'.split(''),
  };

  test('todos os 2400+ exercícios/projetos/apps são 100% digitáveis', () {
    final curriculo =
        jsonDecode(File('assets/curriculo.json').readAsStringSync()) as List;
    final master = jsonDecode(File('assets/master.json').readAsStringSync()) as List;

    final problemas = <String>[];
    void checa(String cod, String local) {
      for (final ch in cod.split('').toSet()) {
        if (!digitaveis.contains(ch)) {
          problemas.add('U+${ch.codeUnitAt(0).toRadixString(16)} "$ch" em $local');
        }
      }
    }

    var total = 0;
    for (final (t, trilha as Map) in curriculo.indexed) {
      for (final (l, licao as Map) in ((trilha['licoes'] ?? []) as List).indexed) {
        for (final (i, e as Map) in ((licao['trechos'] ?? []) as List).indexed) {
          checa(e['cod'] as String, 'trilha $t lição $l trecho $i');
          total++;
        }
      }
      for (final (i, p as Map) in ((trilha['projetos'] ?? []) as List).indexed) {
        checa(p['cod'] as String, 'trilha $t projeto $i (${p['nome']})');
        total++;
      }
    }
    for (final (i, p as Map) in master.indexed) {
      checa(p['cod'] as String, 'master $i (${p['nome']})');
      total++;
    }

    expect(total, greaterThan(2400));
    expect(problemas, isEmpty,
        reason: 'caracteres impossíveis de digitar:\n${problemas.join('\n')}');
  });
}
