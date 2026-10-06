# Revisão final do curso de inglês: o que mudou

05/out/2026. Revisão das 83 críticas das três lentes (progressão, aprendiz e mecânica) sobre `DESIGN.md`, `plano_trilhas.json` e `licoes_*.json` (versão 1.0, guardada sem alterações em `_antes_revisao/`).

## Resultado

| | Antes (v1.0) | Depois (v1.1) |
|---|---|---|
| Fonte do curso | plano e lições separados e divergentes (559 x 566 lições) | **`esboco.json`, fonte única**; `plano_trilhas.json` e `licoes_*.json` agora são visões geradas dele |
| Trilhas / lições / frases | 117 / 559 no plano (566 escritas) / 4.872 no plano (4.936 escritas) | **120 / 595 / 5.206** |
| Itens novos por lição (fora do fechamento) | 10 a 12 em média, até 20 | **no máximo 4 (lição de 8 frases) ou 5 (de 10)**; média 3,8 a 4,8; 2.070 no total |
| Lições do A2 em diante sem reciclagem | 374 de 447 | **0 de 466** (todas com 3 a 5 itens, cota eterna e retomadas de BR) |
| Interferências BR com menos de 3 retomadas | várias (BR09, BR20, BR21, BR59...) | **0**; 63 pontos (3 novos: BR61, BR62, BR63), tabela em `interferenciasBR` |
| Exemplos com mais de 18 palavras | 31 | **0** |
| Exemplos com mais de 14 palavras | 194 | **27** (todos com 15 palavras, marcados: D4 e prova em N2) |
| Média de palavras por exemplo na etapa dev / no C1 | 16,3 / 12,8 | **11,7 / 11,8** |
| Formas britânicas como alvo, duas falas no mesmo `cod`, parênteses no `cod` | 21 / 10 / 3 | **0 / 0 / 0** |
| Validador | — | `_revisao/valida.js`: **0 erros**, 29 avisos (27 frases de 15 palavras, 1 lição com 1 item novo, 1 frase de e-mail formal com *whom*) |

**Como foi feito.** Nada foi editado à mão nos JSON: `_revisao/build.js` carrega os originais, aplica os patches por etapa (`p_a1.js` … `p_dev.js`, `p_longas.js`, `p_global.js`), aplica as regras globais (`regras.js`: tipos de trilha, fechamento, teto de itens novos, códigos BR, retomadas, reciclagem por distância e ids estáveis), acrescenta os extras (`extras.js`: ficha do aluno, glossário, portões, regra do "testar para pular"), valida (`valida.js`) e grava o esboço. `node _revisao/build.js --derivados` regenera também as visões derivadas. A simulação do escalonador em ondas está em `_revisao/sim_ondas.js`.

Legenda: **Aceito** (corrigido como pedido), **Aceito em parte** (corrigido, com uma parte da sugestão trocada por outra solução ou recusada, e o motivo), **Rejeitado** (com o motivo). Nenhum problema foi rejeitado por inteiro: todos apontavam um defeito real; onde a sugestão estava errada em algum detalhe, isso vai explicado.

---

## Lente: progressão (25)

**1. `recicla` vazio do A2 em diante; BR sem retomada; "70% já visto" sem lastro (alta). Aceito.**
Toda lição tem agora `recicla` com 3 a 5 itens: um item de cada trilha a 1, 3, 8 e 20 trilhas para trás (tirado dos itens novos daquela trilha), mais a cota eterna em rodízio (-s da 3ª pessoa, artigos, *do*, present perfect x passado, preposições, *it*; o present perfect só entra na cota depois da trilha present-perfect-experiencias) e, quando cabe, a retomada de um BR no lugar do item de distância 3. No A1, as listas feitas à mão foram mantidas, sem os itens que ainda não tinham sido vistos, e completadas quando ficaram com menos de 3. Criada a tabela BR → trilha que introduz → trilhas de retomada (`interferenciasBR`), com no mínimo 3 retomadas por BR, cada uma rotulada numa lição (`br`, `interferencias` e `recicla`). As retomadas pedidas foram atendidas nas trilhas equivalentes da numeração nova (BR20 em situacao-viagem, relativas-definidoras e opinar-conduzir-conversa; BR21 em falsos-cognatos-ortografia, regencia-preposicoes e argumentar-conectores; BR59 em opinar-conduzir-conversa, funcoes-conversa-b2 e conversa-natural-c1; BR09 em comparar, superlativos e resenhar-criticar; BR14 em relativas-definidoras e regencia-preposicoes; BR16 em situacao-viagem e fazer-ficar-perder-ganhar; as demais pela regra de distância crescente). O D06 do DESIGN passou a ser verificação por lição.

**2. Vocabulário de 10 a 20 itens por lição, matematicamente impossível (alta). Aceito.**
Separado em `vocabulario` (itens novos, no máximo nFrases ÷ 2, priorizando os que aparecem nos exemplos e no foco), `apoio` (itens já vistos) e `cena` (palavras incidentais, no máximo 1 desconhecida por frase, até 2 no A1 e 4 nas demais). O excedente vai para a lição seguinte da trilha quando ela tem vaga e o item tem a ver com ela (aparece no foco ou nos exemplos); senão, para `vocabulario.reserva` da trilha. T2 L2 virou três lições (13–19; 20–99 com hífen; cem, mil e preços), com o contraste *thirteen/thirty* só no fechamento. T13 L2 (dias) e T13 L4 (meses) viraram duas lições cada. T52 L1 e casos parecidos: itens já vistos (*on vacation, crowded, amazing*) agora caem em `apoio`. O D04 virou bloqueante: novos × 2 ≤ nFrases.

**3. B1, B2 e C1 sem trilha de revisão por 13 a 19 trilhas (alta). Aceito.**
Quatro trilhas novas de situação e revisão, com checklist de BR: `situacao-aluguel-contas` (B1, depois da terceira-condicional; revisa 52–63), `situacao-carro-estrada` (B2, depois de wish-condicionais-mistas; revisa 74–78), `situacao-telefone-reclamacao` (B2, depois de phrasal-verbs-b2; revisa 80–87) e `situacao-vida-social` (C1, depois de conceder-rebater). Com as trilhas dev-\*, que também não têm gramática nova, há uma trilha de consolidação a cada 4 a 8 trilhas em todas as etapas (DESIGN 4.1). Para o B2 escolhi carro e estrada em vez de "viagem a trabalho", porque o A1, o A2 e o B1 já têm viagem a trabalho e a lente do aprendiz pediu carro e estrada.

**4. Portões e "testar para pular" sem banco nem diagnóstico (alta). Aceito em parte.**
Criados os 5 portões (A2, B1, B2, C1, dev) em `esboco.json` → `portoes`, com 8 frases cada, e cada frase com `alvo`, `ponto` gramatical e `se_errar` (as trilhas que ela testa), mais a regra de diagnóstico (errou o ponto → a trilha abre em "testar para pular" em vez de ficar marcada como testada). **Recusado:** um banco separado de 10 frases por trilha (cerca de 1.200 frases a mais para escrever e manter). O "testar para pular" usa a primeira frase com alvo de cada lição da própria trilha (o autor pode marcar outra com `teste: true`), o que testa exatamente o que a trilha ensina e não duplica conteúdo. Ficaram 8 frases por portão, e não 15, pela crítica 56.

**5. Falta *want / need / would like sb to* (alta). Aceito.**
Novo ponto **BR61**. Nova lição em verbo-to-ing (A2, trilha 39): "Quero que você revise" (*I'd like you to review my PR today. / I need you to call the client. / Do you want me to send the file? / My boss wants me to finish it by Friday.*). Retomadas: discurso-indireto (*Sarah asked me to send the slides.*), verbos-de-relato (*Mike expects us to finish by Friday. / Our security policy doesn't allow us to share the logs.*) e pro-lideranca-feedback (*I'd like you to lead the next retro.*). Regex do BR61 no G02. O glossário fixa "Quer que eu...?" = *Do you want me to...?* a partir dessa trilha.

**6. Pares confundíveis na mesma lição (alta). Aceito.**
fazer-ficar-perder-ganhar reescrita com um verbo por lição: make; do; get + adjetivo; lose; earn; win e waste (não são par entre si); fechamento com os pares juntos. *miss* foi para situacao-viagem (crítica 12). conhecer-levar-emprestar-dizer: L1 só *meet*, nova L2 só *know / get to know*. T14: L3 só *hear* (com as frases de socorro), nova L4 só *see*, contraste no fechamento. argumentar-conectores L1 só *despite*; *in spite of* no fechamento. phrasal-verbs-b2 L1 sem *get on with*. Teens e tens em lições separadas (crítica 2). quantificadores: *a few* (L2) e *a little* (L3) separados. O validador barra 16 pares na mesma lição.

**7. *There was / there were* nunca ensinado (média). Aceito.**
Nova lição em passado-was-were: "Tinha muita gente" (*There was a lot of traffic this morning. / There were a lot of people at the concert. / Was there a meeting yesterday? / There wasn't any food at the party.*). Retomadas com exemplo: *There's going to be a party on Friday.* (tres-futuros), *There have already been three meetings today.* (present-perfect-just-yet), *If it rains, there'll be a lot of traffic.* (se-e-quando). BR03 rotulado nessas trilhas.

**8. Reflexivos e verbos pronominais (média). Aceito.**
Novo ponto **BR62**. Nova lição em adverbios-phrasal-possessivos (A2): "Me sinto bem: sem -self" (*I feel much better today. / I set up the whole desk by myself. / I hurt myself, but it's nothing serious. / Help yourself!*). Retomadas em revisao-a2, ha-quanto-tempo (*each other*) e situacao-vida-social (*Make yourself at home.*). Escolhi a trilha 47 e não a 45 porque ela já trata de pronomes (*mine, yours*).

**9. *Both / either / neither* e *all of / none of* (média). Aceito.**
Nova lição em quantificadores-incontaveis: "Os dois, nenhum dos dois" (*Both laptops are good... / Neither date works for me. / Either is fine. / either Tuesday or Thursday*). Nova lição em regencia-preposicoes: "Todos nós, nenhum deles" (*All of us work remotely. / None of them answered my email. / Most of the team is in Chicago. / Each of you will get a new laptop.*). Fiz uma lição própria em vez de encaixar em T65 L4, porque a L4 já tinha 12 itens e estouraria o teto.

**10. *Be supposed to*, passiva com *get* e *had better* tarde demais (média). Aceito.**
*be supposed to* foi para modais-no-passado (B1), em lição própria, com o contraste com *should have* numa lição de contraste; saiu do C1. *get* + particípio foi para passiva-1 (B1), em lição própria (*got promoted, got stuck, got hacked*); no C1, a lição virou infinitivo perfeito passivo (*is believed to have been...*). *had better* foi para deducao-perguntas-indiretas (B1), em lição própria; saiu de colocacoes-expressoes (B2). No C1 ficaram *ought to*, *may well* e *might as well*.

**11. *Want to / need to* só na lição ~170 (média). Aceito.**
Nova lição em presente-simples (A1, trilha 10): "Quero aprender: want to, need to" (*I want to learn English. / I need to fix this bug today. / I'd like to work with you. / I don't want to work late.*), declarada como fórmula no `gramatica` da trilha e na tabela de fórmulas do DESIGN 4.4.

**12. Onze pontos lexicais (BR31–BR41) em 13 lições seguidas (média). Aceito em parte.**
Feito: conhecer-levar-emprestar-dizer saiu de logo depois de fazer-ficar-perder-ganhar e foi para depois de dev-slack-commits (agora as duas estão a 4 trilhas de distância, cerca de 25 lições); *miss* foi para situacao-viagem (nova lição "Perdi a conexão"); a lição de *wear* saiu de fazer-ficar-perder-ganhar porque *wear* já é ensinado em presente-continuo (A1); *stay* fica em situacao-viagem. **Recusado:** reduzir as duas trilhas a uma de 3 lições e espalhar o resto pelos destinos sugeridos. Três lições não comportam make/do, ficar, perder, ganhar, ir/vir, levar/trazer, emprestar, dizer, emprego e -ed/-ing com os pares em lições diferentes (o próprio problema 6); e dois destinos sugeridos não servem (a trilha 42 é dev-calls-daily, não uma trilha de dinheiro; mandar *lend* e *borrow* para convites-pedidos juntaria o par numa trilha curta).

**13. Estruturas do B2 reapresentadas como novas no C1 (média). Aceito.**
clivadas-fronting: a L3 virou clivada com verbo (*What we did was roll back the deploy.*), que é C1 de verdade; a lição de *do* enfático saiu (o *I do appreciate* virou frase de reciclagem no fechamento); o `gramatica` marca *What I need is / All we did was / do enfático* como reciclagem do B2. passivas-impessoais L1 deixou de repetir o B2 porque *It is said / is believed* saiu da passiva-2 (crítica 34). nominalizacao-participiais L5 virou "Se for, se não" (*if so, if not, do so*), com *I'm afraid not / so did I* marcados como reciclagem. phrasal-verbs-b2: "separáveis com pronome" marcado como reciclagem das trilhas 8, 35, 47 e 71. As lições liberadas foram para as lacunas (BR61, reflexivos, *there was*, *both/neither*) e para variantes C1 (clivada com verbo, *is believed to have been*).

**14. Cenas finais do C1 com `fechamento: false` e 10 itens novos (média). Aceito.**
A regra global marca a última lição de toda trilha comum como fechamento, com `vocabulario` vazio; os itens de cena que aparecem nos exemplos ficam em `cena` (no máximo 4) e os demais vão para a reserva. Os pares que se juntavam nessas lições agora estão num fechamento de fato.

**15. Verbos de estado no contínuo (média). Aceito.**
presente-continuo L4 reescrita: "Hoje eu preciso: verbos sem -ing" (*I need your help today. / I think it's a good idea. / I'm thinking about the trip.*), com o contraste *usually* x *today*. A roupa (*wear, take off*) foi para uma lição própria. A retomada com *know* + *for* já existe em ha-quanto-tempo (*We've known each other for ten years.*).

**16. Pergunta relatada antes da pergunta indireta (média). Aceito.**
deducao-perguntas-indiretas passou para antes de discurso-indireto (trilhas 60 e 61), o que coloca *Do you know where...? / Could you tell me...?* antes de *She asked me where I lived*, como pede a regra D13 do dossiê 02.

**17. Itens rotulados como "já vistos" que nunca foram ensinados (média). Aceito.**
*I need a doctor. / Call an ambulance! / Help!* entraram em can-pedidos-habilidades (A1, trilha 14). *the same / the same as* entrou em comparar (A1, trilha 26, lição nova). *so + adjetivo + that* entrou em ligar-ideias (*It was so cold that we stayed home.*). As referências foram corrigidas com o número da trilha ("(A1, trilha 14)"). Os `recicla` de perguntas-com-do L3 (*app*) e de can-pedidos-habilidades L3 (*file*) foram limpos: a regra global tira de qualquer `recicla` do A1 o item ainda não visto (fica registrado em `reciclaRemovidos`), e do A2 em diante o `recicla` só usa itens de trilhas anteriores.

**18. Fatos sobre "você" que se contradizem (média). Aceito.**
Criada a ficha do aluno em `personagem` (campos do perfil e fatos fixos) e o validador D11 no DESIGN. Corrigidos: *Two years ago, I moved to a bigger apartment.* (era "to Curitiba"); *Ana grew up in Recife...* (era "I grew up"); *Julia used to live in Recife, but she moved to Curitiba in 2020.*; *I've worked from home since 2020.*; *I've lived in this neighborhood for two years.*; *Mike has worked at this company since 2015.* (era "I... since 2022"). Ver também a crítica 27.

**19. Preposições de movimento e *for* x *during* (média). Aceito.**
Nova lição em situacao-viagem: "Entra, passa, sai" (*into, out of, through, past, across*). Novo ponto **BR63** com lição em contar-historia (A2): "Por três anos, durante o voo" (*Ben lived in Brazil for two years. / I fell asleep during the flight.*), retomado em situacao-viagem, revisao-a2 e ha-quanto-tempo. Fiz a lição em contar-historia, e não na revisao-a2, porque revisão não introduz ponto novo.

**20. Fórmulas usadas antes da regra fora da lista do DESIGN (baixa). Aceito.**
DESIGN 4.4 tem agora uma tabela de fórmulas antecipadas por trilha, com a trilha em que a regra abre (*How do you spell it?, What's your name?, Where are you from?, Have a nice day., Let me think., I didn't catch that., Tell me about yourself., How about + -ing, got promoted...*), e o `gramatica` de primeiro-contato, numeros-horas-soletrar, eu-e-voce-be, situacao-hotel, presente-simples e ja-fui-x-fui as declara. O L03 lê essa tabela.

**21. Três sistemas de horas numa lição do A1 (baixa). Aceito.**
A lição de horas ficou só com *It's ten o'clock.* e *It's seven thirty.* (e *What time is it?*, sem *now*). *a quarter after/of* e *half past* viraram reconhecimento em situacao-viagem L1. Os chunks do plano foram atualizados.

**22. Trilhas desequilibradas (baixa). Aceito.**
Saiu uma lição de colocacoes-expressoes (a de *had better*, que foi para o B1), de phrasal-verbs-b2 (a de *roll back / set off / look forward to*, que já estão em dev-incidentes e escrita-formal) e de dev-planning-retro (a de *circle back / take offline*). Entraram: uma lição de contraste em ja-fui-x-fui ("Já revisou? Revisou quando?"), *be supposed to* e uma lição de contraste em modais-no-passado, e uma lição de contraste 2ª x 3ª condicional em terceira-condicional.

**23. nLicoes do plano diferente das lições escritas (baixa). Aceito.**
Plano e lições viraram uma coisa só (`esboco.json`); `nLicoes` e os totais são calculados das lições e conferidos pelo validador (D12). DESIGN 0, 4.1 e 4.3 recalculados.

**24. Ordinais só até *third* (baixa). Aceito.**
Nova lição em rotina-dias-horarios: "Julho a dezembro e as datas" (ordinais por extenso até *thirty-first*, *on October fourth*). Retomada em tres-futuros L2 (*We're meeting on the twenty-first.*). *fifth floor* em situacao-hotel foi declarado como fórmula.

**25. *How about + -ing* contradiz "preposição + -ing fica para o B1" (baixa). Aceito.**
*How about + -ing* declarado fórmula do A2 (convites-pedidos e DESIGN 4.4); a nota de verbo-to-ing L2 foi corrigida; relativas-gerundio L4 diz que *How about* foi o primeiro caso e que ali o padrão vira sistema.

## Lente: aprendiz (24)

**26. Formas britânicas como alvo (*shall, mustn't, needn't*) (alta). Aceito.**
tres-futuros L4: *Should I open the window?* (PT "Eu abro a janela?"), *Should I drive you home?*. convites-pedidos: *Do you want to go for a walk after dinner?*, *Should I book a table for ten?*. obrigacao-conselho L3 reescrita: *You can't park here. / You're not allowed to share your password. / Don't share your password with anyone.* (*must* só em regra escrita). deducao-no-passado L4 reescrita: *You didn't have to bring dessert... / I didn't need to rush...*; L5: *We didn't need to restart the server.* A lista de bloqueio do N03 (DESIGN 6.4) e o validador barram *shall, mustn't, needn't, mind you, take on board, a drop in the ocean, brilliant, quite* (britânico), *can't have* e *the daily*; essas formas aparecem só como reconhecimento em registro-variantes.

**27. A biografia do aluno usa o nome real e inventa fatos (alta). Aceito em parte.**
Os fatos inventados saíram: idade, ano de nascimento, namorada, cidades e anos de experiência agora vêm dos campos do perfil (`{idade}`, `{cidade_natal}`, `{anos_dev}`...) ou foram para outro personagem (*My brother met his girlfriend at a party.*, *Ana grew up in Recife*, *Julia used to live in Recife*). **Recusado em parte:** usar o nome do dono não é defeito. O curso é dele, e o próprio pedido é decorar frases sobre a própria vida. O nome continua, como valor padrão do campo `{nome}` / `{sobrenome}` (Carlos Souza), e muda sozinho para outro usuário. A coerência é garantida pela ficha em `personagem` e pelo D11.

**28. Alvo único reprova inglês correto (contrações *'s/'d*, sinônimos) (alta). Aceito em parte.**
(a) Aceito: *'s* e *'d* passam a ser automáticas, resolvidas pelo token seguinte (DESIGN 3.3, regra 2). (b) Aceito na forma, com outra solução no detalhe: sinônimo fora do alvo (*tired* por *worn out*) é revelado e limita a nota a Difícil, nunca De novo (2.5); **recusado** mostrar a inicial das palavras de conteúdo nas revisões, porque enfraquece a recordação de toda frase para resolver um caso que a regra do sinônimo já resolve. (c) Aceito: T04 roda na geração contra o autômato da frase; sinônimo provável vira `var` ou gancho no PT (5.3, regra 5).

**29. Faltava o controle de passaporte (alta). Aceito.**
Nova primeira lição em situacao-hotel, que passou a se chamar "Situação: imigração e hotel": as perguntas do oficial ficam no `contexto` em inglês (ouvidas, não digitadas) e o aluno digita as respostas (*I'm here on business. / For five days. / At a hotel downtown. / I work for an American company. / Nothing to declare.*).

**30. Inversões literárias em conversa casual e peso desproporcional no C1 (média). Aceito.**
inversao-negativa (6 lições) e condicionais-invertidas (7) viraram uma trilha só, `inversoes-escrita-formal` (5 lições), em relatório, política, e-mail formal, negociação e discurso, com o par de registro (*Had we known* no e-mail x *If I'd known* na conversa) marcado por pista no PT. No B2, enfase-inversao-clivadas: a L1 virou avaliação escrita; a L2 ensina *As soon as / The moment* na fala e deixa *No sooner had... than* para o texto escrito; o fechamento virou discurso de despedida. As 8 lições liberadas foram para a situacao-vida-social (C1) e para as lacunas de gramática. *Were I to*, *But for*, *Hardly... when* ficaram como reconhecimento.

**31. "I'm fine, thanks. And you?" como primeira frase (média). Aceito.**
primeiro-contato L1: *Hi, Mike! How's it going? / I'm good, thanks. How about you? / Pretty good, thanks!*. L4: *Sorry, I didn't catch that.* ("Desculpa, não peguei.") e *Sorry, what was that?*.

**32. Falsos amigos tratados ao contrário (cafeteria, promotion, resume) (média). Aceito.**
"Você sabe se o refeitório abre aos sábados?" com nota "cafeteria (EUA) = refeitório". *Have you heard? Mike got promoted last week.* ("O Mike foi promovido"). falsos-cognatos-trabalho L3 reescrita: "Currículo, pauta e política" (*Could you send me your resume? / Let's pick this back up after the break.*). *I've attached my resume to the email.* entrou em situacao-entrevista.

**33. Frases longas demais para recordação literal (média). Aceito em parte.**
Teto de 18 palavras no B2, C1 e dev, com alvo de ~14 e uma ideia; 15 a 18 palavras só marcadas (D4 e prova em N2). Reescritas ou divididas em dois itens todas as frases da dev e do C1 acima de 15 palavras (cerca de 120): a média da dev caiu de 16,3 para 11,7 palavras e não sobra nenhuma acima de 15. **Trocado:** o limite das revisões por palavras (900 por dia) virou limite por **tempo** (metade da meta diária, até 80), que mede a mesma coisa e já leva em conta o tamanho da frase.

**34. Passiva impessoal em fofoca e em status de incidente (média). Aceito.**
passiva-2 L5 reescrita: *I heard the company is hiring... / Apparently, the new CEO is really demanding. / The new office is expected to open in March.* Status: *Initial findings suggest the problem was caused by a single bad line of code.* *It is said / is believed* ficaram só no C1 (passivas-impessoais, texto escrito), e o validador barra *It is said* fora dali.

**35. Expressões britânicas (*mind you, drop in the ocean, take on board, brilliant, quite, can't have*) (média). Aceito.**
*Then again, it wasn't cheap.*; *I'd love to stay for another round, but I have an early flight.*; *a drop in the bucket*; *That's fair, and I'll keep it in mind.*; *absolutely amazing*; *kind of slow*; *couldn't have* como `cod` (com *can't have* aceito como variante).

**36. Present perfect onde o americano usa passado (média). Aceito.**
*I can't find my keys. Have you seen them?*, *Has anyone seen my charger?*, *Have you pushed the fix yet?* no lugar de *I've lost my keys again / I've left my laptop / I've broken the build*; a nota da lição diz que em en-US o passado é o mais comum para perda simples. *I lost my keys again.* foi para a lição de *lose*. *gone to x been to* virou só nota: a lição virou "Ele já foi ao Brasil: has + particípio".

**37. "the daily" no inglês (média). Aceito.**
*after standup*, *where we have standup*; o PT continua "daily" e o glossário diz daily (BR) = standup (EUA). Lições e textos do plano renomeados ("O standup de segunda", "Manhã: standup e mensagens").

**38. Duas pessoas falando no mesmo `cod` (média). Aceito.**
Os 10 casos viraram dois itens, com `quem` e a fala anterior no `contexto`. Nas respostas curtas: *So am I.* ("Eu também estou."), *Neither can I.* ("Eu também não consigo.") e *Me neither.* ("Nem eu."), com o glossário fixando a diferença entre "Eu também (estou)" e "Eu também". O validador barra `?` seguido de *Yes/No/So/Neither/For...* (D10).

**39. Nenhuma situação do dia a dia depois do B1 (média). Aceito.**
As quatro trilhas de situação da crítica 3 cobrem aluguel e contas, carro e estrada, reclamação por telefone e vida social com small talk (esporte, Thanksgiving, receber o Ben, rodada no bar). No restaurante do A1: *Is the tip included? / Can I add a tip on the card?* no lugar de *Keep the change* numa conta dividida no cartão.

**40. O caso real do dono (remoto do Brasil) quase não aparece (média). Aceito.**
situacao-entrevista L5: *I'm based in {cidade}, Brazil. / I can overlap with your team until 6 p.m. Central. / Sorry, could you rephrase the question?* e *Can you hear me okay?* no vocabulário. pro-entrevista-senior L5: *I'd be working as a contractor, so I'd send you an invoice every month. / My hourly rate is sixty dollars. / I'm in Brazil, but I can overlap with your team until 2 p.m. Pacific.*

**41. Frases que só mostram gramática (baixa). Aceito.**
*That building is very modern.*, *Those chairs are very cheap!*, *How much water do we need for the trip?*, *How much bread do we need?*, *Emma, your cat is under the couch!*, *This is a great opportunity for our community.*, *Portuguese is spoken in nine countries.*, *The old station was turned into a museum in 2010.*, *On the one hand, it's faster. On the other hand, it would cost more.*

**42. Cenas que contradizem a frase (baixa). Aceito.**
A idade saiu do crachá (perguntas-com-be L2: crachá só com nome; idade no almoço com a Emma). A tag question vai para alguém que você acabou de conhecer no bar (*You're from Chicago, aren't you?*). Na história, perde-se a carteira no táxi e o taxista acha a carteira. Ben deixou de ser colega: *The new developer admitted...*, *You've been quiet. Do you have anything to add?*.

**43. Traduções com registro ou regência errados (baixa). Aceito em parte.**
"Muito obrigado, Ana!"; "Ela é a desenvolvedora cuja biblioteca nós usamos no app."; "Ele é a pessoa de cuja aprovação você precisa."; "fazia dezesseis horas que eu estava trabalhando" (e as outras frases de *past perfect continuous* com "vinha... havia"); "Será que você poderia passar a reunião para quinta?"; "Quer assumir o teclado?". **Mantido em parte:** "discutir" continua em *Could we discuss this on Monday?*, porque a lição treina o BR42 (*discuss* sem *about*) e "conversar sobre" levaria a *talk about*; para tirar o tom de briga, o objeto virou "esse assunto".

**44. Glossário inconsistente (pretender, sprint, implantada, Entre/Entra) (baixa). Aceito.**
pretender = *plan to* (*I plan to finish it today.*, *We plan to finish the roadmap review by Friday.*), *intend* só como nota de escrita formal. "a sprint" sempre (o validador barra o masculino). "A correção já subiu" e "implementação" no lugar de "implantada / implantação" (o validador barra "implant-"). Imperativo único (DESIGN 5.3, regra 11): forma falada (entra, vira, pega, verifica, fica) na fala e forma padrão no formal e no escrito; instrucoes-e-lets e mais 7 frases ajustadas. O glossário travado está em `esboco.json` → `glossario` (38 entradas).

**45. Colocações pouco naturais (baixa). Aceito.**
*the server had gone down*, *because I'd gotten the time zone wrong*, *We carried out a security audit* (*carry out* é o item; *a survey* soava mal), *We started this project*, *I've built two mobile apps*, *My connection is at five. I'm going to miss it.*, *What time is it?*, *there's no hot water*, *I think you're on mute.*, *iron out the issues in the retry logic*, *polite to*, *communicating with*.

**46. Tom e cultura de trabalho errados (baixa). Aceito.**
*Our process ought to have caught this much earlier.*, *In hindsight, we ought to have planned more than a weekend for this.* (postmortem sem culpados), *Make sure you pay attention to the details...*, *I wouldn't be surprised if the client asked for more changes.*, *Our new hire is very educated and always polite to the support team.* Regra 15 de 5.2 no DESIGN.

**47. Resposta STAR robótica (baixa). Aceito.**
pro-entrevista-senior L2 reescrita: *At my last company, our app kept crashing on older phones. / We were losing users every week. / I was the only senior engineer, so finding the cause was on me.* *situation* e *task* ficam só na nota.

**48. Exemplos repetem a moldura e a primeira palavra (baixa). Aceito.**
As lições citadas foram reescritas ou variaram a abertura: condicionais-invertidas (fundida, crítica 30), enfase-inversao-clivadas L2 (*As soon as / The moment / No sooner*), conceder-rebater L1 (*We underestimated the effort, admittedly, ...*) e wish L3 (*Honestly, I wish you would... / That dog barks during all my calls. I wish it would stop!*). O D03 vale também para os exemplos do esboço.

**49. *whom* como alvo digitado (baixa). Aceito.**
relativas-3 L3 reescrita: *This is the team we shared the results with. / The server the app runs on is in Ohio.* e uma única frase de e-mail formal com *to whom* (fora do `vocabulario`). *The engineer I spoke with confirmed the problem.* no fechamento.

## Lente: mecânica (34)

**50. A tolerância premia os erros-alvo de brasileiro e pune o dedo (alta). Aceito.**
DESIGN 2.6: deslize tolerado só para uma tecla vizinha ou uma transposição, fora da zona de morfologia (3 últimas letras de *-s, -es, -ed, -ing, -er, -est, 's*), e se não formar outra palavra válida; vale também em palavras de até 3 letras; palavra encerrada cedo ou alongada sempre derruba e registra o BR. Com o modo palavra a palavra (crítica 67), *She work...* deixa de ser "1 erro tolerado". Testes unitários exigidos em 2.12.

**51. `alt` com frases inteiras não cobre as variações sistemáticas (alta). Aceito.**
DESIGN 3.3: autômato por frase com 12 variações automáticas (*'s/'d*, *that* opcional, partícula separável, *-ing ↔ to*, adjunto de tempo, *already* opcional, *might ↔ may*, perfect simples ↔ contínuo, futuros fora do alvo, *some/any*, OK/okay, compostos) e variações declaradas por trecho (`var`, `opcional`) no lugar de `alt` (5.1). O T04 usa o mesmo autômato.

**52. A mesma tradução leva a ingleses diferentes (alta). Aceito.**
Glossário travado em `esboco.json` → `glossario` e D05 bidirecional e bloqueante. Casos corrigidos: "Me desculpa, Sarah." e "Sinto muito, mas..." para *I'm sorry*; *Is this yours?* ("Isso é seu?") para o pronome sozinho; *I love traveling* nos dois lugares; "Trabalho aqui há..." com *I've worked* e o contínuo aceito pela variação automática; *would* para "disse que ia" (*Mike told us he would talk to her today.*); "O som está muito alto." para *music*; *might* com *may* e *could* aceitos; "Eu abro a janela?" = *Should I...?* e "Quer que eu...?" = *Do you want me to...?*.

**53. A fila gulosa não cumpre os lags da própria tabela (alta). Aceito.**
Escalonador em ondas (DESIGN 2.3): onda 0 com todos os D1 na ordem da cena, ondas seguintes na mesma ordem, recheio quando um item violaria o lag. Simulado: 8 frases → lags 7, 7, 7 e 8 com 1 recheio (41 digitações); 10 frases → lag 9 em tudo. Sem revisões no dia, o recheio usa frases já concluídas da lição em N3, sem nota. A tabela do DESIGN mostra os lags reais e quatro sequências simuladas.

**54. O contexto em inglês entrega outra frase-alvo (alta). Aceito.**
DESIGN 2.2 e 5.1: o `contexto` aponta o `id` da fala anterior e aparece em PT enquanto ela não concluiu (ou tem revisão no mesmo dia); em inglês, só depois, ou quando o contexto não é frase-alvo (a pergunta do oficial da imigração). Respostas curtas usam PT por padrão.

**55. Os arquivos de lições são especificação, não lições (alta). Aceito em parte.**
Aceito: o DESIGN 5.1 agora diz com clareza que `esboco.json` é o roteiro e que a próxima fase gera um JSON por lição no formato 5.1, com validador de schema (F09, F10, D09) antes da revisão de conteúdo; as interferências de cada lição viraram códigos em `br`; o esboço tem `id` estável por lição. **Recusado nesta etapa:** gerar agora as ~5.200 frases no formato final. Esta revisão é do desenho; gerar as lições é a fase seguinte, e gerá-las sobre o desenho antigo multiplicaria os defeitos que as outras 82 críticas apontaram.

**56. Portões em N3 exato medem adivinhação de redação e são longos (alta). Aceito.**
DESIGN 2.9: 8 frases por portão, N3 assistido (contador e iniciais das palavras fora do alvo), nota só no chunk-alvo e na ordem, Difícil conta como acerto, limiar 6 de 8, encerra no 3º erro; 2 a 3 minutos por portão. O mesmo modo vale para o "testar para pular".

**57. Passar no portão joga ~1.000 frases nunca digitadas na caixa 3 (alta). Aceito.**
Só as frases digitadas no teste vão para a caixa 3; as outras ficam "testadas, não vistas", amostradas como recheio (no máximo 10 por dia) ou na Onda 2; falha reabre a lição em modo rápido (2.8 e `testarParaPular`).

**58. Critérios de nota não acompanham o tamanho da frase (alta). Aceito.**
`Lmax` = 3 s + 0,05 s por caractere da tradução; `v` contra a mediana das digitações de memória em frases de tamanho parecido; Boa com `acc` ≥ 0,9 em frases de 12+ palavras; Difícil avança meia caixa no Leitner (intervalo × 1,5; dois seguidos sobem uma caixa); o segundo Difícil no D4 promove para a prova (2.3, 2.6 e 2.8).

**59. Recordação literal de frases de até 25 palavras no mesmo dia (alta). Aceito.**
Teto de 18 palavras no B2, C1 e dev (era 20 e 25); alvo de ~14; de 15 a 18, D4 e prova do dia em N2 e N3 só a partir da 1ª revisão; frases de duas orações divididas em dois itens (crítica 33).

**60. Estimativas de tempo otimistas (média). Aceito.**
Tempo refeito com o tamanho real das frases do esboço (DESIGN 2.3): 10–12 min por lição no A1 até 20–22 min no C1 e na dev. Meta diária em minutos (15, 30 e 50), revisões limitadas a metade do tempo da meta, frases novas por dia caindo naturalmente com o tamanho. Curso inteiro: ~320 a 370 h, ~21 a 24 meses na meta normal (eram "~19 meses e 200–250 h").

**61. Itens novos demais por lição (média). Aceito (mesmo problema da crítica 2).**
Teto novos × 2 ≤ nFrases, com `apoio` e `cena` separados e o excedente para a lição seguinte ou para a reserva da trilha.

**62. Plano e lições divergem; C1 sem `fechamento`; quatro nomes para reciclagem (média). Aceito.**
Fonte única (`esboco.json`) com `nLicoes` e totais calculados; `fechamento` presente em todas as lições e verdadeiro na última de toda trilha comum; um só campo `recicla`; totais do DESIGN recalculados.

**63. *'s* e *'d* sem forma definida pela tradução (média). Aceito.**
Resolvidas pelo token seguinte (DESIGN 3.3, regra 2), com o possessivo de substantivo ainda exigido; e a regra 5.2.3 pede a mesma escolha (contração ou forma plena) dentro de cada trilha.

**64. "Já" sem *already* no inglês (média). Aceito.**
Regra 5.3.7 (o "já" só com *already / ever / yet / by now*; nos outros casos tira-se o "já" ou vale *already* opcional, variação automática 7) e checagem no T09. Ajustados: futuro-avancado L1 ("Até sexta, a gente vai ter terminado..."), "Não percebi que era tão tarde", passiva-2 (*The fix has already been deployed*). "Já vou!" e "já que" ficam como fórmulas à parte.

**65. Âncoras de futuro colidem (média). Aceito.**
Pista obrigatória quando o futuro é o alvo (5.3.8): "(combinado)" nas frases de contínuo de tres-futuros, "(promessa)" e "(decidi agora)" nas de *will*; "(só para saber, sem pedir)" em *Will you be using the meeting room...?*. Fora das lições de futuro, os três são aceitos (variação automática 10).

**66. Adjunto de tempo em posição diferente nas duas línguas (média). Aceito.**
Regra 5.3.9 e variação automática 6 (início ou fim). Ajustados: "Estou trabalhando de casa hoje.", "Eu não tive tempo ontem.", "(combinado) Encontro a Ana na sexta.", "(combinado) A gente janta com o Ben no sábado.", "São seis e quinze." e "(no discurso) Mal sabia eu, quando entrei, que ia liderar este time.".

**67. "Também está certo" e armadilhas são inimplementáveis num motor letra a letra (média). Aceito.**
Modo palavra a palavra em N1–N3 (DESIGN 2.1 e 2.5): a palavra inteira é conferida no espaço, o que permite reconhecer a variação aceita, o sinônimo fora do alvo e a armadilha BR## digitada. N0 continua letra a letra.

**68. Maiúscula inicial livre engole o BR15 (média). Aceito.**
A 1ª letra é livre só quando a primeira palavra não é *I / I'm / I'd / I'll / I've*, nome do elenco, dia, mês, língua ou nacionalidade; erro de caixa nessas classes derruba a palavra (3.1 e 2.6).

**69. Enter antes do fim toca o áudio e custa dica (média). Aceito.**
Enter antes do fim mostra "faltam N palavras" e não toca nada; o áudio foi para Ctrl+. (ou botão), Ctrl+Shift+. para devagar; o contador em N3 é obrigatório (2.1, 2.4).

**70. Construção por blocos no D1 contradiz P2 (média). Aceito.**
Blocos com cópia eliminados: o D1 é sempre uma cópia da frase inteira; frase longa vira dois itens; o campo `blocos` (corte na fronteira de chunk, escolhido pelo autor) só serve para dividir sanguessugas (2.3 e 2.8).

**71. O pulo do D3 acontece quase sempre (média). Aceito.**
Pulo só com D2 Boa ou Fácil, `v` ≥ 0,8, `L` ≤ 3 s e frase de até 8 palavras (2.3, regra 3).

**72. Teto de 8 cabe só um erro (média). Aceito.**
O teto conta só digitações de memória (cópias de correção não entram); o segundo lapso devolve a frase ao N1 na onda seguinte; frase sem prova no fim sai como difícil e vale 0 na nota (2.3, regras 4 e 7).

**73. Critério de conclusão mais fraco que o dossiê (média). Aceito.**
Concluir exige duas recuperações em N3 aceitas (D4 e prova), como no dossiê 01; Difícil na prova vale para frases de 12+ palavras. A volta ao critério de uma só ficou como decisão em aberto a decidir pela telemetria (DESIGN 7.2, item 11).

**74. Duas falas no mesmo `cod` (média). Aceito (mesmo problema da crítica 38).**
Corrigido nos 10 itens e no pro-carreira-networking L2; validador D10.

**75. Chave de progresso por hash do texto x `id` posicional (média). Aceito.**
`id` opaco gravado no JSON (frase: `f-` + hexadecimais; lição: `trilha.slug-do-nome`, gerado uma vez), nunca derivado da posição; o hash só detecta mudança: forma mantém o cartão, sentido desce uma caixa (2.10 e 5.1).

**76. Formas britânicas e *half past ten* no plano (média). Aceito (mesmo problema da crítica 26).**
Também os chunks do plano: *Should I open the window?*, *You can't park here.*, *He couldn't have left already.*, *You didn't have to buy it.*, *seven thirty* no lugar de *half past ten* e *a quarter to five*.

**77. Parênteses no `cod` (baixa). Aceito.**
Proibidos (F02 e regra de tipografia); os três rótulos de code review viraram *Non-blocking: ...* / *Non-blocking suggestion: ...*.

**78. Compostos com grafia variável exigidos letra a letra (baixa). Aceito.**
Tabela de compostos aceitos automaticamente (hífen ≡ nada ≡ espaço) e OK ≡ okay (DESIGN 3.2).

**79. Formato de números e horas sem padrão (baixa). Aceito.**
Formato canônico (5.2 e 5.3.17): *9:00* ↔ "9h00", *7:30* ↔ "7h30", *nine* ↔ "nove", *percent* ↔ "por cento"; `%` digitado vale *percent*. Corrigidos "às 9h00" (dev-incidentes), "às 10h00" (pro-dia-de-trabalho) e "80 por cento" (pro-entrevista-senior); o validador barra "às 9h" e "%".

**80. O contador de palavras engana com números (baixa). Aceito.**
Palavras contadas no `cod` separado por espaços (*7:30*, *$40,000* e *S-O-U-Z-A* = 1), a mesma contagem no "faltam N" (2.1, 2.6).

**81. Bônus de 50 por trilha testada no portão distorce o ranking (baixa). Aceito.**
Bônus só no "testar para pular", uma vez por trilha; o portão dá um marco sem pontos (2.10).

**82. §2.12 desatualizado em relação ao código (baixa). Aceito.**
Conferido no código (leitura, sem alterar nada no projeto): `Revisao.limiteDiario = 80`, `pontuacaoAutomatica`, `_primeiraLetra`, `errosDeCaixa`, `alternativas.dart` e `_alternativaPara`, `variantesContextuais`, `invisiveis`, `composicoesUsIntl` e Enter / Shift+Enter já existem. A seção virou três listas: já existe, precisa mudar e falta implementar.

**83. A fórmula da trilha 1 passava do limite da própria trilha (baixa). Aceito.**
Trilha 1 com *More slowly, please.*; a frase inteira *Could you speak more slowly, please?* foi para can-pedidos-habilidades (A1, trilha 14); o limite da trilha 1 subiu para 6 palavras / 35 caracteres para caber *I'm good, thanks. How about you?*.

---

## Outras correções feitas na revisão (achadas ao aplicar as críticas)

- Pistas de registro e de tempo (*(agora)*, *(por escrito)*, *(e-mail)*, *(no discurso)*) ficam só no PT; o `cod` nunca leva pista, e o validador barra parênteses no inglês.
- Referências numéricas a trilhas atualizadas para a numeração nova (por exemplo, "reciclagem do B2, trilha 86", "trilhas 74 a 78").
- `pt_f` acrescentado em frases do aluno com adjetivo ou particípio com gênero (desenvolvedor/desenvolvedora, animado/animada, cansado/cansada, obrigado/obrigada).
- Listas de chunks do plano coerentes com as lições revisadas (sem *Shall I*, *mustn't*, *needn't*, *whom*, *It is said*, *had better* no B2, *roll back* e *circle back* nas trilhas de onde saíram).
- **Mapa das lições antigas para as novas:** `_revisao/mapa_licoes_v1_para_v1.1.json` liga cada lição da v1.0 (`<trilha>-<NN>`) ao `id` estável da v1.1, ou marca que ela saiu (e para onde foi o conteúdo, no caso das duas trilhas do C1 fundidas). 69 das 566 lições mudaram de posição ou saíram, em 27 trilhas. Qualquer dado que use a posição da lição (por exemplo, as fotos `assets/ingles/fotos/<trilha>-<NN>.jpg` do fluxo de imagens) precisa ser realinhado por esse mapa; daqui em diante, o certo é usar o `id` da lição.
