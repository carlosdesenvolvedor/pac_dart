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

- ⚠️ Código NÃO sincronizado com o GitHub desde o Arcade 2.0 (Turismo 3D inteiro só local + Firebase).
  Push só quando o usuário pedir.
- **Fila do Dart Turismo (pedidos do usuário, set/2026)**: ✅ pistas 4×, ✅ rock por fase,
  ✅ cidade, ✅ engenheira IA, ✅ vento, ✅ qualidade alta/leve, ✅ tremor opcional, ✅ tutorial,
  ✅ minimapa, ✅ fachadas fotográficas, ✅ cenário real por tema, ✅ pneu cantando. Faltam:
  carro-fantasma da melhor volta; estatísticas/troféus; árvores frondosas realistas (as do Poly
  Haven têm .bin de 100–480 MB — inviável na web).
- Adicionar os **topics** no GitHub (flutter, dart, bloc, typing-game, education, pacman) — precisa do agente do Chrome no site.
- (opcional) Sincronizar o **tema por usuário** (hoje é por dispositivo, no shared_preferences).
- (opcional) Sons de arcade (waka-waka), mais joguinhos (o hub em `arcade_page.dart` é uma lista — é só acrescentar o card + página), troféus/temporadas no ranking (hoje é all-time), avatar/apelido editável.
- (opcional) Anti-farming leve no ranking (repetir quiz re-pontua; tudo bem enquanto for entre amigos).

---

## 🧪 Testes (187, todos passando)

`test/`: typing_bloc · preview_engine · preview_cobertura · quiz · teoria · projetos (30 apps) · auth · theme · app_smoke · **fluxo** (sequência quiz/projetos + progresso dos projetos) · **dartpad** (botão "rodar", gerador de programa rodável, plano B fora da web) · **ranking** (repo com fake_cloud_firestore, deltas/pendência do cubit, ordenação por critério, página com pódio) · **arcade** (banco jogável, embaralhado preserva a certa, escadinha de nível, 3 engines, baralho progressivo por fase sem repetir, combo do TiroEngine) · **arcade_ui** (hub, Gol de Dart determinístico com `semente` — 5 gols = 130 pts no ranking —, corrida com turbo, Chuva destruindo palavra por digitação, Rali com turbo, futebol passando de fase e guardando 130 pts, CampoTeclas retomando o foco sozinho, Esc pausando a Corrida (CPU congela frame a frame — no flutter_test um AnimationController gasta 2 frames por ciclo) e retomando, Caça-Bug esmagando a linha certa, largada 3-2-1 antes de qualquer interação, cenários/dicas ciclando, equivalências de teclado (˜/aspas curvas/travessão) a varredura de digitabilidade dos 2445 códigos, o gerador de missões (validade/diversidade/consistência) e a missão completa jogada de ponta a ponta (prever → 🔮 ajuda → digitar → animar → vencer → pontos e progresso salvos) — o TextField oculto retém o texto digitado: para "sumiu da arena" use finder de RichText, não find.text). Também **tutor** (contexto do estudo com trilha/lição/trecho, cubit em streaming com memória curta e erro amigável de setup, painel com chip 👀 e sugestões, layout largo/estreito — ⚠️ em testWidgets, `cursoPronto()` com Future.delayed precisa de tester.runAsync). E **previa_viva** (regressão da "tela de criando junto": app Flutter do Mão na Massa TEM a PreviewAoVivo lado a lado/empilhada e ela sobrevive à digitação; projeto Dart console NÃO tem — é por design, não bug). Rodar: `flutter test`.
`test/tools/`: `preview_check.dart` e `rodavel_check.dart` (ferramentas, não rodam no CI).
Também há `logo_test` (a marca desenha em 16…512 px, solta e em selo) e `quiz_ui_test`
(responder por clique, digitar tudo numa linha, e Enter não corrigindo antes da hora).
⚠️ Nos testes de tela do quiz, aumente a viewport (`tester.view.physicalSize`): o `ListView` é
preguiçoso e não constrói o veredito que fica fora da janela — parece bug e não é.

⚠️ **Em `testWidgets`, `await bloc.close()` TRAVA o teste** (o relógio é falso e o close espera algo que
nunca chega) — o teste só morre no timeout de 10 min. Use `await tester.runAsync(() => bloc.close())`.
