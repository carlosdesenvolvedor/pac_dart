import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pac_dart/core/gemini/chave_gemini.dart';
import 'package:pac_dart/features/tutor/data/falha_ia.dart';
import 'package:pac_dart/features/tutor/data/tutor_service.dart';

/// O Gemini de mentira: CONTA as requisições, guarda os corpos e responde pela fila (vazia → 200 com '{"ok":1}').
class _Servidor {
  final pedidos = <http.Request>[];
  final respostas = <Object>[]; // http.Response, ou um objeto que é lançado
  Duration? atraso;

  late final cliente = MockClient((req) async {
    pedidos.add(req);
    if (atraso != null) await Future<void>.delayed(atraso!);
    if (respostas.isEmpty) return _ok('{"ok":1}');
    final r = respostas.removeAt(0);
    if (r is http.Response) return r;
    throw r;
  });

  Map<String, dynamic> corpo([int i = 0]) => jsonDecode(pedidos[i].body) as Map<String, dynamic>;
  Map<String, dynamic> config([int i = 0]) => corpo(i)['generationConfig'] as Map<String, dynamic>;
}

http.Response _json(int status, Object corpo) =>
    http.Response.bytes(utf8.encode(corpo is String ? corpo : jsonEncode(corpo)), status,
        headers: const {'content-type': 'application/json; charset=utf-8'});

http.Response _ok(String texto, {String finish = 'STOP'}) => _json(200, {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': texto}
            ]
          },
          'finishReason': finish,
        }
      ]
    });

http.Response _vazio(String finish) => _json(200, {
      'candidates': [
        {
          'content': {'parts': <Object>[]},
          'finishReason': finish,
        }
      ]
    });

/// Um Firestore offline: a LEITURA do config/tutor falha (não é "doc sem chave").
class _DbOffline extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable', message: 'Failed to get document because the client is offline.');
}

const _esquema = <String, Object?>{
  'type': 'OBJECT',
  'properties': {
    'fala': {'type': 'STRING'},
  },
  'required': ['fala'],
};

Future<String> _json1(GeminiTutorService s, {int maxTokens = 600}) => s.perguntarJson(
      persona: 'PERSONA-X',
      contexto: 'CTX',
      historico: 'Aluno: hi',
      pergunta: '<<<ALUNO>>>\nI want a coffee\n<<<FIM>>>',
      esquema: _esquema,
      maxTokens: maxTokens,
    );

Future<TipoFalhaIa?> _tipoDoErro(Future<Object?> Function() f) async {
  try {
    await f();
  } on FalhaIa catch (e) {
    return e.tipo;
  }
  return null;
}

void main() {
  late _Servidor srv;
  late GeminiTutorService svc;

  Future<void> config(Map<String, Object?> dados) async {
    final db = FakeFirebaseFirestore();
    await db.collection('config').doc('tutor').set(dados);
    ChaveGemini.dbParaTestes = db;
  }

  setUp(() async {
    GeminiTutorService.resetarCompatibilidade();
    ChaveGemini.limparCache();
    await config({'chaveGemini': 'chave-x'});
    srv = _Servidor();
    svc = GeminiTutorService(client: srv.cliente);
  });

  tearDown(() {
    GeminiTutorService.resetarCompatibilidade();
    ChaveGemini.limparCache();
    ChaveGemini.dbParaTestes = null;
  });

  test('o corpo exato: schema, mime e thinking DENTRO do generationConfig; 1 requisição; devolve o texto', () async {
    srv.respostas.add(_ok('{"fala":"Sure!"}'));
    expect(await _json1(svc), '{"fala":"Sure!"}');
    expect(srv.pedidos, hasLength(1));
    final corpo = srv.corpo();
    expect(corpo['systemInstruction'], {
      'parts': [
        {'text': 'PERSONA-X'}
      ]
    });
    final texto = (((corpo['contents'] as List).single as Map)['parts'] as List).single['text'] as String;
    expect(texto, GeminiTutorService.montarPrompt(contexto: 'CTX', historico: 'Aluno: hi', pergunta: '<<<ALUNO>>>\nI want a coffee\n<<<FIM>>>'));
    final g = srv.config();
    expect(g['responseMimeType'], 'application/json');
    expect(g['responseSchema'], _esquema);
    expect(g['thinkingConfig'], {'thinkingBudget': 0});
    expect(g['maxOutputTokens'], 600);
    expect(g['temperature'], 0.5);
    for (final k in ['responseSchema', 'responseMimeType', 'thinkingConfig']) {
      expect(corpo.containsKey(k), isFalse, reason: '$k fora do generationConfig a API recusa ou ignora');
    }
    expect(srv.pedidos.single.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=chave-x');
  });

  test('várias partes de texto vêm juntas', () async {
    srv.respostas.add(_json(200, {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': '{"fala":'},
              {'text': '"Hi"}'},
            ]
          }
        }
      ]
    }));
    expect(await _json1(svc), '{"fala":"Hi"}');
  });

  group('modeloConversa (config/tutor, sem deploy)', () {
    test('um modelo válido do config vai na URL', () async {
      await config({'chaveGemini': 'chave-x', 'modeloConversa': 'gemini-flash-lite-latest'});
      expect(await GeminiTutorService.modeloConversa(), 'gemini-flash-lite-latest');
      await _json1(svc);
      expect(srv.pedidos.single.url.path, endsWith('/models/gemini-flash-lite-latest:generateContent'));
    });

    test('um valor inválido é ignorado (fica o padrão)', () async {
      await config({'chaveGemini': 'chave-x', 'modeloConversa': 'Gemini Flash/../x?'});
      expect(await GeminiTutorService.modeloConversa(), GeminiTutorService.modelo);
      await _json1(svc);
      expect(srv.pedidos.single.url.path, endsWith('/models/gemini-flash-latest:generateContent'));
    });

    test('sem o campo → o padrão', () async {
      expect(await GeminiTutorService.modeloConversa(), 'gemini-flash-latest');
    });
  });

  group('erros do servidor: nada de nova tentativa', () {
    test('429 → limite, 1 requisição', () async {
      srv.respostas.add(_json(429, '{"error":{"code":429,"status":"RESOURCE_EXHAUSTED"}}'));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.limite);
      expect(srv.pedidos, hasLength(1));
    });

    test('429 por dia → limiteDiario, 1 requisição', () async {
      srv.respostas.add(_json(429,
          '{"error":{"code":429,"details":[{"violations":[{"quotaId":"GenerateRequestsPerDayPerProjectPerModel-FreeTier"}]}]}}'));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.limiteDiario);
      expect(srv.pedidos, hasLength(1));
    });

    test('503 → ocupado, 1 requisição (sem retry)', () async {
      srv.respostas.add(_json(503, '{"error":{"status":"UNAVAILABLE","message":"The model is overloaded."}}'));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.ocupado);
      expect(srv.pedidos, hasLength(1));
    });

    test('a FalhaIa guarda o status e o corpo', () async {
      srv.respostas.add(_json(500, '{"error":"interno"}'));
      try {
        await _json1(svc);
        fail('devia lançar');
      } on FalhaIa catch (e) {
        expect(e.status, 500);
        expect('$e', 'Gemini 500: {"error":"interno"}');
      }
    });
  });

  group('compatibilidade (no máximo 2 requisições por chamada)', () {
    test('400 "thinking" → 2 requisições, a 2ª sem thinkingConfig; a próxima chamada já vai sem', () async {
      srv.respostas
        ..add(_json(400, '{"error":{"message":"Unknown name \\"thinkingConfig\\" at generation_config"}}'))
        ..add(_ok('{"fala":"ok"}'));
      expect(await _json1(svc), '{"fala":"ok"}');
      expect(srv.pedidos, hasLength(2));
      expect(srv.config(0).containsKey('thinkingConfig'), isTrue);
      expect(srv.config(1).containsKey('thinkingConfig'), isFalse);
      expect(srv.config(1)['responseSchema'], _esquema, reason: 'só tira o que o modelo recusou');

      await _json1(svc);
      expect(srv.pedidos, hasLength(3));
      expect(srv.config(2).containsKey('thinkingConfig'), isFalse);
    });

    test('400 que fala de thinking E responseSchema → 2 requisições, a 2ª sem os dois', () async {
      srv.respostas
        ..add(_json(400,
            '{"error":{"message":"Unknown name \\"thinkingConfig\\"; Unknown name \\"responseSchema\\""}}'))
        ..add(_ok('{"fala":"ok"}'));
      expect(await _json1(svc), '{"fala":"ok"}');
      expect(srv.pedidos, hasLength(2));
      expect(srv.config(1).containsKey('thinkingConfig'), isFalse);
      expect(srv.config(1).containsKey('responseSchema'), isFalse);
      expect(srv.config(1)['responseMimeType'], 'application/json');
    });

    test('400 "responseSchema" duas vezes (a nova tentativa falha também) → lança, 2 requisições no total', () async {
      srv.respostas
        ..add(_json(400, '{"error":{"message":"Invalid value at response_schema"}}'))
        ..add(_json(400, '{"error":{"message":"Invalid value at response_schema"}}'));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.outro);
      expect(srv.pedidos, hasLength(2));
    });

    test('400 de outra coisa não tenta de novo', () async {
      srv.respostas.add(_json(400, '{"error":{"message":"Invalid JSON payload received."}}'));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.outro);
      expect(srv.pedidos, hasLength(1));
    });

    test('200 vazio com MAX_TOKENS → nova tentativa com 1500; vazio de novo → devolve \'\' (2 requisições)', () async {
      srv.respostas
        ..add(_vazio('MAX_TOKENS'))
        ..add(_vazio('MAX_TOKENS'));
      expect(await _json1(svc), '');
      expect(srv.pedidos, hasLength(2));
      expect(srv.config(0)['maxOutputTokens'], 600);
      expect(srv.config(1)['maxOutputTokens'], 1500);
    });

    test('200 vazio com MAX_TOKENS e depois texto → o texto', () async {
      srv.respostas
        ..add(_vazio('MAX_TOKENS'))
        ..add(_ok('{"fala":"ok"}'));
      expect(await _json1(svc), '{"fala":"ok"}');
      expect(srv.pedidos, hasLength(2));
    });

    test('200 vazio com STOP → \'\' sem nova tentativa', () async {
      srv.respostas.add(_vazio('STOP'));
      expect(await _json1(svc), '');
      expect(srv.pedidos, hasLength(1));
    });
  });

  group('segurança, rede e chave', () {
    test('promptFeedback.blockReason → recusada', () async {
      srv.respostas.add(_json(200, {
        'promptFeedback': {'blockReason': 'SAFETY'}
      }));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.recusada);
      expect(srv.pedidos, hasLength(1));
    });

    test('finishReason SAFETY sem texto → recusada', () async {
      srv.respostas.add(_vazio('SAFETY'));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.recusada);
    });

    test('ClientException → semRede', () async {
      srv.respostas.add(http.ClientException('XMLHttpRequest error.'));
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.semRede);
      expect(srv.pedidos, hasLength(1));
    });

    test('sem a chave no config/tutor → credencial, nenhuma requisição', () async {
      ChaveGemini.limparCache();
      ChaveGemini.dbParaTestes = FakeFirebaseFirestore();
      expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.credencial);
      expect(await _tipoDoErro(() => svc.perguntarComo(persona: 'p', contexto: 'c', historico: '', pergunta: 'q').join()),
          TipoFalhaIa.credencial);
      expect(srv.pedidos, isEmpty);
    });
  });

  test('leitura do config/tutor que FALHA (offline) → semRede (sem janela), nunca credencial; nenhuma requisição', () async {
    ChaveGemini.limparCache();
    ChaveGemini.dbParaTestes = _DbOffline();
    expect(await _tipoDoErro(() => _json1(svc)), TipoFalhaIa.semRede);
    expect(await _tipoDoErro(() => svc.perguntarComo(persona: 'p', contexto: 'c', historico: '', pergunta: 'q').join()),
        TipoFalhaIa.semRede);
    expect(srv.pedidos, isEmpty);
    // voltou a rede: a chave é lida e a chamada segue
    await config({'chaveGemini': 'chave-x'});
    srv.respostas.add(_ok('{"fala":"Sure!"}'));
    expect(await _json1(svc), '{"fala":"Sure!"}');
  });

  test('perguntarComo: 200 com corpo ilegível → outro (status 200), sem casar "429"/"quota"/"503" do trecho', () async {
    for (final corpo in ['<html>Daily quota exceeded 429</html>', '<html>Service 503 overloaded</html>', '{"candidates":[{"cont']) {
      srv.respostas.add(http.Response(corpo, 200));
      Object? erro;
      try {
        await svc.perguntarComo(persona: 'p', contexto: 'c', historico: '', pergunta: 'q').join();
      } catch (e) {
        erro = e;
      }
      expect(erro, isA<FalhaIa>(), reason: corpo);
      expect((erro! as FalhaIa).tipo, TipoFalhaIa.outro, reason: corpo);
      expect(FalhaIa.de(erro).tipo, TipoFalhaIa.outro, reason: 'o IaCubit reclassifica pelo FalhaIa.de');
      expect((erro as FalhaIa).status, 200);
    }
  });

  test('tempos SEPARADOS: o turno JSON estoura (semRede) e o chat longo responde normalmente', () async {
    // (a escala do "uma resposta de 30 s não derruba o chat antigo": 10 ms × 200 ms contra 50 ms)
    srv.atraso = const Duration(milliseconds: 50);
    final s = GeminiTutorService(
        client: srv.cliente,
        timeoutJson: const Duration(milliseconds: 10),
        timeoutLongo: const Duration(milliseconds: 200));
    // as duas na fila já: o pedido que estourou ainda consome a 1ª quando o atraso dele acaba
    srv.respostas
      ..add(_ok('{"fala":"tarde demais"}'))
      ..add(_ok('Resposta longa do Prof. Dash'));
    expect(await _tipoDoErro(() => _json1(s)), TipoFalhaIa.semRede);
    expect(await s.perguntarComo(persona: 'p', contexto: 'c', historico: '', pergunta: 'q').join(),
        'Resposta longa do Prof. Dash');
  });

  group('perguntarComo (o chat do Prof. Dash) continua igual', () {
    test('429 → FalhaIa cujo texto tem "Gemini 429" (o TutorCubit procura isso)', () async {
      srv.respostas.add(_json(429, '{"error":{"status":"RESOURCE_EXHAUSTED"}}'));
      try {
        await svc.perguntarComo(persona: 'p', contexto: 'c', historico: '', pergunta: 'q').join();
        fail('devia lançar');
      } on FalhaIa catch (e) {
        expect(e.tipo, TipoFalhaIa.limite);
        expect('$e', contains('Gemini 429'));
        expect('$e', contains('RESOURCE_EXHAUSTED'));
      }
      expect(srv.pedidos, hasLength(1));
    });

    test('o corpo de sempre: sem JSON, sem schema, 2048 tokens', () async {
      srv.respostas.add(_ok('Oi!'));
      expect(await svc.perguntarComo(persona: 'p', contexto: 'c', historico: '', pergunta: 'q').join(), 'Oi!');
      expect(srv.config(), {'temperature': 0.4, 'maxOutputTokens': 2048});
    });
  });
}
