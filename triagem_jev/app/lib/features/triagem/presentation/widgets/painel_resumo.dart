import 'package:flutter/material.dart';

import '../../domain/custo.dart';
import '../../domain/metricas.dart';
import '../../domain/orquestrador_triagem.dart';
import 'formato.dart';

/// Métricas contra o gabarito, custo/tempo e a comparação dos três cenários com projeção.
class PainelResumo extends StatelessWidget {
  final RodadaTriagem rodada;
  const PainelResumo({super.key, required this.rodada});

  @override
  Widget build(BuildContext context) {
    final decididos = rodada.resultados.where((r) => r.humana != null).length;
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _Cartao(
          titulo: 'Métricas vs gabarito',
          subtitulo: 'Amostra pequena: números ilustrativos, não conclusivos.',
          filho: _TabelaMetricas({
            'Etapa 1 (modelo de decisão)': rodada.metricasEtapa1,
            'Sistema (decisão + LLM)': rodada.metricasSistema,
            'Final ($decididos/${rodada.resultados.length} revisados)': rodada.metricasFinal,
          }),
        ),
        _Cartao(
          titulo: 'Cenários (uma rodada, ${rodada.resultados.length} estudos)',
          subtitulo: 'Medido = chamadas reais. Estimado = calculado a partir do medido ou do tamanho do prompt.',
          filho: _TabelaCenarios(rodada.cenarios),
        ),
      ],
    );
  }
}

class _Cartao extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final Widget filho;
  const _Cartao({required this.titulo, required this.subtitulo, required this.filho});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(titulo, style: t.titleMedium),
            Text(subtitulo, style: t.bodySmall),
            const SizedBox(height: 8),
            SingleChildScrollView(scrollDirection: Axis.horizontal, child: filho),
          ],
        ),
      ),
    );
  }
}

class _TabelaMetricas extends StatelessWidget {
  final Map<String, Metricas> linhas;
  const _TabelaMetricas(this.linhas);

  @override
  Widget build(BuildContext context) => DataTable(
    headingRowHeight: 36,
    dataRowMinHeight: 32,
    dataRowMaxHeight: 40,
    columns: const [
      DataColumn(label: Text('')),
      DataColumn(label: Text('Recall'), tooltip: 'Dos que deveriam entrar, quantos seguiram. A mais importante.'),
      DataColumn(label: Text('Precisão')),
      DataColumn(label: Text('Acurácia')),
      DataColumn(label: Text('Kappa')),
      DataColumn(label: Text('VP/FP/FN/VN')),
      DataColumn(label: Text('Redução'), tooltip: 'Estudos excluídos na etapa 1 (sem leitura atenta).'),
    ],
    rows: [
      for (final MapEntry(:key, :value) in linhas.entries)
        DataRow(
          cells: [
            DataCell(Text(key)),
            DataCell(Text(pct(value.recall), style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(Text(pct(value.precisao))),
            DataCell(Text(pct(value.acuracia))),
            DataCell(Text(value.kappa?.toStringAsFixed(2) ?? '—')),
            DataCell(Text('${value.vp}/${value.fp}/${value.fn}/${value.vn}')),
            DataCell(Text(pct(value.reducaoTrabalho))),
          ],
        ),
    ],
  );
}

class _TabelaCenarios extends StatelessWidget {
  final ComparacaoCenarios comparacao;
  const _TabelaCenarios(this.comparacao);

  @override
  Widget build(BuildContext context) => DataTable(
    headingRowHeight: 36,
    dataRowMinHeight: 32,
    dataRowMaxHeight: 56,
    columns: [
      const DataColumn(label: Text('Cenário')),
      const DataColumn(label: Text('Custo')),
      const DataColumn(label: Text('Tempo')),
      const DataColumn(label: Text('Chamadas LLM')),
      for (final n in ComparacaoCenarios.tamanhosProjecao)
        for (final r in ComparacaoCenarios.rodadasProjecao) DataColumn(label: Text('$n est. × $r rod.')),
    ],
    rows: [
      for (final c in comparacao.cenarios)
        DataRow(
          cells: [
            DataCell(
              Tooltip(
                message: c.observacao,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(c.nome),
                    const SizedBox(width: 6),
                    Chip(
                      label: Text(c.medido ? 'medido' : 'estimado'),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: c.medido ? Colors.green.shade50 : Colors.orange.shade50,
                    ),
                  ],
                ),
              ),
            ),
            DataCell(Text(usd(c.custo))),
            DataCell(Text(duracao(c.ms))),
            DataCell(Text('${c.chamadasLlm}')),
            for (final n in ComparacaoCenarios.tamanhosProjecao)
              for (final r in ComparacaoCenarios.rodadasProjecao) DataCell(Text(usd(c.projecao(n, rodadas: r)))),
          ],
        ),
    ],
  );
}
