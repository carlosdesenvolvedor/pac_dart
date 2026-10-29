/**
 * Triagem Jev + LLM — proxy para os modelos. As chaves ficam só aqui (.dev.vars / secrets).
 *
 *   POST    /jev    → Jev (TypeSafe). Corpo no formato da Decisions API.
 *   POST    /llm    → LLM (Claude, GPT…). Corpo no formato chat/completions; a resposta volta
 *                     sempre nesse formato, seja qual for a empresa.
 *   OPTIONS /*      → preflight CORS
 *   GET     /saude  → {"ok":true}
 *
 * O app usa sempre os ids do OpenRouter (`typesafe/jev-1.14`, `anthropic/claude-haiku-5.5`…).
 * Para cada pedido, o Worker escolhe o caminho:
 *   0. `ollama/<modelo>` em /llm: o Ollama local (sem chave e sem custo; só com o Worker local);
 *   1. a chave da própria empresa, se existir — a digitada no painel do app (cabeçalho
 *      `x-chave-<empresa>`) ou a do .dev.vars (TYPESAFE_API_KEY, ANTHROPIC_API_KEY, OPENAI_API_KEY) —,
 *      trocando o id pelo da API dela (IDS_DIRETOS);
 *   2. senão, o OpenRouter (OPENROUTER_API_KEY), com o corpo repassado como veio.
 *
 * Feito para rodar LOCAL (`npm run dev`, http://localhost:8787) durante o protótipo. Se for
 * publicar, defina TOKEN_ACESSO e ORIGENS (veja o LEIA-ME) — senão qualquer um gasta seu crédito.
 */
import Anthropic from '@anthropic-ai/sdk';

import {
  IDS_DIRETOS,
  PREFIXO_LOCAL,
  TEMPO_LIMITE_LOCAL_MS,
  TEMPO_LIMITE_MS,
  URL_CHAT,
  URL_DECISOES,
  URL_OLLAMA,
  URL_OPENAI,
  URL_TYPESAFE,
} from './config';

const MAX_BYTES_CORPO = 64 * 1024;

/** Sem max_tokens no pedido, o Claude recebe este teto (o raciocínio também conta). */
const MAX_TOKENS_CLAUDE = 2000;

export interface Env {
  OPENROUTER_API_KEY?: string;
  TYPESAFE_API_KEY?: string;
  ANTHROPIC_API_KEY?: string;
  OPENAI_API_KEY?: string;
  /** Endereço do Ollama para os modelos `ollama/…` (padrão: URL_OLLAMA). */
  OLLAMA_URL?: string;
  /** Ids de modelo aceitos, separados por vírgula. Vazio = qualquer um. */
  MODELOS_PERMITIDOS?: string;
  /** Origens web extras aceitas (além de localhost), separadas por vírgula. */
  ORIGENS?: string;
  /** Se definido, o app precisa mandar `Authorization: Bearer <TOKEN_ACESSO>`. */
  TOKEN_ACESSO?: string;
}

type Empresa = 'typesafe' | 'anthropic' | 'openai';
const ROTAS: Record<string, { openRouter: string; empresas: Empresa[] }> = {
  '/jev': { openRouter: URL_DECISOES, empresas: ['typesafe'] },
  '/llm': { openRouter: URL_CHAT, empresas: ['anthropic', 'openai'] },
};
const CHAVES: Record<Empresa, keyof Env> = {
  typesafe: 'TYPESAFE_API_KEY',
  anthropic: 'ANTHROPIC_API_KEY',
  openai: 'OPENAI_API_KEY',
};
const EMPRESAS = Object.keys(CHAVES) as Empresa[];

/** Chave digitada no painel do app, que vem neste cabeçalho e vale mais que a do .dev.vars. */
const cabecalhoChave = (e: Empresa): string => `x-chave-${e}`;
const ORIGEM_LOCAL = /^http:\/\/(localhost|127\.0\.0\.1)(:\d{1,5})?$/;

function lista(v: string | undefined): string[] {
  return (v ?? '')
    .split(',')
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}

function origemPermitida(origem: string | null, env: Env): boolean {
  if (origem === null || origem === '') return true; // curl / app nativo
  return ORIGEM_LOCAL.test(origem) || lista(env.ORIGENS).includes(origem);
}

function cors(origem: string | null): Record<string, string> {
  if (!origem) return {};
  return {
    'Access-Control-Allow-Origin': origem,
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': `authorization, content-type, ${EMPRESAS.map(cabecalhoChave).join(', ')}`,
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

interface MensagemChat {
  role: string;
  content: string;
}
interface PedidoChat {
  model: string;
  messages?: MensagemChat[];
  max_tokens?: number;
}

/**
 * chat/completions → Messages API da Anthropic, pelo SDK oficial, e a resposta de volta no formato
 * chat/completions (o app lê `choices[0].message.content` e `usage.prompt_tokens/completion_tokens`).
 * Temperatura e top-p não são repassados: os Claude atuais recusam com 400.
 * Recusa por segurança vira erro 502: o estudo segue para o pesquisador, sem trocar de modelo
 * em silêncio (o log precisa dizer qual modelo respondeu).
 */
async function chamarAnthropic(pedido: PedidoChat, modelo: string, chave: string): Promise<Response> {
  const msgs = pedido.messages ?? [];
  const system = msgs
    .filter((m) => m.role === 'system')
    .map((m) => m.content)
    .join('\n\n');
  const client = new Anthropic({ apiKey: chave, timeout: TEMPO_LIMITE_MS, maxRetries: 1 });
  try {
    const r = await client.messages.create({
      model: modelo,
      max_tokens: Math.max(pedido.max_tokens ?? 0, MAX_TOKENS_CLAUDE),
      ...(system ? { system } : {}),
      messages: msgs
        .filter((m) => m.role === 'user' || m.role === 'assistant')
        .map((m) => ({ role: m.role as 'user' | 'assistant', content: m.content })),
    });
    if (r.stop_reason === 'refusal') {
      return json(502, { erro: `o modelo recusou (categoria: ${r.stop_details?.category ?? 'sem categoria'})` });
    }
    const texto = r.content.flatMap((b) => (b.type === 'text' ? [b.text] : [])).join('');
    if (!texto) return json(502, { erro: `resposta sem texto (stop_reason: ${r.stop_reason})` });
    return json(200, {
      id: r.id,
      model: r.model,
      choices: [{ index: 0, message: { role: 'assistant', content: texto }, finish_reason: r.stop_reason }],
      usage: { prompt_tokens: r.usage.input_tokens, completion_tokens: r.usage.output_tokens },
    });
  } catch (e) {
    if (e instanceof Anthropic.APIError) return json(e.status ?? 502, { erro: `Anthropic: ${e.message}` });
    return json(504, { erro: `Anthropic não respondeu: ${String(e)}` });
  }
}

/**
 * Na API direta da OpenAI, os modelos atuais (GPT-6…) recusam `max_tokens` e pedem
 * `max_completion_tokens` (conferido em 2026-10-29). O OpenRouter aceita os dois.
 */
function paraOpenAi(corpo: Record<string, unknown>, modelo: string): Record<string, unknown> {
  const { max_tokens: maxTokens, ...resto } = corpo;
  return {
    ...resto,
    model: modelo,
    ...(maxTokens !== undefined && resto.max_completion_tokens === undefined ? { max_completion_tokens: maxTokens } : {}),
  };
}

async function repassar(
  url: string,
  cabecalhos: Record<string, string>,
  corpo: string,
  limiteMs = TEMPO_LIMITE_MS,
): Promise<Response> {
  try {
    return await fetch(url, {
      method: 'POST',
      headers: { 'content-type': 'application/json', ...cabecalhos },
      body: corpo,
      signal: AbortSignal.timeout(limiteMs),
    });
  } catch (e) {
    return json(504, { erro: `${new URL(url).host} não respondeu: ${String(e)}` });
  }
}

export default {
  async fetch(req: Request, env: Env): Promise<Response> {
    const url = new URL(req.url);
    const origem = req.headers.get('Origin');
    if (!origemPermitida(origem, env)) return json(403, { erro: 'origem não permitida' });
    const h = cors(origem);

    if (req.method === 'OPTIONS') return new Response(null, { status: 204, headers: h });
    if (req.method === 'GET' && url.pathname === '/saude') return json(200, { ok: true }, h);

    const rota = ROTAS[url.pathname];
    if (rota === undefined) return json(404, { erro: 'rota desconhecida' }, h);
    if (req.method !== 'POST') return json(405, { erro: 'use POST' }, h);

    if (env.TOKEN_ACESSO && req.headers.get('Authorization') !== `Bearer ${env.TOKEN_ACESSO}`) {
      return json(401, { erro: 'token de acesso ausente ou errado' }, h);
    }

    const texto = await req.text();
    if (texto.length > MAX_BYTES_CORPO) return json(413, { erro: 'pedido grande demais' }, h);
    let corpo: { model?: unknown };
    try {
      corpo = JSON.parse(texto) as { model?: unknown };
    } catch {
      return json(400, { erro: 'JSON inválido' }, h);
    }
    const modelo = corpo.model;
    const permitidos = lista(env.MODELOS_PERMITIDOS);
    if (typeof modelo !== 'string' || (permitidos.length > 0 && !permitidos.includes(modelo))) {
      return json(400, { erro: `modelo não permitido: ${String(modelo)}` }, h);
    }

    // 1. Chave da própria empresa (o prefixo do id diz qual é): a do painel do app, senão a do .dev.vars.
    const empresa = rota.empresas.find((e) => modelo.startsWith(`${e}/`));
    const chaveDireta = empresa ? req.headers.get(cabecalhoChave(empresa))?.trim() || env[CHAVES[empresa]] : undefined;
    let resp: Response;
    if (url.pathname === '/llm' && modelo.startsWith(PREFIXO_LOCAL)) {
      // 0. Modelo local pelo Ollama (formato chat/completions; sem chave, sem custo). Só com o Worker local.
      resp = await repassar(
        `${env.OLLAMA_URL || URL_OLLAMA}/v1/chat/completions`,
        {},
        JSON.stringify({ ...corpo, model: modelo.slice(PREFIXO_LOCAL.length) }),
        TEMPO_LIMITE_LOCAL_MS,
      );
    } else if (empresa && chaveDireta) {
      const idDireto = IDS_DIRETOS[modelo];
      if (idDireto === undefined) return json(400, { erro: `sem id direto para ${modelo} (veja IDS_DIRETOS)` }, h);
      resp =
        empresa === 'anthropic'
          ? await chamarAnthropic(corpo as PedidoChat, idDireto, chaveDireta)
          : await repassar(
              empresa === 'typesafe' ? URL_TYPESAFE : URL_OPENAI,
              { Authorization: `Bearer ${chaveDireta}` },
              JSON.stringify(empresa === 'openai' ? paraOpenAi(corpo, idDireto) : { ...corpo, model: idDireto }),
            );
    } else if (env.OPENROUTER_API_KEY) {
      // 2. OpenRouter, com o corpo como veio.
      resp = await repassar(
        rota.openRouter,
        { Authorization: `Bearer ${env.OPENROUTER_API_KEY}`, 'X-Title': 'Prototipo triagem Jev' },
        texto,
      );
    } else {
      const falta = empresa
        ? `a chave no painel do app, ou ${CHAVES[empresa]} ou OPENROUTER_API_KEY no .dev.vars`
        : 'OPENROUTER_API_KEY no .dev.vars';
      return json(500, { erro: `nenhuma chave para ${modelo}: informe ${falta}` }, h);
    }
    // Repassa status e corpo como vieram: o app registra a resposta bruta no log.
    return new Response(resp.body, {
      status: resp.status,
      headers: { 'content-type': resp.headers.get('content-type') ?? 'application/json', ...h },
    });
  },
};
