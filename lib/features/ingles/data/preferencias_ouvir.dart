import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/config_ouvir.dart';

/// O que o "🎧 Ouvir" lembra no aparelho (só local): a config (pref `en_ouvir_cfg`) e onde parou em cada
/// fonte (pref `en_ouvir_pos_<uid>` = `{fonteId: {"i": int, "k": chave, "m": ms}}`). Nunca lança: pref
/// estragada = o padrão.
class PreferenciasOuvir {
  final String uid;

  ConfigOuvir _config = const ConfigOuvir();

  /// fonteId → (índice, chave da frase, quando).
  final Map<String, ({int i, String chave, int m})> _posicoes = {};

  Future<void>? _carregando;

  PreferenciasOuvir(this.uid);

  static const prefConfig = 'en_ouvir_cfg';
  String get prefPosicoes => 'en_ouvir_pos_$uid';

  /// Quantas fontes guardam posição (as mais antigas saem).
  static const maxPosicoes = 60;

  /// Memoizado: chamar de novo devolve a mesma leitura.
  Future<void> carregar() => _carregando ??= _ler();

  Future<void> _ler() async {
    try {
      final p = await SharedPreferences.getInstance();
      final cfg = p.getString(prefConfig);
      if (cfg != null) {
        try {
          final j = jsonDecode(cfg);
          _config = ConfigOuvir.fromJson(j is Map ? j : null);
        } catch (_) {}
      }
      final pos = p.getString(prefPosicoes);
      if (pos != null) {
        try {
          final j = jsonDecode(pos);
          if (j is Map) {
            for (final e in j.entries) {
              final v = e.value;
              if (e.key is! String || v is! Map) continue;
              final i = v['i'], k = v['k'], m = v['m'];
              if (i is! int || i < 0 || k is! String) continue;
              _posicoes[e.key as String] = (i: i, chave: k, m: m is int ? m : 0);
            }
          }
        } catch (_) {}
      }
    } catch (_) {}
  }

  ConfigOuvir get config => _config;

  Future<void> salvarConfig(ConfigOuvir c) async {
    _config = c;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(prefConfig, jsonEncode(c.toJson()));
    } catch (_) {}
  }

  ({int i, String chave})? posicao(String fonteId) {
    final p = _posicoes[fonteId];
    return p == null ? null : (i: p.i, chave: p.chave);
  }

  Future<void> salvarPosicao(String fonteId, int i, String chave) async {
    _posicoes[fonteId] = (i: i, chave: chave, m: DateTime.now().millisecondsSinceEpoch);
    if (_posicoes.length > maxPosicoes) {
      final velhas = _posicoes.entries.toList()..sort((a, b) => a.value.m.compareTo(b.value.m));
      for (final e in velhas.take(_posicoes.length - maxPosicoes)) {
        _posicoes.remove(e.key);
      }
    }
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(prefPosicoes, jsonEncode({
        for (final e in _posicoes.entries) e.key: {'i': e.value.i, 'k': e.value.chave, 'm': e.value.m},
      }));
    } catch (_) {}
  }
}

/// Em memória (testes).
class PreferenciasOuvirMemoria implements PreferenciasOuvir {
  @override
  final String uid;

  @override
  ConfigOuvir _config;

  @override
  final Map<String, ({int i, String chave, int m})> _posicoes = {};

  @override
  Future<void>? _carregando;

  final Map<String, ({int i, String chave})> posicoes = {};

  PreferenciasOuvirMemoria({this.uid = 'memoria', ConfigOuvir config = const ConfigOuvir()}) : _config = config;

  @override
  String get prefPosicoes => 'en_ouvir_pos_$uid';

  @override
  Future<void> carregar() async {}

  @override
  Future<void> _ler() async {}

  @override
  ConfigOuvir get config => _config;

  @override
  Future<void> salvarConfig(ConfigOuvir c) async => _config = c;

  @override
  ({int i, String chave})? posicao(String fonteId) => posicoes[fonteId];

  @override
  Future<void> salvarPosicao(String fonteId, int i, String chave) async => posicoes[fonteId] = (i: i, chave: chave);
}
