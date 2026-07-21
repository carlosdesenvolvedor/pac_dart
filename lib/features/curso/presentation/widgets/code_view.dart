import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/syntax/tokenizer.dart';
import '../../../../core/theme/mixart.dart';
import '../bloc/typing_bloc.dart';
import 'pacman.dart';

/// A "tela" de digitação: código com destaque de sintaxe, Pac-Man sobre o
/// caractere atual e um TextField invisível capturando o teclado
/// (inclusive acentos/IME — ver PAC-DART.md §5, armadilha nº 2).
class CodeView extends StatefulWidget {
  /// Chamado quando o usuário aperta Enter com o trecho concluído.
  final VoidCallback onAvancar;

  /// Foco externo opcional (para devolver o foco após popups).
  final FocusNode? focusNode;
  const CodeView({super.key, required this.onAvancar, this.focusNode});

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late final FocusNode _foco = widget.focusNode ?? FocusNode();
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _foco.onKeyEvent = _teclaControle;
    _ctrl.addListener(_processaTexto);
    WidgetsBinding.instance.addPostFrameCallback((_) => _foco.requestFocus());
  }

  void _processaTexto() {
    final txt = _ctrl.text;
    if (txt.isEmpty) return;
    final bloc = context.read<TypingBloc>();
    for (final ch in txt.characters) {
      bloc.add(TeclaDigitada(ch == '\r' ? '\n' : ch));
    }
    _ctrl.clear();
  }

  KeyEventResult _teclaControle(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final bloc = context.read<TypingBloc>();
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      bloc.add(const BackspaceApertado());
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (bloc.state.concluido) {
        widget.onAvancar();
      } else {
        bloc.add(const TeclaDigitada('\n'));
      }
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _foco.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _foco.requestFocus(),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Mixart.bg,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          child: Stack(
            children: [
              // filete amarelo à esquerda
              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2, color: Mixart.brandDim)),
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 24, 24, 24),
                child: BlocBuilder<TypingBloc, TypingState>(
                  builder: (context, st) => LayoutBuilder(
                    builder: (context, box) => _codigo(st, box.maxWidth),
                  ),
                ),
              ),
              // TextField invisível, sempre focado
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  child: TextField(
                    focusNode: _foco,
                    controller: _ctrl,
                    autofocus: true,
                    maxLines: 1,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    onTapOutside: (_) => _foco.requestFocus(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _codigo(TypingState st, double maxWidth) {
    if (st.chars.isEmpty) return const SizedBox(height: 60);
    final fontSize = maxWidth < 560 ? 17.0 : 21.0;
    final cod = st.chars.join();
    final tipos = tokenizar(cod);
    final estiloBase = Mixart.mono(size: fontSize).copyWith(height: 2.05, letterSpacing: .3);

    final spans = <InlineSpan>[];
    for (var i = 0; i < st.chars.length; i++) {
      var ch = st.chars[i];
      final feito = i < st.idx;
      final atual = i == st.idx;
      Color cor = switch (tipos[i]) {
        TokenTipo.keyword => SyntaxColors.kw,
        TokenTipo.ident => SyntaxColors.ident,
        TokenTipo.literal => SyntaxColors.literal,
        TokenTipo.punct => SyntaxColors.punct,
        TokenTipo.comment => SyntaxColors.comment,
      };
      FontWeight peso = tipos[i] == TokenTipo.keyword ? FontWeight.w700 : FontWeight.w400;
      Color? fundo;
      if (feito) {
        cor = Mixart.textHint.withValues(alpha: .6);
        peso = FontWeight.w400;
      } else if (atual) {
        fundo = st.ultimoErrou ? Mixart.danger : Mixart.brandSub;
        if (st.ultimoErrou) cor = Colors.white;
      } else if (ch == ' ') {
        ch = '·'; // pontinho nos espaços ainda não digitados
        cor = Mixart.textFaint;
      }
      spans.add(TextSpan(
        text: ch,
        style: estiloBase.copyWith(
          color: cor,
          fontWeight: peso,
          backgroundColor: fundo,
          fontStyle: tipos[i] == TokenTipo.comment ? FontStyle.italic : null,
        ),
      ));
    }

    // posição do Pac-Man = caret do caractere atual
    final painter = TextPainter(
      text: TextSpan(children: spans, style: estiloBase),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final caret = painter.getOffsetForCaret(
      TextPosition(offset: st.idx.clamp(0, st.chars.length)),
      Rect.zero,
    );
    final alturaLinha = fontSize * 2.05;
    final pacTam = fontSize + 2;
    painter.dispose();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Text.rich(TextSpan(children: spans), style: estiloBase),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 90),
          // um caractere atrás do atual: come a letra anterior, sem tapar a próxima
          left: caret.dx - pacTam - 1,
          top: caret.dy + (alturaLinha - pacTam) / 2,
          child: IgnorePointer(child: Pacman(tamanho: pacTam, venceu: st.concluido)),
        ),
      ],
    );
  }
}
