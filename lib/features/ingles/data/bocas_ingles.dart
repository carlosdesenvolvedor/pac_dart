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

  /// Quanto dura o áudio [asset] (s, a 1×) pela última marca da boca (`"… 222X"` = 2,22 s), sem montar
  /// a trilha inteira; null = sem boca gerada para ele (ou [asset] null).
  static double? duracaoDe(String? asset) {
    if (asset == null) return null;
    final pronta = _prontas[asset];
    if (pronta != null) return pronta.duracao;
    final bruta = _brutas[asset]?.trimRight();
    if (bruta == null || bruta.length < 2) return null;
    final ultima = bruta.substring(bruta.lastIndexOf(' ') + 1);
    if (ultima.length < 2) return null;
    final cs = int.tryParse(ultima.substring(0, ultima.length - 1));
    return cs == null ? null : cs / 100;
  }

  /// Só para testes.
  static void limpar() {
    _brutas.clear();
    _prontas.clear();
  }
}
