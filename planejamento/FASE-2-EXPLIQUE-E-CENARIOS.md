# Fase 2 — "Por quê?" (explicar a resposta) + cenários guiados com o Prof. Dash

> Plano para execução por um agente. Escrito em 13/out/2026. Contexto geral: [`MELHORIAS-PESQUISA.md`](MELHORIAS-PESQUISA.md).
> A fase tem duas partes: **2A** (botão "Por quê?" + cota diária + cache — o alicerce, pode ser feita sozinha) e **2B** (cenários
> guiados em turnos, com feedback no fim e frases que viram cartões — só depois da 2A). Cada parte termina com testes, mutação,
> prova no Chrome e `ESTADO-DO-PROJETO.md` atualizado. **Só vale para o curso de Inglês.**

## 1. Objetivo e o que a pessoa vai ver

1. **"Por quê?"** (2A): depois de errar (digitação de memória, revisão digitada, cartão escrito/lacunas/blocos), um botão
   **"💡 Por quê?"** pede ao Prof. Dash uma explicação **curta, em português**, do erro *daquela resposta*: o que estava diferente,
   a regra por trás e a armadilha típica de quem fala português. A explicação aparece num cartão logo abaixo da correção.
2. **Cota diária** (2A): cada pessoa tem um número de usos de IA por dia (padrão 30; "Por quê?", turnos e feedback gastam 1 cada).
   Ao acabar, a mensagem é acolhedora ("Por hoje o Prof. Dash descansou — amanhã tem mais 🐦"); estudar nunca é bloqueado.
3. **Cache** (2A): a mesma pergunta (mesma frase + mesma resposta + mesmo nível) não chama a IA de novo; não gasta cota.
4. **Cenários guiados** (2B): "Pedir um café", "Check-in no hotel", "Entrevista de emprego", "Chamada de trabalho"… A pessoa conversa por
   **texto** (voz depois) com o Prof. Dash fazendo o outro papel, em turnos curtos, **sem correção no meio** (só no fim).
5. **Feedback no fim** (2B): o que foi bem, até 3 correções explicadas em português e **3 frases úteis que viram cartões** (um toque
   salva no baralho "Meus cartões").

Tom: acolhedor, sem culpa, sem bloquear nada. A IA explica; **quem decide a nota do cartão continua sendo a conferência por palavra**.

## 2. Decisões já tomadas (o agente segue; o dono pode mudar)

| # | Decisão | Por quê |
|---|---|---|
| D1 | **Só Inglês.** Dart e C# ficam como estão (o chat livre já existe). | O pedido vem da pesquisa de apps de idiomas. |
| D2 | **Reaproveitar `TutorService.perguntar(...)`** (contexto + histórico + pergunta). **Não mudar a interface** `TutorService`. | Os fakes dos testes antigos e os dois backends (web REST e celular `firebase_ai`) seguem valendo. |
| D3 | **Cota por pessoa e por dia, no cliente**, guardada em `users/{uid}.ia_cota = {dia, usos}` (+ cópia local, mesmo padrão offline-first do hábito). **Sem mudar `firestore.rules`.** | As regras de `users/{uid}` já cobrem o campo. |
| D4 | **A cota é "macia" (forjável)**: a chave do Gemini viaja no cliente (web) — quem quiser burlar burla. A trava real é a **cota do projeto no Google** (e a restrição por site da chave). Cota dura de verdade = Cloud Functions (plano pago): **fora do escopo**; registrar no relatório. | Honestidade sobre o que a cota garante. |
| D5 | **Dia = `diaDe(agora)`** (igual ao hábito, `lib/features/habito/domain/habito.dart`); relógio que volta é ignorado. | Mesma conta já testada. |
| D6 | **Cache local** (`shared_preferences`, JSON, máx. 100 entradas, a mais antiga sai). Chave = hash de `frase|resposta|nível|versão do prompt`. **Sem cache na nuvem** (exigiria coleção nova e regra nova). | Zero mudança de regras; custo zero. |
| D7 | **Erro/falha de rede não gasta cota** e não é guardado no cache. | Justo com a pessoa. |
| D8 | **Texto da pessoa é dado, não instrução.** Limite de 300 letras por resposta/turno; o prompt manda ignorar pedidos para mudar de papel/regras. | Mitiga injeção de prompt e custo. |
| D9 | **Os cartões do feedback entram em "Meus cartões"** pelo caminho que já existe (`prepararCartao` + `TextosRepository`), com a mesma validação (inglês digitável, ≤ 300 letras). | Nada de formato novo de dados. |
| D10 | **A IA nunca altera nota nem agenda.** Só explica. | Evita o aluno "negociar" a nota e mantém o FSRS limpo. |
| D11 | **2B começa por texto.** Voz (reconhecedor) fica para depois, quando o dono liberar o reconhecedor sem commit. | O reconhecedor é trabalho do dono ainda não commitado. |

### Perguntas em aberto (o agente usa o padrão e registra no relatório final)

- Tamanho da cota diária (padrão **30** usos; "Por quê?" = 1, turno = 1, feedback = 1).
- Quais cenários entram (padrão: os 8 da seção 6, etapa 2B).
- Se "Por quê?" aparece também quando a pessoa **acertou** (padrão: **não**; só em erro ou "hesitou").

## 3. Contexto técnico do projeto (o que o agente precisa saber)

- **Tutor hoje:** `lib/features/tutor/` — `TutorService` (`perguntar` → `Stream<String>`), `GeminiTutorService` (web, REST, chave em
  `config/tutor` via `core/gemini/chave_gemini.dart`), `FirebaseAiTutorService` (celular), `TutorCubit` (chat com memória curta de 6
  mensagens e `TutorCubit.de(context)` que devolve null sem o cubit), `contextoDoEstudo(...)`. A persona do inglês é
  `GeminiTutorService._personaIngles` (pt-BR, ≤ ~10 linhas, inglês americano). **Não crie outro cliente de IA.**
- **O modelo é `gemini-flash-latest`**; respostas já chegam inteiras no celular e em pedaços (ou inteiras) na web — a UI deve aceitar os dois.
- **Pontos onde há "uma resposta errada" para explicar:**
  - digitação de memória no palco: `PalcoIngles._concluiu`/`_avancar` (`lib/features/ingles/presentation/palco_ingles.dart`), com
    `avaliarDigitacao(...)` → `ResultadoRevisao` e `palavrasErradas`;
  - revisão digitada: `SessaoMemoriaPage` (`sessao_memoria_page.dart`) — mesma avaliação;
  - cartão: `SessaoCartoesPage` (`sessao_cartoes_page.dart`) — `ComparacaoResposta` (`comparar_resposta.dart`) com `digitada`, `esperada`,
    palavras certas/erradas; só existe depois de "Conferir".
- **Cartões novos:** `lib/features/ingles/domain/cartoes_texto.dart` (`prepararCartao`, `idCartoesAvulsos`) e
  `lib/features/ingles/data/textos_repository.dart`; ver como `baralhos_page.dart` cria um cartão ("Novo cartão") e liga o sentido inglês → português.
- **Relógio injetável, repositório local/Firestore, cubit "opcional" (`X.de(context)`)**: copie o padrão do hábito
  (`lib/features/habito/**`) — é o mais recente e tem testes de referência.
- **Probe sem Firebase** (`lib/main_portfolio_probe.dart`) tem um `_TutorFake` que responde na hora; ele precisa reconhecer os pedidos
  novos (explicação e cenário) para a prova no Chrome.
- ⚠️ **Árvore de trabalho suja** com trabalho do dono (ver o prompt): edições cirúrgicas, nada de `checkout/restore/stash/reset/clean`.

## 4. Modelo de dados

**Cota** — `lib/features/ia/domain/cota_ia.dart` (Dart puro, `Equatable`):

```
CotaIa
  int dia        // dia (diaDe) a que `usos` se refere
  int usos       // usos de IA nesse dia
  static const limitePadrao = 30
  bool temSaldo(int hoje, {int limite})      // dia virou => saldo cheio
  int restantes(int hoje, {int limite})
  CotaIa gastar(int hoje, {int n = 1})       // vira o dia sozinha; relógio que volta é ignorado
  static CotaIa mesclar(CotaIa a, CotaIa b)  // vence o dia maior; mesmo dia => maior `usos` (nunca devolve usos de graça)
  toJson/fromJson tolerante (nunca lança)    // {v:1, dia, usos}
```

**Cache** — `lib/features/ia/data/cache_explicacoes.dart`: `Future<String?> ler(String chave)`, `Future<void> gravar(String chave, String texto)`;
`prefs` chave `ia_cache_v1`; JSON `{ordem:[...], itens:{chave:texto}}`; corrompido ⇒ vazio.

**Cenário** (2B) — `assets/ingles_cenarios.json` (lista) e `lib/features/ia/domain/cenario.dart`:

```
Cenario { String id, titulo, emoji, etapa(A1..C1), papelDoDash, objetivo, abertura(en), dicasDeVocabulario[], maxTurnos(6) }
```

## 5. Regras (o que os testes de domínio precisam provar)

**`explicacaoDe(...)`** monta o pedido (função pura, testável): recebe `{frase, traducao, resposta, nivel, palavrasErradas}` e devolve
`(contexto, pergunta)` para `TutorService.perguntar`. Regras do texto: contexto diz que é um **pedido de explicação de erro**;
traz a frase certa, a tradução, a resposta da pessoa e as palavras erradas; pede **≤ 6 linhas**, em português, **uma regra + uma
armadilha de brasileiro + um exemplo curto com tradução**, e "não repita a frase inteira corrigida mais de uma vez". A resposta da pessoa
é cortada em 300 letras e vem entre aspas marcada como "dado do aluno" (D8).

**`ServicoIa.explicar(...)`** (orquestra cota + cache + serviço), nesta ordem:
1. chave de cache; **achou** ⇒ devolve (não gasta cota);
2. sem saldo ⇒ `ResultadoIa.semCota` (a UI mostra a mensagem acolhedora);
3. chama o serviço e junta os pedaços; **vazio ou exceção** ⇒ `ResultadoIa.falhou` (não gasta, não guarda);
4. sucesso ⇒ **gasta 1**, grava no cache, devolve o texto.
Duas chamadas iguais ao mesmo tempo gastam **1** (a 2ª espera a 1ª).

**Cota**: tabela de casos — dia novo zera; mesmo dia soma; chega a 30 ⇒ sem saldo; relógio que volta não devolve saldo; `mesclar` nunca
diminui `usos`; JSON corrompido ⇒ cota cheia (perdoa) **mas** a mesclagem com a nuvem pega o maior `usos` do dia.

**Cenário (2B)** — `SessaoCenario`: máquina de turnos pura (`abertura` → alterna `aluno`/`dash` até `maxTurnos` ou "terminar") que
**não** corrige durante a conversa; `feedback()` pede um **JSON** `{foi_bem:[..], correcoes:[{sua,melhor,porque}], frases:[{en,pt}]}`;
o parser é tolerante (aceita ```json … ```), limita a 3 correções e 3 frases, **descarta frases que `prepararCartao` recusa**; JSON inválido ⇒ mostra o texto cru e nenhum cartão.

## 6. Passo a passo

### Parte 2A — "Por quê?" + cota + cache

**Etapa 1 — Cota (domínio)** · `lib/features/ia/domain/cota_ia.dart` · testes `test/ia_cota_test.dart` (tabela da seção 5, JSON, mescla).

**Etapa 2 — Repositórios** · `lib/features/ia/data/cota_repository.dart` (`CotaRepository` + `LocalCotaRepository` + `FirestoreCotaRepository(uid)`,
campo `ia_cota` com `set(..., merge: true)`, cópia local por `uid`, lazy no `FirebaseFirestore.instance` — **igual ao hábito**) e
`cache_explicacoes.dart`. Testes: `test/ia_repository_test.dart` (ida e volta, corrompido, Firestore fake sem apagar outros campos,
sem rede, **exclusão de conta leva `ia_cota`**, cache com 100 entradas expulsa a mais antiga).

**Etapa 3 — Serviço** · `lib/features/ia/domain/explicacao.dart` (`explicacaoDe`) e `lib/features/ia/presentation/ia_cubit.dart`
(`IaCubit(servico:, cota:, cache:, agora:)`, `IaCubit.de(context)`, estado com `restantes`; `explicar(...)` na ordem da seção 5, dedup de chamadas
simultâneas). Testes `test/ia_cubit_test.dart` com `TutorService` falso, repositórios falsos e relógio falso: cache não gasta, sem cota,
falha não gasta, sucesso gasta 1 e grava, dedup, virada do dia, concorrência.

**Etapa 4 — Fiação** · `lib/main.dart`: `IaCubit` no ramo autenticado **ao lado do `HabitoCubit`** (acima de `_cursoDe`, para a cota ser da
conta e não do curso), com `iaBuilder`/`iaAgora` injetáveis (padrão Firestore; teste/probe: local). `main_portfolio_probe.dart`: repositórios locais e o
`_TutorFake` reconhecendo o pedido de explicação. Edição **cirúrgica**.

**Etapa 5 — Interface** · `lib/features/ia/presentation/widgets/botao_por_que.dart` (o botão + o cartão da explicação, estados: pronto / carregando /
resposta / sem cota / falhou com "tentar de novo"; mostra "restam N hoje" discreto) e a ligação nos 3 lugares: palco (`_avancar` mostra o botão
junto do "Correção" quando o passo foi `errou`/`hesitou`), `SessaoMemoriaPage` e `SessaoCartoesPage` (depois de conferir com erro). **Uma linha de
gancho por tela**, o resto no widget novo. Tokens `Mixart`, tema claro/escuro, 360 px sem estouro, acessível por teclado (atalho `?`/`H` documentado na dica da tela).
O botão **não aparece** sem `IaCubit` (testes antigos) nem quando acertou (decisão em aberto).

**Etapa 6 — Fechamento da 2A** · teste de app (`habito_app_test`-style): errar uma frase no palco → "Por quê?" → explicação aparece → mesmo erro de novo não gasta
cota → cota 0 mostra a mensagem → virar o dia devolve; **mutação** (item 8); Chrome real (item 10); `ESTADO-DO-PROJETO.md` (seção "💡 Por quê? (Fase 2A)").

### Parte 2B — Cenários guiados (só depois da 2A concluída e aprovada)

**Etapa 7 — Conteúdo** · `assets/ingles_cenarios.json` com **8 cenários** (padrão): Pedir um café (A1), Check-in no hotel (A2), Pedir direções (A2),
Consulta na farmácia (A2), Entrevista de emprego (B1), Reunião de equipe (B1), Chamada com cliente (B2), Daily de desenvolvimento (B2). Cada um com
`abertura` em inglês do Dash, 4–6 `dicasDeVocabulario` e objetivo em português. Teste de conteúdo: JSON válido, ids únicos, inglês digitável (mesma varredura do currículo), etapas existentes.

**Etapa 8 — Sessão** · `lib/features/ia/domain/sessao_cenario.dart` (máquina de turnos) + `cenario_cubit.dart` (cada turno e o feedback gastam 1 de cota; sem cota ⇒ encerra
com feedback local mínimo "Boa conversa! Volte amanhã para o resumo"). Persona de cenário **separada** (`personaCenario(Cenario)`): fala só em inglês no nível da etapa,
frases curtas, 1–2 por vez, **não corrige durante a conversa**, conduz ao objetivo. Testes com serviço falso.

**Etapa 9 — Telas** · botão "Conversar" no Mapa (cartão como o de "Baralhos e cartões"), `cenarios_page.dart` (lista por etapa) e `conversa_page.dart` (bolhas, campo de texto,
"Terminar e ver feedback", contador de cota), `feedback_cenario.dart` (bom/correções/3 frases com botão **"Salvar como cartão"** → `prepararCartao` + repositório, liga o inglês → português).
Layout largo e 360 px.

**Etapa 10 — Fechamento da 2B** · teste de app (conversa de 3 turnos → feedback → salvar um cartão → ele aparece em "Meus cartões"), mutação, Chrome, `ESTADO-DO-PROJETO.md`.

## 7. Casos de borda (todos viram teste)

Cota exatamente no limite (30 → próxima nega) · virar o dia no meio de uma pergunta · relógio que volta · duas telas pedindo a mesma explicação · resposta vazia
(não pede) · resposta de 5.000 letras (corta em 300) · resposta com "ignore as instruções anteriores…" (vai como dado; o prompt manda ignorar) ·
serviço devolve vazio / exceção / 429 / 403 (mensagem amigável, sem gastar) · web em pedaços × celular inteiro · cache corrompido · cache cheio ·
sem Firebase iniciado (testes) · exclusão de conta · feedback com JSON em bloco ```json, JSON truncado, correções demais, frase que `prepararCartao` recusa,
frase repetida (não duplica cartão) · conversa encerrada pela cota no meio · sair da conversa no meio (nada é salvo) · tema claro/escuro · 360 px.

## 8. Critérios de aceite

### 2A
- [ ] Errou uma frase no palco, na revisão digitada ou num cartão ⇒ aparece **"💡 Por quê?"**; ao tocar, a explicação em português surge no cartão abaixo.
- [ ] Repetir o mesmo erro (mesma frase, resposta e nível) **não chama a IA** e não gasta cota.
- [ ] Com a cota esgotada a mensagem é acolhedora e **nada de estudo é bloqueado**; no dia seguinte a cota volta (teste com relógio falso).
- [ ] Falha de rede/serviço **não gasta cota**.
- [ ] A IA **não altera** nota, agenda nem ranking (teste prova que `RevisaoCubit`/`RankingCubit` não são chamados).
- [ ] Nenhuma regra do Firestore foi alterada; **excluir a conta apaga `ia_cota`** (teste).
- [ ] Sem `IaCubit` na árvore (testes antigos) nada aparece e nada quebra.
- [ ] `dart analyze lib test` limpo; `flutter test`: só as 5 falhas antigas do C#; testes novos verdes.
- [ ] **Mutação** (reverter depois de cada uma) pega por algum teste: (a) gastar cota quando veio do cache; (b) gastar cota quando o serviço falha; (c) não zerar a cota na virada do dia; (d) `mesclar` escolhendo o menor `usos`; (e) cortar o limite com `>` em vez de `>=`; (f) enviar a resposta sem o corte de 300 letras; (g) mostrar o botão quando acertou; (h) duas chamadas simultâneas gastarem 2.
- [ ] Prova no Chrome real (item 10) a 1027 px e 390 px, sem erro no console.
- [ ] `ESTADO-DO-PROJETO.md` atualizado. **Nada commitado, nada publicado.**

### 2B
- [ ] Dá para conversar um cenário inteiro por texto; o Dash **não corrige no meio**; o feedback traz o que foi bem, ≤ 3 correções explicadas e ≤ 3 frases.
- [ ] "Salvar como cartão" cria o cartão em "Meus cartões" (com a validação de `prepararCartao`) e não duplica.
- [ ] Cota esgotada no meio encerra com mensagem gentil; JSON de feedback inválido não quebra a tela.
- [ ] Mutações: (i) o Dash corrigindo durante a conversa (persona sem a regra) é pego por teste de prompt; (j) salvar frase que `prepararCartao` recusa; (k) feedback gastar cota duas vezes; (l) parser aceitar mais de 3 correções.
- [ ] Chrome real, testes, `ESTADO-DO-PROJETO.md`, nada commitado.

## 9. Fora do escopo (não fazer)

Voz/reconhecedor nos cenários (D11) · cota dura no servidor (D4) · cache compartilhado entre usuários · mudar a interface `TutorService` · mudar `firestore.rules` ·
mexer em `pubspec.yaml`/`android/`/`ios/` · usar a IA para atribuir nota · Fase 5 (escrita livre corrigida) — ela reaproveita a cota e o cache desta fase.

## 10. Como verificar

```bash
cd /Users/fazplay/pac_dart
flutter test test/ia_cota_test.dart test/ia_repository_test.dart test/ia_cubit_test.dart test/ia_ui_test.dart test/ia_app_test.dart
dart analyze lib test
flutter test                                   # só as 5 falhas antigas de csharp_curriculo_test
```

**Chrome real (probe sem login):**
`flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_ia` → `python3 -m http.server 8793 --directory build/probe_ia`
→ Playwright em `http://localhost:8793/`. ⚠️ Flutter web: **não** ligue a acessibilidade; dirija por coordenadas (`page.mouse.click`) e teclado.
Caminho: clique no nome do curso no HUD (⇄) → tecla **3** (Inglês) → **Esc** passa o ensaio mental → digite uma frase errada de memória (3ª cópia em diante pede de memória)
→ o botão "Por quê?" aparece com a correção. Para a cota/virada do dia use `page.clock` (instale antes de carregar e avance). Ao terminar: `pkill -f "http.server 8793"`.
