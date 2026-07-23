// Ferramenta (não é teste de CI): gera um programa rodável para CADA trecho
// do currículo e dos projetos, escrevendo em SAIDA, para depois rodar o
// `flutter analyze` lá fora e ver quantos realmente compilam.
//
//   SAIDA=/tmp/lab/lib/gen flutter test test/tools/rodavel_check.dart
//   cd /tmp/lab && flutter analyze
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/util/codigo_executavel.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';

void main() {
  test('gera os programas rodáveis', () {
    final saida = Directory(Platform.environment['SAIDA'] ?? '/tmp/rodavel_gen');
    if (saida.existsSync()) saida.deleteSync(recursive: true);
    saida.createSync(recursive: true);

    final trilhas = (jsonDecode(File('assets/curriculo.json').readAsStringSync()) as List)
        .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
        .toList();
    final master = (jsonDecode(File('assets/master.json').readAsStringSync()) as List)
        .map((e) => Projeto.fromJson(e as Map<String, dynamic>))
        .toList();

    final indice = <String, String>{}; // arquivo → "trilha / lição / trecho"
    var n = 0;

    void escreve(String nome, String codigo, String de) {
      File('${saida.path}/$nome.dart').writeAsStringSync(codigo);
      indice[nome] = de;
      n++;
    }

    for (var t = 0; t < trilhas.length; t++) {
      final tr = trilhas[t];
      for (var l = 0; l < tr.licoes.length; l++) {
        final licao = tr.licoes[l];
        for (var x = 0; x < licao.trechos.length; x++) {
          escreve(
            'tr${t}_l${l}_x$x',
            codigoExecutavel(licao.trechos[x].cod, ehTrilhaFlutter(tr.nivel),
                contexto: licao.trechos.take(x).map((e) => e.cod).toList()),
            '${tr.nivel} / ${licao.nome} / trecho $x',
          );
        }
      }
      for (var p = 0; p < tr.projetos.length; p++) {
        final proj = tr.projetos[p];
        escreve('tr${t}_p$p', codigoExecutavel(proj.cod, proj.flutter),
            '${tr.nivel} / projeto ${proj.nome}');
      }
    }
    for (var m = 0; m < master.length; m++) {
      escreve('master_$m', codigoExecutavel(master[m].cod, master[m].flutter),
          'Master / ${master[m].nome}');
    }

    File('${saida.path}/../indice.json').writeAsStringSync(jsonEncode(indice));
    // ignore: avoid_print
    print('gerados $n programas em ${saida.path}');
  });
}
