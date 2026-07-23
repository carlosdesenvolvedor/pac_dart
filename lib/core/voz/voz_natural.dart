import 'dart:convert';

import 'package:http/http.dart' as http;

import 'voz_natural_stub.dart' if (dart.library.js_interop) 'voz_natural_web.dart'
    as player;

/// 🎙️ Narração NATURAL via Gemini TTS — a mesma API e a MESMA chave
/// (trancada por domínio) do Prof. Dash. Se qualquer coisa falhar (cota,
/// rede, plataforma sem Web Audio), quem chamou usa o fallback do sistema.
class VozNatural {
  static const _chave = 'AIzaSyCnYsKY9LV1wvuquuKX9zm6L_qFAIhWBpI';
  static const _modelo = 'gemini-2.5-flash-preview-tts';

  /// Voz pré-construída do Gemini (Zephyr = clara e animada).
  static const _voz = 'Zephyr';

  /// Instrução de estilo — o modelo NÃO lê esta parte, só obedece.
  static const _estilo = 'Leia em português do Brasil, com tom simpático e '
      'natural de professor, num ritmo tranquilo: ';

  final http.Client _http;
  VozNatural({http.Client? client}) : _http = client ?? http.Client();

  /// A mesma dica repetida não paga nova chamada (nem espera).
  final _cache = <String, List<int>>{};

  /// Falas atropelam as anteriores: só a geração mais nova pode tocar.
  int _geracao = 0;

  /// Fala [texto] com a voz neural. Devolve false quando NÃO deu (sem
  /// suporte, sem rede, sem cota) — aí o chamador usa a voz do sistema.
  Future<bool> falar(String texto) async {
    if (!player.suportado || texto.trim().isEmpty) return false;
    final g = ++_geracao;
    try {
      var pcm = _cache[texto];
      if (pcm == null) {
        pcm = await _sintetizar(texto);
        if (pcm == null) return false;
        if (_cache.length > 120) _cache.remove(_cache.keys.first);
        _cache[texto] = pcm;
      }
      // chegou tarde? outra fala já assumiu o microfone — não atropela
      if (g == _geracao) player.tocaPcm16(pcm, 24000);
      return true;
    } catch (_) {
      return false;
    }
  }

  void parar() {
    _geracao++;
    player.paraTudo();
  }

  Future<List<int>?> _sintetizar(String texto) async {
    final resp = await _http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/'
          'models/$_modelo:generateContent?key=$_chave'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': '$_estilo$texto'}
            ]
          }
        ],
        'generationConfig': {
          'responseModalities': ['AUDIO'],
          'speechConfig': {
            'voiceConfig': {
              'prebuiltVoiceConfig': {'voiceName': _voz}
            }
          },
        },
      }),
    );
    if (resp.statusCode != 200) return null;
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final parte = ((((json['candidates'] as List?)?.firstOrNull as Map?)?['content']
        as Map?)?['parts'] as List?)
        ?.firstOrNull as Map?;
    final inline = parte?['inlineData'] as Map?;
    final mime = inline?['mimeType'] as String? ?? '';
    final dados = inline?['data'] as String?;
    // esperamos PCM16 24kHz; outro formato = melhor não arriscar o ouvido
    if (dados == null || !mime.startsWith('audio/L16')) return null;
    return base64.decode(dados);
  }
}
