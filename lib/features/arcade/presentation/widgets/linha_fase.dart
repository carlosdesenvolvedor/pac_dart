import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// A linha da fase na largada (só no inglês): 'Fase 2 · 14 palavras · 9 novas · 5 pra revisar 🔁'. Fica
/// sempre por cima do escurecido da contagem 3-2-1, então tem a mesma cara no tema claro e no escuro.
class LinhaFase extends StatelessWidget {
  final String texto;
  const LinhaFase(this.texto, {super.key = const Key('fase-intro')});

  /// Pronta pra ir no Stack do jogo, logo depois da [ContagemRegressiva]: um pouco abaixo do número,
  /// sem pegar toque.
  static Widget naContagem(String texto) => Positioned.fill(
        child: IgnorePointer(
          child: Align(
            alignment: const Alignment(0, .42),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinhaFase(texto),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE010131A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Mixart.brandDim),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: const Color(0xFFE8ECF0)),
          ),
        ),
      ),
    );
  }
}

/// O 🔁 de "pra revisar" (com o [rotulo] opcional, ex.: 'REVISÃO'). Vai ao lado da palavra, nunca dentro
/// do Text.rich dela (os testes e a voz leem a palavra pelo texto).
class MarcaRevisao extends StatelessWidget {
  final String? rotulo;
  final double tamanho;
  const MarcaRevisao({super.key, this.rotulo, this.tamanho = 11});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'revisão',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: Text('🔁', style: TextStyle(fontSize: tamanho))),
          if (rotulo != null) ...[
            const SizedBox(width: 4),
            ExcludeSemantics(
              child: Text(
                rotulo!,
                style: Mixart.ui(size: tamanho - 1, weight: FontWeight.w800, color: Mixart.brand)
                    .copyWith(letterSpacing: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
