import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/roteiro.dart';

/// 💾 A lição parada no fim de uma etapa (neste aparelho): a fila inteira, para continuar depois da etapa seguinte.
/// Uma entrada por lição (`en_etapa_<id da lição>`); sai quando a lição termina. Nunca lança.
abstract final class EtapasSalvas {
  static String chave(String licaoId) => 'en_etapa_$licaoId';

  /// A fila salva da lição [licaoId] com [frases] frases, já lida de [p] (null = nada salvo ou não confere).
  static FilaLicao? ler(SharedPreferences p, String licaoId, int frases) {
    if (licaoId.isEmpty) return null;
    try {
      final s = p.getString(chave(licaoId));
      if (s == null) return null;
      return FilaLicao.fromJson(jsonDecode(s) as Map<String, dynamic>, frases);
    } catch (_) {
      return null;
    }
  }

  /// Em que etapa (1-based) a lição [licaoId] parou, e quantas tem (null = não está parada no meio).
  static Future<({int etapa, int de})?> ondeParou(String licaoId, int frases) async {
    try {
      final f = ler(await SharedPreferences.getInstance(), licaoId, frases);
      if (f == null || f.terminou) return null;
      final et = EtapasDaLicao.deFrases(frases);
      return (etapa: et.etapaDe(f.feitos) + 1, de: et.quantas);
    } catch (_) {
      return null;
    }
  }

  static Future<void> salvar(String licaoId, FilaLicao fila) async {
    if (licaoId.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(chave(licaoId), jsonEncode(fila.toJson()));
    } catch (_) {}
  }

  static Future<void> apagar(String licaoId) async {
    if (licaoId.isEmpty) return;
    try {
      final p = await SharedPreferences.getInstance();
      await p.remove(chave(licaoId));
    } catch (_) {}
  }
}
