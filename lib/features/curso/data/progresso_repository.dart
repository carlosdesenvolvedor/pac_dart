import 'package:shared_preferences/shared_preferences.dart';

/// Contrato de persistência do progresso (lições concluídas, posição,
/// notas de quiz, recorde). Implementado local (offline) e no Firestore.
abstract interface class ProgressoRepository {
  Future<Set<String>> concluidas();
  Future<void> marcarConcluida(String chave);
  Future<(int, int)> posicao();
  Future<void> salvarPosicao(int trilha, int licao);

  /// Notas dos quizzes: chave "t:l" → acertos (0..10).
  Future<Map<String, int>> quizNotas();
  Future<void> salvarQuizNota(String chave, int acertos);

  Future<int> recorde();
  Future<void> salvarRecorde(int score);
}

/// Persistência local no dispositivo (shared_preferences). Usada offline e
/// nos testes.
class LocalProgressoRepository implements ProgressoRepository {
  static const _kConcluidas = 'concluidas';
  static const _kTrilha = 'trilha';
  static const _kLicao = 'licao';
  static const _kRecorde = 'recorde';
  static const _kQuiz = 'quiz_notas';

  @override
  Future<Set<String>> concluidas() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_kConcluidas) ?? const []).toSet();
  }

  @override
  Future<void> marcarConcluida(String chave) async {
    final p = await SharedPreferences.getInstance();
    final atual = (p.getStringList(_kConcluidas) ?? const []).toSet()..add(chave);
    await p.setStringList(_kConcluidas, atual.toList());
  }

  @override
  Future<(int, int)> posicao() async {
    final p = await SharedPreferences.getInstance();
    return (p.getInt(_kTrilha) ?? 0, p.getInt(_kLicao) ?? 0);
  }

  @override
  Future<void> salvarPosicao(int trilha, int licao) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kTrilha, trilha);
    await p.setInt(_kLicao, licao);
  }

  @override
  Future<Map<String, int>> quizNotas() async {
    final p = await SharedPreferences.getInstance();
    final lista = p.getStringList(_kQuiz) ?? const [];
    final m = <String, int>{};
    for (final e in lista) {
      final partes = e.split('=');
      if (partes.length == 2) m[partes[0]] = int.tryParse(partes[1]) ?? 0;
    }
    return m;
  }

  @override
  Future<void> salvarQuizNota(String chave, int acertos) async {
    final p = await SharedPreferences.getInstance();
    final m = await quizNotas();
    if ((m[chave] ?? -1) >= acertos) return; // guarda só a melhor
    m[chave] = acertos;
    await p.setStringList(_kQuiz, m.entries.map((e) => '${e.key}=${e.value}').toList());
  }

  @override
  Future<int> recorde() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kRecorde) ?? 0;
  }

  @override
  Future<void> salvarRecorde(int score) async {
    final p = await SharedPreferences.getInstance();
    if (score > (p.getInt(_kRecorde) ?? 0)) await p.setInt(_kRecorde, score);
  }
}
