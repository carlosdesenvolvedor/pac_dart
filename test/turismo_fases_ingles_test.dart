// Turismo no inglês com o baralho por FASE: cada corrida é uma fase — as palavras dos portais saem do
// baralho na ordem (as que voltam pra revisar 🔁 logo no começo), a pista maior traz mais palavras, a que
// você errou volta como combustível ainda na corrida e na frente da próxima, marcada com o 🔁 — e o
// Dart (e o modo setas) seguem sem baralho nenhum.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/baralho_fases.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/turismo_page.dart';
import 'package:pac_dart/features/arcade/presentation/voz_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/linha_fase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Mudo implements FalanteDoJogo {
  @override
  bool get liberado => true;
  @override
  void falar(String palavra) {}
  @override
  void parar() {}
}

/// O vocabulário de reserva do inglês (arcade solto, sem o curso) — o mesmo que a página usa nos testes.
VocabularioJogo get _reserva => VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn);

Widget _app(Widget home) => MaterialApp(theme: Mixart.tema(), home: home);

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

/// O texto (simples) do Text.rich com a chave [k], ou null se não está na tela.
String? _naTela(WidgetTester tester, Key k) {
  final f = find.descendant(of: find.byKey(k), matching: find.byType(RichText));
  if (f.evaluate().isEmpty) return null;
  return tester.widget<RichText>(f.first).text.toPlainText();
}

/// Digita no campo invisível, uma tecla por pump (o campo esvazia sozinho aos 200; aqui antes disso).
class _Teclado {
  String _texto = '';
  Future<void> digitar(WidgetTester tester, String s) async {
    if (_texto.length > 150) {
      _texto = '';
      await tester.enterText(find.byType(TextField), '');
    }
    for (final ch in s.split('')) {
      _texto += ch;
      await tester.enterText(find.byType(TextField), _texto);
      await tester.pump();
    }
  }
}

/// Uma tecla que NÃO é [c].
String _errada(String c) => c == 'z' ? 'q' : 'z';

/// Engine do inglês com o baralho da 1ª fase aberto pra pista [p].
(TurismoEngine, BaralhoFases, DeckFase) _comBaralho(PistaGt p, int semente, {bool reenfileirar = false}) {
  final v = _reserva;
  final b = BaralhoFases(rnd: Random(semente), reenfileirarNaFase: reenfileirar);
  // como a página: uma carta por portal (a 2ª saída vem de fora do baralho)
  final d = b.abrirFase(fase: 1, pool: p.vocabularioCom(v), tamanho: TurismoEngine.portaisDaPista(p));
  final e = TurismoEngine(
    pista: p,
    rnd: Random(semente),
    vocabulario: p.vocabularioCom(v),
    traducoes: v.traducoes,
    esperaPalavra: true,
    semLimiteDeTempo: true,
    fonte: b,
  );
  return (e, b, d);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  group('motor com o baralho (fonte)', () {
    test('vagasDePalavras = as palavras de portal de cada pista (com e sem baralho)', () {
      for (final p in pistasGt) {
        final dart = TurismoEngine(pista: p, rnd: Random(1));
        final n = dart.portais.fold<int>(0, (s, x) => s + x.palavras.length);
        expect(TurismoEngine.vagasDePalavras(p), n, reason: 'pista ${p.numero}');
        final (e, _, _) = _comBaralho(p, 1);
        expect(e.portais.fold<int>(0, (s, x) => s + x.palavras.length), n, reason: 'pista ${p.numero}');
      }
      // a pista seguinte nunca traz menos palavras
      for (var i = 1; i < pistasGt.length; i++) {
        expect(TurismoEngine.vagasDePalavras(pistasGt[i]),
            greaterThanOrEqualTo(TurismoEngine.vagasDePalavras(pistasGt[i - 1])));
      }
    });

    test('pistas de uma saída: os portais seguem a ordem do baralho, todas novas e sem repetir', () {
      for (final p in pistasGt.where((p) => !p.duasSaidas)) {
        final (e, _, d) = _comBaralho(p, 7);
        final palavras = [for (final x in e.portais) x.palavras.single];
        expect(palavras, d.palavras, reason: 'pista ${p.numero}');
        expect(palavras.toSet().length, palavras.length, reason: 'o pool da reserva cobre a pista');
        expect(d.novas, d.cartas.length);
        expect(e.portais.every((x) => !x.ehRevisao(0)), isTrue, reason: '1ª fase sem nada pra revisar');
      }
    });

    test('pistas 7–10: as duas saídas nunca começam com a mesma letra (50 sementes)', () {
      for (final p in pistasGt.where((p) => p.duasSaidas)) {
        final pool = p.vocabularioCom(_reserva).toSet();
        for (var s = 0; s < 50; s++) {
          final (e, _, _) = _comBaralho(p, s);
          for (final x in e.portais) {
            expect(x.palavras, hasLength(2));
            expect(x.palavras[0][0].toLowerCase(), isNot(x.palavras[1][0].toLowerCase()),
                reason: 'pista ${p.numero}, semente $s: ${x.palavras}');
            expect(pool.containsAll(x.palavras), isTrue);
          }
        }
      }
    });

    test('pistas 7–10: uma carta por portal (a linha conta o que se digita); fugir da 🔁 a traz como combustível',
        () {
      final v = _reserva;
      for (final p in pistasGt.where((p) => p.duasSaidas)) {
        final n = TurismoEngine.portaisDaPista(p);
        final b = BaralhoFases(rnd: Random(11), reenfileirarNaFase: true);
        final pool = p.vocabularioCom(v);
        final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: n);
        expect(d1.cartas, hasLength(n));
        expect(d1.resumo(), startsWith('$n palavras · '), reason: 'pista ${p.numero}: um por portal, não 2 × $n');
        // a 1ª corrida: metade das palavras com erro
        for (var i = 0; i < n; i++) {
          b.registrar(d1.palavras[i], erros: i.isEven ? 1 : 0);
        }
        final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: n);
        expect(d2.revisar, (n * BaralhoFases.fracaoRevisao).round(), reason: 'o teto sobre os portais');
        final e = TurismoEngine(pista: p, rnd: Random(11), vocabulario: pool, fonte: b, esperaPalavra: true);
        expect([for (final x in e.portais) x.palavras[0]], d2.palavras, reason: 'a 1ª saída segue o baralho');
        for (final x in e.portais) {
          expect(x.ehRevisao(1), isFalse, reason: 'a 2ª saída vem de fora do baralho');
          expect(x.palavras[0][0].toLowerCase(), isNot(x.palavras[1][0].toLowerCase()));
        }
        expect(e.portais.first.ehRevisao(0), isFalse, reason: 'a 1ª é nova');
        // o 1º portal: digita a saída SEM 🔁 — num portal com 🔁, a página devolve a pulada pro baralho
        final x = e.portais.first;
        for (final ch in x.palavras[1].split('')) {
          e.teclar(ch);
        }
        expect(x.digitado, 1);
        // (a pulada de verdade é a 🔁 de um portal já passado: aqui, a de um portal mais à frente, que não
        // é o seguinte — o combustível nunca adianta o portal seguinte)
        final i = e.portais.indexWhere((p) => p.ehRevisao(0), 2);
        final pulada = e.portais[i].palavras[0];
        b.devolver(pulada);
        var tiradas = 0;
        while (tiradas < 8 && e.palavraGas != pulada) {
          final gas = e.palavraGas;
          if (gas == null) break;
          for (final ch in gas.split('')) {
            e.teclar(ch);
          }
          tiradas++;
        }
        expect(e.palavraGas, pulada, reason: 'pista ${p.numero}: a 🔁 pulada volta como combustível');
        expect(e.palavraGasRevisao, isTrue);
        expect(tiradas, inInclusiveRange(BaralhoFases.atrasoMin - 1, BaralhoFases.atrasoMax));
      }
    });

    test('a palavra com 2 erros volta como combustível 3–5 palavras depois, marcada pra revisar', () {
      final (e, b, _) = _comBaralho(pistasGt[0], 2, reenfileirar: true);
      final w = e.portais.first.palavras.single;
      expect(e.teclar(w[0]), TeclaGt.avancou);
      expect(e.teclar(_errada(w[1])), TeclaGt.errou);
      expect(e.teclar(_errada(w[1])), TeclaGt.errou);
      TeclaGt r = TeclaGt.nada;
      for (final ch in w.substring(1).split('')) {
        r = e.teclar(ch);
      }
      expect(r, TeclaGt.completou);
      b.registrar(w, erros: 2); // o que a página faz ao completar
      expect(e.palavraGas, isNotNull);
      expect(e.palavraGasRevisao, isFalse, reason: 'a 1ª de combustível já tinha saído');
      var tiradas = 0;
      while (tiradas < 8 && e.palavraGas != w) {
        expect(e.palavraGasRevisao, isFalse);
        for (final ch in e.palavraGas!.split('')) {
          e.teclar(ch);
        }
        tiradas++;
      }
      expect(e.palavraGas, w);
      expect(e.palavraGasRevisao, isTrue);
      expect(tiradas, inInclusiveRange(BaralhoFases.atrasoMin, BaralhoFases.atrasoMax));
      // digitada, a seguinte não é mais revisão
      for (final ch in w.split('')) {
        e.teclar(ch);
      }
      expect(e.palavraGasRevisao, isFalse);
    });

    test('a de combustível não adianta a palavra do portal seguinte', () {
      final (e, _, _) = _comBaralho(pistasGt[0], 4);
      for (var k = 0; k < 30; k++) {
        final p = e.portalParaDigitar;
        if (p != null) {
          for (final ch in p.palavras.single.split('')) {
            e.teclar(ch);
          }
          continue;
        }
        final gas = e.palavraGas!;
        expect(e.proximoPortal?.palavras ?? const <String>[], isNot(contains(gas)));
        for (final ch in gas.split('')) {
          e.teclar(ch);
        }
      }
    });

    test('a 2ª fase põe a errada logo no 2º portal (revisão) e o resto é novo', () {
      final p = pistasGt[0];
      final v = _reserva;
      final b = BaralhoFases(rnd: Random(5), reenfileirarNaFase: true);
      final d1 = b.abrirFase(fase: 1, pool: p.vocabularioCom(v), tamanho: TurismoEngine.vagasDePalavras(p));
      final e1 = TurismoEngine(pista: p, rnd: Random(5), vocabulario: p.vocabularioCom(v), fonte: b, esperaPalavra: true);
      final errou = e1.portais[0].palavras.single;
      final limpa = e1.portais[1].palavras.single;
      b.registrar(errou, erros: 1);
      b.registrar(limpa);
      final p2 = pistasGt[1];
      final d2 = b.abrirFase(fase: 2, pool: p2.vocabularioCom(v), tamanho: TurismoEngine.vagasDePalavras(p2));
      expect(d2.cartas.length, greaterThan(d1.cartas.length), reason: 'a pista 2 traz mais palavras');
      final e2 = TurismoEngine(pista: p2, rnd: Random(5), vocabulario: p2.vocabularioCom(v), fonte: b, esperaPalavra: true);
      expect(e2.portais[0].ehRevisao(0), isFalse, reason: 'a 1ª é nova');
      expect(e2.portais[1].palavras.single, errou);
      expect(e2.portais[1].ehRevisao(0), isTrue);
      expect([for (final x in e2.portais) x.palavras.single], isNot(contains(limpa)),
          reason: 'a que saiu limpa não volta enquanto houver novas');
      expect(d2.revisar, 1);
      expect(d2.novas, d2.cartas.length - 1);
    });
  });

  group('na tela', () {
    setUp(() {
      VozDoJogo.falanteDeTeste = () => _Mudo();
    });
    tearDown(() {
      VozDoJogo.falanteDeTeste = null;
      Linguagem.atual = Linguagem.dart;
    });

    for (final tamanho in const [Size(1000, 1400), Size(360, 780)]) {
      testWidgets(
          'inglês ${tamanho.width.round()}px: a 2ª corrida é maior, traz novas e abre com a errada da 1ª marcada 🔁',
          (tester) async {
        Linguagem.atual = Linguagem.ingles;
        SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true, 'turismo_pista_max': 2});
        tester.view.physicalSize = tamanho;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        // a largada diz o que a fase traz
        expect(find.byType(LinhaFase), findsOneWidget);
        expect(find.text('Pista 1 · 47 palavras · 47 novas'), findsOneWidget);
        await _largada(tester);
        expect(find.byType(LinhaFase), findsNothing);
        expect(find.byType(MarcaRevisao), findsNothing, reason: '1ª corrida: nada pra revisar');

        // 1ª corrida: a do portal com um erro no meio, depois uma de combustível limpa
        var teclado = _Teclado();
        final w0 = _naTela(tester, const Key('turismo-palavra-0'))!;
        expect(_reserva.curtas, contains(w0));
        await teclado.digitar(tester, w0[0]);
        await teclado.digitar(tester, _errada(w0[1]));
        await teclado.digitar(tester, w0.substring(1));
        final g0 = _naTela(tester, const Key('turismo-gas'))!;
        expect(g0, isNot(w0));
        await teclado.digitar(tester, g0);
        expect(tester.takeException(), isNull);

        // sai e corre a pista 2
        await tester.tap(find.byTooltip('Pausar (Esc)'));
        await tester.pump();
        await tester.tap(find.text('Sair do jogo'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));
        final cartao2 = find.ancestor(of: find.text('Circuito do Deserto'), matching: find.byType(Opacity)).first;
        await tester.scrollUntilVisible(find.text('Circuito do Deserto'), 200);
        final correr2 = find.descendant(of: cartao2, matching: find.text('Correr'));
        await tester.ensureVisible(correr2);
        await tester.pump();
        await tester.tap(correr2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 20));

        // mais palavras (pista maior), quase todas novas, e 1 pra revisar
        expect(find.text('Pista 2 · 49 palavras · 48 novas · 1 pra revisar 🔁'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _largada(tester);
        teclado = _Teclado();
        final w1 = _naTela(tester, const Key('turismo-palavra-0'))!;
        expect(w1, isNot(anyOf(w0, g0)), reason: 'a fase abre com uma nova');
        // a errada vem no portal seguinte: já marcada no "a seguir"
        expect(find.byType(MarcaRevisao), findsOneWidget);
        expect(find.textContaining(' $w0'), findsWidgets);

        // digita até o portal da errada chegar: ela no HUD com o 🔁 ao lado da faixa
        await teclado.digitar(tester, w1);
        var chegou = false;
        for (var i = 0; i < 80 && !chegou; i++) {
          final portal = _naTela(tester, const Key('turismo-palavra-0'));
          if (portal == w0) {
            chegou = true;
            break;
          }
          final gas = _naTela(tester, const Key('turismo-gas'));
          if (gas != null) await teclado.digitar(tester, gas);
          for (var k = 0; k < 4; k++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        expect(chegou, isTrue, reason: 'o 2º portal (a errada) chegou');
        final faixa = find.ancestor(of: find.byKey(const Key('turismo-palavra-0')), matching: find.byType(Column)).first;
        expect(find.descendant(of: faixa, matching: find.byType(MarcaRevisao)), findsOneWidget,
            reason: 'o 🔁 ao lado da faixa da errada');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(Container());
      });
    }

    testWidgets('inglês no modo setas: sem baralho nem linha da fase', (tester) async {
      Linguagem.atual = Linguagem.ingles;
      SharedPreferences.setMockInitialValues({'turismo_tutorial_setas': true, 'turismo_modo': true});
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(ContagemRegressiva), findsOneWidget);
      expect(find.byType(LinhaFase), findsNothing);
      await _largada(tester);
      expect(find.byType(MarcaRevisao), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(Container());
    });

    testWidgets('Dart: o sorteio de sempre, sem linha da fase nem 🔁', (tester) async {
      expect(Linguagem.atual, Linguagem.dart);
      SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true});
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.byType(ContagemRegressiva), findsOneWidget);
      expect(find.byType(LinhaFase), findsNothing);
      await _largada(tester);
      final replica = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
      final w = replica.portais.first.palavras.first;
      expect(_naTela(tester, const Key('turismo-palavra-0')), w);
      final teclado = _Teclado();
      await teclado.digitar(tester, w[0]);
      await teclado.digitar(tester, _errada(w[1]));
      await teclado.digitar(tester, w.substring(1));
      for (final ch in w.split('')) {
        replica.teclar(ch);
      }
      expect(_naTela(tester, const Key('turismo-gas')), replica.palavraGas);
      expect(find.byType(MarcaRevisao), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(Container());
    });
  });
}
