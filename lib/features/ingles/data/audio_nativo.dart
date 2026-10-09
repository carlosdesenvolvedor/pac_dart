import '../../curso/domain/curriculo.dart';

/// Registro frase em inglês → áudio pronto: a gravação de nativo (asset mp3
/// do Tatoeba) e, quando não há, a voz gerada do personagem (Google Cloud
/// TTS, `assets/ingles/vozes.json` — tools/ingles/vozes_google.py).
/// Preenchido quando o currículo carrega ([registrar] / [registrarGeradas]);
/// a [VozIngles] consulta aqui antes de cair na voz sintética do navegador —
/// assim quem só tem o texto (palco, revisão, ensaio, exemplos da teoria)
/// não precisa saber do áudio.
class AudioNativo {
  AudioNativo._();

  static final Map<String, String> _porFrase = {};
  static final Map<String, String> _geradas = {};

  /// Índice da voz gerada: {texto em inglês: asset}.
  static const indiceGeradas = 'assets/ingles/vozes.json';

  /// Guarda as gravações das frases das [trilhas] (soma ao que já havia:
  /// carregar o currículo do Dart não apaga as do inglês).
  static void registrar(Iterable<Trilha> trilhas) {
    for (final t in trilhas) {
      for (final l in t.licoes) {
        for (final f in l.trechos) {
          if (f.audio.isNotEmpty) _porFrase[f.cod] = f.audio;
        }
      }
    }
  }

  /// Guarda as vozes geradas por personagem ({texto: asset}).
  static void registrarGeradas(Map<String, dynamic> indice) {
    for (final e in indice.entries) {
      if (e.value is String) _geradas[e.key.trim()] = e.value as String;
    }
  }

  /// O asset da gravação de nativo de [frase] (texto exato), ou null.
  static String? daFrase(String frase) => _porFrase[frase.trim()];

  /// O que tocar para [frase]: a gravação de nativo, senão a voz gerada do
  /// personagem; null = voz sintética do navegador.
  static String? paraTocar(String frase) => _porFrase[frase.trim()] ?? _geradas[frase.trim()];

  static int get total => _porFrase.length;
  static int get totalGeradas => _geradas.length;

  /// Só para testes.
  static void limpar() {
    _porFrase.clear();
    _geradas.clear();
  }
}
