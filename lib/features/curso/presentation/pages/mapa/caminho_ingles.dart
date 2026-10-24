// O caminho de lições do PAC·ENGLISH (estilo Duolingo): nós de apertar num seno contínuo entre as unidades,
// a estrada na cor da etapa, o balão "COMEÇAR" no nó atual e o baú no fim. O nome da lição fica ao lado do
// nó nas telas largas e embaixo nas estreitas (sempre um Text que dá para tocar). Logo antes do nó atual, o
// nó "🔁 Revisão até aqui" (frases sortidas de tudo o que já foi feito). Tudo por callback: o mapa decide o
// que cada toque faz.
import 'package:flutter/material.dart';

import '../../../../../core/theme/mixart.dart';
import '../../../../../core/ui/festa.dart';
import '../../../domain/curriculo.dart';
import '../../../domain/mapa_regras.dart';
import '../../bloc/curso_bloc.dart';
import 'bau_trilha.dart';
import 'bolha_comecar.dart';
import 'no_3d.dart';
import 'trilho_ingles.dart';

class CaminhoIngles extends StatelessWidget {
  final CursoState st;
  final int t;
  final double largura;

  /// Índice global do 1º item desta trilha no seno ([iniciosDoSeno]); −1 = conta a partir de 0.
  final int inicioSeno;

  /// Até onde o mapa está aberto ([alcanceDoMapa]); o que vem depois parece trancado.
  final PosicaoMapa? alcance;

  /// A cor da etapa ([corDaEtapa]).
  final Color cor;

  /// Quantas palavras novas cada lição apresenta (null = índice ainda não pronto).
  final int Function(Licao licao)? novasDe;

  /// O baú do fim da unidade (null = sem baú) e quantas palavras ele guarda.
  final EstadoBau? bau;
  final int palavrasBau;

  /// O baú pronto balança? Só um no mapa inteiro ([bauQueBalanca]); os outros ficam parados, com brilho.
  final bool bauBalanca;

  /// O id da lição recém-concluída (pop + confete + a estrada enchendo até a próxima).
  final String? celebrar;

  /// Chave do nó atual (para o mapa rolar até ele).
  final GlobalKey? chaveAtual;

  final void Function(int l) onAbrirLicao;
  final void Function(int l) onComecar;
  final VoidCallback? onBau;

  /// 🔁 "Revisão até aqui": um nó logo antes da lição atual desta trilha (null = sem o nó).
  final VoidCallback? onRevisao;

  const CaminhoIngles({
    super.key,
    required this.st,
    required this.t,
    required this.largura,
    required this.cor,
    required this.onAbrirLicao,
    required this.onComecar,
    this.inicioSeno = -1,
    this.alcance,
    this.novasDe,
    this.bau,
    this.palavrasBau = 0,
    this.bauBalanca = true,
    this.celebrar,
    this.chaveAtual,
    this.onBau,
    this.onRevisao,
  });

  // alturas das faixas (estreito / largo)
  static const bandaEstreita = 128.0, bandaLarga = 104.0;
  static const bandaAtualEstreita = 168.0, bandaAtualLarga = 146.0;
  static const bandaBau = 128.0;
  static const bandaRevisao = 120.0;
  static const _topoNo = 10.0;
  static const _topoNoAtual = BolhaComecar.altura + 10;
  static const rotuloMaxEstreito = 150.0;

  bool get _estreito => largura < larguraRotuloAoLado;

  @override
  Widget build(BuildContext context) {
    final trilha = st.trilhas[t];
    final licoes = trilha.licoes;
    final amp = amplitudeDuolingo(largura);
    final centro = largura / 2;
    final base = inicioSeno < 0 ? 0 : inicioSeno;
    double xDe(int i) => centro + offsetSenoidal(base + i) * amp;

    // monta as faixas
    final itens = <_Item>[];
    var y = 0.0;
    for (var l = 0; l < licoes.length; l++) {
      final feita = st.licaoConcluida(t, l);
      final atual = t == st.trilhaIdx && l == st.licaoIdx;
      final estado = estadoDoNo(feita: feita, atual: atual, pos: (t, l), alcance: alcance, propria: trilha.propria);
      final altura = atual
          ? (_estreito ? bandaAtualEstreita : bandaAtualLarga)
          : (_estreito ? bandaEstreita : bandaLarga);
      final topoNo = atual ? _topoNoAtual : _topoNo;
      if (atual && onRevisao != null) {
        // no meio do caminho entre a última feita e a atual
        final x = l == 0 ? xDe(l) : (xDe(l - 1) + xDe(l)) / 2;
        itens.add(_Item(l: _Item.revisao, y: y, altura: bandaRevisao, x: x, cy: y + _topoNo + No3D.tamanho / 2, estado: EstadoNo.feita));
        y += bandaRevisao;
      }
      itens.add(_Item(l: l, y: y, altura: altura, x: xDe(l), cy: y + topoNo + No3D.tamanho / 2, estado: estado, atual: atual));
      y += altura;
    }
    if (bau != null) {
      final xBau = largura < 100 ? centro : xDe(licoes.length).clamp(50.0, largura - 50);
      itens.add(_Item(l: -1, y: y, altura: bandaBau, x: xBau, cy: y + 10 + BauTrilha.altura * .6));
      y += bandaBau;
    }
    final alturaTotal = y + 6;

    final pontos = [for (final it in itens) Offset(it.x, it.cy)];
    final feitos = [
      for (var i = 0; i < itens.length; i++)
        itens[i].l != _Item.bau && itens[i].estado == EstadoNo.feita,
    ];
    final iCelebrar = celebrar == null ? -1 : itens.indexWhere((it) => it.l >= 0 && licoes[it.l].id == celebrar);

    // camada própria: as animações dos nós não repintam a estrada (que tem brilho com blur)
    Widget estrada(double p) => RepaintBoundary(
          child: CustomPaint(
            size: Size(largura, alturaTotal),
            painter: trilhoDaPaleta(
              pontos: pontos,
              feitos: feitos,
              cor: cor,
              indiceUltimo: iCelebrar >= 0 ? iCelebrar : null,
              progressoUltimo: p,
            ),
          ),
        );

    return SizedBox(
      height: alturaTotal,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: iCelebrar >= 0
              ? TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOutCubic,
                  builder: (context, p, _) => estrada(p),
                )
              : estrada(1),
        ),
        for (final it in itens)
          if (it.l >= 0)
            _faixaLicao(context, trilha, it, it.l == (iCelebrar >= 0 ? itens[iCelebrar].l : -2))
          else if (it.l == _Item.revisao)
            _faixaRevisao(it)
          else
            _faixaBau(it),
      ]),
    );
  }

  Widget _faixaLicao(BuildContext context, Trilha trilha, _Item it, bool comemora) {
    final licao = trilha.licoes[it.l];
    final nota = st.quizNotas[st.chave(t, it.l)];
    final feita = it.estado == EstadoNo.feita;
    final novas = feita ? 0 : (novasDe?.call(licao) ?? 0);
    final topoNo = it.cy - it.y - No3D.tamanho / 2;
    void abrir() => onAbrirLicao(it.l);

    final no = No3D(
      emoji: licao.emoji,
      estado: it.estado,
      cor: cor,
      novas: novas,
      celebrar: comemora,
      rotulo: licao.nome,
      estrelas: nota == null ? null : estrelasDaNota(nota),
      onTap: abrir,
    );

    final filhos = <Widget>[];
    final esquerdaNo = it.x - No3D.tamanho / 2;

    // balão "COMEÇAR" em cima do nó atual
    if (it.atual) {
      const larguraBolha = 190.0;
      final esq = (it.x - larguraBolha / 2).clamp(0.0, (largura - larguraBolha).clamp(0.0, double.infinity));
      filhos.add(Positioned(
        top: 4,
        left: esq,
        width: larguraBolha,
        child: Center(
          child: BolhaComecar(
            key: const Key('mapa-comecar'),
            texto: feita ? 'PRATICAR DE NOVO' : 'COMEÇAR',
            cor: cor,
            onTap: () => onComecar(it.l),
          ),
        ),
      ));
    }

    // confete da comemoração, centrado no nó
    if (comemora) {
      filhos.add(Positioned(
        left: it.x - 90,
        top: topoNo - 60,
        width: 180,
        height: 180,
        child: const Confete(quantidade: 22, origem: Alignment(0, -.1), duracao: Duration(milliseconds: 1300)),
      ));
    }

    filhos.add(Positioned(left: esquerdaNo, top: topoNo, child: no));

    final temEstrelas = nota != null;
    if (temEstrelas) {
      final e = EstrelasArco(estrelas: estrelasDaNota(nota));
      filhos.add(Positioned(
        left: it.x - 27,
        top: topoNo + No3D.tamanho + No3D.labio + 2,
        // o nó já anuncia as estrelas ao leitor de tela
        child: ExcludeSemantics(child: GestureDetector(onTap: abrir, child: e)),
      ));
    }

    // rótulo
    final corNome = switch (it.estado) {
      EstadoNo.atual => Mixart.text,
      EstadoNo.feita => Mixart.text,
      EstadoNo.disponivel => Mixart.textMuted,
      EstadoNo.trancada => Mixart.textFaint,
    };
    final estiloNome = Mixart.ui(size: _estreito ? 12.5 : 13.5, weight: it.atual ? FontWeight.w800 : FontWeight.w700, color: corNome);
    if (_estreito) {
      final topo = topoNo + No3D.tamanho + No3D.labio + (temEstrelas ? 22 : 6);
      const w = rotuloMaxEstreito;
      final esq = (it.x - w / 2).clamp(0.0, (largura - w).clamp(0.0, double.infinity));
      filhos.add(Positioned(
        top: topo,
        left: esq,
        width: w,
        child: Center(
          child: GestureDetector(
            onTap: abrir,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(color: Mixart.bg.withValues(alpha: .82), borderRadius: BorderRadius.circular(8)),
              child: Text(licao.nome, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: estiloNome),
            ),
          ),
        ),
      ));
    } else {
      final off = it.x - largura / 2;
      final i = it.l;
      // lado de fora da curva; no centro, o lado oposto ao que o caminho vai
      final proximo = offsetSenoidal((inicioSeno < 0 ? 0 : inicioSeno) + i + 1);
      final direita = off > 1 || (off.abs() <= 1 && proximo < 0);
      const folga = 16.0;
      final ladoLivre = direita ? largura - (it.x + No3D.tamanho / 2) - folga : it.x - No3D.tamanho / 2 - folga;
      final w = ladoLivre.clamp(40.0, 230.0);
      filhos.add(Positioned(
        top: topoNo,
        height: No3D.tamanho,
        left: direita ? it.x + No3D.tamanho / 2 + folga : it.x - No3D.tamanho / 2 - folga - w,
        width: w,
        child: Align(
          alignment: direita ? Alignment.centerLeft : Alignment.centerRight,
          child: GestureDetector(
            onTap: abrir,
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: direita ? CrossAxisAlignment.start : CrossAxisAlignment.end,
              children: [
                Text(licao.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: direita ? TextAlign.left : TextAlign.right,
                    style: estiloNome),
                if (nota != null)
                  Text('$nota/10', style: Mixart.ui(size: 10.5, weight: FontWeight.w700, color: Mixart.textFaint))
                else if (it.estado == EstadoNo.trancada)
                  Text('🔒 mais adiante', style: Mixart.ui(size: 10.5, weight: FontWeight.w600, color: Mixart.textFaint)),
              ],
            ),
          ),
        ),
      ));
    }

    final faixa = Stack(clipBehavior: Clip.none, children: filhos);
    return Positioned(
      key: it.atual ? chaveAtual : null,
      top: it.y,
      left: 0,
      width: largura,
      height: it.altura,
      child: faixa,
    );
  }

  /// 🔁 O nó da revisão: o nome sempre embaixo (cabe em qualquer largura).
  Widget _faixaRevisao(_Item it) {
    const w = 200.0;
    final esq = (it.x - w / 2).clamp(0.0, (largura - w).clamp(0.0, double.infinity));
    return Positioned(
      top: it.y,
      left: 0,
      width: largura,
      height: it.altura,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned(
          left: it.x - No3D.tamanho / 2,
          top: _topoNo,
          child: No3D(
            key: const Key('mapa-revisao'),
            emoji: '🔁',
            estado: EstadoNo.disponivel,
            cor: cor,
            rotulo: 'Revisão até aqui',
            onTap: onRevisao!,
          ),
        ),
        Positioned(
          top: _topoNo + No3D.tamanho + No3D.labio + 4,
          left: esq,
          width: w,
          child: GestureDetector(
            onTap: onRevisao,
            behavior: HitTestBehavior.opaque,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Revisão até aqui',
                  textAlign: TextAlign.center,
                  style: Mixart.ui(size: _estreito ? 12.5 : 13.5, weight: FontWeight.w800, color: cor)),
              Text('10 exercícios · ✍️ 🧩 👂 🎤',
                  textAlign: TextAlign.center,
                  style: Mixart.ui(size: 10.5, weight: FontWeight.w600, color: Mixart.textFaint)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _faixaBau(_Item it) => Positioned(
        top: it.y,
        left: 0,
        width: largura,
        height: it.altura,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            top: 10,
            left: it.x - 70,
            width: 140,
            child: Center(
              child: BauTrilha(
                key: const Key('mapa-bau'),
                estado: bau!,
                palavras: palavrasBau,
                cor: cor,
                balancar: bauBalanca,
                onTap: onBau ?? () {},
              ),
            ),
          ),
        ]),
      );
}

class _Item {
  static const bau = -1, revisao = -2;
  final int l; // ≥ 0 = lição; [bau]; [revisao]
  final double y, altura, x, cy;
  final EstadoNo estado;
  final bool atual;
  _Item({
    required this.l,
    required this.y,
    required this.altura,
    required this.x,
    required this.cy,
    this.estado = EstadoNo.disponivel,
    this.atual = false,
  });
}
