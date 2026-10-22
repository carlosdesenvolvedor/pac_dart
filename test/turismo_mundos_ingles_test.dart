import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Retoques dos mundos 3D (aurora, estrelas, Cratera Lunar, areia, mar): o
/// motor web/turismo3d/turismo3d.js é o mesmo nos 3 cursos, e só o inglês liga
/// os retoques, pela chave `ingles` do config de `montar`.
///
/// A vista (vista_3d_web.dart) importa dart:ui_web e package:web, que não rodam
/// na VM dos testes, e o config é montado dentro do State; por isso a conferência
/// é no texto dos fontes, como já faz o turismo_ambiente_test com a VERSAO.
void main() {
  final dart = File('lib/features/arcade/presentation/widgets/vista_3d_web.dart').readAsStringSync();
  final js = File('web/turismo3d/turismo3d.js').readAsStringSync();

  test('a vista manda `ingles` no config do montar (true só no curso de inglês)', () {
    expect(dart, contains("'ingles': Linguagem.atual == Linguagem.ingles,"));
    expect(dart, contains("import '../../../../core/linguagem/linguagem.dart';"));
    // a chave vai no mesmo Map que segue pro js.montar
    final config = dart.indexOf('final config = {');
    final chave = dart.indexOf("'ingles': Linguagem.atual");
    final montar = dart.indexOf('js.montar(canvas, config.jsify()!)');
    expect(config, greaterThan(0));
    expect(chave, inExclusiveRange(config, montar));
  });

  test('o JS lê a chave e só aplica os retoques com ela ligada', () {
    expect(js, contains('cfg.ingles = !!config.ingles;'));
    expect(js, contains('if (cfg.ingles && cfg.tema.retoqueIngles) cfg.tema = { ...cfg.tema, ...cfg.tema.retoqueIngles };'));
    // os temas 12 (mar), 14 (areia) e 23 (Lua) guardam o retoque à parte
    for (final t in [12, 14, 23]) {
      final ini = js.indexOf(RegExp('^  $t: \\{', multiLine: true));
      final fim = js.indexOf(RegExp('^  ${t + 1}: \\{', multiLine: true));
      expect(js.substring(ini, fim), contains('retoqueIngles:'), reason: 'tema $t');
    }
    // mar com duas escalas, estrelas e aurora: tudo atrás de cfg.ingles
    expect(js, contains('if (!gelo && cfg.ingles) {'));
    expect(js, contains('mar ? (cfg.ingles ? 140 : 20)'));
    expect(js, contains('size: cfg.ingles ? 2.8 : 2.2'));
    expect(js, contains("nFitas = ing ? (nivelQualidade === 'minima' ? 2 : 3) : 2"));
  });
}
