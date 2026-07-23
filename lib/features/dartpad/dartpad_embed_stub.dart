import 'package:flutter/widgets.dart';

/// Fora do navegador (VM/celular) não há iframe — quem chama mostra o
/// caminho alternativo (copiar o código).
const bool embutivel = false;

Widget construir({
  required String codigo,
  required bool escuro,
  required bool rodarSozinho,
}) =>
    const SizedBox.shrink();
