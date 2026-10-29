import 'package:flutter/material.dart';

import '../../domain/decisoes.dart';
import '../../domain/estudo.dart';
import '../../domain/resultado_estudo.dart';
import '../cores_decisao.dart';
import 'formato.dart';

/// Uma linha por estudo: título, decisão do modelo, probabilidade, LLM, gabarito e decisão humana.
class TabelaEstudos extends StatelessWidget {
  final List<ResultadoEstudo> resultados;
  final bool mostrarEstabilidade;
  final void Function(String estudoId, Decisao? decisao) aoDecidir;

  const TabelaEstudos({super.key, required this.resultados, required this.aoDecidir, this.mostrarEstabilidade = false});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columnSpacing: 18,
      dataRowMinHeight: 48,
      dataRowMaxHeight: 96,
      columns: [
        const DataColumn(label: Text('Estudo')),
        const DataColumn(label: Text('Etapa 1')),
        const DataColumn(label: Text('P(inclusão)'), numeric: true),
        const DataColumn(label: Text('Escolha / conf.')),
        const DataColumn(label: Text('Nota 1–7'), numeric: true),
        const DataColumn(
          label: Tooltip(
            message:
                'Cada critério avaliado à parte, como nos templates do grupo: Likert 1–7 esperado '
                '(verde = booleano "atende" ≥ 50%) e a soma, como na planilha dos LLMs.',
            child: Text('Por critério (Likert)'),
          ),
        ),
        if (mostrarEstabilidade) const DataColumn(label: Text('Estável?')),
        const DataColumn(label: Text('LLM')),
        const DataColumn(label: Text('Gabarito')),
        const DataColumn(label: Text('Decisão humana')),
      ],
      rows: [for (final r in resultados) _linha(context, r)],
    ),
  );

  DataRow _linha(BuildContext context, ResultadoEstudo r) {
    final d = r.decisao;
    final j = r.justificativa;
    final errou =
        r.estudo.gabarito != null &&
        r.decisaoFinal != null &&
        (r.decisaoFinal != Decisao.excluir) != (r.estudo.gabarito == Decisao.incluir);
    return DataRow(
      color: WidgetStatePropertyAll(CoresDecisao.daFaixa(r.faixa).withValues(alpha: r.faixa == null ? 0 : 0.06)),
      cells: [
        DataCell(
          SizedBox(
            width: 320,
            child: Tooltip(
              message: r.estudo.resumo.isEmpty ? '(sem resumo)' : r.estudo.resumo,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${r.estudo.id} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: r.estudo.titulo),
                    if (r.estudo.tipoFonte == TipoFonte.literaturaCinzenta)
                      const TextSpan(
                        text: '  · literatura cinzenta',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        DataCell(
          r.faixa == null
              ? (r.erro != null
                    ? _erro(r.erro!)
                    : const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
              : EtiquetaDecisao(r.faixa!.comoDecisao, texto: r.faixa!.rotulo),
        ),
        DataCell(Text(d == null ? '—' : d.probInclusao.toStringAsFixed(2))),
        DataCell(Text(d == null ? '—' : '${CoresDecisao.rotulo(d.escolha)} · ${pct(d.confianca)}')),
        DataCell(Text(d?.notaEsperada?.toStringAsFixed(1) ?? '—')),
        DataCell(d == null || d.porCriterio.isEmpty ? const Text('—') : _porCriterio(d)),
        if (mostrarEstabilidade)
          DataCell(switch (r.estavel) {
            true => const Icon(Icons.check, color: CoresDecisao.incluir),
            false => const Tooltip(
              message: 'A escolha mudou com a ordem das opções invertida',
              child: Icon(Icons.swap_horiz, color: CoresDecisao.excluir),
            ),
            null => const Text('—'),
          }),
        DataCell(
          SizedBox(
            width: 340,
            child: j == null
                ? Text(
                    r.faixa == Faixa.excluido ? '(não enviado ao LLM)' : (r.erro ?? '—'),
                    style: const TextStyle(color: Colors.black54),
                  )
                : Tooltip(
                    message: 'Critérios atendidos: ${j.criteriosAtendidos.join(', ')}',
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        EtiquetaDecisao(j.decisaoSugerida),
                        const SizedBox(width: 8),
                        Expanded(child: Text(j.justificativa, maxLines: 4, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EtiquetaDecisao(r.estudo.gabarito),
              if (errou)
                const Tooltip(
                  message: 'A decisão final diverge do gabarito',
                  child: Icon(Icons.error_outline, size: 18),
                ),
            ],
          ),
        ),
        DataCell(
          DropdownButton<Decisao?>(
            value: r.humana?.decisao,
            hint: Text('sugestão: ${CoresDecisao.rotulo(r.decisaoSistema)}'),
            underline: const SizedBox.shrink(),
            items: [
              for (final o in Decisao.values)
                DropdownMenuItem(
                  value: o,
                  child: Text(CoresDecisao.rotulo(o), style: TextStyle(color: CoresDecisao.de(o))),
                ),
              // O item nulo só aparece depois de uma decisão; antes, o valor nulo mostra a sugestão (hint).
              if (r.humana != null) const DropdownMenuItem(value: null, child: Text('desfazer')),
            ],
            onChanged: r.faixa == null ? null : (v) => aoDecidir(r.estudo.id, v),
          ),
        ),
      ],
    );
  }

  Widget _porCriterio(DecisaoModelo d) => Tooltip(
    message: [
      for (final a in d.porCriterio)
        '${a.criterioId}: atende ${pct(a.probAtende)} · Likert ${a.likertEsperado?.toStringAsFixed(1) ?? '—'}',
    ].join('\n'),
    child: Text.rich(
      TextSpan(
        children: [
          for (final (i, a) in d.porCriterio.indexed) ...[
            if (i > 0) const TextSpan(text: ' · '),
            TextSpan(
              text: '${a.criterioId} ${a.likertEsperado?.toStringAsFixed(1) ?? '—'}',
              style: TextStyle(color: a.probAtende >= 0.5 ? CoresDecisao.incluir : CoresDecisao.excluir),
            ),
          ],
          TextSpan(
            text: '\nΣ ${d.somaLikert?.toStringAsFixed(1) ?? '—'} de ${7 * d.porCriterio.length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  Widget _erro(String e) => Tooltip(
    message: e,
    child: const Icon(Icons.error, color: CoresDecisao.excluir),
  );
}
