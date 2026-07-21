import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/mixart.dart';
import 'features/curso/data/curriculo_loader.dart';
import 'features/curso/data/progresso_repository.dart';
import 'features/curso/presentation/bloc/curso_bloc.dart';
import 'features/curso/presentation/bloc/typing_bloc.dart';
import 'features/curso/presentation/bloc/voz_cubit.dart';
import 'features/curso/presentation/pages/home_page.dart';

void main() {
  runApp(const PacDartApp());
}

class PacDartApp extends StatelessWidget {
  const PacDartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CursoBloc(
            loader: CurriculoLoader(),
            progresso: ProgressoRepository(),
          )..add(const CursoIniciado()),
        ),
        BlocProvider(create: (_) => TypingBloc()),
        BlocProvider(create: (_) => VozCubit()),
      ],
      child: MaterialApp(
        title: 'PAC·DART — Treino de digitação Dart & Flutter',
        debugShowCheckedModeBanner: false,
        theme: Mixart.tema(),
        home: const HomePage(),
      ),
    );
  }
}
