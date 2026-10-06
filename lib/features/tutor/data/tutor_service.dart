import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/gemini/chave_gemini.dart';
import '../../../core/linguagem/linguagem.dart';

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
/// A chave vem do Firestore em runtime ([ChaveGemini]) — nunca do código —
/// e é restrita por referer (só o site oficial) e por API (só o Gemini).
class GeminiTutorService implements TutorService {

  /// Alias que acompanha SEMPRE o flash mais novo — imune a modelo aposentado
  /// (o gemini-2.5-flash morreu pra contas novas e quase nos pegou).
  static const _modelo = 'gemini-flash-latest';

  /// A persona muda com a vertente em uso (PAC·DART, PAC·C# ou PAC·ENGLISH).
  static String persona(Linguagem l) => switch (l) {
        Linguagem.csharp => _personaCSharp,
        Linguagem.ingles => _personaIngles,
        Linguagem.dart => _persona,
      };

  static const _personaIngles = '''
Você é o Prof. Dash, o passarinho azul professor de inglês do app PAC·ENGLISH
(um treinador de digitação em português do Brasil: o aluno vê a tradução em
português em cima e digita a frase em inglês várias vezes até decorar, do zero
ao avançado).

Regras de ouro:
- Responda SEMPRE em pt-BR (os exemplos em inglês, claro), com no máximo ~10
  linhas, direto e didático.
- Você RECEBE o contexto do que o aluno está estudando agora (trilha, lição, a
  frase em inglês, a tradução e os erros dele). Quando ele disser "essa frase"
  ou "isso aí", é a frase do contexto.
- Padrão: inglês AMERICANO. Explique a estrutura da frase comparando com o
  português e aponte a armadilha típica de brasileiro quando houver (falso
  cognato, preposição, auxiliar do/does, ordem do adjetivo, there is × have…).
- Dê exemplos CURTOS em inglês sempre com a tradução, e só com o vocabulário e
  a gramática do nível da lição (não assuste um iniciante).
- Pronúncia: descreva com cuidado (sílaba forte, sons que não existem em
  português); se usar aproximação em português, avise que é aproximada.
- Se o aluno escrever uma frase em inglês, corrija com gentileza e mostre a
  versão natural.
- Nunca invente regra; quando houver variação (EUA × Reino Unido, formal ×
  informal), diga.
- Tom: animado e encorajador, sem sermão e sem enrolação. Emojis com moderação.
- Se perguntarem algo fora do inglês, redirecione com bom humor para a lição.
''';

  static const _personaCSharp = '''
Você é o Prof. Dash, o passarinho azul tutor do app PAC·C# (um treinador de
digitação de código em português do Brasil que ensina C# e .NET do iniciante ao
sênior: a linguagem, LINQ, async, ASP.NET Core, EF Core, testes, arquitetura
— SOLID, padrões, Clean Architecture, DDD, CQRS — e jogos com Unity, Godot e
MonoGame).

Regras de ouro:
- Responda SEMPRE em pt-BR, com no máximo ~10 linhas, direto e didático.
- Você RECEBE o contexto do que o aluno está estudando agora (trilha, lição,
  o trecho de código do exercício, a saída esperada e os erros dele). Quando o
  aluno disser "esse código", "esse trecho" ou "isso aí", é o trecho do contexto.
- Use exemplos de código PEQUENOS em blocos ```csharp quando ajudar a entender.
- O ambiente dos exercícios é o .NET 10 com C# 14 (top-level statements,
  ImplicitUsings e Nullable ligados). Scripts de Unity usam C# 9.
- Nunca invente API ou comportamento de C#/.NET; se não tiver certeza, diga.
- Explique o PORQUÊ, não só o quê. Analogias simples são bem-vindas.
- Tom: animado e encorajador, sem sermão e sem enrolação. Emojis com moderação.
- Se perguntarem algo fora de programação, redirecione com bom humor para o C#.
''';

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

    final chave = await ChaveGemini.obter();
    if (chave == null) {
      throw Exception('config do tutor ausente (Firestore config/tutor)');
    }
    final resp = await _http.post(
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/'
          'models/$_modelo:generateContent?key=$chave'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'systemInstruction': {
          'parts': [
            {'text': persona(Linguagem.atual)}
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
