import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/texto_salvo.dart';

/// Onde moram os textos que a pessoa colou e viraram lições.
abstract interface class TextosRepository {
  /// Do mais novo para o mais antigo.
  Future<List<TextoSalvo>> carregar();
  Future<void> salvar(TextoSalvo texto);
  Future<void> apagar(String id);
}

/// No aparelho/navegador (shared_preferences), uma lista por conta. Nunca
/// lança: sem armazenamento ou com dado quebrado, a lista só vem vazia.
class LocalTextosRepository implements TextosRepository {
  final String uid;
  LocalTextosRepository(this.uid);

  String get _chave => 'en_textos_$uid';

  @override
  Future<List<TextoSalvo>> carregar() async {
    try {
      final p = await SharedPreferences.getInstance();
      final bruto = p.getString(_chave);
      if (bruto == null) return const [];
      final lista = jsonDecode(bruto);
      if (lista is! List) return const [];
      return [for (final e in lista) ?TextoSalvo.fromJson(e)]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));
    } catch (_) {
      return const [];
    }
  }

  Future<void> _gravar(List<TextoSalvo> textos) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(_chave, jsonEncode([for (final t in textos) t.toJson()]));
    } catch (_) {}
  }

  @override
  Future<void> salvar(TextoSalvo texto) async {
    final todos = (await carregar()).where((t) => t.id != texto.id).toList()..add(texto);
    await _gravar(todos);
  }

  @override
  Future<void> apagar(String id) async {
    await _gravar((await carregar()).where((t) => t.id != id).toList());
  }
}
