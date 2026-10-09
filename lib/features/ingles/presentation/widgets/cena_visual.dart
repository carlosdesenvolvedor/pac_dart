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

  Widget _foto(double largura, double altura) => SizedBox(
        width: largura,
        height: altura,
        // zoom lento enquanto a pessoa visualiza a cena (dá sensação de estar lá)
        child: FotoCena(
          licao: licao,
          altura: altura,
          zoom: compacta ? null : const Duration(seconds: 14),
          emojiFator: compacta ? .42 : .34,
        ),
      );

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

/// A foto da cena preenchendo o espaço que receber (sem foto, os emojis da
/// cena num degradê). Com [zoom], aproxima devagar até [escala] — usada no
/// cartão do palco e em tela cheia no ensaio mental.
///
/// Sem LayoutBuilder de propósito: no ensaio ela vive num OverlayPortal que
/// muda de lugar (GlobalKey) quando a janela cruza a largura do painel do
/// tutor, e um LayoutBuilder ali dentro dispara a asserção de "mutated in
/// performLayout".
class FotoCena extends StatelessWidget {
  final Licao licao;
  final Duration? zoom;
  final double escala;

  /// Altura da caixa (o tamanho dos emojis, sem foto, sai dela).
  final double altura;

  /// Tamanho dos emojis (sem foto) em fração da [altura].
  final double emojiFator;

  const FotoCena(
      {super.key, required this.licao, required this.altura, this.zoom, this.escala = 1.08, this.emojiFator = .34});

  @override
  Widget build(BuildContext context) {
    final fundo = Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Mixart.brandSub, Mixart.surfaceHi])),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      // emojis proporcionais à caixa; numa caixa estreita encolhem para caber
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(licao.imagem.isEmpty ? licao.emoji : licao.imagem,
            style: TextStyle(fontSize: altura * emojiFator), textAlign: TextAlign.center),
      ),
    );
    final foto = licao.foto.isEmpty
        ? fundo
        : Image.asset(licao.foto, fit: BoxFit.cover, errorBuilder: (_, _, _) => fundo);
    final cheia = SizedBox.expand(child: foto);
    final z = zoom;
    if (z == null || licao.foto.isEmpty) return cheia;
    return ClipRect(
      child: TweenAnimationBuilder<double>(
        key: ValueKey(licao.foto),
        tween: Tween(begin: 1, end: escala),
        duration: z,
        curve: Curves.easeOut,
        builder: (_, e, filho) => Transform.scale(scale: e, child: filho),
        child: cheia,
      ),
    );
  }
}
