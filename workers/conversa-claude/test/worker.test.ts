/** O Worker inteiro, com `fetch` falso (Google JWKS + Anthropic) e KV em memória. */

import { afterEach, beforeAll, beforeEach, describe, expect, it, vi } from 'vitest';
import worker, { type Env } from '../src/index';
import { URL_ANTHROPIC } from '../src/anthropic';
import { chaveDia } from '../src/limites';
import { URL_JWKS } from '../src/jwt';
import { assinarToken, claimsValidas, gerarChaves, KvFalso, type ParDeChaves } from './ajuda';

const ORIGEM = 'https://pac-dart.web.app';
const BASE = 'https://paclingo-conversa.exemplo.workers.dev';

let chaves: ParDeChaves;
let token: string;
let kv: KvFalso;
let esperas: Promise<unknown>[];
let respostaAnthropic: () => Promise<Response>;
let pedidosAnthropic: Array<{ headers: Headers; corpo: Record<string, unknown> }>;

const ctx = () =>
  ({ waitUntil: (p: Promise<unknown>) => esperas.push(p), passThroughOnException: () => {}, props: {} }) as unknown as ExecutionContext;

function env(extra: Partial<Env> = {}): Env {
  return {
    ANTHROPIC_API_KEY: 'chave-de-teste',
    MODELO: 'claude-haiku-5-5',
    LIMITE_PESSOAL: '60',
    LIMITE_GERAL: '3000',
    LIMITES: kv as unknown as KVNamespace,
    ...extra,
  };
}

function turno(corpo: unknown, headers: Record<string, string> = {}): Request {
  return new Request(`${BASE}/v1/turno`, {
    method: 'POST',
    headers: { origin: ORIGEM, authorization: `Bearer ${token}`, 'content-type': 'application/json', ...headers },
    body: typeof corpo === 'string' ? corpo : JSON.stringify(corpo),
  });
}

const corpoValido = {
  system: 'Você é o garçom.',
  mensagens: [{ papel: 'aluno', texto: 'A table for two, please.' }],
  esquema: { type: 'OBJECT', properties: { fala: { type: 'STRING' } }, required: ['fala'] },
  maxTokens: 400,
};

function okAnthropic(): Response {
  return Response.json({
    stop_reason: 'tool_use',
    content: [{ type: 'tool_use', id: 't', name: 'responder', input: { fala: 'Right this way!' } }],
    usage: { input_tokens: 321, output_tokens: 45 },
  });
}

beforeAll(async () => {
  chaves = await gerarChaves();
  token = await assinarToken(chaves.privada, claimsValidas(Math.floor(Date.now() / 1000)));
});

beforeEach(() => {
  kv = new KvFalso();
  esperas = [];
  pedidosAnthropic = [];
  respostaAnthropic = async () => okAnthropic();
  vi.stubGlobal(
    'fetch',
    vi.fn(async (entrada: RequestInfo | URL, init?: RequestInit) => {
      const url = String(entrada instanceof Request ? entrada.url : entrada);
      if (url === URL_JWKS) {
        return Response.json({ keys: [chaves.jwkPublica] }, { headers: { 'cache-control': 'max-age=3600' } });
      }
      if (url === URL_ANTHROPIC) {
        pedidosAnthropic.push({ headers: new Headers(init?.headers), corpo: JSON.parse(String(init?.body)) });
        if (init?.signal) {
          const sinal = init.signal;
          return Promise.race([
            respostaAnthropic(),
            new Promise<Response>((_, rej) => sinal.addEventListener('abort', () => rej(new DOMException('abort', 'AbortError')))),
          ]);
        }
        return respostaAnthropic();
      }
      throw new Error(`fetch inesperado: ${url}`);
    }),
  );
  vi.spyOn(console, 'log').mockImplementation(() => {});
});

afterEach(() => {
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
  vi.useRealTimers();
});

async function corpoJson(r: Response): Promise<Record<string, unknown>> {
  return (await r.json()) as Record<string, unknown>;
}

describe('rotas', () => {
  it('GET /saude', async () => {
    const r = await worker.fetch(new Request(`${BASE}/saude`), env(), ctx());
    expect(r.status).toBe(200);
    expect(await r.json()).toEqual({ ok: true });
  });

  it('qualquer outra coisa → 404', async () => {
    for (const [metodo, caminho] of [['GET', '/v1/turno'], ['POST', '/'], ['GET', '/v1/turnos']] as const) {
      const r = await worker.fetch(new Request(`${BASE}${caminho}`, { method: metodo }), env(), ctx());
      expect(r.status).toBe(404);
    }
  });

  it('preflight de origem permitida', async () => {
    const r = await worker.fetch(
      new Request(`${BASE}/v1/turno`, { method: 'OPTIONS', headers: { origin: 'http://localhost:7357' } }),
      env(),
      ctx(),
    );
    expect(r.status).toBe(204);
    expect(r.headers.get('access-control-allow-origin')).toBe('http://localhost:7357');
    expect(r.headers.get('access-control-allow-headers')).toBe('authorization, content-type');
  });

  it('origem negada → 403', async () => {
    const r = await worker.fetch(turno(corpoValido, { origin: 'https://golpe.example' }), env(), ctx());
    expect(r.status).toBe(403);
    expect((await corpoJson(r)).erro).toBe('origem_negada');
  });
});

describe('POST /v1/turno', () => {
  it('turno com esquema: 200, contrato do app e pedido certo para a Anthropic', async () => {
    const r = await worker.fetch(turno(corpoValido), env(), ctx());
    expect(r.status).toBe(200);
    expect(r.headers.get('access-control-allow-origin')).toBe(ORIGEM);
    expect(await r.json()).toEqual({
      texto: '{"fala":"Right this way!"}',
      uso: { entrada: 321, saida: 45 },
      restantesHoje: 59,
    });

    const [p] = pedidosAnthropic;
    expect(p!.headers.get('x-api-key')).toBe('chave-de-teste');
    expect(p!.headers.get('anthropic-version')).toBe('2023-06-01');
    expect(p!.corpo).toMatchObject({
      model: 'claude-haiku-5-5',
      max_tokens: 400,
      tool_choice: { type: 'tool', name: 'responder' },
      tools: [{ name: 'responder', input_schema: { type: 'object', properties: { fala: { type: 'string' } } } }],
    });

    await Promise.all(esperas);
    const dia = chaveDia(new Date());
    expect(kv.dados.get(`u:aluno-123:${dia}`)).toBe('1');
    expect(kv.dados.get(`g:${dia}`)).toBe('1');
  });

  it('o app não escolhe o modelo', async () => {
    await worker.fetch(turno({ ...corpoValido, modelo: 'claude-opus-5-5', model: 'claude-opus-5-5' }), env(), ctx());
    expect(pedidosAnthropic[0]!.corpo.model).toBe('claude-haiku-5-5');
  });

  it('app nativo (sem Origin) funciona, sem cabeçalhos CORS', async () => {
    const req = turno(corpoValido);
    const semOrigem = new Request(req, { headers: { authorization: `Bearer ${token}` } });
    const r = await worker.fetch(semOrigem, env(), ctx());
    expect(r.status).toBe(200);
    expect(r.headers.get('access-control-allow-origin')).toBeNull();
  });

  it('sem token / token ruim → 401', async () => {
    for (const auth of ['', 'Bearer abc.def.ghi', 'Basic xyz']) {
      const r = await worker.fetch(turno(corpoValido, { authorization: auth }), env(), ctx());
      expect(r.status).toBe(401);
      expect((await corpoJson(r)).erro).toBe('nao_autenticado');
    }
    expect(pedidosAnthropic).toHaveLength(0);
  });

  it('sem a chave da Anthropic → 503 sem_chave', async () => {
    const r = await worker.fetch(turno(corpoValido), env({ ANTHROPIC_API_KEY: undefined }), ctx());
    expect(r.status).toBe(503);
    expect((await corpoJson(r)).erro).toBe('sem_chave');
  });

  it('corpo inválido → 400 pedido_invalido', async () => {
    for (const corpo of ['{nao é json', { system: 'x', mensagens: [{ papel: 'ia', texto: 'oi' }] }]) {
      const r = await worker.fetch(turno(corpo), env(), ctx());
      expect(r.status).toBe(400);
      const j = await corpoJson(r);
      expect(j.erro).toBe('pedido_invalido');
      expect(typeof j.mensagem).toBe('string');
    }
  });

  it('limite pessoal → 429 com Retry-After até a meia-noite UTC', async () => {
    kv.dados.set(`u:aluno-123:${chaveDia(new Date())}`, '60');
    const r = await worker.fetch(turno(corpoValido), env(), ctx());
    expect(r.status).toBe(429);
    expect((await corpoJson(r)).erro).toBe('limite_pessoal');
    const retry = Number(r.headers.get('retry-after'));
    expect(retry).toBeGreaterThan(0);
    expect(retry).toBeLessThanOrEqual(86400);
    expect(r.headers.get('access-control-expose-headers')).toContain('Retry-After');
    expect(pedidosAnthropic).toHaveLength(0);
  });

  it('limite geral → 429 limite_geral', async () => {
    kv.dados.set(`g:${chaveDia(new Date())}`, '5');
    const r = await worker.fetch(turno(corpoValido), env({ LIMITE_GERAL: '5' }), ctx());
    expect(r.status).toBe(429);
    expect((await corpoJson(r)).erro).toBe('limite_geral');
  });

  it('sem KV: funciona sem limites', async () => {
    const r = await worker.fetch(turno(corpoValido), env({ LIMITES: undefined }), ctx());
    expect(r.status).toBe(200);
    expect((await corpoJson(r)).restantesHoje).toBe(60);
  });

  it('Anthropic 429 → 429 limite_geral com Retry-After de lá', async () => {
    respostaAnthropic = async () =>
      new Response('{"type":"error","error":{"type":"rate_limit_error"}}', { status: 429, headers: { 'retry-after': '30' } });
    const r = await worker.fetch(turno(corpoValido), env(), ctx());
    expect(r.status).toBe(429);
    expect(r.headers.get('retry-after')).toBe('30');
    expect((await corpoJson(r)).erro).toBe('limite_geral');
  });

  it('Anthropic sobrecarregada (529) → 502 ia_falhou, sem repassar o corpo e sem contar o turno', async () => {
    respostaAnthropic = async () => new Response('{"error":{"type":"overloaded_error","message":"segredo"}}', { status: 529 });
    const r = await worker.fetch(turno(corpoValido), env(), ctx());
    expect(r.status).toBe(502);
    const texto = await r.text();
    expect(JSON.parse(texto).erro).toBe('ia_falhou');
    expect(texto).not.toContain('overloaded');
    await Promise.all(esperas);
    expect(kv.dados.size).toBe(0);
  });

  it('resposta sem a ferramenta → 502 ia_falhou', async () => {
    respostaAnthropic = async () =>
      Response.json({ stop_reason: 'end_turn', content: [{ type: 'text', text: 'Hmm' }], usage: {} });
    const r = await worker.fetch(turno(corpoValido), env(), ctx());
    expect(r.status).toBe(502);
  });

  it('demorou mais de 25 s → 504 ia_demorou', async () => {
    vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout'] });
    respostaAnthropic = () => new Promise<Response>(() => {}); // nunca responde
    const promessa = worker.fetch(turno(corpoValido), env(), ctx());
    let r: Response | undefined;
    promessa.then((x) => (r = x));
    for (let i = 0; i < 200 && !r; i++) {
      await new Promise((ok) => setImmediate(ok));
      await vi.advanceTimersByTimeAsync(500);
    }
    expect(r?.status).toBe(504);
    expect((await corpoJson(r!)).erro).toBe('ia_demorou');
  });
});
