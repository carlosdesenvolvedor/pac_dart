import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import '../../../../core/util/abrir_url.dart';
import '../../../curso/domain/curriculo.dart';
import '../../domain/fonte_frase.dart';
import '../../domain/roteiro.dart';

/// A tradução em português EM CIMA da frase (o pedido do curso): a frase
/// natural grande, o "ao pé da letra" quando ajuda a ver a estrutura, a nota
/// curta da lição e os botões de áudio/dica.
class TraducaoCard extends StatelessWidget {
  final Trecho trecho;
  final ModoFrase modo;

  /// Mostra a nota ("Entenda") — na estreia e nas cópias.
  final bool mostrarNota;

  final bool audioAuto;
  final VoidCallback onOuvir, onOuvirDevagar;

  /// null = sem dica neste modo (copiando, a frase já está à vista).
  final VoidCallback? onDica;

  /// "Não sei" (Esc): mostra a frase inteira.
  final VoidCallback? onNaoSei;
  final VoidCallback? onAlternarAudio;

  /// A voz automática fala devagar (o padrão) — caixinha "voz devagar".
  final bool vozLenta;
  final VoidCallback? onAlternarVozLenta;

  /// 👁 como chave: ligado, o inglês fica à vista em TODAS as frases (não
  /// só nesta). Sem a chave, o 👁 é o "não sei" desta frase ([onNaoSei]).
  final bool verFrases;
  final VoidCallback? onAlternarVerFrases;

  /// Quem disse a fala do [Trecho.contexto] (achado na lição), se souber.
  final String quemDoContexto;

  /// Mostra a fala anterior em português (a frase dela ainda não foi
  /// concluída nesta lição).
  final bool contextoEmPt;

  /// Teclado virtual aberto no celular: sobra pouca tela, então só ficam a
  /// tradução e os botões (a nota, a fonte e as caixinhas voltam quando o
  /// teclado fecha).
  final bool compacto;

  /// Botão a mais ao lado dos de áudio (o 🎧 do áudio do aluno).
  final Widget? acaoAudio;

  /// O rosto de quem diz a frase (mexendo a boca com a voz), à esquerda da tradução; recebe o tamanho.
  final Widget Function(double tamanho)? rosto;

  /// 🎬 A cena da historinha no lugar do rosto (com ela, o [rosto] é ignorado); recebe o tamanho da caixa. No
  /// celular (ou num cartão estreito) é uma faixa de largura total no topo do cartão; no computador, uma caixa
  /// 16:9 à esquerda da tradução. Com o teclado aberto ([compacto]), uma faixa baixa.
  final Widget Function(Size tamanho)? cena;

  /// 🎬 Quanto a faixa da cena ocupa num cartão estreito (o palco mede se a zona de digitação cabe na tela):
  /// a faixa cheia, a baixa ou a miniatura no lugar do rosto. No cartão largo (caixa ao lado), não muda nada.
  final TamanhoCena tamanhoCena;

  /// A chave "🎬 Cena / 🙂 Rosto" (na linha das caixinhas); null = sem a chave (lição sem historinha).
  final VoidCallback? onAlternarCena;
  final bool cenaLigada;

  /// Abaixo desta largura (do interior do cartão) a cena vira faixa no topo, em vez de caixa ao lado.
  static const larguraCenaAoLado = 680.0;

  const TraducaoCard({
    super.key,
    required this.trecho,
    required this.modo,
    this.mostrarNota = true,
    this.audioAuto = true,
    required this.onOuvir,
    required this.onOuvirDevagar,
    this.onDica,
    this.onNaoSei,
    this.onAlternarAudio,
    this.vozLenta = true,
    this.onAlternarVozLenta,
    this.verFrases = false,
    this.onAlternarVerFrases,
    this.quemDoContexto = '',
    this.contextoEmPt = false,
    this.compacto = false,
    this.acaoAudio,
    this.rosto,
    this.cena,
    this.onAlternarCena,
    this.cenaLigada = true,
    this.tamanhoCena = TamanhoCena.cheia,
  });

  /// O tamanho da cena: a faixa de cima ([faixa]) ou a caixa ao lado da tradução, para o [interior] do cartão.
  /// Na faixa, [tamanho] escolhe a cheia, a baixa (96 px, a do teclado aberto) ou a miniatura ([tamanhoMini]).
  static Size tamanhoDaCena({
    required double interior,
    required bool faixa,
    required bool compacto,
    required double alturaTela,
    TamanhoCena tamanho = TamanhoCena.cheia,
  }) {
    if (faixa) {
      return switch (tamanho) {
        TamanhoCena.mini => tamanhoMini(compacto: compacto),
        TamanhoCena.baixa => Size(interior, 96),
        TamanhoCena.cheia => Size(interior, compacto ? 96 : (interior * .5).clamp(112.0, 150.0)),
      };
    }
    final w = compacto ? 171.0 : math.min(alturaTela >= 900 ? 320.0 : 288.0, interior * .36);
    return Size(w, w * 9 / 16);
  }

  /// 🎬 A miniatura 16:9 no lugar do rosto, da altura dele (48 com o teclado aberto): não aumenta o cartão.
  static Size tamanhoMini({required bool compacto}) => compacto ? const Size(86, 48) : const Size(96, 54);

  @override
  Widget build(BuildContext context) {
    final estreito = MediaQuery.sizeOf(context).width < 560;
    // a chave da cena: no celular, na linha dos botões (as caixinhas já ocupam a linha delas inteira)
    final chaveNosBotoes = estreito && !compacto && onAlternarCena != null;
    final botoes = Wrap(spacing: 6, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
      _Botao(icone: Icons.volume_up_rounded, dica: 'Ouvir em inglês', onTap: onOuvir),
      _Botao(icone: Icons.slow_motion_video_rounded, dica: 'Ouvir devagar', onTap: onOuvirDevagar),
      ?acaoAudio,
      if (onDica != null)
        _Botao(
            icone: Icons.lightbulb_outline_rounded,
            dica: 'Dica: revela a palavra (Tab = uma letra, Tab Tab = a palavra)',
            onTap: onDica!),
      if (onAlternarVerFrases != null)
        _Botao(
            icone: verFrases ? Icons.visibility_rounded : Icons.visibility_outlined,
            dica: verFrases
                ? 'Frases à vista em todas as frases — toque para esconder de novo'
                : 'Mostrar o inglês em todas as frases (Esc = não sei só nesta)',
            ativo: verFrases,
            onTap: onAlternarVerFrases!)
      else if (onNaoSei != null)
        _Botao(icone: Icons.visibility_outlined, dica: 'Não sei: mostra a frase (Esc)', onTap: onNaoSei!),
      if (chaveNosBotoes) ...[
        const SizedBox(width: 4),
        _ChaveCena(ligada: cenaLigada, onTap: onAlternarCena!),
      ],
    ]);
    final c = cena;
    if (c == null) return _cartao(context, estreito: estreito, botoes: botoes);
    // a decisão faixa/caixa sai da largura do próprio cartão (uma janela média também vira faixa)
    return LayoutBuilder(builder: (context, box) {
      final interior = (box.maxWidth.isFinite ? box.maxWidth : MediaQuery.sizeOf(context).width) - 34;
      final faixa = estreito || interior < larguraCenaAoLado;
      final tam = tamanhoDaCena(
          interior: interior,
          faixa: faixa,
          compacto: compacto,
          alturaTela: MediaQuery.sizeOf(context).height,
          tamanho: tamanhoCena);
      // a miniatura fica na linha da tradução, no lugar do rosto
      final mini = faixa && tamanhoCena == TamanhoCena.mini;
      return _cartao(context,
          estreito: estreito, botoes: botoes, cenaFaixa: faixa && !mini, cenaMini: mini, cenaTamanho: tam);
    });
  }

  Widget _cartao(BuildContext context,
      {required bool estreito, required Widget botoes, bool cenaFaixa = false, bool cenaMini = false, Size? cenaTamanho}) {
    final c = cena;
    final comCena = c != null && cenaTamanho != null;
    // a imagem-emoji e o rótulo "PT" saem quando há rosto no celular ou a cena (ela já mostra a frase)
    final semImagem = comCena || (rosto != null && estreito);
    final semRotulo = comCena || rosto != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      decoration: BoxDecoration(
        color: Mixart.brandSub,
        border: Border.all(color: Mixart.brandDim),
        borderRadius: BorderRadius.circular(Mixart.radiusMd),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (comCena && cenaFaixa) ...[
          KeyedSubtree(key: const Key('caixa-da-cena'), child: c(cenaTamanho)),
          const SizedBox(height: 10),
        ],
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (comCena && !cenaFaixa)
            Padding(
              key: const Key('caixa-da-cena'),
              padding: EdgeInsets.only(right: cenaMini ? 12 : 14),
              child: c(cenaTamanho),
            )
          else if (!comCena && rosto != null)
            Padding(
              key: const Key('rosto-da-frase'),
              padding: const EdgeInsets.only(right: 12),
              // num círculo, como avatar: o peito do personagem some na borda
              child: ClipOval(
                child: ColoredBox(color: const Color(0xFFFFF1DC), child: rosto!(estreito ? (compacto ? 48 : 60) : 84)),
              ),
            ),
          // no celular, com o rosto, a imagem da frase sai (não cabe tudo na linha)
          if (trecho.imagem.isNotEmpty && !semImagem)
            // a imagem do sentido da frase: vê-la junto com a tradução fixa
            // mais (e, de memória, é pista sem entregar as palavras)
            Container(
              width: estreito ? 54 : 70,
              height: estreito ? 54 : 70,
              margin: const EdgeInsets.only(right: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Mixart.bg,
                border: Border.all(color: Mixart.brandDim),
                borderRadius: BorderRadius.circular(Mixart.radiusMd),
              ),
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(trecho.imagem, style: TextStyle(fontSize: estreito ? 26 : 34)),
                ),
              ),
            )
          else if (!semRotulo) ...[
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('PT', style: Mixart.mono(size: 11, weight: FontWeight.w700, color: Mixart.brand)),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (trecho.contexto.isNotEmpty) ...[
                Text(
                    '↳ ${_prefixoQuem(quemDoContexto)}'
                    '${contextoEmPt && trecho.contextoPt.isNotEmpty ? trecho.contextoPt : trecho.contexto}',
                    style: (contextoEmPt && trecho.contextoPt.isNotEmpty
                            ? Mixart.ui(size: 12.5, color: Mixart.textFaint)
                            : Mixart.mono(size: 12.5, color: Mixart.textFaint))
                        .copyWith(height: 1.4)),
                const SizedBox(height: 4),
              ],
              if (nomeDeQuem(trecho.quem) case final nome?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(nome, style: Mixart.ui(size: 11, weight: FontWeight.w800, color: Mixart.brand)),
                ),
              _TextoComAlvo(
                texto: trecho.dicaPlana,
                alvo: trecho.alvoPt,
                estilo: Mixart.display(size: estreito ? 19 : 23, color: Mixart.text).copyWith(height: 1.3),
              ),
              if (trecho.literal.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text('ao pé da letra: ${trecho.literal}',
                    style: Mixart.ui(size: 12.5, color: Mixart.textMuted).copyWith(fontStyle: FontStyle.italic)),
              ],
            ]),
          ),
          if (!estreito) ...[const SizedBox(width: 8), botoes],
        ]),
        // no celular os botões descem para não espremer a tradução
        if (estreito) ...[const SizedBox(height: 10), botoes],
        if (!compacto && mostrarNota && trecho.temConceito) ...[
          const SizedBox(height: 10),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded, size: 15, color: Mixart.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(Trecho.semTags(trecho.conceito),
                  style: Mixart.ui(size: 12.5, color: Mixart.text).copyWith(height: 1.45)),
            ),
          ]),
        ],
        if (!compacto)
          if (FonteFrase.ler(trecho.fonte) case final fonte?) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: () => abrirUrl(fonte.url),
              borderRadius: BorderRadius.circular(6),
              child: Text('ⓘ frase do ${fonte.rotulo}',
                  style: Mixart.ui(size: 10.5, color: Mixart.textFaint)),
            ),
          ],
        if (!compacto && (onAlternarAudio != null || onAlternarVozLenta != null || (onAlternarCena != null && !estreito))) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 16, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
            if (onAlternarAudio != null) _Caixinha(marcada: audioAuto, rotulo: 'áudio automático', onTap: onAlternarAudio!),
            if (onAlternarVozLenta != null)
              _Caixinha(marcada: vozLenta, rotulo: 'voz devagar', onTap: onAlternarVozLenta!),
            if (onAlternarCena != null && !estreito) _ChaveCena(ligada: cenaLigada, onTap: onAlternarCena!),
          ]),
        ],
      ]),
    );
  }
}

/// 🎬 O tamanho da cena num cartão estreito: a faixa [cheia] no topo, a faixa [baixa] (96 px) ou a [mini]atura
/// 16:9 no lugar do rosto (quando nem a baixa deixa a zona de digitação caber na tela do celular).
enum TamanhoCena { cheia, baixa, mini }

/// "Ana: " antes da fala anterior (vazio se não souber quem disse).
String _prefixoQuem(String quem) {
  final n = nomeDeQuem(quem);
  return n == null ? '' : '$n: ';
}

/// Rótulo de quem fala ("Mike", "Você", "Atendente"); null = sem rótulo.
String? nomeDeQuem(String quem) {
  if (quem.isEmpty) return null;
  if (quem == 'voce') return 'Você';
  if (quem == 'dra-lee') return 'Dra. Lee';
  final limpo = quem.replaceAll('-', ' ');
  return limpo[0].toUpperCase() + limpo.substring(1);
}

/// A tradução com o trecho do chunk-alvo destacado (alvo_pt).
class _TextoComAlvo extends StatelessWidget {
  final String texto, alvo;
  final TextStyle estilo;
  const _TextoComAlvo({required this.texto, required this.alvo, required this.estilo});

  @override
  Widget build(BuildContext context) {
    final i = alvo.isEmpty ? -1 : texto.indexOf(alvo);
    if (i < 0) return Text(texto, style: estilo);
    return Text.rich(TextSpan(style: estilo, children: [
      TextSpan(text: texto.substring(0, i)),
      TextSpan(
        text: alvo,
        style: TextStyle(color: Mixart.brand, decoration: TextDecoration.underline, decorationColor: Mixart.brandDim),
      ),
      TextSpan(text: texto.substring(i + alvo.length)),
    ]));
  }
}

class _Botao extends StatelessWidget {
  final IconData icone;
  final String dica;
  final VoidCallback onTap;

  /// Chave ligada (o 👁 das frases à vista): botão cheio.
  final bool ativo;
  const _Botao({required this.icone, required this.dica, required this.onTap, this.ativo = false});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: dica,
        child: Material(
          color: ativo ? Mixart.brand : Mixart.surfaceHi,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(color: ativo ? Mixart.brand : Mixart.border),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icone, size: 18, color: ativo ? Mixart.onBrand : Mixart.brand)),
          ),
        ),
      );
}

/// 🎬 "🎬 Cena" / "🙂 Rosto": o que o cartão mostra em cima da tradução (fica salvo).
class _ChaveCena extends StatelessWidget {
  final bool ligada;
  final VoidCallback onTap;
  const _ChaveCena({required this.ligada, required this.onTap});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: ligada ? 'Mostrando a cena da historinha — toque para ver o rosto de quem fala' : 'Mostrando o rosto — toque para ver a cena da historinha',
        child: InkWell(
          key: const Key('alternar-cena'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Mixart.border),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(ligada ? '🎬 Cena' : '🙂 Rosto', style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
          ),
        ),
      );
}

/// "☑ áudio automático" / "☑ voz devagar".
class _Caixinha extends StatelessWidget {
  final bool marcada;
  final String rotulo;
  final VoidCallback onTap;
  const _Caixinha({required this.marcada, required this.rotulo, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(marcada ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                size: 15, color: Mixart.textMuted),
            const SizedBox(width: 6),
            Text(rotulo, style: Mixart.ui(size: 11.5, color: Mixart.textMuted)),
          ]),
        ),
      );
}
