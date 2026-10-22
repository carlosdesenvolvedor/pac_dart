# Plano: 📺 Escutar assistindo (as historinhas das lições dentro do 🎧 Ouvir)

> Projeto: `/Users/fazplay/pac_dart` (Flutter, bloc, Paclingo). Este plano é **só leitura** em relação ao projeto. Quem executa segue a tabela de propriedade da seção 9.
> `$SP` = `/private/tmp/claude-501/-Users-fazplay-pac-dart/0331895d-de51-4964-875d-cf4d7eb2f778/scratchpad`. SDK: `~/development/flutter/bin/flutter` (3.41.2).
> Base lida em 22/out/2026: a árvore está limpa no `main` (bb13846). As mudanças da frente "velocidade/voltar" que os mapas citavam como não commitadas **já entraram** no commit bb13846, então os arquivos da história estão livres.
> **Revisão 2 (22/out/2026):** aplicada a crítica `$SP/critica_historias_licoes.md` (3 bloqueadores, 13 importantes, 14 pequenos). O que entrou, o que entrou pela metade e o que ficou de fora está na **§15 Crítica considerada**. O esquema final do JSON está na **§16** e a lista exata do lote piloto na **§17**. A receita `$SP/historia_licoes/RECEITA.md` e o checador `receita_ferramentas.py` foram alinhados.
> **Pedido do dono que manda em tudo:** "No lugar de colocar na lição, coloque na opção do play list, escutar assistindo." Por isso as **portas de entrada** do 📺 são as da playlist (as setlists e o "Curso na ordem" do 🎧 Ouvir) e o "Tocando agora". Nada entra na lição.

---

## 0. Resumo em 16 linhas

1. **Onde fica (decisão do dono):** não fica na lição. Fica no 🎧 Ouvir, a playlist do app, como o modo **📺 Escutar assistindo**. As portas de entrada são: o botão 📺 em **cada setlist** (no cartão da lista e dentro da `SetlistPage`), o cartão do curso ("Continuar" e "Da minha lição atual") e o botão 📺 Assistir do "Tocando agora" (`TocandoPage`). Funciona com o curso, com qualquer setlist e com o "Ouvir esta lição".
2. **Quem manda é o `OuvirCubit`.** Ele decide **o que** se fala e **quando**. O desenho só segue a posição da fila (`indice`, `fase`, `vez`, `status`). `OuvirCubit`, `OuvirState`, `SaidaDeAudio`, `ConfigOuvir` e `passosDa` **não mudam em nada**.
3. **Cada fala com texto da historinha é uma faixa**, ou seja, uma frase da lição, com o texto puxado do currículo pelo `Trecho.id`. As falas de ligação entre as frases **só são atuadas** (passos mudos que tocam nos silêncios do Ouvir). No 📺 elas nunca são faladas.
4. **Voz e boca:** a mesma voz do Ouvir de hoje (mp3 Chirp 3 HD de cada personagem + bocas do Rhubarb). O lip-sync sai de graça: o palco já anima o falante quando `VozIngles.falando.frase == fala.en`.
5. **Ritmo:** velocidade, repetições, "2ª vez devagar", os 3 modos (só inglês / inglês→português / português→inglês), as pausas (incluindo o eco "🗣️ Sua vez"), ⏮/⏭, "desligar em" e o mini-player valem como já valem hoje, porque são do Ouvir.
6. **Toda lição pode ser assistida desde o 1º dia:** um **encenador automático** puro (Dart, determinístico) monta a cena **em tempo de execução** a partir da lição: cenário pela cena e pela foto, elenco pelo `quem`, gestos e emoções pelo texto e pelo emoji, e o emoji da frase como prop ou como ícone no balão.
7. **Histórias autorais** substituem a encenação automática **lição por lição**: um JSON por trilha em `assets/ingles/historias/<trilha>.json`, carregado só quando é preciso. Os lotes seguintes são **só conteúdo**, sem mudar código.
8. **Fase 1:** o motor genérico, o 📺 no Ouvir, o encenador para as 602 lições, a arte mínima nova (5 cenários do dia a dia, 4 props, figurantes variados) e o conteúdo autoral das **12 lições das trilhas 1 e 2** (`primeiro-contato`, `numeros-horas-soletrar`).
9. **O Turismo fica intacto.** O palco passa a ler uma interface (`RoteiroVisivel`) que o `RoteiroHistoria` implementa sem mudar de comportamento. `PlayerHistoria`, as prefs `en_turismo_historia_*` e o conteúdo não mudam, e os testes da história continuam verdes.
10. **Nada se perde de progresso.** A única pref nova é `en_ouvir_assistir` (lembra se o 📺 estava ligado). Assistir não grava nada no Firestore. Dart e C# não são tocados, porque o Ouvir só existe no inglês.
11. **O validador do Dart manda:** `validarHistoriaLicao` reaproveita `validarCenaBase`, extraída de `historia_turismo.dart` com as **mensagens idênticas**. Há um espelho em Python em `tools/ingles/historias/` (no repo, porque o scratchpad some no fim da sessão).
12. **Os lotes saem baratos:** o autor **não escreve inglês novo**. Só escreve a encenação (cenário, posições, ações, emoções, passos mudos) e um título curto, então cada trilha custa dezenas de milhares de tokens, não milhões.
13. **O 📺 começa desligado e é lembrado** (`PreferenciaAssistir.valor`, lido de forma síncrona). Os botões 📺 da playlist abrem já assistindo. Assim os testes de layout do `TocandoPage` ficam intactos.
14. **Prova visual:** **UM** build de `lib/main_arcade_probe.dart` com a rota nova `/assistir-en` (providers e um `Navigator` próprio **embaixo** deles), servido e checado com Playwright. A pasta `build/probe` é reaproveitada e apagada no fim.
15. **O desenho não perde o fio:** a memória do que já aconteceu na faixa (`MemoriaAssistir`) mora junto do `OuvirCubit`, não no widget. Minimizar, reabrir, cruzar 900 px ou entrar no ⛶ não confundem o palco. O esmaecer passa a ser do roteiro (`RoteiroVisivel.escurecimento`), então repetir uma frase não pisca a tela.
16. **O texto e o eco respeitam a voz:** as letras do balão andam pela posição real do áudio, e no modo eco (🗣️ Sua vez) o balão fica na tela enquanto a pessoa repete.

---

## 1. Objetivo e escopo

### 1.1 O que a pessoa vê
- No "Tocando agora", o botão **📺 Assistir** (`ouvir-assistir`) troca a foto da cena (`ImagemDaFaixa`) por um **palco de desenho animado**. Nele estão o cenário da lição, os personagens nas posições, quem fala a frase atual **falando com a boca sincronizada**, o balão com o inglês (e o português, conforme o chip "Tradução" do Ouvir) e o emoji da frase no balão.
- Entre uma frase e outra, nos silêncios do Ouvir, os personagens **reagem e se mexem**: a Ana entra na chamada, todo mundo acena no "até amanhã".
- Ao trocar de lição na fila, troca a cena (com um esmaecer). Uma setlist de frases soltas pula de cena em cena, sempre com o elenco certo.
- **⛶ Tela cheia do desenho** (`assistir-tela-cheia`): o palco ocupa a tela, com uma barra compacta (⏮ ⏯ ⏭, ⏭⏭ próxima lição, chips do Ouvir).
- Ao minimizar (Esc ou ←), aparece o mini-player de sempre e o áudio continua. O desenho só anda com a tela visível.

### 1.2 Fora do escopo da fase 1 (fica para depois, como lote ou decisão do dono)
- Falas de ligação **faladas** (ver a D3).
- Velocidade 0,5 no Ouvir (ver a D5).
- Mais cenários além dos 5 novos (consultório de verdade, sala de aula, metrô/ônibus, parque, academia, cinema): são **lotes de arte**, que mudam código pouco e de forma isolada (seção 12.2).
- O 📺 dentro da lição ou do mapa: **o dono vetou**.
- Marcar "assistido" e troféus.

### 1.3 Duração e tamanho (conferido no currículo)
- 602 lições: 366 têm 8 frases, 226 têm 10 e 10 têm de 9 a 14. Com o padrão do Ouvir (1×, pausa média de 1 s), uma lição dura **~25–40 s**. Com eco ou repetições, **~45–90 s**.
- O pedido original falava em "4–8 falas". Como o dono decidiu que **a fila do Ouvir é a fonte da verdade**, a historinha tem **as frases da lição, todas** (8–10 em 98% delas). Não se cortam frases, senão o 📺 e o 🎧 contariam histórias diferentes.

---

## 2. Decisões (com motivo)

| # | decisão | por quê |
|---|---|---|
| **D1** | O 📺 fica **só** no Ouvir, a playlist: o botão 📺 em cada setlist (`setlist-assistir-<id>` no cartão e `setlist-assistir` na `SetlistPage`), o cartão "📺 Escutar assistindo" do curso (Continuar e Da minha lição atual) e o toggle no `TocandoPage`. Nada na lição, na folha do mapa nem no `PalcoIngles`. | Pedido do dono ("no lugar de colocar na lição, coloque na opção do play list, escutar assistindo"). Isso também evita o fluxo mais frágil do app: o ensaio, a `FilaLicao` e o fluxo da lição (`ingles_ui_test`, `ingles_cartoes_ui_test`). |
| **D2** | **Mestre = `OuvirCubit`; o palco é um seguidor** (`RoteiroSeguidor`), sem voz própria e sem avançar sozinho. Nenhuma mudança em `OuvirCubit`, `OuvirState`, `SaidaDeAudio`, `ConfigOuvir` ou `passosDa`. | Duas vozes (roteiro + cubit) se cortam: `_vezGlobal` produz `cortada` e o Ouvir pausa por "outra fala". Com o cubit intacto, os 25 + 20 + 12 + 13 testes do Ouvir não mexem. O seguidor deduz tudo do estado que já é emitido. |
| **D3** | **Falas da história = faixas** (as frases da lição, ligadas pelo `Trecho.id`, com `en`/`pt` puxados do currículo na hora). As **ligações são só atuadas** (passos `mudo`), nos silêncios entre as faixas. O formato autoral **proíbe** fala com texto sem `frase`. | (a) A fila (setlists, "faltam ~18 min", posição salva, Media Session, contagem de `ouvidas`) continua sendo exatamente o que a pessoa pratica. (b) Texto fora do currículo não tem mp3 Chirp (`vozes_google.py` apaga os órfãos) e cairia na voz sintética, com outra voz para o mesmo personagem. (c) O texto nunca fica fora de sincronia com o currículo: corrigir a frase no currículo corrige a historinha. |
| **D4** | **Voz = a do Ouvir** (`SaidaVozIngles.en` → `falarNoPlayer` **sem** perfil → mp3 do personagem ou Tatoeba, com as bocas do Rhubarb). O 📺 não usa `PerfilVoz` nem TTS próprio. | Coerente com a lição: o Mike tem a mesma voz no curso e no desenho. O lip-sync já funciona pelo `VozIngles.falando` global (palco_historia.dart:400-410). |
| **D5** | **Velocidade, repetições, modos e pausas são os do Ouvir.** O 📺 não tem um 2º controle de velocidade. O "devagar" é `0,75` + "2ª vez devagar" (0,75 × 0,8 = **0,6**). | Uma fonte de verdade só. As velocidades `[1, .85, .7, .5]` são do player do Turismo. O mp3 do Ouvir **aceitaria** 0,5 (`falarNoPlayer` passa `vGravada` sem clamp e o `fala_web.dart:241` usa `playbackRate = velocidade`; o piso de 0,6 é só da voz sintética). O 0,5 fica fora por coerência: os chips e os testes do `ConfigOuvir` são do Ouvir inteiro, não do 📺. Se o dono quiser, é uma mudança à parte em `ConfigOuvir.velocidades`, com atualização consciente dos testes dos chips. |
| **D6** | **Cobertura = encenação automática em tempo de execução**, mais uma **tabela opcional de conteúdo** (`encenacao_auto.json`) que corrige cenário, hora, remotos e entradas por lição. A história autoral, quando existe, ganha das duas. | Toda lição pode ser assistida no dia 1, sem depender de conteúdo. A heurística por palavra-chave erra bastante (protótipo no `curriculo.json`: "Numa loja de eletrônicos" casou com `clinica` por causa de "adapta**dor**"). A tabela gerada uma vez por classificação barata acerta isso **sem código**. Ela grava **as 602 lições explicitamente** (~40 KB): se a heurística mudar depois, decisões já revisadas não mudam junto. A heurística vale só para lição nova ainda sem entrada. |
| **D7** | Conteúdo em **um arquivo por trilha**: `assets/ingles/historias/<slug>.json`, mais `indice.json` e `encenacao_auto.json`, carregados sob demanda. Uma linha nova no pubspec (`- assets/ingles/historias/`), só na fase 1. | O `curriculo.json` já pesa 2,77 MB. Na web, o `loadString` só busca quando é chamado. O índice evita 404 por trilha sem história. |
| **D8** | **Arte nova mínima na fase 1:** cenários `videochamada`, `escritorio`, `casa`, `restaurante` e `loja`; props `notebook`, `prato`, `sacola` e `documento`; figurantes com aparência variada. **Sem `ViaRemota` nova:** na `videochamada` todos estão "presentes" no palco, cada um dentro de uma moldura de webcam desenhada atrás dele. | Cerca de 2/3 das lições são de trabalho, chamada ou mensagem, e os cenários de hoje são de corrida ou viagem (o `cafe` mostra a pista pela janela, `estacao` é espacial, `garagem` é oficina de corrida). A moldura de webcam evita mexer em `SimulacaoCena` (âncora de remoto, máx. 2 remotos) e no laço de `ViaRemota` dos testes. |
| **D9** | Generalizar **sem tocar no player do Turismo**: `PalcoHistoria` passa a ler `RoteiroVisivel` (interface) e aceita um `CabecalhoPalco` opcional. `RoteiroHistoria implements RoteiroVisivel` com comportamento idêntico. O 📺 tem bolinhas próprias (~40 linhas) em vez de extrair as privadas do `player_historia.dart`. | O `player_historia.dart` tem testes com Keys fixas (`historia-pausa`, `historia-bolinhas`…). Não mexer nele zera esse risco. |
| **D10** | O 📺 **começa desligado** e é **lembrado** em `en_ouvir_assistir`, exposto como `PreferenciaAssistir.valor` (`ValueNotifier<bool>`) carregado **uma vez** ao abrir o `OuvirPage` ou o mini-player e lido de forma **síncrona** no `initState` do `TocandoPage` (sem piscar foto → palco). Os botões 📺 da playlist salvam a pref **antes** de abrir (o `abrirTocando` volta cedo com `telaCheia` já true). O botão tem o selo "novo" até o 1º uso. | Os testes `ingles_tocando_ui_test` e `ingles_mini_player_imagens_test` contam com `ouvir-imagem` no layout padrão. Começar ligado quebraria testes antigos (proibido editar para passar) e gastaria bateria em quem só quer ouvir. O dono pode inverter depois: é 1 linha + atualização consciente dos testes. |
| **D11** | **O validador do Dart manda.** A extração pública de `validarCenaBase(...)` em `historia_turismo.dart` mantém as mensagens idênticas, palavra por palavra. O espelho Python fica em `tools/ingles/historias/` (no repo). | O scratchpad é por sessão e some, mas a receita dos lotes futuros precisa sobreviver. O `turismo_historia_conteudo_test` e o `historia_modelo_test` prendem as mensagens. |
| **D12** | **Assistir não grava progresso.** Nem "visto" nem troféu. O Ouvir continua salvando posição e `ouvidas` como hoje. | Zero risco de mexer em `en_*`/Firestore. Se o dono quiser, um "📺 visto" futuro usa uma chave própria (`en_assistir_vistas`), nunca `en_turismo_historia_vistos`. |
| **D13** | Nível pela etapa: `A1` → `a1`, `A2` → `a2`, `B1` → `b1`, `B2`/`C1`/`DEV` → `b2`. Ele **só** regula a velocidade da máquina de escrever. | `NivelIngles` só vai até B2. O texto das âncoras **não** passa pelo limite de palavras da história, porque o pipeline do currículo já é a autoridade sobre ele. |
| **D14** | Faixa **sem lição de curso** (frase órfã, texto colado, trilha própria) → o 📺 mostra a `ImagemDaFaixa` de hoje e um aviso discreto ("sem desenho para esta frase"). O botão continua ligado. | Não há elenco nem cena. Inventar um palco vazio confunde. |
| **D15** | **Arco por trilha:** campo `arco` (pt, até 300 caracteres) no arquivo da trilha, mais continuidade de figurino, props e lugar. **Cada lição se sustenta sozinha**, porque pode tocar avulsa numa setlist. | Pedido do dono, e a fila do Ouvir pode começar em qualquer frase. |
| **D16** | Quem não tem corpo vira narrador: `quem: ''` e `quem: 'placa'` (4 frases do currículo são textos de placa) → `narrador`, com legenda. A placa ganha o ícone 🪧. | `ElencoIngles.de('placa')` desenharia uma pessoa "ele". (`''` não aparece hoje; a regra fica, sem custo.) |
| **D17** | **A memória do 📺 mora junto do cubit, não no widget.** `MemoriaAssistir` (puro, sem Flutter) é única por `OuvirCubit` (`Expando<MemoriaAssistir>`), assina `cubit.stream` **uma vez** (na 1ª vez que o 📺 é aberto) e guarda por índice: `viuTraducao`, `ultimaFalaEnIndice`, `vezVista`. O `RoteiroSeguidor` lê a memória ao nascer. Mais uma **regra de partida a frio**: ao nascer fora de `fase: ouvindo` sem memória da faixa, vai para a âncora atual, balão completo, **sem mudos até a próxima FalaEn**. O `PalcoAssistir` usa uma `GlobalKey` para não ser recriado na troca de layout de 900 px nem no ⛶. | Minimizar é `Navigator.maybePop()` (`tocando_page.dart:129/243`): o `TocandoPage`, o palco e um seguidor local morreriam, e um seguidor novo decidiria o "vão final" com `vez` velho. |
| **D18** | **O esmaecer é do roteiro:** `RoteiroVisivel.escurecimento` (0..1). O `RoteiroHistoria` calcula **a fórmula de hoje**, movida do `palco_historia.dart:1028-1038` sem mudar nada. O `RoteiroSeguidor` só escurece depois de um **corte de verdade** (troca de lição, troca de cena ou abertura no vão), nunca numa reancoragem da mesma âncora. O seguidor devolve `noTitulo = false` e `duracaoTituloAtual = 0`. | Sem isso, cada repetição da 1ª frase (âncora `(0,0)`) dá uma piscada e a 1ª âncora de uma 2ª cena dá um apagão. |
| **D19** | **Voz das 410 frases com gravação do Tatoeba (`au`): decisão do dono.** A fase 1 **não** muda o áudio (D2/D4 intactos). O risco fica visível (§14) com os 9 casos do piloto. A solução proposta, para quando o dono disser sim, é um **lote de voz** separado: gerar a voz Chirp por personagem também para essas frases (`vozes_google.py` hoje as pula) e uma chave estática `AudioNativo.preferirGeradaDoPersonagem`, ligada só com o 📺 visível. | Num desenho, a Ana mexendo a boca com uma voz masculina gravada é gritante; na lição passa. Mas mexer no áudio do Ouvir é outra frente, com assets e testes próprios. |
| **D20** | **Figurantes mudos permitidos (até 2 por lição)**, só de uma lista fixa (`figurantesConhecidos`: os 36 papéis do currículo + `oficial`, `garcom`, `vendedora`). Max e Kim continuam proibidos. | A lição tem muito `voce` falando com alguém que não tem frase (recepção, imigração, garçom). Sem o figurante, o "Excuse me." vai para o vazio. |
| **D21** | **Selo "✨ história especial"** no chip do título (`assistir-titulo`) quando a história é autoral. A automática mostra só o nome da lição. | O dono AMOU uma história autoral: a diferença tem de ficar clara para a automática não parecer defeito. |

---

## 3. Como o 📺 funciona

### 3.1 As peças
```
OuvirCubit (mestre, intocado) ──stream──▶ MemoriaAssistir (1 por cubit, Expando; viuTraducao/última FalaEn/vez)
        │                                        │ lida ao nascer (partida a frio, D17)
        └──emit──▶ PalcoAssistir (StatefulWidget, GlobalKey, TickerProviderStateMixin)
                        │ initState      → seguidor.aoEstado(cubit.state)   (o BlocListener não dá o 1º)
                        │ BlocListener   → seguidor.aoEstado(st)
                        │ Ticker         → seguidor.tick(dt)
                        ▼
HistoriasLicoes.para(faixa) ──▶ HistoriaLicao ──▶ RoteiroSeguidor (implements RoteiroVisivel)
   (autoral em cache, ou                            │ usa CompassoAssistir (puro: âncora, vão, mudos, fator, letras)
    EncenadorLicao.encenar)                         ▼
                                              PalcoHistoria (o mesmo do Turismo) + BalaoFala
VozIngles.falando (global) ──┬──────────────────▶ boca do falante (mp3 + bocas.json)
                             └──▶ seguidor: FalaEmCurso nova da âncora = reancorar (I4); fc.segundo(agora) = letras (I3)
```

### 3.2 Faixa ↔ passo da história
- Uma `HistoriaLicao` tem `cenas` (`CenaHistoria` do Turismo) e `ancoras: Map<String, (int cena, int passo)>`, onde a chave é `chaveDaFrase(trecho)`, que é igual a `Trecho.id` (os 5.308 trechos têm id, e nenhum se repete). `Faixa.chave` é exatamente essa chave.
- **Passo-âncora** = a fala com texto ligada a uma frase. **Passo mudo** = uma ação entre as âncoras.
- Regra de cobertura: na história autoral, **toda frase da lição aparece uma vez, na ordem da lição**. Assim, tocar a lição em ordem percorre a história em ordem. Na automática, isso vale por construção.
- Faixa cuja chave **não** está na história (por exemplo, o currículo ganhou uma frase depois que a história foi escrita) → `HistoriasLicoes.para` cai na **automática da lição inteira**, nunca numa história quebrada. O teste de conteúdo pega o caso antes de ele ir ao ar.

### 3.3 O que o palco mostra em cada momento do Ouvir

| estado do Ouvir | modo | o palco |
|---|---|---|
| `fase: ouvindo` (FalaEn, `vez` v de `de`) | todos | passo = âncora da faixa. Estado `falando` → `lendo`. Balão com o EN: máquina de escrever **só na vez 1** e sem "reduzir". **As letras seguem a voz** (`CompassoAssistir.letrasPelaVoz`): enquanto `VozIngles.falando.value?.frase == âncora.en`, `letras = len × clamp(fc.segundo(agora) / (f.segundos / fator), 0, 1)`, com `fator` = velocidade do passo (`v`, ou `v × .8` da 2ª vez em diante com "2ª vez devagar"). Se em 0,6 s não aparecer `FalaEmCurso` dessa frase (voz sintética, sem som, `f.segundos` nulo), cai em `letrasPorSegundo(nivel, fator)`. Da vez 2 em diante, o texto já vem completo. PT visível = `mostraTraducao(f, cfg)` (a mesma função do mini_player.dart:52). A boca segue `VozIngles.falando`. |
| `fase: traducao` | inglês→português | balão completo, **PT forçado** visível. Boca fechada (a frase em curso é a PT, ≠ `en`). |
| `fase: traducao` ou `pense` | português→inglês (antes do EN) | balão com `esconderEn` (o EN vira "…", com o selo 🤔 no `pense`) e o PT visível. Mesma regra do `escondeIngles(st)` do mini_player.dart:46. |
| `respiro`/`suaVez`, **não** final | — | o balão fica (`lendo`). No `suaVez`, o selo "🗣️ Sua vez" no canto (só na tela cheia, porque fora dela o `ChipFase` do `TocandoPage` já mostra). |
| `respiro`, **vão final** da faixa | — | toca o **plano do vão** (3.4): o balão fecha em .25 s e os passos mudos animam. Sem nada para animar, o balão **fica** até a próxima faixa (sem piscar). |
| `suaVez` (eco), **vão final** da faixa | eco | **o balão fica** (texto completo, sem máquina de escrever) nos primeiros **70%** do vão, porque é a hora de repetir em voz alta. Os mudos tocam só nos **30% finais**, com `fatorDeTempo` calculado sobre esse pedaço (acelera ou salta para o estado final). |
| `status: pausado`, `motivo != timer` | — | congela no quadro atual, com o véu ⏸ (`assistir-pausado`). Tocar no palco = `alternar`. O Ticker para. |
| `status: pausado`, `motivo == timer` | — | "Desligar em" (inclusive "fim da lição", que pausa **depois** de o índice avançar): o palco **mantém o estado final da lição anterior** e mostra o véu "🌙 Timer acabou" (`assistir-timer`). Não abre a próxima lição com o balão de uma frase ainda não falada. |
| `status: acabou` | — | congela no estado final, com o véu 🏁 "▶ de novo" (`tocar(fonte, fila)`, como `_alternar` do `TocandoPage`). |
| faixa sem lição | — | `ImagemDaFaixa` + aviso (D14). |

**Vão final** (`CompassoAssistir.ehVaoFinal`): primeiro `modoEfetivo = temPt ? modo : soIngles` (sem `pt`, o modo vira só inglês, como no `passosDa`). Vão final = `fase ∈ {respiro, suaVez}` && `vez == de` && (`modoEfetivo` ≠ inglês→português **ou** já houve `traducao` depois da última FalaEn desta faixa). A memória (`MemoriaAssistir`, D17) guarda `viuTraducao` por índice e zera quando o `indice` muda. Uma faixa sem `pt` **tem** vão final (correção da revisão 2).

**Armadilha do `vez`:** `irPara`, `continuar` e a 1ª FalaPt do português→inglês **não** zeram o `vez`. O seguidor só lê `vez`/`de` quando `fase == ouvindo`, ou num vão que veio logo depois de uma FalaEn desta faixa (registrada na `MemoriaAssistir`). No resto, ignora (está coberto no teste 11.2-C2).

**Partida a frio** (D17): seguidor que nasce fora de `fase: ouvindo` e sem `ultimaFalaEnIndice == indice` na memória → âncora atual, balão completo, `esconderEn` pela regra do `escondeIngles`, **nenhum mudo** até a próxima FalaEn.

**Reancorar:** qualquer emissão que **não** seja vão final (uma nova FalaEn, `irPara` para o mesmo índice, ou a FalaPt do português→inglês) leva o palco de volta à âncora da faixa atual, com `tFala = 0`. Como o `OuvirState` é `Equatable` e o `emit` descarta estado igual, o "R" (`repetirAtual`) na vez 1 de 1 pode **não** emitir nada: por isso o seguidor também escuta o `VozIngles.falando` e reancora quando chega um `FalaEmCurso` **novo** (`!identical` ao último) com `frase == âncora.en`. Reancorar na mesma âncora **não** escurece (D18).

### 3.4 O plano do vão (os passos mudos)
- **Duração do vão:** `CompassoAssistir.vaoFinal(f, cfg, fimDeLicao:)` = o `d` do último `Silencio` de `passosDa(...)`. Vai de 0,5 s (pausa curta) a 9 s (eco), mais 1,5 s no fim de cada lição. Como o cubit emite a fase **no começo** do passo, o seguidor sabe o tempo inteiro do vão.
- **Plano:** `planoDoVao(atual, âncoraAtual, próxima, âncoraPróxima)` devolve 1 ou 2 `TrechoMudo`:
  1. Se a próxima faixa está **na mesma história e depois** da âncora atual: um trecho com os mudos **entre** as duas âncoras. Se elas estão em cenas diferentes, o trecho inclui o corte (`abreCena`) e os mudos do começo da cena nova.
  2. Senão (outra lição, ou pulo para trás): (a) os mudos logo **depois** da âncora atual, até a próxima âncora ou o fim da cena (o "rabo"); depois (b), **se sobrar ≥ `minimoParaAbrir` (.6 s)**, um corte para a **abertura da próxima história**: estado inicial da cena da âncora + os mudos antes dela (por exemplo, a Sarah entra).
- **Tempo:** cada mudo dura `duracaoMuda(f)`, a mesma conta do `_mudoDe` do Turismo, sem cartão de título: `SimulacaoCena.duracaoDe(acao) ?? 1.2`, máximo com as reações, os efeitos (1,2) e `RoteiroHistoria.duracaoObjeto`, e no mínimo .8. `fatorDeTempo(durações, vão)` = `soma / (vão × .9)`. Se for ≤ 1, toca em tempo real. Se for > 1, acelera (o seguidor expõe `tPasso × fator`). Se cada passo ficar com menos de `minimoPorPasso` (.35 s), devolve `double.infinity`, e aí **salta direto para o estado final** (sem animação, mas com o estado coerente).
- **Coerência garantida:** os estados vêm de `SimulacaoCena.linhaDoTempo(cena)`, que é cumulativa. Pular de qualquer ponto para qualquer âncora dá **exatamente** o estado em que a cena estaria, porque `antes = linha[passo]`. Não há "meio caminho" inválido.
- **Prelúdio da 1ª faixa da fila** (ou depois de um ⏮/irPara): não há vão antes. Os mudos antes da âncora são **pulados** (o estado da âncora já inclui o efeito deles: quem "entrou" já está lá).

### 3.5 Pulos, pausa, timer, mini-player, foco
- ⏮/⏭/"A seguir"/bolinhas → `irPara` → o seguidor vê `indice` novo → `_irPara(âncora)`. Se a lição for outra, troca a história com um esmaecer de .45 s (pelo `escurecimento` do seguidor, D18).
- **Minimizar e reabrir** (mini-player → `abrirTocando` → `TocandoPage()` novo): o seguidor novo lê a `MemoriaAssistir` e continua do mesmo passo; sem memória da faixa, aplica a partida a frio (3.3). Teste de UI dedicado.
- **A autoral chega a tempo** (I6): `HistoriasLicoes.preparar` é chamado **ao abrir o `OuvirPage`** (índice, tabela e a trilha da lição atual do curso) e ao tocar em qualquer botão 📺 (a trilha da 1ª faixa). Se a trilha da faixa está no índice e ainda não carregou, o `PalcoAssistir` mostra a `ImagemDaFaixa` por até **400 ms** antes do palco. Se a autoral chegar no meio da lição, a troca acontece **na fronteira da próxima faixa** quando a próxima âncora existe na autoral (estado pela `linhaDoTempo`, com esmaecer), não só na próxima lição.
- **Bolinhas** (`assistir-bolinhas`): as faixas da **lição atual** na fila (`CompassoAssistir.licaoDaFaixa(fila, i)` → `[inicio, fim)`). Tocar em uma = `cubit.irPara(j)`. Tocar no palco = `alternar`.
- "Desligar em" e "fim da lição" agem sozinhos, porque o cubit pausa e o palco congela.
- O mini-player continua igual: o 📺 vive **dentro** do `TocandoPage` (sem rota nova), então `telaCheia` continua um bool e não briga. A tela cheia do desenho é só uma troca de layout no mesmo `TocandoPage`.
- Teclado: os atalhos do `TocandoPage` (espaço, ←, →, R, Esc) não mudam. O palco **não** captura teclas (`ExcludeFocus` no `PalcoAssistir`). O botão ⛶ e as bolinhas entram no Tab normalmente.
- **Ticker:** só roda com `status == tocando` (ou um esmaecer/mudo em curso) e o app visível (`WidgetsBindingObserver`). Ele vem de `TickerProviderStateMixin`, então o `TickerMode` do Navigator o desliga **só** quando a rota fica realmente coberta. **Não** se usa `ModalRoute.isCurrent`: abrir a folha "Pôr na setlist" ou o menu "Desligar em" (que ficam por cima, mas deixam o palco visível) **não** congela o desenho com o áudio tocando. Com "reduzir animações" (`MediaQuery.maybeDisableAnimationsOf`), o passo vira de 100 ms, sem andar, sem paralaxe e com o clima estático, como no `PlayerHistoria`. Quando a página volta, o seguidor já sabe onde está, porque recebeu todos os `aoEstado`.
- **Desempenho:** `RepaintBoundary` + `ListenableBuilder(seguidor)` só em volta do `PalcoHistoria`. O `BlocBuilder` do `TocandoPage` não reconstrói o palco (o `PalcoAssistir` é um filho estável com `key`). Assets da história com `cache:false`; falha não fica em cache.

### 3.6 Voz e lip-sync (o que já existe e o que se garante)
- O Ouvir toca `saida.en(f.en)` → `VozIngles.falarNoPlayer(f.en)` sem perfil → mp3 do `vozes.json` (gerado **por personagem**, em `vozes_google.py`) ou Tatoeba → `VozIngles.falando = FalaEmCurso(frase: f.en, boca: <bocas.json>)`.
- O `PalcoHistoria._visemaDoFalante` usa `fc.visema(agora)` quando `fc.frase == en`. Como `en` da âncora == `Trecho.cod` == `Faixa.en`, a boca do personagem certo mexe. O seguidor responde `falaComVoz = true`: fora de `falando`, a boca fecha.
- O que **não** muda na fase 1:
  - **as 410 frases com gravação do Tatoeba (`au`)**: o `AudioNativo.paraTocar` prefere a gravação humana à voz do personagem, então a voz pode trocar de gênero no desenho (no piloto: 9 frases, por exemplo a Ana em "That's expensive." e a Sarah em "How do you spell it?" na voz do CK). Decisão do dono (D19), risco visível na §14;
  - a colisão de texto do `vozes.json` (a mesma frase dita por dois personagens toca a voz de um só; na prática, 2 frases). Herdada do curso.

---

## 4. Encenação automática (`EncenadorLicao`)

Puro, determinístico (sem `Random`), < 3 ms por lição. **Toda** saída passa no `validarHistoriaLicao`: o teste roda as 602 lições.

### 4.1 Cenário (ordem de prioridade)
1. `EncenacaoManual` da lição em `encenacao_auto.json` (se houver).
2. Heurística pelo texto de `Licao.cena`, normalizado (minúsculas, sem acento), com **fronteira de palavra** e o **primeiro lugar mencionado** ganhando. A 1ª ocorrência no texto vale, não a ordem da tabela. **Lugares exigem preposição de lugar** antes: `\b(no|na|num|numa|em|ao|a) (cafe|cafeteria|restaurante|padaria|lanchonete|loja|mercado|supermercado|farmacia|hotel|aeroporto|escritorio|casa)\b` (o aluno "adora café" e as cenas dizem "toma um café": isso é a bebida, não o lugar). O `call` só vale isolado em contexto de reunião (`\bcall\b` perto de `daily|reuniao|time|equipe`). Tabela inicial (o grupo D refina olhando a distribuição real):

| cenário | gatilhos (regex com `\b`) | observação |
|---|---|---|
| `videochamada` | chamada de video, videochamada, call, reuniao online, daily, na chamada, camera | "chamada"/"ligação" **por telefone** → `casa` com remoto `celular` |
| `escritorio` | escritorio, sala de reuniao, reuniao, corredor, mesa dele/dela, code review, sprint, deploy, entrevista | |
| `casa` | casa, apartamento, cozinha, sala, vizinh, aluguel, mudanca, familia, irm, festa, aniversario, jantar em casa | |
| `restaurante` | restaurante, cafe, cafeteria, padaria, lanchonete, almoco, jantar, garcom, cardapio, pedido | o `cafe` do Turismo **não** é usado (tem pista pela janela) |
| `loja` | loja, mercado, supermercado, compras, caixa, provador, farmacia | |
| `aeroporto` | aeroporto, voo, aviao, embarque, imigracao, bagagem, alfandega | |
| `hotel` | hotel, check-in, check-out, hospedagem, quarto | é um quarto, não a recepção |
| `clinica` | medic, consulta, clinica, dentista, sintoma | provisório (tenda), até chegar o lote de arte "consultório" |
| `cidade` | rua, taxi, onibus, metro, trem, esquina, caminho, direc, passeio, carro, estacion | |
| `praia` / `lago` | praia, ferias / parque, trilha, lago, piquenique, acampa | |
| *(nada casou)* | — | `escritorio` se a etapa é DEV ou a cena fala de trabalho, time ou projeto; senão `casa` |

- **Mensagem/e-mail/chat** ("por mensagem", "no chat", "e-mail") → o lugar de quem escreve (`casa` ou `escritorio`), com o remoto via `celular`. O aluno trabalha de casa (ficha do aluno).
- **Nunca** usar os cenários de `cenariosSoDoTurismo` (5.3).

### 4.2 Hora e clima
- Hora: o texto da cena ("de manhã", "cedo" → `amanhecer`/`dia`; "à tarde" → `tarde`; "à noite", "jantar" → `noite`), ou a 1ª frase ("Good morning" → `dia`, "Good evening/night" → `noite`). O padrão é `dia`. Sempre dentro de `horasPermitidas(cenario)`.
- Clima: só `chuva`/`neve` quando a cena diz isso e `climaPermitido` aceita. Senão, `[]`.

### 4.3 Elenco e posições
- `quem` de cada trecho → `quemNoPalco` (`''`/`'placa'` → `narrador`). Os que falam entram na ordem da 1ª fala, e `voce` sempre entra.
- Personagens canônicos citados na cena **sem** falar (exemplo: "o Mike e a Sarah falam rápido", mas só o Mike fala): entram mudos, se couberem (máx. 5 presentes). A detecção é pelo nome próprio no texto da cena.
- Posições: 1 → `centro`; 2 → `voce` em `centroEsquerda` e o outro em `centroDireita`; 3 → `esquerda`/`centro`/`direita` (`voce` à esquerda); 4 → `esquerda`/`centroEsquerda`/`centroDireita`/`direita`; 5 → todas.
- **Telefone/mensagem:** `voce` presente, segurando `celular`; o outro com `remoto: celular` (máx. 2 remotos). O 3º em diante vai para o palco, se fizer sentido, ou a lição vira `videochamada`.
- **Entrada tardia:** se a cena diz "entra", "chega", "aparece" ou "atrasad" perto do nome de quem fala e a 1ª fala dele é a 3ª ou depois → `visivel: false` no elenco + um passo mudo `entra` logo antes da 1ª fala dele (vai tocar no vão anterior). Exemplo: a Ana em `oi-tudo-bem`, a Sarah em `prazer-ate-amanha`.
- Figurantes (`atendente`, `dev-novo`…): entram como estão. O corpo vem de `FigurantesHistoria` (8.3).

### 4.4 Gestos (`gestoDe(trecho)`): o emoji primeiro, depois o texto
- **Normalização:** antes de procurar na tabela, tirar o seletor `U+FE0F` e percorrer o `Trecho.imagem` **por grafema** (`characters`), para casar `☝️`, `🖐️` e sequências com ZWJ (`👩‍🎨`). Teste com `☝️🐌` e `👩‍🎨❓`, que existem no piloto.
- **Remoto:** falante com `remoto` só pode `parado` (`SimulacaoCena`). Para ele, a ação vira `parado` e fica só a emoção (e o efeito). Caso no teste do encenador.
- **Emoji → ação:** 👋 `acena`; 👍/🙏 `concorda`; 👎/🙅 `nega`; 👉/☝️ `aponta`; 👏 `palmas`; 💃 `danca`; ✍️/📝 `escreve` (com `segura: documento`); 🪑 `senta`; 🤔 `pensa`.
- **Emoji → emoção:** 😊🙂😄 `feliz`; 😃🤩🥳 `radiante`; 😢😞 `triste`; 😮😲 `surpreso`; 😠 `bravo`; 🤔 `pensativo`; 😬😰 `nervoso`; 😳 `timido`; 💪 `determinado`; 😩🥱 `cansado`.
- **Emoji → efeito** (no passo do falante): ❤️ `coracoes`; 🎉 `confete`; ❗ `exclamacao`; ❓ `interrogacao` (só com "Sorry?/What?/Pardon?"); 💤 `zzz`; 💦 `suor`; 🎵 `notas`; ✨⭐ `brilho`.
- **Emoji → prop** (`segura` do falante, se a mão estiver livre e não for remoto): 💻 `notebook`; 🍽️🍕🥗🍔 `prato`; 🛍️🛒 `sacola`; 📄📋🪪 `documento`; ☕ `cafe`; 📱☎️📞 `celular`; 🧳 `mala`; 🛂 `passaporte`; 🗺️ `mapa`; 🔑 `chave`; 🎁 `presente`; 📖📚 `livro`; ✉️📧 `carta`; ☂️ `guardaChuva`; 🥤💧 `garrafa`; 🎤 `microfone`.
- **Texto (se o emoji não decidiu):** hi/hello/bye/see you/good morning → `acena`; thanks/thank you → `concorda` + `feliz`; sorry/excuse me → `timido`; yes/sure/of course/okay → `concorda`; no/not/don't → `nega`; frase com `?` → `pensativo` só se não houver outra emoção; great/awesome/congrats/! positivo → `comemora`/`radiante` (no máx. 1 por lição); look/here/this/that → `aponta` (só sem alvo-objeto).
- **Câmera:** 1ª âncora `geral`; com 2 presentes, `medio`; com emoção forte (`radiante`/`triste`/`surpreso`), `close`; o resto, `geral`. Nunca `tremida` nem `panoramica` na automática.
- **Reação** de quem ouve (o falante anterior, se for outro e estiver presente): `emocao` espelhada (`feliz` quando agradecem, `surpreso` com `!`). Sem ação de deslocamento.
- **Ícone do balão** (`iconeDaFala`): o `Trecho.imagem` (1–3 emojis) vai no chip do nome. Na `placa`, vai 🪧.
- **Fecho:** se a última frase é despedida, entra um passo mudo final com todos acenando (o rabo, que toca no vão do fim da lição).

### 4.5 `encenacao_auto.json` (conteúdo, opcional por lição)
```json
{ "versao": 1,
  "licoes": {
    "numeros-horas-soletrar.treze-a-dezenove-o-teen": { "cenario": "loja", "hora": "tarde" },
    "primeiro-contato.nao-entendi-pode-repetir": { "cenario": "videochamada", "hora": "dia", "mudos": ["sarah"] },
    "numeros-horas-soletrar.cem-mil-e-os-precos": { "cenario": "loja", "hora": "dia", "remotos": { "ana": "celular" } }
  } }
```
Campos: `cenario`, `hora`, `remotos{quem: celular}`, `entram[quem]` (entrada tardia forçada), `mudos[quem]` (presentes sem falar: canônicos ou até 2 de `figurantesConhecidos`, D20). Todos opcionais. Um enum desconhecido é ignorado no app (modo tolerante) e é erro no teste de conteúdo. A tabela da fase 1 tem **uma entrada para cada uma das 602 lições** (pelo menos `cenario` e `hora`), não só as que diferem da heurística.

---

## 5. Histórias autorais

### 5.1 Arquivos
```
assets/ingles/historias/
  indice.json                 {"versao":1,"trilhas":{"primeiro-contato":1,"numeros-horas-soletrar":1}}   (slug → versão do arquivo)
  encenacao_auto.json         (4.5)
  primeiro-contato.json       (5.2)
  numeros-horas-soletrar.json
```
- `<slug>` = o prefixo do `Licao.id` antes do 1º `.`. Há 121 slugs, um por trilha (conferido).
- Um lote novo só **acrescenta** arquivos e entradas no `indice.json`. Se uma trilha estiver no índice e o arquivo faltar, o app cai na automática, e o teste de conteúdo acusa.

### 5.2 Esquema (v1)
```json
{
  "versao": 1,
  "trilha": "primeiro-contato",
  "arco": "Primeira semana com o time: a 1ª chamada, a visita ao escritório de Chicago e o 1º 'até amanhã' sem medo.",
  "licoes": {
    "<Licao.id>": {
      "titulo": { "en": "The first call", "pt": "A primeira chamada" },
      "cenas": [
        {
          "cenario": "videochamada", "hora": "dia", "clima": [],
          "elenco": [ { "quem": "voce", "pos": "centroEsquerda", "segura": "cafe", "emocao": "nervoso" }, … ],
          "objetos": [ { "prop": "notebook", "pos": "centro" } ],
          "passos": [
            { "frase": "f-ceea0d", "acao": "acena", "emocao": "feliz", "camera": "medio" },
            { "mudo": true, "quem": "ana", "acao": "entra", "emocao": "feliz" },
            …
          ]
        }
      ]
    }
  }
}
```
- **Passo-âncora:** `frase` (= `Trecho.id`, obrigatório) + qualquer campo de fala do Turismo (`acao`, `emocao`, `alvo`, `para`, `camera`, `efeito`, `clima`, `segura`, `cenario`, `hora`, `reacoes`, `objetos`). `quem` é opcional, e quando vem tem de ser igual a `quemNoPalco(trecho.quem)`. **Proibidos:** `en`, `pt`, `pt_f`, `mudo`. O parser injeta `quem`/`en`/`pt` (`cod` e `dicaPlana`) e chama `FalaHistoria.fromJson(j, estrito:)`.
- **Passo mudo:** `{"mudo": true, "quem": …, …}`, exatamente como no Turismo.
- `cenas` (e não `intro`/`fim`) e `passos` (e não `falas`). O parser monta `CenaHistoria(... falas: passos)` reaproveitando `CenaHistoria.fromJson` depois de renomear a chave.
- O esquema **final**, campo a campo, está na §16 (é ele que vale para os lotes).

### 5.3 Regras de validação (`validarHistoriaLicao` / `validarHistoriasDaTrilha`; o Dart manda)

| regra | conteúdo |
|---|---|
| **L-arquivo** | `versao == 1`; `trilha` igual ao slug do arquivo; toda chave de `licoes` é um `Licao.id` dessa trilha; `arco` ≤ 300 caracteres. Trilha incompleta (alguma lição sem história) = **aviso**, não erro. |
| **L-título** | **obrigatório** na autoral (o chip "✨ história especial" mostra o título, D21): `en` ASCII, de 1 a 6 palavras, sem os termos de `termosProibidos`; `pt` não vazio. (A automática não tem título; o chip usa o nome da lição.) |
| **L-cobertura** | cada `Trecho.id` da lição aparece **exatamente uma vez** como `frase`, **na ordem da lição**; nenhuma `frase` desconhecida. |
| **L-âncora** | sem `en`/`pt`/`pt_f`/`mudo` na âncora; `quem` (se vier) bate com o do trecho; `acao` ∉ {`entra`, `anda`, `corre`, `dirige`, `desce`, `sai`}, porque o deslocamento vai num mudo antes ou depois (a voz do Ouvir não espera a andança). |
| **L-ligação** | passo com texto **sem** `frase` → erro "fala sem 'frase': falas de ligação são só atuadas (mudo)". |
| **L-cenas** | de 1 a 2 cenas (lição cuja `cena` cita 3 lugares junta dois deles no mesmo cenário, por exemplo recepção e corredor no mesmo `escritorio`); cada cena tem ≥ 1 âncora; mudos: **≤ 3 por cena e ≤ 2 seguidos** (herdados do `_validarCena`) **e ≤ 4 na história** (somando as cenas). |
| **L-cenário/props** | cenário ∉ `cenariosSoDoTurismo` = {`boxes`, `podio`, `autodromo`, `plataforma`, `espaco`, `lua`, `marte`, `estacao`, `garagem`}; prop ∉ `propsSoDoTurismo` = {`carro`, `carroRival`, `rodaDeOuro`, `foguete`, `capacete`, `pneu`, `trofeu`, `medalha`, `bandeira`}. |
| **L-elenco** | personagens ⊂ `elencoDasLicoes` = {`voce`, `mike`, `sarah`, `ana`, `ben`, `emma`, `lucas`, `julia`, `dra-lee`} ∪ {os `quem` que falam nesta lição} ∪ {**até 2 figurantes mudos** de `figurantesConhecidos`, D20}. Figurante mudo = id de `figurantesConhecidos` que não fala na lição; mais de 2 → erro "N figurantes mudos (máx. 2)"; id fora da lista → erro "'X' não é do elenco das lições nem figurante conhecido". **Max e Kim proibidos** (DESIGN §5.5). |
| **L-base** | `validarCenaBase(ctx, cena, nivel, erros, personagens: …, validarTextos: false)`: hora/clima, elenco (sem narrador, sem repetir, `pos` única, ≤ 5 presentes, ≤ 2 remotos, ≤ 4 objetos), ≤ 2 mudos seguidos e toda a `SimulacaoCena.aplicar` (alvo, `para`, remoto só `parado`, quem está invisível só entra…). Prefixo das mensagens: `"<licaoId> cena[i] passo n: …"`. |
| **L-narrador** | `narrador` só onde o trecho tem `quem` `''` ou `'placa'`. |

O Python (`tools/ingles/historias/validar_historias_licoes.py`) aplica as mesmas regras, importando por caminho (`importlib.util.spec_from_file_location`, porque `-I` não põe a pasta do script no `sys.path`) o motor de `tools/ingles/historias/validar_historia.py` (a cópia do validador do Turismo). Ele lê `curriculo.json` para resolver as âncoras. Em divergência, **o Dart manda**.

**Paridade Dart ↔ Python (provada, não prometida):** `tools/ingles/historias/fixtures/` com ~15 casos negativos (um por regra L, mais 3 da L-base), cada um um `.json` mínimo + `esperado.txt` com a mensagem exata. O `historia_licao_modelo_test` (Dart) e o `validar_historias_licoes.py --auto-teste` leem **os mesmos** fixtures e comparam as mensagens. A receita roda o `--auto-teste` antes de validar um lote.

### 5.4 Exemplo completo (vira `$SP/historias_licoes/exemplo_licao.json` e a fixture do teste do modelo)
```json
{
  "versao": 1,
  "trilha": "primeiro-contato",
  "arco": "Primeira semana com o time: a 1ª chamada, a visita ao escritório de Chicago e o 1º 'até amanhã' sem medo.",
  "licoes": {
    "primeiro-contato.oi-tudo-bem": {
      "titulo": { "en": "The first call", "pt": "A primeira chamada" },
      "cenas": [
        {
          "cenario": "videochamada", "hora": "dia", "clima": [],
          "elenco": [
            { "quem": "voce", "pos": "centroEsquerda", "segura": "cafe", "emocao": "nervoso" },
            { "quem": "mike", "pos": "centroDireita", "emocao": "feliz" },
            { "quem": "ana", "pos": "direita", "visivel": false }
          ],
          "objetos": [],
          "passos": [
            { "frase": "f-ceea0d", "acao": "acena", "emocao": "feliz", "camera": "medio" },
            { "frase": "f-138833", "acao": "acena", "emocao": "radiante" },
            { "frase": "f-cddcb0", "acao": "concorda", "emocao": "feliz",
              "reacoes": [ { "quem": "mike", "emocao": "feliz" } ] },
            { "frase": "f-0f3970", "acao": "concorda" },
            { "mudo": true, "quem": "ana", "acao": "entra", "emocao": "feliz" },
            { "frase": "f-34d001", "acao": "acena", "alvo": "ana", "camera": "geral" },
            { "frase": "f-e15dec", "acao": "acena", "emocao": "feliz" },
            { "frase": "f-3a3e3a", "emocao": "feliz" },
            { "frase": "f-f9d8da", "acao": "aponta", "alvo": "mike",
              "reacoes": [ { "quem": "mike", "acao": "concorda" } ] }
          ]
        }
      ]
    }
  }
}
```
Na prática: o Mike responde, a Ana "entra na chamada" no vão depois de "I'm good, thanks." (ela acende na moldura dela), a pessoa cumprimenta a Ana, e o rabo vazio deixa o último balão até a próxima lição. **O grupo F roda o validador** e ajusta o exemplo. Revisão 2: o exemplo passa **com 0 erros** no checador provisório (`receita_ferramentas.py checar`, rodado em 22/out). Se o validador Dart recusar `acena` com `alvo` logo depois do `entra`, o plano B já decidido é `"acao": "aponta"` com o mesmo `alvo`. O exemplo final é o que fica no teste.

### 5.5 Arco do piloto (12 lições, só conteúdo)
- **`primeiro-contato`** (5): `oi-tudo-bem` (1ª chamada; a Ana entra) → `prazer-ate-amanha` (fim da chamada; a Sarah entra atrasada; todos acenam "see you tomorrow") → `obrigado-desculpa-com-licenca` (`escritorio` em Chicago, **uma cena só**: a `recepcionista` como figurante muda no balcão à esquerda, o Mike mudo esperando à direita, a Sarah no corredor; atraso e esbarrão com a Sarah; o café dela cai, efeito `estalo`) → `nao-entendi-pode-repetir` (`videochamada`; o Mike fala rápido; o `voce` com 🎧 e `pensativo`, depois o alívio) → `cena-a-primeira-chamada` (revisão: a chamada inteira de novo, agora o `voce` está `determinado`).
- **`numeros-horas-soletrar`** (7): `zero-a-doze-o-telefone` (`videochamada`; o `voce` anota no `documento`) → `treze-a-dezenove-o-teen` e `vinte-a-noventa-e-nove-o-hifen` (`loja`; a atendente; a `sacola` no fim) → `cem-mil-e-os-precos` (`loja`, como a `cena` diz; o `voce` na loja e a Ana pelo `celular`) → `que-horas-sao` (`videochamada`; noite no Brasil) → `como-se-escreve-soletrar` (`videochamada`; a Sarah anota) → `cena-o-cadastro-por-telefone` (`casa`; a Sarah pelo `celular`, de Austin).

---

## 6. Contratos (a Phase 0 escreve exatamente estas assinaturas)

### 6.1 `lib/features/arcade/presentation/historia/roteiro_visivel.dart` (novo, completo na Phase 0)
```dart
import 'package:flutter/foundation.dart';
import '../../domain/historia_turismo.dart';
import '../../domain/simulacao_historia.dart';
import 'roteiro_historia.dart' show EstadoRoteiro;

/// O que o [PalcoHistoria] lê de um roteiro, a cada quadro. O Turismo usa o [RoteiroHistoria] (que anda
/// sozinho e fala); o 📺 Assistir usa o `RoteiroSeguidor` (segue o Ouvir, sem voz própria).
abstract interface class RoteiroVisivel implements Listenable {
  EstadoRoteiro get estadoVisivel;
  FalaHistoria? get falaAtual;
  FalaHistoria? get falaAnterior;
  EstadoCena get antes;
  EstadoCena get depois;
  int get cena;
  int get passo;
  double get tPasso;
  double? get tFala;
  double? get tSaida;
  int get letrasVisiveis;
  bool get mostrarPt;
  bool get noTitulo;
  double get duracaoTituloAtual;

  /// A boca segue só a voz do app (fora de `falando`, fecha). Turismo: `vozLigada && voz != null`.
  bool get falaComVoz;

  /// "Português → inglês": o EN do balão vira "…" (Turismo: false).
  bool get esconderEn;

  /// Emoji da frase no chip do balão (Turismo: null).
  String? get iconeDaFala;

  /// Véu preto 0..1 por cima do palco. Turismo: a fórmula de hoje do `_escurecimento()` do palco,
  /// movida sem mudança (cena 0 passo 0: .55 durante o título e depois some em .45 s; passo 0 das
  /// cenas seguintes: 1 − t/.45). Seguidor: só depois de um corte de verdade (troca de lição, de cena
  /// ou abertura no vão); 0 numa reancoragem da mesma âncora. O seguidor tem noTitulo = false e
  /// duracaoTituloAtual = 0.
  double get escurecimento;
}

/// O cabeçalho do palco (cartão de título e Semantics). Turismo: [CabecalhoPalco.doCapitulo].
class CabecalhoPalco {
  final String sobretitulo;      // 'CHAPTER 7' | '🎬 A1 · Primeiro contato'
  final TextoBilingue titulo;
  final String rotuloSemantico;  // Turismo: 'Desenho animado: Chapter 7, <titulo.en>' (idêntico ao de hoje)
  final int pinturaCarro;        // PropPainter(capitulo:); 0 = pintura padrão
  const CabecalhoPalco({required this.sobretitulo, required this.titulo, required this.rotuloSemantico, this.pinturaCarro = 0});
  factory CabecalhoPalco.doCapitulo(CapituloHistoria c) => CabecalhoPalco(
        sobretitulo: 'CHAPTER ${c.pista}', titulo: c.titulo,
        rotuloSemantico: 'Desenho animado: Chapter ${c.pista}, ${c.titulo.en}', pinturaCarro: c.pista);
}
```
(Import circular `roteiro_visivel` ↔ `roteiro_historia`: o Dart permite.)

### 6.2 Edições pequenas da Phase 0 nos arquivos da história (comportamento do Turismo idêntico)
- `roteiro_historia.dart`: `class RoteiroHistoria extends ChangeNotifier implements RoteiroVisivel`; `@override bool get falaComVoz => _vozLigada && _voz != null;` `@override bool get esconderEn => false;` `@override String? get iconeDaFala => null;` `@override double get escurecimento` = **a fórmula copiada** de `palco_historia.dart:1028-1038` (mesmas constantes, mesmos ramos). Mais nada.
- `palco_historia.dart`: o `_escurecimento()` vira `roteiro.escurecimento` (o corpo antigo sai do palco).
- `palco_historia.dart`: `final RoteiroVisivel roteiro;` `final CapituloHistoria? capitulo;` `final CabecalhoPalco? cabecalho;` com `assert(capitulo != null || cabecalho != null)`. Internamente, `cab = cabecalho ?? CabecalhoPalco.doCapitulo(capitulo!)`; Semantics usa `cab.rotuloSemantico`; título usa `cab.sobretitulo`/`cab.titulo`; `PropPainter(capitulo: cab.pinturaCarro)`. Em `_visemaDoFalante`, a linha `if (roteiro.vozLigada && roteiro.voz != null && estado != EstadoRoteiro.falando)` vira `if (roteiro.falaComVoz && estado != EstadoRoteiro.falando)`. Repassa `esconderEn`/`iconeDaFala` ao `BalaoFala`/`LegendaNarrador`.
- `balao_fala.dart`: parâmetros opcionais `this.esconderEn = false, this.icone` em `BalaoFala` e `BalaoFala.medir` (e `esconderEn` em `LegendaNarrador`). **Aceitos e ignorados** na Phase 0. O grupo C implementa.

### 6.3 `lib/features/arcade/domain/historia_turismo.dart` (Phase 0, final)
- `CenarioHistoria` ganha, **no fim** da lista: `videochamada, escritorio, casa, restaurante, loja`. `interioresHistoria` ganha os 5.
- `PropHistoria` ganha, **no fim**: `notebook, prato, sacola, documento`.
- Função pública extraída (mensagens idênticas; `_validarCena` passa a chamá-la com `personagens: personagensHistoria` e `porFala:` = a regra lucas/julia, chamada **no mesmo ponto**, só para passo com texto, depois do `_validarTexto`):
```dart
/// Valida a cena e devolve a linha do tempo (estados antes de cada passo + o final).
List<EstadoCena> validarCenaBase(String ctx, CenaHistoria cena, NivelIngles nivel, List<String> erros, {
  required Set<String> personagens,
  bool validarTextos = true,
  void Function(String ctxFala, FalaHistoria f)? porFala,
});
```
- `personagensHistoria` **não muda** (historia_ator_test:341).

### 6.4 `lib/features/ingles/domain/assistir/historia_licao.dart` (novo, **completo** na Phase 0)
```dart
const elencoDasLicoes = {'voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee'};
/// Os 36 papéis que falam no currículo (conferido em 22/out/2026) + 3 só para figurante mudo (D20).
/// Fonte única: o FigurantesHistoria (grupo B) tem uma aparência fixa para cada um destes.
const figurantesConhecidos = {
  'amigo-do-ben', 'atendente', 'caixa', 'cfo', 'cliente', 'colega', 'convidada', 'convidado', 'corretora',
  'desenvolvedora', 'dev-junior', 'dev-nova', 'dev-novo', 'dev-pleno', 'diretora', 'engenheira', 'engenheiro',
  'entrevistador', 'estagiaria', 'farmaceutica', 'gestora', 'guia', 'marido', 'moradora', 'motorista',
  'participante', 'passageira', 'passageiro', 'proprietario', 'recepcionista', 'recrutadora', 'seguranca',
  'stakeholder', 'supervisora', 'vendedor', 'vizinha',
  'oficial', 'garcom', 'vendedora'};
const maxFigurantesMudos = 2;
const cenariosSoDoTurismo = {CenarioHistoria.boxes, CenarioHistoria.podio, CenarioHistoria.autodromo,
    CenarioHistoria.plataforma, CenarioHistoria.espaco, CenarioHistoria.lua, CenarioHistoria.marte,
    CenarioHistoria.estacao, CenarioHistoria.garagem};
const propsSoDoTurismo = {PropHistoria.carro, PropHistoria.carroRival, PropHistoria.rodaDeOuro, PropHistoria.foguete,
    PropHistoria.capacete, PropHistoria.pneu, PropHistoria.trofeu, PropHistoria.medalha, PropHistoria.bandeira};
const acoesQueDeslocam = {AcaoAtor.entra, AcaoAtor.anda, AcaoAtor.corre, AcaoAtor.dirige, AcaoAtor.desce, AcaoAtor.sai};

/// '' e 'placa' → narrador; o resto como veio.
String quemNoPalco(String quem);

/// A1→a1, A2→a2, B1→b1, B2/C1/DEV→b2 (pelo começo de `Trilha.etapa`).
NivelIngles nivelDaEtapa(String etapa);

/// O slug da trilha de uma lição ('primeiro-contato.oi-tudo-bem' → 'primeiro-contato').
String slugDaLicao(String licaoId);

class HistoriaLicao {
  final String licaoId;
  final NivelIngles nivel;
  final TextoBilingue? titulo;
  final List<CenaHistoria> cenas;            // âncoras já com quem/en/pt do currículo
  final Map<String, (int, int)> ancoras;     // chaveDaFrase → (cena, passo)
  final bool autoral;
  const HistoriaLicao({required this.licaoId, required this.nivel, this.titulo, required this.cenas,
      required this.ancoras, required this.autoral});
  /// Monta a partir das cenas já prontas (a automática usa isto): calcula [ancoras] pelas falas com texto
  /// na ordem, casando com os trechos da [licao] (falas com texto = trechos, na ordem).
  factory HistoriaLicao.daLicao(Licao licao, List<CenaHistoria> cenas, {required NivelIngles nivel,
      TextoBilingue? titulo, required bool autoral});
}

class HistoriasDaTrilha {
  final int versao;
  final String trilha;
  final String? arco;
  final Map<String, HistoriaLicao> licoes;
  const HistoriasDaTrilha({required this.versao, required this.trilha, this.arco, required this.licoes});
  /// estrito=true: FormatException clara ("primeiro-contato.oi-tudo-bem cena[0] passo 3: frase 'f-x' desconhecida").
  /// estrito=false (app): lição com erro é descartada (aviso?.call(motivo)) e cai na automática.
  factory HistoriasDaTrilha.fromJson(Map<String, dynamic> j, {required Trilha trilha, bool estrito = true,
      void Function(String motivo)? aviso});
}

/// [] = ok. Regras 5.3 (L-título, L-cobertura, L-âncora, L-ligação, L-cenas, L-cenário/props, L-elenco, L-base, L-narrador).
List<String> validarHistoriaLicao(HistoriaLicao h, Licao licao);

/// L-arquivo + validarHistoriaLicao de cada lição. [avisos] recebe as lições sem história.
List<String> validarHistoriasDaTrilha(HistoriasDaTrilha h, Trilha trilha, {List<String>? avisos});
```
Observação: L-ligação e L-âncora (campos proibidos) são checadas **no parse**, porque depois do parse não se distingue o que veio do JSON e o que foi injetado. No estrito, viram `FormatException`. O `validarHistoriaLicao` checa o resto.

### 6.5 `lib/features/ingles/domain/assistir/encenador_licao.dart` (stub na Phase 0 → **D**)
```dart
class GestoDaFrase {
  final AcaoAtor acao; final Expressao? emocao; final EfeitoHistoria? efeito; final PropHistoria? segura;
  const GestoDaFrase({this.acao = AcaoAtor.parado, this.emocao, this.efeito, this.segura});
}

class EncenacaoManual {
  final CenarioHistoria? cenario; final HoraHistoria? hora;
  final Map<String, ViaRemota> remotos; final Set<String> entram; final Set<String> mudos;
  const EncenacaoManual({this.cenario, this.hora, this.remotos = const {}, this.entram = const {}, this.mudos = const {}});
  /// Tolerante: enum desconhecido → null/ignorado.
  factory EncenacaoManual.fromJson(Map<String, dynamic> j);
}

abstract final class EncenadorLicao {
  /// Sempre devolve uma história válida (validarHistoriaLicao vazio). Stub: 1 cena `casa`/`dia`, elenco em
  /// linha, uma âncora `parado` por trecho.
  static HistoriaLicao encenar(Licao licao, {required String etapa, EncenacaoManual? manual});
  static CenarioHistoria cenarioDe(Licao licao, {required String etapa});
  static HoraHistoria horaDe(Licao licao, CenarioHistoria cenario);
  static GestoDaFrase gestoDe(Trecho t);
}
```
O stub da Phase 0 já tem de passar no validador (um palco simples e válido), para que C e E integrem desde o 1º dia.

### 6.6 `lib/features/ingles/domain/assistir/compasso_assistir.dart` (stub → **C**)
```dart
enum MomentoAssistir { fala, traducao, pense, vao, vaoFinal, parado }

class TrechoMudo {
  final HistoriaLicao historia;
  final List<(int, int)> passos;   // (cena, passo), na ordem
  final bool abreCena;             // corta para a cena do 1º passo (esmaecer) antes de animar
  const TrechoMudo({required this.historia, required this.passos, this.abreCena = false});
}

abstract final class CompassoAssistir {
  static const minimoPorPasso = .35, folgaDoVao = .9, minimoParaAbrir = .6;
  static MomentoAssistir momento(OuvirState st, {required bool viuTraducao});
  static bool ehVaoFinal({required FaseOuvir fase, required int vez, required int de, required ModoOuvir modo,
      required bool viuTraducao, required bool temPt});
  static (int, int)? ancora(HistoriaLicao h, Faixa f);
  static double vaoFinal(Faixa f, ConfigOuvir c, {required bool fimDeLicao});
  static List<TrechoMudo> planoDoVao({required HistoriaLicao atual, required (int, int) ancoraAtual,
      HistoriaLicao? proxima, (int, int)? ancoraProxima});
  static double duracaoMuda(FalaHistoria f);
  /// soma / (vão × folga); ≤1 tempo real; >1 acelera; infinity = salta para o estado final.
  static double fatorDeTempo(List<double> duracoes, double vao);
  static double letrasPorSegundo(NivelIngles n, double fator);   // A1 22 · A2 26 · B1/B2 30 (× fator)
  /// Letras pela voz (I3): len × clamp(segundoDaVoz / (segundosDaFaixa / fator), 0, 1). null = sem dado
  /// da voz (o seguidor cai em letrasPorSegundo depois de 0,6 s sem FalaEmCurso da frase).
  static int? letrasPelaVoz({required int total, required double? segundoDaVoz, required double? segundosDaFaixa,
      required double fator});
  /// Eco (I2): fração do vão em que o balão fica antes dos mudos (.7). Os mudos usam o resto.
  static const fracaoDoEco = .7;
  static ({int inicio, int fim}) licaoDaFaixa(List<Faixa> fila, int i);
}
```
(Importa `OuvirState` de `presentation/ouvir/ouvir_state.dart`, uma classe pura com Equatable, sem Flutter. Se o analisador de camadas reclamar, `momento` passa a receber `(FaseOuvir, ModoOuvir, StatusOuvir)`.)

### 6.7 `lib/features/ingles/presentation/ouvir/assistir/roteiro_seguidor.dart` (stub → **C**)
```dart
class RoteiroSeguidor extends ChangeNotifier implements RoteiroVisivel {
  RoteiroSeguidor({required HistoriaLicao? Function(Faixa f) historiaDe, required MemoriaAssistir memoria,
      bool reduzir = false});
  /// A cada emit do OuvirCubit (também o 1º, com o estado atual: o PalcoAssistir chama no initState,
  /// porque o BlocListener não dispara para o estado inicial). Ao nascer, lê a [memoria]; sem memória
  /// da faixa e fora de `ouvindo` → partida a frio (âncora, balão completo, sem mudos até a próxima FalaEn).
  void aoEstado(OuvirState st);
  /// A cada mudança de VozIngles.falando: FalaEmCurso nova (!identical) da âncora = reancorar (I4);
  /// também alimenta as letras pela voz (I3).
  void aoFalar(FalaEmCurso? fc);
  /// O relógio do PalcoAssistir.
  void tick(double dt);
  /// null = a faixa atual não tem desenho (D14).
  HistoriaLicao? get historia;
  /// O Ticker só precisa andar com isto true (tocando, ou um esmaecer ou mudo em curso).
  bool get precisaDeRelogio;
  bool get reduzir; set reduzir(bool v);
}
```
Stub: `historia` vem de `historiaDe(st.atual)`; o passo é a âncora; `estadoVisivel` = `lendo`; o texto vem completo; `noTitulo` false; `duracaoTituloAtual` 0; `escurecimento` 0; `tSaida` null.

### 6.7b `lib/features/ingles/presentation/ouvir/assistir/memoria_assistir.dart` (novo, **completo** na Phase 0)
```dart
/// O que o 📺 precisa lembrar da fila, vivo enquanto o cubit vive (D17). Puro, sem Flutter.
class MemoriaAssistir {
  /// Uma por cubit (Expando). Assina cubit.stream na 1ª chamada; cancela no cubit.close (onDone).
  static MemoriaAssistir de(OuvirCubit cubit);
  @visibleForTesting
  MemoriaAssistir.paraTeste();
  /// Alimentada pelo stream (e chamável no teste).
  void registrar(OuvirState st);
  bool viuTraducao(int indice);
  int? get ultimaFalaEnIndice;
  int? get vezVista;          // o `vez` da última FalaEn da faixa `ultimaFalaEnIndice`
}
```

### 6.8 `lib/features/ingles/presentation/ouvir/assistir/palco_assistir.dart` (stub → **C**)
```dart
class PalcoAssistir extends StatefulWidget {
  const PalcoAssistir({super.key, required this.cubit, required this.trilhas, this.grande = false,
      this.onTelaCheia, this.historias});
  final OuvirCubit cubit;
  final List<Trilha> trilhas;
  final bool grande;                  // layout da ⛶ tela cheia (barra compacta própria)
  final VoidCallback? onTelaCheia;    // null = sem botão ⛶
  final HistoriasLicoes? historias;   // injeção nos testes; padrão HistoriasLicoes.de(trilhas)
  /// A faixa tem desenho (lição do curso, não própria)?
  static bool podeAssistir(Faixa f, List<Trilha> trilhas);
}
```
Keys: `assistir-palco` (raiz), `assistir-bolinhas`, `assistir-tela-cheia`, `assistir-titulo` (chip "🎬 emoji nome · A1", com "✨" e o `titulo.pt` quando a história é autoral, D21), `assistir-especial` (o selo ✨ dentro do chip), `assistir-pausado`, `assistir-timer`, `assistir-fim`, `assistir-sem-desenho`, `assistir-carregando` (a `ImagemDaFaixa` dos até 400 ms de espera da autoral). Quem monta o `PalcoAssistir` (o `TocandoPage`) passa uma **`GlobalKey` guardada no State**, para o palco sobreviver à troca de layout de 900 px e ao ⛶. Stub: `ImagemDaFaixa` da faixa atual dentro de um `KeyedSubtree(assistir-palco)`.

### 6.9 `lib/features/ingles/domain/assistir/historias_licoes.dart` (stub → **D**)
```dart
class HistoriasLicoes {
  HistoriasLicoes(this.trilhas, {AssetBundle? bundle, Duration timeout = const Duration(seconds: 8)});
  final List<Trilha> trilhas;
  /// Memoizado por identical(trilhas).
  static HistoriasLicoes de(List<Trilha> trilhas);
  /// Síncrono: a autoral (se a trilha já carregou e tem a lição), senão a automática (memo por licaoId,
  /// com a EncenacaoManual se a tabela já carregou). null = faixa sem lição do curso ou trilha própria.
  HistoriaLicao? para(Faixa f);
  /// Carrega índice, tabela e a trilha da faixa (e a próxima trilha). Nunca lança. Chamado ao abrir o
  /// OuvirPage (com a lição atual do curso) e em todo botão 📺 (I6).
  Future<void> preparar(Faixa f);
  /// Pré-carga pelo id da lição (o OuvirPage ainda não tem Faixa).
  Future<void> prepararLicao(String licaoId);
  bool temAutoral(String licaoId);
  /// A trilha da lição está no índice mas o arquivo ainda não chegou (o palco espera até 400 ms).
  bool carregando(String licaoId);
}
```
Troca para a autoral (I6): o seguidor pede `para(f)` a cada **faixa nova**; se a lição em curso era automática e agora há autoral **com a âncora da faixa nova**, troca ali (estado pela `linhaDoTempo` da autoral, com esmaecer). Nunca troca no meio de uma faixa.

### 6.10 `lib/features/ingles/data/historias_licoes_repo.dart` (novo, **completo** na Phase 0)
```dart
abstract final class HistoriasLicoesRepo {
  static const pasta = 'assets/ingles/historias/';
  static const indice = '${pasta}indice.json';
  static const encenacao = '${pasta}encenacao_auto.json';
  /// slug → versão. Future em cache só no sucesso; falha → {} e tenta de novo no próximo chamado.
  static Future<Map<String, int>> trilhasComHistoria({AssetBundle? bundle});
  /// O JSON cru de uma trilha (null se não está no índice, falhou ou estourou o timeout). cache:false no loadString.
  static Future<Map<String, dynamic>?> trilha(String slug, {AssetBundle? bundle, Duration timeout});
  static Future<Map<String, EncenacaoManual>> encenacaoAuto({AssetBundle? bundle});
  static void limparCache();
}
```
(Mesmo padrão do `HistoriaTurismoRepo`. O parse com `Trilha` fica em `HistoriasLicoes`, porque o repo não conhece o currículo.)

### 6.11 `lib/features/ingles/data/preferencia_assistir.dart` (novo, **completo** na Phase 0)
```dart
abstract final class PreferenciaAssistir {
  static const chave = 'en_ouvir_assistir';
  static const chaveNovidade = 'en_ouvir_assistir_visto';
  /// Leitura síncrona (I9). false até carregar; carregado uma vez ao abrir o OuvirPage ou o mini-player.
  static final ValueNotifier<bool> valor = ValueNotifier(false);
  static Future<void> carregar();               // idempotente; erro → fica false
  static Future<bool> ligado();                 // false sem pref / com erro
  static Future<void> salvar(bool ligado);      // atualiza `valor` na hora; grava com try/catch
  static Future<bool> mostrarNovidade();        // true até o 1º uso
  static Future<void> marcarNovidadeVista();
}
```

### 6.12 Arte (stubs na Phase 0 → **A**; elenco → **B**)
- `fundo_historia.dart`: os 5 `case` novos em `linhaDoChao`/`horizonte`/as camadas, com **placeholders** que já passam no `historia_fundo_test`: céu e chão chapados com cores **únicas** por cenário e uma silhueta simples distinta (mesa, sofá, balcão, prateleira, molduras). A cumpre o resto.
- `props_historia.dart`: os 4 props novos em `tamanho` e no `PropPainter` (placeholder: retângulo com cor própria que desenha algo).
- `lib/features/arcade/presentation/historia/moldura_webcam.dart` (novo): `class MolduraWebcamPainter extends CustomPainter { MolduraWebcamPainter({required int indice, required bool acesa, required HoraHistoria hora}); }` mais `static Rect molduraDe(Rect corpoDoAtor)`. Placeholder: um retângulo arredondado.
- `lib/features/arcade/presentation/historia/figurantes_historia.dart` (novo): `abstract final class FigurantesHistoria { static bool ehFigurante(String quem); static Aparencia de(String quem); static String rotulo(String quem); }`. Stub: `de` = `ElencoIngles.de(quem) ?? <aparência 'ele' padrão>` (os 3 só-mudos `oficial`/`garcom`/`vendedora` não existem no `ElencoIngles`), `rotulo` = o capitalizar de hoje.
- **Checklist dos placeholders da Phase 0** (regras não óbvias dos testes antigos, P12): (1) noite com luminância ≥ 15 abaixo do dia; (2) as 4 horas pintam diferente; (3) distinto dos outros cenários a 64×40 de noite; (4) `tamanhoNaMao` ≤ 0,3 h (`historia_ator_test:328`); (5) `PropPainter` com `ops` não vazio em 5 capítulos e 3 alturas. O nome do teste "os 25 cenários…" fica desatualizado, mas teste antigo **não** se edita: anotar no ESTADO.
- `elenco_turismo.dart` (Phase 0 só a fiação, com saída idêntica): em `de`, `_ => FigurantesHistoria.ehFigurante(quem) ? FigurantesHistoria.de(quem) : ElencoIngles.de(quem)`; em `nomeDe`, `_ => FigurantesHistoria.ehFigurante(quem) ? FigurantesHistoria.rotulo(quem) : <capitaliza>`; e `'placa' => '🪧'`.

---

## 7. A interface (grupo E)

### 7.1 `TocandoPage`
- Construtor: `const TocandoPage({super.key, this.assistir})`, com `final bool? assistir` (null = pref). Os testes antigos usam `TocandoPage()`, e continua compilando.
- Estado: `_assistir` = `assistir ?? PreferenciaAssistir.valor.value`, **síncrono** no `initState` (sem piscar, I9); `_palcoGrande`; `_chavePalco = GlobalKey()` (D17).
- Botão **📺 Assistir / 🖼️ Foto** (`ouvir-assistir`), um `Semantics(toggled:)` numa **posição fixa, fora do bloco da foto**: na linha do `ChipFase`, logo antes dos `ChipsOuvir` (I8). Assim ele existe com o chip "Imagens" desligado e com faixa sem foto. Só aparece com `PalcoAssistir.podeAssistir(f, trilhas)`. O selo "novo" sai depois do 1º toque. Salva a pref.
- Com `_assistir` ligado e a faixa podendo ser assistida, aparece `PalcoAssistir(key: _chavePalco, cubit, trilhas, onTelaCheia: …)` **independente de `cfg.mostrarImagens` e de `f.temImagem`** (o palco ocupa o lugar do bloco da imagem, ou é inserido no mesmo ponto quando o bloco não existiria). Largura `min(maxWidth, 720)`, altura `(w × .56).clamp(200, 380)`; no layout ≥ 900 px, a coluna esquerda inteira (`clamp(260, 520)`). Some o `RostoDaFaixa` do topo (o palco já mostra o rosto). O `ouvir-en` continua, menor (22/26 em vez de 26/32), pela acessibilidade e pelo "…" do português→inglês. (O texto aparece no balão e no `ouvir-en`; esmaecer o `ouvir-en` com `Opacity` baixa, mantendo a `Semantics`, fica como **decisão do dono** depois de ver o piloto.)
- **⛶ tela cheia do desenho:** `_palcoGrande = true` troca o `Scaffold` por um layout de palco cheio + uma barra compacta (⏮ ⏯ ⏭, ⏭⏭ `proximaLicao`, `ChipsOuvir` num scroll horizontal) + o botão de sair (⛶ de novo ou Esc). O Esc com `_palcoGrande` só sai da tela cheia; o 2º Esc minimiza, como hoje.
- Atalhos de teclado iguais. O palco fica dentro de `ExcludeFocus`.

### 7.2 `OuvirPage` (a playlist: o pedido do dono)
- Ao montar: `PreferenciaAssistir.carregar()` e `HistoriasLicoes.de(trilhas).prepararLicao(<lição atual do curso>)` (I6, I9). Sem `await` na UI.
- Logo abaixo do `_CartaoCurso`: o cartão **"📺 Escutar assistindo"** (`ouvir-assistir-cartao`). Texto: "As frases da lição viram desenho animado: cada personagem fala a sua frase". Dois botões, espelhando o cartão do curso:
  - `ouvir-assistir-continuar` "Continuar" = o mesmo de `ouvir-curso-continuar` + abrir assistindo;
  - `ouvir-assistir-curso` "Da minha lição atual" = o mesmo de `ouvir-curso-atual` + abrir assistindo.
- **Em cada setlist** (`_CartaoSetlist`, `ouvir_page.dart:348`): um `IconButton` 📺 (`setlist-assistir-<id>`, tooltip "Escutar assistindo", `Icons.live_tv_rounded`) ao lado do ▶ `setlist-tocar-<id>`, desabilitado com a setlist vazia. Ele chama `assistirSetlist(context, s)`.
- Só no inglês com o curso carregado.

### 7.2b `SetlistPage`
- Ao lado de `setlist-tocar` (`setlist_page.dart:266`): `OutlinedButton.icon` **"📺 Assistir"** (`setlist-assistir`), desabilitado com a fila vazia, que chama `assistirSetlist(context, s)`. Num `Wrap` com o "Tocar", para caber em 360 px.
- Setlist sem nenhuma frase de lição do curso (só frases próprias): o botão continua, e o palco mostra o aviso D14 em cada faixa. (Não se esconde, para o comportamento ser previsível.)

### 7.3 `ouvir_acoes.dart`
- `Future<void> abrirTocando(BuildContext c, {bool? assistir})` repassa para `TocandoPage(assistir: assistir)`. Chamada sem o parâmetro = comportamento de hoje.
- **Novas** (todas salvam a pref com `PreferenciaAssistir.salvar(true)` **antes** de tocar, porque o `abrirTocando` volta cedo com `telaCheia` já true, e todas chamam `tocar` dentro do gesto, por causa do autoplay da web):
  - `Future<void> assistirSetlist(BuildContext c, Setlist s)` = `salvar(true)` + `preparar(1ª faixa)` + `tocarSetlist(c, s)` + `abrirTocando(c, assistir: true)`;
  - `Future<void> assistirCurso(BuildContext c, {int inicio = 0})` = o mesmo, sobre `tocarCurso(c, inicio:)`. O "Continuar" passa `inicio: parou` e o "Da minha lição atual" passa `inicio: atual` (os mesmos índices que o `_CartaoCurso` já calcula, `ouvir_page.dart:141-157`).
  - O cartão do curso só mostra `ouvir-assistir-continuar` quando há `fParou` (como o `ouvir-curso-continuar`).

### 7.4 Textos (pt-BR)
- Botão: "📺 Assistir" / "🖼️ Foto". Dica do botão: "Ver as frases como desenho animado".
- Setlist: tooltip "Escutar assistindo"; botão da `SetlistPage` "📺 Assistir".
- Cartão do curso: "📺 Escutar assistindo" · "Continuar" · "Da minha lição atual".
- Selo da autoral: "✨ história especial". Véu do timer: "🌙 Timer acabou".
- Sem desenho: "Sem desenho para esta frase (ela não é de uma lição do curso)".
- Véus: "⏸ Pausado: toque para continuar"; "🏁 Fim: ▶ de novo".
- Semantics do palco: "Desenho animado: {licaoNome}". O `rotuloSemantico` do cabeçalho do 📺 = "Desenho animado: {emoji} {licaoNome}".

---

## 8. Arte nova da fase 1 (grupos A e B)

### 8.1 Cenários (A) — todos interiores; `horasPermitidas` = as 4 horas; clima só chuva ou neve pela janela

| cenário | o que tem | cuidado |
|---|---|---|
| `videochamada` | o fundo é a tela de um app de chamada **sem marca**: barra superior escura com "● 09:00", grade escura e barra inferior com 🎤 📷 ☎️ (círculo vermelho). As molduras de webcam ficam **atrás de cada ator presente** (`MolduraWebcamPainter`, desenhado pelo palco, grupo C), cada uma com a "parede" de uma casa ou escritório diferente (estante, planta, quadro), com o índice escolhido pelo id do ator. Quem está `visivel: false` aparece como moldura apagada com as iniciais; ao `entra`, acende. | Alinhar com `PalcoHistoria.xsDo(size)` e com o `recuoFila` do retrato (2 filas). A moldura recorta na cintura (o ator inteiro "sentado na câmera"). O tamanho vem do corpo do ator. |
| `escritorio` | escritório aberto: mesas com monitores, cadeiras, planta, quadro branco e a janela com os prédios de Chicago (de noite, luzes acesas). | Sem marca nos monitores (só linhas de "código" coloridas). |
| `casa` | sala com cozinha americana: sofá, mesa com notebook, janela, estante, luminária e fogão/geladeira ao fundo. | A ficha do aluno: ele trabalha de casa (a mesa com o notebook é dele). |
| `restaurante` | mesas com toalha, balcão, quadro de cardápio ilegível, luminárias pendentes e a janela com a rua. **Sem pista.** | Serve para café e restaurante (o `cafe` do Turismo continua só do Turismo, na prática). |
| `loja` | prateleiras com caixas coloridas, balcão do caixa com a maquininha, cartazes de preço com números (`$`), porta de vidro. | Os números dos cartazes são genéricos (sem marca). |

**Spike da `videochamada` (I10), antes dos grupos paralelos:** o grupo A entrega em `$SP/arte_licoes/spike/` 3 opções em PNG (`toImage`, 390×844 com 2 filas e 2560×1080): (a) molduras atrás do tronco com o ator `sentado`; (b) molduras com recorte na cintura (`ClipRect` por ator); (c) grade de chamada com rostos (`RostoPersonagem`) em vez de corpos. O lead escolhe uma (e mostra ao dono, se tiver dúvida). A integração no palco (o recorte por ator dentro do `_Quadro`, alinhado com `xsDo` e o `recuoFila`) vira tarefa **do grupo C**, com teste em 390×844 e 2560×1080.

**Escolha do spike (lead, 22/out/2026): opção (b) — moldura de webcam atrás de cada ator, com o ator DE PÉ recortado na cintura** (`ClipRRect` por ator, no retângulo de `MolduraWebcamPainter.molduraDe(corpo)`). PNGs em `$SP/arte_licoes/spike/` (`a_sentado_*`, `b_recorte_*`, `c_rostos_*` em 390×844, 1280×720 e 2560×1080), feitos com o fundo placeholder da Phase 0.
- Por quê: (b) parece uma chamada de verdade e mantém o corpo da cintura para cima, então os gestos das historinhas (`acena`, `aponta`, `concorda`, `palmas`, `segura` café/notebook/documento) e o lip-sync do `PalcoHistoria` continuam valendo, com a mesma geometria (`xsDo`, `alturaDosAtores`). (a) `sentado` deixa as pernas penduradas abaixo da moldura e fica estranho; (c) só rostos perde os gestos e os props, que são o coração da encenação autoral.
- Regras para o **grupo C** (integração no `_Quadro`): (1) a moldura nunca invade a vizinha: largura ≤ `.92 ×` a menor distância entre posições ocupadas (no spike, com 4 atores, as molduras de `esquerda`/`centroEsquerda` se sobrepõem); (2) margem de cima ≥ `.15 h` acima da cabeça, para a mão do `acena`/`aponta` não ser cortada; (3) no retrato (2 filas), a moldura da fila da frente não pode cobrir o rosto da fila de trás: na `videochamada` o C pode usar **uma fila só** (sem `recuoFila`) e atores menores, ou subir a fila de trás até a moldura dela ficar inteira acima da da frente — escolher pelo que der rosto inteiro nos testes de 390×844; (4) quem está `visivel: false` = moldura apagada (com as iniciais) e acende no `entra`, sem deslocamento horizontal (o `entra` na `videochamada` é um esmaecer da moldura, não uma andança); (5) o balão continua ancorado na boca do ator (dentro da moldura).
- Regras para o **grupo A** (arte): o fundo da `videochamada` **não** desenha quadros de participantes (no placeholder eles aparecem e brigam com as molduras): só a "tela" do app (barra de cima "● 09:00", fundo escuro em grade, barra de baixo com 🎤 📷 ☎️). As 4 "paredes" das molduras (estante, planta, quadro, janela) ficam no `MolduraWebcamPainter` pelo `indice`, e a moldura de noite escurece junto com a hora.

**Base da suíte (Phase 0, 22/out/2026, HEAD bb13846, de `$SP/suite_vel.log`, sem rodar de novo): 2757 testes passando e 5 falhas conhecidas, todas em `test/csharp_curriculo_test.dart`.** Depois da fase 1 a suíte tem de dar 2757 + os novos, com as mesmas 5 falhas e nenhuma outra.

Requisitos de teste (já cobrados por `historia_fundo_test`, que percorre `CenarioHistoria.values`): `linhaDoChao` em [.6, .9]; horizonte < chão −.1; as 4 horas pintam diferente; distinto dos outros a 64×40 de noite; paralaxe periódica (≤ 0,4% de emenda).

### 8.2 Props (A)
`notebook` (aberto, tela azul com linhas), `prato` (com comida genérica), `sacola` (de papel, com alça), `documento` (folha com linhas, ou prancheta). Cada um com `tamanho` coerente e desenho visível na mão (`historia_ator_test`, `historia_props_efeitos_test`).

### 8.3 Figurantes (B)
- `FigurantesHistoria.ehFigurante(quem)` = não está em `elencoDasLicoes` ∪ {`max`, `kim`, `narrador`, `''`, `placa`}.
- `de(quem)`: uma **tabela fixa gerada** (`const`) para os 39 ids de `figurantesConhecidos`, conferida uma vez como "todas distintas entre si" (I11). Só um id **fora** da tabela (papel novo no currículo) cai na **paleta por hash estável** (FNV-1a sobre os bytes, não `String.hashCode`), com pele, cabelo, estilo e roupa sorteados de listas fixas. O gênero segue a lista feminina do `ElencoIngles` (atendente, recepcionista, recrutadora, diretora…). Uniformes por papel: `atendente`/`garcom` com avental, `recepcionista` com crachá (`detalhe`), `dra`/`farmaceutica` com jaleco branco, `motorista` com boné. Os 39 da tabela são distintos entre si (teste), então dois papéis na mesma lição nunca saem iguais; um id novo só precisa dar uma aparência não nula.
- `rotulo(quem)`: tabela (`dev-novo` → "Dev novo", `dev-nova` → "Dev nova", `amigo-do-ben` → "Amigo do Ben", `cfo` → "CFO", `dra-lee` → continua "Dra. Lee" pelo `ElencoTurismo`…). O padrão troca `-` por espaço e põe a 1ª letra maiúscula.
- **Só no palco.** O `RostoDaFaixa` do Ouvir e a lição continuam com `ElencoIngles.de` (as caras 'ela'/'ele' de hoje). Ver os riscos.

---

## 9. Tabela de propriedade (arquivos DISJUNTOS entre grupos paralelos)

Regra: um arquivo da Phase 0 marcado "→ X" só é tocado por X **depois** que a Phase 0 fechar (analyze limpo + foco verde). Nenhum grupo paralelo toca arquivo de outro. Conteúdo e ferramentas são escritos **só no scratchpad** (`$SP/historias_licoes/`); quem copia para o projeto é o lead (memória "não validar dentro do pac_dart").

### Phase 0 — lead (esqueleto que compila, sem mudança de comportamento)

| # | arquivo | conteúdo | depois → |
|---|---|---|---|
| 1 | `lib/features/arcade/presentation/historia/roteiro_visivel.dart` (novo) | 6.1 completo | — |
| 2 | `…/historia/roteiro_historia.dart` | 6.2 (`implements` + 4 getters, incluindo `escurecimento` com a fórmula movida do palco) | — |
| 3 | `…/historia/palco_historia.dart` | 6.2 (tipo da interface, `capitulo` opcional, `cabecalho`, `falaComVoz`, `roteiro.escurecimento` no lugar do `_escurecimento()`, repasse ao balão) | C |
| 4 | `…/historia/balao_fala.dart` | parâmetros `esconderEn`/`icone` aceitos e ignorados | C |
| 5 | `lib/features/arcade/domain/historia_turismo.dart` | 6.3: 5 cenários + 4 props no fim dos enums, `interioresHistoria`, `validarCenaBase` extraída (mensagens idênticas) | — |
| 6 | `…/historia/fundo_historia.dart` | 5 cases placeholder que passam nos testes | A |
| 7 | `…/historia/props_historia.dart` | 4 props placeholder | A |
| 8 | `…/historia/moldura_webcam.dart` (novo) | stub 6.12 | A |
| 9 | `…/historia/figurantes_historia.dart` (novo) | stub 6.12 | B |
| 10 | `…/historia/elenco_turismo.dart` | fiação 6.12 (saída idêntica hoje) | B |
| 11 | `lib/features/ingles/domain/assistir/historia_licao.dart` (novo) | 6.4 **completo** | — |
| 12 | `lib/features/ingles/domain/assistir/encenador_licao.dart` (novo) | stub válido 6.5 | D |
| 13 | `lib/features/ingles/domain/assistir/historias_licoes.dart` (novo) | stub 6.9 (`para` = automática; `preparar` no-op) | D |
| 14 | `lib/features/ingles/domain/assistir/compasso_assistir.dart` (novo) | stub 6.6 | C |
| 15 | `lib/features/ingles/data/historias_licoes_repo.dart` (novo) | 6.10 completo | — |
| 16 | `lib/features/ingles/data/preferencia_assistir.dart` (novo) | 6.11 completo | — |
| 17 | `lib/features/ingles/presentation/ouvir/assistir/roteiro_seguidor.dart` (novo) | stub 6.7 | C |
| 18 | `lib/features/ingles/presentation/ouvir/assistir/palco_assistir.dart` (novo) | stub 6.8 | C |
| 18b | `lib/features/ingles/presentation/ouvir/assistir/memoria_assistir.dart` (novo) | 6.7b **completo** (Expando por cubit, assina o stream uma vez, registra por índice) | — |
| 19 | `pubspec.yaml` | `- assets/ingles/historias/` (logo depois de `- assets/ingles/`) | — |
| 20 | `assets/ingles/historias/indice.json`, `encenacao_auto.json` | `{"versao":1,"trilhas":{}}` e `{"versao":1,"licoes":{}}` | lead (integração) |
| 21 | `test/historia_licao_modelo_test.dart` (novo) | fixture 5.4 como string const + uma `Trilha` montada no teste com os 8 trechos reais; parse estrito; âncoras com `en`/`pt` do currículo; `validarHistoriaLicao` vazio; **≥ 1 caso negativo por regra da 5.3**; tolerante descarta só a lição ruim; `validarCenaBase` com `personagens: personagensHistoria` dá **as mesmas mensagens** que antes (casos do `historia_modelo_test` reaproveitados); `HistoriaLicao.daLicao` monta as âncoras | — |
| 22 | `test/historias_licoes_repo_test.dart` (novo) | `AssetBundle` falso: índice ausente → `{}` sem lançar; falha não fica em cache; timeout → null; trilha fora do índice → null sem pedir o arquivo; a pref `en_ouvir_assistir` liga/desliga/erro → false; `PreferenciaAssistir.valor` muda na hora no `salvar` e fica false com erro no `carregar` | — |
| 23 | `test/assistir_memoria_test.dart` (novo) | `MemoriaAssistir` com um `OuvirCubit` real + `SaidaDeAudio` falsa: a mesma instância para o mesmo cubit; registra `viuTraducao` por índice e zera na troca; `ultimaFalaEnIndice`/`vezVista`; sobrevive a "minimizar" (o widget some, a memória fica); cancela a assinatura no `close` | — |

**Critério de saída:** `flutter analyze lib test` sem avisos; foco verde (`historia_*` [9 arquivos], `turismo_historia_conteudo_test`, `turismo_historia_integracao_test`, `progresso_historia_test`, `ingles_tocando_ui_test`, `ingles_mini_player_*`, `ingles_ouvir_*`, `ingles_fila_ouvir_test`, `ingles_config_ouvir_test`, mais os 3 novos).

**Phase 0 feita (lead, 22/out/2026) — desvios em relação às assinaturas, para os grupos saberem:**
- `validarCenaBase` ganhou um parâmetro opcional a mais, `String rotuloPasso = 'fala'` (o Turismo continua "fala n"; as lições passam `'passo'` e as mensagens saem "<licaoId> cena[i] passo n: …", como pede a L-base).
- `test/historia_fundo_test.dart` teve **uma** linha mudada (a contagem fixa `2 * 91 * 3 * 2 * 2` → `2 * 111 * 3 * 2 * 2`): ela conta os pares cenário/hora e quebra com qualquer valor novo no enum, que a §6.3 manda pôr. Nenhum outro teste antigo foi tocado.
- `HistoriasDaTrilha.fromJson(estrito: false)` também roda o `validarHistoriaLicao` em cada lição e descarta (com aviso) a que não valida — assim o app nunca usa uma história quebrada (frase nova no currículo cai na automática). No estrito, o parse não valida (o teste de conteúdo chama os dois).
- L-âncora "quem bate" é checada no parse (junto com os campos proibidos); o deslocamento na âncora, no validador.
- Campos públicos a mais, sem mudar as assinaturas: `HistoriasLicoes.bundle/timeout`, `RoteiroSeguidor.historiaDe/memoria`, `HistoriasLicoesRepo.timeoutPadrao`; `MemoriaAssistir.assinando` e `PreferenciaAssistir.reiniciar()` são `@visibleForTesting`.
- Já prontos além do stub (C confere e completa): em `CompassoAssistir`, `momento`, `ehVaoFinal`, `ancora`, `vaoFinal`, `duracaoMuda`, `fatorDeTempo`, `letrasPorSegundo`, `letrasPelaVoz` e `licaoDaFaixa` seguem as fórmulas do plano; só `planoDoVao` é vazio. O `EncenadorLicao` stub já valida nas 602 lições (conferido) e respeita `cenario`/`hora` da `EncenacaoManual`.
- O conteúdo do piloto está em `$SP/historia_licoes/` (singular; o plano às vezes diz `historias_licoes`): `primeiro-contato.json` e `numeros-horas-soletrar.json` passam no `HistoriasDaTrilha.fromJson(estrito: true)` + `validarHistoriasDaTrilha` do Dart com **0 erros** (conferido num teste temporário, já apagado).

**Spike (logo depois da Phase 0, antes dos paralelos):** o grupo A faz o spike da `videochamada` (§8.1) e o lead escolhe a opção. Os paralelos começam com a escolha registrada aqui. O lead registra a **base** da suíte inteira (número de testes e falhas conhecidas, hoje as 5 de `csharp_curriculo_test`, segundo o ESTADO) **antes** de começar.

### Grupos paralelos (depois da Phase 0)

| grupo | dono de (somente estes arquivos) | testes que escreve |
|---|---|---|
| **A — Arte (cenários, props, moldura)** | `…/historia/fundo_historia.dart`, `…/historia/props_historia.dart`, `…/historia/moldura_webcam.dart` | `test/historia_cenarios_licao_test.dart`: os 5 cenários × 4 horas × camadas em 360×640, 390×844 (retrato, 2 filas) e 2560×1080, sem exceção; `MolduraWebcamPainter.molduraDe` contém a cabeça e o tronco do ator para as 5 posições de `xsDo` nos 3 layouts; acesa ≠ apagada (pixels); as 4 props desenham algo, com tamanho dentro da caixa da mão. E garantir verdes: `historia_fundo_test`, `historia_props_efeitos_test`, `historia_ator_test`, `historia_render_enums_test`. Prova visual: PNGs pelo widget test (`matchesGoldenFile` **não**; salvar com `toImage` em `$SP/arte_licoes/` para o review). |
| **B — Elenco (figurantes)** | `…/historia/figurantes_historia.dart`, `…/historia/elenco_turismo.dart` | `test/historia_figurantes_test.dart`: todos os `quem` do currículo (lido por `dart:io`) → `ElencoTurismo.de` não nulo (exceto `''`/`placa`/narrador); em cada uma das 602 lições, figurantes diferentes têm `Aparencia` diferente; hash estável (valores fixos para 3 ids); `nomeDe` da tabela; **os 11 ids do Turismo + narrador com a saída idêntica à de hoje** (`de`, `nomeDe`, `corDe`, `perfilDeVoz`). `historia_ator_test` verde. |
| **C — Seguidor + palco do 📺** | `…/historia/palco_historia.dart`, `…/historia/balao_fala.dart`, `lib/features/ingles/domain/assistir/compasso_assistir.dart`, `lib/features/ingles/presentation/ouvir/assistir/roteiro_seguidor.dart`, `lib/features/ingles/presentation/ouvir/assistir/palco_assistir.dart` (+ bolinhas e véus como widgets privados dentro dele) | `test/assistir_compasso_test.dart` (puro): `ehVaoFinal` nos 3 modos × repetições 1–3 × com e sem `pt` (incluindo o `vez` velho do português→inglês); `vaoFinal` = o último `Silencio` de `passosDa` (+1,5 s no fim de lição); `planoDoVao` (mesma história e cena; troca de cena; outra lição com e sem tempo para abrir; pulo para trás); `fatorDeTempo` (≤ 1, > 1, infinity); `licaoDaFaixa`. `test/assistir_seguidor_test.dart`: sequência real de estados (gerada com `passosDa` + `OuvirState.copyWith`) → letras andam com `tick` na vez 1 e vêm completas na vez 2; `traducao` força o PT; `pense` → `esconderEn`; vão final toca os mudos e o estado final = `linhaDoTempo`; `irPara` arbitrário = estado da âncora; pausa congela (o `tick` não muda nada); outra lição troca a história (com esmaecer); a autoral chegando no meio da lição **não** troca até a próxima entrada; faixa órfã → `historia == null`; `reduzir` sem deslocamento. `test/assistir_palco_ui_test.dart`: `PalcoAssistir` com `OuvirCubit` real + `SaidaDeAudio` falsa (no molde do fake de `ingles_ouvir_cubit_test.dart:29`) + uma fixture de 2 lições; balão mostra o EN; `configurar(mostrarTraducao:false)` esconde o PT; lip-sync (`VozIngles.falando.value = FalaEmCurso(frase: en, boca: TrilhaBoca.compacta('0D 500X'), …)` → falante `Visema.d`, ouvinte `Visema.x`); bolinhas → `cubit.state.indice`; tocar no palco alterna; véus ⏸ e 🏁; 360×640, 390×844, 1400×900 e 2560×1080 com `textScaler 1.6` sem `takeException`; pausado → `hasScheduledFrame` falso; `pumpWidget(Container())` sem timer pendente. **Verdes obrigatórios:** `historia_player_test`, `historia_render_enums_test`, `historia_revisao_test`, `historia_velocidade_voltar_test`, `turismo_historia_integracao_test` (palco e balão do Turismo idênticos). |
| **D — Encenador + serviço** | `lib/features/ingles/domain/assistir/encenador_licao.dart`, `lib/features/ingles/domain/assistir/historias_licoes.dart` | `test/assistir_encenador_test.dart`: as **602 lições** do `assets/ingles/curriculo.json` real (por `dart:io`) → `encenar` → `validarHistoriaLicao` vazio; determinismo (2 rodadas iguais); < 15 s no total (folga para máquina carregada); nenhum cenário de `cenariosSoDoTurismo`; nunca max/kim; `placa` → narrador com 🪧; monólogo → `centro`; `oi-tudo-bem` → `videochamada` com a Ana entrando tarde; `treze-a-dezenove-o-teen` → `loja` (o caso "adapta**dor**"); a `EncenacaoManual` vence a heurística; a tabela de emojis (4.4) amostrada. `test/assistir_historias_licoes_test.dart`: `para` síncrono (automática → autoral só depois de `preparar` e na lição seguinte); trilha própria → null; arquivo com uma lição ruim → só ela cai na automática; a próxima trilha é pré-carregada. Também imprime em `$SP/historias_licoes/distribuicao.txt` a contagem de cenários (revisão do lead). |
| **E — Interface do Ouvir (playlist) + probe** | `lib/features/ingles/presentation/ouvir/tocando_page.dart`, `…/ouvir/ouvir_page.dart`, `…/ouvir/setlist_page.dart`, `…/ouvir/ouvir_acoes.dart`, `lib/main_arcade_probe.dart` (rota 11.3) | `test/ingles_assistir_tocando_test.dart`: `ouvir-assistir` só com faixa de lição; ligar troca `ouvir-imagem` → `assistir-palco` e some o `RostoDaFaixa`; a pref persiste e um novo `TocandoPage()` abre já assistindo; **padrão desligado = o layout de hoje**; selo "novo" some depois do 1º toque; ⛶ entra e sai (Esc sai da tela cheia, 2º Esc minimiza); espaço/←/→/R continuam; minimizar mostra `mini-player`; `abrirTocando(assistir: true)`; cartão `ouvir-assistir-curso` toca da lição atual e abre assistindo; 390/1400 px sem estouro; faixa órfã com o 📺 ligado → `assistir-sem-desenho`. **Verdes obrigatórios (sem editar):** `ingles_tocando_ui_test`, `ingles_mini_player_ui_test`, `ingles_mini_player_imagens_test`, `ingles_ouvir_ui_test`, `ingles_ouvir_app_test`, `treino_dia_ui_test`. |
| **F — Conteúdo + ferramentas (só scratchpad)** | `$SP/historias_licoes/` inteiro: `validar_historias_licoes.py`, `validar_historia.py` (cópia do validador do Turismo), `montar_contexto_lote.py`, `listar_por_cenario.py` (lê `encenacao_auto.json` e lista lições por cenário, para a prova visual), `RECEITA.md`, `PROMPT_LOTE.md`, `exemplo_licao.json`, `primeiro-contato.json`, `numeros-horas-soletrar.json`, `encenacao_auto.json` (as 602; ver 10.3) | Roda o Python até sair limpo nos 2 arquivos e no exemplo; o exemplo **tem de** passar também no `historia_licao_modelo_test` (o lead roda); revisão cruzada (o autor de uma trilha revisa a outra) contra o cânone §5.5 e §5.7, a coerência com o texto `cena` e a regra "cada lição se sustenta sozinha". |

**Acréscimos da revisão 2 por grupo** (valem junto com a tabela acima; os arquivos de cada grupo não mudam, exceto o `setlist_page.dart` no E):
- **A:** o spike da `videochamada` (§8.1) antes de tudo; o checklist dos placeholders (§6.12) vale também para a arte final.
- **B:** a tabela `const` dos 39 `figurantesConhecidos` (§8.3), com teste "39 aparências distintas entre si"; o hash só para id fora da tabela (teste: não nulo e estável para 3 ids inventados). O teste das 602 lições continua e fica trivialmente verde.
- **C:** (1) `escurecimento` do seguidor só em corte de verdade (D18) — teste: repetir a âncora `(0,0)` e a `(1,0)` 3 vezes → nenhum véu (`escurecimento == 0`) e nenhum `ColoredBox` preto sobreposto no `assistir_palco_ui_test`; (2) partida a frio e leitura da `MemoriaAssistir` (D17) — testes: seguidor nascendo no meio de `respiro` (vez 2 de 3), de `traducao` (inglês→português) e de `pense` (português→inglês) → âncora certa, `esconderEn` certo e nenhum mudo; UI: minimizar e reabrir no meio de um vão → mesmo passo, sem exceção; trocar 1400 → 800 px e entrar/sair do ⛶ → o `State` do palco é o mesmo (GlobalKey); (3) letras pela voz (I3) — teste com `FalaEmCurso` falso andando `segundo` → letras proporcionais, e sem `FalaEmCurso` por 0,6 s → velocidade por nível; (4) reancorar pelo `VozIngles.falando` (I4) — um fake que anuncia de novo a mesma frase sem novo emit do cubit faz as letras recomeçarem; (5) eco (I2) — no `suaVez` o balão fica nos primeiros 70% e os mudos só no fim; (6) timer (P8) — `pausado` com `motivo: timer` depois de mudar o índice mostra o estado final da lição anterior e o véu `assistir-timer`; (7) `ehVaoFinal` com `modoEfetivo` (P1): faixa sem `pt` tem vão final; (8) o recorte por ator na `videochamada` (opção escolhida no spike), testado em 390×844 e 2560×1080; (9) o `aoEstado(cubit.state)` no `initState` (P10); (10) Ticker por `TickerMode` (P7): com uma folha modal por cima, o Ticker continua; com uma rota opaca por cima, para.
- **D:** pré-carga (`prepararLicao`, `carregando`) e troca para a autoral na fronteira da faixa (I6) — teste: autoral chegando no meio da lição troca na faixa seguinte, nunca no meio; heurística com preposição e `call` restrito (I13) — casos "toma um café" ≠ `restaurante` e "no café" = `restaurante`; emojis normalizados por grafema (P5) e remoto sempre `parado` (P6); a `EncenacaoManual` aceita `mudos` com figurante de `figurantesConhecidos`.
- **E:** os botões da playlist (§7.2/7.2b) e `assistirSetlist`/`assistirCurso` (§7.3); o botão 📺 fora do bloco da foto (I8); a pref síncrona (I9). Testes novos no `ingles_assistir_tocando_test`: `setlist-assistir-s1` toca a setlist **e** abre assistindo; `setlist-assistir` na `SetlistPage` idem; `ouvir-assistir-continuar` e `ouvir-assistir-curso` com os mesmos índices dos botões de hoje; com `mostrarImagens: false` e o 📺 ligado → `assistir-palco` presente e `ouvir-assistir` visível; abrir pelo mini-player com a pref ligada → `assistir-palco` já no 1º `pump` (sem `ouvir-imagem` antes); o botão com `telaCheia` já true não perde o pedido. Os testes antigos usam só `Key`s (`setlist-tocar-s1`, `setlist-tocar`, `ouvir-curso-atual`), então acrescentar botões é seguro.
- **F:** `encenacao_auto.json` com as **602** entradas (I13); `fixtures/` + `--auto-teste` no Python (I12); o piloto da §17 com a `recepcionista` muda em `obrigado-desculpa-com-licenca` (D20); PNGs de **10 lições automáticas** sorteadas (uma por cenário) em `$SP/historias_licoes/amostra_auto/`, gerados pelo lead no widget test do D, para o dono ver antes de ligar o 📺 para todo mundo.

### Grupos sequenciais

| grupo | quando | dono de | testes |
|---|---|---|---|
| **Integração (lead)** | depois de A–F | copia `$SP/historias_licoes/{primeiro-contato,numeros-horas-soletrar,encenacao_auto}.json` → `assets/ingles/historias/` e atualiza `indice.json`; copia as ferramentas e a receita → `tools/ingles/historias/`; acrescenta `ESTADO-DO-PROJETO.md` (seção 📺) e uma linha em `tools/ingles/dados/DESIGN.md` §2.4 ou §5.5 ("as historinhas usam as frases da lição; ligações só atuadas; Max/Kim fora") | **escreve** `test/ingles_historias_licoes_conteudo_test.dart` (lê `indice.json` e todo `assets/ingles/historias/*.json` por `dart:io`, resolve contra o `curriculo.json`, `HistoriasDaTrilha.fromJson(estrito: true)` + `validarHistoriasDaTrilha` vazios; o índice lista **exatamente** os arquivos presentes; o `encenacao_auto.json` só tem ids existentes e enums válidos **e cobre as 602 lições**; nada de `cenariosSoDoTurismo`) e `test/historias_licoes_paridade_test.dart` (lê `tools/ingles/historias/fixtures/*.json` + `esperado.txt` e confere que o Dart dá **as mesmas mensagens**; o lead roda também `python3 -I tools/ingles/historias/validar_historias_licoes.py --auto-teste`). Roda foco + suíte. |
| **Review → fix** | depois da integração | revisão de código (seguidor × cubit: token/pausa/pulos, Ticker e visibilidade, dispose, timers, overflow, foco, desempenho no celular) + revisão de conteúdo (cena coerente, ações que combinam com a frase, cânone, nenhum inglês novo) | — |
| **Verificação final** | por último | **UM** build do probe + smoke Playwright (11.3) | — |

---

## 10. Pipeline de conteúdo ("aos pouquinhos")

### 10.1 Por que fica barato
O autor **não escreve inglês**: as falas são as frases da lição, já revisadas pelo pipeline do currículo. Ele decide lugar, hora, quem está onde, o que cada um faz, sente e segura, os mudos de ligação (≤ 4) e um título de ≤ 6 palavras. Estimativa: ~30–60 mil tokens por trilha (autor + revisor), contra os 7–8 milhões **por nível** do gerador de frases.

### 10.2 Receita de um lote (vai para `tools/ingles/historias/RECEITA.md`)
1. **Escolher** de 3 a 5 trilhas seguidas no currículo (≈ 15–25 lições). Ordem: A1 primeiro (29 trilhas), depois uma etapa por vez.
2. **Montar o contexto:** `python3 -I tools/ingles/historias/montar_contexto_lote.py <slug> [<slug>…] --saida $SP/lote_N/`. Para cada trilha, gera `contexto_<slug>.md` com: etapa e nível; o `arco` das 2 trilhas anteriores (se já existir); para cada lição, `id`, `nome`, `cena` (PT), `imagem`, foto (nome do arquivo) e a tabela das frases (`id`, `quem`, `cod`, `dica`, `img`); o elenco canônico (DESIGN §5.5, a ficha do aluno); os cenários e props **permitidos** (lidos por regex de `historia_turismo.dart`, menos os do Turismo); o exemplo 5.4; as regras 5.3.
3. **Autor** (1 agente por trilha), com `PROMPT_LOTE.md`, escreve `$SP/lote_N/<slug>.json`.
4. **Validar:** primeiro `python3 -I tools/ingles/historias/validar_historias_licoes.py --auto-teste` (a paridade com o Dart, I12); depois `python3 -I tools/ingles/historias/validar_historias_licoes.py $SP/lote_N/<slug>.json --curriculo assets/ingles/curriculo.json` até sair limpo (código 0).
5. **Revisor** (outro agente) confere: cena coerente com `cena` e com a foto; ação e emoção combinam com cada frase; continuidade (figurino, props, lugar) dentro da trilha; cada lição se sustenta sozinha; nada de Max/Kim, marcas ou cenário de corrida. Corrige e revalida.
6. **Lead:** copia para `assets/ingles/historias/`, acrescenta no `indice.json` (versão 1) e roda **só** `~/development/flutter/bin/flutter test test/ingles_historias_licoes_conteudo_test.dart`. A prova visual é opcional (2–3 lições, reaproveitando `build/probe`). Commit `📺 Histórias: lote N (trilhas …)`.
7. **Sem código.** Se um lote precisar de cenário ou prop que não existe, a lição usa o mais próximo e anota em `$SP/lote_N/pedidos_de_arte.md`. Os pedidos viram um **lote de arte** (12.2).
8. **"Só conteúdo" não é "sem publicar"** (P14): cada lote é asset do bundle. O dono só vê a historinha nova depois do build e do deploy de sempre. O lote termina no deploy, não no commit.
9. **Trilha regerada:** se uma trilha do currículo for regerada (ids aleatórios novos), as histórias dela caem na automática no app e o teste de conteúdo acusa. O lote daquela trilha precisa ser refeito (a receita é a mesma).
10. **O que fica fora do "só JSON"** (para ninguém prometer errado): pedidos de arte (código), o lote de voz das frases com `au` se o dono aprovar (D19: ferramenta + mp3, não JSON) e a paridade Python ↔ Dart (o `--auto-teste` tem de passar).

### 10.3 A tabela `encenacao_auto.json` (fase 1, grupo F)
- Classificação única das 602 lições. Entrada: `cena` + `imagem` + `quem` das frases. Saída: `cenario` (da lista permitida), `hora`, `remotos`, `entram`, `mudos`. É feita por trilha (121 chamadas pequenas, ~300–500 mil tokens no total) ou em blocos de 30 lições. **Grava as 602, explicitamente** (~40 KB; revisão 2, I13): o grupo F usa o `distribuicao.txt` do D só para revisar onde a heurística e a tabela discordam.
- Validação: o mesmo Python (`--tabela`), mais o teste de conteúdo.

### 10.4 `PROMPT_LOTE.md` (esqueleto)
```
Você vai ENCENAR (não escrever) as historinhas das lições da trilha <slug> do curso de inglês do Paclingo.
Cada lição já é uma cena: as frases (tabela) são as falas, NA ORDEM, ditas por quem está em `quem`.
Você NÃO escreve inglês nem português de fala. Para cada lição, escreva só:
- titulo {en: até 6 palavras, A1, ASCII; pt}
- 1 (ou 2) cenas: cenario (lista permitida), hora, clima (normalmente []), elenco com pos/segura/emocao/visivel, objetos
- passos: um {"frase": "<id>"} para CADA frase, na ordem, com acao/emocao/camera/alvo/reacoes/segura que combinem
  com o sentido da frase e o emoji `img`; até 4 passos {"mudo": true, ...} para ligar as falas (entrar, sentar,
  mostrar um objeto, acenar no fim). Deslocamentos (entra/anda/sai...) SÓ em passo mudo.
Regras: elenco do DESIGN §5.5 + os papéis que falam na lição + até 2 figurantes mudos da lista fixa (nunca Max/Kim);
1–2 cenas (3 lugares na cena = junte dois no mesmo cenário); mudos ≤ 3 por cena, ≤ 2 seguidos, ≤ 4 na lição;
titulo obrigatório; ficha do aluno (trabalha de casa,
adora café...); cada lição faz sentido sozinha, mas mantenha a continuidade da trilha (arco em 1–2 frases no
campo "arco"); nada de marca, tema sensível ou cenário de corrida/espaço.
Formato: exatamente o esquema e o exemplo anexos. Rode o validador e só entregue com 0 erros.
```

---

## 11. Validação

### 11.1 Estático
`~/development/flutter/bin/flutter analyze lib test` sem nenhum aviso.

### 11.2 Testes
**Novos** (por grupo, seção 9): `historia_licao_modelo_test`, `historias_licoes_repo_test`, `assistir_memoria_test` (Phase 0); `historias_licoes_paridade_test` (integração); `historia_cenarios_licao_test` (A); `historia_figurantes_test` (B); `assistir_compasso_test`, `assistir_seguidor_test`, `assistir_palco_ui_test` (C); `assistir_encenador_test`, `assistir_historias_licoes_test` (D); `ingles_assistir_tocando_test` (E); `ingles_historias_licoes_conteudo_test` (integração).

**Antigos que prendem o que muda** (verdes, **sem edição**):
- Turismo/história: `historia_ator_test`, `historia_fundo_test`, `historia_galeria_test`, `historia_modelo_test`, `historia_player_test`, `historia_props_efeitos_test`, `historia_render_enums_test`, `historia_revisao_test`, `historia_velocidade_voltar_test`, `progresso_historia_test`, `turismo_historia_conteudo_test`, `turismo_historia_integracao_test`, mais os do arcade/turismo (`turismo_*`, `arcade_*`, `ingles_boca_test`, `ingles_cartoes_ui_test`).
- Ouvir: `ingles_tocando_ui_test`, `ingles_mini_player_ui_test`, `ingles_mini_player_imagens_test`, `ingles_ouvir_cubit_test`, `ingles_ouvir_ui_test`, `ingles_ouvir_app_test`, `ingles_fila_ouvir_test`, `ingles_config_ouvir_test`, `ingles_setlist_test`, `ingles_setlists_cubit_test`, `ingles_setlists_repository_test`, `treino_dia_ui_test`.

Foco (o lead roda; ninguém mais roda `flutter build`):
```
~/development/flutter/bin/flutter test \
  test/historia_licao_modelo_test.dart test/historias_licoes_repo_test.dart test/assistir_memoria_test.dart \
  test/historias_licoes_paridade_test.dart test/ingles_setlist_test.dart \
  test/historia_cenarios_licao_test.dart test/historia_figurantes_test.dart \
  test/assistir_compasso_test.dart test/assistir_seguidor_test.dart test/assistir_palco_ui_test.dart \
  test/assistir_encenador_test.dart test/assistir_historias_licoes_test.dart \
  test/ingles_assistir_tocando_test.dart test/ingles_historias_licoes_conteudo_test.dart \
  test/historia_ator_test.dart test/historia_fundo_test.dart test/historia_galeria_test.dart \
  test/historia_modelo_test.dart test/historia_player_test.dart test/historia_props_efeitos_test.dart \
  test/historia_render_enums_test.dart test/historia_revisao_test.dart test/historia_velocidade_voltar_test.dart \
  test/progresso_historia_test.dart test/turismo_historia_conteudo_test.dart test/turismo_historia_integracao_test.dart \
  test/ingles_tocando_ui_test.dart test/ingles_mini_player_ui_test.dart test/ingles_mini_player_imagens_test.dart \
  test/ingles_ouvir_cubit_test.dart test/ingles_ouvir_ui_test.dart test/ingles_ouvir_app_test.dart \
  test/ingles_fila_ouvir_test.dart test/ingles_config_ouvir_test.dart test/treino_dia_ui_test.dart
```
Suíte inteira: `~/development/flutter/bin/flutter test`. Deve dar a base registrada na Phase 0 + os novos, sem falha nova. Nenhum `test/_*_test.dart` pode sobrar. Teste antigo **não** é editado para passar.
Testes com `tester.runAsync` (o app): o carregamento do asset da história e o Ticker do palco precisam de tempo real entre os pumps. O `PalcoAssistir` não usa `Timer`, só o Ticker.

### 11.3 Prova visual (UM build, uma pasta reaproveitada)
**Probe certo:** `lib/main_arcade_probe.dart`. Ele já é o probe sem Firebase, com as rotas do inglês (`_ingles(...)` liga `Linguagem.ingles` dentro do builder). O `main.dart` exige Firebase e login.

Rota nova (grupo E): `'/assistir-en': (_) => _ingles(const _AssistirProbe())`. A `_AssistirProbe`:
- lê `Uri.base.queryParameters['licao']` (padrão `primeiro-contato.oi-tudo-bem`) e `['modo']` (`so`|`ep`|`pe`);
- monta `RepositoryProvider(NavegadorOuvir())`, `BlocProvider(SetlistsCubit(repo: LocalSetlistsRepository('probe'))..carregar())` (**sem ele, `_semOuvir` devolve true e `tocarCursoDesde`/`abrirTocando` voltam sem fazer nada**, `ouvir_acoes.dart:29`), `BlocProvider(CursoBloc(loader: CurriculoLoader(linguagem: Linguagem.ingles), progresso: LocalProgressoRepository(prefixo: 'en_'))..add(const CursoIniciado()))` e `BlocProvider(OuvirCubit(saida: saidaPadrao()))`;
- **por baixo dos providers**, um `Navigator(key: _nav.chave, observers: _nav.observadores, onGenerateRoute:` (com `final _nav = NavegadorOuvir()` guardado no State da `_AssistirProbe` e passado ao `RepositoryProvider.value`), (_) => MaterialPageRoute(builder: (_) => const _AssistirInicio()))` próprio. O `abrirTocando` já prefere `NavegadorOuvir.de(c)?.chave.currentState`, então o `TocandoPage` empurrado fica **embaixo** dos providers (empurrar no Navigator do `MaterialApp` deixaria a rota ao lado deles, e o `OuvirCubit.de` daria null: `Scaffold` vazio, `tocando_page.dart:150`);
- a `_AssistirInicio`, com as trilhas carregadas, mostra um botão grande **"▶ Assistir"**. O clique é o gesto que libera o áudio na web, e chama `configurar(modo)` + `PreferenciaAssistir.salvar(true)` + `tocarCursoDesde(ctx, licao)` + `abrirTocando(ctx, assistir: true)`. Com `?setlist=1`, cria uma setlist "Probe" com 2 lições e usa `assistirSetlist` (prova a porta da playlist);
- **o mini-player não existe no probe** (ele vive no `OuvirShell` do `MaterialApp.builder` do app). "Minimizar mostra o mini-player" e "reabrir no meio do vão" ficam **só** nos widget tests (C e E).

Passos:
1. Build, uma vez, sem builds paralelos: `~/development/flutter/bin/flutter build web -t lib/main_arcade_probe.dart --release --output=build/probe --no-wasm-dry-run`.
2. Servir: `python3 -m http.server 8788 --directory build/probe` (em background).
3. Playwright (`browser_run_code_unsafe`; screenshots em `$SP/smoke_assistir/`):
   - desregistrar o service worker e limpar os caches;
   - `addInitScript`: `window.__audios = []` embrulhando `HTMLMediaElement.prototype.play` (empurra `this.src`); TTS falso (embrulha `speechSynthesis.speak`, empurra `u.text` em `window.__falas`, `onstart` + `onend` em 700 ms); `window.__erros` por `pageerror` e `console.error`;
   - **1280×720**, `/?licao=primeiro-contato.oi-tudo-bem#/assistir-en`: clicar em "▶ Assistir" (coordenada ou Tab+Enter, como na receita 8.3 do Turismo); screenshots em +1, +3, +6 e +10 s com **hashes diferentes**; `__audios[0]` termina com o mp3 de "Good morning, Mike!" (o nome sai de `assets/ingles/vozes.json`); ≥ 3 mp3 distintos em 10 s; revisão visual: o palco `videochamada` com molduras, o balão com o chip "Você", e a Ana entrando depois da 4ª frase;
   - `Space` → véu ⏸ (screenshot) → `Space` volta; `ArrowRight` → a próxima frase; o chip "Tradução" desliga o PT do balão;
   - `&modo=pe` → no `pense`, o balão com "…" e o PT (screenshot);
   - `R` três vezes na 1ª frase → **nenhuma** tela escura nas screenshots (D18); as letras recomeçam (I4);
   - `&setlist=1` → a setlist "Probe" abre já assistindo (a porta da playlist), com o chip "✨ história especial" nas lições do piloto;
   - **uma lição automática de cada cenário novo** (`escritorio`, `casa`, `restaurante`, `loja`) e uma de `aeroporto`, escolhidas com `python3 -I tools/ingles/historias/listar_por_cenario.py` (lê `encenacao_auto.json`). Uma screenshot de cada, mais uma de uma lição com figurante (atendente);
   - ⛶ tela cheia em 1280×720 e em **844×390** (paisagem de celular);
   - **390×844** (retrato: 2 filas e molduras alinhadas) e **360×640**: sem estouro visível e o balão legível;
   - **2560×1080** nativo (nunca HiDPI 2048×864): uma screenshot;
   - o Turismo continua igual: `/#/historia-en1` → "▶ Assistir" → 2 screenshots (o palco e o balão do Turismo sem mudança visível).
4. Aceite: `window.__erros` vazio (exceto o aviso das fontes Noto); todas as screenshots; hashes diferentes no tempo; o 1º áudio certo.
5. Limpeza: matar o servidor e `find build/probe -delete` (memória: não deixar builds nem criar pastas novas a cada teste).

---

## 12. Plano de lotes

### 12.1 Conteúdo (só JSON, sem código)

| lote | trilhas | lições |
|---|---|---|
| 1 (fase 1) | `primeiro-contato`, `numeros-horas-soletrar` | 12 |
| 2 | as 3–4 trilhas seguintes do A1 (`eu-e-voce-be`, …) | ~18 |
| 3–8 | o resto do A1, de 4 em 4 trilhas | ~106 (A1 = 136) |
| depois | A2 → B1 → B2 → C1 → DEV, uma etapa por vez, lotes de 4–5 trilhas | 466 |

Cada lote = receita 10.2 (termina no build + deploy, não no commit). O que não tem história autoral continua com a automática, e o app nunca fica sem desenho.

**Lote de voz (opcional, D19, só com o "sim" do dono):** Chirp por personagem para as 410 frases com `au` (+ bocas do Rhubarb) e a chave `AudioNativo.preferirGeradaDoPersonagem` ligada só com o 📺 visível. Ferramenta + assets de voz + 1 teste; não é JSON de história.

### 12.2 Arte (código pequeno e isolado; a ordem segue os pedidos de `pedidos_de_arte.md`)
`consultorio` (substitui `clinica` na tabela das lições), `salaDeAula`, `metro` (ônibus/trem), `parque`, `recepcaoHotel`, `academia`/`cinema`; props `cardapio`, `cartao`, `caixaDeMudanca`, `fone`, `mochila`, `bolo`, `copo`, `oculos`, `remedio`, `ingresso`, `carroComum`. Cada lote de arte = os valores no **fim** do enum + painter + `interioresHistoria` (se for o caso) + os testes que já percorrem `values`. Depois, uma entrada na tabela do encenador ou do `encenacao_auto.json`.

---

## 13. Persistência e o que NÃO muda
- **Novas:** prefs `en_ouvir_assistir` (bool) e `en_ouvir_assistir_visto` (bool). Só local, nada no Firestore.
- **Não mudam:** `en_concluidas`, `en_trilha`, `en_licao`, `en_quiz_notas`, `en_ouvir_cfg`, `en_ouvir_pos_<uid>`, setlists, FSRS, e as prefs `en_turismo_historia_*` (vistos `i#`/`f#`/`c#`, pt, voz, auto, lenta, vel, perdidos).
- `ConfigOuvir.toJson` não ganha campo, então as setlists e a config salvas continuam compatíveis em versões antigas.
- Dart e C#: o `OuvirCubit` só existe com `Linguagem.ingles` (main.dart:388-401), então nenhuma tela deles vê o 📺.

---

## 14. Riscos e mitigação

| risco | mitigação |
|---|---|
| Duas vozes se cortando (roteiro + cubit) e o Ouvir pausando com "outra fala" | D2: o seguidor não tem voz e não avança sozinho; o teste do palco confere que nenhum `saida.en` extra é chamado pelo palco. |
| Quebrar o Turismo ao generalizar o palco | A interface só abstrai os getters que o palco já lê; `RoteiroHistoria` sem mudança de comportamento; `CabecalhoPalco.doCapitulo` reproduz textos e Semantics **idênticos**; `player_historia.dart` intocado; 12 testes da história + integração no foco; screenshot do `historia-en1` no smoke. |
| Enum novo quebrando os testes que percorrem `values` | Os valores entram no **fim**; a Phase 0 já põe placeholders que passam; A fecha a arte com os mesmos testes; `validar_historia.py` lê os enums por regex (os novos entram sozinhos); os 30 capítulos não usam os valores novos (o `turismo_historia_conteudo_test` continua vazio). |
| As mensagens do validador mudarem na extração | `validarCenaBase` é recorte puro, com `porFala` no mesmo ponto; o `historia_licao_modelo_test` compara as mensagens antigas; o `historia_modelo_test` e o `turismo_historia_conteudo_test` no foco. |
| `vez` desatualizado (o `irPara`/`continuar` não zeram) enganando o "vão final" | O seguidor só confia em `vez` depois de uma FalaEn da mesma faixa e guarda `viuTraducao` por índice; há caso dedicado no `assistir_compasso_test`. |
| Vão curto (pausa curta 0,5 s) sem tempo para os mudos | `fatorDeTempo` acelera ou salta para o estado final (sempre coerente pela `linhaDoTempo`); o balão não pisca quando não há o que animar. |
| Heurística de cenário errando (protótipo: "adapta**dor**" → clínica; "No fim da primeira chamada" → escritório) | Fronteira de palavra + o 1º lugar citado; a tabela `encenacao_auto.json` (conteúdo) corrige sem código; o teste fixa os casos conhecidos; `distribuicao.txt` vai para revisão. |
| 2/3 das lições são de trabalho ou chamada, e os cenários de hoje são de corrida | 5 cenários novos na fase 1 (D8); `cenariosSoDoTurismo` proibidos nas lições; os lotes de arte cobrem o resto. |
| Videochamada com mais de 2 remotos impossível no modelo atual | Na `videochamada` todos estão presentes, dentro de molduras (sem `ViaRemota` nova); até 5 participantes, que é o máximo do currículo. |
| Figurantes clones (2 papéis 'ela' iguais) e rótulos feios ("Dev-novo") | `FigurantesHistoria` com **tabela fixa** para os 39 ids conhecidos (todos distintos) + hash só para id novo + uniformes; teste com as 602 lições; tabela de rótulos. Fica uma **diferença assumida**: no palco a atendente tem cara própria, enquanto no `RostoDaFaixa` e na lição continua o 'ela' genérico. Unificar depois, se o dono quiser, mexendo em `ElencoIngles` e nos seus testes. |
| **Voz trocando de gênero no desenho**: 410 frases (7,7%) tocam a gravação do Tatoeba (`au`) em vez da voz do personagem (voce 164, ana 67, mike 56, sarah 28, ben 28, emma 26…), muitas na voz masculina do CK. **No piloto: 9 frases** (`f-53836f`, `f-a8842b`, `f-698356` em `obrigado-desculpa-com-licenca`; `f-16b51e`, `f-098e80`, `f-a2c597` em `nao-entendi-pode-repetir`; `f-52c0fe` em `cem-mil-e-os-precos`, a Ana em "That's expensive."; `f-72efdb` em `que-horas-sao`; `f-9bf25d` em `como-se-escreve-soletrar`, a Sarah em "How do you spell it?") | Visível e decidido com o dono (D19). A fase 1 não mexe no áudio. Se o dono aprovar, o **lote de voz** (§12.1) resolve sem tocar no cubit. A prova visual registra como soam as 9 frases do piloto para o dono decidir ouvindo. |
| Colisão do `vozes.json` (a mesma frase por dois personagens toca a voz de um) | Herdada do curso (a lição já soa assim; na prática, 2 frases); fora do escopo; anotada no ESTADO. |
| O seguidor perdendo o fio ao minimizar, trocar de layout ou entrar no ⛶ | `MemoriaAssistir` por cubit + partida a frio + `GlobalKey` (D17); testes de UI de minimizar/reabrir e de troca de largura. |
| Palco piscando a cada repetição da 1ª frase | `RoteiroVisivel.escurecimento` (D18); teste com 3 repetições de `(0,0)` e `(1,0)`; screenshot do `R` no smoke. |
| A 1ª lição do piloto saindo na versão automática | Pré-carga ao abrir o `OuvirPage` e nos botões 📺, espera de até 400 ms e troca na fronteira da faixa (I6). |
| As 590 automáticas decepcionando depois da autoral | PNGs de 10 automáticas para o dono antes de ligar; o selo "✨ história especial" deixa a diferença clara (D21). |
| Python e Dart divergindo nas regras | Fixtures compartilhados + `--auto-teste` + `historias_licoes_paridade_test` (I12). |
| Trilha regerada no currículo (ids novos) | As histórias dela caem na automática (nunca quebram); o teste de conteúdo avisa; o lote é refeito (receita). |
| Layout do `TocandoPage` mudando e quebrando os testes antigos | O padrão é desligado (D10); o 📺 só troca o bloco da imagem quando está ligado; 390/1400 px no teste novo. |
| Desempenho no celular (palco de 3.400 linhas de fundo a 60 fps dentro de uma página que reconstrói a cada emit) | `RepaintBoundary`; o palco só escuta o seguidor; o Ticker para em pausa, fora do topo e com o app oculto; "reduzir" = 10 fps; o 📺 começa desligado. |
| Asset da trilha falhando offline | `cache:false`; falha não fica em cache; timeout de 8 s; a automática cobre na hora; a troca para a autoral só na próxima lição (sem pular no meio). |
| Texto do currículo mudando depois de a história ser escrita (frase nova ou id novo) | Âncora por `Trecho.id`, com o texto puxado na hora; L-cobertura no teste de conteúdo pega a frase nova; no app, a lição cai na automática (nunca em história quebrada). |
| Conteúdo "aos pouquinhos" perdido porque o scratchpad some | Ferramentas, receita e prompt vão para `tools/ingles/historias/` na integração; o scratchpad é só a área de trabalho do lote. |
| Max/Kim ou mundos de corrida vazando para as lições | L-elenco e L-cenário/props no Dart e no Python; o encenador nunca os escolhe (teste). |
| Gênero do PT (aluna) | Igual à lição (`dica` masculina padrão); a lição não tem `pt_f`. Quando o curso ganhar gênero, o palco herda pelo `Trecho`. |
| Áudio na web exigindo gesto (o probe e o 1º play) | Hoje o Ouvir já começa por um toque; no probe, o botão "▶ Assistir" é o gesto. |
| `rotaArcade` pausando o Ouvir | O 📺 não abre rota: vive no `TocandoPage`. |
| Builds travando o Mac (memória de 12–13/out) | UM build no fim, na pasta `build/probe` (reaproveitada e apagada depois); os grupos só rodam `flutter test`. |

---

## 15. Crítica considerada (revisão 2, 22/out/2026)

Fonte: `$SP/critica_historias_licoes.md`. Legenda: ✅ entrou como a crítica pediu · ◐ entrou em parte (ou ficou para o dono decidir) · ✗ não entrou (com o motivo).

### Bloqueadores
| # | ponto | | o que foi feito | onde |
|---|---|---|---|---|
| B1 | o seguidor morre ao minimizar, trocar de layout e no ⛶ | ✅ | as duas correções juntas: `MemoriaAssistir` por cubit (Expando, assina o stream uma vez) **e** a regra de partida a frio; `GlobalKey` no `PalcoAssistir`; testes de nascer no meio de `respiro`/`traducao`/`pense` e de minimizar/reabrir | D17, §3.1, §3.3, §3.5, §6.7, §6.7b, §9 (Phase 0 #18b/#23, acréscimos C) |
| B2 | escurece ou pisca a cada repetição | ✅ | `RoteiroVisivel.escurecimento`; o Turismo leva a fórmula de hoje **sem mudança**; o seguidor só escurece em corte de verdade; `noTitulo = false` e `duracaoTituloAtual = 0` explícitos | D18, §6.1, §6.2, §6.7, §9 |
| B3 | a prova visual não roda | ✅ | `SetlistsCubit` no probe e `Navigator` próprio **embaixo** dos providers (com `NavegadorOuvir` e seus observadores); mini-player só nos widget tests | §11.3 |

### Importantes
| # | ponto | | o que foi feito | onde |
|---|---|---|---|---|
| I1 | faltam entradas na **playlist** | ✅ | é o pedido do dono, então virou a porta principal: 📺 em cada setlist (`setlist-assistir-<id>`), "📺 Assistir" na `SetlistPage` (`setlist-assistir`), o cartão do curso com **Continuar** e "Da minha lição atual"; `setlist_page.dart` entrou no grupo E | §0, D1, §7.2, §7.2b, §7.3, §9 |
| I2 | eco: o balão fecha na hora "Sua vez" | ✅ | a 1ª opção: no `suaVez`, balão fica nos primeiros 70% do vão, mudos só nos 30% finais (`fracaoDoEco`) | §3.3, §6.6 |
| I3 | a máquina de escrever não acompanha a voz | ✅ | letras pela posição real do áudio (`fc.segundo(agora)` ÷ `f.segundos/fator`), com recuo para a velocidade por nível depois de 0,6 s sem `FalaEmCurso` | §3.3, §6.6 (`letrasPelaVoz`), §6.7 (`aoFalar`) |
| I4 | "R" e `irPara` no mesmo índice podem não emitir | ✅ | o seguidor também escuta `VozIngles.falando`: `FalaEmCurso` nova da âncora = reancorar; cubit intocado | §3.1, §3.3, §6.7 |
| I5 | 410 frases com voz do Tatoeba trocando de gênero | ◐ | risco **visível** com a contagem e os **9 ids do piloto**; decisão do dono (D19); o "lote de voz" (Chirp para as 410 + `AudioNativo.preferirGeradaDoPersonagem`) fica pronto para quando ele disser sim. ✗ para a opção 2 sozinha: sem a voz gerada (o `vozes_google.py` pula as frases com `au`), a chave não teria o que tocar | D19, §3.6, §12.1, §14 |
| I6 | a 1ª lição pode sair automática | ✅ | (a) pré-carga ao abrir o `OuvirPage` e em todo botão 📺; (b) espera de até 400 ms com a foto (`assistir-carregando`); (c) troca para a autoral na fronteira da próxima faixa | §3.5, §6.8, §6.9, §7.2 |
| I7.1 | mudos: "≤ 4 na história" contra "≤ 3 por cena" | ✅ | regra escrita como "≤ 3 por cena e ≤ 2 seguidos (herdados) e ≤ 4 na história" | §5.3 (L-cenas), §16, RECEITA §6.1 |
| I7.2 | o elenco proíbe o figurante calado | ✅ | até **2 figurantes mudos** de `figurantesConhecidos` (36 do currículo + `oficial`, `garcom`, `vendedora`); `obrigado-desculpa-com-licenca` já usa a `recepcionista`. ✗ para "o campo `mudos` também na autoral": o `elenco` da cena já diz quem está presente, um 2º campo duplicaria (o `mudos` continua só no `encenacao_auto.json`) | D20, §5.3 (L-elenco), §6.4, §16, RECEITA §4 |
| I7.3 | cenas com 3 lugares | ◐ | ficam **2 cenas no máximo**: o autor junta dois lugares no mesmo cenário (recepção e corredor no mesmo `escritorio`); regra no prompt e na receita. Subir para 3 deixaria a lição de 25–40 s com cortes demais | §5.3, §10.4, RECEITA §7.5 |
| I8 | com "Imagens" desligado, o 📺 some | ✅ | botão em posição fixa (linha do `ChipFase`), palco independente de `mostrarImagens` e de `temImagem`; teste dedicado | §7.1, §9 (acréscimos E) |
| I9 | a pref assíncrona faz o palco piscar | ✅ | `PreferenciaAssistir.valor` (`ValueNotifier`), carregado uma vez, lido síncrono; salvar **antes** de abrir | D10, §6.11, §7.1, §7.3 |
| I10 | `videochamada` pouco especificada | ✅ | spike de 3 opções em PNG pelo grupo A antes dos paralelos; o recorte por ator vira tarefa testada do grupo C | §8.1, §9 |
| I11 | "figurantes diferentes" impossível com hash | ✅ | tabela fixa `const` para os 39 ids, distintos entre si; hash só para id novo | §6.4, §8.3, §9 (acréscimos B) |
| I12 | Python vai divergir do Dart | ✅ | `fixtures/` compartilhados, `--auto-teste` no Python e `historias_licoes_paridade_test` no Dart; a receita roda o auto-teste antes de validar | §5.3, §9 (integração), §10.2 |
| I13 | heurística (`cafe` bebida, `call`) e tabela "só o que difere" | ✅ | preposição de lugar obrigatória, `call` só em contexto de reunião; `encenacao_auto.json` com **as 602** explícitas | D6, §4.1, §4.5, §10.3 |

### Pequenos
| # | | o que foi feito |
|---|---|---|
| P1 | ✅ | `modoEfetivo = temPt ? modo : soIngles`; faixa sem `pt` tem vão final (§3.3, teste C-7). |
| P2 | ✅ | motivo da D5 corrigido: o mp3 aceitaria 0,5; fica fora por coerência dos chips e testes. |
| P3 | ✅ | D1 fala do "fluxo da lição (`ingles_ui_test`, `ingles_cartoes_ui_test`)". |
| P4 | ✅ | limite do encenador subiu para 15 s (não foi tirado: ainda pega uma regressão grosseira). |
| P5 | ✅ | emojis sem `U+FE0F`, por grafema; teste com `☝️🐌` e `👩‍🎨❓` (§4.4). |
| P6 | ✅ | remoto sempre `parado`, só emoção e efeito (§4.4). |
| P7 | ✅ | `TickerMode` (via `TickerProviderStateMixin`) em vez de `ModalRoute.isCurrent` (§3.5). |
| P8 | ✅ | timer: estado final da lição anterior + véu "🌙 Timer acabou" (`assistir-timer`) (§3.3). |
| P9 | ◐ | o `ouvir-en` continua (menor); esmaecê-lo com `Opacity` fica para o dono decidir depois do piloto (§7.1). |
| P10 | ✅ | `aoEstado(cubit.state)` no `initState`, com teste (§3.1, §6.7). |
| P11 | ✅ | regra do `quem: ''` mantida, sem custo (D16). |
| P12 | ✅ | checklist das 5 regras dos placeholders (§6.12). |
| P13 | ✅ | exemplo §5.4 rodado: **0 erros** no checador provisório; plano B `aponta` escrito. |
| P14 | ✅ | "o lote termina no deploy" na receita (§10.2, §12.1). |

### Qualidade da encenação automática (seção 4 da crítica)
| ponto | | o que foi feito |
|---|---|---|
| PNGs de 10 automáticas para o dono antes de ligar para todos | ✅ | §9 (acréscimos F): `$SP/historias_licoes/amostra_auto/`. |
| selo "✨ história especial" nas autorais | ✅ | D21, §6.8 (`assistir-especial`). |
| trilha regerada derruba as histórias dela | ✅ | §10.2 passo 9, §14. |

---

## 16. Esquema final do JSON da história de lição (v1)

Um arquivo por trilha: `assets/ingles/historias/<slug>.json` (no lote: `$SP/historia_licoes/<slug>.json`). UTF-8, 2 espaços. Chaves desconhecidas = erro em todos os níveis.

```jsonc
{
  "versao": 1,                                   // obrigatório, sempre 1
  "trilha": "<slug>",                            // obrigatório; = nome do arquivo = prefixo do Licao.id
  "arco": "<pt-BR, ≤ 300 caracteres>",           // opcional (recomendado): o fio da trilha
  "licoes": {                                    // obrigatório; chaves = Licao.id desta trilha
    "<Licao.id>": {
      "titulo": { "en": "<1–6 palavras, ASCII>", "pt": "<pt-BR>" },   // OBRIGATÓRIO na autoral (D21)
      "cenas": [                                 // 1 ou 2
        {
          "cenario": "<CenarioHistoria>",        // obrigatório; nunca cenariosSoDoTurismo
          "hora": "amanhecer|dia|tarde|noite",   // obrigatório; dentro de horasPermitidas(cenario)
          "clima": [],                           // opcional; padrão []
          "elenco": [                            // obrigatório; ≤ 5 presentes, ≤ 2 remotos
            { "quem": "<id>",                    // elencoDasLicoes ∪ falantes da lição ∪ ≤ 2 de figurantesConhecidos
              "pos": "esquerda|centroEsquerda|centro|centroDireita|direita",  // obrigatório se presente; único na cena
              "visivel": true,                   // opcional; false = entra depois por um mudo `entra`
              "remoto": "celular",               // opcional; sem `pos`; só `parado`; alguém no palco segura celular
              "segura": "<PropHistoria>",        // opcional; nunca "nada" aqui; nunca propsSoDoTurismo
              "emocao": "<Expressao>" }          // opcional; padrão neutro
          ],
          "objetos": [ { "prop": "<PropHistoria>", "pos": "<PosicaoPalco>", "visivel": true } ],  // ≤ 4, pos única
          "passos": [                            // ≥ 1 âncora por cena
            // ÂNCORA: uma por frase da lição, todas, na ordem da lição, uma vez só
            { "frase": "<Trecho.id>",            // obrigatório
              "quem": "<id>",                    // opcional; se vier, = quemNoPalco(trecho.quem)
              "acao": "<AcaoAtor>",              // nunca entra|anda|corre|sai|dirige|desce
              "emocao": "…", "alvo": "<ator ou prop visível>", "camera": "geral|medio|close|dupla|aproxima",
              "efeito": "…", "segura": "<prop|nada>", "reacoes": [ … ≤ 4 ], "objetos": [ … ≤ 3 ],
              "clima": [ … ], "hora": "…", "cenario": "…" },
              // PROIBIDOS na âncora: "en", "pt", "pt_f", "mudo" (o texto vem do currículo pelo id)
            // MUDO: ação sem texto, toca no silêncio entre as frases
            { "mudo": true, "quem": "<ator presente>", "acao": "…", "para": "<pos>", "emocao": "…",
              "efeito": "…", "segura": "…", "reacoes": [ … ], "objetos": [ … ] }
              // tem de acontecer algo; ≤ 3 por cena, ≤ 2 seguidos, ≤ 4 na lição
          ]
        }
      ]
    }
  }
}
```

| regra | resumo (detalhe na §5.3) |
|---|---|
| texto | nenhum inglês/português de fala no JSON; passo com texto sem `frase` = erro (ligação só atuada) |
| cobertura | cada `Trecho.id` da lição exatamente uma vez, na ordem; nenhum id desconhecido |
| elenco | 9 canônicos ∪ quem fala na lição ∪ até 2 figurantes mudos de `figurantesConhecidos`; nunca `max`/`kim`; `placa`/`''` → narrador (fora do `elenco`, sem ação, sem `close`) |
| cenários bons | `videochamada`, `escritorio`, `casa`, `restaurante`, `loja`, `aeroporto`, `hotel`, `clinica`, `cidade`, `praia`, `lago`, `ponte` (os do Turismo com pista ou exóticos passam no validador, mas a receita veta) |
| props novas | `notebook`, `prato`, `sacola`, `documento` |
| base | toda a `SimulacaoCena` do Turismo (`validarCenaBase` com `validarTextos: false`) |

Arquivos irmãos (mesma pasta):
```jsonc
// indice.json — slug → versão do arquivo da trilha. Só listar arquivo que existe.
{ "versao": 1, "trilhas": { "primeiro-contato": 1, "numeros-horas-soletrar": 1 } }

// encenacao_auto.json — uma entrada para CADA uma das 602 lições (correção da automática)
{ "versao": 1, "licoes": { "<Licao.id>": {
    "cenario": "<CenarioHistoria>", "hora": "<HoraHistoria>",           // sempre presentes
    "remotos": { "<quem>": "celular" }, "entram": ["<quem>"], "mudos": ["<quem>"] } } }   // opcionais
```

---

## 17. Lote piloto (fase 1): a lista exata

**2 trilhas · 12 lições · 104 frases · etapa A1 · Fundação (nível do palco `a1`).** Ids conferidos no `assets/ingles/curriculo.json` em 22/out/2026. Arquivos: `$SP/historia_licoes/primeiro-contato.json` e `$SP/historia_licoes/numeros-horas-soletrar.json` (o grupo F escreve; o lead copia para `assets/ingles/historias/`).

| # | Licao.id | frases | quem fala | cenário previsto | observações |
|---|---|---|---|---|---|
| 1 | `primeiro-contato.oi-tudo-bem` | 8 | voce, mike, ana | `videochamada` | o exemplo oficial (§5.4); a Ana entra depois da 4ª frase |
| 2 | `primeiro-contato.prazer-ate-amanha` | 8 | voce, mike, ana, sarah | `videochamada` | a Sarah entra atrasada; todos acenam no rabo |
| 3 | `primeiro-contato.obrigado-desculpa-com-licenca` | 8 | voce, sarah | `escritorio` (uma cena) | **figurante mudo** `recepcionista`; Mike mudo; 3 frases com `au` |
| 4 | `primeiro-contato.nao-entendi-pode-repetir` | 8 | voce, mike | `videochamada` | Sarah muda (a cena a cita); 3 frases com `au` |
| 5 | `primeiro-contato.cena-a-primeira-chamada` | 8 | voce, mike, ana, sarah | `videochamada` | revisão: a Sarah entra atrasada; o `voce` termina `determinado` |
| 6 | `numeros-horas-soletrar.zero-a-doze-o-telefone` | 11 | voce, sarah, mike, ana | `videochamada` | o `voce` anota no `documento` |
| 7 | `numeros-horas-soletrar.treze-a-dezenove-o-teen` | 11 | voce, atendente | `loja` | o caso "adapta**dor**" da heurística |
| 8 | `numeros-horas-soletrar.vinte-a-noventa-e-nove-o-hifen` | 10 | voce, atendente | `loja` | vai ao caixa; `sacola` no rabo |
| 9 | `numeros-horas-soletrar.cem-mil-e-os-precos` | 8 | voce, ana | `loja` (Ana pelo `celular`) | exemplo da receita §12; 1 frase com `au` (a Ana) |
| 10 | `numeros-horas-soletrar.que-horas-sao` | 8 | voce, mike | `videochamada`, `noite` | noite no Brasil; 1 frase com `au` |
| 11 | `numeros-horas-soletrar.como-se-escreve-soletrar` | 8 | voce, sarah, ana | `videochamada` | a Sarah anota; 1 frase com `au` (a Sarah) |
| 12 | `numeros-horas-soletrar.cena-o-cadastro-por-telefone` | 8 | voce, sarah | `casa` (Sarah pelo `celular`) | ligação para Austin (sem "Austin" no título) |

Critério de pronto do piloto: os 2 arquivos com **0 erros** no `receita_ferramentas.py checar` e no validador oficial (com `--auto-teste` passando), revisão cruzada feita, `ingles_historias_licoes_conteudo_test` verde no projeto, e as 12 lições com o selo "✨ história especial" na prova visual. As 9 frases com `au` (§14) ficam registradas para o dono ouvir e decidir o D19.
