import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/mixart.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../data/voz_ingles.dart';
import '../domain/dicionario.dart';
import '../domain/palavras_novas.dart';
import '../domain/roteiro_treino.dart';
import 'palavras_cubit.dart';
import 'treino_palavras.dart';

/// "🎯 Escolher palavras" de uma lição: a folha com TODAS as palavras das frases dela (as novas com 🆕)
/// para a pessoa marcar só as que quer estudar, e o treino de palavras abre só com elas (as outras da
/// lição viram opções erradas). [marcada]: a palavra que já vem marcada (o "🎯 Treinar" do balão da
/// palavra). [voz]: a do 🔊 ao marcar (e a do treino); null = uma nova.
///
/// Devolve o resultado do treino (null: fora do inglês, nada escolhido ou saiu antes de terminar).
Future<ResultadoTreino?> escolherPalavrasParaTreinar(
  BuildContext context,
  Licao licao, {
  String? marcada,
  VozIngles? voz,
}) async {
  final cubit = PalavrasCubit.de(context);
  if (cubit == null) return null;
  List<Trilha> trilhas = const [];
  try {
    trilhas = context.read<CursoBloc>().state.trilhas;
  } catch (_) {}
  final mensageiro = ScaffoldMessenger.maybeOf(context);
  final ind = cubit.state.indice ?? await cubit.prepararIndice(trilhas);
  if (ind == null || !context.mounted) return null;
  final palavras = ind.palavrasParaEstudar(licao);
  if (palavras.isEmpty) {
    mensageiro?.showSnackBar(const SnackBar(content: Text('Esta lição não tem palavras para treinar sozinhas.')));
    return null;
  }
  final falar = voz ?? VozIngles();
  final escolhidas = await showModalBottomSheet<List<PalavraNova>>(
    context: context,
    backgroundColor: Mixart.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
    builder: (_) => FolhaEscolherPalavras(
      licao: licao,
      palavras: palavras,
      novas: {for (final p in ind.novasDe(licao.id)) p.chave},
      marcadas: {if (marcada != null) Dicionario.normalizar(marcada)},
      ouvir: (en) => unawaited(falar.falar(en)),
    ),
  );
  if (escolhidas == null || escolhidas.isEmpty || !context.mounted) return null;
  final chaves = {for (final p in escolhidas) p.chave};
  return abrirTreinoPalavras(
    context,
    escolhidas,
    titulo: licao.nome,
    voz: falar,
    reservaExtra: [for (final p in palavras) if (!chaves.contains(p.chave)) p],
  );
}

/// A folha "🎯 Escolher palavras": as palavras da lição como fichas (inglês em cima, português
/// embaixo); tocar marca/desmarca (e fala a palavra ao marcar). "Só as novas" e "Marcar todas" ajudam;
/// "Treinar N palavras" devolve as marcadas, na ordem da lição.
class FolhaEscolherPalavras extends StatefulWidget {
  final Licao licao;
  final List<PalavraNova> palavras;

  /// As chaves das palavras novas da lição (ganham o 🆕).
  final Set<String> novas;

  /// As chaves que já vêm marcadas.
  final Set<String> marcadas;

  final void Function(String en)? ouvir;

  const FolhaEscolherPalavras({
    super.key,
    required this.licao,
    required this.palavras,
    this.novas = const {},
    this.marcadas = const {},
    this.ouvir,
  });

  @override
  State<FolhaEscolherPalavras> createState() => _FolhaEscolherPalavrasState();
}

class _FolhaEscolherPalavrasState extends State<FolhaEscolherPalavras> {
  late final Set<String> _marcadas = {
    for (final p in widget.palavras)
      if (widget.marcadas.contains(p.chave)) p.chave,
  };

  void _alternar(PalavraNova p) {
    setState(() {
      if (!_marcadas.remove(p.chave)) {
        _marcadas.add(p.chave);
        widget.ouvir?.call(p.en);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.licao;
    final mq = MediaQuery.of(context);
    final n = _marcadas.length;
    final todas = n == widget.palavras.length;
    final novas = [for (final p in widget.palavras) if (widget.novas.contains(p.chave)) p.chave];
    final soNovas = novas.isNotEmpty && n == novas.length && novas.every(_marcadas.contains);
    final corBotao = n == 0 ? Mixart.textFaint : Mixart.onBrand;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: mq.size.height * .88),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 4),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: Mixart.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(children: [
                Expanded(child: Text('🎯 Escolher palavras', style: Mixart.display(size: 18))),
                TextButton(
                  key: const Key('palavras-todas'),
                  onPressed: () => setState(() {
                    if (todas) {
                      _marcadas.clear();
                    } else {
                      _marcadas.addAll([for (final p in widget.palavras) p.chave]);
                    }
                  }),
                  child: Text(todas ? 'Desmarcar' : 'Marcar todas',
                      style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
                ),
              ]),
              Text(
                '${l.emoji.isEmpty ? '' : '${l.emoji} '}${l.nome} · toque nas palavras que você quer estudar: '
                'o treino usa só elas.',
                style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.35),
              ),
              if (novas.isNotEmpty) ...[
                const SizedBox(height: 8),
                ActionChip(
                  key: const Key('palavras-so-novas'),
                  onPressed: () => setState(() {
                    _marcadas
                      ..clear()
                      ..addAll(novas);
                  }),
                  backgroundColor: soNovas ? Mixart.brandDim : Mixart.surfaceHi,
                  side: BorderSide(color: soNovas ? Mixart.brand : Mixart.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
                  label: Text('🆕 Só as novas (${novas.length})',
                      style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.text)),
                ),
              ],
            ]),
          ),
          Flexible(
            child: SingleChildScrollView(
              key: const Key('palavras-lista'),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in widget.palavras)
                  _Ficha(
                    palavra: p,
                    nova: widget.novas.contains(p.chave),
                    marcada: _marcadas.contains(p.chave),
                    onTap: () => _alternar(p),
                  ),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Mixart.border))),
            child: FilledButton.icon(
              key: const Key('palavras-treinar'),
              onPressed: n == 0
                  ? null
                  : () => Navigator.of(context).pop<List<PalavraNova>>(
                      [for (final p in widget.palavras) if (_marcadas.contains(p.chave)) p]),
              icon: Icon(Icons.track_changes_rounded, size: 20, color: corBotao),
              label: Text(
                  n == 0
                      ? 'Marque as palavras'
                      : n == 1
                          ? 'Treinar 1 palavra'
                          : 'Treinar $n palavras',
                  style: Mixart.ui(size: 14, weight: FontWeight.w800, color: corBotao)),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 50),
                backgroundColor: Mixart.brand,
                disabledBackgroundColor: Mixart.surfaceHi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Uma palavra da folha: o inglês, a tradução curta embaixo e, marcada, o ✓ e a borda da marca.
class _Ficha extends StatelessWidget {
  final PalavraNova palavra;
  final bool nova, marcada;
  final VoidCallback onTap;

  const _Ficha({required this.palavra, required this.nova, required this.marcada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = palavra;
    return Semantics(
      button: true,
      selected: marcada,
      label: '${p.en}, ${p.pt}${nova ? ', nova' : ''}',
      excludeSemantics: true,
      child: Material(
        color: marcada ? Mixart.brandDim : Mixart.surfaceHi,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: marcada ? Mixart.brand : Mixart.border, width: marcada ? 2 : 1),
        ),
        child: InkWell(
          key: Key('palavra-${p.chave}'),
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (marcada) ...[
                Icon(Icons.check_circle_rounded, size: 18, color: Mixart.brand),
                const SizedBox(width: 6),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('${p.en}${nova ? ' 🆕' : ''}',
                      style: Mixart.mono(size: 15, weight: FontWeight.w700, color: Mixart.text)),
                  Text(p.pt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
