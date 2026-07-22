import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/curriculo.dart';
import '../bloc/typing_bloc.dart';
import '../widgets/code_view.dart';
import '../widgets/console_view.dart';
import '../widgets/fundo_fase.dart';
import '../widgets/preview_ao_vivo.dart';
import '../widgets/preview_panel.dart';

/// Tela de um projeto "Mão na Massa" ou app do Teste Master: a pessoa digita
/// um programa/app completo. Ao concluir, mostra a saída (ou a prévia Flutter).
class ProjetoPage extends StatefulWidget {
  final String nivel;
  final Projeto projeto;
  final bool master;

  const ProjetoPage({super.key, required this.nivel, required this.projeto, this.master = false});

  @override
  State<ProjetoPage> createState() => _ProjetoPageState();
}

class _ProjetoPageState extends State<ProjetoPage> {
  late final TypingBloc _typing = TypingBloc()..add(TrechoCarregado(widget.projeto.cod));
  final _foco = FocusNode();

  @override
  void dispose() {
    _typing.close();
    _foco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.projeto;
    return BlocProvider.value(
      value: _typing,
      child: Scaffold(
        backgroundColor: Mixart.bg,
        body: Stack(children: [
          FundoFase(nivel: widget.nivel),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                  children: [
                    _cabecalho(context, p),
                    const SizedBox(height: 16),
                    _briefing(p),
                    const SizedBox(height: 16),
                    _areaCodigo(p),
                    const SizedBox(height: 16),
                    _BarraProjeto(),
                    const SizedBox(height: 16),
                    BlocBuilder<TypingBloc, TypingState>(
                      buildWhen: (a, b) => a.concluido != b.concluido,
                      builder: (context, st) => Column(children: [
                        if (st.concluido && p.flutter) ...[
                          PreviewPanel(trecho: p.comoTrecho),
                          const SizedBox(height: 16),
                        ],
                        ConsoleView(
                          concluido: st.concluido,
                          out: p.flutter ? '${p.out} (app compilado)' : p.out,
                          onProximo: () => Navigator.of(context).maybePop(),
                        ),
                        if (st.concluido) ...[
                          const SizedBox(height: 16),
                          _feito(context),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  /// Código + prévia ao vivo (só para apps Flutter): lado a lado no desktop,
  /// empilhado no celular.
  Widget _areaCodigo(Projeto p) {
    final code = CodeView(
      focusNode: _foco,
      ehFlutter: p.flutter,
      onAvancar: () => Navigator.of(context).maybePop(),
    );
    if (!p.flutter) return code;

    return LayoutBuilder(builder: (context, box) {
      if (box.maxWidth >= 860) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: code),
          const SizedBox(width: 16),
          PreviewAoVivo(cod: p.cod, largura: 232, altura: 360),
        ]);
      }
      return Column(children: [
        Center(child: PreviewAoVivo(cod: p.cod, largura: 210, altura: 280)),
        const SizedBox(height: 14),
        code,
      ]);
    });
  }

  Widget _cabecalho(BuildContext context, Projeto p) => Row(children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(
              backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.master ? 'TESTE MASTER' : 'MÃO NA MASSA',
                style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand).copyWith(letterSpacing: 2)),
            const SizedBox(height: 2),
            Row(children: [
              Text(p.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Flexible(child: Text(p.nome, style: Mixart.display(size: 22), overflow: TextOverflow.ellipsis)),
            ]),
          ]),
        ),
      ]);

  Widget _briefing(Projeto p) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(p.flutter ? Icons.phone_iphone : Icons.terminal, size: 18, color: Mixart.brand),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.flutter ? 'Você vai construir este app:' : 'Você vai construir este programa:',
                  style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
              const SizedBox(height: 4),
              Text(p.descricao, style: Mixart.ui(size: 13.5, color: Mixart.text).copyWith(height: 1.5)),
            ]),
          ),
        ]),
      );

  Widget _feito(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Mixart.brand,
            foregroundColor: Mixart.onBrand,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            textStyle: Mixart.ui(size: 14, weight: FontWeight.w700),
          ),
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Projeto concluído!'),
        ),
      ]);
}

class _BarraProjeto extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TypingBloc, TypingState>(
      builder: (context, st) => Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Progresso do código', style: Mixart.ui(size: 11, color: Mixart.textMuted)),
              Text('${(st.progresso * 100).round()}%', style: Mixart.ui(size: 11, color: Mixart.textMuted)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: st.progresso,
                minHeight: 8,
                backgroundColor: Mixart.surfaceHi,
                color: Mixart.brand,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
