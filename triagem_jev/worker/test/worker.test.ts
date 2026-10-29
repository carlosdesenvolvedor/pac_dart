import { afterEach, describe, expect, it, vi } from 'vitest';

import { URL_CHAT, URL_DECISOES, URL_OPENAI, URL_TYPESAFE } from '../src/config';
import worker, { type Env } from '../src/index';

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

describe('worker com as chaves de cada empresa', () => {
  const diretas: Env = {
    TYPESAFE_API_KEY: 'ts-teste',
    ANTHROPIC_API_KEY: 'sk-ant-teste',
    OPENAI_API_KEY: 'sk-oa-teste',
    OPENROUTER_API_KEY: 'sk-or-teste', // existe, mas a chave direta tem prioridade
  };

  function chamada(f: ReturnType<typeof vi.fn>): { url: string; corpo: Record<string, unknown>; cabecalhos: Headers } {
    const [url, init] = f.mock.calls[0] as unknown as [string | URL | Request, RequestInit];
    return {
      url: String(url instanceof Request ? url.url : url),
      corpo: JSON.parse(String(init.body)) as Record<string, unknown>,
      cabecalhos: new Headers(init.headers),
    };
  }

  it('/jev vai para a TypeSafe com o id dela', async () => {
    const f = vi.fn(async () => new Response('{"answers":{}}', { status: 200 }));
    vi.stubGlobal('fetch', f);
    const r = await worker.fetch(post('/jev', { model: 'typesafe/jev-1.14', state: 'x', questions: {} }), diretas);
    expect(r.status).toBe(200);
    const c = chamada(f);
    expect(c.url).toBe(URL_TYPESAFE);
    expect(c.corpo.model).toBe('jev-1.14.0');
    expect(c.cabecalhos.get('authorization')).toBe('Bearer ts-teste');
  });

  it('/llm com GPT vai para a OpenAI com o id dela', async () => {
    const f = vi.fn(async () => new Response('{"choices":[]}', { status: 200 }));
    vi.stubGlobal('fetch', f);
    await worker.fetch(post('/llm', { model: 'openai/gpt-6-luna', messages: [], max_tokens: 2000 }), diretas);
    const c = chamada(f);
    expect(c.url).toBe(URL_OPENAI);
    // A API direta da OpenAI recusa max_tokens nos modelos atuais.
    expect(c.corpo).toMatchObject({ model: 'gpt-6-luna', max_completion_tokens: 2000 });
    expect(c.corpo).not.toHaveProperty('max_tokens');
    expect(c.cabecalhos.get('authorization')).toBe('Bearer sk-oa-teste');
  });

  it('/llm com Claude usa a Messages API e devolve no formato chat/completions', async () => {
    const f = vi.fn(
      async () =>
        new Response(
          JSON.stringify({
            id: 'msg_1',
            type: 'message',
            role: 'assistant',
            model: 'claude-haiku-5-5',
            content: [
              { type: 'thinking', thinking: '', signature: 's' },
              { type: 'text', text: '{"decisao_sugerida":"incluir"}' },
            ],
            stop_reason: 'end_turn',
            stop_details: null,
            usage: { input_tokens: 300, output_tokens: 40 },
          }),
          { status: 200, headers: { 'content-type': 'application/json' } },
        ),
    );
    vi.stubGlobal('fetch', f);
    const r = await worker.fetch(
      post('/llm', {
        model: 'anthropic/claude-haiku-5.5',
        max_tokens: 300,
        messages: [
          { role: 'system', content: 'Você faz triagem.' },
          { role: 'user', content: 'Estudo E1' },
        ],
      }),
      diretas,
    );
    expect(r.status).toBe(200);
    expect(await r.json()).toMatchObject({
      choices: [{ message: { content: '{"decisao_sugerida":"incluir"}' } }],
      usage: { prompt_tokens: 300, completion_tokens: 40 },
    });
    const c = chamada(f);
    expect(c.url).toBe('https://api.anthropic.com/v1/messages');
    // O SDK 1.x manda a chave como Bearer.
    expect(c.cabecalhos.get('authorization')).toBe('Bearer sk-ant-teste');
    expect(c.corpo).toMatchObject({
      model: 'claude-haiku-5-5',
      system: 'Você faz triagem.',
      messages: [{ role: 'user', content: 'Estudo E1' }],
    });
    // O teto sobe para caber o raciocínio; temperatura nunca vai para o Claude.
    expect(c.corpo.max_tokens).toBe(2000);
    expect(c.corpo).not.toHaveProperty('temperature');
  });

  it('recusa do Claude vira erro, sem trocar de modelo', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(
        async () =>
          new Response(
            JSON.stringify({
              id: 'msg_2',
              type: 'message',
              role: 'assistant',
              model: 'claude-haiku-5-5',
              content: [],
              stop_reason: 'refusal',
              stop_details: { type: 'refusal', category: null, explanation: null },
              usage: { input_tokens: 10, output_tokens: 0 },
            }),
            { status: 200, headers: { 'content-type': 'application/json' } },
          ),
      ),
    );
    const r = await worker.fetch(post('/llm', { model: 'anthropic/claude-haiku-5.5', messages: [] }), diretas);
    expect(r.status).toBe(502);
  });

  it('chave do painel (cabeçalho) vale mais que a do .dev.vars, e funciona sem ela', async () => {
    const f = vi.fn(async () => new Response('{"choices":[]}', { status: 200 }));
    vi.stubGlobal('fetch', f);
    const pedido = () =>
      post('/llm', { model: 'openai/gpt-6-luna', messages: [] }, { 'x-chave-openai': ' sk-do-painel ' });
    await worker.fetch(pedido(), diretas);
    expect(chamada(f).cabecalhos.get('authorization')).toBe('Bearer sk-do-painel');
    f.mockClear();
    await worker.fetch(pedido(), {});
    expect(chamada(f).url).toBe(URL_OPENAI);
  });

  it('o preflight libera os cabeçalhos das chaves', async () => {
    const r = await worker.fetch(
      new Request('http://w/llm', { method: 'OPTIONS', headers: { Origin: 'http://localhost:5000' } }),
      diretas,
    );
    expect(r.headers.get('Access-Control-Allow-Headers')).toContain('x-chave-anthropic');
    expect(r.headers.get('Access-Control-Allow-Headers')).toContain('x-chave-openai');
  });

  it('sem chave direta, cai no OpenRouter', async () => {
    const f = vi.fn(async () => new Response('{}', { status: 200 }));
    vi.stubGlobal('fetch', f);
    await worker.fetch(post('/llm', { model: 'openai/gpt-6-luna', messages: [] }), { OPENROUTER_API_KEY: 'sk-or' });
    expect(chamada(f).url).toBe(URL_CHAT);
  });
});
