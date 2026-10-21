/**
 * Limites diários (UTC) guardados no Workers KV.
 *
 * Atenção: o KV é eventualmente consistente (uma escrita pode levar até ~60 s para aparecer em
 * outras regiões, e leituras são cacheadas na borda). Pedidos simultâneos podem, portanto, passar
 * um pouco do limite. Para este uso (proteger o orçamento, não cobrar centavos) isso é aceitável;
 * o teto de gasto mensal no Console da Anthropic é a proteção final.
 */

export const TTL_SEGUNDOS = 2 * 24 * 60 * 60;
export const LIMITE_PESSOAL_PADRAO = 60;
export const LIMITE_GERAL_PADRAO = 3000;

export interface KvMinimo {
  get(chave: string): Promise<string | null>;
  put(chave: string, valor: string, opcoes?: { expirationTtl?: number }): Promise<void>;
}

/** "YYYY-MM-DD" em UTC. */
export function chaveDia(data: Date): string {
  return data.toISOString().slice(0, 10);
}

export function chaveUsuario(uid: string, dia: string): string {
  return `u:${uid}:${dia}`;
}

export function chaveGeral(dia: string): string {
  return `g:${dia}`;
}

/** Segundos até a próxima meia-noite UTC (mínimo 1) — vai no `Retry-After`. */
export function segundosAteMeiaNoiteUtc(agora: Date): number {
  const proxima = Date.UTC(agora.getUTCFullYear(), agora.getUTCMonth(), agora.getUTCDate() + 1);
  return Math.max(1, Math.ceil((proxima - agora.getTime()) / 1000));
}

/** Lê um limite das variáveis do wrangler.toml (texto ou número); inválido → padrão. */
export function lerLimite(valor: unknown, padrao: number): number {
  const n = typeof valor === 'number' ? valor : typeof valor === 'string' ? Number(valor.trim()) : NaN;
  return Number.isFinite(n) && n >= 0 ? Math.floor(n) : padrao;
}

function paraNumero(v: string | null): number {
  const n = v === null ? 0 : Number(v);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 0;
}

export interface Contagem {
  pessoal: number;
  geral: number;
}

export async function lerContagem(kv: KvMinimo, uid: string, dia: string): Promise<Contagem> {
  const [p, g] = await Promise.all([kv.get(chaveUsuario(uid, dia)), kv.get(chaveGeral(dia))]);
  return { pessoal: paraNumero(p), geral: paraNumero(g) };
}

export type Veredito = { ok: true } | { ok: false; tipo: 'pessoal' | 'geral' };

export function avaliarLimites(c: Contagem, limitePessoal: number, limiteGeral: number): Veredito {
  if (c.pessoal >= limitePessoal) return { ok: false, tipo: 'pessoal' };
  if (c.geral >= limiteGeral) return { ok: false, tipo: 'geral' };
  return { ok: true };
}

/** Quantos turnos o aluno ainda tem hoje depois deste (que acabou de dar certo). */
export function restantesHoje(c: Contagem, limitePessoal: number): number {
  return Math.max(0, limitePessoal - (c.pessoal + 1));
}

/**
 * Soma 1 nos dois contadores. Relê antes de escrever (o turno levou alguns segundos) para perder
 * menos incrementos concorrentes. Falhas de escrita (ex.: limite de escritas do plano grátis, ou
 * mais de 1 escrita/s na mesma chave) só vão para o log — nunca derrubam a resposta do aluno.
 */
export async function registrarTurno(kv: KvMinimo, uid: string, dia: string): Promise<void> {
  const escrever = async (chave: string) => {
    try {
      const atual = paraNumero(await kv.get(chave));
      await kv.put(chave, String(atual + 1), { expirationTtl: TTL_SEGUNDOS });
    } catch (e) {
      console.log(JSON.stringify({ evento: 'kv_falhou', chave: chave.slice(0, 2), erro: String(e).slice(0, 200) }));
    }
  };
  await Promise.all([escrever(chaveUsuario(uid, dia)), escrever(chaveGeral(dia))]);
}
