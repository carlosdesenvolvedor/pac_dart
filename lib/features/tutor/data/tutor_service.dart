import 'package:firebase_ai/firebase_ai.dart';

/// Contrato do tutor — o Gemini de verdade em produção, um fake nos testes.
abstract interface class TutorService {
  /// Responde em streaming (pedaços de texto conforme chegam).
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  });
}

/// Prof. Dash falando via **Firebase AI Logic** (Gemini): a chave fica no
/// Firebase, nada exposto no cliente — e sem precisar de backend próprio.
class GeminiTutorService implements TutorService {
  GenerativeModel? _model;

  /// Criado só na primeira pergunta (testes e boot nunca tocam o Firebase).
  GenerativeModel get _m => _model ??= FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
        generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 900),
        systemInstruction: Content.system(_persona),
      );

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

  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    final prompt = 'CONTEXTO DO ALUNO AGORA:\n$contexto\n\n'
        '${historico.isEmpty ? '' : 'CONVERSA RECENTE:\n$historico\n\n'}'
        'PERGUNTA DO ALUNO: $pergunta';
    final resposta = _m.generateContentStream([Content.text(prompt)]);
    await for (final pedaco in resposta) {
      final t = pedaco.text;
      if (t != null && t.isNotEmpty) yield t;
    }
  }
}
