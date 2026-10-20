// O vocabulário que os jogos de digitação (Chuva, Rali e Turismo) usam numa
// partida: as três faixas de tamanho, a tradução de cada palavra (o inglês
// mostra embaixo) e as palavras "em foco" (as que a pessoa acabou de treinar).
// Dart puro — não sabe de onde as palavras vieram.

/// As palavras de uma partida, por faixa de tamanho.
class VocabularioJogo {
  /// 3–5 letras (nível 1), 6–8 (nível 2) e 9+ (nível 3, os chefões).
  final List<String> curtas;
  final List<String> medias;
  final List<String> longas;

  /// Palavra → tradução curta (vazio no Dart e no C#: não há o que traduzir).
  final Map<String, String> traducoes;

  /// As palavras que a pessoa está treinando agora: vêm primeiro no Rali.
  final Set<String> foco;

  const VocabularioJogo({
    required this.curtas,
    required this.medias,
    required this.longas,
    this.traducoes = const {},
    this.foco = const {},
  });

  /// As listas fixas de sempre ([vocabularioDe]) — as MESMAS instâncias, sem cópia.
  factory VocabularioJogo.deListas(
    ({List<String> curtas, List<String> medias, List<String> longas}) v, {
    Map<String, String> traducoes = const {},
  }) =>
      VocabularioJogo(curtas: v.curtas, medias: v.medias, longas: v.longas, traducoes: traducoes);

  /// As palavras de um nível de pista — a mesma regra de `PistaGt.vocabulario`:
  /// 1 = curtas, 2 = curtas + médias, 3+ = médias + longas.
  List<String> poolDoNivel(int nivel) => switch (nivel) {
        <= 1 => curtas,
        2 => [...curtas, ...medias],
        _ => [...medias, ...longas],
      };

  /// Todas as palavras (curtas, médias, longas).
  List<String> get todas => [...curtas, ...medias, ...longas];

  /// A tradução de [palavra] (pela forma exata ou em minúsculas), ou null.
  String? traducao(String palavra) {
    final t = traducoes[palavra] ?? traducoes[palavra.toLowerCase()];
    return t == null || t.isEmpty ? null : t;
  }

  bool emFoco(String palavra) => foco.contains(palavra);
}
