import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/decisoes.dart';
import '../domain/estudo.dart';
import '../domain/portas.dart';
import 'falha_modelo.dart';

/// Jev (TypeSafe AI) pela Decisions API do OpenRouter, passando pelo Worker (a chave fica lá).
///
/// Formato conferido em 29/10/2026 na referência oficial
/// (https://openrouter.ai/docs/api/api-reference/alphadecisions/submit-a-decisions-questions-and-answers-request.md)
/// e numa resposta real do Jev 1.13:
/// - pedido: `{model, state, questions: {nome: {type, instructions, criteria}}}`;
///   `noul` leva `criteria: {true, false}`, `choice` um mapa opção→descrição e `score` uma lista
///   de níveis (a posição na lista é o nível, a partir de 0);
/// - resposta: `{model, answers: {nome: …}, usage: {input_tokens, output_tokens, cost}}`;
///   noul → `noul`; choice → `choice`, `confidence`, `probabilities`; score → `score`,
///   `confidence`, `probabilities` ("0".."6"), `legend`.
///
/// As perguntas vão em inglês (o Jev é mais preciso em inglês e lê as instruções ao pé da letra);
/// o texto do estudo e dos critérios vai como está.
///
/// Serve também para a OpenAI Decisions API (cenário 3): mesmo formato, outro [modelo] e [rota].
class ClienteDecisaoOpenRouter implements IDecisionModelClient {
  final Uri worker;
  final http.Client _http;

  /// `Authorization: Bearer …` quando o Worker tem TOKEN_ACESSO (vazio = não manda).
  final String tokenAcesso;
  @override
  final String modelo;

  /// Rota do Worker: `/jev` (OpenRouter) ou `/openai-decisions`.
  final String rota;

  ClienteDecisaoOpenRouter({
    required this.worker,
    this.modelo = 'typesafe/jev-1.14',
    this.rota = '/jev',
    http.Client? cliente,
    this.tokenAcesso = '',
  }) : _http = cliente ?? http.Client();

  @override
  Map<String, dynamic> get parametros => {
    'endpoint': rota,
    'perguntas': ['condicao', 'escolha', 'nota_1_7', 'por_criterio: booleano I/E + Likert 1-7'],
  };

  // Abertura igual à dos templates do grupo de pesquisa (Booleano I/E e Likert 1–7), para que as
  // respostas do Jev sejam comparáveis às planilhas dos LLMs.
  static const _base =
      'Assume you are a software engineering researcher conducting a systematic literature review (SLR). '
      'Consider the title, abstract, and keywords of the primary study in `study`, and nothing else. ';
  static const perguntaCondicao = '${_base}Does the study meet ALL the inclusion criteria?';
  static const perguntaEscolha = '${_base}What should the screening decision for this study be?';
  static const perguntaNota = '${_base}How strongly should this study be included?';

  static const criteriosCondicao = {
    'true': 'The study meets every inclusion criterion',
    'false': 'At least one inclusion criterion is not met',
  };
  static const opcoesEscolha = {
    Decisao.incluir: 'Include: the study clearly meets every inclusion criterion',
    Decisao.excluir: 'Exclude: the study clearly fails at least one inclusion criterion',
    Decisao.incerto: 'Uncertain: the text is not enough to decide; a researcher must read the full study',
  };

  /// Os 7 níveis da nota (índice 0 = nota 1).
  static const niveisNota = [
    '1: certainly exclude',
    '2: very likely exclude',
    '3: probably exclude',
    '4: cannot tell',
    '5: probably include',
    '6: very likely include',
    '7: certainly include',
  ];

  /// Escala do template Likert do grupo (índice 0 = 1).
  static const niveisLikert = [
    '1 - Strongly disagree',
    '2 - Disagree',
    '3 - Somewhat disagree',
    '4 - Neither agree or disagree',
    '5 - Somewhat agree',
    '6 - Agree',
    '7 - Strongly agree',
  ];

  static String perguntaAtende(Criterio c) =>
      '${_base}Using a binary classification, is the following inclusion criterion clearly met? ${c.id} - ${c.texto}';
  static String perguntaLikert(Criterio c) =>
      '${_base}Using a 1-7 Likert scale, rate your agreement with the following statement: ${c.id} - ${c.texto}';
  static const criteriosAtende = {
    'true': 'I: the criterion is clearly met (Include)',
    'false': 'E: the criterion is not clearly met (Exclude)',
  };

  /// Nomes das perguntas de um critério na chamada.
  static String chaveAtende(String id) => 'atende_$id';
  static String chaveLikert(String id) => 'likert_$id';

  /// O pedido: estado (critérios + estudo, nada de irrelevante) e todas as perguntas numa chamada
  /// só — as três gerais e, por critério, o booleano e o Likert. O Jev cobra pela entrada, e o
  /// estado vai uma vez, então cada pergunta a mais custa só o texto dela.
  /// A ordem das opções da escolha segue [ordem] (o teste de estabilidade inverte).
  static Map<String, dynamic> corpo(String modelo, Estudo estudo, List<Criterio> criterios, List<Decisao> ordem) => {
    'model': modelo,
    'state': {
      'inclusion_criteria': {for (final c in criterios) c.id: c.texto},
      'study': {
        'source_type': switch (estudo.tipoFonte) {
          TipoFonte.artigo => 'peer-reviewed article',
          TipoFonte.literaturaCinzenta => 'grey literature (blog post, documentation, issue; no formal abstract)',
        },
        'title': estudo.titulo,
        if (estudo.resumo.isNotEmpty) 'abstract': estudo.resumo,
        if (estudo.palavrasChave.isNotEmpty) 'keywords': estudo.palavrasChave,
      },
    },
    'questions': {
      'condicao': {'type': 'noul', 'instructions': perguntaCondicao, 'criteria': criteriosCondicao},
      'escolha': {
        'type': 'choice',
        'instructions': perguntaEscolha,
        'criteria': {for (final o in ordem) o.name: opcoesEscolha[o]},
      },
      'nota': {'type': 'score', 'instructions': perguntaNota, 'criteria': niveisNota},
      for (final c in criterios) ...{
        chaveAtende(c.id): {'type': 'noul', 'instructions': perguntaAtende(c), 'criteria': criteriosAtende},
        chaveLikert(c.id): {'type': 'score', 'instructions': perguntaLikert(c), 'criteria': niveisLikert},
      },
    },
  };

  @override
  Future<Resposta<DecisaoModelo>> decidir(Estudo estudo, List<Criterio> criterios, {List<Decisao>? ordemOpcoes}) async {
    final ordem = ordemOpcoes ?? const [Decisao.incluir, Decisao.excluir, Decisao.incerto];
    final relogio = Stopwatch()..start();
    final resp = await _http.post(
      worker.resolve(rota),
      headers: {'content-type': 'application/json', if (tokenAcesso.isNotEmpty) 'authorization': 'Bearer $tokenAcesso'},
      body: jsonEncode(corpo(modelo, estudo, criterios, ordem)),
    );
    relogio.stop();
    if (resp.statusCode != 200) throw FalhaModelo.http(resp.statusCode, resp.body);
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    return Resposta(
      mapearResposta(
        json,
        estudo.id,
        modelo,
        ordem,
        relogio.elapsedMilliseconds,
        criterios: [for (final c in criterios) c.id],
      ),
      resp.body,
    );
  }

  /// Lê `answers` da Decisions API. Sem a condição ou a escolha → [FalhaModelo] (o estudo vira
  /// incerto e segue para o pesquisador). A nota e as perguntas por critério são opcionais: um
  /// critério sem o booleano fica de fora de [DecisaoModelo.porCriterio].
  static DecisaoModelo mapearResposta(
    Map<String, dynamic> j,
    String estudoId,
    String modelo,
    List<Decisao> ordem,
    int ms, {
    List<String> criterios = const [],
  }) {
    final answers = j['answers'];
    final cond = answers is Map ? answers['condicao'] : null;
    final esc = answers is Map ? answers['escolha'] : null;
    final nota = answers is Map ? answers['nota'] : null;
    if (cond is! Map || esc is! Map) throw FalhaModelo('Resposta sem as decisões esperadas: ${jsonEncode(j)}');

    final probEscolha = <Decisao, double>{
      if (esc['probabilities'] case final Map pe)
        for (final MapEntry(:key, :value) in pe.entries) ?Decisao.deTexto('$key'): _num(value),
    };
    final escolha =
        Decisao.deTexto('${esc['choice']}') ??
        (probEscolha.isEmpty ? Decisao.incerto : probEscolha.entries.reduce((a, b) => a.value >= b.value ? a : b).key);

    final usage = (j['usage'] as Map?) ?? const {};
    return DecisaoModelo(
      estudoId: estudoId,
      modelo: modelo,
      probCondicao: _num(cond['noul']),
      escolha: escolha,
      probEscolha: probEscolha,
      confianca: _num(esc['confidence'] ?? probEscolha[escolha] ?? 0),
      distribuicaoNota: _distribuicao(nota, niveisNota.length),
      ordemOpcoes: ordem,
      porCriterio: [
        for (final id in criterios)
          if ((answers as Map)[chaveAtende(id)] case final Map atende)
            AvaliacaoCriterio(
              id,
              probAtende: _num(atende['noul']),
              distribuicaoLikert: _distribuicao(answers[chaveLikert(id)], niveisLikert.length),
            ),
      ],
      uso: Uso(
        tokensEntrada: (usage['input_tokens'] ?? 0) as int,
        tokensSaida: (usage['output_tokens'] ?? 0) as int,
        ms: ms,
        medido: true,
      ),
    );
  }

  /// Resposta de score → distribuição na ordem dos níveis ("0".."n-1"); vazia se não veio.
  static List<double> _distribuicao(Object? score, int niveis) => [
    if (score is Map && score['probabilities'] is Map)
      for (var i = 0; i < niveis; i++) _num((score['probabilities'] as Map)['$i']),
  ];

  static double _num(Object? v) => switch (v) {
    num n => n.toDouble(),
    String s => double.tryParse(s) ?? 0,
    _ => 0,
  };
}
