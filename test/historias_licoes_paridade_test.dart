import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';

/// 📺 Paridade Dart ↔ Python (plano §5.3, I12): os mesmos fixtures de `tools/ingles/historias/fixtures/` que o
/// `validar_historias_licoes.py --auto-teste` confere. Cada `<caso>.json` tem de dar, no validador OFICIAL do
/// Dart, exatamente as linhas de `<caso>.esperado.txt` (vazio = 0 erros). Contrato (fixtures/LEIAME.md):
/// - a trilha de referência é a do 1º `Licao.id` em `licoes` (o campo `trilha` pode estar errado de propósito);
/// - se `HistoriasDaTrilha.fromJson(estrito: true)` lança, a única linha é a `FormatException.message`;
/// - senão, as linhas são o `validarHistoriasDaTrilha(h, trilha)` (os avisos de "sem história" não entram).
///
/// Em divergência, o Dart manda: regrave o `.esperado.txt` com o que o Dart deu e conserte o Python.

const _pasta = 'tools/ingles/historias/fixtures';

final _porSlug = {
  for (final t in (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
      .map((e) => Trilha.fromJson(e as Map<String, dynamic>)))
    if (!t.propria && t.licoes.isNotEmpty) slugDaLicao(t.licoes.first.id): t,
};

List<String> _doDart(Map<String, dynamic> j) {
  String? slug;
  final licoes = j['licoes'];
  if (licoes is Map && licoes.isNotEmpty) slug = slugDaLicao(licoes.keys.first as String);
  slug ??= j['trilha'] as String?;
  final trilha = _porSlug[slug];
  if (trilha == null) return ['(trilha de referência não encontrada: $slug)'];
  try {
    final h = HistoriasDaTrilha.fromJson(j, trilha: trilha, estrito: true);
    return validarHistoriasDaTrilha(h, trilha);
  } on FormatException catch (e) {
    return [e.message];
  }
}

List<String> _linhas(String texto) => [
      for (final l in const LineSplitter().convert(texto))
        if (l.trim().isNotEmpty) l,
    ];

void main() {
  final casos = [
    for (final f in Directory(_pasta).listSync().whereType<File>())
      if (f.path.endsWith('.json')) f.uri.pathSegments.last.replaceAll('.json', ''),
  ]..sort();

  test('os fixtures existem (≥ 1 por regra L e os da L-base) e cada um tem o seu esperado', () {
    expect(casos.length, greaterThanOrEqualTo(15));
    expect(casos, contains('00_boa'));
    for (final c in casos) {
      expect(File('$_pasta/$c.esperado.txt').existsSync(), isTrue, reason: c);
    }
  });

  test('o fixture bom (o exemplo oficial §5.4) é o exemplo_licao.json da receita', () {
    final boa = jsonDecode(File('$_pasta/00_boa.json').readAsStringSync());
    final exemplo = jsonDecode(File('tools/ingles/historias/exemplo_licao.json').readAsStringSync());
    expect(boa, exemplo);
  });

  for (final c in casos) {
    test('$c: o Dart dá exatamente as mensagens do esperado.txt', () {
      final j = jsonDecode(File('$_pasta/$c.json').readAsStringSync()) as Map<String, dynamic>;
      final esperado = _linhas(File('$_pasta/$c.esperado.txt').readAsStringSync());
      expect(_doDart(j), esperado);
      // Todo caso negativo falha mesmo (senão o fixture não prova nada).
      if (c != '00_boa') expect(esperado, isNotEmpty, reason: c);
    });
  }
}
