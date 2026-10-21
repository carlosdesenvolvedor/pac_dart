import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/plano_treino.dart';

/// O cartão de uma etapa no hub do treino (chave `treino-dia-bloco-<id>`): emoji, título, subtítulo
/// (quantidade planejada e estimativa) e o selo do estado — "✓ Feito · {resultado}", "⏭ Pulado",
/// "▶ Agora" (a próxima pendente) ou "Depois". A etapa atual mostra também "Pular esta etapa"
/// (`treino-dia-pular`, um `TextButton` de verdade).
class CartaoBloco extends StatelessWidget {
  final BlocoTreino bloco;
  final String emoji;
  final String titulo;
  final String subtitulo;

  /// O texto depois de "✓ Feito · " (ex.: "3 revisadas"); null = só "✓ Feito".
  final String? resultado;

  /// É a próxima etapa pendente ("▶ Agora").
  final bool atual;

  /// "Pular esta etapa" (só na [atual]); null = sem o link.
  final VoidCallback? onPular;

  const CartaoBloco({
    super.key,
    required this.bloco,
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    this.resultado,
    this.atual = false,
    this.onPular,
  });

  /// O texto do selo (também é o que o leitor de tela fala do estado).
  String get rotuloEstado => switch (bloco.estado) {
        EstadoBloco.feito => resultado == null ? '✓ Feito' : '✓ Feito · $resultado',
        EstadoBloco.pulado => '⏭ Pulado',
        EstadoBloco.pendente => atual ? '▶ Agora' : 'Depois',
      };

  @override
  Widget build(BuildContext context) {
    final feito = bloco.estado == EstadoBloco.feito;
    final pulado = bloco.estado == EstadoBloco.pulado;
    final (Color fundoSelo, Color textoSelo, Color bordaSelo) = switch (bloco.estado) {
      EstadoBloco.feito => (Mixart.brandSub, Mixart.brand, Mixart.brandDim),
      EstadoBloco.pulado => (Mixart.surfaceHi, Mixart.textFaint, Mixart.border),
      EstadoBloco.pendente => atual
          ? (Mixart.brand, Mixart.onBrand, Mixart.brand)
          : (Mixart.surfaceHi, Mixart.textMuted, Mixart.border),
    };
    final apagado = pulado;
    return Semantics(
      container: true,
      label: '$titulo. $subtitulo. ${rotuloEstado.replaceAll('▶ ', '').replaceAll('⏭ ', '')}',
      excludeSemantics: onPular == null,
      child: AnimatedContainer(
        key: Key('treino-dia-bloco-${bloco.id}'),
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: atual ? Mixart.surfaceHi : Mixart.surface,
          border: Border.all(color: atual ? Mixart.brand : (feito ? Mixart.brandDim : Mixart.border), width: atual ? 1.6 : 1),
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
        ),
        // o rótulo acima já diz título, subtítulo e estado: as partes visuais ficam fora da árvore de
        // acessibilidade (senão o cartão atual, que tem o "Pular", seria lido duas vezes)
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ExcludeSemantics(
            child: Opacity(
              opacity: apagado ? .45 : 1,
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: atual || feito ? Mixart.brandSub : Mixart.surfaceHi,
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ExcludeSemantics(
                child: Text(titulo,
                    style: Mixart.display(size: 16, color: apagado ? Mixart.textFaint : Mixart.text).copyWith(
                      decoration: pulado ? TextDecoration.lineThrough : null,
                      decorationColor: Mixart.textFaint,
                    )),
              ),
              const SizedBox(height: 3),
              ExcludeSemantics(
                child: Text(subtitulo,
                    style: Mixart.ui(size: 12, color: apagado ? Mixart.textFaint : Mixart.textMuted)
                        .copyWith(height: 1.4)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      key: Key('treino-dia-selo-${bloco.id}'),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: fundoSelo,
                        border: Border.all(color: bordaSelo),
                        borderRadius: BorderRadius.circular(Mixart.radiusChip),
                      ),
                      child: Text(rotuloEstado,
                          style: Mixart.ui(size: 12, weight: FontWeight.w700, color: textoSelo)),
                    ),
                  ),
                  if (atual && onPular != null)
                    TextButton(
                      key: const Key('treino-dia-pular'),
                      onPressed: onPular,
                      style: TextButton.styleFrom(
                        foregroundColor: Mixart.textMuted,
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        textStyle: Mixart.ui(size: 12.5, weight: FontWeight.w600),
                      ),
                      child: const Text('Pular esta etapa'),
                    ),
                ],
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
