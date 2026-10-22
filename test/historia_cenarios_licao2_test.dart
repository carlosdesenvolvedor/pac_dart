import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/ator_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/fundo_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/props_historia.dart';

/// 📺 A 2ª leva de arte das lições (os pedidos dos lotes, `planejamento/historias-licoes/PEDIDOS-DE-ARTE.md`):
/// 3 cenários (copa do escritório, recepção do hotel, sala de estar com TV) e 7 props (telão, quadro branco,
/// caixa, bolo, caderno, casaco, taça), no fim dos enums.

const _novos = [CenarioHistoria.copa, CenarioHistoria.recepcaoHotel, CenarioHistoria.salaDeEstar];
const _propsNovos = [
  PropHistoria.telao,
  PropHistoria.quadroBranco,
  PropHistoria.caixa,
  PropHistoria.bolo,
  PropHistoria.caderno,
  PropHistoria.casaco,
  PropHistoria.taca,
];

/// Celular deitado estreito, celular em pé (2 filas), a página no celular em pé e o monitor largo.
const _tamanhos = [Size(360, 640), Size(390, 844), Size(390, 300), Size(2560, 1080)];

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

/// Fração dos pixels que mudam (> 24 num canal) entre a pintura e ela mesma deslocada [dx] colunas.
double _diferencaDeslocada(Uint8List px, int w, int h, int dx) {
  var dif = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final a = (y * w + x) * 4, b = (y * w + (x + dx) % w) * 4;
      var d = 0;
      for (var k = 0; k < 3; k++) {
        d = math.max(d, (px[a + k] - px[b + k]).abs());
      }
      if (d > 24) dif++;
    }
  }
  return dif / (w * h);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('cenários da 2ª leva', () {
    test('são os 3 do fim do enum (depois dos 5 do 📺), interiores, com as 4 horas e só chuva/neve (pela janela)', () {
      // a 3ª leva (dentroDoCarro, cozinha, quintal, bar) entrou depois destes 3: confere a fatia 30..33
      expect(CenarioHistoria.values.sublist(30, 33), _novos);
      expect(CenarioHistoria.values.indexOf(CenarioHistoria.loja), 29, reason: 'a ordem de antes não muda');
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

    test('3 cenários × 4 horas × 3 camadas × t × paralaxe pintam sem exceção nos 4 tamanhos', () {
      for (final s in [..._tamanhos, const Size(1, 1), const Size(3, 400), const Size(400, 3)]) {
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

    test('a hora muda a pintura: as 4 horas são diferentes e a noite é bem mais escura que o dia', () async {
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

    test('o chão cobre da linha do chão para baixo, nos 4 tamanhos', () async {
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
        }
      }
    });

    test('um cômodo só na tela larga: a parede não se repete em meia tela nem em um terço (como a casa e a loja)',
        () async {
      for (final s in [const Size(640, 270), const Size(320, 180)]) {
        final w = s.width.toInt(), h = s.height.toInt();
        for (final c in _novos) {
          final px = await _pixels(
              (cv) => FundoHistoriaPainter(cenario: c, hora: HoraHistoria.dia, camada: CamadaFundo.distante).paint(cv, s), s);
          for (final passo in [w ~/ 2, w ~/ 3]) {
            expect(_diferencaDeslocada(px, w, h, passo), greaterThan(.12), reason: '${c.name} em $s repete a cada $passo px');
          }
        }
      }
    });

    test('paralaxe sem emenda (meia volta = a pintura deslocada meia tela)', () async {
      for (final s in [const Size(98, 212), const Size(256, 108)]) {
        final w = s.width.toInt(), meia = w ~/ 2;
        for (final c in _novos) {
          for (final cam in CamadaFundo.values) {
            final volta = .5 / FundoHistoriaPainter.fatorParalaxe(cam);
            final a = await _pixels(
                (cv) => FundoHistoriaPainter(cenario: c, hora: HoraHistoria.noite, camada: cam, t: 1).paint(cv, s), s);
            final b = await _pixels(
                (cv) => FundoHistoriaPainter(cenario: c, hora: HoraHistoria.noite, camada: cam, t: 1, paralaxe: volta)
                    .paint(cv, s),
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
            expect(diferentes, lessThan(w * s.height * .004), reason: '${c.name}/${cam.name} em $s');
          }
        }
      }
    });

    test('determinístico e diferente dos outros 30 cenários (de dia e de noite, 64×40)', () async {
      const s = Size(160, 90);
      for (final c in _novos) {
        final a = await _pixels((cv) => _fundo(cv, c, HoraHistoria.tarde, s, t: 3.3, paralaxe: .2), s);
        final b = await _pixels((cv) => _fundo(cv, c, HoraHistoria.tarde, s, t: 3.3, paralaxe: .2), s);
        expect(a, b, reason: c.name);
      }
      const p = Size(64, 40);
      for (final h in [HoraHistoria.dia, HoraHistoria.noite]) {
        final vistos = <int, CenarioHistoria>{};
        for (final c in CenarioHistoria.values) {
          if (!horasPermitidas(c).contains(h)) continue;
          final px = await _pixels((cv) {
            FundoHistoriaPainter(cenario: c, hora: h, camada: CamadaFundo.distante).paint(cv, p);
            FundoHistoriaPainter(cenario: c, hora: h, camada: CamadaFundo.chao).paint(cv, p);
          }, p);
          final chave = Object.hashAll(px);
          expect(vistos[chave], isNull, reason: '${c.name} igual a ${vistos[chave]?.name} (${h.name})');
          vistos[chave] = c;
        }
      }
    });

    testWidgets('as 3 camadas empilhadas em CustomPaint, nos 4 tamanhos e nas 4 horas, sem exceção', (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final s in _tamanhos) {
        tester.view.physicalSize = s;
        for (final c in _novos) {
          for (final h in HoraHistoria.values) {
            await tester.pumpWidget(Stack(textDirection: TextDirection.ltr, children: [
              for (final cam in CamadaFundo.values)
                Positioned.fill(
                  child: CustomPaint(painter: FundoHistoriaPainter(cenario: c, hora: h, camada: cam, t: 1.5, paralaxe: .25)),
                ),
            ]));
            expect(tester.takeException(), isNull, reason: '${c.name}/${h.name} em $s');
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  });

  group('props da 2ª leva', () {
    test('os 7 são os do fim do enum (depois dos 4 do 📺) e cabem na mão (≤ .3 da altura)', () {
      // a 3ª leva de props entrou depois destes 7: confere a fatia 28..35
      expect(PropHistoria.values.sublist(28, 35), _propsNovos);
      expect(PropHistoria.values.indexOf(PropHistoria.documento), 27, reason: 'a ordem de antes não muda');
      for (final p in _propsNovos) {
        final s = PropPainter.tamanho(p, 200);
        expect(s.width, greaterThan(10), reason: p.name);
        expect(s.height, greaterThan(10), reason: p.name);
        final mao = AtorHistoria.tamanhoNaMao(p, 200);
        expect(math.max(mao.width, mao.height), lessThanOrEqualTo(60.0001), reason: p.name);
      }
      // o telão e o quadro branco ficam no chão do tamanho de um móvel (mais alto que a metade do ator)
      expect(PropPainter.tamanho(PropHistoria.telao, 100).height, greaterThan(50));
      expect(PropPainter.tamanho(PropHistoria.quadroBranco, 100).height, greaterThan(50));
    });

    test('cada um desenha algo de verdade (≥ 25% da caixa) em 3 escalas, e cada um é diferente', () async {
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
        for (final s in [Size.zero, const Size(1, 300), const Size(300, 1), const Size(37, 11)]) {
          _grava((cv) => PropPainter(prop: p).paint(cv, s)).dispose();
        }
      }
    });

    testWidgets('na mão de um ator (parado, acenando, mostrando) em 3 alturas, sem exceção', (tester) async {
      for (final p in _propsNovos) {
        for (final alt in [84.0, 200.0, 420.0]) {
          for (final acao in [AcaoAtor.parado, AcaoAtor.acena, AcaoAtor.mostra]) {
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
          }
        }
      }
    });
  });

  test('as histórias escritas usam cada cenário e cada prop novos (os substitutos dos pedidos foram trocados)', () {
    final usados = <String>{};
    final pasta = Directory('assets/ingles/historias');
    void varre(Object? j) {
      if (j is Map) {
        for (final e in j.entries) {
          if ((e.key == 'cenario' || e.key == 'prop' || e.key == 'segura') && e.value is String) usados.add(e.value as String);
          varre(e.value);
        }
      } else if (j is List) {
        j.forEach(varre);
      }
    }

    for (final f in pasta.listSync().whereType<File>().where((f) => f.path.endsWith('.json'))) {
      if (f.path.endsWith('indice.json') || f.path.endsWith('encenacao_auto.json')) continue;
      varre(jsonDecode(f.readAsStringSync()));
    }
    for (final c in _novos) {
      expect(usados, contains(c.name));
    }
    for (final p in _propsNovos) {
      expect(usados, contains(p.name));
    }
  });
}
