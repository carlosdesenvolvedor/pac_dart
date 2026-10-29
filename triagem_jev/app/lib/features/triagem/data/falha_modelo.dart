/// Falha ao chamar um modelo (HTTP, formato inesperado…). A mensagem vai para a coluna de erro.
class FalhaModelo implements Exception {
  final String mensagem;
  const FalhaModelo(this.mensagem);

  factory FalhaModelo.http(int status, String corpo) {
    final curto = corpo.length > 300 ? '${corpo.substring(0, 300)}…' : corpo;
    return FalhaModelo(switch (status) {
      401 || 403 => 'Chave recusada ($status). Confira o segredo OPENROUTER_API_KEY do Worker.',
      402 => 'Sem crédito no OpenRouter (402).',
      429 => 'Limite de requisições (429). Espere um pouco e rode de novo.',
      _ => 'HTTP $status: $curto',
    });
  }

  @override
  String toString() => mensagem;
}
