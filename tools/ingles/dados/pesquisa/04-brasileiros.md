# 04 · Dificuldades específicas de brasileiros + como traduzir

> Dossiê de pesquisa para o **curso de Inglês do PAC·DART** (frase em PT-BR em cima, a pessoa digita a frase inteira em inglês embaixo, várias vezes, do zero ao avançado).
> Frente: interferência do português brasileiro no inglês + regras de tradução para quem escreve as frases + padrão americano × britânico.
> Data: out/2026. Fontes no fim (chaves `[S#]`).

---

## 0. Resumo para quem vai desenhar o curso

1. **Digitar é produzir, e é na produção que a interferência aparece.** Copiando um texto esmaecido o aluno quase não erra. Os erros de brasileiro (*"Is raining"*, *"Have a problem"*, *"I have 30 years"*, *"explain me"*) só aparecem quando ele precisa **recuperar** o inglês a partir do português. Por isso o curso precisa de repetições em que o inglês vai sumindo (cópia → lacuna → recuperação a partir do PT). Sem a fase de recuperação, a lista de interferências abaixo não é treinada de verdade.
2. **A frase em PT de cima deve ser o gatilho natural do erro, e o EN de baixo, a forma certa.** Exemplo: "Tem um problema no build." → `There's a problem with the build.` O aluno digita o contraste dezenas de vezes. A forma errada **nunca** é alvo de digitação; ela aparece no máximo riscada numa nota.
3. **Tradução natural em cima, glosa literal só quando a estrutura diverge.** A linha principal é PT-BR do jeito que um brasileiro falaria (Microsoft pt-BR Style Guide: evitar palavra por palavra [S17]). A glosa literal fica em colchetes, só no trecho divergente, no estilo Assimil/Birkenbihl [S31]. Glosa interlinear, colada ao texto, reduz carga cognitiva e melhora a retenção de vocabulário [S14].
4. **Usar a L1 está do lado das evidências.** Nation (2003) conclui que a tradução para a L1 é sistematicamente o meio mais eficaz de passar significado na aprendizagem deliberada, e que cartões L2↔L1 funcionam muito bem [S13]. O alerta de Schütz contra a "tradução mental" [S5] vale para a **fluência**. A conciliação é esta: PT como âncora de significado no começo, digitação sempre em inglês, e o PT vai sumindo nos níveis altos. É o mesmo percurso que Mairo Vergara propõe com o Anki: frase + tradução no começo, cards inglês/inglês no avançado [S15].
5. **Uma frase, um item novo (i+1).** Cada frase introduz no máximo uma palavra, um chunk ou uma estrutura nova, destacada nas duas linhas [S15].
6. **O PT precisa levar a um único EN.** Quando o inglês estiver escondido, o PT tem que fixar pessoa, posse (dele/dela), tempo (já, desde, há, ontem) e registro. Nos modos de recuperação, o motor deve aceitar variantes equivalentes (`I'm` = `I am`), como o Duolingo faz com listas de traduções aceitas [S26].
7. **O padrão deve ser o inglês americano, com consistência total.** Motivos: as APIs que o dono usa no dia a dia (`Center` [S22], `Color`, `dart analyze`), os guias de estilo de Google e Microsoft (ortografia americana, Merriam-Webster [S19]), e a Cambridge aceita qualquer variante desde que seja consistente [S20]. O inglês britânico entra só como conteúdo de **reconhecimento** a partir do B2.
8. **Os 60 pontos de interferência (seção 6) dividem-se assim:** 20 no A1, 26 no A2, 13 no B1 e 1 no B2. A maior parte da interferência acontece cedo. Por isso o "ponto de partida desconhecido" pede um **teste de nivelamento por interferência**: uma frase de recuperação por ponto. O aluno pula o que acerta.
9. **Ortografia e maiúsculas fazem parte do conteúdo**, porque o curso é de digitação. Brasileiro erra de forma sistemática as consoantes duplas dos cognatos (*comunity*, *diferent*, *confortable*, *accomodation*), o ph/th/y, o -ally e as letras mudas. Também esquece maiúscula em dias, meses, línguas e nacionalidades, que em português são minúsculos [S6][S8].
10. **Falsos cognatos importam menos do que parece.** Schütz estima menos de 0,1% de ocorrência [S2], e o Core Inventory só põe "eliminating false friends" no C1 [S27]. Os de alta frequência (actually, pretend, realize, parents, push, library, college, lunch, eventually, attend/assist) entram cedo e em contexto, nunca como lista solta.

---

## 1. Escopo, método e limites

**O que li de fato** (fonte primária aberta e lida):
- Ricardo Schütz (English Made in Brasil). Páginas de contrastes gramaticais, falsos cognatos, to/for, diferenças idiomáticas e tradução mental [S1–S5].
- Folha "Common English errors when a learner's first language is Portuguese", da equipe de pesquisa linguística da Cambridge University Press [S6].
- Listas de erros de falantes de português: LLEXI, Online Teachers UK, MosaLingua [S7–S9].
- Artigos acadêmicos brasileiros: Vaz de Mello/UFMG sobre análise de erros [S10], Fonseca 2001 sobre o present perfect [S11], Cury & Gama 2022 sobre sujeito nulo [S12].
- Nation 2003 sobre o papel da L1 [S13] e Bonilla Carvajal 2025 sobre tradução interlinear [S14].
- O guia completo de Mairo Vergara [S15–S16].
- Microsoft pt-BR Localization Style Guide [S17].
- Google Developer Style Guide [S19], Cambridge English [S20], Wikipedia (BP, ortografia AmE/BrE, palavras mal escritas), Wiktionary e o British Council/EAQUALS Core Inventory [S27].

**O que não consegui abrir (e como tratei):**
- **Learner English (Swan & Smith, 2001)**, capítulo "Portuguese speakers" [S29]: o livro não está online. Cito só como referência bibliográfica e **não** atribuo a ele nenhum exemplo específico.
- Cambridge Dictionary e Oxford Learner's: devolveram 403. As regras de *explain/say/tell/make/do* vêm de [S1], [S7], [S8] e do conhecimento consolidado da área. Onde não há fonte lida, digo isso.
- Inglês Winner, Teacher Allie e Carina Fragozo (English in Brazil): a cota de buscas acabou antes de achar posts específicos. Os temas que esses canais cobrem coincidem com [S1–S9]. O livro *Sou péssimo em inglês* (Fragozo) fica como leitura recomendada.
- Estudos de corpus Br-ICLE/COBRA-7: tive só os resumos dos resultados de busca, não o texto integral. Uso esses achados como tendência geral, marcados como [S30].

**Contexto do público:** o Brasil aparece no EF EPI com 482 pontos, em 75º lugar, abaixo da média global de 488 [S28]. O brasileiro médio adulto chega com inglês escolar fragmentado. O curso precisa funcionar do zero e permitir pular etapas.

---

## 2. Por que brasileiros erram o que erram: mapa das interferências

### 2.1 O que diz a evidência sobre erros

- **Cambridge University Press, aprendizes com L1 português [S6]:**
  - **Preposições:** as mais confundidas são *in*, *at* e *on*. Os erros mais comuns são *in* no lugar de *at*, *in* no lugar de *on* e *on* no lugar de *in*.
  - **Verbos:** *use* no lugar de *wear*, *go* no lugar de *come*, *forgot* no lugar de *left*. Os verbos que mais faltam são *have*, *wear* e *is*.
  - **Infinitivo de finalidade:** erro característico de lusófonos, como *"for going"* em vez de *"to go"*.
  - **Tempos:** presente no lugar de passado, também em condicionais.
  - **Substantivos:** *work* no lugar de *job*, *travel* no lugar de *trip*, *home* no lugar de *house*, *cloth* no lugar de *clothes*.
  - **Ortografia, palavras que mais erram:** *which*, *comfortable*, *beautiful*, *beginning*, *because*, *believe*, *different*, *accommodation*, *together*, *always*.
- **Corpora de aprendizes brasileiros (Br-ICLE, COBRA-7) [S30]:**
  - As categorias mais frequentes são escolha lexical errada, tempo e aspecto, determinantes (artigos), e perguntas, negativas e auxiliares.
  - Trocar preposições ou partículas é problema recorrente, mas diminui ao longo do curso.
  - Muitos aprendizes ainda omitem a preposição final em perguntas (*"Who are you talking?"*) mesmo no nível avançado.
- **Schütz [S1]:** o inventário de contrastes mais citado no ensino para brasileiros, resultado da "análise dos erros mais frequentemente observados no ensino de inglês a brasileiros".

### 2.2 As famílias de interferência

| Família | Mecanismo no PT-BR | Sintoma típico em inglês |
|---|---|---|
| **Sujeito** | PT é língua de sujeito nulo: "Está chovendo", "Trabalha de casa". No BP o sujeito referencial já costuma ser preenchido, mas o expletivo nunca existe [S12] | ✗ *Is raining.* ✗ *Is important.* |
| **Existência** | No BP falado, *ter* substitui *haver*: "Tem muito problema na cidade" [S18] | ✗ *Have a problem here.* ✗ *Has many people.* |
| **Ter × ser/estar** | ter anos, ter fome, estar com frio, ter razão [S4] | ✗ *I have 30 years.* ✗ *I have cold* (que significa "estou resfriado") |
| **Ordem da frase** | Pergunta só por entonação; *não* antes do verbo; adjetivo depois do nome; advérbio solto | ✗ *You like coffee?* ✗ *I not like.* ✗ *a car red* ✗ *I like very much coffee* |
| **Concordância** | Adjetivo vai ao plural; "gente" é singular; "informações" é contável | ✗ *differents ideas* ✗ *people is* ✗ *informations* |
| **Determinantes** | Artigo definido em generalizações e antes de nomes ("A vida", "O Brasil", "A Maria"); "um" é artigo e numeral | ✗ *The life is short.* ✗ *The Brazil.* ✗ *I'm developer.* |
| **Posse** | "o carro do meu pai"; "seu" ambíguo (dele/dela/seu) | ✗ *the car of my father* ✗ *She called his mother* (querendo dizer a mãe dela) |
| **Regência** | Verbos com preposição em PT e sem em EN (ligar para, perguntar para, entrar em, discutir sobre), e preposições diferentes (depender de, sonhar com, casado com) | ✗ *call to him* ✗ *enter in* ✗ *depend of* ✗ *married with* |
| **Um verbo PT, vários EN** | fazer, ficar, perder, ganhar, conhecer, tomar, levar, emprestar, assistir | ✗ *make my homework* ✗ *lose the bus* ✗ *know Paris* ✗ *borrow me* |
| **Tempo e aspecto** | Não há present perfect equivalente [S11]; futuro do subjuntivo ("quando eu chegar"); imperfeito ("eu morava"); "há X anos" | ✗ *I work here since 2022.* ✗ *When I will arrive.* ✗ *I have seen him yesterday.* |
| **Falsos cognatos** | Formas parecidas com sentidos diferentes [S2] | ✗ *Actually I work at…* (querendo dizer "atualmente") ✗ *I pretend to…* |
| **Ortografia** | Cognatos com letra simples em PT e dupla em EN; ph/th/y; *-mente* vira *-ly*; letras mudas; maiúsculas | ✗ *comunity* ✗ *diferent* ✗ *sistem* ✗ *finaly* ✗ *monday* |

### 2.3 Nem todo erro é interferência

Vaz de Mello (UFMG) lembra que parte dos erros vem de **analogia e hipótese**, não da L1, e muitas vezes das duas coisas juntas [S10]. Exemplos dela: *"had fall"* por *had fallen* (mesmo com as formas paralelas em PT) e *"Portugueses"* (a regra do -s funciona nas duas línguas). O curso deve monitorar também esses **erros de desenvolvimento**: -s de 3ª pessoa, passados irregulares, plurais irregulares. Ver o Anexo D.

---

## 3. Implicações para um curso de digitação de frases

1. **Três modos por frase**, para a interferência aparecer e ser corrigida:
   - **Cópia:** EN esmaecido, PT em cima. Fixa forma, ortografia e ritmo.
   - **Lacuna:** só o chunk-alvo some, por exemplo `___ a problem with the build.` com "Tem um problema no build." em cima. Força a escolha do ponto de interferência.
   - **Recuperação:** só o PT aparece e o aluno digita o EN inteiro. É aqui que *"Have a problem"* aparece e deve ser registrado.
2. **Registrar as armadilhas por frase.** Cada frase leva as etiquetas dos pontos de interferência que treina (por exemplo `BR03`) e, opcionalmente, os prefixos errados previstos (`["Have a", "Has a"]`). No modo recuperação, se o aluno começa a digitar um prefixo-armadilha, o motor mostra o alerta e soma um erro **naquele ponto**. Assim a estatística é por interferência, não só por letra. Ver o Anexo F.
3. **A forma errada nunca é alvo.** Digitar *"I have 30 years"* reforçaria o erro. O ✗ fica só na nota, riscado e em texto menor.
4. **Espiral.** Cada ponto reaparece em níveis seguintes, em frases mais longas. Por exemplo, BR03 (*there is*) volta no B1 como `There must be a mistake in the logs.`
5. **Nivelamento por interferência.** Uma frase de recuperação por ponto (BR01–BR46 para A1–A2, BR47–BR60 para B1–B2). O aluno pula as lições cujos pontos acertou com folga.
6. **Contraste explícito, mas curto.** Fonseca recomenda comparar as estruturas PT × EN para o present perfect [S11]. No app isso cabe numa glosa de uma linha, não numa aula de gramática. Mairo e Schütz concordam: menos regra, mais frase memorizada [S15][S1].

---

## 4. Regras práticas para quem escreve as traduções

### 4.1 Princípio-mestre

> **A linha de cima é o contexto: o que eu quero dizer, em português natural. A linha de baixo é como um falante nativo diz isso.**
> O aluno memoriza o par como uma unidade de sentido, não como uma equação palavra por palavra.

Base: Nation (a L1 dá significado claro, curto e familiar, por isso é eficaz [S13]); Microsoft pt-BR ("word-to-word translation should be avoided… would make the tone stiff and unnatural" [S17]); Mairo (frase + tradução; "jamais deverá inventar suas frases", use frases reais e corretas [S15]).

### 4.2 As regras

**T1. PT natural, do jeito que um brasileiro diria naquela situação.** Teste: "eu falaria exatamente isso no WhatsApp, na padaria ou na daily?"

| EN | ✗ PT ruim (decalque) | ✓ PT bom |
|---|---|---|
| `Can I have a coffee, please?` | Posso ter um café, por favor? | Me vê um café, por favor? |
| `I'm coming!` | Estou vindo! | Já vou! |
| `Never mind.` | Nunca se importe. | Deixa pra lá. |
| `It's up to you.` | Está acima de você. | Você que sabe. |
| `What do you do?` | O que você faz? | Você trabalha com o quê? |
| `Let me know.` | Deixe-me saber. | Me avisa. |
| `I used to live in Rio.` | Eu costumava viver no Rio. | Eu morava no Rio. |
| `Take care!` | Tome cuidado! | Se cuida! |
| `How long have you been here?` | Quanto tempo você tem estado aqui? | Faz quanto tempo que você está aqui? |
| `I'm done.` | Estou feito. | Terminei. / Acabei. |

**T2. Uma frase EN, uma frase PT, com a mesma função e a mesma energia.** Pergunta continua pergunta, ordem continua ordem, exclamação continua exclamação. Não junte duas frases EN numa PT, nem quebre uma em duas, a não ser que quebre as duas juntas.

**T3. Nunca deforme o PT para espelhar o EN.** O espelho vai na glosa.
- ✗ "Isto está chovendo." / ✗ "Eu sou 30 anos velho."
- ✓ "Está chovendo." com a glosa `[it = sujeito obrigatório, sem tradução]`
- ✓ "Tenho 30 anos." com a glosa `[lit.: Eu sou 30 anos velho]`. Glosa literal absurda é um bom gancho de memória.

**T4. A armadilha fica no PT, a correção no EN, o alerta na glosa.** O PT deve conter justamente a palavra que induz o erro, porque é ela que o aluno vai ouvir na cabeça na vida real.
- "Atualmente trabalho como freelancer." → `Currently, I work as a freelancer.` com a glosa `⚠ atualmente = currently (actually = na verdade)`
- "Pretendo terminar hoje." → `I intend to finish today.` com a glosa `⚠ pretender = intend / plan (pretend = fingir)`

**T5. O PT deve levar a um único EN canônico (desambiguação).** Quando o EN estiver escondido, o aluno só tem o PT.

| Ambiguidade | Como resolver no PT |
|---|---|
| Posse ("seu", "a mãe") | Explicitar: "a mãe **dela**", "as chaves **dele**" → *her/his* |
| Tempo e aspecto | Usar âncoras: **já**, **ainda não**, **nunca**, **desde**, **há**, **ontem**, **em 2019** |
| Objeto implícito ("Adorei!") | O canônico inclui o pronome (`I loved it!`). A glosa marca `[it obrigatório]` |
| Formalidade | "o senhor / a senhora" ou "Poderia…?" → *Could you…?* / *Sir* |
| *you* genérico | "a gente nunca sabe" / "nunca se sabe" → `You never know.` |
| Contrações | Convenção global: frases de conversa usam contração no canônico (`I'm`, `don't`, `it's`) e o motor aceita a forma longa nos modos de recuperação |
| Variantes legítimas | Lista `en_variantes` na frase (ex.: `I already ate` / `I've already eaten`) |

Duolingo resolve isso com listas de traduções aceitas montadas por especialistas, que podem chegar a bilhões de combinações [S26]. Aqui o problema é menor, porque o alvo é sempre o inglês e só se aceitam variantes **inglesas**. Mesmo assim, cada frase precisa de 0 a 3 variantes declaradas.

**T6. Glosa literal: só o trecho divergente, entre colchetes, no máximo uma por frase.**
- Formato: `[lit.: …]` para a literal, `[X = …]` para explicar um chunk, `⚠` para um falso cognato.
- Mostrar a glosa por padrão na **primeira exposição** no A0–A1. Depois, só sob demanda (toque ou hover).
- Não glosar o que já é transparente. Glosa em toda frase vira ruído e o aluno para de ler.
- Por quê: a glosa interlinear, colada ao texto, venceu glosa de margem e glosa "construída" na retenção após 8 dias, porque reduz a atenção dividida [S14]. Assimil usa exatamente o par tradução natural + literal entre colchetes [S31]. A "decodificação" de Birkenbihl é a literal palavra por palavra mantendo a sintaxe da língua-alvo [S31]. Esse é o recurso de última instância, útil para estruturas muito estranhas (*there is*, *'s*, *do* em perguntas, phrasal verbs).

**T7. Chunk-alvo (i+1): cada frase introduz no máximo um item novo, destacado nas duas linhas.**
- Mairo: o ideal é que a frase "contenha apenas uma palavra ou expressão que você não saiba". Com três ou mais desconhecidas, "terá muita dificuldade para lembrá-las e os estudos ficarão cansativos" [S15].
- Formato da glosa: `back to square one = de volta à estaca zero`.
- Alinhamento visual: destacar com a mesma cor "Tem" ↔ `There's`, "há" ↔ `ago`. Só no chunk-alvo, não na frase toda.

**T8. Phrasal verbs: traduzir pelo sentido.**
- Partícula transparente pode ir na glosa: `sit down = sentar [down: para baixo]`, `come back = voltar [back: de volta]`.
- Phrasal opaco recebe glosa do bloco inteiro: `figure out = descobrir, sacar`, `put up with = aguentar, tolerar`.
- Nunca traduzir a partícula sozinha na linha principal.

**T9. Idioms: equivalente idiomático em PT quando existir, senão paráfrase.** A literal pode entrar como gancho de memória:
- `It's raining cats and dogs.` → "Está chovendo canivetes." com `[lit.: chovendo gatos e cachorros]`
- `We're back to square one.` → "Voltamos à estaca zero." com `[lit.: de volta ao quadrado um]`
- `It's not my cup of tea.` → "Não é a minha praia." com `[lit.: minha xícara de chá]`
- Sem equivalente: `Break a leg!` → "Boa sorte! (no palco)" com `[lit.: quebre uma perna]`

**T10. Tempos sem par direto em PT: âncoras fixas.**

| Estrutura EN | PT canônico | Âncora / glosa |
|---|---|---|
| `used to + verbo` | imperfeito: "Eu jogava…" | `[used to = costumava; hábito que acabou]` |
| `be used to + -ing` | "Estou acostumado a…" | `[to aqui é preposição → -ing]` |
| present perfect (experiência) | "Você **já** foi…?" / "**Nunca** vi…" | já, nunca, alguma vez |
| present perfect (resultado) | "**Já** terminei." / "**Ainda não** terminei." | já, ainda não, acabei de |
| present perfect + for/since | presente PT: "Moro aqui **há** 5 anos / **desde** 2020" | `[algo que continua → have + particípio]` |
| present perfect continuous | "Estou esperando **há** uma hora." | idem |
| simple past + ago | "Me mudei para cá **há** dois anos." | `[há + passado terminado → ago]` |
| `when/if/as soon as` + presente | futuro do subjuntivo: "quando eu **chegar**" | `[depois de when/if: presente, nunca will]` |
| `will` (promessa ou decisão na hora) | presente PT: "Te ligo amanhã." | `[promessa → will]` |
| present continuous (plano marcado) | presente PT: "Amanhã eu viajo." | `[plano marcado → be + -ing]` |
| 2º condicional | "Se eu **tivesse**… **faria**…" | `[if + passado, would + verbo]` |

**T11. Registro.**
- **"Você" sempre, nunca "tu".** "Você" domina no BP e "tu" é regional [S18]. O guia da Microsoft trata o usuário por "você" [S17].
- **"A gente" em diálogos informais e "nós" em frases neutras ou escritas.** Cada frase leva uma etiqueta de registro (`informal`, `neutro`, `formal`, `trabalho-escrito`) e a escolha segue a etiqueta, nunca o humor de quem escreve.
- **"O senhor / a senhora"** só quando o EN marca formalidade (`Sir`, `Madam`, `Could you possibly…`, `May I…`).
- **Gíria PT só quando o EN é gíria:** `gonna`, `wanna`, `kinda` e `Dude` → "cara", "tipo". Essas formas só entram como reconhecimento no B2 e nunca como alvo de digitação antes disso.

**T12. Gênero: o EN é neutro, o PT marca gênero.**
- "I'm tired" vira "Estou cansado" ou "Estou cansada"; "I'm a developer" vira "Sou desenvolvedor" ou "desenvolvedora".
- Padrão: o gênero do aluno. O dono do app é homem, mas o curso pode servir outras pessoas. Guardar `pt_f` opcional quando a forma muda.
- Na 3ª pessoa, escolher um gênero e manter a coerência com o pronome EN (*he/she*).

**T13. Anglicismos de TI.**
- Manter onde o dev brasileiro de fato fala assim: deploy, build, commit, bug, merge, PR, sprint, daily, feature, release.
- Traduzir quando há palavra PT corrente: arquivo, pasta, tela, botão, senha, servidor, banco de dados.
- Nunca misturar na mesma frase "fazer o deploy" e "implantação".

**T14. Tipografia do EN (é digitado, então tem que ser previsível).**
- **Só ASCII.** Apóstrofo reto `'` (U+0027), nunca o curvo `’` (U+2019). Aspas retas `"`, nunca as curvas `“ ”`. Nada de travessão `—`, reticências `…` como caractere único ou espaço duplo.
- **Evitar aspas no EN até o B1.** No layout US-International, que o dono usa, `'` e `"` são teclas mortas: `'a` vira `á` e `"a` vira `ä`. Contrações (`don't`, `it's`, `I'm`) funcionam, porque t, s e m não recebem acento. Aspas antes de vogal atrapalham.
- **Pontuação americana:** `Mr.` com ponto, ponto e vírgula dentro das aspas (quando houver aspas), vírgula serial ("zones, regions, and multi-regions"), como no guia do Google [S19].
- **Números:** ponto decimal (`3.5`), vírgula de milhar (`1,000`), horas `9:30`, datas americanas `January 5` / `October 4, 2026`. Escolher entre `a.m.` e `AM` e manter sempre a mesma forma.

**T15. Tipografia do PT (só é lido).** Acentos sempre, ortografia padrão e a mesma pontuação final do EN.

**T16. Comprimento.** O PT deve caber em cima: no máximo cerca de 1,3 vez o comprimento do EN. Frase longa demais se quebra em duas, nas duas línguas ao mesmo tempo.

**T17. Glossário único.** O mesmo chunk EN recebe a mesma tradução PT em todo o curso, salvo quando o sentido muda. Antes de publicar, buscar no corpus se o chunk já tem tradução.

**T18. Microcontexto quando a frase isolada é ambígua.** Usar parênteses no PT:
- "(no restaurante) Me vê a conta, por favor." → `Can I get the check, please?`
- "(ao telefone) Quem fala?" → `Who's calling?`

**T19. O erro nunca é alvo.** O ✗ aparece só na nota, riscado. Se a lição é sobre o erro, digita-se a forma certa em vários contextos.

**T20. O PT vai sumindo de forma progressiva**, como a etapa "Eliminando o português" de Mairo [S15] e a ideia de Nation de que a L1 é ferramenta, mas não para ser usada em excesso [S13].

| Nível | PT | Glosa | Outros recursos |
|---|---|---|---|
| A0–A1 | sempre visível | automática na 1ª exposição | alinhamento de cor no chunk |
| A2 | sempre visível | sob demanda | — |
| B1 | visível | só para idioms e phrasal verbs | — |
| B2 | esmaecido, revela com toque | sob demanda | parte das frases com paráfrase em inglês |
| C1 | opcional | definição em inglês, dicionário monolíngue | frases "inglês/inglês" |

**T21. Frases reais, não inventadas no vácuo.** Mairo insiste em frases tiradas de fontes corretas [S15]. Na prática, quem escreve deve conferir colocações duvidosas num dicionário com exemplos ou num corpus, e marcar `fonte` quando a frase for adaptada.

### 4.3 Checklist de revisão de cada frase (10 perguntas)

1. O EN está correto, natural e em inglês americano?
2. O PT é o que um brasileiro diria naquela situação?
3. O PT leva a um único EN, ou as variantes estão declaradas?
4. Há no máximo um item novo, e ele está destacado?
5. A glosa (se houver) cobre só o trecho divergente?
6. O EN é ASCII puro, sem aspas ou travessões problemáticos?
7. O registro (você, a gente, o senhor) bate com a etiqueta?
8. O gênero está coerente (pt / pt_f)?
9. As etiquetas de interferência (`BR##`) estão marcadas?
10. O chunk tem a mesma tradução que no resto do curso?

### 4.4 Proposta de ficha (formato de dado de cada frase)

Só uma sugestão para quem modela o `curriculo` do inglês. Nada disto foi aplicado ao projeto.

```json
{
  "id": "en-a1-012",
  "nivel": "A1",
  "en": "There's a pharmacy near here.",
  "en_variantes": ["There is a pharmacy near here."],
  "pt": "Tem uma farmácia aqui perto.",
  "pt_f": null,
  "glosa": "There's = há/existe (nunca 'have'); lit.: Há uma farmácia perto daqui",
  "foco": "There's",
  "alinhamento": [["Tem", "There's"]],
  "interferencias": ["BR03"],
  "armadilhas": ["Have a", "Has a"],
  "registro": "neutro",
  "contexto": null
}
```

---

## 5. Inglês americano × britânico: qual padrão e por quê

### 5.1 Decisão: **inglês americano (en-US) como único padrão de produção**

1. **Código e ferramentas do dono.** O Flutter usa `Center` ("A widget that centers its child within itself" [S22]), `Color`, `TextAlign.center`, `ColorScheme`. O Dart tem `dart analyze` / `flutter analyze`. CSS e DOM usam `color`, `center`, `behavior`. Para um dev, a grafia americana já é a do dia a dia, e misturar `colour` no curso com `Color` no código cria atrito.
2. **Documentação técnica.** O guia do Google prescreve ortografia americana com o Merriam-Webster como dicionário de referência ("use the first form listed… *canceled*… more common than *cancelled*") [S19]. Google e Microsoft documentam em en-US, e a convenção *-ize* domina em computação e em publicações científicas internacionais [S21].
3. **Exames não penalizam.** A Cambridge aceita ortografia britânica ou americana, desde que a mesma palavra seja escrita sempre do mesmo jeito no teste [S20].
4. **Exposição no Brasil.** Filmes, séries, YouTube e as big techs são majoritariamente americanos. Isto é observação, não dado medido.
5. **Bônus de cognato.** O *-ize* americano casa com o *-izar* do português: organize/organizar, prioritize/priorizar, customize/customizar.

### 5.2 O que padronizar (en-US)

| Área | en-US (padrão do curso) | en-GB (só reconhecimento, B2+) |
|---|---|---|
| -or / -our | color, behavior, favorite, honor, neighbor | colour, behaviour, favourite |
| -er / -re | center, theater, meter, fiber | centre, theatre, metre |
| -ize / -yze | organize, realize, analyze, initialize | organise, realise, analyse |
| l simples | traveled, canceled, labeled, modeling | travelled, cancelled, labelled |
| -se / -ce | license (substantivo e verbo), defense, offense | licence (substantivo), defence |
| -og / -ogue | catalog, dialog (UI) | catalogue, dialogue |
| outras | gray, program, check, jewelry, mom | grey, programme, cheque, jewellery, mum |
| Vocabulário | apartment, vacation, cell phone, elevator, subway, line, check (conta), fall, soccer, gas, cookie, movie, trash, sidewalk, truck | flat, holiday, mobile, lift, underground, queue, bill, autumn, football, petrol, biscuit, film, rubbish, pavement, lorry |
| Gramática | coletivo no singular (*The team is*) [S7]; *on the weekend*; *different from*; *gotten*; *Do you have…?* | *The team are*; *at the weekend*; *different to*; *have got* |
| Present perfect | No inglês americano informal, *Did you eat yet?* / *I already ate* são aceitos. O canônico das lições de present perfect usa present perfect; a forma simples entra em `en_variantes` quando o modo é recuperação | O inglês britânico é mais estrito com o present perfect |
| Datas | October 4, 2026 / 10/04/2026 (mês primeiro!) | 4 October 2026 / 04/10/2026 |
| Pontuação | aspas duplas, ponto e vírgula dentro das aspas, vírgula serial | aspas simples comuns, pontuação fora das aspas |

**Cuidado com datas numéricas.** `10/04/2026` é 4 de outubro em en-US e 10 de abril no Brasil. Em frase de digitação, preferir mês por extenso. O guia da Online Teachers UK também lista a escrita de datas como fonte de erro [S8].

### 5.3 Inglês britânico no curso

- Uma lição de "variantes" no B2: colour/centre/organise, lift/flat/holiday/queue, *have got*, *at the weekend*. Só para **ler e reconhecer**: o aluno digita a frase americana e vê a britânica como nota.
- Nunca misturar as duas grafias em frases de digitação.

---

## 6. Os 60 pontos de interferência mais importantes

**Legenda.**
- **Nível:** CEFR em que o ponto deve ser **introduzido**. Ele volta depois em espiral.
- **(CI: X):** o British Council/EAQUALS Core Inventory põe a estrutura nesse nível [S27].
- **✗:** erro típico de brasileiro. Nunca é alvo de digitação.
- **Frases-modelo:** `EN` | PT natural. A glosa entra só quando ajuda.
- **Código BR##:** sugestão de etiqueta para a ficha (`interferencias`).

### 6.1 Visão geral

| # | Ponto | Nível | Família |
|---|---|---|---|
| BR01 | Sujeito *it* obrigatório | A1 | sujeito |
| BR02 | Pronome sujeito obrigatório | A1 | sujeito |
| BR03 | *There is/are* × *have* | A1 | existência |
| BR04 | *be* para idade e estados (ter anos, fome, frio, razão) | A1 | ter × ser/estar |
| BR05 | *this morning / tonight / this week* (hoje de manhã…) | A1 | expressão de tempo |
| BR06 | Perguntas com *do/does/did* | A1 | ordem e auxiliares |
| BR07 | Negativas com *don't/doesn't/didn't* | A1 | ordem e auxiliares |
| BR08 | Adjetivo antes do substantivo | A1 | ordem |
| BR09 | Adjetivo não vai ao plural | A1 | concordância |
| BR10 | Genitivo *'s* | A1 | posse |
| BR11 | *his/her/their* × seu/sua | A1 | posse |
| BR12 | Sem artigo antes de nomes, países, empresas | A1 | determinantes |
| BR13 | *a/an* com profissões; *a* ≠ *one* | A1 | determinantes |
| BR14 | *people* é plural ("muita gente" = *many people*) | A1 | concordância |
| BR15 | Maiúsculas: *I*, dias, meses, línguas, nacionalidades | A1 | ortografia |
| BR16 | *go home / at work / go to bed* (sem artigo, sem *to*) | A1 | determinantes e regência |
| BR17 | *in / on / at* (tempo e lugar) | A1 | preposições |
| BR18 | Pronome objeto obrigatório (*it/him/them*) | A1 | sujeito e objeto |
| BR19 | Ordem: advérbios (*very much*, *always*) e "mais três" | A1 | ordem |
| BR20 | *watch / see / look at / hear / listen to* | A1 | léxico |
| BR21 | Artigo zero em generalizações | A2 | determinantes |
| BR22 | Incontáveis (*information, advice, software, code, feedback*) | A2 | concordância |
| BR23 | "muito": *very / much / many / a lot / too* | A2 | léxico |
| BR24 | Substantivo + substantivo (*error message*) | A2 | ordem |
| BR25 | Dupla negação | A2 | negação |
| BR26 | "há" = *ago* × "por" = *for* | A2 | tempo |
| BR27 | Present perfect × simple past | A2 (CI: A2; contraste B1) | tempo e aspecto |
| BR28 | Futuro do subjuntivo → presente (*when I get home*) | A2 | tempo |
| BR29 | Planos: present continuous ("Amanhã eu viajo") | A2 (CI: A2) | tempo |
| BR30 | Modais sem *to*; finalidade com *to* (não *for to*) | A2 | verbo |
| BR31 | *say / tell / speak / talk* | A2 | léxico |
| BR32 | *make × do* (+ *ask, have, take*) | A2 | léxico |
| BR33 | ficar | A2 | léxico |
| BR34 | perder: *lose / miss / waste* | A2 | léxico |
| BR35 | ganhar: *win / earn / get* | A2 | léxico |
| BR36 | conhecer: *meet / know / visit* | A2 | léxico |
| BR37 | ir/vir, levar/trazer: *go/come, take/bring* | A2 | léxico |
| BR38 | emprestar: *lend / borrow* | A2 | léxico |
| BR39 | usar/vestir e tomar: *wear/use, have/take* | A2 | léxico |
| BR40 | *job/work, trip/travel, house/home, clothes* | A2 | léxico |
| BR41 | *-ed × -ing* (*bored/boring*) | A2 | léxico |
| BR42 | Verbos sem preposição em EN (*call, ask, enter, discuss*) | A2 | regência |
| BR43 | Respostas curtas: *I think so, me neither* | A2 | idiomático |
| BR44 | Falsos cognatos do dia a dia | A2 | léxico |
| BR45 | Ortografia I: consoantes duplas dos cognatos | A2 | ortografia |
| BR46 | Ortografia II: ph/th/y, -ally, s- inicial, letras mudas, ie/ei | A2 | ortografia |
| BR47 | *since/for* + present perfect ("moro aqui há…") | B1 (CI: B1) | tempo e aspecto |
| BR48 | Imperfeito → *used to / would / past continuous* | B1 | tempo e aspecto |
| BR49 | *be/get used to + -ing* | B1 | verbo |
| BR50 | Perguntas indiretas sem inversão | B1 | ordem |
| BR51 | Preposição no fim da pergunta (*Who are you talking to?*) | B1 | ordem e regência |
| BR52 | Gerúndio × infinitivo; preposição + *-ing* | B1 (CI: A2–B1) | verbo |
| BR53 | Preposições dependentes (*depend on, wait for*) | B1 | regência |
| BR54 | *explain/suggest + to* (✗ *explain me*) | B1 | regência |
| BR55 | Comparações: *most, the same as, different from* | B1 | determinantes e regência |
| BR56 | Falsos cognatos abstratos e profissionais | B1 (CI: C1) | léxico |
| BR57 | Condicionais (*if I had / if I were*) | B1 (CI: B1) | tempo e modo |
| BR58 | Passiva × "se" impessoal | B1 (CI: B1) | voz |
| BR59 | Question tags × "né?" | B1 (CI: B1) | idiomático |
| BR60 | Phrasal verbs (evitação) | B2 (CI: B1–B2) | léxico |

---

### 6.2 Nível A1: fundação (BR01–BR20)

#### BR01 · Sujeito *it* obrigatório · A1
- **Por quê:** PT é língua de sujeito nulo. Clima, hora, distância e avaliações não têm sujeito ("Está chovendo", "É tarde", "É importante…"). O BP já preenche bastante o sujeito referencial, mas **nunca** tem expletivo [S12]. O inglês exige *it*.
- **✗** *Is raining.* · *Is very good to be here.* [S1 §3][S9]
- **Frases-modelo:**
  - `It's raining again.` | Está chovendo de novo. `[it = sujeito obrigatório, sem tradução]`
  - `It's important to test the code.` | É importante testar o código.
- **Nota:** é o primeiro ponto do curso. Dá para formar um bloco inteiro com *It's late / It's cold / It's ten o'clock / It's far*.

#### BR02 · Pronome sujeito obrigatório · A1
- **Por quê:** em PT, "Trabalha de casa" ou "Te liguei" bastam, porque o verbo marca a pessoa. Em inglês o pronome é obrigatório.
- **✗** *Works from home.* · *Called you but didn't answer.*
- **Frases-modelo:**
  - `This is Ana. She works from home.` | Essa é a Ana. Trabalha de casa.
  - `I called you, but you didn't answer.` | Te liguei, mas você não atendeu. `[⚠ atender = answer; attend = participar]`

#### BR03 · *There is/are* × *have* (existência) · A1 (CI: A1)
- **Por quê:** o BP usa *ter* para existência: "Tem muito problema na cidade" [S18]. O brasileiro traduz "tem" por *have/has*.
- **✗** *Have a problem here.* · *Has many people.* · *Not has problem.* [S1 §4][Exame/Babbel]
- **Frases-modelo:**
  - `There's a pharmacy near here.` | Tem uma farmácia aqui perto. `[There's = há/existe; lit.: Há uma farmácia perto daqui]`
  - `There are three bugs in this file.` | Tem três bugs neste arquivo.
- **Nota:** é um dos pontos de maior retorno. Volta em espiral com *There's no…*, *Is there…?*, *There must be…*, *There's been…*.

#### BR04 · *be* para idade e estados (ter anos, fome, frio, razão, medo) · A1
- **Por quê:** "ter 30 anos", "estar com fome", "ter razão" usam *ter/estar com*. O inglês usa *be* + adjetivo.
- **✗** *I have 30 years.* · *I have hungry.* · *I have cold* (que significa "estou resfriado"!) · *You have reason.* [S4][S8][S9]
- **Frases-modelo:**
  - `I'm thirty-two years old.` | Tenho trinta e dois anos. `[lit.: Eu sou 32 anos velho]`
  - `I'm cold and hungry.` | Estou com frio e com fome.
- **Família no mesmo bloco:** *be right* (ter razão), *be afraid* (ter medo), *be in a hurry* (estar com pressa), *be lucky* (ter sorte), *be careful* (tomar cuidado) [S4].

#### BR05 · *this morning / tonight / this week* · A1
- **Por quê:** "hoje de manhã", "hoje à noite" e "nesta semana" puxam *today in the morning*, *today at night*, *in this week* [S1 §12].
- **✗** *Today in the morning.* · *Today at night.* · *In this week.*
- **Frases-modelo:**
  - `I have a meeting this afternoon.` | Tenho uma reunião hoje à tarde.
  - `What are you doing tonight?` | O que você vai fazer hoje à noite? `[hoje à noite = tonight]`

#### BR06 · Perguntas com *do/does/did* · A1 (CI: A1)
- **Por quê:** em PT a pergunta é só entonação: "Ele fala inglês?". O inglês exige auxiliar e inversão [S1 §1]. Os corpora brasileiros apontam perguntas e auxiliares entre as categorias de erro mais frequentes [S30].
- **✗** *He speaks English?* · *You saw my message?*
- **Frases-modelo:**
  - `Does she speak English?` | Ela fala inglês? `[does = marca de pergunta, sem tradução]`
  - `Did you see my message?` | Você viu minha mensagem?

#### BR07 · Negativas com *don't/doesn't/didn't* · A1 (CI: A1)
- **Por quê:** "não" vai direto antes do verbo em PT [S1 §1].
- **✗** *I not drink coffee.* · *He not speaks English.* · *It not works.*
- **Frases-modelo:**
  - `I don't drink coffee.` | Eu não tomo café.
  - `It doesn't work on my phone.` | Não funciona no meu celular. `[sujeito it + doesn't]`

#### BR08 · Adjetivo antes do substantivo · A1 (CI: A1)
- **Por quê:** em PT o adjetivo vem normalmente depois do nome.
- **✗** *a car red* · *a contract big and complex* [S7]
- **Frases-modelo:**
  - `She has a red car.` | Ela tem um carro vermelho. `[lit.: um vermelho carro]`
  - `We need a simple and fast solution.` | Precisamos de uma solução simples e rápida.

#### BR09 · Adjetivo não vai ao plural · A1
- **Por quê:** em PT o adjetivo concorda ("opiniões diferentes", "outras pessoas").
- **✗** *differents opinions* · *others people* · *importants things*
- **Frases-modelo:**
  - `We have different opinions.` | Temos opiniões diferentes. `[adjetivo nunca leva -s]`
  - `Other people use this library too.` | Outras pessoas também usam essa biblioteca.
- **Nota:** *others* existe, mas só como pronome (*Some like it, others don't*).

#### BR10 · Genitivo *'s* · A1 (CI: A1 "Possessive s")
- **Por quê:** o PT diz "o carro do meu pai"; o inglês prefere *my father's car*.
- **✗** *the car of my father* · *the app of the client*
- **Frases-modelo:**
  - `My father's car is old.` | O carro do meu pai é velho. `[lit.: Meu pai-de carro]`
  - `We fixed the bug in the client's app.` | Corrigimos o bug no app do cliente.

#### BR11 · *his/her/their* × seu/sua · A1
- **Por quê:** "seu/sua" concorda com a coisa possuída e serve para você, ele, ela e eles [S1 §13]. Em inglês o possessivo concorda com o **dono**.
- **✗** *Maria called his mother* (a mãe dela) · *This is your book* (o livro dele)
- **Frases-modelo:**
  - `Maria called her mother.` | A Maria ligou para a mãe dela. `[her = dela]`
  - `Paulo left his keys here.` | O Paulo esqueceu as chaves dele aqui. `[esquecer algo EM um lugar = leave (left); forget só sem o lugar: I forgot my keys]`
- **Nota para a tradução:** é aqui que o PT precisa explicitar "dele/dela" (T5). *left* × *forgot* é erro documentado [S6].

#### BR12 · Sem artigo antes de nomes de pessoas, países, cidades e empresas · A1
- **Por quê:** "O Brasil", "A Maria", "A IBM" [S1 §9][S7].
- **✗** *The Brazil is huge.* · *The Maria works at the Google.* · *The Mr. Jones…*
- **Frases-modelo:**
  - `Brazil is a huge country.` | O Brasil é um país enorme.
  - `Ana works at Google.` | A Ana trabalha no Google.
- **Exceções para o anexo:** *the United States*, *the UK*, *the Netherlands*, *the Philippines*.

#### BR13 · *a/an* com profissões; *a* ≠ *one* · A1
- **Por quê:** "Sou desenvolvedor" dispensa artigo. "Um" é artigo e numeral, e *one* aparece onde cabe *a* [S1 §8].
- **✗** *I'm developer.* · *She is engineer.* · *I have one problem* (quando o sentido é só "um problema")
- **Frases-modelo:**
  - `I'm a software developer.` | Sou desenvolvedor de software.
  - `She's an engineer at a bank.` | Ela é engenheira num banco. `[an antes de som de vogal]`

#### BR14 · *people* é plural; "muita gente" = *many people* · A1
- **Por quê:** "gente" e "o povo" são singulares em PT.
- **✗** *People is tired.* · *A lot of people uses this app.* [S7][Exame]
- **Frases-modelo:**
  - `People are tired of long meetings.` | As pessoas estão cansadas de reuniões longas.
  - `A lot of people use this app.` | Muita gente usa esse app. `[gente (singular) → people (plural)]`
- **Mesma família:** *police are*, *children are*. Mas *the team is* no inglês americano [S7].

#### BR15 · Maiúsculas: *I*, dias, meses, línguas, nacionalidades · A1
- **Por quê:** em PT, segunda-feira, janeiro, português e brasileiro vão em minúscula. Em inglês, maiúscula, e *I* é sempre maiúsculo. No curso de digitação isto aparece letra a letra.
- **✗** *i speak portuguese.* · *See you on monday.* · *She's brazilian.*
- **Frases-modelo:**
  - `I'm Brazilian and I speak Portuguese.` | Sou brasileiro e falo português.
  - `See you on Monday, January 5.` | Até segunda, 5 de janeiro.
- **Nota:** estações do ano ficam em minúscula (*summer*). O motor deve diferenciar maiúscula de minúscula **neste ponto**.

#### BR16 · *go home / at work / go to bed* (sem artigo, sem *to*) · A1
- **Por quê:** "ir para casa", "estar no trabalho", "ir para a cama".
- **✗** *I'm going to home.* · *She's in the work.* · *Go to the bed.*
- **Frases-modelo:**
  - `I'm going home now.` | Estou indo para casa agora. `[home sem to]`
  - `She's at work until six.` | Ela está no trabalho até as seis.

#### BR17 · *in / on / at* (tempo e lugar) · A1 (CI: A1)
- **Por quê:** "em" cobre os três. Os erros mais frequentes de lusófonos são *in* por *at*, *in* por *on* e *on* por *in* [S6].
- **✗** *in Monday* · *in 9 o'clock* · *in the internet* · *in the bus*
- **Nota en-US:** *on the weekend* é o padrão americano (o britânico diz *at the weekend*).
- **Frases-modelo:**
  - `The meeting is on Monday at nine.` | A reunião é na segunda às nove. `[on + dia; at + hora]`
  - `I saw it on the internet.` | Vi isso na internet. `[na internet = on the internet]`
- **Regra-resumo para a glosa:** *in* = mês, ano, cidade, país; *on* = dia, data, superfície, internet, ônibus; *at* = hora, ponto exato, endereço com número, *at work*, *at home*.

#### BR18 · Pronome objeto obrigatório · A1
- **Por quê:** o PT omite o objeto ("Gostou? Adorei!", "Já contei"). Em inglês ele é obrigatório [S8].
- **✗** *Did you like? Yes, I loved.* · *I told.*
- **Frases-modelo:**
  - `Did you like it? Yes, I loved it.` | Você gostou? Sim, adorei. `[it obrigatório]`
  - `I told him the truth.` | Contei a verdade para ele. `[told him, sem to]`

#### BR19 · Ordem: advérbios (*very much*, *always*, *well*) e "mais três" · A1
- **Por quê:** "gosto **muito** de café" põe o advérbio no meio, e "**mais** três dias" põe *more* antes do número [S8].
- **✗** *I like very much coffee.* · *I go always.* · *I speak well English.* · *more three days*
- **Frases-modelo:**
  - `I like coffee very much.` | Eu gosto muito de café. `[very much no fim]`
  - `I need three more days.` | Preciso de mais três dias. `[número + more]`
- **Nota:** advérbio de frequência vai antes do verbo principal (*We always test*) e depois de *be* (*She's always late*).

#### BR20 · *watch / see / look at / hear / listen to* · A1
- **Por quê:** "assistir" vira *assist* (falso cognato). "Escutar música" e "olhar a tela" vêm sem preposição [S1 §16][S2].
- **✗** *We assisted a movie.* · *Listen this song.* · *Look the screen.*
- **Frases-modelo:**
  - `We watched a movie last night.` | Assistimos a um filme ontem à noite. `[⚠ assistir = watch; assist = ajudar]`
  - `Listen to this song!` | Escuta essa música! `[listen TO]`

---

### 6.3 Nível A2: base (BR21–BR46)

#### BR21 · Artigo zero em generalizações · A2 (CI: A2 "Articles")
- **Por quê:** o PT usa artigo definido no genérico ("A vida é curta", "O café está caro"). Estudos com aprendizes lusófonos mostram uso excessivo de *the* em contextos genéricos [S30]. É uma das correções mais citadas [S7].
- **✗** *The life is short.* · *The coffee is more expensive this year.* · *I love the music.*
- **Frases-modelo:**
  - `Life is short.` | A vida é curta.
  - `Coffee is more expensive this year.` | O café está mais caro este ano. `[genérico: sem the]`

#### BR22 · Incontáveis (*information, advice, news, software, code, feedback, equipment, furniture, homework, research*) · A2 (CI: A2)
- **Por quê:** em PT "informações", "conselhos" e "móveis" são contáveis. O Wiktionary marca *informations*, *softwares* e *feedbacks* como não-padrão e típicos de não nativos [S25]. *Code*, no sentido de programação, é incontável (*I wrote some code*) [S25]. Ver também [S1 §15].
- **✗** *How many informations…?* · *some advices* · *two softwares* · *I wrote many codes* · *Thanks for the feedbacks*
- **Frases-modelo:**
  - `We need more information about the error.` | Precisamos de mais informações sobre o erro. `[information nunca leva -s]`
  - `Can you give me some advice?` | Você pode me dar uns conselhos?
- **Bloco extra dev:** `I wrote a lot of code today.` / `Thanks for the feedback.` / `We use three pieces of software.`

#### BR23 · "muito": *very / much / many / a lot / too* · A2 (CI: A1–A2)
- **Por quê:** "muito" cobre intensidade, quantidade contável e incontável, e "demais" cobre o excesso.
- **✗** *very people* · *much problems* · *It's very expensive, I can't buy* (quando o sentido é *too*)
- **Frases-modelo:**
  - `I don't have much time today.` | Não tenho muito tempo hoje.
  - `There are too many meetings this week.` | Tem reunião demais esta semana. `[too many = excesso]`

#### BR24 · Substantivo + substantivo · A2
- **Por quê:** o PT encadeia com "de" ("mensagem de erro", "botão de login"). O inglês põe o modificador antes, sem *of*. Para dev é onipresente.
- **✗** *a message of error* · *the button of login* · *the page of settings*
- **Frases-modelo:**
  - `I got an error message.` | Recebi uma mensagem de erro. `[lit.: uma erro mensagem]`
  - `Click the login button.` | Clique no botão de login.

#### BR25 · Dupla negação · A2
- **Por quê:** em PT, "Não tenho **nada**" e "Não tem **ninguém**" são normais. Em inglês padrão, uma negação basta [S1 §7][S8].
- **✗** *I don't have nothing.* · *There's not nobody home.* · *I couldn't do nothing.*
- **Frases-modelo:**
  - `I don't have any questions.` | Não tenho nenhuma pergunta. `[not + any]`
  - `There's nothing I can do.` | Não tem nada que eu possa fazer.

#### BR26 · "há" = *ago* × "por" = *for* · A2
- **Por quê:** "há dois anos" (passado) vira *there are two years* ou *before two years*, e "por dois anos" se confunde com o *ago*.
- **✗** *I moved here there are two years.* · *I moved here before two years.*
- **Frases-modelo:**
  - `I moved here two years ago.` | Eu me mudei para cá há dois anos. `[há + passado terminado = ago, no fim]`
  - `I lived in Rio for two years.` | Morei no Rio por dois anos. `[duração terminada = for]`
- **Ponte para BR47:** "**há** + algo que continua" vira *for* + present perfect.

#### BR27 · Present perfect × simple past · A2 (CI: present perfect A2; contraste B1)
- **Por quê:** não há tempo verbal equivalente em PT. O present perfect corresponde ao presente, ao pretérito perfeito simples ou ao composto, conforme o contexto [S11]. Brasileiros tendem a usar o simple past ou a usar o perfect com tempo definido [S7 #16].
- **✗** *I have seen him yesterday.* · *I have finished it last week.*
- **Nota en-US:** *Did you ever go to Chile?* é aceitável no americano informal. Entra em `en_variantes`, mas o canônico da lição é o perfect.
- **Frases-modelo:**
  - `Have you ever been to Chile?` | Você já foi ao Chile? `[experiência, sem data → have + particípio]`
  - `I went to Santiago in 2019.` | Fui a Santiago em 2019. `[data definida → passado simples]`
- **Nota para a tradução:** usar as âncoras de T10. Em `en_variantes`, aceitar a forma americana informal só nos modos de recuperação.

#### BR28 · Futuro do subjuntivo → presente (*when / if / as soon as*) · A2 (CI: "zero and 1st conditional" A2)
- **Por quê:** "quando eu chegar" e "se você precisar" têm forma de futuro em PT. O inglês usa presente depois de *when* e *if*.
- **✗** *I'll call you when I will get home.* · *If you will need help…*
- **Frases-modelo:**
  - `I'll call you when I get home.` | Te ligo quando eu chegar em casa. `[quando eu chegar = when I get]`
  - `If you need help, let me know.` | Se você precisar de ajuda, me avisa.

#### BR29 · Planos com present continuous / *going to* · A2 (CI: "present continuous for future" A2)
- **Por quê:** o PT usa presente simples para planos ("Amanhã eu viajo", "Sábado eu trabalho").
- **✗** *Tomorrow I travel to Recife.* · *What do you do this weekend?* (quando o sentido é plano)
- **Frases-modelo:**
  - `I'm traveling to Recife tomorrow.` | Amanhã eu viajo para Recife. `[plano marcado → be + -ing; traveling com um l só, en-US]`
  - `What are you doing this weekend?` | O que você vai fazer neste fim de semana?

#### BR30 · Modais sem *to*; finalidade com *to* (não *for to* nem *for -ing*) · A2 (CI: A1–A2)
- **Por quê:** "posso fazer" e "vim **para** falar" levam a *can to* e *for to* [S1 §5–6]. *For + -ing* com valor de finalidade é erro característico de lusófonos [S6].
- **✗** *You can to take a bus.* · *I came for to talk.* · *…a bus for going to the park.*
- **Frases-modelo:**
  - `You can take a bus to get there.` | Você pode pegar um ônibus para chegar lá. `[can + verbo puro; para + verbo = to]`
  - `I came here to talk to you.` | Vim aqui para falar com você.

#### BR31 · *say / tell / speak / talk* (dizer, contar, falar, conversar) · A2
- **Por quê:** "dizer" e "falar" se sobrepõem em PT. *Tell* exige pessoa (*tell me*), *say* não [S1 §10][S8].
- **✗** *He told that…* · *She said me…* · *I said for her…* · *I talk English.*
- **Frases-modelo:**
  - `She said she couldn't come, but she didn't tell me why.` | Ela disse que não podia vir, mas não me disse por quê. `[say algo; tell alguém]`
  - `Do you speak English? Can we talk for a minute?` | Você fala inglês? A gente pode conversar um minuto? `[idioma = speak; conversar = talk]`

#### BR32 · *make × do* (+ *ask, have, take*) · A2
- **Por quê:** "fazer" cobre tudo [S7][S8][S9].
- **✗** *make my homework* · *make a question* · *do a mistake* · *make a party*
- **Frases-modelo:**
  - `I made a mistake, so I have to do it again.` | Eu cometi um erro, então tenho que fazer de novo. `[make = criar/produzir; do = executar tarefa]`
  - `Can I ask you a question?` | Posso te fazer uma pergunta? `[fazer pergunta = ask]`
- **Colocações para o bloco:** *do homework / the dishes / exercise / a favor*; *make a decision / money / a call / a plan*; *have a party / a meeting / surgery*; *take a picture / a test / a break*.

#### BR33 · ficar · A2
- **Por quê:** "ficar" pode ser *get* (mudar de estado), *be* (localização), *stay* (permanecer), *keep* (ficar com), *look* (ficar bem) e *be left* (sobrar).
- **✗** *I stayed nervous.* · *Where stays the hotel?*
- **Frases-modelo:**
  - `I got really nervous before the interview.` | Fiquei muito nervoso antes da entrevista. `[ficar + emoção = get]`
  - `Where's the hotel?` | Onde fica o hotel? `[localização = be]`
- **Mais para o bloco:** *Stay here.* (Fica aqui.) · *Keep the change.* (Fica com o troco.) · *That looks good on you.* (Ficou bom em você.)

#### BR34 · perder: *lose / miss / waste* · A2
- **✗** *I lost the bus.* · *Don't lose time.*
- **Frases-modelo:**
  - `I missed the bus again.` | Perdi o ônibus de novo. `[perder ônibus, voo, aula = miss]`
  - `Don't waste time on that.` | Não perca tempo com isso. `[perder tempo = waste]`
- **Nota:** *lose* = perder objeto ou jogo (*I lost my keys*, *We lost the game*).

#### BR35 · ganhar: *win / earn / get / gain* · A2
- **✗** *I win a good salary.* · *I won a gift from my boss.*
- **Frases-modelo:**
  - `She earns more than I do.` | Ela ganha mais do que eu. `[salário = earn / make]`
  - `I got a gift from my boss.` | Ganhei um presente do meu chefe. `[receber = get]`
- **Nota:** *win* = jogo, prêmio, competição. *Gain weight* = ganhar peso.

#### BR36 · conhecer: *meet / know / visit / get to know* · A2
- **✗** *I knew my wife at work.* · *I want to know Japan.*
- **Frases-modelo:**
  - `I met my wife at work.` | Conheci minha esposa no trabalho. `[conhecer pessoa pela 1ª vez = meet]`
  - `I'd love to visit Japan someday.` | Eu adoraria conhecer o Japão um dia. `[conhecer lugar = visit / see]`

#### BR37 · ir/vir, levar/trazer: *go/come, take/bring* · A2
- **Por quê:** "Já vou!" (indo até quem chama) vira *I'm going*. Lusófonos usam *go* por *come* com frequência [S6]. Ver também [S9].
- **✗** *I'm going!* (resposta a quem chama) · *Can you go to my house?* (quando o sentido é *come*)
- **Frases-modelo:**
  - `I'm coming! Just a second.` | Já vou! Só um segundo. `[em direção a quem fala = come]`
  - `Can you bring your laptop tomorrow?` | Você pode trazer seu notebook amanhã? `[para cá = bring; para lá = take]`

#### BR38 · emprestar: *lend / borrow* · A2
- **✗** *Can you borrow me your charger?*
- **Frases-modelo:**
  - `Can you lend me your charger?` | Você pode me emprestar seu carregador? `[dar emprestado = lend]`
  - `Can I borrow your charger?` | Posso pegar seu carregador emprestado? `[pegar emprestado = borrow]`

#### BR39 · usar/vestir e tomar: *wear/use, have/take/drink* · A2
- **Por quê:** "usar óculos" e "usar roupa" levam a *use* por *wear*, um dos verbos mais confundidos por lusófonos [S6]. "Tomar" serve para café, banho, remédio e café da manhã [S9].
- **✗** *She always uses black.* · *I take breakfast at seven.*
- **Frases-modelo:**
  - `She always wears black.` | Ela sempre usa preto. `[roupa, óculos, perfume = wear]`
  - `I usually have breakfast at seven.` | Normalmente tomo café da manhã às sete. `[refeição = have]`
- **Mais:** *take a shower*, *take medicine*, *drink water*.

#### BR40 · *job/work, trip/travel, house/home, clothes* · A2
- **Por quê:** substantivos que lusófonos mais confundem, segundo [S6]: *work* por *job*, *travel* por *trip*, *home* por *house*, *cloth* por *clothes*.
- **✗** *I got a new work.* · *The travel was great.*
- **Frases-modelo:**
  - `I got a new job!` | Arrumei um trabalho novo! `[um emprego = a job; work é incontável]`
  - `How was your trip?` | Como foi a viagem? `[uma viagem = a trip; travel = viajar, em geral]`

#### BR41 · *-ed × -ing* (*bored/boring, interested/interesting*) · A2 (CI: A2 adjetivos de sentimento)
- **Por quê:** "estou entediado" e "é chato" são palavras diferentes em PT, mas as duas formas inglesas são parecidas.
- **✗** *I'm boring* (no sentido de entediado) · *I'm very interesting in…*
- **Frases-modelo:**
  - `This meeting is boring.` | Esta reunião está chata. `[-ing = causa]`
  - `I'm bored. Let's do something.` | Estou entediado. Vamos fazer alguma coisa. `[-ed = como eu me sinto]`

#### BR42 · Verbos sem preposição em inglês · A2
- **Por quê:** "ligar **para**", "perguntar **para**", "entrar **em**", "discutir **sobre**", "precisar **de**", "gostar **de**", "participar **de**", "casar **com**" [S1 §16][S7].
- **✗** *call to him* · *ask to him* · *enter in the room* · *discuss about* · *I need of help* · *I like of coffee* · *participate of a seminar*
- **Frases-modelo:**
  - `Call me when you get there.` | Me liga quando chegar lá. `[call alguém, sem to]`
  - `We discussed the new design.` | Discutimos sobre o novo design. `[discuss algo, sem about]`
- **Lista para o bloco:** *call, ask, tell, enter, discuss, need, like, attend (a meeting), answer, marry, reach, approach, join*.

#### BR43 · Respostas curtas e eco · A2
- **Por quê:** "Acho que sim", "Nem eu", "Eu também" e "Espero que sim" viram decalque [S1 §14][S4].
- **✗** *I think that yes.* · *Me too not.* · *I hope that yes.*
- **Frases-modelo:**
  - `Is it going to rain? I think so.` | Será que vai chover? Acho que sim.
  - `I don't like it. Me neither.` | Eu não gosto. Nem eu.
- **Mais:** *I hope so / I hope not / So do I / Neither do I / I guess so*.

#### BR44 · Falsos cognatos do dia a dia · A2
- **Por quê:** palavras concretas de alta frequência com armadilha [S2]. O Core Inventory põe "eliminating false friends" no C1 [S27], mas estas são frequentes demais para esperar.
- **✗** *My parents live in Bahia* (querendo dizer os parentes) · *Pull* (no sentido de empurrar) · *I'm going to the library to buy a book.*
- **Frases-modelo:**
  - `My parents live in Curitiba, but my relatives live in Bahia.` | Meus pais moram em Curitiba, mas meus parentes moram na Bahia. `[⚠ parents = pais; parentes = relatives]`
  - `Push the door. Don't pull it.` | Empurra a porta. Não puxa. `[⚠ push = empurrar; puxar = pull]`
- **Mais para o bloco (ver Anexo A):** *college* (faculdade), *library* (biblioteca), *lunch* (almoço), *novel* (romance), *exquisite* (refinado), *costume* (fantasia), *fabric* (tecido), *prejudice* (preconceito), *stupid* (burro, não "grosso").

#### BR45 · Ortografia I: consoantes duplas dos cognatos · A2 (e em todos os níveis)
- **Por quê:** o cognato PT tem letra simples e o EN tem dupla. Entre as palavras que lusófonos mais erram estão *different*, *accommodation*, *beginning*, *comfortable* (*confortable*) e *always* (*allways*, a dupla no lugar errado) [S6]. Mais de duas dúzias das palavras mais mal escritas do Oxford Corpus envolvem letras duplas [S23][S24].
- **✗** *comunity*, *diferent*, *oportunity*, *eficient*, *recomend*, *acommodation*, *sucess*, *atention*, *imediately*
- **Frases-modelo:**
  - `Our community needs better communication.` | Nossa comunidade precisa de uma comunicação melhor. `[comm-: mm]`
  - `This approach is different and more efficient.` | Essa abordagem é diferente e mais eficiente. `[pp, ff, ff]`
- **Lista por padrão no Anexo C.**

#### BR46 · Ortografia II: ph/th/y, -ally, s- inicial, wh-, letras mudas, ie/ei · A2 (e em todos os níveis)
- **Por quê:** o PT simplificou *ph* em *f*, *th* em *t* e *y* em *i* (teoria, sistema, foto), e põe *e-* antes de *s* + consoante (estrutura, especial). *-mente* vira *-ally* com **ll**. O EN tem letras mudas (*answer*, *right*, *Wednesday*, *which*: a Cambridge registra *wich* [S6]). E há ie/ei (*believe*, que vira *belive* [S6]; *receive*).
- **✗** *teory*, *sistem*, *foto* (como palavra formal), *especific*, *estructure*, *finaly*, *realy*, *wich*, *anwser*, *lenght*, *heigth*, *recieve*
- **Frases-modelo:**
  - `The theory of this system is simple.` | A teoria deste sistema é simples. `[th, y]`
  - `I finally wrote the right answer.` | Finalmente escrevi a resposta certa. `[finally = ll; w, gh e w mudos]`

---

### 6.4 Nível B1: intermediário (BR47–BR59)

#### BR47 · *since/for* + present perfect para o que continua · B1 (CI: "present perfect continuous" B1)
- **Por quê:** "Moro aqui **há** cinco anos" e "Trabalho aqui **desde** 2022" usam presente em PT. O inglês exige present perfect [S7 #14–15][S11].
- **✗** *I live here for five years.* · *I work here since 2022.* · *I am working here for two years.*
- **Frases-modelo:**
  - `I've lived here for five years.` | Moro aqui há cinco anos. `[algo que continua + há = have + particípio + for]`
  - `I've worked here since 2022.` | Trabalho aqui desde 2022. `[since + ponto de início]`
- **Extensão (continuous):** `I've been waiting for an hour.` | Estou esperando há uma hora.

#### BR48 · Imperfeito → *used to / would / past continuous* · B1 (CI: "would for past habits" B2)
- **Por quê:** o imperfeito ("eu jogava", "eu estava almoçando") não tem tempo único em inglês. O brasileiro alterna mal entre *used to*, passado simples e passado contínuo.
- **✗** *When I was a child, I was playing soccer every day* (no sentido de hábito) · *I use to play* (sem -d)
- **Frases-modelo:**
  - `I used to play soccer every day.` | Eu jogava futebol todo dia. `[hábito que acabou = used to; costumava]`
  - `We were having lunch when he called.` | Estávamos almoçando quando ele ligou. `[ação em andamento interrompida]`
- **Nota para a tradução:** traduzir *used to* pelo imperfeito, não por "costumava", que fica artificial (T10) [S33].

#### BR49 · *be/get used to + -ing* · B1
- **Por quê:** a forma é igual a *used to* (hábito passado), mas o sentido é "estar acostumado". O *to* é preposição e pede *-ing*.
- **✗** *I'm used to work at night.* · *I used to working…*
- **Frases-modelo:**
  - `I'm used to working at night.` | Estou acostumado a trabalhar à noite. `[be used to + -ing]`
  - `Don't worry, you'll get used to it.` | Fica tranquilo, você vai se acostumar. `[get used to = se acostumar]`

#### BR50 · Perguntas indiretas sem inversão · B1
- **Por quê:** o aluno acabou de aprender a inverter (BR06) e inverte também na pergunta embutida. O PT não marca a diferença [S7 #25].
- **✗** *Do you know where is the meeting?* · *Can you tell me what time is it?*
- **Frases-modelo:**
  - `Do you know where the meeting is?` | Você sabe onde é a reunião? `[dentro da pergunta: ordem normal]`
  - `Can you tell me what time it is?` | Você pode me dizer que horas são?

#### BR51 · Preposição no fim da pergunta · B1
- **Por quê:** em PT a preposição abre a pergunta ("**Com** quem você está falando?"). Em inglês ela vai para o fim, e muitos brasileiros a omitem mesmo no nível avançado [S30].
- **✗** *Who are you talking?* · *With who are you talking?* · *What are you looking?*
- **Frases-modelo:**
  - `Who are you talking to?` | Com quem você está falando? `[com quem… → who… to]`
  - `What are you looking for?` | O que você está procurando? `[⚠ procurar = look for; procure = adquirir]`

#### BR52 · Gerúndio × infinitivo; preposição + *-ing* · B1 (CI: A2 "verb + ing/infinitive"; B1 ampliação)
- **Por quê:** o PT usa infinitivo depois de preposição ("obrigado **por** ajudar", "antes **de** reiniciar"). O inglês usa *-ing*. Os verbos que pedem *-ing* ou *to* não têm paralelo em PT [S1 §18].
- **✗** *Thanks for help me.* · *before to restart* · *I enjoy to code.* · *I want working.*
- **Frases-modelo:**
  - `Thanks for helping me.` | Obrigado por me ajudar. `[preposição + -ing]`
  - `Check the logs before restarting the server.` | Verifique os logs antes de reiniciar o servidor.
- **Lista para o bloco:** *enjoy / avoid / finish / mind / keep + -ing*; *want / need / decide / plan / hope + to*; *stop + -ing* (parar de) × *stop + to* (parar para).

#### BR53 · Preposições dependentes · B1
- **Por quê:** a preposição vem do verbo ou do adjetivo e difere do PT [S7 #8–10]. Mairo: preposições "não funcionam" por tradução um a um [S16].
- **✗** *depend of* · *dream with* · *married with* · *interested on* · *good in* · *worried with* · *arrive to* · *wait the bus* · *think in*
- **Frases-modelo:**
  - `It depends on the client.` | Depende do cliente. `[depender de = depend on]`
  - `I'm waiting for the bus.` | Estou esperando o ônibus. `[esperar alguém/algo = wait for]`
- **Lista completa no Anexo B.**

#### BR54 · *explain / suggest / describe / recommend + to* (✗ *explain me*) · B1
- **Por quê:** "me explica" e "me sugeriu" põem a pessoa direto depois do verbo. Em inglês ela vai depois de *to* ou sai da frase. *Explain, described, mentioned, recommended, suggested* só aceitam objeto indireto com preposição [S3].
- **✗** *Can you explain me this?* · *She suggested me to use Flutter.* · *Describe me…*
- **Frases-modelo:**
  - `Can you explain it to me again?` | Você pode me explicar de novo? `[explain algo TO alguém]`
  - `She suggested that I use Flutter.` | Ela me sugeriu usar Flutter. `[suggest that + sujeito + verbo]`

#### BR55 · Comparações: *most*, *the same as*, *different from*, *similar to* · B1
- **Por quê:** "a maioria **das** pessoas", "igual **ao**", "diferente **de**", "parecido **com**".
- **✗** *The most of the people…* · *the same of* · *different of* · *more big* · *more good*
- **Frases-modelo:**
  - `Most people prefer dark mode.` | A maioria das pessoas prefere o modo escuro. `[a maioria das = most, sem the/of]`
  - `My phone is the same as yours.` | Meu celular é igual ao seu. `[igual a = the same as]`

#### BR56 · Falsos cognatos abstratos e profissionais · B1 (CI: C1)
- **Por quê:** são palavras de reunião, e-mail e documentação [S2][S7].
- **✗** *Actually, I work at…* (atualmente) · *I pretend to finish today* · *We realized the project* · *I'll assist the meeting* · *Eventually we deploy on Fridays* (às vezes)
- **Frases-modelo:**
  - `Actually, I don't agree.` | Na verdade, eu não concordo. `[⚠ actually = na verdade; atualmente = currently]`
  - `I didn't realize it was so late.` | Não percebi que já era tão tarde. `[⚠ realize = perceber; realizar = carry out]`
- **Mais (Anexo A):** *eventually* (no fim), *pretend* (fingir), *assume* (supor), *attend* (participar), *assist* (ajudar), *support* (apoiar), *resume* (retomar), *compromise* (acordo; ou "comprometer" a segurança), *argument* (discussão), *policy* (política, diretriz), *particular* (específico), *data* (dados).

#### BR57 · Condicionais (*if I had / if I were*) · B1 (CI: 2º e 3º B1; misto B2)
- **Por quê:** "Se eu tivesse" e "se eu fosse" (imperfeito do subjuntivo) puxam *would* para dentro do *if*. Lusófonos também usam presente onde caberia passado em condicionais [S6].
- **✗** *If I would have time, I would go.* · *If I have more time, I would learn…*
- **Frases-modelo:**
  - `If I had more time, I would learn Japanese.` | Se eu tivesse mais tempo, aprenderia japonês. `[if + passado; would na outra metade]`
  - `If I were you, I'd take the job.` | Se eu fosse você, aceitaria o emprego.

#### BR58 · Passiva × "se" impessoal · B1 (CI: "simple passive" B1)
- **Por quê:** "Fala-se", "Vende-se" e "Os testes rodam" são estruturas sem agente que o inglês resolve com passiva (ou com *they/you*).
- **✗** *Speaks English here.* · *Sells this house.* · *The tests run on every commit* (aceitável, mas o ponto da lição é a passiva)
- **Frases-modelo:**
  - `English is spoken in many countries.` | Fala-se inglês em muitos países. `[se impessoal → be + particípio]`
  - `The tests are run on every commit.` | Os testes rodam a cada commit.

#### BR59 · Question tags × "né?" · B1 (CI: "complex question tags" B1)
- **Por quê:** o "né?" é invariável. O inglês concorda auxiliar e pessoa. O brasileiro usa *no?* ou *isn't it?* para tudo [S8].
- **✗** *You're Brazilian, no?* · *She is late, isn't it?*
- **Frases-modelo:**
  - `You're from Brazil, aren't you?` | Você é do Brasil, né? `[né = tag que espelha o verbo]`
  - `It works now, doesn't it?` | Agora funciona, né?

### 6.5 Nível B2: intermediário superior (BR60)

#### BR60 · Phrasal verbs (evitação) · B2 (CI: comuns A2, ampliados B1, "splitting" B2)
- **Por quê:** o PT não tem verbo + partícula com sentido opaco. O brasileiro **evita** phrasal verbs e usa o cognato latino (*discover*, *continue*, *extinguish*, *tolerate*). A frase fica correta, mas soa rígida. É interferência por omissão, que os corpora registram como "escolha lexical" [S30].
- **✗ (não natural)** *I discovered that the bug was…* · *Don't desist, continue!*
- **Frases-modelo:**
  - `I found out that the bug was in the cache.` | Descobri que o bug estava no cache. `[find out = descobrir (uma informação)]`
  - `Don't give up. Keep going!` | Não desista. Continue! `[give up = desistir; keep going = continuar]`
- **Bloco sugerido:** *figure out, set up, look up, turn on/off, log in, sign up, run into, put up with, come up with, carry on, show up, get along*.

---

## 7. Como lidar com frases sem equivalente direto (receitas)

| Caso | Receita | Exemplo |
|---|---|---|
| Sujeito vazio (*it/there*) | PT natural sem sujeito + glosa marcando o sujeito | "Está tarde." → `It's late.` `[it obrigatório]` |
| Auxiliar *do* | PT natural + glosa "marca de pergunta/negação" | "Você mora aqui?" → `Do you live here?` |
| Phrasal verb transparente | sentido + glosa da partícula | "Senta aí." → `Sit down.` `[down = para baixo]` |
| Phrasal verb opaco | sentido + glosa do bloco | "Descobri por acaso." → `I found out by accident.` `[find out = descobrir]` |
| Idiom com par em PT | idiom PT + literal como gancho | "Não é a minha praia." → `It's not my cup of tea.` |
| Idiom sem par | paráfrase + literal | "Boa sorte! (no palco)" → `Break a leg!` |
| *used to* | imperfeito | "Eu morava em Recife." → `I used to live in Recife.` |
| Present perfect | âncora temporal | "Ainda não terminei." → `I haven't finished yet.` |
| *get* (polissêmico) | traduzir pelo contexto e glosar o sentido | "Ficou escuro." → `It got dark.` `[get = ficar (mudança)]` |
| Tags e marcadores | "né?", "bom", "então", "quer dizer" | `Well, I mean, it works.` → "Bom, quer dizer, funciona." |
| Polidez | PT polido equivalente, sem decalque | `Would you mind closing the door?` → "Você se importa de fechar a porta?" |
| Interjeições | equivalente brasileiro | `Oops!` → "Opa!" · `Wow!` → "Nossa!" · `Come on!` → "Qual é!" / "Vamos!" |
| *you* genérico | "a gente" / "você" impessoal / "se" | `You never know.` → "Nunca se sabe." |
| Cultura | localizar o sentido e manter a palavra EN | `Can I get the check?` → "(restaurante) Me vê a conta?" |

---

## 8. Anexos

### Anexo A · Falsos cognatos priorizados (base: Schütz [S2] + notas dev)

| EN | Significa | Armadilha PT | Como se diz o que o brasileiro queria | Nível | Nota dev |
|---|---|---|---|---|---|
| actually | na verdade | atualmente | currently, nowadays | A2/B1 | onipresente em reuniões |
| eventually | no fim, finalmente | eventualmente | occasionally, sometimes | B1 | *eventual consistency* = consistência "no fim das contas" |
| pretend | fingir | pretender | intend, plan | B1 | |
| realize | perceber | realizar | carry out, accomplish | B1 | |
| assume | supor | assumir | take over, take on | B1 | |
| attend | participar, comparecer | atender | answer (telefone), serve, help | A2 | *attend a meeting* |
| assist | ajudar | assistir | watch, attend | A2 | |
| support | apoiar, dar suporte | suportar | stand, put up with | B1 | *support team* = suporte (ok) |
| resume | retomar | resumir | summarize | B1 | *resume the download* |
| résumé / resume | currículo (en-US) | resumo | summary | B1 | |
| parents | pais | parentes | relatives | A1/A2 | |
| college | faculdade | colégio | high school | A2 | |
| library | biblioteca | livraria | bookstore | A2 | em código, *library* = biblioteca (ok!) |
| lunch | almoço | lanche | snack | A1 | |
| push / pull | empurrar / puxar | puxar | pull | A1 | |
| novel | romance (livro) | novela | soap opera | B1 | |
| exquisite | refinado, belo | esquisito | weird, strange | B1 | |
| costume | fantasia | costume | habit, custom | B1 | |
| fabric | tecido | fábrica | factory | B1 | |
| data | dados | data | date | A2 | essencial para dev |
| application | inscrição; aplicativo; uso | aplicação (financeira) | investment | A2 | *job application* |
| argument | discussão, briga; argumento (em código) | argumento | point, reasoning | B1 | em código: *argument* = argumento ✓ |
| compromise | acordo, concessão; comprometer (segurança) | compromisso | appointment, commitment | B1 | *the server was compromised* = invadido |
| policy | política, diretriz | polícia | police | B1 | *privacy policy* |
| particular | específico | particular | private, personal | B1 | |
| record | gravar, registro | recordar | remember | B1 | *database record* |
| requirement | requisito | requerimento | request, petition | B1 | *requirements* = requisitos ✓ |
| legend | lenda; legenda de mapa ou gráfico | legenda (filme) | subtitles | B1 | legenda de gráfico = *legend* ✓ |
| notice | notar, aviso | notícia | news | A2 | |
| exit | saída | êxito | success | A2 | |
| expert | especialista | esperto | smart | A2 | |
| large | grande | largo | wide | A2 | |
| lecture | palestra | leitura | reading | B1 | |
| prejudice | preconceito | prejuízo | loss, damage | B1 | |
| procure | adquirir | procurar | look for | B1 | ver BR51 |
| tax | imposto | taxa | fee, rate | B1 | |
| time | tempo, vez, hora | time (equipe) | team | A1 | |
| turn | vez, curva, virar | turno | shift | A2 | |
| educated | instruído | educado | polite | B1 | |
| stupid | burro | estúpido (grosso) | rude | A2 | |
| appointment | hora marcada | apontamento | note | A2 | |
| agenda | pauta | agenda | planner, schedule | B1 | *meeting agenda* = pauta |
| anticipate | prever | antecipar | bring forward, move up | B2 | |
| comprehensive | abrangente | compreensivo | understanding | B2 | |
| convenient | prático | conveniente (adequado) | appropriate | B1 | |
| sensible | sensato | sensível | sensitive | B1 | (fora da lista do Schütz; par clássico) |

**Observação de Schütz:** a ocorrência desses falsos cognatos é "insignificante, menos de 0,1%", e o iniciante não deve se preocupar demais [S2]. Tratar sempre em frase, nunca em lista para decorar.

### Anexo B · Regência

**Verbos que em PT pedem preposição e em EN não** (BR42): *call* (ligar para), *ask* (perguntar para), *tell* (contar para), *enter* (entrar em), *discuss* (discutir sobre), *need* (precisar de), *like* (gostar de), *attend* (participar de), *answer* (responder a), *marry* (casar com), *reach* (chegar a), *approach* (aproximar-se de), *join* (juntar-se a), *ride* (andar de) [S1 §16].

**Preposições diferentes** (BR53):
- depend **on** (depender de) · consist **of** (consistir em) · think **about/of** (pensar em) · dream **about/of** (sonhar com)
- married **to** (casado com) · interested **in** (interessado em) · good **at** (bom em) · bad **at** · worried **about** (preocupado com)
- angry **with/at** (bravo com) · afraid **of** (com medo de) · proud **of** (orgulhoso de)
- arrive **in** (cidade/país) / **at** (lugar) · wait **for** (esperar) · look **at** (olhar) · look **for** (procurar) · listen **to** (escutar) · pay **for** (pagar algo)
- apply **for** (candidatar-se a) [S3] · according **to** (de acordo com) [S3] · different **from** (diferente de) · similar **to** (parecido com) · the same **as** (igual a)
- **in** the picture (na foto) · **on** TV / **on** the internet / **on** the phone · **at** night / **in** the morning · **on** time (pontual) / **in** time (a tempo)

**"Para" → *to* ou *for*** [S3]: *to* = direção ou destinatário de verbos de transferência (*give / send / lend to*); *for* = benefício (*buy / make / open / translate for*). Infinitivo de finalidade: sempre *to* (BR30).

### Anexo C · Ortografia para um curso de digitação

**1. As 10 que lusófonos mais erram** (Cambridge [S6]): which (*wich*), comfortable (*confortable*), beautiful (*beatiful*), beginning (*begining*), because (*becouse*), believe (*belive*), different (*diferent*), accommodation (*accomodation*), together (*togheter*), always (*allways*).

**2. Consoantes duplas: o cognato PT tem simples e o EN tem dupla** (BR45):

| Padrão | Exemplos (EN ← PT) |
|---|---|
| **-mm-** | community ← comunidade · communication ← comunicação · commercial ← comercial · recommend ← recomendar · comment ← comentar · commit ← cometer · immediately ← imediatamente · summary ← sumário · programming |
| **-ff-** | different ← diferente · efficient ← eficiente · effect ← efeito · official ← oficial · office · offer ← oferecer · difficult ← difícil · traffic ← tráfego · sufficient ← suficiente |
| **-pp-** | opportunity ← oportunidade · application ← aplicação · approach · appear ← aparecer · apparent ← aparente · support ← suporte · suppose ← supor · approximately ← aproximadamente · happen |
| **-cc-** | accept ← aceitar · access ← acesso · accommodation ← acomodação · occasion ← ocasião · accurate · account · accident ← acidente · success ← sucesso · occur(red) ← ocorrer |
| **-ll-** | illegal ← ilegal · intelligent ← inteligente · collaborate ← colaborar · collect ← coletar · excellent ← excelente · parallel ← paralelo · finally/really/usually/actually/especially (-ally ← -almente) |
| **-tt-** | attention ← atenção · attitude ← atitude · attack ← ataque · attach · attempt · pattern · settings · button |
| **-nn-** | annual ← anual · connect ← conectar · innovation ← inovação · channel ← canal · beginning · planning · running |
| **-gg-** | suggest ← sugerir · exaggerate ← exagerar · aggressive ← agressivo · debugger · logging |
| **-dd-** | address ← (endereço; armadilha *adress*) · add · middle · hidden |
| **-ss-** (em EN e PT) | process, necessary, possible, professional, message, discuss, express, mission: o brasileiro acerta o ss, mas erra o resto (*neccessary*, *proffessional*) |

**Regra de dobrar no sufixo (en-US)**: dobra quando a sílaba final é tônica e termina em consoante-vogal-consoante (*stop → stopped*, *plan → planning*, *begin → beginning*, *commit → committed*, *occur → occurred*, *refer → referred*). Não dobra quando a última sílaba é átona (*travel → traveled*, *cancel → canceled*, *label → labeled*, *model → modeling*). No inglês britânico essas dobram, então isso é parte da decisão en-US [S21].

**3. Grafias que o PT simplificou** (BR46): ph → f (*phone, photo, phase, phrase, graph, philosophy*); th → t (*theory, theme, method, author, thesis, thread*); y → i (*system, type, analysis, physics, rhythm, symbol, style, cycle*); ch = /k/ (*chemistry, architecture, schedule, technology, school, character*); h inicial (*hour, honest, human, history, hotel*); k/w (*key, keyboard, know, window, web, week*).

**4. Sem o "e" protético** (pronúncia e grafia): *specific* (específico), *structure* (estrutura), *special* (especial), *state* (estado), *space* (espaço), *study* (estudar), *school* (escola), *strategy* (estratégia), *standard*, *stack*, *string*, *style*, *script*.

**5. Letras mudas** (pronúncia ≠ grafia): know, knife, knowledge, write, wrong, wrap, answer, Wednesday, listen, often, island, hour, honest, doubt, debt, receipt, column, design, sign, align, foreign, light, right, night, height, weight, thought, through, though, although, enough, daughter, half, talk, walk, could, should, would, climb, comb, castle, psychology, guess, guide, build, built, business, queue.

**6. ie/ei:** believe, achieve, field, piece, friend, client, science, efficient, ancient, view, review, retrieve × receive, ceiling, deceive, perceive, receipt, height, weight, either, neither, foreign, their, weird, seize.

**7. Palavras de dev que brasileiro costuma errar:** length (*lenght*), height (*heigth*), width (*widht*), receive (*recieve*), environment (*enviroment*), dependency (*dependancy*), separate (*seperate*), occurred (*ocurred*), successful (*sucessful*), necessary (*necesary*), address (*adress*), accessible (*acessible*), argument (*arguement*), parameter (*paramter*), privilege (*privilegy*), maintenance (*maintainance*), definitely (*definately*), existence (*existance*), deprecated (*depreciated*), license (en-US), canceled (en-US), behavior (en-US), initialize (en-US), synchronous, asynchronous, schema, cache, queue, thread, retrieve, authentication, authorization, available, performance, management.

Fontes das listas: [S6][S23][S24]. Os exemplos dev são compilação própria, para validar.

**8. Maiúsculas** (BR15): *I*; dias (*Monday*); meses (*January*); línguas (*English, Portuguese*); nacionalidades (*Brazilian*); feriados (*Christmas*); títulos com nome (*Mr. Smith*). Estações ficam em minúscula (*summer*).

**9. Números e datas** (T14): *3.5*; *1,000*; *9:30*; *January 5*; *October 4, 2026*.

### Anexo D · Erros de desenvolvimento a monitorar (não são interferência)

- -s da 3ª pessoa (*she work*, *everybody like*) [S6]
- passado e particípio irregulares (*had fall*) [S10]
- plural de gentílicos e irregulares (*Portugueses* [S10], *childrens*, *mans*)
- comparativos (*more big*, *more good*)
- grafia do -ed e -ing (*stoped*, *planing*)
- *a/an* (*a apple*)
- contrações confundidas: *it's/its*, *you're/your*, *they're/their/there* [S8]
- *everyday* × *every day*; *a lot* (duas palavras) [S8][S23]

### Anexo E · Um verbo PT, vários EN (cola para quem escreve frases)

| PT | EN conforme o contexto |
|---|---|
| fazer | do (tarefa) · make (criar) · ask (pergunta) · have (festa) · take (prova, foto) · turn (anos: *I turn 30*) |
| ficar | get (mudança) · be (lugar) · stay (permanecer) · keep (ficar com) · look (ficar bem) · be left (sobrar) |
| perder | lose (objeto, jogo) · miss (ônibus, aula, evento) · waste (tempo) |
| ganhar | win (jogo) · earn / make (salário) · get (presente) · gain (peso) |
| conhecer | meet (pessoa, 1ª vez) · know (já conhece) · visit / see (lugar) · get to know (ir conhecendo) |
| tomar | have (refeição, café) · take (banho, remédio, ônibus) · drink (bebida) |
| levar / trazer | take (para lá) · bring (para cá) · carry (carregar) · lead (conduzir) · take (tempo: *It takes 2 hours*) |
| tirar | take off (roupa) · take (foto) · get (nota) · remove (remover) · take out (retirar) |
| pegar | take · get · catch (ônibus, gripe, bola) · pick up (buscar, apanhar) · grab |
| achar | find (encontrar) · think (opinião) · guess (palpite) |
| passar | spend (tempo) · pass (prova, objeto) · go by (tempo passa) · stop by (passar em algum lugar) · iron (roupa) |
| deixar | leave (lugar, objeto) · let (permitir) · drop off (deixar alguém em algum lugar) |
| dizer / falar / contar | say (algo) · tell (alguém, história, verdade) · speak (idioma) · talk (conversar) · count (números) |
| usar | use (ferramenta) · wear (roupa) |
| emprestar | lend (dar) · borrow (pegar) |
| assistir | watch (TV, filme) · attend (aula, reunião) |
| esperar | wait for (aguardar) · hope (ter esperança) · expect (prever) |
| atender | answer (telefone) · serve / help (cliente) · meet (requisito) |

### Anexo F · Sinais de interferência no motor de digitação (sugestão)

No modo **recuperação** (só o PT visível), comparar o que o aluno digita com prefixos-armadilha previstos para a frase:

| Se o aluno digita… | …e o alvo é | Interferência |
|---|---|---|
| `Is rain…` | `It's raining` | BR01 |
| `Have a` / `Has a` | `There's a` | BR03 |
| `I have 3…` | `I'm thirty…` | BR04 |
| `You like…?` | `Do you like…?` | BR06 |
| `The life` | `Life` | BR21 |
| `informations` / `advices` / `softwares` | `information` / `advice` / `software` | BR22 |
| `explain me` | `explain it to me` | BR54 |
| `depend of` | `depends on` | BR53 |
| `monday` / `english` | `Monday` / `English` | BR15 |
| `comunity` / `diferent` | `community` / `different` | BR45 |
| `I work here since` | `I've worked here since` | BR47 |
| `when I will` | `when I get` | BR28 |

Cada acerto ou erro atualiza o domínio do **ponto BR##**, não só da frase. A revisão espaçada pode então puxar outras frases do mesmo ponto: o aluno aprende o **padrão**, e não só a frase decorada.

---

## 9. Fontes

**Interferência PT → EN (primárias abertas e lidas)**
- [S1] SCHÜTZ, Ricardo E. *Contrastes gramaticais entre inglês e português: erros comuns a serem evitados.* English Made in Brasil. https://www.sk.com.br/sk-gram.html
- [S2] SCHÜTZ, Ricardo E. *Falsos cognatos (falsos amigos).* Atualizado em 20/07/2019. https://www.sk.com.br/sk-falsos-cognatos-ou-falsos-amigos.html
- [S3] SCHÜTZ, Ricardo E. *"To & for" comparados a "para".* https://www.sk.com.br/sk-tofor.html
- [S4] SCHÜTZ, Ricardo E. *Diferenças idiomáticas entre português e inglês.* https://www.sk.com.br/sk-idiom.html
- [S5] SCHÜTZ, Ricardo E. *Tradução mental: receita que não dá certo.* https://www.sk.com.br/sk-traducao-mental.html
- [S6] CAMBRIDGE UNIVERSITY PRESS (language research team). *Common English errors when a learner's first language is Portuguese.* 2020. https://www.cambridge.org/elt/blog/wp-content/uploads/2020/03/Portuguese.pdf
- [S7] LLEXI. *Common English Errors by Portuguese Speakers.* https://llexi.com/l1-errors/common-english-errors-portuguese-speakers.html
- [S8] ONLINE TEACHERS UK (Laura Turpin). *Portuguese mistakes in English: 40 most common errors.* https://onlineteachersuk.com/40-most-common-mistakes-english-portuguese/
- [S9] MOSALINGUA. *Os 10 erros mais comuns dos brasileiros no inglês.* https://www.mosalingua.com/pt/10-erros-mais-comuns-dos-brasileiros-no-ingles/
- Complementar: EXAME / Babbel, *Os 10 erros mais comuns dos brasileiros ao falar inglês.* https://exame.com/carreira/os-10-erros-mais-comuns-dos-brasileiros-ao-falar-ingles (citado pelo resumo da busca: *have* × *there is*, idade com *be*, *people are*).

**Acadêmicas**
- [S10] VAZ DE MELLO, Maria da Conceição M. *Errors in foreign language learning.* Revista de Estudos Germânicos, UFMG. https://periodicos.ufmg.br/index.php/germanicos/article/view/8317/5841
- [S11] FONSECA, Marcia Irene da. *The present perfect: a misunderstood tense for Brazilian students.* Linguagem em (Dis)curso, 2001. https://new.scielo.br/j/ld/a/vcPnLkRc7rwmkZjX3RCbxbc/?lang=en
- [S12] CURY, Larissa da S.; GAMA, T. S. M. *A possível influência do PB (L1) na realização de sujeitos referenciais em inglês (L2).* Caderno de Squibs, v. 7, n. 1, p. 49-60, 2022. https://www.periodicos.unb.br/index.php/cs/article/view/38281
- [S30] Estudos de corpus de aprendizes brasileiros (Br-ICLE/PUC-SP; COBRA-7; preposition stranding), **conhecidos só pelos resumos dos resultados de busca, não lidos na íntegra**: https://repositorio.ufmg.br/bitstream/1843/MGSS-9HSNWX/1/dissertacao_completa.pdf · https://revistadogel.emnuvens.com.br/estudos-linguisticos/article/download/1108/674/3086 · https://periodicos.ufmg.br/index.php/germanicos/article/view/8357/5881 · https://tede2.pucsp.br/bitstream/handle/13575/1/Wendel%20Mendes%20Dantas.pdf · https://oasisbr.ibict.br/vufind/Record/RCAP_733444fd8264c16566070260711adfd7 (artigo definido, aprendizes portugueses)
- [S29] SWAN, Michael; SMITH, Bernard (eds.). *Learner English: A Teacher's Guide to Interference and Other Problems.* 2. ed. Cambridge University Press, 2001 (capítulo "Portuguese speakers"). https://www.cambridge.org/core/books/learner-english/AD1F3E59EFD6214E40C8FBCB242C071A. **Referência; o conteúdo do capítulo não foi consultado.**

**Tradução, L1 e memorização**
- [S13] NATION, Paul. *The role of the first language in foreign language learning.* Asian EFL Journal, 2003. https://okt.kmf.uz.ua/atc/oktat-atc/Bakalavr/MELT/Readings_III-5/Nation_Asian_EFL_Journal_june_2003_pn.pdf
- [S14] BONILLA CARVAJAL, Camilo Andrés. *Interlinear Translations Reduce Cognitive Load on EFL Vocabulary Acquisition.* Íkala, v. 30, n. 1, 2025. https://revistas.udea.edu.co/index.php/ikala/article/view/356253
- [S15] VERGARA, Mairo. *Como aprender inglês: o guia definitivo* (v1.2). https://www.mairovergara.com/wp-content/uploads/2015/06/Como-Aprender-Ingl%C3%AAs-O-guia-definitivo-1.2.pdf
- [S16] VERGARA, Mairo. *4 coisas que você não deve fazer na hora de aprender inglês.* https://www.mairovergara.com/4-coisas-que-voce-nao-deve-fazer-na-hora-de-aprender-ingles/
- [S31] Assimil (tradução natural + literal entre colchetes) e Birkenbihl (decodificação palavra por palavra), **via resumos de busca**: https://mezzoguild.com/assimil-review · https://www.assimil.com/en/faq/faqs/methode-utilisation · https://en.wikipedia.org/wiki/Vera_F._Birkenbihl
- [S32] LIMA, Denilso de. *Podcast: What are collocations?* Inglês na Ponta da Língua. https://www.inglesnapontadalingua.com.br/2012/06/podcast-what-are-collocations.html
- [S33] MOSALINGUA. *Used to em inglês.* https://www.mosalingua.com/pt/used-to-em-ingles/ (via resumo de busca)
- [S26] DUOLINGO. *Using AI to open up bottlenecks in course content creation* (listas de traduções aceitas). https://blog.duolingo.com/using-ai-to-open-up-bottlenecks-in-course-content-creation/

**Registro e localização PT-BR**
- [S17] MICROSOFT. *Portuguese (Brazil) Localization Style Guide.* https://download.microsoft.com/download/8/e/3/8e349e32-9eb9-4b63-9909-7586b94a24dd/por-bra-StyleGuide.pdf
- [S18] WIKIPEDIA. *Brazilian Portuguese* (ter existencial; você × tu; próclise). https://en.wikipedia.org/wiki/Brazilian_Portuguese

**Padrão AmE × BrE e ortografia**
- [S19] GOOGLE. *Developer Documentation Style Guide*: Spelling https://developers.google.com/style/spelling · Commas https://developers.google.com/style/commas · Contractions https://developers.google.com/style/contractions
- [S20] CAMBRIDGE ENGLISH. *Should my child learn American or British English?* https://www.cambridgeenglish.org/learning-english/parents-and-children/how-to-support-your-child/should-my-child-learn-american-or-british-english/
- [S21] WIKIPEDIA. *American and British English spelling differences.* https://en.wikipedia.org/wiki/American_and_British_English_spelling_differences
- [S22] FLUTTER API. *Center class.* https://api.flutter.dev/flutter/widgets/Center-class.html
- [S23] OXFORD UNIVERSITY PRESS. *20 most commonly misspelt words in English.* https://teachingenglishwithoxford.oup.com/2010/09/30/20-most-commonly-misspelt-words-in-english/
- [S24] WIKIPEDIA. *Commonly misspelled English words.* https://en.wikipedia.org/wiki/Commonly_misspelled_English_words
- [S25] WIKTIONARY. *softwares* https://en.wiktionary.org/wiki/softwares · *informations* https://en.wiktionary.org/wiki/informations · *feedbacks* https://en.wiktionary.org/wiki/feedbacks · *code* https://en.wiktionary.org/wiki/code

**Níveis e contexto**
- [S27] BRITISH COUNCIL; EAQUALS. *Core Inventory for General English.* 2011. https://www.eaquals.org/wp-content/uploads/EAQUALS_British_Council_Core_Curriculum_April2011.pdf
- [S28] EF. *EF English Proficiency Index: Brazil.* https://www.ef.com/wwen/epi/regions/latin-america/brazil/

**Leitura recomendada (não consultada aqui):** FRAGOZO, Carina. *Sou péssimo em inglês.* Canais: English in Brazil (Carina Fragozo), Inglês Winner, Teacher Allie, Mairo Vergara.

---

*Nada neste dossiê foi aplicado ao projeto `pac_dart`. As frases-modelo são propostas para revisão. Antes de entrar no currículo, convém validar as frases EN com um falante nativo e as PT com o dono do app, que é o público.*
