import 'package:flutter/material.dart';

import '../../../../core/syntax/tokenizer.dart';
import '../../../../core/theme/mixart.dart';
import '../../domain/corrida_engine.dart';
import 'avatares.dart';
import 'cenario.dart';

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
  const CabecalhoJogo({super.key, required this.rotulo, required this.titulo, this.chips = const []});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(
        tooltip: 'Voltar',
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(Icons.arrow_back, color: Mixart.text, size: 20),
        style: IconButton.styleFrom(
            backgroundColor: Mixart.surfaceHi, side: BorderSide(color: Mixart.border)),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(rotulo,
              style: Mixart.ui(size: 10, weight: FontWeight.w700, color: Mixart.brand)
                  .copyWith(letterSpacing: 2)),
          const SizedBox(height: 2),
          Text(titulo, style: Mixart.display(size: 21), overflow: TextOverflow.ellipsis),
        ]),
      ),
      const SizedBox(width: 10),
      Wrap(spacing: 8, runSpacing: 8, children: chips),
    ]);
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

/// A pista profissional da corrida: cenário da fase ao fundo, asfalto com
/// faixas, largada e chegada quadriculadas, personagens com crachá.
/// Compartilhada pela Corrida do Código e pelo Rali de Digitação.
class PistaPro extends StatelessWidget {
  final int posJogador, posCpu, pista;
  final int fase;
  const PistaPro({
    super.key,
    required this.posJogador,
    required this.posCpu,
    required this.pista,
    this.fase = 1,
  });

  static const _alturaAsfalto = 118.0;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: SizedBox(
        height: 246,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final topoAsfalto = h - _alturaAsfalto;
          double x(int pos) => 18 + (pos / pista).clamp(0, 1) * (w - 108);

          return Stack(children: [
            // o cenário vive ACIMA do asfalto (senão os morros somem atrás dele)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: topoAsfalto + 4,
              child: CenarioFase(fase: fase),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: _alturaAsfalto,
              child: CustomPaint(painter: _AsfaltoPainter()),
            ),
            // crachá da fase
            Positioned(
              left: 10,
              top: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xCC10131A),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${emojiDaFase(fase)} FASE $fase · ${nomeDaFase(fase)}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            _corredor(
              nome: 'VOCÊ',
              corBadge: Mixart.brand,
              corTexto: Mixart.onBrand,
              left: x(posJogador),
              top: topoAsfalto + 6,
              avatar: const AvatarPersonagem(tamanho: 34),
            ),
            _corredor(
              nome: 'CPU',
              corBadge: const Color(0xE6262B33),
              corTexto: Colors.white,
              left: x(posCpu),
              top: topoAsfalto + 62,
              avatar: const Text('🤖', style: TextStyle(fontSize: 28)),
            ),
          ]);
        }),
      ),
    );
  }

  Widget _corredor({
    required String nome,
    required Color corBadge,
    required Color corTexto,
    required double left,
    required double top,
    required Widget avatar,
  }) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 450),
      curve: Mixart.spring,
      left: left,
      top: top,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: corBadge,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(nome,
              style: TextStyle(
                  color: corTexto,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8)),
        ),
        const SizedBox(height: 3),
        SizedBox(height: 36, child: Center(child: avatar)),
      ]),
    );
  }
}

/// Asfalto: faixa central tracejada, bordas, largada e chegada quadriculadas.
class _AsfaltoPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    // asfalto com leve luz
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A4048), Color(0xFF272C33)],
        ).createShader(Offset.zero & s),
    );
    // acostamento (bordas brancas)
    final borda = Paint()..color = Colors.white.withValues(alpha: .85);
    c.drawRect(Rect.fromLTWH(0, 2, s.width, 3), borda);
    c.drawRect(Rect.fromLTWH(0, s.height - 5, s.width, 3), borda);
    // faixa central tracejada
    final tracejada = Paint()..color = Colors.white.withValues(alpha: .55);
    final meioY = s.height / 2 - 1.5;
    for (double xx = 6; xx < s.width; xx += 34) {
      c.drawRect(Rect.fromLTWH(xx, meioY, 18, 3), tracejada);
    }
    // largada (esquerda) e chegada (direita) quadriculadas
    _quadriculada(c, 8, s.height, 11);
    _quadriculada(c, s.width - 34, s.height, 13);
  }

  void _quadriculada(Canvas c, double x, double altura, double lado) {
    final claro = Paint()..color = Colors.white;
    final escuro = Paint()..color = const Color(0xFF16191E);
    final linhas = (altura / lado).ceil();
    for (var l = 0; l < linhas; l++) {
      for (var col = 0; col < 2; col++) {
        c.drawRect(
          Rect.fromLTWH(x + col * lado, l * lado, lado, lado),
          (l + col).isEven ? claro : escuro,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_AsfaltoPainter old) => false;
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
                Text('Os pontos já somaram no seu ranking 🏆',
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
