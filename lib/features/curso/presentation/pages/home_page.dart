import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/curriculo.dart';
import '../bloc/curso_bloc.dart';
import '../bloc/typing_bloc.dart';
import '../bloc/voz_cubit.dart';
import '../widgets/code_view.dart';
import '../widgets/console_view.dart';
import '../widgets/dica_banner.dart';
import '../widgets/fundo_fase.dart';
import '../widgets/hud.dart';
import '../widgets/menu_trilhas.dart';
import 'teoria_page.dart';
import '../widgets/preview_panel.dart';
import '../widgets/victory_overlay.dart';

/// Tela única do PAC·DART: HUD, menus, palco (dica + código + console +
/// prévia) e overlay de vitória.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<CursoBloc, CursoState>(
        // sempre que o trecho muda, recarrega o motor e narra a dica
        listenWhen: (a, b) =>
            a.status != b.status ||
            a.trilhaIdx != b.trilhaIdx ||
            a.licaoIdx != b.licaoIdx ||
            a.trechoIdx != b.trechoIdx,
        listener: (context, st) {
          if (st.status != CursoStatus.pronto) return;
          context.read<TypingBloc>().add(TrechoCarregado(st.trecho.cod));
          context.read<VozCubit>().falar(st.trecho.dicaPlana);
        },
        child: BlocBuilder<CursoBloc, CursoState>(
          builder: (context, curso) {
            if (curso.status == CursoStatus.carregando) {
              return Center(child: CircularProgressIndicator(color: Mixart.brand));
            }
            if (curso.status == CursoStatus.erro) {
              return Center(
                  child: Text('Não consegui carregar o currículo 😢',
                      style: Mixart.ui(size: 14, color: Mixart.textMuted)));
            }
            return Stack(children: [
              FundoFase(nivel: curso.trilha.nivel),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 980),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
                    children: [
                      const Hud(),
                      const SizedBox(height: 18),
                      const MenuTrilhas(),
                      const SizedBox(height: 16),
                      _Palco(curso: curso),
                      const SizedBox(height: 24),
                      Text(
                        'Enter pula linha · a indentação é comida sozinha · Backspace corrige · clique no código pra focar',
                        textAlign: TextAlign.center,
                        style: Mixart.ui(size: 11.5, color: Mixart.textFaint).copyWith(height: 1.7),
                      ),
                    ],
                  ),
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }
}

class _Palco extends StatefulWidget {
  final CursoState curso;
  const _Palco({required this.curso});

  @override
  State<_Palco> createState() => _PalcoState();
}

class _PalcoState extends State<_Palco> {
  /// Foco da área de digitação — devolvido ao fechar o popup da prévia.
  final _focoDigitacao = FocusNode();

  CursoState get curso => widget.curso;

  @override
  void dispose() {
    _focoDigitacao.dispose();
    super.dispose();
  }

  void _abrePreview(BuildContext context) {
    final cursoBloc = context.read<CursoBloc>();
    showDialog<void>(
      context: context,
      barrierColor: const Color(0xCC010101),
      builder: (dialogContext) => Focus(
        autofocus: true,
        onKeyEvent: (node, e) {
          if (e is! KeyDownEvent) return KeyEventResult.ignored;
          if (e.logicalKey == LogicalKeyboardKey.enter ||
              e.logicalKey == LogicalKeyboardKey.numpadEnter) {
            Navigator.of(dialogContext).pop();
            cursoBloc.add(const TrechoAvancado());
            return KeyEventResult.handled;
          }
          if (e.logicalKey == LogicalKeyboardKey.escape) {
            Navigator.of(dialogContext).pop();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              PreviewPanel(trecho: curso.trecho),
              const SizedBox(height: 12),
              Text('↵ Enter para o próximo · Esc fecha',
                  style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.brand)),
            ]),
          ),
        ),
      ),
    ).then((_) {
      // popup fechou (Enter, Esc ou clique fora): foco volta pro código
      if (mounted) _focoDigitacao.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        boxShadow: const [BoxShadow(color: Colors.black87, blurRadius: 60, offset: Offset(0, 24), spreadRadius: -30)],
      ),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (curso.trechoIdx == 0 && (curso.licao.resumo.isNotEmpty || curso.licao.temTeoria)) ...[
            _IntroLicao(licao: curso.licao, nivel: curso.trilha.nivel),
            const SizedBox(height: 12),
          ],
          DicaBanner(trecho: curso.trecho),
          const SizedBox(height: 16),
          CodeView(
            focusNode: _focoDigitacao,
            ehFlutter: curso.ehFlutter,
            onAvancar: () => context.read<CursoBloc>().add(const TrechoAvancado()),
            vitoria: curso.vitoria,
            onProximaLicao: () => context.read<CursoBloc>().add(const ProximaLicaoPedida()),
          ),
          const SizedBox(height: 16),
          _BarraProgresso(curso: curso),
          const SizedBox(height: 16),
          BlocConsumer<TypingBloc, TypingState>(
            listenWhen: (a, b) => !a.concluido && b.concluido,
            listener: (context, typing) {
              // prévia abre como popup na frente — sem precisar rolar
              if (curso.ehFlutter) _abrePreview(context);
            },
            buildWhen: (a, b) => a.concluido != b.concluido,
            builder: (context, typing) => ConsoleView(
              concluido: typing.concluido,
              out: curso.trecho.out,
              onProximo: () => context.read<CursoBloc>().add(const TrechoAvancado()),
            ),
          ),
        ]),
        if (curso.vitoria) const VictoryOverlay(),
      ]),
    );
  }
}

/// Introdução da lição (resumo + acesso à teoria), no primeiro exercício.
class _IntroLicao extends StatelessWidget {
  final Licao licao;
  final String nivel;
  const _IntroLicao({required this.licao, required this.nivel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(licao.emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(licao.nome, style: Mixart.display(size: 15)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Mixart.surfaceHi,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${licao.trechos.length} exercícios',
                    style: Mixart.ui(size: 10, weight: FontWeight.w600, color: Mixart.textMuted)),
              ),
            ]),
            if (licao.resumo.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(licao.resumo, style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.5)),
            ],
            if (licao.temTeoria) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => TeoriaPage(nivel: nivel, licao: licao, onPraticar: () {}),
                )),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.menu_book_outlined, size: 14, color: Mixart.brand),
                    const SizedBox(width: 6),
                    Text('Ler a teoria (Nivelamento)',
                        style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
                  ]),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _BarraProgresso extends StatelessWidget {
  final CursoState curso;
  const _BarraProgresso({required this.curso});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: BlocBuilder<TypingBloc, TypingState>(
          builder: (context, typing) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Trecho', style: Mixart.ui(size: 11, color: Mixart.textMuted)),
              Text('${curso.trechoIdx + 1} / ${curso.licao.trechos.length}',
                  style: Mixart.ui(size: 11, color: Mixart.textMuted)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (curso.trechoIdx + typing.progresso) / curso.licao.trechos.length,
                minHeight: 8,
                backgroundColor: Mixart.surfaceHi,
                color: Mixart.brand,
              ),
            ),
          ]),
        ),
      ),
      const SizedBox(width: 14),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Mixart.text,
          side: BorderSide(color: Mixart.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: Mixart.ui(size: 13),
        ),
        onPressed: () => context.read<TypingBloc>().add(const TrechoReiniciado()),
        icon: const Icon(Icons.refresh, size: 15),
        label: const Text('Recomeçar'),
      ),
    ]);
  }
}
