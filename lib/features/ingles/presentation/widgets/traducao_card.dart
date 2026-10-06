import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../../core/util/abrir_url.dart';
import '../../../curso/domain/curriculo.dart';
import '../../domain/fonte_frase.dart';
import '../../domain/roteiro.dart';

/// A tradução em português EM CIMA da frase (o pedido do curso): a frase
/// natural grande, o "ao pé da letra" quando ajuda a ver a estrutura, a nota
/// curta da lição e os botões de áudio/dica.
class TraducaoCard extends StatelessWidget {
  final Trecho trecho;
  final ModoFrase modo;

  /// Mostra a nota ("Entenda") — na estreia e nas cópias.
  final bool mostrarNota;

  final bool audioAuto;
  final VoidCallback onOuvir, onOuvirDevagar;

  /// null = sem dica neste modo (copiando, a frase já está à vista).
  final VoidCallback? onDica;

  /// "Não sei" (Esc): mostra a frase inteira.
  final VoidCallback? onNaoSei;
  final VoidCallback? onAlternarAudio;

  /// Quem disse a fala do [Trecho.contexto] (achado na lição), se souber.
  final String quemDoContexto;

  /// Mostra a fala anterior em português (a frase dela ainda não foi
  /// concluída nesta lição).
  final bool contextoEmPt;

  const TraducaoCard({
    super.key,
    required this.trecho,
    required this.modo,
    this.mostrarNota = true,
    this.audioAuto = true,
    required this.onOuvir,
    required this.onOuvirDevagar,
    this.onDica,
    this.onNaoSei,
    this.onAlternarAudio,
    this.quemDoContexto = '',
    this.contextoEmPt = false,
  });

  @override
  Widget build(BuildContext context) {
    final estreito = MediaQuery.sizeOf(context).width < 560;
    final botoes = Wrap(spacing: 6, runSpacing: 6, children: [
      _Botao(icone: Icons.volume_up_rounded, dica: 'Ouvir em inglês', onTap: onOuvir),
      _Botao(icone: Icons.slow_motion_video_rounded, dica: 'Ouvir devagar', onTap: onOuvirDevagar),
      if (onDica != null)
        _Botao(
            icone: Icons.lightbulb_outline_rounded,
            dica: 'Dica: revela a palavra (Tab = uma letra, Tab Tab = a palavra)',
            onTap: onDica!),
      if (onNaoSei != null)
        _Botao(icone: Icons.visibility_outlined, dica: 'Não sei: mostra a frase (Esc)', onTap: onNaoSei!),
    ]);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: Mixart.brandSub,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (trecho.imagem.isNotEmpty)
            // a imagem do sentido da frase: vê-la junto com a tradução fixa
            // mais (e, de memória, é pista sem entregar as palavras)
            Container(
              width: estreito ? 54 : 70,
              height: estreito ? 54 : 70,
              margin: const EdgeInsets.only(right: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Mixart.bg,
                border: Border.all(color: Mixart.brandDim),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(trecho.imagem, style: TextStyle(fontSize: estreito ? 26 : 34)),
                ),
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('PT', style: Mixart.mono(size: 11, weight: FontWeight.w700, color: Mixart.brand)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (trecho.contexto.isNotEmpty) ...[
                Text(
                    '↳ ${_prefixoQuem(quemDoContexto)}'
                    '${contextoEmPt && trecho.contextoPt.isNotEmpty ? trecho.contextoPt : trecho.contexto}',
                    style: (contextoEmPt && trecho.contextoPt.isNotEmpty
                            ? Mixart.ui(size: 12.5, color: Mixart.textFaint)
                            : Mixart.mono(size: 12.5, color: Mixart.textFaint))
                        .copyWith(height: 1.4)),
                const SizedBox(height: 4),
              ],
              if (_nomeDeQuem(trecho.quem) case final nome?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(nome, style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand)),
                ),
              _TextoComAlvo(
                texto: trecho.dicaPlana,
                alvo: trecho.alvoPt,
                estilo: Mixart.display(size: estreito ? 19 : 23, color: Mixart.text).copyWith(height: 1.3),
              ),
              if (trecho.literal.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text('ao pé da letra: ${trecho.literal}',
                    style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(fontStyle: FontStyle.italic)),
              ],
            ]),
          ),
          if (!estreito) ...[const SizedBox(width: 8), botoes],
        ]),
        // no celular os botões descem para não espremer a tradução
        if (estreito) ...[const SizedBox(height: 10), botoes],
        if (mostrarNota && trecho.temConceito) ...[
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, size: 15, color: Mixart.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(Trecho.semTags(trecho.conceito),
                  style: Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.45)),
            ),
          ]),
        ],
        if (FonteFrase.ler(trecho.fonte) case final fonte?) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => abrirUrl(fonte.url),
            borderRadius: BorderRadius.circular(6),
            child: Text('ⓘ frase do ${fonte.rotulo}',
                style: Mixart.ui(size: 10.5, color: Mixart.textFaint)),
          ),
        ],
        if (onAlternarAudio != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: onAlternarAudio,
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(audioAuto ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                    size: 15, color: Mixart.textMuted),
                const SizedBox(width: 6),
                Text('áudio automático', style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

/// "Ana: " antes da fala anterior (vazio se não souber quem disse).
String _prefixoQuem(String quem) {
  final n = _nomeDeQuem(quem);
  return n == null ? '' : '$n: ';
}

/// Rótulo de quem fala ("Mike", "Você", "Atendente"); null = sem rótulo.
String? _nomeDeQuem(String quem) {
  if (quem.isEmpty) return null;
  if (quem == 'voce') return 'Você';
  if (quem == 'dra-lee') return 'Dra. Lee';
  final limpo = quem.replaceAll('-', ' ');
  return limpo[0].toUpperCase() + limpo.substring(1);
}

/// A tradução com o trecho do chunk-alvo destacado (alvo_pt).
class _TextoComAlvo extends StatelessWidget {
  final String texto, alvo;
  final TextStyle estilo;
  const _TextoComAlvo({required this.texto, required this.alvo, required this.estilo});

  @override
  Widget build(BuildContext context) {
    final i = alvo.isEmpty ? -1 : texto.indexOf(alvo);
    if (i < 0) return Text(texto, style: estilo);
    return Text.rich(TextSpan(style: estilo, children: [
      TextSpan(text: texto.substring(0, i)),
      TextSpan(
        text: alvo,
        style: TextStyle(color: Mixart.brand, decoration: TextDecoration.underline, decorationColor: Mixart.brandDim),
      ),
      TextSpan(text: texto.substring(i + alvo.length)),
    ]));
  }
}

class _Botao extends StatelessWidget {
  final IconData icone;
  final String dica;
  final VoidCallback onTap;
  const _Botao({required this.icone, required this.dica, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: dica,
        child: Material(
          color: Mixart.surfaceHi,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: Mixart.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(padding: const EdgeInsets.all(8), child: Icon(icone, size: 18, color: Mixart.brand)),
          ),
        ),
      );
}
