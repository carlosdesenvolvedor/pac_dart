import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// A tradução que aparece EMBAIXO da palavra nos jogos de digitação do inglês (Chuva, Rali,
/// Turismo). Uma linha só, com reticências; some (SizedBox.shrink) quando não há tradução. É sempre
/// um Text separado da palavra — quem procura a palavra pelo RichText continua achando.
class LegendaTraducao extends StatelessWidget {
  final String? texto;
  final double tamanho;
  final double maxLargura;
  final TextAlign textAlign;

  /// Cor do texto (padrão: textMuted).
  final Color? cor;

  /// Fundo em pílula (para ler sobre o cenário colorido da Chuva); null = sem fundo.
  final Color? fundo;

  const LegendaTraducao(
    this.texto, {
    super.key,
    this.tamanho = 11,
    this.maxLargura = 180,
    this.textAlign = TextAlign.center,
    this.cor,
    this.fundo,
  });

  @override
  Widget build(BuildContext context) {
    final t = texto?.trim() ?? '';
    if (t.isEmpty) return const SizedBox.shrink();
    Widget w = Text(
      t,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: Mixart.ui(size: tamanho, weight: FontWeight.w600, color: cor ?? Mixart.textMuted).copyWith(height: 1.2),
    );
    final f = fundo;
    if (f != null) {
      w = Container(
        padding: EdgeInsets.symmetric(horizontal: tamanho * .6, vertical: 1.5),
        decoration: BoxDecoration(color: f, borderRadius: BorderRadius.circular(999)),
        child: w,
      );
    }
    return ConstrainedBox(constraints: BoxConstraints(maxWidth: maxLargura), child: w);
  }
}
