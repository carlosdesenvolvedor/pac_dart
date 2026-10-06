# Guia dos desafios de lógica — PAC·C#

Cada trilha termina com uma bateria de **desafios de lógica** que NÃO são de digitação: a pessoa
pensa, prevê, escolhe, ordena e acha bugs. Eles ficam num arquivo próprio da trilha:
`$SCR/desafios/NN-id.json` com o formato `{"nivel": "<nome da trilha>", "desafios": [ ... ]}`.

## Regras gerais

- **16 desafios por trilha** (14 a 18), do mais fácil ao mais difícil (`nivel` 1, 2 e 3 — uns 5/6/5).
- Use **SÓ** o que já foi ensinado até esta trilha (inclusive): as trilhas anteriores do esboço e as
  lições desta. Nada de recurso que só aparece depois. Isso é o que torna o desafio justo.
- **Pelo menos 5 com tema de jogo** (`"tema": "jogo"`): vida/dano, placar, inventário, XP e nível,
  fases, dados, cartas, tabuleiro, inimigos, moedas, cooldown, combo, loot, mapa em grade… — mesmo
  em trilhas que não são de jogos (ex.: LINQ ordenando o ranking de jogadores).
- Mistura de tipos: ~4 `saida`, ~3 `valor`, ~3 `lacuna`, ~2 `ordenar`, ~2 `bug`, ~2 `escolha`.
  Em trilhas conceituais (arquitetura, padrões, perfis web/testes/unity/godot/monogame) pode ter mais
  `escolha`, mas mantenha pelo menos 8 desafios executáveis.
- **Todo código de desafio é um programa de console** (perfil console: C# 14, ImplicitUsings,
  Nullable ligados) que compila **sem nenhum aviso** e roda em menos de 8 s, com saída determinística
  (Random só com semente fixa; nada de DateTime.Now). Mesmo em trilhas de web/Unity/Godot, escreva a
  lógica em C# puro (ex.: a máquina de estados do inimigo, a conta do dano, a rota que seria mapeada).
- Linhas até 70 colunas, 4 espaços de indentação, chaves no estilo Allman, só caracteres ABNT
  (as mesmas regras de digitação dos trechos — o código aparece na tela e em cartões).
- `titulo` curto (≤ 40), `enunciado` claro (o que a pessoa tem que fazer/descobrir), `explicacao`
  que ENSINA (2-4 frases: por que a resposta é essa e por que as outras enganam).
- O validador (`$L desafios ARQ.json --fix`) roda o código de verdade: ele PREENCHE `resposta` e
  `esperado` com o valor real e corrige a alternativa certa quando você marcou a errada. Mesmo assim,
  pense a resposta antes (as alternativas erradas precisam ser erros plausíveis e comuns).

## Os 6 tipos

1. **saida** — "O que este programa imprime?"
   ```json
   {"tipo": "saida", "titulo": "Laço que conta", "enunciado": "O que este programa imprime?",
    "cod": "for (int i = 0; i < 3; i++)\n{\n    Console.Write(i);\n}",
    "opcoes": ["012", "123", "0123", "01"], "certa": 0,
    "explicacao": "...", "nivel": 1, "tema": ""}
   ```
   4 opções distintas; saída curta (até 6 linhas / 140 caracteres). Distratores = erros típicos
   (fora-por-um, divisão inteira, ordem de avaliação, referência vs valor, deferred execution…).

2. **valor** — "Qual é o valor final de X?" (a pessoa DIGITA a resposta)
   ```json
   {"tipo": "valor", "titulo": "Vida do herói", "enunciado": "Qual é o valor final de vida?",
    "cod": "int vida = 100;\nvida -= 35;\nvida = Math.Max(vida - 80, 0);",
    "expr": "vida", "resposta": "", "aceitas": [],
    "explicacao": "...", "nivel": 1, "tema": "jogo"}
   ```
   `expr` é a expressão impressa no fim (o validador faz `Console.Write(expr)` e preenche `resposta`).
   Resposta curta de digitar: número, palavra, `True`/`False` (o app aceita vírgula ou ponto e
   `true`/`True`). Use `aceitas` para formas equivalentes (ex.: `["dez"]`). Não imprima a resposta no `cod`.

3. **lacuna** — código com UMA lacuna `___` e 4 opções para preencher
   ```json
   {"tipo": "lacuna", "titulo": "Só os pares",
    "enunciado": "Complete para imprimir os pares de 0 a 8.",
    "cod": "for (int i = 0; i <= 8; ___)\n{\n    Console.Write(i + \" \");\n}",
    "opcoes": ["i += 2", "i++", "i *= 2", "i--"], "certa": 0, "esperado": "",
    "explicacao": "...", "nivel": 1}
   ```
   O validador roda com cada opção: a certa tem que dar o `esperado` (ele preenche); **nenhuma opção
   errada pode produzir a mesma saída** (senão é ambíguo). Opção errada que não compila é válida.

4. **ordenar** — cartões embaralhados; pôr na ordem que produz a saída esperada (Parsons)
   ```json
   {"tipo": "ordenar", "titulo": "Soma de 1 a 5",
    "enunciado": "Ponha as linhas na ordem para imprimir a soma de 1 a 5.",
    "linhas": ["int soma = 0;", "for (int i = 1; i <= 5; i++)\n{", "    soma += i;", "}",
               "Console.WriteLine(soma);"],
    "esperado": "", "explicacao": "...", "nivel": 2}
   ```
   4 a 10 cartões (cada cartão até 3 linhas). **Junte a chave `{` com a linha de cima** (como no
   exemplo) — uma `{` sozinha pode trocar de lugar sem mudar nada. A ordem tem que ser ÚNICA: o
   validador troca cada par vizinho e reclama se ainda compilar e der a mesma saída (então evite
   duas declarações independentes lado a lado; encadeie: cada linha usa a anterior).

5. **bug** — código com UMA linha errada; a pessoa toca na linha do bug
   ```json
   {"tipo": "bug", "titulo": "Média quebrada",
    "enunciado": "Este código deveria imprimir a média 7,5, mas não imprime. Qual linha tem o bug?",
    "linhas": ["int a = 7;", "int b = 8;", "double media = (a + b) / 2;", "Console.WriteLine(media);"],
    "linhaBug": 2, "correcao": "double media = (a + b) / 2.0;", "esperado": "",
    "explicacao": "...", "nivel": 2}
   ```
   `linhaBug` é 0-based. Com a `correcao` no lugar, o programa tem que produzir o `esperado`
   (preenchido pelo validador); com o bug, NÃO. Prefira bugs de lógica (fora-por-um, comparação de
   referência, mutação durante iteração, await esquecido, divisão inteira, null) a erro de sintaxe.
   O `enunciado` deve dizer o que o código DEVERIA fazer/mostrar.

6. **escolha** — pergunta conceitual (2 a 4 opções), opcionalmente com `cod`
   ```json
   {"tipo": "escolha", "titulo": "Quem tem o poder?",
    "enunciado": "Qual princípio SOLID esta classe viola?",
    "cod": "class Relatorio\n{\n    public string Gerar() => \"...\";\n    public void SalvarNoBanco() { }\n    public void EnviarEmail() { }\n}",
    "opcoes": ["Responsabilidade Única (SRP)", "Aberto/Fechado (OCP)", "Substituição de Liskov (LSP)", "Inversão de Dependência (DIP)"],
    "certa": 0, "explicacao": "...", "nivel": 2}
   ```
   Se tiver `cod`, ele tem que compilar (ou começar com um comentário "não compila").

## Qualidade

- Um desafio bom tem UMA sacada: a pessoa precisa entender o conceito, não só ler devagar.
- Varie os cenários e os nomes; nada de desafio idêntico a um trecho da trilha.
- Os distratores vêm de erros reais de iniciante/pleno/sênior (conforme a etapa).
- Em trilhas sênior, desafios de trade-off/diagnóstico: "qual versão escala?", "qual linha causa o
  deadlock?", "qual camada deve conhecer o repositório?", mas ainda com código que roda quando possível.
