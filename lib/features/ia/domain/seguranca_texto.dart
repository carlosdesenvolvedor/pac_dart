import 'package:equatable/equatable.dart';

/// A fala do aluno como vai ao modelo: dados pessoais óbvios trocados por marcadores.
class TextoMascarado extends Equatable {
  /// O que vai ao modelo.
  final String texto;

  /// Os originais que foram trocados, em ordem.
  final List<String> trechos;

  const TextoMascarado(this.texto, [this.trechos = const []]);

  @override
  List<Object?> get props => [texto, trechos];
}

/// Os marcadores que a máscara põe no lugar dos dados.
const marcadorEmail = '[email]', marcadorLink = '[link]', marcadorNumero = '[número]';

// e-mail | URL | um número "de telefone" (dígitos com espaço, traço, ponto ou parênteses entre eles).
final _padrao = RegExp(
  r'([A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)*\.[A-Za-z]{2,})'
  r'|((?:https?://|www\.)[^\s<>"]+)'
  r'|((?<![\w@])(?:\+\s?)?\(?\d+(?:[ ().-]{1,3}\d+)*\)?)',
  caseSensitive: false,
);

/// Número em formato de milhar: "120.000", "120,000", "1,200,000".
final _milhar = RegExp(r'^\d{1,3}([.,]\d{3})+$');

/// Moeda logo antes: "$", "R$", "US$", "€".
final _moedaAntes = RegExp(r'(?:\$|€)\s*$');

/// O que sobra no fim de uma URL e não é dela ("veja www.x.com." → o ponto fica fora).
final _caudaUrl = RegExp(r'''[.,;:!?)\]}'"]+$''');

/// O que vai ao modelo nunca leva dado pessoal óbvio. Só estes padrões:
/// - e-mail → [email]; URL (http(s):// ou www.) → [link];
/// - CPF: ddd.ddd.ddd-dd, ou 11 dígitos seguidos → [número];
/// - telefone: + opcional, dígitos com espaços/traços/pontos/parênteses entre eles, 8 ou mais dígitos
///   no total, com pelo menos um separador ou o + na frente (ou 8+ dígitos seguidos) → [número].
/// NÃO mascara: valores com $, R$, US$ ou € antes (ou k/K depois); números no formato de milhar
/// (^\d{1,3}([.,]\d{3})+$, ex. "120.000", "120,000", "1,200,000"); "120 000"; números curtos
/// ("3 nights", "room 204", "2026", "8:30").
TextoMascarado mascarar(String t) {
  final trechos = <String>[];
  final b = StringBuffer();
  var pos = 0;
  for (final m in _padrao.allMatches(t)) {
    b.write(t.substring(pos, m.start));
    pos = m.end;
    final todo = m.group(0)!;
    if (m.group(1) != null) {
      trechos.add(todo);
      b.write(marcadorEmail);
    } else if (m.group(2) != null) {
      final cauda = _caudaUrl.firstMatch(todo)?.group(0) ?? '';
      final url = todo.substring(0, todo.length - cauda.length);
      if (url.length <= 4) {
        b.write(todo); // "www." solto não é link
        continue;
      }
      trechos.add(url);
      b.write('$marcadorLink$cauda');
    } else {
      final (antes, numero, depois) = _aparar(todo);
      if (_ehDadoPessoal(numero, t.substring(0, m.start + antes.length), t.substring(m.end - depois.length))) {
        trechos.add(numero);
        b.write('$antes$marcadorNumero$depois');
      } else {
        b.write(todo);
      }
    }
  }
  b.write(t.substring(pos));
  return TextoMascarado(b.toString(), trechos);
}

/// Tira das pontas o que não fecha: "(" sem ")" no começo, ")" sem "(" no fim e o espaço depois do "+".
(String, String, String) _aparar(String s) {
  var antes = '', depois = '', n = s;
  int abre(String x) => '('.allMatches(x).length;
  int fecha(String x) => ')'.allMatches(x).length;
  if (n.endsWith(')') && fecha(n) > abre(n)) {
    depois = ')';
    n = n.substring(0, n.length - 1);
  }
  if (n.startsWith('(') && abre(n) > fecha(n)) {
    antes = '(';
    n = n.substring(1);
  }
  return (antes, n, depois);
}

bool _ehDadoPessoal(String numero, String textoAntes, String textoDepois) {
  final digitos = numero.replaceAll(RegExp(r'\D'), '').length;
  if (digitos < 8) return false;
  if (_moedaAntes.hasMatch(textoAntes)) return false;
  if (RegExp(r'^[kK](?![A-Za-z])').hasMatch(textoDepois)) return false;
  if (_milhar.hasMatch(numero)) return false;
  if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(numero)) return false; // data ISO, não telefone
  return true;
}

/// Usado pelo histórico.
String mascararDadosPessoais(String t) => mascarar(t).texto;

/// O tipo de um trecho guardado (para voltar no marcador certo).
String _marcadorDe(String trecho) {
  if (trecho.contains('@')) return marcadorEmail;
  final l = trecho.toLowerCase();
  if (l.startsWith('http') || l.startsWith('www.')) return marcadorLink;
  return marcadorNumero;
}

/// Põe os [trechos] de volta no lugar dos marcadores, em ordem (o `interpretar` usa em melhor/pt).
/// Cada marcador recebe o próximo original do mesmo tipo; marcador sem original sobrando fica como está.
String restaurarDados(String t, List<String> trechos) {
  if (trechos.isEmpty) return t;
  final filas = <String, List<String>>{};
  for (final tr in trechos) {
    filas.putIfAbsent(_marcadorDe(tr), () => []).add(tr);
  }
  final usados = <String, int>{};
  return t.replaceAllMapped(RegExp(r'\[(?:email|link|número)\]'), (m) {
    final tipo = m.group(0)!;
    final fila = filas[tipo] ?? const <String>[];
    final i = usados[tipo] ?? 0;
    if (i >= fila.length) return tipo;
    usados[tipo] = i + 1;
    return fila[i];
  });
}

/// Tem algum marcador da máscara?
bool temMarcadorDeDados(String t) => RegExp(r'\[(?:email|link|número)\]').hasMatch(t);

/// Tira marcadores forjados do texto do aluno (`<<<ALUNO>>>`, `<<<FIM>>>` e qualquer `<<<…>>>`).
String semMarcadores(String t) => t
    .replaceAll(RegExp(r'<{3,}[^<>]*>{3,}'), ' ')
    .replaceAll(RegExp(r'<{3,}|>{3,}'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
