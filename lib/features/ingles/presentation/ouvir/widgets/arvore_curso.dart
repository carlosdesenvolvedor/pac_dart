import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../curso/domain/curriculo.dart';
import '../../../../curso/domain/mapa_regras.dart';
import '../../../../curso/presentation/bloc/curso_bloc.dart';
import '../../../domain/setlist.dart';
import '../ouvir_acoes.dart';

// "Explorar o curso" do hub do Ouvir: etapa → unidade → lição, cada linha com ▶ e ➕ (as lições também com
// "Escolher frases…"). As lições trancadas mostram 🔒 e tocam do mesmo jeito. O desenho vem da tela de
// escolher as lições do Arcade (copiado, não importado: ela é de outra frente).

/// Uma etapa (A1…DEV) ou o grupo "Meus textos", com as unidades dela (índices em `trilhas`).
class _Grupo {
  final String rotulo;
  final bool proprio;
  final List<int> trilhas;
  _Grupo(this.rotulo, {this.proprio = false}) : trilhas = [];
}

List<_Grupo> _agrupar(List<Trilha> trilhas) {
  final grupos = <_Grupo>[];
  _Grupo? meus;
  for (var t = 0; t < trilhas.length; t++) {
    final tr = trilhas[t];
    if (tr.propria) {
      (meus ??= _Grupo('Meus textos', proprio: true)).trilhas.add(t);
      continue;
    }
    if (grupos.isEmpty || grupos.last.rotulo != tr.etapa) grupos.add(_Grupo(tr.etapa));
    grupos.last.trilhas.add(t);
  }
  return [...grupos, ?meus];
}

class ArvoreCurso extends StatefulWidget {
  final CursoState curso;
  const ArvoreCurso({super.key, required this.curso});

  @override
  State<ArvoreCurso> createState() => _ArvoreCursoState();
}

class _ArvoreCursoState extends State<ArvoreCurso> {
  final _abertas = <String>{};

  void _alternar(String k) => setState(() => _abertas.contains(k) ? _abertas.remove(k) : _abertas.add(k));

  @override
  Widget build(BuildContext context) {
    final st = widget.curso;
    final trilhas = st.trilhas;
    final alcance = alcanceDoMapa(trilhas, st.concluidas, (st.trilhaIdx, st.licaoIdx));
    final grupos = _agrupar(trilhas);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final g in grupos) _grupo(context, g, alcance),
    ]);
  }

  Widget _grupo(BuildContext context, _Grupo g, PosicaoMapa? alcance) {
    final st = widget.curso;
    final codigo = g.proprio ? 'meus' : ItemSetlist.codigoEtapa(g.rotulo);
    final k = 'e:$codigo';
    final aberta = _abertas.contains(k);
    var frases = 0;
    for (final t in g.trilhas) {
      for (final l in st.trilhas[t].licoes) {
        frases += l.trechos.length;
      }
    }
    final rotulo = g.rotulo.isEmpty ? 'Curso' : g.rotulo;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: aberta ? Mixart.brandDim : Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Linha(
              chave: 'arvore-etapa-$codigo',
              nivel: 0,
              aberta: aberta,
              onTap: () => _alternar(k),
              titulo: rotulo,
              estiloTitulo: Mixart.ui(size: 15, weight: FontWeight.w800, color: Mixart.text),
              subtitulo:
                  '${plural(g.trilhas.length, 'unidade', 'unidades')} · ${plural(frases, 'frase', 'frases')}',
              etiqueta: g.proprio ? 'voz do sistema' : null,
              acoes: g.proprio
                  ? const []
                  : [
                      _BotaoTocar(
                        chave: 'arvore-tocar-etapa-$codigo',
                        rotulo: 'Ouvir a etapa',
                        onTap: () =>
                            tocarItens(context, [ItemSetlist.daEtapa(g.rotulo)], titulo: 'Etapa $codigo'),
                      ),
                      BotaoPorNaSetlist(
                        key: Key('arvore-add-etapa-$codigo'),
                        redondo: false,
                        item: () => ItemSetlist.daEtapa(g.rotulo),
                      ),
                    ],
            ),
            if (aberta)
              for (final t in g.trilhas) ..._unidade(context, t, alcance),
          ]),
        ),
      ),
    );
  }

  List<Widget> _unidade(BuildContext context, int t, PosicaoMapa? alcance) {
    final st = widget.curso;
    final tr = st.trilhas[t];
    final k = 'u:${tr.baralhoId}';
    final aberta = _abertas.contains(k);
    var frases = 0;
    for (final l in tr.licoes) {
      frases += l.trechos.length;
    }
    return [
      Divider(height: 1, color: Mixart.border),
      _Linha(
        chave: 'arvore-unidade-${tr.baralhoId}',
        nivel: 1,
        aberta: aberta,
        onTap: () => _alternar(k),
        titulo: '${tr.emoji.isEmpty ? '' : '${tr.emoji}  '}${tr.nivel}',
        estiloTitulo: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text),
        subtitulo: '${plural(tr.licoes.length, 'lição', 'lições')} · ${plural(frases, 'frase', 'frases')}',
        acoes: [
          _BotaoTocar(
            chave: 'arvore-tocar-unidade-${tr.baralhoId}',
            rotulo: 'Ouvir a unidade',
            onTap: () => tocarItens(context, [ItemSetlist.daTrilha(tr)], titulo: 'Unidade: ${tr.nivel}'),
          ),
          BotaoPorNaSetlist(
            key: Key('arvore-add-unidade-${tr.baralhoId}'),
            redondo: false,
            item: () => ItemSetlist.daTrilha(tr),
          ),
        ],
      ),
      if (aberta)
        for (var l = 0; l < tr.licoes.length; l++) _licao(context, t, l, alcance),
    ];
  }

  Widget _licao(BuildContext context, int t, int l, PosicaoMapa? alcance) {
    final st = widget.curso;
    final tr = st.trilhas[t];
    final licao = tr.licoes[l];
    final trancada = estadoDoNo(
          feita: st.licaoConcluida(t, l),
          atual: t == st.trilhaIdx && l == st.licaoIdx,
          pos: (t, l),
          alcance: alcance,
          propria: tr.propria,
        ) ==
        EstadoNo.trancada;
    final id = licao.id.isEmpty ? '$t:$l' : licao.id;
    void tocar() => unawaited(tocarItens(context, [ItemSetlist.daLicao(licao)], titulo: licao.nome));
    return _Linha(
      chave: 'arvore-licao-$id',
      nivel: 2,
      onTap: tocar,
      titulo: '${licao.emoji.isEmpty ? '' : '${licao.emoji} '}${licao.nome}',
      estiloTitulo: Mixart.ui(size: 13.5, weight: FontWeight.w600, color: trancada ? Mixart.textMuted : Mixart.text),
      subtitulo: plural(licao.trechos.length, 'frase', 'frases'),
      trancada: trancada,
      acoes: [
        _BotaoTocar(chave: 'arvore-tocar-licao-$id', rotulo: 'Ouvir esta lição', onTap: tocar),
        BotaoPorNaSetlist(
          key: Key('arvore-add-licao-$id'),
          redondo: false,
          item: () => ItemSetlist.daLicao(licao),
        ),
        IconButton(
          key: Key('arvore-frases-$id'),
          tooltip: 'Escolher frases…',
          onPressed: () => escolherFrasesDaLicao(context, licao),
          icon: Icon(Icons.checklist_rounded, size: 21, color: Mixart.textMuted),
        ),
      ],
    );
  }
}

class _BotaoTocar extends StatelessWidget {
  final String chave, rotulo;
  final VoidCallback onTap;
  const _BotaoTocar({required this.chave, required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        key: Key(chave),
        tooltip: rotulo,
        onPressed: onTap,
        icon: Icon(Icons.play_circle_fill_rounded, size: 26, color: Mixart.brand),
      );
}

/// Uma linha da árvore: (chevron) título, subtítulo e as ações à direita.
class _Linha extends StatelessWidget {
  final String chave, titulo, subtitulo;
  final TextStyle estiloTitulo;
  final int nivel;

  /// null = sem chevron (a lição).
  final bool? aberta;
  final VoidCallback onTap;
  final List<Widget> acoes;
  final String? etiqueta;
  final bool trancada;

  const _Linha({
    required this.chave,
    required this.nivel,
    required this.onTap,
    required this.titulo,
    required this.estiloTitulo,
    required this.subtitulo,
    required this.acoes,
    this.aberta,
    this.etiqueta,
    this.trancada = false,
  });

  @override
  Widget build(BuildContext context) {
    // o leitor de tela sabe se a etapa/unidade está aberta; na lição, que o toque já toca
    return Semantics(
      expanded: aberta,
      onTapHint: aberta == null ? 'ouvir esta lição' : null,
      child: _corpo(),
    );
  }

  Widget _corpo() {
    return InkWell(
      key: Key(chave),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: EdgeInsets.fromLTRB(8.0 + nivel * 12, 4, 4, 4),
          child: Row(children: [
            if (aberta case final a?)
              Icon(a ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 22, color: Mixart.textMuted)
            else
              const SizedBox(width: 6),
            const SizedBox(width: 6),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(titulo, maxLines: 2, overflow: TextOverflow.ellipsis, style: estiloTitulo.copyWith(height: 1.3)),
                const SizedBox(height: 2),
                Wrap(spacing: 6, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text(subtitulo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
                  if (trancada)
                    Tooltip(
                      message: 'Lição à frente — pode ouvir à vontade',
                      child: Semantics(
                        label: 'Lição à frente — pode ouvir à vontade',
                        excludeSemantics: true,
                        child: Text('🔒 à frente', style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
                      ),
                    ),
                  if (etiqueta case final e?)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Mixart.surfaceHi,
                        borderRadius: BorderRadius.circular(Mixart.radiusChip),
                        border: Border.all(color: Mixart.border),
                      ),
                      child: Text(e, style: Mixart.ui(size: 10.5, weight: FontWeight.w700, color: Mixart.textMuted)),
                    ),
                ]),
              ]),
            ),
            ...acoes,
          ]),
        ),
      ),
    );
  }
}
