import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/projeto_page.dart';
import 'package:pac_dart/features/curso/presentation/widgets/preview_ao_vivo.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A "tela de criando junto": nos apps Flutter (Mão na Massa / Master), a
/// prévia AO VIVO monta o app conforme se digita. Este teste garante que
/// ela está lá — larga (lado a lado) e estreita (empilhada).
const _appFlutter = Projeto(
  nome: 'Cartão de Teste',
  emoji: '🪪',
  descricao: 'Um cartão simples para provar a prévia.',
  cod: "Scaffold(\n  body: Center(\n    child: Text('Oi'),\n  ),\n)",
  out: 'app na tela',
  flutter: true,
);

final _trilhaFake = Trilha(
  nivel: 'Flutter',
  emoji: '💙',
  licoes: [
    Licao(nome: 'Licao F', emoji: '🅵', trechos: [
      Trecho(cod: 'var a = 1;', dica: 'digite', out: 'ok'),
    ]),
  ],
  projetos: const [_appFlutter],
);

class _LoaderFake extends CurriculoLoader {
  @override
  Future<List<Trilha>> carregar() async => [_trilhaFake];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  SharedPreferences.setMockInitialValues({});

  Future<CursoBloc> cursoPronto(WidgetTester tester) async =>
      (await tester.runAsync(() async {
        final bloc =
            CursoBloc(loader: _LoaderFake(), progresso: LocalProgressoRepository())
              ..add(const CursoIniciado());
        await Future<void>.delayed(Duration.zero);
        return bloc;
      }))!;

  Widget _app(CursoBloc curso) => BlocProvider.value(
        value: curso,
        child: MaterialApp(
          theme: Mixart.tema(),
          home: const ProjetoPage(
            nivel: 'Flutter',
            projeto: _appFlutter,
            chaveProgresso: 'proj:0:0',
          ),
        ),
      );

  testWidgets('tela LARGA: prévia ao vivo lado a lado com o código',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final curso = await cursoPronto(tester);
    await tester.pumpWidget(_app(curso));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PreviewAoVivo), findsOneWidget);
    expect(find.text('Você vai construir este app:'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // digita o começo do app: a prévia continua firme (montando junto)
    await tester.enterText(find.byType(TextField), 'Scaffold(');
    await tester.pump();
    expect(find.byType(PreviewAoVivo), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(curso.close);
  });

  testWidgets('tela ESTREITA: prévia empilhada em cima do código', (tester) async {
    tester.view.physicalSize = const Size(700, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final curso = await cursoPronto(tester);
    await tester.pumpWidget(_app(curso));
    await tester.pump();
    await tester.pump();

    expect(find.byType(PreviewAoVivo), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(curso.close);
  });

  testWidgets('projeto DART (console) não tem prévia — é assim mesmo',
      (tester) async {
    final curso = await cursoPronto(tester);
    await tester.pumpWidget(BlocProvider.value(
      value: curso,
      child: MaterialApp(
        theme: Mixart.tema(),
        home: const ProjetoPage(
          nivel: 'Fundamentos',
          projeto: Projeto(
              nome: 'Programa Console',
              emoji: '🖥️',
              descricao: 'só terminal',
              cod: 'print(1);',
              out: '1'),
          chaveProgresso: 'proj:0:1',
        ),
      ),
    ));
    await tester.pump();
    expect(find.byType(PreviewAoVivo), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(curso.close);
  });
}
