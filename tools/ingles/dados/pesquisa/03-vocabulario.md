# 03 · Vocabulário: listas de frequência, chunks e inglês técnico

> Frente de pesquisa 3 do curso de inglês do PAC·DART (terceiro curso, depois de Dart/Flutter e C#/.NET).
> Pergunta que esta frente responde: **quais palavras e expressões ensinar, e em que ordem**, num curso em que a unidade é a **frase**: a tradução em PT-BR fica em cima e a pessoa digita a frase em inglês inteira, várias vezes.
> Data da pesquisa: 04/out/2026. Todas as fontes estão citadas com URL no corpo do texto e na seção 13.
> Convenções: **[S]** = item do *Survival Syllabus* de Nation & Crabbe (1991); **[P1k]…[P5k]** = item da PHRASE List na banda de frequência 1k…5k; **[PV n]** = posição *n* na PHaVE List.

---

## 0. Resumo executivo

1. **A frequência das palavras é extremamente concentrada.** No Oxford English Corpus, 10 lemas cobrem 25% de tudo o que se escreve, 100 lemas cobrem 50% e 1.000 lemas cobrem 75%. Na fala é ainda mais concentrado: pelo meu cálculo sobre o arquivo oficial da NGSL-Spoken, os 100 lemas mais frequentes cobrem cerca de 64% dos tokens de conversa não roteirizada e os 300 primeiros cobrem cerca de 75%.
2. **Entender de verdade exige de 95% a 98% de cobertura.** Na fala, isso significa de 2.000 a 3.000 famílias de palavras para chegar a 95% e de 6.000 a 7.000 para 98%. Na leitura, cerca de 4.000 para 95% e de 8.000 a 9.000 para 98% (Nation 2006; van Zeeland & Schmitt 2013). Consequência para o curso: o "zero → B2" tem que entregar algo como **3.000 palavras e algumas centenas de chunks**. O C1 vai até cerca de 5.000.
3. **Mais da metade do discurso é pré-fabricado.** Sequências formulaicas são 58,6% da fala e 52,3% da escrita (Erman & Warren 2000). *Lexical bundles* de 3 ou 4 palavras são 28% da conversa (Biber et al. 1999). Isso valida a decisão do dono: a unidade certa é **a frase com um chunk em foco**, não a palavra solta.
4. **Lista-espinha recomendada: família NGSL** (Browne, Culligan & Phillips), com licença **CC BY-SA 4.0, que permite inclusive uso comercial**. São a NGSL 1.2 (2.809 lemas, cerca de 92% de cobertura do inglês geral), a **NGSL-Spoken 1.2 (721 lemas, cerca de 90% da fala espontânea)**, a NGSL-GR (5.000 palavras em 11 bandas, cerca de 98%) e as extensões NAWL (acadêmico), BSL (negócios) e TSL (TOEIC). É a única família de listas grande, recente, graduada e com licença clara para embutir no app.
5. **Correção do briefing:** "NGSL 2.0" **não existe**. A versão vigente é a **NGSL 1.2** (abr/2023). Ver §1.
6. **Chunks:** a PHRASE List (Martinez & Schmitt 2012) traz **505 expressões não transparentes** (como *take place*, *as well*, *a bit of*), divididas pelas bandas 1k–5k. Pela marcação de gênero da própria lista, separei as que dominam na **fala** (para A1–B1) e as que dominam no texto **acadêmico** (para C1). Ver §6 e o Apêndice B.
7. **Phrasal verbs:** a PHaVE List (Garnier & Schmitt 2015) traz **150 phrasal verbs e 288 sentidos**, que cobrem mais de 75% das ocorrências no COCA. Distribuí os 150 por nível, com o sentido principal em PT-BR (Apêndice A).
8. **Nível A0/A1:** o *Survival Syllabus* de Nation & Crabbe (cerca de 120 itens em 8 categorias) é a base com respaldo de pesquisa. Ele é inclusive o "A1" da tabela CEFR × vocabulário de Paul Nation. Expandi-o para **132 chunks com PT-BR** (§7).
9. **Trilha "inglês para desenvolvedores":** é paralela e começa a partir do A2. São 10 submódulos (daily, reuniões, code review, commits/issues, documentação, Slack, e-mail, entrevista, incidentes, pair/call), com cerca de 120 frases-modelo, uma tabela de polissemia de TI (bug, branch, issue…) e os falsos cognatos que mais atrapalham devs (*actually*, *eventually*, *push/puxar*, *support/suportar*, *realize/realizar*). Ver §9.
10. **Regra prática de licença:** **escrever 100% das frases do curso do zero**. As listas servem como *checklist* de seleção e ordenação. Só embutir no repositório dados com licença CC BY-SA/CC BY (família NGSL, PHaVE), com tela de créditos. Oxford, EVP, COCA, ACL e CSAVL ficam **apenas como referência de consulta** (§4).

---

## 1. Correções e esclarecimentos sobre o briefing

| Item do briefing | Situação real (verificada) | Fonte |
|---|---|---|
| "NGSL 2.0 (~2.800 palavras)" | **Não existe versão 2.0.** A vigente é a **NGSL 1.2**, lançada em abril de 2023, com **2.809 lemas**. Ela foi publicada em março de 2013 e atualizada em 2016 e 2023. Em 2024 saiu a **NGSL-GR 1.0** (Graded Reader), que estende a NGSL para 5.000 palavras. | [newgeneralservicelist.com/new-general-service-list](https://www.newgeneralservicelist.com/new-general-service-list) · [Wikipedia](https://en.wikipedia.org/wiki/New_General_Service_List) · [NGSL-GR](https://www.newgeneralservicelist.com/ngsl-graded-reader) |
| "NAWL" | **963 palavras**. Junto com a NGSL, cobre cerca de 92% de um corpus acadêmico de 288 milhões de palavras e cerca de 90% de 18 mil *abstracts*. Substitui a AWL de Coxhead (570 famílias). | [NAWL](https://www.newgeneralservicelist.com/new-academic-word-list) |
| "TSL" | **TOEIC Service List 1.2**: 1.200 palavras. Com a NGSL, chega a 98,5% de cobertura do TOEIC. | [TSL](https://newgeneralservicelist.com/toeic-service-list) |
| "BSL (negócios)" | **Business Service List 1.2**: 1.700 palavras. Com a NGSL, até 97% dos textos de negócios (corpus de 64 milhões de palavras). | [BSL](https://newgeneralservicelist.com/business-service-list) |
| "PHaVE List (150 phrasal verbs + sentidos)" | Confirmado: **150 PVs e 288 sentidos**. Cobre mais de 75% das ocorrências no COCA. Publicada em *Language Teaching Research* 19(6), 2015. | [Norbert Schmitt — recursos](https://www.norbertschmitt.co.uk/vocabulary-resources) · [PDF da lista](https://www.norbertschmitt.co.uk/_files/ugd/5f2482_fb2f15be0d104d08802d9ffd722e5782.pdf) |
| "PHRASE List (505 expressões)" | Confirmado: **505 expressões multipalavra não transparentes**, extraídas do BNC até a frequência das 5.000 palavras mais comuns. Ao processar o .doc oficial obtive 506 linhas, distribuídas assim: **32 (1k) · 84 (2k) · 129 (3k) · 158 (4k) · 103 (5k)**. Publicada em *Applied Linguistics* 33(3), 2012, pp. 299–320. | [lista .doc](https://www.norbertschmitt.co.uk/_files/ugd/5f2482_63c555de9e3f4c09af4170ba051b3bbe.doc) · [guia do usuário .doc](https://www.norbertschmitt.co.uk/_files/ugd/5f2482_6f9fe868fe7c46b38dac881fcef4148f.doc) |
| "Oxford 3000/5000 (com níveis CEFR)" | A Oxford 3000 revisada tem **900 palavras A1, 800 A2, 700 B1 e 600 B2**. A **Oxford 5000** acrescenta 2.000 palavras de nível B2–C1. Existe ainda a **Oxford Phrase List**: 750 frases de A1 a C1. | [Teaching English with Oxford](https://teachingenglishwithoxford.oup.com/2019/11/11/oxford-3000%EF%B8%8F-eltoc/amp) · [OLD wordlists](https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford3000-5000) |
| "Academic Collocation List" | **2.469 colocações** (algumas fontes dizem 2.468), extraídas do corpus PICAE da Pearson, com 25 milhões de palavras. Cobre cerca de 1,4% do inglês acadêmico e apenas 0,1% do inglês geral, ou seja, **é irrelevante antes do C1**. | [EAPFoundation — ACL](https://eapfoundation.com/vocab/academic/acl/) |

---

## 2. Números de cobertura: o que a pesquisa diz

### 2.1 A curva de Zipf, em números

- **Oxford English Corpus:** 10 lemas (*the, be, to, of, and, a, in, that, have, I*) = **25%** do corpus. 100 lemas = **50%**. 1.000 lemas = **75%**. ([Wikipedia — Most common words in English](https://en.wikipedia.org/wiki/Most_common_words_in_English))
- **NGSL 1.2:** 2.809 lemas dão "92%+" de cobertura do inglês geral. Por gênero: 93% em Harry Potter, 94% em provas do TOEIC e 95% em séries como *Friends*. ([NGSL](https://www.newgeneralservicelist.com/new-general-service-list))
- **NGSL-Spoken 1.2:** **721 lemas, cerca de 90% do inglês falado não roteirizado.** Histórico: a v1.0 tinha 822 palavras e 89%; a v1.1 tinha 718 e 90%; a v1.2 é de outubro de 2017. ([NGSL-Spoken](https://www.newgeneralservicelist.com/ngsl-spoken))
- **NGSL-GR 1.0 (2024):** 5.000 palavras com 98% de cobertura do inglês geral, divididas em **11 bandas: 8 bandas de 400 palavras e 3 de 600**. É a graduação mais fina disponível e pode virar a espinha das fases do curso. ([NGSL-GR](https://www.newgeneralservicelist.com/ngsl-graded-reader))

### 2.2 Curva calculada nesta pesquisa (arquivos oficiais da NGSL)

Baixei `NGSL_12_stats.csv` e `NGSL-Spoken_12_stats.csv` (licença CC BY-SA 4.0) e somei a coluna **U**, que é a frequência ajustada por milhão. Atenção: U é **ajustada por dispersão** e penaliza palavras concentradas em poucos textos. Por isso a soma fica *abaixo* dos números oficiais (85% contra 92% e 83% contra 90%). **Leia esta tabela pela forma da curva, não pelo valor absoluto.**

| Primeiros N lemas | NGSL (inglês geral, % de U) | NGSL-Spoken (fala, % de U) |
|---:|---:|---:|
| 10 | 29,0% | 29,8% |
| 50 | 48,1% | 54,5% |
| 100 | 55,4% | **64,2%** |
| 200 | 61,8% | 71,3% |
| 300 | 65,8% | **75,1%** |
| 500 | 70,9% | **79,7%** |
| 720/721 | 74,4% | 82,7% (lista inteira; oficial = 90%) |
| 1.000 | 77,5% | — |
| 1.500 | 81,0% | — |
| 2.000 | 83,2% | — |
| 2.809 | 85,4% (oficial = 92%) | — |

**Leitura para o design:** a fala é bem mais concentrada que a escrita. **Com 300 lemas da NGSL-Spoken a pessoa já reconhece cerca de três quartos das palavras de uma conversa.** Por isso o A1 deve sair da NGSL-**Spoken**, e não da NGSL geral nem da Oxford 3000, que é orientada a livro didático.

### 2.3 Nation (2006): quanto vocabulário para ouvir e ler

Fonte: Nation, I. S. P. (2006). *How large a vocabulary is needed for reading and listening?* Canadian Modern Language Review 63(1), 59–82. [PDF](https://www.wgtn.ac.nz/__data/assets/pdf_file/0018/1626120/2006-How-large-a-vocab.pdf). Os números abaixo usam **famílias de palavras** das listas BNC: base + flexões + derivações, como *teach, teaches, taught, teacher*. Uma família equivale a vários lemas.

**Fala espontânea (Wellington Corpus, Tabela 13):**

| Famílias | Talk-back/entrevista | Conversa entre amigos/família |
|---|---:|---:|
| 2.000 | 89,41% | 89,35% |
| 3.000 + nomes próprios | **96,52%** | **96,03%** |
| 6.000 + nomes próprios | 98,26% | 97,67% |
| 7.000 + nomes próprios | 98,62% | 97,95% |

**Filme (Shrek, Tabela 12):** 1.000 famílias = 81,5% (83,0% com nomes próprios). 2.000 = 86,4% (87,9%). 3.000 = 92,8% (94,3%). **4.000 = 95,3% (96,7%)**. 7.000 = 96,6% (98,1%).

**Escrita:** romances e jornais pedem cerca de **4.000 famílias + nomes próprios para 95%** e **8.000–9.000 para 98%**.

Conclusão de Nation: "*If 98% coverage of a text is needed for unassisted comprehension, then a 8,000 to 9,000 word-family vocabulary is needed for comprehension of written text and a vocabulary of 6,000 to 7,000 for spoken text.*" A replicação de Schmitt, Cobb, Horst & Schmitt (2015) resume esses números e recomenda testá-los em corpora maiores. ([PDF](https://www.lextutor.ca/cover/papers/schmitt_cobb_etal_2015.pdf), DOI 10.1017/S0261444815000075)

### 2.4 TV e cinema (Webb & Rodgers 2009)

- **TV** (88 programas): 3.000 famílias + nomes próprios + palavras marginais = **95,45%**. 7.000 famílias = **98,27%**.
- Dependendo do gênero, 95% de cobertura exige de 2.000 a 4.000 famílias e 98% exige de 5.000 a 9.000. Os números de filmes (2009a) são da mesma ordem. ([resumo secundário — Thai TESOL](https://so05.tci-thaijo.org/index.php/thaitesoljournal/article/download/266026/178362/1031283); Schmitt et al. 2015)

### 2.5 Limiares de compreensão

| Estudo | Limiar |
|---|---|
| Laufer (1989) | 95% de cobertura = compreensão de leitura "aceitável" |
| Hu & Nation (2000) | cerca de 98% para leitura independente de ficção |
| Laufer & Ravenhorst-Kalovski (2010) | 95% = mínimo; 98% = ótimo |
| **van Zeeland & Schmitt (2013)** | **na escuta, 95% de cobertura tende a bastar, e isso se alcança com 2.000–3.000 famílias.** Abaixo de 90% a compreensão fica instável. |
| Swanborn & de Glopper (1999) | inferir palavras novas pelo contexto funciona a partir de cerca de 1 palavra desconhecida em 37 (≈97%) |

(Todos resumidos em [Schmitt et al. 2015](https://www.lextutor.ca/cover/papers/schmitt_cobb_etal_2015.pdf).)

### 2.6 CEFR × tamanho de vocabulário

**Paul Nation**, no documento "Vocabulary, the CEFR levels, and word family size" ([docx](https://wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-lists/vocabulary-cefr-and-word-family-size/vocabulary-and-the-cefr-docx)):

| CEFR | Vocabulário sugerido (Nation) |
|---|---|
| A1 | **~120 palavras e frases do vocabulário de sobrevivência** (Nation & Crabbe 1991) |
| A2 | as **1.000 famílias** mais frequentes |
| B1 | as **2.000–3.000** palavras de alta frequência |
| B2 | **~4.000** (2.000–3.000 de alta frequência + **1.000–2.000 de vocabulário técnico relevante**), ≈ Oxford 3000 completo |
| C1 | 5.000–6.000 (≈ Oxford 5000) |
| C2 | 7.000–9.000 |

**Milton & Alexiou** (teste X-Lex, que vai até 5.000): A1 < 1.500 · A2 1.500–2.500 · B1 2.500 (ou 2.750)–3.250 · B2 3.250–3.750 · C1 3.750–4.500 · C2 4.500–5.000 ([Milton & Alexiou](https://www.enl.auth.gr/gala/14th/Papers/English%20papers/Milton&Alexiou.pdf)). Laufer (2020) sugere cerca de 4.000 palavras para o B1.

> Observação importante: o **B2 de Nation já inclui 1.000–2.000 palavras técnicas da área da pessoa**. Para o dono, que é dev, essa é a justificativa acadêmica para a trilha "inglês para desenvolvedores" (§9) contar como progresso real de nível, e não como extra.

### 2.7 Quanto da língua é formulaica

- **Erman & Warren (2000):** sequências pré-fabricadas são **58,6% da fala** e **52,3% da escrita** analisadas (*Text* 20(1); citado em [Diessel, Uni Jena](https://www.holgerdiessel.uni-jena.de/Grammar%20and%20Language%20Use%204.pdf)).
- **Biber et al. (1999, Longman Grammar):** *lexical bundles* de 3 ou 4 palavras (*I don't know if*, *do you want to*) são **28% da conversa** e 20% da prosa acadêmica.
- **Martinez & Schmitt (2012):** expressões como *take place* "podem causar problemas de decodificação se lidas palavra por palavra": o aluno conhece *take* e *place*, mas não *take place*. Esse é o critério de entrada na PHRASE List ([guia do usuário](https://www.norbertschmitt.co.uk/_files/ugd/5f2482_6f9fe868fe7c46b38dac881fcef4148f.doc)).
- Martinez & Murphy (2011, *TESOL Quarterly* 45(2)) mostraram que aprendizes **superestimam a própria compreensão** de textos cheios de expressões multipalavra *(referência da literatura; não reverificada on-line nesta sessão)*.

### 2.8 O que isso significa para o PAC·English

1. **A tradução em cima é exatamente o remédio para os chunks opacos.** O aluno vê "acontecer" e digita *take place*, "na verdade" e digita *in fact*, "deixa pra lá" e digita *never mind*. É o formato ideal para a PHRASE List.
2. **Faixa útil para o A1 = os 300–500 primeiros lemas da NGSL-Spoken + ~120 chunks de sobrevivência**, o que dá cerca de 75–80% dos tokens de conversa.
3. **Meta "B2 funcional" = ~3.000 famílias (NGSL inteira) + 400–700 termos técnicos + cerca de 500 chunks/phrasal verbs.** É o ponto em que, pelos dados de Nation (2006) e van Zeeland & Schmitt (2013), a pessoa passa de 95% de cobertura na fala.
4. **Regra de cobertura aplicada à frase:** como a tradução garante o significado, o limite de palavras novas é de **carga de memória**, não de compreensão. Recomendação: **no máximo 1 item novo (palavra ou chunk) por frase curta** (até ~10 palavras) e no máximo 2 nas frases longas. O resto da frase deve ser vocabulário já visto (≥90%).

---

## 3. Inventário das listas: ficha técnica e papel no curso

| Lista | Autores / ano | Tamanho | Cobertura declarada | Corpus | Papel recomendado no curso |
|---|---|---|---|---|---|
| **NGSL 1.2** | Browne, Culligan, Phillips · 2013/2016/2023 | 2.809 lemas | 92%+ do inglês geral | subcorpus de 273 milhões de palavras do Cambridge English Corpus | **espinha A2→B2** |
| **NGSL-Spoken 1.2** | Browne, Culligan · 2013–2017 | 721 lemas | ~90% da fala não roteirizada | 3 subseções faladas do corpus NGSL | **espinha A0→A2** (ordem de introdução das palavras) |
| **NGSL-GR 1.0** | Browne, Culligan · 2024 | 5.000 palavras | 98% do inglês geral | extensão da NGSL | **bandas finas para C1**; graduar textos/frases |
| NAWL 1.0 | Browne, Culligan, Phillips · 2013 | 963 | NGSL+NAWL ≈ 92% acadêmico | 288 milhões de palavras acadêmicas | C1, em seleção (leitura técnica/acadêmica) |
| BSL 1.2 | Browne, Culligan | 1.700 | NGSL+BSL ≈ 97% de negócios | 64 milhões de palavras de negócios | B2–C1: reuniões, e-mail, carreira |
| TSL 1.2 | Browne, Culligan | 1.200 | NGSL+TSL ≈ 98,5% do TOEIC | 1,5 milhão de palavras de material TOEIC | opcional (só se o dono quiser fazer TOEIC) |
| Oxford 3000 / 5000 | OUP · rev. 2019 | 3.000 / +2.000 | — | Oxford English Corpus (2 bilhões de palavras) + corpus de livros didáticos | **referência de nível CEFR** (consulta) |
| Oxford Phrase List | OUP | 750 frases A1–C1 | — | idem | referência de nível para chunks |
| English Vocabulary Profile | Cambridge · English Profile | ~7.000 *headwords* com sentidos, frases, PVs e idioms por CEFR | — | Cambridge Learner Corpus (50 milhões) + CEC (1,2 bilhão) | referência de nível (o que um aprendiz *de fato* usa em cada nível) |
| COCA top 5000 | Davies · wordfrequency.info | 5.000 lemas (versão gratuita) | — | COCA (1 bilhão de palavras, inglês americano) | conferência de frequência no inglês americano |
| SUBTLEX-US | Brysbaert & New · 2009 | 74.286 palavras | — | 51 milhões de palavras de legendas de filmes e séries dos EUA | conferência de **frequência falada americana** (Zipf 1–7) |
| **PHaVE List** | Garnier & Schmitt · 2015 | 150 PVs / 288 sentidos | 75%+ das ocorrências dos PVs (COCA) | COCA | **phrasal verbs, ordem e sentido** (Apêndice A) |
| **PHRASE List** | Martinez & Schmitt · 2012 | 505 expressões | até a frequência das 5.000 palavras do BNC | BNC (100 milhões de palavras) | **chunks, ordem por banda e por gênero** (Apêndice B) |
| Academic Collocation List | Ackermann & Chen · 2013 | 2.469 colocações | 1,4% do acadêmico | PICAE (25 milhões de palavras) | só C1 (escrita técnica formal) |
| **CSAVL** | Roesler · 2021 | 904 palavras + 702 técnicas (CSAVL-S) | com a NGSL ≈ 94,8% de textos acadêmicos de computação | 3,5 milhões de palavras (livros e artigos de computação) | **vocabulário técnico de TI**, inclusive palavras polissêmicas (*bug, port, tree, string, mouse*) |
| Survival Syllabus | Nation & Crabbe · 1991 | ~120 itens (~150 palavras), 8 categorias | — | análise de necessidades + guias de viagem + checagem de frequência | **A0 / A1** (base da §7) |

Detalhes que importam para o design:

- **NGSL-Spoken vs. NGSL geral.** O top 30 da fala é *be, the, you, and, it, to, a, have, of, do, not, that, they, we, in, he, know, get, go, so, this, but, on, I, for, think, like, there, will, say*. Já aparecem ***know, get, go, think, like, say*** e, logo depois, *yeah, mean, thing, really, want, actually, lot, sort, kind, bit, okay, probably, stuff, guess, whatever*. São marcadores de conversa que a lista geral empurra para baixo. O Apêndice C traz o top 300.
- **PHaVE.** Cada PV vem com os sentidos mais frequentes e a porcentagem de cada um. Exemplos: *go on* = "acontecer" (64,5%); *pick up* = "pegar/buscar" (70,5%); *find out* = "descobrir" (100%); *figure out* = "entender/descobrir" (100%). Isso permite ensinar **só o sentido principal** no A2/B1 e deixar os secundários para o B2.
- **PHRASE.** Cada item vem com estrelas por gênero (*spoken general*, *written general*, *written academic*). No Apêndice B, separei os itens "dominantes na fala", com três estrelas na fala e no máximo uma no acadêmico (para A1–B1), dos "dominantes no acadêmico" (para C1).
- **CSAVL.** Diferente das listas acadêmicas anteriores, ela **mantém palavras gerais com sentido técnico** (*bug, port, tree, string, mouse*). Esse é justamente o vocabulário que confunde dev brasileiro (§9.4).
- **Survival Syllabus.** As 8 categorias, na ordem de utilidade medida, são: (1) cumprimentos e cortesia; (2) compras e pechincha; (3) placas; (4) chegar a lugares; (5) hospedagem; (6) pedir comida; (7) falar de si; (8) controlar e aprender a língua. Os critérios, em ordem de importância, são: **necessidade > frequência > cobertura e combinabilidade > aprendibilidade**.

---

## 4. Licenças: o que dá para usar num app gratuito

> Isto não é parecer jurídico. É a leitura dos termos publicados por cada fonte, com uma regra prática conservadora.

| Fonte | Termos publicados | Embutir os dados no app/repositório? | Usar como referência de seleção? | Exigência |
|---|---|---|---|---|
| **NGSL, NGSL-Spoken, NGSL-GR, NAWL, BSL, TSL** | **CC BY-SA 4.0**. O site diz "*Free under Creative Commons, including commercial use*". | **Sim** | Sim | Atribuição (autores + link da licença). Se a **lista** for redistribuída modificada, ela sai sob a mesma licença. As frases originais do curso não são obra derivada da lista. |
| **PHaVE** | "*freely available for research and pedagogical purposes*". O artigo é CC BY 4.0 (segundo o [repositório do deck Anki](https://codeberg.org/Ema0408/PHaVE)). | Sim, a seleção de PVs e sentidos, com crédito. **Os exemplos devem ser reescritos.** | Sim | Crédito a Garnier & Schmitt (2015) |
| **PHRASE** | Download livre no site do autor. O artigo pertence a *Applied Linguistics*/OUP. | Usar os **itens** como checklist. **Não copiar exemplos nem a tabela inteira.** | Sim | Crédito a Martinez & Schmitt (2012) |
| Oxford 3000/5000/Phrase List | © Oxford University Press (proprietário) | **Não** | Sim (consultar o nível CEFR de uma palavra) | — |
| English Vocabulary Profile | © Cambridge, base de consulta on-line | **Não** | Sim | — |
| COCA top 5000 (wordfrequency.info) | Gratuito. "*If you re-post the list on the web, you must clearly indicate www.wordfrequency.info as the source*". Há varredura automática de cópias. Os termos para uso comercial em app não são explícitos. | **Não** (licença incerta) | Sim | Citar a fonte se publicar |
| SUBTLEX-US | Dado livre: "*must credit the SUBTLEX authors. It must remain clear that SUBTLEX is freely available data*" ([NOTICE do wordfreq](https://cdn.jsdelivr.net/npm/nodewordfreq@0.2.1/NOTICE.md)) | Possível, com crédito | Sim | Crédito a Brysbaert & New (2009) |
| Academic Collocation List | Pearson. A EAPFoundation permite reuso "educacional, não comercial" com atribuição. | Evitar | Sim | — |
| CSAVL | Artigo da Elsevier (JEAP). A EAPFoundation permite uso educacional não comercial. | Evitar | Sim | — |
| Survival Syllabus (Nation & Crabbe) | Artigo publicado em *System* (1991), PDF disponibilizado pelo autor | Não copiar o texto. Os itens são funções genéricas ("Where is…?") que qualquer curso tem. | Sim | Crédito na bibliografia |

**Regra prática recomendada:**

1. **Toda frase em inglês e toda tradução do curso são originais.** Nada de copiar exemplos de dicionário ou de lista.
2. **Palavras isoladas e fatos de frequência** ("*take place* é frequente") não são protegidos. Já uma **compilação** pode ser, quando a seleção e a organização são criativas. A Lei 9.610/98, art. 7º, XIII protege "coletâneas ou compilações… bases de dados" *(citado de memória; conferir)*. Por isso, só **embute a lista inteira** quando ela for CC BY-SA ou CC BY.
3. **Tela "Créditos e fontes"** no curso de inglês, citando NGSL (CC BY-SA 4.0), PHaVE, PHRASE, SUBTLEX e Nation & Crabbe.
4. O app ser **gratuito não o torna automaticamente "não comercial"** (anúncios ou uso como portfólio podem mudar isso). Por isso, a regra acima não depende disso.

---

## 5. Abordagem lexical (Lewis) e Survival Syllabus aplicados ao motor de digitação

### 5.1 Lewis (1993): "a língua é léxico gramaticalizado, não gramática lexicalizada"

Taxonomia de Lewis ([resenha TESL-EJ](https://www.cc.kyoto-su.ac.jp/information/tesl-ej/ej02/r.3.html); [EBSCO Research Starters](https://ebsco.com/research-starters/language-and-linguistics/lexical-approach)) e como cada tipo vira exercício:

| Tipo de chunk (Lewis) | Exemplos | Como vira exercício de digitação |
|---|---|---|
| **Polywords** (2–3 palavras fixas, incluindo phrasal verbs) | *by the way, of course, look for, find out* | Chunk em destaque dentro da frase. A tradução em cima marca o trecho correspondente ("**a propósito**, …"). |
| **Colocações** (fixas ou semilivres) | *make a decision, heavy traffic, fix a bug, run a test* | Série de 3–5 frases trocando o colocado: *fix a bug / fix the build / fix the tests*. |
| **Expressões institucionalizadas** (frases inteiras com função pragmática) | *Nice to meet you. · Never mind. · I'll get back to you.* | A frase inteira é o item, digitada várias vezes com contextos de diálogo diferentes. |
| **Molduras de frase (sentence frames/heads)** | *Sorry to interrupt, but… · Would you mind …ing? · I was wondering if…* | **Moldura fixa + slot variável.** Repete a moldura 4–6 vezes trocando o slot. É o melhor recurso para "escrever várias vezes sem tédio". |
| **Frases completas** | *I'll be in touch. · It works on my machine.* | Digitação literal com repetição espaçada. |

Princípios de Lewis que se traduzem em regras de produto:

- **Observar → hipotetizar → experimentar** (em vez de apresentar → praticar → produzir). Na prática: mostrar a frase com o chunk destacado antes de qualquer regra gramatical. A gramática aparece como nota curta depois ("*going to* = futuro planejado").
- **Gramática "parcial, provisória, pessoal".** Nada de aula de gramática antes da frase. A gramática vem embutida nas molduras.
- **Aquisição lenta e incremental** = reciclagem obrigatória (§10).

### 5.2 Nation & Crabbe (1991): lições para o A0

Fonte: [PDF do artigo](https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-lists/survival-vocabulary-lists/survival-korean.pdf). O que vale para o PAC·English:

1. **Retorno imediato.** O artigo critica cursos cujas primeiras lições são "This is a pen / The book is red". A lição 1 do curso deve ser algo **usável no mesmo dia** (cumprimentar, agradecer, pedir que repitam).
2. **Interferência (Higa 1963).** Agrupar sinônimos, opostos ou associados livres *atrapalha* a memorização. O artigo manda **não ensinar juntos** *exit/entrance, left/right, far/near, today/tomorrow, bus/train*, nem números em série antes de cada um estar firme. **No curso: os pares de opostos vão em lições diferentes e só depois se juntam numa revisão.** A §7 marca esses pares com **[par]**.
3. **Traduzir pela função, não pela forma.** "*Any translation… should work from the functional meanings of the expressions and not the literal meanings*". Para o curso: a linha PT-BR de cima deve dizer **o que um brasileiro diria naquela situação**. *How's it going?* vira "Tudo certo?", e não "Como está indo?".
4. **Números são prioridade e pedem fluência alta.** O artigo recomenda ditado de números repetido e cada vez mais rápido. Num motor de digitação isso é natural: uma **mini-trilha de números por extenso** (*twenty-five, nine ninety-nine, half past ten*).
5. **Recuperação ativa.** O artigo recomenda lembrar o item na L2 a partir da L1 (cartão PT → EN). Isso é exatamente o modo do curso (PT-BR em cima, digita EN). Para depois da primeira exposição, vale ter uma variante "com a dica esmaecida escondida" (assunto de outra frente).
6. **Tamanho viável.** Cerca de 120 itens (~150 palavras) cabem em menos de 60 horas segundo Pimsleur (1980), citado no artigo. É o tamanho certo para a "Fase 0".

### 5.3 Critérios de seleção e ordenação (síntese para quem escreve as lições)

Em ordem de prioridade:

1. **Necessidade do dono:** trabalho remoto com times estrangeiros, reuniões, leitura técnica, entrevistas, viagens.
2. **Frequência falada:** posição na NGSL-Spoken e, para conferência, Zipf no SUBTLEX-US.
3. **Cobertura e combinabilidade:** priorizar palavras-coringa (*thing, stuff, get, go, make, take, put, have, do, way*) e molduras que geram dezenas de frases (*Can I…? / Could you…? / I'd like… / Where is…? / How do I…?*).
4. **Aprendibilidade:** **cognatos primeiro** (ganho rápido) e **falsos cognatos sinalizados**. Evitar pares de interferência na mesma lição. Para hispanofalantes, mais de 400 das 570 famílias da AWL (~70%) são cognatas (Lubliner & Hiebert 2011, via [Frontiers in Education 2023](https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2023.1225169/full)). Para o português é razoável esperar proporção parecida, porque mais de 82% da AWL tem origem latina ou grega. **O vocabulário acadêmico e técnico é a parte mais fácil para um brasileiro.** O difícil é o vocabulário germânico curto do dia a dia (*get, put, take off, figure out*).

---

## 6. Proposta de faixas de vocabulário por nível

### 6.1 Visão geral

| Nível | Nome sugerido | Vocabulário acumulado | Chunks e expressões (acumulado) | Phrasal verbs (PHaVE) | Frases novas (estimativa) | Cobertura esperada (fala) |
|---|---|---|---|---|---|---|
| **0 (pré-A1)** | Sobrevivência | ~200 lemas (NGSL-Spoken 1–200 + números) | **~130** (§7) + números por extenso | 5–8 concretos | 150–200 | ~70% dos tokens (cálculo U) |
| **A1** | Primeiros passos | ~500–600 (NGSL-Spoken 1–500; conferir com Oxford A1) | +80 (PHRASE 1k "fala" + molduras A1) | ~15 (sentidos concretos) | ~600 | ~80% (U) |
| **A2** | Dia a dia | ~1.000–1.200 (NGSL-Spoken inteira + NGSL 1–1.000) | +150 (PHRASE 2k "fala") | ~50 (sentido principal) | ~900 | ~82–84% (Shrek 1k = 81,5%) |
| **B1** | Independente | ~2.000 (NGSL 1–2.000) | +200 (PHRASE 3k) | ~110 | ~1.100 | ~89% (Nation: 2k = 89,4%) |
| **B2** | Profissional | **~2.800 (NGSL inteira) + 400–700 técnicas/negócios** (CSAVL, BSL) | +250 (PHRASE 4k) | **150** (principal) + 2º sentido | ~1.200 | **95–96%** (limiar de escuta) |
| **C1** | Avançado | ~4.500–5.000 (NGSL-GR bandas 8–11 ≈ Oxford 5000) + NAWL em seleção | +250 (PHRASE 5k + acadêmicos + idioms + ACL em seleção) | 2º e 3º sentidos | ~1.000 | 96–98% |
| **Trilha Dev** (paralela, A2→C1) | Inglês para devs | ~500 termos (CSAVL + vocabulário de processo) | ~400 frases-modelo | PVs técnicos (*set up, roll back, figure out, rule out, follow up*) | 600–800 | — |

**Total:** cerca de **5.500 a 6.000 frases**. Como referência, o curso de Dart tem 2.354 exercícios. **MVP sugerido: Fase 0 + A1 + A2 ≈ 1.700 frases**, mais os primeiros submódulos da trilha Dev.

> As estimativas de cobertura vêm de §2.2 (cálculo U, que é um piso conservador) e §2.3 (Nation 2006, em famílias). Servem para comunicar progresso ao aluno, e não como promessa exata.

### 6.2 Detalhamento por nível

**Nível 0: Sobrevivência (pré-A1)**
- **Vocabulário:** os ~200 primeiros lemas da NGSL-Spoken, mais números (0–100, *hundred, thousand, million*), dias da semana e horas.
- **Chunks:** os 132 itens da §7, nas 8 categorias de Nation & Crabbe mais a ponte dev.
- **Gramática embutida:** *I'm / you're / it's*, *Can I…?*, *Do you have…?*, *Where is…?*, *I'd like…*, imperativo (*Turn left*).
- **Critério de conclusão:** digitar sem errar os 132 chunks a partir do PT-BR, com velocidade mínima. Pode servir de **teste de nivelamento rápido**: quem já sabe pula a fase.

**A1: Primeiros passos**
- **Vocabulário:** NGSL-Spoken 1–500. Conferir com a Oxford A1 (900 palavras) só para garantir que nada básico do material didático ficou de fora (cores, roupas, comida…).
- **Chunks (PHRASE 1k, dominantes na fala):** *have to, going to, of course, a few, a lot, a little, a bit (of), I mean, sort of, have got, so that, such a(n)*. *Used to* fica para o A2.
- **Phrasal verbs concretos e visíveis:** *get up [PV23], wake up [35], sit down [22], stand up [30], come in [14], go out [8], come back [3], go back [5], pick up [2], put on [87], take off (roupa) [28], turn off [106], write down [119], give back [128], go in [54]*.
- **Molduras:** *I like / I don't like · I can / I can't · Let's… · There is/are… · Is there a … near here? · What's your…? · I need…*

**A2: Dia a dia**
- **Vocabulário:** completar a NGSL-Spoken (721) e avançar na NGSL até ~1.000.
- **Chunks (PHRASE 2k, fala):** *each other, no one, look for, last night, work on, think about, too much, you see, a couple of, look like, all right, after all, on the way, as long as, ought to, about to, come on*, além de *used to* (passado).
- **PVs (sentido principal):** *find out [6], grow up [10], set up [11], get out [13], give up [16], get back [19], look up [20], take out [24], go down [26], go ahead [32], go up [33], check out [49], look around [52], get off [56], clean up [65], slow down [68], hang up [75], hold on [77], hang on [83], hang out [86], come over [89], move in [90], put back [96], get in [98], run out (of) [103], fill out [121], move out [131], get on (ônibus) [127]*.
- **Molduras:** *I'm going to… · I have to… · I used to… · Have you ever…? · I've never… · Could you…? · Would you like to…? · It's cheaper than… · What do you think about…? · I'm looking for…*

**B1: Independente**
- **Vocabulário:** NGSL 1.001–2.000. **Trilha Dev entra forte** (daily, Slack, issues, docs básicos).
- **Chunks (PHRASE 3k, fala):** *look after, get to, by the time, lots of, all the time, kind of, get into, go for, what about, in touch (with), in a way, or something, that's it, these days, feel like, heard of, have a look, believe in, move on, go away, oh well*, mais *used to (acostumado)*. Do grupo neutro: *turn out, end up, in other words, as for, in the end, point of view, in case*.
- **PVs:** *come up (with) [4], come out [7], point out [9], turn out [12], make up [17], end up [18], figure out [21], show up [27], work out [29], carry out [36], take over [37], take up [41], put up (with) [43], bring up [45], move on [50], catch up [53], break down [55], keep up [57], reach out [59], cut off [61], shut down [66], go over [74], go through [76], break up [80], build up [84], turn down [94], back up [95], carry on [100], keep on [102], stand out [111], sort out [136], follow up [137], fill in [141], give in [143], put off [146]*.
- **Molduras:** *I've been …ing for… · If I were you, I'd… · I should have… · It turned out that… · I ended up …ing · The thing is,… · What I mean is… · I'm not sure whether… · It depends on… · I'd rather … than … · As far as I know,… · I'm supposed to…*

**B2: Profissional**
- **Vocabulário:** NGSL 2.001–2.809 (fecha os 92%), mais **400–700 técnicas** (CSAVL para documentação e arquitetura, BSL para reuniões, contratos e carreira).
- **Chunks (PHRASE 4k, fala):** *hang on, turn into, by now, think so, go ahead, had better, come up with, no matter, some kind of, keep up, no idea, make sense, ever since, get on with, I'm afraid, right now, by the way, run out (of), on the one hand, first of all, might as well, mind you, as usual*. Do grupo neutro ou escrito: *in terms of, as a result, in the first place, in common, to some extent, in return, as opposed to, take advantage, bear in mind*.
- **PVs:** completar os 150 no sentido principal e acrescentar os 2º sentidos mais úteis: *work out* = "dar certo"; *come up* = "estar chegando"; *put up with*; *go through* = "revisar"; *back up* = "fazer backup/comprovar"; *roll back*, que não está na PHaVE mas é essencial em TI.
- **Molduras:** *On the one hand… on the other hand… · In terms of…, … · I'd push back on that because… · That makes sense, but… · The main trade-off is… · If we had…, we would have… · It's not that…, it's just that… · Not only… but also… · Would it be possible to…? · I was wondering if… · Let me walk you through…*

**C1: Avançado**
- **Vocabulário:** NGSL-GR bandas 8–11 (até 5.000) e NAWL em seleção, com foco na leitura de papers, RFCs e documentação de arquitetura.
- **Chunks:** PHRASE 5k (*when it comes to, in the meantime, take for granted, make use of, for the sake of, what if, no wonder, get away with, come to terms with*), mais os **itens acadêmicos de todas as bandas** (*in accordance with, in the light of, the extent to which, give rise to, by means of, in view of, with respect to, consistent with, contrary to, in conjunction with, provided that, at the expense of*) e uma **seleção da ACL** (*alternative approach, gain access, play a role, take into account, raise awareness*).
- **Idioms e coloquial:** *a piece of cake, the elephant in the room, low-hanging fruit, back to square one, cut corners, on the same page, ballpark figure*.
- **Molduras:** *It could be argued that… · To some extent,… · Given that…,… · Had we known…, we would have… · What concerns me most is… · It's worth bearing in mind that… · By no means… · No matter how…,… · Rather than …ing, we should…*

---

## 7. Os 132 chunks e frases prontas essenciais para iniciantes (com PT-BR)

> Uso: **Fase 0 / A1**. A coluna "PT-BR (em cima)" é a linha que aparece acima do texto. A coluna "Inglês (digitar)" é o alvo.
> **[par]** = par de interferência: ensinar em lições diferentes e juntar só na revisão (§5.2).
> Escolhas de digitação: frases **sem aspas duplas** (no US-International, `"` + vogal vira ë/ö…) e com **apóstrofo reto** (o motor deve aceitar também ’). Variante **americana** (§10.4).

### A. Cumprimentos e cortesia

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 1 | Hi! Hello! | Oi! Olá! | [S] |
| 2 | Good morning. | Bom dia. | [S] |
| 3 | Good afternoon. | Boa tarde. | [S] |
| 4 | Good evening. | Boa noite. (ao chegar) | [par] com 5. *Good night* só se usa na despedida. |
| 5 | Good night. | Boa noite. (ao se despedir / dormir) | [par] com 4 |
| 6 | How are you? | Como vai você? | [S] |
| 7 | I'm fine, thanks. And you? | Estou bem, obrigado. E você? | [S] |
| 8 | How's it going? | Tudo certo? Como vão as coisas? | informal |
| 9 | Not bad. | Nada mal. Tudo certo. | |
| 10 | Nice to meet you. | Prazer em conhecer você. | expressão institucionalizada |
| 11 | Nice to meet you too. | O prazer é meu. | tradução funcional |
| 12 | See you later. | Até mais. | |
| 13 | See you tomorrow. | Até amanhã. | |
| 14 | Bye! Have a nice day. | Tchau! Tenha um bom dia. | [S] |
| 15 | Thank you very much. | Muito obrigado. | [S] |
| 16 | Thanks a lot. | Valeu! Muito obrigado. | [P1k] *a lot* |
| 17 | You're welcome. | De nada. | [S] |
| 18 | No problem. | Sem problema. Imagina. | |
| 19 | Please. | Por favor. | [S] |
| 20 | Excuse me. | Com licença. | [S]. Serve para chamar atenção ou pedir passagem. |
| 21 | I'm sorry. | Desculpa. Sinto muito. | [S] |
| 22 | That's OK. Don't worry. | Tudo bem. Não se preocupe. | |
| 23 | It doesn't matter. | Não tem importância. | [S] |
| 24 | Can I take a photo? | Posso tirar uma foto? | [S] |

### B. Falar de si

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 25 | My name is Carlos. | Meu nome é Carlos. | [S] |
| 26 | What's your name? | Qual é o seu nome? | [S] |
| 27 | I'm from Brazil. | Eu sou do Brasil. | [S] |
| 28 | Where are you from? | De onde você é? | [S] |
| 29 | I live in Rio. | Eu moro no Rio. | evita "São" (til) no alvo |
| 30 | I'm a software developer. | Eu sou desenvolvedor de software. | [S] *I am a (teacher)* |
| 31 | What do you do? | Com o que você trabalha? | [S]. Tradução funcional. |
| 32 | I work from home. | Eu trabalho de casa. | |
| 33 | I'm thirty-five years old. | Eu tenho trinta e cinco anos. | [S]. Idade com *be*, não com *have*. |
| 34 | How old are you? | Quantos anos você tem? | [S] |
| 35 | I have two kids. | Eu tenho dois filhos. | |
| 36 | I've been here for three days. | Estou aqui há três dias. | [S]. Primeiro contato com o *present perfect*. |
| 37 | I like music. | Eu gosto de música. | sem "of" |
| 38 | I don't like coffee. | Eu não gosto de café. | |
| 39 | I'm learning English. | Estou aprendendo inglês. | |
| 40 | I speak a little English. | Eu falo um pouco de inglês. | [S] [P1k] *a little* |

### C. Controlar a conversa e aprender a língua

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 41 | Sorry? | Como? Perdão? (não ouvi) | |
| 42 | I don't understand. | Não entendi. | [S] |
| 43 | Got it. | Entendi. | |
| 44 | Can you repeat that, please? | Você pode repetir, por favor? | [S] |
| 45 | Could you speak more slowly, please? | Você poderia falar mais devagar, por favor? | [S] |
| 46 | What does that mean? | O que isso significa? | |
| 47 | How do you say saudade in English? | Como se diz saudade em inglês? | [S]. Sem aspas. |
| 48 | How do you spell it? | Como se escreve? | |
| 49 | Do you speak Portuguese? | Você fala português? | [S] |
| 50 | I don't know. | Eu não sei. | |
| 51 | I mean, it's not easy. | Quer dizer, não é fácil. | [P1k] *I mean* (fala) |
| 52 | Let me think. | Deixa eu pensar. | |
| 53 | Just a second, please. | Só um segundo, por favor. | frase curta (Lewis) |
| 54 | What do you mean? | Como assim? | tradução funcional |
| 55 | Is that right? | É isso mesmo? | |
| 56 | Can you write it down, please? | Você pode anotar isso, por favor? | [PV119] |
| 57 | One more time, please. | Mais uma vez, por favor. | |
| 58 | I have a question. | Eu tenho uma pergunta. | |

### D. Compras e dinheiro

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 59 | How much is this? | Quanto custa isto? | [S] |
| 60 | Do you have this in blue? | Você tem este em azul? | [S] *Do you have…?* |
| 61 | I'd like this one, please. | Eu queria este, por favor. | [S] *I want…* (*I'd like* é a forma educada) |
| 62 | It's too expensive. | Está caro demais. | [S] |
| 63 | Do you have anything cheaper? | Você tem algo mais barato? | [S] |
| 64 | Can I pay by card? | Posso pagar com cartão? | |
| 65 | I'm just looking, thanks. | Só estou olhando, obrigado. | |
| 66 | I'll take it. | Vou levar. | |
| 67 | Can I have a receipt, please? | Pode me dar o recibo, por favor? | |
| 68 | Is there a discount? | Tem desconto? | [S] *Can you lower the price?* |
| 69 | One more, please. | Mais um, por favor. | [S] |
| 70 | That's all, thanks. | É só isso, obrigado. | |

### E. Comida

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 71 | A table for two, please. | Uma mesa para dois, por favor. | |
| 72 | Can I see the menu, please? | Posso ver o cardápio, por favor? | |
| 73 | I'd like a coffee, please. | Eu queria um café, por favor. | [S] |
| 74 | Can I have some water, please? | Pode me trazer uma água, por favor? | |
| 75 | What do you recommend? | O que você recomenda? | |
| 76 | I'm allergic to peanuts. | Sou alérgico a amendoim. | |
| 77 | It's delicious! | Está delicioso! | [S] |
| 78 | Can I have the check, please? | Pode trazer a conta, por favor? | [S]. EUA: *check*; Reino Unido: *bill*. |
| 79 | For here or to go? | Para comer aqui ou para viagem? | |
| 80 | To go, please. | Para viagem, por favor. | |
| 81 | I'm a vegetarian. | Sou vegetariano. | |

### F. Como chegar a lugares

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 82 | Where's the restroom? | Onde fica o banheiro? | [S]. EUA: *restroom/bathroom*; Reino Unido: *toilet*. |
| 83 | Where is the train station? | Onde fica a estação de trem? | [S] |
| 84 | Can you help me? | Você pode me ajudar? | [S] |
| 85 | Is it far from here? | É longe daqui? | [S] [par] com 86 |
| 86 | Is it near here? | É perto daqui? | [S] [par] com 85 |
| 87 | How long does it take? | Quanto tempo leva? | [S] |
| 88 | Turn left at the corner. | Vire à esquerda na esquina. | [S] [par] com 89 |
| 89 | Turn right after the bank. | Vire à direita depois do banco. | [S] [par] com 88 |
| 90 | Go straight ahead. | Siga em frente. | [S] |
| 91 | Stop here, please. | Pare aqui, por favor. | [S] |
| 92 | A ticket to Boston, please. | Uma passagem para Boston, por favor. | [S] |
| 93 | What time does it leave? | Que horas sai? | [S] |
| 94 | I'm lost. | Estou perdido. | |
| 95 | How do I get to the airport? | Como eu chego ao aeroporto? | moldura *How do I…?* |

### G. Hospedagem e serviços

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 96 | I have a reservation. | Eu tenho uma reserva. | [S] |
| 97 | I'd like to check in, please. | Eu queria fazer o check-in, por favor. | |
| 98 | What time is checkout? | Que horas é o check-out? | |
| 99 | What's the Wi-Fi password? | Qual é a senha do Wi-Fi? | |
| 100 | It doesn't work. | Não funciona. | serve para hotel e para código |

### H. Saúde e emergência

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 101 | I need help. | Eu preciso de ajuda. | |
| 102 | I don't feel well. | Não estou me sentindo bem. | [S] *I am sick* |
| 103 | I need a doctor. | Eu preciso de um médico. | [S] |
| 104 | Call the police! | Chame a polícia! | [S] |

### I. Tempo e planos

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 105 | What time is it? | Que horas são? | |
| 106 | It's half past ten. | São dez e meia. | [P4k] *half past* |
| 107 | I have to go now. | Eu tenho que ir agora. | [P1k] *have to* (o chunk nº 1 da lista) |
| 108 | I'm going to call you later. | Vou te ligar mais tarde. | [P1k] *going to* |
| 109 | See you on Monday. | Até segunda. | |
| 110 | Right now? | Agora mesmo? | [P4k] |
| 111 | Not at the moment. | No momento, não. | [P2k] |
| 112 | Last night I worked late. | Ontem à noite eu trabalhei até tarde. | [P2k] *last night* |
| 113 | Maybe next week. | Talvez semana que vem. | |
| 114 | At least once a week. | Pelo menos uma vez por semana. | [P1k] *at least* |

### J. Opinião e reação

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 115 | I think so. | Acho que sim. | [P4k] [par] com 116 |
| 116 | I don't think so. | Acho que não. | [par] com 115 |
| 117 | I agree. | Concordo. | |
| 118 | Me too. | Eu também. | *Me neither* = "eu também não", em outra lição |
| 119 | Really? | Sério? | |
| 120 | That's great! | Que ótimo! | |
| 121 | Good idea. | Boa ideia. | |
| 122 | It depends. | Depende. | |
| 123 | Of course. | Claro. | [P1k] |
| 124 | Never mind. | Deixa pra lá. | [P5k], domina na fala |
| 125 | How about tomorrow? | Que tal amanhã? | [P5k] |
| 126 | By the way, I'm on vacation next week. | A propósito, estou de férias semana que vem. | [P4k] *by the way* |

### K. Ponte para a trilha Dev (A1)

| # | Inglês (digitar) | PT-BR (em cima) | Nota / fonte |
|---|---|---|---|
| 127 | Can you hear me? | Você está me ouvindo? | |
| 128 | You're on mute. | Você está no mudo. | |
| 129 | Can you see my screen? | Você consegue ver minha tela? | |
| 130 | I'm working on the login page. | Estou trabalhando na página de login. | [P2k] *work on* |
| 131 | I'll get back to you. | Te dou um retorno. | [PV19] *get back* |
| 132 | It works on my machine. | Na minha máquina funciona. | humor dev, alta memorabilidade |

### Mini-trilha de números (Nation & Crabbe: "fluência alta")

Digitar por extenso, com a forma numérica em cima:

- `zero … twenty`, `thirty, forty, fifty`, `a hundred`, `a thousand`, `a million`;
- compostos com hífen: `twenty-one`, `ninety-nine`;
- **preços**: `It's nine ninety-nine.` (em cima: "Custa 9,99.");
- **horas**: `It's a quarter to five.` / `It's half past ten.`;
- **datas**: `October fourth` / `on the fourth of October`;
- **telefone**: `It's five five five, one two three four.`;
- **versões e TI**: `version two point one`, `ten percent`, `forty gigabytes`.

---

## 8. Temas e campos lexicais por nível

| Nível | Temas / campos lexicais | Exemplos de itens | Molduras típicas |
|---|---|---|---|
| **0** | cumprimentos · cortesia · apresentar-se · números · horas · compras · comida · direções · hotel · emergência · controlar a conversa | *hello, thanks, please, sorry, how much, where, left, right, ticket, check, menu, help* | *Can I…? · Do you have…? · Where is…? · I'd like…* |
| **A1** | eu e minha família · rotina diária · casa · comida e bebida · tempo e clima · dias, meses e datas · roupas e cores · lugares na cidade · transporte · gostos · habilidades · trabalho básico · tecnologia do dia a dia | *get up, have breakfast, go to work, kitchen, rain, Monday, shirt, bus, I can swim, laptop, password, email, app, download* | *I usually… · I like / I don't like… · I can / can't… · There is/are… · Let's…* |
| **A2** | passado (fim de semana, viagens) · planos · compras e serviços · saúde e corpo · comparações · descrever pessoas e lugares · escritório · telefone e videochamada · convites e combinados · experiências · problemas simples | *went, bought, headache, cheaper, better, tall, quiet, meeting, call, invite, Have you ever…?, it's broken, I lost my…* | *I'm going to… · I have to… · I used to… · Have you ever…? · Could you…? · Would you like to…?* |
| **B1** | opinião, acordo e desacordo · contar histórias · sentimentos · trabalho e carreira · estudo · internet e tecnologia · notícias · meio ambiente (básico) · problemas em viagens · conselhos e hipóteses · **Dev: daily, Slack, issues, README** | *I agree / I'm not sure, suddenly, it turned out, frustrated, promotion, course, update, news, recycle, delayed flight, you should* | *I've been …ing for… · If I were you… · It turned out that… · I ended up… · The thing is…* |
| **B2** | argumentação · negociação · reuniões · dar e receber feedback · hipóteses no passado · mídia e cultura · negócios (BSL) · ciência e saúde · **Dev: code review, design de sistemas, entrevistas, incidentes** | *on the other hand, in terms of, as a result, deadline, budget, stakeholder, feedback, would have, trade-off, scalability, root cause* | *On the one hand… · In terms of… · I'd push back on… · Would it be possible to…? · Let me walk you through…* |
| **C1** | nuance e *hedging* · idioms · registro formal e acadêmico (NAWL, ACL) · apresentação e persuasão · escrita longa (RFC, ADR, proposta) · liderança e mentoria · economia e política · humor e coloquialismo | *arguably, to some extent, the extent to which, give rise to, play a role, low-hanging fruit, mentor, consensus* | *It could be argued that… · Given that… · Had we known… · What concerns me most is…* |

---

## 9. Bloco "inglês para desenvolvedores"

### 9.1 Por que uma trilha própria

- O B2 de Nation inclui de 1.000 a 2.000 palavras **técnicas da área da pessoa** (§2.6). A trilha Dev **é** o B2 profissional do dono.
- Fontes primárias de processo e estilo: [Scrum Guide](https://scrumguides.org/scrum-guide.html) (Sprint, Sprint Planning, Daily Scrum de 15 minutos, Review, Retrospective, Product/Sprint Backlog, Increment, Definition of Done); [Google Engineering Practices — comentários de code review](https://google.github.io/eng-practices/review/reviewer/comments.html) (cortesia, explicar o porquê, prefixos **Nit: / Optional: / FYI:**); [Conventional Comments](https://conventionalcomments.org/) (rótulos *praise, nitpick, suggestion, issue, todo, question, thought, chore, note* e decorações *(blocking), (non-blocking), (if-minor)*).
- Vocabulário técnico acadêmico: CSAVL (Roesler 2021; [EAPFoundation](https://eapfoundation.com/vocab/academic/other/csavl); [PDXScholar](https://pdxscholar.library.pdx.edu/ling_fac/72)).
- Frases de stand-up e reunião corporativa (*blocker, circle back, take it offline, touch base, loop in*): [llexi](https://llexi.com/business-english/english-team-stand-ups-daily-scrum/) e [TalkDrill](https://www.talkdrill.com/blog/vocabulary/tech/it-tech-english-vocabulary/), usadas como fontes secundárias.

### 9.2 Mapa dos submódulos

| # | Submódulo | Nível de entrada | Foco lexical |
|---|---|---|---|
| D1 | Calls e pair programming | A2 | tela, áudio, navegação no código |
| D2 | Daily/stand-up | A2 | passado simples, *going to*, *blocked* |
| D3 | Slack e chat assíncrono | A2 | abreviações, cortesia curta |
| D4 | Commits, issues e bug reports | A2/B1 | imperativo, *expected/actual*, *repro* |
| D5 | Documentação e README | B1 | instruções, *make sure*, *deprecated* |
| D6 | E-mail profissional | B1 | aberturas e fechamentos, *follow up*, *attached* |
| D7 | Reuniões (planning, refinement, retro, 1:1) | B1/B2 | esclarecer, discordar, estimar |
| D8 | Code review e pull requests | B1/B2 | sugestão educada, severidade |
| D9 | Incidentes, on-call e postmortem | B2 | *outage, rollback, root cause* |
| D10 | Entrevista de emprego | B1→C1 | apresentação, STAR, live coding, perguntas |

### 9.3 Frases-modelo por submódulo (EN para digitar · PT-BR em cima)

**D1: Calls e pair programming (A2)**

| Inglês | PT-BR |
|---|---|
| Can you see my screen? | Você consegue ver minha tela? |
| You're on mute. | Você está no mudo. |
| Let me share my screen. | Deixa eu compartilhar minha tela. |
| Can you zoom in a bit? | Pode dar um zoom? |
| Can you scroll up a little? | Pode rolar um pouco para cima? |
| Sorry, you cut out for a second. | Desculpa, sua voz cortou por um segundo. |
| My internet is a bit unstable today. | Minha internet está meio instável hoje. |
| Do you want to drive? | Você quer pilotar? (no pair programming) |
| Let me walk you through the code. | Deixa eu te mostrar o código passo a passo. |
| Let's take a five-minute break. | Vamos fazer uma pausa de cinco minutos. |

**D2: Daily/stand-up (A2)**

| Inglês | PT-BR |
|---|---|
| Yesterday I worked on the login screen. | Ontem eu trabalhei na tela de login. |
| Today I'm going to finish the payment integration. | Hoje vou terminar a integração de pagamento. |
| I'm still working on the bug from yesterday. | Ainda estou trabalhando no bug de ontem. |
| No blockers on my side. | Sem impedimentos da minha parte. |
| I'm blocked by the API changes. | Estou travado por causa das mudanças na API. |
| I need some help with the database migration. | Preciso de ajuda com a migração do banco. |
| It should be ready by the end of the day. | Deve ficar pronto até o fim do dia. |
| I'll pair with Ana on this after the meeting. | Vou parear com a Ana nisso depois da reunião. |
| I opened a pull request, and it's ready for review. | Abri um pull request e ele está pronto para revisão. |
| That's it from me. | É isso da minha parte. |

**D3: Slack e chat (A2/B1)**

| Inglês | PT-BR |
|---|---|
| Quick question: where are the API keys? | Pergunta rápida: onde ficam as chaves da API? |
| Any updates on this? | Alguma novidade sobre isso? |
| Heads-up: staging will be down at three. | Aviso: o staging vai ficar fora do ar às três. |
| Thanks for the heads-up! | Valeu pelo aviso! |
| Sounds good! | Fechado! |
| No worries. | Tranquilo, sem problemas. |
| Sorry for the late reply. | Desculpa a demora para responder. |
| I'll ping you when it's done. | Te dou um toque quando terminar. |
| Can we jump on a quick call? | Podemos fazer uma chamada rápida? |
| FYI, the deploy is done. | Para sua informação, o deploy terminou. |
| I'm out of office tomorrow. | Amanhã estou fora. |
| Feel free to reach out if you have any questions. | Fique à vontade para me chamar se tiver dúvidas. |

**D4: Commits, issues e bug reports (A2/B1)**

Mensagens de commit vão no **imperativo** (*Fix*, *Add*). Em PT-BR a convenção costuma ser a 3ª pessoa ("Corrige"), e vale explicar essa diferença.

| Inglês | PT-BR |
|---|---|
| Fix crash when the user has no photo. | Corrige crash quando o usuário não tem foto. |
| Add unit tests for the cart service. | Adiciona testes unitários ao serviço do carrinho. |
| Remove unused imports. | Remove imports não usados. |
| Refactor the login flow. | Refatora o fluxo de login. |
| Bump the version to two point one. | Sobe a versão para 2.1. |
| Steps to reproduce: | Passos para reproduzir: |
| Expected behavior: the page should load. | Comportamento esperado: a página deveria carregar. |
| Actual behavior: the app freezes. | Comportamento real: o app trava. (*actual* = real, não "atual") |
| I can't reproduce it on my machine. | Não consigo reproduzir na minha máquina. |
| This test is flaky. | Este teste é instável (às vezes falha). |
| It looks like a regression from the last release. | Parece uma regressão da última versão. |
| As a workaround, you can clear the cache. | Como paliativo, você pode limpar o cache. |

**D5: Documentação e README (B1)**

| Inglês | PT-BR |
|---|---|
| Getting started | Primeiros passos |
| Prerequisites | Pré-requisitos |
| Install the dependencies. | Instale as dependências. |
| Run the following command. | Execute o seguinte comando. |
| Make sure that Flutter is installed. | Certifique-se de que o Flutter está instalado. |
| This method is deprecated and will be removed in the next major version. | Este método está obsoleto e será removido na próxima versão principal. |
| This is a breaking change. | Esta é uma mudança incompatível. |
| It works out of the box. | Funciona sem configuração extra. |
| Under the hood, it uses a local cache. | Por baixo dos panos, usa um cache local. |
| Returns null if the user is not found. | Retorna null se o usuário não for encontrado. |
| Defaults to false. | O padrão é false. |
| See the section below for more details. | Veja a seção abaixo para mais detalhes. |

**D6: E-mail profissional (B1/B2)**

| Inglês | PT-BR |
|---|---|
| Hi Sarah, I hope you're doing well. | Oi Sarah, espero que você esteja bem. |
| I'm writing to ask about the project timeline. | Estou escrevendo para perguntar sobre o cronograma do projeto. |
| Just following up on my last email. | Só retomando meu último e-mail. |
| Please find the report attached. | Segue o relatório em anexo. |
| Could you please confirm by Friday? | Você poderia confirmar até sexta? |
| Let me know if you have any questions. | Me avise se tiver alguma dúvida. |
| Thank you for your quick response. | Obrigado pela resposta rápida. |
| I'm afraid we won't be able to meet the deadline. | Infelizmente não vamos conseguir cumprir o prazo. ([P4k] *I'm afraid*) |
| Looking forward to hearing from you. | Aguardo seu retorno. |
| Best regards, | Atenciosamente, |

**D7: Reuniões (B1/B2)**

| Inglês | PT-BR |
|---|---|
| Let's get started. | Vamos começar. |
| Just to clarify, are we talking about the mobile app? | Só para esclarecer: estamos falando do app mobile? |
| Could you elaborate on that? | Você poderia detalhar isso? |
| I'm not sure I follow. | Não sei se acompanhei. |
| I see your point, but I think we should keep it simple. | Entendo seu ponto, mas acho que devemos manter simples. |
| What's the trade-off here? | Qual é o custo-benefício aqui? |
| How long do you think it will take? | Quanto tempo você acha que vai levar? |
| Sorry to interrupt, but we're running out of time. | Desculpe interromper, mas o tempo está acabando. ([PV103] *run out*) |
| Let's take this offline. | Vamos tratar disso fora da reunião. |
| Let's circle back to this next week. | Vamos retomar isso semana que vem. |
| Who's going to own this? | Quem vai ficar responsável por isso? |
| Let's recap the action items. | Vamos recapitular os próximos passos. |

**D8: Code review e pull requests (B1/B2)**

| Inglês | PT-BR |
|---|---|
| LGTM, thanks! | Parece bom para mim, obrigado! (*looks good to me*) |
| Nit: there's a typo in this variable name. | Detalhe: tem um erro de digitação no nome desta variável. |
| Could you add a test for this edge case? | Você poderia adicionar um teste para este caso de borda? |
| Consider extracting this into a separate function. | Considere extrair isso para uma função separada. |
| This might cause a race condition. | Isso pode causar uma condição de corrida. |
| I'm not sure this handles null values. | Não tenho certeza se isso trata valores nulos. |
| Why did we choose this approach over the other one? | Por que escolhemos esta abordagem em vez da outra? |
| Suggestion (non-blocking): we could cache this result. | Sugestão (não bloqueante): poderíamos cachear este resultado. |
| Nice catch! | Bem observado! |
| Good point, I'll fix it. | Bom ponto, vou corrigir. |
| Addressed in the latest commit. | Resolvido no último commit. |
| Could you take another look? | Pode dar mais uma olhada? (PTAL) |

**D9: Incidentes, on-call e postmortem (B2)**

| Inglês | PT-BR |
|---|---|
| The production server is down. | O servidor de produção caiu. |
| We're looking into it. | Estamos investigando. |
| We rolled back the last deploy. | Revertemos o último deploy. |
| We need a hotfix. | Precisamos de uma correção urgente. |
| We ruled out the network. | Descartamos a rede. ([PV123] *rule out*) |
| The root cause was a missing index. | A causa raiz foi um índice faltando. |
| The issue only affects a small number of users. | O problema afeta só um pequeno número de usuários. ([P1k] *a number of*) |
| I'm on call this week. | Estou de plantão esta semana. |
| Let's write a blameless postmortem. | Vamos escrever um postmortem sem caça às bruxas. |
| We'll follow up with a permanent fix. | Vamos dar seguimento com uma correção definitiva. ([PV137] *follow up*) |

**D10: Entrevista de emprego (B1 → C1)**

| Inglês | PT-BR |
|---|---|
| Tell me about yourself. | Fale sobre você. |
| I've been working as a software developer for eight years. | Trabalho como desenvolvedor de software há oito anos. |
| I'm currently working on a Flutter app. | Atualmente estou trabalhando num app Flutter. (*currently*, não *actually*) |
| I'm really interested in this role because I enjoy building products. | Tenho muito interesse nesta vaga porque gosto de construir produtos. |
| One of my strengths is breaking down complex problems. | Um dos meus pontos fortes é destrinchar problemas complexos. ([PV55] *break down*) |
| In my last project, I was responsible for the payment system. | No meu último projeto, eu era responsável pelo sistema de pagamento. |
| The situation was that our app was crashing on older phones. | A situação era que nosso app travava em celulares antigos. (STAR: *Situation*) |
| As a result, crashes went down by eighty percent. | Como resultado, os crashes caíram oitenta por cento. (STAR: *Result*; [P2k] *as a result*; [PV26] *go down*) |
| Let me think out loud. | Deixa eu pensar em voz alta. |
| I'd start with a simple solution and then optimize it. | Eu começaria com uma solução simples e depois otimizaria. |
| What's the time complexity of this solution? | Qual é a complexidade de tempo desta solução? |
| Could you tell me more about the team? | Você pode me contar mais sobre o time? |
| What does a typical day look like? | Como é um dia típico? |
| What are the next steps in the process? | Quais são os próximos passos do processo? |

### 9.4 Palavras de TI polissêmicas

São o "vocabulário geral com sentido técnico" que a CSAVL faz questão de manter. Ensinar **os dois sentidos**, em frases diferentes.

| Palavra | Sentido geral | Sentido em TI |
|---|---|---|
| bug | inseto | defeito no código |
| port | porto | porta (rede); portar código |
| tree | árvore | árvore (estrutura de dados) |
| string | barbante, corda | cadeia de caracteres |
| thread | linha, fio; tópico de conversa | thread de execução; tópico no Slack |
| branch | galho; filial | ramo (git) |
| fork | garfo; bifurcação | cópia de repositório |
| merge | fundir (empresas) | mesclar |
| commit | comprometer-se | registrar alteração |
| pull / push | puxar / **empurrar** | baixar / enviar (git) |
| issue | questão; edição (revista) | tarefa ou problema registrado |
| ticket | ingresso; multa | chamado |
| shell | concha | terminal |
| release | soltar, libertar | versão, lançamento |
| ship | navio; enviar | entregar ou lançar (*ship a feature*) |
| deploy | posicionar tropas | implantar |
| scope | alcance | escopo |
| argument | discussão, briga; argumento | argumento ou parâmetro de função |
| handle | maçaneta; lidar com | tratar (*handle errors*); identificador |
| raise / throw / catch | levantar / jogar / pegar | lançar / lançar / capturar (exceção) |
| spike | pico; espinho | investigação curta (ágil) |
| backlog | acúmulo | lista priorizada de trabalho |
| sprint | corrida curta | iteração do Scrum |
| stand-up | de pé; comediante | reunião diária |
| library | biblioteca | biblioteca de código (cognato verdadeiro) |

### 9.5 Falsos cognatos que mais atrapalham devs brasileiros

Fontes: [Migaku](https://migaku.com/blog/language-fun/portuguese-false-friends), [Glossika](https://blog.glossika.com/blog/false-friends-between-portuguese-and-english) e experiência de ensino. Cada um merece **um par de frases contrastivas**, em lições separadas.

| Inglês | Significa | Não confundir com (PT) | Em inglês, "isso" se diz |
|---|---|---|---|
| **actually** | na verdade | atualmente | *currently, nowadays* |
| **eventually** | por fim, mais cedo ou mais tarde (daí *eventual consistency*) | eventualmente | *occasionally, possibly* |
| **pretend** | fingir | pretender | *intend, plan to* |
| **push** | empurrar (git: enviar) | puxar | *pull* |
| **realize** | perceber | realizar | *carry out [PV36], accomplish* |
| **support** | apoiar, dar suporte | suportar (aguentar) | *put up with [PV43], stand* |
| **assist** | ajudar | assistir | *watch, attend* |
| **attend** | comparecer | atender | *answer (phone), serve* |
| **resume** | retomar | resumo | *summary* (currículo = *résumé/CV*) |
| **legend** | lenda | legenda | *subtitles, caption* |
| **data** | dados | data | *date* |
| **lunch** | almoço | lanche | *snack* |
| **parents** | pais | parentes | *relatives* |
| **college** | faculdade | colégio | *high school* |
| **library** | biblioteca | livraria | *bookstore* |
| **novel** | romance (livro) | novela | *soap opera* |
| **exquisite** | requintado | esquisito | *weird, strange* |
| **sensible** | sensato | sensível | *sensitive* |
| **comprehensive** | abrangente | compreensivo | *understanding* |
| **costume** | fantasia | costume | *habit, custom* |
| **fabric** | tecido | fábrica | *factory* |
| **policy** | política, diretriz | polícia | *police* |

### 9.6 Abreviações de trabalho remoto

Ensinar digitando a **forma completa e depois a sigla**, por exemplo: *For your information → FYI*.

FYI · ASAP · EOD/EOW (*end of day/week*) · OOO (*out of office*) · PTO (*paid time off*) · LGTM · PTAL (*please take a look*) · WIP · TL;DR · IMO/IMHO · AFAIK · IIRC · BTW · ETA · TBD · N/A · nit · PR/MR · repo · env · prod · CI/CD · MVP · POC · SLA · RFC · ADR · 1:1.

---

## 10. Ordem e mecânica dentro de cada nível (recomendações práticas)

### 10.1 Unidade e progressão

- **Unidade = frase com 1 item em foco** (palavra, colocação, phrasal verb ou moldura). O foco aparece destacado no inglês e o trecho correspondente aparece destacado no PT-BR de cima.
- **Bloco de lição = 1 moldura ou 1 tema** com 8 a 12 frases. Exemplo: *I'd like…* com café, água, a conta, este, uma mesa…
- **Ordem dentro da lição:** frase-modelo, depois variações do slot, depois a frase "de verdade" do contexto do dono (trabalho remoto ou dev).

### 10.2 Reciclagem (o "escrever várias vezes" do pedido)

- Cada item novo aparece em **pelo menos 3 frases diferentes** dentro da lição e volta depois em revisões espaçadas. Webb (2007, *Applied Linguistics*) encontrou ganhos substanciais com cerca de 10 encontros com a palavra *(referência da literatura; não reverificada on-line nesta sessão)*.
- **Repetição com variação > repetição idêntica.** A mesma moldura com slots diferentes mantém o contexto e evita o piloto automático.
- **Interferência:** opostos, sinônimos e associados (*left/right, buy/sell, borrow/lend, say/tell, make/do*) **nunca na mesma lição de introdução**. Eles se juntam só numa revisão de contraste, depois que cada um estiver firme (Nation & Crabbe 1991; Higa 1963).

### 10.3 Ordem de introdução das palavras

1. A posição na **NGSL-Spoken** define a ordem base até o A2.
2. Para desempatar, use a **necessidade** do dono (trabalho e tecnologia antes de "zoológico" e "fazenda").
3. **Cognatos verdadeiros cedo** (*important, problem, project, different, possible, information*) dão sensação de progresso.
4. **Falsos cognatos com aviso explícito** e um par contrastivo.
5. **Palavras-coringa germânicas** (*get, put, take, make, go, thing, stuff*) cedo e em muitas colocações, porque são a parte difícil para quem fala português.

### 10.4 Variante, ortografia e detalhes de digitação

- **Inglês americano como padrão.** COCA e SUBTLEX-US são americanos, a PHaVE foi feita sobre o COCA e a documentação técnica é majoritariamente americana. Ortografia US (*color, center, organize, check*). Diferenças britânicas como nota (*bill/check, toilet/restroom*), nunca como alvo de digitação.
- **Contrações:** ensinar a forma contraída como padrão da fala (*I'm, don't, it's, I'll, I'd*) e a forma plena em lição própria, para que a pessoa reconheça as duas.
- **Apóstrofo:** o motor deve aceitar `'` e `’` como equivalentes, e o conteúdo usa `'`.
- **Evitar aspas duplas e acentos no alvo.** No US-International, `"` + vogal produz trema e `'` + vogal produz acento agudo. Termos em português dentro de frases inglesas (*saudade*) devem ser escolhidos sem acento. Isso é tema da frente de UX, mas afeta a redação do conteúdo.
- **Pontuação:** decidir se a pontuação final conta como erro. Recomendação: conta, porque faz parte do chunk (*Bye! Have a nice day.*).

### 10.5 Teste de nivelamento (para "pular etapas")

- O Vocabulary Levels Test de Schmitt é "*freely available for research and pedagogical purposes*" ([recursos](https://www.norbertschmitt.co.uk/vocabulary-resources)) e serve de **inspiração de formato**: amostra por banda de frequência.
- Versão PAC: mostrar o PT-BR e pedir para digitar o EN em **amostras de 10 itens por banda**: Fase 0 (chunks), NGSL-Spoken 1–300, 301–721, NGSL 1k, 2k, 2,8k, PHRASE 1k–3k e PHaVE 1–50. Quem acerta 90% ou mais numa banda pula o nível correspondente.

---

## 11. Metadados sugeridos por frase (para automatizar o controle de nível)

```json
{
  "id": "a1-rotina-012",
  "nivel": "A1",
  "tema": "rotina",
  "en": "I usually get up at seven.",
  "pt": "Eu geralmente me levanto às sete.",
  "foco": "get up",
  "foco_pt": "me levanto",
  "tipo_foco": "phrasal_verb",
  "itens_novos": ["usually"],
  "fontes": { "phave": 23, "phrase": null, "ngsl_spoken_max_rank": 412 },
  "variacoes": ["I usually get up at six.", "She usually gets up at eight."],
  "registro": "neutro",
  "variante": "US",
  "par_interferencia": null
}
```

**Validação automática possível (licença OK):** a NGSL publica `NGSL_12_lemmatized_for_teaching.csv`, que traz as formas flexionadas por lema, e `NGSL_12_stats.csv`, que traz o ranking, ambos sob CC BY-SA 4.0. Com eles, um script consegue, **sem biblioteca de NLP**:

1. mapear cada token da frase para o seu lema;
2. calcular a maior posição (*rank*) da frase e o % de tokens dentro da banda do nível;
3. sinalizar frases com mais de 1 lema fora da banda ou com item novo não declarado em `itens_novos`.

Isso transforma a "regra da cobertura por frase" (§2.8) em um teste, no mesmo espírito dos testes de currículo que o PAC·DART já tem. Os arquivos ficam em [newgeneralservicelist.com/new-general-service-list](https://www.newgeneralservicelist.com/new-general-service-list), na seção de downloads (`/s/NGSL_12_stats.csv` e `/s/NGSL_12_lemmatized_for_teaching.csv`).

---

## 12. Apêndices

### Apêndice A: PHaVE List completa (150) com sentido principal em PT-BR e nível sugerido

Fonte: Garnier & Schmitt (2015), [PDF oficial](https://www.norbertschmitt.co.uk/_files/ugd/5f2482_fb2f15be0d104d08802d9ffd722e5782.pdf). As porcentagens são do próprio PDF (participação do sentido entre as ocorrências do PV). As glosas em PT-BR e os níveis são propostas desta pesquisa. Escrever exemplos próprios.

| # | PV | Sentido(s) principal(is) em PT-BR | Nível |
|---:|---|---|---|
| 1 | go on | acontecer (64,5%); continuar / passar a (*go on to*) (13%) | A2 |
| 2 | pick up | pegar, buscar (alguém ou algo) (70,5%) | A1 |
| 3 | come back | voltar (96,5%) | A1 |
| 4 | come up | *come up with* = bolar, propor (34%); estar chegando (*coming up*) (27,5%) | B1 |
| 5 | go back | voltar (a lugar ou assunto) (90%) | A1 |
| 6 | find out | descobrir (100%) | A2 |
| 7 | come out | sair (de um lugar) (38%); vir à tona (13,5%); ser lançado (10%) | A2/B1 |
| 8 | go out | sair (para se divertir) (56,5%) | A1 |
| 9 | point out | apontar, ressaltar (89%) | B1 |
| 10 | grow up | crescer, virar adulto (98%) | A2 |
| 11 | set up | montar, criar, configurar (64,5%); posicionar (16,5%) | A2 |
| 12 | turn out | acabar sendo, revelar-se (91%) | B1 |
| 13 | get out | sair (de carro, sala), tirar (75,5%) | A2 |
| 14 | come in | entrar (65%); entrar em cena (14%) | A1 |
| 15 | take on | assumir (tarefa) (42%); adquirir (característica) (41,5%) | B2 |
| 16 | give up | desistir, largar (80,5%) | A2 |
| 17 | make up | compor, formar (42,5%); *make up for* = compensar; *make up one's mind* = decidir | B1 |
| 18 | end up | acabar (em, fazendo) (100%) | B1 |
| 19 | get back | voltar (78,5%); *get back to sb* = dar retorno | A2 |
| 20 | look up | olhar para cima (88%); procurar (no dicionário/busca) | A2 |
| 21 | figure out | entender, descobrir, sacar (100%) | B1 |
| 22 | sit down | sentar-se (100%) | A1 |
| 23 | get up | levantar-se (92%) | A1 |
| 24 | take out | tirar (50,5%); levar para sair (13,5%); contratar (seguro, empréstimo) (12,5%) | A2 |
| 25 | come on | vamos! (50%); ah, qual é! (19,5%) | A2 |
| 26 | go down | descer (29%); cair (valor) (27%); ir (para o sul, para baixo) (18%) | A2 |
| 27 | show up | aparecer, comparecer (81%) | B1 |
| 28 | take off | tirar (roupa) (41%); ir embora (28,5%); decolar (14%) | A2 |
| 29 | work out | planejar, resolver (33%); malhar (23%); dar certo/errado (15%) | B1 |
| 30 | stand up | levantar-se (67,5%); posicionar-se publicamente (11%) | A1 |
| 31 | come down | descer, cair (32,5%); baixar (preço) (11%) | A2 |
| 32 | go ahead | ir em frente, prosseguir (99%) | A2 |
| 33 | go up | subir (valor) (47,5%); subir (lugar) (20,5%) | A2 |
| 34 | look back | relembrar (49,5%); olhar para trás (30%) | B1 |
| 35 | wake up | acordar (92%) | A1 |
| 36 | carry out | realizar (63,5%); executar (plano) (34%) | B1 |
| 37 | take over | assumir (controle, cargo) (96,5%) | B1 |
| 38 | hold up | levantar, erguer (54%); atrasar (11,5%); aguentar (14%) | B2 |
| 39 | pull out | tirar, sacar (75%) | B1 |
| 40 | turn around | virar-se (67,5%) | A2 |
| 41 | take up | ocupar (espaço, tempo) (25,5%); tratar de (17,5%); começar (hobby) (10,5%) | B1 |
| 42 | look down | olhar para baixo (92%) | A2 |
| 43 | put up | afixar (23%); *put up with* = aguentar, tolerar (19%); montar (18%) | B1 |
| 44 | bring back | trazer de volta (52,5%); trazer (de viagem) (22,5%) | A2 |
| 45 | bring up | levantar (assunto) (59,5%); criar (filho) (17,5%) | B1 |
| 46 | look out | olhar para fora (50,5%); *look out for* = cuidar de (25,5%) | B1 |
| 47 | bring in | trazer (52%); chamar alguém para um trabalho (30,5%) | B1 |
| 48 | open up | abrir (possibilidades) (42,5%); abrir (27,5%) | B1 |
| 49 | check out | dar uma olhada, conferir (97%) | A2 |
| 50 | move on | passar para outra coisa (42%); mudar-se (28%); seguir em frente (25%) | B1 |
| 51 | put out | divulgar, lançar (47%); apagar (fogo) (14%) | B2 |
| 52 | look around | olhar em volta, dar uma volta (100%) | A2 |
| 53 | catch up | pôr em dia (26%); alcançar (18%); chegar ao mesmo nível (14%) | B1 |
| 54 | go in | entrar (90%) | A1 |
| 55 | break down | dividir em partes, destrinchar (20%); pifar; desabar emocionalmente (17,5%) | B1 |
| 56 | get off | descer (de ônibus, trem) (54%) | A2 |
| 57 | keep up | acompanhar o ritmo (46%); manter (32,5%) | B1 |
| 58 | put down | pôr no chão ou na mesa (62%) | A2 |
| 59 | reach out | estender a mão (48,5%); entrar em contato (39,5%) | B1 |
| 60 | go off | ir (a algum lugar) (44,5%); disparar (alarme) (22%); explodir (14%) | B1 |
| 61 | cut off | cortar (27%); interromper alguém (24,5%); cortar fornecimento (23,5%) | B1 |
| 62 | turn back | virar-se para trás (51,5%); voltar (25,5%) | B1 |
| 63 | pull up | parar (o carro) (47%); puxar para cima (35,5%) | B1 |
| 64 | set out | começar com um objetivo (42,5%); partir (26,5%); expor por escrito (16%) | B2 |
| 65 | clean up | limpar, arrumar (74%) | A2 |
| 66 | shut down | fechar, desligar (empresa, sistema) (94%) | B1 |
| 67 | turn over | entregar (às autoridades) (59,5%) | B2 |
| 68 | slow down | desacelerar (88,5%) | A2 |
| 69 | wind up | acabar (em situação ruim) (87%) | C1 |
| 70 | turn up | aparecer, ser encontrado (48%); aumentar (volume) (21,5%); chegar (14%) | B1 |
| 71 | line up | enfileirar, alinhar (75%) | B1 |
| 72 | take back | levar de volta (50%); retomar (33,5%); retirar o que disse | B1 |
| 73 | lay out | expor em detalhe (46%); dispor sobre superfície (35%) | B2 |
| 74 | go over | ir até (63%); revisar (*go over the code*, sentido secundário) | B1 |
| 75 | hang up | desligar (telefone) (76,5%) | A2 |
| 76 | go through | passar por (dificuldade) (61%); ser aprovado (10%) | B1 |
| 77 | hold on | segurar firme (57%); esperar um pouco (35,5%) | A2 |
| 78 | pay off | quitar (49%); valer a pena (48,5%) | B2 |
| 79 | hold out | manter (esperança) (15%) | C1 |
| 80 | break up | terminar (relacionamento) (59%); dividir em partes (34,5%) | B1 |
| 81 | bring out | realçar (36%); lançar (33%); tirar de dentro (27%) | B2 |
| 82 | pull back | recuar (66,5%); retirar-se (31%) | B2 |
| 83 | hang on | esperar um pouco (41,5%); segurar firme (35,5%) | A2 |
| 84 | build up | acumular, aumentar (76%) | B1 |
| 85 | throw out | rejeitar (29%); jogar fora (25,5%); expulsar (21%) | B1 |
| 86 | hang out | passar tempo, sair com amigos (84%) | A2 |
| 87 | put on | vestir, pôr (52%); montar (show) (14,5%) | A1 |
| 88 | get down | *get down to* = começar a se dedicar (26%); abaixar-se (22,5%); descer (17,5%) | B2 |
| 89 | come over | vir (até aqui, à casa de alguém) (95%) | A2 |
| 90 | move in | mudar-se (para casa nova) (62,5%); avançar sobre (34%) | A2 |
| 91 | start out | começar (como, fazendo) (95%) | B1 |
| 92 | call out | gritar, chamar em voz alta (79%) | B1 |
| 93 | sit up | sentar-se (de deitado) (93,5%) | B1 |
| 94 | turn down | recusar (82,5%) | B1 |
| 95 | back up | dar ré (26%); apoiar (21%); comprovar (20,5%); fazer backup (TI) | B1 |
| 96 | put back | devolver ao lugar (85,5%) | A2 |
| 97 | send out | enviar (para muitos) (57%); mandar alguém (32,5%) | B1 |
| 98 | get in | entrar (carro, casa) (65,5%) | A2 |
| 99 | blow up | explodir (75,5%) | B1 |
| 100 | carry on | continuar (66%) | B1 |
| 101 | set off | partir (30,5%); disparar (27,5%); desencadear (25,5%) | B2 |
| 102 | keep on | continuar fazendo (92,5%) | B1 |
| 103 | run out | *run out of* = ficar sem (49,5%); sair correndo (34%) | A2 |
| 104 | make out | distinguir (ver/ouvir com dificuldade) (60,5%) | C1 |
| 105 | shut up | calar a boca (97%), registro rude | A2 |
| 106 | turn off | desligar (aparelho) (69,5%); causar repulsa (20,5%) | A1 |
| 107 | bring about | provocar, causar (100%) | C1 |
| 108 | step back | dar um passo atrás (72%); afastar-se para avaliar (22,5%) | B2 |
| 109 | lay down | largar, pôr (31%); deitar (28%); estabelecer (regras) (17%) | C1 |
| 110 | bring down | derrubar (32,5%); reduzir (26%) | B2 |
| 111 | stand out | destacar-se (38%) | B1 |
| 112 | come along | surgir (72,5%); ir junto (20,5%) | B1 |
| 113 | play out | desenrolar-se (79,5%) | C1 |
| 114 | break out | irromper, estourar (69,5%) | B2 |
| 115 | go around | circular (boato) (76%) | B1 |
| 116 | walk out | sair de repente ou irritado (81,5%) | B2 |
| 117 | get through | chegar até (27%); ser entendido (22,5%); conseguir falar ao telefone (20,5%); superar (14,5%) | B2 |
| 118 | hold back | conter-se (23,5%); impedir de progredir (21%) | B2 |
| 119 | write down | anotar (98%) | A1 |
| 120 | move back | voltar a morar em lugar anterior (75%) | A2 |
| 121 | fill out | preencher (formulário) (81,5%) | A2 |
| 122 | sit back | recostar-se (66%); ficar de braços cruzados (34%) | B2 |
| 123 | rule out | descartar (possibilidade) (93,5%) | B2 |
| 124 | move up | subir de posição (47%); subir (22,5%) | B1 |
| 125 | pick out | escolher (71,5%); distinguir (19%) | B1 |
| 126 | take down | tirar, desmontar (38,5%); derrubar (27,5%) | B1 |
| 127 | get on | *get on with* = continuar (51%); embarcar (14,5%) | A2 |
| 128 | give back | devolver (100%) | A1 |
| 129 | hand over | entregar (58,5%); passar o controle (41,5%) | B1 |
| 130 | sum up | resumir (97%) | B1 |
| 131 | move out | mudar-se (sair de casa) (94,5%) | A2 |
| 132 | come off | soltar-se (34%); parecer (*come off as*) (24,5%); terminar (17,5%) | B2 |
| 133 | pass on | passar adiante (37%); falecer (eufemismo) (12,5%) | B2 |
| 134 | take in | acolher (24,5%); absorver, entender (17,5%); enganar (10%) | B2 |
| 135 | set down | pousar, colocar (75%) | B2 |
| 136 | sort out | resolver, ajeitar (51%); apurar (25,5%) | B1 |
| 137 | follow up | dar seguimento, apurar mais (45,5%) | B1 |
| 138 | come through | transparecer (20,5%); vencer a dificuldade (20%); chegar (10%) | C1 |
| 139 | settle down | sossegar (31%); acalmar-se (26,5%); acomodar-se (20%) | B2 |
| 140 | come around | aparecer (45%); mudar de ideia (22%); voltar (data) (10%) | B2 |
| 141 | fill in | substituir alguém (31%); *fill sb in* = pôr a par (29,5%); preencher (19%) | B1 |
| 142 | give out | distribuir (40%); divulgar (33,5%); pifar (11,5%) | B2 |
| 143 | give in | ceder, render-se (100%) | B1 |
| 144 | go along | prosseguir (44%); *go along with* = concordar (28%); ir junto (15,5%) | B2 |
| 145 | break off | partir (pedaço) (40%); parar de falar (28%); romper (relação, negociação) (24%) | C1 |
| 146 | put off | adiar (68%); desanimar, repelir (27,5%) | B1 |
| 147 | come about | acontecer (inesperadamente) (81,5%) | C1 |
| 148 | close down | fechar (empresa, loja) (87%) | B1 |
| 149 | put in | colocar, inserir (50%); investir (tempo, esforço) (26,5%) | B1 |
| 150 | set about | começar (com um objetivo) (97%) | C1 |

Distribuição sugerida: **A1 = 14 · A2 = 38 (+1 A2/B1) · B1 = 60 · B2 = 27 · C1 = 10**.

**PVs de TI fora da PHaVE** (frequência baixa no inglês geral, alta no trabalho): *roll back, roll out, spin up, tear down, log in/out, sign up, check in (código), clean up, look into, ramp up, scale up/out, break down (tarefas), boil down to, iron out, hand off*.

### Apêndice B: PHRASE List por banda, com foco em fala × acadêmico

Fonte: Martinez & Schmitt (2012), [lista oficial (.doc)](https://www.norbertschmitt.co.uk/_files/ugd/5f2482_63c555de9e3f4c09af4170ba051b3bbe.doc). A classificação "fala" e "acadêmico" foi derivada aqui das estrelas de gênero da lista: "fala" = três estrelas em *spoken general* e no máximo uma em *written academic*; "acadêmico" = o inverso. Itens neutros não aparecem nos grupos, mas estão na lista completa.

**B.1 Banda 1k (32 itens), todos com PT-BR**

| Item | PT-BR | Gênero |
|---|---|---|
| have to | ter que | fala |
| there is/are | há, tem | neutro |
| such as | como (por exemplo) | acadêmico |
| going to (futuro) | ir + verbo (futuro planejado) | fala |
| of course | claro | fala |
| a few | alguns, uns poucos | fala |
| at least | pelo menos | neutro |
| such a(n) | um(a) … tão | fala |
| I mean | quer dizer | fala |
| a lot | muito | fala |
| rather than | em vez de | neutro |
| so that | para que | fala |
| a little | um pouco | fala |
| a bit (of) | um pouco (de) | fala |
| as well as | assim como, além de | neutro |
| in fact | na verdade, de fato | neutro |
| (be) likely to | ser provável que | neutro |
| go on | continuar; acontecer | fala |
| is to | vai, deve (futuro formal, jornalístico) | escrita |
| a number of | vários | escrita |
| at all | de jeito nenhum; por acaso (em perguntas) | neutro |
| as if | como se | escrita |
| used to (passado) | costumava | fala |
| was to | iria, estava para | escrita |
| not only | não só | neutro |
| those who | aqueles que | acadêmico |
| deal with | lidar com | neutro |
| lead to | levar a, causar | escrita |
| sort of | meio que | fala |
| the following | o seguinte | acadêmico |
| in order to | a fim de, para | escrita |
| have got (+ subst.) | ter | fala |

**B.2 Banda 2k (84 itens), com PT-BR**

*have got to* (ter que) · *set up* (montar, configurar) · *as to* (quanto a) · *as well* (também) · *based on* (baseado em) · *carry out* (realizar) · *take place* (acontecer, ocorrer) · *tend to* (tender a, costumar) · *due to* (devido a) · *fail to* (deixar de, não conseguir) · *each other* (um ao outro) · *in terms of* (em termos de) · *no one* (ninguém) · *pick up* (pegar, buscar) · *up to* (até, no máximo) · *a single* (um único; nenhum) · *no longer* (não … mais) · *look for* (procurar) · *last night* (ontem à noite) · *as a result* (como resultado) · *in addition (to)* (além de) · *work on* (trabalhar em) · *think about* (pensar em) · *for instance* (por exemplo) · *too much* (demais) · *you see* (sabe, veja bem) · *in particular* (em particular) · *a couple of* (uns dois, alguns) · *instead of* (em vez de) · *come back* (voltar) · *look like* (parecer) · *find out* (descobrir) · *point out* (apontar) · *apart from* (além de; exceto) · *call for* (exigir, pedir) · *manage to* (conseguir) · *or two* (ou dois: *a day or two*) · *a further* (mais um, adicional) · *come out* (sair, ser lançado) · *be expected to* (esperar-se que) · *seek to* (procurar, buscar fazer) · *go through* (passar por) · *long term* (longo prazo) · *result in* (resultar em) · *that is* (ou seja) · *even though* (mesmo que) · *a range of* (uma variedade de) · *the latter* (este último) · *make sure* (garantir, certificar-se) · *take over* (assumir) · *consist of* (consistir em) · *as soon as* (assim que) · *at the time* (na época) · *on the other hand* (por outro lado) · *on one's own* (sozinho) · *all right* (tudo bem) · *subject to* (sujeito a) · *after all* (afinal) · *in front of* (na frente de) · *to do with* (a ver com) · *go out* (sair) · *a good/great deal* (muito) · *on the way* (a caminho) · *as long as* (desde que) · *so far* (até agora) · *ought to* (deveria) · *at the moment* (no momento) · *as though* (como se) · *come to* (passar a, chegar a) · *along with* (junto com) · *may well* (pode muito bem) · *get out* (sair) · *followed by* (seguido de) · *in (the sense) that* (no sentido de que) · *the case* (o caso, ser verdade) · *take up* (ocupar; começar) · *account for* (representar, explicar) · *set out* (partir; expor) · *as far as* (até onde, no que diz respeito) · *concerned with* (relacionado a) · *about to* (prestes a) · *supposed to* (deveria, supostamente) · *and so on* (e assim por diante) · *come on* (vamos!; ah, qual é).
- Dominantes na fala (27): *have got to, each other, no one, pick up, a single, look for, last night, work on, think about, too much, you see, a couple of, look like, or two, on one's own, all right, after all, to do with, go out, a good/great deal, on the way, as long as, ought to, get out, take up, about to, come on*.
- Dominantes no acadêmico (13): *as to, carry out, as a result, for instance, a further, seek to, result in, the latter, consist of, subject to, followed by, account for, concerned with*.

**B.3 Banda 3k (129 itens)**
- **Fala (44), para A2/B1:** *all over, look after, give up, get to (chegar a), get up, get on/off, by the time, lots of, all the time, kind of, get into, go for, get back, what about, something like (cerca de), in touch (with), in the way, care for, they say, next to, turn up, used to (acostumado), full time, in a way, or something, over there, that's it, oh no, go into, out there, have a look, believe in, put it (dizer), these days, feel like, heard of, part time, turn on, set to, move on, all but, rid of, go away, oh well*.
- **Acadêmico (31), para C1:** *out of (de), in practice, in turn, on the basis (of), aim to, make up (compor), no more than, entitled to, prior to, known to, in the event (of), take into account, in respect of, at present, whether or not, in place, on behalf of, in spite of, in part, (with) regard to, as follows, the above, to date, in the course of, aimed at, take part in, in so far as, as such, in contrast (to), follow up, found to*.
- **Neutros de alto valor (B1):** *take on, work out, other than, turn out, at last, a variety of, at first, carry on, go back, focus on, at once, it takes, in time, once again, end up, in other words, as for, not even, in the end, point of view, no doubt, sort out, in mind, too many, more or less, in case, more and more, in charge, look forward to, in any case, thanks to, once more, above all*.

**B.4 Banda 4k (158 itens)**
- **Fala (63), para B1/B2:** *hang on, turn into, something about, by now, think so, go ahead, had better, afford to, take off, switch on, could hardly, come up with, no matter, or whatever, hand over, that much, to death, oh dear, on board, some kind of, keep up, no idea, happen to (be), from time to time, ever since, just about, make sense, a bit of a, break up, but then (again), all too, put up, good at, a long way, for long, some more, all sorts of, get on with, no good, I'm afraid, right now, nothing but, out of (por causa de), next door, get to (ter a oportunidade), by the way, run out (of), on the one hand, old fashioned, or anything, first of all, might as well, to me (na minha opinião), mind you, way out, worth of, a good (pelo menos), except that, day to day, as usual, quite a lot, if you like, care to*.
- **Acadêmico (37), para C1:** *in accordance with, on the part of, short of, in question, prove to be, the former, in the light of, the extent to which, in full, greater than, held that, do(ing) so, put forward, the means, give rise to, large scale, by means of, in short, in the absence of, that which, in view of, in the face of, such that, in principle, as yet, at risk, a mere, shown to, provide for, limited to, with respect to, consistent with, third party, contrary to, in conjunction with, to the extent, take account of*.
- **Neutros de alto valor (B2):** *bring about, call on, at times, all the way, in effect, in advance, bring up, so as to, take advantage, over the years, by no means, in the first place, in common, at this point, in itself, if only, yet to, up to (cabe a), in the same way, for some time, in return (for), on the grounds, to some extent, set off, ever since, as opposed to, break up, a long way, amount to, yet another, key to, if so, in detail, reflected in, to the point, make one's way, in hand, by contrast, add to, by way of, on the road, bear in mind, for sale, most likely, even so, come across, long before, long ago, up to date, let alone, given that, in line with, on the whole*.

**B.5 Banda 5k (103 itens)**
- **Fala (49), para B2/C1:** *something like that, for all (considerando), get away, something of a, the odd, would you like, take for granted, catch up, a go (tentativa), for the moment, put together, things like that, shut up, the other day, for good, bother to, as good as, back up, take care of, go round, the whole thing, head to, way round, can tell, and all that, as it were, what if, touch of, better off, turn down, get on (dar-se bem), never mind, come up to, no sign of, just as, for the sake of, at best, that sort of thing, fond of, get away with, no wonder, well being, how about, to go (restando), straight away, hold up, the lot, keep on, make up one's mind*.
- **Acadêmico (12), para C1:** *little more than, in need, in this respect, provided that, allow for, at the expense of, free from, under way, in the interest of, a degree of, wealth of, at work*.
- **Neutros (C1):** *make use of, when it comes to, fill in, a question of, for life, in the meantime, in theory, thought of (as), opposed to, common sense, on average, in a sense, stand for, to blame, the bulk of, a handful of, (at) the outset, by virtue of, on the market, by far, in one's own right, in which case, in a position to, to come, at best, come to terms with, with a view to, owing to, look to, lay out, come about*.

### Apêndice C: NGSL-Spoken 1.2, os 300 lemas mais frequentes (ordem de rank)

Fonte: Browne & Culligan, *New General Service List-Spoken*, CC BY-SA 4.0 ([arquivo de estatísticas](https://www.newgeneralservicelist.com/s/NGSL-Spoken_12_stats.csv)). Removi quatro artefatos de transcrição que estão no arquivo (*pause, unclear, laugh, laughter*). *Pound* (libra) é viés britânico do corpus.

**1–100:** be, the, you, and, it, to, a, have, of, do, not, that, they, we, in, he, know, get, go, so, this, but, on, I, for, think, like, there, will, say, she, what, just, well, one, with, if, at, all, about, or, as, would, then, because, right, can, no, up, mean, out, see, thing, yes, when, really, want, come, now, some, good, from, time, people, very, yeah, make, look, two, take, here, which, could, work, more, who, other, where, use, something, how, back, year, by, any, lot, way, put, down, give, sort, three, much, actually, need, talk, kind, tell, only, should

**101–200:** over, little, day, into, bit, try, why, okay, off, first, than, too, five, let, call, four, last, start, quite, still, find, probably, even, might, through, point, anything, week, before, again, problem, never, same, big, feel, ask, question, also, different, sure, long, always, school, happen, course, keep, another, nice, read, hundred, leave, many, after, thank, meet, stuff, end, number, hear, next, six, pay, money, place, remember, maybe, old, test, home, change, though, house, new, live, part, kid, interest, around, write, most, move, every, today, twenty, else, anyway, child, buy, fact, play, great, job, seem, man, night, away, (pound), issue, own, area

**201–300:** half, bad, round, eight, help, ten, whole, everything, minute, may, whether, student, guess, whatever, car, sit, bring, book, name, run, show, word, suppose, morning, must, understand, month, both, idea, seven, pretty, somebody, able, item, hour, side, enough, ever, important, late, turn, between, thousand, few, term, life, nine, believe, far, sorry, set, thirty, nothing, case, real, second, mind, woman, guy, each, hard, couple, love, speak, group, together, high, friend, build, family, watch, country, plan, fifty, send, obviously, reason, yet, walk, either, wait, already, person, open, once, deal, report, stop, hand, alright, example, cause, information, please, exactly, ago

**Leitura para o design:** os números (*two, three, five… hundred, thousand*) e marcadores de conversa (*yeah, okay, actually, probably, anyway, whatever, guess, suppose, pretty, obviously, alright*) estão no top 300. Isso reforça a mini-trilha de números e a presença de marcadores de conversa desde o A1.

---

## 13. Fontes

**Listas de frequência (família NGSL)**
- NGSL (site oficial, licenças, downloads): https://www.newgeneralservicelist.com/ · https://www.newgeneralservicelist.com/new-general-service-list
- NGSL-Spoken: https://www.newgeneralservicelist.com/ngsl-spoken
- NAWL: https://www.newgeneralservicelist.com/new-academic-word-list
- BSL: https://newgeneralservicelist.com/business-service-list
- TSL: https://newgeneralservicelist.com/toeic-service-list
- NGSL-GR: https://www.newgeneralservicelist.com/ngsl-graded-reader
- Arquivos usados no cálculo: https://www.newgeneralservicelist.com/s/NGSL_12_stats.csv · https://www.newgeneralservicelist.com/s/NGSL-Spoken_12_stats.csv
- Wikipedia — NGSL: https://en.wikipedia.org/wiki/New_General_Service_List
- Kobe University (seminário com C. Browne, dez/2025): https://www.kobe-u.ac.jp/en/announcement/20251210-67373/

**Phrasal verbs e chunks**
- Norbert Schmitt — recursos (PHaVE, PHRASE, VLT): https://www.norbertschmitt.co.uk/vocabulary-resources
- PHaVE List (PDF): https://www.norbertschmitt.co.uk/_files/ugd/5f2482_fb2f15be0d104d08802d9ffd722e5782.pdf
- Garnier & Schmitt (2015), *Language Teaching Research* 19(6), DOI 10.1177/1362168814559798 — https://nottingham-repository.worktribe.com/output/762398
- Deck Anki PHaVE (nota de licença CC BY 4.0): https://codeberg.org/Ema0408/PHaVE
- PHRASE List (.doc): https://www.norbertschmitt.co.uk/_files/ugd/5f2482_63c555de9e3f4c09af4170ba051b3bbe.doc
- PHRASE List — guia do usuário (.doc): https://www.norbertschmitt.co.uk/_files/ugd/5f2482_6f9fe868fe7c46b38dac881fcef4148f.doc
- Martinez & Schmitt (2012), *A Phrasal Expressions List*, *Applied Linguistics* 33(3), 299–320.
- Academic Collocation List: https://eapfoundation.com/vocab/academic/acl/ · https://www.pearsonpte.com/research/Documents/AcademicCollocationList.pdf

**Listas proprietárias e de referência**
- Oxford 3000/5000: https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford3000-5000
- Revisão da Oxford 3000 (níveis CEFR, Oxford Phrase List): https://teachingenglishwithoxford.oup.com/2019/11/11/oxford-3000%EF%B8%8F-eltoc/amp
- Oxford Phrase List: https://www.oxfordlearnersdictionaries.com/about/wordlists/oxford-phrase-list
- English Profile / EVP: https://en.wikipedia.org/wiki/English_Profile · https://www.englishprofile.org
- COCA (wordfrequency.info): https://www.wordfrequency.info/ · https://wordfrequency.info/samples.asp
- SUBTLEX-US: https://www.ugent.be/pp/experimentele-psychologie/en/research/documents/subtlexus
- Termos do SUBTLEX via wordfreq: https://cdn.jsdelivr.net/npm/nodewordfreq@0.2.1/NOTICE.md

**Cobertura e tamanho de vocabulário**
- Nation (2006): https://www.wgtn.ac.nz/__data/assets/pdf_file/0018/1626120/2006-How-large-a-vocab.pdf
- Schmitt, Cobb, Horst & Schmitt (2015), *Language Teaching*, DOI 10.1017/S0261444815000075: https://www.lextutor.ca/cover/papers/schmitt_cobb_etal_2015.pdf
- Nation — Vocabulary, the CEFR levels, and word family size: https://wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-lists/vocabulary-cefr-and-word-family-size/vocabulary-and-the-cefr-docx
- Milton & Alexiou: https://www.enl.auth.gr/gala/14th/Papers/English%20papers/Milton&Alexiou.pdf
- Webb & Rodgers (2009), resumo secundário: https://so05.tci-thaijo.org/index.php/thaitesoljournal/article/download/266026/178362/1031283
- Most common words in English (OEC): https://en.wikipedia.org/wiki/Most_common_words_in_English
- Erman & Warren (2000), citado em: https://www.holgerdiessel.uni-jena.de/Grammar%20and%20Language%20Use%204.pdf

**Abordagem lexical, sobrevivência e cognatos**
- Nation & Crabbe (1991), *A survival language learning syllabus for foreign travel*: https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-lists/survival-vocabulary-lists/survival-korean.pdf
- Resenha de *The Lexical Approach* (TESL-EJ): https://www.cc.kyoto-su.ac.jp/information/tesl-ej/ej02/r.3.html
- EBSCO — Lexical Approach: https://ebsco.com/research-starters/language-and-linguistics/lexical-approach
- Cognatos e AWL (Lubliner & Hiebert, via Frontiers 2023): https://www.frontiersin.org/journals/education/articles/10.3389/feduc.2023.1225169/full
- Falsos cognatos PT↔EN: https://migaku.com/blog/language-fun/portuguese-false-friends · https://blog.glossika.com/blog/false-friends-between-portuguese-and-english

**Inglês técnico e para desenvolvedores**
- CSAVL: https://eapfoundation.com/vocab/academic/other/csavl · https://pdxscholar.library.pdx.edu/ling_fac/72 (DOI 10.1016/j.jeap.2021.101044)
- Scrum Guide: https://scrumguides.org/scrum-guide.html
- Google Engineering Practices — comentários de code review: https://google.github.io/eng-practices/review/reviewer/comments.html
- Conventional Comments: https://conventionalcomments.org/
- Stand-ups em inglês (fontes secundárias): https://llexi.com/business-english/english-team-stand-ups-daily-scrum/ · https://www.talkdrill.com/blog/vocabulary/tech/it-tech-english-vocabulary/

**Referências citadas sem reverificação on-line nesta sessão** (o limite de buscas acabou): Martinez & Murphy (2011), *TESOL Quarterly* 45(2); Webb (2007), *Applied Linguistics* 28(1); Simpson-Vlach & Ellis (2010), *Academic Formulas List*, *Applied Linguistics* 31(4); Lei 9.610/98, art. 7º, XIII.
