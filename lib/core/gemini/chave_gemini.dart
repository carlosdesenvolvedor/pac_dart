import 'package:cloud_firestore/cloud_firestore.dart';

/// A chave do Gemini NÃO mora no código (aprendemos na pele: o Google varre
/// repositórios públicos e BLOQUEIA chave commitada — "reported as leaked").
/// Ela fica no Firestore em `config/tutor`, legível só por usuário logado,
/// e trocá-la não pede redeploy: é editar o documento.
abstract final class ChaveGemini {
  static String? _cache;

  /// Injetável nos testes (e zera o cache com null).
  static FirebaseFirestore? dbParaTestes;

  static Future<String?> obter() async {
    if (_cache != null) return _cache;
    try {
      final db = dbParaTestes ?? FirebaseFirestore.instance;
      final doc = await db.collection('config').doc('tutor').get();
      final chave = doc.data()?['chaveGemini'] as String?;
      if (chave != null && chave.isNotEmpty) _cache = chave;
      return _cache;
    } catch (_) {
      return null;
    }
  }

  static void limparCache() => _cache = null;
}
