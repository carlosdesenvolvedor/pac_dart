/**
 * Paclingo — proxy da "Conversa com IA" para a API de Mensagens da Anthropic.
 *
 *   POST    /v1/turno  → um turno da conversa (exige ID token do Firebase)
 *   OPTIONS /v1/turno  → preflight CORS
 *   GET     /saude     → {"ok":true}
 *
 * A chave da Anthropic fica só aqui (segredo ANTHROPIC_API_KEY); o modelo é fixado pela variável
 * MODELO — o app não escolhe.
 */

import { montarCorpoAnthropic, extrairResposta, MODELO_PADRAO, URL_ANTHROPIC, VERSAO_ANTHROPIC } from './anthropic';
import { cabecalhosCors, cabecalhosPreflight, decidirOrigem, type DecisaoOrigem } from './cors';
import { criarObtentorDeChaves, ErroToken, tokenDoCabecalho, verificarTokenFirebase } from './jwt';
import {
  avaliarLimites,
  chaveDia,
  lerContagem,
  lerLimite,
  LIMITE_GERAL_PADRAO,
  LIMITE_PESSOAL_PADRAO,
  registrarTurno,
  restantesHoje,
  segundosAteMeiaNoiteUtc,
  type Contagem,
} from './limites';
import { validarPedido } from './pedido';

export const PROJETO_FIREBASE = 'pac-dart';
export const TEMPO_LIMITE_MS = 25_000;
const MAX_BYTES_CORPO = 64 * 1024;

export interface Env {
  ANTHROPIC_API_KEY?: string;
  MODELO?: string;
  LIMITE_PESSOAL?: string;
  LIMITE_GERAL?: string;
  LIMITES?: KVNamespace;
}

export type CodigoErro =
  | 'pedido_invalido'
  | 'nao_autenticado'
  | 'origem_negada'
  | 'limite_pessoal'
  | 'limite_geral'
  | 'ia_falhou'
  | 'ia_demorou'
  | 'sem_chave'
  | 'nao_encontrado';

/** Escopo do módulo: o cache das chaves do Google sobrevive entre pedidos no mesmo isolate. */
const obterChave = criarObtentorDeChaves();
let avisouSemKv = false;

function log(dados: Record<string, unknown>): void {
  console.log(JSON.stringify(dados));
}

function json(corpo: unknown, status: number, cors: DecisaoOrigem, extra: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(corpo), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8', 'cache-control': 'no-store', ...cabecalhosCors(cors), ...extra },
  });
}

function erro(
  codigo: CodigoErro,
  mensagem: string,
  status: number,
  cors: DecisaoOrigem,
  extra: Record<string, string> = {},
): Response {
  return json({ erro: codigo, mensagem }, status, cors, extra);
}

export default {
  async fetch(req: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const url = new URL(req.url);
    const cors = decidirOrigem(req.headers.get('origin'));
    if (cors.tipo === 'negada') {
      return erro('origem_negada', 'Este site não pode usar a conversa com IA.', 403, cors);
    }

    if (url.pathname === '/saude' && req.method === 'GET') return json({ ok: true }, 200, cors);
    if (url.pathname === '/v1/turno' && req.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cabecalhosPreflight(cors) });
    }
    if (url.pathname === '/v1/turno' && req.method === 'POST') return turno(req, env, ctx, cors);

    return erro('nao_encontrado', 'Endereço não encontrado.', 404, cors);
  },
} satisfies ExportedHandler<Env>;

async function turno(req: Request, env: Env, ctx: ExecutionContext, cors: DecisaoOrigem): Promise<Response> {
  // 1) Quem é o aluno?
  const token = tokenDoCabecalho(req.headers.get('authorization'));
  if (!token) return erro('nao_autenticado', 'Entre na sua conta para conversar com a IA.', 401, cors);
  let uid: string;
  try {
    uid = (await verificarTokenFirebase(token, PROJETO_FIREBASE, obterChave)).uid;
  } catch (e) {
    if (!(e instanceof ErroToken)) log({ evento: 'jwks_falhou', erro: String(e).slice(0, 200) });
    return erro('nao_autenticado', 'Sua sessão expirou. Entre de novo para conversar com a IA.', 401, cors);
  }

  // 2) Servidor configurado?
  const chave = env.ANTHROPIC_API_KEY?.trim();
  if (!chave) {
    log({ evento: 'sem_chave' });
    return erro('sem_chave', 'A conversa com IA ainda não foi configurada no servidor.', 503, cors);
  }

  // 3) Pedido válido?
  const texto = await req.text();
  if (new TextEncoder().encode(texto).length > MAX_BYTES_CORPO) {
    return erro('pedido_invalido', 'O pedido é grande demais.', 400, cors);
  }
  let corpo: unknown;
  try {
    corpo = JSON.parse(texto);
  } catch {
    return erro('pedido_invalido', 'O corpo do pedido não é um JSON válido.', 400, cors);
  }
  const validacao = validarPedido(corpo);
  if (!validacao.ok) return erro('pedido_invalido', validacao.mensagem, 400, cors);
  const pedido = validacao.pedido;

  // 4) Limites do dia
  const agora = new Date();
  const dia = chaveDia(agora);
  const limitePessoal = lerLimite(env.LIMITE_PESSOAL, LIMITE_PESSOAL_PADRAO);
  const limiteGeral = lerLimite(env.LIMITE_GERAL, LIMITE_GERAL_PADRAO);
  let contagem: Contagem = { pessoal: 0, geral: 0 };
  const kv = env.LIMITES;
  if (!kv) {
    if (!avisouSemKv) log({ evento: 'aviso', mensagem: 'KV LIMITES ausente: rodando SEM limites diários' });
    avisouSemKv = true;
  } else {
    try {
      contagem = await lerContagem(kv, uid, dia);
    } catch (e) {
      log({ evento: 'kv_leitura_falhou', erro: String(e).slice(0, 200) });
    }
    const veredito = avaliarLimites(contagem, limitePessoal, limiteGeral);
    if (!veredito.ok) {
      const retry = { 'Retry-After': String(segundosAteMeiaNoiteUtc(agora)) };
      return veredito.tipo === 'pessoal'
        ? erro('limite_pessoal', `Você usou suas ${limitePessoal} falas de hoje. Volte amanhã!`, 429, cors, retry)
        : erro('limite_geral', 'A conversa com IA atingiu o limite de hoje. Tente amanhã.', 429, cors, retry);
    }
  }

  // 5) Chama a Anthropic
  const modelo = env.MODELO?.trim() || MODELO_PADRAO;
  const controle = new AbortController();
  const relogio = setTimeout(() => controle.abort(), TEMPO_LIMITE_MS);
  let resp: Response;
  let dados: unknown;
  try {
    resp = await fetch(URL_ANTHROPIC, {
      method: 'POST',
      headers: { 'x-api-key': chave, 'anthropic-version': VERSAO_ANTHROPIC, 'content-type': 'application/json' },
      body: JSON.stringify(montarCorpoAnthropic(pedido, modelo)),
      signal: controle.signal,
    });
    if (!resp.ok) {
      const bruto = await resp.text().catch(() => '');
      log({ evento: 'anthropic_erro', status: resp.status, corpo: bruto.slice(0, 200) });
      if (resp.status === 429) {
        const retryUp = resp.headers.get('retry-after');
        return erro(
          'limite_geral',
          'A IA está muito ocupada agora. Tente de novo em instantes.',
          429,
          cors,
          retryUp && /^\d+$/.test(retryUp.trim()) ? { 'Retry-After': retryUp.trim() } : {},
        );
      }
      return erro('ia_falhou', 'A IA não conseguiu responder agora. Tente de novo.', 502, cors);
    }
    dados = await resp.json();
  } catch (e) {
    if (controle.signal.aborted) {
      log({ evento: 'anthropic_timeout' });
      return erro('ia_demorou', 'A IA demorou demais para responder. Tente de novo.', 504, cors);
    }
    log({ evento: 'anthropic_rede', erro: String(e).slice(0, 200) });
    return erro('ia_falhou', 'A IA não conseguiu responder agora. Tente de novo.', 502, cors);
  } finally {
    clearTimeout(relogio);
  }

  // 6) Lê a resposta
  const extracao = extrairResposta(dados, pedido.esquema !== undefined);
  if (!extracao.ok) {
    const r = dados as Record<string, unknown> | null;
    log({ evento: 'anthropic_resposta_inutil', motivo: extracao.motivo, stop_reason: String(r?.stop_reason ?? '').slice(0, 40) });
    return extracao.motivo === 'recusa'
      ? erro('ia_falhou', 'A IA não quis responder a essa fala. Tente dizer de outro jeito.', 502, cors)
      : erro('ia_falhou', 'A IA não conseguiu responder agora. Tente de novo.', 502, cors);
  }

  // 7) Conta o turno (só os que deram certo) sem atrasar a resposta
  if (kv) ctx.waitUntil(registrarTurno(kv, uid, dia));

  return json(
    {
      texto: extracao.texto,
      uso: extracao.uso,
      restantesHoje: kv ? restantesHoje(contagem, limitePessoal) : limitePessoal,
    },
    200,
    cors,
  );
}
