import 'dart:typed_data';

/// Fora do navegador (testes na VM): mudo, nunca lança.
const suportado = false;

Future<void> falar(String texto, double velocidade) async {}

/// Sem `<audio>` fora do navegador: a voz sintética (muda) assume.
Future<bool> tocar(String asset, double velocidade) async => false;

/// Sem `<audio>` fora do navegador: a voz sintética (muda) assume.
Future<bool> tocarBytes(Uint8List bytes, String mime, double velocidade) async => false;

void parar() {}

String? get vozAtual => null;

/// Onde está a gravação tocando (s), para a boca do personagem; null = sem gravação tocando.
double? get posicaoGravacao => null;
