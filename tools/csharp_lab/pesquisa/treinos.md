# Dossiê de pesquisa · Frente **treinos** (PAC·C#)

**Tema:** bons treinos e exercícios de C#: syllabus do Exercism, Microsoft Learn/freeCodeCamp, Codewars, LeetCode/HackerRank, livros e cursos, e pesquisa pedagógica sobre tipos de exercício (Parsons, prever a saída, lacunas, achar o bug, exemplos resolvidos, prática espaçada, progressão em escada).
**Data:** 27/09/2026 · **Para:** geradores de trilhas, lições, digitação e desafios de lógica do PAC·C#.
**Verificação:** todo o código deste dossiê foi **compilado e executado** no .NET SDK 10.0.102 (runtime 10.0.2, C# 14) em macOS com cultura **pt-BR**. Os exemplos sem recursos de C# 14 também rodaram no .NET SDK 9.0.112 (C# 13). As saídas mostradas são as saídas reais. Os arquivos de verificação estão em `scratchpad/csharp/_treinos_verif/` (ex01–ex16, v_*.cs, t_*.cs, erros/e01–e16).

## 0. Resumo executivo

1. **Ordem.** Use o grafo de pré-requisitos do Exercism (42 exercícios-conceito, 72 conceitos) como espinha e a sequência do Microsoft Learn *Foundational C#* (6 partes, 35 módulos) no nível iniciante. Para algoritmos, siga o LeetCode 75 (22 categorias). No sênior, os e-books de arquitetura da Microsoft e o refactoring.guru. Nos jogos, *Game Programming Patterns* e a documentação de Unity, Godot e MonoGame. A proposta de 48 trilhas está no §1.4.
2. **Ler antes de escrever; semântica antes de padrões** (Xie et al., 2019). Toda lição segue: prever/rastrear → digitar → completar → ordenar (Parsons) → corrigir → escrever de memória.
3. **Parsons com distratores pareados** ensina tanto quanto corrigir ou escrever o código equivalente, em menos tempo (Ericson et al., 2017). É o formato do "ordenar linhas".
4. **Exemplos resolvidos com rótulos de subobjetivo e *fading*** nos níveis iniciais (Margulieux et al., 2016; Renkl/Atkinson). O apoio sai à medida que o aluno domina o assunto (efeito de reversão da expertise).
5. **Recuperação espaçada e intercalada** (Karpicke & Roediger, 2007; Cepeda et al., 2008; Rohrer et al., 2015): revisão em caixas de Leitner, com 20–30% dos itens vindos de lições anteriores.
6. **Calibração:** mirar ~70–85% de acerto na prática e subir **um** "botão" de dificuldade por vez (§4.5).
7. **Armadilhas brasileiras:** a cultura pt-BR muda a saída (`3,5`), o parsing (`double.Parse("3.5")` vira **35**), a moeda (`R$ 10,00`) e até o `Vector2` (`<1,5. 0>`). Todo desafio com decimal, data ou moeda deve declarar a cultura.
8. **Versão base:** C# 14/.NET 10 (LTS). Marque o que só existe no C# 14 (`field`, membros de extensão, `?.=`). O C# 15 ainda é *preview* (.NET 11) e fica fora dos exercícios.
9. **Validação:** `dotnet run app.cs` (file-based app) liga o Native AOT por padrão, e o JSON por reflexão **lança exceção**. Use `#:property PublishAot=false` ou *source generator* (§3).
10. **"Achar o bug" com erros reais:** o SDK em pt-BR emite mensagens em português (ex.: `CS0165: Uso de variável local não atribuída`). Use os códigos CSxxxx verdadeiros (§4.4).

## 1. Árvore de tópicos em ordem didática

### 1.1 Syllabus do Exercism (C#): conceitos em ordem topológica

Fonte: `config.json` da trilha (https://github.com/exercism/csharp/blob/main/config.json), baixado em 27/09/2026. A profundidade de um conceito é 1 + a maior profundidade entre os pré-requisitos do exercício que o ensina. Formato: **conceito(s)** (exercício-conceito) ← pré-requisitos. Para caber na tabela, omiti pré-requisitos que já vêm por transitividade (ex.: `booleans` quando `if` já está na lista).

| Prof. | Conceitos ← pré-requisitos |
|---|---|
| 1 | **basics** (lucians-luscious-lasagna) ← nenhum |
| 2 | **booleans** (annalyns-infiltration) ← basics · **strings** (log-levels) ← basics |
| 3 | **if-statements, numbers** (cars-assemble) ← booleans · **extension-methods** (log-analysis) ← strings · **tuples** (phone-number-analysis) ← strings |
| 4 | **classes** (jedliks-toys) ← if, numbers, strings · **while, do-while, floating-point** (interest-is-interesting) ← if, numbers · **nullability** (tim-from-marketing) ← if, strings · **randomness** (roll-the-die) ← numbers |
| 5 | **arrays, for, foreach** (bird-watcher) ← booleans, classes, if · **constructors** (need-for-speed) ← classes, if, numbers, while · **datetimes** (booking-up-for-beauty) ← classes, numbers, strings |
| 6 | **chars, string-builder** (squeaky-clean) ← if, for, strings · **generic-types, lists** (tracks-on-tracks-on-tracks) ← arrays, for · **inheritance** (wizards-and-warriors) ← classes, constructors, if, strings · **integral-numbers** (hyper-optimized-telemetry) ← arrays, numbers |
| 7 | **dictionaries** (international-calling-connoisseur) ← foreach, generic-types, strings · **switch-statements** (football-match-reports) ← classes, inheritance, nullability |
| 8 | **enums** (logs-logs-logs) ← strings, switch · **exceptions** (calculator-conundrum) ← inheritance, nullability, switch · **time, timezone** (beauty-salon-goes-global) ← if, datetimes, strings, switch |
| 9 | **attributes, flag-enums** (attack-of-the-trolls) ← enums, integral · **casting** (secure-munchester-united) ← exceptions, inheritance, numbers · **overflow** (hyperinflation-hits-hyperia) ← exceptions, floating-point, integral, strings · **properties** (weighing-machine) ← classes, enums, exceptions, floating-point · **resource-cleanup** (object-relational-mapping) ← exceptions, inheritance · **string-formatting, verbatim-strings** (high-school-sweethearts) ← inheritance, string-builder, strings, time |
| 10 | **ternary, expression-bodied-members, switch-expressions, throw-expressions** (the-weather-in-deather) ← classes, constructors, datetimes, exceptions, properties, switch · **interfaces, ordering** (remote-control-competition) ← classes, lists, properties · **method-overloading, named-arguments, optional-parameters** (wizards-and-warriors-2) ← classes, constructors, enums, properties · **object-initializers** (developer-privileges) ← constructors, dictionaries, properties · **regular-expressions** (parsing-log-files) ← arrays, for, string-formatting, verbatim · **resource-lifetime** (orm-in-one-go) ← resource-cleanup · **user-defined-exceptions, exception-filtering** (instruments-of-texas) ← exceptions, inheritance, overflow, integral |
| 11 | **equality, sets** (faceid-2) ← classes, generic-types, inheritance, interfaces, lists · **parameters** (building-telemetry) ← constructors, named-arguments, numbers, strings |
| 12 | **operator-overloading** (hyperia-forex) ← equality, floating-point, method-overloading · **structs** (land-grab-in-space) ← classes, inheritance, sets, integral |
| 13 | **nested-types** (remote-control-cleanup) ← classes, enums, interfaces, properties, structs |
| 14 | **constants, defensive-copying, readonly-collections** (authentication-system) ← arrays, classes, dictionaries, nested-types, object-initializers, properties · **namespaces** (red-vs-blue-darwin-style) ← classes, inheritance, nested-types |

- **Conceitos só com texto, sem exercício-conceito:** bit-manipulation, compound-assignment, const-readonly, enumerables, explicit-casts, indexers, lambdas, math-operators, memory-allocation, varargs.
- **Conceitos que aparecem só nos 136 exercícios de prática ativos:** linq, yield, recursion, higher-order-functions, generic-methods, generic-constraints, lazy-evaluation, immutability, queues, stacks, multi-dimensional-arrays, concurrency, parallellism, streams, globalization, big-integers, events, observables.
- **Prática por dificuldade** (escala 1–10; o site trata 1–3 como fácil, 4–7 médio, 8–10 difícil): 1:15 · 2:11 · 3:21 · 4:23 · 5:31 · 6:14 · 7:7 · 8:7 · 9:3 · 10:4. Âncoras de calibração: *hello-world, two-fer, leap* (1) → *hamming, raindrops* (2) → *isogram, binary-search, allergies* (3) → *clock, anagram, word-count* (4) → *matching-brackets, roman-numerals, linked-list* (5) → *bowling, nth-prime* (6) → *poker, wordy* (7) → *dominoes, zebra-puzzle* (8) → *react* (9) → *forth, zipper* (10).
- **Leitura crítica:** a ordem do Exercism nasce do desenho dos exercícios. Por exemplo, `switch-statements` exige herança só porque o exercício usa classes derivadas, enquanto o Microsoft Learn ensina `switch` antes do `for`. Use o grafo como **restrição mínima** ("não cobrar X antes de Y"), e não como a única ordem possível. O próprio material tem erros: o `about.md` de *resource-lifetime* mostra `using (var file = new File("myStuff.txt")` sem fechar parênteses. Por isso, **nada entra sem compilar**.

### 1.2 Microsoft Learn: *Foundational C# with Microsoft* (freeCodeCamp)

São ~35 h de trilha no Microsoft Learn, mais um exame de 80 questões no freeCodeCamp. Cada parte termina com um **projeto guiado seguido de um projeto desafio**, ou seja, um andaime que é retirado. URL dos módulos: `https://learn.microsoft.com/en-us/training/modules/<slug>/`.
1. **Parte 1, primeiro código:** csharp-write-first · csharp-literals-variables · csharp-basic-operations · csharp-if-elseif-else.
2. **Parte 2, apps de console:** install-configure-visual-studio-code · csharp-call-methods · csharp-arrays (arrays + foreach) · csharp-readable-code · projeto guiado e desafio (arrays, foreach, if).
3. **Parte 3, lógica:** csharp-evaluate-boolean-expressions · csharp-code-blocks (escopo) · csharp-switch-case · csharp-for · csharp-do-while · projeto guiado e desafio.
4. **Parte 4, dados variáveis:** csharp-choose-data-type · csharp-convert-cast · csharp-arrays-operations · csharp-format-strings · csharp-modify-content · projeto guiado e desafio.
5. **Parte 5, métodos:** write-first-c-sharp-method · create-c-sharp-methods-parameters · create-c-sharp-methods-return-values · projeto guiado (petting zoo) · desafio (mini-game).
6. **Parte 6, depuração:** review-principles-code-debugging-exception-handling-c-sharp · implement-visual-studio-code-debugging-tools · implement-exception-handling-c-sharp · create-throw-exceptions-c-sharp · projeto guiado e desafio.

### 1.3 Outras sequências de referência (para conferir cobertura)

- **HackerRank 30 Days of Code** (aceita C#): 0 Hello World · 1 Data Types · 2 Operators · 3 Conditionals · 4 Class vs Instance · 5 Loops · 6 Review · 7 Arrays · 8 Dictionaries · 9 Recursion · 10 Binary Numbers · 11 2D Arrays · 12 Inheritance · 13 Abstract Classes · 14 Scope · 15 Linked List · 16–17 Exceptions · 18 Queues/Stacks · 19 Interfaces · 20 Sorting · 21 Generics · 22 BST · 23 BST Level-Order · 24 Linked Lists · 25 Running Time · 26 Nested Logic · 27 Testing · 28 RegEx · 29 Bitwise AND.
- **LeetCode 75** (22 categorias, 75 problemas): Array/String 9 · Two Pointers 4 · Sliding Window 4 · Prefix Sum 2 · Hash Map/Set 4 · Stack 3 · Queue 2 · Linked List 4 · Binary Tree DFS 6 · Binary Tree BFS 2 · BST 2 · Graphs DFS 4 · Graphs BFS 2 · Heap/Priority Queue 4 · Binary Search 4 · Backtracking 2 · DP 1D 4 · DP multidimensional 4 · Bit Manipulation 3 · Trie 2 · Intervals 2 · Monotonic Stack 2. O *Tech Interview Handbook* organiza em 5 semanas: sequências → estruturas lineares → árvores/grafos/heaps → estruturas avançadas → DP (opcional).
- **Codewars** (C# 10/.NET 6, 12/.NET 8 e 13/.NET 9; testes NUnit; limite de 12 s): 8–7 kyu "beginner" (função simples, if/else, laços, API básica, regex simples) · 6–5 kyu "novice" (algoritmos, closures, OOP e funcional intermediários, padrões básicos) · 4–3 kyu "competent" (algoritmos de CS, concorrência, metaprogramação, criptografia) · 2–1 kyu "proficient" (interpretadores e compiladores, IA, mini-programas com vários recursos).
- **Livros e cursos:**
  - *C# 12 in a Nutshell*: Basics → Creating Types → Advanced C# → .NET Fundamentals → Collections → LINQ → Disposal/GC → Concurrency/Async → Streams → Reflection → Advanced Threading → Parallel → Span/Memory → Regex.
  - *Pro C# 10 with .NET 6*: Core Constructs 1–2 → Encapsulation → Inheritance/Polymorphism → Exceptions → Interfaces → Object Lifetime → Collections/Generics → Advanced Features → Delegates/Events/Lambdas → LINQ → Multithreaded/Parallel/Async.
  - *C# in Depth*, 4ª ed.: nível intermediário, C# 2–7. *The C# Player's Guide*, 5ª ed.: 52 "níveis" com desafios, *Knowledge Checks* e projetos de jogo (*Fountain of Objects*, *The Final Battle*).
  - *Deep Dive: C#* (Dometrain): valor/referência e records → OOP e composição → streams e JSON → delegates, LINQ, Lazy e eventos → multi-projeto e NuGet → threads, tasks, async e cancelamento.
  - Nick Chapsas, "From Zero to Hero": REST, DI, async, paralelo, testes, GC, benchmarking. Tim Corey: *C# Mastercourse* (200 aulas, 70 h, com *homework*) e *C# App from Start to Finish* (Tournament Tracker, 24 h).

### 1.4 Árvore proposta PAC·C# (48 trilhas, em ordem)

Formato: **Txx · Nome** · nível: o que ensinar. Fontes. Abreviações: **ML/** = `https://learn.microsoft.com/en-us/training/modules/`; **EX/** = `https://github.com/exercism/csharp/tree/main/concepts/`; **DOC/** = `https://learn.microsoft.com/en-us/dotnet/csharp/`.

**INICIANTE** (T01–T14; Codewars 8–7 kyu; Exercism 1–3)
- **T01 · Primeiros passos** · iniciante: `Console.WriteLine`/`Write`, top-level statements, comentários, `dotnet new console` e `dotnet app.cs`, ler um erro CSxxxx. ML/csharp-write-first · https://learn.microsoft.com/en-us/dotnet/core/sdk/file-based-apps
- **T02 · Variáveis e tipos** · iniciante: `string`, `char`, `int`, `double`, `decimal`, `bool`; sufixos `m`/`f`/`L`, `1_000`, `var`, `const`, valores padrão. ML/csharp-literals-variables · EX/basics
- **T03 · Operadores** · iniciante: `+ - * / %`, divisão inteira, precedência, `++`/`--` pré e pós, `+=`, `Math.*`. ML/csharp-basic-operations · EX/numbers · EX/math-operators
- **T04 · Strings I** · iniciante: concatenação, interpolação, escapes, `@"..."`, `Length`/`ToUpper`/`Trim`/`Contains`/`IndexOf`/`Substring`/`Replace`, imutabilidade. ML/csharp-modify-content · EX/strings
- **T05 · Decisões** · iniciante: comparações, `&& || !` com curto-circuito, `if`/`else if`/`else`, ternário, escopo de bloco. ML/csharp-evaluate-boolean-expressions · ML/csharp-if-elseif-else · ML/csharp-code-blocks
- **T06 · switch** · iniciante: `case`/`break`/`default` (não existe *fall-through*) e uma primeira `switch` expression. ML/csharp-switch-case · EX/switch-statements
- **T07 · Laços** · iniciante: `for`, `while`, `do-while`, `break`/`continue`, laços aninhados; padrões contador, acumulador e máximo. ML/csharp-for · ML/csharp-do-while · EX/while-loops
- **T08 · Arrays e foreach** · iniciante: criar, indexar, `Length`, `foreach`, `Array.Sort`/`Reverse`/`IndexOf`, `^1` e `1..3`. ML/csharp-arrays · ML/csharp-arrays-operations · EX/arrays
- **T09 · Conversões** · iniciante: escolher o tipo, conversão implícita e explícita, cast, `Parse` × `TryParse`, `Convert`, overflow. ML/csharp-choose-data-type · ML/csharp-convert-cast · EX/casting
- **T10 · Formatação e cultura** · iniciante: `:F2 :N2 :C :P :D5`, alinhamento `{x,-10}`, pt-BR × invariante. ML/csharp-format-strings · EX/string-formatting · DOC/fundamentals/strings/interpolation
- **T11 · Métodos** · iniciante: parâmetros, retorno, `void`, sobrecarga, parâmetros opcionais e nomeados, `=>`. ML/write-first-c-sharp-method · ML/create-c-sharp-methods-parameters · ML/create-c-sharp-methods-return-values
- **T12 · Depuração e exceções I** · iniciante: breakpoints, `try`/`catch`/`finally`, exceções comuns, `throw`. ML/implement-visual-studio-code-debugging-tools · ML/implement-exception-handling-c-sharp · ML/create-throw-exceptions-c-sharp
- **T13 · Código legível** · iniciante: PascalCase e camelCase, `_campo`, comentários, espaçamento, convenções .NET. ML/csharp-readable-code · DOC/fundamentals/coding-style/coding-conventions
- **T14 · Chefe iniciante** · iniciante: mini-jogo de console (adivinhação, dados, forca) que junta T01–T13. ML/challenge-project-create-mini-game · https://csharpplayersguide.com/solutions/5th-edition/

**INTERMEDIÁRIO** (T15–T28; Codewars 6–5 kyu; Exercism 3–5)
- **T15 · Classes e objetos** · intermediário: campos, métodos, construtores, `this`, `new`, encapsulamento. EX/classes · EX/constructors · DOC/fundamentals/types/classes
- **T16 · Propriedades** · intermediário: auto-props, `get`/`set`/`init`, `private set`, validação, `required`, inicializadores de objeto. EX/properties · EX/object-initializers
- **T17 · Modificadores** · intermediário: `static`, `const` × `readonly`, `namespace`, `public`/`private`/`internal`/`protected`. EX/const-readonly · EX/namespaces · DOC/fundamentals/program-structure/namespaces
- **T18 · Herança e polimorfismo** · intermediário: `base`, `virtual`/`override`, `abstract`, `sealed`, `new` (ocultação), `ToString`. EX/inheritance · DOC/fundamentals/object-oriented/polymorphism
- **T19 · Interfaces** · intermediário: contratos, várias interfaces, `IComparable<T>`, `IEquatable<T>`, membros padrão (visão geral). EX/interfaces · DOC/fundamentals/types/interfaces
- **T20 · struct, record, enum e tuplas** · intermediário: valor × referência, `record` e `with`, `enum` com `[Flags]`, desconstrução. EX/structs · EX/flag-enums · EX/tuples · DOC/fundamentals/tutorials/choosing-types
- **T21 · Nulabilidade** · intermediário: `int?`, `string?`, `?.`, `??`, `??=`, `!`, `is null`, aviso CS8602. EX/nullability · DOC/fundamentals/null-safety/
- **T22 · Coleções** · intermediário: `List`, `Dictionary`, `HashSet`, `Queue`, `Stack`, `PriorityQueue`; escolher pela operação. EX/dictionaries · EX/sets · https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.priorityqueue-2
- **T23 · Genéricos** · intermediário: classes e métodos genéricos, restrições `where`, variância (visão geral). EX/generic-types · DOC/fundamentals/types/generics
- **T24 · Delegates, lambdas e eventos** · intermediário: `Func`/`Action`/`Predicate`, closures, `event`/`EventHandler`, multicast. EX/lambdas · DOC/fundamentals/types/delegates-lambdas · DOC/events-overview
- **T25 · LINQ** · intermediário: `Where`/`Select`/`OrderBy`/`GroupBy`/`Any`/`All`/`First(OrDefault)`/`Sum`/`ToList`, execução adiada. DOC/linq/ · DOC/linq/standard-query-operators/
- **T26 · Pattern matching** · intermediário: `is`, `switch` expression, padrões relacionais, lógicos, de propriedade, posicionais e de lista, `_`. DOC/fundamentals/patterns/pattern-matching · EX/switch-expressions
- **T27 · Texto II** · intermediário: `StringBuilder`, `Split`/`Join`, comparação `Ordinal`/`IgnoreCase`, `char`, regex, raw strings `"""`. EX/string-builder · EX/chars · EX/regular-expressions · DOC/fundamentals/strings/raw-string-literals
- **T28 · Exceções II e recursos** · intermediário: exceções próprias, filtro `when`, `throw;` × `throw ex;`, `IDisposable`/`using`. EX/user-defined-exceptions · EX/exception-filtering · EX/resource-lifetime

**AVANÇADO** (T29–T38; Codewars 4–3 kyu; Exercism 5–7; LeetCode Medium)
- **T29 · Tempo e globalização** · avançado: `DateTime`/`DateOnly`/`TimeOnly`/`TimeSpan`/`DateTimeOffset`, fuso, `CultureInfo`, `TimeProvider` nos testes. EX/datetimes · EX/time · EX/timezone
- **T30 · Iteradores** · avançado: `IEnumerable`/`IEnumerator`, `yield return`/`yield break`, avaliação preguiçosa, enumeração múltipla. DOC/iterators · EX/enumerables
- **T31 · Assíncrono** · avançado: `async`/`await`, `Task`/`Task<T>`, `WhenAll`/`WhenAny`, `CancellationToken`, `IAsyncEnumerable`, perigo do `async void`. DOC/asynchronous-programming/
- **T32 · Concorrência** · avançado: `Task` × `Thread`, `lock` com `System.Threading.Lock`, `Interlocked`, coleções concorrentes, `Parallel.For`, `Channel`. DOC/whats-new/csharp-13 · https://dometrain.com/course/deep-dive-csharp/
- **T33 · Arquivos, streams e JSON** · avançado: `File`, `StreamReader`/`StreamWriter`, encoding, `System.Text.Json` com source generator. https://dometrain.com/course/deep-dive-csharp/ · https://learn.microsoft.com/en-us/dotnet/core/sdk/file-based-apps
- **T34 · Tipos avançados** · avançado: sobrecarga de operadores, indexadores, membros de extensão (C# 14), `Equals`/`GetHashCode`/`IEquatable`, generic math. EX/operator-overloading · EX/equality · EX/indexers · DOC/whats-new/csharp-14
- **T35 · Memória e desempenho** · avançado: stack × heap, boxing, GC, `Span<T>`/`Memory<T>`, `stackalloc`, `ArrayPool`, BenchmarkDotNet. EX/memory-allocation · DOC/advanced-topics/performance/
- **T36 · Reflexão e atributos** · avançado: atributos próprios, leitura por reflexão, geradores de código (visão geral). EX/attributes · DOC/advanced-topics/reflection-and-attributes/
- **T37 · Testes** · avançado: xUnit (`[Fact]`, `[Theory]`, `[InlineData]`), padrão AAA, nomes `Metodo_Cenario_Resultado`, stub × mock, *seams*. https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices
- **T38 · Algoritmos e estruturas** · avançado: Big-O, two pointers, sliding window, prefix sum, hash, pilha/fila, listas ligadas, DFS/BFS, BST, heap, busca binária, backtracking, DP, bits, trie, intervalos. https://leetcode.com/studyplan/leetcode-75/ · https://www.techinterviewhandbook.org/best-practice-questions/

**SÊNIOR: arquitetura** (T39–T44; Codewars 2–1 kyu; Exercism 8–10; desafios de design)
- **T39 · Princípios** · sênior: separação de responsabilidades, encapsulamento, SOLID, DRY (sem acoplar à abstração errada), dependências explícitas, *persistence ignorance*. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles
- **T40 · Injeção de dependência** · sênior: `IServiceCollection`, tempos de vida, validação de escopo, dependência cativa, *keyed services*, options, logging. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview
- **T41 · Padrões GoF em C#** · sênior: Strategy, Decorator, Observer, Factory Method, Builder, Adapter, Command, State, Template Method, Chain of Responsibility, mais Result e Specification. https://refactoring.guru/design-patterns/csharp
- **T42 · ASP.NET Core** · sênior: minimal APIs, rotas e restrições, DI por parâmetro, ProblemDetails, **ordem dos middlewares**, autenticação e autorização. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/
- **T43 · EF Core** · sênior: `DbContext`, LINQ-to-Entities, tracking × `AsNoTracking`, `Include` e o problema N+1, owned types (value objects), migrations. https://learn.microsoft.com/en-us/ef/core/
- **T44 · Clean Architecture, DDD, CQRS e microsserviços** · sênior: regra de dependência (tudo aponta para o núcleo), entidades, VOs, agregados e eventos de domínio, commands × queries, mensageria, idempotência, quando **não** usar microsserviços. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures · https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/

**JOGOS** (T45 cabe logo após T22, T46 após T24 e T47–T48 após T31; os desafios com tema de jogos entram em todas as trilhas)
- **T45 · Lógica de jogo em C# puro** · intermediário: game loop, delta time, máquina de estados, grade, colisão AABB, `Random` com semente, inventário, turnos, BFS. https://gameprogrammingpatterns.com/contents.html · https://csharpplayersguide.com/solutions/5th-edition/
- **T46 · Padrões de jogo** · avançado: Command (input e replay), Observer (HUD), State (IA), Object Pool (projéteis), Component, Event Queue, Update Method. https://gameprogrammingpatterns.com/contents.html
- **T47 · Unity** · avançado: `MonoBehaviour` e a ordem Awake → OnEnable → Start → FixedUpdate → Update → LateUpdate → OnDisable → OnDestroy; `Time.deltaTime`, `[SerializeField]`. https://docs.unity3d.com/Manual/execution-order.html
- **T48 · Godot 4 (C#) e MonoGame** · avançado: `partial class : Node`, `_Ready`, `_Process(double delta)`, `[Export]` (sem export para web em C#); `Game1` com Initialize → LoadContent (chamado por `base.Initialize()`) → Update/Draw a 60 Hz. https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html · https://docs.monogame.net/articles/tutorials/building_2d_games/03_the_game1_file/index.html

## 2. Exemplos de código de referência (compilados e executados; saídas reais em pt-BR)

**2.1 Números** (ex01): divisão inteira, resto, truncamento, arredondamento bancário, `double` × `decimal`, overflow.
```csharp
Console.WriteLine(7 / 2);             // 3    (int / int = divisão inteira)
Console.WriteLine(7 / 2.0);           // 3,5  em pt-BR | 3.5 em cultura invariante
Console.WriteLine(-7 % 3);            // -1   (resto tem o sinal do dividendo)
Console.WriteLine((int)-3.99);        // -3   (cast trunca em direção a zero)
Console.WriteLine(Math.Round(2.5));   // 2    (padrão = ToEven, "arredondamento bancário")
Console.WriteLine(Math.Round(2.5, MidpointRounding.AwayFromZero)); // 3
Console.WriteLine(0.1 + 0.2 == 0.3);      // False (double é binário)
Console.WriteLine(0.1m + 0.2m == 0.3m);   // True  (decimal: use para dinheiro)
int grande = int.MaxValue;
Console.WriteLine(grande + 1);        // -2147483648 (unchecked por padrão)
int[] notas = { 7, 8, 8 };
double errada = notas.Sum() / notas.Length;          // 7 (divisão inteira ANTES da conversão)
double certa = (double)notas.Sum() / notas.Length;
Console.WriteLine($"{errada} {certa:F2}");           // 7 7,67
```
Complementos verificados: `checked(grande + 1)` → `OverflowException`. `int y = int.MaxValue + 1;` → erro **CS0220** (constante). `byte b = 255; b++;` → 0. `uint u = 0; u--;` → 4294967295. Somar `0.1` dez vezes dá `0.9999999999999999`, então `== 1.0` é `False`.

**2.2 Strings e cultura** (ex02)
```csharp
using System.Globalization;
string s = "pac";
s.ToUpper();                          // resultado descartado: string é imutável
Console.WriteLine(s);                 // pac
Console.WriteLine(1 + 2 + "3");       // 33  (esquerda p/ direita: 3 + "3")
Console.WriteLine("1" + 2 + 3);       // 123
Console.WriteLine("banana".Substring(1, 3)); // ana (início, TAMANHO)
Console.WriteLine("banana"[1..4]);           // ana (início, FIM exclusivo)
var br = new CultureInfo("pt-BR");
var inv = CultureInfo.InvariantCulture;
Console.WriteLine(double.Parse("3.5", br));   // 35  (!) em pt-BR "." é separador de milhar
Console.WriteLine(3.5.ToString(inv));         // 3.5
Console.WriteLine(10m.ToString("C", br));     // R$ 10,00
var natal = new DateOnly(2026, 12, 25);
Console.WriteLine(natal.DayOfWeek);                  // Friday (nome do enum, não traduz)
Console.WriteLine(natal.ToString("dddd", br));       // sexta-feira
```

**2.3 Valor × referência; passagem de parâmetros** (ex03)
```csharp
var p1 = new PontoS { X = 1 };
var p2 = p1; p2.X = 99;               // struct: p2 é uma CÓPIA
var c1 = new PontoC { X = 1 };
var c2 = c1; c2.X = 99;               // class: c2 aponta para o MESMO objeto
Console.WriteLine($"{p1.X} {c1.X}");  // 1 99
int n = 1;
Inc(n);                               // recebe cópia: n não muda
IncRef(ref n);                        // recebe referência: n muda
int[] v = { 1, 2, 3 };
Zera(v);                              // altera o array compartilhado
Troca(v);                             // só reatribui a cópia local da referência
Console.WriteLine($"{n} {string.Join(",", v)}");  // 2 0,2,3
static void Inc(int x) => x++;
static void IncRef(ref int x) => x++;
static void Zera(int[] a) => a[0] = 0;
static void Troca(int[] a) { a = new[] { 7, 7, 7 }; }
struct PontoS { public int X; }
class PontoC { public int X; }
```

**2.4 Igualdade: record, `with` e boxing** (ex04)
```csharp
var r1 = new Ponto(1, 2);
var r2 = new Ponto(1, 2);
Console.WriteLine(r1 == r2);            // True  (record: igualdade por valor)
Console.WriteLine(r1 with { Y = 9 });   // Ponto { X = 1, Y = 9 }
object a = 1, b = 1;
Console.WriteLine(a == b);              // False (== em object compara referências das "caixas")
Console.WriteLine(a.Equals(b));         // True
record Ponto(int X, int Y);
```

**2.5 Coleções** (ex05)
```csharp
var estoque = new Dictionary<string, int> { ["maçã"] = 3 };
estoque["maçã"]++;                        // 4
estoque["pera"] = 5;                      // indexador cria OU substitui
if (!estoque.TryGetValue("uva", out int qtd))
    Console.WriteLine($"sem uva ({qtd})"); // sem uva (0)   | estoque["uva"] lançaria KeyNotFoundException
var visitados = new HashSet<string>();
Console.WriteLine(visitados.Add("sala1")); // True
Console.WriteLine(visitados.Add("sala1")); // False (já estava)
var fila = new PriorityQueue<string, int>();
fila.Enqueue("goblin", 3);
fila.Enqueue("dragão", 1);
fila.Enqueue("slime", 5);
while (fila.TryDequeue(out var nome, out var prio))
    Console.Write($"{nome}({prio}) ");     // dragão(1) goblin(3) slime(5)
Console.WriteLine();
```
A menor prioridade sai primeiro e, em caso de empate, a ordem **não** é FIFO (documentação da API).

**2.6 Nulos** (ex06)
```csharp
string? apelido = null;
Console.WriteLine(apelido?.Length ?? -1); // -1
apelido ??= "Pac";
apelido ??= "Outro";                      // não atribui: já tem valor
Console.WriteLine(apelido);               // Pac
int? a = null;
int? soma = a + 5;                        // null se propaga
Console.WriteLine(soma.HasValue);         // False
```

**2.7 Pattern matching** (ex07)
```csharp
Console.WriteLine(Classificar(-5) + " " + Classificar(20) + " " + Classificar(31)); // congelando agradável quente
object o = 42;
string d = o switch
{
    int n when n > 10 => "int grande",
    int => "int",
    string txt => $"texto({txt.Length})",
    null => "nulo",
    _ => "outro"
};
Console.WriteLine(d);                     // int grande
int[] b = [0, 1, 2, 3, 4];
Console.WriteLine(b is [0, .., 4]);       // True (padrão de lista)
static string Classificar(int t) => t switch
{
    < 0 => "congelando",
    >= 0 and < 20 => "frio",
    >= 20 and <= 30 => "agradável",
    _ => "quente"
};
```

**2.8 OOP: `override` × `new` e ordem de construção** (ex08)
```csharp
Animal a1 = new Cao();
Animal a2 = new Gato();
Console.WriteLine($"{a1.Som()} {a2.Som()}");  // au ...   (new OCULTA, não sobrescreve)
_ = new Derivada();                           // BDC
Console.WriteLine();
class Animal { public virtual string Som() => "..."; }
class Cao : Animal { public override string Som() => "au"; }
class Gato : Animal { public new string Som() => "miau"; }
class Base
{
    public Base() { Console.Write("B"); Mostrar(); }
    public virtual void Mostrar() { }
}
class Derivada : Base
{
    private string _nome = "D";               // inicializador da derivada roda ANTES do construtor da base
    public Derivada() => Console.Write("C");
    public override void Mostrar() => Console.Write(_nome);
}
```
Outro caso verificado: construtores simples de `Pai` e `Filho` imprimem `Pai Filho` (base primeiro).

**2.9 Exceções: `finally` com `return` e filtro `when`** (ex09)
```csharp
Console.WriteLine(F());                       // 1 (o valor de retorno é avaliado antes do finally)
try { throw new SaldoInsuficienteException(50); }
catch (SaldoInsuficienteException e) when (e.Falta > 10)
{
    Console.WriteLine($"falta {e.Falta}");    // falta 50
}
static int F()
{
    int x = 1;
    try { return x; }
    finally { x = 2; }
}
class SaldoInsuficienteException(decimal falta) : Exception($"Faltam {falta}")
{
    public decimal Falta { get; } = falta;
}
```

**2.10 LINQ: execução adiada e enumeração múltipla** (ex10)
```csharp
var nums = new List<int> { 1, 2, 3 };
var query = nums.Where(n => n > 1);     // nada executa aqui (execução adiada)
nums.Add(4);
Console.WriteLine(query.Count());       // 3 (executa agora e enxerga o 4)
int chamadas = 0;
var seq = Enumerable.Range(1, 3).Select(x => { chamadas++; return x * 10; });
int soma = seq.Sum();
int qtd = seq.Count();
Console.WriteLine($"{soma} {qtd} {chamadas}");  // 60 3 6 (a sequência foi percorrida 2 vezes)
```

**2.11 Closures: `for` × `foreach`** (ex11)
```csharp
var acoes = new List<Action>();
for (int i = 0; i < 3; i++) acoes.Add(() => Console.Write(i));
foreach (var a in acoes) a();           // 333 (todas capturam o MESMO i)
Console.WriteLine();
var acoes2 = new List<Action>();
foreach (var i in new[] { 0, 1, 2 }) acoes2.Add(() => Console.Write(i));
foreach (var a in acoes2) a();          // 012 (foreach cria uma variável nova por iteração)
Console.WriteLine();
```

**2.12 async/await: ordem, `WhenAll` e cancelamento** (ex12)
```csharp
Console.Write("A");
var t = FazAsync();
Console.Write("C");
await t;
Console.WriteLine("E");                 // ABCDE
int[] r = await Task.WhenAll(Dobro(1), Dobro(2), Dobro(3));
Console.WriteLine(string.Join(",", r)); // 2,4,6 (ordem dos argumentos, não de término)
using var cts = new CancellationTokenSource();
cts.Cancel();
try { await Task.Delay(1000, cts.Token); }
catch (OperationCanceledException e) { Console.WriteLine(e.GetType().Name); } // TaskCanceledException
static async Task FazAsync()
{
    Console.Write("B");                 // roda de forma síncrona até o primeiro await
    await Task.Delay(10);
    Console.Write("D");
}
static async Task<int> Dobro(int x) { await Task.Delay(10 * (4 - x)); return x * 2; }
```

**2.13 `using`/Dispose, eventos e delegates multicast** (ex13)
```csharp
{
    using var a = new Recurso("a");
    using var b = new Recurso("b");
    Console.Write("usa ");
}                                        // usa fecha-b fecha-a (ordem inversa)
Console.WriteLine();
var botao = new Botao();
int cliques = 0;
EventHandler h = (s, e) => cliques++;
botao.Clicou += h;
botao.Clicou += h;                       // inscrito 2 vezes
botao.Clicar();                          // +2
botao.Clicou -= h;                       // remove UMA inscrição
botao.Clicar();                          // +1
Console.WriteLine(cliques);              // 3
Func<int, int> f = n => n + 1;
f += n => n * 10;
Console.WriteLine(f(5));                 // 50 (multicast devolve o resultado do ÚLTIMO)
class Recurso(string nome) : IDisposable
{
    public void Dispose() => Console.Write($"fecha-{nome} ");
}
class Botao
{
    public event EventHandler? Clicou;
    public void Clicar() => Clicou?.Invoke(this, EventArgs.Empty);
}
```

**2.14 C# moderno: C# 11 a 14** (ex14). Os recursos de C# 14 **não compilam no .NET 9** (testado).
```csharp
using System.Numerics;
int[] a = [1, 2, 3];                      // C# 12: expressão de coleção
int[] b = [0, .. a, 4];                   // spread
var cfg = new Config { Nome = "pac" };    // C# 11: sem Nome -> erro CS9035
var heroi = new Heroi { Nome = "  Pac  " };
Cliente? cliente = null;
cliente?.UltimoAcesso = DateTime.UtcNow;  // C# 14: só atribui se cliente != null
Console.WriteLine($"{string.Join(",", b)} {cfg.Porta} [{heroi.Nome}] {"   ".EhVazio} {Soma([1.5, 2.5])}");
// 0,1,2,3,4 80 [Pac] True 4
static T Soma<T>(T[] valores) where T : INumber<T>   // C# 11: generic math
{
    T total = T.Zero;
    foreach (var v in valores) total += v;
    return total;
}
class Jogador(string nome) { public string Nome { get; } = nome; }  // C# 12: construtor primário
class Config
{
    public required string Nome { get; init; }
    public int Porta { get; init; } = 80;
}
class Cliente { public DateTime UltimoAcesso { get; set; } }
class Heroi
{
    public string Nome                                   // C# 14: palavra-chave field
    {
        get;
        set => field = value?.Trim() ?? throw new ArgumentNullException(nameof(value));
    } = "";
}
static class ExtensoesDeTexto
{
    extension(string texto)                              // C# 14: membros de extensão
    {
        public bool EhVazio => string.IsNullOrWhiteSpace(texto);
    }
}
```
Também verificados: `nameof(List<>)` → `List` (C# 14); `params ReadOnlySpan<int>`, `System.Threading.Lock` e `'\e'` (C# 13, .NET 9+).

**2.15 DI: dependência cativa detectada** (ex15; file-based app com `#:package Microsoft.Extensions.DependencyInjection@10.0.0`)
```csharp
using Microsoft.Extensions.DependencyInjection;
var services = new ServiceCollection();
services.AddScoped<Contexto>();
services.AddSingleton<Cache>();           // singleton que depende de scoped = "dependência cativa"
try
{
    using var sp = services.BuildServiceProvider(
        new ServiceProviderOptions { ValidateScopes = true, ValidateOnBuild = true });
}
catch (AggregateException e)
{
    Console.WriteLine(e.InnerExceptions[0].Message);
    // ... Cannot consume scoped service 'Contexto' from singleton 'Cache'.
}
class Contexto;
class Cache(Contexto ctx) { public Contexto Ctx { get; } = ctx; }
```
Sem validação, o singleton "captura" o `Contexto` do provedor raiz (verificado). Tempos de vida verificados: transient → nova instância a cada pedido; scoped → a mesma instância dentro do escopo e outra em outro escopo; singleton → uma só.

**2.16 Jogos em C# puro** (ex16)
```csharp
int hp = Math.Clamp(30 - 45, 0, 100);
Console.WriteLine($"{hp} {Envolver(-1, 10)} {-1 % 10}");   // 0 9 -1
Console.WriteLine(Colide(new(0, 0, 10, 10), new(10, 0, 5, 5)));  // False (encostar não é colidir)
var estado = EstadoPac.Parado;
foreach (var e in new[] { "andar", "pular", "pousar", "parar", "pular" })
    estado = (estado, e) switch
    {
        (EstadoPac.Parado, "andar") => EstadoPac.Andando,
        (EstadoPac.Parado or EstadoPac.Andando, "pular") => EstadoPac.Pulando,
        (EstadoPac.Pulando, "pousar") => EstadoPac.Andando,
        (EstadoPac.Andando, "parar") => EstadoPac.Parado,
        _ => estado
    };
Console.WriteLine(estado);                // Pulando
static int Envolver(int x, int largura) => ((x % largura) + largura) % largura;
static bool Colide(Caixa a, Caixa b) =>
    a.X < b.X + b.L && a.X + a.L > b.X && a.Y < b.Y + b.A && a.Y + a.A > b.Y;
readonly record struct Caixa(float X, float Y, float L, float A);
enum EstadoPac { Parado, Andando, Pulando }
```

## 3. Armadilhas e boas práticas que o curso deve ensinar

**Números**
- `int / int` descarta a parte fracionária; a conversão para `double` tem de vir **antes** da divisão.
- O `%` negativo mantém o sinal do dividendo. No wrap-around, use `((x % n) + n) % n`.
- O cast `(int)` trunca em direção a zero. `Math.Round` e `Convert.ToInt32` usam arredondamento bancário (2,5 → 2). Informe o `MidpointRounding` quando a regra de negócio pedir.
- `double` não serve para dinheiro nem para comparar com `==` (use tolerância). Para dinheiro, `decimal` com sufixo `m`.
- Overflow de `int` é silencioso (unchecked). Mostre `checked(...)`, `long` e `BigInteger`. Um overflow em expressão constante vira erro CS0220.
- `double` dividido por zero dá `∞` ou `NaN`; `int` dividido por zero lança `DivideByZeroException`. `NaN == NaN` é `False`.

**Strings e cultura (crítico para alunos no Brasil)**
- `string` é imutável: `s.ToUpper();` sozinho não muda nada. Concatenar em laço gera lixo; use `StringBuilder`.
- `Substring(início, tamanho)` usa tamanho, e o range `[início..fim]` exclui o fim. Confundir os dois é off-by-one clássico.
- A concatenação avalia da esquerda para a direita: `1 + 2 + "3"` dá `33`; `'a' + 1` dá `98` (é `int`, não texto).
- Saída, parsing e formatação dependem de `CultureInfo.CurrentCulture`. Em pt-BR, `3.5` sai `3,5` e `double.Parse("3.5")` vira **35**. Para dados trocados entre sistemas (JSON, CSV, config), use `CultureInfo.InvariantCulture`.
- Em asserts, não compare moeda formatada como string exata: o espaço de `R$ 10,00` pode variar entre SO e versões do ICU. No macOS/.NET 10 saiu U+0020.
- `Vector2.ToString()` em pt-BR gera `<1,5. 0>` (usa o separador de grupo da cultura). É um bom "prever a saída" de nível avançado.
- `enum.ToString()` e `DayOfWeek` não são traduzidos (`Friday`). Para exibir, use `ToString("dddd", pt-BR)`.
- `"é" == "e"` é `False`. Para comparar sem acento, use `CompareInfo`/`CompareOptions`. Em identificadores, prefira nomes sem acento (`preco`, `acao`); nas strings, o acento é livre.
- `string.GetHashCode()` muda a **cada execução** do processo (verificado). Nunca persista esse valor nem use a ordem que ele produz em "prever a saída".

**Coleções e LINQ**
- A ordem de `Dictionary` e de `HashSet` não é garantida por contrato. Não use essa ordem em "prever a saída"; ordene antes com `OrderBy`.
- O indexador `dict[k]` lança `KeyNotFoundException` quando a chave não existe; prefira `TryGetValue` ou `GetValueOrDefault`.
- Alterar uma lista dentro de `foreach` lança `InvalidOperationException`. Use `RemoveAll`, um `for` de trás para frente ou uma cópia.
- `List<StructMutavel>`: `lista[0].X = 5` dá erro **CS1612**. Prefira structs imutáveis (`readonly record struct`).
- LINQ é adiado: a consulta roda quando é enumerada, e cada enumeração roda de novo. Materialize com `ToList()` quando for reusar.
- `List.Contains` é O(n) e `HashSet.Contains` é O(1). Escolha a coleção pela operação dominante.
- `PriorityQueue` não é FIFO em empates.
- `Array.Sort` e `List.Sort` ordenam no lugar, enquanto `OrderBy` devolve uma nova sequência. A ordenação padrão de strings é cultural: `a,A,b,B` em pt-BR contra `A,B,a,b` com `StringComparer.Ordinal`.

**OOP, igualdade e nulos**
- `new` num método **oculta** e não sobrescreve: chamado por uma referência da base, executa a versão da base. Polimorfismo exige `virtual`/`override`.
- Chamar método virtual dentro de construtor é perigoso: os inicializadores de campo da derivada já rodaram, mas o corpo do construtor dela ainda não.
- `Equals` sobrescrito sem `GetHashCode` quebra `Dictionary` e `HashSet` (a chave "some"). Records resolvem isso.
- `==` entre `object` compara referências, inclusive de valores com boxing.
- Struct acessada por interface sofre boxing: a cópia é alterada e o original não (verificado: `0 2`).
- Com nullable habilitado, trate os avisos CS8602/CS8618 como erros de design. `!` só silencia o compilador e não impede a `NullReferenceException`.
- Membros `init`/`required` tornam o objeto imutável e completo desde a criação (erros CS8852 e CS9035).

**Exceções e recursos**
- `throw;` preserva o stack trace; `throw ex;` o reinicia.
- Não engula exceções com `catch (Exception) { }`. Capture o tipo mais específico e use filtro `when`.
- Não use exceção como fluxo normal de regra de negócio. Para falhas esperadas, use `TryXxx` ou o padrão Result.
- `using var` libera os recursos em ordem inversa no fim do escopo. `finally` sempre roda, mas não muda um valor já avaliado no `return`.

**Assíncrono e concorrência**
- `async void` só em event handlers, porque a exceção não pode ser aguardada nem capturada por quem chamou.
- `.Result` e `.Wait()` bloqueiam e podem causar deadlock quando há `SynchronizationContext`. Siga "async até o fim".
- O método async roda de forma síncrona até o primeiro `await` (A→B→C→D→E no ex12).
- Propague o `CancellationToken`. `Task.Delay` cancelado lança `TaskCanceledException`, que deriva de `OperationCanceledException`.
- `Task.WhenAll` devolve os resultados na ordem dos argumentos.
- Contador compartilhado em `Parallel.For` precisa de `lock` ou `Interlocked`. No .NET 9+, prefira `System.Threading.Lock` ao `object`.
- Não crie `new HttpClient()` por requisição (esgota os sockets). Injete `HttpClient` ou `IHttpClientFactory`.

**Ferramentas e validação**
- File-based apps (`dotnet app.cs`) ligam o Native AOT por padrão. Na prática, `JsonSerializer.Serialize(obj)` lança `InvalidOperationException: Reflection-based serialization has been disabled`. Use `[JsonSerializable]` com um `JsonSerializerContext` (verificado) ou `#:property PublishAot=false`.
- Não coloque file-based apps dentro da árvore de um `.csproj`: os arquivos implícitos de build interferem (docs). Valide sempre fora do projeto real.
- O compilador em pt-BR fala português, o que é ótimo para "achar o bug": CS0029, CS0161, CS0163, CS0165, CS1612, CS1656, CS8852, CS9035…
- Testes seguem o padrão AAA, com nomes `Metodo_Cenario_Resultado`, um *Act* por teste, `[Theory]` em vez de laço no teste e *seams* (`TimeProvider`) em vez de `DateTime.Now`. Até a documentação oficial tem `Assert.Equals(...)`, que no xUnit nem compila (**CS0619**, verificado); o correto é `Assert.Equal`.

**Arquitetura (sênior)**
- Na Clean Architecture, as dependências apontam para o núcleo: o Core define as interfaces, a Infrastructure as implementa e a composição acontece no `Program.cs` (*composition root*).
- Scoped dentro de singleton (dependência cativa) deve ser pego com `ValidateScopes`/`ValidateOnBuild`.
- Ordem dos middlewares: ExceptionHandler/HSTS → HttpsRedirection → StaticFiles → Routing → CORS → Authentication → Authorization → endpoints. Na resposta, a ordem se inverte.
- DRY não vale para coincidências: duplicar é melhor do que acoplar à abstração errada (Microsoft, *Architectural principles*).
- Microsserviços têm custo alto (mensageria, consistência eventual, retries). Prefira começar com um monólito bem modularizado quando os limites do domínio ainda não estão claros.
- EF Core: `Include` e projeções evitam N+1; use `AsNoTracking` em leitura; nunca rode migrations no startup em produção sem planejamento.

**Jogos**
- Movimento sem `deltaTime` depende do FPS. Física (Rigidbody) vai em `FixedUpdate`, input e lógica visual em `Update` (Unity).
- `new Random(semente)` é determinístico (bom para replay e testes). Recriar o `Random` com a mesma semente dentro do laço repete os mesmos números.
- `Random.Next(1, 6)` nunca devolve 6, porque o limite superior é exclusivo (um d6 é `Next(1, 7)`). Não remova entidades dentro do `foreach` que percorre a lista (use `RemoveAll` depois do update). Compare posições `float` com tolerância.

## 4. Exercícios: evidência, formatos, bancos de ideias e calibração

### 4.1 O que a pesquisa diz, e o formato que isso gera no PAC·C#

| Evidência | Resultado | Formato no PAC·C# |
|---|---|---|
| Xie et al. 2019 (*Computer Science Education*) | Quatro habilidades ensinadas em ordem: **rastrear**, escrever sintaxe, compreender *templates* e escrever com *templates*. "Ler antes de escrever; semântica antes de padrões" elevou a conclusão de exercícios e reduziu erros. | Toda construção nova aparece como **prever saída** → **digitar** → **padrão** (contador, acumulador, busca) → **Mão na Massa**. |
| Lister et al. 2004 (ITiCSE, 7 países) e Lopez et al. 2008 | Muitos alunos falham em prever a saída de código curto e, pior, em escolher a linha que completa um código. Rastrear e explicar código se relaciona com a capacidade de escrever. | **Prever a saída**, **valor final** e **lacuna** com alternativas vêm antes da escrita livre. |
| Ericson, Margulieux & Rick 2017 (Koli Calling) | Parsons 2D com distratores **pareados** foi significativamente mais rápido do que corrigir ou escrever o equivalente, sem diferença no aprendizado nem na retenção uma semana depois. | **Ordenar linhas** com 1 distrator pareado por bloco "perigoso" (ex.: `<=` × `<`). |
| Ericson et al. 2022 (revisão de mais de 1.000 artigos) e Du et al. 2020 | Distratores pareados são recomendados (muitos distratores soltos sobrecarregam). O *Faded Parsons* (blocos com lacunas) faz a ponte até a escrita. Uma solução "incomum" deixa de ser mais rápida do que escrever. A evidência ainda pede replicação. | Parsons com **solução única e idiomática**, feedback por linha e evolução Parsons → Faded Parsons → digitação livre. |
| Van Merriënboer 1990 | A estratégia de **completar e modificar** programas superou a de gerar programas do zero em testes de construção, com menos evasão. | Muitas **lacunas** e tarefas "modifique este código" no iniciante. |
| Margulieux, Catrambone & Guzdial 2016 | Exemplos resolvidos com **rótulos de subobjetivo** melhoraram a resolução de problemas novos. | Worked example digitado com comentários-rótulo (`// 1. ler entrada`, `// 2. validar`, `// 3. acumular`). |
| Renkl & Atkinson (*fading*) e Kalyuga et al. 2003 | Retirar passos do exemplo, de trás para frente, melhora a transferência próxima. Para quem já sabe, o exemplo detalhado **atrapalha** (reversão da expertise). | Retirar primeiro o último passo; quem acerta muito pula o exemplo e vai direto ao problema. |
| PRIMM (Sentance, Waite, Kallia) | Predict → Run → Investigate → Modify → Make: ler antes de escrever, apoiado em Use-Modify-Create. | Esqueleto de cada lição (§4.2). |
| Lister et al. 2006 (SOLO) e Murphy et al. 2012 (EiPE) | Novatos descrevem linha a linha (multiestrutural); especialistas descrevem o propósito (relacional). Explicar código em linguagem simples se correlaciona com escrever. | **Escolha conceitual**: "o que este código faz?", com alternativas em nível de propósito. |
| Karpicke & Roediger 2007; Roediger & Karpicke 2006 | Testar vence reestudar depois de 2 dias e de 1 semana. Continuar recuperando itens já acertados aumentou a retenção em mais de 100% em relação a descartá-los. | Não aposentar exercício acertado: ele volta em revisões espaçadas. |
| Cepeda et al. 2008 | O intervalo ótimo entre estudos fica em ~20% do prazo de retenção (semanas) e cai para ~5% em um ano. | Revisões em 1, 3, 7, 16 e 35 dias (Leitner). |
| Rohrer, Dedrick & Stershic 2015 (*J. Educ. Psych.*; online em 2014; 126 alunos do 7º ano) | Prática intercalada contra em bloco: 80% × 64% em 1 dia e 74% × 42% em 30 dias (d = 0,79), porque obriga a **escolher** a estratégia. | 20–30% de itens de trilhas anteriores, misturando conceitos confundíveis (`for`/`foreach`/`while`, struct/class, `==`/`Equals`). |
| Dunlosky et al. 2013 | Utilidade alta: prática de teste e prática distribuída. Moderada: intercalação e autoexplicação. Baixa: reler e grifar. | Quiz e desafios valem mais do que reler a teoria. |
| 4C/ID (van Merriënboer) | Apoio em "dente de serra" (muito no início de cada classe de tarefa, nenhum no fim). *Part-task practice* (drill) para habilidades recorrentes, dentro de um contexto de tarefa completa. | A digitação é o drill da sintaxe, e cada trilha fecha com uma tarefa inteira. |
| Thomas et al. 2005 (ACE) | A latência de teclas nas **transições entre tipos de tecla** (letra ↔ símbolo) acompanhou o desempenho em programação. É correlação, com replicação parcial em 2024. | Medir e treinar símbolos típicos de C# (`{ } ; => ?. ?? <T> $"{}"`), sem vender a digitação como causa da competência. |
| Wilson et al. 2019 (Nature Comms) | ~85% de acerto maximiza o aprendizado em modelos de classificação binária. O próprio autor alerta que isso não se transpõe direto para aprendizagem complexa. | Usar como **heurística** de dificuldade-alvo, e não como lei. |
| McCauley et al. 2008; Qian & Lehman 2017 | Depurar é difícil de ensinar. Os erros dos novatos são sintáticos, conceituais e estratégicos. | O "achar o bug" progride de sintaxe (CSxxxx) para exceção em runtime, erro de lógica, semântica (referência, closure, async) e cheiro de design. |

### 4.2 Receita de lição (~9 exercícios) e de trilha (~12 lições)

**Lição (dente de serra):** (1) exemplo resolvido **digitado**, com rótulos de subobjetivo → (2) prever a saída desse código → (3) digitar uma variação → (4) lacuna com 1–2 buracos → (5) Parsons com 1–2 distratores pareados → (6) achar o bug (um erro típico do conceito) → (7) digitar "de memória", com o enunciado e sem o modelo (faded) → (8) desafio intercalado com uma trilha anterior → (9) mini-chefe de 5–8 linhas com tema de jogo ou do dia a dia.

**Trilha:** as lições 1–3 introduzem o conteúdo com muito apoio; as lições 4–9 aplicam, sempre com alguma intercalação; as lições 10–11 fazem a revisão cumulativa; a lição 12 é o chefe da trilha ("Mão na Massa"), um projeto completo que só usa conceitos já liberados.

**Restrição "só o que já foi estudado":** marque cada exercício com os slugs de conceito (padrão Exercism) e publique apenas se todas as marcas estiverem no fecho de pré-requisitos das trilhas concluídas.

### 4.3 Banco de ideias de DIGITAÇÃO (1–8 linhas; compilado em `t_digitacao.cs`, `web/t_web.cs` e `testes/t_testes.cs`)

**Iniciante** (símbolos: `; " ( ) { } $ = + ++ == <=`)
```csharp
Console.WriteLine("Olá, PAC·C#!");
string nome = "Ana";
int idade = 17;
Console.WriteLine($"{nome} tem {idade} anos.");
string status = idade >= 18 ? "adulto" : "menor";
decimal preco = 19.90m;
decimal total = preco * 3;
Console.WriteLine($"Total: {total:C}");            // Total: R$ 59,70
Console.WriteLine($"{"Item",-10}{"Qtd",5}");
int dado = Random.Shared.Next(1, 7);
string[] partes = "a;b;c".Split(';');
```
```csharp
for (int i = 1; i <= 10; i++)
{
    Console.WriteLine($"{i} x 7 = {i * 7}");
}
```
```csharp
if (int.TryParse(Console.ReadLine(), out int numero))
{
    Console.WriteLine(numero * 2);
}
```
Também servem: `foreach (int nota in notas) { ... }`; `while (tentativas < 3) { tentativas++; }`; um `switch (opcao)` com `case 1:` ... `break;` e `default:`; `try { int x = int.Parse(texto); } catch (FormatException) { ... }`; `static int Dobro(int n) => n * 2;`; `static double Media(double a, double b) { return (a + b) / 2; }`.

**Intermediário** (símbolos: `=> ?. ?? <T> { get; } [] with`)
```csharp
public class Jogador
{
    public string Nome { get; }
    public int Pontos { get; private set; }
    public Jogador(string nome) => Nome = nome;
    public void Marcar(int valor) => Pontos += valor;
}
```
```csharp
// cada linha é um exercício independente (as variáveis de contexto vêm da lição)
public record Produto(string Nome, decimal Preco);
var caro = produto with { Preco = produto.Preco * 1.1m };
var aprovados = alunos.Where(a => a.Nota >= 7).OrderBy(a => a.Nome).ToList();
int tamanho = apelido?.Length ?? 0;
Func<int, int> quadrado = x => x * x;
if (forma is Circulo { Raio: > 10 } c) Console.WriteLine($"Círculo grande: {c.Raio}");
[Flags] enum Permissao { Nenhuma = 0, Ler = 1, Escrever = 2, Executar = 4 }
```
```csharp
public static string Classificar(int nota) => nota switch
{
    >= 9 => "A",
    >= 7 => "B",
    _ => "C"
};
public static T Maior<T>(T a, T b) where T : IComparable<T>
    => a.CompareTo(b) >= 0 ? a : b;
```
Também servem: `public abstract class Inimigo { public abstract int Atacar(); public virtual string Grito() => "Grr!"; }`; `public event EventHandler? Morreu; protected void AoMorrer() => Morreu?.Invoke(this, EventArgs.Empty);`; `var sb = new StringBuilder(); foreach (var linha in linhas) sb.AppendLine(linha.Trim());`; `using var leitor = new StreamReader(caminho);`; `public class SaldoInsuficienteException(decimal falta) : Exception($"Faltam {falta:C}");`; `var (min, max) = (numeros.Min(), numeros.Max());`.

**Avançado** (símbolos: `async await Task<T> yield ref ^ .. operator`)
```csharp
var tarefas = ids.Select(id => BuscarAsync(id));
var resultados = await Task.WhenAll(tarefas);
await foreach (var item in LerLinhasAsync())
    Console.WriteLine(item);
```
```csharp
public static IEnumerable<int> Pares(int limite)
{
    for (int i = 0; i <= limite; i += 2)
        yield return i;
}
```
```csharp
private readonly Lock _trava = new();
public void Somar(int v)
{
    lock (_trava) { _total += v; }
    Interlocked.Increment(ref _contador);
}
```
Também servem: `public class Clima(HttpClient http) { public Task<string> ObterAsync(string cidade, CancellationToken ct) => http.GetStringAsync($"/clima/{cidade}", ct); }`; `ReadOnlySpan<char> texto = "2026-09-27"; int ano = int.Parse(texto[..4]);`; `public static Vetor operator +(Vetor a, Vetor b) => new(a.X + b.X, a.Y + b.Y);`; `public bool Equals(Moeda? outra) => outra is not null && Codigo == outra.Codigo;` com `GetHashCode`; `string json = JsonSerializer.Serialize(pedido, AppJson.Default.PedidoDto);` com o source generator `[JsonSerializable(typeof(PedidoDto))] internal partial class AppJson : JsonSerializerContext;`; a propriedade com `field` e o bloco `extension(string texto)` do §2.14 (C# 14).

**Sênior** (compilado com `#:sdk Microsoft.NET.Sdk.Web`, EF Core InMemory e xUnit)
```csharp
// trechos do Program.cs (builder/app vêm do template da minimal API)
builder.Services.AddScoped<IPedidoRepositorio, PedidoRepositorio>();
builder.Services.AddSingleton(TimeProvider.System);
app.MapGet("/pedidos/{id:int}", async (int id, IPedidoRepositorio repo, CancellationToken ct) =>
    await repo.ObterAsync(id, ct) is { } p ? Results.Ok(p) : Results.NotFound());
```
```csharp
public void Adicionar(Item item)
{
    if (Status != StatusPedido.Aberto) throw new InvalidOperationException("Pedido fechado");
    _itens.Add(item);
}
public IReadOnlyCollection<Item> Itens => _itens.AsReadOnly();
```
```csharp
[Theory]
[InlineData(2, 3, 5)]
[InlineData(-1, 1, 0)]
public void Somar_DoisNumeros_RetornaSoma(int a, int b, int esperado)
    => Assert.Equal(esperado, Calculadora.Somar(a, b));
```
Também servem: `public sealed record CriarPedidoCommand(Guid ClienteId, IReadOnlyList<ItemDto> Itens);`; `Task<Pedido?> ObterAsync(int id, CancellationToken ct = default);`; `db.Pedidos.Include(p => p.Itens).AsNoTracking().FirstOrDefaultAsync(p => p.Id == id, ct)`; `modelBuilder.Entity<Pedido>().OwnsOne(p => p.Endereco);`; a sequência `app.UseExceptionHandler(); app.UseHttpsRedirection(); app.UseAuthentication(); app.UseAuthorization();`.

**Jogos:** C# puro (compilado); os blocos de Unity, Godot e MonoGame **não foram compilados aqui** e devem ser validados no motor.
```csharp
// cada item é um exercício independente
hp = Math.Clamp(hp - dano, 0, hpMax);
posicao += velocidade * (float)deltaTime;          // System.Numerics.Vector2
bool Colide(Retangulo a, Retangulo b) =>
    a.X < b.X + b.L && a.X + a.L > b.X &&
    a.Y < b.Y + b.A && a.Y + a.A > b.Y;
```
```csharp
public class Jogador : MonoBehaviour                // Unity (Input Manager legado; conferir Input System)
{
    [SerializeField] private float velocidade = 5f;
    void Update()
    {
        float h = Input.GetAxis("Horizontal");
        transform.Translate(h * velocidade * Time.deltaTime, 0f, 0f);
    }
}
```
```csharp
public partial class Jogador : CharacterBody2D      // Godot 4 C#
{
    [Export] public float Velocidade { get; set; } = 200f;
    public override void _PhysicsProcess(double delta)
    {
        Velocity = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down") * Velocidade;
        MoveAndSlide();
    }
}
```
MonoGame: `protected override void Update(GameTime gameTime) { float dt = (float)gameTime.ElapsedGameTime.TotalSeconds; _posicao.X += _velocidade * dt; base.Update(gameTime); }`.

### 4.4 Banco de DESAFIOS DE LÓGICA (não são de digitação; respostas verificadas)

Legenda: **P** = prever a saída · **V** = valor final · **L** = lacuna · **O** = ordenar · **B** = achar o bug · **C** = escolha conceitual. Saídas em cultura pt-BR.

**Iniciante** (só T01–T14)
- P `Console.WriteLine(7 / 2);` → **3**. Distratores: 3,5 · 4 · erro.
- P `Console.WriteLine(7 / 2.0);` → **3,5** (em pt-BR; em invariante, `3.5`).
- P `Console.WriteLine(1 + 2 + "3"); Console.WriteLine("1" + 2 + 3);` → **33** e **123**.
- P `string s = "pac"; s.ToUpper(); Console.WriteLine(s);` → **pac**.
- P `for (int i = 0; i < 5; i += 2) Console.Write(i);` → **024**.
- P `int i = 10; while (i > 0) { i -= 3; } Console.WriteLine(i);` → **-2**.
- P `int x = 5; Console.WriteLine(x++); Console.WriteLine(++x);` → **5** e **7**.
- P `Console.WriteLine('a' + 1);` → **98**; `(char)('a' + 1)` → **b**.
- P `Console.WriteLine((int)3.99 + " " + (int)-3.99);` → **3 -3**.
- P `Math.Round(2.5)` e `Math.Round(3.5)` → **2** e **4** (ToEven).
- P `Console.WriteLine(-7 % 3);` → **-1**. `Console.WriteLine(0.1 + 0.2 == 0.3);` → **False**.
- P `"banana".IndexOf('n')` → **2**; `"banana".LastIndexOf('a')` → **5**; `$"{"Pac",-6}|{42,5}|"` → `Pac   |   42|`.
- P `string nome = "Ana"; Console.WriteLine($"{nome.Length} {nome[0]} {nome[^1]}");` → **3 A a**.
- P Um `for` de 1 a 3 com um `for` interno de 1 a `i` imprimindo `*` → `*`, `**`, `***`.
- P `int c = 0; for (int i = 0; i < 10; i++) { if (i % 3 == 0) continue; if (i == 8) break; c++; }` → **5**.
- P `int nota = 72; ... nota >= 90 ? "A" : nota >= 70 ? "B" : "C"` → **B**.
- V `int x = 5; x += 3; x *= 2; x--;` → **15** · `int a = 10; int b = a; b = 20;` → a = **10** · `int t = 0; for (int i = 1; i <= 4; i++) t += i;` → **10** · `int n = 0; do { n += 2; } while (n < 7);` → **8** · `bool ok = int.TryParse("12a", out int v);` → **False, 0** · `int x = 5; x += x++;` → **10** · `int i = 5; int j = i++ + ++i;` → **i = 7, j = 12**.
- L `foreach (int nota ___ notas)` → `in` · `int.TryParse(texto, ___ int numero)` → `out` · `decimal preco = 19.90___;` → `m` · `$"Total: {total___}"` (moeda) → `:C` · `for (int i = 0; i ___ v.Length; i++)` → `<` · `case 1: ...; ___;` → `break`.
- O "Média de notas", na ordem certa: `int[] notas = { 7, 8, 9 };` / `int soma = 0;` / `foreach (int n in notas)` / `{` / `soma += n;` / `}` / `double media = (double)soma / notas.Length;` / `Console.WriteLine($"Média: {media:F1}");`. Distrator pareado: **`double media = soma / notas.Length;`** (divisão inteira). Outros dois: "ler número com `TryParse`" e "laço de adivinhação com `while` + `break`".
- B `int dado = Random.Shared.Next(1, 6);` nunca sorteia 6 (em 10.000 sorteios, verificado: de 1 a 5) → `Next(1, 7)`.
- B `for (int i = 0; i <= arr.Length; i++)` → `IndexOutOfRangeException`.
- B `if (x = 5)` → **CS0029** (int não converte para bool). `int total; Console.WriteLine(total);` → **CS0165**.
- B `case 1:` sem `break` antes do `case 2:` → **CS0163**. Um método que não retorna em todos os caminhos → **CS0161**. `string nome = 42;` → **CS0029**. `int n = 3.7;` → **CS0266**.
- B `double media = soma / qtd;` com `int`s → 7 em vez de 7,67.
- C Qual tipo para dinheiro? **decimal**. Quando usar `Parse` e quando usar `TryParse`? Um `break` num `for` aninhado sai de qual laço? **Só do interno.**

**Intermediário** (até T28)
- P struct × class: `p2 = p1; p2.X = 99` e `c2 = c1; c2.X = 99` → **1 99**.
- P `var a = new List<int>{1}; var b = a; b.Add(2); a.Count` → **2**.
- P `Inc(n)` seguido de `IncRef(ref n)` com n = 1 → **2**. `Zera(v)` seguido de `Troca(v)` → **0,2,3**.
- P `Animal a = new Gato();` com `new` em `Som()` → **...**. Com `override` → **au**. Construtores `Pai`/`Filho` → **Pai Filho**.
- P `try { Write("A"); throw ...; } catch { Write("C"); } finally { Write("F"); }` → **ACF**. `finally` depois de `return x;` → **1**.
- P `nums.Where(x => x % 2 == 0).Select(x => x * x).Sum()` com {1..6} → **56**. A consulta adiada que vê o `Add(4)` → **3**.
- P `r1 == r2` (record) e `c1 == c2` (class) → **True False**. `object a = 1, b = 1; a == b` → **False**; `a.Equals(b)` → **True**.
- P `int? a = null; int? c = a + 5; c.HasValue` → **False**. `apelido ??= "Pac"; apelido ??= "Outro";` → **Pac**.
- P `(Permissao.Ler | Permissao.Escrever).ToString()` → **Ler, Escrever**, e `(int)` → **3**. `(int)Dia.Terca` (enum Segunda, Terca, Quarta) → **1**.
- P Pilha com push 1, 2, 3, depois `Pop()` e `Peek()`; fila com enqueue 1, 2, 3, depois `Dequeue()` e `Peek()` → **3 2 1 2**. `HashSet.Add` do mesmo item 2 vezes → **True False** (Count 1).
- P `int[] v = {10,20,30,40,50};` → `v[^2]` = **40**; `v[1..3]` = **20,30**; `v[1..^1]` = **20,30,40**.
- P Um método com `yield` que imprime `[início]` e `(gera i)`, mais `Take(2)` → `[antes] [início] (gera 1) <1> (gera 2) <2>` (`[fim]` nunca aparece).
- V `estoque["maçã"]++` (era 3), `estoque["pera"] = 1; estoque["pera"] = 5;` → **4, 5, Count 2** · `(a, b) = (b, a)` → **a = 2, b = 1** · `StringBuilder` com `"0-1-2-"` e `sb.Length--` → **0-1-2** · 3 × `new Inimigo()` com contador `static` → **3**.
- L `public string Nome { get; ___; }` (imutável depois de criar) → `init` · `produto ___ { Preco = 110m }` → `with` · `apelido___Length ?? 0` → `?.` · `Maior<T>(T a, T b) ___ T : IComparable<T>` → `where` · `catch (SaldoInsuficienteException e) ___ (e.Falta > 10)` → `when` · `lista.___(n => n.Vida <= 0)` → `RemoveAll`.
- O A classe `Jogador`: campo, construtor, propriedade, método, com o distrator `public int Pontos { get; set; }` contra `private set`. O pipeline LINQ `Where → OrderBy → Select → ToList`. O bloco `using` + `try`/`catch` de leitura de arquivo.
- B `foreach (var n in lista) if (n == 2) lista.Remove(n);` → `InvalidOperationException`; corrigir com `RemoveAll`.
- B `pontos[0].X = 5` com `List<struct>` → **CS1612**. `n = n * 2` dentro de `foreach` → **CS1656**. `c.Nome = "b"` com `init` → **CS8852**. `new Usuario()` sem o membro `required` → **CS9035**.
- B `estoque["uva"]` sem checar → `KeyNotFoundException`. `Equals` sobrescrito sem `GetHashCode` → `ContainsKey` devolve **False** (verificado).
- B Uma lambda no `for` que captura `i` imprime **333**. Correção: `int copia = i;` ou `foreach`.
- C struct, class ou record para `Ponto2D` imutável? (**readonly record struct**) · Para "já visitei esta sala?", qual coleção? (**HashSet**) · Interface ou classe abstrata? · Um método que devolve `IEnumerable` executa quando?

**Avançado** (até T38)
- P A ordem de `async`: A, B, C, `await`, D, E → **ABCDE**. `WhenAll(Dobro(1), Dobro(2), Dobro(3))` com atrasos invertidos → **2,4,6**.
- P `using var a` e `using var b` no mesmo bloco → **usa fecha-b fecha-a**.
- P Um `Select` com contador, seguido de `Sum()` e `Count()` → contador = **6**.
- P A base chama um virtual no construtor e a derivada tem o campo `_nome = "D"` → **BDC**.
- P Evento inscrito 2×, `Clicar()`, `-=` 1×, `Clicar()` → **3**. `Func` multicast `n+1` e `n*10` com 5 → **50**.
- P `Lazy<string>`: `IsValueCreated`, `Value`, `Value`, `IsValueCreated` → **False [criando] valor valor True**.
- P Struct `IIncrementavel` incrementada 2× através da interface → original **0**, caixa **2**.
- P `double.Parse("3.5", new CultureInfo("pt-BR"))` → **35**. `new Vector2(1.5f, 0f)` impresso em pt-BR → `<1,5. 0>`.
- P `PriorityQueue` com goblin(3), dragão(1), slime(5) → **dragão goblin slime**. Com prioridade negativa para ordenar por iniciativa descendente (Pac 15, Fantasma 12, Cereja 20) → **Cereja Pac Fantasma**.
- P `checked(int.MaxValue + x)` → `OverflowException`. `byte b = 255; b++` → **0**. `double.NaN == double.NaN` → **False**.
- P `Task.Delay(1000, tokenCancelado)` → **TaskCanceledException**. `object[] arr = new string[1]; arr[0] = 1;` → **ArrayTypeMismatchException**.
- P Somar `0.1` dez vezes e comparar `== 1.0` → **False** (`0.9999999999999999`).
- V `int k = 0; Par(k++, k++, k)` → **"0,1,2"** (argumentos avaliados da esquerda para a direita) · `Span<int> s = stackalloc int[] {5,6,7,8}; s[1..3].Fill(0);` → **5,0,0,8** · `Func<int> proximo = () => ++contador;` chamado 2× e depois consultado → **2**; a terceira chamada devolve **3**.
- L `public async ___<int> ContarAsync()` → `Task` · `await ___ (var linha in LerAsync())` → `foreach` · `Task.Delay(1000, cts.___)` → `Token` · `where T : ___<T>` → `INumber` · `private readonly ___ _trava = new();` → `Lock` (.NET 9+) · `throw___` (preservar o stack) → `throw;`.
- O Um método async com `try`/`catch (OperationCanceledException)`/`finally`, propagando o `ct`. O padrão `IDisposable` com `using`.
- B `async void Salvar()` → não dá para aguardar nem capturar a exceção; trocar por `async Task`. `.Result` num contexto de UI → deadlock. `new HttpClient()` por chamada → esgota os sockets.
- B `total++` em `Parallel.For` sem sincronização → resultado menor; corrigir com `Interlocked.Increment` ou `lock`. `catch (Exception ex) { throw ex; }` → perde o stack trace.
- B `JsonSerializer.Serialize(obj)` num file-based app → `InvalidOperationException` (AOT; verificado). `DateTime.Now` dentro da regra testada → teste frágil; injetar `TimeProvider`.
- C `Task` × `Thread`; `IEnumerable` × `IAsyncEnumerable`; quando `Span<T>` compensa; `ConfigureAwait(false)` em bibliotecas; qual complexidade tem `List.Contains` e qual tem `HashSet.Contains`.

**Sênior** (até T44)
- P Decorator `new Log(new Maiusculas(new Console2()))` chamado com `Enviar("oi")` → **log>[OI]**. Pipeline de middlewares A e B em volta de `ToUpper` → **A(B(REQ))**.
- P Strategy: total 100 com frete expresso (25) e depois grátis → **125 100**. Specification `ativo.And(vip)` → só **Ana**.
- P Tempos de vida de DI: transient igual? **False**; scoped no mesmo escopo? **True**; em outro escopo? **False**; singleton? **True**.
- P `ValidateOnBuild` com um singleton que depende de scoped → `AggregateException` com "Cannot consume scoped service 'Contexto' from singleton 'Cache'".
- O Ordem dos middlewares (docs ASP.NET Core): `UseExceptionHandler` → `UseHsts` → `UseHttpsRedirection` → `UseStaticFiles` → `UseRouting` → `UseCors` → `UseAuthentication` → `UseAuthorization` → `Map...`.
- O Camadas da Clean Architecture, de dentro para fora: Entidades/Domínio → Aplicação (casos de uso, interfaces) → Infraestrutura e UI.
- O Fluxo de um comando CQRS: endpoint → validação → handler → agregado aplica a regra → repositório → `SaveChanges` → evento de domínio publicado.
- B Um singleton recebe o `DbContext` → dependência cativa. `foreach (var p in db.Pedidos.ToList()) Console.WriteLine(p.Itens.Count);` com lazy loading → N+1; resolver com `Include` ou projeção. Uma entidade com `set` público quebra a invariante; usar métodos de domínio com `private set`. `Assert.Equals` no xUnit → **CS0619**.
- C SOLID violado:
  - Uma classe que calcula, formata e envia e-mail viola o **SRP**.
  - Uma cadeia de `if (tipo == "pix") ... else if (tipo == "boleto")` que só cresce viola o **OCP** (resolve-se com Strategy).
  - `Pinguim : Ave` com um `Voar()` que lança exceção viola o **LSP**.
  - Uma interface com 20 métodos viola o **ISP**.
  - Um serviço que faz `new SqlRepositorio()` viola o **DIP**.
- C Entidade ou VO? `Email`, `Dinheiro` e `Endereco` são **VO**; `Cliente` é **entidade**. Command ou query? `CancelarPedido` e `AplicarCupom` são commands; `ObterPedido` e `ListarPedidos` são queries. Quando **não** usar microsserviços? Consumidor *at-least-once* precisa de quê? (**idempotência**)

**Jogos** (em todas as trilhas, respeitando os conceitos já liberados)
- P `Math.Clamp(30 - 45, 0, 100)` → **0**. Cura +250 com máximo 100 → **100**. `Envolver(12)` e `Envolver(-1)` com largura 10 → **2 9**, enquanto `-1 % 10` → **-1**.
- P Em uma grade 5×5 a partir de (0,0), os comandos D, D, B, E, C, C com clamp → **(1, 0)**. AABB (0,0,10,10) × (5,5,10,10) → **True**; × (10,0,5,5) → **False**.
- P Combo `true, true, false, true, true, true` valendo 10 × min(combo, 3) → **90**, com combo final 3.
- P Máquina de estados com andar, pular, pousar, parar, pular → **Pulando**. `new Random(42)` duas vezes gera sequências iguais? **True**.
- P Labirinto BFS (`S.#.` / `..#.` / `....` / `#..E`) → **6** passos. Dano `Max(1, atk - def)` com crítico ×2: (10, 4) → **6**; crítico → **16**; (3, 8) → **1**.
- P Inimigos slime 5, orc 12 e rato 2 levam 5 de dano e passam por `RemoveAll(vida <= 0)` → removidos **2**, resta **orc**. Top-3 de `{120,450,300,450,80}` → **450,450,300**.
- B Movimento `x += velocidade;` sem `deltaTime`. `new Random(42)` recriado a cada frame. `Next(1, 6)` num d6. Remover inimigo dentro do `foreach`. Comparar `float` com `==`. Física no `Update` (Unity) em vez de `FixedUpdate`.
- O Ordem do ciclo de vida na Unity: Awake → OnEnable → Start → FixedUpdate → Update → LateUpdate → OnDisable → OnDestroy. MonoGame: construtor → Initialize → LoadContent → (Update → Draw)\*.
- C Qual padrão usar para desfazer comandos e fazer replay? (**Command**) Para reciclar balas? (**Object Pool**) Para o HUD reagir à vida? (**Observer**/evento) Para a IA com estados? (**State**)

### 4.5 Como calibrar a dificuldade

**Escalas externas mapeadas para os níveis do PAC·C#:**

| Nível | Codewars | Exercism | LeetCode |
|---|---|---|---|
| Iniciante | 8–7 kyu | 1–3 | — |
| Intermediário | 6–5 kyu | 3–5 | Easy |
| Avançado | 4–3 kyu | 5–7 | Medium |
| Sênior | 2–1 kyu | 8–10 | Hard + design |

**Botões por formato.** Suba **um** por vez.

| Formato | Botões |
|---|---|
| Prever / valor final | Linhas (3 → 12), variáveis vivas (1 → 4), iterações a rastrear (≤ 3 → ≤ 10), aninhamento (0 → 2), armadilhas semânticas (0 → 1 no iniciante, até 2 depois), tipo de resposta (múltipla escolha → digitada) |
| Parsons | Blocos (4–6 → 7–10 → 10–15); distratores (nenhum → pareados → soltos); indentação dada (1D) ou exigida (2D); solução **única** e idiomática; feedback por linha |
| Lacuna | Buracos (1 → 3); o que falta (palavra-chave → operador → expressão → linha); com ou sem banco de palavras |
| Achar o bug | Tipo (compilação CSxxxx → exceção → lógica/off-by-one → semântica de referência/closure/async → cheiro de design); linhas a inspecionar (≤ 5 → ≤ 20); dica de saída esperada ou teste que falha |
| Digitação | Tamanho em caracteres; **densidade de símbolos** (proporção de `{}()[];<>=?.$"@`); tokens raros (`??=`, `=>`, `<T>`, `^1`); profundidade de indentação. Exija ≥ 95% de precisão antes de cobrar velocidade e meça os símbolos separadamente. |

**Regras de adaptação:**
- **Alvo:** ~70–85% de acerto na primeira tentativa. Com ≥ 90% em dois blocos seguidos, suba um botão ou pule o exemplo resolvido (reversão da expertise). Abaixo de 60%, desça um botão e mostre um worked example com subobjetivos.
- **Dicas em escada** (linha suspeita → nome do conceito → exemplo parecido), descontadas da pontuação.
- **Distratores** vêm de concepções erradas conhecidas: 7/2 = 3,5, "a string mudou", aliasing esquecido, `<=` no laço, `==` em referência, closure no `for`, "o async roda em paralelo".
- **Intercalação:** 20–30% dos itens de cada lição vêm de trilhas anteriores. Priorize os pares confundíveis e os erros recentes do próprio aluno.
- **Revisão espaçada (Leitner):** acertou, o item sobe de caixa; errou, volta para a caixa 1. Intervalos sugeridos: 1, 3, 7, 16 e 35 dias. Itens acertados continuam voltando.
- **Determinismo:** "prever a saída" só com código determinístico. Evite ordem de `Dictionary`/`HashSet`, `GetHashCode`, `Random` sem semente, threads, `DateTime.Now`, formatação de ponto flutuante em casos de borda (`2.675.ToString("F2")` → `2.67`, mas `Math.Round(2.675, 2)` → `2.68`) e cultura não declarada.

### 4.6 Checklist para os geradores de exercício

1. O código compila no .NET 10. Se não usar recurso de C# 14, compila também no .NET 9. Rodar para capturar a saída real e **nunca** escrever a saída "de cabeça".
2. Declarar a cultura (pt-BR ou invariante) sempre que houver decimal, data ou moeda.
3. Não copiar enunciados do Exercism, Codewars ou LeetCode: servem só para conferir cobertura. Usar contexto brasileiro (Pix, CPF, feira, futebol, fliperama).
4. Estilo .NET: PascalCase para tipos, métodos e propriedades; camelCase para locais e parâmetros; `_camelCase` para campos privados; chaves em linha própria; 4 espaços; `var` quando o tipo é óbvio. Identificadores sem acento.
5. Marcar cada exercício com os conceitos que usa e publicar só se todos já estiverem liberados.
6. Parsons com uma única ordem válida, ou um verificador que execute a solução. Os distratores são pareados e plausíveis.
7. "Achar o bug": um bug por exercício no iniciante e no intermediário, com código CSxxxx real quando for erro de compilação.
8. Tema de jogo em ~30% dos desafios, sem exigir API de motor antes de T47–T48.

## 5. URLs consultadas

**Syllabus e plataformas**
- https://github.com/exercism/csharp/blob/main/config.json (e o raw https://raw.githubusercontent.com/exercism/csharp/main/config.json)
- https://github.com/exercism/csharp/tree/main/concepts, com os `about.md` de basics, strings, nullability, equality, floating-point-numbers, integral-numbers, overflow, casting, string-formatting, structs, resource-cleanup, resource-lifetime, randomness, datetimes, lambdas, enumerables, interfaces, inheritance e outros
- https://github.com/exercism/docs/blob/main/building/tracks/concept-exercises.md · https://github.com/exercism/docs/blob/main/building/tracks/config-json.md · https://exercism.org/tracks/csharp/concepts (403 para robôs)
- https://learn.microsoft.com/en-us/training/paths/get-started-c-sharp-part-1/ (e part-2 a part-6)
- https://www.freecodecamp.org/learn/foundational-c-sharp-with-microsoft/ · https://www.freecodecamp.org/news/free-microsoft-c-sharp-certification · https://devblogs.microsoft.com/dotnet/announcing-foundational-csharp-certification/
- https://docs.codewars.com/gamification/ranks/ · https://docs.codewars.com/curation/references/kata-ranks/ · https://docs.codewars.com/languages/csharp/ · https://www.codewars.com/collections/8-kyu-beginner-katas
- https://leetcode.com/studyplan/leetcode-75/ (403; categorias confirmadas por busca) · https://www.techinterviewhandbook.org/best-practice-questions/
- https://www.hackerrank.com/domains/tutorials/30-days-of-code · https://github.com/xeoneux/30-Days-of-Code

**Documentação da linguagem e do .NET**
- https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-13 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15
- https://learn.microsoft.com/en-us/dotnet/core/sdk/file-based-apps · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/file-based-programs
- https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.priorityqueue-2?view=net-10.0
- https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/ · https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices · https://learn.microsoft.com/en-us/ef/core/
- https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles · https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures · https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/
- Índice da documentação de C# (fundamentals, patterns, LINQ, async, iterators, advanced topics): https://learn.microsoft.com/en-us/dotnet/csharp/

**Livros, cursos e jogos**
- https://www.manning.com/books/c-sharp-in-depth-fourth-edition · https://www.albahari.com/nutshell/ · https://www.springerprofessional.de/en/pro-c-10-with-net-6/23321652
- https://csharpplayersguide.com/solutions/5th-edition/ · https://dometrain.com/courses/ · https://dometrain.com/course/deep-dive-csharp/ · https://www.csharpmastercourse.com/ · https://www.freecodecamp.org/news/c-sharp-24-hour-course/
- https://refactoring.guru/design-patterns/csharp · https://gameprogrammingpatterns.com/contents.html
- https://docs.unity3d.com/Manual/execution-order.html · https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html · https://docs.monogame.net/articles/getting_started/index.html · https://docs.monogame.net/articles/tutorials/building_2d_games/03_the_game1_file/index.html

**Pesquisa pedagógica**
- Ericson, Margulieux & Rick 2017: https://dl.acm.org/doi/10.1145/3141880.3141895 (PDF lido: http://faculty.chas.uni.edu/~schafer/cohort23/Methods/ReadingsBackups/mod2/ParsonsProblems.pdf)
- Ericson et al. 2022, ITiCSE-WGR: https://dl.acm.org/doi/10.1145/3571785.3574127 (PDF lido: https://juholeinonen.com/assets/pdf/ericson2022parsons.pdf) · Du, Luxton-Reilly & Denny 2020: https://dblp.org/rec/conf/ace/DuLD20.html
- Xie et al. 2019: https://doi.org/10.1080/08993408.2019.1565235 (PDF lido: https://rob.co.bb/a-theory-of-instruction-for-introductory-programming-skills-xie-2019.pdf)
- Lister et al. 2004: https://cseweb.ucsd.edu//~bsimon/pubs/abstracts/iticse2004wg.html · Lopez et al. 2008: https://dl.acm.org/doi/10.1145/1404520.1404531 · Lister et al. 2006 (SOLO): https://research.aston.ac.uk/en/publications/not-seeing-the-forest-for-the-trees-novice-programmers-and-the-so/ · EiPE: https://dl.acm.org/doi/10.1145/2538862.2538911
- PRIMM: https://teachcomputing.org/blog/using-primm-to-structure-programming-lessons/ · https://computingeducationresearch.org/projects/primm/
- Margulieux, Catrambone & Guzdial 2016: https://bpb-us-e1.wpmucdn.com/sites.gatech.edu/dist/b/1555/files/2020/09/MargulieuxCatramboneGuzdial2016.pdf
- van Merriënboer 1990: https://eric.ed.gov/?id=EJ417022 · 4C/ID: https://edutechwiki.unige.ch/en/4C-ID · Fading (Renkl & Atkinson): https://link.springer.com/article/10.1023/B:TRUC.0000021815.74806.f6 (via busca)
- Reversão da expertise: https://en.wikipedia.org/wiki/Expertise_reversal_effect · Debugging (McCauley et al. 2008): https://eric.ed.gov/?id=EJ810214 · Concepções erradas (Qian & Lehman 2017): https://dl.acm.org/doi/10.1145/3077618 (via busca)
- Recuperação: https://learninglab.psych.purdue.edu/downloads/2007/2007_Karpicke_Roediger_JML.pdf · https://journals.sagepub.com/doi/10.1111/j.1467-9280.2006.01693.x (via busca) · Espaçamento: https://eric.ed.gov/?id=ED505660 · Dunlosky et al.: https://www.aft.org/ae/fall2013/dunlosky
- Intercalação: https://files.eric.ed.gov/fulltext/ED557355.pdf · Regra dos 85%: https://www.nature.com/articles/s41467-019-12552-4 · https://www.sciencedaily.com/releases/2019/11/191105113457.htm
- Latência de teclas: https://dl.acm.org/doi/abs/10.5555/1082424.1082440 (via busca) · https://www.frontiersin.org/journals/computer-science/articles/10.3389/fcomp.2024.1412458/full · Leitner: https://en.wikipedia.org/wiki/Leitner_system
