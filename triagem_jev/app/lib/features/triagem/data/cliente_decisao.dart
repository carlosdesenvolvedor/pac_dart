import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/decisoes.dart';
import '../domain/estudo.dart';
import '../domain/portas.dart';
import 'falha_modelo.dart';

/// Jev (TypeSafe AI) pela Decisions API do OpenRouter, passando pelo Worker (a chave fica lá).
///
/// ⚠️ CONFIRMAR NA DOCUMENTAÇÃO OFICIAL antes da demonstração:
/// https://openrouter.ai/docs/guides/community/jev — o formato do pedido em [corpo] e a leitura em
/// [mapearResposta] foram escritos sem acesso à documentação (só o endpoint `/api/alpha/decisions`
/// e o id `typesafe/jev-1.13` foram vistos em fontes públicas). Os dois métodos são estáticos e
/// testados à parte, para ajustar sem mexer no resto.
///
/// Serve também para a OpenAI Decisions API (cenário 3): mesmo formato, outro [modelo] e [rota].
class ClienteDecisaoOpenRouter implements IDecisionModelClient {
  final Uri worker;
  final http.Client _http;

  /// `Authorization: Bearer …` quando o Worker tem TOKEN_ACESSO (vazio = não manda).
  final String tokenAcesso;
  @override
  final String modelo;

  /// Rota do Worker: `/jev` (OpenRouter) ou `/openai-decisions`.
  final String rota;

  ClienteDecisaoOpenRouter({
    required this.worker,
    this.modelo = 'typesafe/jev-1.13',
    this.rota = '/jev',
    http.Client? cliente,
    this.tokenAcesso = '',
  }) : _http = cliente ?? http.Client();

  @override
  Map<String, dynamic> get parametros => {
    'endpoint': rota,
    'perguntas': ['condicao', 'escolha', 'nota_1_7'],
  };

  static const perguntaCondicao = 'Este estudo atende a todos os critérios de inclusão?';
  static const perguntaEscolha = 'Qual deve ser a decisão de triagem para este estudo?';
  static const perguntaNota =
      'Numa escala de 1 a 7, o quanto este estudo deve ser incluído? '
      '1 = certamente deve ser excluído, 7 = certamente deve ser incluído.';

  /// O pedido: estado (critérios + estudo, nada de irrelevante) e as três perguntas numa chamada só.
  static Map<String, dynamic> corpo(String modelo, Estudo estudo, List<Criterio> criterios, List<Decisao> ordem) => {
    'model': modelo,
    'state':
        'Critérios de inclusão:\n${[for (final c in criterios) '${c.id}: ${c.texto}'].join('\n')}\n\n'
        'Estudo:\n${estudo.estadoTexto}',
    'decisions': [
      {'name': 'condicao', 'type': 'condition', 'question': perguntaCondicao},
      {
        'name': 'escolha',
        'type': 'choice',
        'question': perguntaEscolha,
        'options': [for (final o in ordem) o.name],
      },
      {
        'name': 'nota',
        'type': 'score',
        'question': perguntaNota,
        'scale': [for (var n = 1; n <= 7; n++) '$n'],
      },
    ],
  };

  @override
  Future<Resposta<DecisaoModelo>> decidir(Estudo estudo, List<Criterio> criterios, {List<Decisao>? ordemOpcoes}) async {
    final ordem = ordemOpcoes ?? const [Decisao.incluir, Decisao.excluir, Decisao.incerto];
    final relogio = Stopwatch()..start();
    final resp = await _http.post(
      worker.resolve(rota),
      headers: {'content-type': 'application/json', if (tokenAcesso.isNotEmpty) 'authorization': 'Bearer $tokenAcesso'},
      body: jsonEncode(corpo(modelo, estudo, criterios, ordem)),
    );
    relogio.stop();
    if (resp.statusCode != 200) throw FalhaModelo.http(resp.statusCode, resp.body);
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return Resposta(mapearResposta(json, estudo.id, modelo, ordem, relogio.elapsedMilliseconds), resp.body);
  }

  /// Lê a resposta de forma tolerante (lista ou mapa de decisões; nomes de campo alternativos).
  /// AJUSTAR aos nomes reais da documentação.
  static DecisaoModelo mapearResposta(
    Map<String, dynamic> j,
    String estudoId,
    String modelo,
    List<Decisao> ordem,
    int ms,
  ) {
    final porNome = <String, Map<String, dynamic>>{};
    final lista = j['decisions'] ?? j['results'] ?? j['outputs'];
    if (lista is List) {
      for (final (i, item) in lista.indexed) {
        final m = item as Map<String, dynamic>;
        porNome['${m['name'] ?? ['condicao', 'escolha', 'nota'][i]}'] = m;
      }
    } else if (lista is Map) {
      for (final MapEntry(:key, :value) in lista.entries) {
        porNome['$key'] = value as Map<String, dynamic>;
      }
    }
    final cond = porNome['condicao'];
    final esc = porNome['escolha'];
    final nota = porNome['nota'];
    if (cond == null || esc == null) throw FalhaModelo('Resposta sem as decisões esperadas: ${jsonEncode(j)}');

    final probCond = _num(cond['probability'] ?? cond['p_true'] ?? cond['probabilities']?['true'] ?? cond['value']);

    final probEscolha = <Decisao, double>{};
    final pe = esc['probabilities'] ?? esc['distribution'];
    if (pe is Map) {
      for (final MapEntry(:key, :value) in pe.entries) {
        final d = Decisao.deTexto('$key');
        if (d != null) probEscolha[d] = _num(value);
      }
    } else if (pe is List && pe.length == ordem.length) {
      for (var i = 0; i < ordem.length; i++) {
        probEscolha[ordem[i]] = _num(pe[i] is Map ? (pe[i] as Map)['probability'] : pe[i]);
      }
    }
    final escolha =
        Decisao.deTexto('${esc['choice'] ?? esc['answer'] ?? esc['value']}') ??
        (probEscolha.isEmpty ? Decisao.incerto : probEscolha.entries.reduce((a, b) => a.value >= b.value ? a : b).key);

    var dist = <double>[];
    final pn = nota?['distribution'] ?? nota?['probabilities'];
    if (pn is List) {
      dist = [for (final v in pn) _num(v is Map ? v['probability'] : v)];
    } else if (pn is Map) {
      dist = [for (var n = 1; n <= 7; n++) _num(pn['$n'] ?? 0)];
    }

    final usage = (j['usage'] as Map?) ?? const {};
    return DecisaoModelo(
      estudoId: estudoId,
      modelo: modelo,
      probCondicao: probCond,
      escolha: escolha,
      probEscolha: probEscolha,
      confianca: _num(esc['confidence'] ?? probEscolha[escolha] ?? 0),
      distribuicaoNota: dist,
      ordemOpcoes: ordem,
      uso: Uso(
        tokensEntrada: (usage['prompt_tokens'] ?? usage['input_tokens'] ?? 0) as int,
        tokensSaida: (usage['completion_tokens'] ?? usage['output_tokens'] ?? 0) as int,
        ms: ms,
        medido: true,
      ),
    );
  }

  static double _num(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}
