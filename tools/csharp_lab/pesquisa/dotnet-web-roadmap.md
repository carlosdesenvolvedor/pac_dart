# Dossiê — .NET no mundo real e progressão de carreira (frente `dotnet-web-roadmap`)

> Pesquisa feita em 27/09/2026 nas páginas oficiais (learn.microsoft.com, aspire.dev, roadmap.sh — JSON oficial dos roadmaps, versão de 14/09/2026 do ASP.NET Core e 07/02/2026 do Backend) e em roadmaps por senioridade. As fontes servem para CONFERIR cobertura, ordem e boas práticas; os exemplos abaixo são nossos (domínio de jogos/loja, identificadores em português sem acento).

## 0. Estado das versões em set/2026 e decisões para o curso

| Item | Situação em 27/09/2026 | Fonte |
|---|---|---|
| .NET 10 | **LTS**, lançado em 11/11/2025, patch 10.0.12 (08/09/2026), suporte até 14/11/2028 | dotnet support policy |
| .NET 11 | RC1 em 08/09/2026 (go-live), GA prevista para nov/2026, STS (2 anos), C# 15 padrão | .NET 11 RC1 / What's new .NET 11 |
| .NET 8 e .NET 9 | fim do suporte em 10/11/2026 | dotnet support policy |
| C# | 14 (com .NET 10); 15 (com .NET 11) | roadmap milanm / InfoQ RC1 |
| EF Core | 10 é o estável (suporte até 10/11/2028); EF 11 previsto para nov/2026 | EF Core releases |
| Aspire | 13.x (13.5 em ago/2026). Não é mais ".NET Aspire": virou plataforma poliglota, docs em aspire.dev, exige SDK do .NET 10 | aspire.dev |
| OpenAPI nativo | `Microsoft.AspNetCore.OpenApi`: gera OpenAPI 3.1 no .NET 10 e 3.2 por padrão no .NET 11 | Generate OpenAPI documents |

**Decisões recomendadas:**
- Todo código mira `net10.0` + C# 14. Quando algo mudar no .NET 11, a lição ganha a nota "Novo no .NET 11". Recursos só do .NET 10+ vêm marcados `net10+` (validação nativa em Minimal APIs, `TypedResults.ServerSentEvents`, filtros nomeados e `LeftJoin` no EF 10, `partial class Program` gerado para testes).
- **Minimal APIs são o caminho principal.** A Microsoft diz textualmente: "For new projects, we recommend using Minimal APIs". Controllers ficam como alternativa, com lições comparativas, porque há muito código legado com eles no mercado.
- Banco nas trilhas iniciais: **SQLite**, sem infraestrutura. PostgreSQL e SQL Server entram nas trilhas avançadas, via Testcontainers ou Aspire.
- Linhas de digitação com até ~70 caracteres. Cadeias fluentes longas são quebradas em várias linhas começando com `.`.

**Verificação feita:** os trechos 2.1–2.28 e 2.31 foram compilados juntos num projeto `net10.0` (SDK 10.0.102, ASP.NET Core 10.0.2, pacotes NuGet 10.0.12) com **0 erros e 0 avisos**. O 2.29 (Aspire) e o 2.30 (xUnit) vêm da documentação e não foram compilados aqui. Os gabaritos marcados **[testado]** na seção 4.2 foram executados de verdade (servidor Kestrel real + SQLite em memória).

## 1. Árvore de tópicos em ordem didática

### 1.1 Progressão de carreira (o que cada nível precisa saber)

| Nível | Foco (resumo das fontes) | Deve dominar nesta frente | Entrega típica |
|---|---|---|---|
| **Júnior** | "entregar uma API funcional e containerizada" (GomesRobert); no roadmap.sh Backend, o aviso "At this point, you should know enough to get a job" fica na altura de "Learn about APIs"/"Caching", depois de linguagem, Git/GitHub e bancos relacionais | HTTP/REST/status; Minimal APIs (rotas, binding, TypedResults); DI e tempos de vida; configuração e ambientes; EF Core básico (DbContext, migrations, CRUD, Include, AsNoTracking); validação e ProblemDetails; logging; testes de unidade e de integração simples; Docker básico | CRUD com SQLite + migrations + OpenAPI + testes (projeto "catálogo") |
| **Pleno** | "evoluir e operar uma aplicação em produção" | Options + validação; middleware e filtros próprios; JWT + políticas; cache (memória, Redis, HybridCache, output); rate limiting; health checks; IHttpClientFactory + resiliência; BackgroundService; EF: N+1, split query, paginação keyset, ExecuteUpdate, concorrência otimista, transações; SignalR; WebApplicationFactory + Testcontainers; logs estruturados/OpenTelemetry; CI/CD | API com auth, cache, logging, testes e job em background ("serviço de pedidos") |
| **Sênior** | "projetar sistemas e justificar trade-offs" | System design; mensageria (outbox/inbox, idempotência, sagas); gRPC/streaming; escala de SignalR; Aspire; observabilidade (SLO/SLI); performance (pooling, compiled queries, AOT, BenchmarkDotNet); segurança com IdP/OIDC; migrations em produção; escolha de libs e licenças | Sistema distribuído observável e resiliente, com deploy e rollback documentados |

Estimativas de tempo (codewithmukesh): base compartilhada de ~200 h (C# ~44 h, primeira Web API ~32 h, bancos ~21 h, EF Core ~39 h), trilha backend de ~94 h e trilha sênior de ~162 h. O mesmo roteiro alerta: "Learn C# first, but only just".
Ordem-resumo (GomesRobert): Git → HTTP → C# → .NET → ASP.NET Core → SQL → EF Core → testes → Docker. Ordem de arquitetura (milanm): camada única → camadas → monólito modular → microsserviços.

### 1.2 Árvore (níveis: ini = iniciante · int = intermediário · ava = avançado · sen = sênior)

Pré-requisitos, vindos de outras frentes: C# básico, OOP, coleções, LINQ, `async/await`, exceções, records e nullable.

**A — Fundamentos de web para quem vem do C#**
- **A1** [ini] Requisição e resposta HTTP: método + URL + headers + corpo; resposta com status + headers + corpo; HTTP não guarda estado. https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Overview
- **A2** [ini] Métodos e idempotência: GET, PUT e DELETE são idempotentes; POST e PATCH não. https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design
- **A3** [ini] Status: 200, 201 (com Location), 204, 400, 401 x 403, 404, 409, 415, 422, 429, 500, 503. https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status
- **A4** [ini] REST: substantivos no plural (`/pedidos/5`), relações rasas (coleção/item/coleção), não espelhar as tabelas do banco. (fonte da A2)
- **A5** [ini] JSON com System.Text.Json: na web, propriedades saem em camelCase e a leitura ignora maiúsculas/minúsculas. https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/overview
- **A6** [ini] Ferramentas: `dotnet new web`/`webapi` (o `webapi` já cria Minimal API; `-controllers` gera controllers), `dotnet run`, `dotnet watch`, arquivos `.http`, curl. https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-new-sdk-templates · https://learn.microsoft.com/en-us/aspnet/core/test/http-files?view=aspnetcore-10.0

**B — Primeira API (Minimal APIs)**
- **B1** [ini] `Program.cs`: `WebApplication.CreateBuilder` → `builder.Services` → `Build()` → pipeline → `Run()`. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/webapplication?view=aspnetcore-10.0
- **B2** [ini] `MapGet/MapPost/MapPut/MapDelete`; o handler pode ser lambda, função local, método de instância ou estático. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/route-handlers?view=aspnetcore-10.0
- **B3** [ini] Parâmetros de rota, constraints (`{id:int}`, `{slug:regex(...)}`) e catch-all (`{*resto}`). Se a constraint falha, a rota não casa e vem 404. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/routing?view=aspnetcore-10.0
- **B4** [ini] Binding inferido (rota, query, header, corpo JSON, serviços de DI) e tipos especiais (`HttpContext`, `CancellationToken`, `ClaimsPrincipal`). GET, HEAD, OPTIONS e DELETE não leem corpo implicitamente. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/parameter-binding?view=aspnetcore-10.0
- **B5** [int] Parâmetros opcionais (`int?`, valor padrão) e falhas de binding: TryParse falhou = 400, JSON inválido = 400, content-type errado = 415. (fonte da B4)
- **B6** [ini] Retornos: `string` sai como text/plain, `T` sai como JSON, `IResult` escolhe. Prefira `TypedResults` a `Results` e use `Results<T1,T2>` quando o handler tem mais de uma saída. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/responses?view=aspnetcore-10.0
- **B7** [int] Organização: `MapGroup` com prefixo comum, métodos de extensão por feature, `WithTags`/`WithName`, grupos aninhados. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis?view=aspnetcore-10.0
- **B8** [int] Binding explícito com `[FromRoute/Query/Header/Body/Form/Services]` e `[AsParameters]`, e a ordem de precedência do binding. (fonte da B4)
- **B9** [int] Controllers: `[ApiController]`, `ControllerBase`, `[Route("api/[controller]")]`, `ActionResult<T>`, 400 automático com `ValidationProblemDetails`. Quando escolher cada abordagem. https://learn.microsoft.com/en-us/aspnet/core/web-api/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/apis?view=aspnetcore-10.0
- **B10** [int] Kestrel e portas: `launchSettings.json`, `ASPNETCORE_URLS`/`ASPNETCORE_HTTP_PORTS`, `http://+:5000`. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel?view=aspnetcore-10.0

**C — Host, pipeline, DI, configuração e logging**
- **C1** [ini] Pipeline de middleware: `Use` (com `next`), `Run` (terminal), `Map` (ramificação). O código roda antes e depois do `next`, e a resposta volta na ordem inversa. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/?view=aspnetcore-10.0
- **C2** [int] Ordem oficial: ExceptionHandler/HSTS → HttpsRedirection → Static → Routing → CORS → Authentication → Authorization → (RateLimiter/OutputCache) → endpoints. O `WebApplication` adiciona sozinho DeveloperExceptionPage (em Dev), Routing e Auth. (fonte da C1)
- **C3** [int] Middleware em classe com `InvokeAsync(HttpContext)`. Serviço scoped entra como parâmetro do `InvokeAsync`, nunca no construtor. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/write?view=aspnetcore-10.0
- **C4** [int] Endpoint filters (`AddEndpointFilter`, `IEndpointFilter`): o código antes do `next` roda em FIFO e o de depois em FILO. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/min-api-filters?view=aspnetcore-10.0
- **C5** [ini] DI: registrar serviços; injetar pelo construtor (inclusive primary constructor) ou como parâmetro do handler. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/dependency-injection?view=aspnetcore-10.0
- **C6** [ini] Tempos de vida: Transient (uma instância por resolução), Scoped (uma por requisição), Singleton (uma por app, precisa ser thread-safe). `AddDbContext` registra como Scoped. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/service-lifetimes
- **C7** [int] Armadilhas de DI: captive dependency, `ValidateScopes`/`ValidateOnBuild` (ligados só em Development), service locator, `BuildServiceProvider`, factory async com `.Result`. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection-guidelines
- **C8** [int] Keyed services (`AddKeyedSingleton` + `[FromKeyedServices("x")]`). (fonte da C5)
- **C9** [ini] Configuração, da maior para a menor prioridade: linha de comando > variáveis de ambiente > user-secrets (só em Dev) > `appsettings.{Ambiente}.json` > `appsettings.json`. Hierarquia com `:` e, em variável de ambiente, `__`. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?view=aspnetcore-10.0
- **C10** [ini] Ambientes: Development, Staging e Production. Sem variável definida, vale Production. `DOTNET_ENVIRONMENT` vence `ASPNETCORE_ENVIRONMENT` no `WebApplication`. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/environments?view=aspnetcore-10.0
- **C11** [int] Segredos: `dotnet user-secrets` em dev; nunca senha em appsettings versionado. https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-10.0
- **C12** [int] Options pattern: classe POCO + `Bind`. `IOptions` (singleton, sem reload), `IOptionsSnapshot` (scoped, recalcula por requisição), `IOptionsMonitor` (singleton, reload e notificação). Validação com `ValidateDataAnnotations` + `ValidateOnStart`. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options?view=aspnetcore-10.0
- **C13** [ini] Logging: `ILogger<T>`, categoria, níveis Trace..Critical, filtros em `Logging:LogLevel`, templates estruturados (`{PedidoId}`), exceção como argumento. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/logging/?view=aspnetcore-10.0
- **C14** [ava] `[LoggerMessage]` com source generator: métodos `partial` sem boxing e sem alocação. https://learn.microsoft.com/en-us/dotnet/core/extensions/logging/source-generation
- **C15** [int] Generic Host fora da web: `Host.CreateApplicationBuilder`, `IHost`, `IHostApplicationLifetime`, desligamento gracioso. https://learn.microsoft.com/en-us/dotnet/core/extensions/generic-host

**D — Dados com EF Core**
- **D1** [ini] SQL antes do ORM: SELECT/WHERE/JOIN, chaves, índices, transações/ACID, normalização (roadmap.sh: "Database Fundamentals" e "Relational Databases"). https://roadmap.sh/backend
- **D2** [ini] O `DbContext` é uma unidade de trabalho de vida curta e não é thread-safe; `DbSet`, convenções (`Id` vira PK) e providers (SQLite, SQL Server, PostgreSQL). https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration/
- **D3** [ini] `AddDbContext` (Scoped) + `GetConnectionString`; construtor com `DbContextOptions<T>`. (fonte da D2)
- **D4** [ini] Migrations: `dotnet ef migrations add`, `database update`, snapshot no Git, `script --idempotent`, bundles. `EnsureCreated` não convive com `Migrate`. https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/
- **D5** [ini] CRUD: `Add`, `FindAsync`, `Remove`, `SaveChangesAsync` (atômico). https://learn.microsoft.com/en-us/ef/core/saving/basic
- **D6** [int] LINQ vira SQL: `IQueryable`, execução adiada; avaliação no cliente só na projeção final. https://learn.microsoft.com/en-us/ef/core/querying/client-eval
- **D7** [int] Relacionamentos 1:N, N:N e 1:1; FK obrigatória ou opcional; `HasMany/WithOne/HasForeignKey`; `OnDelete`. https://learn.microsoft.com/en-us/ef/core/modeling/relationships/one-to-many
- **D8** [int] Carregar dados relacionados: `Include/ThenInclude`, Include filtrado, carregamento explícito; lazy loading é armadilha de N+1. https://learn.microsoft.com/en-us/ef/core/querying/related-data/eager
- **D9** [int] Tracking x `AsNoTracking` x `AsNoTrackingWithIdentityResolution`; projeção com `Select` para DTO não rastreia. https://learn.microsoft.com/en-us/ef/core/querying/tracking
- **D10** [int] Performance: índices, projeção, `Take`, N+1, explosão cartesiana (resolvida com `AsSplitQuery`), buffering x streaming, sempre async. https://learn.microsoft.com/en-us/ef/core/performance/efficient-querying · https://learn.microsoft.com/en-us/ef/core/querying/single-split-queries
- **D11** [int] Paginação offset (`Skip/Take`) x keyset (`Where(Id > ultimo)`). A ordenação precisa ser única. https://learn.microsoft.com/en-us/ef/core/querying/pagination
- **D12** [ava] `ExecuteUpdateAsync`/`ExecuteDeleteAsync`: em massa, ignoram o change tracker e não abrem transação implícita. No EF 10 aceitam lambda comum. https://learn.microsoft.com/en-us/ef/core/saving/execute-insert-update-delete
- **D13** [ava] Transações explícitas (`BeginTransactionAsync`/`CommitAsync`). https://learn.microsoft.com/en-us/ef/core/saving/transactions
- **D14** [ava] Concorrência otimista: `[Timestamp]` (rowversion do SQL Server) ou `[ConcurrencyCheck]`; tratar `DbUpdateConcurrencyException` devolvendo 409. https://learn.microsoft.com/en-us/ef/core/saving/concurrency
- **D15** [ava] SQL cru: `FromSql($"...{x}")` é parametrizado e seguro; `FromSqlRaw` com concatenação permite injeção (o EF 10 avisa com analisador). https://learn.microsoft.com/en-us/ef/core/querying/sql-queries
- **D16** [ava] Filtros globais e **nomeados** (EF 10) para soft delete e multi-tenant; `IgnoreQueryFilters(["Nome"])`. https://learn.microsoft.com/en-us/ef/core/querying/filters
- **D17** [sen] Interceptors, complex types/JSON, `LeftJoin`/`RightJoin` (.NET 10), índices compostos. https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/whatsnew
- **D18** [sen] `AddDbContextPool` (pool padrão de 1024), `EF.CompileAsyncQuery`, compiled models; medir antes de adotar. https://learn.microsoft.com/en-us/ef/core/performance/advanced-performance-topics
- **D19** [sen] Migrations em produção: bundle (automação) ou script revisado (DBA); identidade de deploy separada; lock de migração no EF 9+. https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying
- **D20** [int] Micro-ORM Dapper como alternativa e quando ele vale a pena (roadmap.sh lista Dapper, RepoDB e NHibernate como alternativas). https://github.com/DapperLib/Dapper
- **D21** [int] Testar com banco real (Testcontainers) em vez de InMemory. https://learn.microsoft.com/en-us/ef/core/testing/testing-with-the-database

**E — Qualidade da API**
- **E1** [int] Validação `net10+`: `AddValidation()` + DataAnnotations em classes e records, `IValidatableObject`, `DisableValidation()`, `[ValidatableType]`. Sem `AddValidation` nada é validado e não aparece erro nenhum. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/validation?view=aspnetcore-10.0
- **E2** [int] Validação em controllers (400 automático) e FluentValidation como biblioteca. https://learn.microsoft.com/en-us/aspnet/core/mvc/models/validation?view=aspnetcore-10.0 · https://docs.fluentvalidation.net/
- **E3** [int] ProblemDetails (RFC 9457, que substitui a 7807): `AddProblemDetails`, `UseExceptionHandler`, `UseStatusCodePages`, `CustomizeProblemDetails`. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/handle-errors?view=aspnetcore-10.0 · https://www.rfc-editor.org/rfc/rfc9457.html
- **E4** [ava] `IExceptionHandler`: singleton, chamados em ordem, dependem de `UseExceptionHandler`. Quem retorna `true` precisa escrever status e corpo; no nosso teste (ASP.NET Core 10.0.2), sem isso a resposta saiu 500 e vazia. No .NET 10, exceção tratada não gera log por padrão (`SuppressDiagnosticsCallback`). https://learn.microsoft.com/en-us/aspnet/core/fundamentals/error-handling?view=aspnetcore-10.0
- **E5** [int] OpenAPI nativo: `AddOpenApi()` + `MapOpenApi()` em `/openapi/v1.json`; `TypedResults` documentam as respostas sozinhos; geração no build; transformers. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/aspnetcore-openapi?view=aspnetcore-10.0
- **E6** [int] Interface de documentação (Scalar `/scalar` ou Swagger UI) **só em Development**. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/using-openapi-documents?view=aspnetcore-10.0
- **E7** [int] CORS: política nomeada, `WithOrigins` sem barra no final, `UseCors` antes de auth e de cache. `AllowAnyOrigin` + `AllowCredentials` é proibido. https://learn.microsoft.com/en-us/aspnet/core/security/cors?view=aspnetcore-10.0
- **E8** [ava] Versionamento (por URI, query, header ou media type) e a lib `Asp.Versioning`. (fonte da A2) · https://github.com/dotnet/aspnet-api-versioning
- **E9** [int] Testes: handlers com `TypedResults` são testáveis por tipo; integração com `WebApplicationFactory<Program>` (o .NET 10 gera `public partial class Program`). https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/test-min-api?view=aspnetcore-10.0

**F — Segurança**
- **F1** [ini] Autenticação (quem é) x autorização (o que pode): 401 = token inválido ou ausente; 403 = autenticado mas sem permissão. https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-10.0
- **F2** [int] JWT Bearer: validar assinatura, `iss`, `aud` e `exp`; `ClockSkew` padrão de 5 min; `MapInboundClaims` troca `sub` por `ClaimTypes.NameIdentifier`; tokens de dev com `dotnet user-jwts create`. (fonte da F1) · https://learn.microsoft.com/en-us/aspnet/core/security/authentication/jwt-authn?view=aspnetcore-10.0
- **F3** [int] `RequireAuthorization`/`[Authorize]`, `AllowAnonymous`, roles, claims, políticas (`AddAuthorizationBuilder`), fallback policy. https://learn.microsoft.com/en-us/aspnet/core/security/authorization/policies?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/security?view=aspnetcore-10.0
- **F4** [ava] Emissão de tokens no mundo real: OIDC/OAuth com provedor (Entra ID, Keycloak, Duende, OpenIddict), chaves assimétricas. A doc diz: "You should NOT create an access token from a username/password request". Em estudo, HS256 exige chave de 32 bytes ou mais (erro IDX10720). (fonte da F1)
- **F5** [ava] ASP.NET Core Identity para SPA (`MapIdentityApi`) e cookies. No .NET 10, endpoints de API respondem 401/403 em vez de redirecionar para o login. https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization?view=aspnetcore-10.0
- **F6** [int] HTTPS/HSTS, Data Protection, OWASP (injeção, mass assignment evitado com DTO, exposição de dados evitada com projeção). https://learn.microsoft.com/en-us/aspnet/core/security/enforcing-ssl?view=aspnetcore-10.0

**G — Desempenho, cache e resiliência**
- **G1** [ini] Async de ponta a ponta com `CancellationToken`. Nada de `.Result`, `.Wait()` ou `Task.Run` desnecessário. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices?view=aspnetcore-10.0
- **G2** [int] Cache: `IMemoryCache` → `IDistributedCache` (Redis) → `HybridCache` (evita stampede: só um chamador executa a factory por chave; aceita tags). https://learn.microsoft.com/en-us/aspnet/core/performance/caching/overview?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/performance/caching/hybrid?view=aspnetcore-10.0
- **G3** [int] Output caching. Padrão: só 200, só GET/HEAD, não cacheia resposta que grava cookie nem requisição autenticada. Políticas, tags, `EvictByTagAsync`; entra depois de CORS e auth. https://learn.microsoft.com/en-us/aspnet/core/performance/caching/output?view=aspnetcore-10.0
- **G4** [int] Rate limiting: fixed window, sliding window, token bucket e concorrência; partições por IP, usuário ou chave; **o status padrão de rejeição é 503**, configure 429. https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit?view=aspnetcore-10.0
- **G5** [ava] Request timeouts e compressão de resposta. https://learn.microsoft.com/en-us/aspnet/core/performance/timeouts?view=aspnetcore-10.0
- **G6** [int] HttpClient: não criar um por requisição. `IHttpClientFactory` (básico, nomeado, tipado), handler vive 2 min, `PooledConnectionLifetime`; cliente tipado dentro de singleton é armadilha. https://learn.microsoft.com/en-us/dotnet/core/extensions/httpclient-factory · https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines
- **G7** [ava] Resiliência com `Microsoft.Extensions.Http.Resilience` (Polly v8). `AddStandardResilienceHandler` empilha: limite de 1000 concorrentes, timeout total de 30 s, 3 retries exponenciais com jitter, circuit breaker e timeout de 10 s por tentativa. `DisableForUnsafeHttpMethods()` evita retry de POST. https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience

**H — Segundo plano e operação**
- **H1** [int] `IHostedService` x `BackgroundService`; Worker Service (`dotnet new worker`). https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/hosted-services?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/dotnet/core/extensions/workers
- **H2** [int] Escopo em background (`IServiceScopeFactory.CreateAsyncScope`) e `PeriodicTimer`. https://learn.microsoft.com/en-us/dotnet/core/extensions/scoped-service
- **H3** [ava] Exceção não tratada no `ExecuteAsync` para o host (desde o .NET 6). No .NET 10 o `ExecuteAsync` inteiro roda em background. O desligamento tem 30 s para ser gracioso. https://learn.microsoft.com/en-us/dotnet/core/compatibility/extensions/10.0/backgroundservice-executeasync-task
- **H4** [ava] Filas em memória (`Channel<T>`) e agendadores (Hangfire, Quartz, Coravel). (fonte da H1) · https://www.hangfire.io/
- **H5** [int] Health checks: `AddHealthChecks`, `IHealthCheck`, `AddDbContextCheck`, tags, liveness x readiness, probes de Docker e Kubernetes. https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-10.0
- **H6** [ava] Observabilidade: logs, métricas e traces com OpenTelemetry; correlação entre serviços. https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel
- **H7** [ava] Containers: `dotnet publish` com suporte a container, configuração por variável de ambiente, proxy reverso (forwarded headers). https://learn.microsoft.com/en-us/dotnet/core/containers/sdk-publish · https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/proxy-load-balancer?view=aspnetcore-10.0

**I — Tempo real e comunicação entre serviços**
- **I1** [int] Quando usar cada opção. Polling: simples e caro. SSE: servidor → cliente, texto. WebSockets: bidirecional, baixo nível. SignalR: RPC + broadcast + grupos. gRPC: serviço ↔ serviço, contrato forte, streaming. https://roadmap.sh/backend · https://learn.microsoft.com/en-us/aspnet/core/grpc/comparison?view=aspnetcore-10.0
- **I2** [int] SSE nativo `net10+`: `TypedResults.ServerSentEvents(IAsyncEnumerable<SseItem<T>>)`. (fonte da B6)
- **I3** [int] SignalR: `AddSignalR`/`MapHub`, `Clients.All/Caller/Others/Group/User`, grupos, `Hub<T>` fortemente tipado, `IHubContext` fora do hub, `OnConnectedAsync`, `HubException`. Uma instância de hub é criada por invocação. https://learn.microsoft.com/en-us/aspnet/core/signalr/hubs?view=aspnetcore-10.0
- **I4** [ava] Clientes SignalR (.NET e JS) e reconexão automática. Transportes em ordem de fallback: WebSockets → SSE → Long Polling. https://learn.microsoft.com/en-us/aspnet/core/signalr/dotnet-client?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/signalr/introduction?view=aspnetcore-10.0
- **I5** [sen] Escala do SignalR: sticky sessions obrigatórias (mesmo com backplane Redis), exceto em servidor único, Azure SignalR Service ou só WebSockets com SkipNegotiation. Grupos ficam em memória e não sobrevivem a reconexão. https://learn.microsoft.com/en-us/aspnet/core/signalr/scale?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/signalr/groups?view=aspnetcore-10.0
- **I6** [ava] gRPC: contract-first com `.proto`, `Grpc.AspNetCore`, `AddGrpc`/`MapGrpcService`; chamadas unária, server streaming, client streaming e bidirecional; **não existe deadline padrão**; `AddGrpcClient`. https://learn.microsoft.com/en-us/aspnet/core/grpc/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/grpc/deadlines-cancellation?view=aspnetcore-10.0
- **I7** [sen] gRPC no navegador (gRPC-Web, JSON transcoding) e gRPC x REST x SignalR (broadcast é com SignalR). https://learn.microsoft.com/en-us/aspnet/core/grpc/json-transcoding?view=aspnetcore-10.0
- **I8** [sen] Mensageria: fila x tópico, RabbitMQ, Kafka, Azure Service Bus; outbox/inbox; idempotência; MassTransit (a v9 é comercial). https://roadmap.sh/aspnet-core · https://masstransit.io/
- **I9** [sen] API Gateway e proxy reverso com YARP. https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/yarp-overview?view=aspnetcore-10.0

**J — Cloud-native com Aspire e arquitetura**
- **J1** [ava] Aspire: AppHost (`DistributedApplication.CreateBuilder`), recursos (`AddProject`, `AddRedis`, `AddPostgres().AddDatabase()`), `WithReference` (injeta a conexão), `WaitFor` (sobe só depois que a dependência fica saudável), dashboard, service discovery. https://aspire.dev/get-started/what-is-aspire/ · https://aspire.dev/get-started/app-host/
- **J2** [ava] Service defaults: `AddServiceDefaults()` liga OpenTelemetry, health checks, service discovery e resiliência padrão no HttpClient; `MapDefaultEndpoints()` expõe `/health` e `/alive`, e só em Development. https://aspire.dev/get-started/csharp-service-defaults/
- **J3** [sen] Integrações client (`AddNpgsqlDbContext<T>("nome")`: o nome da conexão é a ponte com o AppHost); CLI `aspire new/run/publish/deploy/do/update`; migrations com Aspire. https://aspire.dev/integrations/databases/postgres/postgres-get-started/ · https://aspire.dev/whats-new/aspire-13/
- **J4** [ava] Arquiteturas de API: camadas, Clean, Vertical Slice, monólito modular, microsserviços, CQRS e DDD (detalhes na frente de arquitetura). https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/ · https://learn.microsoft.com/en-us/dotnet/architecture/microservices/
- **J5** [sen] System design: SLA/SLO/SLI, consistência eventual, sagas, alta disponibilidade, recuperação de desastre. https://roadmap.sh/system-design · https://github.com/GomesRobert/aspnetcore-roadmap
- **J6** [sen] Licenças do ecossistema (2025–26): MediatR e AutoMapper são comerciais (Lucky Penny, com Community edition grátis para receita abaixo de US$ 5 mi); MassTransit v9 é comercial (v8 com patches até o fim de 2026); FluentAssertions 8 é comercial. O roadmap.sh marca "Manual Mapping" como recomendação. https://www.jimmybogard.com/automapper-and-mediatr-commercial-editions-launch-today/

### 1.3 Proposta de trilhas do PAC·C# para esta frente (13 trilhas × 12 lições ≈ 1.400 exercícios)

| # | Trilha | Nível | Tópicos |
|---|---|---|---|
| W1 | HTTP e REST para devs C# | ini | A1–A6 |
| W2 | Minimal APIs: a primeira API | ini | B1–B7 |
| W3 | Pipeline, DI e configuração | ini→int | C1–C12 |
| W4 | EF Core essencial (SQLite) | ini | D1–D6 |
| W5 | EF Core: relações e consultas | int | D7–D11, D20 |
| W6 | Validação, erros, OpenAPI e CORS | int | E1–E7, C13 |
| W7 | Autenticação e autorização | int | F1–F6 |
| W8 | Testando APIs | int | E9, D21, B9 |
| W9 | Cache, rate limit e performance | int→ava | G1–G5 |
| W10 | HttpClient, resiliência e workers | ava | G6–G7, H1–H5 |
| W11 | Tempo real em jogos: SignalR, SSE e gRPC | ava | I1–I7 (placar ao vivo, salas) |
| W12 | EF Core avançado | ava→sen | D12–D19, C14 |
| W13 | Cloud-native: Aspire, OTel e containers | sen | J1–J3, H6–H7, I8–I9 |

## 2. Código de referência (C# 14 / .NET 10, correto e compilável)

**Usings explícitos.** O Sdk.Web já importa System, System.Collections.Generic, System.IO, System.Linq, System.Net.Http, System.Net.Http.Json, System.Threading(.Tasks), Microsoft.AspNetCore.Builder/Hosting/Http/Routing e Microsoft.Extensions.Configuration/DependencyInjection/Hosting/Logging. Todo o resto precisa de `using`: `Microsoft.AspNetCore.Http.HttpResults` (Ok<T>, NotFound...), `Microsoft.EntityFrameworkCore`, `Microsoft.Extensions.Options`, `Microsoft.AspNetCore.Mvc` ([FromQuery], ProblemDetails), `Microsoft.AspNetCore.RateLimiting`, `Microsoft.AspNetCore.OutputCaching`, `Microsoft.AspNetCore.Diagnostics` (IExceptionHandler), `Microsoft.AspNetCore.SignalR`, `System.ComponentModel.DataAnnotations`.
**Pacotes NuGet:** EF (`Microsoft.EntityFrameworkCore.Sqlite` + `.Design`), JWT (`Microsoft.AspNetCore.Authentication.JwtBearer`), `Microsoft.AspNetCore.OpenApi`, `Scalar.AspNetCore`, `Microsoft.Extensions.Caching.Hybrid`, `Microsoft.Extensions.Http.Resilience`, `Microsoft.Extensions.Diagnostics.HealthChecks.EntityFrameworkCore`, `Grpc.AspNetCore`, `Microsoft.AspNetCore.SignalR.Client`, `Microsoft.AspNetCore.Mvc.Testing`.
**Top-level statements:** classes e records vão DEPOIS de `app.Run();` ou em arquivos próprios.

### 2.1 API mínima, rotas e parâmetros
```csharp
var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Olá, PAC·C#!");
app.MapGet("/jogadores/{id:int}", (int id) => $"Jogador {id}");
app.MapGet("/busca", (string termo, int? pagina) =>
    $"{termo} (página {pagina ?? 1})");   // sem ?termo= → 400

app.Run();
```

### 2.2 Modelo EF Core (usado nos demais exemplos)
```csharp
using Microsoft.EntityFrameworkCore;

public class Time
{
    public int Id { get; set; }
    public required string Nome { get; set; }
    public List<Jogador> Jogadores { get; } = [];
}

public class Jogador
{
    public int Id { get; set; }
    public required string Apelido { get; set; }
    public int Nivel { get; set; }
    public bool Ativo { get; set; } = true;
    public int? TimeId { get; set; }      // FK opcional
    public Time? Time { get; set; }
}

public class JogoDb(DbContextOptions<JogoDb> options) : DbContext(options)
{
    public DbSet<Time> Times => Set<Time>();
    public DbSet<Jogador> Jogadores => Set<Jogador>();

    protected override void OnModelCreating(ModelBuilder mb)
    {
        mb.Entity<Jogador>().HasIndex(j => j.Apelido).IsUnique();
        mb.Entity<Time>()
            .HasMany(t => t.Jogadores)
            .WithOne(j => j.Time)
            .HasForeignKey(j => j.TimeId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}

public record JogadorDto(int Id, string Apelido, int Nivel);
public record NovoJogador(string Apelido, int Nivel);
```

### 2.3 CRUD com TypedResults, `Results<>` e 201 Created
```csharp
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddDbContext<JogoDb>(o =>
    o.UseSqlite(builder.Configuration.GetConnectionString("Jogo")));
var app = builder.Build();

var jogadores = app.MapGroup("/jogadores").WithTags("Jogadores");

jogadores.MapGet("/{id:int}",
    async Task<Results<Ok<JogadorDto>, NotFound>> (int id, JogoDb db) =>
        await db.Jogadores.FindAsync(id) is Jogador j
            ? TypedResults.Ok(new JogadorDto(j.Id, j.Apelido, j.Nivel))
            : TypedResults.NotFound());

jogadores.MapPost("/", async (NovoJogador dto, JogoDb db) =>
{
    var j = new Jogador { Apelido = dto.Apelido, Nivel = dto.Nivel };
    db.Jogadores.Add(j);
    await db.SaveChangesAsync();
    return TypedResults.Created($"/jogadores/{j.Id}",
        new JogadorDto(j.Id, j.Apelido, j.Nivel));
});

jogadores.MapDelete("/{id:int}",
    async Task<Results<NoContent, NotFound>> (int id, JogoDb db) =>
        await db.Jogadores.Where(x => x.Id == id).ExecuteDeleteAsync() == 1
            ? TypedResults.NoContent()
            : TypedResults.NotFound());

app.Run();
```
Por que importa: `TypedResults` expõe o tipo concreto, que o teste consegue checar e o OpenAPI documenta sem `.Produces()`. Um ternário com dois `TypedResults` diferentes só compila se o retorno for declarado como `Results<...>`.

### 2.4 Endpoints por feature (método de extensão + MapGroup)
```csharp
public static class RankingEndpoints
{
    public static IEndpointRouteBuilder MapRanking(this IEndpointRouteBuilder app)
    {
        var grupo = app.MapGroup("/ranking").WithTags("Ranking");
        grupo.MapGet("/", ListarTop);
        return app;
    }

    static async Task<Ok<List<JogadorDto>>> ListarTop(
        JogoDb db, int? top, CancellationToken ct) =>
        TypedResults.Ok(await db.Jogadores.AsNoTracking()
            .OrderByDescending(j => j.Nivel).ThenBy(j => j.Apelido)
            .Take(top ?? 10)
            .Select(j => new JogadorDto(j.Id, j.Apelido, j.Nivel))
            .ToListAsync(ct));
}
// Program.cs: app.MapRanking();
```

### 2.5 Binding explícito e `[AsParameters]`
```csharp
using Microsoft.AspNetCore.Mvc;

app.MapGet("/partidas", ([FromQuery(Name = "p")] int pagina,
                         [FromHeader(Name = "X-Regiao")] string? regiao) =>
    $"Página {pagina} da região {regiao ?? "BR"}");

app.MapGet("/partidas/{id:int}", ([AsParameters] ConsultaPartida c) =>
    $"Partida {c.Id}, detalhes: {c.Detalhes ?? false}");

public struct ConsultaPartida
{
    public int Id { get; set; }          // rota {id}
    public bool? Detalhes { get; set; }  // query ?detalhes=true
}
```

### 2.6 Middleware: ordem (inline) e classe
```csharp
app.Use(async (context, next) =>
{
    Console.WriteLine("A antes");
    await next(context);
    Console.WriteLine("A depois");
});
app.Use(async (context, next) =>
{
    Console.WriteLine("B antes");
    await next(context);
    Console.WriteLine("B depois");
});
app.Run(async context => await context.Response.WriteAsync("fim"));
// Console: A antes, B antes, B depois, A depois
```
```csharp
using System.Diagnostics;

public sealed class TempoMiddleware(RequestDelegate next,
    ILogger<TempoMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)   // scoped? injete AQUI
    {
        var inicio = Stopwatch.GetTimestamp();
        await next(context);
        var ms = Stopwatch.GetElapsedTime(inicio).TotalMilliseconds;
        logger.LogInformation("{Metodo} {Caminho} em {Ms} ms",
            context.Request.Method, context.Request.Path, ms);
    }
}
// app.UseMiddleware<TempoMiddleware>();
```

### 2.7 Endpoint filter (validação simples de palpite)
```csharp
app.MapPost("/palpites", (Palpite p) => TypedResults.Ok(p))
   .AddEndpointFilter(async (ctx, next) =>
   {
       var palpite = ctx.GetArgument<Palpite>(0);
       if (palpite.Numero is < 1 or > 100)
           return TypedResults.Problem("Use um número de 1 a 100",
               statusCode: StatusCodes.Status400BadRequest);
       return await next(ctx);
   });

public record Palpite(int Numero);
```

### 2.8 DI: tempos de vida, keyed services e o bug da dependência cativa
```csharp
builder.Services.AddSingleton<IRelogio, RelogioDoSistema>();   // 1 na app
builder.Services.AddScoped<ICarrinho, Carrinho>();             // 1 por requisição
builder.Services.AddTransient<IGeradorCodigo, GeradorCodigo>(); // 1 por resolução
builder.Services.AddKeyedSingleton<IFrete, FreteCorreios>("correios");
builder.Services.AddKeyedSingleton<IFrete, FreteExpresso>("expresso");

app.MapGet("/frete", ([FromKeyedServices("expresso")] IFrete frete) =>
    frete.Calcular(2.5m));

// BUG: AddSingleton<CacheRanking>() com construtor CacheRanking(JogoDb db)
// Em Development: "Cannot consume scoped service 'JogoDb' from singleton..."
// Correção: tornar Scoped ou injetar IServiceScopeFactory e criar escopo.
```

### 2.9 Configuração e options com validação
```json
{
  "ConnectionStrings": { "Jogo": "Data Source=jogo.db" },
  "Partida": { "MaxJogadores": 4, "Modo": "classico" },
  "Logging": { "LogLevel": { "Default": "Information", "Microsoft.AspNetCore": "Warning" } }
}
```
```csharp
using System.ComponentModel.DataAnnotations;
using Microsoft.Extensions.Options;

var limite = builder.Configuration.GetValue<int>("Partida:MaxJogadores");
builder.Services.AddOptions<PartidaOptions>()
    .Bind(builder.Configuration.GetSection(PartidaOptions.Secao))
    .ValidateDataAnnotations()
    .ValidateOnStart();                       // falha já na inicialização
// ... var app = builder.Build();
app.MapGet("/regras", (IOptions<PartidaOptions> o) => o.Value);

public sealed class PartidaOptions
{
    public const string Secao = "Partida";
    [Range(2, 16)] public int MaxJogadores { get; set; } = 4;
    [Required] public string Modo { get; set; } = "classico";
}
// Sobrescrever sem tocar no JSON: variável de ambiente Partida__MaxJogadores=8
```

### 2.10 Logging estruturado e `[LoggerMessage]`
```csharp
app.MapPost("/partidas/{id:int}/fim", (int id, ILogger<Program> logger) =>
{
    logger.LogInformation("Partida {PartidaId} encerrada às {Hora}",
        id, DateTime.UtcNow);
    // Evite: logger.LogInformation($"Partida {id} encerrada"); (perde os campos)
    return TypedResults.NoContent();
});

public static partial class Log
{
    [LoggerMessage(EventId = 1001, Level = LogLevel.Warning,
        Message = "Jogador {JogadorId} passou de {Limite} ações/min")]
    public static partial void LimiteExcedido(this ILogger logger,
        int jogadorId, int limite);
}
// uso: logger.LimiteExcedido(42, 60);
```

### 2.11 Migrations (CLI)
```bash
dotnet new webapi -n Jogo.Api          # Minimal API por padrão
dotnet add package Microsoft.EntityFrameworkCore.Sqlite
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet tool install --global dotnet-ef
dotnet ef migrations add Inicial
dotnet ef database update
dotnet ef migrations script --idempotent -o migracoes.sql
dotnet ef migrations bundle            # artefato para o pipeline de deploy
```

### 2.12 Consultas: Include filtrado, projeção, split query e keyset
```csharp
var times = await db.Times
    .AsNoTracking()
    .Include(t => t.Jogadores.Where(j => j.Ativo))
    .ToListAsync(ct);

var resumo = await db.Times
    .Select(t => new { t.Nome, Total = t.Jogadores.Count })
    .ToListAsync(ct);                     // projeção: só as colunas usadas

var completos = await db.Times
    .Include(t => t.Jogadores)
    .AsSplitQuery()                       // evita a explosão cartesiana
    .ToListAsync(ct);

var proxima = await db.Jogadores
    .OrderBy(j => j.Id)
    .Where(j => j.Id > ultimoId)          // keyset: não relê as páginas anteriores
    .Take(20)
    .ToListAsync(ct);
```

### 2.13 N+1 e navegação vazia (armadilha clássica)
```csharp
// Sem Include e sem lazy loading: t.Jogadores fica VAZIO (Count == 0)
// Com lazy loading: 1 query de times + 1 por time (N+1)
foreach (var t in await db.Times.ToListAsync())
    Console.WriteLine($"{t.Nome}: {t.Jogadores.Count}");

// Correto: uma ida ao banco, só o necessário
var linhas = await db.Times
    .Select(t => new { t.Nome, Qtd = t.Jogadores.Count })
    .ToListAsync();
```

### 2.14 ExecuteUpdate/ExecuteDelete e a pegadinha do change tracker
```csharp
await db.Jogadores
    .Where(j => j.Nivel < 3)
    .ExecuteUpdateAsync(s => s.SetProperty(j => j.Ativo, false), ct);

await db.Jogadores.Where(j => !j.Ativo).ExecuteDeleteAsync(ct);

// Pegadinha (doc oficial): nível no banco era 5
var ana = await db.Jogadores.SingleAsync(j => j.Apelido == "Ana"); // rastreado: 5
await db.Jogadores.ExecuteUpdateAsync(s =>
    s.SetProperty(j => j.Nivel, j => j.Nivel + 1));                 // banco: 6
ana.Nivel += 2;                                                     // memória: 7
await db.SaveChangesAsync();                                        // banco: 7
```

### 2.15 Concorrência otimista, 409 e transação
```csharp
public class Inventario
{
    public int Id { get; set; }
    public int Moedas { get; set; }
    [Timestamp] public byte[] Versao { get; set; } = [];  // rowversion (SQL Server)
}
// SQLite/PostgreSQL: use [ConcurrencyCheck] com Guid e troque o valor a cada gravação

try
{
    inventario.Moedas -= preco;
    await db.SaveChangesAsync(ct);
}
catch (DbUpdateConcurrencyException)
{
    return TypedResults.Conflict("Inventário mudou. Recarregue e tente de novo.");
}

await using var tx = await db.Database.BeginTransactionAsync(ct);
// ... várias operações + SaveChangesAsync ...
await tx.CommitAsync(ct);
```

### 2.16 SQL seguro, filtros nomeados e LeftJoin (EF 10)
```csharp
var nome = "Ana";
var lista = await db.Jogadores
    .FromSql($"SELECT * FROM Jogadores WHERE Apelido = {nome}")
    .ToListAsync(ct);                     // vira parâmetro: seguro
// PERIGO: FromSqlRaw("... WHERE Apelido = '" + nome + "'")

modelBuilder.Entity<Jogador>()
    .HasQueryFilter("Ativos", j => j.Ativo);           // EF 10: filtro nomeado
var todos = await db.Jogadores.IgnoreQueryFilters(["Ativos"]).ToListAsync();
// Atenção: o filtro vale para TODAS as consultas do DbSet, inclusive
// Where(...).ExecuteDeleteAsync(). Para apagar inativos, use IgnoreQueryFilters.

var semTime = db.Jogadores.LeftJoin(db.Times,
    j => j.TimeId, t => (int?)t.Id,
    (j, t) => new { j.Apelido, Time = t == null ? "[sem time]" : t.Nome });
```

### 2.17 Validação nativa (net10+) e ProblemDetails
```csharp
using System.ComponentModel.DataAnnotations;

builder.Services.AddValidation();       // sem isto, NADA é validado
builder.Services.AddProblemDetails();

app.MapPost("/cadastro", (Cadastro c) => TypedResults.Ok(c));
// inválido → 400 automático com a lista de erros (ValidationProblem)

public record Cadastro(
    [Required, StringLength(20, MinimumLength = 3)] string Apelido,
    [Range(1, 99)] int Nivel,
    [EmailAddress] string? Email);
```

### 2.18 IExceptionHandler + UseExceptionHandler
```csharp
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<RegraHandler>();
var app = builder.Build();
app.UseExceptionHandler();     // obrigatório para os handlers rodarem
app.UseStatusCodePages();      // 4xx/5xx sem corpo viram ProblemDetails

public sealed class RegraException(string msg) : Exception(msg) { }

public sealed class RegraHandler(IProblemDetailsService pds) : IExceptionHandler
{
    public async ValueTask<bool> TryHandleAsync(HttpContext http,
        Exception ex, CancellationToken ct)
    {
        if (ex is not RegraException) return false;   // deixa para o próximo
        http.Response.StatusCode = StatusCodes.Status422UnprocessableEntity;
        return await pds.TryWriteAsync(new ProblemDetailsContext
        {
            HttpContext = http,
            Exception = ex,
            ProblemDetails = new ProblemDetails
                { Title = "Regra violada", Detail = ex.Message }
        });
    }
}
```

### 2.19 OpenAPI + Scalar, CORS e pipeline completo recomendado
```csharp
using Scalar.AspNetCore;

// Pressupõe já registrados: AddProblemDetails, AddAuthentication/AddAuthorization,
// AddRateLimiter, AddOutputCache e AddDbContext (ver 2.18, 2.20, 2.21 e 2.22).
builder.Services.AddOpenApi();
builder.Services.AddCors(o => o.AddPolicy("Front", p => p
    .WithOrigins("https://meujogo.com.br")        // sem "/" no final!
    .AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();              // /openapi/v1.json
    app.MapScalarApiReference();   // /scalar
}
else
{
    app.UseExceptionHandler();
    app.UseHsts();
}
app.UseHttpsRedirection();
app.UseCors("Front");
app.UseAuthentication();
app.UseAuthorization();
app.UseRateLimiter();
app.UseOutputCache();              // depois de CORS e auth
app.MapRanking();
app.Run();
```

### 2.20 JWT Bearer, políticas e claims
```csharp
using System.Security.Claims;
using Microsoft.AspNetCore.Authentication.JwtBearer;

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(o =>
    {
        o.Authority = builder.Configuration["Auth:Authority"]; // IdP (OIDC)
        o.Audience = builder.Configuration["Auth:Audience"];
    });
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("Admin", p => p.RequireRole("admin"));

app.MapGet("/perfil", (ClaimsPrincipal user) =>
    user.FindFirst(ClaimTypes.NameIdentifier)?.Value)   // "sub" foi mapeado
   .RequireAuthorization();
app.MapDelete("/jogadores/{id:int}", (int id) => TypedResults.NoContent())
   .RequireAuthorization("Admin");
// Dev: dotnet user-jwts create --role "admin"
// curl -H "Authorization: Bearer <token>" https://localhost:7001/perfil
```

### 2.21 Rate limiting (anti-spam de palpites)
```csharp
using Microsoft.AspNetCore.RateLimiting;

builder.Services.AddRateLimiter(o =>
{
    o.RejectionStatusCode = StatusCodes.Status429TooManyRequests; // padrão: 503
    o.AddFixedWindowLimiter("palpites", opt =>
    {
        opt.PermitLimit = 5;
        opt.Window = TimeSpan.FromSeconds(10);
    });
});
// ...
app.UseRateLimiter();
app.MapPost("/palpites", (Palpite p) => TypedResults.Ok(p))
   .RequireRateLimiting("palpites");
```

### 2.22 Output cache com tags e HybridCache
```csharp
using Microsoft.AspNetCore.OutputCaching;
using Microsoft.Extensions.Caching.Hybrid;

builder.Services.AddOutputCache();
builder.Services.AddHybridCache();

app.MapGet("/ranking/top", async (JogoDb db) =>
        await db.Jogadores.OrderByDescending(j => j.Nivel).Take(10).ToListAsync())
   .CacheOutput(p => p.Expire(TimeSpan.FromSeconds(30)).Tag("ranking"));

app.MapPost("/pontos", async (IOutputCacheStore cache, CancellationToken ct) =>
{
    // ... grava pontos ...
    await cache.EvictByTagAsync("ranking", ct);   // invalida o top 10
    return TypedResults.NoContent();
});

app.MapGet("/perfil/{id:int}", async (int id, HybridCache cache,
    JogoDb db, CancellationToken ct) =>
    await cache.GetOrCreateAsync($"jogador:{id}",
        async token => await db.Jogadores
            .FirstOrDefaultAsync(j => j.Id == id, token),
        cancellationToken: ct));
```

### 2.23 Health checks (liveness x readiness)
```csharp
using Microsoft.AspNetCore.Diagnostics.HealthChecks;

builder.Services.AddHealthChecks()
    .AddDbContextCheck<JogoDb>(tags: ["ready"]);   // usa CanConnectAsync

app.MapHealthChecks("/healthz/live",
    new HealthCheckOptions { Predicate = _ => false });   // só "o processo vive?"
app.MapHealthChecks("/healthz/ready",
    new HealthCheckOptions { Predicate = c => c.Tags.Contains("ready") });
```

### 2.24 BackgroundService com escopo e PeriodicTimer
```csharp
public sealed class LimpezaWorker(IServiceScopeFactory scopes,
    ILogger<LimpezaWorker> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        using var timer = new PeriodicTimer(TimeSpan.FromMinutes(5));
        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            await using var scope = scopes.CreateAsyncScope();  // DbContext é scoped
            var db = scope.ServiceProvider.GetRequiredService<JogoDb>();
            var n = await db.Jogadores.Where(j => !j.Ativo)
                .ExecuteDeleteAsync(stoppingToken);
            logger.LogInformation("Removidos {Qtd} inativos", n);
        }
    }
}
// builder.Services.AddHostedService<LimpezaWorker>();
// Worker puro: var b = Host.CreateApplicationBuilder(args); ... b.Build().Run();
```

### 2.25 HttpClient tipado + resiliência (ViaCEP)
```csharp
using Microsoft.Extensions.Http.Resilience;   // DisableForUnsafeHttpMethods

builder.Services.AddHttpClient<ViaCepClient>(c =>
        c.BaseAddress = new Uri("https://viacep.com.br/ws/"))  // barra final!
    .AddStandardResilienceHandler(o => o.Retry.DisableForUnsafeHttpMethods());

public sealed class ViaCepClient(HttpClient http)
{
    public Task<Endereco?> BuscarAsync(string cep, CancellationToken ct) =>
        http.GetFromJsonAsync<Endereco>($"{cep}/json/", ct);
}

public record Endereco(string? Cep, string? Logradouro, string? Bairro,
    string? Localidade, string? Uf, string? Erro);
// CEP inexistente → 200 com {"erro":"true"}; CEP malformado → 400
// (GetFromJsonAsync lança HttpRequestException em status não-sucesso)
```

### 2.26 SignalR: sala de jogo tipada, IHubContext e cliente .NET
```csharp
using Microsoft.AspNetCore.SignalR;

public interface IClienteSala
{
    Task JogadorEntrou(string apelido);
    Task PlacarAtualizado(string apelido, int pontos);
}

public sealed class SalaHub : Hub<IClienteSala>
{
    public async Task Entrar(string sala, string apelido)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, sala);
        await Clients.OthersInGroup(sala).JogadorEntrou(apelido);
    }
}
// builder.Services.AddSignalR();  app.MapHub<SalaHub>("/hubs/sala");

app.MapPost("/salas/{sala}/pontos", async (string sala, Palpite p,
    IHubContext<SalaHub, IClienteSala> hub) =>
{
    await hub.Clients.Group(sala).PlacarAtualizado("bot", p.Numero);
    return TypedResults.Accepted($"/salas/{sala}");
});
```
```csharp
using Microsoft.AspNetCore.SignalR.Client;

var conexao = new HubConnectionBuilder()
    .WithUrl("https://localhost:7001/hubs/sala")
    .WithAutomaticReconnect()
    .Build();
conexao.On<string, int>("PlacarAtualizado",
    (apelido, pontos) => Console.WriteLine($"{apelido}: {pontos}"));
await conexao.StartAsync();
await conexao.InvokeAsync("Entrar", "sala-1", "Ana");
```

### 2.27 Server-Sent Events (net10+)
```csharp
using System.Net.ServerSentEvents;
using System.Runtime.CompilerServices;

app.MapGet("/placar/stream", (CancellationToken ct) =>
{
    async IAsyncEnumerable<SseItem<int>> Pontos(
        [EnumeratorCancellation] CancellationToken token)
    {
        var total = 0;
        while (!token.IsCancellationRequested)
        {
            total += Random.Shared.Next(1, 10);
            yield return new SseItem<int>(total, eventType: "placar");
            await Task.Delay(1000, token);
        }
    }
    return TypedResults.ServerSentEvents(Pontos(ct));
});
```

### 2.28 gRPC: contrato, serviço e cliente com deadline
```protobuf
syntax = "proto3";
option csharp_namespace = "Jogo.Grpc";

service Placar {
  rpc Registrar (PontoRequest) returns (PlacarReply);
  rpc Acompanhar (SalaRequest) returns (stream PlacarReply);
}
message PontoRequest { string jogador = 1; int32 pontos = 2; }
message SalaRequest { string sala = 1; }
message PlacarReply { string jogador = 1; int32 total = 2; }
```
```csharp
using Grpc.Core;          // ServerCallContext
using Grpc.Net.Client;    // GrpcChannel (lado cliente)
using Jogo.Grpc;          // tipos gerados do .proto (Grpc.Tools)

public class PlacarService : Placar.PlacarBase
{
    public override Task<PlacarReply> Registrar(PontoRequest request,
        ServerCallContext context) =>
        Task.FromResult(new PlacarReply
            { Jogador = request.Jogador, Total = request.Pontos });
}
// builder.Services.AddGrpc();  app.MapGrpcService<PlacarService>();

using var canal = GrpcChannel.ForAddress("https://localhost:7001");
var cliente = new Placar.PlacarClient(canal);
var r = await cliente.RegistrarAsync(
    new PontoRequest { Jogador = "Ana", Pontos = 10 },
    deadline: DateTime.UtcNow.AddSeconds(5));  // sem isso: sem limite de tempo
```

### 2.29 Aspire: AppHost, service defaults e integração client
```csharp
// AppHost: <Project Sdk="Aspire.AppHost.Sdk/13.0.0"> (use a versão atual)
// + pacotes Aspire.Hosting.Redis e Aspire.Hosting.PostgreSQL
var builder = DistributedApplication.CreateBuilder(args);
var cache = builder.AddRedis("cache");
var db = builder.AddPostgres("postgres").AddDatabase("jogodb");
builder.AddProject<Projects.Jogo_Api>("api")
    .WithReference(cache).WithReference(db)
    .WaitFor(db);
builder.Build().Run();
```
```csharp
// Program.cs da API (pacotes Aspire.Npgsql.EntityFrameworkCore.PostgreSQL
// e Aspire.StackExchange.Redis + referência ao projeto ServiceDefaults)
builder.AddServiceDefaults();                      // OTel, health, discovery, resiliência
builder.AddNpgsqlDbContext<JogoDb>("jogodb");      // mesmo nome do AppHost
builder.AddRedisClient("cache");
var app = builder.Build();
app.MapDefaultEndpoints();                         // /health e /alive (só Dev)
```

### 2.30 Testes: unidade de handler e integração
```csharp
using System.Net;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Mvc.Testing;

public class RankingTests(WebApplicationFactory<Program> fabrica)
    : IClassFixture<WebApplicationFactory<Program>>
{
    [Fact]
    public async Task GetRanking_Retorna200()
    {
        var cliente = fabrica.CreateClient();
        var resposta = await cliente.GetAsync("/ranking");
        Assert.Equal(HttpStatusCode.OK, resposta.StatusCode);
    }
}

public class HandlerTests
{
    [Fact]   // Handlers.Obter = método estático do endpoint; dbVazio = contexto de teste
    public async Task Obter_Inexistente_DaNotFound()
    {
        Results<Ok<JogadorDto>, NotFound> r = await Handlers.Obter(999, dbVazio);
        Assert.IsType<NotFound>(r.Result);
    }
}
// Banco real: var pg = new PostgreSqlBuilder("postgres:15.1").Build();
//             await pg.StartAsync(); var cs = pg.GetConnectionString();
```

### 2.31 Controller equivalente (para comparar)
```csharp
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

[ApiController]
[Route("api/[controller]")]
public class JogadoresController(JogoDb db) : ControllerBase
{
    [HttpGet("{id:int}")]
    public async Task<ActionResult<JogadorDto>> Obter(int id, CancellationToken ct)
    {
        var dto = await db.Jogadores.AsNoTracking()
            .Where(j => j.Id == id)
            .Select(j => new JogadorDto(j.Id, j.Apelido, j.Nivel))
            .FirstOrDefaultAsync(ct);
        if (dto is null) return NotFound();
        return dto;
    }
}
// Program.cs: builder.Services.AddControllers(); ... app.MapControllers();
```

## 3. Armadilhas e boas práticas que o curso deve ensinar

**HTTP e API**
- Status certo: POST que cria devolve **201 + Location**; DELETE devolve 204; recurso inexistente dá 404; conflito de estado dá 409. 401 significa não autenticado; 403 significa autenticado sem permissão.
- PUT e DELETE devem ser idempotentes; POST não é, então retry automático de POST pode duplicar pedidos.
- API não espelha tabelas. Use DTOs de entrada e saída, o que evita mass assignment e vazamento de colunas.
- Nunca devolva `IEnumerable` gigante: pagine. Offset fica lento com o volume; keyset precisa de ordem única.

**Minimal APIs**
- `{id:int}` com "abc" dá **404** (a rota não casa). Sem constraint, `(int id)` com "abc" dá **400** (falha de binding).
- Parâmetro complexo em MapGet não vem do corpo, porque GET não lê corpo implicitamente. A 1ª requisição falha com 500 e "Body was inferred but the method does not allow inferred body parameters"; use `[AsParameters]` para ler da query ou troque o verbo.
- `string` retorna text/plain e objeto retorna JSON. Um ternário com `TypedResults` diferentes exige declarar `Results<A,B>`, e devolver um tipo fora da lista é erro de compilação.
- `Run()` é terminal: nada registrado depois dele executa. Não chame `next` depois de começar a escrever o corpo, e não altere headers ou status depois disso.

**Pipeline e ordem**
- Ordem: `UseExceptionHandler` primeiro, `UseCors` antes de `UseAuthentication`, e esse antes de `UseAuthorization`. `UseOutputCache` vem depois de CORS e auth (senão serve cache de usuário autorizado para anônimo). `UseRateLimiter` vem depois do routing quando o limite é por endpoint.
- O `WebApplication` já adiciona Routing, Authentication e Authorization quando os serviços existem. Só chame manualmente se precisar controlar a ordem.

**DI e configuração**
- Dependência cativa: singleton segurando scoped (ex.: `DbContext`). Em Development o erro aparece (ValidateScopes); em Production passa calado e corrompe estado.
- Não injete scoped no construtor de middleware; injete no `InvokeAsync`. Dentro de BackgroundService, crie escopo.
- Evite service locator (`GetService` espalhado) e `BuildServiceProvider()` no registro. Singleton precisa ser thread-safe, e o container não torna o seu código thread-safe.
- `IOptionsSnapshot` é scoped e não entra em singleton. Para recarregar config em singleton, use `IOptionsMonitor`. Use `ValidateOnStart()` para falhar cedo.
- Variável de ambiente sobrescreve appsettings; em Linux use `Secao__Chave`. Sem variável de ambiente definida, o ambiente é Production (o `dotnet run` usa o `launchSettings.json`, que põe Development). Segredo não vai para appsettings versionado: use user-secrets em dev e um cofre em produção.

**Logging e erros**
- Template com placeholders nomeados, nunca interpolação `$"..."`. Os valores vão para os placeholders pela ORDEM dos argumentos, não pelo nome.
- Em produção, não exponha stack trace: use ProblemDetails. `IExceptionHandler` só roda com `UseExceptionHandler()`. Retornar `true` significa "eu escrevi a resposta": sem escrever, o cliente recebe 500 vazio (testado; a doc cita 404 nesse caso).
- Exceção é cara e não serve para controle de fluxo.

**EF Core**
- `DbContext` não é thread-safe: nada de `Task.WhenAll` com o mesmo contexto. Faça `await` imediato em cada operação.
- Sem `Include`, a navegação vem vazia. Lazy loading esconde N+1: prefira projeção ou Include.
- Leitura usa `AsNoTracking()` ou projeção. `ToList()` antes de `Where` puxa a tabela inteira para a memória.
- Dois `Include` de coleções irmãs causam explosão cartesiana; resolva com `AsSplitQuery()` e ordenação única.
- `ExecuteUpdate/Delete` ignoram o change tracker e não abrem transação implícita: não misture com entidades rastreadas no mesmo fluxo.
- `EnsureCreated()` não combina com migrations. Em produção, rode migrations por bundle ou script revisado, não na inicialização de cada réplica. Revise a migration gerada (pode haver perda de dados).
- `FromSqlRaw` com concatenação é injeção de SQL; use `FromSql($"...")`.
- Trate `DbUpdateConcurrencyException` com 409. Sem token de concorrência vale "o último a salvar vence", e dados se perdem em silêncio.
- Em Blazor ou em várias unidades de trabalho por requisição, use `AddDbContextFactory`. Contexto em pool compartilha estado: não guarde dado por requisição no `OnConfiguring`.

**Segurança**
- Valide assinatura, emissor, audiência e expiração do JWT. `ClockSkew` padrão é de 5 min (token "expirado" ainda passa). Com `MapInboundClaims`, `"sub"` vira `ClaimTypes.NameIdentifier`.
- Chave HS256 com menos de 32 bytes gera IDX10720. Em produção prefira IdP/OIDC e chaves assimétricas.
- CORS: nada de `AllowAnyOrigin()` com `AllowCredentials()`; origem sem barra no final.
- UI de OpenAPI (Scalar/Swagger) só em Development.

**Performance e resiliência**
- Não bloqueie com `.Result` ou `.Wait()` (starvation do thread pool). Passe `CancellationToken` até o banco e o HttpClient.
- `new HttpClient()` a cada requisição esgota sockets. Um `HttpClient` estático eterno ignora mudança de DNS; resolva com `PooledConnectionLifetime` ou factory.
- `BaseAddress` precisa terminar em `/` e o caminho relativo não pode começar com `/`, senão parte da URL se perde.
- Cliente tipado é transient: capturado num singleton, ele para de reagir a DNS.
- Standard resilience handler faz retry em POST por padrão; use `DisableForUnsafeHttpMethods()`. Não empilhe vários handlers de resiliência.
- Rate limiter rejeita com **503** por padrão; configure 429 e o header `Retry-After`.
- Output cache não guarda resposta de requisição autenticada nem resposta que grava cookie. Invalide com tags.
- Chave de cache com separador: `order{c}{o}` pode colidir (42+123 = 421+23). Não use entrada crua do usuário como chave.

**Background e operação**
- Exceção não tratada no `ExecuteAsync` DERRUBA o host (padrão desde o .NET 6). Trate e logue dentro do loop.
- No .NET 10, código síncrono no início do `ExecuteAsync` não bloqueia mais a subida dos outros serviços. Para rodar antes, use o construtor ou sobrescreva `StartAsync`.
- `StopAsync` tem 30 s por padrão para desligar com graça; respeite o `stoppingToken`.
- Liveness não checa dependências (senão um banco fora reinicia todos os pods); readiness checa.
- Não capture `HttpContext` nem serviços da requisição em `Task.Run`: copie os dados e crie escopo.

**Tempo real e gRPC**
- A instância do hub é criada por invocação: não guarde estado em campos do hub. Grupos somem na reconexão e diferenciam maiúsculas.
- Só `HubException` chega ao cliente com a mensagem; outras exceções chegam genéricas.
- Com várias instâncias de SignalR, sticky sessions são obrigatórias (mesmo com Redis), salvo Azure SignalR ou só WebSockets com SkipNegotiation.
- gRPC sem deadline pode esperar para sempre. Propague `context.CancellationToken`. Não use o método síncrono do cliente.
- Broadcast para navegadores é trabalho do SignalR (ou SSE); gRPC é serviço ↔ serviço.

## 4. Ideias de exercícios

### 4.1 Digitação (1–8 linhas, ≤ 70 colunas)
Convenção: ` / ` separa exercícios independentes; `⏎` marca quebra de linha DENTRO do mesmo comando, e a linha seguinte começa indentada com 4 espaços.
- `var builder = WebApplication.CreateBuilder(args);` / `var app = builder.Build();` / `app.Run();`
- `app.MapGet("/ping", () => "pong");`
- `app.MapGet("/dobro/{n:int}", (int n) => n * 2);`
- `app.MapGet("/ola", (string nome) => $"Olá, {nome}!");`
- `app.MapPost("/itens", (Item item) =>` ⏎ `TypedResults.Created($"/itens/{item.Id}", item));`
- `return TypedResults.NotFound();` / `return TypedResults.NoContent();` / `return TypedResults.Conflict("ocupado");`
- `var grupo = app.MapGroup("/api/times").WithTags("Times");`
- `grupo.MapDelete("/{id:int}", RemoverAsync);`
- `async Task<Results<Ok<Time>, NotFound>> (int id, JogoDb db) =>`
- `app.Use(async (ctx, next) => { await next(ctx); });`
- `app.UseMiddleware<TempoMiddleware>();`
- `ctx.Response.Headers["X-Versao"] = "1.0";`
- `builder.Services.AddScoped<IRanking, Ranking>();`
- `builder.Services.AddSingleton(TimeProvider.System);`
- `builder.Services.AddKeyedScoped<IFrete, FreteSedex>("sedex");`
- `await using var scope = scopes.CreateAsyncScope();`
- `var cs = builder.Configuration.GetConnectionString("Jogo");`
- `var max = builder.Configuration` ⏎ `.GetValue<int>("Partida:MaxJogadores");`
- `builder.Services.Configure<PartidaOptions>(` ⏎ `builder.Configuration.GetSection("Partida"));`
- `builder.Services.AddOptions<JwtOptions>()` ⏎ `.Bind(builder.Configuration.GetSection("Jwt"))` ⏎ `.ValidateDataAnnotations()` ⏎ `.ValidateOnStart();`
- `if (app.Environment.IsDevelopment()) app.MapOpenApi();`
- `logger.LogWarning("Estoque baixo: {Produto} ({Qtd})", nome, qtd);`
- `logger.LogError(ex, "Falha ao salvar pedido {PedidoId}", id);`
- `public DbSet<Partida> Partidas => Set<Partida>();`
- `public class LojaDb(DbContextOptions<LojaDb> o) : DbContext(o) { }`
- `builder.Services.AddDbContext<LojaDb>(o => o.UseSqlite(cs));`
- `dotnet ef migrations add AdicionaEstoque` / `dotnet ef database update`
- `var p = await db.Produtos.FindAsync(id);`
- `db.Produtos.Remove(p);` / `await db.SaveChangesAsync(ct);`
- `.Include(p => p.Itens).ThenInclude(i => i.Produto)`
- `.AsNoTracking().Where(p => p.Preco > 10).ToListAsync(ct);`
- `.OrderBy(p => p.Id).Where(p => p.Id > ultimo).Take(20)`
- `.Select(t => new TimeDto(t.Id, t.Nome, t.Jogadores.Count))`
- `await db.Sessoes.Where(s => s.Expira < agora).ExecuteDeleteAsync();`
- `.ExecuteUpdateAsync(s =>` ⏎ `s.SetProperty(p => p.Preco, p => p.Preco * 1.1m));`
- `[Timestamp] public byte[] Versao { get; set; } = [];`
- `catch (DbUpdateConcurrencyException)` ⏎ `{` ⏎ `return TypedResults.Conflict();` ⏎ `}`
- `modelBuilder.Entity<Pedido>().HasQueryFilter(p => !p.Excluido);`
- `builder.Services.AddValidation();`
- `public record NovoTime([Required, MaxLength(30)] string Nome);`
- `builder.Services.AddProblemDetails();` / `app.UseExceptionHandler();` / `app.UseStatusCodePages();`
- `return TypedResults.Problem("Saldo insuficiente", statusCode: 422);`
- `builder.Services.AddExceptionHandler<RegraHandler>();`
- `builder.Services.AddOpenApi();` / `app.MapScalarApiReference();`
- `p.WithOrigins("https://site.com.br")` ⏎ `.AllowAnyHeader().AllowAnyMethod()`
- `builder.Services.AddAuthentication().AddJwtBearer();`
- `app.MapGet("/admin", () => "ok").RequireAuthorization("Admin");`
- `app.MapGet("/login", () => "livre").AllowAnonymous();`
- `.AddPolicy("Maior", p => p.RequireClaim("idade_ok", "true"));`
- `dotnet user-jwts create --role "admin"`
- `o.AddFixedWindowLimiter("api", x =>` ⏎ `{` ⏎ `x.PermitLimit = 10;` ⏎ `x.Window = TimeSpan.FromSeconds(1);` ⏎ `});`
- `.RequireRateLimiting("api");` / `.CacheOutput(p => p.Tag("ranking"));`
- `await cache.EvictByTagAsync("ranking", ct);`
- `await hybrid.GetOrCreateAsync($"p:{id}",` ⏎ `async t => await Buscar(id, t));`
- `builder.Services.AddHealthChecks().AddDbContextCheck<JogoDb>();` / `app.MapHealthChecks("/healthz");`
- `builder.Services.AddHostedService<LimpezaWorker>();`
- `using var timer = new PeriodicTimer(TimeSpan.FromSeconds(30));`
- `while (await timer.WaitForNextTickAsync(stoppingToken)) { ... }`
- `builder.Services.AddHttpClient<ViaCepClient>(c =>` ⏎ `c.BaseAddress = new("https://viacep.com.br/ws/"));`
- `.AddStandardResilienceHandler();`
- `var end = await http.GetFromJsonAsync<Endereco>($"{cep}/json/", ct);`
- `public sealed class ChatHub : Hub { }` / `app.MapHub<ChatHub>("/chat");`
- `await Clients.All.SendAsync("Mensagem", usuario, texto);`
- `await Groups.AddToGroupAsync(Context.ConnectionId, sala);`
- `await Clients.Group(sala).PlacarAtualizado(apelido, pontos);`
- `return TypedResults.ServerSentEvents(Eventos(ct), eventType: "tick");`
- `rpc Registrar (PontoRequest) returns (PlacarReply);`
- `builder.Services.AddGrpc();` / `app.MapGrpcService<PlacarService>();`
- `var canal = GrpcChannel.ForAddress("https://localhost:7001");`
- `var cache = builder.AddRedis("cache");` / `.WithReference(cache).WaitFor(cache);`
- `builder.AddServiceDefaults();` / `app.MapDefaultEndpoints();`
- `var cliente = fabrica.CreateClient();` / `Assert.Equal(HttpStatusCode.Created, resp.StatusCode);`

### 4.2 Desafios de lógica (não são de digitação; gabarito incluso)
1. **Prever a saída (ini) [testado]:** três `app.Use` (A, B, C), cada um imprimindo antes e depois do `next`, e depois `app.Run`. → A antes, B antes, C antes, C depois, B depois, A depois.
2. **Prever (ini) [testado]:** um `app.Use` registrado DEPOIS de `app.Run(...)` imprime algo? → Não, `Run` é terminal.
3. **Prever o status (ini) [testado]:** rota `/itens/{id:int}` com GET `/itens/abc`. → 404. E com rota `/itens/{id}` e handler `(int id)`? → 400.
4. **Prever (ini) [testado]:** `MapGet("/busca", (string termo) => ...)` com GET `/busca`. → 400 (parâmetro obrigatório ausente). Com `string? termo`? → 200 e termo nulo.
5. **Escolha (ini):** qual status devolver? Criou recurso → 201; apagou → 204; não achou → 404; token ausente → 401; sem permissão → 403; e-mail já usado → 409.
6. **Completar lacuna (ini):** `builder.Services.____<JogoDb>(o => o.UseSqlite(cs));` → `AddDbContext`.
7. **Completar lacuna (ini):** `app.MapGroup("/times").____("Times");` → `WithTags`.
8. **Ordenar linhas (int):** embaralhe `UseAuthorization`, `UseExceptionHandler`, `UseCors`, `UseAuthentication`, `UseHttpsRedirection`, `MapControllers`. → ExceptionHandler, HttpsRedirection, Cors, Authentication, Authorization, MapControllers.
9. **Achar o bug (int):** `UseAuthorization()` antes de `UseAuthentication()`. → O usuário ainda não foi autenticado quando a autorização roda; inverta a ordem.
10. **Valor final (int) [testado]:** 3 requisições, cada uma resolvendo o serviço X duas vezes. Quantas instâncias existem se X for Transient, Scoped ou Singleton? → 6, 3 e 1.
11. **Achar o bug (int):** `AddSingleton<Ranking>()` e `Ranking(JogoDb db)`. → Dependência cativa: o `DbContext` scoped fica preso no singleton. Em Development o app lança erro; torne o serviço Scoped ou use `IServiceScopeFactory`.
12. **Prever (int) [testado]:** `appsettings.json` tem `Max=4`, `appsettings.Development.json` tem `Max=6`, a variável `Partida__Max=8` está definida e a app é iniciada com `--Partida:Max=10`. → 10. Sem o argumento? → 8. Sem a variável e em Production? → 4.
13. **Prever (ini) [testado]:** app publicada, rodando com `dotnet App.dll` sem `ASPNETCORE_ENVIRONMENT`/`DOTNET_ENVIRONMENT`; `app.Environment.IsDevelopment()`? → false, o padrão é Production. Pegadinha: com `dotnet run`, o `launchSettings.json` do template define Development.
14. **Escolha (int):** um singleton precisa ver a config nova sem reiniciar. → `IOptionsMonitor<T>` (`IOptions` não recarrega e `IOptionsSnapshot` é scoped).
15. **Prever (int) [testado]:** `LogInformation("{Pera}, {Uva}, {Maca}", maca, pera, uva)` com maca=1, pera=2, uva=3. → "1, 2, 3", porque vale a ordem dos argumentos.
16. **Achar o bug (int):** `logger.LogInformation($"Pedido {id} pago");` → Interpolação perde o campo estruturado `PedidoId`; use template com placeholder.
17. **Prever a ordem (int) [testado]:** três `AddEndpointFilter` (F1, F2, F3), cada um logando antes e depois do `next`. → F1, F2, F3, handler, F3, F2, F1.
18. **Valor final (int) [testado]:** `var n = await db.Times.Where(t => t.Id == 1).ToListAsync(); n[0].Jogadores.Count` sem Include e com contexto novo. → 0 (navegação não carregada).
19. **Contar consultas (int):** 10 times, lazy loading ligado, `foreach` lendo `t.Jogadores`. Quantos SELECTs? → 11 (N+1).
20. **Valor final (ava) [testado]:** o `Nivel` de Ana no banco é 5. Ela é carregada (rastreada), vem `ExecuteUpdate` de +1 em todos, depois `ana.Nivel += 2` e `SaveChanges`. Qual o nível final no banco? → 7 (o +1 do ExecuteUpdate foi sobrescrito).
21. **Prever (int) [testado]:** `.Take(10).Skip(20)` sobre 100 linhas. → Vazio. E `.Skip(20).Take(10)`? → Itens 21 a 30.
22. **Keyset (int):** a última linha da página tinha Id 55 e o tamanho da página é 10. Qual o `Where` da próxima? → `Id > 55`, com `OrderBy(Id)` e `Take(10)`.
23. **Achar o bug (int):** `db.Produtos.ToList().Where(p => p.Preco > 10)`. → O filtro roda em memória depois de trazer a tabela inteira; filtre antes, no `IQueryable`, e use a versão async.
24. **Achar o bug (ava):** `await Task.WhenAll(db.A.ToListAsync(), db.B.ToListAsync());` com o mesmo contexto. → `InvalidOperationException`, porque o `DbContext` não aceita operações paralelas.
25. **Prever (ava):** dois usuários compram o mesmo item com `[Timestamp]` configurado. → O segundo `SaveChanges` lança `DbUpdateConcurrencyException`, que vira 409.
26. **Achar o bug (int):** `EnsureCreated()` seguido de `Migrate()`. → `Migrate` falha, porque o schema foi criado fora das migrations.
27. **Ordenar (ini):** criar a migration → revisar o arquivo → `database update` → commitar migration e snapshot.
28. **Prever (int) [testado]:** POST com um record de `[Range(1, 99)] int Nivel` recebendo `Nivel=150`, sem `AddValidation()`. → O handler roda normalmente (nada valida). Com `AddValidation()`? → 400 com ProblemDetails de validação.
29. **Prever (int):** handler retorna `Results<Ok<T>, NotFound>` e alguém adiciona `return TypedResults.BadRequest();`. → Erro de compilação, porque BadRequest não está na lista.
30. **Prever (ava) [testado]:** `IExceptionHandler` retorna `true` sem escrever nada. → O cliente recebe 500 com corpo vazio: o middleware já tinha posto 500 e nenhum ProblemDetails é gerado. Lição: quem retorna `true` escreve a resposta inteira.
31. **Achar o bug (int):** CORS com `WithOrigins("https://jogo.com.br/")`. → A barra final faz a origem nunca bater.
32. **Prever (ava):** token expirou às 10:00 e a requisição chega às 10:03, com configuração padrão. → Aceito, pelo `ClockSkew` de 5 min.
33. **Prever (ava):** `user.FindFirst("sub")` com JwtBearer padrão. → `null`; a claim foi mapeada para `ClaimTypes.NameIdentifier`.
34. **Escolha (int):** um usuário logado sem a role "admin" chama um endpoint de admin. 401 ou 403? → 403.
35. **Prever (int) [testado]:** limite de 5 por janela de 10 s e 7 requisições seguidas, sem configurar `RejectionStatusCode`. → 5 respostas 200 e 2 respostas 503.
36. **Prever (int):** `/ranking` com `CacheOutput()` chamado por usuário autenticado. → Não é cacheado pela política padrão.
37. **Prever (int) [testado]:** `BaseAddress = "https://api.jogo.com/v1"` (sem barra) e `GetAsync("ranking")`. → Vai para `https://api.jogo.com/ranking`. Com `/v1/` e `"ranking"`? → `/v1/ranking`. Com `/v1/` e `"/ranking"`? → `/ranking`.
38. **Achar o bug (ava):** `AddStandardResilienceHandler()` num cliente que cria pedidos via POST. → O retry pode duplicar pedidos; use `DisableForUnsafeHttpMethods()` ou chave de idempotência.
39. **Prever (int) [testado]:** ViaCEP com CEP `99999999`. → HTTP 200 com `{"erro":"true"}`, então o código tem de checar `Erro`. Com `123`? → 400, e `GetFromJsonAsync` lança exceção.
40. **Prever (ava):** `BackgroundService` lança exceção não tratada dentro do loop. → O host para (comportamento padrão `StopHost`).
41. **Escolha (ava):** o endpoint de liveness deve checar o banco? → Não, isso é papel do readiness (senão o banco fora derruba todos os pods).
42. **Escolha (ava):** placar ao vivo para 5.000 navegadores numa sala. SignalR, gRPC ou polling? → SignalR com grupo (ou SSE, se for só servidor → cliente).
43. **Prever (ava):** um jogador reconecta ao SignalR. Continua no grupo "sala-1"? → Não; o cliente precisa chamar `Entrar` de novo.
44. **Prever (ava):** chamada gRPC sem `deadline` a um servidor travado. → Espera indefinidamente, porque não há deadline padrão.
45. **Valor final (ini, tema jogos) [testado]:** ranking com Ana 30, Bia 50, Caio 50 e Duda 10, via `OrderByDescending(Pontos).ThenBy(Nome).Take(3)`. → Bia, Caio, Ana.
46. **Achar o bug (ava) [testado]:** há o filtro nomeado `HasQueryFilter("Ativos", j => j.Ativo)` e o worker executa `db.Jogadores.Where(j => !j.Ativo).ExecuteDeleteAsync()`. Quantas linhas ele apaga? → 0, porque o filtro esconde os inativos. Correção: `IgnoreQueryFilters(["Ativos"])` antes do `Where`.
47. **Prever (int) [testado]:** `app.MapGet("/filtro", (Filtro f) => f.Modo);` com `record Filtro(string Modo)`. → A app sobe, mas a 1ª requisição falha com 500: `InvalidOperationException` ("Body was inferred but the method does not allow inferred body parameters"). Correção: `[AsParameters] Filtro f` (campos vêm da query) ou trocar para MapPost.
48. **Completar lacuna (ava):** `await using var scope = scopes.____();` dentro do `ExecuteAsync`, para obter o `JogoDb`. → `CreateAsyncScope`.

### 4.3 Projetos "Mão na Massa" por nível
- **Júnior:** "API do Placar" com Minimal API, SQLite e migrations: CRUD de jogadores e partidas, ranking top 10, OpenAPI + Scalar, validação, ProblemDetails e 5 testes de integração.
- **Pleno:** "Loja de itens do jogo": JWT + políticas (admin), inventário com concorrência otimista, cache do catálogo (HybridCache) e do ranking (output cache com tags), rate limit nos palpites, worker que encerra partidas inativas, cliente ViaCEP com resiliência, Testcontainers e container publicado.
- **Sênior:** "Arena multiplayer": salas em tempo real com SignalR, serviço de placar em gRPC com streaming, fila de eventos com outbox, Aspire (API + Postgres + Redis), dashboard OTel, health de readiness e liveness, migrations por bundle e um documento de trade-offs (ADR).

## 5. URLs consultadas

Todas foram abertas nesta pesquisa (WebFetch, curl com `Accept: text/markdown` ou JSON oficial). As da Microsoft Learn usam `?view=aspnetcore-10.0` quando há versões.

**Roadmaps e carreira**
- https://roadmap.sh/aspnet-core (JSON oficial: https://roadmap.sh/aspnet-core.json) · https://roadmap.sh/backend (JSON oficial: https://roadmap.sh/backend.json) · https://roadmap.sh/software-design-architecture
- https://roadmap.sh/system-design · https://roadmap.sh/api-design · https://github.com/kamranahmedse/developer-roadmap (conteúdo dos nós)
- https://github.com/milanm/DotNet-Developer-Roadmap · https://github.com/MoienTajik/AspNetCore-Developer-Roadmap · https://github.com/GomesRobert/aspnetcore-roadmap
- https://codewithmukesh.com/blog/dotnet-developer-roadmap/ · https://learn.microsoft.com/en-us/training/paths/aspnet-core-minimal-api/

**Versões e novidades**
- https://dotnet.microsoft.com/en-us/platform/support/policy/dotnet-core · https://learn.microsoft.com/en-us/dotnet/core/whats-new/dotnet-11/overview · https://devblogs.microsoft.com/dotnet/dotnet-11-rc-1/
- https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-10.0?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/release-notes/aspnetcore-11?view=aspnetcore-11.0 · https://learn.microsoft.com/en-us/ef/core/what-is-new/
- https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/whatsnew

**HTTP e REST**
- https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/Overview · https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Status · https://www.rfc-editor.org/rfc/rfc9110.html
- https://www.rfc-editor.org/rfc/rfc9457.html · https://learn.microsoft.com/en-us/azure/architecture/best-practices/api-design · https://learn.microsoft.com/en-us/dotnet/standard/serialization/system-text-json/overview

**ASP.NET Core (fundamentos, APIs, host)**
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/apis?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/webapplication?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/route-handlers?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/parameter-binding?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/responses?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/min-api-filters?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/security?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/handle-errors?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/minimal-apis/test-min-api?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/tutorials/min-web-api?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/tutorials/first-web-api?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/web-api/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/web-api/action-return-types?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/routing?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/middleware/write?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/dependency-injection?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview · https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/service-lifetimes
- https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection-guidelines · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/configuration/options?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/dotnet/core/extensions/options · https://learn.microsoft.com/en-us/dotnet/core/extensions/options-validation-generator · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/environments?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/security/app-secrets?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/logging/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/dotnet/core/extensions/logging
- https://learn.microsoft.com/en-us/dotnet/core/extensions/logging/source-generation · https://learn.microsoft.com/en-us/dotnet/core/extensions/generic-host · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/generic-host?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/host/hosted-services?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/dotnet/core/extensions/workers · https://learn.microsoft.com/en-us/dotnet/core/extensions/scoped-service
- https://learn.microsoft.com/en-us/dotnet/core/compatibility/extensions/10.0/backgroundservice-executeasync-task · https://learn.microsoft.com/en-us/dotnet/core/compatibility/core-libraries/6.0/hosting-exception-handling · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/dotnet/core/project-sdk/overview · https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-new-sdk-templates · https://learn.microsoft.com/en-us/aspnet/core/test/http-files?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/best-practices?view=aspnetcore-10.0 · https://andrewlock.net/behind-the-scenes-of-minimal-apis-3-exploring-the-model-binding-logic-of-minimal-apis/ (erro de corpo inferido em GET)

**Qualidade, segurança e desempenho**
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/validation?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/mvc/models/validation?view=aspnetcore-10.0 · https://docs.fluentvalidation.net/
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/error-handling?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/overview?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/aspnetcore-openapi?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/fundamentals/openapi/using-openapi-documents?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/security/cors?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/security/authentication/configure-jwt-bearer-authentication?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/security/authentication/jwt-authn?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/security/authentication/claims?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/security/authorization/policies?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/security/authorization/roles?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/security/authentication/identity-api-authorization?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/security/enforcing-ssl?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/security/data-protection/introduction?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/dotnet/api/microsoft.identitymodel.tokens.tokenvalidationparameters.defaultclockskew?view=msal-web-dotnet-latest · https://github.com/AzureAD/azure-activedirectory-identitymodel-extensions-for-dotnet/wiki/IDX10720
- https://learn.microsoft.com/en-us/aspnet/core/performance/rate-limit?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/dotnet/api/microsoft.aspnetcore.ratelimiting.ratelimiteroptions.rejectionstatuscode?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/performance/caching/overview?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/performance/caching/output?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/performance/caching/hybrid?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/performance/caching/memory?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/performance/caching/distributed?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/performance/timeouts?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/performance/response-compression?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/test/integration-tests?view=aspnetcore-10.0 · https://dotnet.testcontainers.org/
- https://dotnet.testcontainers.org/modules/postgres/ · https://github.com/dotnet/aspnet-api-versioning

**HttpClient e resiliência**
- https://learn.microsoft.com/en-us/dotnet/core/extensions/httpclient-factory · https://learn.microsoft.com/en-us/dotnet/fundamentals/networking/http/httpclient-guidelines · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/http-requests?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/dotnet/core/resilience/ · https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience · https://www.pollydocs.org/
- https://viacep.com.br/ws/01001000/json/ (testado)

**EF Core**
- https://learn.microsoft.com/en-us/ef/core/ · https://learn.microsoft.com/en-us/ef/core/get-started/overview/first-app · https://learn.microsoft.com/en-us/ef/core/dbcontext-configuration/
- https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/ · https://learn.microsoft.com/en-us/ef/core/managing-schemas/migrations/applying · https://learn.microsoft.com/en-us/ef/core/cli/dotnet
- https://learn.microsoft.com/en-us/ef/core/modeling/relationships · https://learn.microsoft.com/en-us/ef/core/modeling/relationships/one-to-many · https://learn.microsoft.com/en-us/ef/core/modeling/relationships/many-to-many
- https://learn.microsoft.com/en-us/ef/core/querying/tracking · https://learn.microsoft.com/en-us/ef/core/querying/related-data/ · https://learn.microsoft.com/en-us/ef/core/querying/related-data/eager
- https://learn.microsoft.com/en-us/ef/core/querying/related-data/lazy · https://learn.microsoft.com/en-us/ef/core/querying/related-data/explicit · https://learn.microsoft.com/en-us/ef/core/querying/single-split-queries
- https://learn.microsoft.com/en-us/ef/core/querying/pagination · https://learn.microsoft.com/en-us/ef/core/querying/client-eval · https://learn.microsoft.com/en-us/ef/core/querying/how-query-works
- https://learn.microsoft.com/en-us/ef/core/performance/efficient-querying · https://learn.microsoft.com/en-us/ef/core/performance/efficient-updating · https://learn.microsoft.com/en-us/ef/core/performance/advanced-performance-topics
- https://learn.microsoft.com/en-us/ef/core/saving/basic · https://learn.microsoft.com/en-us/ef/core/saving/concurrency · https://learn.microsoft.com/en-us/ef/core/saving/execute-insert-update-delete
- https://learn.microsoft.com/en-us/ef/core/saving/transactions · https://learn.microsoft.com/en-us/ef/core/saving/disconnected-entities · https://learn.microsoft.com/en-us/ef/core/querying/sql-queries
- https://learn.microsoft.com/en-us/ef/core/querying/filters · https://learn.microsoft.com/en-us/ef/core/logging-events-diagnostics/interceptors · https://learn.microsoft.com/en-us/ef/core/logging-events-diagnostics/simple-logging
- https://learn.microsoft.com/en-us/ef/core/modeling/indexes · https://learn.microsoft.com/en-us/ef/core/modeling/complex-types · https://learn.microsoft.com/en-us/ef/core/modeling/owned-entities
- https://learn.microsoft.com/en-us/ef/core/modeling/data-seeding · https://learn.microsoft.com/en-us/ef/core/providers/ · https://learn.microsoft.com/en-us/ef/core/testing/
- https://learn.microsoft.com/en-us/ef/core/testing/testing-with-the-database · https://learn.microsoft.com/en-us/ef/core/miscellaneous/connection-resiliency · https://github.com/DapperLib/Dapper

**Tempo real, gRPC e cloud-native**
- https://learn.microsoft.com/en-us/aspnet/core/signalr/introduction?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/signalr/hubs?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/signalr/groups?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/signalr/hubcontext?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/signalr/dotnet-client?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/signalr/javascript-client?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/signalr/scale?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/signalr/authn-and-authz?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/websockets?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/grpc/?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/grpc/aspnetcore?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/tutorials/grpc/grpc-start?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/grpc/services?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/grpc/client?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/grpc/deadlines-cancellation?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/grpc/comparison?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/grpc/json-transcoding?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/grpc/grpcweb?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/aspnet/core/grpc/clientfactory?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/grpc/performance?view=aspnetcore-10.0 · https://aspire.dev/get-started/what-is-aspire/
- https://aspire.dev/get-started/app-host/ · https://aspire.dev/get-started/csharp-service-defaults/ · https://aspire.dev/get-started/first-app/
- https://aspire.dev/whats-new/aspire-13/ · https://aspire.dev/integrations/databases/postgres/postgres-get-started/ · https://aspire.dev/integrations/databases/efcore/migrations/
- https://aspire.dev/fundamentals/service-discovery/ · https://aspire.dev/dashboard/ · https://learn.microsoft.com/en-us/dotnet/core/diagnostics/observability-with-otel
- https://learn.microsoft.com/en-us/dotnet/core/containers/sdk-publish · https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/proxy-load-balancer?view=aspnetcore-10.0 · https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/yarp/yarp-overview?view=aspnetcore-10.0
- https://learn.microsoft.com/en-us/dotnet/architecture/microservices/ · https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/ · https://github.com/dotnet/eShop

**Ecossistema e licenças**
- https://masstransit.io/ · https://masstransit.io/introduction/v9-announcement · https://www.hangfire.io/
- https://serilog.net/ · https://www.jimmybogard.com/automapper-and-mediatr-commercial-editions-launch-today/ · https://www.infoq.com/news/2025/01/fluent-assertions-v8-license/
