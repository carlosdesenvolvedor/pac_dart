export const meta = {
  name: 'escolher-fotos-ingles',
  description: 'Agentes olham as folhas de miniaturas e escolhem a foto real de cada cena do PAC·ENGLISH',
  whenToUse: 'Depois de buscar os candidatos no Chrome e montar as folhas (tools/ingles/fotos.py folhas); args = {scr, nLotes} — os lotes ficam em <scr>/fotos/lotes_escolha.json',
  phases: [{ title: 'Escolha', detail: 'uma folha 3×3 por cena' }],
}

const SCR = args.scr
const SCHEMA = {
  type: 'object',
  properties: {
    arquivo: { type: 'string' },
    escolhidas: { type: 'number' },
    nenhuma: { type: 'array', items: { type: 'string' } },
  },
  required: ['arquivo', 'escolhidas', 'nenhuma'],
}

phase('Escolha')
const indices = Array.from({ length: args.nLotes }, (_, i) => i)
const r = (await parallel(indices.map((i) => () => agent(`Você escolhe FOTOS REAIS para as cenas das lições de um curso de inglês para brasileiros (app PAC·ENGLISH). A foto
abre a lição como "âncora visual" (o aluno visualiza a cena antes de digitar as frases e a reencontra na revisão), então ela
precisa MOSTRAR A CENA com clareza.

Para cada cena abaixo há uma folha com até 9 miniaturas numeradas de 1 a 9 em ${SCR}/fotos/folhas/<chave>.jpg — abra cada
folha com a ferramenta Read (ela mostra a imagem) e escolha:
- "n": o número da melhor foto para a cena; "reserva": a segunda melhor (para o caso de a mesma foto já ter sido usada).
- 0 quando NENHUMA serve.
Critérios, nesta ordem: (1) mostra o lugar/ação da cena de forma reconhecível; (2) sem logotipo, marca ou texto em destaque,
sem pessoa famosa; (3) nada sensível (bebida alcoólica em destaque, cigarro, violência, sensualidade); (4) foto nítida,
bem iluminada, natural (não montagem nem ilustração); (5) de preferência com pessoas na situação (diálogo, trabalho, viagem).

Suas cenas: o lote de índice ${i} (base 0) da lista em ${SCR}/fotos/lotes_escolha.json — uma lista de lotes, cada lote uma
lista de {"chave", "nome", "situacao"}. Leia só o seu lote (ex.: node -e "console.log(JSON.stringify(require('${SCR}/fotos/lotes_escolha.json')[${i}],null,1))").

Escreva ${SCR}/fotos/escolhas/lote_${String(i + 1).padStart(2, '0')}.json, JSON estrito:
{"<chave>": {"n": 0-9, "reserva": 0-9, "motivo": "curto"}, ...} com TODAS as chaves do lote (folha que não existe = n 0).
Valide com node (JSON.parse). Devolva o caminho, quantas tiveram foto e a lista das chaves sem foto. Não altere nada fora de
${SCR}/fotos/escolhas/.`,
  { label: `escolha:${String(i + 1).padStart(2, '0')}`, phase: 'Escolha', schema: SCHEMA })))).filter(Boolean)
const nenhuma = r.flatMap((x) => x.nenhuma || [])
log(`${r.reduce((a, x) => a + x.escolhidas, 0)} cenas com foto; ${nenhuma.length} sem`)
return { lotes: r.length, escolhidas: r.reduce((a, x) => a + x.escolhidas, 0), nenhuma }
