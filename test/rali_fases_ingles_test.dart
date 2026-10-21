// 🏁 Rali no inglês, fase a fase: cada fase traz palavras NOVAS (as da fase anterior não voltam), MAIS
// palavras (12, 14, 16…, e a pista do tamanho do baralho) e põe de propósito pra revisar 🔁 a que a pessoa
// errou — espalhada pelo trecho que ela digita mesmo (palavra perfeita anda 2 casas: 'até 14 palavras').
// A linha da fase na largada conta o que vem; a palavra que volta tem o "🔁 REVISÃO" ao lado da
// "PALAVRA n" e o 🔁 no "a seguir". No Dart (e no C#) nada disso: o baralho e a pista 12 de sempre.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/baralho_fases.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
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

Widget _app(Widget home) => MaterialApp(theme: Mixart.tema(), home: home);

/// O vocabulário de reserva do inglês (arcade solto, sem o curso — e sem as difíceis do banco).
VocabularioJogo get _reserva => VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn);

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

/// Digita no campo invisível (o texto só cresce; [buffer] guarda o que já foi).
class _Teclado {
  String buffer = '';
  Future<void> digitar(WidgetTester tester, String s) async {
    if (buffer.length + s.length > 180) {
      buffer = '';
      await tester.enterText(find.byType(TextField), '');
    }
    for (final ch in s.split('')) {
      buffer += ch;
      await tester.enterText(find.byType(TextField), buffer);
      await tester.pump();
    }
  }
}

/// A palavra da vez, lida na tela.
String _alvo(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('rali-alvo'))).textSpan!.toPlainText();

String _linha(WidgetTester tester) => tester.widget<Text>(
        find.descendant(of: find.byKey(const Key('fase-intro')), matching: find.byType(Text)))
    .data!;

/// Digita limpas (lendo da tela) até a palavra da vez ser uma revisão 🔁; devolve ela e quantas vieram antes.
Future<(String, int)> _ateRevisao(WidgetTester tester, _Teclado t, {int limite = 10}) async {
  for (var i = 0; i < limite; i++) {
    final w = _alvo(tester);
    if (find.byKey(const Key('rali-revisao')).evaluate().isNotEmpty) return (w, i);
    await t.digitar(tester, w);
  }
  fail('nenhuma revisão nas $limite primeiras palavras');
}

/// Digita a fase inteira lendo a palavra da tela: as de [comErros] com 2 teclas erradas antes, as outras
/// limpas. Devolve as palavras na ordem.
Future<List<String>> _jogarFase(WidgetTester tester, _Teclado t, int fase, {Set<String> comErros = const {},
    void Function(int i, String w)? aCada}) async {
  final feitas = <String>[];
  for (var i = 0; i < 40 && find.text('FASE $fase CONCLUÍDA!').evaluate().isEmpty; i++) {
    final w = _alvo(tester);
    aCada?.call(i, w);
    await t.digitar(tester, '${comErros.contains(w) ? '##' : ''}$w');
    feitas.add(w);
  }
  return feitas;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true});
    VozDoJogo.falanteDeTeste = () => _Mudo();
  });
  tearDown(() {
    VozDoJogo.falanteDeTeste = null;
    Linguagem.atual = Linguagem.dart;
  });

  void tela(WidgetTester tester, [Size s = const Size(1000, 1500)]) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('inglês: a fase 2 traz palavras novas, mais delas, e a que errei volta marcada 🔁', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tela(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    expect(find.textContaining('as que você errar ou demorar voltam pra revisão 🔁'), findsOneWidget);
    await tester.tap(find.text('Fácil'));
    await tester.pump();

    // fase 1: a linha na largada; 12 palavras, todas novas; pista 12
    expect(find.byType(LinhaFase), findsOneWidget);
    expect(_linha(tester), 'Fase 1 · até 12 palavras · 12 novas');
    await _largada(tester);
    expect(find.byType(LinhaFase), findsNothing, reason: 'some quando a largada sai');
    expect(tester.widget<PistaPro>(find.byType(PistaPro)).pista, 12);
    expect(find.byKey(const Key('rali-revisao')), findsNothing, reason: 'nada pra revisar na 1ª fase');
    expect(find.text('PALAVRA 1'), findsOneWidget);

    // a 1ª palavra com 2 erros, as outras limpas (TURBO: anda 2)
    final t = _Teclado();
    final errada = _alvo(tester);
    final fase1 = await _jogarFase(tester, t, 1, comErros: {errada});
    expect(find.text('FASE 1 CONCLUÍDA!'), findsOneWidget);
    expect(fase1.toSet().length, fase1.length, reason: 'sem repetir dentro da fase');
    expect(find.textContaining('vêm palavras novas (e mais delas) — as que escaparam voltam 🔁'), findsOneWidget);

    await tester.tap(find.text('Próxima fase →'));
    await tester.pump();

    // fase 2: maior, e a que escapou volta pra revisar
    expect(_linha(tester), startsWith('Fase 2 · até 14 palavras · '));
    expect(_linha(tester), endsWith('1 pra revisar 🔁'));
    await _largada(tester);
    expect(tester.widget<PistaPro>(find.byType(PistaPro)).pista, 14, reason: 'a pista do tamanho do baralho');

    // a 1ª carta é nova; a que errei vem no meio do trecho que a pessoa digita (alcance 10: a 6ª carta),
    // com o 🔁 já no "a seguir" antes
    final primeira = _alvo(tester);
    expect(primeira, isNot(errada));
    expect(fase1, isNot(contains(primeira)), reason: 'palavra nova');
    expect(find.byKey(const Key('rali-revisao')), findsNothing);

    String? revisada;
    var marcada = false, avisada = false;
    final fase2 = await _jogarFase(tester, t, 2, aCada: (i, w) {
      if (i == 4) avisada = find.byType(MarcaRevisao).evaluate().length == 1 && find.text(errada).evaluate().isNotEmpty;
      if (i == 5) {
        revisada = w;
        marcada = find.byKey(const Key('rali-revisao')).evaluate().isNotEmpty &&
            find.text('PALAVRA 6').evaluate().isNotEmpty;
      } else {
        expect(find.byKey(const Key('rali-revisao')), findsNothing, reason: '"$w" não é revisão');
      }
    });
    expect(avisada, isTrue, reason: 'o 🔁 no "a seguir"');
    expect(revisada, errada);
    expect(marcada, isTrue, reason: '"🔁 REVISÃO" ao lado da PALAVRA 6');
    expect(fase2.length, 7, reason: 'todas limpas: TURBO, 14 casas em 7 palavras — a revisão estava no trecho');
    // todas as outras palavras da fase 2 são diferentes das da fase 1
    final novas = [for (final w in fase2) if (w != errada) w];
    expect(novas.length, fase2.length - 1);
    for (final w in novas) {
      expect(fase1, isNot(contains(w)), reason: '"$w" já tinha saído na fase 1');
    }
    expect(find.text('FASE 2 CONCLUÍDA!'), findsOneWidget);
    expect(find.textContaining('entram as palavras COMPRIDAS — e as que escaparam voltam 🔁'), findsOneWidget);

    // fase 3: 16 palavras (as compridas entram). Quantas revisar depende do relógio de verdade (alguma
    // pode ter saído lenta), então só o tamanho
    await tester.tap(find.text('Próxima fase →'));
    await tester.pump();
    expect(_linha(tester), startsWith('Fase 3 · até 16 palavras · '));
    await _largada(tester);
    expect(tester.widget<PistaPro>(find.byType(PistaPro)).pista, 16);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês: errar de novo na revisão a traz outra vez na fase seguinte',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tela(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 7)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    final t = _Teclado();
    final errada = _alvo(tester);
    await _jogarFase(tester, t, 1, comErros: {errada});
    await tester.tap(find.text('Próxima fase →'));
    await tester.pump();
    await _largada(tester);
    // erra a revisão de novo: na fase 3 ela volta outra vez
    await _jogarFase(tester, t, 2, comErros: {errada});
    await tester.tap(find.text('Próxima fase →'));
    await tester.pump();
    expect(_linha(tester), contains('pra revisar 🔁'));
    await _largada(tester);
    // (a errada vem antes de qualquer lenta: com o relógio de verdade, alguma pode ter saído lenta)
    final (revisao, antes) = await _ateRevisao(tester, t);
    expect(revisao, errada);
    expect(antes, greaterThan(0), reason: 'a 1ª carta é nova');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês: "Jogar de novo" — a 1ª fase da partida nova já traz a que escapou pra revisar',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tela(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 7)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    final t = _Teclado();
    final errada = _alvo(tester);
    await _jogarFase(tester, t, 1, comErros: {errada});
    await tester.tap(find.text('Parar e guardar pontos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.ensureVisible(find.text('Jogar de novo'));
    await tester.tap(find.text('Jogar de novo'));
    await tester.pump();
    expect(_linha(tester), 'Fase 1 · até 12 palavras · 11 novas · 1 pra revisar 🔁');
    await _largada(tester);
    expect(_alvo(tester), isNot(errada), reason: 'a 1ª carta é nova');
    final (revisao, antes) = await _ateRevisao(tester, t);
    expect(revisao, errada);
    expect(antes, 4, reason: 'alcance 8, uma revisão: no meio do trecho (5ª carta)');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês: a palavra que demorei (sem a pausa) volta pra revisar na fase seguinte', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tela(tester);
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    final t = _Teclado();
    Future<void> esperaDeVerdade(int ms) => tester.runAsync(() => Future<void>.delayed(Duration(milliseconds: ms)));

    // 3 com erro (anda 1), depois 5 limpas (TURBO, anda 2) = 13: 8 tempos medidos (a mediana vale)
    for (var i = 0; i < 3; i++) {
      await t.digitar(tester, '##${_alvo(tester)}');
    }
    // a 5ª, limpa mas DEVAGAR (≈180 ms por letra, de verdade)
    final lenta = _alvo(tester);
    for (final ch in lenta.split('')) {
      await t.digitar(tester, ch);
      if (ch != lenta[lenta.length - 1]) await esperaDeVerdade(180);
    }
    // a 6ª, rápida — mas com uma pausa longa no meio: a pausa não conta
    final pausada = _alvo(tester);
    await t.digitar(tester, pausada.substring(0, 1));
    await tester.tap(find.byTooltip('Pausar (Esc)'));
    await tester.pump();
    await esperaDeVerdade(1500);
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    await t.digitar(tester, pausada.substring(1));
    for (var i = 0; i < 3; i++) {
      await t.digitar(tester, _alvo(tester));
    }
    expect(find.text('FASE 1 CONCLUÍDA!'), findsOneWidget);
    await tester.tap(find.text('Próxima fase →'));
    await tester.pump();
    // as 3 erradas + a lenta (a pausada, não); teto: round(.35 × 10 que a pessoa digita) = 4
    expect(_linha(tester), 'Fase 2 · até 14 palavras · 10 novas · 4 pra revisar 🔁');
    await _largada(tester);
    // revisões espalhadas pelas 10 primeiras: cartas 3, 5, 7 (as erradas) e 9 (a lenta) — digita com erro
    // (anda 1)
    final revisoes = <String>[];
    final posicoes = <int>[];
    for (var i = 0; i < 10; i++) {
      final w = _alvo(tester);
      if (find.byKey(const Key('rali-revisao')).evaluate().isNotEmpty) {
        revisoes.add(w);
        posicoes.add(i);
      }
      await t.digitar(tester, '##$w');
    }
    expect(revisoes.length, 4);
    expect(posicoes, [2, 4, 6, 8]);
    expect(revisoes.last, lenta, reason: 'a lenta entra depois das erradas');
    expect(revisoes, isNot(contains(pausada)), reason: 'a pausa ficou fora do tempo da palavra');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês, modo memória: só palavras com tradução, e a revisão também ganha o 🔁', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tela(tester);
    final v = _reserva;
    // o mesmo baralho que a página monta (a fase 1 = o embaralhado de sempre, filtrado)
    final rb = BaralhoFases(rnd: Random(3));
    final replica = rb.abrirFase(
      fase: 1,
      pool: BaralhoFases.poolRali(v, comLongas: false),
      tamanho: BaralhoFases.tamanhoRali(1),
      alcance: BaralhoFases.alcanceRali(1),
      aceita: (w) => v.traducao(w) != null,
    );
    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rali-memoria')));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    expect(_linha(tester), 'Fase 1 · até 12 palavras · 12 novas');
    await _largada(tester);
    final t = _Teclado();
    for (var i = 0; i < replica.palavras.length && find.text('FASE 1 CONCLUÍDA!').evaluate().isEmpty; i++) {
      final w = replica.palavras[i];
      expect(tester.widget<Text>(find.byKey(const Key('rali-memoria-pt'))).data, v.traducao(w));
      await t.digitar(tester, '${i == 0 ? '#' : ''}$w');
      rb.registrar(w, erros: i == 0 ? 1 : 0); // a réplica fica sabendo (sem tempo: nada de lenta)
    }
    expect(find.text('FASE 1 CONCLUÍDA!'), findsOneWidget);
    await tester.tap(find.text('Próxima fase →'));
    await tester.pump();
    expect(_linha(tester), endsWith('1 pra revisar 🔁'), reason: 'o erro de memória também volta');
    final r2 = rb.abrirFase(
      fase: 2,
      pool: BaralhoFases.poolRali(v, comLongas: false),
      tamanho: BaralhoFases.tamanhoRali(2),
      alcance: BaralhoFases.alcanceRali(2),
      aceita: (w) => v.traducao(w) != null,
    );
    final iRev = r2.cartas.indexWhere((c) => c.revisao);
    expect(r2.cartas[iRev].palavra, replica.palavras.first);
    await _largada(tester);
    // limpas até a revisão aparecer no "a seguir" do modo memória (com o 🔁)
    for (var i = 0; i < iRev - 1; i++) {
      expect(find.byType(MarcaRevisao), i < iRev - 2 ? findsNothing : findsOneWidget, reason: 'carta ${i + 1}');
      final w = r2.palavras[i];
      expect(tester.widget<Text>(find.byKey(const Key('rali-memoria-pt'))).data, v.traducao(w));
      await t.digitar(tester, w);
    }
    expect(find.byType(MarcaRevisao), findsWidgets, reason: 'o 🔁 no "a seguir" do modo memória');
    await t.digitar(tester, '#');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  for (final paleta in [Paleta.flutterClaro, Paleta.mixart]) {
    testWidgets('celular 360 (${paleta == Paleta.mixart ? 'escuro' : 'claro'}): linha da fase e 🔁 cabem',
        (tester) async {
      final antes = Mixart.atual;
      Mixart.atual = paleta;
      addTearDown(() => Mixart.atual = antes);
      Linguagem.atual = Linguagem.ingles;
      tela(tester, const Size(360, 800));
      await tester.pumpWidget(_app(const RaliPage(semente: 3)));
      await tester.pump();
      await tester.ensureVisible(find.text('Fácil'));
      await tester.pump();
      await tester.tap(find.text('Fácil'));
      await tester.pump();
      expect(find.byType(LinhaFase), findsOneWidget);
      await _largada(tester);
      final t = _Teclado();
      final errada = _alvo(tester);
      await _jogarFase(tester, t, 1, comErros: {errada});
      await tester.tap(find.text('Próxima fase →'));
      await tester.pump();
      expect(find.byType(LinhaFase), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _largada(tester);
      final (revisao, _) = await _ateRevisao(tester, t);
      expect(revisao, errada);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(Container());
    });
  }

  testWidgets('Dart e C#: sem linha da fase, sem 🔁, pista 12 e o baralho de sempre na fase 2', (tester) async {
    tela(tester);
    for (final l in [Linguagem.dart, Linguagem.csharp]) {
      Linguagem.atual = l;
      final rnd = Random(3);
      final f1 = baralhoRaliDe(rnd, linguagem: l);
      final f2 = baralhoRaliDe(rnd, linguagem: l);
      await tester.pumpWidget(_app(const RaliPage(semente: 3)));
      await tester.pump();
      expect(find.textContaining('voltam pra revisão'), findsNothing, reason: '$l');
      await tester.tap(find.text('Fácil'));
      await tester.pump();
      expect(find.byType(LinhaFase), findsNothing, reason: '$l');
      await _largada(tester);
      expect(tester.widget<PistaPro>(find.byType(PistaPro)).pista, 12);
      expect(_alvo(tester), f1[0]);
      final t = _Teclado();
      for (var i = 0; i < 24 && find.text('FASE 1 CONCLUÍDA!').evaluate().isEmpty; i++) {
        await t.digitar(tester, '##${f1[i % f1.length]}');
      }
      expect(find.text('FASE 1 CONCLUÍDA!'), findsOneWidget, reason: '$l');
      expect(find.textContaining('a CPU fica ainda mais rápida!'), findsOneWidget, reason: '$l');
      await tester.tap(find.text('Próxima fase →'));
      await tester.pump();
      expect(find.byType(LinhaFase), findsNothing);
      await _largada(tester);
      expect(tester.widget<PistaPro>(find.byType(PistaPro)).pista, 12, reason: '$l');
      expect(_alvo(tester), f2[0], reason: '$l: a fase 2 reembaralha como sempre');
      expect(find.byType(MarcaRevisao), findsNothing, reason: '$l');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(Container());
    }
  });
}
