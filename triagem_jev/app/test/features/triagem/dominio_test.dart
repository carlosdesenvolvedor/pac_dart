import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triagem_jev/features/triagem/data/arquivos_triagem.dart';
import 'package:triagem_jev/features/triagem/data/clientes_simulados.dart';
import 'package:triagem_jev/features/triagem/domain/config_triagem.dart';
import 'package:triagem_jev/features/triagem/domain/decisoes.dart';
import 'package:triagem_jev/features/triagem/domain/estudo.dart';
import 'package:triagem_jev/features/triagem/domain/metricas.dart';
import 'package:triagem_jev/features/triagem/domain/orquestrador_triagem.dart';
import 'package:triagem_jev/features/triagem/domain/portas.dart';
import 'package:triagem_jev/features/triagem/domain/resultado_estudo.dart';

const _precos = TabelaPrecos({
  'simulado/decisao': Preco(0.042, 0),
  'simulado/llm': Preco(0.10, 0.50),
  'openai/decisions-gpt-6-luna': Preco(0.10, 0),
});

ProjetoTriagem _exemplo() => ArquivosTriagem.lerProjeto(File('assets/exemplo_triagem.json').readAsStringSync());

ResultadoEstudo _r(String id, Decisao gabarito, Faixa faixa) => ResultadoEstudo(
  Estudo(id: id, titulo: id, gabarito: gabarito),
  faixa: faixa,
);

/// Decisor que devolve probabilidades fixas por estudo (para testar o encaminhamento).
class _DecisorFixo implements IDecisionModelClient {
  final Map<String, double> p;
  final List<List<Decisao>> ordensRecebidas = [];
  _DecisorFixo(this.p);
  @override
  String get modelo => 'simulado/decisao';
  @override
  Map<String, dynamic> get parametros => const {};
  @override
  Future<Resposta<DecisaoModelo>> decidir(Estudo estudo, List<Criterio> criterios, {List<Decisao>? ordemOpcoes}) async {
    final ordem = ordemOpcoes ?? const [Decisao.incluir, Decisao.excluir, Decisao.incerto];
    ordensRecebidas.add(ordem);
    if (!p.containsKey(estudo.id)) throw Exception('falhou');
    return Resposta(
      DecisaoModelo(
        estudoId: estudo.id,
        modelo: modelo,
        probCondicao: p[estudo.id]!,
        escolha: ordem.first,
        ordemOpcoes: ordem,
        uso: const Uso(tokensEntrada: 1000000, ms: 10, medido: true),
      ),
    );
  }
}

class _LlmContador implements ILlmClient {
  final chamados = <String>[];
  @override
  String get modelo => 'simulado/llm';
  @override
  Map<String, dynamic> get parametros => const {};
  @override
  Future<Resposta<JustificativaLlm>> justificar(Estudo estudo, List<Criterio> criterios) async {
    chamados.add(estudo.id);
    return Resposta(
      JustificativaLlm(
        estudoId: estudo.id,
        modelo: modelo,
        decisaoSugerida: Decisao.incluir,
        justificativa: 'ok',
        uso: const Uso(tokensEntrada: 1000000, tokensSaida: 1000000, ms: 100, medido: true),
      ),
    );
  }
}

void main() {
  group('arquivo de entrada', () {
    test('o exemplo tem 24 estudos, critérios e literatura cinzenta', () {
      final p = _exemplo();
      expect(p.estudos, hasLength(24));
      expect(p.criterios.map((c) => c.id), ['C1', 'C2', 'C3']);
      expect(p.estudos.where((e) => e.tipoFonte == TipoFonte.literaturaCinzenta), isNotEmpty);
      expect(p.estudos.every((e) => e.gabarito != null), isTrue);
    });

    test('recusa arquivo sem estudos ou com id repetido', () {
      expect(
        () => ArquivosTriagem.lerProjeto('{"criterios":[{"id":"C1","texto":"x"}],"estudos":[]}'),
        throwsFormatException,
      );
      expect(
        () => ArquivosTriagem.lerProjeto(
          '{"criterios":[{"id":"C1","texto":"x"}],"estudos":[{"id":"E1","titulo":"a"},{"id":"E1","titulo":"b"}]}',
        ),
        throwsFormatException,
      );
    });

    test('o estado enviado ao modelo não leva gabarito nem url', () {
      const e = Estudo(id: 'E', titulo: 'T', resumo: 'R', url: 'http://x', gabarito: Decisao.incluir);
      expect(e.estadoTexto, isNot(contains('http://x')));
      expect(e.estadoTexto, isNot(contains('incluir')));
    });
  });

  group('regra de encaminhamento', () {
    const c = ConfigTriagem();
    test('limites 0,80 e 0,30', () {
      expect(Faixa.de(0.80, c), Faixa.incluido);
      expect(Faixa.de(0.79, c), Faixa.incerto);
      expect(Faixa.de(0.30, c), Faixa.incerto);
      expect(Faixa.de(0.29, c), Faixa.excluido);
      expect(Faixa.excluido.vaiParaLlm, isFalse);
      expect(Faixa.incerto.vaiParaLlm, isTrue);
    });
  });

  group('métricas', () {
    test('incerto conta como "segue"; recall, precisão, kappa e redução', () {
      final rs = [
        _r('a', Decisao.incluir, Faixa.incluido), // VP
        _r('b', Decisao.incluir, Faixa.incerto), // VP
        _r('c', Decisao.incluir, Faixa.excluido), // FN
        _r('d', Decisao.excluir, Faixa.incerto), // FP
        _r('e', Decisao.excluir, Faixa.excluido), // VN
        _r('f', Decisao.excluir, Faixa.excluido), // VN
      ];
      final m = Metricas.de(rs, (r) => r.faixa?.comoDecisao);
      expect([m.vp, m.fp, m.fn, m.vn], [2, 1, 1, 2]);
      expect(m.recall, closeTo(2 / 3, 1e-9));
      expect(m.precisao, closeTo(2 / 3, 1e-9));
      expect(m.acuracia, closeTo(4 / 6, 1e-9));
      expect(m.kappa, closeTo(1 / 3, 1e-9));
      expect(m.reducaoTrabalho, closeTo(3 / 6, 1e-9));
      expect(m.concordancia, closeTo(3 / 6, 1e-9)); // a, e, f
    });

    test('sem dados, métricas ficam nulas', () {
      final m = Metricas.de(const [], (r) => null);
      expect(m.recall, isNull);
      expect(m.kappa, isNull);
    });
  });

  group('orquestrador', () {
    test('LLM só nos incluídos e incertos; erro na etapa 1 vira incerto', () async {
      final p = ProjetoTriagem(
        nome: 't',
        criterios: const [Criterio('C1', 'x')],
        estudos: const [
          Estudo(id: 'A', titulo: 'a'),
          Estudo(id: 'B', titulo: 'b'),
          Estudo(id: 'C', titulo: 'c'),
          Estudo(id: 'D', titulo: 'd'),
        ],
      );
      final llm = _LlmContador();
      final rodada = await OrquestradorTriagem(
        decisor: _DecisorFixo({'A': 0.9, 'B': 0.5, 'C': 0.1}),
        llm: llm,
        config: const ConfigTriagem(precos: _precos),
      ).rodar(p);

      expect(
        [for (final r in rodada.resultados) r.faixa],
        [Faixa.incluido, Faixa.incerto, Faixa.excluido, Faixa.incerto],
      );
      expect(llm.chamados, ['A', 'B', 'D']);
      expect(rodada.resultados[3].erro, contains('Etapa 1'));
      // 3 decisões + 1 falha registrada + 3 LLM
      expect(rodada.registros, hasLength(7));
      expect(rodada.registros.where((r) => r.erro != null), hasLength(1));
      // Custo: 1M tokens de entrada × US$ 0,042 por decisão; LLM 0,10 + 0,50.
      expect(rodada.resultados[0].decisao!.custo, closeTo(0.042, 1e-12));
      expect(rodada.resultados[0].justificativa!.custo, closeTo(0.60, 1e-12));
    });

    test('teste de estabilidade inverte a ordem das opções', () async {
      final decisor = _DecisorFixo({'A': 0.9});
      final rodada =
          await OrquestradorTriagem(
            decisor: decisor,
            llm: _LlmContador(),
            config: const ConfigTriagem(precos: _precos, testeEstabilidade: true),
          ).rodar(
            const ProjetoTriagem(
              nome: 't',
              criterios: [Criterio('C1', 'x')],
              estudos: [Estudo(id: 'A', titulo: 'a')],
            ),
          );
      expect(decisor.ordensRecebidas, [
        [Decisao.incluir, Decisao.excluir, Decisao.incerto],
        [Decisao.incerto, Decisao.excluir, Decisao.incluir],
      ]);
      // O decisor fixo escolhe sempre a primeira opção: com a ordem invertida a escolha muda.
      expect(rodada.resultados.single.estavel, isFalse);
    });

    test('cenários: só LLM e Decisions API são estimados a partir do medido', () async {
      final p = ProjetoTriagem(
        nome: 't',
        criterios: const [Criterio('C1', 'x')],
        estudos: const [
          Estudo(id: 'A', titulo: 'a'),
          Estudo(id: 'B', titulo: 'b'),
        ],
      );
      final rodada = await OrquestradorTriagem(
        decisor: _DecisorFixo({'A': 0.9, 'B': 0.1}),
        llm: _LlmContador(),
        config: const ConfigTriagem(precos: _precos, modeloDecisao: 'simulado/decisao', modeloLlm: 'simulado/llm'),
      ).rodar(p);
      final [jev, soLlm, decisions] = rodada.cenarios.cenarios;
      expect(jev.custo, closeTo(2 * 0.042 + 0.60, 1e-9));
      expect(jev.medido, isTrue);
      expect(soLlm.custo, closeTo(2 * 0.60, 1e-9));
      expect(soLlm.medido, isFalse);
      expect(decisions.custo, closeTo(2 * 0.10 + 0.60, 1e-9));
      expect(jev.projecao(1000, rodadas: 6), closeTo(jev.custo / 2 * 6000, 1e-6));
    });

    test('ponta a ponta com os simulados no exemplo, e exportação', () async {
      final p = _exemplo();
      final rodada = await OrquestradorTriagem(
        decisor: SimuladoDecisionClient(atraso: Duration.zero),
        llm: SimuladoLlmClient(atraso: Duration.zero),
        config: const ConfigTriagem(precos: _precos),
      ).rodar(p);
      expect(rodada.resultados.every((r) => r.faixa != null), isTrue);
      final m = rodada.metricasEtapa1;
      // ignore: avoid_print
      print('simulado — etapa 1: ${m.toJson()}\nsistema: ${rodada.metricasSistema.toJson()}');
      expect(m.avaliados, 24);
      final csv = ArquivosTriagem.exportarCsv(rodada).trim().split('\n');
      expect(csv, hasLength(25));
      // Uma coluna de booleano e uma de Likert por critério, mais a soma (como a planilha do grupo).
      final cabecalho = csv.first.split(';');
      final n = p.criterios.length;
      for (final c in p.criterios) {
        expect(cabecalho, containsAll(['${c.id}_p_atende', '${c.id}_likert']));
      }
      expect(cabecalho, contains('soma_likert'));
      for (final r in rodada.resultados) {
        expect(r.decisao!.porCriterio, hasLength(n));
        expect(r.decisao!.somaLikert, inInclusiveRange(1.0 * n, 7.0 * n));
      }
      expect(ArquivosTriagem.exportarJson(rodada), contains('"por_criterio"'));
      expect(ArquivosTriagem.exportarJson(rodada), contains('"registros"'));
    });
  });
}
