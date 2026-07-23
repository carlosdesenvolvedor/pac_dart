import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/quiz.dart';
import 'package:pac_dart/features/curso/presentation/fluxo_licao.dart';
import 'package:pac_dart/features/curso/presentation/pages/quiz_page.dart';

/// Lição de mentira com trechos MULTI-LINHA — o caso que quebrava: o código
/// certo tem quebra de linha e indentação, e o jogador digita tudo numa linha.
Trecho _tr(String cod, String dica) => Trecho(cod: cod, dica: dica, out: 'ok');

final _licao = Licao(nome: 'Listas', emoji: '📦', trechos: [
  _tr("if (lista.isNotEmpty) {\n  print(lista.first);\n}", 'evita mexer numa lista vazia'),
  _tr("for (var i = 0; i < 3; i++) {\n  print(i);\n}", 'repete três vezes'),
  _tr("var nomes = ['Ana', 'Léo'];", 'cria uma lista de nomes'),
  _tr('nomes.add(\'Rui\');', 'põe um nome no fim'),
  _tr('nomes.removeAt(0);', 'tira o primeiro'),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  final pool = _licao.trechos.map((t) => t.cod).toList();
  final perguntas = gerarQuiz(_licao, pool, seed: sementeQuiz(0, 0));

  Future<void> abrir(WidgetTester tester) async {
    // tela alta: o ListView é preguiçoso e não constrói o que fica fora dela
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: QuizPage(trilhaIdx: 0, licaoIdx: 0, licao: _licao, poolTrilha: pool),
    ));
    await tester.pump();
  }

  testWidgets('clicar na alternativa certa responde na hora', (tester) async {
    await abrir(tester);
    final certa = perguntas.first.correta;
    await tester.tap(find.text(String.fromCharCode(65 + certa)));
    await tester.pump();
    expect(find.textContaining('Acertou'), findsOneWidget);
  });

  testWidgets('clicar na alternativa errada mostra qual era', (tester) async {
    await abrir(tester);
    final errada = perguntas.first.correta == 0 ? 1 : 0;
    await tester.tap(find.text(String.fromCharCode(65 + errada)));
    await tester.pump();
    expect(find.textContaining('Errou'), findsOneWidget);
  });

  testWidgets('digitar o código certo TUDO NUMA LINHA vale', (tester) async {
    await abrir(tester);
    // o código certo tem \n e indentação; aqui vai numa linha só
    final numaLinha = perguntas.first.codigoCerto.replaceAll(RegExp(r'\s+'), ' ').trim();

    await tester.enterText(find.byType(TextField).last, numaLinha);
    await tester.pump();
    await tester.ensureVisible(find.text('Responder'));
    await tester.pump();
    await tester.tap(find.text('Responder'));
    await tester.pump();

    expect(find.textContaining('Acertou'), findsOneWidget);
  });

  testWidgets('Enter no meio da digitação não corrige a questão', (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextField).last, 'if (lista.isNotEmpty) {');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(find.textContaining('Acertou'), findsNothing);
    expect(find.textContaining('Errou'), findsNothing);
    expect(find.text('Responder'), findsOneWidget); // ainda esperando resposta
  });
}
