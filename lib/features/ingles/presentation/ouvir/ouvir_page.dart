import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../curso/presentation/bloc/curso_bloc.dart';
import '../../domain/fila_ouvir.dart';
import '../../domain/setlist.dart';
import 'escolher_setlist_sheet.dart';
import 'ouvir_acoes.dart';
import 'ouvir_cubit.dart';
import 'ouvir_state.dart';
import 'setlists_cubit.dart';
import 'widgets/arvore_curso.dart';

/// "🎧 Ouvir": o curso na ordem (Continuar / Da minha lição atual / Do começo), as setlists do aluno e o
/// curso para explorar (etapa → unidade → lição, com ▶ e ➕ em cada linha).
class OuvirPage extends StatelessWidget {
  const OuvirPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ouvir = OuvirCubit.de(context);
    final setlists = SetlistsCubit.de(context);
    if (ouvir == null || setlists == null) return Scaffold(backgroundColor: Mixart.bg);
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: SafeArea(
        child: BlocBuilder<CursoBloc, CursoState>(
          builder: (context, curso) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                key: const Key('ouvir-lista'),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  Row(children: [
                    IconButton(
                      tooltip: 'Voltar',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
                      style: IconButton.styleFrom(
                          backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('🎧 Ouvir', style: Mixart.display(size: 22))),
                  ]),
                  const SizedBox(height: 10),
                  Text('Escute as lições sem digitar — no ônibus, na academia, lavando a louça.',
                      style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
                  const SizedBox(height: 14),
                  // com o player ligado, um caminho para o "Tocando agora" de DENTRO da rota: o mini-player
                  // fica fora do Navigator e o Tab não chega nele
                  BlocBuilder<OuvirCubit, OuvirState>(
                    bloc: ouvir,
                    buildWhen: (a, b) => a.status != b.status || a.fonte != b.fonte || a.indice != b.indice,
                    builder: (context, st) => _TocandoAgora(st: st),
                  ),
                  // "Continuar" muda quando o player pausa/fecha (a posição é gravada nessas horas)
                  BlocBuilder<OuvirCubit, OuvirState>(
                    bloc: ouvir,
                    buildWhen: (a, b) => a.status != b.status,
                    builder: (context, _) => _CartaoCurso(curso: curso, ouvir: ouvir),
                  ),
                  const _Rotulo('MINHAS SETLISTS'),
                  BlocBuilder<SetlistsCubit, BancoSetlists>(
                    bloc: setlists,
                    builder: (context, banco) => _Setlists(banco: banco, setlists: setlists),
                  ),
                  const _Rotulo('EXPLORAR O CURSO'),
                  ArvoreCurso(curso: curso),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Rotulo extends StatelessWidget {
  final String texto;
  const _Rotulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 0, 8),
        child: Semantics(
          header: true,
          child: Text(texto,
              style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.2)),
        ),
      );
}

/// "Curso na ordem": {n} frases · ~{t}, com Continuar (quando há onde parou), Da minha lição atual e Do começo.
class _CartaoCurso extends StatelessWidget {
  final CursoState curso;
  final OuvirCubit ouvir;
  const _CartaoCurso({required this.curso, required this.ouvir});

  @override
  Widget build(BuildContext context) {
    final fila = filaDoCurso(context);
    final faixas = fila.faixas;
    final pos = ouvir.posicaoSalva('curso');
    final parou = pos == null || faixas.isEmpty ? null : fila.indiceDaChave(pos.chave, dica: pos.i);
    final fParou = parou == null ? null : faixas[parou.clamp(0, faixas.length - 1)];
    // a lição atual do palco (fora do curso → o começo)
    var atual = -1;
    if (curso.trilhas.isNotEmpty && curso.trilhaIdx < curso.trilhas.length) {
      final id = curso.chave(curso.trilhaIdx, curso.licaoIdx);
      atual = faixas.indexWhere((f) => f.licaoId == id);
    }
    final total = faixas.isEmpty ? '' : '${plural(faixas.length, 'frase', 'frases')} · ~${formatarDuracao(fila.segundosTotal)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🌍', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Curso na ordem', style: Mixart.display(size: 18)),
              if (total.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(total, key: const Key('ouvir-curso-total'), style: Mixart.ui(size: 12.5, color: Mixart.textMuted)),
              ],
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        if (fParou != null) ...[
          _BotaoCurso(
            chave: 'ouvir-curso-continuar',
            principal: true,
            icone: Icons.play_arrow_rounded,
            rotulo: 'Continuar',
            subtitulo: 'Parou em: ${fParou.licaoEmoji.isEmpty ? '' : '${fParou.licaoEmoji} '}${fParou.licaoNome}'
                '${fParou.etapa.isEmpty ? '' : ' (${ItemSetlist.codigoEtapa(fParou.etapa)})'}',
            onTap: () => tocarCurso(context, inicio: parou!),
          ),
          const SizedBox(height: 8),
        ],
        Wrap(spacing: 8, runSpacing: 8, children: [
          _BotaoCurso(
            chave: 'ouvir-curso-atual',
            principal: fParou == null,
            icone: Icons.play_arrow_rounded,
            rotulo: 'Da minha lição atual',
            onTap: () => tocarCurso(context, inicio: atual < 0 ? 0 : atual),
          ),
          _BotaoCurso(
            chave: 'ouvir-curso-inicio',
            icone: Icons.replay_rounded,
            rotulo: 'Do começo',
            onTap: () => tocarCurso(context),
          ),
        ]),
      ]),
    );
  }
}

/// "▶ Tocando agora: «{fonte}»" — abre o player cheio (some com o player parado).
class _TocandoAgora extends StatelessWidget {
  final OuvirState st;
  const _TocandoAgora({required this.st});

  @override
  Widget build(BuildContext context) {
    if (!st.ativo) return const SizedBox.shrink();
    final titulo = st.fonte?.titulo ?? '';
    final rotulo = switch (st.status) {
      StatusOuvir.pausado => 'Pausado',
      StatusOuvir.acabou => 'Acabou',
      _ => 'Tocando agora',
    };
    final f = st.atual;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _BotaoCurso(
        chave: 'ouvir-tocando-agora',
        principal: true,
        icone: st.status == StatusOuvir.tocando ? Icons.graphic_eq_rounded : Icons.play_arrow_rounded,
        rotulo: titulo.isEmpty ? rotulo : '$rotulo: «$titulo»',
        subtitulo: f == null || f.en.isEmpty ? 'Abrir o player' : f.en,
        onTap: () => unawaited(abrirTocando(context)),
      ),
    );
  }
}

class _BotaoCurso extends StatelessWidget {
  final String chave, rotulo;
  final String? subtitulo;
  final IconData icone;
  final bool principal;
  final VoidCallback onTap;
  const _BotaoCurso({
    required this.chave,
    required this.rotulo,
    required this.icone,
    required this.onTap,
    this.subtitulo,
    this.principal = false,
  });

  @override
  Widget build(BuildContext context) {
    final frente = principal ? Mixart.onBrand : Mixart.text;
    return Material(
      color: principal ? Mixart.brand : Mixart.surfaceHi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        side: BorderSide(color: principal ? Mixart.brand : Mixart.border),
      ),
      child: InkWell(
        key: Key(chave),
        onTap: onTap,
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(mainAxisSize: subtitulo == null ? MainAxisSize.min : MainAxisSize.max, children: [
              Icon(icone, size: 22, color: frente),
              const SizedBox(width: 8),
              Flexible(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(rotulo, style: Mixart.ui(size: 14, weight: FontWeight.w800, color: frente)),
                  if (subtitulo case final s?)
                    Text(s,
                        key: Key('$chave-sub'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Mixart.ui(size: 12, color: principal ? Mixart.onBrand : Mixart.textMuted)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// As setlists (cartões com ▶ e ⋯), "＋ Nova setlist" e o estado vazio.
class _Setlists extends StatelessWidget {
  final BancoSetlists banco;
  final SetlistsCubit setlists;
  const _Setlists({required this.banco, required this.setlists});

  Future<void> _nova(BuildContext context) async {
    final r = await pedirNomeSetlist(context);
    if (r == null) return;
    await setlists.criar(r.$1, emoji: r.$2);
  }

  @override
  Widget build(BuildContext context) {
    final lista = banco.visiveis;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (lista.isEmpty)
        Container(
          key: const Key('ouvir-setlists-vazio'),
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Mixart.surface,
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            border: Border.all(color: Mixart.border),
          ),
          child: Text('Monte sua setlist: toque em ➕ numa frase, lição ou unidade enquanto estuda.',
              style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.45)),
        ),
      for (final s in lista) _CartaoSetlist(setlist: s, setlists: setlists),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: const Key('ouvir-nova-setlist'),
          onPressed: () => _nova(context),
          style: TextButton.styleFrom(minimumSize: const Size(0, 48)),
          icon: Icon(Icons.add_rounded, color: Mixart.brand),
          label: Text('Nova setlist', style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.brand)),
        ),
      ),
    ]);
  }
}

class _CartaoSetlist extends StatelessWidget {
  final Setlist setlist;
  final SetlistsCubit setlists;
  const _CartaoSetlist({required this.setlist, required this.setlists});

  Future<void> _menu(BuildContext context, String acao) async {
    final s = setlist;
    if (acao == 'renomear') {
      final r = await pedirNomeSetlist(context, titulo: 'Renomear', nome: s.nome, emoji: s.emoji, botao: 'Renomear');
      if (r != null) await setlists.renomear(s.id, r.$1, emoji: r.$2);
    } else if (acao == 'apagar') {
      final ok = await confirmarApagarSetlist(context, s.nome);
      if (ok) await setlists.apagar(s.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = setlist;
    final fila = filaDosItens(context, s.itens);
    final resumo = [
      plural(s.itens.length, 'item', 'itens'),
      plural(fila.faixas.length, 'frase', 'frases'),
      if (fila.faixas.isNotEmpty) '~${formatarDuracao(fila.segundosTotal)}',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Mixart.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          side: BorderSide(color: Mixart.border),
        ),
        child: InkWell(
          key: Key('setlist-${s.id}'),
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusLg)),
          onTap: () => abrirSetlist(context, s.id),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
            child: Row(children: [
              Text(s.emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.nome, maxLines: 1, overflow: TextOverflow.ellipsis, style: Mixart.display(size: 16)),
                  const SizedBox(height: 2),
                  Text(resumo, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                ]),
              ),
              IconButton(
                key: Key('setlist-tocar-${s.id}'),
                tooltip: 'Tocar',
                onPressed: s.itens.isEmpty ? null : () => unawaited(tocarSetlist(context, s)),
                icon: Icon(Icons.play_circle_fill_rounded,
                    size: 30, color: s.itens.isEmpty ? Mixart.textFaint : Mixart.brand),
              ),
              PopupMenuButton<String>(
                key: Key('setlist-menu-${s.id}'),
                tooltip: 'Mais opções',
                color: Mixart.surfaceHi,
                icon: Icon(Icons.more_vert_rounded, color: Mixart.textMuted),
                onSelected: (a) => _menu(context, a),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'renomear', child: Text('Renomear', style: Mixart.ui(size: 14, color: Mixart.text))),
                  PopupMenuItem(
                      value: 'apagar', child: Text('Apagar', style: Mixart.ui(size: 14, color: Mixart.danger))),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// "Apagar «{nome}»? As frases continuam no curso; só a lista some." — true se confirmou.
Future<bool> confirmarApagarSetlist(BuildContext context, String nome) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (d) => AlertDialog(
      backgroundColor: Mixart.surface,
      title: Text('Apagar «$nome»?', style: Mixart.display(size: 18)),
      content: Text('As frases continuam no curso; só a lista some.',
          style: Mixart.ui(size: 14, color: Mixart.textMuted)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(d).pop(false),
          child: Text('Cancelar', style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.textMuted)),
        ),
        TextButton(
          key: const Key('setlist-apagar-confirmar'),
          onPressed: () => Navigator.of(d).pop(true),
          child: Text('Apagar', style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.danger)),
        ),
      ],
    ),
  );
  return r ?? false;
}
