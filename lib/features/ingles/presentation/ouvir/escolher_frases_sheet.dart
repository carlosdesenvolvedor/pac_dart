import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../curso/domain/curriculo.dart';
import '../../domain/baralhos.dart';

/// O que a folha das frases devolve: as frases marcadas (na ordem da lição) e se é para tocar já
/// ("▶ Ouvir só estas") ou pôr na setlist ("➕ Pôr {n} frases na setlist").
typedef EscolhaFrases = ({bool tocar, List<Trecho> escolhidas});

/// A folha "Escolher frases…" de uma lição: caixinhas com o inglês, o português e um 🔊 para ouvir antes.
Future<EscolhaFrases?> mostrarEscolherFrases(BuildContext c, Licao l, {void Function(String en)? ouvir}) =>
    showModalBottomSheet<EscolhaFrases>(
      context: c,
      backgroundColor: Mixart.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Mixart.radiusLg))),
      builder: (_) => FolhaEscolherFrases(licao: l, ouvir: ouvir),
    );

class FolhaEscolherFrases extends StatefulWidget {
  final Licao licao;
  final void Function(String en)? ouvir;
  const FolhaEscolherFrases({super.key, required this.licao, this.ouvir});

  @override
  State<FolhaEscolherFrases> createState() => _FolhaEscolherFrasesState();
}

class _FolhaEscolherFrasesState extends State<FolhaEscolherFrases> {
  final _marcadas = <int>{};

  List<Trecho> get _escolhidas => [
        for (var i = 0; i < widget.licao.trechos.length; i++)
          if (_marcadas.contains(i)) widget.licao.trechos[i],
      ];

  void _fechar(bool tocar) => Navigator.of(context).pop<EscolhaFrases>((tocar: tocar, escolhidas: _escolhidas));

  @override
  Widget build(BuildContext context) {
    final l = widget.licao;
    final mq = MediaQuery.of(context);
    final n = _marcadas.length;
    final todas = n == l.trechos.length && n > 0;
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
                Expanded(
                  child: Text('${l.emoji.isEmpty ? '' : '${l.emoji} '}${l.nome}',
                      maxLines: 2, overflow: TextOverflow.ellipsis, style: Mixart.display(size: 18)),
                ),
                TextButton(
                  key: const Key('frases-todas'),
                  onPressed: () => setState(() {
                    if (todas) {
                      _marcadas.clear();
                    } else {
                      _marcadas.addAll([for (var i = 0; i < l.trechos.length; i++) i]);
                    }
                  }),
                  child: Text(todas ? 'Desmarcar' : 'Marcar todas',
                      style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.brand)),
                ),
              ]),
              Text('Escolher frases…', style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
            ]),
          ),
          Flexible(
            child: ListView.builder(
              key: const Key('frases-lista'),
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
              itemCount: l.trechos.length,
              itemBuilder: (context, i) {
                final f = l.trechos[i];
                final marcada = _marcadas.contains(i);
                // a caixinha e o texto viram um nó só no leitor de tela ("<EN> <PT>, caixa, marcada"); o 🔊 fica
                // de fora, com a ação dele
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    child: MergeSemantics(
                      child: InkWell(
                        key: Key('frase-${chaveDaFrase(f)}'),
                        onTap: () => setState(() => marcada ? _marcadas.remove(i) : _marcadas.add(i)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Checkbox(
                              value: marcada,
                              activeColor: Mixart.brand,
                              checkColor: Mixart.onBrand,
                              side: BorderSide(color: Mixart.textMuted, width: 1.6),
                              onChanged: (v) =>
                                  setState(() => (v ?? false) ? _marcadas.add(i) : _marcadas.remove(i)),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(f.cod,
                                      style: Mixart.ui(size: 14.5, weight: FontWeight.w700, color: Mixart.text)
                                          .copyWith(height: 1.3)),
                                  if (f.dicaPlana.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(f.dicaPlana,
                                        style:
                                            Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.3)),
                                  ],
                                ]),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                  if (widget.ouvir != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IconButton(
                        tooltip: 'Ouvir',
                        onPressed: () => widget.ouvir!(f.cod),
                        icon: Icon(Icons.volume_up_rounded, size: 20, color: Mixart.brand),
                      ),
                    ),
                ]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Mixart.border))),
            child: Wrap(spacing: 10, runSpacing: 8, alignment: WrapAlignment.end, children: [
              OutlinedButton.icon(
                key: const Key('frases-tocar'),
                onPressed: n == 0 ? null : () => _fechar(true),
                icon: Icon(Icons.play_arrow_rounded, size: 20, color: n == 0 ? Mixart.textFaint : Mixart.brand),
                label: Text('Ouvir só estas',
                    style: Mixart.ui(
                        size: 13.5, weight: FontWeight.w700, color: n == 0 ? Mixart.textFaint : Mixart.text)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  side: BorderSide(color: Mixart.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
                ),
              ),
              FilledButton.icon(
                key: const Key('frases-add'),
                onPressed: n == 0 ? null : () => _fechar(false),
                icon: Icon(Icons.playlist_add_rounded, size: 20, color: n == 0 ? Mixart.textFaint : Mixart.onBrand),
                label: Text(n == 1 ? 'Pôr 1 frase na setlist' : 'Pôr $n frases na setlist',
                    style: Mixart.ui(
                        size: 13.5, weight: FontWeight.w800, color: n == 0 ? Mixart.textFaint : Mixart.onBrand)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: Mixart.brand,
                  disabledBackgroundColor: Mixart.surfaceHi,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusChip)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
