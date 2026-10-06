import '../linguagem/linguagem.dart';

/// Tipos de token do destaque de sintaxe.
enum TokenTipo { keyword, ident, literal, punct, comment }

const _keywordsDart = {
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

/// Palavras reservadas + contextuais mais usadas do C#.
const _keywordsCSharp = {
  'abstract', 'as', 'base', 'bool', 'break', 'byte', 'case', 'catch', 'char',
  'checked', 'class', 'const', 'continue', 'decimal', 'default', 'delegate', 'do',
  'double', 'else', 'enum', 'event', 'explicit', 'extern', 'false', 'finally',
  'fixed', 'float', 'for', 'foreach', 'goto', 'if', 'implicit', 'in', 'int',
  'interface', 'internal', 'is', 'lock', 'long', 'namespace', 'new', 'null',
  'object', 'operator', 'out', 'override', 'params', 'private', 'protected',
  'public', 'readonly', 'ref', 'return', 'sbyte', 'sealed', 'short', 'sizeof',
  'stackalloc', 'static', 'string', 'struct', 'switch', 'this', 'throw', 'true',
  'try', 'typeof', 'uint', 'ulong', 'unchecked', 'unsafe', 'ushort', 'using',
  'virtual', 'void', 'volatile', 'while',
  // contextuais
  'add', 'and', 'alias', 'ascending', 'async', 'await', 'by', 'descending',
  'dynamic', 'equals', 'extension', 'field', 'file', 'from', 'get', 'global',
  'group', 'init', 'into', 'join', 'let', 'managed', 'nameof', 'nint', 'not',
  'notnull', 'nuint', 'on', 'or', 'orderby', 'partial', 'record', 'remove',
  'required', 'scoped', 'select', 'set', 'unmanaged', 'value', 'var', 'when',
  'where', 'with', 'yield',
};

final _digito = RegExp(r'\d');
final _numeroDart = RegExp(r'[\dxXa-fA-F_.]');
final _numeroCs = RegExp(r'[\dxXa-fA-F_.mMuUlL]');
final _inicioIdent = RegExp(r'[A-Za-z_$]');
final _restoIdent = RegExp(r'[A-Za-z0-9_$]');
final _inicioIdentCs = RegExp(r'[A-Za-z_@]');
final _restoIdentCs = RegExp(r'[A-Za-z0-9_]');

/// Devolve, para cada caractere do código, o tipo de token dele.
/// (Um tipo por caractere simplifica pintar o texto tecla a tecla.)
///
/// [linguagem] padrão é a vertente em uso ([Linguagem.atual]). [variante]
/// é a linguagem própria do trecho quando não é código do curso (bash,
/// json, xml, sql…) — aí o destaque é genérico: só textos, números e
/// comentários.
List<TokenTipo> tokenizar(String cod, {Linguagem? linguagem, String variante = ''}) {
  if (variante == 'dart') return _dart(cod);
  if (variante == 'cs') return _csharp(cod);
  final lg = linguagem ?? Linguagem.atual;
  // frase em inglês: texto corrido, sem destaque (o apóstrofo de "don't"
  // não abre string nenhuma)
  if (variante == 'en' || (variante.isEmpty && lg == Linguagem.ingles)) {
    return List<TokenTipo>.filled(cod.length, TokenTipo.ident);
  }
  if (variante.isNotEmpty) return _generico(cod, variante);
  return lg == Linguagem.csharp ? _csharp(cod) : _dart(cod);
}

void _marca(List<TokenTipo> tipos, int ini, int fim, TokenTipo t) {
  for (var k = ini; k < fim && k < tipos.length; k++) {
    tipos[k] = t;
  }
}

List<TokenTipo> _dart(String cod) {
  final tipos = List<TokenTipo>.filled(cod.length, TokenTipo.punct);
  var i = 0;

  while (i < cod.length) {
    final c = cod[i];

    // comentário de linha
    if (c == '/' && i + 1 < cod.length && cod[i + 1] == '/') {
      var f = cod.indexOf('\n', i);
      if (f == -1) f = cod.length;
      _marca(tipos, i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    // comentário de bloco
    if (c == '/' && i + 1 < cod.length && cod[i + 1] == '*') {
      var f = cod.indexOf('*/', i + 2);
      f = f == -1 ? cod.length : f + 2;
      _marca(tipos, i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    // string raw: r'...'
    if (c == 'r' && i + 1 < cod.length && (cod[i + 1] == "'" || cod[i + 1] == '"')) {
      final q = cod[i + 1];
      var f = cod.indexOf(q, i + 2);
      f = f == -1 ? cod.length : f + 1;
      _marca(tipos, i, f, TokenTipo.literal);
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
      _marca(tipos, i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    // números (inclui 0xFF e 1_000)
    if (_digito.hasMatch(c)) {
      var f = i;
      while (f < cod.length && _numeroDart.hasMatch(cod[f])) {
        f++;
      }
      _marca(tipos, i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    // identificadores / palavras-chave
    if (_inicioIdent.hasMatch(c)) {
      var f = i;
      while (f < cod.length && _restoIdent.hasMatch(cod[f])) {
        f++;
      }
      final palavra = cod.substring(i, f);
      _marca(tipos, i, f, _keywordsDart.contains(palavra) ? TokenTipo.keyword : TokenTipo.ident);
      i = f;
      continue;
    }
    // espaço em branco herda "punct" (não é pintado)
    i++;
  }
  return tipos;
}

/// Fim de um literal de string/char do C# que começa em [i] (com prefixos
/// `$`/`@`), ou o fim do código se não fechar. Buracos de interpolação com
/// strings dentro (`$"{(ok ? "sim" : "não")}"`) são respeitados.
int _fimLiteralCs(String s, int i) {
  final n = s.length;
  var j = i;
  var interp = false, verbatim = false;
  while (j < n && (s[j] == r'$' || s[j] == '@')) {
    if (s[j] == r'$') interp = true;
    if (s[j] == '@') verbatim = true;
    j++;
  }
  if (j >= n) return n;
  if (s[j] == "'") {
    var k = j + 1;
    while (k < n) {
      if (s[k] == r'\') {
        k += 2;
        continue;
      }
      if (s[k] == "'" || s[k] == '\n') return k + 1;
      k++;
    }
    return n;
  }
  if (s[j] != '"') return j + 1;
  // raw string: 3 ou mais aspas
  var aspas = 0;
  while (j + aspas < n && s[j + aspas] == '"') {
    aspas++;
  }
  if (aspas >= 3) {
    final fecho = '"' * aspas;
    final k = s.indexOf(fecho, j + aspas);
    return k == -1 ? n : k + aspas;
  }
  if (aspas == 2 && !verbatim) return j + 2; // ""
  var p = j + 1;
  while (p < n) {
    final c = s[p];
    if (verbatim) {
      if (c == '"') {
        if (p + 1 < n && s[p + 1] == '"') {
          p += 2;
          continue;
        }
        return p + 1;
      }
    } else {
      if (c == r'\') {
        p += 2;
        continue;
      }
      if (c == '"') return p + 1;
      if (c == '\n') return p;
    }
    if (interp && c == '{') {
      if (p + 1 < n && s[p + 1] == '{') {
        p += 2;
        continue;
      }
      var prof = 1;
      p++;
      while (p < n && prof > 0) {
        final d = s[p];
        final prefixo = (d == r'$' || d == '@') &&
            p + 1 < n &&
            (s[p + 1] == '"' || s[p + 1] == r'$' || s[p + 1] == '@');
        if (d == '"' || d == "'" || prefixo) {
          p = _fimLiteralCs(s, p);
          continue;
        }
        if (d == '{') prof++;
        if (d == '}') prof--;
        p++;
      }
      continue;
    }
    p++;
  }
  return n;
}

List<TokenTipo> _csharp(String cod) {
  final tipos = List<TokenTipo>.filled(cod.length, TokenTipo.punct);
  var i = 0;
  var inicioLinha = true;
  while (i < cod.length) {
    final c = cod[i];
    if (c == '\n') {
      inicioLinha = true;
      i++;
      continue;
    }
    if (c == ' ') {
      i++;
      continue;
    }
    // diretiva de pré-processador (#region, #nullable, #if…)
    if (inicioLinha && c == '#') {
      var f = cod.indexOf('\n', i);
      if (f == -1) f = cod.length;
      _marca(tipos, i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    inicioLinha = false;
    if (c == '/' && i + 1 < cod.length && cod[i + 1] == '/') {
      var f = cod.indexOf('\n', i);
      if (f == -1) f = cod.length;
      _marca(tipos, i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    if (c == '/' && i + 1 < cod.length && cod[i + 1] == '*') {
      var f = cod.indexOf('*/', i + 2);
      f = f == -1 ? cod.length : f + 2;
      _marca(tipos, i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    final prefixoString = (c == r'$' || c == '@') &&
        i + 1 < cod.length &&
        (cod[i + 1] == '"' || cod[i + 1] == r'$' || cod[i + 1] == '@');
    if (c == '"' || c == "'" || prefixoString) {
      final f = _fimLiteralCs(cod, i);
      _marca(tipos, i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    if (_digito.hasMatch(c)) {
      var f = i;
      while (f < cod.length && _numeroCs.hasMatch(cod[f])) {
        f++;
      }
      _marca(tipos, i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    if (_inicioIdentCs.hasMatch(c)) {
      var f = i + 1;
      while (f < cod.length && _restoIdentCs.hasMatch(cod[f])) {
        f++;
      }
      final palavra = cod.substring(i, f);
      _marca(tipos, i, f, _keywordsCSharp.contains(palavra) ? TokenTipo.keyword : TokenTipo.ident);
      i = f;
      continue;
    }
    i++;
  }
  return tipos;
}

/// Destaque mínimo para bash/json/xml/sql/yaml…: textos entre aspas,
/// números e comentários (`#` em bash/yaml/dockerfile, `--` em sql,
/// `//` nos demais).
List<TokenTipo> _generico(String cod, String variante) {
  final tipos = List<TokenTipo>.filled(cod.length, TokenTipo.ident);
  final comentarioHash = const {'bash', 'yaml', 'dockerfile', 'texto'}.contains(variante);
  var i = 0;
  while (i < cod.length) {
    final c = cod[i];
    final ehComentario = (comentarioHash && c == '#') ||
        (variante == 'sql' && c == '-' && i + 1 < cod.length && cod[i + 1] == '-') ||
        (!comentarioHash && variante != 'sql' && c == '/' && i + 1 < cod.length && cod[i + 1] == '/');
    if (ehComentario) {
      var f = cod.indexOf('\n', i);
      if (f == -1) f = cod.length;
      _marca(tipos, i, f, TokenTipo.comment);
      i = f;
      continue;
    }
    if (c == '"' || c == "'") {
      var f = cod.indexOf(c, i + 1);
      final quebra = cod.indexOf('\n', i + 1);
      if (f == -1 || (quebra != -1 && quebra < f)) f = quebra == -1 ? cod.length - 1 : quebra - 1;
      _marca(tipos, i, f + 1, TokenTipo.literal);
      i = f + 1;
      continue;
    }
    if (_digito.hasMatch(c)) {
      var f = i;
      while (f < cod.length && _numeroDart.hasMatch(cod[f])) {
        f++;
      }
      _marca(tipos, i, f, TokenTipo.literal);
      i = f;
      continue;
    }
    if (c == ' ' || c == '\n') {
      tipos[i] = TokenTipo.punct;
    } else if (const {'{', '}', '[', ']', ':', ',', '<', '>', '=', '/', '(', ')', ';'}.contains(c)) {
      tipos[i] = TokenTipo.punct;
    }
    i++;
  }
  return tipos;
}
