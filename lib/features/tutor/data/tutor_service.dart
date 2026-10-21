import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../../../core/gemini/chave_gemini.dart';
import '../../../core/linguagem/linguagem.dart';
import 'falha_ia.dart';

/// Contrato do tutor — o Gemini de verdade em produção, um fake nos testes.
abstract interface class TutorService {
  /// Responde em streaming (pedaços de texto conforme chegam).
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  });
}

/// Serviço que também aceita uma PERSONA própria (os cenários guiados: o Dash vira o atendente
/// da cafeteria). Opcional e à parte do [TutorService], para os serviços falsos dos testes
/// continuarem valendo; quem não o implementa recebe a persona como instrução no contexto.
abstract interface class TutorComPersona {
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  });
}

/// Opcional (como o [TutorComPersona]): a resposta em JSON que segue [esquema] (o subconjunto
/// OpenAPI da API do Gemini: type OBJECT/ARRAY/STRING/BOOLEAN, properties, required, items,
/// propertyOrdering). Lança [FalhaIa]. Sem streaming.
abstract interface class TutorJson {
  Future<String> perguntarJson({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
    required Map<String, Object?> esquema,
    int maxTokens = 600,
  });
}

/// Prof. Dash falando direto com a API do Gemini.
///
/// A chave vem do Firestore em runtime ([ChaveGemini]) — nunca do código —
/// e é restrita por referer (só o site oficial) e por API (só o Gemini).
class GeminiTutorService implements TutorService, TutorComPersona, TutorJson {

  /// Alias que acompanha SEMPRE o flash mais novo — imune a modelo aposentado
  /// (o gemini-2.5-flash morreu pra contas novas e quase nos pegou).
  static const _modelo = 'gemini-flash-latest';

  /// O modelo do tutor (o mesmo no site e no app).
  static String get modelo => _modelo;

  /// O que o modelo recebe: o contexto da lição aberta, a conversa recente e a pergunta.
  static String montarPrompt({required String contexto, required String historico, required String pergunta}) =>
      'CONTEXTO DO ALUNO AGORA:\n$contexto\n\n'
      '${historico.isEmpty ? '' : 'CONVERSA RECENTE:\n$historico\n\n'}'
      'PERGUNTA DO ALUNO: $pergunta';

  /// A persona muda com a vertente em uso (Dart, C# ou Inglês).
  static String persona(Linguagem l) => switch (l) {
        Linguagem.csharp => _personaCSharp,
        Linguagem.ingles => _personaIngles,
        Linguagem.dart => _persona,
      };

  static const _personaIngles = '''
Você é o Prof. Dash, o passarinho azul professor de inglês do app Paclingo
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
Você é o Prof. Dash, o passarinho azul tutor do app Paclingo (um treinador de
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
Você é o Prof. Dash, o passarinho azul tutor de Dart e Flutter do app Paclingo
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

  /// Só o [perguntarJson] (turno curto da conversa, sem thinking).
  final Duration timeoutJson;

  /// O [perguntarComo]/[perguntar] (chat do Prof. Dash, "Por quê?", Escrita: 2048 tokens com
  /// thinking ligado; respostas longas com código).
  final Duration timeoutLongo;

  GeminiTutorService({
    http.Client? client,
    this.timeoutJson = const Duration(seconds: 25),
    this.timeoutLongo = const Duration(seconds: 90),
  }) : _http = client ?? http.Client();

  // Compatibilidade aprendida na sessão (a 1ª recusa do modelo vale para as próximas chamadas).
  static bool _semThinking = false;
  static bool _semEsquema = false;
  static double _fatorTokens = 1;

  static final _modeloValido = RegExp(r'^[a-z0-9.\-]+$');

  /// O modelo da conversa: `config/tutor.modeloConversa` se casar com `^[a-z0-9.\-]+$`; senão o [modelo].
  /// Trocar o modelo (ex.: `gemini-flash-lite-latest` se o limite grátis do flash apertar) não pede deploy.
  static Future<String> modeloConversa() async {
    final m = (await ChaveGemini.campo('modeloConversa'))?.trim();
    return m != null && _modeloValido.hasMatch(m) ? m : _modelo;
  }

  /// Zera o que a sessão aprendeu (`_semThinking`, `_semEsquema`, `_fatorTokens`).
  @visibleForTesting
  static void resetarCompatibilidade() {
    _semThinking = false;
    _semEsquema = false;
    _fatorTokens = 1;
  }

  static const _semChave = 'config do tutor ausente (Firestore config/tutor)';

  /// A chave do Gemini. Doc lido sem a chave → [TipoFalhaIa.credencial]; a LEITURA do doc que falhou
  /// (offline, 'unavailable') → [TipoFalhaIa.semRede], que não abre janela de descanso.
  static Future<String> _chave() async {
    final String? chave;
    try {
      chave = await ChaveGemini.obterOuLancar();
    } catch (e) {
      throw FalhaIa(TipoFalhaIa.semRede, detalhe: 'leitura do config/tutor falhou: ${e.runtimeType}');
    }
    if (chave == null) throw const FalhaIa(TipoFalhaIa.credencial, detalhe: _semChave);
    return chave;
  }

  /// Motivos de parada que querem dizer "o filtro de segurança barrou" (sem texto).
  static const _bloqueios = {'SAFETY', 'PROHIBITED_CONTENT', 'BLOCKLIST', 'SPII'};

  Uri _url(String modelo, String chave) =>
      Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelo:generateContent?key=$chave');

  /// Um POST com [limite] de tempo; erro de rede ou tempo esgotado → [FalhaIa] (semRede).
  Future<http.Response> _post(Uri url, Map<String, Object?> corpo, Duration limite) async {
    try {
      return await _http
          .post(url, headers: const {'Content-Type': 'application/json'}, body: jsonEncode(corpo))
          .timeout(limite);
    } catch (e) {
      throw FalhaIa.de(e);
    }
  }

  /// O texto da 1ª candidata (as partes juntas; pode ser '').
  static String _textoDe(Map<String, dynamic> json) {
    final candidatos = json['candidates'] as List?;
    final partes = ((candidatos?.firstOrNull as Map?)?['content'] as Map?)?['parts'] as List?;
    return [
      for (final p in partes ?? const [])
        if (p is Map && p['text'] is String) p['text'] as String,
    ].join();
  }

  /// Um turno curto em JSON (a Conversa com IA): `responseMimeType`, `responseSchema` e
  /// `thinkingConfig` DENTRO do `generationConfig`. No máximo 2 requisições por chamada — a 2ª só
  /// por compatibilidade (o modelo recusou thinking/schema, ou parou no MAX_TOKENS sem texto).
  /// Nada de nova tentativa em 5xx nem em 429: quem descansa é o [IaCubit].
  @override
  Future<String> perguntarJson({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
    required Map<String, Object?> esquema,
    int maxTokens = 600,
  }) async {
    final chave = await _chave();
    final url = _url(await modeloConversa(), chave);
    final prompt = montarPrompt(contexto: contexto, historico: historico, pergunta: pergunta);
    var retentou = false;
    while (true) {
      final resp = await _post(
        url,
        {
          'systemInstruction': {
            'parts': [
              {'text': persona}
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
          'generationConfig': {
            'temperature': 0.5,
            'maxOutputTokens': (maxTokens * _fatorTokens).round(),
            'responseMimeType': 'application/json',
            if (!_semEsquema) 'responseSchema': esquema,
            if (!_semThinking) 'thinkingConfig': {'thinkingBudget': 0},
          },
        },
        timeoutJson,
      );
      final corpo = utf8.decode(resp.bodyBytes);

      if (resp.statusCode == 400 && !retentou) {
        // o modelo não aceita thinking e/ou schema: tira o que ele recusou (todos de uma vez) e tenta 1 vez
        final baixo = corpo.toLowerCase();
        final tirarThinking = !_semThinking && baixo.contains('thinking');
        final tirarEsquema = !_semEsquema && baixo.contains('schema');
        if (tirarThinking || tirarEsquema) {
          if (tirarThinking) _semThinking = true;
          if (tirarEsquema) _semEsquema = true;
          retentou = true;
          continue;
        }
      }
      if (resp.statusCode != 200) {
        throw FalhaIa(FalhaIa.tipoDoStatus(resp.statusCode, corpo), status: resp.statusCode, detalhe: corpo);
      }

      final Map<String, dynamic> json;
      try {
        json = jsonDecode(corpo) as Map<String, dynamic>;
      } catch (_) {
        throw FalhaIa(TipoFalhaIa.outro, status: 200, detalhe: 'resposta ilegível: $corpo');
      }
      final bloqueio = (json['promptFeedback'] as Map?)?['blockReason'];
      if (bloqueio != null) throw FalhaIa(TipoFalhaIa.recusada, detalhe: 'blocked: $bloqueio');
      final texto = _textoDe(json);
      final motivo = ((json['candidates'] as List?)?.firstOrNull as Map?)?['finishReason'];
      if (texto.isEmpty && _bloqueios.contains(motivo)) {
        throw FalhaIa(TipoFalhaIa.recusada, detalhe: 'blocked: $motivo');
      }
      if (texto.isEmpty && motivo == 'MAX_TOKENS' && !retentou && _fatorTokens < 2.5) {
        // a resposta não coube: mais espaço (vale para o resto da sessão) e 1 nova tentativa
        _fatorTokens = 2.5;
        retentou = true;
        continue;
      }
      return texto;
    }
  }

  @override
  Stream<String> perguntar({
    required String contexto,
    required String historico,
    required String pergunta,
  }) =>
      perguntarComo(persona: persona(Linguagem.atual), contexto: contexto, historico: historico, pergunta: pergunta);

  @override
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    final prompt = montarPrompt(contexto: contexto, historico: historico, pergunta: pergunta);

    final chave = await _chave();
    final resp = await _post(
      _url(_modelo, chave),
      {
        'systemInstruction': {
          'parts': [
            {'text': persona}
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
      },
      timeoutLongo,
    );

    final corpo = utf8.decode(resp.bodyBytes);
    if (resp.statusCode != 200) {
      // o texto continua "Gemini <status>: <corpo>" (o TutorCubit procura '429'/'403' nele)
      throw FalhaIa(FalhaIa.tipoDoStatus(resp.statusCode, corpo), status: resp.statusCode, detalhe: corpo);
    }
    // corpo ilegível (página de proxy, corpo cortado): falha local, tipada — nunca casada por padrão
    // de texto no FalhaIa.de (um "429"/"quota" no trecho abriria descanso à toa)
    final Map<String, dynamic> json;
    try {
      json = jsonDecode(corpo) as Map<String, dynamic>;
    } catch (_) {
      throw const FalhaIa(TipoFalhaIa.outro, status: 200, detalhe: 'resposta ilegível');
    }
    final texto = _textoDe(json);
    if (texto.isNotEmpty) yield texto;
  }
}
