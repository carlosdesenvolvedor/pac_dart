# Fase 9 — "⚡ Treino do dia" (os 3 cursos; mais rico no Inglês)

> 🛠️ **EM IMPLEMENTAÇÃO em 21/out/2026** (sem commit/deploy), dividida em 5 grupos com arquivos separados (seção 9: A domínio/persistência/
> cubit, B costuras do Inglês, C costuras do Arcade e do quiz, D telas do treino, E fiação, testes do app e docs). O que saiu, as divergências
> deste plano e a prova vão para `ESTADO-DO-PROJETO.md`, seção "⚡ Treino do dia — Fase 9". **Sem mudança em `firestore.rules`**
> (o plano mora em `users/{uid}`, campo `{prefixo}treino_dia`).

> Pedido: um botão que responde "o que eu faço hoje?" — uma sessão de ~10 min montada com o que o aluno já tem (Inglês: 🔁 Revisão →
> 🔥 Palavras → 🎧 Ouvir → 🏁 Rali; Dart/C#: 2 quizzes de revisão + 🏁 Rali), retomável no mesmo dia, zerada à meia-noite local, com
> +3 na meta 1× por conta por dia. ⚠️ **Antes de executar:** SDK em `~/development/flutter`; **UMA pasta de probe, apagada no fim; nada de
> `flutter build web` em loop**; prefira `flutter test`.

> O texto abaixo é o plano aprovado (revisão 2, com a crítica aceita na seção 15), mantido como foi escrito.

---

This was read-only: I edited no project file and ran no build or test. **Revision 2** applies the review in "Crítica considerada" (§15); every point was accepted. I checked these claims against the source:

- **`abrirRevisao`** (`lib/features/ingles/presentation/fixacao.dart:59`):
  - returns `Future<void>` and has no limit;
  - opens the empty memória page when nothing is due (`if (diretas.isNotEmpty || invertidas.isEmpty)`);
  - counts toward the habit per item (`onResultado` / `onNota`).
- **`RevisaoCubit.novasReversas`** is pure: it only reads the daily quota and writes nothing. It is safe to call while composing.
- **`abrirTreinoPalavras`** (`treino_palavras.dart:31`):
  - returns `Future<void>` and already captures cubit, habit, curso and nav before the push;
  - after the pop it may call `virarLicaoCom` (pops to the root) or push `ArcadePage`;
  - `TreinoPalavrasPage` builds `ResumoTreino(onJogar:, rotuloContinuar:, onLicao:)` at `treino_palavras_page.dart:410-425`.
- **`treinarTeimosas`** (`acoes_teimosas.dart:17`) calls `cubit.aceitar()` before training.
- **Teimosas offers at the end of a session:**
  - `SessaoMemoriaPage._gravarTeimosas` (`:203`) calls `sugestao(fimDeRevisao)` + `marcarMostrada`;
  - `SessaoCartoesPage._gravarTeimosas` (`:558`) does the same unless `_ofertaRecente` is set;
  - both summaries show `ListaTeimosas` with buttons only when `_sug != null`.
- **`RaliPage`** (`rali_page.dart`) works in **all three courses**: Dart/C# use `BancoArcade.baralhoRali` fixed lists and English uses `BaralhoFases`.
  - It has no single-phase mode.
  - `_venceuFase` (`:365`) → `registrarFaseVencida`, then the `FaseVencida` overlay.
  - `_fimDeJogo` (`:439`) → `encerrar`.
  - `FimDeJogo` buttons are hard-coded to "Jogar de novo" and "Voltar ao Arcade" (`arcade_ui.dart:641,652`).
  - `CampanhaDeFases.dispose` posts partial points.
- **`QuizPage`** (`quiz_page.dart`):
  - the seed is fixed (`sementeQuiz(t,l)`);
  - `_fechar(seguir:)` pops `bool`;
  - with `emSequencia` it shows "Pular quiz", which pops `true` without finishing;
  - each answer calls `praticou()`;
  - `QuizFinalizado` only ever raises the stored best score (`curso_bloc.dart:407`).
- **🎧 Ouvir:**
  - `tocarItens` → `FonteOuvir('avulso', titulo)`, fire-and-forget;
  - `OuvirCubit.tocar` replaces the current session **without** saving its position, while `fechar()` saves it (`ouvir_cubit.dart:225-231`);
  - `_salvarPosicao` skips `avulso`;
  - the end of the queue gives `acabou` unless `repetirTudo`, and `ouvidas` counts the phrases heard;
  - `fechar()` (`ouvir_cubit.dart:225-236`) emits a **fresh** `OuvirState(config:, telaCheia:)`: in the same emit `status` becomes `parado`, `ouvidas` goes back to 0 and `fonte` becomes null. A listener must read the **previous** state;
  - one `ItemSetlist.doTrecho(licao, trechos)` becomes several faixas in `state.fila`;
  - the mini-player (`OuvirShell`) shows whenever the session is active, not `telaCheia` and not in the Arcade.
- **Existing keys that the treino must NOT reuse:** `treino-fechar` (`treino_palavras_page.dart:643`, tapped by `ingles_treino_palavras_ui_test` and `ingles_minhas_palavras_ui_test`), `treino-ouvir` (`passo_digitar`/`passo_escolha`/`passo_conhecer`), `treino-continuar` (`treino_palavras_page.dart:475` + `barra_feedback.dart:75`). All new keys use the prefix `treino-dia-`.
- **`QuizPage` extras:** `_oQueVem()` (`:326`) writes "A seguir: a próxima lição." / "A seguir: N apps do Mão na Massa."; the X tooltip is "Sair da sequência" with `emSequencia`; `_reinicia` (`:115`, button at `:390`) lets the student finish again.
- **Quiz keys and lookup:** `CursoState.chave(t,l)` (`curso_bloc.dart:170`, the lesson id when it exists) keys both `concluidas` and `quizNotas`; `concluidas` also holds `proj:`, `master:` and `desafio:` entries. `temQuiz(CursoState st, int t, int l)` (`fluxo_licao.dart:86`) runs `gerarQuiz` on every call.
- **`treinarTeimosas`** drops words with an empty `pt` (`acoes_teimosas.dart:25`) and returns without opening anything; `abrirTreinoPalavras` also returns early on an empty list. `devidasHoje` does not filter `pt`.
- **`HabitoCubit`** is account-scoped (`main.dart:232`, outside `_cursoDe`); `TreinoDiaCubit` is per course.
- **`PacDartApp` tests:** 15 files under `test/` mount the full app (`grep -l PacDartApp test/`).
- **Habit:**
  - `HabitoCubit.praticou([n])` is the only way to add units;
  - `FirestoreHabitoRepository` writes field `habito` in `users/{uid}` with `merge:true`;
  - `firestore.rules` `match /users/{uid}` has no field validation, so a new field needs **no rules deploy**.
- **The HUD** `_Toggle({key, rotulo, icone, ligado, onTap})` is private to `hud.dart`. The buttons Wrap starts with `ChipSequencia()`, and the 1 s timer rebuilds the whole HUD.
- **`Linguagem.id`** is `'dart' | 'csharp' | 'ingles'` and `prefixoProgresso` is `'' | 'cs_' | 'en_'`.
- **`treinoSemDevidas(PalavrasCubit, CursoState)`** is public in `arcade_page.dart:31`.
- **The map** sliver list starts with `_HeroDashboard` (`mapa_page.dart:238`).

---

## 1. Goals

1. **One tap answers "o que eu faço hoje?"** A HUD button opens a ~10 min session built from what the student already has.
2. **It reuses the real sessions.** Revisão, cartões, word training, Ouvir, Rali and Quiz are launched with a "modo treino" flag; nothing is reimplemented.
3. **It reinforces the ofensiva.** The real exercises inside the treino count as they already do, plus a small, fixed bonus for finishing with at least one real exercise done (once per account per day, whatever the course).
4. **It survives interruptions.** Leave mid-session, come back later the same day and continue from the next pending block. The plan resets at local midnight.
5. **It covers all 3 courses.** English gets 4 blocks. Dart and C# get a lean version (quiz review + Rali) instead of being left out, because the streak is one per account.

## 2. Which courses, and why

| Course | Blocks (in order) | Why |
|---|---|---|
| **Inglês** | 🔁 Revisão (frases + cartões) → 🔥 Palavras (teimosas / devidas / fracas) → 🎧 Ouvir (trecho curto) → 🏁 Rali (1 fase com as suas palavras) | All the sources exist: SRS, word bank, Ouvir, typing games with the student's own vocabulary |
| **Dart / C#** | 🧩 Quiz de revisão · lição A → 🧩 Quiz de revisão · lição B → 🏁 Rali (1 fase) | There is no SRS, no word bank, no Ouvir and no timestamps. But completed lessons have quizzes (`temQuiz`) with best scores (`quizNotas`), and the Rali works with the fixed keyword lists. "Due" is approximated honestly by "lição concluída com a pior nota de quiz (ou sem quiz)", rotated by day. Without a treino in Dart/C# the HUD would show nothing there, while the streak still counts in those courses |

## 3. UX flows (pt-BR strings are canonical)

### 3.1 HUD button
- **Position:** right after `ChipSequencia()` (next to the streak, which is what it feeds). Key `treino-dia-hud`. Icon `Icons.bolt_rounded`.
- **States** (computed on every 1 s HUD tick from `TreinoDiaCubit`):

  | Situação | Rótulo | `ligado` | Tooltip/Semantics |
  |---|---|---|---|
  | pendente (no plan today, or nothing resolved yet) | **Treino** | true (brand fill: calls attention) | "Treino do dia: ~10 min" |
  | emAndamento | **Treino 2/4** (resolved/total) | true | "Treino do dia: continuar" |
  | concluido | **Treino ✓** | false | "Treino do dia feito" |

- **Tap:** `abrirTreinoDoDia(context)` pushes `TreinoDiaPage`.

### 3.2 Map card (second entry point, all courses)
- `_CartaoTreinoDia` (key `treino-dia-cartao-mapa`) is the first card after `_HeroDashboard`, using the existing card pattern (emoji 26, title display16, subtitle ui12 muted, chevron).
- **Title:** "⚡ Treino do dia".
- **Subtitle by state:**
  - pendente: "~10 min com o que você precisa revisar hoje";
  - emAndamento: "Continuar · {feitos} de {total} etapas";
  - concluido: "Feito hoje ✓ — volte amanhã".

### 3.3 `TreinoDiaPage` (the session hub; one route for the whole session)

**Composing** (key `treino-dia-montando`): a spinner with "Montando seu treino…". The order is fixed (§9.1):
1. `await cubit.carregar()` (the saved plan, local + Firestore). If today's plan exists, resume it; nothing is composed.
2. Otherwise `lerFontes` waits for the sources with no hard cut-off. The spinner stays up.
3. After **8 s** without all sources, the spinner gains the line "Está demorando um pouco…" and two buttons: "Tentar de novo" (key `treino-dia-tentar`, restarts the wait) and "Começar assim mesmo" (key `treino-dia-comecar-assim`, composes with what has loaded so far, marking the plan `incompleto`). If the sources arrive meanwhile, the page continues by itself.
4. A plan composed `incompleto` is **upgraded** later (§5.1 `completarPlano`): on every reopen and before each block launch, while no active block is resolved, the page re-reads the sources and inserts the missing `revisao`/`palavras`/`quiz` blocks at the front.

**Body** (max width 720, single column, scrolls):
- **Header:** "⚡ Treino do dia", with the subtitle "~{min} min · {n} etapas · {data por extenso curta, ex.: ter, 21 out}".
- **Segmented progress bar** (key `treino-dia-progresso`): one segment per block. Done = brand, skipped = `Mixart.border` hatched/faint, current = brand outline, pending = surface.
- **Block cards** (key `treino-dia-bloco-<id>`): emoji, title, subtitle with planned count and estimate, and a status chip:
  - "✓ Feito · {resultado}";
  - "⏭ Pulado";
  - "▶ Agora" for the next pending block;
  - "Depois".

  The current card also shows the link "Pular esta etapa" (key `treino-dia-pular`).
- **Main button** (key `treino-dia-comecar`):
  - "▶ Começar" when nothing is resolved;
  - "▶ Continuar · {título do bloco}" otherwise.
- **After a block returns:** the hub shows a one-line snackbar or banner such as "✓ Revisão feita! Próximo: 🔥 Palavras", and the main button points at the next block. **There is no auto-launch**: one tap to continue, and the student may stop at any time.
- **Short plan** (`plano.curto`) shows the hint card "Ainda há pouco para revisar — o treino de hoje é curto. Depois, siga para a sua próxima lição ✍️."
- **X / back:** pops. The progress is already persisted. The HUD shows "Treino 1/4" and the next open resumes.

**Block titles and subtitles:**

| id | Title | Subtitle (planned) | Result chip |
|---|---|---|---|
| `revisao` | 🔁 Revisão do dia | "{n} frases de memória · {m} cartões · ~{t} min" (or only one of the parts) | "✓ {k} revisadas" |
| `palavras` | 🔥 Palavras teimosas / 🔤 Palavras do dia / 🔤 Treino de palavras (decided when the block starts; the plan shows "🔥 Palavras" + "até 6 palavras · ~2 min") | | "✓ {k} palavras" |
| `ouvir` | 🎧 Ouvir | "{n} frases para ouvir · ~1 min" | "✓ {k} frases ouvidas" |
| `rali` | 🏁 Rali relâmpago | Inglês: "1 fase com as suas palavras · ~2 min"; Dart/C#: "1 fase digitando código · ~2 min" | "✓ {pts} pts" or "✓ jogou" |
| `quiz:t:l` | 🧩 Quiz · {nome da lição} | "até 10 perguntas · ~4 min" | "✓ {acertos}/{total}" |

### 3.4 Block behaviour

- **🔁 Revisão:** `abrirRevisao(context, limiteFrases: 8, limiteCartoes: 4, modoTreino: true)`.
  - It pushes the memória page ("Revisão do dia") and then the cartões page, exactly as the HUD does, but limited and with no teimosas offer buttons. Tropeços are still listed, for information only.
  - **Feito** when every part that had items reached its `onFim`.
  - **Nothing due when it starts** (reviewed elsewhere in the meantime): the block is marked feito with 0 and `vazio: true`, and the banner says "✓ Nada vencendo agora — você já está em dia." A `vazio` block never counts toward the bonus (§4).
  - The phrases answered are stored in `plano.ouvirChaves` (≤ 6) for the Ouvir block.
- **🔥 Palavras** (chosen when the block starts, at most 6):
  1. `teimosas(max: 6)` → `treinarTeimosas(..., modoTreino: true)` (revanche, title "🔥 Revanche das teimosas");
  2. else `devidasHoje.take(6)` → `abrirTreinoPalavras(titulo: '🔤 Palavras do dia', modoTreino: true)`;
  3. else `treinoSemDevidas(...).take(6)` → title "🔤 Treino de palavras";
  4. else feito with 0 (`vazio`), banner "✓ Nenhuma palavra pendente agora."

  Every source is filtered to **trainable** words first (`en` and `pt` non-empty, the same rule as `treinarTeimosas` / `treinoSemDevidas`). A source whose words all lack a translation counts as empty, so the block becomes `BlocoVazio` instead of a launcher that returns null and leaves the block stuck in pendente.

  The summary (`ResumoTreino`) has no "🎮 Jogar" and no "📝 Virar lição", and **only its** main button reads "CONTINUAR O TREINO →". The per-step button (`treino-continuar`) and the feedback bar keep "CONTINUAR". A non-null result means feito, and its words go to `plano.palavrasFoco`.
- **🎧 Ouvir:** the hub switches into an inline `PainelOuvirTreino` (no new route).
  - **Resuming a running session:** if `ouvir.state.fonte?.titulo == tituloOuvirTreino` and the session is active (the student left the page mid-Ouvir and the player kept going), the panel attaches to it. It does **not** call `tocarItens` again, so it does not restart from zero. If that session is already `acabou` (the queue ended while the page was closed), the page marks the block feito on open and calls `fechar()`.
  - **Starting:** if another Ouvir session is active and is not `avulso`, `ouvir.fechar()` first (this saves the course/setlist position). Then `tocarItens(ctx, itens, titulo: '⚡ Treino do dia')`.
  - **Target:** `alvo = ouvir.state.fila.length`, read **after** `tocarItens` (faixas, never the number of `ItemSetlist`: one `doTrecho` item expands to up to 6 faixas). When attaching to a running session, the same `fila.length` is used.
  - **Mini-player:** while the panel is open the page calls `ouvir.telaCheia(true)`, which hides the `OuvirShell` mini-player and avoids duplicate controls. It calls `telaCheia(false)` in `dispose` and when the panel closes.
  - **Panel** (key `treino-dia-ouvir`):
    - the character emoji/name, EN large, PT caption, and "Frase {indice+1} de {fila.length}";
    - ⏯ (key `treino-dia-ouvir-play`) → `pausar` / `continuar`;
    - "Pular" (key `treino-dia-ouvir-pular`).
  - **Pause banners:**
    - `outraFala`: "Pausado — outra fala começou. ▶ para continuar.";
    - `semSom`: "Não consegui tocar o som. Toque ▶ ou pule esta etapa.".
  - **Feito** when `fonte.titulo == '⚡ Treino do dia'` and (`status == acabou` or `ouvidas >= alvo`). This also covers a global `repetirTudo`. On feito, `ouvir.fechar()` ends the session.
  - **A stop from outside** (any `fechar()` the panel did not ask for, such as the ✕ of a player elsewhere): `fechar()` resets `ouvidas` and `fonte` in the same emit, so the listener uses `listenWhen: (a, b) => a.fonte?.titulo == tituloOuvirTreino && b.status == StatusOuvir.parado` and reads **`a.ouvidas`** (the previous state). The panel also keeps the last `ouvidas` it saw with the treino source, as a fallback. With `ouvidas >= ceil(alvo/2)` the block counts as feito; otherwise it goes back to pendente, with the button "▶ Ouvir de novo".
  - **Excerpt source:**
    1. `plano.ouvirChaves` (the phrases just reviewed), via `ItemSetlist.daFrase(trecho, licao:)`;
    2. else the last completed non-`propria` lesson (highest `(t,l)` in `concluidas`): `ItemSetlist.doTrecho(licao, first 6 trechos)`;
    3. else the current lesson, the same way. That one is a preview of what comes next.
- **🏁 Rali:**
  - **English only:** `await palavras.prepararIndice(trilhas)` and `palavras.focar(plano.palavrasFoco)`. The focus persists about 30 min in the Arcade, which is documented and intended.
  - **All courses:** push `RaliPage(treino: true)` with `RouteSettings(name: rotaArcade)`. In treino mode the page:
    - skips the start screen and starts on 🐢 Fácil after the first frame;
    - plays exactly one phase;
    - suppresses the teimosas offers;
    - ends on a `FimDeJogo` with the title "FASE VENCIDA! ⚡" or "A CPU VENCEU…", the subtitle "Fase relâmpago do treino: {palavras} palavras.", no "Jogar de novo", and "Continuar o treino →" drawn as the **primary** button (FilledButton brand, not the outlined secondary one).
  - **Result:** the page pops `ResultadoFaseTreino(venceu, pontos, palavras)`. A win **or** a loss means feito. Pause → Sair pops null, so the block stays pendente.
  - The ranking points are the normal Rali points, unchanged.
- **🧩 Quiz (Dart/C#):** push `QuizPage(trilhaIdx, licaoIdx, licao, poolTrilha, emSequencia: false, semente: sementeQuiz(t,l) ^ (dia * 7919), onTerminou: ...)`.
  - `emSequencia: false` on purpose: with `true` the result screen would say "A seguir: a próxima lição." / "A seguir: N apps do Mão na Massa." (`_oQueVem`), the X would read "Sair da sequência" and a "Pular quiz" would sit on top of the hub's "Pular esta etapa". With `false` the X reads "Voltar" and there is no "Pular quiz"; the feito comes from `onTerminou`, not from the pop value. With `false` the result's primary button would read "Voltar ao mapa", so the treino passes `rotuloFim: 'Continuar o treino →'` (new optional field, §7.2). "Repetir quiz" stays.
  - **Feito** only via `onTerminou` (the last question answered), which fires **once per page**, even if the student taps refazer (`_reinicia`) and finishes again. Back before the end leaves the block pendente.
  - The seed changes each day, so the questions vary.
  - `QuizFinalizado` keeps only the best score, so a review can never lower it.

### 3.5 Completion screen (same page, `plano.concluido`)
- **Key** `treino-dia-fim`, with confetti (`Confete`, already in the arcade UI) when `feitos >= 1`.
- **Title:**
  - "Treino do dia completo! ⚡" when feitos ≥ 1;
  - "Hoje foi só uma passada" when everything was skipped.
- **Summary chips:** "🔁 {k} frases", "🔥 {k} palavras", "🎧 {k} ouvidas", "🏁 {pts} pts", "🧩 {a}/{b}" (only for the blocks that exist).
- **Streak card** (BlocBuilder<HabitoCubit>):
  - "🔥 {n} dias seguidos" (`sequenciaVisivel`);
  - "Meta de hoje: {feitas}/{meta}";
  - "+{bonus} na meta pelo treino completo ⚡" when the bonus was granted by this plan;
  - "Bônus do treino já ganho hoje ✓" when the plan qualified but the account already took today's bonus in another course;
  - nothing about the bonus when the plan did not qualify (no active exercise done, or `curto`).
- **Buttons:**
  - "✍️ Continuar minha lição" (key `treino-dia-ir-licao`): `Navigator.popUntil(first)`. The home screen is the palco or editor at the current lesson.
  - "Fechar" (key `treino-dia-fechar`).
- **Reopening on the same day** shows this screen again, with "Volte amanhã para um treino novo 🌅".

## 4. Streak / XP policy

- **Units come from the real exercises,** as today:
  - revisão: 1 per phrase and 1 per card, on the 1st attempt;
  - word training: `r.passos`;
  - quiz: 1 per answer.

  Ouvir and Rali still give no units, which keeps D3.
- **Completion bonus:** `const bonusTreino = 3`, granted through the new `HabitoCubit.ganharBonusTreino(bonusTreino)` (§7.3).
  - **The plan qualifies** (`PlanoTreino.merecebonus`) only when all of these hold:
    - the plan is concluded and `!bonus`;
    - `!curto` and `!incompleto`;
    - **at least one active block** (`revisao`, `palavras`, `quiz`) is `feito`, **not `vazio`**, and has `resultado > 0`;
    - `feitos >= min(2, blocos.length)`, where a `vazio` block does not count as feito.
  - So Ouvir, Rali, a lost Rali phase and blocks that were empty when they started can never earn the bonus by themselves. This keeps D3: passive blocks give no units, directly or through the bonus.
  - **Once per account per day:** the habit stores `bonusTreinoDia` (§7.3). `ganharBonusTreino` returns false, and adds nothing, when it is already today. The per-course plans (`uid:linguagem`) can no longer add +9 in one day.
  - **Order:** the page sets `plano.bonus = true` (persisted) first, then calls `ganharBonusTreino`. A resume or reload never retries the plan, and the habit's own guard covers the other courses.
  - This is the only new habit source: a deliberate, documented policy. It rewards finishing a treino that had real practice, and it is small next to the 10/20/40 goals.
- **There is no XP system** and none is created. The ranking is unchanged. Habit and treino never go to `ranking/{uid}` (D5). The Rali points are the game's own.

## 5. Data model (pure Dart): `lib/features/treino_dia/domain/plano_treino.dart`

```dart
const bonusTreino = 3;
const tituloOuvirTreino = '⚡ Treino do dia';

enum TipoBloco { revisao, palavras, ouvir, rali, quiz }
enum EstadoBloco { pendente, feito, pulado }
enum SituacaoTreino { pendente, emAndamento, concluido }

class BlocoTreino extends Equatable {
  final String id;          // 'revisao' | 'palavras' | 'ouvir' | 'rali' | 'quiz:<t>:<l>'
  final TipoBloco tipo;
  final EstadoBloco estado; // pendente
  final int qtd;            // planned count for the subtitle (frases, palavras, perguntas…)
  final int qtd2;           // revisao: planned cards; 0 otherwise
  final int minutos;        // estimate shown in the UI (≥1)
  final int resultado;      // revisadas / palavras / ouvidas / pontos / acertos
  final int total;          // quiz: perguntas; 0 otherwise
  final int t, l;           // quiz only; -1 otherwise
  final bool vazio;         // marked feito because there was nothing to do when it started (BlocoVazio)
  const BlocoTreino({required this.id, required this.tipo, this.estado = EstadoBloco.pendente,
      this.qtd = 0, this.qtd2 = 0, this.minutos = 1, this.resultado = 0, this.total = 0, this.t = -1, this.l = -1,
      this.vazio = false});
  BlocoTreino copyWith({EstadoBloco? estado, int? resultado, int? total, bool? vazio});
  bool get resolvido => estado != EstadoBloco.pendente;
  bool get ativo => tipo == TipoBloco.revisao || tipo == TipoBloco.palavras || tipo == TipoBloco.quiz;
  bool get feitoDeVerdade => estado == EstadoBloco.feito && !vazio;   // what counts for the bonus
  Map<String, dynamic> toJson();               // short keys: i,y,e,q,q2,m,r,n,t,l,z (block defaults omitted: blocks are
                                               // replaced as a whole list, never merged key by key)
  static BlocoTreino? fromJson(Object? j);     // tolerant: unknown tipo → null (dropped)
}

class PlanoTreino extends Equatable {
  final int dia;                  // diaDe(agora) — local calendar day
  final String curso;             // Linguagem.id
  final List<BlocoTreino> blocos;
  final List<String> ouvirChaves; // ≤ 6, chaveDaFrase of the phrases reviewed in this treino
  final List<String> palavrasFoco;// ≤ 12, EN words trained in this treino
  final bool curto;               // no active-learning block (revisao/palavras/quiz)
  final bool incompleto;          // composed with "Começar assim mesmo" before every source loaded (§3.3)
  final bool bonus;               // this plan already went through the bonus step (granted or not)
  final int editadoEm;            // ms
  const PlanoTreino({...});

  int get resolvidos; int get minutos;
  int get feitos;                                 // estado == feito && !vazio
  bool get concluido => blocos.isNotEmpty && blocos.every((b) => b.resolvido);
  bool get algumAtivoResolvido => blocos.any((b) => b.ativo && b.resolvido);
  BlocoTreino? get proximo;                       // first pendente
  SituacaoTreino get situacao;                    // resolvidos==0 → pendente; concluido → concluido; else emAndamento
  bool get merecebonus => concluido && !bonus && !curto && !incompleto
      && blocos.any((b) => b.ativo && b.feitoDeVerdade && b.resultado > 0)
      && feitos >= math.min(2, blocos.length);
  PlanoTreino marcar(String id, EstadoBloco e, {int? resultado, int? total, bool vazio = false, required int agoraMs});
  /// Inserts [novos] (active blocks whose id is not in the plan yet) at the front, recomputes curto,
  /// and clears incompleto when [fontesCompletas]. Only allowed while !algumAtivoResolvido.
  PlanoTreino completar(List<BlocoTreino> novos, {required bool fontesCompletas, required int agoraMs});
  PlanoTreino anotarOuvir(Iterable<String> chaves, {required int agoraMs});   // dedupe, cap 6
  PlanoTreino anotarFoco(Iterable<String> ens, {required int agoraMs});       // dedupe, cap 12
  PlanoTreino comBonus({required int agoraMs});
  Map<String, dynamic> toJson();       // {"v":1,"d":dia,"c":curso,"b":[...],"o":[...],"f":[...],"k":curto,"p":incompleto,"x":bonus,"m":ms}
                                       // ALWAYS writes every top-level key, false/[] included (see §6.1, Firestore merge)
  static PlanoTreino? fromJson(Object? j);   // tolerant; v != 1 or garbage → null
  static PlanoTreino? mesclar(PlanoTreino? a, PlanoTreino? b);
}
```

**`mesclar` rules** (commutative, tested):
- One side null → the other.
- Different `curso` → `a`.
- Different `dia` → the higher `dia` wins.
- Same `dia`:
  - The base is the side with more `resolvidos` (tie: higher `editadoEm`, then `a`).
  - For each base block whose id also exists on the other side, the estado is the most advanced: feito > pulado > pendente, and `resultado`/`total` take the max.
  - `bonus` = a || b. `ouvirChaves`/`palavrasFoco` = union, capped.
  - `vazio` follows the side whose estado won. Blocks that exist only on the other side are appended only when the base has no active block resolved (a `completar` made on the other device).
  - `incompleto` = a && b (a complete composition on either side wins). `curto` is recomputed from the merged blocks.

### 5.1 Composer (pure): `lib/features/treino_dia/domain/montar_plano.dart`

```dart
class FontesTreino {
  final bool ingles;
  final int frasesDevidas;    // diretas resolvable, before the limit
  final int cartoes;          // invertidas due + new within the quota, before the limit
  final int teimosas, palavrasDevidas, palavrasFracas;
  // teimosas/palavrasDevidas/palavrasFracas count TRAINABLE words only (en and pt non-empty);
  // palavrasFracas = treinoSemDevidas(palavras, st).length (includes never-trained palavrasDoAluno).
  final bool temOuvir;        // OuvirCubit present
  final List<(int, int)> quizes; // Dart/C#: candidates already ranked (escolherQuizes)
  final bool incompleta;      // some source had not loaded when these numbers were read
  const FontesTreino({...defaults 0/false/const []});
}

/// Limits used for the plan and when each block starts.
abstract final class LimitesTreino {
  static const frases = 8, cartoes = 4, palavras = 6, ouvir = 6, quizes = 2;
}

PlanoTreino montarPlano(FontesTreino f, {required int dia, required String curso, required int agoraMs});
// incompleto = f.incompleta

/// Upgrade of an `incompleto`/`curto` plan (§3.3 step 4): the active blocks montarPlano(f) would add that
/// [p] does not have yet. Returns [p] unchanged when p.algumAtivoResolvido.
PlanoTreino completarPlano(PlanoTreino p, FontesTreino f, {required int agoraMs});

/// Dart/C#: completed lessons that have a quiz. Order: no quiz first, then the lowest score;
/// ties are rotated by [dia] (a stable hash of dia*31+t*1009+l), so it varies day to day. At most [max].
/// [temQuiz] is expensive (it runs gerarQuiz): it is called only while walking the already sorted
/// candidates, stopping as soon as [max] are found.
List<(int, int)> escolherQuizes({
  required List<(int, int)> concluidas,      // (t,l) of completed lessons, built by walking trilhas/lições
                                             // with st.licaoConcluida(t,l) — never by parsing `concluidas`
                                             // (it also holds 'proj:', 'master:', 'desafio:' entries)
  required int? Function(int t, int l) nota, // (t,l) => st.quizNotas[st.chave(t,l)]
  required bool Function(int t, int l) temQuiz, // (t,l) => temQuiz(st, t, l)
  required int dia,
  int max = LimitesTreino.quizes,
});
```

**`montarPlano` rules:**

| Course | Rule | Block |
|---|---|---|
| English | `frasesDevidas + cartoes > 0` | `revisao`, with `qtd = min(8, frasesDevidas)`, `qtd2 = min(4, cartoes)`, `minutos = max(1, ((qtd*25 + qtd2*10)/60).ceil())` |
| English | `teimosas + palavrasDevidas + palavrasFracas > 0` | `palavras`, `qtd = min(6, the first non-zero source in that order)`, `minutos 2` |
| English | `temOuvir` | `ouvir`, `qtd 6`, `minutos 1` |
| English | always | `rali`, `minutos 2` |
| Dart/C# | each of `quizes.take(2)` | `quiz:t:l`, `qtd 10`, `minutos 4` |
| Dart/C# | always | `rali`, `minutos 2` |

`curto = !blocos.any((b) => b.tipo is revisao|palavras|quiz)`.

## 6. Persistence, cubit and wiring

### 6.1 Repository: `lib/features/treino_dia/data/treino_dia_repository.dart` (copy of `habito_repository.dart`)

```dart
abstract interface class TreinoDiaRepository {
  Future<PlanoTreino?> carregar();       // never throws; bad data → null
  Future<void> salvar(PlanoTreino p);    // local never throws; Firestore may (the cubit swallows)
}
class LocalTreinoDiaRepository implements TreinoDiaRepository {
  static const chaveBase = 'treino_dia_v1';
  LocalTreinoDiaRepository({this.uid, required this.curso});
  final String? uid; final String curso;
  String get chave => uid == null ? '$chaveBase:$curso' : '$chaveBase:$uid:$curso';
}
class MemoriaTreinoDiaRepository implements TreinoDiaRepository { MemoriaTreinoDiaRepository([PlanoTreino? inicial]); int gravacoes = 0; }
class FirestoreTreinoDiaRepository implements TreinoDiaRepository {
  FirestoreTreinoDiaRepository(this.uid, {required this.linguagem, FirebaseFirestore? db, TreinoDiaRepository? local});
  // field: '${linguagem.prefixoProgresso}treino_dia' in users/{uid}  → 'treino_dia' | 'cs_treino_dia' | 'en_treino_dia'
  // carregar: local, then remote; PlanoTreino.mesclar; sync both sides like FirestoreHabitoRepository
  // salvar: local first, then _doc.set({campo: p.toJson()}, SetOptions(mergeFields: [campo]))
}
```

**Why `mergeFields` and not `merge: true`:** `merge: true` merges nested maps key by key (that is what `salvarQuizNota` relies on). If a key were missing from the new plan, yesterday's value would survive inside the field, for example `x:true`, and today's plan would load with `bonus = true` and never grant the bonus. `mergeFields: [campo]` replaces the whole `treino_dia` field and still leaves the other fields of `users/{uid}` alone. As a second guard, `PlanoTreino.toJson` always writes every top-level key. If `FakeFirebaseFirestore` turns out not to honour `mergeFields`, use `_doc.update({campo: ...})` with a `set(..., merge: true)` fallback when the doc does not exist yet.

**Firestore rule:** no change. The field lives in `users/{uid}`, which `match /users/{uid}` already covers. Account deletion removes the doc, and the treino goes with it. There is nothing to deploy.

### 6.2 Cubit: `lib/features/treino_dia/presentation/treino_dia_cubit.dart`

```dart
class TreinoDiaState extends Equatable { final bool carregado; final PlanoTreino? plano; const TreinoDiaState({this.carregado = false, this.plano}); }

class TreinoDiaCubit extends Cubit<TreinoDiaState> {
  TreinoDiaCubit({required TreinoDiaRepository repo, required String curso, DateTime Function()? agora});
  static TreinoDiaCubit? de(BuildContext c);            // null-safe like HabitoCubit.de
  final DateTime Function() agora;
  int get hoje => diaDe(agora());
  Future<void> carregar();                              // memoized; called by the constructor
  PlanoTreino? get planoDeHoje;                         // state.plano if dia == hoje, else null
  SituacaoTreino get situacao;                          // planoDeHoje?.situacao ?? pendente  (cheap: HUD calls it every second)
  /// Today's plan; creates it with [montar] when missing (or from another day), persists it.
  /// The ONLY method that changes the plan's day. assert(state.carregado): calling it before
  /// carregar() completes is a bug (the page always awaits carregar first, §9.1).
  PlanoTreino iniciar(PlanoTreino Function() montar);
  /// Replaces today's plan with an upgraded one (completarPlano). No-op if it is not today's plan.
  void completar(PlanoTreino Function(PlanoTreino atual) upgrade);
  void marcar(String id, EstadoBloco e, {int? resultado, int? total, bool vazio = false});
  void anotarOuvir(Iterable<String> chaves);
  void anotarFoco(Iterable<String> ens);
  /// Concluded and merecebonus: sets bonus=true, persists, returns true. The caller then calls
  /// HabitoCubit.ganharBonusTreino(bonusTreino), which applies the once-per-account-per-day guard.
  bool tomarBonus();
  @visibleForTesting Future<void> get gravacoes;        // completes when the save queue is empty
}
```
- **Offline-first,** like `HabitoCubit`:
  - every change emits immediately and saves serialized "latest wins";
  - `marcar`/`anotar*`/`tomarBonus` before `carregar` finishes are not expected (the page awaits it); if one happens anyway it is applied to the loaded plan only when that plan has the same `dia`, otherwise dropped;
  - errors are swallowed.
- **Midnight:** there is no "ignore other days" rule. `marcar`, `anotarOuvir`, `anotarFoco` and `tomarBonus` always act on `state.plano`, whatever its `dia`, so a session that crosses midnight finishes on its own plan. `iniciar` is the only method that switches to a new day, and the page does not call it again while open. The HUD keeps using `planoDeHoje` (null after midnight → "Treino").

### 6.3 Wiring in `lib/main.dart`
- **New `PacDartApp` parameter:** `final TreinoDiaRepository Function(AppUser user, Linguagem linguagem)? treinoDiaBuilder;`.
- **In `_cursoDe`** (per course, keyed `uid:linguagem`; for all 3 courses):
  ```dart
  BlocProvider(
    create: (_) => TreinoDiaCubit(
      repo: treinoDiaBuilder?.call(user, linguagem) ??
          (Firebase.apps.isNotEmpty
              ? FirestoreTreinoDiaRepository(user.uid, linguagem: linguagem)
              : LocalTreinoDiaRepository(uid: user.uid, curso: linguagem.id)),
      curso: linguagem.id,
      agora: habitoAgora,   // same day semantics as the streak; tests turn one clock
    ),
  ),
  ```
- **`lib/main_portfolio_probe.dart`:** `treinoDiaBuilder: (u, l) => LocalTreinoDiaRepository(uid: u.uid, curso: l.id)`.

### 6.4 Composition and launchers: `lib/features/treino_dia/presentation/blocos_treino.dart`

```dart
/// Reads the sources (English: RevisaoCubit.carregado, PalavrasCubit.carregar(), then
/// prepararIndice(trilhas); Dart/C#: CursoBloc progress). Never throws. A missing cubit counts as 0
/// (and is NOT incompleta). With [ate] set, it stops waiting at that deadline and returns what it has,
/// with incompleta = true if any present source had not loaded. Without [ate] it waits until all load.
Future<FontesTreino> lerFontes(BuildContext c, {Duration? ate});
/// The page (§9.1) races lerFontes(c) against an 8 s timer to show "Está demorando um pouco…";
/// "Começar assim mesmo" calls lerFontes(c, ate: Duration.zero) → incompleta → plan.incompleto.

/// Launches block [b] and returns how it ended. The plan is updated by the page, not here.
sealed class FimDoBloco {}
class BlocoFeito extends FimDoBloco { final int resultado; final int total; final List<String> chavesOuvir; final List<String> foco; }
class BlocoVazio extends FimDoBloco { final String aviso; }   // nothing to do when it started → feito with 0, vazio: true
class BlocoInterrompido extends FimDoBloco {}                 // left in the middle → stays pendente

Future<FimDoBloco> rodarRevisao(BuildContext c);                 // abrirRevisao(limiteFrases: 8, limiteCartoes: 4, modoTreino: true)
Future<FimDoBloco> rodarPalavras(BuildContext c);                // teimosas > devidas > fracas (max 6), modoTreino
Future<FimDoBloco> rodarRali(BuildContext c, PlanoTreino p);     // focar(p.palavrasFoco) in English; RaliPage(treino: true)
Future<FimDoBloco> rodarQuiz(BuildContext c, BlocoTreino b, int dia);

/// The Ouvir excerpt, at most [max] PHRASES (faixas): ouvirChaves (one daFrase item each) → last completed
/// lesson (ONE doTrecho item holding ≤ max trechos) → current lesson. Empty outside English.
/// The number of items is NOT the target: the panel uses ouvir.state.fila.length after tocarItens.
List<ItemSetlist> trechoParaOuvir(CursoState st, PlanoTreino p, {int max = LimitesTreino.ouvir});

/// Pure helper for the English words block (testable without widgets). Each source is filtered to
/// trainable words (en and pt non-empty) BEFORE choosing; null when nothing trainable is left
/// (→ BlocoVazio, never a launcher that returns null).
enum OrigemPalavras { teimosas, devidas, fracas }
(OrigemPalavras, List<String>)? escolherPalavras(PalavrasCubit c, CursoState st, {int max = LimitesTreino.palavras});
```
The Ouvir block is not a launcher. It runs inside the page (`PainelOuvirTreino`, §7.2), because it is passive and finishes by observing `OuvirCubit`.

`abrirTreinoDoDia(BuildContext c)` lives in `lib/features/treino_dia/presentation/treino_dia_acoes.dart`. It is a no-op without `TreinoDiaCubit` and otherwise pushes `TreinoDiaPage`.

## 7. Seams added to existing code (backwards-compatible)

### 7.1 English (Group B)
- **`fixacao.dart`:**
  ```dart
  class ItensRevisao { final List<Trecho> diretas, invertidas, novas; bool get vazio; int get total; const ItensRevisao(...); }
  /// The selection of abrirRevisao, pure (except reading the cubit state). invertidas = due first, then new
  /// ones within the quota; with [limiteCartoes], [novas] is only the new ones that fit.
  ItensRevisao itensDaRevisao(RevisaoCubit revisao, List<Trilha> trilhas, {String? baralho, int? limiteFrases, int? limiteCartoes});

  class FimDaRevisao { final int respondidas; final bool terminou; final List<Trecho> revisadas; const FimDaRevisao(...); }
  Future<FimDaRevisao> abrirRevisao(BuildContext context,
      {String? baralho, int? limiteFrases, int? limiteCartoes, bool modoTreino = false});
  ```
  - `abrirRevisao` uses `itensDaRevisao`. Without the new parameters the behaviour is identical: the empty page still opens and the same titles appear.
  - `modoTreino`:
    - nothing to review → return `FimDaRevisao(0, terminou: true, [])` without pushing;
    - passes `semOferta: true` to both pages;
    - memória `emSequencia` = `invertidas.isNotEmpty`, as today.
  - `terminou = (diretas.isEmpty || memóriaOnFim) && (invertidas.isEmpty || cartõesOnFim)`.
  - `revisadas` = the trechos received in `onResultado` (memória) plus `onNota` (cartões), in order.
  - Existing callers (`hud.dart:127`, `palco_ingles.dart`, `baralhos_page.dart:64`) compile unchanged, because `Future<FimDaRevisao>` is a `Future<void>`.
- **`sessao_memoria_page.dart` and `sessao_cartoes_page.dart`:** a new `final bool semOferta; // = false`.
  - In `_gravarTeimosas`: `if (!fim || widget.semOferta) return;` (cartões: `|| _ofertaRecente || widget.semOferta`).
  - The evidence is still written. The summary still lists `ListaTeimosas(palavras: tropecos)`, with `onTreinar`/`onJogar` null because `_sug` is null. No quota is spent.
- **`treino_palavras_page.dart`:** two new fields.
  - `final bool semSaidas; // = false`: `onJogar: null`, `onLicao: null`.
  - `final String? rotuloContinuar`: passed **only** to the `ResumoTreino(rotuloContinuar:)` of the final summary (`treino_palavras_page.dart:420`). The step button `Botao3D(key: 'treino-continuar', rotulo: 'CONTINUAR')` (`:475`) and the feedback bar (`barra_feedback.dart:75`) are not touched and keep "CONTINUAR".
- **`treino_palavras.dart`:**
  ```dart
  Future<ResultadoTreino?> abrirTreinoPalavras(BuildContext context, List<PalavraNova> palavras,
      {String? titulo, String? chaveConclusao, bool jaNoArcade = false, VozIngles? voz,
       bool revanche = false, bool antesDaLicao = false, bool modoTreino = false});
  ```
  - It returns `r`, or null on the empty list or null pop.
  - `modoTreino` → `semSaidas: true`, `rotuloContinuar: 'CONTINUAR O TREINO →'`, and it never runs the `r.licao` / `r.jogar` branches.
  - Registration and `habito.praticou(r.passos)` are unchanged.
- **`acoes_teimosas.dart`:**
  ```dart
  Future<ResultadoTreino?> treinarTeimosas(BuildContext context, List<String> chaves,
      {String origem = '', VozIngles? voz, bool modoTreino = false});
  ```
  `modoTreino` skips `cubit.aceitar()`, because it is not a response to an offer, and forwards the flag and the result.

### 7.2 Arcade and quiz (Group C)
- **`rali_page.dart`:**
  ```dart
  class ResultadoFaseTreino { final bool venceu; final int pontos; final int palavras; const ResultadoFaseTreino(...); }
  const RaliPage({super.key, this.semente, this.treino = false});
  final bool treino;   // "⚡ Treino do dia": starts by itself on Fácil, ONE phase, no teimosas offer, pops ResultadoFaseTreino
  ```
  - `initState`: `if (widget.treino) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) _comecarRun(Dificuldade.facil); });` (it needs `context` for `BancoArcade.vocabulario`).
  - `build`: when `widget.treino && _engine == null`, show a short placeholder ("Preparando a fase…") instead of the start screen and `SeletorDificuldade`.
  - `_venceuFase`:
    - `_oferecerEntreFases()` only when `!widget.treino`;
    - after `registrarFaseVencida()`, when `widget.treino`, call `_fimDeJogo(somaFaseAtual: false)`. `encerrar` clears `faseVencida`, so the `FaseVencida` overlay never stays.
  - `_fimDeJogo`: `_oferecerFim()` only when `!widget.treino`.
  - **`FimDeJogo` in treino:**
    - `titulo: fasesVencidas > 0 ? 'FASE VENCIDA! ⚡' : 'A CPU VENCEU…'`;
    - `subtitulo: 'Fase relâmpago do treino: $_palavrasRun palavras.'`;
    - `mostrarDeNovo: false`, `rotuloSair: 'Continuar o treino →'` (with `mostrarDeNovo: false`, `FimDeJogo` draws the sair button as the primary FilledButton);
    - `onSair: () => Navigator.of(context).pop(ResultadoFaseTreino(venceu: fasesVencidas > 0, pontos: pontosTotal, palavras: _palavrasRun))`.
  - **Pause overlay `onSair`:** `pop()` (null). Unchanged.
  - The route is pushed as `MaterialPageRoute<ResultadoFaseTreino>`. Existing pushes of `const RaliPage()` are unaffected.
- **`widgets/arcade_ui.dart` (`FimDeJogo`):** new optional `bool mostrarDeNovo = true`, `String rotuloDeNovo = 'Jogar de novo'`, `String rotuloSair = 'Voltar ao Arcade'`. When `mostrarDeNovo` is false, the sair action is drawn as the brand `FilledButton` (the primary style the "Jogar de novo" button had), not as the `OutlinedButton`. The defaults give identical output.
- **`curso/presentation/pages/quiz_page.dart`:** new optional fields.
  - `final int? semente;`: `seed: widget.semente ?? sementeQuiz(t, l)`.
  - `final void Function(int acertos, int total)? onTerminou;`: called in `_proxima()` right where `QuizFinalizado` is dispatched (only on a real finish, never on "Pular quiz" or back). A `bool _avisouFim` in the State makes it fire **once per page**: finishing again after "Repetir quiz" (`_reinicia`) does not call it a second time (`QuizFinalizado` still goes out as today, and it only ever raises the best score).
  - `final String? rotuloFim;`: when set, replaces the result's primary button text ("Continuar →" / "Voltar ao mapa"). The treino passes 'Continuar o treino →' with `emSequencia: false`.

### 7.3 Habit (Group A)
- **`lib/features/habito/domain/habito.dart`:** new field `final int? bonusTreinoDia;` (the `diaDe` of the last treino bonus).
  - `toJson` key `bt` (omitted when null); `fromJson` tolerant; `copyWith`.
  - `Habito.mesclar`: `bonusTreinoDia` = the max of both sides, so a bonus taken on another device blocks this one after sync.
- **`lib/features/habito/presentation/habito_cubit.dart`:**
  ```dart
  /// Treino do dia bonus: at most once per account per local day. Returns false (and adds nothing)
  /// when bonusTreinoDia == today; otherwise sets it and calls praticou(n) in the same emit/save.
  bool ganharBonusTreino(int n);
  ```
- The field lives inside the existing `habito` map in `users/{uid}`. No rules change. The habit repo writes with `merge: true` (deep), so an older `bt` can survive a write that omits it; that is harmless here because `bonusTreinoDia` only ever grows and `mesclar` takes the max.

## 8. Edge cases

| Case | Behaviour |
|---|---|
| New English user (nothing studied) | Plan = ouvir (current lesson preview) + rali (fixed English lists, since the vocabulary has no words yet), `curto` hint. **No bonus** (`curto`). The completion screen leads with "✍️ Continuar minha lição" |
| New Dart/C# user | Plan = rali only, `curto` hint. **No bonus**, even if the Rali phase is played (won or lost). The completion screen leads to the lesson |
| A block source empties before it starts | `BlocoVazio` → feito with 0, `vazio: true`, and the banner (§3.4). It does not count toward the bonus |
| English: revisão and palavras done elsewhere first (both `vazio`), then ouvir/rali skipped or played | Concluded, but no active block with a real result → **no bonus** |
| English: only ouvir + rali done, revisão and palavras skipped | **No bonus** (no active block feito) |
| Bonus already taken today in another course | `tomarBonus` marks the plan, `ganharBonusTreino` returns false; the completion screen says "Bônus do treino já ganho hoje ✓" |
| Words with no translation (`pt` empty) are the only teimosas/devidas | Filtered out before choosing; if nothing trainable is left the block is `BlocoVazio`, never stuck in pendente |
| Slow first open (cold Firestore + dictionary asset) | `carregar()` is awaited first; then the spinner waits for the sources. After 8 s: "Tentar de novo" / "Começar assim mesmo". A plan composed early is `incompleto`, gets the missing active blocks on reopen/next block (`completarPlano`) while no active block is resolved, and never earns the bonus while still `incompleto` |
| HUD tapped right at app start (plan of today not loaded yet, maybe with progress from another device) | The page awaits `carregar()` before testing `planoDeHoje`, so it resumes 2/4 instead of overwriting it |
| Teimosas appear during the treino (revisão errors) | The palavras block is chosen when it starts, so it picks them up when they cross the threshold |
| Words trained earlier today (`naoSugerirAte`) | `teimosas()` already excludes them; the fallback goes to devidas/fracas |
| User leaves mid-block | Revisão: per-item progress is already saved, and the resume recomputes the due items (idempotent). Palavras: a null pop → pendente. Rali: a null pop → pendente, and the partial points still go to the ranking (existing `dispose`). Quiz: no `onTerminou` → pendente; answers already counted toward the habit |
| Ouvir with `repetirTudo` saved | Ends on `ouvidas >= alvo` (`alvo = fila.length`), then `fechar()` |
| Ouvir blocked (`semSom`) or cut by another voice | Banner with ▶ and "Pular" |
| Student was listening to the course | "Começar" pauses a `tocando` player (`pausar()` saves the position). The Ouvir block calls `fechar()` on a non-avulso session before `tocarItens` |
| Midnight during a session | The cubit keeps mutating `state.plano` (yesterday's), so the page finishes it; only `iniciar` switches day. Habit units and the bonus use `agora()`, so they land on the new day, as everywhere else (the bonus then also uses up the new day's single bonus). The HUD at 00:00 shows "Treino" pending for the new day |
| Two devices on the same day | `mesclar` on load. `plano.bonus` is OR-merged and `Habito.bonusTreinoDia` takes the max, so after a sync the bonus is not granted again. If both devices conclude while offline, it can still be granted twice. Accepted, small |
| Leaving the page during the Ouvir block | The player keeps going (it is global). On reopen the panel attaches to the running treino session instead of restarting it; if the queue already ended (`acabou`), the block is marked feito |
| Course switch | The cubit is per `uid:linguagem`; each course keeps its own plan and field |
| Plan from an older app version / corrupt JSON | `fromJson` → null → a fresh plan |
| Map/HUD in a test without `TreinoDiaCubit` | `TreinoDiaCubit.de` → null, so no button and no card (old tests unchanged) |
| HUD wrapping | The button adds about 110 px to the Wrap in **every** course, so it changes the layout of **every** test that mounts `PacDartApp` (15 files today, e.g. `ingles_ouvir_app_test` taps `ouvir-hud`, `ingles_palavras_app_test`, `ia_*_app_test`, `ingles_leitura_app_test`, `app_smoke_test` at 800×600 taps 'Mapa', `habito_ui_test` at 360/390/1027). At 800×600 pills wrap to a new line and taps on 'Revisão · n', `ouvir-hud` or 'Mapa' can land off-screen. Group E runs and fixes all of them (pumps, `ensureVisible`), §9/§12 |

## 9. Files and groups (disjoint ownership)

**Phase 0 (lead, about 20 minutes):** commit skeletons with the exact signatures from §5–§7. Bodies are `throw UnimplementedError()` or pass-through. Each owner then fills in its files.

| Group | New files | Modified files |
|---|---|---|
| **A: domain, persistence, cubit** | `lib/features/treino_dia/domain/plano_treino.dart`, `lib/features/treino_dia/domain/montar_plano.dart`, `lib/features/treino_dia/data/treino_dia_repository.dart`, `lib/features/treino_dia/presentation/treino_dia_cubit.dart`, `test/treino_dia_test.dart`, `test/treino_dia_repository_test.dart`, `test/treino_dia_cubit_test.dart` | `lib/features/habito/domain/habito.dart` (`bonusTreinoDia`), `lib/features/habito/presentation/habito_cubit.dart` (`ganharBonusTreino`), plus new cases appended to the existing `test/habito_test.dart` (JSON `bt`, `mesclar` max) and `test/habito_cubit_test.dart` (`ganharBonusTreino`) |
| **B: English seams** | `test/treino_dia_seams_ingles_test.dart` | `lib/features/ingles/presentation/fixacao.dart`, `sessao_memoria_page.dart`, `sessao_cartoes_page.dart`, `treino_palavras.dart`, `treino_palavras_page.dart`, `acoes_teimosas.dart` |
| **C: arcade and quiz seams** | `test/rali_treino_test.dart`, `test/quiz_treino_test.dart` | `lib/features/arcade/presentation/rali_page.dart`, `lib/features/arcade/presentation/widgets/arcade_ui.dart` (`FimDeJogo` only), `lib/features/curso/presentation/pages/quiz_page.dart` |
| **D: treino screens** | `lib/features/treino_dia/presentation/blocos_treino.dart`, `lib/features/treino_dia/presentation/treino_dia_page.dart`, `lib/features/treino_dia/presentation/treino_dia_acoes.dart`, `lib/features/treino_dia/presentation/widgets/painel_ouvir_treino.dart`, `lib/features/treino_dia/presentation/widgets/cartao_bloco.dart`, `test/treino_dia_blocos_test.dart`, `test/treino_dia_ui_test.dart` | none |
| **E: wiring and docs** | `test/treino_dia_app_test.dart`, `planejamento/FASE-9-TREINO-DO-DIA.md` (a copy of this plan; the lead renumbers if needed) | `lib/main.dart`, `lib/main_portfolio_probe.dart`, `lib/features/curso/presentation/widgets/hud.dart`, `lib/features/curso/presentation/pages/mapa_page.dart` (`_CartaoTreinoDia` + 1 sliver), **every** `test/*` that mounts `PacDartApp` and breaks because of the extra HUD pill (list them with `grep -l PacDartApp test/`; 15 files today, among them `app_smoke_test`, `habito_ui_test`, `ingles_ouvir_app_test`, `ingles_palavras_app_test`, `ingles_leitura_app_test`, `ia_*_app_test`): extra pumps / `ensureVisible` only, no behaviour change; `ESTADO-DO-PROJETO.md` |

D imports A, B and C through the Phase 0 signatures. E imports A and D (`abrirTreinoDoDia`, `TreinoDiaCubit`). **Group E time budget:** reserve a real slot for the `PacDartApp` test sweep (run all 15, fix taps that fall off-screen at 800×600); it is not a 2-file check.

**`hud.dart` edit (E):** right after `ChipSequencia()`:
```dart
if (TreinoDiaCubit.de(context) != null)
  BlocBuilder<TreinoDiaCubit, TreinoDiaState>(
    builder: (context, _) {
      final c = context.read<TreinoDiaCubit>();
      final p = c.planoDeHoje;               // recomputed every HUD tick → day rollover for free
      final s = c.situacao;
      return _Toggle(
        key: const Key('treino-dia-hud'),
        rotulo: switch (s) {
          SituacaoTreino.pendente => 'Treino',
          SituacaoTreino.emAndamento => 'Treino ${p!.resolvidos}/${p.blocos.length}',
          SituacaoTreino.concluido => 'Treino ✓',
        },
        icone: Icons.bolt_rounded,
        ligado: s != SituacaoTreino.concluido,
        onTap: () => abrirTreinoDoDia(context),
      );
    },
  ),
```

### 9.1 `TreinoDiaPage` internals (D)
- `StatefulWidget`. In `initState` it captures `TreinoDiaCubit`, `HabitoCubit`, `OuvirCubit?` and `CursoBloc`. Then `_preparar()`:
  1. Spinner "Montando seu treino…" (`treino-dia-montando`). `await cubit.carregar()` first, with a 10 s timeout. On timeout it continues with the local plan only (the repo's local read never hangs); this is the only way `iniciar` can run, so `iniciar` before load cannot happen (it asserts `state.carregado`).
  2. **Today's plan exists** → resume it (e.g. 2/4). If it is `incompleto` or `curto` and `!algumAtivoResolvido`, re-read the sources in the background (`lerFontes(context)`) and `cubit.completar((p) => completarPlano(p, fontes, ...))`.
  3. **No plan today** → race `lerFontes(context)` against an 8 s timer. Done in time → `cubit.iniciar(() => montarPlano(fontes, dia: cubit.hoje, curso: ..., agoraMs: ...))`. At 8 s → show "Está demorando um pouco…" with "Tentar de novo" (restart the wait) and "Começar assim mesmo" (`lerFontes(context, ate: Duration.zero)` → `montarPlano` → plan `incompleto`). If the full read finishes while the buttons are showing, it proceeds normally.
  - The page does not keep a separate `_dia`: the cubit acts on `state.plano` (§6.2, midnight).
- **`_rodarProximo()`:**
  - if the next block is `ouvir`, it sets `_ouvindo = true` (panel);
  - before launching an active block of an `incompleto` plan with no active block resolved, it runs the same `completar` step as in `_preparar` (so the newly found revisão/palavras run first);
  - otherwise it awaits `rodarX` and maps `FimDoBloco`:
    - `BlocoFeito` → `marcar(feito, resultado,total)`, plus `anotarOuvir`/`anotarFoco`;
    - `BlocoVazio` → `marcar(feito, 0, vazio: true)` plus a banner;
    - `BlocoInterrompido` → nothing.
  - Then, if `plano.concluido && cubit.tomarBonus()` → `_bonusGanho = habito?.ganharBonusTreino(bonusTreino) ?? false` (drives the completion-screen line, §3.5).
- **`PainelOuvirTreino({required OuvirCubit ouvir, required void Function(int ouvidas) aoTerminar, required void Function(int ouvidas) aoParar, required VoidCallback aoPular})`:**
  - `initState`: `ouvir.telaCheia(true)` (hides the mini-player); `dispose`: `telaCheia(false)`. `dispose` never calls `fechar` (only the page does, on finish or skip).
  - `alvo` is not a parameter: it is `state.fila.length` of the treino session (read after `tocarItens`, or from the running session when attaching).
  - a `BlocBuilder<OuvirCubit, OuvirState>` for the phrase/counter ("Frase {indice+1} de {fila.length}");
  - `BlocListener` #1 (finish): `listenWhen: (a, b) => b.fonte?.titulo == tituloOuvirTreino && (b.status == StatusOuvir.acabou || b.ouvidas >= b.fila.length)` → `aoTerminar(b.ouvidas)` once (flag);
  - `BlocListener` #2 (stopped from outside): `listenWhen: (a, b) => a.fonte?.titulo == tituloOuvirTreino && b.status == StatusOuvir.parado && !_fechandoEu` → `aoParar(a.ouvidas)` (the **previous** state; `fechar()` zeroes `ouvidas`/`fonte` in the same emit). The panel also stores `_ultimasOuvidas` while the treino source is active, as a fallback;
  - the page: `aoParar(k)` → feito if `k >= ceil(alvo/2)`, else back to pendente ("▶ Ouvir de novo").
- **Accessibility:**
  - `Mixart.*` tokens only (getters, never `const`);
  - targets ≥ 48 px;
  - `Semantics` on the segmented bar: "Etapa {i} de {n}: {título}, {estado}";
  - "Pular esta etapa" is a real `TextButton`.

## 10. Test keys

All new keys use the prefix `treino-dia-`, because `treino-fechar`, `treino-ouvir` and `treino-continuar` already exist in the word-training pages, which the Palavras block stacks on top of `TreinoDiaPage`:

`treino-dia-hud`, `treino-dia-cartao-mapa`, `treino-dia-pagina`, `treino-dia-montando`, `treino-dia-tentar`, `treino-dia-comecar-assim`, `treino-dia-progresso`, `treino-dia-bloco-<id>`, `treino-dia-comecar`, `treino-dia-pular`, `treino-dia-ouvir`, `treino-dia-ouvir-play`, `treino-dia-ouvir-pular`, `treino-dia-fim`, `treino-dia-ir-licao`, `treino-dia-fechar`.

Existing keys are left as they are (`treino-continuar`, `treino-fechar`, `treino-ouvir` keep their meaning inside `TreinoPalavrasPage`).

## 11. Tests

Conventions:
- `SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false})`;
- `Mixart.usarGoogleFonts = false`;
- `FraseView.carencia = Duration.zero`;
- `tearDown(() => Linguagem.atual = Linguagem.dart)`;
- use `_anda` / `runAsync` loops instead of `pumpAndSettle` in app tests (the HUD timer never settles);
- check 360, 390 and 1400 px in light and dark.

**A**
- `treino_dia_test`:
  - `montarPlano` tables:
    - full English → 4 blocks in order with the limits;
    - only reverse cards → `revisao` with `qtd 0, qtd2 n`;
    - no teimosas but due words → `palavras`;
    - new English user → `[ouvir, rali]`, `curto`;
    - Dart with 3 candidates → `[quiz, quiz, rali]`;
    - Dart new → `[rali]`, `curto`;
    - no `temOuvir` → no `ouvir`.
    - `incompleta` sources → plan `incompleto`;
    - `completarPlano`: an `incompleto` `[ouvir, rali]` + sources with due phrases → `[revisao, ouvir, rali]`, `curto` false, `incompleto` cleared; unchanged once an active block is resolved; resolved passive blocks keep their estado.
  - `escolherQuizes`: never-quizzed first, then the lowest score; the rotation changes with `dia`; respects `temQuiz` and `max`; `temQuiz` is called only until `max` candidates are found (count the calls with a fake); `nota` is looked up per (t,l), never by parsing keys.
  - `marcar` / `proximo` / `situacao` / `concluido`.
  - `merecebonus`:
    - all skipped → false; already `bonus` → false;
    - English 2 of 4 with revisão feito (resultado 3) → true;
    - **(a)** Dart new, plan `[rali]`, rali feito (lost phase) → false (`curto`);
    - **(b)** English: revisão and palavras `vazio`, ouvir and rali skipped → false;
    - **(c)** English: ouvir + rali feito, revisão and palavras skipped → false;
    - active block feito with `resultado 0` → false;
    - `incompleto` → false;
    - Dart `[quiz, quiz, rali]` with one quiz feito (7/10) and the rali feito → true.
  - `anotarOuvir` / `anotarFoco` dedupe and caps.
  - JSON round-trip: block defaults omitted, **every top-level key always present** (`k`, `p`, `x` written as false); `vazio` (`z`) round-trips; garbage, `v:2` and an unknown tipo are tolerated.
  - `mesclar`: commutative, newer dia wins, same-day block union (feito beats pulado beats pendente, `vazio` follows the winner), bonus OR, `incompleto` AND, null sides.
- `treino_dia_repository_test`:
  - Local round-trip per uid+curso (two courses and two uids don't mix); corrupt pref → null; Memoria.
  - Firestore through `FakeFirebaseFirestore`:
    - writes `en_treino_dia` / `cs_treino_dia` / `treino_dia`;
    - **does not clobber** `habito`, `concluidas` or `en_concluidas`;
    - device and cloud merge on load;
    - **no stale keys:** save a plan with `bonus=true` (and `curto=true`) for day D, then a plan with `bonus=false`, `curto=false` for day D+1; re-read (fresh repo, cloud only) → `bonus == false`, `curto == false`;
    - offline subclass (copy `_FirestoreSemRede` from `habito_repository_test`) → local.
- `treino_dia_cubit_test`:
  - loads; `iniciar` creates once per day and returns the same plan on a second call;
  - an injected clock turning midnight → `planoDeHoje == null`, `situacao == pendente`, and `iniciar` makes a new plan;
  - `marcar` persists (`gravacoes`);
  - `iniciar` before `carregar` completes → assert (debug);
  - slow load (repo whose `carregar` waits on a `Completer`) holding today's plan at 2/4: the cubit does not expose a plan until it completes, and then `planoDeHoje.resolvidos == 2`;
  - midnight: after the clock turns, `marcar` on yesterday's plan still applies (no "ignore other days" rule) and `iniciar` makes today's plan;
  - `completar` replaces today's plan and persists;
  - `tomarBonus` is true once and then false, and a reload with `bonus` set stays false.
- `habito_test` (new cases): `bonusTreinoDia` JSON `bt` round-trip and absent → null; `mesclar` takes the max.
- `habito_cubit_test` (new cases): `ganharBonusTreino(3)` → true and +3; again the same day → false, +0; next day → true; survives a reload (`LocalHabitoRepository`).

**B: `treino_dia_seams_ingles_test`**
- `itensDaRevisao`:
  - 12 due direct → 8 with `limiteFrases: 8`;
  - reverse due + new → due first and capped at 4, with `novas` only the ones that fit;
  - `baralho` filter;
  - with no limits it equals the old selection.
- `abrirRevisao(modoTreino: true)` with nothing due → no route pushed, `terminou: true`.
- With 3 due phrases → memória page; finishing → `FimDaRevisao(respondidas: 3, terminou: true, revisadas: 3)`; habit +3.
- Leaving with X before the end → `terminou: false`.
- `semOferta`: a session with tropeços shows the `ListaTeimosas` words but no "Treinar"/"Jogar" buttons, and `EstadoSugestao` is unchanged (no `marcarMostrada`). The same for cartões.
- `abrirTreinoPalavras(modoTreino: true)`: the summary has no '🎮 Jogar' and no '📝 Virar lição', the summary's main button is 'CONTINUAR O TREINO →', it returns a non-null `ResultadoTreino`, and nothing is pushed afterwards (no ArcadePage).
- In that same session, the per-step button `treino-continuar` and the feedback bar still read 'CONTINUAR' (only the summary label changes).
- Default calls are unchanged: Jogar is still offered.
- `treinarTeimosas(modoTreino: true)` returns the result and doesn't call `aceitar` (the sugestão state is unchanged).

**C**
- `rali_treino_test` (mirror `rali_fases_ingles_test`: `_Mudo`, `_Teclado`, `ContagemRegressiva.duracao`):
  - `RaliPage(treino: true)` shows no 'Escolha o rival:' and the countdown starts by itself;
  - typing the whole deck → no 'FASE 1 CONCLUÍDA!' overlay left, `FimDeJogo` with 'FASE VENCIDA! ⚡' and 'Continuar o treino →' **as a `FilledButton`**, no 'Jogar de novo';
  - `FimDeJogo()` defaults still render 'Jogar de novo' (FilledButton) + 'Voltar ao Arcade' (OutlinedButton);
  - tapping it pops `ResultadoFaseTreino(venceu: true, pontos > 0)`;
  - the CPU wins → `venceu: false`;
  - pausa → Sair pops null;
  - English: no teimosas offer even with tropeços;
  - Dart variant (fixed list) works;
  - `RaliPage()` default still shows the start screen.
- `quiz_treino_test`:
  - `onTerminou(acertos, total)` is called once at the real end, and not on "Pular quiz" or back;
  - finish → "Repetir quiz" → finish again → `onTerminou` still called **once**;
  - with `emSequencia: false` + `rotuloFim: 'Continuar o treino →'`: no "Pular quiz", no "A seguir: …" text, the X tooltip is "Voltar", and the primary button reads 'Continuar o treino →';
  - `semente` changes the question order versus the default;
  - `QuizFinalizado` is still dispatched.

**D**
- `treino_dia_blocos_test`:
  - `escolherPalavras` order: teimosas > devidas > fracas, max 6;
  - `escolherPalavras` with teimosas and devidas that all have an empty `pt` → falls to fracas, or null when nothing trainable is left; `rodarPalavras` then returns `BlocoVazio` (no route pushed);
  - `trechoParaOuvir`: from `ouvirChaves`, else the last completed lesson (one `doTrecho` item that expands to 6 faixas in `filaDosItens`), else the current lesson, and empty in Dart;
  - `lerFontes` with seeded cubits (RepoMemoria SRS due cards, seeded teimosas as in `ingles_teimosas_test`) gives the right counts and waits for the index;
  - `lerFontes`: `palavrasFracas == treinoSemDevidas(...).length` (never-trained `palavrasDoAluno` included); words without `pt` are not counted;
  - `lerFontes(ate: Duration.zero)` with a revisão repo stuck on a `Completer` → `incompleta: true`, revisão counted as 0; without `ate` it waits and returns the real count once the `Completer` completes;
  - `lerFontes` on Dart with `concluidas` (including `proj:`/`master:` entries, which are ignored) + `quizNotas` gives ranked quizzes.
- `treino_dia_ui_test` (providers + `MaterialApp(home: TreinoDiaPage())`, or the `_app` harness):
  - lists the planned blocks and their subtitles;
  - "Começar" opens 'Revisão do dia'; finishing marks `✓ 3 revisadas` and the button becomes "Continuar · 🔥 Palavras";
  - closing the page mid-plan and reopening resumes at the same block;
  - slow `carregar` (Completer) with today's plan at 2/4 → the page shows `treino-dia-montando`, then resumes at 2/4 and never calls `iniciar`;
  - slow sources (revisão repo on a `Completer`): spinner; at 8 s (fake async) "Está demorando um pouco…", "Tentar de novo" and "Começar assim mesmo" appear; "Começar assim mesmo" → plan `incompleto` without `revisao`; complete the `Completer`, reopen → `revisao` inserted at the front;
  - "Pular esta etapa" marks it pulado;
  - the Ouvir panel with a fake `SaidaDeAudio` that finishes each phrase → after `fila.length` phrases the block is feito and `OuvirCubit` is closed;
  - **source "last completed lesson"** (one `doTrecho` item, 6 faixas): the counter reads "Frase 1 de 6", and the block is NOT feito after the 1st phrase;
  - **✕ from outside after 3 of 6 phrases** (`ouvir.fechar()` called by the test) → feito; after 2 of 6 → back to pendente with "▶ Ouvir de novo";
  - while the panel is open `ouvir.state.telaCheia == true` (no mini-player); after closing, false;
  - leave the page mid-Ouvir, reopen → the panel attaches to the running session (no second `tocarItens`: `fila`/`indice` unchanged); if it ended meanwhile, the block is feito on open;
  - the Ouvir panel when the player was playing the course → the course position is saved (`PreferenciasOuvirMemoria`);
  - the Rali block pushes `RaliPage` with `treino == true`;
  - completion screen texts, the bonus applied once (`HabitoCubit` + `LocalHabitoRepository`: +3), and reopening shows `treino-dia-fim`;
  - a plan finished with only passive blocks done → no bonus line and +0;
  - the bonus already taken today (`bonusTreinoDia == hoje`) → "Bônus do treino já ganho hoje ✓", +0;
  - the Palavras block stacked on top: `find.byKey(Key('treino-fechar'))` finds exactly one widget (the word-training page's), and the `treino-dia-*` keys stay unique;
  - `curto` hint;
  - no overflow at 360/390/1400 in light and dark.

**E: `treino_dia_app_test`** (full `PacDartApp`, harness from `habito_app_test` + `ingles_ouvir_app_test`; `treinoDiaBuilder: (u, l) => LocalTreinoDiaRepository(uid: u.uid, curso: l.id)`, `habitoAgora: relogio`):
1. English: the HUD shows `treino-dia-hud` "Treino"; tap → page; skip all blocks → `treino-dia-fim`, and the HUD shows "Treino ✓".
2. Advance the clock past midnight and tick → the HUD shows "Treino" again.
3. Dart app: the `treino-dia-hud` plan has a `rali` block, and there is no Ouvir.
4. Switching course keeps each course's state.
5. The map card `treino-dia-cartao-mapa` exists in English and Dart.
6. Bonus once per account: finish a qualifying treino in English (+3), switch to Dart and finish a qualifying one → +0 and "Bônus do treino já ganho hoje ✓".
7. **Every** `PacDartApp` test still passes (`grep -l PacDartApp test/`, 15 files), fixed in Group E where the new pill moved a tap target.

## 12. Validation (the lead does this)

- Agents write code only. Per the project memory, no `flutter build web` loops.
- The lead runs `~/development/flutter/bin/flutter analyze lib test` and `flutter test`: the new files plus the full suite. The expected failures are the same 5 in `csharp_curriculo_test`.
- Pay special attention to the 15 `PacDartApp` test files (`grep -l PacDartApp test/`): the HUD pill is added in every course, so any of them can break at 800×600 by a tap landing off-screen. Group E owns these fixes; the lead re-runs them as a block before the full suite.
- At most **one** web probe build, in the reused probe folder that is deleted afterwards. Then a Playwright pass at 1027 and 390 px: HUD button states, a run through the plan with skips, completion, and the console free of errors.
- Sweep for stray `test/_*_test.dart` or `*_check.dart` files before analyzing (ESTADO gotcha 16).
- **No `firestore.rules` change and no rules deploy** for this feature.

## 13. Padrões escolhidos (defaults taken without asking)

1. **All 3 courses get the treino.** English has 4 blocks; Dart/C# get 2 review quizzes + 1 Rali phase. The streak is per account, so a Dart/C# student should also get "o que eu faço hoje?".
2. **English order:** Revisão → Palavras → Ouvir → Rali. The most important item comes first, then the teimosas (which may be fed by the revisão errors), a passive breather, and the game as the reward at the end.
3. **Limits:** 8 phrases + 4 cards, 6 words, 6 phrases to hear, 1 Rali phase on Fácil, 2 quizzes. That is about 9–10 min.
4. **No auto-launch between blocks:** one tap "Continuar" each time, and "Pular esta etapa" on every block.
5. **Block contents are chosen when the block starts** (lazy). Only the block list, the quiz lessons, the Ouvir phrases and the words for the Rali focus are persisted.
6. **Habit:** the real exercises count as today; Ouvir and Rali still don't; **+3 units** when the treino is concluded with ≥2 real blocks done, at least one of them an active block (revisão/palavras/quiz) with a real result, and the plan is neither `curto` nor `incompleto` (`bonusTreino`, a single constant). **At most once per account per day** (`Habito.bonusTreinoDia`), whatever the course. It never goes to the ranking.
7. **Persistence:**
   - the local pref `treino_dia_v1:{uid}:{curso}`;
   - plus the field `{prefixo}treino_dia` in `users/{uid}`, written with `SetOptions(mergeFields: [campo])` so the whole field is replaced (no stale nested keys) and the rest of the doc is untouched;
   - no rules change; account deletion already covers it.
8. **Daily reset** uses `diaDe(agora())`, the local date (the same as the streak and the SRS). The clock is `habitoAgora`. A session open across midnight finishes on its own plan: the cubit always acts on `state.plano`, and only `iniciar` switches day.
14. **Slow first open:** the page waits for the saved plan and the sources (no 3 s cut-off). After 8 s it offers "Tentar de novo" / "Começar assim mesmo"; a plan composed early is `incompleto` and gets its missing active blocks later.
15. **Quiz in the treino** runs with `emSequencia: false` and the label 'Continuar o treino →', so no sequence texts leak in.
9. **The Rali** is the only arcade game in the treino. It is the lightest, it has phases, and it works in all three courses. Turismo (WebGL, slow) and Chuva (no natural single phase) are left out.
10. **The Rali focus** (`focar`) on the treino's words persists about 30 min in the Arcade (intended: "continue praticando essas").
11. **Inside the treino, the sessions don't make their own teimosas offers** (`semOferta`, `modoTreino`), so the student stays in the flow and the daily offer quota isn't spent.
12. **The Ouvir excerpt** is the phrases just reviewed; else the last completed lesson; else a preview of the current lesson. The source is `avulso`, so it never moves the course/setlist position.
13. **Entry points:** the HUD button (after the 🔥 chip) and a map card. No notification or reminder changes.

## 14. Deferred (not in this round)

- Reminder text that mentions the treino ("Seu ⚡ Treino do dia está esperando").
- A "treinos seguidos" counter and a weekly calendar of treinos.
- Letting the student choose the length (5 / 10 / 15 min) or reorder or remove block types.
- Chuva or Turismo as alternative game blocks, and remembering the preferred difficulty.
- Dart/C#: real SRS for lessons (needs timestamps in `ProgressoRepository`), "Desafios" as a block, a typing block that replays an old snippet.
- English: a shadowing or ditado block, and leeches (`sanguessugasDe`) passed as `extras` to `teimosas()`.
- Cross-device dedupe of the bonus (server-side) and syncing the in-progress Ouvir block.

## 15. Crítica considerada

Revision 2 accepted **all 15 points** of the review. None was rejected. Where the review offered alternatives, this is the one taken:

| # | Point | Decision |
|---|---|---|
| 1 | Bonus without any exercise; up to +9/day | Accepted. `merecebonus` requires an active block feito, not `vazio`, with `resultado > 0`, plus `!curto` and `!incompleto`. Once per account per day via `Habito.bonusTreinoDia` + `HabitoCubit.ganharBonusTreino` (the habit cubit is already account-scoped, so this is simpler than checking the other courses' plans). Cases (a), (b) and (c) are tests in `treino_dia_test` |
| 2 | Slow sources freeze a poor plan for the whole day | Accepted, combining two of the suggested options: no 3 s cut-off; after 8 s offer "Tentar de novo" / "Começar assim mesmo"; a plan composed early is `incompleto` and `completarPlano` inserts the missing active blocks while none is resolved. Tested with a `Completer` repo |
| 3 | ✕ of the mini-player never counts (`fechar()` zeroes state) | Accepted. `listenWhen` on `a.fonte` + `b.status == parado`, reading `a.ouvidas`; `_ultimasOuvidas` as a fallback |
| 4 | Ouvir target mixes items and faixas | Accepted. `alvo = state.fila.length` after `tocarItens`; "Frase {indice+1} de {fila.length}" |
| 5 | Quiz with `emSequencia: true` shows sequence texts; `onTerminou` twice | Accepted. `emSequencia: false`, plus a new `rotuloFim` (otherwise the button would say "Voltar ao mapa"), and a once-per-page flag for `onTerminou` |
| 6 | Reused keys `treino-fechar` / `treino-ouvir` | Accepted. Every new key is `treino-dia-*` |
| 7 | Deep merge resurrects `x:true` / `k:true` | Accepted. `SetOptions(mergeFields: [campo])` **and** `toJson` always writes every top-level key; stale-key test D → D+1 |
| 8 | `iniciar` before `carregar` overwrites today's plan | Accepted. `_preparar` awaits `carregar()` (10 s timeout, local fallback); `iniciar` asserts `carregado`; test "slow load at 2/4 → resumes 2/4" |
| 9 | Palavras block stuck when words have no `pt`; `palavrasFracas` miscounted | Accepted. Trainable filter before choosing → `BlocoVazio`; `palavrasFracas = treinoSemDevidas(...).length` |
| 10 | The HUD pill changes every `PacDartApp` test | Accepted. Group E owns the sweep of all 15 files, with time reserved for it |
| 11 | Panel and mini-player at once; leaving mid-Ouvir restarts it | Accepted. `telaCheia(true/false)` while the panel is open; reopening attaches to the running treino session, or marks feito if it already ended |
| 12 | `escolherQuizes` / `temQuiz` don't match the code | Accepted. Candidates from `st.licaoConcluida(t,l)` walking trilhas/lições; `nota` via `st.quizNotas[st.chave(t,l)]`; `temQuiz(st,t,l)` called lazily on sorted candidates only |
| 13 | Rali "Continuar o treino →" looks secondary | Accepted. With `mostrarDeNovo: false`, `FimDeJogo` draws sair as the brand FilledButton |
| 14 | `rotuloContinuar` would rename every step button | Accepted. Only the `ResumoTreino` label changes; a test checks the step button still reads "CONTINUAR" |
| 15 | Midnight rule contradicts itself | Accepted (first option). No "ignore other days" rule: the cubit always acts on `state.plano`, and only `iniciar` switches day |

