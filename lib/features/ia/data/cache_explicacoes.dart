import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// As explicações já recebidas, para a mesma pergunta não chamar a IA (nem gastar cota) de novo.
/// Só no aparelho (um cache na nuvem pediria coleção e regra novas). Guarda as últimas
/// [maximo]: a mais antiga sai primeiro.
abstract interface class CacheExplicacoes {
  Future<String?> ler(String chave);
  Future<void> gravar(String chave, String texto);
}

class CacheExplicacoesLocal implements CacheExplicacoes {
  static const pref = 'ia_cache_v1';
  static const maximo = 100;

  /// Cache por conta: [uid] entra na chave da pref.
  final String? uid;

  /// A pref base e quantas respostas guarda (o "toque na palavra" tem cache próprio, maior).
  final String base;
  final int limite;
  CacheExplicacoesLocal({this.uid, this.base = pref, this.limite = maximo});

  String get _pref => uid == null ? base : '$base:$uid';

  ({List<String> ordem, Map<String, String> itens}) _ler(SharedPreferences p) {
    try {
      final j = jsonDecode(p.getString(_pref) ?? '{}');
      if (j is! Map) return (ordem: <String>[], itens: <String, String>{});
      final itens = <String, String>{
        if (j['itens'] is Map)
          for (final e in (j['itens'] as Map).entries)
            if (e.value is String) '${e.key}': e.value as String,
      };
      final ordem = <String>[
        if (j['ordem'] is List)
          for (final k in j['ordem'] as List)
            if (k is String && itens.containsKey(k)) k,
      ];
      return (ordem: ordem, itens: itens);
    } catch (_) {
      return (ordem: <String>[], itens: <String, String>{});
    }
  }

  @override
  Future<String?> ler(String chave) async {
    try {
      return _ler(await SharedPreferences.getInstance()).itens[chave];
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> gravar(String chave, String texto) async {
    if (texto.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      final c = _ler(p);
      c.ordem.remove(chave);
      c.ordem.add(chave);
      c.itens[chave] = texto;
      while (c.ordem.length > limite) {
        c.itens.remove(c.ordem.removeAt(0));
      }
      await p.setString(_pref, jsonEncode({'ordem': c.ordem, 'itens': c.itens}));
    } catch (_) {}
  }
}
