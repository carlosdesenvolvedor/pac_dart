import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/entrada_resposta.dart';

/// A barra de modos acima da frase: ⌨️ Digitar · 🎤 Falar · 🧩 Montar. A pessoa escolhe COMO responde cada passo.
/// [falarDisponivel] = false (o navegador não reconhece voz) tira o Falar da barra.
class SeletorEntrada extends StatelessWidget {
  final EntradaResposta entrada;
  final bool falarDisponivel;
  final ValueChanged<EntradaResposta> onMudar;

  const SeletorEntrada({super.key, required this.entrada, required this.onMudar, this.falarDisponivel = true});

  @override
  Widget build(BuildContext context) {
    final opcoes = [
      for (final e in EntradaResposta.values)
        if (e != EntradaResposta.falar || falarDisponivel) e,
    ];
    return Semantics(
      container: true,
      label: 'Como responder',
      child: Row(children: [
        for (var i = 0; i < opcoes.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: _Pilula(opcao: opcoes[i], ativa: opcoes[i] == entrada, aoTocar: () => onMudar(opcoes[i]))),
        ],
      ]),
    );
  }
}

class _Pilula extends StatelessWidget {
  final EntradaResposta opcao;
  final bool ativa;
  final VoidCallback aoTocar;
  const _Pilula({required this.opcao, required this.ativa, required this.aoTocar});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: ativa,
        label: opcao.rotulo,
        excludeSemantics: true,
        child: Material(
          color: ativa ? Mixart.brand : Mixart.surfaceHi,
          shape: StadiumBorder(side: BorderSide(color: ativa ? Mixart.brand : Mixart.border, width: 1.2)),
          child: InkWell(
            key: Key('entrada-${opcao.id}'),
            customBorder: const StadiumBorder(),
            canRequestFocus: false,
            onTap: aoTocar,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  // a fonte grande ou a tela estreita encolhem o rótulo em vez de estourar a pílula
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('${opcao.emoji} ${opcao.rotulo}',
                        maxLines: 1,
                        style: Mixart.ui(size: 13, weight: FontWeight.w800, color: ativa ? Mixart.onBrand : Mixart.textMuted)),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
