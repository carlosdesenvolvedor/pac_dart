import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/gemini/chave_gemini.dart';

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
}
