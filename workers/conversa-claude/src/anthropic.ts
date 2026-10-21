/** Montagem do pedido para a API de Mensagens da Anthropic e leitura da resposta. */

import { mapearMensagens, type MensagemAnthropic, type PedidoTurno } from './pedido';

export const URL_ANTHROPIC = 'https://api.anthropic.com/v1/messages';
export const VERSAO_ANTHROPIC = '2023-06-01';
export const MODELO_PADRAO = 'claude-haiku-5-5';
export const NOME_FERRAMENTA = 'responder';
export const TEMPERATURA = 0.5;

/**
 * O que cada família de modelo aceita. Os modelos novos recusam (400) `temperature` diferente do
 * padrão, alguns recusam `tool_choice` forçado e alguns pensam por padrão — o que gastaria o
 * `max_tokens` curto de um turno de conversa.
 */
export interface PerfilModelo {
  /** Manda `temperature: 0.5` (só modelos antigos aceitam). */
  temperatura: boolean;
  /** `tool_choice: {type:'tool'}`; senão `auto` + instrução no system. */
  forcarFerramenta: boolean;
  /** Manda `thinking: {type:'disabled'}` (modelos que pensam por padrão mas aceitam desligar). */
  desligarPensamento: boolean;
  /** Manda `output_config.effort = 'low'` (modelos em que o pensamento não desliga). */
  esforcoBaixo: boolean;
}

export function perfilDoModelo(modelo: string): PerfilModelo {
  const m = modelo.trim().toLowerCase();
  // Opus 5.5 / Sonnet 5.5 / Fable / Mythos: pensamento não desliga e tool_choice forçado dá 400.
  if (/^claude-(opus-5-5|sonnet-5-5|fable-|mythos-)/.test(m)) {
    return { temperatura: false, forcarFerramenta: false, desligarPensamento: false, esforcoBaixo: true };
  }
  // Haiku 5.5 / Opus 5 / Sonnet 5: pensam por padrão, aceitam desligar; sem temperature.
  if (/^claude-(haiku-5-5|opus-5|sonnet-5)$/.test(m)) {
    return { temperatura: false, forcarFerramenta: true, desligarPensamento: true, esforcoBaixo: false };
  }
  // Opus 4.7 / 4.8: sem pensamento por padrão, sem temperature.
  if (/^claude-opus-4-[78]/.test(m)) {
    return { temperatura: false, forcarFerramenta: true, desligarPensamento: false, esforcoBaixo: false };
  }
  // Família 3.x e 4.x até 4.6: aceitam tudo.
  if (/^claude-(3|haiku-4|sonnet-4|opus-4)/.test(m)) {
    return { temperatura: true, forcarFerramenta: true, desligarPensamento: false, esforcoBaixo: false };
  }
  // Desconhecido (provavelmente mais novo): o mínimo que todos aceitam.
  return { temperatura: false, forcarFerramenta: false, desligarPensamento: false, esforcoBaixo: false };
}

const INSTRUCAO_FERRAMENTA =
  `\n\nResponda SEMPRE chamando a ferramenta "${NOME_FERRAMENTA}" exatamente uma vez, sem texto fora dela.`;

export interface CorpoAnthropic {
  model: string;
  max_tokens: number;
  messages: MensagemAnthropic[];
  system?: string;
  temperature?: number;
  thinking?: { type: 'disabled' };
  output_config?: { effort: 'low' };
  tools?: Array<{ name: string; description: string; input_schema: Record<string, unknown> }>;
  tool_choice?: { type: 'tool'; name: string } | { type: 'auto' };
}

export function montarCorpoAnthropic(pedido: PedidoTurno, modelo: string): CorpoAnthropic {
  const perfil = perfilDoModelo(modelo);
  const corpo: CorpoAnthropic = {
    model: modelo,
    max_tokens: pedido.maxTokens,
    messages: mapearMensagens(pedido.mensagens),
  };
  let system = pedido.system;
  if (pedido.esquema) {
    corpo.tools = [{ name: NOME_FERRAMENTA, description: 'Responde ao turno da conversa', input_schema: pedido.esquema }];
    if (perfil.forcarFerramenta) {
      corpo.tool_choice = { type: 'tool', name: NOME_FERRAMENTA };
    } else {
      corpo.tool_choice = { type: 'auto' };
      system += INSTRUCAO_FERRAMENTA;
    }
  }
  if (system.trim() !== '') corpo.system = system;
  if (perfil.temperatura) corpo.temperature = TEMPERATURA;
  if (perfil.desligarPensamento) corpo.thinking = { type: 'disabled' };
  if (perfil.esforcoBaixo) corpo.output_config = { effort: 'low' };
  return corpo;
}

export interface Uso {
  entrada: number;
  saida: number;
}

export type Extracao =
  | { ok: true; texto: string; uso: Uso }
  | { ok: false; motivo: 'recusa' | 'sem_ferramenta' | 'vazia' | 'formato' };

interface BlocoResposta {
  type?: unknown;
  text?: unknown;
  name?: unknown;
  input?: unknown;
}

function lerUso(json: Record<string, unknown>): Uso {
  const u = (typeof json.usage === 'object' && json.usage !== null ? json.usage : {}) as Record<string, unknown>;
  const n = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
  return {
    entrada: n(u.input_tokens) + n(u.cache_read_input_tokens) + n(u.cache_creation_input_tokens),
    saida: n(u.output_tokens),
  };
}

/** Tira cercas ```json ... ``` e tenta ler um objeto JSON do texto. */
export function objetoJsonDoTexto(texto: string): Record<string, unknown> | null {
  let t = texto.trim();
  const cerca = /^```(?:json)?\s*([\s\S]*?)\s*```$/i.exec(t);
  if (cerca) t = cerca[1]!;
  if (!t.startsWith('{')) {
    const i = t.indexOf('{');
    const f = t.lastIndexOf('}');
    if (i < 0 || f <= i) return null;
    t = t.slice(i, f + 1);
  }
  try {
    const v = JSON.parse(t);
    return typeof v === 'object' && v !== null && !Array.isArray(v) ? (v as Record<string, unknown>) : null;
  } catch {
    return null;
  }
}

/**
 * Resposta da Anthropic → texto para o app.
 * Com esquema: o `input` do tool_use "responder" serializado como JSON (se o modelo respondeu em
 * texto, tenta ler um JSON desse texto). Sem esquema: os blocos de texto concatenados.
 */
export function extrairResposta(json: unknown, comEsquema: boolean): Extracao {
  if (typeof json !== 'object' || json === null) return { ok: false, motivo: 'formato' };
  const r = json as Record<string, unknown>;
  if (r.stop_reason === 'refusal') return { ok: false, motivo: 'recusa' };
  if (!Array.isArray(r.content)) return { ok: false, motivo: 'formato' };
  const blocos = r.content as BlocoResposta[];
  const textos = blocos
    .filter((b) => b && b.type === 'text' && typeof b.text === 'string')
    .map((b) => b.text as string);
  const uso = lerUso(r);

  if (comEsquema) {
    const ferramenta = blocos.find((b) => b && b.type === 'tool_use' && b.name === NOME_FERRAMENTA);
    if (ferramenta && typeof ferramenta.input === 'object' && ferramenta.input !== null) {
      return { ok: true, texto: JSON.stringify(ferramenta.input), uso };
    }
    const doTexto = objetoJsonDoTexto(textos.join(''));
    return doTexto ? { ok: true, texto: JSON.stringify(doTexto), uso } : { ok: false, motivo: 'sem_ferramenta' };
  }

  const texto = textos.join('').trim();
  return texto === '' ? { ok: false, motivo: 'vazia' } : { ok: true, texto, uso };
}
