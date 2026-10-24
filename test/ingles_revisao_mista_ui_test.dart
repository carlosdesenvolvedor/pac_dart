// 🔁 A tela da "Revisão até aqui": exercícios de tipos diferentes, "não posso escutar agora", a frase errada
// voltando no fim (sem nota) e o resumo.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/revisao_mista.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_mista_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/montagem_frase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _VozFake extends VozIngles {
  final falas = <String>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add(frase);
    return Future.value();
  }

  @override
  Future<void> parar() async {}
  @override
  Future<void> calarTudo() async {}
  @override
  bool get somLiberado => true;
}

const _nice = Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '');
const _coffee = Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: '');
const _cats = Trecho(cod: 'I like cats.', dica: 'Eu gosto de gatos.', out: '');
const _licao = Licao(nome: 'Primeiros passos', emoji: '👋', id: 't1.l1', trechos: [_nice, _coffee, _cats]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FraseView.carencia = Duration.zero;
  });

  Future<void> passa(WidgetTester tester, [int vezes = 4]) async {
    for (var i = 0; i < vezes; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  Future<void> digita(WidgetTester tester, String texto) async {
    await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, texto);
    await tester.pump();
  }

  /// Responde certo do jeito do exercício: digitando ou montando os blocos (e conferindo).
  Future<void> responde(WidgetTester tester, String frase) async {
    final m = find.byType(MontagemFrase);
    if (m.evaluate().isEmpty) return digita(tester, frase);
    final st = tester.state<MontagemFraseState>(m);
    final usados = <int>{};
    for (final w in RegExp(r"[A-Za-z0-9']+").allMatches(frase).map((x) => x.group(0)!)) {
      final b = st.blocos.firstWhere((b) => !b.distrator && b.texto == w && !usados.contains(b.id));
      usados.add(b.id);
      final k = find.byKey(Key('bloco-${b.id}'));
      await tester.ensureVisible(k);
      await tester.pump();
      await tester.tap(k);
      await tester.pump();
    }
    await tester.tap(find.byKey(const Key('montagem-conferir')));
    await tester.pump();
  }

  String titulo(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('revisao-mista-titulo'))).data!;

  Future<void> enter(WidgetTester tester) async {
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await passa(tester);
  }

  testWidgets('escrever certo, escutar → "não posso escutar", errar volta no fim, resumo', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _VozFake();
    final resultados = <ResultadoMisto>[];
    final desligados = <TipoExercicio>[];
    List<ResultadoMisto>? fim;
    SaidaRevisaoMista? saida;

    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                saida = await Navigator.of(context).push<SaidaRevisaoMista>(MaterialPageRoute(
                  builder: (_) => RevisaoMistaPage(
                    exercicios: const [
                      ExercicioMisto(_nice, _licao, TipoExercicio.escrever),
                      ExercicioMisto(_coffee, _licao, TipoExercicio.escutar),
                      ExercicioMisto(_cats, _licao, TipoExercicio.escrever),
                    ],
                    voz: voz,
                    onResultado: resultados.add,
                    onDesligar: desligados.add,
                    onFim: (rs) => fim = rs,
                  ),
                ));
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await passa(tester, 8);

    // 1) ✍️ escrever: a tradução em cima, digitar o inglês
    expect(titulo(tester), contains('Escreva em inglês'));
    expect(find.text('Prazer em te conhecer.'), findsWidgets);
    await digita(tester, _nice.cod);
    await passa(tester);
    expect(find.text('✅ Isso aí!'), findsOneWidget);
    await enter(tester);

    // 2) 👂 escutar: sem a tradução, a frase toca sozinha; "não posso escutar" troca o exercício
    expect(titulo(tester), contains('Escute'));
    expect(find.text('Café, por favor.'), findsNothing);
    expect(voz.falas.last, _coffee.cod);
    await tester.tap(find.byKey(const Key('revisao-mista-nao-posso-escutar')));
    await passa(tester);
    expect(desligados, [TipoExercicio.escutar]);
    expect(titulo(tester), anyOf(contains('Escreva'), contains('Monte')));
    expect(find.byKey(const Key('revisao-mista-nao-posso-escutar')), findsNothing);
    if (titulo(tester).contains('Monte')) expect(find.byType(MontagemFrase), findsOneWidget);
    // "não sei": a frase aparece, é copiada, e a nota é "errou"
    await tester.tap(find.text('não sei').first);
    await passa(tester);
    await responde(tester, _coffee.cod);
    await passa(tester);
    expect(find.text('🔁 Essa volta no fim'), findsOneWidget);
    await enter(tester);

    // 3) ✍️ a última certa
    expect(titulo(tester), contains('Escreva em inglês'));
    await digita(tester, _cats.cod);
    await passa(tester);
    await enter(tester);

    // 4) a errada voltou, sem nota
    expect(titulo(tester), contains('Essa voltou'));
    expect(find.text('4 / 4'), findsOneWidget);
    await responde(tester, _coffee.cod);
    await passa(tester);
    await enter(tester);

    // resumo: só as 3 primeiras tentativas contam
    expect(find.text('Revisão feita! 🎉'), findsOneWidget);
    expect(resultados.map((r) => r.resultado),
        [ResultadoRevisao.acertou, ResultadoRevisao.errou, ResultadoRevisao.acertou]);
    expect(fim, hasLength(4));
    expect(find.textContaining('67% de acerto em 3 exercícios'), findsOneWidget);
    await tester.tap(find.byKey(const Key('revisao-mista-continuar')));
    await passa(tester, 8);
    expect(saida, SaidaRevisaoMista.terminou);
  });

  testWidgets('aberta com o som pausado: nenhum escutar', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: RevisaoMistaPage(
        exercicios: const [ExercicioMisto(_coffee, _licao, TipoExercicio.escutar)],
        semAudio: true,
        voz: _VozFake(),
      ),
    ));
    await passa(tester, 6);
    expect(titulo(tester), anyOf(contains('Escreva'), contains('Monte')));
  });
}
