import '../../curso/domain/curriculo.dart';

/// Registro frase em inglês → áudio pronto: a voz gerada do personagem (Google
/// Cloud TTS Chirp 3 HD, `assets/ingles/vozes.json` — tools/ingles/vozes_google.py)
/// e, só de reserva quando ela falta, a gravação de nativo (asset mp3 do Tatoeba,
/// campo `au` do currículo). A história do Turismo tem o índice dela
/// ([indiceHistoria]), por quem fala + texto.
/// Preenchido quando o currículo carrega ([registrar] / [registrarGeradas] / [registrarHistoria]);
/// a [VozIngles] consulta aqui antes de cair na voz sintética do navegador —
/// assim quem só tem o texto (palco, revisão, ensaio, exemplos da teoria)
/// não precisa saber do áudio.
class AudioNativo {
  AudioNativo._();

  static final Map<String, String> _porFrase = {};
  static final Map<String, String> _geradas = {};
  static final Map<String, String> _historia = {};

  /// Índice da voz gerada: {texto em inglês: asset}.
  static const indiceGeradas = 'assets/ingles/vozes.json';

  /// Índice das falas da história do Turismo ("The Golden Wheel"): {"quem|texto": asset}. A chave tem quem
  /// fala: na história o mesmo texto sai da boca de personagens diferentes ("Copy that!").
  static const indiceHistoria = 'assets/ingles/vozes_historia.json';

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

  /// Guarda as falas da história ({"quem|texto": asset}).
  static void registrarHistoria(Map<String, dynamic> indice) {
    for (final e in indice.entries) {
      if (e.value is String) _historia[e.key.trim()] = e.value as String;
    }
  }

  /// O asset da gravação de nativo de [frase] (texto exato), ou null — há gravação registrada, mesmo que
  /// a voz do personagem toque no lugar dela (veja [tocaGravacaoDeNativo]).
  static String? daFrase(String frase) => _porFrase[frase.trim()];

  /// O que tocar para [frase]: a voz gerada do personagem, senão a gravação de
  /// nativo (reserva); null = voz sintética do navegador.
  static String? paraTocar(String frase) => _geradas[frase.trim()] ?? _porFrase[frase.trim()];

  /// O 🔊 de [frase] toca de fato a gravação do Tatoeba (sem voz do personagem)? Só aí vale o crédito.
  static bool tocaGravacaoDeNativo(String frase) =>
      _geradas[frase.trim()] == null && _porFrase[frase.trim()] != null;

  /// O mp3 da fala de [quem] na história ([frase] exatamente como no JSON), ou null.
  static String? daHistoria(String quem, String frase) => _historia['$quem|${frase.trim()}'];

  static int get total => _porFrase.length;
  static int get totalGeradas => _geradas.length;
  static int get totalHistoria => _historia.length;

  /// Só para testes.
  static void limpar() {
    _porFrase.clear();
    _geradas.clear();
    _historia.clear();
  }
}
