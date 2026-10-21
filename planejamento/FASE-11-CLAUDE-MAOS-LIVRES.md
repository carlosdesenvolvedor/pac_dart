# Fase 11 — Conversa com IA pelo Claude (Worker, desligado) + modo 🙌 mãos-livres

> 🛠️ **IMPLEMENTADA em 21/out/2026 (rodada 9; sem commit/deploy; o Worker NÃO está publicado)**, em 3 grupos com arquivos
> separados depois de uma Fase 0 com os esqueletos (`tutor_claude.dart`, `tutor_roteador.dart`, `maos_livres.dart`):
> **A** serviço do Claude + roteador, **H** mãos-livres na `ConversaPage`, **D** fiação (`main.dart`), probe e docs. O que saiu e
> a prova estão em `ESTADO-DO-PROJETO.md`, seção "🙌 21/out/2026 (rodada 9)". Como ligar o Claude:
> `workers/conversa-claude/LEIA-ME.md`, seção "Ligar no app". **Sem mudança em `firestore.rules`** (os 2 campos novos ficam no
> `config/tutor`, que as regras já cobrem) e nada novo no Firestore além deles.

> **Divergências do texto abaixo (combinadas na implementação):**
> - Fase 0: `FalhaClaude extends FalhaIa` (novo) leva o código do Worker, a mensagem pt-BR e o `Retry-After`; o roteador decide o
>   fallback por ele (`caiParaGemini`, `caiSoNoTurno`). O roteador ganhou `formatoSemJson`: como ele É `TutorJson`, o
>   `IaCubit.consultarJson` sempre chama `perguntarJson`, e no nativo (Firebase AI, sem `TutorJson`) o roteador refaz o caminho
>   "JSON no prompt" com esse texto (`main.dart` passa `formatoTurnoTexto`).
> - Grupo A: **sem tipo novo `TipoFalhaIa.limitePessoal`** (mexeria nos switches exaustivos do `ia_cubit`, `cenario_cubit` e da
>   `ConversaPage`, que o H editava ao mesmo tempo). `limite_pessoal` vira `limiteDiario`; a tela mostra o aviso do limite diário
>   de sempre (não o "Você usou suas falas de hoje…" do Worker), e o roteador repete a falha sem chamar o Worker até o
>   `Retry-After`. Na prática a cota do app (30/dia) acaba antes da do Worker (60/dia).
> - Grupo A: `pedido_invalido` cai para o Gemini **só naquele turno** (sem os 10 min). Turno com mais de 16.000 caracteres nem vai à
>   rede. A config é lida por um `ChaveGemini.campoRecente(nome, maxIdade: 5 min)` novo (o `ChaveGemini.campo` guardava para sempre
>   depois de ler a chave do Gemini; o plano supunha um cache de ~5 min que não existia). A url precisa ser `https://` (ou
>   `http://` só em localhost/127.0.0.1, o `wrangler dev`).
> - Grupo A (a decidir): `limite_geral` (o teto de 450/dia do Worker) é um `limite` comum, como o plano diz — esgotado, todos veem
>   "Muita gente conversando" até a meia-noite UTC em vez de cair para o Gemini.
> - Grupo H: um TOQUE curto no 🎤 (< 400 ms) abre a vez (envia sozinha depois do silêncio) em vez de mandar uma frase vazia.
>   Segurando, o reconhecedor do navegador fecha a cada frase e o controlador reabre (até 6×), somando o texto; soltar pede o fim
>   e, sem resposta em 2 s, fecha à força com o que ouviu. Microfone bloqueado/sem suporte: o modo se desliga e mostra o motivo.
>   A preferência é `conversa_maos_livres` (aparelho). O fim da fala do personagem vem do `Future` do `VozIngles.falar` (sem
>   `duracaoDe`).
> - Correções da revisão (rodada 9): `TipoFalhaIa.limitePessoal` NOVO — o `limite_pessoal` mostra "Você usou suas falas de conversa
>   de hoje" (`ErroCenario.limitePessoal`), não abre a janela de descanso compartilhada (o Gemini segue livre para "Por quê?",
>   Escrita e palavra) e o roteador segura a Conversa até o `Retry-After` (sem ele, até a meia-noite UTC). `limite_geral` com
>   `Retry-After` > 2 min (o teto do dia) → Gemini e o Claude de lado até o `Retry-After` (curto = 429 da Anthropic = `limite`
>   como antes). 3 panes seguidas (`ia_falhou` menos a recusa, `ia_demorou`, `http_5xx`) → Gemini e o Claude de lado 10 min. O
>   tempo esgotado do app (agora 35 s, acima dos 25 s do Worker) vira `ia_demorou` (não cai), não mais `rede`. O `lerCampo`
>   padrão do roteador usa `campoRecente(maxIdade: zero)`: o único cache da config é o do roteador (5 min) — com os dois em
>   série, desligar podia levar ~10 min. Os itens "sem tipo novo" e "(a decidir) limite_geral" acima ficam substituídos por este.
> - Grupo D: só o `IaCubit` passou a usar o roteador (o `IaPalavrasCubit` e o `TutorCubit` continuam no Gemini direto). O
>   `_ReconhecedorFake` do probe agora entrega uma vez por escuta, sozinho depois de `window.__ditoMs` (padrão 500 ms, como antes)
>   ou ~50 ms depois de `parar()`; para segurar o 🎤 na prova, `__ditoMs = 60000`.
> - ⚠️ **Não provado ainda:** o Chrome aceitar o `SpeechRecognition.start()` sem toque novo (a vez que abre sozinha e a reabertura
>   com o dedo no 🎤). Se recusar, o controlador só volta a "ocioso" com o recado — nada quebra.

> O texto abaixo é o plano aprovado, mantido como foi escrito.

---

## Plano: Conversa com IA via Claude (Worker) + modo mãos-livres (rodada 9)

HEAD d6c587f (Conversa Fase 10 no ar, com Gemini). Worker pronto em `workers/conversa-claude/` (NÃO publicado). Leia `workers/conversa-claude/src/*.ts` e `LEIA-ME.md` para o contrato exato; resumo:
- `POST <url>/v1/turno`, `Authorization: Bearer <FirebaseAuth.instance.currentUser!.getIdToken()>` (token novo a cada chamada), JSON `{system, mensagens:[{papel:'aluno'|'ia', texto}], esquema?, maxTokens?}`; ≤24 mensagens, ≤16.000 chars, última do aluno. `esquemaTurno` do app pode ir como está.
- 200 `{texto, uso:{entrada,saida}, restantesHoje}` (com esquema, `texto` é JSON string).
- Erros `{erro, mensagem(pt-BR)}`: 400 pedido_invalido, 401 nao_autenticado, 403 origem_negada, 429 limite_pessoal (Retry-After até meia-noite UTC), 429 limite_geral, 502 ia_falhou, 503 sem_chave, 504 ia_demorou.

## Objetivo
1. **Só a Conversa** (os turnos em JSON da `ConversaPage`/`CenarioCubit`) pode ir para o Claude. Tutor, "Por quê?", Escrita, palavra e engenheira do Turismo continuam no Gemini.
2. **Desligado por padrão.** Liga sem novo deploy quando `config/tutor` tiver `provedorConversa == 'claude'` E `urlConversa` não vazio (lidos com `ChaveGemini.campo`, que nunca lança; cache curto ~5 min como o modeloConversa). Qualquer outro valor → Gemini como hoje.
3. **Fallback:** se o Claude falhar com `sem_chave`, `nao_autenticado`, `origem_negada`, erro de rede/DNS ou 404, aquele turno cai para o Gemini (uma vez) e o app memoriza por 10 min que o Claude está fora (sem martelar). `limite_pessoal` NÃO cai para o Gemini: mostra a mensagem do Worker ("Você usou suas falas de hoje…") e usa a janela de descanso até o Retry-After. `limite_geral`/429 → janela de descanso normal (FalhaIa limite). `ia_falhou`/`ia_demorou` → FalhaIa correspondente (o turno volta ao campo, não gasta uso).
4. **Modo mãos-livres** na ConversaPage (preferência salva no aparelho, padrão desligado; entrada no menu ⋮ "🙌 Mãos-livres" e um chip visível quando ligado):
   - Segurar o 🎤 grava; soltar envia sozinho o que foi reconhecido (se vazio, nada acontece e aparece "Não ouvi nada — tente de novo").
   - Depois que o personagem termina de falar a resposta (fim real da voz, não timer), o 🎤 abre sozinho para a vez do aluno ("Sua vez… fale em inglês"), com um botão ⏹ para parar. Envia sozinho após ~1,5 s de silêncio depois de um resultado final. Se nada for dito em ~8 s, fecha o microfone e mostra "Toque no 🎤 para falar".
   - Nunca abre o microfone enquanto a voz do personagem soa (eco). Para tudo ao sair da página, ao pausar, ao abrir o resumo, na janela de descanso ou se a conversa acabou.
   - A correção do Prof. Dash continua aparecendo na tela; no mãos-livres ganha um 🔊 "Ouvir o jeito certo" que fala a frase corrigida (VozIngles).
   - Sem reconhecimento de voz disponível (navegador sem Web Speech / permissão negada): o item do menu aparece desabilitado com o motivo; nada quebra.
   - Fora do mãos-livres, o comportamento atual (🎤 escreve no campo, o aluno confere e envia) NÃO muda.

## Grupos (posse disjunta)
- **A — serviço Claude + roteador** (novos): `lib/features/tutor/data/tutor_claude.dart` (`ClaudeTutorService implements TutorService, TutorComPersona, TutorJson`; só `perguntarJson` é usado pela conversa; os outros métodos podem delegar a um Gemini interno ou lançar FalhaIa — documente), `lib/features/tutor/data/tutor_roteador.dart` (`TutorConversaRoteador implements TutorService, TutorComPersona, TutorJson`: tudo vai ao Gemini/FirebaseAi, exceto `perguntarJson` que consulta a config e vai ao Claude quando ligado, com o fallback acima; relógio e http injetáveis; obtenção do token injetável para testes). Mapeamento dos erros do Worker para `FalhaIa`/`TipoFalhaIa` existentes (leia `falha_ia.dart`; se precisar de um tipo novo `limitePessoal`, adicione com cuidado e trate em todos os switches exaustivos). Testes: `test/tutor_claude_test.dart`, `test/tutor_roteador_test.dart` (http fake: sucesso com esquema, cada código de erro, fallback e memória de 10 min, config desligada = Gemini, token renovado a cada chamada, nunca loga o texto do aluno). Pode editar `chave_gemini.dart` só para expor leitura com cache dos 2 campos novos, e `falha_ia.dart` se precisar do tipo novo.
- **H — mãos-livres** : `lib/features/ia/presentation/conversa_page.dart`, `lib/features/ia/presentation/widgets/microfone_conversa.dart`, `lib/features/ia/presentation/preferencias_conversa.dart`, `lib/features/ia/presentation/widgets/bolha_conversa.dart` (só o 🔊 do jeito certo), novo `lib/features/ia/presentation/maos_livres.dart` se ajudar (máquina de estados testável: ocioso → ouvindo → enviando → personagem falando → ouvindo…). Use a API pública existente do reconhecedor (`ReconhecedorFala`, `ConversaPage.fabricaReconhecedor`) e de `VozIngles` para saber quando a fala terminou (leia como o palco/Ouvir detectam o fim; se não houver um Future/stream de fim, use o que existir sem mexer em `voz_ingles.dart` — se for impossível, explique em notes e use a duração estimada `VozIngles.duracaoDe` como último recurso). Testes: `test/ia_maos_livres_test.dart` (máquina de estados com fakes) e `test/ia_maos_livres_ui_test.dart` (360×640 e 1027, claro/escuro; segurar/soltar envia; abre sozinho após a fala; não abre durante a fala; para ao sair; desabilitado sem reconhecedor). Prévias PNG em `scratchpad/previas_maoslivres/` via teste temporário (apague-o).
- **D (depois de A e H) — ligação e docs:** `lib/main.dart` (no web e no nativo, o serviço do IaCubit vira `TutorConversaRoteador(gemini: <o atual>)` quando `tutorBuilder == null`; testes com `tutorBuilder` continuam iguais), `lib/main_portfolio_probe.dart` (o fake do probe precisa suportar o mãos-livres: `_ReconhecedorFake` que devolve `window.__dito`), `workers/conversa-claude/LEIA-ME.md` (seção "Ligar no app": `config/tutor.provedorConversa = "claude"` e `urlConversa = "https://paclingo-conversa.<sub>.workers.dev"`; para voltar ao Gemini, apagar `provedorConversa`), `planejamento/FASE-11-CLAUDE-MAOS-LIVRES.md` (este plano final), `ESTADO-DO-PROJETO.md` (seção "🙌 21/out/2026 (rodada 9): Claude na Conversa (desligado) + mãos-livres").

## Validação
`flutter analyze lib test` limpo; testes novos + `test/ia_*` + `test/tutor_*` + `test/chave_gemini_test.dart` + os 5 que importam `TutorCenarioFalso`; suíte completa (só os 5 de csharp_curriculo). Um build do probe e Playwright: ligar mãos-livres no ⋮, segurar/soltar o 🎤 com `window.__dito`, ver o envio automático, a fala do personagem e o 🎤 reabrindo; 0 erros no console. Sem deploy (o lead faz).

## Padrões escolhidos
- Claude só na Conversa; ligado por `config/tutor` (sem deploy). Fallback ao Gemini quando o Worker não existe ou está sem chave.
- A cota por pessoa do app (30/dia, compartilhada) continua valendo também com o Claude; o Worker tem a dele (60/dia) e o limite geral (450/dia).
- Mãos-livres desligado por padrão; preferência por aparelho.
