import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../curso/domain/curriculo.dart';

/// A âncora visual da lição: a foto real da cena (ou os emojis dela), a
/// visualização guiada e o lembrete de falar em voz alta. Ver a cena antes
/// de digitar e reencontrá-la na revisão ajuda a lembrar (memória ligada ao
/// contexto); imagem + frase juntas fixam mais que só a frase.
class CenaVisual extends StatelessWidget {
  final Licao licao;

  /// Versão compacta (faixa na revisão): só a miniatura, os emojis e o nome.
  final bool compacta;

  const CenaVisual({super.key, required this.licao, this.compacta = false});

  bool get temAlgo => licao.foto.isNotEmpty || licao.imagem.isNotEmpty || licao.visualizacao.isNotEmpty;

  Widget _foto(double largura, double altura) {
    final emojis = Center(
      child: Text(licao.imagem.isEmpty ? licao.emoji : licao.imagem,
          style: TextStyle(fontSize: altura * (compacta ? .42 : .34)), textAlign: TextAlign.center),
    );
    final fundo = Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Mixart.brandSub, Mixart.surfaceHi]),
      ),
      child: emojis,
    );
    if (licao.foto.isEmpty) return fundo;
    final foto = Image.asset(
      licao.foto,
      width: largura,
      height: altura,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fundo,
    );
    if (compacta) return foto;
    // zoom lento enquanto a pessoa visualiza a cena (dá sensação de estar lá)
    return SizedBox(
      width: largura,
      height: altura,
      child: ClipRect(
        child: TweenAnimationBuilder<double>(
          key: ValueKey(licao.foto),
          tween: Tween(begin: 1, end: 1.08),
          duration: const Duration(seconds: 14),
          curve: Curves.easeOut,
          builder: (_, escala, filho) => Transform.scale(scale: escala, child: filho),
          child: foto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compacta) {
      return Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: _foto(64, 44)),
        const SizedBox(width: 10),
        if (licao.imagem.isNotEmpty) ...[
          Text(licao.imagem, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(licao.cena.isEmpty ? licao.nome : licao.cena,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.35)),
        ),
      ]);
    }
    return LayoutBuilder(builder: (context, box) {
      final largo = box.maxWidth >= 620;
      final foto = ClipRRect(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        child: _foto(largo ? 260 : box.maxWidth, largo ? 160 : 170),
      );
      final texto = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('VISUALIZE A CENA',
            style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 1.6)),
        const SizedBox(height: 6),
        Text(licao.visualizacao.isNotEmpty ? licao.visualizacao : licao.cena,
            style: Mixart.ui(size: 14, color: Mixart.text).copyWith(height: 1.5, fontStyle: FontStyle.italic)),
        const SizedBox(height: 8),
        Text('Feche os olhos por 3 segundos e veja o lugar. Depois diga cada frase em voz alta enquanto copia.',
            style: Mixart.ui(size: 11.5, color: Mixart.textMuted).copyWith(height: 1.45)),
        if (licao.fotoCredito.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('foto: ${licao.fotoCredito}', style: Mixart.ui(size: 9.5, color: Mixart.textFaint)),
        ],
      ]);
      return largo
          ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              foto,
              const SizedBox(width: 16),
              Expanded(child: texto),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [foto, const SizedBox(height: 12), texto]);
    });
  }
}
