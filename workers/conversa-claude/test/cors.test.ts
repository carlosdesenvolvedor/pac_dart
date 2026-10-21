import { describe, expect, it } from 'vitest';
import { cabecalhosCors, cabecalhosPreflight, decidirOrigem, origemPermitida } from '../src/cors';

describe('origemPermitida', () => {
  it.each([
    'https://pac-dart.web.app',
    'https://pac-dart.firebaseapp.com',
    'http://localhost',
    'http://localhost:8080',
    'http://localhost:54321',
    'http://127.0.0.1:3000',
  ])('aceita %s', (o) => expect(origemPermitida(o)).toBe(true));

  it.each([
    'http://pac-dart.web.app', // sem https
    'https://pac-dart.web.app.evil.com',
    'https://evil-pac-dart.web.app',
    'https://localhost:8080', // local só em http
    'http://localhost.evil.com',
    'http://localhost:8080/caminho',
    'http://127.0.0.2:3000',
    'https://pac-dart.web.app/',
    'null',
  ])('recusa %s', (o) => expect(origemPermitida(o)).toBe(false));
});

describe('decidirOrigem', () => {
  it('sem Origin (app nativo) é permitido, sem cabeçalhos CORS', () => {
    expect(decidirOrigem(null)).toEqual({ tipo: 'sem_origem' });
    expect(decidirOrigem('')).toEqual({ tipo: 'sem_origem' });
    expect(cabecalhosCors({ tipo: 'sem_origem' })).toEqual({});
  });

  it('origem permitida ecoa a origem e varia por Origin', () => {
    const d = decidirOrigem('https://pac-dart.web.app');
    expect(d.tipo).toBe('permitida');
    expect(cabecalhosCors(d)).toMatchObject({ 'Access-Control-Allow-Origin': 'https://pac-dart.web.app', Vary: 'Origin' });
  });

  it('origem estranha é negada', () => {
    expect(decidirOrigem('https://exemplo.com').tipo).toBe('negada');
  });

  it('preflight libera authorization e content-type', () => {
    const h = cabecalhosPreflight(decidirOrigem('http://localhost:5000'));
    expect(h['Access-Control-Allow-Headers']).toBe('authorization, content-type');
    expect(h['Access-Control-Allow-Methods']).toContain('POST');
    expect(h['Access-Control-Allow-Origin']).toBe('http://localhost:5000');
  });
});
