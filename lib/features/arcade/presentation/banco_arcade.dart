import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/linguagem/linguagem.dart';
import '../../curso/domain/curriculo.dart';
import '../../curso/presentation/bloc/curso_bloc.dart';
import '../domain/banco_curriculo.dart';
import '../domain/banco_desafios.dart';
import '../domain/desafio.dart';

/// Bancos do Arcade na vertente em uso. No Dart, o banco autoral de sempre;
/// no C#, os desafios de lógica do currículo C# carregado no [CursoBloc].
/// Sem CursoBloc (testes do arcade solto) ou sem desafios suficientes, fica
/// o banco do Dart — os jogos nunca abrem vazios.
class BancoArcade {
  static List<Trilha> _trilhasCs(BuildContext context) {
    if (Linguagem.atual != Linguagem.csharp) return const [];
    try {
      final st = BlocProvider.of<CursoBloc>(context, listen: false).state;
      return st.ehCSharp ? st.trilhas : const [];
    } catch (_) {
      return const [];
    }
  }

  static List<Desafio> desafios(BuildContext context, TipoDesafio tipo) {
    final cs = desafiosDoCurriculo(_trilhasCs(context));
    return cs.where((d) => d.tipo == tipo).length >= 6 ? cs : bancoDesafios;
  }

  static List<DesafioBug> bugs(BuildContext context) {
    final cs = bugsDoCurriculo(_trilhasCs(context));
    return cs.length >= 4 ? cs : bancoBugs;
  }

  /// "Dart", "C#" ou "English" — para os nomes dos jogos e textos do hub.
  static String get linguagem => switch (Linguagem.atual) {
        Linguagem.csharp => 'C#',
        Linguagem.ingles => 'English',
        Linguagem.dart => 'Dart',
      };

  /// No inglês o Arcade só tem os jogos de DIGITAÇÃO (os de lógica são de código).
  static bool get soDigitacao => !Linguagem.atual.ehProgramacao;
}
