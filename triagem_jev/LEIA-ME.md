# Triagem com modelo de decisão (Jev) + LLM — protótipo

Protótipo para a reunião de orientação do mestrado: um **modelo de decisão** (Jev, da TypeSafe AI) faz a triagem pesada de título e resumo, um **LLM** só entra nos estudos incluídos ou incertos para justificar a decisão, e o **pesquisador decide no final**. O plano completo está em [`docs/plano.md`](docs/plano.md).

> É uma hipótese a medir, não um resultado. A amostra de exemplo é pequena e **fictícia**.

![Tela no modo simulado](docs/tela-simulado.png)

## Estado

| Item do plano (seção 11) | Situação |
|---|---|
| 1. Modelos de domínio e leitura do arquivo | ✅ |
| 2. Cliente Jev + orquestrador da etapa 1 | ✅ código pronto · ⚠️ **formato da API a confirmar** (ver abaixo) |
| 3. Métricas vs gabarito (recall, precisão, acurácia, Kappa, redução) | ✅ |
| 4. Cliente LLM + etapa 2 | ✅ (OpenRouter, qualquer modelo) |
| 5. Custo e comparação dos 3 cenários + projeção 1.000/5.000 × 6 rodadas | ✅ (medido × estimado na tela) |
| 6. Tela com tabela colorida e resumo | ✅ |
| 7. Edição da decisão humana | ✅ |
| 8. OpenAI Decisions | ✅ estimado pelos tokens (cliente real reaproveitável: `ClienteDecisaoOpenRouter(rota: …)`) |
| 9. Teste de estabilidade (ordem das opções invertida) | ✅ interruptor na tela |
| Exportar JSON (com config, preços e log de cada chamada) e CSV | ✅ |

## Arquitetura

O mesmo padrão do PacDart: **Flutter com pastas por funcionalidade (domain / data / presentation) e Cubit**, mais um **Worker da Cloudflare** que guarda a chave (o app nunca vê a chave).

```
triagem_jev/
├── app/                                  Flutter (web)
│   ├── assets/exemplo_triagem.json       24 estudos fictícios + gabarito + 3 critérios
│   ├── assets/precos.json                tabela de preços configurável (US$/1M tokens)
│   └── lib/features/triagem/
│       ├── domain/   Dart puro, testável — não conhece HTTP nem Flutter
│       │   ├── estudo.dart               Estudo, Criterio, ProjetoTriagem, Decisao
│       │   ├── decisoes.dart             DecisaoModelo, JustificativaLlm, DecisaoHumana, Uso, RegistroChamada
│       │   ├── portas.dart               IDecisionModelClient, ILlmClient  ← troca de modelo acontece aqui
│       │   ├── resultado_estudo.dart     Faixa (regra 0,80 / 0,30) e a linha da tabela
│       │   ├── orquestrador_triagem.dart etapa 1 → encaminhamento → etapa 2, grava cada chamada
│       │   ├── metricas.dart             matriz de confusão, recall, precisão, Kappa…
│       │   ├── custo.dart                calculadora de custo, 3 cenários e projeção
│       │   └── prompt_llm.dart           prompt da etapa 2 (boas práticas do grupo)
│       ├── data/
│       │   ├── cliente_decisao.dart      Jev / Decisions API via Worker  ⚠️ formato a confirmar
│       │   ├── cliente_llm.dart          LLM via Worker (chat/completions do OpenRouter)
│       │   ├── clientes_simulados.dart   heurística local, sem internet e sem custo
│       │   └── arquivos_triagem.dart     leitura do JSON, exportação JSON/CSV
│       └── presentation/                 TriagemCubit + página única
└── worker/                               Cloudflare Worker (TypeScript): /jev e /llm → OpenRouter
```

Uma chave do **OpenRouter** serve para tudo: o Jev (`typesafe/jev-1.13`) e o LLM (Claude, GPT…).

## Rodar

Pré-requisitos: Flutter 3.41+ e Node 22.

### Modo simulado (sem chave, sem internet)

```sh
cd triagem_jev/app
flutter run -d chrome
```

Clique em **Usar exemplo** → **Rodar triagem**. A "decisão" simulada é uma heurística de palavras em comum com os critérios: serve para ensaiar a tela, **não é o Jev**. Os números aparecem como *estimado*.

### Modo real (Jev + LLM pelo OpenRouter)

1. Crie uma chave em <https://openrouter.ai/keys> e defina um **limite de gasto** na conta.
2. Coloque a chave em `triagem_jev/worker/.dev.vars` (esse arquivo não vai para o git):
   ```
   OPENROUTER_API_KEY=sk-or-...
   ```
3. Suba o Worker local:
   ```sh
   cd triagem_jev/worker
   npm ci
   npm run dev          # http://localhost:8787
   ```
4. Rode o app apontando para ele:
   ```sh
   cd triagem_jev/app
   flutter run -d chrome --dart-define=WORKER_URL=http://localhost:8787
   ```
   Opcional: `--dart-define=MODELO_LLM=anthropic/claude-sonnet-5.5` (o modelo precisa estar em `assets/precos.json` e em `MODELOS_PERMITIDOS` no `wrangler.toml`).
5. Ligue o interruptor **Modelos reais** e rode.

Se for publicar o Worker (`npx wrangler deploy`), defina `TOKEN_ACESSO` (`npx wrangler secret put TOKEN_ACESSO`), passe o mesmo valor ao app com `--dart-define=TOKEN_ACESSO=…` e coloque a origem do site em `ORIGENS`. Sem isso, qualquer pessoa que achar a URL gasta o seu crédito.

## ⚠️ Antes da demonstração, confirmar

1. **Formato da Decisions API do Jev.** O código usa o endpoint `POST https://openrouter.ai/api/alpha/decisions` e o id `typesafe/jev-1.13`, que aparecem em fontes públicas. Os **nomes dos campos** do pedido e da resposta foram escritos sem acesso à documentação. Ajuste só dois métodos, que têm testes próprios:
   - `ClienteDecisaoOpenRouter.corpo` (pedido) e `ClienteDecisaoOpenRouter.mapearResposta` (resposta), em `app/lib/features/triagem/data/cliente_decisao.dart`;
   - a URL em `worker/src/index.ts` (`URL_DECISOES`).
   Documentação: <https://openrouter.ai/docs/guides/community/jev>
2. **Preços** em `app/assets/precos.json` (Jev 0,042 e Decisions API 0,10 vêm do plano; Claude Haiku 5.5 a US$ 0,10/0,50 é o preço da API da Anthropic, e no OpenRouter pode ser diferente).
3. **Ids dos modelos no OpenRouter** (ex.: `anthropic/claude-haiku-5.5`).
4. **Temperatura zero:** os modelos Claude atuais recusam `temperature` e `top_p` (erro 400). Para eles o cliente não envia esses parâmetros. Para os demais, envia 0. Isso fica registrado no log de cada chamada.

## Regras que o código segue

- **Incerto conta como "segue"** nas métricas, porque vai para o pesquisador ler. É isso que protege o recall.
- Erro na etapa 1 → o estudo vira **incerto** e segue para o humano, nunca é excluído em silêncio.
- O estado enviado ao modelo leva só tipo de fonte, título, resumo e palavras-chave (sem URL e sem gabarito), porque o Jev perde precisão com informação irrelevante.
- Cada chamada fica registrada (modelo, parâmetros, entrada resumida, saída, tokens, ms, custo) e sai no JSON exportado, junto com critérios, limites e preços.

## Testes

```sh
cd triagem_jev/app && flutter analyze && flutter test       # 19 testes
cd triagem_jev/worker && npm run typecheck && npm test      # 6 testes
```

## Próximos passos sugeridos

1. Confirmar o formato do Jev (acima) e fazer uma rodada real com o exemplo.
2. Trocar o exemplo fictício por uma **revisão sistemática publicada** (Opção A do plano), com 20 a 40 estudos e o gabarito dela.
3. Rodar o cenário "só LLM" de verdade em uma amostra, para trocar *estimado* por *medido*.
4. Repetir as rodadas (o grupo usa de 6 a 10) e medir a variação.

## Levar para um repositório próprio

Esta pasta é independente do PacDart: não importa nada de fora dela. Para movê-la para um repositório novo (ex.: `triagem-jev`), crie o repositório vazio no GitHub e, dentro de uma cópia do `pac_dart`, rode:

```sh
git subtree split --prefix=triagem_jev -b triagem-export
git push git@github.com:<usuario>/triagem-jev.git triagem-export:main
```

O histórico dos commits desta pasta vai junto.
