import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/ator_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/props_historia.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/domain/expressao.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';

/// Os 11 personagens com corpo da história.
const _ids = ['voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee', 'max', 'kim'];
const _alturas = [84.0, 200.0, 420.0];
const _progressos = [0.0, .5, 1.0];

/// (sentado, dormindo, noCarro): nenhum, cada um sozinho e os três juntos.
const _estados = [
  (false, false, false),
  (true, false, false),
  (false, true, false),
  (false, false, true),
  (true, true, true),
];

/// Pinta um painter numa imagem e devolve os bytes RGBA.
Future<Uint8List> _pixels(CustomPainter painter, Size size) async {
  final gravador = ui.PictureRecorder();
  painter.paint(Canvas(gravador), size);
  final imagem = await gravador.endRecording().toImage(size.width.round(), size.height.round());
  final dados = await imagem.toByteData(format: ui.ImageByteFormat.rawRgba);
  imagem.dispose();
  return dados!.buffer.asUint8List();
}

void _pinta(CustomPainter painter, Size size) {
  final gravador = ui.PictureRecorder();
  painter.paint(Canvas(gravador), size);
  gravador.endRecording().dispose();
}

void main() {
  group('desenho (painters), todas as combinações', () {
    test('cada AcaoAtor × progresso × estados × Expressao × espelho × altura pinta sem exceção', () {
      var n = 0;
      for (final h in _alturas) {
        final size = Size(AtorHistoria.largura(h), h);
        for (final acao in AcaoAtor.values) {
          for (final p in _progressos) {
            for (final (sentado, dormindo, noCarro) in _estados) {
              final pose = PoseAtor(
                acao: acao,
                progresso: p,
                tempo: 1.37,
                sentado: sentado,
                dormindo: dormindo,
                noCarro: noCarro,
                falando: p == .5,
              );
              for (final reduzir in [false, true]) {
                _pinta(CorpoPainter(aparencia: ElencoIngles.draLee, pose: pose, frente: false, reduzir: reduzir), size);
                _pinta(CorpoPainter(aparencia: ElencoTurismo.max, pose: pose, frente: true, reduzir: reduzir), size);
              }
              for (final e in Expressao.values) {
                for (final espelhado in [false, true]) {
                  _pinta(
                    EmotesPainter(
                      expressao: e,
                      tempo: 2.1,
                      dormindo: dormindo,
                      estrelinhas: acao == AcaoAtor.cai || acao == AcaoAtor.rodopia,
                      espelhado: espelhado,
                      cabeca: Offset(espelhado ? -3 : 3, h * .1),
                    ),
                    size,
                  );
                  n++;
                }
              }
            }
          }
        }
      }
      expect(n, 3 * AcaoAtor.values.length * 3 * _estados.length * 11 * 2);
    });

    test('o rosto pinta cada Expressao com cada Visema, olhar e piscada, para os 11 personagens', () {
      for (final id in _ids) {
        final a = ElencoTurismo.de(id)!;
        for (final e in Expressao.values) {
          for (final v in Visema.values) {
            for (final olhos in [0.0, .5, 1.0]) {
              _pinta(
                PersonagemPainter(a, expressao: e, visema: v, olhos: olhos, olhar: const Offset(-1, .5)),
                const Size.square(120),
              );
            }
          }
        }
      }
    });

    test('as 11 expressões desenham rostos diferentes; o default é o neutro de sempre', () async {
      const size = Size.square(160);
      final padrao = await _pixels(PersonagemPainter(ElencoIngles.ana), size);
      final imagens = <Expressao, Uint8List>{
        for (final e in Expressao.values) e: await _pixels(PersonagemPainter(ElencoIngles.ana, expressao: e), size),
      };
      expect(imagens[Expressao.neutro], padrao, reason: 'neutro = desenho de hoje (ingles_boca_test)');
      final vistos = <String>{};
      for (final MapEntry(:key, :value) in imagens.entries) {
        expect(vistos.add(String.fromCharCodes(value)), isTrue, reason: '$key repetiu outro rosto');
      }
      // o olhar mexe os olhos; falando, a boca segue o visema e não a emoção
      final olhando = await _pixels(PersonagemPainter(ElencoIngles.ana, olhar: const Offset(1, 0)), size);
      expect(olhando, isNot(padrao));
      final falandoNeutro = await _pixels(PersonagemPainter(ElencoIngles.ana, visema: Visema.d), size);
      final falandoFeliz =
          await _pixels(PersonagemPainter(ElencoIngles.ana, visema: Visema.d, expressao: Expressao.feliz), size);
      expect(falandoNeutro, isNot(padrao));
      expect(falandoFeliz, isNot(falandoNeutro), reason: 'as sobrancelhas seguem a emoção mesmo falando');
    });

    test('shouldRepaint compara expressão e olhar', () {
      final base = PersonagemPainter(ElencoIngles.mike);
      expect(PersonagemPainter(ElencoIngles.mike).shouldRepaint(base), isFalse);
      expect(PersonagemPainter(ElencoIngles.mike, expressao: Expressao.bravo).shouldRepaint(base), isTrue);
      expect(PersonagemPainter(ElencoIngles.mike, olhar: const Offset(0, -1)).shouldRepaint(base), isTrue);
      const pose = PoseAtor(acao: AcaoAtor.pula, progresso: .5);
      final corpo = CorpoPainter(aparencia: ElencoIngles.mike, pose: pose, frente: true);
      expect(CorpoPainter(aparencia: ElencoIngles.mike, pose: pose, frente: true).shouldRepaint(corpo), isFalse);
      expect(
        CorpoPainter(aparencia: ElencoIngles.mike, pose: const PoseAtor(acao: AcaoAtor.pula, progresso: .6), frente: true)
            .shouldRepaint(corpo),
        isTrue,
      );
    });
  });

  group('AtorHistoria (widget)', () {
    Future<void> monta(WidgetTester t, List<Widget> atores) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 600,
                height: 600,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [for (final a in atores) Positioned(left: 60, top: 60, child: a)],
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('cada AcaoAtor × progresso × estados × espelho × altura (e reduzir) monta sem exceção', (t) async {
      t.view.physicalSize = const Size(1400, 1400);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final props = PropHistoria.values;
      var i = 0;
      for (final reduzir in [false, true]) {
        for (final h in _alturas) {
          for (final acao in AcaoAtor.values) {
            final atores = <Widget>[];
            for (final p in _progressos) {
              for (final (sentado, dormindo, noCarro) in _estados) {
                for (final espelhado in [false, true]) {
                  final id = _ids[i % _ids.length];
                  atores.add(AtorHistoria(
                    aparencia: ElencoTurismo.de(id)!,
                    altura: h,
                    pose: PoseAtor(
                      acao: acao,
                      progresso: p,
                      tempo: i * .13,
                      sentado: sentado,
                      dormindo: dormindo,
                      noCarro: noCarro,
                      falando: i.isEven,
                    ),
                    visema: Visema.values[i % Visema.values.length],
                    olhos: i % 7 == 0 ? 0 : 1,
                    expressao: Expressao.values[i % Expressao.values.length],
                    olhar: Offset((i % 3) - 1.0, 0),
                    espelhado: espelhado,
                    segura: i % 4 == 0 ? null : props[i % props.length],
                    carro: i.isEven ? PropHistoria.carroRival : null,
                    capitulo: [1, 7, 22, 29, 30][i % 5],
                    reduzir: reduzir,
                  ));
                  i++;
                }
              }
            }
            await monta(t, atores);
            expect(t.takeException(), isNull, reason: '$acao h=$h reduzir=$reduzir');
          }
        }
      }
    });

    testWidgets('cada Expressao em cada altura, com e sem espelho, monta sem exceção', (t) async {
      for (final h in _alturas) {
        await monta(t, [
          for (final e in Expressao.values)
            for (final espelhado in [false, true])
              AtorHistoria(
                aparencia: ElencoTurismo.kim,
                altura: h,
                pose: const PoseAtor(tempo: .8),
                expressao: e,
                espelhado: espelhado,
              ),
        ]);
        expect(t.takeException(), isNull);
      }
    });

    testWidgets('a caixa tem .62H × H; rosto ganha expressão, olhar e visema', (t) async {
      await monta(t, [
        const AtorHistoria(
          aparencia: ElencoIngles.sarah,
          altura: 200,
          pose: PoseAtor(),
          visema: Visema.d,
          expressao: Expressao.surpreso,
          olhar: Offset(.5, 0),
        ),
      ]);
      expect(t.getSize(find.byType(AtorHistoria)), const Size(124, 200));
      final rosto = t.widget<RostoPersonagem>(find.byType(RostoPersonagem));
      expect(rosto.expressao, Expressao.surpreso);
      expect(rosto.visema, Visema.d);
      expect(rosto.olhar, const Offset(.5, 0));
      expect(rosto.tamanho, closeTo(200 * .58, 1e-9));
    });

    testWidgets('pula sobe a cabeça; com reduzir animações fica no chão', (t) async {
      Future<double> topoDaCabeca(PoseAtor pose, {bool reduzir = false}) async {
        await monta(t, [AtorHistoria(aparencia: ElencoIngles.ben, altura: 200, pose: pose, reduzir: reduzir)]);
        return t.getTopLeft(find.byType(RostoPersonagem)).dy;
      }

      final parado = await topoDaCabeca(const PoseAtor());
      final noAr = await topoDaCabeca(const PoseAtor(acao: AcaoAtor.pula, progresso: .5));
      final reduzido = await topoDaCabeca(const PoseAtor(acao: AcaoAtor.pula, progresso: .5), reduzir: true);
      expect(noAr, lessThan(parado - 200 * .15));
      expect(reduzido, closeTo(parado, .5));
      // sentado e no carro, o corpo desce
      expect(await topoDaCabeca(const PoseAtor(sentado: true)), greaterThan(parado + 200 * .15));
      expect(await topoDaCabeca(const PoseAtor(noCarro: true)), greaterThan(parado + 200 * .1));
    });

    testWidgets('dormindo fecha os olhos; noCarro desenha o carro; segura desenha o prop', (t) async {
      await monta(t, [
        const AtorHistoria(
          aparencia: ElencoTurismo.max,
          altura: 200,
          pose: PoseAtor(dormindo: true),
          olhos: 1,
          segura: PropHistoria.trofeu,
        ),
      ]);
      expect(t.widget<RostoPersonagem>(find.byType(RostoPersonagem)).olhos, 0);
      List<PropHistoria> props() => [
            for (final c in t.widgetList<CustomPaint>(find.byType(CustomPaint)))
              if (c.painter case final PropPainter p) p.prop,
          ];
      expect(props(), [PropHistoria.trofeu]);

      await monta(t, [
        const AtorHistoria(
          aparencia: ElencoTurismo.max,
          altura: 200,
          pose: PoseAtor(noCarro: true),
          carro: PropHistoria.carroRival,
        ),
      ]);
      expect(props(), [PropHistoria.carroRival]);
      expect(t.widget<RostoPersonagem>(find.byType(RostoPersonagem)).olhos, 1);

      // fora do carro, o `carro` é ignorado; `nada` = mãos vazias
      await monta(t, [
        const AtorHistoria(
          aparencia: ElencoIngles.voce,
          altura: 200,
          pose: PoseAtor(),
          carro: PropHistoria.carro,
          segura: PropHistoria.nada,
        ),
      ]);
      expect(props(), isEmpty);

      // no carro sem dizer qual: o do Team Star
      await monta(t, [const AtorHistoria(aparencia: ElencoIngles.voce, altura: 200, pose: PoseAtor(noCarro: true))]);
      expect(props(), [PropHistoria.carro]);
    });

    testWidgets('espelhado vira o corpo (Transform.flip)', (t) async {
      await monta(t, [const AtorHistoria(aparencia: ElencoIngles.emma, altura: 200, pose: PoseAtor(), espelhado: true)]);
      final flips = t.widgetList<Transform>(find.byType(Transform)).where((tr) => tr.transform.storage[0] < 0);
      expect(flips, isNotEmpty);
    });

    test('boca() e mao() ficam dentro da caixa', () {
      for (final h in _alturas) {
        final caixa = Offset.zero & Size(AtorHistoria.largura(h), h);
        expect(caixa.contains(AtorHistoria.boca(h)), isTrue, reason: 'boca h=$h');
        // a boca fica no rosto (alto da caixa, no centro)
        expect(AtorHistoria.boca(h).dx, closeTo(caixa.width / 2, 1e-9));
        expect(AtorHistoria.boca(h).dy, inInclusiveRange(h * .3, h * .45));
        for (final direita in [true, false]) {
          final m = AtorHistoria.mao(h, direita: direita);
          expect(caixa.contains(m), isTrue, reason: 'mão h=$h direita=$direita');
          expect(m.dx > caixa.width / 2, direita);
        }
      }
    });

    test('props grandes encolhem para caber na mão', () {
      for (final p in PropHistoria.values) {
        final s = AtorHistoria.tamanhoNaMao(p, 200);
        expect(s.longestSide, lessThanOrEqualTo(200 * .3 + 1e-9), reason: '$p');
      }
    });
  });

  group('ElencoTurismo', () {
    test('de() para os 11 ids; narrador sem corpo; max e kim são os extras', () {
      for (final id in _ids) {
        expect(ElencoTurismo.de(id), isNotNull, reason: id);
      }
      expect(personagensHistoria, _ids.toSet());
      expect(ElencoTurismo.de(narrador), isNull);
      expect(ElencoTurismo.de('max'), same(ElencoTurismo.max));
      expect(ElencoTurismo.de('kim'), same(ElencoTurismo.kim));
      expect(ElencoTurismo.de('voce'), same(ElencoIngles.voce));
      expect(ElencoTurismo.de('dra-lee'), same(ElencoIngles.draLee));
      // aparências da tabela 5.6
      expect(ElencoTurismo.max.roupa, const Color(0xFF26262E));
      expect(ElencoTurismo.max.detalhe, const Color(0xFFFF8A1F));
      expect(ElencoTurismo.kim.estilo, Cabelo.bob);
      expect(ElencoTurismo.kim.fone && ElencoTurismo.kim.brincos && ElencoTurismo.kim.cilios, isTrue);
    });

    test('perfilDeVoz: os 11 soam diferentes e seguem a tabela 5.6', () {
      final perfis = {for (final id in _ids) id: ElencoTurismo.perfilDeVoz(id)};
      expect(perfis.values.toSet(), hasLength(11));
      expect(perfis['voce'], const PerfilVoz());
      expect(perfis['mike'], const PerfilVoz(tom: .88));
      expect(perfis['sarah'], const PerfilVoz(tom: 1.10, variante: 1));
      expect(perfis['ana'], const PerfilVoz(tom: 1.18));
      expect(perfis['ben'], const PerfilVoz(tom: .80, variante: 1));
      expect(perfis['emma'], const PerfilVoz(tom: 1.05, variante: 1));
      expect(perfis['lucas'], const PerfilVoz(tom: 1.22));
      expect(perfis['julia'], const PerfilVoz(tom: 1.30, variante: 1));
      expect(perfis['dra-lee'], const PerfilVoz(tom: .98, variante: 1));
      expect(perfis['max'], const PerfilVoz(tom: .76));
      expect(perfis['kim'], const PerfilVoz(tom: 1.20, variante: 1));
      expect(ElencoTurismo.perfilDeVoz(narrador), const PerfilVoz(tom: .95));
      expect(ElencoTurismo.perfilDeVoz('ninguem'), PerfilVoz.padrao);
    });

    test('nomes, cores dos chips e carros', () {
      expect(ElencoTurismo.nomeDe('voce'), 'Você');
      expect(ElencoTurismo.nomeDe('dra-lee'), 'Dra. Lee');
      expect(ElencoTurismo.nomeDe('max'), 'Max');
      expect(ElencoTurismo.nomeDe('kim'), 'Kim');
      expect(ElencoTurismo.corDe('kim'), ElencoTurismo.kim.roupa);
      expect(ElencoTurismo.corDe(narrador), const Color(0xFF3A2A33));
      expect(ElencoTurismo.carroDe('max'), PropHistoria.carroRival);
      for (final id in _ids.where((id) => id != 'max')) {
        expect(ElencoTurismo.carroDe(id), PropHistoria.carro);
      }
    });
  });
}
