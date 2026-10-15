import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/mixart.dart';

/// Celular/tablet: teclado virtual, microfone e toque no lugar de
/// Enter/Tab/Esc.
bool get ehCelular => defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;

/// Celular: com o teclado aberto sobra pouca tela e a frase fica escondida
/// embaixo dela — rola até a [zona] (a frase, o selo e a barra da fila)
/// aparecer inteira, com a tradução logo acima quando cabe. [aindaVale]
/// é conferido depois do frame (a tela pode ter fechado ou ter outra coisa por
/// cima). No computador não mexe em nada.
void manterZonaVisivel(GlobalKey zona, {bool Function()? aindaVale}) {
  if (!ehCelular) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = zona.currentContext;
    if (ctx == null || !ctx.mounted || !(aindaVale?.call() ?? true)) return;
    _rolarAte(ctx, soSeEscondida: false);
  });
}

/// Celular: depois que [contexto] CRESCEU (um recado novo embaixo da frase), se
/// o fim dele ficou escondido atrás do teclado rola só o necessário para
/// aparecer — nada se mexe quando já está à vista.
void manterContextoVisivel(BuildContext contexto) {
  if (!ehCelular) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!contexto.mounted) return;
    _rolarAte(contexto, soSeEscondida: true);
  });
}

void _rolarAte(BuildContext ctx, {required bool soSeEscondida}) {
  final render = ctx.findRenderObject();
  if (render == null) return;
  Scrollable.maybeOf(ctx)?.position.ensureVisible(
        render,
        alignment: 1.0,
        alignmentPolicy: soSeEscondida
            ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
            : ScrollPositionAlignmentPolicy.explicit,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
}

/// "Enter segue →" depois de terminar a frase. No celular não há Enter na
/// mão: vira um botão "Seguir →" de 48 px (o teclado virtual também tem o
/// "ok", que faz o mesmo).
class BotaoSeguir extends StatelessWidget {
  final VoidCallback onTap;
  final double tamanho;
  const BotaoSeguir({super.key, required this.onTap, this.tamanho = 12.5});

  @override
  Widget build(BuildContext context) {
    if (!ehCelular) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text('Enter segue →', style: Mixart.ui(size: tamanho, weight: FontWeight.w800, color: Mixart.brand)),
        ),
      );
    }
    return Material(
      color: Mixart.brand,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Seguir', style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand)),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 18, color: Mixart.onBrand),
            ]),
          ),
        ),
      ),
    );
  }
}

/// O teclado virtual está aberto, e quando SOBE? O Scaffold consome os
/// `viewInsets` antes de chegar ao corpo da tela (o MediaQuery de lá sempre
/// diz 0), então a conta é feita na própria janela. [tecladoAberto] muda a tela
/// (o cartão da tradução encolhe para sobrar espaço) e [aoSubirOTeclado] vem
/// no momento em que o espaço de baixo aumenta.
mixin VigiaDoTeclado<T extends StatefulWidget> on State<T> implements WidgetsBindingObserver {
  double _tecladoAntes = 0;
  bool _tecladoAberto = false;

  /// Há teclado virtual na tela (só no celular).
  bool get tecladoAberto => _tecladoAberto;

  /// O teclado acabou de subir (ou cresceu).
  void aoSubirOTeclado();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    final janela = View.maybeOf(context);
    if (janela == null) return;
    final teclado = janela.viewInsets.bottom;
    final subiu = teclado > _tecladoAntes;
    _tecladoAntes = teclado;
    final aberto = ehCelular && teclado > 0;
    if (aberto != _tecladoAberto) setState(() => _tecladoAberto = aberto);
    if (subiu) aoSubirOTeclado();
  }
}
