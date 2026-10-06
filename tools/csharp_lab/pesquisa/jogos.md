# Dossiê — frente **jogos** (PAC·C#): programação de jogos com C#

Pesquisa feita em **27/09/2026**. Cobre Unity 6, Godot 4 com C#, MonoGame, os padrões do livro *Game Programming Patterns* (Robert Nystrom) e lógica de jogo em C# puro.

**Como foi verificado**
- Documentação oficial (Unity 6000.3, pacote Input System, Godot *stable* = 4.7, MonoGame, Microsoft Learn).
- Código-fonte de referência: UnityCsReference nos ramos 6000.0 a 6000.7, InputSystem (ramo `develop`), Godot `4.7.2-stable` e MonoGame (ramo `develop`).
- Assinaturas do Godot e do MonoGame **extraídas por reflexão** (Mono.Cecil) dos pacotes NuGet reais: `GodotSharp 4.7.2` e `MonoGame.Framework.DesktopGL 3.8.5.1`.
- **Todos os exemplos deste dossiê foram compilados**:
  - Unity: stub C# 9 / netstandard2.1, com os warnings tratados como erro.
  - Godot: `Godot.NET.Sdk/4.7.2` com os geradores de código e analisadores reais.
  - MonoGame: pacote 3.8.5.1.
  - C# puro: net9.0.
- As respostas de "prever a saída" em C# puro e em MonoGame foram **executadas**. As da Unity foram tiradas do código-fonte ou da documentação, conforme indicado em cada item.

Os arquivos auxiliares ficam no scratchpad, em `pesquisa/raw/validate/` (um diretório por engine):

| Diretório | Conteúdo |
|---|---|
| `purecs/` | Lógica pura: `Logica.cs`, `Padroes.cs`, `Modernos.cs`, `Program.cs` |
| `unitystub/` | Stub mínimo do UnityEngine (serve de ponto de partida para o stub oficial) |
| `unitysnippets/` | Exemplos de Unity |
| `unityneg/` e `godotneg/` | Casos de erro com os códigos de compilador confirmados |
| `godot/` | Exemplos de Godot |
| `monogame/` | Exemplos de MonoGame |
| `bug2048/` | Variantes com bug do 2048, usadas nos desafios de "achar o bug" |

Outros auxiliares, também em `raw/`:
- `raw/src63/`: fontes do UnityCsReference 6000.3, só para consulta. Licença *Reference Only*: não redistribuir.
- `raw/apidump/`: a ferramenta de dump de assinaturas.

---

## 0. Resumo executivo: versões e decisões para o curso

| Alvo | Versão verificada | C# / .NET | Observações que mudam o conteúdo |
|---|---|---|---|
| **Unity** | 6.3 LTS (6000.3, suporte até dez/2027). A release atual é a 6.6 (31/08/2026). A 6.0 LTS perde suporte em out/2026. | **C# 9.0** (Roslyn), API **.NET Standard 2.1** (padrão) | Sem `init`, sem records em tipos serializados, sem recursos de C# 10+ (namespace de arquivo, `global using`, collection expressions `[..]`, `required`, construtor primário em classe). Sem `PriorityQueue`, `Random.Shared` ou `Random.Shuffle`. A Unity **7.0** vai trazer CoreCLR com .NET 10 e C# 14; a 6.7 LTS é a última baseada em Mono. |
| **Godot** | 4.7.2 (a 4.8 está em dev) | Projeto gerado com **net8.0** (C# 12). Android usa net9.0. | Classe `partial` obrigatória, `delta` é `double`, sinais via `delegate ...EventHandler`. **Projetos C# não exportam para Web.** |
| **MonoGame** | 3.8.5.1 | Templates com **net9.0** (C# 13) | Loop `Initialize → LoadContent → Update/Draw`. Por padrão usa passo fixo de 1/60 s e limita cada quadro a no máximo 500 ms. |
| **C# puro** | .NET 9/10 | C# 13/14 | Pode usar `PriorityQueue` (.NET 6+), `Random.Shared` (6+), `Random.Shuffle`/`GetItems` (8+) e `PriorityQueue.Remove` (9+). |

**Recomendações**
1. Separar os exercícios em **"C# 9 compatível com Unity"** e **"C# moderno"** (console, Godot e MonoGame). O validador deve compilar cada grupo com o `LangVersion` e o *target* certos (ver §6).
2. Ensinar a API **atual** da Unity 6:
   - `linearVelocity`, `linearDamping` e `angularDamping` (não `velocity`, `drag` e `angularDrag`);
   - `FindAnyObjectByType<T>()` (não `FindObjectOfType`);
   - **Input System** (`InputSystem.actions.FindAction("Move")`) como padrão, com o Input Manager legado apresentado como "código que você vai encontrar";
   - `Awaitable` com `destroyCancellationToken` como alternativa moderna às corrotinas.
3. Não depender de `FindFirstObjectByType`, de `FindObjectsByType(..., FindObjectsSortMode)` nem de `GetInstanceID`, que ficaram obsoletos na 6.4+ (tabela em §2.2).
4. Com o *Fast Enter Play Mode* (padrão em projetos novos da 6.6), **campos `static` não são zerados** entre execuções do Play. Todo Singleton do curso deve ter reset com `[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]`.
5. Nos desafios de "prever a saída", **evitar imprimir `float`/`double`** sem cultura fixa, porque em pt-BR sai `1,5`. `Vector3.ToString()` da Unity usa cultura invariante (`(1.50, 2.00, 0.00)`), mas `Vector2.ToString()` do MonoGame usa a cultura atual (`{X:1,5 Y:2}`, verificado).

---

## 1. Árvore de tópicos em ordem didática

Convenção dos níveis: **[I]** iniciante, **[M]** intermediário, **[A]** avançado, **[S]** sênior.

### J1 — Lógica de jogo em C# puro (console), sem engine
1. **[I] Game loop**: entrada → atualizar → desenhar, e por que o jogo não "espera" o jogador. Mostrar o loop com `while` e o `Update(dt)`. Fonte: https://gameprogrammingpatterns.com/game-loop.html
2. **[I] Estado numérico**: vida, pontos e nível. Divisão inteira (`7 / 10 == 0`), `Math.Clamp` e `Math.Max`. Fonte: https://learn.microsoft.com/en-us/dotnet/api/system.math.clamp
3. **[I] Aleatoriedade**:
   - `new Random()` e `Next(min, max)` com **max exclusivo**; dados 1d6 e 2d6.
   - Seed fixa só é reprodutível **dentro da mesma versão do .NET**.
   - `Random.Shared` (.NET 6+).

   Fonte: https://learn.microsoft.com/en-us/dotnet/api/system.random
4. **[I] `enum` e `switch`** para direções, estados e naipes. `[Flags]` para status (veneno, gelo). Fonte: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/enum
5. **[I] Grade 2D**:
   - `int[,]` com `GetLength(0)` para linhas e `GetLength(1)` para colunas.
   - Vizinhos 4 e 8.
   - A convenção (linha, coluna) é diferente de (x, y).
6. **[I] Colisão AABB e de círculo**:
   - AABB com comparações **estritas**: encostar não colide.
   - Círculo comparando a distância ao quadrado.

   Fonte: https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
7. **[I] Timers e cooldown com delta time**: acumular `dt` e comparar com a duração. Tudo "por segundo" é multiplicado por `dt`.
8. **[M] Coleções de jogo**:
   - `List`, `Queue`, `Stack`, `Dictionary` e `HashSet`.
   - **Nunca alterar uma lista durante o `foreach`** (lança `InvalidOperationException`).
9. **[M] Passo fixo com acumulador**, *interpolação* do desenho e trava contra a "espiral da morte". Fontes: https://gameprogrammingpatterns.com/game-loop.html · https://gafferongames.com/post/fix_your_timestep/

### J2 — Mini-jogos clássicos em C# puro (desafios com tema de jogo)
10. **[M] Cobrinha**:
    - Segmentos em lista: insere a cabeça e remove a cauda; cresce sem remover.
    - Travessia das bordas com **módulo positivo**: `((a % n) + n) % n`.
    - Proibir a volta de 180° (produto escalar `>= 0`).
    - Andar em "ticks" de 200 ms.

    Fonte: https://docs.monogame.net/articles/tutorials/building_2d_games/22_snake_game_mechanics/index.html
11. **[M] Campo minado**:
    - Contagem das 8 vizinhas.
    - *Flood fill* ao abrir uma célula com 0.
    - Vitória quando todas as não-minas estão abertas.
    - Tabuleiros 9×9/10, 16×16/40 e 30×16/99.

    Fonte: https://en.wikipedia.org/wiki/Minesweeper_(video_game)
12. **[M] 2048**:
    - Deslizar e fundir, com cada peça fundindo **uma vez por jogada**.
    - Três iguais: fundem as duas mais à frente.
    - Nova peça: 2 (90%) ou 4 (10%).
    - A pontuação soma o valor da peça criada.

    Fonte: https://en.wikipedia.org/wiki/2048_(video_game)
13. **[M] Game of Life (B3/S23)**: a geração nova é função pura da anterior, com dois buffers (padrão Double Buffer). Blinker tem período 2 e glider período 4. Fontes: https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life · https://gameprogrammingpatterns.com/double-buffer.html
14. **[M] Baralho**:
    - `enum Naipe` e 52 cartas.
    - **Fisher–Yates** com `j` em `0..i` inclusive. Usar `j < i` vira o algoritmo de Sattolo; usar `0..n-1` sempre gera viés.
    - `Random.Shuffle` no .NET 8+.

    Fontes: https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle · https://learn.microsoft.com/en-us/dotnet/api/system.random.shuffle
15. **[M] Inventário**: `Dictionary<string,int>` com pilhas, capacidade por tipo, remover a pilha quando zera e `TryGetValue`.
16. **[M] Loot table com pesos**: soma dos pesos, `rng.Next(total)` e subtração acumulada. Testar sempre as fronteiras: rolagem 69, 70 e 94.
17. **[M] Combate por turnos**: iniciativa, fórmula `Math.Max(1, (atk - def) * crit)`, laço até alguém morrer e log do combate.
18. **[M] IA com máquina de estados** usando `enum` e *switch expression* com `when`, antes de passar para classes. Fonte: https://gameprogrammingpatterns.com/state.html
19. **[A] Busca em grade**:
    - **BFS**: fila, `veioDe` e *early exit*.
    - **Dijkstra** e **A\***: prioridade = custo + heurística de Manhattan.
    - `PriorityQueue<TElement,TPriority>` não tem *decrease-key*: enfileira de novo.
    - Empates geram "caminhos feios".

    Fontes: https://www.redblobgames.com/pathfinding/a-star/introduction.html · https://www.redblobgames.com/pathfinding/a-star/implementation.html · https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.priorityqueue-2

### J3 — Unity 6: fundamentos de script
20. **[I] Script = componente**: `MonoBehaviour` em um GameObject, nome da classe igual ao do arquivo, `Debug.Log`. Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/MonoBehaviour.html
21. **[I] Ciclo de vida**:
    - `Awake` roda mesmo com o script desabilitado, **uma vez só**, e não pode ser corrotina.
    - `OnEnable` roda depois do `Awake` e antes do `Start`.
    - `Start` só roda com o script habilitado e **pode** ser `IEnumerator`.
    - Depois vêm `FixedUpdate` (0, 1 ou N vezes por frame), `Update` e `LateUpdate`, e por fim `OnDisable` → `OnDestroy`.
    - A ordem entre objetos diferentes **não é garantida**.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/Manual/execution-order.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/MonoBehaviour.Awake.html
22. **[I] Transform**:
    - `position` e `localPosition`, `rotation` e `eulerAngles`.
    - `Translate` e `Rotate` com `Space.Self` (padrão) ou `Space.World`.
    - `LookAt` e `forward`.

    Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Transform.html
23. **[I] Vector2/Vector3**:
    - `magnitude`, `normalized` e `sqrMagnitude` (compare distâncias ao quadrado).
    - `Distance`, `Lerp` (t travado em [0,1]) e `MoveTowards` (não passa do alvo).
    - O `==` do Vector3 é **aproximado**.

    Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Vector3.html
24. **[I] Quaternion**:
    - `identity`, `Euler`, `LookRotation`, `Slerp`, `RotateTowards` e `AngleAxis`.
    - A ordem na multiplicação é `q * v` (o contrário, `v * q`, não compila).

    Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Quaternion.html
25. **[I] Delta time**:
    - `Time.deltaTime`; dentro do `FixedUpdate` ele devolve `fixedDeltaTime`.
    - `Time.timeScale`: com 0, `FixedUpdate` e `WaitForSeconds` param.
    - `unscaledDeltaTime` para UI de pausa.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Time-deltaTime.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Time-timeScale.html
26. **[I] Inspector**:
    - `public` versus `[SerializeField] private`.
    - `[Header]`, `[Tooltip]`, `[Range]`, `[Min]`, `[Space]` e `[HideInInspector]`.
    - `[RequireComponent(typeof(...))]`, que só atua no `AddComponent`.
    - `[field: SerializeField]` para propriedades automáticas.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/SerializeField.html · https://docs.unity3d.com/6000.3/Documentation/Manual/script-serialization-rules.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/RequireComponent.html
27. **[I] Entrada**:
    - **Legado**: `Input.GetAxis`/`GetAxisRaw`/`GetKeyDown`/`GetButtonDown`. A doc diz "não use em projetos novos".
    - **Input System**: `using UnityEngine.InputSystem;`, `InputSystem.actions.FindAction("Move")`, `ReadValue<Vector2>()`, `IsPressed()`, `WasPressedThisFrame()`, `Keyboard.current.spaceKey.wasPressedThisFrame`.
    - "Active Input Handling" com as diretivas `ENABLE_INPUT_SYSTEM` e `ENABLE_LEGACY_INPUT_MANAGER`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Input.GetAxis.html · https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/quick-start-guide.md · https://github.com/Unity-Technologies/InputSystem/blob/develop/Packages/com.unity.inputsystem/Documentation~/corresponding-old-new-api.md
28. **[I] GetComponent**:
    - Guardar a referência em cache no `Awake`.
    - `TryGetComponent(out T)` não aloca no Editor.
    - `CompareTag("Player")`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Component.TryGetComponent.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/GameObject.CompareTag.html
29. **[I] Prefabs**:
    - `Instantiate(prefab, pos, rot)` e as sobrecargas genéricas; o clone recebe o nome "(Clone)".
    - `Destroy(obj)` só destrói de fato **depois do Update atual** (antes do render). `Destroy(obj, t)` destrói após `t` segundos, e esse tempo é afetado pelo `timeScale`.
    - `Destroy(this)` remove só o script.
    - `SetActive`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Object.Instantiate.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Object.Destroy.html · https://docs.unity3d.com/6000.3/Documentation/Manual/instantiating-prefabs-intro.html

### J4 — Unity 6: física, tempo, dados e feedback
30. **[M] Rigidbody**:
    - `linearVelocity` (Unity 6; `velocity` está obsoleto com auto-upgrade).
    - `AddForce` e `ForceMode` (`Force`, `Acceleration`, `Impulse`, `VelocityChange`).
    - `MovePosition`, `isKinematic`, `linearDamping`.
    - Ler o input no `Update` e aplicar no `FixedUpdate`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Rigidbody-linearVelocity.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Rigidbody.AddForce.html
31. **[M] 2D**:
    - `Rigidbody2D.linearVelocity` e `linearVelocityX/Y`.
    - `bodyType` (`isKinematic` está obsoleto).
    - `AddForce(Vector2, ForceMode2D)`.

    Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Rigidbody2D-linearVelocity.html
32. **[M] Colisões e triggers**:
    - `OnCollisionEnter(Collision)`: exige um Rigidbody **não cinemático**.
    - `OnTriggerEnter(Collider)`: um dos colliders é trigger e outro tem corpo físico.
    - As versões 2D usam `Collision2D`/`Collider2D`; parâmetro do tipo errado faz a mensagem ser **ignorada**.
    - As mensagens chegam mesmo com o script desabilitado.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/MonoBehaviour.OnCollisionEnter.html · https://docs.unity3d.com/6000.3/Documentation/Manual/collider-interactions-ontrigger.html
33. **[M] Raycast e camadas**:
    - `Physics.Raycast(ray, out RaycastHit hit, dist, mask)`; o raio **não detecta** o collider onde nasce.
    - `LayerMask.GetMask("Chao")` devolve máscara; `NameToLayer` devolve índice.
    - `Physics2D.Raycast` devolve `RaycastHit2D`, que converte para `bool`.
    - `OverlapSphereNonAlloc`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Physics.Raycast.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/LayerMask.GetMask.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Physics2D.Raycast.html
34. **[M] CharacterController**: `Move(Vector3)` sem gravidade, `SimpleMove` com gravidade, `isGrounded`. Uma chamada por frame. Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/CharacterController.Move.html
35. **[M] Corrotinas**:
    - `IEnumerator` com `yield return null` / `new WaitForSeconds(s)`.
    - `WaitForSecondsRealtime`, `WaitUntil` e `WaitWhile`.
    - `StartCoroutine`, e `StopCoroutine` com o **mesmo tipo** de argumento usado para iniciar.
    - Param com o GameObject inativo ou o script destruído. **Não param** com `enabled = false`.
    - Guardar o `WaitForSeconds` em cache.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/Manual/Coroutines.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/MonoBehaviour.StopCoroutine.html
36. **[M] `Invoke`/`InvokeRepeating`**: recebem o método por string e dependem do `timeScale`. Preferir corrotinas. Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/MonoBehaviour.InvokeRepeating.html
37. **[M] ScriptableObject**:
    - `[CreateAssetMenu(fileName=..., menuName=...)]`.
    - Dados compartilhados entre objetos (armas, inimigos): é o Flyweight/Type Object "de graça".
    - `CreateInstance<T>()`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/ScriptableObject.html · https://docs.unity3d.com/6000.3/Documentation/Manual/class-ScriptableObject.html
38. **[M] Eventos**:
    - `UnityEvent` e `UnityEvent<T>` (configuráveis no Inspector).
    - `AddListener`/`RemoveListener`/`Invoke`.
    - `event Action<T>` para código.
    - Assinar em `OnEnable` e cancelar em `OnDisable`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Events.UnityEvent.html · https://docs.unity3d.com/6000.3/Documentation/Manual/unity-events.html
39. **[M] Cenas**:
    - `SceneManager.LoadScene(nome/índice)` carrega **no próximo frame**.
    - `LoadSceneAsync` e `GetActiveScene().buildIndex`.
    - `DontDestroyOnLoad` só vale para objeto raiz.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/SceneManagement.SceneManager.LoadScene.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Object.DontDestroyOnLoad.html
40. **[M] Persistência**:
    - `PlayerPrefs.SetInt`/`GetInt(chave, padrão)`/`HasKey`. É gravado **sem criptografia**; `Save()` não deve ser chamado durante o jogo.
    - `JsonUtility.ToJson`/`FromJson<T>` segue as regras de serialização da Unity.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/PlayerPrefs.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/JsonUtility.ToJson.html
41. **[M] Animator e áudio**:
    - `SetBool`, `SetTrigger`, `SetFloat` e `SetInteger` com o **hash** de `Animator.StringToHash`.
    - `AudioSource.PlayOneShot` não corta os sons que já estão tocando; `PlayClipAtPoint`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Animator.SetTrigger.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/AudioSource.PlayOneShot.html
42. **[M] HUD**: TextMeshPro faz parte do uGUI 2.0 no Unity 6, com o namespace `TMPro` e a classe `TMP_Text`. Fonte: https://docs.unity3d.com/Packages/com.unity.ugui@2.0/manual/TextMeshPro/index.html

### J5 — Unity 6 avançado e sênior
43. **[A] Awaitable**:
    - `async Awaitable` e `Awaitable<T>`.
    - `NextFrameAsync`, `WaitForSecondsAsync`, `FixedUpdateAsync`, `EndOfFrameAsync`, `BackgroundThreadAsync`/`MainThreadAsync` e `FromAsyncOperation`.
    - `destroyCancellationToken`.
    - As instâncias são **reaproveitadas de um pool**: nunca faça `await` duas vezes na mesma.
    - A continuação roda **síncrona**, no mesmo frame em que a espera termina.
    - Dá para fazer `yield return` de um `Awaitable` numa corrotina, mas não de um `Awaitable<T>`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Awaitable.html · https://docs.unity3d.com/6000.3/Documentation/Manual/async-awaitable-introduction.html · https://docs.unity3d.com/6000.3/Documentation/Manual/async-awaitable-examples.html
44. **[A] Object Pool oficial**:
    - `UnityEngine.Pool.ObjectPool<T>(create, onGet, onRelease, onDestroy, collectionCheck, defaultCapacity, maxSize)`.
    - A checagem de dupla devolução só roda no Editor, e o pool não é thread-safe.

    Fonte: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Pool.ObjectPool_1.html
45. **[A] O `null` da Unity**:
    - O `==` sobrecarregado detecta objeto destruído.
    - `?.` e `??` **não são suportados** com `UnityEngine.Object`.
    - Conversão implícita para `bool`.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Object.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Object-operator_eq.html
46. **[A] Busca de objetos**:
    - `FindAnyObjectByType<T>()` substitui `FindObjectOfType`.
    - `GameObject.Find` é linear e lento; nunca usar no `Update`.
    - Preferir referências pelo Inspector.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Object.FindAnyObjectByType.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/GameObject.Find.html
47. **[A] Estado estático e Enter Play Mode**:
    - Sem *domain reload*, variáveis e eventos `static` persistem entre execuções do Play.
    - O reset é feito com `[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]`.
    - Na 6.6 isso é o padrão em projetos novos.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/Manual/domain-reloading.html · https://discussions.unity.com/t/path-to-coreclr-2026-upgrade-guide/1714279
48. **[A] Padrões na Unity**:
    - Factory, Pool, Singleton (com parcimônia), Command (undo/redo), State (`IState` com `Enter`/`Execute`/`Exit`), Observer (`event Action`) e MVP/MVVM.
    - Strategy e Flyweight com ScriptableObject; Dirty Flag.
    - SOLID.

    Fontes: https://unity.com/resources/design-patterns-solid-ebook · https://github.com/Unity-Technologies/game-programming-patterns-demo
49. **[S] Desempenho**:
    - Guardar em cache `GetComponent` e `Camera.main`.
    - Usar consultas `NonAlloc`, evitar `new WaitForSeconds` a cada volta de laço e evitar `Find` no `Update`.
    - `CompareTag` e hashes do Animator.
    - Medir com o Profiler.

    Fontes: https://docs.unity3d.com/6000.3/Documentation/Manual/Coroutines.html · https://docs.unity3d.com/6000.3/Documentation/ScriptReference/Camera-main.html
50. **[S] Futuro da plataforma**: a 6.7 LTS é a última com Mono. A 7.0 traz CoreCLR, .NET 10 e C# 14; `BinaryFormatter` fica obsoleto e a matemática de ponto flutuante segue IEEE 754 à risca, podendo dar resultados diferentes do Mono. Fontes: https://discussions.unity.com/t/coreclr-scripting-and-serialization-update-june-2026/1723299 · https://discussions.unity.com/t/path-to-coreclr-2026-upgrade-guide/1714279

### J6 — Godot 4 com C#
51. **[M] Script C#**:
    - `using Godot;` e `public partial class X : Node`, com o nome da classe **igual ao do arquivo**.
    - `GD.Print`.
    - A API usa PascalCase (`AddChild`, não `add_child`).
    - Recompilar (*Build*) para o editor ver novos `[Export]` e sinais.

    Fontes: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html · https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_differences.html
52. **[M] Callbacks**:
    - `_EnterTree`: pai antes dos filhos.
    - `_Ready`: **filhos antes do pai**, uma vez só.
    - `_Process(double delta)` a cada frame; `_PhysicsProcess(double delta)` 60×/s por padrão.
    - `_Input`/`_UnhandledInput(InputEvent @event)` e `_ExitTree`.

    Fontes: https://docs.godotengine.org/en/stable/tutorials/scripting/overridable_functions.html · https://docs.godotengine.org/en/stable/tutorials/scripting/idle_and_physics_processing.html
53. **[M] Nós**:
    - `GetNode<T>("Caminho/Filho")` e `GetNodeOrNull<T>`.
    - `[Export] public Sprite2D Retrato { get; set; }`, preferível a caminhos fixos.
    - `AddChild`, `QueueFree` (fim do frame; seguro chamar várias vezes).
    - `PackedScene.Instantiate<T>()`.

    Fonte: https://docs.godotengine.org/en/stable/tutorials/scripting/nodes_and_scene_instances.html
54. **[M] `[Export]`**:
    - Vale para campos e propriedades com tipos compatíveis com Variant.
    - `PropertyHint.Range`, `[ExportGroup]`, e export de nós e recursos.
    - Os analisadores rejeitam export estático (GD0101) ou somente leitura (GD0103).

    Fontes: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_exports.html · https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/diagnostics/index.html
55. **[M] Sinais**:
    - `[Signal] public delegate void MorreuEventHandler();`: o nome tem que terminar em `EventHandler` (GD0201).
    - `EmitSignal(SignalName.Morreu)`; não existe `Invoke` para sinais (erro CS0079).
    - Assinar com `+=`. Sinal próprio assinado com `+=` **não** desconecta sozinho: faça `-=` no `_ExitTree`.
    - `await ToSignal(obj, Classe.SignalName.X)`.

    Fonte: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_signals.html
56. **[M] Movimento**:
    - `CharacterBody2D.Velocity` é propriedade de struct: copie, altere e devolva.
    - `MoveAndSlide()`, `IsOnFloor()`, `GetGravity()`.
    - `Input.GetVector("ui_left","ui_right","ui_up","ui_down")`, `Input.GetAxis(neg,pos)`, `IsActionPressed`/`IsActionJustPressed`.
    - Ação inexistente gera o erro `The InputMap action "x" doesn't exist.`

    Fontes: https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html · https://docs.godotengine.org/en/stable/getting_started/first_2d_game/03.coding_the_player.html
57. **[M] Aleatório e matemática**:
    - `GD.RandRange(int,int)` é **inclusivo** nos dois lados; `GD.Randf()` fica em [0,1].
    - `Mathf.Pi`, `Mathf.PosMod` (módulo sempre positivo), `Mathf.Round` arredonda meio para o par.
    - `Vector2.X/Y` com letra maiúscula.

    Fonte: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_differences.html
58. **[A] Global classes e plataformas**: `[GlobalClass]` com o nome de arquivo exato. Android exige .NET 9 e **Web não é suportado** para C#. Fontes: https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_global_classes.html · https://docs.godotengine.org/en/stable/tutorials/scripting/c_sharp/c_sharp_basics.html

### J7 — MonoGame (framework, "você escreve o loop")
59. **[M] Classe `Game`**:
    - No construtor: `GraphicsDeviceManager`, `Content.RootDirectory = "Content"`, `IsMouseVisible`.
    - `Initialize`: o `base.Initialize()` inicializa o dispositivo gráfico e **chama o `LoadContent` no final**.
    - Depois, o laço `Update`/`Draw`.

    Fontes: https://docs.monogame.net/articles/tutorials/building_2d_games/03_the_game1_file/index.html · https://docs.monogame.net/api/Microsoft.Xna.Framework.Game.html
60. **[M] Conteúdo e desenho**:
    - `Content.Load<Texture2D>("nome")` com o nome sem extensão, via MGCB.
    - `SpriteBatch.Begin` → `Draw` → `End`; `DrawString(SpriteFont, ...)`.
    - `GraphicsDevice.Clear`.

    Fontes: https://docs.monogame.net/articles/tutorials/building_2d_games/05_content_pipeline/index.html · https://docs.monogame.net/api/Microsoft.Xna.Framework.Graphics.SpriteBatch.html
61. **[M] Entrada**:
    - `Keyboard.GetState()` retorna `KeyboardState` com `IsKeyDown`/`IsKeyUp`.
    - "Apertou agora" = estado atual abaixado **e** estado anterior levantado.
    - O eixo Y do analógico é invertido em relação à tela.
    - Mouse e `ButtonState`.

    Fontes: https://docs.monogame.net/articles/tutorials/building_2d_games/10_handling_input/index.html · https://docs.monogame.net/articles/tutorials/building_2d_games/11_input_management/index.html
62. **[M] Colisão**: `Rectangle.Intersects` usa `<` estrito (encostar não conta); `Contains` exclui a borda direita e a de baixo. Círculo com `Vector2.DistanceSquared`; resposta com `Vector2.Reflect`. Fontes: https://docs.monogame.net/articles/tutorials/building_2d_games/12_collision_detection/index.html · https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Rectangle.cs
63. **[A] Tempo**:
    - `gameTime.ElapsedGameTime.TotalSeconds`.
    - `IsFixedTimeStep` (padrão `true`) e `TargetElapsedTime` (1/60 s): o `Game.Tick` implementa o acumulador do padrão Game Loop, limita a 500 ms e liga `IsRunningSlowly`.

    Fonte: https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Game.cs

### J8 — Padrões de programação de jogos (Nystrom) e arquitetura
64. **[A] Game Loop**: desacoplar o tempo do jogo da entrada e da velocidade da CPU; passo fixo com acumulador e `render(lag / MS_PER_UPDATE)`. Fonte: https://gameprogrammingpatterns.com/game-loop.html
65. **[A] Update Method**: cada entidade simula um frame. Cuidado ao alterar a lista durante o update: adiar inclusões e remoções. Fonte: https://gameprogrammingpatterns.com/update-method.html
66. **[A] Double Buffer**: estado lido e estado escrito em buffers separados, com troca no fim (Game of Life, "tapas simultâneos"). Fonte: https://gameprogrammingpatterns.com/double-buffer.html
67. **[A] State**:
    - Máquina de estados finita com enum, depois classes de estado com `Entrar`/`Sair`.
    - Máquinas concorrentes e hierárquicas.
    - *Pushdown automaton* (pilha de estados) para "voltar ao estado anterior".

    Fonte: https://gameprogrammingpatterns.com/state.html
68. **[A] Command**: "uma chamada de método reificada". Serve para remapear entrada, controlar atores (IA ou jogador) e fazer undo/redo com duas pilhas. Fonte: https://gameprogrammingpatterns.com/command.html
69. **[A] Observer**: `event Action<T>` e o problema do **ouvinte esquecido**, que mesmo com GC mantém a UI viva. Cancelar a inscrição é obrigatório. Fonte: https://gameprogrammingpatterns.com/observer.html
70. **[A] Component**: uma entidade que atravessa domínios (física, render, entrada) sem acoplá-los; o próprio GameObject da Unity é esse padrão. Fonte: https://gameprogrammingpatterns.com/component.html
71. **[A] Object Pool**: reusar em vez de alocar. Pontos de atenção: memória desperdiçada, limite fixo, **objeto reciclado não se limpa sozinho** e lista livre. Fonte: https://gameprogrammingpatterns.com/object-pool.html
72. **[A] Flyweight / Type Object**: dados intrínsecos compartilhados (raça, modelo) versus extrínsecos (posição, vida); "novas classes" como dados. Fontes: https://gameprogrammingpatterns.com/flyweight.html · https://gameprogrammingpatterns.com/type-object.html
73. **[A] Spatial Partition**: grade uniforme (spatial hash) e quadtree; consultar só a célula e as vizinhas. Fonte: https://gameprogrammingpatterns.com/spatial-partition.html
74. **[S] Event Queue, Service Locator (com Null Object), Dirty Flag, Data Locality (ponte para ECS/DOTS), Singleton ("por que nos arrependemos") e Bytecode/Subclass Sandbox (leitura).** Fontes: https://gameprogrammingpatterns.com/event-queue.html · https://gameprogrammingpatterns.com/service-locator.html · https://gameprogrammingpatterns.com/dirty-flag.html · https://gameprogrammingpatterns.com/data-locality.html · https://gameprogrammingpatterns.com/singleton.html

---

## 2. Assinaturas exatas das APIs (para o stub e para os geradores)

### 2.1 UnityEngine (Unity 6.3)

Fontes: ScriptReference 6000.3 e https://github.com/Unity-Technologies/UnityCsReference/tree/6000.3. Listei só o subconjunto útil ao curso. Todos são `public`.

```csharp
namespace UnityEngine {
// Object (base de tudo; == e != sobrecarregados, conversão implícita para bool)
class Object { string name {get;set;} HideFlags hideFlags {get;set;}
  static Object Instantiate(Object original);  static Object Instantiate(Object original, Transform parent);
  static Object Instantiate(Object original, Transform parent, bool instantiateInWorldSpace);
  static Object Instantiate(Object original, Vector3 position, Quaternion rotation);
  static Object Instantiate(Object original, Vector3 position, Quaternion rotation, Transform parent);
  static T Instantiate<T>(T original) where T : Object;   // + (T, Transform) (T, Transform, bool worldPositionStays)
  static T Instantiate<T>(T original, Vector3 position, Quaternion rotation) where T : Object; // + (…, Transform parent)
  static void Destroy(Object obj, float t = 0.0F);   // no fonte: 2 sobrecargas (obj) e (obj, t)
  static void DontDestroyOnLoad(Object target);
  static T FindAnyObjectByType<T>() where T : Object;     // + (FindObjectsInactive)
  static T FindFirstObjectByType<T>() where T : Object;   // [Obsolete] a partir da 6.4
  static T[] FindObjectsByType<T>(FindObjectsSortMode sortMode) where T : Object; // [Obsolete] a partir da 6.4
  [Obsolete] static T FindObjectOfType<T>() where T : Object; // obsoleto desde a 2023.1 (warning)
  static bool operator ==(Object x, Object y); static implicit operator bool(Object exists); }
class Component : Object { Transform transform {get;} GameObject gameObject {get;} string tag {get;set;}
  T GetComponent<T>(); Component GetComponent(Type type); bool TryGetComponent<T>(out T component);
  T GetComponentInChildren<T>(); T GetComponentInChildren<T>(bool includeInactive); T GetComponentInParent<T>();
  T[] GetComponents<T>(); bool CompareTag(string tag); }
class Behaviour : Component { bool enabled {get;set;} bool isActiveAndEnabled {get;} }
class MonoBehaviour : Behaviour { CancellationToken destroyCancellationToken {get;} bool didAwake {get;} bool didStart {get;}
  Coroutine StartCoroutine(IEnumerator routine); Coroutine StartCoroutine(string methodName, object value = null);
  void StopCoroutine(IEnumerator routine); void StopCoroutine(Coroutine routine); void StopCoroutine(string methodName);
  void StopAllCoroutines(); void Invoke(string methodName, float time);
  void InvokeRepeating(string methodName, float time, float repeatRate); void CancelInvoke(); static void print(object message); }
sealed class GameObject : Object { GameObject(); GameObject(string name); GameObject(string name, params Type[] components);
  Transform transform {get;} int layer {get;set;} string tag {get;set;} bool activeSelf {get;} bool activeInHierarchy {get;}
  void SetActive(bool value); T AddComponent<T>() where T : Component; T GetComponent<T>(); bool TryGetComponent<T>(out T component);
  bool CompareTag(string tag); static GameObject Find(string name); static GameObject FindWithTag(string tag);
  static GameObject[] FindGameObjectsWithTag(string tag); static GameObject CreatePrimitive(PrimitiveType type); }
class Transform : Component, IEnumerable { Vector3 position {get;set;} Vector3 localPosition {get;set;}
  Vector3 eulerAngles {get;set;} Vector3 localEulerAngles {get;set;} Quaternion rotation {get;set;} Quaternion localRotation {get;set;}
  Vector3 localScale {get;set;} Vector3 forward {get;set;} Vector3 right {get;set;} Vector3 up {get;set;} Transform parent {get;set;}
  int childCount {get;} void SetParent(Transform p); void SetParent(Transform parent, bool worldPositionStays);
  void SetPositionAndRotation(Vector3 position, Quaternion rotation);
  void Translate(Vector3 translation, Space relativeTo = Space.Self); void Translate(float x, float y, float z, Space relativeTo = Space.Self);
  void Rotate(Vector3 eulers, Space relativeTo = Space.Self); void Rotate(float xAngle, float yAngle, float zAngle, Space relativeTo = Space.Self);
  void Rotate(Vector3 axis, float angle, Space relativeTo = Space.Self); void RotateAround(Vector3 point, Vector3 axis, float angle);
  void LookAt(Transform target, Vector3 worldUp = Vector3.up); void LookAt(Vector3 worldPosition, Vector3 worldUp = Vector3.up);
  Vector3 TransformPoint(Vector3 position); Vector3 InverseTransformPoint(Vector3 position); Transform GetChild(int index); Transform Find(string n); }
struct Vector3 { float x, y, z;   // CAMPOS (v.x = 1 funciona numa variável local)
  Vector3(float x, float y, float z); Vector3(float x, float y); static Vector3 zero, one, up, down, left, right, forward, back {get;}
  float magnitude {get;} float sqrMagnitude {get;} Vector3 normalized {get;} void Normalize();
  static Vector3 Lerp(Vector3 a, Vector3 b, float t); static Vector3 LerpUnclamped(Vector3 a, Vector3 b, float t);
  static Vector3 MoveTowards(Vector3 current, Vector3 target, float maxDistanceDelta);
  static Vector3 SmoothDamp(Vector3 current, Vector3 target, ref Vector3 currentVelocity, float smoothTime /*, float maxSpeed = Mathf.Infinity, float deltaTime = Time.deltaTime*/);
  static float Distance(Vector3 a, Vector3 b); static float Dot(Vector3 lhs, Vector3 rhs); static Vector3 Cross(Vector3 lhs, Vector3 rhs);
  static float Angle(Vector3 from, Vector3 to); static Vector3 ClampMagnitude(Vector3 vector, float maxLength);
  static Vector3 Reflect(Vector3 inDirection, Vector3 inNormal); operadores + - * / == (APROXIMADO) != ; ToString() => "(x, y, z)" com F2 e cultura invariante }
// Vector2: igual em espírito (x, y; zero, one, up, down, left, right; Distance; Lerp; MoveTowards; Dot), com conversões implícitas de/para Vector3
struct Quaternion { static Quaternion identity {get;} Vector3 eulerAngles {get;set;} static Quaternion Euler(float x, float y, float z);
  static Quaternion Euler(Vector3 euler); static Quaternion LookRotation(Vector3 forward, Vector3 upwards = Vector3.up);
  static Quaternion Slerp(Quaternion a, Quaternion b, float t); static Quaternion RotateTowards(Quaternion from, Quaternion to, float maxDegreesDelta);
  static Quaternion AngleAxis(float angle, Vector3 axis); static Quaternion operator *(Quaternion lhs, Quaternion rhs);
  static Vector3 operator *(Quaternion rotation, Vector3 point); }   // só q * v
struct Mathf { const float PI, Infinity, NegativeInfinity, Deg2Rad, Rad2Deg; static readonly float Epsilon;
  static float Clamp(float value, float min, float max); static int Clamp(int value, int min, int max); static float Clamp01(float value);
  static float Lerp(float a, float b, float t) /* t travado em [0,1] */; static float LerpUnclamped(float a, float b, float t);
  static float InverseLerp(float a, float b, float value); static float MoveTowards(float current, float target, float maxDelta);
  static float SmoothDamp(float current, float target, ref float currentVelocity, float smoothTime, float maxSpeed = Mathf.Infinity, float deltaTime = Time.deltaTime);
  static int RoundToInt(float f) /* (int)Math.Round: 2.5→2 */; static int FloorToInt(float f); static int CeilToInt(float f);
  static float Sign(float f) /* f >= 0 ? 1 : -1  (Sign(0) == 1) */; static float Abs(float f); static float Repeat(float t, float length);
  static float PingPong(float t, float length); static bool Approximately(float a, float b); static float Sin(float f); static float Atan2(float y, float x); }
static class Random /* UnityEngine.Random */ { static float Range(float minInclusive, float maxInclusive);
  static int Range(int minInclusive, int maxExclusive); static float value {get;} /* [0..1] inclusivo */
  static Vector2 insideUnitCircle {get;} static void InitState(int seed); }
static class Time { static float time, deltaTime, unscaledDeltaTime, realtimeSinceStartup {get;} static int frameCount {get;}
  static float fixedDeltaTime {get;set;} /* padrão 0.02 */ static float timeScale {get;set;} static float maximumDeltaTime {get;set;} }
static class Debug { static void Log(object message); static void Log(object message, Object context); static void LogWarning(object message);
  static void LogError(object message); static void DrawRay(Vector3 start, Vector3 dir, Color color, float duration); static void DrawLine(Vector3 start, Vector3 end); }
static class Input /* legado */ { static float GetAxis(string axisName); static float GetAxisRaw(string axisName);
  static bool GetButton(string buttonName); static bool GetButtonDown(string buttonName); static bool GetButtonUp(string buttonName);
  static bool GetKey(KeyCode key); static bool GetKeyDown(KeyCode key); static bool GetKeyUp(KeyCode key); /* + sobrecargas (string name) */
  static bool GetMouseButtonDown(int button) /* 0 esq, 1 dir, 2 meio */; static Vector3 mousePosition {get;} static bool anyKeyDown {get;} }
// Física 3D
enum ForceMode { Force = 0, Acceleration = 5, Impulse = 1, VelocityChange = 2 }
class Rigidbody : Component { Vector3 linearVelocity {get;set;} Vector3 angularVelocity {get;set;} float linearDamping {get;set;}
  float angularDamping {get;set;} float mass {get;set;} bool useGravity {get;set;} bool isKinematic {get;set;}
  void AddForce(Vector3 force, ForceMode mode = ForceMode.Force); void AddForce(float x, float y, float z, ForceMode mode = ForceMode.Force);
  void MovePosition(Vector3 position); void MoveRotation(Quaternion rot);
  [Obsolete("Please use Rigidbody.linearVelocity instead. (UnityUpgradable) -> linearVelocity")] Vector3 velocity {get;set;}  // idem drag, angularDrag
}
class Collider : Component { bool enabled {get;set;} bool isTrigger {get;set;} Rigidbody attachedRigidbody {get;} }
class Collision { GameObject gameObject {get;} Collider collider {get;} Transform transform {get;} Vector3 relativeVelocity {get;} int contactCount {get;} ContactPoint GetContact(int index); }
struct RaycastHit { Collider collider {get;} Vector3 point {get;set;} Vector3 normal {get;set;} float distance {get;set;} Transform transform {get;} }
class Physics { const int DefaultRaycastLayers, AllLayers;
  static bool Raycast(Vector3 origin, Vector3 direction, float maxDistance = Mathf.Infinity, int layerMask = DefaultRaycastLayers, QueryTriggerInteraction queryTriggerInteraction = QueryTriggerInteraction.UseGlobal);
  static bool Raycast(Vector3 origin, Vector3 direction, out RaycastHit hitInfo, float maxDistance, int layerMask, QueryTriggerInteraction queryTriggerInteraction); // a doc lista sem padrões; o fonte tem sobrecargas equivalentes
  static bool Raycast(Ray ray, float maxDistance = Mathf.Infinity, int layerMask = DefaultRaycastLayers, QueryTriggerInteraction q = QueryTriggerInteraction.UseGlobal);
  static bool Raycast(Ray ray, out RaycastHit hitInfo, float maxDistance = Mathf.Infinity, int layerMask = DefaultRaycastLayers, QueryTriggerInteraction q = QueryTriggerInteraction.UseGlobal);
  static Collider[] OverlapSphere(Vector3 position, float radius, int layerMask = AllLayers, QueryTriggerInteraction q = QueryTriggerInteraction.UseGlobal);
  static int OverlapSphereNonAlloc(Vector3 position, float radius, Collider[] results, int layerMask = AllLayers, QueryTriggerInteraction q = QueryTriggerInteraction.UseGlobal); }
struct LayerMask { int value {get;set;} static int GetMask(params string[] layerNames); static int NameToLayer(string layerName); implicit int <-> LayerMask }
class CharacterController : Collider { bool isGrounded {get;} CollisionFlags Move(Vector3 motion); bool SimpleMove(Vector3 speed); }
// Física 2D
enum ForceMode2D { Force = 0, Impulse = 1 }  enum RigidbodyType2D { Dynamic, Kinematic, Static }
sealed class Rigidbody2D : Component { Vector2 linearVelocity {get;set;} float linearVelocityX {get;set;} float linearVelocityY {get;set;}
  float gravityScale {get;set;} RigidbodyType2D bodyType {get;set;} float linearDamping {get;set;}
  void AddForce(Vector2 force, ForceMode2D mode = ForceMode2D.Force); void MovePosition(Vector2 position);
  [Obsolete] Vector2 velocity; [Obsolete] bool isKinematic; [Obsolete] float drag; }
class Collider2D : Behaviour { bool isTrigger {get;set;} }   class Collision2D { GameObject gameObject {get;} Collider2D collider {get;} }
struct RaycastHit2D { Vector2 point; Vector2 normal; float distance; Collider2D collider {get;} static implicit operator bool(RaycastHit2D hit); }
class Physics2D { static RaycastHit2D Raycast(Vector2 origin, Vector2 direction, float distance = Mathf.Infinity, int layerMask = DefaultRaycastLayers, float minDepth = -Mathf.Infinity, float maxDepth = Mathf.Infinity);
  static Collider2D OverlapCircle(Vector2 point, float radius, int layerMask = DefaultRaycastLayers); }
// Corrotinas
class YieldInstruction {}  sealed class Coroutine : YieldInstruction {}  sealed class WaitForSeconds : YieldInstruction { WaitForSeconds(float seconds); }
class WaitForSecondsRealtime : CustomYieldInstruction { WaitForSecondsRealtime(float time); }  sealed class WaitForFixedUpdate; sealed class WaitForEndOfFrame;
sealed class WaitUntil : CustomYieldInstruction { WaitUntil(Func<bool> predicate); }  sealed class WaitWhile : CustomYieldInstruction { WaitWhile(Func<bool> predicate); }
// Awaitable (Unity 6) — [AsyncMethodBuilder(typeof(AwaitableAsyncMethodBuilder))] public partial class Awaitable : IEnumerator
class Awaitable { static Awaitable NextFrameAsync(CancellationToken cancellationToken = default);
  static Awaitable WaitForSecondsAsync(float seconds, CancellationToken cancellationToken = default);
  static Awaitable FixedUpdateAsync(CancellationToken cancellationToken = default); static Awaitable EndOfFrameAsync(CancellationToken cancellationToken = default);
  static Awaitable FromAsyncOperation(AsyncOperation op, CancellationToken cancellationToken = default);
  static MainThreadAwaitable MainThreadAsync(); static BackgroundThreadAwaitable BackgroundThreadAsync(); bool IsCompleted {get;} void Cancel(); }
class Awaitable<T> { /* [AsyncMethodBuilder(typeof(Awaitable.AwaitableAsyncMethodBuilder<>))] */ }
// extensões: AsyncOperationAwaitableExtensions.GetAwaiter(this AsyncOperation) e UnityEventAwaitableExtensions.GetAwaiter(this UnityEvent)
// Dados, áudio, animação
class ScriptableObject : Object { static T CreateInstance<T>() where T : ScriptableObject; }
static class PlayerPrefs { static void SetInt(string key, int value); static int GetInt(string key); static int GetInt(string key, int defaultValue);
  static void SetFloat(string key, float value); static float GetFloat(string key, float defaultValue); static void SetString(string key, string value);
  static string GetString(string key, string defaultValue); static bool HasKey(string key); static void DeleteKey(string key); static void Save(); }
static class JsonUtility { static string ToJson(object obj); static string ToJson(object obj, bool prettyPrint); static T FromJson<T>(string json); }
class Animator : Behaviour { void SetTrigger(string name); void SetTrigger(int id); void ResetTrigger(string name); void SetBool(string name, bool value);
  void SetBool(int id, bool value); void SetFloat(string name, float value); void SetFloat(string name, float value, float dampTime, float deltaTime);
  void SetInteger(string name, int value); void Play(string stateName, int layer = -1, float normalizedTime = float.NegativeInfinity);
  static int StringToHash(string name); }   // + as sobrecargas (int id, …)
sealed class AudioSource : Behaviour { AudioClip clip {get;set;} float volume {get;set;} bool loop {get;set;} bool isPlaying {get;}
  void Play(); void Stop(); void PlayOneShot(AudioClip clip, float volumeScale = 1.0F); static void PlayClipAtPoint(AudioClip clip, Vector3 position, float volume = 1.0F); }
class Camera : Behaviour { static Camera main {get;} Ray ScreenPointToRay(Vector3 pos); Vector3 ScreenToWorldPoint(Vector3 position); }
static class Application { static int targetFrameRate {get;set;} static string persistentDataPath {get;} static void Quit(); }
// Atributos
[AttributeUsage(Field)] sealed class SerializeField; sealed class SerializeReference; sealed class HideInInspector;
class HeaderAttribute : PropertyAttribute { HeaderAttribute(string header); }  sealed class RangeAttribute : PropertyAttribute { RangeAttribute(float min, float max); }
class TooltipAttribute : PropertyAttribute { TooltipAttribute(string tooltip); } sealed class MinAttribute { MinAttribute(float min); } class SpaceAttribute { SpaceAttribute(); SpaceAttribute(float height); }
sealed class TextAreaAttribute { TextAreaAttribute(); TextAreaAttribute(int minLines, int maxLines); }
[AttributeUsage(Class, AllowMultiple = true)] sealed class RequireComponent { RequireComponent(Type t1); RequireComponent(Type t1, Type t2); RequireComponent(Type t1, Type t2, Type t3); }
sealed class DisallowMultipleComponent; class DefaultExecutionOrder { DefaultExecutionOrder(int order); }
sealed class CreateAssetMenuAttribute { string menuName {get;set;} string fileName {get;set;} int order {get;set;} }
class RuntimeInitializeOnLoadMethodAttribute { (); (RuntimeInitializeLoadType loadType); }  // enum: AfterSceneLoad, BeforeSceneLoad, AfterAssembliesLoaded, BeforeSplashScreen, SubsystemRegistration
}
namespace UnityEngine.SceneManagement { enum LoadSceneMode { Single, Additive } struct Scene { string name; int buildIndex; }
  class SceneManager { static Scene GetActiveScene(); static void LoadScene(string sceneName, LoadSceneMode mode = LoadSceneMode.Single);
    static void LoadScene(int sceneBuildIndex, LoadSceneMode mode = LoadSceneMode.Single);
    static AsyncOperation LoadSceneAsync(string sceneName, LoadSceneMode mode = LoadSceneMode.Single); static event UnityAction<Scene, LoadSceneMode> sceneLoaded; } }
namespace UnityEngine.Events { delegate void UnityAction(); delegate void UnityAction<T0>(T0 arg0);
  class UnityEvent : UnityEventBase { void AddListener(UnityAction call); void RemoveListener(UnityAction call); void Invoke(); }
  class UnityEvent<T0> : UnityEventBase { void AddListener(UnityAction<T0> call); void Invoke(T0 arg0); }  abstract class UnityEventBase { void RemoveAllListeners(); } }
namespace UnityEngine.Pool { interface IObjectPool<T> where T : class { int CountInactive {get;} T Get(); PooledObject<T> Get(out T v); void Release(T element); void Clear(); }
  class ObjectPool<T> : IDisposable, IObjectPool<T> where T : class { ObjectPool(Func<T> createFunc, Action<T> actionOnGet = null,
    Action<T> actionOnRelease = null, Action<T> actionOnDestroy = null, bool collectionCheck = true, int defaultCapacity = 10, int maxSize = 10000);
    int CountAll {get;} int CountActive {get;} } }
namespace UnityEngine.Serialization { class FormerlySerializedAsAttribute { FormerlySerializedAsAttribute(string oldName); } }
namespace TMPro { class TMP_Text /* : MaskableGraphic */ { string text {get;set;} } class TextMeshProUGUI : TMP_Text {} }
```

**Mensagens da Unity**
São encontradas **por nome e assinatura**, via reflexão. Não são virtuais: nunca use `override`. Lista para um *lint* do validador:

| Grupo | Mensagens |
|---|---|
| Sem parâmetro | `Awake`, `OnEnable`, `Start`, `Update`, `FixedUpdate`, `LateUpdate`, `OnDisable`, `OnDestroy`, `Reset`, `OnValidate`, `OnGUI`, `OnDrawGizmos`, `OnDrawGizmosSelected`, `OnBecameVisible`, `OnBecameInvisible`, `OnApplicationQuit`, `OnMouseDown`, `OnMouseUp`, `OnMouseEnter`, `OnMouseExit`, `OnMouseOver`, `OnMouseDrag`, `OnMouseUpAsButton` |
| `(bool)` | `OnApplicationPause`, `OnApplicationFocus` |
| `(Collision)`, parâmetro opcional | `OnCollisionEnter`, `OnCollisionStay`, `OnCollisionExit` |
| `(Collider)` | `OnTriggerEnter`, `OnTriggerStay`, `OnTriggerExit` |
| `(Collision2D)` | `OnCollisionEnter2D`, `OnCollisionStay2D`, `OnCollisionExit2D` |
| `(Collider2D)` | `OnTriggerEnter2D`, `OnTriggerStay2D`, `OnTriggerExit2D` |
| `(ControllerColliderHit)` | `OnControllerColliderHit` |

Quanto ao tipo de retorno:
- Podem ser `IEnumerator` (corrotina): `Start` e `OnCollisionEnter`, entre outras.
- **Não podem** ser corrotina: `Awake`, `OnEnable`, `OnDisable` e `OnDestroy`.

**Pacote Input System 1.x** (namespace `UnityEngine.InputSystem`; versão atual 1.20.0, de 21/07/2026). Fonte: https://github.com/Unity-Technologies/InputSystem/tree/develop/Packages/com.unity.inputsystem/InputSystem/Runtime

```csharp
static class InputSystem { static InputActionAsset actions {get;set;} }   // ações "project-wide"
class InputActionAsset : ScriptableObject { InputAction FindAction(string actionNameOrId, bool throwIfNotFound = false);
  InputActionMap FindActionMap(string nameOrId, bool throwIfNotFound = false); }
sealed class InputAction { TValue ReadValue<TValue>() where TValue : struct; bool IsPressed(); bool WasPressedThisFrame();
  bool WasReleasedThisFrame(); bool WasPerformedThisFrame(); bool triggered {get;} void Enable(); void Disable();
  event Action<InputAction.CallbackContext> started, performed, canceled;
  struct CallbackContext { TValue ReadValue<TValue>() where TValue : struct; bool performed {get;} } }
class Keyboard : InputDevice { static Keyboard current {get;} KeyControl spaceKey, escapeKey, wKey … {get;} }
class Mouse : Pointer { static new Mouse current {get;} ButtonControl leftButton {get;} }   class Pointer { Vector2Control position {get;} }
class Gamepad : InputDevice { static Gamepad current {get;} StickControl leftStick {get;} ButtonControl buttonSouth {get;} }
class ButtonControl /*Controls*/ { bool isPressed {get;} bool wasPressedThisFrame {get;} bool wasReleasedThisFrame {get;} }
class InputValue /*PlayerInput "Send Messages": void OnMove(InputValue v)*/ { TValue Get<TValue>() where TValue : struct; bool isPressed {get;} }
```
- Mapas padrão das ações: **"Player"** (Move, Look, Jump, Attack…) e **"UI"**.
- Nomes repetidos em mapas diferentes se resolvem com `"Player/Move"`.
- Os eventos `OnMouse*` funcionam com o Input System a partir do **Unity 6.4**.
- Se "Active Input Handling" estiver só no *Input System Package*, `UnityEngine.Input` lança `InvalidOperationException` ("You are trying to read Input using the UnityEngine.Input class, but you have switched active Input handling to Input System package in Player Settings").

### 2.2 Mudanças de API entre versões do Unity 6

Verificado no UnityCsReference, ramos 6000.0 a 6000.7.

| API | 6.0–6.3 | 6.4–6.5 | 6.6–6.7 | Ensinar |
|---|---|---|---|---|
| `Rigidbody.velocity`, `drag`, `angularDrag` (e os de `Rigidbody2D`) | `[Obsolete]` warning + API Updater | igual | igual | `linearVelocity`, `linearDamping`, `angularDamping` |
| `Rigidbody2D.isKinematic` | `[Obsolete]` | igual | igual | `bodyType = RigidbodyType2D.Kinematic` |
| `Object.FindObjectOfType<T>()` | `[Obsolete]` (desde 2023.1) | `[Obsolete]` "use FindAnyObjectByType" | igual | `FindAnyObjectByType<T>()` |
| `FindFirstObjectByType<T>()` | ok | **`[Obsolete]`** | `[Obsolete]` | evitar |
| `FindObjectsByType<T>(FindObjectsSortMode)` | ok | **`[Obsolete]`** (enum `FindObjectsSortMode` obsoleto) | igual | 6.4+: `FindObjectsByType<T>()` / `(FindObjectsInactive)` |
| `Object.GetInstanceID()` | ok | `[Obsolete]` warning | **`[Obsolete]` erro** → `GetEntityId()` | evitar |
| `UnityEngine.Input` (legado) | não obsoleto; a doc diz "não use em projetos novos" | igual | igual | Input System |
| Domain reload ao entrar no Play | ligado por padrão | igual | **desligado por padrão em projetos novos (6.6)** | resetar `static` |

### 2.3 Godot 4.7.2 (GodotSharp; dump por reflexão do pacote NuGet `GodotSharp 4.7.2`)

Fontes: https://www.nuget.org/packages/GodotSharp/4.7.2 · https://docs.godotengine.org/en/stable/

```csharp
namespace Godot {
class Node : GodotObject { StringName Name {get;set;} virtual void _Ready(); virtual void _Process(double delta);
  virtual void _PhysicsProcess(double delta); virtual void _EnterTree(); virtual void _ExitTree();
  virtual void _Input(InputEvent @event); virtual void _UnhandledInput(InputEvent @event);
  T GetNode<T>(NodePath path); Node GetNode(NodePath path); T GetNodeOrNull<T>(NodePath path); Node GetParent(); T GetParent<T>();
  void AddChild(Node node, bool forceReadableName = false, Node.InternalMode @internal = 0); void RemoveChild(Node node);
  Array<Node> GetChildren(bool includeInternal = false); int GetChildCount(bool includeInternal = false); SceneTree GetTree(); void QueueFree();
  void AddToGroup(StringName group, bool persistent = false); bool IsInGroup(StringName group); Tween CreateTween(); event Action Ready, TreeExiting; }
class GodotObject { static bool IsInstanceValid(GodotObject instance); void Free(); Error EmitSignal(StringName signal, params Variant[] args);
  SignalAwaiter ToSignal(GodotObject source, StringName signal); Error Connect(StringName signal, Callable callable, uint flags = 0);
  void SetDeferred(StringName property, Variant value); Variant CallDeferred(StringName method, params Variant[] args); }
class CanvasItem : Node { bool Visible {get;set;} Color Modulate {get;set;} void Show(); void Hide(); Rect2 GetViewportRect(); Vector2 GetGlobalMousePosition(); }
class Node2D : CanvasItem { Vector2 Position {get;set;} Vector2 GlobalPosition {get;set;} float Rotation {get;set;} float RotationDegrees {get;set;}
  Vector2 Scale {get;set;} void Rotate(float radians); void Translate(Vector2 offset); void LookAt(Vector2 point); }
class PhysicsBody2D : CollisionObject2D { KinematicCollision2D MoveAndCollide(Vector2 motion, bool testOnly = false, float safeMargin = 0.08f, bool recoveryAsCollision = false);
  Vector2 GetGravity(); }
class CharacterBody2D : PhysicsBody2D { Vector2 Velocity {get;set;} Vector2 UpDirection {get;set;} bool MoveAndSlide(); bool IsOnFloor();
  bool IsOnWall(); bool IsOnCeiling(); int GetSlideCollisionCount(); KinematicCollision2D GetSlideCollision(int slideIdx); }
class Area2D : CollisionObject2D { event BodyEnteredEventHandler BodyEntered; event BodyExitedEventHandler BodyExited; event AreaEnteredEventHandler AreaEntered; }
class Timer : Node { double WaitTime {get;set;} bool OneShot {get;set;} bool Autostart {get;set;} event Action Timeout; void Start(double timeSec = -1); void Stop(); }
class SceneTree { bool Paused {get;set;} Window Root {get;} SceneTreeTimer CreateTimer(double timeSec, bool processAlways = true, bool processInPhysics = false, bool ignoreTimeScale = false);
  Error ChangeSceneToFile(string path); Error ChangeSceneToPacked(PackedScene packedScene); Error ReloadCurrentScene(); void Quit(int exitCode = 0);
  Node GetFirstNodeInGroup(StringName group); Array<Node> GetNodesInGroup(StringName group); }
class SceneTreeTimer { event Action Timeout; }  // SceneTreeTimer.SignalName.Timeout (StringName)
class PackedScene : Resource { T Instantiate<T>(PackedScene.GenEditState editState = 0); Node Instantiate(PackedScene.GenEditState editState = 0); }
class AnimatedSprite2D : Node2D { StringName Animation {get;set;} bool FlipH {get;set;} bool FlipV {get;set;} void Play(StringName name = null, float customSpeed = 1f, bool fromEnd = false); void Stop(); }
static class Input { static bool IsActionPressed(StringName action, bool exactMatch = false); static bool IsActionJustPressed(StringName action, bool exactMatch = false);
  static bool IsActionJustReleased(StringName action, bool exactMatch = false); static float GetActionStrength(StringName action, bool exactMatch = false);
  static float GetAxis(StringName negativeAction, StringName positiveAction);
  static Vector2 GetVector(StringName negativeX, StringName positiveX, StringName negativeY, StringName positiveY, float deadzone = -1f);
  static bool IsKeyPressed(Key keycode); static bool IsMouseButtonPressed(MouseButton button); }
static class GD { static void Print(string what); static void Print(params object[] what); static void PrintErr(params object[] what);
  static void PushWarning(string message); static void PushError(string message); static float Randf() /* [0,1] */; static uint Randi();
  static int RandRange(int from, int to) /* INCLUSIVO */; static double RandRange(double from, double to); static void Randomize();
  static Resource Load(string path); static T Load<T>(string path); }
class RandomNumberGenerator { ulong Seed {get;set;} int RandiRange(int from, int to); float RandfRange(float from, float to); void Randomize(); }
struct Vector2 { float X; float Y;  /* CAMPOS PascalCase */ Vector2(float x, float y); static Vector2 Zero, One, Up, Down, Left, Right {get;}
  float Length(); float LengthSquared(); Vector2 Normalized(); float DistanceTo(Vector2 to); Vector2 DirectionTo(Vector2 to);
  Vector2 Lerp(Vector2 to, float weight); Vector2 MoveToward(Vector2 to, float delta); float Angle(); Vector2 Rotated(float angle);
  float Dot(Vector2 with); Vector2 LimitLength(float length = 1f); Vector2 Slide(Vector2 normal); Vector2 Bounce(Vector2 normal); }
struct Vector2I { int X; int Y; Vector2I(int x, int y); }
static class Mathf { const float Pi = 3.1415927f; const float Tau = 6.2831855f; static float Clamp(float value, float min, float max); /* + int, double */
  static float Lerp(float from, float to, float weight); static float MoveToward(float from, float to, float delta); static float DegToRad(float deg);
  static int PosMod(int a, int b) /* resultado em [0,b) */; static int Wrap(int value, int min, int max); static float Round(float s) /* metade → par */;
  static int RoundToInt(float s); static int FloorToInt(float s); static int Sign(float s); static bool IsEqualApprox(float a, float b); }
sealed class SignalAttribute : Attribute { SignalAttribute(); }  sealed class ExportAttribute : Attribute { ExportAttribute(PropertyHint hint = 0, string hintString = ""); }
// + ExportGroupAttribute(string name, string prefix = ""), ExportSubgroupAttribute, ExportCategoryAttribute, GlobalClassAttribute
}
```
Classes geradas pelo source generator (exigem `partial`):
- `SignalName.<Sinal>`, `PropertyName.<Prop>` e `MethodName.<Metodo>` (tipo `StringName`) em cada classe.
- Um evento C# por sinal: `delegate void FooEventHandler(...)` gera o evento `Foo`.

### 2.4 MonoGame 3.8.5.1 (dump por reflexão de `MonoGame.Framework.DesktopGL 3.8.5.1`)

Fontes: https://www.nuget.org/packages/MonoGame.Framework.DesktopGL/3.8.5.1 · https://docs.monogame.net/api/

```csharp
namespace Microsoft.Xna.Framework {
class Game : IDisposable { Game(); ContentManager Content {get;set;} GraphicsDevice GraphicsDevice {get;} GameWindow Window {get;}
  bool IsMouseVisible {get;set;} bool IsFixedTimeStep {get;set;} /* true */ TimeSpan TargetElapsedTime {get;set;} /* 166667 ticks = 1/60 s */
  void Run(); void Exit(); protected virtual void Initialize(); protected virtual void LoadContent(); protected virtual void UnloadContent();
  protected virtual void Update(GameTime gameTime); protected virtual void Draw(GameTime gameTime); }
class GraphicsDeviceManager { GraphicsDeviceManager(Game game); int PreferredBackBufferWidth {get;set;} int PreferredBackBufferHeight {get;set;}
  bool IsFullScreen {get;set;} bool SynchronizeWithVerticalRetrace {get;set;} void ApplyChanges(); void ToggleFullScreen(); }
class GameTime { TimeSpan TotalGameTime {get;set;} TimeSpan ElapsedGameTime {get;set;} bool IsRunningSlowly {get;set;} }
struct Vector2 { float X; float Y; Vector2(float x, float y); Vector2(float value); static Vector2 Zero, One, UnitX, UnitY {get;}
  float Length(); float LengthSquared(); void Normalize(); static Vector2 Normalize(Vector2 value); static float Distance(Vector2 value1, Vector2 value2);
  static float DistanceSquared(Vector2 value1, Vector2 value2); static Vector2 Lerp(Vector2 value1, Vector2 value2, float amount);
  static Vector2 Clamp(Vector2 value1, Vector2 min, Vector2 max); static float Dot(Vector2 value1, Vector2 value2); static Vector2 Reflect(Vector2 vector, Vector2 normal);
  /* ToString() => "{X:1,5 Y:2}" — usa a CULTURA ATUAL */ }
struct Rectangle { int X; int Y; int Width; int Height; Rectangle(int x, int y, int width, int height); Rectangle(Point location, Point size);
  int Left, Right /* X+Width */, Top, Bottom /* Y+Height */ {get;} Point Center {get;} Point Location {get;set;} static Rectangle Empty {get;}
  bool Intersects(Rectangle value) /* estrito: value.Left < Right && Left < value.Right && value.Top < Bottom && Top < value.Bottom */;
  bool Contains(int x, int y) /* X <= x < X+Width */; bool Contains(Point value); bool Contains(Vector2 value); bool Contains(Rectangle value);
  static Rectangle Intersect(Rectangle value1, Rectangle value2); static Rectangle Union(Rectangle value1, Rectangle value2);
  void Offset(int offsetX, int offsetY); void Inflate(int horizontalAmount, int verticalAmount); }
struct Point { int X; int Y; Point(int x, int y); }  struct Color { static Color White, Black, Red, CornflowerBlue … {get;} Color(int r, int g, int b); Color(float r, float g, float b, float alpha); }
static class MathHelper { const float Pi, PiOver2, TwoPi; static float Clamp(float value, float min, float max); static int Clamp(int value, int min, int max);
  static float Lerp(float value1, float value2, float amount); static float ToRadians(float degrees); } }
namespace Microsoft.Xna.Framework.Graphics {
class SpriteBatch : GraphicsResource { SpriteBatch(GraphicsDevice graphicsDevice);
  void Begin(SpriteSortMode sortMode = 0, BlendState blendState = null, SamplerState samplerState = null, DepthStencilState depthStencilState = null,
             RasterizerState rasterizerState = null, Effect effect = null, Matrix? transformMatrix = null); void End();
  void Draw(Texture2D texture, Vector2 position, Color color); void Draw(Texture2D texture, Rectangle destinationRectangle, Color color);
  void Draw(Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color);
  void Draw(Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, float scale, SpriteEffects effects, float layerDepth);
  void DrawString(SpriteFont spriteFont, string text, Vector2 position, Color color); }
class Texture2D : Texture { int Width {get;} int Height {get;} Rectangle Bounds {get;} Texture2D(GraphicsDevice graphicsDevice, int width, int height); void SetData<T>(T[] data) where T : struct; }
class GraphicsDevice { Viewport Viewport {get;set;} void Clear(Color color); }  class SpriteFont { Vector2 MeasureString(string text); } }
namespace Microsoft.Xna.Framework.Input {
static class Keyboard { static KeyboardState GetState(); }  struct KeyboardState { bool IsKeyDown(Keys key); bool IsKeyUp(Keys key); Keys[] GetPressedKeys(); }
static class Mouse { static MouseState GetState(); }  struct MouseState { int X {get;} int Y {get;} Point Position {get;} ButtonState LeftButton {get;} int ScrollWheelValue {get;} }
static class GamePad { static GamePadState GetState(PlayerIndex playerIndex); static GamePadState GetState(int index); }  enum ButtonState { Released, Pressed } }
namespace Microsoft.Xna.Framework.Content { class ContentManager { string RootDirectory {get;set;} virtual T Load<T>(string assetName); } }
```

### 2.5 BCL do .NET usada em lógica de jogo: disponibilidade

Conferido no Microsoft Learn.

| API | Unity 6 (netstandard2.1) | Godot 4.7 (net8) / MonoGame (net9) / console |
|---|---|---|
| `Math.Clamp`, `MathF`, `HashCode`, tuplas, `switch` expression, padrões `is 2 or 3` | ✔ | ✔ |
| `PriorityQueue<TElement,TPriority>` (`Enqueue`, `Dequeue`, `TryDequeue(out e, out p)`, `Peek`, `Count`; `Remove` só no **.NET 9**) | ✘ (não compila: CS0246) | ✔ (.NET 6+) |
| `Random.Shared` | ✘ (CS0117) | ✔ (.NET 6+) |
| `Random.Shuffle<T>(T[])`, `GetItems<T>(T[], int)` | ✘ | ✔ (.NET 8+) |
| `record` / `init` | ✘ (CS0518 `IsExternalInit`, a menos que você declare o tipo) | ✔ |
| `record struct`, namespace de arquivo, `[1, 2, 3]` | ✘ (CS8773: exige C# 10/12) | ✔ |

---

## 3. Exemplos de código de referência

Todos foram compilados. Os arquivos completos estão em `raw/validate/`.

### 3.1 C# puro: lógica de jogo (compatível com C# 9 e, portanto, com Unity)

```csharp
public readonly struct Caixa                         // AABB
{
    public readonly float X, Y, L, A;
    public Caixa(float x, float y, float l, float a) { X = x; Y = y; L = l; A = a; }
    public bool Colide(Caixa o) =>                   // encostar NÃO colide
        X < o.X + o.L && X + L > o.X && Y < o.Y + o.A && Y + A > o.Y;
}

public static int ModPositivo(int a, int n) => ((a % n) + n) % n;   // cobrinha atravessando a borda

public static int Distancia(char[,] mapa, (int l, int c) inicio, (int l, int c) fim)   // BFS
{
    var fila = new Queue<(int l, int c)>();
    var dist = new Dictionary<(int l, int c), int> { [inicio] = 0 };
    fila.Enqueue(inicio);
    while (fila.Count > 0)
    {
        var atual = fila.Dequeue();
        if (atual == fim) return dist[atual];
        foreach (var (dx, dy) in Direcoes4)          // (1,0) (-1,0) (0,1) (0,-1)
        {
            var viz = (l: atual.l + dy, c: atual.c + dx);
            if (!Dentro(mapa, viz.l, viz.c) || mapa[viz.l, viz.c] == '#') continue;
            if (dist.ContainsKey(viz)) continue;
            dist[viz] = dist[atual] + 1;
            fila.Enqueue(viz);
        }
    }
    return -1;
}

public static int[] MoverEsquerda(int[] linha, ref int pontos)       // 2048
{
    var valores = linha.Where(v => v != 0).ToList();
    var saida = new List<int>();
    for (int i = 0; i < valores.Count; i++)
    {
        if (i + 1 < valores.Count && valores[i] == valores[i + 1])
        { saida.Add(valores[i] * 2); pontos += valores[i] * 2; i++; }   // funde uma vez só
        else saida.Add(valores[i]);
    }
    while (saida.Count < linha.Length) saida.Add(0);
    return saida.ToArray();
}

public static string Escolher(IReadOnlyList<(string item, int peso)> tabela, int rolagem)  // loot
{
    foreach (var (item, peso) in tabela)
    {
        if (rolagem < peso) return item;
        rolagem -= peso;
    }
    throw new ArgumentOutOfRangeException(nameof(rolagem));
}
// Sortear: total = soma dos pesos; Escolher(tabela, rng.Next(total));   // Next(max) => 0..max-1

public static void Embaralhar<T>(T[] itens, Random rng)              // Fisher–Yates
{
    for (int i = itens.Length - 1; i > 0; i--)
    {
        int j = rng.Next(i + 1);                                        // 0..i INCLUSIVO
        (itens[i], itens[j]) = (itens[j], itens[i]);
    }
}

public static int Dano(int ataque, int defesa, bool critico) =>      // combate
    Math.Max(1, (ataque - defesa) * (critico ? 2 : 1));

public static EstadoIA Proximo(EstadoIA atual, float distancia, int vida) => atual switch   // IA
{
    _ when vida < 20                          => EstadoIA.Fugindo,
    EstadoIA.Patrulha when distancia < 10f    => EstadoIA.Perseguindo,
    EstadoIA.Perseguindo when distancia < 2f  => EstadoIA.Atacando,
    EstadoIA.Perseguindo when distancia > 15f => EstadoIA.Patrulha,
    EstadoIA.Atacando when distancia >= 2f    => EstadoIA.Perseguindo,
    _                                         => atual
};

// Game of Life com Double Buffer (trecho de Passo())
_proximo[y, x] = _atual[y, x] ? viz is 2 or 3 : viz == 3;
(_atual, _proximo) = (_proximo, _atual);                              // troca os buffers no fim
```

### 3.2 C# moderno (.NET 6+): A\* com `PriorityQueue`. Não serve para Unity.

```csharp
public readonly record struct Ponto(int X, int Y)
{
    public static readonly Ponto[] Direcoes = [new(1, 0), new(-1, 0), new(0, 1), new(0, -1)];
    public Ponto Somar(Ponto o) => new(X + o.X, Y + o.Y);
    public static int Manhattan(Ponto a, Ponto b) => Math.Abs(a.X - b.X) + Math.Abs(a.Y - b.Y);
}

public static List<Ponto>? AEstrela(bool[,] parede, Ponto inicio, Ponto fim)
{
    var fronteira = new PriorityQueue<Ponto, int>();
    var veioDe = new Dictionary<Ponto, Ponto>();
    var custo = new Dictionary<Ponto, int> { [inicio] = 0 };
    fronteira.Enqueue(inicio, 0);
    while (fronteira.TryDequeue(out var atual, out _))
    {
        if (atual == fim) break;
        foreach (var d in Ponto.Direcoes)
        {
            var prox = atual.Somar(d);
            if (prox.X < 0 || prox.Y < 0 || prox.X >= parede.GetLength(0) || prox.Y >= parede.GetLength(1)) continue;
            if (parede[prox.X, prox.Y]) continue;
            int novo = custo[atual] + 1;
            if (!custo.TryGetValue(prox, out int velho) || novo < velho)
            {
                custo[prox] = novo;
                veioDe[prox] = atual;
                fronteira.Enqueue(prox, novo + Ponto.Manhattan(prox, fim));   // sem decrease-key: enfileira de novo
            }
        }
    }
    if (!custo.ContainsKey(fim)) return null;
    var caminho = new List<Ponto>();
    for (var p = fim; p != inicio; p = veioDe[p]) caminho.Add(p);
    caminho.Add(inicio);
    caminho.Reverse();
    return caminho;
}
```

### 3.3 Padrões (Nystrom) em C#, compatíveis com Unity

```csharp
// Game Loop com passo fixo (tempo do quadro injetado => testável)
public double Quadro(double tempoDoQuadro)
{
    _acumulado += Math.Min(tempoDoQuadro, 0.25);   // trava contra a "espiral da morte"
    while (_acumulado >= Dt) { Atualizacoes++; _acumulado -= Dt; }   // Update(Dt), Dt = 1.0/60
    return _acumulado / Dt;                         // alfa para Render(alfa)
}

// Update Method: não mexa na lista durante a iteração
public void Atualizar(float dt)
{
    foreach (var e in _entidades) e.Atualizar(dt);
    _entidades.RemoveAll(e => e.Morta);
    _entidades.AddRange(_novas); _novas.Clear();
}

// Command com undo/redo
public interface IComando { void Executar(); void Desfazer(); }
public void Executar(IComando c) { c.Executar(); _desfazer.Push(c); _refazer.Clear(); }
public bool Desfazer() { if (_desfazer.Count == 0) return false; var c = _desfazer.Pop(); c.Desfazer(); _refazer.Push(c); return true; }

// Observer idiomático
public event Action<int>? Mudou;
Mudou?.Invoke(_valor);           // em C# puro ?. é o certo (não é UnityEngine.Object)

// Object Pool
public T Pegar() { if (_livres.Count > 0) return _livres.Pop(); Criados++; return _criar(); }
public void Devolver(T obj) { _resetar(obj); _livres.Push(obj); }   // reciclado não se limpa sozinho

// State com Entrar/Sair
public void Comando(string c)
{
    var proximo = Estado.Tratar(this, c);
    if (proximo == null) return;
    Estado.Sair(this); Estado = proximo; Estado.Entrar(this);
}

// Service Locator com Null Object
public static IAudio Audio { get; private set; } = new AudioNulo();
public static void Registrar(IAudio audio) => Audio = audio ?? new AudioNulo();
```
Também estão validados em `Padroes.cs`: Flyweight/Type Object (`Raca` compartilhada por vários `Monstro`), grade espacial (`Dictionary<(int,int), List<...>>` consultando 3×3 células), Dirty Flag e Event Queue.

### 3.4 Unity 6 (C# 9)

```csharp
using UnityEngine;

[RequireComponent(typeof(Rigidbody))]
public class Pulo : MonoBehaviour
{
    [Header("Movimento")]
    [SerializeField, Tooltip("Velocidade horizontal em m/s")] private float velocidade = 6f;
    [SerializeField] private float forcaPulo = 7f;
    private Rigidbody _rb;
    private bool _querPular;
    private float _h;

    private void Awake() => _rb = GetComponent<Rigidbody>();       // cache

    private void Update()                                           // ler input
    {
        _h = Input.GetAxisRaw("Horizontal");
        if (Input.GetButtonDown("Jump")) _querPular = true;         // "Down" dura 1 frame: guarde
    }

    private void FixedUpdate()                                      // aplicar física
    {
        Vector3 v = _rb.linearVelocity;
        v.x = _h * velocidade;
        _rb.linearVelocity = v;
        if (_querPular) { _rb.AddForce(Vector3.up * forcaPulo, ForceMode.Impulse); _querPular = false; }
    }
}

public class Moeda : MonoBehaviour
{
    [SerializeField] private int valor = 10;
    private void OnTriggerEnter(Collider other)
    {
        if (!other.CompareTag("Player")) return;
        if (other.TryGetComponent(out Carteira carteira)) carteira.Somar(valor);
        Destroy(gameObject);
    }
}

public class Mira : MonoBehaviour
{
    [SerializeField] private float alcance = 50f;
    [SerializeField] private LayerMask camadasAtingiveis;
    private void Update()
    {
        if (!Input.GetMouseButtonDown(0)) return;
        Ray raio = Camera.main.ScreenPointToRay(Input.mousePosition);
        if (Physics.Raycast(raio, out RaycastHit hit, alcance, camadasAtingiveis))
            Debug.Log($"Acertou {hit.collider.name} a {hit.distance:F1} m");
    }
}

// Input System (projetos novos)
private InputAction _mover;                                          // using UnityEngine.InputSystem;
private void Start() => _mover = InputSystem.actions.FindAction("Move");
private void Update()
{
    Vector2 entrada = _mover.ReadValue<Vector2>();
    transform.Translate(new Vector3(entrada.x, 0f, entrada.y) * velocidade * Time.deltaTime, Space.World);
}

// Corrotina x Awaitable
private static readonly WaitForSeconds Meio = new WaitForSeconds(0.1f);   // cache
private IEnumerator PiscarVezes(int vezes)
{
    for (int i = 0; i < vezes; i++) { rend.enabled = false; yield return Meio; rend.enabled = true; yield return Meio; }
}
// iniciar: _rotina = StartCoroutine(PiscarVezes(3));   parar: StopCoroutine(_rotina);

private async void Start()
{
    try
    {
        for (int i = 0; i < 3; i++)
        {
            rend.enabled = !rend.enabled;
            await Awaitable.WaitForSecondsAsync(0.1f, destroyCancellationToken);
        }
    }
    catch (System.OperationCanceledException) { }   // destruído no meio da espera
}

// ScriptableObject + Observer + Inspector
[CreateAssetMenu(fileName = "NovaArma", menuName = "Jogo/Arma")]
public class DadosArma : ScriptableObject
{
    [SerializeField] private string nome = "Espada";
    [SerializeField, Min(0)] private int dano = 10;
    public string Nome => nome;
    public int Dano => dano;
}

public class Vida : MonoBehaviour
{
    [SerializeField] private int maxima = 100;
    [SerializeField] private UnityEvent aoMorrer;                 // using UnityEngine.Events;
    public event System.Action<int, int> Mudou;
    [field: SerializeField] public int Atual { get; private set; }
    private void Awake() => Atual = maxima;
    public void Dano(int qtd)
    {
        if (Atual <= 0) return;
        Atual = Mathf.Clamp(Atual - qtd, 0, maxima);
        Mudou?.Invoke(Atual, maxima);
        if (Atual == 0) aoMorrer.Invoke();
    }
}
// Assinante: OnEnable => vida.Mudou += Atualizar;   OnDisable => vida.Mudou -= Atualizar;

// Pool oficial
_pool = new ObjectPool<Projetil>(                                   // using UnityEngine.Pool;
    createFunc: () => { var p = Instantiate(prefab); p.Pool = _pool; return p; },
    actionOnGet: p => p.gameObject.SetActive(true),
    actionOnRelease: p => p.gameObject.SetActive(false),
    actionOnDestroy: p => Destroy(p.gameObject),
    collectionCheck: true, defaultCapacity: 20, maxSize: 100);
// no projétil: if (_vida <= 0f) Pool.Release(this);   (resetar estado em OnEnable)

// Singleton seguro sem domain reload
public static Audio Instancia { get; private set; }
[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]
private static void Resetar() => Instancia = null;
private void Awake()
{
    if (Instancia != null && Instancia != this) { Destroy(gameObject); return; }
    Instancia = this;
    DontDestroyOnLoad(gameObject);
}

// Animator com hash + PlayerPrefs + recarregar a cena
private static readonly int Ataque = Animator.StringToHash("Ataque");
_anim.SetTrigger(Ataque); _audio.PlayOneShot(somEspada);
if (Pontos > PlayerPrefs.GetInt("recorde", 0)) { PlayerPrefs.SetInt("recorde", Pontos); PlayerPrefs.Save(); }
SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);    // using UnityEngine.SceneManagement;
```

### 3.5 Godot 4.7 (C# 12)

```csharp
using Godot;

public partial class JogadorPlataforma : CharacterBody2D
{
    [Export] public float Velocidade { get; set; } = 200f;
    [Export] public float ForcaPulo { get; set; } = -400f;      // Y cresce para baixo

    public override void _PhysicsProcess(double delta)
    {
        Vector2 v = Velocity;                                    // copia o struct
        if (!IsOnFloor()) v += GetGravity() * (float)delta;      // delta é double
        if (Input.IsActionJustPressed("ui_accept") && IsOnFloor()) v.Y = ForcaPulo;
        v.X = Input.GetAxis("ui_left", "ui_right") * Velocidade;
        Velocity = v;                                            // devolve
        MoveAndSlide();
    }
}

public partial class Vida : Node
{
    [Signal] public delegate void MudouEventHandler(int atual, int maxima);
    [Signal] public delegate void MorreuEventHandler();
    [Export] public int Maxima { get; set; } = 100;
    public int Atual { get; private set; }
    public override void _Ready() => Atual = Maxima;
    public void Dano(int qtd)
    {
        if (Atual <= 0) return;
        Atual = Mathf.Clamp(Atual - qtd, 0, Maxima);
        EmitSignal(SignalName.Mudou, Atual, Maxima);
        if (Atual == 0) EmitSignal(SignalName.Morreu);
    }
}

public partial class Hud : Label
{
    [Export] public Vida Alvo { get; set; }
    public override void _EnterTree() => Alvo.Mudou += AoMudar;
    public override void _ExitTree() => Alvo.Mudou -= AoMudar;   // sinal próprio: desconecte
    private void AoMudar(int atual, int maxima) => Text = $"{atual}/{maxima}";
}

// instanciar / remover / esperar
var inimigo = CenaInimigo.Instantiate<Node2D>(); inimigo.Position = posicao; AddChild(inimigo);
filho.QueueFree();
await ToSignal(GetTree().CreateTimer(1.0), SceneTreeTimer.SignalName.Timeout);
Position = Position with { X = x };                              // C# 10+: alterar só o X
int d6 = GD.RandRange(1, 6);                                     // 1..6 (inclusivo)
```

### 3.6 MonoGame 3.8.5 (C# 13)

```csharp
public Game1()
{
    _graphics = new GraphicsDeviceManager(this);
    Content.RootDirectory = "Content";
    IsMouseVisible = true;
}

protected override void Initialize()
{
    _graphics.PreferredBackBufferWidth = 800; _graphics.PreferredBackBufferHeight = 480; _graphics.ApplyChanges();
    base.Initialize();                                                // chama LoadContent no final
    _posicao = new Vector2(400 - _bola.Width / 2f, 240 - _bola.Height / 2f);   // só DEPOIS do base
}

protected override void LoadContent()
{
    _spriteBatch = new SpriteBatch(GraphicsDevice);
    _bola = Content.Load<Texture2D>("bola");
}

protected override void Update(GameTime gameTime)
{
    _teclado.Atualizar();
    if (_teclado.Apertou(Keys.Escape)) Exit();
    float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;
    _posicao += _velocidade * dt;
    base.Update(gameTime);
}

protected override void Draw(GameTime gameTime)
{
    GraphicsDevice.Clear(Color.CornflowerBlue);
    _spriteBatch.Begin(samplerState: SamplerState.PointClamp);
    _spriteBatch.Draw(_bola, _posicao, Color.White);
    _spriteBatch.DrawString(_fonte, $"Pontos: {_pontos}", new Vector2(10, 10), Color.White);
    _spriteBatch.End();
    base.Draw(gameTime);
}

public class Teclado                                                  // borda de subida
{
    public KeyboardState Anterior { get; private set; }
    public KeyboardState Atual { get; private set; }
    public void Atualizar() { Anterior = Atual; Atual = Keyboard.GetState(); }
    public bool Apertou(Keys k) => Atual.IsKeyDown(k) && Anterior.IsKeyUp(k);
}
```

---

## 4. Armadilhas e boas práticas que o curso deve ensinar

**Transversais (todas as engines)**
- **Multiplicar por delta time** tudo que é "por segundo". Usar `(float)delta` no Godot, `(float)gameTime.ElapsedGameTime.TotalSeconds` no MonoGame e `Time.deltaTime` na Unity.
- **Structs devolvidos por propriedade são cópias**, e alterar um campo dá CS1612. Afeta `transform.position.x`, `Position.X` e `Velocity.Y` no Godot, e `lista[0].Vida` com `List<struct>`. Copie, altere e reatribua (ou use `with` no C# 10+).
- **Divisão inteira**: `7 / 10` dá 0. Converter antes: `(float)acertos / tiros`.
- **Módulo negativo**: `-1 % 10` dá -1. Use `((a % n) + n) % n` ou `Mathf.PosMod` no Godot.
- **Limites do aleatório** diferem por engine:
  - `System.Random.Next(1, 7)` → 1..6 (máximo exclusivo);
  - `UnityEngine.Random.Range(1, 7)` → 1..6 (máximo exclusivo no `int`), mas `Range(0f, 1f)` **inclui** o 1;
  - `GD.RandRange(1, 6)` → 1..6 (**inclusivo**).
- **Arredondamento**: `Math.Round(2.5)` dá 2. O arredondamento bancário também vale para `Mathf.RoundToInt` na Unity e `Mathf.Round` no Godot. Para "arredondar para cima no meio", use `MidpointRounding.AwayFromZero`.
- **`float` e igualdade**: nunca use `==`. Use `Mathf.Approximately` (Unity), `Mathf.IsEqualApprox` (Godot) ou tolerância. O `==` do `Vector3` da Unity já é aproximado, mas o `Equals` é exato.
- **Cultura pt-BR**:
  - `1.5.ToString()` sai "1,5".
  - `Vector2.ToString()` do MonoGame sai `{X:1,5 Y:2}`.
  - O `Vector3` da Unity usa invariante, `(1.50, 2.00, 0.00)`.
  - Para salvar ou transmitir números, use `CultureInfo.InvariantCulture`.
- **Não alterar coleção dentro do `foreach`**, que lança `InvalidOperationException: Collection was modified`. Adie as mudanças (Update Method) ou itere de trás para frente com `for`.
- **Eventos**: cada `+=` precisa de um `-=`. Assinar duas vezes chama duas vezes (verificado com `event Action`). O "ouvinte esquecido" vaza memória mesmo com GC.
- **Seed fixa não é portável** entre versões do .NET, segundo a doc de `Random`. Não use sequências "sorteadas" como gabarito de exercício.

**Unity 6**
- **Mensagens são por nome**:
  - `void update()` minúsculo compila e **nunca roda**.
  - `public override void Update()` dá CS0115.
  - `OnTriggerEnter2D(Collider other)` é ignorada, com o log "This message parameter has to be of type: Collider2D".
- **API do Unity 6**:
  - `linearVelocity` (e `velocity` dá CS0618 com `TreatWarningsAsErrors`).
  - `FindAnyObjectByType`.
  - Não usar `GameObject.Find` nem `Camera.main` dentro do `Update` sem cache.
- **Onde fica cada código**:
  - Ler input no `Update` e aplicar física no `FixedUpdate`. `GetButtonDown` no `FixedUpdate` **perde toques**, porque dura um frame e o FixedUpdate pode rodar 0 vezes naquele frame.
  - Câmera que segue fica no `LateUpdate`.
- **Inicialização**: o próprio componente se prepara no `Awake` e fala com outros no `Start`, depois que todos os `Awake` rodaram. A ordem entre objetos não é garantida; use *Script Execution Order* / `[DefaultExecutionOrder]` só quando precisar.
- **Null da Unity**:
  - Objeto destruído `== null` é `true`, mas `ReferenceEquals` dá `false`.
  - **`?.` e `??` não funcionam** com `UnityEngine.Object`.
  - Depois de `Destroy(obj)`, o objeto só some **no fim do Update atual**.
- **Colisão não dispara?** Confira:
  - as duas partes têm Collider;
  - pelo menos um Rigidbody (para `OnCollision*`, não cinemático);
  - no caso de trigger, um marcado como `isTrigger`;
  - 2D e 3D não se misturam;
  - a matriz de camadas.
- **Máscaras de camada**:
  - `LayerMask.GetMask("Inimigo")` é máscara.
  - `LayerMask.NameToLayer` é índice e precisa de `1 << indice`.
  - Passar o índice 8 como máscara filtra a **camada 3** (bit 3).
- **Corrotinas**:
  - `StartCoroutine(Metodo())`, com parênteses.
  - `StopCoroutine` com o mesmo tipo de argumento usado para iniciar.
  - Param com `SetActive(false)` ou `Destroy`, mas **não** com `enabled = false`.
  - Guarde o `WaitForSeconds` em cache.
  - `WaitForSeconds` congela com `timeScale = 0`; use `WaitForSecondsRealtime` para UI de pausa.
- **Awaitable**:
  - Nunca faça `await` duas vezes na mesma instância, porque ela vem de um pool.
  - Use `async void` só em "pontas" (como `Start`), com `try/catch (OperationCanceledException)`.
  - Passe `destroyCancellationToken`.
  - Para `WhenAll`, embrulhe em `Task` (há uma extensão `AsTask` no manual).
- **Serialização**:
  - Só campos `public` ou `[SerializeField]`, não `static`, `const` nem `readonly`.
  - `Dictionary` e arrays multidimensionais **não serializam** no 6.3. O 6.6 adicionou serialização nativa de `Dictionary`, mas o curso deve mirar o 6.3 LTS: use `List` de pares `[Serializable]` ou `ISerializationCallbackReceiver`.
  - Classes próprias precisam de `[Serializable]`.
  - Records não servem em tipos serializados.
  - `[field: SerializeField]` para propriedades automáticas.
  - Renomear campo sem `[FormerlySerializedAs("antigo")]` **perde os dados** do Inspector.
- **C# 9**: `init`, `record` (sem declarar `IsExternalInit`), namespace de arquivo e `[1,2,3]` não compilam (§6). Anotações `string?` sem `#nullable enable` geram o warning CS8632.
- **`using System;` junto com `using UnityEngine;`** deixa `Random` ambíguo (CS0104). Use `UnityEngine.Random.Range` ou um alias.
- **Estáticos e Singleton**: sem domain reload, `static` persiste entre execuções do Play. Resetar com `RuntimeInitializeOnLoadMethod(SubsystemRegistration)`. Prefira referências pelo Inspector e ScriptableObjects a Singletons.
- **PlayerPrefs**: só para preferências simples. O dado **não é criptografado**. Não chamar `Save()` todo frame.
- **Input**: em projeto novo o *Active Input Handling* é o Input System. Nesse caso, o código com `Input.GetAxis` lança `InvalidOperationException`; ensine as duas APIs e a opção "Both" só como transição.
- **Objeto reciclado de pool**: resete o estado em `OnEnable` ou no `actionOnGet`.

**Godot 4 C#**
- **Classe e arquivo**:
  - `partial` é obrigatório (GD0001).
  - Nome da classe igual ao nome do arquivo (senão: "Cannot find class XXX for script res://XXX.cs").
  - Recompile para ver novos exports e sinais no editor.
- **Assinaturas**:
  - `_Process(double delta)`: com `float` dá CS0115.
  - `Vector2 * double` não compila (CS0019); converta com `(float)delta`.
  - Sem `override` no `_Ready` o compilador avisa que o método **esconde** o da base (CS0114; com warnings tratados como erro, não compila). Sempre use `public override`.
- **Sinais**:
  - O `delegate` termina em `EventHandler` (GD0201).
  - Emita com `EmitSignal(SignalName.X, args)`; `X?.Invoke()` dá CS0079.
  - Há dois casos que **não desconectam sozinhos** quando o receptor é liberado: sinal próprio assinado com `+=`, e qualquer lambda que captura variável. Faça `-=` no `_ExitTree`, senão vem `ObjectDisposedException`. Alternativa: `Connect(...)`, que desconecta sinal próprio automaticamente.
- **Métodos por string**: `CallDeferred("AddChild")` não funciona, porque espera o nome em snake_case. Use `MethodName.AddChild` e `PropertyName.X`.
- **Mudanças de física dentro de um callback de física** devem ser adiadas: `SetDeferred(CollisionShape2D.PropertyName.Disabled, true)`.
- **Ações de input** precisam existir no Input Map (`ui_*` já vêm prontas), senão aparece `The InputMap action "jump" doesn't exist.`
- **Interop**: ler e gravar `Position` numa variável local em laços evita chamadas nativas repetidas. Passar `string` para `StringName`/`NodePath` tem custo de marshalling.
- **Web**: projeto C# **não exporta para Web** no Godot 4. Para demo no navegador use GDScript, ou Godot 3.

**MonoGame**
- **Ordem de inicialização**: sempre chamar `base.Initialize()`. Código que usa conteúdo vai **depois** dele, porque o `LoadContent` roda no fim do `base.Initialize()`; usar a textura antes dá `NullReferenceException`.
- **Entrada**: "apertou" precisa do estado anterior. `IsKeyDown` sozinho dispara todo frame.
- **Colisão**: `Intersects` não conta bordas encostadas e `Contains` exclui a borda direita e a de baixo. Considere isso nos testes de "prever a saída".
- **Tempo**: com passo fixo (padrão), `ElapsedGameTime` é sempre 1/60 s. Se desligar `IsFixedTimeStep`, o delta varia e **todo** movimento precisa de `dt`.

**Padrões**
- Padrão não é *checklist*. Nystrom abre cada capítulo com "quando usar" e "tenha em mente".
- Singleton, na prática, é uma variável global (Nystrom: "It's a global variable"). Prefira injeção de dependência, Service Locator com Null Object ou referências pelo Inspector.
- Pool exige reset explícito e tem capacidade fixa.
- Observer exige cancelar a inscrição.
- Event Queue pode entrar em laço de realimentação e deixa o estado do mundo mudar entre o envio e o processamento.

---

## 5. Ideias de exercícios

### 5.1 Digitação curta (1 a 8 linhas)

Todas as linhas vêm de código validado em §3 ou em `raw/validate`.

**C# puro**
1. `int d6 = rng.Next(1, 7);`
2. `int x = ((cabeca.X + dx) % largura + largura) % largura;`
3. `bool colide = a.X < b.X + b.L && a.X + a.L > b.X && a.Y < b.Y + b.A && a.Y + a.A > b.Y;`
4. `(cartas[i], cartas[j]) = (cartas[j], cartas[i]);`
5. `var fila = new Queue<(int l, int c)>(); fila.Enqueue(inicio);`
6. `novo[y, x] = vivo ? viz is 2 or 3 : viz == 3;`
7. `int dano = Math.Max(1, (ataque - defesa) * (critico ? 2 : 1));`
8. `if (!_itens.TryGetValue(item, out int atual) || atual < qtd) return false;`
9. `foreach (var (item, peso) in tabela) { if (rolagem < peso) return item; rolagem -= peso; }`
10. `fronteira.Enqueue(prox, novo + Ponto.Manhattan(prox, fim));` (.NET 6+)
11. `_restante = Math.Max(0f, _restante - dt);`
12. `[Flags] enum Status { Nenhum = 0, Envenenado = 1, Congelado = 2, Queimando = 4 }`
13. `for (var p = fim; p != inicio; p = veioDe[p]) caminho.Add(p);`

**Padrões**
14. `public interface IComando { void Executar(); void Desfazer(); }`
15. `c.Executar(); _desfazer.Push(c); _refazer.Clear();`
16. `public event Action<int> VidaMudou;` + `VidaMudou?.Invoke(vida);`
17. `if (_livres.Count > 0) return _livres.Pop();`
18. `(_atual, _proximo) = (_proximo, _atual);`
19. `Estado.Sair(this); Estado = proximo; Estado.Entrar(this);`

**Unity**
20. `[SerializeField, Range(0f, 360f)] private float grausPorSegundo = 90f;`
21. `transform.Rotate(0f, grausPorSegundo * Time.deltaTime, 0f);`
22. `private void Awake() => _rb = GetComponent<Rigidbody>();`
23. `_rb.AddForce(Vector3.up * forcaPulo, ForceMode.Impulse);`
24. `Vector3 v = _rb.linearVelocity; v.x = _h * velocidade; _rb.linearVelocity = v;`
25. `if (other.CompareTag("Player")) Destroy(gameObject);`
26. `GameObject inimigo = Instantiate(prefabInimigo, pos, Quaternion.identity); Destroy(inimigo, 10f);`
27. `if (Physics.Raycast(raio, out RaycastHit hit, alcance, camadasAtingiveis))`
28. `yield return new WaitForSeconds(0.5f);`
29. `_rotina = StartCoroutine(PiscarVezes(3));`
30. `await Awaitable.WaitForSecondsAsync(0.1f, destroyCancellationToken);`
31. `[CreateAssetMenu(fileName = "NovaArma", menuName = "Jogo/Arma")]`
32. `private static readonly int Ataque = Animator.StringToHash("Ataque");`
33. `private void OnEnable() => vida.Mudou += Atualizar;` / `private void OnDisable() => vida.Mudou -= Atualizar;`
34. `SceneManager.LoadScene(SceneManager.GetActiveScene().buildIndex);`
35. `PlayerPrefs.SetInt("recorde", pontos);`
36. `Vector2 entrada = _mover.ReadValue<Vector2>();`
37. `if (Keyboard.current.spaceKey.wasPressedThisFrame) Pular();`
38. `[field: SerializeField] public int Atual { get; private set; }`
39. `[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.SubsystemRegistration)]`
40. `transform.position = Vector3.SmoothDamp(transform.position, desejado, ref _velocidade, suavizacao);`

**Godot**
41. `public partial class Jogador : CharacterBody2D`
42. `[Export] public float Velocidade { get; set; } = 300f;`
43. `public override void _PhysicsProcess(double delta)`
44. `Velocity = Input.GetVector("ui_left", "ui_right", "ui_up", "ui_down") * Velocidade;`
45. `[Signal] public delegate void MorreuEventHandler();`
46. `EmitSignal(SignalName.Morreu);`
47. `var sprite = GetNode<AnimatedSprite2D>("AnimatedSprite2D");`
48. `await ToSignal(GetTree().CreateTimer(1.0), SceneTreeTimer.SignalName.Timeout);`
49. `var inimigo = CenaInimigo.Instantiate<Node2D>(); AddChild(inimigo);`

**MonoGame**
50. `_spriteBatch = new SpriteBatch(GraphicsDevice);`
51. `_bola = Content.Load<Texture2D>("bola");`
52. `float dt = (float)gameTime.ElapsedGameTime.TotalSeconds;`
53. `_spriteBatch.Begin(); _spriteBatch.Draw(_bola, _posicao, Color.White); _spriteBatch.End();`
54. `public bool Apertou(Keys k) => Atual.IsKeyDown(k) && Anterior.IsKeyUp(k);`
55. `if (jogador.Intersects(inimigo)) vidas--;`

**"Mão na Massa" (projetos maiores com o mesmo material)**
- Cobrinha em console.
- 2048 com a linha e depois a grade inteira (rotacionar a grade).
- Campo minado com *flood fill*.
- Batalha por turnos com loot.
- Pong em MonoGame.
- Plataforma 2D em Godot.
- Coletor de moedas em Unity com pool de projéteis.

### 5.2 Desafios de lógica (não são de digitação)

Os gabaritos marcados **(exec)** foram executados. Os marcados **(fonte)** vêm do código-fonte ou da documentação oficial.

**Prever a saída**
1. `int acertos = 7, tiros = 10; float taxa = acertos / tiros; Console.WriteLine(taxa);` → **0** (exec). E `(float)acertos / tiros` → 0.7.
2. `Console.WriteLine(-1 % 10);` → **-1** (exec). E `((-1 % 10) + 10) % 10` → **9**.
3. `Math.Round(2.5)` e `Math.Round(3.5)` → **2** e **4** (exec, arredondamento bancário). `Math.Round(2.5, MidpointRounding.AwayFromZero)` → 3.
4. `(int)-2.9f` → **-2**; `Math.Floor(-2.5)` → **-3** (exec).
5. `int p = 5; int a = p++ + 10; int b = ++p + 10;` → a=**15**, b=**17**, p=**7** (exec).
6. `[Flags]` com `var s = Envenenado | Queimando;` → `s` imprime **"Envenenado, Queimando"** e `(int)s` → **5**. Depois de `s &= ~Envenenado` → **"Queimando"** (exec).
7. 2048 (`MoverEsquerda`) (exec):
   - `[2,2,2,0]` → **[4,2,0,0]**, 4 pontos;
   - `[2,2,2,2]` → **[4,4,0,0]**, 8 pontos;
   - `[4,0,4,8]` → **[8,8,0,0]**;
   - `[8,8,16,16]` → **[16,32,0,0]**, 48 pontos.
8. Loot com pesos Comum 70 / Raro 25 / Épico 5 (exec):
   - rolagem 69 → Comum;
   - rolagem 70 → **Raro**;
   - rolagem 94 → Raro;
   - rolagem 95 → **Épico**.
9. `Dano(10, 12, critico: true)` → **1**, por causa do `Math.Max` (exec).
10. Combate (exec):
    - Herói: vida 30, ataque 12, defesa 3. Orc: vida 20, ataque 9, defesa 4.
    - Crítico no turno 3; o orc só revida se estiver vivo.
    - Resultado: **3 turnos**, vida final **18/0**.
11. `new Caixa(0,0,10,10).Colide(new Caixa(10,0,5,5))` → **False** (exec). Na MonoGame, `Rectangle(0,0,10,10).Intersects(Rectangle(10,0,10,10))` → **False** e `Contains(10,5)` → **False** (exec).
12. Blinker horizontal em (2,1),(2,2),(2,3) (exec): a célula do centro tem **2** vizinhos e a (1,2) tem **3**. Depois de 1 passo fica **vertical**.
13. Observer (exec): um `ouvinte` assinado **duas vezes** e cancelado uma vez; `Dano(3)`, `Dano(20)`, `Dano(5)` → chamadas = **3**, `Morreu` = 1.
14. Pool (exec): `Pegar, Pegar, Devolver(b1), Pegar, Pegar` → `Criados` = **3**. O 3º `Pegar` devolve **o mesmo objeto** `b1`.
15. Game loop com passo de 1/60 s e trava de 0,25 s (exec):
    - um quadro de 1,0 s → **15** updates;
    - 10 quadros de 8 ms → **4** updates.
16. Unity, com o objeto ativo e o script habilitado: `Debug.Log` em Awake, OnEnable e Start; depois `Destroy(gameObject)` → **Awake, OnEnable, Start … OnDisable, OnDestroy** (fonte).
17. Unity, com o script **desabilitado** no Inspector e o GameObject ativo → imprime só **"Awake"** (fonte: "Awake is called even if the script is a disabled component").
18. Unity (fonte):
    - `Random.Range(0, 3)` (int) pode dar **0, 1 ou 2**;
    - `Random.Range(0f, 3f)` pode dar exatamente **3.0**.
19. Unity (fonte):
    - `Mathf.RoundToInt(2.5f)` → **2**;
    - `Mathf.Sign(0f)` → **1**;
    - `Mathf.Lerp(0f, 10f, 1.5f)` → **10**;
    - `Mathf.LerpUnclamped(0f, 10f, 1.5f)` → **15**;
    - `Mathf.Clamp(10, 0, 5)` → **5**.
20. Unity: `Debug.Log(new Vector3(1f, 2.5f, 0f));` → **(1.00, 2.50, 0.00)** (fonte: F2 com cultura invariante).
21. Unity: `Destroy(inimigo); Debug.Log(inimigo == null);` no mesmo Update → **False**, porque a destruição só ocorre no fim do Update (fonte).
22. Unity: com a camada "Inimigo" no índice 8 (fonte):
    - `LayerMask.GetMask("Inimigo")` → **256**;
    - `LayerMask.NameToLayer("Inimigo")` → **8**.
23. Godot: `GD.RandRange(1, 3)` pode dar **1, 2 ou 3** (fonte).
24. Godot: árvore `Pai → (A, B)` (fonte):
    - ordem de `_EnterTree`: **Pai, A, B**;
    - ordem de `_Ready`: **A, B, Pai**.
25. `unchecked((byte)(250 + 10))` → **4**; `unchecked(int.MaxValue + 1)` → **-2147483648** (exec). Serve para uma pontuação que "vira".

**Completar a lacuna**
1. `private void ____() => _rb = GetComponent<Rigidbody>();` → `Awake`
2. `_rb.________ = new Vector3(0, 10, 0);` → `linearVelocity`
3. `if (other.________("Player"))` → `CompareTag`
4. `yield return new __________(0.5f);` → `WaitForSeconds`
5. `__________(Piscar());` → `StartCoroutine`
6. `[Signal] public delegate void Morreu__________();` → `EventHandler`
7. `public override void _Process(______ delta)` → `double`
8. `public _______ class Jogador : Node2D` → `partial`
9. `int j = rng.Next(_____);` (Fisher–Yates) → `i + 1`
10. `return ((a % n) + ___) % n;` → `n`
11. `float dt = (float)gameTime.______________.TotalSeconds;` → `ElapsedGameTime`
12. `await Awaitable.____________________(1f, destroyCancellationToken);` → `WaitForSecondsAsync`
13. `[________________(typeof(Rigidbody))]` → `RequireComponent`
14. `Velocity = v; ____________();` → `MoveAndSlide`
15. `EmitSignal(__________.Morreu);` → `SignalName`
16. `private void __________() => vida.Mudou -= Atualizar;` (par do `OnEnable`) → `OnDisable`

**Ordenar linhas**
1. Ciclo de vida Unity: `Update`, `Awake`, `OnDestroy`, `Start`, `LateUpdate`, `OnEnable`, `FixedUpdate`, `OnDisable` → Awake, OnEnable, Start, FixedUpdate, Update, LateUpdate, OnDisable, OnDestroy.
2. MonoGame: `Draw`, construtor, `LoadContent`, `Update`, `Initialize` → construtor, Initialize, LoadContent, Update, Draw.
3. Passo da cobrinha: (a) calcular a nova cabeça com wrap; (b) testar colisão com o corpo; (c) inserir a cabeça; (d) se comeu, crescer, senão remover a cauda.
4. BFS: criar a fila e o `dist[inicio]=0` → enfileirar o início → `while` → desenfileirar → *early exit* → para cada vizinho válido e não visitado: marcar a distância e enfileirar.
5. Fisher–Yates: `for (i = n-1; i > 0; i--)` → `j = rng.Next(i+1)` → trocar `a[i]` e `a[j]`.
6. Undo: executar → empilhar em `_desfazer` → limpar `_refazer`. Desfazer: desempilhar → `c.Desfazer()` → empilhar em `_refazer`.
7. Pool: `Get()` → configurar posição e rotação → usar → `Release(this)` → `actionOnRelease` desativa.

**Achar o bug** (erros de compilação confirmados pelos compiladores reais)
1. `void update() { ... }` na Unity: compila e nunca executa. A mensagem é `Update`.
2. `rb.velocity = Vector3.up;` no Unity 6 → **CS0618** "'Rigidbody.velocity' is obsolete: 'Please use Rigidbody.linearVelocity instead…'".
3. `transform.position.x = 5f;` → **CS1612** "Cannot modify the return value of 'Transform.position'".
4. `public override void Update() {}` → **CS0115** "no suitable method found to override".
5. `void OnTriggerEnter2D(Collider other)` → a Unity ignora a mensagem ("This message parameter has to be of type: Collider2D").
6. `StartCoroutine(Esperar);` → **CS1503** (grupo de métodos). E `StartCoroutine(Esperar())` com `void Esperar()` → **CS1503** ("cannot convert from 'void'").
7. `using System; using UnityEngine; … Random.Range(1, 7)` → **CS0104** "'Random' is an ambiguous reference".
8. `rb = GetComponent(typeof(Rigidbody));` → **CS0266** (falta o cast; use `GetComponent<Rigidbody>()`).
9. `[SerializeField] public int Vida { get; set; }` → **CS0592**. Use `[field: SerializeField]`.
10. `public int Preco { get; init; }` ou `public record Item(...)` na Unity → **CS0518** (`IsExternalInit`).
11. `namespace Jogo;` na Unity → **CS8773** (C# 10).
12. `Vector3 F(Quaternion q, Vector3 v) => v * q;` → **CS0019** (a ordem certa é `q * v`).
13. `if (Input.GetButtonDown("Jump"))` dentro do `FixedUpdate`: perde pulos. Mover para o `Update` e guardar numa flag.
14. `Physics.Raycast(raio, out hit, 100f, 8)` para "camada 8": o 8 é **máscara** (bit 3). O certo é `1 << 8` ou `LayerMask.GetMask(...)`.
15. `enabled = false;` para "parar" corrotinas: elas continuam. Use `StopCoroutine` ou `StopAllCoroutines`.
16. `if (alvo?.gameObject != null)` com o alvo destruído: `?.` ignora o null da Unity. Use `if (alvo != null)`.
17. Assinar `vida.Mudou += Atualizar;` no `OnEnable` sem o `-=` no `OnDisable`: vazamento e erro depois da troca de cena.
18. `rng.Next(1, 6)` para um d6: nunca sai 6.
19. Fisher–Yates com `rng.Next(i)`: vira Sattolo, e nenhuma carta fica na mesma posição.
20. `cabeca.X = (cabeca.X - 1) % largura;` → índice -1 e `IndexOutOfRangeException`.
21. `foreach (var e in inimigos) if (e.Morto) inimigos.Remove(e);` → **InvalidOperationException** (exec).
22. Game of Life atualizando **no mesmo array**: as células já atualizadas contaminam as vizinhas. Use dois buffers.
23. 2048 (exec, `raw/validate/bug2048`):
    - sem o `i++` depois de fundir, a peça consumida reaparece: `[2,2,0,0]` vira `[4,2,0,0]`;
    - na variante clássica que compara com a peça **já fundida** (`s[^1] == x`), `[2,2,4,0]` vira `[8,0,0,0]`, quando o certo é `[4,4,0,0]`.
24. Godot `public class Jogador : Node2D` → **GD0001** (falta `partial`).
25. Godot `[Signal] public delegate void Morreu();` → **GD0201**.
26. Godot `public override void _Process(float delta)` → **CS0115**.
27. Godot `Position += new Vector2(100, 0) * delta;` → **CS0019** (`double`).
28. Godot `Velocity.Y += 10f;` → **CS1612**.
29. Godot `Morreu?.Invoke();` → **CS0079**. Use `EmitSignal(SignalName.Morreu)`.
30. Godot `[Export] public static int Vidas = 3;` → **GD0101**. E `[Export] public readonly int Vidas` → **GD0103**.
31. MonoGame `_posicao = … _bola.Width …` **antes** de `base.Initialize()` → `NullReferenceException`, porque o `LoadContent` ainda não rodou.
32. MonoGame `if (Keyboard.GetState().IsKeyDown(Keys.Space)) Atirar();` → atira a cada frame. Faltou o estado anterior.

**Valor final da variável / rastreio** (exec)
1. `Recarga(1.5f)`: `TentarUsar()`, `Atualizar(1f)`, `TentarUsar()`, `Atualizar(0.5f)`, `TentarUsar()` → **[True, False, True]**.
2. Inventário com capacidade 2 → **[True, True, False, True]**, e `Quantidade("pocao")` = **5**. A sequência é:
   1. `Adicionar("pocao",3)`
   2. `Adicionar("espada")`
   3. `Adicionar("escudo")`
   4. `Adicionar("pocao",2)`
3. Command: `Mover(1,0)`, `Mover(0,2)`, `Mover(3,0)`, desfazer, desfazer, refazer, `Mover(-1,-1)`, refazer → posição **(0,1)**; o último refazer devolve **False**.
4. State: `EmPe` com os comandos "pular", "pular", "aterrissar" → log **entrou EmPe | saiu EmPe | entrou Pulando | saiu Pulando | entrou EmPe** (o 2º "pular" é ignorado).
5. IA (`Proximo`):
   - `(Patrulha, 5, 100)` → Perseguindo;
   - `(Atacando, 1, 10)` → Fugindo;
   - `(Perseguindo, 20, 50)` → Patrulha;
   - `(Atacando, 3, 80)` → Perseguindo.
6. Mapa `"...#" / "##.#" / "...."`: a distância BFS de (0,0) a (2,0) é **6**, e até (0,3), que é parede, é **-1**.
7. Grade 5×5 com parede em x=1, y=0..3: o A\* de (0,0) a (2,0) dá **10** passos.
8. Campo 4×4 com minas em (0,3) e (3,3): abrir (3,0) abre **12** células.
9. Update Method com balas de 2 e 1 quadros → quantidade por quadro **[2,1,0,0]**.
10. Grade espacial com células de 10: pontos A(1,1), B(12,1) e C(35,35); `Proximos(5,1, raio 8)` → **A,B**.

**Escolha conceitual**
1. Onde aplicar `AddForce`? → `FixedUpdate`.
2. Onde colocar a câmera que segue? → `LateUpdate`.
3. Moeda que não empurra ninguém: collider ou trigger? → trigger (`OnTriggerEnter`).
4. Personagem FPS sem física realista: `CharacterController` ou `Rigidbody`? → `CharacterController`.
5. 300 balas por minuto → Object Pool.
6. 500 inimigos com os mesmos atributos base → Flyweight/Type Object (ScriptableObject).
7. "Desfazer jogada" no puzzle → Command.
8. HUD reagindo à vida sem o `Vida` conhecer a UI → Observer (`event` / sinal).
9. Achar vizinhos entre 10 mil unidades → Spatial Partition.
10. Vários sistemas pedindo som no mesmo frame → Event Queue.
11. Menor caminho com custo uniforme para todos os destinos → BFS. Para um destino, com heurística → A\*.
12. Projeto Unity novo: `Input.GetAxis` ou Input System? → Input System.
13. Godot, mover `CharacterBody2D`: `_Process` ou `_PhysicsProcess`? → `_PhysicsProcess`.
14. Esperar 1 s na Unity 6 cancelando se o objeto for destruído → `Awaitable.WaitForSecondsAsync(1f, destroyCancellationToken)`.
15. Demo C# que precisa rodar no navegador: Godot 4 C#? → **Não** (sem export Web). Use Unity (WebGL/Web) ou outra opção.

---

## 6. Recomendações para o stub e o validador

1. **Um projeto de compilação por alvo**:
   - Unity: `netstandard2.1` com `LangVersion 9.0`, `Nullable disable` e `TreatWarningsAsErrors true`. Adicionar `NoWarn CS0649`, porque campos `[SerializeField]` atribuídos pelo Inspector geram esse warning.
   - Godot: `Sdk="Godot.NET.Sdk/4.7.2"` com net8.0. Compila fora do editor, com os geradores de código e os analisadores GD0xxx reais.
   - MonoGame: net9.0 com `MonoGame.Framework.DesktopGL 3.8.5.1`.
   - C# puro: net9.0 ou net10.0.
2. **Replicar os `[Obsolete]` reais** no stub, com as mesmas mensagens (`velocity`, `drag`, `angularDrag`, `isKinematic` do 2D, `FindObjectOfType`). Com warnings tratados como erro, o exercício que usar a API velha **falha**, como queremos.
3. **Replicar a forma dos membros**:
   - `Vector3.x/y/z` e `Vector2.x/y` são **campos**; `Vector2Int.x/y` são propriedades.
   - `Transform.position` e `Rigidbody.linearVelocity` são **propriedades**, e é isso que gera o CS1612 real.
   - O `==` do `UnityEngine.Object` é sobrecarregado e há conversão implícita para `bool`. O `RaycastHit2D` também converte para `bool`.
4. **Awaitable no stub**: sem o `[AsyncMethodBuilder]` na classe, `async Awaitable` não compila. O stub validado em `raw/validate/unitystub/Misc.cs` tem um builder mínimo que funciona com C# 9.
5. **Lint de mensagens** (a Roslyn não pega): validar nome e parâmetros contra a tabela de §2.1.
   - Rejeitar variações de caixa (`update`, `Onenable`).
   - Rejeitar `override` em mensagens.
   - Rejeitar `OnTriggerEnter2D(Collider)` e similares.
   - Rejeitar `IEnumerator` em `Awake`, `OnEnable`, `OnDisable` e `OnDestroy`.
6. **Namespaces do stub**:

   | Namespace | Tipos |
   |---|---|
   | `UnityEngine` | núcleo |
   | `UnityEngine.SceneManagement` | cenas |
   | `UnityEngine.Events` | `UnityEvent` e `UnityAction` |
   | `UnityEngine.Pool` | `ObjectPool` |
   | `UnityEngine.InputSystem` e `UnityEngine.InputSystem.Controls` | pacote Input System |
   | `UnityEngine.Serialization` | `FormerlySerializedAs` |
   | `TMPro` | `TMP_Text` |

7. **Base de versão**: 6.3 LTS. Recomendo também um **modo 6.4+** no stub, com `FindFirstObjectByType` e `FindObjectsSortMode` marcados como `[Obsolete]`. Assim os exercícios ficam compatíveis com toda a série 6.x.
8. **Gabaritos**: rodar de fato os de C# puro, como feito em `raw/validate/purecs/Program.cs`.
   - Nunca usar sequências de `Random` com seed como gabarito.
   - Não imprimir `float` sem cultura fixa.
   - Nos gabaritos de Unity, usar só comportamentos documentados (os marcados como **fonte**).
9. **Licença**: o UnityCsReference é *Reference Only*. Use-o para conferir assinaturas e escreva o stub com código nosso; não copie arquivos.

---

## 7. URLs consultadas

**Unity: versões, roadmap e C#**
- https://endoflife.date/unity
- https://unity.com/releases/unity-6/support
- https://discussions.unity.com/t/coreclr-scripting-and-serialization-update-june-2026/1723299
- https://discussions.unity.com/t/path-to-coreclr-2026-upgrade-guide/1714279
- https://digitalproduction.com/2025/11/26/unitys-2026-roadmap-coreclr-verified-packages-fewer-surprises/
- https://docs.unity3d.com/6000.0/Documentation/Manual/csharp-compiler.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/csharp-compiler.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/dotnet-profile-support.html
- https://docs.unity3d.com/6000.0/Documentation/Manual/UpgradeGuideUnity6.html
- https://discussions.unity.com/t/why-change-velocity-to-linearvelocity/1571926

**Unity: manual**
- https://docs.unity3d.com/6000.0/Documentation/Manual/execution-order.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/execution-order.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/Coroutines.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/async-await-support.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/async-awaitable-introduction.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/async-awaitable-examples.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/script-serialization-rules.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/domain-reloading.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/fixed-updates.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/collider-interactions-ontrigger.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/collision-detection.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/layermask-set.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/use-layers.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/instantiating-prefabs-intro.html
- https://docs.unity3d.com/2020.1/Documentation/Manual/InstantiatingPrefabs.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/class-ScriptableObject.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/unity-events.html
- https://docs.unity3d.com/6000.3/Documentation/Manual/script-execution-order.html
- https://docs.unity3d.com/Packages/com.unity.ugui@2.0/manual/TextMeshPro/index.html

**Unity: Scripting API** (todas em `https://docs.unity3d.com/6000.3/Documentation/ScriptReference/`; a `Rigidbody-linearVelocity.html` também foi consultada na 6000.0)
- MonoBehaviour: `MonoBehaviour.html` (6000.0 e 6000.3), `.Awake`, `.Start`, `.Update`, `.FixedUpdate`, `.LateUpdate`, `.OnEnable`, `.OnDisable`, `.OnDestroy`, `.OnValidate`, `.OnCollisionEnter`, `.OnCollisionEnter2D`, `.OnTriggerEnter`, `.OnTriggerEnter2D`, `.OnApplicationPause`, `.StartCoroutine`, `.StopCoroutine`, `.StopAllCoroutines`, `.Invoke`, `.InvokeRepeating`, `-destroyCancellationToken`
- Object: `Object.html`, `-operator_eq`, `-operator_Object`, `.Instantiate`, `.Destroy`, `.DontDestroyOnLoad`, `.FindAnyObjectByType`, `.FindFirstObjectByType`, `.FindObjectsByType`, `.FindObjectOfType`
- Component e GameObject: `Component.TryGetComponent`, `Component.CompareTag`, `GameObject.GetComponent`, `GameObject.TryGetComponent`, `GameObject.CompareTag`, `GameObject.SetActive`, `GameObject.AddComponent`, `GameObject.Find`, `GameObject.FindWithTag`
- Transform: `.Translate`, `.Rotate`, `-position`, `-localPosition`, `-eulerAngles`, `-forward`, `.LookAt`, `.SetParent`
- Vector3 e Quaternion: `Vector3.MoveTowards`, `.Lerp`, `.Distance`, `-normalized`, `-sqrMagnitude`, `.ClampMagnitude`, `.Dot`; `Quaternion.Euler`, `.LookRotation`, `.Slerp`, `.RotateTowards`, `-identity`, `.AngleAxis`
- Mathf e Random: `Mathf.Clamp`, `.Lerp`, `.MoveTowards`, `.Approximately`, `.PingPong`, `.SmoothDamp`, `.Abs`, `.RoundToInt`; `Random.Range`, `Random-value`, `Random-insideUnitCircle`
- Time: `-deltaTime`, `-fixedDeltaTime`, `-timeScale`, `-time`, `-unscaledDeltaTime`, `-maximumDeltaTime`
- Input legado: `Input.GetAxis`, `.GetAxisRaw`, `.GetKeyDown`, `.GetKey`, `.GetButtonDown`, `.GetMouseButtonDown`, `Input-mousePosition`
- Física 3D: `Rigidbody.AddForce`, `ForceMode`, `Rigidbody.MovePosition`, `Rigidbody-linearVelocity`, `-linearDamping`, `-angularDamping`, `-isKinematic`; `Collision`, `Collision-gameObject`, `Collision.GetContact`; `CharacterController.Move`, `-isGrounded`, `.SimpleMove`
- Física 2D: `Rigidbody2D-linearVelocity`, `-linearVelocityX`, `Rigidbody2D.AddForce`, `ForceMode2D`, `Rigidbody2D.MovePosition`, `-bodyType`, `-gravityScale`, `-linearDamping`; `Collision2D`
- Consultas de física: `Physics.Raycast`, `Physics2D.Raycast`, `Physics.OverlapSphere`, `Physics.OverlapSphereNonAlloc`, `Physics.RaycastNonAlloc`, `RaycastHit`, `LayerMask.GetMask`, `LayerMask.NameToLayer`
- Câmera, dados e aplicação: `Camera.ScreenPointToRay`, `Camera-main`, `Camera.ScreenToWorldPoint`; `JsonUtility.ToJson`, `JsonUtility.FromJson`; `Application.Quit`, `Application-targetFrameRate`
- Atributos e ScriptableObject: `SerializeField`, `ScriptableObject`, `CreateAssetMenuAttribute`, `RequireComponent`
- Awaitable e Pool: `Awaitable`; `Pool.ObjectPool_1`, `Pool.ObjectPool_1-ctor`, `Pool.ObjectPool_1.Get`, `Pool.ObjectPool_1.Release`, `Pool.IObjectPool_1`
- Eventos: `Events.UnityEvent`, `Events.UnityEvent.AddListener`, `Events.UnityEvent.Invoke`, `Events.UnityEvent_1`, `Events.UnityAction`, `Events.UnityAction_1`, `Events.UnityEventBase.RemoveAllListeners`
- Cenas e PlayerPrefs: `SceneManagement.SceneManager.LoadScene`, `.LoadSceneAsync`, `.GetActiveScene`, `SceneManagement.Scene-buildIndex`; `PlayerPrefs`, `PlayerPrefs.SetInt`, `.GetInt`, `.GetString`, `.Save`, `.HasKey`
- Animator e áudio: `Animator.SetTrigger`, `.SetBool`, `.SetFloat`, `.SetInteger`, `.StringToHash`, `.ResetTrigger`, `.Play`; `AudioSource.PlayOneShot`, `.Play`, `.PlayClipAtPoint`, `AudioSource-clip`, `AudioSource-volume`

**Unity: código-fonte de referência e exemplos**
- https://github.com/Unity-Technologies/UnityCsReference (ramos 6000.0, 6000.3, 6000.4, 6000.5, 6000.6, 6000.7). Arquivos:
  - `Modules/Physics/ScriptBindings/Rigidbody.bindings.cs` e `Rigidbody.deprecated.cs`
  - `Modules/Physics2D/ScriptBindings/Physics2D.bindings.cs` e `Physics2D.deprecated.cs`
  - `Runtime/Export/Scripting/UnityEngineObject.bindings.cs`, `MonoBehaviour.bindings.cs`, `Component.bindings.cs`, `GameObject.bindings.cs`, `Behaviour.bindings.cs`
  - `Runtime/Transform/ScriptBindings/Transform.bindings.cs`
  - `Runtime/Export/Math/*.cs`
  - `Runtime/Export/Scripting/Awaitable*.cs`, `Attributes.cs`
  - `Runtime/Export/PropertyDrawer/PropertyAttribute.cs`
  - `Runtime/Export/Serialization/Serialization.cs`
  - `Runtime/Export/ObjectPool/ObjectPools.cs`
  - `Modules/InputLegacy/Input.bindings.cs`
- https://github.com/Unity-Technologies/game-programming-patterns-demo
- https://unity.com/resources/design-patterns-solid-ebook
- https://unity.com/blog/game-programming-patterns-update-ebook

**Unity: Input System e TextMeshPro**
- https://github.com/Unity-Technologies/InputSystem/tree/develop/Packages/com.unity.inputsystem
  - Documentação: `Documentation~/quick-start-guide.md`, `using-direct-workflow.md`, `corresponding-old-new-api.md`, `enable-correct-input-system.md`, `Installation.md`, `select-notification-behavior.md`, `set-callbacks-on-actions.md`
  - Código: `Runtime/Actions/InputAction.cs`, `InputActionAsset.cs`, `Controls/ButtonControl.cs`, `Devices/Keyboard.cs`, `Mouse.cs`, `Gamepad.cs`, `Pointer.cs`, `InputSystem.cs`, `Plugins/PlayerInput/InputValue.cs`
- https://raw.githubusercontent.com/needle-mirror/com.unity.inputsystem/master/CHANGELOG.md
- https://discussions.unity.com/t/script-error-ontriggerenter2d-this-message-parameter-has-to-be-of-type-collider2d-solved/752521
- https://issuetracker.unity3d.com/issues/error-invalidoperationexception-you-are-trying-to-read-input-using-the-unityengine-dot-input-class-but-you-have-switched-active-input-handling-to-input-system-package-in-player-settings-dot-is-present-when-using-ui-toolkit-and-new-input-system
- https://discussions.unity.com/t/textmesh-pro-and-ugui-merged-clarification-on-where-to-get-the-latest-tmp-for-urp/1603892

**Godot 4.7**

Documentação (todas em `https://docs.godotengine.org/en/stable/tutorials/`, exceto a do jogo 2D):
- `scripting/c_sharp/`: `c_sharp_basics`, `c_sharp_signals`, `c_sharp_exports`, `c_sharp_differences`, `c_sharp_global_classes`, `c_sharp_style_guide`, `diagnostics/index`, `diagnostics/GD0001`, `diagnostics/GD0201`
- `scripting/`: `overridable_functions`, `idle_and_physics_processing`, `nodes_and_scene_instances`
- `physics/using_character_body_2d` e `inputs/input_examples`
- https://docs.godotengine.org/en/stable/getting_started/first_2d_game/03.coding_the_player.html

Código e pacotes:
- https://github.com/godotengine/godot/blob/4.7.2-stable/modules/mono/editor/GodotTools/GodotTools.ProjectEditor/ProjectGenerator.cs
- https://github.com/godotengine/godot/blob/4.7.2-stable/core/input/input_map.cpp
- https://www.nuget.org/packages/GodotSharp/4.7.2 (lido por reflexão, incluindo o XML de documentação)
- https://www.nuget.org/packages/Godot.NET.Sdk/4.7.2

**MonoGame 3.8.5**

Documentação (todas em `https://docs.monogame.net/articles/tutorials/building_2d_games/`):
- `index.html`, `03_the_game1_file/`, `05_content_pipeline/`, `10_handling_input/`, `11_input_management/`, `12_collision_detection/`, `22_snake_game_mechanics/`
- API: https://docs.monogame.net/api/Microsoft.Xna.Framework.Game.html · https://docs.monogame.net/api/Microsoft.Xna.Framework.Rectangle.html · https://docs.monogame.net/api/Microsoft.Xna.Framework.Graphics.SpriteBatch.html

Código e pacotes:
- https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Game.cs
- https://github.com/MonoGame/MonoGame/blob/develop/MonoGame.Framework/Rectangle.cs
- https://www.nuget.org/packages/MonoGame.Framework.DesktopGL/3.8.5.1
- https://www.nuget.org/packages/MonoGame.Templates.CSharp/3.8.5.1 (TargetFramework dos templates)

**Padrões e algoritmos**
- *Game Programming Patterns*, capítulos em `https://gameprogrammingpatterns.com/<capítulo>.html`: `contents`, `game-loop`, `update-method`, `double-buffer`, `state`, `command`, `observer`, `flyweight`, `component`, `object-pool`, `spatial-partition`, `event-queue`, `service-locator`, `type-object`, `dirty-flag`, `data-locality`, `singleton`, `subclass-sandbox`, `bytecode`, `prototype`
- https://gafferongames.com/post/fix_your_timestep/
- https://www.redblobgames.com/pathfinding/a-star/introduction.html
- https://www.redblobgames.com/pathfinding/a-star/implementation.html
- https://developer.mozilla.org/en-US/docs/Games/Techniques/2D_collision_detection
- https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life
- https://en.wikipedia.org/wiki/2048_(video_game)
- https://en.wikipedia.org/wiki/Minesweeper_(video_game)
- https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle

**.NET (Microsoft Learn)**
- https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.priorityqueue-2
- https://learn.microsoft.com/en-us/dotnet/api/system.collections.generic.priorityqueue-2.remove
- https://learn.microsoft.com/en-us/dotnet/api/system.random
- https://learn.microsoft.com/en-us/dotnet/api/system.random.shared
- https://learn.microsoft.com/en-us/dotnet/api/system.random.shuffle
- https://learn.microsoft.com/en-us/dotnet/api/system.math.clamp
- https://learn.microsoft.com/en-us/dotnet/api/system.mathf
- https://learn.microsoft.com/en-us/dotnet/api/system.hashcode
