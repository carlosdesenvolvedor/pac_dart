import 'package:flutter/material.dart';

import '../../../../core/som/sons.dart';
import '../../../../core/theme/mixart.dart';
import '../../../../core/ui/festa.dart';
import '../palavras_cubit.dart';

/// A cor das teimosas (o 🔥): o coral da festa, um pouco mais escuro no tema claro.
Color _corTeimosa() => escurecer(CoresFesta.coral, quanto: .2, soNoClaro: true);

/// A oferta "🔥 treinar só elas" (fim de lição, fim de jogo, entre fases): as palavras que deram trabalho
/// (inglês, tradução e quantas vezes — os chips aparecem um depois do outro), "🎯 Treinar só elas (N)" e,
/// se vierem, "🎮 Jogar com elas", "📝 Virar lição" e "Agora não". "Agora não" chama [onAgoraNao], avisa
/// quando pergunta de novo e recolhe o cartão.
class CartaoTeimosas extends StatefulWidget {
  /// (como se escreve, tradução, vezes).
  final List<(String, String, int)> palavras;

  /// Versão enxuta (fim de jogo): menos respiro e no máximo 5 chips.
  final bool compacto;

  /// As palavras são DESTA lição/partida ("Essas palavras te deram trabalho") ou as de sempre ("Suas
  /// palavras teimosas").
  final bool daSessao;

  final VoidCallback onTreinar;
  final VoidCallback? onJogar;
  final VoidCallback? onLicao;
  final VoidCallback? onAgoraNao;

  const CartaoTeimosas({
    super.key,
    required this.palavras,
    required this.onTreinar,
    this.compacto = false,
    this.daSessao = true,
    this.onJogar,
    this.onLicao,
    this.onAgoraNao,
  });

  @override
  State<CartaoTeimosas> createState() => _CartaoTeimosasState();
}

class _CartaoTeimosasState extends State<CartaoTeimosas> with SingleTickerProviderStateMixin {
  late final AnimationController _entrada;
  bool _dispensado = false;

  int get _visiveis => widget.compacto ? widget.palavras.length.clamp(0, 5) : widget.palavras.length;

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(vsync: this, duration: Duration(milliseconds: 260 + 90 * _visiveis));
    _entrada.forward();
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  void _agoraNao() {
    final mensageiro = ScaffoldMessenger.maybeOf(context);
    final cubit = PalavrasCubit.de(context);
    widget.onAgoraNao?.call();
    final recusas = cubit?.state.banco.sugestao.recusasSeguidas ?? 0;
    final texto = recusas >= 3
        ? 'Ok, vou deixar quieto uns dias. Elas ficam em 📚 Minhas palavras'
        : 'Beleza! Pergunto de novo amanhã 😉';
    mensageiro
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        key: const Key('snack-agora-nao'),
        backgroundColor: Mixart.surfaceHi,
        content: Text(texto, style: Mixart.ui(size: 13, color: Mixart.text)),
      ));
    setState(() => _dispensado = true);
  }

  Animation<double> _pop(int i) {
    final n = _visiveis == 0 ? 1 : _visiveis;
    final total = 260 + 90 * n;
    final ini = (90 * i) / total;
    final fim = ((90 * i) + 260) / total;
    return CurvedAnimation(
      parent: _entrada,
      curve: Interval(ini.clamp(0.0, 1.0), fim.clamp(0.0, 1.0), curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_dispensado || widget.palavras.isEmpty) return const SizedBox.shrink();
    final c = widget.compacto;
    final cor = _corTeimosa();
    final n = widget.palavras.length;
    final extras = n - _visiveis;
    return Container(
      key: const Key('cartao-teimosas'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(c ? 12 : 16, c ? 10 : 14, c ? 12 : 16, c ? 10 : 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(cor.withValues(alpha: .07), Mixart.surface),
        borderRadius: BorderRadius.circular(Mixart.radiusLg),
        border: Border(
          top: BorderSide(color: cor.withValues(alpha: .55), width: 1.5),
          left: BorderSide(color: cor.withValues(alpha: .55), width: 1.5),
          right: BorderSide(color: cor.withValues(alpha: .55), width: 1.5),
          bottom: BorderSide(color: cor.withValues(alpha: .55), width: 4),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text(
          widget.daSessao ? '🔥 Essas palavras te deram trabalho' : '🔥 Suas palavras teimosas',
          style: Mixart.display(size: c ? 15 : 17, weight: FontWeight.w800),
        ),
        SizedBox(height: c ? 8 : 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < _visiveis; i++)
            ScaleTransition(
              scale: _pop(i),
              child: _ChipTeimosa(en: widget.palavras[i].$1, pt: widget.palavras[i].$2, vezes: widget.palavras[i].$3, cor: cor),
            ),
          if (extras > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Text('+$extras', style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.textMuted)),
            ),
        ]),
        SizedBox(height: c ? 8 : 10),
        Text('Bora treinar só elas? Uns 2 minutinhos.',
            style: Mixart.ui(size: c ? 12.5 : 13.5, weight: FontWeight.w600, color: Mixart.textMuted)),
        SizedBox(height: c ? 8 : 12),
        Botao3D(
          key: const Key('treinar-teimosas'),
          rotulo: '🎯 Treinar só elas ($n)',
          cor: cor,
          corTexto: corSobre(cor),
          altura: c ? 42 : 46,
          tamanhoTexto: c ? 13.5 : 14.5,
          onTap: widget.onTreinar,
        ),
        if (widget.onJogar != null || widget.onLicao != null || widget.onAgoraNao != null) ...[
          const SizedBox(height: 4),
          Wrap(alignment: WrapAlignment.center, spacing: 2, runSpacing: 0, children: [
            if (widget.onJogar != null)
              _BotaoTexto(chave: const Key('jogar-teimosas'), rotulo: '🎮 Jogar com elas', onTap: widget.onJogar!),
            if (widget.onLicao != null)
              _BotaoTexto(chave: const Key('licao-teimosas'), rotulo: '📝 Virar lição', onTap: widget.onLicao!),
            if (widget.onAgoraNao != null)
              _BotaoTexto(chave: const Key('agora-nao'), rotulo: 'Agora não', onTap: _agoraNao, discreto: true),
          ]),
        ],
      ]),
    );
  }
}

class _BotaoTexto extends StatelessWidget {
  final Key chave;
  final String rotulo;
  final VoidCallback onTap;
  final bool discreto;
  const _BotaoTexto({required this.chave, required this.rotulo, required this.onTap, this.discreto = false});

  @override
  Widget build(BuildContext context) => TextButton(
        key: chave,
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(rotulo,
            style: Mixart.ui(
                size: 13, weight: FontWeight.w700, color: discreto ? Mixart.textFaint : Mixart.brand)),
      );
}

/// Um chip de teimosa: o inglês (mono), a tradução apagadinha e o "Nx".
class _ChipTeimosa extends StatelessWidget {
  final String en, pt;
  final int vezes;
  final Color cor;
  const _ChipTeimosa({required this.en, required this.pt, required this.vezes, required this.cor});

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: Mixart.border, width: 1.2),
          borderRadius: BorderRadius.circular(Mixart.radiusChip),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(en, style: Mixart.mono(size: 14, weight: FontWeight.w800, color: Mixart.text)),
          if (pt.isNotEmpty) ...[
            const SizedBox(width: 6),
            Flexible(
              child: Text(pt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textMuted)),
            ),
          ],
          // "1x" não diz nada (e contradiz "teimosa"): o badge só aparece de 2 vezes para cima
          if (vezes >= 2) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: cor.withValues(alpha: .16), borderRadius: BorderRadius.circular(999)),
              child: Text('${vezes}x', style: Mixart.ui(size: 11, weight: FontWeight.w900, color: cor)),
            ),
          ] else
            const SizedBox(width: 4),
        ]),
      );
}

/// A anotação discreta DURANTE a lição: '📝 "through" escapou de novo — anotei pro seu treino'. Sem botão.
class ChipAnotada extends StatelessWidget {
  final String en;
  const ChipAnotada(this.en, {super.key});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: const Key('licao-anotei'),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        builder: (_, v, filho) => Opacity(
          opacity: v,
          child: Transform.translate(offset: Offset(0, 6 * (1 - v)), child: filho),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Mixart.surfaceHi,
            border: Border.all(color: Mixart.border),
            borderRadius: BorderRadius.circular(Mixart.radiusChip),
          ),
          child: Text('📝 "$en" escapou de novo — anotei pro seu treino',
              style: Mixart.ui(size: 12.5, weight: FontWeight.w600, color: Mixart.textMuted)),
        ),
      );
}

/// A linha passiva do fim de uma revisão: "Você tropeçou em: through · enough · because" e, só quando
/// vierem os callbacks (a política deixou oferecer), "🎯 Treinar só elas" e "🎮 Jogar com elas".
class ListaTeimosas extends StatelessWidget {
  /// Como se escrevem.
  final List<String> palavras;
  final VoidCallback? onTreinar;
  final VoidCallback? onJogar;

  const ListaTeimosas({super.key, required this.palavras, this.onTreinar, this.onJogar});

  @override
  Widget build(BuildContext context) {
    if (palavras.isEmpty) return const SizedBox.shrink();
    final cor = _corTeimosa();
    return Container(
      key: const Key('resumo-teimosas'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: cor.withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '🔥 Você tropeçou em: ', style: Mixart.ui(size: 13.5, weight: FontWeight.w700, color: Mixart.textMuted)),
            TextSpan(
                text: palavras.join(' · '),
                style: Mixart.mono(size: 13.5, weight: FontWeight.w800, color: Mixart.text)),
          ]),
        ),
        if (onTreinar != null || onJogar != null) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (onTreinar != null)
              Botao3D(
                key: const Key('treinar-teimosas'),
                rotulo: '🎯 Treinar só elas',
                cor: cor,
                corTexto: corSobre(cor),
                expandir: false,
                altura: 40,
                tamanhoTexto: 13,
                onTap: onTreinar,
              ),
            if (onJogar != null)
              Botao3D(
                key: const Key('jogar-teimosas'),
                rotulo: '🎮 Jogar com elas',
                contorno: true,
                expandir: false,
                altura: 40,
                tamanhoTexto: 13,
                onTap: onJogar,
              ),
          ]),
        ],
      ]),
    );
  }
}

/// O selo dourado "🏆 DOMINADA!" de uma palavra que saiu da lista de teimosas: cresce (0,6 → 1,15 → 1 em
/// 600 ms), com confete e fanfarra ([som] falso: só o selo — para vários selos juntos tocarem uma vez).
class SeloDominada extends StatefulWidget {
  final String en;
  final bool som;
  const SeloDominada(this.en, {super.key, this.som = true});

  @override
  State<SeloDominada> createState() => _SeloDominadaState();
}

class _SeloDominadaState extends State<SeloDominada> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
  late final Animation<double> _escala = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: .6, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 40),
  ]).animate(_c);

  @override
  void initState() {
    super.initState();
    _c.forward();
    if (widget.som) Sons.toca(Som.fanfarra);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const ouro = CoresFesta.ouro;
    final escuro = escurecer(ouro, quanto: .35);
    return Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
      ScaleTransition(
        scale: _escala,
        child: Container(
          key: Key('selo-dominada-${widget.en.toLowerCase()}'),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(ouro, Colors.white, .25)!, ouro, escurecer(ouro, quanto: .12)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: escuro, width: 2),
            boxShadow: [BoxShadow(color: ouro.withValues(alpha: .35), blurRadius: 14, spreadRadius: 1)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🏆 DOMINADA!',
                style: Mixart.ui(size: 13, weight: FontWeight.w900, color: const Color(0xFF3A2A00))
                    .copyWith(letterSpacing: .8)),
            const SizedBox(height: 2),
            Text(widget.en, style: Mixart.mono(size: 16, weight: FontWeight.w800, color: const Color(0xFF241A00))),
          ]),
        ),
      ),
      Positioned(
        left: -70,
        right: -70,
        top: -60,
        bottom: -30,
        child: IgnorePointer(child: Confete(quantidade: 26, origem: const Alignment(0, -.1), semente: widget.en.length)),
      ),
    ]);
  }
}
