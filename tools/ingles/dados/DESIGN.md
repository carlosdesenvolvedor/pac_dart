# PAC·ENGLISH: o método

> O terceiro curso do PAC·DART. A unidade é a **frase**. A tradução em português do Brasil fica **sempre em cima**, e a pessoa **sempre digita a frase inteira em inglês**, **várias vezes**, até decorar o contexto. A progressão vai do zero absoluto ao C1, com uma etapa final de inglês profissional para desenvolvedores.
>
> Versão 1.1, 05/out/2026 (revisão final). Este documento consolida os sete dossiês de pesquisa em `pesquisa/` (citados como **[01]** a **[07]**, com a seção) e serve de contrato para três públicos: quem implementa a mecânica no app, os agentes que vão escrever as frases e os revisores automáticos. **A fonte única do curso é `esboco.json`** (plano + lições + portões + glossário + ficha do aluno + tabela de retomadas das interferências). `plano_trilhas.json` e `licoes_<etapa>.json` são visões geradas a partir dele e não se editam à mão. As decisões da revisão final, problema a problema, estão em `CHANGELOG-REVISAO.md`.

---

## 0. Resumo em doze linhas

1. **Cada frase nova é digitada 5 vezes na lição**, em **ondas** (todas as frases passam por um degrau antes de qualquer uma passar ao seguinte), e o modelo em inglês vai sumindo: **inteiro esmaecido → só as iniciais → só o esqueleto → escondido → escondido de novo na prova final**. A tradução fica em cima o tempo todo. Entre duas digitações da mesma frase há sempre 7 ou mais outras (2.3).
2. **Só a primeira digitação é cópia.** As outras quatro exigem lembrar. É a recuperação que fixa, e copiar várias vezes com o modelo à vista é a forma mais fraca de repetir [01 §2.4].
3. **Errou, vê na hora:** a frase certa aparece com as palavras erradas marcadas, o áudio toca, a pessoa copia a frase corrigida uma vez e ela volta na onda seguinte, um degrau abaixo.
4. **O áudio en-US toca antes da cópia e depois de cada tentativa de memória**, nunca antes dela, porque entregaria a resposta.
5. **Nos dias seguintes a frase volta uma vez por revisão, escondida**, com intervalos crescentes: 1, 3, 7, 16, 35, 80 e 180 dias (caixas de Leitner, já implementadas). Depois, FSRS-6 com retenção de 90%.
6. **A nota é automática e mede memória, não dedo:** nas digitações de memória a pessoa digita **palavra a palavra** (cada palavra é conferida no espaço), o que separa deslize de dedo de erro de inglês e permite aceitar as variações corretas.
7. **A correção é tolerante no que não é inglês** (pontuação, teclas mortas do ABNT2 e do US-International, variações legítimas como contrações, *that* opcional e posição do advérbio de tempo) **e exigente no que é inglês** (terminações *-s/-ed/-ing*, apóstrofo, maiúscula de *I*, dias, meses e nacionalidades).
8. **Curso:** 6 etapas, **120 trilhas, 595 lições e 5.206 frases**, do pré-A1 ao C1, mais a etapa de dev. É o porte do curso de C# (meta de 4.708) [02 §3].
9. **Frases em cenas e diálogos com elenco fixo**, uma fala por item, uma novidade por frase, no máximo ~14 palavras na recordação, com o chunk-alvo destacado nas duas línguas e reciclagem com lastro em toda lição.
10. **Os 63 pontos de interferência do português** (*it* obrigatório, *there is*, idade com *be*, *present perfect*, *I want you to*...) entram no nível certo, voltam pelo menos 3 vezes e são treinados justamente nas digitações de memória [04 §6].
11. **Pular etapas só com prova curta:** portões de 8 frases (2 a 3 min cada) no começo de cada nível, com diagnóstico por ponto gramatical, e "testar para pular" em cada trilha com as frases da própria trilha.
12. **Gamificação gentil:** ofensiva com congelamento, metas por minutos (leve, normal e intensa), ranking por pontos de memória e arcade só com frases já estudadas. Nada de vidas nem energia.

---

## 1. Princípios

Cada princípio traz a evidência e o dossiê de origem. Em todos, "digitar de memória" quer dizer digitar a frase em inglês com a tradução em cima e o inglês parcial ou totalmente escondido.

| # | Princípio | Evidência | Fonte |
|---|---|---|---|
| P1 | **Tradução PT-BR sempre em cima; digitar sempre a frase inteira em inglês, várias vezes.** É o pedido literal do dono e coincide com a "segunda onda" do Assimil (ler a tradução, produzir a frase estrangeira). A L1 é o meio mais eficaz de dar significado na aprendizagem deliberada. | Nation (2003); Assimil, fase ativa | [04 §0.4], [05 §2.11] |
| P2 | **Recuperar fixa; copiar quase não fixa.** A cópia aparece uma única vez, no primeiro contato. | Testados de novo, 80% lembrados em uma semana, contra 36% de quem só estudou de novo (Karpicke & Roediger 2008). Digitar a palavra 6 vezes vendo o modelo: 29–40% no teste final, contra 40–58% com o modelo sumindo (Finley et al. 2011). Copiar perdeu para a recordação a partir da tradução (Candry et al. 2020; Barcroft 2006/2007). | [01 §2.3–2.4], [05 §3] |
| P3 | **O modelo some aos poucos (pistas decrescentes).** É a ponte entre copiar e lembrar, e o motor esmaecido do PAC já é o primeiro degrau. | Finley 2011 (DC > cópia, d = 0,37 e 0,56); Glisky et al. 1986; quanto menos pista para acertar, melhor a retenção (Carpenter & DeLosh 2006). | [01 §2.8], [05 M1] |
| P4 | **Intercalar sempre; nunca a mesma frase duas vezes seguidas** (exceto a cópia de correção logo depois de um erro). | Em bloco, 20% de retenção em 2 dias, contra 45% com cinco itens entre as repetições (Karpicke & Roediger 2007). Espaçar a recuperação: g ≈ 0,74 (Latimier et al. 2021). 72% das pessoas acham que o bloco rende mais, e erram (Kornell 2009). | [01 §2.5] |
| P5 | **Atrasar a primeira recuperação e marcar a primeira revisão para o dia seguinte.** | Atrasar a primeira tentativa: 52% contra 44% em 2 dias. Reaprender depois de uma noite de sono exigiu metade das tentativas e reteve mais por 6 meses (Mazza et al. 2016). | [01 §2.6, 2.14] |
| P6 | **Repetição moderada no mesmo dia, o resto espalhado em dias.** | 5–7 recuperações na sessão superam 1–3 (Nakata 2017); dobrar o treino no mesmo dia some em 4 semanas (Rohrer et al. 2005); 3 acertos na sessão e depois reaprendizagens espaçadas (Rawson & Dunlosky 2011). | [01 §2.10] |
| P7 | **Feedback corretivo imediato depois de cada erro.** Errar tentando é aceitável e até útil. | Mostrar a resposta depois do erro elevou a retenção em uma semana em 494% (Pashler et al. 2005). Sem feedback e com 50% ou menos de acerto, o efeito do teste some (Rowland 2014). | [01 §2.3] |
| P8 | **A nota mede memória, não dedo.** Só digitação de memória gera nota; precisão por palavra, e não por tecla; cada dica rebaixa a nota. | Na cópia a precisão é de 91–98% e a retenção de 29–40% (Finley 2011). Lingvist separa erro de digitação de erro de memória. | [01 §4], [05 §2.3] |
| P9 | **Mirar 80–90% de acerto nas digitações de memória.** Acima disso, acelerar; abaixo de 70%, desacelerar. | Regra dos 85% (Wilson et al. 2019, heurística teórica) e o limite de Rowland. | [01 §2.9, 5.7] |
| P10 | **Uma novidade por frase, com o chunk-alvo destacado nas duas línguas.** O resto da frase é conhecido. | i+1 (Krashen 1982); método de frases do Mairo Vergara (uma desconhecida por frase); o contexto pode desviar a atenção da palavra-alvo (Laufer & Shmueli 1997). | [02 §5.2], [03 §2.8], [04 T7] |
| P11 | **Fórmula antes da regra, e espiral.** Chunks de alta frequência entram cedo como bloco fechado (*I'd like*, *Can I...?*) e são "abertos" depois; as mesmas estruturas voltam com usos novos. | English Grammar Profile: fórmula → slot e moldura → sistema produtivo; "mesmas estruturas, usos novos" (O'Keeffe & Mark 2017; Mark 2023); Bruner (1960). | [02 §2.3, §5] |
| P12 | **Frases em cenas reais, com elenco fixo e contexto.** Nada de frase solta nem absurda. | A reclamação número 1 contra Glossika, Clozemaster e Lingvist é a frase "em vácuo"; o Core Inventory manda dar os expoentes em contexto. | [05 §5], [02 §2.2] |
| P13 | **Lições temáticas, sem pares de interferência na mesma lição** (*left/right*, *lend/borrow*, *make/do*, *meet/know*, *miss/lose*, *hear/see*, *a few/a little*, *thirteen/thirty*). Os pares se juntam só no fechamento da trilha, numa lição de contraste (zero itens novos) ou nas revisões. Trilhas de pares confundíveis não ficam em sequência (fazer-ficar-perder-ganhar e conhecer-levar-emprestar-dizer estão a 4 trilhas de distância, e parte dos itens foi para as trilhas temáticas). | Agrupar sinônimos e opostos gera erros de troca (Tinkham; Waring; Nakata & Suzuki 2019; Nation & Crabbe 1991). | [01 §2.7], [03 §5.2] |
| P14 | **As interferências do português são treinadas na recuperação.** Copiando, quase ninguém erra; os erros de brasileiro aparecem quando é preciso lembrar o inglês a partir do português. A forma errada nunca é alvo de digitação. | 60 pontos do dossiê (BR01–BR60), 46 deles no A1–A2, mais 3 acrescentados na revisão final (BR61–BR63, 4.4); folheto de erros de lusófonos da Cambridge; corpora Br-ICLE e COBRA-7. | [04 §0, §3, §6] |
| P15 | **PT natural, mas determinístico:** a tradução leva a um único inglês (âncoras de tempo, posse explícita, microcontexto) ou declara as variantes. | Num motor de alvo único, tradução ambígua mede adivinhação, não memória; o Duolingo precisa de 200 a 30 mil respostas aceitas por exercício. | [04 T1, T5, T10], [05 M9], [07 T04] |
| P16 | **Inglês americano e ASCII digitável.** A progressão herdada do English Grammar Profile e do Core Inventory (Cambridge, corpus britânico) é filtrada: *shall*, *mustn't*, *needn't*, *mind you*, *take on board*, *quite* (= razoavelmente), *brilliant* (= ótimo), *a drop in the ocean*, *can't have* (dedução) e *the daily* nunca são alvo; aparecem só como reconhecimento. | Ferramentas e documentação do dono são en-US (`Color`, `Center`); a Cambridge aceita qualquer variante consistente; teclas mortas do US-International transformam `'c` em `ç`. | [04 §5], [06 B8] |
| P17 | **Correção tolerante no que não é inglês, exigente no que é ortografia.** | Correção implicante é a 4ª reclamação mais comum (Duolingo, Lingvist); Glossika torna a pontuação opcional; apóstrofo e maiúsculas de dias e nacionalidades são conteúdo para brasileiros. | [05 M8], [06 B6] |
| P18 | **Áudio como modelo no primeiro contato e como feedback depois; nunca antes de uma tentativa de memória.** | Ditado imediato vira transcrição e o ganho some em 2 semanas; variar vozes ajuda (Barcroft & Sommers 2005); o laço fonológico aprende a forma sonora (Baddeley et al. 1998). | [01 §2.12], [06 A10] |
| P19 | **Revisão espaçada por frase e por pessoa, com nota automática.** | Revisão personalizada: +16,5% sobre a revisão em bloco num exame 28 dias depois (COLT, Lindsey et al. 2014); FSRS é o melhor algoritmo aberto e já existe em Dart. | [01 §2.15, §3] |
| P20 | **Vocabulário pela frequência falada.** NGSL-Spoken até o A2, NGSL até o B2, NGSL-GR no C1, mais PHaVE (phrasal verbs) e PHRASE (chunks). | Com 300 lemas da NGSL-Spoken reconhecem-se ~75% das palavras de uma conversa; 2.000–3.000 famílias dão 95% de cobertura na escuta (van Zeeland & Schmitt 2013). | [03 §2] |
| P21 | **Pular etapas só com prova, e prova curta.** Nada é descartado sem uma digitação de memória, mas o portão mede o chunk-alvo, não a redação exata, e dura 2 a 3 minutos. | Deixar a pessoa descartar o que "já sabe" piora o aprendizado (Kornell & Bjork 2008); nivelamento longo e obrigatório é reclamação contra o Glossika. | [01 §2.9, 5.5], [05 M13] |
| P22 | **Gamificação gentil e métrica de memória.** Ofensiva com congelamento sim; vidas, energia e XP por cópia não. | Ofensiva: +14% de retenção no 7º dia (Duolingo); o sistema de energia gerou abandono; XP fácil vira "farm". | [05 M18–M19, §7] |
| P23 | **Frase humana sempre que possível, IA sempre revisada.** | Exemplos do ChatGPT: 3,3/5 contra 4,2/5 dos lexicógrafos (Lew 2023). O Tatoeba (CC BY) tem 85 mil pares filtrados EN–PT-BR. | [07 §0, §6] |
| P24 | **Honestidade sobre o alcance.** Digitar frases cobre cerca de 25–30% das horas guiadas até o C1; escuta, ditado e fala complementam. | Cambridge: ~700–800 horas guiadas até o C1. | [02 §3] |

---

## 2. A mecânica no app

### 2.1 Vocabulário da mecânica

- **Digitação:** uma tentativa completa de digitar a frase.
- **Lag:** quantas outras digitações acontecem entre duas digitações da mesma frase.
- **Níveis de apoio** (o que aparece do inglês na linha de digitação; a tradução PT fica sempre em cima):

| Nível | Nome no app | O que aparece do inglês ainda não digitado | Exemplo: *I'd like a glass of water, please.* |
|---|---|---|---|
| **N0** | Copie | a frase inteira, esmaecida (o motor atual) | `I'd like a glass of water, please.` |
| **N1** | Iniciais | a 1ª letra de cada palavra, tracinhos no resto; apóstrofo, hífen e pontuação visíveis | `I'_ l___ a g____ o_ w____, p_____.` |
| **N2** | Esqueleto | só tracinhos (tamanho de cada palavra), apóstrofo, hífen e pontuação | `_'_ ____ _ _____ __ _____, ______.` |
| **N3** | De memória | nada, só o contador **obrigatório** de palavras que faltam | `faltam 7 palavras` |

O que já foi digitado aparece cheio. O app já tem a máscara (`mascaraDaFrase`). O contador conta as palavras do `cod` separadas por espaço: *7:30*, *$40,000* e *S-O-U-Z-A* contam como 1 palavra cada.

- **Modo de entrada.** Em **N0** (cópia) o motor é o de sempre: letra a letra, e a tecla errada não avança. Em **N1, N2 e N3** a digitação é **palavra a palavra**: a pessoa digita a palavra num campo livre, e no espaço (ou na pontuação, ou no Enter do fim) a palavra inteira é conferida contra as formas aceitas naquele ponto da frase (o autômato da 3.3). É isso que permite separar deslize de dedo de erro de inglês, aceitar variações corretas e registrar a armadilha de interferência que a pessoa digitou.
- **Degraus de uma frase nova** (D1 a D5): a sequência de níveis que a frase percorre dentro da lição (2.3).

### 2.2 O que aparece na tela

```
┌──────────────────────────────────────────────────────────────────┐
│ ☕ Café e restaurante · lição 2/4      🔥 12 dias  ✔ 184 frases    │
│──────────────────────────────────────────────────────────────────│
│  Mike: Quer mais alguma coisa?                       (contexto)  │  ← fala anterior, em PT até ela concluir
│                                                                  │
│  Só um café, por favor. [Pra viagem.]                            │  ← tradução PT, alvo destacado
│  ⓘ to go = pra viagem (EUA)                       (recolhível)   │  ← nota de 1 linha / glosa
│                                                                  │
│  J___ a c_____, p_____. [T_ g_.]                  (N1 iniciais)  │  ← máscara + alvo na mesma cor
│  Just a [coff▌]                                                  │  ← palavra em digitação (campo livre)
│                                                                  │
│  Ctrl+. ouvir* · Tab letra · Tab Tab palavra · Esc não sei · faltam 4 palavras │
│  degrau ●●○○○   frase 3/8   precisão de memória 92%              │
└──────────────────────────────────────────────────────────────────┘
* em N1–N3 ouvir antes de terminar conta como dica (2.5)
[ ] = trecho do chunk-alvo, mostrado na cor de destaque
```

- **Em cima, sempre:** a tradução PT-BR, com o trecho correspondente ao chunk-alvo destacado (`alvo_pt`).
- **Acima da tradução, quando houver:** a fala anterior da cena (`contexto`). Ela aparece **em português** (a `dica` daquela frase) enquanto a frase do contexto ainda não foi concluída na sessão ou tem revisão marcada para o mesmo dia, porque mostrar o inglês de outra frase-alvo transforma a recordação em cópia de memória de curto prazo. Aparece **em inglês, em cinza**, só depois que aquela frase concluiu, ou quando o contexto não é frase-alvo do curso (ex.: a pergunta do oficial da imigração, que se ouve e não se digita). Respostas curtas (*Yes, I would.* / *So am I.*) usam o contexto em PT por padrão [05 M4, MCD].
- **Abaixo da tradução, recolhível:** a nota de uma linha (`conceito`) e a glosa literal (`lit`). No A1, a glosa abre sozinha no D1; depois disso, só com um toque [04 T6, T20].
- **Linha de digitação:** fonte de prosa legível, sem realce de sintaxe [05 M24]. O chunk-alvo fica na cor de destaque também na máscara.

### 2.3 Passo a passo de uma lição

**0. Abertura (opcional, até 20 s).** Nome da cena, uma linha de situação ("No café perto do hotel, você pede para viagem") e, se houver, a teoria curta da lição (até 5 blocos no formato que o app já usa: `h`, `p`, `ex`, `tip`, `warn`). O botão "Começar" leva direto às frases. Nunca uma aula.

**1. Fase de aprendizagem: as ondas.** As frases sobem a escada abaixo **em ondas**: todas passam por um degrau antes de qualquer uma passar ao seguinte, sempre na mesma ordem relativa (a ordem da cena).

| Degrau | Nível | Lag mínimo | Lag real (8 / 10 frases) | Áudio | Para quê |
|---|---|---|---|---|---|
| **D1 Conhecer** | N0 (copie) | — | onda 0, na ordem da cena | toca **antes** de digitar e de novo **depois** | ligar forma, som e significado; a única cópia; lê a cena inteira |
| **D2 Iniciais** | N1 | 3 | 7 / 9 | só **depois** | primeira recuperação, atrasada e com muito apoio |
| **D3 Esqueleto** | N2 | 5 | 7 / 9 | só depois | recuperação com pouco apoio |
| **D4 De memória** | N3 | 7 | 7 / 9 | só depois | primeira recordação literal só com a tradução |
| **D5 Prova** | N3 | 8 | 8 / 9 | só depois | segunda recordação sem ajuda: o critério da lição |

Regras da fila (substituem o algoritmo guloso do `FilaLicao`; o que falta implementar está marcado com †):

1. **Onda 0†:** o D1 de todas as frases, na ordem da cena. **Ondas seguintes†:** cada frase pendente faz o próximo degrau, na mesma ordem relativa.
2. **Recheio†:** antes de um item que violaria o lag mínimo do degrau (ondas menores por pulo ou erro), entra uma digitação de recheio: uma **revisão vencida** em N3 (conta como revisão) ou, quando não há revisões no dia (primeiras semanas), **uma frase já concluída da própria lição** em N3, sem nota. Com 8 frases sem erros, basta 1 recheio antes da onda da prova.
3. **Pulo do D3†:** só quando o D2 saiu Boa ou Fácil com `v` ≥ 0,8, `L` ≤ 3 s e a frase tem até 8 palavras.
4. **Erro num degrau de memória** (nota De novo; 2.6): feedback, cópia de correção em N0 na hora (a única repetição seguida permitida) e a frase **desce um degrau** (D2 fica no D2, D3→D2, D4→D3, a prova repete a prova), voltando **na onda seguinte**. O **segundo lapso** da mesma frase no dia a devolve ao N1 (D2).
5. **Difícil no D4:** repete o D4 na onda seguinte; o **segundo Difícil** no D4 promove para a prova.
6. **Critério para concluir a frase:** **duas recuperações em N3 aceitas**, o D4 (Boa, Fácil ou Difícil) e a prova (Boa ou Fácil; em frase de 12 ou mais palavras, Difícil também vale) [01 §5.2]. Prova Difícil em frase curta repete a prova uma vez; o segundo Difícil conclui "com esforço" (vale 0,5 na nota e volta amanhã marcada).
7. **Teto do dia: 8 digitações de memória da mesma frase.** As cópias de correção **não** contam. Estourou sem passar na prova: a frase sai da lição como **"difícil"**, entra com **0** na nota da lição e volta amanhã na revisão.
8. **Frases longas** (15 a 18 palavras, permitidas só do B2 em diante e marcadas pelo validador): o D4 e a prova do dia ficam em **N2**; o N3 começa na 1ª revisão. **Não há construção por blocos com cópia**: o D1 é sempre uma única cópia da frase inteira (P2). Sanguessuga de mais de 10 palavras vira dois itens pelo campo `blocos`, cortado pelo autor na fronteira de chunk (2.8).
9. **Modo memorização forte†** (opção nas configurações): critério de 3 acertos em N3, com uma onda extra [01 §2.10].

Ordem real gerada pelo escalonador em ondas (simulação em `_revisao/sim_ondas.js`; A a J são as frases, o número é o degrau, R é recheio, Bc é cópia de correção):

```
8 frases, sem erros: 41 digitações (1 recheio); lags D2 7 · D3 7 · D4 7 · prova 8
A1 B1 C1 D1 E1 F1 G1 H1 A2 B2 C2 D2 E2 F2 G2 H2 A3 B3 C3 D3 E3 F3 G3 H3 A4 B4 C4 D4 E4 F4 G4 H4 R A5 B5 C5 D5 E5 F5 G5 H5

10 frases, sem erros: 50 digitações (sem recheio); lag 9 em todos os degraus

8 frases, D3 pulado em B, D e F: 42 digitações (5 recheios); lags mínimos 7 / 7 / 7 / 8
A1 … H1 A2 … H2 A3 B4 C3 D4 E3 F4 G3 H3 A4 R B5 C4 D5 E4 F5 G4 H4 A5 R R C5 R E5 R G5 H5

8 frases, erro de B no D4: 52 digitações (9 recheios); lags mínimos 7 / 7 / 7 / 8
… A4 B4 Bc C4 D4 E4 F4 G4 H4 A5 B3 R C5 D5 E5 F5 G5 H5 B4 R R R R R R R R B5
```

**2. Prova da lição (D5).** É a última onda, toda em N3. Ela é o **quiz de fixação** da lição: a nota de 0 a 10 vem da primeira prova de cada frase (limpa = 1, com tropeço ou "com esforço" = 0,5, errada ou sem prova = 0), como o app já calcula. A prova sempre se digita em inglês, de memória, com a tradução em cima. Não existe múltipla escolha no núcleo do curso.

**3. Fim da lição.** Tela de resumo com a nota (e estrelas: 3 com 9 ou 10, 2 com 7 ou 8, 1 com 5 ou 6), frases novas, frases difíceis, palavras que mais erraram, os pontos BR## em que a pessoa caiu e a **previsão de amanhã** ("amanhã: ~N revisões, ~M minutos"). Botões: "Próxima lição", "Voltar ao mapa" e, se a meta do dia foi cumprida, "Jogar no arcade com as frases de hoje".

**Tamanho e tempo da lição** (estimativa refeita com o tamanho médio real das frases do esboço: cópia a 4 caracteres/s mais 1,5 s de áudio; digitação de memória a 2,5 caracteres/s, mais a latência de 3 s + 0,05 s por caractere da tradução e 2 s de feedback; cerca de 4,2 digitações de memória por frase, contando pulos e erros):

| Etapa | Frases por lição | Tamanho (média) | Digitações | Tempo da lição | 1 revisão |
|---|---|---|---|---|---|
| A1 (com pré-A1) | 8 | 3–9 palavras (5,6) | ~41 | 10–12 min | ~18 s |
| A2 | 10 | 5–12 palavras (7,0) | ~50 | 15–17 min | ~21 s |
| B1 | 10 | 6–16 palavras (8,9) | ~50 | 18–21 min | ~25 s |
| B2 | 8 | 8–14, até 18 marcadas (10,1) | ~41 | 17–19 min | ~29 s |
| C1 e dev | 8 | 8–14, até 18 marcadas (11,8) | ~41 | 20–22 min | ~34 s |

O número de frases cai no B2 e no C1 porque as frases ficam mais longas. Como a lição passa de 15 minutos do A2 em diante, **a meta diária é medida em minutos**, não em lições (2.8).

### 2.4 Áudio

Voz en-US. Na fase 1, Web Speech com o invólucro e o ranking de vozes do dossiê 06 (A4, A5); na fase 2, áudio pré-gerado com Kokoro `af_heart` (Apache-2.0), com versão normal, versão lenta e tempo de cada palavra [06 A7, A9].

| Momento | Comportamento |
|---|---|
| **D1 e cópias de correção** | Toca **sozinho antes** de digitar (velocidade 0,95). **Ctrl+.** (ou o botão 🔊) repete; **Ctrl+Shift+.** repete devagar (0,75). Ao concluir, toca de novo ("eco", desligável). Lembrete opcional: "diga a frase em voz alta" (a fala é a produção mais forte [01 §2.1]). |
| **D2 a D5, revisões e prova** | Toca **só depois** de terminar, junto com o feedback. Antes de terminar, o áudio só toca pela tecla de áudio ou pelo botão, e **conta como dica** (nota máxima Difícil). |
| **Enter antes do fim** | Não toca nada: mostra "faltam N palavras". Enter é o gesto de "enviar" que a pessoa faz quando acha que terminou; não pode custar uma dica [05 M8]. |
| **Ditado** (tipo extra de revisão, 2.8) | Toca uma vez e só então a pessoa digita, com a tradução em cima (preferência do dono, desligável). Pode repetir 2 vezes sem custo. |
| **Vozes** | Uma voz fixa no A1. Do A2 em diante, alternar duas vozes en-US (feminina e masculina) entre D1, prova e revisões [01 §2.12]. Variantes britânicas só como nota de reconhecimento no B2. |
| **Sem som** | Tudo funciona sem áudio (iPhone no silencioso, navegador sem voz). Aviso discreto, uma vez. Se só houver voz fraca (Safari), dica única: "Para uma voz mais natural, use Edge ou Chrome" [06 A5]. |

O atalho de áudio sai do Enter (o app hoje usa Enter e Shift+Enter) para **Ctrl+.**, que não existe no texto das frases, não é tecla morta e não colide com a troca de fonte de entrada do Mac (Ctrl+Espaço) nem com o painel de emoji do Windows (Win+.) [06 A10].

### 2.5 O que acontece quando a pessoa erra

| Situação | Comportamento |
|---|---|
| Tecla errada em N0 (cópia) | O motor não avança (já é assim), a letra esperada treme de leve. Sem som alto, sem tela vermelha [05 M7]. A cópia não gera nota. |
| Palavra em N1–N3 (modo palavra a palavra) | No espaço, a palavra digitada é conferida: **forma aceita** naquele ponto (alvo ou variação do autômato, 3.3) → entra e a frase segue, trocando de caminho sem custo; **deslize tolerado** (2.6) → entra corrigida e conta como certa; **outra coisa** → a palavra treme, é registrada e a pessoa tenta de novo. |
| **2ª tentativa errada na mesma palavra** | Aparecem a inicial e o tamanho da palavra (dica). Na 3ª, a palavra inteira (dicas). A palavra já não conta como certa desde a 1ª tentativa errada [01 §5.1]. |
| **Tab** | Revela a próxima letra da palavra atual (dica). **Tab Tab** revela a palavra inteira (dicas). Já implementado. |
| **Esc ("não sei")** | Mostra a frase inteira (N0). A tentativa vale **De novo**, e a pessoa digita a frase copiando. Já implementado. |
| **Enter antes do fim** | Mostra "faltam N palavras". Não toca áudio e não custa nada. |
| **Fim de uma digitação de memória** | Tela de feedback por **no mínimo 1,5 s** (Enter avança depois disso; avanço automático em ~2,5 s, desligável): a frase completa com as palavras erradas sublinhadas, o áudio tocando e, se a nota foi Difícil ou De novo, a lista das palavras que falharam [01 §5.1; 05 M20]. |
| Nota **De novo** num degrau | Cópia de correção em N0 na hora, a frase desce um degrau e volta na onda seguinte. |
| Nota **Difícil** | Sem cópia de correção, a menos que haja palavra errada; segue a regra 5 da fila. |
| **"Foi erro de digitação"** | Botão na tela de feedback que sobe a nota um nível (De novo → Difícil ou Difícil → Boa), **uma vez por sessão**. Preserva a confiança sem virar porta para autoengano [01 §4.3; Kornell & Bjork 2008]. |
| **Sinônimo fora do alvo** (a pessoa digita uma palavra válida em inglês que não é a do curso, num trecho que não é o chunk-alvo nem palavra gramatical: *tired* no lugar de *worn out* numa revisão) | A palavra certa aparece com a mensagem "também existe, mas aqui treinamos *X*". Conta como certa para o limiar de De novo e **limita a nota a Difícil**. No chunk-alvo ou em palavra gramatical (artigo, auxiliar, preposição, pronome, terminação), conta como erro normal [05 M9]. |
| **Armadilha de interferência** (*have* onde vinha *there*, *I want that you*, *explain me*, *She work*) | Como a palavra inteira chega ao motor, ela é comparada com o campo `armadilhas` da frase e com a lista do ponto BR##: conta como erro e **registra o BR## na telemetria da pessoa**, não só a frase [04 Anexo F]. |

### 2.6 A nota de cada digitação de memória

Só digitações em N1, N2 e N3 geram nota. Cópia (N0) e cópia de correção nunca geram.

**Métricas** (o app já mede acerto por palavra, dicas e desistência em `avaliarDigitacao`; o resto é †):

| Métrica | Definição |
|---|---|
| `palavra_ok` | palavra aceita na **primeira** tentativa, sem dica. **Deslize tolerado†** (conta como certa) só quando: (a) é **uma** substituição por **tecla vizinha** no layout da pessoa (mapa ABNT2 ou US) ou **uma** transposição de letras vizinhas; (b) não cai nas **3 últimas letras** de palavra terminada em *-s, -es, -ed, -ing, -er, -est* ou *'s* (a zona da morfologia); (c) o resultado **não forma outra palavra válida** (*in/on/at, a/an, is/as, was/were, has/have, then/than*). Vale também para palavras de até 3 letras. Omissão ou acréscimo de letra nunca é tolerado: **palavra encerrada cedo** (espaço onde vinha letra: *work* por *works*) ou **alongada** (*informations*, *can swims*) sempre derruba a palavra e registra o BR## (BR02, BR21–22, *was/were*, *have/has*). |
| erro só de caixa | não derruba a palavra, **exceto** em *I, I'm, I'd, I'll, I've*, nomes do elenco, dias, meses, línguas e nacionalidades, onde derruba e registra BR15 |
| `acc` | palavras_ok ÷ palavras da frase (contadas no `cod`, separadas por espaço) |
| `dicas` | letras reveladas (Tab, 2ª e 3ª tentativas erradas, Esc); áudio antes do fim conta 1 dica |
| `desistiu` | apertou Esc |
| `L`† | latência: da tradução aparecer até a 1ª tecla. **Limite proporcional à tradução:** `Lmax` = 3 s + 0,05 s por caractere da `dica` (ler 120 caracteres leva 6 a 8 s; um limite fixo de 8 s rebaixava toda frase longa) |
| `v`† | velocidade relativa: caracteres por segundo nesta digitação ÷ mediana das **digitações de memória** da própria pessoa em frases de **tamanho parecido** (faixas: até 6, 7 a 10, 11 a 14 e 15 ou mais palavras). Desconta o teclado, o dedo e as pausas naturais de quem compõe frase longa |

**Nota** (avaliada de cima para baixo) [01 §4.3]:

| Nota | Regra | No código atual |
|---|---|---|
| **De novo** | `desistiu` OU `acc` < 0,80 OU `dicas` ≥ 30% das letras | `errou` |
| **Difícil** | `acc` < 1 (até 11 palavras) ou `acc` < 0,9 (12 ou mais) OU `dicas` > 0 OU sinônimo fora do alvo OU `v` < 0,35† OU `L` > `Lmax`† | `hesitou` |
| **Fácil**† | Boa E `v` ≥ 0,75 E `L` ≤ 0,6 × `Lmax` E a revisão anterior da frase foi Boa ou Fácil | (novo) |
| **Boa** | todo o resto: `acc` = 1 (ou ≥ 0,9 em frase de 12+ palavras) e `dicas` = 0 | `acertou` |

**O que conta como acerto (frase lembrada):** Boa, Fácil e Difícil. Difícil é acerto com esforço: a frase avança menos. **De novo** é lapso.

### 2.7 Fixação, treino de memória e frases difíceis

- **Prova da lição (D5)** = o quiz de fixação, descrito em 2.3. A nota alimenta o progresso da lição no mapa.
- **Treino de memória** (já existe no mapa como "fixação"): todas as frases da lição, embaralhadas, em N3. A nota só sobe. Recomendado **a partir do dia seguinte**. Feito no mesmo dia, melhora só a nota da lição e **não altera a revisão espaçada** (treinar a mais no mesmo dia rende pouco [01 §2.10]).
- **Frases difíceis:** pilha automática com as frases que estouraram o teto, as que tiveram 2 ou mais lapsos e as "sanguessugas" (2.8). Fica acessível no mapa e alimenta o treino extra.

### 2.8 Revisão espaçada entre dias

**Uma revisão** é uma única digitação da frase em **N3** (escondida, tradução em cima, contador de palavras), com dica sob demanda. Começar escondido é bom mesmo com risco de erro, porque tentativa seguida de feedback ensina [01 §2.3]. Frases de 15 a 18 palavras fazem a 1ª revisão em N3 depois de terem feito D4 e prova em N2 (2.3, regra 8).

**v1: caixas de Leitner (já implementadas, com ajustes†).**

| Caixa | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| Próxima revisão em | 1 dia | 3 dias | 7 dias | 16 dias | 35 dias | 80 dias | 180 dias |

- Frase concluída na lição → **caixa 1** (volta amanhã).
- **Boa** → sobe 1 caixa. **Fácil**† → sobe 2 caixas. **Difícil**† → fica na caixa, mas o próximo intervalo é **1,5 vez** o da caixa (meia caixa); dois Difíceis seguidos na mesma caixa sobem 1 caixa (hoje o código repete o intervalo, e a frase longa estagnava). **De novo** → desce 2 caixas (mínimo 1), volta amanhã e soma 1 lapso. Nunca zera [05 A8].
- Frase **digitada** num teste de nivelamento e aceita → **caixa 3**†. As frases de uma trilha testada que **não** foram digitadas no teste ficam **"testadas, não vistas"**: não entram na revisão de uma vez (passar no portão do A2 jogaria cerca de 1.000 frases nunca digitadas no mesmo dia); viram um lote amostrado como recheio, no máximo 10 por dia, ou entram na Onda 2. Uma falha nesse lote reabre a lição daquela trilha em modo rápido (2.9).
- **Frase dominada** (métrica de ranking e de marcos) = caixa ≥ 5 (próxima revisão em 35 dias ou mais).

**v2: FSRS-6** com o pacote Dart `fsrs` 2.0.1, um `Card` por frase [01 §3.4, §5.4]:

| Parâmetro | Valor |
|---|---|
| `desiredRetention` | **0,90** (modo leve: 0,85) |
| `learningSteps` / `relearningSteps` | **[]** (a própria lição e a reaprendizagem na sessão fazem o papel) |
| `maximumInterval` | **365** dias no 1º ano; depois 730 |
| `enableFuzzing` | **true** |
| pesos `w` | padrão do pacote; **otimizar** com o otimizador do py-fsrs depois de 2 a 5 mil revisões da pessoa |
| 1ª revisão | **forçada para o dia seguinte** (limitar o 1º intervalo a 1 dia) |
| Ao concluir a lição | registrar **um** review com a nota da prova |
| Notas | De novo = `Rating.again`, Difícil = `hard`, Boa = `good`, Fácil = `easy` |
| Frase dominada | estabilidade ≥ 21 dias |
| Migração | ao trocar de v1 para v2, criar o `Card` com estabilidade igual ao intervalo da caixa atual |

**Fluxo de uma revisão com erro (reaprendizagem na sessão):** nota De novo → feedback e áudio → cópia em N0 → a frase volta **na mesma sessão** em N2 depois de 5 ou mais outras digitações e, depois, em N3, até 1 acerto sem ajuda. Se a sessão tiver poucas revisões, o recheio vem das frases já revisadas no dia, em N3, sem nota. **Só a primeira tentativa do dia vai para o agendador** [01 §5.4; Rawson & Dunlosky 2011]. Nota Difícil não repete na sessão.

**Sessão do dia, nesta ordem:**
1. **Revisões vencidas**, intercaladas entre lições diferentes, das mais atrasadas para as menos (empate: a de caixa menor, ou de menor recuperabilidade no FSRS). É o aquecimento. Ocupam **no máximo metade do tempo da meta** e nunca mais de 80 por dia (o `Revisao.limiteDiario` atual).
2. **Lição nova**, se couber no tempo que sobrou (com revisões restantes como recheio). Se não couber, o app propõe a lição para amanhã e a ofensiva conta do mesmo jeito.
3. **Prova** da lição.

**Metas (escolhidas na primeira semana, mudáveis), em minutos:**

| Meta | Minutos por dia | Teto de revisões | Ritmo resultante |
|---|---|---|---|
| Leve | 15 | 7 min (até 40) | ~1 lição a cada 2–3 dias |
| **Normal (padrão)** | **30** | **15 min (até 80)** | ~1 lição por dia no A1–A2; ~1 a cada 1,5 dia do B1 em diante |
| Intensa | 50 | 25 min (até 80) | ~1,5 a 2 lições por dia |

- As frases novas por dia caem sozinhas conforme as frases crescem, porque a lição longa não cabe todo dia na meta normal. Ninguém precisa escolher "frases por dia".
- **Freio suave†:** se sobrarem revisões vencidas por 2 dias seguidos, a lição nova continua liberada, mas aparece como "não recomendada", e a ofensiva passa a contar só as revisões. **Nada bloqueia o estudo** [05 A9].
- **Tempo do curso inteiro (refeito):** ~170 h de lições (tempo da tabela de 2.3 × 595 lições) + ~150 a 200 h de revisões (≈5 revisões por frase ao longo do curso, de 18 a 34 s cada) ≈ **320 a 370 horas**. Na meta normal, **~21 a 24 meses** do zero ao fim; na intensa, ~13 a 15 meses. Quem passa no portão do B1 economiza cerca de 40%.

**Sanguessugas (leeches):** depois de **6 lapsos**, a frase sai da rotação e vai para "frases difíceis". Lá ganha uma mini-lição em ondas de novo e, se tiver mais de 10 palavras, é **dividida em dois itens** pelo campo `blocos` (cortado pelo autor na fronteira de chunk), cada um com o outro como `contexto`, até voltar a ser acertada inteira. A frase também entra numa fila para a curadoria conferir a tradução, porque PT ambíguo é a causa mais comum [01 §5.4].

**Ditado†:** tipo extra de revisão, liberado quando a frase chega à **caixa 4** (ou estabilidade ≥ 14 dias no FSRS). No máximo 1 em cada 3 revisões daquela frase. Treina escuta; não substitui a revisão normal [01 §5.3].

**Treino extra** (para quem quer "escrever mais vezes"): puxa as frases de menor recuperabilidade ou erradas nos últimos 3 dias, sempre em N3 e intercaladas. **Não altera o agendamento**, exceto que um erro antecipa a frase para amanhã. A repetição extra acontece onde rende [01 §5.6].

**Onda 2 (v2):** ao concluir uma etapa, as cenas dela podem ser refeitas inteiras só em N3, como a fase ativa do Assimil. Conta como treino extra [05 M14].

### 2.9 Nivelamento e como pular etapas

O nível do dono é desconhecido. O curso funciona do zero, mas ninguém precisa refazer o que já sabe. O banco dos portões, com o diagnóstico de cada frase, está em `esboco.json` (`portoes`).

- **Primeira entrada:** "Começar do zero" ou "Teste de nivelamento (2 a 3 min por nível)".
- **Portões†:** um no começo de cada nível (A2, B1, B2, C1 e dev; `portao: true` no JSON). Cada portão tem **8 frases** que cobrem as dependências do nível anterior, cada uma etiquetada com o ponto gramatical (`ponto`) e as trilhas que ela testa (`se_errar`). O teste começa pelo portão do A2 e para no primeiro portão reprovado.
  - **Modo N3 assistido:** contador de palavras e **iniciais das palavras fora do chunk-alvo**; o chunk-alvo fica escondido. A nota olha **só o chunk-alvo e a ordem**, e **Difícil conta como acerto**. Assim quem sabe inglês e escreve *Sorry, Sarah.* ou *Is this wallet yours?* não reprova por redação.
  - **Limiar:** 6 de 8. O portão **encerra assim que fica matematicamente reprovado** (no 3º erro).
  - **Diagnóstico:** passou no portão, mas errou frases → as trilhas de `se_errar` dessas frases abrem em "testar para pular", em vez de ficarem marcadas como testadas (errou *present perfect* → faz as trilhas de present perfect) [02 §9]. As demais trilhas anteriores ficam "testadas, não vistas" (2.8).
- **Testar para pular†** (em qualquer trilha): não há banco separado. O teste usa a primeira frase com alvo de cada lição de conteúdo da própria trilha (no máximo 8; o autor pode marcar outra com `teste: true`), em N3 assistido.
  - **80% ou mais** → trilha "testada". Só as frases digitadas no teste vão para a caixa 3; as outras ficam "testadas, não vistas".
  - **50% a 79%** → lições em **modo rápido**: o D1 vira N2 (com o modelo mostrado só depois), e a frase faz D1 = N2, D2 = N3 e a prova.
  - **Menos de 50%** → lição completa.
- **"Já conheço esta frase"** (no D1): troca a cópia por uma tentativa em N3 na hora. Se der Boa ou Fácil, a frase pula para a prova.
- Os erros do teste não são desperdício: tentar antes de aprender também ajuda depois [01 §2.3].

### 2.10 Metas, ofensiva, pontos, ranking e arcade

Compatível com o ranking (Firestore) e o arcade que o app já tem.

- **Ofensiva diária:** conta o dia quem fizer a sessão do dia (revisões vencidas até o teto de tempo + a lição, se couber) ou, no freio, só as revisões. **Congelamento automático** de 1 dia por semana, acumulando até 2 [05 M19].
- **Pontos de memória** (o que vai para o ranking do curso): Boa = 10, Fácil = 12, Difícil = 5, De novo = 0, por digitação de memória (D2 a D5, revisões, provas). Bônus de 20 por lição concluída e de **50 por trilha testada só no "testar para pular", uma vez por trilha**. **O portão dá um marco no mapa, sem pontos** (passar no portão do A2 daria 1.400 pontos de uma vez e incentivaria refazer testes). **Cópia vale 0.** Cada frase pontua no máximo uma vez por dia na revisão; o treino extra pontua metade; o Treino de memória feito no mesmo dia não pontua; recheio sem nota não pontua.
- **Ranking:** semanal, por pontos de memória. Ranking secundário por **frases dominadas**. **Nunca por velocidade (WPM)**, que mede dedo e teclado [05 M18].
- **Marcos:** 7, 30, 100 e 365 dias de ofensiva; 100, 500, 1.000, 2.500 e todas as frases dominadas (a meta de 1.000 frases é a do método Mairo Vergara [05 §2.7]); cada nível concluído ou testado.
- **No mapa:** trilhas como fases, como nos outros cursos; estrelas por lição; selo "testada".
- **Arcade:** os jogos existentes (Chuva, Rali, Dart Turismo...) ganham modo inglês **só com frases e chunks já estudados, nunca conteúdo novo**, com a tradução em cima. Como o texto fica à vista, é cópia: **não mexe no agendamento** e pontua no ranking do arcade, não no do curso. Uma variação cronometrada com máscara N1 pode virar revisão disfarçada no futuro (v3) [05 M21].
- **Proibido:** vidas, energia, bloqueio por erro, XP por cópia e reorganizar o progresso de quem já estudou. Trilhas novas entram só no fim.
- **Chave de progresso = `id` opaco da frase**†, gravado no JSON e nunca derivado da posição nem do texto. O hash do texto em inglês (o `Revisao.chave` atual) passa a servir só para **detectar mudança**: se a curadoria mudou só a forma (pontuação, contração, troca de sinônimo fora do alvo), o cartão é mantido; se mudou o sentido ou o alvo, a frase desce uma caixa. Assim corrigir um `cod` não zera o histórico [05 A15].

### 2.11 Telemetria para calibrar

| Medida | Alvo | Ação |
|---|---|---|
| Acerto em N3 na lição (D4 e prova) | 80–90% | acima de 95% por várias lições: oferecer meta intensa ou pular D3 mais cedo; abaixo de 70%: frases mais curtas ou meta leve |
| Retenção na 1ª revisão (dia seguinte) | ≥ 80% | abaixo: rever lags, teto e o critério de 2 recuperações (decisão em aberto 7.2) |
| Retenção real nas revisões x alvo | próxima de 90% | muito abaixo: otimizar os pesos do FSRS |
| Dicas e lapsos por frase | — | frase acima do percentil 95 vai para a curadoria (PT ambíguo, frase longa, colocação estranha) |
| Erros por ponto BR## | — | puxar mais frases do mesmo ponto na revisão |
| Sinônimos fora do alvo por frase | — | sinônimo frequente vira `var` (se for forma) ou gancho no PT (se for léxico) |
| Recheios por lição | ≤ 2 em média | acima: rever pulo do D3 e o tamanho das ondas |
| Tempo de sessão e abandono | dentro da meta em minutos | acima por 3 dias: sugerir a meta leve |

### 2.12 Alinhamento com o código atual (leitura sem alterações)

Conferido em `lib/features/ingles/` e `lib/features/curso/presentation/bloc/typing_bloc.dart`.

**Já existe:** a escada N0–N3 (`ModoFrase`, `mascaraDaFrase`); a fila `FilaLicao` (gulosa, com lags 3, 5 e 7, prova com lag 8, erro com lag 3 e teto 8 contando cópias); a avaliação por palavra com tolerância de 1 posição em palavras de 4+ letras (`avaliarDigitacao`); as caixas de Leitner 1-3-7-16-35-80-180 com "errou desce 2" e **`Revisao.limiteDiario = 80`**; a chave da revisão por hash do texto (`Revisao.chave`); Tab, Tab Tab e Esc (`frase_view.dart`); **Enter e Shift+Enter para ouvir antes de terminar** (contando dica); **pontuação automática** em N1–N3 (`pontuacaoAutomatica`: `, . ! ? ; : "`); **maiúscula inicial livre** (`_primeiraLetra`); **erro só de caixa separado** (`errosDeCaixa`); **contrações automáticas não ambíguas e `alt`** com troca de alvo por prefixo (`alternativas.dart`, `_alternativaPara`); **variantes contextuais, caracteres invisíveis e composições do US-International** (`variantesContextuais`, `invisiveis`, `composicoesUsIntl`); o treino de memória no mapa (`fixacao.dart`); e o esquema de trecho `{cod, dica, lit, conceito, alvo}` no `curriculo.json` de inglês.

**Precisa mudar:** a fila gulosa vira o escalonador em ondas com recheio (2.3); o teto passa a contar só digitações de memória; a tolerância de 1 posição vira a regra de deslize de 2.6; Enter antes do fim deixa de tocar áudio (vai para Ctrl+.); a maiúscula inicial livre ganha as exceções de BR15; a lista `alt` de frases inteiras vira o autômato por trecho (3.3); a chave da revisão passa do hash para o `id`.

**Falta implementar (†):** modo palavra a palavra em N1–N3; autômato de variações (`var`, `opcional` e regras automáticas, incluindo *'s/'d* pelo token seguinte); sinônimo fora do alvo valendo Difícil; registro de armadilhas BR##; `Lmax` e `v` por faixa de tamanho; nota Fácil; contador obrigatório em N3; pulo adaptativo do D3; Difícil × 1,5 no Leitner; "testadas, não vistas"; metas em minutos e freio suave; sanguessugas com `blocos`; portões e "testar para pular"; ditado; FSRS na v2; os campos novos do formato (5.1); preenchimento dos campos do perfil (`{nome}`, `{cidade}`...). A regra de deslize e o modo palavra a palavra entram com **testes unitários** para os casos BR02 (*She work*), BR21–22 (*informations*, *can swims*), *was/were*, *have/has*, tecla vizinha em palavra de 2 e 3 letras e troca que forma outra palavra (*in/on*).

---

## 3. Regras de correção da digitação

### 3.1 Por nível de apoio

| Regra | N0 (copie) | N1 e N2 (iniciais, esqueleto) | N3 (memória, prova, revisão) |
|---|---|---|---|
| Modo de entrada | letra a letra | **palavra a palavra**† | **palavra a palavra**† |
| Letras | exigidas | exigidas (com o deslize tolerado de 2.6) | exigidas (idem) |
| **Maiúscula da 1ª letra da frase** | exigida | livre, **exceto** quando a 1ª palavra é *I, I'm, I'd, I'll, I've*, nome do elenco, dia, mês, língua ou nacionalidade† | idem† |
| **Outras maiúsculas** (*I*, nomes, dias, meses, línguas, nacionalidades, siglas) | exigidas | exigidas | exigidas, com dica específica no erro ("em inglês, *Monday* e *English* levam maiúscula") |
| **Erro só de caixa** (letra certa, caixa errada) | o motor não avança até a caixa certa | não derruba a palavra, **exceto** nas classes acima, onde derruba e registra BR15† | idem† |
| Pontuação `. , ! ? ; :` | exigida | **preenchida sozinha**: o cursor pula por ela; se a pessoa digitar, aceita sem duplicar (já existe) | preenchida sozinha |
| Parênteses, colchetes e aspas duplas | não aparecem no `cod` (proibidos pelo validador) | — | — |
| Apóstrofo dentro da palavra (*don't*, *Mary's*) | exigido | exigido e visível na máscara | exigido (é ortografia: *dont* é erro) |
| Hífen dentro da palavra (*twenty-one*) | exigido | exigido e visível | exigido, exceto nos compostos de grafia variável (3.2) |
| `:` `.` `,` dentro de números (*7:30*, *3.5*, *1,000*) | exigidos | exigidos (parte da "palavra") | exigidos |
| Variações (contração, *that* opcional, ordem do adjunto...) | o que está escrito | a máscara mostra o caminho canônico; outro caminho aceito troca a máscara sem custo | aceita as **variações do autômato** (3.3) |
| Erro conta para a nota? | não (cópia não gera nota) | sim, por palavra | sim, por palavra |

Racional: em N0 tudo está à vista, então exigir tudo é coerente com o resto do PAC e fixa a grafia completa. Nos níveis de memória, o objetivo é lembrar **palavras e ordem**, não adivinhar vírgula; mas as maiúsculas de *I*, dias, meses, idiomas e nacionalidades **são conteúdo** para brasileiros, e o apóstrofo é ortografia [06 B6; 04 BR15]. A maiúscula inicial livre não pode engolir o BR15 justamente na posição em que ele mais aparece (*i'm fine* no começo da frase).

### 3.2 Normalizações (todas as entradas, todos os níveis)

Valem tanto para o que a pessoa digita quanto para o texto-alvo ao carregar a frase (rede de segurança; o validador do conteúdo deve barrar antes) [06 B5]:

| Entrada | Tratamento | Situação |
|---|---|---|
| `’ ‘ ‛ ʼ ′ ＇` quando o esperado é `'` | aceita como `'` | já existe para `’`; ampliar† |
| `´` (acento agudo do ABNT2) ou `` ` `` quando o esperado é `'` | aceita como `'` + **dica única**: "o apóstrofo é a tecla `'` à esquerda do 1, não o acento ao lado do P" | † |
| `“ ” „ ‟ ″ ＂` quando o esperado é `"` | aceita como `"` | parcial; ampliar† |
| `– — ‐ ‑ ‒ −` quando o esperado é `-` | aceita como `-` | já existe |
| Compostos do US-International (`ç` = `'c`, `á` = `'a`, `ä` = `"a`, `à`, `â`, `ã`, `ñ` e maiúsculas) | desdobra no par esperado | já existe |
| `'` ou `"` seguido de espaço quando o esperado não é espaço (US-Intl consome ou exige o espaço) | engole o espaço sem erro | já existe |
| Espaço que "solta" acento morto (`~ ^ ´ ``) | engole | já existe |
| Espaço repetido quando o esperado não é espaço | engole sem erro | já existe |
| NBSP (Option+Espaço no Mac), U+2007, U+2009, U+202F, U+3000 | vira espaço | † |
| `…` | vale por `...` (mas o conteúdo não usa reticências) | já existe |
| U+200B, U+200C, U+200D, U+2060, U+FEFF, U+00AD | ignorados sem erro | já existe (`invisiveis`) |
| Letra + acento combinante (U+0300–U+036F) | tratado como o composto | † |
| `%` depois de número | vale por ` percent` (o conteúdo escreve *percent*) | † |
| **Compostos de grafia variável** | hífen ≡ nada ≡ espaço: *trade-off/tradeoff, follow-up/followup, sign-up/signup, on-call/oncall, heads-up, Wi-Fi/wifi, e-mail/email, setup/set-up* (substantivo); e **OK ≡ okay** | † (tabela no validador e no motor) |
| Backspace | permitido, não conta erro | já existe |

**Teclado:** o dono usa **ABNT2** no Mac (`'` e `"` não são mortas, o risco é o `´`). Quem usa **US-International** ou o layout "Brasileiro" do Mac tem `'` e `"` mortas. Na primeira vez que o app detectar o `'` morto (`keydown` com `key === "Dead"` e `code === "Quote"`), mostra uma vez: "No seu teclado o `'` é tecla morta. Pode digitar normal: entendemos `ç` como `'c`" [06 B3, B7]. O mapa de **teclas vizinhas** usado no deslize tolerado (2.6) segue o layout detectado.

### 3.3 Variações aceitas: o autômato da frase

O motor tem um caminho canônico (o `cod`), mas aceita formas equivalentes. Em N1–N3 ele monta, para cada frase, um **autômato com todos os caminhos aceitos** e confere cada palavra contra as palavras possíveis naquele ponto†. Isso substitui a lista `alt` de até 3 frases inteiras, que se esgotava com dois pontos de variação na mesma frase [01 §4.3; 05 M9].

**Variações automáticas (o autor não declara):**

1. **Contrações** *'m, n't, 're, 've, 'll* ↔ formas plenas (já existe).
2. ***'s* e *'d* resolvidas pelo token seguinte†:** *'s* ou *'d* antes de *been* ou de particípio = *has / had*; *'d* antes de verbo base = *would*; *'s* depois de *it, that, what, where, who, how, there, here, he, she* = *is* (ou *has*, pela regra anterior). O possessivo de substantivo (*Mike's*) continua exigido. Assim *I had been working* passa onde o `cod` diz *I'd been working*, e *Where is the restroom?* passa onde diz *Where's*.
3. ***that* opcional** depois de *say, tell, think, know, hope, sure, realize, guess* e em relativa de objeto (*the app I use* ↔ *the app that I use*).
4. **Partícula separável com objeto nominal:** *Put on your coat* ↔ *Put your coat on*; *turn off the lights* ↔ *turn the lights off*. Com pronome, só a forma separada (*turn it off*).
5. ***-ing* ↔ *to* + verbo** depois de *like, love, hate, start, begin, prefer, continue* (*I love traveling* ↔ *I love to travel*).
6. **Adjunto de tempo no início ou no fim** (*Today, Yesterday, Tonight, Now, This morning, On Friday, Next week*...): *I'm working from home today* ↔ *Today I'm working from home*.
7. ***already* opcional** depois do auxiliar quando a `dica` tem "já" e o `cod` tem aspecto perfeito sem *already* (*I've seen that movie twice* ↔ *I've already seen...*).
8. ***might* ↔ *may*** (possibilidade) e, quando a dica diz "pode ser + substantivo", *could* ↔ *might*.
9. **Present perfect simples ↔ contínuo** com *for/since* para *work, live, study, teach, wait* (*I've worked here for two years* ↔ *I've been working...*).
10. **Os três futuros** (*will / going to / contínuo*) quando o futuro **não** é o alvo da lição e a dica não traz pista (*(combinado)*, *(promessa)*, *(decidi agora)*, *(previsão)*).
11. ***some / any* opcionais** quando a dica não tem artigo (*We need bread and fruit* ↔ *We need some bread and fruit*).
12. **OK ↔ okay** e a tabela de compostos de 3.2.

**Variações declaradas pelo autor** (substituem o `alt`): `var` — lista de `{"em": "trecho do cod", "aceita": ["outra forma"]}` — e `opcional` — lista de palavras que podem faltar. Só variantes de **forma** com o mesmo sentido e registro; **nunca sinônimos do chunk-alvo**: o alvo é o que se treina. Sinônimo fora do alvo é tratado em 2.5 (vale Difícil).

**Números:** a forma por extenso ou em dígitos é a que está na frase; o PT espelha a forma (palavras com palavras, dígitos com dígitos; *7:30* ↔ "7h30", *9:00* ↔ "9h00", *percent* ↔ "por cento").

O checador **T04** (retro-tradução cega) usa o mesmo autômato: retro-tradução que cai num caminho aceito passa; a que cai fora dele pede pista no PT, `var` ou contexto.

---

## 4. Estrutura do curso

### 4.1 Etapas, trilhas, lições e frases

| Etapa | Nível | Trilhas | Lições | Frases por lição | Frases | Máx. por frase (palavras / caracteres) | Itens-alvo novos nas lições |
|---|---|---|---|---|---|---|---|
| `a1` Fundação | Pré-A1 + A1 | 28 | 129 | 8 | 1.032 | 6/35 nas 2 primeiras trilhas; 7/40 até a 8ª; 9/50 depois; 12/60 nas situações e na revisão | 413 |
| `a2` Dia a dia | A2 | 23 | 112 | 10 | 1.120 | 12/65 (14/70 nas situações) | 434 |
| `b1` Independência | B1 | 22 | 111 | 10 | 1.110 | 16/90 (18/95 nas situações) | 434 |
| `b2` Desenvoltura | B2 | 22 | 113 | 8 | 904 | 18/100 (alvo de até 14; de 15 a 18, marcadas) | 361 |
| `c1` Domínio | C1 | 14 | 74 | 8 | 592 | 18/105 (idem) | 244 |
| `dev` Inglês profissional de dev | C1 aplicado | 11 | 56 | 8 | 448 | 18/105 (idem) | 184 |
| **Total** | | **120** | **595** | | **5.206** | | **2.070** |

As 120 trilhas, em ordem de estudo, com gramática nova, funções, faixa de vocabulário, temas, chunks sugeridos, situações, reciclagem, interferências, retomadas e as lições com exemplos, estão em `esboco.json`.

**O que cada lição traz no esboço:** `vocabulario` (os itens novos, que viram `alvo`), `apoio` (itens já vistos que a cena usa), `cena` (palavras incidentais permitidas), `recicla` (itens de trilhas anteriores), `interferencias` e `br` (códigos BR##), `situacao`, 3 a 5 `exemplos` de referência e `nFrases` (o total que o autor escreve).

**Teto de itens novos (honesto com a matemática):** cada item novo é o `alvo` de pelo menos 2 frases e cada frase tem um alvo só, então uma lição comporta no máximo **nFrases ÷ 2** itens novos: **4** nas lições de 8 frases (A1, B2, C1, dev) e **5** nas de 10 (A2, B1). Fechamento e lição de contraste: **zero**. As listas originais tinham de 10 a 20 itens por lição; o excedente foi para `cena` (no máximo 1 desconhecida por frase, glosada, sem virar alvo) ou para a `reserva` da trilha (candidatos para as trilhas de situação e para "Frases do mundo"). Com isso, o curso ensina **cerca de 2.100 itens-alvo de forma produtiva** (chunks, estruturas e palavras), mais o vocabulário de cena por exposição. As faixas NGSL de cada trilha (`vocabulario.faixa`) são o **teto** do vocabulário permitido nas frases, não a meta de itens ensinados. O resto da cobertura de 3.000 famílias vem da exposição nas frases, da revisão e das "Frases do mundo" (Tatoeba) [03 §2.8].

**Tipos de trilha e de lição:**
- **Trilha comum** (a maioria): introduz gramática ou léxico. **A última lição é a "cena de fechamento"**: frases novas, **zero itens novos**, mistura tudo da trilha e junta os pares de interferência que ficaram separados. Itens de cena no fechamento: no máximo 1 por frase, em `cena`.
- **Lição de contraste** (`contraste: true`, opcional, antes do fechamento): zero itens novos, junta os pares de uma trilha densa em mini-cenas (ex.: *should have* x *was supposed to* x *could have*; 2ª x 3ª condicional).
- **Trilha de situação** (`situacao-*`) e **revisão de nível** (`revisao-*`, mais `pro-dia-de-trabalho`): nenhuma gramática nova; situações reais com vocabulário situacional (no máximo 1 item novo por frase) e checklist das interferências das trilhas anteriores. **Trilhas sem gramática nova (situação, revisão e dev-\*) aparecem a cada 4 a 8 trilhas em todas as etapas**: A1 9, 16, 21, 27, 28; A2 35, 40, 42, 48, 51; B1 58, 64, 69, 70, 73; B2 79, 80, 84, 88, 91, 95; C1 102, 109; dev 110 a 120 (todas aplicadas). As situações do dia a dia continuam até o C1: aluguel e banco (B1), carro e estrada e atendimento por telefone (B2), vida social e small talk (C1) [02 §7; 05 M14].
- **Trilhas de dev em todas as etapas** (`dev-*`): A1 (chamadas), A2 (standup, pair, Slack, commits), B1 (documentação, e-mail, reuniões), B2 (planning, code review, incidentes). Usam só a gramática já vista e dão retorno imediato a quem trabalha com software.

### 4.2 Por que uma etapa final de dev

A pesquisa sustenta: (1) o consenso sobre o conteúdo cai no C1, que "depende do contexto e do propósito do aluno" segundo o Core Inventory [02 §2.2, §9.7]; (2) o B2 de Nation já inclui 1.000 a 2.000 palavras técnicas da área da pessoa [03 §2.6]; (3) o Tatoeba quase não tem vocabulário de dev (zero frases com *pull request*), então essa parte é toda autoral e precisa de espaço próprio [07 §2.6]. A etapa `dev` fica **depois** do C1 porque usa estruturas C1 (inversão em escrita formal, hedging, conceder e rebater) em cenas profissionais. Não introduz gramática nova. As trilhas `dev-*` das etapas anteriores garantem que o dono não espere até o fim para usar inglês no trabalho. O caso real do dono (trabalhar remoto do Brasil para empresa americana: fuso, sobreposição de horário, contractor, invoice, rate, currículo) aparece na entrevista do B1 e na entrevista sênior da etapa dev.

### 4.3 Por que cerca de 5.200 frases

- **Faixa dos dossiês:** 3.700 a 5.000 frases de A1 a C1 (82 blocos com 40 a 60 frases cada [02 §3, §7]) e 5.500 a 6.000 contando a trilha de dev [03 §6.1]. O plano fica no meio: 4.758 frases de A1 a C1 e 448 de dev.
- **Porte dos outros cursos:** Dart tem 2.354 exercícios; a meta do C# é 4.708.
- **Vocabulário:** cerca de 2.100 itens-alvo produtivos (4.1) e a exposição de cena; cada item novo em 2 ou mais frases da lição e de novo nas lições seguintes, pela reciclagem com lastro (5.5).
- **Referência de mercado:** 1.000 frases para um básico sólido (Mairo Vergara), o que aqui corresponde ao A1 [05 §9 D7].
- **Tempo (refeito, 2.8):** ~320 a 370 horas somando lições e revisões; na meta normal (30 min por dia), ~21 a 24 meses do zero ao fim; na intensa (50 min), ~13 a 15 meses. Isso é cerca de 40 a 50% das horas guiadas da Cambridge até o C1 [02 §3]. Com os portões, quem já sabe o básico começa no A2 ou no B1 e encurta isso bastante.
- **Volume extra sem custo de autoria (v2):** o treino "Frases do mundo" com as 85.460 frases do Tatoeba filtradas por nível [07 §2.6].

### 4.4 Ordem e dependências

A ordem das trilhas segue as regras "não usar X antes de Y" do dossiê 02 (§6.2). As principais:

- *be* firme antes do presente simples; 3ª pessoa depois de I/you/we/they + *do*; contínuo depois do simples; *going to*, contínuo como futuro e passado contínuo depois do contínuo. Verbos de estado (*need, know, like, want, understand*) ficam no simples desde a trilha do contínuo.
- *was/were* (e *there was / there were*) antes do passado lexical; *did/didn't* depois do passado afirmativo.
- *present perfect* só depois do passado sólido e dos particípios; *for/since* só depois do contraste com o passado; *present perfect continuous* depois de *for/since*.
- *past perfect* depois da narrativa com passado simples e contínuo; 3ª condicional depois do *past perfect* e dos modais no passado; mistas depois da 2ª e da 3ª; invertidas só no C1, em registro escrito.
- passiva depois de *be* em vários tempos e dos particípios; *get* + particípio no B1, logo depois da passiva com *be*.
- **pergunta indireta (deducao-perguntas-indiretas) antes do discurso indireto**, para a ordem direta da pergunta encaixada estar firme quando chegar o recuo de tempo [02 D13].
- inversão-fórmula no B2 só em escrita e discurso, sistemática no C1; clivadas depois das relativas.
- estruturas B1 de alta frequência no B1, não no C1: *be supposed to* (trilha modais-no-passado), *get* + particípio (passiva-1), *had better* (deducao-perguntas-indiretas).

**Fórmulas antecipadas** (permitidas como chunk fechado antes da regra, e marcadas como "fórmula" no campo `gramatica` do JSON; o validador L03 lê esta lista):

| Trilha | Fórmulas | A regra abre em |
|---|---|---|
| 1 primeiro-contato | *I'm...*, *How's it going?*, *I'm good, thanks. How about you?*, *Sorry, I didn't catch that.*, *Can you repeat that, please?*, *More slowly, please.*, *Have a nice day.*, *Let me think.* | be (3), imperativo (8), *didn't* (24), *Let me* (27) |
| 2 numeros-horas-soletrar | *It's + hora/preço*, *How much is it?*, *What time is it?*, *How do you spell it?* | do (11) |
| 3 eu-e-voce-be | *What's your name?*, *Where are you from?* | Wh- com be (5) |
| 9 situacao-hotel | *I'm here on business.*, *I have a reservation.*, *There's no hot water.*, *I work for...*, *fifth floor* | there is (19), presente (10), ordinais (13) |
| 10 presente-simples | *I want to... / I need to... / I'd like to...* + verbo | verbo + to (39) |
| 16 situacao-cafe-restaurante | *I'd like...*, *Can I have...?* | would (B1) |
| 21 situacao-caminho-compras | *I'll take it.* | will (32) |
| 27 dev-ponte-a1 | *Let me...* | — |
| 41 convites-pedidos | *How about + -ing?* (primeiro caso de preposição + -ing) | preposição + -ing (65) |
| 52 ja-fui-x-fui | *got promoted* | get + particípio (59) |
| 58 situacao-entrevista | *Tell me about yourself.*, *One of my strengths is...* | — |

**Interferências por nível** [04 §6]: BR01–BR20 no A1; BR21–BR46 no A2; BR47–BR48 e BR50–BR59 no B1; BR49 (*be used to*) e BR60 (evitação de phrasal verbs) no B2, porque *be used to + -ing* depende do gerúndio depois de preposição (B1) [02 D16]. A revisão final acrescentou três pontos que faltavam na lista do dossiê:

| Código | Interferência | Entra | Retoma |
|---|---|---|---|
| **BR61** | querer / precisar / gostaria que + subjuntivo → *want / need / would like* + pessoa + *to* (não: *I want that you...*) | A2, verbo-to-ing | discurso-indireto (*ask / tell sb to*), verbos-de-relato (*expect / allow sb to*), pro-lideranca-feedback |
| **BR62** | verbos pronominais do PT sem *-self* (*me sinto = I feel*, *me mudei = I moved*) x reflexivo real (*hurt myself*, *by myself*, *Help yourself!*) | A2, adverbios-phrasal-possessivos | revisao-a2, ha-quanto-tempo (*each other*), situacao-vida-social |
| **BR63** | durante: *for* + duração x *during* + evento (não: *during three years*) | A2, contar-historia | situacao-viagem, revisao-a2, ha-quanto-tempo |

**Cada BR volta pelo menos 3 vezes depois de entrar**, em distância crescente, e cada retomada fica rotulada numa lição (`br` e `recicla`). A tabela completa BR → trilha que introduz → trilhas de retomada está em `esboco.json` (`interferenciasBR`) e é gerada e conferida pelo validador.

---

## 5. Regras de conteúdo para os autores

Os autores são agentes que escrevem as lições de uma trilha a partir do `esboco.json`. Esta seção é o contrato deles.

### 5.1 Formato de uma lição

O `esboco.json` é o **roteiro**: cada lição traz objetivo, foco, itens novos, apoio, cena, reciclagem, interferências e 3 a 5 exemplos de referência. A próxima fase gera, a partir dele, **um arquivo JSON por lição** no formato abaixo, com as `nFrases` frases completas; um validador de schema (F09, F10, D09) roda antes de qualquer revisão de conteúdo. As chaves de frase reaproveitam as que o app já lê (`cod`, `dica`, `lit`, `conceito`, `alvo`); as novas são opcionais até o loader ser atualizado.

```json
{
  "id": "there-is-lugares.tem-farmacia-aqui-perto",
  "trilha": "there-is-lugares",
  "nome": "Tem uma farmácia aqui perto?",
  "emoji": "💊",
  "cena": "Na rua, perto do hotel em Chicago, você pede ajuda a uma moradora.",
  "resumo": "Perguntar o que existe por perto: Is there...? / There's...",
  "fechamento": false,
  "novos": ["Is there...?", "near here", "next to"],
  "apoio": ["pharmacy", "bank"],
  "teoria": [
    {"t": "h", "c": "Tem (existir) = there is"},
    {"t": "p", "c": "Para dizer que algo existe, o inglês usa **there is / there are**, nunca *have*."},
    {"t": "ex", "c": "There's a bank near here.\nTem um banco aqui perto."}
  ],
  "trechos": [
    {
      "id": "f-7c1e2a",
      "quem": "voce",
      "cod": "Excuse me, is there a pharmacy near here?",
      "dica": "Com licença, tem uma farmácia aqui perto?",
      "alvo": "is there",
      "alvo_pt": "tem",
      "lit": "[lit.: existe uma farmácia perto daqui?]",
      "conceito": "Tem, no sentido de existir, é there is. Have é posse.",
      "registro": "neutro",
      "interferencias": ["BR03"],
      "armadilhas": ["have", "has"],
      "teste": true,
      "origem": "autoral_ia"
    },
    {
      "id": "f-03b9d4",
      "quem": "moradora",
      "contexto": "f-7c1e2a",
      "cod": "Yes, there's one next to the bank.",
      "dica": "Tem, sim, uma do lado do banco.",
      "alvo": "next to",
      "alvo_pt": "do lado do",
      "opcional": [],
      "var": [{"em": "there's", "aceita": ["there is"]}],
      "registro": "informal",
      "interferencias": ["BR03"],
      "origem": "autoral_ia"
    }
  ]
}
```

| Campo | Obrigatório | Regra |
|---|---|---|
| `id` | sim | **identificador opaco** (ex.: `f-` + 6 hexadecimais), gerado uma vez e gravado no JSON; nunca derivado da posição nem do texto. É a chave do progresso da pessoa (2.10). O `id` da lição vem do esboço (`trilha.slug-do-nome`) e também não muda depois de publicado |
| `cod` | sim | a frase em inglês que se digita (regras 5.2) |
| `dica` | sim | a tradução PT-BR que fica em cima (regras 5.3) |
| `alvo` | sim* | o chunk-alvo, **substring exata** de `cod`, um por frase, tirado de `novos`. *Vazio só nas cenas de fechamento e nas lições de contraste, onde pode marcar o chunk reciclado principal |
| `alvo_pt` | sim se houver `alvo` | o trecho correspondente, **substring exata** de `dica` |
| `quem` | sim | quem fala: `voce`, `ana`, `mike`, `sarah`, `ben`, `emma`, `lucas`, `julia`, `dra-lee` ou um papel genérico (`atendente`, `recepcionista`, `oficial`, `moradora`, `cliente`, `recrutadora`, `dev-novo`). **Um `quem` por item: nunca duas falas no mesmo `cod`** |
| `contexto` | quando a frase é resposta ou o PT sozinho for ambíguo | o `id` da fala anterior (o app mostra a `dica` dela em PT até ela concluir; depois, o `cod`, em 2.2) ou, se a fala não é frase-alvo do curso, o texto em inglês ASCII (ex.: a pergunta do oficial da imigração) |
| `lit` | não | glosa literal **só do trecho divergente**, formato `[lit.: ...]`, até 60 caracteres, no máximo uma por frase |
| `conceito` | não | nota de **uma linha** em PT, até 120 caracteres, explicando o porquê |
| `var` | não | variações de **forma** por trecho: `[{"em": "trecho do cod", "aceita": ["outra forma"]}]`; nunca sinônimos do alvo. As variações automáticas de 3.3 não precisam ser declaradas |
| `opcional` | não | palavras que podem faltar sem erro (*some*, *that*, *one*) |
| `blocos` | se a frase tiver mais de 10 palavras | posições de corte na fronteira de chunk, usadas só para dividir sanguessugas (2.8) |
| `pt_f` | quando muda | a tradução no feminino, se o gênero de quem fala (o aluno) muda o PT ("Estou cansado" → "Estou cansada") |
| `registro` | sim | `informal`, `neutro`, `formal` ou `escrito-trabalho` |
| `interferencias` | quando houver | códigos BR## que a frase treina |
| `armadilhas` | não | palavras ou prefixos errados previstos, em minúsculas, para telemetria (nunca exibidos como alvo); o motor palavra a palavra os reconhece (2.5) |
| `teste` | não | `true` na frase que representa a lição no "testar para pular" (padrão: a primeira com alvo) |
| `bio` | quando usa campos do perfil | lista dos campos (`nome`, `cidade`...) que aparecem como `{campo}` no `cod` e na `dica` (5.5) |
| `origem` | sim | `autoral_ia`, `autoral_humana`, `tatoeba` ou `tatoeba_adaptada` |
| `fonte` | se `tatoeba*` | `{en_id, en_autor, pt_id, pt_autor, pt_autoral, licenca: "CC BY 2.0 FR", modificada, nota_modificacao, export}` [07 §7.1] |
| `variacao_de` | não | `id` da frase-moldura, quando a frase é variação de slot da mesma moldura |
| `fala` / `heteronimo` | não | texto alternativo só para o TTS (siglas) e marcação de heterônimos (*read*, *live*, *lead*) |

Campos da lição: `id`, `nome` (PT, até 40 caracteres), `emoji`, `cena` (1 frase PT), `resumo` (1 frase), `fechamento` (true na última lição de cada trilha comum), `contraste` (true na lição de contraste), `novos` (os itens de `vocabulario` do esboço: no máximo nFrases ÷ 2; zero no fechamento e no contraste), `apoio`, `teoria` (0 a 5 blocos, até 600 caracteres somados; exemplos `ex` no formato `EN\nPT`).

### 5.2 Regras do inglês (`cod`)

1. **Natural, atual e útil:** algo que um nativo americano diria hoje naquela situação. Teste: dá para nomear quem diz, para quem e onde? Nada de frase de exemplo de gramática nem de frase absurda (*the bear drinks beer*; *The theory of this system is simple.*) [05 A4; 07 N06].
2. **Inglês americano, consistente:** *color, center, organize, traveled, check (conta), vacation, apartment, on the weekend, Do you have...?, standup, resume (currículo), a drop in the bucket, couldn't have (dedução)*. **Nunca como alvo:** *shall* (exceto um *Shall we?* isolado, como nota), *mustn't*, *needn't*, *have got*, *at the weekend*, *flat*, *holiday*, *mind you*, *take on board*, *quite* no sentido de "razoavelmente", *brilliant* no sentido de "ótimo", *the daily*. Britanismos só em nota de reconhecimento, na trilha registro-variantes [04 §5].
3. **Contrações em conversa** (*I'm, don't, it's, I'll, let's, that's*); formas plenas só com registro formal ou ênfase declarada [07 N05; 02 D23]. Dentro de uma trilha, a mesma estrutura sempre com a mesma escolha (contração ou forma plena).
4. **Uma novidade por frase:** o item novo (o `alvo`) é uma estrutura **ou** 1–2 palavras (A1–A2) **ou** até 3 palavras (B1+). Todo o resto já foi visto no curso, é transparente ou é **uma** palavra de `cena`, glosada. Estrutura nova entra com vocabulário velho; palavra nova entra em estrutura velha [02 §5.2].
5. **Cada item novo da lição é alvo de pelo menos 2 frases dela** (moldura com o slot trocado), e volta em pelo menos 2 lições seguintes (pelo `recicla`). Repetição com variação é melhor que repetição idêntica [03 §10.2].
6. **Vocabulário dentro da faixa da trilha** (`vocabulario.faixa`), exceto o `alvo`, a palavra de `cena` e nomes próprios [07 L01].
7. **Gramática só da trilha atual ou anteriores**, mais as fórmulas da tabela de 4.4. Nada de estrutura que só aparece depois. Item marcado como reciclado (*"(A1, trilha 14)"*) precisa existir de fato onde diz (o validador confere `recicla` ⊆ já visto).
8. **Comprimento:** dentro de `maxPalavras` e `maxCaracteres` da trilha e, para a recordação literal, **no máximo ~14 palavras e uma ideia**. Do B2 em diante, 15 a 18 palavras só quando inevitável, marcadas (o D4 e a prova do dia ficam em N2). Frase com duas orações vira, de preferência, **dois itens encadeados** pelo `contexto`.
9. **Frase inteira e uma fala só:** começa com maiúscula e termina com `.`, `?` ou `!`. Um item pode ter duas frases curtas **da mesma pessoa** (*Thanks for having me. Can I bring anything?*). Pergunta e resposta nunca no mesmo `cod`: a resposta vira item próprio, com a pergunta no `contexto` (o validador barra `?` seguido de *Yes/No/So/Neither/For...*).
10. **Sem anáfora solta:** pronomes (*he, it, that, they*) só com antecedente na própria frase ou na cena [07 L04].
11. **Variedade na lição:** nenhum tempo verbal acima de 60% das frases (salvo o foco da trilha) e no máximo 30% das frases com a mesma primeira palavra, **também nos exemplos do esboço**. Varie a abertura com pergunta, resposta, fala de outro personagem e frase de reciclagem [07 D02, D03].
12. **Sem estilo de IA:** nada de *delve, vibrant, bustling, seamless, tapestry, embark, foster, showcase, pivotal, journey* (figurado), *in today's world*; nada de oração de particípio no fim (*, making it easier*); nada de abrir com *Interestingly, Notably, Ultimately* [07 N03, N04].
13. **A forma errada nunca é `cod`.** Ela pode aparecer no `conceito`, entre parênteses e começando por "não:" (ex.: "(não: I have 30 years)") [04 T19].
14. **Registro adequado à cena:** inversões literárias (*Never have I..., No sooner had..., Were I to..., But for...*) e *It is said that* só em cena escrita ou de discurso (relatório, e-mail formal, política, avaliação escrita, brinde); na conversa, a forma direta. *whom* só como reconhecimento ou numa única frase de e-mail muito formal.
15. **Tom de trabalho americano:** postmortem sem culpados (o sujeito é o processo ou *we*, nunca um colega); nada de fofoca sobre pessoas do elenco; aviso a colega com *Make sure...*, não com *You'd better...*; resposta de entrevista sem recitar o método (*The situation was that... / My task was to...*).

**Tipografia do `cod` (validada automaticamente)** [06 B8]:
- Só **ASCII imprimível** (U+0020 a U+007E). Apóstrofo reto `'`. Um espaço entre palavras; nada no começo ou no fim.
- **Proibidos:** `& < > # @ * _ | \ [ ] ~ ^ ( )` `` ` ``, aspas curvas, travessão, reticências (`...` ou `…`), tabulação e quebra de linha. Chaves `{ }` só nos campos do perfil (`{nome}`), substituídos antes da validação. Rótulos de code review vão sem parênteses (*Non-blocking: ...*).
- **Evitar aspas duplas `"`:** use discurso indireto ou ponha cada fala num item separado, com `quem`.
- **Sem acentos:** *cafe*, *resume*, *naive*. Nomes e cidades brasileiras sem acento no `cod` (*Julia*, *Brasilia*, *Sao Paulo* evitado em favor de *Curitiba*, *Recife*, *Salvador*).
- Apóstrofo antes de vogal, *c* ou *y* (*o'clock*) é permitido, mas gera aviso: o motor trata, e o revisor confere.
- **Números:** por extenso de zero a dez e quando o número é o conteúdo (trilha 2); dígitos para horas (*7:30*, *9:00*), anos, preços (*$15*), versões (*2.1*) e quantidades grandes; porcentagem sempre *percent* (nunca `%`). Datas por extenso, padrão americano, com ordinal na fala (*on October fourth*) e dígito na escrita (*May 1*). Nada de `£`, `€` ou `°` (escreva *euros*, *degrees*).
- Pontuação americana: *Mr.*, *Dr.*, vírgula serial.

### 5.3 Regras da tradução (`dica`)

1. **PT-BR natural, do jeito que um brasileiro diria naquela situação** (WhatsApp, padaria, daily): *Never mind.* = "Deixa pra lá."; *What do you do?* = "Você trabalha com o quê?"; *I used to live in Rio.* = "Eu morava no Rio." [04 T1].
2. **Mesma função e energia:** pergunta continua pergunta, exclamação continua exclamação, mesma pontuação final [04 T2].
3. **Nunca deformar o PT para espelhar o inglês.** O espelho vai na glosa: "Tenho 30 anos." com `[lit.: eu sou 30 anos velho]` [04 T3].
4. **A armadilha fica no PT:** se a lição treina *There's*, o PT diz "Tem"; se treina *Currently*, o PT diz "Atualmente", e o `conceito` avisa [04 T4].
5. **Determinismo (o PT leva a um único inglês):** explicitar posse ("a mãe **dela**"); usar âncoras de tempo (**já, ainda não, nunca, há, desde, ontem**); microcontexto entre parênteses no começo quando a frase isolada for ambígua: "(no restaurante)", "(ao telefone)", "(combinado)", "(e-mail)", "(no discurso)", "(dedução)", "(conselho)" [04 T5, T10, T18; 02 §8]. Sinônimo provável fora do alvo (*acabado* → *worn out / exhausted / tired*) se resolve com `var` (forma), com a regra do sinônimo fora do alvo (2.5) ou, se for léxico de cena, com um gancho no PT só nas frases que não são de recordação do item.
6. **Âncoras fixas dos tempos sem par em PT:** *used to* = imperfeito; *present perfect* de experiência = "já"/"nunca"; resultado = "já"/"ainda não"/"acabei de"; com *for/since* = presente + "há"/"desde"; *simple past + ago* = "há" + passado; *when/if* + presente = futuro do subjuntivo ("quando eu chegar"); *past perfect continuous* = "fazia X que eu estava + gerúndio" (não "vinha... havia", escrito demais para conversa) [04 T10].
7. **"Já" só quando o inglês tem *already / ever / yet / by now*.** Nos demais casos, tirar o "já" ("Até sexta, a gente vai ter terminado") ou contar com a variação automática *already* opcional (3.3, regra 7). "Já vou!" (= *I'm coming!*) e "já que" (= *since*) são fórmulas à parte.
8. **Pista obrigatória para o futuro quando o futuro é o alvo:** "(combinado)" = contínuo; "(promessa)" e "(decidi agora)" = *will*; "(previsão)" ou evidência na própria frase = *going to*. Fora das lições de futuro, os três são aceitos (3.3, regra 10).
9. **Adjunto de tempo e lugar na mesma posição nos dois lados** quando as duas ordens soam naturais em PT ("Estou trabalhando de casa hoje." para *I'm working from home today.*). Se o PT ficar mais natural com o adjunto no começo, o autômato aceita as duas posições (3.3, regra 6).
10. **Registro:** sempre "você", nunca "tu"; "a gente" em `informal`, "nós" em `neutro` e escrito; "o senhor/a senhora" só quando o inglês marca formalidade (nunca para uma diretora de empresa de tech: "Será que você poderia...?"); gíria no PT só quando o inglês é gíria ("Valeu" = *Thanks!*, não *Thanks a lot*) [04 T11].
11. **Imperativo único:** na fala informal e neutra, a forma falada ("Entra", "Vira", "Pega", "Verifica", "Não se preocupa"); no registro formal e escrito (e-mail, instrução escrita, consulta médica, entrevista), a forma padrão ("Entre", "Verifique", "Tome").
12. **Gênero:** o aluno no masculino por padrão, com `pt_f` quando a forma muda; na 3ª pessoa, coerente com *he/she* [04 T12].
13. **Anglicismos de TI** onde o dev brasileiro fala assim (deploy, build, commit, bug, merge, PR, sprint, daily, feature, release, contractor, invoice); palavra PT onde ela é corrente (arquivo, pasta, tela, botão, senha, servidor, banco de dados). **"A sprint"**, sempre no feminino. **Nunca "implantar"/"implantação"**: "fazer deploy", "subir", "ir pro ar"; *implementation* = "implementação" [04 T13].
14. **Comprimento:** até 1,3 vez o `cod` mais 10 caracteres. Se não couber, a frase é longa demais nas duas línguas [04 T16].
15. **Glossário travado:** o mesmo chunk recebe a mesma tradução no curso todo, salvo quando o sentido muda. **Antes de escrever, consultar `esboco.json` → `glossario`** (*Desculpa* = *Sorry*, *Me desculpa / Sinto muito* = *I'm sorry*; *Essa X é sua?* = *Is this your X?*; *Isso é seu?* = *Is this yours?*; *Eu adoro + verbo* = *I love + -ing*; *Trabalho aqui há...* = *I've worked here for...*; *Talvez* = *might*; *Eu abro a janela?* = *Should I...?*; *Quer que eu...?* = *Do you want me to...?*; *pretender* = *plan to*; *daily* = *standup*; *música (a faixa)* = *song*, *o som* = *music*...). O D05 é bidirecional e bloqueante: a mesma âncora PT com inglês diferente só passa com pista diferente entre parênteses [04 T17].
16. **Falsos cognatos:** o PT nunca usa o cognato enganoso como tradução (*actually* ≠ "atualmente", *eventually* ≠ "eventualmente", *attend* ≠ "atender", *cafeteria* ≠ "cafeteria" (= refeitório), *resume* ≠ "resumir" (= currículo), *promotion* no trabalho = "foi promovido") [07 T05].
17. **Números espelhados:** palavras no inglês = palavras no PT; dígitos = dígitos ("7:30" ↔ "7h30", "9:00" ↔ "9h00", *percent* ↔ "por cento"). Nunca "às 9h" para *at 9:00*.
18. **Nomes iguais nos dois lados** (*Mike* não vira "Miguel").
19. **Ortografia pós-Acordo e acentos sempre** no PT (ideia, voo, meio-dia). Sem marcas de Portugal (*estou a fazer*, *pequeno-almoço*, *autocarro*, *telemóvel*, *equipa*, *facto*). Regência correta ("de cuja aprovação você precisa"; nada de "cuja... a gente").

### 5.4 Chunk-alvo, glosa e nota

- **`alvo`** é o item novo da frase. O app o destaca na mesma cor no PT (`alvo_pt`) e na máscara.
- **`lit`** só quando a estrutura diverge do português e a glosa literal ajuda a memória (*there is*, *'s*, *do* em pergunta, idade com *be*, phrasal verbs opacos, idioms). Glosa em toda frase vira ruído [04 T6].
- **Phrasal verbs** são traduzidos pelo sentido; a partícula só vai na glosa (`sit down = sentar [down: para baixo]`) [04 T8].
- **Idioms:** equivalente idiomático em PT quando existir ("Não é a minha praia." para *It's not my cup of tea.*; "uma gota no oceano" para *a drop in the bucket*), com a literal como gancho [04 T9].
- **`conceito`:** uma linha, o porquê, sem aula. Bons exemplos: "to go = pra viagem (EUA)"; "Tem, no sentido de existir, é there is."; "actually = na verdade; atualmente = currently"; "daily (BR) = standup (EUA)"; "cafeteria (EUA) = refeitório".

### 5.5 Cenas, elenco, ficha do aluno e reciclagem

- **Cada lição é uma cena** (micro-diálogo ou situação contínua) com as frases encadeadas na ordem da cena. A primeira frase da lição é a mais simples [05 M4]. A cena tem de ser coerente com a frase: ninguém pergunta a idade para o crachá, uma viagem doméstica não perde passaporte, o amigo de cinco anos não pergunta se você é brasileiro.
- **Elenco fixo** (nomes ASCII curtos que o TTS pronuncia bem; nada de Tom e Mary) [06 B8; 07 D04], com papéis travados em `esboco.json` → `personagem.elenco`:
  - **Você** (o aluno): dev brasileiro que trabalha remoto para uma empresa americana. A empresa e os produtos não têm marca ("our company", "the app").
  - **Mike:** tech lead americano, em Chicago. **Sarah:** product manager, em Austin. **Ana:** colega brasileira, designer, cresceu em Recife.
  - **Ben:** amigo americano, em Boston (não é colega de trabalho). **Emma:** vizinha e anfitriã nas viagens.
  - **Lucas** (irmão) e **Julia** (irmã). **Dra. Lee:** médica.
  - Papéis genéricos: atendente, recepcionista, oficial da imigração, motorista, cliente, recrutadora, dev novo do time.
- **Ficha do aluno:** a pessoa vai decorar as frases sobre si mesma, então elas não podem se contradizer nem inventar uma vida que não é a dela. Frase de biografia do aluno usa os **campos do perfil** (`{nome}`, `{sobrenome}`, `{sobrenome_soletrado}`, `{cidade}`, `{cidade_natal}`, `{idade}`, `{anos_dev}`), preenchidos no `cod` e na `dica` quando a lição é montada (padrão: Carlos, Souza, Curitiba, Curitiba, trinta e dois, oito). Os fatos fixos (trabalha de casa desde 2020; entrou na empresa há dois anos; adora café...) estão em `personagem.aluno.fatos_fixos`. Fato de vida que não cabe na ficha (namorada, ter morado em Recife, ano de nascimento) vai para outro personagem. O validador de coerência compara cada frase de `quem: voce` com a ficha.
- **Fio narrativo por etapa:** A1, a primeira viagem a Chicago para conhecer o time (começando pela imigração); A2, os primeiros meses no emprego, viagens, saúde e rotina; B1, entrevista para uma vaga sênior e três meses no escritório de Austin; B2, o time cresce (reuniões, code review, incidentes) e a vida prática nos EUA (carro, atendimento); C1, o aluno vira tech lead e tem vida social com os americanos; dev, um dia inteiro de tech lead. O fio dá contexto, mas **cada frase precisa fazer sentido sozinha** (com o `contexto`, quando for resposta).
- **Reciclagem com lastro:** cada lição do esboço traz em `recicla` **3 a 5 itens** de trilhas anteriores, em distância crescente (**1, 3, 8 e 20 trilhas para trás**), mais a **cota eterna** (do A2 em diante, um destes pontos por lição, em rodízio: -s da 3ª pessoa, artigos, *do* em perguntas e negativas, *present perfect* x passado, preposições, *it* obrigatório) e, quando for o caso, a **retomada de um BR** (4.4). O autor usa esses itens como o "material já visto" de pelo menos 70% da lição [02 §5.2, §5.2.7]. O validador D06 confere, lição a lição, que os itens de `recicla` já foram vistos e que a cota aparece em pelo menos uma frase.
- **Pares de interferência nunca na mesma lição** (exceto na cena de fechamento, na lição de contraste e nas revisões): *left/right*, *Good evening/Good night*, *thirteen/thirty*, *lend/borrow*, *make/do*, *say/tell*, *come/go*, *bring/take*, *meet/know*, *miss/lose/waste*, *win/earn*, *hear/see*, *a few/a little*, *put on/take off*, *despite/in spite of*, *get along with/get on with*, *should have/was supposed to*, *look at/look for/look after*, *I think so/I don't think so*, *far/near*, *this/that* no primeiro contato [03 §5.2, §10.2].
- **Molduras com slot** são o jeito de "escrever várias vezes sem tédio": *I'd like a coffee / I'd like the check / I'd like a window seat* (marcar `variacao_de`) [03 §5.1].

### 5.6 Origem das frases

- Duas origens permitidas: **autoral** (IA revisada ou humana) e **Tatoeba** (CC BY 2.0 FR, com atribuição por frase). Ordem de preferência para cada slot: (a) adotar uma frase do Tatoeba que encaixe, (b) adaptar (trocar nome ou objeto; `modificada: true`), (c) escrever [07 §6.3].
- Candidatas já filtradas: `pesquisa/fontes07/tatoeba_candidatas_en_ptbr.tsv` (85.460 pares, dono nativo, tradutor brasileiro, antes de dez/2022, sem tema sensível). **O PT do Tatoeba sempre passa pelas regras 5.3**: a amostra auditada teve 3% de erro de sentido [07 §2.5.8].
- Metas iniciais de proporção: ≥ 40% de frases adotadas ou adaptadas do Tatoeba no A1–A2; 20–30% no B1–B2; 100% autorais nas trilhas de dev e na etapa dev [07 §6.4].
- **Proibido como fonte:** legendas (OpenSubtitles), decks do AnkiWeb, DailyDialog, exemplos de dicionário, concordâncias de COCA, SkELL ou Ludwig, letras de música, livros didáticos [07 P05].

### 5.7 Proibições de conteúdo

- **Temas sensíveis:** violência, morte, armas, drogas, sexo, política partidária, religião em tom de juízo, insultos, doença grave. Exceções úteis e marcadas: *Call an ambulance!*, *I'm allergic to peanuts.*, *I need a doctor.*
- **Marcas:** nenhuma empresa, app comercial, rede social, loja, bebida, carro ou produto de consumo (nada de Google, Slack, Zoom, Uber, iPhone). Termos técnicos genéricos (pull request, repo, API, JSON, cache) e nomes de linguagens e ferramentas abertas (Git, Python, JavaScript, Dart, Flutter) podem aparecer, com parcimônia e só em contexto técnico.
- **Gírias datadas ou de internet** (*groovy, rad, on fleek, bae, YOLO, lit*), palavrões e *gonna/wanna/kinda* como alvo de digitação (podem aparecer só em nota de reconhecimento no B2) [04 T11].
- **Pessoas reais** que não sejam figuras públicas, estereótipos de gênero, nacionalidade ou idade, e fatos falsos ou datados sem propósito (fax, VHS, telegrama) [07 C02–C04].
- **Frases que só existem para mostrar gramática** e frases absurdas.

### 5.8 Exemplos

| Ruim | Por quê | Bom |
|---|---|---|
| `The book is on the table.` / "O livro está sobre a mesa." | sem situação, sem utilidade | `Your keys are on the table.` / "Suas chaves estão em cima da mesa." (cena: saindo de casa) |
| `I am a developer and I am working with Flutter.` | sem contração em conversa; duas novidades | `I'm a developer. I work from home.` / "Sou desenvolvedor. Trabalho de casa." |
| `Let's delve into the vibrant streets of the city.` | vocabulário de IA | `Let's walk around downtown.` / "Vamos dar uma volta no centro." |
| "Eu costumava viver no Rio." para `I used to live in Rio.` | decalque | "Eu morava no Rio." |
| "Vamos sair." para `Let's go out.` | admite *We're going out.* | "(convite) Vamos sair hoje à noite?" ou `contexto` que desambigua |
| "Ela ligou para a mãe." para `She called her mother.` | "a mãe" é ambíguo | "Ela ligou para a mãe dela." |
| `I've lived here for five years.` / "Moro aqui há cinco anos." no A2 | *for* + perfect só no B1 | fica para a trilha `ha-quanto-tempo` |
| `Make sure that "debug" is set to false.` | aspas duplas, tecla morta no US-Intl | `Make sure that debug mode is off.` |
| `I'm fine, thanks. And you?` como primeira frase do curso | clichê de livro; o americano não fala assim | `I'm good, thanks. How about you?` / "Tudo bem, obrigado. E você?" |
| `Have you ever been to Salvador? Yes, I went there in 2019.` | duas falas no mesmo `cod`; a resposta vira cópia do auxiliar | dois itens: a pergunta, e `Yes, I went there in 2019.` com a pergunta no `contexto` |
| `You mustn't park here.` / "É proibido estacionar aqui." | britânico; o americano diz *can't* | `You can't park here.` |
| `Sorry, I've broken the build.` | en-US usa o passado aqui | `Sorry, I broke the build.` (ou, na lição de present perfect, `Have you pushed the fix yet?`) |
| `Never have I seen such a beautiful place.` dito à vizinha | inversão literária em conversa soa teatral | na conversa, `I've never seen such a beautiful place.`; a inversão vai para a avaliação escrita |
| `I'm thirty-two years old.` / `I was born in Curitiba, in 1994.` | inventa a biografia do aluno, que vai decorá-la | `I'm {idade} years old.` / `I was born in {cidade_natal}.` (campos do perfil) |
| `The situation was that our app was crashing...` (22 palavras) | recita o método STAR e passa do limite de recordação | `At my last company, our app kept crashing on older phones.` |

---

## 6. Checklist de qualidade, frase a frase

Para revisores automáticos. Baseado no dossiê 07 (§8), com as regras dos dossiês 02, 03, 04 e 06. Severidades: **BLOQUEIA** (a frase não entra como está), **AJUSTAR** (precisa mudar; o revisor sugere a correção) e **AVISO** (entra e fica registrado). Decisão: `rejeitar` se houver BLOQUEIA não autocorrigível; `ajustar` se houver BLOQUEIA autocorrigível ou AJUSTAR; `aprovado` no resto.

### 6.1 Formato e teclado (determinístico)

| ID | Regra | Teste | Sev. |
|---|---|---|---|
| F01 | `cod` só em ASCII imprimível | `^[\x20-\x7E]+$` | BLOQUEIA (autocorrige `’` → `'`, aspas curvas, NBSP) |
| F02 | Sem `& < > # @ * _ \| \ [ ] ~ ^ ( )` `` ` ``; `{ }` só nos campos do perfil, substituídos antes | regex | BLOQUEIA |
| F03 | Sem espaço duplo, nem no começo ou no fim | regex | BLOQUEIA (autocorrige) |
| F04 | Maiúscula inicial e `.`, `?` ou `!` no fim | `^[A-Z0-9$]` e `[.?!]$` | BLOQUEIA |
| F05 | Sem `...`, `—`, `–`; aspas duplas geram aviso | regex | AJUSTAR / AVISO |
| F06 | Grafia americana | lista UK→US + LanguageTool `en-US` | AJUSTAR |
| F07 | `dica` com ortografia pós-Acordo, acentos e hífens corretos | lista + LanguageTool `pt-BR` | AJUSTAR |
| F08 | Comprimento dentro de `maxPalavras` e `maxCaracteres` da trilha; acima de 14 palavras, marca a frase como longa (D4 e prova em N2) | contagem por espaços | AJUSTAR / AVISO |
| F09 | `alvo` é substring exata de `cod`; `alvo_pt` é substring exata de `dica` | busca | BLOQUEIA |
| F10 | `id` único e no padrão; campos obrigatórios presentes | schema | BLOQUEIA |
| F11 | `dica` até 1,3 × `cod` + 10 caracteres | contagem | AVISO |
| F12 | Apóstrofo antes de vogal, *c* ou *y* | regex `'[aeiouyc]`, ignorando maiúsculas | AVISO |

### 6.2 Proveniência

| ID | Regra | Teste | Sev. |
|---|---|---|---|
| P01 | `origem` válida | schema | BLOQUEIA |
| P02 | Se `tatoeba*`: `fonte` completa (IDs, autores, licença, `modificada`) | schema | BLOQUEIA |
| P03 | IDs existem no export e o texto bate, ou a divergência está justificada | junção com o export | AVISO |
| P04 | Origem proibida (legenda, deck, dicionário, letra de música, livro didático) | declaração + juiz para frases autorais de 8+ palavras ("é citação famosa ou exemplo de dicionário?") | BLOQUEIA |
| P05 | Frase autoral idêntica a uma do Tatoeba com 6+ palavras → reclassificar e atribuir | busca exata | AJUSTAR |

### 6.3 Gramática e interferência

| ID | Regra | Teste | Sev. |
|---|---|---|---|
| G01 | Sem erro de gramática, digitação, palavra confundida ou colocação | LanguageTool `en-US` (estilo e pontuação viram aviso) | BLOQUEIA / AVISO |
| G02 | Nenhum padrão de interferência BR no `cod` | regex: `\bI (have\|has) \d+ years\b(?! of)`, `\bexplain me\b`, `\bdepends? of\b`, `\bdiscuss about\b`, `\bmarried with\b`, `\bmake a party\b`, `\bpeople is\b`, `\bthe life is\b`, `\bI am agree\b`, `\b(informations\|advices\|softwares\|feedbacks)\b`, `\ban? (advice\|information\|news)\b`, `\bwhen I will\b`, `\bfor to\b`, `\bcan to\b`, `\b(want\|need\|would like)s? that (you\|he\|she\|we\|they)\b` (BR61), `\bfeel (myself\|yourself\|himself\|herself)\b`, `\bmoved myself\b` (BR62), `\bduring (a\|one\|two\|three\|\d+) (years?\|months?\|weeks?\|days?\|hours?)\b` (BR63) | BLOQUEIA |
| G03 | Tempo coerente com o marcador (*since/for* + presente; *yesterday/ago/last* + presente; *ever/never/yet* conforme en-US) | regex de triagem + juiz | BLOQUEIA se confirmado |
| G04 | Ordem adjetivo-substantivo, posição do advérbio de frequência, *do/does* em perguntas | LanguageTool + juiz | AJUSTAR |

### 6.4 Naturalidade do inglês

| ID | Regra | Teste | Sev. |
|---|---|---|---|
| N01 | Atestação de trigramas contra o Tatoeba nativo pré-2022 (minúsculas, dígitos → `NUM`, nomes → `PROP`) | contagem local | triagem (alimenta N02) |
| N02 | Frequência com alternativas (Netspeak `web-en`): reprovar se a forma usada tiver < 10% da melhor alternativa no mesmo slot e a melhor tiver ≥ 1.000; aprovar com ≥ 1.000 e ≥ 20%; aviso entre os dois | `netspeak.py` com cache | AJUSTAR |
| N03 | Variante: expressões com par conhecido não podem ser mais britânicas que americanas; **lista de bloqueio**: *shall* (exceto *Shall we?* isolado em nota), *mustn't*, *needn't*, *mind you*, *take on board*, *a drop in the ocean*, *quite* (= razoavelmente), *brilliant* (= ótimo), *can't have* + particípio, *the daily* | Google Books Ngram, 2015–2019, `en-US` x `en-GB` + lista | AJUSTAR (lista: BLOQUEIA) |
| N04 | Vocabulário de IA fora do lugar (lista de 5.2.12 e a de [07 N03]) | lista de lemas | BLOQUEIA no A1–B1; AVISO no B2+ |
| N05 | Padrões estruturais de IA (particípio no fim, abertura com advérbio de comentário, nominalizações demais no A1–B1, *in order to* em conversa) | regex + contagem | AJUSTAR |
| N06 | Registro de conversa com contrações (formas plenas só com `registro: formal` ou ênfase) | regex `\b(I am\|do not\|does not\|it is\|cannot\|I will\|let us)\b` + juiz | AJUSTAR |
| N07 | Situação plausível: o juiz nomeia quem diz, para quem e onde | juiz LLM | AJUSTAR |
| N08 | Reescrita nativa adversarial: dois juízes reescrevem "exatamente como um nativo diria"; mudança material nos dois → AJUSTAR; em um só → AVISO e terceiro juiz | juízes LLM [07 §8.4a] | AJUSTAR / AVISO |
| N09 | Colocações-chave (verbo + substantivo, verbo + preposição, adjetivo + substantivo) testadas como em N02 | lista de verbos leves e preposições + Netspeak | AJUSTAR |

### 6.5 Nível e progressão

| ID | Regra | Teste | Sev. |
|---|---|---|---|
| L01 | Todo lema dentro da faixa da trilha, exceto `alvo` e nomes próprios | lematizador + NGSL / CEFR-J | AJUSTAR |
| L02 | No máximo uma novidade por frase em relação ao inventário acumulado do curso | diferença com o "já visto" | AJUSTAR |
| L03 | Só estruturas permitidas até a trilha (regras de 4.4 e a tabela de fórmulas antecipadas, lida pelo validador) | regex por estrutura (*have* + particípio, *would have*, *had* + particípio, *if ... were*...) + juiz | AJUSTAR |
| L04 | Sem anáfora solta | regex de pronome inicial + flag de cena | AVISO |
| L05 | No máximo 1–2 palavras desconhecidas além do alvo | como L01 | AJUSTAR |
| L06 | Par de interferência na mesma lição fora do fechamento | lista de pares | AJUSTAR |

### 6.6 Tradução PT-BR

| ID | Regra | Teste | Sev. |
|---|---|---|---|
| T01 | Sem palavras de Portugal e sem erro gramatical | LanguageTool `pt-BR` (`PT_BR_SIMPLE_REPLACE_*`, GRAMMAR) | BLOQUEIA |
| T02 | Sem marcas europeias (*tu* + verbo de 2ª pessoa, *estar a* + infinitivo, ênclise coloquial, *pequeno-almoço, casa de banho, autocarro, comboio, telemóvel, equipa, registo, facto, ecrã*) | regex | BLOQUEIA |
| T03 | **Fidelidade de sentido:** negação, tempo e aspecto, modalidade (*might, must, should, can, could*), frequência e quantidade (*often* = muitas vezes, *sometimes* = às vezes), singular ou plural de *you*, nada omitido ou acrescentado | juiz bilíngue [07 §8.4b] | BLOQUEIA |
| T04 | **Determinismo PT → EN:** retro-tradução cega 3 vezes, **já na geração**; cada retro-tradução tem de cair num caminho do autômato da frase (3.3), e nenhuma maioria pode ter sentido diferente | modelo sem acesso ao inglês [07 §8.4c] + autômato | AJUSTAR (pista, contexto, `var` ou gancho no PT) |
| T05 | Falso cognato no PT (*actually* → "atualmente" etc.) | lista de pares proibidos | BLOQUEIA |
| T06 | Naturalidade brasileira e registro ("Eu" redundante em sequência, futuro sintético na fala, mesóclise, *você/a gente/o senhor* coerente com `registro`) | regex + juiz | AJUSTAR |
| T07 | Nomes próprios iguais nos dois lados | tokens com maiúscula | AJUSTAR |
| T08 | Tipo de frase e pontuação final compatíveis | pontuação final | AVISO |
| T09 | Glosa só do trecho divergente; o mesmo chunk com a mesma tradução no curso; "já" na dica sem *already / ever / yet / by now* no `cod` | dicionário de chunks do curso + regex | AJUSTAR |
| T10 | Números espelhados (palavras com palavras, dígitos com dígitos) | regex | AJUSTAR |
| T11 | `pt_f` presente quando a fala do aluno tem adjetivo ou particípio com gênero | regex de terminações (-ado/-ada, -o/-a) em frases de `quem: voce` | AVISO |

### 6.7 Conteúdo

| ID | Regra | Teste | Sev. |
|---|---|---|---|
| C01 | Tema sensível (exceções marcadas `sensivel_ok`) | regex + juiz | BLOQUEIA no A1–B1; AJUSTAR no B2+ |
| C02 | Marca comercial, pessoa real privada, propaganda | lista + juiz | BLOQUEIA |
| C03 | Fato falso ou datado sem propósito | juiz | AJUSTAR |
| C04 | Estereótipo de gênero, nacionalidade ou idade | juiz | AJUSTAR |
| C05 | Utilidade para o perfil (adulto brasileiro, dev, viagem, trabalho), nota de 1 a 5 | juiz | AVISO se ≤ 2 |
| C06 | Forma errada no `cod` | G02 + juiz | BLOQUEIA |

### 6.8 Regras de lote (por lição e no curso)

| ID | Regra | Sev. |
|---|---|---|
| D01 | Quase-duplicatas (similaridade > 0,85 ou só o nome trocado), exceto com `variacao_de` | AJUSTAR |
| D02 | Nenhum tempo verbal acima de 60% da lição, salvo o foco da trilha | AJUSTAR |
| D03 | No máximo 30% das frases da lição com a mesma primeira palavra, também nos exemplos do esboço | AVISO |
| D04 | Cada item de `novos` é alvo de pelo menos 2 frases da lição; **novos × 2 ≤ nFrases** (no máximo 4 em lição de 8 frases e 5 em lição de 10); zero no fechamento e na lição de contraste; `novos` não repete item já visto (esse vai para `apoio`) | BLOQUEIA |
| D05 | Mesmo chunk, mesma tradução no curso todo, **nos dois sentidos**: a mesma âncora PT com inglês diferente só passa com pista diferente entre parênteses; confere contra `glossario` | BLOQUEIA |
| D06 | Por lição: `recicla` com 3 a 5 itens de trilhas anteriores (distâncias 1, 3, 8 e 20), todos já vistos; cota eterna presente em pelo menos 1 frase (A2+); ≥ 70% de material já visto; cada BR com pelo menos 3 retomadas rotuladas (`interferenciasBR`) | AJUSTAR |
| D07 | Detectabilidade: 20 frases nossas misturadas com 20 do Tatoeba; se o juiz acerta mais de 70% das nossas como "máquina", revisar o estilo do gerador | AVISO (lote) |
| D08 | Proporção de origens e lista de autores do Tatoeba atualizada para a tela de créditos | AVISO |
| D09 | Número de frases da lição = `frasesPorLicao` da trilha | BLOQUEIA |
| D10 | Uma fala por item: nada de `?` seguido de *Yes / No / So / Neither / For...* no mesmo `cod` | BLOQUEIA |
| D11 | Coerência da ficha do aluno: frase de `quem: voce` com fato de vida usa campo do perfil ou bate com `personagem.aluno.fatos_fixos`; nada em `personagem.aluno.nunca` | AJUSTAR |
| D12 | Fonte única: o número de lições, de frases e o fechamento de cada trilha vêm do `esboco.json`; as visões derivadas são regeneradas, nunca editadas | BLOQUEIA |
| D13 | Pares de interferência (5.5) fora da mesma lição, exceto fechamento, contraste e revisão; trilhas de pares confundíveis não consecutivas | AJUSTAR |

**Calibração antes de confiar no revisor:** conjunto-ouro com 300 pares bons (Tatoeba, inglês do CK e PT de tradutor brasileiro, revisados) e 300 ruins semeados (100 com interferência BR, 100 com estilo de IA, 100 com PT defeituoso). Metas: ≥ 90% dos ruins pegos nas camadas G, N e T, e ≤ 5% de alarme falso nos bons. Recalibrar a cada troca de modelo [07 §8.5].

---

## 7. Riscos e decisões em aberto

### 7.1 Riscos

| Risco | Mitigação |
|---|---|
| **Nenhum estudo testa exatamente esta tarefa** (frases inteiras de L2, digitadas, com tradução visível e pistas que somem). Ondas, 5 degraus, critério de 2 recuperações em N3 e teto 8 são extrapolações de pares de palavras e do COLT [01 §6]. | Telemetria de 2.11 desde o primeiro dia; ajustar ondas, teto e tamanho de lição pelos dados do próprio dono. |
| **Recordação literal de frases longas** sobrecarrega a memória de trabalho (8–12 palavras já pesam [01 §6.2]). | Teto de 18 palavras com alvo de ~14 (a média do C1 e da dev caiu de 16,3 para ~11,8 palavras na revisão final); frases de 15 a 18 marcadas fazem D4 e prova em N2; frase de duas orações vira dois itens; `blocos` para sanguessugas; critérios de nota proporcionais ao tamanho (2.6). |
| **Pesos padrão do FSRS** vêm de flashcards do Anki, não de frases digitadas. | Começar com Leitner (já pronto), migrar para FSRS e otimizar os pesos com 2 a 5 mil revisões. |
| **Naturalidade das frases de IA** e o dono não ser nativo (não é autoridade sobre o inglês). | Âncoras do Tatoeba, revisor em camadas com juízes adversariais e retro-tradução; o dono valida o PT por amostragem; telemetria aponta frases em que todos travam no mesmo ponto. |
| **PT ambíguo** faz a pessoa "errar" por escolher outra forma válida. | Autômato de variações (3.3), sinônimo fora do alvo valendo Difícil (2.5), glossário travado e D05 bidirecional, pistas de futuro e "já" (5.3), T04 com o mesmo autômato, sanguessugas viram fila de curadoria. |
| **Carga de revisões** cresce e desmotiva (o Anki prevê ~200 por dia com 20 novos). | Meta em minutos com as revisões limitadas a metade do tempo (e a 80 por dia), Difícil avançando meia caixa, "testadas, não vistas" em lote pequeno, freio suave, previsão de amanhã em minutos, meta leve a um clique. |
| **Áudio fraco no Safari e no iPhone** e cota do Gemini (~10 áudios por dia). | Invólucro próprio da Web Speech com ranking de vozes e dica "use Edge ou Chrome"; áudio pré-gerado com Kokoro na fase 2. |
| **Digitar no celular** é difícil e o teclado virtual autocorrige. | O curso é desktop primeiro; no celular, oferecer revisões e o arcade, com tolerância extra (decisão em aberto). |
| **Volume** (~21 a 24 meses na meta normal; ~320 a 370 horas no total) pode cansar. | Portões curtos com diagnóstico e "testar para pular", trilhas dev desde o A1, situações do dia a dia até o C1, cenas com fio narrativo, marcos e arcade. |
| **Licenças:** atribuição do Tatoeba por frase; listas NGSL (CC BY-SA) se embutidas; Lei 9.610 sobre compilações. | Campos de `fonte` por frase, tela de créditos, só embutir listas CC BY ou CC BY-SA; frases do curso sempre originais ou do Tatoeba [03 §4; 07 §7]. |
| **Gênero no PT:** o curso pode servir a outras pessoas. | `pt_f` quando muda e configuração de gênero no perfil. |
| **Biografia decorada que não é a do aluno** (nome, idade, cidade, anos de experiência). | Campos do perfil preenchidos ao montar a lição, ficha fixa em `personagem` e validador de coerência D11. |
| **Mecânica palavra a palavra é uma mudança grande no motor** (hoje tudo é letra a letra). | N0 continua letra a letra (o PAC de sempre); o modo palavra só entra nos níveis de memória, que já são telas separadas; dá para lançar primeiro só no N3 e estender a N1 e N2 depois. |

### 7.2 Decisões em aberto (para o dono)

1. **FSRS desde já ou Leitner primeiro?** Recomendação: Leitner (já implementado) no lançamento; FSRS quando houver ~2 mil revisões para otimizar.
2. **Ditado com ou sem a tradução em cima?** Recomendação: com, por padrão (respeita o pedido), com opção de esconder.
3. **Etapa dev no fim, como neste plano, ou liberada logo depois do B2?** O plano a põe depois do C1 por dependência gramatical; dá para liberar com aviso para quem testar o B2.
4. **Frases por lição no B2, no C1 e na dev** (8): com as frases encurtadas, a lição fica em 17 a 22 minutos e a meta em minutos absorve isso. Se a telemetria mostrar sessões acima da meta, cair para 6.
5. **Erro só de maiúscula:** a regra adotada é não derrubar a palavra, **exceto** em *I*, nomes do elenco, dias, meses, línguas e nacionalidades (BR15), inclusive na 1ª letra da frase.
11. **Critério de conclusão:** a revisão final adotou duas recuperações em N3 aceitas (D4 e prova), como pede o dossiê 01. Se a retenção no dia seguinte passar de 90% com folga, testar voltar ao critério de uma só (a prova), que encurta a lição.
12. **Modo palavra a palavra também em N1 e N2** ou só em N3 no lançamento (ver 7.1).
6. **Avanço automático depois do feedback** (2,5 s) ligado ou desligado por padrão.
7. **Celular:** só revisões e arcade, ou o curso inteiro com tolerância a autocorreção.
8. **Britânico:** só a trilha `registro-variantes` (reconhecimento) ou também uma voz britânica alternada nas revisões do B2+.
9. **Onda 2 e "Frases do mundo"** (Tatoeba) na v2 ou já no lançamento.
10. **Marcos e pontos:** confirmar os valores de 2.10 contra a escala do ranking atual dos outros cursos, para que o inglês não domine nem suma no ranking geral.
