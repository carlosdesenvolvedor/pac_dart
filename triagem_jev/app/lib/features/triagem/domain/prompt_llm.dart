import 'dart:convert';

import 'estudo.dart';

/// O prompt da etapa 2, seguindo as boas práticas do grupo de pesquisa: um estudo por chamada,
/// critérios na forma positiva, "não encontrei informação suficiente" em vez de inventar.
/// Fica no domínio porque o cenário "só LLM" estima tokens com ele.
abstract final class PromptLlm {
  static const sistema =
      'Você é um revisor auxiliar numa revisão sistemática de Engenharia de Software. '
      'Avalie UM estudo contra os critérios de inclusão usando só o título, o resumo e as palavras-chave dados. '
      'Se faltar informação para decidir, diga "não encontrei informação suficiente" na justificativa e use '
      '"incerto". Não invente dados que não estão no texto. '
      'Responda SOMENTE com um JSON no formato: '
      '{"decisao_sugerida": "incluir | excluir | incerto", "criterios_atendidos": ["C1"], '
      '"justificativa": "até 2 frases"}';

  static String usuario(Estudo estudo, List<Criterio> criterios) =>
      'Critérios de inclusão:\n'
      '${[for (final c in criterios) '${c.id}: ${c.texto}'].join('\n')}\n\n'
      'Estudo:\n${estudo.estadoTexto}';

  /// Tamanho típico da resposta pedida (≈ 2 frases + JSON), para estimativas.
  static const tokensSaidaTipicos = 90;

  /// Estimativa grosseira de tokens (≈ 4 caracteres por token). Só para o que é ESTIMADO.
  static int estimarTokens(String texto) => (texto.length / 4).ceil();

  static int tokensEntradaEstimados(Estudo estudo, List<Criterio> criterios) =>
      estimarTokens(sistema) + estimarTokens(usuario(estudo, criterios));

  /// Lê o JSON da resposta, tolerando texto ou cercas ``` em volta.
  static Map<String, dynamic> lerJson(String resposta) {
    final ini = resposta.indexOf('{');
    final fim = resposta.lastIndexOf('}');
    if (ini < 0 || fim <= ini) throw FormatException('Resposta do LLM sem JSON: $resposta');
    return jsonDecode(resposta.substring(ini, fim + 1)) as Map<String, dynamic>;
  }
}
