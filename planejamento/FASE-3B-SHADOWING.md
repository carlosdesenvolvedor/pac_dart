# Fase 3, parte 2 — Shadowing: ouvir, repetir falando, conferir por palavra

> Plano para execução por um agente. Escrito em 13/out/2026. Contexto: [`MELHORIAS-PESQUISA.md`](MELHORIAS-PESQUISA.md) (Fase 3, item 2). Modelo de formato: [`FASE-5-ESCRITA-CORRIGIDA.md`](FASE-5-ESCRITA-CORRIGIDA.md).
> **Só vale para o curso de Inglês.** A parte 1 (ditado "🎧 Áudio → escrever") já está feita e é o molde: o shadowing é "o ditado, mas a pessoa FALA".
> ⚠️ **Depende do reconhecedor de voz do dono, que segue SEM commit** (arquivos novos não rastreados). O dono autorizou construir em cima dele **sem editá-lo** (13/out/2026).

## 1. Objetivo e o que a pessoa vai ver

Novo sentido do cartão de virar, **"🗣 Ouvir e repetir"**, ao lado de EN → PT / PT → EN / Misturado / 🎧 Áudio → escrever:

1. **Ouve:** a frente do cartão mostra só o áudio ("🗣 Ouça e repita"), **sem o texto da frase**. O áudio toca sozinho ao abrir (se "áudio automático" estiver ligado, como no ditado); 🔊 e 🐢 ouvem de novo (R também).
2. **Repete falando:** a pessoa toca no **🎤 Falar** (precisa de um toque, é regra do navegador), diz a frase em inglês e o microfone fecha sozinho quando ela para (ou toca de novo para parar). Enquanto fala aparece o que o reconhecedor está ouvindo ("…").
3. **Confere por palavra:** o resultado vem pelo mesmo `avaliarFala` que o palco já usa: o que foi ouvido, as **palavras da frase marcadas** (certa / faltou ou trocada) e as que sobraram ("a mais" não reprova).
   Se não saiu perfeito, a pessoa pode **tentar de novo (até 3 tentativas)** — a frase continua escondida — ou **"Mostrar a frase"**.
4. **Vira:** perfeito, ou 3ª tentativa, ou "Mostrar a frase": o cartão vira — aparecem o inglês (com as palavras erradas sublinhadas), a tradução e as 4 notas, com **a nota sugerida marcada** (mesmo botão `_notas` de sempre). A pessoa decide a nota; o FSRS cuida do resto.

Tom: acolhedor. Falar é difícil para muita gente — a tela diz o que foi ouvido, nunca "você errou". **A conferência é do reconhecedor, não de pronúncia:** o texto avisa que ele confere se as PALAVRAS saíram, não o sotaque.

## 2. Decisões já tomadas (o agente segue; o dono pode mudar)

| # | Decisão | Por quê |
|---|---|---|
| D1 | **Só Inglês**, dentro do `SessaoCartoesPage` (como o ditado): `SentidoCartao.shadowing` (id `shadowing`, rótulo "🗣 Ouvir e repetir"). **Sem página nova**: a fila, o FSRS, o banner de nível, o "DE NOVO" e as 4 notas já vivem ali. | Reuso máximo; menos arquivos sujos do dono para mexer. |
| D2 | **Não edito o reconhecedor do dono** (`reconhecedor_*.dart`, `fala_nativo.dart`, `avaliacao_fala.dart`, `voz_ingles.dart`, `frase_view.dart`, `ingles_fala_test.dart`). Só **importo** a API pública: `ReconhecedorFala` (`.navegador()`, `suportado`, `ouvir`), `SessaoFala`, `ErroFala`, `avaliarFala`, `AvaliacaoFala`. Se a API mudar, eu ajusto o meu lado. | Regra de convivência + o dono pediu. |
| D3 | **Mesma conferência do palco** (`avaliarFala(frase, hipoteses, alternativas:)`): caixa/pontuação não contam, contração = forma plena, número por extenso, homófonos, nomes pelo SOM. Eu **não** crio outra régua. | Já é testada pelo dono. |
| D4 | **Até 3 tentativas** por cartão; a frase só aparece ao virar. A tentativa vale quando o reconhecedor entrega hipóteses; "não entendi nenhuma palavra" (`av.nada`) **não conta** como tentativa (pede de novo, sem castigo). | Shadowing cobra repetir; sem laço infinito. |
| D5 | **Nota sugerida** (função pura `notaDoShadowing`): melhor tentativa **perfeita na 1ª** ⇒ **Bom**; perfeita na 2ª ou 3ª ⇒ **Difícil**; não perfeita mas **≥ 70%** das palavras certas na melhor tentativa ⇒ **Difícil**; menos que isso, ou "Mostrar a frase"/sem fala ⇒ **Errei**. **"Fácil" só a pessoa escolhe** (igual a `ComparacaoResposta`). A pessoa sempre pode trocar a nota. | Mesma filosofia do cartão escrito; régua pública e testável. |
| D6 | **Sem nível** (Fácil/Médio/Avançado não se aplicam: a resposta é falada) ⇒ o seletor de nível some neste sentido; o cartão **não entra na série de subida/descida de nível** (Fase 6) e **"Misturado" nunca sorteia o shadowing** (como o ditado). | A série é por degrau de escrita. |
| D7 | **Sem microfone/sem suporte** (`!suportado`: Firefox, Safari, desktop nativo, VM de teste; ou permissão negada; ou `ErroFala.naoSuportado`) ⇒ o cartão **vira ditado Avançado automaticamente** (reusa tudo que existe) com uma linha: "Este aparelho não reconhece voz — hoje é ditado: escreva o que ouviu." Nunca trava a revisão. | O estudo nunca é bloqueado. |
| D8 | **O app se cala enquanto o microfone está aberto** (`_voz.parar()` antes de ouvir) — senão o reconhecedor ouve o próprio áudio do app (o palco já faz isso por `onMicrofone`). O áudio automático só toca quando o microfone está fechado. | Armadilha conhecida do dono. |
| D9 | **Nada de áudio do aluno guardado**: o app não grava nem salva o que a pessoa fala; só recebe o TEXTO do reconhecedor. O painel diz, uma vez, que **o reconhecimento é feito pelo navegador/sistema (no Chrome, num servidor: precisa de internet)**. | Honestidade sobre privacidade e rede. |
| D10 | **Mesma cota/agenda de sempre**: a nota do shadowing é a nota do cartão (sem cartão novo, como no ditado). **A IA não participa** (nada de cota de IA aqui). Conta no hábito diário pelo mesmo gancho do cartão (1ª nota). Nada vai ao ranking. | Zero superfície nova. |
| D11 | **Sem pacote novo, sem `pubspec.yaml`, `firestore.rules`, `android/`, `ios/`.** O pacote `speech_to_text` já está no `pubspec` (do dono). | Regras do repositório. |

### Perguntas em aberto (o agente usa o **padrão** e registra no relatório final)

1. **Quantas tentativas?** Padrão **3**.
2. **Limiar do "Difícil" por palavras?** Padrão **70%**.
3. **A frase some mesmo?** Padrão: **sim**, só aparece ao virar (o shadowing do dono pode querer um "espiar" — fica como ideia).
4. **Atalho de teclado?** Padrão: **Espaço** inicia/pára o microfone e **R** ouve de novo (o resto do cartão já usa Enter/1–4). Cuidado: o microfone no navegador exige que o início venha de um gesto; a tecla é um gesto de usuário e vale (testar no Chrome).
5. **Voz do Prof. Dash nos cenários** (a outra metade do item do dono): **fora deste plano** — usa as mesmas peças (reconhecedor + `avaliarFala` não serve para conversa livre, pede outra conferência) e vira um plano próprio, se o dono quiser.

## 3. Contexto técnico (o que reaproveitar — e o que NÃO tocar)

- **Reconhecedor (API pública, só ler):** `lib/features/ingles/data/reconhecedor_fala.dart` — `ReconhecedorFala.navegador()` (web: Web Speech API; Android/iOS: `speech_to_text`; VM de teste: "não suportado"), `bool suportado`, `SessaoFala ouvir({idioma='en-US', aoParcial, aoFinal(List<String> hipoteses), aoErro(ErroFala), aoFim})` — **`aoFim` sempre vem, uma vez, por último**; `SessaoFala.parar()` entrega o que ouviu, `.cancelar()` desiste; `ErroFala {semPermissao, semMicrofone, semRede, naoOuviu, naoSuportado, outro}`.
- **Conferência:** `lib/features/ingles/domain/avaliacao_fala.dart` — `avaliarFala(frase, ditos, alternativas) → AvaliacaoFala {palavrasOk[], ouvidas[], ouvidaCasou[], perfeita, nada, erradas, aMais, acertos, palavras}`.
- **Padrão de uso já existente:** `lib/features/ingles/presentation/widgets/frase_view.dart` (do dono, **não editar**): `_escuta`, `_vezEscuta` (descarta avisos de escuta velha), `onMicrofone`, mensagens de erro por `ErroFala` (copiar o TEXTO das mensagens para o meu widget, não importar privados), `FraseView.fabricaReconhecedor` (static para testes).
- **Onde encaixar:** `lib/features/ingles/presentation/sessao_cartoes_page.dart` (já sujo, **edição pontual**): `_calcularPtEn`, `_prepararCartao` (`_audioAtual`), `_instrucao`, `_cartao` (`soAudio`), `_revelar`, `_notas`, teclas (R), seletor de sentido (linha ~687) e `SentidoCartao.values`. O ditado é o molde: copie o que ele faz com `_audioAtual`.
- **Enum:** `lib/features/ingles/domain/nivel_resposta.dart` → `SentidoCartao.shadowing`. Só `sessao_cartoes_page.dart` usa `SentidoCartao` (conferido) — os `switch` exaustivos de lá precisam do caso novo.
- **Pref do sentido:** `SentidoCartao.porId` já lê o id novo; id desconhecido volta ao misturado (JSON/pref antigos seguem valendo).
- **Probe:** `lib/main_portfolio_probe.dart` não tem reconhecedor falso. No Chrome headless/Playwright **não há microfone nem reconhecimento** ⇒ a prova no Chrome usa um **reconhecedor falso injetado** (`SessaoCartoesPage.reconhecedor`/`fabrica`), igual ao que os testes usam; **a prova com voz de verdade é do dono**, num Chrome/celular reais (pedir no relatório).
- ⚠️ **Árvore suja:** backup em `scratchpad/` de cada arquivo sujo antes de editar; nada de `checkout/restore/stash/reset/clean`; `git status --short` no início e no fim.

## 4. Modelo de dados (tudo novo, Dart puro)

`lib/features/ingles/domain/shadowing.dart`:

```
const maxTentativasShadowing = 3;
const limiarShadowing = 0.70;                 // fração de palavras certas que ainda vale "Difícil"

class TentativaShadowing { AvaliacaoFala avaliacao; }     // uma fala conferida (a "nada" não vira tentativa)

class SessaoShadowing                         // máquina de tentativas pura, por cartão
  final List<AvaliacaoFala> tentativas
  SessaoShadowing registrar(AvaliacaoFala a)  // ignora `nada`; ignora se já encerrou
  bool get encerrou                           // perfeita OU 3 tentativas
  bool get perfeita
  AvaliacaoFala? get melhor                   // a de mais acertos (a 1ª em empate)
  Rating notaSugerida({bool desistiu = false})  // D5

Rating notaDoShadowing({required int tentativas, required AvaliacaoFala? melhor, bool desistiu = false})
```

`lib/features/ingles/presentation/widgets/painel_shadowing.dart` (widget novo, só apresentação + o microfone): recebe `ReconhecedorFala`, `frase`, `alternativas`, callbacks `onTentativa(AvaliacaoFala)`, `onMicrofone(bool)`, `onMostrarFrase`; guarda a escuta (`_vezEscuta`, como o dono faz).

## 5. Regras (o que os testes de domínio precisam provar)

**`notaDoShadowing` (tabela):** perfeita na 1ª ⇒ Bom · perfeita na 2ª ⇒ Difícil · perfeita na 3ª ⇒ Difícil · 3 tentativas, melhor com 80% ⇒ Difícil · melhor com 70% exato ⇒ Difícil · 69,9% ⇒ Errei · melhor 0% ⇒ Errei ·
sem tentativas / desistiu ⇒ Errei · desistiu depois de uma tentativa com 90% ⇒ Errei (mostrou a frase) · **nunca devolve Fácil**.

**`SessaoShadowing`:** `registrar(nada)` não conta · perfeita encerra na hora · 3ª não perfeita encerra · depois de encerrar, `registrar` é ignorado · `melhor` = mais acertos, empate = a primeira · tentativas em ordem.

**Integração com `avaliarFala`:** frase com contração dita por extenso ⇒ perfeita · homófono ⇒ perfeita · palavra trocada ⇒ aponta a errada · `alt:` do autor vale.

## 6. Passo a passo

**Etapa 1 — Domínio** · `domain/shadowing.dart` + `nivel_resposta.dart` (`SentidoCartao.shadowing`; **edição pontual** — é arquivo sujo) · `test/ingles_shadowing_test.dart` (as tabelas da seção 5; `SentidoCartao.porId('shadowing')`; ids únicos; "Misturado" não o sorteia).

**Etapa 2 — Painel** · `presentation/widgets/painel_shadowing.dart`: estados *pronto / ouvindo (com parcial) / conferido (palavras marcadas + o que foi ouvido + "a mais") / sem entendimento / erro (mensagem por `ErroFala`) / sem suporte (avisa e pede o ditado)*;
botões **🎤 Falar** (vira **⏹ Parar** enquanto ouve), **Tentar de novo** (n/3), **Mostrar a frase**; texto fixo "o reconhecimento confere as palavras, não o sotaque"; D9 uma vez.
Tokens `Mixart.*`, tema claro/escuro, 360 px, **sem `TextField`** (nada de armadilha de foco), `Semantics`/`Tooltip` nos botões, teclas **Espaço** (falar/parar) e **R** (ouvir). `_voz.parar()` antes de abrir o microfone (D8).
Testes `test/ingles_shadowing_ui_test.dart` com um **reconhecedor falso** (como o de `test/ingles_fala_test.dart`, que só leio para copiar o jeito): estados, parcial, 3 tentativas, nada-entendido não conta, erro por tipo, sem suporte, não deixa o microfone aberto ao sair da tela (cancela), `aoFim` tardio de escuta velha é ignorado.

**Etapa 3 — Ligar no cartão** · `sessao_cartoes_page.dart` (**backup + edição pontual**): `_shadowAtual` (como `_audioAtual`) · `_calcularPtEn` (inglês a responder) · `_prepararCartao` (zera a `SessaoShadowing`; sem suporte ⇒ cai no ditado Avançado) · `_instrucao` · `_cartao` (frente = áudio + `PainelShadowing`, sem texto da frase; depois de virar, mostra a frase com as palavras erradas sublinhadas) · `_revelar` com `sugerida: sessao.notaSugerida()` ·
seletor de nível some neste sentido · fora da série de nível · seletor de sentido (rótulo/descrição "Shadowing: ouça e repita falando; a frase só aparece depois") · `SessaoCartoesPage.reconhecedor` (injetável, null = `ReconhecedorFala.navegador()`).
Testes `test/ingles_shadowing_cartao_test.dart`: cartão inteiro (fala perfeita ⇒ vira, sugerida Bom; 2ª ⇒ Difícil; 3 falhas ⇒ Errei; mostrar a frase ⇒ Errei), a frente sem texto, sem tradução também funciona, sem suporte ⇒ ditado, "Misturado" não sorteia, o "DE NOVO" não conta no hábito, fora da série de nível, tradução/inglês depois de virar.

**Etapa 4 — Probe** · `main_portfolio_probe.dart` (**backup + pontual**): injeta um reconhecedor falso que devolve hipóteses combinadas (1ª tentativa com 1 palavra trocada, 2ª perfeita) para a prova no Chrome.

**Etapa 5 — Teste de app** · `test/ingles_shadowing_app_test.dart` (modelo `ia_cenario_app_test.dart`): `PacDartApp` inteiro, Inglês → Baralhos/Revisão → sentido 🗣 → ouvir → falar (falso) → conferir → nota sugerida → nota → agenda do cartão muda; ranking intacto; sem suporte vira ditado.

**Etapa 6 — Mutações** (script no scratchpad; backup → troca UMA string → roda os testes da fase → restaura e confere por hash; em segundo plano, sem editar o código enquanto roda). **Etapa 7 — Chrome real** (probe, 1027 e 390 px). **Etapa 8 — `ESTADO-DO-PROJETO.md`** (seção "🗣 Shadowing — Fase 3, parte 2", e atualizar a nota "Falta da Fase 3").

## 7. Casos de borda (todos viram teste)

Sem suporte (Firefox/desktop/VM) · permissão negada · sem microfone · sem internet (`semRede`) · `naoOuviu` · reconhecedor sem palavra (`nada`) · fala perfeita de primeira · palavra trocada · palavra a mais · contração/homófono/número/nome · `alt:` do autor · frase de 1 palavra · frase com pontuação só · frase muito longa (≤ 300) ·
tocar em Falar duas vezes seguidas (1 escuta só) · `aoFim` antes/depois do `aoFinal` · escuta velha respondendo depois de o cartão mudar (ignorada) · sair da tela com o microfone aberto (cancela e `onMicrofone(false)`) · "DE NOVO" (cartão errado volta; a nota do repasse não conta no hábito) ·
cartão sem tradução · cartão de lacuna da leitura (`alvo`) no sentido shadowing (vira shadowing normal, a frase inteira) · virar o dia no meio · tema claro · 360 px · fonte de teste.

## 8. Critérios de aceite

- [ ] Em Baralhos/Revisão o sentido **"🗣 Ouvir e repetir"** aparece; a frente é **só o áudio** (sem texto), toca sozinho (com "áudio automático") e tem 🔊/🐢/R.
- [ ] **🎤 Falar** abre o microfone **a partir de um toque/tecla**, mostra o que está sendo ouvido, fecha sozinho e confere por **palavra** com `avaliarFala`; as palavras marcadas e as "a mais" aparecem; **a frase continua escondida** até virar.
- [ ] Até **3 tentativas**; "não entendi nada" **não conta**; "Mostrar a frase" vira na hora.
- [ ] Ao virar: o inglês (palavras erradas sublinhadas), a tradução e as 4 notas com **a sugerida marcada** pela regra D5 (Bom só na 1ª perfeita; **nunca Fácil sozinha**); a pessoa pode trocar.
- [ ] **O app se cala** quando o microfone abre e **não deixa o microfone aberto** ao virar, trocar de cartão ou sair.
- [ ] **Sem suporte/permissão** ⇒ vira ditado Avançado com aviso e **a revisão nunca trava**.
- [ ] Sem nível, **fora da série** de subida/descida de nível; "Misturado" não sorteia; o "DE NOVO" segue sem contar no hábito; a IA não é chamada; nada vai ao ranking.
- [ ] **Nenhum arquivo do reconhecedor do dono foi editado** (`reconhecedor_*`, `fala_nativo`, `avaliacao_fala`, `voz_ingles`, `frase_view`, `ingles_fala_test`): `git diff` deles igual ao do início.
- [ ] Sem `pubspec.yaml`/`firestore.rules`/`android/`/`ios/`.
- [ ] `dart analyze lib test` limpo; `flutter test`: só as 5 falhas antigas do C# (baseline 1.050; 1.045 passam); testes novos verdes.
- [ ] **Mutações pegas** (restaurar e conferir por hash): (a) Bom também na 2ª perfeita; (b) devolver Fácil; (c) limiar 60% em vez de 70%; (d) "nada" contando como tentativa; (e) 4 tentativas em vez de 3; (f) mostrar o texto da frase na frente; (g) não parar a voz do app ao abrir o microfone; (h) microfone aberto ao sair da tela (sem cancelar); (i) sem suporte não cair no ditado; (j) "Misturado" sorteando o shadowing; (k) shadowing entrando na série de nível; (l) escuta velha aceita depois de trocar de cartão; (m) "Mostrar a frase" sugerindo Bom; (n) empate escolhendo a última tentativa; (o) nota não vinda da melhor tentativa.
- [ ] **Prova no Chrome** (probe com reconhecedor falso, 1027 e 390 px, sem erro de console). **A prova com microfone real fica para o dono** (Chrome com internet e/ou celular) — registrar no relatório o roteiro de 2 minutos.
- [ ] `ESTADO-DO-PROJETO.md` atualizado. **Nada commitado, nada publicado.** `git status --short` igual ao do início, exceto os arquivos desta fase.

## 9. Fora do escopo (não fazer)

Voz nos cenários com o Prof. Dash (plano próprio) · avaliar pronúncia/sotaque/prosódia · gravar ou guardar o áudio do aluno · modo shadowing em vídeo/legenda · nota por IA · "espiar a frase" · tocar o áudio ao mesmo tempo que a pessoa fala (shadowing "simultâneo": o reconhecedor ouviria o app) ·
editar o reconhecedor do dono · mudar a régua de `avaliarFala` · `pubspec`/`android`/`ios`/`firestore.rules`.

## 10. Como verificar

```bash
cd /Users/fazplay/pac_dart
flutter test test/ingles_shadowing_test.dart test/ingles_shadowing_ui_test.dart test/ingles_shadowing_cartao_test.dart test/ingles_shadowing_app_test.dart
dart analyze lib test
flutter test                                   # só as 5 falhas antigas de csharp_curriculo_test (baseline 1.050; 1.045 passam)
git diff --stat -- lib/features/ingles/data/reconhecedor_fala.dart lib/features/ingles/domain/avaliacao_fala.dart   # nada (arquivos do dono)
```

**Chrome real (probe, reconhecedor falso):** `flutter build web -t lib/main_portfolio_probe.dart --output=build/probe_ia` → `python3 -m http.server 8793 --directory build/probe_ia` → Playwright em `http://localhost:8793/` a 1027 e 390 px.
⚠️ Flutter web: **não** ligue a acessibilidade; dirija por coordenadas e teclado; observe `pageerror`. Caminho: HUD ⇄ → tecla **3** (Inglês) → **Esc** → **Revisão** (ou Mapa → Baralhos) → sentido **🗣** → ouvir → **🎤 Falar** (o falso responde: 1ª tentativa com uma palavra trocada, 2ª perfeita) → palavras marcadas → virar → nota sugerida **Difícil** → nota.
**Roteiro do dono (2 min, Chrome com internet ou celular):** abrir Revisão → 🗣 → permitir o microfone → ouvir → falar a frase certa (deve virar com "Bom") → falar errado de propósito 3× (deve virar com "Errei") → negar a permissão (deve cair no ditado).
Ao terminar: `pkill -f "http.server 8793"` e fechar o navegador.
