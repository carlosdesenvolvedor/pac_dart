import 'package:flutter/foundation.dart';

import 'sessao_midia.dart';

/// Fora do navegador (VM dos testes, nativo): sem sessão de mídia, nunca lança.
SessaoMidia criarSessaoMidia() => SessaoMidiaMuda();

class SessaoMidiaMuda implements SessaoMidia {
  @override
  void atualizar({required String titulo, required String artista, required String album, required bool tocando}) {}

  @override
  void acoes({
    required VoidCallback play,
    required VoidCallback pause,
    required VoidCallback proxima,
    required VoidCallback anterior,
    required VoidCallback parar,
  }) {}

  @override
  void limpar() {}

  @override
  bool get oculta => false;
}
