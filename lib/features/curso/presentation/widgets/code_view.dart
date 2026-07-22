import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/syntax/tokenizer.dart';
import '../../../../core/theme/mixart.dart';
import '../../../../core/util/codigo_executavel.dart';
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

  /// Quando a lição foi concluída (overlay de vitória visível), o Enter
  /// dispara isto (ir para a próxima lição) em vez da digitação.
  final bool vitoria;
  final VoidCallback? onProximaLicao;

  /// Código Flutter (widget) → o botão copiar gera um app rodável.
  final bool ehFlutter;

  const CodeView({
    super.key,
    required this.onAvancar,
    this.focusNode,
    this.vitoria = false,
    this.onProximaLicao,
    this.ehFlutter = false,
  });

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  late final FocusNode _foco = widget.focusNode ?? FocusNode();
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _foco.onKeyEvent = _teclaControle;
    _ctrl.addListener(_processaTexto);
    WidgetsBinding.instance.addPostFrameCallback((_) => _foco.requestFocus());
  }

  void _processaTexto() {
    // Não processa enquanto o acento está sendo composto (dead keys: ~ + a = ã).
    // Só quando a composição termina o caractere final chega.
    if (!_ctrl.value.composing.isCollapsed) return;
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
      if (widget.vitoria) {
        widget.onProximaLicao?.call(); // Enter na tela de vitória → próxima lição
      } else if (bloc.state.concluido) {
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
    _scroll.dispose();
    super.dispose();
  }

  /// Mantém o cursor (Pac-Man) numa faixa confortável, rolando o código sozinho.
  void _seguirCursor(double caretDy) {
    if (!_scroll.hasClients) return;
    final vp = _scroll.position.viewportDimension;
    final rel = caretDy - _scroll.offset; // posição do cursor dentro da janela
    if (rel > vp * 0.72 || rel < vp * 0.10) {
      final alvo = (caretDy - vp * 0.40).clamp(0.0, _scroll.position.maxScrollExtent);
      _scroll.animateTo(alvo, duration: const Duration(milliseconds: 160), curve: Curves.easeOut);
    }
  }

  Future<void> _copiar() async {
    final cod = context.read<TypingBloc>().state.chars.join();
    await Clipboard.setData(ClipboardData(text: codigoExecutavel(cod, widget.ehFlutter)));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Mixart.surfaceHi,
      duration: const Duration(seconds: 3),
      content: Text('Código copiado! Cole no DartPad (dartpad.dev) ou na sua IDE para rodar.',
          style: Mixart.ui(size: 13, color: Mixart.text)),
    ));
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
                    builder: (context, box) {
                      final alturaMax =
                          (MediaQuery.sizeOf(context).height * 0.46).clamp(220.0, 520.0);
                      return _codigo(st, box.maxWidth, alturaMax);
                    },
                  ),
                ),
              ),
              // botão copiar (canto superior direito)
              Positioned(
                top: 6,
                right: 6,
                child: Tooltip(
                  message: 'Copiar código para rodar numa IDE',
                  child: Material(
                    color: Mixart.surfaceHi,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Mixart.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: _copiar,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.copy_all_outlined, size: 14, color: Mixart.textMuted),
                          const SizedBox(width: 5),
                          Text('copiar', style: Mixart.ui(size: 11, weight: FontWeight.w600, color: Mixart.textMuted)),
                        ]),
                      ),
                    ),
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
                    keyboardType: TextInputType.text,
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

  Widget _codigo(TypingState st, double maxWidth, double alturaMax) {
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
    final alturaConteudo = painter.height + pacTam;
    painter.dispose();

    // rola sozinho para manter o cursor visível
    WidgetsBinding.instance.addPostFrameCallback((_) => _seguirCursor(caret.dy + alturaLinha / 2));

    final conteudo = SizedBox(
      height: alturaConteudo,
      child: Stack(
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
      ),
    );

    // área com altura limitada: código curto cabe todo; código longo rola.
    return SizedBox(
      height: math.min(alturaConteudo, alturaMax),
      child: SingleChildScrollView(
        controller: _scroll,
        physics: const ClampingScrollPhysics(),
        child: conteudo,
      ),
    );
  }
}
