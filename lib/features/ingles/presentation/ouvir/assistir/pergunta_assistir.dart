import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../domain/assistir/pergunta_compreensao.dart';

/// 📺❓ O cartão da pergunta OPCIONAL do fim da historinha da lição (por cima do palco, no véu do fim).
/// Antes de responder: as 3 opções, o 🔊 da frase e "Pular". Depois: a certa em verde (a errada escolhida
/// em vermelho), "Ver de novo" e "Voltar para a lição". Não grava nada: quem decide é a [AssistirLicaoPage].
///
/// Keys: `assistir-pergunta`, `assistir-pergunta-opcao-<i>`, `assistir-pergunta-ouvir`,
/// `assistir-pergunta-resultado`, `assistir-pergunta-pular`, `assistir-pergunta-de-novo`,
/// `assistir-pergunta-voltar`.
class PerguntaAssistir extends StatelessWidget {
  const PerguntaAssistir({
    super.key,
    required this.pergunta,
    required this.escolha,
    required this.onEscolher,
    required this.onOuvir,
    required this.onPular,
    required this.onDeNovo,
    required this.onVoltar,
  });

  final PerguntaCompreensao pergunta;

  /// A opção escolhida (null = ainda não respondeu).
  final int? escolha;
  final ValueChanged<int> onEscolher;
  final VoidCallback onOuvir, onPular, onDeNovo, onVoltar;

  /// O verde do "certo" (o mesmo da pastilha e dos cartões).
  static const verde = Color(0xFF4CD08A);

  static const _fundo = Color(0xFF16161F);

  @override
  Widget build(BuildContext context) {
    final respondida = escolha != null;
    final acertou = escolha == pergunta.certa;
    return ColoredBox(
      key: const Key('assistir-pergunta'),
      color: const Color(0xD90E0E14),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _fundo,
                borderRadius: BorderRadius.circular(Mixart.radiusLg),
                border: Border.all(color: Mixart.brandDim),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('❓ Pergunta rápida · opcional',
                      style: Mixart.ui(size: 12, weight: FontWeight.w700, color: Mixart.brand)),
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Expanded(
                      child: Text(pergunta.enunciado,
                          style: Mixart.ui(size: 17, weight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('assistir-pergunta-ouvir'),
                      tooltip: 'Ouvir a frase',
                      onPressed: onOuvir,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      icon: Icon(Icons.volume_up_rounded, size: 26, color: Mixart.brand),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  for (var i = 0; i < pergunta.opcoes.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _opcao(i),
                  ],
                  if (respondida) ...[
                    const SizedBox(height: 10),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        acertou ? '✅ Isso!' : '❌ Quase! A certa é «${pergunta.opcoes[pergunta.certa]}».',
                        key: const Key('assistir-pergunta-resultado'),
                        style: Mixart.ui(size: 14, weight: FontWeight.w700, color: acertou ? verde : Colors.white),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (!respondida)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: const Key('assistir-pergunta-pular'),
                        onPressed: onPular,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(88, 48),
                          // no desktop a densidade compacta encolheria para 40 px
                          visualDensity: VisualDensity.standard,
                          foregroundColor: Colors.white70,
                        ),
                        child: Text('Pular', style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Colors.white70)),
                      ),
                    )
                  else
                    Wrap(alignment: WrapAlignment.end, spacing: 8, runSpacing: 8, children: [
                      OutlinedButton.icon(
                        key: const Key('assistir-pergunta-voltar'),
                        onPressed: onVoltar,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          // no desktop a densidade compacta encolheria para 40 px
                          visualDensity: VisualDensity.standard,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        icon: const Icon(Icons.arrow_back_rounded, size: 20),
                        label: Text('Voltar para a lição',
                            style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Colors.white)),
                      ),
                      FilledButton.icon(
                        key: const Key('assistir-pergunta-de-novo'),
                        onPressed: onDeNovo,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          // no desktop a densidade compacta encolheria para 40 px
                          visualDensity: VisualDensity.standard,
                          backgroundColor: Mixart.brand,
                          foregroundColor: Mixart.onBrand,
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 20),
                        label: Text('Ver de novo',
                            style: Mixart.ui(size: 14, weight: FontWeight.w800, color: Mixart.onBrand)),
                      ),
                    ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A opção [i]: "1  Mike". Depois de responder, a certa fica verde (✓) e a errada escolhida vermelha (✗).
  Widget _opcao(int i) {
    final respondida = escolha != null;
    final certa = i == pergunta.certa;
    final errada = respondida && i == escolha && !certa;
    final marca = respondida && certa ? verde : (errada ? Mixart.danger : null);
    final texto = pergunta.opcoes[i];
    final estado = !respondida ? '' : (certa ? ', certa' : (errada ? ', errada' : ''));
    return Semantics(
      button: true,
      enabled: !respondida,
      label: 'Opção ${i + 1}: $texto$estado',
      excludeSemantics: true,
      child: Material(
        color: marca == null ? const Color(0xFF22222E) : marca.withValues(alpha: .16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          side: BorderSide(color: marca ?? Colors.white24, width: marca == null ? 1 : 2),
        ),
        child: InkWell(
          key: Key('assistir-pergunta-opcao-$i'),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          onTap: respondida ? null : () => onEscolher(i),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Text('${i + 1}', style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Colors.white54)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(texto, style: Mixart.ui(size: 15, weight: FontWeight.w700, color: Colors.white)),
                ),
                if (marca != null) ...[
                  const SizedBox(width: 8),
                  Icon(certa ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 22, color: marca),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
