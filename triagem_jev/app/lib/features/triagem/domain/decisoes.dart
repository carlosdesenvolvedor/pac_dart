import 'package:equatable/equatable.dart';

import 'estudo.dart';

/// Uso de uma chamada: tokens, tempo e se os números foram MEDIDOS (chamada real) ou ESTIMADOS
/// (cliente simulado / contagem aproximada). A tela sempre mostra essa diferença.
class Uso extends Equatable {
  final int tokensEntrada;
  final int tokensSaida;
  final int ms;
  final bool medido;
  const Uso({this.tokensEntrada = 0, this.tokensSaida = 0, this.ms = 0, this.medido = false});

  Uso operator +(Uso o) => Uso(
    tokensEntrada: tokensEntrada + o.tokensEntrada,
    tokensSaida: tokensSaida + o.tokensSaida,
    ms: ms + o.ms,
    medido: medido && o.medido,
  );

  Map<String, dynamic> toJson() => {
    'tokens_entrada': tokensEntrada,
    'tokens_saida': tokensSaida,
    'ms': ms,
    'medido': medido,
  };

  @override
  List<Object?> get props => [tokensEntrada, tokensSaida, ms, medido];
}

/// O que o modelo de decisão devolve para UM estudo: as três perguntas da seção 5 do plano.
class DecisaoModelo extends Equatable {
  final String estudoId;
  final String modelo;

  /// Condição: "atende a todos os critérios?" → probabilidade de ser verdade.
  final double probCondicao;

  /// Escolha entre incluir / excluir / incerto.
  final Decisao escolha;
  final Map<Decisao, double> probEscolha;
  final double confianca;

  /// Nota 1..7: distribuição (índice 0 = nota 1). Pode vir vazia se o modelo não respondeu.
  final List<double> distribuicaoNota;

  /// Ordem em que as opções da escolha foram enviadas (para o teste de estabilidade).
  final List<Decisao> ordemOpcoes;

  final Uso uso;
  final double custo;

  const DecisaoModelo({
    required this.estudoId,
    required this.modelo,
    required this.probCondicao,
    required this.escolha,
    this.probEscolha = const {},
    this.confianca = 0,
    this.distribuicaoNota = const [],
    this.ordemOpcoes = const [Decisao.incluir, Decisao.excluir, Decisao.incerto],
    this.uso = const Uso(),
    this.custo = 0,
  });

  /// Nota esperada (1..7) a partir da distribuição; null se não houver.
  double? get notaEsperada {
    if (distribuicaoNota.isEmpty) return null;
    final soma = distribuicaoNota.fold<double>(0, (a, b) => a + b);
    if (soma == 0) return null;
    var e = 0.0;
    for (var i = 0; i < distribuicaoNota.length; i++) {
      e += (i + 1) * distribuicaoNota[i];
    }
    return e / soma;
  }

  /// A probabilidade de inclusão que a regra de encaminhamento usa: a da pergunta de condição.
  double get probInclusao => probCondicao;

  DecisaoModelo comCusto(double c) => DecisaoModelo(
    estudoId: estudoId,
    modelo: modelo,
    probCondicao: probCondicao,
    escolha: escolha,
    probEscolha: probEscolha,
    confianca: confianca,
    distribuicaoNota: distribuicaoNota,
    ordemOpcoes: ordemOpcoes,
    uso: uso,
    custo: c,
  );

  Map<String, dynamic> toJson() => {
    'estudo_id': estudoId,
    'modelo': modelo,
    'prob_condicao': probCondicao,
    'escolha': escolha.name,
    'prob_escolha': {for (final MapEntry(:key, :value) in probEscolha.entries) key.name: value},
    'confianca': confianca,
    'distribuicao_nota': distribuicaoNota,
    'nota_esperada': notaEsperada,
    'ordem_opcoes': [for (final o in ordemOpcoes) o.name],
    'uso': uso.toJson(),
    'custo_usd': custo,
  };

  @override
  List<Object?> get props => [
    estudoId,
    modelo,
    probCondicao,
    escolha,
    probEscolha,
    confianca,
    distribuicaoNota,
    ordemOpcoes,
    uso,
    custo,
  ];
}

/// Saída do LLM da etapa 2 (JSON pedido na seção 6 do plano).
class JustificativaLlm extends Equatable {
  final String estudoId;
  final String modelo;
  final Decisao decisaoSugerida;
  final List<String> criteriosAtendidos;
  final String justificativa;
  final Uso uso;
  final double custo;

  const JustificativaLlm({
    required this.estudoId,
    required this.modelo,
    required this.decisaoSugerida,
    this.criteriosAtendidos = const [],
    this.justificativa = '',
    this.uso = const Uso(),
    this.custo = 0,
  });

  JustificativaLlm comCusto(double c) => JustificativaLlm(
    estudoId: estudoId,
    modelo: modelo,
    decisaoSugerida: decisaoSugerida,
    criteriosAtendidos: criteriosAtendidos,
    justificativa: justificativa,
    uso: uso,
    custo: c,
  );

  Map<String, dynamic> toJson() => {
    'estudo_id': estudoId,
    'modelo': modelo,
    'decisao_sugerida': decisaoSugerida.name,
    'criterios_atendidos': criteriosAtendidos,
    'justificativa': justificativa,
    'uso': uso.toJson(),
    'custo_usd': custo,
  };

  @override
  List<Object?> get props => [estudoId, modelo, decisaoSugerida, criteriosAtendidos, justificativa, uso, custo];
}

/// A palavra final do pesquisador.
class DecisaoHumana extends Equatable {
  final Decisao decisao;
  final String observacao;
  const DecisaoHumana(this.decisao, [this.observacao = '']);

  Map<String, dynamic> toJson() => {'decisao': decisao.name, 'observacao': observacao};

  @override
  List<Object?> get props => [decisao, observacao];
}

/// Uma chamada a modelo, como foi feita — o log de reprodutibilidade (seção 10 do plano).
class RegistroChamada extends Equatable {
  final DateTime quando;
  final String etapa;
  final String estudoId;
  final String modelo;
  final Map<String, dynamic> parametros;
  final String entradaResumida;
  final String saida;
  final Uso uso;
  final double custo;
  final String? erro;

  const RegistroChamada({
    required this.quando,
    required this.etapa,
    required this.estudoId,
    required this.modelo,
    this.parametros = const {},
    this.entradaResumida = '',
    this.saida = '',
    this.uso = const Uso(),
    this.custo = 0,
    this.erro,
  });

  Map<String, dynamic> toJson() => {
    'quando': quando.toUtc().toIso8601String(),
    'etapa': etapa,
    'estudo_id': estudoId,
    'modelo': modelo,
    'parametros': parametros,
    'entrada_resumida': entradaResumida,
    'saida': saida,
    'uso': uso.toJson(),
    'custo_usd': custo,
    if (erro != null) 'erro': erro,
  };

  @override
  List<Object?> get props => [quando, etapa, estudoId, modelo, parametros, entradaResumida, saida, uso, custo, erro];
}
