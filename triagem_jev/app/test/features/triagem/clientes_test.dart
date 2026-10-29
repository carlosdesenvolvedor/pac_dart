import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:triagem_jev/features/triagem/data/cliente_decisao.dart';
import 'package:triagem_jev/features/triagem/data/cliente_llm.dart';
import 'package:triagem_jev/features/triagem/data/falha_modelo.dart';
import 'package:triagem_jev/features/triagem/domain/estudo.dart';

const _estudo = Estudo(id: 'E1', titulo: 'Geração de testes com LLM', resumo: 'Um experimento.');
const _criterios = [Criterio('C1', 'Trata de geração de testes.')];

void main() {
  group('cliente de decisão (formato A CONFIRMAR)', () {
    test('o pedido leva as três perguntas e a ordem das opções', () {
      final c = ClienteDecisaoOpenRouter.corpo(
        'typesafe/jev-1.13',
        _estudo,
        _criterios,
        Decisao.values.reversed.toList(),
      );
      final ds = c['decisions'] as List;
      expect([for (final d in ds) d['type']], ['condition', 'choice', 'score']);
      expect(ds[1]['options'], ['incerto', 'excluir', 'incluir']);
      expect(c['state'], contains('C1: Trata de geração de testes.'));
    });

    test('lê resposta em lista com nomes', () {
      final d = ClienteDecisaoOpenRouter.mapearResposta(
        {
          'decisions': [
            {'name': 'condicao', 'probability': 0.83},
            {
              'name': 'escolha',
              'choice': 'incluir',
              'probabilities': {'incluir': 0.7, 'excluir': 0.1, 'incerto': 0.2},
              'confidence': 0.66,
            },
            {
              'name': 'nota',
              'distribution': [0, 0, 0, 0.1, 0.2, 0.3, 0.4],
            },
          ],
          'usage': {'prompt_tokens': 210, 'completion_tokens': 0},
        },
        'E1',
        'typesafe/jev-1.13',
        Decisao.values,
        123,
      );
      expect(d.probInclusao, 0.83);
      expect(d.escolha, Decisao.incluir);
      expect(d.confianca, 0.66);
      expect(d.notaEsperada, closeTo(6.0, 1e-9));
      expect(d.uso.tokensEntrada, 210);
      expect(d.uso.medido, isTrue);
    });

    test('lê resposta em mapa e escolhe pela maior probabilidade', () {
      final d = ClienteDecisaoOpenRouter.mapearResposta(
        {
          'results': {
            'condicao': {'p_true': 0.2},
            'escolha': {
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

    test('modelos não-Claude levam temperatura e top-p zero', () {
      final c = ClienteLlmOpenRouter(worker: Uri.parse('http://w'), modelo: 'openai/gpt-x');
      expect(c.parametros['temperature'], 0);
      expect(c.parametros['top_p'], 0);
    });
  });
}
