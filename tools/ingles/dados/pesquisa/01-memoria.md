# Dossiê 01: a ciência de memorizar frases digitando

**Frente:** como maximizar a memorização de frases em inglês (L2) quando a pessoa digita a frase inteira várias vezes com a tradução em PT-BR visível em cima.
**Para quem:** quem vai desenhar a mecânica do curso de inglês do PAC·DART (motor de digitação letra a letra com texto-alvo esmaecido).
**Data da pesquisa:** outubro de 2026. As fontes estão numeradas entre colchetes [n] e listadas com URL no fim do documento.

---

## 0. Resumo executivo

1. **Digitar é melhor que só ler, mas digitar copiando é a forma mais fraca de digitar.** Produzir a palavra (falar, digitar, escrever) melhora a memória em relação à leitura silenciosa: é o *production effect* [1][2]. Já copiar uma palavra nova sem precisar recuperá-la rendeu menos que não escrever nada quando o tempo era fixo [10][11]. Também perdeu para a recordação a partir da tradução, inclusive no teste de forma uma semana depois [13]. Num experimento em que se digitava a palavra-alvo 6 vezes com ela sempre visível, ficaram 29% a 40% no teste final. Mostrar cada vez menos letras rendeu 40% a 58% [15].
2. **O que fixa é a recuperação.** Digitar a frase sem vê-la, só com a tradução em cima, é o *testing effect* [7][8]. Num estudo clássico, quem continuou sendo testado lembrou 80% uma semana depois. Quem só continuou estudando lembrou cerca de 36% [7]. O efeito médio nas metanálises fica entre g = 0,50 e 0,61 [8].
3. **As repetições precisam ser intercaladas, nunca seguidas.** Repetir o mesmo item em sequência (massed) foi a pior condição: 20% de retenção após 2 dias, contra 45% com cinco itens entre as repetições [24]. Na metanálise, espaçar a recuperação contra repeti-la em bloco deu g ≈ 0,74 [22]. Em L2, o efeito do espaçamento é de médio a grande [21].
4. **Esmaecer o modelo aos poucos (fading, ou vanishing cues) é a ponte entre copiar e lembrar.** Começar com o modelo inteiro e tirar pistas a cada tentativa supera tanto a cópia constante quanto começar do zero sem feedback [15][16]. Quanto menos pistas a pessoa precisa para acertar, melhor ela retém depois [18].
5. **O feedback depois de um erro é obrigatório.** Mostrar a resposta certa após um erro aumentou a retenção em uma semana em **494%** [9]. Sem feedback e com taxa de acerto de 50% ou menos nas tentativas, o *testing effect* some [8].
6. **Para quantidade de repetições, o ponto ótimo é moderado e depois espalhado em dias.** Cinco ou sete recuperações numa sessão superam uma ou três. Por minuto investido, porém, uma rende mais [39]. Dobrar o treino no mesmo dia (10 contra 5 tentativas) não deixa vantagem detectável após 4 semanas [40]. A receita com melhor custo-benefício é recuperar até 3 acertos e depois reaprender 3 vezes em dias bem espaçados [41][43].
7. **Expandir ou manter fixos os intervalos dá praticamente no mesmo para a retenção final** (g = 0,03) [22][21]. Expandir mantém a taxa de acerto mais alta durante o treino [25], o que ajuda a motivação. O que importa é **atrasar a primeira recuperação** em vez de fazê-la logo depois de ver [24].
8. **Dormir entre as sessões de aprendizagem conta.** Reaprender depois de uma noite de sono exigiu metade das tentativas e deu retenção bem maior em 6 meses [61]. Por isso a primeira revisão fica para o dia seguinte.
9. **Áudio entra como modelo no primeiro contato e como feedback depois de cada acerto.** Não deve tocar antes de uma tentativa de memória, porque entrega a resposta. Variar as vozes ajuda a aprender vocabulário em L2 [50]. O laço fonológico é o mecanismo que aprende formas sonoras novas [49]. Ditado imediato dá ganho que desaparece em 2 semanas. Reconstruir de memória rende mais [52].
10. **Para o agendamento, FSRS é o melhor algoritmo aberto e já existe em Dart** (pacote `fsrs` 2.0.1, FSRS-6 com 21 parâmetros) [67][68][69]. Na previsão de memória ele bate o modelo do Duolingo, HLR (log loss 0,346 contra 0,469) [68]. Leitner com caixas de intervalos fixos serve de alternativa simples.
11. **Na nota de cada digitação, o principal é a precisão por palavra digitada de memória.** Dicas usadas rebaixam a nota. O tempo relativo à velocidade de cópia da própria pessoa só desempata entre "bom" e "fácil" (como no ARTS, que agenda por velocidade e precisão [63]). Precisão em modo cópia não informa nada sobre memória.

**Recomendação central (detalhes na seção 5).** Cada frase nova é digitada **5 vezes na lição**, sempre intercalada com outras frases (lags de cerca de 3, 5 e 7 digitações e uma rodada final). Os níveis de apoio são, em ordem: **modelo completo esmaecido + áudio**, **só as iniciais**, **só o esqueleto**, **escondido** e **escondido de novo na prova final**. A tradução fica sempre em cima, e a pessoa sempre digita em inglês. Nos dias seguintes há 1 digitação de memória por revisão, agendada por FSRS-6 com retenção desejada de 0,90 e a primeira revisão no dia seguinte. Um erro leva a feedback, à cópia corrigida e a uma nova tentativa na mesma sessão.

---

## 1. Como ler este dossiê

- **Força da evidência.** Uso três níveis: **forte** (metanálises ou várias replicações), **moderada** (alguns estudos bons e coerentes) e **fraca** (um estudo só, contexto distante, ou analogia minha).
- **Distância do nosso caso.** Quase tudo o que existe foi testado com **pares de palavras** (L1 ou palavra estrangeira). Não encontrei estudo que teste exatamente "digitar frases inteiras de L2 com tradução visível e pistas esmaecendo". O caso mais próximo é o COLT [62], em que alunos **digitavam** a tradução em espanhol de **palavras e frases curtas** a partir do inglês, com repetição espaçada personalizada. Também está perto Finley et al. 2011 [15]: palavras estrangeiras **digitadas** com letras aparecendo ou sumindo. As recomendações extrapolam dessas bases e eu sinalizo onde.
- **"Digitação" (pass).** Neste documento é uma tentativa completa de digitar a frase. **Lag** é o número de outras digitações entre duas digitações da mesma frase.

---

## 2. O que a pesquisa diz, fenômeno por fenômeno

### 2.1 Production effect: produzir é melhor que ler (forte, com ressalvas)

- **O que é.** Palavras lidas em voz alta são mais lembradas que palavras lidas em silêncio. A produção acrescenta traços sensório-motores distintivos ao registro do episódio [1].
- **Digitar também conta.** Soletrar, escrever e **digitar** melhoram a memória explícita em relação à leitura silenciosa. Nenhuma dessas formas iguala a fala em voz alta [2][1]. **Imaginar** que digita ajuda, mas **digitar de fato** ajuda mais [4].
- **Também vale para frases e dura.** O efeito aparece com pares de palavras e **frases**, persiste por **1 semana** e melhora o desempenho em teste de lacunas sobre textos lidos em voz alta um dia antes [5].
- **Ressalva crucial: o efeito é relativo.** Ele é grande quando a mesma lista mistura itens produzidos e itens lidos em silêncio. Entre pessoas diferentes (todo o material produzido contra todo lido) ele cai para **g ≈ 0,37** em reconhecimento [3]. Em evocação livre, o efeito entre listas costuma não aparecer [1]. **Dizer "yes" repetidamente** não ajuda. A produção precisa ser específica do item [1].
- **Implicação.** Digitar todas as frases ainda supera só ler, mas o ganho vindo da produção é modesto se tudo for produzido. O grosso do ganho tem que vir da **recuperação** (2.3) e do **espaçamento** (2.5). Uma alavanca barata é pedir, como opção, que a pessoa **fale a frase em voz alta enquanto digita ou logo depois**, já que a fala é a produção mais forte [2].

### 2.2 Generation effect: gerar é melhor que ler (forte)

- Uma metanálise de 86 estudos e 445 tamanhos de efeito achou **d ≈ 0,40** a favor de gerar a informação em vez de lê-la pronta [6].
- **Moderadores relevantes para nós** [6]:
  - o efeito **cresce com intervalos de retenção maiores**;
  - é maior com **menos itens**;
  - **some ou cai em listas "puras"** (tudo gerado contra tudo lido), de novo um efeito relativo;
  - é menor em evocação livre (d = 0,32).
- **Implicação.** Toda digitação com apoio parcial, como iniciais ou esqueleto, já é geração e vale mais que a cópia integral.

### 2.3 Testing effect: recuperar é o que fixa (forte)

- **Experimento-chave.** Karpicke e Roediger, na Science em 2008 [7]: 80 pares de palavras suaíli–inglês aprendidos até acertar. Depois disso, cada item era ou não estudado de novo e ou não testado de novo.
  - **Continuar estudando** depois de já saber **não teve efeito** na recordação após 1 semana.
  - **Continuar testando** teve efeito grande: **cerca de 80%** contra **cerca de 36%** de recordação na semana seguinte.
  - As **previsões** dos alunos sobre o próprio desempenho **não se correlacionaram** com o desempenho real.
- **Metanálises.** Rowland (2014): **g = 0,50** contra reestudo, com 159 tamanhos de efeito. Adesope et al. (2017): **g = 0,61**, com 272 tamanhos de efeito [8].
  - Rowland também mostra que **o feedback aumenta o efeito**.
  - Em estudos de laboratório **sem feedback** e com **acerto de 50% ou menos** nas tentativas de prática, **não houve testing effect** [8].
- **Feedback.** Pashler et al. (2005) estudaram 258 pessoas aprendendo luganda–inglês [9]:
  - mostrar a resposta certa **depois de um erro** aumentou a retenção em 1 semana em **494%**;
  - feedback depois de acerto **quase não fez diferença**, mesmo quando a pessoa estava insegura.
- **Errar tentando também ensina.** Tentativas de recuperação **mal-sucedidas** seguidas da resposta melhoram o aprendizado posterior [37]. **Chutar** a tradução de uma palavra estrangeira antes de ver a resposta deixa uma memória melhor que estudar o par pronto, **mesmo quando o chute está sempre errado**. O mecanismo parece ser a curiosidade e o processamento mais intenso do feedback [38].
- **Implicação.** O "digitar de memória com a tradução em cima" é exatamente o tipo de prática que a pesquisa favorece: recordação com pista em L1 e produção em L2. Errar é aceitável, **desde que haja feedback imediato e corretivo**.

### 2.4 Copiar contra recordar: o ponto mais importante para este curso (moderada a forte)

O pedido do dono, "vou escrever ela várias vezes", tende naturalmente para a **cópia repetida**. A pesquisa é bem clara sobre o limite disso.

| Estudo | O que comparou | Resultado |
|---|---|---|
| Barcroft 2006 [10] | Aprendizes de espanhol **copiando** 12 palavras novas contra não escrever outras 12, vendo par palavra–figura com tempo fixo | Vocabulário produtivo **maior sem escrever**, tanto no teste imediato quanto 2 dias depois |
| Barcroft 2007 [11] | Copiar a palavra contra copiar fragmento contra não escrever | **Não escrever > copiar palavra > copiar fragmento** |
| *Re-examining word writing* (ITL 2018) [12] | Copiar com tempo limitado, copiar com tempo **livre** e não copiar | Com o mesmo tempo, pouca diferença. Com **tempo livre** para escrever e aprender, a cópia **ganhou** das outras condições |
| Candry, Decloedt & Eyckmans 2020 [13] | 179 alunos, 15 palavras, 15 s cada: **copiar várias vezes** contra **recuperar a palavra em L2 a partir da tradução** contra só olhar o par | **Recuperação > as duas outras**, no teste imediato e em 1 semana. A cópia ganhou de só olhar no teste imediato de forma e **perdeu** no teste atrasado de forma. A recordação de significado foi sempre pior na cópia |
| Finley et al. 2011 [15] | Palavras de iñupiaq **digitadas** 6 vezes: modelo sempre completo ("study-only"), letras **sumindo** (DC) ou letras **aparecendo** (AC) | Teste final: **cópia 29%** e **DC 40%** (Exp. 1, sem feedback). **Cópia 40%** e **DC 58%** (Exp. 2, com feedback). Durante o treino a cópia acertava 91% a 98%, mas isso não virou memória |

Há ainda um apoio vindo da alfabetização: **soletrar ou produzir** a palavra gera melhor aprendizado ortográfico que só ler [73]. Escrever frases com palavras novas melhora a recordação imediata em relação a ler frases, **mas essa vantagem some no teste atrasado** [74].

**Por que a cópia é fraca.** Na cópia a pessoa pode processar só a forma superficial, letra por letra, sem precisar recuperar nada. Barcroft chama isso de "output forçado sem acesso ao significado", que consome recursos de processamento [10][11]. É o mesmo princípio dos níveis de processamento: o processamento raso deixa traço fraco. Quem digita bem consegue copiar com fluência dando pouca atenção ao sentido. Isso é uma inferência minha, coerente com [10][13][15], e não um estudo específico. Para quem desenha o curso, a cópia fluente e "bonita" é o pior indicador de aprendizagem que existe.

**Implicação.** A cópia tem papel legítimo e curto: **1 digitação no primeiro contato**, com significado visível (a tradução em cima) e sem pressão de tempo [12]. Ela serve para mapear forma e significado e para a produção. **Todas as outras repetições precisam exigir alguma recuperação.**

### 2.5 Espaçamento e lag: intercalar as repetições (forte)

- **Metanálise geral.** Cepeda et al. (2006) reuniram 839 avaliações em 317 experimentos [19]:
  - espaçar supera repetir em bloco;
  - o intervalo ótimo entre estudos **cresce com o tempo que se quer reter**.
- **A "crista" temporal.** Cepeda et al. (2008) estudaram mais de 1.350 pessoas, com revisão até 3,5 meses depois e teste até 1 ano depois [20]. O intervalo ótimo cai de **cerca de 20–40%** do intervalo de retenção (quando se quer lembrar em 1 semana) para **cerca de 5–10%** (quando se quer lembrar em 1 ano).
- **Em L2.** Kim e Webb (2022) analisaram 98 tamanhos de efeito de 48 experimentos com N = 3.411 [21]:
  - espaçamento com efeito **de médio a grande**;
  - espaçamento curto empata com o longo em teste imediato, **mas perde** em teste atrasado;
  - expandir e manter fixo são **equivalentes**.
  - Outros estudos de L2 [71][72] também mostram espaçado > em bloco no teste atrasado.
- **Recuperação espaçada contra recuperação em bloco.** A metanálise de Latimier et al. reúne 29 estudos [22]. O resultado é **g = 1,02**, corrigido para **g ≈ 0,74** depois do ajuste de viés de publicação.
- **Dentro da sessão.** Karpicke e Roediger (2007, Exp. 1, pares de vocabulário) [24]:

  | Esquema (itens entre as tentativas) | 10 min | 2 dias |
  |---|---|---|
  | Em bloco (0–0–0) | 47% | **20%** |
  | Expandido (1–5–9) | **71%** | 33% |
  | Fixo (5–5–5) | 62% | **45%** |

- **Pilha grande ou pilha pequena.** Kornell (2009) [23]:
  - estudar **uma pilha grande** de cartões, ou seja, com mais espaço entre as repetições, superou estudar 4 pilhas pequenas separadas;
  - o espaçamento foi melhor para **90%** dos participantes;
  - mesmo assim, **72%** acharam que o bloco tinha funcionado melhor.
  - Nakata e Webb [28] mostram que o tamanho do bloco em si pouco importa **se o espaçamento for igual**. O que manda é o espaçamento.
- **Muito longo prazo.** Bahrick et al. (1993) acompanharam 4 pessoas por 9 anos com 300 pares de palavras [27]. **13 sessões a cada 56 dias** deram retenção **comparável a 26 sessões a cada 14 dias**.
- **Implicação.** Dentro da lição, **nunca repetir a mesma frase em sequência**. A exceção é a correção imediata depois de um erro, que é reestudo e não prática. Nos dias seguintes, os intervalos crescem conforme a frase fica estável.

### 2.6 Intervalos expandidos ou fixos, e a primeira recuperação (forte)

- Karpicke e Roediger (2007) [24]:
  - expandir (1–5–9) ganha em 10 min, mas **perde em 2 dias** para o fixo (5–5–5): 33% contra 45%, d = 0,50;
  - no Exp. 3, o que realmente importou foi **atrasar a primeira tentativa**: 52% contra 44% em 2 dias, fosse o resto expandido ou fixo.
- Kang et al. (2014) [25] estudaram vocabulário ao longo de 4 semanas:
  - **expandido**: dias 1 → 3 → 9 → 28;
  - **fixo**: dias 1 → 10 → 19 → 28;
  - os dois esquemas empataram no teste **56 dias depois**;
  - o **expandido manteve a recordação média bem mais alta durante o treino**.
- Latimier et al. [22]: expandido contra fixo, **g = 0,032** (sem diferença). Com **mais de 4 exposições** por item há uma tendência a favor do expandido (g ≈ 0,20, sem significância).
- Nakata (2015, flashcards em L2): pequena vantagem do expandido, que some com correção estrita [26].
- **Precedente.** O agendamento de Pimsleur, de 1967, usava intervalos de 5 s, 25 s, 2 min, 10 min, 1 h, 5 h, 1 dia, 5 dias, 25 dias, 4 meses e 2 anos [70].
- **Implicação.**
  - Na lição, a **primeira tentativa com apoio reduzido não vem logo após a cópia**: espera pelo menos 2 ou 3 outras digitações.
  - Nos dias seguintes, os intervalos se expandem (é o que o FSRS faz). Isso mantém a taxa de acerto alta, o que é bom para motivação, sem custo para a retenção.

### 2.7 Intercalar temas contra agrupar, e a interferência semântica (moderada, com nuances)

- **Intercalar categorias diferentes** não é a mesma coisa que espaçar as repetições do mesmo item. A metanálise de Brunmair e Richter (2019), com 59 estudos, achou [29]:
  - efeito geral de **g = 0,42**;
  - **g = 0,67** com pinturas;
  - **vantagem do bloco** quando o material eram **palavras** (**g = −0,39**);
  - intercalar ajuda mais quando as categorias são parecidas entre si e exigem discriminação.
- **Gramática em L2.** Nakata e Suzuki (2019) testaram 5 estruturas [30]. Intercalar gerou mais erros no treino, mas **foi melhor que o bloco em 1 semana**, sobretudo para quem sabia menos.
- **Agrupamento semântico.** Ensinar juntas palavras do mesmo campo (frutas, cores, sinônimos) causou interferência em Tinkham e Waring [32]. Estudo mais controlado [31] não achou diferença nos escores, mas os itens semanticamente relacionados **geraram mais erros de interferência**, e o espaçamento ajudou menos esses itens. **Agrupar por tema**, como uma cena de restaurante, tende a ajudar [32].
- **Implicação.**
  - A lição pode e deve ser **temática** ("no aeroporto").
  - **Evite pôr na mesma lição frases quase idênticas que diferem por um sinônimo ou uma preposição**, como *look at* / *look for* / *look after*. Elas devem aparecer em lições diferentes e se misturar só nas revisões, que intercalam lições naturalmente.

### 2.8 Vanishing cues e fading: mostrar cada vez menos do modelo (moderada)

- **Origem.** Glisky, Schacter e Tulving (1986) criaram o "método das pistas que somem" para ensinar vocabulário de informática a pacientes amnésicos [16]. Letras da palavra-alvo são retiradas sistematicamente ao longo das tentativas. O aprendizado foi lento e dependia muito da **primeira letra**, mas todos chegaram a produzir as palavras sem pista e retiveram por 6 semanas.
  - No método original, **as letras se acumulam dentro de uma tentativa** quando a pessoa precisa de ajuda, e **diminuem entre tentativas** [15].
- **Em pessoas sem lesão.** Finley et al. (2011) [15]:
  - **pares inglês–iñupiaq com palavras de 5 letras, digitados**: 6 tentativas por item, lag médio de 5 (de 3 a 7);
  - **DC**: começa com a palavra inteira e tira 1 letra por tentativa;
  - **AC**: começa sem letras e põe 1 por tentativa;
  - **cópia**: palavra sempre inteira.

  | Condição | Acerto no treino (tentativas 1→6) | Teste final, Exp. 1 (sem feedback) | Teste final, Exp. 2 (com feedback) |
  |---|---|---|---|
  | Cópia (sempre visível) | .91 → .96 | .29 | .40 |
  | **DC (pistas diminuindo)** | .89 → .51 | **.40** | **.58** |
  | AC (pistas aumentando) | .12 → .95 | .25 | .51 |

  - Como os autores explicam, DC produz recuperações **bem-sucedidas** e AC produz recuperações **difíceis**. O **feedback** resgata parte do AC.
  - Eles sugerem combinar **pistas que se acumulam dentro da tentativa** (ajuda sob demanda) com **pistas que diminuem entre tentativas**, ajustando ao desempenho [15]. É exatamente o desenho recomendado aqui.
- **Quanto menos pista, melhor.** Quanto menos pistas a pessoa precisou para acertar no teste intermediário, melhor ela foi no teste final [18].
- **Ritmo de retirada.** Material mais difícil e memória mais fraca pedem retirada mais **gradual**. Itens fáceis e memória melhor permitem retirada **rápida** [17].
- **Precedente pedagógico.** O "cover, copy, compare" (olhar, cobrir, escrever de memória e comparar) é uma intervenção de ortografia com histórico de eficácia em escolas [75]. É, na prática, a mesma sequência modelo → memória → feedback.
- **Implicação.** O motor do PAC·DART, com texto-alvo esmaecido, já é o nível 0 dessa escada. Basta criar os níveis intermediários (iniciais e esqueleto) e o nível escondido, mais a ajuda sob demanda.

### 2.9 Desirable difficulties e metacognição (forte)

- Bjork e Bjork distinguem **força de recuperação**, que é a facilidade de acessar agora, de **força de armazenamento**, que é o quanto o item está enraizado [33].
  - As condições que mais aumentam a força de recuperação durante o treino (repetir em bloco, ver o modelo) **não** são as que mais aumentam a força de armazenamento.
  - São **dificuldades desejáveis**: espaçar, intercalar, testar em vez de reapresentar, e variar as condições.
- **Mais esforço com sucesso é melhor.** Recuperações difíceis, mas bem-sucedidas, deixam memória mais forte [34]. Intervalos maiores entre tentativas (por exemplo, 34 itens contra 6) tornam a recuperação mais difícil e o resultado final melhor. Aumentar o número exigido de acertos tem **retorno decrescente** [34].
- **As pessoas julgam mal.**
  - 72% preferiram o bloco, que rendeu menos [23].
  - As previsões não se correlacionaram com o desempenho [7].
  - Deixar a pessoa **descartar** os cartões que "já sabe" teve efeito **pequeno, mas consistentemente negativo** [35].
- **Dificuldade ótima, como heurística.** Para uma ampla classe de algoritmos de aprendizagem, a taxa de erro de treino ótima é de **cerca de 15,87%**, ou seja, cerca de **85% de acerto** [36]. É um resultado matemático para redes e algoritmos de gradiente, não um experimento com humanos aprendendo línguas. Uso como **alvo de calibração**, junto com o limite de Rowland: sem feedback e com 50% de acerto ou menos, o *testing effect* some [8].
- **Implicação.**
  - Não ofereça botão de "já sei, pular" sem uma prova de memória.
  - Mire **80–90% de acerto** nas digitações de memória, ajustando o ritmo de fading e a quantidade de frases novas.
  - Explique para o usuário, no app, por que a lição não é cópia em bloco. A sensação de que o bloco "rende mais" é uma ilusão documentada.

### 2.10 Quantas repetições? Overlearning, critério e reaprendizagem espaçada (forte)

- **Repetições na mesma sessão.** Nakata (2017) estudou 98 japoneses com 16 pares inglês–japonês e 1, 3, 5 ou 7 recuperações [39]. **5 e 7 superaram 1 e 3** em todos os testes, inclusive com mais de 2 semanas. Com o **tempo controlado**, porém, **1 recuperação deu o maior ganho por minuto**.
- **Overlearning.** Rohrer et al. (2005) compararam 5 tentativas com 10 tentativas de pares palavra–definição [40]. Os ganhos foram visíveis em 1 semana e **quase indetectáveis em 4 semanas**. Treinar a mais no mesmo dia é ineficiente.
- **Critério inicial mais reaprendizagem.** Rawson e Dunlosky (2011) reuniram 533 estudantes e mais de 100 mil respostas [41]:
  - testaram de 1 a 4 acertos na sessão inicial e de 1 a 5 sessões de reaprendizagem até 1 acerto;
  - o efeito do critério inicial é forte **antes** da reaprendizagem e **diminui** conforme as reaprendizagens se acumulam;
  - reaprender dá **grande ganho de retenção com pouco custo extra**;
  - a prescrição é **3 acertos na primeira sessão e depois 3 reaprendizagens bem espaçadas**.
- **O que cada acerto a mais melhora.** Mais acertos na sessão melhoram a memória associativa (pista↔alvo) e a memória do próprio alvo e da pista [42].
- **Na prática.** No guia de *successive relearning* [43], a primeira sessão de 8 a 10 definições leva 30–40 min, a primeira reaprendizagem cerca de 15 min e a seguinte menos de 5 min. Com alunos do 8º ano, 3 sessões de reaprendizagem levaram a **cerca de 60%** de recordação 1 mês depois.
- **Visão do Anki (FSRS).** O manual afirma que "repetir um cartão várias vezes no mesmo dia não contribui significativamente para a memória de longo prazo". Por isso recomenda **etapas de aprendizagem curtas e poucas** [44].
- **Implicação.**
  - **5 digitações por frase nova na lição** cabem no ponto ótimo de Nakata (5–7 > 1–3).
  - Mais que isso no mesmo dia tende a desperdiçar tempo [40][44].
  - O critério da lição deve ser **2 recordações sem ajuda** (3 no modo "memorização forte"), com o restante do esforço levado para **revisões em dias diferentes**.

### 2.11 Digitação contra escrita à mão (moderada; pouco decisivo para o nosso caso)

- **A favor da mão:**
  - em listas ditadas, a evocação livre foi melhor para palavras escritas à mão que digitadas, sem diferença em reconhecimento [45];
  - ao aprender **letras novas** (o alfabeto árabe, 42 adultos), escrever à mão deu aprendizado mais rápido e mais generalização que digitar ou ver vídeo [46].
- **Sem diferença:**
  - em aprendizado ortográfico de crianças com feedback, as duas formas empataram, com cerca de 80% de reconhecimento e 60–69% de soletração em 1 e 7 dias. **A habilidade prévia de digitar explicou 8% a mais da variância** no grupo que digitava [47];
  - para verbos irregulares do inglês, a mão não foi superior à digitação [48].
- **Digitar é produção.** Produz um efeito de produção real [2][4].
- **Implicação.**
  - O dono já domina o alfabeto latino. A vantagem mais robusta da mão é aprender **formas de letras novas**, o que não se aplica aqui.
  - Ele é programador e digita bem, e a habilidade de digitar modera o ganho [47].
  - **Digitar é uma escolha razoável.** O que importa é *como* se digita: recuperando, e não copiando.

### 2.12 Áudio, ditado e fonologia (moderada)

- **O laço fonológico** é o componente da memória de trabalho que retém padrões sonoros desconhecidos enquanto o registro permanente se forma. É central para aprender a **forma sonora** de palavras novas [49].
- **Variar as vozes ajuda.** Variar o falante, o estilo de fala e a velocidade **melhora** o aprendizado de vocabulário em L2. Variar volume ou altura (F0) não melhora [50].
- **Ouvir os outros produzindo ajuda menos.** Ouvir outra pessoa produzir ajuda a memória, mas menos que produzir você mesmo [1].
- **O insumo incidental é fraco.** Ler, ler ouvindo ou só ouvir histórias ensina pouco vocabulário. Depois de 3 meses, quase nada dos 28 itens ficou [51]. É mais um argumento pela prática **deliberada**. O aprendizado deliberado de palavras novas gera representações lexicais com algum grau de automaticidade [60].
- **Ditado contra reconstrução.** Num estudo com 142 aprendizes chineses de inglês [52]:
  - **ditado** (escrever segmentos logo depois de ouvir) e **dictogloss** (reconstruir o texto de memória) ganharam de perguntas de compreensão no teste imediato;
  - **a vantagem diminuiu em 2 semanas, mais ainda no ditado**;
  - os itens **recuperados com sucesso na reconstrução** foram os mais lembrados.
  - Ditado imediato está mais perto da cópia (transcrição auditiva) do que da recuperação.
- **Implicação.**
  - Áudio no **primeiro contato** com a frase, como modelo fonológico.
  - Áudio **depois** de cada digitação de memória, como feedback e para fixar a pronúncia.
  - **Nunca antes de uma tentativa de memória**, porque o áudio entrega a resposta.
  - **Alternar 2 ou 3 vozes** (por exemplo, americana e britânica, masculina e feminina) entre as digitações e revisões [50].
  - O ditado entra como **tipo extra de revisão** para frases já estáveis, para treinar escuta. Não substitui a digitação com a tradução em cima.

### 2.13 Frase contra palavra solta; chunks e fórmulas (moderada)

- **Contexto pode desviar a atenção.** Tarefas descontextualizadas funcionaram tão bem ou melhor que contextualizadas para memorizar palavras. O contexto pode tirar a atenção da palavra-alvo [53].
- **Repetição importa.** Os ganhos crescem com o número de encontros (1, 3, 7 ou 10 encontros em frases) [54]. Na metanálise de 26 estudos, a correlação entre número de encontros e aprendizado incidental é **r = 0,34**, e o **espaçamento** é um dos moderadores [55].
- **Fórmulas e chunks dão fluência.** Alunos treinados a notar sequências fixas (colocações e expressões) foram julgados **mais proficientes** por juízes cegos, e a contagem de sequências fixas na fala acompanhou a nota de proficiência [56]. Adultos retêm quais palavras aparecem juntas no insumo, e a **repetição** melhora essa retenção [57]. A **memorização de textos** é prática associada a aprendizes chineses bem-sucedidos (Ding, 2007) e melhorou a escrita de alunos que memorizavam um texto por semana, com reprodução literal testada [58].
- **A forma literal se perde rápido.** Depois de 80 a 160 sílabas de texto intercalado, o reconhecimento de mudanças **sintáticas**, mesmo com o sentido preservado, cai a quase o acaso. O **sentido** permanece [59]. Decorar a forma exata (que é o que o dono quer, para internalizar a estrutura do inglês) **exige** prática que force a forma exata, ou seja, recordação literal digitada, e não só compreensão.
- **Implicação.**
  - A frase é a unidade certa para **chunks e estrutura**.
  - Para não diluir a atenção, cada frase deve ter **um alvo novo destacado** (uma palavra ou um chunk), realçado na tradução e no inglês, com o resto já conhecido ou transparente.
  - A **tradução PT deve ser precisa o bastante para apontar uma única forma inglesa** (ver 4.3).

### 2.14 Sono e consolidação (moderada)

- Mazza et al. (2016) estudaram 40 pessoas com 16 pares francês–suaíli, aprendidos até acertar tudo [61]:
  - um grupo aprendeu de manhã e reaprendeu à noite, sem dormir no meio;
  - o outro aprendeu à noite e reaprendeu na manhã seguinte, com sono no meio;
  - quem dormiu precisou de **cerca de 3 tentativas** para reaprender tudo, contra **cerca de 6** de quem ficou acordado;
  - a retenção em **1 semana e 6 meses** foi bem melhor com sono entre as sessões.
- **Implicação.** A **primeira revisão no dia seguinte** fica justificada. Se houver notificação, o melhor horário para revisar é de manhã, de preferência quando a lição nova foi à noite.

### 2.15 Personalização em sala real (moderada a forte)

- **COLT.** Lindsey, Shroyer, Pashler e Mozer (2014) acompanharam 179 alunos de espanhol durante um semestre [62]:
  - a ferramenta mostrava **palavras e frases curtas em inglês** e os alunos **digitavam a tradução em espanhol**;
  - o feedback trazia a resposta e a tela ficava verde ou vermelha, com **pelo menos 3 s** de feedback;
  - havia um botão de "não sei", que contava como erro e mostrava a resposta;
  - aceitavam-se **várias traduções corretas**, e **maiúsculas e pontuação eram ignoradas**;
  - a sessão começava com estudo **até acertar cada item** (descarte após o acerto) e seguia para a revisão.
  - **Resultado:** a revisão personalizada (modelo bayesiano por aluno e item) deu **+16,5%** sobre a revisão em bloco e **+10,0%** sobre o espaçamento genérico num exame 28 dias depois do fim do semestre. Isso com cerca de 30 min por semana, cerca de 10% do tempo do curso.
- **ARTS.** Agendar de forma adaptativa pela **velocidade e precisão** de cada resposta superou agendamentos fixos que se expandiam, com ganhos que duraram 2 semanas e transferiram para avaliação padronizada 2 a 3 meses depois [63].
- **Implicação.** É o argumento mais direto para um agendador **por frase e por usuário** (FSRS) e para usar o **tempo de resposta** como sinal secundário.

---

## 3. Algoritmos de repetição espaçada viáveis num app web simples

### 3.1 Leitner (1972)

- **Como funciona.** Caixas numeradas. Um acerto **promove** o cartão para a caixa seguinte, revisada com menos frequência. Um erro manda o cartão **de volta para a caixa 1** [65].
  - Exemplo comum com 3 caixas: diária, a cada 3 dias e a cada 5 dias.
  - O original usava divisórias de 1, 2, 5, 8 e 14 cm, e a revisão disparava quando a divisória enchia [65].
- **Prós.** Trivial de implementar e explicar, e os intervalos são visíveis ao usuário.
- **Contras.** Ignora quão difícil o acerto foi e o quanto atrasou. Voltar à caixa 1 é punitivo para quem esqueceu só um pouco.

### 3.2 SM-2 (SuperMemo, 1987–1990)

Os passos originais, segundo a SuperMemo [64]:
- intervalos I(1) = 1 dia, I(2) = 6 dias e, para n > 2, I(n) = I(n−1) × EF;
- EF (fator de facilidade) começa em 2,5 e nunca fica abaixo de 1,3;
- notas de 0 a 5, com nota menor que 3 = erro;
- atualização: EF' = EF + (0,1 − (5−q)·(0,08 + (5−q)·0,02));
- nota menor que 3 recomeça as repetições sem mudar o EF;
- **no fim da sessão, repetir todos os itens com nota menor que 4 até tirarem 4 ou mais**.

**Prós:** simples e conhecido. **Contras:** o EF despenca e trava em 1,3 (o "ease hell"), não modela a probabilidade de lembrar e não aprende com dados.

### 3.3 HLR, o half-life regression do Duolingo (2016)

- Estima a **meia-vida** de cada palavra na memória do aluno a partir do histórico e de traços do item [66].
- Reduziu o erro de previsão em mais de 45% em relação às linhas de base.
- No teste A/B, aumentou em 9,5% a retenção diária de usuários em sessões de prática [66].
- **No benchmark aberto atual ele fica bem atrás do FSRS** [68].

### 3.4 FSRS, o Free Spaced Repetition Scheduler (recomendado)

**Modelo DSR.** Cada cartão tem **Dificuldade D** (1 a 10), **Estabilidade S** (em dias; S é o intervalo em que R = 90%) e **Recuperabilidade R** (probabilidade de lembrar agora) [67]. Notas: 1 = Again, 2 = Hard, 3 = Good, 4 = Easy.

Fórmulas principais, conforme a wiki oficial [67]:
- **Curva de esquecimento (FSRS-6):** R(t,S) = (1 + fator · t/S)^(−w20), com fator = 0,9^(−1/w20) − 1, de modo que R(S,S) = 90%.
  - No FSRS-4.5/5, DECAY = −0,5 e FACTOR = 19/81.
- **Próximo intervalo para a retenção desejada r:** I(r,S) = (S/fator) · (r^(1/decay) − 1). Com r = 0,9, I = S.
- **Estabilidade inicial:** S0(G) = w[G−1]. Com os padrões do FSRS-6: Again 0,21 d, Hard 1,29 d, **Good 2,31 d**, Easy 8,30 d.
- **Dificuldade inicial (FSRS-5/6):** D0(G) = w4 − e^(w5·(G−1)) + 1.
- **Atualização da dificuldade:**
  - amortecimento linear: ΔD = −w6·(G−3), D' = D + ΔD·(10−D)/9;
  - reversão à média: D'' = w7·D0(4) + (1−w7)·D'.
- **Estabilidade após acerto:** S'r = S · (e^w8 · (11−D) · S^(−w9) · (e^(w10·(1−R)) − 1) · [w15 se Hard] · [w16 se Easy] + 1).
  - Itens mais difíceis crescem menos.
  - Itens já estáveis crescem menos.
  - Acertar quando R estava mais baixo faz crescer **mais**. É o efeito do espaçamento.
- **Estabilidade após esquecer:** S'f = w11 · D^(−w12) · ((S+1)^w13 − 1) · e^(w14·(1−R)).
- **Revisões no mesmo dia (FSRS-6):** S' = S · e^(w17·(G−3+w18)) · S^(−w19).
- **Parâmetros padrão do FSRS-6 (21):** [0.212, 1.2931, 2.3065, 8.2956, 6.4133, 0.8334, 3.0194, 0.001, 1.8722, 0.1666, 0.796, 1.4835, 0.0614, 0.2629, 1.6483, 0.6014, 1.8729, 0.5425, 0.0912, 0.0658, 0.1542].

**Benchmark aberto.** Cerca de 10 mil usuários do Anki e cerca de 727 milhões de revisões, sem revisões do mesmo dia [68]:

| Algoritmo | Parâmetros | Log loss (menor é melhor) | RMSE em faixas | AUC |
|---|---|---|---|---|
| FSRS-6 | 21 | 0,3460 | 0,0653 | 0,703 |
| FSRS-5 | 19 | 0,3561 | 0,0742 | 0,701 |
| FSRS-4.5 | 17 | 0,3625 | 0,0764 | 0,689 |
| HLR (Duolingo) | 3 | 0,4694 | 0,1275 | 0,637 |

**Pronto para Flutter.** O pacote **`fsrs` 2.0.1** no pub.dev (open-spaced-repetition/dart-fsrs, MIT, porte do py-fsrs) implementa o FSRS-6 [69]:
- classes `Scheduler`, `Card`, `ReviewLog` e `Rating` (again, hard, good, easy);
- configuração `desiredRetention` (padrão 0,9), `learningSteps` (padrão 1 min e 10 min), `relearningSteps` (padrão 10 min), `maximumInterval` (padrão 36.500) e `enableFuzzing`;
- `getCardRetrievability`;
- serialização `toMap` e `fromMap`, que serve para guardar no Firestore;
- **trabalha só em UTC**.
- Os parâmetros padrão do pacote diferem levemente da tabela da wiki. É o mesmo FSRS-6, com uma versão dos pesos.

**Retenção desejada.** O manual do Anki recomenda **0,90 como padrão**, faixa de 0,80–0,95, nunca acima de 0,97, porque **acima de 0,90 a carga cresce muito rápido** [44].

**Ressalva.** Os pesos padrão vêm de usuários de **flashcards no Anki**, não de frases digitadas. Ao juntar alguns milhares de revisões, vale **otimizar os parâmetros** com o otimizador do py-fsrs ou do fsrs-rs, rodado fora do app, e gravar os pesos por usuário ou para o curso.

### 3.5 Comparação para a decisão

| Critério | Leitner | SM-2 | FSRS-6 |
|---|---|---|---|
| Complexidade | mínima | baixa | média (pronto em Dart) |
| Usa a qualidade do acerto | não | sim (0–5) | sim (1–4) |
| Modela a probabilidade de lembrar | não | não | sim (R) |
| Lida com atraso | mal | mal (cresce linearmente) | bem (satura) |
| Precisão de previsão | baixa | baixa | a melhor entre os abertos [68] |
| **Recomendação** | alternativa | não | **padrão** |

---

## 4. Adaptar a repetição espaçada a frases digitadas: o que conta como acerto

### 4.1 Princípios

1. **Só digitação de memória gera nota.** Digitações de cópia (nível 0) e de correção servem para codificar, nunca para avaliar. A precisão na cópia não prevê memória: a cópia acerta 91% a 98% no treino e retém 29% a 40% [15].
2. **Precisão por palavra, e não por tecla.** Um erro de dedo ("teh") não é falha de memória. Avaliar por palavra com tolerância de 1 tecla errada separa erro motor de erro de memória.
3. **Dica tem custo.** Ajuda sob demanda (revelar a próxima letra) é o acúmulo de pistas dentro da tentativa [15][16], e cada letra revelada rebaixa a nota. Precisar de menos pistas é sinal de memória mais forte [18].
4. **Tempo é sinal secundário e relativo à própria pessoa.** O ARTS mostra que velocidade com precisão é informativa [63]. A velocidade absoluta, porém, depende do teclado, ABNT2 ou US-International. Comparar com a velocidade de cópia da própria pessoa naquela frase, ou com a mediana dela, desconta o fator motor.
5. **Errar com feedback é aceitável e até útil** [37][38][9]. A nota baixa reagenda o item. Não é punição.

### 4.2 Métricas por digitação de memória

| Métrica | Definição |
|---|---|
| `W` | nº de palavras da frase-alvo |
| `palavra_ok` | palavra digitada sem dica e com no máximo 1 tecla errada (0 tecla errada se a palavra tem até 3 letras) |
| `acc` | palavras_ok / W |
| `dicas` | letras reveladas, por Tab ou automaticamente |
| `desistiu` | apertou "não sei" (Esc) |
| `erros` | total de teclas erradas |
| `L` | latência: do aparecimento da tradução até a 1ª tecla |
| `v` | velocidade relativa = (caracteres/s nesta digitação) ÷ (caracteres/s de referência em cópia, mediana móvel das últimas 20 cópias da pessoa) |

### 4.3 Mapeamento para as notas do FSRS (proposta inicial, para calibrar com dados)

| Nota | Regra (avaliada de cima para baixo) |
|---|---|
| **1 (Again)** | `desistiu` OU `acc` < 0,80 OU `dicas` ≥ 30% das letras |
| **2 (Hard)** | `acc` < 1,0 OU `dicas` > 0 OU `v` < 0,35 OU `L` > 8 s |
| **4 (Easy)** | `acc` = 1,0 E `dicas` = 0 E `erros` = 0 E `v` ≥ 0,75 E `L` ≤ 2,5 s E a revisão anterior foi Good ou Easy |
| **3 (Good)** | todo o resto, ou seja, `acc` = 1,0 e `dicas` = 0 |

- **Contestar.** Um botão de "foi erro de digitação" converte Again → Hard ou Hard → Good no máximo 1 vez por sessão. Isso preserva a confiança no sistema sem virar porta para autoengano [35].
- **Normalização para não punir o que não é memória:**
  - maiúsculas e minúsculas ignoradas nos níveis de memória (o COLT ignorava maiúsculas e pontuação [62]);
  - pontuação (. , ! ? : ; e aspas) preenchida automaticamente pelo motor nos níveis 1–3;
  - **apóstrofos fazem parte da forma** (*don't*, *I'm*) e são obrigatórios, mas ' e ’ são equivalentes.
- **Atenção ao teclado US-International.** No Windows e no macOS ("U.S. International – PC"), o apóstrofo é tecla morta: **' + c vira ç** (*o'clock* → *oçlock*) e **' + vogal vira vogal acentuada**. O motor deve aceitar a sequência composta como equivalente ou orientar "apóstrofo + espaço". No ABNT2 o apóstrofo fica na tecla ao lado do 1 e não é tecla morta. *Verificar no motor atual.*
- **Formas alternativas.** "I am" e "I'm", "do not" e "don't", "going to" e "gonna" (este último não deveria ser aceito). Duas saídas:
  - **(a)** a tradução PT sinaliza a forma esperada, com uma etiqueta discreta como "(contraído)";
  - **(b)** a frase guarda `alternativas[]` e o motor compara o prefixo digitado com todas elas e troca o alvo na primeira divergência compatível.
  - O COLT aceitava qualquer tradução correta [62]. Recomendo (a) nos níveis iniciais e (b) a partir do intermediário.
- **Tradução não ambígua.** Como a pessoa precisa produzir *uma* forma exata, a tradução precisa apontar para ela. Quando o português admite várias versões inglesas, mostrar uma **nota de contexto** (por exemplo, "formal" ou "pergunta educada") ou o **número de palavras**.

---

## 5. Recomendação concreta da mecânica

> Respeita o pedido do dono: **tradução PT sempre em cima**, **sempre digitar a frase em inglês inteira**, **várias vezes**. As "melhorias" da pesquisa entram como **etapas da repetição**: o modelo vai sumindo, as repetições ficam intercaladas e voltam em dias diferentes. Nada é substituído por múltipla escolha.

### 5.1 Escada de apoio: o que aparece do inglês

| Nível | Nome | O que a pessoa vê do inglês (a tradução PT sempre em cima) | Exemplo para *I'd like a glass of water, please.* |
|---|---|---|---|
| **N0** | Modelo | frase inteira **esmaecida** (o motor atual) | I'd like a glass of water, please. (esmaecido) |
| **N1** | Iniciais | 1ª letra de cada palavra + sublinhados no lugar das demais; pontuação e apóstrofos visíveis | I'_ l___ a g____ o_ w____, p_____. |
| **N2** | Esqueleto | só os sublinhados (nº de letras por palavra), pontuação e apóstrofos | _'_ ____ _ _____ __ _____, ______. |
| **N3** | Escondido | nada do inglês; opcionalmente "(8 palavras)" | (8 palavras) |

**Ajuda dentro da tentativa (pistas que se acumulam) em N1–N3:**
- **Tab** revela a próxima letra. **Tab duas vezes seguidas** revela a palavra inteira.
- **Errar 2 vezes a mesma posição revela a letra automaticamente.** Evita o ciclo de chute letra a letra e conta como dica.
- **Esc ("não sei")** mostra a frase inteira (N0). A tentativa vale nota 1 e a pessoa **digita a frase uma vez copiando**, que é a correção.

**Feedback ao terminar qualquer digitação de memória:**
- mostrar a frase completa com as palavras erradas destacadas;
- tocar o áudio;
- manter a tela por pelo menos ~2–3 s antes de seguir (o COLT usava 3 s [62]);
- se houve erro, **digitar a frase corrigida uma vez em N0** (reestudo, que não conta como passada).

### 5.2 A lição de frases novas

**Tamanho.** **10 frases** é o padrão.
- 8 frases no nível inicial, com frases de 2–6 palavras.
- 12 frases no intermediário e avançado.
- **Um alvo novo por frase** (palavra, chunk ou estrutura), destacado na tradução e no inglês [53].
- Lições **temáticas**, sem pares quase idênticos na mesma lição [31][32].

**As 5 digitações de cada frase:**

| Digitação | Nível | Quando acontece (lag) | Áudio | Para que serve |
|---|---|---|---|---|
| **D1, Conhecer** | **N0** (modelo esmaecido) | quando a frase entra | **toca antes** (pode repetir) e de novo depois | mapear forma e significado, produção, fonologia. Cópia sem pressa [12] e uma única vez [10][13] |
| **D2, Iniciais** | **N1** | depois de **≥ 3** outras digitações | só **depois** | primeira recuperação, atrasada [24], com muito apoio [15][16] |
| **D3, Esqueleto** | **N2** | depois de **≥ 5** outras | só depois | recuperação com pouco apoio [18] |
| **D4, De memória** | **N3** | depois de **≥ 7** outras | só depois | recordação literal só com a tradução [7][13] |
| **D5, Prova da lição** | **N3** | **rodada final**, ordem embaralhada, lag ≥ 8 (de preferência ≥ 10) | só depois | 2ª recordação sem ajuda, que é o critério [41] |

**Regras de adaptação, que formam um fading dirigido pelo desempenho [17][18]:**
- **D2 com nota Good ou Easy e `v` ≥ 0,5** → pular D3 e ir direto a D4. Para itens fáceis, o fading pode ser mais rápido.
- **Nota 1 (Again) em D2–D5** → feedback, cópia em N0, e a próxima digitação desce **um nível**, com lag 3.
- **Nota 2 (Hard) em D4** → repete D4 antes da rodada final.
- **Critério para sair da lição:** **2 digitações N3 com Good ou Easy (D4 e D5)**. Se D5 falhar, a frase volta com lag ≥ 3 até 1 acerto sem ajuda. É o *dropout* de Rawson e Dunlosky e do COLT [41][62].
- **Modo "memorização forte"** (opção do usuário): critério de **3** acertos N3, com uma D6 em N3 na rodada final [41].
- **Teto:** no máximo **7 digitações** da mesma frase por dia, contando correções. Acima disso, a frase sai marcada como "difícil" e volta amanhã [40][44].

**Nunca repetir a frase em sequência.** A única exceção é a cópia de correção logo depois do feedback [24][22][23].

**Algoritmo de fila da lição (pseudocódigo):**

```
lags = {D1→D2: 3, D2→D3: 5, D3→D4: 7}; LAG_MIN_FINAL = 8
a cada passo:
  1. se há frase com "vence_em" ≤ passo_atual → pegar a que venceu há mais tempo
  2. senão, se ainda há frase nova → introduzir (D1)
  3. senão, se há frase pronta para D5 (concluiu D4 há ≥ LAG_MIN_FINAL passos) → sortear uma
  4. senão, se há revisão antiga vencida hoje → usar como "recheio" (aumenta o lag de graça)
  5. senão → pegar a pendente mais próxima, respeitando lag ≥ 2
  ao terminar a digitação: calcular nota → reagendar (vence_em = passo + lag do próximo nível)
```

Uma simulação de 10 frases (A a J) gera 50 digitações nesta ordem:

`A1 B1 C1 D1 A2 B2 C2 D2 E1 F1 A3 B3 C3 E2 D3 F2 G1 H1 A4 B4 E3 C4 G2 F3 H2 D4 I1 J1 E4 G3 H3 I2 F4 J2 C5 A5 D5 G4 I3 H4 J3 F5 B5 E5 I4 J4 G5 H5 I5 J5`

- Lags medianos: D2 = 4, D3 = 6, D4 = 7, D5 = 10.
- As últimas frases ficam com lags menores. É por isso que o passo 4 usa revisões antigas do dia como recheio: o "fim" da fila ganha espaçamento extra e as lições antigas se intercalam com a nova [30].

**Tempo estimado.** Uma frase de cerca de 8 palavras tem cerca de 40 caracteres. Para quem digita cópia em inglês a 50–70 ppm, isso leva cerca de 8–10 s em N0 e cerca de 15–20 s em N3, mais 3–5 s de feedback. Com 10 frases, são cerca de **50–55 digitações ≈ 12–18 min**. Isso coincide com a escala de tempo de sessões que funcionaram em sala (20–30 min no COLT [62]). *A estimativa é minha.*

### 5.3 O áudio, passo a passo

1. **D1:** toca **antes** de digitar. Botão para repetir e opção de velocidade 0,8× nos níveis iniciais. Toca de novo **depois**.
2. **D2–D5 e revisões:** toca **só depois** de terminar, como feedback. Tocar antes tornaria a tarefa uma transcrição e reduziria o esforço de recuperação [52][18].
3. **Vozes:** alternar 2 ou 3 vozes TTS naturais (EUA e Reino Unido, masculina e feminina) entre D1, a rodada final e as revisões [50]. Fixar uma voz nas duas primeiras semanas de um iniciante absoluto pode reduzir a confusão. *Isto é opinião, não evidência.*
4. **"Fale enquanto digita" (opcional, sem microfone):** um lembrete visual em D1 e D4 para dizer a frase em voz alta. A fala é a produção mais forte [2][1].
5. **Ditado como tipo extra de revisão:** desbloqueado quando a frase atinge **S ≥ 14 dias** no FSRS.
   - O áudio toca, o inglês fica escondido (N3) e a tradução continua em cima (preferência do dono, que pode ser desligada).
   - Treina escuta e varia as condições de recuperação [33].
   - Deve ficar com no máximo ~1/3 das revisões de cada frase, sem substituir a revisão normal.
   - Como ditado imediato tende a ser raso [52], **o áudio toca uma vez e só depois a pessoa começa a digitar**, de memória do que ouviu.

### 5.4 Revisão nos dias seguintes

**Agendador:** FSRS-6 pelo pacote Dart `fsrs` [69], um `Card` por frase.

| Parâmetro | Valor recomendado | Justificativa |
|---|---|---|
| `desiredRetention` | **0,90** (modo "leve": 0,85) | padrão recomendado; acima de 0,90 a carga explode [44] |
| `learningSteps` | **[]** (vazio) | o motor da lição já faz as repetições do mesmo dia |
| `relearningSteps` | **[]** (vazio) | a reaprendizagem acontece na própria sessão (ver abaixo) |
| `maximumInterval` | **365** dias no 1º ano (depois 730) | evita sumiços de mais de um ano numa fase de aquisição; manutenção espaçada como em Bahrick [27] |
| `enableFuzzing` | **true** | espalha a carga entre dias |
| parâmetros `w` | padrão do pacote → **otimizar** após cerca de 2–5 mil revisões do usuário | os padrões vêm de flashcards do Anki [68] |
| **1ª revisão** | **forçar para o dia seguinte** (limitar o 1º intervalo a 1 dia) | sono entre as sessões [61]; recordação alta no treino com expansão [25] |

**Ao concluir a lição:** registrar **um** review no FSRS com a nota da D5. Para quem cumpriu o critério, normalmente é Good (S0 ≈ 2,3 dias, limitado a 1 dia na primeira vez).

**Uma revisão:**
1. Mostrar a tradução e o inglês em **N3**, com ajuda sob demanda (Tab).
2. Começar escondido mesmo com o risco de errar é bom: tentativa seguida de feedback [37][38].
3. Digitar uma vez → calcular a nota (4.3) → `scheduler.reviewCard(card, rating)`.
4. **Nota 1 (Again):** feedback, áudio e cópia em N0. A frase volta **na mesma sessão** em N2 (lag ≥ 5) e depois em N3, até 1 acerto sem ajuda. Isso é o *successive relearning* [41][43]. Só a primeira tentativa do dia vai para o FSRS.
5. **Nota 2 (Hard):** sem repetir na sessão. O FSRS já encurta o intervalo.

**Sessão diária, em ordem:**
1. **Revisões vencidas**, intercaladas entre lições, ordenadas por menor `getCardRetrievability`. São o aquecimento.
2. **Lição nova**, usando revisões restantes como recheio.
3. **Rodada final** da lição.

**Limites:**
- **Frases novas por dia:** padrão **10** (uma lição); "leve" 5; "intensivo" 15.
- **Teto de revisões por dia:** 150, priorizando por menor R.
- **Freio automático:** se houver mais de ~2 dias de revisões atrasadas, **pausar lições novas** até zerar. É a regra do Anki de "revisões antes de novos".

**Frases "sanguessuga" (leeches):** depois de **6 lapsos**, a frase sai da rotação e vai para "frases-problema". Lá recebe uma mini-lição D1–D4 de novo e, se for longa, é **quebrada em chunks**, com cada chunk como item próprio por um tempo. Também é sinal para a curadoria revisar a tradução, que pode estar ambígua.

**Carga prevista.** Simulei com o FSRS-6 padrão, revisões sempre Good ou Again segundo R, 1ª revisão no dia seguinte e teto de 365 dias. *É modelo, não medição.*

| Novas/dia | Retenção | Revisões/dia (dias 1–30) | (31–90) | (91–180) |
|---|---|---|---|---|
| 5 | 0,90 | ~10 | ~21 | ~27 |
| **10** | **0,90** | **~22** | **~41** | **~55** |
| 15 | 0,90 | ~33 | ~63 | ~82 |
| 10 | 0,85 | ~19 | ~32 | ~48 |

- A ~15–20 s por revisão, 10 novas por dia dá cerca de **10–18 min de revisão** mais **12–18 min de lição** por dia, ou **~25–35 min/dia** no regime estável.
- Frases são mais difíceis que palavras, então espere mais lapsos que no modelo. Calibrar com telemetria.

**Alternativa sem FSRS (Leitner com 7 caixas, intervalos que se expandem):**
- **Caixas e intervalos:** 1 → **1 d**, 2 → **3 d**, 3 → **7 d**, 4 → **16 d**, 5 → **35 d**, 6 → **80 d**, 7 → **180 d**.
- **Regras:** Good sobe uma caixa. Easy sobe duas. Hard fica na caixa e repete o intervalo. Again **desce duas caixas** (mínimo 1), com reaprendizagem na sessão.
- A sequência de 1, 3 e 7 dias lembra o esquema expandido de Kang (dias 1 → 3 → 9 → 28 [25]). Intervalos de 1–6 meses na manutenção seguem a crista de Cepeda (cerca de 5–10% do intervalo de retenção para metas de 1 ano [20]) e os 56 dias de Bahrick [27].

### 5.5 Nivelamento e como pular etapas (o nível dele é desconhecido)

Cada unidade tem uma **prova de entrada opcional**: 10 frases representativas, digitadas em **N3** com a tradução em cima. É um pré-teste, então errar aqui também ajuda depois [38][37].
- **≥ 8 de 10 Good ou Easy** → unidade **"testada"**. As frases **não passam pela lição**: entram direto no FSRS como **Easy** (S0 ≈ 8 dias), e a primeira revisão confirma ou derruba. **Nada é descartado sem prova** [35].
- **5–7 de 10** → lição em **modo rápido**. Começa em N2: D1 vira N2 com o modelo mostrado só depois. São 3 digitações, D2 = N3 e D3 = N3 na rodada final.
- **< 5** → lição completa, com as 5 digitações.
- Na própria lição, um botão de "já conheço esta frase" na D1 troca a cópia por uma tentativa em N3 na hora. Se der Good ou Easy, a frase só precisa da D5.

### 5.6 Modo "treino extra" (para quem quer digitar mais)

O dono quer "escrever várias vezes". Em vez de repetir em bloco as frases de hoje, que é o pior uso do tempo [24][40], o treino extra puxa as frases com **menor R** no FSRS ou as que **erraram nos últimos 3 dias**, sempre em N3 e intercaladas. A repetição continua, só que no lugar onde rende.

### 5.7 Telemetria para calibrar

- **Acerto em N3 na lição** (D4, D5). Alvo: **80–90%**.
  - Acima de 95% de forma consistente → acelerar o fading ou oferecer mais frases novas.
  - Abaixo de 70% → frases mais curtas, menos frases novas ou fading mais lento [36][8][17].
- **Retenção na 1ª revisão (dia seguinte).** Alvo: **≥ 80%**.
- **Retenção real nas revisões contra `desiredRetention`.** Se a real ficar bem abaixo, os parâmetros FSRS padrão não servem → otimizar.
- **Dicas por frase**, lapsos por frase e tempo por digitação. Servem para achar **frases mal traduzidas ou longas demais**.
- **Tempo/dia e abandono.** Se a sessão passar de ~40 min, reduzir as novas/dia.

### 5.8 O que não fazer (antipadrões com evidência)

| Antipadrão | Por quê |
|---|---|
| Digitar a mesma frase 5× seguidas | em bloco: 20% em 2 dias contra 45% com lag de 5 [24]; g ≈ 0,74 [22]; e a ilusão de eficácia [23] |
| Várias cópias com o modelo visível | cópia: 29–40% contra 40–58% com fading [15]; perde para a recuperação e até para o controle no teste atrasado [13][10] |
| Tocar o áudio antes de uma tentativa de memória | vira transcrição; ganho de ditado imediato some em 2 semanas [52] |
| Botão "já sei" que descarta sem prova | descartar cartões piora o aprendizado [35] |
| Errar sem ver a resposta | sem feedback, −494% [9]; sem testing effect com acerto ≤ 50% [8] |
| Muitas repetições no mesmo dia | overlearning some em 4 semanas [40]; repetir no mesmo dia rende pouco no longo prazo [44] |
| Lição com pares quase sinônimos | interferência e erros trocados [31][32] |
| Nota pela precisão na cópia | não mede memória [15] |
| Tradução ambígua | a pessoa "erra" por adivinhar outra forma válida; mede adivinhação, não memória |

---

## 6. Lacunas e incertezas

1. **Nenhum estudo encontrado testa exatamente a nossa tarefa:** frases inteiras de L2 digitadas com tradução visível e pistas que somem por nível. A mecânica combina evidências de pares de palavras [7][15][24][39][41] com o caso mais próximo, o COLT [62]. Os números de lag e de digitações são **extrapolações razoáveis, não ótimos medidos**.
2. **Frases são mais longas que palavras.** A recordação literal de 8 a 12 palavras sobrecarrega a memória de trabalho mais que uma palavra de 5 letras. Os níveis N1 e N2 e a quebra em chunks mitigam isso, mas os limites (por exemplo, até quantas palavras ainda dá para fazer o N3 no dia 1) precisam vir da telemetria.
3. **O production effect com digitação é relativo** (g ≈ 0,37 entre listas [3]). Não dá para contar com ele como motor principal.
4. **A regra dos 85% [36] é teórica**, vinda de algoritmos de aprendizagem. Serve como alvo inicial, não como lei.
5. **Os parâmetros FSRS padrão** vêm de flashcards do Anki, e frases digitadas podem ter outra curva. Por isso o plano de otimizar com dados próprios.
6. **Ditado** tem pouca evidência de longo prazo como ferramenta de memorização [52]. Fica como modo extra.
7. **O tempo como sinal** depende do teclado e do sistema operacional (ABNT2 contra US-International, Mac contra Windows). A normalização pela velocidade de cópia da própria pessoa é proposta minha.
8. **Alguns números vêm de resumos e não do texto integral:** Nakata 2015 [26], Tinkham e Waring via revisão [32] e Rowland e Adesope via o artigo da Frontiers [8]. O restante foi conferido nos resumos oficiais (PubMed, Crossref) ou no PDF.

---

## 7. Fontes

1. MacLeod, C. M. & Bodner, G. E. (2017). The production effect in memory. *Current Directions in Psychological Science*. https://uwaterloo.ca/memory-attention-cognition-lab/sites/default/files/uploads/files/macleodbodner_cdps17_0.pdf · https://journals.sagepub.com/doi/10.1177/0963721417691356
2. Forrin, N. D., MacLeod, C. M. & Ozubko, J. D. (2012). Widening the boundaries of the production effect. *Memory & Cognition*. https://pubmed.ncbi.nlm.nih.gov/22528825/
3. Fawcett, J. M. (2013). The production effect benefits performance in between-subject designs: a meta-analysis. *Acta Psychologica*. https://pubmed.ncbi.nlm.nih.gov/23142670/
4. Jamieson, R. K. & Spear, J. (2014). The offline production effect. *Canadian Journal of Experimental Psychology*. https://pubmed.ncbi.nlm.nih.gov/24364810/
5. Ozubko, J. D., Hourihan, K. L. & MacLeod, C. M. (2012). Production benefits learning: the production effect endures and improves memory for text. *Memory*. https://pubmed.ncbi.nlm.nih.gov/22827717/
6. Bertsch, S. et al. (2007). The generation effect: a meta-analytic review. *Memory & Cognition*. https://pubmed.ncbi.nlm.nih.gov/17645161/
7. Karpicke, J. D. & Roediger, H. L. (2008). The critical importance of retrieval for learning. *Science* 319, 966. https://www.brucehayes.org/Teaching/papers/2008_Roediger_Karpicke_Science.pdf · https://pubmed.ncbi.nlm.nih.gov/18276894/
8. Artigo da Frontiers in Psychology (2018) que resume Rowland (2014) e Adesope et al. (2017), com os moderadores feedback e taxa de acerto. https://frontiersin.org/articles/10.3389/fpsyg.2018.02412/full
9. Pashler, H., Cepeda, N. J., Wixted, J. T. & Rohrer, D. (2005). When does feedback facilitate learning of words? *JEP:LMC*. https://pubmed.ncbi.nlm.nih.gov/15641900/
10. Barcroft, J. (2006). Can writing a new word detract from learning it? *Second Language Research* 22(4). https://doi.org/10.1191/0267658306sr276oa
11. Barcroft, J. (2007). Effects of word and fragment writing during L2 vocabulary learning. *Foreign Language Annals*. https://doi.org/10.1111/j.1944-9720.2007.tb02889.x
12. Re-examining the effects of word writing on vocabulary learning (2018). *ITL – International Journal of Applied Linguistics*. https://doi.org/10.1075/itl.00007.web
13. Candry, S., Decloedt, J. & Eyckmans, J. (2020). Comparing the merits of word writing and retrieval practice for L2 vocabulary learning. *System*. https://doi.org/10.1016/j.system.2020.102206
14. Candry, S. et al. (2017). Word writing vs. meaning inferencing in contextualized L2 vocabulary learning. *Canadian Modern Language Review*. https://doi.org/10.3138/cmlr.3688
15. Finley, J. R., Benjamin, A. S., Hays, M. J., Bjork, R. A. & Kornell, N. (2011). Benefits of accumulating versus diminishing cues in recall. *Journal of Memory and Language* 64, 289–298. https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/07/Finley_Benjamin_Hays_RBjork_Kornell_2011.pdf
16. Glisky, E. L., Schacter, D. L. & Tulving, E. (1986). Learning and retention of computer-related vocabulary in memory-impaired patients: method of vanishing cues. https://pubmed.ncbi.nlm.nih.gov/3755140/
17. Guidelines for the selection of a method of fading cues (2000). *Neuropsychological Rehabilitation* (Universidade de Birmingham). https://doi.org/10.1080/096020100389219 · https://research.birmingham.ac.uk/en/publications/guidelines-for-the-selection-of-a-method-of-fading-cues/
18. Carpenter, S. K. & DeLosh, E. L. (2006). Impoverished cue support enhances subsequent retention. *Memory & Cognition*. https://pubmed.ncbi.nlm.nih.gov/16752591/
19. Cepeda, N. J. et al. (2006). Distributed practice in verbal recall tasks: a review and quantitative synthesis. *Psychological Bulletin*. https://pubmed.ncbi.nlm.nih.gov/16719566/
20. Cepeda, N. J. et al. (2008). Spacing effects in learning: a temporal ridgeline of optimal retention. *Psychological Science*. https://pubmed.ncbi.nlm.nih.gov/19076480/
21. Kim, S. K. & Webb, S. (2022). The effects of spaced practice on second language learning: a meta-analysis. *Language Learning*. https://doi.org/10.1111/lang.12479
22. Latimier, A., Peyre, H. & Ramus, F. (2021). A meta-analytic review of the benefit of spacing out retrieval practice episodes on retention. *Educational Psychology Review*. https://doi.org/10.1007/s10648-020-09572-8 · preprint: https://osf.io/kzy7u
23. Kornell, N. (2009). Optimising learning using flashcards: spacing is more effective than cramming. *Applied Cognitive Psychology*. https://doi.org/10.1002/acp.1537
24. Karpicke, J. D. & Roediger, H. L. (2007). Expanding retrieval practice promotes short-term retention, but equally spaced retrieval enhances long-term retention. *JEP:LMC* 33(4). https://www.gwern.net/doc/psychology/spaced-repetition/2007-karpicke.pdf
25. Kang, S. H. K., Lindsey, R. V., Mozer, M. C. & Pashler, H. (2014). Retrieval practice over the long term: should spacing be expanding or equal-interval? *Psychonomic Bulletin & Review*. https://doi.org/10.3758/s13423-014-0636-z · https://home.cs.colorado.edu/~mozer/Research/Selected%20Publications/reprints/KangLindseyMozerPashler2014.pdf
26. Nakata, T. (2015). Effects of expanding and equal spacing on second language vocabulary learning. *SSLA* 37(4), 677–711 (resumo secundário). https://sanad.iau.ir/en/Article/897069
27. Bahrick, H. P. et al. (1993). Maintenance of foreign language vocabulary and the spacing effect. *Psychological Science*. https://gwern.net/doc/psychology/spaced-repetition/1993-bahrick.pdf
28. Nakata, T. & Webb, S. (2016). Does studying vocabulary in smaller sets increase learning? *SSLA*. https://doi.org/10.1017/s0272263115000236
29. Brunmair, M. & Richter, T. (2019). Similarity matters: a meta-analysis of interleaved learning and its moderators. *Psychological Bulletin*. https://pubmed.ncbi.nlm.nih.gov/31556629/
30. Nakata, T. & Suzuki, Y. (2019). Mixing grammar exercises facilitates long-term retention. *Modern Language Journal*. https://doi.org/10.1111/modl.12581
31. Nakata, T. & Suzuki, Y. (2019). Effects of massing and spacing on the learning of semantically related and unrelated words. *SSLA*. https://doi.org/10.1017/s0272263118000219
32. Revisão sobre agrupamento semântico e temático (Tinkham, 1993; Waring, 1997; Erten & Tekin, 2008). https://www.aijcrnet.com/journals/Vol_2_No_2_February_2012/26.pdf
33. Bjork, E. L. & Bjork, R. A. (2011). Making things hard on yourself, but in a good way: creating desirable difficulties. https://bjorklab.psych.ucla.edu/wp-content/uploads/sites/13/2016/04/EBjork_RBjork_2011.pdf
34. Pyc, M. A. & Rawson, K. A. (2009). Testing the retrieval effort hypothesis. *Journal of Memory and Language*. https://doi.org/10.1016/j.jml.2009.01.004 · resumo: https://notes.andymatuschak.org/z5zckzyAM1DwEQqt94qMpsd
35. Kornell, N. & Bjork, R. A. (2008). Optimising self-regulated study: the benefits, and costs, of dropping flashcards. *Memory*. https://pubmed.ncbi.nlm.nih.gov/18286417/
36. Wilson, R. C., Shenhav, A., Straccia, M. & Cohen, J. D. (2019). The Eighty Five Percent Rule for optimal learning. *Nature Communications*. https://pubmed.ncbi.nlm.nih.gov/31690723/
37. Kornell, N., Hays, M. J. & Bjork, R. A. (2009). Unsuccessful retrieval attempts enhance subsequent learning. *JEP:LMC*. https://pubmed.ncbi.nlm.nih.gov/19586265/
38. Potts, R., Davies, G. & Shanks, D. R. (2019). The benefit of generating errors during learning: what is the locus of the effect? *JEP:LMC*. https://pubmed.ncbi.nlm.nih.gov/30024254/
39. Nakata, T. (2017). Does repeated practice make perfect? The effects of within-session repeated retrieval on second language vocabulary learning. *SSLA*. https://doi.org/10.1017/s0272263116000280
40. Rohrer, D., Taylor, K., Pashler, H., Wixted, J. T. & Cepeda, N. J. (2005). The effect of overlearning on long-term retention (com síntese de Rohrer & Pashler). https://escholarship.org/uc/item/6061k9j5
41. Rawson, K. A. & Dunlosky, J. (2011). Optimizing schedules of retrieval practice for durable and efficient learning: how much is enough? *JEP:General*. https://pubmed.ncbi.nlm.nih.gov/21707204/
42. Vaughn, K. E. & Rawson, K. A. (2011). Diagnosing criterion-level effects on memory. *Psychological Science*. https://pubmed.ncbi.nlm.nih.gov/21813798/
43. Dunlosky, J., Greve, A., Badali, S., Wissman, K. & Rawson, K. A. Successive relearning (guia aplicado). https://www.unh.edu/teaching-learning-resource-hub/sites/default/files/media/2023-06/itow-successive-relearning-dunlosky-greve-badali-wissman-rawson.pdf
44. Manual do Anki, Deck Options (FSRS, retenção desejada, etapas de aprendizagem). https://docs.ankiweb.net/deck-options.html
45. Mangen, A. et al. (2015). Handwriting versus keyboard writing: effect on word recall. *Journal of Writing Research* 7(2). https://www.jowr.org/index.php/jowr/article/view/662
46. Wiley, R. W. & Rapp, B. (2021). The effects of handwriting experience on literacy learning. *Psychological Science*. https://pubmed.ncbi.nlm.nih.gov/34184564/
47. Ouellette, G. & Tims, T. (2014). The write way to spell: printing vs. typing effects on orthographic learning. *Frontiers in Psychology*. https://pmc.ncbi.nlm.nih.gov/articles/PMC3923165/
48. Typing vs handwriting to acquire irregular English verbs by young Spanish speakers (UTA, 2023). https://repositorio.uta.edu.ec/handle/123456789/38123
49. Baddeley, A., Gathercole, S. & Papagno, C. (1998). The phonological loop as a language learning device. *Psychological Review*. https://pubmed.ncbi.nlm.nih.gov/9450375/
50. Barcroft, J. & Sommers, M. S. (2005). Effects of acoustic variability on second language vocabulary learning. *SSLA* 27, 387–414. https://www.cambridge.org/core/product/E421D628FF972119B2803579FCF9B585
51. Brown, R., Waring, R. & Donkaewbua, S. (2008). Incidental vocabulary acquisition from reading, reading-while-listening, and listening to stories. *Reading in a Foreign Language*. https://doi.org/10.64152/10125/66816
52. Learning multiword items through dictation and dictogloss: how task performance predicts learning outcomes (2022). *Language Teaching Research*. https://doi.org/10.1177/13621688221117242
53. Laufer & Shmueli (1997), discutido em: https://teslcanadajournal.ca/index.php/tesl/article/download/1073/892/1171
54. Webb, S. (2007). The effects of repetition on vocabulary knowledge. *Applied Linguistics*. https://doi.org/10.1093/applin/aml048
55. Uchihara, T., Webb, S. & Yanagisawa, A. (2019). The effects of repetition on incidental vocabulary learning: a meta-analysis of correlational studies. *Language Learning*. https://doi.org/10.1111/lang.12343
56. Boers, F. et al. (2006). Formulaic sequences and perceived oral proficiency: putting a Lexical Approach to the test. *Language Teaching Research*. https://doi.org/10.1191/1362168806lr195oa
57. Durrant, P. & Schmitt, N. (2010). Adult learners' retention of collocations from exposure. *Second Language Research*. https://repository.bilkent.edu.tr/items/d9deeca9-3faa-4d4a-8da2-a0c79cab1ef4
58. Text memorization: an effective strategy to improve Chinese EFL learners' argumentative writing proficiency (2023, *Frontiers in Psychology*; revisa Ding 2007 e Dai & Ding 2010). https://pmc.ncbi.nlm.nih.gov/articles/PMC10112396/
59. Sachs, J. S. (1967). Recognition memory for syntactic and semantic aspects of connected discourse. *Perception & Psychophysics*. https://link.springer.com/article/10.3758/BF03208784
60. Elgort, I. (2011). Deliberate learning and vocabulary acquisition in a second language. *Language Learning*. https://doi.org/10.1111/j.1467-9922.2010.00613.x
61. Mazza, S. et al. (2016). Relearn faster and retain longer. *Psychological Science*. https://pubmed.ncbi.nlm.nih.gov/27530500/
62. Lindsey, R. V., Shroyer, J. D., Pashler, H. & Mozer, M. C. (2014). Improving students' long-term knowledge retention through personalized review. *Psychological Science* (com material suplementar do COLT). https://home.cs.colorado.edu/~mozer/Research/Selected%20Publications/reprints/LindseyShroyerPashlerMozer2014.pdf
63. Mettler, E., Massey, C. M., El-Ashmawy, A. K. & Kellman, P. J. (2020). Adaptive vs. fixed spacing of learning items (ARTS). *CogSci*. https://pubmed.ncbi.nlm.nih.gov/34337610/
64. SuperMemo, algoritmo SM-2 (descrição original). https://www-v1.supermemo.com/archives1990-2015/english/ol/sm2
65. Leitner system. https://en.wikipedia.org/wiki/Leitner_system
66. Settles, B. & Meeder, B. (2016). A trainable spaced repetition model for language learning. *ACL*. https://aclanthology.org/P16-1174/
67. FSRS, The Algorithm (wiki oficial; fórmulas do FSRS-4.5, 5 e 6). https://github.com/open-spaced-repetition/awesome-fsrs/wiki/The-Algorithm
68. SRS Benchmark (open-spaced-repetition). https://github.com/open-spaced-repetition/srs-benchmark
69. Pacote Dart `fsrs` 2.0.1 (pub.dev) e repositório dart-fsrs. https://pub.dev/packages/fsrs · https://github.com/open-spaced-repetition/dart-fsrs
70. Pimsleur Language Programs (intervalos de recordação graduada). https://en.wikipedia.org/wiki/Pimsleur_Language_Programs
71. Zheng, G., Nakata, T., Clenton, J. & Boutorwick, T. J. (2026). Effects of spacing on the acquisition of explicit and implicit vocabulary knowledge. *SSLLT*. https://pressto.amu.edu.pl/index.php/ssllt/article/view/49487 · Nakata & Elgort (2020): https://doi.org/10.1177/0267658320927764
72. Does spaced practice have the same effects on different L2 vocabulary learning activities? Fill-in-the-blanks versus flashcards (2023). *Modern Language Journal*. https://doi.org/10.1111/modl.12879
73. Shahar-Yames, D. & Share, D. L. (2008). Spelling as a self-teaching mechanism in orthographic learning. *Journal of Research in Reading*. https://cris.haifa.ac.il/en/publications/spelling-as-a-self-teaching-mechanism-in-orthographic-learning/
74. Pichette, F., De Serres, L. & Lafontaine, M. (2012). Sentence reading and writing for second language vocabulary acquisition. *Applied Linguistics* 33(1). https://r-libre.teluq.ca/406/1/Pichette_AppliedLinguistics_2011.pdf
75. Cover-copy-compare (módulo didático; cita a metanálise de Joseph et al., 2012). https://winthrop.edu/uploadedFiles/ceshs/edco/module/202-610-cover-copy-compare.pdf
