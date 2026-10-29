import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:triagem_jev/features/triagem/data/chaves_api.dart';
import 'package:triagem_jev/features/triagem/data/cliente_decisao.dart';
import 'package:triagem_jev/features/triagem/data/cliente_llm.dart';
import 'package:triagem_jev/features/triagem/data/falha_modelo.dart';
import 'package:triagem_jev/features/triagem/domain/decisoes.dart';
import 'package:triagem_jev/features/triagem/domain/estudo.dart';

const _estudo = Estudo(id: 'E1', titulo: 'Geração de testes com LLM', resumo: 'Um experimento.');
const _criterios = [Criterio('C1', 'Trata de geração de testes.')];

void main() {
  group('cliente de decisão (Decisions API do OpenRouter)', () {
    test('o pedido segue o esquema: noul, choice com criteria em mapa e score com níveis', () {
      final c = ClienteDecisaoOpenRouter.corpo(
        'typesafe/jev-1.14',
        _estudo,
        _criterios,
        Decisao.values.reversed.toList(),
      );
      expect(c['model'], 'typesafe/jev-1.14');
      final q = c['questions'] as Map<String, dynamic>;
      expect(q.keys, ['condicao', 'escolha', 'nota', 'atende_C1', 'likert_C1']);
      expect([for (final v in q.values) v['type']], ['noul', 'choice', 'score', 'noul', 'score']);
      // Por critério, o texto dos templates do grupo (Booleano I/E e Likert 1–7).
      expect(q['atende_C1']['instructions'], endsWith('clearly met? C1 - Trata de geração de testes.'));
      expect(q['likert_C1']['criteria'], hasLength(7));
      expect((q['likert_C1']['criteria'] as List).first, '1 - Strongly disagree');
      expect((q['condicao']['criteria'] as Map).keys, ['true', 'false']);
      // A ordem das opções segue o pedido (o teste de estabilidade inverte).
      expect((q['escolha']['criteria'] as Map).keys, ['incerto', 'excluir', 'incluir']);
      expect(q['nota']['criteria'], hasLength(7));
      final state = c['state'] as Map<String, dynamic>;
      expect(state['inclusion_criteria'], {'C1': 'Trata de geração de testes.'});
      expect(state['study'], {
        'source_type': 'peer-reviewed article',
        'title': 'Geração de testes com LLM',
        'abstract': 'Um experimento.',
      });
      // Sobrevive ao jsonEncode (é o que vai pelo fio).
      expect(jsonDecode(jsonEncode(c)), c);
    });

    test('lê as três respostas no formato documentado', () {
      final d = ClienteDecisaoOpenRouter.mapearResposta(
        {
          'id': 'gen-1',
          'model': 'typesafe/jev-1.14',
          'answers': {
            'condicao': {'type': 'noul', 'noul': 0.83},
            'escolha': {
              'type': 'choice',
              'choice': 'incluir',
              'confidence': 0.66,
              'probabilities': {'incluir': 0.7, 'excluir': 0.1, 'incerto': 0.2},
            },
            'nota': {
              'type': 'score',
              'score': 5.0,
              'confidence': 0.4,
              'probabilities': {'0': 0.0, '1': 0.0, '2': 0.0, '3': 0.1, '4': 0.2, '5': 0.3, '6': 0.4},
              'legend': {'0': '1: certainly exclude'},
            },
            'atende_C1': {'type': 'noul', 'noul': 0.9},
            'likert_C1': {
              'type': 'score',
              'score': 6.0,
              'confidence': 0.8,
              'probabilities': {'0': 0, '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 1.0},
            },
            // C2 sem resposta: fica de fora.
          },
          'usage': {'input_tokens': 210, 'output_tokens': 70, 'cost': 0.0000088},
        },
        'E1',
        'typesafe/jev-1.14',
        Decisao.values,
        123,
        criterios: ['C1', 'C2'],
      );
      expect(d.porCriterio, [
        const AvaliacaoCriterio('C1', probAtende: 0.9, distribuicaoLikert: [0, 0, 0, 0, 0, 0, 1]),
      ]);
      expect(d.somaLikert, 7);
      expect(d.probInclusao, 0.83);
      expect(d.escolha, Decisao.incluir);
      expect(d.probEscolha, {Decisao.incluir: 0.7, Decisao.excluir: 0.1, Decisao.incerto: 0.2});
      expect(d.confianca, 0.66);
      expect(d.notaEsperada, closeTo(6.0, 1e-9));
      expect(d.uso.tokensEntrada, 210);
      expect(d.uso.ms, 123);
      expect(d.uso.medido, isTrue);
    });

    test('sem "choice" escolhe pela maior probabilidade; nota é opcional', () {
      final d = ClienteDecisaoOpenRouter.mapearResposta(
        {
          'answers': {
            'condicao': {'type': 'noul', 'noul': 0.2},
            'escolha': {
              'type': 'choice',
              'probabilities': {'incluir': 0.1, 'excluir': 0.8, 'incerto': 0.1},
            },
          },
        },
        'E1',
        'm',
        Decisao.values,
        5,
      );
      expect(d.escolha, Decisao.excluir);
      expect(d.notaEsperada, isNull);
    });

    test('resposta sem answers vira FalhaModelo', () {
      expect(
        () => ClienteDecisaoOpenRouter.mapearResposta({'error': {'code': 400}}, 'E1', 'm', Decisao.values, 1),
        throwsA(isA<FalhaModelo>()),
      );
    });

    test('HTTP de erro vira FalhaModelo com mensagem útil', () async {
      final c = ClienteDecisaoOpenRouter(
        worker: Uri.parse('http://w'),
        cliente: MockClient((_) async => http.Response('{"error":"x"}', 401)),
      );
      await expectLater(c.decidir(_estudo, _criterios), throwsA(isA<FalhaModelo>()));
    });
  });

  group('cliente LLM', () {
    test('lê o JSON da resposta mesmo com texto em volta e mede tokens', () async {
      late Map<String, dynamic> enviado;
      final c = ClienteLlmOpenRouter(
        worker: Uri.parse('http://w'),
        modelo: 'anthropic/claude-haiku-5.5',
        cliente: MockClient((req) async {
          enviado = jsonDecode(req.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content':
                        'Aqui:\n```json\n{"decisao_sugerida":"incluir","criterios_atendidos":["C1"],"justificativa":"Atende C1."}\n```',
                  },
                },
              ],
              'usage': {'prompt_tokens': 300, 'completion_tokens': 40},
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
      );
      final r = await c.justificar(_estudo, _criterios);
      expect(r.valor.decisaoSugerida, Decisao.incluir);
      expect(r.valor.criteriosAtendidos, ['C1']);
      expect(r.valor.uso.tokensSaida, 40);
      // Claude atual recusa temperatura/top_p.
      expect(enviado.containsKey('temperature'), isFalse);
    });

    test('chave do painel vai em cabeçalho, nunca nos parâmetros do log', () async {
      late http.Request enviado;
      final c = ClienteLlmOpenRouter(
        worker: Uri.parse('http://w'),
        modelo: 'anthropic/claude-haiku-5.5',
        chaves: const ChavesApi(anthropic: 'sk-ant-x'),
        cliente: MockClient((req) async {
          enviado = req;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {'content': '{"decisao_sugerida":"incerto","justificativa":"x"}'},
                },
              ],
            }),
            200,
          );
        }),
      );
      await c.justificar(_estudo, _criterios);
      expect(enviado.headers['x-chave-anthropic'], 'sk-ant-x');
      expect(enviado.body, isNot(contains('sk-ant-x')));
      expect('${c.parametros}', isNot(contains('sk-ant-x')));
    });

    test('GPT-6 também não leva temperatura (recusa com 400) e ganha teto maior', () {
      final c = ClienteLlmOpenRouter(worker: Uri.parse('http://w'), modelo: 'openai/gpt-6-luna');
      expect(c.parametros, {'max_tokens': 2000});
    });

    test('modelos que não raciocinam levam temperatura e top-p zero', () {
      final c = ClienteLlmOpenRouter(worker: Uri.parse('http://w'), modelo: 'openai/gpt-x');
      expect(c.parametros['temperature'], 0);
      expect(c.parametros['top_p'], 0);
    });
  });
}
