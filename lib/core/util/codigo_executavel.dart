/// Transforma o trecho de um exercício (que é um FRAGMENTO — uma linha, uma
/// classe, um statement solto) num programa que **roda de verdade** no DartPad
/// ou numa IDE.
///
/// Os trechos do currículo não são programas: falta `main()`, faltam imports,
/// falta o que veio antes na lição (`p.x = 5;` só vive depois de
/// `var p = Ponto();`) e às vezes falta o próprio dado (`nums.length` sem
/// nunca dizer o que é `nums`). Então aqui a gente:
///
///  1. traz do [contexto] (trechos anteriores da lição) só o que o trecho cita;
///  2. separa declaração de topo (classe/enum/função) de comando (vai no `main`);
///  3. **completa o que falta** — declara os nomes citados e nunca definidos,
///     deduzindo pelo uso (`.length` → lista, `> 0` → número…), sempre marcado
///     com `// ←` para ninguém confundir com o exercício;
///  4. liga os imports necessários;
///  5. no Flutter: widget vira tela; comando que precisa de `context`
///     (showDialog, Navigator, SnackBar) vira botão; `setState` ganha um
///     StatefulWidget em volta.
library;

/// Trilhas cujo conteúdo é Flutter (UI) e não Dart de console.
const _trilhasFlutter = {
  'Flutter',
  'Navegação',
  'Animações',
  'Layout Pro',
  'Formulários e Gestos',
  'Estado Avançado',
  'UI e Material 3',
  'Cupertino iOS',
  'Widgets Avançados',
  'Ciclo de Vida',
  'i18n e Acessibilidade',
};

bool ehTrilhaFlutter(String nivel) => _trilhasFlutter.contains(nivel);

final _marcasFlutter = RegExp(
    r'\b(Widget|StatelessWidget|StatefulWidget|BuildContext|Scaffold|MaterialApp|'
    r'AppBar|Container|Column|Row|Center|Padding|Text|Icon|runApp|showDialog|'
    r'Navigator|ScaffoldMessenger|setState|TextStyle|EdgeInsets|Colors|Theme|'
    r'ListView|SizedBox|ElevatedButton|TextButton|Card|Image|State<)\b');

/// O código tem cara de Flutter mesmo que a trilha não seja "Flutter"?
bool pareceFlutter(String cod) => _marcasFlutter.hasMatch(cod);

/// Comandos que só existem dentro de um `BuildContext` — viram botão.
final _precisaContexto = RegExp(
    r'\b(showDialog|showModalBottomSheet|showBottomSheet|showSnackBar|showMenu|'
    r'showDatePicker|showTimePicker|showAboutDialog|Navigator\s*\.|ScaffoldMessenger\s*\.|'
    r'FocusScope\s*\.|Scaffold\s*\.of|Theme\s*\.of|MediaQuery\s*\.of)');

final _declaracaoTopo = RegExp(
    r'^(@\w+\s+)?(abstract\s+|base\s+|final\s+|sealed\s+|interface\s+)*'
    r'(class|enum|mixin|extension|typedef)\b');

/// Assinatura de função de topo: `void nome(...) {`, `Widget build(...) =>`…
final _funcaoTopo = RegExp(
    r'^(@override\s+)?[\w<>,\s\[\]?]+\s+\w+\s*\([^)]*\)\s*(async\s*\*?\s*)?[{=]');

final _temMain = RegExp(r'\bmain\s*\(');
final _linhaImport = RegExp(r'^\s*(import|export|part)\s+[^\n]*;', multiLine: true);

/// Marca do que o PAC·DART inventou para o programa fechar.
const _marca = ' // ← completado para rodar';

String codigoExecutavel(String cod, bool flutter, {List<String> contexto = const []}) {
  final base = cod.trim();
  if (base.isEmpty) return 'void main() {}';

  final ehFlutter = flutter || pareceFlutter(base) || contexto.any(pareceFlutter);
  if (_temMain.hasMatch(base)) return _comImports(base, ehFlutter);

  final pecas = [..._apoioNecessario(base, contexto), _remendaFragmento(base)];

  // imports que vierem DENTRO do trecho sobem para o topo do arquivo
  final importes = <String>[];
  final limpas = <String>[];
  for (final p in pecas) {
    var c = p;
    for (final m in _linhaImport.allMatches(p)) {
      importes.add(m.group(0)!.trim());
    }
    c = c.replaceAll(_linhaImport, '').trim();
    if (c.isNotEmpty) limpas.add(c);
  }

  final topo = <String>[];
  final comandos = <String>[];
  for (final p in limpas) {
    (_ehDeclaracaoTopo(p) ? topo : comandos).add(_semOverrideSolto(p));
  }

  var programa =
      ehFlutter ? _montaFlutter(topo, comandos, base) : _montaDart(topo, comandos);
  programa = _completaFaltando(programa, ehFlutter);
  if (importes.isNotEmpty) programa = '${importes.toSet().join('\n')}\n\n$programa';
  return _comImports(programa, ehFlutter);
}

// ───────────────────────── contexto da lição ─────────────────────────

Iterable<String> _nomesDefinidos(String cod) sync* {
  for (final m in RegExp(r'\b(?:class|enum|mixin|extension|typedef)\s+(\w+)').allMatches(cod)) {
    yield m.group(1)!;
  }
  for (final m in RegExp(r'\b(?:var|final|const|late)\s+(?:\w+\s+)?(\w+)\s*[=;]').allMatches(cod)) {
    yield m.group(1)!;
  }
  for (final m in RegExp(r'^[\w<>,\s\[\]?]+?\s+(\w+)\s*\(', multiLine: true).allMatches(cod)) {
    yield m.group(1)!;
  }
}

List<String> _apoioNecessario(String alvo, List<String> contexto) {
  if (contexto.isEmpty) return const [];
  final escolhidos = <String>{};
  var procurando = _identificadores(alvo);
  final jaDefinidos = _nomesDefinidos(alvo).toSet();

  for (var volta = 0; volta < 3; volta++) {
    final novos = <String>[];
    for (final c in contexto) {
      if (escolhidos.contains(c)) continue;
      final definidos = _nomesDefinidos(c).toSet();
      if (definidos.isEmpty) continue;
      if (definidos.any((d) => procurando.contains(d) && !jaDefinidos.contains(d))) {
        novos.add(c);
        jaDefinidos.addAll(definidos);
      }
    }
    if (novos.isEmpty) break;
    escolhidos.addAll(novos);
    procurando = novos.expand(_identificadores).toSet();
  }
  return contexto.where(escolhidos.contains).toList();
}

/// Trechos que são PEDAÇO de construção (`case >= 90:`, `on X catch (e) {`,
/// `if (v case int n) {`, chamada cortada no meio) não fecham sozinhos —
/// aqui a gente completa o que falta para virar código válido.
String _remendaFragmento(String cod) {
  var c = cod.trim();

  // membro de classe solto no topo
  c = c.replaceFirst(RegExp(r'^static\s+'), '');

  // braço de switch sem switch
  if (RegExp(r'^(case\b|default\s*:)').hasMatch(c)) {
    c = 'switch (valor) {\n${_indenta(c, 2)}\n}';
  }
  // captura sem try
  if (RegExp(r'^(on\s+\w+|catch\s*\()').hasMatch(c)) {
    c = 'try {\n} $c';
  }
  // else sem if
  if (RegExp(r'^else\b').hasMatch(c)) c = 'if (false) {\n} $c';

  return _fecha(c);
}

/// Fecha parênteses/colchetes/chaves que ficaram abertos (fora de texto).
String _fecha(String cod) {
  final pilha = <String>[];
  var emTexto = '';
  for (var i = 0; i < cod.length; i++) {
    final ch = cod[i];
    if (emTexto.isNotEmpty) {
      if (ch == emTexto && (i == 0 || cod[i - 1] != r'\')) emTexto = '';
      continue;
    }
    if (ch == "'" || ch == '"') {
      emTexto = ch;
    } else if (ch == '(' || ch == '[' || ch == '{') {
      pilha.add(ch);
    } else if (ch == ')' || ch == ']' || ch == '}') {
      if (pilha.isNotEmpty) pilha.removeLast();
    }
  }
  if (pilha.isEmpty) return cod;
  final fim = StringBuffer(cod.trimRight());
  // vírgula pendurada antes do fecha-parêntese atrapalha menos que faltar
  for (final abre in pilha.reversed) {
    fim.write(switch (abre) { '(' => ')', '[' => ']', _ => '\n}' });
  }
  return fim.toString();
}

Set<String> _identificadores(String cod) =>
    RegExp(r'\b[A-Za-z_]\w*\b').allMatches(cod).map((m) => m.group(0)!).toSet();

bool _ehDeclaracaoTopo(String cod) {
  final c = cod.trim();
  if (_declaracaoTopo.hasMatch(c)) return true;
  if (c.startsWith('return') || c.startsWith('await')) return false;
  return _funcaoTopo.hasMatch(c);
}

String _semOverrideSolto(String cod) =>
    cod.replaceFirst(RegExp(r'^@override\s*\n?'), '').trim();

// ───────────────────────── montagem Dart ─────────────────────────

String _montaDart(List<String> topo, List<String> comandos) {
  final corpo = [...comandos];
  final usaAwait = corpo.any((c) => c.contains('await '));

  if (!corpo.any((c) => c.contains('print('))) {
    final mostrar = <String>[];
    for (final c in corpo) {
      for (final m in RegExp(r'\b(?:var|final|const)\s+(?:\w+\s+)?(\w+)\s*=').allMatches(c)) {
        mostrar.add(m.group(1)!);
      }
      for (final m in RegExp(r'^(?:int|double|String|bool|num)\s+(\w+)\s*=', multiLine: true)
          .allMatches(c)) {
        mostrar.add(m.group(1)!);
      }
    }
    for (final v in mostrar.toSet()) {
      corpo.add("print('$v = \$$v');$_marca");
    }
  }

  final dentro = corpo.map((c) => _indenta(c, 2)).join('\n');
  final cabeca = usaAwait ? 'Future<void> main() async {' : 'void main() {';
  final antes = topo.isEmpty ? '' : '${topo.join('\n\n')}\n\n';
  return '$antes$cabeca\n$dentro\n}';
}

// ───────────────────────── montagem Flutter ─────────────────────────

/// Expressão que dá para pendurar como filho de um widget?
final _comecaWidget = RegExp(r'^(const\s+)?[A-Z]\w*(<[^>]*>)?\s*[(.]');

String _montaFlutter(List<String> topo, List<String> comandos, String base) {
  final antes = topo.isEmpty ? '' : '${topo.join('\n\n')}\n\n';
  final alvo = comandos.isEmpty ? '' : comandos.last;
  final apoio = comandos.length > 1 ? comandos.sublist(0, comandos.length - 1) : const <String>[];

  // 1) setState só existe dentro de um State → monta um StatefulWidget
  if (alvo.contains('setState')) {
    return '$antes${_telaComEstado(alvo)}';
  }

  // 2) ação que precisa de context → botão que dispara
  if (alvo.isNotEmpty && _precisaContexto.hasMatch(alvo)) {
    final acao = alvo.endsWith(';') || alvo.endsWith('}') ? alvo : '$alvo;';
    final assinc = acao.contains('await ') ? 'onPressed: () async {' : 'onPressed: () {';
    return '$antes'
        'void main() => runApp(\n'
        '  MaterialApp(\n'
        '    debugShowCheckedModeBanner: false,\n'
        '    home: Scaffold(\n'
        "      appBar: AppBar(title: const Text('Toque para rodar o trecho')),\n"
        '      body: Center(\n'
        '        child: Builder(\n'
        '          builder: (context) => ElevatedButton(\n'
        '            $assinc\n'
        '${_indenta(acao, 14)}\n'
        '            },\n'
        "            child: const Text('Rodar o trecho'),\n"
        '          ),\n'
        '        ),\n'
        '      ),\n'
        '    ),\n'
        '  ),\n'
        ');';
  }

  // 3) o próprio trecho já chama runApp
  if (alvo.startsWith('runApp')) {
    return '${antes}void main() {\n${_indenta(alvo.endsWith(';') ? alvo : '$alvo;', 2)}\n}';
  }

  // 4) declarou um widget → mostra esse widget
  final classeWidget = _primeiraClasseWidget(topo);
  if (classeWidget != null && (alvo.isEmpty || _ehDeclaracaoTopo(base))) {
    return '$antes'
        'void main() => runApp(\n'
        '  MaterialApp(debugShowCheckedModeBanner: false, home: $classeWidget()),\n'
        ');';
  }

  // 5) função build de topo → vira a tela
  if (alvo.isEmpty && topo.any((t) => RegExp(r'\bWidget\s+build\s*\(').hasMatch(t))) {
    return '$antes'
        'void main() => runApp(\n'
        '  MaterialApp(\n'
        '    debugShowCheckedModeBanner: false,\n'
        '    home: Builder(builder: (context) => build(context)),\n'
        '  ),\n'
        ');';
  }

  // 6) expressão de widget → vira a tela; o resto vira comando antes do runApp
  final expr = _semPontoEVirgula(alvo);
  final ehWidget = expr.isNotEmpty && _comecaWidget.hasMatch(expr);
  final widget = ehWidget ? expr : 'const Text(\'trecho executado\')$_marca';
  final extrasLista = ehWidget ? apoio : [...apoio, if (alvo.isNotEmpty) _comoComando(alvo)];
  final extras =
      extrasLista.isEmpty ? '' : '${extrasLista.map((c) => _indenta(c, 2)).join('\n')}\n';
  final ehTela = RegExp(r'^(const\s+)?(Scaffold|MaterialApp|CupertinoApp|CupertinoPageScaffold)\b')
      .hasMatch(widget);
  final home =
      ehTela ? widget : 'Scaffold(\n      body: SafeArea(\n        child: $widget,\n      ),\n    )';

  if (extras.isEmpty) {
    return '$antes'
        'void main() => runApp(\n'
        '  MaterialApp(\n'
        '    debugShowCheckedModeBanner: false,\n'
        '    home: $home,\n'
        '  ),\n'
        ');';
  }
  return '$antes'
      'void main() {\n'
      '$extras'
      '  runApp(\n'
      '    MaterialApp(\n'
      '      debugShowCheckedModeBanner: false,\n'
      '      home: ${home.replaceAll('\n    ', '\n      ')},\n'
      '    ),\n'
      '  );\n'
      '}';
}

String _telaComEstado(String acao) {
  final corpo = acao.endsWith(';') || acao.endsWith('}') ? acao : '$acao;';
  return 'void main() => runApp(const MaterialApp(\n'
      '  debugShowCheckedModeBanner: false,\n'
      '  home: TelaDemo(),\n'
      '));\n'
      '\n'
      'class TelaDemo extends StatefulWidget {$_marca\n'
      '  const TelaDemo({super.key});\n'
      '  @override\n'
      '  State<TelaDemo> createState() => _TelaDemoState();\n'
      '}\n'
      '\n'
      'class _TelaDemoState extends State<TelaDemo> {\n'
      '  int contador = 0;\n'
      '\n'
      '  void rodarTrecho() {\n'
      '${_indenta(corpo, 4)}\n'
      '  }\n'
      '\n'
      '  @override\n'
      '  Widget build(BuildContext context) => Scaffold(\n'
      "        appBar: AppBar(title: const Text('Toque para rodar o trecho')),\n"
      '        body: Center(\n'
      '          child: ElevatedButton(\n'
      '            onPressed: rodarTrecho,\n'
      "            child: Text('contador = \$contador'),\n"
      '          ),\n'
      '        ),\n'
      '      );\n'
      '}';
}

String _comoComando(String cod) {
  final c = cod.trim();
  if (c.endsWith(';') || c.endsWith('}')) return c;
  return '$c;';
}

String _semPontoEVirgula(String cod) {
  var c = cod.trim();
  while (c.endsWith(';')) {
    c = c.substring(0, c.length - 1).trimRight();
  }
  return c;
}

String? _primeiraClasseWidget(List<String> topo) {
  for (final t in topo) {
    final m = RegExp(r'class\s+(\w+)\s+extends\s+(StatelessWidget|StatefulWidget)').firstMatch(t);
    if (m != null) return m.group(1);
  }
  return null;
}

String _indenta(String cod, int espacos) =>
    cod.split('\n').map((l) => l.isEmpty ? l : '${' ' * espacos}$l').join('\n');

// ───────────────────────── completar o que falta ─────────────────────────

/// Palavras que nunca são "variável faltando".
const _reservadas = {
  'abstract', 'as', 'assert', 'async', 'await', 'base', 'break', 'case', 'catch',
  'class', 'const', 'continue', 'covariant', 'default', 'deferred', 'do', 'dynamic',
  'else', 'enum', 'export', 'extends', 'extension', 'external', 'factory', 'false',
  'final', 'finally', 'for', 'get', 'hide', 'if', 'implements', 'import', 'in',
  'interface', 'is', 'late', 'library', 'mixin', 'new', 'null', 'on', 'operator',
  'part', 'required', 'rethrow', 'return', 'sealed', 'set', 'show', 'static', 'super',
  'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var', 'void', 'when',
  'while', 'with', 'yield',
  // tipos e globais que já existem
  'int', 'double', 'num', 'bool', 'String', 'List', 'Map', 'Set', 'Object', 'Iterable',
  'Future', 'Stream', 'Duration', 'DateTime', 'RegExp', 'Uri', 'Symbol', 'Type',
  'print', 'main', 'identical', 'runApp', 'debugPrint', 'context', 'setState',
  'jsonEncode', 'jsonDecode', 'utf8', 'base64', 'sqrt', 'pow', 'min', 'max', 'sin',
  'cos', 'tan', 'pi', 'e', 'log', 'exp', 'value', 'child', 'children', 'builder',
};

/// Tira strings e comentários (mas guarda as interpolações `$nome`).
String _semTextoLiteral(String cod) {
  final interpoladas = <String>[];
  for (final m in RegExp(r'\$\{?([A-Za-z_]\w*)').allMatches(cod)) {
    interpoladas.add(m.group(1)!);
  }
  var limpo = cod
      .replaceAll(RegExp(r'//[^\n]*'), ' ')
      .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), ' ')
      .replaceAll(RegExp(r"'''.*?'''", dotAll: true), " '' ")
      .replaceAll(RegExp(r'""".*?"""', dotAll: true), ' "" ')
      .replaceAll(RegExp(r"'(\\.|[^'\\])*'"), " '' ")
      .replaceAll(RegExp(r'"(\\.|[^"\\])*"'), ' "" ');
  if (interpoladas.isNotEmpty) limpo = '$limpo ${interpoladas.join(' ')}';
  return limpo;
}

/// Nomes que o programa já tem (declarações, parâmetros, laços, captura).
Set<String> _jaExistem(String limpo) {
  final nomes = <String>{};
  void add(RegExp re, [int grupo = 1]) {
    for (final m in re.allMatches(limpo)) {
      final g = m.group(grupo);
      if (g != null) nomes.add(g);
    }
  }

  add(RegExp(r'\b(?:class|enum|mixin|extension|typedef)\s+(\w+)'));
  add(RegExp(r'\b(?:var|final|const|late)\s+(?:[\w<>,\s\[\]?]+\s+)??(\w+)\s*[=;,)]'));
  add(RegExp(r'\b(?:int|double|num|bool|String|List|Map|Set|Object|dynamic|Widget|Future|Stream)'
      r'(?:<[^>]*>)?\??\s+(\w+)\s*[=;,)]'));
  add(RegExp(r'^[\w<>,\s\[\]?]+?\s+(\w+)\s*\(', multiLine: true)); // funções
  add(RegExp(r'\bfor\s*\(\s*(?:var|final)?\s*(?:\w+\s+)?(\w+)\s+in\b'));
  add(RegExp(r'\bcatch\s*\(\s*(\w+)'));
  add(RegExp(r'\bget\s+(\w+)'));

  // parâmetros de função/lambda: cada pedaço dentro de ( ... )
  for (final m in RegExp(r'\(([^()]*)\)').allMatches(limpo)) {
    for (final parte in m.group(1)!.split(',')) {
      final p = parte.trim();
      if (p.isEmpty || p.contains('.') || p.contains('=>')) continue;
      final id = RegExp(r'([A-Za-z_]\w*)\s*$').firstMatch(p);
      if (id != null) nomes.add(id.group(1)!);
    }
  }
  return nomes;
}

/// Declara o que o trecho cita e ninguém definiu, deduzindo pelo uso.
String _completaFaltando(String programa, bool ehFlutter) {
  final limpo = _semTextoLiteral(programa);
  final existentes = _jaExistem(limpo);

  final usados = <String>{};
  // `.membro`, `$interpolado`, `@anotacao` e `nomeado:` não são variáveis soltas
  for (final m in RegExp(r'(^|[^\w.$@])([a-z_]\w*)\s*(:?)').allMatches(limpo)) {
    final nome = m.group(2)!;
    if (m.group(3) == ':') continue;
    if (_reservadas.contains(nome) || existentes.contains(nome)) continue;
    usados.add(nome);
  }
  if (usados.isEmpty) return programa;

  final novas = <String>[];
  for (final nome in usados) {
    novas.add(_declaracaoPara(nome, limpo, ehFlutter));
  }
  novas.sort();
  return '${novas.join('\n')}\n\n$programa';
}

String _declaracaoPara(String nome, String limpo, bool ehFlutter) {
  bool usa(String padrao) => RegExp(padrao.replaceAll('#', RegExp.escape(nome))).hasMatch(limpo);

  // se o trecho ATRIBUI ao nome, não pode ser `final`
  final mutavel = usa(r'#\s*(=[^=]|\+\+|--|\+=|-=)');
  String decl(String tipoValor) =>
      '${mutavel ? 'var' : 'final'} $nome = $tipoValor;$_marca';

  // função: `nome(` — devolve algo plausível pelo contexto
  if (usa(r'\b#\s*\(')) {
    final args = RegExp('\\b${RegExp.escape(nome)}\\s*\\(([^()]*)\\)').firstMatch(limpo)?.group(1) ?? '';
    final qtd = args.trim().isEmpty ? 0 : args.split(',').length;
    final params = List.generate(qtd, (i) => 'dynamic a$i').join(', ');
    if (usa(r'(future|stream)\s*:\s*#\s*\(') || usa(r'await\s+#\s*\(')) {
      return 'Future<String> $nome($params) async => \'ok\';$_marca';
    }
    return 'dynamic $nome($params) => 0;$_marca';
  }
  // lista: `.length`, `.map(`, `for (x in nome)`, `nome[`
  if (usa(r'#\s*\.\s*(length|map|where|forEach|first|last|isEmpty|isNotEmpty|reduce|fold|any|every|contains|sort|add|remove|join|toList|take|skip|expand|indexOf|reversed)') ||
      usa(r'in\s+#\b') ||
      usa(r'#\s*\[')) {
    if (usa(r"#\s*\[\s*''")) return decl("{'a': 1, 'b': 2}");
    return decl('[1, 2, 3]');
  }
  // texto
  if (usa(r'#\s*\.\s*(toUpperCase|toLowerCase|split|trim|substring|startsWith|endsWith|replaceAll|padLeft|padRight|codeUnits|characters)') ||
      usa(r"#\s*\?\?\s*''")) {
    return "${mutavel ? 'String?' : 'final String?'} $nome = 'exemplo';$_marca";
  }
  // registro: `nome case (var a, var b)`
  if (usa(r'#\s+case\s*\(')) return decl('(1, 2)');
  // número: comparação/aritmética
  if (usa(r'#\s*[<>+\-*/%]') || usa(r'[<>+\-*/%]\s*#\b') || usa(r'#\s*\.\s*(toDouble|toInt|abs|round|floor|ceil|toStringAsFixed)')) {
    return decl('10');
  }
  // widget/controller do Flutter
  if (ehFlutter && usa(r'#\s*\.\s*(dispose|addListener|animateTo|jumpTo|forward|reverse)')) {
    return decl('ValueNotifier<int>(0)');
  }
  return 'dynamic $nome;$_marca';
}

// ───────────────────────── imports ─────────────────────────

String _comImports(String programa, bool ehFlutter) {
  final imports = <String>[];
  if (ehFlutter && !programa.contains('package:flutter/material.dart')) {
    imports.add("import 'package:flutter/material.dart';");
  }
  if (ehFlutter &&
      RegExp(r'\bCupertino\w+\b').hasMatch(programa) &&
      !programa.contains('package:flutter/cupertino.dart')) {
    imports.add("import 'package:flutter/cupertino.dart';");
  }
  if (RegExp(r'\b(Random|pi|sqrt|pow|max|min|sin|cos|tan)\s*[(.)]').hasMatch(programa) &&
      !programa.contains('dart:math')) {
    imports.add("import 'dart:math';");
  }
  if (RegExp(r'\b(jsonEncode|jsonDecode|json\.|utf8|base64)\b').hasMatch(programa) &&
      !programa.contains('dart:convert')) {
    imports.add("import 'dart:convert';");
  }
  if (RegExp(r'\b(Timer|StreamController|Completer|scheduleMicrotask)\b').hasMatch(programa) &&
      !programa.contains('dart:async')) {
    imports.add("import 'dart:async';");
  }
  if (imports.isEmpty) return programa;
  return '${imports.join('\n')}\n\n$programa';
}
