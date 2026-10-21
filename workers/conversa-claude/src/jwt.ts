/**
 * Verificação do ID token do Firebase Auth (RS256) só com WebCrypto.
 * Regras: https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
 */

export const URL_JWKS =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

/** Folga de relógio aceita em `exp`/`iat`/`auth_time` (segundos). */
export const FOLGA_SEGUNDOS = 60;

/** Se a chave pedida não está no cache, rebusca no máximo uma vez a cada X ms (rotação de chaves). */
const INTERVALO_MIN_REBUSCA_MS = 60_000;
const MAX_AGE_PADRAO_S = 3600;

export interface CabecalhoJwt {
  alg?: unknown;
  kid?: unknown;
  typ?: unknown;
}

export interface ClaimsFirebase {
  aud?: unknown;
  iss?: unknown;
  sub?: unknown;
  exp?: unknown;
  iat?: unknown;
  auth_time?: unknown;
  [k: string]: unknown;
}

export interface JwtDecodificado {
  cabecalho: CabecalhoJwt;
  claims: ClaimsFirebase;
  assinado: Uint8Array; // bytes de "<cabecalho>.<payload>"
  assinatura: Uint8Array;
}

export class ErroToken extends Error {}

export function base64UrlParaBytes(s: string): Uint8Array {
  if (!/^[A-Za-z0-9_-]*$/.test(s)) throw new ErroToken('base64url inválido');
  const b64 = s.replace(/-/g, '+').replace(/_/g, '/') + '='.repeat((4 - (s.length % 4)) % 4);
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function jsonDeBase64Url(s: string): unknown {
  return JSON.parse(new TextDecoder().decode(base64UrlParaBytes(s)));
}

export function decodificarJwt(token: string): JwtDecodificado {
  const partes = token.split('.');
  if (partes.length !== 3) throw new ErroToken('formato de JWT inválido');
  const [c, p, a] = partes as [string, string, string];
  let cabecalho: unknown;
  let claims: unknown;
  try {
    cabecalho = jsonDeBase64Url(c);
    claims = jsonDeBase64Url(p);
  } catch {
    throw new ErroToken('JWT ilegível');
  }
  if (typeof cabecalho !== 'object' || cabecalho === null || typeof claims !== 'object' || claims === null) {
    throw new ErroToken('JWT ilegível');
  }
  return {
    cabecalho: cabecalho as CabecalhoJwt,
    claims: claims as ClaimsFirebase,
    assinado: new TextEncoder().encode(`${c}.${p}`),
    assinatura: base64UrlParaBytes(a),
  };
}

/** Confere as claims; devolve o motivo da recusa ou `null` se estiver tudo certo. */
export function conferirClaims(claims: ClaimsFirebase, projeto: string, agoraS: number): string | null {
  if (claims.aud !== projeto) return 'aud';
  if (claims.iss !== `https://securetoken.google.com/${projeto}`) return 'iss';
  if (typeof claims.sub !== 'string' || claims.sub === '' || claims.sub.length > 128) return 'sub';
  if (typeof claims.exp !== 'number' || claims.exp <= agoraS - FOLGA_SEGUNDOS) return 'exp';
  if (typeof claims.iat !== 'number' || claims.iat > agoraS + FOLGA_SEGUNDOS) return 'iat';
  if (claims.auth_time !== undefined && (typeof claims.auth_time !== 'number' || claims.auth_time > agoraS + FOLGA_SEGUNDOS)) {
    return 'auth_time';
  }
  return null;
}

/** `max-age` do Cache-Control, em segundos (ou `null`). */
export function lerMaxAge(cacheControl: string | null): number | null {
  if (!cacheControl) return null;
  const m = /(?:^|[,\s])max-age=(\d+)/i.exec(cacheControl);
  return m ? Number(m[1]) : null;
}

export type ObterChave = (kid: string) => Promise<CryptoKey | null>;

const ALGORITMO = { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' };

/**
 * Cache das chaves públicas do Google. Fica no escopo do módulo (dura enquanto o isolate do Worker
 * estiver vivo) e respeita o `max-age` do Cache-Control da resposta.
 */
export function criarObtentorDeChaves(
  buscar: (url: string) => Promise<Response> = (url) => fetch(url),
  relogioMs: () => number = Date.now,
): ObterChave {
  let chaves = new Map<string, CryptoKey>();
  let expiraEm = 0;
  let buscadoEm = -Infinity;
  let emAndamento: Promise<void> | null = null;

  async function atualizar(): Promise<void> {
    const resp = await buscar(URL_JWKS);
    if (!resp.ok) throw new Error(`JWKS respondeu ${resp.status}`);
    const corpo = (await resp.json()) as { keys?: Array<JsonWebKey & { kid?: string }> };
    const novas = new Map<string, CryptoKey>();
    for (const jwk of corpo.keys ?? []) {
      if (typeof jwk.kid !== 'string' || jwk.kty !== 'RSA') continue;
      const { kid, ...resto } = jwk;
      novas.set(kid, await crypto.subtle.importKey('jwk', resto as JsonWebKey, ALGORITMO, false, ['verify']));
    }
    const agora = relogioMs();
    chaves = novas;
    buscadoEm = agora;
    expiraEm = agora + (lerMaxAge(resp.headers.get('cache-control')) ?? MAX_AGE_PADRAO_S) * 1000;
  }

  async function atualizarUmaVez(): Promise<void> {
    emAndamento ??= atualizar().finally(() => {
      emAndamento = null;
    });
    return emAndamento;
  }

  return async (kid: string) => {
    const agora = relogioMs();
    if (agora >= expiraEm) {
      await atualizarUmaVez();
    } else if (!chaves.has(kid) && agora - buscadoEm >= INTERVALO_MIN_REBUSCA_MS) {
      await atualizarUmaVez();
    }
    return chaves.get(kid) ?? null;
  };
}

export interface UsuarioVerificado {
  uid: string;
}

/** Verifica assinatura + claims. Lança `ErroToken` se o token não servir. */
export async function verificarTokenFirebase(
  token: string,
  projeto: string,
  obterChave: ObterChave,
  agoraS: number = Math.floor(Date.now() / 1000),
): Promise<UsuarioVerificado> {
  const jwt = decodificarJwt(token);
  if (jwt.cabecalho.alg !== 'RS256') throw new ErroToken('alg');
  if (typeof jwt.cabecalho.kid !== 'string' || jwt.cabecalho.kid === '') throw new ErroToken('kid');

  const motivo = conferirClaims(jwt.claims, projeto, agoraS);
  if (motivo) throw new ErroToken(motivo);

  const chave = await obterChave(jwt.cabecalho.kid);
  if (!chave) throw new ErroToken('kid desconhecido');

  const valido = await crypto.subtle.verify(ALGORITMO, chave, jwt.assinatura, jwt.assinado);
  if (!valido) throw new ErroToken('assinatura');

  return { uid: jwt.claims.sub as string };
}

/** Extrai o token de `Authorization: Bearer <token>`. */
export function tokenDoCabecalho(authorization: string | null): string | null {
  if (!authorization) return null;
  const m = /^Bearer\s+(\S+)\s*$/i.exec(authorization);
  return m ? m[1]! : null;
}
