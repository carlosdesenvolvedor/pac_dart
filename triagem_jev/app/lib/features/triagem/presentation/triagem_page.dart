import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/util/salvar_texto.dart';
import '../data/arquivos_triagem.dart';
import 'triagem_cubit.dart';
import 'widgets/painel_resumo.dart';
import 'widgets/tabela_estudos.dart';

/// Escolhe um arquivo JSON e devolve o conteúdo (null = cancelou).
typedef SeletorTexto = Future<String?> Function();

Future<String?> seletorDeJsonDoSistema() async {
  final f = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['json']);
  if (f == null) return null;
  return const Utf8Decoder(allowMalformed: true).convert(await f.readAsBytes());
}

/// A tela única do protótipo: carregar → rodar → revisar → exportar.
class TriagemPage extends StatelessWidget {
  final SeletorTexto seletor;
  const TriagemPage({super.key, this.seletor = seletorDeJsonDoSistema});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TriagemCubit, TriagemState>(
      listenWhen: (a, b) => b.erro != null && a.erro != b.erro,
      listener: (context, s) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.erro!)));
        context.read<TriagemCubit>().limparErro();
      },
      builder: (context, s) {
        final cubit = context.read<TriagemCubit>();
        final rodando = s.status == StatusTriagem.rodando;
        return Scaffold(
          appBar: AppBar(
            title: Text(s.projeto?.nome ?? 'Triagem com modelo de decisão + LLM'),
            bottom: rodando
                ? const PreferredSize(preferredSize: Size.fromHeight(4), child: LinearProgressIndicator())
                : null,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: rodando
                        ? null
                        : () async {
                            final texto = await seletor();
                            if (texto != null) cubit.carregarArquivo(texto);
                          },
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Carregar arquivo'),
                  ),
                  OutlinedButton.icon(
                    onPressed: rodando ? null : cubit.carregarExemplo,
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Usar exemplo'),
                  ),
                  FilledButton.icon(
                    onPressed: s.projeto == null || rodando ? null : cubit.rodar,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Rodar triagem'),
                  ),
                  _Interruptor(
                    rotulo: s.modoReal ? 'Modelos reais' : 'Simulado',
                    dica: s.realDisponivel
                        ? 'Ligado: chama Jev e LLM pelo Worker (gasta crédito). Desligado: heurística local, sem custo.'
                        : 'Sem WORKER_URL: só o modo simulado. Veja o LEIA-ME.',
                    valor: s.modoReal,
                    aoMudar: rodando || !s.realDisponivel ? null : cubit.alternarModoReal,
                  ),
                  _Interruptor(
                    rotulo: 'Teste de estabilidade',
                    dica: 'Roda cada estudo de novo com a ordem das opções invertida (dobra as chamadas da etapa 1).',
                    valor: s.config.testeEstabilidade,
                    aoMudar: rodando ? null : cubit.alternarEstabilidade,
                  ),
                  if (s.rodada != null && !rodando) ...[
                    TextButton(onPressed: cubit.aceitarSugestoes, child: const Text('Aceitar sugestões pendentes')),
                    TextButton.icon(
                      onPressed: () => _salvar(context, 'triagem.json', ArquivosTriagem.exportarJson(s.rodada!)),
                      icon: const Icon(Icons.download),
                      label: const Text('JSON'),
                    ),
                    TextButton.icon(
                      onPressed: () => _salvar(context, 'triagem.csv', ArquivosTriagem.exportarCsv(s.rodada!)),
                      icon: const Icon(Icons.download),
                      label: const Text('CSV'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              _Limites(estado: s),
              if (s.etapa.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(s.etapa)),
              const SizedBox(height: 12),
              if (s.projeto == null)
                const _Vazio()
              else if (s.rodada == null)
                Text(
                  '${s.projeto!.estudos.length} estudos e ${s.projeto!.criterios.length} critérios carregados.\n\n'
                  '${s.projeto!.criteriosTexto}',
                )
              else ...[
                if (!rodando) PainelResumo(rodada: s.rodada!),
                const SizedBox(height: 16),
                Card(
                  child: TabelaEstudos(
                    resultados: s.rodada!.resultados,
                    mostrarEstabilidade: s.rodada!.config.testeEstabilidade,
                    aoDecidir: cubit.decidirHumano,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'O pesquisador decide no final. Isto é uma hipótese a medir, não um resultado: a amostra é pequena.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  void _salvar(BuildContext context, String nome, String conteudo) {
    if (salvarTexto(nome, conteudo)) return;
    Clipboard.setData(ClipboardData(text: conteudo));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$nome copiado para a área de transferência.')));
  }
}

class _Interruptor extends StatelessWidget {
  final String rotulo;
  final String dica;
  final bool valor;
  final ValueChanged<bool>? aoMudar;
  const _Interruptor({required this.rotulo, required this.dica, required this.valor, required this.aoMudar});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: dica,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Switch(value: valor, onChanged: aoMudar),
        Text(rotulo),
      ],
    ),
  );
}

/// Os dois limites da regra de encaminhamento, ajustáveis antes de rodar.
class _Limites extends StatelessWidget {
  final TriagemState estado;
  const _Limites({required this.estado});

  @override
  Widget build(BuildContext context) {
    final c = estado.config;
    final cubit = context.read<TriagemCubit>();
    final travado = estado.status == StatusTriagem.rodando;
    return Wrap(
      spacing: 24,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Excluir abaixo de ${c.limiteExcluir.toStringAsFixed(2)}'),
        SizedBox(
          width: 180,
          child: Slider(
            value: c.limiteExcluir,
            divisions: 20,
            onChanged: travado ? null : (v) => cubit.ajustarLimites(excluir: v),
          ),
        ),
        Text('Incluir a partir de ${c.limiteIncluir.toStringAsFixed(2)}'),
        SizedBox(
          width: 180,
          child: Slider(
            value: c.limiteIncluir,
            divisions: 20,
            onChanged: travado ? null : (v) => cubit.ajustarLimites(incluir: v),
          ),
        ),
        const Text('Entre os dois: incerto (vai para o LLM e para o pesquisador).'),
      ],
    );
  }
}

class _Vazio extends StatelessWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Text('Carregue um arquivo de estudos (JSON) ou use o exemplo para começar.', textAlign: TextAlign.center),
    ),
  );
}
