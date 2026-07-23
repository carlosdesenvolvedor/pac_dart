# PAC·DART — Estado do Projeto (handoff)

> Treinador de digitação que ensina **Dart & Flutter**: você digita código real,
> um Pac-Man "come" as letras, e ao concluir o trecho ele "compila" — mostrando a
> saída no console e, nos exercícios Flutter, uma **prévia do widget renderizado**.
> Feito em **Flutter (web)** com **flutter_bloc**. Tudo em português do Brasil.

Última atualização: jul/2026.

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
  hora, "Pular quiz" segue sem ele) → quando **todas as lições da trilha** estão feitas, emendam os
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
- **🎮 Arcade Dart** (`lib/features/arcade/`, jul/2026) — joguinhos de programação, banco
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
  - **Prova visual sem login**: `lib/main_arcade_probe.dart` renderiza PistaPro/cenários/avatares
    cru — `flutter build web -t lib/main_arcade_probe.dart --output=build/probe` + Chrome headless
    `--screenshot` servindo a pasta. Foi assim que o layout do cenário foi conferido/ajustado.
- **🐦 Prof. Dash — tutor de IA (jul/2026)** (`lib/features/tutor/`): chat que SEMPRE enxerga o
  estudo — `contextoDoEstudo(CursoState, TypingState)` empacota trilha/lição/resumo/teoria/o
  trecho digitado/saída esperada/precisão e VIAJA junto de cada pergunta (chip "👀 vendo: …"
  mostra ao aluno). Backend: **API do Gemini DIRETA**
  (`package:http`, POST generateContent, modelo **`gemini-flash-latest`** — alias que acompanha
  o flash mais novo; o gemini-2.5-flash foi APOSENTADO pra contas novas e derrubou a 1ª versão).
  A chave (criada via `gcloud services api-keys create`) é RESTRITA por referer
  (`https://pac-dart.web.app/*`, **`https://pac-dart.web.app./*` — SIM, com PONTO FINAL:
  o usuário navega no FQDN `pac-dart.web.app.` e o browser manda esse referer, que é OUTRA
  origem** — mais `pac-dart.firebaseapp.com/*` e `http://localhost:*/*`) E por API (só
  generativelanguage) —
  pública por design, igual à chave web do Firebase; testada com curl (200 no domínio, 403 fora).
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
  features/ranking/             # domain/jogador_ranking (critérios+ordenação) ·
                                # data/ranking_repository (Firestore `ranking/{uid}`) ·
                                # presentation/ranking_cubit (deltas+pendências) + ranking_page (pódio)
  features/arcade/              # domain: desafio, banco_desafios (76), palavras_dart (93),
                                #   corrida/futebol/caca_bug/tiro_engine, digitar_palavra
                                # presentation: arcade_page (hub) + 5 jogos (corrida, futebol,
                                #   caca_bug, chuva, rali) + widgets (arcade_ui, campo_teclas)
  features/preview/             # interpretador próprio (parser + widget_builder) + preview_engine
  firebase_options.dart         # gerado por flutterfire configure
assets/  curriculo.json · master.json · backgrounds/ · fonts (google_fonts em runtime)
```

Estado: `flutter_bloc`. Cores via `Mixart.*` (getters que seguem `Mixart.atual`).

---

## 🔥 Firebase

- Auth **Email/senha** habilitado (feito no console; Identity Platform pago exige billing, o grátis é só o toggle).
- Firestore: doc por usuário `users/{uid}` (concluidas[], quizNotas{}, **projetos[]**, trilha, licao, recorde). Regras em `firestore.rules`: **só o dono acessa** (são por documento, não por campo — campo novo não precisa de deploy de regras).
- **`ranking/{uid}`** (jul/2026): apelido, pontos, teclas, erros, licoes, projetos, quizAcertos, arcadePontos, arcade{jogo→recorde}, atualizadoEm. Regras: **todo logado lê, só o dono escreve** — regras JÁ DEPLOYADAS (`firebase deploy --only firestore:rules`). Query do top: orderBy pontos desc (índice single-field automático).
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
9. **Motor de prévia (projetos `flutter:true`) — só um SUBSET:** o `cod` deve ser UMA expressão de widget LITERAL começando por `Scaffold(`/`Center(` (sem variáveis/funções/setState/classes). O interpretador **não** entende: `Color(0xFF...)` (use `Colors.*`), tipos genéricos `Widget<Tipo>(...)` (ex.: `DropdownButton<String>`), `Sliver*`, `PageView`, `CustomPaint`, `FilledButton`, `LayoutBuilder`, `MediaQuery`, `Theme.of`. `SizedBox(height:N)` sem filho vira, **de propósito**, uma caixinha de contorno azul-claro (marca o espaço). Valide qualquer app novo com `PREVIEW_JSON=arquivo.json flutter test test/tools/preview_check.dart` — tem que dar **status OK** (raiz parseia inteira), não "PARCIAL".
10. **Toda lição PRECISA de ≥1 bloco `teoria` do tipo `code`** (o `teoria_test` exige). Lições de comparação/decisão também.
11. **DartPad embutido — o jeito documentado MORREU.** A wiki oficial ainda cita `embed-flutter.html`
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
12. **`assets/roda.json` é GERADO — regere se mexer no currículo ou no gerador.** Receita (o lab fica
    FORA do projeto):
    ```bash
    LAB=/tmp/rodavel_lab   # pubspec com dependência flutter + flutter pub get
    SAIDA=$LAB/lib/gen flutter test test/tools/rodavel_check.dart   # gera 2445 programas
    cd $LAB && flutter analyze > analise.txt                        # quem tem erro fica de fora
    # cruzar analise.txt com $LAB/lib/indice.json → assets/roda.json
    ```
    O app tem que gerar EXATAMENTE o mesmo programa que foi analisado: mesma noção de "é Flutter"
    (`ehTrilhaFlutter`) e mesmo `contexto` (trechos anteriores da lição). Se divergir, o mapa mente.
13. **`carregarRodaveis()` faz I/O de asset:** em `testWidgets` o relógio é falso e o `rootBundle`
    nunca resolve — o fake do loader nos testes PRECISA sobrescrever esse método (ver `fluxo_test`).
14. **Fonte mono SEM ligaduras + teclado Mac:** `Mixart.mono()` desliga liga/calt/clig/dlig —
    a JetBrains Mono fundia `->` em `→` e `!=` em `≠` e o jogador não sabia o que teclar
    (bug real, jul/2026). NÃO reativar. No Mac ABNT, `~`+espaço solta U+02DC (˜), não `~`:
    `TypingBloc.equivalenciasTeclado` normaliza (˜→~, ˆ→^, aspas curvas→retas, travessões→hífen)
    no motor E no quiz. `test/teclado_equivalencias_test.dart` cobre. Além disso, TODO `cod`
    precisa ser 100% digitável (ASCII + acentos pt-BR): `test/conteudo_digitavel_test.dart`
    varre os 2445 códigos — `°`/`º` foram trocados por texto puro no Card de Clima e no
    Placar do Campeonato (cod E out).
15. **Subagentes podem deixar lixo no projeto:** ao gerar conteúdo em massa, eles às vezes criam arquivos `*_check.dart`/`tmp_*.dart` em `test/tools/` ou na raiz pra validar render. Faça uma varredura (`find . -name '*.dart'` fora de `lib/` e não-`_test`) e remova antes do `flutter analyze`/deploy. O único arquivo legítimo em `test/tools/` é `preview_check.dart`.

---

## 📋 Pendências / próximos passos

- ✅ Código sincronizado com o GitHub (última sessão: Prof. Dash tutor IA + tudo anterior).
- (nada pendente no console: o tutor fala com o Gemini via chave restrita por domínio)
- Adicionar os **topics** no GitHub (flutter, dart, bloc, typing-game, education, pacman) — precisa do agente do Chrome no site.
- (opcional) Sincronizar o **tema por usuário** (hoje é por dispositivo, no shared_preferences).
- (opcional) Sons de arcade (waka-waka), mais joguinhos (o hub em `arcade_page.dart` é uma lista — é só acrescentar o card + página), troféus/temporadas no ranking (hoje é all-time), avatar/apelido editável.
- (opcional) Anti-farming leve no ranking (repetir quiz re-pontua; tudo bem enquanto for entre amigos).

---

## 🧪 Testes (140, todos passando)

`test/`: typing_bloc · preview_engine · preview_cobertura · quiz · teoria · projetos (30 apps) · auth · theme · app_smoke · **fluxo** (sequência quiz/projetos + progresso dos projetos) · **dartpad** (botão "rodar", gerador de programa rodável, plano B fora da web) · **ranking** (repo com fake_cloud_firestore, deltas/pendência do cubit, ordenação por critério, página com pódio) · **arcade** (banco jogável, embaralhado preserva a certa, escadinha de nível, 3 engines) · **arcade_ui** (hub, Gol de Dart determinístico com `semente` — 5 gols = 130 pts no ranking —, corrida com turbo, Chuva destruindo palavra por digitação, Rali com turbo, futebol passando de fase e guardando 130 pts, CampoTeclas retomando o foco sozinho, cenários/dicas ciclando, equivalências de teclado (˜/aspas curvas/travessão) a varredura de digitabilidade dos 2445 códigos, o gerador de missões (validade/diversidade/consistência) e a missão completa jogada de ponta a ponta (prever → 🔮 ajuda → digitar → animar → vencer → pontos e progresso salvos) — o TextField oculto retém o texto digitado: para "sumiu da arena" use finder de RichText, não find.text). Também **tutor** (contexto do estudo com trilha/lição/trecho, cubit em streaming com memória curta e erro amigável de setup, painel com chip 👀 e sugestões, layout largo/estreito — ⚠️ em testWidgets, `cursoPronto()` com Future.delayed precisa de tester.runAsync). Rodar: `flutter test`.
`test/tools/`: `preview_check.dart` e `rodavel_check.dart` (ferramentas, não rodam no CI).
Também há `logo_test` (a marca desenha em 16…512 px, solta e em selo) e `quiz_ui_test`
(responder por clique, digitar tudo numa linha, e Enter não corrigindo antes da hora).
⚠️ Nos testes de tela do quiz, aumente a viewport (`tester.view.physicalSize`): o `ListView` é
preguiçoso e não constrói o veredito que fica fora da janela — parece bug e não é.

⚠️ **Em `testWidgets`, `await bloc.close()` TRAVA o teste** (o relógio é falso e o close espera algo que
nunca chega) — o teste só morre no timeout de 10 min. Use `await tester.runAsync(() => bloc.close())`.
