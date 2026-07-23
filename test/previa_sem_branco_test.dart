import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/preview/preview_engine.dart';

/// Caça-fantasma das prévias EM BRANCO: toda prévia que o motor rotula de
/// "AO VIVO" é RENDERIZADA de verdade aqui — sem exceção de layout e com
/// tamanho de gente (nada de tela 0×0 com selo verde).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('nenhuma prévia AO VIVO do currículo inteiro sai em branco',
      (tester) async {
    final curriculo =
        jsonDecode(File('assets/curriculo.json').readAsStringSync()) as List;
    final master = jsonDecode(File('assets/master.json').readAsStringSync()) as List;
    final trilhas = [
      for (final t in curriculo) Trilha.fromJson(t as Map<String, dynamic>)
    ];
    final apps = [
      for (final p in master) Projeto.fromJson(p as Map<String, dynamic>)
    ];

    final alvos = <(String, Trecho)>[
      for (final (ti, trilha) in trilhas.indexed)
        for (final (li, licao) in trilha.licoes.indexed)
          for (final (ei, e) in licao.trechos.indexed)
            ('trilha $ti (${trilha.nivel}) lição $li trecho $ei', e),
      for (final (ti, trilha) in trilhas.indexed)
        for (final (pi, p) in trilha.projetos.indexed)
          if (p.flutter) ('trilha $ti projeto $pi (${p.nome})', p.comoTrecho),
      for (final (i, p) in apps.indexed)
        if (p.flutter) ('master $i (${p.nome})', p.comoTrecho),
    ];

    var vivos = 0, demos = 0, conceitos = 0;
    final brancos = <String>[];

    for (final (onde, trecho) in alvos) {
      final res = PreviewEngine.gerar(trecho.cod, trecho.dicaPlana);
      switch (res.modo) {
        case PreviewModo.demo:
          demos++;
          continue;
        case PreviewModo.conceito:
          conceitos++;
          continue;
        case PreviewModo.vivo:
          vivos++;
      }
      await tester.pumpWidget(MaterialApp(
        home: Material(
          color: const Color(0xFFFAFAFA),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(child: res.widget),
          ),
        ),
      ));
      final erro = tester.takeException();
      if (erro != null) {
        brancos.add('$onde → EXCEÇÃO: ${'$erro'.split('\n').first}');
        continue;
      }
      final tamanho = tester.getSize(find.byType(VidaPreview));
      // barra de progresso 150x4 pinta; 768x0 e 0x20 não — o juiz é a ÁREA
      if (tamanho.width * tamanho.height < 64) {
        brancos.add('$onde → tela ${tamanho.width.toStringAsFixed(0)}x'
            '${tamanho.height.toStringAsFixed(0)}');
      }
    }
    await tester.pumpWidget(Container());

    // ignore: avoid_print
    print('Prévias: $vivos ao vivo · $demos demos · $conceitos conceitos');
    expect(brancos, isEmpty,
        reason: '${brancos.length} prévia(s) AO VIVO em branco:\n'
            '${brancos.take(25).join('\n')}');
    expect(vivos, greaterThan(100)); // a checagem não pode "resolver" matando as vivas
  });
}
