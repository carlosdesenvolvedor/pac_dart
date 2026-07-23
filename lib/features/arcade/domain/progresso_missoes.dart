import 'package:shared_preferences/shared_preferences.dart';

/// Progresso do Lógica Animada por trilha (persistido por dispositivo,
/// mesmo padrão do tema): guarda o índice da PRÓXIMA missão de cada trilha.
abstract final class ProgressoMissoes {
  static String _chave(int trilha) => 'missao_t$trilha';

  static Future<int> proxima(int trilha) async {
    try {
      final p = await SharedPreferences.getInstance();
      return p.getInt(_chave(trilha)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> concluiu(int trilha, int indice) async {
    try {
      final p = await SharedPreferences.getInstance();
      final atual = p.getInt(_chave(trilha)) ?? 0;
      if (indice + 1 > atual) await p.setInt(_chave(trilha), indice + 1);
    } catch (_) {}
  }
}
