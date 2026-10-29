import 'package:equatable/equatable.dart';

import 'config_triagem.dart';
import 'decisoes.dart';
import 'estudo.dart';
import 'prompt_llm.dart';
import 'resultado_estudo.dart';

/// Custo = tokens × preço da tabela.
class CalculadoraCusto {
  final TabelaPrecos precos;
  const CalculadoraCusto(this.precos);

  double de(String modelo, Uso uso) => precos.de(modelo).custo(uso.tokensEntrada, uso.tokensSaida);
}

/// Um dos três cenários da seção 8 do plano, para UMA rodada sobre o conjunto atual.
class Cenario extends Equatable {
  final String nome;
  final double custo;
  final int ms;

  /// Chamadas ao LLM neste cenário.
  final int chamadasLlm;

  /// true = números vindos de chamadas reais; false = estimados (a tela diz qual é qual).
  final bool medido;
  final String observacao;

  /// Estudos do conjunto (para projetar por estudo).
  final int estudos;

  const Cenario({
    required this.nome,
    required this.custo,
    required this.ms,
    required this.chamadasLlm,
    required this.medido,
    required this.estudos,
    this.observacao = '',
  });

  /// Quanto custaria para [n] estudos e [rodadas] rodadas, mantendo a proporção deste conjunto.
  double projecao(int n, {int rodadas = 1}) => estudos == 0 ? 0 : custo / estudos * n * rodadas;

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'custo_usd': custo,
    'ms': ms,
    'chamadas_llm': chamadasLlm,
    'medido': medido,
    'observacao': observacao,
    'projecao_usd': {
      for (final n in ComparacaoCenarios.tamanhosProjecao)
        for (final r in ComparacaoCenarios.rodadasProjecao) '${n}_estudos_${r}_rodadas': projecao(n, rodadas: r),
    },
  };

  @override
  List<Object?> get props => [nome, custo, ms, chamadasLlm, medido, observacao, estudos];
}

/// Jev + LLM (o que rodou), só LLM e Decisions API + LLM — os dois últimos estimados a partir do
/// que foi medido, a menos que tenham sido rodados de verdade.
class ComparacaoCenarios {
  static const tamanhosProjecao = [1000, 5000];
  static const rodadasProjecao = [1, 6];

  final List<Cenario> cenarios;
  const ComparacaoCenarios(this.cenarios);

  factory ComparacaoCenarios.de(List<ResultadoEstudo> resultados, List<Criterio> criterios, ConfigTriagem config) {
    final calc = CalculadoraCusto(config.precos);
    final n = resultados.length;
    final decisoes = [for (final r in resultados) ?r.decisao];
    final justs = [for (final r in resultados) ?r.justificativa];

    final usoDecisao = decisoes.fold(const Uso(medido: true), (a, d) => a + d.uso);
    final custoDecisao = decisoes.fold<double>(0, (a, d) => a + d.custo);
    final usoLlm = justs.fold(const Uso(medido: true), (a, j) => a + j.uso);
    final custoLlm = justs.fold<double>(0, (a, j) => a + j.custo);

    // Custo e tempo médios de UMA chamada ao LLM: do que foi medido, ou estimado pelo prompt.
    final double custoLlmPorEstudo;
    final double msLlmPorEstudo;
    if (justs.isNotEmpty) {
      custoLlmPorEstudo = custoLlm / justs.length;
      msLlmPorEstudo = usoLlm.ms / justs.length;
    } else {
      final tokens = [for (final r in resultados) PromptLlm.tokensEntradaEstimados(r.estudo, criterios)];
      final media = tokens.isEmpty ? 0.0 : tokens.reduce((a, b) => a + b) / tokens.length;
      custoLlmPorEstudo = config.precos.de(config.modeloLlm).custo(media.round(), PromptLlm.tokensSaidaTipicos);
      msLlmPorEstudo = 1500;
    }

    // Decisions API: mesmos tokens de entrada que o modelo de decisão consumiu, outro preço.
    final usoAlt = Uso(tokensEntrada: usoDecisao.tokensEntrada, tokensSaida: usoDecisao.tokensSaida);
    final custoAlt = calc.de(config.modeloDecisaoAlternativo, usoAlt);

    return ComparacaoCenarios([
      Cenario(
        nome: 'Decisão (${config.modeloDecisao}) + LLM',
        custo: custoDecisao + custoLlm,
        ms: usoDecisao.ms + usoLlm.ms,
        chamadasLlm: justs.length,
        medido: decisoes.isNotEmpty && usoDecisao.medido && usoLlm.medido,
        estudos: n,
        observacao: 'LLM só nos incluídos e incertos.',
      ),
      Cenario(
        nome: 'Só LLM (${config.modeloLlm})',
        custo: custoLlmPorEstudo * n,
        ms: (msLlmPorEstudo * n).round(),
        chamadasLlm: n,
        medido: false,
        estudos: n,
        observacao: justs.isEmpty
            ? 'Estimado pelo tamanho do prompt (≈ 4 caracteres/token).'
            : 'Estimado: média por chamada medida × todos os estudos.',
      ),
      Cenario(
        nome: 'Decisions API (${config.modeloDecisaoAlternativo}) + LLM',
        custo: custoAlt + custoLlm,
        ms: usoDecisao.ms + usoLlm.ms,
        chamadasLlm: justs.length,
        medido: false,
        estudos: n,
        observacao: 'Estimado: mesmos tokens e mesmo encaminhamento, preço da Decisions API.',
      ),
    ]);
  }

  List<Map<String, dynamic>> toJson() => [for (final c in cenarios) c.toJson()];
}
