import { describe, expect, it } from 'vitest';
import {
  avaliarLimites,
  chaveDia,
  chaveGeral,
  chaveUsuario,
  lerContagem,
  lerLimite,
  registrarTurno,
  restantesHoje,
  segundosAteMeiaNoiteUtc,
  TTL_SEGUNDOS,
} from '../src/limites';
import { KvFalso } from './ajuda';

describe('chaves por dia (UTC)', () => {
  it('usa a data UTC, não a local', () => {
    // 23:30 de 20/out em São Paulo (UTC-3) já é 21/out em UTC
    expect(chaveDia(new Date('2026-10-21T02:30:00Z'))).toBe('2026-10-21');
    expect(chaveDia(new Date('2026-10-20T23:59:59.999Z'))).toBe('2026-10-20');
  });

  it('formato das chaves', () => {
    expect(chaveUsuario('abc', '2026-10-21')).toBe('u:abc:2026-10-21');
    expect(chaveGeral('2026-10-21')).toBe('g:2026-10-21');
  });

  it('segundos até a meia-noite UTC', () => {
    expect(segundosAteMeiaNoiteUtc(new Date('2026-10-21T23:00:00Z'))).toBe(3600);
    expect(segundosAteMeiaNoiteUtc(new Date('2026-10-21T00:00:00Z'))).toBe(86400);
    expect(segundosAteMeiaNoiteUtc(new Date('2026-10-21T23:59:59.500Z'))).toBe(1);
    expect(segundosAteMeiaNoiteUtc(new Date('2026-12-31T12:00:00Z'))).toBe(43200); // virada de ano
  });
});

describe('lerLimite', () => {
  it('lê texto ou número; inválido vira o padrão', () => {
    expect(lerLimite('60', 1)).toBe(60);
    expect(lerLimite(' 25 ', 1)).toBe(25);
    expect(lerLimite(10, 1)).toBe(10);
    expect(lerLimite('0', 1)).toBe(0);
    expect(lerLimite(undefined, 7)).toBe(7);
    expect(lerLimite('abc', 7)).toBe(7);
    expect(lerLimite('-3', 7)).toBe(7);
  });
});

describe('avaliarLimites / restantesHoje', () => {
  it('libera abaixo dos limites', () => {
    expect(avaliarLimites({ pessoal: 59, geral: 2999 }, 60, 3000)).toEqual({ ok: true });
  });
  it('pessoal tem prioridade sobre geral', () => {
    expect(avaliarLimites({ pessoal: 60, geral: 3000 }, 60, 3000)).toEqual({ ok: false, tipo: 'pessoal' });
    expect(avaliarLimites({ pessoal: 1, geral: 3000 }, 60, 3000)).toEqual({ ok: false, tipo: 'geral' });
  });
  it('restantes contam o turno atual', () => {
    expect(restantesHoje({ pessoal: 0, geral: 0 }, 60)).toBe(59);
    expect(restantesHoje({ pessoal: 59, geral: 0 }, 60)).toBe(0);
  });
});

describe('KV', () => {
  it('lerContagem com chaves ausentes ou lixo dá zero', async () => {
    const kv = new KvFalso();
    expect(await lerContagem(kv, 'u1', '2026-10-21')).toEqual({ pessoal: 0, geral: 0 });
    kv.dados.set('u:u1:2026-10-21', 'xyz');
    kv.dados.set('g:2026-10-21', '12');
    expect(await lerContagem(kv, 'u1', '2026-10-21')).toEqual({ pessoal: 0, geral: 12 });
  });

  it('registrarTurno soma 1 nos dois contadores com TTL de 2 dias', async () => {
    const kv = new KvFalso();
    kv.dados.set('g:2026-10-21', '41');
    await registrarTurno(kv, 'u1', '2026-10-21');
    await registrarTurno(kv, 'u1', '2026-10-21');
    expect(kv.dados.get('u:u1:2026-10-21')).toBe('2');
    expect(kv.dados.get('g:2026-10-21')).toBe('43');
    expect(kv.ttls.get('u:u1:2026-10-21')).toBe(TTL_SEGUNDOS);
    expect(TTL_SEGUNDOS).toBe(172800);
  });

  it('falha de escrita não lança', async () => {
    const kv = new KvFalso();
    kv.falharPut = true;
    await expect(registrarTurno(kv, 'u1', '2026-10-21')).resolves.toBeUndefined();
  });
});
