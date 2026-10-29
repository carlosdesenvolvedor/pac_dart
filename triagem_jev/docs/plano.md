# Protótipo: triagem de estudos com modelo de decisão (Jev) + LLM

Documento de planejamento para um agente de código implementar um protótipo funcional dentro de um projeto já existente. O objetivo é ter algo pequeno, mas que rode de ponta a ponta, para mostrar em uma reunião de orientação de mestrado.

## 1. Contexto

Em uma revisão sistemática (ou mapeamento sistemático), a etapa mais cansativa é a **triagem**: ler título e resumo de centenas de estudos e decidir quais entram e quais saem, conforme critérios de inclusão. Hoje o grupo de pesquisa usa **LLMs como copiloto** nessa etapa (um revisor a mais), pedindo respostas em três formatos: nota de 1 a 7 (Likert), sim ou não, e probabilidade de 0 a 1. O maior problema relatado é o **custo**, porque eles rodam várias vezes e com vários modelos.

**Hipótese que o protótipo quer demonstrar:** um **modelo de decisão** (Jev, da TypeSafe AI) faz a triagem pesada de forma muito mais rápida e barata, e um **LLM** entra só no final, com os poucos estudos que sobraram ou ficaram em dúvida, para explicar a decisão e extrair dados. O **pesquisador sempre decide no final**.

Isso é uma hipótese a testar, não um resultado garantido.

## 2. Objetivo do protótipo (o que precisa funcionar até amanhã)

1. Carregar um conjunto pequeno de estudos (20 a 40) com um **gabarito humano** (incluído ou excluído).
2. Rodar a triagem com o **Jev** usando os critérios de inclusão.
3. Mandar para o **LLM** só os estudos incluídos ou incertos, pedindo uma justificativa curta.
4. Mostrar numa tela simples: decisão do Jev, confiança, justificativa do LLM, decisão humana final.
5. Calcular **métricas** (acerto contra o gabarito) e **custo e tempo** de cada etapa.
6. Comparar o custo de três cenários: **Jev + LLM**, **só LLM**, e **OpenAI Decisions API + LLM** (este pode ser só estimado se não houver acesso).

Fora do escopo agora: busca automática em bases, leitura de PDF, extração completa de dados, multiusuário, login.

## 3. Fluxo

```
[Estudos (CSV/JSON)] + [Critérios de inclusão]
        |
        v
[Etapa 1 - Triagem com Jev]  -> decisão + probabilidade + confiança por estudo
        |
        |-- incluído (alta confiança) ---------\
        |-- incerto (confiança baixa) ----------+--> [Etapa 2 - LLM] -> justificativa curta
        |-- excluído (alta confiança) --> fica registrado, sem LLM
        v
[Etapa 3 - Revisão humana]  -> pesquisador confirma ou muda cada decisão
        |
        v
[Relatório] -> métricas vs gabarito, custo, tempo, comparação de cenários
```

## 4. Componentes

Use a linguagem, o framework e a infraestrutura que o projeto atual já usa. A divisão sugerida:

### 4.1 Modelos de domínio
- **Estudo**: id, título, resumo, palavras-chave, tipo de fonte (artigo ou literatura cinzenta), url opcional, decisão do gabarito.
- **Critério**: id, texto do critério (escrito sempre na forma positiva, sem negação).
- **Projeto de triagem**: nome, lista de critérios, lista de estudos, configuração de modelos e preços.
- **Decisão de modelo**: estudo, modelo usado, formato da pergunta, resultado, probabilidade ou nota, confiança, tokens de entrada, tokens de saída, tempo em ms, custo calculado.
- **Justificativa do LLM**: estudo, modelo, texto, tokens, tempo, custo.
- **Decisão humana**: estudo, decisão final, observação.

### 4.2 Serviços
- **Cliente Jev** (interface `IDecisionModelClient` ou equivalente): envia o estado (título, resumo, palavras-chave, critérios) e recebe a decisão tipada.
- **Cliente OpenAI Decisions** (mesma interface): opcional, para comparação. Se não houver chave, apenas estimar custo pelos tokens.
- **Cliente LLM** (interface `ILlmClient`): gera a justificativa curta para os estudos que passaram ou ficaram incertos. Pode ser Claude, GPT ou outro que o projeto já use.
- **Orquestrador de triagem**: roda as etapas na ordem, aplica o limite de confiança e grava tudo.
- **Calculadora de métricas**: compara com o gabarito.
- **Calculadora de custo**: usa a tabela de preços configurável.

Ter os modelos atrás de interfaces é importante: a pesquisa precisa trocar e comparar modelos facilmente.

### 4.3 Interface
Uma tela simples (ou até uma página única):
- Botão para carregar o arquivo de estudos e critérios.
- Botão "Rodar triagem".
- Tabela com uma linha por estudo: título, decisão do Jev, probabilidade, decisão do LLM ou justificativa, gabarito, decisão humana (editável).
- Cores: verde incluído, vermelho excluído, amarelo incerto.
- Painel de resumo: métricas, custo total, tempo total, comparação de cenários.

Se o tempo apertar, a interface pode ser trocada por um relatório em console ou em Markdown. O importante é funcionar.

## 5. Integração com o Jev

**Confirmar tudo na documentação oficial antes de implementar** (endpoint, nome dos campos, autenticação, limites). O que se sabe por fontes públicas:

- Não gera texto: recebe um estado (texto ou JSON) e devolve decisões tipadas.
- Tipos de pergunta, que podem ir juntos numa chamada:
  - **Escolha** (choice): escolhe uma opção entre alternativas e devolve a probabilidade de cada uma e uma confiança.
  - **Condição** (verdadeiro ou falso): devolve a probabilidade de uma condição ser verdadeira.
  - **Nota** (score): posição numa escala ordenada, com a distribuição completa.
- Disponível também pelo **OpenRouter**. Contexto de cerca de 32 mil tokens no OpenRouter. Só texto.
- Preço divulgado: cerca de **US$ 0,042 por milhão de tokens de entrada**, saída sem custo.
- Cuidados citados: a precisão cai quando o estado tem muita informação irrelevante, e a probabilidade pode mudar se a ordem das opções mudar.

**Perguntas a enviar por estudo** (uma chamada por estudo):
1. Condição: "Este estudo atende a todos os critérios de inclusão?" → probabilidade.
2. Escolha: "incluir", "excluir", "incerto" → opção + probabilidades + confiança.
3. Nota: escala de 1 a 7, onde 7 é "certamente deve ser incluído" → distribuição.

Guardar os três resultados. Isso permite comparar os mesmos formatos que o grupo de pesquisa já testou com LLMs.

**Regra de encaminhamento (configurável):**
- Probabilidade de inclusão >= 0,80 → incluído, vai para o LLM.
- Entre 0,30 e 0,80 → incerto, vai para o LLM.
- < 0,30 → excluído, não vai para o LLM.

**Teste de estabilidade (se der tempo):** rodar cada estudo duas vezes com a ordem das opções trocada e registrar se a decisão mudou.

## 6. Etapa do LLM

Só para estudos incluídos ou incertos. Boas práticas que o grupo de pesquisa recomenda:
- Temperatura e top-p em zero.
- Um estudo por chamada.
- Critérios escritos na forma positiva.
- Instruir o modelo a dizer "não encontrei informação suficiente" em vez de inventar.

Saída pedida (JSON):
```json
{
  "decisao_sugerida": "incluir | excluir | incerto",
  "criterios_atendidos": ["C1", "C2"],
  "justificativa": "até 2 frases"
}
```

## 7. Métricas

Comparando com o gabarito humano:
- **Recall** (sensibilidade): dos estudos que deveriam entrar, quantos o sistema incluiu. **É a métrica mais importante**, porque perder estudo relevante é o pior erro numa revisão.
- **Precisão**: dos que o sistema incluiu, quantos estavam certos.
- **Acurácia** e **concordância** (percentual de decisões iguais ao gabarito; se der tempo, Kappa de Cohen).
- **Redução de trabalho**: percentual de estudos que o pesquisador não precisou ler com atenção.
- Mostrar a matriz: verdadeiro positivo, falso positivo, falso negativo, verdadeiro negativo.

## 8. Custo e tempo

Registrar por chamada: tokens de entrada, tokens de saída, tempo em ms. Custo = tokens x preço da tabela.

Tabela de preços **configurável** (arquivo de configuração), com valores a confirmar nas páginas oficiais no dia:

| Modelo | Entrada (US$ por 1M tokens) | Saída (US$ por 1M tokens) |
|---|---|---|
| Jev (TypeSafe AI) | 0,042 | 0 |
| OpenAI Decisions API (GPT-6 Luna) | 0,10 | 0 |
| LLM usado na etapa final | preencher | preencher |

**Comparação de cenários** (mesmo conjunto de estudos):
1. **Jev + LLM**: Jev em todos, LLM só nos que passaram.
2. **Só LLM**: LLM em todos os estudos (o jeito atual).
3. **Decisions API + LLM**: igual ao cenário 1, trocando o Jev.

Para o cenário 2, se não quiser gastar rodando de verdade, estimar pelo número de tokens. Deixar claro na tela o que foi **medido** e o que foi **estimado**.

Também mostrar uma **projeção**: quanto custaria cada cenário para 1.000 e 5.000 estudos, e com 6 rodadas (o grupo usa de 6 a 10 rodadas para estabilizar).

## 9. Dados de teste

Opção A (melhor para a demonstração): pegar uma revisão sistemática já publicada em Engenharia de Software que liste os estudos incluídos e excluídos, e usar 20 a 40 deles como gabarito.

Opção B (mais rápida): montar à mão um arquivo com 20 a 40 estudos (título e resumo) sobre um tema qualquer, marcar o gabarito e escrever 3 ou 4 critérios de inclusão.

Incluir alguns itens de **literatura cinzenta** (post de blog, documentação, issue do GitHub, sem resumo formal) marcados com tipo de fonte, para mostrar como o modelo de decisão lida com texto sem estrutura. Este é um ponto que a professora mencionou como interesse.

Formato sugerido do arquivo de entrada:
```json
{
  "projeto": "Demo triagem",
  "criterios": [
    { "id": "C1", "texto": "O estudo propõe ou avalia ..." },
    { "id": "C2", "texto": "O estudo apresenta avaliação empírica ..." }
  ],
  "estudos": [
    {
      "id": "E01",
      "titulo": "...",
      "resumo": "...",
      "palavras_chave": ["..."],
      "tipo_fonte": "artigo",
      "url": "",
      "gabarito": "incluir"
    }
  ]
}
```

## 10. Registro (logs) e reprodutibilidade

O grupo de pesquisa valoriza explicabilidade e poder refazer a revisão. Então:
- Salvar cada chamada (modelo, versão, parâmetros, entrada resumida, saída, tokens, tempo, custo).
- Exportar o resultado completo em JSON e CSV.
- Guardar a configuração usada (critérios, limites, preços) junto com o resultado.

## 11. Ordem de implementação (por prioridade)

1. Modelos de domínio e leitura do arquivo de entrada.
2. Cliente Jev + orquestrador da etapa 1, gravando decisão, tokens e tempo.
3. Métricas contra o gabarito (só com o Jev já dá para mostrar algo).
4. Cliente LLM + etapa 2 para incluídos e incertos.
5. Calculadora de custo e comparação de cenários.
6. Tela simples com a tabela e o resumo.
7. Edição da decisão humana.
8. Cliente OpenAI Decisions (ou só estimativa).
9. Teste de estabilidade com a ordem das opções trocada.

Se algo travar, pare no item 5: com ele já dá para apresentar.

## 12. O que mostrar na reunião (3 a 5 minutos)

1. O arquivo com os estudos e os critérios.
2. Rodar a triagem ao vivo (ou mostrar o resultado já rodado, para não depender da internet).
3. A tabela colorida com a decisão do Jev e a justificativa do LLM.
4. As métricas contra o gabarito.
5. O custo dos três cenários e a projeção para 1.000 estudos.
6. Reforçar: **o pesquisador decide no final** e isso é uma hipótese que a pesquisa mediria com mais rigor.

## 13. Cuidados

- Não colocar chaves de API no código nem no repositório. Usar variáveis de ambiente ou o gerenciador de segredos do projeto.
- Confirmar preços e parâmetros nas documentações oficiais no dia.
- Não afirmar que o Jev é melhor: mostrar os números e deixar claro que a amostra é pequena.
