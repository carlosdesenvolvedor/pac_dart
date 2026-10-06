// Vocabulário digitável do C#/.NET para os jogos de digitação (Chuva de
// Código, Rali e Turismo) quando a vertente é o PAC·C#. Só letras [A-Za-z]
// — nada de acento/símbolo — e com as maiúsculas reais (C# diferencia
// maiúsculas: string é palavra-chave, String é o tipo; Console, List…).
import 'dart:math';

import '../../../core/linguagem/linguagem.dart';
import 'palavras_dart.dart';
import 'palavras_ingles.dart';

/// 3–5 letras (nível 1).
const List<String> palavrasCurtasCs = [
  'var', 'int', 'new', 'for', 'try', 'get', 'set', 'out', 'ref', 'Any',
  'Func', 'else', 'bool', 'char', 'byte', 'long', 'enum', 'null', 'true',
  'void', 'this', 'base', 'case', 'goto', 'lock', 'init', 'List', 'Task', 'Math',
  'class', 'const', 'false', 'float', 'while', 'break', 'catch', 'throw', 'using', 'await',
  'async', 'yield', 'event', 'Where', 'Count', 'Parse', 'Add', 'Sum', 'Max', 'Min',
];

/// 6–8 letras (nível 2).
const List<String> palavrasMediasCs = [
  'string', 'double', 'decimal', 'return', 'switch', 'static', 'public', 'private',
  'object', 'struct', 'record', 'sealed', 'params', 'typeof', 'nameof', 'foreach',
  'virtual', 'finally', 'default', 'dynamic', 'partial', 'required', 'abstract', 'override',
  'readonly', 'internal', 'Console', 'Select', 'OrderBy', 'GroupBy', 'ToList', 'Result',
  'String', 'Action', 'Length', 'Dispose', 'TryParse', 'Update', 'Vector', 'Invoke',
];

/// 9+ letras (nível 3 — os chefões).
const List<String> palavrasLongasCs = [
  'namespace', 'interface', 'protected', 'Dictionary', 'WriteLine', 'ReadLine',
  'Exception', 'StringBuilder', 'IEnumerable', 'MonoBehaviour', 'Transform', 'DbContext',
  'Controller', 'Middleware', 'Repository', 'Interlocked', 'CancellationToken',
  'ServiceCollection', 'FirstOrDefault', 'ConfigureAwait', 'IDisposable', 'Quaternion',
];

/// As três faixas do vocabulário da linguagem [l] (padrão: a vertente em uso).
({List<String> curtas, List<String> medias, List<String> longas}) vocabularioDe([Linguagem? l]) =>
    switch (l ?? Linguagem.atual) {
      Linguagem.csharp => (curtas: palavrasCurtasCs, medias: palavrasMediasCs, longas: palavrasLongasCs),
      Linguagem.ingles => (curtas: palavrasCurtasEn, medias: palavrasMediasEn, longas: palavrasLongasEn),
      Linguagem.dart => (curtas: palavrasCurtas, medias: palavrasMedias, longas: palavrasLongas),
    };

/// Baralho do Rali na vertente em uso (as longas entram nas fases altas).
List<String> baralhoRaliDe(Random rnd, {bool comLongas = false, Linguagem? linguagem}) {
  final v = vocabularioDe(linguagem);
  return [...v.curtas, ...v.medias, if (comLongas) ...v.longas]..shuffle(rnd);
}
