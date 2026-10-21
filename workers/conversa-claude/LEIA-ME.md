# Worker da Conversa com IA (Cloudflare)

Este Worker fica entre o app e a Anthropic: o app manda o ID token do Firebase, o Worker confere quem é o aluno, aplica os limites do dia e chama o Claude com a chave que **só existe no servidor**.

## Colocar no ar (uma vez)

**a) Conta Cloudflare.** Crie em <https://dash.cloudflare.com/sign-up> (o plano grátis serve para começar).

**b) Teto de gasto na Anthropic.** No Console da Anthropic (<https://console.anthropic.com>) → *Settings → Limits*, defina um **limite de gasto mensal**. É a proteção final se algo der errado.

**c) Instalar e entrar:**

```sh
cd workers/conversa-claude
npm install
npx wrangler login
```

**d) Criar o KV dos limites:**

```sh
npx wrangler kv namespace create LIMITES
```

Copie o `id` que aparecer e cole no `wrangler.toml`, no lugar de `COLE_AQUI_O_ID_DO_KV_LIMITES` (ou peça ao Claude para colar).

**e) Guardar a chave da Anthropic como segredo:**

```sh
npx wrangler secret put ANTHROPIC_API_KEY
```

O terminal pede o valor: cole a chave **ali**. Nunca no chat, nunca em arquivo do repositório.

**f) Publicar:**

```sh
npx wrangler deploy
```

Anote a URL que aparecer, no formato `https://paclingo-conversa.<seu-subdominio>.workers.dev`. É ela que o app vai usar.

**g) Testar:**

```sh
curl https://paclingo-conversa.<seu-subdominio>.workers.dev/saude
# → {"ok":true}
```

Um `POST /v1/turno` sem token deve responder `401` com `{"erro":"nao_autenticado",...}`.

## Ligar no app (sem novo deploy do app)

O app já sabe usar o Worker, mas vem **desligado**: enquanto nada for configurado, a Conversa continua no Gemini como sempre.
Só os turnos da **💬 Conversa com IA** vão para o Claude; o Prof. Dash, o "Por quê?", a Escrita, o toque na palavra e o
Turismo continuam no Gemini.

**Ligar.** No console do Firebase → Firestore → coleção `config`, documento `tutor` (o mesmo da chave do Gemini), crie dois
campos do tipo *string*:

| campo | valor |
|---|---|
| `provedorConversa` | `claude` |
| `urlConversa` | `https://paclingo-conversa.<seu-subdominio>.workers.dev` (a URL do passo f, **sem** `/v1/turno`) |

O app aberto percebe a mudança em até **~5 min** (ou na hora, recarregando a página). Só vale `https://…`; `http://` só com
`localhost`/`127.0.0.1` (o `npx wrangler dev`). Qualquer outro valor (campo vazio, outro provedor, URL inválida) = Gemini.

**Voltar ao Gemini.** Apague o campo `provedorConversa` (ou troque o valor para qualquer coisa que não seja `claude`). Em até
~5 min todo mundo volta ao Gemini; não precisa mexer no Worker.

**Se o Worker falhar, o app se vira sozinho:**

- Worker fora do ar, URL errada (404), sem a chave (`sem_chave`), token recusado (`nao_autenticado`) ou origem negada → aquele
  turno vai para o **Gemini** e o app deixa o Claude de lado por **10 min** (não fica martelando o Worker).
- Pedido grande demais (`pedido_invalido`) → só aquele turno vai para o Gemini.
- `limite_pessoal` (o aluno usou as 60 falas do dia no Worker) → **não** cai para o Gemini: a Conversa mostra "Você usou suas
  falas de conversa de hoje" e o app não chama o Worker de novo até o `Retry-After` (meia-noite UTC). O resto da IA ("Por quê?",
  Escrita, palavra) segue no Gemini, sem janela de descanso. Na prática a cota do próprio app (30 falas/dia por aluno, somando
  toda a IA) acaba antes.
- `limite_geral` do dia (o teto geral esgotou; `Retry-After` longo, até a meia-noite UTC) → aquele turno vai para o **Gemini** e o
  app deixa o Claude de lado até o `Retry-After`. Um 429 passageiro da Anthropic (`Retry-After` de até 2 min, ou sem) → o aviso
  "muita gente conversando" de sempre; a fala volta ao campo.
- `ia_falhou`, `ia_demorou` (ou o app sem resposta em 35 s) → "tente de novo"; a fala volta ao campo e não gasta uso. **3 seguidas**
  (chave revogada, sem crédito, teto de gastos da Anthropic, `MODELO` errado — o Worker devolve tudo como `ia_falhou`) → aquele
  turno vai para o Gemini e o Claude fica de lado por 10 min. A recusa ("não quis responder") não conta.

**Conferir que ligou:** com o app aberto em pac-dart.web.app, faça uma fala na Conversa e veja na aba *Network* do navegador um
`POST …workers.dev/v1/turno` com resposta 200 (no `npx wrangler tail` aparece o turno, sem o texto do aluno). Se aparecer a
chamada ao Gemini (`generativelanguage.googleapis.com`) no lugar, confira os dois campos e espere os ~5 min.

**Android/iOS:** o app nativo não manda `Origin`, e o Worker aceita (o token continua obrigatório). Se o Claude falhar ali, o
fallback é o Firebase AI, com o JSON pedido no texto do prompt.

## Mudar limites ou modelo

Edite `[vars]` no `wrangler.toml` e rode `npx wrangler deploy` de novo:

- `MODELO`: modelo do Claude (padrão `claude-haiku-5-5`). O app não escolhe.
- `LIMITE_PESSOAL`: falas por aluno por dia (padrão 60).
- `LIMITE_GERAL`: falas de todos os alunos somadas por dia (o `wrangler.toml` vem com 450, por causa do KV grátis; sem a variável, 3000).

O dia vira à meia-noite UTC (21h em Brasília). Para trocar a chave, rode o passo (e) de novo.

## Bom saber

- **Os limites são aproximados.** O KV da Cloudflare leva alguns segundos (até ~1 min) para propagar. Por isso, pedidos ao mesmo tempo podem passar um pouco do limite. O teto de gasto do passo (b) é a garantia final.
- **Plano grátis da Cloudflare:** o KV aceita só **1.000 escritas por dia**. Cada fala que dá certo grava 2 contadores, então o limite cobre umas **500 falas por dia**. Depois disso os contadores param de subir: as falas continuam funcionando, mas sem limite. Com mais uso que isso, assine o Workers Paid (US$ 5/mês) ou baixe o `LIMITE_GERAL` para uns 450.
- **Sem o bloco `[[kv_namespaces]]`,** o Worker roda sem limites e avisa no log.
- **Logs ao vivo:** `npx wrangler tail`. O texto dos alunos nunca vai inteiro para o log, e a chave nunca aparece nele.
- **Para desenvolver:** `npm test` roda os testes e `npm run typecheck` confere os tipos.
