import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/linguagem/linguagem.dart';
import 'core/linguagem/linguagem_cubit.dart';
import 'core/theme/mixart.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/domain/app_user.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/curso/data/curriculo_loader.dart';
import 'features/curso/data/firestore_progresso_repository.dart';
import 'features/curso/data/progresso_repository.dart';
import 'features/curso/presentation/bloc/curso_bloc.dart';
import 'features/curso/presentation/bloc/typing_bloc.dart';
import 'features/curso/presentation/bloc/voz_cubit.dart';
import 'features/curso/presentation/pages/escolha_linguagem_page.dart';
import 'features/curso/presentation/pages/home_page.dart';
import 'features/ingles/data/revisao_repository.dart';
import 'features/ingles/presentation/revisao_cubit.dart';
import 'features/ranking/data/ranking_repository.dart';
import 'features/ranking/presentation/ranking_cubit.dart';
import 'features/tutor/data/tutor_service.dart';
import 'features/tutor/presentation/tutor_cubit.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    runApp(const PacDartApp());
  } catch (e) {
    // Se o Firebase não iniciar, mostra um aviso em vez de tela em branco.
    runApp(_ErroInicializacao(erro: e.toString()));
  }
}

class _ErroInicializacao extends StatelessWidget {
  final String erro;
  const _ErroInicializacao({required this.erro});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Mixart.bg,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.cloud_off, size: 44, color: Mixart.textMuted),
                const SizedBox(height: 16),
                Text('Não consegui conectar', style: Mixart.display(size: 20), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Verifique sua internet e recarregue a página (Ctrl/Cmd + Shift + R).',
                    style: Mixart.ui(size: 13, color: Mixart.textMuted), textAlign: TextAlign.center),
                const SizedBox(height: 14),
                Text(erro, style: Mixart.mono(size: 10, color: Mixart.textFaint), textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class PacDartApp extends StatelessWidget {
  /// Injetáveis para testes (evitam tocar no Firebase real).
  final AuthCubit? authCubitOverride;
  final ProgressoRepository Function(AppUser user)? progressoBuilder;
  final RankingRepository Function()? rankingBuilder;
  final TutorService Function()? tutorBuilder;

  /// Pula a tela de escolha já numa vertente (testes). null = lê a escolha
  /// salva; sem escolha salva, mostra a tela "Escolha sua trilha".
  final Linguagem? linguagemInicial;

  /// Carregador do currículo por vertente (testes usam um sem I/O de asset).
  final CurriculoLoader Function(Linguagem linguagem)? curriculoBuilder;

  /// Progresso por vertente (probe/testes locais: `LocalProgressoRepository(prefixo:)`).
  /// Tem prioridade sobre [progressoBuilder].
  final ProgressoRepository Function(AppUser user, Linguagem linguagem)? progressoPorLinguagem;

  /// Revisão espaçada do inglês (testes/probe: `LocalRevisaoRepository()`).
  final RevisaoRepository Function(AppUser user)? revisaoBuilder;

  const PacDartApp({
    super.key,
    this.authCubitOverride,
    this.progressoBuilder,
    this.rankingBuilder,
    this.tutorBuilder,
    this.linguagemInicial,
    this.curriculoBuilder,
    this.progressoPorLinguagem,
    this.revisaoBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // Cada vertente guarda o progresso com o próprio prefixo no mesmo doc
    // (Dart sem prefixo, C# com "cs_", inglês com "en_").
    ProgressoRepository progressoDe(AppUser u, Linguagem l) =>
        progressoPorLinguagem?.call(u, l) ??
        progressoBuilder?.call(u) ??
        FirestoreProgressoRepository(u.uid, prefixo: l.prefixoProgresso);
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider<AuthCubit>(
          create: (_) => authCubitOverride ?? AuthCubit(AuthRepository(FirebaseAuth.instance)),
        ),
      ],
      // O gate fica ACIMA do MaterialApp: assim os blocs do curso (no ramo
      // autenticado) envolvem o MaterialApp e ficam acessíveis a todas as
      // rotas empurradas (Mapa, Quiz, diálogos).
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, estado) => switch (estado.status) {
          AuthStatus.desconhecido => const _AppShell(home: _TelaCarregando()),
          AuthStatus.naoAutenticado => const _AppShell(home: LoginPage()),
          AuthStatus.autenticado => BlocProvider(
              key: ValueKey('lg:${estado.user!.uid}'),
              create: (_) => LinguagemCubit(uid: estado.user!.uid, inicial: linguagemInicial),
              child: BlocBuilder<LinguagemCubit, LinguagemState>(
                builder: (context, lg) {
                  if (!lg.carregado) return const _AppShell(home: _TelaCarregando());
                  final linguagem = lg.escolhida;
                  if (linguagem == null) {
                    return const _AppShell(home: EscolhaLinguagemPage());
                  }
                  return _cursoDe(estado.user!, linguagem, progressoDe(estado.user!, linguagem));
                },
              ),
            ),
        },
      ),
    );
  }

  /// Os blocs do curso de uma vertente. Trocar de conta OU de linguagem
  /// recria tudo (currículo, progresso, digitação).
  Widget _cursoDe(AppUser user, Linguagem linguagem, ProgressoRepository progresso) =>
      MultiBlocProvider(
        key: ValueKey('${user.uid}:${linguagem.id}'),
        providers: [
          BlocProvider(
            create: (_) => CursoBloc(
              loader: curriculoBuilder?.call(linguagem) ?? CurriculoLoader(linguagem: linguagem),
              progresso: progresso,
            )..add(const CursoIniciado()),
          ),
          BlocProvider(create: (_) => TypingBloc()),
          BlocProvider(create: (_) => VozCubit()),
          // Prof. Dash — o modelo só é criado na primeira pergunta
          BlocProvider(
            create: (_) => TutorCubit(
              service: tutorBuilder != null ? tutorBuilder!() : GeminiTutorService(),
            ),
          ),
          // placar público (lazy: só toca o Firestore quando usado)
          BlocProvider(
            create: (_) => RankingCubit(
              repo: rankingBuilder != null
                  ? rankingBuilder!()
                  : FirestoreRankingRepository(),
              uid: user.uid,
              apelido: user.apelido,
            ),
          ),
          // inglês: as frases aprendidas voltam na revisão espaçada
          if (linguagem == Linguagem.ingles)
            BlocProvider(
              create: (_) => RevisaoCubit(
                repo: revisaoBuilder?.call(user) ?? FirestoreRevisaoRepository(user.uid),
              ),
            ),
        ],
        child: _AppShell(home: const HomePage(), linguagem: linguagem),
      );
}

class _AppShell extends StatelessWidget {
  final Widget home;
  final Linguagem? linguagem;
  const _AppShell({required this.home, this.linguagem});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeCubit, Paleta>(
        // troca de tema reconstrói o MaterialApp inteiro → tudo recolore
        builder: (context, _) => MaterialApp(
          title: linguagem == null
              ? 'PAC·DART — Treino de digitação: Dart, Flutter, C# e inglês'
              : '${linguagem!.nomeApp} — Treino de digitação ${linguagem!.nomeCurso}',
          debugShowCheckedModeBanner: false,
          theme: Mixart.tema(),
          home: home,
        ),
      );
}

class _TelaCarregando extends StatelessWidget {
  const _TelaCarregando();
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Mixart.bg,
        body: Center(child: CircularProgressIndicator(color: Mixart.brand)),
      );
}
