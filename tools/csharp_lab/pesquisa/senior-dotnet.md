# Dossiê de pesquisa — frente `senior-dotnet` (PAC·C#)

> Tópicos sênior de C#/.NET: performance e memória, concorrência/async, metaprogramação, interop e Native AOT, segurança (OWASP em ASP.NET Core), observabilidade, testes avançados e o que cai em entrevista sênior.
> Pesquisa feita em **27/09/2026** em fontes primárias (Microsoft Learn, devblogs .NET, OWASP, docs oficiais das bibliotecas). Código de exemplo é nosso; fontes usadas para conferir cobertura, ordem e boas práticas.

## 0. Versões, convenções e como usar este dossiê

- **Base estável do curso: .NET 10 (LTS, nov/2025) + C# 14.** Novidades do C# 14 que aparecem aqui: `field` em propriedades, atribuição null-condicional (`jogador?.Vidas = 5`, `j?.Vidas -= 3`), `nameof(List<>)` → `"List"`, extension members (`extension(Tipo t) { ... }`), conversões implícitas de `Span`, modificadores em lambdas simples, construtores/eventos `partial`.
- **C# 13 / .NET 9** trouxe o que mais usamos nesta frente: `System.Threading.Lock`, `params` com Span/coleções, `ref struct` implementando interface + `allows ref struct`, `ref`/Span em métodos async/iteradores (desde que não cruzem `await`/`yield`), propriedades `partial` (usadas por `[GeneratedRegex]`).
- **Em prévia: .NET 11 (pacotes em RC1 em set/2026) + C# 15** (union types, `closed`, extension indexers, `break`/`continue` rotulados, `[with(...)]` em collection expressions, novo modelo de memory safety). **Não usar C# 15 em exercícios obrigatórios**; no máximo como "curiosidade/prévia".
- **Selo [verificado]**: o trecho foi compilado e executado com SDK .NET 10.0.102 (runtime 10.0.2, macOS arm64) em projetos descartáveis (`pesquisa/_verificacao-senior-dotnet/`), e as saídas nos comentários são as reais. **[verificado .NET 9]**: idem com SDK 9.0.112. **[doc]**: adaptado de exemplo oficial, não executado aqui. **[ilustrativo]**: fragmento com tipos inventados só para ler.
- Versões NuGet resolvidas em 27/09/2026 (para os geradores não inventarem): Microsoft.Extensions.* **10.0.12**; Microsoft.Extensions.Diagnostics.Testing e .TimeProvider.Testing **10.10.0**; xunit.v3 **4.0.1** (+ xunit.runner.visualstudio 4.0.0, Microsoft.NET.Test.Sdk 18.10.1); NSubstitute **6.2.0**; Moq **4.21.0**; BenchmarkDotNet **0.15.8**; OpenTelemetry **1.19.x**; NetArchTest.Rules **1.3.2**; Microsoft.CodeAnalysis.CSharp 4.14.0 (fixada por nós no teste do gerador — confira a mais nova). O dossiê passa de 900 linhas porque a seção 2 traz ~40 trechos completos e verificados; as seções 1, 3, 4 e 5 são o "índice" rápido.
- Níveis: **I** iniciante · **M** intermediário · **A** avançado · **S** sênior. Cada bloco lista pré-requisitos; desafios de lógica só podem usar o que a trilha (e as anteriores) ensinou.

### Sugestão de fatiamento desta frente em trilhas (≈12 das ~48)

| # | Trilha sugerida | Nível | Tópicos |
|---|---|---|---|
| S1 | Memória: valor x referência, boxing, GC | M→A | A1–A10 |
| S2 | Span, Memory, stackalloc e pools | A→S | A11–A16 |
| S3 | Strings e coleções rápidas + BenchmarkDotNet | A | A17–A21 |
| S4 | Async de verdade (await, exceções, contexto) | M→A | B1–B7 |
| S5 | Cancelamento, timeouts, ValueTask | A→S | B8–B10, B19 |
| S6 | Sincronização e coleções concorrentes | A | B11–B14 |
| S7 | Produtor/consumidor, paralelismo e async streams | A→S | B15–B18 |
| S8 | Atributos, reflection, expression trees, source generators | A→S | C1–C6 |
| S9 | Interop, trimming e Native AOT | S | C7–C10 |
| S10 | Segurança em ASP.NET Core (OWASP 2025) | A→S | D1–D13 |
| S11 | Observabilidade (logs, métricas, traces, health) | A→S | E1–E8 |
| S12 | Testes avançados + revisão de entrevista sênior | A→S | F1–F11, seção 5 |

---

## 1. Árvore de tópicos em ordem didática

### Bloco A — Memória, tipos e runtime
Pré-req: classes, structs, arrays, `List<T>`, LINQ básico, exceções, `using`.

- **A1. Valor x referência; pilha x heap** (M) — struct copia o valor na atribuição/passagem; class copia a referência; arrays de struct guardam os valores "inline" (melhor localidade). https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/choosing-between-class-and-struct
- **A2. Quando criar um struct** (A) — só se: representa um valor único, tem < 16 bytes, é imutável e raramente sofre boxing; senão, class. Mesma fonte + https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/struct
- **A3. Boxing e unboxing** (M) — converter valor para `object`/interface aloca no heap e copia; unboxing exige o tipo exato (senão `InvalidCastException`; `null` → `NullReferenceException`). https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/types/boxing-and-unboxing
- **A4. `readonly struct`, membros `readonly`, `record struct`, `with`** (A) — imutabilidade evita cópias defensivas; `default(T)` e arrays ignoram o construtor sem parâmetros. URL do A2.
- **A5. Passagem por referência: `ref`, `in`, `ref readonly`, `out`, ref return, `scoped`** (A) — evitar cópia de structs grandes com segurança verificada pelo compilador ("ref safe context"). https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/performance/
- **A6. GC: heap gerenciado, gerações 0/1/2, promoção** (A) — objetos novos nascem na gen0; sobreviventes sobem; coletar a gen2 = "full GC"; fases: marcar → realocar → compactar; gatilhos: pouca memória física, limite de alocação, `GC.Collect`. https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/fundamentals
- **A7. LOH (objetos ≥ 85.000 bytes)** (A) — quase sempre arrays; coletado junto com a gen2 e normalmente não compactado → fragmentação; a cura é reaproveitar (pools). URL do A6.
- **A8. Workstation x Server GC, background GC, DATAS** (S) — Server GC: um heap e uma thread de GC por CPU lógica, foco em vazão (em ASP.NET o host decide o padrão); DATAS adapta o heap ao tamanho real da app (opt-in no .NET 8, ligado por padrão no .NET 9). https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/workstation-server-gc · https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/datas
- **A9. `IDisposable`, `using`, padrão Dispose, finalizadores, `SafeHandle`** (M→A) — Dispose idempotente; `GC.SuppressFinalize`; `Dispose(bool)` só em classes não seladas; finalizador só com recurso não gerenciado direto (prefira `SafeHandle`); finalizador vazio custa desempenho; .NET 5+ **não** roda finalizadores ao encerrar o processo. https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/implementing-dispose · https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/finalizers
- **A10. `IAsyncDisposable` / `await using`** (A) — `DisposeAsync` retorna `ValueTask`; classe não selada expõe `protected virtual ValueTask DisposeAsyncCore()`; implemente também `IDisposable` (quem só chama `Dispose` vazaria). https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/implementing-disposeasync
- **A11. `Span<T>` / `ReadOnlySpan<T>`** (A) — janela sobre memória contígua (array, string, stackalloc, nativa) sem copiar; `Slice`, ranges `[..]`, parse sem alocar. https://learn.microsoft.com/en-us/dotnet/standard/memory-and-spans/memory-t-usage-guidelines
- **A12. `ref struct` e suas restrições** (A) — não pode ser elemento de array, campo de classe, ser capturado por lambda, cruzar `await`/`yield`, nem virar interface (boxing). https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/ref-struct
- **A13. `Memory<T>`, `IMemoryOwner<T>` e as 10 regras** (S) — `Memory<T>` pode ir para o heap e atravessar `await`; conceitos de dono/consumidor/"lease"; quem tem `IMemoryOwner` descarta **ou** transfere (nunca os dois). URL do A11.
- **A14. `stackalloc`** (A) — buffer na pilha, fora do GC; use com `Span<T>`, sempre com limite e fallback para o heap; nunca dentro de laço; conteúdo inicial indefinido; estouro → `StackOverflowException`. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/stackalloc
- **A15. `ArrayPool<T>`** (A) — `Rent(n)` devolve array com tamanho **≥ n** (vimos 16 para 10) e que pode vir sujo; `Return` no `finally`; nunca usar após devolver; esquecer de devolver não é fatal, só piora desempenho. https://learn.microsoft.com/en-us/dotnet/api/system.buffers.arraypool-1 · https://learn.microsoft.com/en-us/dotnet/api/system.buffers.arraypool-1.rent
- **A16. `ObjectPool<T>` (Microsoft.Extensions.ObjectPool)** (S) — só para objetos caros de criar, recurso limitado e uso frequente; `IResettable`/`PooledObjectPolicy`; o pool limita o que **retém**, não o que aloca; medir antes. https://learn.microsoft.com/en-us/aspnet/core/performance/objectpool
- **A17. Strings de alta performance** (M→A) — imutáveis; `StringBuilder` em laços; `StringComparison.Ordinal/OrdinalIgnoreCase` explícito; `ToUpperInvariant` para normalizar; problema do "I turco"; `TryWrite` em Span e `string.Create`. https://learn.microsoft.com/en-us/dotnet/standard/base-types/stringbuilder · https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- **A18. `SearchValues<T>`** (A) — conjunto pré-otimizado para `IndexOfAny`/`ContainsAny`; `char`/`byte` desde o .NET 8, `string` (só Ordinal/OrdinalIgnoreCase) desde o .NET 9; guarde em `static readonly`. https://learn.microsoft.com/en-us/dotnet/api/system.buffers.searchvalues-1 · https://learn.microsoft.com/en-us/dotnet/api/system.buffers.searchvalues.create
- **A19. Coleções congeladas** (A) — `FrozenDictionary`/`FrozenSet` (.NET 8): caras de criar, lookup muito rápido; ideais para tabelas fixas carregadas no startup (só com chaves confiáveis). https://learn.microsoft.com/en-us/dotnet/api/system.collections.frozen.frozendictionary-2
- **A20. Medir antes de otimizar: BenchmarkDotNet** (A) — `[Benchmark]`, `[MemoryDiagnoser]`, `[Params]`, `[GlobalSetup]`, `Baseline = true`; só em Release, sem debugger, devolvendo o resultado (evita eliminação de código morto); colunas Mean/Error/StdDev/Gen0/Allocated/Ratio. https://benchmarkdotnet.org/articles/overview.html · https://benchmarkdotnet.org/articles/guides/good-practices.html
- **A21. O que o runtime já otimiza + ferramentas** (S) — JIT do .NET 10: arrays pequenos de tamanho fixo e delegates que não escapam vão para a pilha (escape analysis), desvirtualização de interfaces de array → microbenchmarks mudam entre versões. Diagnóstico: `dotnet-counters`, `dotnet-trace`, `dotnet-dump`, `dotnet-gcdump`, `dotnet-stack`, `dotnet-monitor`. https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10/runtime · https://learn.microsoft.com/en-us/dotnet/core/diagnostics/tools-overview

### Bloco B — Assíncrono e concorrência
Pré-req: A1–A10, delegates/lambdas, LINQ, exceções, `Task` básico.

- **B1. Thread x Task x ThreadPool** (M) — Task é abstração de nível mais alto sobre o pool (balanceamento, espera, cancelamento, continuações, exceções); TPL é a API preferida. Não use o pool para bloqueios longos, threads foreground, prioridade ou STA. https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/task-based-asynchronous-programming · https://learn.microsoft.com/en-us/dotnet/standard/threading/the-managed-thread-pool
- **B2. O que roda síncrono num método async** (M) — tudo até o primeiro `await` de algo incompleto; exceções ficam guardadas na Task e saem no `await` [verificado].
- **B3. "Async all the way"** (M) — `await` em vez de `.Wait()/.Result`; `Task.WhenAny/WhenAll` em vez de `WaitAny/WaitAll`; `Task.Delay` em vez de `Thread.Sleep`. https://learn.microsoft.com/en-us/archive/msdn-magazine/2013/march/async-await-best-practices-in-asynchronous-programming
- **B4. `async void`** (A) — só para event handlers; a exceção vai direto para o `SynchronizationContext` (o `try/catch` de quem chamou não pega); lambda async passada para `Action` vira async void. Mesma fonte + https://github.com/davidfowl/AspNetCoreDiagnosticScenarios/blob/master/AsyncGuidance.md
- **B5. Sync-over-async: deadlock e starvation** (A) — bloquear em UI/ASP.NET clássico trava (contexto de uma thread só); ASP.NET Core não tem `SynchronizationContext` (não trava assim), mas bloquear esgota o thread pool e continuações podem rodar em paralelo. https://blog.stephencleary.com/2012/07/dont-block-on-async-code.html · https://blog.stephencleary.com/2017/03/aspnetcore-synchronization-context.html
- **B6. `SynchronizationContext`, `TaskScheduler`, `ConfigureAwait(false)`** (A/S) — use `ConfigureAwait(false)` em biblioteca de uso geral, não em código de app/UI; não garante mudar de contexto se a Task já terminou. `ConfigureAwaitOptions` (.NET 8): `ContinueOnCapturedContext`, `SuppressThrowing`, `ForceYielding`. https://devblogs.microsoft.com/dotnet/configureawait-faq/ · https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.configureawaitoptions
- **B7. Exceções com tasks** (A) — `await` relança só a primeira; `.Wait()/.Result` embrulham em `AggregateException`; no `WhenAll` todas ficam em `tarefa.Exception.InnerExceptions` (não dependa da ordem: no .NET 10 vimos ordem de término); tarefa não observada escala via `UnobservedTaskException`. https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/exception-handling-task-parallel-library
- **B8. Cancelamento cooperativo** (A) — CTS cria/cancela, o token é repassado; `ThrowIfCancellationRequested`; `Register` (callbacks rodam em ordem inversa); tokens vinculados (`CreateLinkedTokenSource`); timeout com `CancelAfter`/construtor; descarte o CTS; token cancelado não volta atrás. https://learn.microsoft.com/en-us/dotnet/standard/threading/cancellation-in-managed-threads
- **B9. Utilidades modernas** (A) — `Task.WaitAsync(TimeSpan|CancellationToken)` (.NET 6), `PeriodicTimer` (.NET 6), `TimeProvider` (.NET 8), `Task.WhenEach` (.NET 9), `Random.Shared` (thread-safe, .NET 6). https://learn.microsoft.com/en-us/dotnet/standard/datetime/timeprovider-overview · https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.task.wheneach · https://learn.microsoft.com/en-us/dotnet/api/system.random.shared
- **B10. `ValueTask` / `ValueTask<T>`** (S) — o padrão continua `Task`; use quando completar síncrono é comum e alocação importa; **nunca** aguardar duas vezes, aguardar em paralelo ou chamar `GetAwaiter().GetResult()` antes de completar; `.AsTask()` se precisar reusar. https://devblogs.microsoft.com/dotnet/understanding-the-whys-whats-and-whens-of-valuetask/
- **B11. `lock`, `Monitor` e `System.Threading.Lock`** (A) — .NET 9/C# 13: trave um `Lock` dedicado (o compilador usa `EnterScope()`); converter `Lock` para `object` volta ao Monitor (aviso CS9216); é reentrante [verificado]; nunca trave `this`, `Type` ou strings; seção curta; `await` dentro de `lock` não compila (CS1996). https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/lock
- **B12. `Interlocked`** (A) — `x++` não é atômico (ler-somar-gravar); `Increment`/`Add` devolvem o **novo** valor; `Exchange`/`CompareExchange` devolvem o valor **original** (CAS). https://learn.microsoft.com/en-us/dotnet/api/system.threading.interlocked
- **B13. `SemaphoreSlim`** (A) — exclusão/limite com `await WaitAsync()` + `Release()` no `finally`; sem afinidade de thread (não sabe "quem" entrou — pareamento é responsabilidade sua); ótimo para limitar N chamadas simultâneas. https://learn.microsoft.com/en-us/dotnet/api/system.threading.semaphoreslim
- **B14. Coleções concorrentes** (A) — `ConcurrentDictionary`: leitura sem lock, escrita com lock fino; `GetOrAdd(chave, fábrica)` roda a fábrica **fora** do lock e pode rodá-la várias vezes → use `Lazy<T>`; `AddOrUpdate` para contadores. https://learn.microsoft.com/en-us/dotnet/api/system.collections.concurrent.concurrentdictionary-2.getoradd
- **B15. Channels (produtor/consumidor)** (S) — `Channel.CreateBounded/Unbounded`, backpressure, `BoundedChannelFullMode` (Wait, DropNewest, DropOldest, DropWrite), `SingleReader/SingleWriter`, `Complete()`, `ReadAllAsync`, padrão `WaitToReadAsync` + `TryRead`. https://learn.microsoft.com/en-us/dotnet/core/extensions/channels
- **B16. Paralelismo de dados** (A) — `Parallel.For/ForEach` para CPU; `Parallel.ForEachAsync` (.NET 6) e `Parallel.ForAsync` (.NET 8) executam no máximo `Environment.ProcessorCount` por padrão; ajuste `MaxDegreeOfParallelism`. https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.parallel.foreachasync · https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.parallel.forasync
- **B17. PLINQ** (A) — `AsParallel`, `AsOrdered` (tem custo), `WithDegreeOfParallelism`, `WithCancellation`, `ForAll`; trabalho barato ou coleção pequena fica mais lento; algumas "formas" de consulta caem para sequencial; exceções em `AggregateException`. https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/introduction-to-plinq · https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/understanding-speedup-in-plinq
- **B18. Async streams (`IAsyncEnumerable<T>`)** (A) — `async` + `yield return`, `await foreach`, `[EnumeratorCancellation]` + `WithCancellation`, `ConfigureAwait`; descarte assíncrono do enumerador. https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/generate-consume-asynchronous-stream
- **B19. Receitas do guia do David Fowler** (S) — `Task.FromResult` (ou `ValueTask`) para valor pronto; trabalho longo bloqueante em thread dedicada/`LongRunning`; `TaskCompletionSource` com `RunContinuationsAsynchronously`; descartar CTS de timeout; sempre repassar token; `await using` em `StreamWriter`; fábrica async em vez de `.Result` no construtor; `AsyncLocal` só com dados imutáveis. URL do B4.

### Bloco C — Metaprogramação, interop e AOT
Pré-req: bloco A, generics, interfaces, `partial`, LINQ.

- **C1. Atributos** (M) — metadados declarativos; parâmetros posicionais (construtor) x nomeados (propriedades/campos); alvos (`[return:]`, `[assembly:]`, `[field:]`); `AttributeUsage`; sufixo "Attribute" opcional ao usar. https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/reflection-and-attributes/
- **C2. Reflection** (A) — `GetType()/typeof`, `GetProperties()` (públicas por padrão), `GetCustomAttribute<T>()`, `Activator.CreateInstance`, `PropertyInfo.SetValue`; custa caro e atrapalha trimming/AOT. URL do C1.
- **C3. `UnsafeAccessor`** (S) — .NET 8: acessa membro privado sem reflection (o runtime resolve; amigo de AOT); genéricos a partir do .NET 9. https://learn.microsoft.com/en-us/dotnet/api/system.runtime.compilerservices.unsafeaccessorattribute
- **C4. Expression trees** (A/S) — `Expression<Func<...>>` = código como dado (EF Core traduz para SQL; Moq inspeciona); o compilador só gera a partir de lambdas de expressão (sem bloco, `await`, `?.`, `is`, tuplas, interpolação, collection expressions...); imutáveis; `Compile()`; em Native AOT são interpretadas (mais lentas). https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/expression-trees/ · https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/expression-trees/expression-trees-building
- **C5. Source generators — consumir** (A) — geram código na compilação (acrescentam, nunca alteram o seu): `[GeneratedRegex]` (.NET 7; em propriedade parcial no .NET 9), `[LoggerMessage]`, `JsonSerializerContext`, `[LibraryImport]`. https://learn.microsoft.com/en-us/dotnet/standard/base-types/regular-expression-source-generators · https://learn.microsoft.com/en-us/dotnet/core/extensions/logger-message-generator · https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/source-generation
- **C6. Source generators — escrever** (S) — `IIncrementalGenerator` (o `ISourceGenerator` v1 está obsoleto); pipeline com cache (`Select/Where/Collect`); `ForAttributeWithMetadataName` (~99x mais eficiente que `CreateSyntaxProvider`); `RegisterPostInitializationOutput` para o atributo marcador; projeto `netstandard2.0` com `LangVersion` moderna e `EnforceExtendedAnalyzerRules` [verificado]. https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.md · https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/
- **C7. Interop nativo (P/Invoke)** (S) — `DllImport` gera stub IL em runtime (ruim para AOT); `LibraryImport` (.NET 7) gera o marshalling na compilação: método `static partial`, `StringMarshalling`, exige `AllowUnsafeBlocks`; `SafeHandle` para handles; Span + `fixed` para buffers síncronos, `Memory<T>.Pin` para assíncronos. https://learn.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke-source-generation
- **C8. Trimming** (S) — remove código não usado; avisos como IL2026 (`[RequiresUnreferencedCode]`, propague até a API pública), `[DynamicallyAccessedMembers]`; `UnconditionalSuppressMessage`/`DynamicDependency` só como último recurso; prefira geradores. https://learn.microsoft.com/en-us/dotnet/core/deploying/trimming/prepare-libraries-for-trimming
- **C9. Native AOT** (S) — `<PublishAot>true</PublishAot>` + `dotnet publish -r <RID> -c Release`; startup rápido, menos memória, sem JIT, roda sem runtime instalado; limitações: sem `Assembly.LoadFile`, sem `Reflection.Emit`, sem C++/CLI, sem COM embutido no Windows, trimming obrigatório, arquivo único, expressions interpretadas, binário maior por instâncias genéricas; `IsAotCompatible` liga os analisadores. https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/
- **C10. JSON sem reflection** (A) — `[JsonSerializable]` + `JsonSerializerContext`; `JsonSerializerIsReflectionEnabledByDefault=false` faz o código com reflection falhar cedo e claro. URL de JSON source gen (C5).

### Bloco D — Segurança (OWASP em ASP.NET Core)
Pré-req: minimal APIs, DI, configuração, EF Core básico, autenticação básica.

- **D1. OWASP Top 10:2025** (A) — A01 Broken Access Control (agora inclui SSRF) · A02 Security Misconfiguration · A03 Software Supply Chain Failures (novo) · A04 Cryptographic Failures · A05 Injection · A06 Insecure Design · A07 Authentication Failures · A08 Software or Data Integrity Failures · A09 Security Logging & Alerting Failures · A10 Mishandling of Exceptional Conditions (novo). https://top10.owasp.org/2025/0x00_2025-Introduction
- **D2. Controle de acesso** (A) — `[Authorize]`/policies em todo endpoint externo; checar se o recurso pertence ao usuário (IDOR); nunca mudar estado em GET. https://cheatsheetseries.owasp.org/cheatsheets/DotNet_Security_Cheat_Sheet.html
- **D3. Injeção de SQL com EF Core** (M/A) — `FromSql`/`ExecuteSql`/`SqlQuery` com interpolação viram `DbParameter` (seguros); `FromSqlRaw`/`ExecuteSqlRaw` com concatenação = injeção; nomes de coluna não são parametrizáveis → lista branca. https://learn.microsoft.com/en-us/ef/core/querying/sql-queries
- **D4. XSS** (A) — Razor codifica tudo que sai com `@`; `HtmlString`/`Html.Raw` com dado do usuário = XSS; dados para JS via atributo `data-*`; `HtmlEncoder`/`JavaScriptEncoder`/`UrlEncoder` via DI; codificar na saída, nunca guardar codificado; validação sozinha não basta. https://learn.microsoft.com/en-us/aspnet/core/security/cross-site-scripting
- **D5. CSRF/XSRF** (A) — risco quando a autenticação é por cookie (o navegador envia sozinho); bearer token no header não; `[AutoValidateAntiforgeryToken]` em apps com views; minimal APIs (.NET 8): `AddAntiforgery` + `UseAntiforgery`, validado ao ligar dados de formulário; `DisableAntiforgery` só sem cookie/sem navegador; .NET 11 (prévia) traz proteção automática via `Sec-Fetch-Site`. https://learn.microsoft.com/en-us/aspnet/core/security/anti-request-forgery
- **D6. Senhas** (A) — nunca hash rápido (MD5/SHA-256) para senha. OWASP: Argon2id (m = 19 MiB, t = 2, p = 1) primeiro; scrypt (N = 2^17, r = 8, p = 1); bcrypt (custo ≥ 10, máx. 72 bytes); PBKDF2-HMAC-SHA256 600.000 iterações / HMAC-SHA512 220.000; salt único por usuário; pepper opcional. `PasswordHasher<T>` do Identity: PBKDF2-HMAC-SHA512, salt 128 bits, subchave 256 bits, **100.000** iterações por padrão (configurável via `PasswordHasherOptions.IterationCount`) [verificado]. https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html · https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/consumer-apis/password-hashing
- **D7. Criptografia do dia a dia** (S) — nunca inventar cripto; `RandomNumberGenerator` para sal/chave/nonce; AES-GCM com nonce novo a cada cifragem; comparar segredos com `CryptographicOperations.FixedTimeEquals`. Cheat sheet do D2.
- **D8. Data Protection API** (S) — `IDataProtectionProvider.CreateProtector("propósito")`, `Protect/Unprotect`; propósitos isolam consumidores; chaves geridas e rotacionadas automaticamente; payload inválido → `CryptographicException`; protetores são thread-safe. https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/introduction · https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/using-data-protection
- **D9. Segredos** (M) — nada em código/`appsettings.json` versionado; dev: `dotnet user-secrets` (não criptografa; fica no perfil do usuário); variáveis de ambiente com `__` como separador; produção: cofre (ex.: Azure Key Vault). https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets
- **D10. Borda: HTTPS, HSTS, rate limiting, HttpClient** (A) — `UseHttpsRedirection`; `UseHsts` fora de dev (padrão 30 dias); API não deve redirecionar HTTP→HTTPS, deve recusar; rate limiting (fixed/sliding window, token bucket, concurrency; 429); cuidado ao particionar por dado controlado pelo usuário; `HttpClient` reutilizado (estático com `PooledConnectionLifetime` ou `IHttpClientFactory`). https://learn.microsoft.com/en-us/aspnet/core/security/enforcing-ssl · https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit · https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines
- **D11. Desserialização insegura** (A) — `BinaryFormatter` nunca é seguro com dado não confiável e, desde o .NET 9, lança exceção ao ser usado; a doc cita justamente **arquivos de save de jogo compartilhados** como vetor de ataque; use System.Text.Json. https://learn.microsoft.com/en-us/dotnet/standard/serialization/binaryformatter-security-guide
- **D12. Cadeia de suprimentos (A03:2025)** (A) — NuGet Audit no restore (avisos NU1901–NU1904; `NuGetAuditMode=all` é padrão para `net10.0`), `dotnet list package --vulnerable --include-transitive`, `dotnet package update --vulnerable` (SDK .NET 10). https://learn.microsoft.com/en-us/nuget/concepts/auditing-packages
- **D13. Erros e logs seguros (A09/A10)** (A) — não vazar stack trace em produção (`UseExceptionHandler`); registrar falhas de autenticação; nunca logar dados sensíveis (há redaction em `Microsoft.Extensions.Compliance.Redaction`); não engolir exceção. Cheat sheet do D2 + URL do E3.

### Bloco E — Observabilidade
Pré-req: DI, ASP.NET Core, async, `IDisposable`.

- **E1. `ILogger<T>`, categorias e níveis** (M) — categoria = nome completo da classe; Trace(0), Debug(1), Information(2), Warning(3), Error(4), Critical(5), None(6); padrão Information; filtros por categoria no `appsettings.json`; métodos de log são síncronos (nada de log async). https://learn.microsoft.com/en-us/dotnet/core/extensions/logging/overview
- **E2. Logging estruturado** (A) — template com placeholders nomeados (a associação é por **posição**, não por nome); os valores viram campos pesquisáveis; nunca interpolar/concatenar (regra CA2254); exceção como argumento; `EventId`; `BeginScope`. https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca2254
- **E3. `[LoggerMessage]` (source-gen)** (A/S) — método `partial void`; menos boxing/alocação; nomes sem `_`; se estático, recebe `ILogger`; no .NET 9 pode usar o logger do construtor primário; suporta nível dinâmico e redaction. https://learn.microsoft.com/en-us/dotnet/core/extensions/logger-message-generator
- **E4. Métricas (`System.Diagnostics.Metrics`)** (S) — `Meter` estático sem DI ou `IMeterFactory` com DI (.NET 8); `Counter`, `UpDownCounter`, `Histogram` (latência → percentis), `Gauge` (.NET 9), versões observáveis; nomes minúsculos com ponto e `_` (`pac.fantasmas_comidos`); unidades UCUM (`"s"`, `"{fantasma}"`); tags de baixa cardinalidade (< ~1000 combinações); `Add/Record` sem alocação até 3 tags; `MetricCollector<T>` em testes. https://learn.microsoft.com/en-us/dotnet/core/diagnostics/metrics-instrumentation · https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.metrics.gauge-1
- **E5. Tracing distribuído** (S) — `ActivitySource` estático (nome único + versão); `StartActivity` com `using` devolve `null` sem ouvinte → sempre `?.`; tags, eventos (poucos), `SetStatus(ActivityStatusCode.Error)`, `ActivityKind`, links; `IsAllDataRequested` para não calcular tag cara à toa. OTel chama ActivitySource de "Tracer" e Activity de "Span". https://learn.microsoft.com/en-us/dotnet/core/diagnostics/distributed-tracing-instrumentation-walkthroughs
- **E6. OpenTelemetry** (S) — .NET já traz as APIs (ILogger, Meter, ActivitySource); o OTel coleta e exporta (OTLP, Prometheus, Zipkin, Azure Monitor); bibliotecas dependem só de `System.Diagnostics.DiagnosticSource`; Aspire Dashboard é coletor de **desenvolvimento**. https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel · https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-otlp-example
- **E7. Health checks** (A) — `AddHealthChecks()` + `MapHealthChecks`; `IHealthCheck` → Healthy/Degraded/Unhealthy; readiness x liveness separados por tags/`Predicate`. https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks
- **E8. Diagnóstico em produção** (S) — escada: dotnet-counters → dotnet-stack → dotnet-trace → dotnet-gcdump → dotnet-dump; painel mínimo: taxa de requisições, erros, latência p99 e saturação (thread pool/GC). URL do A21 + https://codewithmukesh.com/blog/senior-dotnet-developer-interview-questions/

### Bloco F — Testes avançados
Pré-req: xUnit básico (`[Fact]`, `Assert`), DI, async, interfaces.

- **F1. Boas práticas de teste unitário** (M) — rápido, isolado, repetível, auto-verificável; nome `Metodo_Cenario_Esperado`; Arrange-Act-Assert; um Act por teste; `[Theory]` em vez de laço/if no teste; teste o privado via público; cobertura alta ≠ qualidade. https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices
- **F2. Stub x mock x fake** (A) — stub fornece dados; mock é o que você verifica no Assert; "fake" é o termo genérico. URL do F1.
- **F3. xUnit v3** (A) — testes viram executáveis (`dotnet run` roda); Microsoft Testing Platform; `TestContext.Current` (inclui `CancellationToken`); `Assert.Skip/SkipUnless/SkipWhen`; testes `Explicit`; `TheoryDataRow`. No SDK .NET 10, `dotnet test` com projeto MTP exige `global.json` com `"test": { "runner": "Microsoft.Testing.Platform" }` [verificado]. https://xunit.net/docs/getting-started/v3/whats-new
- **F4. NSubstitute e Moq** (A) — NSubstitute: `Substitute.For<I>()`, `.Returns`, `Received/DidNotReceive`, `Arg.Any/Arg.Is` (use com interfaces/membros virtuais; instale NSubstitute.Analyzers). Moq: `Setup/Returns/Verify`, `It.IsAny`. Histórico: Moq 4.20.0 embutiu o SponsorLink (hash SHA-256 de e-mail) e a 4.20.2 removeu. https://nsubstitute.github.io/help/getting-started/ · https://github.com/devlooped/moq/releases/tag/v4.20.2
- **F5. Tempo testável** (A) — injete `TimeProvider`; em teste, `FakeTimeProvider` (Microsoft.Extensions.TimeProvider.Testing) + `Advance(...)`. URL do B9.
- **F6. Testar logs e métricas** (S) — `FakeLogger<T>` e `MetricCollector<T>` (pacote Microsoft.Extensions.Diagnostics.Testing) [verificado]. URL do E4.
- **F7. Integração com `WebApplicationFactory<Program>`** (A/S) — `IClassFixture`, `CreateClient`, `WithWebHostBuilder` + `ConfigureTestServices` para trocar serviços, fábrica própria com `ConfigureWebHost`; no .NET 10 `Program` já é público (sem `public partial class Program {}`) [verificado]. https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests
- **F8. Testcontainers** (S) — banco/fila reais e descartáveis em Docker (`Testcontainers.PostgreSql`, `MsSql`, `Redis`, `RabbitMq`...); integração xUnit v3 via `Testcontainers.XunitV3` (`ContainerFixture`/`ContainerTest`). https://dotnet.testcontainers.org/ · https://dotnet.testcontainers.org/test_frameworks/xunit_net/ · https://dotnet.testcontainers.org/modules/postgres/
- **F9. Testes de arquitetura** (S) — NetArchTest.Rules (`Types.InAssembly(...).That().ResideInNamespace(...).ShouldNot().HaveDependencyOn(...)`) e ArchUnitNET (`TngTech.ArchUnitNET.xUnit`). https://github.com/BenMorris/NetArchTest · https://github.com/TNG/ArchUnitNET
- **F10. Asserções e licenças** (A) — FluentAssertions 8 virou licença comercial (Xceed, ~US$ 130/dev/ano; a 7.x segue Apache 2.0); alternativas: AwesomeAssertions (fork) e Shouldly — ou o `Assert` do xUnit. https://www.infoq.com/news/2025/01/fluent-assertions-v8-license/
- **F11. Validar DI no teste** (A) — `ValidateScopes`/`ValidateOnBuild` pegam "dependência cativa" (scoped dentro de singleton) [verificado]. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/service-lifetimes

---

## 2. Exemplos de código de referência (para os geradores)

### 2.1 Memória e tipos

```csharp
// [verificado] boxing copia; unboxing exige o tipo exato
int vidas = 123;
object caixa = vidas;          // boxing
vidas = 456;
Console.WriteLine(caixa);      // 123
object o = 42;
// long l = (long)o;           // InvalidCastException em runtime
long ok = (int)o;              // unbox para int e depois converte: 42
```

```csharp
// [verificado] struct copia valor; readonly record struct compara por valor
// (em Program.cs, as instruções vêm antes das declarações de tipo)
var p = new PontoMutavel { X = 1 };
var q = p;
q.X = 5;
Console.WriteLine(p.X);                    // 1

var a = new Posicao(1, 2);
var c = a with { X = 5 };
Console.WriteLine(a == new Posicao(1, 2)); // True
Console.WriteLine(c);                      // Posicao { X = 5, Y = 2 }

struct PontoMutavel { public int X; }
public readonly record struct Posicao(int X, int Y);
```

```csharp
// [verificado] new() x default(T) em struct com construtor sem parâmetros
public readonly struct Medida
{
    public Medida() { Valor = double.NaN; Descricao = "Indefinida"; }
    public double Valor { get; init; }
    public string Descricao { get; init; }
    public override string ToString() => $"{Valor} ({Descricao})";
}
// new Medida() → "NaN (Indefinida)" | default(Medida) → "0 ()" | new Medida[2] → "0 (); 0 ()"
```

```csharp
// [verificado .NET 9] padrão Dispose para classe base (não selada)
public class RecursoBase : IDisposable
{
    private bool _descartado;
    private Stream? _arquivo = new MemoryStream();

    public void Dispose()
    {
        Dispose(disposing: true);
        GC.SuppressFinalize(this);
    }

    protected virtual void Dispose(bool disposing)
    {
        if (_descartado) return;          // idempotente
        if (disposing)
        {
            _arquivo?.Dispose();          // gerenciados só quando disposing == true
            _arquivo = null;
        }
        // não gerenciados (se houver) seriam liberados aqui
        _descartado = true;
    }
}

// [verificado .NET 9] classe selada: basta repassar
public sealed class ConexaoPlacar : IAsyncDisposable
{
    private readonly Stream _rede = new MemoryStream();
    public ValueTask DisposeAsync() => _rede.DisposeAsync();
}
// await using var conexao = new ConexaoPlacar();
```

```csharp
// [verificado] ordem de descarte: inversa à criação
using (var a = new Recurso("A"))
using (var b = new Recurso("B"))
{
    Console.Write("corpo; ");
}
// saída: corpo; Dispose B; Dispose A;

sealed class Recurso(string nome) : IDisposable
{
    private bool _descartado;
    public void Dispose()
    {
        if (_descartado) return;
        _descartado = true;
        Console.Write($"Dispose {nome}; ");
    }
}
```

```csharp
// [verificado] gerações e LOH (objeto mantido vivo com GC.KeepAlive)
var obj = new object();
Console.Write(GC.GetGeneration(obj));   // 0
GC.Collect();
Console.Write(GC.GetGeneration(obj));   // 1
GC.Collect();
Console.Write(GC.GetGeneration(obj));   // 2
GC.KeepAlive(obj);
Console.WriteLine(GC.GetGeneration(new byte[100_000])); // 2 (LOH é coletado com a gen2)
Console.WriteLine(GC.GetGeneration(new byte[1_000]));   // 0
```

### 2.2 Span, stackalloc e pools

```csharp
// [verificado] Span não copia: é uma janela
ReadOnlySpan<char> codigo = "PAC-DART-2026";
Console.WriteLine(codigo.Slice(4, 4).ToString()); // DART
Console.WriteLine(codigo[9..].ToString());        // 2026

int[] mapa = { 1, 2, 3, 4 };
Span<int> meio = mapa.AsSpan(1, 2);
meio[0] = 9;
Console.WriteLine(string.Join(",", mapa));        // 1,9,3,4

// [verificado .NET 9 e 10] parse sem alocar substrings
ReadOnlySpan<char> linha = "10;20;30";
int soma = 0;
foreach (Range faixa in linha.Split(';'))
    soma += int.Parse(linha[faixa]);
Console.WriteLine(soma);                          // 60
```

```csharp
// [verificado] stackalloc com limite + ArrayPool com finally
const int LimitePilha = 256;
int n = 100;
Span<byte> buffer = n <= LimitePilha ? stackalloc byte[n] : new byte[n];
buffer.Fill(7);

byte[] alugado = ArrayPool<byte>.Shared.Rent(10);  // Length >= 10 (vimos 16)
try
{
    Span<byte> util = alugado.AsSpan(0, 10);         // use só o que pediu
    util.Clear();                                    // pode vir com dados antigos
}
finally
{
    ArrayPool<byte>.Shared.Return(alugado);          // depois disto, não toque mais nele
}
```

```csharp
// [verificado] ObjectPool (Microsoft.Extensions.ObjectPool) com IResettable
var provider = new DefaultObjectPoolProvider();
ObjectPool<Projetil> balas = provider.Create(new DefaultPooledObjectPolicy<Projetil>());
var bala = balas.Get();
try { bala.X = 50; /* dispara */ }
finally { balas.Return(bala); }            // TryReset() zera antes de voltar

ObjectPool<StringBuilder> sbs = provider.CreateStringBuilderPool(); // volta limpo

public sealed class Projetil : IResettable
{
    public int X { get; set; }
    public bool TryReset() { X = 0; return true; }
}
```

### 2.3 Strings e coleções rápidas

```csharp
// [verificado]
Console.WriteLine("Pac-Man".AsSpan().IndexOfAny(Buscas.Vogais));                     // 1
Console.WriteLine("o jogador usou SPAWN hoje".AsSpan().IndexOfAny(Buscas.Proibidas)); // 15

FrozenDictionary<string, int> poderes = new Dictionary<string, int> { ["fogo"] = 3, ["gelo"] = 2 }
    .ToFrozenDictionary(StringComparer.OrdinalIgnoreCase);
Console.WriteLine(poderes["FOGO"]);                                                   // 3

Console.WriteLine(string.Equals("Save.TXT", "save.txt", StringComparison.OrdinalIgnoreCase)); // True
Console.WriteLine(string.Equals("Save.TXT", "save.txt", StringComparison.Ordinal));           // False

Span<char> destino = stackalloc char[32];
if (destino.TryWrite($"Pontos: {1234:D6}", out int escritos))
    Console.WriteLine(destino[..escritos].ToString());                                // Pontos: 001234
string linhaDeX = string.Create(5, 'x', (span, ch) => span.Fill(ch));                // xxxxx

static class Buscas   // guarde SearchValues em static readonly
{
    public static readonly SearchValues<char> Vogais = SearchValues.Create("aeiouAEIOU");
    public static readonly SearchValues<string> Proibidas =
        SearchValues.Create(["spawn", "cheat"], StringComparison.OrdinalIgnoreCase); // .NET 9+
}
```

```csharp
// [verificado: compila] BenchmarkDotNet — rodar com: dotnet run -c Release
[MemoryDiagnoser]
public class ConcatBench
{
    [Params(10, 1000)]
    public int N;

    [Benchmark(Baseline = true)]
    public string Concatenar()
    {
        string s = "";
        for (int i = 0; i < N; i++) s += "a";
        return s;                       // devolver o resultado evita eliminação de código morto
    }

    [Benchmark]
    public string ComStringBuilder()
    {
        var sb = new StringBuilder();
        for (int i = 0; i < N; i++) sb.Append('a');
        return sb.ToString();
    }
}
// Program.cs: BenchmarkRunner.Run<ConcatBench>();
```

### 2.4 Async, exceções e cancelamento

```csharp
// [verificado] o que roda síncrono
Console.Write("A ");
Task t = FazAsync();
Console.Write("C ");
await t;
Console.WriteLine("E");          // A B C D E

static async Task FazAsync()
{
    Console.Write("B ");          // síncrono até o primeiro await incompleto
    await Task.Delay(50);
    Console.Write("D ");
}
```

```csharp
// [verificado] await relança só a primeira; todas ficam em Exception.InnerExceptions
Task todas = Task.WhenAll(Falha(1, new InvalidOperationException()),
                          Falha(80, new ArgumentException()));
try { await todas; }
catch (Exception ex)
{
    Console.WriteLine(ex.GetType().Name);                        // InvalidOperationException
    Console.WriteLine(todas.Exception!.InnerExceptions.Count);   // 2
}
// todas.Wait() lançaria AggregateException com 2 internas.
static async Task Falha(int ms, Exception ex) { await Task.Delay(ms); throw ex; }
```

```csharp
// [verificado] timeout, tokens vinculados, Register em ordem inversa
using var cts = new CancellationTokenSource(TimeSpan.FromMilliseconds(30));
try { await Task.Delay(1000, cts.Token); }
catch (OperationCanceledException ex) { Console.WriteLine(ex.GetType().Name); } // TaskCanceledException

using var pai = new CancellationTokenSource();
using var filho = CancellationTokenSource.CreateLinkedTokenSource(pai.Token);
filho.Cancel();
Console.WriteLine(pai.IsCancellationRequested);   // False (cancelar o filho não sobe)

using var sinal = new CancellationTokenSource();
sinal.Token.Register(() => Console.Write("1 "));
sinal.Token.Register(() => Console.Write("2 "));
sinal.Token.Register(() => Console.Write("3 "));
sinal.Cancel();                                    // 3 2 1
```

```csharp
// [verificado] utilidades modernas
await Task.Delay(500).WaitAsync(TimeSpan.FromMilliseconds(20));   // TimeoutException

var falha = Falha(10, new InvalidOperationException());
await falha.ConfigureAwait(ConfigureAwaitOptions.SuppressThrowing); // não lança; falha.Status == Faulted

Task<string>[] tarefas = [Espera(60, "lenta"), Espera(10, "rapida"), Espera(30, "media")];
await foreach (Task<string> pronta in Task.WhenEach(tarefas))       // .NET 9
    Console.Write(await pronta + " ");                             // rapida media lenta
static async Task<string> Espera(int ms, string nome) { await Task.Delay(ms); return nome; }
```

```csharp
// [verificado] ValueTask: caminho síncrono sem alocar Task
sealed class CacheDePontos
{
    private readonly Dictionary<string, int> _cache = new();

    public ValueTask<int> ObterAsync(string jogador)
    {
        if (_cache.TryGetValue(jogador, out var p))
            return ValueTask.FromResult(p);                 // 2ª chamada: IsCompletedSuccessfully == true
        return new ValueTask<int>(CarregarAsync(jogador));  // 1ª chamada: assíncrona
    }

    private async Task<int> CarregarAsync(string j)
    {
        await Task.Delay(10);
        _cache[j] = 100;
        return 100;
    }
}
// Consumir com um único await. Para reusar: var t = cache.ObterAsync("ana").AsTask();
```

```csharp
// [verificado] PeriodicTimer (loop de jogo) e TimeProvider (tempo testável)
using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(16));
int ticks = 0;
while (ticks < 3 && await timer.WaitForNextTickAsync()) ticks++;

public sealed class BonusDiario(TimeProvider tempo)
{
    private DateTimeOffset? _ultimo;
    public bool PodeResgatar() => _ultimo is null || tempo.GetUtcNow() - _ultimo >= TimeSpan.FromHours(24);
    public void Resgatar() => _ultimo = tempo.GetUtcNow();
}
```

### 2.5 Sincronização e coleções concorrentes

```csharp
// [verificado .NET 9] Lock + Interlocked + SemaphoreSlim
public sealed class Placar
{
    private readonly Lock _trava = new();          // C# 13 / .NET 9
    private int _pontos;
    private int _fantasmas;

    public void Somar(int valor)
    {
        lock (_trava) { _pontos += valor; }        // vira _trava.EnterScope()
    }

    public void FantasmaComido() => Interlocked.Increment(ref _fantasmas);
}

public sealed class Baixador
{
    private readonly SemaphoreSlim _limite = new(2);   // no máximo 2 ao mesmo tempo

    public async Task BaixarAsync(string url, CancellationToken ct)
    {
        await _limite.WaitAsync(ct);
        try { await Task.Delay(30, ct); /* chamada de rede */ }
        finally { _limite.Release(); }
    }
}
```

```csharp
// [verificado] Interlocked: valores de retorno
int x = 5;
int antigo = Interlocked.CompareExchange(ref x, 10, 5);  // x = 10, antigo = 5
antigo = Interlocked.CompareExchange(ref x, 20, 5);      // x continua 10, antigo = 10
int y = 1;
int velho = Interlocked.Exchange(ref y, 7);              // y = 7, velho = 1
int c = 0;
Console.WriteLine(Interlocked.Increment(ref c));         // 1 (devolve o NOVO valor)
```

```csharp
// [verificado] GetOrAdd + Lazy: a fábrica cara roda UMA vez com 50 threads
var cache = new ConcurrentDictionary<string, Lazy<int>>();
int chamadas = 0;
Parallel.For(0, 50, i =>
{
    _ = cache.GetOrAdd("chave", k => new Lazy<int>(() =>
    {
        Interlocked.Increment(ref chamadas);
        return 42;
    })).Value;
});
Console.WriteLine(chamadas);                              // 1

var contagem = new ConcurrentDictionary<int, int>();
Parallel.For(0, 10000, i => contagem.AddOrUpdate(1, 1, (k, velho) => velho + 1));
Console.WriteLine(contagem[1]);                           // 10000
```

### 2.6 Channels, paralelismo e async streams

```csharp
// [verificado] modos de canal cheio (capacidade 2, escrevendo 1, 2, 3 com TryWrite)
// Wait:       TryWrite(3) = False → lidos [1,2]
// DropNewest: TryWrite(3) = True  → lidos [1,3]  (descarta o mais novo que estava no canal)
// DropOldest: TryWrite(3) = True  → lidos [2,3]
// DropWrite:  TryWrite(3) = True  → lidos [1,2]  (o 3 é jogado fora, mas TryWrite diz True!)
var canal = Channel.CreateBounded<int>(new BoundedChannelOptions(2)
{
    FullMode = BoundedChannelFullMode.DropOldest
});
canal.Writer.TryWrite(1);
canal.Writer.TryWrite(2);
canal.Writer.TryWrite(3);
canal.Writer.Complete();                          // sem Complete o await foreach nunca termina
await foreach (var v in canal.Reader.ReadAllAsync())
    Console.Write(v);                             // 23
```

```csharp
// [ilustrativo] produtor/consumidor de eventos de jogo
Channel<EventoDeJogo> fila = Channel.CreateBounded<EventoDeJogo>(new BoundedChannelOptions(100)
{
    SingleReader = true,
    FullMode = BoundedChannelFullMode.Wait        // backpressure: o produtor espera
});
Task consumidor = Task.Run(async () =>
{
    await foreach (var e in fila.Reader.ReadAllAsync(ct))
        Aplicar(e);
});
foreach (var e in eventos)
    await fila.Writer.WriteAsync(e, ct);
fila.Writer.Complete();
await consumidor;
```

```csharp
// [verificado] paralelismo limitado, PLINQ ordenado, async stream com cancelamento
int total = 0;
await Parallel.ForEachAsync(Enumerable.Range(1, 10),
    new ParallelOptions { MaxDegreeOfParallelism = 3 },
    async (numero, ct) =>
    {
        await Task.Delay(1, ct);
        Interlocked.Add(ref total, numero);
    });
Console.WriteLine(total);                         // 55

int[] quadrados = Enumerable.Range(1, 8).AsParallel().AsOrdered().Select(v => v * v).ToArray();
// 1,4,9,16,25,36,49,64 (sem AsOrdered a ordem não é garantida)

static async IAsyncEnumerable<int> Contagem(int n,
    [EnumeratorCancellation] CancellationToken ct = default)
{
    for (int i = 1; i <= n; i++)
    {
        await Task.Delay(5, ct);
        yield return i;
    }
}
// await foreach (var v in Contagem(10).WithCancellation(cts.Token)) { if (v == 2) cts.Cancel(); }
// → lê 1 e 2 e depois lança OperationCanceledException
```

### 2.7 Metaprogramação

```csharp
// [verificado] atributo + reflection + UnsafeAccessor
var attr = typeof(Blinky).GetCustomAttribute<InimigoAttribute>()!;
Console.WriteLine($"{attr.Nome} vida={attr.Vida}");            // Fantasma Blinky vida=3
Console.WriteLine(string.Join(",", typeof(Blinky).GetProperties().Select(p => p.Name))); // X,Y
var blinky = new Blinky();
Acessos.Segredo(blinky) = 99;                                  // escreve no campo privado

[AttributeUsage(AttributeTargets.Class)]
sealed class InimigoAttribute(string nome) : Attribute
{
    public string Nome { get; } = nome;
    public int Vida { get; set; } = 100;           // parâmetro nomeado (init também funciona)
}

[Inimigo("Fantasma Blinky", Vida = 3)]
sealed class Blinky
{
    public int X { get; set; }
    public int Y { get; set; }
    private int segredo = 7;    // aviso CS0414 é esperado: o compilador não "vê" o UnsafeAccessor
}

static class Acessos
{
    [UnsafeAccessor(UnsafeAccessorKind.Field, Name = "segredo")]
    public static extern ref int Segredo(Blinky b);            // .NET 8+, sem reflection
}
```

```csharp
// [verificado] expression trees
Expression<Func<int, int, int>> soma = (a, b) => a + b;
Console.WriteLine(soma);                  // (a, b) => (a + b)
Console.WriteLine(soma.Body.NodeType);    // Add
Console.WriteLine(soma.Compile()(2, 3));  // 5

var x = Expression.Parameter(typeof(int), "x");
var dobro = Expression.Lambda<Func<int, int>>(Expression.Multiply(x, Expression.Constant(2)), x);
Console.WriteLine(dobro);                 // x => (x * 2)
Console.WriteLine(dobro.Compile()(21));   // 42
```

```csharp
// [verificado] geradores que o .NET já traz
static partial class Regras
{
    [GeneratedRegex(@"^[A-Z]{3}-\d{4}$")]
    public static partial Regex Placa { get; }          // propriedade parcial: C# 13 / .NET 9
}
// Regras.Placa.IsMatch("PAC-2026") → True ; "pac-2026" → False

public record Placar(string Jogador, int Pontos);

[JsonSerializable(typeof(Placar))]
internal partial class JogoJsonContext : JsonSerializerContext { }
// JsonSerializer.Serialize(new Placar("Ana", 1500), JogoJsonContext.Default.Placar)
// → {"Jogador":"Ana","Pontos":1500}

public static partial class Log
{
    [LoggerMessage(EventId = 100, Level = LogLevel.Information, Message = "Fase {Fase} concluída em {Tempo}")]
    public static partial void FaseConcluida(ILogger logger, int fase, TimeSpan tempo);
}
```

```csharp
// [verificado: compila] esqueleto de gerador incremental
// .csproj: netstandard2.0 + <LangVersion>latest</LangVersion> + <EnforceExtendedAnalyzerRules>true</EnforceExtendedAnalyzerRules>
//          + <IsRoslynComponent>true</IsRoslynComponent> + pacote Microsoft.CodeAnalysis.CSharp
[Generator]
public sealed class GeradorDeConstantes : IIncrementalGenerator
{
    public void Initialize(IncrementalGeneratorInitializationContext contexto)
    {
        var arquivos = contexto.AdditionalTextsProvider.Where(static f => f.Path.EndsWith(".txt"));
        var pares = arquivos.Select(static (texto, ct) => (
            nome: Path.GetFileNameWithoutExtension(texto.Path),
            conteudo: texto.GetText(ct)!.ToString()));
        contexto.RegisterSourceOutput(pares, static (spc, par) =>
            spc.AddSource($"Constantes.{par.nome}.g.cs",
                $"public static partial class Constantes {{ public const string {par.nome} = \"{par.conteudo}\"; }}"));
    }
}
```

### 2.8 Interop, trimming e AOT

```csharp
// [verificado] LibraryImport (macOS/Linux). .csproj: <AllowUnsafeBlocks>true</AllowUnsafeBlocks>
static partial class Nativo
{
    [LibraryImport("libc", EntryPoint = "getpid")]
    public static partial int GetPid();
}
// Nativo.GetPid() == Environment.ProcessId → True

// [verificado .NET 9: compila] anotações de trimming
public static class Plugins
{
    [RequiresUnreferencedCode("Usa reflection em tipos desconhecidos; prefira gerador de código.")]
    public static void CarregarPlugins() { }

    public static void UsarMetodos(
        [DynamicallyAccessedMembers(DynamicallyAccessedMemberTypes.PublicMethods)] Type tipo)
    {
        foreach (var m in tipo.GetMethods()) { _ = m.Name; }
    }
}
```

```xml
<!-- [doc] app Native AOT: dotnet publish -r linux-x64 -c Release -->
<PropertyGroup>
  <PublishAot>true</PublishAot>
  <JsonSerializerIsReflectionEnabledByDefault>false</JsonSerializerIsReflectionEnabledByDefault>
</PropertyGroup>
<!-- [doc] biblioteca: liga IsTrimmable + analisadores de trim, single-file e AOT -->
<PropertyGroup>
  <IsAotCompatible>true</IsAotCompatible>
</PropertyGroup>
```

### 2.9 Segurança

```csharp
// [doc] EF Core: interpolação vira DbParameter; concatenação crua = injeção
var jogadores = await db.Jogadores
    .FromSql($"SELECT * FROM Jogadores WHERE Nome = {nome}")
    .ToListAsync();
// NUNCA: db.Jogadores.FromSqlRaw("SELECT * FROM Jogadores WHERE Nome = '" + nome + "'")
```

```csharp
// [verificado] senhas: PasswordHasher do Identity (pacote Microsoft.Extensions.Identity.Core)
var hasher = new PasswordHasher<Usuario>();           // PBKDF2-HMAC-SHA512, 100.000 iterações
string hash = hasher.HashPassword(usuario, "S3nh@Forte!");
var r1 = hasher.VerifyHashedPassword(usuario, hash, "S3nh@Forte!"); // Success
var r2 = hasher.VerifyHashedPassword(usuario, hash, "errada");      // Failed
var forte = new PasswordHasher<Usuario>(   // using Microsoft.Extensions.Options;
    Options.Create(new PasswordHasherOptions { IterationCount = 220_000 })); // alinhado à OWASP p/ SHA-512

// [verificado] só BCL: PBKDF2 + comparação em tempo constante
byte[] sal = RandomNumberGenerator.GetBytes(16);
byte[] derivado = Rfc2898DeriveBytes.Pbkdf2("senha123", sal, 600_000, HashAlgorithmName.SHA256, 32);
bool iguais = CryptographicOperations.FixedTimeEquals(derivado, derivadoSalvo);
```

```csharp
// [verificado] AES-GCM: nonce novo a cada cifragem; tag adulterada falha
byte[] chave = RandomNumberGenerator.GetBytes(32);
byte[] nonce = RandomNumberGenerator.GetBytes(AesGcm.NonceByteSizes.MaxSize);   // 12 bytes
byte[] texto = Encoding.UTF8.GetBytes("save do jogo");
byte[] cifrado = new byte[texto.Length];
byte[] tag = new byte[16];
using var aes = new AesGcm(chave, tagSizeInBytes: 16);
aes.Encrypt(nonce, texto, cifrado, tag);
aes.Decrypt(nonce, cifrado, tag, texto);   // tag alterada → AuthenticationTagMismatchException

// [verificado] Data Protection: propósito isola
var services = new ServiceCollection();
services.AddDataProtection();
using var sp = services.BuildServiceProvider();
var protetor = sp.GetRequiredService<IDataProtectionProvider>().CreateProtector("PacCSharp.Save.v1");
string protegido = protetor.Protect("vidas=3;fase=7");
string original = protetor.Unprotect(protegido);   // "vidas=3;fase=7"
// CreateProtector("PacCSharp.Convite.v1").Unprotect(protegido) → CryptographicException
```

```csharp
// [verificado] borda de uma minimal API: rate limit, HSTS, antiforgery, health
// usings: Microsoft.AspNetCore.RateLimiting, Microsoft.AspNetCore.Diagnostics.HealthChecks,
//         Microsoft.Extensions.Diagnostics.HealthChecks
builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    o.AddFixedWindowLimiter("fixo", l =>
    {
        l.PermitLimit = 2;
        l.Window = TimeSpan.FromMinutes(1);
        l.QueueLimit = 0;
    });
});
builder.Services.AddHealthChecks().AddCheck<BancoHealthCheck>("banco", tags: ["ready"]);
builder.Services.AddAntiforgery();

var app = builder.Build();
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/erro");
    app.UseHsts();
}
app.UseHttpsRedirection();
app.UseRateLimiter();
app.UseAntiforgery();
app.MapGet("/placar", () => "ok").RequireRateLimiting("fixo");    // 3ª chamada no minuto → 429
app.MapHealthChecks("/healthz/ready", new HealthCheckOptions { Predicate = c => c.Tags.Contains("ready") });
app.MapHealthChecks("/healthz/live", new HealthCheckOptions { Predicate = _ => false });
```

```bash
# [doc] segredos em dev (não criptografa; fica no perfil do usuário)
dotnet user-secrets init
dotnet user-secrets set "Pagamentos:ChaveApi" "12345"
# [doc] cadeia de suprimentos
dotnet list package --vulnerable --include-transitive
```

### 2.10 Observabilidade

```csharp
// [verificado] logging estruturado + escopo + LoggerMessage
logger.LogInformation("Jogador {Jogador} fez {Pontos} pontos", "Ana", 1500);
// NÃO: logger.LogInformation($"Jogador {nome} fez {pontos} pontos");   // CA2254: perde os campos
using (logger.BeginScope("Partida {PartidaId}", 42))
{
    Log.FaseConcluida(logger, 3, TimeSpan.FromSeconds(12.5));
}
// console: info: Jogo[100]  => Partida 42  Fase 3 concluída em 00:00:12.5000000
```

```csharp
// [verificado] métricas com IMeterFactory (DI) — registre: services.AddMetrics(); AddSingleton<MetricasJogo>()
public sealed class MetricasJogo
{
    private readonly Counter<int> _comidos;

    public MetricasJogo(IMeterFactory fabrica)
    {
        var meter = fabrica.Create("PacCSharp.Jogo");
        _comidos = meter.CreateCounter<int>("pac.fantasmas_comidos", unit: "{fantasma}");
    }

    public void FantasmaComido(string nome) =>
        _comidos.Add(1, new KeyValuePair<string, object?>("pac.fantasma", nome)); // 4 fantasmas = baixa cardinalidade
}

// [verificado .NET 9] tracing: StartActivity devolve null sem ouvinte → use ?.
public static class Telemetria
{
    private static readonly ActivitySource Fonte = new("PacCSharp.Jogo", "1.0.0");

    public static void CarregarFase(int fase)
    {
        using Activity? atividade = Fonte.StartActivity("CarregarFase");
        atividade?.SetTag("fase.numero", fase);
        atividade?.AddEvent(new ActivityEvent("mapa carregado"));
        atividade?.SetStatus(ActivityStatusCode.Error, "arquivo corrompido");
    }
}
```

```csharp
// [verificado: compila e sobe nos testes de integração; o envio OTLP em si não foi exercitado]
// pacotes: OpenTelemetry.Extensions.Hosting, .Instrumentation.AspNetCore, .Instrumentation.Http,
//          .Exporter.OpenTelemetryProtocol ; usings: OpenTelemetry, .Metrics, .Resources, .Trace
builder.Services.AddOpenTelemetry()
    .ConfigureResource(r => r.AddService("pac-csharp-api"))
    .WithMetrics(m => m
        .AddAspNetCoreInstrumentation()
        .AddMeter("PacCSharp.Jogo"))
    .WithTracing(t => t
        .AddAspNetCoreInstrumentation()
        .AddHttpClientInstrumentation()
        .AddSource("PacCSharp.Jogo"))
    .UseOtlpExporter();   // endpoint via OTEL_EXPORTER_OTLP_ENDPOINT (a doc também mostra AddOtlpExporter por sinal)
// logs: builder.Logging.AddOpenTelemetry(l => { l.IncludeFormattedMessage = true; l.IncludeScopes = true; });
```

### 2.11 Testes

```csharp
// [verificado: compila] xUnit v3 + NSubstitute
public class TestesRanking
{
    [Fact]
    public void Nivel_PontosAcimaDeMil_RetornaOuro()
    {
        // Arrange
        var repo = Substitute.For<IRepositorioPlacar>();
        repo.ObterPontos("ana").Returns(1500);
        // Act
        var nivel = new ServicoRanking(repo).Nivel("ana");
        // Assert
        Assert.Equal("Ouro", nivel);
        repo.Received(1).ObterPontos("ana");
    }

    [Theory]
    [InlineData(999, "Bronze")]
    [InlineData(1000, "Ouro")]
    public void Nivel_VariosPontos_RetornaNivelCorreto(int pontos, string esperado)
    {
        var repo = Substitute.For<IRepositorioPlacar>();
        repo.ObterPontos(Arg.Any<string>()).Returns(pontos);
        Assert.Equal(esperado, new ServicoRanking(repo).Nivel("qualquer"));
    }
}
// Moq equivalente [verificado]: var mock = new Mock<IRepositorioPlacar>();
// mock.Setup(r => r.ObterPontos(It.IsAny<string>())).Returns(10); ... mock.Verify(r => r.ObterPontos("x"), Times.Once());
```

```csharp
// [verificado] tempo, logs e métricas falsos
var tempo = new FakeTimeProvider(new DateTimeOffset(2026, 9, 27, 12, 0, 0, TimeSpan.Zero));
var bonus = new BonusDiario(tempo);
bonus.Resgatar();                      // PodeResgatar() → False
tempo.Advance(TimeSpan.FromHours(24)); // PodeResgatar() → True

var fake = new FakeLogger<Jogo>();
fake.LogWarning("Vida baixa: {Vida}", 1);
// fake.LatestRecord.Level == Warning ; fake.LatestRecord.Message == "Vida baixa: 1"

var coletor = new MetricCollector<int>(meterFactory, "PacCSharp.Jogo", "pac.fantasmas_comidos");
metricas.FantasmaComido("Blinky");
// coletor.GetMeasurementSnapshot()[0].Tags["pac.fantasma"] == "Blinky"
```

```csharp
// [verificado: 3 testes passando no .NET 10] integração com WebApplicationFactory
public class ApiTests(WebApplicationFactory<Program> fabrica) : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task Placar_ComRelogioFalso_MostraHorarioFixo()
    {
        var client = fabrica.WithWebHostBuilder(b =>
                b.ConfigureTestServices(s => s.AddSingleton<IRelogio>(new RelogioFixo())))
            .CreateClient();

        var resposta = await client.GetStringAsync("/placar", TestContext.Current.CancellationToken);

        Assert.Equal("placar às 12:00", resposta);
    }
}
// global.json para `dotnet test` no SDK 10 com xUnit v3: { "test": { "runner": "Microsoft.Testing.Platform" } }
```

```csharp
// [verificado] arquitetura (NetArchTest) e DI (dependência cativa)
var resultado = Types.InAssembly(typeof(Fantasma).Assembly)
    .That().ResideInNamespace("Dominio")
    .ShouldNot().HaveDependencyOn("Infra")
    .GetResult();
// resultado.IsSuccessful ; resultado.FailingTypeNames lista os violadores

var services = new ServiceCollection();
services.AddScoped<Carrinho>();
services.AddSingleton<CacheGlobal>();          // CacheGlobal(Carrinho) → captura um scoped!
services.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true, ValidateOnBuild = true });
// → AggregateException com InvalidOperationException. Sem validação, o "scoped" vira singleton silenciosamente.
```

```csharp
// [doc] Testcontainers (xUnit v3): pacotes Testcontainers.PostgreSql + Testcontainers.XunitV3
public sealed class RedisContainerFixture(IMessageSink messageSink)
    : ContainerFixture<RedisBuilder, RedisContainer>(messageSink)
{
    protected override RedisBuilder Configure() => new RedisBuilder("redis:7.0");
}
// Teste: IClassFixture<RedisContainerFixture> e fixture.Container.GetConnectionString()
```

---

## 3. Armadilhas e boas práticas (o curso deve ensinar)

**Memória e performance**
- Otimize só **caminhos quentes** e só depois de medir (baseline → mudança → medir de novo). Pooling nem sempre ajuda: pegar do pool pode ser mais lento que alocar objeto barato.
- Struct grande e mutável é armadilha: cópias silenciosas (`var q = p; q.X = 5` não muda `p`); `lista[0].X = 5` com `List<struct>` nem compila (CS1612). Prefira `readonly struct`.
- Boxing escondido: `object`, interfaces não genéricas, `string.Concat(object...)`. Unboxing exige o tipo exato.
- `GC.Collect()` manual quase nunca: atrapalha as heurísticas (num jogo, travadinhas por frame).
- Arrays ≥ 85.000 bytes criados e descartados em sequência fragmentam o LOH → `ArrayPool<T>`.
- `ArrayPool`: o array pode ser **maior** e vir **sujo**; use só `[0..n]`; devolva no `finally`; nunca use depois de devolver nem devolva duas vezes.
- `stackalloc`: sempre com limite conservador e fallback para heap; nunca em laço; nunca devolver o Span (CS8352).
- Span não atravessa `await` (CS4007), não vai para lambda (CS8175), não é campo de classe (CS8345); `ReadOnlySpan` não aceita escrita (CS8331). Precisa guardar/atravessar `await`? `Memory<T>`.
- Finalizador só com recurso não gerenciado direto — e mesmo assim prefira `SafeHandle`. Nunca finalizador vazio. Não acesse objetos gerenciados dentro do finalizador.
- Dispose idempotente; quem **cria** (é dono) descarta; não descarte o que o container de DI criou.
- Strings: comparação sem `StringComparison` explícito é ambígua (algumas sobrecargas são culturais); não use `Compare(...) == 0` para igualdade; `ToUpperInvariant` para normalizar.
- BenchmarkDotNet: Release, sem debugger, devolvendo o resultado, máquina quieta; microbenchmark não é carga real — confirme com profiling.

**Async e concorrência**
- `async void` só em event handler; exceção derruba o processo em ASP.NET Core e não é pega pelo `try` do chamador.
- `.Result`, `.Wait()`, `.GetAwaiter().GetResult()` = sync-over-async: deadlock em UI/ASP.NET clássico e starvation do thread pool em ASP.NET Core. "Async all the way".
- `Task.Run` em ASP.NET Core para "deixar async" só troca uma thread por outra; não use para I/O.
- `Task.Factory.StartNew(async () => ...)` devolve `Task<Task>` (a interna não é aguardada) → use `Task.Run`.
- `TaskCompletionSource` sem `RunContinuationsAsynchronously` roda continuações inline na thread de quem completa.
- Repasse o `CancellationToken` a todas as APIs; descarte CTS (principalmente com timeout); `Cancel()` depois de `Dispose()` → `ObjectDisposedException`.
- Capturar `OperationCanceledException` (base de `TaskCanceledException`), não só `TaskCanceledException`.
- `ValueTask`: um único `await`; nada de guardar e aguardar de novo.
- `ConfigureAwait(false)` em biblioteca, não em app; nunca como "remédio" para bloquear em async.
- `lock`: objeto privado dedicado (`Lock` no .NET 9+); nunca `this`, `typeof(...)` ou string (strings literais são internadas: `ReferenceEquals("abc", "abc")` é True); nada de `await` dentro (use `SemaphoreSlim`).
- `x++` compartilhado entre threads perde incrementos (vimos 637.419 de 1.000.000) → `Interlocked`.
- `ConcurrentDictionary.GetOrAdd(fábrica)`: fábrica pode rodar várias vezes → `Lazy<T>`; não use `.Result` dentro da fábrica (cache a `Task`).
- Chamar uma API externa 500 vezes: `Parallel.ForEachAsync` com `MaxDegreeOfParallelism` ou `SemaphoreSlim`, não `Task.WhenAll` sem limite.
- Canal com `DropWrite`: `TryWrite` devolve True mesmo descartando o item. Sempre `Complete()` depois que **todos** os produtores terminarem.
- `Parallel`/PLINQ só para trabalho CPU de verdade; coleções pequenas/trabalho barato ficam mais lentos; `AsOrdered` custa.
- `HttpClient` novo por requisição esgota portas; `HttpClient` estático eterno ignora mudança de DNS → `PooledConnectionLifetime` ou `IHttpClientFactory`.
- Dependência cativa: singleton que recebe scoped (ex.: `DbContext`) → use `IServiceScopeFactory`; deixe `ValidateScopes`/`ValidateOnBuild` ligados.
- Lambda com um único `_` (`_ => _ * 2`) declara um **parâmetro** chamado `_`, não um descarte (descarte só com dois ou mais `_`).

**Metaprogramação, interop e AOT**
- Reflection é lenta e quebra com trimming/AOT: prefira geradores (`[GeneratedRegex]`, `[LoggerMessage]`, `JsonSerializerContext`, `[LibraryImport]`) e `UnsafeAccessor`.
- Expression trees não aceitam lambda com bloco, `await`, `?.`, `is`/`switch` de padrões, tuplas, interpolação — e no Native AOT viram interpretadas (lentas).
- Projeto de gerador: `netstandard2.0` com `LangVersion` moderna e `EnforceExtendedAnalyzerRules`; use o pipeline incremental (`ForAttributeWithMetadataName`), nunca o `ISourceGenerator` antigo.
- `UnconditionalSuppressMessage` só quando você **garante** que o membro é alvo visível de reflection; justificativa do tipo "o app usa essa propriedade" é inválida (a doc mostra isso).
- Antes de ligar `PublishAot`: zero avisos de trim/AOT; teste o binário publicado (o app depurado com JIT esconde quebras).

**Segurança**
- Nunca concatenar SQL; `FromSqlRaw` só com lista branca para nomes de coluna.
- `Html.Raw`/`HtmlString` com dado do usuário = XSS; codifique na saída, não no banco.
- Auth por cookie precisa de antiforgery; não mude estado em GET; `DisableAntiforgery` só em endpoint que não é chamado por navegador com cookie.
- Senha: nunca MD5/SHA-1/SHA-256 simples; use `PasswordHasher` (ajuste iterações) ou Argon2id/bcrypt/PBKDF2 com os parâmetros OWASP; compare com `FixedTimeEquals`.
- AES-GCM: nonce **nunca** se repete com a mesma chave; não invente modo/criptografia.
- Segredo no Git é incidente: `user-secrets` em dev, cofre em produção; env vars também são texto puro.
- `BinaryFormatter` (e SoapFormatter, NetDataContractSerializer, LosFormatter, ObjectStateFormatter): nunca. Save de jogo baixado da internet é entrada não confiável.
- API: não redirecione HTTP→HTTPS (cliente pode mandar segredo em claro antes); recuse.
- Rate limiting particionado por IP/usuário; cuidado com chaves ilimitadas vindas do usuário (memória/DoS).
- Não logue senha, token, CPF; não devolva stack trace em produção; não engula exceções (A10:2025).
- Rode NuGet Audit no CI (NU1901–NU1904) e trate vulneráveis transitivos.

**Observabilidade**
- Template de log constante, placeholders nomeados (posição importa), exceção como argumento, nada de interpolação; `IsEnabled` antes de montar argumento caro; `[LoggerMessage]` em caminho quente.
- `StartActivity` pode devolver `null` → `?.` sempre; poucos eventos por Activity (muito volume vai para log).
- Métrica com tag de alta cardinalidade (id de jogador/pedido) explode custo/memória do coletor → vá para log/trace.
- Latência é `Histogram` (olhe p95/p99), não média; contagem monotônica é `Counter`; fila/cache é `UpDownCounter`.
- Aspire Dashboard é ferramenta de dev, não monitoramento de produção.
- Health check: liveness barato (sem dependências); readiness verifica banco/fila.

**Testes**
- Sem lógica no teste (`if`/`for`) → `[Theory]`; um Act por teste; nomes que contam o comportamento.
- Não chame de "mock" o que é stub; asserte no mock, não no stub.
- `DateTime.Now`/`Random`/rede dentro da regra = teste instável → injete `TimeProvider` e interfaces.
- Unitário não toca infraestrutura; integração em projeto separado; banco em memória esconde diferenças de SQL real → Testcontainers.
- Mock só de interfaces/membros virtuais (NSubstitute executa código real de membros não virtuais).
- Licenças mudam: FluentAssertions 8 é comercial; Moq teve o episódio SponsorLink — avalie dependências de teste também.

---

## 4. Ideias de exercícios

### 4.1 Digitação curta (1–8 linhas), por tópico
Tema de jogo sempre que possível (PAC, fantasmas, fases, placar, save). Todas as linhas abaixo compilam no contexto indicado.

**Memória/Span/pools (S1–S3)**
1. `public readonly record struct Posicao(int X, int Y);`
2. `var proxima = atual with { X = atual.X + 1 };`
3. `object caixa = vidas; // boxing: cópia no heap`
4. `ReadOnlySpan<char> sigla = "PAC-DART".AsSpan(0, 3);`
5. `Span<int> pontos = stackalloc int[4];` + `pontos.Fill(0);`
6. `Span<byte> buffer = n <= 256 ? stackalloc byte[n] : new byte[n];`
7. `foreach (Range r in linha.Split(';')) soma += int.Parse(linha[r]);`
8. `byte[] alugado = ArrayPool<byte>.Shared.Rent(4096);` / `finally { ArrayPool<byte>.Shared.Return(alugado); }`
9. `ObjectPool<Projetil> balas = provider.Create(new DefaultPooledObjectPolicy<Projetil>());`
10. `public bool TryReset() { X = 0; Y = 0; return true; }`
11. `public void Dispose() { Dispose(true); GC.SuppressFinalize(this); }`
12. `if (_descartado) return;` / `_descartado = true;`
13. `await using var conexao = new ConexaoPlacar();`
14. `private static readonly SearchValues<char> Vogais = SearchValues.Create("aeiouAEIOU");`
15. `var itens = tabela.ToFrozenDictionary(StringComparer.OrdinalIgnoreCase);`
16. `if (string.Equals(extensao, ".json", StringComparison.OrdinalIgnoreCase))`
17. `destino.TryWrite($"Pontos: {pontos:D6}", out int escritos);`
18. `[MemoryDiagnoser] public class PlacarBench` / `[Params(10, 1000)] public int N;`
19. `[Benchmark(Baseline = true)] public string Concatenar() { ... }`
20. `BenchmarkRunner.Run<PlacarBench>();` (e o comando `dotnet run -c Release`)

**Async/cancelamento (S4–S5)**
21. `public async Task<int> CarregarPontosAsync(string jogador, CancellationToken ct = default)`
22. `int[] resultados = await Task.WhenAll(tarefaA, tarefaB);`
23. `using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));`
24. `using var vinculado = CancellationTokenSource.CreateLinkedTokenSource(ct, cts.Token);`
25. `ct.ThrowIfCancellationRequested();`
26. `catch (OperationCanceledException) when (ct.IsCancellationRequested) { return; }`
27. `await tarefa.WaitAsync(TimeSpan.FromSeconds(2), ct);`
28. `var tcs = new TaskCompletionSource<int>(TaskCreationOptions.RunContinuationsAsynchronously);`
29. `if (_cache.TryGetValue(id, out var p)) return ValueTask.FromResult(p);`
30. `await falha.ConfigureAwait(ConfigureAwaitOptions.SuppressThrowing);`
31. `using var timer = new PeriodicTimer(TimeSpan.FromMilliseconds(16));` / `while (await timer.WaitForNextTickAsync(ct)) AtualizarJogo();`
32. `public sealed class BonusDiario(TimeProvider tempo)`
33. `await foreach (var pronta in Task.WhenEach(tarefas)) Console.WriteLine(await pronta);`

**Sincronização/concorrência (S6–S7)**
34. `private readonly Lock _trava = new();` / `lock (_trava) { _pontos += valor; }`
35. `Interlocked.Increment(ref _fantasmasComidos);`
36. `int antigo = Interlocked.CompareExchange(ref _estado, 1, 0);`
37. `await _semaforo.WaitAsync(ct); try { ... } finally { _semaforo.Release(); }`
38. `var cache = new ConcurrentDictionary<string, Lazy<Mapa>>();`
39. `contagem.AddOrUpdate(fase, 1, (_, velho) => velho + 1);`
40. `var fila = Channel.CreateBounded<EventoDeJogo>(new BoundedChannelOptions(100) { FullMode = BoundedChannelFullMode.DropOldest });`
41. `await fila.Writer.WriteAsync(evento, ct);` / `fila.Writer.Complete();`
42. `await foreach (var e in fila.Reader.ReadAllAsync(ct)) Aplicar(e);`
43. `while (await leitor.WaitToReadAsync(ct)) while (leitor.TryRead(out var e)) Aplicar(e);`
44. `await Parallel.ForEachAsync(fases, new ParallelOptions { MaxDegreeOfParallelism = 4 }, async (fase, ct) => await GerarAsync(fase, ct));`
45. `var quadrados = numeros.AsParallel().AsOrdered().Select(n => n * n).ToArray();`
46. `public async IAsyncEnumerable<int> LerPlacarAsync([EnumeratorCancellation] CancellationToken ct = default)`

**Metaprogramação/AOT (S8–S9)**
47. `[AttributeUsage(AttributeTargets.Class)] sealed class InimigoAttribute(string nome) : Attribute`
48. `var attr = typeof(Blinky).GetCustomAttribute<InimigoAttribute>();`
49. `foreach (var p in typeof(Jogador).GetProperties()) Console.WriteLine(p.Name);`
50. `Expression<Func<int, int, int>> soma = (a, b) => a + b;`
51. `var dobro = Expression.Lambda<Func<int, int>>(Expression.Multiply(x, Expression.Constant(2)), x);`
52. `[GeneratedRegex(@"^[A-Z]{3}-\d{4}$")] private static partial Regex Placa { get; }`
53. `[JsonSerializable(typeof(Placar))] internal partial class JogoJsonContext : JsonSerializerContext { }`
54. `string json = JsonSerializer.Serialize(placar, JogoJsonContext.Default.Placar);`
55. `[UnsafeAccessor(UnsafeAccessorKind.Field, Name = "segredo")] static extern ref int Segredo(Blinky b);`
56. `[LibraryImport("libc", EntryPoint = "getpid")] public static partial int GetPid();`
57. `[RequiresUnreferencedCode("Usa reflection sobre tipos desconhecidos.")]`
58. `<PublishAot>true</PublishAot>` e `dotnet publish -r linux-x64 -c Release`
59. `public sealed class Gerador : IIncrementalGenerator` / `public void Initialize(IncrementalGeneratorInitializationContext contexto)`

**Segurança (S10)**
60. `var jogadores = await db.Jogadores.FromSql($"SELECT * FROM Jogadores WHERE Nome = {nome}").ToListAsync();`
61. `string hash = hasher.HashPassword(usuario, senha);`
62. `var resultado = hasher.VerifyHashedPassword(usuario, hash, tentativa);`
63. `byte[] sal = RandomNumberGenerator.GetBytes(16);`
64. `bool iguais = CryptographicOperations.FixedTimeEquals(hashA, hashB);`
65. `using var aes = new AesGcm(chave, tagSizeInBytes: 16);`
66. `var protetor = provider.CreateProtector("PacCSharp.Save.v1");`
67. `dotnet user-secrets set "Pagamentos:ChaveApi" "12345"`
68. `o.AddFixedWindowLimiter("fixo", l => { l.PermitLimit = 10; l.Window = TimeSpan.FromMinutes(1); });`
69. `app.MapGet("/placar", ObterPlacar).RequireRateLimiting("fixo");`
70. `if (!app.Environment.IsDevelopment()) { app.UseExceptionHandler("/erro"); app.UseHsts(); }`
71. `builder.Services.AddAntiforgery();` / `app.UseAntiforgery();`
72. `dotnet list package --vulnerable --include-transitive`

**Observabilidade (S11)**
73. `logger.LogInformation("Jogador {Jogador} fez {Pontos} pontos", nome, pontos);`
74. `using (logger.BeginScope("Partida {PartidaId}", partidaId))`
75. `[LoggerMessage(Level = LogLevel.Warning, Message = "Vida baixa: {Vida}")] static partial void VidaBaixa(ILogger logger, int vida);`
76. `private static readonly ActivitySource Fonte = new("PacCSharp.Jogo", "1.0.0");`
77. `using var atividade = Fonte.StartActivity("CarregarFase");` / `atividade?.SetTag("fase.numero", fase);`
78. `_comidos = meter.CreateCounter<int>("pac.fantasmas_comidos", unit: "{fantasma}");`
79. `var duracao = meter.CreateHistogram<double>("pac.fase.duracao", unit: "s");`
80. `builder.Services.AddHealthChecks().AddCheck<BancoHealthCheck>("banco", tags: ["ready"]);`
81. `.WithTracing(t => t.AddAspNetCoreInstrumentation().AddSource("PacCSharp.Jogo"))`
82. `dotnet-counters monitor -n PacCSharp --counters PacCSharp.Jogo`

**Testes (S12)**
83. `[Fact] public void Nivel_PontosAcimaDeMil_RetornaOuro()`
84. `[Theory] [InlineData(999, "Bronze")] [InlineData(1000, "Ouro")]`
85. `var repo = Substitute.For<IRepositorioPlacar>();` / `repo.ObterPontos("ana").Returns(1500);`
86. `repo.Received(1).ObterPontos("ana");`
87. `mock.Setup(r => r.ObterPontos(It.IsAny<string>())).Returns(10);`
88. `var tempo = new FakeTimeProvider();` / `tempo.Advance(TimeSpan.FromHours(24));`
89. `public class ApiTests(WebApplicationFactory<Program> fabrica) : IClassFixture<WebApplicationFactory<Program>>`
90. `b.ConfigureTestServices(s => s.AddSingleton<IRelogio>(new RelogioFixo()));`
91. `var ct = TestContext.Current.CancellationToken;`
92. `Types.InAssembly(typeof(Fantasma).Assembly).That().ResideInNamespace("Dominio").ShouldNot().HaveDependencyOn("Infra").GetResult();`
93. `services.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true, ValidateOnBuild = true });`

**Mini-projetos "Mão na Massa" desta frente (digitação longa)**: (a) `PoolDeProjeteis` com `ObjectPool` + benchmark de alocação; (b) `LeitorDeMapa` que faz parse de fase com `Span`/`Split` sem alocar; (c) `FilaDeEventos` com `Channel` limitado + consumidor + cancelamento; (d) `ServicoDeRanking` com `ConcurrentDictionary` + `Lazy` + métricas; (e) API mínima "Placar" com rate limit, health checks, OTel e testes com `WebApplicationFactory`; (f) `CofreDeSave` que cifra o save com AES-GCM e protege com Data Protection.

### 4.2 Desafios de lógica (não são de digitação) — com gabarito verificado
Formato sugerido: enunciado curto + código de 3–10 linhas + 4 alternativas (ou campo livre). Gabaritos marcados [v] foram executados.

**Prever a saída**
1. (A3) `int i = 123; object o = i; i = 456; Console.WriteLine(o);` → **123** [v]
2. (A1) struct `PontoMutavel` com `var q = p; q.X = 5; Console.WriteLine(p.X);` (p.X era 1) → **1**; com class → **5** [v]
3. (A11) `int[] a = {1,2,3,4}; Span<int> s = a.AsSpan(1,2); s[0] = 9;` imprime `string.Join(",", a)` → **1,9,3,4** [v]
4. (A11) `"PAC-DART-2026".AsSpan().Slice(4, 4).ToString()` → **DART** [v]
5. (A6) `GC.GetGeneration(obj)` antes e depois de dois `GC.Collect()` (obj vivo) → **0 → 1 → 2**; `GC.GetGeneration(new byte[100_000])` → **2** [v]
6. (B2) programa "A B C D E" da seção 2.4 → **A B C D E** [v]
7. (B2) `var t = FalhaImediata(); Console.Write("chamou; "); await t;` → imprime **"chamou; "** e só então lança no `await` (a Task já estava Faulted) [v]
8. (B7) `await Task.WhenAll(falhaRapida /*InvalidOperation*/, falhaLenta /*Argument*/)` no `catch (Exception ex)` → **InvalidOperationException**; `todas.Exception.InnerExceptions.Count` → **2** [v]
9. (B8) filho vinculado cancelado → `pai.IsCancellationRequested`? **False**; pai cancelado → filho? **True** [v]
10. (B8) três `Register` imprimindo 1, 2, 3 e `Cancel()` → **3 2 1** [v]
11. (B12) `int x = 5; Interlocked.CompareExchange(ref x, 10, 5); Interlocked.CompareExchange(ref x, 20, 5);` → x = **10** [v]
12. (B12) `int c = 0; Console.Write($"{Interlocked.Increment(ref c)} {Interlocked.Increment(ref c)}");` → **1 2** [v]
13. (B15) canal capacidade 2, `DropOldest`, `TryWrite(1,2,3)`, lê tudo → **2,3**; com `DropNewest` → **1,3**; com `DropWrite` → **1,2** (e `TryWrite(3)` = **True**); com `Wait` → `TryWrite(3)` = **False** [v]
14. (B9) `Task.WhenEach` com tarefas de 60/10/30 ms nomeadas lenta/rapida/media → **rapida, media, lenta** [v]
15. (B18) `await foreach` sobre `Contagem(10).WithCancellation(t)` cancelando quando `v == 2` → lê **1, 2** e depois lança **OperationCanceledException** [v]
16. (B17) `Enumerable.Range(1,8).AsParallel().AsOrdered().Select(x => x*x)` → **1,4,9,16,25,36,49,64** [v]
17. (M, closures) `for (int i = 0; i < 3; i++) acoes.Add(() => Console.Write(i));` executar todas → **333**; com `foreach (var j in new[]{0,1,2})` → **012** [v]
18. (M, LINQ) `var maiores = nums.Where(n => n > 1); nums.Add(10); maiores.Count()` com nums = {1,2,3} → **3** (execução adiada) [v]
19. (M, LINQ) `Select` com contador de execuções, percorrido duas vezes em `foreach` sobre 4 itens → **8** [v]
20. (C4) `Expression<Func<int,int,int>> soma = (a, b) => a + b; Console.WriteLine(soma);` → **(a, b) => (a + b)** [v]
21. (C2) `typeof(Blinky).GetProperties()` (X e Y públicas, `segredo` privado) → **X,Y** [v]
22. (B19) `AsyncLocal`: chamador põe "A", método async põe "B" e imprime; chamador imprime depois → **B** e depois **A** [v]
23. (A9) dois `using` aninhados A e B → **Dispose B; Dispose A;** [v]
24. (A3) `object o = 42; long l = (long)o;` → **InvalidCastException** [v]
25. (B10) `ValueTask` do cache: 1ª chamada `IsCompletedSuccessfully`? **False**; 2ª? **True** [v]
26. (C# 14) `nameof(List<>)` → **List**; `Jogador? j = null; j?.Vidas = 5;` → **nada acontece** (lado direito nem é avaliado) [v]
27. (E5) `StartActivity("Fase")` sem nenhum ouvinte → **null** [v]
28. (M) `Func<int,int> f = _ => _ * 2; f(21)` → **42** (o `_` é parâmetro) [v]
29. (A4) `new Medida()` x `default(Medida)` (seção 2.1) → **NaN (Indefinida)** x **0 ()** [v]
30. (B8) `cts.Dispose(); cts.Cancel();` → **ObjectDisposedException** [v]
31. (B13) `SemaphoreSlim(2)` com 6 tarefas de 30 ms → pico de simultâneas **2** [v]
32. (D6) `VerifyHashedPassword` com senha errada → **Failed** [v]
33. (D8) `Unprotect` com protetor de outro propósito → **CryptographicException** [v]
34. (D7) AES-GCM com um byte da tag alterado → **AuthenticationTagMismatchException** (é uma `CryptographicException`) [v]
35. (A17) `string s = "abc"; s.ToUpper(); Console.WriteLine(s);` → **abc** [v]

**Completar a lacuna**
36. `Span<byte> buf = n <= 256 ? ____ byte[n] : new byte[n];` → `stackalloc`
37. `finally { ArrayPool<byte>.Shared.____(buffer); }` → `Return`
38. `public void Dispose() { Dispose(true); GC.____(this); }` → `SuppressFinalize`
39. `____ using var conexao = new ConexaoPlacar();` (IAsyncDisposable) → `await`
40. `Interlocked.____(ref _pontos, bonus);` (somar atômico) → `Add`
41. `await _semaforo.____(ct);` → `WaitAsync`
42. `var canal = Channel.____<int>(10);` (com limite) → `CreateBounded`
43. `async IAsyncEnumerable<int> Ler([____] CancellationToken ct = default)` → `EnumeratorCancellation`
44. `private readonly ____ _trava = new();` (.NET 9) → `Lock`
45. `new TaskCompletionSource<int>(TaskCreationOptions.____)` → `RunContinuationsAsynchronously`
46. `new ParallelOptions { ____ = 4 }` → `MaxDegreeOfParallelism`
47. `[____(@"^\d{3}$")] private static partial Regex TresDigitos { get; }` → `GeneratedRegex`
48. `<____>true</____>` (publicar nativo) → `PublishAot`
49. `db.Jogadores.____($"... WHERE Nome = {nome}")` (seguro) → `FromSql`
50. `logger.LogInformation(____, nome);` sem quebrar logging estruturado → `"Jogador {Jogador} entrou"`
51. `.WithTracing(t => t.____("PacCSharp.Jogo"))` → `AddSource`
52. `repo.____(1).ObterPontos("ana");` (NSubstitute) → `Received`
53. `tempo.____(TimeSpan.FromHours(24));` (FakeTimeProvider) → `Advance`

**Ordenar as linhas**
54. ArrayPool: `byte[] b = ArrayPool<byte>.Shared.Rent(1024);` → `try {` → `Usar(b.AsSpan(0, 1024));` → `} finally {` → `ArrayPool<byte>.Shared.Return(b);` → `}`
55. `Dispose(bool)`: `if (_descartado) return;` → `if (disposing) { _arquivo?.Dispose(); }` → `// liberar não gerenciados` → `_descartado = true;`
56. Produtor/consumidor: criar canal → iniciar consumidor (`Task.Run` + `await foreach`) → escrever itens → `Writer.Complete()` → `await consumidor;`
57. Timeout: `using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(2));` → `try {` → `await BaixarAsync(cts.Token);` → `} catch (OperationCanceledException) {` → `Console.WriteLine("demorou");` → `}`
58. Pipeline HTTPS (doc): `UseExceptionHandler` → `UseHsts` → `UseHttpsRedirection` → `UseStaticFiles` → `UseRouting` → `UseAuthorization` → `MapRazorPages`
59. Teste AAA: criar substituto e `Returns` → criar serviço → chamar método → `Assert.Equal` → `Received`
60. OTel: `AddOpenTelemetry()` → `ConfigureResource(...)` → `WithMetrics(...)` → `WithTracing(...)` → exportador

**Achar o bug** (resposta = problema + correção)
61. `async void SalvarAsync()` chamado dentro de `try/catch` → exceção escapa do `catch` e pode derrubar o processo; use `async Task` + `await`.
62. `var dados = ObterAsync().Result;` num controller → bloqueio (starvation no ASP.NET Core; deadlock em UI) → `await`.
63. `lock (this)` / `lock ("placar")` → trava pública/internada; use `private readonly Lock _trava = new();`.
64. `lock (_trava) { await SalvarAsync(); }` → não compila (CS1996); use `SemaphoreSlim(1,1)` com `WaitAsync`.
65. `Parallel.For(0, 1_000_000, _ => contador++);` → incrementos perdidos; `Interlocked.Increment(ref contador)`.
66. `using var client = new HttpClient();` a cada requisição → esgota portas; `IHttpClientFactory` ou estático com `PooledConnectionLifetime`.
67. `var cts = new CancellationTokenSource(TimeSpan.FromSeconds(10));` sem `using` → timer pendurado; `using`.
68. `var vt = cache.ObterAsync("ana"); var a = await vt; var b = await vt;` → `ValueTask` aguardado duas vezes; aguarde uma vez ou `.AsTask()`.
69. `for (...) { Span<byte> tmp = stackalloc byte[1024]; ... }` com milhares de voltas → risco de estouro de pilha; aloque fora do laço.
70. `static Span<int> Criar() { Span<int> s = stackalloc int[3]; return s; }` → não compila (CS8352); devolva array ou receba o Span por parâmetro.
71. Span usado depois de `await` → CS4007; use `Memory<T>` ou termine de usar o Span antes do `await`.
72. `List<PontoMutavel> l; l[0].X = 5;` → CS1612; `var p = l[0]; p.X = 5; l[0] = p;` (ou use class/readonly struct).
73. `ReadOnlySpan<char> ro = "abc"; ro[0] = 'x';` → CS8331 (somente leitura).
74. `db.Jogadores.FromSqlRaw($"SELECT * FROM Jogadores WHERE Nome = '{nome}'")` → SQL injection; `FromSql($"... {nome}")`.
75. `var hash = SHA256.HashData(Encoding.UTF8.GetBytes(senha));` para guardar senha → hash rápido; `PasswordHasher`/Argon2id/PBKDF2 com parâmetros OWASP.
76. `logger.LogInformation($"Jogador {nome} entrou");` → CA2254, perde os campos; template com `{Jogador}`.
77. `@Html.Raw(comentario.Texto)` → XSS; `@comentario.Texto`.
78. `"ChaveApi": "sk-..."` no `appsettings.json` versionado → vazamento; `user-secrets`/env/cofre (e revogar a chave!).
79. `new BinaryFormatter().Deserialize(arquivoDoSave)` → RCE; e no .NET 9+ lança exceção; use System.Text.Json.
80. `services.AddSingleton<CacheGlobal>()` com `CacheGlobal(AppDbContext db)` → dependência cativa; `IServiceScopeFactory`; `ValidateScopes`.
81. `cache.GetOrAdd(id, id => CarregarMapaCaro(id))` sob concorrência → carrega várias vezes; `Lazy<Mapa>`.
82. `Task.Factory.StartNew(async () => await SalvarAsync())` aguardado → só espera a Task externa; `Task.Run`.
83. `Fonte.StartActivity("x").SetTag("a", 1);` → `NullReferenceException` sem ouvinte; `?.`.
84. `contador.Add(1, new("jogador.id", jogadorId));` → alta cardinalidade; tag de baixa cardinalidade ou mova para log/trace.
85. Teste que chama `DateTime.Now` na regra de "bônus diário" → instável; injete `TimeProvider` e use `FakeTimeProvider`.
86. `Lock trava = new(); object o = trava; lock (o) { }` → aviso CS9216 (volta ao Monitor); trave o `Lock` diretamente.
87. `catch (Exception) { }` vazio no processamento de pagamento → A10:2025; trate exceções específicas, logue e falhe fechado.
88. `GC.Collect();` a cada frame do jogo → travadas; remova e reduza alocações (pools/structs).

**Valor final da variável**
89. `var sb = new StringBuilder(); for (int i = 0; i < 3; i++) sb.Append(i).Append('-'); sb.Length--;` → **"0-1-2"** [v]
90. `int y = 1; int velho = Interlocked.Exchange(ref y, 7);` → y = **7**, velho = **1** [v]
91. `long total = 0; long novo = Interlocked.Add(ref total, 50);` → novo = **50** [v]
92. `Parallel.ForEachAsync` somando 1..10 com `Interlocked.Add` → **55** [v]
93. `AddOrUpdate(1, 1, (k, v) => v + 1)` 10.000 vezes em paralelo → **10000** [v]
94. `new Lazy<string>(...)` lido por 20 threads → fábrica executada **1** vez [v]
95. `var c = new Posicao(1, 2) with { X = 5 };` → **Posicao { X = 5, Y = 2 }** [v]
96. C# 14: `Jogador j` com `Vidas = 3`, depois `j?.Vidas -= 3;` → Vidas = **0** [v]

**Escolha conceitual**
97. Retorno de método de cache que quase sempre acerta sem I/O → **`ValueTask<T>`**.
98. Onde `ConfigureAwait(false)` faz sentido → **biblioteca de uso geral** (não em UI/app).
99. 500 chamadas a uma API externa com limite de 4 simultâneas → **`Parallel.ForEachAsync` com `MaxDegreeOfParallelism = 4`** (ou `SemaphoreSlim`), não `WhenAll` solto.
100. `Vector2` imutável de 8 bytes muito usado no jogo → **`readonly struct`**.
101. Array de 100.000 bytes vai para → **LOH** (coletado com a gen2).
102. Quando `ObjectPool` vale a pena → objeto **caro de inicializar e usado com frequência**, após medir.
103. Primeira escolha OWASP para hash de senha → **Argon2id**.
104. "No máximo 5 requisições ao mesmo tempo" → **concurrency limiter**; "10 por minuto" → **fixed/sliding window**.
105. Probe que diz "o processo está vivo, não reinicie" → **liveness**; "pode receber tráfego" → **readiness**.
106. Você vai conferir se `Salvar` foi chamado → isso é um **mock**; se só devolve dados → **stub**.
107. Instrumento para duração de fase (quero p99) → **Histogram**.
108. Acessar campo privado num app Native AOT sem reflection → **`UnsafeAccessor`**.
109. `Reflection.Emit` num app Native AOT → **não suportado**.
110. Telemetria de posição do jogador em que só o dado mais recente importa → canal com **`DropOldest`**.
111. API chamada só com bearer token no header precisa de antiforgery? → **não** (CSRF explora cookies enviados automaticamente).
112. Ferramenta para o primeiro olhar em produção lenta (CPU, GC, thread pool) → **dotnet-counters**.

---

## 5. O que cai em entrevista .NET sênior (e a resposta que o curso deve treinar)

**Runtime e memória**
- Valor x referência, pilha x heap, boxing; quando struct (regra dos 16 bytes/imutável/valor único).
- Gerações, promoção, LOH ≥ 85.000 bytes, Server x Workstation, DATAS (.NET 9); "a memória sobe o dia todo e cai no restart" → diferenciar crescimento de objetos vivos x working set (dotnet-counters/gcdump).
- `IDisposable` x finalizador ("o GC chama Dispose?" → **não**; o GC libera memória gerenciada, recursos não gerenciados exigem Dispose/SafeHandle).
- `Span<T>` x `Memory<T>` (ref struct x heap/await), `ArrayPool`, `stackalloc`.
- "Por que microbenchmarks mentem?" → sem contenção, caches quentes; valide com profiling e carga real; reporte variância.

**Async e concorrência**
- async/await é máquina de estados e escalonamento cooperativo, não "criar thread".
- Deadlock clássico com `.Result` + contexto; por que ASP.NET Core não trava mas sofre starvation; `ConfigureAwait(false)` em biblioteca.
- `async void`, `Task.Run` em servidor, `StartNew` + async, `TaskCompletionSource` com `RunContinuationsAsynchronously`.
- `Task` x `ValueTask` (e as 3 proibições); exceções em `WhenAll`; cancelamento cooperativo e tokens vinculados.
- `lock` x `SemaphoreSlim` x `Interlocked` (contador → Interlocked; invariante → lock; seção crítica async → SemaphoreSlim); `System.Threading.Lock`.
- `ConcurrentDictionary.GetOrAdd` roda a fábrica duas vezes → `Lazy`; Channels e backpressure; limitar paralelismo em chamadas externas.
- "API lenta com CPU ociosa" → starvation por sync-over-async; confirmar com contadores do thread pool; `dotnet-stack`/`dotnet-trace`.

**Plataforma e arquitetura (ponte com outras frentes)**
- Tempos de vida de DI e dependência cativa (`ValidateScopes`); `HttpClient` x `IHttpClientFactory`.
- Reflection x source generators; o que quebra no Native AOT e como anotar (trimming).
- Ordem de otimização: medir → banco → formato de rede → cache → código → runtime ("de fora para dentro").
- Quando "só pôr um cache" é errado (dado não tolera atraso, taxa de acerto baixa, esconde causa raiz).

**Segurança**
- OWASP Top 10:2025 e o que mudou (Supply Chain e Exceptional Conditions novos; SSRF dentro de A01).
- SQL injection no EF Core (`FromSql` x `FromSqlRaw`), XSS no Razor, CSRF e cookies, hash de senha (Argon2id/PBKDF2 + iterações), segredos, Data Protection, `BinaryFormatter`.

**Observabilidade**
- Logs x métricas x traces; logging estruturado (template constante); cardinalidade de tags; p50 x p99; correlação por trace id; OpenTelemetry/OTLP; health checks liveness x readiness.
- "40 GB de log e não sei por que a requisição foi lenta" → logs estruturados com correlação, logar nas fronteiras, não em toda entrada/saída de método.

**Testes**
- Pirâmide: unitário (rápido, isolado) x integração (`WebApplicationFactory`, Testcontainers) x contrato; stub x mock; tempo testável (`TimeProvider`); testes de arquitetura; `dotnet test` com MTP no .NET 10.

Fonte da lista de perguntas atuais (2026) usada para conferência: https://codewithmukesh.com/blog/senior-dotnet-developer-interview-questions/

---

## 6. URLs consultadas (abertas e lidas nesta pesquisa)

**Memória, tipos, GC e performance**
- https://learn.microsoft.com/en-us/dotnet/standard/design-guidelines/choosing-between-class-and-struct
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/struct
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/ref-struct
- https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/types/boxing-and-unboxing
- https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/performance/
- https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/fundamentals
- https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/workstation-server-gc
- https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/datas
- https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/implementing-dispose
- https://learn.microsoft.com/en-us/dotnet/standard/garbage-collection/implementing-disposeasync
- https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/classes-and-structs/finalizers
- https://learn.microsoft.com/en-us/dotnet/standard/memory-and-spans/memory-t-usage-guidelines
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/operators/stackalloc
- https://learn.microsoft.com/en-us/dotnet/api/system.buffers.arraypool-1
- https://learn.microsoft.com/en-us/dotnet/api/system.buffers.arraypool-1.rent
- https://learn.microsoft.com/en-us/aspnet/core/performance/objectpool
- https://learn.microsoft.com/en-us/dotnet/standard/base-types/stringbuilder
- https://learn.microsoft.com/en-us/dotnet/standard/base-types/best-practices-strings
- https://learn.microsoft.com/en-us/dotnet/api/system.buffers.searchvalues-1
- https://learn.microsoft.com/en-us/dotnet/api/system.buffers.searchvalues.create
- https://learn.microsoft.com/en-us/dotnet/api/system.collections.frozen.frozendictionary-2
- https://benchmarkdotnet.org/articles/overview.html
- https://benchmarkdotnet.org/articles/guides/good-practices.html
- https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-10/runtime
- https://learn.microsoft.com/en-us/dotnet/core/diagnostics/tools-overview
- https://devblogs.microsoft.com/dotnet/understanding-the-whys-whats-and-whens-of-valuetask/

**Async e concorrência**
- https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/task-based-asynchronous-programming
- https://learn.microsoft.com/en-us/dotnet/standard/threading/the-managed-thread-pool
- https://learn.microsoft.com/en-us/archive/msdn-magazine/2013/march/async-await-best-practices-in-asynchronous-programming
- https://github.com/davidfowl/AspNetCoreDiagnosticScenarios/blob/master/AsyncGuidance.md
- https://blog.stephencleary.com/2012/07/dont-block-on-async-code.html
- https://blog.stephencleary.com/2017/03/aspnetcore-synchronization-context.html
- https://devblogs.microsoft.com/dotnet/configureawait-faq/
- https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.configureawaitoptions
- https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/exception-handling-task-parallel-library
- https://learn.microsoft.com/en-us/dotnet/standard/threading/cancellation-in-managed-threads
- https://learn.microsoft.com/en-us/dotnet/standard/datetime/timeprovider-overview
- https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.task.wheneach
- https://learn.microsoft.com/en-us/dotnet/api/system.random.shared
- https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/lock
- https://learn.microsoft.com/en-us/dotnet/api/system.threading.interlocked
- https://learn.microsoft.com/en-us/dotnet/api/system.threading.semaphoreslim
- https://learn.microsoft.com/en-us/dotnet/api/system.collections.concurrent.concurrentdictionary-2.getoradd
- https://learn.microsoft.com/en-us/dotnet/core/extensions/channels
- https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.parallel.foreachasync
- https://learn.microsoft.com/en-us/dotnet/api/system.threading.tasks.parallel.forasync
- https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/introduction-to-plinq
- https://learn.microsoft.com/en-us/dotnet/standard/parallel-programming/understanding-speedup-in-plinq
- https://learn.microsoft.com/en-us/dotnet/csharp/asynchronous-programming/generate-consume-asynchronous-stream

**Linguagem (versões)**
- https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-13
- https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-14
- https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15

**Metaprogramação, interop e AOT**
- https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/reflection-and-attributes/
- https://learn.microsoft.com/en-us/dotnet/api/system.runtime.compilerservices.unsafeaccessorattribute
- https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/expression-trees/
- https://learn.microsoft.com/en-us/dotnet/csharp/advanced-topics/expression-trees/expression-trees-building
- https://learn.microsoft.com/en-us/dotnet/csharp/roslyn-sdk/
- https://github.com/dotnet/roslyn/blob/main/docs/features/incremental-generators.md
- https://learn.microsoft.com/en-us/dotnet/standard/base-types/regular-expression-source-generators
- https://learn.microsoft.com/en-us/dotnet/core/extensions/logger-message-generator
- https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/source-generation
- https://learn.microsoft.com/en-us/dotnet/standard/native-interop/pinvoke-source-generation
- https://learn.microsoft.com/en-us/dotnet/core/deploying/trimming/prepare-libraries-for-trimming
- https://learn.microsoft.com/en-us/dotnet/core/deploying/native-aot/

**Segurança**
- https://top10.owasp.org/2025/0x00_2025-Introduction
- https://cheatsheetseries.owasp.org/cheatsheets/DotNet_Security_Cheat_Sheet.html
- https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html
- https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/consumer-apis/password-hashing
- https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/introduction
- https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/using-data-protection
- https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets
- https://learn.microsoft.com/en-us/ef/core/querying/sql-queries
- https://learn.microsoft.com/en-us/aspnet/core/security/cross-site-scripting
- https://learn.microsoft.com/en-us/aspnet/core/security/anti-request-forgery
- https://learn.microsoft.com/en-us/aspnet/core/security/enforcing-ssl
- https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit
- https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines
- https://learn.microsoft.com/en-us/dotnet/standard/serialization/binaryformatter-security-guide
- https://learn.microsoft.com/en-us/nuget/concepts/auditing-packages
- https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/service-lifetimes

**Observabilidade**
- https://learn.microsoft.com/en-us/dotnet/core/extensions/logging/overview
- https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca2254
- https://learn.microsoft.com/en-us/dotnet/core/diagnostics/metrics-instrumentation
- https://learn.microsoft.com/en-us/dotnet/api/system.diagnostics.metrics.gauge-1
- https://learn.microsoft.com/en-us/dotnet/core/diagnostics/distributed-tracing-instrumentation-walkthroughs
- https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel
- https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-otlp-example
- https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks

**Testes**
- https://learn.microsoft.com/en-us/dotnet/core/testing/unit-testing-best-practices
- https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests
- https://xunit.net/docs/getting-started/v3/whats-new
- https://nsubstitute.github.io/help/getting-started/
- https://github.com/devlooped/moq/releases/tag/v4.20.2
- https://www.infoq.com/news/2025/01/fluent-assertions-v8-license/
- https://dotnet.testcontainers.org/
- https://dotnet.testcontainers.org/test_frameworks/xunit_net/
- https://dotnet.testcontainers.org/modules/postgres/
- https://github.com/BenMorris/NetArchTest
- https://github.com/TNG/ArchUnitNET

**Entrevista**
- https://codewithmukesh.com/blog/senior-dotnet-developer-interview-questions/

**Vistas só em resultado de busca (não abertas; usar com cautela)**
- https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-10/ (escape analysis/stack allocation — os fatos usados foram conferidos na página oficial "What's new in .NET 10 runtime")
- https://devblogs.microsoft.com/dotnet/performance-improvements-in-net-11/ (existência do post confirma o ciclo do .NET 11)
- https://aka.ms/dotnet-test-mtp-error (link impresso pelo próprio SDK 10 ao rodar `dotnet test` sem opt-in no MTP)
