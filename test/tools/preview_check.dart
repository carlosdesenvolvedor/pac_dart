import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/preview/preview_engine.dart';
import 'package:pac_dart/features/preview/interpreter/parser.dart';

/// Validador AVULSO (sem sufixo _test → não roda no `flutter test` normal).
/// Uso: PREVIEW_JSON=/caminho/arquivo.json flutter test test/tools/preview_check.dart
/// Reporta, por app: se renderiza AO VIVO E se a RAIZ (o widget de fora, ex.:
/// Scaffold) parseia inteira. "OK" = raiz parseia. "PARCIAL" = só um widget
/// interno renderizou (a raiz falhou). "NAOVIVO" = virou demo/cartão.
void main() {
  test('render check dos projetos candidatos', () {
    final path = Platform.environment['PREVIEW_JSON'];
    if (path == null || !File(path).existsSync()) {
      // ignore: avoid_print
      print('!! defina PREVIEW_JSON com um arquivo válido');
      return;
    }
    final lista = (jsonDecode(File(path).readAsStringSync()) as List)
        .map((e) => Projeto.fromJson(e as Map<String, dynamic>))
        .toList();
    var full = 0, parcial = 0, naovivo = 0;
    final problemas = <String>[];
    for (final p in lista) {
      final r = PreviewEngine.gerar(p.cod, p.descricao);
      final modo = r.modo.toString().split('.').last;
      final m = RegExp(r'\b([A-Z][A-Za-z]+)(?:\.\w+)?\s*\(').firstMatch(p.cod);
      var raiz = '?';
      var raizOk = false;
      if (m != null) {
        raiz = m.group(1)!;
        try {
          parseWidget(p.cod, m.start);
          raizOk = true;
        } catch (_) {
          raizOk = false;
        }
      }
      final status = modo != 'vivo' ? 'NAOVIVO' : (raizOk ? 'OK' : 'PARCIAL');
      if (status == 'OK') {
        full++;
      } else if (status == 'PARCIAL') {
        parcial++;
        problemas.add('PARCIAL (raiz $raiz): ${p.nome}');
      } else {
        naovivo++;
        problemas.add('NAOVIVO: ${p.nome}');
      }
      // ignore: avoid_print
      print('${status.padRight(8)} raiz=${raiz.padRight(12)} ${p.nome}');
    }
    // ignore: avoid_print
    print('RESUMO: full=$full parcial=$parcial naovivo=$naovivo de ${lista.length}');
    if (problemas.isNotEmpty) {
      // ignore: avoid_print
      print('PROBLEMAS:\n  ${problemas.join('\n  ')}');
    }
  });
}
