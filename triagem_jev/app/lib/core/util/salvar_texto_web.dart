import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Cria um `<a download>` temporário apontando para um Blob de texto e clica nele.
bool salvarTexto(String nome, String conteudo) {
  try {
    final blob = web.Blob([conteudo.toJS].toJS, web.BlobPropertyBag(type: 'text/plain;charset=utf-8'));
    final url = web.URL.createObjectURL(blob);
    final a = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = nome;
    web.document.body?.append(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
    return true;
  } catch (_) {
    return false;
  }
}

const podeSalvar = true;
