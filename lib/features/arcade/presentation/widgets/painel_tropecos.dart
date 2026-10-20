import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../../core/ui/festa.dart';
import '../../../ingles/domain/teimosas.dart';
import '../../../ingles/presentation/widgets/cartao_teimosas.dart';

/// Entre as fases do Rali (o jogo já está parado): as palavras que escaparam nesta partida e duas saídas —
/// treinar só elas agora (1 minuto, volta para a mesma tela) ou seguir para a próxima fase com elas na
/// frente do baralho.
class PainelTropecos extends StatelessWidget {
  /// (como se escreve, tradução ou null, vezes que escapou).
  final List<(String, String?, int)> palavras;
  final VoidCallback onTreinar;
  final VoidCallback onFocar;

  const PainelTropecos({
    super.key = const Key('rali-teimosas'),
    required this.palavras,
    required this.onTreinar,
    required this.onFocar,
  });

  @override
  Widget build(BuildContext context) {
    if (palavras.isEmpty) return const SizedBox.shrink();
    final cor = escurecer(CoresFesta.coral, quanto: .2, soNoClaro: true);
    final uma = palavras.length == 1;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cor.withValues(alpha: .10), Mixart.surface),
        border: Border.all(color: cor.withValues(alpha: .6)),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(uma ? '🔥 Essa palavra escapou nesta partida' : '🔥 Essas palavras escaparam nesta partida',
            textAlign: TextAlign.center, style: Mixart.display(size: 15, color: Mixart.text)),
        const SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
          for (final (en, pt, vezes) in palavras.take(6)) _chip(en, pt, vezes, cor),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          FilledButton(
            key: const Key('rali-treinar-teimosas'),
            style: FilledButton.styleFrom(
              backgroundColor: cor,
              foregroundColor: corSobre(cor),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
            ),
            onPressed: onTreinar,
            child: const Text('🎯 Treinar agora (1 min)'),
          ),
          OutlinedButton(
            key: const Key('rali-proxima-com-elas'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Mixart.text,
              side: BorderSide(color: cor.withValues(alpha: .7)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
            ),
            onPressed: onFocar,
            child: Text(uma ? '⚡ Próxima fase com ela' : '⚡ Próxima fase com elas'),
          ),
        ]),
      ]),
    );
  }

  Widget _chip(String en, String? pt, int vezes, Color cor) => Container(
        constraints: const BoxConstraints(maxWidth: 240),
        padding: const EdgeInsets.fromLTRB(10, 5, 6, 5),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(en, style: Mixart.mono(size: 13.5, weight: FontWeight.w800, color: Mixart.text)),
          if (pt != null && pt.isNotEmpty) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(pt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textMuted)),
            ),
          ],
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: cor.withValues(alpha: .18), borderRadius: BorderRadius.circular(999)),
            child: Text('${vezes}x', style: Mixart.ui(size: 10.5, weight: FontWeight.w900, color: cor)),
          ),
        ]),
      );
}

/// A linha passiva da pausa: '📝 Anotadas nesta partida: through ×2 · enough ×1'. A pausa tem sempre o
/// fundo quase preto (nas duas paletas), então a cor do texto é fixa e clara.
class LinhaAnotadas extends StatelessWidget {
  final String texto;
  const LinhaAnotadas(this.texto, {super.key = const Key('pausa-anotadas')});

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Text(texto,
            textAlign: TextAlign.center,
            style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: const Color(0xFFF4F1EA))
                .copyWith(height: 1.4)),
      );
}

/// A oferta do fim de jogo (Chuva, Rali, Turismo): o [CartaoTeimosas] enxuto e "⚡ Revanche no jogo" (as
/// palavras em foco e outra partida).
class OfertaTeimosasFim extends StatelessWidget {
  final SugestaoTeimosas sugestao;
  final VoidCallback onTreinar;
  final VoidCallback onRevanche;
  final VoidCallback? onAgoraNao;

  const OfertaTeimosasFim({
    super.key,
    required this.sugestao,
    required this.onTreinar,
    required this.onRevanche,
    this.onAgoraNao,
  });

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CartaoTeimosas(
            palavras: sugestao.itens,
            compacto: true,
            daSessao: sugestao.daSessao,
            onTreinar: onTreinar,
            onAgoraNao: onAgoraNao,
          ),
          const SizedBox(height: 4),
          TextButton(
            key: const Key('fim-revanche'),
            onPressed: onRevanche,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('⚡ Revanche no jogo',
                // o fundo do fim de jogo é sempre quase preto: amarelo Mixart fixo (o azul do claro some)
                style: Mixart.ui(size: 13, weight: FontWeight.w700, color: const Color(0xFFFFC73B))),
          ),
        ]),
      );
}
