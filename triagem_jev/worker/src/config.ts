/**
 * Endereços, tempo limite e ids dos modelos. Ficam fora do index.ts porque o runtime da
 * Cloudflare trata cada export nomeado do módulo principal como ponto de entrada e recusa
 * constantes ("Incorrect type for map entry").
 */

/**
 * Conferido em 2026-10-29: https://openrouter.ai/docs/guides/community/jev e a referência da Decisions
 * API (o servidor dessa rota é https://openrouter.ai, não https://openrouter.ai/api/v1).
 */
export const URL_DECISOES = 'https://openrouter.ai/api/alpha/decisions';
export const URL_CHAT = 'https://openrouter.ai/api/v1/chat/completions';
/** Mesmo formato de pedido e resposta da Decisions API (https://docs.typesafe.ai/api.md). */
export const URL_TYPESAFE = 'https://api.typesafe.ai/v1/systemone';
export const URL_OPENAI = 'https://api.openai.com/v1/chat/completions';
export const TEMPO_LIMITE_MS = 30_000;

/**
 * Modelos locais: id `ollama/<modelo do Ollama>` (ex.: `ollama/qwen2.5:7b`), servidos pelo Ollama na
 * própria máquina no formato chat/completions. A primeira chamada carrega o modelo na memória e
 * pode levar dezenas de segundos, por isso o limite maior.
 */
export const PREFIXO_LOCAL = 'ollama/';
export const URL_OLLAMA = 'http://localhost:11434';
export const TEMPO_LIMITE_LOCAL_MS = 180_000;

/** Id do OpenRouter → id na API da própria empresa (conferidos em 2026-10-29). */
export const IDS_DIRETOS: Record<string, string> = {
  'typesafe/jev-1.14': 'jev-1.14.0',
  'typesafe/jev-1.13': 'jev-1.13.0',
  'anthropic/claude-haiku-5.5': 'claude-haiku-5-5',
  'anthropic/claude-sonnet-5.5': 'claude-sonnet-5-5',
  'openai/gpt-6-luna': 'gpt-6-luna',
};
