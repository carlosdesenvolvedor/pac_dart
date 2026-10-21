import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pac_dart/core/gemini/chave_gemini.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/tutor/data/falha_ia.dart';
import 'package:pac_dart/features/tutor/data/tutor_claude.dart';
import 'package:pac_dart/features/tutor/data/tutor_roteador.dart';
import 'package:pac_dart/features/tutor/data/tutor_service.dart';

import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria;

const _esquema = <String, Object?>{
  'type': 'OBJECT',
  'properties': {
    'fala': {'type': 'STRING'},
  },
  'required': ['fala'],
};
const _falaDoAluno = 'my secret sentence about Ana 555-1234';
const _url = 'https://paclingo-conversa.exemplo.workers.dev';

/// O Gemini de mentira (REST: [TutorJson]); conta cada caminho e pode falhar.
class _Gemini implements TutorService, TutorComPersona, TutorJson {
  int json = 0, como = 0, simples = 0;
  Object? erro;
  final perguntas = <String>[];

  @override
  Future<String> perguntarJson({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
    required Map<String, Object?> esquema,
    int maxTokens = 600,
  }) async {
    json++;
    perguntas.add(pergunta);
    if (erro != null) throw erro!;
    return '{"fala":"do Gemini"}';
  }

  @override
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    como++;
    perguntas.add(pergunta);
    yield 'como:$persona';
  }

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) async* {
    simples++;
    perguntas.add(pergunta);
    yield 'simples:$contexto';
  }
}

/// O Firebase AI do nativo: só [TutorComPersona] (sem [TutorJson]).
class _GeminiNativo implements TutorService, TutorComPersona {
  final perguntas = <String>[];
  @override
  Stream<String> perguntarComo({
    required String persona,
    required String contexto,
    required String historico,
    required String pergunta,
  }) async* {
    perguntas.add(pergunta);
    yield '{"fala":"nativo"}';
  }

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) =>
      throw UnimplementedError();
}

/// Um tutor de teste antigo: só [TutorService].
class _GeminiSimples implements TutorService {
  final contextos = <String>[], perguntas = <String>[];
  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) async* {
    contextos.add(contexto);
    perguntas.add(pergunta);
    yield '{"fala":"simples"}';
  }
}

class _Relogio {
  DateTime t = DateTime.utc(2026, 10, 21, 13);
  DateTime call() => t;
  void passar(Duration d) => t = t.add(d);
}

/// O Worker de mentira: responde pela fila (vazia → 200 com um turno).
class _Worker {
  final pedidos = <http.Request>[];
  final respostas = <Object>[];

  late final cliente = MockClient((req) async {
    pedidos.add(req);
    if (respostas.isEmpty) return _ok();
    final r = respostas.removeAt(0);
    if (r is http.Response) return r;
    throw r;
  });
}

http.Response _ok() => http.Response.bytes(
    utf8.encode(jsonEncode({
      'texto': '{"fala":"do Claude"}',
      'uso': {'entrada': 1, 'saida': 1},
      'restantesHoje': 41,
    })),
    200,
    headers: const {'content-type': 'application/json; charset=utf-8'});

http.Response _erro(int status, String codigo, {Map<String, String> headers = const {}}) => http.Response.bytes(
    utf8.encode(jsonEncode({'erro': codigo, 'mensagem': 'mensagem de $codigo'})), status,
    headers: {'content-type': 'application/json; charset=utf-8', ...headers});

void main() {
  late _Gemini gemini;
  late _Worker worker;
  late _Relogio relogio;
  late Map<String, String?> config;
  late int leituras;
  late int tokens;

  setUp(() {
    gemini = _Gemini();
    worker = _Worker();
    relogio = _Relogio();
    config = {TutorConversaRoteador.campoProvedor: 'claude', TutorConversaRoteador.campoUrl: _url};
    leituras = 0;
    tokens = 0;
  });

  TutorConversaRoteador criar({TutorService? g, String formatoSemJson = ''}) => TutorConversaRoteador(
        gemini: g ?? gemini,
        client: worker.cliente,
        obterToken: () async => 'token-${++tokens}',
        agora: relogio.call,
        lerCampo: (nome) async {
          leituras++;
          return config[nome];
        },
        formatoSemJson: formatoSemJson,
      );

  Future<String> turno(TutorConversaRoteador r) => r.perguntarJson(
        persona: 'PERSONA',
        contexto: 'café',
        historico: 'Aluno: hi',
        pergunta: _falaDoAluno,
        esquema: _esquema,
      );

  Future<FalhaIa> falha(Future<Object?> f) async {
    try {
      await f;
    } on FalhaIa catch (e) {
      return e;
    }
    fail('devia lançar FalhaIa');
  }

  group('config', () {
    for (final (rotulo, provedor, url) in <(String, String?, String?)>[
      ('sem provedorConversa', null, _url),
      ('provedorConversa = gemini', 'gemini', _url),
      ('sem urlConversa', 'claude', null),
      ('urlConversa que não é url', 'claude', 'paclingo-conversa'),
      ('urlConversa http fora do localhost', 'claude', 'http://exemplo.workers.dev'),
    ]) {
      test('desligada ($rotulo) → Gemini, o Worker nem é chamado', () async {
        config = {TutorConversaRoteador.campoProvedor: provedor, TutorConversaRoteador.campoUrl: url};
        final r = criar();
        expect(await turno(r), '{"fala":"do Gemini"}');
        expect(await r.urlClaudeAtiva(), isNull);
        expect(worker.pedidos, isEmpty);
        expect(gemini.json, 1);
      });
    }

    test('ligada (provedorConversa = claude, sem caixa/espaços) → Claude; o Gemini não é chamado', () async {
      config[TutorConversaRoteador.campoProvedor] = ' Claude ';
      final r = criar();
      expect(await turno(r), '{"fala":"do Claude"}');
      expect(worker.pedidos.single.url.toString(), '$_url/v1/turno');
      expect(gemini.json, 0);
      expect(r.restantesNoClaude, 41);
    });

    test('http://localhost (wrangler dev) é aceito', () {
      expect(TutorConversaRoteador.urlValida('http://localhost:8787'), 'http://localhost:8787');
      expect(TutorConversaRoteador.urlValida(' $_url '), _url);
      expect(TutorConversaRoteador.urlValida('ftp://x.dev'), isNull);
    });

    test('a config é lida no máximo a cada 5 min (e desligar passa a valer depois disso)', () async {
      final r = criar();
      await turno(r);
      await turno(r);
      expect(leituras, 2, reason: 'provedor + url, uma vez só');
      config[TutorConversaRoteador.campoProvedor] = null; // desligou no Firestore
      relogio.passar(const Duration(minutes: 4));
      expect(await turno(r), '{"fala":"do Claude"}');
      relogio.passar(const Duration(minutes: 1));
      expect(await turno(r), '{"fala":"do Gemini"}');
      expect(leituras, 3, reason: 'desligado: nem lê a url');
      expect(worker.pedidos, hasLength(3));
    });

    test('chamadas juntas leem a config uma vez', () async {
      final r = criar();
      await Future.wait([turno(r), turno(r), turno(r)]);
      expect(leituras, 2);
      expect(worker.pedidos, hasLength(3));
    });
  });

  test('o token é pedido de novo a cada turno', () async {
    final r = criar();
    await turno(r);
    await turno(r);
    expect(worker.pedidos.map((p) => p.headers['Authorization']), ['Bearer token-1', 'Bearer token-2']);
  });

  group('fallback', () {
    final quedas = <(String, Object)>[
      ('sem_chave', _erro(503, 'sem_chave')),
      ('nao_autenticado', _erro(401, 'nao_autenticado')),
      ('origem_negada', _erro(403, 'origem_negada')),
      ('404 sem o Worker (não publicado)', http.Response('<html>nada aqui</html>', 404)),
      ('rede/DNS', http.ClientException('Failed host lookup: paclingo-conversa.exemplo.workers.dev')),
    ];
    for (final (rotulo, resposta) in quedas) {
      test('$rotulo → aquele turno vai ao Gemini e o Claude fica de lado por 10 min', () async {
        final r = criar();
        worker.respostas.add(resposta);
        expect(await turno(r), '{"fala":"do Gemini"}');
        expect(worker.pedidos, hasLength(1));
        expect(gemini.json, 1);
        expect(r.claudeForaAte, relogio.t.add(TutorConversaRoteador.foraPor));

        // dentro dos 10 min: direto ao Gemini, sem martelar o Worker
        relogio.passar(const Duration(minutes: 9, seconds: 59));
        expect(await turno(r), '{"fala":"do Gemini"}');
        expect(worker.pedidos, hasLength(1));
        expect(await r.urlClaudeAtiva(), isNull);

        // depois: o Claude de novo
        relogio.passar(const Duration(seconds: 1));
        expect(r.claudeForaAte, isNull);
        expect(await turno(r), '{"fala":"do Claude"}');
        expect(worker.pedidos, hasLength(2));
      });
    }

    test('o Gemini do fallback também falha → a falha DELE sobe (uma tentativa só)', () async {
      final r = criar();
      worker.respostas.add(_erro(503, 'sem_chave'));
      gemini.erro = const FalhaIa(TipoFalhaIa.limite, status: 429, detalhe: 'quota');
      final f = await falha(turno(r));
      expect(f, isNot(isA<FalhaClaude>()));
      expect(f.tipo, TipoFalhaIa.limite);
      expect(gemini.json, 1);
      expect(worker.pedidos, hasLength(1));
    });

    test('pedido_invalido → só aquele turno vai ao Gemini; o próximo volta ao Claude', () async {
      final r = criar();
      worker.respostas.add(_erro(400, 'pedido_invalido'));
      expect(await turno(r), '{"fala":"do Gemini"}');
      expect(r.claudeForaAte, isNull);
      expect(await turno(r), '{"fala":"do Claude"}');
      expect(worker.pedidos, hasLength(2));
    });

    test('limite_pessoal NÃO cai: limitePessoal com a mensagem do Worker; até o Retry-After nem chama', () async {
      final r = criar();
      worker.respostas.add(_erro(429, 'limite_pessoal', headers: {'Retry-After': '3600'}));
      final f = await falha(turno(r));
      expect(f, isA<FalhaClaude>());
      expect(f.tipo, TipoFalhaIa.limitePessoal);
      expect((f as FalhaClaude).mensagem, 'mensagem de limite_pessoal');
      expect(gemini.json, 0);
      expect(r.claudeForaAte, isNull);

      relogio.passar(const Duration(minutes: 59));
      expect((await falha(turno(r))).tipo, TipoFalhaIa.limitePessoal);
      expect(worker.pedidos, hasLength(1), reason: 'sem martelar o Worker');
      expect(gemini.json, 0);

      relogio.passar(const Duration(minutes: 1));
      expect(await turno(r), '{"fala":"do Claude"}');
      expect(worker.pedidos, hasLength(2));
    });

    test('limite_pessoal sem Retry-After: repete até a próxima meia-noite UTC (quando o Worker zera)', () async {
      final r = criar(); // 13:00 UTC
      worker.respostas.add(_erro(429, 'limite_pessoal'));
      await falha(turno(r));
      relogio.passar(const Duration(hours: 10, minutes: 59));
      expect((await falha(turno(r))).tipo, TipoFalhaIa.limitePessoal);
      expect(worker.pedidos, hasLength(1));
      relogio.passar(const Duration(minutes: 1));
      expect(await turno(r), '{"fala":"do Claude"}');
    });

    test('limite_geral com Retry-After longo (o teto do dia do Worker) → Gemini; o Claude de lado até lá', () async {
      final r = criar();
      worker.respostas.add(_erro(429, 'limite_geral', headers: {'Retry-After': '3600'}));
      expect(await turno(r), '{"fala":"do Gemini"}');
      expect(r.claudeForaAte, relogio.t.add(const Duration(hours: 1)));

      relogio.passar(const Duration(minutes: 59, seconds: 59));
      expect(await turno(r), '{"fala":"do Gemini"}');
      expect(worker.pedidos, hasLength(1), reason: 'sem martelar o Worker');
      relogio.passar(const Duration(seconds: 1));
      expect(await turno(r), '{"fala":"do Claude"}');
      expect(worker.pedidos, hasLength(2));
    });

    test('limite_geral com Retry-After curto (429 passageiro da Anthropic) → FalhaIa limite, sem Gemini', () async {
      final r = criar();
      worker.respostas.add(_erro(429, 'limite_geral', headers: {'Retry-After': '30'}));
      final f = await falha(turno(r));
      expect((f.tipo, (f as FalhaClaude).retryAfter), (TipoFalhaIa.limite, const Duration(seconds: 30)));
      expect(gemini.json, 0);
      expect(r.claudeForaAte, isNull);
    });

    test('${TutorConversaRoteador.panesParaFora} panes seguidas (ia_falhou, ia_demorou, 5xx) → Gemini; o Claude de lado 10 min',
        () async {
      final r = criar();
      worker.respostas.addAll([
        _erro(502, 'ia_falhou'),
        _erro(504, 'ia_demorou'),
        http.Response('<html>erro da Cloudflare</html>', 500),
      ]);
      expect((await falha(turno(r))).tipo, TipoFalhaIa.ocupado);
      expect((await falha(turno(r))).tipo, TipoFalhaIa.ocupado);
      expect(gemini.json, 0);
      expect(await turno(r), '{"fala":"do Gemini"}', reason: 'a 3ª pane seguida cai no mesmo turno');
      expect(r.claudeForaAte, relogio.t.add(TutorConversaRoteador.foraPor));
      expect(await turno(r), '{"fala":"do Gemini"}');
      expect(worker.pedidos, hasLength(3));
      relogio.passar(TutorConversaRoteador.foraPor);
      expect(await turno(r), '{"fala":"do Claude"}');
    });

    test('panes que não são seguidas (uma resposta ou uma recusa no meio) não deixam o Claude de lado', () async {
      final r = criar();
      worker.respostas.addAll([
        _erro(502, 'ia_falhou'),
        _erro(502, 'ia_falhou'),
        _ok(),
        _erro(502, 'ia_falhou'),
        _erro(502, 'ia_falhou'),
        http.Response.bytes(
            utf8.encode(jsonEncode({'erro': 'ia_falhou', 'mensagem': 'A IA não quis responder a essa fala.'})), 502),
        _erro(502, 'ia_falhou'),
        _erro(502, 'ia_falhou'),
      ]);
      for (var i = 0; i < 8; i++) {
        if (i == 2) {
          expect(await turno(r), '{"fala":"do Claude"}');
        } else {
          await falha(turno(r));
        }
      }
      expect(gemini.json, 0);
      expect(r.claudeForaAte, isNull);
      expect(worker.pedidos, hasLength(8));
    });

    for (final (codigo, status, tipo) in <(String, int, TipoFalhaIa)>[
      ('limite_geral', 429, TipoFalhaIa.limite),
      ('ia_falhou', 502, TipoFalhaIa.ocupado),
      ('ia_demorou', 504, TipoFalhaIa.ocupado),
    ]) {
      test('$codigo → FalhaIa ${tipo.name}, sem Gemini; o próximo turno tenta o Claude de novo', () async {
        final r = criar();
        worker.respostas.add(_erro(status, codigo));
        expect((await falha(turno(r))).tipo, tipo);
        expect(gemini.json, 0);
        expect(r.claudeForaAte, isNull);
        expect(await turno(r), '{"fala":"do Claude"}');
      });
    }
  });

  group('o resto vai sempre ao Gemini', () {
    test('perguntar e perguntarComo (Tutor, "Por quê?", Escrita) nunca vão ao Claude', () async {
      final r = criar();
      expect(await r.perguntar(contexto: 'c', historico: '', pergunta: 'p').join(), 'simples:c');
      expect(await r.perguntarComo(persona: 'Dash', contexto: 'c', historico: '', pergunta: 'p').join(), 'como:Dash');
      expect(worker.pedidos, isEmpty);
      expect(leituras, 0);
    });

    test('Gemini sem TutorComPersona: a persona vai no contexto (como no IaCubit.consultar)', () async {
      final simples = _GeminiSimples();
      final r = criar(g: simples);
      await r.perguntarComo(persona: 'Dash', contexto: 'c', historico: '', pergunta: 'p').join();
      expect(simples.contextos.single, 'Dash\n\nc');
    });

    test('nativo (sem TutorJson): o turno no Gemini leva o formato em palavras, como o IaCubit fazia', () async {
      config[TutorConversaRoteador.campoProvedor] = null;
      final nativo = _GeminiNativo();
      final r = criar(g: nativo, formatoSemJson: 'Devolva SOMENTE um JSON.');
      expect(await turno(r), '{"fala":"nativo"}');
      expect(nativo.perguntas.single, '$_falaDoAluno\n\nDevolva SOMENTE um JSON.');

      final simples = _GeminiSimples();
      final r2 = criar(g: simples);
      expect(await turno(r2), '{"fala":"simples"}');
      expect(simples.perguntas.single, _falaDoAluno, reason: 'formatoSemJson vazio: a pergunta vai como está');
      expect(simples.contextos.single, 'PERSONA\n\ncafé');
    });

    test('nativo com o Claude fora: o fallback também leva o formato', () async {
      final nativo = _GeminiNativo();
      final r = criar(g: nativo, formatoSemJson: 'FORMATO');
      worker.respostas.add(_erro(503, 'sem_chave'));
      expect(await turno(r), '{"fala":"nativo"}');
      expect(nativo.perguntas.single, '$_falaDoAluno\n\nFORMATO');
    });
  });

  test('nunca loga nada (nem o texto do aluno) em nenhum caminho', () async {
    final logs = <String>[];
    await runZoned(
      () async {
        final r = criar();
        await turno(r);
        worker.respostas.add(_erro(429, 'limite_pessoal', headers: {'Retry-After': '60'}));
        await falha(turno(r));
        relogio.passar(const Duration(minutes: 2));
        worker.respostas.add(http.ClientException('Connection refused'));
        await turno(r);
      },
      zoneSpecification: ZoneSpecification(print: (_, _, _, linha) => logs.add(linha)),
    );
    expect(logs, isEmpty);
  });

  group('com o IaCubit', () {
    Future<IaCubit> cubit(TutorService s) async {
      final c = IaCubit(service: s, cotaRepo: CotaMemoria(), cache: CacheMemoria(), agora: relogio.call);
      await c.carregar();
      return c;
    }

    Future<ResultadoIa> consultar(IaCubit c) => c.consultarJson(
          persona: 'PERSONA',
          contexto: 'café',
          historico: '',
          pergunta: _falaDoAluno,
          esquema: _esquema,
          formatoTexto: 'FORMATO',
        );

    test('Claude ligado: o turno vem do Claude e gasta 1 uso', () async {
      final c = await cubit(criar());
      final r = await consultar(c);
      expect(r, const ResultadoIa(StatusIa.ok, '{"fala":"do Claude"}'));
      expect(c.state.restantes, 29);
      await c.close();
    });

    test('limite_pessoal → falhou (limitePessoal), não gasta, NÃO abre a janela compartilhada', () async {
      final c = await cubit(criar());
      worker.respostas.add(_erro(429, 'limite_pessoal', headers: {'Retry-After': '3600'}));
      final r = await consultar(c);
      expect(r, const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.limitePessoal));
      expect(c.state.restantes, 30);
      expect(c.descanso.ativo(relogio.t), isFalse);
      // o "Por quê?"/Escrita (Gemini) seguem; a Conversa segue barrada até o Retry-After, sem chamar o Worker
      expect((await c.consultar(contexto: 'c', pergunta: 'p')).status, StatusIa.ok);
      expect(await consultar(c), const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.limitePessoal));
      expect(worker.pedidos, hasLength(1));
      await c.close();
    });

    test('limite_geral do dia → o Gemini responde a Conversa; nenhuma janela barra o resto', () async {
      final c = await cubit(criar());
      worker.respostas.add(_erro(429, 'limite_geral', headers: {'Retry-After': '39600'}));
      expect(await consultar(c), const ResultadoIa(StatusIa.ok, '{"fala":"do Gemini"}'));
      expect(c.descanso.ativo(relogio.t), isFalse);
      expect((await c.consultar(contexto: 'c', pergunta: 'p')).status, StatusIa.ok);
      expect(await consultar(c), const ResultadoIa(StatusIa.ok, '{"fala":"do Gemini"}'));
      expect(worker.pedidos, hasLength(1));
      await c.close();
    });

    test('Worker fora → o Gemini responde no mesmo turno (sem janela de descanso)', () async {
      final c = await cubit(criar());
      worker.respostas.add(http.Response('', 404));
      final r = await consultar(c);
      expect(r, const ResultadoIa(StatusIa.ok, '{"fala":"do Gemini"}'));
      expect(c.descanso.ativo(relogio.t), isFalse);
      await c.close();
    });
  });

  group('ChaveGemini.campoRecente (o lerCampo padrão)', () {
    test('o lerCampo padrão vai ao banco quando o cache do roteador vence: desligar chega em ~5 min, não ~10',
        () async {
      ChaveGemini.relogio = relogio.call;
      final db = FakeFirebaseFirestore();
      final doc = db.collection('config').doc('tutor');
      await doc.set({'chaveGemini': 'k', 'provedorConversa': 'claude', 'urlConversa': _url});
      ChaveGemini.dbParaTestes = db;
      expect(await ChaveGemini.obter(), 'k'); // outra tela leu o config/tutor (o cache do ChaveGemini)
      await doc.set({'chaveGemini': 'k'}); // desligou no Firestore
      relogio.passar(const Duration(minutes: 4, seconds: 59));
      final r = TutorConversaRoteador(
          gemini: gemini, client: worker.cliente, obterToken: () async => 't', agora: relogio.call);
      expect(await turno(r), '{"fala":"do Gemini"}', reason: 'nada do doc velho guardado no ChaveGemini');
      expect(worker.pedidos, isEmpty);

      await doc.set({'chaveGemini': 'k', 'provedorConversa': 'claude', 'urlConversa': _url}); // religou
      relogio.passar(TutorConversaRoteador.configValePor);
      expect(await turno(r), '{"fala":"do Claude"}');
    });

    late DateTime agora;
    setUp(() {
      agora = DateTime.utc(2026, 10, 21, 13);
      ChaveGemini.relogio = () => agora;
    });
    tearDown(() {
      ChaveGemini.limparCache();
      ChaveGemini.dbParaTestes = null;
      ChaveGemini.relogio = DateTime.now;
    });

    test('relê o config/tutor depois de maxIdade (ligar o Claude chega ao app aberto)', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('config').doc('tutor').set({'chaveGemini': 'k'});
      ChaveGemini.dbParaTestes = db;
      expect(await ChaveGemini.campoRecente('provedorConversa'), isNull);

      await db.collection('config').doc('tutor').set({'chaveGemini': 'k', 'provedorConversa': 'claude'});
      agora = agora.add(const Duration(minutes: 4));
      expect(await ChaveGemini.campoRecente('provedorConversa'), isNull, reason: 'ainda do cache');
      expect(await ChaveGemini.campo('provedorConversa'), isNull, reason: 'o campo de sempre segue o cache');
      agora = agora.add(const Duration(minutes: 1));
      expect(await ChaveGemini.campoRecente('provedorConversa'), 'claude');
      expect(await ChaveGemini.campo('provedorConversa'), 'claude', reason: 'o cache foi renovado');
      expect(await ChaveGemini.obter(), 'k');
    });

    test('releitura que falha fica com o cache; sem nada lido → null (nunca lança)', () async {
      final db = FakeFirebaseFirestore();
      await db.collection('config').doc('tutor').set({'chaveGemini': 'k', 'urlConversa': _url});
      ChaveGemini.dbParaTestes = db;
      expect(await ChaveGemini.campoRecente('urlConversa'), _url);
      ChaveGemini.dbParaTestes = _DbOffline();
      agora = agora.add(const Duration(minutes: 10));
      expect(await ChaveGemini.campoRecente('urlConversa'), _url);
      ChaveGemini.limparCache();
      expect(await ChaveGemini.campoRecente('urlConversa'), isNull);
    });
  });
}

/// Um Firestore offline: a leitura em si falha.
class _DbOffline extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable', message: 'client is offline');
}
