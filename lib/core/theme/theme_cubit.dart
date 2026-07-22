import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mixart.dart';

/// Guarda a paleta ativa, aplica em [Mixart.atual] e persiste a escolha.
class ThemeCubit extends Cubit<Paleta> {
  static const _chave = 'paleta';

  ThemeCubit() : super(Mixart.atual) {
    _carregar();
  }

  Future<void> _carregar() async {
    final p = await SharedPreferences.getInstance();
    final nome = p.getString(_chave);
    final pal = Paleta.todas.firstWhere((x) => x.nome == nome, orElse: () => Paleta.mixart);
    Mixart.atual = pal;
    emit(pal);
  }

  Future<void> trocar(Paleta pal) async {
    Mixart.atual = pal;
    emit(pal);
    final p = await SharedPreferences.getInstance();
    await p.setString(_chave, pal.nome);
  }
}
