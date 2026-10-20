import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../domain/roteiro_treino.dart';

/// O título de cada passo da sessão ("Qual é a tradução?").
class TituloPasso extends StatelessWidget {
  final String texto;
  final String? emoji;
  const TituloPasso(this.texto, {super.key, this.emoji});

  @override
  Widget build(BuildContext context) => Text(
        emoji == null ? texto : '$emoji  $texto',
        style: Mixart.display(size: 22, weight: FontWeight.w800),
      );
}

/// Botão redondo de áudio (🔊 / 🐢).
class BotaoSom extends StatelessWidget {
  final IconData icone;
  final VoidCallback onTap;
  final String dica;
  final double tamanho;
  final bool destaque;
  const BotaoSom({
    super.key,
    required this.icone,
    required this.onTap,
    required this.dica,
    this.tamanho = 44,
    this.destaque = true,
  });

  @override
  Widget build(BuildContext context) {
    final fundo = destaque ? Mixart.brand : Mixart.surfaceHi;
    final cor = destaque ? Mixart.onBrand : Mixart.text;
    return Tooltip(
      message: dica,
      child: Material(
        color: fundo,
        shape: const CircleBorder(),
        child: InkWell(
          canRequestFocus: false,
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: tamanho,
            child: Icon(icone, size: tamanho * .5, color: cor),
          ),
        ),
      ),
    );
  }
}

/// A frase de exemplo com a [palavra] em destaque (todas as vezes que ela aparece).
class FraseComDestaque extends StatelessWidget {
  final String frase;
  final String palavra;
  final double tamanho;
  const FraseComDestaque({super.key, required this.frase, required this.palavra, this.tamanho = 16});

  @override
  Widget build(BuildContext context) {
    final base = Mixart.ui(size: tamanho, weight: FontWeight.w600, color: Mixart.text).copyWith(height: 1.45);
    final forte = base.copyWith(color: Mixart.brand, fontWeight: FontWeight.w800);
    final spans = <TextSpan>[];
    final re = RegExp('\\b${RegExp.escape(palavra)}\\b', caseSensitive: false);
    var i = 0;
    for (final m in re.allMatches(frase)) {
      if (m.start > i) spans.add(TextSpan(text: frase.substring(i, m.start)));
      spans.add(TextSpan(text: frase.substring(m.start, m.end), style: forte));
      i = m.end;
    }
    if (i < frase.length) spans.add(TextSpan(text: frase.substring(i)));
    return Text.rich(TextSpan(style: base, children: spans));
  }
}

/// Passo 1: a palavra nova — o inglês grande, o áudio (fala sozinha ao aparecer), a tradução e a
/// frase da lição em que ela apareceu.
class PassoConhecer extends StatefulWidget {
  final ItemTreino item;
  final void Function({required bool lenta}) onOuvir;

  /// Fala sozinha ao aparecer.
  final bool falarAoAbrir;

  /// O "relembrar" da revanche das teimosas: selo "🔁 RELEMBRAR", palavra menor, sem o verbete inteiro.
  final bool compacto;
  const PassoConhecer({
    super.key,
    required this.item,
    required this.onOuvir,
    this.falarAoAbrir = true,
    this.compacto = false,
  });

  @override
  State<PassoConhecer> createState() => _PassoConhecerState();
}

class _PassoConhecerState extends State<PassoConhecer> {
  @override
  void initState() {
    super.initState();
    if (widget.falarAoAbrir) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onOuvir(lenta: false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.item.palavra;
    final completa = p.ptCompleta.trim();
    final compacto = widget.compacto;
    final mostraCompleta = !compacto && completa.isNotEmpty && completa != widget.item.pt && completa != p.pt;
    return Column(
      key: Key(compacto ? 'passo-relembrar' : 'passo-conhecer'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Mixart.brandSub,
            border: Border.all(color: Mixart.brandDim),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(compacto ? '🔁 RELEMBRAR' : '🆕 PALAVRA NOVA',
              style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: .8)),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          decoration: BoxDecoration(
            color: Mixart.surface,
            borderRadius: BorderRadius.circular(Mixart.radiusLg),
            border: Border(
              top: BorderSide(color: Mixart.border, width: 1.5),
              left: BorderSide(color: Mixart.border, width: 1.5),
              right: BorderSide(color: Mixart.border, width: 1.5),
              bottom: BorderSide(color: Mixart.border, width: 5),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(p.en,
                      key: const Key('treino-prompt'),
                      style: Mixart.display(size: compacto ? 34 : 42, weight: FontWeight.w800, color: Mixart.brand)),
                ),
              ),
              const SizedBox(width: 14),
              BotaoSom(
                key: const Key('treino-ouvir'),
                icone: Icons.volume_up_rounded,
                dica: 'Ouvir',
                onTap: () => widget.onOuvir(lenta: false),
              ),
              const SizedBox(width: 8),
              BotaoSom(
                key: const Key('treino-ouvir-devagar'),
                icone: Icons.slow_motion_video_rounded,
                dica: 'Ouvir devagar 🐢',
                tamanho: 38,
                destaque: false,
                onTap: () => widget.onOuvir(lenta: true),
              ),
            ]),
            const SizedBox(height: 10),
            Text(widget.item.pt, style: Mixart.display(size: 22, weight: FontWeight.w700)),
            if (mostraCompleta) ...[
              const SizedBox(height: 4),
              Text(completa, style: Mixart.ui(size: 13, color: Mixart.textMuted).copyWith(height: 1.4)),
            ],
            if (p.exemplo.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Mixart.bg,
                  border: Border.all(color: Mixart.border),
                  borderRadius: BorderRadius.circular(Mixart.radiusMd),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(compacto ? 'EXEMPLO' : 'NA LIÇÃO',
                      style: Mixart.ui(size: 10, weight: FontWeight.w800, color: Mixart.textFaint)
                          .copyWith(letterSpacing: 1)),
                  const SizedBox(height: 6),
                  FraseComDestaque(frase: p.exemplo, palavra: p.en),
                  if (p.exemploPt.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(p.exemploPt,
                        style: Mixart.ui(size: 13, color: Mixart.textMuted)
                            .copyWith(fontStyle: FontStyle.italic, height: 1.4)),
                  ],
                ]),
              ),
            ],
          ]),
        ),
      ],
    );
  }
}
