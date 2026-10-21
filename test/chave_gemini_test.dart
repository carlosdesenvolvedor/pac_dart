import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/gemini/chave_gemini.dart';

/// Um Firestore offline: a leitura em si falha.
class _DbOffline extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable', message: 'client is offline');
}

/// A chave do Gemini vem do Firestore (config/tutor) — nunca do código.
void main() {
  tearDown(() {
    ChaveGemini.limparCache();
    ChaveGemini.dbParaTestes = null;
  });

  test('lê a chave do doc config/tutor e cacheia', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('config').doc('tutor').set({'chaveGemini': 'chave-x'});
    ChaveGemini.dbParaTestes = db;

    expect(await ChaveGemini.obter(), 'chave-x');
    // segunda leitura vem do cache (nem tocaria o banco)
    ChaveGemini.dbParaTestes = FakeFirebaseFirestore();
    expect(await ChaveGemini.obter(), 'chave-x');
  });

  test('sem o doc, devolve null (tutor mostra recado, voz cai no fallback)', () async {
    ChaveGemini.dbParaTestes = FakeFirebaseFirestore();
    expect(await ChaveGemini.obter(), isNull);
  });

  test('campo: lê um campo String de config/tutor (ex.: modeloConversa) e usa o mesmo cache', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('config').doc('tutor').set({'chaveGemini': 'chave-x', 'modeloConversa': 'gemini-flash-lite-latest'});
    ChaveGemini.dbParaTestes = db;

    expect(await ChaveGemini.campo('modeloConversa'), 'gemini-flash-lite-latest');
    // veio junto com a chave: o cache vale para os dois (nem tocaria o banco novo)
    ChaveGemini.dbParaTestes = FakeFirebaseFirestore();
    expect(await ChaveGemini.obter(), 'chave-x');
    expect(await ChaveGemini.campo('modeloConversa'), 'gemini-flash-lite-latest');
  });

  test('campo ausente, vazio ou que não é texto → null; obter segue o mesmo contrato', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('config').doc('tutor').set({'chaveGemini': 'chave-x', 'vazio': '', 'numero': 3});
    ChaveGemini.dbParaTestes = db;
    expect(await ChaveGemini.campo('modeloConversa'), isNull);
    expect(await ChaveGemini.campo('vazio'), isNull);
    expect(await ChaveGemini.campo('numero'), isNull);
    expect(await ChaveGemini.obter(), 'chave-x');
  });

  test('sem chave não cacheia nada: o campo é lido, e a chave nova aparece na próxima leitura', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('config').doc('tutor').set({'modeloConversa': 'gemini-flash-latest'});
    ChaveGemini.dbParaTestes = db;
    expect(await ChaveGemini.obter(), isNull);
    expect(await ChaveGemini.campo('modeloConversa'), 'gemini-flash-latest');
    await db.collection('config').doc('tutor').set({'chaveGemini': 'chave-nova'});
    expect(await ChaveGemini.obter(), 'chave-nova');
    expect(await ChaveGemini.campo('modeloConversa'), isNull);
  });

  test('leitura que FALHA: obter/campo devolvem null (não lançam); obterOuLancar lança — não é "sem chave"', () async {
    ChaveGemini.dbParaTestes = _DbOffline();
    expect(await ChaveGemini.obter(), isNull);
    expect(await ChaveGemini.campo('modeloConversa'), isNull);
    await expectLater(ChaveGemini.obterOuLancar(), throwsA(isA<FirebaseException>()));
  });

  test('obterOuLancar: doc lido sem a chave → null; com a chave → a chave (e o cache vale)', () async {
    ChaveGemini.dbParaTestes = FakeFirebaseFirestore();
    expect(await ChaveGemini.obterOuLancar(), isNull);
    final db = FakeFirebaseFirestore();
    await db.collection('config').doc('tutor').set({'chaveGemini': 'chave-x'});
    ChaveGemini.dbParaTestes = db;
    expect(await ChaveGemini.obterOuLancar(), 'chave-x');
    ChaveGemini.dbParaTestes = _DbOffline();
    expect(await ChaveGemini.obterOuLancar(), 'chave-x', reason: 'do cache, sem tocar o banco');
  });

  test('campo sem o doc devolve null e não lança', () async {
    ChaveGemini.dbParaTestes = FakeFirebaseFirestore();
    expect(await ChaveGemini.campo('modeloConversa'), isNull);
  });
}
