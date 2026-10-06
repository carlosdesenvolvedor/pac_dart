# Dossiê de pesquisa — frente `arquitetura` (PAC·C#)

Arquitetura e design em C# para o nível sênior: princípios, SOLID, DI, padrões GoF, Clean/Hexagonal/Vertical Slice/monolito modular, DDD tático, CQRS/Mediator/Result, mensageria (outbox, inbox, saga, idempotência), resiliência e testes de arquitetura.

- **Pesquisado em:** 27/09/2026. **Base do curso:** .NET 10 LTS + C# 14 (EF Core 10 é LTS até 10/11/2028). C# 15 (union types, `closed`) ainda é *preview* do .NET 11, com GA prevista para nov/2026.
- **Código validado:** todo exemplo da seção 2 foi **compilado e executado** no .NET SDK 9.0.112 (C# 13, compatível com .NET 10), com EF Core 9.0.20 + SQLite, NetArchTest 1.3.2 e Microsoft.Extensions.Http.Resilience 9.10. As saídas nos comentários são as reais, rodadas com `InvariantGlobalization`. O `field` (C# 14) foi testado com `LangVersion preview`. O laboratório está em `scratchpad/csharp/pesquisa/lab-arquitetura/` (LabConsole, LabWeb, LabJogo, LabField; saídas em `saida-console.txt`).

## 0. Resumo executivo e decisões para os geradores

1. **Licenças mudaram (2025–2026).** O MediatR ≥ 13 e o AutoMapper ≥ 15 são comerciais desde 02/07/2025. A edição Community é grátis para quem fatura menos de US$ 5 mi, para ONGs e para uso educacional. O MassTransit v9 é comercial desde o 1º tri/2026, e o v8 continua Apache 2.0, com patches até o fim de 2026. O template do Ardalis (v11) **removeu o MediatR** e passou a usar o `Mediator` (source generator, MIT). **Decisão:** o curso ensina os *padrões* com código próprio (um mediador caseiro de cerca de 25 linhas, decorators como "behaviors" e mapeamento manual) e cita as bibliotecas só como contexto de mercado.
2. **EF Core 10:** a recomendação oficial para value objects passou a ser **complex types** (`ComplexProperty`, que também pode ir para JSON e aceita tipos opcionais e structs). Eles substituem os owned types, que o e-book de microsserviços da Microsoft ainda usa (`OwnsOne`). **Pegadinha testada:** propriedade *get-only* pura não é mapeada no complex type (o erro é "No suitable constructor was found"). A solução é usar `{ get; private init; }`.
3. **Fowler e Microsoft alertam:** CQRS "adds risky complexity" para a maioria dos sistemas, e event sourcing é "complex pattern… costly to migrate". Ensine a versão **simplificada** (um banco, dois modelos) e deixe separação de bancos e ES como tópico sênior, com o foco em quando **não** usar.
4. **DDD só onde há complexidade de negócio.** Em CRUD, o modelo anêmico é aceitável (e-book da Microsoft). Ensine a decidir.
5. **Repositório não é obrigatório.** O próprio `DbContext` já é Repository + Unit of Work. O repositório por agregado vale para o lado de escrita, e as queries podem ir direto (projeção/Dapper).
6. **Formato dos exercícios, calibrado pelo `curriculo.json` do PAC·DART** (2.354 trechos): as linhas têm p50 de 26 caracteres, p90 de 54 e p99 de 76, e cada trecho tem p50 de 1 linha e p90 de 4. **Meta:** linhas com até 60 caracteres (máximo 72), 1 a 3 linhas por trecho e, no máximo, 8 em trechos de "montagem". Os campos são `cod` / `dica` / `out`.
7. **Convenção de nomes sugerida (PT-BR):** conceitos do domínio em português **sem acento** nos identificadores (`Pedido`, `Dinheiro`, `Preco`, `Endereco`) e sufixos de padrão em inglês, como o mercado BR usa (`IPedidoRepository`, `CriarPedidoHandler`, `PedidoConfirmado` como evento, `...Specification`). Siga a convenção .NET: PascalCase em tipos e membros, `_camelCase` em campos privados, `I` para interfaces, parâmetros de primary constructor em camelCase (classe) e em PascalCase (record).
8. **Saídas determinísticas nos desafios de "prever a saída":** evite `decimal` com casas decimais (em pt-BR, `100m*0.8m` imprime `80,0`; no modo invariante, `80.0`). Evite também `:C`/`:F` (dependem da cultura), `Guid`, `DateTime.Now`, a ordem de `HashSet`/`Dictionary` e `double`. Prefira `int`, `bool` e strings.
9. **Proposta de trilhas desta frente:** A0 (mini-lições espalhadas no iniciante) + **A1–A9, 9 trilhas × 12 lições**. Na versão enxuta são 7 trilhas: A1 vira lições dentro de A2/A3, e A8+A9 se fundem em "CQRS e sistemas distribuídos". Temas de jogo aparecem em A4/A5 (State, Command, Flyweight, Observer, Object Pool — ver *Game Programming Patterns*).

## 1. Árvore de tópicos em ordem didática

Níveis: **[I]** iniciante · **[M]** intermediário · **[A]** avançado · **[S]** sênior. Pré-requisitos vindos de outras frentes: classes e interfaces, herança e polimorfismo, genéricos, delegates/lambdas, LINQ, records, exceções, async/await, coleções e pattern matching.

### A0 — Boas práticas espalhadas no iniciante (6 mini-lições)
1. **Nomes que revelam intenção** [I]: PascalCase/camelCase, `I` em interfaces, `_campo`, sem abreviações. https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/identifier-names
2. **Métodos pequenos, um propósito** [I]: "um motivo para mudar" em escala de método. https://deviq.com/principles/single-responsibility-principle/
3. **Guard clauses e retorno antecipado** [I]: `ArgumentNullException.ThrowIfNull`, `ThrowIfNegative` etc. https://learn.microsoft.com/en-us/dotnet/standard/exceptions/best-practices-for-exceptions
4. **Constantes/enums no lugar de números mágicos** [I]: enum para conjunto fechado e simples. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/enumeration-classes-over-enum-types
5. **Imutabilidade básica** [I]: `readonly`, `const`, `init` e `record`, incluindo o `with` como cópia **rasa**. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/record
6. **DRY com juízo** [I]: "duplicação é preferível a acoplar na abstração errada". https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles

### A1 — Princípios de design [M]
1. **Separação de responsabilidades (SoC)**: negócio × UI × infraestrutura. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles
2. **Encapsulamento**: estado privado mudado só por métodos com intenção, e o estado global mutável como antítese. (mesma URL)
3. **Acoplamento e coesão**: "new is glue" e *static cling* (estático com efeito colateral acopla). https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/develop-asp-net-core-mvc-apps
4. **Dependências explícitas**: o construtor "honesto" pede tudo de que precisa. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles
5. **Composição > herança**: estender injetando estratégias em vez de subclasses. https://deviq.com/principles/open-closed-principle/
6. **Tell, don't ask; rico × anêmico**: comportamento junto dos dados, e quando o anêmico é aceitável (CRUD). https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-domain-model
7. **CQS (Meyer)**: um método **ou** consulta **ou** altera, e é a base do CQRS. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/apply-simplified-microservice-cqrs-ddd-patterns
8. **Fail fast e objetos sempre válidos**: invariantes no construtor e nos métodos, sem mudança parcial de estado. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-model-layer-validations
9. **Exceções: quando lançar**: padrão `Try*`, `throw;` × `throw ex;`, tipos predefinidos e throw helpers. https://learn.microsoft.com/en-us/dotnet/standard/exceptions/best-practices-for-exceptions
10. **Value semantics com records**: igualdade por valor e cópia rasa no `with`. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/record
11. **Persistence ignorance (POCO)**: sem base obrigatória, sem Active Record, sem atributos de ORM. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles
12. **YAGNI e abstração prematura**: "Pain Driven Development". https://deviq.com/principles/solid

### A2 — SOLID em C# [M]
1. **SRP**: um motivo para mudar. Responsabilidades típicas: persistência, validação, notificação, log, formatação, parsing e mapeamento. https://deviq.com/principles/single-responsibility-principle/
2. **SRP na prática**: separar cálculo, formatação e armazenamento. Um construtor com muitos parâmetros é o *smell*. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-web-api-design
3. **OCP**: aberto para extensão, fechado para modificação, via parâmetro, herança, composição ou strategy. https://deviq.com/principles/open-closed-principle/
4. **OCP + DI**: `IEnumerable<IFrete>` e um dicionário por nome, em que um novo frete vira uma nova classe. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview
5. **LSP**: o subtipo precisa ser substituível ("IS-SUBSTITUTABLE-FOR" e não só "IS-A"). https://deviq.com/principles/liskov-substitution-principle/
6. **LSP na prática**: Retângulo/Quadrado, `NotImplementedException`, `if (x is Tipo)` no laço e o `IList<T>` de um array (`Add` lança). (mesma URL)
7. **ISP**: interfaces pequenas, "pertencem ao cliente". https://deviq.com/principles/interface-segregation/
8. **ISP na prática**: quebrar `IMembership` em `ILogin`/`IRegister`/`IForgotPassword` e recompor por herança de interface. (mesma URL)
9. **DIP**: alto e baixo nível dependem de abstrações, e a abstração fica no lado de quem usa. https://deviq.com/principles/dependency-inversion-principle/
10. **DIP × DI × IoC**: princípio (o quê) × técnica (como), com o grafo invertido em tempo de compilação. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/architectural-principles
11. **Refatorando uma "God class"** com SOLID, passo a passo (testes antes). https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-web-api-design
12. **Armadilhas do SOLID**: interface com uma implementação só "por padrão", classes minúsculas demais e abstração especulativa. https://deviq.com/principles/solid

### A3 — Injeção de dependência e composição [M→A]
1. **DI manual e composition root**: `Program.cs` liga interfaces a implementações. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures
2. **Container da Microsoft**: `ServiceCollection`, `AddX`, `GetRequiredService`, injeção por construtor. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview
3. **Tempos de vida**: transient/scoped/singleton, e o `DbContext` é **scoped** (nunca singleton nem transient). https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-implementation-entity-framework-core
4. **Escopos fora do HTTP**: `IServiceScopeFactory` em `BackgroundService`. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview
5. **Captive dependency e validação de escopos**: singleton segurando scoped, e `ValidateScopes`/`ValidateOnBuild`. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection-guidelines
6. **Várias implementações**: `GetServices<T>()` na ordem de registro, `GetService<T>()` retorna a **última** e `TryAdd*` não sobrescreve. https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection/overview
7. **Keyed services (.NET 8+)**: `AddKeyedSingleton`, `[FromKeyedServices]`, `KeyedService.AnyKey`. (mesma URL)
8. **Decorator via DI**: registro por fábrica, ou o `Decorate` do Scrutor, para scanning e decoração. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-implementation-web-api
9. **Primary constructors para DI** (C# 12): o parâmetro não é campo `readonly`, pode ser reatribuído e pode duplicar numa hierarquia. https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/tutorials/primary-constructors
10. **Antipadrões**: service locator, `BuildServiceProvider` no registro, acesso estático, fábrica `async` com `.Result` (deadlock). https://learn.microsoft.com/en-us/dotnet/core/extensions/dependency-injection-guidelines
11. **Disposal**: o container descarta o que ele criou. Transient `IDisposable` resolvido da raiz vaza, e instância registrada pronta não é descartada. (mesma URL)
12. **Testabilidade**: fakes à mão × mocks e testes de unidade sem infraestrutura. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/test-asp-net-core-mvc-apps

### A4 — Padrões GoF I: criacionais e estruturais [A]
1. **Por que padrões**: vocabulário comum, com 22 padrões em 3 famílias. https://refactoring.guru/design-patterns/catalog
2. **Factory Method** e a "simple factory" com `switch` expression. https://refactoring.guru/design-patterns/csharp
3. **Abstract Factory**: famílias coerentes (tema claro/escuro, inimigos por fase). (mesma URL)
4. **Builder fluente** × object initializer + `required`, e quando cada um vale. (mesma URL)
5. **Prototype com `record` + `with`**: a pegadinha da cópia rasa. https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/record
6. **Singleton**: `Lazy<T>` thread-safe × `AddSingleton`. O Singleton global é tido como antipadrão, e o uso está em declínio. https://refactoring.guru/design-patterns/singleton/csharp/example
7. **Adapter**: SDK legado que vira a nossa interface (porta). https://refactoring.guru/design-patterns/csharp
8. **Decorator**: cache, log e retry em volta de um serviço (e streams da BCL). A ordem importa. https://refactoring.guru/design-patterns/decorator/csharp/example
9. **Proxy**: carregamento lazy, cache e controle de acesso, e a diferença para o decorator (a intenção). https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/work-with-data-in-asp-net-core-apps
10. **Composite**: árvore com a mesma interface (combo, inventário com bolsas, pastas). https://refactoring.guru/design-patterns/csharp
11. **Facade**: um ponto de entrada simples para subsistemas (checkout). (mesma URL)
12. **Bridge e Flyweight**: forma × renderizador, e estado intrínseco compartilhado (tiles, árvores, partículas). https://gameprogrammingpatterns.com/contents.html

### A5 — Padrões GoF II: comportamentais [A]
1. **Strategy**: interface ou `Func<>`, e dicionário de estratégias (fretes, descontos, IA de inimigo). https://refactoring.guru/design-patterns/strategy/csharp/example
2. **Template Method**: esqueleto na base com passos abstratos ou hooks. Nunca chame virtual no construtor. https://refactoring.guru/design-patterns/csharp
3. **Observer com `event`**: `EventHandler<T>`, `?.Invoke`, desinscrever com `-=`. https://learn.microsoft.com/en-us/dotnet/standard/events/observer-design-pattern
4. **`IObservable<T>`/`IObserver<T>`** e alternativas: `Channels`, `IAsyncEnumerable`, Rx. (mesma URL)
5. **Command**: requisição como objeto, com fila, histórico, desfazer/refazer e replay de input em jogos. https://refactoring.guru/design-patterns/csharp
6. **Chain of Responsibility**: aprovações, pipeline/middleware e cadeia de dano (escudo → armadura → vida). https://refactoring.guru/design-patterns/chain-of-responsibility/csharp/example
7. **State**: enum + `switch` em tupla × uma classe por estado (herói no chão/no ar). https://refactoring.guru/design-patterns/csharp
8. **Mediator (GoF)**: os componentes só conversam com o mediador (chat, UI, torre de controle). (mesma URL)
9. **Iterator com `yield`**: execução adiada, validação adiada e múltipla enumeração. (mesma URL)
10. **Memento**: snapshot imutável (record) para desfazer ou checkpoint. (mesma URL)
11. **Visitor × pattern matching**: `switch` em hierarquia de records. No C# 15 (preview), `closed`/`union` permitem switch exaustivo. https://learn.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-15
12. **Specification**: regras nomeadas e combináveis (`E`/`Ou`/`Nao`) como `Expression<Func<T,bool>>`. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-implementation-entity-framework-core

### A6 — Arquitetura de aplicações [A→S]
1. **Monolito all-in-one**: pastas por tipo (Models/Views/Controllers) e onde ele começa a doer. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures
2. **N-camadas (UI→BLL→DAL)**: a regra de negócio acaba dependendo do banco (camada ≠ tier). (mesma URL)
3. **Clean Architecture**: Application Core no centro e Infra e UI dependendo dele. Tem os mesmos princípios do Onion. (mesma URL)
4. **O que vai em cada projeto** (Core, UseCases/Application, Infrastructure, Web) e onde validar. https://github.com/ardalis/CleanArchitecture
5. **Hexagonal / Ports & Adapters**: atores primários (dirigem) e secundários (dirigidos), para testar sem UI e sem banco. https://alistair.cockburn.us/hexagonal-architecture/
6. **Composition root** e a referência Web→Infra "só no Program.cs". https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/common-web-application-architectures
7. **Vertical Slice**: "minimize o acoplamento entre fatias, maximize dentro da fatia", começando com transaction script e refatorando. https://www.jimmybogard.com/vertical-slice-architecture/
8. **REPR e endpoints por arquivo**: Minimal APIs com `TypedResults` e FastEndpoints/ApiEndpoints. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/develop-asp-net-core-mvc-apps
9. **Monolito modular**: cada módulo tem dados próprios (schema), contrato público e integração **assíncrona** por eventos e outbox/inbox. https://github.com/kgrzybek/modular-monolith-with-ddd
10. **Testes de arquitetura**: NetArchTest (e eNhancedEdition), ArchUnitNET e o analisador NsDepCop. https://github.com/BenMorris/NetArchTest
11. **Templates de mercado**: `ca-sln` (Jason Taylor, .NET 10 + Aspire), `clean-arch`/`min-clean` (Ardalis). Quando **não** usar. https://github.com/jasontaylordev/CleanArchitecture
12. **Documentar decisões**: ADR (log append-only com status) e diagramas C4 (contexto, container, componente, código). https://learn.microsoft.com/en-us/azure/well-architected/architect-role/architecture-decision-record

### A7 — DDD tático em C# [S]
1. **Quando usar DDD** e quando não (CRUD e relatórios), mais a abordagem híbrida. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/develop-asp-net-core-mvc-apps
2. **Estratégico em 1 lição**: linguagem ubíqua, bounded context, subdomínios core/supporting/generic e context map (ACL, open host). https://learn.microsoft.com/en-us/azure/architecture/microservices/model/domain-analysis
3. **Entidade**: identidade que persiste, igualdade por Id e comportamento dentro. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/seedwork-domain-model-base-classes-interfaces
4. **IDs fortemente tipados** (`readonly record struct PedidoId(Guid Valor)`) e a estratégia de identidade (natural × surrogate). https://learn.microsoft.com/en-us/azure/architecture/microservices/model/tactical-domain-driven-design
5. **Value object**: sem identidade, imutável, igual por valor (`Dinheiro`, `Endereco`) e "padrão default" de modelagem. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/implement-value-objects
6. **Sempre válido**: validar no construtor/fábrica e nos métodos, com exceção para invariante violada. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-model-layer-validations
7. **Agregado e raiz**: fronteira de consistência, sem setters públicos, coleções expostas só leitura (`AsReadOnly`). https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/net-core-microservice-domain-model
8. **Regras de agregado**: pequeno, referência a outro agregado **por Id**, uma transação por agregado e consistência eventual entre eles. https://martinfowler.com/bliki/DDD_Aggregate.html
9. **Eventos de domínio**: nome no passado, imutáveis, registrados no agregado e despachados antes ou depois do `SaveChanges`. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/domain-events-design-implementation
10. **Domain service × application service**: regra entre agregados × orquestração sem regra. https://learn.microsoft.com/en-us/azure/architecture/microservices/model/tactical-domain-driven-design
11. **Repositório por agregado + Unit of Work**: interface no domínio, implementação na infra, e o `DbContext` já é UoW. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/infrastructure-persistence-layer-design
12. **Persistindo modelo rico no EF Core**: backing fields, `HasConversion` para IDs, `ComplexProperty` (EF 10 > owned) e smart enums. https://learn.microsoft.com/en-us/ef/core/what-is-new/ef-core-10.0/whatsnew

### A8 — Casos de uso: CQRS, Mediator, Result [S]
1. **De CQS a CQRS**: dois modelos, e não necessariamente dois bancos. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/apply-simplified-microservice-cqrs-ddd-patterns
2. **Comandos**: imperativos (`CriarPedido`), imutáveis, processados **uma vez** e podem ser recusados. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-implementation-web-api
3. **Command handler**: validar → obter ou criar o agregado → chamar o método → persistir. Regra dentro do handler é *smell*. (mesma URL)
4. **Queries**: DTO/projeção direto do banco, sem agregado, com `AsNoTracking`/Dapper. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/cqrs-microservice-reads
5. **Mediator in-process**: por que usar (controller enxuto, pipeline), o custo (indireção) e o mediador caseiro. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/develop-asp-net-core-mvc-apps
6. **Pipeline behaviors** (decorator/chain) para log, validação, transação e cache. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-implementation-web-api
7. **Validação em 2 níveis**: entrada (FluentValidation/DataAnnotations no DTO) × invariantes (domínio). Duplicar por defesa é ok. https://github.com/ardalis/CleanArchitecture
8. **Result pattern**: erro como valor (`Resultado<T>`, `Match`/`Map`/`Bind`) e conversões implícitas. https://andrewlock.net/working-with-the-result-pattern-part-1-replacing-exceptions-as-control-flow/
9. **Exceção × Result**: fluxo esperado → Result; falha inesperada → exceção. Não espalhe Result por tudo. https://andrewlock.net/working-with-the-result-pattern-part-4-is-the-result-pattern-worth-it/
10. **Result → HTTP**: `TypedResults`, `ValidationProblem`/ProblemDetails e um mapa de códigos de erro para status. https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/develop-asp-net-core-mvc-apps
11. **Comandos idempotentes**: `IdentifiedCommand` com Id de requisição e o header `Idempotency-Key`. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/microservice-application-layer-implementation-web-api
12. **CQRS completo e event sourcing**: bancos separados, projeções, snapshots, versionamento de eventos e **quando não usar**. https://martinfowler.com/bliki/CQRS.html · https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing

### A9 — Sistemas distribuídos e mensageria [S]
1. **Monolito (modular) × microsserviços**: custos e fronteiras. Um serviço é ≥ um agregado e ≤ um bounded context. https://learn.microsoft.com/en-us/azure/architecture/microservices/model/tactical-domain-driven-design
2. **Síncrono × assíncrono**: fila (um receptor) × tópico (pub/sub) e "evite misturar HTTP em cadeia". https://learn.microsoft.com/en-us/dotnet/architecture/microservices/architect-microservice-container-applications/asynchronous-message-based-communication
3. **Evento de domínio × evento de integração**. O de integração só sai após o commit, e contratos **não** ficam numa lib compartilhada. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/multi-container-microservice-net-applications/integration-event-based-microservice-communications
4. **Consistência eventual e CAP**: escolher disponibilidade e tolerância, e deixar isso explícito ao usuário. https://learn.microsoft.com/en-us/dotnet/architecture/microservices/multi-container-microservice-net-applications/subscribe-events
5. **Dual write → Transactional Outbox**: entidade e evento na mesma transação. https://learn.microsoft.com/en-us/azure/architecture/databases/guide/transactional-out-box-cosmos
6. **Relay do outbox**: polling publisher × log tailing. A entrega é *at-least-once* e a ordem deve ser preservada. https://microservices.io/patterns/data/transactional-outbox.html
7. **Consumidor idempotente / Inbox**: chave estável (MessageId), marcador e efeito atômicos, constraint única e TTL. https://learn.microsoft.com/en-us/azure/architecture/patterns/idempotent-consumer
8. **Sagas**: orquestração × coreografia, e transações compensáveis, pivô e retentáveis. https://learn.microsoft.com/en-us/azure/architecture/patterns/saga
9. **Compensação e anomalias**: lost update, dirty read, semantic lock e compensação idempotente. https://learn.microsoft.com/en-us/azure/architecture/patterns/compensating-transaction
10. **Resiliência HTTP**: `AddStandardResilienceHandler` (rate limit, timeouts, retry exponencial com jitter, circuit breaker). Não repetir POST. https://learn.microsoft.com/en-us/dotnet/core/resilience/http-resilience
11. **Legado**: Anti-Corruption Layer (tradução sem regra de negócio) e Strangler Fig (fachada e migração incremental). https://learn.microsoft.com/en-us/azure/architecture/patterns/strangler-fig
12. **Ecossistema 2026**: brokers (RabbitMQ, Azure Service Bus), frameworks (NServiceBus, MassTransit v9 comercial, Brighter, Rebus) e licenças. https://www.jimmybogard.com/automapper-and-mediatr-commercial-editions-launch-today/

## 2. Código de referência (compilado e executado)

Os blocos juntam declarações e chamadas para caber na página. No laboratório, cada parte está no lugar certo: arquivos separados e top-level statements antes dos tipos. Os comentários `// ->` mostram a saída real.

### 2.1 SOLID — OCP com estratégias e as duas faces do LSP
```csharp
public interface IFrete { string Nome { get; } decimal Calcular(decimal peso); }
public sealed class FretePac : IFrete
{
    public string Nome => "pac";
    public decimal Calcular(decimal peso) => 10m + peso;
}
public sealed class CalculadoraFrete(IEnumerable<IFrete> fretes)
{
    private readonly Dictionary<string, IFrete> _porNome = fretes.ToDictionary(f => f.Nome);
    public decimal Calcular(string tipo, decimal peso) =>
        _porNome.TryGetValue(tipo, out var f) ? f.Calcular(peso)
            : throw new ArgumentException($"Frete desconhecido: {tipo}");
}
// novo frete = nova classe; CalculadoraFrete não muda (OCP)

public class Retangulo
{
    public virtual int Largura { get; set; }
    public virtual int Altura { get; set; }
    public int Area => Largura * Altura;
}
public class Quadrado : Retangulo   // viola LSP
{
    public override int Largura { get => base.Largura; set { base.Largura = value; base.Altura = value; } }
    public override int Altura { get => base.Altura; set { base.Largura = value; base.Altura = value; } }
}
static int AreaEsperada(Retangulo r) { r.Largura = 4; r.Altura = 3; return r.Area; }
// AreaEsperada(new Retangulo()) -> 12 ; AreaEsperada(new Quadrado()) -> 9

IList<int> lista = new int[3];
lista.Add(1); // NotSupportedException: Collection was of a fixed size.  (LSP na própria BCL)
```

### 2.2 DI — tempos de vida, captive dependency, keyed, "última vence", decorator
```csharp
services.AddTransient<Relogio>(); services.AddScoped<Carrinho>(); services.AddSingleton<Config>();
using var sp = services.BuildServiceProvider(validateScopes: true);
// mesmo escopo: Relogio == Relogio? False | Carrinho == Carrinho? True
// escopos diferentes: Carrinho? False | Config? True
sp.GetRequiredService<Carrinho>(); // "Cannot resolve scoped service 'Lab.Di.Carrinho' from root provider."

ruins.AddScoped<Repo>(); ruins.AddSingleton<CacheGlobal>(); // CacheGlobal(Repo repo)
ruins.BuildServiceProvider(new ServiceProviderOptions { ValidateScopes = true, ValidateOnBuild = true });
// AggregateException -> "...Cannot consume scoped service 'Lab.Di.Repo' from singleton 'Lab.Di.CacheGlobal'."
// SEM validação: o Repo "scoped" vira eterno (mesma instância em todos os escopos)

fretes.AddSingleton<IFrete, FreteSedex>();
fretes.AddSingleton<IFrete, FretePac>();
fretes.TryAddSingleton<IFrete, FreteSedex>();        // ignorado: já existe IFrete
sp.GetRequiredService<IFrete>().Nome;                // "pac"  (a última vence)
sp.GetServices<IFrete>().Select(f => f.Nome);        // sedex, pac (ordem de registro)

chaves.AddKeyedSingleton<IFrete, FreteSedex>("sedex");
public sealed class Checkout([FromKeyedServices("sedex")] IFrete frete) { }

deco.AddSingleton<RepositorioProdutos>();
deco.AddSingleton<IRepositorioProdutos>(p =>
    new RepositorioProdutosComCache(p.GetRequiredService<RepositorioProdutos>()));
// Buscar(1), Buscar(1), Buscar(2) -> o repositório real é chamado 2 vezes
```

### 2.3 GoF enxutos (criacionais e estruturais)
```csharp
public static class FreteFactory
{
    public static IFrete Criar(string tipo) => tipo switch
    {
        "sedex" => new FreteSedex(),
        "pac" => new FretePac(),
        _ => throw new ArgumentException($"Frete desconhecido: {tipo}", nameof(tipo))
    };
}

public sealed class PedidoBuilder
{
    private string _cliente = "anonimo";
    private readonly List<string> _itens = [];
    public PedidoBuilder ParaCliente(string c) { _cliente = c; return this; }
    public PedidoBuilder ComItem(string i) { _itens.Add(i); return this; }
    public string Build() => _itens.Count == 0
        ? throw new InvalidOperationException("Pedido sem itens")
        : $"{_cliente}: {string.Join(", ", _itens)}";
}
// new PedidoBuilder().ParaCliente("Ana").ComItem("cafe").ComItem("pao").Build() -> "Ana: cafe, pao"

public sealed record Personagem(string Nome, int Vida, string[] Itens);   // Prototype
var p1 = new Personagem("Orc", 100, ["machado"]);
var p2 = p1 with { Nome = "Orc 2" };
p2.Itens[0] = "clava";   // p1.Itens[0] também vira "clava" (cópia RASA); p1 == p2 -> False

public sealed class Configuracao                                     // Singleton (prefira AddSingleton)
{
    private static readonly Lazy<Configuracao> _instancia = new(() => new Configuracao());
    public static Configuracao Instancia => _instancia.Value;       // Lazy<T> é thread-safe por padrão
    private Configuracao() { }
}

public sealed class GatewayAdapter(GatewayLegado legado) : IPagamentos          // Adapter
{
    public bool Pagar(string cpf, decimal valor) => legado.Cobrar(cpf, (double)valor) == 200;
}

public interface IMensageiro { string Enviar(string msg); }                      // Decorator
public sealed class Mensageiro : IMensageiro { public string Enviar(string msg) => msg; }
public sealed class Maiusculas(IMensageiro inner) : IMensageiro
{ public string Enviar(string msg) => inner.Enviar(msg.ToUpperInvariant()); }
public sealed class ComPrefixo(IMensageiro inner) : IMensageiro
{ public string Enviar(string msg) => inner.Enviar("[log] " + msg); }
new ComPrefixo(new Maiusculas(new Mensageiro())).Enviar("oi");   // "[LOG] OI"
new Maiusculas(new ComPrefixo(new Mensageiro())).Enviar("oi");   // "[log] OI"

public sealed class ImagemProxy(string arquivo) : IImagem                        // Proxy virtual
{
    private ImagemReal? _real;
    public string Exibir() => (_real ??= new ImagemReal(arquivo)).Exibir(); // carrega só 1x
}

public sealed record Produto(string Nome, decimal Valor) : IItemMenu { public decimal Preco() => Valor; }
public sealed class Combo(params IItemMenu[] itens) : IItemMenu                    // Composite
{
    public decimal Preco() => itens.Sum(i => i.Preco()) - 5m;
}
// Combo(burger 20, refri 8, Combo(batata 10, molho 2)).Preco() -> 30

public sealed record TipoArvore(string Especie, string Textura);                 // Flyweight
public readonly record struct Arvore(int X, int Y, TipoArvore Tipo);   // 1000 árvores, 2 tipos
```

### 2.4 GoF enxutos (comportamentais)
```csharp
var descontos = new Dictionary<string, Func<decimal, decimal>>                    // Strategy
{
    ["normal"] = v => v, ["vip"] = v => v * 0.8m, ["funcionario"] = v => v * 0.5m
};

public sealed class Termometro                                                    // Observer
{
    public event EventHandler<decimal>? TemperaturaMudou;
    private decimal _atual;
    public void Medir(decimal valor)
    {
        if (valor == _atual) return;
        _atual = valor;
        TemperaturaMudou?.Invoke(this, valor);
    }
}
// += handler; Medir(20); Medir(20); Medir(25); -= handler; Medir(30) -> handler rodou 2x
// ATENÇÃO: "-= (_, _) => cliques++;" NÃO remove um "+= (_, _) => cliques++;" (delegates diferentes)

public interface IComando { void Executar(); void Desfazer(); }                    // Command
public sealed class Somar(Calculadora calc, int valor) : IComando
{
    public void Executar() => calc.Total += valor;
    public void Desfazer() => calc.Total -= valor;
}
// executa 5, 10, 20 e empilha; historico.Pop().Desfazer(); -> Total = 15

public abstract class Aprovador                                                  // Chain
{
    private Aprovador? _proximo;
    public Aprovador Entao(Aprovador proximo) { _proximo = proximo; return proximo; }
    public string Aprovar(decimal valor) => PodeAprovar(valor)
        ? $"{GetType().Name} aprovou {valor}"
        : _proximo?.Aprovar(valor) ?? "ninguem aprovou";
    protected abstract bool PodeAprovar(decimal valor);
}
// Supervisor(<=1.000) -> Gerente(<=10.000) -> Diretor(<=100.000); Aprovar(5_000m) -> "Gerente aprovou 5000"

// State (enum deste exemplo: Rascunho, Pago, Enviado, Cancelado)
public static StatusPedido Proximo(StatusPedido s, string acao) => (s, acao) switch
{
    (StatusPedido.Rascunho, "pagar") => StatusPedido.Pago,
    (StatusPedido.Pago, "enviar") => StatusPedido.Enviado,
    (StatusPedido.Rascunho or StatusPedido.Pago, "cancelar") => StatusPedido.Cancelado,
    _ => throw new InvalidOperationException($"Nao da para {acao} em {s}")
};

public sealed record EditorMemento(string Texto);                                // Memento
public static double Area(FormaGeo f) => f switch                                // "Visitor" moderno
{
    Circulo c => Math.PI * c.Raio * c.Raio,
    Retang r => r.L * r.A,
    _ => throw new NotSupportedException(f.GetType().Name)
};
```

### 2.5 DDD — entidade, ID tipado, value object, agregado
```csharp
public abstract class Entidade<TId> : ITemEventos where TId : notnull
{
    private readonly List<IEventoDominio> _eventos = [];
    public TId Id { get; protected init; } = default!;
    public IReadOnlyList<IEventoDominio> Eventos => _eventos.AsReadOnly();
    protected void Registrar(IEventoDominio e) => _eventos.Add(e);
    public void LimparEventos() => _eventos.Clear();
    public override bool Equals(object? obj) => obj is Entidade<TId> o
        && o.GetType() == GetType() && EqualityComparer<TId>.Default.Equals(Id, o.Id);
    public override int GetHashCode() => HashCode.Combine(GetType(), Id);
}   // cuidado: Equals sobrescrito, mas "==" continua comparando REFERÊNCIA

public readonly record struct PedidoId(Guid Valor)
{
    public static PedidoId Novo() => new(Guid.NewGuid());   // new PedidoId() => Guid.Empty!
}

public sealed record Dinheiro
{
    public decimal Valor { get; private init; }   // get-only puro NÃO é mapeado pelo EF
    public string Moeda { get; private init; }
    public Dinheiro(decimal valor, string moeda)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(valor);
        ArgumentException.ThrowIfNullOrWhiteSpace(moeda);
        Valor = valor; Moeda = moeda.ToUpperInvariant();
    }
    public static Dinheiro Zero(string moeda) => new(0m, moeda);
    public static Dinheiro Reais(decimal valor) => new(valor, "BRL");
    public Dinheiro Vezes(int qtd) => new(Valor * qtd, Moeda);
    public static Dinheiro operator +(Dinheiro a, Dinheiro b) => a.Moeda == b.Moeda
        ? new(a.Valor + b.Valor, a.Moeda) : throw new InvalidOperationException("Moedas diferentes");
    public override string ToString() => $"{Moeda} {Valor}";
}
// Dinheiro.Reais(10) == new Dinheiro(10, "brl") -> True

public sealed record EmailFragil(string Valor)   // PEGADINHA: o "with" burla a validação
{
    public string Valor { get; init; } = Valor.Contains('@') ? Valor : throw new ArgumentException("e-mail invalido");
}
// new EmailFragil("a@b.com") with { Valor = "sem-arroba" } -> aceita "sem-arroba"!
public sealed record Email   // correto (C# 14): valida no init; "with" também passa por aqui
{
    public Email(string valor) => Valor = valor;
    public string Valor { get; init => field = value.Contains('@') ? value : throw new ArgumentException("e-mail invalido"); } = "";
}

public sealed class Pedido : Entidade<PedidoId>
{
    public const int MaxItens = 10;
    private readonly List<ItemPedido> _itens = [];
    public string Cliente { get; private set; } = "";
    public StatusPedido Status { get; private set; } = StatusPedido.Rascunho;
    public IReadOnlyList<ItemPedido> Itens => _itens.AsReadOnly();   // cast para List falha
    private Pedido() { }                                            // para o EF
    public static Pedido Criar(string cliente)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(cliente);
        return new Pedido { Id = PedidoId.Novo(), Cliente = cliente };
    }
    public void AdicionarItem(string sku, int quantidade, Dinheiro preco)
    {
        if (Status != StatusPedido.Rascunho) throw new InvalidOperationException("Pedido nao esta em rascunho");
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(quantidade);
        var existente = _itens.Find(i => i.Sku == sku);
        if (existente is not null) { existente.Somar(quantidade); return; }
        if (_itens.Count == MaxItens) throw new InvalidOperationException($"Maximo de {MaxItens} itens");
        _itens.Add(new ItemPedido(sku, quantidade, preco));   // construtor internal
    }
    public Dinheiro Total() => _itens.Aggregate(Dinheiro.Zero("BRL"), (s, i) => s + i.Subtotal);
    public void Confirmar(DateTime agora)
    {
        if (Status != StatusPedido.Rascunho) throw new InvalidOperationException("Pedido ja confirmado ou cancelado");
        if (_itens.Count == 0) throw new InvalidOperationException("Pedido vazio");
        Status = StatusPedido.Confirmado;
        Registrar(new PedidoConfirmado(Id, Total().Valor, agora));
    }
}
public sealed record PedidoConfirmado(PedidoId PedidoId, decimal Total, DateTime OcorridoEm) : IEventoDominio;
// cafe 2x10 + pao 3x1 + cafe 1x10 -> "2 itens, total BRL 33"; Confirmar -> 1 evento

public sealed class CarrinhoVazado   // BUG clássico para desafio
{
    private readonly List<string> _itens = [];
    public IReadOnlyList<string> Itens => _itens;   // devolve a própria lista
    public void Adicionar(string sku) { if (_itens.Count < 3) _itens.Add(sku); }
}
// ((List<string>)carrinho.Itens).Add("hack") burla o limite -> Count = 4
```

### 2.6 Specification combinável (funciona em LINQ to Objects e EF)
```csharp
public abstract class Especificacao<T>
{
    public abstract Expression<Func<T, bool>> ParaExpressao();
    public bool EhSatisfeitaPor(T c) => ParaExpressao().Compile()(c);
    public Especificacao<T> E(Especificacao<T> outra) => new EEspecificacao<T>(this, outra);
}
internal sealed class EEspecificacao<T>(Especificacao<T> a, Especificacao<T> b) : Especificacao<T>
{
    public override Expression<Func<T, bool>> ParaExpressao()
    {
        var ea = a.ParaExpressao(); var eb = b.ParaExpressao(); var p = ea.Parameters[0];
        var corpoB = new TrocaParametro(eb.Parameters[0], p).Visit(eb.Body);   // unifica o "p"
        return Expression.Lambda<Func<T, bool>>(Expression.AndAlso(ea.Body, corpoB), p);
    }
}
internal sealed class TrocaParametro(ParameterExpression de, ParameterExpression para) : ExpressionVisitor
{
    protected override Expression VisitParameter(ParameterExpression n) => n == de ? para : base.VisitParameter(n);
}
public sealed class PedidoConfirmadoSpec : Especificacao<Pedido>
{
    public override Expression<Func<Pedido, bool>> ParaExpressao() => p => p.Status == StatusPedido.Confirmado;
}
// pedidos.Count(new PedidoConfirmadoSpec().E(new PedidoDoClienteSpec("Ana")).ParaExpressao())
// Com Ardalis.Specification: class X : Specification<Pedido> { public X() { Query.Where(...).OrderBy(...); } }
```

### 2.7 Aplicação — Result, mediador caseiro, "behavior" e handlers CQRS
```csharp
public sealed record Erro(string Codigo, string Mensagem)
{
    public static Erro NaoEncontrado(string o) => new("nao_encontrado", $"{o} nao encontrado");
    public static Erro Validacao(string m) => new("validacao", m);
}
public sealed class Resultado<T>   // classe (não struct): default(struct) viraria "sucesso" falso
{
    private readonly T? _valor;
    private Resultado(T valor) { _valor = valor; Sucesso = true; }
    private Resultado(Erro erro) { Erro = erro; }
    public bool Sucesso { get; }
    public Erro? Erro { get; }
    public T Valor => Sucesso ? _valor! : throw new InvalidOperationException($"Resultado com falha: {Erro!.Codigo}");
    public static Resultado<T> Ok(T v) => new(v);
    public static Resultado<T> Falha(Erro e) => new(e);
    public static implicit operator Resultado<T>(T v) => Ok(v);
    public static implicit operator Resultado<T>(Erro e) => Falha(e);
    public TOut Match<TOut>(Func<T, TOut> ok, Func<Erro, TOut> falha) => Sucesso ? ok(_valor!) : falha(Erro!);
    public Resultado<TOut> Map<TOut>(Func<T, TOut> f) => Sucesso ? f(_valor!) : Erro!;
    public Resultado<TOut> Bind<TOut>(Func<T, Resultado<TOut>> f) => Sucesso ? f(_valor!) : Erro!;
}
// Validar(15).Bind(Cadastrar) -> "menor de idade" (para no 1º erro)

public interface IRequest<TResposta>;                                   // C# 12: corpo ";"
public interface IHandler<in TRequest, TResposta> where TRequest : IRequest<TResposta>
{
    Task<TResposta> Handle(TRequest request, CancellationToken ct);
}
internal abstract class Invocador<TResposta>
{
    public abstract Task<TResposta> Invocar(object req, IServiceProvider sp, CancellationToken ct);
}
internal sealed class Invocador<TRequest, TResposta> : Invocador<TResposta> where TRequest : IRequest<TResposta>
{
    public override Task<TResposta> Invocar(object req, IServiceProvider sp, CancellationToken ct) =>
        sp.GetRequiredService<IHandler<TRequest, TResposta>>().Handle((TRequest)req, ct);
}
public sealed class Mediador(IServiceProvider sp) : IMediador   // sem "dynamic", tipado
{
    public Task<TResposta> Enviar<TResposta>(IRequest<TResposta> req, CancellationToken ct = default)
    {
        var tipo = typeof(Invocador<,>).MakeGenericType(req.GetType(), typeof(TResposta));
        return ((Invocador<TResposta>)Activator.CreateInstance(tipo)!).Invocar(req, sp, ct);
    }
}
public sealed class LogHandler<TReq, TRes>(IHandler<TReq, TRes> inner, List<string> log)   // "behavior"
    : IHandler<TReq, TRes> where TReq : IRequest<TRes>
{
    public async Task<TRes> Handle(TReq r, CancellationToken ct)
    {
        log.Add($"-> {typeof(TReq).Name}");
        var resposta = await inner.Handle(r, ct);
        log.Add($"<- {typeof(TReq).Name}");
        return resposta;
    }
}

public sealed record CriarPedido(string Cliente, IReadOnlyList<ItemDto> Itens) : IRequest<Resultado<Guid>>;
public sealed class CriarPedidoHandler(IPedidoRepository repo, IUnitOfWork uow) : IHandler<CriarPedido, Resultado<Guid>>
{
    public async Task<Resultado<Guid>> Handle(CriarPedido cmd, CancellationToken ct)
    {
        if (cmd.Itens.Count == 0) return Erro.Validacao("Pedido precisa de itens");
        var pedido = Pedido.Criar(cmd.Cliente);
        foreach (var i in cmd.Itens) pedido.AdicionarItem(i.Sku, i.Quantidade, Dinheiro.Reais(i.Preco));
        repo.Adicionar(pedido);
        await uow.SalvarAsync(ct);
        return pedido.Id.Valor;   // conversão implícita Guid -> Resultado<Guid>
    }
}
public sealed record ObterPedido(Guid Id) : IRequest<Resultado<PedidoResumo>>;
public sealed class ObterPedidoHandler(IConsultasPedido consultas) : IHandler<ObterPedido, Resultado<PedidoResumo>>
{
    public async Task<Resultado<PedidoResumo>> Handle(ObterPedido q, CancellationToken ct) =>
        await consultas.ResumoAsync(q.Id, ct) is { } r ? r : Erro.NaoEncontrado("Pedido");
}
// Mediator (MIT, source generator): ValueTask<TRes> Handle(TReq, CancellationToken); services.AddMediator();
```

### 2.8 EF Core — IDs, complex type, eventos → outbox na MESMA transação, relay e inbox
```csharp
protected override void OnModelCreating(ModelBuilder mb)
{
    mb.Entity<Produto>(b =>
    {
        b.HasKey(p => p.Id);
        b.Property(p => p.Id).HasConversion(id => id.Valor, v => new ProdutoId(v));
        b.ComplexProperty(p => p.Preco);   // value object (EF 8+; EF 10: opcional/JSON/struct)
        b.Ignore(p => p.Eventos);
    });
    mb.Entity<OutboxMensagem>().HasKey(m => m.Id);
    mb.Entity<MensagemProcessada>().HasKey(m => new { m.MensagemId, m.Consumidor });   // inbox
}
public override async Task<int> SaveChangesAsync(CancellationToken ct = default)
{
    var comEventos = ChangeTracker.Entries<ITemEventos>().Select(e => e.Entity)
        .Where(e => e.Eventos.Count > 0).ToList();
    foreach (var ent in comEventos)
    {
        foreach (var ev in ent.Eventos)
            Outbox.Add(new OutboxMensagem { Id = Guid.NewGuid(), Tipo = ev.GetType().Name,
                Conteudo = JsonSerializer.Serialize(ev, ev.GetType()), CriadaEm = ev.OcorridoEm });
        ent.LimparEventos();
    }
    return await base.SaveChangesAsync(ct);   // entidade + outbox: tudo ou nada
}
// Relay (at-least-once): pega pendentes -> publica -> marca -> SaveChanges. 1ª rodada 1 msg, 2ª rodada 0.
public static async Task<bool> ProcessarAsync(LojaDbContext db, Guid msgId, string sku, int qtd)
{
    db.Processadas.Add(new MensagemProcessada { MensagemId = msgId, Consumidor = "estoque", ProcessadaEm = DateTime.UtcNow });
    var estoque = await db.Estoques.SingleAsync(e => e.Sku == sku);
    estoque.Quantidade -= qtd;
    try { await db.SaveChangesAsync(); return true; }
    catch (DbUpdateException) { return false; }   // PK duplicada = já processada
}
// mesma mensagem 2x (um DbContext por mensagem): True, False; estoque 10 -> 7 (baixou 1x só)
// SQLite devolve decimal com escala: BRL 12 volta como "BRL 12.0" (compare valores, não strings)
```

### 2.9 Saga orquestrada com compensação em ordem inversa
```csharp
public sealed record Passo(string Nome, Func<bool> Executar, Action Compensar);
public static bool Rodar(IEnumerable<Passo> passos, List<string> log)
{
    var feitos = new Stack<Passo>();
    foreach (var passo in passos)
    {
        if (passo.Executar()) { log.Add($"ok: {passo.Nome}"); feitos.Push(passo); continue; }
        log.Add($"falhou: {passo.Nome}");
        while (feitos.TryPop(out var feito)) { feito.Compensar(); log.Add($"desfeito: {feito.Nome}"); }
        return false;
    }
    return true;
}
// reservar estoque(ok) -> cobrar cartao(ok) -> agendar entrega(falha) -> [enviar e-mail nunca roda]
// log: ok: reservar estoque | ok: cobrar cartao | falhou: agendar entrega | desfeito: cobrar cartao | desfeito: reservar estoque
```

### 2.10 Web — vertical slice, Result→HTTP, Idempotency-Key, resiliência
```csharp
public static class CriarTarefa   // uma fatia: request + response + validação + handler
{
    public sealed record Requisicao(string Titulo);
    public sealed record Resposta(Guid Id, string Titulo);
    public static void Mapear(IEndpointRouteBuilder app) => app.MapPost("/tarefas", Handle);
    static Results<Created<Resposta>, ValidationProblem> Handle(Requisicao req, BancoTarefas db)
    {
        if (string.IsNullOrWhiteSpace(req.Titulo))
            return TypedResults.ValidationProblem(new Dictionary<string, string[]> { ["titulo"] = ["obrigatorio"] });
        var t = new Tarefa(Guid.NewGuid(), req.Titulo.Trim(), false);
        db.Itens[t.Id] = t;
        return TypedResults.Created($"/tarefas/{t.Id}", new Resposta(t.Id, t.Titulo));
    }
}   // testado: 400 com ProblemDetails {"errors":{"titulo":["obrigatorio"]}}; 201 + Location

public sealed class IdempotenciaStore
{
    private readonly ConcurrentDictionary<string, Lazy<PagamentoResp>> _respostas = new();
    public PagamentoResp ObterOuExecutar(string chave, Func<PagamentoResp> executar) =>
        _respostas.GetOrAdd(chave, _ => new Lazy<PagamentoResp>(executar)).Value;   // 1 execução mesmo em corrida
}   // testado: 2 POSTs com a mesma Idempotency-Key -> mesmo Id

using Microsoft.Extensions.Http.Resilience;   // sem este using, DisableForUnsafeHttpMethods não compila
builder.Services.AddHttpClient<ClienteFrete>(c => c.BaseAddress = new("https://frete.exemplo"))
    .AddStandardResilienceHandler(o => o.Retry.DisableForUnsafeHttpMethods());
// padrão: rate limiter(1000) > total timeout 30s > retry 3x exponencial+jitter > circuit breaker(10%/30s) > attempt timeout 10s
```

### 2.11 Testes de arquitetura e o futuro (C# 15)
```csharp
var r = Types.InAssembly(typeof(Pedido).Assembly)          // NetArchTest.Rules 1.3.2
    .That().ResideInNamespace("Lab.Dominio")
    .ShouldNot().HaveDependencyOn("Microsoft.EntityFrameworkCore")
    .GetResult();
Console.WriteLine(r.IsSuccessful);                          // True (domínio limpo)
// Infra -> EF: IsSuccessful False, FailingTypeNames = LojaDbContext, OutboxRelay, ConsumidorEstoque
Types.InAssembly(asm).That().ImplementInterface(typeof(IEventoDominio)).Should().BeSealed().GetResult();

// ArchUnitNET (README; não compilado aqui): rode em Debug
// Types().That().Are(Dominio).Should().NotDependOnAny(Infra).Because("regra de camadas").Check(Architecture);

// C# 15 PREVIEW (.NET 11, não compilado aqui) — Result como união exaustiva:
public record class Ok(int Valor);
public record class Falhou(string Motivo);
public union Resultado(Ok, Falhou);
string Texto(Resultado r) => r switch { Ok o => $"ok {o.Valor}", Falhou f => f.Motivo };   // sem "_ =>"
```

## 3. Armadilhas e boas práticas que o curso deve ensinar

**Princípios/SOLID**
- Abstração especulativa: uma interface para cada classe "por padrão" não é SOLID. Extraia quando houver dor ou uma segunda implementação (inclui teste). Veja "Pain Driven Development".
- DRY errado: duas constantes iguais com significados diferentes **não** devem virar uma só.
- LSP: `NotImplementedException`/`NotSupportedException`, `if (x is Sub)` em código polimórfico e setters que mudam outra propriedade (o Quadrado). Na BCL, `IList<T>` sobre array lança em `Add`.
- DIP ≠ DI: a interface (porta) mora **no core**. Colocar `IRepositorio` no projeto de infraestrutura mantém a dependência na direção errada.
- *Static cling* e "new is glue": `new` e estáticos com efeito colateral (arquivo, banco, `DateTime.Now`) dificultam o teste. No domínio, use `TimeProvider`/`DateTime` recebido como parâmetro.

**DI**
- Captive dependency (singleton recebendo scoped ou `DbContext`) e scoped resolvido da raiz. Ligue `ValidateScopes` + `ValidateOnBuild` (o Development já valida escopos).
- Service locator (`IServiceProvider` injetado em regra de negócio), `BuildServiceProvider()` durante o registro e fábrica `async` com `.Result` (deadlock).
- Transient `IDisposable` resolvido da raiz vaza memória. Instância registrada pronta (`AddSingleton(new X())`) não é descartada pelo container.
- "A última registrada vence" em `GetService<T>`. Use `TryAdd*` em bibliotecas e `IEnumerable<T>` para várias implementações.
- Primary constructor: o parâmetro é capturado, é **mutável** e não é `readonly`. Numa hierarquia, pode virar **cópia duplicada** (o compilador avisa). Para garantir imutabilidade, atribua a um campo `private readonly`.
- Singleton precisa ser thread-safe. O container é thread-safe para resolver, **não** o seu objeto.

**GoF**
- Singleton estático é estado global (difícil de testar). Prefira `AddSingleton`, e se precisar do padrão, use `Lazy<T>`.
- `record` + `with` faz cópia **rasa**: arrays e listas continuam compartilhados. A propriedade calculada no initializer fica desatualizada após o `with`.
- Decorator: a ordem de composição muda o resultado. Proxy × Decorator é diferença de **intenção** (controlar acesso × adicionar comportamento).
- Observer: esquecer `-=` mantém o assinante vivo (vazamento). Uma lambda "igual" não remove a outra, então guarde o delegate numa variável. Use `?.Invoke`.
- Template Method: chamar um método virtual no construtor da base faz a derivada ver campos inicializados no *initializer*, mas **não** os atribuídos no corpo do construtor (`"campo/null"`).
- Iterator: `yield` adia até a validação de argumentos. Para falhar na hora, valide num método público e delegue a um iterator local. Cuidado com a múltipla enumeração.
- `switch` sobre hierarquia aberta precisa de `_ => throw`. A exaustividade real só vem com C# 15 (`closed`/`union`, preview).

**DDD**
- Modelo anêmico em domínio complexo, setters públicos e `List<T>` pública no agregado.
- Expor `IReadOnlyList<T>` devolvendo a **própria** `List<T>`: um cast recupera o acesso de escrita. Use `AsReadOnly()` ou uma cópia (e `AsReadOnly` cria um wrapper novo a cada acesso).
- Record posicional validado no *initializer*: o `with` **burla** a validação. Valide no `init` (C# 14: `field`) ou use uma classe com construtor privado e fábrica.
- Record com `List`/array compara a coleção **por referência** (`new Tags(["a"]) == new Tags(["a"])` → False).
- IDs em `record struct`: `new PedidoId()` e `default` geram `Guid.Empty` silenciosamente. Crie só por fábrica (`Novo()`) e valide.
- Entidade com `Equals` sobrescrito, mas sem `==`, dá `Equals` True e `==` False. Records não servem como entidades do EF, que usa identidade por referência.
- Agregado grande demais ou com navegação para outro agregado: referencie por Id. Uma transação cobrindo vários agregados pede eventos e consistência eventual.
- Repositório por **tabela** (em vez de por agregado) e repositório retornando `IQueryable` (a query "vaza" e quebra em tempo de execução). O correto é retornar a coleção materializada.
- Lazy loading em apps web: N+1 escondido no dev e lento em produção.
- EF: value object com propriedade get-only pura não é mapeado. Use `private init`/`private set`. Prefira `ComplexProperty` a `OwnsOne` no EF 10.
- Eventos de domínio mutáveis ou carregando a entidade inteira: prefira IDs e valores e nome no passado (`PedidoConfirmado`).

**CQRS/Mediator/Result**
- Lógica de negócio no handler (a regra deve estar no agregado), handler chamando handler e mediator para tudo (indireção sem ganho).
- Queries passando por agregado e repositório: desnecessário, projete direto num DTO.
- CQRS com bancos separados ou event sourcing sem necessidade (Fowler: "risky complexity"). Comando assíncrono "fire and forget" também é armadilha: sempre dê um retorno ou status.
- Result: acessar `.Valor` sem checar (lança), `struct` Result cujo `default` parece sucesso e exceção para fluxo esperado (cara). O oposto também é armadilha: Result em **tudo**, gerando boilerplate.
- Validação: entrada (DTO/endpoint) e invariantes (domínio) são coisas diferentes. Duplicar por defesa é aceitável.

**Distribuídos**
- Dual write: salvar e depois publicar (ou publicar e depois salvar) cria perda de evento ou evento fantasma. Use outbox.
- Relay e broker entregam *at-least-once*, então **todo** consumidor precisa ser idempotente. A deduplicação do broker (janela limitada, do lado do envio) **não substitui** isso.
- A chave de deduplicação precisa ser estável (`MessageId`/idempotency key). Nunca use `CorrelationId`, timestamp ou identificador regenerado na reentrega. O marcador e o efeito vão na **mesma transação**, com constraint única.
- "Checar e depois inserir" em duas etapas tem janela de corrida. Use uma escrita atômica (insert que falha no conflito) e um DbContext ou escopo por mensagem.
- Não apague o registro de deduplicação cedo demais: a retenção precisa ser maior que a janela de reentrega (e considerar a DLQ).
- Prefira mensagens naturalmente idempotentes ("preço = 25" em vez de "some 5").
- Deduplicar não garante a ordem: use sessões/partições ou versão.
- Biblioteca de eventos compartilhada entre serviços acopla tudo. Defina os contratos em cada serviço, sem eventos "magros demais" nem "gordos demais".
- Retry em POST ou pagamento sem idempotency key gera cobrança dupla (`DisableForUnsafeHttpMethods`). Empilhar vários handlers de resiliência também é armadilha: use **um**.
- A compensação pode falhar: registre o progresso, faça passos idempotentes e defina o ponto sem volta (pivô) depois das validações.
- Microsserviços cedo demais custam caro. No começo do MVP as fronteiras não estão claras, então comece com um monolito modular. Banco compartilhado entre serviços quebra a autonomia.
- ACL com regra de negócio dentro: ela deve só **traduzir**.

**Arquitetura, testes e licenças**
- Pastas não impõem camadas. Garanta as regras com projetos separados, `internal` e testes de arquitetura (NetArchTest, ArchUnitNET em Debug) ou com o analisador NsDepCop.
- O NetArchTest original parou na 1.3.2. Considere o fork eNhancedEdition (1.4.5) ou o ArchUnitNET.
- MediatR ≥ 13, AutoMapper ≥ 15 e MassTransit v9 são comerciais. Verifique a licença antes de adotar. Alternativas: um mediador próprio, `Mediator` (MIT), mapeamento manual e Rebus ou os clientes oficiais `Azure.Messaging.ServiceBus`/`RabbitMQ.Client`.

## 4. Ideias de exercícios

### 4.1 Digitação (trechos para `cod`; cada linha com até cerca de 60 caracteres)
**A0/A1 princípios**
- `public const int MaxTentativas = 3;` — nome no lugar de número mágico
- `ArgumentException.ThrowIfNullOrWhiteSpace(nome);` — guard clause (fail fast)
- `ArgumentOutOfRangeException.ThrowIfNegative(valor);`
- `if (itens.Count == 0) return 0m;` — retorno antecipado
- `private readonly List<Item> _itens = [];` — estado privado
- `public IReadOnlyList<Item> Itens => _itens.AsReadOnly();`
- `public int Contar() => _itens.Count;` / `public void Limpar() => _itens.Clear();` — CQS: consulta × comando
- `public sealed record Coordenada(int X, int Y);` + `var c2 = c1 with { X = 5 };`
- `public sealed class Relatorio(TimeProvider tempo)` — dependência explícita
- `catch (IOException) { Log(); throw; }` — `throw;` preserva o stack trace

**A2 SOLID**
- `public interface IFrete { decimal Calcular(decimal peso); }`
- `public sealed class FretePac : IFrete` + `public decimal Calcular(decimal peso) => 10m + peso;`
- `private readonly Dictionary<string, IFrete> _porNome;`
- `public interface IScanner { string Digitalizar(); }`
- `public sealed class Multifuncional : IImpressora, IScanner`
- `public interface IMembership : ILogin, IRegister { }` — ISP recompondo
- `public sealed record Quad(int Lado) : IForma` + `public int Area => Lado * Lado;`
- `public sealed class ServicoCadastro(INotificador notificador)`
- `public void Cadastrar(string e) => notificador.Enviar(e, "Oi!");`
- `var fake = new NotificadorFake();` — trocar a implementação no teste (DIP)

**A3 DI**
- `builder.Services.AddScoped<IPedidoRepository, PedidoRepository>();`
- `builder.Services.AddSingleton<IRelogio, RelogioSistema>();`
- `builder.Services.AddTransient<IEmail, EmailSmtp>();`
- `services.AddKeyedSingleton<IFrete, FreteSedex>("sedex");`
- `public sealed class Checkout([FromKeyedServices("pac")] IFrete frete)`
- `services.TryAddSingleton<IFrete, FretePac>();`
- `using var escopo = sp.CreateScope();`
- `var repo = escopo.ServiceProvider.GetRequiredService<IRepo>();`
- 3 linhas: `services.AddScoped<IRepo>(sp =>` / `    new RepoComCache(` / `        sp.GetRequiredService<Repo>()));` — decorator
- 2 linhas: `public sealed class Worker(IServiceScopeFactory fabrica)` / `    : BackgroundService`

**A4 criacionais/estruturais**
- `"pac" => new FretePac(),` — braço da simple factory
- `_ => throw new ArgumentException($"Frete: {tipo}"),`
- `protected abstract Notificacao Criar();` — o factory method
- `public PedidoBuilder ComItem(string i) { _itens.Add(i); return this; }`
- `var p2 = p1 with { Nome = "Orc 2" };` — prototype (cópia rasa!)
- `private static readonly Lazy<Config> _inst = new(() => new());`
- `public sealed class GatewayAdapter(GatewayLegado legado) : IPagamentos`
- `IMensageiro m = new ComPrefixo(new Maiusculas(new Mensageiro()));`
- `public string Exibir() => (_real ??= new ImagemReal(arq)).Exibir();` — proxy
- `public decimal Preco() => itens.Sum(i => i.Preco());` — composite
- `estoque.Reservar(sku) && cobranca.Cobrar(v) && envio.Agendar(sku)` — facade
- [jogo] `var tipo = FabricaTipos.Obter("pinho");` — flyweight
- [jogo] `IArma arma = new Flamejante(new Dobro(new Espada()));`

**A5 comportamentais**
- `Func<decimal, decimal> blackFriday = v => v * 0.5m;`
- `protected abstract string Separador { get; }` — passo do template method
- `public event EventHandler<decimal>? TemperaturaMudou;`
- `TemperaturaMudou?.Invoke(this, valor);`
- `termo.TemperaturaMudou -= handler;`
- `public interface IComando { void Executar(); void Desfazer(); }`
- `historico.Pop().Desfazer();`
- `cadeia.Entao(new Gerente()).Entao(new Diretor());`
- `(StatusPedido.Pago, "enviar") => StatusPedido.Enviado,`
- [jogo] `public IEstadoHeroi Pular() => new NoAr();`
- `foreach (var n in Numeros()) Console.WriteLine(n);` + `yield return 1;`
- `public EditorMemento Salvar() => new(Texto);`
- `Circulo c => Math.PI * c.Raio * c.Raio,` — pattern matching no lugar do Visitor

**A6 arquitetura**
- `dotnet new install Clean.Architecture.Solution.Template`
- `dotnet new ca-sln --client-framework none --database sqlite -o Loja`
- `dotnet new install Ardalis.CleanArchitecture.Template`
- `dotnet new clean-arch -o Loja` · `dotnet new min-clean -o Loja`
- `dotnet add src/Infra reference src/Core` — a Infra depende do Core
- `public interface IPagamentos { bool Pagar(string cpf, decimal v); }` — porta
- `app.MapPost("/tarefas", Handle);` + `public sealed record Requisicao(string Titulo);`
- `return TypedResults.Created($"/tarefas/{t.Id}", t);`
- 4 linhas NetArchTest: `Types.InAssembly(asm)` / `.That().ResideInNamespace("Loja.Dominio")` / `.ShouldNot().HaveDependencyOn("Loja.Infra")` / `.GetResult().IsSuccessful;`
- `Task<TResult> ExecuteCommandAsync<TResult>(ICommand<TResult> c);` — contrato de módulo

**A7 DDD**
- `public readonly record struct PedidoId(Guid Valor);`
- `public static PedidoId Novo() => new(Guid.NewGuid());`
- `public decimal Valor { get; private init; }`
- `public Dinheiro Vezes(int qtd) => new(Valor * qtd, Moeda);`
- 2 linhas: `if (Status != StatusPedido.Rascunho)` / `    throw new InvalidOperationException("Fechado");`
- `ArgumentOutOfRangeException.ThrowIfNegativeOrZero(quantidade);`
- `private Pedido() { } // EF`
- `Registrar(new PedidoConfirmado(Id, Total().Valor, agora));`
- 2 linhas: `public sealed record PedidoConfirmado(` / `    PedidoId Id, DateTime OcorridoEm) : IEventoDominio;`
- `public interface IPedidoRepository { void Adicionar(Pedido p); }`
- `b.Property(p => p.Id).HasConversion(id => id.Valor, v => new(v));`
- `b.ComplexProperty(p => p.Preco);`
- `public static readonly TipoCartao Credito = new(1, "credito", 0.03m);` — smart enum

**A8 CQRS/Result**
- 2 linhas: `public sealed record CriarPedido(string Cliente)` / `    : IRequest<Resultado<Guid>>;`
- 2 linhas: `public sealed record ObterPedido(Guid Id)` / `    : IRequest<Resultado<PedidoResumo>>;`
- `Task<TResposta> Handle(TRequest request, CancellationToken ct);`
- `if (cmd.Itens.Count == 0) return Erro.Validacao("Sem itens");`
- `return pedido.Id.Valor;` — conversão implícita para `Resultado<Guid>`
- `public static implicit operator Resultado<T>(Erro e) => Falha(e);`
- `var texto = r.Match(v => $"ok {v}", e => e.Mensagem);`
- `var total = await mediador.Enviar(new ObterPedido(id));`
- `RuleFor(c => c.Cliente).NotEmpty().MaximumLength(100);` — FluentValidation
- `db.Pedidos.AsNoTracking().Select(p => new ResumoDto(p.Cliente))` — query projetada (DTO nunca é rastreado)

**A9 distribuídos**
- 2 linhas: `public sealed record PedidoPagoIntegrationEvent(` / `    Guid PedidoId, decimal Total);`
- `Outbox.Add(new OutboxMensagem { Id = Guid.NewGuid(), Tipo = nome });`
- `.Where(m => m.ProcessadaEm == null).OrderBy(m => m.CriadaEm)`
- `m.MarcarProcessada(DateTime.UtcNow);`
- `HasKey(m => new { m.MensagemId, m.Consumidor });`
- `catch (DbUpdateException) { return false; } // duplicada`
- `var msg = new ServiceBusMessage(json) { MessageId = ev.Id.ToString() };`
- `new Passo("cobrar cartao", Cobrar, Estornar),`
- `while (feitos.TryPop(out var f)) f.Compensar();`
- 2 linhas: `.AddStandardResilienceHandler(o =>` / `    o.Retry.DisableForUnsafeHttpMethods());`
- `_respostas.GetOrAdd(chave, _ => new Lazy<Resp>(executar)).Value;`

### 4.2 Desafios de lógica (sem digitação), com resposta verificada no laboratório
Tipos: **PS** prever a saída · **CL** completar lacuna · **OL** ordenar linhas · **AB** achar o bug · **VF** valor final · **EC** escolha conceitual.

1. **PS** `AreaEsperada` (define largura 4 e altura 3) com `new Retangulo()` e `new Quadrado()`? → `12` e `9`. É a violação de LSP.
2. **PS** `IList<int> l = new int[3]; l.Add(1);` → `NotSupportedException` ("Collection was of a fixed size.").
3. **PS** Transient/scoped/singleton: `Relogio==Relogio` no mesmo escopo, `Carrinho==Carrinho` no mesmo escopo, `Carrinho` entre escopos e `Config` entre escopos → `False, True, False, True`.
4. **PS** Registra `FreteSedex` e depois `FretePac` como `IFrete`: `GetRequiredService<IFrete>().Nome`? → `pac`. E `GetServices` → `sedex,pac`.
5. **PS** `new ComPrefixo(new Maiusculas(m)).Enviar("oi")` × `new Maiusculas(new ComPrefixo(m))` → `[LOG] OI` × `[log] OI`.
6. **PS** [jogo] `Flamejante(Dobro(Espada))` × `Dobro(Flamejante(Espada))`, com espada 10, dobro ×2 e fogo +5 → `25` × `30`.
7. **PS** [jogo] Clonou o Orc com `with` e trocou `p2.Itens[0]` para "clava": `p1.Itens[0]`? → `clava` (cópia rasa). `p1 == p2`? → `False`.
8. **PS** `Medir(20); Medir(20); Medir(25);` depois `-=` e `Medir(30)`: quantos avisos? → `2`.
9. **PS** `+= (_, _) => c++;` e `-= (_, _) => c++;`, depois `Medir(1)`: `c`? → `1` (não desinscreveu).
10. **PS** `Numeros()` com `yield`: imprime "antes" e depois itera. Saída? → `antes`, `inicio`, `1`, `meio`, `2`.
11. **PS** `var s = Pares(-1); Console.WriteLine("criou");` e depois `foreach` → "criou" sai **antes** da exceção.
12. **PS** Middleware A(B(handler)) → `A antes > B antes > handler > B depois > A depois`.
13. **PS** Combo(burger 20, refri 8, Combo(batata 10, molho 2)), com cada combo dando −5 → `30`.
14. **PS** `new Tags(["a"]) == new Tags(["a"])`? → `False`. E com a **mesma** lista? → `True`.
15. **PS** `new EmailFragil("a@b.com") with { Valor = "x" }` → aceita `"x"`, porque o `with` não roda o initializer.
16. **PS** `Nota.ComId(7,10).Equals(Nota.ComId(7,99))` e `==` → `True False`.
17. **PS** A base chama um virtual no construtor. A derivada tem `_a = "campo"` (initializer) e `_b = "ctor"` (no corpo) → `base ve: campo/null`.
18. **PS** `var q = dados.Where(x => x > 1); dados.Add(10); q.Count()` com `dados = {1,2,3}` → `3` (a execução é adiada).
19. **PS** `ImagemProxy`: carregamentos antes de `Exibir()` e depois de dois `Exibir()` → `0` e `1`.
20. **PS** `Validar(15).Bind(Cadastrar)` / `Validar(30)…` / `Validar(200)…` → `menor de idade` / `cadastrado com 30` / `idade absurda`.
21. **PS** [jogo] `heroi = new NoChao().Pular().Pular();` e `heroi.Nome` → `ar`.
22. **PS** [jogo] Escudo absorve 5, armadura corta 50%, vida 100. Dano 25 e depois dano 4 → `90` e `90`.
23. **PS** Captive dependency **sem** validação: `Cache2.Repo.Id` em dois escopos é igual? → `True`.
24. **PS** Saga com o passo 3 falhando: quais linhas saem? → `ok ×2`, `falhou: agendar entrega`, `desfeito: cobrar cartao`, `desfeito: reservar estoque`. O "enviar e-mail" nunca roda.
25. **PS** `Dinheiro.Reais(10) == new Dinheiro(10, "brl")` → `True`, porque o construtor normaliza a moeda.
26. **VF** Conta Ana 100 e Bia 0. Transferir 150 falha, transferir 40 funciona → `60` e `40`.
27. **VF** Calculadora: executa +5, +10, +20 e desfaz 1 → `15`.
28. **VF** Pedido: cafe 2×10, pao 3×1, cafe +1 → `2` itens, total `BRL 33`.
29. **VF** `CarrinhoVazado` (limite 3): adiciona a,b,c,d, depois o cast e `Add("hack")` → `Count = 4`.
30. **VF** Estoque 10 e a mesma mensagem "baixar 3" chega 2× num consumidor idempotente → `7`.
31. **VF** [jogo] Pool: pega b1 e b2, devolve b1, pega b3. `ReferenceEquals(b1,b3)` e criadas → `True`, `2`.
32. **VF** [jogo] HUD: `Curar(0); Levar(10); Levar(0); Curar(5)` com vida inicial 100 → vida `95`, atualizações `2`.
33. **CL** `public IReadOnlyList<Item> Itens => _itens.____();` → `AsReadOnly`.
34. **CL** `services.Add____<Carrinho>(); // um por requisição` → `Scoped`.
35. **CL** `var p2 = p1 ____ { Nome = "Orc 2" };` → `with`.
36. **CL** `b.____(p => p.Preco); // value object no EF` → `ComplexProperty`.
37. **CL** `public static ____ operator Resultado<T>(Erro e) => Falha(e);` → `implicit`.
38. **CL** `.That().ResideInNamespace("Dominio").____().HaveDependencyOn("Infra")` → `ShouldNot`.
39. **CL** `sp.GetRequired____Service<IFrete>("pac")` → `Keyed`.
40. **OL** Command handler: `validar comando` → `criar/obter agregado` → `chamar método do agregado` → `repo.Adicionar` → `uow.SalvarAsync` → `retornar Id`.
41. **OL** Outbox: `iniciar transação` → `alterar entidade + inserir evento no outbox` → `commit` → `relay lê pendentes` → `publica` → `marca processada`.
42. **OL** Consumidor idempotente: `extrair MessageId` → `tentar inserir marcador + efeito (mesma transação)` → `se conflito: ack e descarta` → `senão: commit e ack`.
43. **OL** Strangler Fig: `pôr fachada` → `migrar funcionalidades aos poucos` → `desligar legado` → `remover fachada`.
44. **AB** `builder.Services.AddSingleton<RelatorioService>();` sendo que `RelatorioService(AppDbContext db)` → captive dependency. O serviço deve ser scoped, ou usar `IServiceScopeFactory`.
45. **AB** `await _bus.Publish(evento); await db.SaveChangesAsync();` → se o commit falhar, sai um evento fantasma. Use outbox.
46. **AB** `if (!await db.Processadas.AnyAsync(x => x.MensagemId == id)) { … }` e o insert do marcador depois → corrida entre consumidores. A solução é uma constraint única e o marcador na mesma transação.
47. **AB** Handler com `if (pedido.Itens.Count >= 10) return Erro…` → a regra vazou para a aplicação e deve estar em `Pedido.AdicionarItem`.
48. **AB** `static Config? _i; public static Config I => _i ??= new Config();` → não é thread-safe. Use `Lazy<T>` ou DI.
49. **AB** `public List<ItemPedido> Itens { get; set; }` no agregado → setter público e lista mutável, que furam as invariantes.
50. **AB** POST `/pagamentos` com `AddStandardResilienceHandler()` padrão e sem Idempotency-Key → o retry pode cobrar 2×.
51. **EC** Onde fica `IPedidoRepository`? → no domínio/core. A implementação EF fica na infra.
52. **EC** Endereço é entidade ou VO? → VO no e-commerce. Pode ser entidade numa distribuidora de energia, se a identidade importar.
53. **EC** CPF inválido digitado → Result. Banco fora do ar → exceção (e retry/circuit breaker).
54. **EC** A deduplicação do Service Bus basta? → Não: a janela é limitada e só vale do lado do envio. O consumidor continua idempotente.
55. **EC** Chave de dedup: `MessageId` ou `CorrelationId`? → `MessageId`, pois o CorrelationId agrupa várias mensagens.
56. **EC** Orquestração ou coreografia para 6 passos em 5 serviços? → Orquestração (evita dependência cíclica e é mais fácil de rastrear).
57. **EC** MVP com fronteiras incertas: microsserviços ou monolito modular? → Monolito modular.
58. **EC** Qual padrão? Cache em volta do repositório sem alterá-lo → **Decorator**. SDK legado → **Adapter**. Simplificar 3 subsistemas → **Facade**. Desfazer jogada → **Command/Memento**. Muitos tiles iguais → **Flyweight**.
59. **EC** Mensagem "preço = 25" ou "some 5"? → "preço = 25", que é naturalmente idempotente (mas cuidado com a ordem e as versões).
60. **EC** CQRS com dois bancos num CRUD de cadastro? → Não. Fowler recomenda usar só onde houver complexidade ou assimetria real.

## 5. URLs consultadas
**E-book "Architect Modern Web Applications with ASP.NET Core and Azure"** (https://learn.microsoft.com/en-us/dotnet/architecture/modern-web-apps-azure/):
- .../architectural-principles · .../common-web-application-architectures · .../develop-asp-net-core-mvc-apps · .../work-with-data-in-asp-net-core-apps · .../test-asp-net-core-mvc-apps

**E-book ".NET Microservices: Architecture for Containerized .NET Applications"** (https://learn.microsoft.com/en-us/dotnet/architecture/microservices/):
- microservice-ddd-cqrs-patterns/: ddd-oriented-microservice · microservice-domain-model · net-core-microservice-domain-model · seedwork-domain-model-base-classes-interfaces · implement-value-objects · enumeration-classes-over-enum-types · domain-model-layer-validations · domain-events-design-implementation · infrastructure-persistence-layer-design · infrastructure-persistence-layer-implementation-entity-framework-core · apply-simplified-microservice-cqrs-ddd-patterns · cqrs-microservice-reads · microservice-application-layer-web-api-design · microservice-application-layer-implementation-web-api
- multi-container-microservice-net-applications/: integration-event-based-microservice-communications · subscribe-events
- architect-microservice-container-applications/: asynchronous-message-based-communication

**Azure Architecture Center / Well-Architected** (https://learn.microsoft.com/en-us/azure/...):
- architecture/patterns/: cqrs · event-sourcing · saga · compensating-transaction · idempotent-consumer · anti-corruption-layer · strangler-fig
- architecture/databases/guide/transactional-out-box-cosmos · architecture/microservices/model/domain-analysis · architecture/microservices/model/tactical-domain-driven-design · well-architected/architect-role/architecture-decision-record

**Docs .NET / C# / EF Core** (https://learn.microsoft.com/en-us/...):
- dotnet/core/extensions/dependency-injection/overview · dotnet/core/extensions/dependency-injection-guidelines · dotnet/core/resilience/http-resilience
- dotnet/standard/exceptions/best-practices-for-exceptions · dotnet/standard/events/observer-design-pattern
- dotnet/csharp/whats-new/tutorials/primary-constructors · dotnet/csharp/language-reference/builtin-types/record · dotnet/csharp/fundamentals/coding-style/identifier-names · dotnet/csharp/whats-new/csharp-14 · dotnet/csharp/whats-new/csharp-15
- ef/core/what-is-new/ef-core-10.0/whatsnew

**SOLID e padrões**
- https://deviq.com/principles/solid · https://deviq.com/principles/single-responsibility-principle/ · https://deviq.com/principles/open-closed-principle/ · https://deviq.com/principles/liskov-substitution-principle/ · https://deviq.com/principles/interface-segregation/ · https://deviq.com/principles/dependency-inversion-principle/
- https://refactoring.guru/design-patterns/csharp · https://refactoring.guru/design-patterns/catalog · https://refactoring.guru/design-patterns/singleton/csharp/example · https://refactoring.guru/design-patterns/strategy/csharp/example · https://refactoring.guru/design-patterns/decorator/csharp/example · https://refactoring.guru/design-patterns/observer/csharp/example · https://refactoring.guru/design-patterns/chain-of-responsibility/csharp/example
- https://gameprogrammingpatterns.com/contents.html

**Templates, bibliotecas e repositórios**
- https://github.com/jasontaylordev/CleanArchitecture · https://github.com/ardalis/CleanArchitecture · https://ardalis.github.io/CleanArchitecture/
- Docs do template Ardalis (raw GitHub): docs/content/design-decisions.md · docs/content/migration-guides/v10-to-v11.md · docs/content/minimal-clean-architecture.md · Directory.Packages.props · MinimalClean/src/MinimalClean.Architecture.Web/config.nsdepcop
- https://github.com/ardalis/Specification · https://raw.githubusercontent.com/ardalis/Specification/main/docs/usage/create-specifications.md · https://specification.ardalis.com/
- https://github.com/martinothamar/Mediator · https://github.com/BenMorris/NetArchTest · https://github.com/NeVeSpl/NetArchTest.eNhancedEdition · https://github.com/TNG/ArchUnitNET
- https://github.com/kgrzybek/modular-monolith-with-ddd

**Artigos e referências**
- https://www.jimmybogard.com/vertical-slice-architecture/ · https://www.jimmybogard.com/automapper-and-mediatr-commercial-editions-launch-today/
- https://milanjovanovic.tech/blog/mediatr-and-masstransit-going-commercial-what-this-means-for-you · https://masstransit.massient.com/introduction/v9-announcement (só confirma a Massient como empresa do v9 comercial)
- https://alistair.cockburn.us/hexagonal-architecture/ · https://c4model.com/
- https://martinfowler.com/bliki/CQRS.html · https://martinfowler.com/bliki/DDD_Aggregate.html · https://martinfowler.com/bliki/ValueObject.html
- https://microservices.io/patterns/data/transactional-outbox.html · https://microservices.io/patterns/data/saga.html
- https://andrewlock.net/working-with-the-result-pattern-part-1-replacing-exceptions-as-control-flow/ · https://andrewlock.net/working-with-the-result-pattern-part-4-is-the-result-pattern-worth-it/
- Versões via https://api.nuget.org/v3-flatcontainer/ : NetArchTest.Rules 1.3.2 · NetArchTest.eNhancedEdition 1.4.5 · TngTech.ArchUnitNET 0.13.4 · Microsoft.EntityFrameworkCore.Sqlite 9.0.20 · Microsoft.Extensions.Http.Resilience 9.10.0
