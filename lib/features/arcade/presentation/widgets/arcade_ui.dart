import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/som/sons.dart';
import '../../../../core/syntax/tokenizer.dart';
import '../../../../core/theme/mixart.dart';
import '../../domain/corrida_engine.dart';
import 'cenario.dart';

export 'pista3d.dart' show PistaPro;

/// Código com destaque de sintaxe (mesma pintura do quiz), sem edição.
class CodigoRealcado extends StatelessWidget {
  final String codigo;
  final double tamanho;
  const CodigoRealcado(this.codigo, {super.key, this.tamanho = 13});

  @override
  Widget build(BuildContext context) {
    final tipos = tokenizar(codigo);
    final spans = <TextSpan>[
      for (var k = 0; k < codigo.length; k++)
        TextSpan(
          text: codigo[k],
          style: TextStyle(
            color: switch (tipos[k]) {
              TokenTipo.keyword => SyntaxColors.kw,
              TokenTipo.ident => SyntaxColors.ident,
              TokenTipo.literal => SyntaxColors.literal,
              TokenTipo.punct => SyntaxColors.punct,
              TokenTipo.comment => SyntaxColors.comment,
            },
            fontWeight: tipos[k] == TokenTipo.keyword ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
    ];
    return Text.rich(
      TextSpan(children: spans),
      style: Mixart.mono(size: tamanho).copyWith(height: 1.6),
    );
  }
}

/// Cartão escuro com o trecho do desafio (rola de lado se a linha for longa).
class CartaoCodigo extends StatelessWidget {
  final String codigo;
  const CartaoCodigo(this.codigo, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Mixart.bg,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: CodigoRealcado(codigo, tamanho: 13.5),
      ),
    );
  }
}

/// Chip de placar dos jogos (mesma cara dos stats do HUD).
class ChipPlacar extends StatelessWidget {
  final String k, v;
  final Color? cor;
  const ChipPlacar(this.k, this.v, {super.key, this.cor});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 66),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Mixart.surfaceHi,
          border: Border.all(color: Mixart.border),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(children: [
          Text(k,
              style: Mixart.ui(size: 9, weight: FontWeight.w600, color: Mixart.textMuted)
                  .copyWith(letterSpacing: 1)),
          const SizedBox(height: 3),
          Text(v, style: Mixart.display(size: 15, color: cor ?? Mixart.text)),
        ]),
      );
}

/// Cabeçalho padrão das telas do Arcade: voltar + rótulo + título + placar.
class CabecalhoJogo extends StatelessWidget {
  final String rotulo;
  final String titulo;
  final List<Widget> chips;

  /// Botão extra no canto (⏸ pausa).
  final Widget? acao;
  const CabecalhoJogo({
    super.key,
    required this.rotulo,
    required this.titulo,
    this.chips = const [],
    this.acao,
  });

  @override
  Widget build(BuildContext context) {
    final voltar = IconButton(
      tooltip: 'Voltar',
      onPressed: () => Navigator.of(context).pop(),
      icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
      style: IconButton.styleFrom(
          backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
    );
    final titulos = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(rotulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand).copyWith(letterSpacing: 2)),
      const SizedBox(height: 2),
      Text(titulo, style: Mixart.display(size: 21), maxLines: 1, overflow: TextOverflow.ellipsis),
    ]);
    return LayoutBuilder(builder: (context, box) {
      // celular: os chips descem pra uma linha própria (senão o título
      // fica com um caractere de largura e o botão de pausa some da tela)
      if (box.maxWidth < 640) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            voltar,
            const SizedBox(width: 10),
            Expanded(child: titulos),
            if (acao != null) ...[const SizedBox(width: 8), acao!],
          ]),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
        ]);
      }
      return Row(children: [
        voltar,
        const SizedBox(width: 14),
        Expanded(child: titulos),
        const SizedBox(width: 10),
        Flexible(child: Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.end, children: chips)),
        if (acao != null) ...[const SizedBox(width: 10), acao!],
      ]);
    });
  }
}

/// Botão de alternativa dos jogos (número pra teclar + código realçado).
class BotaoOpcao extends StatelessWidget {
  final int indice;
  final String codigo;

  /// Já respondeu? Pinta a certa de brand e a errada escolhida de danger.
  final bool revelado;
  final bool ehCerta;
  final bool ehEscolhida;
  final VoidCallback? onTap;

  /// Rótulo extra em cima do código (usado nos cantos do gol).
  final String? cantoRotulo;

  const BotaoOpcao({
    super.key,
    required this.indice,
    required this.codigo,
    required this.revelado,
    required this.ehCerta,
    required this.ehEscolhida,
    required this.onTap,
    this.cantoRotulo,
  });

  @override
  Widget build(BuildContext context) {
    Color borda = Mixart.border;
    if (revelado && ehCerta) borda = Mixart.brand;
    if (revelado && ehEscolhida && !ehCerta) borda = Mixart.danger;

    return Material(
      color: Mixart.surface,
      borderRadius: BorderRadius.circular(Mixart.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
        onTap: revelado ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
                color: borda, width: revelado && (ehCerta || ehEscolhida) ? 1.6 : 1),
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: revelado && ehCerta
                    ? Mixart.brand
                    : revelado && ehEscolhida
                        ? Mixart.danger
                        : Mixart.surfaceHi,
                shape: BoxShape.circle,
                border: Border.all(color: Mixart.border),
              ),
              child: Text('${indice + 1}',
                  style: Mixart.ui(
                      size: 12,
                      weight: FontWeight.w700,
                      color: revelado && (ehCerta || (ehEscolhida && !ehCerta))
                          ? Mixart.onBrand
                          : Mixart.textMuted)),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (cantoRotulo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(cantoRotulo!,
                        style: Mixart.ui(size: 9.5, weight: FontWeight.w700, color: Mixart.textFaint)
                            .copyWith(letterSpacing: 1.2)),
                  ),
                CodigoRealcado(codigo),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// 🔥 Chama tremulante atrás do corredor turbinado.
class ChamaTurbo extends StatefulWidget {
  const ChamaTurbo({super.key});

  @override
  State<ChamaTurbo> createState() => _ChamaTurboState();
}

class _ChamaTurboState extends State<ChamaTurbo> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 160))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) => Transform.scale(
          scaleX: 1 + _ctrl.value * .35,
          scaleY: .85 + _ctrl.value * .25,
          alignment: Alignment.centerRight,
          child: const Text('🔥', style: TextStyle(fontSize: 22)),
        ),
      );
}

/// Barrinha que enche até o próximo passo do rival.
class CargaCpu extends StatelessWidget {
  final Animation<double> carga;
  const CargaCpu({super.key, required this.carga});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: carga,
      builder: (_, _) {
        final v = carga.value.clamp(0.0, 1.0);
        return Container(
          width: 40,
          height: 5,
          decoration: BoxDecoration(
            color: const Color(0x8010131A),
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                color: v > .8 ? const Color(0xFFF2555A) : Colors.white.withValues(alpha: .85),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Overlay de fase vencida: pontos da fase + total acumulado + dica de Dart.
class FaseVencida extends StatelessWidget {
  final int fase;
  final int pontosFase;
  final int pontosTotal;
  final String dica;

  /// O que muda na próxima fase ("a CPU acelerou", "o relógio apertou"…).
  final String aviso;
  final VoidCallback onProxima;
  final VoidCallback onParar;

  const FaseVencida({
    super.key,
    required this.fase,
    required this.pontosFase,
    required this.pontosTotal,
    required this.dica,
    required this.aviso,
    required this.onProxima,
    required this.onParar,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Mixart.spring,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
        ),
        child: Container(
          color: const Color(0xED010101),
          padding: const EdgeInsets.all(20),
          child: Stack(children: [
            const Confete(pedacos: 18),
            Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🏁', style: TextStyle(fontSize: 46)),
                  const SizedBox(height: 8),
                  Text('FASE $fase CONCLUÍDA!',
                      textAlign: TextAlign.center,
                      style: Mixart.display(size: 26, color: Mixart.brand)),
                  const SizedBox(height: 6),
                  Text(
                    'Próxima parada: ${emojiDaFase(fase + 1)} ${nomeDaFase(fase + 1)} — $aviso',
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                    ChipPlacar('FASE', '+$pontosFase', cor: Mixart.brand),
                    ChipPlacar('TOTAL', '$pontosTotal'),
                  ]),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Mixart.brandSub,
                      border: Border.all(color: Mixart.brandDim),
                      borderRadius: BorderRadius.circular(Mixart.radiusMd),
                    ),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('💡', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Dica Dart: $dica',
                            style: Mixart.ui(size: 12.5, color: Mixart.text)
                                .copyWith(height: 1.45)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 18),
                  Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Mixart.brand,
                        foregroundColor: Mixart.onBrand,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
                      ),
                      onPressed: onProxima,
                      child: const Text('Próxima fase →'),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Mixart.text,
                        side: BorderSide(color: Mixart.border),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        textStyle: Mixart.ui(size: 13),
                      ),
                      onPressed: onParar,
                      child: const Text('Parar e guardar pontos'),
                    ),
                  ]),
                ]),
              ),
            ),
          ),
          ]),
        ),
      ),
    );
  }
}

/// Cartões de escolha do rival (Fácil/Normal/Difícil), com o título.
class SeletorDificuldade extends StatelessWidget {
  final ValueChanged<Dificuldade> onEscolher;
  const SeletorDificuldade({super.key, required this.onEscolher});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Escolha o rival:', style: Mixart.display(size: 16)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final d in Dificuldade.values)
          Material(
            color: Mixart.surface,
            borderRadius: BorderRadius.circular(Mixart.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(Mixart.radiusMd),
              onTap: () => onEscolher(d),
              child: Container(
                width: 236,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Mixart.border),
                  borderRadius: BorderRadius.circular(Mixart.radiusMd),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.emoji, style: const TextStyle(fontSize: 30)),
                  const SizedBox(height: 8),
                  Text(d.rotulo, style: Mixart.display(size: 17)),
                  const SizedBox(height: 4),
                  Text(d.descricao, style: Mixart.ui(size: 12, color: Mixart.textMuted)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Mixart.brandSub,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text('pontos x${d.multiplicador}',
                        style: Mixart.ui(
                            size: 11, weight: FontWeight.w700, color: Mixart.brand)),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    ]);
  }
}

/// 🎊 Chuva de confete de uma vez só, determinística e leve (celebrações).
class Confete extends StatelessWidget {
  final int pedacos;
  const Confete({super.key, this.pedacos = 26});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 1900),
          builder: (_, t, _) =>
              CustomPaint(painter: _ConfetePainter(t, pedacos), size: Size.infinite),
        ),
      ),
    );
  }
}

class _ConfetePainter extends CustomPainter {
  final double t;
  final int n;
  _ConfetePainter(this.t, this.n);

  static const _cores = [
    Color(0xFFFFC73B),
    Color(0xFF4FC3F7),
    Color(0xFFF2555A),
    Color(0xFF57C765),
    Color(0xFFB388FF),
    Color(0xFFF4F1EA),
  ];

  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < n; i++) {
      // pseudo-aleatório estável por índice (mesma chuva em todo frame)
      final x = ((i * 61) % 97) / 97 * s.width + (i.isEven ? 1 : -1) * 18 * t;
      final velo = 0.65 + ((i * 37) % 50) / 100; // 0.65..1.15
      final y = -20 + t * velo * (s.height + 60);
      final lado = 5.0 + (i % 3) * 2;
      final tinta = Paint()..color = _cores[i % _cores.length].withValues(alpha: (1.6 - t).clamp(0, 1).toDouble());
      c.save();
      c.translate(x, y);
      c.rotate(t * 6.28 * (1 + i % 3));
      c.drawRect(Rect.fromCenter(center: Offset.zero, width: lado, height: lado * .6), tinta);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfetePainter old) => old.t != t;
}

/// Overlay de fim de partida (mesmo clima do overlay de vitória das lições).
class FimDeJogo extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  final int pontos;
  final bool novoRecorde;
  final List<(String, String)> stats;
  final VoidCallback onDeNovo;
  final VoidCallback onSair;

  /// Solta confete (vitórias/campanhas com fase vencida).
  final bool celebrar;

  /// Há ranking pra receber os pontos (jogador logado)?
  final bool noRanking;

  const FimDeJogo({
    super.key,
    required this.emoji,
    required this.titulo,
    required this.subtitulo,
    required this.pontos,
    required this.novoRecorde,
    required this.stats,
    required this.onDeNovo,
    required this.onSair,
    this.celebrar = false,
    this.noRanking = true,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Mixart.spring,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 8 * (1 - t)), child: child),
        ),
        child: Container(
          color: const Color(0xED010101),
          padding: const EdgeInsets.all(20),
          child: Stack(children: [
            if (celebrar) const Confete(),
            Center(
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(height: 10),
                Text(titulo,
                    textAlign: TextAlign.center,
                    style: Mixart.display(size: 28, color: Mixart.brand)),
                const SizedBox(height: 6),
                Text(subtitulo,
                    textAlign: TextAlign.center,
                    style: Mixart.ui(size: 13, color: Mixart.textMuted)),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                  decoration: BoxDecoration(
                    color: Mixart.surface,
                    border: Border.all(color: novoRecorde ? Mixart.brand : Mixart.border),
                    borderRadius: BorderRadius.circular(Mixart.radiusMd),
                  ),
                  child: Column(children: [
                    Text('+$pontos pts', style: Mixart.display(size: 32, color: Mixart.brand)),
                    if (novoRecorde) ...[
                      const SizedBox(height: 4),
                      Text('🏅 NOVO RECORDE PESSOAL!',
                          style: Mixart.ui(size: 11, weight: FontWeight.w700, color: Mixart.brand)
                              .copyWith(letterSpacing: 1)),
                    ],
                  ]),
                ),
                const SizedBox(height: 14),
                Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                  for (final (k, v) in stats) ChipPlacar(k, v),
                ]),
                const SizedBox(height: 10),
                Text(
                    noRanking
                        ? 'Os pontos já somaram no seu ranking 🏆'
                        : 'Entre na sua conta pra guardar pontos no ranking 🏆',
                    style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
                const SizedBox(height: 18),
                Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Mixart.brand,
                      foregroundColor: Mixart.onBrand,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
                    ),
                    onPressed: onDeNovo,
                    child: const Text('Jogar de novo'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Mixart.text,
                      side: BorderSide(color: Mixart.border),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      textStyle: Mixart.ui(size: 13),
                    ),
                    onPressed: onSair,
                    child: const Text('Voltar ao Arcade'),
                  ),
                ]),
              ]),
            ),
          ),
          ]),
        ),
      ),
    );
  }
}


/// Barra de relógio das rodadas (escoa suave, fica vermelha na urgência).
class BarraTempo extends StatelessWidget {
  final int restante;
  final int total;

  /// A partir de quantos segundos restantes a barra vira vermelha.
  final int urgenteAte;
  const BarraTempo({super.key, required this.restante, required this.total, this.urgenteAte = 5});

  @override
  Widget build(BuildContext context) {
    final urgente = restante <= urgenteAte;
    final cor = urgente ? Mixart.danger : Mixart.brand;
    return Row(children: [
      Icon(Icons.timer_outlined, size: 15, color: urgente ? Mixart.danger : Mixart.textMuted),
      const SizedBox(width: 8),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: total <= 0 ? 0 : (restante / total).clamp(0, 1).toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.linear,
            builder: (_, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: Mixart.surfaceHi,
              color: cor,
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),
      SizedBox(
        width: 30,
        child: Text('${restante.clamp(0, 99)}s',
            textAlign: TextAlign.right,
            style: Mixart.mono(size: 12, color: urgente ? Mixart.danger : Mixart.textMuted)),
      ),
    ]);
  }
}

/// Selo do nível do desafio (★☆☆ básico … ★★★ chefão).
class SeloNivel extends StatelessWidget {
  final int nivel;
  const SeloNivel(this.nivel, {super.key});

  @override
  Widget build(BuildContext context) {
    final n = nivel.clamp(1, 3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: Mixart.surfaceHi,
        border: Border.all(color: Mixart.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('NÍVEL ${'★' * n}${'☆' * (3 - n)}',
          style: Mixart.ui(size: 9.5, weight: FontWeight.w700, color: n == 3 ? Mixart.brand : Mixart.textMuted)
              .copyWith(letterSpacing: 1)),
    );
  }
}

/// Botão ⏸ do cabeçalho (mesma cara do botão de voltar).
class BotaoPausa extends StatelessWidget {
  final VoidCallback? onTap;
  const BotaoPausa({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: 'Pausar (Esc)',
        onPressed: onTap,
        icon: Icon(Icons.pause_rounded, color: onTap == null ? Mixart.textFaint : Mixart.text, size: 20),
        style: IconButton.styleFrom(
            backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      );
}

/// Overlay de jogo pausado: relógios parados até o jogador voltar.
class PausaOverlay extends StatelessWidget {
  final VoidCallback onContinuar;
  final VoidCallback onSair;
  const PausaOverlay({super.key, required this.onContinuar, required this.onSair});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: const Color(0xE6010101),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('⏸', style: TextStyle(fontSize: 46)),
            const SizedBox(height: 8),
            Text('PAUSADO', style: Mixart.display(size: 26, color: Mixart.brand)),
            const SizedBox(height: 6),
            Text('Relógios parados. Respire, tome uma água — a CPU também espera.',
                textAlign: TextAlign.center,
                style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(height: 1.4)),
            const SizedBox(height: 18),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Mixart.brand,
                  foregroundColor: Mixart.onBrand,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: Mixart.ui(size: 13, weight: FontWeight.w700),
                ),
                onPressed: onContinuar,
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Continuar'),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Mixart.text,
                  side: BorderSide(color: Mixart.border),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  textStyle: Mixart.ui(size: 13),
                ),
                onPressed: onSair,
                child: const Text('Sair do jogo'),
              ),
            ]),
            const SizedBox(height: 12),
            Text('Esc também continua · os pontos até aqui ficam guardados',
                style: Mixart.ui(size: 11, color: Mixart.textFaint)),
          ]),
        ),
      ),
    );
  }
}

/// Largada 3 · 2 · 1 · VAI! — ninguém começa a corrida sem estar pronto.
class ContagemRegressiva extends StatefulWidget {
  final VoidCallback onFim;

  /// O grito final ("VAI!", "JÁ!").
  final String grito;

  /// O que aparece embaixo do número (ex.: "prepare os dedos").
  final String legenda;
  const ContagemRegressiva({
    super.key,
    required this.onFim,
    this.grito = 'VAI!',
    this.legenda = '',
  });

  static const passo = Duration(milliseconds: 650);

  /// Duração total até o [onFim] (3 números + o grito).
  static const duracao = Duration(milliseconds: 650 * 4);

  @override
  State<ContagemRegressiva> createState() => _ContagemRegressivaState();
}

class _ContagemRegressivaState extends State<ContagemRegressiva> {
  int _n = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Sons.toca(Som.tique);
    _timer = Timer.periodic(ContagemRegressiva.passo, (_) {
      if (!mounted) return;
      if (_n <= 0) {
        _timer?.cancel();
        widget.onFim();
        return;
      }
      setState(() => _n--);
      Sons.toca(_n > 0 ? Som.tique : Som.largada);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vai = _n <= 0;
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: const Color(0xB3010101),
          child: Center(
            child: TweenAnimationBuilder<double>(
              key: ValueKey(_n),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Mixart.spring,
              builder: (_, t, child) => Opacity(
                opacity: t.clamp(0, 1),
                child: Transform.scale(scale: .55 + .45 * t, child: child),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(vai ? widget.grito : '$_n',
                    style: Mixart.display(size: vai ? 64 : 84, color: Mixart.brand)),
                if (widget.legenda.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(widget.legenda,
                      style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.text)),
                ],
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sacode o filho quando [gatilho] muda (perdeu vida, defesa, linha errada).
/// Parado, não custa nada.
class Tremor extends StatelessWidget {
  final int gatilho;
  final double forca;
  final Widget child;
  const Tremor({super.key, required this.gatilho, required this.child, this.forca = 7});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(gatilho),
      tween: Tween(begin: gatilho == 0 ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 380),
      builder: (_, t, c) {
        final d = math.sin(t * math.pi * 5) * forca * (1 - t);
        return Transform.translate(offset: Offset(d, d * .35), child: c);
      },
      child: child,
    );
  }
}

/// 💥 Estilhaços de uma passada: pedacinhos voando do centro (palavra
/// destruída, bug esmagado). Posicione com o centro em (alcance, alcance).
class Estilhacos extends StatelessWidget {
  final Color cor;
  final int pedacos;
  final double alcance;
  final int semente;
  const Estilhacos({
    super.key,
    required this.cor,
    this.pedacos = 12,
    this.alcance = 44,
    this.semente = 0,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: alcance * 2,
        height: alcance * 2,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 560),
          curve: Curves.easeOutCubic,
          builder: (_, t, _) => CustomPaint(painter: _EstilhacosPainter(t, cor, pedacos, semente)),
        ),
      ),
    );
  }
}

class _EstilhacosPainter extends CustomPainter {
  final double t;
  final Color cor;
  final int n;
  final int semente;
  _EstilhacosPainter(this.t, this.cor, this.n, this.semente);

  @override
  void paint(Canvas c, Size s) {
    final centro = Offset(s.width / 2, s.height / 2);
    final raio = s.width / 2;
    final tinta = Paint()..color = cor.withValues(alpha: (1 - t).clamp(0, 1).toDouble());
    for (var i = 0; i < n; i++) {
      final k = (i * 37 + semente * 11) % 50 / 50; // pseudo-aleatório estável
      final ang = (i / n) * math.pi * 2 + k * .9;
      final dist = raio * (.45 + k * .55) * t;
      final p = centro + Offset(math.cos(ang), math.sin(ang)) * dist;
      c.drawCircle(p, (3.6 - 2.2 * t) * (.7 + k * .6), tinta);
    }
  }

  @override
  bool shouldRepaint(_EstilhacosPainter old) => old.t != t;
}


/// Cartão com PROFUNDIDADE: inclina levemente seguindo o mouse (perspectiva
/// 3D), com sombra que cresce ao passar por cima. No toque, só a sombra.
class CartaoInclinavel extends StatefulWidget {
  final Widget child;
  final BorderRadius raio;
  const CartaoInclinavel({super.key, required this.child, required this.raio});

  @override
  State<CartaoInclinavel> createState() => _CartaoInclinavelState();
}

class _CartaoInclinavelState extends State<CartaoInclinavel> {
  Offset _alvo = Offset.zero; // -1..1 em cada eixo
  bool _sobre = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _sobre = true),
      onExit: (_) => setState(() {
        _sobre = false;
        _alvo = Offset.zero;
      }),
      onHover: (e) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) return;
        final s = box.size;
        setState(() => _alvo = Offset(
              (e.localPosition.dx / s.width * 2 - 1).clamp(-1, 1),
              (e.localPosition.dy / s.height * 2 - 1).clamp(-1, 1),
            ));
      },
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _alvo),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        builder: (_, incl, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: widget.raio,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _sobre ? .55 : .35),
                blurRadius: _sobre ? 26 : 14,
                offset: Offset(-incl.dx * 6, _sobre ? 14 : 8),
              ),
            ],
          ),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0014)
              ..rotateX(-incl.dy * .09)
              ..rotateY(incl.dx * .09)
              ..scaleByDouble(_sobre ? 1.015 : 1.0, _sobre ? 1.015 : 1.0, 1.0, 1.0),
            child: child,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
