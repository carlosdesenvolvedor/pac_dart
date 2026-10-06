import 'fala_stub.dart' if (dart.library.js_interop) 'fala_web.dart' as fala;

/// Fala as frases do curso de inglês em inglês americano com a melhor voz
/// que o navegador tiver. Grátis e sem cota (Web Speech API): as vozes de
/// rede ("Microsoft … Online (Natural)" no Edge, "Google US English" no
/// Chrome) soam bem melhor que as locais. Nunca lança: plataforma sem TTS
/// (testes na VM) só fica muda.
class VozIngles {
  /// Velocidade normal e a lenta (🐢) no `rate` do Web Speech — abaixo de
  /// 0,7 as vozes neurais arrastam (dossiê 06 §A6).
  static const velocidadeNormal = .95;
  static const velocidadeLenta = .72;

  /// Fala [frase] por cima do que estiver tocando. [lenta] = 🐢.
  Future<void> falar(String frase, {bool lenta = false}) async {
    try {
      await fala.falar(frase, lenta ? velocidadeLenta : velocidadeNormal);
    } catch (_) {}
  }

  Future<void> parar() async {
    try {
      fala.parar();
    } catch (_) {}
  }

  /// A voz em uso (null fora do navegador ou antes da 1ª fala).
  String? get vozAtual => fala.vozAtual;
}
