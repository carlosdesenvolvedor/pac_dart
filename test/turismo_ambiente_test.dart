import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/ambiente_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/cenario.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/cenario_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/pista_gt.dart';

/// 🌍 Os 26 mundos do Turismo no fallback 2D (AmbienteTurismo, CenarioTurismo, CamadaClima2D,
/// VistaCorrida nas pistas 11–30) e o espelho com a tabela TEMAS do 3D (web/turismo3d/turismo3d.js).
void main() {
  group('AmbienteTurismo.de', () {
    test('1..26: tema certo, base 1..6, nome e emoji, nomes únicos', () {
      final nomes = <String>{};
      for (var t = 1; t <= 26; t++) {
        final a = AmbienteTurismo.de(t);
        expect(a.tema, t);
        expect(a.base, inInclusiveRange(1, 6), reason: 'tema $t');
        expect(a.nome.trim(), isNotEmpty);
        expect(a.emoji.trim(), isNotEmpty);
        expect(nomes.add(a.nome), isTrue, reason: 'nome repetido: ${a.nome}');
        expect(a.tintaForca, inInclusiveRange(0, 1));
        if (t <= 6) {
          expect(a.base, t);
          expect(a.tintaCeu, isNull);
          expect(a.clima, Clima2D.nenhum);
          expect(a.chao, isNull);
          expect(a.relampago, isFalse);
        }
      }
    });

    test('o nome do mundo nunca repete o nome de uma pista (as 30 do inglês)', () {
      final pistas = {for (final p in pistasGtIngles) p.nome.toLowerCase()};
      for (var t = 1; t <= 26; t++) {
        expect(pistas.contains(AmbienteTurismo.de(t).nome.toLowerCase()), isFalse, reason: 'tema $t');
      }
    });

    test('1–6: nome/emoji de cenario.dart e noturno pela fórmula antiga da VistaCorrida', () {
      for (var t = 1; t <= 6; t++) {
        final a = AmbienteTurismo.de(t);
        expect(a.nome, nomeDaFase(t));
        expect(a.emoji, emojiDaFase(t));
        final antigo = (t - 1) % 6;
        expect(a.noturno, antigo == 2 || antigo == 4 || antigo == 5, reason: 'tema $t');
        expect(identical(a.chaoEfetivo, chaoDaFase(t)), isTrue);
      }
    });

    test('fora de 1..26 cai no tema 1', () {
      for (final t in [0, -3, 27, 99]) {
        final a = AmbienteTurismo.de(t);
        expect(a.tema, 1);
        expect(a.nome, nomeDaFase(1));
      }
    });

    test('pistas 11–30: tema = número − 4, cada uma com o seu mundo (sem cair no tema 1)', () {
      final vistos = <int>{};
      for (final p in pistasGtExtrasIngles) {
        expect(p.tema, p.numero - 4);
        expect(AmbienteTurismo.de(p.tema).tema, p.tema);
        expect(vistos.add(p.tema), isTrue);
      }
      expect(vistos, hasLength(20));
    });

    test('só o relâmpago da Campina sob Raios; neon com linha própria (18 e 25)', () {
      expect([for (var t = 1; t <= 26; t++) if (AmbienteTurismo.de(t).relampago) t], [10]);
      expect(AmbienteTurismo.de(18).chaoEfetivo.linha, const Color(0xFF22E6FF));
      expect(AmbienteTurismo.de(25).chaoEfetivo.linha, const Color(0xFF22E6FF));
    });

    test('temaPara3d: módulo velho (cache) recebe o mundo base; o atual, o próprio tema', () {
      for (var t = 1; t <= 26; t++) {
        expect(AmbienteTurismo.temaPara3d(t, versaoModulo: 30, esperada: 30), t);
        expect(AmbienteTurismo.temaPara3d(t, versaoModulo: 31, esperada: 30), t);
        final velho = AmbienteTurismo.temaPara3d(t, versaoModulo: 0, esperada: 30);
        expect(velho, t <= 6 ? t : AmbienteTurismo.de(t).base);
        expect(velho, inInclusiveRange(1, 6));
      }
    });
  });

  group('espelho do 3D (web/turismo3d/turismo3d.js)', () {
    final js = File('web/turismo3d/turismo3d.js').readAsStringSync();
    // cada tema numa linha "N: { hdri: '…', … noturno: true|false, … densidade: 0.00xx"
    final temas = {
      for (final m in RegExp(r"^\s*(\d+): \{ hdri: '(\w+)'.*?noturno: (true|false).*?densidade: ([\d.]+)", multiLine: true)
          .allMatches(js))
        int.parse(m.group(1)!): (hdri: m.group(2)!, noturno: m.group(3) == 'true', densidade: double.parse(m.group(4)!)),
    };

    test('TEMAS 1..26, neblina ≤ .005 e o mesmo noturno do 2D', () {
      expect(temas.keys.toList()..sort(), [for (var t = 1; t <= 26; t++) t]);
      for (final MapEntry(key: t, value: v) in temas.entries) {
        expect(v.densidade, inExclusiveRange(0, .0051), reason: 'tema $t');
        expect(v.noturno, AmbienteTurismo.de(t).noturno, reason: 'noturno do tema $t (3D × 2D)');
      }
    });

    test('VERSAO 30 no módulo, ?v=30 no import e o mesmo número no Dart', () {
      expect(RegExp(r'export const VERSAO = (\d+);').firstMatch(js)?.group(1), '30');
      expect(File('web/index.html').readAsStringSync(), contains("import('./turismo3d/turismo3d.js?v=30')"));
      expect(File('lib/features/arcade/presentation/widgets/vista_3d_web.dart').readAsStringSync(),
          contains('const versaoTurismo3d = 30;'));
    });
  });

  group('CamadaClima2D', () {
    test('relâmpago: opacidade ≤ .25 e no máximo 2 pulsos por segundo; reduzir = nenhum', () {
      const passo = .001;
      final inicios = <double>[];
      var anterior = 0.0, maximo = 0.0;
      for (var i = 0; i < 30000; i++) {
        final t = i * passo;
        final o = PintorClima2D.opacidadeRelampago(t);
        maximo = max(maximo, o);
        if (o > 0 && anterior == 0) inicios.add(t);
        anterior = o;
        expect(PintorClima2D.opacidadeRelampago(t, reduzir: true), 0);
      }
      expect(maximo, greaterThan(0));
      expect(maximo, lessThanOrEqualTo(.25));
      expect(inicios, isNotEmpty);
      for (var i = 2; i < inicios.length; i++) {
        expect(inicios[i] - inicios[i - 2], greaterThanOrEqualTo(1), reason: '3 pulsos em menos de 1 s');
      }
    });

    testWidgets('todo clima × camada × reduzir pinta sem exceção (360×200 e 1280×300)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final tam in const [Size(360, 200), Size(1280, 300)]) {
        for (final clima in Clima2D.values) {
          for (final camada in CamadaClima.values) {
            for (final reduzir in [false, true]) {
              for (final t in [0.0, 2.05, 7.3]) {
                await tester.pumpWidget(Center(
                  child: SizedBox.fromSize(
                    size: tam,
                    child: CamadaClima2D(clima: clima, t: t, reduzir: reduzir, camada: camada, relampago: clima == Clima2D.chuva),
                  ),
                ));
                expect(tester.takeException(), isNull, reason: '$clima $camada reduzir=$reduzir t=$t');
              }
            }
          }
        }
      }
    });
  });

  group('CenarioTurismo', () {
    testWidgets('os 26 temas (e camadas) renderizam em 360×200 e 1280×300, com e sem reduzir', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final tam in const [Size(360, 200), Size(1280, 300)]) {
        for (var tema = 1; tema <= 26; tema++) {
          for (final reduzir in [false, true]) {
            for (final camada in CamadaClima.values) {
              await tester.pumpWidget(Directionality(
                textDirection: TextDirection.ltr,
                child: Center(
                  child: SizedBox.fromSize(
                    size: tam,
                    child: CenarioTurismo(tema: tema, t: 2.05, reduzir: reduzir, camada: camada),
                  ),
                ),
              ));
              expect(tester.takeException(), isNull, reason: 'tema $tema $camada reduzir=$reduzir');
              expect(find.byType(CenarioFase), findsOneWidget);
            }
          }
        }
      }
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'o clima 2D não tem Ticker próprio');
    });

    testWidgets('temas 1–6 são o CenarioFase puro (sem véu nem clima)', (tester) async {
      for (var tema = 1; tema <= 6; tema++) {
        await tester.pumpWidget(SizedBox(width: 300, height: 150, child: CenarioTurismo(tema: tema, t: 3)));
        expect(find.byType(CamadaClima2D), findsNothing);
        expect(find.byType(DecoratedBox), findsNothing);
        expect(tester.widget<CenarioFase>(find.byType(CenarioFase)).fase, tema);
      }
    });

    testWidgets('mundo novo: véu no céu + clima; na camada do céu só o clima do céu', (tester) async {
      Future<void> montar(int tema, CamadaClima camada) => tester.pumpWidget(
          SizedBox(width: 300, height: 150, child: CenarioTurismo(tema: tema, camada: camada)));
      await montar(10, CamadaClima.tudo); // chuva + relâmpago
      expect(find.byType(DecoratedBox), findsOneWidget);
      expect(tester.widget<CamadaClima2D>(find.byType(CamadaClima2D)).relampago, isTrue);
      await montar(10, CamadaClima.ceu); // a chuva cai na frente da estrada, não aqui
      expect(find.byType(CamadaClima2D), findsNothing);
      await montar(15, CamadaClima.ceu); // estrelas moram no céu
      expect(tester.widget<CamadaClima2D>(find.byType(CamadaClima2D)).clima, Clima2D.estrelas);
      expect(tester.widget<CenarioFase>(find.byType(CenarioFase)).fase, 2);
    });
  });

  group('VistaCorrida (fallback 2D)', () {
    testWidgets('cada pista 11–30 em 360×780 e 1000×1400, parada e andando, sem exceção', (tester) async {
      for (final tam in const [Size(360, 780), Size(1000, 1400)]) {
        await tester.binding.setSurfaceSize(tam);
        for (final p in pistasGtExtrasIngles) {
          final e = TurismoEngine(pista: p, rnd: Random(3), vocabulario: const ['road', 'house', 'water', 'green', 'light', 'friend']);
          for (final (relogio, reduzir) in [(0.0, false), (2.05, false), (5.5, true)]) {
            if (relogio > 0) e.tick(.5);
            await tester.pumpWidget(MaterialApp(
              home: Scaffold(body: VistaCorrida(engine: e, relogio: relogio, reduzir: reduzir)),
            ));
            expect(tester.takeException(), isNull, reason: 'pista ${p.numero} $tam relogio=$relogio');
          }
          final ambiente = AmbienteTurismo.de(p.tema);
          final naFrente = (ambiente.clima != Clima2D.nenhum && !ambiente.clima.doCeu) || ambiente.relampago;
          expect(find.byType(CenarioTurismo), findsOneWidget);
          // a camada da frente só existe quando o clima cai por cima da estrada
          expect(
            find.byWidgetPredicate((w) => w is CamadaClima2D && w.camada == CamadaClima.frente),
            naFrente ? findsOneWidget : findsNothing,
            reason: 'pista ${p.numero}',
          );
        }
      }
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('pistas 1–10: nenhuma camada de clima (o 2D de sempre)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 600));
      for (final p in pistasGt) {
        final e = TurismoEngine(pista: p, rnd: Random(3));
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: VistaCorrida(engine: e, relogio: 1))));
        expect(tester.takeException(), isNull);
        expect(find.byType(CamadaClima2D), findsNothing);
        expect(tester.widget<CenarioFase>(find.byType(CenarioFase)).fase, p.tema);
      }
      await tester.binding.setSurfaceSize(null);
    });
  });
}
