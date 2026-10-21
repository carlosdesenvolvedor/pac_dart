import { beforeAll, describe, expect, it, vi } from 'vitest';
import {
  conferirClaims,
  criarObtentorDeChaves,
  decodificarJwt,
  ErroToken,
  FOLGA_SEGUNDOS,
  lerMaxAge,
  tokenDoCabecalho,
  URL_JWKS,
  verificarTokenFirebase,
} from '../src/jwt';
import { assinarToken, claimsValidas, gerarChaves, KID, PROJETO, type ParDeChaves } from './ajuda';

const AGORA = 1_792_000_000; // segundos

describe('conferirClaims', () => {
  const ok = claimsValidas(AGORA);

  it('aceita claims válidas', () => {
    expect(conferirClaims(ok, PROJETO, AGORA)).toBeNull();
  });

  it.each([
    ['aud', { aud: 'outro-projeto' }],
    ['iss', { iss: 'https://securetoken.google.com/outro' }],
    ['sub', { sub: '' }],
    ['sub', { sub: 42 }],
    ['sub', { sub: 'x'.repeat(129) }],
    ['exp', { exp: AGORA - FOLGA_SEGUNDOS - 1 }],
    ['exp', { exp: '9999999999' }],
    ['iat', { iat: AGORA + FOLGA_SEGUNDOS + 1 }],
    ['iat', { iat: undefined }],
    ['auth_time', { auth_time: AGORA + FOLGA_SEGUNDOS + 1 }],
  ])('recusa %s errado (%j)', (motivo, extra) => {
    expect(conferirClaims({ ...ok, ...extra }, PROJETO, AGORA)).toBe(motivo);
  });

  it('tolera a folga de relógio', () => {
    expect(conferirClaims({ ...ok, exp: AGORA - 30, iat: AGORA + 30 }, PROJETO, AGORA)).toBeNull();
  });

  it('usuário anônimo (só sub) é aceito', () => {
    const { auth_time: _a, ...semAuthTime } = ok;
    expect(conferirClaims({ ...semAuthTime, firebase: { sign_in_provider: 'anonymous' } }, PROJETO, AGORA)).toBeNull();
  });
});

describe('lerMaxAge / tokenDoCabecalho', () => {
  it('lê max-age do Cache-Control do Google', () => {
    expect(lerMaxAge('public, max-age=22029, must-revalidate, no-transform')).toBe(22029);
    expect(lerMaxAge('max-age=60')).toBe(60);
    expect(lerMaxAge('no-cache')).toBeNull();
    expect(lerMaxAge(null)).toBeNull();
    expect(lerMaxAge('s-max-age=10')).toBeNull();
  });

  it('extrai o Bearer', () => {
    expect(tokenDoCabecalho('Bearer abc.def.ghi')).toBe('abc.def.ghi');
    expect(tokenDoCabecalho('bearer abc')).toBe('abc');
    expect(tokenDoCabecalho('Basic abc')).toBeNull();
    expect(tokenDoCabecalho('Bearer')).toBeNull();
    expect(tokenDoCabecalho(null)).toBeNull();
  });
});

describe('verificarTokenFirebase (RSA gerada localmente)', () => {
  let chaves: ParDeChaves;
  let outra: ParDeChaves;
  const obter = async (kid: string) => (kid === KID ? chaves.publica : null);

  beforeAll(async () => {
    chaves = await gerarChaves();
    outra = await gerarChaves();
  });

  it('aceita um token bem assinado e devolve o uid', async () => {
    const token = await assinarToken(chaves.privada, claimsValidas(AGORA, { name: 'Ana Conceição' }));
    expect(await verificarTokenFirebase(token, PROJETO, obter, AGORA)).toEqual({ uid: 'aluno-123' });
  });

  it('recusa assinatura de outra chave', async () => {
    const token = await assinarToken(outra.privada, claimsValidas(AGORA));
    await expect(verificarTokenFirebase(token, PROJETO, obter, AGORA)).rejects.toThrow('assinatura');
  });

  it('recusa payload adulterado', async () => {
    const token = await assinarToken(chaves.privada, claimsValidas(AGORA));
    const [c, , a] = token.split('.');
    const falso = btoa(JSON.stringify(claimsValidas(AGORA, { sub: 'outro-aluno' })))
      .replace(/\+/g, '-')
      .replace(/\//g, '_')
      .replace(/=+$/, '');
    await expect(verificarTokenFirebase(`${c}.${falso}.${a}`, PROJETO, obter, AGORA)).rejects.toThrow('assinatura');
  });

  it('recusa alg diferente de RS256 (inclusive "none")', async () => {
    const t1 = await assinarToken(chaves.privada, claimsValidas(AGORA), { alg: 'none', kid: KID });
    const t2 = await assinarToken(chaves.privada, claimsValidas(AGORA), { alg: 'HS256', kid: KID });
    await expect(verificarTokenFirebase(t1, PROJETO, obter, AGORA)).rejects.toThrow('alg');
    await expect(verificarTokenFirebase(t2, PROJETO, obter, AGORA)).rejects.toThrow('alg');
  });

  it('recusa kid desconhecido ou ausente', async () => {
    const t1 = await assinarToken(chaves.privada, claimsValidas(AGORA), { alg: 'RS256', kid: 'outro' });
    const t2 = await assinarToken(chaves.privada, claimsValidas(AGORA), { alg: 'RS256' });
    await expect(verificarTokenFirebase(t1, PROJETO, obter, AGORA)).rejects.toThrow('kid');
    await expect(verificarTokenFirebase(t2, PROJETO, obter, AGORA)).rejects.toThrow('kid');
  });

  it('recusa token expirado mesmo bem assinado', async () => {
    const token = await assinarToken(chaves.privada, claimsValidas(AGORA, { exp: AGORA - 3600 }));
    await expect(verificarTokenFirebase(token, PROJETO, obter, AGORA)).rejects.toThrow('exp');
  });

  it('recusa lixo', async () => {
    await expect(verificarTokenFirebase('abc', PROJETO, obter, AGORA)).rejects.toBeInstanceOf(ErroToken);
    await expect(verificarTokenFirebase('a.b.c', PROJETO, obter, AGORA)).rejects.toBeInstanceOf(ErroToken);
    expect(() => decodificarJwt('a+b.c.d')).toThrow(ErroToken);
  });

  describe('cache das chaves do Google', () => {
    function respostaJwks(jwks: object[], cacheControl = 'public, max-age=100') {
      return new Response(JSON.stringify({ keys: jwks }), { headers: { 'cache-control': cacheControl } });
    }

    it('busca uma vez, respeita max-age e verifica com a chave importada', async () => {
      let relogio = 1_000_000;
      const buscar = vi.fn(async (url: string) => {
        expect(url).toBe(URL_JWKS);
        return respostaJwks([chaves.jwkPublica]);
      });
      const obterChave = criarObtentorDeChaves(buscar, () => relogio);
      const token = await assinarToken(chaves.privada, claimsValidas(AGORA));

      expect(await verificarTokenFirebase(token, PROJETO, obterChave, AGORA)).toEqual({ uid: 'aluno-123' });
      await verificarTokenFirebase(token, PROJETO, obterChave, AGORA);
      expect(buscar).toHaveBeenCalledTimes(1);

      relogio += 101_000; // passou o max-age=100
      await verificarTokenFirebase(token, PROJETO, obterChave, AGORA);
      expect(buscar).toHaveBeenCalledTimes(2);
    });

    it('kid novo (rotação) força nova busca, mas no máximo 1 por minuto', async () => {
      let relogio = 5_000_000;
      const antiga = { ...outra.jwkPublica, kid: 'kid-antigo' };
      let lista = [antiga];
      const buscar = vi.fn(async () => respostaJwks(lista, 'max-age=20000'));
      const obterChave = criarObtentorDeChaves(buscar, () => relogio);

      expect(await obterChave('kid-antigo')).not.toBeNull();
      expect(buscar).toHaveBeenCalledTimes(1);
      expect(await obterChave(KID)).toBeNull(); // ainda dentro do minuto: não rebusca
      expect(buscar).toHaveBeenCalledTimes(1);

      lista = [antiga, chaves.jwkPublica];
      relogio += 61_000;
      expect(await obterChave(KID)).not.toBeNull();
      expect(buscar).toHaveBeenCalledTimes(2);
    });

    it('pedidos simultâneos compartilham a mesma busca', async () => {
      const buscar = vi.fn(async () => respostaJwks([chaves.jwkPublica]));
      const obterChave = criarObtentorDeChaves(buscar, () => 1);
      await Promise.all([obterChave(KID), obterChave(KID), obterChave(KID)]);
      expect(buscar).toHaveBeenCalledTimes(1);
    });

    it('erro do Google vira exceção (não ErroToken)', async () => {
      const obterChave = criarObtentorDeChaves(async () => new Response('x', { status: 500 }), () => 1);
      const token = await assinarToken(chaves.privada, claimsValidas(AGORA));
      const erro = await verificarTokenFirebase(token, PROJETO, obterChave, AGORA).catch((e) => e);
      expect(erro).toBeInstanceOf(Error);
      expect(erro).not.toBeInstanceOf(ErroToken);
    });
  });
});
