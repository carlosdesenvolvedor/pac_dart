/// Mini-parser de expressões de widget Flutter (subset).
/// Lê o texto do exercício e monta uma árvore de [Node]; nada é compilado.
library;

class Node {
  final String t; // call | str | num | bool | ident | list | lambda
  final String name; // call/ident: nome pontuado (ex.: EdgeInsets.all)
  final String s; // str: conteúdo sem aspas
  final double n; // num
  final bool b; // bool
  final List<Node> pos; // args posicionais / itens da lista
  final Map<String, Node> named; // args nomeados
  final List<String> params; // lambda
  final Node? corpo; // lambda

  const Node._({
    required this.t,
    this.name = '',
    this.s = '',
    this.n = 0,
    this.b = false,
    this.pos = const [],
    this.named = const {},
    this.params = const [],
    this.corpo,
  });

  factory Node.str(String v) => Node._(t: 'str', s: v);
  factory Node.num(double v) => Node._(t: 'num', n: v);
  factory Node.boolean(bool v) => Node._(t: 'bool', b: v);
  factory Node.ident(String nome) => Node._(t: 'ident', name: nome);
  factory Node.lista(List<Node> itens) => Node._(t: 'list', pos: itens);
  factory Node.lambda(List<String> params, Node? corpo) =>
      Node._(t: 'lambda', params: params, corpo: corpo);
  factory Node.call(String nome, List<Node> pos, Map<String, Node> named) =>
      Node._(t: 'call', name: nome, pos: pos, named: named);

  /// Nome-base da chamada: `ListView.builder` → `ListView`.
  String get base => name.split('.').first;
}

class ParseException implements Exception {}

class _Tok {
  final String t; // id | num | str | sym
  final String v;
  const _Tok(this.t, this.v);
}

List<_Tok> _lex(String src) {
  final toks = <_Tok>[];
  var i = 0;
  while (i < src.length) {
    final c = src[i];
    if (c == ' ' || c == '\n' || c == '\t' || c == '\r') {
      i++;
      continue;
    }
    if (c == '/' && i + 1 < src.length && src[i + 1] == '/') {
      final f = src.indexOf('\n', i);
      i = f == -1 ? src.length : f;
      continue;
    }
    if (c == "'" || c == '"') {
      var f = i + 1;
      final sb = StringBuffer();
      while (f < src.length && src[f] != c) {
        if (src[f] == r'\' && f + 1 < src.length) {
          sb.write(src[f + 1]);
          f += 2;
          continue;
        }
        sb.write(src[f]);
        f++;
      }
      toks.add(_Tok('str', sb.toString()));
      i = f + 1;
      continue;
    }
    if (RegExp(r'[0-9]').hasMatch(c) ||
        (c == '.' && i + 1 < src.length && RegExp(r'[0-9]').hasMatch(src[i + 1]))) {
      var f = i;
      while (f < src.length && RegExp(r'[0-9._]').hasMatch(src[f])) {
        f++;
      }
      toks.add(_Tok('num', src.substring(i, f).replaceAll('_', '')));
      i = f;
      continue;
    }
    if (RegExp(r'[A-Za-z_$]').hasMatch(c)) {
      var f = i;
      while (f < src.length && RegExp(r'[A-Za-z0-9_$]').hasMatch(src[f])) {
        f++;
      }
      toks.add(_Tok('id', src.substring(i, f)));
      i = f;
      continue;
    }
    if (c == '=' && i + 1 < src.length && src[i + 1] == '>') {
      toks.add(const _Tok('sym', '=>'));
      i += 2;
      continue;
    }
    toks.add(_Tok('sym', c));
    i++;
  }
  return toks;
}

class _Parser {
  final List<_Tok> toks;
  int p = 0;
  _Parser(this.toks);

  _Tok get cur => p < toks.length ? toks[p] : const _Tok('sym', '');
  bool ehSym(String v) => cur.t == 'sym' && cur.v == v;
  void espera(String v) {
    if (!ehSym(v)) throw ParseException();
    p++;
  }

  Node expr() {
    var n = _primary();
    // ignora cadeias após a chamada (ex.: `.copyWith(...)`)
    while (ehSym('.') && n.t == 'call') {
      p++; // .
      if (cur.t != 'id') throw ParseException();
      p++;
      if (ehSym('(')) _pulaBalanceado('(', ')');
    }
    return n;
  }

  Node _primary() {
    if (cur.t == 'id' && cur.v == 'const') {
      p++;
      return _primary();
    }
    if (cur.t == 'str') {
      final v = cur.v;
      p++;
      return Node.str(v);
    }
    if (cur.t == 'num') {
      final v = double.parse(cur.v);
      p++;
      return Node.num(v);
    }
    if (cur.t == 'id' && (cur.v == 'true' || cur.v == 'false')) {
      final v = cur.v == 'true';
      p++;
      return Node.boolean(v);
    }
    if (ehSym('-') ) {
      p++;
      final n = _primary();
      if (n.t != 'num') throw ParseException();
      return Node.num(-n.n);
    }
    if (ehSym('[')) {
      p++;
      final itens = <Node>[];
      while (!ehSym(']')) {
        itens.add(expr());
        if (ehSym(',')) p++;
      }
      p++;
      return Node.lista(itens);
    }
    if (ehSym('(')) return _lambda();
    if (cur.t == 'id') return _chamada();
    throw ParseException();
  }

  Node _lambda() {
    espera('(');
    final params = <String>[];
    while (!ehSym(')')) {
      if (cur.t == 'id') params.add(cur.v);
      p++;
    }
    p++; // )
    if (ehSym('=>')) {
      p++;
      final corpo = expr();
      return Node.lambda(params, corpo);
    }
    if (ehSym('{')) {
      // bloco: procura um `return <expr>` dentro dele
      final ini = p;
      _pulaBalanceado('{', '}');
      final fim = p;
      for (var k = ini; k < fim; k++) {
        if (toks[k].t == 'id' && toks[k].v == 'return') {
          final sub = _Parser(toks.sublist(k + 1, fim - 1));
          try {
            return Node.lambda(params, sub.expr());
          } on ParseException {
            break;
          }
        }
      }
      return Node.lambda(params, null);
    }
    throw ParseException();
  }

  Node _chamada() {
    final nome = StringBuffer(cur.v);
    p++;
    while (ehSym('.') && p + 1 < toks.length && toks[p + 1].t == 'id') {
      // só continua o nome pontuado se não for início de chamada encadeada
      nome.write('.${toks[p + 1].v}');
      p += 2;
    }
    if (!ehSym('(')) return Node.ident(nome.toString());
    p++; // (
    final pos = <Node>[];
    final named = <String, Node>{};
    while (!ehSym(')')) {
      if (cur.t == 'id' && p + 1 < toks.length && toks[p + 1].t == 'sym' && toks[p + 1].v == ':') {
        final chave = cur.v;
        p += 2;
        named[chave] = expr();
      } else {
        pos.add(expr());
      }
      if (ehSym(',')) p++;
    }
    p++; // )
    return Node.call(nome.toString(), pos, named);
  }

  void _pulaBalanceado(String abre, String fecha) {
    espera(abre);
    var depth = 1;
    while (p < toks.length && depth > 0) {
      if (ehSym(abre)) depth++;
      if (ehSym(fecha)) depth--;
      p++;
    }
  }
}

/// Tenta extrair e parsear a expressão do widget-raiz a partir de [offset].
Node parseWidget(String cod, int offset) {
  final toks = _lex(cod.substring(offset));
  final parser = _Parser(toks);
  final n = parser.expr();
  if (n.t != 'call') throw ParseException();
  return n;
}
