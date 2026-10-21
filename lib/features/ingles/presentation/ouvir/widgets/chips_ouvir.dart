import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../domain/config_ouvir.dart';

// Os chips do "Tocando agora" (velocidade, modo, repetir, pausa, tradução, repetir tudo, timer), o chip da
// fase (🔊 Ouça / 🇧🇷 Tradução / 🧠 Pense / 🗣️ Sua vez) e os rótulos em português que as telas do Ouvir usam.

/// 0,75× / 0,9× / 1× / 1,15×.
String rotuloVelocidade(double v) {
  var s = v.toStringAsFixed(2);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${s.replaceAll('.', ',')}×';
}

String rotuloModo(ModoOuvir m) => switch (m) {
      ModoOuvir.soIngles => 'Só inglês',
      ModoOuvir.inglesPortugues => 'Inglês → português',
      ModoOuvir.portuguesIngles => 'Português → inglês',
    };

String rotuloPausa(PausaOuvir p) => switch (p) {
      PausaOuvir.curta => 'Curta',
      PausaOuvir.media => 'Média',
      PausaOuvir.longa => 'Longa',
      PausaOuvir.eco => 'Eco 🗣',
    };

String rotuloDesligar(DesligarEm d) => switch (d) {
      DesligarEm.nunca => 'Desligado',
      DesligarEm.min15 => '15 min',
      DesligarEm.min30 => '30 min',
      DesligarEm.min60 => '1 h',
      DesligarEm.fimDaLicao => 'No fim da lição',
    };

/// O texto do chip da fase. "(vez/de)" só aparece quando a frase repete.
String rotuloFase(FaseOuvir f, {int vez = 1, int de = 1}) => switch (f) {
      FaseOuvir.ouvindo => de > 1 ? '🔊 Ouça ($vez/$de)' : '🔊 Ouça',
      FaseOuvir.traducao => '🇧🇷 Tradução',
      FaseOuvir.pense => '🧠 Pense: como se diz em inglês?',
      FaseOuvir.suaVez => '🗣️ Sua vez — repita em voz alta',
      FaseOuvir.respiro => '⏸ Respiro',
    };

T _proximo<T>(List<T> valores, T atual) {
  final i = valores.indexOf(atual);
  return valores[(i + 1) % valores.length];
}

/// Os ajustes do player, em chips que quebram linha. Cada toque passa para o próximo valor (ou liga/desliga).
class ChipsOuvir extends StatelessWidget {
  final ConfigOuvir config;
  final DesligarEm desligar;
  final ValueChanged<ConfigOuvir> onConfig;
  final ValueChanged<DesligarEm> onDesligar;

  const ChipsOuvir({
    super.key,
    required this.config,
    required this.desligar,
    required this.onConfig,
    required this.onDesligar,
  });

  @override
  Widget build(BuildContext context) {
    final c = config;
    // uma velocidade fora da lista (pref antiga) volta para 1×
    final velocidades = ConfigOuvir.velocidades;
    final proximaVelocidade =
        velocidades.contains(c.velocidade) ? _proximo(velocidades, c.velocidade) : 1.0;
    final proximoModo = _proximo(ModoOuvir.values, c.modo);
    final proximasRepeticoes = c.repeticoes >= 3 ? 1 : c.repeticoes + 1;
    final proximaPausa = _proximo(PausaOuvir.values, c.pausa);
    final proximoDesligar = _proximo(DesligarEm.values, desligar);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ChipOuvir(
          key: const Key('chip-velocidade'),
          rotulo: 'Velocidade ${rotuloVelocidade(c.velocidade)}',
          icone: Icons.speed_rounded,
          ativo: c.velocidade != 1.0,
          dica: 'mudar para ${rotuloVelocidade(proximaVelocidade)}',
          onTap: () => onConfig(c.copyWith(velocidade: proximaVelocidade)),
        ),
        ChipOuvir(
          key: const Key('chip-modo'),
          rotulo: rotuloModo(c.modo),
          icone: Icons.translate_rounded,
          ativo: c.modo != ModoOuvir.soIngles,
          dica: 'mudar para ${rotuloModo(proximoModo)}',
          onTap: () => onConfig(c.copyWith(modo: proximoModo)),
        ),
        ChipOuvir(
          key: const Key('chip-repetir'),
          rotulo: 'Repetir ${c.repeticoes}×',
          icone: Icons.repeat_one_rounded,
          ativo: c.repeticoes > 1,
          dica: 'mudar para $proximasRepeticoes×',
          onTap: () => onConfig(c.copyWith(repeticoes: proximasRepeticoes)),
        ),
        ChipOuvir(
          key: const Key('chip-devagar'),
          rotulo: '2ª vez devagar',
          icone: Icons.slow_motion_video_rounded,
          ativo: c.segundaDevagar,
          alternavel: true,
          onTap: () => onConfig(c.copyWith(segundaDevagar: !c.segundaDevagar)),
        ),
        ChipOuvir(
          key: const Key('chip-pausa'),
          rotulo: 'Pausa: ${rotuloPausa(c.pausa)}',
          icone: Icons.hourglass_empty_rounded,
          ativo: c.pausa != PausaOuvir.media,
          dica: 'mudar para ${rotuloPausa(proximaPausa)}',
          onTap: () => onConfig(c.copyWith(pausa: proximaPausa)),
        ),
        ChipOuvir(
          key: const Key('chip-traducao'),
          rotulo: 'Tradução',
          icone: c.mostrarTraducao ? Icons.subtitles_rounded : Icons.subtitles_off_rounded,
          ativo: c.mostrarTraducao,
          alternavel: true,
          onTap: () => onConfig(c.copyWith(mostrarTraducao: !c.mostrarTraducao)),
        ),
        ChipOuvir(
          key: const Key('chip-imagens'),
          rotulo: 'Imagens',
          icone: c.mostrarImagens ? Icons.image_rounded : Icons.hide_image_rounded,
          ativo: c.mostrarImagens,
          alternavel: true,
          onTap: () => onConfig(c.copyWith(mostrarImagens: !c.mostrarImagens)),
        ),
        ChipOuvir(
          key: const Key('chip-repetir-tudo'),
          rotulo: '🔁 Repetir tudo',
          ativo: c.repetirTudo,
          alternavel: true,
          onTap: () => onConfig(c.copyWith(repetirTudo: !c.repetirTudo)),
        ),
        ChipOuvir(
          key: const Key('chip-desligar'),
          rotulo: desligar == DesligarEm.nunca ? '⏾ Desligado' : '⏾ Desligar: ${rotuloDesligar(desligar)}',
          ativo: desligar != DesligarEm.nunca,
          dica: 'mudar para ${rotuloDesligar(proximoDesligar)}',
          onTap: () => onDesligar(proximoDesligar),
        ),
      ],
    );
  }
}

/// Um chip do Ouvir: 40 px de altura visível, 48 px de área de toque. [alternavel] = liga/desliga de
/// verdade (o leitor de tela anuncia "ligado/desligado"); os que giram por valores não são interruptores e
/// dizem na [dica] o próximo valor ("mudar para 1,15×").
class ChipOuvir extends StatelessWidget {
  final String rotulo;
  final IconData? icone;
  final bool ativo;
  final bool alternavel;
  final String? dica;
  final VoidCallback? onTap;

  const ChipOuvir({
    super.key,
    required this.rotulo,
    this.icone,
    this.ativo = false,
    this.alternavel = false,
    this.dica,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ativo ? Mixart.brand : Mixart.textMuted;
    return Semantics(
      button: onTap != null,
      toggled: alternavel ? ativo : null,
      onTapHint: onTap == null ? null : dica,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Mixart.radiusChip),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ativo ? Mixart.brandSub : Mixart.surfaceHi,
              borderRadius: BorderRadius.circular(Mixart.radiusChip),
              border: Border.all(color: ativo ? Mixart.brandDim : Mixart.border),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icone case final i?) ...[
                Icon(i, size: 16, color: cor),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(rotulo,
                    style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: ativo ? Mixart.text : Mixart.textMuted)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// O chip da fase em que o player está (não é botão).
class ChipFase extends StatelessWidget {
  final FaseOuvir fase;
  final int vez, de;
  const ChipFase({super.key, required this.fase, this.vez = 1, this.de = 1});

  @override
  Widget build(BuildContext context) {
    final destaque = fase == FaseOuvir.suaVez || fase == FaseOuvir.pense;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: destaque ? Mixart.brand : Mixart.brandSub,
        borderRadius: BorderRadius.circular(Mixart.radiusChip),
        border: Border.all(color: Mixart.brandDim),
      ),
      child: Text(
        rotuloFase(fase, vez: vez, de: de),
        textAlign: TextAlign.center,
        style: Mixart.ui(size: 13, weight: FontWeight.w800, color: destaque ? Mixart.onBrand : Mixart.text),
      ),
    );
  }
}
