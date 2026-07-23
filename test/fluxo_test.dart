import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/core/theme/theme_cubit.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/voz_cubit.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/quiz_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/curso/presentation/widgets/victory_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Currículo mínimo: 1 trilha, 2 lições de 2 exercícios e 2 projetos.
/// (4 códigos na trilha = distratores suficientes para gerar quiz.)
Trecho _tr(String cod) => Trecho(cod: cod, dica: 'digite $cod', out: 'ok');

Projeto _proj(String nome, String cod) =>
    Projeto(nome: nome, emoji: '🛠️', descricao: 'projeto $nome', cod: cod, out: 'ok');

final _trilhaFake = Trilha(
  nivel: 'Fundamentos',
  emoji: '🌱',
  licoes: [
    Licao(nome: 'Licao A', emoji: '🅰', trechos: [_tr('var a = 1;'), _tr('var b = 2;')]),
    Licao(nome: 'Licao B', emoji: '🅱', trechos: [_tr('var c = 3;'), _tr('var d = 4;')]),
  ],
  projetos: [_proj('App Um', 'print(1);'), _proj('App Dois', 'print(2);')],
);

class _LoaderFake extends CurriculoLoader {
  @override
  Future<List<Trilha>> carregar() async => [_trilhaFake];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  // sem I/O de asset: o relógio falso do testWidgets nunca resolveria
  @override
  Future<MapaRodavel> carregarRodaveis() async =>
      const MapaRodavel(licoes: {'0:0': '11', '0:1': '10'}, projetos: {'proj:0:0'});
}

/// Auth fake já autenticado (o HUD pede o usuário logado).
class _AuthFake implements AuthRepository {
  static const _user = AppUser(uid: 'teste-uid', email: 'teste@pac.dart');
  @override
  Stream<AppUser?> get mudancas => Stream.value(_user);
  @override
  AppUser? get atual => _user;
  @override
  Future<void> entrar(String email, String senha) async {}
  @override
  Future<void> cadastrar(String email, String senha) async {}
  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async {}
}

class _RepoFake implements ProgressoRepository {
  final Set<String> licoes = {};
  final Map<String, int> notas = {};
  final Set<String> projetos = {};
  int trilha = 0, licao = 0, rec = 0;

  @override
  Future<Set<String>> concluidas() async => {...licoes};
  @override
  Future<void> marcarConcluida(String chave) async => licoes.add(chave);
  @override
  Future<(int, int)> posicao() async => (trilha, licao);
  @override
  Future<void> salvarPosicao(int t, int l) async {
    trilha = t;
    licao = l;
  }

  @override
  Future<Map<String, int>> quizNotas() async => {...notas};
  @override
  Future<void> salvarQuizNota(String chave, int acertos) async {
    if ((notas[chave] ?? -1) < acertos) notas[chave] = acertos;
  }

  @override
  Future<Set<String>> projetosFeitos() async => {...projetos};
  @override
  Future<void> marcarProjetoFeito(String chave) async => projetos.add(chave);
  @override
  Future<int> recorde() async => rec;
  @override
  Future<void> salvarRecorde(int score) async {
    if (score > rec) rec = score;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  Future<CursoBloc> montar(WidgetTester tester, _RepoFake repo, {Widget? tela}) async {
    SharedPreferences.setMockInitialValues({});
    final bloc = CursoBloc(loader: _LoaderFake(), progresso: repo)..add(const CursoIniciado());
    await tester.pumpWidget(MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => AuthCubit(_AuthFake())),
        BlocProvider.value(value: bloc),
        BlocProvider(create: (_) => TypingBloc()),
        BlocProvider(create: (_) => VozCubit()),
      ],
      child: MaterialApp(theme: Mixart.tema(), home: tela ?? const HomePage()),
    ));
    await tester.pump(); // currículo do fake carrega sem I/O
    await tester.pump();
    return bloc;
  }

  /// Digita a lição atual até o fim (só avança os trechos, sem teclar).
  Future<void> concluirLicao(WidgetTester tester, CursoBloc bloc) async {
    for (var i = 0; i < bloc.state.licao.trechos.length; i++) {
      bloc.add(const TrechoAvancado());
    }
    await tester.pump();
    await tester.pump();
  }

  group('sequência depois da lição', () {
    testWidgets('lição concluída chama o quiz sozinho, com opção de pular',
        (tester) async {
      final repo = _RepoFake();
      final bloc = await montar(tester, repo);

      await concluirLicao(tester, bloc);
      expect(bloc.state.vitoria, isTrue);
      expect(find.text('LIÇÃO CONCLUÍDA!'), findsOneWidget);
      expect(find.text('Fazer o quiz agora →'), findsOneWidget);
      expect(find.text('Pular quiz'), findsOneWidget);
      expect(find.textContaining('começa em seguida'), findsOneWidget);

      // ninguém tocou em nada: passada a contagem, o quiz entra sozinho
      await tester.pump(const Duration(milliseconds: 3500));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('QUIZ ·'), findsOneWidget);

      // pular volta ao fluxo: não era a última lição → vai para a próxima
      await tester.tap(
          find.descendant(of: find.byType(QuizPage), matching: find.text('Pular quiz')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(bloc.state.licaoIdx, 1);
      expect(bloc.state.vitoria, isFalse);
      expect(repo.licoes, {'0:0'});
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('no fim da trilha vêm os projetos, um a um', (tester) async {
      final repo = _RepoFake()..licoes.add('0:0'); // lição A já feita
      final bloc = await montar(tester, repo);
      bloc.add(const LicaoSelecionada(1));
      await tester.pump();

      await concluirLicao(tester, bloc);
      expect(find.textContaining('Depois vêm 2 apps'), findsOneWidget);

      // pula o quiz → primeiro projeto da trilha
      await tester.tap(find.text('Pular quiz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('MÃO NA MASSA · 1 DE 2'), findsOneWidget);
      expect(find.text('App Um'), findsOneWidget);

      // digitar o projeto inteiro marca ele como feito
      await tester.enterText(find.byType(TextField).last, 'print(1);');
      await tester.pump();
      expect(bloc.state.projetoFeito(CursoState.chaveProjeto(0, 0)), isTrue);
      expect(repo.projetos, {'proj:0:0'});

      // e o botão de concluído emenda no projeto seguinte
      await tester.tap(find.text('Projeto concluído — próximo →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('MÃO NA MASSA · 2 DE 2'), findsOneWidget);
      expect(find.text('App Dois'), findsOneWidget);

      // pular o último fecha a sequência e devolve para a próxima lição
      await tester.tap(find.text('Pular projeto'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(HomePage), findsOneWidget);
      expect(bloc.state.vitoria, isFalse);
      expect(repo.projetos, {'proj:0:0'}); // pulado não conta
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('overlay de vitória cabe numa tela de celular', (tester) async {
      tester.view.physicalSize = const Size(390, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final bloc = CursoBloc(loader: _LoaderFake(), progresso: _RepoFake())
        ..add(const CursoIniciado());
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider(create: (_) => TypingBloc()),
        ],
        child: MaterialApp(
          theme: Mixart.tema(),
          home: Scaffold(
            body: Stack(children: [
              VictoryOverlay(
                esperaAuto: const Duration(seconds: 3),
                projetosDepois: 3,
                onQuiz: () {},
                onPularQuiz: () {},
                onRepetir: () {},
              ),
            ]),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
      expect(find.text('Fazer o quiz agora →'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('sair pela seta interrompe a sequência', (tester) async {
      final repo = _RepoFake();
      final bloc = await montar(tester, repo);

      await concluirLicao(tester, bloc);
      await tester.tap(find.text('Fazer o quiz agora →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.textContaining('QUIZ ·'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(bloc.state.licaoIdx, 0); // não avançou
      expect(bloc.state.vitoria, isTrue); // segue na tela de vitória
      await tester.runAsync(() => bloc.close());
    });
  });

  group('progresso dos projetos', () {
    test('ProjetoConcluido guarda no estado e no repositório', () async {
      final repo = _RepoFake();
      final bloc = CursoBloc(loader: _LoaderFake(), progresso: repo)..add(const CursoIniciado());
      await Future<void>.delayed(Duration.zero);

      bloc.add(ProjetoConcluido(CursoState.chaveMaster(3)));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.projetoFeito('master:3'), isTrue);
      expect(repo.projetos, {'master:3'});
      await bloc.close();
    });

    test('projetos pendentes e lições da trilha', () async {
      final repo = _RepoFake()
        ..licoes.addAll({'0:0', '0:1'})
        ..projetos.add('proj:0:0');
      final bloc = CursoBloc(loader: _LoaderFake(), progresso: repo)..add(const CursoIniciado());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.trilhaSemLicoesPendentes(0), isTrue);
      expect(bloc.state.projetosPendentes(0), [1]);
      await bloc.close();
    });

    testWidgets('mapa mostra o projeto construído', (tester) async {
      final repo = _RepoFake()..projetos.add('proj:0:0');
      final bloc = await montar(tester, repo, tela: const MapaPage());
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('construído'), findsOneWidget);
      expect(find.textContaining('1 de 2 construídos'), findsOneWidget);
      await tester.runAsync(() => bloc.close());
    });
  });
}
