import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// Fundo temático da fase (trilha), como cenário de jogo. A foto fica atrás
/// de tudo, escurecida por um véu que segue a paleta ativa — não atrapalha
/// a leitura, só dá clima.
class FundoFase extends StatelessWidget {
  final String nivel;
  const FundoFase({super.key, required this.nivel});

  static const _porTrilha = {
    'Fundamentos': 'fundamentos',
    'Lógica': 'logica',
    'Coleções': 'colecoes',
    'Objetos': 'objetos',
    'Avançado': 'avancado',
    'Flutter': 'flutter',
    'Desafios': 'desafios',
    'Pacotes': 'pacotes',
  };

  static String asset(String nivel) =>
      'assets/backgrounds/${_porTrilha[nivel] ?? 'fundamentos'}.jpg';

  @override
  Widget build(BuildContext context) {
    final claro = Mixart.atual.ehClaro;
    final bg = Mixart.bg;
    // Cenário visível no topo, fica sólido embaixo (área de código limpa).
    // No tema claro o véu é mais forte, senão a foto "suja" o branco.
    final cores = claro
        ? [bg.withValues(alpha: .74), bg.withValues(alpha: .90), bg.withValues(alpha: .97)]
        : [bg.withValues(alpha: .38), bg.withValues(alpha: .76), bg.withValues(alpha: .95)];
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset(nivel),
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => const SizedBox.shrink(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: cores,
                stops: const [0, .48, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
