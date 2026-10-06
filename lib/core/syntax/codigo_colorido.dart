import 'package:flutter/material.dart';

import '../theme/mixart.dart';
import 'tokenizer.dart';

/// Código com destaque de sintaxe (só leitura), na linguagem em uso.
class CodigoColorido extends StatelessWidget {
  final String cod;
  final double tamanho;

  /// bash, json, xml… quando o código não é da linguagem do curso.
  final String variante;

  /// Trecho que deve aparecer como lacuna (ex.: `___`), pintado em destaque.
  final String? lacuna;

  const CodigoColorido(this.cod, {super.key, this.tamanho = 13, this.variante = '', this.lacuna});

  static Color cor(TokenTipo t) => switch (t) {
        TokenTipo.keyword => SyntaxColors.kw,
        TokenTipo.ident => SyntaxColors.ident,
        TokenTipo.literal => SyntaxColors.literal,
        TokenTipo.punct => SyntaxColors.punct,
        TokenTipo.comment => SyntaxColors.comment,
      };

  @override
  Widget build(BuildContext context) {
    final tipos = tokenizar(cod, variante: variante);
    final spans = <InlineSpan>[];
    final ini = lacuna == null ? -1 : cod.indexOf(lacuna!);
    for (var k = 0; k < cod.length; k++) {
      if (k == ini) {
        spans.add(TextSpan(
          text: ' ??? ',
          style: TextStyle(
            color: Mixart.onBrand,
            backgroundColor: Mixart.brand,
            fontWeight: FontWeight.w800,
          ),
        ));
        k += lacuna!.length - 1;
        continue;
      }
      spans.add(TextSpan(
        text: cod[k],
        style: TextStyle(
          color: cor(tipos[k]),
          fontWeight: tipos[k] == TokenTipo.keyword ? FontWeight.w700 : FontWeight.w400,
          fontStyle: tipos[k] == TokenTipo.comment ? FontStyle.italic : null,
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans), style: Mixart.mono(size: tamanho).copyWith(height: 1.6));
  }
}
