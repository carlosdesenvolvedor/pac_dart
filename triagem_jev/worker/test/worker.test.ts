import { afterEach, describe, expect, it, vi } from 'vitest';

import worker, { URL_CHAT, URL_DECISOES, type Env } from '../src/index';

const env: Env = { OPENROUTER_API_KEY: 'sk-teste', MODELOS_PERMITIDOS: 'typesafe/jev-1.14,anthropic/claude-haiku-5.5' };

function post(caminho: string, corpo: unknown, cabecalhos: Record<string, string> = {}): Request {
  return new Request(`http://w${caminho}`, {
    method: 'POST',
    headers: { 'content-type': 'application/json', ...cabecalhos },
    body: typeof corpo === 'string' ? corpo : JSON.stringify(corpo),
  });
}

afterEach(() => vi.unstubAllGlobals());

describe('worker', () => {
  it('repassa /jev para a Decisions API com a chave do servidor', async () => {
    const f = vi.fn(async () => new Response('{"decisions":[]}', { status: 200 }));
    vi.stubGlobal('fetch', f);
    const r = await worker.fetch(post('/jev', { model: 'typesafe/jev-1.14', state: 'x' }), env);
    expect(r.status).toBe(200);
    const [url, init] = f.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toBe(URL_DECISOES);
    expect((init.headers as Record<string, string>).Authorization).toBe('Bearer sk-teste');
  });

  it('repassa /llm para chat/completions e devolve o status de erro como veio', async () => {
    const f = vi.fn(async () => new Response('{"error":"sem crédito"}', { status: 402 }));
    vi.stubGlobal('fetch', f);
    const r = await worker.fetch(post('/llm', { model: 'anthropic/claude-haiku-5.5', messages: [] }), env);
    expect(r.status).toBe(402);
    expect((f.mock.calls[0] as unknown as [string])[0]).toBe(URL_CHAT);
  });

  it('recusa modelo fora da lista, JSON inválido e rota desconhecida', async () => {
    vi.stubGlobal('fetch', vi.fn());
    expect((await worker.fetch(post('/llm', { model: 'caro/modelo' }), env)).status).toBe(400);
    expect((await worker.fetch(post('/llm', '{nada'), env)).status).toBe(400);
    expect((await worker.fetch(post('/outra', {}), env)).status).toBe(404);
  });

  it('origem: localhost passa (com CORS), site estranho não', async () => {
    const ok = await worker.fetch(new Request('http://w/saude', { headers: { Origin: 'http://localhost:5000' } }), env);
    expect(ok.headers.get('Access-Control-Allow-Origin')).toBe('http://localhost:5000');
    const nao = await worker.fetch(new Request('http://w/saude', { headers: { Origin: 'https://mal.example' } }), env);
    expect(nao.status).toBe(403);
  });

  it('com TOKEN_ACESSO, exige o Bearer', async () => {
    vi.stubGlobal('fetch', vi.fn(async () => new Response('{}')));
    const e = { ...env, TOKEN_ACESSO: 'abc' };
    expect((await worker.fetch(post('/jev', { model: 'typesafe/jev-1.14' }), e)).status).toBe(401);
    expect((await worker.fetch(post('/jev', { model: 'typesafe/jev-1.14' }, { Authorization: 'Bearer abc' }), e)).status).toBe(200);
  });

  it('sem a chave configurada, avisa', async () => {
    const r = await worker.fetch(post('/jev', { model: 'typesafe/jev-1.14' }), {});
    expect(r.status).toBe(500);
  });
});
