/// Fora do navegador (testes na VM): mudo, nunca lança.
const suportado = false;

Future<void> falar(String texto, double velocidade) async {}

/// Sem `<audio>` fora do navegador: a voz sintética (muda) assume.
Future<bool> tocar(String asset, double velocidade) async => false;

void parar() {}

String? get vozAtual => null;
