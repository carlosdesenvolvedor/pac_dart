// Chuva no inglês com o baralho por nível: cada nível traz palavras NOVAS e MAIS delas (8, 10, 12…), e a
// que a pessoa errou ou deixou cair volta pra revisar 🔁 (na mesma fase, poucas palavras depois, e na
// frente do nível seguinte). O motor sem baralho (Dart, C#) segue igual: sorteio nas listas e nível a cada 8.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/baralho_fases.dart';
import 'package:pac_dart/features/arcade/domain/palavras_dart.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/tiro_engine.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/linha_fase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fonte de mentira: devolve as cartas em ordem (em ciclo) e guarda o que pediram pra evitar.
class _FonteFake implements FonteDePalavras {
  final List<CartaFase> cartas;
  final List<Set<String>> evitados = [];
  int _i = 0;
  _FonteFake(this.cartas);

  @override
  CartaFase proxima({Set<String> evitar = const {}, String? outraInicialQue}) {
    evitados.add(evitar);
    return cartas[_i++ % cartas.length];
  }

  @override
  CartaFase proximaExtra({Set<String> evitar = const {}, String? outraInicialQue}) =>
      proxima(evitar: evitar, outraInicialQue: outraInicialQue);
}

/// Nasce uma palavra (a tela está vazia) e ela é digitada inteira. Devolve o texto.
String _nasceEDestroi(TiroEngine e) {
  e.tick(e.intervaloSpawn);
  final p = e.ativas.single;
  for (final ch in p.texto.split('')) {
    e.teclar(ch);
  }
  expect(e.ativas, isEmpty);
  return p.texto;
}

Widget _app(Widget home) => MaterialApp(theme: Mixart.tema(), home: home);

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

/// Digita como o campo invisível recebe (o texto inteiro de uma vez; zera de tempos em tempos).
class _Teclado {
  String buffer = '';
  Future<void> digitar(WidgetTester tester, String s) async {
    if (buffer.length + s.length > 180) {
      buffer = '';
      await tester.enterText(find.byType(TextField), '');
    }
    buffer += s;
    await tester.enterText(find.byType(TextField), buffer);
    await tester.pump();
  }
}

/// As palavras caindo agora (de [pool]), da mais baixa pra mais alta.
List<String> _naTela(WidgetTester tester, Set<String> pool) {
  final achadas = [
    for (final e in find.byWidgetPredicate((w) => w is RichText && pool.contains(w.text.toPlainText())).evaluate())
      ((e.widget as RichText).text.toPlainText(), tester.getTopLeft(find.byWidget(e.widget)).dy),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final (w, _) in achadas) w];
}

Finder _rich(String texto) => find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == texto);

/// O chip de [w] tem o 🔁 (a marca fica ao lado do texto, na mesma Row do chip).
bool _marcada(String w) {
  final row = find.ancestor(of: _rich(w), matching: find.byType(Row)).first;
  return find.descendant(of: row, matching: find.byType(MarcaRevisao)).evaluate().isNotEmpty;
}

String _nivelNoPlacar(WidgetTester tester) =>
    tester.widget<ChipPlacar>(find.byWidgetPredicate((w) => w is ChipPlacar && w.k == 'NÍVEL')).v;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Linguagem.atual = Linguagem.dart);

  group('TiroEngine com a fonte (baralho)', () {
    test('as palavras saem da fonte, o 🔁 vem junto e a fonte evita as que já estão na tela', () {
      final f = _FonteFake(const [
        CartaFase('alpha', OrigemCarta.nova),
        CartaFase('bravo', OrigemCarta.errou),
        CartaFase('charlie', OrigemCarta.lenta),
      ]);
      final e = TiroEngine(rnd: Random(1), fonte: f);
      e.tick(0.01);
      e.tick(e.intervaloSpawn);
      e.tick(e.intervaloSpawn);
      expect([for (final p in e.ativas) p.texto], ['alpha', 'bravo', 'charlie']);
      expect([for (final p in e.ativas) p.revisao], [false, true, true]);
      expect(f.evitados, [<String>{}, {'alpha'}, {'alpha', 'bravo'}]);
    });

    test('com o BaralhoFases de verdade, nascem na ordem do baralho da fase', () {
      final b = BaralhoFases(rnd: Random(2), reenfileirarNaFase: true);
      final d = b.abrirFase(fase: 1, pool: palavrasCurtasEn, tamanho: BaralhoFases.tamanhoChuva(1));
      final e = TiroEngine(rnd: Random(2), fonte: b, metaDoNivel: BaralhoFases.tamanhoChuva);
      final saidas = [for (var i = 0; i < d.cartas.length; i++) _nasceEDestroi(e)];
      expect(saidas, d.palavras);
      expect(e.nivel, 2, reason: '8 destruídas: sobe');
    });

    test('metaDoNivel: sobe aos 8, depois a cada 10, 12… (não mais a cada 8)', () {
      final f = _FonteFake([for (final w in ['ab', 'cd', 'ef', 'gh']) CartaFase(w, OrigemCarta.nova)]);
      final e = TiroEngine(rnd: Random(1), fonte: f, metaDoNivel: BaralhoFases.tamanhoChuva);
      final niveis = <int>[];
      for (var i = 0; i < 8 + 10 + 12; i++) {
        _nasceEDestroi(e);
        niveis.add(e.nivel);
      }
      expect(niveis[6], 1);
      expect(niveis[7], 2, reason: '8ª');
      expect(niveis[16], 2, reason: '17ª: ainda no 2 (no Dart já seria 3)');
      expect(niveis[17], 3, reason: '18ª = 8 + 10');
      expect(niveis[28], 3);
      expect(niveis[29], 4, reason: '30ª = 8 + 10 + 12');
    });

    test('metaDoNivel: o baralho troca por nível, mas a velocidade aperta a cada 8 como no Dart', () {
      final f = _FonteFake([for (final w in ['ab', 'cd', 'ef', 'gh']) CartaFase(w, OrigemCarta.nova)]);
      final ingles = TiroEngine(rnd: Random(1), fonte: f, metaDoNivel: BaralhoFases.tamanhoChuva);
      final dart = TiroEngine(rnd: Random(1), fonte: _FonteFake(f.cartas));
      for (var i = 0; i < 92; i++) {
        _nasceEDestroi(ingles);
        _nasceEDestroi(dart);
        expect(ingles.velocidade, dart.velocidade, reason: '${i + 1}ª');
        expect(ingles.intervaloSpawn, dart.intervaloSpawn, reason: '${i + 1}ª');
      }
      expect(ingles.nivelDoRitmo, TiroEngine.nivelMaximo, reason: 'o máximo aos 56, não aos 92');
      expect(ingles.nivel, TiroEngine.nivelMaximo);
      // aos 17: nível (do baralho) 2, ritmo 3
      final e = TiroEngine(rnd: Random(1), fonte: _FonteFake(f.cartas), metaDoNivel: BaralhoFases.tamanhoChuva);
      for (var i = 0; i < 17; i++) {
        _nasceEDestroi(e);
      }
      expect((e.nivel, e.nivelDoRitmo), (2, 3));
    });

    test('sem a fonte: sorteio nas listas e nível a cada 8, como sempre', () {
      final e = TiroEngine(rnd: Random(1));
      final textos = <String>[];
      for (var i = 0; i < 16; i++) {
        textos.add(_nasceEDestroi(e));
        if (i == 7) expect(e.nivel, 2);
      }
      expect(e.nivel, 3);
      expect(palavrasCurtas, containsAll(textos.take(8)), reason: 'nível 1: só as curtas');
      expect(e.ativas.every((p) => !p.revisao), isTrue);
    });

    test('ultimasCaidas: as que tocaram o chão no último tick; esvazia a cada tick, até depois do fim', () {
      final e = TiroEngine(rnd: Random(1));
      e.tick(0.01);
      final id = e.ativas.single.id;
      e.tick(0.01);
      expect(e.ultimasCaidas, isEmpty);
      e.tick(20); // nasce outra e as duas despencam
      expect(e.ultimasCaidas.map((p) => p.id), contains(id));
      expect(e.vidas, lessThan(TiroEngine.vidasIniciais));
      e.tick(0.01);
      expect(e.ultimasCaidas, isEmpty, reason: 'a mesma lista, esvaziada');
      for (var i = 0; i < 10 && !e.fim; i++) {
        e.tick(20);
      }
      expect(e.fim, isTrue);
      e.tick(0.01);
      expect(e.ultimasCaidas, isEmpty, reason: 'depois do fim também');
    });
  });

  testWidgets('inglês: a largada mostra o nível 1; a que escapou volta 🔁; o nível 2 traz palavras novas e mais delas',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LinhaFase), findsOneWidget);
    expect(find.text('Nível 1 · 8 palavras · 8 novas'), findsOneWidget);
    await _largada(tester);
    expect(find.byType(LinhaFase), findsNothing, reason: 'só na largada');

    final reserva = {...palavrasCurtasEn, ...palavrasMediasEn, ...palavrasLongasEn};
    final teclado = _Teclado();
    String? escapou;
    final nivel1 = <String>[], nivel2 = <String>[];
    var destruidas1 = 0, destruidas2 = 0;
    var fase = 1;
    var voltouNaFase1 = false, marcadaNaFase1 = false, marcadaNaFase2 = false, outraMarcada = false;
    String? aviso2;
    var naTelaAntes = <String>{};
    for (var i = 0; i < 4000 && fase < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final naTela = _naTela(tester, reserva);
      // as que acabaram de nascer
      for (final w in naTela) {
        if (naTelaAntes.contains(w)) continue;
        (fase == 1 ? nivel1 : nivel2).add(w);
        final marcada = _marcada(w);
        if (w == escapou) {
          if (fase == 1) {
            voltouNaFase1 = true;
            marcadaNaFase1 |= marcada;
          } else {
            marcadaNaFase2 |= marcada;
          }
        } else if (marcada) {
          outraMarcada = true;
        }
      }
      for (final w in naTela) {
        escapou ??= w;
        // a escolhida sai sempre com 2 teclas erradas (conta como errada: volta pra revisar)
        await teclado.digitar(tester, w == escapou ? '${w[0]}##${w.substring(1)}' : w);
        if (fase == 1) {
          destruidas1++;
          if (find.textContaining('NÍVEL 2 ·').evaluate().isNotEmpty) {
            aviso2 = tester.widget<Text>(find.textContaining('NÍVEL 2 ·')).data;
            fase = 2;
          }
        } else {
          destruidas2++;
          if (find.textContaining('NÍVEL 3 ·').evaluate().isNotEmpty) fase = 3;
        }
        if (fase == 3) break;
      }
      naTelaAntes = _naTela(tester, reserva).toSet();
    }
    expect(fase, 3, reason: 'chegou ao nível 3');
    expect(tester.takeException(), isNull);

    // nível 1: 8 palavras, só curtas; a escapada voltou na mesma fase com o 🔁
    expect(destruidas1, 8);
    expect(palavrasCurtasEn, containsAll(nivel1.toSet()));
    expect(voltouNaFase1, isTrue, reason: '"$escapou" (2 erros) volta 3–5 palavras depois');
    expect(marcadaNaFase1, isTrue, reason: 'com o 🔁 no chip');
    expect(outraMarcada, isFalse, reason: 'as limpas não levam 🔁');

    // nível 2: MAIS palavras (10), quase todas novas, e a escapada de volta 🔁
    expect(destruidas2, 10, reason: 'o nível 2 pede 10 (o 1 pedia 8)');
    expect(aviso2, matches(RegExp(r'NÍVEL 2 · 10 palavras · \d+ novas · \d+ pra revisar 🔁')));
    expect(nivel2, contains(escapou));
    expect(marcadaNaFase2, isTrue);
    // fora a revisão (que volta de novo enquanto sair com erro), só palavras que o nível 1 não trouxe
    final outras = nivel2.where((w) => w != escapou).toList();
    expect(outras.toSet().intersection(nivel1.toSet()), isEmpty, reason: '$nivel2 × $nivel1');
    expect(outras.toSet(), hasLength(outras.length), reason: 'sem repetir');
    expect(outras.length, greaterThanOrEqualTo(7));
    expect(_nivelNoPlacar(tester), '3');
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês: a palavra que cai no chão volta poucas palavras depois com o 🔁', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 7)));
    await tester.pump(const Duration(milliseconds: 500));
    await _largada(tester);

    final reserva = {...palavrasCurtasEn, ...palavrasMediasEn, ...palavrasLongasEn};
    final teclado = _Teclado();
    // a 1ª palavra cai sozinha (ninguém digita): ~18 s; as outras que nascem são destruídas, menos ela
    await tester.pump(const Duration(milliseconds: 60));
    final caiu = _naTela(tester, reserva).single;
    var nasceramDepois = 0;
    var naTelaAntes = {caiu};
    var jaCaiu = false;
    var voltou = false;
    for (var i = 0; i < 1500 && !voltou; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final naTela = _naTela(tester, reserva);
      if (!jaCaiu && !naTela.contains(caiu)) jaCaiu = true;
      for (final w in naTela) {
        if (naTelaAntes.contains(w) || !jaCaiu) continue;
        if (w == caiu) {
          voltou = true;
          expect(_marcada(w), isTrue, reason: 'voltou com o 🔁');
        } else {
          nasceramDepois++;
        }
      }
      if (voltou) break;
      // as outras são destruídas (só a escolhida cai)
      for (final w in naTela) {
        if (w != caiu) await teclado.digitar(tester, w);
      }
      naTelaAntes = _naTela(tester, reserva).toSet();
    }
    expect(jaCaiu, isTrue);
    expect(voltou, isTrue, reason: '"$caiu" voltou');
    expect(nasceramDepois, lessThanOrEqualTo(6), reason: 'até ~5 palavras depois de cair');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês: a palavra que demorou volta 🔁 no nível 2; o tempo da pausa não conta', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var agora = 0;
    ChuvaPage.relogioDeTeste = () => agora;
    addTearDown(() => ChuvaPage.relogioDeTeste = null);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 500));
    await _largada(tester);

    final reserva = {...palavrasCurtasEn, ...palavrasMediasEn, ...palavrasLongasEn};
    final teclado = _Teclado();
    final feitas = <String>[];
    String? lenta, pausada;
    var fase = 1;
    final nivel2 = <String>[];
    var lentaMarcada = false;
    var naTelaAntes = <String>{};
    for (var i = 0; i < 3000 && nivel2.length < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      final naTela = _naTela(tester, reserva);
      if (fase == 2) {
        for (final w in naTela) {
          if (naTelaAntes.contains(w)) continue;
          nivel2.add(w);
          if (w == lenta) lentaMarcada = _marcada(w);
          if (w == pausada) expect(_marcada(w), isFalse, reason: 'a pausa não fez "$w" lenta');
        }
      }
      for (final w in naTela) {
        if (fase == 2 && nivel2.length >= 6) break;
        final n = feitas.length;
        // 1ª tecla trava a mira e liga o relógio; o resto sai depois de 100 ms por letra (a 3ª: 600)
        await teclado.digitar(tester, w[0]);
        if (fase == 1 && n == 3) {
          // a 4ª: pausa longa no meio da palavra (o relógio congela)
          pausada = w;
          await tester.tap(find.byTooltip('Pausar (Esc)'));
          await tester.pump();
          agora += 120000;
          await tester.tap(find.text('Continuar'));
          await tester.pump();
        }
        if (fase == 1 && n == 2) lenta = w;
        agora += (w == lenta && fase == 1 ? 600 : 100) * (w.length - 1);
        await teclado.digitar(tester, w.substring(1));
        feitas.add(w);
        if (fase == 1 && find.textContaining('NÍVEL 2 ·').evaluate().isNotEmpty) {
          expect(feitas, hasLength(8));
          expect(find.text('🏜️ NÍVEL 2 · 10 palavras · 9 novas · 1 pra revisar 🔁'), findsOneWidget);
          fase = 2;
        }
      }
      naTelaAntes = _naTela(tester, reserva).toSet();
    }
    expect(fase, 2);
    expect(nivel2, contains(lenta), reason: 'a que demorou (6× o normal) volta logo no nível 2: $nivel2');
    expect(lentaMarcada, isTrue);
    expect(nivel2, isNot(contains(pausada)));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês no celular 360, paleta escura e clara: a linha da largada e a chuva cabem', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    final antes = Mixart.atual;
    addTearDown(() => Mixart.atual = antes);
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final p in [Paleta.mixart, Paleta.flutterClaro]) {
      Mixart.atual = p;
      await tester.pumpWidget(_app(ChuvaPage(key: ValueKey(p.nome), semente: 5)));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(LinhaFase), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '${p.nome}: largada');
      await _largada(tester);
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(tester.takeException(), isNull, reason: '${p.nome}: chuva');
      await tester.pumpWidget(Container());
    }
  });

  testWidgets('Dart: sem linha da largada, sem 🔁, o sorteio de sempre e o nível a cada 8', (tester) async {
    expect(Linguagem.atual, Linguagem.dart);
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(LinhaFase), findsNothing);
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60));
    final replica = TiroEngine(rnd: Random(5))..tick(0.06);
    final pool = {...palavrasCurtas, ...palavrasMedias, ...palavrasLongas};
    expect(_naTela(tester, pool), [replica.ativas.single.texto], reason: 'o mesmo sorteio de antes');

    final teclado = _Teclado();
    var destruidas = 0;
    String? primeira;
    for (var i = 0; i < 2000 && destruidas < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      for (final w in _naTela(tester, pool)) {
        primeira ??= w;
        await teclado.digitar(tester, w == primeira ? '${w[0]}##${w.substring(1)}' : w);
        destruidas++;
        if (destruidas == 8) break;
      }
      expect(find.byType(MarcaRevisao), findsNothing);
    }
    expect(destruidas, 8);
    expect(_nivelNoPlacar(tester), '2', reason: 'a cada 8, como sempre');
    expect(find.textContaining('NÍVEL 2 ·'), findsNothing, reason: 'o aviso do baralho é só do inglês');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });
}
