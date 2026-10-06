import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/linguagem/linguagem_cubit.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/core/theme/theme_cubit.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/desafios_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/escolha_linguagem_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Uma trilha C# de mentira com um desafio de cada tipo.
final _trilhaCs = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '🌱',
  etapa: 'Iniciante',
  fundo: 'fundamentos',
  perfil: 'console',
  licoes: const [
    Licao(nome: 'Olá', emoji: '👋', trechos: [
      Trecho(cod: 'Console.WriteLine("Oi");', dica: 'imprime', out: 'Oi'),
      Trecho(cod: 'int x = 1;', dica: 'int', out: 'x = 1'),
    ]),
  ],
  desafios: const [
    DesafioLogica(
      tipo: TipoDesafioLogica.saida,
      titulo: 'Contagem',
      enunciado: 'O que imprime?',
      cod: 'for (int i = 0; i < 3; i++)\n{\n    Console.Write(i);\n}',
      opcoes: ['123', '012', '0123', '01'],
      certa: 1,
      explicacao: 'i vai de 0 a 2.',
      nivel: 1,
    ),
    DesafioLogica(
      tipo: TipoDesafioLogica.valor,
      titulo: 'Vida do herói',
      enunciado: 'Qual o valor final de vida?',
      cod: 'int vida = 100;\nvida -= 35;',
      resposta: '65',
      explicacao: '100 - 35 = 65.',
      nivel: 1,
      tema: 'jogo',
    ),
    DesafioLogica(
      tipo: TipoDesafioLogica.ordenar,
      titulo: 'Soma',
      enunciado: 'Ponha em ordem',
      linhas: ['int soma = 0;', 'soma += 5;', 'Console.WriteLine(soma);'],
      esperado: '5',
      explicacao: 'declara, soma, mostra.',
      nivel: 2,
    ),
    DesafioLogica(
      tipo: TipoDesafioLogica.bug,
      titulo: 'Média',
      enunciado: 'Deveria imprimir 7,5',
      linhas: ['int a = 7;', 'int b = 8;', 'double m = (a + b) / 2;', 'Console.WriteLine(m);'],
      linhaBug: 2,
      correcao: 'double m = (a + b) / 2.0;',
      esperado: '7,5',
      explicacao: 'divisão inteira.',
      nivel: 3,
    ),
  ],
);

class _LoaderCs extends CurriculoLoader {
  _LoaderCs() : super(linguagem: Linguagem.csharp);
  @override
  Future<List<Trilha>> carregar() async => [_trilhaCs];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

/// Dá tempo REAL (rootBundle, prefs) até [alvo] aparecer ou ~4 s passarem.
Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 20 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('sem escolha salva, o app abre em "Escolha sua trilha" e a tecla 1 entra no Dart', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(PacDartApp(
        authCubitOverride: AuthCubit(_AuthFake()),
        progressoBuilder: (_) => LocalProgressoRepository(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    expect(find.byType(EscolhaLinguagemPage), findsOneWidget);
    expect(find.text('Escolha sua trilha'), findsOneWidget);
    expect(find.text('Estudar C# & .NET'), findsOneWidget);
    expect(find.text('Estudar Dart & Flutter'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await _esperar(tester, find.text('SCORE'));
    expect(find.byType(EscolhaLinguagemPage), findsNothing);
    expect(find.text('SCORE'), findsOneWidget);
    expect(Linguagem.atual, Linguagem.dart);
    final p = await SharedPreferences.getInstance();
    expect(p.getString(LinguagemCubit.chaveDe('teste-uid')), 'dart');
  });

  testWidgets('a escolha é por CONTA: a de outra pessoa no mesmo navegador não vale para mim', (tester) async {
    SharedPreferences.setMockInitialValues({LinguagemCubit.chaveDe('outra-conta'): 'csharp'});
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(PacDartApp(
        authCubitOverride: AuthCubit(_AuthFake()),
        progressoBuilder: (_) => LocalProgressoRepository(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    expect(find.byType(EscolhaLinguagemPage), findsOneWidget);
    expect(Linguagem.atual, Linguagem.dart);
  });

  testWidgets('a escolha salva pula a tela; o ⇄ do HUD abre a escolha e a MESMA linguagem só volta', (tester) async {
    SharedPreferences.setMockInitialValues({LinguagemCubit.chaveDe('teste-uid'): 'dart'});
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(PacDartApp(
        authCubitOverride: AuthCubit(_AuthFake()),
        progressoBuilder: (_) => LocalProgressoRepository(),
        curriculoBuilder: (_) => _LoaderCs(),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump();
    });
    await _esperar(tester, find.text('DART & FLUTTER'));
    expect(find.byType(EscolhaLinguagemPage), findsNothing);
    expect(find.text('DART & FLUTTER'), findsOneWidget);

    // (o relógio do HUD redesenha todo segundo: pumpAndSettle nunca assenta)
    Future<void> anda() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    await tester.tap(find.text('DART & FLUTTER'));
    await anda();
    expect(find.byType(EscolhaLinguagemPage), findsOneWidget);
    expect(find.text('ESTUDANDO'), findsOneWidget);
    expect(find.text('Continuar em Dart & Flutter'), findsOneWidget);

    // escolher o Dart de novo não recria nada: só fecha a tela
    await tester.tap(find.text('Continuar em Dart & Flutter'));
    await anda();
    expect(find.byType(EscolhaLinguagemPage), findsNothing);
    expect(find.text('DART & FLUTTER'), findsOneWidget);
    expect(Linguagem.atual, Linguagem.dart);
  });

  group('página de desafios de lógica', () {
    late CursoBloc bloc;
    late LocalProgressoRepository repo;

    Future<void> abrir(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repo = LocalProgressoRepository(prefixo: 'cs_');
      bloc = CursoBloc(loader: _LoaderCs(), progresso: repo)..add(const CursoIniciado());
      await tester.runAsync(() async {
        await tester.pumpWidget(MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider.value(value: bloc),
          ],
          child: MaterialApp(
            theme: Mixart.tema(),
            home: const SizedBox(),
          ),
        ));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(bloc.state.status, CursoStatus.pronto);
      expect(bloc.state.ehCSharp, isTrue);
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute<bool>(
        builder: (_) => DesafiosPage(trilhaIdx: 0, trilha: _trilhaCs, semente: 1),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('responde os 4 tipos, marca o progresso e mostra o placar', (tester) async {
      await abrir(tester);
      expect(find.text('DESAFIOS DE LÓGICA'), findsOneWidget);

      // a fila vem do mais fácil ao mais difícil: nível 1 (saida/valor), 2, 3
      for (var passo = 0; passo < 4; passo++) {
        if (find.text('Qual é a saída?').evaluate().isNotEmpty) {
          await tester.tap(find.text('012'));
        } else if (find.text('Valor final').evaluate().isNotEmpty) {
          await tester.enterText(find.byType(TextField), '65');
          await tester.testTextInput.receiveAction(TextInputAction.done);
        } else if (find.text('Ponha em ordem').evaluate().isNotEmpty) {
          await tester.tap(find.text('int soma = 0;'));
          await tester.pump();
          await tester.tap(find.text('soma += 5;'));
          await tester.pump();
          await tester.tap(find.text('Console.WriteLine(soma);'));
          await tester.pump();
          await tester.tap(find.text('Conferir (Enter)'));
        } else if (find.text('Ache o bug').evaluate().isNotEmpty) {
          await tester.tap(find.text('double m = (a + b) / 2;'));
        } else {
          fail('tipo de desafio inesperado no passo $passo');
        }
        await tester.pump();
        expect(find.text('Acertou!'), findsOneWidget, reason: 'passo $passo');
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
      }
      expect(find.text('Você acertou 4 de 4'), findsOneWidget);
      expect(bloc.state.desafiosFeitos(0), 4);
      expect(await repo.projetosFeitos(), containsAll(['desafio:0:0', 'desafio:0:1', 'desafio:0:2', 'desafio:0:3']));
      await tester.runAsync(() => bloc.close());
    });

    testWidgets('errar mostra o gabarito e não marca o desafio', (tester) async {
      await abrir(tester);
      // primeiro desafio (nível 1): responde errado, seja qual for
      if (find.text('Qual é a saída?').evaluate().isNotEmpty) {
        await tester.tap(find.text('123'));
      } else {
        await tester.enterText(find.byType(TextField), '99');
        await tester.testTextInput.receiveAction(TextInputAction.done);
      }
      await tester.pump();
      expect(find.text('Não foi dessa vez'), findsOneWidget);
      expect(bloc.state.desafiosFeitos(0), 0);
      await tester.runAsync(() => bloc.close());
    });
  });
}
