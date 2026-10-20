import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../domain/roteiro_treino.dart';
import '../pastilha.dart';
import 'passo_conhecer.dart';

/// Um ladrilho "de apertar" da sessão (opção, par): face sobre um lábio mais escuro, com a
/// [marca] (certa = verde, errada = vermelha), [selecionado] (contorno da marca) e [vazio] (já
/// usado: sobra o buraco). Treme ([tremer]) quando erra e pula ([pular]) quando acerta — cada um
/// uma vez, ao mudar o contador.
class Ladrilho3D extends StatefulWidget {
  final String texto;
  final VoidCallback? onTap;
  final MarcaPastilha marca;
  final bool selecionado;
  final bool vazio;

  /// O número da tecla (1–4) no canto; null = sem número.
  final int? tecla;

  /// Uma letra no lugar do número (os pares: A–E na coluna do português).
  final String? letra;

  /// Muda → treme / pula uma vez.
  final int tremer;
  final int pular;
  final double altura;
  final double tamanhoTexto;
  final bool mono;

  const Ladrilho3D({
    super.key,
    required this.texto,
    this.onTap,
    this.marca = MarcaPastilha.nenhuma,
    this.selecionado = false,
    this.vazio = false,
    this.tecla,
    this.letra,
    this.tremer = 0,
    this.pular = 0,
    this.altura = 60,
    this.tamanhoTexto = 17,
    this.mono = false,
  });

  static const labio = 4.0;

  @override
  State<Ladrilho3D> createState() => _Ladrilho3DState();
}

class _Ladrilho3DState extends State<Ladrilho3D> with TickerProviderStateMixin {
  late final _tremor = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final _pulo = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  bool _apertado = false;

  @override
  void didUpdateWidget(covariant Ladrilho3D old) {
    super.didUpdateWidget(old);
    if (widget.tremer != old.tremer) _tremor.forward(from: 0);
    if (widget.pular != old.pular) _pulo.forward(from: 0);
  }

  @override
  void dispose() {
    _tremor.dispose();
    _pulo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verde = escurecer(CoresFesta.verde, quanto: .2, soNoClaro: true);
    final corMarca = switch (widget.marca) {
      MarcaPastilha.certa => verde,
      MarcaPastilha.errada => Mixart.danger,
      MarcaPastilha.nenhuma => widget.selecionado ? Mixart.brand : null,
    };
    final claro = Mixart.atual.ehClaro;
    final Color face, borda, labio, texto;
    if (widget.vazio) {
      face = Mixart.bg;
      borda = Mixart.border;
      labio = Mixart.bg;
      texto = Colors.transparent;
    } else if (corMarca != null) {
      face = Color.alphaBlend(corMarca.withValues(alpha: .16), Mixart.surface);
      borda = corMarca;
      labio = escurecer(corMarca, quanto: .35);
      texto = widget.marca == MarcaPastilha.nenhuma ? Mixart.text : corMarca;
    } else {
      face = Mixart.surface;
      borda = claro ? Mixart.border : Mixart.surfaceHi;
      labio = claro ? escurecer(Mixart.border, quanto: .15) : Mixart.surfaceHi;
      texto = Mixart.text;
    }
    final ativo = widget.onTap != null && !widget.vazio;
    final rotuloTecla = widget.letra ?? widget.tecla?.toString();
    final desce = _apertado ? Ladrilho3D.labio - 1 : 0.0;
    final raio = BorderRadius.circular(14);
    final estilo = widget.mono
        ? Mixart.mono(size: widget.tamanhoTexto, weight: FontWeight.w700, color: texto)
        : Mixart.ui(size: widget.tamanhoTexto, weight: FontWeight.w700, color: texto);
    final tile = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      margin: EdgeInsets.only(top: desce),
      padding: EdgeInsets.only(bottom: widget.vazio ? 0 : Ladrilho3D.labio - desce),
      decoration: BoxDecoration(color: labio, borderRadius: raio),
      child: Container(
        constraints: BoxConstraints(minHeight: widget.altura - (widget.vazio ? 0 : Ladrilho3D.labio)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: face, borderRadius: raio, border: Border.all(color: borda, width: 2)),
        child: Row(children: [
          if (rotuloTecla != null && !widget.vazio)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: corMarca ?? borda, width: 1.5),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(rotuloTecla,
                  style: Mixart.ui(size: 12, weight: FontWeight.w800, color: corMarca ?? Mixart.textFaint)),
            ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: rotuloTecla != null ? 8 : 0, right: rotuloTecla != null ? 24 : 0),
              // palavra em inglês (mono) nunca quebra no meio: encolhe para caber
              child: widget.mono
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(widget.texto, maxLines: 1, softWrap: false, style: estilo),
                    )
                  : Text(widget.texto,
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: estilo),
            ),
          ),
        ]),
      ),
    );
    return Semantics(
      button: ativo,
      label: widget.texto,
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: Listenable.merge([_tremor, _pulo]),
        builder: (_, child) {
          final t = _tremor.value;
          final dx = _tremor.isAnimating ? math.sin(t * math.pi * 6) * 7 * (1 - t) : 0.0;
          final p = _pulo.value;
          final s = _pulo.isAnimating ? 1 + .08 * math.sin(p * math.pi) : 1.0;
          return Transform.translate(offset: Offset(dx, 0), child: Transform.scale(scale: s, child: child));
        },
        child: MouseRegion(
          cursor: ativo ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: ativo ? (_) => setState(() => _apertado = true) : null,
            onTapCancel: ativo ? () => setState(() => _apertado = false) : null,
            onTapUp: ativo
                ? (_) {
                    setState(() => _apertado = false);
                    widget.onTap!();
                  }
                : null,
            child: tile,
          ),
        ),
      ),
    );
  }
}

/// Passos 2 e 4: o inglês (ou só o áudio, no 🎧) e 4 opções em grade 2×2. Tocar (ou as teclas 1–4,
/// que a página repassa) responde na hora: a certa fica verde e pula; a errada treme em vermelho.
class PassoEscolha extends StatelessWidget {
  final PassoTreino passo;
  final ItemTreino item;

  /// A opção escolhida (null = ainda não respondeu).
  final int? escolhida;
  final ValueChanged<int> onEscolher;
  final void Function({required bool lenta}) onOuvir;

  const PassoEscolha({
    super.key,
    required this.passo,
    required this.item,
    required this.escolhida,
    required this.onEscolher,
    required this.onOuvir,
  });

  bool get _ouvir => passo.tipo == TipoPasso.ouvirEscolher;

  @override
  Widget build(BuildContext context) {
    final respondeu = escolhida != null;
    return LayoutBuilder(builder: (context, c) {
      final estreito = c.maxWidth < 520;
      final opcoes = [
        for (var i = 0; i < passo.opcoes.length; i++)
          Ladrilho3D(
            key: Key('treino-opcao-$i'),
            texto: passo.opcoes[i],
            tecla: i + 1,
            mono: _ouvir,
            altura: estreito ? 64 : 68,
            tamanhoTexto: estreito ? 15.5 : 17,
            marca: !respondeu
                ? MarcaPastilha.nenhuma
                : i == passo.correta
                    ? MarcaPastilha.certa
                    : (i == escolhida ? MarcaPastilha.errada : MarcaPastilha.nenhuma),
            tremer: respondeu && i == escolhida && i != passo.correta ? 1 : 0,
            pular: respondeu && i == passo.correta ? 1 : 0,
            onTap: respondeu ? null : () => onEscolher(i),
          ),
      ];
      return Column(
        key: Key(_ouvir ? 'passo-ouvir' : 'passo-escolha'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TituloPasso(_ouvir ? 'O que você ouviu?' : 'Qual é a tradução?'),
          SizedBox(height: estreito ? 18 : 26),
          if (_ouvir)
            Center(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                BotaoSom(
                  key: const Key('treino-ouvir'),
                  icone: Icons.volume_up_rounded,
                  dica: 'Ouvir de novo',
                  tamanho: 92,
                  onTap: () => onOuvir(lenta: false),
                ),
                const SizedBox(width: 14),
                BotaoSom(
                  key: const Key('treino-ouvir-devagar'),
                  icone: Icons.slow_motion_video_rounded,
                  dica: 'Ouvir devagar 🐢',
                  tamanho: 56,
                  destaque: false,
                  onTap: () => onOuvir(lenta: true),
                ),
              ]),
            )
          else
            Row(children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(item.en,
                      key: const Key('treino-prompt'),
                      style: Mixart.display(size: 40, weight: FontWeight.w800, color: Mixart.brand)),
                ),
              ),
              const SizedBox(width: 12),
              BotaoSom(
                key: const Key('treino-ouvir'),
                icone: Icons.volume_up_rounded,
                dica: 'Ouvir',
                tamanho: 40,
                destaque: false,
                onTap: () => onOuvir(lenta: false),
              ),
            ]),
          SizedBox(height: estreito ? 22 : 30),
          _Grade(filhos: opcoes, espaco: estreito ? 10 : 14),
        ],
      );
    });
  }
}

/// Duas colunas, linhas da mesma altura.
class _Grade extends StatelessWidget {
  final List<Widget> filhos;
  final double espaco;
  const _Grade({required this.filhos, required this.espaco});

  @override
  Widget build(BuildContext context) {
    final linhas = <Widget>[];
    for (var i = 0; i < filhos.length; i += 2) {
      if (i > 0) linhas.add(SizedBox(height: espaco));
      linhas.add(IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(child: filhos[i]),
          SizedBox(width: espaco),
          Expanded(child: i + 1 < filhos.length ? filhos[i + 1] : const SizedBox.shrink()),
        ]),
      ));
    }
    return Column(mainAxisSize: MainAxisSize.min, children: linhas);
  }
}
