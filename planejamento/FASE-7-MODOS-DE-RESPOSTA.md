# Fase 7 — Modos de resposta nas lições do Inglês: ⌨️ Digitar · 🎤 Falar · 🧩 Montar

> ✅ **IMPLEMENTADA em 13/out/2026** (sem commit/deploy) — o que saiu, as divergências deste plano e a prova estão em `ESTADO-DO-PROJETO.md`, seção "🧩 Modos de resposta — Fase 7".

> Plano para execução por um agente. Escrito em 13/out/2026, a pedido do dono ("não encontrei no celular a opção de digitar; quero nas trilhas também a opção mic, digitar e aquele de
> montar com as palavras, igual fizemos em outro lugar"). Contexto geral: [`MELHORIAS-PESQUISA.md`](MELHORIAS-PESQUISA.md). **Só o curso de Inglês** (Dart e C# digitam código).
> ⚠️ **Antes de executar:** use o SDK novo (`~/development/flutter`; reinicie o Claude Code se o `which flutter` ainda mostrar `~/Documents/...`) e siga as regras de build em
> `ESTADO-DO-PROJETO.md`/memória: **UMA pasta de probe (`build/probe`), apagada no fim; nada de build web em loop**; prefira `flutter test`.

## 1. Objetivo e o que a pessoa vai ver

Hoje a lição do Inglês só tem UM jeito visível de responder: digitar (e no celular o teclado só abre se a pessoa **tocar na frase** — a dica fica no rodapé, por isso "não achei a opção de digitar"). O 🎤 aparece
só no celular, ao lado do "não sei". O "montar com blocos" (estilo Duolingo) existe **só nos cartões de revisão** (nível "Fácil").

Nova **barra de modos** acima da frase de cada passo da lição:

| ⌨️ Digitar | 🎤 Falar | 🧩 Montar |
|---|---|---|
| o que existe hoje, com um botão visível que **abre o teclado** no celular | a pessoa diz a frase; conferência por palavra (`avaliarFala`, a do palco) | a tradução em cima e **blocos de palavras** (com 2–5 de enfeite) embaixo; toca na ordem e **Conferir** |

- A escolha é **lembrada neste aparelho** (pref). Padrão: ⌨️ Digitar em todo lugar (inclusive celular).
- No celular, **Falar e Montar não abrem o teclado**; **Digitar** abre.
- **Falar** só aparece se o navegador/aparelho reconhece voz (`ReconhecedorFala.suportado`); senão a barra mostra só Digitar e Montar (o 🎤 do teclado do iOS/Android segue valendo no Digitar, via `aoDitar`).
- O que aparece da frase em inglês **continua obedecendo ao degrau** (Copie / Iniciais / Esqueleto / De memória): montar não entrega a resposta nos degraus de memória.
- No **computador nada muda** (padrão Digitar; teclado físico, Enter, Tab, Esc iguais).

## 2. Decisões (as 3 primeiras o dono escolheu em 13/out/2026; o resto o agente segue)

| # | Decisão | Por quê |
|---|---|---|
| D1 | **Só Inglês.** | Dart/C# são código. |
| D2 | **Nota do montar: vale em todos os degraus, mas na PROVA final (D5) um montar certo conta só "tropeçou" (meio ponto).** Montar errado vale como errou, igual a digitar. Digitar e Falar valem inteiro. | Montar é RECONHECER; digitar de memória é LEMBRAR — o diferencial do app. Mesma ideia do 👁 ("frase à vista": meio ponto na prova). *(escolha do dono)* |
| D3 | **Modo inicial: ⌨️ Digitar em todo lugar**; a pessoa troca na barra e o app lembra a última escolha por aparelho (`SharedPreferences`, chave `en_entrada`). *(escolha do dono)* | Mantém o diferencial; sem surpresa para quem já usa. |
| D4 | **Enfeites no montar: 2 a 5 blocos a mais** (`quantosDistratores`), tirados das outras frases da lição e, se faltar, de `palavrasDeReservaEn` — a MESMA lógica `montarBlocos` dos cartões. *(escolha do dono)* | Reuso; obriga a pensar. |
| D5 | **Reuso total dos blocos dos cartões:** `Bloco`, `montarBlocos`, `conferirBlocos` (em `domain/nivel_resposta.dart`) e a pastilha visual (hoje `_Pastilha` privada em `sessao_cartoes_page.dart` → **extrair** para `widgets/pastilha.dart`, público). | Nada de lógica duplicada. |
| D6 | **O montar entra pelo caminho que a FALA já usa:** erros por palavra vão para `FraseViewState.errosDeFala` (posição da 1ª letra da palavra, como `responderPorVoz`) e a frase concluída dispara `TrechoFalado` no `TypingBloc`. O palco (`_concluiu`) **não muda** na avaliação: `somarErros(st.errosPorPosicao, fv.errosDeFala)` já soma. | O caminho está provado e testado (Fase 3/palco). |
| D7 | **Montar errado: tentativas ilimitadas, cada "Conferir" errado soma 1 erro nas palavras erradas** (as pastilhas erradas ficam em vermelho, as certas em verde); "não sei" (que já existe) revela a frase e vira cópia. **Conferir** é botão (Enter também confere no teclado físico); não confere sozinho ao colocar o último bloco. | Estilo Duolingo ("Verificar"); a nota cai com os erros. |
| D8 | **Sem IA, sem cota, sem Firestore, sem ranking novo.** A lição conta no hábito/ranking como sempre (a contagem é por passo concluído, qualquer modo). | Escopo. |
| D9 | **O campo de texto escondido (digitação) NUNCA fica `readOnly`/`enabled` mudando e não ganha `autofocus`** (armadilha da web: derruba a conexão do teclado com um erro do motor). Trocar de modo só deixa de pedir foco e, no celular, esconde o teclado (`TextInput.hide`). | Armadilha já paga (cenários/escrita). |
| D10 | **Sem pacote novo, sem `pubspec.yaml`, `firestore.rules`, `android/`, `ios/`.** Edições **pontuais** nos arquivos sujos do dono (`frase_view.dart`, `palco_ingles.dart`, `sessao_cartoes_page.dart`), com backup. | Regras de convivência. |

### Perguntas em aberto (o agente usa o **padrão** e registra no relatório final)
1. **Falar no computador:** aparece se `suportado` (Chrome desktop reconhece). Padrão: **sim**.
2. **Montar também na "Revisão do dia"** (`SessaoMemoriaPage`)? Padrão: **não** (os cartões já têm o "Fácil"; fora do escopo).
3. **Atalho de teclado para trocar de modo** no computador? Padrão: **não**.
4. **A frase certa aparece no montar do degrau "Copie"** (a frase à vista)? Padrão: **sim** (é o degrau de cópia; o modo mostra a frase como sempre).

## 3. Contexto técnico

- `lib/features/ingles/presentation/palco_ingles.dart` — a lição: `FilaLicao` (escada D1–D5: `Degrau.conhecer/iniciais/esqueleto/memoria/prova`), `PassoFila.modo` (`ModoFrase`), `_carregarPasso`, `_concluiu` (monta o `DesempenhoFrase` com `avaliarDigitacao(..., errosPorPosicao: somarErros(...))`), `_avancar` (registra na fila), `FraseView(modo:…, onMicrofone:…)`. As chamadas `_foco.requestFocus()` (várias) abrem o teclado no celular.
- `lib/features/ingles/presentation/widgets/frase_view.dart` — a frase, o campo escondido, o `TypingBloc`, o microfone (`alternarMicrofone`, `_barraDeVoz`, `responderPorVoz`, `_errosFala`, `_pediuParar/_forcaFim` — **proteção contra microfone preso, não quebrar**) e `_tocou()` (abre o teclado).
- `lib/features/ingles/domain/nivel_resposta.dart` — `Bloco`, `montarBlocos`, `conferirBlocos`, `quantosDistratores`, `palavrasDeReservaEn`.
- `lib/features/ingles/presentation/sessao_cartoes_page.dart` — `_montagemComBlocos`, `_Pastilha`, `_pegarBloco/_soltarBloco`, `_conferir`: **o molde da interface do montar**.
- `lib/features/curso/presentation/bloc/typing_bloc.dart` — `TrechoFalado` ("trecho concluído sem teclas contadas").
- `lib/features/ingles/domain/avaliacao.dart` — `avaliarDigitacao`, `somarErros`, `palavrasDe`.
- ⚠️ Arquivos já sujos (trabalho do dono): faça **backup no scratchpad e `Edit` pontual**; nada de `checkout/restore/stash/reset/clean`. `git status --short` no início e no fim.

## 4. Modelo (Dart puro no domínio)

`lib/features/ingles/domain/entrada_resposta.dart`:

```
enum EntradaResposta { digitar('digitar','⌨️','Digitar'), falar('falar','🎤','Falar'), montar('montar','🧩','Montar') }
  static EntradaResposta? porId(String? id)                  // id desconhecido/antigo ⇒ null (cai no padrão digitar)
  static const padrao = EntradaResposta.digitar

ResultadoRevisao notaDaEntrada(ResultadoRevisao r, {required EntradaResposta entrada, required Degrau degrau})
  // montar + prova + acertou ⇒ hesitou (meio ponto); o resto não muda; nunca melhora uma nota
```

`lib/features/ingles/presentation/widgets/seletor_entrada.dart` — `SeletorEntrada(entrada, falarDisponivel, onMudar)` (pílulas 360 px sem estouro, `Key('entrada-digitar')` etc., tema claro/escuro).
`lib/features/ingles/presentation/widgets/montagem_frase.dart` — `MontagemFrase(frase, apoio, extra, semente, onErrou(posicoesDasPalavrasErradas), onCerta, onNaoSei)`: monta os blocos uma vez por passo (mesma semente ⇒ mesmos blocos), escolhidos/soltos, "Conferir".

## 5. Regras (o que os testes de domínio precisam provar)

**`notaDaEntrada` (tabela):** digitar/falar nunca mudam a nota · montar nos degraus Copie/Iniciais/Esqueleto/De memória não muda · **montar na prova: acertou ⇒ hesitou; hesitou ⇒ hesitou; errou ⇒ errou** · nunca devolve nota melhor que a entrada.
**`EntradaResposta.porId`:** ids válidos ida e volta; `null`/`''`/`'xyz'`/de outro tipo ⇒ null; padrão digitar.
**Montagem:** frase com N palavras ⇒ N blocos certos + 2..5 enfeites que **nunca repetem** palavra da frase (`montarBlocos`); mesma semente ⇒ mesmos blocos; frase sem palavra ⇒ sem montagem (mostra só "não sei"); Conferir com blocos certos na ordem ⇒ concluída; palavras certas em outra ordem ou erradas ⇒ erros nas palavras que NÃO casaram (índices da frase) e as pastilhas ficam marcadas; Conferir sem nenhum bloco ⇒ nada.

## 6. Passo a passo

**Etapa 1 — Domínio** · `domain/entrada_resposta.dart` + pref (`PrefsEntrada` com `carregar()/salvar()` tolerantes) · `test/ingles_entrada_test.dart` (tabelas da seção 5).
**Etapa 2 — Pastilha compartilhada** · extrair `_Pastilha` de `sessao_cartoes_page.dart` para `widgets/pastilha.dart` (público, mesmo visual); **os testes dos cartões (`ingles_cartoes_ui_test`, `ingles_ditado_test`, `ingles_shadowing_*`) continuam verdes sem mudar**.
**Etapa 3 — `MontagemFrase`** · widget + `test/ingles_montagem_ui_test.dart` (blocos/enfeites, tocar e soltar, Conferir certo/errado/ordem trocada, marcação das pastilhas, "não sei", troca de passo zera, 360/390/1027 px, tema claro).
**Etapa 4 — `SeletorEntrada`** · widget + testes (3 pílulas, Falar some sem suporte, 360 px, pref ida e volta, id inválido volta ao padrão).
**Etapa 5 — `FraseView`** · parâmetro `entrada` (padrão `digitar` ⇒ **zero mudança** para quem não usa): Digitar mantém tudo + botão visível que abre o teclado (`_tocou`); Falar mostra o painel do microfone em destaque (reusa `_barraDeVoz`) e esconde o cursor do Pac-Man; Montar mostra `MontagemFrase` no lugar do campo e alimenta `errosDeFala`/`TrechoFalado` (D6); Falar/Montar chamam `TextInput.hide` e **não** pedem foco (D9). Testes `test/ingles_entrada_frase_test.dart` com `TypingBloc` e reconhecedor falso (o mesmo molde de `ingles_fala_test.dart`/`ingles_microfone_travado_test.dart`).
**Etapa 6 — Palco** · carrega/salva a pref, guarda a escolha em `_entrada`, mostra o `SeletorEntrada` entre o `TraducaoCard` e a `FraseView`, **só pede foco** (`_foco.requestFocus()`) quando `_entrada == digitar`, e em `_concluiu` aplica `notaDaEntrada` (D2). Teste de app `test/ingles_entrada_app_test.dart` (modelo `ia_cenario_app_test.dart`): lição → Montar → monta certo → o passo avança e conta 1 no hábito; prova montada certa ⇒ meio ponto; troca de modo no meio; lembra a escolha depois de reabrir; **modo Digitar idêntico ao de hoje**.
**Etapa 7 — Mutações** (script no scratchpad; backup → troca UMA string → roda os testes da fase → restaura e confere por **hash**; em segundo plano e **sem editar o código enquanto roda**). **Etapa 8 — Chrome** (UMA pasta `build/probe`, sobrescrita; emulação de iPhone com `addInitScript` — user agent iPhone + `navigator.platform='iPhone'`; **limpar o `serviceWorker`/`caches` antes de reprovar**; o botão "Parar" e outros DESCEM quando aparecem linhas novas: confira as coordenadas por screenshot) a 1027 px e 390 px, sem erro de console; **apagar `build/probe` no fim**. **Etapa 9 — `ESTADO-DO-PROJETO.md`** (seção nova + contagem de testes + pendências) e relatório.

## 7. Casos de borda (todos viram teste)

Frase de 1 palavra · sem palavra (só pontuação) · palavras repetidas na frase ("very very good": os dois blocos "very" valem em qualquer posição certa) · enfeite igual a palavra da frase (nunca) · apóstrofo/hífen ("don't", "well-known") · número ("7:30") · frase de 25 palavras (blocos em várias linhas, 360 px) · soltar um bloco no meio · Conferir sem nada · errar 3× a mesma palavra (soma 3 e a nota cai) · "não sei" no montar (vira cópia e **não** conta como nota boa) · trocar de modo no meio do passo (o passo reinicia limpo, sem perder o que já valeu) · trocar de passo com blocos escolhidos (zera) · voltar à lição depois de sair · pref estragada/id antigo (cai em Digitar) · sem suporte de voz (barra sem Falar) · microfone preso (a proteção da Fase "microfone preso" continua valendo) · teclado do celular aberto ao trocar para Montar (fecha) · lição repetida/vitória · tema claro · 360 px e fonte de teste · desktop (Digitar/Enter/Tab/Esc idênticos).

## 8. Critérios de aceite

- [ ] No celular a barra **⌨️ Digitar · 🎤 Falar · 🧩 Montar** aparece em cada passo; **Digitar abre o teclado com um toque no botão** (sem precisar adivinhar tocar na frase).
- [ ] **Montar** mostra a tradução em cima e os blocos (com 2–5 de enfeite); Conferir certo conclui o passo; errado marca as palavras e soma erros; "não sei" revela.
- [ ] **Falar** usa a conferência por palavra e conta como digitado; some se o navegador não reconhece voz.
- [ ] **Nota:** montar certo na **prova** conta meio ponto; nos outros degraus vale normal; digitar/falar valem inteiro; montar errado vale errou.
- [ ] A escolha é **lembrada**; o padrão é Digitar; no computador o fluxo é idêntico ao de hoje (testes antigos do palco/`FraseView` verdes sem mudar).
- [ ] Falar/Montar **não abrem o teclado** no celular; o campo escondido não é `readOnly`/`autofocus` (nenhum `pageerror` no Chrome).
- [ ] Hábito e ranking contam como sempre (1 por passo, qualquer modo); nada vai ao Firestore além do que já ia.
- [ ] `dart analyze lib test` limpo; `flutter test`: só as 5 falhas antigas do C# (`csharp_curriculo_test`); testes novos verdes.
- [ ] **Mutações pegas** (restaurar por hash): (a) montar na prova valendo inteiro; (b) montar errado valendo certo; (c) enfeite repetindo palavra da frase; (d) erros do montar não somando; (e) Conferir sem nada concluindo; (f) pref não lembrada/id estranho quebrando; (g) Falar sem suporte aparecendo; (h) Montar pedindo foco/abrindo o teclado; (i) modo Digitar mudando (regressão); (j) trocar de passo sem zerar os blocos; (k) "não sei" no montar contando como acerto; (l) a nota da prova de Digitar caindo por engano.
- [ ] Prova no Chrome a 1027 e 390 px (emulando iPhone), sem erro de console; **prova no iPhone/Android reais = do dono** (roteiro de 2 min no relatório).
- [ ] `ESTADO-DO-PROJETO.md` atualizado. **Nada commitado, nada publicado.** `git status --short` igual ao do início, exceto os arquivos da fase.

## 9. Fora do escopo

Montar/Falar nas revisões ("Revisão do dia" e cartões — os cartões já têm Fácil e o ditado/shadowing) · modo de resposta nas lições de Dart e C# · "montar" por arrastar (só toque) · tradução inversa (montar o PORTUGUÊS) · pontuação/estrelas novas · IA · `pubspec.yaml`/`firestore.rules`/`android/`/`ios/` · mexer na `FilaLicao` (a escada) além da nota da prova.

## 10. Como verificar

```bash
cd /Users/fazplay/pac_dart            # SDK novo: `which flutter` deve ser ~/development/flutter/bin/flutter
flutter test test/ingles_entrada_test.dart test/ingles_montagem_ui_test.dart test/ingles_entrada_frase_test.dart test/ingles_entrada_app_test.dart
dart analyze lib test
flutter test                           # só as 5 falhas antigas de csharp_curriculo_test
```

**Chrome (probe sem login), UMA pasta:** `flutter build web -t lib/main_portfolio_probe.dart --output=build/probe` → `python3 -m http.server 8793 --directory build/probe` → Playwright em `http://localhost:8793/` a 1027 e 390 px (iPhone emulado por `addInitScript`).
Caminho: HUD ⇄ → **3** (Inglês) → **Esc** (pula o ensaio) → a barra de modos aparece acima da frase → **🧩 Montar** → toca os blocos → **Conferir** → o passo avança. **🎤 Falar** com o reconhecedor do Chromium (sem áudio): "Parar" solta. **⌨️ Digitar**: o botão abre o teclado no celular.
Ao terminar: `pkill -f "http.server 8793"`, fechar o navegador e **apagar `build/probe`**.
