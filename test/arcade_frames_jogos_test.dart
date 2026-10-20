import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
import 'package:pac_dart/features/arcade/presentation/turismo_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/vista_3d.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/ranking/presentation/ranking_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No navegador (CanvasKit) cada frame redesenha a tela inteira: o relógio
/// dos jogos só roda com a partida andando — pausa, fim, campeonato e o hub
/// parados não pedem frame.
class _RepoFake implements RankingRepository {
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}

  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => false;

  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

Widget _app(RankingCubit cubit, Widget home) => BlocProvider.value(
      value: cubit,
      child: MaterialApp(theme: Mixart.tema(), home: home),
    );

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

/// Deixa as animações de uma vez só (entrada de overlay, placar…) terminarem.
Future<void> _assenta(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('hub do Arcade: o Pac só mastiga com o mouse em cima (pumpAndSettle termina)', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const ArcadePage()));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // mouse em cima do cartão do Pac: ele mastiga…
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await mouse.moveTo(tester.getCenter(find.text('Pac')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    // …e saiu, para de novo
    await mouse.moveTo(const Offset(1, 1));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Chuva: o relógio para na pausa, volta ao retomar e para no fim de jogo', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const ChuvaPage(semente: 5)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'chovendo');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsOneWidget);
    await _assenta(tester);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nada embaixo da pausa pede frame');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PAUSADO'), findsNothing);
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'voltou a chover');

    // ninguém digita: três palavras chegam ao chão
    for (var i = 0; i < 1200 && find.byType(FimDeJogo).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FimDeJogo), findsOneWidget);
    await _assenta(tester);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'fim de jogo parado');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Rali pausado: a pista congela embaixo da pausa', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsOneWidget);
    await _assenta(tester);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Dart Turismo: campeonato parado; o relógio só roda na pista (para na pausa e no fim)',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'turismo_modo': true, 'turismo_tutorial_setas': true});

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    // o campeonato (menu) não pede frame
    await tester.pumpWidget(_app(cubit, const TurismoPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _assenta(tester);
    expect(find.text('🏎️ Dart Turismo'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'campeonato parado');

    await tester.pumpWidget(Container());
    await tester.pumpWidget(_app(cubit, const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'correndo');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsOneWidget);
    final relogio = find.textContaining(RegExp(r'^\d+\.\ds$'));
    final antes = tester.widgetList<Text>(relogio).map((t) => t.data).toList();
    await _assenta(tester);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nada embaixo da pausa pede frame');
    expect(tester.widgetList<Text>(relogio).map((t) => t.data).toList(), antes, reason: 'o tempo não correu');

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PAUSADO'), findsNothing);
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'voltou a correr');

    // parado na largada até o relógio da pista 1 estourar
    final passos = (pistasGt[0].tempoLimite * 10).ceil() + 5;
    for (var i = 0; i < passos && find.text('⏱ TEMPO ESGOTADO').evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('⏱ TEMPO ESGOTADO'), findsOneWidget);
    await _assenta(tester);
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'resultado parado');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Dart Turismo sem 3D: a estrada em Canvas redesenha a cada 2 frames também a 120 Hz',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'turismo_modo': true, 'turismo_tutorial_setas': true});

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(Vista3D.disponivel, isFalse, reason: 'no teste vale o stub (como no Android/iOS)');

    // 24 frames de 120 Hz (~0,2 s): a página reconstrói a vista em metade deles (o limite de
    // ~30 Hz por tempo — só pro HUD sobre o 3D — daria uns 6)
    const quadro = Duration(microseconds: 8333);
    var redesenhos = 0;
    var antes = tester.widget<Vista3D>(find.byType(Vista3D));
    for (var i = 0; i < 24; i++) {
      await tester.pump(quadro);
      final agora = tester.widget<Vista3D>(find.byType(Vista3D));
      if (!identical(agora, antes)) redesenhos++;
      antes = agora;
    }
    expect(redesenhos, inInclusiveRange(11, 13));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('hub do inglês: 1 teimosa sem "a mais teimosa" e o botão dela é "🔥 Revanche"', (tester) async {
    final linguagemAntes = Linguagem.atual;
    addTearDown(() => Linguagem.atual = linguagemAntes);
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(390, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final trilhas = [
      const Trilha(nivel: 'T1', emoji: '🍽️', etapa: 'A1 · Fundação', licoes: [
        Licao(nome: 'Comida', emoji: '🍞', id: 't1.l1', trechos: [
          Trecho(cod: 'I want tea, milk, cake and bread.', dica: 'Quero chá, leite, bolo e pão.', out: ''),
        ]),
      ]),
    ];
    final curso = _CursoFake(CursoState(
      status: CursoStatus.pronto,
      trilhas: trilhas,
      linguagem: Linguagem.ingles,
      concluidas: const {'t1.l1'},
    ));
    final palavras = PalavrasCubit(
      repo: MemoriaPalavrasRepository(),
      carregarDicionario: () async =>
          const Dicionario({'want': 'querer', 'tea': 'chá', 'milk': 'leite', 'cake': 'bolo', 'bread': 'pão'}),
    );
    await tester.runAsync(() async {
      await palavras.carregar();
      await palavras.prepararIndice(trilhas);
    });
    final ranking = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');

    await tester.pumpWidget(BlocProvider.value(
      value: curso,
      child: BlocProvider.value(value: palavras, child: _app(ranking, const ArcadePage())),
    ));
    await tester.pump();
    palavras.registrarErros([
      for (var i = 0; i < 2; i++) EvidenciaPalavra(chave: 'cake', peso: 1, falha: 1, fonte: FonteErro.licao),
    ]);
    await tester.pump(Duration.zero);

    expect(find.byKey(const Key('arcade-teimosas')), findsOneWidget);
    expect(find.textContaining('🔥 1 teimosa: cake'), findsOneWidget);
    expect(find.textContaining('a mais teimosa'), findsNothing);
    expect(
        find.descendant(of: find.byKey(const Key('arcade-treinar-teimosas')), matching: find.text('🔥 Revanche')),
        findsOneWidget);
    expect(find.text('🎯 Treinar').evaluate().length, lessThanOrEqualTo(1), reason: 'o "🎯 Treinar" é só o do banco');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(() async {
      await palavras.gravacoes;
      await palavras.close();
      await curso.close();
      await ranking.close();
    });
  });
}

class _CursoFake extends CursoBloc {
  _CursoFake(CursoState s) : super(loader: CurriculoLoader(), progresso: LocalProgressoRepository()) {
    emit(s);
  }
}
