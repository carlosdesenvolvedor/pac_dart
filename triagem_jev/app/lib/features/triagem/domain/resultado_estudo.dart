import 'package:equatable/equatable.dart';

import 'config_triagem.dart';
import 'decisoes.dart';
import 'estudo.dart';

/// A faixa em que a etapa 1 colocou o estudo (regra de encaminhamento da seção 5 do plano).
enum Faixa {
  incluido,
  incerto,
  excluido;

  static Faixa de(double probInclusao, ConfigTriagem c) {
    if (probInclusao >= c.limiteIncluir) return Faixa.incluido;
    if (probInclusao < c.limiteExcluir) return Faixa.excluido;
    return Faixa.incerto;
  }

  /// Só os excluídos com segurança ficam de fora do LLM.
  bool get vaiParaLlm => this != Faixa.excluido;

  String get rotulo => switch (this) {
    Faixa.incluido => 'incluído',
    Faixa.incerto => 'incerto',
    Faixa.excluido => 'excluído',
  };

  Decisao get comoDecisao => switch (this) {
    Faixa.incluido => Decisao.incluir,
    Faixa.incerto => Decisao.incerto,
    Faixa.excluido => Decisao.excluir,
  };
}

/// Uma linha da tabela: tudo o que aconteceu com um estudo.
class ResultadoEstudo extends Equatable {
  final Estudo estudo;
  final DecisaoModelo? decisao;

  /// A mesma decisão com a ordem das opções invertida (só no teste de estabilidade).
  final DecisaoModelo? decisaoInvertida;
  final JustificativaLlm? justificativa;
  final DecisaoHumana? humana;

  /// Erro de alguma etapa. Estudo com erro na etapa 1 vira "incerto" (vai para o humano).
  final String? erro;

  /// Faixa calculada na etapa 1 (null = ainda não rodou).
  final Faixa? faixa;

  const ResultadoEstudo(
    this.estudo, {
    this.decisao,
    this.decisaoInvertida,
    this.justificativa,
    this.humana,
    this.erro,
    this.faixa,
  });

  ResultadoEstudo copyWith({
    DecisaoModelo? decisao,
    DecisaoModelo? decisaoInvertida,
    JustificativaLlm? justificativa,
    DecisaoHumana? humana,
    String? erro,
    Faixa? faixa,
    bool limparHumana = false,
  }) => ResultadoEstudo(
    estudo,
    decisao: decisao ?? this.decisao,
    decisaoInvertida: decisaoInvertida ?? this.decisaoInvertida,
    justificativa: justificativa ?? this.justificativa,
    humana: limparHumana ? null : humana ?? this.humana,
    erro: erro ?? this.erro,
    faixa: faixa ?? this.faixa,
  );

  /// O que o sistema sugere ao pesquisador: a do LLM se ele foi chamado, senão a faixa da etapa 1.
  Decisao? get decisaoSistema => justificativa?.decisaoSugerida ?? faixa?.comoDecisao;

  /// A decisão que vale: a do pesquisador; enquanto ele não decidiu, a do sistema.
  Decisao? get decisaoFinal => humana?.decisao ?? decisaoSistema;

  /// A escolha mudou quando a ordem das opções foi invertida? (null = teste não rodou)
  bool? get estavel =>
      decisao == null || decisaoInvertida == null ? null : decisao!.escolha == decisaoInvertida!.escolha;

  double get custo => (decisao?.custo ?? 0) + (decisaoInvertida?.custo ?? 0) + (justificativa?.custo ?? 0);

  Map<String, dynamic> toJson() => {
    'estudo': estudo.toJson(),
    'faixa': faixa?.name,
    'decisao_modelo': decisao?.toJson(),
    if (decisaoInvertida != null) 'decisao_modelo_ordem_invertida': decisaoInvertida!.toJson(),
    if (estavel != null) 'estavel': estavel,
    'justificativa_llm': justificativa?.toJson(),
    'decisao_humana': humana?.toJson(),
    'decisao_sistema': decisaoSistema?.name,
    'decisao_final': decisaoFinal?.name,
    if (erro != null) 'erro': erro,
  };

  @override
  List<Object?> get props => [estudo, decisao, decisaoInvertida, justificativa, humana, erro, faixa];
}
