/// Monta um programa C# a partir dos trechos de um exercício — o que o
/// botão "copiar" entrega no PAC·C#.
///
/// Os trechos de uma lição C# foram escritos e VALIDADOS (compilados com o
/// Roslyn no laboratório do currículo) para formar, em ordem, um programa
/// só. A regra da montagem é a mesma do laboratório (Montador.cs):
///
///  1. `using` sobe para o topo (sem repetir);
///  2. comandos soltos (top-level statements) ficam na ordem em que
///     aparecem;
///  3. declarações de tipo (class, record, struct, interface, enum,
///     delegate, namespace) vão para o FIM — o C# exige que os comandos
///     venham antes dos tipos no Program.cs;
///  4. `namespace X;` (de arquivo) vira `namespace X { … }` em volta dos
///     tipos daquele trecho.
///
/// Se mudar a regra aqui, mude também no laboratório — senão o botão copia
/// um programa diferente do que foi compilado.
library;

// `\w` do .NET aceita letras acentuadas; o do Dart, só ASCII. Para a regra
// ser IDÊNTICA à do Montador.cs, os "\w" daqui são a classe Unicode abaixo.
const _w = r'[\p{L}\p{Mn}\p{Nd}\p{Pc}]';
final _reUsing = RegExp('^(global\\s+)?using\\s+(static\\s+)?[A-Za-z_](?:$_w|\\.)*\\s*;\\s*(//.*)?\$', unicode: true);
final _reUsingAlias = RegExp('^(global\\s+)?using\\s+[A-Za-z_]$_w*\\s*=\\s*[^;]+;\\s*(//.*)?\$', unicode: true);
final _reNamespaceArquivo = RegExp('^namespace\\s+[A-Za-z_](?:$_w|\\.)*\\s*;\\s*(//.*)?\$', unicode: true);
final _reNamespaceBloco = RegExp('^namespace\\s+[A-Za-z_](?:$_w|\\.)*\\s*(\\{.*)?\$', unicode: true);
final _reTipo = RegExp(
    r'^((public|internal|private|protected|file|abstract|sealed|static|partial|readonly|ref|unsafe|new)\s+)*'
    r'(class|struct|interface|enum|delegate)\b');
final _reRecord = RegExp(
    '^((public|internal|private|protected|file|abstract|sealed|static|partial|readonly|ref|unsafe|new)\\s+)*'
    'record\\s+((struct|class)\\s+)?[A-Za-z_]$_w*',
    unicode: true);
final _reContinuaBloco = RegExp(r'^(else|catch|finally|while)\b');
final _reComentarioFim = RegExp(r'\s*//.*$');

enum _Tipo { using, namespace, tipo, comando }

class _Pedaco {
  final _Tipo tipo;
  final List<String> linhas;
  _Pedaco(this.tipo, this.linhas);
}

/// Estado do scanner entre linhas (literal multilinha e comentário de bloco).
class _Scanner {
  int profundidade = 0;
  bool emComentario = false;
  bool emLiteral = false;
  String fecho = '';
  bool verbatim = false;
}

/// Fim de um literal (string/char) que começa em [i]; `null` se atravessa a linha.
int? _pularLiteral(String s, int i) {
  final n = s.length;
  var j = i;
  var dolares = 0;
  var verb = false;
  while (j < n && (s[j] == r'$' || s[j] == '@')) {
    if (s[j] == r'$') dolares++;
    if (s[j] == '@') verb = true;
    j++;
  }
  if (j >= n) return null;
  if (s[j] == "'") {
    var k = j + 1;
    while (k < n) {
      if (s[k] == r'\') {
        k += 2;
        continue;
      }
      if (s[k] == "'") return k + 1;
      k++;
    }
    return n;
  }
  if (s[j] != '"') return j + 1;
  var aspas = 0;
  while (j + aspas < n && s[j + aspas] == '"') {
    aspas++;
  }
  if (aspas >= 3) {
    final k = s.indexOf('"' * aspas, j + aspas);
    if (k < 0) return null;
    var fim = k + aspas;
    while (fim < n && s[fim] == '"') {
      fim++;
    }
    return fim;
  }
  if (aspas == 2 && !verb) return j + 2;
  var p = j + 1;
  final interp = dolares > 0;
  while (p < n) {
    final c = s[p];
    if (verb) {
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
          final f = _pularLiteral(s, p);
          if (f == null) return null;
          p = f;
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
  return verb ? null : n;
}

/// Atualiza a profundidade de chaves e devolve o último caractere
/// significativo da linha (fora de texto e comentário).
String _analisarLinha(String linha, _Scanner sc) {
  var ultimo = '';
  var i = 0;
  final n = linha.length;
  if (sc.emLiteral) {
    if (sc.verbatim) {
      var k = -1;
      for (var q = 0; q < n; q++) {
        if (linha[q] == '"') {
          if (q + 1 < n && linha[q + 1] == '"') {
            q++;
            continue;
          }
          k = q;
          break;
        }
      }
      if (k < 0) return '';
      sc.emLiteral = false;
      i = k + 1;
    } else {
      final k = linha.indexOf(sc.fecho);
      if (k < 0) return '';
      sc.emLiteral = false;
      i = k + sc.fecho.length;
      while (i < n && linha[i] == '"') {
        i++;
      }
    }
    ultimo = '"';
  }
  while (i < n) {
    final c = linha[i];
    if (sc.emComentario) {
      final k = linha.indexOf('*/', i);
      if (k < 0) return ultimo;
      sc.emComentario = false;
      i = k + 2;
      continue;
    }
    if (c == '/' && i + 1 < n && linha[i + 1] == '/') break;
    if (c == '/' && i + 1 < n && linha[i + 1] == '*') {
      sc.emComentario = true;
      i += 2;
      continue;
    }
    final prefixo = (c == r'$' || c == '@') &&
        i + 1 < n &&
        (linha[i + 1] == '"' || linha[i + 1] == r'$' || linha[i + 1] == '@');
    if (c == '"' || c == "'" || prefixo) {
      final fim = _pularLiteral(linha, i);
      if (fim == null) {
        var j = i;
        var verb = false;
        while (j < n && (linha[j] == r'$' || linha[j] == '@')) {
          if (linha[j] == '@') verb = true;
          j++;
        }
        var aspas = 0;
        while (j + aspas < n && linha[j + aspas] == '"') {
          aspas++;
        }
        if (aspas >= 3) {
          sc
            ..emLiteral = true
            ..fecho = '"' * aspas
            ..verbatim = false;
        } else if (verb) {
          sc
            ..emLiteral = true
            ..fecho = '"'
            ..verbatim = true;
        }
        return '"';
      }
      i = fim;
      ultimo = '"';
      continue;
    }
    if (c == '{') sc.profundidade++;
    if (c == '}') sc.profundidade--;
    if (c.trim().isNotEmpty) ultimo = c;
    i++;
  }
  return ultimo;
}

bool _neutra(String t) =>
    t.isEmpty || t.startsWith('//') || t.startsWith('#') || t.startsWith('/*') || t.startsWith('*');

bool _atributo(String t) => t.startsWith('[') && t.endsWith(']');

_Pedaco _classificar(List<String> linhas) {
  var primeira = '';
  for (final l in linhas) {
    final t = l.trim();
    if (_neutra(t) || _atributo(t)) continue;
    primeira = t;
    break;
  }
  final _Tipo tipo;
  if (_reUsing.hasMatch(primeira) || _reUsingAlias.hasMatch(primeira)) {
    tipo = _Tipo.using;
  } else if (_reNamespaceArquivo.hasMatch(primeira)) {
    tipo = _Tipo.namespace;
  } else if (_reNamespaceBloco.hasMatch(primeira) || _reTipo.hasMatch(primeira) || _reRecord.hasMatch(primeira)) {
    tipo = _Tipo.tipo;
  } else {
    tipo = _Tipo.comando;
  }
  return _Pedaco(tipo, List.of(linhas));
}

List<_Pedaco> _fatiar(String cod) {
  final linhas = cod.replaceAll('\r\n', '\n').split('\n');
  final pedacos = <_Pedaco>[];
  var atual = <String>[];
  final sc = _Scanner();
  for (var li = 0; li < linhas.length; li++) {
    final linha = linhas[li];
    atual.add(linha);
    final ultimo = _analisarLinha(linha, sc);
    if (sc.emLiteral || sc.emComentario || sc.profundidade != 0) continue;
    if (ultimo != ';' && ultimo != '}') continue;
    var prox = '';
    for (var k = li + 1; k < linhas.length; k++) {
      final t = linhas[k].trim();
      if (t.isEmpty || t.startsWith('//')) continue;
      prox = t;
      break;
    }
    if (ultimo == '}' && _reContinuaBloco.hasMatch(prox)) continue;
    if (ultimo == '}' &&
        (prox.startsWith('.') || prox.startsWith(')') || prox.startsWith(',') || prox.startsWith(';'))) {
      continue;
    }
    pedacos.add(_classificar(atual));
    atual = [];
  }
  if (atual.isNotEmpty && !(atual.every((l) => l.trim().isEmpty) && pedacos.isNotEmpty)) {
    pedacos.add(_classificar(atual));
  }
  return pedacos;
}

/// Usings que o `dotnet new console` liga sozinho (ImplicitUsings).
const usingsImplicitos = [
  'System',
  'System.Collections.Generic',
  'System.IO',
  'System.Linq',
  'System.Net.Http',
  'System.Threading',
  'System.Threading.Tasks',
];

/// O programa C# (Program.cs) formado pelos [trechos], na ordem.
///
/// Com [paraSharpLab], vira um programa que roda no SharpLab (que não tem
/// ImplicitUsings nem a cultura do seu PC): os usings implícitos entram no
/// topo e, havendo comandos, a 1ª linha põe a cultura em pt-BR — assim a
/// saída bate com o console do app (R$ 12,50, e não $12.50).
String programaCSharp(List<String> trechos, {bool paraSharpLab = false}) {
  final usings = <String>[];
  final vistos = <String>{};
  if (paraSharpLab) {
    for (final u in usingsImplicitos) {
      usings.add('using $u;');
      vistos.add('using $u;');
    }
  }
  final comandos = <String>[];
  final tipos = <String>[];
  for (final cod in trechos) {
    var abriuNs = false;
    for (final p in _fatiar(cod)) {
      switch (p.tipo) {
        case _Tipo.using:
          for (final l in p.linhas) {
            final t = l.trim();
            if (t.isEmpty) continue;
            if (vistos.add(t.replaceAll(_reComentarioFim, ''))) usings.add(t);
          }
        case _Tipo.namespace:
          if (abriuNs) tipos.add('}');
          final ns = p.linhas.firstWhere((l) => l.trim().startsWith('namespace')).trim();
          tipos
            ..add(ns.substring(0, ns.lastIndexOf(';')).trim())
            ..add('{');
          abriuNs = true;
        case _Tipo.tipo:
          tipos.addAll(p.linhas);
        case _Tipo.comando:
          (abriuNs ? tipos : comandos).addAll(p.linhas);
      }
    }
    if (abriuNs) tipos.add('}');
  }
  final b = StringBuffer();
  for (final u in usings) {
    b.writeln(u);
  }
  if (usings.isNotEmpty) b.writeln();
  if (paraSharpLab && comandos.any((c) => !_neutra(c.trim()))) {
    b
      ..writeln('System.Globalization.CultureInfo.CurrentCulture = new("pt-BR"); // como no seu PC')
      ..writeln();
  }
  for (final c in comandos) {
    b.writeln(c);
  }
  if (comandos.isNotEmpty && tipos.isNotEmpty) b.writeln();
  for (final t in tipos) {
    b.writeln(t);
  }
  return b.toString();
}

/// Como rodar o código copiado, conforme o perfil da trilha.
String comoRodarCSharp(String perfil) => switch (perfil) {
      'web' => 'Cole no Program.cs de um projeto "dotnet new web" e rode com "dotnet run".',
      'testes' => 'Cole num arquivo de um projeto "dotnet new xunit" e rode com "dotnet test".',
      'biblioteca' => 'Cole num arquivo .cs de um projeto "dotnet new classlib".',
      'unity' => 'Cole num script C# do Unity (Assets > Create > MonoBehaviour Script).',
      'godot' => 'Cole num script C# do Godot 4 (anexado a um nó da cena).',
      'monogame' => 'Cole num projeto MonoGame ("dotnet new mgdesktopgl").',
      _ => 'Cole no Program.cs de um projeto "dotnet new console" e rode com "dotnet run".',
    };

/// Os [trechos] têm algum comando para executar (top-level statements)?
/// Lição só de tipos (classes, records…) não tem o que "rodar".
bool temComandosCSharp(List<String> trechos) =>
    trechos.any((cod) => _fatiar(cod).any((p) => p.tipo == _Tipo.comando && p.linhas.any((l) => !_neutra(l.trim()))));
