import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'fala_stub.dart'
    if (dart.library.js_interop) 'fala_web.dart'
    if (dart.library.io) 'fala_nativo.dart' as fala;

/// O mp3 de uma fala da aula ([url] inteira, no site) e a boca dela (o lip sync compacto; '' = sem).
typedef VozDaFala = ({String url, String boca});

/// 🎓 A voz do Prof. Beto nas aulas. As aulas longas (6 a 10 minutos cada) passam de 200 MB de mp3: elas NÃO vão
/// no pacote do app — ficam no site (`web/aula_voz/`, publicado junto com o app web), com um índice por trilha,
/// `aula_voz/<slug>.json` = {"pt|texto": ["<arquivo>.mp3", "<boca>"], "en|texto": [...]} (gerado por
/// `tools/ingles/aulas/vozes_aula.py`). Na web o endereço é o do próprio site; no celular, o do site publicado.
/// Sem rede (ou sem a trilha no índice): [de] devolve null e a aula fala com a voz pt-BR do aparelho. Nunca lança.
abstract final class VozesAula {
  static const pasta = 'aula_voz/';
  static const timeout = Duration(seconds: 10);

  /// Testes: as vozes prontas por trilha, sem rede (null = buscar no site).
  static Map<String, Map<String, VozDaFala>>? fixas;

  static final Map<String, Future<Map<String, VozDaFala>?>> _pedidos = {};
  static final Map<String, Map<String, VozDaFala>> _prontas = {};

  /// Só para testes.
  static void limpar() {
    _pedidos.clear();
    _prontas.clear();
  }

  static String chave(String texto, {required bool ingles}) => '${ingles ? 'en' : 'pt'}|${texto.trim()}';

  /// Busca o índice das vozes da trilha [slug] (uma vez; o que falhou tenta de novo no próximo pedido).
  /// true = carregou.
  static Future<bool> carregar(String slug) async {
    final f = fixas;
    if (f != null) return f.containsKey(slug);
    if (_prontas.containsKey(slug)) return true;
    final r = await (_pedidos[slug] ??= _buscar(slug));
    return r != null;
  }

  static Future<Map<String, VozDaFala>?> _buscar(String slug) async {
    try {
      final resp = await http.get(Uri.parse(fala.urlDoSite('$pasta$slug.json'))).timeout(timeout);
      if (resp.statusCode != 200) throw StateError('HTTP ${resp.statusCode}');
      final j = jsonDecode(utf8.decode(resp.bodyBytes));
      final r = <String, VozDaFala>{};
      if (j is Map) {
        for (final e in j.entries) {
          final v = e.value;
          if (e.key is String && v is List && v.isNotEmpty && v.first is String) {
            r[e.key as String] = (
              url: fala.urlDoSite('$pasta${v.first}'),
              boca: v.length > 1 && v[1] is String ? v[1] as String : '',
            );
          }
        }
      }
      return _prontas[slug] = r;
    } catch (e) {
      debugPrint('🎓 voz da aula: trilha $slug indisponível: $e');
      _pedidos.remove(slug);
      return null;
    }
  }

  /// A voz da fala [texto] da trilha [slug] (já [carregar]ada), ou null (a voz do aparelho assume).
  static VozDaFala? de(String slug, String texto, {required bool ingles}) =>
      (fixas ?? _prontas)[slug]?[chave(texto, ingles: ingles)];
}
