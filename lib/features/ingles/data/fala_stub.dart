import 'dart:typed_data';

/// Fora do navegador (testes na VM): mudo, nunca lança.
const suportado = false;

Future<void> falar(String texto, double velocidade) async {}

/// Fala [texto] na voz do idioma [lang] (ex. `pt-BR`). Fora do navegador não há voz: false.
Future<bool> falarEm(String texto, double velocidade, String lang) async => false;

/// Há voz instalada cujo idioma começa com [prefixo] (ex. `pt`)? Fora do navegador, não.
Future<bool> temVozEm(String prefixo) async => false;

/// Silêncio de [ms] no `<audio>`: fora do navegador completa na hora.
Future<bool> tocarSilencio(int ms) async => true;

/// Começar a baixar o áudio [asset]: fora do navegador, nada.
void preaquecer(String asset) {}

/// A página está escondida? Fora do navegador, nunca.
bool get oculto => false;

/// Sem `<audio>` fora do navegador: a voz sintética (muda) assume.
Future<bool> tocar(String asset, double velocidade) async => false;

/// Sem `<audio>` fora do navegador: a voz sintética (muda) assume.
Future<bool> tocarBytes(Uint8List bytes, String mime, double velocidade) async => false;

void parar() {}

String? get vozAtual => null;

/// Onde está a gravação tocando (s), para a boca do personagem; null = sem gravação tocando.
double? get posicaoGravacao => null;
