// Os tutores falsos compartilhados pelos testes da IA (cenários / Conversa com IA).
// O TutorCenarioFalso e o TutorComPersonaFalso vieram de ia_cenario_cubit_test.dart com a MESMA API
// (5 testes de fora da IA ainda os importam por lá, via export).
import 'dart:async';
import 'dart:convert';

import 'package:pac_dart/features/tutor/data/tutor_service.dart';

/// O Prof. Dash dos cenários: responde um turno (em inglês) ou o feedback (JSON), conforme o contexto.
class TutorCenarioFalso implements TutorService {
  int chamadas = 0;
  final contextos = <String>[];
  final historicos = <String>[];
  final perguntas = <String>[];
  Object? erro;
  Completer<void>? segura;
  String turno = 'Sure! What size?';
  String feedback = '{}';

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) async* {
    chamadas++;
    contextos.add(contexto);
    historicos.add(historico);
    perguntas.add(pergunta);
    await segura?.future;
    if (erro != null) throw erro!;
    yield contexto.contains('MODO FEEDBACK DE CENÁRIO') ? feedback : turno;
  }
}

/// O mesmo, mas aceitando persona própria (como o Gemini de verdade).
class TutorComPersonaFalso extends TutorCenarioFalso implements TutorComPersona {
  final personas = <String>[];
  int viaPerguntar = 0;

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) {
    viaPerguntar++;
    return super.perguntar(contexto: contexto, historico: historico, pergunta: pergunta);
  }

  @override
  Stream<String> perguntarComo({required String persona, required String contexto, required String historico, required String pergunta}) {
    personas.add(persona);
    return super.perguntar(contexto: contexto, historico: historico, pergunta: pergunta);
  }
}

/// O tutor da Conversa com IA: [TutorService] + [TutorComPersona] + [TutorJson], como o Gemini da web.
///
/// Guarda tudo o que recebeu (por qualquer caminho) e responde pela fila [respostas]: um String sai
/// como texto da resposta; QUALQUER outro objeto é lançado (ex.: `FalhaIa(TipoFalhaIa.limite)`). Fila
/// vazia → [respostaJson]. Com [erro] ligado, toda chamada lança [erro] (antes da fila). [segura]
/// prende a resposta até ser completado.
class TutorConversaFalso implements TutorService, TutorComPersona, TutorJson {
  /// Chamadas por qualquer caminho, e por qual caminho.
  int chamadas = 0;
  int viaJson = 0, viaComo = 0, viaPerguntar = 0;

  /// A persona de cada chamada ('' no caminho `perguntar`, que leva a persona dentro do contexto).
  final personas = <String>[];
  final contextos = <String>[];
  final historicos = <String>[];
  final perguntas = <String>[];

  /// Só do caminho `perguntarJson`.
  final esquemas = <Map<String, Object?>>[];
  final maxTokens = <int>[];

  /// A fila de respostas (String = texto; outro objeto = lançado).
  final respostas = <Object>[];

  Object? erro;
  Completer<void>? segura;

  Future<String> _responder({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) async {
    chamadas++;
    personas.add(persona);
    contextos.add(contexto);
    historicos.add(historico);
    perguntas.add(pergunta);
    await segura?.future;
    if (erro != null) throw erro!;
    if (respostas.isEmpty) return respostaJson();
    final r = respostas.removeAt(0);
    if (r is String) return r;
    throw r;
  }

  @override
  Future<String> perguntarJson({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
    required Map<String, Object?> esquema,
    int maxTokens = 600,
  }) {
    viaJson++;
    esquemas.add(esquema);
    this.maxTokens.add(maxTokens);
    return _responder(persona: persona, contexto: contexto, historico: historico, pergunta: pergunta);
  }

  @override
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    viaComo++;
    final t = await _responder(persona: persona, contexto: contexto, historico: historico, pergunta: pergunta);
    if (t.isNotEmpty) yield t;
  }

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) async* {
    viaPerguntar++;
    final t = await _responder(persona: '', contexto: contexto, historico: historico, pergunta: pergunta);
    if (t.isNotEmpty) yield t;
  }
}

/// Uma resposta de turno válida (o modelo do plano). Com [precisa], a correção do "I want a coffee";
/// sem, "✅ Certinho!". `size` passa na regra das palavras novas.
String respostaJson({bool precisa = true, bool fim = false, String fala = 'Sure! What size would you like?'}) =>
    jsonEncode({
      'correcao': precisa
          ? {
              'precisa': true,
              'melhor': 'Can I have a coffee, please?',
              'pt': 'Posso pedir um café, por favor?',
              'porque': '*I want* soa **seco** num pedido; *Can I have* é o jeito educado.',
              'dica': 'Em pedidos, prefira Can I have / I\'d like.',
            }
          : {'precisa': false},
      'fala': fala,
      'traducao': 'Claro! Qual tamanho você quer?',
      'sugestoes': ['Small, please.', 'A large one, please.'],
      'palavras': [
        {'en': 'size', 'pt': 'tamanho'}
      ],
      'fim': fim,
    });
