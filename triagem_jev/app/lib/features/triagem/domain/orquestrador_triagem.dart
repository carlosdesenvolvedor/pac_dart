import 'dart:convert';

import 'config_triagem.dart';
import 'custo.dart';
import 'decisoes.dart';
import 'estudo.dart';
import 'metricas.dart';
import 'portas.dart';
import 'resultado_estudo.dart';

/// O resultado completo de uma rodada — o que se exporta e o que se refaz.
class RodadaTriagem {
  final ProjetoTriagem projeto;
  final ConfigTriagem config;
  final List<ResultadoEstudo> resultados;
  final List<RegistroChamada> registros;
  final DateTime inicio;
  final DateTime? fim;

  const RodadaTriagem({
    required this.projeto,
    required this.config,
    required this.resultados,
    this.registros = const [],
    required this.inicio,
    this.fim,
  });

  RodadaTriagem copyWith({List<ResultadoEstudo>? resultados, List<RegistroChamada>? registros, DateTime? fim}) =>
      RodadaTriagem(
        projeto: projeto,
        config: config,
        resultados: resultados ?? this.resultados,
        registros: registros ?? this.registros,
        inicio: inicio,
        fim: fim ?? this.fim,
      );

  /// Etapa 1 sozinha (incerto conta como "segue").
  Metricas get metricasEtapa1 => Metricas.de(resultados, (r) => r.faixa?.comoDecisao);

  /// O que o sistema sugere (LLM quando chamado, senão etapa 1).
  Metricas get metricasSistema => Metricas.de(resultados, (r) => r.decisaoSistema);

  /// Depois da revisão humana.
  Metricas get metricasFinal => Metricas.de(resultados, (r) => r.decisaoFinal);

  ComparacaoCenarios get cenarios => ComparacaoCenarios.de(resultados, projeto.criterios, config);

  Map<String, dynamic> toJson() => {
    'gerado_em': DateTime.now().toUtc().toIso8601String(),
    'inicio': inicio.toUtc().toIso8601String(),
    'fim': fim?.toUtc().toIso8601String(),
    'projeto': projeto.nome,
    'criterios': [for (final c in projeto.criterios) c.toJson()],
    'config': config.toJson(),
    'metricas': {
      'etapa1': metricasEtapa1.toJson(),
      'sistema': metricasSistema.toJson(),
      'final': metricasFinal.toJson(),
    },
    'cenarios': cenarios.toJson(),
    'resultados': [for (final r in resultados) r.toJson()],
    'registros': [for (final r in registros) r.toJson()],
  };
}

/// Roda as etapas na ordem: modelo de decisão em todos → regra de encaminhamento → LLM só nos
/// incluídos/incertos. Grava cada chamada. A etapa 3 (humana) acontece depois, na tela.
class OrquestradorTriagem {
  final IDecisionModelClient decisor;
  final ILlmClient llm;
  final ConfigTriagem config;
  final DateTime Function() agora;

  OrquestradorTriagem({required this.decisor, required this.llm, required this.config, DateTime Function()? agora})
    : agora = agora ?? DateTime.now;

  CalculadoraCusto get _calc => CalculadoraCusto(config.precos);

  /// [aoProgredir] recebe a rodada parcial depois de cada estudo (para a tabela ir enchendo).
  Future<RodadaTriagem> rodar(
    ProjetoTriagem projeto, {
    void Function(RodadaTriagem parcial, String etapa)? aoProgredir,
  }) async {
    final resultados = [for (final e in projeto.estudos) ResultadoEstudo(e)];
    final registros = <RegistroChamada>[];
    var rodada = RodadaTriagem(projeto: projeto, config: config, resultados: resultados, inicio: agora());
    void avisar(String etapa) {
      rodada = rodada.copyWith(resultados: List.of(resultados), registros: List.of(registros));
      aoProgredir?.call(rodada, etapa);
    }

    // Etapa 1 — modelo de decisão em todos os estudos.
    for (var i = 0; i < resultados.length; i++) {
      final estudo = resultados[i].estudo;
      try {
        final d = await _decidir(estudo, projeto.criterios, null, registros);
        var r = resultados[i].copyWith(decisao: d, faixa: Faixa.de(d.probInclusao, config));
        if (config.testeEstabilidade) {
          final invertida = await _decidir(estudo, projeto.criterios, d.ordemOpcoes.reversed.toList(), registros);
          r = r.copyWith(decisaoInvertida: invertida);
        }
        resultados[i] = r;
      } catch (e) {
        // Sem decisão, o estudo vai para o humano (protege o recall).
        resultados[i] = resultados[i].copyWith(erro: 'Etapa 1: $e', faixa: Faixa.incerto);
      }
      avisar('Etapa 1 — ${i + 1}/${resultados.length}');
    }

    // Etapa 2 — LLM só nos incluídos e incertos.
    final paraLlm = [
      for (var i = 0; i < resultados.length; i++)
        if (resultados[i].faixa?.vaiParaLlm ?? false) i,
    ];
    for (var k = 0; k < paraLlm.length; k++) {
      final i = paraLlm[k];
      final estudo = resultados[i].estudo;
      try {
        final resp = await llm.justificar(estudo, projeto.criterios);
        final j = resp.valor.comCusto(_calc.de(llm.modelo, resp.valor.uso));
        resultados[i] = resultados[i].copyWith(justificativa: j);
        registros.add(_registro('llm', estudo, llm.modelo, llm.parametros, resp.bruto, j.uso, j.custo));
      } catch (e) {
        final atual = resultados[i].erro;
        resultados[i] = resultados[i].copyWith(erro: [?atual, 'Etapa 2: $e'].join(' | '));
        registros.add(_registro('llm', estudo, llm.modelo, llm.parametros, '', const Uso(), 0, erro: '$e'));
      }
      avisar('Etapa 2 — ${k + 1}/${paraLlm.length}');
    }

    rodada = rodada.copyWith(resultados: List.of(resultados), registros: List.of(registros), fim: agora());
    aoProgredir?.call(rodada, 'Concluída');
    return rodada;
  }

  Future<DecisaoModelo> _decidir(
    Estudo estudo,
    List<Criterio> criterios,
    List<Decisao>? ordem,
    List<RegistroChamada> registros,
  ) async {
    final etapa = ordem == null ? 'decisao' : 'decisao_ordem_invertida';
    try {
      final resp = await decisor.decidir(estudo, criterios, ordemOpcoes: ordem);
      final d = resp.valor.comCusto(_calc.de(decisor.modelo, resp.valor.uso));
      registros.add(_registro(etapa, estudo, decisor.modelo, decisor.parametros, resp.bruto, d.uso, d.custo));
      return d;
    } catch (e) {
      registros.add(_registro(etapa, estudo, decisor.modelo, decisor.parametros, '', const Uso(), 0, erro: '$e'));
      rethrow;
    }
  }

  RegistroChamada _registro(
    String etapa,
    Estudo estudo,
    String modelo,
    Map<String, dynamic> parametros,
    String saida,
    Uso uso,
    double custo, {
    String? erro,
  }) => RegistroChamada(
    quando: agora(),
    etapa: etapa,
    estudoId: estudo.id,
    modelo: modelo,
    parametros: parametros,
    entradaResumida: _resumir(estudo.estadoTexto),
    saida: saida.length > 2000 ? '${saida.substring(0, 2000)}…' : saida,
    uso: uso,
    custo: custo,
    erro: erro,
  );

  static String _resumir(String s) => s.length <= 200 ? s : '${s.substring(0, 200)}… (${utf8.encode(s).length} bytes)';
}
