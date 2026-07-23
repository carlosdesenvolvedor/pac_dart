import 'package:flutter/widgets.dart';

import 'dartpad_embed_stub.dart' if (dart.library.js_interop) 'dartpad_embed_web.dart' as impl;

/// O DartPad roda dentro de um `iframe` — só existe no navegador.
bool get dartPadEmbutivel => impl.embutivel;

/// Tela do DartPad já com [codigo] no editor (e rodando, se [rodarSozinho]).
///
/// Como funciona (contrato do próprio DartPad, visto no bundle de produção):
/// o iframe abre em `dartpad.dev/?embed=true`, avisa o pai com
/// `{sender: <name do iframe>, type: 'ready'}` e aceita de volta
/// `{type: 'sourceCode', sourceCode: '<código>'}`.
Widget dartPadEmbutido({
  required String codigo,
  required bool escuro,
  bool rodarSozinho = true,
}) =>
    impl.construir(codigo: codigo, escuro: escuro, rodarSozinho: rodarSozinho);
