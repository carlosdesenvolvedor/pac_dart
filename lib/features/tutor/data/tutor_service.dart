import 'dart:convert';

import 'package:http/http.dart' as http;

/// Contrato do tutor — o Gemini de verdade em produção, um fake nos testes.
abstract interface class TutorService {
  /// Responde em streaming (pedaços de texto conforme chegam).
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  });
}

/// Prof. Dash falando direto com a API do Gemini.
///
/// A [_chave] é RESTRITA de dois jeitos (criada via gcloud):
///  1. por referer — só aceita chamadas vindas de https://pac-dart.web.app
///     e de localhost (dev); de qualquer outro lugar, 403;
///  2. por API — só serve para a generativelanguage.googleapis.com.
/// Ou seja: é pública por design, como a própria chave web do Firebase.
class GeminiTutorService implements TutorService {
  static const _chave = 'AIzaSyCnYsKY9LV1wvuquuKX9zm6L_qFAIhWBpI';

  /// Alias que acompanha SEMPRE o flash mais novo — imune a modelo aposentado
  /// (o gemini-2.5-flash morreu pra contas novas e quase nos pegou).
  static const _modelo = 'gemini-flash-latest';

  static const _persona = '''
Você é o Prof. Dash, o passarinho azul tutor de Dart e Flutter do app PAC·DART
(um treinador de digitação de código em português do Brasil).

Regras de ouro:
- Responda SEMPRE em pt-BR, com no máximo ~10 linhas, direto e didático.
- Você RECEBE o contexto do que o aluno está estudando agora (trilha, lição,
  o trecho de código do exercício, a saída esperada e os erros dele). Quando o
  aluno disser "esse código", "esse trecho" ou "isso aí", é o trecho do contexto.
- Use exemplos de código PEQUENOS em blocos ```dart quando ajudar a entender.
- Nunca invente API ou comportamento de Dart/Flutter; se não tiver certeza, diga.
- Explique o PORQUÊ, não só o quê. Analogias simples são bem-vindas.
- Tom: animado e encorajador, sem sermão e sem enrolação. Emojis com moderação.
- Se perguntarem algo fora de programação, redirecione com bom humor para o Dart.
''';

  final http.Client _http;
  GeminiTutorService({http.Client? client}) : _http = client ?? http.Client();

  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    final prompt = 'CONTEXTO DO ALUNO AGORA:\n$contexto\n\n'
        '${historico.isEmpty ? '' : 'CONVERSA RECENTE:\n$historico\n\n'}'
        'PERGUNTA DO ALUNO: $pergunta';

    final resp = await _http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/'
          'models/$_modelo:generateContent?key=$_chave'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': _persona}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 2048},
      }),
    );

    if (resp.statusCode != 200) {
      throw Exception('Gemini ${resp.statusCode}: ${utf8.decode(resp.bodyBytes)}');
    }
    final json = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final candidatos = json['candidates'] as List?;
    final partes =
        ((candidatos?.firstOrNull as Map?)?['content'] as Map?)?['parts'] as List?;
    final texto = [
      for (final p in partes ?? const [])
        if ((p as Map)['text'] != null) p['text'] as String,
    ].join();
    if (texto.isNotEmpty) yield texto;
  }
}
