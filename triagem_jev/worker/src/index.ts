/**
 * Triagem Jev + LLM — proxy para o OpenRouter. A chave fica só aqui (segredo OPENROUTER_API_KEY).
 *
 *   POST    /jev    → Decisions API do OpenRouter (Jev). Corpo repassado como veio.
 *   POST    /llm    → chat/completions do OpenRouter (Claude, GPT…). Corpo repassado como veio.
 *   OPTIONS /*      → preflight CORS
 *   GET     /saude  → {"ok":true}
 *
 * Feito para rodar LOCAL (`npm run dev`, http://localhost:8787) durante o protótipo. Se for
 * publicar, defina TOKEN_ACESSO e ORIGENS (veja o LEIA-ME) — senão qualquer um gasta seu crédito.
 */

/**
 * Conferido em 2026-10-29: https://openrouter.ai/docs/guides/community/jev e a referência da Decisions
 * API (o servidor dessa rota é https://openrouter.ai, não https://openrouter.ai/api/v1).
 */
export const URL_DECISOES = 'https://openrouter.ai/api/alpha/decisions';
export const URL_CHAT = 'https://openrouter.ai/api/v1/chat/completions';
export const TEMPO_LIMITE_MS = 30_000;
const MAX_BYTES_CORPO = 64 * 1024;

export interface Env {
  OPENROUTER_API_KEY?: string;
  /** Ids de modelo aceitos, separados por vírgula. Vazio = qualquer um. */
  MODELOS_PERMITIDOS?: string;
  /** Origens web extras aceitas (além de localhost), separadas por vírgula. */
  ORIGENS?: string;
  /** Se definido, o app precisa mandar `Authorization: Bearer <TOKEN_ACESSO>`. */
  TOKEN_ACESSO?: string;
}

const ROTAS: Record<string, string> = { '/jev': URL_DECISOES, '/llm': URL_CHAT };
const ORIGEM_LOCAL = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;

function lista(v: string | undefined): string[] {
  return (v ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

export function origemPermitida(origem: string | null, env: Env): boolean {
  if (origem === null || origem === '') return true; // curl / app nativo
  return ORIGEM_LOCAL.test(origem) || lista(env.ORIGENS).includes(origem);
}

function cors(origem: string | null): Record<string, string> {
  if (!origem) return {};
  return {
    'Access-Control-Allow-Origin': origem,
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'authorization, content-type',
    'Access-Control-Max-Age': '86400',
    Vary: 'Origin',
  };
}

function json(status: number, corpo: unknown, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', ...extra },
  });
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const origem = req.headers.get('Origin');
    if (!origemPermitida(origem, env)) return json(403, { erro: 'origem não permitida' });
    const h = cors(origem);

    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: h });
    if (req.method === 'GET' && url.pathname === '/saude') return json(200, { ok: true }, h);

    const destino = ROTAS[url.pathname];
    if (destino === undefined) return json(404, { erro: 'rota desconhecida' }, h);
    if (req.method !== 'POST') return json(405, { erro: 'use POST' }, h);

    if (env.TOKEN_ACESSO && req.headers.get('Authorization') !== `Bearer ${env.TOKEN_ACESSO}`) {
      return json(401, { erro: 'token de acesso ausente ou errado' }, h);
    }
    if (!env.OPENROUTER_API_KEY) return json(500, { erro: 'segredo OPENROUTER_API_KEY não configurado' }, h);

    const texto = await req.text();
    if (texto.length > MAX_BYTES_CORPO) return json(413, { erro: 'pedido grande demais' }, h);
    let corpo: { model?: unknown };
    try {
      corpo = JSON.parse(texto) as { model?: unknown };
    } catch {
      return json(400, { erro: 'JSON inválido' }, h);
    }
    const permitidos = lista(env.MODELOS_PERMITIDOS);
    if (typeof corpo.model !== 'string' || (permitidos.length > 0 && !permitidos.includes(corpo.model))) {
      return json(400, { erro: `modelo não permitido: ${String(corpo.model)}` }, h);
    }

    let resp: Response;
    try {
      resp = await fetch(destino, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.OPENROUTER_API_KEY}`,
          'content-type': 'application/json',
          'X-Title': 'Prototipo triagem Jev',
        },
        body: texto,
        signal: AbortSignal.timeout(TEMPO_LIMITE_MS),
      });
    } catch (e) {
      return json(504, { erro: `OpenRouter não respondeu: ${String(e)}` }, h);
    }
    // Repassa status e corpo como vieram: o app registra a resposta bruta no log.
    return new Response(resp.body, {
      status: resp.status,
      headers: { 'content-type': resp.headers.get('content-type') ?? 'application/json', ...h },
    });
  },
};
