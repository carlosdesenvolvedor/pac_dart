import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/decisoes.dart';
import '../domain/estudo.dart';
import '../domain/portas.dart';
import '../domain/prompt_llm.dart';
import 'falha_modelo.dart';

/// LLM da etapa 2 pelo OpenRouter (formato chat/completions), via Worker. Qualquer modelo do
/// OpenRouter serve (Claude, GPT, Llama…) — basta trocar [modelo] e o preço na tabela.
class ClienteLlmOpenRouter implements ILlmClient {
  final Uri worker;
  final http.Client _http;

  /// `Authorization: Bearer …` quando o Worker tem TOKEN_ACESSO (vazio = não manda).
  final String tokenAcesso;
  @override
  final String modelo;

  ClienteLlmOpenRouter({required this.worker, required this.modelo, http.Client? cliente, this.tokenAcesso = ''})
    : _http = cliente ?? http.Client();

  /// Temperatura e top-p em zero (boa prática do grupo) — exceto nos Claude atuais, que recusam
  /// parâmetros de amostragem com erro 400; neles a resposta já é pedida em JSON fixo.
  @override
  Map<String, dynamic> get parametros => {
    if (!modelo.startsWith('anthropic/')) ...{'temperature': 0, 'top_p': 0},
    'max_tokens': 300,
  };

  @override
  Future<Resposta<JustificativaLlm>> justificar(Estudo estudo, List<Criterio> criterios) async {
    final relogio = Stopwatch()..start();
    final resp = await _http.post(
      worker.resolve('/llm'),
      headers: {'content-type': 'application/json', if (tokenAcesso.isNotEmpty) 'authorization': 'Bearer $tokenAcesso'},
      body: jsonEncode({
        'model': modelo,
        ...parametros,
        'messages': [
          {'role': 'system', 'content': PromptLlm.sistema},
          {'role': 'user', 'content': PromptLlm.usuario(estudo, criterios)},
        ],
      }),
    );
    relogio.stop();
    if (resp.statusCode != 200) throw FalhaModelo.http(resp.statusCode, resp.body);
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return Resposta(mapearResposta(json, estudo.id, modelo, relogio.elapsedMilliseconds), resp.body);
  }

  static JustificativaLlm mapearResposta(Map<String, dynamic> j, String estudoId, String modelo, int ms) {
    final texto = '${(j['choices'] as List).first['message']['content']}';
    final saida = PromptLlm.lerJson(texto);
    final usage = (j['usage'] as Map?) ?? const {};
    return JustificativaLlm(
      estudoId: estudoId,
      modelo: modelo,
      decisaoSugerida: Decisao.deTexto(saida['decisao_sugerida'] as String?) ?? Decisao.incerto,
      criteriosAtendidos: [for (final c in (saida['criterios_atendidos'] as List? ?? const [])) '$c'],
      justificativa: '${saida['justificativa'] ?? ''}',
      uso: Uso(
        tokensEntrada: (usage['prompt_tokens'] ?? 0) as int,
        tokensSaida: (usage['completion_tokens'] ?? 0) as int,
        ms: ms,
        medido: true,
      ),
    );
  }
}
