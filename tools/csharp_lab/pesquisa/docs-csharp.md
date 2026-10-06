# Dossiê `docs-csharp` — Documentação oficial de C# (learn.microsoft.com)

> Frente de pesquisa **docs-csharp** para o PAC·C#. Pesquisa feita em **27/09/2026** abrindo as páginas oficiais
> (WebFetch) e o sumário oficial da seção (`/dotnet/csharp/toc.json` e `/dotnet/csharp/language-reference/toc.json`).
> Os exemplos de código são **nossos** (identificadores em pt-BR) e foram **compilados e executados** com o
> **.NET SDK 10.0.102 (C# 14)** como *file-based apps* (`dotnet run arquivo.cs`) — arquivos de prova em
> `scratchpad/csharp/pesquisa/verificacao/` (t01…t10 + 25 casos de erro em `erros/`). Exceção: seção 2.24 (C# 15,
> prévia) segue a sintaxe da doc, mas não foi executada (exige SDK .NET 11 preview).

## 0. Contexto de versões e convenções para os geradores

- **Estado em set/2026**: C# 14 é a versão estável (lançada nov/2025 com o **.NET 10**, LTS com suporte até
  **10/11/2028**, e Visual Studio 2026). C# 13 ↔ .NET 9 · C# 12 ↔ .NET 8 — **.NET 8 e .NET 9 saem de suporte em
  10/11/2026** (blog oficial de 29/06/2026 recomenda migrar para o .NET 10). **C# 15 está em prévia** (.NET 11 preview;
  página "What's new in C# 15" atualizada em 11/09/2026). O "What's new" do hub já aponta para C# 15.
- A versão da linguagem segue o TFM (`net10.0` → C# 14; `net9.0` → C# 13). A doc **desaconselha**
  `<LangVersion>latest</LangVersion>` (build instável entre máquinas); `preview` só para experimentar; usar versão
  mais nova que a do TFM "não é suportado".
- **Alvo do curso: C# 14 / .NET 10.** Marcar cada lição/exercício com a versão mínima quando usar recurso novo
  (C# 12 → .NET 8+, C# 13 → .NET 9+, C# 14 → .NET 10+). File-based apps (`dotnet app.cs`) exigem **SDK .NET 10**.
  C# 15 só numa lição "Prévia", com aviso de `LangVersion preview`.
- **Estilo moderno que a própria doc usa** (e o curso deve imitar): top-level statements; tutoriais iniciantes como
  file-based apps; `ImplicitUsings` e `<Nullable>enable</Nullable>` ligados; collection expressions `[...]`; raw strings
  `"""`; records para dados; `is null` / `is not null`; file-scoped namespace; `required`/`init`; `var` só se óbvio.
- **Implicit usings (console)**: `System`, `System.Collections.Generic`, `System.IO`, `System.Linq`, `System.Threading`,
  `System.Threading.Tasks` (+`System.Net.Http`). **Não** incluem `System.Text` (StringBuilder), `System.Numerics`
  (INumber<T>), `System.Globalization`, `System.Reflection`, `System.Linq.Expressions`, `System.Drawing`,
  `System.Diagnostics` → o exercício precisa do `using` ou do nome qualificado.
- **Ordem num arquivo com top-level statements**: diretivas `#!`/`#:` → `using` → instruções (funções locais podem ficar
  no meio) → **tipos e namespaces por último** (senão **CS8803**).
- **Cultura — crítico para público BR**: `Console.WriteLine(3.5)`, `{x:F2}`, `{x:N0}`, `{x:C}` e datas usam
  `CultureInfo.CurrentCulture`. Verificado: `7 / 2.0` → `3.5` (en-US) × `3,5` (pt-BR); `{1500:N0}` → `1,500` × `1.500`;
  `1.0 / 0` → `∞` (en-US e pt-BR com ICU) × `Infinity` (cultura invariante; a doc mostra `Infinity`).
  **Convenção para "prever a saída"**: evitar imprimir fracionário/infinito; se inevitável, dizer no enunciado
  "considere cultura invariante (ponto decimal)" ou usar `string.Create(CultureInfo.InvariantCulture, $"...")`.
- **Identificadores**: C# aceita acentos em identificadores, mas para digitação preferir sem acento (`posicao`,
  `acao`) e deixar acentos em strings/comentários. Convenções da doc: PascalCase (tipos, métodos, membros públicos,
  constantes); camelCase (locais, parâmetros); `_campoPrivado`; `s_estaticoPrivado`; `t_threadStatic`; `I` em
  interfaces; `T`/`TAlgo` em genéricos; sufixo `Async`; atributos terminam em `Attribute`; enum singular (plural se
  `[Flags]`); parâmetro de primary constructor em camelCase (class/struct) e PascalCase (record).

## 1. Árvore de tópicos em ORDEM DIDÁTICA (nível · o que ensinar · fonte)

**Ordem macro que a própria Microsoft sugere** (hub `/dotnet/csharp/`, bloco "Learn to program"): *Get started* (Tour +
tutoriais) → *Fundamentals* (estrutura, tipos, null safety, strings, pattern matching, expressões/instruções, OOP,
funcional, exceções, estilo) → *Language concepts* (programming concepts, LINQ, async) → *Advanced language concepts*
(reflection/attributes, interface implementations, expression trees, native interop, performance, Roslyn SDK) →
*Reference* (language reference + especificação). Os tutoriais do Tour dizem: "Each lesson builds on the prior
lessons. You should do them in order." Legenda: **[INI]** iniciante · **[INT]** intermediário · **[AVA]** avançado ·
**[SEN]** sênior.

### A. Primeiros passos — Tour of C# (fazer em ordem)
1. [INI] Visão geral — família C, `;`, case-sensitive, compilada, fortemente tipada; Hello World em top-level e com `Main`; tour de pattern matching, collection expressions, índices/ranges, LINQ, async. https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/overview
2. [INI] O que dá para construir — web, desktop, mobile, nuvem, IoT, IA e **jogos (Unity, MonoGame, CryEngine)**. https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/what-you-can-build
3. [INI] Tutorial 1 · Hello world e texto — `Console.WriteLine`, variável `string`, `+`, `$"{x}"`, `Length`, `Trim*`, `Replace`, `ToUpper/ToLower`, `Contains`, `StartsWith/EndsWith`. https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/hello-world
4. [INI] Tutorial 2 · Números — `int`, **divisão inteira**, `%`, precedência, `int.MaxValue`, overflow que "dá a volta", `double` e arredondamento, `decimal` com `M`, `Math.PI`; organizar em métodos locais. https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/numbers-in-csharp
5. [INI] Tutorial 3 · Tuplas e tipos — `(X: 1, Y: 2)`, `with`, aridade; `record Point(int X, int Y)`, `record struct`; class (referência) × struct (valor); interface. https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/tuples-and-types
6. [INI] Tutorial 4 · Branches e loops — `if/else` com chaves, `&&`/`||`, `==`, `while`, `do-while`, `for`, laços aninhados; desafio "soma dos múltiplos de 3 entre 1 e 20" (= 63). https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/branches-and-loops
7. [INI] Tutorial 5 · Listas — `List<string>` com `[...]`, `foreach`, `Add/Remove`, `[i]`, `Count`, `IndexOf` (−1 se não achar), `Sort`; desafio Fibonacci (20º = 6765). https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/list-collection
8. [INI] Tutorial 6 · Pattern matching — `is "DEPOSIT"`, raw string, `TryParse(..., out ...)`, enum, `switch` expression exaustiva, `_`, subsunção (erro), type patterns com records. https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/pattern-matching
9. [INI] File-based apps (.NET 10) — `dotnet app.cs`, `#!`, `#:package Nome@ver`, `#:property`, `#:sdk`, `#:project` (`#:include` só SDK 10.0.300+/.NET 11), `args`, stdin, `dotnet project convert`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/file-based-programs · https://learn.microsoft.com/en-us/dotnet/core/sdk/file-based-apps
10. [INI] (opcional) Dicas para quem vem de Java / JavaScript / Python. https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tips-for-python-developers (e `tips-for-java-developers`, `tips-for-javascript-developers`)

### B. Estrutura do programa
11. [INI] Estrutura geral — file-based × project-based; top-level × `Main`; expressão (produz valor) × instrução (executa ação). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/
12. [INI] Top-level statements — um arquivo só; `args`; `await` e `return` definem a assinatura do `Main` implícito (`void`/`int`/`Task`/`Task<int>`); tipos depois das instruções. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/top-level-statements
13. [INI] `Main` e argumentos de linha de comando. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/main-command-line
14. [INI] Namespaces e `using` — file-scoped namespace, `global using`, implicit usings, `using static System.Math`, alias (C# 12: alias de qualquer tipo, ex. tupla). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/namespaces
15. [INT] Diretivas de pré-processador — `#if DEBUG`, `#region`, `#nullable`, `#pragma warning`, `#error version`. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/preprocessor-directives
16. [INT] Organização de programa (assemblies, projetos, `dotnet new/build/run`). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/program-organization

### C. Sistema de tipos
17. [INI] Visão geral — tipagem forte, `var`, valor × referência, CTS, tipo em compilação × execução, guia "qual tipo escolher" (tupla, struct/record struct, record class, class, interface, enum). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/
18. [INI] Tipos embutidos e literais — `int/long/short/byte`, `double/float(f)/decimal(m)`, `uint/ulong`, `nint`, `bool/char/string`, `0x`, `0b`, `_`, `1.5e6`, escapes, `default`, `var`, `new()` alvo, `dynamic` (evitar). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/built-in-types
19. [INI] Conversões, cast e boxing — implícita × explícita (trunca), `is`/`as`, boxing/unboxing, `Parse` × `TryParse`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/conversions
20. [INI] Classes — referência, construtores, primary constructor (C# 12), `required`, `init`, object initializer, `static class`, herança básica. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/classes
21. [INT] Structs — cópia na atribuição, construtor sem parâmetros × `default`, auto-default, `readonly struct`, membros `readonly`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/structs
22. [INI→INT] Records — posicional, `record class` × `record struct` × `readonly record struct`, igualdade por valor, `ToString`, `with`, desconstrução, herança entre records; evitar record como entidade EF Core. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/records
23. [INT] Interfaces — contrato, prefixo `I`, várias interfaces, implementação explícita, herança de interfaces, interface × classe abstrata, visão de membros padrão e `static abstract`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/interfaces
24. [INI] Enums — tipo subjacente, valores explícitos, `switch`, `[Flags]` + `HasFlag`, cast int↔enum (não valida!), `Enum.Parse/TryParse/IsDefined/GetValues<T>`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/enums
25. [INT] Generics — coleções genéricas, métodos genéricos com inferência, constraints (`class`, `struct`, `new()`, base, interface, `notnull`, `unmanaged`, `Enum`, `Delegate`), co/contravariância, classe genérica própria. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/generics · https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/generics/constraints-on-type-parameters
26. [INI] Tuplas e desconstrução — nomes inferidos, retorno múltiplo, `_`, `==` entre tuplas (nomes não contam), `with`, tupla como chave de dicionário. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/tuples · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/functional/deconstruct
27. [INT] Lambdas, delegates e eventos (intro) — `=>`, `delegate`, `Func`/`Action`, closure, `static` lambda, parâmetros `_`, `event EventHandler<T>`, `+=`/`-=`, `?.Invoke`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/delegates-lambdas
28. [INT] Tipos anônimos (e por que preferir tuplas). https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/anonymous-types

### D. Null safety
29. [INI] Visão geral — `NullReferenceException`; as 3 ferramentas: nullable value types, nullable reference types, operadores. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/
30. [INI] Nullable value types — `int?`, `HasValue`, `GetValueOrDefault(x)`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-value-types
31. [INT] Nullable reference types — `string?`, contexto `<Nullable>enable</Nullable>`/`#nullable`, estados *not-null*/*maybe-null*, `!`, `[NotNullWhen]`, armadilhas (struct `default`, arrays novos). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-reference-types
32. [INI] Operadores de null — `?.`, `?[]` (curto-circuito), `??`, `??=`, `is null`, `!`; atribuição null-condicional (C# 14). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/null-operators
33. [INT/AVA] Resolver avisos; tutorial de design com NRT; migração de projetos antigos. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/common-tasks/resolve-warnings · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/nullable-reference-types · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/update-applications/nullable-migration-strategies

### E. Strings
34. [INI] Visão geral — imutabilidade, `string` = `System.String`, `StringBuilder`, literais (regular, `@`, `"""`, `$`, `u8`), `\e` (C# 13), `char`/UTF-16, igualdade e `StringComparison`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/
35. [INI] Raw string literals — 3+ aspas, a coluna do `"""` final define a margem, `$$` quando o texto tem `{ }`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/raw-string-literals
36. [INI] Interpolação — `{x:F2}`, `{x,-10}`, `{{ }}`, ternário entre parênteses, expressão multilinha (C# 11), `const` interpolada, `string.Create` com cultura. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/interpolation
37. [INI] `nameof` (C# 14: `nameof(List<>)`). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/nameof
38. [INI] Tarefas comuns — concatenar, modificar, comparar, buscar, `Split`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/common-tasks/split (e `concatenate`, `modify`, `compare`, `search`)

### F. Pattern matching
39. [INI→INT] Visão geral — `is`, `switch` (instrução) × `switch` (expressão), guarda `when`, subsunção (erro) e exaustividade (aviso). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/pattern-matching
40. [INT] Padrões declaration/constant/`var` e type patterns. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/declaration-constant-var-patterns · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/type-patterns
41. [INT] Property e positional patterns — `{ Dias: <= 2 }`, `{ }` = não nulo, caminho `{ Data.DayOfWeek: ... }`, `(a, b)` com tuplas/`Deconstruct`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/property-positional-patterns
42. [INT] Relacionais e lógicos — `<`, `>=`, `and`, `or`, `not`, parênteses; precedência **not > and > or**; operando precisa ser constante. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/relational-logical-patterns
43. [INT] List e slice patterns (C# 11) — `[]`, `[var a, _, var c]`, `[.., var ultimo]`, `.. { Length: > 0 }`; exige `Length`/`Count` + indexador (não serve `IEnumerable<T>`). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/list-patterns
44. [INT] Descartes `_`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/discards
45. [INT] Tutoriais — algoritmos com pattern matching; padrões em objetos; conversão segura com `is`/`as`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/pattern-matching · https://learn.microsoft.com/en-us/dotnet/csharp/tutorials/patterns-objects · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/safely-cast-using-pattern-matching-is-and-as-operators
46. [AVA] Referência completa de padrões e `switch` expression. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/patterns · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/switch-expression

### G. Expressões e instruções
47. [INI] Operadores — aritméticos (divisão inteira trunca p/ zero; `%` tem o sinal do dividendo), `++` pré/pós, relacionais (`char` compara código Unicode), `==` (não existe `===`), `&&`/`||` curto-circuito, `?:`, atribuição composta (converte de volta: `byte += int`). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/expressions/operators
48. [INT] Aritmética avançada — overflow `checked`/`unchecked` (padrão unchecked; constante estourando = erro), `/0` inteiro lança, `double` dá ∞/NaN, arredondamento binário, `decimal` lança. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/checked-and-unchecked
49. [INT] Igualdade — valor × referência, `ReferenceEquals`, records, struct sem `==` próprio, tuplas, record com `List` (compara referência). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/expressions/equality
50. [INI] Seleção — `if`/`else if`/`else` (ordem importa), `switch` com `break` obrigatório (sem fall-through), rótulos empilhados, `case` com padrão + `when`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/selection
51. [INI] Iteração — `foreach` (variável só leitura), `while`, `do-while`, `for`, `break`/`continue`, `await foreach`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/iteration
52. [INI] Coleções — array (tamanho fixo), `List<T>` (Insert/RemoveAt no meio = O(n)), `Dictionary` (`TryGetValue`), collection expressions + spread, índices `^` e ranges `..` (fim exclusivo). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/collections · https://learn.microsoft.com/en-us/dotnet/csharp/tutorials/ranges-indexes
53. [INI→INT] LINQ essencial — query × method syntax, `Where/Select/OrderBy/GroupBy/Count/Sum/Any/First`, execução adiada × imediata, `ToList` como "foto", composição. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/linq
54. [INT] Instruções de salto e demais (`goto case`, `return`, `yield`, `using`, `lock`, `checked`, `fixed`). https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/jump-statements

### H. Programação orientada a objetos
55. [INI] Classes, structs e records — membros e acessibilidade. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/object-oriented/
56. [INI] Objetos — instância, referência compartilhada × cópia de struct, identidade × igualdade. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/object-oriented/objects
57. [INT] Herança — uma base só, construtores não são herdados, `base(...)`, `abstract`, `sealed`, ocultação com `new` (aviso CS0108/CS0114). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/object-oriented/inheritance
58. [INT] Polimorfismo — `virtual`/`override`, `base.Metodo()`, `new` usa o tipo em compilação e `override` o de execução, `sealed override`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/object-oriented/polymorphism
59. [INI→INT] Membros (programming guide) — campos, `const`, propriedades (auto, `init`, `required`, `field` C# 14), métodos, funções locais, parâmetros nomeados/opcionais, construtores (instância, `static`, `private`, primary, cópia), finalizadores, inicializadores, tipos aninhados, `partial`, modificadores de acesso (`file`, `private protected`...). https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/properties · https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/constructors · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/access-modifiers
60. [INT] Tutoriais de projeto — classes (conta bancária), OOP, herança, escolher entre tupla/record/struct/class, records, XML docs. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/classes · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/oop · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/inheritance · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/choosing-types
61. [INT] Indexadores e sobrecarga de operadores/conversões. https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/indexers/ · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/operator-overloading
62. [AVA] Interfaces avançadas — implementação explícita, membros padrão (versionar/mixins), `static abstract`/`static virtual` e generic math (`INumber<T>`). https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/interface-implementation/default-interface-methods-versions · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members

### I. Exceções
63. [INI] Visão geral e uso de exceções. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/ · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/using-exceptions
64. [INI] Tratamento — `try/catch/finally`, catch do mais específico ao mais geral, filtro `when`, `throw;` para relançar, `finally` sempre roda. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/exception-handling
65. [INT] Criar/lançar — `ArgumentException`+`nameof`, `InvalidOperationException`, `InnerException`, não lançar `Exception`/`NullReferenceException`, validar antes da parte `async`, exceção própria com 3 construtores. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/creating-and-throwing-exceptions
66. [INI] Exceções do runtime (divisão por zero, índice, cast, overflow...) e how-tos `try-catch`/`finally`. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/compiler-generated-exceptions · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/how-to-handle-an-exception-using-try-catch
67. [INT] `using` (bloco e declaração `using var`), `await using`, `throw` como expressão. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/using · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/exception-handling-statements

### J. Estilo de código
68. [INI] Nomes de identificadores (regras + convenções). https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/identifier-names
69. [INI] Convenções — interpolação, `StringBuilder` em laço, raw strings, collection expressions, `Func/Action`, `using` sem chaves, `&&` (não `&`), `new()`, object initializer, `var` só quando óbvio (e não em `foreach`), file-scoped namespace, `using` fora do namespace, 4 espaços, Allman, uma instrução por linha, comentário `//` em linha própria. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions

### K. Métodos e parâmetros
70. [INI] Métodos (assinatura, retorno, sobrecarga, expression-bodied). https://learn.microsoft.com/en-us/dotnet/csharp/methods
71. [INT] Parâmetros — por valor × `ref`/`out`/`in`/`ref readonly` (C# 12), `params` (arrays; *params collections* C# 13), nomeados/opcionais; propriedade não pode ir em `ref`. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/method-parameters · https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/named-and-optional-arguments
72. [INT] Funções locais (inclusive `static`). https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/local-functions

### L. Delegates, lambdas e eventos (aprofundamento)
73. [INT] Delegates — intro, `System.Delegate`, fortemente tipados, padrões, multicast. https://learn.microsoft.com/en-us/dotnet/csharp/delegates-overview (e `delegate-class`, `delegates-strongly-typed`, `delegates-patterns`)
74. [INT] Eventos — padrão .NET (`sender`, args, cancelamento), padrão atualizado (args sem herdar de `EventArgs`; handler `async void` com `try/catch`), delegate × evento. https://learn.microsoft.com/en-us/dotnet/csharp/events-overview · https://learn.microsoft.com/en-us/dotnet/csharp/event-pattern · https://learn.microsoft.com/en-us/dotnet/csharp/modern-events · https://learn.microsoft.com/en-us/dotnet/csharp/distinguish-delegates-events
75. [INT] Lambdas (referência) — tipo natural (`var f = (string s) => ...`), retorno explícito, parâmetro padrão (C# 12), `params` em lambda, modificadores sem tipo (C# 14), `static`, captura/closures, atributos. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/lambda-expressions
76. [AVA] Covariância e contravariância (interfaces/delegates genéricos). https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/concepts/covariance-contravariance/

### M. Iteradores e LINQ completo
77. [INT] Iteradores — `yield return`/`yield break`, não misturar com `return`, `foreach` por baixo (`GetEnumerator`/`MoveNext`/`Current` + `Dispose`), `IAsyncEnumerable`. https://learn.microsoft.com/en-us/dotnet/csharp/iterators · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/yield
78. [INT] LINQ — introdução, sintaxe de query, escrever consultas, relações de tipo, recursos que suportam LINQ. https://learn.microsoft.com/en-us/dotnet/csharp/linq/ · https://learn.microsoft.com/en-us/dotnet/csharp/linq/get-started/introduction-to-linq-queries
79. [INT] Operadores padrão — filtro, projeção (`SelectMany`), conjuntos, ordenação (`ThenBy`), quantificadores, partição (`Take/Skip/Chunk`), conversão, **join** (`Join`, `GroupJoin`, `LeftJoin`/`RightJoin` .NET 10), agrupamento. https://learn.microsoft.com/en-us/dotnet/csharp/linq/standard-query-operators/ · https://learn.microsoft.com/en-us/dotnet/csharp/linq/standard-query-operators/join-operations
80. [INT] Tutorial "Working with LINQ" — baralho + *faro shuffle*, bloco `extension`, lazy × eager (`ToArray`). **Ótimo para tema de jogo.** https://learn.microsoft.com/en-us/dotnet/csharp/tutorials/working-with-linq
81. [AVA] Estender LINQ; consultas dinâmicas. https://learn.microsoft.com/en-us/dotnet/csharp/linq/how-to-extend-linq · https://learn.microsoft.com/en-us/dotnet/csharp/linq/how-to-build-dynamic-queries

### N. Programação assíncrona e concorrência
82. [INT] Visão geral ("café da manhã") — `await`, iniciar tarefas juntas, composição, exceções (`AggregateException`; `await` relança a 1ª), `WhenAll`/`WhenAny`, async/await × `ContinueWith`. https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/
83. [INT] Cenários — I/O-bound (`await` direto) × CPU-bound (`Task.Run`), `async void` só em handler, sufixo `Async`, não bloquear (`.Result/.Wait()/Thread.Sleep` → `await`/`Task.Delay`), LINQ+async com `ToArray/ToList`, `ValueTask`, `ConfigureAwait`, `GetAwaiter().GetResult()` como último recurso. https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/async-scenarios
84. [INT] Modelo TAP e tipos de retorno (`Task`, `Task<T>`, `void`, `ValueTask`, `IAsyncEnumerable`). https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/task-asynchronous-programming-model · https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/async-return-types
85. [AVA] Processar conforme terminam; arquivos async; cancelamento (`CancellationToken`, `CancelAfter`); async streams. https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/cancel-async-tasks-after-a-period-of-time · https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/generate-consume-asynchronous-stream
86. [AVA] `lock` e `System.Threading.Lock` (C# 13/.NET 9) — nada de `await` dentro; não travar `this`, `typeof`, strings. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/lock

### O. Novidades por versão (C# 12, 13, 14 + prévia 15)
87. [INT/AVA] C# 12 (.NET 8) — primary constructors, collection expressions, inline arrays, lambda com parâmetro padrão, `ref readonly`, alias de qualquer tipo, `[Experimental]`, interceptors (prévia). https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-12 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/primary-constructors · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/collection-expressions
88. [INT/AVA] C# 13 (.NET 9) — `params` collections, `Lock`, `\e`, tipo natural de method group, `^` em object initializer, `ref`/`unsafe` em iteradores/async, `ref struct` implementa interface, `allows ref struct`, propriedades/indexadores `partial`, `[OverloadResolutionPriority]`. https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-13
89. [INT/AVA] C# 14 (.NET 10) — membros de extensão, `field`, conversões implícitas de span, `nameof(List<>)`, modificadores em lambda simples, construtores/eventos `partial`, `+=`/`++` definidos pelo usuário, atribuição null-condicional, diretivas de file-based apps. https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/extension-members · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/compound-assignment-operators
90. [SEN] C# 15 (PRÉVIA, .NET 11 preview) — `with(...)` em collection expressions, `union`, `closed`, indexadores de extensão, `break`/`continue` rotulados, memory safety. https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15 · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/union · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/closed-hierarchies
91. [SEN] Histórico, compatibilidade e breaking changes; configurar versão. https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-version-history · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/breaking-changes

### P. Tópicos avançados e sênior
92. [AVA] Atributos e reflexão — `[Obsolete]`, alvos (`assembly:`, `return:`), parâmetros posicionais × nomeados, `GetType`/`typeof`/`Assembly`, atributo próprio com `AttributeUsage`, ler com `GetCustomAttribute<T>`, atributos genéricos (C# 11). https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/reflection-and-attributes/ · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/reflection-and-attributes/creating-custom-attributes
93. [AVA] Atributos lidos pelo compilador — caller info (`[CallerMemberName]`, `CallerArgumentExpression`), análise de nulidade, `Conditional`, `Obsolete`, `Experimental`, `ModuleInitializer`. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/caller-information · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/nullable-analysis · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/attributes/general
94. [AVA] Expression trees — `Expression<Func<...>>` × `Func`, EF Core traduz p/ SQL, limitações (sem lambda de bloco, sem `?.`, sem pattern matching, sem collection expressions, sem async...). https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/expression-trees/
95. [AVA] Performance — medir antes (hot paths); `ref` locals/returns, *ref safe context*, `Span`/`Memory`, `stackalloc`, `readonly struct`, `in`/`ref readonly`; tutoriais "reduzir alocações" e "interpolated string handler". https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/performance/ · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/performance/ref-tutorial · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/performance/interpolated-string-handler
96. [AVA] `ref struct` e conversões de span — restrições, `ref` fields (C# 11), `scoped`, `allows ref struct`. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/ref-struct · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/built-in-types
97. [SEN] Unsafe e ponteiros, `fixed`, function pointers (+ modelo de memory safety do C# 15). https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/unsafe-code
98. [SEN] Interop nativo (P/Invoke, COM, `dynamic`). https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/interop/
99. [SEN] .NET Compiler Platform (Roslyn) — modelo da API, sintaxe, semântica, workspace, analyzers + code fixes. https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/ · https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/tutorials/how-to-write-csharp-analyzer-code-fix
100. [SEN] Versionamento de bibliotecas; especificação da linguagem e feature specs. https://learn.microsoft.com/en-us/dotnet/csharp/versioning · https://learn.microsoft.com/en-us/dotnet/csharp/specification/overview

**Distribuição sugerida para ~48 trilhas** (proporcional ao peso na doc): Iniciante ≈ 14 trilhas (blocos A, B, C18-20/24/26, D29-32, E, G47/50-53, H55-56, I63-64/66, J, K70); Intermediário ≈ 14 (C21-23/25/27, D31/33, F, G48-49, H57-61, I65/67, K71-72, L73-75, M77-80, N82-84); Avançado ≈ 11 (H62, L76, M81, N85-86, O87-89, P92-96); Sênior ≈ 9 (O90-91, P97-100 + arquitetura/jogos das outras frentes).

## 2. Exemplos de código de referência (C# 14 / .NET 10 — todos executados)

### 2.1 Arquivo mínimo (file-based app) — `dotnet run ola.cs -- Ana`
```csharp
#!/usr/bin/env dotnet
#:property TargetFramework=net10.0
#:property PublishAot=false

string jogador = args.Length > 0 ? args[0] : "Visitante";
Console.WriteLine($"Bem-vindo ao PAC·C#, {jogador}!");   // Bem-vindo ao PAC·C#, Ana!
return args.Length;                                        // código de saída (Main implícito vira int)
```

### 2.2 Números — as armadilhas clássicas
```csharp
Console.WriteLine(7 / 2);            // 3    (inteiro ÷ inteiro trunca em direção a zero)
Console.WriteLine(-7 / 2);           // -3
Console.WriteLine(-7 % 3);           // -1   (sinal do resto = sinal do dividendo)
Console.WriteLine(7 / 2.0);          // 3.5  (pt-BR imprime 3,5)
Console.WriteLine((double)(7 / 2));  // 3    (a divisão inteira já aconteceu)
Console.WriteLine(9 / 5 / 2);        // 0    (esquerda p/ direita: 1 / 2)
int max = int.MaxValue;
Console.WriteLine(max + 1);          // -2147483648 (unchecked por padrão: "dá a volta")
try { Console.WriteLine(checked(max + 1)); }
catch (OverflowException) { Console.WriteLine("estourou"); }
// int y = int.MaxValue + 1;         // CS0220: constante estoura em tempo de compilação
// Console.WriteLine(1 / 0);         // CS0020: divisão por zero constante
double a = 0.1;
Console.WriteLine(3 * a == 0.3);     // False (ponto flutuante binário)
Console.WriteLine(0.1m * 3 == 0.3m); // True  (decimal é base 10: use para dinheiro)
Console.WriteLine(double.IsInfinity(1.0 / 0)); // True (double não lança; int/decimal lançam)
Console.WriteLine(Math.Round(2.5));  // 2    (padrão ToEven, "arredondamento bancário")
Console.WriteLine(Math.Round(2.5, MidpointRounding.AwayFromZero)); // 3
char c = 'a';
Console.WriteLine(c + 1);            // 98   (char + int = int)
Console.WriteLine((char)(c + 1));    // b
Console.WriteLine(1 + 2 + "3");      // 33   (soma primeiro, depois concatena)
Console.WriteLine("1" + 2 + 3);      // 123
byte b = 250;
b += 10;                             // compilou: += converte de volta para byte
Console.WriteLine(b);                // 4
```

### 2.3 Strings, interpolação e raw strings
```csharp
string nome = "Ana";
int pontos = 1500;
Console.WriteLine($"|{nome,-6}|{pontos,6}|");   // |Ana   |  1500|
Console.WriteLine($"{{literal}} {pontos:N0}");  // {literal} 1,500   (pt-BR: 1.500)
string caminho = @"C:\jogos\pac";               // verbatim: \ literal
string json = """
    { "nome": "Ana", "nivel": 3 }
    """;                                         // raw: a coluna do """ final define a margem
Console.WriteLine($"{caminho} {json}");          // C:\jogos\pac { "nome": "Ana", "nivel": 3 }
string msg = $$"""{"jogador": "{{nome}}"}""";   // {"jogador": "Ana"}  ($$ → { } literais)
string s = "pac";
s.ToUpper();                                     // resultado descartado: strings são imutáveis
Console.WriteLine(s);                            // pac
Console.WriteLine(string.Equals("pac", "PAC", StringComparison.OrdinalIgnoreCase)); // True
var sb = new System.Text.StringBuilder();        // System.Text não é implicit using
for (int i = 1; i <= 3; i++) sb.Append(i).Append(';');
Console.WriteLine(sb);                           // 1;2;3;
Console.WriteLine("banana".Replace("a", "o"));   // bonono
Console.WriteLine(string.Join("-", "a,b,,c".Split(',', StringSplitOptions.RemoveEmptyEntries))); // a-b-c
Console.WriteLine(string.Create(System.Globalization.CultureInfo.InvariantCulture, $"{3.5:F2}")); // 3.50 sempre
Console.WriteLine("\e[32mVerde\e[0m");           // \e = ESC (C# 13), cor ANSI no terminal
```

### 2.4 Decisão e repetição
```csharp
int hp = 25;
string estado = hp switch
{
    <= 0 => "morto",
    < 30 => "crítico",
    < 70 => "ferido",
    _ => "ok"
};                                               // crítico (1º braço que casa vence)
DayOfWeek dia = DayOfWeek.Sunday;
switch (dia)
{
    case DayOfWeek.Saturday:
    case DayOfWeek.Sunday:
        Console.WriteLine("Fim de semana: bônus em dobro");
        break;                                   // obrigatório: sem fall-through (CS0163)
    default:
        Console.WriteLine("Dia útil");
        break;
}
for (int i = 3; i > 0; i--) Console.Write($"{i}... ");   // 3... 2... 1...
int tentativas = 0;
do { tentativas++; } while (tentativas < 3);             // corpo roda ao menos 1 vez
for (char letra = 'a'; letra < 'e'; letra++) Console.Write(letra); // abcd
int soma = 0;
for (int n = 1; n <= 20; n++) { if (n % 3 == 0) soma += n; }       // 63
```

### 2.5 Coleções, índices e ranges
```csharp
List<string> inventario = ["espada", "escudo"];
inventario.Add("poção");
inventario.Remove("escudo");
Console.WriteLine($"{inventario.Count} {inventario[^1]}");   // 2 poção
Dictionary<string, int> placar = new() { ["Ana"] = 1500, ["Bia"] = 900 };
placar["Caio"] = 1200;                                        // adiciona ou substitui
if (placar.TryGetValue("Dani", out int p)) Console.WriteLine(p);
else Console.WriteLine("Dani não jogou");                     // placar["Dani"] lançaria KeyNotFoundException
HashSet<int> vistos = [1, 2, 2, 3];                           // Count = 3
Queue<string> fila = new(); fila.Enqueue("P1"); fila.Enqueue("P2");
Stack<int> pilha = new();   pilha.Push(1);      pilha.Push(2);
Console.WriteLine($"{fila.Dequeue()} {pilha.Pop()}");        // P1 2
int[] v = [10, 20, 30, 40, 50];
Console.WriteLine(string.Join(",", v[1..3]));                 // 20,30  (fim exclusivo)
Console.WriteLine(string.Join(",", v[^2..]));                 // 40,50
int[] todas = [0, .. v[..2], 99];                             // 0,10,20,99 (spread)
// var x = [1, 2, 3];                                         // CS9176: collection expression não tem tipo natural
```

### 2.6 Métodos e parâmetros
```csharp
int vida = 10;
Dano(ref vida, 4);                                   // vida = 6
var (min, max) = Extremos([3, 9, 1]);                // 1 e 9
if (int.TryParse("42", out int lido)) Console.WriteLine(lido + 1);   // 43
Console.WriteLine(Total(1, 2, 3));                   // 6
Console.WriteLine(Saudar(saudacao: "Oi", nome: "Bia")); // Oi, Bia!
Console.WriteLine(Fatorial(5));                      // 120

static void Dano(ref int hp, int valor) => hp = Math.Max(0, hp - valor);
static (int Min, int Max) Extremos(int[] v) => (v.Min(), v.Max());
static int Total(params int[] valores) => valores.Sum();
static string Saudar(string nome, string saudacao = "Olá") => $"{saudacao}, {nome}!";
static int Fatorial(int n) => n <= 1 ? 1 : n * Fatorial(n - 1);
```

### 2.7 Classes, propriedades, `required`/`init`, primary constructor e `field`
```csharp
var conta = new Conta { Titular = "Ana" };          // sem Titular → CS9035
conta.Depositar(100m);
Console.WriteLine($"{conta.Numero}: {conta.Saldo}"); // 1: 100
var slime = new Inimigo("Slime", 3);
slime.LevarDano(5);
Console.WriteLine(slime.Vivo);                       // False
var j = new Jogador { Nome = "Ana" };
j.Vida -= 130;
Console.WriteLine(j.Vida);                           // 0

public class Conta
{
    private static int s_proximoNumero = 1;          // static: compartilhado por todas
    private readonly List<decimal> _movimentos = [];
    public int Numero { get; }
    public required string Titular { get; init; }
    public decimal Saldo => _movimentos.Sum();       // propriedade calculada
    public Conta() => Numero = s_proximoNumero++;
    public void Depositar(decimal valor)
    {
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(valor);   // .NET 8+
        _movimentos.Add(valor);
    }
}

public class Inimigo(string nome, int vida)          // primary constructor (C# 12)
{
    public string Nome { get; } = nome;              // só inicializa: não captura
    public bool Vivo => vida > 0;                    // usado em membro: vira campo oculto
    public void LevarDano(int dano) => vida -= dano; // parâmetro é mutável!
}

public class Jogador
{
    public required string Nome { get; init; }
    public int Vida { get; set => field = Math.Clamp(value, 0, 100); } = 100;  // field (C# 14); "= 100" vai direto no campo
}
```

### 2.8 Structs, records, enums e tuplas
```csharp
var p1 = new Posicao(1, 2);
var p2 = p1 with { X = 5 };                          // cópia com alteração
Console.WriteLine(p1);                               // Posicao { X = 1, Y = 2 }
var c1 = new Carta("Copas", 10);
var c2 = new Carta("Copas", 10);
Console.WriteLine($"{c1 == c2} {ReferenceEquals(c1, c2)}");   // True False
var (naipe, valor) = c1;                             // desconstrução posicional
var poderes = Poder.Voo | Poder.Invisivel;
Console.WriteLine($"{poderes} {(int)poderes}");      // Voo, Invisivel 5
Console.WriteLine(Enum.IsDefined((Poder)99));        // False — (Poder)99 compila e roda!
Console.WriteLine((Nome: "Ana", Pts: 30) == (Jogador: "Ana", Total: 30)); // True: nomes não contam (aviso CS8383)
int a = 1, b = 2;
(a, b) = (b, a);                                     // troca: a = 2, b = 1
PontoS[] arr = [new PontoS()];
arr[0].X = 5;                                        // ok (elemento de array é variável)
// List<PontoS> l = [new PontoS()]; l[0].X = 5;      // CS1612: o indexador devolve cópia
Console.WriteLine(new Mochila("A", ["poção"]) == new Mochila("A", ["poção"])); // False (List por referência)

public readonly record struct Posicao(int X, int Y);
public record Carta(string Naipe, int Valor);
public record Mochila(string Dono, List<string> Itens);
[Flags] public enum Poder { Nenhum = 0, Voo = 1, Forca = 2, Invisivel = 4 }
public struct PontoS { public int X; public int Y; }
```

### 2.9 Herança, polimorfismo, classe abstrata e interface com membro padrão
```csharp
List<Personagem> grupo = [new Guerreiro("Ana"), new Mago("Bia")];
foreach (Personagem per in grupo) Console.WriteLine(per.Atacar());
// Ana golpeia com a espada / Bia lança uma bola de fogo
IDescritivel d = new Guerreiro("Caio");
Console.WriteLine(d.Descrever());          // [Caio] — membro padrão só via interface
// new Guerreiro("Caio").Descrever();      // CS1061: a classe não "herda" o membro padrão
Animal an = new Gato();
Console.WriteLine($"{an.Som()} {an.Nome()}");   // Miau Animal  (override × new)

public interface IDescritivel
{
    string Nome { get; }
    string Descrever() => $"[{Nome}]";      // implementação padrão (C# 8)
}
public abstract class Personagem(string nome) : IDescritivel
{
    public string Nome { get; } = nome;
    public abstract string Atacar();
    public virtual int Defesa => 1;
}
public class Guerreiro(string nome) : Personagem(nome)
{
    public override string Atacar() => $"{Nome} golpeia com a espada";
    public override int Defesa => base.Defesa + 2;
}
public sealed class Mago(string nome) : Personagem(nome)
{
    public override string Atacar() => $"{Nome} lança uma bola de fogo";
}
public class Animal { public virtual string Som() => "..."; public string Nome() => "Animal"; }
public class Gato : Animal { public override string Som() => "Miau"; public new string Nome() => "Gato"; }
```

### 2.10 Null safety
```csharp
string? apelido = null;
int tamanho = apelido?.Length ?? 0;        // 0
apelido ??= "Visitante";                   // só atribui se for null
if (apelido is not null) Console.WriteLine(apelido.ToUpper());   // VISITANTE
int? recorde = null;
Console.WriteLine(recorde.GetValueOrDefault(-1));  // -1
Jogador? j = BuscarJogador(true);
j?.Pontos += 10;                           // C# 14: atribuição null-condicional (+= permitido)
j?.Nome = "Bia";                           // lado direito só é avaliado se j não for null
// j?.Pontos++;                            // CS1059: ++/-- não são permitidos
Console.WriteLine($"{j?.Nome} {j?.Pontos}");       // Bia 10

static Jogador? BuscarJogador(bool existe) => existe ? new Jogador() : null;
public class Jogador { public string Nome { get; set; } = ""; public int Pontos { get; set; } }
```

### 2.11 Pattern matching
```csharp
object item = 42;
if (item is int n && n > 40) Console.WriteLine($"int grande: {n}");
Console.WriteLine(Descrever(new Posicao(2, 3)));   // 1º quadrante
Console.WriteLine(Mao([1, 2, 3]));                 // 1..3
char tecla = 'd';
bool movimento = tecla is 'w' or 'a' or 's' or 'd';   // True
bool letra = tecla is >= 'a' and <= 'z';              // True
int x = 2;
Console.WriteLine(x is not 1 or 2);        // True  — lido como (not 1) or 2
Console.WriteLine(x is not (1 or 2));      // False — o que geralmente se quer

static string Descrever(object? x) => x switch
{
    null => "nada",
    int i when i < 0 => "int negativo",
    int => "int",
    string { Length: 0 } => "texto vazio",
    string s => $"texto com {s.Length} letras",
    Posicao(0, 0) => "origem",
    Posicao { X: > 0, Y: > 0 } => "1º quadrante",
    _ => "outra coisa"                     // precisa ser o último (senão CS8510)
};
static string Mao(int[] dados) => dados switch
{
    [] => "sem dados",
    [6, 6, 6] => "trinca de seis!",
    [var a, var b] when a == b => "par",
    [var primeiro, .., var ultimo] => $"{primeiro}..{ultimo}",
    [var unico] => $"só {unico}"
};
public record Posicao(int X, int Y);
```

### 2.12 Exceções e `using`
```csharp
try
{
    int nivel = int.Parse("abc");
    Console.WriteLine(nivel);
}
catch (FormatException ex) when (ex.Message.Length > 0)   // filtro de exceção
{
    Console.WriteLine("Nível inválido");
}
finally
{
    Console.WriteLine("Sempre executa");
}
try { DefinirVolume(150); }
catch (ArgumentOutOfRangeException ex) { Console.WriteLine(ex.ParamName); }   // volume
using var arquivo = new StreamWriter("save.txt");         // Dispose no fim do escopo (ou bloco using (...) { })
arquivo.WriteLine("fase=3");

static void DefinirVolume(int volume)
{
    ArgumentOutOfRangeException.ThrowIfNegative(volume);
    ArgumentOutOfRangeException.ThrowIfGreaterThan(volume, 100);
}
public class SaveCorrompidoException : Exception          // os 3 construtores recomendados
{
    public SaveCorrompidoException() { }
    public SaveCorrompidoException(string message) : base(message) { }
    public SaveCorrompidoException(string message, Exception inner) : base(message, inner) { }
}
```

### 2.13 Generics e generic math
```csharp
using System.Numerics;
Console.WriteLine(Maior(3, 7));                  // 7
int[] pontos = [10, 20, 30];
Console.WriteLine(Somar(pontos));                // 60
Console.WriteLine(new Caixa<string>("moeda").Conteudo);

static T Maior<T>(T a, T b) where T : IComparable<T> => a.CompareTo(b) >= 0 ? a : b;
static T Somar<T>(IEnumerable<T> itens) where T : INumber<T>   // static abstract em interface (C# 11)
{
    T total = T.Zero;
    foreach (T item in itens) total += item;
    return total;
}
public class Caixa<T>(T conteudo) where T : notnull { public T Conteudo { get; } = conteudo; }
```

### 2.14 Delegates, lambdas e eventos
```csharp
Func<int, int> dobro = x => x * 2;
Func<int, int, int> soma = (a, b) => a + b;
Action<string> log = msg => Console.WriteLine($"[LOG] {msg}");
Predicate<int> ehPar = static n => n % 2 == 0;       // static: não captura nada
var parse = (string s) => int.Parse(s);              // tipo natural: Func<string, int>
var incrementar = (int v, int passo = 1) => v + passo;   // parâmetro padrão (C# 12)
Console.WriteLine(dobro(soma(2, 3)));                // 10
var botao = new Botao();
botao.Clicado += (_, texto) => log(texto);
botao.Clicar("Start");                               // [LOG] Start

public class Botao
{
    public event EventHandler<string>? Clicado;      // fora da classe: só += e -=
    public void Clicar(string texto) => Clicado?.Invoke(this, texto);
}
```

### 2.15 LINQ
```csharp
List<Jogador> jogadores =
[
    new("Ana", "Azul", 30), new("Bia", "Verde", 45),
    new("Caio", "Azul", 12), new("Dani", "Verde", 45)
];
var top = jogadores.Where(j => j.Pontos >= 20)
                   .OrderByDescending(j => j.Pontos).ThenBy(j => j.Nome)
                   .Select(j => j.Nome);
Console.WriteLine(string.Join(", ", top));           // Bia, Dani, Ana
var porTime = from j in jogadores
              group j by j.Time into g
              select (Time: g.Key, Total: g.Sum(x => x.Pontos));
foreach (var (time, total) in porTime) Console.WriteLine($"{time}: {total}");   // Azul: 42 / Verde: 90
Console.WriteLine(jogadores.Any(j => j.Pontos > 40));        // True
Jogador? nenhum = jogadores.FirstOrDefault(j => j.Pontos == 0); // null (First lançaria)
List<int> nums = [1, 2, 3];
var maiores = nums.Where(n => n > 1);                // execução ADIADA
nums.Add(4);
Console.WriteLine(maiores.Count());                  // 3 (enxerga o 4)
Console.WriteLine(string.Join(" | ", new[] { 1, 2, 3, 4, 5 }.Chunk(2).Select(g => string.Join(",", g)))); // 1,2 | 3,4 | 5
var times = new[] { ("Azul", 1), ("Roxo", 3) };
var membros = new[] { ("Ana", 1), ("Bia", 2) };
var esq = times.LeftJoin(membros, t => t.Item2, m => m.Item2, (t, m) => $"{t.Item1}:{m.Item1 ?? "-"}"); // .NET 10
Console.WriteLine(string.Join(" ", esq));            // Azul:Ana Roxo:-

public record Jogador(string Nome, string Time, int Pontos);
```

### 2.16 Iteradores
```csharp
foreach (int f in Fibonacci().Take(8)) Console.Write($"{f} ");   // 1 1 2 3 5 8 13 21

static IEnumerable<int> Fibonacci()
{
    int a = 1, b = 1;
    while (true)
    {
        yield return a;                  // sequência infinita + Take: só funciona por ser preguiçosa
        (a, b) = (b, a + b);
    }
}
```

### 2.17 Assíncrono, cancelamento e async streams
```csharp
Task<int> a = SimularDownloadAsync("fase1", 300);    // as duas começam já
Task<int> b = SimularDownloadAsync("fase2", 500);
int[] tamanhos = await Task.WhenAll(a, b);           // ~500 ms no total, não 800
Console.WriteLine(tamanhos.Sum());                   // 1000
using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(100));
try { await Task.Delay(1000, cts.Token); }
catch (OperationCanceledException) { Console.WriteLine("Carregamento cancelado"); }
await foreach (int onda in OndasAsync()) Console.WriteLine($"Onda {onda}");

static async Task<int> SimularDownloadAsync(string nome, int ms)
{
    await Task.Delay(ms);                            // I/O simulado: não bloqueia a thread
    return nome.Length * 100;
}
static async IAsyncEnumerable<int> OndasAsync()
{
    for (int k = 1; k <= 3; k++) { await Task.Delay(50); yield return k; }
}
```

### 2.18 Concorrência com `Lock` (C# 13/.NET 9) e `Span` sem alocação
```csharp
var placar = new Placar();
Parallel.For(0, 1000, _ => placar.Somar(1));
Console.WriteLine(placar.Total);                     // 1000
ReadOnlySpan<char> linha = "HP=75;MP=20";            // string → ReadOnlySpan<char>
ReadOnlySpan<char> hp = linha[..linha.IndexOf(';')]; // "HP=75" sem nova string
Span<int> buffer = stackalloc int[4];                // memória na pilha
buffer.Fill(7);
Console.WriteLine(int.Parse(hp[3..]) + buffer[0]);   // 82

public class Placar
{
    private readonly Lock _trava = new();            // antes do C# 13: private readonly object
    private int _total;
    public int Total { get { lock (_trava) return _total; } }
    public void Somar(int pontos) { lock (_trava) { _total += pontos; } }   // nada de await aqui (CS1996)
}
```

### 2.19 Atributos, reflexão e expression trees
```csharp
using System.Linq.Expressions;
using System.Reflection;
var info = typeof(Chefe).GetCustomAttribute<InimigoAttribute>();
Console.WriteLine($"Chefe: nível {info?.Nivel}");    // Chefe: nível 10
Expression<Func<int, bool>> filtro = n => n > 5;     // árvore de expressão (dado)
Console.WriteLine(filtro);                           // n => (n > 5)
Console.WriteLine(filtro.Compile()(7));              // True

[AttributeUsage(AttributeTargets.Class)]
public sealed class InimigoAttribute(int nivel) : Attribute { public int Nivel { get; } = nivel; }
[Inimigo(10)] public class Chefe { }
```

### 2.20 Novidades do C# 12 (.NET 8)
```csharp
using Ponto = (int X, int Y);                        // alias de QUALQUER tipo (aqui, tupla)
Ponto inicio = (0, 0);
Console.WriteLine(inicio.X + inicio.Y);              // 0
int[] linha1 = [1, 2, 3];
List<int> lista = [.. linha1, 4];                    // collection expression + spread
Span<char> letras = ['p', 'a', 'c'];
IEnumerable<string> vazio = [];
var incrementar = (int v, int passo = 1) => v + passo;   // lambda com parâmetro padrão
var vet = new Vetor3(1, 2, 2);
Console.WriteLine(Comprimento(in vet));              // 3 (ref readonly aceita in/ref no argumento)
var buf = new Buffer4();
for (int i = 0; i < 4; i++) buf[i] = i * 10;         // inline array usado como array

static double Comprimento(ref readonly Vetor3 v) => Math.Sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z);
public readonly record struct Vetor3(double X, double Y, double Z);
[System.Runtime.CompilerServices.InlineArray(4)]
public struct Buffer4 { private int _elemento0; }
// + primary constructors (2.7), [System.Diagnostics.CodeAnalysis.Experimental("PAC001")], interceptors (prévia)
```

### 2.21 Novidades do C# 13 (.NET 9)
```csharp
Console.WriteLine(SomarTudo(1, 2, 3));               // 6 — params collections
var cont = new Contagem { Ultimos = { [^1] = 99 } }; // ^ dentro de object initializer
Console.WriteLine(string.Join(",", cont.Ultimos));   // 0,0,99
Console.WriteLine((int)'\e');                        // 27 — nova sequência de escape
var cfg = new Config { Tema = "  claro  " };
Console.WriteLine($"[{cfg.Tema}]");                  // [claro]

static int SomarTudo(params ReadOnlySpan<int> nums) { int t = 0; foreach (int n in nums) t += n; return t; }
public class Contagem { public int[] Ultimos { get; set; } = new int[3]; }
public partial class Config { public partial string Tema { get; set; } }   // declaração
public partial class Config                                                 // implementação
{
    public partial string Tema { get; set => field = value.Trim(); } = "escuro";   // field: C# 14
}
// + Lock (2.18), ref struct implementando interface, where T : allows ref struct,
//   ref/unsafe em iteradores e async, [OverloadResolutionPriority(n)] (para autores de bibliotecas)
```

### 2.22 Novidades do C# 14 (.NET 10) — membros de extensão
```csharp
using System.Drawing;
Console.WriteLine("banana".Vogais);                  // 3   — propriedade de extensão
Console.WriteLine("  ".EstaEmBranco);                // True
Console.WriteLine(int.Aleatorio(1, 6) is >= 1 and <= 6);   // True — membro "estático" de extensão
Console.WriteLine(new Point(1, 2) + new Point(3, 4));      // {X=4,Y=6} — operador de extensão
Console.WriteLine(Point.Origem);                     // {X=0,Y=0}
int[] arr = [1, 2, 3];
Console.WriteLine(arr.Soma());                       // 6 — array → ReadOnlySpan<int> no receptor (span implícito)

public static class ExtensoesPac                     // static, não genérica, não aninhada
{
    extension(string texto)                          // receptor de instância
    {
        public int Vogais => texto.Count(c => "aeiouAEIOU".Contains(c));
        public bool EstaEmBranco => string.IsNullOrWhiteSpace(texto);
    }
    extension(int)                                   // sem nome: só membros static
    {
        public static int Aleatorio(int min, int max) => Random.Shared.Next(min, max + 1);
    }
    extension(Point)
    {
        public static Point Origem => Point.Empty;
        public static Point operator +(Point a, Point b) => new(a.X + b.X, a.Y + b.Y);
    }
    public static int Soma(this ReadOnlySpan<int> valores)   // sintaxe antiga (this) continua válida
        { int t = 0; foreach (int v in valores) t += v; return t; }
}
```

### 2.23 Novidades do C# 14 — demais recursos
```csharp
Console.WriteLine(nameof(List<>));                   // List — nameof com genérico não vinculado
TentarConverter<int> conv = (texto, out resultado) => int.TryParse(texto, out resultado); // modificador sem tipo
Console.WriteLine(conv("12", out int r) ? r * 2 : -1);    // 24
var heroi = new Heroi("Ana");
heroi.Morreu += () => Console.WriteLine("Herói caiu!");
heroi.Morrer();                                      // Herói caiu!
var placar = new PlacarMutavel();
placar += 10;                                        // chama o operator += de instância
placar++;
Console.WriteLine(placar.Pontos);                    // 11

public delegate bool TentarConverter<T>(string texto, out T resultado);
public partial class Heroi                                   // construtor e evento partial
{
    public partial Heroi(string nome);                       // declaração
    public partial event Action Morreu;                      // declaração (sem campo gerado)
}
public partial class Heroi
{
    private Action? _morreu;
    public string Nome { get; }
    public partial Heroi(string nome) => Nome = nome;        // implementação
    public partial event Action Morreu { add => _morreu += value; remove => _morreu -= value; }
    public void Morrer() => _morreu?.Invoke();               // evento partial não é "field-like"
}
public class PlacarMutavel
{
    public int Pontos { get; private set; }
    public void operator +=(int p) => Pontos += p;           // compound assignment definido pelo usuário
    public void operator ++() => Pontos++;
}
// + field (2.7/2.21), atribuição null-condicional (2.10), diretivas #: de file-based apps (2.1)
```

### 2.24 PRÉVIA C# 15 (.NET 11 preview + `<LangVersion>preview</LangVersion>`) — não executado
```csharp
HashSet<string> nomes = [with(StringComparer.OrdinalIgnoreCase), "Ana", "ANA", "Bia"];  // Count == 2
List<int> pontos = [with(capacity: 100), 10, 20];     // with(...) sempre o 1º elemento; não vale p/ array/span

Resultado res = new Erro("save corrompido");          // union: conversão implícita de cada "case type"
string texto = res switch
{
    Sucesso s => $"ok: {s.Pontos}",
    Erro e => $"falhou: {e.Motivo}",                  // exaustivo sem "_"
};

busca: for (int lin = 0; lin < 3; lin++)             // break/continue rotulados
{
    for (int col = 0; col < 3; col++)
    {
        if (lin == col) continue busca;
        if (lin + col == 3) break busca;
    }
}

public record class Sucesso(int Pontos);
public record class Erro(string Motivo);
public union Resultado(Sucesso, Erro);
public closed record class EstadoPorta;               // closed: só derivável no mesmo assembly (implícito abstract)
public record class Fechada : EstadoPorta;
public record class Aberta(int Percentual) : EstadoPorta;
public static class SequenciaExt { extension(IEnumerable<int> seq) { public int this[int i] => seq.ElementAt(i); } } // indexador de extensão
```

## 3. Armadilhas e boas práticas que o curso deve ensinar

**Sintaxe e compilação**
- `=` × `==`: `if (vida = 0)` não compila (**CS0029**, não converte int→bool). Não existe `===` em C#.
- `decimal preco = 9.99;` → **CS0664** (use `9.99m`); `float f = 3.14;` → **CS0664** (use `3.14f`).
- `switch` instrução: toda seção com código termina em `break`/`return`/`throw`/`goto` (**CS0163**). Rótulos vazios empilhados podem.
- Top-level: tipos antes das instruções → **CS8803**. Só **um** arquivo do projeto pode ter top-level statements.
- Variável local precisa estar atribuída antes do uso (**CS0165**); `const` só aceita constante de compilação (**CS0133**; `DateTime` nem pode ser `const` — use `static readonly`).
- Chamar membro de instância via tipo → **CS0120**; nem todos os caminhos retornam → **CS0161**.
- Indentação não define bloco: sempre chaves em `if`/`for`/`while` (a doc recomenda).
- `var` exige inicializador e o tipo é fixo em compilação (não é `dynamic`). Collection expression sozinha não tem tipo (**CS9176**).

**Números**
- Divisão inteira trunca em direção a zero (`-7 / 2 == -3`); `%` tem o sinal do dividendo. Converter **antes** de dividir: `(double)a / b`.
- Overflow de `int` é silencioso (unchecked) em tempo de execução; com constantes é erro (**CS0220**); use `checked(...)` quando importar. `int.MinValue / -1` lança mesmo em unchecked.
- Inteiro/`decimal` ÷ 0 lança `DivideByZeroException` (constante: **CS0020**); `double` dá ∞/NaN sem exceção.
- `double` não é exato (`0.1 * 3 != 0.3`): dinheiro = `decimal`; comparar double com tolerância.
- `Math.Round(2.5) == 2` (ToEven); passe `MidpointRounding.AwayFromZero` se quiser o "arredondamento escolar".
- `byte/short/char` em operação viram `int` (`byte + byte` é `int`), mas `+=` converte de volta (pode "dar a volta": 250+10 → 4).

**Strings e cultura**
- Strings são imutáveis: `s.ToUpper();` sozinho não muda `s`. Em laço grande, `StringBuilder`.
- Formatação depende da cultura (pt-BR usa vírgula decimal e ponto de milhar); para logs/arquivos use cultura invariante; para comparar identificadores, `StringComparison.Ordinal(IgnoreCase)`.
- Ternário dentro de interpolação exige parênteses: `$"{(ok ? "sim" : "não")}"`. Chave literal: `{{`/`}}` (ou raw `$$"""`).
- Raw string multilinha: conteúdo em linhas próprias; nenhuma linha pode ficar à esquerda do `"""` final.
- `"1" + 2 + 3 == "123"` mas `1 + 2 + "3" == "33"` (avaliação da esquerda para a direita).

**Valor × referência**
- Atribuir struct copia; atribuir class copia a referência (duas variáveis, um objeto). Passar struct para método sem `ref` altera só a cópia.
- `lista[0].X = 5` com `List<struct>` → **CS1612** (indexador retorna cópia); em array funciona.
- `default(StructComConstrutor)` ignora o construtor sem parâmetros (campos zerados/null).
- Records comparam por valor **membro a membro**, mas `List`/array dentro do record comparam por referência; `with` é cópia rasa.
- Não use record como entidade do EF Core (EF depende de igualdade por referência).
- Cast de int para enum não valida (`(Poder)99` roda) — valide com `Enum.IsDefined`/`TryParse` + `IsDefined`.

**Null safety**
- Prefira `is null`/`is not null` a `== null` (não sofre sobrecarga de operador).
- `a?.B` sobre membro `int` produz `int?`; complete com `??`. `(a?.B).C()` quebra o curto-circuito.
- `!` só silencia o compilador — não evita `NullReferenceException`. Avisos típicos: **CS8600**, **CS8602**, **CS8618**.
- Atribuição null-condicional (C# 14): `x?.P = v` e `x?.P += v` ok; `x?.P++` não (**CS1059**); o lado direito nem é avaliado se `x` for null.
- Array novo de referência nasce com `null` em todas as posições, mesmo tipado como não-anulável.

**Coleções, iteradores e LINQ**
- Modificar uma `List` dentro do `foreach` sobre ela → `InvalidOperationException`; use `RemoveAll`, `for` de trás para frente ou uma cópia (`ToList()`).
- Índices vão de `0` a `Count - 1`; `i <= Length` em `for` estoura (`IndexOutOfRangeException`). `^1` é o último; em range o fim é exclusivo.
- `dicionario[chave]` inexistente lança `KeyNotFoundException`; use `TryGetValue`. `First()` em sequência vazia lança; `FirstOrDefault()` retorna `default`.
- LINQ é **adiado**: a consulta roda ao enumerar e vê as mudanças da fonte; enumerar duas vezes executa duas vezes. `ToList()/ToArray()` tiram uma "foto".
- Iterador (`yield`) não roda nada até o primeiro `MoveNext` — validação de argumento lança tarde (verificado: `Contar(-1)` só lança no `foreach`). Padrão: método público **sem** `yield` que valida e devolve um iterador privado/local (a doc divide iteradores em dois métodos e usa a mesma ideia para validar antes da parte `async`). Não misture `return valor` e `yield return` no mesmo método.
- Closure em `for` captura a **mesma** variável (`for` com lambdas imprime `333`); `foreach` cria variável nova por iteração (`012`).
- List patterns só funcionam em tipos com `Length`/`Count` + indexador (array, `List`, `string`, span), não em `IEnumerable<T>`.

**OOP**
- Só `virtual`/`abstract` podem ser sobrescritos; sem `override` você **oculta** (aviso **CS0114**) e a chamada via base usa a versão da base.
- Construtores não são herdados; derivada chama `: base(...)`. Classe com membro `abstract` deve ser `abstract`.
- Membro padrão de interface só é acessível pelo tipo da interface (**CS1061** via classe).
- Primary constructor: parâmetros **não são propriedades** (exceto em record), não têm `this.`, são mutáveis e viram campo oculto se usados em membros; cuidado ao usá-los na derivada **e** passá-los à base (cópia duplicada; o compilador avisa).
- Interface × classe abstrata (doc): estado/construtor compartilhado → abstrata; capacidade transversal/várias → interface.

**Exceções**
- `catch` do mais específico ao mais geral (senão **CS0160**); não capture `Exception` sem relançar/filtro.
- Relance com `throw;` (preserva o stack trace), não `throw ex;`. Não use exceção para fluxo normal; não lance `Exception`, `NullReferenceException`, `IndexOutOfRangeException` de propósito.
- Use as guardas prontas: `ArgumentNullException.ThrowIfNull`, `ArgumentOutOfRangeException.ThrowIfNegative/ThrowIfGreaterThan`, `ArgumentException.ThrowIfNullOrEmpty` (`ParamName` sai certo sozinho).
- `using` garante `Dispose` mesmo com exceção/`return`; declare a variável **no** `using` (senão ela fica viva e "morta" → `ObjectDisposedException`).

**Async e concorrência**
- Não bloqueie: `.Result`/`.Wait()`/`Thread.Sleep` → `await`/`await Task.Delay`; `WaitAll/WaitAny` → `await Task.WhenAll/WhenAny`.
- `async void` só em event handler (exceções não podem ser capturadas pelo chamador); dentro dele, `try/catch` em volta do `await`.
- Método `async` sem `await` roda síncrono (**CS1998**); chamada async não aguardada (**CS4014**) perde exceções.
- I/O → `await` direto; CPU pesado → `await Task.Run(...)`. Para disparar em paralelo: crie as tasks **antes** de aguardar; com LINQ, materialize com `ToArray()`.
- Método `async` roda sincronamente até o primeiro `await` (ordem de saída "12345" na seção 4).
- Valide argumentos **antes** da parte assíncrona (exceção síncrona); exceções async ficam guardadas na `Task` até o `await`.
- `lock`: objeto dedicado (`Lock` no .NET 9+); nunca `this`, `typeof(...)` ou string; sem `await` dentro (**CS1996**); segure o menor tempo possível.

**Novidades (quando usar)**
- `field` (C# 14): cuidado se a classe já tem membro chamado `field` (use `@field`/`this.field` ou renomeie).
- Extension members: blocos só em `static class` não genérica e não aninhada; membro da própria classe sempre vence a extensão; todas as assinaturas da classe precisam ser únicas (o bloco não cria escopo); receptor `ref` só para structs.
- Collection expression **sempre** materializa todos os elementos (não é preguiçosa como LINQ); não serve para `const` nem valor padrão de parâmetro.
- `ref struct`/`Span<T>`: não pode ir para o heap (sem campo em class, sem array, sem captura em lambda, sem atravessar `await`).
- Performance: só otimize hot path medido (a doc insiste: "measure a baseline").
- C# 15 é prévia: não use em exercício principal.

**Catálogo de diagnósticos (verificados no SDK 10.0.102) — ótimo para "achar o bug"**

| Código | Situação típica |
|---|---|
| CS0029 | `if (vida = 0)` — não converte `int` em `bool` |
| CS0664 | `decimal x = 9.99;` / `float f = 3.14;` sem sufixo `m`/`f` |
| CS0163 | `case` sem `break` (fall-through) |
| CS0160 | `catch (Exception)` antes de `catch (FormatException)` |
| CS0165 | `int total; total += 5;` (variável não atribuída) |
| CS0020 / CS0220 | `1 / 0` constante / `int.MaxValue + 1` constante |
| CS0133 (+CS0283) | `const DateTime Inicio = DateTime.Now;` |
| CS8803 | tipo declarado antes das top-level statements |
| CS1996 | `await` dentro de `lock` |
| CS1612 | `lista[0].X = 5` com `List<struct>` |
| CS9176 | `var x = [1, 2, 3];` |
| CS1059 | `j?.Pontos++;` |
| CS9035 / CS8852 | `required` não setado / `init` atribuído fora do inicializador |
| CS8510 (erro) / CS8509 (aviso) | braço de `switch` inalcançável / `switch` não exaustivo |
| CS1061 | membro inexistente (ex.: membro padrão de interface chamado pela classe) |
| CS0120 / CS0161 | membro de instância chamado pelo tipo / caminho sem `return` |
| CS8602 (aviso) | desreferência de possível null |
| CS0114 (aviso) | método "igual" ao virtual da base sem `override`/`new` |
| CS4014 (aviso) | chamada async não aguardada |
| CS1002 / CS1003 | `;` faltando (dependendo do contexto o compilador pede `;` ou `,`) |

## 4. Ideias de exercícios típicos desta frente

### 4.1 Digitação curta (1–8 linhas), por tópico — C# válido (assume as variáveis do contexto já declaradas)
- **Saída e variáveis**: `Console.WriteLine("Olá, PAC·C#!");` · `string nome = "Ana";` · `Console.WriteLine($"Olá, {nome}!");` · `int vidas = 3; vidas--;` · `const int VidaMaxima = 100;`
- **Números**: `double media = (double)soma / qtd;` · `decimal preco = 19.90m;` · `int resto = pontos % 10;` · `double area = Math.PI * raio * raio;` · `int dado = Random.Shared.Next(1, 7);` · `int limitado = Math.Clamp(vida, 0, 100);`
- **Strings**: `string limpo = entrada.Trim().ToLower();` · `bool temPac = frase.Contains("pac");` · `string[] partes = linha.Split(';');` · `string titulo = string.Join(" - ", partes);` · `Console.WriteLine($"{nome,-10}|{pontos,5}");`
- **Decisão**: `if (vida <= 0) { Console.WriteLine("Game over"); }` · `string faixa = idade >= 18 ? "adulto" : "jovem";` · `string medalha = pos switch { 1 => "ouro", 2 => "prata", 3 => "bronze", _ => "-" };`
- **Laços**: `for (int i = 1; i <= 10; i++) Console.WriteLine(i * 7);` · `while (vida > 0) vida -= dano;` · `foreach (string item in inventario) Console.WriteLine(item);`
- **Coleções**: `List<int> pontos = [10, 20, 30];` · `pontos.Add(40);` · `int ultimo = pontos[^1];` · `var top3 = ranking[..3];` · `Dictionary<string, int> estoque = new() { ["poção"] = 3 };` · `if (estoque.TryGetValue("poção", out int qtd)) { }`
- **Métodos**: `static int Dobro(int x) => x * 2;` · `static (int Min, int Max) Faixa(int[] v) => (v.Min(), v.Max());` · `static void Curar(ref int hp, int qtd) => hp = Math.Min(hp + qtd, 100);`
- **Classes/records**: `public record Carta(string Naipe, int Valor);` · `public readonly record struct Posicao(int X, int Y);` · `public required string Nome { get; init; }` · `public class Inimigo(string nome, int vida) { }` · `var copia = carta with { Valor = 11 };`
- **Enum/tuplas**: `public enum Direcao { Norte, Sul, Leste, Oeste }` · `[Flags] public enum Poder { Nenhum = 0, Voo = 1, Forca = 2 }` · `(a, b) = (b, a);` · `var (x, y) = posicao;`
- **Null**: `string? apelido = null;` · `int tam = apelido?.Length ?? 0;` · `cache ??= CarregarDados();` · `if (jogador is not null) { }` · `jogador?.Pontos += 10;` (C# 14)
- **Patterns**: `if (obj is int n && n > 0) { }` · `bool ehVogal = c is 'a' or 'e' or 'i' or 'o' or 'u';` · `string r = dados switch { [6, 6] => "par de 6", [.., 1] => "termina em 1", _ => "-" };`
- **Exceções**: bloco `try { ... } catch (FormatException) { ... } finally { ... }` (6–8 linhas) · `throw new ArgumentOutOfRangeException(nameof(valor));` · `ArgumentNullException.ThrowIfNull(jogador);` · `using var leitor = new StreamReader("save.txt");`
- **Lambdas/LINQ**: `Func<int, bool> ehPar = n => n % 2 == 0;` · `var aprovados = notas.Where(n => n >= 7).ToList();` · `var nomes = jogadores.Select(j => j.Nome);` · `int total = itens.Sum(i => i.Preco);` · `var porTime = jogadores.GroupBy(j => j.Time);`
- **Async**: `string html = await http.GetStringAsync(url);` · `await Task.Delay(500);` · `int[] r = await Task.WhenAll(t1, t2);` · `static async Task<int> ContarAsync() { await Task.Delay(10); return 1; }`
- **Novidades**: `extension(string texto) { public int Palavras => texto.Split(' ').Length; }` · `set => field = Math.Max(0, value);` · `static int Somar(params ReadOnlySpan<int> v) { ... }` · `private readonly Lock _trava = new();` · `Console.WriteLine(nameof(List<>));`

### 4.2 Desafios de lógica (não são de digitação) — com gabarito verificado
**Prever a saída**
1. `int moedas = 7, jog = 2; Console.WriteLine(moedas / jog); Console.WriteLine(moedas % jog);` → `3` e `1`.
2. `Console.WriteLine(2 + 3 * 4); Console.WriteLine((2 + 3) * 4);` → `14` e `20`.
3. `Console.WriteLine("Nível " + 1 + 2); Console.WriteLine(1 + 2 + " vidas");` → `Nível 12` e `3 vidas`.
4. `int x = 5; int y = x++ + ++x; Console.WriteLine($"{x} {y}");` → `7 12`.
5. `string s = "pac"; s.ToUpper(); Console.WriteLine(s);` → `pac`.
6. `byte b = 250; b += 10; Console.WriteLine(b);` → `4`.
7. Struct × class: copiar `PontoS` e `PontoC`, alterar a cópia para 9 e imprimir os originais → `1 9`.
8. `record Item(string Nome, int Qtd)`: `new Item("Poção", 2) == new Item("Poção", 2)` → `True` (com `class` seria `False`).
9. `hp = 25` no `switch` de 2.4 → `crítico`.
10. Três lambdas criadas num `for (int i = 0; i < 3; i++)` e chamadas depois → `333`; com `foreach` sobre `{0,1,2}` → `012`.
11. `nums = [1,2,3]; var m = nums.Where(n => n > 1); nums.Add(4); Console.WriteLine(m.Count());` → `3`.
12. `Console.WriteLine(Math.Round(2.5)); Console.WriteLine(Math.Round(3.5));` → `2` e `4`.
13. `try { Write("A"); throw new InvalidOperationException(); } catch (InvalidOperationException) { Write("C"); } finally { Write("D"); } Write("E");` → `ACDE`.
14. `int[] dados = [6, 6, 1];` no switch `[6,6,6] → "trinca" | [6,6,_] → "dois 6" | [..,1] → "termina em 1"` → `dois 6` (1º braço que casa).
15. Iterador que imprime `A` antes do `yield return 1` e `B` antes do `yield return 2`; código: `var seq = Numeros(); Write("C"); foreach (int n in seq) Write(n);` → `CA1B2`.
16. Async: `Write("1"); Task t = EsperarAsync(); Write("3"); await t; Write("5");` com `EsperarAsync` = `Write("2"); await Task.Delay(100); Write("4");` → `12345`.
17. `Animal an = new Gato(); an.Som(); an.Nome();` (Som = override, Nome = new) → `Miau` e `Animal`.
18. `int x = 2; Console.WriteLine(x is not 1 or 2);` → `True` (precedência de `not`).

**Valor final da variável**
1. `pontos = 10; pontos += 5; pontos *= 2; pontos -= 3;` → `27`.
2. `energia = 100; for (i = 0; i < 4; i++) energia -= 15;` → `40`.
3. `List<int> f = [1,2,3]; f.Add(4); f.Remove(2); f.Insert(0, 9);` → `[9, 1, 3, 4]`.
4. `int? bonus = null; bonus ??= 50; bonus ??= 70;` → `50`.
5. `inv["poção"] = 3; inv["poção"] += 2;` (com `inv` já tendo "espada") → `Count = 2`, `inv["poção"] = 5`.
6. `total = 0; for (i = 0; i < 3; i++) for (j = i; j < 3; j++) total++;` → `6`.
7. Collatz de `n = 17` contando passos até 1 → `12` (intermediário).
8. `Curar(ref vida, 25)` com `vida = 90` e teto 100 → `100`.

**Completar a lacuna** (resposta entre parênteses)
`Console.WriteLine(__"Olá, {nome}!");` (`$`) · `List<string> itens = __;` lista vazia (`[]`) · `int.TryParse(txt, __ int v)` (`out`) · `public string Nome { get; __; }` só na criação (`init`) · `foreach (var (nome, pts) __ placar)` (`in`) · `int t = apelido?.Length __ 0;` (`??`) · `await __.WhenAll(t1, t2);` (`Task`) · base `public __ string Falar()` para permitir `override` (`virtual`) · `set => __ = Math.Max(0, value);` (`field`) · `__(string texto) { public int Tam => texto.Length; }` (`extension`) · `catch (FormatException ex) __ (ex.Message != "")` (`when`) · `nums.__(n => n > 0)` filtra (`Where`).

**Ordenar linhas**
1. Ler nome e cumprimentar: `Console.Write("Seu nome: ");` → `string? nome = Console.ReadLine();` → `nome ??= "anônimo";` → `Console.WriteLine($"Olá, {nome}!");`.
2. Classe: `public class Moeda` → `{` → `public int Valor { get; }` → `public Moeda(int valor) => Valor = valor;` → `}`.
3. Exceção: `try` → `{ int n = int.Parse(txt); }` → `catch (FormatException)` → `{ Console.WriteLine("inválido"); }` → `finally` → `{ Console.WriteLine("fim"); }`.
4. Async: assinatura `static async Task<int> TamanhoAsync(string url)` → `{` → `string html = await http.GetStringAsync(url);` → `return html.Length;` → `}`.
5. Arquivo top-level: `#!/usr/bin/env dotnet` → `#:property ...` → `using System.Text;` → instruções → `record`/`class` no fim.

**Achar o bug** — usar a tabela de diagnósticos da seção 3 (cada linha vira um desafio) e mais:
`for (int i = 0; i <= itens.Length; i++)` (estoura índice) · remover de `List` dentro do `foreach` · `throw ex;` (perde stack trace) · `lock (this)` · `async void SalvarAsync()` fora de handler · `var dados = CarregarAsync().Result;` · `record Mochila(List<string> Itens)` esperando igualdade de conteúdo · `x is not 1 or 2` querendo "nem 1 nem 2" · `double saldo` para dinheiro · `Math.Round(0.5)` esperando `1` · `string.Format` com cultura pt-BR gerando `3,5` num arquivo CSV.

**Escolha conceitual** (múltipla escolha)
Ponto 2D pequeno e imutável → `readonly record struct` · entrada do usuário → `TryParse` (não `Parse`) · concatenar 10 000 vezes → `StringBuilder` · teste de nulo → `is null` · I/O → `await` direto; cálculo pesado → `Task.Run` · estado compartilhado + construtor na base → classe abstrata; capacidade para tipos não relacionados → interface · entidade EF Core → `class` (não record) · valor fixo de compilação → `const`; calculado em runtime → `static readonly` · sequência pode estar vazia → `FirstOrDefault` · handler de clique assíncrono → `async void` com `try/catch` · tipo que não é seu e precisa de propriedade/operador novo → extension member (C# 14) · contar pontos de vários threads → `lock` com `Lock` · muitos `+=` em objeto grande imutável → operador `+=` de instância (C# 14) ou `record struct`.

### 4.3 Projetos "Mão na Massa" inspirados nos tutoriais oficiais (código sempre nosso)
- **Banco do herói** (tutorial *classes*/*oop*/*inheritance*): conta com número automático (`static`), extrato em `List<Transacao>` (record), exceções para depósito ≤ 0 e saque sem saldo, relatório com `StringBuilder`, subclasses com juros/limite (primary constructors + `override`).
- **Faro shuffle do baralho** (*working-with-linq*): naipes/valores com `yield`, baralho com `from ... from ...`, embaralhar com `Take/Skip` + método de extensão `Intercalar`, contar embaralhadas até voltar à ordem (8 no *out shuffle*), lazy × `ToArray()`.
- **Extrato em CSV com pattern matching** (tour *pattern-matching*): raw string com transações, `Split`, `TryParse`, enum, `switch` exaustivo, records `Deposito`/`Saque`.
- **Arte ASCII / utilitário de linha de comando** (*file-based-programs*): `args`, stdin (`Console.ReadLine() is string linha`), `#:package`, opções `--delay`.
- **Teleprompter assíncrono** (*console-teleprompter*) e **cliente REST** (*console-webapiclient*): `async`/`await`, `Task.Delay`, `HttpClient`, JSON.
- **Geometria com extensões** (*extension-members*): `Point.Origem`, operadores `+`/`-`, métodos de instância com receptor `ref`.
- **Catraca de show / placar** (*compound-assignment-operators*): `operator +=`/`++` de instância reduzindo alocações.
- **Ponto genérico** (*static-virtual-interface-members*): `Point<T>` com `INumber<T>`/`IAdditionOperators`.
- Temas de jogo para os desafios: HP/dano (`Math.Clamp`), inventário (`List`/`Dictionary`), cartas (records + LINQ), dados (`Random.Shared.Next(1, 7)` — saída não determinística: evite em "prever a saída"), mapa em grade (`char[,]` + `break`/`continue` rotulados só como prévia), estados do jogador (`enum` + `switch`), eventos (`Morreu`, `SubiuDeNivel`), save (`File.WriteAllText` + `using`).

## 5. URLs consultadas (abertas com WebFetch/curl em 27/09/2026)
- Sumários: https://learn.microsoft.com/en-us/dotnet/csharp/toc.json · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/toc.json
- Hub: https://learn.microsoft.com/en-us/dotnet/csharp/
- Tour: https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/overview · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/what-you-can-build · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/ · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/hello-world · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/numbers-in-csharp · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/tuples-and-types · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/branches-and-loops · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/list-collection · https://learn.microsoft.com/en-us/dotnet/csharp/tour-of-csharp/tutorials/pattern-matching
- File-based apps: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/file-based-programs · https://learn.microsoft.com/en-us/dotnet/core/sdk/file-based-apps
- Estrutura: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/ · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/top-level-statements · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/namespaces · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/preprocessor-directives · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/configure-language-version
- Tipos: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/ · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/built-in-types · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/classes · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/structs · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/records · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/interfaces · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/enums · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/generics · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/tuples · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/conversions · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/delegates-lambdas · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/built-in-types · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/ref-struct · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/union
- Null safety: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/ · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/null-operators · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/null-safety/nullable-reference-types
- Strings: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/ · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/raw-string-literals · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/strings/interpolation
- Patterns: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/pattern-matching · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/relational-logical-patterns · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/list-patterns · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/patterns/property-positional-patterns
- Expressões/instruções: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/expressions/operators · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/expressions/equality · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/selection · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/iteration · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/collections · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/statements/linq · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/arithmetic-operators · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/member-access-operators · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/collection-expressions · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/lambda-expressions · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/lock · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/using · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/method-parameters
- OOP: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/object-oriented/objects · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/object-oriented/inheritance · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/object-oriented/polymorphism · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/tutorials/classes · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/partial-member · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/field · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/keywords/extension · https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/extension-methods · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/interface-implementation/static-virtual-interface-members
- Exceções e estilo: https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/exception-handling · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/creating-and-throwing-exceptions · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions · https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/identifier-names
- Conceitos/LINQ/async: https://learn.microsoft.com/en-us/dotnet/csharp/iterators · https://learn.microsoft.com/en-us/dotnet/csharp/modern-events · https://learn.microsoft.com/en-us/dotnet/csharp/linq/standard-query-operators/ · https://learn.microsoft.com/en-us/dotnet/csharp/linq/standard-query-operators/join-operations · https://learn.microsoft.com/en-us/dotnet/csharp/tutorials/working-with-linq · https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/ · https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/async-scenarios
- Avançado: https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/reflection-and-attributes/ · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/expression-trees/ · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/performance/
- Novidades: https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-12 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-13 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15 · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-version-history · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/primary-constructors · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/extension-members · https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/compound-assignment-operators · https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/proposals/csharp-14.0/partial-events-and-constructors
- API: https://learn.microsoft.com/en-us/dotnet/api/system.math.round?view=net-10.0 · https://learn.microsoft.com/en-us/dotnet/api/system.linq.enumerable.leftjoin?view=net-10.0 (via busca)
- Suporte/ciclo de vida: https://devblogs.microsoft.com/dotnet/dotnet-8-9-end-of-support/ · https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core (via busca)
