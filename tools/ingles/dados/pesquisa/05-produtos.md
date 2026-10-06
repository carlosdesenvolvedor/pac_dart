# 05 — Benchmark de produtos e métodos: UX de aprender FRASES DIGITANDO

> Frente de pesquisa: como os apps e métodos existentes ensinam com frases, o que funciona, o que os usuários reclamam, e o que isso significa para o **PAC·ENGLISH** (tradução PT‑BR em cima, frase em inglês digitada letra a letra, várias vezes, do zero ao avançado).
> Data: 04/out/2026. Tudo em PT‑BR. As fontes estão linkadas ao longo do texto e listadas no fim (§11).

---

## 0. Resumo executivo (para quem só vai ler uma página)

1. **Nenhum produto grande faz exatamente o que o dono pediu** (frase inteira em inglês, digitada letra a letra, com a tradução em cima, repetida até decorar). O mais parecido é o **Glossika** (frase inteira, digitação, 5 frases × 5 repetições, áudio nativo); depois vêm o **Clozemaster** e o **Lingvist** (digitar só UMA palavra que falta na frase) e o **Assimil na “segunda onda”** (ler a tradução e reproduzir a frase na língua estrangeira). O **TypeLit.io** e os treinadores de digitação (keybr, Monkeytype) trazem a parte do motor. **A combinação é um espaço vazio.** O PAC já tem metade pronta: o motor letra a letra.
2. **Achado mais importante, e com dado de laboratório:** digitar a mesma coisa várias vezes **com o modelo inteiro à vista (cópia)** é o jeito mais fraco de repetir. No experimento de [Finley, Benjamin, Hays, Bjork & Kornell (2011)](https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/07/Finley_Benjamin_Hays_RBjork_Kornell_2011.pdf), as pessoas digitavam a palavra-alvo 6 vezes. Quando **o modelo ia perdendo uma letra a cada tentativa** (pistas decrescentes), a lembrança no teste final foi **40% contra 29%** da cópia pura. Com feedback depois de cada tentativa, foi **58% contra 40%**. Ou seja: o “escrever várias vezes” do dono tem que ser uma **escada que apaga o texto‑fantasma aos poucos**, e não cinco cópias iguais.
3. **Repetição tem que vir intercalada**, não em bloco (A B C D E, A B C D E… e não A A A A A). O Glossika embaralha as 25 repetições das 5 frases, e no estudo do Finley havia em média 5 itens entre duas tentativas da mesma palavra.
4. **A maior reclamação contra apps de frases é “frase solta, sem contexto, em vácuo”** (Glossika, Clozemaster, Lingvist). A segunda é **frase estranha ou tradução ruim** (Tatoeba no Clozemaster, traduções “de segunda mão”, as frases absurdas do Duolingo). Por isso as frases devem vir **em cenas e diálogos curtos**, ser escritas ou revisadas por gente, e ter **tradução natural**.
5. **Correção chata é a terceira reclamação** (Duolingo recusando acento ou ordem válida, Lingvist recusando sinônimo). O motor do PAC já tolera tecla morta, US‑International e aspas curvas, e deve ir além. **Pontuação final e maiúscula inicial não podem custar erro**, já que o Glossika torna a pontuação opcional e o Lingvist ignora diacríticos por padrão. Para as frases com mais de uma resposta certa (I’m / I am), a pista visual tem que deixar claro qual forma é esperada.
6. **Áudio é obrigatório** desde a primeira frase: tocar ao aparecer, uma tecla para repetir, velocidade lenta. Também é preciso uma passada avançada **só de ouvido** (ditado), como fazem o Glossika e o *cloze‑listening* do Clozemaster. Atenção: a voz Gemini que o PAC já usa tem cota grátis de uns 10 áudios por dia (comentário no `voz_natural.dart`). Para o inglês, a voz principal precisa ser a do navegador (en‑US) ou áudios gerados antes.
7. **Revisão espaçada por frase, com nota automática.** O motor já mede erros, ajudas e tempo, então não é preciso pedir que a pessoa se dê nota de 1 a 4 (como no Anki ou no MosaLingua). A revisão vem antes do conteúdo novo, e os conteúdos novos por dia precisam de limite para não virar avalanche: 20 novos por dia no Anki dão cerca de 200 revisões por dia.
8. **Sessão curta e fechada:** uma cena com 5 a 8 frases, cada uma digitada umas 5 vezes com cada vez menos ajuda, o que dá cerca de 25 digitações e uns 10 minutos. É a mesma ordem de grandeza do Glossika (25 repetições), do Babbel (lição média de 6 min) e do MosaLingua (10 min por dia).
9. **Gamificação do tipo “ofensiva” (streak) gentil, sem vidas nem energia.** O Duolingo provou que a ofensiva retém (+14% de retenção no 7º dia no experimento da “aposta”). Também provou que **energia que acaba mesmo quando a pessoa acerta** gera revolta e abandono, e que XP fácil vira “farm” sem aprendizado.
10. **O nível do dono é desconhecido:** o curso precisa de um **nivelamento curto e pulável** e de um botão **“testar para pular esta trilha”**. Ninguém pode ser obrigado a refazer o básico, e o nivelamento longo e obrigatório do Glossika é uma das reclamações contra ele.

---

## 1. Escopo, método e limites

- **Produtos e métodos analisados:** Duolingo, Babbel, Busuu, Glossika, Clozemaster, Lingvist, Anki (com Fluent Forever, MCD/AJATT, *sentence mining*, i+1 e o método de frases do Mairo Vergara, muito popular no Brasil), Memrise, LingQ, MosaLingua, Assimil, Pimsleur, Michel Thomas, TypeLit.io, keybr, Monkeytype e Ratatype (este só de passagem).
- **Foco:** a mecânica e a UX. Como cada um mostra a tradução, as dicas e o modelo; o feedback de erro; o áudio; o tamanho da sessão; a fila de revisão; as metas e a gamificação; como evitam frases artificiais; e o que os usuários reclamam.
- **Fontes:** sites e centrais de ajuda oficiais (Glossika, Lingvist, Clozemaster, Duolingo, Babbel, Busuu, MosaLingua, Pimsleur, Michel Thomas, Anki, TypeLit), fóruns oficiais (Clozemaster, AnkiWeb), reviews independentes (StoryLearning, FluentU, Mezzoguild, Lingopie, Actual Fluency, PCWorld, Android Authority), artigos científicos (Finley et al. 2011, lido no PDF original, com números conferidos na Tabela 2; Fiechter & Benjamin 2018; Barcroft; Karpicke & Zaromb 2010) e o guia do Mairo Vergara (PDF original).
- **Limites:**
  - A cota de buscas web desta sessão acabou no fim da pesquisa. Alguns pontos ficaram sem uma segunda fonte (marcados com “(fonte secundária)” ou “(não confirmado)”).
  - Os relatórios de avaliações de lojas da Kimola (Lingvist, Memrise) responderam *410 Gone*. As reclamações de usuários vieram dos fóruns, dos reviews e dos trechos de busca citados.
  - Reddit não foi lido diretamente, só por espelhos e citações.
- **Contexto do nosso motor** (lido no código, sem alterar nada):
  - O `TypingBloc` funciona como o **“stop on error = letter”** do Monkeytype: tecla errada não avança, conta erro e marca `ultimoErrou`.
  - Ele já trata **teclas mortas do ABNT2**, **composições do US‑International** (`'`+`c` vira `ç` e vale como `'c` em *o’clock*) e **aspas e travessões curvos**.
  - O enum `Linguagem.ingles` já existe. Nele o trecho é `cod` (a frase em inglês) com `dica` (a tradução em cima), o que casa com o esquema `{cod, dica, conceito}` do currículo.
  - Há TTS neural via Gemini (cota de cerca de 10 por dia) com voz do sistema como reserva.

---

## 2. Fichas por produto e método

Cada ficha traz: **Como funciona**, **Tradução, dica e modelo**, **Feedback de erro**, **Áudio**, **Sessão e revisão**, **Gamificação**, **Reclamações**, **O que copiar** e **O que evitar**.

### 2.1 Glossika (o parente mais próximo)

- **Como funciona:** é o “Mass Sentence Method”: só frases completas, sem lições de gramática. Uma sessão nova tem **5 pares de frases × 5 repetições = 25 “reps”**. A sessão de revisão tem **25 frases diferentes × 1 repetição** ([Ajuda Glossika](http://help.glossika.com/en/articles/6611459-step-4-the-most-effective-way-to-train-on-glossika-legacy-app)). As 25 repetições vêm **embaralhadas** ([Actual Fluency](https://actualfluency.com/glossika)).
- **Tradução, dica e modelo:**
  - Na primeira exposição aparecem a frase, a romanização, a tradução e o áudio (nativo e na língua da pessoa).
  - **Nas revisões a romanização some** e a tradução pode ser desligada ([Flexiclasses](https://flexiclasses.com/glossika-review/)). Isso é pista decrescente feita na prática.
  - No ditado, a pessoa pode “espiar” a frase quando quiser ([blog Glossika](https://ai.glossika.com/blog/glossika-all-new-learning-interface)).
- **Digitação:**
  - O Glossika defende que digitar “força você a identificar conscientemente cada parte da frase” e liga som a letra.
  - O roteiro recomendado é ouvir, repetir em voz alta, digitar letra por letra pensando no som e, se errar, comparar e analisar o erro ([Ajuda Glossika: Typing](https://help.glossika.com/en/articles/3256617-typing-how-does-typing-help-me-speak-better-what-s-the-best-way-to-do-it)).
- **Regras de correção:** **pontuação opcional** (“falantes nativos escolhem ponto, vírgula ou interrogação por preferência pessoal”) e **acentos com correspondência flexível** (o acento certo ou nenhum acento) ([blog Glossika](https://ai.glossika.com/blog/glossika-all-new-learning-interface)).
- **Áudio:** nativo, com velocidades **75%, 100% e 125%** ([Flexiclasses](https://flexiclasses.com/glossika-review/)). Os modos são digitação, ditado, escuta e gravação. A gravação mostra a onda sonora, e os atalhos são espaço (tocar e gravar), Enter (enviar), F (favoritar) e **E (pular frase fácil)**.
- **Sessão e revisão:**
  - Cada item novo vira **15 a 20 revisões ao longo de um ano**, e o alvo é **10 revisões para cada item novo**.
  - O conselho é começar com **1 sessão nova por dia durante 2 semanas** antes de subir para 2, **sempre revisando antes** ([Ajuda Glossika](http://help.glossika.com/en/articles/6611459-step-4-the-most-effective-way-to-train-on-glossika-legacy-app)).
- **Nivelamento:** teste de compreensão auditiva que começa no A1. Dá para pular, mas é longo ([Flexiclasses](https://flexiclasses.com/glossika-review/)).
- **Reclamações:**
  - “Ouve, repete, passa. Ouve, repete, passa”: fadiga e desatenção ([Lingopie](https://lingopie.com/blog/glossika-review/)).
  - “Eu me peguei cochilando e devaneando… só repetia sem pensar na frase” ([FluentU](https://fluentu.com/blog/reviews/glossika)).
  - **Frases sem relação entre si**: “quando as frases mal se relacionam, há pouco contexto para aprender” ([Actual Fluency](https://actualfluency.com/glossika)).
  - **Nenhuma explicação** do porquê.
  - Frases formais ou datadas e falta de contexto cultural ([Lingopie](https://lingopie.com/blog/glossika-review/)).
  - Pouco apoio para iniciante absoluto e falta de conteúdo acima do B2 ([Flexiclasses](https://flexiclasses.com/glossika-review/)).
- **Copiar:** 5×5 intercalado, ajuda que some nas revisões, pontuação opcional, velocidades de áudio, ditado, “pular fácil”, revisão antes do novo, proporção 10:1 e limite de sessões novas.
- **Evitar:** frases em vácuo, zero explicação, repetição idêntica sem variação e nivelamento longo.

### 2.2 Clozemaster

- **Como funciona:**
  - Mostra uma frase real com **uma palavra faltando**. A palavra é escolhida automaticamente: a **menos frequente da frase, entre as 10 mil mais comuns** da língua ([FAQ](https://www.clozemaster.com/faq), [StoryLearning](https://storylearning.com/clozemaster-review)).
  - A resposta pode ser por múltipla escolha (**4 pontos**) ou **digitada (8 pontos, o dobro)**.
- **Tradução, dica e modelo:**
  - A tradução fica visível como apoio.
  - Ao digitar, **o texto fica verde enquanto está certo e vermelho quando erra**, e há uma dica durante a digitação ([Ling App](https://ling-app.com/blog/clozemaster-review/)).
  - A opção **“Sentence Text Initially Hidden”** esconde a frase e mostra só a tradução, para a pessoa tentar montar a frase inteira de cabeça antes de revelar a lacuna. Os usuários descrevem isso como “simular ter que produzir a frase do zero”, e quem passou da múltipla escolha para a digitação diz que ela “expôs lacunas de gramática, conjugação e concordância” ([fórum](https://forum.clozemaster.com/t/new-setting-sentence-text-initially-hidden/55526)).
- **Áudio:** TTS. O modo ***cloze‑listening*** toca a frase **antes** de mostrá‑la ([FAQ](https://www.clozemaster.com/faq)).
- **Revisão:**
  - Intervalos de **1, 10, 30 e 180 dias** (domínio de 25%, 50%, 75% e 100%).
  - **Um erro zera o progresso** ([FAQ](https://www.clozemaster.com/faq)).
  - Rodada “Play” = frases novas com até 5 revisões misturadas; rodada “Review” = só revisões.
- **Fonte das frases:** Tatoeba (CC‑BY).
- **Reclamações:**
  - **Qualidade:** um usuário achou 3 erros em 50 frases revisadas com professor (“awful”). Há traduções indiretas, tradução de tradução importada como se fosse direta, com perda de distinções como formal e informal ([fórum: sentence quality](https://forum.clozemaster.com/t/review-of-clozemaster-sentence-quality/7007), [fórum: translations misleading](https://forum.clozemaster.com/t/translations-are-often-misleading/46770)).
  - **Sem contexto ligado:** “as frases não têm relação; você encontra a palavra numa linha e nunca numa situação real” ([StoryLearning](https://storylearning.com/clozemaster-review)).
  - **Zerar tudo por um erro** pune o deslize igual à ignorância ([StoryLearning](https://storylearning.com/clozemaster-review)).
  - **Digitar no celular é difícil.** Usuários pedem um botão “já sei” e, para expressões, **esconder a expressão inteira** (“_ _ _”) com a **tradução primeiro** e **botões de dica que revelam palavra por palavra** ([fórum: ideas](https://forum.clozemaster.com/t/ideas-about-program-improvements/6684)).
- **Copiar:** pontos dobrados para digitação, cor ao vivo, “só tradução primeiro”, ouvir antes de ver, dica que revela palavra a palavra e progresso por frequência.
- **Evitar:** corpus colaborativo não revisado, tradução indireta e reset para zero.

### 2.3 Lingvist

- **Como funciona:**
  - Cartão com frase de exemplo, **tradução** e **uma lacuna** onde a pessoa digita a palavra.
  - Há pistas e um botão “Learn Word” que revela a resposta. **Cinco pontinhos** mostram a força da palavra.
  - O curso geral cobre **as 6.000 palavras mais frequentes**, e a recomendação é **50 cartões por dia, 4 vezes por semana** ([blog Lingvist](https://lingvist.com/blog/learn-with-lingvist-in-three-easy-steps/)).
- **Feedback de erro (a referência de como errar sem punir):**
  - O Lingvist **analisa a posição das letras para decidir se foi typo ou erro**, e se foi erro grave ou tolerável.
  - Mesmo quando pede para **redigitar**, um typo **não conta como erro inteiro** (“não se preocupe se errou uma letra numa palavra longa como *subscription*”).
  - **Diacríticos não contam como erro por padrão.** Existe a opção “Strict Diacritics” para quem quiser ([Ajuda: mistakes](https://lingvist.com/help/how-do-you-count-mistakes)).
- **Sinônimos:**
  - Nem sempre aceita, porque “queremos ensinar expressões específicas num contexto específico”. Há o botão “meu sinônimo não foi aceito” ([Ajuda: synonyms](https://lingvist.com/help/why-wont-you-accept-synonyms/)).
  - O reviewer achou “meio implicante”, mas reconhece que isso “empurra você a praticar a palavra que o app quer” ([FluentU](https://www.fluentu.com/blog/lingvist-review/)).
- **Fluxo:** **avanço automático** depois da resposta certa, que pode ser desligado ([Ajuda](https://lingvist.com/help/the-card-changes-too-quickly/)).
- **Reclamações:**
  - “Ensina no vácuo”: um livro de frases de palavras isoladas, pouco contexto e formato seco ([FluentU](https://www.fluentu.com/blog/lingvist-review/)).
  - Repetitivo e monótono ([Mezzoguild](https://www.mezzoguild.com/lingvist-review/)).
  - Relatos de que o algoritmo **converge para só revisão**, com usuário “meses sem ver palavra nova” (trecho de busca sobre reviews de loja; fonte secundária).
- **Copiar:** distinguir typo de erro, redigitar sem penalizar em dobro, diacrítico leniente por padrão com modo estrito opcional, avanço automático configurável e “revelar resposta” explícito.
- **Evitar:** isolamento da palavra e fila que só revisa.

### 2.4 Duolingo

- **Mecânica relevante:**
  - Exercícios variados: traduzir, montar a frase com **banco de palavras**, “digite o que ouviu” e falar.
  - O banco de palavras é **reconhecimento**. O próprio Duolingo admite que “responder pelo banco de palavras e pelo teclado exige níveis muito diferentes de recordação ativa” e passou a deixar **o aluno escolher digitar** (a partir do nível 2, em todos os cursos) ([blog](https://blog.duolingo.com/improving-how-duolingo-teaches-chinese-and-other-languages)).
  - Existe extensão de navegador só para devolver o teclado, porque usuários “frustrados com o banco de palavras” querem recordar de memória ([TypeLingo](https://addons.mozilla.org/firefox/addon/typelingo/)).
- **Correção de frase livre:**
  - A resposta é comparada com uma **lista de respostas aceitas**: **mais de 200 em média por exercício, e até 30 mil** em frases longas. Uma única frase em espanhol tem 2.156 traduções aceitas ([blog: ML e melhorias de curso](https://blog.duolingo.com/how-machine-learning-helps-duolingo-prioritize-course-improvements)).
  - Typo de uma letra costuma passar com aviso, a menos que forme outra palavra (fonte secundária).
  - **Lição para nós:** aceitar tradução livre exige um esforço editorial gigantesco. Nosso motor tem **um alvo só**, então a interface precisa **desambiguar** qual forma é esperada.
- **Reclamações sobre correção:**
  - Marca errado por acento (“Lopez” × “López”).
  - Recusa pronome opcional e ordem de palavras válida.
  - Trata typos de forma inconsistente.
  - Contexto insuficiente para saber se era “tú” ou “ustedes” ([Matt Vanecek](https://mvanec.substack.com/p/duolingo-annoyances)).
  - Um novo sistema de flashcards recusa sinônimos antes aceitos (trecho de busca, fonte secundária).
- **Frases estranhas:**
  - O Duolingo defende as frases absurdas como “âncora gramatical” e porque prendem a atenção, mas **não cita pesquisa** e admite: “não esperamos que você use essas frases exatas” ([blog 1](https://blog.duolingo.com/why-does-duolingo-teach-weird-sentences/), [blog 2](https://blog.duolingo.com/how-silly-sentences-can-help-you-learn)).
  - Usuários citam “O que a colher diria à sopa?” como exemplo de irritação ([Vanecek](https://mvanec.substack.com/p/duolingo-annoyances)).
- **Revisão espaçada:**
  - Modelo HLR, *half‑life regression*: p = 2^(−Δ/h).
  - Errou cerca de **45–50% menos** que o sistema Leitner na previsão de lembrança, com **+9,5% de retenção diária em sessões de prática** e **+12% de atividade geral** num teste A/B ([blog](https://blog.duolingo.com/how-we-learn-how-you-learn); [Settles & Meeder, ACL 2016](https://preview.aclanthology.org/landing_page/P16-1174)).
  - A ideia central: “a melhor hora de praticar é quando você está à beira de esquecer”.
- **Dificuldade adaptativa (Birdbrain):** estima a chance de acerto de cada exercício para cada aluno e monta a lição no ponto certo de dificuldade. Quem teve lições do Birdbrain aprendeu mais e voltou mais ([blog](https://blog.duolingo.com/learning-how-to-help-you-learn-introducing-birdbrain)). Fontes secundárias falam em mirar cerca de 70% de acerto (não confirmado no blog oficial).
- **Ofensiva (streak), o motor de retenção do Duolingo:**
  - Experimento “aposta de ofensiva”: **+14% de retenção no 7º dia**.
  - “Amuleto de fim de semana”: **+4% de volta depois de uma semana** e **5% menos ofensivas perdidas** ([blog](https://blog.duolingo.com/how-streaks-keep-duolingo-learners-committed-to-their-language-goals)).
  - **“Congelamento”** que salva um dia de falta, e animações de marco: **+1,7% de retenção de novatos**.
  - Quem chega a 7 dias de ofensiva tem **3,6×** mais chance de terminar o curso.
  - **Escolher a meta** logo depois de começar uma ofensiva cria compromisso. Um estudo da UPenn/UCLA mostra que **folga na meta aumenta a motivação** ([blog](https://blog.duolingo.com/how-duolingo-streak-builds-habit)).
  - Achado crucial: **quem “maratona” lições abandona mais** do que quem vai em ritmo constante ([blog](https://blog.duolingo.com/how-streaks-keep-duolingo-learners-committed-to-their-language-goals)).
- **Reclamações de gamificação:**
  - O sistema de **Energia** (testado desde julho de 2025) gasta energia **até quando você acerta**: 25 unidades por dia, 1 por acerto e 1 a 2 por erro. Um usuário com **700+ dias de ofensiva** desistiu por isso (“a gota d’água”) ([Android Authority](https://www.androidauthority.com/quitting-duolingo-energy-system-3599842/), [Wiki](https://duolingo.fandom.com/wiki/Energy)).
  - Com corações ilimitados (pago), a pessoa “passa nas coxas” sabendo que pode tentar de novo. Faz a “prática personalizada pelos 20 XP” sem avançar, e fica “mais preocupada com a ofensiva e o XP” do que com aprender ([PCWorld](https://www.pcworld.com/article/2924235/why-i-fell-out-of-love-with-duolingo.html)).
  - Atualizações de curso **embaralharam o progresso** de usuários avançados (trecho de busca sobre o Android Authority).
- **Revisão de erros:** o Practice Hub (pago) traz “Erros” e revisão personalizada baseada no que a pessoa fez recentemente ([blog](https://blog.duolingo.com/guide-to-duolingo-practice-hub/)).
- **Copiar:** digitação como modo de primeira classe, ofensiva com congelamento, escolha de meta, marcos, “Meus erros” e dificuldade adaptativa.
- **Evitar:** banco de palavras como núcleo, energia e vidas que bloqueiam, frases absurdas, XP fácil e mexer no progresso.

### 2.5 Babbel

- **Como funciona:**
  - Lições de **5 a 10 minutos (média de 6)** centradas em situações reais, com “conversas guiadas”: a pessoa ouve nativos e repete falas ([Babbel](https://www.babbel.com/how-babbel-works)).
  - Diálogos com lacunas e exercícios de escrita “digitando palavras e frases em contexto”.
- **Revisão:**
  - **6 níveis de conhecimento**, em que cada acerto sobe um nível ([All Language Resources](https://www.alllanguageresources.com/babbel-review/)).
  - Quatro modos: cartões, escuta, fala e escrita (preencher lacuna).
- **Reclamações:**
  - Exercícios “monótonos e sem inspiração”, ritmo arrastado.
  - “Não dá pra responder preguiçosamente”: só avança acertando, o que desanima.
  - Alguns narradores “não soam naturais” ([StoryLearning](https://storylearning.com/blog/babbel-review)).
- **Copiar:** lição curta, diálogo de situação real e equipe editorial (mais de 150 linguistas e professores).
- **Evitar:** áudio pouco claro e travar o avanço sem ajuda.

### 2.6 Busuu

- **Destaque:** **correção pela comunidade**. A pessoa escreve ou fala sobre um tema e nativos corrigem: editam o texto (as mudanças aparecem em verde), dão estrelas e comentam, inclusive quando algo está “gramaticalmente correto mas soa estranho” ([Busuu](https://www.busuu.com/en/how-to/corrections)).
- Treinador de vocabulário com revisão espaçada e métrica de decaimento.
- **Para nós:** produção livre corrigida é o passo depois da frase‑modelo. No PAC isso caberia como **“desafio livre” corrigido pelo Prof. Dash (Gemini)** nas trilhas avançadas, sem ser o núcleo.

### 2.7 Anki e a família “sentence mining” (Fluent Forever, MCD, i+1, Mairo Vergara)

- **Anki, a mecânica de digitar:**
  - O campo `{{type:…}}` compara o que foi digitado com a resposta e **mostra a diferença** com classes CSS (`typeGood`, `typeBad`, `typeMissed`).
  - `type:nc` **ignora diacríticos**. Só aceita uma comparação por cartão, em uma linha, e **quem dá a nota ainda é a pessoa** ([manual](https://docs.ankiweb.net/templates/fields.html)).
- **Anki, a carga:**
  - Passos de aprendizado no exemplo do manual: **1 min e 10 min**. Retenção‑alvo padrão do FSRS: **90%**.
  - **“Se você aprende 20 cartões novos por dia de forma consistente, espere cerca de 200 revisões por dia”** ([manual](https://docs.ankiweb.net/deck-options.html)). O FSRS modela dificuldade, estabilidade e recuperabilidade, e **baixar a retenção‑alvo** reduz muito a carga ([explicação](https://domenic.me/fsrs/)).
- **Fluent Forever (Wyner):**
  - Pronúncia primeiro, 625 palavras e **imagens em vez de tradução** (“nunca traduza”), ligação pessoal com a palavra, 15 a 30 cartões novos por dia (cerca de 30 min).
  - Para frases, perguntar: **“há palavra nova? forma nova? ordem de palavras surpreendente?”** e fazer um cartão para cada descoberta ([notas do livro](https://grahammann.net/book-notes/fluent-forever-gabriel-wyner)).
  - Ponto de tensão com o pedido do dono (tradução em cima) está em §5, decisão D3.
- **MCD (*massive context cloze deletion*):** lacuna dentro de um **contexto grande** (às vezes um parágrafo), para que **só uma resposta seja possível** ([Textkit](https://www.textkit.com/t/cloze-deletion-or-massive-context-cloze-deletion/15350)). Para nós: **a linha anterior do diálogo como contexto desambigua a frase‑alvo.**
- **i+1 e Mairo Vergara (referência brasileira):**
  - O guia ensina a **“captação de frases”**: cada frase deve ter **só uma palavra ou expressão desconhecida**, para que você aprenda uma coisa e revise o resto. “Se você inserir frases com três ou mais palavras que não sabe, terá muita dificuldade… e as revisões ficarão cansativas.”
  - **Nunca invente frases**: tire de fontes confiáveis.
  - **Destaque a palavra nova** em negrito no cartão.
  - Meta inicial de **1.000 frases** e **10 a 50 frases por dia**. Mais adiante, cartões **inglês/inglês** ([guia do Mairo Vergara, PDF](https://www.mairovergara.com/wp-content/uploads/2015/09/Como-Aprender-Ingl%C3%AAs-O-guia-definitivo-V1.4.pdf)).
  - O exemplo dele mostra como frases geram frases: sabendo *The book is on the table*, o cérebro produz *The computer is on the table*.
  - Atenção: o cartão do Mairo é **EN → PT (reconhecimento)**. O PAC é **PT → EN (produção)**, que é mais difícil e mais forte, mas pede mais ajuda no começo (ver §3).
  - Um SaaS brasileiro que implementa o método relata que **todos que testaram por mais de uma semana ficaram os 30 dias e assinaram** ([TabNews](https://www.tabnews.com.br/DiogenesLima/aprenda-ingles-um-saas-com-o-metodo-do-mairo-vergara)). É um dado anedótico, mas mostra apetite no Brasil por **frase + revisão espaçada**.
- **Copiar:** diferença destacada ao fim da frase, ignorar diacríticos, limite de novos por dia, i+1, destaque do novo, contexto que desambigua e meta de “N frases”.
- **Evitar:** nota manual, avalanche de revisões e frases que a própria pessoa inventa sem revisão.

### 2.8 Memrise

- **Mecânica:**
  - Duas palavras novas por vez, com **vídeos de nativos** pronunciando.
  - Testes de tocar, **digitar o que ouviu** e múltipla escolha.
  - **Speed Review** (revisão cronometrada) e **Difficult Words**, uma pilha das palavras que você errou ([FluentU](https://www.fluentu.com/blog/reviews/memrise-review/)).
- **A virada de 2023:**
  - Removeu os cursos da comunidade e o fórum para focar em conteúdo oficial, chatbot e vídeos. O CEO justificou que os usuários “tinham vocabulário grande mas não conseguiam usar a língua” ([Memrise CEO](https://memrise.com/blog/changes-to-memrise-update-from-our-ceo)).
  - **Revolta** pela perda de conteúdo e de autonomia ([Eurolinguiste](https://eurolinguiste.com/memrise-is-doing-away-with-user-generated-content-now-what/)).
- **Copiar:** “Palavras e frases difíceis” como pilha própria, revisão cronometrada opcional (combina com o arcade do PAC) e vozes variadas.
- **Evitar:** tirar do usuário o que ele construiu.

### 2.9 LingQ

- **Mecânica:**
  - *Input* compreensível: ler e ouvir conteúdo que a pessoa entende quase todo.
  - Toque numa palavra desconhecida e ela vira um “LingQ” **colorido toda vez que reaparece**. O sistema **conta palavras conhecidas** e mostra **a porcentagem de palavras novas** de cada texto ([blog LingQ](https://blog.thelinguist.com/comprehensible-input)).
- **Para nós:**
  - Mostrar **“palavras e chunks que você já domina”** como métrica de progresso.
  - **Colorir** o chunk novo dentro da frase.
  - Usar a contagem de palavras conhecidas para **escolher a próxima frase i+1** e no nivelamento.

### 2.10 MosaLingua (popular no Brasil)

- **Mecânica:**
  - Cartões com repetição espaçada em intervalos de **5 min, 7 h, 3 dias, 10 dias, 1 mês…** e **autoavaliação de 1 a 4** antes de ver a resposta.
  - Princípio 80/20 (o vocabulário mais útil) e **“frases‑modelo”**: estruturas simples que cobrem a maioria das situações ([MosaLingua: método](https://www.mosalingua.com/pt/about/o-metodo-mosa-learning/)).
  - Promete **600 palavras e frases em 2 meses com 10 min por dia** ([App Store](https://apps.apple.com/br/app/mosalingua-curso-de-idiomas/id858567694)).
  - A sessão padrão é de **5 cartões** (mais 5 a cada clique), com **áudio primeiro**: ouve, grava e só então vê a escrita. Há modo “mãos livres” ([Mezzoguild](https://mezzoguild.com/mosalingua-review), [StoryLearning](https://storylearning.com/blog/mosalingua-app-review)).
- **Reclamações:** repetitivo, “sem gamificação”, lento e travado, e cobrança agressiva ([Mezzoguild](https://mezzoguild.com/mosalingua-review), [App Store](https://apps.apple.com/br/app/mosalingua-curso-de-idiomas/id858567694)).
- **Copiar:** frases‑modelo 80/20, lotes de 5 com opção de “mais 5”, áudio primeiro e 10 min por dia como promessa clara.
- **Evitar:** UX travada e falta de jogo. O PAC tem jogo de sobra, o que é uma vantagem.

### 2.11 Assimil (fase passiva e fase ativa, a “segunda onda”)

- **Mecânica:**
  - Cerca de **100 lições** de diálogo com a **tradução na página ao lado** e notas curtas. **20 a 40 min por dia** ([Mezzoguild](https://mezzoguild.com/assimil-review), [Assimil/tiz](https://assimil.tiz.fr/en/articles/5-la-methode-assimil)).
  - **Fase de impregnação (lições 1 a 49):** ler, ouvir e repetir, sem produzir.
  - **Fase ativa (da lição 50 em diante):** continua avançando **e volta à lição 1**, agora **lendo a tradução e reproduzindo a frase na língua estrangeira com a resposta escondida**.
  - **A cada 7 lições, uma lição de revisão** das 6 anteriores ([Assimil/tiz](https://assimil.tiz.fr/en/articles/5-la-methode-assimil)).
- **Crítica:** só ler e traduzir não forma falante B2 ([Mezzoguild](https://mezzoguild.com/assimil-review)). Por isso o nosso precisa de áudio e ditado.
- **Para nós:** a **segunda onda é literalmente o pedido do dono** (tradução em cima, produzir em inglês). Duas coisas para copiar:
  - **Lição de revisão a cada 6 ou 7 lições.**
  - **“Onda 2”:** depois de X trilhas, as lições antigas voltam **em modo só tradução**, sem texto‑fantasma.

### 2.12 Pimsleur

- **Princípios:**
  - **Lembrança em intervalos crescentes** (*graduated interval recall*).
  - **Antecipação**: o aluno é chamado a **produzir antes de ouvir a resposta**, com uma pausa cronometrada e depois a confirmação.
  - **Vocabulário central** limitado e reciclado sem parar.
  - **Aprendizado orgânico** em conversa ([Pimsleur](https://www.pimsleur.com/the_pimsleur_method)).
- **Detalhes de uma análise independente:**
  - **Construção de trás para frente** (*backward build‑up*) para frases novas: começa pelo fim da palavra ou frase e vai acrescentando o começo, para manter a entonação natural.
  - Unidades de cerca de **30 min**, estritamente sequenciais, com **cerca de 80% de domínio para avançar**.
  - Pausas que chegam a **7–8 s** nos níveis altos.
  - As instruções passam aos poucos da língua materna para a língua‑alvo ([análise](https://courses.languagereactor.com/david/alc-english/raw/commit/adecabbc4d062182efd4cd12bf79b1138be11d98/pimsleur-study/ANALYSIS.md)).
- **Para nós:**
  - “Tradução em cima e digitar antes de ver” é a antecipação.
  - Frases longas (B1 em diante) podem ser montadas **por blocos**, com construção de trás para frente ou com a frase crescendo.
  - Um limiar de domínio de cerca de 80% para liberar a próxima passada ou lição.

### 2.13 Michel Thomas

- **Princípios:**
  - **Tirar o estresse** (“o estresse é a maior barreira para aprender”).
  - **Proibido decorar.** O professor é responsável pela compreensão.
  - A língua é quebrada em **blocos claríssimos** apresentados um a um, e só depois de absorvido um vem o próximo, até o aluno **montar as próprias frases** ([Michel Thomas](https://www.michelthomas.com/how-it-works/)).
- **Para nós:**
  - **Progressão por blocos combináveis** (I want → I want to eat → I don’t want to eat → Do you want to eat?).
  - **Feedback de erro sem drama**: nada de vermelho piscando nem som alto.

### 2.14 TypeLit.io

- **Mecânica:**
  - **Redigitar livros inteiros** (80+ obras em domínio público, 9 idiomas, entre eles inglês e português), com **WPM e precisão em tempo real**, destaque de erro “a cada tecla”, estatística por página, capítulo e livro, e **200+ patentes de nível**.
  - Diz que digitar literatura na língua‑alvo “constrói vocabulário pelo contexto em vez de decoreba” ([FAQ](https://www.typelit.io/faq)).
- **Para nós:** prova de que digitar texto **com sentido** é agradável e vira hábito. Mas o TypeLit é **cópia pura**: não há tradução, recordação nem revisão espaçada. Serve como modo bônus nas trilhas avançadas (C1): **“digite um texto curto com tradução em cima, por parágrafo”**, e não como núcleo.

### 2.15 keybr, Monkeytype e Ratatype (o motor)

- **keybr:**
  - Começa com **poucas letras frequentes** e **acrescenta letras quando você atinge a velocidade‑alvo**.
  - Mede **cada tecla** e gera lições **focadas nas teclas mais fracas**. Prevê quantas lições faltam para a meta ([README](https://github.com/aradzie/keybr.com)).
  - Uma reimplementação aberta documenta a fórmula: **confiança = (velocidade‑alvo ÷ velocidade real) × precisão**. **Precisão primeiro**: tecla rápida mas errada não libera a próxima. Teclas fracas recebem **até 4× mais peso** no sorteio, e a recomendação é de **15 a 20 min por dia** ([Keystrike: pedagogia](https://github.com/egno/keystrike/wiki/Typing-Pedagogy)).
- **Monkeytype:**
  - **Stop on error** desligado, por palavra ou por letra. O PAC já é “por letra”.
  - **Indicate typos**: mostra a letra certa **abaixo** ou **no lugar** da errada.
  - **Confidence mode**: sem backspace. **Blind mode**: esconde o texto, para digitar de memória.
  - **Lazy mode**: troca letras acentuadas pela base. **Strict space**.
  - Som de erro opcional, reinício rápido (Tab, Esc ou Enter), e no resultado as categorias de caractere correto, incorreto, extra e faltante, além do gráfico de WPM ([customização](https://mintlify.wiki/monkeytypegame/monkeytype/guides/customization), [recursos](https://mintlify.wiki/monkeytypegame/monkeytype/features)).
- **Ratatype:** treino guiado de digitação. O PAC já usa o estilo dele na “Chuva de Código”. Não foi analisado a fundo aqui.
- **Para nós:**
  - O **blind mode é a passada final** (só tradução).
  - O **indicate typos “abaixo”** é a ajuda depois de N erros na mesma posição.
  - A **confiança por tecla do keybr vira confiança por palavra ou chunk**: palavras que a pessoa erra muito ganham mais repetições e voltam em frases novas.

---

## 3. A ciência que decide o desenho (curta e aplicada)

| Achado | Dado | Fonte | Consequência para o PAC·ENGLISH |
|---|---|---|---|
| **Pistas decrescentes > cópia** | Digitando a palavra 6×: final **DC 40% × cópia 29%** (sem feedback) e **58% × 40%** (com feedback de 4 s). DC × cópia: d = 0,37 e 0,56. | [Finley et al. 2011, Tabela 2 e Fig. 1](https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/07/Finley_Benjamin_Hays_RBjork_Kornell_2011.pdf) | O “escrever várias vezes” tem que **apagar o fantasma aos poucos**. Cinco cópias com o modelo inteiro é desperdício. |
| Pistas que **aumentam** (começar sem nada) dão menos acertos na prática | AC 25% no final (sem feedback); com feedback sobe para 51% | idem | **Não começar a frase nova sem modelo.** Primeiro mostrar e ouvir, depois tirar. |
| DC funciona até onde a recordação comum falha | Material difícil sem feedback: DC > recordação comum = releitura | [Fiechter & Benjamin 2018 (Psychonomic)](https://featuredcontent.psychonomic.org/sherlock-holmes-and-mrs-h____n-the-mystery-of-diminishing-cues-retrieval-practice/) | Para o iniciante absoluto, a escada com fantasma é o que torna a recordação possível. |
| **Copiar** a palavra pode **atrapalhar** | Escrever ou copiar durante o estudo deu escore menor que não escrever | [Barcroft (TOPRA)](https://profiles.wustl.edu/en/publications/effects-of-word-and-fragment-writing-during-l2-vocabulary-learnin/) | Reforça: a cópia não pode ser o modo principal. A passada de cópia é só a primeira. |
| **Recordar > gerar ou reler** | Recordação intencional > geração | [Karpicke & Zaromb 2010 (notas)](https://notes.andymatuschak.org/zbtc1h8QyVdG8jeWLcPKuu) | As passadas de recordação (só tradução) são as que fixam. |
| Recordar > copiar (sala de aula) | Grupo de recordação > grupo de cópia | [Penn State](https://pure.psu.edu/en/publications/retrieval-practice-and-retention-of-course-content-in-a-middle-sc/) | idem |
| **Espaçar** dentro da sessão | O estudo usou em média 5 itens entre duas tentativas do mesmo par | Finley et al. 2011 | **Intercalar 5 frases**, nunca AAAAA. |
| **Espaçar** entre dias | HLR: +9,5% de retenção. FSRS a 90% como padrão | [Duolingo](https://blog.duolingo.com/how-we-learn-how-you-learn), [Anki](https://docs.ankiweb.net/deck-options.html) | Revisão espaçada por frase, com nota automática. |

---

## 4. Tabela comparativa rápida

| Produto | Unidade | Tradução visível? | Modelo visível ao produzir? | Digita? | Frase inteira? | Feedback de erro | Áudio | Revisão espaçada | Sessão típica |
|---|---|---|---|---|---|---|---|---|---|
| **Glossika** | frase | sim (desligável) | 1ª vez sim, depois some (romanização) | sim | **sim** | compara depois; pontuação opcional; acento flexível | **nativo, 3 velocidades, ditado** | sim (10:1) | 5 frases × 5 = 25 reps |
| **Clozemaster** | frase com 1 lacuna | sim | sim (menos a lacuna) | opcional (8 pts × 4) | não | **verde/vermelho ao vivo**, dica | TTS, ouvir antes | 1/10/30/180 dias, erro zera | rodada de 10 com até 5 revisões |
| **Lingvist** | frase com 1 lacuna | sim | sim (menos a lacuna) | sim | não | **typo × erro**, redigita, diacrítico leniente | sim | sim | 50 cartões por dia |
| **Duolingo** | exercício variado | sim | banco de palavras ou nada | opcional | às vezes | lista de 200 a 30 mil respostas aceitas | sim | HLR | lição curta |
| **Babbel** | diálogo | sim | lacunas | sim (lacunas) | parcial | só avança acertando | sim | 6 níveis | ~6 min |
| **Anki** | cartão | depende | não | opcional (`type:`) | sim | diff no fim; nota manual | se adicionar | SM‑2 / FSRS | 20 novos → ~200 revisões |
| **MosaLingua** | cartão (palavra ou frase) | sim | não | às vezes | às vezes | autoavaliação 1–4 | **áudio primeiro** | 5 min → 1 mês | 5 cartões, 10 min |
| **Assimil** | diálogo | **página ao lado** | onda 2: não | (escrita no papel) | **sim** | autocorreção | sim | revisão a cada 7 lições | 20–40 min |
| **Pimsleur** | fala | áudio L1 | não (antecipação) | não | sim | confirmação depois da pausa | **só áudio** | intervalos crescentes | 30 min |
| **TypeLit** | texto | não | **sim (cópia)** | sim | sim | erro por tecla | não | não | livre |
| **Monkeytype / keybr** | palavras | — | sim (blind opcional) | sim | — | por letra, typos abaixo | som | keybr: teclas fracas | 15–60 s / 15–20 min |
| **PAC·ENGLISH (proposta)** | **frase em cena** | **sim, em cima** | **escada: inteiro → parcial → iniciais → nada** | **sim** | **sim** | **por letra, tolerante, typo × erro** | **TTS en‑US, lento, ditado** | **por frase, nota automática** | **5–8 frases × ~5 passadas ≈ 10 min** |

---

## 5. Reclamações dos usuários, por tema (o que NÃO repetir)

1. **“Frases soltas, sem contexto, em vácuo”** — Glossika ([Actual Fluency](https://actualfluency.com/glossika), [Lingopie](https://lingopie.com/blog/glossika-review/)), Clozemaster ([StoryLearning](https://storylearning.com/clozemaster-review)), Lingvist ([FluentU](https://www.fluentu.com/blog/lingvist-review/)).
2. **“Repetição chata e monótona”** — Glossika (“cochilando”, [FluentU](https://fluentu.com/blog/reviews/glossika)), Lingvist ([Mezzoguild](https://www.mezzoguild.com/lingvist-review/)), MosaLingua ([Mezzoguild](https://mezzoguild.com/mosalingua-review)), Babbel ([StoryLearning](https://storylearning.com/blog/babbel-review)).
3. **“Frase artificial, absurda ou tradução errada”** — Duolingo ([Vanecek](https://mvanec.substack.com/p/duolingo-annoyances)), Clozemaster/Tatoeba ([fórum](https://forum.clozemaster.com/t/review-of-clozemaster-sentence-quality/7007), [fórum](https://forum.clozemaster.com/t/translations-are-often-misleading/46770)), Glossika (“formal ou datada”).
4. **“Correção implicante”** (acento, pontuação, sinônimo, ordem válida) — Duolingo ([Vanecek](https://mvanec.substack.com/p/duolingo-annoyances)), Lingvist ([FluentU](https://www.fluentu.com/blog/lingvist-review/), [Ajuda](https://lingvist.com/help/why-wont-you-accept-synonyms/)).
5. **“Um deslize zera tudo”** — Clozemaster ([StoryLearning](https://storylearning.com/clozemaster-review)).
6. **“Sem explicação do porquê”** — Glossika ([Lingopie](https://lingopie.com/blog/glossika-review/)).
7. **“Me impede de estudar”** (energia, vidas, paywall) — Duolingo ([Android Authority](https://www.androidauthority.com/quitting-duolingo-energy-system-3599842/)).
8. **“Gamificação vazia”** (XP fácil, ofensiva como fim em si) — Duolingo ([PCWorld](https://www.pcworld.com/article/2924235/why-i-fell-out-of-love-with-duolingo.html)).
9. **“Só revisão, nada novo”** / avalanche de revisões — Lingvist (trecho de busca), Anki ([manual](https://docs.ankiweb.net/deck-options.html)).
10. **“Nivelamento longo”** — Glossika ([Flexiclasses](https://flexiclasses.com/glossika-review/)).
11. **“Áudio ruim ou pouco claro”** — Babbel ([StoryLearning](https://storylearning.com/blog/babbel-review)).
12. **“Tiraram meu conteúdo e mexeram no meu progresso”** — Memrise ([Eurolinguiste](https://eurolinguiste.com/memrise-is-doing-away-with-user-generated-content-now-what/)), Duolingo (reorganização de curso).
13. **“Digitar no celular é difícil”** — Clozemaster ([fórum](https://forum.clozemaster.com/t/ideas-about-program-improvements/6684)).
14. **“Banco de palavras é fácil demais”** — Duolingo ([TypeLingo](https://addons.mozilla.org/firefox/addon/typelingo/), [blog](https://blog.duolingo.com/improving-how-duolingo-teaches-chinese-and-other-languages)).

---

## 6. MECÂNICAS RECOMENDADAS para o PAC·ENGLISH

Legenda de prioridade: **[MVP]** precisa estar no primeiro lançamento · **[v2]** logo depois · **[v3]** quando houver fôlego.

### M1. A ESCADA DE PASSADAS (texto‑fantasma que some) — o coração do curso **[MVP]**

**O quê:** cada frase é digitada umas **5 vezes**, e a cada vez o modelo em inglês mostra menos:

| Passada | O que aparece em cima | O que aparece na linha de digitar (fantasma) | Áudio | Objetivo |
|---|---|---|---|---|
| **P1 – Conhecer** | tradução PT + nota de 1 linha | **frase inteira** esmaecida (o motor de hoje) | toca sozinho | ver, ouvir e copiar com atenção |
| **P2 – Apoio** | tradução PT | frase com **as palavras de conteúdo apagadas** (ou ~40% das letras viram `_`) | tecla para ouvir | começar a recordar |
| **P3 – Iniciais** | tradução PT | **só a 1ª letra de cada palavra** e a pontuação: `I w__ t_ b__ a n__ p____.` | tecla para ouvir | recordar com uma muleta mínima |
| **P4 – Forma** | tradução PT | **só tracinhos** com o tamanho das palavras | tecla para ouvir | quase recordação livre |
| **P5 – Livre** | tradução PT | **nada** (só o cursor) | só depois de terminar | recordação total, o “blind mode” |

- **Por quê:** é o desenho que ganhou no experimento de Finley et al. 2011: pistas que diminuem, com a pessoa digitando o alvo inteiro em todas as tentativas (40% × 29% sem feedback, 58% × 40% com feedback). Glossika (a romanização some nas revisões), Assimil (da fase passiva para a ativa) e Pimsleur (antecipação) fazem versões do mesmo.
- **De quem copiamos:** Finley et al. 2011 (o desenho), Glossika (sumir o apoio), Monkeytype *blind mode* (a passada 5), Assimil onda 2.
- **No motor:** o `TypingBloc` não muda. Só muda **o que o `CodeView` desenha nas posições ainda não digitadas** (máscara por passada). O caractere esperado continua o mesmo. Já digitado = texto cheio, e o que falta segue a máscara da passada.
- **Adaptativo:**
  - Acertou a P3 **sem erro e sem ajuda**: pode **pular a P4**.
  - Errou muito na P5: ganha **uma P5 extra no fim da rodada** (passo de reaprendizado, como os passos de 1 min e 10 min do Anki).
  - O limiar de cerca de 80% do Pimsleur serve de referência.

### M2. Intercalar, nunca repetir em bloco **[MVP]**

- **O quê:** a rodada tem 5 a 8 frases. Cada passada percorre **todas** as frases em ordem embaralhada (A C B E D → P2 → …), e nunca a mesma frase duas vezes seguidas.
- **Por quê:** espaçamento dentro da sessão (lag de cerca de 5 no Finley). O Glossika embaralha as 25 repetições.
- **De quem:** Glossika, Finley.
- **Observação:** responde ao “vou escrever várias vezes” sem virar a cópia monótona de que reclamam no Glossika.

### M3. Tradução em cima NATURAL, com o “bloco novo” destacado nas duas línguas **[MVP]**

- **O quê:**
  - Em cima, o PT‑BR **natural** (“Estou morrendo de fome”, e não “Eu estou morrendo de fome” palavra por palavra).
  - O **bloco novo** (o i+1) aparece **na mesma cor no PT e no fantasma EN** (ex.: *estante* ↔ *bookshelf*).
  - Opcionalmente, uma **glosa literal** pequena quando a estrutura difere muito (*It’s cold* → “Faz frio” · lit.: “é frio”).
- **Por quê:** o Mairo manda destacar a palavra nova, o LingQ colore o que é novo e o Fluent Forever pergunta o que há de novo na frase. A tradução natural evita o “pensar em português palavra por palavra”, a crítica do Fluent Forever a traduzir, sem tirar a tradução que o dono pediu.
- **De quem:** Mairo Vergara, LingQ, Fluent Forever, Assimil (tradução ao lado).
- **Dado sugerido:** `dica` (PT natural), mais `literal?`, `novo?` (ex.: `"bookshelf|estante"`) e `conceito` (a nota de 1 linha, que já existe no esquema).

### M4. Frases‑modelo i+1 em CENAS (micro‑diálogos), nunca soltas **[MVP]**

- **O quê:**
  - Cada lição é **uma cena** (no café, no aeroporto, no daily da empresa, no code review…) com 5 a 8 falas encadeadas.
  - **Uma coisa nova por frase**, com o resto já conhecido.
  - A **fala anterior aparece em cinza acima** como contexto, o que desambigua: “Would you like some coffee?” → *“Yes, please. With milk.”*
- **Por quê:** é a reclamação nº 1 contra Glossika, Clozemaster e Lingvist (frase em vácuo). O MCD mostra que mais contexto deixa uma resposta só. Babbel, Assimil e Pimsleur usam diálogo.
- **De quem:** Babbel (situação real), Assimil (diálogo), Pimsleur (aprendizado orgânico), MCD (contexto que desambigua), Mairo (i+1).
- **Bônus de público:** o dono é desenvolvedor. Trilhas de **inglês para trabalho em TI** (reunião, PR, issue, entrevista) têm valor imediato e motivação alta.

### M5. Progressão por BLOCOS combináveis e variações (substituição) **[MVP]**

- **O quê:**
  - A trilha ensina um padrão e **varia uma peça por vez**: *I want coffee* → *I want to drink coffee* → *I don’t want coffee* → *Do you want coffee?* → *She wants coffee*.
  - Na revisão, entra a **variação**, e não a cópia idêntica.
- **Por quê:**
  - Michel Thomas (blocos claros, um de cada vez).
  - Pimsleur (vocabulário central reciclado).
  - MosaLingua (frases‑modelo 80/20).
  - O exemplo do Mairo (*The book is on the table* → *The computer is on the table*).
  - Corta a monotonia de repetir sempre a mesma frase.
- **De quem:** Michel Thomas, Pimsleur, MosaLingua, Mairo.

### M6. Áudio em toda frase, com velocidade lenta e passada de ditado **[MVP → v2]**

- **O quê:**
  - **[MVP]** A frase toca ao aparecer na P1. Uma tecla (ex.: `Ctrl+Espaço` ou `F2`; nunca uma tecla que o texto use) repete o áudio. Botão 🐢 0,75×. Ao terminar a P5, a frase toca inteira como recompensa e confirmação.
  - **[v2]** **Passada de ditado**: só áudio, sem PT e sem fantasma. Também “ouvir antes de ver”, como o *cloze‑listening* e o “Sentence Text Initially Hidden”.
- **Por quê:** o ponto forte do Glossika é o áudio nativo (75/100/125%). MosaLingua e Clozemaster começam pelo ouvido. Sem áudio, a pessoa decora a grafia e não o som (o argumento do Glossika de ligar som e letra).
- **De quem:** Glossika, Clozemaster, MosaLingua, Memrise (vozes variadas).
- **Atenção técnica:**
  - A **voz Gemini tem cota grátis de uns 10 áudios por dia** (comentário no código). Não serve para centenas de frases.
  - Use **`speechSynthesis` do navegador com voz en‑US** como padrão, ou **gere os áudios antes e empacote** (offline, com voz consistente), deixando o Gemini só para a nota em PT.
  - Escolha **uma variante** (sugestão: inglês americano) e mantenha a grafia coerente (*color*, *center*).

### M7. Feedback de erro letra a letra, gentil e informativo **[MVP]**

- **O quê** (em cima do “stop on error = letter” que o motor já tem):
  1. Errou: a letra esperada **treme de leve** (já existe `ultimoErrou`). Sem som alto e sem tela vermelha.
  2. **3 erros na mesma posição**: aparece **a letra certa embaixo do cursor**, como o *indicate typos: below* do Monkeytype. Nas passadas 3 a 5, isso marca a frase como **“com ajuda”**.
  3. Contar **erro por posição**, e não por tecla: dez teclas erradas no mesmo lugar contam como 1 lugar errado. Isso evita a cascata que destrói a precisão de quem trava.
  4. Ao terminar a frase, mostrar a **frase com as posições erradas sublinhadas**, como a diferença do Anki com `typeBad`/`typeMissed`, junto com o áudio.
- **Por quê:** Michel Thomas (o estresse é a barreira), Lingvist (typo não é erro inteiro), Monkeytype (*indicate typos*) e Anki (diferença no fim). A cor ao vivo do Clozemaster mostra que o feedback imediato é valorizado.
- **De quem:** Monkeytype, Lingvist, Anki, Clozemaster.

### M8. Correção tolerante no que não é inglês: pontuação, maiúscula e teclado **[MVP]**

- **O quê:**
  - **Pontuação final opcional** (`.`, `!`, `?`): se o esperado é pontuação final e a pessoa aperta Enter ou espaço, ou se a frase acaba ali, o motor considera a frase concluída.
  - **Vírgula opcional nas passadas 4 e 5**: se o esperado é `,` e veio espaço, o motor **consome a vírgula sozinho**. É o mesmo truque do “pula a indentação” que já existe.
  - **Maiúscula da 1ª letra da frase**: aceitar minúscula. O pronome *I* e os nomes próprios continuam exigindo maiúscula, porque isso é inglês de verdade e vale ensinar.
  - Manter as **equivalências que já existem**: aspas curvas e retas, travessão e hífen, teclas mortas do ABNT2, composição do US‑International. Incluir na bateria de testes de conteúdo frases com *o’clock*, *’cause*, *rock ’n’ roll*, *it’s*, *I’d*, *“quoted”* e *café / naïve / résumé* (raras; evitar no começo).
  - **Modo estrito** opcional nas configurações, para quem quiser pontuação exata (como o “Strict Diacritics” do Lingvist).
- **Por quê:** a reclamação nº 4 (correção implicante). O Glossika torna a pontuação opcional e o Lingvist e o Anki (`type:nc`) ignoram diacríticos.
- **De quem:** Glossika, Lingvist, Anki, Monkeytype (*lazy mode*).

### M9. Uma resposta certa por frase, mas com a pista que desambigua **[MVP]**

- **O quê:**
  - O motor tem um alvo só, e reproduzir as 200 a 30 mil respostas aceitas do Duolingo é inviável.
  - Por isso, nas passadas **com pista** (P2 a P4), **a pista já define a forma**: `I’_ …` mostra que é contração, e os tracinhos mostram o número de palavras.
  - Na **P5 (livre)**, aceitar um conjunto pequeno de **formas equivalentes declaradas no conteúdo** (`alt`: *I’m* / *I am*, *don’t* / *do not*). O motor trocaria de alvo na primeira divergência compatível com uma alternativa.
  - Se nada casar, contar como erro, **mas** com uma mensagem tipo Lingvist: “também está certo, mas aqui treinamos a forma X”, sem descontar como erro grave.
- **Por quê:** Duolingo (listas gigantes de respostas aceitas), Lingvist (sinônimo não aceito e o botão “meu sinônimo não foi aceito”), MCD (contexto que deixa uma resposta só).
- **De quem:** Lingvist, Duolingo, MCD.

### M10. Dica sob demanda em degraus (nunca travar) **[MVP]**

- **O quê:**
  - Nas passadas de recordação, uma tecla de ajuda (sugestão: `Tab`) **revela a próxima palavra** no fantasma.
  - Ficar parado uns 6 a 8 s faz a próxima letra aparecer fraquinha (as pausas de 7–8 s do Pimsleur servem de referência para o tempo de “pensar”).
  - Cada ajuda **rebaixa a nota da frase** na revisão espaçada, mas **não bloqueia nem pune com vida**.
- **Por quê:** o fórum do Clozemaster pede botões que revelem palavra por palavra. O Lingvist tem “Learn Word”, o Glossika permite espiar e o Babbel é criticado por travar o avanço.
- **De quem:** Clozemaster (pedido de usuários), Lingvist, Glossika.

### M11. Revisão espaçada por frase, com nota AUTOMÁTICA **[MVP simples → v2 FSRS]**

- **O quê:**
  - **[MVP]** Caixas fixas expansivas, por exemplo **mesmo dia (fim da rodada) → 1 d → 3 d → 7 d → 16 d → 35 d → 90 d**, inspiradas no Clozemaster (1/10/30/180) e no MosaLingua (5 min / 7 h / 3 d / 10 d / 1 mês).
  - **Errar desce 1 ou 2 caixas, e não zera.**
  - **Nota automática** com o que o motor já mede:
    - P5 perfeita, sem ajuda, em velocidade normal = *fácil*.
    - Até 2 posições erradas = *bom*.
    - Ajuda ou 3 ou mais posições erradas = *de novo* (desce caixa e repete na sessão).
  - **[v2]** FSRS com retenção‑alvo de 90% e simulação da carga.
- **Revisão no dia seguinte:** já começa em **modo P5 (só PT)**. Se a pessoa falhar, **desce um degrau na escada** (P3 com iniciais) só para aquela frase.
- **Por quê:**
  - HLR do Duolingo: “praticar à beira de esquecer”, +9,5% de retenção.
  - FSRS e Anki.
  - Não é preciso autoavaliação (MosaLingua e Anki pedem 1 a 4), porque o dado objetivo já existe.
  - O reset para zero do Clozemaster é criticado.
- **De quem:** Duolingo, Anki/FSRS, Clozemaster, MosaLingua.

### M12. Sessão fechada de ~10 min: revisão primeiro, depois a cena nova **[MVP]**

- **O quê:**
  - “Sessão do dia” = **revisões vencidas** (com teto) + **1 cena nova** (5 a 8 frases × escada ≈ 25 digitações).
  - Com 40 caracteres por frase a uns 30 WPM, dá cerca de 6 min digitando, mais áudio e leitura: uns 10 min.
  - Depois da sessão, **“mais uma cena?”** é opcional.
- **Limite de novos por dia** (padrão: 1 a 2 cenas, configurável). Mostrar a previsão: “amanhã você terá ~N revisões”.
- **Por quê:**
  - Glossika: revisar antes, 1 sessão nova por dia nas 2 primeiras semanas, proporção 10:1.
  - Anki: 20 novos geram ~200 revisões.
  - Babbel: 6 min. MosaLingua: 10 min e lotes de 5.
  - Duolingo: quem maratona abandona.
- **De quem:** Glossika, Anki, Babbel, MosaLingua, Duolingo.

### M13. Nivelamento curto e pulável, e “testar para pular trilha” **[MVP]**

- **O quê:**
  - Na primeira entrada: **“Começar do zero”** ou **“Fazer teste de 3 min”**.
  - O teste tem cerca de 12 frases de níveis crescentes em **modo P3 (iniciais)** e para quando errar muito. O nível define a trilha inicial, e as trilhas anteriores ficam marcadas como “testadas”: liberadas, com revisão leve agendada.
  - Em cada trilha, um botão **“Já sei isso: testar”** (5 frases em P5; passou, pula).
  - Por frase, um **“já sei”** opcional que manda a frase para uma caixa alta.
- **Por quê:** o nível do dono é desconhecido. O nivelamento longo e obrigatório do Glossika é criticado, e o Duolingo tem nivelamento e salto de unidade. O fórum do Clozemaster pede um botão “já sei”.
- **De quem:** Duolingo, Glossika (pelo contraexemplo), Clozemaster.

### M14. Lição de revisão a cada 6 lições, e a “Onda 2” **[v2]**

- **O quê:**
  - Depois de cada 6 cenas, uma **lição de revisão** que mistura as falas das 6 em modo P4 e P5.
  - Ao chegar na metade do curso (ou a cada nível CEFR concluído), **a Onda 2 é liberada**: as cenas antigas voltam **só em P5**, como no Assimil.
- **Por quê:** Assimil (revisão a cada 7 lições e fase ativa a partir da lição 50). Encaixa no mapa de jornada que o PAC já tem.
- **De quem:** Assimil.

### M15. “Minhas frases difíceis” e confiança por palavra **[v2]**

- **O quê:**
  - Uma pilha automática com as frases que mais deram erro ou ajuda.
  - **Confiança por palavra ou bloco**, como a confiança por tecla do keybr (velocidade × precisão). Palavras fracas ganham **peso maior** na escolha das próximas variações e revisões.
  - Um mapa de calor simples de “palavras que você mais erra”.
- **De quem:** keybr/Keystrike (peso até 4× nas teclas fracas), Memrise *Difficult Words*, Duolingo *Mistakes*.

### M16. Construção por blocos para frases longas (B1 em diante) **[v2]**

- **O quê:**
  - Para frases de 12 palavras ou mais, a P1 vira **3 mini‑digitações**: o bloco final, depois o meio + o final, depois a frase inteira (construção de trás para frente, como no Pimsleur).
  - Alternativa: a **frase cresce** (*I’d like* → *I’d like to book* → *I’d like to book a table for two*), como os blocos do Michel Thomas.
- **De quem:** Pimsleur, Michel Thomas.

### M17. Nota curta de uso (o porquê, em 1 linha) **[MVP]**

- **O quê:**
  - Embaixo da tradução, opcional e recolhível: **uma linha** em PT (“*‘I’m starving’* é exagero comum, significa só ‘muita fome’”).
  - Nas trilhas, a **teoria curta** que o PAC já tem (blocos h/p/tip/warn) para padrões gramaticais.
- **Por quê:** a crítica ao Glossika (nenhuma explicação, sem contexto cultural). O Clozemaster acrescentou explicações por IA. O Babbel e o Assimil têm notas curtas. Ao mesmo tempo, o Mairo e o Michel Thomas mostram que **gramática pesada atrapalha**, então tem que ser 1 linha, nunca uma aula.
- **De quem:** Assimil, Babbel, Clozemaster.

### M18. Métricas que medem memória, não só dedo **[MVP]**

- **O quê:**
  - No HUD e no fim da sessão: **frases dominadas** (caixa ≥ 7 d), **palavras e blocos conhecidos** (estilo LingQ), **precisão na P5** e **sequência de dias**. WPM fica como métrica secundária.
  - No ranking: **frases dominadas** e **precisão de recordação**, e não velocidade.
- **Por quê:** o LingQ conta palavras conhecidas e o Clozemaster mostra progresso por frequência. A crítica da PCWorld (XP sem aprender) mostra que a métrica errada gera o comportamento errado.
- **De quem:** LingQ, Clozemaster, PCWorld (contraexemplo).

### M19. Ofensiva e metas gentis (sem vidas nem energia) **[MVP]**

- **O quê:**
  - **Ofensiva diária** = completar a “sessão do dia” (revisões + 1 cena) ou só as revisões.
  - **Congelamento automático** (1 por semana, acumula até 2).
  - **Escolher a meta** na primeira semana (“leve / normal / intenso”).
  - **Marcos** com animação (7, 30 e 100 dias; 100, 500 e 1.000 frases dominadas, ecoando a meta de 1.000 frases do Mairo).
  - **Nunca bloquear estudo** por vidas ou energia.
- **Por quê:**
  - Duolingo: aposta +14% D7; amuleto +4% e −5% de perda; 7 dias = 3,6× de conclusão; folga na meta aumenta a motivação.
  - O sistema de energia gerou revolta e abandono.
- **De quem:** Duolingo (o que funciona e o que evitar), Mairo (a meta de 1.000 frases).

### M20. Avanço automático com respiro e reinício rápido **[MVP]**

- **O quê:**
  - Terminou a frase: toca o áudio, mostra a diferença por cerca de 1,2 s e avança. Enter avança na hora.
  - Opção para **desligar o avanço automático**.
  - `Esc` reinicia a frase atual, como o reinício rápido do Monkeytype.
- **De quem:** Lingvist (o avanço automático pode ser desligado), Monkeytype (reinício rápido).

### M21. Arcade e jogos com frases de inglês **[v3]**

- **O quê:** reusar Chuva, Rali e Dart Turismo com **palavras e blocos das frases já estudadas** (nunca conteúdo novo). Uma revisão cronometrada opcional no estilo *Speed Review* do Memrise.
- **Por quê:** o MosaLingua é criticado por falta de jogo, e o PAC já tem um arcade forte. Revisão disfarçada de jogo aumenta o volume de repetições sem cansar.
- **De quem:** Memrise *Speed Review*, PAC (o que já existe).

### M22. Produção livre corrigida por IA **[v3]**

- **O quê:** nas trilhas avançadas, um desafio aberto (“escreva 2 frases contando seu dia usando *used to*”). O Prof. Dash (Gemini) devolve a versão corrigida em verde, como as correções do Busuu, e a frase corrigida **vira cartão** da pessoa.
- **De quem:** Busuu (correção), Clozemaster (explicação por IA), *sentence mining* (a frase vira cartão).

### M23. “Minhas frases” (mineração pessoal) **[v3]**

- **O quê:** a pessoa cola uma frase em inglês que viu num filme ou no trabalho, a IA sugere a tradução natural e a nota, e a frase entra na escada e na revisão.
- **Por quê:** Anki, Mairo e MosaLingua deixam adicionar cartões próprios. A revolta contra o Memrise mostra que **o conteúdo da pessoa nunca pode sumir**.
- **De quem:** Anki/Mairo (mineração), MosaLingua, Memrise (contraexemplo).

### M24. Texto‑fantasma de frase, não de código **[MVP]**

- **O quê:**
  - Para inglês, uma fonte **proporcional legível** (ou uma monoespaçada mais humana).
  - O cursor sublinha a letra atual. As palavras ficam com espaço claro entre si, porque o espaço é tecla esperada.
  - **Sem realce de sintaxe.**
  - A tradução PT fica em cima, menor e mais apagada que a linha de digitação, mas sempre legível.
- **Por quê:** o PAC foi feito para código, e para frases o foco é ler e lembrar. O TypeLit mostra que digitar prosa precisa de uma tipografia calma.
- **De quem:** TypeLit, Monkeytype (minimalismo e modo foco).

---

## 7. ANTI‑PADRÕES (o que evitar), com evidência e antídoto

| # | Anti‑padrão | Evidência | Antídoto no PAC·ENGLISH |
|---|---|---|---|
| A1 | **Copiar a frase 5× com o modelo inteiro visível** | Cópia: 29% e 40% × 40% e 58% com pistas decrescentes ([Finley 2011](https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/07/Finley_Benjamin_Hays_RBjork_Kornell_2011.pdf)); copiar atrapalha ([Barcroft](https://profiles.wustl.edu/en/publications/effects-of-word-and-fragment-writing-during-l2-vocabulary-learnin/)); “cochilando” no Glossika | Escada M1 |
| A2 | **Repetir a mesma frase em bloco (AAAAA)** | Espaçamento (Finley); repetição monótona (Glossika, MosaLingua) | Intercalar M2, variações M5 |
| A3 | **Frases soltas, sem cena** | Glossika, Clozemaster, Lingvist | Cenas e diálogos M4 |
| A4 | **Frases absurdas** (“the bear drinks beer”) **ou formais e datadas** | O Duolingo admite que você não vai usá‑las e não cita pesquisa ([blog](https://blog.duolingo.com/how-silly-sentences-can-help-you-learn)); irritação ([Vanecek](https://mvanec.substack.com/p/duolingo-annoyances)); Glossika datado | Humor só **dentro de situação plausível**; frases que um nativo diria hoje |
| A5 | **Tradução ruim, literal ou de segunda mão** | Tatoeba / traduções indiretas no Clozemaster ([fórum](https://forum.clozemaster.com/t/translations-are-often-misleading/46770)) | Tradução natural escrita direto EN↔PT, revisada; glosa literal só como extra |
| A6 | **Prompt ambíguo com motor de alvo único** | Duolingo precisa de 200 a 30 mil respostas; reclamação de sinônimos no Lingvist | Pista que define a forma (M9), linha de contexto (M4), `alt` curto na P5 |
| A7 | **Punir pontuação, maiúscula inicial, apóstrofo curvo ou acento de tecla morta** | Duolingo (acentos); Glossika e Lingvist lenientes por padrão | M8 |
| A8 | **Um erro zera a frase** | Clozemaster ([StoryLearning](https://storylearning.com/clozemaster-review)) | Desce 1 ou 2 caixas; typo ≠ erro (M11, M7) |
| A9 | **Vidas ou energia que bloqueiam estudar** | Energia do Duolingo ([Android Authority](https://www.androidauthority.com/quitting-duolingo-energy-system-3599842/)) | Nada bloqueia; ajuda só rebaixa a nota (M10) |
| A10 | **XP fácil e ofensiva como fim em si** | [PCWorld](https://www.pcworld.com/article/2924235/why-i-fell-out-of-love-with-duolingo.html) | Ofensiva conta a sessão do dia; ranking por frases dominadas (M18, M19) |
| A11 | **Maratona e avalanche de revisões** | Quem maratona abandona (Duolingo); 20 novos → 200 revisões (Anki); “só revisão” (Lingvist) | Teto de novos, previsão de carga, revisão primeiro (M12) |
| A12 | **Nivelamento longo e obrigatório** | Glossika ([Flexiclasses](https://flexiclasses.com/glossika-review/)) | 3 min, pulável, e “testar trilha” (M13) |
| A13 | **Múltipla escolha ou banco de palavras como núcleo** | Duolingo admite que é outra coisa; extensões para voltar a digitar | O núcleo é digitar a frase inteira; MC só no quiz opcional |
| A14 | **Zero explicação ou aula de gramática demais** | Glossika (zero); Mairo e Michel Thomas (regra demais trava) | Nota de 1 linha + teoria curta opcional (M17) |
| A15 | **Mexer no progresso e no conteúdo do usuário** | Memrise e Duolingo | Novas trilhas **só no fim** (o PAC já faz isso no Dart); ids estáveis por frase |
| A16 | **Feedback de erro agressivo** (vermelho, som alto, tremor forte) | Michel Thomas: o estresse é a barreira | Feedback discreto; som de erro opcional (M7) |
| A17 | **Sem áudio ou com áudio ruim** | Babbel (narrador pouco claro); o ponto forte do Glossika é o áudio | TTS en‑US de qualidade ou áudio pré‑gerado, 0,75× (M6) |
| A18 | **Avançar antes de a pessoa ver a correção** | Lingvist precisou de opção para desligar | Respiro de cerca de 1,2 s + diferença + opção (M20) |
| A19 | **Contar o erro por tecla em cascata** | (dedução do motor atual: travar numa letra soma vários erros) | Erro por posição (M7) |
| A20 | **Frase longa demais para o nível** | i+1 do Mairo: 3 ou mais desconhecidas cansam | Limite de comprimento por nível + blocos (M16) |

---

## 8. Como fica uma tela e uma sessão (esboço)

```
┌──────────────────────────────────────────────────────────────┐
│ ☕ No café · cena 2/6           🔥 12 dias   ✔ 184 frases     │
│ ──────────────────────────────────────────────────────────── │
│   (antes)  “Would you like anything else?”          🔊        │
│                                                              │
│   Só um café, por favor. Pra viagem.          ← PT em cima   │
│   ⓘ “to go” = pra viagem (EUA)                ← nota 1 linha │
│                                                              │
│   J___ a c_____, p_____. T_ g_.               ← P3 iniciais  │
│   Just a c▌                                   ← já digitado  │
│                                                              │
│   🔊 ouvir (Ctrl+Espaço) · 🐢 0,75× · Tab = revelar palavra  │
│   passada ●●●○○   frase 3/6   precisão 96%                   │
└──────────────────────────────────────────────────────────────┘
```

**Roteiro da “Sessão do dia” (~10 min):**

1. **Revisões vencidas** (máx. ~30), em P5. Quem falha desce para P3 só naquela frase.
2. **Cena nova**: 6 falas.
   - P1 (vê, ouve, copia) em ordem.
   - P2, P3, P4 e P5 com ordem embaralhada a cada passada.
   - Frases perfeitas pulam a P4. Frases com muitos erros na P5 ganham uma P5 extra no fim.
3. **Fim**: resumo (frases novas, frases dominadas, palavras difíceis), previsão de amanhã e ofensiva.
4. Opcional: “mais uma cena?” ou “jogar no arcade com as frases de hoje”.

**Campos sugeridos por frase** (compatível com `{cod, dica, conceito}`; a decisão final é de quem desenha o conteúdo):

```json
{
  "id": "a1-cafe-03",
  "cod": "Just a coffee, please. To go.",
  "dica": "Só um café, por favor. Pra viagem.",
  "conceito": "“to go” = pra viagem (EUA). No Reino Unido: “takeaway”.",
  "novo": "To go|Pra viagem",
  "contexto": "Would you like anything else?",
  "alt": [],
  "nivel": "A1"
}
```

---

## 9. Decisões em aberto para quem desenha o curso

- **D1 – Variante:** inglês americano (sugestão) ou britânico? Isso afeta a grafia, o áudio e as notas.
- **D2 – Contrações:** ensinar *I’m* desde a primeira frase (é como se fala) e aceitar *I am* na P5 via `alt`? Sugestão: sim.
- **D3 – A tradução some no topo?** O dono pediu explicitamente a tradução em cima, então ela **fica sempre**. Para trilhas C1, oferecer **opcionalmente** a pista em inglês (paráfrase ou definição), como os cartões inglês/inglês do Mairo, ou só o áudio (ditado). Sempre como opção, nunca como padrão.
- **D4 – Número de passadas:** 5 é o padrão (bate com o 5×5 do Glossika). Com a pulada adaptativa, a média real deve ficar entre 4 e 5.
- **D5 – Áudio:** `speechSynthesis` no navegador (grátis, mas a qualidade e as vozes variam por sistema) ou áudios pré‑gerados no build (consistente e offline, mas pesa no tamanho e custa uma vez)?
- **D6 – Celular:** o motor é desktop‑first. Digitar no celular é difícil (fórum do Clozemaster). No celular, aceitar o teclado virtual com tolerância extra a autocorreção, ou oferecer só a revisão?
- **D7 – Tamanho do currículo:** a referência de mercado é de **1.000 frases para um básico sólido** (Mairo) e **6.000 palavras mais frequentes** para um vocabulário amplo (Lingvist, MosaLingua). Isso dá a ordem de grandeza de frases por nível.

---

## 10. Lista final: de quem copiamos cada mecânica

| Mecânica | Copiado de |
|---|---|
| Escada de fantasma que some (M1) | Finley et al. 2011 · Glossika · Assimil onda 2 · Monkeytype blind |
| Intercalar as frases (M2) | Glossika (25 reps embaralhadas) · Finley (lag) |
| Bloco novo destacado e tradução natural (M3) | Mairo Vergara · LingQ · Fluent Forever |
| Cenas e diálogos i+1 com linha de contexto (M4) | Babbel · Assimil · Pimsleur · MCD · Mairo |
| Blocos e variações (M5) | Michel Thomas · Pimsleur · MosaLingua · Mairo |
| Áudio, 0,75× e ditado (M6) | Glossika · Clozemaster · MosaLingua · Memrise |
| Erro gentil, letra embaixo e diferença no fim (M7) | Monkeytype · Lingvist · Anki · Clozemaster |
| Pontuação e maiúscula tolerantes (M8) | Glossika · Lingvist · Anki `type:nc` · Monkeytype lazy |
| Pista que desambigua e `alt` (M9) | Lingvist · Duolingo · MCD |
| Dica em degraus (M10) | Clozemaster (pedido de usuários) · Lingvist · Glossika |
| Revisão espaçada com nota automática (M11) | Duolingo HLR · Anki/FSRS · Clozemaster · MosaLingua |
| Sessão de 10 min, revisão primeiro, teto de novos (M12) | Glossika · Anki · Babbel · MosaLingua · Duolingo |
| Nivelamento pulável e testar trilha (M13) | Duolingo · Glossika (contraexemplo) · Clozemaster |
| Revisão a cada 6 lições e Onda 2 (M14) | Assimil |
| Frases difíceis e confiança por palavra (M15) | keybr · Memrise · Duolingo |
| Construção por blocos de trás para frente (M16) | Pimsleur · Michel Thomas |
| Nota de 1 linha (M17) | Assimil · Babbel · Clozemaster |
| Métricas de memória (M18) | LingQ · Clozemaster |
| Ofensiva gentil (M19) | Duolingo |
| Avanço automático e reinício rápido (M20) | Lingvist · Monkeytype |
| Arcade com frases (M21) | Memrise Speed Review · PAC |
| Produção livre corrigida por IA (M22) | Busuu · Clozemaster IA |
| Minhas frases (M23) | Anki · Mairo · MosaLingua |
| Tipografia de prosa (M24) | TypeLit · Monkeytype |

---

## 11. Fontes

**Ciência**
- Finley, Benjamin, Hays, Bjork & Kornell (2011). *Benefits of accumulating versus diminishing cues in recall*. JML 64:289–298. https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/07/Finley_Benjamin_Hays_RBjork_Kornell_2011.pdf
- Fiechter & Benjamin (2018), resumo na Psychonomic Society: https://featuredcontent.psychonomic.org/sherlock-holmes-and-mrs-h____n-the-mystery-of-diminishing-cues-retrieval-practice/
- Barcroft, *Effects of word and fragment writing during L2 vocabulary learning*: https://profiles.wustl.edu/en/publications/effects-of-word-and-fragment-writing-during-l2-vocabulary-learnin/
- Karpicke & Zaromb (2010), notas de Andy Matuschak: https://notes.andymatuschak.org/zbtc1h8QyVdG8jeWLcPKuu
- Recordação × cópia em sala de aula (Penn State): https://pure.psu.edu/en/publications/retrieval-practice-and-retention-of-course-content-in-a-middle-sc/
- Settles & Meeder (2016), *A Trainable Spaced Repetition Model for Language Learning* (ACL): https://preview.aclanthology.org/landing_page/P16-1174
- FSRS explicado: https://domenic.me/fsrs/

**Glossika**
- Ajuda: http://help.glossika.com/en/articles/6611459-step-4-the-most-effective-way-to-train-on-glossika-legacy-app
- Ajuda (digitação): https://help.glossika.com/en/articles/3256617-typing-how-does-typing-help-me-speak-better-what-s-the-best-way-to-do-it
- Blog (nova interface, regras de digitação): https://ai.glossika.com/blog/glossika-all-new-learning-interface
- Reviews: https://flexiclasses.com/glossika-review/ · https://lingopie.com/blog/glossika-review/ · https://actualfluency.com/glossika · https://fluentu.com/blog/reviews/glossika

**Clozemaster**
- FAQ: https://www.clozemaster.com/faq · Home: https://www.clozemaster.com/
- Fórum: https://forum.clozemaster.com/t/new-setting-sentence-text-initially-hidden/55526 · https://forum.clozemaster.com/t/review-of-clozemaster-sentence-quality/7007 · https://forum.clozemaster.com/t/translations-are-often-misleading/46770 · https://forum.clozemaster.com/t/ideas-about-program-improvements/6684
- Reviews: https://storylearning.com/clozemaster-review · https://ling-app.com/blog/clozemaster-review/

**Lingvist**
- https://lingvist.com/blog/learn-with-lingvist-in-three-easy-steps/ · https://lingvist.com/help/how-do-you-count-mistakes · https://lingvist.com/help/why-wont-you-accept-synonyms/ · https://lingvist.com/help/the-card-changes-too-quickly/
- Reviews: https://www.fluentu.com/blog/lingvist-review/ · https://www.mezzoguild.com/lingvist-review/

**Duolingo**
- https://blog.duolingo.com/why-does-duolingo-teach-weird-sentences/ · https://blog.duolingo.com/how-silly-sentences-can-help-you-learn
- https://blog.duolingo.com/how-duolingo-streak-builds-habit · https://blog.duolingo.com/how-streaks-keep-duolingo-learners-committed-to-their-language-goals
- https://blog.duolingo.com/how-we-learn-how-you-learn · https://blog.duolingo.com/learning-how-to-help-you-learn-introducing-birdbrain
- https://blog.duolingo.com/improving-how-duolingo-teaches-chinese-and-other-languages · https://blog.duolingo.com/how-machine-learning-helps-duolingo-prioritize-course-improvements · https://blog.duolingo.com/guide-to-duolingo-practice-hub/
- Críticas: https://mvanec.substack.com/p/duolingo-annoyances · https://www.androidauthority.com/quitting-duolingo-energy-system-3599842/ · https://duolingo.fandom.com/wiki/Energy · https://www.pcworld.com/article/2924235/why-i-fell-out-of-love-with-duolingo.html · https://addons.mozilla.org/firefox/addon/typelingo/

**Babbel, Busuu, Memrise, LingQ**
- https://www.babbel.com/how-babbel-works · https://storylearning.com/blog/babbel-review · https://www.alllanguageresources.com/babbel-review/
- https://www.busuu.com/en/how-to/corrections
- https://memrise.com/blog/changes-to-memrise-update-from-our-ceo · https://eurolinguiste.com/memrise-is-doing-away-with-user-generated-content-now-what/ · https://www.fluentu.com/blog/reviews/memrise-review/
- https://blog.thelinguist.com/comprehensible-input

**MosaLingua**
- https://www.mosalingua.com/pt/about/o-metodo-mosa-learning/ · https://www.mosalingua.com/pt/segredo-mosalingua-um-especialista-aprendizagem/ · https://apps.apple.com/br/app/mosalingua-curso-de-idiomas/id858567694
- Reviews: https://storylearning.com/blog/mosalingua-app-review · https://mezzoguild.com/mosalingua-review

**Anki, Fluent Forever, MCD, Mairo Vergara**
- https://docs.ankiweb.net/templates/fields.html · https://docs.ankiweb.net/deck-options.html
- https://grahammann.net/book-notes/fluent-forever-gabriel-wyner
- https://www.textkit.com/t/cloze-deletion-or-massive-context-cloze-deletion/15350
- Guia do Mairo Vergara (PDF): https://www.mairovergara.com/wp-content/uploads/2015/09/Como-Aprender-Ingl%C3%AAs-O-guia-definitivo-V1.4.pdf
- https://www.tabnews.com.br/DiogenesLima/aprenda-ingles-um-saas-com-o-metodo-do-mairo-vergara
- Debate sobre redigitar depois do erro: https://community.wanikani.com/t/let-us-type-in-the-correct-response-when-learning-and-after-getting-something-wrong/66845

**Assimil, Pimsleur, Michel Thomas**
- https://assimil.tiz.fr/en/articles/5-la-methode-assimil · https://mezzoguild.com/assimil-review
- https://www.pimsleur.com/the_pimsleur_method · Análise independente: https://courses.languagereactor.com/david/alc-english/raw/commit/adecabbc4d062182efd4cd12bf79b1138be11d98/pimsleur-study/ANALYSIS.md
- https://www.michelthomas.com/how-it-works/

**Digitação**
- TypeLit: https://www.typelit.io/faq
- keybr: https://github.com/aradzie/keybr.com · Pedagogia (Keystrike): https://github.com/egno/keystrike/wiki/Typing-Pedagogy
- Monkeytype: https://mintlify.wiki/monkeytypegame/monkeytype/guides/customization · https://mintlify.wiki/monkeytypegame/monkeytype/features
