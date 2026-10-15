import 'package:firebase_ai/firebase_ai.dart';

import '../../../core/linguagem/linguagem.dart';
import 'tutor_service.dart';

/// O Prof. Dash no app (Android e iOS): fala com o Gemini pelo Firebase AI Logic.
/// Nenhuma chave de API vai dentro do app — a do Gemini fica no servidor do Firebase
/// (projeto `pac-dart`, provedor "Gemini Developer API"); o app só se identifica pelo
/// projeto, e a cota é a gratuita do projeto (sem cobrança ligada).
///
/// A versão web continua no [GeminiTutorService], que usa a chave restrita ao site.
class FirebaseAiTutorService implements TutorService, TutorComPersona {
  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) =>
      perguntarComo(
          persona: GeminiTutorService.persona(Linguagem.atual), contexto: contexto, historico: historico, pergunta: pergunta);

  @override
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    final modelo = FirebaseAI.googleAI().generativeModel(
      model: GeminiTutorService.modelo,
      systemInstruction: Content.system(persona),
      generationConfig: GenerationConfig(temperature: 0.4, maxOutputTokens: 2048),
    );
    final prompt = GeminiTutorService.montarPrompt(contexto: contexto, historico: historico, pergunta: pergunta);
    final resposta = await modelo.generateContent([Content.text(prompt)]);
    final texto = resposta.text;
    if (texto != null && texto.isNotEmpty) yield texto;
  }
}
