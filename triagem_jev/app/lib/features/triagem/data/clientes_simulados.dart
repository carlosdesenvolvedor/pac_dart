import 'dart:math';

import '../domain/decisoes.dart';
import '../domain/estudo.dart';
import '../domain/portas.dart';
import '../domain/prompt_llm.dart';

/// Clientes SIMULADOS: rodam sem internet e sem chave, para ensaiar a demonstração e testar a tela.
/// A "decisão" é uma heurística de palavras em comum com os critérios — não tem nada de Jev nem de
/// LLM. Os números saem com `medido: false` e a tela mostra "simulado".
abstract final class _Heuristica {
  static final _naoLetra = RegExp(r'[^a-z0-9à-ú]+');
  static const _vazias = {
    'que',
    'com',
    'dos',
    'das',
    'por',
    'para',
    'uma',
    'como',
    'sem',
    'nos',
    'nas',
    'seu',
    'sua',
    'estudo',
    'trata',
    'utiliza',
    'apresenta',
    'propõe',
    'proposta',
    'avaliada',
    'abordagem',
    'grande',
    'porte',
    'qualquer',
  };

  /// Radicais grosseiros: minúsculas, sem plural em "s", primeiros 5 caracteres.
  static Set<String> radicais(String texto) => {
    for (var p in texto.toLowerCase().split(_naoLetra))
      if (p.length >= 3 && !_vazias.contains(p))
        (p = p.endsWith('s') && p.length > 3 ? p.substring(0, p.length - 1) : p).substring(0, min(p.length, 5)),
  };

  /// Quanto de cada critério aparece no estudo (1 = uns 40% dos termos do critério encontrados).
  static List<double> cobertura(Estudo estudo, List<Criterio> criterios) {
    final doEstudo = radicais('${estudo.titulo} ${estudo.resumo} ${estudo.palavrasChave.join(' ')}');
    return [
      for (final c in criterios)
        () {
          final termos = radicais(c.texto);
          if (termos.isEmpty) return 0.0;
          return min(1.0, termos.where(doEstudo.contains).length / max(1.0, 0.4 * termos.length));
        }(),
    ];
  }

  /// Probabilidade de "atende a todos": puxada pelo critério MAIS fraco.
  static double probInclusao(Estudo estudo, List<Criterio> criterios) {
    final cob = cobertura(estudo, criterios);
    if (cob.isEmpty) return 0.5;
    final pior = cob.reduce(min);
    final media = cob.reduce((a, b) => a + b) / cob.length;
    final x = 0.65 * pior + 0.35 * media;
    // Sem resumo há menos evidência: a probabilidade encosta no meio.
    final peso = estudo.resumo.isEmpty ? 0.3 : 1.0;
    final p = 1 / (1 + exp(-10 * (x - 0.6)));
    return 0.5 + (p - 0.5) * peso;
  }

  static int msFalso(String id, int base) => base + id.codeUnits.fold(0, (a, b) => a + b) % base;
}

class SimuladoDecisionClient implements IDecisionModelClient {
  final Duration atraso;
  SimuladoDecisionClient({this.atraso = const Duration(milliseconds: 40)});

  @override
  String get modelo => 'simulado/decisao';

  @override
  Map<String, dynamic> get parametros => {'tipo': 'heuristica_palavras', 'aviso': 'não é o Jev'};

  @override
  Future<Resposta<DecisaoModelo>> decidir(Estudo estudo, List<Criterio> criterios, {List<Decisao>? ordemOpcoes}) async {
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    final ordem = ordemOpcoes ?? const [Decisao.incluir, Decisao.excluir, Decisao.incerto];
    final p = _Heuristica.probInclusao(estudo, criterios);

    // Escolha: "incerto" ganha massa perto do meio. A opção listada primeiro ganha um empurrão
    // pequeno — imita o efeito de ordem citado na documentação, para o teste de estabilidade.
    final bruto = {Decisao.incluir: p * p, Decisao.excluir: (1 - p) * (1 - p), Decisao.incerto: 2 * p * (1 - p) * 0.9};
    bruto[ordem.first] = bruto[ordem.first]! + 0.04;
    final soma = bruto.values.reduce((a, b) => a + b);
    final probs = {for (final MapEntry(:key, :value) in bruto.entries) key: value / soma};
    final escolha = probs.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // Notas 1..7 em sino: a geral centrada em 1 + 6p; por critério, a cobertura de cada um vira
    // P(atende) e um Likert centrado em 1 + 6·cobertura.
    final cob = _Heuristica.cobertura(estudo, criterios);
    List<double> sino(double centro) {
      final w = [for (var n = 1; n <= 7; n++) exp(-pow(n - centro, 2) / 1.2)];
      final t = w.reduce((a, b) => a + b);
      return [for (final x in w) x / t];
    }

    // O estado vai uma vez; cada critério acrescenta o texto das duas perguntas.
    final entrada =
        PromptLlm.estimarTokens('${estudo.estadoTexto}\n${criterios.map((c) => c.texto).join('\n')}') +
        60 +
        criterios.fold<int>(0, (a, c) => a + 2 * PromptLlm.estimarTokens(c.texto) + 90);
    final d = DecisaoModelo(
      estudoId: estudo.id,
      modelo: modelo,
      probCondicao: p,
      escolha: escolha,
      probEscolha: probs,
      confianca: probs[escolha]!,
      distribuicaoNota: sino(1 + 6 * p),
      ordemOpcoes: ordem,
      porCriterio: [
        for (var i = 0; i < criterios.length; i++)
          AvaliacaoCriterio(
            criterios[i].id,
            probAtende: 1 / (1 + exp(-8 * (cob[i] - 0.5))),
            distribuicaoLikert: sino(1 + 6 * cob[i]),
          ),
      ],
      uso: Uso(tokensEntrada: entrada, ms: _Heuristica.msFalso(estudo.id, 60)),
    );
    return Resposta(d, '{"simulado": true, "p": ${p.toStringAsFixed(3)}}');
  }
}

class SimuladoLlmClient implements ILlmClient {
  final Duration atraso;
  SimuladoLlmClient({this.atraso = const Duration(milliseconds: 80)});

  @override
  String get modelo => 'simulado/llm';

  @override
  Map<String, dynamic> get parametros => {'temperature': 0, 'top_p': 0, 'aviso': 'texto gerado por regra, não por LLM'};

  @override
  Future<Resposta<JustificativaLlm>> justificar(Estudo estudo, List<Criterio> criterios) async {
    if (atraso > Duration.zero) await Future<void>.delayed(atraso);
    final cob = _Heuristica.cobertura(estudo, criterios);
    final atendidos = [
      for (var i = 0; i < criterios.length; i++)
        if (cob[i] >= 0.4) criterios[i].id,
    ];
    final faltam = [
      for (final c in criterios)
        if (!atendidos.contains(c.id)) c.id,
    ];
    final Decisao sugerida;
    final String texto;
    if (estudo.resumo.isEmpty) {
      sugerida = Decisao.incerto;
      texto = 'Fonte sem resumo formal: não encontrei informação suficiente para todos os critérios.';
    } else if (faltam.isEmpty) {
      sugerida = Decisao.incluir;
      texto = '[simulado] O texto menciona elementos de todos os critérios (${atendidos.join(', ')}).';
    } else if (atendidos.isEmpty) {
      sugerida = Decisao.excluir;
      texto = '[simulado] Nenhum critério aparece no título nem no resumo.';
    } else {
      sugerida = faltam.length == 1 ? Decisao.incerto : Decisao.excluir;
      texto =
          '[simulado] Atende ${atendidos.join(', ')}; não encontrei informação suficiente sobre ${faltam.join(', ')}.';
    }
    final entrada = PromptLlm.tokensEntradaEstimados(estudo, criterios);
    final j = JustificativaLlm(
      estudoId: estudo.id,
      modelo: modelo,
      decisaoSugerida: sugerida,
      criteriosAtendidos: atendidos,
      justificativa: texto,
      uso: Uso(
        tokensEntrada: entrada,
        tokensSaida: PromptLlm.tokensSaidaTipicos,
        ms: _Heuristica.msFalso(estudo.id, 900),
      ),
    );
    return Resposta(j, texto);
  }
}
