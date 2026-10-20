import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/mixart.dart';

/// Curva por segmento → radianos (o mesmo valor do JS: `CURVA_RAD`).
const curvaRad = 0.028;

/// O traçado da pista no plano (metros), ponto a ponto por segmento —
/// a MESMA integração do JS (`construirCentro`), pra que o minimapa e a
/// cena 3D concordem: x pra direita, y "pra frente" (norte).
List<Offset> tracadoDaPista(List<double> curvas, {double comprimento = 8}) {
  final pontos = <Offset>[];
  var x = 0.0, z = 0.0, h = 0.0;
  for (final c in curvas) {
    pontos.add(Offset(x, -z));
    h += c * curvaRad;
    x += math.sin(h) * comprimento;
    z -= math.cos(h) * comprimento;
  }
  pontos.add(Offset(x, -z));
  return pontos;
}

/// 🗺️ Minimapa: a forma da pista com a largada, a chegada e o carro.
class Minimapa extends StatelessWidget {
  final List<Offset> tracado;
  final double posicao;
  final double comprimentoSegmento;
  final double tamanho;
  const Minimapa({
    super.key,
    required this.tracado,
    required this.posicao,
    this.comprimentoSegmento = 8,
    this.tamanho = 112,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'minimapa da pista',
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          color: const Color(0xCC10131A),
          borderRadius: BorderRadius.circular(Mixart.radiusMd),
          border: Border.all(color: Colors.white.withValues(alpha: .12)),
        ),
        // camada própria: o limite de 4 m do shouldRepaint vale de verdade
        // (sem ela, cada rebuild do HUD ao lado regravava o minimapa)
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _PintorMinimapa(tracado, posicao / comprimentoSegmento, Mixart.brand),
          ),
        ),
      ),
    );
  }
}

/// O que não muda durante a corrida, calculado UMA vez por (traçado,
/// tamanho): os pontos já em coordenadas de tela e o traçado de fundo
/// gravado numa Picture. O trecho percorrido cresce aos poucos (só os
/// pontos novos entram no Path) — antes, cada repaint varria a pista
/// inteira (até ~1.500 pontos) duas vezes.
class _GeometriaMinimapa {
  final List<Offset> tracado;
  final Size size;
  final double escala, dx, dy;
  final List<Offset> pontos;
  final ui.Picture fundo;
  final Path feito;
  int feitoAte = 0;

  _GeometriaMinimapa._(this.tracado, this.size, this.escala, this.dx, this.dy, this.pontos, this.fundo)
      : feito = Path()..moveTo(pontos.first.dx, pontos.first.dy);

  Offset tela(Offset p) => Offset(p.dx * escala + dx, dy - p.dy * escala);

  static _GeometriaMinimapa? _ultima;

  static _GeometriaMinimapa para(List<Offset> tracado, Size size) {
    final u = _ultima;
    if (u != null && identical(u.tracado, tracado) && u.size == size && u.pontos.length == tracado.length) {
      return u;
    }
    var minX = double.infinity, maxX = -double.infinity, minY = double.infinity, maxY = -double.infinity;
    for (final p in tracado) {
      minX = math.min(minX, p.dx);
      maxX = math.max(maxX, p.dx);
      minY = math.min(minY, p.dy);
      maxY = math.max(maxY, p.dy);
    }
    const margem = 12.0;
    final escala = math.min(
      (size.width - margem * 2) / math.max(1, maxX - minX),
      (size.height - margem * 2) / math.max(1, maxY - minY),
    );
    final dx = (size.width - (maxX - minX) * escala) / 2 - minX * escala;
    final dy = (size.height - (maxY - minY) * escala) / 2 + maxY * escala;
    final pontos = [for (final p in tracado) Offset(p.dx * escala + dx, dy - p.dy * escala)];

    final caminho = Path()..moveTo(pontos.first.dx, pontos.first.dy);
    for (final p in pontos.skip(1)) {
      caminho.lineTo(p.dx, p.dy);
    }
    final gravador = ui.PictureRecorder();
    Canvas(gravador).drawPath(
      caminho,
      Paint()
        ..color = Colors.white.withValues(alpha: .28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    u?.fundo.dispose();
    return _ultima = _GeometriaMinimapa._(tracado, size, escala, dx, dy, pontos, gravador.endRecording());
  }

  /// O Path do trecho percorrido até o ponto [ate] (só cresce; se voltou —
  /// corrida nova no mesmo traçado — recomeça).
  Path trechoPercorrido(int ate) {
    if (ate < feitoAte) {
      feito
        ..reset()
        ..moveTo(pontos.first.dx, pontos.first.dy);
      feitoAte = 0;
    }
    for (var i = feitoAte + 1; i <= ate && i < pontos.length; i++) {
      feito.lineTo(pontos[i].dx, pontos[i].dy);
    }
    if (ate > feitoAte) feitoAte = math.min(ate, pontos.length - 1);
    return feito;
  }
}

class _PintorMinimapa extends CustomPainter {
  final List<Offset> tracado;
  final double indice;
  final Color cor;
  _PintorMinimapa(this.tracado, this.indice, this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    if (tracado.length < 2) return;
    final g = _GeometriaMinimapa.para(tracado, size);
    final pontos = g.pontos;
    canvas.drawPicture(g.fundo);
    // o trecho já percorrido acende
    final ate = indice.clamp(0, tracado.length - 1.0);
    final feito = g.trechoPercorrido(ate.floor());
    canvas.drawPath(
      feito,
      Paint()
        ..color = cor.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // chegada (quadradinho xadrez) e largada
    final fim = pontos.last;
    canvas.drawRect(Rect.fromCenter(center: fim, width: 7, height: 7), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromCenter(center: fim, width: 3.5, height: 3.5), Paint()..color = Colors.black);
    canvas.drawCircle(pontos.first, 2.5, Paint()..color = Colors.white54);
    // o carro
    final i = ate.floor();
    final t = ate - i;
    final a = tracado[i], b = tracado[math.min(i + 1, tracado.length - 1)];
    final carro = g.tela(Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t));
    canvas.drawCircle(carro, 6, Paint()..color = cor.withValues(alpha: .35));
    canvas.drawCircle(carro, 3.4, Paint()..color = cor);
  }

  @override
  bool shouldRepaint(covariant _PintorMinimapa old) =>
      (old.indice - indice).abs() >= 0.5 || old.tracado != tracado; // meio segmento = 4 m
}
