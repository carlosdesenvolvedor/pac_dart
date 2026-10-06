import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'linguagem.dart';

class LinguagemState extends Equatable {
  /// Já leu a escolha salva? (antes disso a tela fica carregando)
  final bool carregado;

  /// null = ainda não escolheu → mostra a tela de escolha.
  final Linguagem? escolhida;

  const LinguagemState({this.carregado = false, this.escolhida});

  @override
  List<Object?> get props => [carregado, escolhida];
}

/// Guarda a vertente escolhida (Dart ou C#) POR CONTA neste dispositivo:
/// num navegador compartilhado, a escolha de uma pessoa não vaza para a
/// outra (cada uma cai no próprio progresso). Trocar de linguagem recria os
/// blocs do curso com o currículo e o progresso da outra vertente.
class LinguagemCubit extends Cubit<LinguagemState> {
  /// Chave da escolha de cada conta nas preferências.
  static String chaveDe(String uid) => 'linguagem_$uid';

  final String uid;

  LinguagemCubit({required this.uid, Linguagem? inicial})
      : super(inicial == null ? const LinguagemState() : LinguagemState(carregado: true, escolhida: inicial)) {
    if (inicial != null) {
      Linguagem.atual = inicial;
    } else {
      _carregar();
    }
  }

  /// A linguagem do app em volta — Dart fora do app (widgets soltos nos testes).
  static Linguagem de(BuildContext context) {
    try {
      return BlocProvider.of<LinguagemCubit>(context, listen: false).state.escolhida ?? Linguagem.dart;
    } catch (_) {
      return Linguagem.dart;
    }
  }

  /// Há um LinguagemCubit acima de [context]? (o HUD só oferece a troca aí)
  static bool existe(BuildContext context) {
    try {
      BlocProvider.of<LinguagemCubit>(context, listen: false);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _carregar() async {
    Linguagem? salva;
    try {
      final p = await SharedPreferences.getInstance();
      salva = Linguagem.porId(p.getString(chaveDe(uid)));
    } catch (_) {}
    if (isClosed) return;
    if (salva != null) Linguagem.atual = salva;
    emit(LinguagemState(carregado: true, escolhida: salva));
  }

  /// Escolhe [l]. Escolher a MESMA linguagem não faz nada (não derruba a
  /// sessão: a lição, o placar e a conversa com o tutor continuam).
  Future<void> escolher(Linguagem l) async {
    if (state.escolhida == l) return;
    Linguagem.atual = l;
    emit(LinguagemState(carregado: true, escolhida: l));
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chaveDe(uid), l.id);
    } catch (_) {}
  }
}
