import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/ator_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/fundo_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/moldura_webcam.dart';
import 'package:pac_dart/features/arcade/presentation/historia/palco_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/props_historia.dart';

/// 📺 Grupo A (plano §8.1–8.2): os 5 cenários do dia a dia das lições, os 4 props novos e a moldura de webcam
/// da `videochamada` (opção b do spike: o ator de pé, recortado na cintura).

const _novos = [
  CenarioHistoria.videochamada,
  CenarioHistoria.escritorio,
  CenarioHistoria.casa,
  CenarioHistoria.restaurante,
  CenarioHistoria.loja,
];
const _propsNovos = [PropHistoria.notebook, PropHistoria.prato, PropHistoria.sacola, PropHistoria.documento];

/// Os 3 tamanhos do plano: celular deitado estreito, celular em pé (2 filas) e o monitor largo.
const _tamanhos = [Size(360, 640), Size(390, 844), Size(2560, 1080)];

ui.Picture _grava(void Function(Canvas c) pinta) {
  final rec = ui.PictureRecorder();
  pinta(Canvas(rec));
  return rec.endRecording();
}

Future<Uint8List> _pixels(void Function(Canvas c) pinta, Size s) async {
  final pic = _grava(pinta);
  final img = await pic.toImage(s.width.toInt(), s.height.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  pic.dispose();
  return bytes!.buffer.asUint8List();
}

void _fundo(Canvas c, CenarioHistoria cen, HoraHistoria h, Size s, {double t = 0, double paralaxe = 0}) {
  for (final cam in CamadaFundo.values) {
    FundoHistoriaPainter(cenario: cen, hora: h, camada: cam, t: t, paralaxe: paralaxe).paint(c, s);
  }
}

double _luminancia(Uint8List px) {
  var soma = 0.0;
  for (var i = 0; i < px.length; i += 4) {
    soma += .2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2];
  }
  return soma / (px.length / 4);
}

int _opacos(Uint8List px) {
  var n = 0;
  for (var i = 3; i < px.length; i += 4) {
    if (px[i] > 0) n++;
  }
  return n;
}

/// As medidas do corpo do [AtorHistoria] (frações da altura H, de pé, parado): cabeça = quadrado de .58H no
/// alto; ombros em .495H (±.165H); quadril em .74H; mão parada em (±.205H, .705H).
Rect _cabeca(Rect corpo) => Rect.fromLTWH(corpo.center.dx - corpo.height * .29, corpo.top, corpo.height * .58, corpo.height * .58);
Rect _tronco(Rect corpo) => Rect.fromLTRB(corpo.center.dx - corpo.height * .165, corpo.top + corpo.height * .495,
    corpo.center.dx + corpo.height * .165, corpo.top + corpo.height * .74);

bool _contem(Rect fora, Rect dentro) =>
    fora.left <= dentro.left + 1e-6 &&
    fora.top <= dentro.top + 1e-6 &&
    fora.right >= dentro.right - 1e-6 &&
    fora.bottom >= dentro.bottom - 1e-6;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cenários das lições', () {
    test('são os 5 do fim do enum, todos interiores, com as 4 horas e só chuva/neve (pela janela)', () {
      // a 2ª leva (copa, recepcaoHotel, salaDeEstar) entrou depois destes 5: confere a fatia 25..30
      expect(CenarioHistoria.values.sublist(25, 30), _novos);
      for (final c in _novos) {
        expect(interioresHistoria, contains(c), reason: c.name);
        expect(horasPermitidas(c), HoraHistoria.values.toSet(), reason: c.name);
        for (final h in HoraHistoria.values) {
          for (final cl in ClimaHistoria.values) {
            expect(climaPermitido(cl, c, h), cl == ClimaHistoria.chuva || cl == ClimaHistoria.neve, reason: '${c.name}/${cl.name}');
          }
        }
        final chao = FundoHistoriaPainter.linhaDoChao(c);
        expect(chao, inInclusiveRange(.6, .9), reason: c.name);
        expect(FundoHistoriaPainter.horizonte(c), lessThan(chao - .1), reason: c.name);
      }
    });

    test('5 cenários × 4 horas × 3 camadas × t × paralaxe pintam sem exceção em 360×640, 390×844 e 2560×1080', () {
      for (final s in _tamanhos) {
        for (final c in _novos) {
          for (final h in HoraHistoria.values) {
            for (final cam in CamadaFundo.values) {
              for (final (t, par) in [(0.0, 0.0), (2.3, .37), (9.1, -1.6)]) {
                _grava((cv) => FundoHistoriaPainter(cenario: c, hora: h, camada: cam, t: t, paralaxe: par).paint(cv, s))
                    .dispose();
              }
            }
          }
        }
      }
    });

    testWidgets('as 3 camadas empilhadas em CustomPaint, nos 3 tamanhos e nas 4 horas, sem exceção', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final s in _tamanhos) {
        tester.view.physicalSize = s;
        for (final c in _novos) {
          for (final h in HoraHistoria.values) {
            await tester.pumpWidget(Stack(textDirection: TextDirection.ltr, children: [
              for (final cam in CamadaFundo.values)
                Positioned.fill(
                  child: RepaintBoundary(
                      child: CustomPaint(painter: FundoHistoriaPainter(cenario: c, hora: h, camada: cam, t: 1.5, paralaxe: .25))),
                ),
            ]));
            expect(tester.takeException(), isNull, reason: '${c.name}/${h.name} em $s');
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    });

    test('a hora muda a pintura: as 4 horas são diferentes e a noite é bem mais escura que o dia (no celular em pé também)',
        () async {
      for (final s in [const Size(80, 60), const Size(39, 84)]) {
        for (final c in _novos) {
          final lum = <HoraHistoria, double>{};
          final vistos = <int>{};
          for (final h in HoraHistoria.values) {
            final px = await _pixels((cv) => _fundo(cv, c, h, s), s);
            lum[h] = _luminancia(px);
            vistos.add(Object.hashAll(px));
          }
          expect(vistos.length, 4, reason: '${c.name} em $s: horas iguais');
          expect(lum[HoraHistoria.noite]!, lessThan(lum[HoraHistoria.dia]! - 15), reason: '${c.name} em $s');
        }
      }
    });

    test('os 5 são pinturas diferentes entre si e dos 25 do Turismo, de dia e de noite (64×40)', () async {
      const s = Size(64, 40);
      for (final h in [HoraHistoria.dia, HoraHistoria.noite]) {
        final vistos = <int, CenarioHistoria>{};
        for (final c in CenarioHistoria.values) {
          if (!horasPermitidas(c).contains(h)) continue;
          final px = await _pixels((cv) {
            FundoHistoriaPainter(cenario: c, hora: h, camada: CamadaFundo.distante).paint(cv, s);
            FundoHistoriaPainter(cenario: c, hora: h, camada: CamadaFundo.chao).paint(cv, s);
          }, s);
          final chave = Object.hashAll(px);
          expect(vistos[chave], isNull, reason: '${c.name} igual a ${vistos[chave]?.name} (${h.name})');
          vistos[chave] = c;
        }
      }
    });

    test('o chão cobre da linha do chão para baixo e a parede (distante) cobre até o horizonte, nos 3 tamanhos', () async {
      for (final s0 in _tamanhos) {
        final s = Size((s0.width / 8).roundToDouble(), (s0.height / 8).roundToDouble());
        final w = s.width.toInt();
        for (final c in _novos) {
          final chao = await _pixels(
              (cv) => FundoHistoriaPainter(cenario: c, hora: HoraHistoria.tarde, camada: CamadaFundo.chao, paralaxe: .2)
                  .paint(cv, s),
              s);
          for (var y = (s.height * FundoHistoriaPainter.linhaDoChao(c)).ceil(); y < s.height; y++) {
            for (var x = 0; x < w; x++) {
              expect(chao[(y * w + x) * 4 + 3], 255, reason: '${c.name} em $s: ($x,$y) sem chão');
            }
          }
          if (c == CenarioHistoria.videochamada) {
            // a tela do app é opaca de ponta a ponta (sem janela para o céu)
            final longe = await _pixels(
                (cv) => FundoHistoriaPainter(cenario: c, hora: HoraHistoria.dia, camada: CamadaFundo.distante).paint(cv, s), s);
            final ate = (s.height * FundoHistoriaPainter.horizonte(c)).floor();
            for (var y = 0; y < ate; y++) {
              for (var x = 0; x < w; x++) {
                expect(longe[(y * w + x) * 4 + 3], 255, reason: 'videochamada em $s: ($x,$y) vazado');
              }
            }
          }
        }
      }
    });

    test('videochamada: o fundo é só a tela do app (nenhum quadro de participante pintado no meio)', () async {
      for (final s in [const Size(640, 360), const Size(195, 422)]) {
        for (final h in HoraHistoria.values) {
          final px = await _pixels((cv) => _fundo(cv, CenarioHistoria.videochamada, h, s), s);
          final w = s.width.toInt();
          final u = s.height / 100;
          // a faixa do meio (abaixo da barra de cima e acima da linha do chão) só tem o fundo do tema, as linhas da
          // grade e a mistura dos dois (antialias); nenhum retângulo de "participante" (eles são as molduras do palco)
          final y0 = (9 * u).ceil(), y1 = (s.height * FundoHistoriaPainter.linhaDoChao(CenarioHistoria.videochamada)).floor();
          final contagem = <int, int>{};
          for (var y = y0; y < y1; y++) {
            for (var x = 0; x < w; x++) {
              final i = (y * w + x) * 4;
              final cor = px[i] << 16 | px[i + 1] << 8 | px[i + 2];
              contagem[cor] = (contagem[cor] ?? 0) + 1;
            }
          }
          final top = contagem.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          List<double> rgb(int c) => [(c >> 16 & 255).toDouble(), (c >> 8 & 255).toDouble(), (c & 255).toDouble()];
          final fundo = rgb(top[0].key), linha = rgb(top.length > 1 ? top[1].key : top[0].key);
          var naGrade = 0, total = 0;
          for (final e in contagem.entries) {
            final c = rgb(e.key);
            // distância de c à semirreta fundo → linha (a 2ª cor mais comum já é uma mistura; a linha pura fica além)
            final d = [for (var k = 0; k < 3; k++) linha[k] - fundo[k]];
            final dd = d.fold(0.0, (a, v) => a + v * v);
            final t = dd == 0 ? 0.0 : ([for (var k = 0; k < 3; k++) (c[k] - fundo[k]) * d[k]].fold(0.0, (a, v) => a + v) / dd).clamp(0.0, 4.0);
            final dist = math.sqrt([for (var k = 0; k < 3; k++) math.pow(c[k] - fundo[k] - t * d[k], 2)].fold(0.0, (a, v) => a + v));
            if (dist < 10) naGrade += e.value;
            total += e.value;
          }
          expect(naGrade / total, greaterThan(.98), reason: '${h.name} em $s: algo além da grade no meio da tela');
          var claros = 0;
          for (var i = 0; i < px.length; i += 4) {
            if (.2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2] > 200) claros++;
          }
          expect(claros / (px.length / 4), lessThan(.03), reason: '${h.name} em $s: área clara demais (quadros?)');
        }
      }
    });

    test('paralaxe sem emenda também no celular em pé (meia volta = a pintura deslocada meia tela)', () async {
      const s = Size(98, 212);
      final w = s.width.toInt(), meia = w ~/ 2;
      for (final c in _novos) {
        for (final cam in CamadaFundo.values) {
          final volta = .5 / FundoHistoriaPainter.fatorParalaxe(cam);
          final a = await _pixels(
              (cv) => FundoHistoriaPainter(cenario: c, hora: HoraHistoria.noite, camada: cam, t: 1).paint(cv, s), s);
          final b = await _pixels(
              (cv) => FundoHistoriaPainter(cenario: c, hora: HoraHistoria.noite, camada: cam, t: 1, paralaxe: volta).paint(cv, s),
              s);
          var diferentes = 0;
          for (var y = 0; y < s.height; y++) {
            for (var x = 0; x < w; x++) {
              final ia = (y * w + (x + meia) % w) * 4, ib = (y * w + x) * 4;
              var d = 0;
              for (var k = 0; k < 4; k++) {
                d = math.max(d, (a[ia + k] - b[ib + k]).abs());
              }
              if (d > 24) diferentes++;
            }
          }
          expect(diferentes, lessThan(w * s.height * .004), reason: '${c.name}/${cam.name}');
        }
      }
    });

    test('determinístico: a mesma entrada pinta os mesmos pixels', () async {
      const s = Size(160, 90);
      for (final c in _novos) {
        final a = await _pixels((cv) => _fundo(cv, c, HoraHistoria.tarde, s, t: 3.3, paralaxe: .2), s);
        final b = await _pixels((cv) => _fundo(cv, c, HoraHistoria.tarde, s, t: 3.3, paralaxe: .2), s);
        expect(a, b, reason: c.name);
      }
    });
  });

  group('props das lições', () {
    test('os 4 são os do fim do enum e têm tamanho coerente (cabem na mão: ≤ .3 da altura)', () {
      // a 2ª leva de props entrou depois destes 4: confere a fatia 24..28
      expect(PropHistoria.values.sublist(24, 28), _propsNovos);
      for (final p in _propsNovos) {
        final s = PropPainter.tamanho(p, 200);
        expect(s.width, greaterThan(10), reason: p.name);
        expect(s.height, greaterThan(10), reason: p.name);
        final mao = AtorHistoria.tamanhoNaMao(p, 200);
        expect(math.max(mao.width, mao.height), lessThanOrEqualTo(60.0001), reason: p.name);
      }
    });

    test('cada um desenha algo de verdade (≥ 25% da caixa pintada) em 3 escalas, e cada um é diferente', () async {
      final vistos = <int, PropHistoria>{};
      for (final p in _propsNovos) {
        for (final alt in [84.0, 200.0, 420.0]) {
          final s = PropPainter.tamanho(p, alt);
          final caixa = Size(s.width.ceilToDouble(), s.height.ceilToDouble());
          final px = await _pixels((cv) => PropPainter(prop: p, t: 1).paint(cv, caixa), caixa);
          expect(_opacos(px) / (caixa.width * caixa.height), greaterThan(.25), reason: '${p.name} a $alt');
          if (alt == 200) {
            final chave = Object.hashAll(px);
            expect(vistos[chave], isNull, reason: '${p.name} igual a ${vistos[chave]?.name}');
            vistos[chave] = p;
          }
        }
        // caixas tortas e tamanho zero não quebram
        for (final s in [Size.zero, const Size(1, 300), const Size(300, 1), const Size(37, 11)]) {
          _grava((cv) => PropPainter(prop: p).paint(cv, s)).dispose();
        }
      }
    });

    testWidgets('na mão de um ator (parado, acenando, escrevendo) em 3 alturas, sem exceção', (tester) async {
      for (final p in _propsNovos) {
        for (final alt in [84.0, 200.0, 420.0]) {
          for (final acao in [AcaoAtor.parado, AcaoAtor.acena, AcaoAtor.escreve]) {
            await tester.pumpWidget(Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: AtorHistoria.largura(alt),
                  height: alt,
                  child: AtorHistoria(
                    aparencia: ElencoTurismo.de('voce')!,
                    altura: alt,
                    pose: PoseAtor(acao: acao, progresso: .5),
                    segura: p,
                  ),
                ),
              ),
            ));
            expect(tester.takeException(), isNull, reason: '${p.name} a $alt (${acao.name})');
            expect(
                find.byWidgetPredicate((w) => w is CustomPaint && w.painter is PropPainter && (w.painter! as PropPainter).prop == p),
                findsOneWidget,
                reason: '${p.name} sumiu da mão');
          }
        }
      }
    });
  });

  group('moldura de webcam (videochamada)', () {
    /// As molduras das 5 posições de [s] com todas ocupadas: (corpo, moldura com a largura máxima .92 × vizinho).
    List<(Rect, Rect)> molduras(Size s, {required bool comLimite}) {
      final xs = [for (final f in PalcoHistoria.xsDo(s)) f * s.width];
      final chao = s.height * FundoHistoriaPainter.linhaDoChao(CenarioHistoria.videochamada);
      final h = PalcoHistoria.alturaDosAtores(s, xs);
      final w = AtorHistoria.largura(h);
      var menor = double.infinity;
      for (var i = 1; i < xs.length; i++) {
        menor = math.min(menor, xs[i] - xs[i - 1]);
      }
      // no retrato a 2ª fila (posições ímpares) sobe, como no palco
      final recuo = PalcoHistoria.retrato(s)
          ? math.min(h * PalcoHistoria.recuoFila,
              s.height * (FundoHistoriaPainter.linhaDoChao(CenarioHistoria.videochamada) -
                      FundoHistoriaPainter.horizonte(CenarioHistoria.videochamada)) *
                  .6)
          : 0.0;
      return [
        for (var i = 0; i < xs.length; i++)
          () {
            final pe = chao - (i.isOdd ? recuo : 0);
            final corpo = Rect.fromLTWH(xs[i] - w / 2, pe - h, w, h);
            return (corpo, MolduraWebcamPainter.molduraDe(corpo, larguraMaxima: comLimite ? .92 * menor : null));
          }(),
      ];
    }

    test('molduraDe contém a cabeça, o tronco e a mão parada, com folga em cima, nas 5 posições dos 3 layouts', () {
      for (final s in _tamanhos) {
        for (final comLimite in [false, true]) {
          for (final (corpo, m) in molduras(s, comLimite: comLimite)) {
            final h = corpo.height;
            final ctx = '$s x=${corpo.center.dx.round()} limite=$comLimite';
            expect(_contem(m, _cabeca(corpo)), isTrue, reason: 'cabeça fora: $ctx');
            expect(_contem(m, _tronco(corpo)), isTrue, reason: 'tronco fora: $ctx');
            for (final mao in [AtorHistoria.mao(h), AtorHistoria.mao(h, direita: false)]) {
              expect(m.contains(corpo.topLeft + mao), isTrue, reason: 'mão fora: $ctx');
            }
            expect(corpo.top - m.top, greaterThanOrEqualTo(h * .15 - 1e-6), reason: 'sem folga em cima: $ctx');
            expect(m.top, greaterThanOrEqualTo(0), reason: 'passa do topo do palco: $ctx');
            // recorta na cintura: as pernas ficam de fora
            expect(m.bottom, lessThan(corpo.bottom - h * .1), reason: 'não recorta: $ctx');
            expect(m.center.dx, closeTo(corpo.center.dx, 1e-6), reason: ctx);
          }
        }
      }
    });

    test('com a largura máxima (.92 × menor distância), molduras vizinhas não se encostam (fila da frente e de trás)', () {
      for (final s in _tamanhos) {
        final ms = molduras(s, comLimite: true);
        for (var i = 0; i < ms.length; i++) {
          for (var j = i + 1; j < ms.length; j++) {
            final (a, b) = (ms[i].$2, ms[j].$2);
            final mesmaFila = (a.top - b.top).abs() < 1;
            if (mesmaFila) expect(a.overlaps(b), isFalse, reason: '$s: $i × $j');
          }
          if (i > 0 && !PalcoHistoria.retrato(s)) {
            expect(ms[i].$2.left, greaterThanOrEqualTo(ms[i - 1].$2.right - 1e-6), reason: '$s: $i encosta em ${i - 1}');
          }
        }
      }
    });

    test('molduraDe: sem vizinho é 1,3× o corpo; limite menor que o corpo é ignorado; infinito é ignorado', () {
      const corpo = Rect.fromLTWH(100, 200, 62, 100);
      expect(MolduraWebcamPainter.molduraDe(corpo).width, closeTo(62 * 1.3, 1e-9));
      expect(MolduraWebcamPainter.molduraDe(corpo, larguraMaxima: 70).width, closeTo(70, 1e-9));
      expect(MolduraWebcamPainter.molduraDe(corpo, larguraMaxima: 10).width, closeTo(62, 1e-9));
      expect(MolduraWebcamPainter.molduraDe(corpo, larguraMaxima: double.infinity).width, closeTo(62 * 1.3, 1e-9));
      final m = MolduraWebcamPainter.molduraDe(corpo);
      expect(m.top, closeTo(200 - 15, 1e-9));
      expect(m.bottom, closeTo(200 + 80, 1e-9));
    });

    test('acesa ≠ apagada; as 4 paredes são diferentes; a noite é mais escura; "falando" e as iniciais mudam o desenho',
        () async {
      const s = Size(120, 110);
      Future<Uint8List> px(MolduraWebcamPainter m) => _pixels((cv) => m.paint(cv, s), s);
      final paredes = <int>{};
      for (var i = 0; i < MolduraWebcamPainter.paredes; i++) {
        final acesa = await px(MolduraWebcamPainter(indice: i, acesa: true, hora: HoraHistoria.dia));
        final apagada = await px(MolduraWebcamPainter(indice: i, acesa: false, hora: HoraHistoria.dia));
        expect(acesa, isNot(equals(apagada)), reason: 'parede $i');
        expect(_luminancia(acesa), greaterThan(_luminancia(apagada) + 40), reason: 'parede $i: a apagada não é escura');
        paredes.add(Object.hashAll(acesa));
        final horas = <int>{};
        final lum = <HoraHistoria, double>{};
        for (final h in HoraHistoria.values) {
          final p = await px(MolduraWebcamPainter(indice: i, acesa: true, hora: h));
          horas.add(Object.hashAll(p));
          lum[h] = _luminancia(p);
        }
        expect(horas.length, 4, reason: 'parede $i: horas iguais');
        expect(lum[HoraHistoria.noite]!, lessThan(lum[HoraHistoria.dia]! - 10), reason: 'parede $i');
        expect(await px(MolduraWebcamPainter(indice: i, acesa: true, hora: HoraHistoria.dia, falando: true)),
            isNot(equals(acesa)), reason: 'parede $i: falando');
      }
      expect(paredes.length, MolduraWebcamPainter.paredes);
      // o índice vem de um hash: negativo e enorme também servem
      expect(await px(MolduraWebcamPainter(indice: -3, acesa: true, hora: HoraHistoria.dia)),
          await px(MolduraWebcamPainter(indice: 1, acesa: true, hora: HoraHistoria.dia)));
      expect(await px(MolduraWebcamPainter(indice: 1 << 40, acesa: true, hora: HoraHistoria.dia)),
          await px(MolduraWebcamPainter(indice: 0, acesa: true, hora: HoraHistoria.dia)));
      final semIni = await px(MolduraWebcamPainter(indice: 0, acesa: false, hora: HoraHistoria.dia));
      final comIni = await px(MolduraWebcamPainter(indice: 0, acesa: false, hora: HoraHistoria.dia, iniciais: 'An'));
      expect(comIni, isNot(equals(semIni)));
    });

    test('tamanhos estranhos não quebram e shouldRepaint só quando algo muda', () {
      for (final s in [Size.zero, const Size(1, 1), const Size(3, 400), const Size(400, 3), const Size(2560, 1080)]) {
        for (final acesa in [true, false]) {
          _grava((cv) => MolduraWebcamPainter(indice: 2, acesa: acesa, hora: HoraHistoria.noite, iniciais: 'XY', falando: true)
              .paint(cv, s)).dispose();
        }
      }
      final base = MolduraWebcamPainter(indice: 1, acesa: true, hora: HoraHistoria.dia);
      expect(base.shouldRepaint(MolduraWebcamPainter(indice: 1, acesa: true, hora: HoraHistoria.dia)), isFalse);
      expect(base.shouldRepaint(MolduraWebcamPainter(indice: 2, acesa: true, hora: HoraHistoria.dia)), isTrue);
      expect(base.shouldRepaint(MolduraWebcamPainter(indice: 1, acesa: false, hora: HoraHistoria.dia)), isTrue);
      expect(base.shouldRepaint(MolduraWebcamPainter(indice: 1, acesa: true, hora: HoraHistoria.noite)), isTrue);
      expect(base.shouldRepaint(MolduraWebcamPainter(indice: 1, acesa: true, hora: HoraHistoria.dia, falando: true)), isTrue);
      expect(base.shouldRepaint(MolduraWebcamPainter(indice: 1, acesa: true, hora: HoraHistoria.dia, iniciais: 'A')), isTrue);
    });

    testWidgets('moldura + ator recortado (ClipRRect) na videochamada, nos 3 tamanhos, sem exceção', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final s in _tamanhos) {
        tester.view.physicalSize = s;
        final ms = molduras(s, comLimite: true);
        const quem = ['voce', 'mike', 'sarah', 'ana', 'ben'];
        await tester.pumpWidget(Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(children: [
            for (final cam in CamadaFundo.values)
              Positioned.fill(
                child: CustomPaint(
                    painter: FundoHistoriaPainter(cenario: CenarioHistoria.videochamada, hora: HoraHistoria.noite, camada: cam)),
              ),
            for (var i = 0; i < ms.length; i++) ...[
              Positioned.fromRect(
                rect: ms[i].$2,
                child: CustomPaint(
                    painter: MolduraWebcamPainter(indice: i, acesa: i != 3, hora: HoraHistoria.noite, iniciais: 'A', falando: i == 1)),
              ),
              if (i != 3)
                Positioned.fromRect(
                  rect: ms[i].$2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(MolduraWebcamPainter.raioDe(ms[i].$2.size)),
                    child: OverflowBox(
                      alignment: Alignment.topLeft,
                      minWidth: ms[i].$1.width,
                      maxWidth: ms[i].$1.width,
                      minHeight: ms[i].$1.height,
                      maxHeight: ms[i].$1.height,
                      child: Transform.translate(
                        offset: ms[i].$1.topLeft - ms[i].$2.topLeft,
                        child: AtorHistoria(
                          aparencia: ElencoTurismo.de(quem[i])!,
                          altura: ms[i].$1.height,
                          pose: const PoseAtor(acao: AcaoAtor.acena, progresso: .4),
                          segura: _propsNovos[i % 4],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ]),
        ));
        expect(tester.takeException(), isNull, reason: '$s');
      }
      await tester.pumpWidget(const SizedBox());
    });
  });
}
