import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/mixart.dart';
import '../../domain/config_ouvir.dart';
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

/// No "Português → inglês", o inglês fica escondido enquanto a pessoa pensa.
bool escondeIngles(OuvirState st) =>
    st.config.modo == ModoOuvir.portuguesIngles &&
    st.status == StatusOuvir.tocando &&
    (st.fase == FaseOuvir.traducao || st.fase == FaseOuvir.pense);

/// A tradução aparece com o chip "Tradução" ligado (e sempre no "Português → inglês").
bool mostraTraducao(Faixa f, ConfigOuvir c) =>
    f.pt.isNotEmpty && (c.mostrarTraducao || c.modo == ModoOuvir.portuguesIngles);

/// A imagem da faixa: a foto real da cena da lição com o emoji do sentido da frase num selo (sem foto, os
/// emojis num degradê) e, com personagem, o rosto dele falando no canto. Troca com um esmaecer curto.
class ImagemDaFaixa extends StatelessWidget {
  final Faixa faixa;
  final double largura, altura;
  final double raio;

  /// Mostra o rosto de quem fala no canto (o mini-player mostra; o "Tocando agora" já tem o rosto grande).
  final bool comRosto;

  const ImagemDaFaixa({
    super.key,
    required this.faixa,
    required this.largura,
    required this.altura,
    this.raio = 12,
    this.comRosto = true,
  });

  @override
  Widget build(BuildContext context) {
    final f = faixa;
    final menor = largura < altura ? largura : altura;
    final emojiFrase = f.imagem.trim();
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 2;
    final semFoto = Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: [Mixart.brandSub, Mixart.surfaceHi])),
      alignment: Alignment.center,
      padding: EdgeInsets.all(menor * .08),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          emojiFrase.isNotEmpty ? emojiFrase : (f.cena.trim().isNotEmpty ? f.cena : f.licaoEmoji),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: menor * .4, height: 1.1),
        ),
      ),
    );
    final Widget fundo = f.foto.isEmpty
        ? semFoto
        : Image.asset(
            f.foto,
            fit: BoxFit.cover,
            width: largura,
            height: altura,
            cacheWidth: (largura * dpr).round(),
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => semFoto,
          );
    final rosto = comRosto && ElencoIngles.de(f.quem) != null;
    final selo = menor * (menor < 120 ? .3 : .22);
    final conteudo = Stack(fit: StackFit.expand, children: [
      fundo,
      if (f.foto.isNotEmpty && emojiFrase.isNotEmpty)
        Positioned(
          right: menor * .05,
          bottom: menor * .05,
          child: Container(
            key: const Key('imagem-faixa-selo'),
            constraints: BoxConstraints(maxWidth: largura * .8),
            padding: EdgeInsets.symmetric(horizontal: selo * .22, vertical: selo * .1),
            decoration: BoxDecoration(
              color: const Color(0xF2FFFFFF),
              borderRadius: BorderRadius.circular(selo),
              boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            // o selo abraça os emojis (um FittedBox aqui esticaria até a largura máxima)
            child: Text(emojiFrase,
                maxLines: 1,
                overflow: TextOverflow.clip,
                softWrap: false,
                style: TextStyle(fontSize: selo * .6, height: 1.1)),
          ),
        ),
      if (rosto)
        Positioned(
          left: menor * .04,
          top: menor * .04,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 5, offset: Offset(0, 1))],
            ),
            child: RostoDaFaixa(faixa: f, tamanho: menor * (menor < 120 ? .34 : .24)),
          ),
        ),
    ]);
    final semAnimar = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Semantics(
      image: true,
      label: emojiFrase.isEmpty ? 'Imagem da cena' : 'Imagem da frase: $emojiFrase',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(raio),
          child: SizedBox(
            width: largura,
            height: altura,
            child: AnimatedSwitcher(
              duration: semAnimar ? Duration.zero : const Duration(milliseconds: 220),
              child: KeyedSubtree(key: ValueKey('${f.foto}|${f.chave}'), child: conteudo),
            ),
          ),
        ),
      ),
    );
  }
}

/// A barra do player embaixo do app. Linha de cima: a imagem da frase (ou o rosto de quem diz), a frase em
/// inglês e a tradução embaixo. Linha de baixo: "{lição} · 34/212", os botões de mostrar/esconder tradução e
/// imagens, e ⏯ ⏭ ✕ (⏪ também, a partir de 600 px). Tocar na linha de cima abre o "Tocando agora". Mora
/// acima do Navigator: sem Tooltip (não há Overlay).
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
      // a barra tem altura fixa: a fonte do sistema cresce só um pouco aqui (o "Tocando agora" cresce inteiro)
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: BlocBuilder<OuvirCubit, OuvirState>(
          bloc: cubit,
          builder: (context, st) {
            final barra = _Barra(cubit: cubit, st: st, cartao: largo, comAnterior: mq.size.width >= 600);
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
                  constraints: const BoxConstraints(maxWidth: OuvirShell.larguraMaxCartao),
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
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  final OuvirCubit cubit;
  final OuvirState st;
  final bool cartao, comAnterior;
  const _Barra({required this.cubit, required this.st, required this.cartao, required this.comAnterior});

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
    final cfg = st.config;
    final tocando = st.status == StatusOuvir.tocando;
    final total = st.fila.length;
    final progresso = total == 0 ? 0.0 : ((st.indice + 1) / total).clamp(0.0, 1.0);
    final aviso = st.status == StatusOuvir.acabou ||
        (st.status == StatusOuvir.pausado && st.motivo != null && st.motivo != MotivoPausa.usuario);
    final rica = OuvirShell.barraRica(cfg);
    final altConteudo = OuvirShell.alturaConteudo(cfg, cartao: cartao);
    final comImagem = cfg.mostrarImagens && f != null && f.temImagem;
    final escondeEn = escondeIngles(st);
    final pt = f != null && mostraTraducao(f, cfg);
    final ladoImagem = altConteudo - (cartao ? 16 : 12);
    final textoEn = Text(
      escondeEn ? '…' : (f?.en ?? ''),
      key: const Key('mini-player-frase'),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      semanticsLabel: escondeEn ? 'Pense: como se diz em inglês?' : null,
      style: Mixart.ui(size: cartao ? 19 : (rica ? 15.5 : 15), weight: FontWeight.w800, color: Mixart.text)
          .copyWith(height: 1.2),
    );
    final linhaDeCima = Padding(
      padding: EdgeInsets.fromLTRB(cartao ? 12 : 10, cartao ? 10 : 8, 12, cartao ? 6 : 4),
      child: Row(children: [
        if (comImagem)
          ImagemDaFaixa(key: const Key('mini-player-imagem'), faixa: f, largura: ladoImagem, altura: ladoImagem)
        else
          RostoDaFaixa(faixa: f, tamanho: rica ? (cartao ? 64 : 52) : (cartao ? 52 : 44)),
        SizedBox(width: cartao ? 14 : 10),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(child: textoEn),
              if (pt) ...[
                SizedBox(height: cartao ? 4 : 3),
                Flexible(
                  child: Text(
                    f.pt,
                    key: const Key('mini-player-traducao'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Mixart.ui(size: cartao ? 15 : 13, weight: FontWeight.w500, color: Mixart.textMuted)
                        .copyWith(height: 1.25),
                  ),
                ),
              ],
            ],
          ),
        ),
      ]),
    );
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
        SizedBox(
          height: altConteudo,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const Key('mini-player-abrir'),
              onTap: () => abrirTocando(context),
              child: Semantics(button: true, label: 'Abrir o player', child: linhaDeCima),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(cartao ? 14 : 12, 0, 4, 0),
            child: Row(children: [
              Expanded(
                child: Text(
                  _linha2(),
                  key: const Key('mini-player-linha2'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Mixart.ui(
                      size: 12,
                      weight: aviso ? FontWeight.w700 : FontWeight.w500,
                      color: aviso ? Mixart.brand : Mixart.textMuted),
                ),
              ),
              _AlternarBarra(
                chave: 'mini-player-traducao-alternar',
                rotulo: 'Tradução',
                icone: cfg.mostrarTraducao ? Icons.subtitles_rounded : Icons.subtitles_off_rounded,
                ligado: cfg.mostrarTraducao,
                comTexto: comAnterior,
                onTap: () => cubit.configurar(cfg.copyWith(mostrarTraducao: !cfg.mostrarTraducao)),
              ),
              _AlternarBarra(
                chave: 'mini-player-imagens-alternar',
                rotulo: 'Imagens',
                icone: cfg.mostrarImagens ? Icons.image_rounded : Icons.hide_image_rounded,
                ligado: cfg.mostrarImagens,
                comTexto: comAnterior,
                onTap: () => cubit.configurar(cfg.copyWith(mostrarImagens: !cfg.mostrarImagens)),
              ),
              SizedBox(width: comAnterior ? 8 : 2),
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
      ],
    );
  }
}

/// Liga/desliga tradução ou imagens direto na barra: só o ícone no celular, ícone + nome a partir de 600 px.
class _AlternarBarra extends StatelessWidget {
  final String chave, rotulo;
  final IconData icone;
  final bool ligado, comTexto;
  final VoidCallback onTap;
  const _AlternarBarra({
    required this.chave,
    required this.rotulo,
    required this.icone,
    required this.ligado,
    required this.comTexto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cor = ligado ? Mixart.brand : Mixart.textFaint;
    return Semantics(
      button: true,
      toggled: ligado,
      label: '$rotulo: ${ligado ? 'ligada' : 'desligada'}',
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        key: Key(chave),
        onTap: onTap,
        radius: 22,
        containedInkWell: comTexto,
        highlightShape: comTexto ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: BorderRadius.circular(Mixart.radiusChip),
        child: SizedBox(
          height: 44,
          width: comTexto ? null : 44,
          child: Center(
            child: comTexto
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: ligado ? Mixart.brandSub : Colors.transparent,
                      borderRadius: BorderRadius.circular(Mixart.radiusChip),
                      border: Border.all(color: ligado ? Mixart.brandDim : Mixart.border),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icone, size: 17, color: cor),
                      const SizedBox(width: 5),
                      Text(rotulo,
                          style: Mixart.ui(
                              size: 12.5, weight: FontWeight.w700, color: ligado ? Mixart.text : Mixart.textMuted)),
                    ]),
                  )
                : Icon(icone, size: 22, color: cor),
          ),
        ),
      ),
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
