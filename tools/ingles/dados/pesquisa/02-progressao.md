# 02 — Progressão CEFR A1→C1: gramática, funções, situações e a ordem dos blocos

> Frente de pesquisa 02 do curso de INGLÊS do PAC·DART (terceiro curso: frase em inglês para DIGITAR, tradução PT-BR EM CIMA, repetição para memorizar, do zero absoluto ao avançado).
> Data: 04/out/2026. Autor: subagente de pesquisa. Tudo aqui é insumo para quem desenha o currículo; nada foi escrito dentro do projeto.

---

## 0. Sumário executivo (leia isto se tiver 2 minutos)

1. **Existe consenso forte sobre a ordem do A1 ao B2.** O *Core Inventory for General English* (British Council/EAQUALS) foi montado justamente com os pontos presentes em **≥80%** de quatro tipos de fonte (descritores do CEFR, currículos de escolas, livros didáticos populares, pesquisa com professores). O consenso é maior no B1 e menor no C1, onde o conteúdo depende do contexto e do autor. Ou seja: do A1 ao B2 dá para seguir o "cânone"; no C1 o curso deve se moldar à necessidade do aluno (no caso, um dev brasileiro).
2. **O *English Grammar Profile* (EGP, Cambridge/English Profile) mostra o que os alunos de fato PRODUZEM corretamente em cada nível**, com base num corpus de 55 milhões de palavras escritas por alunos. Contei os **1.239 enunciados** por nível: **A1 109 · A2 297 · B1 342 · B2 248 · C1 130 · C2 113**. A maior parte da gramática nova surge no **A2 e no B1** (o B1 é o "pivô"). No C1 o crescimento é menos de estruturas novas e mais de **usos novos para estruturas velhas**, além de léxico, registro e discurso.
3. **A gramática cresce em espiral, não em fila.** A mesma estrutura reaparece com funções novas. *will*: planos (A1) → previsão (B1) → hábito típico (C1). *must*: obrigação (A2) → dedução, convite (B1) → *must have*, concessão "*I must admit*" (B2). Isso justifica reciclar as frases antigas com usos novos, em vez de "ensinar e passar adiante".
4. **Horas guiadas (Cambridge, cumulativas):** A1 ≈ 90–100 h · A2 ≈ 180–200 h · B1 ≈ 350–400 h · B2 ≈ 500–600 h · C1 ≈ 700–800 h. Pela minha estimativa (seção 3), um curso só de digitação cobre algo como 25–30% disso. Ele serve de motor de memorização e produção escrita, mas não substitui escuta e fala.
5. **Tamanho de frase cresce de forma mensurável.** Nos exemplos reais do EGP, a mediana de palavras por exemplo é: A1 9 · A2 9 · B1 13 · B2 16 · C1 18 · C2 19. Em caracteres: 41 · 45 · 66 · 81 · 98 · 99. O salto grande é A2→B1. Para digitação e memorização, recomendo começar menor ainda (2–5 palavras) no A1.
6. **i+1 operacional:** cada frase nova traz **no máximo um elemento novo** (uma estrutura OU 1–2 palavras novas no A1/A2, 2–3 do B1 em diante), com o resto já visto. Porém, como alerta o próprio Krashen, não convém "afinar demais": blocos de **fórmulas prontas (chunks)** podem antecipar estruturas que só serão analisadas depois (ex.: *I'd like…* no A1, *Have you ever been…?* no A2).
7. **Entrego (seção 7) uma lista ordenada de ~80 blocos**, de P0 (pré-A1) a C1.09, com revisões e situações. Para cada bloco vão: dependências explícitas, o que recicla, frase-modelo EN/PT-BR e comprimento-alvo. A seção 6 traz as **regras "não usar X antes de Y"**. Exemplo: nada de *present perfect* antes de *past simple* + particípios irregulares mais comuns; nada de 3ª condicional antes de *past perfect*; nada de *reported speech* com mudança de tempo verbal antes de *past perfect* e *would*.
8. **Específico de PT-BR → EN:** como a tradução fica EM CIMA, as estruturas sem equivalente 1:1 ficam ambíguas a partir do português. Exemplos: *present perfect* × *past simple*, *for/since*, *going to* × *will* × *present continuous*, "deve" (obrigação × dedução). **A tradução precisa de "dicas de contexto"** (ex.: "Moro aqui há 5 anos *(e ainda moro)*"), senão a resposta certa vira loteria. A lista de armadilhas está na seção 8.

---

## 1. Fontes e método

### 1.1 O que foi lido de verdade nesta sessão (fontes primárias)

| # | Fonte | O que extraí | Como acessei |
|---|---|---|---|
| F1 | **British Council / EAQUALS — *A Core Inventory for General English*** (North, Ortega & Sheehan, 2010/2011, 37 p.) | Tabela-resumo por nível (funções, gramática, conectores, vocabulário, tópicos), metodologia (consenso ≥80%), Apêndices A (características salientes dos níveis), C (tipos de texto), D (mapeamento de conteúdo) e E (exemplos) | PDF baixado e extraído com `pdftotext` |
| F2 | **Core Inventory Posters — 2018 update** (A1–C1) | Can-dos por habilidade, gramática, vocabulário e frases-exemplo ("Language Work") por nível | PDF baixado e extraído |
| F3 | **English Grammar Profile (EGP)**, cópia da planilha oficial com **1.239 itens** (SuperCategory, SubCategory, Level, guideword, can-do, exemplos reais do Cambridge Learner Corpus) | Contagem nível × categoria, primeiro nível de cada estrutura, enunciados de condicionais, *present perfect*, passiva, relativas, *reported speech*, modais etc., e tamanho médio das frases-exemplo | `.xlsx` baixado e analisado com Python (openpyxl) |
| F4 | **Geraldine Mark (co-autora do EGP), "Building on the insights from the EGP"**, workshop L2P, Gotemburgo, abr/2023 | Metodologia (frequência, distribuição, dispersão por L1 etc.), *"same structures = new uses"*, B1 como ponto pivô, "fórmula → slot-and-frame → produtivo", descompasso entre programas de ELT e competência real | PDF extraído |
| F5 | **CEFR-J Grammar Profile (20180315) e CEFR-J Wordlist 1.5 + Octanove C1/C2** (Tono Lab, TUFS) | Subníveis A1.1…B2.2 e cruzamento com Core Inventory, EGP e GSE; contagem de vocabulário por nível | CSVs do GitHub, analisados com Python |
| F6 | **English File 4th ed. — Beginner Teacher's Guide** (Oxford, 2019): *Syllabus checklist* | Sequência gramatical do A1 (12 Files) | PDF extraído |
| F7 | **English File 4th ed. — Elementary, Pre-Intermediate e Intermediate**, conforme o programa da Niğde Ömer Halisdemir University (2023-24) | Sequência gramatical A1–A2, A2+–B1 e B1+ | PDF extraído |
| F8 | **Interchange Intro, 5th ed. — Teacher's Edition, "Plan of Intro Book"** (Cambridge) | Sequência de 16 unidades (tópicos, funções, gramática) | PDF extraído |
| F9 | **Krashen (1982), *Principles and Practice in Second Language Acquisition*** | Enunciado original do i+1, input "roughly-tuned", ordem natural dos morfemas, estágios de negação e de perguntas | PDF extraído (sdkrashen.com) |
| F10 | **Descritores do CEFR "General Linguistic Range" e "Grammatical Accuracy"** (reproduzidos no projeto CEFTrain, Univ. Helsinki) | Texto dos descritores A1–C2 | WebFetch |
| F11 | **Cambridge English — *Guided learning hours*** | Horas cumulativas por nível | Busca (página oficial bloqueada com 403); números confirmados na reprodução da EC English |
| F12 | Wikipedia: *Spiral approach* (Bruner, 1960), *Processability theory* (Pienemann), *English Profile* | Princípios de espiral, teoria da processabilidade | WebFetch |

### 1.2 O que NÃO consegui verificar nesta sessão (e como tratei)

- **Headway 5th ed., Cambridge Empower 2nd ed. e Evolve:** não obtive o sumário. Houve 404 em PDFs e o orçamento de busca web da sessão acabou. Quando cito esses livros, é **conhecimento prévio, não verificado aqui**. Até onde sei, eles seguem a mesma espinha dorsal do English File e do Interchange (be → presente simples → presente contínuo → passado → futuro → comparativos → *present perfect* → modais → condicionais → passiva → *reported speech*).
- **CEFR Companion Volume 2020 (PDF oficial do Conselho da Europa):** o site rm.coe.int bloqueou o acesso (Cloudflare). Os descritores que cito vêm da reprodução do CEFTrain (F10) e do Apêndice A do Core Inventory (F1), que resume a seção 3.6 do CEFR. Do CV 2020, uso só fatos amplamente conhecidos: o nível **Pré-A1**, os descritores de mediação e a interação online.
- **Referências clássicas citadas de memória** (sem acesso nesta sessão; marcadas com †): Lightbown & Spada, *How Languages are Learned* (estágios das perguntas); Pienemann (1998); Hu & Nation (2000), sobre os 98% de cobertura lexical; Nation, *Learning Vocabulary in Another Language*; Lewis (1993), *The Lexical Approach*; van Ek & Trim, *Waystage/Threshold/Vantage* (estas citadas dentro do próprio Core Inventory).

### 1.3 Método de síntese

Para cada estrutura, cruzei: (a) o nível em que o **Core Inventory** a coloca para ENSINO; (b) o nível em que o **EGP** registra a primeira PRODUÇÃO correta; (c) a posição nos **livros** (English File, Interchange); (d) o subnível do **CEFR-J**. Quando divergem, aplico uma regra: **ensina-se de meio nível a um nível antes de o aluno produzir com autonomia** (o próprio Core Inventory diz que "learners are not expected to have mastery of the language points at that stage"). Além disso, digitar com o modelo à vista é uma produção *apoiada*, de carga cognitiva menor. Por isso pode vir um pouco antes do nível de produção livre do EGP, desde que a frase apareça primeiro em modo cópia.

---

## 2. O que cada fonte diz (resumo crítico)

### 2.1 CEFR (2001) e Companion Volume (2020)

- **Seis níveis** (A1, A2, B1, B2, C1, C2) e faixas "plus" (A2+, B1+, B2+). O CV 2020 acrescentou o **Pré-A1**. Para o curso, o Pré-A1 é o "dia zero": saudações, polidez, números, soletrar e pedir repetição.
- **Características salientes** (Core Inventory, Apêndice A, resumindo o CEFR 3.6):
  - **A1** — "o nível mais baixo de uso *gerativo* da língua": interagir de forma simples, perguntar e responder sobre si, onde mora, pessoas que conhece e coisas que tem. A frase deixa de ser só "um repertório finito, ensaiado, de frases por situação".
  - **A2** — o *Waystage*: concentra os descritores de **funções sociais** (cumprimentar, perguntar como a pessoa está, convidar, aceitar e recusar, fazer ofertas, combinar encontro) e de **"sair e se virar"** (lojas, correio, banco, transporte, pedir informação, direções, comprar passagem).
  - **B1** — o *Threshold*: (1) **manter a interação** e se fazer entender numa variedade de contextos, com pausas para planejar e reparar a frase; (2) **lidar com problemas do dia a dia**: imprevistos em viagem, conversa não preparada sobre temas familiares.
  - **B1+** — troca de **quantidade de informação**: descrever sintomas ao médico, explicar por que algo é um problema, resumir e opinar sobre um texto ou filme.
  - **B2** — "uma ruptura": **argumentação eficaz** (sustentar opinião com explicações, prós e contras), **desenvoltura no discurso social** (interagir com nativos sem esforço para nenhum dos lados) e **consciência linguística** (corrigir os próprios "erros favoritos").
  - **B2+** — habilidades de discurso: gerenciar a conversa, relacionar a própria fala com a dos outros, conectores variados, **negociação**.
  - **C1** — **acesso a um repertório amplo**, que permite comunicação fluente e espontânea; preencher lacunas com circunlocução; estrutura clara, conectores e coesão.
- **Descritores de gramática e repertório** (F10):

| Nível | General Linguistic Range | Grammatical Accuracy |
|---|---|---|
| A1 | "a very basic range of simple expressions about personal details and needs of a concrete type" | "limited control of a few simple grammatical structures and sentence patterns in a learnt repertoire" |
| A2 | "basic language… to deal with everyday situations with predictable content, though… will generally have to compromise the message" | "uses some simple structures correctly, but still systematically makes basic mistakes – for example tends to mix up tenses and forget to mark agreement" |
| B1 | "sufficient range… to describe unpredictable situations, explain the main points in an idea or problem… express thoughts on abstract or cultural topics such as music and films" | "reasonable accuracy in familiar contexts; generally good control though with noticeable mother tongue influence" |
| B2 | "express him/herself clearly and without much sign of having to restrict what he/she wants to say" | "good grammatical control; occasional 'slips'… rare" |
| C1 | "select an appropriate formulation from a broad range of language… without having to restrict what he/she wants to say" | "consistently maintains a high degree of grammatical accuracy; errors are rare and difficult to spot" |

**Leitura para o curso:** o A1 é "repertório decorado" por definição. Isso casa perfeitamente com "digitar várias vezes para decorar". O A2 ainda erra sistematicamente o tempo verbal e a concordância (o -s da 3ª pessoa!), então a reciclagem desses pontos tem que ser **permanente**, não só no bloco em que aparecem.

### 2.2 Core Inventory for General English (British Council/EAQUALS)

- **O que é:** inventário do "núcleo" do inglês geral para adultos (16+), níveis A1–C1. Foi feito com **consenso de ≥80%** entre descritores do CEFR, currículos de escolas EAQUALS, séries de livros populares e pesquisa com professores. Itens com consenso menor aparecem em itálico como "less core". Bancas como Cambridge ESOL, City & Guilds e Trinity revisaram, sobretudo o C1.
- **Achados metodológicos importantes:**
  - "Elementary" nos livros corresponde a **A1+A2**; "pre-intermediate" corresponde ao **A2 mais exigente (A2+)**. Isso explica por que o *present perfect* aparece no fim do Elementary e é retomado no Pre-int.
  - Consenso **maior de A1 a B2 do que no C1**. No C1, "o conteúdo era ditado em muito maior grau pelo contexto, propósito de aprendizagem e preferências do autor". O B1 tem o maior consenso, por herança do *Threshold Level* (1976).
  - Faça: derive o conteúdo de contextos reais; adapte os exemplos (nomes, lugares) ao seu contexto; **dê os expoentes dentro de um contexto**. Não faça: ensinar "cantos obscuros" da língua só porque existem; mandar decorar listas soltas de expoentes. *(Isso apoia frases contextualizadas, com personagens e situações recorrentes, em vez de frases soltas.)*
  - "Decisões sobre **reciclagem** foram deixadas para professores e autores de programa" — cabe a nós desenhá-la (seção 5).
- **Tabela-resumo por nível (extraída de F1 e F2):**

| | **A1** | **A2** | **B1** | **B2** | **C1** |
|---|---|---|---|---|---|
| **Funções** | direções; hábitos e rotinas; informação pessoal; cumprimentos; dizer as horas; números; preços | hábitos e rotinas; experiências passadas; descrever pessoas, lugares e coisas; obrigação e necessidade; pedidos; sugestões (+ conselhos, convites, ofertas, combinar encontros no Apêndice D) | checar compreensão; descrever experiências, eventos, sentimentos e lugares; opinar, concordar e discordar; iniciar e encerrar conversa; gerenciar a interação (interromper, mudar de assunto, retomar) | criticar e resenhar; descrever esperanças e planos; desenvolver argumento; encorajar o outro a falar; ideias abstratas; reagir (indiferença); interagir informalmente (interesse, simpatia, surpresa); especular; tomar a iniciativa; sintetizar | conceder um ponto; criticar construtivamente; defender um ponto de vista persuasivamente; argumentar sistematicamente; enfatizar; atitudes com precisão; certeza, probabilidade e dúvida; opinar com cautela (*hedging*); nuances de opinião; responder a contra-argumentos; especular sobre causas e consequências; sintetizar |
| **Gramática** | *be* (com perguntas e negativas); pronomes; possessivos; 's; *there is/are*; presente simples; presente contínuo; imperativo; *can/can't/could/couldn't*; *I'd like*; *like/love/hate + -ing*; advérbios de frequência; preposições (lugar; tempo *in/on/at*); *how much/how many* + incontáveis comuns; *going to*; passado de *be*; passado simples; comparativos e superlativos; intensificadores básicos | comparativo com *than*; superlativo com *the*; locuções adverbiais (ordem); artigos com contáveis e incontáveis; *much/many*; futuro (*will* e *going to*); gerúndio; *can/could*; *have to*; *should*; passado contínuo; passado simples; phrasal verbs comuns; 's e s'; preposições de tempo; presente contínuo com valor de futuro; ***present perfect***; verbo + *-ing*/infinitivo; perguntas *Wh-* no passado; **condicional zero e 1ª** | advérbios; *too/enough*; *question tags* complexas; **2ª e 3ª condicional**; conectores de causa, efeito e contraste; *future continuous*; *must/can't* (dedução); *might/may/will/probably*; *should have/might have*; *must/have to*; passado contínuo; ***past perfect***; phrasal verbs ampliados; ***present perfect continuous***; *present perfect* × *past simple*; ***reported speech***; **passiva simples**; *will* × *going to* (previsão) | *future perfect* (+ contínuo); *future continuous*; **condicionais mistas**; *can't have/needn't have*; modais de dedução e especulação; tempos narrativos; **passivas** (todas); *past perfect continuous*; **orações relativas**; *reported speech*; ***wish***; *would* para hábito passado | futuros (revisão); **inversão com advérbios negativos**; condicionais mistas (passado, presente, futuro); modais no passado; tempos narrativos (incl. passiva); todas as formas de passiva; phrasal verbs separáveis; *wish/if only* (arrependimento) |
| **Conectores** | *and, but, because* | sequenciais no passado (*first, then, finally*) | causa, efeito e contraste; sequenciais | causa e efeito; marcadores de fala formal; *although, in spite of, despite*; *subsequently* | conectores lógicos; marcadores para estruturar fala e escrita formal e informal |
| **Vocabulário** | comida e bebida; nacionalidades e países; informação pessoal; cidade, lojas e compras; verbos básicos | adjetivos de personalidade, descrição e sentimentos; comida; cidade e compras; viagens e serviços | colocação; linguagem coloquial; cidade e compras; viagens e serviços | colocação; linguagem coloquial | linguagem vaga (*approximating*); colocação; coloquial; uso diferenciado; **eliminar falsos cognatos**; registros formal e informal; expressões idiomáticas |
| **Tópicos** | vida familiar; hobbies; férias; lazer; compras; trabalho | educação; hobbies; férias; lazer; compras; trabalho | livros e literatura; educação; cinema; lazer; mídia; notícias e estilo de vida | artes; livros; educação; cinema; mídia; atualidades | artes; livros; cinema; mídia; atualidades; **avanços científicos**; **linguagem técnica e jurídica** |

- **Exemplos de frases do próprio Core Inventory** (pôsteres de 2018; servem de "calibração" do que é uma frase típica de cada nível):
  - A1: *My name is Carlos.* · *I am from the north of China.* · *We have three cats and one dog.* · *What's the time? A quarter to seven.* · *Where is the supermarket? It's straight ahead.* · *I'd like a cup of coffee.* · *She's taller than Michelle.* · *Are you going to study this weekend?* · *I moved to Madrid when I was 15.*
  - A2: *Could I use your computer? Yes. Of course you can.* · *I was living in Spain when I met her.* · *It was raining, so we decided to get a taxi.* · *Have you ever been to Greece?* · *If I stay in the sun I get a headache.* · *You should stay in and study tonight. You've got an exam on Friday.* · *A return ticket to Brighton, please.*
  - B1: *When I got home, Joan had already cooked supper.* · *How long have you been studying English?* · *If I won the lottery I'd buy a big house in the countryside.* · *I would have told Jim, if I had seen him.* · *She said she liked brown bread.* · *Mohamed can't be at home yet, I saw him leave just a few minutes ago.* · *I'm sorry but I think you're wrong.*
  - B2: *This time next year, I'll be working in Japan and earning good money.* · *If I had studied harder, I'd be at university now.* · *I wish today wasn't Monday.* · *What can he have done with the keys? He can't have lost them again.* · *Despite the rain we all had a great time.* · *As far as I am concerned this has nothing to do with the issue.*
  - C1: *There's bound to be trouble at the meeting.* · *Supposing he had missed his train?* · *If Lola had given me the information earlier, she'd be coming with us on holiday.* · *I should have warned him about the traffic, but I forgot.* · *I rather doubt that he'll come.* · *It's on the tip of my tongue.*

### 2.3 English Grammar Profile (EGP)

- **O que é:** um perfil empírico, baseado em corpus, do que os alunos **conseguem fazer** com a gramática em cada nível do CEFR. Fonte: o *Cambridge Learner Corpus*, com 55 milhões de palavras, mais de 200 mil provas, 215 países e 143 L1s (F4). Considera só provas aprovadas. Cada item é um enunciado "Can use…" com exemplos reais de alunos. Não é perfil de erros nem é prescritivo (F4). Autoras: Anne O'Keeffe e Geraldine Mark (O'Keeffe & Mark, 2017, *IJCL* 22(4): 457–489).
- **Minha contagem na planilha (1.239 itens):**

| Categoria | A1 | A2 | B1 | B2 | C1 | C2 | Total |
|---|---:|---:|---:|---:|---:|---:|---:|
| MODALITY | 12 | 49 | 71 | 60 | 34 | 30 | 256 |
| CLAUSES (inclui condicionais e relativas) | 8 | 33 | 43 | 20 | 14 | 17 | 135 |
| PRONOUNS | 9 | 29 | 29 | 30 | 11 | 11 | 119 |
| PAST (inclui present perfect) | 2 | 15 | 33 | 29 | 7 | 7 | 93 |
| ADJECTIVES | 5 | 28 | 22 | 12 | 5 | 7 | 79 |
| FUTURE | 2 | 19 | 18 | 18 | 8 | 7 | 72 |
| DETERMINERS | 12 | 24 | 17 | 6 | 4 | 7 | 70 |
| ADVERBS | 16 | 20 | 14 | 7 | 8 | 4 | 69 |
| VERBS | 11 | 17 | 16 | 13 | 3 | 2 | 62 |
| NOUNS | 13 | 15 | 16 | 6 | 5 | 1 | 56 |
| PASSIVES | 0 | 3 | 10 | 18 | 5 | 4 | 40 |
| PRESENT | 6 | 14 | 8 | 4 | 4 | 2 | 38 |
| QUESTIONS | 1 | 13 | 13 | 2 | 4 | 2 | 35 |
| NEGATION | 3 | 7 | 7 | 4 | 6 | 4 | 31 |
| CONJUNCTIONS | 7 | 1 | 6 | 4 | 5 | 3 | 26 |
| REPORTED SPEECH | 0 | 2 | 8 | 7 | 0 | 0 | 17 |
| FOCUS | 0 | 1 | 2 | 2 | 5 | 5 | 15 |
| PREPOSITIONS | 2 | 5 | 4 | 3 | 1 | 0 | 15 |
| DISCOURSE MARKERS | 0 | 2 | 5 | 3 | 1 | 0 | 11 |
| **Total** | **109** | **297** | **342** | **248** | **130** | **113** | **1.239** |

  **Leituras:** (1) **A2 + B1 concentram 52% de toda a gramática nova.** Os blocos de A2 e B1 devem ser os mais densos em gramática. (2) Passiva, *reported speech* e "foco" (clivadas, inversão) crescem do B1 ao C1. (3) No C1 e C2, o que mais aparece é **modalidade** (nuances), **foco/ênfase** e **orações complexas**: refinamento, não estruturas básicas novas. (4) O número baixo do A1 reflete em parte o pouco dado A1 no corpus. Para iniciante absoluto, o A1 precisa de **muitos passos pequenos** mesmo assim.

- **Primeiro nível de PRODUÇÃO de estruturas-chave no EGP** (extraído da planilha):

| Estrutura | 1º nível EGP | Observação |
|---|---|---|
| *be*, presente simples (+/−), presente contínuo, *can*, *will* (planos: "*I will see you soon*"), *would like*, passado simples (eventos do dia a dia), *there is/are*, *because* | **A1** | *will* e *would like* aparecem como fórmulas já no A1 |
| comparativos (-er, *more*, *than*), superlativos, *going to*, presente contínuo como futuro, passado contínuo, ***present perfect*** (afirmativa, perguntas, *ever/never*, *yet*, *for*), *should*, *must*, *have to*, *might*, *may*, *could*, *if* + presente (real), relativas definidoras (*who/which/that*), passiva presente e passado simples ("*It was built in 1880*"), *reported speech* com *say/tell* (só troca de pronome) | **A2** | o A2 é o nível do "kit básico completo" |
| *present perfect* com *since/already*, uso "recente" e "inacabado"; *present perfect continuous*; ***past perfect***; *used to*; *if* + *will*; **2ª condicional** (*if I were you*); **3ª condicional**; *unless*; *must* para dedução; *should have/might have*; passiva em outros tempos e com *by*; *reported speech* com mudança de tempo, perguntas e pedidos; *whose*, *where*; *it + be + adj + that* | **B1** | o B1 é o pivô |
| *future perfect* (+ contínuo); *must have + -ed*; passiva em todos os tempos e com modais; *wish/if only* + *past perfect*; inversão com *never*, *no sooner*; relativas com preposição; *the reason (that)…* | **B2** | |
| *if* + *past perfect* + modais; condicional invertida com *should* ("*Should you require…*"); *had I known…*; *what*-cleft ("*What we need is…*"); *not only… but also* com inversão; *might* para crítica polida | **C1** | |
| *were I to…*; *had it not been for…*; *hardly… when*; *it*-cleft; *if it were not for*; "*might as well*" | **C2** | fora do escopo, mas útil como teto |

- **Insights do EGP que mudam o desenho do curso** (F4):
  1. **"Desenvolvimento gramatical ≠ só estruturas novas; = mesmas estruturas, usos novos."** A trilha de *must* mostra isso. **A2:** obrigação ("*You must wear your sports shoes*"). **B1:** dedução ("*it must be boring for you*"), convite ("*You must come and stay*"), sugestão forte, elipse ("*Must go now*"). **B2:** *must have + -ed*, concessão ("*you must admit*"), ênfase ("*I must say*"), regras. **C2:** inversão ("*Not only must you study…*"). O *past simple* segue o mesmo padrão: eventos (A1) → estados habituais (B1) → polidez "*I wondered/I wanted…*" (B2) → *did* enfático para refutar (C1).
  2. **"B1 é o ponto pivô"** no uso de sequências de palavras: frases com verbos conjugados atingem o pico no B1, e há um **salto do B1 para o B2**, quando crescem os sintagmas nominais longos ("*a wide range of*").
  3. **Percurso baseado no uso: fórmula → "slot and frame" → sistema produtivo.** Os 4-gramas mais típicos do A2 são **fórmulas**: *How are you?*, *I would like to*, *I'm going to*, *Would you like to*, *Thank you for your*, *I think you should*, *See you soon*. **Implicação direta para o curso de frases: começar pelas fórmulas e depois abrir os "slots"** (*I'm going to + [verbo]*, *went to the + [lugar]*).
  4. **Aumento de erros no B1** ("trade-off" entre acurácia e complexidade): o aluno arrisca mais. Esperado. O sistema de correção não deve punir isso a ponto de desmotivar.
  5. **Descompasso entre programas de ELT e competência real:** os livros às vezes ensinam cedo coisas que o aluno só produz bem muito depois (ex.: *theirs* tem muitos erros ainda no B2). Em vez de "ensinar uma vez", reciclar.

### 2.4 Livros didáticos: a sequência na prática

**English File 4th ed. — Beginner (A1)** (F6). Files 1–12:
1A *be* (I/you) · 1B *be* (he/she/it) · 2A *be* plural · 2B perguntas *Wh-*/*How* com *be* · 3A plurais, *a/an* · 3B *this/that/these/those* · 4A possessivos, 's · 4B adjetivos · 5A presente simples +/− (I/you/we/they) · 5B presente simples ? · 6A presente simples he/she/it · 6B advérbios de frequência · 7A ordem das palavras em perguntas · 7B imperativo, pronomes objeto · 8A *can/can't* · 8B *like/love/hate + -ing* · 9A presente contínuo · 9B presente contínuo × simples · 10A *there's a… / there are some…* · 10B passado de *be* · 11A passado regular · 11B irregulares *get, go, have, do* · 12A regulares e irregulares · 12B revisão do passado.
*Practical English:* check-in em hotel, reservar mesa, preços, comprar almoço, dizer as horas, data, telefone, convidar e oferecer, pedir e dar direções.

**English File 4th ed. — Elementary (A1–A2)** (F7):
*be* +/− e ? · possessivos · plurais · adjetivos (*very/really/quite*) · imperativo, *let's* · presente simples +/− e ? · ordem das perguntas · 's · *at/in/on* · advérbios de frequência · *can/can't* · presente contínuo · simples × contínuo · pronomes objeto · *like + -ing* · *be* ou *do*? · *was/were* · passado regular · irregular · *there is/there was* · contáveis e incontáveis, *a/an/some/any* · quantificadores · comparativos · superlativos · *be going to* (planos) · *be going to* (previsões) · advérbios · verbo + *to* · artigo definido · ***present perfect*** (experiências) · *present perfect* × *past simple*.

**English File 4th ed. — Pre-Intermediate (A2+–B1)** (F7):
ordem das perguntas · presente simples × contínuo · passado simples · passado contínuo · sequenciadores e conectores · *going to* e presente contínuo (futuro) · **relativas definidoras** · *present perfect + yet/just/already* · *present perfect* × *past simple* (1) · *something/anything/nothing* · comparativos de adjetivos e advérbios, *as…as* · superlativos (+ *ever* + *present perfect*) · quantificadores, *too*, *(not) enough* · *will/won't* (previsão) · *will/won't/shall* (outros usos) · revisão de formas verbais · infinitivo com *to* · gerúndio · *have to*, *must* · *should* · **1ª condicional** · pronomes possessivos · **2ª condicional** · *present perfect + for/since* · *present perfect* × *past simple* (2) · movimento · phrasal verbs · **passiva** · ***used to*** · *might* · *so/neither* + auxiliar · ***past perfect*** · ***reported speech*** · perguntas sem auxiliar.

**English File 4th ed. — Intermediate (B1+)** (F7, parcial):
presente simples e contínuo, verbos estativos · formas de futuro · *present perfect* × *past simple* · *present perfect continuous* · comparativos e superlativos · artigos · proibição e permissão · *can/could/be able to* · tempos narrativos e *past perfect continuous* · *used to/usually* · passiva · modais de dedução · orações temporais (*when, until*) · condicionais · gerúndio e infinitivo · quantificadores · **relativas definidoras e não definidoras** · …

**Interchange Intro, 5th ed. (A1)** (F8):
U1 possessivos, *be* · U2 artigos, *this/these*, plurais, perguntas com *be*, preposições de lugar · U3 *be* completo, perguntas *Wh-* · U4 possessivos *our/their*, pronomes, *whose*, presente contínuo, *and/but/so*, adjetivos antes do substantivo · U5 horas, presente contínuo (*Wh-*) · U6 presente simples (+, ?, *Wh-*) · U7 *there is/are* · U8 *Wh-* com *do/does* · U9 contáveis e incontáveis, *some/any*, advérbios de frequência · U10 *can* (habilidade) · U11 ***be going to*** · U12 *have + substantivo*, *feel + adj*, imperativo (saúde) · U13 preposições, direções · U14 **passado simples** (regulares e irregulares) · U15 **passado de *be***, *Wh-* com *did/was/were* · U16 pronomes sujeito e objeto, convites com *Do you want to…? / Would you like to…?*, verbo + *to*.

**Comparação.** Os dois livros (um britânico, outro americano) **concordam na espinha dorsal**: *be* → possessivos → plurais e demonstrativos → presente simples → presente contínuo → *there is/are* → *can* → passado. Divergem em detalhes:
- o **Interchange põe o presente contínuo ANTES do presente simples** (U4–5 × U6);
- o **English File põe *was/were* ANTES do passado regular**, e o Interchange faz o contrário;
- o **Interchange põe *going to* antes do passado**, e o English File põe depois.

Para frases memorizadas por digitação, recomendo a ordem do English File: presente simples antes do contínuo e *was/were* antes do passado lexical. Motivos: (a) o presente simples é a forma de base do verbo e vem antes da perífrase *be + -ing*; (b) *was/were* reaproveita o *be* recém-aprendido.

### 2.5 CEFR-J: subníveis e vocabulário

- O **CEFR-J** (projeto japonês, Tono Lab/TUFS) divide A1→A1.1/A1.2/A1.3, A2→A2.1/A2.2, B1→B1.1/B1.2, B2→B2.1/B2.2. Seu *Grammar Profile* cruza cada item com Core Inventory, EGP e GSE (Pearson). Exemplos de subnível: **A1.1** *be*, possessivos, artigos, presente simples afirmativo; **A1.2** negativa e pergunta do presente simples, *can*, *there + be*, frequência; **A1.3** presente contínuo, passado de *be*, comparativo -er, *let's*; **A2.1** *present perfect*, passado contínuo, *will*, *should*, *if*, passiva no passado; **A2.2** *going to*, *have to*, *more + adj*, discurso indireto com *say*; **B1.1** *used to*, *could*, *may*, reflexivos, relativa não restritiva; **B1.2** *past perfect*, **2ª condicional**, *get + particípio*; **B2.1** *present perfect continuous*, passiva no *present perfect* e no futuro, *whether*, *so that*.
  ⚠ Os níveis do CEFR-J saem de frequência em livros japoneses e têm idiossincrasias (ex.: "*You are*" aparece em B1.1). Use como **apoio para granular**, não como verdade.
- **Vocabulário (contagem própria nos CSVs):** CEFR-J A1 **1.164** · A2 **1.411** · B1 **2.446** · B2 **2.778** (acumulado **7.799**) · Octanove C1 **1.111** · C2 **1.025**. Para comparação, o *English Vocabulary Profile* (Cambridge) tem "just under 7,000 headwords" A1–C2 (Text Inspector, via busca). **Ordem de grandeza útil:** ~1.100 palavras no A1, ~2.500 acumuladas no A2, ~5.000 no B1, ~7.800 no B2 e ~9.000 no C1.

### 2.6 Onde as fontes divergem (e a decisão para o curso)

| Estrutura | Core Inventory (ensino) | EGP (produção) | English File | Interchange | **Decisão para o curso** |
|---|---|---|---|---|---|
| *going to* | A1 | A2 | Elem. 10B (≈A2) | Intro U11 (A1) | **fim do A1** (planos); previsão com evidência no A2 |
| comparativos | A1 | A2 | Elem. 9C | — | **fim do A1** (-er/*than*); completo no A2 |
| *will* | A2 | A1 (fórmula de plano/promessa) | Pre-int 6 | — | **fórmula no A1** (*I'll call you*), sistema no A2 |
| *present perfect* (experiência) | A2 | A2 | fim do Elem. (12A) | — | **meio/fim do A2**, depois de passado + particípios |
| *present perfect* × *past simple*; *for/since* | B1 | A2–B1 | Pre-int 4 e 9; Int 2 | — | **B1.01–B1.02** (o contraste é a parte difícil) |
| relativas definidoras | B2 ("relative clauses") | A2 | Pre-int 3C | — | **fim do A2** (*who/which/that*); *whose*/não definidoras no B1; preposição + *which/whom* no B2 |
| passiva (presente/passado simples) | B1 | A2 | Pre-int 10C | — | **B1** (frase-fórmula "*It was built in…*" pode aparecer no A2) |
| *reported speech* | B1 | A2 (só pronome) / B1 (tempo) | Pre-int 12B | — | **B1**, depois do *past perfect* |
| *used to* | (narrativa B1–B2) | B1 | Pre-int 11A | — | **B1** |
| *past perfect* | B1/B2 | B1 | Pre-int 12A | — | **B1** |
| 2ª condicional | B1 | B1 | Pre-int 9A | — | **B1** |
| 3ª condicional | B1 | B1 | Int (≈B1+) | — | **fim do B1**, reciclada no B2 |
| inversão com advérbio negativo | C1 | B2 (*Never had I…*) / C1 (*Not only…*) | — | — | **B2** (fórmulas *Never have I…*), sistema no **C1** |
| *wish* | B2 (C1 com arrependimento) | B2 (*if only* + *past perfect*) | (Int/Upper) | — | **B2** |

---

## 3. Horas guiadas (Cambridge GLH) e o que isso significa para um curso de digitação

**Números da Cambridge** (cumulativos, desde o zero; "guided learning hours", ou seja, tempo de aula ou estudo supervisionado; valem só como orientação):

| Nível | Horas cumulativas | Horas a mais no nível | Livro típico |
|---|---|---|---|
| A1 | 90–100 | ~95 | Beginner / Starter |
| A2 | 180–200 | ~95 | Elementary (A1–A2) / Pre-int (A2+) |
| B1 | 350–400 | ~185 | Pre-int → Intermediate |
| B2 | 500–600 | ~175 | Upper-intermediate |
| C1 | 700–800 | ~200 | Advanced |
| C2 | 1.000–1.200 | ~350 | Proficiency |

Fontes: support.cambridgeenglish.org (artigo *Guided learning hours*) e reprodução da EC English, que reforça: "these are guided learning hours, not calendar time".

**Leitura:** o B1 custa o mesmo que A1 e A2 juntos. É coerente com o EGP, que concentra a gramática nova em A2 e B1. Do B1 ao C1 são mais ~400 horas, em grande parte de vocabulário, discurso e fluência.

**Estimativa para o app (cálculo meu, para dimensionar o currículo):**

| Nível | Frases sugeridas | Tamanho típico | Tempo por frase (5 repetições + leitura) | Horas de digitação | % das horas guiadas do nível |
|---|---|---|---|---|---|
| A1 | 500–700 | 15–40 caracteres | ~1 min | ~10–12 h | ~11% |
| A2 | 700–900 | 25–65 | ~1,5 min | ~18–22 h | ~20% |
| B1 | 900–1.200 | 45–90 | ~2 min | ~30–40 h | ~19% |
| B2 | 900–1.200 | 60–110 | ~2,5 min | ~38–50 h | ~25% |
| C1 | 700–1.000 | 80–140 | ~3,5 min | ~40–58 h | ~25% |
| **Total** | **~3.700–5.000** | | | **~140–180 h**; com revisões espaçadas (~+50%), **~210–270 h** | **~20–35%** das ~750 h (ponto médio ≈ 25–30%) |

- **Conclusão honesta:** a digitação de frases é um ótimo **motor de memorização de padrões e de escrita**, mas sozinha não leva ao C1. As outras ~65–80% das horas são escuta, fala e leitura extensiva. **Recomendação:** cada frase com áudio (TTS) e um modo de ditado opcional (a frente de memorização ou de áudio decide).
- Para referência no próprio app: o curso de Dart tem 2.354 exercícios, e a meta do C# é ≥4.708. **~4.000–4.500 frases** dá um curso de inglês do mesmo porte.

---

## 4. Nível a nível (perfil para quem escreve as frases)

> Convenções: **[CI]** = Core Inventory; **[EGP]** = English Grammar Profile; **[EF]** = English File; **[IC]** = Interchange. Os tamanhos de frase vêm dos exemplos reais do EGP (mediana e intervalo interquartil, p25–p75), seguidos da minha recomendação para digitação.

### 4.0 Pré-A1 (dia zero)
- **Meta:** sobreviver ao primeiro contato. Fórmulas não analisadas: cumprimentar, agradecer, pedir desculpas, dizer que não entendeu, pedir repetição, soletrar o nome, números 0–20.
- **Estratégias [CI A1]:** "establish contact… using simple words and phrases", "say when I do not understand", "ask somebody to repeat".
- **Frase:** 1–5 palavras (5–30 caracteres). Ex.: *Thank you.* · *Excuse me.* · *I don't understand.* · *Can you repeat that, please?*

### 4.1 A1 (Breakthrough) — "repertório decorado sobre mim e o meu mundo imediato"
- **Gramática, em ordem de ensino:** *be* (I/you → he/she/it → plural; +/−/?; respostas curtas) → perguntas *Wh-* com *be* → possessivos + 's → *a/an*, plurais, *this/that/these/those* → adjetivos (antes do substantivo, depois de *be*, invariáveis, *very*) → imperativo e *let's* → presente simples (I/you/we/they: +/−) → perguntas com *do* e ordem das palavras → 3ª pessoa (-s/-es, *does/doesn't*) → advérbios de frequência + horas + *in/on/at* → *can/can't* → *like/love/hate + -ing* → presente contínuo (agora) e contraste com o simples → pronomes objeto → *there is/are* + *some/any* + preposições de lugar → contáveis e incontáveis, *how much/many*, *I'd like* → *was/were* → passado simples (afirmativo; regulares + *went/had/got/did/saw…*) → passado com *did/didn't* → *going to* (planos) → comparativos (-er, *more*, *than*).
- **Funções [CI]:** cumprimentar e se despedir; apresentar-se e apresentar alguém; dar informação pessoal (nome, nacionalidade, idade, telefone, endereço, família, hobbies); números, preços, horas e datas; direções simples; pedir comida; gostos; rotina; habilidades; descrever casa e cidade.
- **Situações [CI, cenário "On holiday"]:** hotel, restaurante e café, compras, transporte, perguntar o caminho, preencher ficha.
- **Conectores:** *and, but, or, because* [CI; EGP A1: "because" para razões].
- **Vocabulário:** ~1.100 palavras (CEFR-J); comida, países e nacionalidades, família, casa, cidade, profissões, dias e meses, cores, roupas, verbos básicos.
- **Tamanho de frase:** EGP A1 com mediana de **9 palavras / 41 caracteres** (p25–p75: 6–11 palavras / 26–57 caracteres), mas isso é escrita de prova de quem foi aprovado. **Para memorizar digitando: começar com 2–5 palavras e subir até 6–9 no fim do nível.**

### 4.2 A2 (Waystage) — "me viro no dia a dia e conto o que aconteceu"
- **Gramática, em ordem:** revisão das perguntas (todos os auxiliares) + perguntas de sujeito (*Who called?*) → narrar o passado (irregulares ampliados, *ago*, *when*, sequenciadores) → passado contínuo (pano de fundo, *when/while*) → futuro: *going to* (previsão com evidência) + presente contínuo (combinados) + *will* (decisão na hora, oferta, promessa) → comparativos e superlativos completos, *as…as* → quantificadores (*much/many/a lot of/a few/a little*, *something/anything/nothing*) → ***present perfect*** I (experiência: *ever/never*) → *present perfect* II (*just/already/yet*, resultado no presente) → *have to/don't have to*, *must/mustn't*, *should* → verbo + *to* / verbo + *-ing*, *to* de finalidade → convites, sugestões, pedidos e ofertas (*Would you like to…? Why don't we…? Could you…?*) → condicional zero e 1ª, *when/as soon as* + presente → *might/may*, *could* (passado e possibilidade) → relativas definidoras (*who/which/that/where*) → advérbios de modo, phrasal verbs comuns, pronomes possessivos.
- **Funções [CI]:** hábitos e rotinas; experiências passadas e histórias; descrever pessoas, lugares e coisas; obrigação e necessidade; pedidos; sugestões, conselhos, convites, ofertas, combinar encontros; pedir e aceitar desculpas; como a pessoa se sente.
- **Situações:** viagem (aeroporto, estação, hotel), serviços (banco, correio, farmácia, médico), telefone e mensagens, convites, compras com troca e devolução, falar do trabalho e da formação.
- **Conectores:** *so, then, first, after that, finally, when* [CI: "linkers sequential past time"].
- **Vocabulário:** +~1.400 (≈2.500 no acumulado); sentimentos, personalidade, aparência, viagem, serviços, saúde, clima.
- **Tamanho:** EGP A2 com mediana de **9 palavras / 45 caracteres** (p75: 13 / 64). **Recomendado: 5–12 palavras (25–65 caracteres).** Começam a aparecer **duas orações** (*I was having lunch when you called.*).

### 4.3 B1 (Threshold) — "mantenho a conversa, explico, opino e conto histórias"
- **Gramática, em ordem:** *present perfect* × *past simple* → *for/since*, *How long…?*, *present perfect continuous* → *used to* → ***past perfect*** e tempos narrativos → futuro: *will* × *going to* (previsão), *probably/definitely*, *future continuous* → **2ª condicional** (*If I were you…*) → **passiva** (presente e passado simples, *by*) → ***reported speech*** (afirmações, perguntas, pedidos: *ask/tell sb to*) → modais de dedução no presente (*must/might/can't be*) + perguntas indiretas polidas → modais no passado (*should have/could have/might have*) → **3ª condicional** → relativas II (*whose*, não definidoras, *where/when*) + gerúndio como sujeito e depois de preposição → conectores de causa, contraste e finalidade (*although, however, even though, unless, so that, in order to*), *so/such*, *too/enough*, *question tags*, *so/neither do I* → funções de conversa.
- **Funções [CI]:** checar compreensão; descrever experiências, eventos, sentimentos e emoções; opinar, concordar e discordar com educação; iniciar e encerrar conversa; gerenciar a interação (interromper, mudar de assunto, retomar: *By the way…*, *What were we talking about?*, *Sorry to interrupt, but…*); reclamar; telefonar; dar instruções detalhadas.
- **Situações:** entrevista de emprego, reclamação, viagem com imprevistos, conversa com colegas, consulta médica com sintomas, resumir um filme ou livro, e-mail informal e formal simples.
- **Tópicos [CI]:** educação, cinema, livros, mídia, notícias, estilo de vida.
- **Tamanho:** EGP B1 com mediana de **13 palavras / 66 caracteres** (p25–p75: 9–18 / 46–89). **Recomendado: 8–16 palavras (45–90 caracteres).** É o maior salto de tamanho; vale a pena **quebrar frases longas em partes** antes da frase inteira.

### 4.4 B2 (Vantage) — "argumento, especulo, avalio e falo com naturalidade"
- **Gramática, em ordem:** tempos narrativos completos + *past perfect continuous* → futuro avançado (*future perfect* e *future perfect continuous*, *be about to*, *be likely to*) → passiva II (todos os tempos, com modais, *have/get sth done*, *it is said that / he is believed to*) → dedução no passado (*must have/can't have/might have*), *needn't have* → *wish/if only/I'd rather/it's time* + condicionais mistas → verbos de relato com padrões (*suggest -ing*, *deny -ing*, *warn sb not to*) → hábitos (*would/used to/be used to/get used to*) → relativas III (preposição + *which/whom*, *which* comentando a oração inteira, reduzidas com particípio) → conectores formais (*despite, whereas, nevertheless, consequently*) → ênfase I (inversão-fórmula *Never have I…*; clivadas *What I need is…*, *The reason I'm writing is…*).
- **Funções [CI]:** desenvolver argumento; avaliar vantagens e desvantagens; especular; criticar e resenhar; sintetizar várias fontes; encorajar o outro a falar (*Let's hear what X has to say*, *What makes you say that?*); ganhar tempo (*That's a difficult question to answer*); reagir com interesse, simpatia e surpresa (*No way! I don't believe it.*).
- **Situações:** reunião de trabalho, debate, negociação, carta formal de reclamação, resenha, apresentação curta, entrevista.
- **Vocabulário:** colocações, phrasal verbs ampliados, coloquialismos, expressões idiomáticas frequentes; +~2.800 palavras (≈7.800 no acumulado).
- **Tamanho:** EGP B2 com mediana de **16 palavras / 81 caracteres** (p25–p75: 11–21 / 60–110). **Recomendado: 10–20 palavras (60–110 caracteres).**

### 4.5 C1 (Effective Operational Proficiency) — "escolho a formulação certa para cada registro"
- **Gramática, em ordem:** inversão com advérbios negativos (*Not only… / Hardly… when / Under no circumstances / Little did I know*) → condicionais invertidas e alternativas (*Had I known… / Should you need… / Were I to… / provided that / supposing / but for*) → clivadas e *fronting* (*It was X who… / All I want is…*), *do* enfático → modalidade avançada (*bound to, supposed to, may well, could well*) → passivas avançadas e impessoais (*It is widely believed that… / He is thought to have… / Having been warned…*) → *hedging*, linguagem vaga e registro → argumentação sofisticada (conceder, rebater) → nominalização, orações participiais, elipse e substituição → idiomas, colocações, phrasal verbs separáveis, **falsos cognatos** [CI C1].
- **Funções [CI]:** conceder; defender um ponto de vista persuasivamente; responder a contra-argumentos; opinar com cautela; expressar nuances de certeza; enfatizar; sintetizar e avaliar.
- **Situações (o C1 depende do contexto [CI]):** para um dev, **apresentação técnica, *code review*, *post-mortem* de incidente, negociação de prazo e escopo, e-mail formal a cliente, entrevista sênior, debate sobre tecnologia**; mais os tópicos do CI: avanços científicos, linguagem técnica e jurídica, mídia, artes.
- **Tamanho:** EGP C1 com mediana de **18 palavras / 98 caracteres** (p25–p75: 13–23 / 70–126). **Recomendado: 12–25 palavras (80–140 caracteres)**, digitando em partes (oração por oração) antes da frase completa.

---

## 5. Espiral e i+1 aplicados a um curso de FRASES

### 5.1 O que dizem as fontes

- **Krashen (1982), i+1** (F9): "a necessary (but not sufficient) condition to move from stage *i* to stage *i + 1* is that the acquirer understand input that contains *i + 1*… focussed on the meaning". Detalhe que costuma ser esquecido: o input deve **conter** *i+1*, mas **não só** *i+1*. Krashen critica a "structure of the day" e defende o input **"roughly-tuned"**, que "provides built-in review… *i + 1* will occur and reoccur". Ele também nota que a **ordem natural** dos morfemas (ex.: *-ing* e plural cedo; **-s da 3ª pessoa e 's possessivo tarde**) **não deve virar programa**. Ainda assim, ela avisa **o que vai precisar de reciclagem eterna**.
- **Estágios de desenvolvimento** (Krashen, F9; Pienemann, F12/†; Lightbown & Spada †). Negação: "*No like*" → "*I no like*" → "*I don't like*". Perguntas: fórmula (*What's your name?*) → entonação (*You like pizza?*) → *fronting* (*Where you go?*) → inversão com *be*/modal (*Can you…? Where is…?*) → *do*/auxiliar na 2ª posição (*Where did you go?*) → perguntas indiretas **sem** inversão (*Can you tell me where you live?*). **Implicação:** a pergunta indireta (*Could you tell me where the station is?*) só depois de a pergunta direta com *do* estar sólida, porque ela exige "desligar" a inversão.
- **Espiral (Bruner, 1960)** (F12): "each subject or skill area is revisited at intervals, at a more sophisticated level each time… later encounters linked to earlier learning".
- **EGP** (F4): "mesmas estruturas, usos novos" e "fórmula → slot e frame → produtivo".
- **Core Inventory** (F1): dê os expoentes dentro de um contexto; adapte ao aluno; reciclagem fica a cargo do autor.
- **Cobertura lexical †** (Hu & Nation, 2000; Nation): compreensão confortável sem ajuda pede ~98% de palavras conhecidas no texto. Uma frase isolada tem pouco contexto, mas a tradução EM CIMA compensa. Ainda assim, convém frases com **≤1–2 palavras desconhecidas**.

### 5.2 Regras operacionais (proposta)

1. **Uma novidade por frase.** A frase introduz **ou** uma estrutura nova **ou** palavras novas (no máximo 1–2 no A1/A2, até 3 do B1 em diante), nunca as duas coisas juntas. Estrutura nova entra com vocabulário velho; palavra nova entra em estrutura velha.
2. **Fórmula antes de regra (chunk-first).** Expressões de alta frequência entram cedo como bloco fechado e são "abertas" depois. Exemplos: *I'd like…* (A1) antes de *would* condicional (B1); *Can I…? / Could you…?* (A1/A2) antes de *could* para possibilidade e no passado; *Have you ever been to…?* (A2, fórmula) antes do contraste *present perfect* × *past* (B1); *I'm going to…* (A1) antes da previsão com evidência (A2); *If I were you, I'd…* (B1, fórmula de conselho) dentro da 2ª condicional; *Never have I…* (B2) antes da inversão sistemática (C1).
3. **Pares mínimos dentro do bloco.** Frases vizinhas que diferem só no ponto-alvo, para o contraste aparecer: *I work from home. / I'm working from home today.* · *I went to London in 2019. / I've been to London.* · *If it rains, we'll stay. / If it rained, we'd stay.*
4. **≥70% de material reciclado por bloco.** Cada bloco reaproveita vocabulário, personagens e situações dos anteriores. **Revisões a cada 4–6 blocos** misturam tudo (bloco "R" na lista).
5. **Espiral funcional.** A mesma função volta a cada nível com expoentes mais sofisticados (tabela 5.3).
6. **Espiral de usos (EGP).** Estruturas antigas voltam com usos novos (tabela 5.4).
7. **Reciclagem eterna** para os pontos de aquisição tardia ou de interferência do português: **-s da 3ª pessoa**, artigos, *do-support*, *present perfect* × *past*, preposições, sujeito obrigatório (*It's raining*). Pelo menos algumas frases por bloco, em qualquer nível, devem exercitá-los.
8. **Não exagerar no ajuste fino (Krashen).** De vez em quando, uma fórmula "acima do nível" é bem-vinda se a tradução deixar o sentido claro: *Long time no see!* no A1, *Could you do me a favor?* no A2.

### 5.3 Espiral funcional: a mesma intenção, níveis diferentes

| Função | A1 | A2 | B1 | B2 | C1 |
|---|---|---|---|---|---|
| **Pedir algo** | *A coffee, please.* / *I'd like a coffee.* | *Could I have the bill, please?* | *Would you mind closing the door?* / *Do you mind if I sit here?* | *I was wondering if you could help me with this.* | *I'd be grateful if you could send me the report by Friday.* |
| **Opinar** | *I like it.* / *It's very good.* | *I think it's a good idea.* | *In my opinion, it's too expensive.* / *I see what you mean, but…* | *As far as I'm concerned, this has nothing to do with the issue.* [CI] | *I know this may not be a popular conclusion, but it seems to me we have to face the facts.* [CI] |
| **Falar do passado** | *I was at home yesterday.* / *I went to the beach.* | *I was watching TV when you called.* | *When I got home, Joan had already cooked supper.* [CI] | *I was tired. I'd been working for sixteen hours.* [CI] | *Had I known the tour would be so bad, I wouldn't have booked it.* [EGP] |
| **Futuro/planos** | *I'm going to study this weekend.* | *I'm meeting Ana on Friday.* / *I'll call you later.* | *This time tomorrow, I'll be flying to Lisbon.* | *This time next year, I'll be working in Japan.* [CI] / *She won't have left by then.* [CI] | *There's bound to be trouble at the meeting.* [CI] |
| **Hipótese** | — | *If it rains, we'll stay home.* | *If I won the lottery, I'd buy a big house.* [CI] / *I would have told Jim if I had seen him.* [CI] | *If I had studied harder, I'd be at university now.* [CI] | *Supposing he had missed his train?* [CI] / *Should you need any help, let me know.* |
| **Obrigação/conselho** | *Don't worry.* / *Turn left.* | *You should stay in and study tonight.* [CI] / *I have to go.* | *You should have come with us.* [CI] | *You needn't have bought it.* | *He ought to be sacked for behaviour like that.* [CI] |
| **Certeza/dedução** | — | *It might rain.* | *He must be at home.* / *That can't be true.* | *She must have forgotten.* / *He can't have lost them again.* [CI] | *It could well be the best solution.* [CI] / *I rather doubt that he'll come.* [CI] |
| **Reagir** | *Great!* / *Really?* | *That's a good idea.* / *What a pity!* | *Exactly!* / *Well, not really.* [CI] | *No way! I don't believe it.* [CI] / *That's just what I was thinking.* [CI] | *You can say that again!* [CI] / *I couldn't care less.* [CI] |

### 5.4 Espiral de usos (mesma forma, função nova), segundo o EGP

| Forma | Usos por nível (EGP) |
|---|---|
| *will* | A1 planos e intenções ("*I will see you soon*") → A2 ofertas e promessas → B1 previsões ("*it'll be harder to meet your old friends*") → C1 hábito típico ("*a dish that will usually contain some kind of sauce*") |
| *must* | A2 obrigação → B1 dedução, convite ("*You must come and stay*"), sugestão forte, elipse ("*Must go now.*") → B2 *must have + -ed*, concessão ("*you must admit*"), ênfase ("*I must say*"), regras → C2 inversão |
| *should* | A2 conselho e sugestão → B1 *should have* (arrependimento), probabilidade ("*It should be a good day!*"), agradecimento ("*you shouldn't have!*") → B2 expectativa, elipse ("*I think you should.*") → C1 *If you should…* e inversão (*Should you need…*) |
| *past simple* | A1 eventos e estados do dia a dia → B1 estados habituais → B2 polidez ("*I wondered/I wanted*", "*It would be better if you provided…*") → C1 *did* enfático para refutar ("*it did rain*") |
| *past continuous* | A2 pano de fundo, evento em andamento → B1 razão, eventos repetidos → B2 polidez ("*I was wondering if I could…*") |
| *present perfect* | A2 experiência, *yet*, *for* → B1 *since*, *already*, passado recente, situação inacabada, com superlativo ("*the most delicious… I have ever tasted*") → B2 *still* |
| *going to* | A2 intenção, previsão com *be* → B1 negativa, passado (*was going to*: plano frustrado), relato |

---

## 6. Dependências: o que vem antes do quê

### 6.1 Grafo de pré-requisitos (resumo)

```
be (am/is/are) ─┬─> perguntas/negativas com be ─> Wh- com be
                ├─> there is/are
                ├─> was/were ───────────────┐
                └─> be + -ing (pres. cont.) ┼─> going to ─> pres. cont. (futuro)
                                            ├─> past continuous ─────────────┐
pronomes sujeito ─> possessivos ─> 's       │                                │
                 └─> pronomes objeto        │                                │
presente simples (I/you/we/they) ─> do/don't/perguntas ─> 3ª pessoa (-s, does)
        │                                   │
        └─> advérbios de frequência         └─> did/didn't (passado ?/−)
passado simples (regular + irregulares) ────┤
        │                                   v
        ├──> particípios irregulares ─> PRESENT PERFECT (experiência)
        │                                 ├─> just/already/yet
        │                                 ├─> PP × past simple ─> for/since ─> PP continuous
        │                                 ├─> superlativo + ever ("the best… I've ever…")
        │                                 ├─> PAST PERFECT ─> 3ª condicional ─> mistas ─> invertidas (C1)
        │                                 ├─> passiva (be + particípio) ─> passiva em todos os tempos ─> impessoal
        │                                 └─> modais perfeitos (should/must/might have)
        ├──> used to ─> would (hábito) ─> be/get used to + -ing
        └──> narrativa (PS + past continuous) ─> + past perfect ─> + past perfect continuous
will (fórmula A1) ─> will (sistema A2) ─> 1ª condicional ─> 2ª condicional (+ past forms, would)
can ─> could (pedido/passado) ─> could have
must/have to (obrigação) ─> must/can't (dedução presente) ─> must/can't have (dedução passada)
perguntas diretas com do/aux sólidas ─> perguntas indiretas (sem inversão) ─> reported questions
like + -ing ─> want/would like + to ─> padrões verbo+to/-ing ─> tell/ask sb to ─> reported requests ─> verbos de relato (suggest -ing…)
relativas who/which/that ─> where/whose ─> não definidoras ─> prep + which/whom, "which" comentário ─> reduzidas/participiais
inversão de pergunta (aux-sujeito) sólida ─> inversão-fórmula (B2) ─> inversão com advérbio negativo (C1)
relativas + what-clauses ─> clivadas (B2/C1)
and/but/because ─> so/then/first/after that ─> although/however/unless ─> despite/whereas/nevertheless ─> admittedly/that said/hence
```

### 6.2 Regras "não usar X antes de Y" (para quem escreve frases)

| # | Regra | Por quê |
|---|---|---|
| D1 | **Nada de presente simples de verbos lexicais antes de o *be* estar firme** (A1.01–A1.02). | O brasileiro mistura "*I am work*". O *be* é a âncora; o *do-support* vem depois, como sistema separado. |
| D2 | **3ª pessoa (-s/*does*) só depois de I/you/we/they + *do***, e então reciclada para sempre. | Aquisição tardia (ordem natural, Krashen); erro sistemático no A2 (descritor do CEFR: "forget to mark agreement"). |
| D3 | **Presente contínuo só depois de *be* + presente simples**; o contraste simples × contínuo vem logo em seguida. | O contínuo é *be* + *-ing*; sem o simples não há contraste. [EF] |
| D4 | ***Going to*, presente contínuo como futuro e passado contínuo dependem do presente contínuo.** | Mesma estrutura *be* + *-ing*. |
| D5 | **Perguntas e negativas no passado (*did/didn't*) só depois do passado afirmativo e do *do* no presente.** | Transferência do *do-support*. |
| D6 | **NÃO usar *present perfect* antes de: (a) passado simples sólido; (b) ~30–50 particípios irregulares de alta frequência (*been, seen, done, had, made, gone, eaten, written…*); (c) *have* como auxiliar, distinto de *have* = "ter".** | Forma: *have* + particípio. Uso: o contraste com o *past simple* é a maior armadilha do falante de português. [EF; EGP A2] |
| D7 | ***for/since* com *present perfect* só depois do contraste *present perfect* × *past simple*.** | "Moro aqui há 5 anos" → o brasileiro diz "*I live here for 5 years*". |
| D8 | ***Present perfect continuous* só depois de *for/since* e do presente contínuo.** | Combinação das duas formas. |
| D9 | ***Past perfect* só depois de narrativa com *past simple* + *past continuous* e dos particípios.** | O *past perfect* é "um passado antes de outro passado"; precisa da âncora narrativa. [EF Pre-int 12A; EGP B1] |
| D10 | **1ª condicional só depois de *will*; 2ª só depois da 1ª + formas do passado + *would* (a fórmula *I'd like* não conta como domínio de *would*); 3ª só depois do *past perfect* e de *would have*; mistas só depois da 2ª e da 3ª; invertidas só no C1.** | Cada uma reaproveita peças da anterior. |
| D11 | **Em *when/as soon as/if* com sentido de futuro, sem *will* na oração subordinada**, a partir do A2. | "Quando eu chegar" → *When I arrive* (não *when I will arrive*). |
| D12 | **Passiva só depois de *be* em vários tempos + particípios.** Presente e passado simples (B1) → outros tempos e com modais (B2) → impessoal e infinitivo passivo (C1). | Fórmulas "*It was built in…*" e "*It's made of…*" podem aparecer antes, como chunk (A2). |
| D13 | ***Reported speech* com mudança de tempo só depois de *past perfect*, *would/could* e ordem de palavras da pergunta indireta.** *Say/tell* + troca de pronome pode vir antes (A2/B1). | O recuo de tempo (*will*→*would*, *have done*→*had done*) exige as formas de destino. |
| D14 | **Pergunta indireta (*Could you tell me where the station is?*) só depois de a pergunta direta com auxiliar estar sólida.** | Estágio final da sequência de perguntas: desligar a inversão. |
| D15 | **Modais perfeitos (*should have*, *must have*, *might have*) só depois dos particípios e dos modais no presente.** | *Should have* (B1) → *must/can't have* (B2). |
| D16 | ***Used to* depois de *did/didn't*; *would* para hábito passado só depois de *used to*; *be/get used to + -ing* só depois do gerúndio após preposição.** | Confusão clássica entre os três. |
| D17 | **Superlativo + *ever* + *present perfect*** ("*the best movie I've ever seen*") **só depois do *present perfect*.** | [EF Pre-int 5B; EGP B1] |
| D18 | **Relativas em camadas:** *who/which/that* definidoras (fim do A2) → *where/whose*, não definidoras com vírgula (B1) → preposição + *which/whom*, *which* comentando a oração inteira, reduzidas (B2) → nominalização e participiais (C1). | [EGP A2/B1/B2; EF Pre-int 3C e Int 10A] |
| D19 | **Inversão** (*Never have I…*) **só depois de *present perfect* + inversão de pergunta sólida**; sistemática (*Not only did…*, *Hardly had…*) **só no C1.** | [EGP B2/C1; CI C1] |
| D20 | **Clivadas** (*What I need is…*, *It was X who…*) **só depois das relativas e das orações com *what*.** | [EGP B2/C1] |
| D21 | ***Wish* + passado** depois da 2ª condicional; ***wish* + *past perfect*** depois da 3ª. | Mesma lógica de "irrealidade". |
| D22 | **Conectores em camadas:** *and/but/or/because* (A1) → *so/then/first/after that/when* (A2) → *although/however/unless/even though/so that* (B1) → *despite/in spite of/whereas/nevertheless/consequently* (B2) → *admittedly/that said/hence/notwithstanding* (C1). | [CI] |
| D23 | **Contrações** (*I'm, it's, don't*) desde o Pré-A1 como fórmula; formas plenas (*I am*) usadas para ênfase e no registro formal (B2/C1). | A fala real é contraída; a digitação exige o apóstrofo desde o dia 1. |

---

## 7. A LISTA ORDENADA DE BLOCOS (entregável principal)

> **Como ler:** ID · nome · conteúdo · **depende de** · **recicla** · frase-modelo (EN | PT-BR) · comprimento-alvo.
> Blocos **R** = revisão com situação (misturam tudo que veio antes e servem de portão para o próximo trecho).
> ★ = **ponto de entrada** para quem quer pular etapas (teste de nivelamento antes; ver seção 9).
> Comprimento em palavras / caracteres, com espaços e pontuação.

### PRÉ-A1 (portão ★ de entrada: início absoluto)

| ID | Bloco | Conteúdo | Depende de | Recicla | Frase-modelo | Tam. |
|---|---|---|---|---|---|---|
| **P0** | Primeiras fórmulas | cumprimentos, polidez, estratégias (não entendi, repita, mais devagar), *yes/no*, números 0–20, soletrar | — | — | *Nice to meet you.* \| Prazer em te conhecer. · *Can you repeat that, please?* \| Você pode repetir, por favor? · *Sorry, I don't understand.* \| Desculpe, não entendi. | 1–5 / 5–30 |

### A1 — Breakthrough (≈ 90–100 h guiadas no acumulado)

| ID | Bloco | Conteúdo | Depende de | Recicla | Frase-modelo | Tam. |
|---|---|---|---|---|---|---|
| **A1.01** | Eu e você: *be* | *I'm / you're*, *Are you…?*, *Yes, I am*; nome, origem; **maiúscula em países e nacionalidades** | P0 | P0 | *I'm from Brazil.* \| Eu sou do Brasil. · *Are you from Canada?* \| Você é do Canadá? | 2–5 / 10–25 |
| **A1.02** | Ele, ela, nós, eles: *be* completo | *he/she/it/we/they*; negativa (*isn't/aren't*); perguntas sim/não; respostas curtas; *It's…* (sujeito obrigatório) | A1.01 | A1.01 | *She's a doctor.* \| Ela é médica. · *It isn't expensive.* \| Não é caro. · *Are they Brazilian? No, they aren't.* \| Eles são brasileiros? Não. | 3–7 / 12–35 |
| **A1.03** | Perguntas com *be* + números | *What/Where/How/How old/Who*; idade (**"tenho 30 anos" = *I'm 30***); telefone, e-mail | A1.02 | P0 (números) | *How old are you? I'm thirty.* \| Quantos anos você tem? Tenho trinta. · *What's your email address?* \| Qual é o seu e-mail? | 3–7 / 15–35 |
| **A1.04** | De quem é: possessivos e 's | *my/your/his/her/our/their*; 's; família | A1.02 | A1.01–03 | *This is my wife, Ana.* \| Esta é minha esposa, Ana. · *My brother's car is red.* \| O carro do meu irmão é vermelho. | 4–7 / 15–35 |
| **A1.05** | Coisas: artigos, plurais, demonstrativos, adjetivos | *a/an*, plurais (-s/-es), *this/that/these/those*; adjetivo antes do substantivo e invariável (*two big cars*); *very* | A1.02 | A1.04 | *These are my keys.* \| Estas são minhas chaves. · *It's a very big house.* \| É uma casa muito grande. | 3–7 / 15–35 |
| **A1.06** | Imperativo e *let's* | ordens, instruções, *please*, *Don't…*, *Let's…*; direções simples | A1.05 | P0 | *Turn left at the bank.* \| Vire à esquerda no banco. · *Don't worry.* \| Não se preocupe. · *Let's go!* \| Vamos! | 2–6 / 8–30 |
| **R1** | Situação: check-in no hotel | mistura de A1.01–06; soletrar nome, número do quarto | A1.01–06 | tudo | *I have a reservation. My name is Carlos Souza.* \| Tenho uma reserva. Meu nome é Carlos Souza. | 3–9 / 15–45 |
| **A1.07** | Presente simples I/you/we/they (+/−) | verbos básicos; *don't*; *like/love/hate* + substantivo; comida, trabalho | A1.02 (D1) | A1.04–05 | *I work in an office.* \| Eu trabalho num escritório. · *We don't eat meat.* \| Nós não comemos carne. | 3–7 / 15–35 |
| **A1.08** | Perguntas com *do* | *Do you…?*, *Where/What/When do you…?*, ordem da pergunta; **objeto obrigatório** (*Do you like it?*); *What do you do?* | A1.07, A1.03 | A1.03 | *Where do you live?* \| Onde você mora? · *What do you do? I'm a developer.* \| O que você faz? Sou desenvolvedor. | 3–7 / 15–40 |
| **A1.09** | Ele e ela: 3ª pessoa | -s/-es/-ies, *has*; *doesn't*; *Does…?* | A1.07–08 (D2) | A1.04 (família) | *She works from home.* \| Ela trabalha de casa. · *Does he speak English?* \| Ele fala inglês? | 3–7 / 15–35 |
| **A1.10** | Rotina e tempo | advérbios de frequência (posição!), horas, *in/on/at*, dias e meses (**maiúscula**) | A1.09 | A1.07–09 | *I always get up at seven.* \| Eu sempre acordo às sete. · *We go to the gym on Mondays.* \| A gente vai à academia às segundas. | 4–8 / 20–40 |
| **A1.11** | *can/can't* | habilidade, permissão, pedido, oferta (*Can I help you?*) | A1.07 | A1.06 | *Can I pay by card?* \| Posso pagar com cartão? · *I can't swim.* \| Eu não sei nadar. | 3–6 / 12–30 |
| **A1.12** | Gostos: *like + -ing* | *like/love/hate/enjoy* + *-ing*; tempo livre | A1.07 | A1.10 | *I like reading before bed.* \| Eu gosto de ler antes de dormir. · *She hates waiting.* \| Ela odeia esperar. | 3–7 / 15–35 |
| **R2** | Situação: café e restaurante | ***I'd like…*** (fórmula), *How much is it?*, *Can I have the bill, please?*, preços | A1.07–12 | A1.03 (números) | *I'd like a coffee and a cheese sandwich, please.* \| Eu queria um café e um sanduíche de queijo, por favor. | 3–10 / 15–50 |
| **A1.13** | Agora: presente contínuo | *am/is/are + -ing*; *What are you doing?*; contraste com o simples; roupas | A1.02, A1.09 (D3) | A1.10 | *I'm working from home today.* \| Hoje estou trabalhando de casa. · *I usually take the bus, but today I'm walking.* \| Normalmente pego ônibus, mas hoje estou indo a pé. | 4–10 / 20–50 |
| **A1.14** | Pronomes objeto | *me/you/him/her/it/us/them* | A1.08 | A1.06, A1.11 | *Call me tomorrow.* \| Me liga amanhã. · *Do you know him?* \| Você conhece ele? | 3–6 / 12–30 |
| **A1.15** | Onde fica: *there is/are* + lugar | *there's/there are*, *some/any*, *Is there…?*; *in/on/under/next to/near*; casa e cidade (**"tem um banco" = *there's a bank***) | A1.05, A1.08 | A1.05 | *There's a bank near here.* \| Tem um banco aqui perto. · *Are there any good restaurants around here?* \| Tem algum restaurante bom por aqui? | 4–8 / 20–45 |
| **A1.16** | Quanto: contáveis e incontáveis | *How much/How many*, *some/any*, *a lot of*; compras e comida | A1.15, R2 | R2 | *How many people are there?* \| Quantas pessoas tem? · *How much water do you drink?* \| Quanta água você bebe? | 4–8 / 20–40 |
| **R3** | Situação: perguntar o caminho e fazer compras | mistura de A1.06, A1.13–16 | A1.13–16 | tudo | *Excuse me, is there a pharmacy near here? Yes, go straight on and turn right.* \| Com licença, tem uma farmácia aqui perto? Sim, siga em frente e vire à direita. | 4–12 / 20–60 |
| **A1.17** | Ontem: *was/were* | passado de *be*; *born*; *yesterday/last…* | A1.02 | A1.03 (datas) | *Where were you born? I was born in Recife.* \| Onde você nasceu? Nasci em Recife. · *I was at home yesterday.* \| Eu estava em casa ontem. | 4–8 / 20–40 |
| **A1.18** | Passado simples (+) | regulares (-ed) + irregulares de alta frequência (*went, had, got, did, saw, made, came, took…*) | A1.17, A1.07 | A1.10 | *We went to the beach last weekend.* \| Fomos à praia no fim de semana passado. · *I worked late yesterday.* \| Trabalhei até tarde ontem. | 4–8 / 20–45 |
| **A1.19** | Passado (?/−) | *Did you…?*, *didn't*, *What did you do…?* | A1.18, A1.08 (D5) | A1.18 | *Did you sleep well?* \| Você dormiu bem? · *I didn't see your message.* \| Eu não vi sua mensagem. | 3–8 / 15–40 |
| **A1.20** | Planos: *going to* | *I'm going to…*, *Are you going to…?* (planos e intenções) | A1.13 (D4) | A1.10 | *I'm going to study English tonight.* \| Vou estudar inglês hoje à noite. · *Are you going to travel this year?* \| Você vai viajar este ano? | 4–8 / 20–45 |
| **A1.21** | Comparar | *-er/more…than*, *better/worse* | A1.05 | A1.15 | *She's taller than her brother.* \| Ela é mais alta que o irmão. · *This phone is more expensive than mine.* \| Este celular é mais caro que o meu. | 4–8 / 20–45 |
| **R4** ★ | Revisão final do A1 + checkpoint | "falar de mim": apresentação, rotina, ontem, planos (ver seção 9) | A1.01–21 | tudo | *My name is Carlos. I'm a developer and I work from home. Yesterday I worked late.* \| Meu nome é Carlos. Sou desenvolvedor e trabalho de casa. Ontem trabalhei até tarde. | 4–12 / 20–60 |

### A2 — Waystage (≈ 180–200 h guiadas no acumulado)

| ID | Bloco | Conteúdo | Depende de | Recicla | Frase-modelo | Tam. |
|---|---|---|---|---|---|---|
| **A2.01** ★ | Perguntas em todos os tempos | revisão de *do/does/did/be/can*; **perguntas de sujeito** (*Who called?* × *Who did you call?*) | R4 | A1.08, A1.19 | *Who called you this morning?* \| Quem te ligou hoje de manhã? · *What happened?* \| O que aconteceu? | 3–8 / 15–40 |
| **A2.02** | Contar uma história | irregulares ampliados; *ago*; *when*; *first, then, after that, finally* | A1.18–19 | A1.17 | *Two years ago, I moved to Curitiba.* \| Há dois anos, me mudei para Curitiba. · *First we had dinner, then we went to a bar.* \| Primeiro jantamos, depois fomos a um bar. | 6–12 / 30–60 |
| **A2.03** | Pano de fundo: passado contínuo | *was/were + -ing*; *when/while*; razão | A2.02, A1.13 (D4) | A2.02 | *I was having lunch when you called.* \| Eu estava almoçando quando você ligou. · *It was raining, so we took a taxi.* \| Estava chovendo, então pegamos um táxi. | 6–12 / 30–60 |
| **A2.04** | Três futuros | *going to* (previsão com evidência); presente contínuo (combinados); ***will*** (decisão na hora, oferta, promessa: *I'll…*) | A1.20, A1.13 | A1.10 | *Look at those clouds. It's going to rain.* \| Olha aquelas nuvens. Vai chover. · *I'm meeting Ana on Friday.* \| Vou encontrar a Ana na sexta *(combinado)*. · *I'll call you later.* \| Te ligo mais tarde. | 4–10 / 20–50 |
| **A2.05** | O maior, o melhor | superlativos (*the -est/the most*), irregulares, *as…as*, *not as…as* | A1.21 | A1.15 | *It's the best restaurant in town.* \| É o melhor restaurante da cidade. · *My car isn't as fast as yours.* \| Meu carro não é tão rápido quanto o seu. | 5–10 / 25–50 |
| **A2.06** | Quanto e nada | *much/many/a lot of/a few/a little/too much*; *something/anything/nothing/nobody/everyone* | A1.16 | A1.15 | *I don't have much time today.* \| Não tenho muito tempo hoje. · *There's nothing in the fridge.* \| Não tem nada na geladeira. | 4–9 / 20–45 |
| **R5** | Situação: viagem (aeroporto, estação, hotel) | horários, passagens, check-in, imprevisto simples | A2.01–06 | tudo | *What time does the next train to Lisbon leave?* \| A que horas sai o próximo trem para Lisboa? · *A return ticket to Brighton, please.* [CI] \| Uma passagem de ida e volta para Brighton, por favor. | 5–12 / 25–60 |
| **A2.07** | Já fiz isso? *Present perfect* I | *have/has* + particípio; ***ever/never***; experiências; 30–50 particípios de alta frequência | A1.18–19, A2.02 (D6) | A2.02 | *Have you ever been to London?* \| Você já foi a Londres? *(alguma vez na vida)* · *I've never eaten sushi.* \| Nunca comi sushi. | 4–9 / 20–45 |
| **A2.08** | Acabei de: *present perfect* II | ***just/already/yet***; resultado presente (*I've lost my keys*) | A2.07 | A2.07 | *I've just finished the report.* \| Acabei de terminar o relatório. · *Have you finished yet?* \| Você já terminou? · *I haven't seen it yet.* \| Ainda não vi. | 4–9 / 20–45 |
| **A2.09** | Tenho que, devo, não pode | *have to/don't have to*, *must/mustn't*, *should/shouldn't* (conselho) | A1.11 | A1.06 | *I have to work tomorrow.* \| Tenho que trabalhar amanhã. · *You don't have to come.* \| Você não precisa vir. · *You should see a doctor.* \| Você deveria ir ao médico. | 4–9 / 20–45 |
| **A2.10** | Querer fazer, gostar de fazer | verbo + *to* (*want, need, decide, hope, would like*); verbo + *-ing* (*enjoy, finish, mind*); *to* de finalidade | A1.12 | A1.20 | *I want to learn English.* \| Quero aprender inglês. · *I came here to see you.* \| Vim aqui para te ver. | 4–9 / 20–45 |
| **R6** | Situação: médico e farmácia | sintomas (*I have a headache / a sore throat*), conselho (*should*), obrigação; evitar *since* aqui (é ensinado no B1.02) | A2.07–10 | tudo | *I have a headache. What should I take?* \| Estou com dor de cabeça. O que devo tomar? · *You should drink a lot of water.* \| Você deveria beber muita água. | 4–10 / 20–50 |
| **A2.11** | Convidar, sugerir, pedir, oferecer | *Would you like to…?*, *Why don't we…?*, *Shall we…?*, *Could you…?*, *Could I…?* | A1.11, A2.10 | R2 | *Would you like to come to dinner on Saturday?* \| Quer vir jantar no sábado? · *Could you open the window, please?* \| Você poderia abrir a janela, por favor? | 5–10 / 25–50 |
| **A2.12** | Se e quando: condicional zero e 1ª | *if* + presente, imperativo/*will*/*can*; *when/as soon as* + presente (D11) | A2.04, A1.09 | A2.09 | *If it rains, we'll stay home.* \| Se chover, vamos ficar em casa. · *Call me when you arrive.* \| Me liga quando chegar. | 5–11 / 25–55 |
| **A2.13** | Talvez: *might/may/could* | possibilidade; *could* (habilidade no passado: *couldn't sleep*) | A1.11, A2.04 | A2.12 | *I might be late tonight.* \| Posso chegar atrasado hoje à noite. · *I couldn't sleep last night.* \| Não consegui dormir ontem à noite. | 4–9 / 20–45 |
| **A2.14** | Quem, que, onde: relativas definidoras | *who/which/that/where*; omissão do pronome objeto | A1.05, A1.07 (D18) | A2.02 | *She's the woman who lives next door.* \| Ela é a mulher que mora ao lado. · *This is the app I use every day.* \| Este é o app que eu uso todo dia. | 6–11 / 30–55 |
| **A2.15** | Como e de quem | advérbios de modo (-ly); phrasal verbs comuns (*turn on/off, look for, pick up, get up*); *mine/yours/his/hers* | A1.06, A1.04 | A2.11 | *Can you turn off the lights?* \| Você pode apagar as luzes? · *Is this phone yours?* \| Esse celular é seu? | 4–9 / 20–45 |
| **R7** ★ | Revisão final do A2 + checkpoint | "contar as últimas férias" [can-do do CI A2] + combinar um encontro | A2.01–15 | tudo | *Last summer we went to Salvador. We stayed there for a week and visited the old town.* \| No verão passado fomos a Salvador. Ficamos lá uma semana e visitamos o centro histórico. | 6–14 / 30–70 |

### B1 — Threshold (≈ 350–400 h guiadas no acumulado)

| ID | Bloco | Conteúdo | Depende de | Recicla | Frase-modelo | Tam. |
|---|---|---|---|---|---|---|
| **B1.01** ★ | Já fui × fui | *present perfect* × *past simple* (indefinido × definido); *Did you…?* × *Have you…?* | A2.07–08 | A2.02 | *I've been to Salvador. I went there in 2019.* \| Já fui a Salvador. Fui lá em 2019. · *Did you see the game last night?* \| Você viu o jogo ontem à noite? | 6–14 / 30–70 |
| **B1.02** | Há quanto tempo: *for/since* + contínuo | *for/since*, *How long…?*, *present perfect continuous* | B1.01, A1.13 (D7, D8) | A2.07 | *I've lived here for five years.* \| Moro aqui há cinco anos *(e ainda moro)*. · *How long have you been studying English?* \| Há quanto tempo você estuda inglês? · *I've been working on this bug all morning.* \| Estou nesse bug a manhã inteira. | 6–13 / 30–65 |
| **B1.03** | Eu costumava: *used to* | *used to/didn't use to* | A1.19 (D16) | A2.02 | *I used to play football every weekend.* \| Eu costumava jogar futebol todo fim de semana. · *We didn't use to have internet at home.* \| A gente não tinha internet em casa *(antigamente)*. | 6–12 / 30–60 |
| **B1.04** | Antes daquilo: *past perfect* e tempos narrativos | *had* + particípio; *already, never…before, by the time*; PS + PC + PP | A2.02–03, A2.07 (D9) | A2.03 | *When I arrived, the meeting had already started.* \| Quando cheguei, a reunião já tinha começado. · *I had never seen snow before that trip.* \| Eu nunca tinha visto neve antes daquela viagem. | 7–14 / 35–70 |
| **B1.05** | Previsões e futuro contínuo | *will* × *going to*; *probably/definitely*; *I think… will*; *future continuous* | A2.04, A1.13 | A2.12 | *She'll probably be late.* \| Ela provavelmente vai se atrasar. · *This time tomorrow, I'll be flying to Lisbon.* \| A esta hora amanhã estarei voando para Lisboa. | 5–12 / 25–60 |
| **B1.06** | E se…? 2ª condicional | *if* + passado, *would/could*; ***If I were you, I'd…***; *What would you do if…?* | A2.12, A1.18, A2.11 (D10) | A2.13 | *If I had more time, I'd learn the guitar.* \| Se eu tivesse mais tempo, aprenderia violão. · *If I were you, I'd accept the offer.* \| Se eu fosse você, aceitaria a proposta. | 7–14 / 35–70 |
| **R8** | Situação: entrevista de emprego | experiência (*present perfect* + *for*), passado, planos, pontos fortes | B1.01–06 | tudo | *I've been working as a developer for six years, and I led a team of four people in my last job.* \| Trabalho como desenvolvedor há seis anos, e no último emprego liderei uma equipe de quatro pessoas. | 8–18 / 45–95 |
| **B1.07** | Foi feito: passiva I | presente e passado simples; *by*; *It's made of…* | A2.07, A1.17 (D12) | B1.04 | *English is spoken all over the world.* \| O inglês é falado no mundo inteiro. · *This house was built in 1920.* \| Esta casa foi construída em 1920. | 6–12 / 30–60 |
| **B1.08** | Ele disse que…: *reported speech* | *say/tell*; recuo de tempo (*will*→*would*, *is*→*was*, *have done*→*had done*); perguntas indiretas relatadas; *ask/tell sb to* | B1.04, A2.04, A2.01 (D13) | B1.07 | *She said she was tired.* \| Ela disse que estava cansada. · *He asked me where I lived.* \| Ele me perguntou onde eu morava. · *My boss told me to wait.* \| Meu chefe me disse para esperar. | 5–12 / 25–60 |
| **B1.09** | Deve estar: dedução + perguntas indiretas | *must/might/can't* + *be*; *Do you know where…?*, *Could you tell me…?* | A2.09, A2.13, B1.08 (D14) | A2.13 | *He must be at home.* \| Ele deve estar em casa *(dedução)*. · *That can't be true.* \| Isso não pode ser verdade. · *Could you tell me where the station is?* \| Você poderia me dizer onde fica a estação? | 4–11 / 20–55 |
| **B1.10** | Devia ter: modais no passado | *should have/shouldn't have/could have/might have* | B1.09, A2.07 (D15) | B1.04 | *You should have told me.* \| Você devia ter me contado. · *They might have missed the bus.* \| Eles podem ter perdido o ônibus. | 5–10 / 25–50 |
| **B1.11** | Se tivesse…: 3ª condicional | *if* + *past perfect*, *would have* + particípio | B1.04, B1.06, B1.10 (D10) | B1.06 | *If I had known, I would have called you.* \| Se eu soubesse, teria te ligado. · *If we had left earlier, we wouldn't have missed the flight.* \| Se tivéssemos saído mais cedo, não teríamos perdido o voo. | 8–14 / 40–70 |
| **B1.12** | Relativas II + gerúndio | *whose*, não definidoras com vírgula, *where/when*; gerúndio como sujeito e depois de preposição | A2.14, A1.12 (D18) | B1.07 | *My neighbor, who is a doctor, helped me.* \| Meu vizinho, que é médico, me ajudou. · *I'm interested in learning Spanish.* \| Tenho interesse em aprender espanhol. | 6–13 / 30–65 |
| **B1.13** | Ligar ideias | *although, however, even though, unless, so that, in order to, because of*; *so/such*; *too/enough*; *question tags*; *so/neither do I* | A1/A2 (D22) | tudo | *Although it was late, we kept working.* \| Embora fosse tarde, continuamos trabalhando. · *You're Brazilian, aren't you?* \| Você é brasileiro, né? · *I love coffee. So do I.* \| Adoro café. Eu também. | 4–14 / 20–70 |
| **B1.14** | Opinar e gerenciar a conversa | opinar, concordar e discordar com educação; interromper; mudar de assunto e retomar; checar compreensão [CI B1] | B1.13 | tudo | *I see what you mean, but I don't agree.* \| Entendo o que você quer dizer, mas não concordo. · *Sorry to interrupt, but I have a question.* \| Desculpe interromper, mas tenho uma pergunta. | 5–12 / 25–60 |
| **R9** ★ | Revisão final do B1 + checkpoint | reclamação por e-mail e telefone; contar um imprevisto de viagem | B1.01–14 | tudo | *I'm writing to complain about the laptop I bought last week, which stopped working after two days.* \| Escrevo para reclamar do notebook que comprei semana passada, que parou de funcionar depois de dois dias. | 8–18 / 45–95 |

### B2 — Vantage (≈ 500–600 h guiadas no acumulado)

| ID | Bloco | Conteúdo | Depende de | Recicla | Frase-modelo | Tam. |
|---|---|---|---|---|---|---|
| **B2.01** ★ | Tempos narrativos completos | + *past perfect continuous*; *Had they been waiting long?* | B1.04, B1.02 | B1.04 | *I was exhausted because I'd been working for sixteen hours.* \| Eu estava exausto porque vinha trabalhando há dezesseis horas. | 8–16 / 45–85 |
| **B2.02** | Futuro avançado | *future perfect* (+ contínuo), *future continuous*, *be about to*, *be likely to* | B1.05, A2.07 | B1.02 | *By next year, I'll have finished my degree.* \| Até o ano que vem, terei terminado a faculdade. · *By June, I'll have been working here for ten years.* \| Em junho, completo dez anos trabalhando aqui. | 8–15 / 40–80 |
| **B2.03** | Passiva II | todos os tempos; com modais; *have/get something done*; *It is said that… / He is believed to…* | B1.07, B1.10 (D12) | B1.07 | *The road is being repaired.* \| A estrada está sendo consertada. · *I had my car fixed yesterday.* \| Mandei consertar meu carro ontem. · *The report should have been sent yesterday.* \| O relatório deveria ter sido enviado ontem. | 6–14 / 30–75 |
| **B2.04** | Deve ter sido: dedução no passado | *must have/can't have/might have*; *needn't have/didn't need to* | B1.09–10 (D15) | B1.10 | *She must have forgotten.* \| Ela deve ter esquecido. · *He can't have left already.* \| Ele não pode ter saído já. · *You needn't have bought it.* \| Você não precisava ter comprado *(mas comprou)*. | 4–10 / 20–55 |
| **B2.05** | Quem dera: *wish*, *if only* + mistas | *wish* + passado / *past perfect* / *would*; *I'd rather*; *It's time we…*; condicionais mistas | B1.06, B1.11 (D21) | B1.11 | *I wish I had more time.* \| Queria ter mais tempo. · *I wish I'd studied harder.* \| Queria ter estudado mais. · *If I had taken that job, I'd be living in Lisbon now.* \| Se eu tivesse aceitado aquele emprego, estaria morando em Lisboa agora. | 5–15 / 25–80 |
| **B2.06** | Verbos de relato | *suggest/recommend + -ing*, *deny/admit + -ing*, *warn/advise sb (not) to*, *offer/refuse to* | B1.08, A2.10 | B1.08 | *She suggested going to the beach.* \| Ela sugeriu irmos à praia. · *They warned us not to go out at night.* \| Eles nos avisaram para não sair à noite. | 5–12 / 25–60 |
| **B2.07** | Hábitos e costume | *would/used to* (passado); *be used to/get used to + -ing*; *will* para hábito irritante | B1.03, B1.12 (D16) | B1.03 | *When I was a kid, we would spend every summer at the beach.* \| Quando eu era criança, passávamos todo verão na praia. · *I'm used to working at night.* \| Estou acostumado a trabalhar à noite. | 6–14 / 30–70 |
| **B2.08** | Relativas III e particípio | preposição + *which/whom*; *which* comentando a oração inteira; reduzidas (*the man sitting…*) | B1.12 (D18) | B1.12 | *He passed the exam, which surprised everyone.* \| Ele passou na prova, o que surpreendeu todo mundo. · *The people I work with are great.* \| As pessoas com quem trabalho são ótimas. | 6–14 / 30–75 |
| **B2.09** | Argumentar com conectores formais | *despite/in spite of, whereas, nevertheless, consequently, on the one hand… on the other hand, to sum up* | B1.13 (D22) | B1.14 | *Despite the rain, we had a great time.* [CI] \| Apesar da chuva, nos divertimos muito. · *On the other hand, it would cost much more.* \| Por outro lado, custaria muito mais. | 6–16 / 30–85 |
| **B2.10** | Ênfase I: inversão-fórmula e clivadas | *Never have I…*, *No sooner had… than*; *What I need is…*, *The reason (why) I'm writing is…* | A2.07, B1.04, B1.12 (D19, D20) | B1.12 | *Never have I seen such a beautiful place.* \| Nunca vi um lugar tão bonito. · *What I really need is a holiday.* \| O que eu realmente preciso é de férias. | 6–14 / 30–75 |
| **B2.11** | Funções B2 + léxico | especular, avaliar prós e contras, negociar, convidar o outro a falar, ganhar tempo; phrasal verbs ampliados, colocações, idiomas frequentes | todos | todos | *That's a difficult question to answer.* \| Essa é uma pergunta difícil de responder. · *Let's hear what Ana has to say.* \| Vamos ouvir o que a Ana tem a dizer. | 5–15 / 25–80 |
| **R10** ★ | Revisão final do B2 + checkpoint | reunião de trabalho e debate: propor, objetar, negociar, resumir | B2.01–11 | tudo | *I see your point, but if we postpone the launch, we might lose the client.* \| Entendo seu ponto, mas se adiarmos o lançamento, podemos perder o cliente. | 10–20 / 55–110 |

### C1 — Effective Operational Proficiency (≈ 700–800 h guiadas no acumulado)

| ID | Bloco | Conteúdo | Depende de | Recicla | Frase-modelo | Tam. |
|---|---|---|---|---|---|---|
| **C1.01** ★ | Inversão com advérbios negativos | *Not only…but also*, *Hardly…when*, *Under no circumstances*, *Little did I know*, *Only then* | B2.10 (D19) | B1.04 | *Not only did he lie, but he also blamed me.* \| Ele não só mentiu, como também me culpou. · *Under no circumstances should you share your password.* \| Em hipótese alguma compartilhe sua senha. | 8–16 / 45–90 |
| **C1.02** | Condicionais invertidas e alternativas | *Had I known…*, *Should you need…*, *Were I to…*; *provided that, as long as, supposing, otherwise, but for* | B1.11, B2.05, C1.01 | B2.05 | *Had I known, I would have come earlier.* \| Se eu soubesse, teria vindo mais cedo. · *Should you need any help, let me know.* \| Caso precise de ajuda, me avise. | 6–16 / 35–90 |
| **C1.03** | Clivadas e *fronting* | *It was X who…*; *All I want is…*; *do* enfático; *fronting* | B2.10 (D20) | B2.08 | *It was Maria who found the bug.* \| Foi a Maria quem encontrou o bug. · *I do appreciate your help.* \| Eu agradeço muito a sua ajuda, de verdade. | 5–14 / 30–75 |
| **C1.04** | Modalidade avançada | *bound to, supposed to, likely to, may well, could well, might as well, ought to have* | B2.04 | B1.09 | *There's bound to be trouble at the meeting.* [CI] \| Com certeza vai ter confusão na reunião. · *It could well be the best solution.* [CI] \| Pode muito bem ser a melhor solução. | 6–14 / 35–75 |
| **C1.05** | Passivas avançadas e impessoais | *It is widely believed that…*, *He is thought to have…*, *having been* + particípio, *being* + particípio | B2.03, B2.08 | B2.03 | *It is widely believed that the policy will fail.* \| Acredita-se amplamente que a política vai fracassar. · *He is thought to have left the country.* \| Acredita-se que ele tenha deixado o país. | 7–16 / 40–90 |
| **C1.06** | *Hedging*, linguagem vaga e registro | *sort of, kind of, -ish, or so, I'd say, It would seem that, arguably*; formal × informal | B2.09 | B2.11 | *There were thirty or so people at the event.* \| Havia umas trinta pessoas no evento. · *It would seem that the data supports this view.* \| Ao que parece, os dados sustentam essa visão. | 6–15 / 35–85 |
| **C1.07** | Conceder e rebater | *Admittedly…*, *That said…*, *Granted, …*, *It could be argued that…*, *Even so…*, *No one would dispute that…* | B2.09, C1.06 | B2.09 | *Admittedly, the plan is expensive. That said, it's our best option.* \| É verdade que o plano é caro. Dito isso, é a nossa melhor opção. | 8–18 / 45–100 |
| **C1.08** | Nominalização, participiais, elipse | *the implementation of…*; *Having finished…, she…*; *I hope so / I'm afraid not*; substituição | B2.08 | C1.05 | *The implementation of the new system took two years.* \| A implantação do novo sistema levou dois anos. · *Having finished the report, she went home.* \| Depois de terminar o relatório, ela foi para casa. | 7–16 / 40–90 |
| **C1.09** | Léxico C1: idiomas, colocações, falsos cognatos | phrasal verbs separáveis; colocações fortes; ***actually, eventually, pretend, push, realize, sensible, library…***; uso diferenciado de sinônimos | espiral | tudo | *Eventually, he realized he had been wrong.* \| No fim, ele percebeu que estava errado. · *Let's call it a day.* \| Vamos encerrar por hoje. | 5–15 / 25–85 |
| **R11** ★ | Revisão final do C1 | apresentação técnica, *post-mortem*, negociação, e-mail formal | C1.01–09 | tudo | *Had we monitored the logs more closely, we would have caught the issue before it reached production.* \| Se tivéssemos monitorado os logs mais de perto, teríamos pegado o problema antes de chegar à produção. | 12–25 / 80–140 |

**Totais:** 1 bloco pré-A1, 21 + 4 R no A1, 15 + 3 R no A2, 14 + 2 R no B1, 11 + 1 R no B2, 9 + 1 R no C1, ou seja, **~82 blocos**. Com 40–60 frases em média por bloco, dá ~3.700–4.900 frases (seção 3). Sugiro que cada bloco vire uma "trilha" ou "fase" no mapa, no mesmo formato das trilhas e lições do curso de Dart.

**Trilha paralela opcional "Inglês para dev"** (o CI recomenda acrescentar o que o aluno precisa): as mesmas estruturas aplicadas ao trabalho. A1 *I'm a developer. I work from home.* → A2 *I fixed a bug yesterday.* → B1 *I've been working on this feature for two weeks.* → B2 *The deployment should have been tested more carefully.* → C1 *Had we monitored the logs, we would have caught the issue earlier.*

---

## 8. Armadilhas PT-BR → EN que afetam a progressão e a "tradução em cima"

Como a pessoa lê o português e digita o inglês, **qualquer estrutura sem equivalente 1:1 vira ambiguidade**. Proponho que a tradução PT-BR seja natural, **mais uma dica curta entre parênteses ou em cinza** quando o português não determina a forma inglesa.

| # | Português | Inglês-alvo | Bloco | Armadilha | Dica sugerida na tradução |
|---|---|---|---|---|---|
| 1 | Tenho 30 anos. | *I'm 30.* | A1.03 | "*I have 30 years*" | — (memorizar como fórmula) |
| 2 | Está chovendo. / É importante. | *It's raining.* / *It's important.* | A1.02, A1.13 | sujeito oculto | — |
| 3 | Tem um banco aqui perto. | *There's a bank near here.* | A1.15 | "*Have a bank…*" | — |
| 4 | carros azuis | *blue cars* | A1.05 | adjetivo depois do substantivo e no plural | — |
| 5 | segunda-feira, janeiro, brasileiro, inglês | *Monday, January, Brazilian, English* | A1.01, A1.10 | **maiúsculas** (armadilha específica de digitação!) | — |
| 6 | Ela trabalha… | *She works…* | A1.09 + sempre | esquecer o -s | — (reciclagem eterna) |
| 7 | Você gosta? | *Do you like it?* | A1.08, A1.14 | omitir *do* e o objeto | — |
| 8 | Já fui a Paris. / Fui a Paris em 2019. | *I've been to Paris.* / *I went to Paris in 2019.* | A2.07, B1.01 | PP × PS | *(alguma vez na vida)* / *(quando)* |
| 9 | Moro aqui há 5 anos. | *I've lived / I've been living here for five years.* | B1.02 | "*I live here for…*" | *(e ainda moro)* |
| 10 | desde 2015 / há 2 horas | *since 2015* / *for two hours* | B1.02 | *since* × *for* | — |
| 11 | Vou viajar amanhã. | *I'm traveling* (combinado) / *I'm going to travel* (plano) / *I'll travel* (decisão agora) | A2.04 | 3 futuros | *(combinado)*, *(plano)*, *(decidi agora)* |
| 12 | Quando eu chegar, te ligo. | *When I arrive, I'll call you.* | A2.12 | "*when I will arrive*" | — |
| 13 | Ele deve estar em casa. / Você deve estudar. | *He must be at home.* / *You should/must study.* | A2.09, B1.09 | "deve" = dedução × obrigação | *(dedução)* / *(conselho)* / *(obrigação)* |
| 14 | Me explica isso. | *Can you explain this to me?* | A2.11 | "*Explain me*" | — |
| 15 | Ele me disse que… / Ele disse que… | *He told me (that)…* / *He said (that)…* | B1.08 | *say* × *tell* | — |
| 16 | As pessoas são… | *People are…* | A1/A2 | "*people is*" | — |
| 17 | A vida é difícil. | *Life is hard.* | A2/B1 | artigo com sentido genérico | — |
| 18 | Se eu fosse você… | *If I were you…* | B1.06 | — (fórmula) | — |
| 19 | Eu costumava… | *I used to…* | B1.03 | "*I costume*" | — |
| 20 | Estou acostumado a… | *I'm used to + -ing* | B2.07 | "*I'm used to work*" | — |
| 21 | Fazer | *make* × *do* | A2 (léxico) | escolha do verbo | *(fazer = produzir)*, se ajudar |
| 22 | na verdade / no fim / fingir / empurrar / perceber | *actually / eventually / pretend / push / realize* | C1.09 (mas aparecem antes) | falsos cognatos [CI C1] | marcar o falso cognato na 1ª ocorrência |
| 23 | Você não precisava ter comprado. | *You needn't have bought it.* × *You didn't need to buy it.* | B2.04 | comprou ou não comprou? | *(mas comprou)* / *(e não comprou)* |
| 24 | Mandei consertar o carro. | *I had my car fixed.* | B2.03 | "*I sent to fix*" | *(alguém consertou para mim)* |

---

## 9. Implicações para o desenho do curso (o que levar daqui)

1. **Portões para pular etapas (★).** Pontos de entrada: P0 · A2.01 · B1.01 · B2.01 · C1.01. Antes de cada um, um **teste de 15–20 frases do português para o inglês, digitadas de memória**, cobrindo as estruturas que dão acesso ao trecho seguinte (as dependências da seção 6). Sugestão: ≥80% das frases com ≤1 erro = pula. Abaixo disso, o resultado indica **quais blocos fazer** (ex.: errou só *present perfect* → faz A2.07–A2.08 e segue). Cada bloco também pode ter um "test-out" (5 frases) para quem já domina.
2. **Modo cópia antes do modo memória.** Estrutura nova aparece primeiro com o inglês visível esmaecido (como o motor atual faz com código), depois com dicas parciais e por fim só com o português. Isso permite introduzir uma estrutura **antes** do nível de produção livre do EGP sem frustrar (seção 1.3).
3. **Fórmulas no começo de cada nível.** Cada nível abre com as fórmulas mais úteis da situação, inclusive acima do nível gramatical (chunk-first), e "abre os slots" depois.
4. **Personagens e situações recorrentes** (o CI pede contexto). Um elenco fixo e um "fio narrativo" por nível (ex.: o Carlos, dev, que viaja, trabalha, faz entrevista, lidera reunião) ajudam a memorizar o contexto, que é exatamente o pedido do usuário.
5. **Reciclagem programada**: revisões R a cada 4–6 blocos; frases de blocos antigos voltam nos novos com usos novos (seção 5.4); os pontos de interferência do português ganham quota fixa de frases em todos os níveis.
6. **Tamanho de frase como parâmetro**: usar a tabela da seção 4 como faixa de validação automática ao gerar frases (A1 ≤ ~45 caracteres; B1 ≤ ~90; C1 ≤ ~140), com frases longas digitadas primeiro em partes.
7. **C1 com a cara do aluno**: o consenso cai no C1 (CI). Use a trilha "Inglês para dev" como eixo principal ali.
8. **Ortografia**: definir um padrão. Sugiro o **americano** (*color, center, traveling*), por coerência com teclado e mercado de dev; o British Council e o English File usam o britânico. Avisar o motor de digitação para aceitar o apóstrofo reto e o tipográfico (’) nas contrações.
9. **Expectativa honesta**: a digitação cobre ~25–30% das horas guiadas até o C1 (seção 3). Vale mostrar isso no app e oferecer áudio, ditado e escuta como complemento.

---

## 10. Fontes

### 10.1 Lidas nesta sessão (com URL)

1. British Council & EAQUALS — North, B.; Ortega, A.; Sheehan, S. *A Core Inventory for General English* (2010/2011). PDF: https://www.eaquals.org/wp-content/uploads/EAQUALS_British_Council_Core_Curriculum_April2011.pdf
2. British Council & EAQUALS — *Core Inventory Posters (2018 update)*, A1–C1. PDF: https://www.eaquals.org/wp-content/uploads/Core-Inventory-Posters-2018-update.pdf · página: https://www.eaquals.org/resources/the-core-inventory-for-general-english/
3. English Profile — *English Grammar Profile Online*: https://englishprofile.org/?menu=egp-online · cópia da planilha com 1.239 itens analisada aqui: https://github.com/ninja33/EGP (arquivo `asset/egpo.xlsx`)
4. Mark, G. (2023). *Building on the insights from the English Grammar Profile: from really good to painfully obvious*. L2P workshop, Gotemburgo, 20–21/abr/2023. PDF: https://spraakbanken.gu.se/sites/default/files/2023/Geraldine_grammar_GothenburgApril2023_2.pdf
5. O'Keeffe, A. & Mark, G. (2017). The English Grammar Profile of learner competence: Methodology and key findings. *International Journal of Corpus Linguistics* 22(4): 457–489. Registro: https://dspace.mic.ul.ie/handle/10395/2151 (só o registro; o artigo é citado pela F4)
6. CEFR-J Grammar Profile (20180315), CEFR-J Wordlist 1.5 e Octanove Vocabulary Profile C1/C2: https://github.com/openlanguageprofiles/olp-en-cefrj
7. *English File 4th edition — Beginner Teacher's Guide* (Oxford University Press, 2019), Syllabus checklist: https://languageadvisor.net/wp-content/uploads/2021/09/English_File_4th_edition_Beginner_TG.pdf
8. Niğde Ömer Halisdemir University — programa 2023-24 com *English File 4th ed.* Elementary, Pre-Intermediate e Intermediate: https://static.ohu.edu.tr/uniweb/media/portallar/yabancidiller//sayfalar/15346/qmb3iww4.pdf
9. *Interchange Intro, 5th edition — Teacher's Edition*, "Plan of Intro Book" (Cambridge University Press): https://basicedu.uodiyala.edu.iq/wp-content/uploads/2025/07/Interchange_Intro_5th_edition_teachers.pdf
10. Krashen, S. (1982). *Principles and Practice in Second Language Acquisition*. Pergamon. PDF: https://www.sdkrashen.com/content/books/principles_and_practice.pdf
11. Descritores do CEFR "General Linguistic Range" e "Grammatical Accuracy" (CEFTrain, Univ. Helsinki): https://blogs.helsinki.fi/ceftrain/?p=117
12. Cambridge English — *Guided learning hours*: https://support.cambridgeenglish.org/hc/en-gb/articles/202838506-Guided-learning-hours (acesso direto bloqueado com 403; números confirmados por busca e por https://ecenglish.com/en/blog/english/how-long-to-learn-english-to-b2-level/)
13. Wikipedia — *Spiral approach* (Bruner, J. 1960, *The Process of Education*, pp. 52–54): https://en.wikipedia.org/wiki/Spiral_approach
14. Wikipedia — *Processability theory* (Pienemann): https://en.wikipedia.org/wiki/Processability_theory
15. Wikipedia — *English Profile*: https://en.wikipedia.org/wiki/English_Profile
16. Text Inspector — *English Vocabulary Profile* ("just under 7,000 headwords"; via resultado de busca, página com 403): https://textinspector.com/help/lexis-evp/
17. Conselho da Europa — *CEFR Companion Volume* (2020), página oficial: https://www.coe.int/en/web/common-european-framework-reference-languages (bloqueado com Cloudflare nesta sessão; usado só para fatos gerais: Pré-A1, mediação)

### 10.2 Referências de memória, não acessadas nesta sessão (†)

- Lightbown, P. & Spada, N. *How Languages are Learned* (4ª ed., OUP, 2013): seis estágios das perguntas em inglês como L2.
- Pienemann, M. (1998). *Language Processing and Second Language Development: Processability Theory*. John Benjamins.
- Hu, M. & Nation, P. (2000). Unknown vocabulary density and reading comprehension. *Reading in a Foreign Language* 13(1).
- Nation, I.S.P. (2013). *Learning Vocabulary in Another Language* (2ª ed.). CUP.
- Lewis, M. (1993). *The Lexical Approach*. LTP.
- van Ek, J.A. & Trim, J.L.M. (2001). *Waystage / Threshold 1990 / Vantage*. CUP (citados no próprio Core Inventory).
- Sumários de *Headway 5th ed.* (OUP), *Cambridge Empower 2nd ed.* e *Evolve*: não verificados aqui; até onde sei, seguem a mesma espinha dorsal descrita na seção 2.4.

### 10.3 Artefatos de trabalho (no scratchpad, para quem quiser conferir)

- `pesquisa/fontes/core2011.txt`, `posters2018.txt` — texto extraído do Core Inventory
- `pesquisa/fontes/egp.json` — os 1.239 itens do EGP em JSON (nível, categoria, can-do, exemplos)
- `pesquisa/fontes/cefrj_*.csv` — perfis do CEFR-J
- `pesquisa/fontes/EF4_Beginner.txt`, `ohu_qmb3iww4.txt`, `ic_intro.txt` — sumários dos livros
- `pesquisa/fontes/krashen1982.txt` — Krashen (1982)
