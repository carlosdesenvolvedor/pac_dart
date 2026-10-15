# Fase 1 — Hábito diário (sequência, meta do dia, congelamento, lembrete)

> Plano para execução por um agente. Escrito em 12/out/2026. Contexto geral: [`MELHORIAS-PESQUISA.md`](MELHORIAS-PESQUISA.md).
> A fase tem duas partes: **1A** (núcleo: sequência + meta + congelamento + telas — pode ser feita sozinha) e **1B** (lembrete no
> celular — só depois de o dono liberar mexer em `android/` e `ios/`; ver seção 9).

## 1. Objetivo e o que a pessoa vai ver

Quem usa o Paclingo (qualquer um dos 3 cursos) passa a ter:

1. **🔥 Sequência**: quantos dias seguidos bateu a meta. Aparece como um chip no cabeçalho (HUD) com um anel que mostra o progresso do dia.
2. **Meta do dia** em *exercícios*: Leve 10 · **Normal 20** · Forte 40 (constantes num lugar só, fáceis de ajustar).
3. **❄️ Congelamento**: ganho a cada 7 dias de sequência (guarda até 2); cobre um dia perdido sozinho, sem a pessoa fazer nada.
4. **Tela "Sua sequência"** (folha que abre ao tocar no chip): chama grande, dias seguidos, melhor sequência, progresso de hoje,
   congelamentos, últimos 14 dias (feito / congelado / perdido) e o seletor da meta.
5. **Aviso de meta batida**: uma mensagem curta, uma vez por dia, quando bate a meta ("Meta de hoje batida! 🔥 4 dias").

Tom: acolhedor. Sem culpa, sem energia/vidas, sem bloquear nada. Se a sequência acabar, a mensagem é "recomece hoje", não "você perdeu".

## 2. Decisões já tomadas (o agente segue; o dono pode mudar)

| # | Decisão | Por quê |
|---|---|---|
| D1 | **Uma sequência só para o usuário**, somando os 3 cursos (Dart, C#, Inglês). | É hábito de estudar, não de um curso. |
| D2 | **O dia conta quando bate a meta** (não por qualquer atividade). | Dá sentido à meta; evita "abrir e fechar" para manter a chama. |
| D3 | **Unidade = 1 exercício concluído**: trecho digitado até o fim · cartão/frase avaliada na revisão (só a 1ª nota) · pergunta de quiz respondida. **Não contam:** arcade, pular, voltar, "DE NOVO" (repetição do Errei), criar texto/cartão. | Mede estudo, difícil de inflar. |
| D4 | **Dia = dia do calendário local do aparelho**, como inteiro (mesma conta de `Revisao.dia` em `lib/features/ingles/domain/revisao.dart`: `DateTime.utc(y, m, d)` em dias desde a época). Relógio que volta atrás é **ignorado**. | Evita bug de fuso/horário de verão. |
| D5 | **Só no cliente; não vai ao ranking.** | Daria para forjar. |
| D6 | **Armazenamento:** campo `habito` (mapa) no documento `users/{uid}` do Firestore + cópia local em `shared_preferences` (`habito_v1`). **Sem mudar `firestore.rules`** (a regra de `users/{uid}` já cobre o campo). | Não exige deploy de regras; a exclusão de conta já apaga o documento. |
| D7 | **Offline-first:** grava local na hora, sobe para o Firestore sem bloquear; ao carregar, **mescla** local × remoto (regra na seção 5). | App funciona sem internet e em 2 aparelhos. |
| D8 | **Congelamento:** +1 ao chegar a uma sequência múltipla de 7 (máx. 2). Cobre automaticamente os dias perdidos *entre* duas metas, se houver congelamentos suficientes para **todos** os dias perdidos. | Regra simples e previsível. |

### Perguntas em aberto (o agente usa o padrão e registra no relatório final)

- Valores das metas (10/20/40) e se o padrão deve ser 20.
- Se arcade deveria contar (padrão: não).
- Se a sequência deve aparecer no ranking mais tarde (padrão: não, fora do escopo).

## 3. Contexto técnico do projeto (o que o agente precisa saber)

- **Flutter 3.11 / Dart ^3.11**, `flutter_bloc`, `equatable`, `shared_preferences`, `cloud_firestore`. Interface em **português do Brasil**.
- Organização: `lib/features/<feature>/{data,domain,presentation}`; temas/tokens em `lib/core/theme/mixart.dart` (`Mixart.ui(...)`,
  `Mixart.display(...)`, cores `Mixart.brand`, `surface`, `surfaceHi`, `border`, `textMuted`, `danger`…).
- **Padrão de cubit "opcional":** `RankingCubit.de(context)` e `RevisaoCubit.de(context)` devolvem `null` quando o cubit não está na
  árvore (testes antigos continuam passando). **Siga o mesmo padrão** com `HabitoCubit.de(context)`.
- **Padrão de repositório:** interface + `Local…Repository` (shared_preferences, usado em teste/probe) + `Firestore…Repository`,
  escolhidos em `lib/main.dart` por *builders* injetáveis (`revisaoBuilder`, `progressoPorLinguagem`, `audioBuilder`…). Leia
  `lib/features/ingles/data/revisao_repository.dart` e `lib/main.dart` (`PacDartApp`, `_cursoDe`).
- **Escopo dos blocs:** `_cursoDe(user, linguagem, …)` cria `CursoBloc`, `TypingBloc`, `RankingCubit`, `RevisaoCubit` **por linguagem**.
  O `HabitoCubit` precisa viver **acima** disso, no ramo autenticado (`AuthStatus.autenticado`), para a sequência ser única (D1).
- **HUD:** `lib/features/curso/presentation/widgets/hud.dart` (stats da sessão + botões Mapa/Arcade/Ranking/Revisão). O chip entra aí.
- **Pontos onde um exercício termina** (o agente confirma lendo o código e escolhe o gancho de menor intrusão):
  - trecho digitado: `TrechoAvancado` (despachado em `lib/features/curso/presentation/pages/home_page.dart`, ~linhas 209/267/287) e o
    palco do inglês `lib/features/ingles/presentation/palco_ingles.dart`;
  - revisão do inglês: `RevisaoCubit.registrar` (digitada) e `RevisaoCubit.registrarVirar` (cartão) em
    `lib/features/ingles/presentation/revisao_cubit.dart`;
  - quiz: `QuizFinalizado` (`quiz_page.dart`, `palco_ingles.dart`, `fixacao.dart`).
- **Exclusão de conta:** `lib/features/auth/data/exclusao_de_conta.dart` (`apagarDadosDoUsuario` apaga `users/{uid}` e subcoleções).
  Como `habito` é campo do documento, sai junto — **um teste deve provar isso** (veja `test/ingles_audio_test.dart`, ~linha 336, que já usa `fake_cloud_firestore`).
- **Relógio injetável:** `RevisaoCubit` recebe `DateTime Function() agora`. Faça igual no `HabitoCubit`.
- ⚠️ **Árvore de trabalho suja** (veja o prompt): vários arquivos têm alterações do dono que não são suas.

## 4. Modelo de dados

`lib/features/habito/domain/habito.dart` — Dart puro (sem Flutter), imutável, `Equatable`.

```
Habito
  int meta            // exercícios por dia (padrão 20)
  int dia             // o "hoje" a que `unidadesHoje` se refere (dia inteiro, D4)
  int unidadesHoje    // exercícios feitos em `dia`
  int sequencia       // sequência na última meta batida
  int melhor          // maior sequência já alcançada
  int? ultimoDiaMeta  // dia em que a meta foi batida pela última vez (null = nunca)
  int congelamentos   // 0..2 guardados
  List<int> historico // dias em que a meta foi batida (só os últimos 60)
  List<int> congelados// dias cobertos por congelamento (só os últimos 60)
```

JSON (local e Firestore): `{v:1, meta, dia, un, seq, melhor, ult, frz, hist:[…], gel:[…]}`. Tolerar campos ausentes/tipos errados
(documento antigo ou editado à mão) devolvendo o padrão — nunca lançar.

## 5. Regras (o que os testes de domínio precisam provar)

**`Habito registrar(int unidades, DateTime agora)`** (função pura; `unidades` ≥ 1):

1. `d = diaDe(agora)`. Se `d < dia` (relógio voltou): trate `d = dia`.
2. Se `d > dia`: vira o dia → `dia = d`, `unidadesHoje = 0`.
3. `unidadesHoje += unidades`.
4. Se `unidadesHoje >= meta` **e** `ultimoDiaMeta != d` → **meta batida hoje**:
   - perdidos = `ultimoDiaMeta == null ? 0 : d - ultimoDiaMeta - 1` (dias inteiros sem meta entre a última meta e hoje);
   - se `ultimoDiaMeta == null` → `sequencia = 1`;
   - senão se `perdidos == 0` → `sequencia += 1`;
   - senão se `perdidos <= congelamentos` → `congelamentos -= perdidos`, **anota esses dias em `congelados`**, `sequencia += 1`;
   - senão → `sequencia = 1` (recomeça; **os congelamentos não são gastos**);
   - `ultimoDiaMeta = d`; `historico += d`; `melhor = max(melhor, sequencia)`;
   - se `sequencia` subiu e `sequencia % 7 == 0` → `congelamentos = min(2, congelamentos + 1)`.
5. Aparar `historico`/`congelados` aos últimos 60 dias.

**`Habito mudarMeta(int novaMeta, DateTime agora)`**: troca `meta` (só valores permitidos 10/20/40, ou os das constantes) e **reavalia**
o dia (se `unidadesHoje` já alcança a nova meta, a meta de hoje conta como batida pela mesma regra do passo 4).

**`int sequenciaVisivel(DateTime agora)`** (o que o chip mostra *antes* de a pessoa estudar hoje): `d = diaDe(agora)`; se `ultimoDiaMeta == null` → 0;
se `ultimoDiaMeta == d` → `sequencia`; `perdidos = d - ultimoDiaMeta - 1`; se `perdidos <= congelamentos` → `sequencia` (ainda viva);
senão → 0 (acabou — não mostre número velho).

**`bool emRisco(DateTime agora)`**: sequência viva, `sequenciaVisivel > 0` e hoje ainda sem meta (`ultimoDiaMeta != d`).

**`double progressoHoje(DateTime agora)`**: `unidadesHoje / meta` limitado a 1, **só se `dia == diaDe(agora)`**, senão 0 (dia virou e nada foi feito ainda).

**`Habito mesclar(Habito a, Habito b)`** (local × remoto; cada um pode estar adiantado):
- vence quem tem **maior `ultimoDiaMeta`** (null perde de qualquer data); empate → maior `dia`, depois maior `unidadesHoje`;
- `melhor = max`; `historico` e `congelados` = união ordenada e aparada; `meta` do vencedor.
- Deve ser **comutativa** e **idempotente** (`mesclar(a,b) == mesclar(b,a)`, `mesclar(a,a) == a`).

## 6. Passo a passo

**Etapa 1 — Domínio** · `lib/features/habito/domain/habito.dart` (+ `diaDe(DateTime)` no mesmo arquivo; um teste confere que
`diaDe(x) == Revisao.dia(x)` para várias datas, inclusive virada de mês/ano e bissexto) · constantes das metas em um só lugar.
Testes: `test/habito_test.dart` — tabela com cada regra da seção 5.

**Etapa 2 — Repositório** · `lib/features/habito/data/habito_repository.dart`:
`HabitoRepository { Future<Habito> carregar(); Future<void> salvar(Habito h); }`, `LocalHabitoRepository` (`habito_v1`, JSON string),
`FirestoreHabitoRepository(uid)` (`users/{uid}`, campo `habito`, `set(..., SetOptions(merge: true))`). Testes: `test/habito_repository_test.dart`
(local: ida e volta, JSON corrompido → padrão; Firestore com `fake_cloud_firestore`: grava sem apagar os outros campos do documento
— `concluidas`, `recorde`…).

**Etapa 3 — Cubit** · `lib/features/habito/presentation/habito_cubit.dart`: `HabitoCubit(repo, {agora})`, estado = `Habito` + `carregando`;
`static HabitoCubit? de(BuildContext)`; `carregar()` (lê local → mescla com remoto → salva os dois); `praticou(int n)` (aplica `registrar`,
**emite na hora**, salva sem bloquear e engole erro de rede); `mudarMeta(int)`; um `Stream`/campo para o aviso de **meta batida**
(o cubit marca `metaBatidaHoje` só na transição, para a UI avisar uma vez). Testes com repositório falso e relógio falso:
virada do dia, 2 chamadas rápidas seguidas (não perde unidade), erro no salvar, mudar a meta.

**Etapa 4 — Fiação** · `lib/main.dart`: `habitoBuilder` (padrão: `FirestoreHabitoRepository(uid)`; testes/probe: `LocalHabitoRepository()`),
`HabitoCubit` provido no ramo autenticado, **acima** de `_cursoDe`. Edição **cirúrgica** (o arquivo tem alterações do dono).
Também `lib/main_portfolio_probe.dart` (passar `habitoBuilder: (_) => LocalHabitoRepository()`).

**Etapa 5 — Ganchos de contagem** · um por tipo de exercício (D3), sempre via `HabitoCubit.de(context)?.praticou(1)` (no-op se não houver).
Garanta **uma contagem por exercício** (sem duplicar quando o mesmo evento passa por 2 lugares) e **nenhuma** em "pular/voltar/DE NOVO".
Testes: um por gancho provando que conta e outro provando que não conta no que a lista D3 exclui.

**Etapa 6 — Interface** · `lib/features/habito/presentation/widgets/`: `chip_sequencia.dart` (no HUD, ao lado dos botões; 🔥 + número +
anel de progresso; cinza com 0 quando não há sequência; realce quando `emRisco`) e `sequencia_sheet.dart` (folha: chama grande, "N dias",
"melhor", progresso "12/20 hoje", ❄️ ×n, 14 dias com ● feito / ❄ congelado / ○ perdido, seletor da meta). Aviso de meta batida
(`SnackBar` ou faixa curta, **uma vez por dia**, sem som obrigatório, sem bloquear). Tudo com os tokens `Mixart`, funcionando em tema claro e
escuro e em **360 px** (o HUD usa `Wrap`). Testes de widget: chip nos estados (sem sequência / viva / em risco / meta batida), folha, troca
de meta, aviso 1×, 360 px sem overflow.

**Etapa 7 — Fechamento** · testes de app (`ingles_ui_test`-style): digitar uma frase → o chip sobe; exclusão de conta apaga `habito`;
`dart analyze lib test` limpo; `flutter test` sem regressão (as 5 falhas conhecidas de `csharp_curriculo_test` continuam as únicas);
**mutação** nos pontos críticos (item 8); prova no Chrome real (item 10); atualizar `ESTADO-DO-PROJETO.md` (nova seção "🔥 Hábito diário")
e a contagem de testes.

## 7. Casos de borda (todos viram teste)

Primeiro uso (`ultimoDiaMeta == null`) · meta batida duas vezes no mesmo dia (conta uma) · bater a meta às 23:59 e estudar às 00:01
(dias diferentes, sequência +1) · 1 dia perdido **com** congelamento (mantém, gasta 1) · 1 dia perdido **sem** congelamento (recomeça em 1, congelamentos intactos) ·
3 dias perdidos com 2 congelamentos (recomeça) · ganhar congelamento no dia 7, 14… e **nunca passar de 2** · relógio voltando um dia (ignora) ·
mudar a meta para menos depois de já ter feito os exercícios · `praticou` em 2 telas quase juntas · JSON antigo/corrompido · documento do
Firestore sem `habito` · mesclagem de dois aparelhos (um atrasado) · virada de horário de verão · virada de ano e ano bissexto ·
chip sem sequência não mostra "0 dias" assustador, e sim convite ("comece hoje").

## 8. Critérios de aceite

- [ ] Em qualquer curso, concluir exercícios sobe o anel; bater a meta mostra o aviso **uma vez** e sobe a 🔥.
- [ ] Fechar e reabrir o app (e entrar em outro aparelho) mantém sequência, meta e congelamentos.
- [ ] Um dia perdido com congelamento mantém a sequência; sem congelamento, o chip mostra convite para recomeçar (não o número velho).
- [ ] Nada do hábito aparece no ranking. Nenhuma regra do Firestore foi alterada.
- [ ] Excluir a conta apaga o hábito (teste).
- [ ] `dart analyze lib test` limpo; `flutter test`: só as 5 falhas antigas do C#; testes novos verdes.
- [ ] **Mutação** (reverter depois de cada uma) é pega por algum teste: (a) trocar `>=` por `>` na meta; (b) não ignorar relógio que volta;
      (c) gastar congelamento no recomeço; (d) contar "DE NOVO" como exercício; (e) mesclar escolhendo sempre o remoto.
- [ ] Prova no Chrome real (item 10), a 1027 px e a 390 px, sem erro no console.
- [ ] `ESTADO-DO-PROJETO.md` atualizado. **Nada commitado, nada publicado.**

## 9. Fase 1B — Lembrete (separada; só com a liberação do dono)

Por que separada: precisa de plugin nativo e mexe em `android/` e `ios/`, que hoje têm o trabalho de lojas do dono sem commit, além de
`pubspec.yaml`/`pubspec.lock` (e exige `flutter clean && flutter pub get`).

- **Android/iOS:** `flutter_local_notifications` (+ `timezone`), lembrete **diário num horário escolhido** (padrão 20:00), ligado/desligado e
  com o horário dentro da folha "Sua sequência". Só dispara se a meta do dia **ainda não foi batida**: ao bater a meta, reagendar para o
  dia seguinte. Pedir permissão no momento em que a pessoa liga o lembrete (iOS; Android 13+ `POST_NOTIFICATIONS`). Texto acolhedor, sem culpa.
- **Web:** **não fazer push** agora. Push web de verdade pede Firebase Cloud Messaging, chave VAPID, service worker e um envio agendado
  no servidor (Cloud Functions, plano pago) — fase própria, se um dia valer a pena.
- Testar com agendador falso (interface `AgendadorDeLembrete`) e a política "só se a meta não foi batida" em teste puro.

## 10. Como verificar

```bash
cd /Users/fazplay/pac_dart
flutter test test/habito_test.dart test/habito_repository_test.dart test/habito_ui_test.dart
dart analyze lib test
flutter test                                   # só as 5 falhas antigas de csharp_curriculo_test
```

**Chrome real (probe sem login):**
`flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_habito` → `python3 -m http.server 8793 --directory build/probe_habito`
→ MCP do Playwright em `http://localhost:8793/`. ⚠️ Flutter web: **não** ligue a acessibilidade com clique sintético; dirija por
coordenadas (`page.mouse.click`) e teclado (`keyboard.type/press`). Caminho no probe: tecla Esc passa o "ensaio mental"; o HUD fica no topo.
Para provar a virada do dia, o Playwright tem `page.clock` (instale o relógio antes de carregar a página e avance com `fastForward`).
Ao terminar, encerre o servidor (`pkill -f "http.server 8793"`).
