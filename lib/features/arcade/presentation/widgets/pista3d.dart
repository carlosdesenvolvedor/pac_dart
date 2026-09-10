import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';
import 'arcade_ui.dart';
import 'avatares.dart';
import 'cenario.dart';
import 'perspectiva.dart';

/// A pista em PSEUDO-3D: estrada fugindo pro horizonte (asfalto em
/// segmentos, zebras vermelhas e brancas, faixa central), chão do mundo da
/// fase em faixas de profundidade, adereços na beira, largada quadriculada
/// perto e o portal de CHEGADA lá no fundo. Os corredores andam PRA DENTRO
/// da tela, diminuindo com a distância, cada um com sombra no chão.
/// Compartilhada pela Corrida do Código e pelo Rali de Digitação.
class PistaPro extends StatelessWidget {
  final int posJogador, posCpu, pista;
  final int fase;

  /// Chama de turbo sob o jogador (acabou de dar passo dobrado).
  final bool turbo;

  /// Carga do relógio do rival (0 → 1 = prestes a andar): barrinha sob a CPU,
  /// pra ninguém ser pego de surpresa.
  final Animation<double>? cargaCpu;

  const PistaPro({
    super.key,
    required this.posJogador,
    required this.posCpu,
    required this.pista,
    this.fase = 1,
    this.turbo = false,
    this.cargaCpu,
  });

  static const altura = 272.0;

  /// Distância (perspectiva) da largada e da chegada.
  static const dLargada = 1.28;
  static const dChegada = 2.6;

  /// Faixa de cada corredor (meias-larguras da pista): jogador à esquerda.
  static const lateralJogador = -.46;
  static const lateralCpu = .46;

  double _dDe(double pos) => dLargada + (pos / pista).clamp(0, 1) * (dChegada - dLargada);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Mixart.radiusLg),
      child: SizedBox(
        height: altura,
        child: LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          final p = Perspectiva(largura: w, altura: h, horizonte: h * .40, meiaLargura: w * .43);
          final tema = chaoDaFase(fase);

          // quem está mais longe é pintado primeiro (fica atrás)
          final jogador = _Corredor(
            p: p,
            dDe: _dDe,
            pos: posJogador,
            lateral: lateralJogador,
            nome: 'VOCÊ',
            corBadge: Mixart.brand,
            corTexto: Mixart.onBrand,
            avatar: (t) => AvatarPersonagem(tamanho: t),
            chama: turbo,
          );
          final cpu = _Corredor(
            p: p,
            dDe: _dDe,
            pos: posCpu,
            lateral: lateralCpu,
            nome: 'CPU',
            corBadge: const Color(0xE6262B33),
            corTexto: Colors.white,
            avatar: (t) => RoboCpu(tamanho: t),
            carga: cargaCpu,
          );
          final ordem = posCpu >= posJogador ? [cpu, jogador] : [jogador, cpu];

          return Stack(children: [
            // céu e morros do mundo da fase, até o horizonte
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: p.horizonte + 4,
              child: CenarioFase(fase: fase),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _EstradaPainter(p: p, tema: tema, fase: fase)),
            ),
            ...ordem,
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
          ]);
        }),
      ),
    );
  }
}

/// Um corredor na pista: crachá, boneco, sombra (e chama/medidor), posto
/// na perspectiva e animado suavemente entre as casas.
class _Corredor extends StatelessWidget {
  final Perspectiva p;
  final double Function(double pos) dDe;
  final int pos;
  final double lateral;
  final String nome;
  final Color corBadge, corTexto;
  final Widget Function(double tamanho) avatar;
  final bool chama;
  final Animation<double>? carga;

  const _Corredor({
    required this.p,
    required this.dDe,
    required this.pos,
    required this.lateral,
    required this.nome,
    required this.corBadge,
    required this.corTexto,
    required this.avatar,
    this.chama = false,
    this.carga,
  });

  static const _tamBase = 56.0;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: pos.toDouble()),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, posAnim, _) {
        final d = dDe(posAnim);
        final esc = p.escala(d) * PistaPro.dLargada; // 1.0 na largada
        final tam = _tamBase * esc;
        final escBadge = math.max(.78, esc);
        final pe = p.ponto(d, lateral);
        final sombraH = tam * .3;
        final boxW = math.max(tam * 2.6, 90.0);
        final cargaH = carga == null ? 0.0 : 10.0;
        final boxH = 22 * escBadge + 4 + tam + sombraH / 2 + cargaH;
        // o centro da sombra é o ponto do chão
        final top = pe.dy - (boxH - cargaH - sombraH / 2);
        return Positioned(
          left: pe.dx - boxW / 2,
          top: top,
          width: boxW,
          height: boxH,
          child: Stack(alignment: Alignment.topCenter, children: [
            Positioned(
              bottom: cargaH,
              child: Sombra(largura: tam * 1.15, altura: sombraH, opacidade: .42),
            ),
            if (chama)
              Positioned(
                bottom: cargaH + sombraH * .1,
                child: Transform.scale(scale: esc, child: const ChamaTurbo()),
              ),
            Positioned(
              bottom: cargaH + sombraH * .35,
              child: avatar(tam),
            ),
            Positioned(
              bottom: cargaH + sombraH * .35 + tam + 3,
              child: Transform.scale(
                scale: escBadge,
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: corBadge,
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Text(nome,
                      style: TextStyle(
                          color: corTexto,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8)),
                ),
              ),
            ),
            if (carga != null) Positioned(bottom: 0, child: CargaCpu(carga: carga!)),
          ]),
        );
      },
    );
  }
}

/// A estrada e o chão da fase, em perspectiva.
class _EstradaPainter extends CustomPainter {
  final Perspectiva p;
  final TemaChao tema;
  final int fase;
  _EstradaPainter({required this.p, required this.tema, required this.fase});

  static const _segmento = .22;
  static const _ate = 18.0;

  @override
  void paint(Canvas c, Size s) {
    // chão do mundo em faixas de profundidade
    pintarChaoEmFaixas(c, p,
        claro: tema.claro, escuro: tema.escuro, linha: tema.linha, segmento: .3, ate: _ate);

    // asfalto por segmentos (tons alternados dão a sensação de movimento)
    final asfaltoA = const Color(0xFF3B424B);
    final asfaltoB = const Color(0xFF353B44);
    var i = 0;
    for (var d = 1.0; d < _ate; d += _segmento, i++) {
      final d2 = d + _segmento;
      if (p.y(d) - p.y(d2) < .5) break;
      final par = i.isEven;
      c.drawPath(p.faixa(d, d2, -1, 1), Paint()..color = par ? asfaltoA : asfaltoB);
      // zebras vermelhas e brancas
      final zebra = Paint()..color = par ? const Color(0xFFE53935) : Colors.white;
      c.drawPath(p.faixa(d, d2, -1.14, -1), zebra);
      c.drawPath(p.faixa(d, d2, 1, 1.14), zebra);
      // faixa central tracejada
      if (par) {
        c.drawPath(p.faixa(d, d2, -.028, .028), Paint()..color = Colors.white.withValues(alpha: .7));
      }
    }

    // largada (perto) e chegada (longe) quadriculadas
    pintarQuadriculado(c, p, PistaPro.dLargada - .16, -1, 1, profundidade: .1);
    pintarQuadriculado(c, p, PistaPro.dChegada, -1, 1, profundidade: .09);

    // adereços na beira, do mais longe pro mais perto
    for (var d = 11.0; d > 1.05; d -= .85) {
      final k = (d * 7).round();
      _adereco(c, d, k.isEven ? -1.55 : -1.75, k);
      _adereco(c, d, k.isOdd ? 1.55 : 1.75, k + 3);
    }

    // portal de chegada: dois postes + faixa
    _portal(c);

    // neblina do horizonte (profundidade atmosférica)
    pintarNeblina(c, p, tema.neblina, ate: .5);
  }

  void _portal(Canvas c) {
    const d = PistaPro.dChegada;
    final esc = p.escala(d);
    final altura = p.alturaChao * .62 / d;
    final esq = p.ponto(d, -1.2);
    final dir = p.ponto(d, 1.2);
    final poste = Paint()
      ..color = const Color(0xFFE8ECF0)
      ..strokeWidth = math.max(2.5, 5 * esc)
      ..strokeCap = StrokeCap.round;
    c.drawLine(esq, esq - Offset(0, altura), poste);
    c.drawLine(dir, dir - Offset(0, altura), poste);
    final faixa = Rect.fromLTRB(esq.dx, esq.dy - altura, dir.dx, esq.dy - altura + 30 * esc);
    c.drawRRect(
      RRect.fromRectAndRadius(faixa, Radius.circular(3 * esc)),
      Paint()..color = const Color(0xFF10131A),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(faixa, Radius.circular(3 * esc)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Mixart.brand.withValues(alpha: .8),
    );
    pintarTexto(c, '🏁 CHEGADA', faixa.center,
        tamanho: math.max(9, 20 * esc), cor: Mixart.brand, espaco: 1.5);
  }

  /// Árvore, cacto, poste… escalado pela distância.
  void _adereco(Canvas c, double d, double lateral, int semente) {
    final pe = p.ponto(d, lateral);
    if (pe.dx < -40 || pe.dx > p.largura + 40) return;
    final h = p.alturaChao * .42 / d;
    final w = h * .55;
    switch (tema.adereco) {
      case Adereco.arvore:
        c.drawRect(Rect.fromLTWH(pe.dx - w * .08, pe.dy - h * .4, w * .16, h * .4),
            Paint()..color = const Color(0xFF6D4C2F));
        c.drawCircle(Offset(pe.dx, pe.dy - h * .62), w * .5, Paint()..color = const Color(0xFF2F6E33));
        c.drawCircle(Offset(pe.dx - w * .15, pe.dy - h * .72), w * .32,
            Paint()..color = const Color(0xFF4C9A4A));
      case Adereco.pinheiro:
        c.drawRect(Rect.fromLTWH(pe.dx - w * .07, pe.dy - h * .25, w * .14, h * .25),
            Paint()..color = const Color(0xFF5B3B26));
        for (final (base, larg, alt, cor) in [
          (.22, 1.0, .5, const Color(0xFF2F5D46)),
          (.5, .75, .42, const Color(0xFF3C7357)),
          (.74, .5, .3, const Color(0xFFE9F4FA)),
        ]) {
          final tri = Path()
            ..moveTo(pe.dx - w * larg / 2, pe.dy - h * base)
            ..lineTo(pe.dx, pe.dy - h * (base + alt))
            ..lineTo(pe.dx + w * larg / 2, pe.dy - h * base)
            ..close();
          c.drawPath(tri, Paint()..color = cor);
        }
      case Adereco.cacto:
        final tinta = Paint()
          ..color = const Color(0xFF4E8F4A)
          ..strokeWidth = w * .3
          ..strokeCap = StrokeCap.round;
        c.drawLine(pe, pe - Offset(0, h * .95), tinta);
        c.drawLine(pe - Offset(0, h * .5), pe - Offset(w * .4, h * .72), tinta);
        c.drawLine(pe - Offset(0, h * .4), pe - Offset(-w * .4, h * .66), tinta);
      case Adereco.poste:
        c.drawLine(
            pe,
            pe - Offset(0, h),
            Paint()
              ..color = const Color(0xFF8A96A3)
              ..strokeWidth = math.max(1, w * .12));
        c.drawCircle(pe - Offset(0, h), w * .55,
            Paint()
              ..color = const Color(0xFFFFE082).withValues(alpha: .35)
              ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, w * .4));
        c.drawCircle(pe - Offset(0, h), w * .18, Paint()..color = const Color(0xFFFFF3C4));
      case Adereco.rocha:
        c.drawOval(Rect.fromCenter(center: pe - Offset(0, h * .22), width: w * 1.3, height: h * .5),
            Paint()..color = const Color(0xFF2A1613));
        c.drawOval(
            Rect.fromCenter(center: pe - Offset(w * .15, h * .32), width: w * .7, height: h * .22),
            Paint()..color = const Color(0xFF5A3A32));
        if (semente % 3 == 0) {
          c.drawCircle(pe - Offset(0, h * .3), w * .15, Paint()..color = const Color(0xFFFF7043));
        }
      case Adereco.cristal:
        final cor = semente.isEven ? const Color(0xFFB388FF) : const Color(0xFF80DEEA);
        final cristal = Path()
          ..moveTo(pe.dx, pe.dy - h)
          ..lineTo(pe.dx + w * .35, pe.dy - h * .45)
          ..lineTo(pe.dx, pe.dy)
          ..lineTo(pe.dx - w * .35, pe.dy - h * .45)
          ..close();
        c.drawPath(
            cristal,
            Paint()
              ..color = cor.withValues(alpha: .35)
              ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, w * .3));
        c.drawPath(cristal, Paint()..color = cor);
        c.drawLine(Offset(pe.dx, pe.dy - h), Offset(pe.dx, pe.dy),
            Paint()
              ..color = Colors.white.withValues(alpha: .5)
              ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(_EstradaPainter old) =>
      old.fase != fase || old.p.largura != p.largura || old.p.altura != p.altura;
}
