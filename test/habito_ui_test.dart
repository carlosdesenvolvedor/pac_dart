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
import 'package:pac_dart/features/curso/domain/quiz.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/voz_cubit.dart';
import 'package:pac_dart/features/curso/presentation/fluxo_licao.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/projeto_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/quiz_page.dart';
import 'package:pac_dart/features/curso/presentation/widgets/hud.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/habito/presentation/widgets/chip_sequencia.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RepoMemoria implements HabitoRepository {
  Habito guardado;
  _RepoMemoria([this.guardado = Habito.vazio]);
  @override
  Future<Habito> carregar() async => guardado;
  @override
  Future<void> salvar(Habito habito) async => guardado = habito;
}

class _Relogio {
  DateTime t = DateTime(2026, 10, 12, 10);
  DateTime call() => t;
  void dias(int n) => t = DateTime(t.year, t.month, t.day + n, 10);
}

int _dia(int depois) => diaDe(DateTime(2026, 10, 12 + depois));

/// Uma sequência de [seq] dias com a última meta [ultima] dias atrás (0 = hoje).
Habito _viva(int seq, {int ultima = 0, int frz = 0, int meta = 20, int unidades = 0, List<int> congelados = const []}) => Habito(
      meta: meta,
      dia: _dia(-ultima),
      unidadesHoje: unidades,
      sequencia: seq,
      melhor: seq + 3,
      ultimoDiaMeta: _dia(-ultima),
      congelamentos: frz,
      historico: [for (var i = 0; i < seq; i++) _dia(-ultima - i)]..sort(),
      congelados: congelados,
    );

// ---- currículo mínimo do Dart (como em fluxo_test) -------------------------------------------

Trecho _tr(String cod) => Trecho(cod: cod, dica: 'digite $cod', out: 'ok');

final _trilha = Trilha(
  nivel: 'Fundamentos',
  emoji: '🌱',
  licoes: [
    Licao(nome: 'Licao A', emoji: '🅰', trechos: [_tr('var a = 1;'), _tr('var b = 2;'), _tr('var c = 3;')]),
    // 5 trechos: o suficiente para gerar um quiz
    Licao(
        nome: 'Licao B',
        emoji: '🅱',
        trechos: [_tr('var d = 4;'), _tr('var e = 5;'), _tr('var f = 6;'), _tr('var g = 7;'), _tr('var h = 8;')]),
  ],
  projetos: [Projeto(nome: 'App Um', emoji: '🛠️', descricao: 'projeto', cod: 'print(1);', out: 'ok')],
);

class _Loader extends CurriculoLoader {
  @override
  Future<List<Trilha>> carregar() async => [_trilha];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

/// Progresso em memória (o de prefs usa I/O de verdade, que o relógio falso do teste não espera).
class _Progresso implements ProgressoRepository {
  final licoes = <String>{};
  final notas = <String, int>{};
  final projetos = <String>{};
  int _t = 0, _l = 0, _rec = 0;
  @override
  Future<Set<String>> concluidas() async => {...licoes};
  @override
  Future<void> marcarConcluida(String chave) async => licoes.add(chave);
  @override
  Future<(int, int)> posicao() async => (_t, _l);
  @override
  Future<void> salvarPosicao(int t, int l) async {
    _t = t;
    _l = l;
  }

  @override
  Future<Map<String, int>> quizNotas() async => {...notas};
  @override
  Future<void> salvarQuizNota(String chave, int acertos) async => notas[chave] = acertos;
  @override
  Future<Set<String>> projetosFeitos() async => {...projetos};
  @override
  Future<void> marcarProjetoFeito(String chave) async => projetos.add(chave);
  @override
  Future<int> recorde() async => _rec;
  @override
  Future<void> salvarRecorde(int score) async => _rec = score;
}

class _Auth implements AuthRepository {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  late _Relogio relogio;
  setUp(() {
    relogio = _Relogio();
    SharedPreferences.setMockInitialValues({});
  });

  Future<HabitoCubit> cubitCom(WidgetTester tester, [Habito? inicial]) async {
    final c = HabitoCubit(repo: _RepoMemoria(inicial ?? Habito.vazio), agora: relogio.call);
    await tester.runAsync(() => c.carregar());
    addTearDown(() => tester.runAsync(c.close));
    return c;
  }

  /// O chip sozinho, num Scaffold (que também mostra o aviso).
  Future<void> montarChip(WidgetTester tester, HabitoCubit c, {Size tela = const Size(900, 900)}) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(BlocProvider.value(
      value: c,
      child: MaterialApp(
        theme: Mixart.tema(),
        home: const Scaffold(body: Center(child: ChipSequencia())),
      ),
    ));
    await tester.pump();
  }

  /// Os blocs entregam eventos por stream: dá alguns quadros para tudo chegar.
  Future<void> anda(WidgetTester tester, [int quadros = 3]) async {
    for (var i = 0; i < quadros; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  String rotulo(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data!;

  group('o chip do cabeçalho', () {
    testWidgets('sem a Cubit na árvore (testes antigos) ele não existe', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: ChipSequencia())));
      expect(find.byKey(const Key('chip-sequencia')), findsNothing);
    });

    testWidgets('sem sequência: convite "Comece hoje", nunca "0 dias"', (tester) async {
      final c = await cubitCom(tester);
      await montarChip(tester, c);
      expect(rotulo(tester), 'Comece hoje');
      expect(find.textContaining('0'), findsNothing);
      expect(find.byType(AnelDaMeta), findsOneWidget);
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).acesa, isFalse);
    });

    testWidgets('começou hoje mas ainda sem sequência: mostra o andamento da meta', (tester) async {
      final c = await cubitCom(tester);
      c.praticou(7);
      await montarChip(tester, c);
      expect(rotulo(tester), '7/20');
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, closeTo(.35, 1e-9));
    });

    testWidgets('sequência viva e hoje ainda sem meta ("em risco"): número, anel parcial e borda realçada', (tester) async {
      final c = await cubitCom(tester, _viva(4, ultima: 1, unidades: 0));
      c.praticou(5);
      await montarChip(tester, c);
      expect(rotulo(tester), '4');
      final anel = tester.widget<AnelDaMeta>(find.byType(AnelDaMeta));
      expect(anel.acesa, isTrue);
      expect(anel.progresso, closeTo(.25, 1e-9));
      final deco = tester.widget<AnimatedContainer>(find.descendant(of: find.byKey(const Key('chip-sequencia')), matching: find.byType(AnimatedContainer))).decoration as BoxDecoration;
      expect((deco.border as Border).top.color, Mixart.brand, reason: 'realce de "estude hoje"');
    });

    testWidgets('meta batida: anel cheio e o número sobe', (tester) async {
      final c = await cubitCom(tester, _viva(4, ultima: 1));
      await montarChip(tester, c);
      expect(rotulo(tester), '4');
      c.praticou(20);
      await anda(tester);
      expect(rotulo(tester), '5');
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, 1);
    });

    testWidgets('um dia perdido SEM congelamento: o chip convida a recomeçar (não mostra o número velho)', (tester) async {
      final c = await cubitCom(tester, _viva(9, ultima: 2, frz: 0));
      await montarChip(tester, c);
      expect(rotulo(tester), 'Comece hoje');
      expect(find.text('9'), findsNothing);
    });

    testWidgets('um dia perdido COM congelamento: a sequência segue viva', (tester) async {
      final c = await cubitCom(tester, _viva(9, ultima: 2, frz: 1));
      await montarChip(tester, c);
      expect(rotulo(tester), '9');
    });

    testWidgets('a virada do dia com o app aberto zera o anel', (tester) async {
      final c = await cubitCom(tester, _viva(3, ultima: 0));
      await montarChip(tester, c);
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, 1);
      relogio.dias(1);
      c.praticou(2); // qualquer coisa que redesenhe: o chip relê o relógio
      await anda(tester);
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, closeTo(.1, 1e-9));
      expect(rotulo(tester), '3', reason: 'ontem bateu, hoje ainda dá tempo');
    });
  });

  group('o aviso de meta batida', () {
    testWidgets('aparece UMA vez por dia, com os dias seguidos, e some sozinho', (tester) async {
      final c = await cubitCom(tester, _viva(3, ultima: 1));
      await montarChip(tester, c);
      expect(find.byKey(const Key('aviso-meta-batida')), findsNothing);

      c.praticou(19);
      await tester.pump();
      expect(find.byKey(const Key('aviso-meta-batida')), findsNothing, reason: 'ainda faltava 1');
      c.praticou(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Meta de hoje batida! 🔥 4 dias'), findsOneWidget);

      // some depois do tempo
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('aviso-meta-batida')), findsNothing);

      // mais exercícios no mesmo dia: não avisa de novo
      c.praticou(10);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('aviso-meta-batida')), findsNothing);

      // no dia seguinte, ao bater de novo, avisa outra vez
      relogio.dias(1);
      c.praticou(20);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Meta de hoje batida! 🔥 5 dias'), findsOneWidget);
    });

    testWidgets('primeiro dia: "1 dia" no singular', (tester) async {
      final c = await cubitCom(tester);
      await montarChip(tester, c);
      c.praticou(20);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Meta de hoje batida! 🔥 1 dia'), findsOneWidget);
    });

    testWidgets('abrir o app com a meta de hoje já batida não avisa de novo', (tester) async {
      final c = await cubitCom(tester, _viva(6, ultima: 0));
      await montarChip(tester, c);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byKey(const Key('aviso-meta-batida')), findsNothing);
    });
  });

  group('a folha "Sua sequência"', () {
    Future<void> abrir(WidgetTester tester, HabitoCubit c, {Size tela = const Size(900, 1000)}) async {
      await montarChip(tester, c, tela: tela);
      await tester.tap(find.byKey(const Key('chip-sequencia')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('mostra dias seguidos, melhor, progresso de hoje e congelamentos', (tester) async {
      final c = await cubitCom(tester, _viva(12, ultima: 1, frz: 2, unidades: 0));
      c.praticou(8);
      await abrir(tester, c);
      expect(find.byKey(const Key('sequencia-sheet')), findsOneWidget);
      expect(find.text('12 dias seguidos'), findsOneWidget);
      expect(find.textContaining('Faltam 12 exercícios hoje'), findsOneWidget);
      expect(find.text('8/20'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('numero-melhor')), matching: find.text('15 dias')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('numero-congelamentos')), matching: find.text('❄️ 2/2')), findsOneWidget);
    });

    testWidgets('meta batida hoje: mensagem de volte amanhã', (tester) async {
      final c = await cubitCom(tester, _viva(1, ultima: 0));
      c.praticou(20);
      await abrir(tester, c);
      expect(find.text('1 dia seguido'), findsOneWidget);
      expect(find.textContaining('Meta de hoje batida'), findsWidgets);
      expect(find.textContaining('Volte amanhã'), findsOneWidget);
    });

    testWidgets('sem sequência: convite para recomeçar, sem culpa', (tester) async {
      final c = await cubitCom(tester, _viva(9, ultima: 4));
      await abrir(tester, c);
      expect(find.text('Comece hoje'), findsWidgets);
      expect(find.textContaining('Recomece hoje'), findsOneWidget);
      expect(find.textContaining('perdeu'), findsNothing);
      expect(find.textContaining('9 dias'), findsNothing);
    });

    testWidgets('primeira vez: convite com a meta', (tester) async {
      final c = await cubitCom(tester);
      await abrir(tester, c);
      expect(find.textContaining('acenda sua primeira chama'), findsOneWidget);
    });

    testWidgets('últimos 14 dias: feito, congelado, perdido e hoje', (tester) async {
      // fez os dias -6..-3, congelou -2 e -1 não existe: foi ontem (-1) que bateu
      final h = Habito(
        meta: 20,
        dia: _dia(-1),
        sequencia: 5,
        melhor: 5,
        ultimoDiaMeta: _dia(-1),
        congelamentos: 0,
        historico: [_dia(-7), _dia(-5), _dia(-4), _dia(-3), _dia(-1)],
        congelados: [_dia(-2)],
      );
      final c = await cubitCom(tester, h);
      await abrir(tester, c);
      expect(find.byKey(const Key('dia-feito')), findsNWidgets(5));
      expect(find.byKey(const Key('dia-congelado')), findsNWidgets(1));
      expect(find.byKey(const Key('dia-hoje')), findsNWidgets(1));
      // -6 (entre dois feitos) foi perdido; antes de -7 ninguém tinha começado
      expect(find.byKey(const Key('dia-perdido')), findsNWidgets(1));
      expect(find.byKey(const Key('dia-antes')), findsNWidgets(6));
      expect(find.byKey(const Key('dia-feito')).evaluate().length + find.byKey(const Key('dia-congelado')).evaluate().length + 1 + 1 + 6, 14);
    });

    testWidgets('trocar a meta: grava e o anel/progresso acompanham', (tester) async {
      final c = await cubitCom(tester, _viva(2, ultima: 1));
      c.praticou(12);
      await abrir(tester, c);
      expect(find.text('12/20'), findsOneWidget);
      await tester.tap(find.byKey(const Key('meta-40')));
      await tester.pump();
      expect(c.state.habito.meta, 40);
      expect(find.text('12/40'), findsOneWidget);
      // baixar depois de já ter feito: 12 ≥ 10 → a meta de hoje conta como batida
      await tester.tap(find.byKey(const Key('meta-10')));
      await tester.pump();
      expect(c.state.habito.meta, 10);
      expect(c.state.habito.bateuHoje(relogio.t), isTrue);
      expect(c.state.habito.sequencia, 3);
      expect(find.text('3 dias seguidos'), findsOneWidget);
    });

    testWidgets('celular de 360 px: sem estouro na folha nem no chip', (tester) async {
      final c = await cubitCom(tester, _viva(15, ultima: 0, frz: 1));
      await abrir(tester, c, tela: const Size(360, 740));
      expect(find.byKey(const Key('sequencia-sheet')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byKey(const Key('sequencia-sheet')), const Offset(0, -400));
      await tester.pump();
      expect(find.byKey(const Key('meta-40')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tema claro também (sem texto invisível nem estouro)', (tester) async {
      final c = await cubitCom(tester, _viva(15, ultima: 0, frz: 1));
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await abrir(tester, c, tela: const Size(360, 740));
      expect(tester.takeException(), isNull);
      expect(find.text('15 dias seguidos'), findsOneWidget);
    });
  });

  group('no cabeçalho de verdade (Hud)', () {
    Future<HabitoCubit> montarHud(WidgetTester tester, {required Size tela}) async {
      tester.view.physicalSize = tela;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final c = await cubitCom(tester, _viva(7, ultima: 1));
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => AuthCubit(_Auth())),
          BlocProvider(create: (_) => TypingBloc()),
          BlocProvider(create: (_) => VozCubit()),
          BlocProvider.value(value: c),
        ],
        child: MaterialApp(theme: Mixart.tema(), home: const Scaffold(body: SingleChildScrollView(child: Hud()))),
      ));
      await tester.pump();
      return c;
    }

    for (final largura in [1027.0, 390.0, 360.0]) {
      testWidgets('a ${largura.toInt()} px o chip aparece e nada estoura', (tester) async {
        await montarHud(tester, tela: Size(largura, 900));
        expect(find.byKey(const Key('chip-sequencia')), findsOneWidget);
        expect(rotulo(tester), '7');
        expect(tester.takeException(), isNull);
        // o relógio do Hud (1 s) redesenha sem problema
        await tester.pump(const Duration(seconds: 2));
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('ganchos de contagem (Dart & C#)', () {
    Future<(CursoBloc, HabitoCubit)> montarCurso(WidgetTester tester, {Widget? tela}) async {
      final c = await cubitCom(tester);
      final bloc = CursoBloc(loader: _Loader(), progresso: _Progresso());
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ThemeCubit()),
          BlocProvider(create: (_) => AuthCubit(_Auth())),
          BlocProvider.value(value: bloc),
          BlocProvider(create: (_) => TypingBloc()),
          BlocProvider(create: (_) => VozCubit()),
          BlocProvider.value(value: c),
        ],
        child: MaterialApp(theme: Mixart.tema(), home: tela ?? const HomePage()),
      ));
      // só agora o currículo carrega (como no app: a tela já está ouvindo quando o 1º trecho chega)
      bloc.add(const CursoIniciado());
      await anda(tester, 6);
      addTearDown(() => tester.runAsync(bloc.close));
      return (bloc, c);
    }

    testWidgets('digitar o trecho até o fim conta 1; avançar/pular sem digitar não conta', (tester) async {
      final (bloc, habito) = await montarCurso(tester);
      expect(habito.state.habito.unidadesHoje, 0);

      await tester.enterText(find.byType(TextField).last, 'var a = 1;');
      await anda(tester);
      expect(habito.state.habito.unidadesHoje, 1, reason: 'o trecho concluído conta');
      expect(find.byKey(const Key('chip-sequencia')), findsOneWidget);

      // passar ao próximo sem digitar (pular/voltar usam o mesmo evento) não soma
      bloc.add(const TrechoAvancado());
      await anda(tester);
      bloc.add(const TrechoAvancado());
      await anda(tester);
      expect(habito.state.habito.unidadesHoje, 1);
    });

    testWidgets('o anel sobe com cada trecho e a lição inteira soma 1 por trecho', (tester) async {
      final (bloc, habito) = await montarCurso(tester);
      for (final cod in ['var a = 1;', 'var b = 2;', 'var c = 3;']) {
        await tester.enterText(find.byType(TextField).last, cod);
        await anda(tester);
        bloc.add(const TrechoAvancado());
        await anda(tester);
      }
      expect(habito.state.habito.unidadesHoje, 3);
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, closeTo(3 / 20, 1e-9));
    });

    testWidgets('quiz: cada pergunta respondida conta 1 (clique ou digitando), "Pular quiz" não', (tester) async {
      final licao = _trilha.licoes[1];
      final pool = licao.trechos.map((t) => t.cod).toList();
      final perguntas = gerarQuiz(licao, pool, seed: sementeQuiz(0, 1));
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final habito = await cubitCom(tester);
      await tester.pumpWidget(BlocProvider.value(
        value: habito,
        child: MaterialApp(
          theme: Mixart.tema(),
          home: QuizPage(trilhaIdx: 0, licaoIdx: 1, licao: licao, poolTrilha: pool),
        ),
      ));
      await tester.pump();
      expect(habito.state.habito.unidadesHoje, 0);

      final certa = perguntas.first.correta;
      await tester.tap(find.text(String.fromCharCode(65 + certa)));
      await tester.pump();
      expect(habito.state.habito.unidadesHoje, 1);
      // clicar de novo na mesma pergunta (já respondida) não soma
      await tester.tap(find.text(String.fromCharCode(65 + certa)));
      await tester.pump();
      expect(habito.state.habito.unidadesHoje, 1);
    });

    testWidgets('quiz digitando a resposta e tocando em Responder também conta 1 (uma vez)', (tester) async {
      final licao = _trilha.licoes[1];
      final pool = licao.trechos.map((t) => t.cod).toList();
      final perguntas = gerarQuiz(licao, pool, seed: sementeQuiz(0, 1));
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final habito = await cubitCom(tester);
      await tester.pumpWidget(BlocProvider.value(
        value: habito,
        child: MaterialApp(
          theme: Mixart.tema(),
          home: QuizPage(trilhaIdx: 0, licaoIdx: 1, licao: licao, poolTrilha: pool),
        ),
      ));
      await tester.pump();
      await tester.enterText(find.byType(TextField).last, perguntas.first.codigoCerto);
      await tester.pump();
      await tester.ensureVisible(find.text('Responder'));
      await tester.pump();
      await tester.tap(find.text('Responder'));
      await tester.pump();
      expect(habito.state.habito.unidadesHoje, 1);
      expect(find.text('Responder'), findsNothing, reason: 'respondida: o botão some, não há como contar de novo');
    });

    Future<HabitoCubit> abrirProjeto(WidgetTester tester) async {
      final c = await cubitCom(tester);
      final bloc = CursoBloc(loader: _Loader(), progresso: _Progresso())..add(const CursoIniciado());
      addTearDown(() => tester.runAsync(bloc.close));
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: bloc),
          BlocProvider(create: (_) => VozCubit()),
          BlocProvider.value(value: c),
        ],
        child: MaterialApp(
          theme: Mixart.tema(),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(
                builder: (_) => ProjetoPage(
                  nivel: 'Fundamentos',
                  projeto: _trilha.projetos.first,
                  chaveProgresso: 'proj:0:0',
                  emSequencia: true,
                ),
              )),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      return c;
    }

    testWidgets('Mão na Massa: digitar o projeto até o fim conta 1', (tester) async {
      final c = await abrirProjeto(tester);
      expect(c.state.habito.unidadesHoje, 0);
      await tester.enterText(find.byType(TextField).last, 'print(1);');
      await tester.pump();
      expect(c.state.habito.unidadesHoje, 1);
    });

    testWidgets('Mão na Massa: "Pular projeto" não é exercício', (tester) async {
      final c = await abrirProjeto(tester);
      await tester.tap(find.text('Pular projeto'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(c.state.habito.unidadesHoje, 0);
    });
  });
}
