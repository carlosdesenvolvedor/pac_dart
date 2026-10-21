import 'package:flutter/foundation.dart';

import 'sessao_midia_stub.dart' if (dart.library.js_interop) 'sessao_midia_web.dart' as impl;

/// A "sessão de mídia" do sistema: título na tela de bloqueio e as teclas de mídia (▶ ⏸ ⏭ ⏮) do
/// "🎧 Ouvir". No navegador é a Media Session API (melhor esforço); fora dele, nada.
abstract class SessaoMidia {
  factory SessaoMidia.criar() => impl.criarSessaoMidia();

  void atualizar({required String titulo, required String artista, required String album, required bool tocando});

  void acoes({
    required VoidCallback play,
    required VoidCallback pause,
    required VoidCallback proxima,
    required VoidCallback anterior,
    required VoidCallback parar,
  });

  void limpar();

  /// A página está escondida (aba em segundo plano / tela apagada)?
  bool get oculta;
}

/// A sessão que também sabe "voltar um pouco" (`seekbackward` da Media Session): o player liga em
/// "repetir a frase atual". Separada de [SessaoMidia] para os fakes dos testes não precisarem dela.
abstract class SessaoMidiaComRepetir {
  void aoRepetir(VoidCallback repetir);
}
