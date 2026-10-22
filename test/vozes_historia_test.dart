// 🎙️ Dados das vozes (lote "trocar as vozes" + D15): toda fala da história do Turismo e toda frase do curso de
// inglês têm um mp3 de personagem que existe no disco, com a boca do Rhubarb. Lê os arquivos por dart:io.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/ingles/data/audio_nativo.dart';

Map<String, dynamic> _json(String p) => jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final partes = [for (final p in 'abc'.split('')) _json('assets/ingles/turismo_historia_$p.json')];
  final historia = HistoriaTurismo.dasPartes(partes, estrito: true);
  final falas = [
    for (final cap in historia.capitulos)
      for (final parte in ParteDoCapitulo.values)
        for (final cena in cap.parte(parte))
          for (final f in cena.falas)
            if ((f.en ?? '').isNotEmpty) (cap: cap.pista, quem: f.quem, en: f.en!),
  ];
  final indice = _json(AudioNativo.indiceHistoria);
  final bocas = _json('assets/ingles/bocas.json');

  test('toda fala da história com texto em inglês tem o mp3 de quem fala, no disco, com boca', () {
    expect(falas.length, greaterThanOrEqualTo(400));
    for (final f in falas) {
      final chave = '${f.quem}|${f.en}';
      final asset = indice[chave];
      expect(asset, isA<String>(), reason: 'cap ${f.cap}: "$chave" sem voz');
      final arq = File(asset as String);
      expect(arq.existsSync(), isTrue, reason: '"$chave" (falta $asset)');
      expect(arq.lengthSync(), greaterThan(1000), reason: '"$chave" ($asset vazio)');
      expect(bocas.containsKey(asset), isTrue, reason: '"$chave" ($asset) sem boca do Rhubarb');
    }
    // max, kim e o narrador da história também falam com mp3
    final quem = {for (final k in indice.keys) k.split('|').first};
    expect(quem, containsAll(['max', 'kim', 'narrador', 'voce']));
  });

  test('nenhum mp3 sobrando em voz_historia/, nenhuma chave sem fala; a pasta está no pubspec', () {
    final usados = {for (final v in indice.values) (v as String).split('/').last};
    final naPasta = Directory('assets/ingles/voz_historia')
        .listSync()
        .map((e) => e.path.split('/').last)
        .where((n) => n.endsWith('.mp3'))
        .toSet();
    expect(naPasta.difference(usados), isEmpty);
    expect(indice.keys.toSet(), {for (final f in falas) '${f.quem}|${f.en}'});
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/ingles/voz_historia/'));
  });

  test('o mesmo texto com falantes diferentes toca vozes diferentes ("Copy that!")', () {
    final porTexto = <String, Set<String>>{};
    for (final e in indice.entries) {
      porTexto.putIfAbsent(e.key.split('|').last, () => {}).add(e.value as String);
    }
    final quemPorTexto = <String, Set<String>>{};
    for (final f in falas) {
      quemPorTexto.putIfAbsent(f.en, () => {}).add(f.quem);
    }
    for (final e in quemPorTexto.entries.where((e) => e.value.length > 1)) {
      expect(porTexto[e.key]!.length, e.value.length, reason: '"${e.key}" (${e.value})');
    }
  });

  test('toda frase do curso de inglês tem a voz do personagem (mp3 no disco, com boca)', () {
    final geradas = _json(AudioNativo.indiceGeradas);
    final trilhas = jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List;
    final falantes = <String, Set<String>>{};
    for (final t in trilhas) {
      for (final l in (t as Map)['licoes'] as List) {
        for (final f in (l as Map)['trechos'] as List) {
          falantes.putIfAbsent(((f as Map)['cod'] as String).trim(), () => {}).add((f['quem'] ?? '') as String);
        }
      }
    }
    var n = 0, noTatoeba = 0;
    for (final t in trilhas) {
      for (final l in (t as Map)['licoes'] as List) {
        for (final f in (l as Map)['trechos'] as List) {
          final cod = ((f as Map)['cod'] as String).trim();
          final asset = geradas[cod];
          final au = (f['au'] ?? '') as String;
          // exceção: frase do Tatoeba dita por personagens de vozes diferentes segue no Tatoeba (com boca)
          if (asset == null && au.isNotEmpty && falantes[cod]!.length > 1) {
            expect(bocas.containsKey(au), isTrue, reason: '"$cod" ($au) sem boca');
            noTatoeba++;
            continue;
          }
          expect(asset, isA<String>(), reason: '"$cod" sem voz do personagem');
          expect(File(asset as String).existsSync(), isTrue, reason: '"$cod" (falta $asset)');
          expect(bocas.containsKey(asset), isTrue, reason: '"$cod" ($asset) sem boca');
          n++;
        }
      }
    }
    expect(n, greaterThanOrEqualTo(5000));
    expect(noTatoeba, lessThanOrEqualTo(10));
  });
}
