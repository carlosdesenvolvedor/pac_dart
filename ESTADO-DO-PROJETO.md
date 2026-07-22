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

# testar (41 testes) e analisar
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

**Dados:** `assets/curriculo.json` (trilhas → lições → trechos + `resumo` + `teoria`), `assets/master.json` (30 apps), `assets/backgrounds/*.jpg` (fundo por trilha).

---

## ✨ Features (o que existe)

- **Motor de digitação** Pac-Man: auto-indentação, backspace inteligente, acentos/IME (dead keys).
- **Auto-scroll** do código (a caixa acompanha o Pac-Man) + **altura limitada** (não empurra o console).
- **Botão "copiar"**: gera código **rodável** (Flutter vira `main()+MaterialApp`, Dart fica completo) pra colar no DartPad/IDE.
- **3 paletas** (Mixart escuro / Flutter claro / Flutter escuro) com **seletor de tema** (HUD e login), persistido por dispositivo.
- **Login e-mail/senha** (Firebase Auth) + **progresso na nuvem** por usuário (Firestore).
- **Mapa da Jornada**: caminho zigue-zague, dashboard, e **busca por nome** (lições + projetos + apps).
- **Teoria / Nivelamento** por lição (texto simples + exemplos, blocos h/p/code/tip/warn).
- **Quiz** por lição (até 10 perguntas; escolhe a alternativa e digita o código).
- **Fundos temáticos** por trilha (foto escurecida, clima de "fase de jogo").
- **Prévia Flutter AO VIVO**: o app se monta na telinha conforme você digita (nos apps Mão na Massa / Master).
- **Narração por voz** (TTS pt-BR) das dicas.

---

## 🏗️ Arquitetura (arquivos-chave)

```
lib/
  main.dart                     # gate de auth ACIMA do MaterialApp; ThemeCubit+AuthCubit no topo
  core/theme/
    mixart.dart                 # Paleta (3 temas) + Mixart.* (getters dinâmicos!) + tema()
    theme_cubit.dart            # troca/persiste a paleta
    seletor_tema.dart
  core/syntax/tokenizer.dart    # destaque de sintaxe
  core/util/codigo_executavel.dart  # gera código rodável (botão copiar)
  features/auth/                # AppUser, AuthRepository (FirebaseAuth), AuthCubit, LoginPage
  features/curso/
    domain/curriculo.dart       # Trilha, Licao, Trecho, BlocoTeoria, Projeto
    data/                       # CurriculoLoader, ProgressoRepository (Local + Firestore)
    presentation/
      bloc/                     # CursoBloc, TypingBloc, VozCubit
      pages/                    # home_page, mapa_page, teoria_page, quiz_page, projeto_page
      widgets/                  # code_view, hud, menu_trilhas, dica_banner, console_view,
                                # preview_panel, preview_ao_vivo, fundo_fase, pacman, victory_overlay
  features/preview/             # interpretador próprio (parser + widget_builder) + preview_engine
  firebase_options.dart         # gerado por flutterfire configure
assets/  curriculo.json · master.json · backgrounds/ · fonts (google_fonts em runtime)
```

Estado: `flutter_bloc`. Cores via `Mixart.*` (getters que seguem `Mixart.atual`).

---

## 🔥 Firebase

- Auth **Email/senha** habilitado (feito no console; Identity Platform pago exige billing, o grátis é só o toggle).
- Firestore: doc por usuário `users/{uid}` (concluidas[], quizNotas{}, trilha, licao, recorde). Regras em `firestore.rules`: **só o dono acessa**.
- `firebase.json` (hosting → build/web + SPA rewrite; firestore rules/indexes), `.firebaserc` (default: pac-dart).
- Trocar `ProgressoRepository` local por Firestore já está feito (`FirestoreProgressoRepository`).

---

## ⚠️ Armadilhas (gotchas) — leia antes de mexer

1. **Firebase web:** `flutter clean` antes de buildar quando mexer em plugins (senão channel-error / tela branca).
2. **Cores são getters (não const):** por causa dos 3 temas, `Mixart.brand` etc. NÃO podem ir em contexto `const`. Default de parâmetro que era `= Mixart.x` vira nullable + `?? Mixart.x`.
3. **Acentos:** campo oculto usa `TextInputType.text` e `_processaTexto` espera a composição terminar (`if (!_ctrl.value.composing.isCollapsed) return;`). Vale em `code_view.dart` e no quiz.
4. **Prévia ao vivo:** `preview_ao_vivo.dart` balanceia brackets/aspas do código parcial + apara token incompleto (trim-retry); só renderiza **árvore de widget** (não classe StatefulWidget). Cod dos apps Flutter deve ser expressão de widget começando por Scaffold/Column/Card/Center.
5. **Validar Dart:** `dart run` roda dentro do projeto imprime "Running build hooks..." no stdout — rodar com `cwd` num diretório temporário fora do projeto.
6. **Verificação visual (headless):** `Chrome --headless=new --disable-gpu --enable-unsafe-swiftshader --force-device-scale-factor=1` servindo `build/web`; usar largura **≥600px** (headless tem largura mínima que distorce abaixo disso). Headless NÃO carrega os módulos ES do Firebase (gstatic) — pra checar o boot, ler o console (`--enable-logging=stderr`) e ver "Initializing Firebase" sem "channel-error".
7. **Ordem das trilhas:** progresso é keyed por `"trilhaIdx:licaoIdx"`. **Nunca inserir trilha no meio** — só no fim — senão quebra o progresso salvo.
8. **Sem emoji no `cod`:** emoji não é digitável e vira "tofu"/ratinho na fonte mono. Já há testes que barram isso.
9. **Motor de prévia (projetos `flutter:true`) — só um SUBSET:** o `cod` deve ser UMA expressão de widget LITERAL começando por `Scaffold(`/`Center(` (sem variáveis/funções/setState/classes). O interpretador **não** entende: `Color(0xFF...)` (use `Colors.*`), tipos genéricos `Widget<Tipo>(...)` (ex.: `DropdownButton<String>`), `Sliver*`, `PageView`, `CustomPaint`, `FilledButton`, `LayoutBuilder`, `MediaQuery`, `Theme.of`. `SizedBox(height:N)` sem filho vira, **de propósito**, uma caixinha de contorno azul-claro (marca o espaço). Valide qualquer app novo com `PREVIEW_JSON=arquivo.json flutter test test/tools/preview_check.dart` — tem que dar **status OK** (raiz parseia inteira), não "PARCIAL".
10. **Toda lição PRECISA de ≥1 bloco `teoria` do tipo `code`** (o `teoria_test` exige). Lições de comparação/decisão também.
11. **Subagentes podem deixar lixo no projeto:** ao gerar conteúdo em massa, eles às vezes criam arquivos `*_check.dart`/`tmp_*.dart` em `test/tools/` ou na raiz pra validar render. Faça uma varredura (`find . -name '*.dart'` fora de `lib/` e não-`_test`) e remova antes do `flutter analyze`/deploy. O único arquivo legítimo em `test/tools/` é `preview_check.dart`.

---

## 📋 Pendências / próximos passos

- ⚠️ **Commit + push do código desta sessão pro GitHub** (o repo só tem o commit inicial). Fluxo: `git add . && git commit && git push` (remote já configurado). O `firebase_options.dart` pode ir (a chave web do Firebase é pública por design).
- Adicionar os **topics** no GitHub (flutter, dart, bloc, typing-game, education, pacman) — precisa do agente do Chrome no site.
- (opcional) Sincronizar o **tema por usuário** (hoje é por dispositivo, no shared_preferences).
- (opcional) Sons de arcade (waka-waka), modo cronometrado, mais apps.

---

## 🧪 Testes (41, todos passando)

`test/`: typing_bloc · preview_engine · preview_cobertura · quiz · teoria · projetos (30 apps) · auth · theme · app_smoke. Rodar: `flutter test`.
