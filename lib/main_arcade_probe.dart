// Entrypoint de PROVA VISUAL do Arcade (sem Firebase): renderiza a pista em
// várias fases, os personagens e um cenário cru — para screenshot headless.
//   flutter build web -t lib/main_arcade_probe.dart --output=build/probe
import 'package:flutter/material.dart';

import 'core/theme/mixart.dart';
import 'features/arcade/domain/gerador_missoes.dart';
import 'features/arcade/domain/personagem.dart';
import 'features/arcade/presentation/widgets/arcade_ui.dart';
import 'features/arcade/presentation/widgets/avatares.dart';
import 'features/arcade/presentation/widgets/cenario.dart';
import 'features/arcade/presentation/widgets/cenas.dart';

void main() => runApp(const _ProbeApp());

class _ProbeApp extends StatelessWidget {
  const _ProbeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Mixart.tema(),
      home: Scaffold(
        backgroundColor: Mixart.bg,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('PistaPro — fases 1, 3 e 5', style: Mixart.display(size: 16)),
                const SizedBox(height: 8),
                const PistaPro(posJogador: 5, posCpu: 3, pista: 12, fase: 1),
                const SizedBox(height: 12),
                const PistaPro(posJogador: 9, posCpu: 7, pista: 12, fase: 3),
                const SizedBox(height: 12),
                const PistaPro(posJogador: 2, posCpu: 4, pista: 12, fase: 5),
                const SizedBox(height: 16),
                Text('Personagens', style: Mixart.display(size: 16)),
                const SizedBox(height: 8),
                const Row(children: [
                  AvatarPersonagem(tamanho: 64, personagem: Personagem.pac),
                  SizedBox(width: 24),
                  AvatarPersonagem(tamanho: 64, personagem: Personagem.dash),
                ]),
                const SizedBox(height: 16),
                Text('Cenas do Lógica Animada', style: Mixart.display(size: 16)),
                const SizedBox(height: 8),
                // porta no meio do caminho
                CenaMissao(
                  missao: missaoPara(0, 2),
                  estado: {...missaoPara(0, 2).dados, 'avanco': 3},
                  trilha: 0,
                ),
                const SizedBox(height: 10),
                // blitz com vereditos parciais
                CenaMissao(
                  missao: missaoPara(1, 0),
                  estado: {...missaoPara(1, 0).dados, 'atual': 1, 'v0': true, 'v1': false},
                  trilha: 1,
                ),
                const SizedBox(height: 10),
                // foguete no meio da contagem
                CenaMissao(
                  missao: missaoPara(1, 3),
                  estado: {...missaoPara(1, 3).dados, 'contagem': 2},
                  trilha: 4,
                ),
                const SizedBox(height: 16),
                Text('Cenários crus — fases 2, 4 e 6', style: Mixart.display(size: 16)),
                const SizedBox(height: 8),
                Row(children: [
                  for (final f in [2, 4, 6]) ...[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(height: 120, child: CenarioFase(fase: f)),
                      ),
                    ),
                    if (f != 6) const SizedBox(width: 10),
                  ],
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
