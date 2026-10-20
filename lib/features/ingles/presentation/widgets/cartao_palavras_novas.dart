import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../../core/ui/festa.dart';
import '../../domain/palavras_novas.dart';

/// No fim da lição (dentro da vitória): "🆕 N palavras novas nesta lição", as palavras (inglês em
/// cima, português embaixo, entrando uma depois da outra) e "🎯 Treinar agora". Já treinadas (nesta
/// visita ou antes): "✅ Você já treinou essas palavras" e "🔁 Revisar de novo". Só toque/Tab: Enter e
/// Esc continuam sendo da vitória.
class CartaoPalavrasNovas extends StatefulWidget {
  final List<PalavraNova> palavras;

  /// Já treinadas (o convite vira "✅ Você já treinou" + "🔁 Revisar de novo").
  final bool treinadas;

  /// "🎯 Treinar agora" (e o "🔁 Revisar de novo", depois de treinadas).
  final VoidCallback onTreinar;

  /// Quantas palavras aparecem no cartão (o resto vira "+N").
  final int maxChips;

  /// Uma linha só ("🆕 +N palavras novas já entraram no Arcade 🎮" + "ver", que abre o cartão): quando a
  /// vitória já tem a oferta das teimosas.
  final bool compacto;

  const CartaoPalavrasNovas({
    super.key,
    required this.palavras,
    required this.onTreinar,
    this.treinadas = false,
    this.maxChips = 6,
    this.compacto = false,
  });

  @override
  State<CartaoPalavrasNovas> createState() => _CartaoPalavrasNovasState();
}

class _CartaoPalavrasNovasState extends State<CartaoPalavrasNovas> with SingleTickerProviderStateMixin {
  late final _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  /// Compacto: a pessoa tocou em "ver".
  bool _aberto = false;

  @override
  void initState() {
    super.initState();
    // criado já (o compacto pode nunca abrir, e o dispose não pode ser o 1º a tocar no controlador)
    _entrada.value;
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  /// A linha do modo compacto: um texto só, com o "ver" no fluxo dele (o fim "Arcade 🎮 ver" não se separa
  /// — os espaços ali são inquebráveis —, então nada fica sozinho numa linha no celular).
  Widget _linha() {
    final n = widget.palavras.length;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Center(
        child: Text.rich(
          key: const Key('palavras-novas-linha'),
          TextSpan(children: [
            TextSpan(
                text: '🆕 +$n ${n == 1 ? 'palavra nova já entrou' : 'palavras novas já entraram'} no Arcade 🎮 '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: InkWell(
                key: const Key('ver-palavras-novas'),
                onTap: () {
                  _entrada.forward(from: 0);
                  setState(() => _aberto = true);
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text('ver',
                      style: Mixart.ui(size: 13, weight: FontWeight.w800, color: Mixart.brand)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
              ),
            ),
          ]),
          textAlign: TextAlign.center,
          style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.textMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compacto && !_aberto) return _linha();
    final n = widget.palavras.length;
    final mostradas = widget.palavras.take(widget.maxChips).toList();
    final resto = n - mostradas.length;
    final verde = escurecer(CoresFesta.verde, quanto: .2, soNoClaro: true);
    Widget chip(int i, Widget filho) {
      final ini = (.08 * i).clamp(0.0, .6);
      final anim = CurvedAnimation(parent: _entrada, curve: Interval(ini, (ini + .4).clamp(0.0, 1.0), curve: Mixart.spring));
      return AnimatedBuilder(
        animation: anim,
        builder: (_, f) => Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: .6 + .4 * anim.value, child: f),
        ),
        child: filho,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Mixart.surface,
          border: Border.all(color: widget.treinadas ? verde.withValues(alpha: .6) : Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.treinadas)
            Text('✅ Você já treinou essas palavras',
                key: const Key('palavras-treinadas'),
                textAlign: TextAlign.center,
                style: Mixart.display(size: 16, weight: FontWeight.w800, color: verde))
          else
            Text(
              '🆕 $n ${n == 1 ? 'palavra nova' : 'palavras novas'} nesta lição',
              textAlign: TextAlign.center,
              style: Mixart.display(size: 16, weight: FontWeight.w800),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < mostradas.length; i++)
                chip(
                  i,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Mixart.surfaceHi,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(mostradas[i].en, style: Mixart.mono(size: 13.5, weight: FontWeight.w800, color: Mixart.brand)),
                      Text(mostradas[i].pt, style: Mixart.ui(size: 10.5, weight: FontWeight.w600, color: Mixart.textMuted)),
                    ]),
                  ),
                ),
              if (resto > 0)
                chip(
                  mostradas.length,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(color: Mixart.surfaceHi, borderRadius: BorderRadius.circular(10)),
                    child: Text('+$resto', style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.textMuted)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.treinadas)
            Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
              Botao3D(
                key: const Key('revisar-palavras'),
                rotulo: '🔁 Revisar de novo',
                contorno: true,
                expandir: false,
                altura: 36,
                tamanhoTexto: 13,
                onTap: widget.onTreinar,
              ),
              Text('🎮 já estão no Arcade', style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
            ])
          else ...[
            Botao3D(
              key: const Key('treinar-palavras'),
              rotulo: '🎯 Treinar agora',
              expandir: false,
              altura: 40,
              tamanhoTexto: 14,
              onTap: widget.onTreinar,
            ),
            const SizedBox(height: 6),
            Text('Elas vão para os seus jogos do Arcade 🎮',
                textAlign: TextAlign.center, style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
          ],
        ]),
      ),
    );
  }
}

/// No COMEÇO da lição (acima da 1ª frase): "🆕 Esta lição tem N palavras novas", as palavras (inglês em
/// cima, português embaixo) e "🎯 Conhecer antes" / "Começar direto". Fora do foco do teclado: a frase
/// continua recebendo as teclas (a 1ª tecla dispensa o cartão; o Enter segue como sempre).
class CartaoAntesDaLicao extends StatefulWidget {
  final List<PalavraNova> palavras;
  final VoidCallback onConhecer;
  final VoidCallback onComecar;

  /// Quantas palavras aparecem (o resto vira "+N").
  final int maxChips;

  /// Uma linha só ("🆕 N palavras novas · 🎯 conhecer antes"): quem já pulou o cartão várias vezes seguidas,
  /// ou a 1ª lição no celular (com o nivelamento em cima).
  final bool compacto;

  /// O atalho de teclado do "Conhecer antes" (ex.: "⌘ Enter"), mostrado ao lado do botão; null no celular.
  final String? atalho;

  const CartaoAntesDaLicao({
    super.key,
    required this.palavras,
    required this.onConhecer,
    required this.onComecar,
    this.maxChips = 6,
    this.compacto = false,
    this.atalho,
  });

  @override
  State<CartaoAntesDaLicao> createState() => _CartaoAntesDaLicaoState();
}

class _CartaoAntesDaLicaoState extends State<CartaoAntesDaLicao> with SingleTickerProviderStateMixin {
  late final _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    // criado já (o compacto não anima, e o dispose não pode ser o 1º a tocar no controlador)
    _entrada.value;
  }

  @override
  void dispose() {
    _entrada.dispose();
    super.dispose();
  }

  /// A tecla do atalho, como as teclas da vitória ("↵ Enter").
  Widget? _tecla() {
    final a = widget.atalho;
    if (a == null) return null;
    return Container(
      key: const Key('atalho-antes'),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(a, style: Mixart.mono(size: 11, color: Mixart.brand)),
    );
  }

  /// O modo de uma linha: o convite e o link, sem as palavras.
  Widget _linha() {
    final n = widget.palavras.length;
    final tecla = _tecla();
    return ExcludeFocus(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(text: '🆕 $n ${n == 1 ? 'palavra nova' : 'palavras novas'} nesta lição · '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: InkWell(
                key: const Key('treinar-antes'),
                onTap: widget.onConhecer,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  child: Text('🎯 conhecer antes',
                      style: Mixart.ui(size: 12.5, weight: FontWeight.w800, color: Mixart.brand)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
              ),
            ),
            if (tecla != null) ...[
              const TextSpan(text: ' '),
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: tecla),
            ],
          ]),
          style: Mixart.ui(size: 12.5, weight: FontWeight.w700, color: Mixart.textMuted),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compacto) return _linha();
    final n = widget.palavras.length;
    final mostradas = widget.palavras.take(widget.maxChips).toList();
    final resto = n - mostradas.length;
    final tecla = _tecla();
    Widget chip(int i, Widget filho) {
      final ini = (.08 * i).clamp(0.0, .6);
      final anim = CurvedAnimation(parent: _entrada, curve: Interval(ini, (ini + .4).clamp(0.0, 1.0), curve: Mixart.spring));
      return AnimatedBuilder(
        animation: anim,
        builder: (_, f) => Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(scale: .6 + .4 * anim.value, child: f),
        ),
        child: filho,
      );
    }

    return ExcludeFocus(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        decoration: BoxDecoration(
          color: Mixart.brandSub,
          border: Border.all(color: Mixart.brandDim),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('🆕 Esta lição tem $n ${n == 1 ? 'palavra nova' : 'palavras novas'}',
              style: Mixart.display(size: 15, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Quer conhecer antes? Leva 1 minutinho — ou comece direto, você escolhe.',
              style: Mixart.ui(size: 12, color: Mixart.textMuted).copyWith(height: 1.35)),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < mostradas.length; i++)
              chip(
                i,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Mixart.surface,
                    border: Border.all(color: Mixart.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(mostradas[i].en, style: Mixart.mono(size: 13, weight: FontWeight.w800, color: Mixart.brand)),
                    Text(mostradas[i].pt, style: Mixart.ui(size: 10.5, weight: FontWeight.w600, color: Mixart.textMuted)),
                  ]),
                ),
              ),
            if (resto > 0)
              chip(
                mostradas.length,
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                  decoration: BoxDecoration(color: Mixart.surface, borderRadius: BorderRadius.circular(10)),
                  child: Text('+$resto', style: Mixart.ui(size: 12, weight: FontWeight.w800, color: Mixart.textMuted)),
                ),
              ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
            Botao3D(
              key: const Key('treinar-antes'),
              rotulo: '🎯 Conhecer antes',
              expandir: false,
              altura: 38,
              tamanhoTexto: 13.5,
              onTap: widget.onConhecer,
            ),
            ?tecla,
            TextButton(
              key: const Key('comecar-direto'),
              onPressed: widget.onComecar,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('Começar direto',
                  style: Mixart.ui(size: 13, weight: FontWeight.w700, color: Mixart.textMuted)),
            ),
          ]),
        ]),
      ),
    );
  }
}
