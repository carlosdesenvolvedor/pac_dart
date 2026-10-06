import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../banco_arcade.dart';

import '../../../../core/theme/mixart.dart';

/// 📖 Tutorial da 1ª corrida (um por modo de controle): três cartões e o
/// botão de largar. Enter também larga. Só aparece uma vez — a página guarda
/// a preferência.
class TutorialTurismo extends StatelessWidget {
  final bool porSetas;
  final VoidCallback onLargar;
  const TutorialTurismo({super.key, required this.porSetas, required this.onLargar});

  static const _digitacao = [
    ('🛣️', 'A palavra é o volante',
        'Cada portal mostra uma palavra sobre a faixa LIVRE. Digite-a e o carro entra nessa faixa. '
            'As outras faixas têm tráfego — encostar nele é batida.'),
    ('⛽', 'Digitar é acelerar',
        'Toda tecla certa dá gás e a palavra de COMBUSTÍVEL segura a velocidade entre os portais. '
            'Parou de digitar? O carro vai parando.'),
    ('🪙', 'Fichas, moedas e medalhas',
        'Passe por cima das fichas de código na faixa livre pra ganhar moedas (elas compram carros na garagem). '
            'Feche a pista no tempo: 🥇 ouro, 🥈 prata ou 🥉 bronze. Esc pausa e 🎥 troca a câmera.'),
  ];

  static const _setas = [
    ('🎮', '← → trocam de faixa',
        'As placas mostram a SETA da faixa livre do próximo portal: vá pra ela. '
            'As outras faixas têm tráfego — encostar nele é batida.'),
    ('⬆️', '↑ acelera · ↓ freia',
        'Segure ↑ o tempo todo e use ↓ só quando precisar. No celular, os botões ▲ GÁS e ▼ FREIO fazem o mesmo; '
            'A/D/W/S também servem.'),
    ('🪙', 'Fichas, moedas e medalhas',
        'Passe por cima das fichas de código na faixa livre pra ganhar moedas (elas compram carros na garagem). '
            'Feche a pista no tempo: 🥇 ouro, 🥈 prata ou 🥉 bronze. Esc pausa e C troca a câmera.'),
  ];

  @override
  Widget build(BuildContext context) {
    final passos = porSetas ? _setas : _digitacao;
    return Positioned.fill(
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, ev) {
          if (ev is KeyDownEvent &&
              (ev.logicalKey == LogicalKeyboardKey.enter || ev.logicalKey == LogicalKeyboardKey.space)) {
            onLargar();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          color: const Color(0xF2070910),
          padding: const EdgeInsets.all(20),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('COMO JOGAR · ${porSetas ? '🎮 MODO SETAS' : '⌨️ MODO DIGITAÇÃO'}',
                      style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand).copyWith(letterSpacing: 2)),
                  const SizedBox(height: 6),
                  Text('🏎️ ${BancoArcade.linguagem} Turismo', style: Mixart.display(size: 24)),
                  const SizedBox(height: 16),
                  for (var i = 0; i < passos.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    _passo(i + 1, passos[i].$1, passos[i].$2, passos[i].$3),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Mixart.brand,
                      foregroundColor: Mixart.onBrand,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: Mixart.ui(size: 13.5, weight: FontWeight.w700),
                    ),
                    onPressed: onLargar,
                    child: const Text('Entendi, largar!  ↵'),
                  ),
                  const SizedBox(height: 8),
                  Text('este guia aparece só na sua primeira corrida neste modo',
                      style: Mixart.ui(size: 10.5, color: Mixart.textFaint)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _passo(int n, String emoji, String titulo, String texto) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Mixart.brandSub, shape: BoxShape.circle),
          child: Text(emoji, style: const TextStyle(fontSize: 20)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$n · $titulo', style: Mixart.display(size: 14.5)),
            const SizedBox(height: 4),
            Text(texto, style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}
