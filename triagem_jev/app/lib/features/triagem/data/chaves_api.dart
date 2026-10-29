/// Chaves de API digitadas no painel. Vivem só na memória da aba (somem ao recarregar), vão ao
/// Worker em cabeçalhos próprios e têm prioridade sobre as do `.dev.vars`. Nunca entram no log,
/// no JSON/CSV exportado nem no estado do Cubit — e o [toString] não as mostra.
class ChavesApi {
  final String anthropic;
  final String openai;

  const ChavesApi({this.anthropic = '', this.openai = ''});

  /// Cabeçalhos que o Worker lê (`x-chave-<empresa>`); só os das chaves informadas.
  Map<String, String> get cabecalhos => {
    if (anthropic.isNotEmpty) 'x-chave-anthropic': anthropic,
    if (openai.isNotEmpty) 'x-chave-openai': openai,
  };

  /// Nomes das empresas com chave informada, para a tela.
  List<String> get informadas => [if (anthropic.isNotEmpty) 'Anthropic', if (openai.isNotEmpty) 'OpenAI'];

  /// Junta com [novas]: campo vazio em [novas] mantém a chave atual.
  ChavesApi mais(ChavesApi novas) => ChavesApi(
    anthropic: novas.anthropic.isNotEmpty ? novas.anthropic : anthropic,
    openai: novas.openai.isNotEmpty ? novas.openai : openai,
  );

  @override
  String toString() => 'ChavesApi(${informadas.isEmpty ? 'nenhuma' : informadas.join(', ')})';
}
