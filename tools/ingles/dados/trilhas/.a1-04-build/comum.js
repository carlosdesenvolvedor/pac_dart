// utilidades do pacote a1-04: monta a "fonte" do Tatoeba e grava NN.json na ordem do DESIGN §5.1
const fs = require('fs');
const path = require('path');

const SAIDA = path.join(__dirname, '..');

function T(enId, enAutor, ptId, ptAutor, o = {}) {
  return {
    en_id: enId,
    en_autor: enAutor,
    pt_id: ptId,
    pt_autor: ptAutor,
    pt_autoral: ptId == null,
    licenca: 'CC BY 2.0 FR',
    modificada: !!o.mod,
    nota_modificacao: o.nota || '',
    export: '2026-10-03',
  };
}

const ORDEM_L = ['id', 'trilha', 'nome', 'emoji', 'cena', 'resumo', 'fechamento', 'contraste', 'novos', 'apoio', 'teoria',
  'imagem', 'visualizacao', 'foto_busca', 'trechos'];
const ORDEM_F = ['id', 'quem', 'contexto', 'cod', 'dica', 'pt_f', 'img', 'alvo', 'alvo_pt', 'lit', 'conceito', 'var', 'opcional',
  'blocos', 'registro', 'interferencias', 'armadilhas', 'teste', 'bio', 'variacao_de', 'origem', 'fonte'];

function ordena(o, ordem) {
  const r = {};
  for (const k of ordem) if (o[k] !== undefined) r[k] = o[k];
  for (const k of Object.keys(o)) if (!(k in r)) r[k] = o[k];
  return r;
}

function salva(trilha, licoes) {
  const dir = path.join(SAIDA, trilha);
  fs.mkdirSync(dir, { recursive: true });
  licoes.forEach((l, i) => {
    const out = ordena(l, ORDEM_L);
    out.trechos = l.trechos.map((f) => ordena(f, ORDEM_F));
    fs.writeFileSync(path.join(dir, String(i + 1).padStart(2, '0') + '.json'), JSON.stringify(out, null, 2) + '\n');
  });
  console.log(`${trilha}: ${licoes.length} lições, ${licoes.reduce((s, l) => s + l.trechos.length, 0)} frases`);
}

module.exports = { T, salva };
