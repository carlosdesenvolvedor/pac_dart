# Paclingo — o que acrescentar (pesquisa de apps de inglês, 12/out/2026)

> **Como usar este arquivo.** É o mapa do que os apps de inglês têm e o Paclingo ainda não. Cada item vira uma **fase**.
> A **Fase 1 já tem plano detalhado** em [`FASE-1-HABITO-DIARIO.md`](FASE-1-HABITO-DIARIO.md) e o prompt para entregar a um agente em
> [`PROMPT-AGENTE-FASE-1.md`](PROMPT-AGENTE-FASE-1.md). As outras fases ganham o próprio plano quando chegar a vez delas.
>
> **Ordem sugerida de execução:** 1 → 3 → 2 → 6 → 4 → 5 (a 1 segura quem já entrou; a 3 custa pouco porque as peças existem;
> a 2 é o maior diferencial; as demais dependem do que as anteriores deixam pronto).

## O que o Paclingo já tem (não repetir)

Digitação em escada (5×) com ensaio mental e cena visual · revisão espaçada **FSRS** (baralhos, navegador, importar/exportar Anki,
áudio do aluno) · cartão de virar com **níveis** (Fácil/Médio/Avançado/Só virar) e **sentidos** (EN→PT, PT→EN, misturado) ·
lição a partir de **texto colado** · nivelamento · treino de conjugação · vozes (gravação do curso, Chirp, voz do aparelho) ·
**Prof. Dash** (IA, `firebase_ai`) · reconhecedor de fala com conferência por palavra (`AvaliacaoFala`, trabalho do dono ainda sem commit) ·
ranking e arcade.

---

## Fase 1 — Hábito diário: sequência, meta do dia, congelamento e lembrete

- **Quem faz:** Duolingo (sequência, congelamento de até 2, meta diária, lembretes), Speak (sequência com congelamentos, máx. 2).
- **Hoje no Paclingo:** nada. O HUD mostra SCORE/PPM/PRECISÃO/ERROS/TEMPO só da sessão aberta; ao fechar o app não sobra "hábito" nenhum.
- **O que falta:** 🔥 sequência de dias, meta do dia (exercícios), congelamento ❄️ ganho por constância, tela "Sua sequência" e, numa
  sub-fase separada (1B), lembrete no celular.
- **Esforço:** baixo a médio (1A) · médio (1B, mexe em `android/` e `ios/`).
- **Cuidados:** sem energia/vidas e sem pressão de perda agressiva (a crítica a sequências é que viram só métrica de engajamento);
  o dado é só do cliente — **não vai para o ranking** (daria para forjar, mesmo critério das notas do cartão).
- **Evidência (fraca, da própria empresa):** o Duolingo diz que permitir até 2 congelamentos aumentou os ativos por dia e que quem
  chega a 7 dias tem 3,6× mais chance de terminar o curso. Sem prova independente de causa.

## Fase 2 — "Explique minha resposta" + conversa em papéis com o Prof. Dash

- **Quem faz:** Duolingo Max (*Explain My Answer*, *Roleplay* com feedback no fim, *Video Call*), Speak, Praktika, ELSA (conversador por IA).
- **Hoje:** o Prof. Dash responde dúvidas no palco com o contexto da frase; não recebe o erro que a pessoa acabou de cometer
  nem conduz um cenário.
- **O que falta:**
  1. Botão **"Por quê?"** depois de errar (digitação) ou ao virar um cartão: envia frase, resposta esperada, resposta da pessoa e nível,
     e volta uma explicação curta em português.
  2. **Cenários guiados** (pedir um café, check-in no hotel, entrevista, chamada de trabalho — alinhados às cenas das lições), em turnos
     por texto e por voz (reaproveita o reconhecedor), com **feedback no fim**: o que foi bem, correções e 3 frases que viram cartão.
  3. **Cota diária por usuário** e cache, porque cada chamada de IA custa.
- **Esforço:** médio. A chave do Gemini vive em `config/tutor`; web usa REST e celular `firebase_ai`.
- **Sinergia:** alimenta a Fase 5 (erros viram cartões).

## Fase 3 — Ditado e shadowing

- **Quem faz:** ELSA e Speak (repetir e receber nota), Language Reactor (shadowing em vídeos), apps de IELTS (listening).
- **Hoje:** vozes com velocidade lenta; reconhecedor + `AvaliacaoFala` (por palavra). Falta usar isso como exercício.
- **O que falta:**
  1. Novo **sentido do cartão "🎧 Áudio → escrever"**: só o áudio na frente, sem texto; a pessoa digita o que ouviu (encaixa no
     `SessaoCartoesPage`, que já tem os níveis).
  2. **Modo shadowing**: ouve → a frase some → repete falando → conferência por palavra → nota sugerida.
- **Esforço:** baixo a médio. **Depende** de o reconhecedor do dono estar commitado e estável.
- **Evidência:** uma revisão de 44 estudos acha ganho em inteligibilidade, fluência e prosódia; efeito em sons isolados é inconclusivo;
  os estudos são pequenos.

## Fase 4 — Leitura com toque na palavra que vira cartão

- **Quem faz:** LingQ, Readlang, Language Reactor (toque na palavra → tradução → cartão com a frase), Clozemaster (lacunas em contexto).
- **Hoje:** texto colado vira lição para digitar; o nível Médio é quase um cloze.
- **O que falta:** tela de **leitura** (texto colado ou graduado) onde tocar numa palavra mostra a tradução (MyMemory, como já é) e
  **salva um cartão de lacuna com a frase de contexto** no baralho "Meus textos".
- **Esforço:** médio. **Cuidado:** dicionário/tradução por palavra isolada erra sentido; mostrar a frase inteira junto.

## Fase 5 — Escrita corrigida por IA, com os erros virando cartões

- **Quem faz:** Busuu (correção por revisores da comunidade), ELSA (conversador por IA), Duolingo Max (feedback do Roleplay).
- **Hoje:** nada de escrita livre.
- **O que falta:** a pessoa escreve 2–3 frases sobre o dia; a IA devolve o texto corrigido, explica cada erro em português e
  **cada erro vira um cartão**.
- **Esforço:** médio. **Depende** da cota/cache da Fase 2.

## Fase 6 — Sanguessugas e subida automática de nível

- **Quem faz:** Anki (*leech*: cartão que cai demais é marcado e tratado à parte); Duolingo (dificuldade adaptativa).
- **Hoje:** `CartaoSrs.lapsos` já é guardado; ninguém usa.
- **O que falta:** lista de **sanguessugas** nos Baralhos (ex.: 8+ lapsos) com ajuda (dica, outra frase de exemplo, mnemônico por IA,
  ou suspender); e **sugerir subir de nível** (Fácil → Médio → Avançado) depois de N acertos seguidos, e descer depois de erros.
- **Esforço:** baixo.

---

## Backlog (sem fase definida)

- **Metas por objetivo:** trilhas de viagem, entrevista de emprego, IELTS/TOEFL; relatório semanal de progresso por nível CEFR.
- **Ligas semanais e amigos** (Duolingo): não achei evidência independente de que funcionem — só depois do hábito provado.
- **Modo offline instalável** (PWA com cache de áudio). Obs.: o reconhecimento de voz no navegador exige internet (registrado em `reconhecedor_fala.dart`).
- **Vídeos com legenda dupla** (Memrise, FluentU, Language Reactor): o mais caro, por direitos de uso e hospedagem.
- **Mini-histórias** com perguntas de compreensão (Duolingo Stories, Lingopie).
- **Widget na tela inicial** com a sequência (celular).
- **Os níveis do cartão também na sessão "digitar de memória"** (`SessaoMemoriaPage`, o PT→EN digitado).
- **Já registradas antes:** gravar áudio pelo microfone (o pacote `record` pede Dart ≥ 3.12; o projeto está no 3.11), calibrar o FSRS com
  as revisões reais, áudio também no português, cloze, importar `.apkg`.

## Princípios para escolher e construir

1. **Diferencial é digitar + ensaio mental + FSRS.** Os concorrentes misturam toque e conversa de IA; quase nenhum cobra escrever a frase.
   Cada fase deve reforçar isso, não virar "mais um Duolingo".
2. **Nada de dado forjável no ranking** (sequência, notas de auto-avaliação).
3. **Sem padrões sombrios:** nada de energia/vidas que bloqueiam estudo, nem culpa nas notificações.
4. **Recursos de IA sempre com cota diária e cache** (custo e abuso).
5. **Cada fase termina com:** testes (com mutação nos pontos críticos), prova no Chrome real pelo *probe* e atualização do
   `ESTADO-DO-PROJETO.md`.

## Ressalva sobre a pesquisa

A maioria das fontes são blogs de comparação com links de afiliado e páginas de lojas; os rankings são opinião e os preços
divergem entre elas (por isso não há preços aqui). As cifras de retenção são da própria empresa. Para decidir investimento,
vale olhar as notas atuais nas lojas e testar os apps.

**Fontes:**
[Best English Learning Apps 2026](https://learnenglish.life/guides/best-english-learning-apps-2026/) ·
[Duolingo alternatives 2026 (Stimuler)](https://stimuler.tech/blog/7-best-duolingo-alternatives-for-english-fluency-2026) ·
[Duolingo Max](https://blog.duolingo.com/duolingo-max) ·
[Duolingo Roleplay explained](https://duolingoguides.com/duolingo-roleplay-explained/) ·
[Sequência do Duolingo](https://blog.duolingo.com/how-duolingo-streak-builds-habit) ·
[Streak 101 (Speak)](https://help.speak.com/en/articles/11645358-streak-101-how-streaks-work-how-to-keep-them) ·
[Crítica à sequência (Android Authority)](https://www.androidauthority.com/reasons-give-up-duolingo-streak-3543009) ·
[Apps de conversa por IA](https://www.getpronounce.com/blog/speaking-with-ai-best-apps-for-english-speaking-practice) ·
[ELSA Speak (App Store)](https://apps.apple.com/us/app/-/id1083804886) ·
[Duolingo alternatives (Clozemaster)](https://www.clozemaster.com/blog/?p=7766) ·
[Comprehensible input apps 2026](https://comprehensibleinput.it.com/blog/best-comprehensible-input-apps-2026) ·
[Language Reactor / ReadLang](https://apps.apple.com/app/id6740740246) ·
[Revisão sobre shadowing (Oxford)](https://ora.ox.ac.uk/ark:/29072/ora_3104cae13a6b400ab173de44384238d2) ·
[Tese Anki × grupo de controle (Lund)](https://www.sol.lu.se/media/kalender/2025-05/Emin%20Youssef%20Gaaya_MA%20Thesis.pdf)
