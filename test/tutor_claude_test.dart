import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pac_dart/features/ia/domain/conversa_resposta.dart' show esquemaTurno;
import 'package:pac_dart/features/tutor/data/falha_ia.dart';
import 'package:pac_dart/features/tutor/data/tutor_claude.dart';

/// O Worker de mentira: guarda os pedidos e responde pela fila (vazia → 200 com um turno).
class _Worker {
  final pedidos = <http.Request>[];
  final respostas = <Object>[]; // http.Response, ou um objeto que é lançado

  late final cliente = MockClient((req) async {
    pedidos.add(req);
    if (respostas.isEmpty) return _ok('{"fala":"Hi!"}');
    final r = respostas.removeAt(0);
    if (r is http.Response) return r;
    throw r;
  });

  Map<String, dynamic> corpo([int i = 0]) => jsonDecode(pedidos[i].body) as Map<String, dynamic>;
}

http.Response _json(int status, Object corpo, {Map<String, String> headers = const {}}) =>
    http.Response.bytes(utf8.encode(corpo is String ? corpo : jsonEncode(corpo)), status,
        headers: {'content-type': 'application/json; charset=utf-8', ...headers});

http.Response _ok(String texto, {int restantes = 59}) => _json(200, {
      'texto': texto,
      'uso': {'entrada': 900, 'saida': 120},
      'restantesHoje': restantes,
    });

http.Response _erro(int status, String codigo, String mensagem, {Map<String, String> headers = const {}}) =>
    _json(status, {'erro': codigo, 'mensagem': mensagem}, headers: headers);

const _falaDoAluno = 'my secret sentence about Ana 555-1234';

Future<String> _turno(ClaudeTutorService s, {String persona = 'Você é a atendente.', String pergunta = _falaDoAluno}) =>
    s.perguntarJson(
      persona: persona,
      contexto: 'Cenário: cafeteria',
      historico: 'Aluno: hello\nAtendente: Hi!',
      pergunta: pergunta,
      esquema: esquemaTurno,
      maxTokens: 500,
    );

Future<FalhaClaude> _falha(Future<Object?> f) async {
  try {
    await f;
  } on FalhaClaude catch (e) {
    return e;
  }
  fail('devia lançar FalhaClaude');
}

void main() {
  late _Worker w;
  late int tokensPedidos;
  late ClaudeTutorService s;

  setUp(() {
    w = _Worker();
    tokensPedidos = 0;
    s = ClaudeTutorService(
      url: 'https://paclingo-conversa.exemplo.workers.dev/',
      client: w.cliente,
      obterToken: () async => 'token-${++tokensPedidos}',
    );
  });

  test('sucesso: POST /v1/turno com Bearer, system = persona, uma fala do aluno, o esquema e o maxTokens', () async {
    final r = await _turno(s);
    expect(r, '{"fala":"Hi!"}');
    expect(s.restantesHoje, 59);

    final req = w.pedidos.single;
    expect(req.method, 'POST');
    expect(req.url.toString(), 'https://paclingo-conversa.exemplo.workers.dev/v1/turno');
    expect(req.headers['Authorization'], 'Bearer token-1');
    expect(req.headers['Content-Type'], startsWith('application/json'));
    final c = w.corpo();
    expect(c['system'], 'Você é a atendente.');
    final msgs = c['mensagens'] as List;
    expect(msgs, hasLength(1));
    expect(msgs.single['papel'], 'aluno');
    final texto = msgs.single['texto'] as String;
    expect(texto, contains('Cenário: cafeteria'));
    expect(texto, contains('Aluno: hello'));
    expect(texto, contains(_falaDoAluno));
    // o esquema do Gemini vai como está (o Worker normaliza)
    expect(c['esquema'], jsonDecode(jsonEncode(esquemaTurno)));
    expect(c['maxTokens'], 500);
  });

  test('o token é pedido de novo a CADA chamada', () async {
    await _turno(s);
    await _turno(s);
    expect(tokensPedidos, 2);
    expect(w.pedidos[0].headers['Authorization'], 'Bearer token-1');
    expect(w.pedidos[1].headers['Authorization'], 'Bearer token-2');
  });

  test('url sem barra final também vira <url>/v1/turno', () {
    expect(ClaudeTutorService(url: 'https://x.workers.dev', obterToken: () async => 't').urlTurno.toString(),
        'https://x.workers.dev/v1/turno');
  });

  test('sem sessão (token null) ou token que falha: nao_autenticado sem tocar a rede', () async {
    final semToken = ClaudeTutorService(url: 'https://x.workers.dev', client: w.cliente, obterToken: () async => null);
    final f1 = await _falha(_turno(semToken));
    expect(f1.codigo, 'nao_autenticado');
    expect(f1.caiParaGemini, isTrue);

    final quebrado =
        ClaudeTutorService(url: 'https://x.workers.dev', client: w.cliente, obterToken: () async => throw StateError('x'));
    expect((await _falha(_turno(quebrado))).codigo, 'nao_autenticado');
    expect(w.pedidos, isEmpty);
  });

  test('turno acima do teto do Worker: pedido_invalido sem tocar a rede (só o turno cai)', () async {
    final f = await _falha(_turno(s, persona: 'x' * ClaudeTutorService.maxCaracteres));
    expect(f.codigo, 'pedido_invalido');
    expect(f.caiSoNoTurno, isTrue);
    expect(f.caiParaGemini, isFalse);
    expect(w.pedidos, isEmpty);
  });

  group('cada código de erro do Worker', () {
    final casos = <(int, String, String, TipoFalhaIa, bool)>[
      (400, 'pedido_invalido', 'A última fala precisa ser do aluno.', TipoFalhaIa.outro, false),
      (401, 'nao_autenticado', 'Sua sessão expirou.', TipoFalhaIa.credencial, true),
      (403, 'origem_negada', 'Este site não pode usar a conversa com IA.', TipoFalhaIa.credencial, true),
      (404, 'nao_encontrado', 'Endereço não encontrado.', TipoFalhaIa.credencial, true),
      (429, 'limite_pessoal', 'Você usou suas 60 falas de hoje. Volte amanhã!', TipoFalhaIa.limitePessoal, false),
      (429, 'limite_geral', 'A conversa com IA atingiu o limite de hoje. Tente amanhã.', TipoFalhaIa.limite, false),
      (502, 'ia_falhou', 'A IA não conseguiu responder agora. Tente de novo.', TipoFalhaIa.ocupado, false),
      (502, 'ia_falhou', 'A IA não quis responder a essa fala. Tente dizer de outro jeito.', TipoFalhaIa.recusada, false),
      (503, 'sem_chave', 'A conversa com IA ainda não foi configurada no servidor.', TipoFalhaIa.credencial, true),
      (504, 'ia_demorou', 'A IA demorou demais para responder. Tente de novo.', TipoFalhaIa.ocupado, false),
    ];
    for (final (status, codigo, mensagem, tipo, cai) in casos) {
      test('$status $codigo → ${tipo.name}${cai ? ' (cai para o Gemini)' : ''}', () async {
        w.respostas.add(_erro(status, codigo, mensagem));
        final f = await _falha(_turno(s));
        expect(f.codigo, codigo);
        expect(f.mensagem, mensagem);
        expect(f.tipo, tipo);
        expect(f.status, status);
        expect(f.caiParaGemini, cai);
        // o IaCubit recebe ela mesma (FalhaIa.de não a reinterpreta)
        expect(FalhaIa.de(f), same(f));
      });
    }
  });

  test('limite_pessoal traz o Retry-After (até a meia-noite UTC)', () async {
    w.respostas.add(_erro(429, 'limite_pessoal', 'Você usou suas 60 falas de hoje. Volte amanhã!',
        headers: {'Retry-After': '3600'}));
    final f = await _falha(_turno(s));
    expect(f.retryAfter, const Duration(hours: 1));
  });

  test('resposta sem o JSON do Worker: o código sai do status', () {
    expect(ClaudeTutorService.falhaDe(404, '<html>Not found</html>').codigo, 'nao_encontrado');
    expect(ClaudeTutorService.falhaDe(401, '').codigo, 'nao_autenticado');
    expect(ClaudeTutorService.falhaDe(403, '').codigo, 'origem_negada');
    final l = ClaudeTutorService.falhaDe(429, '', cabecalhos: {'retry-after': '20'});
    expect((l.codigo, l.tipo, l.retryAfter), ('limite_geral', TipoFalhaIa.limite, const Duration(seconds: 20)));
    final c = ClaudeTutorService.falhaDe(530, '<html>${'x' * 5000}</html>');
    expect(c.codigo, 'http_530');
    expect(c.caiParaGemini, isFalse);
    expect(c.detalhe.length, lessThanOrEqualTo(200));
    expect(ClaudeTutorService.falhaDe(503, 'Service Unavailable').tipo, TipoFalhaIa.ocupado);
  });

  test('ehPane: ia_falhou (menos a recusa), ia_demorou e http_5xx; o resto não', () {
    FalhaClaude f(int st, String codigo, [String msg = '']) =>
        ClaudeTutorService.falhaDe(st, jsonEncode({'erro': codigo, 'mensagem': msg}));
    expect(f(502, 'ia_falhou', 'A IA não conseguiu responder agora. Tente de novo.').ehPane, isTrue);
    expect(f(502, 'ia_falhou', 'A IA não quis responder a essa fala. Tente dizer de outro jeito.').ehPane, isFalse);
    expect(f(504, 'ia_demorou').ehPane, isTrue);
    expect(ClaudeTutorService.falhaDe(500, '<html>erro</html>').ehPane, isTrue);
    expect(ClaudeTutorService.falhaDe(530, '<html>erro</html>').ehPane, isTrue);
    for (final c in ['limite_geral', 'limite_pessoal', 'sem_chave', 'pedido_invalido']) {
      expect(f(429, c).ehPane, isFalse, reason: c);
    }
  });

  test('rede (conexão recusada, DNS, CORS) → rede, semRede, cai; tempo esgotado → ia_demorou, não cai', () async {
    expect(ClaudeTutorService(url: 'https://x.workers.dev').timeout, const Duration(seconds: 35),
        reason: 'acima dos 25 s do Worker: o 504 dele chega antes');
    w.respostas.add(http.ClientException('XMLHttpRequest error.'));
    final f = await _falha(_turno(s));
    expect((f.codigo, f.tipo, f.caiParaGemini), ('rede', TipoFalhaIa.semRede, true));

    final lento = ClaudeTutorService(
      url: 'https://x.workers.dev',
      client: MockClient((_) => Completer<http.Response>().future),
      obterToken: () async => 't',
      timeout: const Duration(milliseconds: 10),
    );
    final t = await _falha(_turno(lento));
    expect((t.codigo, t.tipo, t.caiParaGemini, t.ehPane), ('ia_demorou', TipoFalhaIa.ocupado, false, true));
  });

  test('200 ilegível ou sem "texto" → outro, sem o corpo no detalhe', () async {
    w.respostas.add(_json(200, '<html>$_falaDoAluno</html>'));
    final f = await _falha(_turno(s));
    expect((f.codigo, f.tipo, f.caiParaGemini), ('resposta_ilegivel', TipoFalhaIa.outro, false));
    expect('$f', isNot(contains(_falaDoAluno)));
    w.respostas.add(_json(200, {'uso': {}}));
    expect((await _falha(_turno(s))).codigo, 'resposta_ilegivel');
  });

  test('nunca loga e nunca põe o texto do aluno numa falha', () async {
    final logs = <String>[];
    await runZoned(
      () async {
        await _turno(s);
        for (final r in [
          _erro(429, 'limite_pessoal', 'Você usou suas 60 falas de hoje. Volte amanhã!'),
          _erro(502, 'ia_falhou', 'A IA não conseguiu responder agora. Tente de novo.'),
          http.ClientException('Failed host lookup'),
        ]) {
          w.respostas.add(r);
          final f = await _falha(_turno(s));
          expect('$f', isNot(contains(_falaDoAluno)));
          expect(f.detalhe, isNot(contains(_falaDoAluno)));
        }
      },
      zoneSpecification: ZoneSpecification(print: (_, _, _, linha) => logs.add(linha)),
    );
    expect(logs, isEmpty);
  });

  test('perguntar / perguntarComo não são do Claude: fluxo com FalhaIa (outro)', () async {
    await expectLater(s.perguntar(contexto: '', historico: '', pergunta: 'x'),
        emitsError(isA<FalhaIa>().having((f) => f.tipo, 'tipo', TipoFalhaIa.outro)));
    await expectLater(s.perguntarComo(persona: 'p', contexto: '', historico: '', pergunta: 'x'),
        emitsError(isA<FalhaIa>().having((f) => f.tipo, 'tipo', TipoFalhaIa.outro)));
    expect(w.pedidos, isEmpty);
  });
}
