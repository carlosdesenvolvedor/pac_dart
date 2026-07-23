/// Prepara a resposta do Prof. Dash para a NARRAÇÃO: ninguém merece ouvir
/// "crase crase crase dart" — blocos de código viram um convite pra olhar
/// o chat, e a marcação/emoji somem da fala.
String textoFalavel(String markdown) {
  var t = markdown;
  t = t.replaceAll(RegExp(r'```[\s\S]*?```'),
      ' Dá uma olhada no exemplo de código aqui no chat. ');
  t = t.replaceAll('`', '').replaceAll('**', '').replaceAll('*', '');
  t = t.replaceAll(
      RegExp(r'[\u{1F000}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{FE0F}]',
          unicode: true),
      '');
  return t.replaceAll(RegExp(r'\s+'), ' ').trim();
}
