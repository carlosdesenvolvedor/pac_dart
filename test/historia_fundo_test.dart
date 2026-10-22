import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/fundo_historia.dart';

/// 🖼️ Grupo C3: os 25 fundos pintados (FundoHistoriaPainter) × paleta da hora × 3 camadas.

ui.Picture _grava(List<FundoHistoriaPainter> camadas, Size s) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  for (final f in camadas) {
    f.paint(c, s);
  }
  return rec.endRecording();
}

Future<Uint8List> _pixels(List<FundoHistoriaPainter> camadas, Size s) async {
  final pic = _grava(camadas, s);
  final img = await pic.toImage(s.width.toInt(), s.height.toInt());
  final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
  img.dispose();
  pic.dispose();
  return bytes!.buffer.asUint8List();
}

FundoHistoriaPainter _f(CenarioHistoria c, HoraHistoria h, CamadaFundo cam, {double t = 0, double paralaxe = 0}) =>
    FundoHistoriaPainter(cenario: c, hora: h, camada: cam, t: t, paralaxe: paralaxe);

HoraHistoria _umaHora(CenarioHistoria c) =>
    horasPermitidas(c).contains(HoraHistoria.dia) ? HoraHistoria.dia : HoraHistoria.noite;

double _luminancia(Uint8List px) {
  var soma = 0.0;
  for (var i = 0; i < px.length; i += 4) {
    soma += .2126 * px[i] + .7152 * px[i + 1] + .0722 * px[i + 2];
  }
  return soma / (px.length / 4);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const tamanhos = [Size(360, 640), Size(2560, 1080)];

  test('linhaDoChao de cada cenário fica em [.6, .9] e o horizonte fica acima dela', () {
    for (final c in CenarioHistoria.values) {
      final chao = FundoHistoriaPainter.linhaDoChao(c);
      expect(chao, inInclusiveRange(.6, .9), reason: c.name);
      expect(FundoHistoriaPainter.horizonte(c), lessThan(chao - .1), reason: c.name);
    }
  });

  test('cada cenário × horasPermitidas × 3 camadas × paralaxe 0/1 pinta sem exceção (360×640 e 2560×1080)', () {
    var quadros = 0;
    for (final s in tamanhos) {
      for (final c in CenarioHistoria.values) {
        for (final h in horasPermitidas(c)) {
          for (final cam in CamadaFundo.values) {
            for (final par in [0.0, 1.0]) {
              for (final t in [0.0, 7.3]) {
                _grava([_f(c, h, cam, t: t, paralaxe: par)], s).dispose();
                quadros++;
              }
            }
          }
        }
      }
    }
    // espaciais (espaco, lua, estacao) só têm noite: 34×4 + 3×1 = 139 pares cenário/hora
    // (os 5 interiores das lições do 📺 entraram no fim do enum: 22×4 → 27×4; a 2ª leva dos pedidos de arte —
    // copa, recepcaoHotel, salaDeEstar — mais 3: 27×4 → 30×4; a 3ª leva — dentroDoCarro, cozinha, quintal, bar —
    // mais 4: 30×4 → 34×4)
    expect(quadros, 2 * 139 * 3 * 2 * 2);
  });

  test('entradas estranhas não quebram: tamanho zero, paralaxe negativa/enorme/NaN, t infinito', () {
    for (final s in [Size.zero, const Size(0, 300), const Size(1, 1), const Size(37, 11)]) {
      for (final cam in CamadaFundo.values) {
        _grava([_f(CenarioHistoria.cidade, HoraHistoria.noite, cam)], s).dispose();
      }
    }
    for (final par in [-3.7, 1e9, double.nan, double.infinity]) {
      for (final t in [-5.0, double.infinity, double.nan]) {
        for (final cam in CamadaFundo.values) {
          _grava([_f(CenarioHistoria.praia, HoraHistoria.tarde, cam, t: t, paralaxe: par)], const Size(200, 120))
              .dispose();
        }
      }
    }
  });

  testWidgets('as 3 camadas empilhadas em CustomPaint, 360×640 e 2560×1080, sem exceção', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final s in tamanhos) {
      tester.view.physicalSize = s;
      for (final c in CenarioHistoria.values) {
        final h = horasPermitidas(c).elementAt(c.index % horasPermitidas(c).length);
        await tester.pumpWidget(Stack(
          textDirection: TextDirection.ltr,
          children: [
            for (final cam in CamadaFundo.values)
              Positioned.fill(
                child: RepaintBoundary(child: CustomPaint(painter: _f(c, h, cam, t: 1.5, paralaxe: .25))),
              ),
          ],
        ));
        expect(tester.takeException(), isNull, reason: '${c.name}/${h.name} em $s');
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  test('o céu é opaco na tela inteira (qualquer cenário, hora e paralaxe)', () async {
    const s = Size(96, 64);
    for (final c in CenarioHistoria.values) {
      for (final h in horasPermitidas(c)) {
        final px = await _pixels([_f(c, h, CamadaFundo.ceu, t: 2, paralaxe: .37)], s);
        for (var i = 3; i < px.length; i += 4) {
          if (px[i] != 255) fail('${c.name}/${h.name}: pixel ${i ~/ 4} transparente no céu');
        }
      }
    }
  });

  test('o chão cobre tudo da linha do chão para baixo; nos exteriores, o topo da camada distante é céu aberto', () async {
    const s = Size(120, 90);
    for (final c in CenarioHistoria.values) {
      final h = _umaHora(c);
      final chao = await _pixels([_f(c, h, CamadaFundo.chao, paralaxe: .2)], s);
      final y0 = (s.height * FundoHistoriaPainter.linhaDoChao(c)).ceil();
      for (var y = y0; y < s.height; y++) {
        for (var x = 0; x < s.width; x++) {
          expect(chao[(y * s.width.toInt() + x) * 4 + 3], 255, reason: '${c.name}: ($x,$y) sem chão');
        }
      }
      if (!interioresHistoria.contains(c) && c != CenarioHistoria.canion) {
        // a camada distante não pinta o céu (a primeira linha é transparente, salvo um ou outro poste)
        final longe = await _pixels([_f(c, h, CamadaFundo.distante)], s);
        var opacos = 0;
        for (var x = 0; x < s.width; x++) {
          if (longe[x * 4 + 3] > 0) opacos++;
        }
        expect(opacos, lessThan(s.width * .2), reason: c.name);
      }
    }
  });

  test('a hora muda a paleta: à noite tudo fica mais escuro que de dia', () async {
    const s = Size(80, 60);
    for (final c in CenarioHistoria.values) {
      if (!horasPermitidas(c).contains(HoraHistoria.dia)) continue;
      final lum = <HoraHistoria, double>{};
      for (final h in HoraHistoria.values) {
        lum[h] = _luminancia(await _pixels([for (final cam in CamadaFundo.values) _f(c, h, cam)], s));
      }
      expect(lum[HoraHistoria.noite]!, lessThan(lum[HoraHistoria.dia]! - 15), reason: c.name);
      expect(lum.values.toSet().length, 4, reason: '${c.name}: as 4 horas pintam igual');
    }
  });

  test('os 25 cenários são pinturas diferentes (distante + chão)', () async {
    const s = Size(64, 40);
    final vistos = <String, CenarioHistoria>{};
    for (final c in CenarioHistoria.values) {
      final px = await _pixels([_f(c, HoraHistoria.noite, CamadaFundo.distante), _f(c, HoraHistoria.noite, CamadaFundo.chao)], s);
      final chave = Object.hashAll(px).toString();
      expect(vistos.containsKey(chave), isFalse, reason: '${c.name} igual a ${vistos[chave]?.name}');
      vistos[chave] = c;
    }
  });

  test('determinístico: a mesma entrada pinta os mesmos pixels; t mexe nas animações', () async {
    const s = Size(160, 90);
    for (final c in [CenarioHistoria.praia, CenarioHistoria.vulcao, CenarioHistoria.autodromo]) {
      final todas = [for (final cam in CamadaFundo.values) _f(c, HoraHistoria.noite, cam, t: 3.3, paralaxe: .2)];
      expect(await _pixels(todas, s), await _pixels(todas, s), reason: c.name);
      final depois = [for (final cam in CamadaFundo.values) _f(c, HoraHistoria.noite, cam, t: 4.1, paralaxe: .2)];
      expect(await _pixels(todas, s), isNot(equals(await _pixels(depois, s))), reason: '${c.name} parado no tempo');
    }
  });

  test('paralaxe: cada camada é periódica e meia volta é a pintura deslocada meia tela (sem emenda)', () async {
    const s = Size(240, 135);
    final w = s.width.toInt(), meia = w ~/ 2;
    final emendas = <String>[];
    for (final c in CenarioHistoria.values) {
      final h = _umaHora(c);
      for (final cam in CamadaFundo.values) {
        final volta = .5 / FundoHistoriaPainter.fatorParalaxe(cam); // anda exatamente meia largura
        final a = await _pixels([_f(c, h, cam, t: 1)], s);
        final b = await _pixels([_f(c, h, cam, t: 1, paralaxe: volta)], s);
        var diferentes = 0;
        for (var y = 0; y < s.height; y++) {
          for (var x = 0; x < w; x++) {
            final ia = (y * w + (x + meia) % w) * 4, ib = (y * w + x) * 4;
            var d = 0;
            for (var k = 0; k < 4; k++) {
              d = d > (a[ia + k] - b[ib + k]).abs() ? d : (a[ia + k] - b[ib + k]).abs();
            }
            if (d > 24) diferentes++;
          }
        }
        if (diferentes >= w * s.height * .004) emendas.add('${c.name}/${cam.name} ($diferentes px)');
      }
    }
    expect(emendas, isEmpty, reason: 'emenda na paralaxe');
  });

  test('shouldRepaint só quando algo muda', () {
    final base = _f(CenarioHistoria.campina, HoraHistoria.dia, CamadaFundo.ceu);
    expect(base.shouldRepaint(_f(CenarioHistoria.campina, HoraHistoria.dia, CamadaFundo.ceu)), isFalse);
    expect(base.shouldRepaint(_f(CenarioHistoria.deserto, HoraHistoria.dia, CamadaFundo.ceu)), isTrue);
    expect(base.shouldRepaint(_f(CenarioHistoria.campina, HoraHistoria.noite, CamadaFundo.ceu)), isTrue);
    expect(base.shouldRepaint(_f(CenarioHistoria.campina, HoraHistoria.dia, CamadaFundo.chao)), isTrue);
    expect(base.shouldRepaint(_f(CenarioHistoria.campina, HoraHistoria.dia, CamadaFundo.ceu, t: 1)), isTrue);
    expect(base.shouldRepaint(_f(CenarioHistoria.campina, HoraHistoria.dia, CamadaFundo.ceu, paralaxe: .1)), isTrue);
  });
}
