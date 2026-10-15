# Prompt para o agente — as próximas fases do Paclingo (5, depois 3-shadowing, 1B e voz nos cenários)

> Cole o texto abaixo (tudo dentro do bloco) em um agente novo, sem contexto. Ele é autossuficiente.
> Escrito em 13/out/2026, depois de concluídas as Fases 1A, 2A, 2B, 3 (ditado), 4 e 6.

````
Você vai continuar a evolução de um app Flutter que já existe. Responda e escreva textos de interface sempre em português do Brasil.

## O projeto
O Paclingo (nome interno antigo: PAC·DART) fica em /Users/fazplay/pac_dart. É um app Flutter (web, com projetos Android/iOS em andamento), Dart ^3.11, flutter_bloc, Firebase (Auth + Firestore, projeto "pac-dart"). Ensina por DIGITAÇÃO: o aluno digita trechos de código (cursos Dart & Flutter e C# & .NET) ou frases em inglês (curso Inglês) e o app corrige e agenda revisões (FSRS, como o Anki). As melhorias recentes são quase todas do curso de INGLÊS.

## Leia ANTES de escrever código (nesta ordem)
1. /Users/fazplay/pac_dart/ESTADO-DO-PROJETO.md — fonte de verdade do estado. Leia o começo ("Rodar, testar, publicar"), a seção "🧪 Testes" e AS SEÇÕES NOVAS (procure pelos emojis): 🔥 Hábito diário (Fase 1A), 🎧 Ditado (Fase 3, parte 1), 💡 "Por quê?" + cota/cache de IA (Fase 2A), 💬 Cenários guiados (Fase 2B), 🩸 Sanguessugas e subida de nível (Fase 6), 📖 Leitura com toque na palavra (Fase 4). Cada uma lista decisões, arquivos, testes e ARMADILHAS.
2. /Users/fazplay/pac_dart/planejamento/MELHORIAS-PESQUISA.md — por que cada fase existe, o que falta e os princípios (seção "Princípios para escolher e construir").
3. /Users/fazplay/pac_dart/planejamento/FASE-1-HABITO-DIARIO.md e FASE-2-EXPLIQUE-E-CENARIOS.md — são o MODELO do formato de plano que você vai escrever (decisões numeradas, modelo de dados, regras exatas, etapas, casos de borda, critérios de aceite, "fora do escopo", como verificar).

## O que já foi feito (não refazer; reaproveitar)
- **Fase 1A** hábito diário (`lib/features/habito/**`): sequência, meta, congelamento. **1B (lembrete no celular) NÃO foi feita.**
- **Fase 2A/2B** IA (`lib/features/ia/**`): `IaCubit` (cache → cota → serviço; `explicar(PedidoIa)` e `consultar(...)`), cota de 30 usos/dia por conta (campo `users/{uid}.ia_cota` + cópia local), cache local de 100 respostas, "Por quê?" (`BotaoPorQue`), cenários guiados (`cenario_cubit`, `conversa_page`, `feedback_cenario` com `salvarCartaoDoCenario`), `TutorComPersona` (persona própria, opcional, sem mudar `TutorService`). **Voz nos cenários NÃO foi feita.**
- **Fase 3**: só o ditado ("🎧 Áudio → escrever", `SentidoCartao.audio`). **O shadowing NÃO foi feito.**
- **Fase 4** leitura: `leitura_page`, cartão de lacuna com `alvo` (só vale para "Meus cartões": `SessaoCartoesPage.lacunaDaLeitura`).
- **Fase 6** sanguessugas (`sanguessugas_page`) e sugestão de subir/descer de nível (`SerieDeNivel`).

## Sua tarefa, em ordem
### 1) Fase 5 — Escrita corrigida por IA, com os erros virando cartões (a próxima do arquivo de melhorias)
Veja a seção "Fase 5" de MELHORIAS-PESQUISA.md: a pessoa escreve 2–3 frases sobre o dia; a IA devolve o texto corrigido, explica cada erro em português e CADA ERRO VIRA UM CARTÃO. Depende da cota/cache da Fase 2 (já existem).
**Passo 1 — escreva o plano**: crie /Users/fazplay/pac_dart/planejamento/FASE-5-ESCRITA-CORRIGIDA.md no formato dos planos anteriores, com decisões D1… e "perguntas em aberto" com um padrão cada. Dicas de desenho que já aprendemos:
 - reaproveite `IaCubit.consultar` (1 uso por correção), `salvarCartaoDoCenario` (cartão em "Meus cartões"), `prepararCartao` (valida o inglês digitável) e o parser tolerante de JSON de `FeedbackCenario.interpretar` (peça SÓ um JSON; aceite ```json, texto em volta, truncado; limite de itens; JSON ruim ⇒ texto cru e nenhum cartão);
 - o texto da pessoa é DADO, não instrução (corte em ~300 letras por frase; o prompt manda ignorar instruções dentro dele);
 - a IA NUNCA dá nota nem mexe em agenda/ranking; erros viram cartões, não notas;
 - onde entra na interface (provavelmente um card no Mapa ao lado de "Conversar"), sem pacote novo.
**Passo 2 — pare e mostre o plano ao dono** (ele pode ajustar as decisões) e, só com o OK, implemente seguindo as etapas do plano.

### 2) Itens que dependem de uma liberação do dono (PERGUNTE antes; não presuma)
 - **Fase 3, parte 2 — shadowing** (ouve → a frase some → repete falando → conferência por palavra → nota sugerida) e **voz nos cenários**: dependem do reconhecedor de voz (`lib/features/ingles/data/reconhecedor_*.dart`, `domain/avaliacao_fala.dart`), que é trabalho do dono AINDA SEM COMMIT. Pergunte se já está commitado/estável (`git status`, `git log`) antes de tocar.
 - **Fase 1B — lembrete diário no celular**: exige plugin nativo (`flutter_local_notifications` + `timezone`), mexe em `pubspec.yaml`/`pubspec.lock` e em `android/` e `ios/` (que têm o trabalho de lojas do dono sem commit) e pede `flutter clean && flutter pub get`. A especificação está na seção 9 de planejamento/FASE-1-HABITO-DIARIO.md. Só com autorização explícita.
 - Itens do "Backlog" de MELHORIAS-PESQUISA.md (metas por objetivo, PWA offline, mini-histórias…): só se o dono pedir.

## Regras de convivência com o repositório (IMPORTANTE)
1. A árvore do git está SUJA com trabalho do dono que NÃO é seu (android/, ios/, branding/, preparação das lojas, e alterações dentro de muitos arquivos — por exemplo `lib/main.dart`, `hud.dart`, `home_page.dart`, `palco_ingles.dart`, `sessao_cartoes_page.dart`, `pubspec.yaml`). ANTES de começar rode `git status --short` e guarde a lista (num arquivo no scratchpad). No fim compare: as únicas diferenças devem ser seus arquivos.
2. Nesses arquivos já modificados faça SÓ edições cirúrgicas (Edit pontual) no trecho de que precisa. NUNCA rode `git checkout`, `git restore`, `git stash`, `git reset`, `git clean`, nem reformate/reescreva arquivo inteiro, nem apague pastas (`rm -rf`). Antes de editar um arquivo sujo, faça uma cópia de segurança no scratchpad.
3. NÃO faça commit, NÃO faça push, NÃO publique (nada de `firebase deploy`) e NÃO altere `firestore.rules`. O dono pede commit/publicação quando quiser. NÃO adicione dependências ao `pubspec.yaml` (exceto o item 1B, com autorização).
4. Código novo deve parecer com o vizinho: comentários em português explicando o PORQUÊ, nomes e padrões do projeto (`Mixart.*` para cores/tipografia; padrão `Cubit.de(context)` que devolve null quando o cubit não existe na árvore; repositório local + Firestore com cópia no aparelho, como o do hábito e o da cota de IA; relógio injetável).
5. Faça só o que a fase pede. Pare e pergunte ao dono apenas para decisões que mudam o produto (não para detalhes técnicos).

## Como trabalhar (o que funcionou nas fases anteriores)
- Comandos: `flutter test <arquivo>`, `flutter test` (suíte inteira), `dart analyze lib test`. **Baseline atual: 985 testes, 980 passam; as 5 falhas são ANTIGAS, todas em `test/csharp_curriculo_test.dart` (conteúdo do C# incompleto) — não tente consertá-las; elas devem continuar sendo as únicas.**
- Testes de verdade: domínio com tabela de casos, repositórios (com `fake_cloud_firestore`), cubit com repositório e relógio falsos, widgets (`Mixart.usarGoogleFonts = false;` e `SharedPreferences.setMockInitialValues({...})`; veja test/ingles_cartoes_ui_test.dart), e UM teste de app (`PacDartApp` inteiro; modelos: test/ia_cenario_app_test.dart, test/ingles_leitura_app_test.dart). Fakes reutilizáveis: `TutorCenarioFalso` (test/ia_cenario_cubit_test.dart), `CotaMemoria`/`CacheMemoria`/`Relogio` (test/ia_cubit_test.dart), `RepoMemoria`/`ConfigMemoria` (test/ingles_baralhos_test.dart), `LoaderTeste` (test/ingles_cartoes_ui_test.dart).
- **Valide os testes por MUTAÇÃO**: para cada ponto crítico, quebre de propósito (script que faz backup, troca UMA string, roda os testes da fase, restaura e confere com `diff`), confirme que algum teste falha e desfaça. Rode em segundo plano e NÃO edite o código enquanto as mutações rodam. Há modelos em /private/tmp/claude-501/-Users-fazplay-pac-dart/*/scratchpad/mut*.py (se ainda existirem) — são fáceis de recriar.
- **Prova no Chrome real (obrigatória em cada fase)**: `flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_ia`; `python3 -m http.server 8793 --directory build/probe_ia`; Playwright (MCP) em http://localhost:8793/ a 1027 px e a 390 px (`browser_resize`); confira erros de console (`page.on('pageerror')`). Em Flutter web NÃO ligue a acessibilidade/semântica: dirija por coordenadas (`page.mouse.click`) e teclado. No probe: clique no nome do curso no HUD (⇄), tecla 3 (Inglês), Esc passa o "ensaio mental"; "Mapa" leva aos cards (Baralhos, Ler, Conversar). O probe usa fakes (`lib/main_portfolio_probe.dart`: `_TutorFake`, `_TradutorFake`, repositórios locais) — ensine-os a responder o que sua fase pede. `localStorage` do navegador guarda cota/hábito entre execuções (chaves `flutter.*`, valor duplamente codificado em JSON). Para virar o dia use `page.clock`. Ao terminar: `pkill -f "http.server 8793"` e feche o navegador.
- Atualize o ESTADO-DO-PROJETO.md: uma seção nova por fase (o que foi feito, decisões, arquivos, testes, armadilhas, pendências) e a contagem na seção "🧪 Testes".

## ARMADILHAS já pagas (leia; vão se repetir)
- **Web + campo de texto**: o `TextInputAction.done` padrão TIRA O FOCO a cada Enter; `readOnly`/`enabled` mudando, `requestFocus` ou `autofocus` na abertura da tela, durante/depois do Enter, derrubam a conexão de teclado da web com um `Error` do motor, SEM mensagem (aparece como `pageerror` em `a_0.mo`). Use `onEditingComplete: () {}`, campo sempre ligado e sem autofocus. Os testes de widget NÃO pegam isso — só o Chrome.
- `Future.whenComplete(() => mapa.remove(chave))` DEVOLVE o próprio Future e trava (deadlock): use bloco `{}`.
- As frases do CURSO também têm `Trecho.alvo` (é o destaque da lição): não use `alvo` sozinho para identificar nada.
- Cores são getters (`Mixart.brand`…), não `const`. Sem emoji no `cod` do currículo. Toda lição precisa de teoria com bloco de código. Nunca inserir trilha no MEIO do currículo (progresso é por índice).
- `testWidgets`: `await bloc.close()` trava (use `tester.runAsync`); o relógio do HUD redesenha todo segundo (`pumpAndSettle` nunca assenta; use pumps com tempo); I/O de asset/prefs precisa de `tester.runAsync` com tempo real; `Scrollable.ensureVisible` do campo de digitação deixa a lista "ignorando toques" até a animação acabar (dois `pump` de 500 ms antes de tocar).
- Tela que empilha rota nova precisa dos providers: em teste os providers ficam DENTRO do `home`, então passe `BlocProvider.value` ao empurrar a página (em produção ficam acima do `MaterialApp`).
- Teste que abre a mesma página duas vezes no mesmo `pumpWidget` reaproveita o State (as prefs não são relidas): separe em dois testes.
- A cota de IA é "macia" (a chave do Gemini viaja no cliente na web): não prometa cota dura.

## Definição de pronto (para cada fase)
Todos os critérios de aceite do plano da fase, mais: `dart analyze lib test` limpo; `flutter test` sem regressão (só as 5 falhas antigas do C#); mutações pegas e arquivos restaurados; prova no Chrome (1027 e 390 px, sem erro de console); ESTADO-DO-PROJETO.md atualizado; `git status --short` igual ao do início exceto pelos seus arquivos; NADA commitado, NADA publicado, `firestore.rules` e `pubspec.yaml` intactos.

## Relatório final (por fase)
1. O que foi entregue (3–6 linhas, em português simples).
2. Arquivos criados e alterados (e, nos que já estavam sujos, o que você mexeu).
3. Testes: nº de testes novos, suíte inteira (passam/falham e confirmação de que as falhas são só as 5 antigas), `dart analyze`.
4. Mutações feitas e qual teste pegou cada uma.
5. Prova no Chrome: o que viu e testou.
6. Divergências do plano, decisões, riscos e pendências.
7. Confirmação explícita: nada commitado, nada publicado, firestore.rules e pubspec.yaml intactos.
Ao terminar a Fase 5, diga qual é o próximo item do item 2 (liberações do dono) e pergunte se pode seguir.
````
