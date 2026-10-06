export const meta = {
  name: 'gerar-trilhas-ingles',
  description: 'Gera as frases do PAC·ENGLISH por pacote de trilhas: autor → revisor nativo (EN) → revisor PT/progressão',
  whenToUse: 'Depois do esboco.json final; args = {scr, pacotes:[{nome, trilhas:[ids]}]}',
  phases: [
    { title: 'Autor', detail: 'escreve as trilhas do pacote e passa no validador' },
    { title: 'Revisão EN', detail: 'professor nativo americano reescreve o que não soa natural' },
    { title: 'Revisão PT', detail: 'tradução, recordação sem ambiguidade, progressão e teoria' },
  ],
}

// args: { scr: '<scratchpad>/ingles', projeto: '/Users/fazplay/pac_dart', pacotes: [{ nome, trilhas: ['id', ...] }] }
const SCR = args.scr
const PROJ = args.projeto || '/Users/fazplay/pac_dart'
const ESBOCO = `${SCR}/esboco.json`
const SAIDA = `${SCR}/trilhas`
const VALIDAR = `node ${PROJ}/tools/ingles/validar.js`
const TSV = `${SCR}/pesquisa/fontes07/tatoeba_candidatas_en_ptbr.tsv`

const CTX = `CONTEXTO
PAC·ENGLISH é o curso de inglês do app PAC·DART (Flutter web): a pessoa vê a TRADUÇÃO PT-BR em cima e DIGITA a frase
em inglês, letra a letra. Cada frase é digitada 5 vezes intercalada com as outras e com cada vez menos ajuda
(cópia → só as iniciais → só os tracinhos → escondida → prova), e volta na revisão espaçada dos dias seguintes.
Por isso a frase precisa ser NATURAL, ÚTIL, do NÍVEL CERTO e a tradução precisa levar a UM inglês só.
Leia (Read) antes de começar:
- ${SCR}/DESIGN.md — o contrato: §5 (REGRAS DE CONTEÚDO: formato 5.1, inglês 5.2, tradução 5.3, alvo/glosa/nota 5.4,
  cenas e ELENCO FIXO 5.5, origem 5.6, proibições 5.7, exemplos 5.8) e §6 (CHECKLIST frase a frase). Siga à risca;
- ${ESBOCO} — o esboço final: a(s) sua(s) trilha(s) (gramática, vocabulário/chunks, situações, interferências BRxx,
  maxPalavras, maxCaracteres, frasesPorLicao e as lições com objetivo, foco, vocabulário, exemplos e nFrases). As
  trilhas ANTERIORES dizem o que o aluno já sabe; as posteriores, o que ele ainda NÃO sabe;
- ${SCR}/IMAGENS.md — as ÂNCORAS VISUAIS (pedido do dono): campos obrigatórios "imagem", "visualizacao" e "foto_busca"
  em cada lição e "img" (1–3 emojis do SENTIDO) em cada frase. Siga as regras de lá;
- ${SCR}/pesquisa/04-brasileiros.md (interferências BR01–BR60 e regras de tradução T1–T20) quando precisar.
REGRAS DE AMBIENTE: escreva só em ${SAIDA}/. Não crie nem altere nada em ${PROJ} (só LEIA/rode a ferramenta de validação).

ARQUIVOS: uma pasta por trilha, ${SAIDA}/<id-da-trilha>/, com UM JSON POR LIÇÃO: 01.json, 02.json, … (na ordem do
esboço, uma por lição do esboço). Cada arquivo segue À RISCA o formato do DESIGN.md §5.1 — campos da lição: id (O MESMO id
da lição no esboço, ex. "presente-simples.gosto-de-cafe-amo-pizza"), nome, emoji, cena (1 frase PT: a situação), resumo,
fechamento, contraste (se for), novos, apoio, teoria, imagem, visualizacao, foto_busca; e "trechos" com id, quem, contexto,
cod, dica, img, alvo, alvo_pt, lit, conceito, var, opcional, blocos, pt_f, registro, interferencias, armadilhas, teste, bio,
origem, fonte…
- id da frase = "f-" + 6 hexadecimais ALEATÓRIOS (gere com: node -e "console.log(require('crypto').randomBytes(3).toString('hex'))"),
  único — nunca derivado da posição ou do texto.
- "contexto" = o id de uma frase ANTERIOR da mesma lição (a fala que esta frase responde) ou, se a fala não é frase do curso,
  o texto em inglês. Pergunta e resposta NUNCA no mesmo cod.
- "cod": só ASCII imprimível, apóstrofo reto, pontuação final, SEM parênteses, dentro de maxPalavras/maxCaracteres da trilha.
- Frases sobre o próprio aluno usam a FICHA (esboço → personagem.aluno): {nome}, {sobrenome}, {cidade}, {idade}, {anos_dev}…
  no cod e na dica, listados em "bio". Nunca invente fato da vida dele fora da ficha.
- "dica": PT-BR natural, fiel e determinística (leva a UM inglês; microcontexto entre parênteses na DICA, âncoras de tempo,
  glossário travado do esboço → "glossario").
- "alvo" ⊂ cod e "alvo_pt" ⊂ dica (substrings EXATAS); vazio só na cena de fechamento e na lição de contraste.
- "var" para formas equivalentes (ex.: [{"em": "I'd", "aceita": ["I would"]}]) e "opcional" para palavras que podem faltar.
- "lit" no formato "[lit.: ...]", só quando ajuda; "conceito" 1 linha, até 120 caracteres.
- Teoria: 0 a 5 blocos curtos ({"t": "h"|"p"|"ex"|"tip"|"warn", "c": "..."}), "ex" = "inglês\ntradução".
Valide cada trilha com: ${VALIDAR} ${SAIDA}/<id-da-trilha> --esboco ${ESBOCO}
e só termine com "RESULTADO: OK" em todas as suas trilhas.`

const TATOEBA = `FONTE TATOEBA (modelo misto, dossiê 07 §6): o arquivo ${TSV} (TSV com cabeçalho:
nivel_lexical, en_id, en, en_dono, pt_id, pt, pt_dono, palavras, audio_en, tem_tom_mary) tem 85 mil frases de nativos
com tradução brasileira. Para cada lição, procure (grep -i) frases com o chunk/estrutura-alvo e o nível certo. Quando uma
frase encaixa na cena e no nível, ADOTE (cod igual; origem "tatoeba") ou ADAPTE (troque nome/objeto; origem "tatoeba_adaptada", "modificada": true),
sempre com o campo "fonte". O PT do Tatoeba só fica se for pt-BR natural, fiel e determinístico; senão reescreva e use
"pt_id": null, "pt_autor": null, "pt_autoral": true.
Evite Tom/Mary em excesso. Meta: A1–A2 cerca de 30–40% das frases do Tatoeba, B1–B2 20–30%, C1 até 15%, dev 0%.
Frase do Tatoeba passa pelas MESMAS regras (ASCII, tamanho, nível, elenco: troque Tom/Mary por alguém do elenco fixo e
marque origem "tatoeba_adaptada" e "modificada": true). Preencha a "fonte" como no DESIGN §5.1 (en_id, en_autor, pt_id,
pt_autor, pt_autoral, licenca "CC BY 2.0 FR", modificada, nota_modificacao, export "2026-10-03").`

const PACOTE_SCHEMA = {
  type: 'object',
  properties: {
    trilhas: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string' },
          licoes: { type: 'number' },
          frases: { type: 'number' },
          tatoeba: { type: 'number' },
          resultado: { type: 'string', enum: ['OK', 'FALHOU'] },
        },
        required: ['id', 'licoes', 'frases', 'resultado'],
      },
    },
    mudancas: { type: 'number', description: 'frases alteradas nesta etapa (0 no autor)' },
    observacoes: { type: 'string' },
  },
  required: ['trilhas', 'mudancas'],
}

function autor(p) {
  return agent(`${CTX}

${TATOEBA}

VOCÊ É O AUTOR do pacote "${p.nome}". Suas trilhas (nesta ordem): ${p.trilhas.join(', ')}.
Escreva cada trilha em ${SAIDA}/<id>/NN.json (um arquivo por lição) seguindo o esboço lição a lição (objetivo, foco,
vocabulário, interferências, nFrases) e as regras do DESIGN.md. Comece pelo vocabulário e pela gramática que o aluno já tem (trilhas anteriores do
esboço) e não use estrutura que só aparece depois. Rode o validador em cada arquivo e corrija até "RESULTADO: OK".
Devolva por trilha: id, lições, frases, quantas vieram do Tatoeba e o resultado do validador.`,
    { label: `autor:${p.nome}`, phase: 'Autor', schema: PACOTE_SCHEMA })
}

function revisorEn(p) {
  return agent(`${CTX}

VOCÊ É O REVISOR NATIVO (EN) do pacote "${p.nome}": professor americano de ESL, nativo, exigente com naturalidade.
Pastas: ${p.trilhas.map((id) => `${SAIDA}/${id}/`).join(', ')} (um JSON por lição).
Para CADA frase (cod) e cada exemplo "ex" da teoria:
1. Imagine a situação (quem diz para quem, onde). Sem situação plausível = frase ruim.
2. "Rewrite it exactly as a native speaker would say it in this situation; if nothing should change, keep it identical."
   Corrija: falta de naturalidade, colocação errada, britanismo (curso en-US), vocabulário inflado, frase perfeita demais
   sem contração, particípio pendurado (", making..."), padrão repetido demais na lição, nome/tema monótono.
3. Confira o NÍVEL: só gramática e vocabulário já introduzidos (esboço: trilhas anteriores + lição atual); respeite
   maxPalavras/maxCaracteres. Uma frase fora do nível é reescrita no nível, não apagada.
4. Ao mudar o cod: ajuste o "alvo" (pedaço exato do cod), a "dica"/"alvo_pt" se o sentido mudou, o "contexto" das
   frases seguintes que o citam, e se a frase veio do Tatoeba passe a origem para "tatoeba_adaptada" com "modificada": true.
Edite os arquivos no lugar (mantenha o formato), rode o validador em cada um até "RESULTADO: OK".
Devolva por trilha o resultado e o total de frases que você mudou, com as 10 mudanças mais importantes em observacoes
("antes → depois — motivo").`,
    { label: `revisor-en:${p.nome}`, phase: 'Revisão EN', schema: PACOTE_SCHEMA })
}

function revisorPt(p) {
  return agent(`${CTX}

VOCÊ É O REVISOR DE TRADUÇÃO E PROGRESSÃO do pacote "${p.nome}": tradutor brasileiro e professor de inglês para brasileiros.
Pastas: ${p.trilhas.map((id) => `${SAIDA}/${id}/`).join(', ')} (um JSON por lição).
Para CADA frase:
1. PT ("dica") natural do Brasil e fiel ao cod (negação, tempo, pessoa); nada de pt-PT ("estou a fazer", "contigo"), translationese
   ("Eu" sempre explícito, futuro sintético "terminarei") ou falso cognato.
2. TESTE DE RECORDAÇÃO (retro-tradução, DESIGN T04): sem olhar o cod, traduza a dica para o inglês. Se sair outro inglês IGUALMENTE certo e
   natural, a pessoa vai "errar" acertando: ajuste a dica (microcontexto entre parênteses, âncora de tempo,
   posse explícita), use "contexto", ou declare a forma em "alt" (até 3, só variantes de FORMA).
3. "img" (emojis) mostra o SENTIDO da frase e leva a ela (sem repetir o conjunto da vizinha); "visualizacao" da lição em
   2ª pessoa, presente e sensorial; "lit" só quando ajuda; "conceito" em 1 linha, correto, sem jargão; "alvo"/"alvo_pt" = o chunk ensinado, iguais nas
   duas línguas; mesmo chunk = mesma tradução no curso (glossário único).
4. A lição cumpre o objetivo do esboço? Recicla o que veio antes? A ordem das frases forma uma cena coerente? A teoria
   (3–6 blocos) está certa, curta, em PT-BR, com a armadilha de brasileiro da lição (BRxx do esboço) num "warn"?
Corrija no lugar (sem trocar o inglês, a não ser erro claro — aí ajuste o alvo e, se Tatoeba, tatoeba_adaptada), rode o
validador em cada arquivo até "RESULTADO: OK". Devolva por trilha o resultado e o total de frases mudadas, com as 10
mudanças mais importantes em observacoes.`,
    { label: `revisor-pt:${p.nome}`, phase: 'Revisão PT', schema: PACOTE_SCHEMA })
}

// autor que morreu não passa pelos revisores (o pacote volta como falha)
const resultados = await pipeline(
  args.pacotes,
  (p) => autor(p),
  (r, p) => (r ? revisorEn(p) : null),
  (r, p) => (r ? revisorPt(p) : null),
)

const linhas = []
resultados.forEach((r, i) => {
  const p = args.pacotes[i]
  if (!r) {
    linhas.push({ pacote: p.nome, trilhas: p.trilhas, falhou: true })
    return
  }
  linhas.push({ pacote: p.nome, trilhas: r.trilhas, mudancasPt: r.mudancas, obs: (r.observacoes || '').slice(0, 600) })
})
const falhas = linhas.filter((l) => l.falhou || (l.trilhas || []).some((t) => t.resultado !== 'OK'))
log(`${linhas.length - falhas.length}/${linhas.length} pacotes OK`)
return { pacotes: linhas, falhas: falhas.map((f) => f.pacote) }
