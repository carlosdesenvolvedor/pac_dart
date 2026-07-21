# PAC·DART — Blueprint para reconstruir em Flutter

> **PAC·DART** é um treinador de digitação em que um Pac-Man "come" as letras conforme você digita **código Dart/Flutter de verdade**. A ideia é aprender a programar enquanto pratica digitação: cada exercício é um trecho de código real que, ao ser digitado corretamente, "compila" e mostra o resultado. Todo o conteúdo é em **português do Brasil**.

Este documento descreve o projeto por inteiro — conceito, funcionalidades, design, dados, o motor de digitação e a prévia ao vivo — e traz orientação concreta de **como reimplementar tudo em Flutter** (o projeto atual é HTML/CSS/JS puro). Onde faz sentido, há esboços de código Dart.

---

## 1. Conceito e loop principal

O usuário escolhe uma **trilha** (ex.: Fundamentos, Flutter) e uma **lição** (ex.: Variáveis, Botões). A tela mostra um **trecho de código** a ser digitado. Um **Pac-Man** fica sobre o caractere atual e "avança comendo" as letras conforme você acerta.

1. A cada tecla correta, o cursor avança um caractere e o Pac-Man se reposiciona.
2. A cada tecla errada, conta um erro (o cursor **não** avança).
3. A **indentação é automática**: o usuário nunca digita os espaços do começo da linha — ao apertar Enter, o motor pula sozinho toda a indentação da próxima linha.
4. Quando o trecho termina, ele "compila": o **console** mostra sucesso e (nos exercícios Flutter) uma **prévia do widget** aparece renderizada. Aperta-se **Enter** para ir ao próximo.
5. Estatísticas em tempo real: **pontuação**, **PPM** (palavras por minuto), **precisão** e **erros**.

Extras: **narração por voz** (TTS em pt-BR lendo a dica), **destaque de sintaxe** próprio, e um **menu** de navegação (trilha/lição em dropdowns).

---

## 2. Funcionalidades (checklist)

- [ ] 7 trilhas, 93 lições, **641 exercícios** (todos código Dart válido).
- [ ] Motor de digitação caractere-a-caractere com **auto-indentação** e Backspace inteligente.
- [ ] Suporte a **acentos / teclado internacional / IME** (dead keys, AltGr).
- [ ] **Enter para avançar** ao concluir um trecho.
- [ ] Estatísticas: pontuação, PPM, precisão, erros, cronômetro.
- [ ] **Console** que "compila" e mostra a saída esperada.
- [ ] **Prévia Flutter ao vivo** (exercícios da trilha Flutter) com animações.
- [ ] **Narração por voz** (TTS pt-BR) da dica.
- [ ] **Destaque de sintaxe** monocromático + amarelo.
- [ ] **Menu** com dropdowns de trilha e lição, marcando lições concluídas (✓).
- [ ] Tela de vitória ao concluir uma lição.

---

## 3. Design System ("Mixart")

Estética **escura e minimalista**, monocromática com **um** acento amarelo. Nada de gradientes chamativos nem "glow".

### Cores (design tokens)

| Token | Valor | Uso |
|---|---|---|
| `bg` | `#010101` | Fundo geral |
| `surface` | `#0F0F0F` | Cartões/superfícies |
| `surface-hi` | `#1F1F1F` | Superfície em destaque/hover |
| `text` | `#F4F1EA` | Texto principal (branco quente) |
| `text-muted` | `#9CA3AF` | Texto secundário |
| `text-faint` | `#6B7280` | Texto terciário |
| `text-hint` | `#4B5563` | Comentários/dicas fracas |
| `brand` | `#FFC73B` | Amarelo (acento único) |
| `on-brand` | `#010101` | Texto sobre o amarelo (preto) |
| `border` | `#1F1F1F` | Bordas |
| `danger` | `#F2555A` | Erros |

Raios: `md 16px`, `lg 18px`, `chip 24px`, `pill 999px`.
Easings: spring `cubic-bezier(.16,1,.3,1)`, slide `cubic-bezier(.4,0,.2,1)`.

### Tipografia

- **Display** (títulos): `Funnel Display`
- **UI** (interface): `Archivo`
- **Mono** (código): `JetBrains Mono`

No Flutter, use o pacote **`google_fonts`** (`GoogleFonts.archivo()`, `GoogleFonts.jetBrainsMono()`, etc.). "Funnel Display" pode não estar no Google Fonts do pacote — nesse caso, inclua o `.ttf` em `assets/fonts` e declare no `pubspec.yaml`.

### Destaque de sintaxe (paleta)

Monocromático, com **palavras-chave em amarelo** e o resto em tons de cinza:

| Elemento | Cor |
|---|---|
| Palavra-chave (`class`, `if`, `for`, `var`…) | `brand` (`#FFC73B`) |
| Tipo / função / identificador | `text` (`#F4F1EA`) |
| String / número | `text-muted` (`#9CA3AF`) |
| Pontuação / operador | `text-faint` (`#6B7280`) |
| Comentário | `text-hint` (`#4B5563`) |

---

## 4. Modelo de dados do currículo

Estrutura em 3 níveis: **Trilha → Lição → Trecho**.

```
Trilha { nivel, emoji, licoes: [Licao] }
Licao  { nome, emoji, trechos: [Trecho] }
Trecho { cod, dica, out }
```

- `cod`: o código a digitar (com `\n` reais e indentação de 2 espaços).
- `dica`: explicação curta (no projeto atual tem `<b>…</b>`; em Flutter, prefira texto puro ou um markup simples).
- `out`: o resultado/efeito esperado (texto mostrado no console ao "compilar").

**Recomendação para Flutter:** exporte o currículo (hoje um grande array JS) para **`assets/curriculo.json`** e carregue com `rootBundle`. Assim os dados ficam separados do código.

Classes Dart:

```dart
class Trilha {
  final String nivel, emoji;
  final List<Licao> licoes;
  Trilha({required this.nivel, required this.emoji, required this.licoes});
  factory Trilha.fromJson(Map<String, dynamic> j) => Trilha(
    nivel: j['nivel'], emoji: j['emoji'],
    licoes: (j['licoes'] as List).map((e) => Licao.fromJson(e)).toList(),
  );
}
class Licao {
  final String nome, emoji;
  final List<Trecho> trechos;
  Licao({required this.nome, required this.emoji, required this.trechos});
  factory Licao.fromJson(Map<String, dynamic> j) => Licao(
    nome: j['nome'], emoji: j['emoji'],
    trechos: (j['trechos'] as List).map((e) => Trecho.fromJson(e)).toList(),
  );
}
class Trecho {
  final String cod, dica, out;
  Trecho({required this.cod, required this.dica, required this.out});
  factory Trecho.fromJson(Map<String, dynamic> j) =>
    Trecho(cod: j['cod'], dica: j['dica'] ?? '', out: j['out'] ?? '');
}
```

### As 7 trilhas

| # | Trilha | Lições | Exerc. | Conteúdo |
|---|---|---|---|---|
| 1 | 🌱 **Fundamentos** | 10 | 77 | Variáveis, inteiros, decimais, booleanos, operadores, texto (básico/métodos/avançado), conversões, comentários |
| 2 | 🔀 **Lógica** | 12 | 81 | Condições, switch, switch expr, padrões, laços for/while, fluxo, funções, parâmetros, arrow/anônimas, closures, generators |
| 3 | 📦 **Coleções** | 10 | 72 | Listas (buscar/mudar), Sets, Maps (métodos), Iterables, literais, Records, ordenar |
| 4 | 🧱 **Objetos** | 14 | 94 | Classes, construtores, get/set, estáticos, herança, abstract, mixins, enums, extensions, operadores, generics, extension types, modifiers |
| 5 | ⏳ **Avançado** | 12 | 79 | Null safety, Future (métodos), Streams, erros (tratar/lançar), bibliotecas, JSON, math, isolates |
| 6 | 💙 **Flutter** | 30 | 208 | Widgets, Text/estilo, imagens/ícones, Container, espaçamento, Column/Row, Expanded/Flexible, Stack/Align, Wrap/GridView, listas, Material, botões, entrada, seletores, estado, ciclo de vida, navegação, diálogos, FutureBuilder, tema, animações, Cupertino, rolagem, abas, responsivo, formulário, estado compartilhado, Provider, Slivers, widgets úteis |
| 7 | 🧩 **Desafios** | 5 | 30 | Programas maiores e completos (FizzBuzz, fatorial, Fibonacci, palíndromo, bubble sort, conta bancária, carrinho…) organizados em Números, Textos, Listas, Funções, Classes |

Cada trecho é código Dart real (Dart 3.12 / Flutter 3.44, Material 3). Os da trilha Desafios têm até 13 linhas; os demais são curtos e focados em um conceito.

---

## 5. O motor de digitação (a parte mais delicada)

O coração do app. Ele compara o que o usuário digita com o código-alvo, caractere por caractere.

### Estado

- `chars`: lista de caracteres do trecho (crus, incluindo `\n` e espaços).
- `idx`: posição atual (próximo caractere esperado).
- `erros`, `travado` (bloqueado ao concluir), `aguardandoProximo` (esperando Enter para avançar).

### Regras

1. **Digitar**: se a tecla == `chars[idx]`, avança (`idx++`). Se o caractere digitado foi `\n`, **pula toda a indentação** da próxima linha. Se errou, incrementa `erros` e **não** avança.
2. **Auto-indentação (crítico)**: o usuário **nunca digita os espaços do início da linha**. Logo após um `\n` correto, o motor pula **todos** os espaços seguidos.
3. **Backspace**: volta `idx--`; se caiu dentro da indentação auto-consumida, **volta por todos os espaços** até o `\n`.
4. **Enter**: se aguardando o próximo → avança de trecho; senão → conta como digitar `\n`.

### ⚠️ Armadilha nº 1 (bug real que corrigimos)

A função que pula a indentação **precisa pular TODOS os espaços**, não apenas um. Uma versão que checa "o caractere anterior é `\n`" a cada iteração só pula o **primeiro** espaço e trava em qualquer linha indentada com 2+ espaços (ou seja, praticamente todo `if{}`, classe e função). O correto:

```dart
class TypingEngine extends ChangeNotifier {
  late List<String> chars;
  int idx = 0, erros = 0;
  bool travado = false, aguardandoProximo = false;

  void carregar(String cod) {
    chars = cod.split('');
    idx = 0; erros = 0; travado = false; aguardandoProximo = false;
    notifyListeners();
  }

  void digitar(String tecla) {
    if (travado || idx >= chars.length) return;
    final esperado = chars[idx];
    final ok = tecla == '\n' ? esperado == '\n' : tecla == esperado;
    if (ok) {
      idx++;
      if (tecla == '\n') _pularIndentacao();     // ← pula TODA a indentação
      if (idx >= chars.length) _concluir();
    } else {
      erros++;
    }
    notifyListeners();
  }

  // Chamado só logo após um \n; idx está no começo da linha.
  void _pularIndentacao() {
    while (idx < chars.length && chars[idx] == ' ') idx++;
  }

  void apagar() {
    if (travado || idx <= 0) return;
    idx--;
    // volta por TODA a indentação auto-consumida até o \n
    while (idx > 0 && chars[idx] == ' ' &&
           (chars[idx - 1] == ' ' || chars[idx - 1] == '\n')) {
      idx--;
    }
    notifyListeners();
  }

  void _concluir() {
    travado = true;
    aguardandoProximo = true;
    // pontuação, tempo, etc.
  }
}
```

### ⚠️ Armadilha nº 2 — captura de teclas com acentos / IME

Digitar código Dart usa muitos caracteres especiais e, em português, acentos (dead keys) e AltGr. No projeto web, a solução foi **capturar Tab/Backspace/Enter no keydown** e deixar **todo o resto** fluir por um `<textarea>` escondido (eventos de composição), evitando problemas com acentos.

Em Flutter, o equivalente robusto é um **`TextField` invisível** sempre focado, processando as mudanças, combinado com um `Focus`/`KeyboardListener` para as teclas de controle:

```dart
// TextField transparente/fora da tela, sempre com foco.
_controller.addListener(() {
  final txt = _controller.text;
  for (final ch in txt.characters) {
    engine.digitar(ch);            // processa cada caractere digitado (inclui acentos)
  }
  _controller.clear();             // limpa para o próximo
});

// Teclas de controle:
Focus(
  onKeyEvent: (node, e) {
    if (e is! KeyDownEvent) return KeyEventResult.ignored;
    if (e.logicalKey == LogicalKeyboardKey.backspace) { engine.apagar(); return KeyEventResult.handled; }
    if (e.logicalKey == LogicalKeyboardKey.enter) {
      if (engine.aguardandoProximo) { avancar(); } else { engine.digitar('\n'); }
      return KeyEventResult.handled;
    }
    if (e.logicalKey == LogicalKeyboardKey.tab) return KeyEventResult.handled; // ignora Tab
    return KeyEventResult.ignored;
  },
  child: /* TextField invisível */,
)
```

> Se quiser algo mais simples e só ASCII, dá para usar `KeyboardListener`/`HardwareKeyboard` direto — mas para acentos e teclados internacionais, o caminho do `TextField` é mais seguro.

### ⚠️ Armadilha nº 3 — digitação muito rápida

Ao digitar rápido, o Enter (síncrono) pode "passar na frente" de um caractere ainda na fila de entrada, dessincronizando tudo. No web resolvemos **esvaziando a entrada pendente antes de processar o Enter**. Em Flutter, como o `TextField` entrega o texto de forma consistente, processe primeiro qualquer texto pendente do controller e só então trate o Enter.

### Renderização do código + Pac-Man

- Renderize o código com **`RichText`/`TextSpan`**, colorindo por token (destaque de sintaxe) e diferenciando: já digitado / caractere atual / ainda por digitar.
- O **Pac-Man** fica sobre o caractere atual. Use um `TextPainter` (ou `RenderParagraph`) para obter a posição (offset) do caractere `idx` via `getOffsetForCaret`, e posicione o Pac-Man num `Stack`/`Positioned` ali, animando a posição.
- Anime o "comer" (a boca do Pac-Man) com um `AnimationController` simples.

---

## 6. A prévia Flutter ao vivo

Nos exercícios da trilha **Flutter**, ao concluir o código, mostramos uma **prévia do widget** dentro de uma **moldura de celular**, ao lado do console.

No projeto web isso é feito por um **mini-interpretador** próprio: ele **lê o texto do código** (não compila nada), monta a árvore de widgets e desenha uma **aproximação em HTML/CSS**. Dos 208 exercícios de Flutter, ~**122 renderizam ao vivo** (widgets visuais) e ~**86 viram "cartão de conceito"** (fragmentos sem saída visual — `class extends StatefulWidget`, `setState`, `Navigator.push`, objetos de estilo, variáveis).

### 🎯 A grande vantagem em Flutter

Em Flutter, o mesmo interpretador fica **muito melhor**: em vez de desenhar HTML parecido, ele constrói **widgets Flutter de verdade** a partir do código lido. Resultado: a prévia é Flutter nativo, com as **animações reais** do framework — sem compilar nada, tudo em runtime, disparado quando o usuário termina o código.

Você tem **dois caminhos**:

**A) Interpretador próprio (recomendado, controlado):** porte o parser/renderizador para Dart, mas fazendo o renderizador devolver `Widget`:

```dart
// Node = saída do parser: t ∈ {call, str, num, list, ident, lambda}
Widget construir(Node node, Map<String, Object?> ctx) {
  if (node.t == 'str')  return Text(interp(node.value, ctx));
  if (node.t == 'list') return Column(children: node.items.map((n) => construir(n, ctx)).toList());
  if (node.t != 'call') return const SizedBox.shrink();

  final base = node.name.split('.').first;
  final m = argMap(node);            // args nomeados + posicionais
  Widget? filho() => m['child'] != null ? construir(m['child'] as Node, ctx) : null;
  List<Widget> filhos() => (m['children'] as List<Node>? ?? []).map((n) => construir(n, ctx)).toList();

  switch (base) {
    case 'Text':
      return Text(strOf(m['_pos0']), style: textStyleFrom(m['style']));
    case 'Container':
      return Container(
        width: numOf(m['width']), height: numOf(m['height']),
        color: colorFrom(m['color']),
        padding: edgeFrom(m['padding']),
        alignment: alignFrom(m['alignment']),
        child: filho(),
      );
    case 'Column':
      return Column(
        mainAxisAlignment: mainFrom(m['mainAxisAlignment']),
        crossAxisAlignment: crossFrom(m['crossAxisAlignment']),
        mainAxisSize: MainAxisSize.min,
        children: filhos(),
      );
    case 'Row': /* análogo */ return Row(/* ... */);
    case 'ElevatedButton':
      return ElevatedButton(onPressed: () {}, child: filho() ?? const Text('Botão'));
    case 'Icon':
      return Icon(iconFrom(m['_pos0']), size: numOf(m['size']) ?? 24, color: colorFrom(m['color']));
    case 'AnimatedContainer':
      return _PreviewAnimatedBox(color: colorFrom(m['color']), w: numOf(m['width']), h: numOf(m['height']));
    // ... demais widgets
    default:
      return filho() ?? (filhos().isNotEmpty ? Column(children: filhos()) : const SizedBox.shrink());
  }
}
```

Os "helpers" a portar: `argMap`, `colorFrom` (mapa `Colors.red → Color`), `edgeFrom` (`EdgeInsets.all/symmetric/only`), `textStyleFrom` (`TextStyle`), `mainFrom`/`crossFrom` (enums de alinhamento), `iconFrom` (`Icons.*`), interpolação de string `'$i'`. E, para `ListView.builder`, capture o parâmetro do índice do lambda e gere 2–3 itens de amostra (0, 1, 2).

**Classificação live vs conceito:** se a raiz for um widget "visual" conhecido → renderiza; se for declaração (`class`, `extends`, `@override`) ou fragmento (`TextStyle` solto, `Navigator.*`, `setState`, variável) → mostra um **cartão de conceito** (um mini-diagrama explicando, ex.: `StatefulWidget → State → build()`).

**B) `flutter_eval` / `dart_eval` (pronto):** o pacote **`flutter_eval`** (sobre `dart_eval`) avalia código Flutter em runtime e tem um `CompilerWidget` que compila o código para um bytecode interno e mostra o `Widget` retornado — funciona inclusive na web, sem servidor. É um meio-termo (ele "compila" para bytecode na hora, mas tudo dentro do app). Cobre mais casos que o interpretador próprio, mas não suporta todos os recursos de Flutter/Dart e é mais pesado.

> Como discutido no projeto: **não é compilação de verdade** (nada de servidor tipo DartPad) — é **simulação disparada na conclusão**. Em Flutter, essa simulação vira widget nativo.

### Animações da prévia

Em Flutter isso fica trivial e nativo:

- `AnimatedContainer`, `AnimatedOpacity`, `TweenAnimationBuilder` para os widgets animados.
- **Entrada** (ao compilar, uma vez): anime a lista aparecendo item a item, o diálogo dando "pop", a `AppBar` descendo — com `AnimationController` de duração curta ou `AnimatedSwitcher`.
- **Loop contínuo** (enquanto a prévia está aberta): use `AnimationController(...).repeat(reverse: true)` para o `AnimatedContainer` pulsar, o slider ir e voltar, etc. **Pare o controller** (`dispose`/`stop`) ao trocar de exercício.
- Botões, switches e sliders são widgets Flutter reais → já interativos.

---

## 7. Layout das telas

Coluna central (~980px no desktop; responsiva). De cima para baixo:

1. **Cabeçalho**: título "PAC·DART", estatísticas (pontuação, PPM, precisão, erros, tempo) e toggles (voz, som).
2. **Barra de menu**: dois dropdowns — **Trilha ▾** e **Lição ▾** — cada um abrindo um painel escuro; a lição mostra ✓ nas concluídas e destaca a atual. À direita, contador "Trilha 6/7 · Lição 2/30".
3. **Palco** (cartão):
   - **Dica** do trecho.
   - **Área de digitação**: o código com destaque de sintaxe + o Pac-Man.
   - **Barra de progresso** + botão "Recomeçar".
   - **Prévia** (moldura de celular) — só na trilha Flutter, aparece ao compilar.
   - **Console**: "Digite o código acima para compilar…" → ao concluir, "✓ Compilado com sucesso" + a saída (`out`) + "↵ Enter para o próximo".
4. **Overlay de vitória** ao terminar a lição.

Comportamento importante da prévia: **fica escondida enquanto se digita** e **aparece junto com o console** no momento em que o código compila.

---

## 8. Arquitetura sugerida em Flutter

**Estado:** `provider` ou `flutter_riverpod`. Sugestão de "controllers" (`ChangeNotifier`): `CursoController` (trilha/lição/trecho atuais + progresso), `TypingEngine` (digitação), e a prévia como widget que reage ao trecho atual.

**Pacotes úteis:**
- `provider` **ou** `flutter_riverpod` — estado.
- `google_fonts` — Archivo / JetBrains Mono.
- `flutter_tts` — narração da dica (pt-BR: `setLanguage('pt-BR')`).
- (opcional) `flutter_eval` — prévia "real" alternativa.

**Estrutura de arquivos:**

```
lib/
  main.dart
  models/            trilha.dart · licao.dart · trecho.dart
  data/              curriculo_loader.dart        (lê assets/curriculo.json)
  state/             curso_controller.dart · typing_engine.dart
  interpreter/       tokenizer.dart · parser.dart · widget_builder.dart · helpers.dart
  ui/
    home_screen.dart
    stats_bar.dart
    menu_bar.dart            (dropdowns de trilha/lição)
    code_view.dart           (RichText + destaque + Pac-Man)
    pacman.dart
    preview_panel.dart       (moldura de celular + prévia)
    console_view.dart
    victory_overlay.dart
  theme/             mixart_theme.dart · syntax_colors.dart
assets/
  curriculo.json
  fonts/             (se precisar hospedar "Funnel Display")
```

**Persistência (opcional):** para lembrar lições concluídas e recordes, use `shared_preferences`.

---

## 9. Notas de portabilidade (web → Flutter)

- O currículo já é dado puro → exporte para **JSON** e carregue como asset.
- O motor de digitação porta quase 1:1 (veja §5) — só troque a captura de teclas do `<textarea>` pelo `TextField` invisível + `Focus`.
- O interpretador de prévia **melhora** ao portar: devolve `Widget` real em vez de HTML (veja §6).
- As animações CSS viram **animações nativas** do Flutter (mais simples e mais bonitas).
- O TTS do navegador (Web Speech API) vira **`flutter_tts`**.
- Destaque de sintaxe: reaproveite o **tokenizador** (ele já classifica keyword/tipo/string/número/pontuação/comentário) e mapeie cada tipo para uma cor via `TextSpan`.

---

## 10. Roadmap / extras (ideias)

- Modo **desafio cronometrado** (1 minuto), à la arcade, especialmente para a trilha Desafios.
- **Recordes** e progresso persistente.
- Modo **"cole seu próprio código"** para treinar com qualquer trecho.
- Aumentar a cobertura "ao vivo" da prévia (mais widgets renderizando).
- Barra de status no "celular" (horinha, bateria) para parecer ainda mais um app rodando.
- Sons de arcade opcionais (o "waka-waka" do Pac-Man ao comer letras).

---

### Resumo em uma frase

Um **treinador de digitação que ensina Dart/Flutter**: você digita código real, um Pac-Man come as letras, e ao concluir o trecho ele "compila" — mostrando a saída no console e, nos exercícios Flutter, uma **prévia do widget renderizado** (que em Flutter vira widget nativo com animações reais, tudo por simulação/interpretação, sem compilador).
