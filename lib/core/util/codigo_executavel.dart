/// Transforma o código de um exercício/projeto em algo que RODA numa IDE de
/// verdade (DartPad, VS Code): programas Dart completos ficam como estão;
/// árvores de widgets Flutter ganham um main() + MaterialApp; fragmentos Dart
/// são embrulhados num main().
String codigoExecutavel(String cod, bool flutter) {
  final temMain = RegExp(r'\bmain\s*\(').hasMatch(cod);
  if (temMain) return cod; // já é um programa completo

  if (flutter) {
    final t = cod.trimLeft();
    final ehTelaCompleta = t.startsWith('Scaffold') || t.startsWith('MaterialApp');
    final home = ehTelaCompleta ? cod : 'Scaffold(\n      body: SafeArea(\n        child: $cod,\n      ),\n    )';
    return "import 'package:flutter/material.dart';\n\n"
        'void main() => runApp(\n'
        '  MaterialApp(\n'
        '    debugShowCheckedModeBanner: false,\n'
        '    home: $home,\n'
        '  ),\n'
        ');';
  }

  // fragmento Dart (ex.: var nome = 'Ana';) → embrulha num main para rodar
  final corpo = cod.split('\n').map((l) => l.isEmpty ? l : '  $l').join('\n');
  return 'void main() {\n$corpo\n}';
}
