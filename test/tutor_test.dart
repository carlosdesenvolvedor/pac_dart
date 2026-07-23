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
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/tutor/data/tutor_service.dart';
import 'package:pac_dart/features/tutor/domain/contexto_estudo.dart';
import 'package:pac_dart/features/tutor/presentation/tutor_cubit.dart';
import 'package:pac_dart/features/tutor/presentation/tutor_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tutor de mentira: grava o que recebeu e responde em pedaços.
class _TutorFake implements TutorService {
  String? contexto, historico, pergunta;
  List<String> resposta = ['Piu! ', 'Isso é uma **lista**.'];
  bool falha = false;

  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    this.contexto = contexto;
    this.historico = historico;
    this.pergunta = pergunta;
    if (falha) throw Exception('Gemini 403: PERMISSION_DENIED (referer bloqueado)');
    for (final r in resposta) {
      yield r;
    }
  }
}

Trecho _tr(String cod) => Trecho(cod: cod, dica: 'digite <b>$cod</b>', out: 'ok');

final _trilhaFake = Trilha(
  nivel: 'Fundamentos',
  emoji: '🌱',
  licoes: [
    Licao(
        nome: 'Licao A',
        emoji: '🅰',
        resumo: 'Variáveis guardam valores.',
        trechos: [_tr('var a = 1;'), _tr('var b = 2;')]),
  ],
);

class _LoaderFake extends CurriculoLoader {
  @override
  Future<List<Trilha>> carregar() async => [_trilhaFake];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  SharedPreferences.setMockInitialValues({});

  Future<CursoBloc> cursoPronto() async {
    final bloc = CursoBloc(loader: _LoaderFake(), progresso: LocalProgressoRepository())
      ..add(const CursoIniciado());
    await Future<void>.delayed(Duration.zero);
    return bloc;
  }

  group('contextoDoEstudo', () {
    test('o Prof. Dash enxerga trilha, lição, trecho e desempenho', () async {
      final bloc = await cursoPronto();
      const typing = TypingState(
          chars: ['v', 'a'], idx: 1, acertosSessao: 98, errosSessao: 2);
      final ctx = contextoDoEstudo(bloc.state, typing);
      expect(ctx, contains('Fundamentos'));
      expect(ctx, contains('Licao A'));
      expect(ctx, contains('Variáveis guardam valores.'));
      expect(ctx, contains('var a = 1;'));
      expect(ctx, contains('trecho 1 de 2'));
      expect(ctx, contains('98% de precisão'));
      expect(ctx, contains('2 erro(s)'));
      await bloc.close();
    });

    test('currículo carregando não quebra o contexto', () {
      expect(contextoDoEstudo(const CursoState(), const TypingState()),
          contains('carregando'));
    });
  });

  group('TutorCubit', () {
    test('pergunta leva o contexto e a resposta chega em pedaços', () async {
      final fake = _TutorFake();
      final cubit = TutorCubit(service: fake);
      await cubit.perguntar('O que é lista?', 'CTX-DA-LICAO');

      expect(fake.contexto, 'CTX-DA-LICAO');
      expect(fake.pergunta, 'O que é lista?');
      expect(cubit.state.mensagens, hasLength(2));
      expect(cubit.state.mensagens.first.doAluno, isTrue);
      expect(cubit.state.mensagens.last.texto, 'Piu! Isso é uma **lista**.');
      expect(cubit.state.digitando, isFalse);
      await cubit.close();
    });

    test('a conversa recente vai junto (memória curta)', () async {
      final fake = _TutorFake();
      final cubit = TutorCubit(service: fake);
      await cubit.perguntar('Primeira?', 'CTX');
      await cubit.perguntar('Segunda?', 'CTX');
      expect(fake.historico, contains('Aluno: Primeira?'));
      expect(fake.historico, contains('Prof. Dash: Piu!'));
      await cubit.close();
    });

    test('erro de credencial vira recado amigável (trava de domínio)', () async {
      final fake = _TutorFake()..falha = true;
      final cubit = TutorCubit(service: fake);
      await cubit.perguntar('Oi?', 'CTX');
      expect(cubit.state.mensagens.last.texto, contains('pac-dart.web.app'));
      expect(cubit.state.digitando, isFalse);
      await cubit.close();
    });

    test('pergunta vazia é ignorada', () async {
      final cubit = TutorCubit(service: _TutorFake());
      await cubit.perguntar('   ', 'CTX');
      expect(cubit.state.mensagens, isEmpty);
      await cubit.close();
    });
  });

  group('TutorPanel', () {
    testWidgets('chip mostra o que ele vê; sugestão envia com contexto do trecho',
        (tester) async {
      final fake = _TutorFake();
      final curso = (await tester.runAsync(cursoPronto))!;
      final cubit = TutorCubit(service: fake);

      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: curso),
          BlocProvider(create: (_) => TypingBloc()),
          BlocProvider(create: (_) => VozCubit()),
          BlocProvider.value(value: cubit),
        ],
        child: MaterialApp(
          theme: Mixart.tema(),
          home: Scaffold(body: SizedBox(width: 340, child: TutorPanel())),
        ),
      ));
      await tester.pump();

      expect(find.text('Prof. Dash'), findsOneWidget);
      expect(find.textContaining('👀 vendo:'), findsOneWidget);
      expect(find.textContaining('Licao A'), findsOneWidget);

      // sugestão dispara a pergunta já com o trecho atual no contexto
      await tester.tap(find.text('O que esse trecho faz?'));
      await tester.pump();
      await tester.pump();
      expect(fake.contexto, contains('var a = 1;'));
      expect(find.text('O que esse trecho faz?'), findsOneWidget); // bolha do aluno
      expect(find.textContaining('Piu!'), findsOneWidget); // resposta

      // a voz do professor: toggle no cabeçalho + "ouvir" na resposta
      expect(find.byIcon(Icons.volume_up), findsOneWidget);
      expect(find.text('ouvir'), findsOneWidget);
      await tester.tap(find.text('ouvir')); // fallback silencioso na VM
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(Container());
      await tester.runAsync(() async {
        await curso.close();
        await cubit.close();
      });
    });
  });

  group('HomePage + tutor', () {
    Widget app(CursoBloc curso, TutorCubit tutor) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => ThemeCubit()),
            BlocProvider(create: (_) => AuthCubit(_AuthFake())),
            BlocProvider.value(value: curso),
            BlocProvider(create: (_) => TypingBloc()),
            BlocProvider(create: (_) => VozCubit()),
            BlocProvider.value(value: tutor),
          ],
          child: MaterialApp(theme: Mixart.tema(), home: const HomePage()),
        );

    testWidgets('tela larga: painel fixo à esquerda', (tester) async {
      tester.view.physicalSize = const Size(1600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final curso = (await tester.runAsync(cursoPronto))!;
      final tutor = TutorCubit(service: _TutorFake());
      await tester.pumpWidget(app(curso, tutor));
      await tester.pump();
      await tester.pump();

      expect(find.text('tutor de Dart · vê o seu estudo'), findsOneWidget);
      expect(find.byType(BotaoTutor), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(Container());
      await tester.runAsync(() async {
        await curso.close();
        await tutor.close();
      });
    });

    testWidgets('tela estreita: vira botão flutuante à esquerda', (tester) async {
      final curso = (await tester.runAsync(cursoPronto))!;
      final tutor = TutorCubit(service: _TutorFake());
      await tester.pumpWidget(app(curso, tutor));
      await tester.pump();
      await tester.pump();

      expect(find.byType(BotaoTutor), findsOneWidget);
      expect(find.text('tutor de Dart · vê o seu estudo'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(Container());
      await tester.runAsync(() async {
        await curso.close();
        await tutor.close();
      });
    });
  });
}
