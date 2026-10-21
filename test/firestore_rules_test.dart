import 'dart:async';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

/// Testa o `firestore.rules` REAL (o que é publicado). Só vale para operações em
/// documentos soltos (get/set/delete): o fake ainda não confere regras em lotes nem
/// em listagens de coleção. Roda só na VM (lê o arquivo).
void main() {
  // O analisador do fake não conhece `rules_version` nem `allow create, update[, delete]`
  // (só `read`/`write`): essas duas linhas são trocadas; o resto do arquivo REAL entra como está.
  final regras = File('firestore.rules')
      .readAsStringSync()
      .replaceFirst(RegExp(r"rules_version\s*=\s*'2';"), '')
      .replaceAll(RegExp(r'allow create, update(, delete)?:'), 'allow write:');

  FakeFirebaseFirestore como(String? uid) =>
      FakeFirebaseFirestore(securityRules: regras, authObject: Stream.value(uid == null ? null : {'uid': uid}));

  const caminhos = [
    'users/u1/srs/b01',
    'users/u1/srs/_meta',
    'users/u1/srs_log/2026-10',
    'users/u1/audio/k3j9x2a',
    'users/u1/audio/_idx',
    'users/u1/textos/k3j9x2a',
    'users/u1/palavras/v1',
    'users/u1/setlists/v1',
  ];

  group('revisão espaçada, áudios, textos, palavras e setlists do aluno (users/{uid}/srs, srs_log, audio, textos, palavras e setlists)', () {
    test('o dono lê e escreve os blocos de cartões e o histórico', () async {
      final db = como('u1');
      for (final c in caminhos) {
        await db.doc(c).set({'c': {'k': 'f|2|1|1.0|5.0|1|0'}});
        expect((await db.doc(c).get()).exists, isTrue, reason: c);
        await db.doc(c).delete();
      }
    });

    test('outro usuário e quem não entrou NÃO leem nem escrevem os dados do dono', () async {
      for (final uid in ['u2', null]) {
        final db = como(uid);
        for (final c in caminhos) {
          await expectLater(db.doc(c).set({'c': {}}), throwsException, reason: '$uid escrevendo $c');
          await expectLater(db.doc(c).get(), throwsException, reason: '$uid lendo $c');
        }
      }
    });

    test('só essas seis subcoleções foram abertas: qualquer outra de users/{uid} continua negada ao dono', () async {
      final db = como('u1');
      await expectLater(db.doc('users/u1/outra/x').set({'a': 1}), throwsException);
      await expectLater(db.doc('users/u1/srs/b01/fundo/x').set({'a': 1}), throwsException);
    });
  });

  test('o que já existia continua valendo: o dono usa o próprio users/{uid}; ranking é legível por todo logado', () async {
    // um banco só; quem está logado muda
    final auth = StreamController<Map<String, dynamic>?>.broadcast();
    final db = FakeFirebaseFirestore(securityRules: regras, authObject: auth.stream);
    void entrar(String uid) => auth.add({'uid': uid});

    entrar('u1');
    await db.doc('users/u1').set({'concluidas': []});
    await db.doc('ranking/u1').set({'pontos': 1});
    entrar('u2');
    await expectLater(db.doc('users/u1').get(), throwsException);
    expect((await db.doc('ranking/u1').get()).exists, isTrue);
    await expectLater(db.doc('ranking/u1').set({'pontos': 9}), throwsException);
  });
}
