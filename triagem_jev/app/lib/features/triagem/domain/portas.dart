import 'decisoes.dart';
import 'estudo.dart';

/// A resposta de um cliente: o valor já tipado e o texto bruto (vai para o log).
class Resposta<T> {
  final T valor;
  final String bruto;
  const Resposta(this.valor, [this.bruto = '']);
}

/// Modelo de decisão (Jev, OpenAI Decisions, simulado…). Ficar atrás desta interface é o que deixa a
/// pesquisa trocar e comparar modelos sem mexer no resto.
abstract interface class IDecisionModelClient {
  /// Id do modelo (o mesmo usado na tabela de preços).
  String get modelo;

  /// Parâmetros que vão para o log (versão, temperatura…).
  Map<String, dynamic> get parametros;

  /// Uma chamada por estudo, com as três perguntas (condição, escolha, nota). [ordemOpcoes] é a
  /// ordem das opções da escolha — o teste de estabilidade inverte. O custo vem zerado: quem
  /// calcula é a [CalculadoraCusto].
  Future<Resposta<DecisaoModelo>> decidir(Estudo estudo, List<Criterio> criterios, {List<Decisao>? ordemOpcoes});
}

/// LLM da etapa 2: só gera a justificativa curta (e uma decisão sugerida).
abstract interface class ILlmClient {
  String get modelo;
  Map<String, dynamic> get parametros;

  Future<Resposta<JustificativaLlm>> justificar(Estudo estudo, List<Criterio> criterios);
}
