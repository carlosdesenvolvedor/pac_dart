import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/historia_turismo.dart';

/// 📖 Carrega a história do English Turismo (3 JSON em `assets/ingles/`, um por roteirista).
abstract final class HistoriaTurismoRepo {
  static const arquivos = [
    'assets/ingles/turismo_historia_a.json',
    'assets/ingles/turismo_historia_b.json',
    'assets/ingles/turismo_historia_c.json',
  ];

  static Future<HistoriaTurismo?>? _cache;

  /// Future em cache só quando dá certo; falha (arquivo ausente, rede) → null e o próximo chamado tenta de novo.
  /// Parse TOLERANTE (estrito: false). Em debug, roda validar() e faz debugPrint das mensagens.
  static Future<HistoriaTurismo?> carregar({AssetBundle? bundle}) {
    final emCache = _cache;
    if (emCache != null) return emCache;
    final futuro = _carregar(bundle ?? rootBundle);
    _cache = futuro;
    futuro.then((h) {
      if (h == null && identical(_cache, futuro)) _cache = null;
    });
    return futuro;
  }

  static Future<HistoriaTurismo?> _carregar(AssetBundle bundle) async {
    try {
      final partes = <Map<String, dynamic>>[];
      for (final a in arquivos) {
        // cache:false: um arquivo que falhou (offline na web) não fica preso no cache do bundle
        final texto = await bundle.loadString(a, cache: false);
        final j = jsonDecode(texto);
        if (j is! Map<String, dynamic>) throw FormatException('$a: esperava um objeto JSON');
        partes.add(j);
      }
      final h = HistoriaTurismo.dasPartes(partes, estrito: false, aviso: (m) => debugPrint('📖 história: $m'));
      if (h.capitulos.isEmpty) return null;
      if (kDebugMode) {
        for (final m in h.validar()) {
          debugPrint('📖 história (validar): $m');
        }
      }
      return h;
    } catch (e) {
      debugPrint('📖 história indisponível: $e');
      return null;
    }
  }

  @visibleForTesting
  static void limparCache() => _cache = null;
}
