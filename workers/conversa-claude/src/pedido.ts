/** Validação do corpo do POST /v1/turno e conversão para o formato da Anthropic. */

export const MAX_CARACTERES = 16_000;
export const MAX_MENSAGENS = 24;
export const MAX_CARACTERES_ESQUEMA = 8_000;
export const MAX_TOKENS_MIN = 64;
export const MAX_TOKENS_MAX = 800;
export const MAX_TOKENS_PADRAO = 600;

export type Papel = 'aluno' | 'ia';

export interface MensagemApp {
  papel: Papel;
  texto: string;
}

export interface PedidoTurno {
  system: string;
  mensagens: MensagemApp[];
  esquema?: Record<string, unknown>;
  maxTokens: number;
}

export interface MensagemAnthropic {
  role: 'user' | 'assistant';
  content: string;
}

export type ResultadoValidacao = { ok: true; pedido: PedidoTurno } | { ok: false; mensagem: string };

/** Abertura sintética quando a conversa começa por uma fala da IA (a API quer `user` primeiro). */
export const ABERTURA_SINTETICA = '[A conversa começa.]';

function ehObjeto(v: unknown): v is Record<string, unknown> {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

function falha(mensagem: string): ResultadoValidacao {
  return { ok: false, mensagem };
}

export function limitarMaxTokens(v: number): number {
  return Math.min(MAX_TOKENS_MAX, Math.max(MAX_TOKENS_MIN, Math.round(v)));
}

/**
 * Aceita o esquema no formato JSON Schema (minúsculo) e também no formato do Gemini que o app já
 * usa (`type: 'OBJECT'`, `propertyOrdering`): os tipos viram minúsculos e `propertyOrdering` sai.
 */
export function normalizarEsquema(no: unknown): unknown {
  if (Array.isArray(no)) return no.map(normalizarEsquema);
  if (!ehObjeto(no)) return no;
  const saida: Record<string, unknown> = {};
  for (const [chave, valor] of Object.entries(no)) {
    switch (chave) {
      case 'propertyOrdering':
        break;
      case 'type':
        saida.type = typeof valor === 'string'
          ? valor.toLowerCase()
          : Array.isArray(valor)
            ? valor.map((t) => (typeof t === 'string' ? t.toLowerCase() : t))
            : valor;
        break;
      case 'properties':
      case '$defs':
      case 'definitions':
        // Mapa nome → esquema: as chaves são nomes de campo, não palavras-chave.
        saida[chave] = ehObjeto(valor)
          ? Object.fromEntries(Object.entries(valor).map(([k, v]) => [k, normalizarEsquema(v)]))
          : valor;
        break;
      case 'items':
      case 'additionalProperties':
      case 'anyOf':
      case 'oneOf':
      case 'allOf':
      case 'not':
        saida[chave] = normalizarEsquema(valor);
        break;
      default:
        saida[chave] = valor;
    }
  }
  return saida;
}

export function validarPedido(corpo: unknown): ResultadoValidacao {
  if (!ehObjeto(corpo)) return falha('O corpo precisa ser um objeto JSON.');

  const { system, mensagens, esquema, maxTokens } = corpo;
  if (typeof system !== 'string') return falha('O campo "system" precisa ser texto.');
  if (!Array.isArray(mensagens) || mensagens.length === 0) {
    return falha('O campo "mensagens" precisa ser uma lista com pelo menos uma fala.');
  }
  if (mensagens.length > MAX_MENSAGENS) {
    return falha(`A conversa passou de ${MAX_MENSAGENS} falas. Comece uma conversa nova.`);
  }

  const lista: MensagemApp[] = [];
  let total = system.length;
  for (const m of mensagens) {
    if (!ehObjeto(m) || (m.papel !== 'aluno' && m.papel !== 'ia') || typeof m.texto !== 'string') {
      return falha('Cada fala precisa de "papel" ("aluno" ou "ia") e "texto".');
    }
    if (m.texto.trim() === '') return falha('Há uma fala vazia na conversa.');
    total += m.texto.length;
    lista.push({ papel: m.papel, texto: m.texto });
  }
  if (total > MAX_CARACTERES) {
    return falha(`A conversa passou de ${MAX_CARACTERES} caracteres. Comece uma conversa nova.`);
  }
  if (lista[lista.length - 1]!.papel !== 'aluno') {
    return falha('A última fala precisa ser do aluno.');
  }

  let esquemaFinal: Record<string, unknown> | undefined;
  if (esquema !== undefined && esquema !== null) {
    if (!ehObjeto(esquema)) return falha('O campo "esquema" precisa ser um objeto (JSON Schema).');
    if (JSON.stringify(esquema).length > MAX_CARACTERES_ESQUEMA) return falha('O esquema é grande demais.');
    const normalizado = normalizarEsquema(esquema) as Record<string, unknown>;
    if (normalizado.type !== 'object') return falha('O esquema precisa ter "type": "object" na raiz.');
    esquemaFinal = normalizado;
  }

  let max = MAX_TOKENS_PADRAO;
  if (maxTokens !== undefined && maxTokens !== null) {
    if (typeof maxTokens !== 'number' || !Number.isFinite(maxTokens)) {
      return falha('O campo "maxTokens" precisa ser um número.');
    }
    max = limitarMaxTokens(maxTokens);
  }

  return {
    ok: true,
    pedido: { system, mensagens: lista, maxTokens: max, ...(esquemaFinal ? { esquema: esquemaFinal } : {}) },
  };
}

/** aluno → user, ia → assistant; falas seguidas do mesmo papel viram uma só (separadas por linha em branco). */
export function mapearMensagens(mensagens: MensagemApp[]): MensagemAnthropic[] {
  const saida: MensagemAnthropic[] = [];
  for (const m of mensagens) {
    const role = m.papel === 'aluno' ? 'user' : 'assistant';
    const anterior = saida[saida.length - 1];
    if (anterior && anterior.role === role) {
      anterior.content = `${anterior.content}\n\n${m.texto}`;
    } else {
      saida.push({ role, content: m.texto });
    }
  }
  if (saida[0]?.role === 'assistant') saida.unshift({ role: 'user', content: ABERTURA_SINTETICA });
  return saida;
}
