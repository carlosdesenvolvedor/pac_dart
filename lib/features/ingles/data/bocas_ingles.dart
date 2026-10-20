import '../domain/boca.dart';

/// Registro áudio → boca (lip sync): `assets/ingles/bocas.json`, gerado pelo Rhubarb a partir de cada mp3
/// (`tools/ingles/bocas_rhubarb.py`). Preenchido quando o currículo do inglês carrega; cada trilha só é
/// montada na primeira vez que alguém pede.
class BocasIngles {
  BocasIngles._();

  static const indice = 'assets/ingles/bocas.json';

  static final Map<String, String> _brutas = {};
  static final Map<String, TrilhaBoca> _prontas = {};

  static void registrar(Map<String, dynamic> json) {
    for (final e in json.entries) {
      if (e.value is String) _brutas[e.key] = e.value as String;
    }
  }

  /// A boca do áudio [asset], ou null (sem lip sync gerado para ele).
  static TrilhaBoca? de(String asset) {
    final pronta = _prontas[asset];
    if (pronta != null) return pronta;
    final bruta = _brutas[asset];
    if (bruta == null) return null;
    return _prontas[asset] = TrilhaBoca.compacta(bruta);
  }

  /// Só para testes.
  static void limpar() {
    _brutas.clear();
    _prontas.clear();
  }
}
