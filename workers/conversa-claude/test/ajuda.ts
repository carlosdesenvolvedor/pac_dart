/** Utilidades de teste: chave RSA local, tokens assinados e um KV em memória. */

import type { KvMinimo } from '../src/limites';

export const PROJETO = 'pac-dart';
export const KID = 'kid-teste';

export interface ParDeChaves {
  privada: CryptoKey;
  publica: CryptoKey;
  jwkPublica: JsonWebKey & { kid: string };
}

export async function gerarChaves(kid = KID): Promise<ParDeChaves> {
  const par = (await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  )) as CryptoKeyPair;
  const jwk = (await crypto.subtle.exportKey('jwk', par.publicKey)) as JsonWebKey;
  return { privada: par.privateKey, publica: par.publicKey, jwkPublica: { ...jwk, kid, alg: 'RS256', use: 'sig' } };
}

function base64Url(bytes: Uint8Array): string {
  let bin = '';
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

function textoBase64Url(s: string): string {
  return base64Url(new TextEncoder().encode(s));
}

export function claimsValidas(agoraS: number, extra: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    aud: PROJETO,
    iss: `https://securetoken.google.com/${PROJETO}`,
    sub: 'aluno-123',
    iat: agoraS - 10,
    exp: agoraS + 3600,
    auth_time: agoraS - 100,
    ...extra,
  };
}

export async function assinarToken(
  privada: CryptoKey,
  claims: Record<string, unknown>,
  cabecalho: Record<string, unknown> = { alg: 'RS256', kid: KID, typ: 'JWT' },
): Promise<string> {
  const entrada = `${textoBase64Url(JSON.stringify(cabecalho))}.${textoBase64Url(JSON.stringify(claims))}`;
  const assinatura = new Uint8Array(
    await crypto.subtle.sign({ name: 'RSASSA-PKCS1-v1_5' }, privada, new TextEncoder().encode(entrada)),
  );
  return `${entrada}.${base64Url(assinatura)}`;
}

export class KvFalso implements KvMinimo {
  dados = new Map<string, string>();
  ttls = new Map<string, number | undefined>();
  falharPut = false;

  async get(chave: string): Promise<string | null> {
    return this.dados.get(chave) ?? null;
  }

  async put(chave: string, valor: string, opcoes?: { expirationTtl?: number }): Promise<void> {
    if (this.falharPut) throw new Error('KV put limit exceeded');
    this.dados.set(chave, valor);
    this.ttls.set(chave, opcoes?.expirationTtl);
  }
}
