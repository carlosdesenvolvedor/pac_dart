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

  /// O tempo máximo para baixar um arquivo (índice, tabela ou trilha). Uma conexão que trava sem falhar
  /// (portal cativo, dados móveis ruins) não pode deixar um Future pendente preso no cache: o índice e a tabela
  /// em voo há mais que isto são abandonados e o próximo pedido tenta de novo ([emVooTravado]); a trilha (e o
  /// índice que ela espera) estoura no `timeout`. Sem `Timer` no Future compartilhado: o índice e a tabela
  /// podem ficar em voo para sempre num teste de widget (o `compute` do loadString grande não anda no relógio
  /// falso), e um Timer pendurado quebraria esses testes.
  static const timeoutPadrao = Duration(seconds: 8);

  static _EmVoo<Map<String, int>>? _indice;
  static _EmVoo<Map<String, EncenacaoManual>>? _encenacao;

  /// O índice ou a tabela está em voo há mais que [timeout] (a conexão travou).
  static bool emVooTravado({Duration timeout = timeoutPadrao}) =>
      (_indice?.travado(timeout) ?? false) || (_encenacao?.travado(timeout) ?? false);

  /// slug → versão. Future em cache só no sucesso; falha → {} e tenta de novo no próximo chamado (também se o
  /// pedido anterior travou por mais que [timeout]).
  static Future<Map<String, int>> trilhasComHistoria({AssetBundle? bundle, Duration timeout = timeoutPadrao}) {
    final emCache = _indice;
    if (emCache != null && !emCache.travado(timeout)) return emCache.futuro;
    final ok = <bool>[false];
    final voo = _EmVoo(_lerIndice(bundle ?? rootBundle, ok));
    _indice = voo;
    voo.futuro.then((_) {
      voo.pronto = true;
      if (!ok.first && identical(_indice, voo)) _indice = null;
    });
    return voo.futuro;
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
      final idx = await trilhasComHistoria(bundle: b, timeout: timeout).timeout(timeout);
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

  /// A tabela `encenacao_auto.json` (Licao.id → correção da automática). Cache só no sucesso; falha → {} (e o
  /// pedido travado por mais que [timeout] é abandonado, como o do índice).
  static Future<Map<String, EncenacaoManual>> encenacaoAuto({AssetBundle? bundle, Duration timeout = timeoutPadrao}) {
    final emCache = _encenacao;
    if (emCache != null && !emCache.travado(timeout)) return emCache.futuro;
    final ok = <bool>[false];
    final voo = _EmVoo(_lerEncenacao(bundle ?? rootBundle, ok));
    _encenacao = voo;
    voo.futuro.then((_) {
      voo.pronto = true;
      if (!ok.first && identical(_encenacao, voo)) _encenacao = null;
    });
    return voo.futuro;
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

/// Um Future do cache e quando ele saiu (para abandonar o que travou sem Timer).
class _EmVoo<T> {
  _EmVoo(this.futuro);

  final Future<T> futuro;
  final _relogio = Stopwatch()..start();
  bool pronto = false;

  bool travado(Duration timeout) => !pronto && _relogio.elapsed > timeout;
}
