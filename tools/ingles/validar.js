#!/usr/bin/env node
// Validador do conteúdo do PAC·ENGLISH — contrato do DESIGN.md §5.1 (um JSON por lição).
//   node tools/ingles/validar.js <pasta-da-trilha | lição.json ...> --esboco esboco.json [--estrito]
// Uma pasta de trilha = <trilhas>/<id-da-trilha>/NN.json (NN = número da lição com 2 dígitos).
// Sai com código 1 se houver ERRO; avisos não bloqueiam (--estrito: avisos de formato viram erro).
// Regras: tipografia do cod (DESIGN §5.2 / dossiê 06 §B8), campos obrigatórios, tetos da trilha no
// esboço (maxPalavras, maxCaracteres, frasesPorLicao / nFrases), alvo ⊂ cod e alvo_pt ⊂ dica.
const fs = require('fs');
const path = require('path');

const args = process.argv.slice(2);
let esboco = null;
// (o perfil padrão do esboço, se houver, vem em personagem.aluno.campos_do_perfil)
let estrito = false;
const alvos = [];
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--esboco') esboco = JSON.parse(fs.readFileSync(args[++i], 'utf8'));
  else if (args[i] === '--estrito') estrito = true;
  else alvos.push(args[i]);
}

const SO_ASCII = /^[\x20-\x7E]+$/;
const PROIBIDOS = /[&<>#@*_|\\{}\[\]~^`()]/;
const TIPOS_TEORIA = new Set(['h', 'p', 'ex', 'tip', 'warn']);
const REGISTROS = new Set(['informal', 'neutro', 'formal', 'escrito-trabalho']);
const ORIGENS = new Set(['autoral_ia', 'autoral_humana', 'tatoeba', 'tatoeba_adaptada']);
const CAMPOS = new Set(['id', 'quem', 'contexto', 'cod', 'dica', 'alvo', 'alvo_pt', 'lit', 'conceito', 'var', 'opcional',
  'blocos', 'pt_f', 'registro', 'interferencias', 'armadilhas', 'teste', 'bio', 'origem', 'fonte', 'variacao_de', 'fala',
  'heteronimo', 'img']);
const ID_FRASE = /^f-[0-9a-f]{6}$/;
const idsFrase = new Map(); // id da frase → onde (únicos no lote validado)
// ficha do aluno (DESIGN §5.5): {campo} trocado pelo valor padrão antes de validar
let PERFIL = { nome: ['Carlos', 'Carlos'], sobrenome: ['Souza', 'Souza'], sobrenome_soletrado: ['S-O-U-Z-A', 'S-O-U-Z-A'],
  cidade: ['Curitiba', 'Curitiba'], cidade_natal: ['Curitiba', 'Curitiba'], idade: ['thirty-two', 'trinta e dois'],
  anos_dev: ['eight', 'oito'] };
function comPerfil(texto, lingua, onde, bio) {
  return String(texto || '').replace(/\{([a-z_]+)\}/g, (m, campo) => {
    if (!PERFIL[campo]) { erro(onde, `campo de perfil desconhecido {${campo}}`); return m; }
    if (!(bio || []).includes(campo)) erro(onde, `{${campo}} usado sem estar em "bio"`);
    return PERFIL[campo][lingua];
  });
}
// âncoras visuais (IMAGENS.md): emojis, sem letras/números, contados por grafema
const grafemas = (s) => [...new Intl.Segmenter('en', { granularity: 'grapheme' }).segment(s)].length;
function emojis(v, onde, rotulo, min, max) {
  if (typeof v !== 'string' || !v.trim()) return erro(onde, `sem "${rotulo}" (emojis)`);
  if (/[A-Za-z0-9]/.test(v)) erro(onde, `${rotulo} com letra/número: "${v}" (só emojis)`);
  if (!/\p{Extended_Pictographic}/u.test(v)) erro(onde, `${rotulo} sem emoji: "${v}"`);
  const n = grafemas(v.replace(/\s/g, ''));
  if (n < min || n > max) erro(onde, `${rotulo} com ${n} emojis (de ${min} a ${max}): "${v}"`);
}
const MAX_PADRAO = { a1: 9, a2: 12, b1: 16, b2: 20, c1: 25, dev: 25 };

let erros = 0, avisos = 0, nFrases = 0, nLicoes = 0, nTatoeba = 0;
const vistas = new Map();
const erro = (onde, msg) => { erros++; console.log(`ERRO  ${onde}: ${msg}`); };
const aviso = (onde, msg) => { if (estrito) return erro(onde, msg); avisos++; console.log(`aviso ${onde}: ${msg}`); };
const palavras = (s) => (s.match(/[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*/g) || []).length;
const trilhaDoEsboco = (id) => esboco && (esboco.trilhas || []).find((t) => t.id === id);

function tipografia(en, onde, maxPal, maxCar, rotulo = 'cod') {
  if (typeof en !== 'string' || !en.length) return erro(onde, `${rotulo} vazio`);
  if (!SO_ASCII.test(en)) {
    const ruins = [...en].filter((c) => !/[\x20-\x7E]/.test(c)).map((c) => `${c}(U+${c.codePointAt(0).toString(16).toUpperCase()})`);
    erro(onde, `${rotulo} com caractere fora do ASCII digitável: ${ruins.join(' ')}`);
  }
  if (PROIBIDOS.test(en)) erro(onde, `${rotulo} com símbolo proibido (${en.match(PROIBIDOS)[0]}): "${en}"`);
  if (en !== en.trim()) erro(onde, `${rotulo} com espaço no começo/fim: "${en}"`);
  if (en.includes('  ')) erro(onde, `${rotulo} com espaço duplo: "${en}"`);
  if (en.includes('...')) erro(onde, `${rotulo} com reticências: "${en}"`);
  if (!/[.?!]"?$/.test(en)) erro(onde, `${rotulo} sem pontuação final (. ? !): "${en}"`);
  if (!/^["(]?[A-Z0-9]/.test(en)) aviso(onde, `${rotulo} não começa com maiúscula: "${en}"`);
  const n = palavras(en);
  if (maxPal && n > maxPal) erro(onde, `${rotulo} com ${n} palavras (máx. ${maxPal}): "${en}"`);
  if (maxCar && en.length > maxCar) erro(onde, `${rotulo} com ${en.length} caracteres (máx. ${maxCar}): "${en}"`);
  if (en.includes('"')) aviso(onde, `aspas duplas (evite): "${en}"`);
}

function validaLicao(arq, trilhaId, num) {
  let l;
  try { l = JSON.parse(fs.readFileSync(arq, 'utf8')); } catch (e) { return erro(arq, `JSON inválido: ${e.message}`); }
  nLicoes++;
  const t = trilhaDoEsboco(trilhaId);
  if (esboco && !t) erro(arq, `trilha "${trilhaId}" não existe no esboço`);
  const etapa = (t && t.etapa) || '';
  const maxPal = (t && t.maxPalavras) || MAX_PADRAO[etapa] || 25;
  const maxCar = (t && t.maxCaracteres) || 0;
  const doEsboco = t && t.licoes && t.licoes[num - 1];
  const ondeL = `${trilhaId}/${String(num).padStart(2, '0')} ${l.nome || '?'}`;
  if (doEsboco && l.id !== doEsboco.id) erro(ondeL, `id da lição "${l.id}" (o esboço diz "${doEsboco.id}")`);
  const semAlvo = l.fechamento === true || l.contraste === true;

  for (const c of ['nome', 'emoji', 'cena', 'resumo']) if (!l[c] || typeof l[c] !== 'string') erro(ondeL, `lição sem "${c}"`);
  if (l.nome && l.nome.length > 40) aviso(ondeL, `nome com ${l.nome.length} caracteres (máx. 40)`);
  if (typeof l.fechamento !== 'boolean') erro(ondeL, '"fechamento" precisa ser true/false');
  emojis(l.imagem, ondeL, 'imagem', 2, 4);
  if (!l.visualizacao || typeof l.visualizacao !== 'string') erro(ondeL, 'sem "visualizacao"');
  else if (l.visualizacao.length > 240) aviso(ondeL, `visualizacao com ${l.visualizacao.length} caracteres (até 220)`);
  if (!l.foto_busca || typeof l.foto_busca !== 'string' || !/^[A-Za-z][A-Za-z -]+$/.test(l.foto_busca)) {
    erro(ondeL, '"foto_busca" = 3 a 6 palavras em inglês (só letras)');
  }
  if (!Array.isArray(l.novos)) erro(ondeL, '"novos" precisa ser lista');
  const teoria = l.teoria || [];
  if (!Array.isArray(teoria) || teoria.length > 6) erro(ondeL, 'teoria: 0 a 5 blocos');
  let somaTeoria = 0;
  teoria.forEach((b, bi) => {
    const ondeB = `${ondeL} teoria[${bi}]`;
    if (!TIPOS_TEORIA.has(b.t)) erro(ondeB, `tipo inválido "${b.t}" (h/p/ex/tip/warn)`);
    if (!b.c || typeof b.c !== 'string') return erro(ondeB, 'bloco vazio');
    somaTeoria += b.c.length;
    if (b.t === 'ex') {
      const [en, pt] = b.c.split('\n');
      if (!pt) erro(ondeB, 'exemplo sem a tradução na 2ª linha ("inglês\\ntradução")');
      tipografia(en || '', ondeB, maxPal + 6, maxCar ? maxCar + 30 : 0, 'exemplo');
    }
  });
  if (somaTeoria > 700) aviso(ondeL, `teoria com ${somaTeoria} caracteres (DESIGN: até 600)`);

  const trechos = l.trechos;
  if (!Array.isArray(trechos) || !trechos.length) return erro(ondeL, 'lição sem trechos');
  const alvoN = (doEsboco && doEsboco.nFrases) || (t && t.frasesPorLicao);
  if (alvoN && Math.abs(trechos.length - alvoN) > 1) erro(ondeL, `${trechos.length} frases; o esboço pede ${alvoN}`);
  const daLicao = new Set();
  const imgs = new Map();
  const idsDaLicao = new Set();
  trechos.forEach((f, fi) => {
    nFrases++;
    const onde = `${ondeL} #${fi + 1}`;
    for (const k of Object.keys(f)) if (!CAMPOS.has(k)) erro(onde, `campo desconhecido "${k}"`);
    if (!ID_FRASE.test(f.id || '')) erro(onde, `id "${f.id}" (formato f-xxxxxx, 6 hexadecimais)`);
    else if (idsFrase.has(f.id)) erro(onde, `id "${f.id}" repetido (já em ${idsFrase.get(f.id)})`);
    else idsFrase.set(f.id, onde);
    const cod = comPerfil(f.cod, 0, onde, f.bio);
    const dica = comPerfil(f.dica, 1, onde, f.bio);
    tipografia(cod, onde, maxPal, maxCar);
    if (/\?\s+(Yes|No|So|Neither|For|Sure|Of course)\b/.test(cod)) erro(onde, `pergunta e resposta no mesmo cod: "${cod}"`);
    if (f.var !== undefined) {
      if (!Array.isArray(f.var)) erro(onde, 'var: lista de {em, aceita}');
      else f.var.forEach((v) => {
        if (!v || typeof v.em !== 'string' || !cod.includes(comPerfil(v.em, 0, onde, f.bio))) erro(onde, `var.em "${v && v.em}" não está no cod`);
        if (!v || !Array.isArray(v.aceita) || !v.aceita.length) erro(onde, 'var.aceita: lista não vazia');
        else v.aceita.forEach((a) => { if (!SO_ASCII.test(a) || PROIBIDOS.test(a)) erro(onde, `var.aceita com caractere inválido: "${a}"`); });
      });
    }
    if (f.opcional !== undefined && (!Array.isArray(f.opcional) || f.opcional.some((w) => !new RegExp('\\b' + w + '\\b').test(cod)))) {
      erro(onde, `opcional ${JSON.stringify(f.opcional)}: palavras que estão no cod`);
    }
    if (f.teste !== undefined && typeof f.teste !== 'boolean') erro(onde, 'teste: true/false');
    emojis(f.img, onde, 'img', 1, 3);
    if (!f.dica || typeof f.dica !== 'string' || !f.dica.trim()) erro(onde, 'sem dica (tradução)');
    else if (f.dica !== f.dica.trim() || /\n/.test(f.dica)) erro(onde, 'dica com espaço sobrando/quebra de linha');
    else if (dica.length > cod.length * 1.3 + 10) aviso(onde, `dica longa demais para o cod (${dica.length} × ${cod.length})`);
    if (!f.quem) erro(onde, 'sem "quem"');
    if (!REGISTROS.has(f.registro)) erro(onde, `registro inválido "${f.registro}"`);
    if (!ORIGENS.has(f.origem)) erro(onde, `origem inválida "${f.origem}"`);
    if (f.alvo) {
      if (!cod.includes(comPerfil(f.alvo, 0, onde, f.bio))) erro(onde, `alvo "${f.alvo}" não está no cod "${cod}"`);
      if (!f.alvo_pt) erro(onde, 'alvo sem alvo_pt');
      else if (!dica.includes(comPerfil(f.alvo_pt, 1, onde, f.bio))) erro(onde, `alvo_pt "${f.alvo_pt}" não está na dica "${dica}"`);
    } else if (!semAlvo) {
      erro(onde, 'sem alvo (só a cena de fechamento e a lição de contraste podem deixar vazio)');
    }
    if (f.contexto !== undefined) {
      if (ID_FRASE.test(f.contexto)) {
        if (!idsDaLicao.has(f.contexto)) erro(onde, `contexto "${f.contexto}" não é o id de uma frase ANTERIOR desta lição`);
      } else {
        tipografia(comPerfil(f.contexto, 0, onde, f.bio), onde, 0, 0, 'contexto');
      }
    }
    if (f.id) idsDaLicao.add(f.id);
    if (f.lit !== undefined && (typeof f.lit !== 'string' || f.lit.length > 70)) aviso(onde, 'lit longo (até 60)');
    if (f.conceito && f.conceito.length > 140) aviso(onde, `conceito com ${f.conceito.length} caracteres (até 120)`);
    if (String(f.origem || '').startsWith('tatoeba')) {
      nTatoeba++;
      const fo = f.fonte;
      if (!fo || !Number.isInteger(fo.en_id) || !fo.en_autor || typeof fo.modificada !== 'boolean') {
        erro(onde, 'origem tatoeba sem "fonte" {en_id, en_autor, pt_id, pt_autor, modificada, ...}');
      } else if ((f.origem === 'tatoeba_adaptada') !== fo.modificada) {
        aviso(onde, 'origem tatoeba_adaptada ⇔ fonte.modificada: true');
      }
    } else if (f.fonte) {
      erro(onde, '"fonte" só para origem tatoeba*');
    }
    if (typeof f.img === 'string' && f.img) {
      const k = f.img.replace(/\s/g, '');
      if (imgs.has(k)) aviso(onde, `img "${f.img}" igual à da frase #${imgs.get(k)} (varie)`);
      else imgs.set(k, fi + 1);
    }
    const chave = String(f.cod || '').toLowerCase();
    if (daLicao.has(chave)) erro(onde, `frase repetida na lição: "${f.cod}"`);
    daLicao.add(chave);
    if (vistas.has(chave)) aviso(onde, `frase igual à de ${vistas.get(chave)}: "${f.cod}"`);
    else vistas.set(chave, ondeL);
  });
}

for (const alvo of alvos) {
  const st = fs.statSync(alvo);
  if (st.isDirectory()) {
    const id = path.basename(alvo);
    const arqs = fs.readdirSync(alvo).filter((a) => /^\d\d\.json$/.test(a)).sort();
    const t = trilhaDoEsboco(id);
    const nPlano = t && (t.licoes ? t.licoes.length : t.nLicoes);
    if (!arqs.length) erro(alvo, 'pasta sem lições NN.json');
    if (nPlano && arqs.length !== nPlano) erro(alvo, `${arqs.length} lições; o esboço tem ${nPlano}`);
    arqs.forEach((a) => validaLicao(path.join(alvo, a), id, parseInt(a, 10)));
  } else {
    validaLicao(alvo, path.basename(path.dirname(alvo)), parseInt(path.basename(alvo), 10));
  }
}

const pct = nFrases ? Math.round((nTatoeba * 100) / nFrases) : 0;
console.log(`\n${nLicoes} lição(ões) · ${nFrases} frases (${pct}% Tatoeba) · ${erros} erro(s) · ${avisos} aviso(s)`);
console.log(erros ? 'RESULTADO: FALHOU' : 'RESULTADO: OK');
process.exit(erros ? 1 : 0);
