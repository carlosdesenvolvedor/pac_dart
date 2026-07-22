import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/curriculo.dart';
import '../bloc/voz_cubit.dart';

/// Banner amarelo com a dica do trecho (marcação <b> vira negrito), botão de
/// ouvir e, quando há, uma seção expansível "Entenda melhor" com a explicação
/// aprofundada do conceito.
class DicaBanner extends StatefulWidget {
  final Trecho trecho;
  const DicaBanner({super.key, required this.trecho});

  @override
  State<DicaBanner> createState() => _DicaBannerState();
}

class _DicaBannerState extends State<DicaBanner> {
  bool _aberto = false;

  @override
  void didUpdateWidget(covariant DicaBanner old) {
    super.didUpdateWidget(old);
    if (old.trecho != widget.trecho) _aberto = false; // recolhe ao trocar de trecho
  }

  @override
  Widget build(BuildContext context) {
    final trecho = widget.trecho;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Mixart.brandSub,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: Mixart.brand, shape: BoxShape.circle),
            child: Icon(Icons.lightbulb_outline, size: 16, color: Mixart.onBrand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: RichText(
                  text: TextSpan(style: Mixart.ui(size: 13.5).copyWith(height: 1.55), children: _spans(trecho.dica))),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => context.read<VozCubit>().falarSempre(trecho.dicaPlana),
            tooltip: 'Ouvir a explicação',
            icon: Icon(Icons.volume_up_outlined, size: 18, color: Mixart.brand),
            style: IconButton.styleFrom(
              backgroundColor: Mixart.surfaceHi,
              side: BorderSide(color: Mixart.border),
            ),
          ),
        ]),
        if (trecho.temConceito) _entendaMelhor(trecho),
      ]),
    );
  }

  Widget _entendaMelhor(Trecho trecho) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      InkWell(
        onTap: () => setState(() => _aberto = !_aberto),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(_aberto ? Icons.expand_less : Icons.school_outlined, size: 15, color: Mixart.brand),
            const SizedBox(width: 6),
            Text(_aberto ? 'Recolher' : 'Entenda melhor',
                style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
          ]),
        ),
      ),
      AnimatedCrossFade(
        firstChild: const SizedBox(width: double.infinity),
        secondChild: Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(trecho.conceito,
              style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.55)),
        ),
        crossFadeState: _aberto ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 220),
        sizeCurve: Mixart.slide,
      ),
    ]);
  }

  /// Converte "<b>var</b> deixa…" em spans com negrito.
  List<TextSpan> _spans(String dica) {
    final spans = <TextSpan>[];
    final re = RegExp(r'<b>(.*?)</b>|<code>(.*?)</code>');
    var fim = 0;
    for (final m in re.allMatches(dica)) {
      if (m.start > fim) spans.add(TextSpan(text: dica.substring(fim, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.w700)));
      } else {
        spans.add(TextSpan(text: m.group(2), style: Mixart.mono(size: 12.5, color: Mixart.brand)));
      }
      fim = m.end;
    }
    if (fim < dica.length) spans.add(TextSpan(text: dica.substring(fim)));
    return spans;
  }
}
