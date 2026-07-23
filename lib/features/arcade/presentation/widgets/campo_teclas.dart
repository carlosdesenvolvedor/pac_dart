import 'package:flutter/material.dart';

/// TextField invisível que entrega cada caractere digitado (mesmo truque do
/// CodeView: funciona com teclado físico e com o virtual do celular).
/// Sem correção: os jogos não usam backspace — errou, conta erro e segue.
class CampoTeclas extends StatefulWidget {
  final ValueChanged<String> onChar;
  const CampoTeclas({super.key, required this.onChar});

  @override
  State<CampoTeclas> createState() => _CampoTeclasState();
}

class _CampoTeclasState extends State<CampoTeclas> {
  final _foco = FocusNode();
  final _ctrl = TextEditingController();
  String _anterior = '';

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_processa);
    // Clicar em QUALQUER botão (Jogar de novo, Fácil…) rouba o foco do campo
    // e o teclado "morre" — este listener devolve o foco sozinho, sempre.
    _foco.addListener(_mantemFoco);
  }

  void _mantemFoco() {
    if (_foco.hasFocus || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_foco.hasFocus) _foco.requestFocus();
    });
  }

  @override
  void dispose() {
    _foco.removeListener(_mantemFoco);
    _ctrl.removeListener(_processa);
    _ctrl.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _processa() {
    final t = _ctrl.text;
    if (t.length > _anterior.length && t.startsWith(_anterior)) {
      for (var i = _anterior.length; i < t.length; i++) {
        widget.onChar(t[i]);
      }
    }
    _anterior = t;
    if (t.length > 200) {
      // esvazia de vez em quando pra não crescer pra sempre
      _anterior = '';
      _ctrl.value = const TextEditingValue(text: '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: TextField(
          focusNode: _foco,
          controller: _ctrl,
          autofocus: true,
          maxLines: 1,
          autocorrect: false,
          enableSuggestions: false,
          // sem composição/autocomplete: as palavras dos jogos são ASCII puro
          keyboardType: TextInputType.visiblePassword,
          onTapOutside: (_) => _foco.requestFocus(),
        ),
      ),
    );
  }
}
