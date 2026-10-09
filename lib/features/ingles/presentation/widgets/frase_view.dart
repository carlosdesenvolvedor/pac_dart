import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/som/sons.dart';
import '../../../../core/theme/mixart.dart';
import '../../../curso/presentation/bloc/typing_bloc.dart';
import '../../../curso/presentation/widgets/pacman.dart';
import '../../data/voz_ingles.dart';
import '../../domain/avaliacao.dart';
import '../../domain/roteiro.dart';

/// A frase em inglês sendo digitada, com o Pac-Man comendo letra a letra.
///
/// O que aparece antes de digitar depende do degrau ([ModoFrase]): a frase
/// toda, só as iniciais, só os tracinhos ou nada. No escuro, errar duas
/// vezes a mesma letra a revela; Tab revela a próxima letra (Tab duas vezes
/// seguidas, a palavra) e Esc ("não sei") mostra a frase inteira. Terminada
/// uma digitação de memória, a frase aparece completa com as palavras
/// erradas sublinhadas. O teclado entra por um TextField invisível, como no
/// CodeView (acentos/IME e as teclas mortas do US-International).
class FraseView extends StatefulWidget {
  final ModoFrase modo;

  /// Número do passo: mudou, as revelações recomeçam (a frase pode voltar
  /// logo em seguida, na cópia de correção).
  final int passo;

  /// Trecho da frase que a lição ensina — vem destacado.
  final String alvo;

  /// Palavras (índices) a sublinhar em vermelho depois de terminar.
  final Set<int> palavrasErradas;

  /// Enter com a frase completa.
  final VoidCallback onAvancar;

  /// Enter ANTES de terminar = ouvir na velocidade padrão (a lenta, se o
  /// aluno não mudou); Shift+Enter = na outra velocidade.
  final void Function({required bool lenta})? onOuvir;

  /// 👁 ligado: a frase inteira à vista em qualquer degrau (vale para
  /// todas as frases até desligar).
  final bool mostrarTudo;

  /// Pediu dica (Tab / 💡) ou desistiu (Esc): algo foi revelado.
  final VoidCallback? onRevelou;

  final FocusNode? focusNode;

  /// Overlay de vitória na tela: Enter segue, Esc pula a etapa seguinte.
  final bool vitoria;
  final VoidCallback? onProximaLicao;
  final VoidCallback? onPularQuiz;

  /// Janela logo após montar em que o texto que chega é descartado (a
  /// tecla que escolheu o curso). Testes zeram.
  static Duration carencia = const Duration(milliseconds: 350);

  const FraseView({
    super.key,
    required this.modo,
    this.passo = 0,
    required this.onAvancar,
    this.onOuvir,
    this.alvo = '',
    this.palavrasErradas = const {},
    this.onRevelou,
    this.focusNode,
    this.vitoria = false,
    this.onProximaLicao,
    this.onPularQuiz,
    this.mostrarTudo = false,
  });

  @override
  State<FraseView> createState() => FraseViewState();
}

class FraseViewState extends State<FraseView> {
  late final FocusNode _foco = widget.focusNode ?? FocusNode();
  final _ctrl = TextEditingController();

  /// Posições reveladas no escuro (dica, letra errada duas vezes, "não sei").
  final Set<int> _reveladas = {};
  bool _desistiu = false;
  bool _ultimaFoiTab = false;

  /// A tecla que ESCOLHEU o curso (o "3" da tela de escolha) chega aqui
  /// logo depois da montagem como texto digitado — descarta esse resto.
  final _montadoEm = DateTime.now();

  /// O que foi revelado nesta digitação (para a nota).
  Set<int> get reveladas => Set.unmodifiable(_reveladas);
  bool get desistiu => _desistiu;

  @override
  void initState() {
    super.initState();
    _foco.onKeyEvent = _teclaControle;
    _ctrl.addListener(_processaTexto);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _foco.requestFocus();
    });
  }

  @override
  void didUpdateWidget(covariant FraseView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.modo != widget.modo || oldWidget.passo != widget.passo) _recomecar();
  }

  void _recomecar() {
    _reveladas.clear();
    _desistiu = false;
    _ultimaFoiTab = false;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _foco.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _processaTexto() {
    // espera a tecla morta terminar de compor (´ + a = á, ' + c = ç)
    if (!_ctrl.value.composing.isCollapsed) return;
    final txt = _ctrl.text;
    if (txt.isEmpty) return;
    if (DateTime.now().difference(_montadoEm) < FraseView.carencia) {
      _ctrl.clear();
      return;
    }
    _ultimaFoiTab = false;
    final bloc = context.read<TypingBloc>();
    for (final ch in txt.characters) {
      if (ch == '\n' || ch == '\r' || ch == '\t') continue; // frase não tem quebra de linha
      bloc.add(TeclaDigitada(ch));
    }
    _ctrl.clear();
  }

  KeyEventResult _teclaControle(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) return KeyEventResult.ignored;
    final bloc = context.read<TypingBloc>();
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.backspace) {
      bloc.add(const BackspaceApertado());
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.enter || k == LogicalKeyboardKey.numpadEnter) {
      if (widget.vitoria) {
        widget.onProximaLicao?.call();
      } else if (bloc.state.concluido) {
        widget.onAvancar();
      } else if (e is KeyDownEvent) {
        final shift = HardwareKeyboard.instance.isShiftPressed;
        widget.onOuvir?.call(lenta: shift ? !VozIngles.lentaPorPadrao : VozIngles.lentaPorPadrao);
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      if (widget.vitoria) {
        widget.onPularQuiz?.call();
      } else if (e is KeyDownEvent) {
        naoSei();
      }
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.tab) {
      if (e is KeyDownEvent) {
        if (_ultimaFoiTab) {
          revelarPalavra();
        } else {
          revelarLetra();
        }
        _ultimaFoiTab = true;
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  static bool _ehLetra(String c) => RegExp(r'[A-Za-z0-9]').hasMatch(c);

  /// Próxima letra a partir do cursor (pula espaço e pontuação).
  int? _proximaLetra(TypingState st) {
    for (var i = st.idx; i < st.chars.length; i++) {
      if (_ehLetra(st.chars[i])) return i;
    }
    return null;
  }

  void _revelar(Iterable<int> posicoes) {
    var revelou = false;
    for (final i in posicoes) {
      revelou |= _reveladas.add(i);
    }
    if (revelou) {
      setState(() {});
      widget.onRevelou?.call();
    }
  }

  /// Tab: revela a próxima letra.
  void revelarLetra() {
    if (!widget.modo.deMemoria) return;
    final st = context.read<TypingBloc>().state;
    if (st.concluido) return;
    final i = _proximaLetra(st);
    if (i != null) _revelar([i]);
  }

  /// Tab duas vezes (ou o 💡): revela o resto da palavra atual.
  void revelarPalavra() {
    if (!widget.modo.deMemoria) return;
    final st = context.read<TypingBloc>().state;
    if (st.concluido) return;
    final ini = _proximaLetra(st);
    if (ini == null) return;
    final ps = <int>[];
    for (var i = ini; i < st.chars.length; i++) {
      final c = st.chars[i];
      if (!_ehLetra(c) && c != "'" && c != '-') break;
      ps.add(i);
    }
    _revelar(ps);
  }

  /// Esc: "não sei" — a frase inteira aparece e vira cópia (nota: errou).
  void naoSei() {
    if (!widget.modo.deMemoria) return;
    final st = context.read<TypingBloc>().state;
    if (st.concluido) return;
    _desistiu = true;
    _revelar([for (var i = st.idx; i < st.chars.length; i++) i]);
  }

  // baseline do placar para tocar o som certo (o listener só vê o estado novo)
  int _somAcertos = 0, _somErros = 0;
  bool _somConcluido = false;

  void _trilhaSonora(TypingState st) {
    if (st.acertosSessao > _somAcertos) {
      Sons.toca(Som.waka);
    } else if (st.errosSessao > _somErros) {
      Sons.toca(Som.erro);
    }
    if (st.concluido && !_somConcluido) Sons.toca(Som.blip);
    _somAcertos = st.acertosSessao;
    _somErros = st.errosSessao;
    _somConcluido = st.concluido;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TypingBloc, TypingState>(
      listenWhen: (a, b) =>
          a.acertosSessao != b.acertosSessao || a.errosSessao != b.errosSessao || a.concluido != b.concluido,
      listener: (_, st) {
        _trilhaSonora(st);
        // no escuro, errar DUAS vezes a mesma letra a revela (conta como dica)
        if (st.ultimoErrou && widget.modo.deMemoria && st.idx < st.chars.length) {
          if ((st.errosPorPosicao[st.idx] ?? 0) >= 2) _revelar([st.idx]);
        }
      },
      child: GestureDetector(
        onTap: () => _foco.requestFocus(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Mixart.bg,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Stack(children: [
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 2, color: Mixart.brandDim)),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 26, 24, 26),
              child: BlocBuilder<TypingBloc, TypingState>(
                builder: (context, st) => LayoutBuilder(
                  builder: (context, box) => _frase(st, box.maxWidth),
                ),
              ),
            ),
            // letra certa com a caixa errada: avisa a regra (é conteúdo)
            Positioned(
              left: 28,
              right: 24,
              bottom: 6,
              child: BlocBuilder<TypingBloc, TypingState>(
                buildWhen: (a, b) => a.idx != b.idx || a.errosDeCaixa != b.errosDeCaixa || a.ultimoErrou != b.ultimoErrou,
                builder: (context, st) {
                  if (!st.ultimoErrou || !st.errosDeCaixa.containsKey(st.idx)) return const SizedBox.shrink();
                  final c = st.idx < st.chars.length ? st.chars[st.idx] : '';
                  final maiuscula = c == c.toUpperCase();
                  return Text(
                    maiuscula
                        ? 'Maiúscula aqui: em inglês I, nomes, dias, meses, idiomas e nacionalidades começam com maiúscula.'
                        : 'Minúscula aqui.',
                    style: Mixart.ui(size: 11, weight: FontWeight.w600, color: Mixart.brand),
                  );
                },
              ),
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

  Widget _frase(TypingState st, double maxWidth) {
    if (st.chars.isEmpty) return const SizedBox(height: 60);
    final frase = st.chars.join();
    final mascara = mascaraDaFrase(frase, widget.mostrarTudo ? ModoFrase.ver : widget.modo);
    final ini = widget.alvo.isEmpty ? -1 : frase.indexOf(widget.alvo);
    final fim = ini < 0 ? -1 : ini + widget.alvo.length;
    final erradas = <int>{};
    if (st.concluido && widget.palavrasErradas.isNotEmpty) {
      final ps = palavrasDe(frase);
      for (final w in widget.palavrasErradas) {
        if (w < ps.length) erradas.addAll([for (var i = ps[w].ini; i < ps[w].fim; i++) i]);
      }
    }

    // letra grande; encolhe só se a palavra mais longa não couber na linha
    final base = maxWidth < 560 ? 22.0 : 30.0;
    final maiorPalavra = frase.split(' ').fold<int>(0, (m, p) => math.max(m, p.length));
    final cabe = maiorPalavra == 0 ? base : (maxWidth - 8) / (maiorPalavra * 0.64);
    final fontSize = math.max(16.0, math.min(base, cabe));
    final estilo = Mixart.mono(size: fontSize).copyWith(height: 1.9, letterSpacing: .4);

    final spans = <InlineSpan>[];
    for (var i = 0; i < st.chars.length; i++) {
      final ch = st.chars[i];
      final feito = i < st.idx;
      final atual = i == st.idx;
      final noAlvo = i >= ini && i < fim;
      final mostra = _reveladas.contains(i) ? Mostra.letra : mascara[i];
      var texto = ch;
      Color cor;
      Color? fundo;
      var peso = FontWeight.w500;
      TextDecoration? deco;
      Color? corDeco;
      if (feito) {
        cor = noAlvo ? Mixart.brand : Mixart.text;
        peso = FontWeight.w600;
        if (erradas.contains(i)) {
          cor = Mixart.danger;
          deco = TextDecoration.underline;
          corDeco = Mixart.danger;
        }
      } else if (mostra == Mostra.nada) {
        cor = Colors.transparent; // ocupa o lugar, mas não entrega nada
      } else if (mostra == Mostra.tracinho) {
        texto = '_';
        cor = Mixart.textHint;
      } else {
        final revelada = _reveladas.contains(i) && widget.modo.deMemoria;
        cor = revelada
            ? Mixart.brand.withValues(alpha: .55)
            : (noAlvo ? Mixart.brand.withValues(alpha: .85) : Mixart.textMuted);
      }
      if (noAlvo && widget.modo == ModoFrase.ver && !feito) {
        deco = TextDecoration.underline;
        corDeco = Mixart.brandDim;
      }
      if (atual && !st.concluido) {
        fundo = st.ultimoErrou ? Mixart.danger : Mixart.brandSub;
        if (st.ultimoErrou) {
          // a posição fica vermelha; a letra só aparece se estiver à vista
          texto = mostra == Mostra.letra ? (ch == ' ' ? '␣' : ch) : (ch == ' ' ? ' ' : '?');
          cor = Colors.white;
        }
      }
      spans.add(TextSpan(
        text: texto,
        style: estilo.copyWith(
          color: cor,
          fontWeight: peso,
          backgroundColor: fundo,
          decoration: deco,
          decorationColor: corDeco,
        ),
      ));
    }

    final painter = TextPainter(
      text: TextSpan(children: spans, style: estilo),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    final caret = painter.getOffsetForCaret(TextPosition(offset: st.idx.clamp(0, st.chars.length)), Rect.zero);
    final alturaLinha = fontSize * 1.9;
    final pacTam = fontSize * .9;
    final altura = painter.height;
    painter.dispose();

    return SizedBox(
      height: altura,
      child: Stack(clipBehavior: Clip.none, children: [
        Text.rich(TextSpan(children: spans), style: estilo),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 90),
          left: caret.dx - pacTam - 1,
          top: caret.dy + (alturaLinha - pacTam) / 2,
          child: IgnorePointer(child: Pacman(tamanho: pacTam, venceu: st.concluido)),
        ),
      ]),
    );
  }
}
