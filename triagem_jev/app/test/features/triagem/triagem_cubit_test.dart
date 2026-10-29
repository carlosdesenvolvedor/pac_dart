import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:triagem_jev/features/triagem/data/arquivos_triagem.dart';
import 'package:triagem_jev/features/triagem/data/chaves_api.dart';
import 'package:triagem_jev/features/triagem/data/clientes_simulados.dart';
import 'package:triagem_jev/features/triagem/domain/estudo.dart';
import 'package:triagem_jev/features/triagem/presentation/triagem_cubit.dart';

TriagemCubit _cubit({void Function(ChavesApi)? aoFabricar}) => TriagemCubit(
  arquivos: ArquivosTriagem(),
  fabrica: (config, {required real, required chaves}) {
    aoFabricar?.call(chaves);
    return (SimuladoDecisionClient(atraso: Duration.zero), SimuladoLlmClient(atraso: Duration.zero));
  },
);

void main() {
  final exemplo = File('assets/exemplo_triagem.json').readAsStringSync();

  test('chaves do painel: vão para a fábrica, ficam fora do estado e campo vazio mantém', () async {
    late ChavesApi recebidas;
    final c = _cubit(aoFabricar: (k) => recebidas = k)..carregarArquivo(exemplo);
    c.definirChaves(const ChavesApi(anthropic: 'sk-ant-1'));
    c.definirChaves(const ChavesApi(openai: 'sk-oa-2'));
    expect(c.state.chavesNoPainel, ['Anthropic', 'OpenAI']);
    expect('${c.state}${c.state.props}', isNot(contains('sk-')));
    await c.rodar();
    expect(recebidas.cabecalhos, {'x-chave-anthropic': 'sk-ant-1', 'x-chave-openai': 'sk-oa-2'});
    expect('$recebidas', isNot(contains('sk-')));
    // Nada da chave no log nem na exportação.
    expect(ArquivosTriagem.exportarJson(c.state.rodada!), isNot(contains('sk-')));
    c.apagarChaves();
    expect(c.state.chavesNoPainel, isEmpty);
  });

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
