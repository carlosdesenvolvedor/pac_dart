import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/fila_ouvir.dart';
import '../../domain/setlist.dart';
import 'escolher_setlist_sheet.dart';
import 'ouvir_acoes.dart';
import 'setlists_cubit.dart';

/// O ícone de cada tipo de item.
String iconeDoItem(TipoItem t) => switch (t) {
      TipoItem.frase => '💬',
      TipoItem.trecho => '✂️',
      TipoItem.licao => '📘',
      TipoItem.trilha => '🧭',
      TipoItem.etapa => '🏔',
      TipoItem.curso => '🌍',
    };

/// Uma setlist: nome editável, resumo, ▶ Tocar e os itens (arrastar para reordenar, ✕ ou deslizar para
/// remover com Desfazer, ⋯ com Tocar daqui / Mover para cima / Mover para baixo / Remover). Tocar num item
/// toca a setlist a partir dele.
class SetlistPage extends StatefulWidget {
  final String setlistId;
  const SetlistPage({super.key, required this.setlistId});

  @override
  State<SetlistPage> createState() => _SetlistPageState();
}

class _SetlistPageState extends State<SetlistPage> {
  final _nome = TextEditingController();
  final _foco = FocusNode();

  /// Itens que acabaram de sair por deslize: somem já (o Dismissible exige), antes do cubit avisar.
  final _saindo = <String>{};

  SetlistsCubit? get _setlists => SetlistsCubit.de(context);

  @override
  void initState() {
    super.initState();
    _foco.addListener(() {
      if (!_foco.hasFocus) _salvarNome();
    });
  }

  @override
  void dispose() {
    _foco.dispose();
    _nome.dispose();
    super.dispose();
  }

  void _salvarNome() {
    final s = _setlists?.state.porId[widget.setlistId];
    final n = _nome.text.trim();
    if (s == null) return;
    if (n.isEmpty) {
      _nome.text = s.nome;
      return;
    }
    if (n != s.nome) unawaited(_setlists!.renomear(s.id, n));
  }

  void _remover(Setlist s, ItemSetlist item) {
    final setlists = _setlists!;
    final indice = s.itens.indexWhere((i) => i.id == item.id);
    if (indice < 0) return;
    unawaited(setlists.remover(s.id, item.id));
    avisarRemovido(context, () => unawaited(setlists.restaurar(s.id, item, indice)));
  }

  void _mover(Setlist s, int de, int para) {
    if (de == para || para < 0 || para >= s.itens.length) return;
    unawaited(_setlists!.mover(s.id, de, para));
  }

  Future<void> _escolherEmoji(Setlist s) async {
    final e = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Mixart.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
      builder: (folha) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in emojisSetlist)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => Navigator.of(folha).pop(e),
                child: Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: e == s.emoji ? Mixart.brandSub : Mixart.surfaceHi,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: e == s.emoji ? Mixart.brand : Mixart.border),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 24)),
                ),
              ),
          ]),
        ),
      ),
    );
    if (e != null && e != s.emoji) await _setlists!.renomear(s.id, s.nome, emoji: e);
  }

  @override
  Widget build(BuildContext context) {
    final setlists = _setlists;
    if (setlists == null) return Scaffold(backgroundColor: Mixart.bg);
    return BlocBuilder<SetlistsCubit, BancoSetlists>(
      bloc: setlists,
      builder: (context, banco) {
        final s = banco.porId[widget.setlistId];
        if (s == null || s.apagada) return _semSetlist(context);
        if (!_foco.hasFocus && _nome.text != s.nome) _nome.text = s.nome;
        _saindo.removeWhere((id) => !s.itens.any((i) => i.id == id));
        final itens = [for (final i in s.itens) if (!_saindo.contains(i.id)) i];
        final fila = filaDosItens(context, s.itens);
        final fora = fila.indisponiveis.toSet();
        // frases e segundos por item (itemIdx = posição em s.itens)
        final frases = List<int>.filled(s.itens.length, 0);
        final segundos = List<double>.filled(s.itens.length, 0);
        for (final f in fila.faixas) {
          if (f.itemIdx >= 0 && f.itemIdx < s.itens.length) {
            frases[f.itemIdx]++;
            segundos[f.itemIdx] += f.segundos;
          }
        }
        return Scaffold(
          backgroundColor: Mixart.bg,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ReorderableListView.builder(
                  key: const Key('setlist-itens'),
                  buildDefaultDragHandles: false,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  header: _cabecalho(context, s, fila),
                  footer: itens.isEmpty
                      ? Padding(
                          key: const Key('setlist-vazia'),
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                              'Sua setlist está vazia. Toque em ➕ numa frase, lição ou unidade enquanto estuda.',
                              style: Mixart.ui(size: 13.5, color: Mixart.textMuted).copyWith(height: 1.5)),
                        )
                      : null,
                  itemCount: itens.length,
                  onReorder: (de, para) {
                    if (para > de) para -= 1;
                    int real(int i) => s.itens.indexWhere((x) => x.id == itens[i].id);
                    _mover(s, real(de), real(para));
                  },
                  itemBuilder: (context, i) {
                    final item = itens[i];
                    final k = s.itens.indexOf(item);
                    return _LinhaItem(
                      key: ValueKey(item.id),
                      item: item,
                      indice: i,
                      total: itens.length,
                      indisponivel: fora.contains(item.id),
                      frases: k < 0 ? 0 : frases[k],
                      segundos: k < 0 ? 0 : segundos[k],
                      onTocar: () => unawaited(tocarSetlist(context, s, item: k)),
                      onRemover: () => _remover(s, item),
                      onDeslizou: () {
                        setState(() => _saindo.add(item.id));
                        _remover(s, item);
                      },
                      onMover: (passo) => _mover(s, k, k + passo),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _semSetlist(BuildContext context) => Scaffold(
        backgroundColor: Mixart.bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _voltar(context),
              const SizedBox(height: 20),
              Text('Esta setlist não existe mais.', style: Mixart.ui(size: 14, color: Mixart.textMuted)),
            ]),
          ),
        ),
      );

  Widget _voltar(BuildContext context) => IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
        style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      );

  Widget _cabecalho(BuildContext context, Setlist s, FilaOuvir fila) {
    final resumo = [
      plural(s.itens.length, 'item', 'itens'),
      plural(fila.faixas.length, 'frase', 'frases'),
      if (fila.faixas.isNotEmpty) '~${formatarDuracao(fila.segundosTotal)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _voltar(context),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: 'Trocar o emoji',
            child: InkWell(
              key: const Key('setlist-emoji'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => _escolherEmoji(s),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(child: Text(s.emoji, style: const TextStyle(fontSize: 26))),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              key: const Key('setlist-nome'),
              controller: _nome,
              focusNode: _foco,
              maxLength: 60,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _salvarNome(),
              style: Mixart.display(size: 21),
              cursorColor: Mixart.brand,
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: 'Nome da setlist',
                hintStyle: Mixart.display(size: 21, color: Mixart.textHint),
                border: InputBorder.none,
                suffixIcon: Icon(Icons.edit_rounded, size: 16, color: Mixart.textFaint),
                suffixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text(resumo, key: const Key('setlist-resumo'), style: Mixart.ui(size: 13, color: Mixart.textMuted)),
        const SizedBox(height: 12),
        // ▶ Tocar e 📺 Assistir lado a lado; em 360 px o Wrap quebra a linha em vez de estourar
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            key: const Key('setlist-tocar'),
            onPressed: fila.faixas.isEmpty ? null : () => unawaited(tocarSetlist(context, s)),
            icon: Icon(Icons.play_arrow_rounded,
                size: 22, color: fila.faixas.isEmpty ? Mixart.textFaint : Mixart.onBrand),
            label: Text('Tocar',
                style: Mixart.ui(
                    size: 15, weight: FontWeight.w800, color: fila.faixas.isEmpty ? Mixart.textFaint : Mixart.onBrand)),
            style: FilledButton.styleFrom(
              minimumSize: const Size(140, 48),
              backgroundColor: Mixart.brand,
              disabledBackgroundColor: Mixart.surfaceHi,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
            ),
          ),
          OutlinedButton(
            key: const Key('setlist-assistir'),
            onPressed: fila.faixas.isEmpty ? null : () => unawaited(assistirSetlist(context, s)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(140, 48),
              side: BorderSide(color: Mixart.border),
              backgroundColor: Mixart.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
            ),
            child: Text('📺 Assistir',
                style: Mixart.ui(
                    size: 15, weight: FontWeight.w800, color: fila.faixas.isEmpty ? Mixart.textFaint : Mixart.text)),
          ),
        ]),
      ]),
    );
  }
}

class _LinhaItem extends StatelessWidget {
  final ItemSetlist item;
  final int indice, total, frases;
  final double segundos;
  final bool indisponivel;
  final VoidCallback onTocar, onRemover, onDeslizou;

  /// -1 = sobe uma posição; +1 = desce uma.
  final ValueChanged<int> onMover;

  const _LinhaItem({
    super.key,
    required this.item,
    required this.indice,
    required this.total,
    required this.frases,
    required this.segundos,
    required this.indisponivel,
    required this.onTocar,
    required this.onRemover,
    required this.onDeslizou,
    required this.onMover,
  });

  @override
  Widget build(BuildContext context) {
    final sub = indisponivel
        ? 'Item indisponível (saiu do curso)'
        : '${plural(frases, 'frase', 'frases')}${frases > 0 ? ' · ~${formatarDuracao(segundos)}' : ''}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Dismissible(
        key: ValueKey('deslizar-${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDeslizou(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Mixart.danger.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Icon(Icons.delete_outline_rounded, color: Mixart.danger),
        ),
        child: Material(
          color: Mixart.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            side: BorderSide(color: Mixart.border),
          ),
          child: InkWell(
            key: Key('setlist-item-${item.id}'),
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd)),
            onTap: indisponivel ? null : onTocar,
            child: Opacity(
              opacity: indisponivel ? .55 : 1,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                child: Row(children: [
                  ReorderableDragStartListener(
                    index: indice,
                    child: Semantics(
                      label: 'Arrastar para reordenar',
                      child: SizedBox(
                        width: 40,
                        height: 48,
                        child: Icon(Icons.drag_indicator_rounded, size: 20, color: Mixart.textFaint),
                      ),
                    ),
                  ),
                  Text(iconeDoItem(item.tipo), style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.rotulo,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text).copyWith(height: 1.3)),
                      const SizedBox(height: 2),
                      Text(sub,
                          style: Mixart.ui(
                              size: 12,
                              weight: indisponivel ? FontWeight.w700 : FontWeight.w500,
                              color: indisponivel ? Mixart.danger : Mixart.textMuted)),
                    ]),
                  ),
                  if (indisponivel)
                    TextButton(
                      key: Key('setlist-remover-${item.id}'),
                      onPressed: onRemover,
                      style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
                      child: Text('Remover', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.danger)),
                    )
                  else
                    IconButton(
                      key: Key('setlist-remover-${item.id}'),
                      tooltip: 'Remover',
                      onPressed: onRemover,
                      icon: Icon(Icons.close_rounded, size: 20, color: Mixart.textMuted),
                    ),
                  PopupMenuButton<String>(
                    key: Key('setlist-item-menu-${item.id}'),
                    tooltip: 'Mais opções',
                    color: Mixart.surfaceHi,
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: Mixart.textMuted),
                    onSelected: (a) {
                      switch (a) {
                        case 'tocar':
                          onTocar();
                        case 'cima':
                          onMover(-1);
                        case 'baixo':
                          onMover(1);
                        case 'remover':
                          onRemover();
                      }
                    },
                    itemBuilder: (_) => [
                      if (!indisponivel) _opcao('tocar', 'Tocar daqui'),
                      _opcao('cima', 'Mover para cima', ativa: indice > 0),
                      _opcao('baixo', 'Mover para baixo', ativa: indice < total - 1),
                      _opcao('remover', 'Remover', cor: Mixart.danger),
                    ],
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _opcao(String v, String rotulo, {bool ativa = true, Color? cor}) => PopupMenuItem(
        value: v,
        enabled: ativa,
        child: Text(rotulo, style: Mixart.ui(size: 14, color: ativa ? (cor ?? Mixart.text) : Mixart.textFaint)),
      );
}
