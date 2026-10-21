import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/fila_ouvir.dart';
import '../widgets/elenco_ingles.dart';
import 'ouvir_acoes.dart';
import 'ouvir_cubit.dart';
import 'ouvir_state.dart';

/// O fundo fixo do rosto (o mesmo do cartão da tradução no palco).
const corFundoRosto = Color(0xFFFFF1DC);

/// O rosto de quem diz a faixa, mexendo a boca com a voz. Sem personagem (narrador / frase órfã) mostra 🎧;
/// com "reduzir animações" ligado, o rosto fica parado.
class RostoDaFaixa extends StatelessWidget {
  final Faixa? faixa;
  final double tamanho;
  const RostoDaFaixa({super.key, required this.faixa, required this.tamanho});

  @override
  Widget build(BuildContext context) {
    final f = faixa;
    final aparencia = f == null ? null : ElencoIngles.de(f.quem);
    final Widget dentro;
    if (f == null || aparencia == null) {
      dentro = Center(child: Text('🎧', style: TextStyle(fontSize: tamanho * .5)));
    } else if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      dentro = RostoPersonagem(aparencia: aparencia, tamanho: tamanho);
    } else {
      dentro = PersonagemFalante(quem: f.quem, tamanho: tamanho, frase: f.en);
    }
    return ExcludeSemantics(
      child: ClipOval(
        child: SizedBox.square(
          dimension: tamanho,
          child: ColoredBox(color: corFundoRosto, child: dentro),
        ),
      ),
    );
  }
}

/// A barra do player embaixo do app: rosto, a frase, "{lição} · 34/212" e ⏯ ⏭ ✕ (⏪ também, a partir de
/// 600 px). Tocar na barra abre o "Tocando agora". Mora acima do Navigator: sem Tooltip (não há Overlay).
class MiniPlayer extends StatelessWidget {
  final OuvirCubit cubit;

  /// A altura total que o [OuvirShell] reservou (barra + área segura + margem).
  final double altura;

  const MiniPlayer({super.key, required this.cubit, required this.altura});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final largo = mq.size.width >= OuvirShell.larguraCartao;
    return SizedBox(
      height: altura,
      child: BlocBuilder<OuvirCubit, OuvirState>(
        bloc: cubit,
        builder: (context, st) {
          final barra = _Barra(cubit: cubit, st: st, comAnterior: mq.size.width >= 600);
          if (!largo) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Mixart.surface,
                border: Border(top: BorderSide(color: Mixart.border)),
              ),
              child: Padding(
                padding: EdgeInsets.only(bottom: mq.padding.bottom),
                child: barra,
              ),
            );
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + mq.padding.bottom),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Mixart.surface,
                    borderRadius: BorderRadius.circular(Mixart.radiusMd),
                    border: Border.all(color: Mixart.border),
                    boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6))],
                  ),
                  child: barra,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final OuvirCubit cubit;
  final OuvirState st;
  final bool comAnterior;
  const _Barra({required this.cubit, required this.st, required this.comAnterior});

  String _linha2() {
    final f = st.atual;
    final total = st.fila.length;
    if (st.status == StatusOuvir.acabou) return 'Fim de «${st.fonte?.titulo ?? ''}» 🎉';
    if (st.status == StatusOuvir.pausado) {
      switch (st.motivo) {
        case MotivoPausa.outraFala:
          return 'Pausado — outra fala começou';
        case MotivoPausa.semSom:
          return 'Sem som — toque ▶ para tentar de novo';
        case MotivoPausa.timer:
          return 'Timer acabou 🌙';
        case MotivoPausa.usuario:
        case null:
          break;
      }
    }
    final onde = (f == null || f.licaoNome.isEmpty) ? (st.fonte?.titulo ?? '') : f.licaoNome;
    return '$onde · ${st.indice + 1}/$total';
  }

  @override
  Widget build(BuildContext context) {
    final f = st.atual;
    final tocando = st.status == StatusOuvir.tocando;
    final total = st.fila.length;
    final progresso = total == 0 ? 0.0 : ((st.indice + 1) / total).clamp(0.0, 1.0);
    final aviso = st.status == StatusOuvir.acabou ||
        (st.status == StatusOuvir.pausado && st.motivo != null && st.motivo != MotivoPausa.usuario);
    return Column(
      key: const Key('mini-player'),
      children: [
        SizedBox(
          height: 3,
          child: LinearProgressIndicator(
            value: progresso,
            minHeight: 3,
            color: Mixart.brand,
            backgroundColor: Mixart.border,
          ),
        ),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('mini-player-abrir'),
              onTap: () => abrirTocando(context),
              child: Semantics(
                button: true,
                label: 'Abrir o player',
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
                  child: Row(children: [
                    RostoDaFaixa(faixa: f, tamanho: 38),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f?.en ?? '',
                            key: const Key('mini-player-frase'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Mixart.ui(size: 14, weight: FontWeight.w700, color: Mixart.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _linha2(),
                            key: const Key('mini-player-linha2'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Mixart.ui(
                                size: 12,
                                weight: aviso ? FontWeight.w700 : FontWeight.w500,
                                color: aviso ? Mixart.brand : Mixart.textMuted),
                          ),
                        ],
                      ),
                    ),
                    if (comAnterior)
                      _BotaoBarra(
                        chave: 'mini-player-anterior',
                        rotulo: 'Frase anterior',
                        icone: Icons.fast_rewind_rounded,
                        onTap: cubit.anterior,
                      ),
                    _BotaoBarra(
                      chave: 'mini-player-play',
                      rotulo: tocando ? 'Pausar' : 'Tocar',
                      icone: tocando ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      cheio: true,
                      onTap: () {
                        final fonte = st.fonte;
                        if (st.status == StatusOuvir.acabou && fonte != null) {
                          cubit.tocar(fonte, st.fila);
                        } else {
                          cubit.alternar();
                        }
                      },
                    ),
                    _BotaoBarra(
                      chave: 'mini-player-proxima',
                      rotulo: 'Próxima frase',
                      icone: Icons.skip_next_rounded,
                      onTap: cubit.proxima,
                    ),
                    _BotaoBarra(
                      chave: 'mini-player-fechar',
                      rotulo: 'Fechar player',
                      icone: Icons.close_rounded,
                      onTap: cubit.fechar,
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Botão de 48 px da barra, com rótulo de acessibilidade (sem Tooltip: a barra fica fora do Overlay).
class _BotaoBarra extends StatelessWidget {
  final String chave, rotulo;
  final IconData icone;
  final VoidCallback onTap;
  final bool cheio;
  const _BotaoBarra({required this.chave, required this.rotulo, required this.icone, required this.onTap, this.cheio = false});

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: rotulo,
        // o excludeSemantics tira também a ação de toque do InkResponse: o nó carrega a dele
        excludeSemantics: true,
        onTap: onTap,
        child: InkResponse(
          key: Key(chave),
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Center(
              child: cheio
                  ? Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Mixart.brand, shape: BoxShape.circle),
                      child: Icon(icone, size: 24, color: Mixart.onBrand),
                    )
                  : Icon(icone, size: 24, color: Mixart.text),
            ),
          ),
        ),
      );
}
