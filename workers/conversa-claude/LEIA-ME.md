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

## Mudar limites ou modelo

Edite `[vars]` no `wrangler.toml` e rode `npx wrangler deploy` de novo:

- `MODELO`: modelo do Claude (padrão `claude-haiku-5-5`). O app não escolhe.
- `LIMITE_PESSOAL`: falas por aluno por dia (padrão 60).
- `LIMITE_GERAL`: falas de todos os alunos somadas por dia (padrão 3000).

O dia vira à meia-noite UTC (21h em Brasília). Para trocar a chave, rode o passo (e) de novo.

## Bom saber

- **Os limites são aproximados.** O KV da Cloudflare leva alguns segundos (até ~1 min) para propagar. Por isso, pedidos ao mesmo tempo podem passar um pouco do limite. O teto de gasto do passo (b) é a garantia final.
- **Plano grátis da Cloudflare:** o KV aceita só **1.000 escritas por dia**. Cada fala que dá certo grava 2 contadores, então o limite cobre umas **500 falas por dia**. Depois disso os contadores param de subir: as falas continuam funcionando, mas sem limite. Com mais uso que isso, assine o Workers Paid (US$ 5/mês) ou baixe o `LIMITE_GERAL` para uns 450.
- **Sem o bloco `[[kv_namespaces]]`,** o Worker roda sem limites e avisa no log.
- **Logs ao vivo:** `npx wrangler tail`. O texto dos alunos nunca vai inteiro para o log, e a chave nunca aparece nele.
- **Para desenvolver:** `npm test` roda os testes e `npm run typecheck` confere os tipos.
