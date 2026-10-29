import 'package:equatable/equatable.dart';

/// Preço de um modelo em US$ por 1 milhão de tokens.
class Preco extends Equatable {
  final double entrada;
  final double saida;
  const Preco(this.entrada, this.saida);

  double custo(int tokensEntrada, int tokensSaida) => (tokensEntrada * entrada + tokensSaida * saida) / 1e6;

  @override
  List<Object?> get props => [entrada, saida];
}

/// Tabela de preços configurável (assets/precos.json). Os valores são A CONFIRMAR nas páginas
/// oficiais no dia da demonstração.
class TabelaPrecos extends Equatable {
  final Map<String, Preco> porModelo;

  /// Data em que os preços foram conferidos (vai junto no relatório).
  final String conferidoEm;
  const TabelaPrecos(this.porModelo, {this.conferidoEm = ''});

  factory TabelaPrecos.fromJson(Map<String, dynamic> j) => TabelaPrecos({
    for (final MapEntry(:key, :value) in (j['modelos'] as Map<String, dynamic>).entries)
      key: Preco((value['entrada'] as num).toDouble(), (value['saida'] as num).toDouble()),
  }, conferidoEm: '${j['conferido_em'] ?? ''}');

  Map<String, dynamic> toJson() => {
    'conferido_em': conferidoEm,
    'modelos': {
      for (final MapEntry(:key, :value) in porModelo.entries) key: {'entrada': value.entrada, 'saida': value.saida},
    },
  };

  /// Preço do modelo; um modelo fora da tabela custa zero (e a tela avisa).
  Preco de(String modelo) => porModelo[modelo] ?? const Preco(0, 0);
  bool conhece(String modelo) => porModelo.containsKey(modelo);

  @override
  List<Object?> get props => [porModelo, conferidoEm];
}

/// Tudo o que define uma rodada — salvo junto com o resultado para dar para refazer.
class ConfigTriagem extends Equatable {
  /// Probabilidade de inclusão a partir da qual o estudo é "incluído".
  final double limiteIncluir;

  /// Abaixo disto é "excluído" (e não vai para o LLM). Entre os dois, "incerto".
  final double limiteExcluir;

  /// Modelo de decisão da etapa 1 (id no OpenRouter).
  final String modeloDecisao;

  /// LLM da etapa 2 (id no OpenRouter).
  final String modeloLlm;

  /// Modelo de decisão usado no cenário 3 (só estimado se não houver acesso).
  final String modeloDecisaoAlternativo;

  /// Roda cada estudo de novo com a ordem das opções invertida e registra se a decisão mudou.
  final bool testeEstabilidade;

  final TabelaPrecos precos;

  const ConfigTriagem({
    this.limiteIncluir = 0.80,
    this.limiteExcluir = 0.30,
    this.modeloDecisao = 'typesafe/jev-1.14',
    this.modeloLlm = 'anthropic/claude-haiku-5.5',
    this.modeloDecisaoAlternativo = 'openai/decisions-gpt-6-luna',
    this.testeEstabilidade = false,
    this.precos = const TabelaPrecos({}),
  }) : assert(limiteExcluir <= limiteIncluir);

  ConfigTriagem copyWith({
    double? limiteIncluir,
    double? limiteExcluir,
    String? modeloDecisao,
    String? modeloLlm,
    bool? testeEstabilidade,
    TabelaPrecos? precos,
  }) => ConfigTriagem(
    limiteIncluir: limiteIncluir ?? this.limiteIncluir,
    limiteExcluir: limiteExcluir ?? this.limiteExcluir,
    modeloDecisao: modeloDecisao ?? this.modeloDecisao,
    modeloLlm: modeloLlm ?? this.modeloLlm,
    modeloDecisaoAlternativo: modeloDecisaoAlternativo,
    testeEstabilidade: testeEstabilidade ?? this.testeEstabilidade,
    precos: precos ?? this.precos,
  );

  Map<String, dynamic> toJson() => {
    'limite_incluir': limiteIncluir,
    'limite_excluir': limiteExcluir,
    'modelo_decisao': modeloDecisao,
    'modelo_llm': modeloLlm,
    'modelo_decisao_alternativo': modeloDecisaoAlternativo,
    'teste_estabilidade': testeEstabilidade,
    'precos': precos.toJson(),
  };

  @override
  List<Object?> get props => [
    limiteIncluir,
    limiteExcluir,
    modeloDecisao,
    modeloLlm,
    modeloDecisaoAlternativo,
    testeEstabilidade,
    precos,
  ];
}
