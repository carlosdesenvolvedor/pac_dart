import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triagem_jev/features/triagem/data/arquivos_triagem.dart';
import 'package:triagem_jev/features/triagem/data/clientes_simulados.dart';
import 'package:triagem_jev/features/triagem/domain/estudo.dart';
import 'package:triagem_jev/features/triagem/presentation/triagem_cubit.dart';

TriagemCubit _cubit() => TriagemCubit(
  arquivos: ArquivosTriagem(),
  fabrica: (config, {required real}) =>
      (SimuladoDecisionClient(atraso: Duration.zero), SimuladoLlmClient(atraso: Duration.zero)),
);

void main() {
  final exemplo = File('assets/exemplo_triagem.json').readAsStringSync();

  test('carregar → rodar → revisar', () async {
    final c = _cubit();
    c.carregarArquivo(exemplo);
    expect(c.state.status, StatusTriagem.pronto);

    await c.rodar();
    expect(c.state.status, StatusTriagem.concluido);
    expect(c.state.rodada!.resultados, hasLength(24));
    expect(c.state.rodada!.config.modeloDecisao, 'simulado/decisao');

    c.decidirHumano('E01', Decisao.excluir, observacao: 'teste');
    expect(c.state.rodada!.resultados.first.decisaoFinal, Decisao.excluir);
    c.decidirHumano('E01', null);
    expect(c.state.rodada!.resultados.first.humana, isNull);

    c.aceitarSugestoes();
    expect(c.state.rodada!.resultados.every((r) => r.humana != null), isTrue);
  });

  test('arquivo inválido vira erro, sem trocar o projeto', () {
    final c = _cubit()..carregarArquivo('{nada');
    expect(c.state.erro, isNotNull);
    expect(c.state.projeto, isNull);
  });

  test('modo real só liga com Worker configurado; limites não se cruzam', () {
    final c = _cubit()..alternarModoReal(true);
    expect(c.state.modoReal, isFalse);
    c.ajustarLimites(excluir: 0.9);
    expect(c.state.config.limiteExcluir, 0.30);
  });
}
