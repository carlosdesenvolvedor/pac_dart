import 'package:shared_preferences/shared_preferences.dart';

/// Persiste lições concluídas, posição atual e recorde de score.
class ProgressoRepository {
  static const _kConcluidas = 'concluidas';
  static const _kTrilha = 'trilha';
  static const _kLicao = 'licao';
  static const _kRecorde = 'recorde';

  Future<Set<String>> concluidas() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kConcluidas) ?? const []).toSet();
  }

  Future<void> marcarConcluida(String chave) async {
    final p = await SharedPreferences.getInstance();
    final atual = (p.getStringList(_kConcluidas) ?? const []).toSet()..add(chave);
    await p.setStringList(_kConcluidas, atual.toList());
  }

  Future<(int, int)> posicao() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_kTrilha) ?? 0, p.getInt(_kLicao) ?? 0);
  }

  Future<void> salvarPosicao(int trilha, int licao) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTrilha, trilha);
    await p.setInt(_kLicao, licao);
  }

  /// Notas dos quizzes: chave "t:l" → acertos (0..10).
  Future<Map<String, int>> quizNotas() async {
    final p = await SharedPreferences.getInstance();
    final lista = p.getStringList('quiz_notas') ?? const [];
    final m = <String, int>{};
    for (final e in lista) {
      final partes = e.split('=');
      if (partes.length == 2) m[partes[0]] = int.tryParse(partes[1]) ?? 0;
    }
    return m;
  }

  Future<void> salvarQuizNota(String chave, int acertos) async {
    final p = await SharedPreferences.getInstance();
    final m = await quizNotas();
    if ((m[chave] ?? -1) >= acertos) return; // guarda só a melhor
    m[chave] = acertos;
    await p.setStringList('quiz_notas', m.entries.map((e) => '${e.key}=${e.value}').toList());
  }

  Future<int> recorde() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kRecorde) ?? 0;
  }

  Future<void> salvarRecorde(int score) async {
    final p = await SharedPreferences.getInstance();
    if (score > (p.getInt(_kRecorde) ?? 0)) await p.setInt(_kRecorde, score);
  }
}
