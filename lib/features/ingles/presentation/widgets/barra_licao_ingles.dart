import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../../curso/presentation/bloc/curso_bloc.dart';
import '../../../curso/presentation/pages/inicio_page.dart';
import '../../../curso/presentation/pages/mapa_page.dart';
import '../../../curso/presentation/pages/teoria_page.dart';
import '../../data/aulas_repo.dart';
import '../../domain/aula_professor.dart';
import '../fixacao.dart';
import '../revisao_cubit.dart';
import 'cena_visual.dart';

/// 🏠 A barra do topo da lição de inglês com a tela Início (pedido do dono, 26/out/2026: "essas informações podem
/// estar ocultas por botões no topo… no menu de hambúrguer, e um voltar para ir para o menu"): "← Início", o nome da
/// lição, o 🔁 com as frases para revisar e o ☰ com o resto — 📖 entender a lição, 🎓 a aula do professor, 🎬 o
/// ensaio mental, 📺 a historinha e 🆕 as palavras novas. A frase fica sozinha embaixo.
class BarraLicaoIngles extends StatelessWidget {
  final CursoState curso;
  final RevisaoCubit? revisao;
  final bool podeAssistir, ensaioLigado;

  /// Palavras novas da lição para conhecer antes (0 = nenhuma: o item some).
  final int novas;
  final VoidCallback onAula, onEnsaio, onHistorinha, onPalavras;

  const BarraLicaoIngles({
    super.key,
    required this.curso,
    required this.revisao,
    required this.podeAssistir,
    required this.ensaioLigado,
    required this.novas,
    required this.onAula,
    required this.onEnsaio,
    required this.onHistorinha,
    required this.onPalavras,
  });

  @override
  Widget build(BuildContext context) {
    final licao = curso.licao;
    final rv = revisao;
    return Row(children: [
      IconButton(
        key: const Key('abrir-inicio'),
        tooltip: 'Início',
        onPressed: () => abrirInicio(context),
        icon: Icon(Icons.arrow_back_rounded, color: Mixart.text),
        style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      ),
      const SizedBox(width: 10),
      if (licao.emoji.isNotEmpty) ...[Text(licao.emoji, style: const TextStyle(fontSize: 22)), const SizedBox(width: 8)],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(licao.nome, style: Mixart.display(size: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('${curso.trilha.nivel} · lição ${curso.licaoIdx + 1} de ${curso.trilha.licoes.length}',
              style: Mixart.ui(size: 11.5, color: Mixart.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
      if (rv != null)
        BlocBuilder<RevisaoCubit, RevisaoState>(
          bloc: rv,
          builder: (context, st) {
            final n = st.quantasDevidas(rv.hoje);
            if (n == 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Tooltip(
                message: '$n frases para revisar hoje',
                child: TextButton.icon(
                  key: const Key('barra-revisar'),
                  onPressed: () => abrirRevisao(context),
                  icon: Icon(Icons.replay_rounded, size: 18, color: Mixart.brand),
                  label: Text('$n', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand)),
                ),
              ),
            );
          },
        ),
      const SizedBox(width: 4),
      Badge(
        isLabelVisible: novas > 0,
        smallSize: 9,
        backgroundColor: Mixart.brand,
        child: IconButton(
          key: const Key('menu-licao'),
          tooltip: 'Mais da lição',
          onPressed: () => _abrirMenu(context),
          icon: Icon(Icons.menu_rounded, color: Mixart.text),
          style: IconButton.styleFrom(backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
      ),
    ]);
  }

  void _abrirMenu(BuildContext context) {
    final licao = curso.licao;
    final temIntro = licao.resumo.isNotEmpty || licao.cena.isNotEmpty || licao.temTeoria || CenaVisual(licao: licao).temAlgo;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Mixart.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) {
        // fecha o menu e faz a ação (na tela da lição)
        void faz(VoidCallback acao) {
          Navigator.of(sheet).pop();
          acao();
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (temIntro)
                _Item(
                  key: const Key('menu-entender'),
                  emoji: '📖',
                  titulo: 'Entenda a lição',
                  sub: 'a cena, o objetivo e a explicação em português',
                  onTap: () => faz(() => _entender(context)),
                ),
              FutureBuilder<AulaLicao?>(
                future: AulasRepo.daLicao(licao.id),
                builder: (_, snap) {
                  final aula = snap.data;
                  if (aula == null) return const SizedBox.shrink();
                  final min = (aula.segundos / 60).round().clamp(1, 15);
                  return _Item(
                    key: const Key('menu-aula'),
                    emoji: '🎓',
                    titulo: 'Aula do $nomeDoProfessor',
                    sub: '~$min min, em português: o que as frases querem dizer e como lembrar',
                    onTap: () => faz(onAula),
                  );
                },
              ),
              _Item(
                key: const Key('menu-ensaio'),
                emoji: '🎬',
                titulo: ensaioLigado ? 'Rever o ensaio mental' : 'Ensaio mental',
                sub: '20 s de cena e frases antes de digitar',
                onTap: () => faz(onEnsaio),
              ),
              if (podeAssistir)
                _Item(
                  key: const Key('menu-historinha'),
                  emoji: '📺',
                  titulo: 'Assistir a historinha',
                  sub: 'o desenho da lição, só ouvindo (não conta progresso)',
                  onTap: () => faz(onHistorinha),
                ),
              if (novas > 0)
                _Item(
                  key: const Key('menu-palavras'),
                  emoji: '🆕',
                  titulo: '$novas palavras novas nesta lição',
                  sub: 'conheça antes de começar',
                  onTap: () => faz(onPalavras),
                ),
              _Item(
                key: const Key('menu-mapa'),
                emoji: '🗺️',
                titulo: 'Mapa · trocar de lição',
                sub: 'o caminho do curso, a partir de onde você está',
                onTap: () => faz(() => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const MapaPage()))),
              ),
            ]),
          ),
        );
      },
    );
  }

  /// 📖 A cena, o objetivo e a teoria da lição, numa folha (o que ficava no topo da lição).
  void _entender(BuildContext context) {
    final licao = curso.licao;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Mixart.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('${licao.emoji} ${licao.nome}', key: const Key('entender-licao'), style: Mixart.display(size: 18)),
            const SizedBox(height: 4),
            Text('${licao.trechos.length} frases · cada uma 5×', style: Mixart.ui(size: 12, color: Mixart.textMuted)),
            if (CenaVisual(licao: licao).temAlgo) ...[const SizedBox(height: 12), CenaVisual(licao: licao)],
            if (licao.cena.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('📍 ${licao.cena}', style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.5)),
            ],
            if (licao.resumo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(licao.resumo, style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.5)),
            ],
            if (licao.temTeoria) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                key: const Key('entender-teoria'),
                onPressed: () {
                  Navigator.of(sheet).pop();
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => TeoriaPage(
                        nivel: curso.trilha.nivel, fundo: curso.trilha.fundo, licao: licao, onPraticar: () {}),
                  ));
                },
                icon: const Icon(Icons.menu_book_outlined, size: 18),
                label: const Text('Explicação em português'),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String emoji, titulo, sub;
  final VoidCallback onTap;
  const _Item({super.key, required this.emoji, required this.titulo, required this.sub, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        onTap: onTap,
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(titulo, style: Mixart.ui(size: 14.5, weight: FontWeight.w800, color: Mixart.text)),
        subtitle: Text(sub, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Mixart.radiusMd)),
      );
}
