export const meta = {
  name: 'gerar-trilhas-csharp',
  description: 'Gera, valida no laboratório Roslyn e revisa trilhas do PAC·C# (lições, teoria, trechos, projetos e desafios de lógica)',
  phases: [
    { title: 'Gerar', detail: 'um autor por trilha: ~12 lições, teoria, ~110 trechos e projetos, validados até RESULTADO: OK' },
    { title: 'Desafios', detail: 'desafios de lógica por trilha com gabarito tirado da execução real' },
    { title: 'Revisar', detail: 'revisor adversarial por trilha: correção técnica, didática e progressão; conserta e revalida' },
  ],
}

const SCR = '/private/tmp/claude-501/-Users-fazplay-pac-dart/bbf7559e-a2cf-4561-a6d6-0cc5c2c0fffd/scratchpad/csharp'
const ESBOCO = `${SCR}/esboco_final.json`
const ALVO = Array.isArray(args) ? args : args.trilhas

const nn = (t) => String(t.ordem).padStart(2, '0')
const arqT = (t) => `${SCR}/trilhas/${nn(t)}-${t.id}.json`
const arqD = (t) => `${SCR}/desafios/${nn(t)}-${t.id}.json`
const LAB = `export DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec; L="$DOTNET_ROOT/dotnet ${SCR}/lab/bin/lab/Lab.dll"`
const REGRA = `REGRA DURA: escreva só dentro de ${SCR} (use a sua pasta de trabalho); NUNCA crie/altere nada em /Users/fazplay/pac_dart; não rode flutter.`
const DOSSIES = `Dossiês de pesquisa (exemplos corretos, armadilhas, ordem didática, URLs oficiais): ${SCR}/pesquisa/docs-csharp.md (linguagem C# 14),
dotnet-web-roadmap.md (.NET, ASP.NET Core, EF Core, roadmap júnior→sênior), arquitetura.md (SOLID, padrões, Clean, DDD, CQRS, microsserviços),
senior-dotnet.md (desempenho, concorrência, segurança, testes, observabilidade), treinos.md (bons exercícios e pedagogia), jogos.md (Unity 6,
Godot 4, MonoGame, padrões de jogos). Leia as seções que tocam a sua trilha. Na dúvida sobre uma API, confira na doc oficial
(carregue as ferramentas com ToolSearch "select:WebFetch,WebSearch").`

const anteriores = (t) => `as trilhas com "ordem" de 1 a ${t.ordem - 1} em ${ESBOCO} (leia nome e lições de cada uma)`
const posteriores = (t) => `as trilhas com "ordem" de ${t.ordem + 1} em diante no mesmo arquivo`

const RES_GERAR = {
  type: 'object',
  properties: {
    arquivo: { type: 'string' },
    licoes: { type: 'number' },
    trechos: { type: 'number' },
    projetos: { type: 'number' },
    resultado_lab: { type: 'string', description: 'a última linha "RESULTADO: ..." do laboratório' },
    observacoes: { type: 'string' },
  },
  required: ['arquivo', 'licoes', 'trechos', 'projetos', 'resultado_lab'],
}
const RES_DESAFIOS = {
  type: 'object',
  properties: {
    arquivo: { type: 'string' },
    total: { type: 'number' },
    jogos: { type: 'number' },
    por_tipo: { type: 'string' },
    resultado_lab: { type: 'string' },
  },
  required: ['arquivo', 'total', 'jogos', 'resultado_lab'],
}
const RES_REVISAR = {
  type: 'object',
  properties: {
    problemas: { type: 'array', items: { type: 'string' } },
    corrigido: { type: 'array', items: { type: 'string' } },
    pendente: { type: 'array', items: { type: 'string' } },
    resultado_trilha: { type: 'string' },
    resultado_desafios: { type: 'string' },
  },
  required: ['problemas', 'corrigido', 'pendente', 'resultado_trilha', 'resultado_desafios'],
}

function promptGerar(t) {
  return `Você é autor sênior do currículo PAC·C# (curso de C#/.NET com treino de digitação, em pt-BR).
Sua tarefa: escrever COMPLETA a trilha ${t.ordem} "${t.nivel}" (${t.etapa}, perfil ${t.perfil}).

LEIA PRIMEIRO, com atenção: ${SCR}/GUIA-GERADOR.md — é o contrato (formato JSON, regras de digitação, perfis de compilação,
laboratório, pedagogia). Se o perfil for unity, leia também o stub ${SCR}/lab/stubs/UnityEngine.cs.
${DOSSIES}

A SUA TRILHA: a entrada com "ordem": ${t.ordem} (id "${t.id}") no esboço ${ESBOCO} — lições com tópicos, ideias de projetos,
ideias de desafios e URLs oficiais. Pode melhorar nomes/ordem/tópicos das lições para ficar mais didático, mantendo a cobertura.
O QUE A PESSOA JÁ ESTUDOU (pode usar): ${t.ordem === 1 ? 'nada — esta é a primeira trilha do curso' : anteriores(t)}.
O QUE VEM DEPOIS (não antecipe; se precisar muito de algo, apresente na teoria antes de usar): ${posteriores(t)}.

ENTREGA: ${arqT(t)} — um objeto de trilha com nivel="${t.nivel}", emoji="${t.emoji}", etapa="${t.etapa}", fundo="${t.fundo}",
perfil="${t.perfil}", descricao, 12 lições (11 a 13) com 9 ou 10 trechos cada, teoria de 5 a 9 blocos (2-3 blocos code) e resumo,
e 2 ou 3 projetos "Mão na Massa". Pasta de trabalho: ${SCR}/trabalho/${t.id}/ (crie).
Fluxo sugerido: escreva a trilha lição por lição (ex.: um script Python em ${SCR}/trabalho/${t.id}/ que monta o JSON), valide cada
lição assim que escrever (${LAB}; $L trilha ${arqT(t)} --fix --licao N), conserte, siga para a próxima; no fim rode a trilha inteira
($L trilha ${arqT(t)} --fix) até "RESULTADO: OK" e zere os avisos que der. O --fix preenche os "out" dos trechos que imprimem.
Qualidade acima de tudo: C# moderno e correto, explicações que ensinam o porquê, exemplos realistas e variados, progressão suave.
${REGRA}
Responda com o resumo pedido (contagens reais do arquivo final).`
}

function promptDesafios(t) {
  return `Você escreve os DESAFIOS DE LÓGICA (não são de digitação) da trilha ${t.ordem} "${t.nivel}" (${t.etapa}) do PAC·C#.
LEIA: ${SCR}/GUIA-DESAFIOS.md (contrato completo, com exemplos de cada tipo) e a trilha pronta ${arqT(t)} (o que ela ensina de fato).
Use SÓ o que foi ensinado até esta trilha, inclusive. Trilhas anteriores: ${t.ordem === 1 ? 'nenhuma' : anteriores(t)}.
Ideias do esboço: o campo "desafios_ideias" da trilha ${t.ordem} em ${ESBOCO}.
ENTREGA: ${arqD(t)} com {"nivel": "${t.nivel}", "desafios": [16 desafios]} — mistura de saida/valor/lacuna/ordenar/bug/escolha,
níveis 1→3, pelo menos 5 com "tema": "jogo". Pasta de trabalho: ${SCR}/trabalho/${t.id}-desafios/.
Valide: ${LAB}; $L desafios ${arqD(t)} --fix — até "RESULTADO: OK" (ele roda o código e corrige gabaritos; confira depois se as
alternativas erradas continuam plausíveis e se a explicação bate com o gabarito final).
${REGRA}
Responda com o resumo pedido.`
}

function promptRevisar(t) {
  return `Você é o REVISOR ADVERSARIAL da trilha ${t.ordem} "${t.nivel}" (${t.etapa}, perfil ${t.perfil}) do PAC·C#.
Arquivos: trilha ${arqT(t)} e desafios ${arqD(t)}. Leia os contratos ${SCR}/GUIA-GERADOR.md e ${SCR}/GUIA-DESAFIOS.md.
Assuma que há problemas e CAÇE-OS — depois conserte direto nos arquivos:
1. CORREÇÃO TÉCNICA: afirmação errada ou desatualizada sobre C# 14/.NET 10 (ou Unity 6/Godot 4/MonoGame) na teoria, nas dicas,
   nos "conceito" e nas explicações dos desafios; API obsoleta; prática ruim ensinada como boa; nome fora das convenções .NET.
   Confira na doc oficial quando houver dúvida (ToolSearch "select:WebFetch,WebSearch"). ${DOSSIES}
2. DIDÁTICA E PROGRESSÃO: lição que pula etapas; trecho que usa algo que a teoria não preparou; conceito de trilha POSTERIOR
   (trilhas anteriores: ${t.ordem === 1 ? 'nenhuma' : anteriores(t)}); trechos repetitivos
   ou triviais; pouca variedade de domínios; teoria rasa (sem o porquê, sem armadilha, sem uso real); resumo que não diz o que se aprende.
3. DIGITAÇÃO: trecho longo demais ou chato de digitar sem ganho; dica que não diz o que o trecho faz; "out" descritivo incoerente.
4. PROJETOS: fracos, triviais ou que não usam o que a trilha ensinou.
5. DESAFIOS: gabarito discutível, distratores bobos/implausíveis, explicação que não ensina, tema de jogo forçado, uso de conceito
   que a pessoa ainda não viu, ordem ambígua.
6. PORTUGUÊS: erros, frases truncadas, tom (professor animado, claro, "você").
Reescreva o que for preciso (pode reescrever lições inteiras). Depois rode os DOIS validadores até "RESULTADO: OK":
${LAB}; $L trilha ${arqT(t)} --fix; $L desafios ${arqD(t)} --fix. Pasta de trabalho: ${SCR}/trabalho/${t.id}-revisao/.
${REGRA}
Responda com: problemas encontrados, o que corrigiu, o que ficou pendente (se algo) e as linhas RESULTADO dos dois validadores.`
}

const resultados = await pipeline(
  ALVO,
  (t) => agent(promptGerar(t), { label: `gerar:${nn(t)}-${t.id}`, phase: 'Gerar', schema: RES_GERAR, effort: 'high' }),
  (r, t) => agent(promptDesafios(t), { label: `desafios:${nn(t)}-${t.id}`, phase: 'Desafios', schema: RES_DESAFIOS, effort: 'high' })
    .then((d) => ({ gerar: r, desafios: d })),
  (r, t) => agent(promptRevisar(t), { label: `revisar:${nn(t)}-${t.id}`, phase: 'Revisar', schema: RES_REVISAR, effort: 'high' })
    .then((v) => ({ trilha: `${nn(t)}-${t.id}`, ...r, revisao: v })),
)
const ok = resultados.filter(Boolean)
log(`${ok.length}/${ALVO.length} trilhas concluídas`)
return ok
