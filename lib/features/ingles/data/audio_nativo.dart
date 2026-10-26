
/// Registro frase em inglês → áudio pronto: a voz gerada do personagem (Google
/// Cloud TTS Chirp 3 HD, `assets/ingles/vozes.json` — tools/ingles/vozes_google.py).
/// (As gravações de nativo do Tatoeba saíram do app em 26/out/2026: licença não comercial.)
/// A história do Turismo tem o índice dela ([indiceHistoria]), por quem fala + texto.
/// Preenchido quando o currículo carrega ([registrarGeradas] / [registrarHistoria]);
/// a [VozIngles] consulta aqui antes de cair na voz sintética do navegador —
/// assim quem só tem o texto (palco, revisão, ensaio, exemplos da teoria)
/// não precisa saber do áudio.
class AudioNativo {
  AudioNativo._();

  static final Map<String, String> _geradas = {};
  static final Map<String, String> _historia = {};

  /// Índice da voz gerada: {texto em inglês: asset}.
  static const indiceGeradas = 'assets/ingles/vozes.json';

  /// Índice das falas da história do Turismo ("The Golden Wheel"): {"quem|texto": asset}. A chave tem quem
  /// fala: na história o mesmo texto sai da boca de personagens diferentes ("Copy that!").
  static const indiceHistoria = 'assets/ingles/vozes_historia.json';


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

  /// O que tocar para [frase]: a voz gerada do personagem; null = voz sintética do navegador.
  static String? paraTocar(String frase) => _geradas[frase.trim()];

  /// O mp3 da fala de [quem] na história ([frase] exatamente como no JSON), ou null.
  static String? daHistoria(String quem, String frase) => _historia['$quem|${frase.trim()}'];

  static int get totalGeradas => _geradas.length;
  static int get totalHistoria => _historia.length;

  /// Só para testes.
  static void limpar() {
    _geradas.clear();
    _historia.clear();
  }
}
