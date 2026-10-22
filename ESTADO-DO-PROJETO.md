# Paclingo (ex-PAC·DART) — Estado do Projeto (handoff)

> **Nome novo (11/out/2026): Paclingo.** Os três cursos seguem com os nomes de trabalho usados neste documento (PAC·DART,
> PAC·C#, PAC·ENGLISH), mas na tela aparecem como Paclingo · Dart & Flutter / C# & .NET / Inglês. Ver a seção "📲 Lojas".

> Treinador de digitação que ensina **Dart & Flutter**: você digita código real,
> um Pac-Man "come" as letras, e ao concluir o trecho ele "compila" — mostrando a
> saída no console e, nos exercícios Flutter, uma **prévia do widget renderizado**.
> Feito em **Flutter (web)** com **flutter_bloc**. Tudo em português do Brasil.

Última atualização: out/2026 (renome para Paclingo + projetos Android/iOS gerados).

---

## 🗺️ Planejamento das próximas fases (12/out/2026)

Pesquisa de apps de inglês + lista do que acrescentar, em ordem de execução: `planejamento/MELHORIAS-PESQUISA.md`. A **Fase 1 (hábito diário:
sequência, meta do dia, congelamento; lembrete como 1B)** tem plano detalhado em `planejamento/FASE-1-HABITO-DIARIO.md` e o prompt para um
agente sem contexto em `planejamento/PROMPT-AGENTE-FASE-1.md`. **A Fase 1A (sequência, meta, congelamento, telas) está implementada** — ver "🔥 Hábito diário"
abaixo; a **1B (lembrete diário no celular) está implementada** (13/out/2026, autorizada pelo dono) — plano em `planejamento/FASE-1B-LEMBRETE.md`, seção "🔔 Lembrete diário" abaixo; falta só a prova num aparelho físico.
A **Fase 2 está implementada** (2A "💡 Por quê?" e 2B "💬 Cenários guiados"); o plano está em `planejamento/FASE-2-EXPLIQUE-E-CENARIOS.md` (prompt: `PROMPT-AGENTE-FASE-2.md`); a Fase 3 tem o ditado e o shadowing feitos (plano do shadowing: `planejamento/FASE-3B-SHADOWING.md`).
A **Fase 7 (modos de resposta nas lições do Inglês — barra ⌨️ Digitar · 🎤 Falar · 🧩 Montar)** está **implementada** (13/out/2026, a pedido do dono: "não encontrei no celular a opção de digitar… quero mic, digitar e o de montar igual ao Duolingo"); plano em `planejamento/FASE-7-MODOS-DE-RESPOSTA.md`, seção "🧩 Modos de resposta" abaixo (decisões do dono: montar vale tudo mas conta meio ponto na prova; padrão Digitar; enfeites de 2 a 5).
A **Fase 5 (escrita corrigida por IA, erros viram cartões) está implementada** — plano em `planejamento/FASE-5-ESCRITA-CORRIGIDA.md`, seção "📝 Escrita corrigida" abaixo.
A **Fase 8 ("🎧 Ouvir": escutar as lições na ordem e setlists pessoais, com mini-player) está em implementação** (20/out/2026, a pedido do dono) — plano em `planejamento/FASE-8-OUVIR-PLAYLIST.md`, seção "🎧 Ouvir — Fase 8" abaixo.
A **Fase 9 ("⚡ Treino do dia": uma sessão de ~10 min montada com o que o aluno já tem, nos 3 cursos) está implementada e validada pelo líder** (21/out/2026; sem commit/deploy) — plano em `planejamento/FASE-9-TREINO-DO-DIA.md`, seções "⚡ Treino do dia — Fase 9" e "⚡ 21/out/2026 (rodada 7): Treino do dia" abaixo.
A **Fase 10 ("💬 Conversa com IA": role-play em inglês com os personagens do palco, o Prof. Dash corrigindo cada fala na hora, digitando ou pelo microfone, resumo local no fim) está feita e validada pelo líder** (21/out/2026, rodada 8; sem commit/deploy; evolui a 2B "💬 Cenários guiados") — plano em `planejamento/FASE-10-CONVERSA-IA.md` (escrito como FASE-9; renumerado porque o Treino do dia ficou com a 9), seção "💬 Conversa com IA — Fase 10" abaixo.
A **Fase 11 (💬 Conversa pelo Claude Haiku via Worker da Cloudflare — DESLIGADA por padrão, liga pelo `config/tutor` — + modo 🙌 mãos-livres na Conversa)** está implementada (21/out/2026, rodada 9; sem commit/deploy; Worker ainda não publicado) — plano em `planejamento/FASE-11-CLAUDE-MAOS-LIVRES.md`, seção "🙌 21/out/2026 (rodada 9)" no fim.

---

## 🔗 Links e acesso

- **App no ar:** https://pac-dart.web.app  *(sempre dar hard refresh: `Ctrl/Cmd + Shift + R`)*
- **GitHub:** https://github.com/carlosdesenvolvedor/pac_dart  ✅ **sincronizado (main)** — todo o código está pushado (commit `b364070`, jul/2026).
- **Firebase project:** `pac-dart` (Firestore em São Paulo / southamerica-east1)
- **Pasta local:** `/Users/fazplay/pac_dart`

---

## ▶️ Rodar, testar, publicar

```bash
# desenvolver
flutter run -d chrome

# testar (97 testes) e analisar
flutter test
flutter analyze

# publicar (deploy)
flutter build web
firebase deploy --only hosting --project=pac-dart
```

⚠️ **Se mexeu em pacotes/plugins (pubspec): rode `flutter clean && flutter pub get` ANTES do build.**
Senão o registrant do Firebase web fica stale → `PlatformException(channel-error … initializeCore)` → **tela branca no boot**.

Depois de todo deploy, avise o usuário para **hard refresh** (o service worker do Flutter cacheia o `main.dart.js`).

---

## 📦 Conteúdo (números)

- **32 trilhas**, **336 lições**, **2354 exercícios de digitação**, **todas as lições com teoria** (com bloco de código).
- Trilhas base (1–8): 🌱 Fundamentos · 🔀 Lógica · 📦 Coleções · 🧱 Objetos · ⏳ Avançado · 💙 Flutter · 🧩 Desafios · 🧰 Pacotes.
- **Trilhas avançadas (9–32, adicionadas jul/2026, sempre no FIM p/ não quebrar progresso):** 🧩 Dart Moderno · ⚡ Assíncrono · 🧪 Testes · 🧭 Navegação · ✨ Animações · 📐 Layout Pro · 🌐 Rede e APIs · 💾 Persistência · 🏛️ Arquitetura · 🔌 Pacotes II · ⌨️ Dart Idiomático · 📚 Coleções Pro · 📝 Formulários e Gestos · 🧠 Estado Avançado · 🎨 UI e Material 3 · 🍎 Cupertino iOS · 🔥 Firebase · ⚠️ Erros e Exceções · 📅 Datas e Texto · ♻️ Ciclo de Vida · 🚀 Debug e Performance · 🎛️ Widgets Avançados · 🌍 i18n e Acessibilidade · 🔗 Plataforma Nativa.
- Cada trilha Dart teve um **programa-demo rodado com `dart run` (exit 0)**; cada trilha Flutter teve um **arquivo compilável checado no `dart analyze`**. Varredura confirma **0 caracteres não-digitáveis** em `cod`.
- **61 projetos "Mão na Massa"** — os 21 originais + 40 novos: **30 apps Flutter** de prévia ao vivo (5 cada em Layout Pro, Animações, UI e Material 3, Formulários e Gestos, Navegação, Estado Avançado), todos com **render "full" validado** via `test/tools/preview_check.dart`; + **10 programas Dart console** (rodados com `dart run`, exit 0) distribuídos em Dart Moderno, Assíncrono, Coleções Pro, Datas e Texto, Erros e Exceções, Arquitetura, Dart Idiomático.
- **30 apps Flutter no "Teste Master"** (`assets/master.json`), ordenados do simples ao avançado, todos com **prévia ao vivo**.
- Trilha **Pacotes**: 16 pacotes mais usados (provider, flutter_bloc, flutter_riverpod, get_it, http, dio, shared_preferences, sqflite, go_router, google_fonts, cached_network_image, flutter_svg, intl, url_launcher, image_picker, connectivity_plus).

**Dados:** `assets/curriculo.json` (trilhas → lições → trechos + `resumo` + `teoria`), `assets/master.json` (30 apps), `assets/roda.json` (quem roda no DartPad — gerado, ver abaixo), `assets/backgrounds/*.jpg` (fundo por trilha).

---

## 🟣 PAC·C# — a vertente C# (set/2026, EM ANDAMENTO)

Pedido do usuário (27/set/2026): escolher a linguagem no início (Dart ou C#); currículo C# com **pelo menos o
dobro** dos exercícios do Dart (≥ 4.708), progressivo **Iniciante → Intermediário → Avançado → Sênior**
(com arquitetura: SOLID, padrões, Clean Architecture, DDD, CQRS, microsserviços), baseado na doc oficial +
pesquisa de bons treinos; **desafios de lógica que não são de digitação** (só com o que já foi estudado) e
**desafios/trilhas de jogos** (C# puro, Unity 6, Godot 4, MonoGame). Autorizou ultracode (workflows).

**No app (feito):**
- `lib/core/linguagem/linguagem.dart` (enum `Linguagem.dart/.csharp`: marca, assets, prefixo de progresso;
  `Linguagem.atual` estático como `Mixart.atual`) + `linguagem_cubit.dart` (pref `linguagem`, por dispositivo).
- `EscolhaLinguagemPage` ("Escolha sua trilha", teclas 1/2) aparece quando não há escolha salva e quando se
  toca em "DART & FLUTTER ⇄" / "C# & .NET ⇄" no HUD. `PacDartApp(linguagemInicial:, curriculoBuilder:)` para testes.
- Progresso do C# no MESMO doc `users/{uid}` com prefixo **`cs_`** (`cs_concluidas`, `cs_quizNotas`,
  `cs_projetos`, `cs_trilha`, `cs_licao`, `cs_recorde`); o Dart segue sem prefixo (progresso antigo intacto).
  Regras do Firestore não mudaram (valem por documento).
- Modelo: `Trilha.etapa/fundo/perfil/desafios`, `Trecho.linguagem` e `BlocoTeoria.linguagem` (campo `l` no
  JSON: bash/json/xml/sql… = texto que não é C#), `DesafioLogica` (saida · valor · lacuna · ordenar · bug ·
  escolha). `DesafiosPage`: fila do fácil ao difícil, teclas 1-4/A-D e Enter, gabarito + explicação; acerto novo
  vira `desafio:t:i` em `projetosFeitos` e 15 pts no ranking (`RankingCubit.desafiosResolvidos`). Correção pura
  em `domain/conferir_desafio.dart` (número com vírgula ou ponto, True/true, texto com/sem aspas).
- Mapa: faixas de etapa (🌱/🚀/⚙️/🏛️), rodapé "🧠 Desafios de lógica" por trilha; fluxo pós-lição emenda os
  desafios pendentes depois dos projetos.
- **Teste Master do C#** (`assets/csharp/master.json`): 30 sistemas de console (2.054 linhas), do "Caixa da Padaria" à
  "Saga de Pagamento" (lotes: 1-10 iniciante→intermediário, 11-20 POO/LINQ/async/JSON, 21-30 arquitetura: State,
  Specification, DDD, middlewares, token bucket, motor de jogo, CQRS+outbox, saga) — todos compilados e executados no lab,
  `out` = saída real. Gerados/revisados pelo workflow `teste-master-csharp` (3 autores + 3 revisores adversariais).
- **Currículo C#**: esboço de **50 trilhas / 615 lições** (8 Iniciante · 13 Intermediário · 15 Avançado · 14 Sênior) em
  `…/scratchpad/csharp/esboco_final.json` (cópia em `tools/csharp_lab/esboco.json`), gerado por pesquisa multiagente
  (docs oficiais, roadmap.sh, arquitetura, Exercism/treinos, jogos, sênior). Geração em 3 lotes (A 1-16, B 17-33,
  C 34-50) pelo workflow `tools/csharp_lab/workflow_gerar_trilhas.js`: autor → desafios → revisor adversarial, cada
  trilha só vale com "RESULTADO: OK" nos dois validadores.
- Destaque de sintaxe C# (`tokenizer.dart`, `tokenizar(cod, linguagem:, variante:)`), `CodigoColorido`,
  botão **copiar** monta o Program.cs com `lib/core/util/programa_csharp.dart` — **mesma regra** do `Montador.cs`
  do laboratório (usings no topo, comandos na ordem, tipos no fim, `namespace X;` vira bloco). Mudou num, mude no outro.
- Botão **rodar** no C#: abre o programa no **SharpLab** (sharplab.io) numa aba nova, já no modo Run
  (`lib/core/util/sharplab.dart`: URL `#v2:` + `LZString.compressToBase64("t:run|código")` — LZString portado 1:1 e
  conferido contra o JS; `@` vira `@@`). O SharpLab não tem ImplicitUsings nem pt-BR: `programaCSharp(..., paraSharpLab: true)`
  põe os 7 usings implícitos no topo e `CultureInfo.CurrentCulture = new("pt-BR")` antes dos comandos (testado no navegador:
  sai "R$ 12,50" como no console do app). Só aparece em perfil console, sem NuGet de fora e sem ReadLine (`rodaNoSharpLab`).
- A escolha de linguagem é **por conta** (`linguagem_<uid>` nas prefs — navegador compartilhado não vaza a escolha); o "⇄" do
  HUD abre a escolha como ROTA com "voltar" e escolher a mesma linguagem não derruba a sessão (revisão multiagente, 14 achados
  confirmados e corrigidos em 27/set).
- Tutor (Prof. Dash) com persona C# (`GeminiTutorService.persona(Linguagem)`), Arcade no modo C#: palavras C#
  (`palavras_csharp.dart`), dicas C#, Corrida/Gol/Caça-Bug usam os desafios do currículo C#
  (`domain/banco_curriculo.dart` + `presentation/banco_arcade.dart`); Lógica Animada segue em Dart.

**Laboratório (a garantia de qualidade):** projeto .NET 10 com Roslyn 5.9 — `Lab trilha arq.json --fix`
compila cada lição inteira E cada prefixo (o "copiar" de qualquer trecho compila), trata aviso como erro
(menos "não usado"), roda a lição com cultura **pt-BR** e **preenche o `out` com a saída real** (detecta saída
não determinística rodando 2×); valida teoria (todo bloco `code` compila sozinho, salvo `// não compila`) e
projetos. `Lab desafios arq.json --fix` executa cada desafio e corrige o gabarito; lacuna/ordenar checam
ambiguidade. Perfis: console · web · testes · biblioteca · unity (stub próprio do UnityEngine 6, C# 9;
`velocity`/`FindObjectOfType` obsoletos) · godot (GodotSharp + Godot.SourceGenerators) · monogame.
Guias dos agentes geradores: `GUIA-GERADOR.md` e `GUIA-DESAFIOS.md`. Integração: `integrar.py`.
Cópia durável em **`tools/csharp_lab/`** (fonte do lab + stub Unity + guias + `integrar.py` + `paridade/` +
`workflow_gerar_trilhas.js`, o roteiro do workflow que gera as trilhas). Paridade app↔lab:
`Lab montar-lote arq.json lab.json` + `dart run tools/csharp_lab/paridade/bin/paridade.dart arq.json lab.json`
(fora do projeto: copie a pasta; 20/20 casos difíceis idênticos, inclusive identificadores acentuados).

---

## 🗽 PAC·ENGLISH — o curso de inglês (out/2026, COMPLETO: A1→C1 + dev)

Pedido do usuário (4/out/2026): "terceiro curso, de inglês — frases em inglês para eu escrever com a tradução em
cima, escrever várias vezes para decorar o contexto, de forma progressiva; sempre escrevo em inglês". Ultracode
autorizado (pesquisa + criação).

**Pesquisa (workflow `pesquisa-curso-ingles`, 7 dossiês + arquiteto + 3 críticos + revisor):** em
`<scratchpad da sessão 8078ca22…>/ingles/` — `pesquisa/01-memoria.md` (ciência da memorização digitando),
`02-progressao.md` (CEFR A1→C1), `03-vocabulario.md`, `04-brasileiros.md` (interferências + regras de tradução),
`05-produtos.md` (benchmark de UX), `06-audio-teclado.md` (Web Speech + ABNT2/US-Intl), `07-fontes.md` (Tatoeba e
naturalidade; `pesquisa/fontes07/tatoeba_candidatas_en_ptbr.tsv` = 85 mil pares EN↔PT-BR filtrados),
`DESIGN.md` (método) e `esboco.json` (117 trilhas / 559 lições: a1 28 · a2 23 · b1 21 · b2 20 · c1 14 · dev 11).

**Método (com evidência — não é "copiar 5× seguidas", que é a pior retenção):** cada frase é digitada **5 vezes
intercalada** com as outras, com apoio que some: D1 cópia com áudio antes → D2 só as iniciais → D3 só o esqueleto
(tracinhos) → D4 escondida (só a tradução) → D5 prova na rodada final embaralhada (lags 3/5/7/8 digitações).
Digitação de memória: pontuação preenchida sozinha e 1ª maiúscula livre (apóstrofo, I, dias e nomes exigidos), nota
POR PALAVRA (≤1 tecla errada por palavra > 3 letras), Tab = 1 letra, Tab Tab = palavra, Esc = "não sei", errar 2× a
mesma letra a revela. Errou → frase completa com as palavras erradas sublinhadas + áudio + **cópia de correção** e a
frase desce um degrau. Teto 8 digitações/frase/dia. Revisão espaçada ~~Leitner 1·3·7·16·35·80·180 dias~~ **(desde 12/out/2026 é o FSRS — "Anki no app", seção abaixo)** na "Revisão do dia" (HUD "Revisão · N" e aviso no começo da lição).
Teste de nivelamento por trilha no mapa ("Já sei esta trilha": 10 frases de memória, 8 limpas = trilha concluída e
frases na caixa 3). Treino de memória por lição no mapa (nota = melhor).
Pedido do dono (6/out): a voz é **devagar por padrão** (caixinha "voz devagar", pref `en_voz_lenta`; Enter ouve na
velocidade padrão, Shift+Enter na outra); terminada a frase a voz a **repete e ela fica na tela até o Enter** (nada de
avançar sozinho — palco e Revisão/Treino; "Enter segue →" também é tocável); o **👁 é uma chave** (pref
`en_ver_frases`): ligado, o inglês fica à vista em todas as frases — sobe a escada como cópia, sem correção, e a prova
vale meio ponto (`FilaLicao.registrar(vista:)`). Esc continua sendo o "não sei" só da frase atual.

**Ensaio mental (8/out, "âncora" da PNL, opcional):** `widgets/ensaio_mental.dart`, num OverlayPortal do palco (sem
LayoutBuilder dentro dele — dispara "mutated in performLayout" quando a HomePage move o conteúdo pela GlobalKey; usar
MediaQuery). Antes da lição: respiração 4/4 s + "junte o polegar e o indicador" + `Som.ancora` (sino) → foto da cena em
tela cheia com a `visualizacao` → "Daqui a pouco, nessa cena, você vai dizer:" (TODAS as frases da lição desde 19/out —
antes eram até 3 com alvo; PT depois EN com voz; o tempo de cada uma acompanha o fim da fala; na tela só a da vez grande
+ as 2 anteriores pequenas e "frase N de M"; o fim lista todas em 2 colunas no desktop; ~1 min com 10 frases)
**Pronúncia da palavra (19/out):** o balão do toque na palavra (`traducao_palavra.dart`) tem 🔊 normal e 🐢 devagar só
da palavra (`FraseView.onOuvirPalavra` → `VozIngles.falar(palavra)`, voz sintética: as gravações são por frase); ao
tocar ela já soa na velocidade padrão se o "áudio automático" estiver ligado (`falarPalavraAoTocar`). Palco e revisão.
**Personagens que falam (19/out, lip sync estilo Duolingo, feito do zero):** `widgets/elenco_ingles.dart` desenha o
elenco em CustomPainter (chibi: cabeça grande, olhos com brilho, bochechas; nada de imagem): Mike, Sarah, Ana, Ben, Emma,
Lucas, Julia, Dra. Lee, **Você** (o aluno, de fone) e dois genéricos (`ela`/`ele`, papéis por gênero como na voz). Cada
um tem as 9 bocas do Rhubarb (`domain/boca.dart`: `Visema` X/A–H, `TrilhaBoca`) e pisca sozinho. `PersonagemFalante`
ouve `VozIngles.falando` (`FalaEmCurso`: frase, trilha, início, velocidade) e só anima enquanto a fala é dele (ou uma
palavra dela). A trilha vem de `assets/ingles/bocas.json` ({asset mp3: "0X 9B 15E…", centésimos + visema}), gerado
OFFLINE pelo **Rhubarb Lip Sync 1.14 (MIT)** com o texto da frase (`--dialogFile`):
`python3 -I tools/ingles/bocas_rhubarb.py` (binário em `~/development/rhubarb/`, ffmpeg; incremental; ~4 s/frase/núcleo,
6 processos ≈ 1h30 para as 5.538). No web a boca segue o `currentTime` do `<audio>` (`fala.posicaoGravacao`); sem
bocas (voz sintética, áudio do aluno) ela é estimada pelo texto (`TrilhaBoca.doTexto`). Aparece num círculo creme à
esquerda da tradução (`TraducaoCard.rosto`), no palco e na revisão. Rodar o bocas_rhubarb.py DEPOIS do vozes_google.py. → espera o Enter. Esc pula; "não mostrar mais" = pref `en_ensaio`
(padrão ligado), link "🎬 rever o ensaio mental" no começo da lição. Sem gesto na página (autoplay) abre parado em
"▶ Começar o ensaio". Na vitória, se o ensaio chegou ao sino: `Som.ancora` + linha da âncora (VictoryOverlay ganhou
`extra`). Respeita "áudio automático".

**Voz nativa (8/out):** 410 frases (A1 157 · A2 140 · B1 62 · B2 37 · C1 14 · DEV 0) tocam a gravação de nativo do
Tatoeba (409 de CK, CC BY-NC-ND 3.0; 1 de Susan1430, CC BY-NC 4.0 — o curso é gratuito). Casamento por PALAVRAS iguais
(pergunta só com pergunta), frases da ficha fora, só licença declarada. mp3 sem alteração em
`assets/ingles/audio/<sentence_id>-<audio_id>.mp3` (7 MB); `tools/ingles/audio_nativo.py --cache <pasta fora do projeto>`
(baixa exports, casa, baixa, escreve `tools/ingles/dados/audio_nativo.json`) ANTES do `integrar.py` (campos `au`,
`au_cred` no trecho). App: `data/audio_nativo.dart` (registro cod → mp3, preenchido no CurriculoLoader); `VozIngles.falar`
toca o mp3 (lenta = playbackRate .8) e cai na sintética se falhar; completa no fim da fala. Crédito "🎙️ voz nativa" no
TraducaoCard e parágrafo em "Créditos e fontes".

**Voz gerada por personagem (8/out):** todas as outras frases (4.796) e os exemplos da teoria têm voz do Google Cloud
TTS (Chirp 3 HD, en-US), sempre a mesma voz por personagem: você = Orus, Mike = Puck, Ana = Kore, Sarah = Aoede,
Ben = Fenrir, Emma = Leda, Julia = Zephyr, Lucas = Iapetus, Dra. Lee = Sulafat, narrador/teoria = Charon; papéis menores
por gênero (mapa em `tools/ingles/dados/vozes_google.json`). 5.029 mp3 (55,6 MB) em `assets/ingles/voz/<hash>.mp3` +
índice `assets/ingles/vozes.json` {texto: asset}. Gerar/atualizar DEPOIS do integrar.py:
`python3 -I tools/ingles/vozes_google.py --gcp music-system-421ee` (API Text-to-Speech ativa nesse projeto, que tem
faturamento; ~3 arquivos/s; só gera o que falta e apaga órfãos). Ordem no app (`AudioNativo.paraTocar`): gravação de
nativo > voz gerada > voz sintética do navegador.

**No app:**
- `Linguagem.ingles` (marca ENGLISH, `assets/ingles/`, prefixo `en_`, `ehProgramacao=false`), 3º cartão na escolha
  (tecla 3). `CursoState.ehIngles`; HomePage troca o palco por `PalcoIngles` (o conteúdo tem GlobalKey: cruzar 1240
  px não recria a fila). Eventos novos no CursoBloc: `LicaoFinalizada`, `TrechoMostrado` (tutor vê a frase da vez),
  `TrilhaTestada`.
- `lib/features/ingles/`: `domain/roteiro.dart` (`FilaLicao` determinística — o começo reproduz a simulação do
  dossiê; `ModoFrase`, `mascaraDaFrase`), `domain/avaliacao.dart` (nota por palavra), `domain/revisao.dart`
  (chave = hash do texto em inglês; o Leitner virou só o formato ANTIGO lido na migração — agora é `domain/srs.dart`, FSRS), `domain/fonte_frase.dart` (atribuição Tatoeba), `data/voz_ingles.dart`
  + `fala_web.dart` (Web Speech DIRETO: espera `voiceschanged`, `lang=en-US` sempre, ranking de vozes Edge Natural >
  Google > Apple; o flutter_tts deixava a 1ª frase sair em voz portuguesa), `data/revisao_repository.dart` (mapa
  cartões em blocos `users/{uid}/srs/b00…b15` + histórico `srs_log` — o mapa `en_revisao` ficou só como legado), `presentation/palco_ingles.dart`,
  `sessao_memoria_page.dart` (Revisão do dia / Treino / Teste, com reaprendizagem sucessiva), `fixacao.dart`,
  `widgets/frase_view.dart`, `widgets/traducao_card.dart` (PT grande, "ao pé da letra", nota, 🔊 🐢 💡 👁, fonte).
- Frase = `Trecho(cod: en, dica: pt, lit, conceito: nota, alvo, src)`; teoria ganhou bloco `ex` ("inglês\ntradução"
  com 🔊). `TypingBloc`: `TrechoCarregado(cod, tolerante:)`, `errosPorPosicao`, aceita ´/` como apóstrofo, NBSP,
  …, invisíveis, espaço repetido e o desdobramento US-International (`'`+`c` = `ç` vale por `'c` — também ajuda as
  strings do Dart/C#).
- Arcade no inglês: só Turismo/Chuva/Rali com `palavras_ingles.dart` (+ `dicasIngles`); Prof. Dash vira professor
  de inglês (`_personaIngles`, sugestões próprias); mapa com faixas A1…C1, "Créditos e fontes" (Tatoeba CC BY 2.0 FR).
- 🎬 Ensaio mental (`widgets/ensaio_mental.dart`) e voz nativa (8/out, correções): cada frase do ensaio do futuro
  fica o tempo de ser dita inteira (`EnsaioMental.segDaFrase`, por palavras e velocidade) e o relógio ainda espera a
  fala acabar (`VozIngles.falar` só completa no fim) — uma frase não corta a outra; respeita "áudio automático";
  sem gesto na página (app recém-aberto) espera parado no "▶ Começar o ensaio" (`Sons.liberado` =
  `navigator.userActivation`; o `som_web` também não agenda nota antes do 1º gesto). A âncora da vitória (sino +
  "👌 Junte o polegar…", agora DENTRO do VictoryOverlay via `extra`) só aparece se o ensaio desta lição chegou ao
  sino; ao repetir, sem "novas". Gravações do Tatoeba: `assets/ingles/audio/<sentence_id>-<audio_id>.mp3` (o nome
  prova qual gravação é; `audio_nativo.py --sem-baixar` nunca grava crédito de mp3 que não está na pasta).
- Testes: `test/ingles_dominio_test.dart` (fila, máscara, nota, chaves) e `test/ingles_ui_test.dart` (escolha,
  lição inteira, correção, Revisão, redimensionar, nivelamento). ⚠️ App montado dentro de `tester.runAsync`: os
  listeners dos blocs só andam com tempo REAL entre os pumps; páginas abertas por toque nascem na zona falsa.

**Conteúdo:** gerado por workflow (autor → revisor nativo EN → revisor PT/progressão, cada trilha só vale com o
validador OK). Ferramentas em `tools/ingles/`: `validar.js` (só ASCII digitável, pontuação final, tamanho por
nível, alvo ⊂ frase, fonte Tatoeba) e `integrar.py` (trilhas → `assets/ingles/curriculo.json`, `src` da atribuição).
Dados duráveis em `tools/ingles/dados/` (esboço final 120 trilhas / 595 lições, DESIGN.md, IMAGENS.md, pacotes.json,
trilhas prontas); roteiro para continuar em `tools/ingles/PROMPT-CONTINUAR.md`.

**CURSO COMPLETO no ar (6/out/2026):** **121 trilhas · 602 lições · 5.308 frases** (1.072 do Tatoeba) — A1 28 ·
A2 23 · B1 22 · B2 22 · C1 14 · DEV 11. Toda trilha passou por autor + revisor nativo EN + revisor PT/progressão e
pelo validador. Integração: `integrar.py tools/ingles/dados/trilhas tools/ingles/dados/esboco.json --etapas
a1,a2,b1,b2,c1,dev`. `test/ingles_*_test.dart` 28/28 verdes.
8/out: lições de LISTA fechada auditadas (o validador não pega): 0–12, 13–19, dezenas, jan–jun, jul–dez agora cobrem
todos os itens (nFrases 10 no esboço) e a "carro vermelho" ganhou o red. Ao mexer numa lição de lista, conferir a
cobertura item a item.
9/out: trilha EXTRA a pedido do dono, `conjugar-s-es-ies` (A1, ordem 12.5 = 13ª, logo depois de terceira-pessoa):
7 lições / 88 frases de treino da 3ª pessoa (+s; -es em s/ss/sh/ch/x/z/o; consoante+y → -ies; vogal+y → -s; has),
escrita à mão + revisor independente; esboço ganhou a trilha (ordem fracionária é aceita pelo integrar.py).

**📱 Celular + áudio (11/out/2026, SÓ Android/iOS — o desktop não muda):** pedido do dono: "mandar áudio" no inglês e o
teclado do celular funcionando perfeitamente. Testado no Chromium emulado como Pixel (UA/touch por CDP), NÃO em aparelho real.
- **Bugs reais achados na emulação** (antes de mexer): (1) o Gboard mantém a palavra em *composição* até o espaço e o campo só
  lia texto com a composição fechada → o Pac-Man andava palavra a palavra, erro só no espaço; (2) com o teclado aberto a frase
  ficava escondida embaixo dele; (3) o selo "✓ Feita… Enter segue →" quebrava em 2 linhas e atropelava a barra da lição.
- **`widgets/leitor_teclado.dart`** (`LeitorTeclado`): lê a composição ao vivo pela diferença para o que já foi lido (o que o
  teclado apaga/reescreve não vira tecla). Só esperam o fim da composição a tecla morta sozinha (´ ~ ^ ` ' ") e o ditado em
  andamento (várias palavras). No celular, texto com espaço que chega de uma vez (o 🎤 do Gboard/iOS, colar) = **resposta falada**,
  não cem teclas (senão a 1ª palavra errada virava cascata de erros). `esquecer()` na troca de frase não mexe no DOM do campo.
- **🎤 "Falar a frase"** (botão de 48 px no canto do FraseView; Revisão/Treino também): `data/reconhecedor_fala.dart` (+ `_web`
  com `SpeechRecognition`/`webkit…`, en-US, `interimResults`, 5 hipóteses, guarda de 25 s; `_stub` na VM). ⚠️ Chromium novo tem o
  nome SEM prefixo: o código prefere `SpeechRecognition`, então fakes de teste precisam trocar os DOIS nomes. Erros viram recado
  em português (microfone bloqueado, sem rede, não ouviu, navegador sem suporte → manda usar o 🎤 do teclado). A voz do app cala
  ao abrir o microfone (`onMicrofone`).
- **`domain/avaliacao_fala.dart`** (`avaliarFala`): confere por PALAVRA (alinhamento DP) — ignora caixa/pontuação, aceita
  contração↔forma plena (I'm = I am, can't = can not), homófonos (to/too/two), número por extenso (7:30 = seven thirty, 25 =
  twenty five), ±1 letra em palavra de 5+ letras, palavra a mais não reprova, melhor das hipóteses vence, `alt:` do autor vale.
  Tudo certo → `TrechoFalado` no TypingBloc (frase vale como digitada, erros por tecla de antes somem); senão mostra "Ouvi: …"
  (palavra errada riscada) e cada palavra errada vira erro na 1ª letra (`somarErros` → `avaliarDigitacao`); errada 2× = revelada.
  Falar completa a frase em qualquer degrau (cópia ou memória) e conta na nota como digitação limpa — decisão a revisar se a
  grafia importar mais que a produção.
- **Mais do celular:** `onEditingComplete` (o "ok" do teclado virtual não fecha o teclado e não duplica com a tecla Enter,
  janela de 300 ms); toque na frase reabre o teclado (`TextInput.show`); `zona_visivel.dart` rola a zona de digitação
  (tradução + frase + selo + barra) para ficar acima do teclado — o Scaffold CONSOME os `viewInsets`, então o aviso vem de
  `WidgetsBindingObserver.didChangeMetrics` (`VigiaDoTeclado`), não do MediaQuery do body; com o teclado aberto o cartão da
  tradução encolhe (`TraducaoCard(compacto:)`); botão "Seguir →" no lugar de "Enter segue →"; "não sei" na tela (não há Esc);
  rodapé da HomePage sem Enter/Tab/Esc.
- **Testes:** `test/ingles_fala_test.dart` (44: avaliação, `LeitorTeclado`, FraseView com composição estilo Gboard, ditado,
  microfone falso, Enter) + grupo "no celular (Android)" no `ingles_ui_test.dart` (o resto dele agora roda como macOS via
  `testWidgetsDesktop`; o padrão do flutter_test é Android). ⚠️ Plataforma em teste só por `variant:
  TargetPlatformVariant.only(...)` — `debugDefaultTargetPlatformOverride` em setUp/tearDown reprova o teste.
  `csharp_curriculo_test` falha por conteúdo (C# em 4.147 de 4.708), não por isto.
- **Receita da prova no navegador** (sem celular): `flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_voz`,
  `python3 -m http.server`, MCP do Playwright em `browser_run_code_unsafe`: `context.newCDPSession` →
  `Emulation.setUserAgentOverride` (UA Android + `platform: 'Linux armv81'`), `setDeviceMetricsOverride {mobile:true}`,
  `setTouchEmulationEnabled`; composição do Gboard = `Input.imeSetComposition` (uma por letra) e commit = `Input.insertText`;
  teclado aberto = `Object.defineProperty(visualViewport,'height',…)` + evento `resize` (o engine calcula `viewInsets`);
  reconhecedor falso = `addInitScript` trocando `SpeechRecognition` E `webkitSpeechRecognition`. Desregistre o service worker
  (`navigator.serviceWorker.getRegistrations`) a cada build, senão vem o JS velho.
- **Não coberto / a fazer:** aparelho real (Gboard, Samsung Keyboard, iOS Safari; PWA do iOS não tem reconhecimento de voz);
  `CodeView` e o quiz (Dart/C#) têm o MESMO campo que só lê a composição fechada — mesmo conserto (`LeitorTeclado`) se o dono
  quiser; Backspace no teclado virtual não anda para trás (letra errada nunca entra, então não faz falta).


**📝 Lição a partir de um texto (12/out/2026):** pedido do dono: "colo um texto em inglês e ele vira lição, com tradução
automática; a pronúncia pode ser a de antes, sem mudar para a nativa". Mapa do inglês → cartão "✍️ Transforme um texto em
lição" → colar (título opcional) → **Traduzir e revisar** (a tradução é editável, a lixeira tira frase) → **Criar**: cai direto
na 1ª lição. Nenhuma dependência nova (só `http`).
- **Domínio puro** `ingles/domain/texto_para_frases.dart`: `simplificarParaDigitar` (aspas curvas → retas, travessão → " - ",
  acento sai: café → cafe, emoji/link somem — o curso é todo ASCII digitável), `dividirEmFrases` (abreviações Mr./Dr./e.g./U.S.,
  iniciais, decimais, fala entre aspas, linha quebrada de PDF é juntada, marcador de lista sai, repetidas saem;
  **frase > 12 palavras** (`maxPalavrasDoTextoColado`, 13/out/2026 — pedido do dono: exercícios mais rápidos, MAS cada pedaço com
  sentido/contexto, não um caco de frase; antes o limite era 25) é cortada **nos trechos naturais**: depois de `,` `;` `:` ou
  " - ", ou antes de and/but/because/when/which/who/if/or/then/after/before/until/since/although/though/where. O melhor conjunto
  de cortes sai de uma **programação dinâmica** (`_quebrar`): pedaço ideal ≈ 7 palavras (custo ao quadrado), pedaço com < 5 palavras
  ("quite astonished,") custa muito e gruda no vizinho, corte antes de conjunção sem vírgula custa um pouco mais que corte
  na vírgula. Frase de até 12 fica inteira (mesmo com bom corte); sem corte natural bom ela fica inteira até 18 (1,5×); acima
  disso `_partirNoMeio` corta entre palavras. **Golden:** o texto "Jack Hannaford" do dono (14 linhas) sai IDÊNTICO ao "texto
  linha a linha" de um professor. A tela avisa "N frases compridas foram divididas em pedaços curtos…"
  (`TextoDividido.partidas`). Teto 150 frases — **textos grandes batem nele mais cedo agora que há mais pedaços**; o limite de
  25 do CURSO (`maxPalavrasPorFrase`) é outro e não mudou) e `repartirEmLicoes` (8 por lição, equilibrado:
  17 → 6+6+5). Só quebra frase quando a seguinte começa em MAIÚSCULA/número (texto todo em minúscula vira uma frase só).
- **Tradução** `ingles/data/tradutor.dart`: contrato `Tradutor` + `TradutorMyMemory` (api.mymemory.translated.net, grátis,
  sem chave, **CORS aberto — provado no Chrome**; 3 em paralelo, 1 nova tentativa, frase > 400 car. vai em pedaços). Limite do
  plano anônimo ≈ 5.000 caracteres/dia por IP: o aviso de cota ("MYMEMORY WARNING…", que vem como se fosse a tradução!) vira
  `TraducaoFalhou(cota: true)` com "volta em N h M min" e nunca é gravado como tradução; o que já foi traduzido fica em cache
  na instância e "Tentar de novo" continua de onde parou. Trocar de serviço (Gemini, DeepL…) = implementar `Tradutor`;
  `PacDartApp(tradutorBuilder:)` injeta um falso nos testes (o app provê via `RepositoryProvider<Tradutor>` só no inglês).
  O endpoint não oficial do Google Translate (`translate.googleapis.com/translate_a/single`, o do pacote `translator`) foi
  descartado: respondeu 429 no teste e não tem CORS garantido.
- **Modelo** `ingles/domain/texto_salvo.dart`: `TextoSalvo{id,titulo,criadoEm,frases[{en,pt}]}` → `comoTrilha()` (1 trilha por
  texto, lições "Parte N" com id `txt-<id>-N`, etapa "Meus textos", `Trilha.textoId` / `Trilha.propria`). Salvo local por conta em
  `ingles/data/textos_repository.dart` (`LocalTextosRepository`, prefs `en_textos_<uid>`; **não sincroniza entre aparelhos**).
- **Integração**: `CursoBloc(textos:)` anexa as trilhas próprias DEPOIS do curso (o mais novo primeiro) — índices do curso não
  mudam; eventos `TextoCriado` (salva, cria a trilha logo após o curso e seleciona a 1ª lição) e `TextoApagado`. As trilhas
  próprias aparecem no mapa no TOPO, sob a faixa "MEUS TEXTOS", com 🗑 e confirmação. **Ficam FORA** do curso: totais/% do mapa
  (`CursoState.progressoDoCurso`, estrelas), nivelamento (`etapasDoCurso`), "Já sei esta trilha" e **ranking** (HomePage não
  chama `licaoConcluida` — senão colar "aaa aaa" seria atalho de pontos). Entram na Revisão do dia, no Treino de memória e no
  ensaio mental (lição sem cena: 3 passos, "Daqui a pouco, você vai dizer:"). Ao terminar a última parte, "próxima lição" volta à
  1ª pendente do curso.
- **Voz**: a sintética do aparelho (Web Speech / TTS nativo) — texto próprio não tem mp3 de nativo nem Chirp, então
  `AudioNativo.paraTocar` não acha e `VozIngles.falar` cai na sintética (provado no Chrome: `speechSynthesis` en-US, rate .72,
  zero `<audio>`). Se a frase colada for IGUAL a uma do curso, toca a gravação dela (mesmas palavras).
- **Testes**: `test/ingles_texto_test.dart` (41: divisão, simplificação, tradutor com `MockClient` incl. cota/429/sem rede/cache,
  repositório, bloc, tela isolada) + grupo "lição feita de texto colado" no `ingles_ui_test.dart` (app inteiro: mapa → colar →
  traduzir → corrigir → criar → digitar a lição; ranking = 0 chamadas, com teste-controle do curso = 1; apagar com confirmação).
  Prova no Chrome (build do probe + Playwright): ⚠️ NÃO ligue a acessibilidade com clique sintético em `flt-semantics-placeholder`
  — o texto vai pro DOM mas o Flutter não o lê; dirija por coordenadas (`page.mouse.click`) + `keyboard.type/insertText`.
- **Não feito / ideias**: sincronizar os textos pelo Firestore (hoje só no aparelho); Gemini como tradutor (melhor qualidade, sem
  limite diário — a chave já vive em `config/tutor`; web usa REST e o celular `firebase_ai`); editar o inglês depois de criado;
  voz Chirp para textos próprios (pediria TTS em tempo real).


**🧠 Anki dentro do app — Fases 1 e 2 (12/out/2026, SÓ o inglês; Dart e C# NÃO ganham este motor, decisão do dono):**
pedido: "quero o anki dentro do app, somente para o inglês; subcoleção como recomendado". Plano em 6 fases (motor, armazenamento,
tela de baralhos, cartão virar-e-avaliar, importar/exportar TSV, calibrar parâmetros); **feitas a 1 e a 2, sem mudar a tela**.
- **Motor** `ingles/domain/srs.dart`: `AgendadorFsrs` (pacote `fsrs` ^2.0.1, FSRS-6, MIT, só depende de `meta`; web/Android/iOS) e
  `CartaoSrs{estabilidade, dificuldade, ultimoDia, proximoDia, revisoes, lapsos}`. Retenção 0,90, SEM etapas de aprendizado (a lição já
  repete a frase no mesmo dia), intervalo máx. 365, fuzz ligado (`fuzz:false` nos testes). **A 1ª revisão volta SEMPRE amanhã**;
  nivelamento ("testada") entra como "fácil" e volta em 7 dias. Ritmo medido a 90%: 1 → ~6 → ~21 → ~67 → ~194 dias com "bom"; errar um
  cartão maduro volta em ~5 dias. Frases a revisar vêm das de MENOR chance de lembrar (`devidas`, teto 80/dia = `Revisao.limiteDiario`).
  ⚠️ O pacote conta dias por diferença TRUNCADA de datas-hora (revisar "amanhã de manhã" de algo revisado "hoje à tarde" daria 0 dias =
  revisão do mesmo dia): por isso só recebe meia-noite UTC do dia local (`Revisao.dia`, inteiro desde 1970).
- **Nota**: `notaDoResultado` — limpa = bom (3), tropeço/dica = difícil (2), errada/"não sei" = errei (1); "fácil" (4) só existe se
  alguém medir velocidade/latência (`facil:`) ou no botão da Fase 4 (hoje não é gerado pela digitação). A prova de cada frase na lição
  (`FilaLicao.primeiraProva`) vira a nota do 1º cartão (`RevisaoCubit.aprender(notas:)`). Só a 1ª tentativa do dia conta (como antes).
- **Interface**: o plano falava em "duas implementações (Leitner e FSRS)"; NÃO fiz — manter um 2º motor só dobraria a manutenção. O
  agendador é injetável (`RevisaoCubit(agendador:)`) e o Leitner sobrevive só como leitor do formato antigo (`CartaoRevisao`) para a
  migração. Voltar ao antigo = voltar o código; o mapa `en_revisao` fica intacto no Firestore.
- **Armazenamento** `ingles/data/revisao_repository.dart`: `FirestoreRevisaoRepository` grava em **16 blocos** `users/{uid}/srs/b00…b15`
  (mapa `c` = chave→"f|próx|último|estab|dif|revisões|lapsos"; o bloco é função SÓ da chave: `idDoBloco`, NÃO mudar — mover cartões já
  gravados; web e celular dão o mesmo bloco, há teste com valores fixos rodando na VM e no Chrome) e histórico em `users/{uid}/srs_log/AAAA-MM`
  (array `r` de "dia|chave|nota", `arrayUnion`). Abrir o app = ~17 leituras; blocos ~45 KB com 12 mil cartões (o mapa único estouraria
  1 MiB). **Migração automática** do `en_revisao`: sem o doc `_meta`, converte (Leitner → estabilidade = intervalo da caixa, agenda mantida)
  e grava tudo num lote atômico junto do `_meta`; blocos criados offline antes da migração ganham do legado, nada se perde. O local
  (`LocalRevisaoRepository`: `en_srs`, `en_srs_log` com teto 5.000) lê o legado igual.
- **Regras** (`firestore.rules`): `match /users/{uid}/srs/{bloco}` e `/srs_log/{mes}` só para o dono — as regras de `users/{uid}` NÃO
  valem para subcoleções. **PUBLICAR AS REGRAS ANTES DO HOSTING** (`firebase deploy --only firestore:rules --project=pac-dart`): com o app
  novo e regras antigas a leitura é negada e a Revisão aparece vazia. As regras desta e de outras mudanças do working tree ainda NÃO foram
  publicadas. **Exclusão de conta** agora apaga também `srs` e `srs_log` (`apagarDadosDoUsuario`; apagar o doc pai não apaga subcoleção).
- **Testes**: `test/ingles_srs_test.dart` (41, rodam também com `flutter test --platform chrome`: agendador, codecs, migração, blocos,
  histórico, exclusão, escala de 12 mil cartões) e `test/firestore_rules_test.dart` (o `firestore.rules` REAL no fake; só VM; o fake não
  confere lotes nem listagens, e não entende `rules_version` nem `allow create, update, delete` — essas 2 linhas são trocadas no teste).
  Testes antigos de Leitner foram reescritos (`ingles_dominio_test`, `ingles_ui_test`: o UI semeia o formato ANTIGO e exercita a migração).

**🧠 Anki — Fases 3 a 5 + cartão frente/verso + áudio do aluno (12/out/2026, mesma sessão; NÃO commitado, NÃO publicado):**
O dono pediu (mesmo dia): "cartão com frente em inglês e verso traduzido, como no Anki" e "opção de adicionar áudio também"
(e, sobre onde guardar: "vai no recomendado; se eu não adicionar usa como está; se adicionar usa o que coloquei, no formato dele").
- **Mapa → "🧠 Baralhos e cartões"** (`presentation/baralhos_page.dart`; acima das trilhas do inglês): a revisar hoje (+ novos de
  inglês → português da cota do dia), revisados hoje/maduros/cartões, **previsão de 14 dias** (barras, hoje inclui atrasados),
  **retenção real** dos 30 dias (só revisões de cartões já aprendidos — a 1ª vez de cada cartão fica de fora, `EntradaHistorico.primeira`)
  + atividade dos 14 dias, baralhos por etapa ("Meus textos" primeiro; uma trilha = um baralho, id `tr:<slug>` / `txt:<id>` =
  `Trilha.baralhoId`), interruptor **inglês → português** por baralho e por grupo, "Estudar" por baralho, "Cartões" (navegador) e
  **ajustes** (revisões/dia 20–300, novos EN→PT/dia 0–40, retenção 85/90/95%; `domain/config_srs.dart`, em `users/{uid}.en_srs_cfg`
  ou prefs). Domínio dos baralhos/estatísticas em `domain/baralhos.dart` (`IndiceBaralhos`, `previsaoDeCarga`, `retencaoReal`).
- **Cartão frente EN / verso PT = "virar e avaliar"** (`presentation/sessao_cartoes_page.dart`): lê/ouve o inglês (voz sozinha se
  "áudio automático"), "Mostrar resposta" (Espaço), 4 botões **Errei · Difícil · Bom · Fácil com o intervalo previsto** (1 dia, 3 dias,
  2 sem…; teclas 1–4; `AgendadorFsrs.previsao`, SEM fuzz para o número não pular). Cada SENTIDO é um cartão à parte com memória própria
  (chave `<chave>~r`, `Revisao.chaveReversa`; "Basic and reversed" do Anki). Cartão novo: a nota decide o intervalo (`novo(voltaAmanha:
  false)`; o PT→EN da lição continua voltando amanhã). Errei volta na sessão até 2× SEM contar de novo; só a 1ª nota vai ao FSRS. Os
  novos entram pela cota "novos/dia" (`RevisaoCubit.novasReversas`). `abrirRevisao` (HUD "Revisão") agora roda os dois sentidos: digitados
  primeiro, depois os de virar; a nota de auto-avaliação NÃO vai para o ranking (daria para forjar).
- **Responder ESCREVENDO no cartão de virar** (pedido do dono, 12/out: "aqui a forma de responder deve ser por escrita também"; o "digitar a
  resposta" do Anki): no cartão inglês → português há um campo para ESCREVER a tradução em português (padrão LIGADO, lembrado em `en_cartao_escrita`;
  a chave "✍️ Responder escrevendo" volta ao "Mostrar resposta"; "Não sei" também mostra sem escrever). Enter/Conferir compara palavra por palavra
  (`domain/comparar_resposta.dart`): ignora maiúscula, acento e pontuação, perdoa 1 letra errada em palavra de 5+ (2 em 9+), NÃO liga para a ordem
  (tradução é livre) e conta palavras repetidas uma vez cada. Mostra "SUA RESPOSTA" (certas em verde, sobra em vermelho), a resposta do cartão com
  as palavras que FALTARAM sublinhadas e "acertou X de Y palavras"; **sugere** a nota — Bom (≥85% das palavras e ≥75% sem sobra, ou idêntica),
  Difícil (≥60% e ≥50%), senão Errei; "Fácil" nunca é sugerido — e a nota sugerida vem marcada ("sugerida"); **Espaço/Enter aceita a sugestão**,
  1–4 ou toque trocam (tradução livre pode estar certa mesmo diferente). Com o campo em foco as teclas são do campo (espaço, 1–4 e R não
  avaliam nem ouvem). A repetição do "Errei" também pede a escrita. A nota continua sendo do aluno (não vai ao ranking). (A chave "Responder
  escrevendo" virou o seletor de nível — ver o item seguinte; Avançado é este modo.)
- **Níveis de resposta e sentido do cartão** (pedido do dono, 12/out: "tenha um nível… iniciante, médio e avançado… e nem sempre vai ser só a
  frase em inglês, às vezes é ao contrário"; `domain/nivel_resposta.dart`, tela em `sessao_cartoes_page.dart`). Duas fileiras de opções em cima do
  cartão, lembradas em `en_cartao_nivel` / `en_cartao_sentido` (a pref antiga `en_cartao_escrita=false` vira "Só virar"):
  **Nível** — 🧩 **Fácil** (blocos de palavras para montar a frase, como no Duolingo, misturados com blocos de ENFEITE que não fazem parte da
  resposta: `quantosDistratores` = ~metade, 2–5; vêm primeiro das outras frases da sessão, depois das frases do curso (`apoio`, passadas por
  `abrirRevisao`) e por fim de uma lista de reserva por idioma; nunca repetem palavra da resposta; tocar no bloco da frase devolve ao banco;
  Backspace tira o último, Enter confere), ✏️ **Médio** (a frase com ~55% das palavras como LACUNAS para escrever — as compridas têm mais chance
  —, o resto à vista; Espaço/Enter pula para a próxima lacuna, Enter na última confere), ✍️ **Avançado** (escrever a frase inteira, o de antes)
  e 👁 **Só virar**. **Sentido** — EN → PT, PT → EN ou 🔀 **Misturado** (padrão; cada cartão sorteia o lado e o "Errei" que volta mantém o lado).
  Com o português na frente, o áudio (inglês) só toca/aparece DEPOIS de responder (nem a tecla R entrega antes) e a resposta é em INGLÊS (campo,
  lacunas ou blocos em inglês; `don't`/`dont`/`I’m` contam como a mesma palavra — apóstrofo faz parte da palavra e não entra na comparação).
  Nota sugerida por nível: Médio = todas as lacunas Bom, ≥60% Difícil; Fácil = só a frase certa NA ORDEM sugere Bom, palavras certas em outra
  ordem ou quase = Difícil, senão Errei (montar é reconhecer, não lembrar); Avançado = como antes. "Fácil" (a nota) nunca é sugerido.
  Os dois sentidos avaliam o MESMO cartão `~r` (uma memória só por frase/sentido de virar; o PT→EN digitado da lição segue sendo outro cartão).
  Trocar o nível/sentido no meio do cartão ainda não respondido refaz o cartão; depois de virar só vale para o próximo.
  Testes: `ingles_nivel_resposta_test` (23: partes, lacunas, blocos, conferências, apóstrofo) + 18 novos em `ingles_cartoes_ui_test`
  (blocos, enfeites no idioma certo, Médio, PT→EN, R/áudio, sorteio do lado, 360 px) — validados com mutação (R antes de virar, áudio ao abrir,
  lado na repetição, sentido no cartão virado). **PUBLICADO em pac-dart.web.app (12/out/2026, só hosting; regras não mudaram).** **Prova no Chrome real** (probe `main_portfolio_probe` + Playwright, 1027 e 390 px): Fácil montado e
  conferido por Enter, Médio com Espaço pulando de lacuna, PT→EN com o 🔊 só depois de responder, sem erro no console.
- **Navegador de cartões** (`navegador_cartoes_page.dart`): por baralho, busca, situação dos dois sentidos ("vence hoje", "em 3 sem ·
  memória 30 d"), **suspender** (some até reativar) e **enterrar até amanhã** (`CartaoSrs.suspenso/enterradoAte`, 8º campo opcional do codec).
- **Novo cartão à mão** (`novo_cartao_page.dart`): frente em inglês + verso em português (ou "Traduzir para mim"), áudio opcional, cria vários
  seguidos. Vai para o baralho "Meus cartões" (`TextoSalvo` id `cartoes`, `sequencial: true` = lições 8,8,1… para o progresso das lições
  anteriores nunca mudar), evento `CartaoAdicionado`; o 1º cartão liga o EN→PT do baralho. A frente passa pelo mesmo conserto de
  caracteres do texto colado (é frase para DIGITAR). **Importar lista** (`importar_cartoes_page.dart`, `domain/cartoes_texto.dart`): TAB (arquivo
  do Anki, com `#separator`, tags, HTML e aspas), `;` ou `|`; até 500; vira baralho novo SEM sair dos Baralhos (`TextoCriado(abrir:false)`).
  **Exportar para o Anki** (`exportar_anki_dialog.dart`, `domain/exportar_anki.dart`): arquivo TAB (`#separator:tab #html:false #tags column:3`,
  frente=inglês, verso=português ou invertido, tags `Paclingo::<etapa>::<baralho>`), copiar/baixar .txt (só web), e o **histórico em CSV**
  (fase 6 só até aqui: a calibração dos parâmetros do FSRS continua sendo offline, ainda não feita).
- **Áudio do aluno** (`data/audio_usuario*.dart`, `domain/audio_usuario.dart`, `widgets/audio_da_frase.dart`): 🎧 ao lado do 🔊 no cartão da
  tradução (palco e Revisão), no cartão de virar e no menu do navegador; folha "Seu áudio desta frase" (enviar, ouvir, trocar, remover);
  também no Novo cartão. Formatos mp3/m4a/mp4/aac/wav/ogg/opus/webm/flac conferidos pelo CONTEÚDO (não só pela extensão), máx. **800 KB**,
  guardados **como vieram** (sem converter). **Prioridade ao tocar (`VozIngles.falar`)**: áudio do aluno > gravação do curso (Tatoeba) > voz
  gerada (Chirp) > voz do aparelho; se o formato não toca naquele aparelho, cai na voz de antes sem ficar mudo. Chave = texto da frase
  (`Revisao.chave`), então vale em todas as telas. Armazenamento (decisão "recomendado"): bytes no Firestore, `users/{uid}/audio/{chave}`
  `{b: Blob, m, n}` + índice `_idx` (1 leitura abre o app; 1 por clipe na 1ª vez da sessão, depois cache em memória). Só existe com nuvem
  (`Firebase.apps.isNotEmpty`) ou repositório injetado (`PacDartApp(audioBuilder:)`); sem isso o 🎧 some. **Gravar pelo microfone NÃO foi feito**:
  o pacote `record` 7.1.2 exige Dart ≥ 3.12 e o projeto está no 3.11. Pacote novo: `file_picker` ^13.1.0 (plugin: no iOS rode `pod install`).
- **Rotinas que mudaram de lugar**: `RevisaoCubit` agora tem config, cartão invertido, escondidos e previsão; `CursoBloc` serializa as operações de
  texto numa fila (`_serializar`) — o bloc trata eventos em paralelo e o repositório lê-modifica-grava (várias adições seguidas perdiam cartões).
  `main.dart`: `RepositoryProvider<AudioUsuarioRepository>(lazy: false …)` — sem `lazy: false` o registro NUNCA inicia (o 🎧 não aparece).
- **Regras / exclusão de conta**: `firestore.rules` ganhou `users/{uid}/audio/{doc}` (junto de `srs` e `srs_log`) — **publicar as regras ANTES do
  hosting**. `apagarDadosDoUsuario` apaga os áudios achados pelo índice (listar a coleção baixaria todos os arquivos) em lotes de até 498.
- **Provas**: testes `ingles_baralhos_test` (domínio/cubit), `ingles_cartoes_ui_test` (sessão, baralhos, navegador), `ingles_cartoes_texto_test`
  (importar/exportar/bloc), `ingles_novo_cartao_ui_test`, `ingles_audio_test` (30: formatos, repositórios, registro, prioridade, corrida entre duas
  falas — com teste de mutação), mais grupos no `ingles_ui_test` (app inteiro) e `firestore_rules_test`; os puros também rodam com
  `--platform chrome`. **Prova no Chrome real** (probe + Playwright): WAV enviado pelo seletor de arquivos, `<audio>` tocou o `blob:` a 0,8×
  sem acionar a síntese de voz, novo cartão com tradução do MyMemory, cartão de virar com os 4 botões, previsão e atividade nos Baralhos.
  Armadilhas: no Playwright o seletor de arquivo vira "modal" — use `browser_file_upload`; o arquivo precisa estar em `.playwright-mcp/` ou
  no projeto. Nos testes de app a transição de saída de página leva ~17 passos de `_anda` (não 4).
- **Não feito / ideias**: gravar áudio pelo microfone (ver acima); sincronizar suspensos/enterrados (já vão no cartão, sim) e os ajustes locais; áudio
  também no PORTUGUÊS (hoje só no inglês); calibrar os parâmetros do FSRS com milhares de revisões; cloze; importar `.apkg` (só texto).

---

## ✨ Features (o que existe)

- **Motor de digitação** Pac-Man: auto-indentação, backspace inteligente, acentos/IME (dead keys).
- **Auto-scroll** do código (a caixa acompanha o Pac-Man) + **altura limitada** (não empurra o console).
- **Botão "copiar"**: gera código **rodável** (Flutter vira `main()+MaterialApp`, Dart fica completo) pra colar no DartPad/IDE.
- **3 paletas** (Mixart escuro / Flutter claro / Flutter escuro) com **seletor de tema** (HUD e login), persistido por dispositivo.
- **Login e-mail/senha** (Firebase Auth) + **progresso na nuvem** por usuário (Firestore).
- **Mapa da Jornada**: caminho zigue-zague, dashboard, e **busca por nome** (lições + projetos + apps).
- **Teoria / Nivelamento** por lição (texto simples + exemplos, blocos h/p/code/tip/warn).
- **Quiz** por lição (até 10 perguntas), com **dois jeitos de responder**: tocar direto na
  alternativa certa, ou digitar o código dela e mandar no botão **Responder** (ou Ctrl/Cmd+Enter).
  - **Enter NUNCA envia** — só quebra linha. (Antes ele enviava quando o texto digitado não casava
    com nenhuma alternativa, então qualquer typo corrigia a questão antes da hora.)
  - A correção **ignora formatação**: quebra de linha, indentação e espaço colado em pontuação não
    contam, então dá para digitar um trecho de 3 linhas numa linha só. Typo em identificador
    (`istnotEmpty`) continua errado — é código.
- **Sequência automática pós-lição** (`presentation/fluxo_licao.dart`): terminou de digitar a lição →
  o **quiz** abre sozinho depois de ~3,4s (barrinha de contagem no overlay de vitória; Enter começa na
  hora, "Pular quiz" segue sem ele; **Esc na vitória também pula o quiz** — o overlay mostra os dois atalhos: ↵ Enter → quiz · Esc → próxima lição) → quando **todas as lições da trilha** estão feitas, emendam os
  projetos **Mão na Massa** que ainda faltam, um a um ("projeto X de Y", cada um com "Pular") →
  próxima lição. A seta de voltar sai da sequência.
- **Progresso de projetos**: digitar um projeto/app até o fim marca ele como **construído**
  (chaves `proj:t:i` e `master:i`), e o mapa mostra check + contador ("2 de 3 construídos").
  No nó da lição, a estrela indica quiz respondido (cheia quando ≥8/10).
- **Fundos temáticos** por trilha (foto escurecida, clima de "fase de jogo").
- **Prévia Flutter AO VIVO**: o app se monta na telinha conforme você digita (nos apps Mão na Massa / Master).
- **Rodar no DartPad** (`lib/features/dartpad/`): botão **"rodar"** no canto do editor abre o
  **DartPad de verdade em tela cheia**, já com o código do exercício carregado e **executado**
  (compila no servidor do Dart — precisa de internet).
  - O trecho é um FRAGMENTO; quem o transforma em programa é `core/util/codigo_executavel.dart`:
    puxa da lição os trechos que o trecho cita, **declara o que ninguém declarou** (deduz pelo uso:
    `.length` → lista, `> 0` → número) marcando com `// ← completado para rodar`, liga imports,
    fecha chaves de trecho cortado, e no Flutter transforma comando com `context`
    (showDialog/Navigator/SnackBar) num **botão** e `setState` num StatefulWidget.
  - **O botão só aparece onde o programa comprovadamente compila** (`assets/roda.json`):
    **1174 dos 2354 exercícios (49%)** e **85 dos 121 projetos**. O resto não tem como rodar —
    depende de pacote que o DartPad não carrega (dio, sqflite, shared_preferences, Firebase, http),
    do `package:test`, ou é pedaço solto demais. Melhor sem botão do que com tela de erro vermelho.
- **Narração por voz NATURAL** (jul/2026): `core/voz/voz_natural.dart` — as dicas falam com a
  voz neural do **Gemini TTS** (`gemini-2.5-flash-preview-tts`, voz Zephyr, instrução de estilo
  em pt-BR que NÃO é lida), usando a MESMA chave trancada por domínio do Prof. Dash. Resposta é
  PCM16 24kHz base64 → tocado no Web Audio (`voz_natural_web.dart`; ⚠️ `package:web` exporta um
  `Float32List` de interop que sombreia o de dart:typed_data — importar com `hide Float32List`).
  Cache por texto (dica repetida = instantâneo), gerações atropelam falas antigas, e QUALQUER
  falha (cota/rede/VM) cai no fallback antigo do flutter_tts sem drama (`VozCubit.falarSempre`
  tenta natural → senão sistema). Fora da web o stub desiste na hora (teste garante zero rede).
  ⚠️ **Cota do TTS grátis é POR DIA (~10 áudios)** — confirmado empiricamente: 429 persiste
  horas ("a voz perfeita veio nas primeiras vezes e depois se perdeu" = cota diária, não bug).
  **Política de gasto**: a voz neural é RESERVADA para a fala do Prof. Dash e para toques
  explícitos no 🔊/"ouvir" (falarSempre); a narração AUTOMÁTICA das dicas usa a MELHOR voz do
  navegador (`_escolherMelhorVoz`: getVoices → prioriza nome com "Google"/"Natural" e locale
  pt-BR — no Chrome, a "Google português do Brasil" é de rede e bem menos robótica que a voz
  local padrão). Debounce de 900ms segue nas dicas; cooldown pós-429 = 5 min. Se um dia
  quiser voz neural EM TUDO: ativar billing no projeto (TTS pago custa centavos) e voltar
  `falar()` a chamar `falarSempre()`.
  - **O Prof. Dash também FALA** (mesma voz): toggle 🔊 no cabeçalho do painel (persistido em
    `voz_tutor`, padrão ligado) narra cada resposta ao terminar de chegar + link "ouvir" em cada
    bolha. `domain/texto_falavel.dart` prepara a fala: blocos ``` viram "dá uma olhada no exemplo
    de código aqui no chat", marcação e emoji somem. Reusa `VozCubit.falarSempre` (natural →
    fallback), lido null-safe no painel.
- **🏆 Ranking de jogadores** (`lib/features/ranking/`, jul/2026): placar público em
  `ranking/{uid}` no Firestore (apelido + pontos, teclas, erros, lições, projetos, quiz, arcade,
  recordes por joguinho). Alimentado sozinho ao concluir lição (HomePage escuta `vitoria`),
  quiz (`quiz_page`), projeto (`projeto_page`) e partidas do Arcade. A digitação sobe por
  **DELTA** (RankingCubit guarda a régua do último envio; escrita que falha fica pendente e
  reenvia na próxima). Página com pódio 🥇🥈🥉 (vagas livres convidam amigos), critérios
  **Geral / Precisão / Digitação / Arcade** (precisão exige 300+ toques pra valer) e badge VOCÊ.
  `RankingCubit.de(context)` devolve null fora do app logado — telas antigas e testes não quebram.
- **🎮 Arcade Dart** (`lib/features/arcade/`, jul/2026; 6 jogos desde set/2026 com o Dart Turismo) — joguinhos de programação, banco
  autoral de **76 desafios** (30 lógica + 30 sintaxe + 16 caça-bugs, níveis 1–3, escadinha
  fácil→difícil, opções embaralhadas por partida). **Os 30 de lógica foram RODADOS de verdade**
  (harness no scratchpad gera programa + runZoned captura print e compara com a opção certa).
  Botões no HUD (Arcade · Ranking). Pontos somam no ranking; recorde pessoal por jogo:
  - **🏎️ Corrida do Código** (lógica: "o que imprime?"): acertou avança, em ≤6s é TURBO (anda 2);
    errou, a CPU ganha um passo — e ela anda sozinha no relógio (Fácil 6s / Normal 4s / Difícil 3s,
    pontos x1/x1,5/x2). Teclas 1-2-3 respondem.
  - **⚽ Gol de Dart** (sintaxe: complete a peça): 5 pênaltis, cada opção é um canto do gol;
    certa = a bola vai no canto e o goleiro pula errado; errada/tempo (20s) = defesa.
    20 pts por gol + 30 da série perfeita. Teclas 1-2-3 ou ←↓→.
  - **🐞 Caça-Bug** (atenção): 8 rodadas, trecho com UMA linha defeituosa; clique nela antes do
    relógio (14s→10s conforme o nível); acerto = 10 + segundos sobrando.
  - **☄️ Chuva de Código** (digitação, estilo Ratatype): palavras do Dart caem
    (`domain/palavras_dart.dart`: 93 termos digitáveis em 3 faixas de tamanho, case-sensitive);
    a 1ª letra TRAVA a mira na palavra mais baixa e cada letra certa sai como TIRO da boca do
    Pac (o `Pacman` do code_view girado -90°). 15% nascem DOURADAS (4x pontos). Palavra no chão
    = -1 vida (3); nível sobe a cada 8 destruídas (spawn 3,4s→1,6s, queda ~18s→~9s).
    Motor puro `tiro_engine.dart` + `Ticker` na página; teclado via `CampoTeclas`
    (TextField invisível, mesmo truque do CodeView — funciona no celular).
  - **🏁 Rali de Digitação**: cada palavra digitada = 1 passo do carrinho; palavra PERFEITA
    (zero erros) = turbo (2 passos). Reusa o `CorridaEngine` (pista 12, mesmos rivais
    Fácil/Normal/Difícil) + `ProgressoPalavra`; placar com PPM ao vivo.
  - **Campanha de FASES em TODOS os jogos (jul/2026)**: venceu → `FaseVencida` (pontos da fase +
    total acumulado + **dica Dart** de `domain/dicas_dart.dart`, 20 dicas que ciclam) → próxima
    fase mais difícil (CPU 8% mais rápida por fase nos 2 de corrida; relógio do chute -2s no
    futebol, mín 8s; relógio do Caça-Bug -10%/fase; Rali ganha palavras compridas na fase 3) —
    ou "Parar e guardar pontos". O TOTAL da campanha é publicado no ranking UMA vez, no fim
    (`_fimDeJogo`); sair no meio publica o parcial no `dispose` (cubit capturado no initState).
  - **Cenário muda a cada fase** (`widgets/cenario.dart`, CustomPainter, ciclo de 6 mundos):
    🌅 Campina ao Amanhecer · 🏜️ Deserto · 🌃 Cidade à Noite · ❄️ Montanha Nevada · 🌋 Vulcão ·
    🌌 Espaço. Usado na pista dos 2 jogos de corrida, atrás do gol do futebol, na faixa do
    Caça-Bug e na arena da Chuva (que troca por NÍVEL, com aviso "NÍVEL X — cenário!").
  - **Pista profissional** (`PistaPro` em arcade_ui, estilo Ratatype): cenário no horizonte,
    asfalto com faixa tracejada, largada/chegada quadriculadas, crachá da fase, personagens com
    badge VOCÊ/CPU olhando pro lado CERTO (nada de emoji de carro espelhado).
  - **Personagem escolhível** (`domain/personagem.dart` + `widgets/avatares.dart`): **Pac** (o
    CustomPainter animado do app) ou **Dash** (o passarinho do Flutter, DESENHADO em
    CustomPainter — sem imagem externa). Escolha no hub, persiste em shared_preferences
    (`PersonagemStore.atual`, padrão estático tipo Mixart). Corre nas pistas e atira na Chuva.
  - Widgets compartilhados dos jogos: `widgets/arcade_ui.dart` (CabecalhoJogo, ChipPlacar,
    BotaoOpcao, CartaoCodigo, **PistaPro**, **SeletorDificuldade**, FimDeJogo, **FaseVencida**),
    `widgets/campo_teclas.dart`, `widgets/cenario.dart` e `widgets/avatares.dart`.
  - ⚠️ **CampoTeclas mantém o foco NA MARRA**: clicar em qualquer botão (Jogar de novo, Fácil…)
    roubava o foco do TextField oculto e o teclado "morria" na 2ª partida. O fix é um listener no
    FocusNode que devolve o foco no pós-frame sempre que perde. NÃO remover — tem teste cobrindo.
  - **🗺️ LÓGICA ANIMADA (jul/2026)** — modo missões do Arcade (cartão de destaque no hub):
    cada missão é uma cena travada em 4 atos — **PREVER** (pergunta de lógica com 3 opções,
    +15 pts) → **DIGITAR** o código no motor Pac-Man (reusa `CodeView` + `TypingBloc` local,
    padrão ProjetoPage) → **ASSISTIR** a execução animada passo a passo (legendas narrando:
    "idade 16 >= 18? NÃO → barrado ⛔") → **VITÓRIA** (pontos + explicação). **🔮 Ajuda
    Misteriosa**: 3 dicas progressivas, -5 pts cada.
    - **Gerador infinito** (`domain/gerador_missoes.dart`): 16 gabaritos parametrizados
      (nomes/números/listas sorteados) — `missaoPara(trilha, indice)` é DETERMINÍSTICO e a
      resposta certa + roteiro da animação são COMPUTADOS dos mesmos parâmetros (teste audita
      a consistência). `test/missoes_test.dart` prova **1000+ códigos únicos** numa amostra de
      1280 (32 trilhas × 40) — e o índice não tem teto. TODO código gerado passa na whitelist
      de digitabilidade.
    - **6 cenas** (`widgets/cenas.dart`, sobre o CenarioFase da trilha): 🚪 porta (laços/if),
      🚓 blitz (condições — maioridade/radar/&&), 🍇 colheita (listas), 🚦 semáforo
      (switch/ternário), 🚀 foguete (contagem/while), 🌉 ponte (acumulação). Estado da cena =
      `dados` da missão + merge dos `muda` de cada `PassoCena`.
    - **Trilhas do mapa gateiam as missões** (`missoes_page.dart`): trilha liberada se é a
      0 ou tem ≥1 lição concluída — "jogue o Mapa pra liberar mundos". Progresso por trilha
      em shared_preferences (`ProgressoMissoes`, chave `missao_t{n}`). Pontos →
      `RankingCubit.missaoConcluida` (campo `missoes` no doc do ranking, aparece na linha).
  - **🔊 Sons de fliperama SINTETIZADOS (jul/2026)** — `core/som/` (sons.dart + som_web.dart /
    som_stub.dart via import condicional): Web Audio puro (osciladores + envelopes agendados no
    relógio do AudioContext), ZERO assets e zero dependências novas (`package:web` já existia).
    13 efeitos: waka-waka alternado na digitação (gancho único no CodeView — vale lição, projeto
    e missão), erro, blip, tiro, explosão, turbo, gol (3 notas), defesa, fanfarra (arpejo),
    fase, tique, decolar e 🔮 mistério. Toggle **Som** no HUD (persistido, `som_ligado`).
    Na VM/testes vira no-op (`test/sons_test.dart`). AudioContext nasce lazy no 1º toque
    (política de autoplay) e `Sons.toca` NUNCA lança.
  - **Missões de Maps/Strings/null safety (jul/2026)**: +2 cenas (🛒 mercado com visor de caixa,
    🔐 cofre com painel) e +6 gabaritos — Visor do Caixa (`precos['x'] ?? 0`), Conta da Feira
    (soma de `.values`), Tem no Estoque? (`containsKey`), Senha do Cofre (`length`), Cofre aos
    Gritos (`toUpperCase`), Bilhete Perdido (`String?` + `??`). Total: **22 gabaritos**, trilhas
    0/2/3 ampliadas e os 6 conjuntos avançados com 5-6 cada. Diversidade re-auditada: 1000+
    códigos únicos seguem garantidos por teste (ao mexer em gabarito, rode `missoes_test`:
    pouco espaço de parâmetros × muitos sorteios = colisão).
  - **🎊 Confete** (`Confete` em arcade_ui, CustomPainter determinístico de uma passada):
    FimDeJogo ganhou `celebrar:` (true quando venceu fases / recorde na Chuva), FaseVencida e
    a vitória de missão sempre celebram.
  - **Prova visual sem login**: `lib/main_arcade_probe.dart` abre o HUB DO ARCADE de verdade
    (os jogos rodam sem Firebase — `RankingCubit.de` vira no-op) + rota `/galeria` com
    pista/cenários/avatares crus. `flutter build web -t lib/main_arcade_probe.dart
    --output=build/probe`, `python3 -m http.server 8788 --directory build/probe` e o MCP do
    Playwright: `document.querySelector('flt-semantics-placeholder').click()` liga a
    acessibilidade do canvas e aí `role=button[name=/Fácil/]` etc. viram alvos clicáveis;
    `browser_run_code_unsafe` encadeia clique → espera → screenshot sem latência (foi assim
    que o voo da bola e a pausa foram fotografados). O cartão "Lógica Animada" NÃO abre no
    probe (precisa de `CursoBloc`).
  - **🕹️ ARCADE 2.0 (set/2026) — jogabilidade**:
    - **Baralho progressivo** (`domain/baralho.dart`): `Baralho<T>` genérico + `BaralhoDesafios`
      / `BaralhoBugs`. Antes, `sortearDesafios` ordenava o banco por nível e cada fase
      recomeçava do nível 1 — Corrida e Gol NUNCA mostravam níveis 2-3 (2/3 do banco morto).
      Agora `pesosDaFase`: fase 1 = {1}, fase 2 = {1: .4, 2: .6}, fase 3 = {2: .5, 3: .5},
      4+ = {2: .3, 3: .7}; nenhuma carta repete até o nível esgotar (aí recicla só ele);
      lotes saem em escadinha. Os testes de tela reproduzem o sorteio com a mesma semente
      (`BaralhoDesafios(rnd: Random(42), …).sortear(5, 1)`). Selo `NÍVEL ★★☆` no desafio.
    - **Pausa em todos os jogos** (`presentation/widgets/campanha.dart`, mixin `PausaDeJogo`):
      Esc, botão ⏸ no cabeçalho e AUTOMÁTICA no `didChangeAppLifecycleState != resumed` (outra
      aba, janela sem foco). Corrida/Rali param os `AnimationController`s; Futebol/Caça-Bug
      deixam o `Timer.periodic` rodando mas o tick sai cedo se `pausado` (o avanço entre
      rodadas ainda acontece, o relógio não); Chuva sincroniza `_ultimo` no ticker.
      `pausarSeEscondido()` cobre largada terminando com a aba escondida. Overlay
      `PausaOverlay` (Continuar / Sair do jogo — sair publica o parcial no dispose).
    - **`CampanhaDeFases`** (mesmo arquivo): fase/fator(+10%/fase)/total/faseVencida/acabou/
      novoRecorde/pontuado + `encerrar()` (publica no ranking UMA vez) e `pontosParciais`
      (parcial no dispose) — tirou ~60 linhas duplicadas de cada uma das 4 páginas de
      campanha. Ordem obrigatória dos mixins: `with WidgetsBindingObserver, PausaDeJogo<X>,
      CampanhaDeFases<X>` (+ `TickerProviderStateMixin` se precisar).
    - **Largada 3-2-1** (`ContagemRegressiva`, 4 × 650 ms = 2,6 s, sons tique + `Som.largada`)
      na Corrida, no Rali e na Chuva — relógios só ligam no `onFim`. Nos testes:
      `tester.pump(ContagemRegressiva.duracao + 50ms)` antes de interagir.
    - **Corrida**: barra do TURBO visível (`AnimationController` de 6 s por pergunta —
      `rapida = !_turboCtrl.isCompleted`, pausa-friendly) e **medidor da CPU** na pista
      (`cargaCpu`, o `_cpuCtrl` cuja conclusão dá o passo do rival e reinicia). Chama 🔥 no
      passo dobrado. **Rali**: idem + fila "a seguir: x · y" e PPM descontando pausas.
    - **Chuva**: **COMBO** no `TiroEngine` (palavras seguidas sem erro: x2 aos 5, x3 aos 10;
      tecla errada ou palavra no chão zera; `ultimoGanho`, `melhorCombo`, `faltamProCombo`),
      chip COMBO + aviso "🔥 COMBO x2", `Som.combo`; estilhaços na palavra destruída
      (`Estilhacos`), tremor da arena e chão vermelho ao perder vida (`Tremor`), próxima letra
      do alvo com cursor (sem riscar o digitado), chips em perigo (y > .78) com borda vermelha,
      mira tracejada Pac → alvo, tiros com rastro luminoso (`_TirosPainter`), `px = x·(w-200)`.
    - **Gol**: bola em ARCO (`TweenAnimationBuilder` com `sin(πt)`), rede, `Tremor` na defesa,
      `BarraTempo` compartilhada. **Caça-Bug**: estilhaços na linha esmagada, tremor na errada.
    - Widgets novos em `arcade_ui.dart`: `BarraTempo`, `SeloNivel`, `BotaoPausa`,
      `PausaOverlay`, `ContagemRegressiva`, `Tremor`, `Estilhacos`, `CartaoInclinavel`,
      `ChamaTurbo`, `CargaCpu`; `CabecalhoJogo.acao`; `FimDeJogo.noRanking`.
      Sons novos: `Som.combo`, `Som.largada`.
  - **🎮 ARCADE 2.0 — visual PSEUDO-3D (set/2026)**: pedido do usuário ("cara mais realista
    tipo 3D"). Sem motor 3D nem dependência nova: tudo é Canvas com projeção de perspectiva.
    - `widgets/perspectiva.dart`: `Perspectiva` (câmera olhando pro horizonte: `y(d) =
      horizonte + alturaChao/d`, `x(d, l) = fugaX + l·meiaLargura/d`, escala `1/d`, `acima()`
      pra alturas), `Sombra` (elipse com blur), `pintarChaoEmFaixas` (faixas horizontais
      cada vez mais finas = profundidade), `pintarLinhasDeFuga`, `pintarQuadriculado`,
      `pintarNeblina`, `pintarTexto`, `tom()`.
    - `widgets/pista3d.dart` (**`PistaPro`**, mesma API, exportada por `arcade_ui.dart`):
      estrada em segmentos alternados com zebras vermelhas/brancas e faixa central, chão do
      mundo em faixas, adereços por tema (árvore/cacto/poste/pinheiro/rocha/cristal) do mais
      longe pro mais perto, largada quadriculada perto (d=1,28) e **portal de CHEGADA** ao
      fundo (d=2,6). Corredores andam PRA DENTRO da tela (jogador na faixa −.46, CPU +.46),
      escalam com `1/d` (crachá com mínimo .78), sombra no chão, quem está mais longe é
      pintado primeiro. Altura 272.
    - `widgets/cenario.dart`: `TemaChao`/`chaoDaFase()` (cores do chão, neblina, linha de
      grade e adereço por mundo) + **`PalcoFase`** (céu do cenário até o horizonte + chão em
      perspectiva com grade e brilho) — usado na arena da Chuva (`horizonte: .58`) e na faixa
      do Caça-Bug. Árvores da campina viraram copas redondas com luz.
    - `widgets/gol3d.dart` (**`Gol3D`**): estádio da marca do pênalti — gramado listrado em
      perspectiva com linhas da área e marca, arquibancada com torcida (pontinhos estáveis) e
      placas, trave com **rede em caixa** (fundo a d=2,5, laterais, teto), **goleiro desenhado**
      (`_GoleiroPainter`, mergulha girando pro canto) e **bola com gomos e brilho** que voa em
      arco diminuindo, com sombra correndo no gramado. `chuteId` reanima. Altura 216.
    - `widgets/avatares.dart`: **`Pac3D`** (esfera com gradiente radial, lábios em sombra,
      brilho especular, olho com reflexo; mastiga), Dash com luz/contraluz, **`RoboCpu`**
      (cabeça metálica, visor, olhos ciano acesos, antena) — substitui o 🤖 emoji.
    - Chuva: sombra sob o Pac, chips com sombra (flutuam sobre o palco). Caça-Bug: código
      dentro de um **monitor** (`_Monitor`: moldura metálica com luz, reflexo + scanlines
      por cima sem bloquear clique, LED, pé). Hub: `CartaoInclinavel` (inclina em perspectiva
      seguindo o mouse, sombra que cresce) + gradiente e emoji com sombra nos cartões.
    - O Pac do CodeView (`curso/.../pacman.dart`) NÃO mudou — só o arcade usa o 3D.
  - **🏎️ DART TURISMO (set/2026)** — 6º jogo do hub, pedido do usuário: "corrida profissional
    tipo Gran Turismo, tudo 3D; no lugar de setas, o que muda de lado são PALAVRAS; se parar de
    escrever o carro vai parando; 10 fases com níveis de dificuldade".
    - **Regra**: campeonato de 10 pistas (`domain/turismo.dart`, tabela `pistasGt`). A cada
      `intervaloPortais` metros há um PORTAL: as faixas livres (1, ou 2 nas pistas 7-10 —
      `duasSaidas`) têm uma palavra na placa; as outras estão bloqueadas por carros parados.
      Digitar a palavra = o carro vai pra faixa dela. Cada tecla certa dá impulso
      (`velMax·0,075`), completar a palavra dá boost (`velMax·0,12`); arrasto quadrático
      `velMax·(0,02 + 0,13·r²)` por segundo → parar de digitar é ir parando até zero (~10 s).
      Tecla errada: −10% de velocidade. Portal cruzado em faixa bloqueada: BATIDA (velocidade
      a 30%, `impacto` = 1 pro tremor/vinheta). COMBO de palavras sem erro/batida: x2 aos 5,
      x3 aos 10. Pontos = (3+letras)·mult + bônus da medalha (60/120/200) — calibrado no probe: um bot a 15 letras/s fez 3.822 pts com (10+letras), fora da escala dos outros jogos; um humano a ~1 palavra/s faz ~500-900 por corrida com (3+letras).
    - **Dificuldade derivada, não chutada**: `velAlvo` (média mínima, km/h) e `tempoPorPortal`
      (s) definem `tempoLimite = distancia/velAlvo` (bronze; prata ≤ 86%, ouro ≤ 72%),
      `intervaloPortais = velAlvo·tempoPorPortal` e `velMax = intervalo/2,8` (sempre ≥ 2,8 s
      por portal na máxima). Teste garante que o ouro exige ≤ 92% da máxima em toda pista.
      Pista 1: 1 km, 60 km/h, palavras curtas, curvas 1,5 · Pista 10: 3 km, 150 km/h,
      médias+longas, curvas 6, duas saídas. Vocabulário = `palavras_dart.dart` por nível.
    - **Sempre há o que digitar — COMBUSTÍVEL**: `portalParaDigitar` = o próximo portal se
      ainda não digitado; digitada a palavra dele, `_atualizaAlvo()` sorteia `palavraGas`
      (mesmo vocabulário) que só acelera (boost menor, `velMax·0,06`, mesmos pontos/combo).
      Ao cruzar o portal, o portal seguinte assume a vez — mas uma palavra de combustível pela
      metade termina antes (prioridade do portal só com gás intocado). Foi assim que se
      resolveu o problema visto no probe: com "digitar adiantado" o jogador esgotava as 11
      palavras em 4 s e o carro parava sem ter o que digitar. A primeira letra escolhe a
      palavra quando há duas saídas (`palavraTravada`). Portal cruzado sem palavra zera a
      digitação pela metade. O cartão da tela marca `Semantics(label: 'digite: <palavra>')`
      — é o gancho que o Playwright usa pra ler a palavra na vez (`[aria-label^="digite: "]`).
    - **Pista gerada** (`_gerarPista`): segmentos de 8 m com curva acumulada (técnica dos
      racers clássicos — a curva soma segmento a segmento e dobra a estrada na tela), largada
      reta de 10 segmentos, seções entrada/manter/saída com `_suave`; portais nunca liberam a
      faixa que o carro já ocupa (todo portal exige digitar). Determinística por semente.
    - **Persistência** (`domain/progresso_turismo.dart`): `turismo_pista_max`,
      `turismo_medalha_N`, `turismo_tempo_N` (só melhora); medalha > 0 libera a próxima.
      Ranking: `arcadeJogado('turismo', pontosFinais)` ao fim de cada corrida (parcial no
      dispose se sair no meio).
    - **Tela** (`presentation/turismo_page.dart`): campeonato (grade das 10 pistas com
      medalha/tempo/🔒) → corrida (cabeçalho TEMPO/PALAVRAS/COMBO/ERROS + ⏸, vista 3D em
      `Expanded`, cartão da palavra com seta da faixa — ⬅ ESQUERDA · ⬆ MEIO · ➡ DIREITA —,
      cursor, "✓ próximo portal liberado", "a seguir") → fim (medalha, tempos de ouro/prata/
      bronze, pontos, recorde, Próxima pista / Correr de novo / Campeonato; "🏆 CAMPEÃO"
      na 10ª com medalha; ⏱ TEMPO ESGOTADO com tentar de novo). Largada 3-2-1, pausa
      (`PausaDeJogo`), `Tremor` na batida. Ticker de 60 fps com `setState` da página.
    - **Vista 3D** (`widgets/pista_gt.dart`, `VistaCorrida` + `_EstradaGtPainter`): projeção
      `escala = 0,84/z`, horizonte em 46%, câmera a 1,5 m seguindo `xAtual`; segmentos
      pintados do longe pro perto (o segmento sob o carro é cortado no plano próximo),
      zebras, faixas tracejadas, largada/chegada quadriculadas, neblina exponencial por
      distância (`tema.neblina`), adereços por tema com sorteio estável por segmento, pórtico
      (postes + viga + placas: verde/palavra, ✓ quando digitada, ✕ vermelho bloqueada) e
      carros parados nas faixas bloqueadas; carro do jogador visto de trás (`_carro`: rodas,
      para-choque, carroceria com gradiente, vidro com reflexo, aerofólio, capacete do piloto
      na cor do personagem, lanternas que acendem ao frear, chamas no boost, placa DART),
      inclina ao trocar de faixa, faróis em cone nas pistas noturnas (cidade/vulcão/espaço),
      rastros de velocidade acima de 35% da máxima, vinheta vermelha na batida, velocímetro
      de ponteiro (arco amarelo→vermelho, km/h). Paralaxe do céu pela curva atual.
    - **Som**: `Sons.motorRonco(intensidade)` (serra + quadrada num passa-baixas, sobe de tom
      e abre o filtro com a velocidade; chamado a cada 80 ms) e `Sons.motorParar()`; waka na
      tecla, turbo na palavra, combo, erro, explosão na batida, fase/fanfarra na chegada.
    - **Probe**: rotas `#/turismo` (pista 1, semente 3: add trim true yield this Text for
      false final build where), `#/turismo3` (noturna) e `#/turismo10` (duas saídas).
      Testes: `test/turismo_test.dart` (campeonato, geração, física, adiantado, batida,
      medalhas, combo, progresso) + 2 testes de tela em `arcade_ui_test.dart`.
  - **🏎️ DART TURISMO em 3D REAL (set/2026)** — o usuário achou o Canvas "desenho" e pediu
    "super realista, carros top, pode baixar 3D". Solução: **Three.js (WebGL) embutido num
    `HtmlElementView`** só na web; a lógica segue em Dart e o estado do motor vai pro JS a
    cada frame. Fora da web (e nos testes) a vista em Canvas continua (`vista_3d_stub.dart`).
    - **Arquivos**: `web/turismo3d/turismo3d.js` (módulo ES: `window.turismo3d.{montar,
      atualizar, destruir, pronto, erro, debug, CARROS}`), `web/lib3d/` (three r0.186 MIT
      auto-hospedado: `three.module.min.js` + `three.core.js` + addons GLTFLoader/RGBELoader/
      DRACOLoader + decoder Draco — importmap no `web/index.html`), `web/assets3d/`
      (32 MB: `hdri/<mundo>.hdr` 1k, `tex/<nome>/{diff,nor,arm}.jpg` 512px, `modelos/`
      poste e barreira, `carros/<id>/scene.gltf` + bin + textures + license.txt),
      `lib/.../widgets/vista_3d.dart` (export condicional) + `vista_3d_web.dart`
      (`Vista3D`: registra `pac-turismo3d`, canvas com `pointer-events: none` pra os toques
      chegarem ao Flutter, manda tamanho/estado/palavra em `atualizar`, HUD Flutter por
      cima com `Velocimetro` de `widgets/velocimetro.dart`) + `vista_3d_stub.dart`.
    - **Assets e licenças** (créditos no rodapé do campeonato): carros do Sketchfab por
      **Lexyc16, CC BY 4.0** (Porsche 911 (930) Turbo 1975, Nissan Skyline R34 GT-R, Honda
      NSX 1990, Mazda Miata MX-5 NA, Toyota Corolla AE86 Trueno — baixados pelo Chrome do
      usuário logado; a Ferrari do exemplo do three.js foi DESCARTADA porque a página do
      Sketchfab está desativada e a licença não confere); céus/texturas/modelos da **Poly
      Haven, CC0** (API pública `api.polyhaven.com/files/<id>` exige User-Agent; os modelos
      de árvore têm .bin de 100-480 MB — não use; postes e barreira ok). Texturas reduzidas
      com `sips -Z 512`.
    - **Cena** (JS): centro da pista integra a curva do motor (`CURVA_RAD = 0,012` rad por
      segmento de 8 m → curva 6 ≈ raio 110 m) e vira faixas de geometria real (asfalto PBR
      `asphalt_track`, pintura em CanvasTexture com bordas e tracejado, zebras, chão do mundo
      4 km², guard-rail com lâmina de `metal_plate` + postes instanciados, largada/chegada
      quadriculadas, pórticos com placas CanvasTexture verde/✓/✕ atualizadas pelo estado,
      carros parados nas faixas bloqueadas só visíveis a −30..320 m). HDRI = background +
      environment; sol direcional com sombra 1536 seguindo o carro; FogExp2 por mundo; ACES.
      Câmera de perseguição com atraso (7,2-9 m atrás, 2,9-3,25 m alto, FOV 62+14·v);
      tremor no impacto. Faróis SpotLight à noite; cidade: postes clonados a cada 60 m com
      bulbo emissivo e um POOL de 5 PointLights que pulam pros postes próximos (39 luzes
      reais travaram a GPU — lição aprendida). Normalização dos glTF: mede caixa por malha,
      esconde plano de sombra (achatado e gigante ou nome shadow/plane), escala pelo
      comprimento em metros, frente pra −z (`giro: Math.PI` pros 5 modelos), chão em y=0.
      `faixaGeometria` precisa de índices anti-horários vistos de cima (normal +y) — a
      primeira versão saiu preta por isso. `materialPbr` nasce cinza com `metalness: 0`
      (asfalto/grama nunca ficam pretos enquanto as texturas chegam).
    - **Painéis das palavras no cenário** (dicas do usuário: "sentir que dirige enquanto
      escreve" e "a escrita do lado pra onde vai"): até 2 planos de 4,4×1,375 m, 5 m à
      frente do carro e 2,05 m de altura, cada um SOBRE A FAIXA pra onde a palavra leva
      (lateral `(faixa−1)·3,7 m` do centro da pista; combustível fica na faixa atual),
      sempre virados pra câmera (`depthTest: false`), CanvasTexture com rótulo da faixa,
      digitado em amarelo (verde no combustível), próxima letra destacada, palavra não
      escolhida esmaecida. O Dart manda `palavras: [{texto, digitadas, faixa, rotulo, tipo,
      ativa}]` em `atualizar`.
    - **Garagem**: `carrosGt` + `ProgressoTurismo.carroEscolhido()/escolherCarro()`
      (`turismo_carro`); a tela do campeonato tem os chips; o tráfego são os outros 4.
    - **Como depurar**: Playwright travou em screenshots com a cena pesada; o Chrome do
      usuário (extensão) mostrou `[turismo3d] cena montada / céu ok / carro ok` no console
      e `window.turismo3d.debug()` devolve carro/câmera/estado. JS muda sem rebuild: copie
      `web/turismo3d/turismo3d.js` pra `build/probe/turismo3d/` e recarregue.
    - **Peso**: ~32 MB de assets em `web/` vão pro Firebase Hosting; cada corrida carrega só
      o HDRI do mundo (~1,6 MB), 3 texturas e os carros (4-6 MB cada) — cuidado com a cota
      de banda do plano gratuito se o jogo viralizar.
    - **Rodada 2 (feedback "atravessa o carro / poucas curvas / som antigo")**: os carros
      parados ficam LOGO DEPOIS do pórtico (`p.z + 2,6`), e quando o motor marca `batido` o JS
      **arremessa** o carro da faixa (voa, gira, capota, some em 1,6 s) com **faíscas**
      (`THREE.Points`) e som de batida; `CURVA_RAD` 0,012 → 0,028 (curva 6 ≈ raio 48 m) e o
      gerador Dart faz sequência de S (só 12% de retas, curvas com 50-100% da máxima,
      alternando o lado em 80% das vezes). **Som gravado**: `web/assets3d/som/motor.m4a`
      (qubodup, CC BY 3.0, loop de 4 s; `playbackRate` 0,55→1,9 e passa-baixas abrindo com a
      velocidade) e `batida.m4a` (qubodup, CC0) tocados pelo JS via Web Audio (contexto nasce
      no 1º keydown/pointerdown); o Dart manda `som`/`pausado`/`acabou`/`faixa` em
      `atualizar` e só usa o ronco sintetizado quando o 3D não existe. O 7z do OpenGameArt
      abre com o `tar` do macOS (bsdtar lê 7-Zip); ffmpeg converte pra AAC.
    - **Rodada 3 (feedback "ainda atravessa / carros parados / quero moedas")**:
      - **Batida por CONTATO na faixa VISUAL** (`faixaVisual` = arredondamento de `xAtual`):
        a linha do pórtico não bate mais; bate quem encosta (|Δz| < 4,2 m) num carro à frente
        na mesma faixa física. Foi isso que resolvia o "atravessa": a versão anterior usava a
        faixa ALVO, então digitar em cima da hora passava por dentro do carro.
      - **Tráfego que anda** (`CarroTrafego`): parado no pórtico, arranca do zero quando o
        jogador chega a 25 m dele (`distanciaArranque`), acelera em 1,5 s até 32% da máxima
        (`fracaoTrafego`) — mas nunca acima de 45% da velocidade ATUAL do jogador
        (`fracaoDoJogador`), senão quem chega devagar na faixa errada nunca alcança o carro
        (visto no probe: 12 m/s contra 8,9 m/s do tráfego = zero batidas). Segue na faixa
        dele; quem passou deixa o carro pra trás (carro atrás nunca bate). Lição do traçado de
        testes: arrancar a 90 m fazia o tráfego do portal anterior parar na faixa do portal
        seguinte (10 batidas numa corrida limpa).
      - **Troca de faixa com folga** (`folgaTroca` = 14 m): a palavra do próximo portal só
        troca a faixa 14 m depois do pórtico anterior (`faixaPendente`), senão o jogador
        entrava em cima do tráfego recém-deixado. Lerp de `xAtual` subiu pra 8/s.
      - **Fichas de programação** (`Ficha`, `fichasDart`: `=>`, `{ }`, `;`, `??`, `...`,
        `async`…): 3 por portal, na faixa livre, a −34/−24/−14 m do pórtico (marcam o caminho
        certo); passar por cima na faixa delas (|Δz| < 3 m) = +3 moedas e +5 pontos. Moedas
        somam entre corridas (`turismo_moedas`) com bônus por medalha (15/30/50) e compram
        os carros da garagem (`CarroGt.preco`: AE86 80, Miata 140, NSX 260, Skyline 420;
        `turismo_comprados`; `ProgressoTurismo.comprarCarro`). HUD e fim mostram 🪙.
      - JS: tráfego segue `portais[k].carros[i].z` do Dart a cada frame (arremesso quando
        `batido`); fichas são discos dourados girando (`CircleGeometry` + CanvasTexture com o
        símbolo, `animarFichas`) que somem com faíscas douradas ao serem pegas.
      - **Cena por corrida**: `Vista3D` recebe `key: ValueKey('vista3d-$_corridaId')` — sem
        isso o State sobrevivia à troca de pista e a cena da 1ª pista (campina) ficava pra
        todas ("todas as fases com o mesmo cenário", visto pelo usuário na Rota do Vulcão).
        O `montar` novo religa o motor gravado (`ligarMotor` se o buffer já existe).
- **🐦 Prof. Dash — tutor de IA (jul/2026)** (`lib/features/tutor/`): chat que SEMPRE enxerga o
  estudo — `contextoDoEstudo(CursoState, TypingState)` empacota trilha/lição/resumo/teoria/o
  trecho digitado/saída esperada/precisão e VIAJA junto de cada pergunta (chip "👀 vendo: …"
  mostra ao aluno). Backend: **API do Gemini DIRETA**
  (`package:http`, POST generateContent, modelo **`gemini-flash-latest`** — alias que acompanha
  o flash mais novo; o gemini-2.5-flash foi APOSENTADO pra contas novas e derrubou a 1ª versão).
  ⚠️ **A CHAVE NUNCA VAI NO REPO NEM NO BUNDLE** (lição paga: a 1ª chave foi commitada no
  GitHub público e o Google a BLOQUEOU em horas — "reported as leaked"). Ela mora no Firestore
  em **`config/tutor`** (campo `chaveGemini`), legível SÓ por usuário logado (rules: write
  sempre false), buscada em runtime por `core/gemini/chave_gemini.dart` (cache em memória).
  **Rotacionar = criar chave nova no gcloud + PATCH no doc via REST autenticado — sem redeploy**:
  ```bash
  gcloud services api-keys create --project=pac-dart --display-name="..." \
    --api-target=service=generativelanguage.googleapis.com \
    --allowed-referrers="https://pac-dart.web.app/*,https://pac-dart.web.app./*,https://pac-dart.firebaseapp.com/*,http://localhost:*/*"
  curl -X PATCH "https://firestore.googleapis.com/v1/projects/pac-dart/databases/(default)/documents/config/tutor" \
    -H "Authorization: Bearer $(gcloud auth print-access-token)" -H "Content-Type: application/json" \
    -d '{"fields":{"chaveGemini":{"stringValue":"NOVA_CHAVE"}}}'
  ```
  A chave é RESTRITA por referer
  (incluindo **`https://pac-dart.web.app./*` com PONTO FINAL** — o usuário navega no FQDN e o
  browser manda esse referer, que é OUTRA origem — mais firebaseapp.com e localhost) E por API
  (só generativelanguage); testada com curl (200 no domínio, 403 fora).
  ⚠️ Tentativa anterior com `firebase_ai`/AI Logic exigia onboarding CLICADO no console
  ("AI logic config is missing") — abandonada; firebase_ai removido do pubspec.
  ⚠️ web/index.html NÃO pode ganhar `<meta name="referrer" content="no-referrer">` — a trava
  da chave depende do browser mandar a origem. UI: painel fixo à
  ESQUERDA em telas ≥1240px, senão botão flutuante (avatar Dash) que abre folha; markdown de
  bolso nas respostas (```dart → CartaoCodigo, `inline`, **negrito**); sugestões prontas;
  memória curta (últimas 6 mensagens). `GenerativeModel` criado LAZY na 1ª pergunta (testes e
  boot nunca tocam o Firebase); `TutorCubit.de(context)` null-safe (fluxo_test sem tutor não vê
  nada). ⚠️ O campo do chat convive com o TextField oculto do CodeView via `TextFieldTapRegion`
  (sem isso o onTapOutside do CodeView rouba o foco do chat).
- **Marca própria** (`lib/core/brand/logo_pacdart.dart`): o Pac comendo dois pontos — os mesmos que
  viram o "·" de PAC·DART. É **desenhada** (CustomPainter, caixa lógica 100×100), não imagem: fica
  nítida em qualquer tamanho e segue a paleta. `selo: true` põe a moldura arredondada (versão ícone).
  Favicon/PWA saem do MESMO desenho — regerar com
  `bash <scratchpad>/icones/gerar.sh web` (SVG → Chrome headless → PNG 512/192/64 + maskable).

- **🏎️ DART TURISMO — rodada 4: modo SETAS, 4 câmeras, carro visível no escuro, tela de carga (set/2026)**
  Pedido do usuário: "coloque uma possibilidade de jogar normal por seta, sem ser digitação" +
  "um carro preto no escuro desapareceu" + "câmeras diferentes" + "pode ir melhorando e
  implantando sem parar". Antes de mexer, um curso-relâmpago de boas práticas na web
  (Three.js: pixel ratio ≤ 2, poucas luzes, shadow map pequeno em celular, dispose; game feel:
  câmera com atraso suave, FOV abrindo com a velocidade, tremor só na batida; UX: jogo em < 60 s,
  feedback imediato; acessibilidade: modo sem digitação, menus rasos). O que entrou:
    - **`ModoControle` no motor** (`turismo.dart`): `digitacao` (o de sempre) ou `setas`.
      No modo setas `teclar()` vira no-op e `portalParaDigitar` é null; entram `virar(±1)`
      (troca de faixa NA HORA, sem a folga dos 14 m — quem muda em cima de um carro bate, e é
      justo) e `pedais(dt, gas:, freio:)` (aceleração .55·velMax/s, freio 1.4·velMax/s; sem gás
      o arrasto quadrático de sempre vai parando o carro). Passar o portal pela faixa livre
      conta `portaisLimpos++`, sobe o combo, dá 10×mult pontos e boost — o equivalente da
      palavra acertada. Tráfego, fichas, medalhas e moedas são idênticos nos dois modos.
    - **Página**: seletor "COMO DIRIGIR" (⌨️ Digitação / 🎮 Setas) no campeonato, salvo em
      `turismo_modo` (`ProgressoTurismo.modoSetas/escolherModo`). ⚠️ A corrida direta
      (`pistaInicial`) agora só larga DEPOIS de `_carregarCampeonato()` — senão o motor nascia
      no modo errado (o teste pegou). No modo setas não há `CampoTeclas`: o `Focus` raiz
      (`_foco`) segura o teclado (o `_tick` re-pede foco se um botão roubou) e trata ← → ↑ ↓
      (ou A D W S) em `_teclaGlobal`; `KeyDown` liga gás/freio, `KeyUp` desliga, repeat é
      ignorado. Botões na tela (`BotoesSetas`): ◀ ▶ por `onTapDown`, ▼ FREIO / ▲ GÁS por
      `Listener` (valem enquanto o dedo segura) — celular joga sem teclado. O cartão de baixo vira
      "FAIXA LIVRE ⬅ ESQUERDA · palavra · portal em X m · sua faixa: …". Placas 3D no modo
      setas (`tipo: 'seta'`): a SETA gigante com a palavra de legenda.
    - **4 câmeras** (`camerasGt` em `progresso_turismo.dart`, salva em `turismo_camera`; botão 🎥
      no HUD e tecla C no modo setas): `perseguicao` (atrás, atraso suave — padrão), `capo`
      (para-choque, rígida, FOV 66–82: a mais rápida), `cinema` (câmera de TV parada na beira da
      pista 48 m à frente, alternando lados, teleobjetiva com zoom pela distância — o carro passa e
      ela pula) e `alta` (helicóptero). `posicionarCamera()` no JS; as placas se reposicionam por
      câmera (capô: 16 m à frente e mais baixas; helicóptero: mais altas).
    - **Carro visível no escuro**: `luzCarro` (PointLight 26 à noite / 6 de dia) segue atrás e acima
      do carro; lanternas traseiras e faróis emissivos embutidos na carroceria (caixas
      MeshBasicMaterial na altura das lanternas reais); hemisfério .28 à noite; exposição
      espaço .95 / vulcão 1.05. Verificado por screenshot na Grande Final Sideral.
    - **Tela de carga real**: o JS expõe `api.progresso` (0.05 renderer → .2 → .45 céu → .85
      carro → 1 tráfego); o Dart mostra barra + etapa ("baixando o céu…", "construindo a pista e o
      carro…") com um `Timer.periodic` só enquanto não está pronto.
    - Testes: +3 no motor (pedais/freio, virar+portal limpo+combo, batida na faixa errada) e +2 de
      UI (modo setas sem TextField, ↑ anda, ← troca de faixa, C gira a câmera; seletor salva a pref).

- **🏎️ DART TURISMO — rodada 5: pistas 4× mais longas, rock por fase, cidade construída, engenheira de pista (IA), vento (set/2026)**
  Pedidos: "fases pelo menos 4 vezes o tamanho", "música de rock instrumental, diferente em cada
  fase", "cidade construída", "IA integrada" (o Gemini que já existe), "sensação de realismo".
    - **Pistas 4–12 km** (`distancia` ×4 em `pistasGt`; limites de tempo/portais/medalhas derivam
      dela, então escalaram sozinhos: 240 s na pista 1, 288 s na 10). ⚠️ Testes que contavam
      "60 s parado = tempo estourado" agora usam `pista.tempoLimite`. Com 48–64 portais por pista,
      o Dart manda ao JS por frame SÓ uma janela de portais (`_janelaDePortais`: do anterior ao
      5º à frente, cada um com `indice`) — antes mandava todos e virava lixo pro GC a 60 fps.
    - **🎸 Rock instrumental por fase**: 10 faixas do "Rock Music Pack" de Ragnar Random
      (OpenGameArt, **CC0**) em `web/assets3d/som/musica/NN_nome.m4a` (AAC 80 kbps, ~0,6 MB
      cada — baixadas com curl e convertidas com ffmpeg). `PistaGt.musica/tituloMusica`; o card da
      pista mostra "🎸 título"; botão "🎸 Rock ligado/desligado" no campeonato (pref
      `turismo_musica`). No JS: `carregarMusica(url)` (cache por URL, loop, ganho .28) toca quando
      o AudioContext nasce (1º gesto) ou quando a cena monta com ele já vivo; **ducking** pra .09
      por 1,8 s na batida (`duckAte` em `tocarBatida`); some no pause e no fim; `pararAudio`
      para tudo e zera `musicaUrl` (a próxima pista recarrega a dela).
    - **🌬️ Vento**: ruído branco em bandpass (300–1400 Hz) com ganho ∝ velocidade² — sensação
      de velocidade sem asset novo.
    - **🏙️ Cidade construída** (tema 3 `cidade: true` → `construirCidade()`): prédios
      procedurais dos dois lados seguindo as curvas (lotes a cada 26 m, 12% vazios), 3
      `InstancedMesh` por faixa de altura (11–16 m / 20–34 m / 38–64 m, pra janela não esticar),
      fachada e mapa de janelas acesas pintados em canvas (`texturaFachada`, 42% acesas em 3 tons),
      emissivo 1.1 à noite; telhado escuro por grupos de material; calçadas de concreto entre o
      guard-rail e os prédios. Custa 3 draw calls.
    - **🎧 Engenheira de pista (IA)** (`lib/features/arcade/data/engenheiro_gt.dart`): depois da
      corrida, `EngenheiroGt.debrief(TelemetriaGt)` manda a telemetria (pista, modo, medalha,
      tempo vs ouro, batidas, combo, precisão/portais limpos, fichas pegas) ao Gemini
      (`gemini-flash-latest`, a MESMA chave do Prof. Dash via `ChaveGemini`) com persona de rádio
      de equipe: ≤ 3 frases, um dado concreto + UMA dica + curiosidade de Dart sobre uma ficha.
      **Nunca trava a tela de fim**: sem chave/rede/429/corpo estranho → `debriefLocal` (regras
      simples + 20 curiosidades locais por ficha). Card "🎧 RÁDIO DA EQUIPE" no overlay de fim
      com spinner enquanto lê. `TurismoPage(engenheiro:)` injetável. 4 testes com `MockClient`
      + `FakeFirebaseFirestore` (`test/engenheiro_gt_test.dart`).

- **🏎️ DART TURISMO — rodada 6: qualidade Alta/Leve, tremor opcional, tutorial da 1ª corrida, minimapa (set/2026)**
  O usuário liberou carregamento mais longo em troca de qualidade ("o usuário está acostumado
  com loading"). Então:
    - **Presets de qualidade** (`qualidadesGt` auto/alta/leve, pref `turismo_qualidade`; no JS
      `resolverQualidade` — auto = leve só em tela de toque < 700 px): **alta** = HDRI **2k**
      (`hdri/<tema>_2k.hdr`, ~6,4 MB cada, Poly Haven CC0), texturas **1k** (`assets3d/tex1k/`,
      1–3,5 MB por material), sombra 2048, pixel ratio ≤ 2, anisotropia 16; **leve** = os 1k/512
      de antes, sombra 1024, pixel ratio ≤ 1,5. `web/assets3d` foi de 32 → 89 MB, mas cada corrida
      só baixa o céu + 3 materiais + o carro + a música dela (cache do browser depois).
      ⚠️ Hosting no plano Spark tem ~360 MB/dia de saída — ok entre amigos, atenção se viralizar.
    - **Tremor de câmera** desligável (pref `turismo_tremor` → `estado.tremor` no JS; a batida
      ainda mostra faíscas e som).
    - **Tutorial da 1ª corrida** (`widgets/tutorial_turismo.dart`), um por modo (prefs
      `turismo_tutorial_digitacao/_setas`): 3 cartões + "Entendi, largar! ↵" (Enter/espaço). A
      contagem 3-2-1 só monta DEPOIS dele; a cena 3D carrega por baixo enquanto isso.
      ⚠️ Testes de corrida direta precisam marcar o tutorial como visto nas prefs mock.
    - **Minimapa** (`widgets/minimapa.dart`): `tracadoDaPista(curvas)` integra o traçado com a
      MESMA fórmula do JS (`CURVA_RAD` .028, 8 m) — trecho feito acende, chegada xadrez, carro
      como bolinha; canto superior direito da vista. Teste do traçado em `turismo_test.dart`.
    - Seção "⚙️ OPÇÕES" no campeonato: 🎸 rock, 📳 tremor, qualidade Auto/Alta/Leve.

- **🏎️ DART TURISMO — rodada 7: prédios com fachadas fotográficas, cenário real por tema, pneu cantando (set/2026)**
  Pedido: "prédios mais reais, pode fazer download de fotos de prédio". Fontes CC0 encontradas
  pela API: **ambientCG** (materiais `Facade0xx` com cor + normal + rugosidade + **emissão** das
  janelas acesas — `https://ambientcg.com/get?file=Facade002_1K-JPG.zip`) e **Poly Haven**
  (`api.polyhaven.com/files/<id>` → `gltf.1k.gltf.url` + `include` com .bin e texturas; os
  modelos pequenos de 1–5 MB: shrub_03/04, rock_moss_set_01, tree_stump_01,
  namaqualand_boulder_04, rock_09, quiver_tree_02, boulder_01, dead_tree_trunk, moon_rock_01/03/05).
    - **Cidade**: `construirCidade()` agora gera 4 paredes por prédio (`parede()` = PlaneGeometry
      com **UV em metros** — `tile` é o tamanho real da foto: 24 m nas de vidro, 16 m na de
      tijolo, 48–64 m nas de arranha-céu noturno) e **funde** tudo de uma mesma fachada numa
      geometria só (`fundir()`, sem BufferGeometryUtils): 5 fachadas + telhados = **6 draw calls**
      pra 390 prédios, 60 fps. Deslocamento de UV por prédio pra vizinhos não acenderem as
      mesmas janelas; as fotos de arranha-céu viram torres de 40–82 m. Pastas
      `web/assets3d/fachadas/{1k,512}/<id>/{color,nor,rough,emis}.jpg` (Alta usa 1k).
    - **Cenário por tema** (`cfg.tema.cenario` → `construirCenario()`): modelos glTF reais
      instanciados ao longo da pista, normalizados pelo maior lado e sorteados em `tam` (metros,
      tabela `CENARIO_MODELOS`); 55% ficam na beira (4,5–13,5 m do guard-rail), o resto até 38 m.
      ⚠️ Um `InstancedMesh` da pista inteira desenha tudo sempre (bounding sphere gigante) —
      as instâncias são agrupadas por **trecho de 320 m** e `computeBoundingSphere()` deixa o
      frustum culling descartar o que está longe. Campina: arbustos/rochas/tocos; deserto:
      rochas + árvore-aljava; neve: rochas + troncos secos; vulcão/espaço: rochas lunares.
    - **Chão que acompanha o carro**: o plano de 4 km pulava fora nas pistas de 12 km — agora
      salta de tile em tile (`4000 / repChao`) atrás do carro, sem a textura deslizar.
    - **🛞 Pneu cantando** na troca de faixa (`derrapagem.m4a`, "Car tire squeal skid loop" de
      audible-edge, CC BY 3.0): fatia de 0,6 s do loop em posição aleatória, volume ∝ velocidade.
    - `web/assets3d` foi de 89 → 135 MB (tudo carregado por corrida, sob demanda). Créditos
      novos na tela do campeonato e em `CREDITOS.txt` de cada pasta.

- **🏎️ DART TURISMO — rodada 8: carro-fantasma, estatísticas e troféus (set/2026)**
    - **👻 Fantasma**: o motor grava `gravacao` (posição, x a cada 0,25 s — `VoltaFantasma.passo`)
      e no fim a melhor volta da pista vai pra pref `turismo_fantasma_N` (`serializar()`:
      `tempo|p,x,p,x…`, ~14 KB por pista). Na corrida seguinte a vista recebe `fantasma` e o JS
      clona o carro do jogador **antes** das lanternas/faróis (clonar luz = luz a mais),
      translúcido (opacity .34, emissivo azulado, sem sombra) e o move pelo relógio da corrida
      (`estado.tempo`). Chip "👻 FANTASMA −1,2s/+0,8s" no HUD = `tempo − fantasma.tempoEm(posicao)`
      (busca binária nas posições, que só crescem). Bater o fantasma mostra chip no fim e conta
      pro troféu.
    - **📊 Estatísticas** (`EstatisticasGt`, JSON em `turismo_stats`): corridas, chegadas, voltas
      limpas, palavras, fichas, batidas, melhor combo, fantasmas batidos, portais limpos, km,
      segundos — `somar(engine)` no `_fim` (também em tempo esgotado).
    - **🏆 12 troféus** (`trofeusGt`: condição sobre stats + campeonato): primeira bandeirada,
      ouro, volta limpa, combo x3, caça-fantasma, colecionador (100 fichas), mil palavras,
      maratonista (50 km), garagem cheia, meio campeonato, campeão, coleção dourada. Seção
      "TROFÉUS · n/12" no campeonato com os chips de stats; troféus novos aparecem no overlay
      de fim com fanfarra. Testes: gravação/fantasma (ida e volta pelo texto, tempoEm) e stats +
      troféus em `turismo_test.dart`; o teste de fim de corrida confere `turismo_stats`.

- **🏎️ DART TURISMO — rodada 9: cabeçalho dos jogos no celular (set/2026)**
  Prova em 400×800 (Playwright): o `CabecalhoJogo` (Row: voltar · título · chips · ação) espremia o
  título a 1 caractere de largura e empurrava 🎥/⏸ pra fora da tela; a vista 3D sobrava com 256 px.
  Agora, abaixo de 640 px, vira Column (voltar · título · ação na 1ª linha; chips numa linha
  própria) e, largo, os chips ficam num `Flexible` alinhado à direita. Vale pros 6 jogos.

- **🏎️ DART TURISMO — rodada 10: desempenho ("no Windows a opção de escrever vai travando") (set/2026)**
  Diagnóstico: a corrida era marcada `pronto` ANTES do tráfego carregar (`construirObstaculos`
  vinha depois), e as texturas 1k, os 4 carros do tráfego e a compilação dos shaders
  aconteciam nos primeiros segundos de corrida — no Windows o Chrome roda WebGL via ANGLE
  (GLSL→HLSL), onde cada material novo custa um engasgo no 1º frame em que aparece; somado ao
  preset Alta (dpr 2, sombra 2048) numa GPU integrada, dava "vai travando" logo no começo.
    - **Largada só com tudo pronto**: `LoadingManager` único (`gerente`) em TextureLoader,
      GLTFLoader e RGBELoader → `esperarCarregamento(30 s)`; depois `aquecer()` =
      `renderer.compileAsync` + 3 renders (com o tráfego visível) pra subir texturas/PMREM e
      compilar shaders; depois `medirDesempenho()` (mediana de 24 frames) e só então
      `api.pronto`. O Dart segura a **contagem 3-2-1 até `onPronto`** (`_cenaPronta`; sem 3D é
      imediato; timer de segurança de 60 s). Etapas novas na tela de carga ("baixando as
      texturas", "aquecendo os shaders e medindo a fluidez").
    - **Qualidade adaptativa em 3 níveis** (alta · leve · mínima): `sondarGpu()` lê
      `UNMASKED_RENDERER` num contexto descartável ANTES do renderer — SwiftShader/"software"
      → mínima (sem sombras, sem antialias, dpr 1) + aviso "sem aceleração de hardware";
      Intel HD/UHD, Mali, Adreno antigo → começa em leve. `medirDesempenho` (> 24 ms → leve,
      > 40 ms → mínima) e o `vigiarDesempenho` por frame (mediana de 150 frames > 26 ms →
      desce um nível, 6 s de calma) ajustam `aplicarQualidade` (dpr, sombras, tamanho do
      shadow map). Pill "⚡ Modo leve ativado automaticamente" nos 9 primeiros segundos.
      `debug()` mostra `gpu`, `frameMs` e `qualidade` efetiva.
    - **Menos trabalho por frame/tecla**: placas de palavra em canvas 768×240 (pintura lógica
      1024×320 via `setTransform`), minimapa repinta a cada 4 m, velocímetro por 0,4% e a
      bolinha do progresso em pixel inteiro; textura 4096 px do AE86 reduzida a 1024.

- **🏎️ DART TURISMO — rodada 11: placas legíveis, FOV por proporção, ficha com animação (set/2026)**
  Print do usuário numa tela larga e baixa (854×443 de vista): "tá muito pequeno de ler a
  letra na pista" e "a moeda não está pegando, precisa de uma animação".
    - **Placas de palavra com tamanho constante na tela**: em `posicionarPaineis` a escala vem
      da distância da câmera e do FOV (`visW = 2·d·tan(fov/2)·aspect`; a placa ocupa 36% da
      largura da vista, 31% cada quando há duas) — antes eram 4,4 m fixos a 12–14 m da câmera,
      ~14 px de letra em tela pequena. Duas placas vizinhas grandes se afastam cada uma pro seu
      lado (`sep = max(3,7·Δfaixa, largura+0,4)`); sobem 0,55 m por unidade de escala.
    - **FOV pela horizontal** (`fovVertical(h)`): os FOVs eram verticais fixos (62–76°), o que
      em janela 1,93:1 virava >100° horizontais — carro e placas minúsculos. Agora perseguição
      83°+16·v, capô 88°, helicóptero 69°, cinema 26–78° horizontais → vertical pela proporção
      (limitado a 40–82°).
    - 🐛 **Bug sério achado de tabela (desde a rodada 5)**: a janela de portais mandada por
      frame usava `Portal.indice` — que é o índice do SEGMENTO (`z / 8`: 93, 104, 114…), não a
      posição na lista — tanto pra recortar a janela (`getRange(91, 99)` com o carro no portal
      0) quanto pro JS achar `portais[indice]` (undefined → `continue`). Efeito: tráfego parado
      no pórtico, placas sem ✓/batida e fichas que não sumiam ("a moeda não está pegando").
      Agora o motor tem `ordinalDoPortalAtual` + `janelaDePortais()` (lista de `(k, portal)`,
      testada) e o JS sincroniza por `k`. ⚠️ Lição: `indice` de portal ≠ posição no array.
    - **Ficha pega com festa**: `coletarFicha()` — a moeda voa 2,4 m girando, cresce e some
      (0,55 s), 52 faíscas, sprite "+3 🪙" subindo (pool de 6, tamanho constante na tela) e o
      chip MOEDAS do HUD pulsa (`_chipPulsante`, TweenAnimationBuilder com key pelo valor).
      No motor a coleta virou tolerância lateral (`alcanceLateralFicha` 2,3 m do centro da ficha)
      em vez da faixa arredondada — pega enquanto desliza entre faixas (teste novo).

- **🏎️ DART TURISMO — rodada 12: câmera estável, placa mais alta, rock de verdade (set/2026)**
  Feedback: "pode ficar um pouco pra cima pra não atrapalhar ver o carro", "tem muita mudança de
  câmera, precisa estabilizar por bom tempo" e "a música precisa ser um rock com mp3, esse som de
  video game é horrível".
    - **Câmera**: zoom (FOV), distância e altura seguiam a velocidade INSTANTÂNEA — e no modo
      digitação cada palavra dá um impulso, então a vista "respirava" a cada 2–3 s, mais o pulso
      de zoom do turbo. Agora tudo segue `fracaoSuave` (filtro exponencial, τ = 1,8 s), sem pulso
      do turbo; tremor da batida menor (.2); cinema corta só 45 m depois de o carro passar e
      escolhe o ponto 95 m à frente (um corte a cada ~140 m em vez de 60), com zoom filtrado.
      Medido: FOV variando 0,4°/frame no máximo enquanto se digita palavra atrás de palavra.
    - **Placas** 1 m mais altas (3,0 m + 0,8 por unidade de escala): o carro e a ficha ficam
      inteiros abaixo delas.
    - **Música**: o "Rock Music Pack" (fakebit) saiu. Entraram 10 instrumentais de rock com
      guitarra/baixo/bateria de **Kevin MacLeod** (incompetech.com, **CC BY 4.0** — crédito no
      jogo e em `CREDITOS.txt`): Cool Rock, Hotrock, Big Rock, Delay Rock, Neolith, Exhilarate,
      Riptide, Ready Aim Fire, Metalmania, Summon the Rawk (pistas 1–10). Catálogo em
      `https://incompetech.com/music/royalty-free/pieces.json` (genre "19" = rock; mp3 em
      `.../mp3-royaltyfree/<filename>`). Reencodadas sem a capa embutida (~3–5 MB cada).

- **🏎️ DART TURISMO — rodada 13: máquina fraca de verdade ("dá umas travada ainda", nível mínima) + volume (set/2026)**
  O console do usuário mostrou `qualidade: minima` logo na carga — a medição de frames viu
  > 40 ms ANTES de a cena rodar (só o Flutter + overlay), ou seja, máquina bem fraca.
    - **Benchmark real da GPU** (`benchmarkGpu`, ~0,3 s, renderer descartável com 24 esferas
      texturizadas e 3 luzes) decide o nível no `auto` ANTES de baixar céu 2k/texturas 1k:
      > 34 ms → mínima, > 19 ms → leve. `api.benchMs` no `debug()`.
    - **Perfis por nível** (`PERFIS`): mínima = sem cenário instanciado (arbustos com alpha =
      overdraw caro), sem luz de acompanhamento/faróis/postes, tráfego desenhado só a 150 m;
      leve = tráfego a 240 m. `aplicarQualidade` aplica em tempo real (o vigia também rebaixa).
      Gancho `turismo3d.forcarQualidade('minima')` pra testar.
    - **Música em streaming**: `<audio loop>` (`prepararMusica/tocarMusica/atualizarMusica`) no
      lugar de `decodeAudioData` — cada mp3 de 3–5 min decodificado virava ~80 MB de RAM (e o
      cache guardava um por pista visitada). Volume 0,6 (ducking 0,22 por 1,8 s na batida), fade
      no pause. Amostras curtas (motor/batida/pneu) decodificadas na tela de carga
      (`carregarAmostras`, AudioContext nasce suspenso e acorda no 1º gesto).
    - **Balanço de áudio**: motor 0,045 + 0,10·v (era 0,10 + 0,22·v), vento pela metade.
    - **HUD a 30 Hz**: `Vista3DControlador` — a página manda o estado do motor pro JS a cada
      tick (`_vista.enviar()`) e só chama `setState` a cada 2 frames (ou em batida/ficha/fim).
      Metade do trabalho do CanvasKit, que pesa em GPU fraca.

- **🏎️ DART TURISMO — rodada 14: corrida mais larga no desktop, probe do app logado e material de portfólio (set/2026)**
    - A vista da corrida vai a **1400 px** no desktop (era presa a 920 px com faixas pretas
      enormes em 1920); o campeonato continua em 920.
    - `lib/main_portfolio_probe.dart`: o app inteiro SEM Firebase (usuário fake logado,
      `LocalProgressoRepository`, ranking em memória, Prof. Dash de mentira que responde em
      streaming) pra fotografar telas: `flutter build web -t lib/main_portfolio_probe.dart
      --output=build/probe_app --no-tree-shake-icons --no-wasm-dry-run` + `python3 -m http.server
      8789 --directory build/probe_app`. ⚠️ O `--no-wasm-dry-run` importa: a checagem wasm ficou
      TRAVADA (1 s de CPU em 10 min) duas vezes seguidas; e o tree-shake de ícones falhou com dois
      builds em paralelo.
    - Pasta `portfolio/` (gitignored): 19 PNGs 1920×1080 (corrida em vários mundos/câmeras, ficha
      sendo pega, tutorial, celular, fim de corrida com a engenheira, campeonato, hub, lição, mapa,
      projeto com prévia ao vivo, tutor, quiz, login), `PAC-DART-resumo.pdf` (gerado do
      `resumo.html` com Chrome headless `--print-to-pdf`) e `README.md` com legenda de cada imagem
      e os créditos. Receita das fotos: injetar prefs no localStorage COM JSON (`flutter.<chave>`
      = `JSON.stringify(valor)`; lista = array JSON, não string dupla — senão `getStringList`
      lança e `carregar()` devolve tudo vazio), ligar a semântica (`flt-semantics-placeholder`),
      dirigir com um robô que lê "faixa livre"/"sua faixa" dos aria-labels e aperta ←/→.
    - 🐛 Achado nas fotos: com o combustível pela metade e o portal ainda sem palavra, o cartão
      mostrava "✓ undefined marcada" (índice −1 em dart2js sem checagem). Agora diz "⛽ COMBUSTÍVEL
      · termine a palavra, depois vem a do portal".

- **🏎️ DART TURISMO — rodada 15: "trava muito" mesmo em mínima → o que pesava de verdade (set/2026)**
  Medição com `renderer.info` (novo `debug().render` e `composicao()`): a campina desenhava
  **931 draw calls e 13,4 MILHÕES de triângulos por frame** (cidade: 744 / 2,3 M). Culpados:
  os modelos do Poly Haven são pesados (shrub_04 27k, rock_moss_set 63k, tree_stump 41k, boulder
  66k, dead_tree_trunk 102k triângulos cada) × 450–650 instâncias em lotes de 320 m sempre
  visíveis; postes de luz clonados (30k triângulos × 93); 3 malhas por pórtico × 64; carros
  do Sketchfab em 15–38 malhas cada. Até no nível mínima sobravam ~500 draw calls.
    - **Cenário**: densidade ~metade (passo 16–30 m), pesos puxados pros modelos leves, lotes de
      **160 m ligados por distância a cada frame** (`cularPorDistancia`: alta até 420 m, leve até
      240 m e só a metade A das instâncias, mínima nada).
    - **Postes**: `InstancedMesh` por malha e por trecho de 160 m (culling por distância) +
      um InstancedMesh só pros bulbos.
    - **Pórticos**: postes e vigas de TODOS os portais fundidos em 2 malhas (`fundir`).
    - **Carros**: `fundirPorMaterial` no `carregarCarro` — funde as malhas por material (só
      position/normal/uv, não indexado) e esconde as originais: ~27 → ~15 draw calls por carro;
      tráfego desenhado a 260/200/150 m por nível.
    - **Mínima** renderiza a 75% da resolução (preenchimento é o gargalo em GPU integrada);
      sombra do cenário só no alta; poste de luz procedural (~150 tris) fora do alta.
    - Resultado (M2, 1366×700): campina alta 931 → ~500 draw calls e 13,4 M → ~3,9 M triângulos
      contando a passagem de sombra (~1,9 M na cena); cidade leve 744 → ~270 draw calls, 2,3 M →
      ~0,7 M triângulos, 60 fps; mínima ~255 draw calls / 0,7 M. ⚠️ Lição: medir
      `renderer.info` ANTES de otimizar — a "qualidade mínima" antiga cortava luzes e sombras
      mas deixava 500 draw calls e o cenário de 13 M de triângulos no leve.

---

## 📲 Lojas (Google Play / App Store) — EM ANDAMENTO (11/out/2026)

**Decisão do dono:** publicar nas duas lojas, sob o nome **Paclingo**, ID definitivo **`com.carlos.paclingo`** (escolhido pelo dono em 11/out/2026; Android
`applicationId`/`namespace` e iOS `PRODUCT_BUNDLE_IDENTIFIER`). Para trocar de novo ANTES do 1º upload: `python3 tool/trocar_id.py <novo.id>` (depois de publicado o ID
não muda). Apps registrados no Firebase `pac-dart`: `Paclingo (Android)` `1:932071268596:android:973258f499eba20a8c3ea1` e `Paclingo (iOS)`
`1:932071268596:ios:e95e7372a1df930b8c3ea1` (os provisórios `com.seunome.*` foram removidos); os SHA-1/SHA-256 da chave de upload estão cadastrados no app Android.

**Feito (passos 1 e 2):**
- **Nome visível → Paclingo:** HUD (`PAC`+`LINGO` colorido, a linha de baixo é o curso), login, ranking, hub/arcade, título do
  MaterialApp (`Linguagem.nomeApp` = "Paclingo · <curso>"), cartões da escolha de trilha (`Linguagem.marca`: DART / C# / INGLÊS),
  personas do Prof. Dash e da engenheira de pista, `web/manifest.json`, `web/index.html`, `pubspec.yaml`. Comentários internos
  continuam falando PAC·DART/PAC·C#/PAC·ENGLISH (são os nomes de trabalho das vertentes). **Não mudou:** projeto Firebase
  `pac-dart`, URL `pac-dart.web.app`, nome do pacote `pac_dart`, chaves de progresso/Firestore, classe `LogoPacDart`.
- **`android/` e `ios/` gerados** com `flutter create --platforms=android,ios --org com.seunome . (e o ID virou com.carlos.paclingo depois)` (nenhum arquivo existente foi
  alterado, só `.metadata`) e depois ajustados: ID, rótulo "Paclingo" e `INTERNET` no manifesto principal (o gerador só põe nos de
  debug/profile; sem isso o release não fala com Firebase/Gemini).

- **Logo/ícones (11/out/2026, 4ª versão — a "limpa"):** o dono testou 3 logos geradas por IA e pediu uma versão mais limpa da 3ª
  (a do Pac de boné + fantasma + labirinto, "paclingo — The Language Chase"). A atual foi redesenhada em vetor: fundo azul-marinho com moldura
  neon turquesa→roxa, "pac" amarelo + "lingo" turquesa (fonte Fredoka 700, embutida no SVG), Pac de boné virado para trás, e um ponto + "A" + "文"
  (o que ele "come"). SEM fantasma e SEM labirinto. Fonte editável: `branding/paclingo-limpo.svg` (autossuficiente; para rasterizar:
  Chrome headless `--screenshot --window-size=1024,1024 --force-device-scale-factor=1 file://…/paclingo-limpo.svg`) → original dos ícones:
  `branding/paclingo-logo.png` (1024×1024, quadrado cheio, sem transparência). As anteriores estão em `branding/outras-versoes/`
  (v2 mascote azul-bolha, v3 boné+fantasma; a v1, pássaro turquesa, só existe no histórico da conversa). Para voltar a uma delas: copiar para
  `branding/paclingo-logo.jpg`, apagar o `.png` (o script prefere o png) e rodar o gerador — ele preenche sozinho os cantos brancos arredondados
  dessas versões.
  `swift tool/gerar_icones.swift` (na raiz) gera TODOS os ícones: web (`favicon.png`, `icons/Icon-*.png`, maskable com margem de 20%), Android
  (`mipmap-*/ic_launcher.png` + adaptativo: `ic_launcher_foreground.png` a 60%, `values/ic_launcher_background.xml` `#0D133C`,
  `mipmap-anydpi-v26/ic_launcher.xml`), iOS (todo o `AppIcon.appiconset`, PNG sem transparência) e os de loja em `branding/`
  (`play-store-512.png`, `app-store-1024.png`).
  ⚠️ **Propriedade intelectual:** a v3 usava o Pac-Man e o fantasma vermelho (Blinky) da Bandai Namco; a atual tira o fantasma mas o Pac
  continua sendo um círculo amarelo com boca em cunha. As lojas (Apple 5.2.1, Google Play "Intellectual Property") podem barrar ou
  derrubar o app; os textos de loja não devem dizer "Pac-Man". Alternativa segura: a v2 (mascote próprio). Decisão do dono.
  Dentro do app: o login e a escolha de trilha usam a imagem (`LogoPaclingo`, `assets/brand/paclingo-logo.png` 512 px); o HUD e a splash do `index.html` seguem com o Pac desenhado (`LogoPacDart`) + "PACLINGO".

**Feito depois (11/out/2026, fases de publicação):**
- **Firebase nativo:** apps `Paclingo (Android)` e `Paclingo (iOS)` registrados no projeto `pac-dart` (`firebase apps:create`); `lib/firebase_options.dart`
  ganhou `android` e `ios`. O app abre no simulador do iPhone com o Firebase de verdade (testado).
- **Som no celular:** `core/som/sintetizador.dart` (WAV em Dart puro, a mesma "partitura" da web; testado em `test/sintetizador_test.dart`) +
  `som_nativo.dart` (audioplayers, `AudioPool`; motor do Dart Turismo em laço com `playbackRate`). Import condicional de 3 vias em `sons.dart`
  (`stub` / `js_interop` → web / `io` → nativo); no desktop e na VM de teste o nativo fica inerte (`Platform.isAndroid || isIOS`).
- **Inglês no celular:** `ingles/data/fala_nativo.dart` (gravações Tatoeba/voz Google via audioplayers + voz do sistema via flutter_tts, mesma escolha
  de voz do navegador), `reconhecedor_nativo.dart` (speech_to_text), `core/util/abrir_url_nativo.dart` (url_launcher; créditos do Tatoeba).
  Permissões: `RECORD_AUDIO` + `<queries>` (RecognitionService, TTS_SERVICE) no Android; `NSMicrophoneUsageDescription` e
  `NSSpeechRecognitionUsageDescription` no iOS. DartPad embutido e Three.js seguem só na web (o celular usa o plano B / a vista em Canvas).
- **Tutor no celular:** `tutor/data/tutor_firebase_ai.dart` (`firebase_ai` 2.3, Gemini Developer API **pelo Firebase AI Logic**, sem chave no app).
  Configurado por REST: a chave "Gemini Developer API key (Firebase AI Logic)" (restrita a `generativelanguage`) foi criada com `gcloud` e gravada em
  `projects/pac-dart/locations/global/config` (`generativeLanguageConfig.apiKey`). Testado com curl: HTTP 200 (`gemini-flash-latest`; o
  `gemini-2.5-flash` não existe mais para projetos novos). Usa a cota GRATUITA (sem billing). O web segue no `GeminiTutorService`. Falta App Check.
- **Excluir conta:** `auth/data/exclusao_de_conta.dart` + `presentation/excluir_conta_dialog.dart` (menu do avatar). Ordem: senha → apaga `users/{uid}` e
  `ranking/{uid}` (lote) → apaga o login. `firestore.rules` ganhou `delete` no ranking (**só vale depois de `firebase deploy --only firestore:rules`**).
  Testes em `test/auth_test.dart`.
- **Privacidade:** `web/privacidade.html` e `web/excluir-conta.html` (placeholders `[SEU NOME OU EMPRESA]`/`[SEU E-MAIL DE CONTATO]` a preencher).
- **Assinatura Android:** `android/key.properties` (fora do git) + `~/.paclingo/upload-keystore.jks` (alias `upload`); `build.gradle.kts` assina o release com ela
  (sem o arquivo, cai na chave de debug). `flutter build appbundle --release` → 153,7 MB.
- **Lojas:** `branding/lojas/` — `google-play.md`, `app-store.md`, `CHECKLIST.md` e capturas (`ios/` 1320×2868 e `android/` 1080×1920, tiradas do build
  `main_portfolio_probe` com Playwright). `tool/trocar_id.py` troca o ID do app em todos os arquivos.
- **Publicado em 11/out/2026:** `firebase deploy --only hosting,firestore:rules` (site Paclingo + regra de `delete` no ranking). As páginas `privacidade.html`/`excluir-conta.html` foram
  RETIRADAS do `build/web` antes do deploy (placeholders de contato); gráfico do Play em `branding/lojas/grafico-play-1024x500.(svg|png)`.
- **Ainda não feito / com o dono:** ver `branding/lojas/CHECKLIST.md` (ID real, contas, Team do Xcode, marcas de terceiros, deploy, teste em aparelho real,
  gráfico de recursos 1024×500 do Play, App Check).

---

## 🏗️ Arquitetura (arquivos-chave)

```
lib/
  main.dart                     # gate de auth ACIMA do MaterialApp; ThemeCubit+AuthCubit no topo
  core/theme/
    mixart.dart                 # Paleta (3 temas) + Mixart.* (getters dinâmicos!) + tema()
    theme_cubit.dart            # troca/persiste a paleta
    seletor_tema.dart
  core/brand/logo_pacdart.dart  # a marca (CustomPainter) — HUD, login e ícones
  core/syntax/tokenizer.dart    # destaque de sintaxe
  core/util/codigo_executavel.dart  # gera código rodável (botão copiar)
  features/auth/                # AppUser, AuthRepository (FirebaseAuth), AuthCubit, LoginPage
  features/curso/
    domain/curriculo.dart       # Trilha, Licao, Trecho, BlocoTeoria, Projeto
    data/                       # CurriculoLoader, ProgressoRepository (Local + Firestore)
    presentation/
      bloc/                     # CursoBloc, TypingBloc, VozCubit
      fluxo_licao.dart          # sequência lição → quiz → Mão na Massa → próxima lição
      pages/                    # home_page, mapa_page, teoria_page, quiz_page, projeto_page
      widgets/                  # code_view, hud, menu_trilhas, dica_banner, console_view,
                                # preview_panel, preview_ao_vivo, fundo_fase, pacman, victory_overlay,
                                # botao_pular
  features/dartpad/             # DartPadPage + iframe do dartpad.dev (embed_web / embed_stub)
                                # + mapa_rodavel.dart (lê assets/roda.json)
  features/habito/              # domain/habito (sequência, meta, congelamento — puro) · data/habito_repository (Local + Firestore) ·
                                # presentation/habito_cubit + widgets/chip_sequencia + sequencia_sheet
  features/ranking/             # domain/jogador_ranking (critérios+ordenação) ·
                                # data/ranking_repository (Firestore `ranking/{uid}`) ·
                                # presentation/ranking_cubit (deltas+pendências) + ranking_page (pódio)
  features/arcade/              # domain: desafio, banco_desafios (76), baralho (níveis por fase), turismo (10 pistas + motor), progresso_turismo, palavras_dart (93),
                                #   corrida/futebol/caca_bug/tiro_engine, digitar_palavra
                                # presentation: arcade_page (hub) + 6 jogos (turismo, corrida, futebol,
                                #   caca_bug, chuva, rali) + widgets (arcade_ui, campanha [pausa+fases],
                                #   perspectiva, pista3d, pista_gt [VistaCorrida], gol3d, cenario [PalcoFase], avatares, campo_teclas)
  features/preview/             # interpretador próprio (parser + widget_builder) + preview_engine
  firebase_options.dart         # gerado por flutterfire configure
assets/  curriculo.json · master.json · backgrounds/ · fonts (google_fonts em runtime)
```

Estado: `flutter_bloc`. Cores via `Mixart.*` (getters que seguem `Mixart.atual`).

---

## 🔥 Hábito diário — Fase 1A (12/out/2026, FEITA; sem commit/deploy)

Sequência de dias (🔥), meta do dia em exercícios, congelamento (❄️) e as telas. Plano: `planejamento/FASE-1-HABITO-DIARIO.md`.

**O que a pessoa vê:** chip no HUD (anel de progresso + 🔥 + dias; cinza com o convite "Comece hoje" quando não há sequência — nunca "0 dias";
borda realçada quando a sequência está viva e hoje ainda sem meta); toque abre a folha "Sua sequência" (chama, dias seguidos, progresso de
hoje, melhor, ❄️ n/2, últimos 14 dias feito/congelado/perdido, seletor Leve 10 · Normal 20 · Forte 40); aviso "Meta de hoje batida! 🔥 N dias"
(SnackBar, 1× por dia, sem som).

**Decisões D1–D8 (todas seguidas):** D1 uma sequência por conta (Dart+C#+Inglês; o `HabitoCubit` vive ACIMA de `_cursoDe`, em `main.dart`/`_comHabito`) ·
D2 o dia conta ao bater a meta · D3 unidade = exercício concluído (ganchos abaixo) · D4 dia = dia local inteiro (`diaDe` == `Revisao.dia`), relógio que volta é ignorado ·
D5 só no cliente, nunca no ranking (teste prova que nenhuma chave do hábito vai ao ranking) · D6 campo `habito` (mapa) em `users/{uid}` + cópia local
(`habito_v1:{uid}`); **`firestore.rules` intacto** · D7 offline-first: emite na hora, grava sem bloquear (coalescendo), mescla aparelho × nuvem ·
D8 +1 ❄️ a cada 7 dias (máx. 2); cobre os dias perdidos só se houver congelamentos para TODOS; recomeçar não gasta congelamento.
Padrões das "perguntas em aberto": metas 10/20/40 com Normal=20, arcade não conta, hábito fora do ranking.

**Ganchos de contagem (`HabitoCubit.de(context)?.praticou()`; no-op sem o cubit):** trecho de Dart/C# digitado até o fim (listener de `concluido` em `home_page.dart`,
`_Palco`) · cada passo da escada do inglês (`PalcoIngles._avancar`, **sem** a cópia de correção) · Mão na Massa digitado (`projeto_page.dart`) · pergunta de quiz
respondida (`quiz_page.dart`, clique ou digitando; 1× por pergunta) · revisão do inglês: frase digitada (1ª tentativa) e cartão (1ª nota) em `abrirRevisao`
(`fixacao.dart`); o "DE NOVO" do Errei NÃO conta. Não contam: arcade, pular, voltar, nivelamento, treino de memória da lição, criar texto/cartão.

**Arquivos novos:** `lib/features/habito/domain/habito.dart` (modelo puro, `RegrasHabito`, `diaDe`, `registrar`/`mudarMeta`/`mesclar`/JSON tolerante) ·
`data/habito_repository.dart` (`LocalHabitoRepository`, `FirestoreHabitoRepository` — Firestore acessado só ao ler/gravar, então testes sem Firebase seguem no aparelho) ·
`presentation/habito_cubit.dart` · `presentation/widgets/chip_sequencia.dart` (+ `AnelDaMeta`, `Chama`) · `widgets/sequencia_sheet.dart`.
**Editados com cirurgia:** `lib/main.dart` (`habitoBuilder`, `habitoAgora`, `_comHabito`), `lib/main_portfolio_probe.dart` (`LocalHabitoRepository`), `hud.dart` (o chip, 1ª posição do Wrap
de botões), `home_page.dart`, `palco_ingles.dart`, `fixacao.dart`, `quiz_page.dart`, `projeto_page.dart` (1 linha de gancho cada) e `test/app_smoke_test.dart` (2 pumps antes de tocar em "Mapa":
o chip deixa o HUD uma linha mais alto na janela 800×600 e a rolagem automática do campo ignorava o toque).

**Testes (+111):** `habito_test` (44: domínio em tabelas, `diaDe`, congelamento, relógio, mesclar comutativa/idempotente, JSON) · `habito_repository_test` (16: local, Firestore fake sem apagar outros campos,
mescla, sem rede, exclusão de conta leva o hábito) · `habito_cubit_test` (13) · `habito_ui_test` (28: chip nos estados, aviso 1×, folha, 14 dias, meta, 360/390/1027 px, tema claro, ganchos Dart/quiz/projeto) ·
`habito_app_test` (10: app inteiro — inglês, Dart, troca de curso mantém, reabrir, virada do dia, ranking sem hábito). Validado por 16 mutações (>=→>, relógio, congelamento no recomeço, "DE NOVO" contando, mescla sempre remota, etc.).
Prova em Chrome real (probe, 1027 e 390 px, virada do dia com `page.clock`): sem erro no console.

⚠️ Pendências: **1B (lembrete)** feita depois (ver "🔔 Lembrete diário"); o treino de memória da lição e o nivelamento não contam (decisão); `home_page.dart:380` (barra de progresso do Dart) estoura ~2 px a 390 px com a fonte de TESTE (problema antigo, fora do hábito).

---

## 🎧 Ditado — Fase 3 (parte 1: "Áudio → escrever", 13/out/2026, FEITA; sem commit/deploy)

Novo sentido do cartão inglês → português: `SentidoCartao.audio` (id `audio`, rótulo "🎧 Áudio → escrever"), ao lado de EN → PT / PT → EN / Misturado.
A frente do cartão é SÓ o áudio ("🎧 Ouça e escreva", sem nenhum texto da frase) e toca sozinho ao abrir; a pessoa escreve em inglês o que ouviu
e vale em todos os níveis (Fácil = blocos em inglês, Médio = lacunas, Avançado = escrever, Só virar). Depois de virar aparecem o inglês, a tradução e as 4 notas
(a nota sugerida vem da conferência por palavra, como sempre). Funciona com frase sem tradução. Tecla R ouve de novo; 🔊 e 🐢 na frente. "Misturado" NÃO sorteia o ditado.
Usa os mesmos cartões `~r` e a mesma agenda FSRS (a nota do ditado é a nota do cartão — decisão: sem cartão novo por enquanto).
Arquivos: `domain/nivel_resposta.dart` (enum) e `presentation/sessao_cartoes_page.dart` (`_audioAtual`, `soAudio`, instrução, autoplay, tecla R) — edições pontuais em arquivos já sujos.
Testes: `test/ingles_ditado_test.dart` (12) + 5 mutações pegas (texto na frente, sem autoplay, responder em português, tecla R). Chrome real (probe 1027/390 px): ok, 0 erros.
**Fase 3, parte 2 (shadowing): FEITA em 13/out/2026** — ver a seção "🗣 Shadowing" abaixo.

---

## 💡 "Por quê?" + cota/cache de IA — Fase 2A (13/out/2026, FEITA; sem commit/deploy)

Plano: `planejamento/FASE-2-EXPLIQUE-E-CENARIOS.md` (a 2B, cenários guiados, veio depois).

**O que a pessoa vê (só Inglês):** depois de errar ou tropeçar, um botão **"💡 Por quê?"** (com "restam N usos hoje") pede ao Prof. Dash uma explicação curta em português
do erro daquela resposta; ela aparece num cartão "🐦 Prof. Dash" logo abaixo (mini-markdown: **negrito**, *itálico*, `código`). Onde aparece: palco (passo de memória que errou/hesitou — a cópia
de correção não), revisão digitada (`SessaoMemoriaPage`) e cartões de virar (`SessaoCartoesPage`, só se respondeu e não foi idêntico; "Não sei" não). Cota esgotada ⇒ "Por hoje o Prof. Dash
descansou — amanhã tem mais 🐦" e o estudo segue. Falha de rede ⇒ aviso + "Tentar de novo", **sem gastar**.

**Decisões D1–D11 (seguidas):** só Inglês · reaproveita `TutorService.perguntar` (interface intacta; pedido começa com `PEDIDO: explicar um erro`) · cota por pessoa/dia em `users/{uid}.ia_cota` + cópia local
(`ia_cota_v1:{uid}`), padrão do hábito, `firestore.rules` intacto · cota **macia/forjável** (a chave do Gemini viaja no cliente na web; a trava real é a cota do projeto no Google; cota dura = Cloud Functions, fora do escopo) ·
dia = `diaDe` (relógio que volta é ignorado) · cache local (`ia_cache_v1:{uid}`, 100 entradas, a mais antiga sai; chave = hash de versão|frase|resposta|palavras erradas|exercício|desistiu) · erro/vazio não gasta nem guarda ·
resposta cortada em 300 letras e marcada como DADO no prompt (anti-injeção) · IA nunca mexe em nota, agenda nem ranking (teste prova). Padrões das perguntas em aberto: limite 30/dia; "Por quê?" só em erro/hesitação.

**Arquivos novos:** `lib/features/ia/domain/{cota_ia,explicacao}.dart` · `data/{cota_repository,cache_explicacoes}.dart` · `presentation/ia_cubit.dart` (cache → cota → serviço; dedup de pedidos iguais; reserva do uso antes de chamar,
então pedidos simultâneos não passam do limite) · `presentation/widgets/botao_por_que.dart`.
**Editados com cirurgia:** `main.dart` (`iaCotaBuilder`/`iaCacheBuilder`/`iaAgora`, `_comIa` ao lado do `HabitoCubit`, acima dos cursos) · `main_portfolio_probe.dart` (cota local + o `_TutorFake` reconhece o pedido) ·
`palco_ingles.dart`, `sessao_memoria_page.dart`, `sessao_cartoes_page.dart` (o botão + `_pedidoPorQue`).
Divergências do plano: na digitação não existe "resposta escrita" (o motor só aceita a tecla certa), então o pedido leva as PALAVRAS que tropeçaram e se desistiu; não criei atalho de teclado (o botão é focável).

**Testes (+57):** `ia_cota_test` (11: cota em tabela, mesclar, JSON, pedido/chave/corte/anti-injeção) · `ia_repository_test` (13: local, Firestore fake sem apagar outros campos, mescla, sem rede, exclusão de conta leva `ia_cota`, cache de 100) ·
`ia_cubit_test` (15) · `ia_ui_test` (12) · `ia_app_test` (6: app inteiro — palco, cache depois de reabrir o app, cota esgotada, falha, revisão digitada). 14 mutações pegas (cache gastando, falha gastando, não zerar na virada, mesclar menor,
limite, sem corte, botão ao acertar, sem dedup, sem reserva, cache sem gravar, chave sem resposta, sem marca de dado, sem `_comIa`); a "botão na cópia" é equivalente (o widget já se esconde sem erro). Os testes pegaram um deadlock real
(`whenComplete` devolvendo o próprio Future). Chrome real (probe, 1027 e 390 px): ok, 0 erros.
⚠️ Pendências: a Fase 3 shadowing segue não feita (a 2B foi feita depois: seção "💬 Cenários guiados").

---

## 💬 Cenários guiados — Fase 2B (13/out/2026, FEITA; sem commit/deploy)

> ⚠️ **Evoluída na Fase 10 (21/out/2026):** virou "💬 Conversa com IA" — o feedback do fim (2ª chamada, `pedidoDeFeedback`,
> `FeedbackCenario`, `FeedbackCenarioView`) e a persona "NÃO corrija" **não existem mais**. O texto abaixo é o histórico da 2B; o estado
> atual está em "💬 Conversa com IA — Fase 10".

Plano: `planejamento/FASE-2-EXPLIQUE-E-CENARIOS.md` (etapas 7–10). Só Inglês; por TEXTO (voz fica para depois — o reconhecedor do dono ainda não está commitado).

**O que a pessoa vê:** no Mapa, o card **"💬 Conversar com o Prof. Dash"** (ao lado de "Baralhos e cartões"; some sem a IA) → lista de **8 cenários por etapa**
(`assets/ingles/cenarios.json`: Pedir um café A1 · Check-in no hotel, Pedir direções, Na farmácia A2 · Entrevista, Reunião de equipe B1 · Chamada com cliente, Daily de desenvolvimento B2) →
conversa: o Dash faz o outro papel só em inglês (abertura fixa com tradução, 1–2 frases por vez), **sem corrigir no meio**; 4–6 "frases úteis" que preenchem o campo; cada cenário tem 4–6 falas.
"Terminar e ver feedback" → **o que foi bem, até 3 correções explicadas e 3 frases com "Salvar como cartão"** (entra em "Meus cartões" pelo caminho do "Novo cartão": a mesma frente só troca o verso, nunca duplica; o 1º cartão liga o inglês → português).

**Regras:** cada fala da pessoa (resposta do Dash) e o feedback gastam **1 uso** da cota (`IaCubit.consultar`, mesma cota/limite do "Por quê?"; erro/vazio/sem saldo nunca gastam; reserva antes de chamar). Falha ⇒ a fala volta para o campo, sem gastar. Sem cota no meio ⇒ mensagem gentil, a conversa até ali fica e
o "feedback" vira um resumo local ("volte amanhã"). Feedback é pedido como **JSON** (`FeedbackCenario.interpretar`: tolerante a ```json, texto em volta, truncado; ≤3 correções, ≤3 frases; frase recusada por `prepararCartao` ou repetida é descartada; JSON ruim ⇒ texto cru, nenhum cartão).
A fala da pessoa vai como DADO (cortada em 300 letras; o prompt manda ignorar instruções dentro dela). Persona do cenário: serviços que implementam o novo `TutorComPersona` (Gemini web e `firebase_ai`) a recebem como persona; os outros (fakes) recebem como instrução no contexto — a interface `TutorService` NÃO mudou.

**Arquivos novos:** `lib/features/ia/domain/{cenario,sessao_cenario}.dart` (modelo, máquina de turnos pura, persona, contexto do turno, pedido e parser do feedback) · `presentation/{cenario_cubit,cenarios_page,conversa_page,feedback_cenario}.dart` · `assets/ingles/cenarios.json` (já coberto pelo `assets/ingles/` do pubspec).
**Editados com cirurgia:** `tutor/data/tutor_service.dart` e `tutor_firebase_ai.dart` (`TutorComPersona.perguntarComo`; `perguntar` só delega) · `ia_cubit.dart` (`consultar` + `_chamar` compartilhado com o "Por quê?") · `mapa_page.dart` (o card) · `main_portfolio_probe.dart` (o `_TutorFake` fala o cenário e devolve um feedback JSON).

⚠️ **Armadilhas achadas na prova em Chrome (leia antes de mexer em `conversa_page.dart`):** o padrão do `TextInputAction.done` é TIRAR O FOCO do campo a cada Enter (e `readOnly`/`enabled`/`requestFocus` no meio do Enter, ou `autofocus` na abertura da tela, derrubam a conexão de teclado da web com um `Error` do motor, sem mensagem — aparece como `pageerror` em `a_0.mo`). Solução: `onEditingComplete: () {}`, campo sempre ligado e sem autofocus; o envio é que espera a resposta (o texto fica no campo). Testes de widget NÃO pegam esse erro: só o Chrome.

**Testes (+56):** `ia_cenario_test` (25: conteúdo dos 8 cenários — ids, etapas, inglês digitável —, máquina de turnos, persona/contexto/pedido de feedback, parser em tabela) · `ia_cenario_cubit_test` (15: cota, falha, sem cota, persona própria × contexto, conversa inteira, feedback único, JSON ruim) ·
`ia_cenario_ui_test` (15) · `ia_cenario_app_test` (1: app inteiro — Mapa → Conversar → café → 3 falas → feedback → salvar cartão → "Meus cartões", sem duplicar, cota 30→26, ranking intacto). 15 mutações pegas (persona que corrige, correções/frases sem limite, frase sem validar, feedback sem guarda, falha sem desfazer a fala, histórico com a fala atual, sem aviso de última fala, frases duplicadas, persona pelo caminho padrão, sem corte de 300, Mapa sem o card, contexto sem a regra de idioma, feedback local sumindo, 1º cartão sem ligar o sentido, campo sem foco).
Chrome real (probe, 1027 e 390 px): conversa de 3 falas, feedback, 2 cartões salvos, 0 erros.
⚠️ Pendências: ~~voz nos cenários (D11)~~ ✅ feita na Fase 10 (voz, rosto e microfone — ver "💬 Conversa com IA — Fase 10", que substituiu o feedback do fim por correção a cada fala e um resumo local), shadowing (Fase 3), cota dura no servidor (D4).

---

## 🩸 Sanguessugas e subida de nível — Fase 6 (13/out/2026, FEITA; sem commit/deploy)

**Sanguessuga** (como o *leech* do Anki): cartão com **8+ lapsos** (`limiteSanguessuga`, padrão do Anki) e não suspenso. Inglês.
- **Em Baralhos:** aparece o card "🩸 N sanguessugas" (só havendo alguma) → **tela Sanguessugas** (`sanguessugas_page.dart`): cada cartão com a frase, a tradução, o sentido (digitar de memória/cartão de virar), "errou N vezes", o "ao pé da letra" e a nota que a própria frase já tem, e as ajudas:
  **📖 Outra frase** (até 2 frases do curso/dos textos com a palavra MAIS RARA da frase — `exemplosParecidos`), **🧠 Dica de memória** (Prof. Dash: 1 dica ≤ 4 linhas; mesma cota e mesmo cache do "Por quê?" via `PedidoMnemonico`/`PedidoIa`; some sem IA)
  e **⏸ Suspender** (com "Desfazer"). Ordem: quem mais erra primeiro. Domínio puro em `domain/sanguessugas.dart`.
- **Sugestão de nível** (`domain/subida_nivel.dart`, `SerieDeNivel`): na revisão de cartões, a 1ª nota de cada cartão (o "DE NOVO" não conta) entra numa série por degrau (Fácil → Médio → Avançado; "Só virar" fica fora; "Difícil" não conta nem quebra).
  **Subir:** 10 acertos seguidos (Bom/Fácil) → "🚀 … que tal tentar o Avançado?". **Descer:** 4 erros nas últimas 8 → "🫶 Está pesado? … que tal voltar ao Médio por um tempo?". É só um **convite** (botões "Subir/Voltar para X" e "Agora não"; nunca troca sozinho); aceitar ou dispensar recomeça a contagem do degrau.
  A série fica em `en_cartao_serie_v1` (aparelho). Padrões escolhidos por mim (o plano deixava em aberto): 8 lapsos, 10 acertos, 4/8 erros — constantes em `sanguessugas.dart`/`SerieDeNivel`, fáceis de ajustar.

**Arquivos novos:** `lib/features/ingles/domain/{sanguessugas,subida_nivel}.dart` · `presentation/sanguessugas_page.dart`; em `ia/domain/explicacao.dart`: `PedidoIa` (interface: chave, temErro, montar) e `PedidoMnemonico`.
**Editados com cirurgia:** `baralhos_page.dart` (o card; abre a tela com os providers) · `sessao_cartoes_page.dart` (a série, o banner e a persistência) · `ia_cubit.dart` (`explicar(PedidoIa)`) · `botao_por_que.dart` (rótulo/emoji/chave configuráveis) · `main_portfolio_probe.dart` (o `_TutorFake` dá uma dica de memória).

**Testes (+41):** `ingles_sanguessugas_test` (18: limite exato, suspensos, ordem estável, palavras-chave, palavra mais rara, `SerieDeNivel` em tabela, JSON) · `ingles_sanguessugas_ui_test` (19: a tela, ações, dica de memória com cota, sem IA, 360 px/tema claro, o card nos Baralhos, o convite de subir/descer/aceitar/dispensar, "Só virar" fora, "DE NOVO" fora) · +4 `PedidoMnemonico` em `ia_cota_test`.
16 mutações pegas (limite `>`, suspensos dentro, ordem invertida, exemplo com a própria frase, raridade invertida, subir com 9, "Difícil" contando, "Só virar" na escada, descer com 3, trocar de nível sozinho, repetição entrando na série, "Agora não" sem zerar, suspender sem suspender, card sempre visível). Chrome real (probe, 1027 e 390 px): card, tela, dica, outras frases, convite de descer e aceitar — 0 erros.
⚠️ Pendências/ideias: aviso na hora em que o cartão vira sanguessuga (hoje só a lista); limite de lapsos configurável nos ajustes.

---

## 📖 Leitura com toque na palavra — Fase 4 (13/out/2026, FEITA; sem commit/deploy)

**O que a pessoa vê (Inglês):** no Mapa, o card **"📖 Ler e guardar palavras"** → lista (`leituras_page.dart`): **"Seus textos"** (os "Meus textos" já traduzidos; "Meus cartões" não conta) e **6 textos graduados** A1→B2
(`assets/ingles/leituras.json`: Minha manhã, No mercado, Um fim de semana na praia, Procurando um apartamento, Uma reunião adiada, Aprendendo a programar; cada frase com tradução).
Na leitura (`leitura_page.dart`) cada palavra é tocável; tocar abre a **folha da palavra**: a palavra (🔊), a **tradução da palavra** (MyMemory, pelo `Tradutor` que já existe; em minúscula; "Traduzindo…"/falha amigável) com o aviso
**"uma palavra sozinha pode mudar de sentido: confira na frase"**, a **FRASE INTEIRA com a palavra destacada + a tradução da frase** e **"Guardar cartão de lacuna"**. As palavras já guardadas ficam **sublinhadas** na leitura.
Sem tradutor (cota/rede) ainda dá para guardar: a pista do cartão é a tradução da FRASE, não a da palavra. Frase sem tradução (texto próprio sem pt) não gera cartão (e a folha explica).

**O cartão de lacuna:** entra em "Meus cartões" pelo mesmo caminho do "Novo cartão"/cenários (`CartaoAdicionado`; o 1º liga o inglês → português). Guarda a frase, a tradução, a palavra-alvo (`alvo`, como está na frase) e, se a tradução da palavra aparece INTEIRA e sozinha
na frase em português, o pedaço (`alvoPt`). **Um cartão por frase**: guardar outra palavra da mesma frase TROCA a palavra do cartão (o botão diz "Trocar a palavra do cartão ('a' → 'b')"). Na revisão (`SessaoCartoesPage`) esse cartão é **sempre PT → EN com SÓ a palavra em lacuna**
(`lacunaUnica`), em qualquer nível menos "Só virar" e no ditado, e **não entra na série de níveis** (Fase 6). Na lição de digitação a palavra aparece sublinhada (é o `Trecho.alvo` que já existia).
Dados: `FraseDoTexto`/`CartaoEscrito` ganharam `alvo`/`alvoPt` opcionais (JSON antigo continua valendo; sem alvo o JSON não muda); `TextoSalvo.comoTrilha` e o `CursoBloc._cartaoAdicionado` os carregam.

⚠️ **ARMADILHA (pega por um teste antigo):** as frases do CURSO também têm `alvo` (é o destaque da lição). Por isso o que decide se um cartão é "lacuna da leitura" NÃO é ter `alvo`: é quem abre a revisão dizer (`SessaoCartoesPage.lacunaDaLeitura`, que `abrirRevisao` preenche
com "a frase está no baralho `txt:cartoes`"). Teste de regressão cobre. Outra: palavras repetidas na mesma frase geravam chave duplicada (assert na tela) — agora `palavra-x`, `palavra-x#2`…
Obs.: com o cartão da leitura na tela, o seletor "Sentido" continua mostrando o que a pessoa escolheu (o cartão é PT → EN por regra; a instrução em cima explica).

**Arquivos novos:** `lib/features/ingles/domain/leitura.dart` (`Leitura`, `leiturasDeJson`, `alvoNaTraducao`, `cartaoDeLacuna`) · `presentation/{leituras_page,leitura_page}.dart` · `assets/ingles/leituras.json`.
**Editados com cirurgia:** `texto_salvo.dart`, `cartoes_texto.dart`, `nivel_resposta.dart` (`lacunaUnica`), `curso_bloc.dart` (merge do alvo), `sessao_cartoes_page.dart`, `fixacao.dart` (`lacunaDaLeitura`), `mapa_page.dart` (o card), `main_portfolio_probe.dart` (`_TradutorFake`). Sem pacote novo, sem `firestore.rules`.

**Testes (+46):** `ingles_leitura_test` (19: os 6 textos, `deTrilha`, `alvoNaTraducao` (só palavra inteira), `cartaoDeLacuna`, JSON antigo/novo, `comoTrilha`, `lacunaUnica`) · `ingles_leitura_ui_test` (26: leitura, folha, tradutor com falha, guardar/trocar/sublinhado/sem tradução, palavra repetida, lista, o cartão na revisão em 3 níveis, regressão do `alvo` do curso, série, 360 px) · `ingles_leitura_app_test` (1: app inteiro Mapa → Ler → palavra → guardar → revisão com a lacuna).
18 mutações pegas (substring em vez de palavra inteira, cartão sem tradução, lacuna só da 1ª ocorrência/sem caixa, sem forçar PT→EN, entrando na série, bloco perdendo o alvo, `comoTrilha`/JSON sem alvo, sem sublinhado, tradução com caixa, "Meus cartões" como texto, Mapa sem card, botão sempre ligado, folha sem a tradução da frase, chave repetida, ignorar o `lacunaDaLeitura`).
Chrome real (probe, 1027 e 390 px): lista, leitura, folha, sublinhado e a lacuna "Then I have ___ with my sister." na revisão — 0 erros.
⚠️ Pendências: um cartão por frase (várias palavras na mesma frase = só a última); texto colado direto na tela de leitura (hoje se cola pelo "Transforme um texto em lição" e ele aparece em "Seus textos"); tradução contextual da palavra pela IA (hoje MyMemory, palavra isolada).

---

## 📝 Escrita corrigida por IA — Fase 5 (13/out/2026, FEITA; sem commit/deploy)

Plano: `planejamento/FASE-5-ESCRITA-CORRIGIDA.md` (decisões D1–D11). Só Inglês, por texto.

**O que a pessoa vê:** no Mapa, o card **"📝 Escrever e ser corrigido"** (depois de "Conversar"; some sem a IA; 📝 porque o ✍️ já é do "Transforme um texto em lição") → tela com 6 temas sugeridos
(preenchem o começo da frase em inglês), campo multilinha, contador "N de 3 frases" e **Corrigir** (1 uso da cota). Volta, em português: **texto corrigido**, **o que foi bem**, e **um bloco por frase com erro**
(a frase riscada → a frase inteira corrigida → tradução → "por quê") com **"Salvar como cartão"** e **"Salvar todos (N)"**. O cartão entra em "Meus cartões" pelo caminho dos cenários (`salvarCartaoDoCenario`):
frente = a frase corrigida, verso = a tradução; a mesma frente nunca duplica. **Nunca há nota/pontuação.** "Escrever outro texto" recomeça.

**Regras (todas com teste):** texto da pessoa = DADO (≤ 3 frases × 300 letras, numerado e entre aspas, o prompt manda ignorar instruções dentro dele; abreviações `Mr.`/`Dr.`/`e.g.` não separam frase) · pedido pede SÓ um JSON
(`em_ingles`, `corrigido`, `elogio`, `erros[{sua, melhor, pt, porque}]`, ≤ 5 erros, um por frase) · parser tolerante (```json, texto em volta; JSON ruim/truncado/vazio ⇒ texto cru e nenhum cartão; nunca lança) que
**descarta** erro vazio, `melhor ≈ sua`, `sua` que a pessoa nunca escreveu (a IA inventou) e `melhor` repetido; campos fora do contrato (`nota`, `score`…) são ignorados · `melhor` que o `prepararCartao` recusa: o erro aparece, sem botão de salvar ·
`em_ingles:false` ⇒ "Escreva em inglês" (gasta 1 uso: não adivinho idioma no cliente) · **o MESMO texto de novo mostra o resultado e não chama a IA** (sem cache em disco) · falha de rede/vazio/sem saldo não gastam e o texto fica no campo ·
nada é salvo ao sair (só os cartões salvos) · **não conta no hábito** e não toca em ranking/agenda (teste prova) · salvar é ação da pessoa, nunca automático.
Padrões das perguntas em aberto: salvar pelo botão; escrita fora do hábito; até 3 frases; português gasta 1 uso; 6 temas fixos no código; sem rascunho/histórico; cartão sem o "porquê".

**Arquivos novos:** `lib/features/ia/domain/escrita.dart` (`TextoEscrito`, `pedidoDeCorrecao`, `ErroEscrito`, `ResultadoEscrita.interpretar`, `temasDeEscrita`) · `presentation/escrita_cubit.dart` (`EscritaCubit`, usa `IaCubit.consultar`) · `presentation/escrita_page.dart`.
**Editados com cirurgia:** `mapa_page.dart` (import + `_CartaoEscrever` + 1 linha na lista) · `main_portfolio_probe.dart` (o `_TutorFake` devolve um JSON com 2 erros para `MODO CORREÇÃO DE ESCRITA`).
**Intactos:** `IaCubit`, `TutorService`, `sessao_cenario.dart`/`FeedbackCenario`, `pubspec.*`, `firestore.rules`, `android/`, `ios/`.

⚠️ **Armadilhas:** o campo é multilinha (Enter quebra linha; só o botão envia), **sempre ligado, sem `autofocus`/`requestFocus`** (mesma armadilha do teclado na web dos cenários; teste trava isso, mas só o Chrome prova) ·
`CursoBloc` de teste precisa de `textos: LocalTextosRepository(..)` para salvar cartão e de ≥ 1 trilha para ficar "pronto" (lista vazia trava a montagem) · identificador com acento (`_lê`) não compila em Dart.

**Testes (+65):** `ia_escrita_test` (32: `preparar` em tabela, prompt, parser em tabela, "sem nota", temas) · `ia_escrita_cubit_test` (11: cota, mesmo texto, falha, sem cota, toques repetidos, JSON ruim, injeção, fechar a tela) ·
`ia_escrita_ui_test` (21: telas e estados, salvar um/todos sem duplicar, cartão recusado, sem erros/cru/não-inglês, falha/sem cota mantêm o texto, campo nunca desligado, card do Mapa com/sem IA, 360/390/1027 px com tema claro) · `ia_escrita_app_test` (1: app inteiro Mapa → Escrever → corrigir → salvar todos → "Meus cartões", 30→29, mesmo texto não gasta, ranking e hábito intactos).
**20 mutações pegas** (corte 400, 4 frases, prompt sem a ordem de ignorar, 6 erros, `melhor==sua`, `sua` inventada, `melhor` repetido, JSON vazio virando "sem erros", campo `nota` lido, mesmo texto chamando a IA, campo limpo ao enviar,
`salvaveis` com cartão nulo, cartão sem `prepararCartao`, card sem IA visível, `em_ingles:false` ignorado, escrita contando no hábito, `autofocus`, campo `readOnly` esperando, abreviação separando frase, texto vazio chamando a IA) — arquivos restaurados (hash igual).
Chrome real (probe, 1027 e 390 px): card, tela, tema, 2 linhas com Enter, Corrigir, blocos, "Salvar todos", cartões no `localStorage` (`en_textos_*`), mesmo texto não gastou (cota 25→24 uma só vez), 0 erros de console/`pageerror`.
⚠️ Pendências/ideias: histórico dos textos escritos e "erros mais comuns" por tipo; guardar o "porquê" no cartão (exige campo novo no baralho); escrita por voz; contar no hábito (decisão do dono).

---

## 🗣 Shadowing — Fase 3, parte 2 (13/out/2026, FEITA; sem commit/deploy)

Plano: `planejamento/FASE-3B-SHADOWING.md` (D1–D11). Só Inglês. Feito **em cima do reconhecedor do dono sem editá-lo** (autorizado em 13/out): só importa a API pública
(`ReconhecedorFala`, `SessaoFala`, `ErroFala`, `avaliarFala`, `AvaliacaoFala`); `reconhecedor_*.dart`, `fala_nativo.dart`, `avaliacao_fala.dart`, `voz_ingles.dart`, `frase_view.dart` e `ingles_fala_test.dart`
seguem **byte a byte iguais** (conferido por `shasum` antes/depois) e **continuam sem commit**.

**O que a pessoa vê:** novo sentido do cartão de virar **"🗣 Ouvir e repetir"** (ao lado de EN→PT, PT→EN, Misturado e 🎧 Áudio→escrever). A frente é **só o áudio** ("🗣 Ouça e repita"; toca sozinho; 🔊/🐢/R) com o painel do microfone:
**🎤 Falar** (ou **Espaço**) → mostra o que está sendo ouvido → confere por palavra com o `avaliarFala` do dono. Entre uma tentativa e outra aparece **o que foi ouvido** (palavras que casaram em verde, as outras em vermelho)
e "Faltaram N de M palavras · sobraram K" **sem revelar a frase** (ela só aparece ao virar). Até **3 tentativas** ("não entendi nenhuma palavra" não conta); **"Mostrar a frase"** desiste.
Perfeita, ou na 3ª tentativa, ou desistindo: o cartão vira (inglês com as palavras certas/erradas marcadas, "O QUE EU OUVI", a tradução) com as 4 notas e **a sugerida marcada**:
**Bom** só se a 1ª tentativa for perfeita · **Difícil** se perfeita na 2ª/3ª ou melhor tentativa com ≥ 70% das palavras · **Errei** abaixo disso ou "Mostrar a frase" · **Fácil nunca é sugerida**. A nota é a do cartão (mesma agenda FSRS, mesmo gancho de hábito).

**Regras (todas com teste):** sem nível (o seletor de nível some; a frase INTEIRA mesmo no cartão de lacuna da leitura) · fora da série de subida/descida de nível · **"Misturado" nunca sorteia** · sem "Por quê?" na fala ·
o app se cala (`_voz.parar()`) quando o microfone abre · sair da tela/trocar de cartão com o microfone aberto **cancela** a escuta · aviso de escuta velha (outra já começou) é ignorado ·
**sem voz** (`!suportado`, permissão negada, sem microfone, `naoSuportado`) o cartão **vira ditado com o nível escolhido** ("Sem voz neste aparelho, hoje é ditado.") pelo resto da sessão e a revisão nunca trava (divergência do plano: o plano dizia "Avançado"; usei o nível que a pessoa escolheu, que o ditado já suporta) ·
sem áudio gravado, sem IA, sem ranking; o painel diz uma vez que o reconhecimento é do navegador/sistema (no Chrome, num servidor: precisa de internet) e que confere PALAVRAS, não sotaque.
Padrões das perguntas em aberto: 3 tentativas · limiar 70% · a frase some até virar · Espaço (falar/parar) e R (ouvir) · voz nos cenários fica FORA (outro plano).
Divergência de redação do plano: entre tentativas o painel mostra só o que foi OUVIDO (e quantas palavras faltaram), porque marcar "as palavras da frase" revelaria a frase escondida; a frase marcada vem ao virar.

**Arquivos novos:** `lib/features/ingles/domain/shadowing.dart` (`notaDoShadowing`, `SessaoShadowing`, `comparacaoDoShadowing`, `maxTentativasShadowing`, `limiarShadowing`) · `presentation/widgets/painel_shadowing.dart` (`PainelShadowing`, `PainelShadowingState.alternar()`).
**Editados com cirurgia (já sujos):** `domain/nivel_resposta.dart` (`SentidoCartao.shadowing`) · `presentation/sessao_cartoes_page.dart` (`reconhecedor` + `fabricaReconhecedor` estático, `_shadowAtual`/`_shadow`/`_painel`/`_shadowSemVoz`, `_aoTentativa`/`_aoMostrarFrase`/`_aoSemVoz`, ramos em `_calcularPtEn`, `_prepararCartao`, `_tecla`, `_seletores`, `_instrucao`, `_cartao`, `_resumoDe`, `_dica`) ·
`main_portfolio_probe.dart` (`_ReconhecedorFake`: devolve o que estiver em `window.__dito`). **Intactos:** os arquivos do dono acima, `IaCubit`, `pubspec.*`, `firestore.rules`, `android/`, `ios/`.

⚠️ **Armadilhas:** o botão do painel usa `InkWell(canRequestFocus: false)` (o foco fica na tela do cartão: Espaço/R continuam valendo) e `Center(widthFactor: 1)` — um `Container` com `alignment` esticava os botões até a borda (achado no Chrome) ·
no Chrome automatizado **não há microfone nem reconhecimento**: a prova usa o falso do probe; **a prova com voz de verdade é do dono** (roteiro abaixo) · o `SessaoCartoesPage.fabricaReconhecedor` é estático (como o `FraseView.fabricaReconhecedor`): testes de app que o trocam precisam restaurá-lo em `tearDown`.

**Testes (+76):** `ingles_shadowing_test` (31: `notaDoShadowing` em tabela e limiar exato, `SessaoShadowing`, integração com `avaliarFala`, `comparacaoDoShadowing`, `SentidoCartao.shadowing`) · `ingles_shadowing_ui_test` (18: painel com reconhecedor falso — estados, erros por tipo, escuta velha, cancelar ao sair, 360/390/1027 px, tema claro) ·
`ingles_shadowing_cartao_test` (24: a frente sem texto, nível some, Misturado, lacuna da leitura, Bom/Difícil/Errei, "Mostrar a frase", "DE NOVO", teclas, voz do app, sem voz vira ditado, série) · `ingles_shadowing_app_test` (3: app inteiro Revisão → 🗣 → agenda FSRS e hábito, "Mostrar a frase", sem reconhecimento).
**22 mutações pegas** (Bom na 2ª perfeita, Fácil sugerido, limiar 60%, "nada" contando, 4 tentativas, frente mostrando o texto, app não se cala, sair sem cancelar, sem suporte não vira ditado, Misturado sorteando, série, escuta velha, "Mostrar a frase" pela tentativa, empate na última, nota da última, Enter virando o cartão,
sem autoplay, seletor de nível visível, "nada" não tratado, Espaço sem falar, erro sem saída, lacuna da leitura) — arquivos restaurados (hash igual).
Chrome real (probe, 1027 e 390 px, 0 erros de console/`pageerror`): sentido 🗣 → áudio na frente → **Espaço abre o microfone no navegador de verdade** → "o que eu ouvi" com 1 palavra faltando → 2ª perfeita pelo clique → vira com **Difícil · sugerida** → Espaço aceita → "não ouvi nada" (recado) → "Mostrar a frase" → **Errei · sugerida** → resultado totalmente errado a 390 px.

🎙️ **Roteiro do dono (2 min, Chrome com internet ou celular):** Revisão → 🗣 Ouvir e repetir → permitir o microfone → ouvir → falar a frase certa (deve virar com **Bom**) → no cartão seguinte falar errado de propósito 3× (deve virar com **Errei**) → negar a permissão (deve cair no ditado com o aviso).
⚠️ Pendências/ideias: "espiar a frase"; shadowing simultâneo (não dá: o reconhecedor ouviria o app); **voz nos cenários com o Prof. Dash** (plano próprio: conversa livre pede outra conferência que não o `avaliarFala`); limiar/tentativas configuráveis.

---

## 🔔 Lembrete diário — Fase 1B (13/out/2026, FEITA; falta provar num aparelho; sem commit/deploy)

Plano: `planejamento/FASE-1B-LEMBRETE.md` (D1–D10). **Autorizada pelo dono** ("Pode seguir com 1B") a mexer em `pubspec.*`, `android/` e `ios/`. Só Android e iOS; web/desktop não recebem lembrete (push web = FCM + VAPID + service worker + servidor: fase própria).

**O que a pessoa vê:** na folha "Sua sequência" (toque no chip), no fim, **"🔔 Lembrete diário"**: interruptor **"Lembrar de estudar"** (desligado de fábrica; ao LIGAR o aparelho pede a permissão de notificação) e, ligado, **"Horário: 20:00"** (seletor 24 h; padrão 20:00) com a regra: "Todo dia às 20:00 — só se a meta do dia ainda não foi batida."
Permissão negada ⇒ continua desligado e um aviso diz como liberar nas configurações. No navegador/desktop a seção só diz "O lembrete diário funciona no app do celular (Android e iOS)." A notificação é acolhedora e sem culpa: 4 textos que giram por dia, **sem número de dias** (ex.: "Hora de uma pausa com o inglês 🐦 — Bastam alguns minutos. O Prof. Dash está esperando você!").

**Como funciona (decisões):** **notificações únicas para os próximos 7 dias** (ids `7100…7106`), não "diária repetida" — porque a regra "só se a meta de hoje não foi batida" não existe numa notificação repetida: bater a meta reagenda SEM hoje; cada abertura do app renova os 7 dias ·
horário de hoje que já passou não entra · reagenda quando: o app abre (lê a config), liga/desliga, muda o horário, **a meta de hoje é batida** (e quando o dia vira e a meta volta a valer); um exercício que não bate a meta NÃO reagenda ·
cada lembrete é um **instante absoluto** (`DateTime` local → `TZDateTime.from(…, tz.UTC)`): não precisa do nome do fuso (nem de um 3º pacote) e o horário de verão já vem certo ·
**Android: alarme NÃO exato** (`inexactAllowWhileIdle`), sem `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` (a Play restringe; um lembrete de estudo não precisa de minuto exato) ·
configuração **do aparelho e da conta** em `lembrete_v1:{uid}` (SharedPreferences) — **nada vai ao Firestore** (`firestore.rules` intacto) · o último `LembreteCubit` aberto cancela ao fechar (saiu da conta); na troca de conta o antigo NÃO apaga o que o novo agendou · o lembrete só LÊ o hábito.

**Arquivos novos:** `lib/features/habito/domain/lembrete.dart` (`ConfigLembrete`, `LembreteAgendado`, `proximosLembretes` — a regra pura —, `textosDoLembrete`) · `data/lembrete_repository.dart` · `data/agendador_lembrete.dart` (interface `AgendadorDeLembrete` + `AgendadorNulo`) · `data/agendador_celular.dart` (`AgendadorDoCelular`, o plugin) · `presentation/lembrete_cubit.dart`.
**Editados com cirurgia:** `sequencia_sheet.dart` (a seção + `seletorDeHorarioDoLembrete` injetável) · `lib/main.dart` (`lembreteBuilder`/`agendadorBuilder`, `_comLembrete` ao lado do hábito, **`lazy: false`**) · `main_portfolio_probe.dart` (`_AgendadorFake` "disponível": loga `LEMBRETE agendados N: …` no console e nega a permissão com `window.__negarLembrete`) ·
`pubspec.yaml`/`pubspec.lock` (**`flutter_local_notifications` 22.3.2 + `timezone` 0.11.2**, só esses dois) · `android/app/src/main/AndroidManifest.xml` (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, os 2 receivers do plugin) · `android/app/build.gradle.kts` (`isCoreLibraryDesugaringEnabled` + `desugar_jdk_libs:2.1.4`) ·
`ios/Runner/AppDelegate.swift` (`UNUserNotificationCenter.current().delegate`) · **`ios/Podfile`, `ios/Runner.xcodeproj/project.pbxproj` (3×) e `ios/Flutter/AppFrameworkInfo.plist`: iOS mínimo 13 → 14** (ver abaixo) · `ios/Podfile.lock`/`ios/Pods` (pelo `pod install`). **Intactos:** `firestore.rules`, `HabitoCubit`, `IaCubit`, reconhecedor.

⚠️ **Achado que NÃO era da 1B:** o `file_picker` (já no `pubspec`, 13.1.0) exige iOS 14, e o projeto estava em 13 — `flutter build ios` **já falhava** antes da 1B ("The plugin file_picker_darwin requires a higher minimum iOS deployment version"; o `Podfile.lock` antigo nem tinha o `file_picker`). Subi o mínimo para **14.0** (Podfile + Xcode + AppFrameworkInfo) para o build passar; iPhones com iOS 13 deixam de ser suportados (decisão do dono se quiser voltar: então trocar de `file_picker`).
⚠️ **Armadilhas:** (1) **`BlocProvider` preguiçoso**: o `LembreteCubit` só nascia ao abrir a folha, então o app aberto sem abrir a folha nunca renovava os 7 dias — achado na prova no Chrome; hoje `lazy: false` + teste de app que NÃO toca no cubit ·
(2) `late final int _minha = ++_geracao` é preguiçoso e só rodava dentro do `close()` (o cubit nunca cancelava ao fechar) — achado pelos testes; hoje campo comum ·
(3) no **iOS sem permissão concedida NADA fica agendado** (nem `pendingNotificationRequests` mostra; testado no simulador): por isso o pedido de permissão vem antes do agendamento ·
(4) a folha ancora embaixo: ao desligar o lembrete o botão de horário some e o interruptor DESCE (cuidado com coordenadas em prova no Chrome) · (5) `?` digitado pelo Playwright não passa no motor de digitação (limitação do driver; use o `localStorage` para ajustar o hábito na prova).

**Testes (+74):** `lembrete_test` (a regra pura: horário passado, meta batida, 7 dias, virada de mês/ano/bissexto, madrugada, ids, textos sem número/culpa, JSON estragado) · `lembrete_repository_test` · `lembrete_cubit_test` (permissão, negada, horário, ordem/fila, hábito lento, meta batida, virou o dia, fechar/troca de conta) · `lembrete_ui_test` (a folha: sem cubit, web, ligar/negada/horário/desligar, 360/390/1027 px, tema claro) ·
`lembrete_app_test` (3: app inteiro — folha → permissão → 7 dias → meta tira hoje → virou o dia; sem suporte; **abrir o app com o lembrete ligado renova sem abrir a folha**).
**22 mutações pegas** (a de "não esperar o hábito" só foi pega depois de um teste com hábito lento) — arquivos restaurados (hash igual).
**Builds:** `flutter build apk --debug` ✓ (Gradle, desugaring, manifest final com SÓ `POST_NOTIFICATIONS`/`RECEIVE_BOOT_COMPLETED`/os receivers) · `flutter build ios --simulator --no-codesign` ✓ (pod install; só depois do iOS 14) · `flutter build web` do probe E do app real ✓ — o app real abre na tela de login sem erro de console (nada de "tela branca" de registrante velho; **não precisei de `flutter clean`**).
**Chrome real (probe, 1027 e 390 px, 0 erros):** a folha mostra a seção → ligar ⇒ "permissão concedida" + **7 lembretes às 20:00** → horário 07:30 pelo seletor ⇒ reagenda 7 às 07:30 → recarregar SEM abrir a folha ⇒ renovou sozinho → bater a meta (10/10) ⇒ **6 lembretes, sem hoje** → desligar ⇒ 0 → permissão negada ⇒ aviso vermelho e continua desligado.
**Simulador do iOS (iPhone 17):** o código real abre o **diálogo do sistema "Paclingo deseja enviar notificações"** (visto na tela); `initialize` e `zonedSchedule` rodam sem exceção. **Não deu para conceder a permissão** (o macOS bloqueia clique/tecla sintéticos no Simulator) — logo o agendamento pendente de verdade NÃO foi observado.

🔔 **Roteiro do dono (3 min, num Android e/ou iPhone reais):** abrir o app → chip da sequência → "Lembrar de estudar" → permitir → mudar o horário para daqui a ~2 min → fechar o app → a notificação aparece (Android: pode atrasar alguns minutos, é alarme não exato) → tocar nela abre o app → estudar até bater a meta → o lembrete de HOJE não vem → negar a permissão (configurações) e ligar de novo mostra o aviso.
⚠️ Pendências/ideias: prova num aparelho físico; lembrete por dia da semana; ícone/ação na notificação; ao tocar na notificação abrir direto a lição; reagendar também ao voltar do segundo plano (hoje renova na abertura e a cada mudança do hábito); se for publicar na loja: `flutter clean && flutter pub get` antes do build de produção e conferir a política de notificações da Play/App Store.

---

## 🧩 Modos de resposta — Fase 7 (13/out/2026, FEITA; falta provar num celular de verdade; sem commit/deploy)

Plano: `planejamento/FASE-7-MODOS-DE-RESPOSTA.md` (D1–D10). **Só as lições do Inglês** (a "Revisão do dia" e os cartões não mudaram; Dart e C# digitam código).

**O que a pessoa vê:** uma barra **⌨️ Digitar · 🎤 Falar · 🧩 Montar** logo acima da frase de cada passo da lição (a escolha é lembrada neste aparelho, chave `en_entrada`; **padrão Digitar**).
· **Digitar** = o de sempre, e no celular ganhou um botão **⌨ Teclado** (ao lado do 🎤 "Falar a frase") que abre o teclado — antes só se descobria tocando na frase.
· **Falar** = o painel do microfone em destaque ("Toque em "Falar a frase" e diga…"), a mesma conferência por palavra (`avaliarFala`); a frase certa vale como digitada. Só aparece se o navegador/aparelho reconhece voz (senão a barra tem só Digitar e Montar; uma escolha guardada "falar" num aparelho sem voz vale Digitar sem apagar a preferência).
· **Montar** = a tradução em cima e **blocos de palavras** (as da frase + 2 a 5 de enfeite, de `montarBlocos`) para tocar na ordem; **Conferir** (ou **Enter** no teclado físico) confere: certa conclui o passo; errada pinta as pastilhas (verde = no lugar, vermelho = fora) e soma 1 erro por palavra fora do lugar (tentativas ilimitadas); tocar numa pastilha da frase a solta; **"não sei"** (degraus de memória) revela a frase e os blocos recomeçam para ela ser copiada (nota: errou).
· **Falar e Montar não abrem o teclado do celular** (o campo escondido sai do foco; Digitar o devolve). No computador nada muda (padrão Digitar; Enter/Tab/Esc iguais; o foco segue valendo para as teclas).

**Nota (D2):** a conclusão do Montar entra pelo mesmo caminho da fala (`TrechoFalado` + erros por posição em `FraseViewState.errosDeFala` → `avaliarDigitacao`), então o palco só ganhou UMA linha de nota: **`notaDaEntrada`** — na **PROVA (D5)** um montar **certo** conta só "tropeçou" (meio ponto: 3 provas montadas certas = nota 5 de 10; digitadas = 10); nos outros degraus vale inteiro; digitar e falar valem inteiro; montar errado vale como errou; a nota nunca melhora. O selo diz "🧩 Montou certo! Na prova, montar vale meio ponto — digite ou fale para valer inteiro", **sem** "foi erro de digitação" (não há o que contestar) e **sem** "💡 Por quê?" (não há palavra errada). Selos novos: "✅ Montou certinho" / "✅ Falou certinho". Hábito/ranking contam como sempre (1 por passo, qualquer modo); nada vai ao Firestore.

**Divergências do plano (todas deliberadas):** (1) a barra mora **dentro da `FraseView`** (parâmetro `onMudarEntrada`; sem ele a tela é idêntica à de antes — a Revisão do dia não a tem), não no palco entre o card e a frase: visualmente o mesmo lugar, e a `FraseView` já sabe se há voz (`_rec.suportado`) · (2) o Montar usa conferência PRÓPRIA (`conferirMontagem`: **ordem exata** pela maior subsequência comum, um enfeite no meio não estraga as outras palavras) em vez do `conferirBlocos` dos cartões (que perdoa ordem) — reaproveita só `Bloco`/`montarBlocos`/a pastilha · (3) Montar **não revela letras** após 2 erros na mesma palavra (a fala revela): as pastilhas vermelhas já guiam · (4) o campo escondido continua sem `readOnly`/`enabled`; ao trocar para Falar/Montar no celular o foco sai (`unfocus`), ao voltar para Digitar pede foco + `TextInput.show`; `autofocus` e `onTapOutside` só valem quando o modo pede teclado · (5) Enter no Montar confere (não "ouve"); letras e Backspace são ignorados em Falar/Montar.
**Padrões das perguntas em aberto:** Falar aparece no computador se há voz (sim) · Montar fora da Revisão do dia (não entrou) · sem atalho de teclado para trocar de modo · frase à vista no Copie (sim).

**Arquivos novos:** `lib/features/ingles/domain/entrada_resposta.dart` (`EntradaResposta`, `notaDaEntrada`, `abreTeclado`, `PrefsEntrada`) · `domain/montagem.dart` (`conferirMontagem`, `ConferenciaMontagem`) · `presentation/widgets/{pastilha,montagem_frase,seletor_entrada}.dart` · testes `ingles_entrada_test`, `ingles_montagem_test`, `ingles_montagem_ui_test`, `ingles_entrada_frase_test`, `ingles_entrada_app_test`.
**Editados com cirurgia (arquivos já sujos, backup em scratchpad):** `widgets/frase_view.dart` (`entrada`, `onMudarEntrada`, `apoioMontagem`, `entradaAtiva`, `_pedeFoco`, `_trocouEntrada`, botão Teclado, painel do mic em Falar, `MontagemFrase`, `_montagemErrou/_montagemCerta`) · `palco_ingles.dart` (`_entrada` + pref, `_pedirFoco`, `_mudarEntrada`, `notaDaEntrada` em `_concluiu`, selo/"Por quê?"/contestar) · `sessao_cartoes_page.dart` (`_Pastilha` privada → `Pastilha` pública; visual idêntico) · `home_page.dart` (a dica do rodapé no celular fala dos 3 modos) · `main_portfolio_probe.dart` (`FraseView.fabricaReconhecedor` = o reconhecedor falso, para provar o Falar no Chrome). **Intactos:** `pubspec.*`, `firestore.rules`, `android/`, `ios/`, `typing_bloc.dart`, `roteiro.dart` (a escada), os reconhecedores.

⚠️ **Armadilhas (todas pagas nesta fase):**
· **`BlocBuilder` condicional SEM `key` reaproveita o estado do vizinho** quando o modo muda (o Flutter casa filhos de `Column` por posição+tipo): o do Montar herdava o `_state` do "aviso de caixa", criado com a frase ainda VAZIA, e os blocos nunca apareciam — só no app inteiro (a tela nasce antes da frase carregar); no teste de widget com a frase já carregada passava. Os três têm `ValueKey` agora e há teste "a tela nasceu ANTES da frase" ·
· `tester.ensureVisible` **não faz pump**: sem `await tester.pump()` depois, a posição lida/tocada é a antiga (no celular de 400 px o toque errava) · widgets fora da tela de uma lista preguiçosa **não existem** no teste (rolar antes de procurar) · contar `TextInput.show` NÃO prova teclado aberto (o `EditableText` chama `show` ao ganhar foco, até no computador): prove por `hasFocus`/`TextInput.setClient` · no Chrome, `document.activeElement` = `INPUT.flt-text-editing` quando o teclado do celular estaria aberto e `FLUTTER-VIEW` quando não (bom detector na prova) · o botão "Conferir"/blocos DESCEM quando a frase montada quebra em 2 linhas (conferir coordenadas por screenshot).

**Testes (+115):** `ingles_entrada_test` (19: modos, `porId`, tabela completa de `notaDaEntrada`, "nunca melhora", prefs ida e volta/estragada) · `ingles_montagem_test` (15: ordem exata, enfeite, repetidas, hífen, número, 25 palavras, chaves × `avaliarDigitacao`, `montarBlocos` 2–5 sem repetir) · `ingles_montagem_ui_test` (31: blocos, tocar/soltar, Conferir certo/errado/ordem/enfeite/falta, marcas, 3× o mesmo erro, "não sei", frase nova, sem palavras, 360/390/1027 px × 2 temas × fonte 1,3, seletor) · `ingles_entrada_frase_test` (38: Digitar idêntico, botão Teclado, Falar, Montar, teclado fechado, troca de modo, tela que nasce antes da frase, sem estouro) · `ingles_entrada_app_test` (12: app inteiro — Montar conclui e conta 1, escolha lembrada, pref estragada, **3 provas montadas = nota 5 / digitadas = 10**, montar certo fora da prova vale inteiro, montar errado 2× na prova → errou + cópia de correção, celular sem teclado no Montar e com teclado ao voltar).
**33 mutações** (script no scratchpad, backup → UMA troca → testes da fase → restaura e confere por hash): 31 pegas direto (montar na prova inteiro, ordem errada valendo, enfeite sobrando valendo, enfeite repetindo palavra, erros não somando, Conferir vazio no domínio e na tela, pref com id errado/padrão trocado/não gravada, Falar sem suporte aparecendo/não virando Digitar, Montar/Falar pedindo teclado, Digitar sem digitar, toque na moldura, blocos sem zerar no passo novo, "não sei" sem recomeçar/sem desistir, prova de Digitar caindo, contestar e "Por quê?" no meio ponto, palco sem nota/sem pref/pedindo foco, Enter sem conferir, sem `unfocus`, certa sem concluir, erro sem aviso, pastilhas sem marca, Pac-Man em Falar) + 2 que **escaparam sozinhas** porque cada uma tem uma trava redundante — a `key` do Montar (os vizinhos também têm) e o `contains` do `_pegar` (o `onTap` também barra): pegas ao remover as travas juntas (`m2`, `w2`). Todos os arquivos restaurados (hash igual); `git status` igual ao do início + só os arquivos da fase.
**Chrome (probe, 1027 e 390 px com iPhone emulado por `addInitScript`; 0 erros de console/`pageerror`):** barra de modos acima da frase · **Montar** errado (enfeite no lugar do Mike → pastilhas verde/verde/vermelha + "Ainda não: as palavras em vermelho…") → troca → **Conferir** → Pac-Man comemora, pastilhas verdes, "✓ Feita", Enter segue (1/40; `en_entrada = "montar"` gravada; a frase seguinte já vem em Montar com blocos novos) · **Falar** (reconhecedor falso): "hi carlos how is going" → "Ouvi: … faltaram 2 palavras" → "hi carlos how's it going" → conclui · **Digitar** digitando no Pac-Man · no celular (390 px): 3 pílulas + **Teclado** + **Falar a frase** cabem; `document.activeElement` = INPUT em Digitar → **FLUTTER-VIEW em Montar e em Falar** (sem teclado) → INPUT de novo ao voltar a Digitar · Montar com 2 linhas de blocos cabe em 390 px. Probe apagado (`build/probe`), servidor encerrado.
🎙️ **Roteiro do dono (2 min, num celular de verdade):** abra uma lição de Inglês → toque **🧩 Montar** (o teclado NÃO deve abrir) → monte a frase e **Conferir** → toque **⌨️ Digitar** e depois **Teclado** (o teclado abre) → toque **🎤 Falar**, permita o microfone e diga a frase (o teclado não abre) → numa **Prova** (cabeçalho "Prova"), monte certo e veja "montar vale meio ponto" → feche e reabra o app: o último modo escolhido deve estar marcado.
⚠️ Pendências/ideias: Montar/Falar na "Revisão do dia"; atalho de teclado para trocar de modo; montar o PORTUGUÊS (tradução inversa); pistas no Montar (dica de próxima palavra); **voz do Prof. Dash nos cenários** (plano próprio).

---

## 🎬 Vídeo de novidades (13/out/2026, FEITO; fora do repositório)

**"Paclingo - Novidades.mp4"**: 1920×1080, 30 fps, 3:49, sem música (o dono põe no CapCut; `roteiro.txt` e `legendas.srt` acompanham). Entregue em `~/Downloads/paclingo-video/`. Mostra: escolha da trilha, a lição (cópia → iniciais → tamanho → de memória, erro e "💡 Por quê?"), os **3 modos de resposta** (Digitar/Falar/Montar), o celular, a prova (montar = meio ponto), hábito + lembrete, Mapa, baralhos/cartões/ditado/ouvir e repetir, conversa e escrita com o Prof. Dash, texto colado, leitura, Arcade (English Turismo em 3D), Dart e C#.
**Como foi feito (e como refazer):** projeto em `~/development/paclingo-video/` (fora do iCloud) — Playwright grava cada cena do app de prova com o relógio da página congelado a 1/30 s por quadro e o Remotion compõe câmera, legendas, celular e acabamento de cinema. Passo a passo e armadilhas na memória `video-paclingo-novidades`.
**Mudança no app:** só `lib/main_portfolio_probe.dart` (o `_TradutorFake` ganhou 4 frases traduzidas de verdade para a cena do texto colado); sem commit. `build/probe` ficou para apagar (`rm -rf build/probe`).

---

## ☁️ Textos na nuvem — correção (14/out/2026, FEITA; ⚠️ REGRAS AINDA NÃO PUBLICADAS; sem commit/deploy)

**O bug (achado pelo dono):** os textos que a pessoa cola/escreve e viram lição ("Meus textos", "Meus cartões", frases guardadas da leitura/escrita) ficavam só no `shared_preferences` do aparelho (`en_textos_{uid}`): ao entrar com a mesma conta em outro aparelho, a trilha não existia. O progresso e os cartões da revisão já iam para a nuvem; só o TEXTO não ia.

**A correção:** `FirestoreTextosRepository` (em `lib/features/ingles/data/textos_repository.dart`, junto do `LocalTextosRepository`): um documento por texto em **`users/{uid}/textos/{id}`**, com o espelho local de sempre ao lado. Ligado em `main.dart` (`textosBuilder` novo; sem ele vale a nuvem quando há Firebase, o aparelho no probe/testes). O `CursoBloc` não mudou (mesma interface `TextosRepository`).
· **Salvar/apagar** valem no aparelho na hora e sobem em seguida, **sem travar a tela**; se a nuvem falhar (sem rede, regra ausente) a operação fica anotada como **pendente** (`en_textos_sync_{uid}`) e é refeita na próxima abertura: nenhum texto se perde.
· **Carregar** lê a nuvem (espera 6 s; falhou → vale o aparelho), aplica as pendências, devolve a lista mesclada e a guarda no espelho (offline mostra o que veio de outro aparelho).
· **Migração (1ª abertura em cada aparelho):** os textos que só existem no aparelho SOBEM; "Meus cartões" (id fixo `cartoes`) dos dois lados vira a união das frases. Depois disso **a nuvem manda**: texto apagado em outro aparelho sai do espelho e não ressuscita.
· Texto > ~900 KB (limite de 1 MiB do documento) fica só no aparelho, sem sumir.

**⚠️ Regras (aprovado pelo dono em 14/out/2026):** `firestore.rules` ganhou o bloco `match /users/{uid}/textos/{id}` (só o dono lê e escreve). **Falta publicar: `firebase deploy --only firestore:rules`** (e o site, para quem usa a web). Antes disso o app NÃO quebra — salva no aparelho e deixa pendente —, mas não sincroniza. Quem já tinha textos no aparelho os vê subir sozinhos na primeira abertura depois da publicação (as pendências também).

**Testes (+20 novos, todos passam):** `ingles_textos_nuvem_test` (19: texto vai e aparece no outro aparelho inteiro, ordem, uma conta não vê a outra, regravar não duplica, apagar some dos outros, migração, união de "Meus cartões", apagado não ressuscita, sem rede/rede travada/pendência de salvar e de apagar, espelho offline, texto gigante, doc quebrado, leitura antiga não atropela texto novo, bloc nos dois aparelhos) · `ingles_textos_nuvem_app_test` (1: PacDartApp inteiro recebe o texto da nuvem e manda o criado) · `firestore_rules_test` (+ o caminho `users/u1/textos/…`: dono sim, outro/anônimo não).
**20 mutações** (backup → UMA troca → testes → restaura, conferido por `cmp`): 19 pegas (envio de salvar/apagar, migração off/sempre, sem fallback, limite de tamanho, união, flag de migrado, espelho, pendências, salvar esperando a nuvem, leitura antiga atropelando o espelho, subcoleção errada, uid errado, `textosBuilder` ignorado, regra removida, regra aberta a todo logado) + 1 que escapou por ser **linha redundante** (o `continue` do apagado pendente; o laço seguinte já o tirava da lista) — a linha foi removida.
**Chrome:** não foi possível provar a sincronia de verdade no navegador (exige conta real e as regras publicadas; o probe roda sem Firebase). A prova é a dos testes (dois "aparelhos" com armazenamentos separados e UMA nuvem falsa que confere as regras reais) + o roteiro abaixo.
🎙️ **Roteiro do dono (3 min, depois de publicar as regras e o site):** no aparelho A (onde já tem textos) abra o app em Inglês e entre na conta → espere uns segundos no Mapa → no aparelho B entre com a MESMA conta → "Meus textos" deve mostrar os mesmos textos. Cole um texto novo no B → reabra o A: o texto novo aparece. Apague um no B → reabra o A: ele some. Para conferir no console do Firebase: `users/{uid}/textos`.
⚠️ Outros dados que continuam SÓ no aparelho (por ora de propósito, não são "conteúdo"): ajustes dos cartões no teste (`LocalConfigSrsRepository` só no probe; em produção já vai para a nuvem), modo de resposta Digitar/Falar/Montar (`en_entrada`), preferências de voz/som/tema.

---

## 🔥 Firebase

- Auth **Email/senha** habilitado (feito no console; Identity Platform pago exige billing, o grátis é só o toggle).
- Firestore: doc por usuário `users/{uid}` (concluidas[], quizNotas{}, **projetos[]**, trilha, licao, recorde). Regras em `firestore.rules`: **só o dono acessa** (são por documento, não por campo — campo novo não precisa de deploy de regras).
- **`ranking/{uid}`** (jul/2026): apelido, pontos, teclas, erros, licoes, projetos, quizAcertos, arcadePontos, arcade{jogo→recorde}, atualizadoEm. Regras: **todo logado lê, só o dono escreve** — regras JÁ DEPLOYADAS (`firebase deploy --only firestore:rules`). Query do top: orderBy pontos desc (índice single-field automático).
- **Revisão do inglês (12/out/2026)**: subcoleções `users/{uid}/srs/{b00…b15,_meta}` (cartões FSRS) e `users/{uid}/srs_log/{AAAA-MM}` (histórico); regras próprias só do dono (as de `users/{uid}` não cobrem subcoleção). O mapa `users/{uid}.en_revisao` é LEGADO (lido uma vez na migração, nunca apagado).
- **Textos do aluno (14/out/2026)**: subcoleção `users/{uid}/textos/{id}` (um documento por texto colado/escrito; ver "☁️ Textos na nuvem"). Regra própria só do dono — **escrita no `firestore.rules`, ainda não publicada**.
- **Banco de palavras do inglês (20/out/2026)**: um doc `users/{uid}/palavras/v1` (campo `b`, JSON compacto; ver "🆕 Palavras novas"). Regra própria só do dono — **escrita no `firestore.rules`, ainda não publicada**; sem ela o app funciona só no aparelho (falha da nuvem é engolida). `apagarDadosDoUsuario` já apaga `palavras`.
- **`config/tutor` (21/out/2026, rodada 9)**: além de `chaveGemini` e `modeloConversa`, dois campos opcionais ligam o Claude na Conversa: `provedorConversa = "claude"` + `urlConversa = "https://paclingo-conversa.<sub>.workers.dev"` (apagar `provedorConversa` = volta ao Gemini; o app relê em ~5 min). Mesmo doc, mesmas regras (sem deploy de regras). Passo a passo: `workers/conversa-claude/LEIA-ME.md` → "Ligar no app".
- `firebase.json` (hosting → build/web + SPA rewrite; firestore rules/indexes), `.firebaserc` (default: pac-dart).
- Trocar `ProgressoRepository` local por Firestore já está feito (`FirestoreProgressoRepository`).

---

## ⚠️ Armadilhas (gotchas) — leia antes de mexer

1. **Firebase web:** `flutter clean` antes de buildar quando mexer em plugins (senão channel-error / tela branca).
2. **Cores são getters (não const):** por causa dos 3 temas, `Mixart.brand` etc. NÃO podem ir em contexto `const`. Default de parâmetro que era `= Mixart.x` vira nullable + `?? Mixart.x`.
3. **Acentos e TECLA MORTA (ABNT):** campo oculto usa `TextInputType.text` e `_processaTexto` espera
   a composição terminar (`if (!_ctrl.value.composing.isCollapsed) return;`) — vale em `code_view.dart`
   e no quiz. **Além disso:** `~ ^ ´ \`` são tecla morta, e o ESPAÇO que "solta" o acento chega ao
   motor como uma tecla a mais. Sem tratamento, todo `~/` do Dart (9 trechos: divisão inteira) custava
   um erro e travava o jogador. `TypingBloc._espacoQueSoltaAcento` engole esse espaço quando o
   caractere anterior OU o esperado é acento morto. Reproduzido e conferido no Chrome via CDP
   (`Input.imeSetComposition`) — antes `erros=1`, depois `erros=0`.
4. **Prévia ao vivo:** `preview_ao_vivo.dart` balanceia brackets/aspas do código parcial + apara token incompleto (trim-retry); só renderiza **árvore de widget** (não classe StatefulWidget). Cod dos apps Flutter deve ser expressão de widget começando por Scaffold/Column/Card/Center.
5. **Validar Dart:** `dart run` roda dentro do projeto imprime "Running build hooks..." no stdout — rodar com `cwd` num diretório temporário fora do projeto.
6. **Verificação visual (headless):** `Chrome --headless=new --disable-gpu --enable-unsafe-swiftshader --force-device-scale-factor=1` servindo `build/web`; usar largura **≥600px** (headless tem largura mínima que distorce abaixo disso). Headless NÃO carrega os módulos ES do Firebase (gstatic) — pra checar o boot, ler o console (`--enable-logging=stderr`) e ver "Initializing Firebase" sem "channel-error".
7. **Ordem das trilhas:** progresso é keyed por `"trilhaIdx:licaoIdx"`. **Nunca inserir trilha no meio** — só no fim — senão quebra o progresso salvo.
8. **Sem emoji no `cod`:** emoji não é digitável e vira "tofu"/ratinho na fonte mono. Já há testes que barram isso.
9. **Prévias EM BRANCO — exterminadas (jul/2026):** o motor rotulava "AO VIVO" coisas que
    pintavam 0×0 (ex.: `Wrap(children: itens)` com variável, `Text(variavel)`, `SizedBox.shrink`,
    Scaffold só-drawer, `Colors.black26`/`Theme.of` não resolvidos, `ListView.separated`,
    raiz `Expanded/Positioned`). Correções: `interpreter/visibilidade.dart` (só é vivo se a
    árvore parseada tem folha que PINTA — Text exige string literal), engine pula raízes
    Expanded/Flexible/Positioned/Spacer, builder ganhou: Container colorido sem tamanho → caixa
    96×56, Row/Column com flex → palco finito, `.separated` mocka 3 itens + Divider, children
    `ident` são pulados, `_lista` vazia vira 3 ListTiles de amostra, Scaffold só-drawer vira
    gaveta entreaberta, cor pedida-mas-desconhecida vira azul de amostra, `_EntradaAnimada`
    cancela o Timer no dispose. **`test/previa_sem_branco_test.dart` RENDERIZA as 377 prévias
    ao vivo do currículo inteiro e exige área > 64px²** — regressão impossível de passar batida.
10. **Motor de prévia (projetos `flutter:true`) — só um SUBSET:** o `cod` deve ser UMA expressão de widget LITERAL começando por `Scaffold(`/`Center(` (sem variáveis/funções/setState/classes). O interpretador **não** entende: `Color(0xFF...)` (use `Colors.*`), tipos genéricos `Widget<Tipo>(...)` (ex.: `DropdownButton<String>`), `Sliver*`, `PageView`, `CustomPaint`, `FilledButton`, `LayoutBuilder`, `MediaQuery`, `Theme.of`. `SizedBox(height:N)` sem filho vira, **de propósito**, uma caixinha de contorno azul-claro (marca o espaço). Valide qualquer app novo com `PREVIEW_JSON=arquivo.json flutter test test/tools/preview_check.dart` — tem que dar **status OK** (raiz parseia inteira), não "PARCIAL".
11. **Toda lição PRECISA de ≥1 bloco `teoria` do tipo `code`** (o `teoria_test` exige). Lições de comparação/decisão também.
12. **DartPad embutido — o jeito documentado MORREU.** A wiki oficial ainda cita `embed-flutter.html`
    / `embed-inline.html` + gist: **não funciona mais** ("no longer supported"). O que funciona hoje
    (achado no `main.dart.js` de produção do dartpad.dev e confirmado no Chrome):
    - iframe em `https://dartpad.dev/?embed=true&theme=dark|light&run=true`;
    - ele manda pro pai `{sender: <name do iframe>, type: 'ready'}` ~1–5s depois de carregar;
    - o pai responde `{type: 'sourceCode', sourceCode: '<código>'}` → cai no editor e, com `run=true`,
      roda sozinho. É **um arquivo só** (main.dart) — por isso mandamos `codigoExecutavel()`.
    - O `sender` é o atributo `name` do iframe: é assim que se sabe qual frame avisou.
    - Contrato **não documentado** → pode mudar sem aviso; o botão "copiar" é o plano B.
    - Em Flutter web: `HtmlElementView` + `registerViewFactory`, num arquivo com **import condicional**
      (`dartpad_embed_stub.dart` if (dart.library.js_interop) `dartpad_embed_web.dart`) — sem isso o
      `flutter test` (que roda na VM) para de compilar.
    - Headless com `--virtual-time-budget` **não** completa o boot do DartPad dentro do iframe (o
      "ready" nunca chega). Para testar de verdade: Chrome headless em tempo real + CDP.
13. **`assets/roda.json` é GERADO — regere se mexer no currículo ou no gerador.** Receita (o lab fica
    FORA do projeto):
    ```bash
    LAB=/tmp/rodavel_lab   # pubspec com dependência flutter + flutter pub get
    SAIDA=$LAB/lib/gen flutter test test/tools/rodavel_check.dart   # gera 2445 programas
    cd $LAB && flutter analyze > analise.txt                        # quem tem erro fica de fora
    # cruzar analise.txt com $LAB/lib/indice.json → assets/roda.json
    ```
    O app tem que gerar EXATAMENTE o mesmo programa que foi analisado: mesma noção de "é Flutter"
    (`ehTrilhaFlutter`) e mesmo `contexto` (trechos anteriores da lição). Se divergir, o mapa mente.
14. **`carregarRodaveis()` faz I/O de asset:** em `testWidgets` o relógio é falso e o `rootBundle`
    nunca resolve — o fake do loader nos testes PRECISA sobrescrever esse método (ver `fluxo_test`).
15. **Fonte mono SEM ligaduras + teclado Mac:** `Mixart.mono()` desliga liga/calt/clig/dlig —
    a JetBrains Mono fundia `->` em `→` e `!=` em `≠` e o jogador não sabia o que teclar
    (bug real, jul/2026). NÃO reativar. No Mac ABNT, `~`+espaço solta U+02DC (˜), não `~`:
    `TypingBloc.equivalenciasTeclado` normaliza (˜→~, ˆ→^, aspas curvas→retas, travessões→hífen)
    no motor E no quiz. `test/teclado_equivalencias_test.dart` cobre. Além disso, TODO `cod`
    precisa ser 100% digitável (ASCII + acentos pt-BR): `test/conteudo_digitavel_test.dart`
    varre os 2445 códigos — `°`/`º` foram trocados por texto puro no Card de Clima e no
    Placar do Campeonato (cod E out).
16. **Subagentes podem deixar lixo no projeto:** ao gerar conteúdo em massa, eles às vezes criam arquivos `*_check.dart`/`tmp_*.dart` em `test/tools/` ou na raiz pra validar render. Faça uma varredura (`find . -name '*.dart'` fora de `lib/` e não-`_test`) e remova antes do `flutter analyze`/deploy. O único arquivo legítimo em `test/tools/` é `preview_check.dart`.

---

## 📋 Pendências / próximos passos

- **"💬 Conversa com IA" (Fase 10, 21/out, sem commit/deploy):** ✅ validada pelo líder (rodada 8: suíte inteira, analyze, UM build
  do probe + Playwright em 390 e 1027 px, 0 `pageerror`). Falta: commit, `flutter build web` + deploy **só de hosting** (**nenhum deploy de regras**) e
  a conferência com o Gemini de verdade (JSON com esquema e `thinkingBudget: 0` aceitos, latência < 4 s, chat do Prof. Dash ainda
  respondendo pergunta longa) — ver "💬 Conversa com IA — Fase 10". Se aparecer 429 com frequência: `config/tutor.modeloConversa =
  "gemini-flash-lite-latest"` no console (sem deploy). ⚠️ A troca não solta uma janela de **limite diário** já aberta no aparelho (a
  `DescansoIa` é uma só, sem saber o modelo): ela some só ao recarregar a página ou nas 08:00 UTC.
- **🏎️ Turismo — voz no modo setas (21/out, commitado em `e804b90`; sem deploy):** testes verdes (`turismo_voz_setas_test` + os do
  arcade); ✅ provado no Chrome do probe (rodada 8: chip 🔊 no HUD, 1 palavra por portal a ~3 s uma da outra); falta ouvir com o
  ouvido de verdade num navegador com voz, e sobe no mesmo deploy da Fase 10. Ao revisar/commitar a Fase 10, comparar com `e804b90` (não `bdb12d8`): o Turismo já não faz parte dela.
- **"⚡ Treino do dia" (Fase 9, 21/out, sem commit/deploy):** validado pelo líder (suíte, analyze, probe + Playwright em 1027 e 390 px,
  0 erros). Falta: commit, `flutter build web` + deploy **só de hosting** (**nenhum deploy de regras**) e as conferências à mão da
  "rodada 7" — ver "⚡ 21/out/2026 (rodada 7): Treino do dia".
- ⚠️ **"🎧 Ouvir" (Fase 8, 20/out, sem commit/deploy):** publicar `firebase deploy --only firestore:rules` (bloco `users/{uid}/setlists`) **ANTES** do hosting; fazer as 7 conferências em aparelho de verdade do plano (aba oculta, Android bloqueado, iOS, Web Speech oculto, 🔊 do palco pausando, 360 px com teclado, tema claro) — ver "🎧 Ouvir — Fase 8".
- ⚠️ **Palavras novas (20/out, sem commit/deploy):** publicar `firebase deploy --only firestore:rules` (bloco `users/{uid}/palavras`) **ANTES** do hosting; conferir as legendas do `web/turismo3d/turismo3d.js` com UM build de prova numa pasta reaproveitada (apagada depois) — ver "🆕 Palavras novas".
- ⚠️ Código NÃO sincronizado com o GitHub desde o Arcade 2.0 (Turismo 3D inteiro só local + Firebase).
  Push só quando o usuário pedir.
- **Fila do Dart Turismo (pedidos do usuário, set/2026)**: ✅ pistas 4×, ✅ rock por fase,
  ✅ cidade, ✅ engenheira IA, ✅ vento, ✅ qualidade alta/leve, ✅ tremor opcional, ✅ tutorial,
  ✅ minimapa, ✅ fachadas fotográficas, ✅ cenário real por tema, ✅ pneu cantando,
  ✅ carro-fantasma, ✅ estatísticas/troféus. Ideias seguintes: árvores frondosas realistas (as
  do Poly Haven têm .bin de 100–480 MB — inviável na web; alternativa = billboards CC0);
  chuva/clima; replay; ranking de tempos por pista entre amigos (Firestore).
- Adicionar os **topics** no GitHub (flutter, dart, bloc, typing-game, education, pacman) — precisa do agente do Chrome no site.
- (opcional) Sincronizar o **tema por usuário** (hoje é por dispositivo, no shared_preferences).
- (opcional) Sons de arcade (waka-waka), mais joguinhos (o hub em `arcade_page.dart` é uma lista — é só acrescentar o card + página), troféus/temporadas no ranking (hoje é all-time), avatar/apelido editável.
- (opcional) Anti-farming leve no ranking (repetir quiz re-pontua; tudo bem enquanto for entre amigos).
- 🐛 **Card da lição estourava no celular (corrigido e PUBLICADO em 13/out):** em `palco_ingles.dart` o link "📖 Entenda a lição (explicação em português)" era um `Text` solto num `Row` (`mainAxisSize.min`) e não quebrava de linha a ~390 px; agora é `Flexible`.
- 🐛 **Tradução com `<g id="1">…</g>` (achado pelo dono no celular, corrigido e PUBLICADO em 13/out):** o MyMemory às vezes devolve a tradução com marcas de memória de tradução (`<g id="1">mas ninguém achava </g>que…`, `<x id="2"/>`), às vezes até escapadas (`&lt;g…&gt;`, ou escapadas 2×). Nova `limparTraducao` (`ingles/domain/limpar_traducao.dart`): decodifica entidades (2×), tira marcas (`<br>` vira espaço; `<` colado em letra e fechado por `>`; "3 < 5", "<3" e "a<b" ficam), junta espaços. Usada (1) pelo `TradutorMyMemory` (também nas traduções de palavra da Leitura) e (2) em `FraseDoTexto.fromJson` (`pt` e `alvoPt`): **textos já salvos com a marca voltam limpos sem refazer a lição** (a lição "Jack Hannaford" do dono ficou certa só de recarregar).
- 🚀 **Publicado em 13/out/2026** (`flutter build web` + `firebase deploy --only hosting --project=pac-dart`, a pedido do dono para testar o texto colado): o site agora tem TUDO o que estava na árvore — hábito/sequência (1A), "Por quê?"+cota de IA (2A), cenários (2B), leitura (4), escrita corrigida (5), sanguessugas (6), ditado e shadowing (3), lembrete (1B; só no celular nativo, no site só a explicação) e o corte do texto colado em trechos com sentido. **Nada de `firestore.rules`** foi publicado (só hosting): os campos novos de `users/{uid}` (`habito`, `ia_cota`) dependem das regras que JÁ estão no ar. Depois de publicar: hard refresh (`Ctrl/Cmd+Shift+R`; no iPhone fechar e abrir a aba).
- 🐛 **Microfone preso em "Ouvindo…" no iPhone/Chrome (relato do dono em 13/out) — CORRIGIDO e PUBLICADO (13/out 13:22 GMT):** o botão "Parar" só pedia `stop()` ao navegador e ESPERAVA o `onend`; no Chrome/Safari do iPhone o navegador nunca avisa, então a tela ficava presa ("Ouvindo… ■ Parar", sem conseguir digitar). Reproduzido no probe emulando iPhone (UA + Chromium sem áudio): ANTES, depois de "Falar" + 2 toques em "Parar" continuava "Ouvindo…"; DEPOIS, solta e volta a "Falar a frase".
  Correção em 3 camadas, **todas com a mesma ideia: sempre dá para sair**: (1) `reconhecedor_web.dart` (`_Sessao`): `parar()` agora força o fim 1,5 s depois (`abort()` + `_fim()`) se o navegador não responder, o 2º `parar()` força na hora, teto da escuta 25 → 15 s, e se a escuta acabou sem nunca abrir o microfone (`onstart`/`onaudiostart`) depois de > 3 s o erro vira `naoSuportado` ("use o 🎤 do teclado") em vez de "não ouvi nada" ·
  (2) `frase_view.dart` (digitação): 2º toque em "Parar" ou 2 s depois solta o microfone (`_soltarMicrofone`: "O microfone não respondeu. Toque no 🎤 para tentar de novo ou digite a frase."), e **tocar na frase ("quero digitar") fecha o microfone** · (3) `painel_shadowing.dart` (shadowing): o mesmo (2 s / 2º toque). Testes: `ingles_microfone_travado_test` (7, com um reconhecedor falso TEIMOSO que ignora o "parar") + 3 no `ingles_shadowing_ui_test`; 8 mutações pegas (as 2 que passaram são equivalentes: `_soltar*` já confere `_ouvindo`).
  ⚠️ Armadilhas: (a) o botão "Parar" DESCE quando aparece a linha "Ouvindo…" (clique de prova em coordenadas errou por isso); (b) o Chromium do Playwright tem `SpeechRecognition` NATIVO e ele é usado antes do `webkitSpeechRecognition` falso — para simular o travamento basta o próprio Chromium sem áudio; (c) o service worker do Flutter segura o `main.dart.js` antigo: limpar `serviceWorker`/`caches` antes de reprovar um build novo no probe.
  Se o microfone AINDA não reconhecer no iPhone (o Chrome do iOS pode simplesmente não reconhecer voz): o app agora diz "este navegador não reconhece voz" e o caminho é o 🎤 do teclado (ditado do iOS), que a digitação já aceita (`aoDitar`).

---

## 🧪 Testes (1.383 em 14/out/2026: 1.378 passam, +20 dos textos na nuvem (ingles_textos_nuvem_test, ingles_textos_nuvem_app_test), +115 dos modos de resposta (ingles_entrada_*, ingles_montagem_*), +10 do microfone que não pode ficar preso (ingles_microfone_travado_test + painel), +19 da limpeza das traduções (ingles_texto_test), +19 do corte do texto colado em trechos com sentido (ingles_texto_test), +74 do lembrete diário (lembrete_*), +76 do shadowing (ingles_shadowing_*), +65 da escrita corrigida (ia_escrita_*), +46 da leitura (ingles_leitura_*), +41 das sanguessugas (ingles_sanguessugas_*), +56 dos cenários (ia_cenario_*), +57 do "Por quê?" (ia_*), +12 do ditado, +111 do hábito diário (habito_test/_repository/_cubit/_ui/_app); as 5 que falham são `csharp_curriculo_test` — conteúdo do C# incompleto, 4.147 de 4.708 exercícios e 0 desafios)

`test/`: typing_bloc · preview_engine · preview_cobertura · quiz · teoria · projetos (30 apps) · auth · theme · app_smoke · **fluxo** (sequência quiz/projetos + progresso dos projetos) · **dartpad** (botão "rodar", gerador de programa rodável, plano B fora da web) · **ranking** (repo com fake_cloud_firestore, deltas/pendência do cubit, ordenação por critério, página com pódio) · **arcade** (banco jogável, embaralhado preserva a certa, escadinha de nível, 3 engines, baralho progressivo por fase sem repetir, combo do TiroEngine) · **arcade_ui** (hub, Gol de Dart determinístico com `semente` — 5 gols = 130 pts no ranking —, corrida com turbo, Chuva destruindo palavra por digitação, Rali com turbo, futebol passando de fase e guardando 130 pts, CampoTeclas retomando o foco sozinho, Esc pausando a Corrida (CPU congela frame a frame — no flutter_test um AnimationController gasta 2 frames por ciclo) e retomando, Caça-Bug esmagando a linha certa, largada 3-2-1 antes de qualquer interação, cenários/dicas ciclando, equivalências de teclado (˜/aspas curvas/travessão) a varredura de digitabilidade dos 2445 códigos, o gerador de missões (validade/diversidade/consistência) e a missão completa jogada de ponta a ponta (prever → 🔮 ajuda → digitar → animar → vencer → pontos e progresso salvos) — o TextField oculto retém o texto digitado: para "sumiu da arena" use finder de RichText, não find.text). Também **tutor** (contexto do estudo com trilha/lição/trecho, cubit em streaming com memória curta e erro amigável de setup, painel com chip 👀 e sugestões, layout largo/estreito — ⚠️ em testWidgets, `cursoPronto()` com Future.delayed precisa de tester.runAsync). E **previa_viva** (regressão da "tela de criando junto": app Flutter do Mão na Massa TEM a PreviewAoVivo lado a lado/empilhada e ela sobrevive à digitação; projeto Dart console NÃO tem — é por design, não bug). Rodar: `flutter test`.
`test/tools/`: `preview_check.dart` e `rodavel_check.dart` (ferramentas, não rodam no CI).
Também há `logo_test` (a marca desenha em 16…512 px, solta e em selo) e `quiz_ui_test`
(responder por clique, digitar tudo numa linha, e Enter não corrigindo antes da hora).
⚠️ Nos testes de tela do quiz, aumente a viewport (`tester.view.physicalSize`): o `ListView` é
preguiçoso e não constrói o veredito que fica fora da janela — parece bug e não é.

⚠️ **Em `testWidgets`, `await bloc.close()` TRAVA o teste** (o relógio é falso e o close espera algo que
nunca chega) — o teste só morre no timeout de 10 min. Use `await tester.runAsync(() => bloc.close())`.

## 14/out/2026 — Inglês: toque na palavra = tradução (pé da letra + no contexto) · Montar/Falar cobrem a frase

**Pedido do dono:** "clicando em qualquer palavra do exercício de inglês, ter a tradução ao pé da letra e no contexto" (escolheu
**dicionário embutido + IA**) e, na sequência, "no Montar e no Falar a frase não pode estar à vista — se preciso adivinhar a sequência,
não faz sentido o texto já estar ali".

**Toque na palavra** (`FraseView`, vale na lição e na Revisão/Treino de memória): tocar/clicar numa palavra **inteira à vista**
(digitada ou mostrada; coberta não abre — seria cola) abre um balão preso à palavra (`widgets/traducao_palavra.dart`, `BalaoPalavra`
num Overlay, não toma o foco: dá para seguir digitando; fecha no ✕, tocando fora, com **Esc** — que nesse caso NÃO é "não sei" — e na
próxima frase). Conteúdo:
- **Ao pé da letra:** `assets/ingles/dicionario.json` (3.132 palavras do curso + leituras, gerado por 6 agentes; ~106 KB) via
  `domain/dicionario.dart` (`Dicionario.literal`: exata, apóstrofo curvo, e cai na base para plural/-ed/-ing/'s dizendo "(de X)") e
  `data/dicionario_ingles.dart` (carrega no 1º toque). Teste garante que TODA palavra do currículo tem entrada.
- **No contexto:** se a palavra está no `alvo` da frase, mostra `alvo → alvoPt` (instantâneo, sem IA); senão o Prof. Dash
  (`PedidoPalavra` em `ia/domain/explicacao.dart`, resposta de ≤2 linhas) pelo **`IaPalavrasCubit`** — cota PRÓPRIA (150/dia, só no
  aparelho, pref `ia_cota_palavras_v1`) e cache próprio (`ia_palavras_v1`, 800 itens): não gasta os 30 do "Por quê?". Sem rede:
  "Tentar de novo" (não gasta). Provido em `main.dart::_comIa` (agora `MultiBlocProvider`).
- `FraseView` ganhou `traducao` e `alvoPt` (passados pelo `PalcoIngles` e pela `SessaoMemoriaPage`).

**Montar/Falar cobertos:** com 🧩 Montar ou 🎤 Falar a frase vira tracinhos (pontuação fica) até ser respondida, em QUALQUER degrau
(inclusive a cópia D1). O "não sei" agora existe também na cópia coberta (único jeito de ver; cópia não gera nota). O 👁 (`mostrarTudo`)
continua mostrando tudo. O teste antigo "na cópia não há não sei" virou "na cópia a frase fica coberta e há não sei".

**Prova:** `test/ingles_palavra_test.dart` (14) + suítes ingles_*/ia_*/smoke (946) verdes; Chrome real no probe (1027 e 390 px):
balão abaixo/acima da palavra conforme o espaço, "morning" → "Good morning → Bom dia" sem IA, "Mike" → Dash (falso do probe),
digitar com o balão aberto funciona, Montar/Falar cobertos. Probe apagado. **Publicado** (hosting, 14/out/2026) e **commitado + push** (2153671, junto com todo o trabalho pendente da árvore).
Ideia não feita: o mesmo toque na palavra nos cartões (`SessaoCartoesPage`) e na leitura — o `BalaoPalavra` já é reaproveitável.

## 🆕 20/out/2026 — Inglês: palavras novas, treino, Minhas palavras, Arcade com as palavras das lições e mapa estilo Duolingo (FEITO; sem commit/deploy)

Tudo **só no inglês** (gated em `st.ehIngles` / `Linguagem.atual == ingles` / `PalavrasCubit.de(context) != null`); Dart e C#
ficam idênticos (vocabulário do arcade, RNG do Turismo, mapa antigo). Plano completo: scratchpad da sessão (`plano_final.json`).

- **Palavras novas da lição** (`ingles/domain/palavras_novas.dart`, puro): tokens de `Trecho.cod` na ordem do curso; nova =
  1ª vez no curso, base ainda não vista (lema "(de X)" ou `Dicionario.bases`), fora das ~90 palavras de função, ≥3 letras,
  sem apóstrofo/número/soletrada, não é nome próprio nem personagem, existe no dicionário; até 8 por lição (as do `alvo`
  primeiro). `IndicePalavras` (memoizado, montado preguiçoso pelo `PalavrasCubit.prepararIndice`, NÃO no curriculo_loader)
  dá `novasPorLicao`, `poolPorLicao` (o que vai para os jogos: inclui palavras de função), `novasDaTrilha`, `traducao`.
  `traducaoCurta` corta o verbete para caber embaixo da palavra. Hífen/apóstrofo: treina, mas não entra nos jogos.
- **Banco de palavras** (`domain/banco_palavras.dart`, `data/palavras_repository.dart`, `presentation/palavras_cubit.dart`):
  só guarda o que não se deriva (treinadas, adicionadas, editadas, escondidas, cartões FSRS, contadores do jogo, `emTreino`);
  as palavras das lições vêm do currículo + `concluidas` (sem migração quando o curso cresce). **Separado da revisão das
  frases** (não infla "para revisar hoje"). Repositórios: `Local` (`en_palavras_{uid}`), `Memoria` (testes), `Firestore`
  (`users/{uid}/palavras/v1`, local primeiro, nuvem mescla e falha calada). DI em `main.dart` (`palavrasBuilder`).
- **Fim da lição:** na vitória de lição nova (não repetida) com 2+ palavras novas, `CartaoPalavrasNovas`
  (`Key('vitoria-palavras')`): "🆕 N palavras novas nesta lição" + "🎯 Treinar agora"; depois "✅ Treinadas · 🎮 já estão
  no Arcade". Enter/Esc continuam sendo da vitória.
- **Treino de palavras** (`domain/roteiro_treino.dart` + `treino_palavras.dart`/`treino_palavras_page.dart` + `widgets/treino/`):
  até 8 por sessão (mais = lotes): conhecer → escolher o PT → pares → 🎧 ouvir e escolher → digitar; errar volta 3 passos
  depois; nota = pior 1ª tentativa; resumo com baú + confete, "🎮 Jogar com essas palavras" (põe em foco e abre o Arcade).
  Registra FSRS das palavras, o hábito do dia e, se veio, `ProjetoConcluido('bau:<baralhoId>')`.
- **Minhas palavras** (`minhas_palavras_page.dart` + `widgets/adicionar_palavra_sheet.dart`): contagem, "Revisar agora",
  "Jogar com elas", filtros (Para revisar / Das lições / Minhas / Da leitura / Fora dos jogos), busca, força em 4 pontos,
  🎮 liga/desliga do jogo, editar tradução, remover (só as suas). Adicionar: só letras A–Z (2–14), PT do dicionário ou "✨
  Traduzir" (MyMemory), modo "colar lista". Abre pelo card "📚 Minhas palavras" do mapa e pelo hub do Arcade.
- **Arcade com as palavras das lições + tradução** (`arcade/domain/vocabulario_jogo.dart`, `ingles/domain/vocabulario_aluno.dart`,
  `BancoArcade.vocabulario/baralhoRali/registrarJogo`): ordem = foco/emTreino → vencidas/fracas → lição atual + 5 últimas
  concluídas → as suas + "Meus cartões" → amostra das antigas (as do teste de nivelamento entram aqui, limitadas) → listas
  fixas para completar 12. Tradução embaixo (`LegendaTraducao`, sempre um Text separado) na Chuva, no Rali, no HUD do
  Turismo, no Canvas (`pista_gt.dart`) e no 3D web (`vista_3d_web.dart` → `turismo3d.js pintarPainel/pintarPlaca`).
  Vistas/erros por palavra vão para o banco (sem FSRS). Rali "modo memória" (`Key('rali-memoria')`: PT grande, EN em
  esqueleto) alimenta o FSRS. Hub: cartão "Minhas palavras" (`Key('arcade-minhas-palavras')`) no lugar da Lógica Animada.
- **Mapa estilo Duolingo** (só inglês; `curso/presentation/pages/mapa/*` + `curso/domain/mapa_regras.dart`): caminho em
  seno, nó 3D que afunda (`No3D`: feita/atual/disponível/trancada só na aparência — ainda abre, a folha oferece o teste da
  unidade), 3 estrelas pela nota, chip "🆕 N", balão COMEÇAR (`Key('mapa-comecar')`), faixa da unidade com cor por etapa e o
  rosto do personagem principal (`RostoPersonagem`, estático), guia da unidade, estrada `TrilhoIngles`, baú no fim da
  unidade, comemoração (pop + confete) ao voltar com lição nova, rolagem até a lição atual + "📍 Onde parei"
  (`MapaPage.rolarAoAbrir` desliga nos testes), card "📚 Minhas palavras" e "🆕 Treinar as palavras novas" na folha da lição.
  Sem Timer: só AnimationControllers de uma vez (o atual e o baú pronto repetem) — `pumpAndSettle` continua funcionando.

**Testes:** suíte inteira em 20/out: **1.553 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`); +151 desde
o começo do trabalho. Novos: `ingles_palavras_novas`, `ingles_banco_palavras`, `ingles_palavras_repository`,
`ingles_palavras_cubit`, `ingles_roteiro_treino`, `ingles_treino_palavras_ui`, `ingles_minhas_palavras_ui`,
`ingles_vocabulario_aluno`, `arcade_ingles(_ui)`, `turismo_ingles`, `mapa_regras`, `ingles_mapa_ui`, `festa` e o ponta a
ponta `ingles_palavras_app_test` (PacDartApp: lição → cartão → treino → "Jogar" → hub com as palavras em foco → Chuva com
palavra da lição + PT → mapa comemora e a folha oferece as palavras → "mango" adicionada aparece no vocabulário dos jogos).
`flutter analyze lib test`: sem avisos.

**⚠️ Operação (nada publicado ainda):**
1. **`firebase deploy --only firestore:rules` ANTES do hosting** (bloco `match /users/{uid}/palavras/{doc}`). Sem as regras o
   app não quebra (fica só no aparelho), mas não sincroniza.
2. As legendas do 3D (`turismo3d.js`) não têm teste automático: conferir com **UM** build de prova numa pasta reaproveitada
   e apagá-la depois (nada de `flutter build web` em loop — regra de build). Conferir o mapa a 360/412/1440 e na paleta clara
   e o Turismo a 2560×1080 (receita Playwright de sempre).

## 🔥 20/out/2026 (rodada 2) — Palavras teimosas · treinar antes da lição · pacote de desempenho do Arcade (FEITO; sem commit/deploy)

Tudo das teimosas é **só inglês** e null-safe (`PalavrasCubit.de(context)?.…`); Dart/C# e telas sem cubit não mudam (params
novos default null/false, RNG do Turismo intocado). Sem Timer. Planos: scratchpad da sessão (`plano_teimosas.json`, `plano_desempenho.json`).

- **Palavras teimosas** (`ingles/domain/erros_palavra.dart`, `teimosas.dart`, `licao_de_palavras.dart`; `widgets/cartao_teimosas.dart`):
  erros por palavra capturados na lição (passos de memória; cópia, 👁 e "foi erro de digitação" não contam), na Revisão de memória,
  nos cartões PT→EN e nos jogos (Chuva/Rali/Turismo via `arcade/domain/tropecos.dart` `TropecosDoJogo`); carga de erro que decai,
  DOMINADA só num acerto limpo (jogo nunca domina). Oferta (`sugestao`: fim de lição/revisão/entre fases, adiar/recusas):
  `CartaoTeimosas` na vitória (treinar só elas · jogar com elas · 📝 virar lição · agora não), `ChipAnotada` ("anotei", máx. 2
  por lição), `ListaTeimosas` nos resumos, `SeloDominada` 🏆. Treino **revanche** (relembrar → ouvir e escolher → digitar sem a
  1ª letra → 2ª rodada de digitar). Minhas palavras: seção/filtro "Teimosas (N)", medidor 🔥, "errou Nx · há D dias", "Já sei
  essa" (some por 2 semanas), prateleira 🏆 Dominadas. Mapa: "· K teimosas" no card; Sanguessugas: "🎯 Treinar as palavras desta frase".
  Arcade: `AvisoArcade` (toast), `PainelTropecos` entre fases do Rali, `OfertaTeimosasFim` com "⚡ Revanche no jogo", linha
  `arcade-teimosas` no hub. JSON antigo do banco re-codifica byte a byte igual (testado).
- **Treinar antes da lição** (`CartaoAntesDaLicao`, `Key('antes-palavras')`): lição nova com 2+ palavras ainda não treinadas mostra
  "🆕 Esta lição tem N palavras novas" + "🎯 Conhecer antes" (atalho ⌘/Ctrl Enter) / "Começar direto"; a 1ª tecla o dispensa,
  não toma foco; pulado 3 vezes seguidas vira uma linha só. Na vitória: "✅ Você já treinou essas palavras" + "🔁 Revisar de novo";
  com teimosas o card das novas fica compacto ("🆕 +N palavras novas já entraram no Arcade 🎮").
- **Desempenho do Arcade** (visual igual): Pac3D com `animado` (hub só mastiga no hover, Lógica Animada só no ato 3; Chuva/Rali
  param atrás dos overlays) · `TickerMode` no jogo da Corrida/Rali/Chuva/Missão · Ticker da Chuva e do Turismo só ligado em
  corrida (para em pausa/fim/menu) · HUD do Turismo ~30 Hz por tempo · `RepaintBoundary` em pista/avatares/campo/minimapa/cabeçalho ·
  `BarraTempo` 180 ms · `CampoTeclas` sem cursor piscando · torcida do gol em `drawRawPoints` · minimapa com traçado em cache ·
  estilos do `Mixart` em cache · 3D web: teto de 60 fps acima de ~90 Hz, imagem congela na pausa/1,5 s após o fim, `three.core.min.js`,
  módulo 3D carregado sob demanda (`await window.turismo3d.carregar()` antes de `montar` em receitas externas!), `no-cache` em
  `/turismo3d/**` no `firebase.json`. **Pulado:** build wasm, cache longo de /assets3d e /lib3d, teto de 60 Hz no `_tick` da
  Chuva (mexeria na ordem do RNG), refatoração grande do HUD do Turismo, blur/MaskFilter, `deferred` no hud.
- **Prova no build web (20/out, 1 build):** abre sem erro no console (só avisos de fonte Noto e RGBELoader); sem modo convidado,
  então mapa/hub não foram abertos no navegador (cobertos pelos testes). Tela de login parada = **0 rAF em 3 s**. Turismo 3D
  montado à mão no build: só carrega `turismo3d.js` + `three.core.min.js` sob demanda, placas e painéis mostram a tradução
  (house/casa, water/água), 121 renders em 2 s correndo → **1 na pausa** → 120 ao retomar.

**Testes:** suíte inteira em 20/out (rodada 2): **1.657 testes, 1.652 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`);
114 arquivos. Novos: `ingles_erros_palavra`, `ingles_teimosas`, `ingles_licao_de_palavras`, `ingles_teimosas_sessoes`,
`arcade_tropecos`, `arcade_teimosas_ui`, `arcade_frames_ocioso`, `arcade_frames_jogos` (hub assenta no `pumpAndSettle`; jogos sem
frames em pausa/fim). `flutter analyze lib test`: sem avisos. ⚠️ Com o hub ocioso, `tester.pump()` puro pode não entregar um
update do cubit: use `pump(Duration.zero)`.

## 🎵📚 20/out/2026 (rodada 3) — Escolher as lições das palavras do Arcade · música do Turismo que parava na largada (FEITO; sem commit/deploy)

Pedido do Carlos: "quero escolher referente a quais lições vão ter as palavras nos jogos" e "a música começa a tocar na carga
da corrida e para quando a corrida começa".

- **Lições das palavras (só inglês)** — `arcade/presentation/escolher_licoes_page.dart` (`abrirEscolherLicoes(context)`):
  no hub, card "Minhas palavras", botão **"📚 Palavras: Automático / N lições"** (`Key('arcade-escolher-licoes')`). Tela cheia
  com o curso agrupado por nível → unidade (card recolhível com "marcar tudo") → lição (status feita/atual/liberada/🔒, nº de
  palavras e 3 exemplos EN/PT). Só dá pra marcar o que o mapa já liberou. Atalhos ✨ Automático · ✅ Todas as concluídas ·
  Limpar; chave "Incluir minhas palavras"; barra fixa com o total ao vivo ("N lições · P palavras + K suas") e os avisos
  (poucas palavras → completa com as mais usadas; poucas longas 9+ letras; >120 → cada jogo sorteia até 120); "Salvar a
  escolha?" ao sair com mudança (Descartar / Continuar escolhendo / Salvar). Ids que sumiram do curso caem no próximo Salvar.
  - Dados: `BancoPalavras` ganhou `licoesJogo` ('lj', null = Automático), `minhasNoJogo` ('lm':0 só quando desligado) e
    `licoesJogoEm` ('le'; o mais novo vence no `mesclar`) — viaja no mesmo doc do Firestore (`users/{uid}/palavras/v1`),
    sem mudar regras; JSON antigo re-codifica byte a byte igual.
  - `IndicePalavras.palavrasDeJogo(licao)` (novas primeiro + demais palavras de conteúdo das frases traduzíveis + cartões de
    uma palavra); `montarVocabularioIngles(..., licoesEscolhidas, incluirMinhas)`: foco/revanche primeiro, as suas até 1/3 de
    cada faixa, depois as lições em revezamento (ordem das lições e palavras sorteadas por dia), enchimento só abaixo de 12
    por faixa. `VocabularioJogo` ganhou `enchimento`, `enchimentoLongas` e `minhas`. Chuva/Rali/Turismo não mudaram: já leem
    `BancoArcade.vocabulario(context)` no `initState`.
  - Rali: o intervalo da CPU virou `intervaloCpuRali(...)` (puro, testado). Dart/C# igual ao HEAD; inglês com piso 2,4 s,
    +140 ms por letra acima de 5 e ×1,25 (×1,4 de memória). **Confirmar se o rebalanceamento do inglês fica.**
- **Música do Turismo — causa:** o 1º `atualizar()` do Dart só chega com a cena **pronta**; na carga o JS usava um estado
  padrão sem `som`/`musica` (= tudo ligado). E `atualizarMusica` exigia `e.som !== false`, sendo `som` o liga/desliga GLOBAL dos
  efeitos (`Sons.ligado`, prefs `som_ligado`, o alto-falante do HUD das lições, que não aparece no arcade). Quem desligou os
  efeitos numa lição ouvia a música subir na carga e sumir em ~1,5 s quando a cena ficava pronta (bem na contagem/largada),
  com o chip dizendo "🎸 Rock ligado". **Correção:** a música segue só o 🎸, a pausa e o fim (motor/vento/batida/pneu
  continuam no `som`); `montar` recebe `som` e `musicaLigada` no config (`config.musica` já é a URL) e monta um `estadoCarga`
  que vale até o 1º estado (`estado || estadoCarga || …`). Arquivos: `web/turismo3d/turismo3d.js`, `widgets/vista_3d_web.dart`.
  Se um dia o mudo global tiver que calar a música também, é só voltar o `e.som` no `atualizarMusica` — mas aí a tela do
  Turismo precisa mostrar isso.
- **Prova no build web (20/out, 1 build, `build/web` = build de deploy; `privacidade.html`/`excluir-conta.html` removidos):**
  `main.dart.js` leva `musicaLigada`; Turismo montado à mão (Playwright, `play/pause/volume` instrumentados): com efeitos
  mudos e 🎸 ligado a música sobe na carga (0,4→0,53), segue na contagem e fica em **0,6 a corrida toda**; pausa → 0 → retoma
  0,59; 🎸 desligado no meio → 0 → religado 0,59; tudo ligado igual; carga com 🎸 desligado fica em 0 do começo ao fim (o
  `<audio>` dá `play()` mudo, volume 0). Troca de faixa entre corridas: pause do elemento velho + play do novo, sem erro.

**Testes:** suíte inteira em 20/out (rodada 3): **1.684 testes, 1.679 passam, 5 falham** (as 5 de sempre do
`csharp_curriculo_test`); 117 arquivos. Novos: `arcade_licoes_jogo` (codec/back-compat/merge, vocabulário com escolha,
revezamento por dia, teto de 40, as suas com 1/3), `arcade_escolher_licoes_ui` (hub → tela → salvar; avisos; bloqueadas;
diálogo de saída; teclado; ids fantasma), `arcade_rali_intervalo`. `flutter analyze lib test`: sem avisos.

## 🔊 20/out/2026 (rodada 4) — Arcade (inglês) fala a palavra · chip "🔊 Voz" (FEITO; sem commit/deploy)

- **O quê:** no modo inglês, Rali, Turismo e Chuva falam a palavra em voz alta (mesma voz das lições, `VozIngles`,
  velocidade normal). Helper novo `lib/features/arcade/presentation/voz_jogo.dart` (`VozDoJogo` + `BotaoVozJogo`): não repete
  a mesma palavra em 1,5 s (`forcar: true` pula a janela), palavra nova corta a anterior, cala na pausa/fim, com o chip
  desligado, em Dart/C# e antes do 1º toque/tecla; para ao sair do jogo. Liga/desliga por aparelho em prefs
  `arcade_falar_palavras` (ligado por padrão). Não segue o mudo global `Sons.ligado` (não aparece no arcade).
- **Quando fala:** Rali → 1ª palavra logo depois do 3-2-1 e cada palavra nova; fim de fase não fala a próxima; memória só
  fala depois de digitada; ao retomar da pausa repete a palavra (forçada) se ainda não começou. Turismo e Chuva → na 1ª
  letra certa que trava a palavra (portal, gasolina ou gota), nunca só por aparecer.
- **Turismo web:** ao falar, a música da fase desce ao volume de batida por 1,4 s via `api.abaixarMusica(ms)` novo no
  `web/turismo3d/turismo3d.js` (não encurta um abaixamento maior em curso; JS velho em cache = só não abaixa). Canvas
  (não web) ignora (`vista_3d_stub/controlador`).
- **Chip** `Key('arcade-voz')` (semântica com toque, "voz das palavras ligada/desligada"): Rali/Chuva ao lado da pausa (Rali
  também na tela inicial); Turismo nas opções ao lado do 🎸 Rock com rótulo longo ("🔊 Falar palavras ligado/desligado") e na
  corrida no fim dos chips de placar (ao lado da câmera/pausa estourava 65 px em 360 px). Some em Dart/C#.
- **Não provado em navegador real:** a voz de verdade e o abaixar da música no Turismo 3D.
- **Bug antigo (já no HEAD, não corrigido):** fechar o Rali na tela inicial, antes de correr, dá em debug "Looking up a
  deactivated widget's ancestor is unsafe" — o `dispose()` cria o `late final _cpuCtrl` pela 1ª vez no desmonte.

**Testes:** suíte inteira em 20/out (rodada 4): **1.704 testes, 1.699 passam, 5 falham** (as 5 de sempre do
`csharp_curriculo_test`); 119 arquivos. Novos: `voz_jogo_test` (unidade, falante falso via `VozDoJogo.falanteDeTeste`) e
`arcade_voz_ui_test` (regras de cada jogo, chip salvo/religado, pausa corta, retomar repete, Dart mudo, semântica, 360 px).
`flutter analyze lib test`: sem avisos. 1 `flutter build web` (`build/web`, `privacidade.html`/`excluir-conta.html`
removidos); `build/web/turismo3d/turismo3d.js` idêntico ao `web/` (tem `abaixarMusica`).

## 🔁 20/out/2026 (rodada 5): baralho por fase — palavras novas a cada fase, erradas/lentas voltam (FEITO; sem commit/deploy)

- **Pedido:** cada fase com palavras diferentes, quantidade crescendo, e repetir de propósito as que o jogador errou ou
  demorou. **Só no modo inglês** (`BancoArcade.soDigitacao`/`Linguagem.ingles`); Dart e C# idênticos ao HEAD 4b6b5fb.
- **Núcleo novo** `lib/features/arcade/domain/baralho_fases.dart`: `BaralhoFases` (implementa `FonteDePalavras`),
  `DeckFase`/`CartaFase`/`OrigemCarta` (nova, deNovo, foco, errou, lenta, dificil), `CronometroPalavra`.
  - Rodízio: só palavra ainda não vista no jogo; repete (a menos recente primeiro) só depois de ver o pool todo.
  - Revisão ≈35% da fase (mín. 1, máx. metade), nunca a 1ª carta, nunca duas seguidas. Ordem: perdeu > errou > lenta >
    difícil do banco (teimosas, depois fracas; ≤2 por fase, via `BancoArcade.dificeisDoBanco`).
  - Lenta = ms/letra > 1,6× a mediana do jogador (precisa de 8 amostras; pausa e 3-2-1 não contam). Muito lenta (>2×, 2 vezes)
    vai pro banco no fim (`PlacarPalavras.enviar(lentas:)`, falha 0,2 — lentidão sozinha não vira teimosa).
  - Palavra com ≥2 erros volta 3–5 palavras depois na mesma fase (máx. 2 por fase; não no Rali).
  - Extras: `emJogo` (Chuva: o que ainda cai não volta como "nova"), `alcance` (Rali: revisões dentro das ~2/3 cartas que
    o jogador digita de fato), `proximaExtra` (Turismo: 2ª saída fora do baralho), `devolver` (desviar do 🔁 não o libera).
  - Bug web corrigido: o "deNovo" usava um valor inicial que vira 0 em JS e travava em 2 palavras; conferido com `dart compile js`.
- **Rali:** fase N = `tamanhoRali` 12, 14, 16… até 20 (pista cresce junto); revisões espalhadas no alcance
  (8, 10, 11… até 14). Linha no 3-2-1: "Fase 2 · até 14 palavras · 10 novas · 4 pra revisar 🔁"; "🔁 REVISÃO" ao lado de
  PALAVRA n e no "a seguir" (que agora para no fim da fase). "Jogar de novo" traz as pendentes da partida anterior. Memória
  usa o mesmo baralho (só palavras com tradução).
- **Chuva:** nível N = `tamanhoChuva` 8, 10, 12… até 16 palavras; 🔁 no chip da gota. Volta quem caiu (em até ~6 palavras),
  quem levou ≥2 erros ou foi lenta. Velocidade/spawn continuam subindo a cada 8 destruídas como no Dart
  (`TiroEngine.nivelDoRitmo`). Rodapé em inglês explica o 🔁. Gancho de teste `ChuvaPage.relogioDeTeste`.
- **Turismo:** cada corrida = 1 fase, 1 carta por portal (`TurismoEngine.portaisDaPista`); pistas maiores = mais palavras.
  Erradas/lentas da corrida anterior voltam cedo (portal 2, depois alternado). Na corrida, ≥2 erros = volta como gasolina
  3–5 depois, "🔁 REVISÃO". Linha: "Pista 2 · 49 palavras · 48 novas · 1 pra revisar 🔁". Correção à parte: card do carro na
  garagem estourava em 360 px (`Flexible`).
- **Widgets:** `widgets/linha_fase.dart` (`LinhaFase` `Key('fase-intro')`, `MarcaRevisao` 🔁 com semântica "revisão").
  Keys novas: `rali-alvo`, `rali-revisao`, `turismo-palavra-0`, `turismo-gas`.
- **Não provado em navegador real:** a progressão jogada de ponta a ponta (só testes de widget + check JS do núcleo).

**Testes:** suíte inteira em 20/out (rodada 5): **1.781 testes, 1.776 passam, 5 falham** (as 5 de sempre do
`csharp_curriculo_test`); 123 arquivos. Novos: `arcade_baralho_fases` (núcleo + glue do banco + widgets),
`rali_fases_ingles`, `chuva_fases_ingles`, `turismo_fases_ingles`; ajustados blocos de inglês em `arcade_ingles_ui`,
`arcade_voz_ui`, `arcade_teimosas_ui`. `flutter analyze lib test`: sem avisos. 1 `flutter build web` (`build/web`,
`privacidade.html`/`excluir-conta.html` removidos).

## 🎧 Ouvir — Fase 8 (20/out/2026, EM IMPLEMENTAÇÃO; falta a validação do líder e a prova em aparelho; sem commit/deploy)

- **Pedido do dono:** uma seção para só ESCUTAR as lições em sequência — o curso inteiro na ordem ou setlists pessoais montadas
  "conforme for fazendo" (uma frase, parte da lição, a lição, a unidade, a etapa ou tudo) — com um player que continua tocando enquanto
  navega. **Só no inglês**; Dart e C# não mudam. Plano completo (contrato, grupos, UI, textos, chaves, testes): `planejamento/FASE-8-OUVIR-PLAYLIST.md`.
- **Decisões (padrões da v1):** lição trancada toca (🔒 "Lição à frente — pode ouvir à vontade"); ouvir **não** marca progresso nem conta na
  sequência; português pela voz pt-BR do navegador (sem ela, silêncio do mesmo tamanho e o texto na tela); modo padrão **Só inglês**;
  no nativo só com o app aberto.
- **Feito em 4 grupos com arquivos separados** (Fase 0 = esqueletos com as assinaturas; depois A domínio/persistência/regras, B áudio e
  motor, C telas, D fiação). Código novo em `lib/features/ingles/{domain,data,presentation/ouvir}/` (`setlist.dart`, `fila_ouvir.dart`,
  `config_ouvir.dart`, `saida_audio.dart`, `setlists_repository.dart`, `preferencias_ouvir.dart`, `saida_voz_ingles.dart`,
  `sessao_midia*.dart`, `ouvir_cubit.dart`, `setlists_cubit.dart`, `ouvir_acoes.dart`, telas do grupo C); `voz_ingles.dart` ganhou
  `vezGlobal`/`falarNoPlayer`/`falarPt`/`silencio` (aditivo).
- **Fiação (grupo D):**
  - `main.dart`: `PacDartApp(setlistsBuilder:, saidaOuvirBuilder:)`; no `_cursoDe` do inglês `NavegadorOuvir` (um por `uid:linguagem`),
    `SetlistsCubit` (nuvem `users/{uid}/setlists/v1` com cópia no aparelho; sem Firebase, o aparelho) e `OuvirCubit`; o `_AppShell` usa
    `navigatorKey: NavegadorOuvir.de(context)?.chave` e `builder: OuvirShell.envolver` — **o mini-player fica acima do Navigator** e
    sobrevive às rotas. Sem `OuvirCubit` (Dart/C#) o `builder` devolve o filho como veio.
  - HUD: botão **Ouvir** (`ouvir-hud`, aceso enquanto toca). Mapa: cartão "🎧 Ouvir" (`ouvir-cartao-mapa`) depois do "Ler"; folha da lição com
    "▶ Ouvir esta lição", "⏩ Ouvir daqui até o fim do curso" (some em texto próprio), "➕ Pôr na setlist" (toque longo = escolher frases) e
    "Escolher frases…" — a folha fecha antes e agora **rola** em tela baixa. Guia da unidade: "🎧 Ouvir a unidade" + ➕. Palco: ➕
    (`botao-setlist`) ao lado do 🎧 do cartão da frase. Navegador de cartões: "➕ Pôr na setlist" no menu ⋮.
- **Regras:** `firestore.rules` ganhou `match /users/{uid}/setlists/{doc}` e a exclusão de conta apaga `users/{uid}/setlists`
  (grupo A). ⚠️ Publicar as regras **antes** do hosting.
- **Testes novos:** `ingles_setlist`, `ingles_fila_ouvir`, `ingles_setlists_repository`, `ingles_setlists_cubit` (A);
  `ingles_voz_vez_global`, `ingles_config_ouvir`, `ingles_ouvir_cubit` (B); `ingles_ouvir_ui`, `ingles_tocando_ui`, `ingles_mini_player_ui` (C);
  `ingles_ouvir_app_test` (D: ponta a ponta com uma saída de áudio falsa que deixa cada fala pendente — HUD → "Do começo" → mini-player
  nas rotas → ➕ na folha e no palco → "cortada" pausa com aviso → ✕; mais 390 px e o curso de Dart sem nada disso).
- ⚠️ **Armadilha nova:** a saída falsa do teste de app deixa o vigia do passo (`Future.delayed`) pendente; o teste fecha a sessão e dá um
  `pump(30 min)` no fim para não sobrar Timer.
- **Não provado:** áudio com a aba oculta / tela bloqueada, notificação de mídia no Android, Safari iOS, voz pt-BR real.

## 🎧 20/out/2026 (rodada 6): Ouvir / playlist (FEITO e validado pelo líder; falta a prova em aparelho; sem commit/deploy)

- **O que existe (só no curso de inglês; Dart e C# sem nada disso):**
  - **Hub "🎧 Ouvir"** (botão **Ouvir** no HUD, `ouvir-hud`, e cartão "🎧 Ouvir" no mapa): "Curso na ordem" com ▶ Continuar ("Parou em: …"),
    ▶ Da minha lição atual e ↺ Do começo; cartão "Tocando agora / Pausado / Acabou" enquanto o player está ativo; "Minhas setlists"
    (▶, ⋯ Renomear/Apagar, "＋ Nova setlist"); "Explorar o curso" em árvore etapa → unidade → lição, cada linha com ▶ e ➕
    (lição trancada mostra "🔒 à frente" e toca mesmo assim; "Meus textos" com a etiqueta "voz do sistema").
  - **Setlists** com nome e emoji: itens frase, trecho (frases escolhidas de uma lição), lição, unidade/texto, etapa e curso inteiro;
    reordenar arrastando, remover (✕ ou deslizar) com Desfazer, itens indisponíveis em cinza. Até 50 setlists × 300 itens.
    Sincronizam em `users/{uid}/setlists/v1` (mescla por item, lápides de 90 dias, cópia no aparelho gravada na hora; a nuvem espera 600 ms).
  - **➕ "Pôr na setlist"** em 5 lugares: palco (ao lado do 🎧 do cartão), folha da lição no mapa (+ "Escolher frases…"), guia da unidade,
    árvore do hub e menu ⋮ do navegador de cartões. Toque = última setlist usada (snackbar Desfazer/Trocar); toque longo = escolher.
  - **Player:** tela "Tocando agora" (personagem falando, trilha etapa › unidade › lição, EN grande e legenda PT, ⏮ ⏪ ⏯ ⏩ ⏭ ↺, "A seguir",
    atalhos de teclado) e **mini-player persistente acima do Navigator** (some com teclado aberto e na tela cheia; escurece sob folhas/diálogos;
    some e pausa no Arcade). Ajustes: velocidade, repetir 1–3×, pausa Curta/Média/Longa/Eco, modo, "2ª vez devagar", "Repetir tudo",
    timer de desligar. Media Session no web (teclas de mídia / tela bloqueada, melhor esforço).
  - O player **pausa sozinho** quando outra voz do app fala (aviso "outra fala"); uma página que fecha sem ter falado não corta mais o player
    (`VozIngles.parar()` só cala o que é seu; `calarTudo()` fica para o microfone).
- **Padrões da v1:** lição trancada toca; ouvir **não** marca progresso nem conta na sequência/meta; PT pela voz pt-BR do navegador (sem ela,
  silêncio do mesmo tamanho + aviso "Seu navegador não tem voz em português — a tradução aparece só na tela."); modo padrão **Só inglês**;
  no nativo só com o app aberto.
- **Adiado (plano §11):** áudio em segundo plano/tela bloqueada no nativo (`audio_service`, permissões — precisa autorização e mexe na revisão
  das lojas); mp3 pt-BR (~5,3 mil arquivos); receitas "Conversa" e "Pra dormir"; embaralhar, exemplos da teoria e leituras; faixa
  silenciosa p/ notificação no Android (só se a conferência 2 falhar); Wake Lock; "Tocar em seguida"; refazer a fila quando a setlist
  tocando é editada (v1 toca uma foto); posição na nuvem; ➕ na sessão de cartões, no `BannerUnidade` e na vitória do palco; "Só o que já
  estudei"; "⭐ Frases difíceis"; minutos ouvidos no hábito.
- **Validação do líder (21/out, madrugada):**
  - Suíte inteira: **1.951 testes, 1.946 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`); 134 arquivos.
    `flutter analyze lib test`: sem avisos. Nenhum `test/_*_test.dart` sobrando.
  - 1 `flutter build web` (`build/web`, main.dart.js 4,8 MB; `privacidade.html`/`excluir-conta.html` removidos). O aviso de wasm é só do
    `flutter_tts` (pacote de fora, já existia).
  - Navegador (Playwright, servidor local): o app abre na tela de login sem erro do app no console (só um 400 do `securetoken` = sessão velha
    salva no perfil do Playwright, e o aviso de fontes Noto de sempre). O Ouvir fica atrás do login, então não foi clicado. Conferido no
    mesmo Chrome: `navigator.mediaSession` existe, há 9 vozes pt-BR (Luciana etc.) e um WAV silencioso 8-bit tocou num `<audio>`.
- **Falta provar em aparelho de verdade (plano §10):** (1) Chrome desktop com a aba oculta 20 min — a playlist avança e as pausas ficam do
  tamanho certo? (2) Android Chrome com a tela bloqueada — continua e aparece notificação de mídia? (3) Safari do iPhone bloqueado 10 min;
  (4) setlist de texto próprio (Web Speech) com a aba oculta; (5) 🔊 do palco com a playlist tocando → pausa com o aviso; (6) 360 px com
  mini-player + teclado do palco; (7) tema claro.
- ⚠️ **Antes do hosting:** `firebase deploy --only firestore:rules` (bloco `users/{uid}/setlists`).

## ⚡ Treino do dia — Fase 9 (21/out/2026, FEITA e validada pelo líder — ver "rodada 7" logo abaixo; sem commit/deploy)

- **O que é:** um botão **Treino** no HUD (logo depois do chip 🔥 da sequência, `treino-dia-hud`, ícone ⚡) e um cartão "⚡ Treino do dia"
  no mapa (`treino-dia-cartao-mapa`, o 1º depois do painel, **nos 3 cursos**) que abrem o hub `TreinoDiaPage`: uma sessão de ~10 min que
  reaproveita as sessões que já existem. **Inglês:** 🔁 Revisão (8 frases + 4 cartões) → 🔥 Palavras (até 6: teimosas > devidas > fracas) →
  🎧 Ouvir (painel dentro do hub, fonte `⚡ Treino do dia`) → 🏁 Rali (1 fase no Fácil). **Dart/C#:** 2 quizzes de revisão (lições
  concluídas com a pior nota, girando por dia) + 🏁 Rali. Plano completo: `planejamento/FASE-9-TREINO-DO-DIA.md`.
- **Estados do botão:** "Treino" (aceso, nada resolvido hoje) → "Treino 2/4" (aceso, em andamento) → "Treino ✓" (apagado, concluído). O
  relógio de 1 s do Hud relê o plano de hoje: na meia-noite volta a "Treino" sozinho. O cartão do mapa diz "~10 min com o que você precisa
  revisar hoje" / "Continuar · N de M etapas" / "Feito hoje ✓ — volte amanhã".
- **Retomável no mesmo dia, zera à meia-noite local** (`diaDe(habitoAgora())`, o mesmo relógio da sequência). Sair no meio guarda o
  andamento; reabrir continua da próxima etapa pendente.
- **Bônus:** +3 na meta (`bonusTreino`) ao concluir um plano com ≥ 2 etapas feitas, pelo menos uma ativa (revisão/palavras/quiz) com
  resultado real, e plano nem `curto` nem `incompleto`. **1× por conta por dia** (`Habito.bonusTreinoDia`, chave `bt`), qualquer curso.
  Ouvir e Rali continuam sem dar unidades. Nada vai ao ranking.
- **Persistência:** aparelho `treino_dia_v1:{uid}:{curso}` + nuvem no campo `{prefixo}treino_dia` de `users/{uid}` (`treino_dia`,
  `cs_treino_dia`, `en_treino_dia`). **Sem mudança em `firestore.rules`** (o `match /users/{uid}` já cobre; excluir a conta leva junto).
  Divergência do plano §6.1: a gravação na nuvem usa `update({campo: json})` (com `set(merge: true)` se o doc não existe) em vez de
  `SetOptions(mergeFields:)`, porque o `FakeFirebaseFirestore` ignora `mergeFields` e apagava o doc inteiro nos testes.
- **Arquivos:** `lib/features/treino_dia/{domain,data,presentation}/` (`plano_treino.dart`, `montar_plano.dart`,
  `treino_dia_repository.dart`, `treino_dia_cubit.dart`, `blocos_treino.dart`, `treino_dia_page.dart`, `treino_dia_acoes.dart`,
  `widgets/painel_ouvir_treino.dart`, `widgets/cartao_bloco.dart`). Costuras opcionais (padrão = comportamento de antes): `abrirRevisao`
  (limites, `modoTreino`, devolve `FimDaRevisao`), `semOferta` nas sessões de memória/cartões, `semSaidas`/`rotuloContinuar` no treino de
  palavras, `abrirTreinoPalavras`/`treinarTeimosas` devolvem `ResultadoTreino?`, `RaliPage(treino: true)` (1 fase, devolve
  `ResultadoFaseTreino`), `FimDeJogo(mostrarDeNovo:, rotuloDeNovo:, rotuloSair:)`, `QuizPage(semente:, onTerminou:, rotuloFim:)`,
  `HabitoCubit.ganharBonusTreino`.
- **Fiação (grupo E):** `main.dart` ganhou `PacDartApp(treinoDiaBuilder:)`; no `_cursoDe` (os 3 cursos, chave `uid:linguagem`) um
  `TreinoDiaCubit` com a nuvem (sem Firebase iniciado, o aparelho) e `agora: habitoAgora`. `main_portfolio_probe.dart`:
  `treinoDiaBuilder: (u, l) => LocalTreinoDiaRepository(uid: u.uid, curso: l.id)` (o plano sai das fontes locais do probe). Sem o cubit
  na árvore (testes de tela antigos) não há botão nem cartão.
- **Testes novos:** `treino_dia_test`, `treino_dia_repository_test`, `treino_dia_cubit_test` (A); `treino_dia_seams_ingles_test` (B);
  `rali_treino_test`, `quiz_treino_test` (C); `treino_dia_blocos_test`, `treino_dia_ui_test` (D); `treino_dia_app_test` (E: o app inteiro —
  inglês pula tudo → "Treino ✓" → meia-noite → "Treino"; Dart com 🏁 Rali e sem 🎧; cartão do mapa nos dois cursos; trocar de curso
  guarda o plano de cada um; bônus +3 no inglês e +0 com "Bônus do treino já ganho hoje ✓" no Dart; Dart e C# com lições concluídas
  montam 🧩 quiz + 🧩 quiz + 🏁 Rali (sem quiz primeiro, depois a pior nota; `proj:` ignorado) e o 1º quiz respondido de verdade
  vira "Treino 1/3" com as respostas no hábito; 360 e 390 px sem estouro).
  Passada de integração: suíte inteira +2109, só as 5 falhas antigas do `csharp_curriculo_test`.
  Os 15 testes que montam o `PacDartApp` (`grep -l PacDartApp test/`) passaram com a pílula nova sem nenhum ajuste.
- ⚠️ **Armadilha nova (testes de app no celular):** com o HUD rolando junto com o palco, o palco pede uma rolagem animada até a frase
  (`zona_visivel.dart`) que no relógio falso não anda, e enquanto ela vive a lista ignora toques no HUD. O `treino_dia_app_test` encerra
  essa rolagem com `position.jumpTo(position.pixels)` antes de tocar na pílula. O relógio de 1 s do Hud nasce dentro do `runAsync` da
  abertura (é um Timer de verdade): para ver a virada do dia no HUD, espere ~1,2 s reais com `runAsync`.
- **Conhecido, não mexido:** no Dart/C#, o Rali em 360 px estoura 18 px na fila "a seguir" (já acontecia fora do treino).

## ⚡ 21/out/2026 (rodada 7): Treino do dia (FEITO e validado pelo líder; sem commit/deploy)

- **O que existe:** botão **⚡ Treino** no HUD (logo depois do chip 🔥) e cartão **"Treino do dia"** no mapa, nos **3 cursos**. Abrem o hub
  `TreinoDiaPage`: uma sessão de ~10 min com as sessões que já existem, em modo treino (sem ofertas de teimosas, sem "Jogar"/"Virar
  lição", sem "Pular quiz"; o botão principal de cada sessão diz "Continuar o treino →").
  - **Inglês (4 etapas):** 🔁 Revisão do dia (até 8 frases + 4 cartões) → 🔥 Palavras (até 6: teimosas > devidas > fracas) → 🎧 Ouvir
    (painel dentro do hub, as frases que acabou de revisar; senão a última lição concluída; senão uma prévia da atual) → 🏁 Rali relâmpago
    (1 fase no Fácil, começa sozinho, com as palavras do treino em foco).
  - **Dart/C# (3 etapas):** 🧩 Quiz · lição A → 🧩 Quiz · lição B (lições concluídas: sem nota de quiz primeiro, depois a pior nota
    relativa ao tamanho do quiz, desempate girando por dia; semente do quiz muda por dia) → 🏁 Rali (1 fase digitando código).
  - Aluno novo: plano **curto** (inglês: Ouvir + Rali; Dart/C#: só Rali) com a dica "o treino de hoje é curto… siga para a sua lição".
  - Cada etapa tem **"Pular esta etapa"**; não há lançamento automático entre etapas (um toque em "▶ Continuar · …" por vez).
- **Padrões adotados (sem perguntar):** limites 8 frases + 4 cartões / 6 palavras / 6 frases ouvidas / 1 fase do Rali / 2 quizzes;
  conteúdo de cada etapa escolhido na hora em que ela começa; retomável no mesmo dia, zera à meia-noite local (`habitoAgora`);
  **bônus +3 na meta** ao concluir com ≥ 2 etapas feitas, ao menos uma ativa (revisão/palavras/quiz) com resultado > 0, plano nem curto
  nem incompleto — **1× por conta por dia** (`Habito.bonusTreinoDia`), qualquer curso; Ouvir e Rali continuam sem dar unidades; nada vai
  ao ranking. Após 8 s sem as fontes: "Tentar de novo" / "Começar assim mesmo" (plano `incompleto`, completado depois).
- **Correções da revisão (rodada de fixes):** plano concluído (até o curto) não "revive" ao reabrir; JSON sem bloco utilizável → plano
  novo; `FirestoreTreinoDiaRepository`: leitura com prazo de 10 s (cai na cópia do aparelho) e `salvar` espera **só o aparelho** (a nuvem
  vai numa fila própria, a mais nova vence, erros engolidos — offline não trava mais as gravações); voltar (sistema/navegador) no fim do
  Rali devolve o resultado; sessão de Ouvir de outro dia não é creditada; leitores de tela leem o cartão atual uma vez; "Começando…" e
  avisos com `liveRegion`; cartão do mapa vira à meia-noite (relógio de 1 s).
- **Validação do líder (21/out):**
  - Suíte inteira: **2.128 testes, 2.123 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`); 143 arquivos de teste.
    `flutter analyze lib test`: sem avisos. Nenhum `test/_*_test.dart` sobrando.
  - **1 build** do probe (`flutter build web -t lib/main_portfolio_probe.dart --release --output=build/probe --no-wasm-dry-run`, ~29 s),
    servido em `python3 -m http.server`, **apagado depois** (`find build/probe -delete`). `build/web` não foi tocado; nada publicado.
  - **Chrome (Playwright), 1027 e 390 px, 0 erros de console e 0 `pageerror`** (só o aviso de fontes Noto de sempre). Semente no
    `localStorage`: `en_revisao` com 12 frases vencidas ontem, `en_concluidas` com 2 lições, `concluidas` 0:0–0:2 e `quiz_notas` 0:0=5.
    - Inglês: HUD "⚡ Treino" aceso → hub com as **4 etapas** (~9 min) → Revisão aberta (8 frases) e **saí no meio pela ←: continuou
      pendente** → reabri e digitei as 8 → "✓ Feito · 8 revisadas" + faixa "Próximo: 🔥 Palavras" → pulei Palavras → **Ouvir tocou as 6
      frases revisadas sozinho** ("Frase 2 de 6" … "✓ Feito · 6 frases ouvidas") → Rali começou sozinho (sem tela de início), saí pela ←
      (pendente) → pulei → "Treino do dia completo! ⚡", **"+3 na meta pelo treino completo ⚡"** (meta 13/20 = 10 respostas + 3) → HUD
      **"Treino ✓"** apagado; cartão do mapa "Feito hoje ✓ — volte amanhã".
    - Dart: HUD "Treino" aceso → **🧩 Quiz · Decimais → 🧩 Quiz · Inteiros → 🏁 Rali** (as sem nota primeiro; Variáveis com nota ficou de
      fora) → quiz abriu sem "Pular quiz", voltei pela ← (pendente) → pulei → fechei → **390 px: HUD "Treino 1/3"** → reabri no mesmo
      bloco → Rali de código a 390 px (sem estouro com as palavras sorteadas) → pulei tudo → "Hoje foi só uma passada", **sem linha de
      bônus**, meta inalterada → HUD "Treino ✓".
    - De volta ao inglês a 390 px: HUD "Treino ✓"; reabrir mostra "Volte amanhã para um treino novo 🌅" e "Bônus do treino já ganho hoje ✓"
      (sem bônus de novo).
    - Capturas em `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/smoke_treino/` (35 PNGs, temporárias).
  - ⚠️ **Receita da prova:** a ferramenta de captura do MCP só grava dentro do projeto; para salvar no scratchpad use
    `page.screenshot({path})` dentro de `browser_run_code_unsafe`. O plano com 4 etapas no inglês precisa de material: semear
    `flutter.en_revisao` (formato antigo `"caixa|proximoDia|lapsos"`, `proximoDia = diaDe(ontem)`) e `flutter.en_concluidas` — sem isso o
    aluno do probe é novo e o plano sai curto (Ouvir + Rali). No Playwright, `keyboard.press('Tab')` não preencheu letras na revisão; digite a frase com `keyboard.type`.
- **Adiado (plano §14):** texto do lembrete falando do treino; contador "treinos seguidos" e calendário semanal; escolher a duração
  (5/10/15 min) ou tirar/reordenar etapas; Chuva/Turismo como etapa de jogo; Dart/C# com SRS de verdade (precisa de datas no progresso),
  Desafios como etapa, reescrever um trecho antigo; inglês com ditado/shadowing como etapa e sanguessugas nas teimosas; bônus sem
  duplicar entre aparelhos offline (servidor) e sincronizar o Ouvir em andamento. Também não feito: `FirestoreHabitoRepository.salvar`
  ainda espera a nuvem (mesmo travamento offline que foi corrigido no treino); o Rali do Dart/C# em 360 px ainda estoura 18 px na fila
  "a seguir" com palavras longas.
- **Falta conferir à mão (o dono):** (1) Rali jogado até o fim no treino → tela "FASE VENCIDA! ⚡" / "A CPU VENCEU…" com "Continuar o
  treino →" (coberto por teste, não no Chrome); (2) etapa 🔥 Palavras feita de verdade e o Rali depois com essas palavras; (3) quiz do
  Dart/C# respondido até o fim no navegador; (4) virada da meia-noite com o app aberto (HUD volta a "Treino"); (5) dois aparelhos no
  mesmo dia (o plano mescla; bônus 1×); (6) celular de verdade (teclado + mini-player do Ouvir) e tema claro; (7) logado de verdade
  (Firestore: campos `treino_dia`/`cs_treino_dia`/`en_treino_dia` em `users/{uid}`; **sem mudança de regras**).

## 💬 Conversa com IA — Fase 10 (21/out/2026, FEITA e validada pelo líder — ver "rodada 8" no fim; falta o Gemini de verdade; sem commit/deploy)

Plano: `planejamento/FASE-10-CONVERSA-IA.md` (escrito como FASE-9 e renumerado: o Treino do dia ficou com a 9). **Só Inglês.** Evolui a
2B "💬 Cenários guiados" (mesmas classes `Cenario`/`SessaoCenario`/`CenarioCubit`/`ConversaPage`/`CenariosPage`, mesma chave `conversar`
no mapa); não é uma feature paralela.

- **O que o aluno vê:** no Mapa, o cartão **"💬 Conversa com IA"** ("Converse com a Emma, o Mike… num café, num check-in, numa
  entrevista. Cada fala sua é corrigida na hora — digitando ou pelo microfone."; some sem `RevisaoCubit`/`IaCubit`) → lista de **13
  situações** por etapa (A1×2, A2×4, B1×3, B2×3, C1×1; 5 novas: Pedir comida, Imigração no aeroporto, Conversa num meetup, Code review,
  Negociar uma proposta), cada uma com um **personagem do palco** (`quem`/`nome` no `cenarios.json`), a fila de nível "Seu nível nas
  conversas:" (Automático (Xn) · A1…C1, guardada no aparelho), "Restam N usos hoje · cada fala usa 1" e o selo "⬆ acima do seu nível" →
  a conversa: topo com voltar (pede "Sair da conversa?" se já falou), rosto com boca mexendo (`PersonagemFalante`), título, "com {Nome} ·
  {nível} · restam N usos hoje", 🌐 tradução (ligada em A1/A2) e ⋮ (ler em voz alta / Terminar conversa); caixa do objetivo com "Não use
  dados pessoais de verdade…"; bolhas do personagem com tradução, 🔊 e 🐢; embaixo de cada fala do aluno, **o cartão do Prof. Dash**
  ("✅ Certinho!" ou "✏️ jeito mais natural" com a versão certa, a tradução, o porquê, 💡 dica, 🔊 e "Salvar como cartão"); "{Nome} está
  digitando…"; ideias de resposta numa linha (sempre em A1/A2; atrás de "💡 Ideias de resposta" do B1 para cima) que só PREENCHEM o
  campo; rodapé com campo + 🎤 + ➤. O 🎤 escreve no campo (nunca envia sozinho: "Confira o texto e toque em Enviar.").
  No fim (o personagem encerra, acabam as falas ou ⋮ › Terminar), **o resumo aparece na própria lista**: números, "✏️ Para revisar"
  (cartão + ➕ setlist por correção), "📚 Palavras novas" (até 8, "Adicionar N às Minhas palavras"), "Conversar de novo" / "Outras
  situações". **O resumo não gasta nenhum uso.**
- **Regras que mudaram em relação à 2B (R1–R7):** R1 corrige **cada fala**, num campo separado (`correcao`); o personagem nunca corrige
  e nunca sai da cena · R2 sem 2ª chamada de feedback: **resumo local, 0 usos** · R3 cada turno é **UMA chamada com resposta em JSON**
  (`esquemaTurno`, `correcao` primeiro no `propertyOrdering`) pelo novo `TutorJson` — só o `GeminiTutorService` (web) implementa; quem
  não tem (o `FirebaseAiTutorService` do Android/iOS e os fakes) cai no "JSON no prompt" (`formatoTurnoTexto`) + parser tolerante · R4
  **nível da conversa = o nível do aluno** (o MAIOR nível das unidades até a da fronteira, `fronteira()`, incluída — quem terminou o
  C1 e entrou no DEV continua C1; DEV vindo direto do A2 conta B2; lição feita adiante da fronteira não sobe) ou o que ele escolher;
  `Cenario.etapa` só agrupa e mostra "acima do seu nível" · R5 um **personagem do palco por cenário** (sem `quem` → 🐦 Prof. Dash) · R6
  texto **e microfone** (fecha a D11 da 2B) · R7 histórico de **8** falas (era 12), sem as correções.
- **Proteção da cota (camadas 1–7):** (1) fala de até 300 letras; (2) cota por pessoa de 30/dia, 1 por fala, reservada antes e **gasta
  só quando a resposta é usável** (`aceitar` = `RespostaTurno.interpretar(...) != null`, checado ANTES de gastar); (3) **3 s** entre
  falas (`IaCubit.intervaloMinimo`, só produção — espera em vez de recusar); (4) **janela de descanso do projeto, UMA (`DescansoIa`)
  dividida por `IaCubit` e `IaPalavrasCubit` no `main.dart`**: 429 → 20 s, 40 s, 80 s… até 5 min; 429 diário (RPD) → até a próxima
  08:00 UTC (≤ 12 h, só em memória); 503 → 8 s; 401/403/sem chave → 60 s; sem rede/recusa/outro → sem janela; sucesso zera; durante a
  janela **nenhuma chamada** sai; (5) serviço: timeout **25 s** no `perguntarJson` e **90 s** no `perguntarComo`/`perguntar` (chat do
  Dash, "Por quê?", Escrita), **no máximo 2 requisições HTTP por chamada** (1 retry só de compatibilidade: 400 de thinking/schema ou
  200 vazio com MAX_TOKENS), **sem retry em 5xx/429**; (6) `thinkingBudget: 0`, `maxOutputTokens: 600`, temperatura 0,5, 1–2 frases;
  (7) modelo trocável sem deploy: **`config/tutor.modeloConversa`** (opcional; só aceita `^[a-z0-9.\-]+$`, senão `gemini-flash-latest`).
  ⚠️ Limitação conhecida: o RPM/RPD grátis do Gemini é contado **por modelo**, mas a `DescansoIa` é uma só e não sabe o modelo. Com um
  `modeloConversa` diferente, um 429 diário do flash (no "Por quê?", na Escrita ou no toque na palavra) segura também a conversa (e
  vice-versa) até recarregar a página ou as 08:00 UTC — trocar o `modeloConversa` não solta uma janela diária já aberta no aparelho.
  Janela por modelo ficou para depois.
  Cada falha tem o seu aviso (`cenario-sem-cota`, `-limite` com contagem regressiva no relógio do cubit, `-limite-dia`, `-ocupado`,
  `-sem-rede`, `-indisponivel`, `-recusada`, `-falhou`) e **a fala sempre volta para o campo**; durante a janela só o ➤ fica desligado
  (o campo nunca) e Enter não apaga nada.
- **Erros tipados:** `FalhaIa` (`lib/features/tutor/data/falha_ia.dart`, `TipoFalhaIa` limite/limiteDiario/ocupado/semRede/credencial/
  recusada/outro); o `toString()` continua "Gemini <status>: …" (o `TutorCubit._erroAmigavel` casa texto). `ResultadoIa.motivo` é um
  campo novo opcional — **`StatusIa` NÃO ganhou valor** (quebraria os `switch` exaustivos).
- **Segurança:** o aluno vira DADO entre `<<<ALUNO>>>`/`<<<FIM>>>` (marcadores forjados são tirados); regras "acima de qualquer outra
  instrução"; **dados pessoais mascarados** antes de ir ao modelo (e-mail → `[email]`, link → `[link]`, CPF/telefone de 8+ dígitos →
  `[número]`; valores com moeda, milhar, "120k", datas ISO e números curtos ficam). A correção compara com o texto mascarado (sem ✏️
  falso) e devolve o dado original na tela; correção que tinha dado pessoal **não vira cartão nem item de setlist**. A fala do
  personagem passa por `limparFala` (tira markdown/emoji sem inserir texto — a fala mostrada é a falada). Palavras novas seguem a regra
  do `validarPalavraNova` (`^[a-z]{2,14}$`, sem stopwords): "Adicionar" nunca falha por formato.
- **Voz:** a velocidade preferida é carregada na própria tela (`VozIngles.carregarPreferencia()` antes da abertura); a abertura só é
  falada com voz automática ligada **e** som liberado; **resposta que chega com o microfone ouvindo NÃO é falada** (o reconhecedor
  escreveria a fala do personagem no campo); o 🎤 chama `calarTudo()` antes de ouvir; o avatar do topo só mexe a boca com a fala do
  personagem (o 🔊 da correção e o 🎧 não mexem).
- ⚠️ **Mudança de comportamento intencional:** a janela de descanso depois de um 429/503/401 vale para **tudo que usa IA** — a conversa,
  o toque na palavra, o "Por quê?" e a Escrita. Durante ela o "Por quê?" e a Escrita mostram a mensagem genérica de falha deles, sem
  dizer o motivo (mensagens próprias ficaram para depois, plano §15).
- **Nativo (Android/iOS) na v1:** a conversa usa **"JSON no prompt"** + o parser tolerante (o `FirebaseAiTutorService` não implementa
  `TutorJson`; o esquema nativo ficou para depois, precisa de aparelho para validar). O Firebase AI ganhou só o timeout de 90 s e
  `throw FalhaIa.de(e)`.
- **Nota honesta sobre a cota:** o limite de verdade é o RPM/RPD grátis do projeto `pac-dart`, **dividido por todo mundo**. As camadas 3–4
  diminuem as marteladas, mas não criam uma cota dura (isso pede Cloud Functions ou billing — fora do escopo, como a D4 da Fase 2). Uma
  resposta que chega depois de o aluno sair ainda gasta 1 uso (documentado).
- **Persistência:** **nada no Firestore** e nenhuma conversa salva (sair descarta, depois da confirmação). Ficam só o que o aluno escolhe
  (cartões, Minhas palavras, setlists) e as prefs do aparelho `conversa_nivel` / `conversa_voz_auto`. **Sem mudança em
  `firestore.rules`** (`config/tutor.modeloConversa` mora no doc que o app já lê).
- **Arquivos novos:** `lib/features/tutor/data/falha_ia.dart` · `lib/features/ia/domain/{conversa_resposta,prompt_conversa,
  nivel_conversa,seguranca_texto}.dart` · `lib/features/ia/presentation/{preferencias_conversa,resumo_conversa}.dart` ·
  `lib/features/ia/presentation/widgets/{bolha_conversa,microfone_conversa}.dart` · `test/helpers/tutor_falso.dart` (os tutores falsos
  compartilhados; o `ia_cenario_cubit_test.dart` reexporta `TutorCenarioFalso`/`TutorComPersonaFalso` para os 5 testes de fora da IA
  que os importam por lá).
  **Mexidos:** `tutor_service.dart` (`TutorJson`, `perguntarJson`, `modeloConversa`, timeouts, `FalhaIa`), `tutor_firebase_ai.dart`
  (timeout + `FalhaIa.de`), `chave_gemini.dart` (`campo()`, cacheia o mapa inteiro), `ia_cubit.dart` (`DescansoIa`, `agora()`,
  `consultarJson`, `aceitar`, `motivo`, `esperaAte`), `cenario.dart`, `sessao_cenario.dart` (saíram `personaCenario`,
  `contextoDoTurno`, `pedidoDeFeedback`, `CorrecaoCenario`, `FeedbackCenario`), `assets/ingles/cenarios.json` (13 cenários; a farmácia
  agora é a "farmacêutica" Dra. Lee), `cenario_cubit.dart` (`terminar()` síncrono e local), `conversa_page.dart` (reescrita),
  `cenarios_page.dart`, `feedback_cenario.dart` (saiu o `FeedbackCenarioView`; ficou `salvarCartaoDoCenario`, que não espera mais 5 s quando o mesmo
  cartão já está no baralho), `main.dart` (UMA
  `DescansoIa` para `IaCubit` + `IaPalavrasCubit`; `intervaloMinimo` de 3 s só sem `tutorBuilder`), `mapa_page.dart` (o cartão) e
  `main_portfolio_probe.dart` (o `_TutorFake` responde o turno da conversa em JSON — "want" na fala → correção "Can I have a coffee,
  please?", senão ✅; da 3ª fala em diante `fim: true` — e `ConversaPage.fabricaReconhecedor` usa o reconhecedor de mentira
  `window.__dito`; saíram os ramos `MODO FEEDBACK DE CENÁRIO` e `MODO CENÁRIO`).
- **Testes:** novos `ia_falha_test`, `tutor_json_rest_test` (conta as requisições), `ia_cubit_json_test` (A); `ia_conversa_resposta_test`,
  `ia_nivel_conversa_test`, `ia_seguranca_texto_test` (B); `ia_conversa_voz_ui_test` (C). Reescritos/adaptados: `ia_cenario_test` (B),
  `ia_cenario_cubit_test`, `ia_cenario_ui_test` (C: 360/390/1400 px claro e escuro e 360×640 com teclado de 300 px), `chave_gemini_test`,
  `ia_cubit_test`, `ia_app_test` (A: o relógio anda 21 s depois do 429), `ia_cenario_app_test` (D: o app inteiro — Mapa → "Conversa com
  IA" → café com o rosto da Emma → 3 falas, a 1ª corrigida, a 2ª ✅, a 3ª fecha a cena → o resumo aparece sozinho, **cota 30 → 27 e
  continua 27** → cartão em "Meus cartões" com o inglês → português ligado, sem duplicar pelo cartão da correção → "size" em Minhas
  palavras → hábito +3, ranking intacto; e um 2º caso: `IaCubit` e `IaPalavrasCubit` do app dividem a MESMA `DescansoIa` e um 429 na
  conversa abre a janela para os dois).
- **Adiado (plano §15):** voz diferente por personagem na web; conversa livre sem cenário e cenário por unidade; nota de pronúncia do
  que o microfone ouviu; salvar as últimas conversas e "✓ feita" por cenário; cota dura no servidor e App Check; streaming; repetir a
  cena mais difícil; cenários escritos pelo aluno; JSON com esquema no Android/iOS; mensagens próprias de 429 no "Por quê?" e na
  Escrita; guardar a janela do limite diário no aparelho; expressões (`check-in`, `go over`) em Minhas palavras.

## 🏎️ Turismo — voz no modo SETAS (inglês) (21/out/2026, commitado em `e804b90`; sem deploy)

- No inglês com **🎮 Setas** (ninguém digita, nada trava), o Turismo agora **fala a palavra de cada portal** quando ele vira o alvo
  à frente do carro (`_falarPortalSetas`, chamado no `_tick` depois do `e.tick(dt)` só com `porSetas && correndo && _voz.ativa`): o
  1º na largada (não na contagem), cada seguinte no instante em que o carro cruza o anterior (~2,8 s de antecedência na velocidade
  máxima). **Uma vez por portal** (`_vozPortal` + `identical`), nem de novo ao voltar da pausa; é a `palavras.first`, a mesma do
  cartão das setas (com duas saídas a 2ª fica muda — falada logo depois cortaria a 1ª). Nas setas não há palavra de combustível.
  Voz desligada não marca nada: religada no meio, o portal da vez fala.
- O chip **🔊 (`arcade-voz`)** aparece também nas setas (a condição agora é só `BancoArcade.soDigitacao`). Pausa/sair/fim/dispose já
  calavam a voz — agora valem para as setas também. **Modo digitação: sem mudança** (fala ao TRAVAR, como antes).
- De quebra: os `BotoesSetas` (◀ ▶ ▼ FREIO ▲ GÁS, 336 px) vazavam 16 px no celular de 360 — agora encolhem juntos (`LayoutBuilder`);
  altura e fonte iguais, nada muda em telas normais.
- Teste novo: `test/turismo_voz_setas_test.dart` (chip no HUD, 1º portal na largada, sem repetir, 2º com > 20 m de folga, pausa e
  sair calam, dispose cala, pref desligada = mudo e religar fala o portal da vez, 360 px sem estouro, Dart nas setas sem chip nem voz).

## 💬 21/out/2026 (rodada 8): Conversa com IA (Fase 10) + voz no modo setas do Turismo (FEITO e validado pelo líder; sem commit/deploy)

- **O que existe:**
  - **💬 Conversa com IA** (só Inglês): cartão no Mapa → 13 situações (A1×2, A2×4, B1×3, B2×3, C1×1) com um personagem do palco cada
    → conversa com o rosto falando, o Prof. Dash corrigindo **cada fala** num cartão separado (✅ ou ✏️ + tradução + porquê + dica +
    🔊 + "Salvar como cartão"), ideias de resposta, 🌐 tradução, ⋮ (voz automática / Terminar), digitação **e** 🎤 (o mic só escreve
    no campo) → **resumo local** (números, correções com cartão e ➕ setlist, palavras novas para "Minhas palavras"), que não gasta uso.
    Detalhes: seção "💬 Conversa com IA — Fase 10" acima e `planejamento/FASE-10-CONVERSA-IA.md`.
  - **🏎️ Turismo (inglês, 🎮 Setas):** fala a palavra de cada portal quando ele vira o alvo; chip 🔊 no HUD também nas setas; os
    botões das setas cabem em 360 px. Modo digitação sem mudança. (Já commitado em `e804b90`.)
- **Padrões (plano §14):** 1 uso por fala dentro dos 30/dia, resumo grátis; nível = o maior até a fronteira (DEV = B2, mas quem
  terminou o C1 continua C1), com escolha manual guardada no aparelho; tradução ligada em A1/A2; voz automática ligada; ideias sempre
  em A1/A2 e atrás de "💡" do B1 para cima; `gemini-flash-latest` (trocável em `config/tutor.modeloConversa`), JSON com esquema só na
  web, "JSON no prompt" no nativo; 25 s por turno, no máximo 2 requisições, sem retry de 5xx/429; janela de descanso **única**
  (`DescansoIa`) para toda a IA (429 → 20 s…5 min; 429 diário → próxima 08:00 UTC; 503 → 8 s; credencial → 60 s); 3 s entre falas em
  produção; dados pessoais mascarados; nada salvo no Firestore, sem mudança de regras.
- **Correções da revisão (rodada de fixes, já na seção da Fase 10):** leitura da chave que falha = sem rede (não "sem chave");
  `perguntarComo` com corpo ilegível = `outro`; JSON com quebra de linha crua, cerca ```` ```json ```` cortada, contrações ("dont" =
  "don't") e marcadores traduzidos (`[number]`) tratados; exemplo da palavra só quando ela aparece na fala; marcadores forjados fora do
  histórico; mic aberto + Terminar / `fim:true` sem `setState` travado; aviso do limite diário lembra que o resumo funciona; relógio de
  1 s só no aviso com contagem; "Nenhuma palavra marcada" / "✓ Já estão nas suas palavras" no lugar de "Adicionar 0"; salvar um
  cartão repetido não espera mais 5 s.
- **Validação do líder (21/out):**
  - Suíte inteira: **2.366 testes, 2.361 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`); 151 arquivos de teste.
    `flutter analyze lib test`: sem avisos. Nenhum `test/_*_test.dart` sobrando.
  - **1 build** do probe (`flutter build web -t lib/main_portfolio_probe.dart --release --output=build/probe --no-wasm-dry-run`,
    ~29 s), servido em `python3 -m http.server`, **apagado depois** (`find build/probe -delete`). `build/web` não foi tocado; nada
    publicado.
  - **Chrome (Playwright), 1027 e 390 px, 0 erros de console e 0 `pageerror`** (só o aviso de fontes Noto de sempre e o
    `RGBELoader` deprecado do three.js no Turismo). Espião em `speechSynthesis.speak` e `HTMLMediaElement.play` por `addInitScript`.
    - Conversa (nas duas larguras): Mapa → "💬 Conversa com IA" (subtítulo novo) → lista com a fila de nível "Automático (A1)", "Restam
      30 usos hoje" e "⬆ acima do seu nível" a partir do A2 → ☕ café com a Emma (rosto no topo, "com Emma · A1 · restam N usos") → a
      abertura **foi falada** (tts) → fala 1 digitada + **Enter** → "✅ Certinho!" e a Emma responde com tradução → 🎤 com
      `window.__dito = 'I want a coffee'` → o campo mostra "I want a coffee" + "Confira o texto e toque em Enviar." (não enviou sozinho)
      → Enviar → cartão "✏️ Prof. Dash · jeito mais natural: Can I have a coffee, please?" com tradução, porquê, 💡 e "Salvar como
      cartão" → 🌐 desliga a tradução (as bolhas viram "Ver tradução") → "Ouvir de novo" fala a última fala da Emma → ideia "No,
      thanks." preenche o campo → Enviar → a Emma encerra e **o resumo aparece na lista** ("Você falou 3 vezes em inglês · 2
      certinhas de primeira · 1 correção", "Este resumo não gastou nenhum uso") → "Salvar como cartão" vira "✓ Salvo" (cartão em
      "Meus cartões" no `localStorage`) → "Adicionar 1 às Minhas palavras" → SnackBar "1 palavra entrou em Minhas palavras", "size"
      com o exemplo "Sure! What size would you like?" e o botão vira "✓ Já estão nas suas palavras". Cota 30 → 27 em cada conversa
      (3 falas).
    - Turismo (inglês, 🎮 Setas, qualidade Leve): chip **🔊 Voz** no HUD (1027 e 390 px) → a 1ª palavra ("lot") **falada na largada**,
      depois do "1" da contagem → segurando ↑: "bye", "you", "good", "meet", "size", "see" — **uma por portal, ~3,3 s uma da outra**,
      cada uma quando o portal vira o alvo (ex.: "good" com o portal ainda a 52 m). A 390 px os botões ◀ ▶ FREIO GÁS cabem.
    - Capturas em `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/smoke_conversa/` (38 PNGs, temporárias).
  - ⚠️ **Receita da prova (armadilha nova):** com a acessibilidade ligada, clicar no `<input>` da árvore de semântica
    (`page.locator('input').click()`) e digitar na hora **perde as primeiras letras** (o motor ainda está trocando o elemento de
    edição: "A small latte" virou "all latte"). Clicar pela posição (`page.mouse.click(x, y)`) ou esperar ~400 ms antes de digitar
    resolve. Não é bug do app (uma pessoa não digita 7 letras em 60 ms depois do toque).
- **Adiado (plano §15):** voz por personagem na web; conversa livre e cenário por unidade; nota de pronúncia do mic; salvar conversas
  e "✓ feita"; cota dura no servidor e App Check; streaming; JSON com esquema no Android/iOS; mensagens próprias de 429 no "Por quê?"
  e na Escrita; janela do limite diário guardada no aparelho e **janela por modelo**; expressões em Minhas palavras. Turismo: repetir
  a palavra cortada pela pausa (hoje não repete; o Rali repete — 1 linha em `aoRetomar` se o dono quiser).
- **Falta conferir à mão (o dono):** (1) **Gemini de verdade** depois do deploy: uma cena do café em pac-dart.web.app — o JSON com
  esquema e `thinkingBudget: 0` são aceitos (ou o retry de compatibilidade entra; ver o console), latência < 4 s, e o chat do Prof.
  Dash ainda responde pergunta longa com código (90 s); (2) microfone de verdade (Chrome no desktop e no Android) escrevendo no campo,
  e a resposta que chega com o mic aberto não é falada; (3) celular de verdade com teclado aberto (campo e ideias visíveis); (4) voz
  com o ouvido: a Emma e as palavras do Turismo nas setas; (5) um 429 de verdade (contagem regressiva no aviso, ➤ volta sozinho);
  (6) Android/iOS: uma cena pelo "JSON no prompt" quando houver aparelho.

## 🙌 21/out/2026 (rodada 9): Claude na Conversa (desligado até publicar o Worker) + modo mãos-livres (FEITO e validado no probe; sem commit/deploy)

Plano: `planejamento/FASE-11-CLAUDE-MAOS-LIVRES.md` (com as divergências no topo). Worker: `workers/conversa-claude/` (**não publicado**).

- **💬 Conversa pelo Claude Haiku (Worker da Cloudflare) — DESLIGADO por padrão:**
  - Só os turnos em JSON da Conversa (`IaCubit.consultarJson`, que só o `CenarioCubit` usa) podem ir ao Claude. Prof. Dash, "Por
    quê?", Escrita, toque na palavra e Turismo continuam no Gemini.
  - Liga **sem deploy do app**: `config/tutor.provedorConversa = "claude"` + `urlConversa = "https://paclingo-conversa.<sub>.workers.dev"`
    (só `https://`; `http://` só localhost/127.0.0.1). O app relê a config a cada ~5 min (`ChaveGemini.campoRecente`). Para voltar
    ao Gemini: apagar `provedorConversa`. Passo a passo: `workers/conversa-claude/LEIA-ME.md` → "Ligar no app".
  - `lib/main.dart`: o serviço do `IaCubit` virou `TutorConversaRoteador(gemini: GeminiTutorService() | FirebaseAiTutorService(),
    formatoSemJson: formatoTurnoTexto)` quando `tutorBuilder == null` (testes e probe com `tutorBuilder` não mudam). O
    `IaPalavrasCubit` e o `TutorCubit` seguem no Gemini direto.
  - `lib/features/tutor/data/tutor_claude.dart` (`ClaudeTutorService` + `FalhaClaude`): `POST <url>/v1/turno` com o ID token do
    Firebase (novo a cada turno), `{system: persona, mensagens: [{papel: 'aluno', texto: montarPrompt(...)}], esquema, maxTokens}`;
    nunca loga, nunca põe o texto do aluno no erro. `lib/features/tutor/data/tutor_roteador.dart` (`TutorConversaRoteador`): decide
    cada turno e faz o fallback.
  - **Fallback:** `sem_chave`, `nao_autenticado`, `origem_negada`, 404/`nao_encontrado` ou rede/DNS/CORS → aquele turno vai ao
    Gemini e o Claude fica de lado **10 min**; `pedido_invalido` → só aquele turno no Gemini; `limite_pessoal` → **não** cai: vira
    `TipoFalhaIa.limitePessoal` (aviso próprio "Você usou suas falas de conversa de hoje", SEM a janela de descanso compartilhada —
    "Por quê?"/Escrita/palavra seguem no Gemini) e o Worker não é chamado até o `Retry-After`; `limite_geral` com `Retry-After`
    > 2 min (o teto do dia) → Gemini e o Claude de lado até o `Retry-After`; curto/sem (429 da Anthropic) → `limite` ("Muita gente
    conversando", backoff 20 s…5 min); `ia_falhou`/`ia_demorou` (e o tempo esgotado do app, 35 s) → `ocupado` (a fala volta ao
    campo, sem gastar uso); **3 panes seguidas** (`ia_falhou` menos a recusa, `ia_demorou`, `http_5xx`) → Gemini e o Claude de
    lado 10 min. A config é relida do banco a cada 5 min (um cache só, o do roteador).
  - A cota do app (30/dia, toda a IA) continua valendo também no Claude; o Worker tem a dele (60/aluno/dia) e o teto geral (450/dia
    no `wrangler.toml`).
- **🙌 Modo mãos-livres na Conversa** (preferência do aparelho `conversa_maos_livres`, padrão desligado; ⋮ → "🙌 Mãos-livres"):
  - Segurar o 🎤 grava, soltar envia sozinho (vazio → "Não ouvi nada — tente de novo"); um toque curto abre a vez. Depois que o
    personagem termina de falar (fim real da voz: `Future` do `VozIngles.falar`), o 🎤 abre sozinho ("Sua vez… fale em inglês", com
    ⏹); envia depois de 1,5 s de silêncio; nada em 8 s → "Toque no 🎤 para falar". Nunca abre com a voz soando; fecha ao sair,
    pausar, abrir o resumo, na janela de descanso, no fim da conversa e com diálogo/menu por cima.
  - Faixa com o chip "🙌 Mãos-livres" (só 🙌 no celular), o que o mic ouve, "Emma está falando…", recados e ideias. A correção do
    Prof. Dash ganha "🔊 Ouvir o jeito certo". Sem reconhecimento de voz (ou mic bloqueado): item desabilitado com o motivo.
  - Fora do mãos-livres nada muda (o 🎤 escreve no campo, o aluno confere e envia).
  - Código: `lib/features/ia/presentation/maos_livres.dart` (`ControladorMaosLivres`, máquina de estados testável) + `conversa_page.dart`,
    `widgets/microfone_conversa.dart` (`maosLivres`: botão de segurar), `preferencias_conversa.dart`, `widgets/bolha_conversa.dart`.
- **Probe (`lib/main_portfolio_probe.dart`):** o `_ReconhecedorFake` entrega UMA vez por escuta — sozinho depois de
  `window.__ditoMs` (padrão 500 ms, igual a antes) ou ~50 ms depois de `parar()`. ⚠️ **Receita da prova:** para SEGURAR o 🎤 no
  mãos-livres, `window.__ditoMs = 60000` antes do `mouse.down()` (com 500 ms a escuta fecharia sozinha, o app reabriria e o texto
  somaria duas vezes); para a vez que abre sozinha, `__ditoMs = 500`. Chaves úteis: `alternar-maos-livres`, `chip-maos-livres`,
  `faixa-maos-livres`, `ouvindo-maos-livres`, `parar-maos-livres`, `personagem-falando`, `recado-maos-livres`, `ideias-maos-livres`,
  `motivo-maos-livres`, `microfone-conversa`. O probe usa `tutorBuilder` (tutor falso), então não passa pelo roteador.
- **Testes novos:** `test/tutor_claude_test.dart`, `test/tutor_roteador_test.dart` (http/relógio/token falsos: cada código do Worker,
  fallback e memória de 10 min, config desligada de 5 jeitos, cache de 5 min, nativo com o formato no prompt, nunca loga, roteador
  com o `IaCubit` de verdade, `campoRecente`), `test/ia_maos_livres_test.dart` (39, máquina de estados com timers falsos),
  `test/ia_maos_livres_ui_test.dart` (22, 360×640 e 1027×768, claro/escuro, teclado, clique direito, descanso). Prévias PNG (20) em
  `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/previas_maoslivres/` (temporárias).
- **Correções da revisão (depois dos grupos):** mãos-livres — pausa no meio da frase na vez aberta sozinha reabre o mic e soma
  ("I would like" + "a coffee" = uma fala); toque curto com a vez aberta não fecha com "Não ouvi nada"; o limite de reaberturas
  segurando só conta escutas vazias seguidas (e, se não der para reabrir, envia o que ouviu); voz que nunca termina tem teto
  (duração estimada × 2 + 5 s, senão 30 s) e a vez abre assim mesmo; o 🎤 chega pelo Tab e Espaço/Enter seguram; clique direito
  não grava; com a conversa ocupada/acabada/em descanso o 🎤 fica cinza com o motivo ("Espere a resposta", "Espere a IA liberar",
  "A conversa acabou") e a fala que não puder ir vai para o campo com "Sua fala ficou no campo". Claude — tempo esgotado do app
  (35 s) vira `ia_demorou` (não `rede`), as 3 panes seguidas, o `limite_geral` do dia → Gemini e o `limite_pessoal` com tipo e
  aviso próprios (ver o Fallback acima).
- **Validação do líder (21/out, rodada 9):**
  - Suíte inteira: **2.489 testes, 2.484 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`); 155 arquivos de teste.
    `flutter analyze lib test`: sem avisos. Nenhum `test/_*_test.dart` sobrando.
  - **1 build** do probe (`flutter build web -t lib/main_portfolio_probe.dart --release --output=build/probe --no-wasm-dry-run`,
    ~29 s), servido em `python3 -m http.server`, **apagado depois** (`find build/probe -delete`). `build/web` não foi tocado; nada
    publicado.
  - **Chrome (Playwright), 1027 e 390 px, 0 erros de console e 0 `pageerror`** (só o aviso de fontes Noto de sempre). Espião em
    `speechSynthesis.speak`/`HTMLMediaElement.play`. Nas duas larguras: Mapa → 💬 Conversa com IA → ☕ café com a Emma → ⋮ →
    "🙌 Mãos-livres" (com o subtítulo "Segure o 🎤 e solte para enviar; ele abre sozinho na sua vez", habilitado — o probe tem
    reconhecedor) → chip "🙌 Mãos-livres" (só 🙌 em 390) e `flutter.conversa_maos_livres = true` no `localStorage` → com
    `__dito = 'I want a coffee'` e `__ditoMs = 60000`, `mouse.down()` no 🎤 → "🎙️ Ouvindo… solte para enviar" (🎤 vermelho) →
    `mouse.up()` → **enviou sozinho** ("Enviado — Emma já responde", "Emma está digitando…") → cartão "✏️ Prof. Dash · jeito mais
    natural: Can I have a coffee, please?" com **"🔊 Ouvir o jeito certo"** → a resposta "Sure! What size would you like?" **foi
    falada** → **o 🎤 reabriu sozinho** ("🎙️ Sua vez… fale em inglês" + ideias + ⏹; "restam 29 usos") → "Ouvir o jeito certo"
    fala "Can I have a coffee, please?" (a faixa mostra "Emma está falando… depois é a sua vez") e o 🎤 reabre de novo depois →
    ⏹ → "Toque no 🎤 para falar" → ⋮ → "Desligar o mãos-livres" (`localStorage` = false) → o 🎤 de antes: `__dito = 'A small
    latte, please.'` **preencheu o campo** com "Confira o texto e toque em Enviar." e **não enviou**; o 🔊 da correção volta a ser
    só o ícone.
  - Capturas em `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/smoke_maoslivres/` (22 PNGs, temporárias).
  - Detalhes vistos (não bloqueiam): no "Ouvir o jeito certo" a faixa diz "Emma está falando…" (é a frase do Prof. Dash, na
    mesma voz); em 390 px com o chip 🙌 a fila de ideias corta a 2ª ideia na borda direita (a fila rola de lado).
- **Adiado:** a mensagem exata do Worker no `limite_pessoal` (hoje texto fixo do app, o `ResultadoIa` só leva o tipo); a checagem
  dos 64 KB do corpo no app (o Worker responde `pedido_invalido` e o turno cai no Gemini); `http_500` HTML da Cloudflare sem
  fallback (só conta como pane); voz própria para o Prof. Dash no "Ouvir o jeito certo".
- **Falta conferir à mão (o dono):** (1) ⚠️ **Chrome de verdade com microfone:** o `SpeechRecognition.start()` sem toque novo (a vez
  que abre sozinha depois da fala, a reabertura com o dedo no 🎤 e a reabertura na pausa do meio da frase) — o reconhecedor falso
  do probe não mostra a regra de gesto do Chrome; se o Chrome recusar, o controlador volta a "ocioso" com o recado, nada quebra.
  Também: o eco (a voz da Emma não pode virar fala do aluno) e o celular Android segurando o 🎤. (2) Publicar o Worker (LEIA-ME,
  passos a–g), ligar no `config/tutor` e conferir um `POST …/v1/turno` 200 na aba Network; depois desligar e ver a volta ao
  Gemini em ~5 min. (3) Android/iOS: uma cena com o Claude ligado (sem `Origin`, o Worker aceita) e o fallback no Firebase AI.
- **Decidido na revisão:** o `limite_pessoal` ganhou mensagem própria (`TipoFalhaIa.limitePessoal`) e o `limite_geral` do dia cai
  para o Gemini (ver o Fallback acima).

## 🏎️📖 21/out/2026 (rodada 10): English Turismo com 30 pistas + história em desenho animado "The Golden Wheel" (FEITO e integrado; falta a revisão e a prova visual; sem commit/deploy)

- **Só no inglês.** O campeonato do Turismo do inglês tem **30 pistas**: as 10 de sempre e mais 20 novas (11–30, temas 7..26, cada uma com seu mundo no 3D e no 2D de reserva; a 17 e a 27 são sprints). **Dart e C# não mudam**: as mesmas 10 pistas (`pistasGt`), o mesmo RNG e os mesmos troféus.
  - Domínio: `pistasGtExtrasIngles`, `pistasGtIngles` e `pistasTurismo(ingles:)` em `turismo.dart`. O campo `PistaGt.retas` tem default `.12`.
  - Progresso: nada é regravado. `ProgressoTurismo.carregar(totalPistas: 30)` calcula o desbloqueio (um tempo ou uma medalha na pista n, de 10 a 29, libera a n+1).
  - Troféus: `campeao` e `dourado` contam só as pistas 1–10. O inglês ganha mais 3: 🌍 `volta-mundo` (11–20), 🏆 `lenda` (as 30) e 📖 `historia` (o final do capítulo 30 **assistido**, chave `c30`).
  - 3D: o módulo agora é `turismo3d.js?v=30` (`VERSAO = 30`). Se o módulo em cache for mais velho, o Dart manda o mundo base (`temaBase`).
- **História "The Golden Wheel / A Roda de Ouro":** 30 capítulos, um por pista, cada um com abertura antes da corrida e chegada depois.
  - O nível sobe de A1 a B2.
  - Os dados estão em `assets/ingles/turismo_historia_{a,b,c}.json` (≈220 KB, já cobertos pela linha `assets/ingles/` do pubspec).
  - O desenho é feito em Flutter (`lib/features/arcade/presentation/historia/`): 25 cenários com paleta por hora do dia, atores de corpo inteiro com lip-sync e 11 expressões, clima, efeitos, props, balão em inglês com o PT que dá para esconder e voz com tom diferente por personagem (`PerfilVoz`).
  - Controles: pular, galeria "📖 História", resumo até aqui e créditos "THE END".
  - Elenco: os 8 personagens do curso, `voce`, o narrador e **2 extras só do jogo, Max (rival) e Kim (locutora)**. Eles foram registrados no DESIGN §5.5.
  - Só carrega com opt-in: o hub passa `carregarHistoria: true`, e no Dart e no C# nada é lido.
- **Validação da integração (21/out):**
  - `flutter analyze lib test`: sem avisos.
  - Suíte inteira: **2.733 testes, 2.728 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`).
  - Suíte de foco do plano: 392 testes, todos verdes.
  - `validar_historia.py` nos 3 JSON: sem erros. Sobram 2 avisos de `pt_f`, ambos falsos positivos, porque o "sozinho" se refere ao Max.
  - Novo `test/turismo_historia_conteudo_test.dart` (parse estrito dos 3 arquivos):
    - `validar()` vazio;
    - 30 capítulos, níveis da tabela 5.2 e regra V-mundo;
    - os capítulos 1 e 30 tocados de ponta a ponta no player, com os créditos.
  - Uma varredura temporária tocou os 30 capítulos (abertura e chegada) em 1280×720, 360×640 e 2560×1080, e também com animações reduzidas e texto 1.3×, sem exceção nem overflow.
- **Pendente:**
  1. Revisão de código e do inglês.
  2. **Prova visual (plano 8.3):** UM build do probe (`/turismo-en`, `/turismo-en11..30`, `/historia-en`, `/historia-en1`, `/historia-en30`) e o smoke com Playwright. As cores dos 20 mundos só foram conferidas em código e no harness Node, sem WebGL.
  3. Voz mp3 por personagem (Chirp) para a história, incluindo `max`, `kim` e `narrador` no `vozes_google.py` (D15). Rodar o script sem a história **apaga** mp3 órfãos.
  4. Pré-carregar o 3D durante a cena de abertura (crítica b8).
  5. O cabeçalho da corrida (`CabecalhoJogo`, `arcade_ui.dart:148`) estoura 39 px em ~800 px no modo digitação do inglês. Isso já acontecia antes desta rodada.
  6. O arco-íris que aparece no meio de uma cena (cap. 14) surge sem o fade de 1 s, porque o clima usa o relógio global.
- **Ajustes da integração entre grupos:**
  - O palco soma a tremida do relâmpago (`EfeitoHistoriaLayer.tremor`, zero com reduzir) à câmera.
  - O arremesso não desenha mais um 2º estalo, porque o projétil já faz o respingo.
  - No nativo, `vista_3d_stub.dart` passa `reduzir` quando o tremor está desligado ou o sistema pede menos animação, como já acontece na web.

## 🏁 21/out/2026 (rodada 14): English Turismo com 30 pistas + história em desenho animado 'The Golden Wheel' (FEITO, revisado e com prova visual no probe; sem commit/deploy)

Fecha a rodada 10 acima (que ficou "falta a revisão e a prova visual"). O que vale agora:

- **O que existe (só no inglês):**
  - Campeonato de **30 pistas** em 3 temporadas (Word Grand Tour 1–10, World Tour 11–20, Legends 21–30), com cabeçalho e 🏅 por temporada; ao abrir, a lista rola até a pista mais longe liberada. `MEDALHAS x/30`, `TROFÉUS x/15` (12 de sempre + 🌍 Volta ao mundo, 🏆 Lenda do English Turismo, 📖 História completa).
  - 20 mundos 3D novos (temas 7–26) + fallback 2D com clima; módulo `turismo3d.js?v=30` com handshake de versão.
  - História **"The Golden Wheel / A Roda de Ouro"**: 30 capítulos (A1→B2), abertura antes da corrida e chegada depois; desenho em Flutter (palco, atores de corpo inteiro, lip-sync, 11 expressões, balão EN com PT, voz com tom por personagem), galeria "📖 História", "Resumo até aqui", aviso de capítulos perdidos e créditos "THE END" no fim do 30.
  - Dart e C# continuam com 10 pistas, mesmo RNG e os 12 troféus.
- **Padrões (defaults):** cenas automáticas ligadas (`📖 Auto`), PT visível, voz ligada, 🐢 voz lenta desligada; vistas gravadas em `en_turismo_historia_vistos` (`iN`/`fN`/`cN`). A abertura toca uma vez por pista (o 2º "Correr" vai direto para a largada); a chegada abre 1,2 s depois do fim, só depois de moedas/estatísticas/campeonato gravados, e o ranking (rede) não segura mais nada. Na web sem som liberado aparece "▶ Assistir".
- **Correções da revisão (rodada de review → fix):** chegada não abre por cima de outra tela nem espera o ranking; Voltar do sistema grava a vista antes de o chamador reler; fala sem texto não trava; quem "sai" fala antes de sair; balão medido e centrado na boca (rabicho certo) e PT que não corta no celular; contraste do chip de nome; rolagem até a pista mais longe; aviso de perdidos com a lista real; água do 3D que não dobra nem invade outro trecho; muros do cânion sem "pop-in"; 6 ajustes de texto da história (H1–H6).
- **Correção da verificação final:** as muretas de concreto da pista 30 (tema 26) usavam o modelo do Poly Haven com **~61 mil triângulos cada**; com passo de 12 m nos dois lados a pista desenhava **6,5–10 milhões de triângulos por quadro** (as outras ficam em ~0,35–0,97 mi). Agora são um perfil "New Jersey" extrudado (28 triângulos, `construirMuretas` em `turismo3d.js`), sem baixar o glTF: a pista 30 caiu para **~0,52 mi** e continua com as muretas visíveis. O modelo `concrete_road_barrier` ficou em `web/assets3d/modelos/` sem uso.
- **Validação (21/out):**
  - `flutter analyze lib test`: sem avisos.
  - Suíte inteira: **2.751 testes, 2.746 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`). Nenhum `test/_*` sobrando.
  - JS: `node --check`, checador de `TEMAS` (26 temas, neblina ≤ .005, `VERSAO 30`, `?v=30`, assets) e o harness Node dos 26 temas (alta e mínima+reduzir) — tudo OK depois da troca das muretas.
  - **Prova visual com UM build do probe** (`lib/main_arcade_probe.dart`, `build/probe`, apagado no fim) + Playwright com voz fake:
    - 1280×720 `/#/turismo-en`: MEDALHAS 0/30, cabeçalhos de temporada, pistas 11 e 12 com "Correr" (`turismo_pista_max=12`), 13–30 trancadas, botão 📖 História, troféus 0/15.
    - "Correr" na pista 1 → player: quadros em +0,5/+2/+4 s diferentes; 1ª fala "Your first trip to Chicago." (narrador, tom .95) e tons 1 / .88 / 1.1 / .8 nas seguintes; `t` esconde o PT (e grava); Espaço completa e depois avança; Esc → contagem e corrida 3D (tema 1); 2º "Correr" na pista 1 **não** reabre a cena.
    - `/#/historia-en`: 30 capítulos, 30 "▶ Abertura" e 30 "▶ Chegada". `/#/historia-en30`: "▶ Assistir" → 16 falas → THE END com elenco e créditos; grava `f30` e `c30`.
    - 390×844, 360×640 e 2560×1080: campeonato e `historia-en1` sem overflow, balão no topo (celular) e acima do falante (largo) com o rabicho na boca.
    - 20 mundos (página nova por pista, `/?m=N#/turismo-enN`): `temaId == N-4` e `versao == 30` em todos, 3–4 s de corrida digitando, 20 screenshots distintos.
    - 0 erros de página/console (só os avisos de fontes Noto e "RGBELoader deprecated").
- **Diferido / pendente:**
  1. Voz mp3 por personagem (D15) para a história (incluir `max`, `kim`, `narrador` no `vozes_google.py`; rodar sem a história **apaga** mp3 órfãos).
  2. Pré-carregar o 3D durante a abertura (crítica b8).
  3. Palavras da história como `foco` do baralho (b4) e 🐢 automática por nível (b5).
  4. `pt_f` (frases no feminino) validado mas ainda não exibido.
  5. Arco-íris do cap. 14 surge sem o fade de 1 s (clima no relógio global).
  6. `CabecalhoJogo` estoura 39 px em ~800 px no modo digitação (já existia).
- **Achados visuais para a próxima rodada (não corrigidos, precisariam de outro build para conferir):**
  - Celular em pé (390×844/360×640): os atores ficam pequenos (~110 px) no terço de baixo, com muito céu vazio em cima; dá para subir a altura dos atores ou o enquadramento no retrato.
  - Créditos: cada linha do elenco é centrada sozinha, então os rostinhos ficam em zigue-zague; alinhar a lista numa coluna de largura fixa.
  - O troféu `campeao` ainda se chama "Campeão Dart Turismo" no inglês (texto antigo de `trofeusGt`, ao lado de "Lenda do English Turismo").
  - 3D: no ângulo de perseguição o céu aparece pouco e fica atrás dos portais, então aurora (25) e estrelas quase não aparecem; a Cratera Lunar (27) usa um céu acinzentado com relevo, menos "espaço" do que a Estação Orbital; a Tempestade de Areia (18) quase não mostra partículas na qualidade Leve; a água da Ponte sobre o Mar (16) mostra o padrão repetido da textura.
- **Conferir à mão (aparelho/navegador de verdade):** voz real do sistema (tons por personagem soam diferentes?), celular nativo (fallback 2D com clima, `reduzir`), máquina fraca nas pistas 21–30 (qualidade Mínima), a cena de chegada por cima da vista 3D e o troféu 📖 depois de assistir ao final do 30.

## 📺 22/out/2026 (rodada 16): Escutar assistindo no 🎧 Ouvir — desenho que acompanha a playlist (automático nas 602 lições + histórias escritas nas trilhas 1–2)

Estado: integrado, revisado, testado e com a prova visual feita no probe. **Sem commit e sem deploy** (o lead faz). Falta só a prova em aparelho de verdade.

- **Plano:** `plano_historias_licoes.md` (scratchpad da sessão; o que sobrevive está em `tools/ingles/historias/RECEITA.md`). Pedido do dono: o 📺 fica **na playlist**, não na lição.
- **O que a pessoa vê:** no "Tocando agora", o botão **📺 Assistir / 🖼️ Foto** (`ouvir-assistir`, começa desligado e é lembrado em `en_ouvir_assistir`) troca a foto por um **palco de desenho animado** que segue o Ouvir: quem diz a frase fala com a boca sincronizada (mp3 + bocas de sempre), balão EN (+PT pelo chip Tradução, "…" no português→inglês), gestos e passos mudos nos silêncios, ⛶ tela cheia com barra compacta. Portas: 📺 em cada setlist (cartão e `SetlistPage`), cartão "📺 Escutar assistindo" do curso (Continuar / Da minha lição atual).
- **Mestre = `OuvirCubit` (intocado).** O palco (`PalcoAssistir` + `RoteiroSeguidor` + `CompassoAssistir` + `MemoriaAssistir`) só segue o estado; nunca fala. O Turismo usa o mesmo `PalcoHistoria` via `RoteiroVisivel` com saída idêntica.
- **As 602 lições têm desenho:** `EncenadorLicao` (automático, puro) + a tabela `assets/ingles/historias/encenacao_auto.json` (as 602, revisadas: cenário, hora, remotos, entradas, mudos). **Autorais (✨ história especial):** `primeiro-contato` e `numeros-horas-soletrar` (12 lições) em `assets/ingles/historias/<trilha>.json` + `indice.json`. Lotes novos = só JSON, pela receita `tools/ingles/historias/RECEITA.md` (validador Python com paridade provada contra o Dart: `python3 -I tools/ingles/historias/validar_historias_licoes.py --auto-teste`; depois `flutter test test/ingles_historias_licoes_conteudo_test.dart`).
- **Arte nova:** cenários `videochamada` (app de chamada sem marca + molduras de webcam com o ator recortado na cintura), `escritorio`, `casa`, `restaurante`, `loja`; props `notebook`, `prato`, `sacola`, `documento`; 39 figurantes com aparência fixa (gênero = o da voz gerada).
- **Ajustes da integração (depois de olhar os PNGs):** o balão do 📺 nunca corta o texto num palco baixo (`PalcoHistoria.balaoSemCorte`, só o 📺 liga); o palco no celular em pé ficou mais alto (`w × .78`, 220–380 px); props do emoji só onde cabem (nada de prato no consultório nem mala no lago); o selo vira só "✨" em faixa estreita; as molduras apagadas usam as iniciais do próprio painter e acendem a borda verde de quem fala.
- **Testes novos:** `historia_licao_modelo`, `historias_licoes_repo`, `assistir_memoria`, `historias_licoes_paridade` (39 fixtures em `tools/ingles/historias/fixtures/`), `historia_cenarios_licao`, `historia_figurantes`, `assistir_compasso`, `assistir_seguidor`, `assistir_palco_ui`, `assistir_encenador`, `assistir_historias_licoes`, `ingles_assistir_tocando`, `ingles_historias_licoes_conteudo`. Teste antigo editado: só a contagem fixa de `historia_fundo_test` (cenário/hora; o nome "os 25 cenários…" ficou desatualizado).
- **Validação (22/out, integração):** `flutter analyze lib test` sem avisos; suíte inteira **3.067 testes, 3.062 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`; base da Phase 0 era 2.757 + 5); `--auto-teste` do Python 59/59; nenhum `test/_*`. PNGs de 10 automáticas (uma por cenário) + 1 com figurante + 3 do piloto, em 720×405 e 358×279, olhados e corrigidos (ver os ajustes acima).
- **Padrões:** o 📺 começa **desligado** (pref `en_ouvir_assistir`; o selo "novo" some no 1º uso); frase sem lição do curso (texto próprio numa setlist) mostra a foto + "Sem desenho para esta frase…"; lição sem história escrita usa a automática (com a tabela); a escrita só entra na troca de faixa (nunca no meio de uma frase); "reduzir movimento" anda em passos de 100 ms; o palco só anda tocando e com o app visível.
- **Correções do review (rodada 16):**
  - Interface: palco limitado pela altura visível (celular deitado: o ⛶ fica na tela); ⛶ no celular deitado com barra de 1 linha e faixa do balão no topo; 2 filas no retrato com o balão logo acima da moldura de quem fala e a borda verde acesa a fala inteira; molduras de 1 fila dividem a largura por igual; alvos de toque ≥ 24×40 (bolinhas viram "k/N ◀ ▶" quando não cabem); o toque no desenho não vira botão sem nome; uma só saída no ⛶.
  - Encenação: props do emoji só onde cabem (nada de 🍽️/💧 virando prop, chave/mapa/microfone/presente por cenário, prop negado com 🚫/"No…"); ninguém senta por 🪑; ~45 rostos novos → emoção; "No problem/No worries" = concorda, "No way" = surpreso; 👋 só em cumprimento/despedida; sem alvo para quem está no telefone; 6 lições corrigidas na tabela (T1–T7).
  - Prova visual (esta rodada): na `videochamada` o zoom da câmera (`medio`/`close`/`dupla`) **nunca corta uma moldura na borda** (o app de chamada não dá zoom; teste novo em `assistir_palco_ui_test`, falha sem a correção); o 🎬 saiu do título da faixa do palco quando a lição tem emoji (a claquete escura sumia na faixa preta e parecia um glifo quebrado).
- **Validação final (22/out, rodada 16):**
  - `flutter analyze lib test`: sem avisos. Suíte inteira: **3.087 testes, 3.082 passam, 5 falham** (as 5 de sempre do `csharp_curriculo_test`); depois disso entrou 1 teste novo (o do zoom na chamada), e o foco do §11.2 rodado depois das últimas correções deu 705/705. Nenhum `test/_*`.
  - Python: `validar_historias_licoes.py --auto-teste` 59/59; `--pasta assets/ingles/historias` 0 erros e 1 aviso de propósito (a Sarah entra antes da 2ª frase de `prazer-ate-amanha`).
  - Pixels do Turismo: idênticos ao HEAD (harness de 1.552 quadros do review).
  - **Prova visual (UM build do probe, `/?licao=…&modo=so|ep|pe&setlist=1#/assistir-en`, porta 8788, apagado depois):** 1º áudio = mp3 de "Good morning, Mike!"; 4 mp3 distintos em 10 s; screenshots em +1/+3/+6/+10 s com hashes diferentes; ⏸ véu e volta com Space; → próxima frase; chip Tradução tira o PT do balão; `modo=pe` mostra "…" + PT + 🤔; R 3× na 1ª frase sem tela escura e com as letras recomeçando; `setlist=1` abre a setlist "Probe" já assistindo, com "✨ história especial"; automáticas de escritório, casa, restaurante (atendente), loja (atendente) e aeroporto; ⛶ em 1280×720 e 844×390; 390×844, 360×640 e 2560×1080 sem estouro; Turismo `/historia-en1` sem mudança. Console: **0 erros** (só o aviso das fontes Noto).
- **Polimento (22/out, depois do review; sem commit/deploy):**
  - Desempenho: o `RoteiroSeguidor` só avisa quando algo visível muda (véu do corte, passo novo, letra nova, passo ainda animando ≈ max(`duracaoMuda`, 2,6 s) + .4 s); o palco escuta `seguidor` + um relógio de 1/30 s (`_quadro`; 100 ms no "reduzir movimento"); parado, o palco redesenha a ≤ 30 fps em vez de todo quadro.
  - Vão e timer: o plano do vão compara o timer com o **fim** do vão; mudar o "Desligar em" no vão tira a abertura da próxima lição; pausa que chega com a próxima já aberta volta o palco para o fim da faixa atual. O véu do corte é limpo em pausado/parado/fim.
  - Config da faixa: `OuvirCubit.configDaFaixa` (gravada em `_tocarFaixa`) → o seguidor usa a config **daquela faixa** no tamanho do vão, `ehVaoFinal` e `_fatorFala` (as flags de texto seguem a config atual).
  - Carga travada: `HistoriasLicoesRepo.emVooTravado` (pedido pendente além do timeout cai e o próximo tenta de novo, sem Timer); `trilha()` com `.timeout` no índice; `HistoriasLicoes.carregando()` desiste depois do timeout.
  - Fundos: a `casa` é **um cômodo só** em qualquer largura (cozinha à esquerda, mesa com pendente, janela + sofá + planta + porta no largo, estante + escrivaninha à direita; antes o palco do celular mostrava 2 cozinhas); a `loja` tem **uma** entrada (porta de vidro, placa "$5", caixa e cestas) no módulo do meio, os outros com gôndola e banca de frutas.
  - Balão no celular (fora da chamada): palco da página em pé mais alto (`w × .95`, 240–380 px); com `balaoSemCorte`, os atores encolhem (até 56 px) para a cabeça ficar abaixo da faixa de um balão típico (`8 + 94·escala·texto`, no máximo ½ palco) e o zoom não as sobe para dentro dela; num palco largo e baixo, o balão vai para o **lado** de quem fala, no vão até a próxima cabeça. O Turismo não muda.
  - `/assistir-en` do probe mostra o modo pelo `rotuloModo` ("Só inglês"…).
  - Teste corrigido: `historias_licoes_repo_test` "os assets do projeto existem…" esperava só as 2 trilhas do piloto no `indice.json`; agora confere o piloto + versão ≥ 1 + arquivo de cada trilha listada (o A1 inteiro entrou em `8601a04`/`593cc03`).
  - **Validação:** `flutter analyze lib test` sem avisos; suíte inteira **3.122 testes, 3.116 passam, 6 falham**: as 5 de sempre do `csharp_curriculo_test` + o teste do índice acima, já corrigido (16/16 no arquivo). Nenhum `test/_*`. UM build do probe (porta 8788, apagado depois): `primeiro-contato.oi-tudo-bem` em 1280×720, 390×844, 360×640 e 844×390; automática de casa `contar-historia.primeiro-depois-por-fim` em 1280×720, 2560×1080 e 844×390 (balão ao lado, sem cobrir cabeça). Console: **0 erros** (só o aviso das fontes Noto). PNGs em `smoke_polimento/` do scratchpad.
- **Balão da chamada e relógio fora da tela (22/out, depois do polimento; sem commit/deploy):**
  - **Videochamada numa fila, na página (fora do ⛶):** `PalcoHistoria.ptNaPagina` (o 📺 liga com `!grande`; o Turismo e o ⛶ não mudam). Se o balão no topo cobriria uma cabeça (no palco estreito < 560 px: uma moldura), ele **perde o PT** (a página já mostra o PT logo abaixo do palco); se ainda cobrir, vira o **`BalaoFala.compacto`** (chip do nome ao lado do inglês, 15 px, rabicho curto, sem PT; o inglês ainda quebra linha) e, com texto ampliado, encolhe a letra até o normal. Molduras **sem mudança** (o compacto de até 2 linhas cabe na faixa de 61 px). PNGs com a Roboto de verdade (`balao_chamada/antes|depois/` do scratchpad): 844×390 (palco 640×170) agora com o balão de 1 linha acima de todas as cabeças (antes: EN + PT ≈ 107 px cobrindo 2–4 cabeças); 360×640 com frase longa perde o PT e não toca mais as molduras; 390×844, 1280×720, o ⛶ 844×390 e o escritório (fora da chamada) **idênticos byte a byte** ao antes.
  - **Relógio fora da tela:** o `PalcoAssistir` escuta a `ScrollPosition` do `Scrollable` em volta (a página do "Tocando agora"); depois do quadro confere se a caixa do palco ainda cruza a área visível e, rolado para fora, **para o Ticker** (volta ao aparecer; no ⛶ não há `Scrollable`). Mesma semântica do app oculto: o seguidor só congela a animação, os estados do cubit continuam chegando.
  - **Testes novos (`assistir_palco_ui_test`, 2):** chamada 640×210 na página (3 falas: sem PT, balão < 60 px, nenhuma cabeça coberta) × ⛶ 844×390 e 1280×720 (PT fica); rolar para fora para o relógio e nenhum quadro fica agendado, voltar faz andar. 3 mutações pegas (`ptNaPagina: false`, sem o passo compacto, sem `_foraDaTela` no `_sincronizar`). `flutter analyze lib test` sem avisos; os 8 arquivos do foco 175/175 + `historia_cenarios_licao`/`historia_figurantes` 41/41.
- **Limites conhecidos (não corrigidos):**
  - Na chamada de uma fila na página, uma frase que precise de 3+ linhas no balão compacto (≈ 150+ letras no 640 px) ainda encosta nas cabeças (as molduras não encolhem por frase, para não pular de tamanho a cada fala).
  - Em 1280×720 (página, chamada) o balão com PT ainda cobre a borda de cima das molduras, não as cabeças (mantido de propósito).
  - A conferência de visibilidade só roda na rolagem (e ao montar/trocar de layout): uma mudança de layout sem rolagem que empurre o palco para fora não para o relógio até a próxima rolagem.
  - Em 2560×1080 o palco fica no máximo de 720 px de largura (pequeno na tela larga; por desenho do §7.1).
  - Variantes de gênero com ZWJ (🙋‍♂️, 🙅‍♀️) ainda não viram gesto.
  - No avental/boné dos figurantes: `Aparencia` não tem esses campos (atendente e garçom usam crachá; motorista usa gorro).
- **Conferir à mão (aparelho de verdade):** o 📺 num celular em pé e deitado (balão compacto da chamada, ver acima), a voz e o lip-sync com mp3 de verdade (e as 410 frases do Tatoeba, D19), minimizar → mini-player → reabrir no meio do vão (só provado em widget test: o probe não tem mini-player), o timer "Desligar em", leitor de tela no botão 📺 e nas bolinhas, e uma máquina fraca com o palco + Ouvir.
- **Pendente:** commit + deploy (lead). **Decisões do dono:** D19 (410 frases com gravação do Tatoeba trocam a voz do personagem no desenho; no piloto, 9), começar ligado ou não, esmaecer o `ouvir-en` com o palco, recepcionista e Mike parecidos de longe (ambos de azul com crachá).

## 📺 22/out/2026 (rodada 17): 📺 na lição — "Assistir a historinha" (FEITO; sem deploy)

- **Onde:** link "📺 Assistir a historinha" no começo da lição (`licao-assistir`, abaixo do "🎬 rever o ensaio mental", `palco_ingles.dart`), botão na vitória (`vitoria-assistir`) e opção `sheet-assistir` na folha da lição do mapa (`mapa_page.dart`). Só aparece em lição do curso (texto próprio não tem desenho) e com o Ouvir na árvore (inglês).
- **Player próprio da lição** (decisão: não bagunçar a fila do Ouvir): `assistirLicao()` em `ouvir/assistir/assistir_licao_page.dart` cria um `OuvirCubit` só da tela (na mesma `SaidaDeAudio`, sem prefs nem sessão de mídia; velocidade do Ouvir, resto no padrão), toca a lição (`FonteOuvir('avulso')`, não grava posição) e abre a `AssistirLicaoPage` (o `PalcoAssistir` em tela cheia + ⏮ ⏯ ⏭; espaço/←/→/Esc). Se o 🎧 Ouvir estava tocando, ele **pausa** (a fila dele não muda e não volta sozinho). Ao fechar, o cubit fecha (cala a saída) e a lição volta com o teclado na frase (ou na vitória). Não grava progresso.
- **Teste novo:** `test/ingles_assistir_licao_test.dart` (2): na lição com o Ouvir tocando (pausa, fila do curso intacta, player próprio com 3 frases, ⏭ só no próprio, fechar cala e progresso igual) e na folha do mapa.
- **Validação:** `flutter analyze lib` sem avisos; suíte inteira **3.193 testes, 3.187 passam, 6 falham**: as 5 de sempre do `csharp_curriculo_test` + `ingles_curriculo_test` "o motor digita toda frase…" por **timeout de 30 s** — falha igual no commit anterior (máquina de nuvem mais lenta; não é desta mudança).
- **Conferir à mão:** a voz e o desenho num aparelho de verdade; o mini-player do Ouvir pausado por baixo da tela do 📺.

## 📺 22/out/2026 (rodada 18): histórias escritas do C1 e do Dev — o curso inteiro com ✨ história especial (FEITO; sem deploy)

- **Publicadas 25 trilhas (127 lições):** as 14 do C1 e as 11 `pro-*` do Dev, a partir dos rascunhos validados de `tools/ingles/historias/rascunhos_c1_dev/` (a pasta saiu do repo). O `indice.json` agora lista **as 121 trilhas** do curso.
- **Passada do revisor (RECEITA §9 passo 9):** 5 revisores, 5 trilhas cada. 13 ajustes pontuais, nenhum id de frase nem ordem de âncora mexido: gestos que contradiziam a fala (`concorda` numa discordância, `nega` numa explicação, "You can say that again" com `nega`, apontar para a diretora ao agradecer), um `zzz` que parecia sono, reações sem sentido no Thanksgiving, a garrafa da rodada em cima do Mike, o mudo do dev novo que estragava o "Don't worry", `sensato-e-abrangente` da videochamada para o escritório (como a foto), a hora de `cena-final-o-artigo-e-os-resultados` (noite) e dois arcos (`phrasal-verbs-c1`, `pro-dia-de-trabalho`).
- **Teste ajustado:** `ingles_historias_licoes_conteudo_test` "preparar → … uma lição fora do piloto sai automática" procurava uma trilha sem história e não acha mais nenhuma; agora o bundle de teste esconde uma trilha do índice (`_BundleSemTrilha`) e confere que ela cai na automática com a tabela.
- **Validação:** `validar_historias_licoes.py --pasta assets/ingles/historias` 0 erros e 1 aviso de propósito (o de sempre, `prazer-ate-amanha`); cada trilha nova 0 erros / 0 avisos; `--auto-teste` 59/59; `ingles_historias_licoes_conteudo`, `historias_licoes_repo`, `assistir_historias_licoes` e `historias_licoes_paridade`: 203/203.
- **Pendente:** build + deploy (o lote é asset do bundle: o dono só vê depois do deploy); prova visual opcional de 2–3 lições.

## 📺 22/out/2026: 2ª leva de arte das historinhas (os pedidos de arte dos lotes)

Branch `claude/arte-historias`. Sem deploy.

- **Agrupamento** de `planejamento/historias-licoes/PEDIDOS-DE-ARTE.md` (a contagem ficou no topo do arquivo): telão/tela de reunião/gráfico ≈ 30, copa ≈ 14, recepção do hotel ≈ 13, quadro branco ≈ 13, sofá + TV ≈ 12, caixa ≈ 12, bolo ≈ 11, caderno ≈ 10, casaco ≈ 9, taça ≈ 8. Os 10 mais pedidos viraram arte.
- **Cenários novos** (fim do `CenarioHistoria`, interiores, 4 horas): `copa` (geladeira de inox, cafeteira com luzinha, pia, micro-ondas com o relógio da hora, canecas penduradas, janela com Chicago e a mesa alta; no largo: mural de avisos, bebedouro e a parede de vidro da sala de reunião com o telão aceso), `recepcaoHotel` (balcão com sino, monitor, orquídea e folhetos, escaninho das chaves, placa de estrelas, lustre, elevador com o andar, porta de vidro da rua com toldo, carrinho de bagagem, poltrona e tapete vermelho), `salaDeEstar` (TV no painel de ripas passando o jogo, rack, sofá mostarda de 3 lugares com a mesinha e a pipoca, luminária de pé, janela com cortinas). Cada um é **um cômodo só** em qualquer largura: as peças principais aparecem uma vez e o resto da parede vira janela/quadros/arandelas/estante (`_vaosDaParede`, que também divide o vão que passa pela borda para nada ficar cortado ao meio). Na sala, a TV fica no meio da parede (acima das cabeças) e o sofá entre `centroDireita` e `direita`, onde uma cena a dois não o tampa.
- **Props novos** (fim do `PropHistoria`): `telao` (pedestal de rodinhas, gráfico de barras e linha), `quadroBranco` (caixas, setas, post-its e marcadores), `caixa` (papelão com fita e ↑↑), `bolo` (velinhas que tremulam), `caderno` (espiral), `casaco`, `taca` (espumante com bolhinhas). Telão e quadro são móveis (≈ .8 e .72 da altura do ator no chão; na mão encolhem para .3).
- **Histórias:** 100 trocas em 58 trilhas (só `cenario`, `prop`, `segura` e o `alvo` que apontava para o objeto trocado; nenhum id de frase nem ordem de âncora): escritório → `copa` (11 cenas), hotel → `recepcaoHotel` (10), casa → `salaDeEstar` (7), notebook-como-tela → `telao` (28), documento/notebook-como-quadro → `quadroBranco` (4), mala/sacola → `caixa`, prato/presente → `bolo`, livro/documento → `caderno`, cachecol → `casaco`, caneca do brinde → `taca`. Na `videochamada` o notebook-como-quadro-virtual ficou (outra leva). Ferramenta de troca sem reformatar o JSON: no scratchpad da sessão (não versionada).
- **Validadores:** os enums são lidos por regex (Python) e as listas das lições são de proibidos, então nada mudou no código deles; `RECEITA.md` §5.4 ganhou os 3 cenários e os 7 props; `montar_contexto_lote.py` lista os cenários novos. O encenador automático não mudou (as 602 automáticas continuam iguais).
- **Testes:** novo `test/historia_cenarios_licao2_test.dart` (12: enums no fim e ordem antiga intacta, 4 horas/noite mais escura, chão coberto, **não repete o cômodo em meia tela nem em um terço**, paralaxe sem emenda, diferente dos 30 de antes, props ≥ 25% pintados e na mão, e as histórias usam cada novo). Ajustados de propósito, com comentário: `historia_fundo_test` (contagem 111 → 123 pares cenário/hora), `historia_licao_modelo_test` e `historia_cenarios_licao_test` (conferem a fatia da 1ª leva em vez do "fim do enum").
- **Prova visual:** PNGs com a Roboto de verdade (palco inteiro com atores e balão) das 3 salas nas 4 horas em 1280×720, 390×300 (página do celular em pé), 390×600 (retrato, 2 filas), 844×390 e 2560×1080, e de cada prop no chão e na mão; corrigidos: o lambri da recepção tapava o vidro da porta, prédios da rua altos demais, quadro e estante cortados na borda, mural sem lugar em 1280, luminária que dava a volta na tela, botão do elevador que ia para a outra borda, TV e sofá atrás dos atores da cena a dois, noite pouco escura no retrato da sala.
- **Conferir no aparelho:** uma lição de check-in (`situacao-hotel.check-in-tenho-uma-reserva`), uma de copa (`perguntas-com-be.cena-um-colega-novo`), uma de sofá (`there-is-lugares.em-cima-da-mesa-embaixo-do-sofa`) e uma com telão (`conceder-rebater.dito-isso`), no celular em pé e deitado.
