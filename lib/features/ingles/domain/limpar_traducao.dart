/// Limpa o texto que um tradutor automático devolve: o MyMemory às vezes manda a tradução com marcas de formatação
/// de memória de tradução (`<g id="1">mas ninguém achava </g>que…`, `<x id="2"/>`) — às vezes até escapadas
/// (`&lt;g id=&quot;1&quot;&gt;`) — e entidades HTML (`&quot;`, `&#39;`). Nada disso é texto: sai tudo,
/// e os espaços que sobram viram um só.
///
/// Só some o que PARECE marca: `<` colado numa letra, `/` ou `!` e fechado por `>` (`<g id="1">`, `</g>`, `<br/>`).
/// "3 < 5 e 7 > 2" e "eu <3 você" ficam como estão.
String limparTraducao(String s) {
  var t = _decodificar(_decodificar(s)); // 2×: "&amp;lt;g&amp;gt;" (escapado duas vezes) também
  t = t.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), ' '); // quebra de linha separa palavras
  t = t.replaceAll(RegExp(r'</?[A-Za-z][^<>]*>|<![^<>]*>'), '');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _decodificar(String s) => s
    .replaceAllMapped(RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)))
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
