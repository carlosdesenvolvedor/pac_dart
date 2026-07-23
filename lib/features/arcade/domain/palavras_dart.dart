// Vocabulário digitável do Dart/Flutter para os jogos de digitação
// (Chuva de Código e Rali). Só letras [A-Za-z] — nada de acento/símbolo —
// e com maiúsculas reais (Dart é case-sensitive: String, ListView…).
import 'dart:math';

/// 3–5 letras (nível 1).
const List<String> palavrasCurtas = [
  'var', 'int', 'num', 'bool', 'for', 'new', 'try', 'set', 'get', 'add',
  'Map', 'Set', 'else', 'null', 'void', 'main', 'late', 'enum', 'this',
  'class', 'final', 'const', 'await', 'async', 'print', 'while', 'break',
  'super', 'throw', 'yield', 'List', 'Text', 'Row', 'Icon', 'true', 'false',
  'catch', 'mixin', 'trim', 'join', 'split', 'where', 'build', 'State',
];

/// 6–8 letras (nível 2).
const List<String> palavrasMedias = [
  'return', 'double', 'String', 'import', 'export', 'static', 'switch',
  'extends', 'dynamic', 'Future', 'Stream', 'Widget', 'Column', 'Center',
  'Padding', 'Scaffold', 'setState', 'context', 'required', 'finally',
  'typedef', 'override', 'isEmpty', 'length', 'toList', 'forEach', 'Colors',
  'AppBar', 'runApp', 'Expanded', 'ListView', 'SizedBox', 'dispose',
  'abstract', 'continue',
];

/// 9+ letras (nível 3 — os chefões).
const List<String> palavrasLongas = [
  'implements', 'Container', 'Navigator', 'TextField', 'initState',
  'Alignment', 'MaterialApp', 'BuildContext', 'BoxDecoration',
  'FutureBuilder', 'StreamBuilder', 'ValueNotifier', 'StatefulWidget',
  'StatelessWidget', 'GestureDetector',
];

/// Baralho do Rali: curtas e médias embaralhadas; [comLongas] entra nas
/// fases altas (StatelessWidget e companhia são os chefões).
List<String> baralhoRali(Random rnd, {bool comLongas = false}) =>
    [...palavrasCurtas, ...palavrasMedias, if (comLongas) ...palavrasLongas]
      ..shuffle(rnd);
