import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'sessao_midia.dart';

/// No navegador: Media Session API (`navigator.mediaSession`), arte `icons/Icon-512.png`;
/// `seekbackward` = repetir a frase atual. Melhor esforço: navegador sem a API (ou que recusa uma ação)
/// só fica sem os controles — nunca lança.
SessaoMidia criarSessaoMidia() => SessaoMidiaWeb();

class SessaoMidiaWeb implements SessaoMidia, SessaoMidiaComRepetir {
  static const arte = 'icons/Icon-512.png';

  /// As ações que o player liga (`play`, `pause`, `nexttrack`, `previoustrack`, `stop`, `seekbackward`).
  static const _acoes = ['play', 'pause', 'nexttrack', 'previoustrack', 'stop', 'seekbackward'];

  String? _ultimoTitulo, _ultimoArtista, _ultimoAlbum;

  web.MediaSession? get _sessao {
    try {
      return web.window.navigator.mediaSession;
    } catch (_) {
      return null;
    }
  }

  @override
  void atualizar({required String titulo, required String artista, required String album, required bool tocando}) {
    final s = _sessao;
    if (s == null) return;
    try {
      // a mesma faixa: só o estado muda (trocar o metadata à toa pisca a notificação)
      if (titulo != _ultimoTitulo || artista != _ultimoArtista || album != _ultimoAlbum) {
        _ultimoTitulo = titulo;
        _ultimoArtista = artista;
        _ultimoAlbum = album;
        s.metadata = web.MediaMetadata(web.MediaMetadataInit(
          title: titulo,
          artist: artista,
          album: album,
          artwork: [web.MediaImage(src: arte, sizes: '512x512', type: 'image/png')].toJS,
        ));
      }
      s.playbackState = tocando ? 'playing' : 'paused';
    } catch (_) {}
  }

  @override
  void acoes({
    required VoidCallback play,
    required VoidCallback pause,
    required VoidCallback proxima,
    required VoidCallback anterior,
    required VoidCallback parar,
  }) {
    _liga('play', play);
    _liga('pause', pause);
    _liga('nexttrack', proxima);
    _liga('previoustrack', anterior);
    _liga('stop', parar);
  }

  @override
  void aoRepetir(VoidCallback repetir) => _liga('seekbackward', repetir);

  void _liga(String acao, VoidCallback? f) {
    final s = _sessao;
    if (s == null) return;
    try {
      s.setActionHandler(acao, f == null ? null : ((JSAny? _) => f()).toJS);
    } catch (_) {
      // ação que este navegador não conhece: segue sem ela
    }
  }

  @override
  void limpar() {
    final s = _sessao;
    if (s == null) return;
    _ultimoTitulo = _ultimoArtista = _ultimoAlbum = null;
    for (final a in _acoes) {
      _liga(a, null);
    }
    try {
      s.metadata = null;
      s.playbackState = 'none';
    } catch (_) {}
  }

  @override
  bool get oculta {
    try {
      return web.document.visibilityState == 'hidden';
    } catch (_) {
      return false;
    }
  }
}
