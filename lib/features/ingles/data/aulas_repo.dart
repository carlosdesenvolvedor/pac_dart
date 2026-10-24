import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/aula_professor.dart';

/// 🎓 Carrega as aulas do professor (`assets/ingles/aulas/`): o índice (slug → versão) e cada trilha sob demanda.
/// Futures em cache só quando dão certo, `loadString(cache: false)` (um arquivo que falhou offline na web não fica
/// preso) e timeout; nunca lança. [indiceCarregado] responde na hora, sem esperar (a folha do mapa decide se mostra
/// o botão sem ficar piscando).
abstract final class AulasRepo {
  static const pasta = 'assets/ingles/aulas/';
  static const indice = '${pasta}indice.json';
  static const timeout = Duration(seconds: 8);

  /// Testes: as aulas prontas, sem ler asset (null = o bundle de verdade).
  static Map<String, AulaLicao>? fixas;

  static Future<Map<String, int>>? _indice;
  static Map<String, int>? _indicePronto;
  static final Map<String, Future<AulasDaTrilha?>> _trilhas = {};

  /// Só para testes.
  static void limpar() {
    _indice = null;
    _indicePronto = null;
    _trilhas.clear();
  }

  /// O índice já lido (null = ainda não chegou ou falhou).
  static Map<String, int>? get indiceCarregado => _indicePronto;

  /// A trilha [slug] tem aulas? (pelo índice já lido; sem ele, false — chame [trilhasComAula] antes).
  static bool temAulaNaTrilha(String slug) {
    final f = fixas;
    if (f != null) return f.keys.any((id) => trilhaDaLicao(id) == slug);
    return _indicePronto?.containsKey(slug) ?? false;
  }

  static Future<Map<String, int>> trilhasComAula({AssetBundle? bundle}) {
    final f = fixas;
    if (f != null) return Future.value({for (final id in f.keys) trilhaDaLicao(id): 1});
    return _indice ??= _lerIndice(bundle ?? rootBundle);
  }

  static Future<Map<String, int>> _lerIndice(AssetBundle bundle) async {
    try {
      final j = jsonDecode(await bundle.loadString(indice, cache: false).timeout(timeout));
      final r = <String, int>{};
      final t = j is Map ? j['trilhas'] : null;
      if (t is Map) {
        for (final e in t.entries) {
          if (e.key is String && e.value is int) r[e.key as String] = e.value as int;
        }
      }
      _indicePronto = r;
      return r;
    } catch (e) {
      debugPrint('🎓 aulas: índice indisponível: $e');
      _indice = null; // tenta de novo no próximo pedido
      return {};
    }
  }

  /// A aula da lição [licaoId] (null = não tem, ou não carregou). Nunca lança.
  static Future<AulaLicao?> daLicao(String licaoId, {AssetBundle? bundle}) async {
    final f = fixas;
    if (f != null) return f[licaoId];
    final slug = trilhaDaLicao(licaoId);
    final idx = await trilhasComAula(bundle: bundle);
    if (!idx.containsKey(slug)) return null;
    final t = await (_trilhas[slug] ??= _lerTrilha(slug, bundle ?? rootBundle));
    return t?.licoes[licaoId];
  }

  static Future<AulasDaTrilha?> _lerTrilha(String slug, AssetBundle bundle) async {
    try {
      final texto = await bundle.loadString('$pasta$slug.json', cache: false).timeout(timeout);
      return AulasDaTrilha.fromJson(jsonDecode(texto));
    } catch (e) {
      debugPrint('🎓 aulas: trilha $slug indisponível: $e');
      _trilhas.remove(slug);
      return null;
    }
  }
}
