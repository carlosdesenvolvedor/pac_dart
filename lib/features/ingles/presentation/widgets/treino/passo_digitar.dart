import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../domain/banco_palavras.dart';
import '../../../domain/roteiro_treino.dart';
import 'passo_conhecer.dart';

/// Passo 5: a tradução (e o 🔊) → digitar o inglês de memória, em quadradinhos de letra (campo
/// invisível por baixo, `Key('treino-digitar')`). Enter confere (e, conferido, segue), Tab dá a
/// próxima letra (vale como erro), Esc = "não sei". Na 1ª vez o 1º quadradinho mostra a inicial
/// apagadinha (menos com [semDica] ou `passo.semDica`: a revanche das teimosas). NÃO usa
/// FraseView/TypingBloc (o TypingBloc é do palco que está por baixo).
class PassoDigitar extends StatefulWidget {
  final PassoTreino passo;
  final ItemTreino item;

  /// A nota depois de conferir (null = ainda digitando).
  final ResultadoRevisao? nota;

  /// Conferir: o que foi digitado e se usou dica.
  final void Function(String texto, {required bool dica}) onEnviar;
  final VoidCallback onNaoSei;

  /// Enter depois de conferido.
  final VoidCallback onContinuar;
  final void Function({required bool lenta}) onOuvir;

  /// Sem a inicial apagadinha (vale também `passo.semDica`).
  final bool semDica;

  const PassoDigitar({
    super.key,
    required this.passo,
    required this.item,
    required this.nota,
    required this.onEnviar,
    required this.onNaoSei,
    required this.onContinuar,
    required this.onOuvir,
    this.semDica = false,
  });

  @override
  State<PassoDigitar> createState() => PassoDigitarState();
}

class PassoDigitarState extends State<PassoDigitar> {
  final _ctrl = TextEditingController();
  final _foco = FocusNode(debugLabel: 'treino-digitar');
  bool _dica = false;
  // o Enter do teclado virtual chega como ação do campo e, às vezes, também como tecla: o que vier
  // segundo, dentro da janela, é o mesmo toque
  DateTime _teclaEm = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _acaoEm = DateTime.fromMillisecondsSinceEpoch(0);
  static const _mesmoToque = Duration(milliseconds: 250);

  String get _alvo => widget.item.en;

  @override
  void initState() {
    super.initState();
    _foco.onKeyEvent = _tecla;
    _ctrl.addListener(_mudou);
    _foco.addListener(_mudou);
  }

  void _mudou() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  /// Pede o foco do campo (o teclado do celular junto).
  void focar() => _foco.requestFocus();

  bool get _respondido => widget.nota != null;

  /// Confere o que está digitado (Enter / VERIFICAR).
  void verificar() {
    if (_respondido) return;
    if (_ctrl.text.trim().isEmpty && !_dica) return;
    widget.onEnviar(_ctrl.text, dica: _dica);
  }

  /// Dá a próxima letra certa (Tab / Dica).
  void dica() {
    if (_respondido) return;
    final t = _ctrl.text;
    var certo = 0;
    while (certo < t.length && certo < _alvo.length && t[certo].toLowerCase() == _alvo[certo].toLowerCase()) {
      certo++;
    }
    final novo = _alvo.substring(0, math.min(certo + 1, _alvo.length));
    setState(() => _dica = true);
    _ctrl.value = TextEditingValue(text: novo, selection: TextSelection.collapsed(offset: novo.length));
    focar();
  }

  void naoSei() {
    if (_respondido) return;
    widget.onNaoSei();
  }

  void _enter({required bool daTecla}) {
    final agora = DateTime.now();
    if (agora.difference(daTecla ? _acaoEm : _teclaEm) < _mesmoToque) return;
    if (daTecla) {
      _teclaEm = agora;
    } else {
      _acaoEm = agora;
    }
    if (_respondido) {
      widget.onContinuar();
    } else {
      verificar();
    }
  }

  KeyEventResult _tecla(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      _enter(daTecla: true);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.tab) {
      dica();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      naoSei();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final digitado = _ctrl.text;
    final nota = widget.nota;
    final verde = escurecer(CoresFesta.verde, quanto: .2, soNoClaro: true);
    final ambar = escurecer(CoresFesta.ambar, quanto: .2, soNoClaro: true);
    final corNota = switch (nota) {
      ResultadoRevisao.acertou => verde,
      ResultadoRevisao.hesitou => ambar,
      ResultadoRevisao.errou => Mixart.danger,
      null => null,
    };
    return LayoutBuilder(builder: (context, c) {
      final n = _alvo.length;
      const vao = 6.0;
      final lado = math.min(46.0, (c.maxWidth - vao * (n - 1)) / n).clamp(14.0, 46.0);
      final altura = math.min(lado * 1.25, 56.0);
      final quadrados = <Widget>[];
      for (var i = 0; i < n; i++) {
        final temLetra = i < digitado.length;
        final fantasma =
            !temLetra && i == 0 && widget.passo.vez == 0 && !_respondido && !widget.semDica && !widget.passo.semDica;
        final cursor = !_respondido && i == digitado.length && _foco.hasFocus;
        final letra = temLetra ? digitado[i] : (fantasma ? _alvo[0] : '');
        final borda = corNota ?? (cursor ? Mixart.brand : (temLetra ? Mixart.textFaint : Mixart.border));
        quadrados.add(AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: lado,
          height: altura,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: corNota != null ? Color.alphaBlend(corNota.withValues(alpha: .14), Mixart.surface) : Mixart.surface,
            borderRadius: BorderRadius.circular(math.min(10, lado * .25)),
            border: Border(
              top: BorderSide(color: borda, width: 1.5),
              left: BorderSide(color: borda, width: 1.5),
              right: BorderSide(color: borda, width: 1.5),
              bottom: BorderSide(color: borda, width: cursor ? 4 : 3),
            ),
          ),
          child: Text(
            letra,
            style: Mixart.mono(
              size: lado * .56,
              weight: FontWeight.w800,
              color: fantasma ? Mixart.textHint : (corNota ?? Mixart.text),
            ),
          ),
        ));
      }
      return Column(
        key: const Key('passo-digitar'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TituloPasso('Escreva em inglês'),
          const SizedBox(height: 20),
          Row(children: [
            Flexible(
              child: Text(widget.item.pt,
                  key: const Key('treino-prompt'), style: Mixart.display(size: 30, weight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            BotaoSom(
              key: const Key('treino-ouvir'),
              icone: Icons.volume_up_rounded,
              dica: 'Ouvir a palavra',
              tamanho: 40,
              destaque: false,
              onTap: () => widget.onOuvir(lenta: false),
            ),
            const SizedBox(width: 6),
            BotaoSom(
              key: const Key('treino-ouvir-devagar'),
              icone: Icons.slow_motion_video_rounded,
              dica: 'Ouvir devagar 🐢',
              tamanho: 36,
              destaque: false,
              onTap: () => widget.onOuvir(lenta: true),
            ),
          ]),
          const SizedBox(height: 26),
          GestureDetector(
            onTap: focar,
            behavior: HitTestBehavior.opaque,
            child: Stack(clipBehavior: Clip.none, children: [
              Wrap(spacing: vao, runSpacing: vao, children: quadrados),
              Positioned(
                left: 0,
                top: 0,
                width: 1,
                height: 1,
                child: Opacity(
                  opacity: 0,
                  alwaysIncludeSemantics: true,
                  child: TextField(
                    key: const Key('treino-digitar'),
                    controller: _ctrl,
                    focusNode: _foco,
                    autofocus: true,
                    readOnly: _respondido,
                    maxLines: 1,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z'’\- ]")),
                      LengthLimitingTextInputFormatter(n),
                    ],
                    // o Enter do teclado virtual não fecha o teclado
                    onEditingComplete: () {},
                    onSubmitted: (_) => _enter(daTecla: false),
                  ),
                ),
              ),
            ]),
          ),
          if (c.maxWidth >= 600 && !_respondido) ...[
            const SizedBox(height: 14),
            Text('Enter confere · Tab dá uma letra (conta como erro) · Esc = não sei',
                style: Mixart.ui(size: 12, color: Mixart.textFaint)),
          ],
          if (_dica && !_respondido) ...[
            const SizedBox(height: 8),
            Text('💡 Com dica, a palavra volta mais cedo na revisão.',
                style: Mixart.ui(size: 12, weight: FontWeight.w600, color: ambar)),
          ],
        ],
      );
    });
  }
}
