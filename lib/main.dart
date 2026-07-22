import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
import 'features/curso/presentation/pages/home_page.dart';
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

  const PacDartApp({super.key, this.authCubitOverride, this.progressoBuilder});

  @override
  Widget build(BuildContext context) {
    final builder = progressoBuilder ?? (u) => FirestoreProgressoRepository(u.uid);
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
          AuthStatus.autenticado => MultiBlocProvider(
              key: ValueKey(estado.user!.uid), // trocar de conta recria os blocs
              providers: [
                BlocProvider(
                  create: (_) => CursoBloc(
                    loader: CurriculoLoader(),
                    progresso: builder(estado.user!),
                  )..add(const CursoIniciado()),
                ),
                BlocProvider(create: (_) => TypingBloc()),
                BlocProvider(create: (_) => VozCubit()),
              ],
              child: const _AppShell(home: HomePage()),
            ),
        },
      ),
    );
  }
}

class _AppShell extends StatelessWidget {
  final Widget home;
  const _AppShell({required this.home});

  @override
  Widget build(BuildContext context) => BlocBuilder<ThemeCubit, Paleta>(
        // troca de tema reconstrói o MaterialApp inteiro → tudo recolore
        builder: (context, _) => MaterialApp(
          title: 'PAC·DART — Treino de digitação Dart & Flutter',
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
