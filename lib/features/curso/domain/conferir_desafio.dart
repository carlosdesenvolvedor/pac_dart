import 'curriculo.dart';

/// Regras de correção dos desafios de lógica — puras, para testar sem tela.

String _normal(String s) =>
    s.replaceAll(' ', ' ').replaceAll('\r\n', '\n').replaceAll(RegExp(r'[ \t]+'), ' ').trim();

String _semAspas(String s) {
  if (s.length >= 2 &&
      ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'")))) {
    return s.substring(1, s.length - 1);
  }
  return s;
}

double? _numero(String s) {
  final limpo = s.replaceAll(' ', '');
  if (!RegExp(r'^-?\d+([.,]\d+)?$').hasMatch(limpo)) return null;
  return double.tryParse(limpo.replaceAll(',', '.'));
}

/// A resposta digitada confere com o gabarito do desafio `valor`?
/// Aceita vírgula ou ponto nos números (o C# em pt-BR imprime 7,5), True/true
/// nos booleanos e texto com ou sem aspas. Texto continua sensível a
/// maiúsculas — em C# "Ana" e "ana" são diferentes.
bool confereValor(String digitado, DesafioLogica d) {
  final x = _semAspas(_normal(digitado));
  if (x.isEmpty) return false;
  for (final alvo in [d.resposta, ...d.aceitas]) {
    final y = _semAspas(_normal(alvo));
    if (y.isEmpty) continue;
    if (x == y) return true;
    if ((y == 'True' || y == 'False') && x.toLowerCase() == y.toLowerCase()) return true;
    final nx = _numero(x), ny = _numero(y);
    if (nx != null && ny != null && (nx - ny).abs() < 1e-9) return true;
  }
  return false;
}

/// A ordem montada confere? Compara o TEXTO dos cartões (cartões iguais,
/// como dois `}`, podem trocar entre si).
bool confereOrdem(List<String> montada, DesafioLogica d) {
  if (montada.length != d.linhas.length) return false;
  for (var i = 0; i < montada.length; i++) {
    if (montada[i].trim() != d.linhas[i].trim()) return false;
  }
  return true;
}

/// Rótulo curto do tipo, para o chip do cartão.
String rotuloTipo(TipoDesafioLogica t) => switch (t) {
      TipoDesafioLogica.saida => 'Qual é a saída?',
      TipoDesafioLogica.valor => 'Valor final',
      TipoDesafioLogica.lacuna => 'Complete a lacuna',
      TipoDesafioLogica.ordenar => 'Ponha em ordem',
      TipoDesafioLogica.bug => 'Ache o bug',
      TipoDesafioLogica.escolha => 'Conceito',
    };
