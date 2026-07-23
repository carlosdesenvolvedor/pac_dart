import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../core/theme/mixart.dart';

const bool embutivel = true;

const _origem = 'https://dartpad.dev';

/// Cada instância precisa de um viewType único (o registro é global).
int _contador = 0;

Widget construir({
  required String codigo,
  required bool escuro,
  required bool rodarSozinho,
}) =>
    _DartPadFrame(codigo: codigo, escuro: escuro, rodarSozinho: rodarSozinho);

class _DartPadFrame extends StatefulWidget {
  final String codigo;
  final bool escuro, rodarSozinho;
  const _DartPadFrame({
    required this.codigo,
    required this.escuro,
    required this.rodarSozinho,
  });

  @override
  State<_DartPadFrame> createState() => _DartPadFrameState();
}

class _DartPadFrameState extends State<_DartPadFrame> {
  /// Vai no `name` do iframe — o DartPad devolve isso em `sender` no "ready",
  /// e é assim que sabemos que o aviso é do NOSSO frame.
  late final String _id = 'pacdart-dartpad-${_contador++}';

  late final web.HTMLIFrameElement _frame;
  JSFunction? _ouvinte;
  bool _pronto = false;

  @override
  void initState() {
    super.initState();

    final url = Uri.parse('$_origem/').replace(queryParameters: {
      'embed': 'true',
      'theme': widget.escuro ? 'dark' : 'light',
      if (widget.rodarSozinho) 'run': 'true',
    }).toString();

    _frame = web.document.createElement('iframe') as web.HTMLIFrameElement
      ..name = _id
      ..src = url
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%';

    ui_web.platformViewRegistry.registerViewFactory(_id, (int _) => _frame);

    // O DartPad avisa quando terminou de carregar; aí mandamos o código.
    _ouvinte = ((web.MessageEvent evento) {
      if (evento.origin != _origem) return;
      if (evento.data case _Aviso(:final type?, :final sender?)
          when type == 'ready' && sender == _id) {
        _injetar();
      }
    }).toJS;
    web.window.addEventListener('message', _ouvinte);
  }

  void _injetar() {
    _frame.contentWindow?.postMessage(
      {'type': 'sourceCode', 'sourceCode': widget.codigo}.jsify(),
      _origem.toJS,
    );
    if (mounted && !_pronto) setState(() => _pronto = true);
  }

  @override
  void dispose() {
    if (_ouvinte != null) web.window.removeEventListener('message', _ouvinte);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: HtmlElementView(viewType: _id)),
        if (!_pronto)
          Positioned.fill(
            child: ColoredBox(
              color: Mixart.bg,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                CircularProgressIndicator(color: Mixart.brand),
                const SizedBox(height: 16),
                Text('Acordando o DartPad…', style: Mixart.ui(size: 13, color: Mixart.textMuted)),
                const SizedBox(height: 4),
                Text('ele compila no servidor do Dart, então precisa de internet',
                    style: Mixart.ui(size: 11.5, color: Mixart.textFaint)),
              ]),
            ),
          ),
      ]);
}

/// Formato do aviso que o DartPad manda para a página que o embute.
extension type _Aviso._(JSObject _) {
  external String? get type;
  external String? get sender;
}
