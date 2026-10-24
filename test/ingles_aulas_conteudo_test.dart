// 🎓 O conteúdo das aulas do professor no app: toda lição do A1 tem aula, toda aula lê inteira no app (nenhuma
// fala some no parse), toda fala tem o mp3 do Prof. Beto (vozes_aula.json → arquivo existe) e a boca dele.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/aula_professor.dart';

void main() {
  final curriculo = jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List;
  final indice = (jsonDecode(File('assets/ingles/aulas/indice.json').readAsStringSync()) as Map)['trilhas'] as Map;
  final vozes = jsonDecode(File('assets/ingles/vozes_aula.json').readAsStringSync()) as Map<String, dynamic>;
  final bocas = jsonDecode(File('assets/ingles/bocas.json').readAsStringSync()) as Map<String, dynamic>;

  final aulas = <String, AulaLicao>{};
  setUpAll(() {
    for (final slug in indice.keys) {
      final cru = jsonDecode(File('assets/ingles/aulas/$slug.json').readAsStringSync()) as Map;
      final t = AulasDaTrilha.fromJson(cru);
      expect(t.trilha, slug);
      final brutas = cru['licoes'] as Map;
      for (final e in brutas.entries) {
        final aula = t.licoes[e.key];
        expect(aula, isNotNull, reason: '${e.key} não leu');
        expect(aula!.falas.length, (e.value['falas'] as List).length, reason: '${e.key}: alguma fala sumiu no parse');
      }
      aulas.addAll(t.licoes);
    }
  });

  test('toda lição do A1 tem aula (e as aulas são de lições que existem)', () {
    final a1 = [
      for (final t in curriculo)
        if ((t['etapa'] as String).startsWith('A1'))
          for (final l in t['licoes'] as List) l['id'] as String,
    ];
    expect(a1.length, greaterThanOrEqualTo(150));
    expect(a1.where((id) => !aulas.containsKey(id)), isEmpty);
    final todas = {
      for (final t in curriculo)
        for (final l in t['licoes'] as List) l['id'] as String,
    };
    expect(aulas.keys.where((id) => !todas.contains(id)), isEmpty);
  });

  test('toda fala tem o mp3 do professor e a boca dele', () {
    final semVoz = <String>[], semArquivo = <String>[], semBoca = <String>[];
    for (final aula in aulas.values) {
      for (final f in aula.falas) {
        final asset = vozes['${f.ingles ? 'en' : 'pt'}|${f.texto}'] as String?;
        if (asset == null) {
          semVoz.add(f.texto);
        } else if (!File(asset).existsSync()) {
          semArquivo.add(asset);
        } else if (bocas[asset] == null) {
          semBoca.add(asset);
        }
      }
    }
    expect(semVoz, isEmpty, reason: 'rodar tools/ingles/aulas/vozes_aula.py');
    expect(semArquivo, isEmpty);
    expect(semBoca, isEmpty, reason: 'rodar tools/ingles/bocas_rhubarb.py');
  });
}
