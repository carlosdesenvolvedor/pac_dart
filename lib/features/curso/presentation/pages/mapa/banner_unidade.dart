// A faixa de abertura de cada unidade do mapa do PAC·ENGLISH (estilo Duolingo): um cartão na cor da etapa,
// com lábio mais escuro, "UNIDADE N · A2", o nome, o progresso, o rosto do personagem principal e o
// botão "📖 Guia".
import 'package:flutter/material.dart';

import '../../../../../core/som/sons.dart';
import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../../ingles/presentation/widgets/elenco_ingles.dart';
import 'no_3d.dart' show FocoDeTeclado;

class BannerUnidade extends StatelessWidget {
  /// "UNIDADE 3 · A2" (ou "MEU TEXTO" numa trilha própria).
  final String sobretitulo;
  final String emoji, nome;

  /// A linha "X de N lições · Y frases".
  final String detalhe;
  final double progresso;
  final Color cor;
  final bool atual, completa;

  /// O personagem principal (quem mais fala); null = mostra o emoji da trilha.
  final Aparencia? rosto;
  final VoidCallback? onGuia;

  /// Ação extra no canto (o "apagar" das trilhas próprias).
  final Widget? acao;

  const BannerUnidade({
    super.key,
    required this.sobretitulo,
    required this.emoji,
    required this.nome,
    required this.detalhe,
    required this.progresso,
    required this.cor,
    this.atual = false,
    this.completa = false,
    this.rosto,
    this.onGuia,
    this.acao,
  });

  static const labio = 5.0;

  @override
  Widget build(BuildContext context) {
    final texto = corSobre(cor);
    final suave = texto.withValues(alpha: .78);
    final escuro = escurecer(cor, quanto: .3);
    return Container(
      padding: const EdgeInsets.only(bottom: labio),
      decoration: BoxDecoration(
        color: escuro,
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        boxShadow: atual ? [BoxShadow(color: cor.withValues(alpha: .35), blurRadius: 28, spreadRadius: -8)] : null,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(Mixart.radiusLg),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.lerp(cor, Colors.white, .1)!, cor],
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(
                    sobretitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.ui(size: 11, weight: FontWeight.w900, color: suave).copyWith(letterSpacing: 1.6),
                  ),
                ),
                if (completa) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.verified, size: 15, color: texto),
                ] else if (atual) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: texto.withValues(alpha: .16),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: texto.withValues(alpha: .45)),
                    ),
                    child: Text('ATUAL',
                        style: Mixart.ui(size: 9, weight: FontWeight.w800, color: texto).copyWith(letterSpacing: 1)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text(
                '$emoji $nome',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Mixart.display(size: 18, weight: FontWeight.w800, color: texto).copyWith(height: 1.15),
              ),
              const SizedBox(height: 4),
              Text(detalhe,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: suave)),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 7,
                  child: Stack(fit: StackFit.expand, children: [
                    ColoredBox(color: escuro.withValues(alpha: .55)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progresso.clamp(0.0, 1.0),
                      child: ColoredBox(color: texto.withValues(alpha: .92)),
                    ),
                  ]),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.lerp(cor, Colors.white, .35),
                  border: Border.all(color: escuro, width: 2.5),
                ),
                child: ClipOval(
                  child: rosto != null
                      ? Transform.translate(
                          offset: const Offset(0, 4),
                          child: RostoPersonagem(aparencia: rosto!, tamanho: 60),
                        )
                      : Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
                ),
              ),
              if (acao != null) Positioned(right: -14, top: -14, child: acao!),
            ]),
            if (onGuia != null) ...[
              const SizedBox(height: 8),
              _BotaoGuia(cor: escuro, texto: texto, onTap: onGuia!),
            ],
          ]),
        ]),
      ),
    );
  }
}

class _BotaoGuia extends StatefulWidget {
  final Color cor, texto;
  final VoidCallback onTap;
  const _BotaoGuia({required this.cor, required this.texto, required this.onTap});

  @override
  State<_BotaoGuia> createState() => _BotaoGuiaState();
}

class _BotaoGuiaState extends State<_BotaoGuia> {
  bool _foco = false; // anel de foco do teclado

  void _tocar() {
    Sons.toca(Som.blip);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Guia da unidade',
        child: FocoDeTeclado(
          onAtivar: _tocar,
          onFoco: (v) => setState(() => _foco = v),
          child: GestureDetector(
            key: const Key('mapa-guia'),
            behavior: HitTestBehavior.opaque,
            onTap: _tocar,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: widget.cor.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(10),
                border: _foco
                    ? Border.all(color: widget.texto, width: 2)
                    : Border.all(color: widget.texto.withValues(alpha: .35)),
              ),
              child: ExcludeSemantics(
                child: Text('📖 GUIA',
                    style:
                        Mixart.ui(size: 10.5, weight: FontWeight.w900, color: widget.texto).copyWith(letterSpacing: .8)),
              ),
            ),
          ),
        ),
      );
}
