import 'package:cloud_firestore/cloud_firestore.dart';

/// A chave do Gemini NÃO mora no código (aprendemos na pele: o Google varre
/// repositórios públicos e BLOQUEIA chave commitada — "reported as leaked").
/// Ela fica no Firestore em `config/tutor`, legível só por usuário logado,
/// e trocá-la não pede redeploy: é editar o documento.
abstract final class ChaveGemini {
  /// O doc `config/tutor` inteiro — guardado só quando a `chaveGemini` veio não vazia.
  static Map<String, dynamic>? _cache;

  /// Injetável nos testes (e zera o cache com null).
  static FirebaseFirestore? dbParaTestes;

  /// O doc `config/tutor` (do cache ou do banco), ou null se o doc não existe.
  /// LANÇA quando a leitura em si falha (offline, 'unavailable', …).
  static Future<Map<String, dynamic>?> _ler() async {
    if (_cache != null) return _cache;
    final db = dbParaTestes ?? FirebaseFirestore.instance;
    final doc = await db.collection('config').doc('tutor').get();
    final dados = doc.data();
    final chave = dados?['chaveGemini'];
    if (chave is String && chave.isNotEmpty) _cache = dados;
    return dados;
  }

  /// O mesmo que [_ler], mas nunca lança (falha de leitura → null).
  static Future<Map<String, dynamic>?> _config() async {
    try {
      return await _ler();
    } catch (_) {
      return null;
    }
  }

  static String? _chaveDe(Map<String, dynamic>? dados) {
    final chave = dados?['chaveGemini'];
    return chave is String && chave.isNotEmpty ? chave : null;
  }

  /// A chave, ou null (sem o doc, sem a chave OU leitura que falhou). Nunca lança.
  static Future<String?> obter() async => _chaveDe(await _config());

  /// Como [obter], mas separa os dois casos: null = o doc foi lido e não tem a chave;
  /// a leitura que FALHOU (offline, …) LANÇA o erro do Firestore — não é "chave ausente".
  static Future<String?> obterOuLancar() async => _chaveDe(await _ler());

  /// Um campo String não vazio de `config/tutor` (ex.: 'modeloConversa'), ou null. Nunca lança.
  static Future<String?> campo(String nome) async {
    final v = (await _config())?[nome];
    return v is String && v.isNotEmpty ? v : null;
  }

  static void limparCache() => _cache = null;
}
