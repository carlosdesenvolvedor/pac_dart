# 07 · Fontes abertas de frases e garantia de naturalidade

> Dossiê de pesquisa para o terceiro curso do PAC·DART (inglês por digitação de frases, com a tradução PT-BR em cima).
> Escrito em 04/out/2026. Nada aqui foi aplicado ao projeto. Os dados baixados, os scripts e a lista de candidatas ficaram em `scratchpad/ingles/pesquisa/fontes07/`.
> Conversa com os dossiês irmãos: **02** (progressão e comprimento por nível), **03** (listas de frequência e licenças de listas), **04** (interferências de brasileiros, regras de tradução e decisão por en-US), **05** (produtos) e **06** (TTS e teclado, incluindo o validador de formato). Este dossiê não repete esses temas, só os referencia quando o checklist depende deles.

---

## 0. Resumo executivo

**Recomendação: modelo MISTO, com papéis separados. A regra é "Tatoeba primeiro, autoria própria (assistida por IA) para o resto, e o mesmo revisor automático para as duas origens".**

1. **O Tatoeba é a única fonte aberta grande, humana e bilíngue EN↔PT, frase a frase, com licença que permite uso comercial** (CC BY 2.0 FR, só exige atribuição). Medi no export de 03/10/2026: 2.046.655 frases em inglês, 445.215 em português e **302.059 ligações diretas EN–PT, cobrindo 242.305 frases inglesas distintas**.
2. **Não serve como espinha dorsal do curso.** As frases são soltas, sem progressão nem cenas. 21% têm Tom ou Mary, 48% são de um único autor (CK), e a tradução mistura pt-BR com pt-PT. Mesmo nos pares filtrados há erro de tradução. Na auditoria manual de 60 pares achei 2 erros de sentido, 2 de ortografia e cerca de 4 traduções duras. Nas buscas por chunk apareceu uma negação perdida: *"If I were you, I wouldn't do that kind of thing."* virou "Se eu fosse você, eu faria esse tipo de coisa."
3. **Como reservatório, o Tatoeba é enorme.** Apliquei um funil conservador: dono do inglês nativo, tradutor brasileiro, PT sem marca europeia, frases criadas antes de dez/2022, sem Tanaka Corpus nem `@change`, sem tema sensível, 3 a 14 palavras só em ASCII. Sobram **85.460 frases inglesas com tradução brasileira**: 47 mil no vocabulário A1 (pelo CEFR-J), 19 mil A2, 10 mil B1 e 3,5 mil B2. Sem Tom/Mary, ficam 50 mil. Isso basta como "âncora" de inglês real e para treino extra e revisão. Vocabulário de dev quase não existe ali (0 frases com *pull request*, 1 com *deploy*), então essa trilha é toda autoral.
4. **O áudio do Tatoeba não serve.** 98% do áudio em inglês (835.148 gravações) é do usuário CK, sob **CC BY-NC-ND 3.0**: não comercial, sem derivados. O dono escreve que "qualquer site com anúncio é considerado comercial". Só 1.189 frases inglesas dos pares têm áudio com licença permissiva. Use TTS (dossiê 06).
5. **Não usar como conteúdo**:
   - OpenSubtitles: sem licença declarada, e legendas derivam de filmes protegidos.
   - Decks do AnkiWeb: a licença padrão é "personal use only".
   - DailyDialog: CC BY-NC-SA.
   - Exemplos de dicionário, COCA e Ludwig: servem só para consulta.
   - Wikipedia e Common Voice: as licenças são boas, mas o registro é enciclopédico e não serve de modelo de conversa.
6. **Nas frases de IA, o risco é naturalidade e monotonia, não gramática.**
   - No estudo de Lew (2023), os exemplos do ChatGPT tiveram **3,3/5**, contra **4,2/5** dos lexicógrafos do COBUILD. Os comentários foram "unnatural", "dull and samey" e "clunky past-tense".
   - Reinhart et al. (PNAS, 2025) mediram que modelos instruídos usam orações de particípio presente **2 a 5 vezes** mais que humanos (GPT-4o: 5,3 vezes) e nominalizações **1,5 a 2 vezes** mais.
   - **O próprio Tatoeba proíbe frases geradas por IA**. Isso o torna uma das poucas referências de inglês humano que restam. Para segurança, use só frases de antes de dez/2022.
7. **A checagem automática faz triagem, não dá veredito.** Testei nesta sessão:
   - A atestação de trigramas contra 1,27 milhão de frases nativas do Tatoeba pegou 5 de 7 erros típicos de brasileiro e a frase "LLM-ish".
   - O Netspeak (API gRPC-web, que fiz funcionar) e o Google Books Ngram (endpoint JSON) resolvem as dúvidas comparando a frequência das alternativas.
   - O LanguageTool pegou *look forward to see* e as palavras de Portugal no PT, mas deixou passar *I have 20 years* e *I am living here since*.
   - Por isso é preciso somar as regras de interferência do dossiê 04, um juiz LLM adversarial no papel de nativo e a retro-tradução PT→EN.
8. **A atribuição custa pouco.** Cada frase vinda do Tatoeba guarda IDs e autores do EN e do PT, a licença e se foi modificada. O app ganha uma tela "Créditos" e um link por frase.
9. **Entregável principal (seção 8):** um checklist em 8 camadas (F, P, G, N, L, T, C, D) com 50 regras testáveis, severidade, ferramenta e formato de saída JSON, para outro agente aplicar frase a frase.

---

## 1. Escopo, método e limites

**O que foi feito de verdade nesta sessão:**

- **Leitura de fontes primárias** com WebFetch, curl e navegador headless. A cota de WebSearch da sessão (compartilhada) esgotou logo no início. Por isso as buscas bibliográficas foram feitas pelas APIs do OpenAlex, OPUS, GitHub e Hugging Face, e por páginas oficiais.
- **Download e medição dos exports do Tatoeba** (EN, PT, links, áudio, tags, níveis declarados, revisões), cerca de 330 MB. Os números da seção 2 saem desses arquivos, não de memória.
- **Testes práticos** com a API v1 do Tatoeba, o Netspeak (cliente gRPC-web escrito aqui), o endpoint JSON do Google Books Ngram, a API pública do LanguageTool e uma atestação de trigramas montada aqui.
- **Auditoria manual** de 60 pares EN–PT sorteados entre as candidatas filtradas.

**Scripts reproduzíveis** (todos em `pesquisa/fontes07/`):

| Arquivo | O que faz |
|---|---|
| `analisa.py` | contagens gerais dos pares EN–PT: donos, áudio, revisões, tags, variantes PT, tipografia |
| `nivel.py` | estimativa do nível lexical CEFR-J/Octanove de cada frase EN |
| `funil.py` | funil de filtros e geração de `tatoeba_candidatas_en_ptbr.tsv` (85.460 linhas) |
| `netspeak.py` | cliente mínimo do Netspeak (gRPC-web, sem dependências) |
| `trigramas.py` | atestação de trigramas contra o inglês nativo do Tatoeba |

**Limites:**

- **Não é parecer jurídico.** É a leitura dos termos publicados.
- **O "nível" das frases é só lexical e grosseiro.** Usa um lematizador heurístico com a lista CEFR-J 1.5 e a Octanove C1/C2. Não mede gramática: *"I've never met someone that I love as much as I love you."* sai "A1" no léxico.
- **A classificação do tradutor como brasileiro ou português é heurística**, feita por contagem de marcadores.
- **A auditoria de 60 pares é amostra pequena.** Os intervalos de confiança estão indicados.
- **Não consegui abrir o COCA nem o Ludwig** (bloqueio Cloudflare). O que digo deles vem de fontes secundárias ou está marcado como não verificado.

---

## 2. Tatoeba a fundo

### 2.1 Tamanho (medido em 04/out/2026)

| Item | Valor | Fonte |
|---|---|---|
| Frases no total / idiomas | 13.625.213 / 431 | [stats](https://tatoeba.org/en/stats/sentences_by_language) |
| Inglês (`eng`) | 2.046.655 (1º lugar) | idem |
| Português (`por`) | 445.215 (11º lugar) | idem |
| Ligações diretas EN–PT (`eng-por_links.tsv`) | 302.059 válidas | export medido |
| Frases EN distintas com tradução PT | 242.305 | export medido |
| Frases PT distintas ligadas a EN | 280.769 | export medido |
| EN com mais de uma tradução PT | 43.097 (máximo de 52 traduções para uma frase) | export medido |
| Pacote OPUS "Tatoeba" en–pt (v2026-07-08) | 239.869 pares alinhados | [OPUS API](https://opus.nlpl.eu/opusapi/?corpus=Tatoeba&source=en&target=pt&preprocessing=moses&version=latest) |
| Arquivo `por-eng.zip` do ManyThings (pré-filtrado) | 197.147 pares | [manythings.org/anki](https://www.manythings.org/anki/) |

### 2.2 Licença do texto

**O que o Tatoeba publica:**

- "Tatoeba's technical infrastructure uses the default Creative Commons Attribution 2.0 France license (CC-BY 2.0 FR) for the use of textual sentences." A menção BY "implies a single restriction ... a condition of attribution" ([Terms of use](https://tatoeba.org/en/terms_of_use); [wiki](https://en.wiki.tatoeba.org/articles/show/using-the-tatoeba-corpus)).
- **A licença permite uso comercial e adaptação.** "Share — ... for any purpose, even commercially"; "Adapt — remix, transform ... even commercially". Exige "give appropriate credit, provide a link to the license, and indicate if changes were made" ([deed CC BY 2.0 FR](https://creativecommons.org/licenses/by/2.0/fr/deed.en)).
- **Não há ShareAlike.** O conteúdo próprio do curso continua nosso, e misturar as duas origens não "contamina" nada.
- **O subconjunto CC0 é irrelevante para nós.** Tem 41.512 frases EN e só **17 frases PT**.
- **Como atribuir, segundo o FAQ:** "write somewhere that some/all of your sentences are from Tatoeba, with a link to https://tatoeba.org, and mention that Tatoeba's data is released under CC-BY 2.0 FR". O exemplo citado é a página do Clozemaster ([FAQ](https://en.wiki.tatoeba.org/articles/show/faq)).
- **O ManyThings é mais exigente:** "The owner of tatoeba.org has suggested that the CC-BY license means that you also must give attribution to each sentence owner ... if you want to redistribute this material" ([manythings.org/anki](https://www.manythings.org/anki/)).
- **Decisão prática:** fazer as duas coisas. Uma tela de créditos global e, em cada frase, o ID e o autor (seção 7). Custa só dois campos no JSON.
- **A responsabilidade é de quem usa:** "You are responsible for your use, reuse, modification and dissemination of the content" ([Terms](https://tatoeba.org/en/terms_of_use)).

### 2.3 Áudio: licença por contribuidor, e o grosso é NC-ND

**O que diz o Tatoeba:** "The license covering an audio file is chosen by the contributor". Áudio sem licença declarada "you may not reuse ... outside the Tatoeba project" ([Downloads](https://tatoeba.org/en/downloads)).

**O que medi em `eng_sentences_with_audio.tsv` (851.623 linhas):**

| Contribuidor / licença | Gravações EN |
|---|---|
| **CK / CC BY-NC-ND 3.0** | **835.148 (98,1%)** |
| Auride / CC BY-SA 4.0 | 3.321 |
| CVeng2 / sem licença (só Tatoeba) | 2.290 |
| rul / CC BY 4.0 | 1.895 |
| Them / CC BY 4.0 | 1.853 |
| cblanken / CC BY-NC 4.0 | 1.102 |
| demais | menos de 1 mil cada |

**Nos pares EN–PT:**

- 148.396 frases EN (61,2%) têm áudio, quase todas do CK.
- Só **1.189** têm áudio com licença que permite uso comercial (CC BY, CC BY-SA ou CC0).
- No português, das 20.957 gravações, 12.316 não têm licença e 8.638 são CC BY-NC 4.0.

**O que diz o dono do áudio do CK** (Charles Kelly, do ManyThings): "licensed under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 Unported license" e "**Any website that includes advertising is considered commercial and should not be using these MP3 files**". Ele exige atribuição em cada página e os metadados mantidos no MP3 ([manythings.org/tatoeba](https://www.manythings.org/tatoeba/)).

**Download, se algum dia for preciso:** `https://audio.tatoeba.org/sentences/{lang}/{id}.mp3`, um a um. Há um ZIP em inglês de 3,8 GB de 2017 ([FAQ](https://en.wiki.tatoeba.org/articles/show/faq)).

**Conclusão:** não usar o áudio do Tatoeba. O PAC·DART pode vir a ter anúncio ou uso de portfólio, e o ND complica até a compressão para outro bitrate. TTS próprio está detalhado no dossiê 06.

### 2.4 Como baixar (receita)

Os arquivos são atualizados "every Saturday at 6:30 a.m. (UTC)" ([Downloads](https://tatoeba.org/en/downloads)). Para o curso bastam os **exports por idioma**:

| Arquivo | Conteúdo (TSV) | Uso |
|---|---|---|
| `per_language/eng/eng-por_links.tsv.bz2` | `id_en \t id_pt` (ligações diretas) | os pares |
| `per_language/eng/eng_sentences_detailed.tsv.bz2` | `id \t lang \t texto \t dono \t criada \t modificada` | texto, autor, data |
| `per_language/por/por_sentences_detailed.tsv.bz2` | idem para PT | idem |
| `per_language/{eng,por}/*_user_languages.tsv.bz2` | `lang \t nível 0-5 \t usuário \t detalhes` (autodeclarado) | "dono nativo" |
| `per_language/{eng,por}/*_tags.tsv.bz2` | `id \t tag` | filtrar `Tanaka Corpus`, `@change`, `vulgar`... |
| `per_language/eng/eng_sentences_base.tsv.bz2` | `id \t base` (0 = original; >0 = traduzida de) | detectar "translationese" |
| `per_language/eng/eng_sentences_with_audio.tsv.bz2` | `id \t audio_id \t usuário \t licença \t url` | (não usar) |
| `users_sentences.csv` (na raiz) | `usuário \t id \t -1/0/1 \t datas` (revisões; "experimental") | sinal fraco de qualidade |

Base: `https://downloads.tatoeba.org/exports/`. Comandos usados:

```bash
B=https://downloads.tatoeba.org/exports/per_language
curl -L -O $B/eng/eng-por_links.tsv.bz2
curl -L -O $B/eng/eng_sentences_detailed.tsv.bz2
curl -L -O $B/por/por_sentences_detailed.tsv.bz2
curl -L -O $B/eng/eng_user_languages.tsv.bz2
curl -L -O $B/por/por_user_languages.tsv.bz2
curl -L -O $B/eng/eng_tags.tsv.bz2
bunzip2 -k *.bz2
```

**API v1** (documentação em [api.tatoeba.org](https://api.tatoeba.org/)), testada aqui:

```
GET https://api.tatoeba.org/v1/sentences?lang=eng&trans:lang=por&q=coffee&sort=relevance&limit=2
```

- Cada frase volta com `license` e `owner`, e cada tradução traz `is_direct`.
- **Atenção:** a API devolve também traduções **indiretas** (`is_direct: false`, feitas via outra língua). Exemplo real: *"Drink coffee."* (frase órfã) → "Bebe café." (indireta, em forma de tu/Portugal).
- **Use só ligações diretas.** Os arquivos `eng-por_links` já são diretos.

### 2.5 Qualidade, medida nos dados

#### 2.5.1 Quem escreve

**Inglês (242.305 frases dos pares):**

- **69,6%** pertencem a donos que se declaram nativos (nível 5) e 1,9% são órfãs.
- **CK sozinho é dono de 117.280 (48,4%).**
- Seguem Cangarejo (10.174, nível 4 em inglês), Hybrid (9.295, nativo), carlosalberto (9.159, nível 3) e CM (8.562, nativo).
- Ou seja, parte do inglês ligado ao português foi escrita por **não nativos**. Filtrar por dono nativo é obrigatório.

**Português (280.769 frases):** 93,9% de donos nativos. Os maiores são alexmarcelo (46.332), Ricardo14 (44.678, "Rio de Janeiro"), carlosalberto (31.809) e bill (31.644, "Brazilian Portuguese").

**Pares com os dois lados nativos:** 204.150, cobrindo 159.476 frases EN distintas.

**Ressalva do próprio Tatoeba:** "several members rate themselves as native speakers of multiple languages and ... self-reported levels may not be accurate" ([wiki](https://en.wiki.tatoeba.org/articles/show/using-the-tatoeba-corpus)).

#### 2.5.2 Revisão e a lista do CK

- **A lista 907, "Proofread Good English Sentences That CK Uses on His Projects", tem 959.300 frases** ([lista 907](https://tatoeba.org/en/sentences_lists/show/907)). A wiki a recomenda para material didático: "you should probably use only sentences that you or someone else has personally proofread and not rejected" ([wiki](https://en.wiki.tatoeba.org/articles/show/using-the-tatoeba-corpus)).
- **As revisões (`users_sentences.csv`) são, na prática, do CK.** Das revisões de frases inglesas, 959.741 são dele. Os votos somam +1 = 989.279, 0 = 865 e −1 = 635.
- **Nos pares EN–PT:** 160.020 frases EN (66%) têm alguma revisão e só 71 têm −1.
- **"Revisado" aqui significa "um nativo prolífico achou OK", não "revisão independente".** O próprio Tatoeba alerta: "not all sentences that are OK are explicitly marked ... and some sentences that do have errors are not marked with a negative rating".

#### 2.5.3 Origem e o Tanaka Corpus

**Pelo `sentences_base`, as frases EN dos pares se dividem assim:** 147.677 originais (61%), 61.180 traduzidas de outra língua (25%, risco de *translationese*) e 33.448 de origem desconhecida (14%).

**Tag `Tanaka Corpus`:** 138.064 frases EN no total e **32.148 nos pares**. O Tanaka Corpus foi montado por alunos japoneses do Prof. Yasuhito Tanaka ("given the task of collecting 300 sentence pairs each"). A documentação admite:

- "The original collection contained large numbers of errors, both in the Japanese and English".
- "many of the sentence pairs have been derived from textbooks".
- Há "contrived examples of grammar usage or slightly archaic English".

Fonte: [EDRDG](https://www.edrdg.org/wiki/Tanaka_Corpus.html). **Excluir.**

#### 2.5.4 Variante do português (crítico para "tradução em cima")

O Tatoeba usa um código só (`por`), e as etiquetas de variante quase não são usadas: "Brazilian Portuguese" aparece em 63 frases dos pares e "Portuguese from Portugal" em 57. Contei marcadores nas 280.769 frases PT dos pares:

| Marcador brasileiro | n | Marcador europeu | n |
|---|---|---|---|
| você/vocês | 37.983 | tu (+ formas *estás, tens, queres*...) | 1.313 + 1.020 |
| ônibus | 697 | autocarro | 42 |
| trem | 543 | comboio | 53 |
| celular | 230 | telemóvel | 23 |
| estar + gerúndio | 10.008 | estar a + infinitivo | 1.045 |
| ortografia pós-Acordo | — | *facto, actual, óptimo, acção*... | 154 |

**Por tradutor** (marcadores brasileiros mais de 3 vezes acima dos europeus em toda a produção dele):

- **271.824 pares (90%) vêm de tradutores majoritariamente brasileiros.**
- 17.361 (5,7%) vêm de tradutores europeus. Cangarejo, por exemplo, se declara de Portugal.
- O resto é misto ou tem amostra pequena.

**Há tradutores que fazem as duas variantes.** carlosalberto tem 8.905 marcadores brasileiros e 2.333 europeus. Por isso o filtro precisa ser **por frase, além de por tradutor**.

Exemplos europeus reais nos pares:

- "Ela quer que tu lhe laves o carro."
- "Ela está em dívida para contigo."
- "Eu tenho uma volta para dar." (para *I have to take a walk*)
- "até à África"

#### 2.5.5 Monotonia e temas

- **Tom/Mary:** 51.825 frases EN dos pares (21,4%) têm *Tom* ou *Mary*, e 34.367 (14,2%) começam com *Tom*.
- **Nomes de "séries" de um contribuidor** (Sami, Layla, Fadil, Ziri, Yanni...): 2.404 frases, com histórias de crime em parte delas.
- **Vocabulário violento** (*kill, murder, gun, dead, suicide, stab, shot*): 1.545 frases.
- **Quase-duplicatas reais são poucas.** Trocando os nomes, sobram 242.066 frases distintas de 242.306. A monotonia é de nomes e de tom, não de cópia.

#### 2.5.6 Tipografia e grafia (para um curso de digitação)

- **Tipografia:** 2.580 frases EN dos pares têm caracteres fora do ASCII. São `’` (1.435), `—` (1.003), `“ ”` (518 e 516), `–` (117), acentos (*café*), espaço zero-width (42) e espaço inseparável (16). Filtrar ou normalizar segundo as regras do dossiê 06.
- **Grafia:** numa lista de marcadores, as formas americanas aparecem 1.248 vezes e as britânicas 182. O inglês do Tatoeba é majoritariamente americano, mas misturado. Aplicar a regra en-US do dossiê 04.

#### 2.5.7 Datas e IA

- **Regra do Tatoeba:** "**Do not add sentences generated by artificial intelligence.** Generative artificial intelligence ... does not respect copyright. It also violates Tatoeba's central purpose of providing sentences generated directly by humans" ([Rules and Guidelines](https://en.wiki.tatoeba.org/articles/show/guidelines)).
- **Mesmo com a regra, uso um corte em 1º/dez/2022** (lançamento do ChatGPT) como seguro. Das frases EN dos pares, 15.489 (6,4%) foram criadas de 2023 em diante.
- **Consequência para nós:** nunca contribuir de volta ao Tatoeba frases geradas por IA para o curso.

#### 2.5.8 Auditoria manual (60 pares sorteados entre as candidatas A1–B1 já filtradas)

| Resultado | n | Exemplos reais |
|---|---|---|
| OK, natural nos dois lados | 52 | *"I haven't eaten Chinese food in a while."* → "Faz tempo que não como comida chinesa." |
| **Erro de sentido** | **2** | *"Tom often wears a fake wedding ring."* → "O Tom **de vez em quando** usa..." (*often* ≠ de vez em quando)<br>*"I think you might eventually change your mind."* → "...você pode, **eventualmente**, mudar de idéia" (falso cognato) |
| Ortografia PT | 2 | "meio dia" (meio-dia); "idéia" (pré-Acordo) |
| Tradução dura | 4 | "Você parece estar ocupado."; "Nunca esqueceremos o Tom."; "Quando você terminará sua tarefa?"; "objetivos para mim mesmo" |
| Inconsistência de nome | 2 | *Mary* → "Maria" |

**Estimativas com IC 95% de Wilson:**

- **Erro de sentido:** 2/60 = 3,3%, IC de 0,9% a 11,4%. Projetado nas 85 mil candidatas, são **centenas a alguns milhares de pares** com sentido trocado.
- **"Precisa de ajuste"** (sentido, ortografia ou dureza): 8/60 = 13%, IC de 7% a 24%.

**Outros erros achados em buscas pontuais dentro das candidatas filtradas:**

- *"If I were you, I wouldn't do that kind of thing."* → "Se eu fosse você, eu faria esse tipo de coisa." (**negação perdida**)
- *"I don't eat as much meat as I used to."* → "Não como mais tanto quanto eu costumava." (some *meat*)
- *"I hope that you had a wonderful day."* → "Eu **esperava** que você tivesse um dia maravilhoso." (muda o sentido)
- *"We might go."* → "Nós podemos ir." (perde a incerteza)
- *"This is never going to end."* → "Isso nunca acaba." (perde o futuro)

**Conclusão:** o inglês do CK e de nativos é muito confiável. **O português precisa passar pela camada T do checklist em 100% dos casos.**

### 2.6 Funil aplicado e o que sobra

| Etapa (cumulativa) | Pares | Frases EN distintas |
|---|---|---|
| 0. Ligações diretas EN–PT | 302.059 | 242.305 |
| 1. Dono do EN nativo (nível 5) | 221.260 | 173.484 |
| 2. Tradutor PT majoritariamente brasileiro | 138.399 | 111.971 |
| 3. Frase PT sem marcador europeu (regex) | 135.463 | 110.145 |
| 4. EN e PT criadas antes de 01/12/2022 | 128.088 | 103.509 |
| 5. Sem tag Tanaka, `@change`, `@check`, `@needs native check`, arcaico, vulgar, sexual | 111.494 | 89.299 |
| 6. Sem tema sensível nem nomes de "série" | 109.814 | 87.889 |
| 7. 3 a 14 palavras, só ASCII digitável | 106.625 | **85.460** |

Escolhendo uma tradução por frase (a mais curta), o nível lexical estimado pelo CEFR-J/Octanove fica assim:

| Nível lexical | Todas as 85.460 | Sem Tom/Mary |
|---|---|---|
| A1 | 47.038 | 27.237 |
| A2 | 19.433 | 11.349 |
| B1 | 9.731 | 5.719 |
| B2 | 3.496 | 2.046 |
| C1 / C2 | 353 / 68 | 208 / 41 |
| palavra fora das listas | 5.341 | 3.441 |

**Cobertura por chunk** (entre as candidatas; o número após "A1–A2 sem Tom/Mary" é a contagem nesse recorte):

| Chunk | Candidatas | A1–A2 sem Tom/Mary |
|---|---|---|
| *I'd like* | 199 | 134 |
| *How much* | 148 | 110 |
| *Can I* | 177 | 147 |
| *Have you ever* | 124 | 78 |
| *I'm going to* | 317 | 252 |
| *I used to* | 101 | 63 |
| *If I were* | 15 | 9 |
| *bug* | 8 | 5 |
| *deploy* | 1 | 0 |
| *pull request* | 0 | 0 |

**Ou seja: para o inglês geral A1–B1 quase sempre há âncora humana; para o inglês de dev, não.**

**Arquivo gerado:** `fontes07/tatoeba_candidatas_en_ptbr.tsv`, com colunas `nivel_lexical, en_id, en, en_dono, pt_id, pt, pt_dono, palavras, audio_en, tem_tom_mary`. É insumo para o desenhista, não conteúdo pronto: o PT ainda precisa da camada T.

### 2.7 Balanço do Tatoeba para o PAC·English

| A favor | Contra |
|---|---|
| Humano, conversacional, curto (79% das frases EN dos pares têm de 4 a 10 palavras) | Sem progressão, sem cenas, sem controle de "1 item novo" |
| Licença comercial simples (CC BY) | Atribuição por frase recomendada |
| Inglês de nativos revisado por CK (lista 907) | Metade de um único autor, com estilo e nomes repetitivos (Tom/Mary) |
| Proíbe IA, o que dá uma referência "limpa" para checar naturalidade | O PT mistura variantes e tem erros de sentido (3% na amostra) |
| Export semanal, API, IDs estáveis | Dev e tecnologia quase ausentes |
| | Áudio com licença inviável |

---

## 3. Outras fontes avaliadas

| Fonte | Licença ou termos (lidos) | Como conteúdo do curso | Para checar naturalidade | Veredito |
|---|---|---|---|---|
| **OpenSubtitles (via OPUS)** | O OPUS pede "add a link to http://www.opensubtitles.org/" e citação (Lison & Tiedemann 2016). **Não declara licença** ([OPUS](https://opus.nlpl.eu/legacy/OpenSubtitles-v2018.php)). As legendas derivam de obras audiovisuais protegidas. v2024 en–pt: 68.557.861 pares ([OPUS API](https://opus.nlpl.eu/opusapi/?corpus=OpenSubtitles&source=en&target=pt&preprocessing=moses&version=latest)) | **Não** | Só estatística: frequência de palavras e n-gramas (ex.: listas *FrequencyWords*, CC BY-SA 4.0, [GitHub](https://github.com/hermitdave/FrequencyWords)) | Fora do conteúdo |
| **Wikipedia / Simple English Wikipedia** | CC BY-SA 4.0 + GFDL. Exige atribuição. Adaptações saem sob a mesma licença ([Copyrights](https://en.wikipedia.org/wiki/Wikipedia:Copyrights)) | Não: registro enciclopédico | Fraco para conversa | Fora |
| **Mozilla Common Voice (frases)** | Textos em CC0: "user submissions ... or scraped from Wikipedia ... released under a CC0 public domain" ([README](https://github.com/common-voice/common-voice)) | Não: frases de leitura, em boa parte da Wikipedia | Fraco | Fora |
| **VOA Learning English** | "Learning English texts, MP3s, photos and videos are in the public domain", exceto material de agências como AP, Reuters e AFP. Crédito a learningenglish.voanews.com ([VOA](https://learningenglish.voanews.com/p/6861.html)) | Possível em B1–B2 (notícia graduada), não para conversa. Já há 1.768 frases "voanews.com" nos pares do Tatoeba | Médio (notícia) | Opcional em B1+, com crédito |
| **DailyDialog** | CC BY-NC-SA 4.0 ([HF](https://huggingface.co/datasets/li2017dailydialog/daily_dialog)) | **Não** (NC e SA) | Uso interno de pesquisa | Fora |
| **Decks públicos do AnkiWeb** | "Shared Deck License ... to use the material in your personal studies. This license is for **personal use only**, and the deck may not be redistributed, re-uploaded, published, or used for any other purposes without explicit permission" ([AnkiWeb Terms](https://ankiweb.net/account/terms)) | **Não**, salvo permissão expressa do autor | Não | Fora |
| **Decks do ManyThings (Tatoeba)** | Herdam CC BY. Vale o alerta "There are errors in the Tatoeba Corpus" ([ManyThings](https://www.manythings.org/anki/)) | Igual ao Tatoeba, mas melhor ir à fonte (IDs e atualização semanal) | — | Usar o Tatoeba direto |
| **COCA** | "free to search for registered users", "available only through the web interface, due to copyright restrictions". Cerca de 1 bilhão de palavras, 1990–2019, com TV/filmes, fala e ficção ([Wikipedia](https://en.wikipedia.org/wiki/Corpus_of_Contemporary_American_English)) | **Não** (não copiar exemplos) | **Sim, manual** (o revisor humano consulta) | Consulta manual |
| **Google Books Ngram** | Dataset sob "Creative Commons Attribution 3.0 Unported" ([datasets](https://storage.googleapis.com/books/ngrams/books/datasetsv3.html)). Corpora `eng`, `eng_us`, `eng_gb`, `eng_fiction`, n-gramas em pelo menos 40 livros ([info](https://books.google.com/ngrams/info)) | Não (são n-gramas) | **Sim, automatizável** (endpoint JSON testado, seção 5.3) | Usar, com crédito |
| **Netspeak** | Mantido pelo grupo Webis (código MIT no [GitHub](https://github.com/netspeak)). Corpus `web-en`. Não achei termos de uso publicados | Não | **Sim, automatizável** (gRPC-web testado, seção 5.2) | Usar com cache e moderação |
| **SkELL** (Sketch Engine for Language Learning) | "No registration or payment required". "Multi-billion" palavras de notícias, Wikipedia, livros abertos, web ([SkELL](https://www.sketchengine.eu/skell/)) | Não | Sim, manual (exemplos, word sketch) | Consulta manual |
| **Ludwig.guru** | Não verificado nesta sessão (bloqueio Cloudflare). Buscador pago de frases em fontes editoriais | Não | Manual | Opcional, pago |
| **YouGlish** | Busca de pronúncia em vídeos do YouTube, com API listada no site ([youglish.com](https://youglish.com/)) | Não | Manual (ouvir o chunk em contexto) | Consulta manual |
| **Dicionários** (Oxford, Cambridge, Longman, Collins, Merriam-Webster) | Proprietários | **Não copiar exemplos** | Manual | Consulta |
| **Listas de frequência e de nível** (NGSL, CEFR-J, Octanove, SUBTLEX, wordfreq) | Ver dossiê 03. Complementos lidos aqui: CEFR-J permite uso "for research and commercial purposes with no charge" com citação; Octanove C1/C2 é CC BY-SA 4.0 ([README](https://github.com/openlanguageprofiles/olp-en-cefrj)); wordfreq congelado em 2021 porque "Generative AI has polluted the data" ([SUNSET](https://github.com/rspeer/wordfreq/blob/master/SUNSET.md)) | — | **Sim:** checar o nível lexical de cada frase | Usar no revisor (build) |
| **CEFR-SP** (17 mil frases com nível CEFR atribuído por professores) | Por parte: Wiki-Auto CC BY-SA 3.0, SCoRE CC BY-NC-SA 4.0, Newsela sob acesso ([README](https://github.com/yukiar/CEFR-SP)) | Não | Sim: calibrar ou treinar um classificador de nível de frase (uso interno) | Opcional |

**Regra derivada:** o conteúdo do curso só pode ter duas origens, **Tatoeba (com atribuição) ou autoral**. Esta é uma emenda à regra 1 do dossiê 03 ("toda frase é original"). O Tatoeba é a única exceção, e se justifica porque a licença é CC BY sem SA.

---

## 4. Riscos de frases geradas por IA

### 4.1 O que a pesquisa mostra

- **Exemplos de dicionário feitos por IA perdem para os humanos.** [Lew (2023)](https://doi.org/10.1057/s41599-023-02119-6) comparou, às cegas, verbetes estilo COBUILD gerados pelo ChatGPT com os originais, em 15 verbos. Definições: IA 3,6 contra COBUILD 3,9. **Exemplos: IA 3,3 ("Passable") contra COBUILD 4,2 ("Good").** Comentários dos especialistas:
  - "Redundancy—examples repeat exactly the same pattern"
  - "last example is unconvincing, looks unnatural"
  - "examples are dull and samey"
  - "clunky past-tense examples"
  - "only past forms of the verb in the examples"

  Com prompt refinado a partir desse feedback, os exemplos melhoraram ("authentic-sounding and accessible"). **O ganho vem de instrução e revisão, não do modelo cru.**
- **Exemplos bilíngues gerados por LLM são aceitáveis, mas os humanos discordam entre si.** [Merx, Vylomova & Kurniawan (2024)](https://arxiv.org/abs/2410.03182) avaliaram pelos critérios GDEX (típico, informativo, inteligível). Os exemplos são "reasonably good" em línguas com muitos recursos, como o inglês. O estudo encontra "low inter-annotator agreement", e a **perplexidade de um modelo pré-treinado é "a good proxy for typicality and intelligibility"**.
- **Há um quadro de avaliação para exemplos do ChatGPT.** [Lyu, Liu & Jablonkai (2026, IJL)](https://doi.org/10.1093/ijl/ecag029) estendem Kilgarriff et al. (2008) com completude, saliência, inteligibilidade, informatividade, tipicidade, diversidade, complexidade e sensibilidade. Concluem que o ChatGPT tem potencial "for scalable, quality-controlled use", ou seja, com controle de qualidade.
- **O GDEX é a referência clássica de "bom exemplo".** [Sketch Engine](https://www.sketchengine.eu/guide/gdex/); [Kosem et al. 2018](https://doi.org/10.1093/ijl/ecy014). Critérios: frase inteira (maiúscula no início, pontuação final), comprimento ótimo (10–14 palavras no dicionário), palavras frequentes, sem anáfora solta, sem tabus, pontuação e maiúsculas sem excesso.
- **O estilo dos LLMs difere do humano de forma mensurável.** [Reinhart et al. (2025, PNAS)](https://doi.org/10.1073/pnas.2422455122) usaram os traços de Biber ([versão arXiv](https://arxiv.org/html/2410.16107) com os números):

  | Traço | Modelos instruídos | GPT-4o |
  |---|---|---|
  | Orações de particípio presente | 2 a 5 vezes o humano | 5,3 vezes |
  | Nominalizações | 1,5 a 2 vezes | 2,1 vezes |
  | *that*-clauses como sujeito | — | 2,6 vezes |
  | Coordenação de sintagmas | — | 1,9 vezes |
  | Passiva sem agente | — | cerca de metade da humana |

  E: "instruction tuning introduces more extreme grammatical differences".
- **Palavras "de IA" são infladas.** Kobak et al. estimam que pelo menos 13,5% dos resumos biomédicos de 2024 passaram por LLM, com palavras em excesso como *delves, showcasing, underscores* ([Science Advances 2025 / arXiv](https://arxiv.org/abs/2406.07016)). [Juzek & Ward (2024)](https://arxiv.org/abs/2412.11385) acham 21 palavras focais (*delve, intricate, underscore*...) e sinais de que o RLHF contribui.
- **Tradução de LLM puxa para o literal.** [Li et al. (2025)](https://arxiv.org/abs/2503.04369) mostram que LLMs "frequently generate overly literal and unnatural translations" e atribuem isso ao fine-tuning supervisionado. [Valentini et al. (2026)](https://arxiv.org/abs/2608.17399) investigam se a geração multilíngue de LLMs carrega traços de texto traduzido.
- **A web está "poluída".** O wordfreq foi congelado porque "the Web at large is full of slop generated by large language models" ([SUNSET](https://github.com/rspeer/wordfreq/blob/master/SUNSET.md)). **Corpora de referência devem ser anteriores a 2022.** Isso favorece Tatoeba (com corte de data), COCA (1990–2019) e Google Books Ngram (versão 2020, livros até 2019).

### 4.2 Tipologia de defeitos "LLM-ish" em frases de curso

| Família | Como aparece em frase curta de curso | Exemplo ruim → melhor |
|---|---|---|
| **Vocabulário inflado** | Palavras de redação em situação de conversa | *"Let's delve into the vibrant streets of the city."* → *"Let's walk around downtown."* |
| **Particípio no fim** | ", making it...", ", allowing us to..." | *"I moved closer to work, making my mornings easier."* → *"I moved closer to work, so my mornings are easier."* |
| **Perfeição artificial** | Sem contrações, resposta completa demais | *"Yes, I do like coffee very much."* → *"Yeah, I love it."* |
| **Monotonia** | Mesmo padrão, mesmo tempo verbal, mesma abertura (Lew 2023) | 10 frases "I + passado" seguidas |
| **Genérico e positivo demais** | Frases que ninguém diria, sem situação | *"The weather is beautiful and everyone is happy."* |
| **Nomes "de IA"** | Sarah, Emily, Alex em todo lugar | variar nomes com critério (TTS, dossiê 06) |
| **Colocação quase certa** | Verbo leve errado, preposição de PT | *make a party, explain me, depend of, married with* |
| **Variante trocada** | Britanismo num curso en-US | *at the weekend, have got, in hospital* |
| **PT literal (translationese)** | Sujeito "Eu" sempre explícito, futuro sintético, possessivo demais | "Eu terminarei meu trabalho." → "Vou terminar o trabalho." |
| **PT de Portugal** | Modelos misturam pt-PT | "Estou a fazer", "pequeno-almoço", "contigo" |
| **Falso cognato no PT** | *eventually* → "eventualmente", *actually* → "atualmente" | — |
| **PT ambíguo para recordar** | Um PT que leva a vários EN igualmente certos | "Vamos sair." → *We're going out.* / *Let's go out.* |
| **Fato errado ou datado** | "Venus is the largest planet", telegrama | — |

### 4.3 O que a IA faz bem (para equilibrar)

- **Controle de vocabulário e de estrutura por nível.** Gerar 20 variações de *Can I...?* só com palavras A1 é trivial.
- **Volume e cobertura de temas que o Tatoeba não tem:** dev, trabalho remoto, viagem moderna, apps.
- **Cenas e micro-diálogos coerentes,** pedidos pelos dossiês 02 e 05.
- **Gramática quase sempre correta em frases curtas.** O defeito típico é de naturalidade e de tradução, que é justamente o que o checklist ataca.

---

## 5. Técnicas para checar naturalidade (com testes desta sessão)

### 5.1 Atestação de trigramas contra o inglês humano do Tatoeba

**Referência:** frases EN de donos nativos, criadas antes de dez/2022, no total **1.270.656 frases**. Normalização: minúsculas, dígitos viram `NUM` e nomes próprios viram `PROP`. Cada frase é envolvida em `<s> ... </s>`, e conto quantos de seus trigramas aparecem na referência.

| Frase testada | Trigramas atestados | Ausentes | Correto? | O teste acertou? |
|---|---|---|---|---|
| I'm looking forward to seeing you. | 6/6 | — | sim | sim |
| I look forward to see you. | 5/6 | *forward to see* | não | **sim** |
| I have 20 years. | 3/4 | *have NUM years* | não | **sim** |
| I'm 20 years old. | 4/4 | — | sim | sim |
| I am living in Brazil since 2010. | 7/7 | — | não | **não** (erro de tempo) |
| I've been living in Brazil since 2010. | 7/7 | — | sim | sim |
| Let's delve into the vibrant tapestry of this city. | 3/9 | 6 trigramas | "LLM-ish" | **sim** |
| Can you explain me this? | 4/5 | *explain me this* | não | **sim** |
| Can you explain this to me? | 6/6 | — | sim | sim |
| She is married with a doctor. | 6/6 | — | não | **não** (cada trigrama existe em outro contexto) |
| She's married to a doctor. | 5/5 | — | sim | sim |
| I'm going to make a party on Saturday. | 7/8 | *make a party* | não | **sim** |
| I'm having a party on Saturday. | 6/6 | — | sim | sim |

**Leitura dos resultados:**

- O teste pegou 5 de 7 erros e o texto inflado, sem falso positivo nas frases corretas (depois da normalização; sem ela, *I'm 20 years old* daria alarme falso).
- **Ele não pega erro de tempo verbal nem colocação "montada" com peças comuns.** Para isso entram as regras G02 e G03 e os juízes.
- **É triagem barata e local:** roda em segundos, sem rede, sobre um corpus CC BY e humano.

### 5.2 Netspeak (frequência web por janela, com alternativas)

Netspeak é um buscador de n-gramas do grupo Webis. A interface usa gRPC-web, e escrevi um cliente mínimo sem dependências (`fontes07/netspeak.py`, seção 9).

- **Serviço:** `https://ngram.api.netspeak.org/netspeak.service.NetspeakService/Search`, com corpora `web-en` e `web-de`.
- **Operadores:**
  - `?` = uma palavra qualquer
  - `*` = zero ou mais palavras
  - `[ a b c ]` = alternativas
- **Limite observado:** consultas de 6 palavras voltam vazias. Na prática, trabalhe com janelas de até 5 palavras.

Resultados reais (ocorrências no `web-en`):

| Consulta | Resultado |
|---|---|
| `make a decision` / `take a decision` / `do a decision` | 1.257.138 / 103.385 / 226 |
| `[ make take do ] a mistake` | make 619.576 · do 1.080 · take 272 |
| `I look forward to ?` | hearing 197.324 · seeing 193.704 · the 184.764 · working 147.652 |
| `explain me` / `explain to me` | 57.887 / 424.489 |
| `depend of` / `depends on` | 25.784 / 21.724.212 |
| `discuss about` | **159.463** (erro comum de não nativos, presente na web) |
| `married to her` / `married with her` | 112.382 / 2.674 |
| `[ in on at ] the weekend` | on 532.378 · at 384.451 · in 72.038 |
| `I have 20 years` / `I am 20 years` | 4.901 / 17.468 (a 1ª aparece em *"I have 20 years of experience"*) |
| `? to meet you` | nice 318.995 · pleased 135.262 · glad 81.117 · pleasure 53.529 |
| `[ make have throw give ] a party` | have 250.937 · throw 71.307 · **make 27.263** · give 26.859 (o erro de brasileiro tem 10,9% da melhor forma) |

**Lições:**

1. **Frequência absoluta não basta.** A web tem texto de não nativos: *discuss about* soma 159 mil. **Use a razão entre a forma usada e a melhor alternativa no mesmo slot.**
2. **A web mistura en-US e en-GB** (*at the weekend*). Para variante, use o Google Ngram por país (5.3).
3. **Contexto importa.** *I have 20 years* existe, mas como parte de outra construção. A janela deve incluir o fim da frase (`have NUM years .`) ou a regra G02 decide.

### 5.3 Google Books Ngram (variante, registro escrito, CC BY 3.0)

O endpoint JSON (não oficial, mas estável e usado pelo próprio site) foi testado:

```
https://books.google.com/ngrams/json?content=on+the+weekend,at+the+weekend&year_start=2015&year_end=2019&corpus=en-US&smoothing=0
```

| Consulta (média 2015–2019, frequência relativa) | en-US | en-GB |
|---|---|---|
| *on the weekend* | 4,63e-07 | 2,66e-07 |
| *at the weekend* | 1,05e-07 | **7,92e-07** |
| *make a decision* (corpus `en`) | 1,74e-06 | — |
| *take a decision* (corpus `en`) | 1,11e-07 | — |
| *do a decision* (corpus `en`) | 2,2e-10 | — |

**Uso no revisor:** para expressões suspeitas de variante, exigir que a forma usada não seja muito mais britânica que americana (regra N02b). Limites:

- **É registro de livro**, que subestima a fala.
- **O endpoint pode mudar.** O dataset completo (CC BY 3.0) pode ser baixado se for preciso independência.

### 5.4 LanguageTool (gramática EN e "brasileirismo" no PT)

Testei a API pública (`https://api.languagetool.org/v2/check`).

**EN** (*"I have 20 years and I am living in Brazil since 2010. I look forward to see you."*): pegou `ADMIT_ENJOY_VB` (*to see* → *to seeing*) e um aviso de vírgula. **Não pegou** *I have 20 years* nem o tempo errado com *since*.

**PT** com `language=pt-BR` (*"Eu estou a fazer o pequeno-almoço na casa de banho com o meu telemóvel."*): pegou `PT_BR_SIMPLE_REPLACE_PEQUENO_ALMOÇO`, `..._CASA_DE_BANHO` e `..._TELEMÓVEL` ("expressão usada sobretudo em Portugal"). **Não pegou** "estou a fazer".

**Limites da API pública:** "20 requests per IP per minute", "75KB text per IP per minute", "20KB text per request" ([public API](https://dev.languagetool.org/public-http-api)). O LanguageTool é LGPL-2.1 ([GitHub](https://github.com/languagetool-org/languagetool)). **Para o revisor, rodar um servidor próprio (Docker) e somar regex próprias** para "estar a + infinitivo", ênclise coloquial e a lista do dossiê 04.

### 5.5 Ferramentas manuais (para o revisor humano ou para dúvidas pontuais)

- **COCA:** frequência por gênero (TV/filmes, fala, ficção) e colocações. Responde se aquilo é falado ou escrito. Só pela interface web.
- **SkELL:** até 40 exemplos e o *word sketch*, gratuito, bom para ver a colocação típica de um verbo.
- **YouGlish:** ouvir o chunk em vídeos reais. Útil para confirmar redução e entonação de *gonna, wanna, kind of*.
- **Ludwig:** buscador pago de frases editoriais. Opcional.

### 5.6 Perplexidade (opcional)

Merx et al. (2024) mostram que a perplexidade de um modelo pré-treinado aproxima bem "típico" e "inteligível" em inglês. Uma variante barata:

- Calcular a perplexidade por token de cada frase num modelo pequeno local, como GPT-2.
- Comparar com a distribuição das frases do Tatoeba do mesmo comprimento.
- Avisar acima do percentil 95.

Exige Python com `transformers`, por isso fica como v2.

### 5.7 Revisão adversarial "nativo" (juiz LLM)

Protocolo recomendado:

1. **Dois julgamentos independentes** (prompts diferentes, temperatura baixa), cada um com persona de "professor americano de ESL, nativo, chato com naturalidade".
2. **Tarefa reescrever, não "está bom?"** O modelo diz "sim" fácil demais. Peça: "Rewrite it exactly as a native speaker would say it in this situation; if nothing should change, return it identical".
3. **Diferença material** (além de pontuação ou maiúscula) nas duas reescritas → **AJUSTAR** com a sugestão. Em só uma → **AVISO**, que vai para um terceiro juiz ou para a fila humana.
4. **Pedir sempre a situação** ("who says this to whom, where?"). Se não existe situação plausível, a frase é "unlikely" (critério do Tatoeba e do GDEX).
5. **Teste de detectabilidade por lote** (regra D06). Misture 20 frases nossas com 20 do Tatoeba (humanas, pré-2022) e peça ao juiz para apontar as que parecem de máquina. Se ele acerta muito acima do acaso, o estilo do gerador precisa mudar.

A concordância entre humanos é baixa (Merx 2024). Por isso: **dois juízes, regra de decisão explícita e calibração num conjunto-ouro** (seção 8.5).

### 5.8 Retro-tradução e determinismo PT→EN

No curso, a tradução fica em cima. Nas passadas de recordação (o inglês some, dossiês 01 e 05), o aluno **produz o EN a partir do PT**. Então o PT precisa **levar a um EN único**, ou as variantes precisam estar declaradas (dossiê 04, item 3). Teste:

- **Um modelo que nunca viu o EN** traduz o PT para inglês três vezes.
- **Se a frase-alvo (ou uma variante declarada) não aparece em nenhuma** e as traduções concordam entre si num EN diferente, o PT está puxando para outro lugar. Então: ajustar o PT, adicionar pista (contexto ou glosa) ou declarar a variante.
- **O mesmo teste pega erro de sentido:** se a retro-tradução diz *"I would do that"*, a negação sumiu.

### 5.9 Regras de estilo (fontes convergentes)

- **Tatoeba, "How to Write Good Sentences"** ([wiki](https://en.wiki.tatoeba.org/articles/show/how-to-write-good-sentences)): clara, autocontida ou com contexto fácil de imaginar, provável ("Colorless green ideas sleep furiously" é o contraexemplo), dialeto padrão atual, natural e sem chance de ofender.
- **Naturalidade, segundo a mesma página:** sem repetição que o nativo evita, com paralelismo completo e sem palavra que o nativo omitiria (*"We drank grape wine"*). **Sem *comma splice* em inglês.**
- **Diversidade:** variar nomes e situações em vez de "Tom works in a skyscraper..." ×10.
- **Rules and Guidelines** ([wiki](https://en.wiki.tatoeba.org/articles/show/guidelines)): frase completa, tradução natural e não palavra a palavra, "sentences that a native speaker would actually use", sem alternativas na mesma frase (*He/she*), sem anotações dentro da frase e sem pessoas reais que não sejam públicas.
- **GDEX:** frase inteira, comprimento-alvo, vocabulário frequente, sem anáfora sem antecedente e sem tabu.
- **Formato e teclado:** dossiê 06, seção B8. **Interferência e tradução:** dossiê 04, seções 4 e 6.

---

## 6. Recomendação: misto, com papéis definidos

### 6.1 Por que não só autoral, e por que não só Tatoeba

- **Só Tatoeba:** não dá para montar a progressão (1 item novo por frase, espiral, cenas), não cobre dev e o PT exige revisão total. O curso viraria "frases aleatórias por nível".
- **Só IA:** o risco documentado é a naturalidade (Lew: 3,3 contra 4,2) e a monotonia. Sem âncora humana, o revisor automático não tem contra o que medir "isso soa nativo".
- **Misto:** a progressão vem da autoria (blocos do dossiê 02). O inglês vem do Tatoeba sempre que houver frase que caiba no slot, e da IA quando não houver. O Tatoeba nativo pré-2022 ainda serve como **corpus de referência** do revisor.

### 6.2 Papéis

| Papel do Tatoeba | Como |
|---|---|
| **A. Âncora de redação** | Para cada slot ("bloco A1.07, chunk *Can I...?*, vocabulário permitido X"), buscar no TSV de candidatas as frases que contêm o chunk e respeitam o nível. Mostrar ao redator (humano ou LLM) como "inglês real de referência". |
| **B. Fonte direta** | Se uma candidata encaixa no slot (nível, 1 item novo, tema), **adotar verbatim** com atribuição, ou **adaptar** (trocar nome ou objeto) com nota "adaptada". O PT pode ser aproveitado se passar na camada T; senão, reescrever e marcar `pt_autoral: true`. |
| **C. Corpus de referência do revisor** | Atestação de trigramas (N01) contra 1,27 milhão de frases nativas pré-2022. Fica só no build, nada vai para o app. |
| **D. Treino extra e revisão** | Modo "Frases do mundo" com sorteio entre as candidatas do nível já liberado (filtradas, sem Tom/Mary em excesso, PT revisado). Dá volume sem custo de autoria. |

| Papel da autoria (IA + revisão) | Como |
|---|---|
| **Espinha dorsal das lições novas** | Frases escritas para a especificação do bloco (02), o vocabulário (03) e as interferências (04), em cenas e micro-diálogos (05). |
| **Tudo que o Tatoeba não tem** | Dev, apps, trabalho remoto, situações atuais, frases para interferências brasileiras específicas (BR01–BR60). |
| **Tradução PT-BR final** | Toda frase, de qualquer origem, termina com PT revisado pela camada T. |

### 6.3 Fluxo de produção (por lote de lição)

1. **Especificação do slot**, vinda do 02, 03 e 04: nível, chunk ou estrutura nova, vocabulário permitido, tema e cena, etiquetas BR.
2. **Busca de âncoras** em `tatoeba_candidatas_en_ptbr.tsv`: chunk + nível ≤ alvo + sem Tom/Mary em excesso. Ficar com as 5 melhores (mais curtas, mais frequentes).
3. **Redação**, nesta ordem de preferência: (a) adotar, (b) adaptar, (c) escrever. Na opção (c), o prompt do gerador inclui as âncoras como exemplos de estilo e a lista negra da regra N03.
4. **Tradução PT-BR:** reaproveitar a do Tatoeba se estiver no padrão brasileiro e for fiel; senão, escrever segundo as regras do 04.
5. **Revisor automático** (seção 8): aprovado, ajustar ou rejeitar, com evidência.
6. **Juízes adversariais** (N07, T03, T04) nas frases com aviso e em **10% das aprovadas** (amostra de controle).
7. **Validação do dono do curso** numa amostra pequena por lição, focada no PT. Ele é brasileiro e não nativo de inglês, então não é a autoridade sobre o inglês.
8. **Telemetria pós-lançamento.** Frases em que muitos alunos travam sempre na mesma palavra ou digitam sistematicamente outra forma podem estar estranhas ou ambíguas, e voltam para a fila de revisão.

### 6.4 Proporções sugeridas (ponto de partida)

| Faixa | Lições novas | Treino extra |
|---|---|---|
| A1–A2 | Meta de **≥ 40% das frases adotadas ou adaptadas do Tatoeba** (há âncora para quase todo chunk geral) | 100% Tatoeba filtrado |
| B1–B2 | Cerca de 20–30% do Tatoeba (menos frases, mais longas, mais Tom/Mary) | 100% Tatoeba filtrado |
| Dev e tecnologia | **100% autoral** | autoral |
| Cenas e diálogos | Majoritariamente autoral; frases do Tatoeba podem ser "costuradas" quando encaixam | — |

---

## 7. Atribuição obrigatória (modelo concreto)

### 7.1 Campos por frase (complementa a ficha do dossiê 04, seção 4.4)

```json
{
  "id": "en-a1-012",
  "en": "Can I pay by card?",
  "pt": "Posso pagar com cartão?",
  "origem": "tatoeba",
  "fonte": {
    "en_id": 1234567,
    "en_autor": "CK",
    "pt_id": 7654321,
    "pt_autor": "alexmarcelo",
    "pt_autoral": false,
    "licenca": "CC BY 2.0 FR",
    "modificada": false,
    "nota_modificacao": null,
    "export": "2026-10-03"
  }
}
```

(IDs ilustrativos. Use os reais do export.)

| Campo | Valores e regra |
|---|---|
| `origem` | `tatoeba`, `tatoeba_adaptada`, `autoral_ia` ou `autoral_humana` |
| `modificada` | `true` sempre que o EN ou o PT for alterado. `nota_modificacao` diz o quê, por exemplo "nome trocado de Tom para Ana" ou "PT reescrito" |
| `pt_autoral` | `true` quando o PT não é do Tatoeba. Nesse caso `pt_id` e `pt_autor` ficam `null` |

### 7.2 Tela "Créditos e fontes" do curso de inglês (texto sugerido)

> Algumas frases deste curso vêm do **Tatoeba** (https://tatoeba.org), um acervo colaborativo de frases e traduções, publicadas sob a licença **Creative Commons Atribuição 2.0 França (CC BY 2.0 FR)** — https://creativecommons.org/licenses/by/2.0/fr/. Cada frase de origem Tatoeba mostra o número e o autor originais; as marcadas como "adaptada" foram modificadas por nós (por exemplo, troca de nome ou nova tradução). Autores das frases usadas: CK, alexmarcelo, Ricardo14, … (lista gerada automaticamente com a contagem de frases de cada um).

- **Por frase:** um "ⓘ fonte" discreto com "Tatoeba nº 1234567 · CK · CC BY 2.0 FR" e link `https://tatoeba.org/pt-br/sentences/show/1234567`. Se adaptada, "adaptada de Tatoeba nº ...".
- **Listas e dados usados no app:** se o app embutir NGSL (CC BY-SA 4.0) ou Octanove (CC BY-SA 4.0), citar com link da licença. Se embutir CEFR-J, citar "The CEFR-J Wordlist Version 1.5, compiled by Yukio Tono, TUFS". Se só o revisor de build usar, citar no README do repositório de conteúdo.
- **Google Books Ngram:** só no build. A fonte pede crédito ("acknowledgement ... would be appreciated", segundo o README do wordfreq) e o dataset é CC BY 3.0. Citar no README.
- **VOA Learning English, se usado:** "Fonte: learningenglish.voanews.com (domínio público)".
- **Atualização:** o Tatoeba corrige frases continuamente, e a própria wiki recomenda "frequently update your project". Um script de build pode comparar o texto guardado com o export da semana e listar divergências (regra P03).

---

## 8. CHECKLIST DO REVISOR AUTOMÁTICO (entregável)

### 8.1 Como usar

**Entrada:** uma frase por vez (ficha JSON do dossiê 04 + campos da seção 7.1) e o contexto do lote (lição, nível, "já visto", outras frases da lição).

**Recursos que o revisor precisa ter à mão:**

| Recurso | Para quê |
|---|---|
| `REF_TRIGRAMAS` | contagens de trigramas normalizados do Tatoeba EN nativo pré-2022 (gerar com `trigramas.py`) |
| CEFR-J 1.5 + Octanove C1/C2 | nível lexical (já em `pesquisa/fontes/`) |
| LanguageTool | servidor próprio, `en-US` e `pt-BR` |
| `netspeak.py` | frequências web por janela |
| Google Ngram JSON | variante en-US × en-GB |
| Listas do dossiê 04 | BR01–BR60, falsos cognatos (anexo A), regência (anexo B), ortografia (anexo C) |
| Validador de formato | dossiê 06, seção B8 |
| Dois juízes LLM | prompts da seção 8.4 |

**Severidades:**

- **BLOQUEIA:** a frase não entra como está.
- **AJUSTAR:** precisa de mudança, com sugestão.
- **AVISO:** entra, mas fica registrado e conta para métricas do lote.

**Decisão final:**

- **`rejeitar`** se houver BLOQUEIA que não se resolve com autocorreção.
- **`ajustar`** se houver BLOQUEIA autocorrigível ou qualquer AJUSTAR.
- **`aprovado`**, com ou sem avisos, no restante.

### 8.2 Regras frase a frase

**Camada F, formato e teclado** (determinística; detalhes no dossiê 06, seção B8)

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| F01 | `en` só em ASCII imprimível (U+0020–U+007E) | regex `^[\x20-\x7E]+$` | BLOQUEIA (autocorrige `’` → `'`, aspas tipográficas, NBSP) |
| F02 | Sem `& < > # @ * _ \| \ { } [ ] ~ ^` `` ` `` | regex | BLOQUEIA |
| F03 | Sem espaço duplo, sem espaço no início ou fim | regex | BLOQUEIA (autocorrige) |
| F04 | Frase inteira: maiúscula inicial e `.`, `?` ou `!` no fim (GDEX *is_whole_sentence*). Exceção: itens `tipo: fragmento_dialogo` | regex | BLOQUEIA |
| F05 | Sem `...`, `—` ou `–`. Aspas duplas geram aviso | regex | AJUSTAR |
| F06 | Grafia en-US (*color, center, realize, traveled, theater, neighbor, favorite, gray, program*) | lista de pares UK→US + LanguageTool `en-US` | AJUSTAR |
| F07 | `pt` com ortografia pós-Acordo (*ideia, voo, assembleia, heroico; para* sem acento) e hífens corretos (*meio-dia*) | lista + LanguageTool `pt-BR` | AJUSTAR |
| F08 | Comprimento por nível (dossiê 02): pré-A1 1–5 palavras; A1 2–9; A2 5–12; B1 8–16; B2 10–20; C1 12–25 | contagem | AJUSTAR (ou partir em blocos) |

**Camada P, proveniência e licença**

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| P01 | `origem` preenchida e válida | schema | BLOQUEIA |
| P02 | Se `tatoeba*`: `en_id`, `en_autor`, `licenca`, `modificada` presentes. O PT tem `pt_id` e `pt_autor`, ou `pt_autoral: true` | schema | BLOQUEIA |
| P03 | IDs existem no export da semana. Texto igual ao do export, ou divergência justificada por `modificada: true` | junção com o export | AVISO (se o Tatoeba corrigiu, revisar) |
| P04 | Se `tatoeba*`: EN e PT criadas antes de 01/12/2022, ou com dono nativo e revisão posterior | datas do export | AVISO |
| P05 | Origem proibida: OpenSubtitles, deck AnkiWeb, DailyDialog, exemplo de dicionário, concordância de COCA/SkELL/Ludwig/YouGlish, letra de música, livro didático, legenda | declaração de origem. Para `autoral_*` com 8 ou mais palavras, o juiz responde "is this a famous quote/lyric/dictionary example?" | BLOQUEIA |
| P06 | Frase `autoral_*` idêntica (normalizada) a uma frase do Tatoeba com 6 ou mais palavras → reclassificar como `tatoeba` e atribuir | busca exata no export | AJUSTAR |
| P07 | Áudio externo só com licença sem NC e sem ND. Preferir TTS (06) | metadado | BLOQUEIA |

**Camada G, gramática EN e interferência**

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| G01 | LanguageTool `en-US` sem ocorrências em GRAMMAR, TYPOS, CONFUSED_WORDS, COLLOCATIONS. STYLE e PUNCTUATION (ex.: `COMMA_COMPOUND_SENTENCE`) viram aviso | API local | BLOQUEIA / AVISO |
| G02 | Nenhum padrão de interferência BR do dossiê 04 casa. Exemplos de regex: `\bI (have\|has) \d+ years\b(?! of)`, `\bexplain me\b`, `\bdepend(s)? of\b`, `\bdiscuss about\b`, `\bmarried with\b`, `\bmake a party\b`, `\bpeople is\b`, `\bthe life is\b`, `\bI am agree\b`, `\b(informations\|advices\|furnitures\|equipments)\b`, `\ban? (advice\|information\|news)\b` | regex + whitelist por contexto | BLOQUEIA |
| G03 | Tempo coerente com o marcador. *since/for + período* com presente simples ou contínuo, como `\b(am\|is\|are)\s+\w+ing\b.*\bsince\b`, é suspeito. *yesterday/ago/last* com presente; *already/yet/ever/never* conforme en-US | regex de triagem + juiz LLM confirma | BLOQUEIA se confirmado |
| G04 | Ordem adjetivo-substantivo, posição de advérbio de frequência (*I always...*), *do/does* em perguntas | LanguageTool + juiz | AJUSTAR |

**Camada N, naturalidade EN** (núcleo deste dossiê)

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| N01 | **Atestação de trigramas.** Normalizar (minúsculas, dígitos → `NUM`, nomes próprios → `PROP`, `<s>`/`</s>`). Todos os trigramas presentes em `REF_TRIGRAMAS` passa. Trigrama ausente leva a janela de até 5 palavras ao redor dele para N02 | contagem local | triagem (não bloqueia sozinho) |
| N02a | **Frequência com alternativas** (Netspeak `web-en`). Para cada janela suspeita, montar a consulta com o slot trocado (`?` ou `[ make take do have get ]`, preposições `[ in on at for to with of ]`). **Reprovar** se a forma usada tiver menos de 10% da melhor alternativa e a melhor tiver 1.000 ou mais ocorrências. **Aprovar** se a forma usada tiver 1.000 ou mais e pelo menos 20% da melhor. Entre os dois, AVISO. *Limiares iniciais, calibrar com 8.5* | `netspeak.py` com cache | AJUSTAR (sugestão = melhor alternativa) |
| N02b | **Variante en-US.** Para expressões com par conhecido (*at/on the weekend, have got/have, in hospital/in the hospital, at school/in school*...), exigir que a frequência relativa em `en-US` não seja menor que a de `en-GB` | Google Ngram JSON, 2015–2019 | AJUSTAR |
| N03 | **Vocabulário "LLM-ish"** fora de lugar. Lista inicial: *delve, tapestry, vibrant, bustling, embark, realm, testament, seamless(ly), foster, leverage* (fora de dev), *elevate, unlock* (figurado), *intricate, showcase, underscore, pivotal, meticulous(ly), robust* (fora de dev), *navigate/journey/landscape* (figurados), *myriad, plethora, nestled, boasts, captivating, enchanting, breathtaking, unwavering, invaluable, resonate, harness, endeavor, holistic, synergy, game-changer, cutting-edge, ever-evolving, dive into, in today's (fast-paced) world, it's important to note, whether you're ... or ...* | lista (lema). Base: palavras em excesso de Kobak et al. e Juzek & Ward (*delve, intricate, underscore, showcasing*...) + heurística | BLOQUEIA em A1–B1 · AVISO em B2+ (salvo se for o alvo da lição) |
| N04 | **Padrões estruturais de IA:** oração de particípio no fim (`, (making\|leaving\|allowing\|ensuring\|creating\|helping\|giving)\b`); *not only ... but also* antes de B2; abertura com advérbio de comentário (*Interestingly, Notably, Ultimately, Additionally,*); densidade de nominalizações (`-tion/-ment/-ity/-ness/-ance/-ence`) acima de 1 a cada 8 palavras em A1–B1; *in order to* em fala casual; *It is + adj + to* onde o nativo diria *It's* | regex + contagem | AJUSTAR |
| N05 | **Registro de conversa.** Se `registro` for conversa ou informal, contrair onde o nativo contrai (*I'm, don't, it's, can't, I'll, let's, that's, there's*), salvo ênfase declarada (`enfase: true`). Evitar respostas "completas demais" (*Yes, I do like...*) | regex de formas plenas (`\b(I am\|do not\|does not\|it is\|cannot\|I will\|let us)\b`) + juiz | AJUSTAR |
| N06 | **Situação plausível** (GDEX "typical/likely"; Tatoeba "likely, self-contained"). O juiz precisa nomear quem diz, para quem e onde. Se não consegue, ou se a frase só faz sentido como exemplo de gramática, falha | juiz LLM | AJUSTAR |
| N07 | **Reescrita nativa adversarial** (5.7): dois juízes independentes reescrevem. Diferença material nos dois → AJUSTAR com a sugestão. Em um só → AVISO e terceiro juiz | juízes LLM | AJUSTAR / AVISO |
| N08 | **Colocações-chave mesmo sem trigrama ausente.** Extrair pares verbo+substantivo, verbo+preposição e adjetivo+substantivo e testar como em N02a. Pega casos como *married with a doctor*, que passam no N01 | parser simples (POS) ou lista de verbos leves e preposições + Netspeak | AJUSTAR |
| N09 | Perplexidade (opcional, 5.6) acima do percentil 95 do Tatoeba do mesmo comprimento | LM local | AVISO |

**Camada L, nível e progressão** (depende dos dossiês 02 e 03)

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| L01 | Todo lema com nível ≤ alvo (CEFR-J/Octanove ou faixa NGSL do 03), exceto os itens declarados em `foco` e os nomes próprios | lematizador (o de `nivel.py` serve de base; melhor com POS) | AJUSTAR |
| L02 | No máximo 1 item novo (estrutura, ou 1–2 palavras em A1–A2; 2–3 em B1+) em relação ao "já visto" do curso | diferença com o inventário acumulado | AJUSTAR |
| L03 | Estruturas permitidas no nível (regras "não usar X antes de Y" do 02, seção 6.2) | regex por estrutura (*have + particípio, would have, had + particípio, if ... were*...) + juiz | AJUSTAR |
| L04 | Sem anáfora solta (*he, she, it, that, they* sem antecedente) em frase isolada. Em cena ou diálogo, o antecedente deve estar na cena | regex de pronome inicial + flag de cena | AVISO |
| L05 | Palavras desconhecidas além do foco: no máximo 1–2 por frase (02, Hu & Nation) | igual a L01 | AJUSTAR |

**Camada T, tradução PT-BR** (o que aparece em cima)

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| T01 | PT sem palavras de Portugal e sem erro gramatical | LanguageTool `pt-BR`: nenhuma regra `PT_BR_SIMPLE_REPLACE_*` nem GRAMMAR | BLOQUEIA |
| T02 | Sem marcadores europeus: `\btu\b` + verbo de 2ª pessoa; `\b(estou\|está\|estamos\|estão\|estava\|estás)\s+a\s+\w+r\b`; ênclise coloquial (`\b\w+-(me\|te\|lhe\|nos)\b` em fala casual); *convosco, pequeno-almoço, casa de banho, autocarro, comboio, telemóvel, rapariga, miúdo, equipa, registo, facto, ecrã, frigorífico* | regex | BLOQUEIA |
| T03 | **Fidelidade de sentido.** Negação; tempo e aspecto (*will/going to/present perfect*); modalidade (*might, must, should, can, could*); quantificadores e frequência (*often* = muitas vezes, *sometimes* = às vezes, *always, never, any, some*); número de *you* (singular ou plural, declarado); sujeito e objeto; nada omitido nem acrescentado | juiz bilíngue (8.4b) + retro-tradução (T04). Casos reais que precisam falhar: *wouldn't* → "faria"; *often* → "de vez em quando"; *hope ... had* → "esperava ... tivesse"; *might* → "podemos"; *as much meat* → (omitido) | BLOQUEIA |
| T04 | **Determinismo PT→EN.** Retro-tradução cega três vezes. A forma-alvo ou variante declarada aparece, e nenhuma retro-tradução majoritária tem sentido diferente. Se o PT admite 2 ou mais EN distintos e plausíveis, acrescentar pista (contexto ou glosa) ou declarar `en_variantes` | modelo sem acesso ao EN | AJUSTAR |
| T05 | **Falsos cognatos** (anexo A do 04). Se o EN contém *actually, eventually, pretend, assist, attend, push, library, college, fabric, sensible, realize, exquisite, parents, lunch, prejudice, injury, ordinary*..., o PT não pode usar o cognato enganoso (*atualmente, eventualmente, pretender, assistir, atender* para *attend*...) | lista de pares proibidos | BLOQUEIA |
| T06 | **Naturalidade brasileira e registro.** Sem "Eu" redundante em sequência; futuro perifrástico na fala (*vai terminar*, não *terminará*); sem mesóclise ou ênclise em fala; *você/a gente/o senhor* coerente com `registro`; *te/você* coerente dentro da frase | regex + juiz | AJUSTAR |
| T07 | Nomes próprios iguais nos dois lados (*Mary* não vira "Maria") | comparação de tokens capitalizados | AJUSTAR |
| T08 | Tipo de frase compatível (pergunta vira pergunta; exclamação só se o EN tem) | pontuação final | AVISO |
| T09 | Glosa literal (se houver) cobre só o trecho divergente, e o chunk tem a mesma tradução no curso todo (04, itens 5 e 10) | dicionário de chunks do curso | AJUSTAR |

**Camada C, conteúdo**

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| C01 | Tema sensível (violência, morte, armas, drogas, sexo, política partidária, religião em tom de juízo, insultos, doença grave). Exceções úteis marcadas `sensivel_ok` (*Call an ambulance!*, *I'm allergic to peanuts.*) | regex (a lista de `funil.py` serve de base) + juiz | BLOQUEIA em A1–B1 · AJUSTAR em B2+ |
| C02 | Pessoa real privada, contribuidor, propaganda de marca | juiz + lista | BLOQUEIA |
| C03 | Fato falso ou datado sem propósito (telegrama, fax, VHS, "Venus is the largest planet") | juiz | AJUSTAR |
| C04 | Estereótipo de gênero, nacionalidade ou idade | juiz | AJUSTAR |
| C05 | Utilidade para o perfil (adulto brasileiro, dev, viagem, trabalho) | juiz (nota de 1 a 5) | AVISO se ≤ 2 |

### 8.3 Regras de lote (por lição e no curso todo)

| ID | Regra | Como testar | Sev. |
|---|---|---|---|
| D01 | Quase-duplicatas: similaridade de tokens acima de 0,85 (Levenshtein normalizado) ou mesma frase com só o nome trocado. Permitido só se marcada `variacao_de` (exercício de substituição do 05) | pares na lição e no curso | AJUSTAR |
| D02 | Monotonia de tempo verbal: nenhum tempo acima de 60% da lição, salvo foco declarado (Lew 2023) | classificação simples por regex | AJUSTAR |
| D03 | Abertura: no máximo 30% das frases da lição com a mesma primeira palavra | contagem | AVISO |
| D04 | Nomes: Tom/Mary em no máximo 10% do curso; variedade com nomes curtos e fáceis no TTS (06) | contagem | AVISO |
| D05 | Mesmo chunk, mesma tradução (consistência) | dicionário de chunks | AJUSTAR |
| D06 | **Detectabilidade:** 20 frases nossas misturadas com 20 do Tatoeba. Se o juiz acerta mais de 70% das nossas como "máquina", revisar o estilo do gerador | juiz LLM (5.7) | AVISO (lote) |
| D07 | Taxa de N03 e N04 por 100 frases no lote (meta: N03 = 0 em A1–B1; N04 abaixo de 3%) | contagem | AVISO |
| D08 | Proporção de origens (6.4) e lista de autores do Tatoeba atualizada para os créditos | contagem | AVISO |

### 8.4 Prompts dos juízes (em inglês, que dá julgamentos mais estáveis; a saída é JSON)

**(a) Juiz nativo (N06, N07)**, rodar duas vezes, com variação de persona:

```
You are a native speaker of American English and a strict ESL teacher.
Sentence: "<EN>"
Level: <A1..C1>. Register: <conversation|neutral|formal>. Scene (optional): "<cena>".
Tasks:
1. In one line, name a realistic situation: who says this, to whom, where. If none is plausible, say "NONE".
2. Rewrite the sentence exactly as a native speaker would naturally say it in that situation,
   keeping the meaning and the level. If nothing should change, return it IDENTICAL.
3. List any word or collocation that sounds non-native, textbook-like, British, or AI-generated.
Return JSON: {"situacao": "...", "reescrita": "...", "problemas": ["..."], "natural": true|false}
```

**(b) Juiz bilíngue (T03, T06)**

```
You are a professional EN->PT-BR translator from Brazil.
EN: "<EN>"   PT-BR shown to the learner: "<PT>"
Check, one by one: negation, tense/aspect, modality (might/must/should/can/could),
frequency/quantity words (often, sometimes, always, any, some), singular/plural "you",
omissions/additions, false cognates, European Portuguese forms, stiffness (unnecessary "Eu",
synthetic future in speech, enclisis in casual speech), register (você/a gente/o senhor).
Return JSON: {"fiel": true|false, "erros_sentido": ["..."], "pt_natural_br": true|false,
"sugestao_pt": "...", "observacoes": ["..."]}
```

**(c) Retro-tradutor cego (T04)**, rodar três vezes, sem mostrar o EN:

```
Translate this Brazilian Portuguese sentence into natural American English.
Give the single most likely translation, then up to 2 alternatives a native might also say.
PT: "<PT>"
Return JSON: {"principal": "...", "alternativas": ["...", "..."]}
```

Regra para T04: normalizar e comparar com `en` e `en_variantes`. Se nenhuma das três rodadas trouxer o alvo, e as rodadas concordarem entre si em outra forma, marcar AJUSTAR.

### 8.5 Calibração antes de confiar no revisor

Montar um **conjunto-ouro** e medir precisão e cobertura por regra:

- **300 positivos:** pares do Tatoeba com EN do CK (lista 907) e PT de tradutor brasileiro, revisados à mão.
- **300 negativos semeados:**
  - 100 com interferência BR do dossiê 04 (*I have 20 years*, *explain me*, *since* + presente...);
  - 100 com estilo "LLM-ish" (N03, N04, sem contração);
  - 100 com PT defeituoso (negação perdida, *often* → "de vez em quando", pt-PT, falso cognato).

Metas iniciais:

- **Pelo menos 90% de cobertura dos negativos** nas camadas G, N e T.
- **No máximo 5% de alarme falso nos positivos.**

Ajustar os limiares de N02a e da regra de decisão dos juízes até chegar lá. Recalibrar quando trocar de modelo LLM.

### 8.6 Saída por frase (JSON)

```json
{
  "id": "en-a2-031",
  "status": "ajustar",
  "falhas": [
    {"regra": "G02", "sev": "BLOQUEIA",
     "evidencia": "padrão de interferência BR 'make a party'",
     "sugestao": "I'm having a party on Saturday."},
    {"regra": "N01", "sev": "triagem",
     "evidencia": "trigrama 'make a party' ausente no REF (7/8 atestados)"},
    {"regra": "N02a", "sev": "AVISO",
     "evidencia": "Netspeak [make have throw give] a party: have 250.937 · throw 71.307 · make 27.263 · give 26.859 (make = 10,9% da melhor)",
     "sugestao": "have a party / throw a party"},
    {"regra": "T06", "sev": "AJUSTAR",
     "evidencia": "futuro sintético em fala: 'farei'",
     "sugestao": "Vou dar uma festa no sábado."}
  ],
  "avisos": ["D03"],
  "medidas": {"trigramas_atestados": "7/8", "nivel_lexical": "A2", "palavras": 8,
               "juiz_nativo_mudou": [true, true], "retro_traducao_ok": true},
  "fonte_conferida": null
}
```

As contagens do Netspeak nesse exemplo foram medidas de verdade nesta sessão, e o caso é instrutivo. *Make a party* tem 10,9% da frequência de *have a party*. Isso cai na **zona de aviso** do N02a (entre 10% e 20%), não na de reprovação, porque a web tem muito texto de não nativos. Quem bloqueia é a regra G02, alimentada pela lista de interferências do dossiê 04, e o N01 já tinha marcado a frase como suspeita. Por isso **nenhuma camada decide sozinha**, e os limiares do N02a precisam da calibração da seção 8.5.

---

## 9. Receitas e código (load-bearing para o agente revisor)

**Cliente mínimo do Netspeak** (gRPC-web, só biblioteca padrão; protocolo extraído do bundle da interface web). Campos do `SearchRequest`: 1 = query, 2 = corpus, 3 = max_phrases. A resposta traz `result` (campo 1), com `phrases` (campo 1), e cada frase tem `frequency` (campo 2) e `words` (campo 3, texto no campo 2):

```python
import urllib.request, struct
def _v(n):
    o=b''
    while True:
        b=n&0x7f; n>>=7
        if n: o+=bytes([b|0x80])
        else: return o+bytes([b])
def _s(f,s): s=s.encode(); return _v((f<<3)|2)+_v(len(s))+s
def _rv(b,i):
    r=s=0
    while True:
        c=b[i]; i+=1; r|=(c&0x7f)<<s; s+=7
        if not c&0x80: return r,i
def _p(b):
    i=0; out=[]
    while i<len(b):
        k,i=_rv(b,i); f,t=k>>3,k&7
        if t==0: v,i=_rv(b,i)
        elif t==2: l,i=_rv(b,i); v=b[i:i+l]; i+=l
        elif t==1: v=b[i:i+8]; i+=8
        else: v=b[i:i+4]; i+=4
        out.append((f,v))
    return out
def netspeak(q, corpus='web-en', n=10):
    msg=_s(1,q)+_s(2,corpus)+_v(3<<3)+_v(n)
    req=urllib.request.Request(
        'https://ngram.api.netspeak.org/netspeak.service.NetspeakService/Search',
        data=b'\x00'+struct.pack('>I',len(msg))+msg,
        headers={'content-type':'application/grpc-web+proto','x-grpc-web':'1'})
    d=urllib.request.urlopen(req,timeout=30).read()
    pay=d[5:5+struct.unpack('>I',d[1:5])[0]]; res=[]
    for f,v in _p(pay):
        if f==1:
            for f2,v2 in _p(v):
                if f2==1:
                    fq=0; w=[]
                    for f3,v3 in _p(v2):
                        if f3==2: fq=v3
                        if f3==3: w+=[v4.decode() for f4,v4 in _p(v3) if f4==2]
                    res.append((' '.join(w),fq))
    return res
# netspeak('[ make take do ] a mistake') -> [('make a mistake', 619576), ('do a mistake', 1080), ...]
```

**Atestação de trigramas** (`fontes07/trigramas.py`):

- Normalizar com `re.sub(r"\d+","NUM",s)` e trocar nomes próprios conhecidos por `PROP`.
- Tokenizar com `re.findall(r"[a-z]+(?:'[a-z]+)?", s.lower())` e envolver em `<s>`/`</s>`.
- Contar trigramas sobre as frases EN de donos com nível 5 e `criada < 2022-12-01`.
- Para o revisor, gerar uma vez um `Counter` completo, ou um SQLite com `trigrama TEXT PRIMARY KEY, n INTEGER`, a partir de `eng_sentences_detailed.tsv` + `eng_user_languages.tsv`.

**Funil de candidatas** (`fontes07/funil.py`): junta links, textos, níveis declarados e tags, aplica os filtros da seção 2.6, escolhe uma tradução por frase e anota o nível lexical. Para atualizar, basta baixar os exports do sábado e rodar de novo.

**Google Ngram:** `GET https://books.google.com/ngrams/json?content=A,B&year_start=2015&year_end=2019&corpus=en-US&smoothing=0`. Retorna `[{ngram, timeseries[]}]`; comparar as médias. Pausar entre consultas e manter cache.

---

## 10. Lacunas e incertezas

- **Direito:** a leitura das licenças é de leigo. Pontos a confirmar se o app for monetizado:
  - se a atribuição por frase é exigível (a FAQ do Tatoeba se contenta com crédito global; o ManyThings sugere por autor);
  - o efeito da Lei 9.610/98 sobre compilações.

  A recomendação de fazer as duas coisas cobre os dois cenários.
- **Nível CEFR das frases:** a estimativa é só lexical e heurística. Um classificador de nível de frase (por exemplo, treinado com CEFR-SP, uso interno) e as regras de estrutura do 02 deixariam isso melhor.
- **Classificação do tradutor (BR ou PT):** feita por marcadores. Tradutores "bilíngues de variante", como carlosalberto, só são resolvidos pelo filtro por frase e pela camada T.
- **Auditoria de 60 pares:** amostra pequena. A taxa real de erro de sentido pode estar entre cerca de 1% e 11%. Uma auditoria de 300 pares (meio dia de trabalho) estreitaria o intervalo.
- **Netspeak:**
  - não achei termos de uso nem a composição exata do corpus `web-en`;
  - a web inclui texto de não nativos (*discuss about*, 159 mil);
  - janelas acima de 5 palavras voltam vazias;
  - é preciso cache e moderação, e o serviço pode sair do ar. O plano B é o dataset do Google Ngram (CC BY 3.0) baixado.
- **Google Ngram:** o endpoint JSON não é documentado. E livro não é fala: subestima contrações e informalidade.
- **COCA e Ludwig:** não testados (Cloudflare). Ficam para consulta manual.
- **Tatoeba depois de 2022:** a regra anti-IA existe, mas não há como provar que nada passou. Por isso o corte de data.
- **O áudio do CK:** não verifiquei como foi produzido. Para a decisão isso é irrelevante, porque a licença NC-ND já exclui o uso.
- **Juízes LLM:** a concordância humana já é baixa (Merx 2024). Os juízes precisam do conjunto-ouro (8.5) e de recalibração a cada troca de modelo.

---

## 11. Fontes

**Tatoeba e derivados**
- Tatoeba, Downloads: https://tatoeba.org/en/downloads
- Tatoeba, Terms of Use: https://tatoeba.org/en/terms_of_use
- Tatoeba, estatísticas por idioma: https://tatoeba.org/en/stats/sentences_by_language
- Exports: https://downloads.tatoeba.org/exports/ e https://downloads.tatoeba.org/exports/per_language/
- API v1: https://api.tatoeba.org/
- Wiki, Using the Tatoeba Corpus for Your Own Projects: https://en.wiki.tatoeba.org/articles/show/using-the-tatoeba-corpus
- Wiki, FAQ (atribuição de texto e áudio, download de áudio): https://en.wiki.tatoeba.org/articles/show/faq
- Wiki, Rules and Guidelines (proibição de IA, de material protegido, tradução natural): https://en.wiki.tatoeba.org/articles/show/guidelines
- Wiki, How to Write Good Sentences: https://en.wiki.tatoeba.org/articles/show/how-to-write-good-sentences
- Lista 907 do CK: https://tatoeba.org/en/sentences_lists/show/907
- ManyThings, pares bilíngues (Anki): https://www.manythings.org/anki/
- ManyThings, áudio do CK (CC BY-NC-ND 3.0): https://www.manythings.org/tatoeba/
- Creative Commons, CC BY 2.0 FR (deed): https://creativecommons.org/licenses/by/2.0/fr/deed.en
- EDRDG, Tanaka Corpus: https://www.edrdg.org/wiki/Tanaka_Corpus.html
- Clozemaster FAQ (exemplo de atribuição citado pelo Tatoeba): https://www.clozemaster.com/faq
- OPUS API, Tatoeba en–pt: https://opus.nlpl.eu/opusapi/?corpus=Tatoeba&source=en&target=pt&preprocessing=moses&version=latest

**Outras fontes de frases e corpora**
- OPUS, OpenSubtitles v2018 (condições de uso e citação): https://opus.nlpl.eu/legacy/OpenSubtitles-v2018.php
- OPUS API, OpenSubtitles en–pt v2024: https://opus.nlpl.eu/opusapi/?corpus=OpenSubtitles&source=en&target=pt&preprocessing=moses&version=latest
- Wikipedia, Copyrights: https://en.wikipedia.org/wiki/Wikipedia:Copyrights
- Mozilla Common Voice (README, CC0 das frases): https://github.com/common-voice/common-voice
- VOA Learning English (domínio público): https://learningenglish.voanews.com/p/6861.html
- DailyDialog (CC BY-NC-SA 4.0): https://huggingface.co/datasets/li2017dailydialog/daily_dialog
- AnkiWeb, Terms and Conditions (Shared Deck License): https://ankiweb.net/account/terms
- COCA (Wikipedia): https://en.wikipedia.org/wiki/Corpus_of_Contemporary_American_English
- Google Books Ngram, datasets (CC BY 3.0): https://storage.googleapis.com/books/ngrams/books/datasetsv3.html
- Google Books Ngram, info: https://books.google.com/ngrams/info
- Netspeak: https://netspeak.org/ · código: https://github.com/netspeak
- SkELL: https://www.sketchengine.eu/skell/
- YouGlish: https://youglish.com/
- Ludwig: https://ludwig.guru/ (não acessado: Cloudflare)
- LanguageTool, API pública: https://dev.languagetool.org/public-http-api · código (LGPL-2.1): https://github.com/languagetool-org/languagetool
- FrequencyWords (OpenSubtitles; CC BY-SA 4.0): https://github.com/hermitdave/FrequencyWords
- wordfreq (licenças, SUBTLEX, Google Ngram) e SUNSET: https://github.com/rspeer/wordfreq · https://github.com/rspeer/wordfreq/blob/master/SUNSET.md
- Open Language Profiles, CEFR-J e Octanove: https://github.com/openlanguageprofiles/olp-en-cefrj
- CEFR-SP: https://github.com/yukiar/CEFR-SP
- NGSL: https://www.newgeneralservicelist.com/new-general-service-list
- Cambridge University Press, "Common English errors when a learner's first language is Portuguese" (folheto; também usado no dossiê 04): https://www.cambridge.org/elt/blog/wp-content/uploads/2020/03/Portuguese.pdf

**IA, exemplos e naturalidade**
- Lew, R. (2023). ChatGPT as a COBUILD lexicographer. *Humanities and Social Sciences Communications* 10:704. https://doi.org/10.1057/s41599-023-02119-6
- de Schryver, G.-M. (2023). Generative AI and Lexicography: The Current State of the Art Using ChatGPT. *IJL*. https://doi.org/10.1093/ijl/ecad021
- Lyu, J., Liu, X., Jablonkai, R. R. (2026). Towards Updated Standards for Dictionary Examples for English Learners: An Evaluation Framework for ChatGPT-Generated Illustrative Sentences. *IJL*. https://doi.org/10.1093/ijl/ecag029
- Merx, R., Vylomova, E., Kurniawan, K. (2024). Generating bilingual example sentences with large language models as lexicography assistants. https://arxiv.org/abs/2410.03182
- Kilgarriff, A., Husák, M., McAdam, K., Rundell, M., Rychlý, P. (2008). GDEX: Automatically finding good dictionary examples in a corpus. *Proc. EURALEX XIII*, 425–432. Resumo dos critérios: https://www.sketchengine.eu/guide/gdex/
- Kosem, I. et al. (2018). Identification and automatic extraction of good dictionary examples: the case(s) of GDEX. *IJL*. https://doi.org/10.1093/ijl/ecy014
- Reinhart, A. et al. (2025). Do LLMs write like humans? Variation in grammatical and rhetorical styles. *PNAS*. https://doi.org/10.1073/pnas.2422455122 · https://arxiv.org/html/2410.16107
- Kobak, D. et al. (2024/2025). Delving into LLM-assisted writing in biomedical publications through excess vocabulary. https://arxiv.org/abs/2406.07016
- Juzek, T. S., Ward, Z. B. (2024). Why Does ChatGPT "Delve" So Much? https://arxiv.org/abs/2412.11385
- Li, Y. et al. (2025). Lost in Literalism: How Supervised Training Shapes Translationese in LLMs. https://arxiv.org/abs/2503.04369
- Valentini, M. et al. (2026). An Investigation of Translationese in the Generations of Multilingual Large Language Models. https://arxiv.org/abs/2608.17399

**Dados e scripts desta pesquisa** (scratchpad, fora do projeto)
- `pesquisa/fontes07/` contém:
  - os exports do Tatoeba de 03/10/2026 (`eng_*`, `por_*`, `eng-por_links.tsv`, `users_sentences.csv`);
  - os scripts `analisa.py`, `nivel.py`, `funil.py`, `netspeak.py` e `trigramas.py`;
  - a lista `tatoeba_candidatas_en_ptbr.tsv` (85.460 pares filtrados, com IDs e autores para atribuição).
