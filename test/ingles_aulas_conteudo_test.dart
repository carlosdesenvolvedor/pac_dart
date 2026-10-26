// 🎓 O conteúdo das aulas do professor no app: toda lição do curso tem aula, toda aula lê inteira no app (nenhuma
// fala some no parse), é uma aula de verdade (6 a 10 minutos, em partes, dizendo todas as frases da lição) e toda
// fala tem o mp3 do Prof. Beto e a boca dele no site (web/aula_voz/<slug>.json → arquivo existe).
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/aula_professor.dart';

void main() {
  final curriculo = jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List;
  final indice = (jsonDecode(File('assets/ingles/aulas/indice.json').readAsStringSync()) as Map)['trilhas'] as Map;
  final licoes = {
    for (final t in curriculo)
      for (final l in t['licoes'] as List) l['id'] as String: l as Map,
  };

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

  test('toda lição do curso tem aula, do A1 ao DEV (e as aulas são de lições que existem)', () {
    final todas = [
      for (final t in curriculo)
        for (final l in t['licoes'] as List) l['id'] as String,
    ];
    expect(todas.length, greaterThanOrEqualTo(796));
    expect(todas.where((id) => !aulas.containsKey(id)), isEmpty);
    expect(aulas.keys.where((id) => !licoes.containsKey(id)), isEmpty);
  });

  test('cada aula é uma aula inteira: 6 a 10 minutos, em partes, com figuras e todas as frases da lição', () {
    final ruins = <String>[];
    for (final e in aulas.entries) {
      final a = e.value;
      final ditas = {
        for (final f in a.falas)
          if (f.ingles) f.en,
      };
      final faltam = [
        for (final t in licoes[e.key]!['trechos'] as List)
          if (!ditas.contains((t['cod'] as String).trim())) t['cod'],
      ];
      final foto = a.falas.any((f) => f.img == figuraFoto);
      if (a.segundos < 4.5 * 60 || a.segundos > 13 * 60) ruins.add('${e.key}: ${a.segundos ~/ 60} min');
      if (a.secoes.length < 5) ruins.add('${e.key}: ${a.secoes.length} partes');
      if (faltam.isNotEmpty) ruins.add('${e.key}: não diz $faltam');
      if (foto && !File(licoes[e.key]!['foto'] as String? ?? '').existsSync()) ruins.add('${e.key}: foto sem arquivo');
    }
    expect(ruins, isEmpty);
  });

  // Os mp3 não vão para o git (centenas de MB; regerar: tools/ingles/aulas/vozes_aula.py): numa cópia sem eles
  // (sessão na nuvem, CI) este teste não tem o que conferir.
  final semMp3 =
      !Directory('web/aula_voz').existsSync() ||
      !Directory('web/aula_voz').listSync().any((f) => f.path.endsWith('.mp3'));
  test(
    'toda fala tem o mp3 do professor e a boca dele no site (web/aula_voz)',
    skip: semMp3 ? 'sem os mp3 das aulas nesta cópia' : null,
    () {
      final semIndice = <String>[], semVoz = <String>[], semArquivo = <String>[], semBoca = <String>[];
      for (final slug in indice.keys) {
        final f = File('web/aula_voz/$slug.json');
        if (!f.existsSync()) {
          semIndice.add(slug);
          continue;
        }
        final vozes = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
        for (final aula in aulas.entries.where((e) => trilhaDaLicao(e.key) == slug).map((e) => e.value)) {
          for (final fala in aula.falas) {
            final v = vozes['${fala.ingles ? 'en' : 'pt'}|${fala.texto}'] as List?;
            if (v == null) {
              semVoz.add(fala.texto);
            } else if (!File('web/aula_voz/${v[0]}').existsSync()) {
              semArquivo.add(v[0] as String);
            } else if ((v[1] as String).isEmpty) {
              semBoca.add(v[0] as String);
            }
          }
        }
      }
      expect(semIndice, isEmpty, reason: 'rodar tools/ingles/aulas/vozes_aula.py');
      expect(semVoz, isEmpty, reason: 'rodar tools/ingles/aulas/vozes_aula.py');
      expect(semArquivo, isEmpty);
      expect(semBoca.length, lessThan(5), reason: 'rodar tools/ingles/aulas/vozes_aula.py (faz a boca do que falta)');
    },
  );

  test('a voz das aulas NÃO vai no pacote do app (fica no site)', () {
    expect(File('pubspec.yaml').readAsStringSync(), isNot(contains('aula_voz')));
    expect(Directory('assets/ingles/voz_aula').existsSync(), isFalse);
  });
}
