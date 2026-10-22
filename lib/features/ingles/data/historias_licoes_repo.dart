import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/assistir/encenador_licao.dart';

/// 📺 Carrega as historinhas das lições (`assets/ingles/historias/`): o índice (slug → versão), a tabela
/// da encenação automática e o JSON cru de cada trilha, sob demanda. O mesmo padrão do
/// `HistoriaTurismoRepo`: Future em cache só quando dá certo, `loadString(cache: false)` (um arquivo que
/// falhou offline na web não fica preso no cache do bundle) e nunca lança. O parse com a `Trilha` fica em
/// `HistoriasLicoes`, porque o repo não conhece o currículo.
abstract final class HistoriasLicoesRepo {
  static const pasta = 'assets/ingles/historias/';
  static const indice = '${pasta}indice.json';
  static const encenacao = '${pasta}encenacao_auto.json';

  /// O tempo máximo para baixar o arquivo de uma trilha.
  static const timeoutPadrao = Duration(seconds: 8);

  static Future<Map<String, int>>? _indice;
  static Future<Map<String, EncenacaoManual>>? _encenacao;

  /// slug → versão. Future em cache só no sucesso; falha → {} e tenta de novo no próximo chamado.
  static Future<Map<String, int>> trilhasComHistoria({AssetBundle? bundle}) {
    final emCache = _indice;
    if (emCache != null) return emCache;
    final ok = <bool>[false];
    final futuro = _lerIndice(bundle ?? rootBundle, ok);
    _indice = futuro;
    futuro.then((_) {
      if (!ok.first && identical(_indice, futuro)) _indice = null;
    });
    return futuro;
  }

  static Future<Map<String, int>> _lerIndice(AssetBundle bundle, List<bool> ok) async {
    try {
      final j = jsonDecode(await bundle.loadString(indice, cache: false));
      if (j is! Map) throw const FormatException('indice.json: esperava um objeto JSON');
      final trilhas = j['trilhas'];
      final r = <String, int>{};
      if (trilhas is Map) {
        for (final e in trilhas.entries) {
          final v = e.value;
          if (e.key is String && v is int) r[e.key as String] = v;
        }
      }
      ok[0] = true;
      return r;
    } catch (e) {
      debugPrint('📺 historinhas: índice indisponível: $e');
      return {};
    }
  }

  /// O JSON cru de uma trilha (null se não está no índice, falhou ou estourou o timeout). cache:false no loadString.
  static Future<Map<String, dynamic>?> trilha(String slug, {AssetBundle? bundle, Duration timeout = timeoutPadrao}) async {
    final b = bundle ?? rootBundle;
    try {
      final idx = await trilhasComHistoria(bundle: b);
      if (!idx.containsKey(slug)) return null;
      final texto = await b.loadString('$pasta$slug.json', cache: false).timeout(timeout);
      final j = jsonDecode(texto);
      if (j is Map<String, dynamic>) return j;
      if (j is Map) return j.map((k, v) => MapEntry('$k', v));
      return null;
    } catch (e) {
      debugPrint('📺 historinhas: trilha $slug indisponível: $e');
      return null;
    }
  }

  /// A tabela `encenacao_auto.json` (Licao.id → correção da automática). Cache só no sucesso; falha → {}.
  static Future<Map<String, EncenacaoManual>> encenacaoAuto({AssetBundle? bundle}) {
    final emCache = _encenacao;
    if (emCache != null) return emCache;
    final ok = <bool>[false];
    final futuro = _lerEncenacao(bundle ?? rootBundle, ok);
    _encenacao = futuro;
    futuro.then((_) {
      if (!ok.first && identical(_encenacao, futuro)) _encenacao = null;
    });
    return futuro;
  }

  static Future<Map<String, EncenacaoManual>> _lerEncenacao(AssetBundle bundle, List<bool> ok) async {
    try {
      final j = jsonDecode(await bundle.loadString(encenacao, cache: false));
      if (j is! Map) throw const FormatException('encenacao_auto.json: esperava um objeto JSON');
      final licoes = j['licoes'];
      final r = <String, EncenacaoManual>{};
      if (licoes is Map) {
        for (final e in licoes.entries) {
          final v = e.value;
          if (e.key is! String || v is! Map) continue;
          r[e.key as String] = EncenacaoManual.fromJson(v.map((k, x) => MapEntry('$k', x)));
        }
      }
      ok[0] = true;
      return r;
    } catch (e) {
      debugPrint('📺 historinhas: tabela da encenação indisponível: $e');
      return {};
    }
  }

  /// Esquece os caches (testes; e para recarregar depois de um erro).
  static void limparCache() {
    _indice = null;
    _encenacao = null;
  }
}
