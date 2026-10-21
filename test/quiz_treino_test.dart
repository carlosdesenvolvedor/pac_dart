// 🧩 QuizPage no "⚡ Treino do dia" (grupo C): a semente do dia, o onTerminou UMA vez por página (só no fim de
// verdade — nunca no "Pular quiz", ao voltar ou depois do "Repetir quiz") e o rotuloFim no botão principal.
// Com emSequencia: false, nada dos textos da sequência ("A seguir: …", "Pular quiz", "Sair da sequência").
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/quiz.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/fluxo_licao.dart';
import 'package:pac_dart/features/curso/presentation/pages/quiz_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CursoBloc de verdade num estado fixo, anotando os eventos que chegam.
class _CursoFake extends CursoBloc {
  _CursoFake(CursoState s) : super(loader: CurriculoLoader(), progresso: LocalProgressoRepository()) {
    emit(s);
  }
  final eventos = <CursoEvent>[];
  @override
  void onEvent(CursoEvent event) {
    eventos.add(event);
    super.onEvent(event);
  }
}

Trecho _tr(String cod, String dica) => Trecho(cod: cod, dica: dica, out: 'ok');

final _licao = Licao(nome: 'Listas', emoji: '📦', trechos: [
  _tr("if (lista.isNotEmpty) {\n  print(lista.first);\n}", 'evita mexer numa lista vazia'),
  _tr("for (var i = 0; i < 3; i++) {\n  print(i);\n}", 'repete três vezes'),
  _tr("var nomes = ['Ana', 'Léo'];", 'cria uma lista de nomes'),
  _tr('nomes.add(\'Rui\');', 'põe um nome no fim'),
  _tr('nomes.removeAt(0);', 'tira o primeiro'),
]);

final _pool = [for (final t in _licao.trechos) t.cod];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late _CursoFake curso;
  late List<(int, int)> terminou;
  late List<Object?> pops;

  /// Abre a QuizPage por cima de uma tela-base (para o pop ter para onde voltar) e anota o que ela devolve.
  Future<void> abrir(WidgetTester tester, {bool emSequencia = false, int? semente, String? rotuloFim}) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    curso = _CursoFake(CursoState(
        status: CursoStatus.pronto,
        linguagem: Linguagem.dart,
        trilhas: [Trilha(nivel: 'T1', emoji: '📦', licoes: [_licao])]));
    addTearDown(curso.close);
    terminou = [];
    pops = [];
    await tester.pumpWidget(BlocProvider<CursoBloc>.value(
      value: curso,
      child: MaterialApp(
        theme: Mixart.tema(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  final r = await Navigator.of(context).push<bool>(MaterialPageRoute(
                    builder: (_) => QuizPage(
                      trilhaIdx: 0,
                      licaoIdx: 0,
                      licao: _licao,
                      poolTrilha: _pool,
                      emSequencia: emSequencia,
                      semente: semente,
                      rotuloFim: rotuloFim,
                      onTerminou: (a, t) => terminou.add((a, t)),
                    ),
                  ));
                  pops.add(r);
                },
                child: const Text('abrir quiz'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir quiz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(QuizPage), findsOneWidget);
  }

  /// Responde as perguntas por clique (as [certas] primeiras certas, o resto errado) e dá Enter para seguir.
  Future<void> responderTudo(WidgetTester tester, List<PerguntaQuiz> perguntas, {required int certas}) async {
    for (var k = 0; k < perguntas.length; k++) {
      final p = perguntas[k];
      final a = k < certas ? p.correta : (p.correta == 0 ? 1 : 0);
      await tester.tap(find.text(String.fromCharCode(65 + a)));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
    }
  }

  final padrao = gerarQuiz(_licao, _pool, seed: sementeQuiz(0, 0));

  testWidgets('onTerminou: uma vez no fim de verdade (e não de novo depois do "Repetir quiz")', (tester) async {
    await abrir(tester);
    expect(padrao.length, greaterThan(1));
    await responderTudo(tester, padrao, certas: padrao.length - 1);
    expect(find.text('QUIZ CONCLUÍDO!'), findsOneWidget);
    expect(terminou, [(padrao.length - 1, padrao.length)]);
    // o QuizFinalizado continua saindo como sempre
    expect(curso.eventos.whereType<QuizFinalizado>().single,
        QuizFinalizado(0, 0, padrao.length - 1));

    // refaz e termina de novo: o QuizFinalizado sai outra vez, o onTerminou não
    await tester.tap(find.text('Repetir quiz'));
    await tester.pump();
    await responderTudo(tester, padrao, certas: padrao.length);
    expect(find.text('QUIZ CONCLUÍDO!'), findsOneWidget);
    expect(curso.eventos.whereType<QuizFinalizado>().length, 2);
    expect(terminou.length, 1, reason: 'uma vez por página');
    expect(tester.takeException(), isNull);
  });

  testWidgets('onTerminou: nada ao voltar no meio', (tester) async {
    await abrir(tester);
    await responderTudo(tester, padrao.sublist(0, 1), certas: 1);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(QuizPage), findsNothing);
    expect(pops, [false]);
    expect(terminou, isEmpty);
    expect(curso.eventos.whereType<QuizFinalizado>(), isEmpty);
  });

  testWidgets('onTerminou: nada no "Pular quiz" (emSequencia)', (tester) async {
    await abrir(tester, emSequencia: true);
    await tester.tap(find.text('Pular quiz'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(pops, [true]);
    expect(terminou, isEmpty);
    expect(curso.eventos.whereType<QuizFinalizado>(), isEmpty);
  });

  testWidgets('modo treino: sem "Pular quiz" nem "A seguir", X "Voltar" e o botão "Continuar o treino →"',
      (tester) async {
    await abrir(tester, rotuloFim: 'Continuar o treino →');
    expect(find.text('Pular quiz'), findsNothing);
    expect(find.byTooltip('Voltar'), findsOneWidget);
    expect(find.byTooltip('Sair da sequência'), findsNothing);
    await responderTudo(tester, padrao, certas: padrao.length);
    expect(find.text('QUIZ CONCLUÍDO!'), findsOneWidget);
    expect(find.textContaining('A seguir'), findsNothing);
    expect(find.text('Voltar ao mapa'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continuar o treino →'), findsOneWidget);
    expect(find.text('Repetir quiz'), findsOneWidget);
    await tester.tap(find.text('Continuar o treino →'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(QuizPage), findsNothing);
    expect(terminou, [(padrao.length, padrao.length)]);
  });

  testWidgets('sem rotuloFim, o texto de sempre: "Voltar ao mapa"', (tester) async {
    await abrir(tester);
    await responderTudo(tester, padrao, certas: 0);
    expect(find.widgetWithText(FilledButton, 'Voltar ao mapa'), findsOneWidget);
  });

  testWidgets('sem rotuloFim, em sequência: "Continuar →" e o "A seguir"', (tester) async {
    await abrir(tester, emSequencia: true);
    await responderTudo(tester, padrao, certas: 0);
    expect(find.widgetWithText(FilledButton, 'Continuar →'), findsOneWidget);
    expect(find.textContaining('A seguir:'), findsOneWidget);
  });

  testWidgets('semente: troca a ordem das perguntas', (tester) async {
    // uma semente cuja 1ª pergunta não é a do padrão
    var semente = 1;
    while (gerarQuiz(_licao, _pool, seed: semente).first.enunciado == padrao.first.enunciado) {
      semente++;
    }
    final doDia = gerarQuiz(_licao, _pool, seed: semente);
    await abrir(tester, semente: semente);
    expect(find.text(doDia.first.enunciado), findsOneWidget);
    expect(find.text(padrao.first.enunciado), findsNothing);
    // e responde pela ordem nova até o fim
    await responderTudo(tester, doDia, certas: doDia.length);
    expect(terminou, [(doDia.length, doDia.length)]);
  });
}
