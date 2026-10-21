# Plan: "🏪 Preparar as lojas" (Google Play and App Store), track 3 of 3

This was read-only. I edited no project file and ran no build. The only command I ran against the toolchain was the scouts' `flutter doctor -v`.

**Sequence.** This track runs **last**, after "Treino do dia" and "Conversa com IA". Every step that depends on those two features says so, and starts by reading what they actually shipped.

**Drafts already written to the scratchpad.** The canonical copy lives here. Builders copy it and do not rewrite it.

- `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/lojas_rascunho/pt-BR/descricao_completa.txt` (2,234 chars)
- `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/lojas_rascunho/en-US/descricao_completa.txt` (2,305 chars)
- `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/lojas_rascunho/pt-BR/novidades.txt` (363 chars; the Play limit is 500)
- `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/lojas_rascunho/en-US/novidades.txt` (372 chars)
- `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/lojas_rascunho/privacidade.html`: the full new policy, with placeholders kept.
- `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/lojas_rascunho/excluir-conta.html`: the full new deletion page, with placeholders kept.
- `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad/lojas_rascunho/contar.py`: the length counter.

**Verified in code for this plan:**

- **Account deletion** (`lib/features/auth/data/exclusao_de_conta.dart:61-91`) deletes:
  - `users/{uid}`, `ranking/{uid}`;
  - the `srs`, `srs_log`, `textos`, `palavras` and `setlists` subcollections;
  - `audio/*` (found through `_idx`).
- **MyMemory** is used in `lib/features/ingles/data/tradutor.dart:30-37`. It is also used for word translations in Leitura (ESTADO, pending items).
- **Firestore collections the code uses today:** `users`, `srs`, `srs_log`, `audio`, `textos`, `palavras`, `setlists`, `ranking`, `config`.
- **The probe** (`lib/main_portfolio_probe.dart`) never initializes Firebase. Because of that, `SetlistsCubit` (`main.dart:355-357`) and `TextosRepository` (`main.dart:291-293`) fall back to local storage, and the probe needs no new override for Ouvir.
- **Flutter release builds turn on R8 and `isShrinkResources`** (`~/development/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterPlugin.kt:262-268`). A drawable that only Dart refers to by name gets **stripped** unless `res/raw/keep.xml` keeps it. The flutter_local_notifications 22.3.2 README (line 461) says the same.
- **flutter_local_notifications v19+ ships its own ProGuard rules** (README line 465), so no `proguard-rules.pro` is needed.
- **Every AI call goes through two places:**
  - `IaCubit._chamar` (`ia_cubit.dart:135`) serves "Por quê?" (`botao_por_que.dart:42`), word explanation (`traducao_palavra.dart:184`), scenarios (`cenario_cubit.dart:84,110`) and writing (`escrita_cubit.dart:48`).
  - `TutorCubit.perguntar` (`tutor_cubit.dart:56`) serves the tutor.

  `EngenheiroGt.debrief` (`arcade/data/engenheiro_gt.dart:53`, built at `turismo_page.dart:738`) calls Gemini REST directly.
- **Track 2 changes the AI layer this plan builds on** (`plano_conversa_ia.md` §4.1):
  - the new optional interface `TutorJson` (`perguntarJson` with `responseSchema`), which `IaCubit.consultarJson` picks with `svc is TutorJson`;
  - `FalhaIa` / `TipoFalhaIa` (`lib/features/tutor/data/falha_ia.dart`), plus `ResultadoIa.motivo`;
  - `bolha_conversa.dart` and `resumo_conversa.dart` (new); `FeedbackCenarioView` and the `_Bolha` in `conversa_page.dart` go away.

  So this plan does **not** wrap the services (a wrapper would hide `TutorJson`). The gate is a check injected into the cubits (§5.3).
- **Where the cubits are created** (`main.dart`): `IaCubit` and `IaPalavrasCubit` in `_comIa` (:254, per user); `TutorCubit` in `_cursoDe` (:282, per user + language). `_cursoDe` is built inside `_comIa`'s child (`_comHabito` → `_comLembrete` → `_comIa(user, filho)`, :236), so a provider placed in `_comIa` is visible to `_cursoDe`.
- **The word balloon** (`traducao_palavra.dart:178`): `_perguntar()` runs by itself from `initState` of an `OverlayEntry` in the root overlay, inside a `TapRegion(onTapOutside: fechar)`. `IaCubit._explicar` reads the cache (:112) before `_chamar`.
- **`TutorCubit._erroAmigavel`** (`tutor_cubit.dart:90`) knows only 403/429 strings; anything else becomes "😵 Não consegui falar com a central…" plus the raw error in backticks.
- **The avatar menu** (`hud.dart:226`) uses a fixed `Color(0xFF141414)`, while `Mixart.surface` follows the theme (`core/theme/mixart.dart:130`, light and dark).
- **`google_fonts` 7.1** fetches fonts at runtime on every platform, so the policy line about Google Fonts stays.
- **iOS:** `TARGETED_DEVICE_FAMILY = "1,2"` (pbxproj 466/596/649), `DEVELOPMENT_TEAM = 82C5YBT8U3` (478/661/684), no `ITSAppUsesNonExemptEncryption` and no `UIBackgroundModes`.
- **Android:** `build.gradle.kts:56-58` falls back to **debug signing** when `key.properties` is missing.
- **`test/firestore_rules_test.dart`:**
  - It feeds the REAL `firestore.rules` into `fake_cloud_firestore`.
  - Before that, it rewrites `allow create, update(, delete)?:` to `allow write:`, because the fake only knows `read` and `write`.
  - A bare `allow create:` would break it.

---

## 1. Goals for this round, and what is out

Claude does everything below without touching accounts, keys or uploads:

1. **Native readiness.** Re-run the audit for web-only code paths over everything added since 14/out, including Treino do dia and Conversa com IA. Prove it with ONE `flutter build appbundle --release` and ONE `flutter build ios --release --no-codesign`.
2. **Store compliance in the app.** Two policies apply:
   - **Apple 5.1.2(i)** (Nov/2025): the app must ask explicit permission before sending personal data to a third-party AI.
   - **Google Play "AI-generated content"**: users must be able to report AI output without leaving the app.

   That means a one-time **AI consent sheet**, an on/off switch in the avatar menu, and a **⚑ Denunciar** button on every AI answer. These are small code changes, and both stores can reject the app without them.
3. **Native polish found in the audit:**
   - a monochrome notification icon, kept by `keep.xml`;
   - `ITSAppUsesNonExemptEncryption=false`;
   - the release AAB fails fast when `key.properties` is missing;
   - a version bump.
4. **Listings** in pt-BR and en-US (Play and App Store), "Novidades", TestFlight "O que testar" and App Review notes.
5. **Data safety and App Privacy answers**, rewritten. The old answers wrongly said "no audio collected".
6. **Privacy policy and deletion page updated.** The placeholders stay, and the pages stay out of the deploy through `firebase.json`.
7. **New screenshots** from the probe, with caption frames: 8 scenes × phone / iPhone 6.9" / iPad 13".
8. **fastlane:** lanes for the Play internal track, the Play listing, TestFlight and the App Store listing. Secrets only come from `~/.paclingo/fastlane.env` and outside paths. The lanes fail fast with pt-BR messages.
9. **CHECKLIST rewritten** with a final ordered "🙋 O que só você faz" list.

**Out of this round:**

- creating accounts, console records, uploads or keys;
- API key restrictions;
- App Check;
- the trademark change;
- background audio (`audio_service`);
- an app-level `PrivacyInfo.xcprivacy`;
- Play Asset Delivery;
- an emulator smoke run.

---

## 2. Owner decisions and the defaults this round ships

| # | Question | Default (what ships) | Why |
|---|---|---|---|
| D1 | Version | `version: 1.0.0+2`. Every later upload bumps `+N`, and the first public release stays 1.0.0 | Nothing was ever uploaded. `+2` sets this build apart from the 11/out `.aab` |
| D2 | iPad | **Keep** `TARGETED_DEVICE_FAMILY "1,2"` and ship an iPad 13" set (2064×2752) | The layout already works at desktop widths. The probe recipe makes the set cheap |
| D3 | AI consent | **Required on every platform** (web too), per account, on this device. Pref `ia_consentimento_<uid>` = `sim`/`nao` | Apple 5.1.2(i) and the LGPD. Web stays consistent |
| D4 | AI reports | Firestore `denuncias/{auto}` with **create-only** rules, **no uid or e-mail** stored. Each doc carries `expira` = now + 365 days, and a Firestore **TTL policy** on `expira` deletes it (owner-authorized command, §12 item 3). The policy says "apagadas automaticamente em até 12 meses" | Play AI policy. Not linked to the user, so the privacy labels stay simple. The TTL makes the retention promise true |
| D5 | Data safety for the text sent to Gemini (free tier) and MyMemory | Declared **shared** (conservative) | The free tier lets Google use the content. Over-declaring is safe; under-declaring is a rejection or takedown risk |
| D6 | Export compliance | Add `ITSAppUsesNonExemptEncryption=false` | The app only uses HTTPS. The owner can revert it (one line) |
| D7 | Privacy pages | Stay **excluded** from hosting through `firebase.json` `hosting.ignore` until the owner gives a contact | Removes the manual-delete step that is easy to forget |
| D8 | Screenshots language | Framed captions **pt-BR only**. The en-US listings reuse them (Play and ASC fall back to the default language's images) | The UI is pt-BR anyway, and the repo stays lean |
| D9 | Screenshot format | **JPEG q92** (both stores accept it; no alpha problems) | About 4× smaller than PNG in git |
| D10 | Apple age rating | Answer the questionnaire honestly (AI chat = yes). **13+ expected**, the same as the Play audience | Replaces the old "4+" |
| D11 | Apple secondary category | `PRODUCTIVITY` (primary `EDUCATION`) | Matches the existing doc. No Games subcategory rules |
| D12 | en-US listing | Ship it, and state "The app's interface is in Brazilian Portuguese" | Honest metadata and a wider reach |
| D13 | Engenheira de pista (Turismo debrief) | Respects the AI switch: when denied, it uses the local debrief | Consistent with D3. No personal data is involved, but the user's "no" must mean no |
| D14 | Keystore guard | `bundleRelease` without `key.properties` **fails** with a pt-BR message. Debug and release APKs keep the fallback | Stops a debug-signed `.aab` from being uploaded |
| D15 | How the gate blocks calls | **No service wrapper.** One `PortaoIa` per user, provided in `_comIa`. `IaCubit` (and so `IaPalavrasCubit`) and `TutorCubit` get `Future<bool> Function()? permitido` = `portao.permitido`, which awaits `carregar()` first. A refusal is `TipoFalhaIa.naoAutorizada` with the text "A IA está desligada. Ligue no menu do seu avatar." | A wrapper would hide track 2's `TutorJson`. One instance means the menu switch acts at once everywhere. Awaiting the load avoids a false "no" just after start |
| D16 | Word balloon | **Never** opens the consent sheet. It reads the cache first; when the gate refuses, it shows only the literal translation and the line "IA desligada — ligue no menu do seu avatar." | A tap on a word is not a request for AI. A modal inside a `TapRegion` overlay would close the balloon and lose the result |

---

## 3. Execution order (the lead orchestrates; builds are strictly sequential)

```
Phase 0 (lead, read-only): re-audit + read what Treino do dia / Conversa com IA shipped (§4)
Phase 1 (builders, parallel, disjoint files): Group A (IA data + wiring), Group B (native config),
         Group C (store texts / fastlane / privacy / docs), Group D (capture tooling only)
Phase 2 (builders, after A): Group E (IA UI insertions)
Phase 3 (lead): flutter analyze + full flutter test → fastlane dry checks → `cd android && ./gradlew help -q`
         → flutter build appbundle --release → checks → flutter build ios --release --no-codesign → checks
         → probe web build ONCE → captures → delete build/probe
         → ESTADO + CHECKLIST final numbers → commit (owner asked to execute)
```
Never run two Flutter builds at once. No `flutter build web` other than the single probe build (memory rule: the Mac froze on 12–13/out). Run nothing in iCloud folders.

The captures moved to the end of Phase 3 because they are the part this round can drop (§3.1).

### 3.1 Cut order (what can be left for later without blocking the commit)

Do the work in this order. Each level is committed only when every level above it is green.

1. **Consent + ⚑ + rules + tests** (Groups A and E, the `firestore.rules` change, the full `flutter test`). This must ship. Without it, there is no commit.
2. **Native config + the two release builds** (Group B, `gradlew help`, `.aab`, iOS `--no-codesign`). If Gradle stops on licenses, or pods fail, record it in CHECKLIST as an owner item and go on. Do not retry heavy builds in a loop.
3. **Texts, policy, fastlane** (Group C). These are plain files and the cheapest to fix.
4. **Captures** (Group D run). If the probe build or a capture fails (size off, scene not reachable), **commit without the new captures**: keep the old `branding/lojas/{android,ios}/*.png` (skip the `git rm`), keep the `tool/lojas/` scripts, and write in CHECKLIST "capturas novas pendentes: rodar `tool/lojas/LEIA-ME.md`". Never repeat the web build in the same round.

A failure in level 4 never forces a redo of level 2.

---

## 4. Phase 0: native-readiness re-audit (lead, at execution)

Run from `/Users/fazplay/pac_dart` and record the results in the ESTADO section (§13):

```bash
git diff --name-only ad7f1d6..HEAD -- lib test pubspec.yaml firestore.rules     # what tracks 1–2 changed
grep -rln "dart:html\|dart:js_interop\|dart:ui_web\|package:web/\|js_util" lib   # every hit must be *_web.dart or main_portfolio_probe.dart
grep -rn "if (dart.library" lib                                                  # each facade: stub + (js_interop) + io where the feature exists natively
grep -rln "import 'dart:io'" lib                                                 # only *_nativo.dart (+ new ones must be behind a facade)
grep -rn "kIsWeb\|defaultTargetPlatform\|Platform\.is" lib | grep -v "_nativo.dart\|_web.dart"
grep -rhn "collection('[a-z_]*')" lib | grep -o "collection('[a-z_]*')" | sort -u   # new Firestore collections → policy/data safety/deletion
grep -rn "api\.\|https://" lib --include='*.dart' | grep -v "^.*//" | grep -o "https://[a-z0-9.\-]*" | sort -u     # new external hosts
grep -rn "consultar(\|explicar(\|perguntar(\|perguntarComo(\|generativelanguage" lib   # every AI entry point (feeds Group E list)
```

**Pass criteria:**

- No new web-only import outside a `*_web.dart` file that is reached only through a conditional import.
- Any new mic or TTS use goes through `ReconhecedorFala.navegador()` / `VozIngles`.
- Any new audio uses `SaidaDeAudio` / audioplayers.

**Conversa com IA and Treino do dia.** From the track-2 and track-1 plans (scratchpad `plano_*.md`) and from ESTADO, write down:

- each screen's entry point and file path (for Group E, the screenshots and the copy);
- any new Firestore path (for the policy, Data safety and the deletion list);
- any data sent to Gemini (for the policy);
- whether Conversa uses the mic.

**Read what track 2 actually shipped in the AI layer** (the contract below assumes `plano_conversa_ia.md` §4.1; adjust names if the code differs):

```bash
grep -n "interface class\|class .*implements" lib/features/tutor/data/tutor_service.dart   # TutorService / TutorComPersona / TutorJson and who implements them
cat lib/features/tutor/data/falha_ia.dart                                                  # TipoFalhaIa values
grep -n "_chamar\|consultarJson\|intervaloMinimo\|class ResultadoIa" -A3 lib/features/ia/presentation/ia_cubit.dart
grep -rn "TipoFalhaIa\.\|switch (.*motivo\|switch (.*tipo" lib                              # every exhaustive switch → needs the new naoAutorizada branch (Group A)
grep -rn "ConversaPage(" lib                                                               # every way into a conversation → each needs the gate (Group E)
grep -rn "FeedbackCenarioView\|class _Bolha" lib                                           # must be gone; if not, ⚑ goes there too
ls lib/features/ia/presentation/ lib/features/ia/presentation/widgets/                     # confirm bolha_conversa.dart and resumo_conversa.dart
grep -rn "\.perguntar(\|perguntarComo(\|perguntarJson(" lib | grep -v "_test\|tutor_service.dart\|ia_cubit.dart\|tutor_cubit.dart"   # any caller that skips the cubits → must get the gate
```

Write the results into the Group A and E notes before Phase 1 starts. If track 2 did not ship `TutorJson`/`FalhaIa`, Group A keeps `StatusIa.falhou` and adds the reason as a new field `naoAutorizada` on `ResultadoIa` (bool), and the rest of the plan is unchanged.

**If a new collection appeared under `users/{uid}`:**

- check that `exclusao_de_conta.dart` deletes it;
- if it doesn't, add it there and to `test/auth_test.dart`. This is owned by the lead; it is a one-line list entry.

**Final proof** is the two native release builds in Phase 3. A web-only import fails compilation there.

---

## 5. Group A: AI consent and reports, data and wiring

**Owns:**

- `lib/features/ia/data/portao_ia.dart` (new)
- `lib/features/ia/data/denuncias_repository.dart` (new)
- `lib/features/tutor/data/falha_ia.dart` (one enum value: `naoAutorizada`)
- `lib/features/ia/presentation/ia_cubit.dart` (the `permitido` parameter and the check)
- `lib/features/tutor/presentation/tutor_cubit.dart` (the `permitido` parameter, the check and the refusal text)
- every file with an exhaustive `switch` over `TipoFalhaIa` that Phase 0 lists (one new branch each, so the code compiles). Group E runs after A, so a file both groups touch is edited in sequence, never at the same time.
- `lib/main.dart`
- `lib/main_portfolio_probe.dart` (comment only)
- `lib/features/arcade/data/engenheiro_gt.dart`
- `lib/features/arcade/presentation/turismo_page.dart` (only the `EngenheiroGt(` construction at line ~738)
- `firestore.rules`
- `test/firestore_rules_test.dart`
- `test/ia_portao_test.dart` (new)
- `test/ia_denuncias_repository_test.dart` (new)

### 5.1 `lib/features/ia/data/portao_ia.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DecisaoIa { naoPerguntado, permitido, negado }

/// Texto único da recusa (tutor, cartões de erro, balão).
const textoIaDesligada = 'A IA está desligada. Ligue no menu do seu avatar.';

/// Permissão para mandar texto à IA do Google (Apple 5.1.2(i) / LGPD). Uma por conta, neste aparelho.
/// UMA instância por usuário, criada em _comIa (main.dart) — todos os cubits leem a mesma.
class PortaoIa extends ChangeNotifier {
  PortaoIa._(this._chave, this.fixo, this._decisao);
  /// Real: pref `ia_consentimento_<uid>` = 'sim' | 'nao' (ausente = nunca perguntado).
  factory PortaoIa.preferencias(String uid);           // _chave = 'ia_consentimento_$uid'; chama carregar() em seguida (sem await)
  /// Probe/testes antigos: sempre permitido, não aparece no menu.
  factory PortaoIa.liberado();                          // fixo = true, permitido, carregado = true
  /// Testes: começa em [inicial], grava só em memória.
  factory PortaoIa.memoria([DecisaoIa inicial = DecisaoIa.naoPerguntado]);
  final bool fixo;
  bool get carregado;
  DecisaoIa get decisao;                  // naoPerguntado enquanto !carregado
  bool get concedido => decisao == DecisaoIa.permitido;   // SÍNCRONO: só para rótulos (menu); nunca para liberar envio
  Future<void> carregar();                // idempotente (guarda o Future); erro de prefs = naoPerguntado (nunca lança)
  /// O que os cubits e o Turismo chamam: espera carregar() e responde. Nunca lança.
  Future<bool> permitido() async { await carregar(); return concedido; }
  Future<void> decidir(bool permitir);    // grava, notifyListeners()
  static PortaoIa? de(BuildContext context); // try RepositoryProvider.of<PortaoIa>(context, listen:false) catch → null
}
```

**No service wrapper, no `IaNaoAutorizada` exception.** The services stay as they are, so `svc is TutorJson` and `svc is TutorComPersona` keep working in `IaCubit`. The safety net is the check inside the cubits (§5.3), which every AI path in the app goes through. Phase 0's last grep finds any caller that skips the cubits; such a caller gets the same `permitido` check.

### 5.2 `lib/features/ia/data/denuncias_repository.dart`

```dart
enum MotivoDenuncia { ofensiva, errada, outro }
class Denuncia {
  final String onde;        // 'tutor' | 'por-que' | 'palavra' | 'escrita' | 'conversa' | 'conversa-resumo' (≤40)
  final MotivoDenuncia motivo;
  final String comentario;  // trimmed, ≤300
  final String pergunta;    // ≤1000 (truncate, never throw)
  final String resposta;    // ≤2000
  const Denuncia({...});
  Map<String, dynamic> toJson(); // {onde, motivo: motivo.name, comentario, pergunta, resposta, plataforma}; repo adds 'em' and 'expira'
}
abstract interface class DenunciasRepository {
  Future<void> enviar(Denuncia d);   // throws on failure (UI shows the error snackbar)
  static DenunciasRepository? de(BuildContext c); // try RepositoryProvider.of catch → null
}
class FirestoreDenunciasRepository implements DenunciasRepository {
  FirestoreDenunciasRepository({FirebaseFirestore? db, DateTime Function()? agora});
  // collection('denuncias').add({...toJson(),
  //   'em': FieldValue.serverTimestamp(),
  //   'expira': Timestamp.fromDate(agora().add(const Duration(days: 365)))})   // campo da política de TTL
}
class MemoriaDenunciasRepository implements DenunciasRepository { final enviadas = <Denuncia>[]; bool falhar = false; }
```

`plataforma` is `kIsWeb ? 'web' : defaultTargetPlatform.name` (at most 7 chars). `onde` values are fixed constants, all ≤ 40.

### 5.3 The gate in the cubits, and the wiring in `lib/main.dart`

**`falha_ia.dart`:** add `naoAutorizada` to `TipoFalhaIa`. `FalhaIa.de` never produces it (no exception carries it). In every exhaustive switch from Phase 0, the new branch shows `textoIaDesligada`, with no technical detail.

**`IaCubit`:** new constructor parameter `Future<bool> Function()? permitido` (null = always allowed, so old tests and fakes are unaffected). `IaPalavrasCubit` passes it through to `super`.

- In `_chamar`, the check is the **first** statement, before the rest window, the quota reservation and the call:
  ```dart
  if (permitido != null && !await permitido!()) return const ResultadoIa(StatusIa.falhou, '', TipoFalhaIa.naoAutorizada);
  ```
  It does not reserve, does not spend, does not open a rest window, and does not emit `esperaAte`.
- In `consultarJson`, the same check runs **before** the `intervaloMinimo` wait, so a refused turn does not wait 3 s.
- `explicar` keeps its order: cache first (`_explicar` :112), then `_chamar`. A cached explanation is shown even when the gate is closed, because nothing is sent.
- Routing is untouched: `svc is TutorJson` → `perguntarJson`, as track 2 wrote it.

**`TutorCubit`:** new parameter `Future<bool> Function()? permitido`. In `perguntar`, after appending the student's message and before creating the model or streaming: if `permitido != null && !await permitido!()`, append a Dash message with exactly `textoIaDesligada` and return. No call, no backticks. `_erroAmigavel` gets no new branch, because this path never reaches it.

**New `PacDartApp` parameters**, next to `setlistsBuilder`:

```dart
/// Permissão de IA (testes: PortaoIa.memoria(...)/liberado()). Sem isto: nuvem → preferências; sem Firebase → liberado.
final PortaoIa Function(AppUser user)? portaoIaBuilder;
/// Denúncias de respostas da IA (testes: MemoriaDenunciasRepository()). Sem isto: Firebase → Firestore; sem Firebase → nenhum (o ⚑ não aparece).
final DenunciasRepository Function()? denunciasBuilder;
```

**`_comIa` becomes** (one `PortaoIa` per user, the only instance in the app):

```dart
Widget _comIa(AppUser user, Widget filho) => RepositoryProvider<PortaoIa>(
      key: ValueKey('portao:${user.uid}'),
      create: (_) => portaoIaBuilder?.call(user) ??
          (Firebase.apps.isNotEmpty ? PortaoIa.preferencias(user.uid) : PortaoIa.liberado()),
      dispose: (p) => p.dispose(),
      child: _comDenuncias(MultiBlocProvider(
        key: ValueKey('ia:${user.uid}'),
        providers: [
          BlocProvider<IaCubit>(create: (ctx) => IaCubit(service: …as today…, …, permitido: ctx.read<PortaoIa>().permitido)),
          BlocProvider<IaPalavrasCubit>(create: (ctx) => IaPalavrasCubit(service: …as today…, …, permitido: ctx.read<PortaoIa>().permitido)),
        ],
        child: filho,
      )),
    );
```

- `_comDenuncias(w)`: `final den = denunciasBuilder?.call() ?? (Firebase.apps.isNotEmpty ? FirestoreDenunciasRepository() : null)`; if not null, `RepositoryProvider<DenunciasRepository>.value(value: den, child: w)`, else `w`. Create `den` once per user (inside the same keyed subtree), not on every rebuild.
- **`_cursoDe`** (`TutorCubit`, :301): `create: (ctx) => TutorCubit(service: …as today…, permitido: ctx.read<PortaoIa>().permitido)`. It works because `_cursoDe` is built inside `_comIa`'s child. **Never** create a second `PortaoIa` here.
- The services themselves are built exactly as today (`tutorBuilder` / `GeminiTutorService` / `FirebaseAiTutorService`), with no wrapper.

**What existing tests see:**

- **App tests** that pass `tutorBuilder` run without Firebase, so they get `liberado` and `den == null`. They are unaffected.
- **Unit tests** that build `IaCubit` / `TutorCubit` directly pass no `permitido`, so nothing changes for them.
- **The probe:** no change is needed. It gets `liberado`, so screenshots show no sheet. Add a comment line only.

### 5.4 `EngenheiroGt`

```dart
EngenheiroGt({http.Client? client, Future<bool> Function()? permitido});
// in debrief(): if (permitido != null && !await permitido!()) return t.debriefLocal;  (before ChaveGemini.obter())
```

At `turismo_page.dart:738`:

```dart
widget.engenheiro ?? EngenheiroGt(permitido: PortaoIa.de(context)?.permitido)
```

No provider (probe, old tests) means `null`, which means allowed.

### 5.5 `firestore.rules`: add before the catch-all

```
    // Denúncias de respostas da IA (botão ⚑): qualquer logado CRIA; ninguém lê/edita/apaga pelo cliente
    // (o padrão já nega; o dono lê no console). Sem uid/e-mail no documento (ver política de privacidade).
    // `expira` alimenta a política de TTL do Firestore (apaga sozinho em até 12 meses).
    match /denuncias/{id} {
      allow create: if request.auth != null
        && request.resource.data.keys().hasOnly(['onde', 'motivo', 'comentario', 'pergunta', 'resposta', 'plataforma', 'em', 'expira'])
        && request.resource.data.onde is string && request.resource.data.onde.size() <= 40
        && request.resource.data.motivo in ['ofensiva', 'errada', 'outro']
        && request.resource.data.plataforma is string && request.resource.data.plataforma.size() <= 40
        && request.resource.data.resposta is string && request.resource.data.resposta.size() <= 2000
        && request.resource.data.pergunta is string && request.resource.data.pergunta.size() <= 1000
        && request.resource.data.comentario is string && request.resource.data.comentario.size() <= 300
        && request.resource.data.expira is timestamp;
    }
```

There is **no** `allow read, update, delete: if false;` line. The default already denies, and that line would not match the test's rewrite regex.

### 5.6 `test/firestore_rules_test.dart`

1. Extend the pre-processing: also replace a bare `allow create:` with `allow write:` (the fake only knows `read`/`write`).
2. **Plan for the fake parser to reject the conditions** (`keys().hasOnly`, `is string`, `is timestamp`, `.size()`, `in [...]`). Before feeding the fake, replace the whole `match /denuncias/{id} { … }` block with `match /denuncias/{id} { allow write: if request.auth != null; }`. Try the real block first; keep the replacement only if the fake throws.
3. Plain-string tests on the **real** file, inside the denúncias block:
   - it contains `hasOnly(['onde', 'motivo', 'comentario', 'pergunta', 'resposta', 'plataforma', 'em', 'expira'])`;
   - it contains `motivo in ['ofensiva', 'errada', 'outro']` and `expira is timestamp`;
   - it contains no `allow read` and no `allow update`.
4. Behavior tests on the fake:
   - a logged-in user creates `denuncias/x`;
   - a logged-in user cannot read it back;
   - an anonymous user cannot create;
   - the catch-all still denies `outra/x`.

### 5.7 Tests (Group A)

**`test/ia_portao_test.dart`:**

- `PortaoIa.preferencias`:
  - with no pref, gives `naoPerguntado`;
  - `decidir(true)` persists `'sim'` and a new instance reads `permitido`;
  - `decidir(false)` gives `'nao'`;
  - the uid `a` choice does not leak to `b`;
  - **load race:** with `'sim'` saved, a fresh instance answers `await permitido()` with `true` even when called right after construction (before `carregar()` finished).
- `liberado`: `fixo` and `concedido`.
- `IaCubit` with a counting fake that implements `TutorService, TutorComPersona, TutorJson` (reuse track 2's `TutorConversaFalso` if exported):
  - gate denied: `consultar`, `explicar` (no cache) and `consultarJson` return `motivo == TipoFalhaIa.naoAutorizada`, the fake gets **0** calls, the quota is **not** spent, `esperaAte` stays null, and `consultarJson` does not wait `intervaloMinimo`;
  - gate denied but the explanation is cached: `explicar` returns the cached text with 0 calls;
  - gate granted: `consultarJson` still goes to `perguntarJson` (the gate does not change routing).
- `IaPalavrasCubit` passes `permitido` through (denied → 0 calls).
- `TutorCubit` denied: the last message is exactly `textoIaDesligada` (no backticks, no "Instance of"), and the fake gets 0 calls.
- **Real services keep their interfaces:** `GeminiTutorService()` is `TutorJson` and `TutorComPersona` (guards against anyone wrapping them later). If constructing `FirebaseAiTutorService` needs Firebase, check it by a plain-string test on `tutor_service.dart` instead.

**`test/ia_denuncias_repository_test.dart`:**

- `toJson` truncates to 1000 / 2000 / 300;
- the Firestore implementation writes to `denuncias` with the fields plus `em` and `expira` (`fake_cloud_firestore`; with a fixed `agora`, `expira` is exactly 365 days later);
- `Memoria.falhar` throws.

**Turismo:** add one small test (or a case in an existing turismo test) proving that `EngenheiroGt(permitido: () async => false)` returns `debriefLocal` without any HTTP call. Use a `MockClient` that fails if it is called.

---

## 6. Group E: AI UI, the consent sheet and the ⚑ button (Phase 2, after A)

**Owns:**

- `lib/features/ia/presentation/widgets/consentimento_ia.dart` (new)
- `lib/features/ia/presentation/widgets/botao_denunciar_ia.dart` (new)
- `lib/features/tutor/presentation/tutor_panel.dart`
- `lib/features/ia/presentation/widgets/botao_por_que.dart`
- `lib/features/ingles/presentation/widgets/traducao_palavra.dart`
- `lib/features/ia/presentation/cenarios_page.dart`
- `lib/features/ia/presentation/widgets/bolha_conversa.dart` (track 2)
- `lib/features/ia/presentation/resumo_conversa.dart` (track 2)
- `lib/features/ia/presentation/escrita_page.dart`
- any other file Phase 0 found that pushes `ConversaPage(` (the gate only)
- the Treino do dia AI site, only if Phase 0 found one
- `lib/features/curso/presentation/widgets/hud.dart` (the avatar menu only)
- `test/ia_consentimento_ui_test.dart` (new)
- `test/ia_denuncia_ui_test.dart` (new)
- `test/ia_consentimento_app_test.dart` (new)

### 6.1 `consentimento_ia.dart`

```dart
/// true = pode mandar à IA. Sem PortaoIa na árvore (testes antigos) → true sem perguntar.
/// Primeiro `await portao.carregar()` (nunca decide com as prefs ainda carregando).
/// Já permitido → true. Não perguntado ou negado → abre a folha; "Permitir" grava e devolve true;
/// "Agora não" grava 'nao', mostra o snackbar e devolve false. Nada é enviado antes disso.
/// Só para toques em que a pessoa PEDIU a IA (enviar, "Por quê?", abrir conversa, "Corrigir") — nunca no balão da palavra.
Future<bool> garantirIa(BuildContext context);
Future<bool?> mostrarConsentimentoIa(BuildContext context); // a folha
```

**Layout of both sheets (consent and report):**

```dart
showModalBottomSheet(
  context: context, isScrollControlled: true, useSafeArea: true,
  backgroundColor: Mixart.surface,
  builder: (ctx) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
    child: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), child: …)),
  ),
)
```

Texts use the Mixart tokens (`Mixart.ui(...)`, `Mixart.text` / `Mixart.textFaint`, `Mixart.brand` for the main button), never fixed colors, so both work in the light and dark themes.

**The consent sheet** (key `ia-consentimento`), in pt-BR:

- Title: **"Usar a IA do Google?"**
- Paragraph 1: "Para responder, corrigir e conversar, o Paclingo envia à IA Gemini, do Google, o que você escreve e o trecho da lição que está aberta."
- Paragraph 2: "Seu e-mail e seu nome não vão junto. O Google pode usar esse conteúdo para melhorar os serviços dele, então não escreva dados pessoais."
- Paragraph 3: "Você pode desligar quando quiser, no menu do seu avatar."
- Link: "Ler a política de privacidade" opens `abrirUrl('https://pac-dart.web.app/privacidade.html')`.
- Buttons: `Agora não` (key `ia-agora-nao`, TextButton) and `Permitir` (key `ia-permitir`, FilledButton). Dismissing counts as "Agora não" without saving: it returns false and does not save `'nao'`.

**Snackbar after "Agora não":** "Tudo bem: nada foi enviado. Dá para ligar a IA depois no menu do seu avatar."

### 6.2 `botao_denunciar_ia.dart`

```dart
class BotaoDenunciarIa extends StatelessWidget {
  const BotaoDenunciarIa({super.key, required this.onde, required this.pergunta, required this.resposta});
  // Sem DenunciasRepository.de(context) ou resposta vazia → SizedBox.shrink().
  // IconButton(Icons.outlined_flag, size 16, tooltip 'Denunciar esta resposta', key 'ia-denunciar').
}
```

**The report sheet** (same layout as §6.1, so the keyboard never covers the send button):

- Title: "Denunciar resposta da IA"
- Text: "Esta resposta foi gerada por IA e pode errar. Conte o que houve — vamos analisar."
- Reasons (radio, key `ia-denuncia-motivo-<name>`): "Ofensiva ou imprópria", "Errada ou enganosa", "Outro motivo"
- Field hint: "Comentário (opcional)" (maxLength 300)
- Buttons: `Cancelar` and `Enviar denúncia` (key `ia-denuncia-enviar`; disabled until a reason is chosen)

**Snackbars:**

- Success: "Obrigado! A denúncia foi enviada."
- Error: "Não deu para enviar agora. Confira a internet e tente de novo."

### 6.3 Insertions

| Site | Gate (`if (!await garantirIa(context)) return;`) | ⚑ placement |
|---|---|---|
| `tutor_panel.dart` `_enviar` (:88). This also covers the suggestion chips that call `_enviar` | First line after the empty check. Make `_enviar` `async` and guard with `mounted` | On each tutor answer bubble (`!doAluno && texto.isNotEmpty && !digitando`), and not on the `textoIaDesligada` message. `pergunta` = the previous student message |
| `botao_por_que.dart` `_pedir` (:39) | Before `ia.explicar` (a tap on "Por quê?" is an explicit request) | In the explanation card, `onde: 'por-que'` |
| `traducao_palavra.dart` `_perguntar` (:178) | **No sheet, no `garantirIa`** (D16). Call `ia.explicar` as today: the cache is read first and the cubit's gate refuses the rest. When `r.motivo == TipoFalhaIa.naoAutorizada`, keep the literal translation and show one line: "IA desligada — ligue no menu do seu avatar." (key `palavra-ia-desligada`, `Mixart.textFaint`) instead of the failure text | Next to the explanation text, `onde: 'palavra'` |
| Conversa (track 2): `cenarios_page.dart` card tap (:104) **and** every other `ConversaPage(` push site from Phase 0 | Before `Navigator.push` | ⚑ in `widgets/bolha_conversa.dart` on every AI line (character side), `onde: 'conversa'`, `pergunta` = the student's previous line. ⚑ on the card in `resumo_conversa.dart` (the final AI feedback), `onde: 'conversa-resumo'` |
| `escrita_page.dart` (the "Corrigir" action) | Before calling the cubit | On the correction result card (key `resultado-escrita`), `onde: 'escrita'` |
| Treino do dia (track 1) | Only if it calls AI (Phase 0 says) | Same pattern |

If Phase 0 shows that `FeedbackCenarioView` or `_Bolha` still exists, the ⚑ goes there too, and the lead adds that file to E.

### 6.4 Avatar menu (`hud.dart`)

Add a `PopupMenuItem<String>(value: 'ia')` before the divider that precedes "Sair da conta". Show it only when `PortaoIa.de(context)` exists and is not `fixo`.

- Icon: `Icons.auto_awesome`
- Text: `IA do Google: ligada` when granted, `IA do Google: desligada` otherwise (the menu opens long after start, so the sync `concedido` is loaded by then)
- Key: `menu-ia`
- While here, the menu's fixed `color: const Color(0xFF141414)` (:226) becomes `Mixart.surface`, so the new item reads well in the light theme. The other fixed `0xFF141414` sheets in the app stay as they are (out of scope).

**In `onSelected` (:233):**

- `'ia'` while granted: `decidir(false)` and snackbar "IA desligada. Nada mais é enviado ao Google."
- Otherwise: `mostrarConsentimentoIa`.

Because there is a single `PortaoIa` (§5.3), this switch blocks the tutor, "Por quê?", the balloon, the conversation, the writing check and the Turismo debrief at once.

### 6.5 Tests (Group E)

**`test/ia_consentimento_ui_test.dart`:** pump `TutorPanel` / `BotaoPorQue` inside a tree with `PortaoIa.memoria()` and a counting fake tutor, where the cubits get `permitido: portao.permitido`.

- Tapping send opens `ia-consentimento`.
- `ia-agora-nao`: 0 calls, the snackbar text matches, and the decision is `negado`.
- Tapping again reopens the sheet. `ia-permitir` then gives 1 call.
- A third send: no sheet.
- No `PortaoIa` in the tree: no sheet (the old behavior).
- Cenários: tapping a card while denied does not push `ConversaPage`.
- **Word balloon:** with the gate denied, tapping a word does **not** open `ia-consentimento`, the fake gets **0** calls, and `palavra-ia-desligada` shows. With a cached explanation and the gate denied, the cached text shows and calls stay at 0.
- **Small phone:** at `tester.view.physicalSize = Size(360, 640)` (devicePixelRatio 1) with `tester.view.viewInsets` simulating a keyboard (bottom ≈ 300), open the report sheet, focus the comment field, then `tester.ensureVisible(find.byKey(Key('ia-denuncia-enviar')))`: no overflow exception and the button is hit-testable. Same for `ia-permitir` in the consent sheet.

**`test/ia_denuncia_ui_test.dart`:**

- The ⚑ is absent without a repo.
- It is present on AI bubbles in `BolhaConversa` and absent on the student's; present on the `resumo_conversa` card and on `resultado-escrita`.
- Choosing a reason and sending: `MemoriaDenunciasRepository.enviadas` has `onde`, `motivo`, the truncated texts, and the success snackbar shows.
- `falhar = true` shows the error snackbar.

**`test/ia_consentimento_app_test.dart`** (whole app, like `ia_app_test`): `PacDartApp(tutorBuilder: contador, portaoIaBuilder: (_) => PortaoIa.memoria(DecisaoIa.permitido), …)`.

- Ask the tutor once: 1 call. Ask "Por quê?" once: 1 call.
- Open the avatar menu, tap `menu-ia` (now "desligada").
- Ask the tutor again: the reply is `textoIaDesligada` and calls do not grow. Tap "Por quê?": the consent sheet opens, and with `ia-agora-nao` calls still do not grow. This proves both levels (`_comIa` and `_cursoDe`) read the same `PortaoIa`.

**Regression:** the existing app tests (`ia_app_test`, `ia_cenario_app_test`, `ia_escrita_app_test`, `ingles_leitura_app_test`, …) must still pass unchanged. They run without Firebase and get `liberado`. If one fails, inject `portaoIaBuilder: (_) => PortaoIa.liberado()`; do not change the default.

---

## 7. Group B: native configuration

**Owns:**

- `pubspec.yaml` (the version line only)
- `android/app/build.gradle.kts`
- `android/app/src/main/res/drawable/ic_notificacao.xml` (new)
- `android/app/src/main/res/raw/keep.xml` (new)
- `lib/features/habito/data/agendador_celular.dart` (line 36 only)
- `ios/Runner/Info.plist`
- `.gitignore`
- `test/nativo_config_test.dart` (new)

1. **`pubspec.yaml:5`:** `version: 1.0.0+2`. This needs no `flutter clean`, because no plugin changed.
2. **`build.gradle.kts`:**
   - Delete the stale `// TODO: Specify your own unique Application ID` comment (line 34) and the two template comment lines under `applicationId`.
   - After `val chaves = …`, add:
     ```kotlin
     // O .aab da loja PRECISA da chave de upload: sem key.properties o release cairia na chave de debug e o Play recusaria.
     val gerandoAabDaLoja = gradle.startParameter.taskNames.any { it.contains("bundleRelease", ignoreCase = true) }
     if (gerandoAabDaLoja && chaves.isEmpty()) {
         throw GradleException("Falta android/key.properties (chave de upload). Veja branding/lojas/CHECKLIST.md — sem ela o .aab sairia assinado com a chave de debug.")
     }
     ```
     `isEmpty()` is a **function call** (Kotlin maps `Properties`/`Hashtable` to `Map`, where `isEmpty()` is a function), the same style as `chaves.isNotEmpty()` at line 45. A bare `chaves.isEmpty` would not compile, and since the script runs at configuration time it would break **every** Android build. Keep the `release` buildType fallback for APKs.
   - **Validate the script cheaply** before any heavy build (lead, Phase 3): `cd /Users/fazplay/pac_dart/android && ./gradlew help -q`. It only configures the project (no `bundleRelease` in the task list, so the guard does not fire) and fails fast on a Kotlin script error.
3. **`res/drawable/ic_notificacao.xml`:** a white 24dp speech bubble. The path is Material "chat_bubble", Apache-2.0. It is not the Pac shape, so there is no trademark risk.
   ```xml
   <vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="24dp" android:height="24dp"
       android:viewportWidth="24" android:viewportHeight="24">
     <path android:fillColor="#FFFFFFFF" android:pathData="M20,2H4C2.9,2 2,2.9 2,4v18l4,-4h14c1.1,0 2,-0.9 2,-2V4C22,2.9 21.1,2 20,2z"/>
   </vector>
   ```
   **`res/raw/keep.xml`:**
   ```xml
   <?xml version="1.0" encoding="utf-8"?>
   <resources xmlns:tools="http://schemas.android.com/tools" tools:keep="@drawable/ic_notificacao,@mipmap/ic_launcher" />
   ```
4. **`agendador_celular.dart:36`:** `AndroidInitializationSettings('@drawable/ic_notificacao')`. Then run `grep -rn "ic_launcher" test lib` to make sure no test asserts the old string.
5. **`Info.plist`:** after the `NSSpeechRecognitionUsageDescription` pair, add `<key>ITSAppUsesNonExemptEncryption</key><false/>`. Do NOT add `UIBackgroundModes`.
6. **`.gitignore`:** append
   ```
   # fastlane / lojas: nada de segredo no git
   fastlane/report.xml
   fastlane/Preview.html
   fastlane/test_output/
   fastlane/.env*
   fastlane/README.md
   *.p8
   *service-account*.json
   *.jks
   *.keystore
   *.mobileprovision
   *.ipa
   *.aab
   ```
   fastlane regenerates `fastlane/README.md` on its own. Our doc is `README-lojas.md`.
7. **`test/nativo_config_test.dart`** (VM; reads files). Assert that:
   - the main `AndroidManifest.xml` contains `INTERNET`, `RECORD_AUDIO`, `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and does **not** contain `FOREGROUND_SERVICE` or `SCHEDULE_EXACT_ALARM`;
   - `Info.plist` contains `NSMicrophoneUsageDescription`, `NSSpeechRecognitionUsageDescription`, `ITSAppUsesNonExemptEncryption` followed by `<false/>`, and **no** `UIBackgroundModes`. The reason message is: "a ficha das lojas promete áudio só com o app aberto".
   - the `pubspec.yaml` version matches `^\d+\.\d+\.\d+\+(\d+)$` with a build ≥ 2;
   - `ic_notificacao.xml` exists, `keep.xml` contains `@drawable/ic_notificacao`, and `agendador_celular.dart` contains `'@drawable/ic_notificacao'`;
   - `build.gradle.kts` contains `bundleRelease` and `GradleException`;
   - `.gitignore` contains `*.p8` and `*service-account*.json`.

---

## 8. Group C: store texts, privacy, fastlane and docs (no Dart)

**Owns:**

- `branding/lojas/CHECKLIST.md`
- `branding/lojas/google-play.md`
- `branding/lojas/app-store.md`
- `web/privacidade.html`
- `web/excluir-conta.html`
- `firebase.json`
- `fastlane/Appfile`
- `fastlane/Fastfile`
- `fastlane/README-lojas.md`
- `fastlane/fastlane.env.exemplo`
- every `fastlane/metadata/**/*.txt`
- `test/lojas_metadados_test.dart` (new)

It does NOT own `fastlane/metadata/android/*/images/**` or `fastlane/screenshots/**`; those belong to Group D and the lead.

**Before writing:** update the "TREINO DO DIA" and "CONVERSA COM IA" paragraphs of the scratchpad drafts so they match what tracks 1 and 2 really shipped (names, what the session contains, whether Conversa uses voice). Keep every limit: run `contar.py`-style counting in `lojas_metadados_test`.

### 8.1 Privacy pages

- Copy `lojas_rascunho/privacidade.html` to `web/privacidade.html` and `lojas_rascunho/excluir-conta.html` to `web/excluir-conta.html`.
- Set the date line to the execution date in the form `21 de outubro de 2026`.
- Keep `[SEU NOME OU EMPRESA]` / `[SEU E-MAIL DE CONTATO]` as they are.
- If Phase 0 found new data, such as Conversa history saved in Firestore or a Treino do dia doc, add a table row and add it to the deletion list.
- The draft already says the reports "são apagadas automaticamente em até 12 meses" (lines 64 and 73). That is true only after the TTL policy exists (§12 item 3). Until then, CHECKLIST marks it ⚠️.

**`firebase.json` `hosting.ignore`:** add `"privacidade.html"` and `"excluir-conta.html"`, with a comment in CHECKLIST (JSON has no comments): "tirar do ignore quando o dono passar o contato".

### 8.2 fastlane layout (root `fastlane/`)

```
fastlane/
  Appfile
  Fastfile
  README-lojas.md                 (pt-BR: setup + each lane, short)
  fastlane.env.exemplo            (template; real file = ~/.paclingo/fastlane.env, chmod 600)
  metadata/android/pt-BR/{title,short_description,full_description}.txt + changelogs/default.txt
  metadata/android/en-US/{title,short_description,full_description}.txt + changelogs/default.txt
  metadata/android/pt-BR/images/{icon.png,featureGraphic.png,phoneScreenshots/*.jpg}   ← Group D / lead
  metadata/ios/copyright.txt, primary_category.txt (EDUCATION), secondary_category.txt (PRODUCTIVITY)
  metadata/ios/pt-BR/{name,subtitle,promotional_text,description,keywords,support_url,privacy_url,marketing_url}.txt
  metadata/ios/en-US/{same}.txt
  metadata/ios/review_information/notes.txt        (no personal data; the rest comes from env)
  screenshots/ios/pt-BR/*.jpg                       ← Group D / lead (iPhone 1320×2868 + iPad 2064×2752)
```

**No iOS `release_notes.txt`.** Apple has no "What's New" for the first version, and `deliver` would fail on it. The text lives in `app-store.md` for 1.0.1+.

**`fastlane.env.exemplo`:**

```
# Copie para ~/.paclingo/fastlane.env (FORA do repositório) e: chmod 600 ~/.paclingo/fastlane.env
# Google Play — JSON da conta de serviço (Play Console > Configuração > Acesso à API)
PACLINGO_PLAY_JSON=~/.paclingo/play-service-account.json
# App Store Connect — chave de API (Usuários e acesso > Integrações > Chaves)
ASC_KEY_ID=
ASC_ISSUER_ID=
ASC_KEY_PATH=~/.appstoreconnect/private_keys/AuthKey_XXXXXXXXXX.p8
# Time da Apple (o projeto já usa 82C5YBT8U3 — confirme que é o da conta da loja)
PACLINGO_TEAM_ID=82C5YBT8U3
# Conta de teste para a revisão da Apple (crie no app; não use a sua)
PACLINGO_REVISAO_EMAIL=
PACLINGO_REVISAO_SENHA=
PACLINGO_REVISAO_NOME=
PACLINGO_REVISAO_SOBRENOME=
PACLINGO_REVISAO_TELEFONE=
PACLINGO_REVISAO_CONTATO_EMAIL=
```

**`Appfile`:**

```ruby
# Paclingo — sem segredo aqui (chaves vêm de ~/.paclingo/fastlane.env, lidas no Fastfile)
package_name("com.carlos.paclingo")
app_identifier("com.carlos.paclingo")
team_id(ENV["PACLINGO_TEAM_ID"] || "82C5YBT8U3")
```

**`Fastfile`:**

```ruby
# Paclingo — publicação. NUNCA ponha chave/senha neste arquivo nem no repositório.
# Uso: fastlane android interno | android ficha | android verificar | ios testflight | ios ficha | ios verificar
require "dotenv"
default_platform(:android)

RAIZ = `git rev-parse --show-toplevel`.strip
ENV_ARQUIVO = File.expand_path(ENV["PACLINGO_ENV"] || "~/.paclingo/fastlane.env")
Dotenv.load(ENV_ARQUIVO) if File.exist?(ENV_ARQUIVO)
FLUTTER = File.expand_path(ENV["FLUTTER"] || "~/development/flutter/bin/flutter")
AAB = File.join(RAIZ, "build/app/outputs/bundle/release/app-release.aab")
META = File.join(RAIZ, "fastlane/metadata")

def exigir_env!(*nomes)
  faltam = nomes.select { |n| ENV[n].to_s.strip.empty? }
  return if faltam.empty?
  UI.user_error!("Faltam #{faltam.join(', ')} em #{ENV_ARQUIVO} (fora do repositório). Modelo: fastlane/fastlane.env.exemplo")
end

def arquivo_secreto!(var)
  caminho = File.expand_path(ENV[var].to_s)
  UI.user_error!("#{var}: arquivo não encontrado (#{caminho}).") unless File.file?(caminho)
  UI.user_error!("#{var} aponta para DENTRO do repositório — mova para ~/.paclingo/ ou ~/.appstoreconnect/.") if caminho.start_with?(RAIZ + "/")
  caminho
end

def sem_marcadores!(pasta)
  sujos = Dir.glob(File.join(pasta, "**/*.txt")).select { |f| File.read(f).include?("[SEU ") }
  UI.user_error!("Ainda há [SEU …] em: #{sujos.map { |f| f.sub(RAIZ + '/', '') }.join(', ')}") unless sujos.empty?
end

def versao_pubspec
  linha = File.read(File.join(RAIZ, "pubspec.yaml"))[/^version:\s*(\S+)/, 1] or UI.user_error!("pubspec.yaml sem version")
  nome, numero = linha.split("+")
  { nome: nome, numero: numero.to_i }
end

platform :android do
  desc "Confere a conta de serviço do Play (não envia nada)"
  lane :verificar do
    exigir_env!("PACLINGO_PLAY_JSON")
    validate_play_store_json_key(json_key: arquivo_secreto!("PACLINGO_PLAY_JSON"))
  end

  desc "Gera o .aab de release (exige android/key.properties)"
  lane :aab do
    UI.user_error!("Falta android/key.properties (chave de upload).") unless File.exist?(File.join(RAIZ, "android/key.properties"))
    sh("cd #{RAIZ.shellescape} && #{FLUTTER.shellescape} build appbundle --release")
    UI.success("AAB: #{AAB} (#{(File.size(AAB) / 1024.0 / 1024).round(1)} MB)")
  end

  desc "Envia o .aab ao teste INTERNO como rascunho (o 1º envio do app precisa ser manual no Play Console)"
  lane :interno do |o|
    exigir_env!("PACLINGO_PLAY_JSON")
    aab if o[:construir]
    UI.user_error!("Não achei #{AAB}. Rode: fastlane android aab") unless File.exist?(AAB)
    upload_to_play_store(track: "internal", release_status: "draft", aab: AAB,
      json_key: arquivo_secreto!("PACLINGO_PLAY_JSON"), metadata_path: File.join(META, "android"),
      skip_upload_metadata: true, skip_upload_images: true, skip_upload_screenshots: true)
  end

  desc "Envia só a ficha (textos, ícone, gráfico e capturas) — sem binário"
  lane :ficha do
    exigir_env!("PACLINGO_PLAY_JSON")
    sem_marcadores!(File.join(META, "android"))
    upload_to_play_store(json_key: arquivo_secreto!("PACLINGO_PLAY_JSON"), metadata_path: File.join(META, "android"),
      skip_upload_apk: true, skip_upload_aab: true, skip_upload_changelogs: true, sync_image_upload: true)
  end
end

platform :ios do
  def chave_asc
    exigir_env!("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH")
    app_store_connect_api_key(key_id: ENV["ASC_KEY_ID"], issuer_id: ENV["ASC_ISSUER_ID"],
      key_filepath: arquivo_secreto!("ASC_KEY_PATH"), in_house: false)
  end

  desc "Confere a chave do App Store Connect (não envia nada)"
  lane :verificar do
    chave_asc
    UI.success("Chave do App Store Connect OK.")
  end

  desc "Compila, assina (Team #{ENV['PACLINGO_TEAM_ID'] || '82C5YBT8U3'}) e envia ao TestFlight"
  lane :testflight do
    chave_asc
    sh("cd #{RAIZ.shellescape} && #{FLUTTER.shellescape} build ios --release --no-codesign")
    auth = "-allowProvisioningUpdates -authenticationKeyPath #{File.expand_path(ENV['ASC_KEY_PATH']).shellescape} " \
           "-authenticationKeyID #{ENV['ASC_KEY_ID']} -authenticationKeyIssuerID #{ENV['ASC_ISSUER_ID']}"
    build_app(workspace: File.join(RAIZ, "ios/Runner.xcworkspace"), scheme: "Runner", configuration: "Release",
      export_method: "app-store", export_team_id: ENV["PACLINGO_TEAM_ID"] || "82C5YBT8U3",
      output_directory: File.join(RAIZ, "build/ios/fastlane"), xcargs: auth, export_xcargs: auth)
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end

  desc "Envia só a ficha (textos e capturas) — não envia para revisão"
  lane :ficha do
    chave_asc
    sem_marcadores!(File.join(META, "ios"))
    v = versao_pubspec
    revisao = {
      first_name: ENV["PACLINGO_REVISAO_NOME"], last_name: ENV["PACLINGO_REVISAO_SOBRENOME"],
      phone_number: ENV["PACLINGO_REVISAO_TELEFONE"], email_address: ENV["PACLINGO_REVISAO_CONTATO_EMAIL"],
      demo_user: ENV["PACLINGO_REVISAO_EMAIL"], demo_password: ENV["PACLINGO_REVISAO_SENHA"],
      notes: File.read(File.join(META, "ios/review_information/notes.txt"))
    }.compact
    deliver(app_version: v[:nome], skip_binary_upload: true, submit_for_review: false, force: true,
      metadata_path: File.join(META, "ios"), screenshots_path: File.join(RAIZ, "fastlane/screenshots/ios"),
      overwrite_screenshots: true, run_precheck_before_submit: false, precheck_include_in_app_purchases: false,
      app_review_information: revisao)
  end
end
```

**Notes for the builder:**

- In Ruby, `shellescape` needs `require "shellwords"`. Add it next to `require "dotenv"`.
- `export_xcargs` is a real gym option; keep it.
- If `deliver` rejects the folder because `review_information/notes.txt` sits next to the locale folders, move `notes.txt` to `fastlane/revisao-apple.txt` and update the path.
- `metadata_path` for ios is `fastlane/metadata/ios`, so it does not clash with supply's `metadata/android`.

**`README-lojas.md`** (pt-BR, at most about 60 lines):

1. one-time setup: copy the env template, chmod 600, where to get each key;
2. the order of the first upload (manual first `.aab` in the console, then `fastlane android interno`);
3. `fastlane ios testflight`;
4. `fastlane android ficha` / `fastlane ios ficha`;
5. "Nunca: chaves dentro do repo; `--force` em nada; enviar para revisão pelo fastlane (faça no console)".

### 8.3 Metadata text values

| File | Value |
|---|---|
| android/pt-BR/title.txt | `Paclingo: aprenda digitando` (27/30) |
| android/pt-BR/short_description.txt | `Inglês, Dart e C# digitando: treino do dia, ouvir, jogos e conversa com IA.` (75/80) |
| android/pt-BR/full_description.txt | draft `pt-BR/descricao_completa.txt` |
| android/pt-BR/changelogs/default.txt | draft `pt-BR/novidades.txt` |
| android/en-US/title.txt | `Paclingo: learn by typing` (25/30) |
| android/en-US/short_description.txt | `Learn English, Dart and C# by typing. Daily practice, listening, games, AI chat.` (80/80) |
| android/en-US/full_description.txt / changelogs/default.txt | en-US drafts |
| ios/pt-BR/name.txt | `Paclingo`. If the name is taken in ASC, the owner uses `Paclingo: aprenda digitando` |
| ios/pt-BR/subtitle.txt | `Inglês e código digitando` (25/30) |
| ios/pt-BR/promotional_text.txt | `Novo: Treino do dia, 🎧 Ouvir com setlists, conversa com IA e palavras teimosas que voltam até grudar. Digite, ouça, fale — e fixe de vez.` (137/170) |
| ios/pt-BR/keywords.txt | `inglês,digitação,programação,vocabulário,idiomas,código,frases,pronúncia,ouvir,conversa,teclado` (95 chars) |
| ios/pt-BR/description.txt | same as the Play pt-BR full description |
| ios/en-US/name.txt | `Paclingo` |
| ios/en-US/subtitle.txt | `Learn English by typing` (23) |
| ios/en-US/promotional_text.txt | `New: daily practice, 🎧 listening playlists, AI conversation and stubborn words that come back until they stick. Type, listen, speak.` (132) |
| ios/en-US/keywords.txt | `english,typing,learn,programming,vocabulary,coding,phrases,listening,flashcards,keyboard,portuguese` (99) |
| ios/*/support_url.txt, privacy_url.txt | `https://pac-dart.web.app/privacidade.html` |
| ios/*/marketing_url.txt | `https://pac-dart.web.app` |
| ios/copyright.txt | `© 2026 [SEU NOME OU EMPRESA]`. The `ficha` lane refuses it until the owner fills it in. This is intended |

**`ios/review_information/notes.txt`** (pt-BR; the reviewer reads English, so put the pt-BR block first and the en-US block below it):

```
O app tem login por e-mail e senha (Firebase Authentication). Use a conta de teste informada.
Recursos de IA (tutor, "Por quê?", cenários, correção de escrita e conversa) usam o Gemini do Google e só funcionam depois que a pessoa
toca em "Permitir" na tela "Usar a IA do Google?". Dá para desligar no menu do avatar (círculo com a inicial, no topo).
Cada resposta da IA tem um botão ⚑ para denunciar conteúdo impróprio.
O microfone é opcional (curso de inglês, botão 🎤) e usa o Reconhecimento de Fala do iOS; o app não grava áudio.
O "🎧 Ouvir" toca só com o app aberto (não usa áudio em segundo plano).
Excluir conta: ícone do perfil (círculo com a inicial, no topo) > Excluir minha conta.

Sign in with the demo account above. AI features (Google Gemini) run only after the user taps "Permitir" on the consent sheet;
every AI answer has a ⚑ report button. The microphone is optional (iOS Speech Recognition, no audio is stored).
Listening ("Ouvir") plays only while the app is open. Account deletion: avatar circle (top) > "Excluir minha conta".
```

### 8.4 `branding/lojas/google-play.md` (rewrite)

**Basic data table:**

- Same layout as before.
- Screenshots row: `fastlane/metadata/android/pt-BR/images/phoneScreenshots/` (8, 1080×1920 JPEG).
- Keep the icon and feature-graphic rows.
- Add a line: "Textos oficiais: `fastlane/metadata/android/<idioma>/` (pt-BR padrão + en-US)".

**Descriptions:** don't duplicate them. Point to the metadata files and keep only the short fields in the table.

**"Novidades (o que há de novo)":** points to `changelogs/default.txt`. From 1.0.1 on, create `changelogs/<versionCode>.txt`.

**Data safety (new table):**

| Tipo de dado | Coletado | Compartilhado | Opcional? | Finalidade |
|---|---|---|---|---|
| Informações pessoais → Endereço de e-mail | Sim | Não | Obrigatório | Gerenciamento da conta; Funcionalidade do app |
| Informações pessoais → IDs de usuário (UID; o apelido do ranking vem do e-mail) | Sim | Não | Obrigatório | Funcionalidade do app; Gerenciamento da conta |
| Atividade no app → Interações no app (progresso, pontos, ranking, sequência, uso da IA no dia) | Sim | Não | Obrigatório | Funcionalidade do app |
| Atividade no app → Outros conteúdos gerados pelo usuário (textos colados/escritos, palavras, cartões, setlists, frases enviadas à tradução) | Sim | **Sim**¹ | Opcional | Funcionalidade do app |
| Mensagens → Outras mensagens no app (perguntas e conversa com a IA) | Sim | **Sim**¹ | Opcional | Funcionalidade do app |
| Áudio → Outros arquivos de áudio (áudios que a pessoa anexa às frases) | Sim | Não | Opcional | Funcionalidade do app |
| Áudio → Gravações de voz | **Não**² | — | — | — |
| Identificadores do dispositivo, localização, contatos, fotos, saúde, finanças, histórico, diagnóstico | Não | — | — | — |

**Header answers:** collects or shares = Sim; encrypted in transit = Sim; deletion = Sim (in the app plus the URL).

**Footnotes:**

- ¹ Sent to Google's Gemini (free tier: Google may use the content) and to MyMemory (translation). Only after consent in the case of AI. Declared as shared to be conservative.
- ² The 🎤 uses the system recognizer. The app only receives text.

**App content section (new):**

- **Ads:** No.
- **App access:** login required → test account (owner).
- **Content rating (IARC):** Reference/Education. If asked about AI-generated content or interaction: **Yes, generative AI with in-app reporting (⚑)**. Ranking nicknames are visible to other users.
- **Target audience:** 13+.
- **News:** No. **Government:** No. **Financial features:** none. **Health:** No.
- **Data deletion URL:** the excluir-conta page.

**Before sending:**

- the closed test (12 testers for 14 days);
- the first `.aab` manual in the console, then `fastlane android interno`;
- App Signing SHA to Firebase;
- checking the 16 KB page-size line (see §11).

### 8.5 `branding/lojas/app-store.md` (rewrite)

**Table:**

- name, subtitle, promo and keywords: point to `fastlane/metadata/ios/<loc>/`;
- screenshots: `fastlane/screenshots/ios/pt-BR/` (iPhone 6.9" 1320×2868 and iPad 13" 2064×2752).

**App Privacy (new table).** Tracking: **No** for all rows.

| Tipo | Vinculado | Finalidade |
|---|---|---|
| Informações de contato → E-mail | Sim | Funcionalidade do app |
| Identificadores → ID do usuário | Sim | Funcionalidade do app |
| Dados de uso → Interação com o produto | Sim | Funcionalidade do app |
| Conteúdo do usuário → Dados de áudio (áudios anexados) | Sim | Funcionalidade do app |
| Conteúdo do usuário → Conteúdo de jogo (recordes do arcade no ranking) | Sim | Funcionalidade do app |
| Conteúdo do usuário → Outro conteúdo do usuário (textos, palavras, cartões, setlists, mensagens à IA) | Sim | Funcionalidade do app |

**Not collected:** location, contacts, health, financial, browsing, search, diagnostics, sensitive data, purchases, device IDs.

**Age rating:** answer the new questionnaire. AI or chat with generated content: Yes. UGC between users: No (the ranking only shows nicknames). Web access: No. **Expected 13+.**

**Export compliance:** the `Info.plist` key is already there (exempt, HTTPS only).

**Other sections:**

- Review notes: point to `notes.txt`.
- "What's New" for 1.0.1+: paste from `novidades.txt`.
- **TestFlight "O que testar"** (paste into ASC):

```
Obrigado por testar o Paclingo! Confira, no seu aparelho:
1. Entrar com e-mail e senha; sair e entrar de novo.
2. Inglês: digitar uma frase, tocar no 🔊 (voz) e no 🎤 (fale a frase; aceite o microfone).
3. 🎧 Ouvir: tocar "Do começo", navegar pelo app com o mini-player; bloquear a tela (deve PARAR — é esperado).
4. Treino do dia: fazer uma sessão inteira.
5. IA: abrir a conversa/tutor, ver o pedido "Usar a IA do Google?", permitir, conversar e testar o ⚑.
6. Arcade: uma partida com som.
7. Lembrete diário: ligar para daqui a 2 minutos e fechar o app.
8. Avise qualquer travamento, som cortado ou tela que não coube.
```

### 8.6 `branding/lojas/CHECKLIST.md` (rewrite, about 90 lines)

Keep the legend ✅ / 👤 / ⚠️ and add 🤖 (Claude does it on request).

**Sections:**

1. **Status:** what is ready, with dates. Includes:
   - the version;
   - the `.aab` path and size from Phase 3;
   - the iOS build;
   - consent and reporting;
   - the listings, screenshots and fastlane.
2. **Builds:** the exact commands.
3. **fastlane:** points to `fastlane/README-lojas.md`.
4. **Native features verified,** updated with everything since 14/out, each marked ⚠️ until a real device proves it.
5. **Attention points,** fixed:
   - "o app não guarda áudio" becomes "não grava o microfone; guarda só os áudios que você anexa";
   - the AI free-tier quota;
   - the TTL of `denuncias` (⚠️ until §12 item 3 runs: the policy promises deletion within 12 months);
   - the ranking nickname;
   - 13+;
   - the Pac/Dash trademark.
6. **🙋 O que só você faz:** the ordered list from §12, verbatim.

### 8.7 `test/lojas_metadados_test.dart` (VM)

Read every metadata file and assert:

**Play:**

- title ≤ 30
- short ≤ 80
- full ≤ 4000
- changelog ≤ 500

**iOS:**

- name ≤ 30
- subtitle ≤ 30
- promo ≤ 170
- keywords ≤ 100 chars, no spaces after commas
- description ≤ 4000

**Across all files:**

- no `Pac-Man`, `Flutter` or `Dash` in titles, names, subtitles or keywords;
- no `segundo plano`, `tela bloqueada`, `background` or `lock screen` anywhere in descriptions or changelogs (case-insensitive);
- both descriptions contain the open-app caveat (`com o app aberto` / `while the app is open`);
- the `[SEU ` placeholder appears only in `ios/copyright.txt`.

**Privacy page:**

- `web/privacidade.html` contains `MyMemory`, `Gemini`, `Permitir`/`permitir`, `áudios`, `Denúncias` and `apagadas automaticamente em até 12 meses`;
- `web/excluir-conta.html` contains `setlists` and `áudios`.

**`firebase.json`:** `hosting.ignore` contains both pages.

---

## 9. Group D: capture tooling (written in Phase 1, run by the lead in Phase 3)

**Owns:**

- `tool/lojas/capturas.mjs` (new)
- `tool/lojas/moldura.html` (new)
- `tool/lojas/LEIA-ME.md` (new, short)
- the generated images under `fastlane/metadata/android/pt-BR/images/**` and `fastlane/screenshots/ios/pt-BR/**`
- the removal of the old `branding/lojas/android/*.png` and `branding/lojas/ios/*.png` (`git rm`)

### 9.1 `capturas.mjs` (Node 22, Playwright from the npx cache)

```js
// Capturas das lojas a partir do build de prova (lib/main_portfolio_probe.dart, sem Firebase).
// Uso: (1) flutter build web -t lib/main_portfolio_probe.dart --release --output=build/probe --no-tree-shake-icons --no-wasm-dry-run
//      (2) python3 -m http.server 8789 --directory build/probe   (3) node tool/lojas/capturas.mjs [cena…]
// PLAYWRIGHT=/caminho/para/playwright/index.mjs para trocar o pacote. Saída crua: build/lojas_cru/<aparelho>/NN_nome.png
const PW = process.env.PLAYWRIGHT || "/Users/fazplay/.npm/_npx/9833c18b2d85bc59/node_modules/playwright/index.mjs";
const { chromium } = await import(PW);
const APARELHOS = {
  android: { w: 360, h: 640, escala: 3, ua: "Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Mobile Safari/537.36" },
  iphone:  { w: 440, h: 956, escala: 3, ua: null /* vem do script IPHONE copiado (abaixo) */ },
  ipad:    { w: 1032, h: 1376, escala: 2, ua: "Mozilla/5.0 (iPad; CPU OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1" },
};
```

**Context and page setup:**

- Each context gets `isMobile: true` (false for the iPad), `hasTouch: true`, `locale: 'pt-BR'`, `timezoneId: 'America/Sao_Paulo'` and `deviceScaleFactor`.
- **iPhone identity:** copy the whole `IPHONE` init script from `~/development/paclingo-video/captura/lib.mjs` (line 49: UA + `navigator.platform` + `maxTouchPoints`) as a string constant and pass it to `ctx.addInitScript(IPHONE)` for the iPhone context, exactly as `lib.mjs:71` does. The UA is not a separate constant there, so do not invent one. The iPad context only sets the iPad UA above (no init script); the Android context only sets its UA.
- State goes in through `localStorage['flutter.<key>'] = JSON.stringify(value)` (strings keep their quotes). Reuse `prefsPadrao` / `habitoSemeado` from `~/development/paclingo-video/captura/lib.mjs` by **copying** the two small functions; do not import that file, because it reads `~/Downloads/...`. Read `ESTADO` from `~/development/paclingo-video/captura/estado-app.json`, falling back to `~/Downloads/pac-dart-video/estado-app.json`.
- **Freeze the clock on the same day the seeded data assumes:** `habitoSemeado` fixes `hoje` at `Date.UTC(2026, 9, 14)` and the seeded revision (`ESTADO.revisao`) is dated for that week too. So use `page.clock.install({ time: new Date('2026-10-14T08:30:00-03:00') })`, as the video does, then `runFor` to settle animations. Keep one constant `const DIA = new Date('2026-10-14T08:30:00-03:00')` and, in the copied `habitoSemeado`, derive `hoje = Math.floor(Date.UTC(DIA.getUTCFullYear(), DIA.getUTCMonth(), DIA.getUTCDate()) / 86400000)` instead of the literal date, so the two can never drift apart again.
- Before the first scene, unregister the service worker and clear caches.
- Enable semantics: `document.querySelector('flt-semantics-placeholder')?.click()`.
- Click by `getByRole('button', { name })` / `getByText`, falling back to coordinates measured once.

**Scenes.** Keep 8 at most, the Play maximum.

| NN_nome | Prefs / steps | Must NOT show |
|---|---|---|
| 01_escolha | no `linguagem_carlos` → the track-choice screen | — |
| 02_treino_do_dia | English, seeded habit (12 days) → open Treino do dia (path from track 1) | — |
| 03_frase | `en_trilha`/`en_licao` like `s2_licao` → palco with the character and a phrase half typed | the 🎤 "Ouvindo…" state |
| 04_ouvir | HUD **Ouvir** → "Do começo" → open "Tocando agora" → `runFor(1500)` | "Seu navegador não tem voz…" (mode Só inglês) |
| 05_conversa | Cenários or the track-2 Conversa → send one message (the `_TutorFake` answers) | the consent sheet (the probe is `liberado`) |
| 06_palavras | "Minhas palavras" with the teimosas card (seed from estado-app.json; otherwise do one word session first) | — |
| 07_arcade | Arcade → **Rali or Chuva** with English words, mid-game | **Turismo 3D** (web-only three.js; the phone uses the Canvas view, which would mislead) |
| 08_dart | `linguagem_carlos: 'dart'` → a lesson with code half typed | the **DartPad embed** (web only) |

**Captions** (pt-BR, ≤ 38 chars, in `moldura.html`):

- 01: "Escolha: inglês, Dart ou C#"
- 02: "Treino do dia, curto e pronto pra você"
- 03: "Digite, ouça e fale a frase"
- 04: "🎧 Ouça o curso ou suas setlists"
- 05: "Converse em inglês com a IA"
- 06: "Palavras teimosas voltam até grudar"
- 07: "Arcade com as palavras das lições"
- 08: "Código de verdade, digitado por você"

### 9.2 `moldura.html`

- One static page that reads `?img=&titulo=&w=&h=` and draws:
  - the background `#0B1136`, with the same neon turquoise→purple frame as the logo;
  - the caption at the top (system-ui 700, `#FFD21F` for the first word, then white), about 15% of the height;
  - the raw screenshot scaled to 84% of the width, with 28px rounded corners and a soft shadow;
  - no device chrome.
- The script opens it at the final pixel size with `deviceScaleFactor: 1` and takes a JPEG screenshot with `quality: 92`. The raw image is served from the same http.server, so copy `build/lojas_cru` under `build/probe/_cru/` before serving.

**Final outputs:**

- android → `fastlane/metadata/android/pt-BR/images/phoneScreenshots/NN_nome.jpg` (1080×1920)
- iphone → `fastlane/screenshots/ios/pt-BR/iphone_NN_nome.jpg` (1320×2868)
- ipad → `fastlane/screenshots/ios/pt-BR/ipad_NN_nome.jpg` (2064×2752)
- Copy `branding/play-store-512.png` to `…/pt-BR/images/icon.png` and `branding/lojas/grafico-play-1024x500.png` to `…/images/featureGraphic.png`.

**Exact pixel sizes are required by the stores.** After capture, check each image with `sips -g pixelWidth -g pixelHeight` and fail if any size is off.

---

## 10. Wiring and ownership summary (disjoint)

| Group | Phase | Files |
|---|---|---|
| A | 1 | `lib/features/ia/data/portao_ia.dart`*, `lib/features/ia/data/denuncias_repository.dart`*, `lib/features/tutor/data/falha_ia.dart` (enum value), `lib/features/ia/presentation/ia_cubit.dart`, `lib/features/tutor/presentation/tutor_cubit.dart`, the files with exhaustive `TipoFalhaIa` switches (Phase 0 list, one branch each), `lib/main.dart`, `lib/main_portfolio_probe.dart` (comment only), `lib/features/arcade/data/engenheiro_gt.dart`, `lib/features/arcade/presentation/turismo_page.dart` (line ~738), `firestore.rules`, `test/firestore_rules_test.dart`, `test/ia_portao_test.dart`*, `test/ia_denuncias_repository_test.dart`*, plus a Turismo engineer test |
| B | 1 | `pubspec.yaml` (version), `android/app/build.gradle.kts`, `android/app/src/main/res/drawable/ic_notificacao.xml`*, `android/app/src/main/res/raw/keep.xml`*, `lib/features/habito/data/agendador_celular.dart`, `ios/Runner/Info.plist`, `.gitignore`, `test/nativo_config_test.dart`* |
| C | 1 | `branding/lojas/{CHECKLIST,google-play,app-store}.md`, `web/privacidade.html`, `web/excluir-conta.html`, `firebase.json`, `fastlane/{Appfile,Fastfile,README-lojas.md,fastlane.env.exemplo}`*, `fastlane/metadata/**/*.txt`*, `test/lojas_metadados_test.dart`* |
| D | 1 (code) / 3 (run by the lead) | `tool/lojas/{capturas.mjs,moldura.html,LEIA-ME.md}`*, images under `fastlane/metadata/android/pt-BR/images/` and `fastlane/screenshots/ios/pt-BR/`, `git rm branding/lojas/{android,ios}/*.png` |
| E | 2 | `lib/features/ia/presentation/widgets/{consentimento_ia,botao_denunciar_ia}.dart`*, `tutor_panel.dart`, `botao_por_que.dart`, `traducao_palavra.dart`, `cenarios_page.dart`, `widgets/bolha_conversa.dart`, `resumo_conversa.dart`, `escrita_page.dart`, any other `ConversaPage(` push site (gate only), the Treino do dia AI site if any, `hud.dart` (avatar menu), `test/ia_consentimento_ui_test.dart`*, `test/ia_denuncia_ui_test.dart`*, `test/ia_consentimento_app_test.dart`* |
| Lead | 0 / 3 | `ESTADO-DO-PROJETO.md`, `lib/features/auth/data/exclusao_de_conta.dart` + `test/auth_test.dart` (only if Phase 0 finds a new collection), the final numbers in CHECKLIST (coordinated after C), the commit |

`*` = new file.

**Frozen contract between A and E:**

- `PortaoIa` (`de`, `carregar`, `permitido`, `concedido`, `decidir`, `fixo`), `textoIaDesligada`, `TipoFalhaIa.naoAutorizada` (A); `garantirIa` (E implements it on top of `PortaoIa`)
- the single `RepositoryProvider<PortaoIa>` in `_comIa`; nobody else creates a `PortaoIa` in the app tree
- `DenunciasRepository.de`, `Denuncia`, `MotivoDenuncia`, the `onde` values (`tutor`, `por-que`, `palavra`, `escrita`, `conversa`, `conversa-resumo`)
- the keys `ia-consentimento`, `ia-permitir`, `ia-agora-nao`, `menu-ia`, `ia-denunciar`, `ia-denuncia-enviar`, `ia-denuncia-motivo-<name>`, `palavra-ia-desligada`

---

## 11. Validation (lead, Phase 3). One build of each kind, in this order

1. **Analyze and test.** Run `~/development/flutter/bin/flutter analyze lib test` (no warnings), then the full `flutter test`.
   - Expected: the previous total plus the new tests. Only the 5 known `csharp_curriculo_test` failures are allowed.
   - Delete any `test/_*_test.dart` leftovers.
2. **Fastlane dry checks.** These read no secrets and send nothing.
   ```bash
   cd /Users/fazplay/pac_dart && ruby -c fastlane/Fastfile
   FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_OPT_OUT_USAGE=1 FASTLANE_HIDE_CHANGELOG=1 PACLINGO_ENV=/nonexistent fastlane lanes
   FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_OPT_OUT_USAGE=1 PACLINGO_ENV=/nonexistent fastlane android verificar   # must fail: "Faltam PACLINGO_PLAY_JSON …"
   FASTLANE_SKIP_UPDATE_CHECK=1 FASTLANE_OPT_OUT_USAGE=1 PACLINGO_ENV=/nonexistent fastlane ios verificar       # must fail: "Faltam ASC_KEY_ID, …"
   ```
   **NEVER** run `interno`, `ficha`, `testflight` or `aab` through fastlane. Use `git status` to confirm that `fastlane/README.md` / `report.xml` are ignored.
3. **Gradle script check** (seconds, no build): `cd /Users/fazplay/pac_dart/android && ./gradlew help -q`. It must pass before the `.aab`. If it fails on the Kotlin script, fix `build.gradle.kts` first (this is what catches a `chaves.isEmpty` without parentheses).
4. **Android release.** Run `~/development/flutter/bin/flutter build appbundle --release`, then check:
   - The size: `ls -lh build/app/outputs/bundle/release/app-release.aab`. If it is over 190 MB, flag it in CHECKLIST as an owner decision (Play Asset Delivery or slimming `assets/ingles/voz`).
   - The signer: `keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab | grep SHA1` must start `8F:0B:C3:DD`. This prints a public certificate fingerprint; nothing secret.
   - 16 KB pages:
     ```bash
     mkdir -p <scratchpad>/aab && unzip -o -q app-release.aab 'base/lib/arm64-v8a/*.so' -d <scratchpad>/aab
     ~/Library/Android/sdk/ndk/28.2.13676358/toolchains/llvm/prebuilt/darwin-x86_64/bin/llvm-objdump -p <so> | grep LOAD
     ```
     Every `align` must be ≥ `2**14`. If not, record it for the owner.
   - The notification icon survived shrinking:
     ```bash
     unzip -l app-release.aab | grep -i ic_notificacao
     ```
     The file must be present, and `base/res/raw/keep.xml` must be absent from the output (it is consumed).
   - If Gradle fails over licenses, do NOT accept them for the owner. Write it into CHECKLIST ("rode `flutter doctor --android-licenses`") and continue with iOS.
5. **iOS release.** Run `~/development/flutter/bin/flutter build ios --release --no-codesign` (pod install runs automatically).
   - Check `du -sh build/ios/iphoneos/Runner.app`.
   - Check `/usr/libexec/PlistBuddy -c "Print :ITSAppUsesNonExemptEncryption" build/ios/iphoneos/Runner.app/Info.plist` gives `false`.
   - Check `CFBundleShortVersionString` = 1.0.0 and `CFBundleVersion` = 2.
   - **Do not** run `flutter build ipa` (signing is for the owner or the TestFlight lane).
6. **Screenshots** (cut level 4 of §3.1; do this once, after both native builds).
   1. `flutter build web -t lib/main_portfolio_probe.dart --release --output=build/probe --no-tree-shake-icons --no-wasm-dry-run`
   2. Serve on port 8789 (background), then run `node tool/lojas/capturas.mjs`.
   3. Look at every image (Read the JPEGs). Check: no consent sheet, no Turismo 3D, no DartPad, no voice warning, the text fits, **the streak reads 12 days (not broken, no freeze spent)** and **the "Revisão · N" count is small and plausible** (not inflated by a date mismatch).
   4. Stop the server, then `rm -rf build/probe build/lojas_cru`.
   5. **If the build or any capture fails:** do not rebuild. Delete `build/probe`, skip the `git rm` of the old images, and record "capturas novas pendentes" in CHECKLIST (§3.1).
7. **Deploy of `firestore.rules`.** The `denuncias`, `textos`, `palavras` and `setlists` blocks are all pending. Deploy only if the owner has explicitly authorized deploys in this round. The same authorization covers the TTL policy (`gcloud firestore fields ttls update expira --collection-group=denuncias --enable-ttl --project=pac-dart`). Otherwise both are item 3 of §12. Hosting needs no change from this track.
8. **Update `ESTADO-DO-PROJETO.md`:**
   - rewrite the "📲 Lojas" section, with the dated status, the audit results, the build sizes and SHA check, and links to fastlane/README-lojas.md and CHECKLIST;
   - add the new gotchas: keep.xml, `PortaoIa` default by Firebase presence, `deliver` metadata path, no iOS release notes for 1.0;
   - fix CHECKLIST §1–§6.
9. **Commit** with a message like `Lojas: consentimento e denúncia de IA, fichas pt-BR/en-US, capturas novas, fastlane e política atualizada`. Use the attribution lines, and do not push.

---

## 12. "🙋 O que só você faz" (goes into CHECKLIST, in order)

Each item has a tag: (👤) you, (🤖) Claude does it once you say so, (✅) already done at execution.

1. ⚠️👤 **Decidir a marca:** manter o Pac de boné e o nome "Prof. Dash", ou trocar para a v2 (mascote próprio) antes das capturas finais. Com o Pac, a loja pode recusar.
2. 👤 **Me passar o nome (ou empresa) e o e-mail de contato.** 🤖 Eu preencho as páginas e o `copyright.txt`, e tiro as páginas do `ignore`.
3. 👤 **Dizer "pode publicar".** 🤖 Eu rodo `firebase deploy --only firestore:rules` (textos, palavras, setlists e denúncias), ligo a limpeza automática das denúncias (`gcloud firestore fields ttls update expira --collection-group=denuncias --enable-ttl --project=pac-dart`, para a política dizer a verdade sobre os 12 meses) e publico o hosting com as páginas de privacidade.
4. 👤 **Fazer o backup** de `~/.paclingo/upload-keystore.jks` e da senha (em `android/key.properties`) num lugar seguro fora do Mac.
5. 👤 **Testar num celular de verdade** (Android e iPhone), com o `.aab` pelo teste interno e o TestFlight. Siga "O que testar" do `app-store.md`. Atenção a: som, voz, 🎤, teclado, lembrete, 🎧 Ouvir (para com a tela bloqueada, é esperado), pedido da IA e ⚑.
6. 👤 **Play Console:** criar o app (Paclingo, pt-BR, gratuito) e aceitar o App Signing. Depois, subir **à mão** o primeiro `build/app/outputs/bundle/release/app-release.aab` no teste interno.
7. 👤 **Play:** criar a conta de serviço, baixar o JSON para `~/.paclingo/play-service-account.json` e dar acesso a ela no Play Console.
8. 👤 **Play:** copiar os SHA-1/SHA-256 do "App Signing". 🤖 Eu cadastro no Firebase (`firebase apps:android:sha:create`).
9. 👤 **Apple:** confirmar que o Team `82C5YBT8U3` é o da conta da loja. Depois, registrar o Bundle ID `com.carlos.paclingo` e criar o app no App Store Connect (nome "Paclingo"; se estiver ocupado, "Paclingo: aprenda digitando").
10. 👤 **Apple:** criar a chave de API (.p8) em `~/.appstoreconnect/private_keys/` e preencher `~/.paclingo/fastlane.env` a partir de `fastlane/fastlane.env.exemplo` (chmod 600).
11. 👤 **Criar no app a conta de teste da revisão** (e-mail e senha) e pôr no `fastlane.env`.
12. 👤 **Rodar** (ou me pedir com você ao lado): `fastlane android interno`, `fastlane ios testflight`, `fastlane android ficha` e `fastlane ios ficha`.
13. 👤 **Preencher nos consoles** (as respostas estão prontas em `google-play.md` e `app-store.md`): Data safety, Privacidade do app, classificação (IA = sim), público-alvo 13+, acesso ao app (conta de teste), anúncios = não.
14. 👤 **Play (conta pessoal nova):** teste fechado com 12 ou mais testadores por 14 dias.
15. 👤 **Depois do 1º upload:** ligar o App Check (Play Integrity / App Attest) e prender as chaves de API ao app (CHECKLIST §3/§4). Não prenda por "referrer" a chave do Gemini que está no Firestore: o celular também a usa (engenheira de pista).
16. 👤 **Enviar para revisão,** nos dois consoles.

At execution, Claude marks ✅ in this order: the build, the texts, the screenshots, fastlane, the policy text (still with placeholders) and the version.

---

## 13. Edge cases and gotchas

- **`PortaoIa` default by Firebase presence.** The real app always initializes Firebase, so the gate is active. The probe and the old tests have no Firebase, so they get `liberado`. Document this in ESTADO, or someone will think the gate is missing.
- **Consent is per device.** On a new phone the app asks again. This is acceptable and stated in the policy.
- **The tutor panel suggestion chips** go through `_enviar`, so they are gated too. Check that no other path calls `TutorCubit.perguntar` (grep).
- **The privacy link inside the consent sheet** opens the app itself (hosting rewrite) until the pages are published. That is acceptable before submission, and checklist items 2 and 3 come before sending.
- **The fake rules parser:** see §5.6. The denúncias block has only `allow create`; a `allow read, update, delete: if false;` line would break the test's regex and is not needed (default deny).
- **One `PortaoIa` only.** It lives in `_comIa`; `_cursoDe` reads it with `ctx.read<PortaoIa>()`. A second instance would make the avatar-menu "desligar" miss one of the cubits until a restart. `ia_consentimento_app_test` guards it.
- **Load race.** `concedido` is false until the prefs load. Anything that decides whether to send uses `await portao.permitido()` (cubits, Turismo) or `garantirIa` (which awaits `carregar()`); the sync getter is only for the menu label.
- **No service wrapper.** Wrapping `GeminiTutorService` / `FirebaseAiTutorService` would hide track 2's `TutorJson` and silently drop the JSON schema path. The gate lives in the cubits; a test asserts the real services still implement `TutorJson`.
- **Word balloon.** It never opens a modal (it lives in a `TapRegion` overlay; a sheet would close it). Cache first; a refusal shows "IA desligada — ligue no menu do seu avatar.".
- **Report TTL.** Firestore deletes expired docs within about a day after `expira`, and only once the TTL policy exists. Without it, the 12-month promise is false.
- **`deliver` and first versions:**
  - It cannot set "What's New" on 1.0, so no `release_notes.txt` exists.
  - It needs the app record to exist.
  - `app_version` comes from pubspec.
- **supply's first upload:** the Play API cannot create the app or its first release for a brand-new app, so the first `.aab` must go through the console (item 6).
- **Keystore guard:** `flutter build apk --release` still works without the key. Only `bundleRelease` fails.
- **R8 and resources:** without `keep.xml` the drawable would be stripped and the reminder would silently break in release only.
- **Listing promises:** never "segundo plano" or "tela bloqueada". `lojas_metadados_test` and `nativo_config_test` guard it.
- **Keywords:** Apple counts characters (95). If ASC still complains, drop `teclado`.
- **The iPad set is required** while `TARGETED_DEVICE_FAMILY` contains 2. Changing to iPhone-only would remove the need, but that is not the default.
- **Screenshot honesty:** never Turismo 3D or the DartPad embed (web-only).
- **Heavy builds:** strictly sequential. Delete `build/probe` and `build/lojas_cru` after the captures. Keep the `.aab`, because the owner uploads it.
- **Capture dates.** The seeded habit and revision assume 14/10/2026; the capture clock is frozen on that day (§9.1). Freezing on the execution date would break the 12-day streak in scene 02 and inflate "Revisão · N".

---

## 14. Deferred (not this round)

- an app-level `ios/Runner/PrivacyInfo.xcprivacy` (the plugins and Flutter ship theirs; a project-file edit carries risk);
- background audio / lock-screen controls on native (`audio_service`, `UIBackgroundModes`);
- Play Asset Delivery for `assets/ingles/voz` (only if the AAB nears 200 MB);
- Play tablet screenshots (optional);
- en-US captioned screenshots;
- bundling the Google Fonts into the native app (offline and no IP leak);
- Bluetooth headset mic permissions;
- warning on native when the device lacks a pt-BR TTS voice (`voz_ingles.dart:330`);
- an emulator smoke run (only if the owner asks: it is another heavy build);
- App Check;
- API key restrictions;
- the trademark change;
- a CI pipeline.

---

## 15. Crítica considerada

All eleven points of the review were accepted and are in the plan:

1. Wrapper hides `TutorJson` → wrapper removed; `permitido` injected into `IaCubit`/`IaPalavrasCubit`/`TutorCubit`; `TipoFalhaIa.naoAutorizada` + `textoIaDesligada`; a test asserts the real services still implement `TutorJson` (§5.1, §5.3, §5.7, D15).
2. Single `PortaoIa` → `RepositoryProvider<PortaoIa>` keyed by uid in `_comIa`, read by `_cursoDe`; app test for the menu switch (§5.3, §6.5).
3. Load race → `permitido()` and `garantirIa` await `carregar()`; `tutor_cubit.dart` joins Group A with the pt-BR refusal and no technical detail (§5.1, §5.3, §6.1).
4. Word balloon → never opens the sheet, cache first, a single "IA desligada" line; test with 0 calls (§6.3, §6.5, D16).
5. Group E sites vs track 2 → ⚑ in `bolha_conversa.dart` and `resumo_conversa.dart` (`conversa-resumo`), both owned by E; `_Bolha`/`FeedbackCenarioView` checked in Phase 0 (§4, §6).
6. 12-month promise → `expira` field + TTL command in §12 item 3; policy draft reworded (§2 D4, §5.2, §5.5, §8.1).
7. `chaves.isEmpty` → `chaves.isEmpty()` plus `./gradlew help -q` before the `.aab` (§7, §11 step 3).
8. Capture dates and iPhone UA → clock frozen on 14/10/2026 with `hoje` derived from one constant; the whole `IPHONE` init script copied; visual check of streak and Revisão (§9.1, §11 step 6).
9. Rules → the `allow read, update, delete: if false;` line removed; `onde`/`motivo`/`plataforma` validated; string tests on the real file (§5.5, §5.6).
10. Sheets on a 360×640 phone → `isScrollControlled`, `viewInsets` padding, scroll, SafeArea, `Mixart.surface`; small-phone keyboard test (§6.1, §6.5).
11. Scope → cut order in §3.1; captures moved to the end of Phase 3 and droppable without redoing native builds.

Partially taken (one line each):

- Point 10, the fixed `0xFF141414` color: changed only in the avatar menu that this round edits; the other four fixed-color sheets (`baralhos_page`, `audio_da_frase`, `mapa_page`, `menu_trilhas`) are out of scope for a store round.
- Point 4, the optional "Usar a IA" button inside the balloon: not added; the balloon's context dies when it closes, and the line already points to the avatar menu.
