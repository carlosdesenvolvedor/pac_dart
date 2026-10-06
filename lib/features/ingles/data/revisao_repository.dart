import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/revisao.dart';

/// Onde mora a revisão espaçada do inglês: chave da frase → cartão.
abstract interface class RevisaoRepository {
  Future<Map<String, CartaoRevisao>> carregar();

  /// Grava vários cartões de uma vez (fim de lição, fim de revisão).
  Future<void> salvar(Map<String, CartaoRevisao> cartoes);
}

/// No aparelho (offline, testes, probe).
class LocalRevisaoRepository implements RevisaoRepository {
  static const _chave = 'en_revisao';

  @override
  Future<Map<String, CartaoRevisao>> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final bruto = jsonDecode(p.getString(_chave) ?? '{}') as Map<String, dynamic>;
      return _decodificar(bruto);
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> salvar(Map<String, CartaoRevisao> cartoes) async {
    if (cartoes.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      final atual = jsonDecode(p.getString(_chave) ?? '{}') as Map<String, dynamic>;
      for (final e in cartoes.entries) {
        atual[e.key] = e.value.codificar();
      }
      await p.setString(_chave, jsonEncode(atual));
    } catch (_) {}
  }
}

/// Na nuvem: mapa `en_revisao` no MESMO `users/{uid}` do progresso (as
/// regras já deixam o dono ler e escrever o próprio documento). Cada cartão
/// é uma string curta ("caixa|dia|lapsos"): milhares cabem no 1 MiB.
class FirestoreRevisaoRepository implements RevisaoRepository {
  final String uid;
  final FirebaseFirestore _db;

  FirestoreRevisaoRepository(this.uid, {FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc => _db.collection('users').doc(uid);

  @override
  Future<Map<String, CartaoRevisao>> carregar() async {
    final snap = await _doc.get();
    final bruto = (snap.data()?['en_revisao'] as Map?) ?? const {};
    return _decodificar(bruto.map((k, v) => MapEntry('$k', v)));
  }

  @override
  Future<void> salvar(Map<String, CartaoRevisao> cartoes) async {
    if (cartoes.isEmpty) return;
    // merge:true é profundo no mapa — só as chaves enviadas mudam
    await _doc.set({
      'en_revisao': {for (final e in cartoes.entries) e.key: e.value.codificar()},
    }, SetOptions(merge: true));
  }
}

Map<String, CartaoRevisao> _decodificar(Map<String, dynamic> bruto) {
  final m = <String, CartaoRevisao>{};
  for (final e in bruto.entries) {
    final c = CartaoRevisao.decodificar(e.value);
    if (c != null) m[e.key] = c;
  }
  return m;
}
