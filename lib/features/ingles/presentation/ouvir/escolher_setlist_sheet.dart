import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/setlist.dart';
import 'setlists_cubit.dart';

/// O que a folha "Pôr em qual setlist?" devolve além do id de uma setlist.
abstract final class EscolhaSetlist {
  /// "▶ Tocar agora" (não põe em setlist nenhuma).
  static const tocarAgora = '\u0000tocar-agora';
}

/// Os emojis que uma setlist pode ter.
const emojisSetlist = ['🎧', '🚌', '🏋️', '🍳', '🌙', '☕', '🚗', '⭐'];

/// Abre a folha "Pôr em qual setlist?": as setlists (a última usada já marcada), "＋ Nova setlist" e, com
/// [tocarAgora], "▶ Tocar agora". [atual] (o "Trocar" do aviso) fica fora da lista. Devolve o id escolhido
/// (ou criado), [EscolhaSetlist.tocarAgora], ou null se fechou.
Future<String?> mostrarEscolherSetlist(
  BuildContext c, {
  required SetlistsCubit setlists,
  bool tocarAgora = false,
  String? atual,
}) =>
    showModalBottomSheet<String>(
      context: c,
      backgroundColor: Mixart.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
      builder: (_) => _FolhaEscolherSetlist(setlists: setlists, tocarAgora: tocarAgora, atual: atual),
    );

/// Pede nome e emoji (criar ou renomear uma setlist). Devolve (nome, emoji) ou null.
Future<(String, String)?> pedirNomeSetlist(
  BuildContext c, {
  String titulo = 'Nova setlist',
  String nome = '',
  String emoji = '🎧',
  String botao = 'Criar',
}) =>
    showModalBottomSheet<(String, String)>(
      context: c,
      backgroundColor: Mixart.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
      builder: (folha) => Padding(
        padding: EdgeInsets.fromLTRB(18, 14, 18, 18 + MediaQuery.viewInsetsOf(folha).bottom),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _Pegador(),
            Text(titulo, style: Mixart.display(size: 19)),
            const SizedBox(height: 12),
            FormNovaSetlist(
              nome: nome,
              emoji: emoji,
              botao: botao,
              onPronto: (n, e) => Navigator.of(folha).pop((n, e)),
            ),
          ]),
        ),
      ),
    );

class _Pegador extends StatelessWidget {
  const _Pegador();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(color: Mixart.border, borderRadius: BorderRadius.circular(2)),
        ),
      );
}

class _FolhaEscolherSetlist extends StatefulWidget {
  final SetlistsCubit setlists;
  final bool tocarAgora;
  final String? atual;
  const _FolhaEscolherSetlist({required this.setlists, required this.tocarAgora, required this.atual});

  @override
  State<_FolhaEscolherSetlist> createState() => _FolhaEscolherSetlistState();
}

class _FolhaEscolherSetlistState extends State<_FolhaEscolherSetlist> {
  bool _criando = false;
  bool _ocupado = false;

  Future<void> _criar(String nome, String emoji) async {
    if (_ocupado) return;
    setState(() => _ocupado = true);
    final id = await widget.setlists.criar(nome, emoji: emoji);
    if (mounted) Navigator.of(context).pop(id);
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * .85),
        child: SafeArea(
          top: false,
          child: BlocBuilder<SetlistsCubit, BancoSetlists>(
            bloc: widget.setlists,
            builder: (context, banco) {
              final lista = [for (final s in banco.visiveis) if (s.id != widget.atual) s];
              final marcada = lista.any((s) => s.id == banco.ultimaUsada)
                  ? banco.ultimaUsada
                  : (lista.isEmpty ? null : lista.first.id);
              final criando = _criando || lista.isEmpty;
              return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const _Pegador(),
                    Text(widget.atual == null ? 'Pôr em qual setlist?' : 'Trocar para qual setlist?',
                        style: Mixart.display(size: 19)),
                  ]),
                ),
                Flexible(
                  child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(6, 4, 6, 12), children: [
                    if (widget.tocarAgora)
                      ListTile(
                        key: const Key('escolher-tocar-agora'),
                        minTileHeight: 52,
                        leading: Icon(Icons.play_circle_fill_rounded, color: Mixart.brand, size: 28),
                        title: Text('Tocar agora',
                            style: Mixart.ui(size: 14.5, weight: FontWeight.w700, color: Mixart.text)),
                        onTap: () => Navigator.of(context).pop(EscolhaSetlist.tocarAgora),
                      ),
                    // tocar numa linha já escolhe (a última usada vem marcada: é para onde o ➕ rápido iria)
                    for (final s in lista)
                      Semantics(
                        selected: s.id == marcada,
                        child: ListTile(
                          key: Key('escolher-setlist-${s.id}'),
                          minTileHeight: 56,
                          leading: Text(s.emoji, style: const TextStyle(fontSize: 22)),
                          title: Text(s.nome,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Mixart.ui(size: 14.5, weight: FontWeight.w700, color: Mixart.text)),
                          subtitle: Text(
                              '${s.itens.length} ${s.itens.length == 1 ? 'item' : 'itens'}'
                              '${s.id == banco.ultimaUsada ? ' · a última usada' : ''}',
                              style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                          trailing: Icon(
                            s.id == marcada ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                            color: s.id == marcada ? Mixart.brand : Mixart.textFaint,
                          ),
                          onTap: () => Navigator.of(context).pop(s.id),
                        ),
                      ),
                    if (!criando)
                      ListTile(
                        key: const Key('escolher-nova-setlist'),
                        minTileHeight: 52,
                        leading: Icon(Icons.add_rounded, color: Mixart.brand),
                        title: Text('Nova setlist',
                            style: Mixart.ui(size: 14.5, weight: FontWeight.w700, color: Mixart.brand)),
                        onTap: () => setState(() => _criando = true),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Nova setlist',
                              style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.textMuted)),
                          const SizedBox(height: 8),
                          FormNovaSetlist(onPronto: _criar, autofocus: lista.isNotEmpty),
                        ]),
                      ),
                  ]),
                ),
              ]);
            },
          ),
        ),
      ),
    );
  }
}

/// Nome + emoji de uma setlist, com o botão [botao] ("Criar" / "Renomear").
class FormNovaSetlist extends StatefulWidget {
  final String nome, emoji, botao;
  final bool autofocus;
  final void Function(String nome, String emoji) onPronto;

  const FormNovaSetlist({
    super.key,
    this.nome = '',
    this.emoji = '🎧',
    this.botao = 'Criar',
    this.autofocus = true,
    required this.onPronto,
  });

  @override
  State<FormNovaSetlist> createState() => _FormNovaSetlistState();
}

class _FormNovaSetlistState extends State<FormNovaSetlist> {
  late final _nome = TextEditingController(text: widget.nome);
  late String _emoji = widget.emoji;

  @override
  void dispose() {
    _nome.dispose();
    super.dispose();
  }

  void _pronto() {
    final n = _nome.text.trim();
    if (n.isEmpty) return;
    widget.onPronto(n.length > 60 ? n.substring(0, 60) : n, _emoji);
  }

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        key: const Key('nova-setlist-nome'),
        controller: _nome,
        autofocus: widget.autofocus,
        maxLength: 60,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _pronto(),
        onChanged: (_) => setState(() {}),
        style: Mixart.ui(size: 15, color: Mixart.text),
        cursorColor: Mixart.brand,
        decoration: InputDecoration(
          labelText: 'Nome da setlist',
          hintText: 'Ex.: Inglês no ônibus',
          counterText: '',
          labelStyle: Mixart.ui(size: 13, color: Mixart.textMuted),
          hintStyle: Mixart.ui(size: 14, color: Mixart.textHint),
          filled: true,
          fillColor: Mixart.surfaceHi,
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Mixart.border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Mixart.brand, width: 1.4)),
        ),
      ),
      const SizedBox(height: 10),
      Wrap(spacing: 4, runSpacing: 4, children: [
        for (var i = 0; i < emojisSetlist.length; i++)
          Semantics(
            button: true,
            selected: emojisSetlist[i] == _emoji,
            label: 'Emoji ${emojisSetlist[i]}',
            child: InkWell(
              key: Key('nova-setlist-emoji-$i'),
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _emoji = emojisSetlist[i]),
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: emojisSetlist[i] == _emoji ? Mixart.brandSub : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: emojisSetlist[i] == _emoji ? Mixart.brand : Mixart.border),
                ),
                child: Text(emojisSetlist[i], style: const TextStyle(fontSize: 20)),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 12),
      FilledButton(
        key: const Key('nova-setlist-criar'),
        onPressed: _nome.text.trim().isEmpty ? null : _pronto,
        style: FilledButton.styleFrom(
          backgroundColor: Mixart.brand,
          foregroundColor: Mixart.onBrand,
          disabledBackgroundColor: Mixart.surfaceHi,
          disabledForegroundColor: Mixart.textFaint,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
        ),
        child: Text(widget.botao,
            style: Mixart.ui(
                size: 14.5,
                weight: FontWeight.w800,
                color: _nome.text.trim().isEmpty ? Mixart.textFaint : Mixart.onBrand)),
      ),
    ]);
  }
}
