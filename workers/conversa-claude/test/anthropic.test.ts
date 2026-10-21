import { describe, expect, it } from 'vitest';
import {
  extrairResposta,
  montarCorpoAnthropic,
  NOME_FERRAMENTA,
  objetoJsonDoTexto,
  perfilDoModelo,
} from '../src/anthropic';
import type { PedidoTurno } from '../src/pedido';

const esquema = { type: 'object', properties: { fala: { type: 'string' } }, required: ['fala'] };
const pedido: PedidoTurno = {
  system: 'Você é o garçom.',
  mensagens: [
    { papel: 'ia', texto: 'Hi! Table for two?' },
    { papel: 'aluno', texto: 'Yes' },
    { papel: 'aluno', texto: 'please' },
  ],
  maxTokens: 600,
};

describe('perfilDoModelo', () => {
  it('Haiku 5.5 (padrão): sem temperature, ferramenta forçada, pensamento desligado', () => {
    expect(perfilDoModelo('claude-haiku-5-5')).toEqual({
      temperatura: false,
      forcarFerramenta: true,
      desligarPensamento: true,
      esforcoBaixo: false,
    });
  });

  it('Opus 5.5 / Sonnet 5.5 / Fable 5.1: tool_choice auto e esforço baixo', () => {
    for (const m of ['claude-opus-5-5', 'claude-sonnet-5-5', 'claude-fable-5-1']) {
      expect(perfilDoModelo(m)).toMatchObject({ forcarFerramenta: false, esforcoBaixo: true, temperatura: false });
    }
  });

  it('Haiku 4.5 / Sonnet 4.6: aceitam temperature', () => {
    expect(perfilDoModelo('claude-haiku-4-5').temperatura).toBe(true);
    expect(perfilDoModelo('claude-sonnet-4-6').temperatura).toBe(true);
    expect(perfilDoModelo('claude-opus-4-8').temperatura).toBe(false);
  });
});

describe('montarCorpoAnthropic', () => {
  it('com esquema no Haiku 5.5: tool forçada, thinking off, sem temperature', () => {
    const c = montarCorpoAnthropic({ ...pedido, esquema }, 'claude-haiku-5-5');
    expect(c.model).toBe('claude-haiku-5-5');
    expect(c.max_tokens).toBe(600);
    expect(c.system).toBe('Você é o garçom.');
    expect(c.tools).toEqual([{ name: NOME_FERRAMENTA, description: 'Responde ao turno da conversa', input_schema: esquema }]);
    expect(c.tool_choice).toEqual({ type: 'tool', name: NOME_FERRAMENTA });
    expect(c.thinking).toEqual({ type: 'disabled' });
    expect(c).not.toHaveProperty('temperature');
    expect(c.messages).toEqual([
      { role: 'user', content: '[A conversa começa.]' },
      { role: 'assistant', content: 'Hi! Table for two?' },
      { role: 'user', content: 'Yes\n\nplease' },
    ]);
  });

  it('com esquema no Opus 5.5: tool_choice auto + instrução no system + effort low', () => {
    const c = montarCorpoAnthropic({ ...pedido, esquema }, 'claude-opus-5-5');
    expect(c.tool_choice).toEqual({ type: 'auto' });
    expect(c.system).toContain(`"${NOME_FERRAMENTA}"`);
    expect(c.output_config).toEqual({ effort: 'low' });
    expect(c).not.toHaveProperty('thinking');
  });

  it('modelo antigo recebe temperature 0.5', () => {
    expect(montarCorpoAnthropic(pedido, 'claude-haiku-4-5').temperature).toBe(0.5);
  });

  it('sem esquema: sem tools; system vazio é omitido', () => {
    const c = montarCorpoAnthropic({ ...pedido, system: '  ' }, 'claude-haiku-5-5');
    expect(c).not.toHaveProperty('tools');
    expect(c).not.toHaveProperty('tool_choice');
    expect(c).not.toHaveProperty('system');
  });
});

describe('extrairResposta', () => {
  const uso = { input_tokens: 100, output_tokens: 20, cache_read_input_tokens: 5 };

  it('tool_use → input como JSON em texto', () => {
    const r = extrairResposta(
      {
        stop_reason: 'tool_use',
        content: [
          { type: 'tool_use', id: 't1', name: NOME_FERRAMENTA, input: { fala: 'Great, follow me.', fim: false } },
        ],
        usage: uso,
      },
      true,
    );
    expect(r).toEqual({ ok: true, texto: '{"fala":"Great, follow me.","fim":false}', uso: { entrada: 105, saida: 20 } });
  });

  it('com esquema mas resposta em texto JSON (tool_choice auto) também serve', () => {
    const r = extrairResposta(
      { stop_reason: 'end_turn', content: [{ type: 'text', text: '```json\n{"fala":"Ok"}\n```' }], usage: uso },
      true,
    );
    expect(r).toMatchObject({ ok: true, texto: '{"fala":"Ok"}' });
  });

  it('com esquema e só texto solto → falha', () => {
    const r = extrairResposta({ stop_reason: 'end_turn', content: [{ type: 'text', text: 'Sure!' }], usage: uso }, true);
    expect(r).toEqual({ ok: false, motivo: 'sem_ferramenta' });
  });

  it('sem esquema → texto concatenado, ignorando blocos de pensamento', () => {
    const r = extrairResposta(
      {
        stop_reason: 'end_turn',
        content: [
          { type: 'thinking', thinking: '', signature: 'x' },
          { type: 'text', text: 'Hello ' },
          { type: 'text', text: 'there!' },
        ],
        usage: { input_tokens: 7, output_tokens: 3 },
      },
      false,
    );
    expect(r).toEqual({ ok: true, texto: 'Hello there!', uso: { entrada: 7, saida: 3 } });
  });

  it('recusa e formatos estranhos', () => {
    expect(extrairResposta({ stop_reason: 'refusal', content: [] }, false)).toEqual({ ok: false, motivo: 'recusa' });
    expect(extrairResposta({ content: [] }, false)).toEqual({ ok: false, motivo: 'vazia' });
    expect(extrairResposta('x', false)).toEqual({ ok: false, motivo: 'formato' });
    expect(extrairResposta({ content: 'x' }, false)).toEqual({ ok: false, motivo: 'formato' });
  });

  it('objetoJsonDoTexto', () => {
    expect(objetoJsonDoTexto('Aqui: {"a":1} pronto')).toEqual({ a: 1 });
    expect(objetoJsonDoTexto('[1,2]')).toBeNull();
    expect(objetoJsonDoTexto('{quebrado')).toBeNull();
  });
});
