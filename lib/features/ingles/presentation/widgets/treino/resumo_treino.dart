import 'package:flutter/material.dart';

import '../../../../../core/som/sons.dart';
import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../domain/banco_palavras.dart';
import '../../../domain/roteiro_treino.dart';
import '../cartao_teimosas.dart' show SeloDominada;

/// O fim da sessão: o baú (abre ao tocar, com confete e fanfarra), "Treino concluído!", os números
/// (acerto de primeira, melhor combo, palavras), um chip por palavra com como ela saiu e os botões
/// (🎮 jogar com elas, treinar de novo, continuar — ou as próximas palavras, quando há mais um lote).
class ResumoTreino extends StatefulWidget {
  final ResultadoTreino resultado;

  /// Quantas palavras vêm no próximo lote (0 = acabou).
  final int proximas;
  final VoidCallback onContinuar;
  final VoidCallback onDeNovo;

  /// Null = nenhuma palavra entra nos jogos (só letras A–Z).
  final VoidCallback? onJogar;
  final VoidCallback? onProximas;

  /// Mostra "Enter = continuar" (só no computador: no celular não há Enter).
  final bool dicaTeclado;

  /// Revanche das "🔥 teimosas": "Revanche concluída!", as ⭐ de cada palavra (acertos limpos seguidos, de
  /// 2), o selo "🏆 DOMINADA!" das [dominadas] e o "📝 Virar lição" ([onLicao]).
  final bool revanche;
  final List<String> dominadas;
  final Map<String, int> acertos;
  final VoidCallback? onLicao;

  /// O texto do botão principal ("COMEÇAR A LIÇÃO →" quando o treino veio antes de uma lição).
  final String rotuloContinuar;

  const ResumoTreino({
    super.key,
    required this.resultado,
    required this.onContinuar,
    required this.onDeNovo,
    this.onJogar,
    this.proximas = 0,
    this.onProximas,
    this.dicaTeclado = false,
    this.revanche = false,
    this.dominadas = const [],
    this.acertos = const {},
    this.onLicao,
    this.rotuloContinuar = 'CONTINUAR',
  });

  @override
  State<ResumoTreino> createState() => _ResumoTreinoState();
}

class _ResumoTreinoState extends State<ResumoTreino> with SingleTickerProviderStateMixin {
  late final _tampa = AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  int _confete = 0;

  void _abrir() {
    if (_tampa.value > 0) return;
    _tampa.forward();
    Sons.toca(Som.fanfarra);
    setState(() => _confete++);
  }

  @override
  void dispose() {
    _tampa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.resultado;
    final n = r.palavras.length;
    final verde = escurecer(CoresFesta.verde, quanto: .2, soNoClaro: true);
    final ambar = escurecer(CoresFesta.ambar, quanto: .2, soNoClaro: true);
    final azul = escurecer(CoresFesta.azul, quanto: .25, soNoClaro: true);
    final coral = escurecer(CoresFesta.coral, quanto: .2, soNoClaro: true);
    final mais = widget.proximas > 0 && widget.onProximas != null;
    return Stack(children: [
      Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            key: const Key('treino-resumo'),
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                key: const Key('treino-bau'),
                onTap: _abrir,
                behavior: HitTestBehavior.opaque,
                child: Semantics(
                  button: true,
                  label: 'Abrir o baú',
                  child: AnimatedBuilder(
                    animation: _tampa,
                    builder: (_, _) => CustomPaint(
                      size: const Size(150, 124),
                      painter: BauPainter(
                        abertura: Curves.elasticOut.transform(_tampa.value).clamp(0.0, 1.0),
                        brilho: .55 + .45 * _tampa.value,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _tampa,
                builder: (_, _) => Opacity(
                  opacity: (1 - _tampa.value * 2).clamp(0.0, 1.0),
                  child: Text('Toque no baú 🎁', style: Mixart.ui(size: 12, weight: FontWeight.w600, color: Mixart.textFaint)),
                ),
              ),
              const SizedBox(height: 10),
              Text(widget.revanche ? 'Revanche concluída!' : 'Treino concluído!',
                  textAlign: TextAlign.center, style: Mixart.display(size: 30, weight: FontWeight.w800, color: Mixart.brand)),
              const SizedBox(height: 6),
              Text(
                widget.revanche
                    ? '${r.dePrimeira} de $n de primeira 💪'
                    : '${r.dePrimeira} de $n ${n == 1 ? 'palavra' : 'palavras'} de primeira',
                textAlign: TextAlign.center,
                style: Mixart.ui(size: 15, weight: FontWeight.w600, color: Mixart.textMuted),
              ),
              if (widget.revanche && widget.dominadas.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
                  for (var i = 0; i < widget.dominadas.length; i++) SeloDominada(widget.dominadas[i], som: i == 0),
                ]),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: _Numero(rotulo: 'ACERTO', valor: '${r.pct}%', cor: verde, icone: Icons.track_changes_rounded)),
                const SizedBox(width: 10),
                Expanded(
                    child: _Numero(
                        rotulo: 'COMBO', valor: '${r.melhorCombo}', cor: coral, icone: Icons.local_fire_department_rounded)),
                const SizedBox(width: 10),
                Expanded(child: _Numero(rotulo: 'PALAVRAS', valor: '$n', cor: azul, icone: Icons.style_rounded)),
              ]),
              const SizedBox(height: 18),
              if (widget.revanche)
                Column(key: const Key('revanche-palavras'), children: [
                  for (final p in r.palavras)
                    _LinhaRevanche(
                      en: p.en,
                      pt: ItemTreino.de(p).pt,
                      // quem acertou agora tem pelo menos 1 ⭐ (a palavra leve não conta sequência no banco)
                      estrelas: (widget.acertos[p.chave] ?? 0)
                          .clamp(r.notas[p.chave] == ResultadoRevisao.acertou ? 1 : 0, 2),
                      dominada: widget.dominadas.any((d) => d.toLowerCase() == p.chave),
                    ),
                ])
              else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final p in r.palavras)
                    _ChipPalavra(
                      en: p.en,
                      // a tradução curta dos botões (a própria do aluno pode ter 60 letras)
                      pt: ItemTreino.de(p).pt,
                      nota: r.notas[p.chave],
                      verde: verde,
                      ambar: ambar,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (mais) ...[
                Botao3D(
                  key: const Key('treino-proximas'),
                  rotulo: 'PRÓXIMAS ${widget.proximas} PALAVRAS →',
                  onTap: widget.onProximas,
                ),
                const SizedBox(height: 12),
              ],
              Botao3D(
                key: const Key('treino-concluir'),
                rotulo: widget.rotuloContinuar,
                contorno: mais,
                onTap: widget.onContinuar,
              ),
              if (widget.onJogar != null) ...[
                const SizedBox(height: 12),
                Botao3D(
                  key: const Key('jogar-palavras'),
                  rotulo: widget.revanche ? '🎮 Jogar com elas' : '🎮 Jogar com essas palavras',
                  cor: azul,
                  onTap: widget.onJogar,
                ),
              ],
              if (widget.onLicao != null) ...[
                const SizedBox(height: 12),
                Botao3D(
                  key: const Key('treino-virar-licao'),
                  rotulo: '📝 Virar lição',
                  contorno: true,
                  onTap: widget.onLicao,
                ),
              ],
              const SizedBox(height: 12),
              Botao3D(
                key: const Key('treinar-de-novo'),
                rotulo: 'Treinar de novo',
                contorno: true,
                altura: 44,
                tamanhoTexto: 14,
                onTap: widget.onDeNovo,
              ),
              if (widget.dicaTeclado) ...[
                const SizedBox(height: 8),
                Text('Enter = continuar', style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
              ],
            ],
          ),
        ),
      ),
      if (_confete > 0)
        Positioned.fill(
          child: Confete(key: ValueKey('confete-$_confete'), quantidade: 60, origem: const Alignment(0, -.75)),
        ),
    ]);
  }
}

/// Revanche: uma palavra com as ⭐ (acertos limpos seguidos, de 2 para dominar) e como ficou.
class _LinhaRevanche extends StatelessWidget {
  final String en, pt;
  final int estrelas;
  final bool dominada;
  const _LinhaRevanche({required this.en, required this.pt, required this.estrelas, required this.dominada});

  @override
  Widget build(BuildContext context) {
    final cheias = dominada ? 2 : estrelas.clamp(0, 2);
    final ouro = escurecer(CoresFesta.ouro, quanto: .25, soNoClaro: true);
    final legenda = dominada
        ? '🏆 dominada!'
        : (cheias >= 1 ? 'quase lá — volta amanhã pra fechar' : 'ainda escapa — ela volta logo');
    return Container(
      key: Key('revanche-$en'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: dominada ? ouro : Mixart.border, width: dominada ? 1.6 : 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(en,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Mixart.mono(size: 15, weight: FontWeight.w800, color: Mixart.text)),
            Text('$pt · $legenda',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Mixart.ui(size: 11.5, weight: FontWeight.w600, color: Mixart.textMuted)),
          ]),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: '$cheias de 2 estrelas',
          child: Text(
            '${'⭐' * cheias}${'☆' * (2 - cheias)}',
            key: Key('estrelas-$en'),
            style: TextStyle(fontSize: 17, color: ouro),
          ),
        ),
      ]),
    );
  }
}

class _Numero extends StatelessWidget {
  final String rotulo, valor;
  final Color cor;
  final IconData icone;
  const _Numero({required this.rotulo, required this.valor, required this.cor, required this.icone});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
        child: Column(children: [
          Text(rotulo,
              style: Mixart.ui(size: 10.5, weight: FontWeight.w900, color: corSobre(cor)).copyWith(letterSpacing: .8)),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(color: Mixart.surface, borderRadius: BorderRadius.circular(12)),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icone, size: 18, color: cor),
                const SizedBox(width: 6),
                Text(valor, style: Mixart.display(size: 20, weight: FontWeight.w800, color: cor)),
              ]),
            ),
          ),
        ]),
      );
}

class _ChipPalavra extends StatelessWidget {
  final String en, pt;
  final ResultadoRevisao? nota;
  final Color verde, ambar;
  const _ChipPalavra({required this.en, required this.pt, required this.nota, required this.verde, required this.ambar});

  @override
  Widget build(BuildContext context) {
    final (cor, rotulo) = switch (nota) {
      ResultadoRevisao.acertou => (verde, 'de primeira'),
      ResultadoRevisao.hesitou => (ambar, 'quase'),
      ResultadoRevisao.errou => (Mixart.danger, 'volta logo'),
      null => (Mixart.textFaint, '—'),
    };
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 12, 7),
      decoration: BoxDecoration(
        color: Mixart.surface,
        border: Border.all(color: cor.withValues(alpha: .6), width: 1.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: cor, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        // Flexible + 1 linha com reticências: um chip nunca passa da largura da tela
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(en,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Mixart.mono(size: 14, weight: FontWeight.w800, color: Mixart.text)),
            // só a tradução encolhe: o "· volta logo" fica sempre à vista
            Row(mainAxisSize: MainAxisSize.min, children: [
              Flexible(
                child: Text(pt,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.ui(size: 11, weight: FontWeight.w600, color: Mixart.textMuted)),
              ),
              Text(' · $rotulo',
                  maxLines: 1, style: Mixart.ui(size: 11, weight: FontWeight.w600, color: Mixart.textMuted)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
