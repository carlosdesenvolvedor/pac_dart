import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/config_triagem.dart';
import '../domain/estudo.dart';
import '../domain/orquestrador_triagem.dart';

/// Leitura do arquivo de entrada e da tabela de preços; exportação do resultado em JSON e CSV.
class ArquivosTriagem {
  final AssetBundle bundle;
  ArquivosTriagem([AssetBundle? bundle]) : bundle = bundle ?? rootBundle;

  Future<ProjetoTriagem> exemplo() async => lerProjeto(await bundle.loadString('assets/exemplo_triagem.json'));

  Future<TabelaPrecos> precos() async =>
      TabelaPrecos.fromJson(jsonDecode(await bundle.loadString('assets/precos.json')) as Map<String, dynamic>);

  static ProjetoTriagem lerProjeto(String conteudo) =>
      ProjetoTriagem.fromJson(jsonDecode(conteudo) as Map<String, dynamic>);

  static String exportarJson(RodadaTriagem r) => const JsonEncoder.withIndent('  ').convert(r.toJson());

  /// Uma linha por estudo, separador ";" (abre direto no Excel em português).
  static String exportarCsv(RodadaTriagem r) {
    String c(Object? v) {
      final s = switch (v) {
        null => '',
        double d => d.toStringAsFixed(4),
        _ => '$v',
      };
      return s.contains(RegExp(r'[;"\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    final linhas = [
      [
        'id',
        'titulo',
        'tipo_fonte',
        'gabarito',
        'faixa',
        'prob_inclusao',
        'escolha',
        'confianca',
        'nota_esperada',
        'estavel',
        'llm_decisao',
        'llm_criterios',
        'llm_justificativa',
        'decisao_humana',
        'observacao',
        'decisao_final',
        'tokens_entrada',
        'tokens_saida',
        'ms',
        'custo_usd',
        'erro',
      ].join(';'),
      for (final x in r.resultados)
        [
          x.estudo.id,
          x.estudo.titulo,
          x.estudo.tipoFonte.rotulo,
          x.estudo.gabarito?.name,
          x.faixa?.name,
          x.decisao?.probInclusao,
          x.decisao?.escolha.name,
          x.decisao?.confianca,
          x.decisao?.notaEsperada,
          x.estavel,
          x.justificativa?.decisaoSugerida.name,
          x.justificativa?.criteriosAtendidos.join(','),
          x.justificativa?.justificativa,
          x.humana?.decisao.name,
          x.humana?.observacao,
          x.decisaoFinal?.name,
          (x.decisao?.uso.tokensEntrada ?? 0) + (x.justificativa?.uso.tokensEntrada ?? 0),
          (x.decisao?.uso.tokensSaida ?? 0) + (x.justificativa?.uso.tokensSaida ?? 0),
          (x.decisao?.uso.ms ?? 0) + (x.justificativa?.uso.ms ?? 0),
          x.custo,
          x.erro,
        ].map(c).join(';'),
    ];
    return '${linhas.join('\n')}\n';
  }
}
