import 'package:shared_preferences/shared_preferences.dart';

import '../domain/nivel_conversa.dart';

/// As escolhas da Conversa com IA que ficam no aparelho: o nível e a leitura automática das falas.
abstract final class PreferenciasConversa {
  static const prefNivel = 'conversa_nivel', prefVozAuto = 'conversa_voz_auto';

  /// '' = automático (vem do progresso). Nunca lança.
  static Future<String> nivel() async {
    try {
      final p = await SharedPreferences.getInstance();
      final n = p.getString(prefNivel) ?? '';
      return niveisConversa.contains(n) ? n : '';
    } catch (_) {
      return '';
    }
  }

  /// '' (ou um nível inválido) volta ao automático.
  static Future<void> salvarNivel(String n) async {
    try {
      final p = await SharedPreferences.getInstance();
      if (niveisConversa.contains(n)) {
        await p.setString(prefNivel, n);
      } else {
        await p.remove(prefNivel);
      }
    } catch (_) {}
  }

  /// Padrão: ligada.
  static Future<bool> vozAuto() async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getBool(prefVozAuto) ?? true;
    } catch (_) {
      return true;
    }
  }

  static Future<void> salvarVozAuto(bool v) async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setBool(prefVozAuto, v);
    } catch (_) {}
  }
}
