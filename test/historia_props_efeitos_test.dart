import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/clima_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/efeitos_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/props_historia.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';

/// Canvas espião: anota cada chamada (com os argumentos que importam) e os retângulos pintados com a cor.
class _Espiao implements Canvas {
  final ops = <String>[];
  final retangulos = <(Rect, Color)>[];

  static String _desc(Object? a) => switch (a) {
        final Path p => 'Path(${p.getBounds()})',
        final Paint p => 'Paint(${p.color}, ${p.style}, ${p.strokeWidth})',
        _ => '$a',
      };

  @override
  void drawRect(Rect rect, Paint paint) {
    ops.add('drawRect $rect ${_desc(paint)}');
    retangulos.add((rect, paint.color));
  }

  @override
  dynamic noSuchMethod(Invocation i) {
    ops.add('${i.memberName} ${i.positionalArguments.map(_desc).join(', ')}');
    return null;
  }
}

/// Pinta num canvas de verdade (pega erro de API do motor) e no espião; devolve o espião.
_Espiao _pinta(CustomPainter p, Size s) {
  final gravador = ui.PictureRecorder();
  p.paint(Canvas(gravador), s);
  gravador.endRecording().dispose();
  final e = _Espiao();
  p.paint(e, s);
  return e;
}

/// Opacidade do clarão (retângulo que cobre a camada inteira) medida no painter.
double _flashMedido(List<EfeitoAtivo> efeitos, double t, {bool reduzir = false, Size s = const Size(400, 300)}) {
  final e = _pinta(EfeitosHistoriaPainter(efeitos: efeitos, projeteis: const [], t: t, reduzir: reduzir), s);
  var alfa = 0.0;
  for (final (r, cor) in e.retangulos) {
    if (r.contains(Offset.zero) && r.contains(Offset(s.width, s.height)) && cor.a > alfa) alfa = cor.a;
  }
  return alfa;
}

/// Inícios dos pulsos (subidas de 0 para > 0) amostrados de 5 em 5 ms.
List<double> _pulsosMedidos(List<EfeitoAtivo> efeitos, {bool reduzir = false, double ate = 4}) {
  const passo = .005;
  final subidas = <double>[];
  var antes = 0.0;
  for (var t = -.1; t < ate; t += passo) {
    final a = _flashMedido(efeitos, t, reduzir: reduzir);
    expect(a, lessThanOrEqualTo(EfeitoHistoriaLayer.opacidadeMaxFlash + 1e-6), reason: 'clarão forte demais em t=$t');
    if (antes == 0 && a > 0) subidas.add(t);
    antes = a;
  }
  return subidas;
}

void _semMaisDeDoisPorSegundo(List<double> subidas) {
  for (var i = 2; i < subidas.length; i++) {
    expect(subidas[i] - subidas[i - 2], greaterThanOrEqualTo(1.0 - .006),
        reason: '3 pulsos em menos de 1 s: ${subidas.sublist(i - 2, i + 1)}');
  }
}

void main() {
  group('PropPainter', () {
    test('cada prop pinta em capítulos 1/7/22/29/30 e em caixas de vários formatos', () {
      for (final p in PropHistoria.values) {
        for (final cap in [1, 7, 22, 29, 30]) {
          for (final alt in [84.0, 200.0, 420.0]) {
            final s = PropPainter.tamanho(p, alt);
            final e = _pinta(PropPainter(prop: p, capitulo: cap, t: 1.3), s);
            if (p == PropHistoria.nada) {
              expect(s, Size.zero);
              expect(e.ops, isEmpty);
            } else {
              expect(s.width, greaterThan(0));
              expect(s.height, greaterThan(0));
              expect(e.ops, isNotEmpty, reason: '${p.name} não pintou nada');
            }
          }
        }
        // caixa com outra proporção, minúscula e vazia: sem exceção
        for (final s in const [Size(300, 40), Size(30, 300), Size(3, 3), Size.zero]) {
          _pinta(PropPainter(prop: p), s);
        }
      }
    });

    test('o carro do Team Star acumula as pinturas pelo capítulo; o rival não muda', () {
      int ops(PropHistoria p, int cap) => _pinta(PropPainter(prop: p, capitulo: cap), const Size(220, 90)).ops.length;
      final contagens = [for (final cap in [1, 7, 22, 29, 30]) ops(PropHistoria.carro, cap)];
      for (var i = 1; i < contagens.length; i++) {
        expect(contagens[i], greaterThan(contagens[i - 1]), reason: 'capítulos $contagens');
      }
      expect(ops(PropHistoria.carroRival, 1), ops(PropHistoria.carroRival, 30));
      expect(ops(PropHistoria.carro, 6), contagens[0]);
    });

    test('celular com e sem rosto (o rosto segue o visema)', () {
      const s = Size(48, 84);
      final sem = _pinta(PropPainter(prop: PropHistoria.celular), s);
      final com = _pinta(PropPainter(prop: PropHistoria.celular, rosto: ElencoIngles.mike, visema: Visema.d), s);
      final calado = _pinta(PropPainter(prop: PropHistoria.celular, rosto: ElencoIngles.mike), s);
      expect(com.ops.length, greaterThan(sem.ops.length));
      expect(com.ops.join('\n'), isNot(calado.ops.join('\n')));
      expect(
        PropPainter(prop: PropHistoria.celular, rosto: ElencoIngles.mike, visema: Visema.d)
            .shouldRepaint(PropPainter(prop: PropHistoria.celular, rosto: ElencoIngles.mike)),
        isTrue,
      );
    });

    testWidgets('props renderizam como widget (CustomPaint)', (tester) async {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(children: [
          for (final p in PropHistoria.values)
            CustomPaint(
              size: PropPainter.tamanho(p, 120),
              painter: PropPainter(prop: p, capitulo: 30, rosto: p == PropHistoria.celular ? ElencoIngles.sarah : null),
            ),
        ]),
      ));
      expect(tester.takeException(), isNull);
    });
  });

  group('EfeitoHistoriaLayer', () {
    const s = Size(400, 300);
    const o = Offset(200, 120);

    test('cada efeito em t 0/.6/1.2, com e sem reduzir', () {
      for (final ef in EfeitoHistoria.values) {
        for (final reduzir in [false, true]) {
          for (final t in [0.0, .6, 1.2]) {
            _pinta(
              EfeitosHistoriaPainter(efeitos: [EfeitoAtivo(ef, o, 0)], projeteis: const [], t: t, reduzir: reduzir),
              s,
            );
          }
          // no começo sempre aparece alguma coisa
          final e = _pinta(
            EfeitosHistoriaPainter(efeitos: [EfeitoAtivo(ef, o, 0)], projeteis: const [], t: .01, reduzir: reduzir),
            s,
          );
          expect(e.ops, isNotEmpty, reason: '${ef.name} reduzir=$reduzir');
          // depois da duração some
          final fim = EfeitoHistoriaLayer.duracao(ef, reduzir: reduzir);
          final depois = _pinta(
            EfeitosHistoriaPainter(efeitos: [EfeitoAtivo(ef, o, 0)], projeteis: const [], t: fim + .01, reduzir: reduzir),
            s,
          );
          expect(depois.ops, isEmpty, reason: '${ef.name} ainda na tela depois de $fim s');
          expect(EfeitoHistoriaLayer.ativo(EfeitoAtivo(ef, o, 0), fim + .01, reduzir: reduzir), isFalse);
          expect(EfeitoHistoriaLayer.ativo(EfeitoAtivo(ef, o, 0), .01, reduzir: reduzir), isTrue);
        }
      }
    });

    test('com reduzir, o efeito é um ícone parado (mesmo quadro ao longo dos 800 ms)', () {
      for (final ef in EfeitoHistoria.values) {
        if (ef == EfeitoHistoria.relampago) continue;
        String quadro(double t) => _pinta(
              EfeitosHistoriaPainter(efeitos: [EfeitoAtivo(ef, o, 0)], projeteis: const [], t: t, reduzir: true),
              s,
            ).ops.join('\n');
        expect(quadro(.1), quadro(.7), reason: ef.name);
        expect(EfeitoHistoriaLayer.duracao(ef, reduzir: true), .8);
      }
    });

    test('projétil: bola de neve e bolinha de papel voam em arco e respingam', () {
      for (final neve in [true, false]) {
        final pr = ProjetilAtivo(const Offset(60, 200), const Offset(340, 200), 1, neve: neve);
        for (final t in [.9, 1.0, 1.2, 1.4, 1.6, 1.79, 1.81]) {
          for (final reduzir in [false, true]) {
            _pinta(EfeitosHistoriaPainter(efeitos: const [], projeteis: [pr], t: t, reduzir: reduzir), s);
          }
        }
        // antes do início e depois do respingo: nada
        expect(_pinta(EfeitosHistoriaPainter(efeitos: const [], projeteis: [pr], t: .9), s).ops, isEmpty);
        expect(
          _pinta(EfeitosHistoriaPainter(efeitos: const [], projeteis: [pr], t: 1 + EfeitoHistoriaLayer.duracaoProjetil + .01), s)
              .ops,
          isEmpty,
        );
        // no meio do voo está pintando (e a neve é diferente do papel)
        expect(_pinta(EfeitosHistoriaPainter(efeitos: const [], projeteis: [pr], t: 1.25), s).ops, isNotEmpty);
      }
      String meio(bool neve) => _pinta(
            EfeitosHistoriaPainter(
                efeitos: const [],
                projeteis: [ProjetilAtivo(const Offset(60, 200), const Offset(340, 200), 0, neve: neve)],
                t: .25),
            s,
          ).ops.join('\n');
      expect(meio(true), isNot(meio(false)));
    });

    test('relâmpago: clarão ≤ .25 e no máximo 2 pulsos por segundo (medido no painter)', () {
      // um relâmpago: 2 pulsos
      final um = _pulsosMedidos([const EfeitoAtivo(EfeitoHistoria.relampago, o, 0)]);
      expect(um.length, 2);
      _semMaisDeDoisPorSegundo(um);
      expect(
        [for (var t = 0.0; t < .5; t += .005) _flashMedido([const EfeitoAtivo(EfeitoHistoria.relampago, o, 0)], t)]
            .reduce((a, b) => a > b ? a : b),
        closeTo(EfeitoHistoriaLayer.opacidadeMaxFlash, .01),
      );
      // vários relâmpagos colados (pior caso do roteiro): continua ≤ 2 por segundo e ≤ .25
      final muitos = [
        for (final i in [0.0, .1, .2, .5, .8, 1.1, 1.3, 2.0, 2.05]) EfeitoAtivo(EfeitoHistoria.relampago, o, i),
      ];
      final subidas = _pulsosMedidos(muitos);
      expect(subidas, isNotEmpty);
      _semMaisDeDoisPorSegundo(subidas);
    });

    test('relâmpago com reduzir: clarão suave ≤ .15 por 300 ms, sem raio e sem tremida', () {
      const um = [EfeitoAtivo(EfeitoHistoria.relampago, o, 0)];
      final medidas = [for (var t = -.05; t < 1.0; t += .005) (t, _flashMedido(um, t, reduzir: true))];
      final aceso = [for (final (t, a) in medidas) if (a > 0) t];
      expect(medidas.map((m) => m.$2).reduce((a, b) => a > b ? a : b),
          lessThanOrEqualTo(EfeitoHistoriaLayer.opacidadeFlashSuave + 1e-6));
      expect(aceso.last - aceso.first, lessThanOrEqualTo(.3));
      final subidas = _pulsosMedidos(
        [for (final i in [0.0, .2, .4, .6]) EfeitoAtivo(EfeitoHistoria.relampago, o, i)],
        reduzir: true,
      );
      _semMaisDeDoisPorSegundo(subidas);
      // só o clarão (um drawRect), nada de raio
      final e = _pinta(EfeitosHistoriaPainter(efeitos: um, projeteis: const [], t: .15, reduzir: true), s);
      expect(e.ops.length, 1);
      expect(EfeitoHistoriaLayer.tremor(um, .1, reduzir: true), Offset.zero);
      expect(EfeitoHistoriaLayer.tremor(um, .1), isNot(Offset.zero));
      expect(EfeitoHistoriaLayer.tremor(um, .5), Offset.zero);
    });

    test('pulsosRelampago: pulsos sobrepostos viram um e a janela de 1 s nunca tem 3', () {
      expect(EfeitoHistoriaLayer.pulsosRelampago(const [EfeitoAtivo(EfeitoHistoria.relampago, o, 2)]), [2, 2.35]);
      expect(EfeitoHistoriaLayer.pulsosRelampago(const [EfeitoAtivo(EfeitoHistoria.confete, o, 2)]), isEmpty);
      final p = EfeitoHistoriaLayer.pulsosRelampago([
        for (var i = 0; i < 20; i++) EfeitoAtivo(EfeitoHistoria.relampago, o, i * .05),
      ]);
      for (var i = 2; i < p.length; i++) {
        expect(p[i] - p[i - 2], greaterThanOrEqualTo(1.0));
      }
    });

    testWidgets('a camada monta em 360×640 e 2560×1080, com e sem reduzir', (tester) async {
      for (final tam in const [Size(360, 640), Size(2560, 1080)]) {
        for (final reduzir in [false, true]) {
          for (final t in [0.0, .3, 1.2]) {
            await tester.pumpWidget(Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox.fromSize(
                  size: tam,
                  child: Stack(children: [
                    Positioned.fill(
                      child: EfeitoHistoriaLayer(
                        efeitos: [
                          for (final ef in EfeitoHistoria.values) EfeitoAtivo(ef, Offset(tam.width / 2, tam.height / 3), 0),
                        ],
                        projeteis: [
                          ProjetilAtivo(Offset(10, tam.height * .7), Offset(tam.width - 10, tam.height * .7), 0, neve: true),
                          ProjetilAtivo(Offset(tam.width - 10, tam.height * .7), Offset(10, tam.height * .7), 0),
                        ],
                        t: t,
                        reduzir: reduzir,
                      ),
                    ),
                  ]),
                ),
              ),
            ));
            expect(tester.takeException(), isNull);
          }
        }
      }
      await tester.pumpWidget(const EfeitoHistoriaLayer(efeitos: [], projeteis: [], t: 0));
      expect(tester.takeException(), isNull);
    });
  });

  group('ClimaHistoriaPainter', () {
    test('cada clima permitido em cada cenário/hora, frente e trás, animado e estático', () {
      var combinacoes = 0;
      for (final c in CenarioHistoria.values) {
        for (final h in horasPermitidas(c)) {
          for (final cl in ClimaHistoria.values) {
            if (!climaPermitido(cl, c, h)) continue;
            combinacoes++;
            var pintou = false;
            for (final frente in [false, true]) {
              for (final estatico in [false, true]) {
                for (final t in [0.0, 1.3, 7.9]) {
                  final e = _pinta(
                    ClimaHistoriaPainter(clima: [cl], frente: frente, t: t, hora: h, cenario: c, estatico: estatico),
                    const Size(640, 360),
                  );
                  pintou |= e.ops.isNotEmpty;
                }
              }
            }
            expect(pintou, isTrue, reason: '${cl.name} em ${c.name}/${h.name} não pinta em nenhuma passada');
          }
        }
      }
      expect(combinacoes, greaterThan(200));
    });

    test('passadas: estrelas/aurora/arco-íris atrás; chuva na frente (na janela, só atrás, nos interiores)', () {
      int ops(ClimaHistoria cl, bool frente, CenarioHistoria c, HoraHistoria h) => _pinta(
            ClimaHistoriaPainter(clima: [cl], frente: frente, t: 2, hora: h, cenario: c),
            const Size(640, 360),
          ).ops.length;
      for (final cl in [ClimaHistoria.estrelas, ClimaHistoria.aurora]) {
        expect(ops(cl, true, CenarioHistoria.neve, HoraHistoria.noite), 0);
        expect(ops(cl, false, CenarioHistoria.neve, HoraHistoria.noite), greaterThan(0));
      }
      expect(ops(ClimaHistoria.arcoIris, true, CenarioHistoria.campina, HoraHistoria.dia), 0);
      expect(ops(ClimaHistoria.arcoIris, false, CenarioHistoria.campina, HoraHistoria.dia), greaterThan(0));
      for (final cl in [ClimaHistoria.areia, ClimaHistoria.folhas, ClimaHistoria.vento]) {
        expect(ops(cl, false, CenarioHistoria.deserto, HoraHistoria.dia), 0);
        expect(ops(cl, true, CenarioHistoria.deserto, HoraHistoria.dia), greaterThan(0));
      }
      expect(ops(ClimaHistoria.chuva, true, CenarioHistoria.campina, HoraHistoria.tarde), greaterThan(0));
      for (final interior in interioresHistoria) {
        if (interior == CenarioHistoria.estacao) continue;
        expect(ops(ClimaHistoria.chuva, true, interior, HoraHistoria.noite), 0, reason: interior.name);
        expect(ops(ClimaHistoria.chuva, false, interior, HoraHistoria.noite), greaterThan(0), reason: interior.name);
        expect(ops(ClimaHistoria.neve, true, interior, HoraHistoria.dia), 0, reason: interior.name);
      }
      expect(ClimaHistoriaPainter.pintaNaPassada(ClimaHistoria.neve, frente: true, interior: false), isTrue);
      expect(ClimaHistoriaPainter.pintaNaPassada(ClimaHistoria.neve, frente: false, interior: false), isTrue);
    });

    test('estático = mesmo quadro em qualquer t; animado muda com t; arco-íris aparece com fade', () {
      for (final cl in ClimaHistoria.values) {
        final (c, h) = switch (cl) {
          ClimaHistoria.estrelas || ClimaHistoria.aurora => (CenarioHistoria.neve, HoraHistoria.noite),
          ClimaHistoria.neon => (CenarioHistoria.cidade, HoraHistoria.noite),
          _ => (CenarioHistoria.campina, HoraHistoria.dia),
        };
        expect(climaPermitido(cl, c, h), isTrue);
        for (final frente in [false, true]) {
          String quadro(double t, bool est) => _pinta(
                ClimaHistoriaPainter(clima: [cl], frente: frente, t: t, hora: h, cenario: c, estatico: est),
                const Size(640, 360),
              ).ops.join('\n');
          expect(quadro(0, true), quadro(5.7, true), reason: '${cl.name} frente=$frente');
          final animado = quadro(.4, false);
          // o arco-íris fica parado depois do fade; o véu da neblina e o brilho das brasas atrás são fixos
          final fixo = cl == ClimaHistoria.arcoIris ||
              (!frente && (cl == ClimaHistoria.neblina || cl == ClimaHistoria.brasas));
          if (animado.isNotEmpty && !fixo) {
            expect(animado, isNot(quadro(2.9, false)), reason: '${cl.name} frente=$frente parado');
          }
        }
      }
      String arco(double t) => _pinta(
            ClimaHistoriaPainter(
                clima: const [ClimaHistoria.arcoIris],
                frente: false,
                t: t,
                hora: HoraHistoria.dia,
                cenario: CenarioHistoria.campina),
            const Size(640, 360),
          ).ops.join('\n');
      expect(arco(0), isEmpty);
      expect(arco(.5), isNot(arco(1.0)));
      expect(arco(1.0), arco(4.0));
      final p1 = ClimaHistoriaPainter(
          clima: const [ClimaHistoria.chuva], frente: true, t: 1, hora: HoraHistoria.dia, cenario: CenarioHistoria.campina);
      final p2 = ClimaHistoriaPainter(
          clima: const [ClimaHistoria.chuva], frente: true, t: 2, hora: HoraHistoria.dia, cenario: CenarioHistoria.campina);
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test('vários climas juntos e tamanhos extremos', () {
      for (final s in const [Size(360, 640), Size(2560, 1080), Size(1, 1), Size.zero]) {
        for (final frente in [false, true]) {
          _pinta(
            ClimaHistoriaPainter(
              clima: const [ClimaHistoria.neve, ClimaHistoria.vento, ClimaHistoria.aurora, ClimaHistoria.estrelas],
              frente: frente,
              t: 3.3,
              hora: HoraHistoria.noite,
              cenario: CenarioHistoria.neve,
            ),
            s,
          );
          _pinta(
            ClimaHistoriaPainter(
              clima: const [ClimaHistoria.neon, ClimaHistoria.chuva],
              frente: frente,
              t: 3.3,
              hora: HoraHistoria.noite,
              cenario: CenarioHistoria.cidade,
            ),
            s,
          );
        }
      }
      expect(
        _pinta(
          ClimaHistoriaPainter(clima: const [], frente: true, t: 1, hora: HoraHistoria.dia, cenario: CenarioHistoria.campina),
          const Size(640, 360),
        ).ops,
        isEmpty,
      );
    });

    testWidgets('renderiza como widget em 360×640 e 2560×1080', (tester) async {
      for (final tam in const [Size(360, 640), Size(2560, 1080)]) {
        for (final frente in [false, true]) {
          await tester.pumpWidget(Center(
            child: CustomPaint(
              size: tam,
              painter: ClimaHistoriaPainter(
                clima: const [ClimaHistoria.chuva, ClimaHistoria.neblina, ClimaHistoria.brasas, ClimaHistoria.folhas],
                frente: frente,
                t: 2.2,
                hora: HoraHistoria.tarde,
                cenario: CenarioHistoria.vulcao,
              ),
            ),
          ));
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
