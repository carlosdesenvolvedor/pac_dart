import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../../ingles/presentation/widgets/elenco_ingles.dart';
import '../domain/cenario.dart';
import '../domain/nivel_conversa.dart';
import 'conversa_page.dart';
import 'ia_cubit.dart';
import 'preferencias_conversa.dart';
import 'widgets/bolha_conversa.dart' show corFundoRosto;

/// Lê `assets/ingles/cenarios.json` (a lista vazia se faltar ou estiver estragado).
Future<List<Cenario>> carregarCenarios() async {
  try {
    return cenariosDeJson(jsonDecode(await rootBundle.loadString('assets/ingles/cenarios.json')));
  } catch (_) {
    return const [];
  }
}

/// A lista de situações da Conversa com IA, por etapa, e o nível da conversa (automático, pelo progresso,
/// ou escolhido). Cada uma abre uma conversa com um personagem do palco.
class CenariosPage extends StatefulWidget {
  /// Testes dão a lista pronta (o relógio falso do testWidgets não espera I/O de asset).
  final Future<List<Cenario>> Function()? carregador;
  const CenariosPage({super.key, this.carregador});

  @override
  State<CenariosPage> createState() => _CenariosPageState();
}

class _CenariosPageState extends State<CenariosPage> {
  late final Future<List<Cenario>> _futuro = (widget.carregador ?? carregarCenarios)();

  /// O nível escolhido ('' = automático).
  String _escolhido = '';

  @override
  void initState() {
    super.initState();
    PreferenciasConversa.nivel().then((n) {
      if (mounted && n != _escolhido) setState(() => _escolhido = n);
    });
  }

  /// O nível pelo progresso (a fronteira do curso); sem o curso na árvore, A1.
  String _nivelDoAluno() {
    try {
      final st = context.read<CursoBloc>().state;
      return nivelDoAluno(trilhas: st.trilhas, concluidas: st.concluidas);
    } catch (_) {
      return 'A1';
    }
  }

  void _escolher(String n) {
    setState(() => _escolhido = n);
    PreferenciasConversa.salvarNivel(n);
  }

  @override
  Widget build(BuildContext context) {
    final aluno = _nivelDoAluno();
    final nivel = nivelDaConversa(aluno: aluno, escolhido: _escolhido);
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 48), children: [
              Row(children: [
                IconButton(
                  tooltip: 'Voltar',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                  style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                ),
                const SizedBox(width: 12),
                const Text('💬', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Text('Conversa com IA', style: Mixart.display(size: 22), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 10),
              Text(
                  'Escolha uma situação: um personagem faz o outro papel e você responde em inglês, digitando ou falando. '
                  'A cada fala, o Prof. Dash mostra o jeito certo e explica em português.',
                  style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
              const SizedBox(height: 12),
              _niveis(aluno),
              const SizedBox(height: 10),
              BlocBuilder<IaCubit, IaState>(
                builder: (_, ia) => Text(
                    ia.carregado
                        ? '${ia.restantes == 1 ? 'Resta 1 uso hoje' : 'Restam ${ia.restantes} usos hoje'} · cada fala usa 1'
                        : '',
                    key: const Key('cenarios-restantes'),
                    style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.textFaint)),
              ),
              const SizedBox(height: 6),
              FutureBuilder<List<Cenario>>(
                future: _futuro,
                builder: (context, snap) {
                  if (!snap.hasData) return Padding(padding: const EdgeInsets.all(30), child: Center(child: CircularProgressIndicator(color: Mixart.brand)));
                  final lista = snap.data!;
                  if (lista.isEmpty) {
                    return Text('Não encontrei os cenários agora. Tente de novo mais tarde.', style: Mixart.ui(size: 13, color: Mixart.textMuted));
                  }
                  final etapas = <String>[for (final c in lista) c.etapa]..sort();
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    for (final e in etapas.toSet()) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(2, 12, 0, 6),
                        child: Text(e, style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.2)),
                      ),
                      for (final c in lista.where((c) => c.etapa == e)) _CartaoCenario(cenario: c, nivel: nivel),
                    ],
                  ]);
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _niveis(String aluno) {
    Widget chip(Key k, String rotulo, String valor) => ChoiceChip(
          key: k,
          label: Text(rotulo, style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: _escolhido == valor ? Mixart.onBrand : Mixart.text)),
          selected: _escolhido == valor,
          showCheckmark: false,
          selectedColor: Mixart.brand,
          backgroundColor: Mixart.surfaceHi,
          side: BorderSide(color: _escolhido == valor ? Mixart.brand : Mixart.border),
          visualDensity: VisualDensity.compact,
          onSelected: (_) => _escolher(valor),
        );
    return Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Text('Seu nível nas conversas:', style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted)),
      ),
      Tooltip(
        message: 'Vem do seu progresso no curso',
        child: chip(const Key('nivel-conversa-auto'), 'Automático ($aluno)', ''),
      ),
      for (final n in niveisConversa) chip(Key('nivel-conversa-$n'), n, n),
    ]);
  }
}

class _CartaoCenario extends StatelessWidget {
  final Cenario cenario;

  /// O nível em que a conversa vai acontecer.
  final String nivel;
  const _CartaoCenario({required this.cenario, required this.nivel});

  @override
  Widget build(BuildContext context) {
    final c = cenario;
    final rosto = ElencoIngles.de(c.quem);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        key: Key('cenario-${c.id}'),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ConversaPage(cenario: c, nivel: nivel))),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Mixart.surface,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
          ),
          child: Row(children: [
            if (rosto != null)
              ClipOval(child: ColoredBox(color: corFundoRosto, child: RostoPersonagem(aparencia: rosto, tamanho: 44)))
            else
              SizedBox.square(dimension: 44, child: Center(child: Text(c.emoji, style: const TextStyle(fontSize: 26)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${c.emoji} ${c.titulo}', style: Mixart.display(size: 16)),
                const SizedBox(height: 3),
                Text('com ${c.nomePersonagem} · ${c.objetivo}', style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.4)),
                const SizedBox(height: 6),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  _Selo(texto: '~${c.maxTurnos} falas'),
                  if (acimaDoNivel(c.etapa, nivel)) _Selo(chave: Key('acima-${c.id}'), texto: '⬆ acima do seu nível', destaque: true),
                ]),
              ]),
            ),
            Icon(Icons.chevron_right, color: Mixart.textMuted),
          ]),
        ),
      ),
    );
  }
}

class _Selo extends StatelessWidget {
  final Key? chave;
  final String texto;
  final bool destaque;
  const _Selo({this.chave, required this.texto, this.destaque = false});

  @override
  Widget build(BuildContext context) => Container(
        key: chave,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: destaque ? Mixart.brandSub : Mixart.surfaceHi,
          border: Border.all(color: destaque ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(texto, style: Mixart.ui(size: 11, weight: FontWeight.w700, color: destaque ? Mixart.brand : Mixart.textMuted)),
      );
}
