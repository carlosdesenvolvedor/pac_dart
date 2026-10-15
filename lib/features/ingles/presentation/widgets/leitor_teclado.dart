import 'package:flutter/widgets.dart';

/// Lê o que o teclado escreve no campo invisível da frase e entrega o que
/// importa: tecla a tecla ([aoDigitar]) ou, no celular, a FRASE ditada
/// ([aoDitar]).
///
/// Por que não basta olhar o texto quando a composição acaba (o que o
/// campo fazia): o Gboard e outros teclados de Android mantêm a palavra que
/// está sendo digitada como TEXTO EM COMPOSIÇÃO (a que aparece sublinhada) até
/// o espaço. Esperar o fim dela = o Pac-Man só anda palavra a palavra, o erro
/// só aparece no espaço e o som de cada letra some. Aqui a composição de
/// letras é lida ao vivo, pela diferença para o que já foi lido. Esperam
/// o fim da composição só dois casos:
///  - a tecla morta sozinha (´ ~ ^ ` ' " …), que ainda vai se fundir à letra
///    seguinte (á, ã, ç do US-Internacional) — como sempre foi;
///  - várias palavras de uma vez, que é ditado em andamento (o reconhecedor
///    do teclado reescreve o que já pôs): vale o texto final.
class LeitorTeclado {
  /// Uma tecla (um caractere) digitada.
  final void Function(String ch) aoDigitar;

  /// Uma frase inteira chegou de uma vez (ditado pelo microfone do teclado,
  /// colar, sugestão em bloco). Só no celular — no computador, texto que chega
  /// junto continua valendo tecla a tecla.
  final void Function(String frase)? aoDitar;

  LeitorTeclado({required this.aoDigitar, this.aoDitar});

  /// O texto do campo que já foi entregue (a composição vai crescendo: só o
  /// que é novo, depois do que já foi lido, conta como tecla).
  String _lido = '';

  /// O campo foi esvaziado (ou trocou de frase): recomeça do zero.
  void zerar() => _lido = '';

  /// A frase mudou com o campo ainda em composição (o teclado segue com a
  /// palavra que a pessoa não terminou): o que já está nele não vale de
  /// novo para a frase seguinte.
  void esquecer(String textoDoCampo) => _lido = textoDoCampo;

  /// Lê o valor atual do campo. true = nada pendente, o campo pode ser
  /// esvaziado; false = ainda em composição, não mexa nele.
  bool ler(TextEditingValue v) {
    final t = v.text;
    final c = v.composing;
    if (c.isValid && !c.isCollapsed && c.end <= t.length) {
      final composto = c.textInside(t);
      if (composto.length == 1 && !_alfanumerico(composto)) return false; // tecla morta
      if (_espaco.hasMatch(composto.trim())) return false; // ditado em andamento
      _entregar(t);
      return false;
    }
    if (t.isEmpty) {
      _lido = '';
      return false;
    }
    _entregar(t);
    return true;
  }

  /// Espaço entre palavras (o ditado separa com espaço; tab e quebra de linha não são frase).
  static final _espaco = RegExp(r'[ \u00A0]');

  static bool _alfanumerico(String s) => RegExp(r'[A-Za-z0-9]').hasMatch(s);

  void _entregar(String t) {
    var p = 0;
    final max = _lido.length < t.length ? _lido.length : t.length;
    while (p < max && _lido.codeUnitAt(p) == t.codeUnitAt(p)) {
      p++;
    }
    // só o que é novo: o que o teclado APAGOU de dentro da composição ou
    // reescreveu (autocorreção) não volta como tecla
    final novo = t.substring(p);
    _lido = t;
    if (novo.isEmpty) return;
    final ditar = aoDitar;
    if (ditar != null && _espaco.hasMatch(novo.trim())) {
      ditar(novo.trim());
      return;
    }
    for (final ch in novo.characters) {
      if (ch == '\n' || ch == '\r' || ch == '\t') continue; // frase não tem quebra de linha
      aoDigitar(ch);
    }
  }
}
