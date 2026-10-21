import { describe, expect, it } from 'vitest';
import {
  ABERTURA_SINTETICA,
  mapearMensagens,
  MAX_CARACTERES,
  MAX_MENSAGENS,
  normalizarEsquema,
  validarPedido,
  type MensagemApp,
} from '../src/pedido';

const base = { system: 'Você é o Prof. Dash.', mensagens: [{ papel: 'aluno', texto: 'Hi!' }] };

function erroDe(corpo: unknown): string {
  const r = validarPedido(corpo);
  if (r.ok) throw new Error('esperava erro');
  return r.mensagem;
}

describe('validarPedido', () => {
  it('aceita o mínimo e usa maxTokens 600 por padrão', () => {
    const r = validarPedido(base);
    expect(r.ok).toBe(true);
    if (r.ok) {
      expect(r.pedido.maxTokens).toBe(600);
      expect(r.pedido.esquema).toBeUndefined();
    }
  });

  it('limita maxTokens a [64, 800]', () => {
    const mt = (v: number) => {
      const r = validarPedido({ ...base, maxTokens: v });
      return r.ok ? r.pedido.maxTokens : -1;
    };
    expect(mt(10)).toBe(64);
    expect(mt(5000)).toBe(800);
    expect(mt(300.4)).toBe(300);
    expect(erroDe({ ...base, maxTokens: '300' })).toMatch(/maxTokens/);
  });

  it('recusa corpo que não é objeto', () => {
    expect(erroDe(null)).toBeTruthy();
    expect(erroDe([])).toBeTruthy();
    expect(erroDe('oi')).toBeTruthy();
  });

  it('exige system texto e mensagens não vazias', () => {
    expect(erroDe({ mensagens: base.mensagens })).toMatch(/system/);
    expect(erroDe({ system: '', mensagens: [] })).toMatch(/mensagens/);
  });

  it('recusa papel desconhecido, texto vazio e texto não-string', () => {
    expect(erroDe({ system: '', mensagens: [{ papel: 'user', texto: 'x' }] })).toMatch(/papel/);
    expect(erroDe({ system: '', mensagens: [{ papel: 'aluno', texto: '   ' }] })).toMatch(/vazia/);
    expect(erroDe({ system: '', mensagens: [{ papel: 'aluno', texto: 3 }] })).toMatch(/papel/);
  });

  it('a última fala precisa ser do aluno', () => {
    expect(
      erroDe({ system: '', mensagens: [{ papel: 'aluno', texto: 'a' }, { papel: 'ia', texto: 'b' }] }),
    ).toMatch(/última/);
  });

  it(`no máximo ${MAX_MENSAGENS} falas`, () => {
    const muitas = Array.from({ length: MAX_MENSAGENS + 1 }, (_, i) => ({
      papel: i % 2 === 0 ? 'aluno' : 'ia',
      texto: 'x',
    }));
    expect(erroDe({ system: '', mensagens: muitas })).toMatch(/falas/);
    expect(validarPedido({ system: '', mensagens: muitas.slice(1) }).ok).toBe(true);
  });

  it(`no máximo ${MAX_CARACTERES} caracteres somando system e falas`, () => {
    const metade = 'a'.repeat(MAX_CARACTERES / 2);
    expect(validarPedido({ system: metade, mensagens: [{ papel: 'aluno', texto: metade }] }).ok).toBe(true);
    expect(erroDe({ system: metade, mensagens: [{ papel: 'aluno', texto: metade + 'a' }] })).toMatch(/caracteres/);
  });

  it('esquema precisa ser objeto com type object (aceita o formato do Gemini)', () => {
    expect(erroDe({ ...base, esquema: [] })).toMatch(/esquema/);
    expect(erroDe({ ...base, esquema: { type: 'string' } })).toMatch(/object/);
    const r = validarPedido({ ...base, esquema: { type: 'OBJECT', properties: { fala: { type: 'STRING' } } } });
    expect(r.ok && r.pedido.esquema).toEqual({ type: 'object', properties: { fala: { type: 'string' } } });
  });

  it('esquema grande demais é recusado', () => {
    const props = Object.fromEntries(Array.from({ length: 400 }, (_, i) => [`campo_${i}`, { type: 'string' }]));
    expect(erroDe({ ...base, esquema: { type: 'object', properties: props } })).toMatch(/grande/);
  });
});

describe('normalizarEsquema', () => {
  it('converte o esquema do turno do app (Gemini) para JSON Schema', () => {
    const gemini = {
      type: 'OBJECT',
      properties: {
        correcao: { type: 'OBJECT', properties: { precisa: { type: 'BOOLEAN' } }, required: ['precisa'] },
        sugestoes: { type: 'ARRAY', items: { type: 'STRING' } },
        // um campo chamado "type" ou "propertyOrdering" não é palavra-chave
        type: { type: 'STRING' },
        propertyOrdering: { type: 'INTEGER' },
      },
      required: ['correcao'],
      propertyOrdering: ['correcao', 'sugestoes'],
    };
    expect(normalizarEsquema(gemini)).toEqual({
      type: 'object',
      properties: {
        correcao: { type: 'object', properties: { precisa: { type: 'boolean' } }, required: ['precisa'] },
        sugestoes: { type: 'array', items: { type: 'string' } },
        type: { type: 'string' },
        propertyOrdering: { type: 'integer' },
      },
      required: ['correcao'],
    });
  });

  it('não mexe em enum nem description', () => {
    expect(normalizarEsquema({ type: 'string', enum: ['A', 'B'], description: 'Tipo X' })).toEqual({
      type: 'string',
      enum: ['A', 'B'],
      description: 'Tipo X',
    });
  });
});

describe('mapearMensagens', () => {
  const m = (papel: 'aluno' | 'ia', texto: string): MensagemApp => ({ papel, texto });

  it('aluno → user, ia → assistant', () => {
    expect(mapearMensagens([m('aluno', 'oi'), m('ia', 'hello'), m('aluno', 'tchau')])).toEqual([
      { role: 'user', content: 'oi' },
      { role: 'assistant', content: 'hello' },
      { role: 'user', content: 'tchau' },
    ]);
  });

  it('junta falas seguidas do mesmo papel', () => {
    expect(mapearMensagens([m('aluno', 'a'), m('aluno', 'b'), m('ia', 'c'), m('ia', 'd'), m('aluno', 'e')])).toEqual([
      { role: 'user', content: 'a\n\nb' },
      { role: 'assistant', content: 'c\n\nd' },
      { role: 'user', content: 'e' },
    ]);
  });

  it('conversa que começa pela IA ganha uma abertura do usuário', () => {
    expect(mapearMensagens([m('ia', 'Hi! Table for two?'), m('aluno', 'Yes please')])).toEqual([
      { role: 'user', content: ABERTURA_SINTETICA },
      { role: 'assistant', content: 'Hi! Table for two?' },
      { role: 'user', content: 'Yes please' },
    ]);
  });

  it('não altera a lista de entrada', () => {
    const entrada = [m('aluno', 'a'), m('aluno', 'b')];
    mapearMensagens(entrada);
    expect(entrada).toEqual([m('aluno', 'a'), m('aluno', 'b')]);
  });
});
