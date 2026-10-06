# Guia do gerador de trilhas — PAC·C#

Você vai escrever UMA trilha do currículo **PAC·C#**: um curso completo de C#/.NET, do iniciante
ao sênior, dentro de um app de **treino de digitação** (Flutter web). A pessoa lê a teoria curta
da lição, depois **digita** cada trecho de código (um Pac-Man come as letras), vê a saída no
console, faz um quiz, digita projetos completos ("Mão na Massa") e resolve **desafios de lógica**
(que não são de digitação). Público: brasileiros; tudo em **português do Brasil**.

O conteúdo é **nosso**: use a documentação oficial (learn.microsoft.com) e os dossiês de pesquisa
para conferir cobertura, ordem e boas práticas, mas **não copie** texto nem exercícios de ninguém.

## Onde escrever (REGRA DURA)

- Escreva **somente** dentro de `$SCR` (o scratchpad; caminho absoluto no seu prompt).
- **Nunca** crie, altere ou apague nada em `/Users/fazplay/pac_dart`. Não rode `flutter`.
- O laboratório (validador) está em `$SCR/lab/bin/lab/Lab.dll`. Rode sempre com o .NET 10:
  ```bash
  export DOTNET_ROOT=/opt/homebrew/opt/dotnet/libexec
  L="$DOTNET_ROOT/dotnet $SCR/lab/bin/lab/Lab.dll"
  $L trilha   ARQ.json --fix          # valida lições/teoria/projetos e PREENCHE as saídas reais
  $L trilha   ARQ.json --fix --licao 3  # só a lição 3 (0-based), mais rápido enquanto conserta
  $L desafios ARQ.json --fix          # valida os desafios de lógica e corrige gabaritos
  $L snippet  x.cs --perfil console --rodar   # testa um código solto
  $L montar   ARQ.json 3 5            # mostra o programa que o botão "copiar" gera (lição 3 até o trecho 5)
  ```
  Rode a partir de uma pasta sua em `$SCR/trabalho/<id-da-trilha>/` (programas podem criar arquivos).
- O relatório completo vai para `ARQ.json.relatorio.txt` / `ARQ.json.desafios.txt`.
- A trilha só está pronta quando os dois validadores terminam com **`RESULTADO: OK`**.
  Avisos (`[AVISO]`) devem ser zerados sempre que possível; erros (`[ERRO]`) são obrigatórios.

## Formato do arquivo (JSON estrito, UTF-8)

```json
{
  "nivel": "Nome da Trilha",
  "emoji": "🌱",
  "etapa": "Iniciante",
  "descricao": "Uma frase que vende a trilha.",
  "fundo": "fundamentos",
  "perfil": "console",
  "licoes": [
    {
      "nome": "Nome da lição",
      "emoji": "📦",
      "resumo": "1-2 frases: o que a pessoa vai aprender e por que importa.",
      "teoria": [
        {"t": "h", "c": "Subtítulo"},
        {"t": "p", "c": "Parágrafo com **negrito** e `código inline`."},
        {"t": "code", "c": "var nome = \"Ana\";\nConsole.WriteLine(nome);"},
        {"t": "code", "l": "bash", "c": "dotnet new console -n Loja"},
        {"t": "tip", "c": "Dica prática."},
        {"t": "warn", "c": "Armadilha comum."}
      ],
      "trechos": [
        {"cod": "Console.WriteLine(\"Olá!\");", "dica": "<b>WriteLine</b> escreve e pula a linha.", "out": ""},
        {"cod": "string cidade = \"Recife\";", "dica": "<b>string</b> guarda texto.", "out": "cidade = \"Recife\"",
         "conceito": "Explicação mais funda, opcional (até ~400 caracteres)."}
      ]
    }
  ],
  "projetos": [
    {"nome": "Caixa da Padaria", "emoji": "🥖", "descricao": "O que o programa faz (1-2 frases).",
     "cod": "...programa completo...", "out": "", "flutter": false}
  ]
}
```

- `etapa`: `Iniciante` | `Intermediário` | `Avançado` | `Sênior` (a do esboço).
- `fundo`: `fundamentos` | `logica` | `colecoes` | `objetos` | `avancado` | `flutter` | `desafios` | `pacotes`.
- `perfil`: `console` | `web` | `testes` | `biblioteca` | `unity` | `godot` | `monogame` (a do esboço).
- `nivel`: único, ≤ 22 caracteres; não pode repetir nome de trilha da vertente Dart.
- Campos extras opcionais que o validador entende: lição `"entrada": "Ana\n30\n"` (stdin quando a
  lição usa `Console.ReadLine`), lição `"permitir": ["CS1998"]` (aviso de compilação intencional,
  use raríssimo e explique na teoria), trecho `"l": "bash"` (trecho que não é C#: `bash`, `json`,
  `xml`, `sql`, `yaml`, `proto`, `http`, `dockerfile`, `texto` — só digitação, não compila).

## Tamanho (meta do currículo: 5.000+ exercícios no total)

- **12 lições** por trilha (11 a 13), cada uma com **9 ou 10 trechos** (mínimo 8, máximo 12).
- Teoria: **5 a 9 blocos** por lição, com **2 ou 3 blocos `code`**.
- **2 ou 3 projetos** "Mão na Massa" por trilha (programas completos de 20 a 60 linhas).
- Trechos de outra linguagem (`"l"`) no máximo em ~10% da trilha (ex.: `dotnet ef migrations add Inicial`).

## Regras dos trechos (o que a pessoa DIGITA)

1. **Digitável num teclado ABNT**: só ASCII imprimível + quebra de linha + `áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ`.
   Nada de tab, emoji, `°`, `º`, `→`, `…`, aspas curvas, travessão. Em strings, escreva `graus`, não `°`.
2. **Indentação de 4 espaços**, chaves no estilo do C# (Allman: `{` na linha de baixo). Sem espaço
   sobrando no fim da linha, sem linha em branco no começo/fim, nunca duas linhas em branco seguidas.
3. **Linhas de até 70 colunas** (o limite duro é 80; acima de 78 vira aviso). Quebre chamadas longas.
4. **1 a 12 linhas** por trecho; a maioria com 1 a 6. Cada lição precisa de **pelo menos 4 trechos
   curtos** (≤ 90 caracteres e ≤ 3 linhas) — o quiz da lição é montado com eles.
5. **A lição inteira é UM programa**: o laboratório junta os trechos na ordem (usings no topo,
   comandos na ordem, `class`/`record`/`struct`/`interface`/`enum`/`namespace` no fim) e compila;
   depois compila também cada prefixo (trechos 0..k). Portanto:
   - trecho k **nunca** usa algo declarado num trecho posterior;
   - **nomes únicos na lição** (não declare `var nome` duas vezes; não repita nome de classe);
   - não parta um comando entre trechos (um trecho não pode terminar no `if` e o outro começar no `else`);
   - método solto (sem classe) = função local de top-level: não dá overload; para overload use uma classe;
   - membro solto (`public int X { get; set; }` fora de classe) NÃO compila: escreva a classe inteira
     (pode ser pequena) ou use `partial class` quando a lição for sobre partes de uma mesma classe.
6. **Zero aviso de compilação** (o validador trata aviso como erro), exceto "declarado e não usado".
   Com `Nullable` ligado: inicialize strings (`= ""`), use `required`, `string?`, `??`, `!` com critério.
   Nada de `async` sem `await`, chamada assíncrona sem `await` (CS4014), membro obsoleto (CS0618).
7. **Saída (`out`)**: se o trecho imprime algo, deixe `"out": ""` — o `--fix` preenche com a saída REAL
   (cultura pt-BR: `12,50`, `R$ 16,75`). Se o trecho **não** imprime, escreva um `out` descritivo curto,
   no estilo do console: `nome = "Ana"`, `lista com 3 itens`, `classe Produto criada`, `pronto para receber`.
   Programa com resultado aleatório/horário (Random sem semente, DateTime.Now…) mantém o seu `out`
   descritivo: diga que varia (`um número de 1 a 6 (muda a cada execução)`). Prefira `new Random(42)`.
8. **Sem exceção sem tratamento** e sem laço infinito: a lição tem que rodar do começo ao fim
   (para ensinar exceção, capture e imprima a mensagem). Leitura de teclado: use `"entrada"` na lição.
9. **Dica** (`dica`): 1 frase, até ~150 caracteres, com a palavra-chave do trecho em `<b>…</b>`
   (só `<b>` e `<code>` são permitidos). Ela é narrada em voz alta: escreva como se falasse.
10. **Conceito** (`conceito`, opcional): em 2 ou 3 trechos por lição, uma explicação mais funda
    (o porquê, o que acontece por baixo, quando NÃO usar).
11. **Progressão dentro da lição**: do trecho mais simples ao mais completo; o último pode juntar
    as ideias da lição. Varie domínios e nomes (loja, escola, banco, clínica, entregas, streaming,
    jogo, futebol, estoque, cardápio…), com sabor brasileiro (nomes, cidades, reais).
12. **Não repita** o mesmo código na trilha. Nada de trecho trivial repetido com outro valor.

## Teoria (o "Nivelamento" antes de praticar)

- Texto claro, de professor animado e direto (frases curtas, "você", analogias do dia a dia).
- Explique **o porquê**, não só a sintaxe; mostre uso real e armadilhas (`warn`) e boas práticas (`tip`).
- Todo bloco `code` em C# tem que **compilar sozinho** no perfil da trilha (o validador compila).
  Se quiser mostrar código que NÃO compila de propósito, a 1ª linha do bloco deve ser um comentário
  com "não compila" (ex.: `// não compila: falta o ;`) — o validador confere que ele de fato falha.
- Outras linguagens no bloco: use `"l": "bash"` (ou json, xml, sql, yaml…) — não é compilado.
- Marque versões quando importar: "recurso do C# 12", "novo no .NET 10 / C# 14".
- `p` aceita `**negrito**` e `` `código inline` ``.

## Projetos "Mão na Massa"

- Programas **completos e realistas** que usam o que a trilha ensinou (20 a 60 linhas), com um
  enunciado claro em `descricao` e saída de **3 a 40 linhas**. `"flutter": false` sempre.
- Perfil `console`: roda de verdade; `out` vazio → o `--fix` preenche. Determinístico.
- Perfis `web`/`testes`/`biblioteca`/`unity`/`godot`/`monogame`: só compila; escreva `out` descritivo
  (o que aconteceria ao rodar: rotas, testes aprovados, comportamento no jogo).
- As mesmas regras de digitação dos trechos valem para o `cod` do projeto.

## Perfis (como o laboratório compila)

- **console**: `dotnet new console` .NET 10, **C# 14**, ImplicitUsings (System, System.Collections.Generic,
  System.IO, System.Linq, System.Net.Http, System.Threading, System.Threading.Tasks) e Nullable ligados.
  Roda cada lição e confere as saídas. Bibliotecas NuGet disponíveis (compilar e rodar): EF Core 10
  (Sqlite/InMemory), Dapper, Microsoft.Extensions.* (Hosting/DI/Logging/Configuration/Options),
  System.Text.Json, Newtonsoft.Json, Serilog, Polly 8, MediatR 12, FluentValidation 12, ErrorOr, Mapster,
  Humanizer, Bogus, Spectre.Console, BenchmarkDotNet (só compilar), xUnit 2.9/Moq/NSubstitute/Shouldly.
  Nada de rede de verdade nos exercícios que rodam (HttpClient para URL real não roda no lab: use
  handler falso, `HttpMessageHandler` de teste, ou deixe o programa compilável sem executar a chamada).
- **web**: `dotnet new web` (ASP.NET Core .NET 10) — os usings implícitos da Web SDK também estão ligados.
  Só compila. `app.Run();` só no último trecho que precisar dele. Pacotes: OpenApi, JwtBearer, Scalar,
  SignalR, OpenTelemetry, Resilience, Mvc.Testing.
- **testes**: projeto xUnit (global using Xunit). **Sem comandos soltos**: só classes. Só compila.
- **biblioteca**: só tipos (classes, interfaces, records…). Sem comandos soltos. Só compila.
- **unity**: script do **Unity 6** — **C# 9** (sem `record` struct/`required`/raw string/list pattern/
  namespace de arquivo/`global using`), **sem ImplicitUsings** (escreva `using UnityEngine;`,
  `using System.Collections;` etc. em cada trecho que precisar), Nullable desligado, sem comandos soltos.
  Compila contra o stub `$SCR/lab/stubs/UnityEngine.cs` — **leia o stub** e use só o que existe nele
  (é a API real do Unity 6: MonoBehaviour e ciclo de vida, Transform, Vector2/3, Quaternion, Time,
  Input clássico e Input System, Rigidbody/2D com `linearVelocity`, colisões/triggers, Physics.Raycast,
  corrotinas, Awaitable, ScriptableObject, UnityEvent, SceneManager, PlayerPrefs, Animator, AudioSource,
  NavMeshAgent, UI/TextMeshPro, UnityEngine.Pool.ObjectPool…). APIs antigas (`velocity`, `drag`,
  `angularDrag`, `Rigidbody2D.isKinematic`, `FindObjectOfType`, `FindFirstObjectByType`, `GetInstanceID`)
  dão erro — use `linearVelocity`, `linearDamping`, `bodyType`, `FindAnyObjectByType`. A BCL é a do
  **.NET Standard 2.1** (a que o Unity expõe): nada de `PriorityQueue`, `Random.Shared`, `Random.Shuffle`.
  Prefira referências por `[SerializeField]` e eventos a `Find*`/`GetComponent` dentro de `Update`.
  Cuidado: `using System;` + `using UnityEngine;` torna `Random` e `Object` ambíguos (igual no Unity real).
- **godot**: script C# do **Godot 4** (GodotSharp 4.7 + geradores de código): classes `partial` que
  herdam de nós (`Node2D`, `CharacterBody2D`, `Area2D`…), `_Ready`, `_Process(double delta)`,
  `_PhysicsProcess`, `[Export]`, `[Signal] ...EventHandler` + `EmitSignal(SignalName.X)`, `GD.Print`,
  `GetNode<T>("caminho")`, `Input.IsActionPressed`. Sem ImplicitUsings (escreva `using Godot;`), C# 12,
  Nullable desligado, sem comandos soltos. Só compila.
- **monogame**: MonoGame 3.8 DesktopGL: classe que herda `Game` (Initialize, LoadContent,
  Update(GameTime), Draw(GameTime)), SpriteBatch, Texture2D, Vector2, Rectangle, Keyboard.GetState.
  Sem ImplicitUsings. Pode ter o `using var jogo = new Jogo(); jogo.Run();` do Program.cs. Só compila.

## Pedagogia e progressão (o que diferencia um curso bom)

- Cada lição ensina **uma ideia central** com variações; a trilha segue a ordem do esboço.
- Use **só** o que já foi ensinado em trilhas anteriores ou na própria trilha até ali (o esboço lista
  as trilhas anteriores). Se precisar de algo novo, apresente na teoria antes.
- Nível **Iniciante**: exemplos concretos, nomes em português, muito `Console.WriteLine`.
- **Intermediário**: modelagem de domínio, coleções, LINQ, erros, async — código de aplicação real.
- **Avançado**: .NET de verdade (DI, web, dados, testes, desempenho, jogos) com as APIs atuais.
- **Sênior**: arquitetura e decisões: trade-offs, quando usar/não usar, anti-padrões, custos,
  testes de arquitetura, observabilidade, resiliência. Mostre o "antes/depois" de uma refatoração.
- Nomes de identificadores: pode misturar português (domínio: `Pedido`, `CalcularFrete`) e inglês
  quando é convenção da plataforma (`Dispose`, `ToString`, `Handle`, `Configure`). Siga as convenções
  do .NET: PascalCase em tipos/métodos/propriedades, camelCase em locais/parâmetros, `_campo` privado,
  `I` em interfaces, sufixo `Async` em métodos assíncronos.
