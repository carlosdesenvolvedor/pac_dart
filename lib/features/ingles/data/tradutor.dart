import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// A tradução não saiu; [mensagem] já vem em português para mostrar na tela.
class TraducaoFalhou implements Exception {
  final String mensagem;

  /// Acabou a cota do dia do serviço gratuito (tentar de novo só mais tarde).
  final bool cota;

  const TraducaoFalhou(this.mensagem, {this.cota = false});

  @override
  String toString() => mensagem;
}

/// Traduz as frases em inglês das lições feitas de texto colado. Um contrato
/// pequeno para trocar o serviço (MyMemory hoje; Gemini, DeepL… amanhã) sem
/// mexer na tela.
abstract interface class Tradutor {
  /// Devolve, na mesma ordem, a tradução de cada frase. [aoProgredir] avisa
  /// quantas já foram. Lança [TraducaoFalhou] se não deu.
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir});
}

/// MyMemory (api.mymemory.translated.net): grátis, sem chave, aceita chamadas
/// do navegador (CORS aberto) e do celular. Limite do plano anônimo: ~5.000
/// caracteres por dia por IP — quando acaba, a resposta vem com um aviso no
/// lugar da tradução, que aqui vira [TraducaoFalhou] (nunca vira "tradução").
/// O que já foi traduzido fica em [_cache]: tentar de novo continua de onde
/// parou, sem gastar a cota outra vez.
class TradutorMyMemory implements Tradutor {
  static final _endereco = Uri.https('api.mymemory.translated.net', '/get');

  /// A API recusa consulta com mais de 500 bytes.
  static const _maxCaracteres = 400;

  final http.Client _http;
  final int simultaneas;
  final Duration espera;
  final Map<String, String> _cache = {};

  TradutorMyMemory({http.Client? client, this.simultaneas = 3, this.espera = const Duration(seconds: 20)})
      : _http = client ?? http.Client();

  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir}) async {
    var feitas = 0;
    var proxima = 0;
    TraducaoFalhou? falha;
    Future<void> trabalhador() async {
      while (falha == null && proxima < frases.length) {
        final i = proxima++;
        try {
          _cache[frases[i]] ??= await _traduzirUma(frases[i]);
          aoProgredir?.call(++feitas, frases.length);
        } on TraducaoFalhou catch (e) {
          falha ??= e;
        }
      }
    }

    await Future.wait([for (var k = 0; k < simultaneas; k++) trabalhador()]);
    if (falha != null) throw falha!;
    return [for (final f in frases) _cache[f]!];
  }

  Future<String> _traduzirUma(String frase) async {
    final partes = [for (final p in _pedacos(frase)) await _consultar(p)];
    return partes.join(' ');
  }

  /// Frases enormes (sem onde quebrar) vão em pedaços de até [_maxCaracteres].
  static List<String> _pedacos(String s) {
    if (s.length <= _maxCaracteres) return [s];
    final r = <String>[];
    var atual = '';
    for (final palavra in s.split(' ')) {
      if (atual.isNotEmpty && atual.length + palavra.length + 1 > _maxCaracteres) {
        r.add(atual);
        atual = palavra;
      } else {
        atual = atual.isEmpty ? palavra : '$atual $palavra';
      }
    }
    if (atual.isNotEmpty) r.add(atual);
    return r;
  }

  Future<String> _consultar(String texto) async {
    for (var tentativa = 1;; tentativa++) {
      try {
        final r = await _http
            .get(_endereco.replace(queryParameters: {'q': texto, 'langpair': 'en|pt-BR'}))
            .timeout(espera);
        if (r.statusCode == 429) throw const TraducaoFalhou('O tradutor grátis chegou ao limite de hoje.', cota: true);
        if (r.statusCode != 200) {
          if (r.statusCode >= 500 && tentativa < 2) continue;
          throw TraducaoFalhou('O tradutor respondeu com erro (${r.statusCode}). Tente de novo daqui a pouco.');
        }
        return _lerResposta(utf8.decode(r.bodyBytes));
      } on TraducaoFalhou {
        rethrow;
      } on Exception {
        // sem rede, DNS, tempo esgotado: uma segunda chance antes de desistir
        if (tentativa < 2) {
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        throw const TraducaoFalhou('Não consegui falar com o tradutor. Confira a internet e tente de novo.');
      }
    }
  }

  static String _lerResposta(String corpo) {
    final Object? j;
    try {
      j = jsonDecode(corpo);
    } on FormatException {
      throw const TraducaoFalhou('O tradutor mandou uma resposta que não entendi. Tente de novo daqui a pouco.');
    }
    final dados = j is Map ? j['responseData'] : null;
    final texto = dados is Map ? dados['translatedText'] : null;
    final status = int.tryParse('${j is Map ? j['responseStatus'] : ''}');
    if (texto is String && texto.toUpperCase().contains('MYMEMORY WARNING')) {
      throw TraducaoFalhou(_avisoDeCota(texto), cota: true);
    }
    if (status == 429 || (j is Map && j['quotaFinished'] == true)) {
      throw const TraducaoFalhou('O tradutor grátis chegou ao limite de hoje.', cota: true);
    }
    if (status != 200 || texto is! String || texto.trim().isEmpty) {
      throw const TraducaoFalhou('O tradutor não devolveu a tradução de uma das frases. Tente de novo daqui a pouco.');
    }
    return _limpar(texto);
  }

  /// "…NEXT AVAILABLE IN 05 HOURS 54 MINUTES…" → "volta em ~5 h 54 min".
  static String _avisoDeCota(String aviso) {
    final m = RegExp(r'IN\s+(\d+)\s+HOURS?\s+(\d+)\s+MINUTES?', caseSensitive: false).firstMatch(aviso);
    if (m == null) return 'O tradutor grátis chegou ao limite de hoje. Tente de novo mais tarde.';
    final h = int.parse(m[1]!), min = int.parse(m[2]!);
    return 'O tradutor grátis chegou ao limite de hoje (volta em ${h > 0 ? '$h h ' : ''}$min min). '
        'O que já foi traduzido fica guardado: é só tentar de novo depois.';
  }

  /// A API às vezes devolve entidades HTML (&#39; &quot;) no meio do texto.
  static String _limpar(String s) => s
      .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)))
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
