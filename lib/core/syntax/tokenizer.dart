/// Tipos de token do destaque de sintaxe.
enum TokenTipo { keyword, ident, literal, punct, comment }

const _keywords = {
  'abstract', 'as', 'assert', 'async', 'await', 'base', 'bool', 'break', 'case',
  'catch', 'class', 'const', 'continue', 'covariant', 'default', 'deferred',
  'do', 'double', 'dynamic', 'else', 'enum', 'export', 'extends', 'extension',
  'external', 'factory', 'false', 'final', 'finally', 'for', 'get', 'hide',
  'if', 'implements', 'import', 'in', 'int', 'interface', 'is', 'late',
  'library', 'mixin', 'new', 'null', 'num', 'on', 'operator', 'part',
  'required', 'rethrow', 'return', 'sealed', 'set', 'show', 'static', 'super',
  'switch', 'sync', 'this', 'throw', 'true', 'try', 'typedef', 'var', 'void',
  'when', 'while', 'with', 'yield', 'String', 'Object', 'override',
};

/// Devolve, para cada caractere do código, o tipo de token dele.
/// (Um tipo por caractere simplifica pintar o texto tecla a tecla.)
List<TokenTipo> tokenizar(String cod) {
  final tipos = List<TokenTipo>.filled(cod.length, TokenTipo.punct);
  var i = 0;

  void marca(int ini, int fim, TokenTipo t) {
    for (var k = ini; k < fim && k < cod.length; k++) {
      tipos[k] = t;
    }
  }

  while (i < cod.length) {
    final c = cod[i];

    // comentário de linha
    if (c == '/' && i + 1 < cod.length && cod[i + 1] == '/') {
      var f = cod.indexOf('\n', i);
      if (f == -1) f = cod.length;
      marca(i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    // comentário de bloco
    if (c == '/' && i + 1 < cod.length && cod[i + 1] == '*') {
      var f = cod.indexOf('*/', i + 2);
      f = f == -1 ? cod.length : f + 2;
      marca(i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    // string raw: r'...'
    if (c == 'r' && i + 1 < cod.length && (cod[i + 1] == "'" || cod[i + 1] == '"')) {
      final q = cod[i + 1];
      var f = cod.indexOf(q, i + 2);
      f = f == -1 ? cod.length : f + 1;
      marca(i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    // strings (' " e ''' )
    if (c == "'" || c == '"') {
      var f = i + 1;
      final tripla = cod.startsWith(c * 3, i);
      final fecho = tripla ? c * 3 : c;
      f = i + fecho.length;
      while (f < cod.length) {
        if (cod[f] == r'\' && !tripla) {
          f += 2;
          continue;
        }
        if (cod.startsWith(fecho, f)) {
          f += fecho.length;
          break;
        }
        f++;
      }
      marca(i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    // números (inclui 0xFF e 1_000)
    if (RegExp(r'\d').hasMatch(c)) {
      var f = i;
      while (f < cod.length && RegExp(r'[\dxXa-fA-F_.]').hasMatch(cod[f])) {
        f++;
      }
      marca(i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    // identificadores / palavras-chave
    if (RegExp(r'[A-Za-z_$]').hasMatch(c)) {
      var f = i;
      while (f < cod.length && RegExp(r'[A-Za-z0-9_$]').hasMatch(cod[f])) {
        f++;
      }
      final palavra = cod.substring(i, f);
      marca(i, f, _keywords.contains(palavra) ? TokenTipo.keyword : TokenTipo.ident);
      i = f;
      continue;
    }
    // espaço em branco herda "punct" (não é pintado)
    i++;
  }
  return tipos;
}
