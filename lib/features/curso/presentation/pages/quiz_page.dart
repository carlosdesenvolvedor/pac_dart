import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/syntax/tokenizer.dart';
import '../../../../core/theme/mixart.dart';
import '../../domain/curriculo.dart';
import '../../domain/quiz.dart';
import '../bloc/curso_bloc.dart';
import '../widgets/pacman.dart';

/// Quiz da lição: até 10 perguntas geradas dos próprios exercícios.
/// O jogador ESCOLHE uma alternativa e a digita livremente — a resposta
/// só é avaliada quando ele dá Enter no final.
class QuizPage extends StatefulWidget {
  final int trilhaIdx, licaoIdx;
  final Licao licao;
  final List<String> poolTrilha;

  const QuizPage({
    super.key,
    required this.trilhaIdx,
    required this.licaoIdx,
    required this.licao,
    required this.poolTrilha,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  late final List<PerguntaQuiz> perguntas = gerarQuiz(
    widget.licao,
    widget.poolTrilha,
    seed: widget.trilhaIdx * 1000 + widget.licaoIdx,
  );

  int i = 0;
  int acertos = 0;
  bool terminou = false;

  // resposta da pergunta atual
  bool submetido = false;
  bool acertou = false;

  void _responder(String digitado) {
    if (submetido) return;
    final p = perguntas[i];
    String norm(String s) =>
        s.split('\n').map((l) => l.trimRight()).join('\n').trim();
    setState(() {
      submetido = true;
      acertou = norm(digitado) == norm(p.codigoCerto);
      if (acertou) acertos++;
    });
  }

  void _proxima() {
    if (i >= perguntas.length - 1) {
      setState(() => terminou = true);
      context
          .read<CursoBloc>()
          .add(QuizFinalizado(widget.trilhaIdx, widget.licaoIdx, acertos));
      return;
    }
    setState(() {
      i++;
      submetido = false;
      acertou = false;
    });
  }

  void _reinicia() {
    setState(() {
      i = 0;
      acertos = 0;
      terminou = false;
      submetido = false;
      acertou = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (perguntas.isEmpty) {
      return Scaffold(
        backgroundColor: Mixart.bg,
        body: Center(
            child: Text('Esta lição ainda não tem quiz.',
                style: Mixart.ui(size: 14, color: Mixart.textMuted))),
      );
    }
    return Scaffold(
      backgroundColor: Mixart.bg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: terminou ? _resultado() : _pergunta(),
        ),
      ),
    );
  }

  // ---------- telas ----------

  Widget _pergunta() {
    final p = perguntas[i];
    return ListView(padding: const EdgeInsets.fromLTRB(20, 24, 20, 40), children: [
      _cabecalho(),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Text(p.enunciado,
            style: Mixart.ui(size: 14.5, weight: FontWeight.w600).copyWith(height: 1.5)),
      ),
      const SizedBox(height: 14),
      for (var a = 0; a < p.alternativas.length; a++)
        _alternativa(a, p.alternativas[a], p),
      const SizedBox(height: 14),
      Text('Escolha uma alternativa e digite o código dela — Enter no final envia:',
          style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted)),
      const SizedBox(height: 8),
      _AreaRespostaLivre(
        key: ValueKey(i), // zera a digitação a cada pergunta
        alternativas: p.alternativas,
        submetido: submetido,
        onEnviar: _responder,
        onProxima: _proxima,
      ),
      const SizedBox(height: 12),
      if (!submetido)
        Text('Você pode digitar qualquer alternativa — o veredito só sai no Enter.',
            style: Mixart.ui(size: 11.5, color: Mixart.textFaint))
      else
        Row(children: [
          Icon(acertou ? Icons.check_circle : Icons.cancel,
              size: 18, color: acertou ? Mixart.brand : Mixart.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              acertou
                  ? 'Acertou! 🎉'
                  : 'Errou — a correta era a ${String.fromCharCode(65 + p.correta)}.',
              style: Mixart.ui(
                  size: 13,
                  weight: FontWeight.w700,
                  color: acertou ? Mixart.brand : Mixart.danger),
            ),
          ),
          Text('↵ Enter para a próxima',
              style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.brand)),
        ]),
    ]);
  }

  Widget _cabecalho() => Row(children: [
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
          style: IconButton.styleFrom(
              backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('QUIZ · ${widget.licao.emoji} ${widget.licao.nome}',
                style: Mixart.display(size: 17)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (i + 1) / perguntas.length,
                minHeight: 6,
                backgroundColor: Mixart.surfaceHi,
                color: Mixart.brand,
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Text('${i + 1}/${perguntas.length}', style: Mixart.mono(size: 12, color: Mixart.textMuted)),
      ]);

  Widget _alternativa(int a, String cod, PerguntaQuiz p) {
    final letra = String.fromCharCode(65 + a);
    // após o envio, pinta a certa (e a errada, se foi o caso)
    Color borda = Mixart.border;
    if (submetido && a == p.correta) borda = Mixart.brand;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: borda, width: submetido && a == p.correta ? 1.6 : 1),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: submetido && a == p.correta ? Mixart.brand : Mixart.surfaceHi,
            shape: BoxShape.circle,
            border: Border.all(color: Mixart.border),
          ),
          child: Text(letra,
              style: Mixart.ui(
                  size: 12,
                  weight: FontWeight.w700,
                  color: submetido && a == p.correta ? Mixart.onBrand : Mixart.textMuted)),
        ),
        const SizedBox(width: 12),
        Expanded(child: _codigoColorido(cod)),
      ]),
    );
  }

  Widget _codigoColorido(String cod) {
    final tipos = tokenizar(cod);
    final spans = <TextSpan>[];
    for (var k = 0; k < cod.length; k++) {
      spans.add(TextSpan(
        text: cod[k],
        style: TextStyle(
          color: switch (tipos[k]) {
            TokenTipo.keyword => SyntaxColors.kw,
            TokenTipo.ident => SyntaxColors.ident,
            TokenTipo.literal => SyntaxColors.literal,
            TokenTipo.punct => SyntaxColors.punct,
            TokenTipo.comment => SyntaxColors.comment,
          },
          fontWeight: tipos[k] == TokenTipo.keyword ? FontWeight.w700 : FontWeight.w400,
        ),
      ));
    }
    return Text.rich(
      TextSpan(children: spans),
      style: Mixart.mono(size: 13).copyWith(height: 1.6),
    );
  }

  Widget _resultado() {
    final total = perguntas.length;
    final otimo = acertos >= (total * .8).ceil();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(otimo ? '🏆' : '📚', style: const TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          Text('QUIZ CONCLUÍDO!', style: Mixart.display(size: 26, color: Mixart.brand)),
          const SizedBox(height: 6),
          Text('${widget.licao.emoji} ${widget.licao.nome}',
              style: Mixart.ui(size: 13, color: Mixart.textMuted)),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            decoration: BoxDecoration(
              color: Mixart.surface,
              border: Border.all(color: Mixart.border),
              borderRadius: BorderRadius.circular(Mixart.radiusMd),
            ),
            child: Text('$acertos / $total',
                style: Mixart.display(size: 34, color: otimo ? Mixart.brand : Mixart.text)),
          ),
          const SizedBox(height: 8),
          Text(
            otimo ? 'Mandou muito! ⭐' : 'Refaça a lição e tente de novo!',
            style: Mixart.ui(size: 13, color: Mixart.textMuted),
          ),
          const SizedBox(height: 22),
          Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Mixart.brand,
                foregroundColor: Mixart.onBrand,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Voltar ao mapa'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Mixart.text,
                side: BorderSide(color: Mixart.border),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: Mixart.ui(size: 13),
              ),
              onPressed: _reinicia,
              child: const Text('Repetir quiz'),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// Área de digitação LIVRE: mostra só o que o jogador digitou (nada da
/// resposta), com Pac-Man no fim da linha. Enter no meio vira quebra de
/// linha se o texto ainda casa com alguma alternativa multi-linha;
/// Enter no final envia a resposta.
class _AreaRespostaLivre extends StatefulWidget {
  final List<String> alternativas;
  final bool submetido;
  final ValueChanged<String> onEnviar;
  final VoidCallback onProxima;

  const _AreaRespostaLivre({
    super.key,
    required this.alternativas,
    required this.submetido,
    required this.onEnviar,
    required this.onProxima,
  });

  @override
  State<_AreaRespostaLivre> createState() => _AreaRespostaLivreState();
}

class _AreaRespostaLivreState extends State<_AreaRespostaLivre> {
  final _foco = FocusNode();
  final _ctrl = TextEditingController();
  String buffer = '';

  @override
  void initState() {
    super.initState();
    _foco.onKeyEvent = _teclaControle;
    _ctrl.addListener(_processaTexto);
    WidgetsBinding.instance.addPostFrameCallback((_) => _foco.requestFocus());
  }

  @override
  void dispose() {
    _foco.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _processaTexto() {
    // Espera a composição de acentos terminar (dead keys: ~ + a = ã).
    if (!_ctrl.value.composing.isCollapsed) return;
    final txt = _ctrl.text;
    if (txt.isEmpty || widget.submetido) {
      _ctrl.clear();
      return;
    }
    setState(() => buffer += txt.replaceAll('\r', ''));
    _ctrl.clear();
  }

  KeyEventResult _teclaControle(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;

    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      if (widget.submetido) {
        widget.onProxima();
      } else if (buffer.isNotEmpty) {
        _enter();
      }
      return KeyEventResult.handled;
    }
    if (widget.submetido) return KeyEventResult.handled;
    if (e.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab) return KeyEventResult.handled;
    return KeyEventResult.ignored;
  }

  /// Enter: quebra de linha se ainda casa com alguma alternativa; senão envia.
  void _enter() {
    final comQuebra = '$buffer\n';
    final candidata = widget.alternativas
        .where((a) => a.startsWith(comQuebra) && a.length > comQuebra.length)
        .firstOrNull;
    if (candidata != null) {
      // auto-indentação: já emenda os espaços do começo da próxima linha
      var novo = comQuebra;
      var k = comQuebra.length;
      while (k < candidata.length && candidata[k] == ' ') {
        novo += ' ';
        k++;
      }
      setState(() => buffer = novo);
    } else {
      widget.onEnviar(buffer);
    }
  }

  void _backspace() {
    if (buffer.isEmpty) return;
    // se o fim é só indentação de uma linha nova, volta a linha inteira
    final ultimaQuebra = buffer.lastIndexOf('\n');
    if (ultimaQuebra >= 0) {
      final cauda = buffer.substring(ultimaQuebra + 1);
      if (cauda.isNotEmpty && cauda.trim().isEmpty) {
        setState(() => buffer = buffer.substring(0, ultimaQuebra));
        return;
      }
    }
    setState(() => buffer = buffer.substring(0, buffer.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _foco.requestFocus(),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: Mixart.bg,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          child: Stack(children: [
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2, color: Mixart.brandDim)),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 20, 24, 20),
              child: LayoutBuilder(builder: (context, box) => _texto(box.maxWidth)),
            ),
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
          ]),
        ),
      ),
    );
  }

  Widget _texto(double maxWidth) {
    final fontSize = maxWidth < 560 ? 16.0 : 19.0;
    final estiloBase = Mixart.mono(size: fontSize).copyWith(height: 1.9, letterSpacing: .3);

    if (buffer.isEmpty) {
      return Row(children: [
        Pacman(tamanho: fontSize + 2),
        const SizedBox(width: 10),
        Text('comece a digitar…',
            style: Mixart.ui(size: 13, color: Mixart.textHint).copyWith(fontStyle: FontStyle.italic)),
      ]);
    }

    final tipos = tokenizar(buffer);
    final spans = <TextSpan>[
      for (var k = 0; k < buffer.length; k++)
        TextSpan(
          text: buffer[k],
          style: estiloBase.copyWith(
            color: switch (tipos[k]) {
              TokenTipo.keyword => SyntaxColors.kw,
              TokenTipo.ident => SyntaxColors.ident,
              TokenTipo.literal => SyntaxColors.literal,
              TokenTipo.punct => SyntaxColors.punct,
              TokenTipo.comment => SyntaxColors.comment,
            },
            fontWeight: tipos[k] == TokenTipo.keyword ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
    ];

    // Pac-Man no fim do que foi digitado
    final painter = TextPainter(
      text: TextSpan(children: spans, style: estiloBase),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final caret = painter.getOffsetForCaret(TextPosition(offset: buffer.length), Rect.zero);
    final alturaLinha = fontSize * 1.9;
    final pacTam = fontSize + 2;
    painter.dispose();

    return Stack(clipBehavior: Clip.none, children: [
      Text.rich(TextSpan(children: spans), style: estiloBase),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 90),
        left: caret.dx + 2,
        top: caret.dy + (alturaLinha - pacTam) / 2,
        child: IgnorePointer(child: Pacman(tamanho: pacTam)),
      ),
    ]);
  }
}
