/// O "ao pé da letra" de uma palavra em inglês: o dicionário embutido (assets/ingles/dicionario.json, as
/// palavras do curso) e as regras para achar uma forma que não está nele (plural, passado, gerúndio,
/// possessivo). Dart puro.
class Dicionario {
  /// Palavra em minúsculas → tradução curta ("went" → "foi, ia (passado de go)").
  final Map<String, String> entradas;
  const Dicionario(this.entradas);

  static const vazio = Dicionario({});

  /// A palavra como chave: minúsculas, apóstrofo reto, sem pontuação nas pontas.
  static String normalizar(String palavra) =>
      palavra.toLowerCase().replaceAll(RegExp('[‘’ʼ`´]'), "'").replaceAll(RegExp(r"^[^a-z0-9]+|[^a-z0-9]+$"), '');

  /// A tradução de [palavra], ou null. Sem a forma exata, tenta a base (plural, -ed, -ing, 's…) e avisa
  /// de qual palavra veio ("cats" → "gato (de cat)").
  String? literal(String palavra) {
    final w = normalizar(palavra);
    if (w.isEmpty) return null;
    final exata = entradas[w];
    if (exata != null) return exata;
    if (w.endsWith("'s") && w.length > 2) {
      final base = w.substring(0, w.length - 2);
      final t = entradas[base];
      if (t != null) return "$t (+ 's: de ${_capitalizada(base)} / ${_capitalizada(base)} is)";
    }
    for (final base in _bases(w)) {
      final t = entradas[base];
      if (t != null) return '$t (de $base)';
    }
    return null;
  }

  static String _capitalizada(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  /// Bases prováveis de uma forma flexionada, da mais provável para a menos.
  static List<String> _bases(String w) {
    final r = <String>[];
    void tenta(bool cond, String Function() base) {
      if (cond) {
        final b = base();
        if (b.length >= 2 && !r.contains(b)) r.add(b);
      }
    }

    final n = w.length;
    tenta(w.endsWith('ies'), () => '${w.substring(0, n - 3)}y');
    tenta(w.endsWith('es'), () => w.substring(0, n - 2));
    tenta(w.endsWith('s') && !w.endsWith('ss'), () => w.substring(0, n - 1));
    tenta(w.endsWith('ied'), () => '${w.substring(0, n - 3)}y');
    tenta(w.endsWith('ed'), () => w.substring(0, n - 2));
    tenta(w.endsWith('ed'), () => w.substring(0, n - 1)); // liked → like
    tenta(w.endsWith('ed') && n > 4 && w[n - 3] == w[n - 4], () => w.substring(0, n - 3)); // stopped → stop
    tenta(w.endsWith('ing'), () => w.substring(0, n - 3));
    tenta(w.endsWith('ing'), () => '${w.substring(0, n - 3)}e'); // making → make
    tenta(w.endsWith('ing') && n > 5 && w[n - 4] == w[n - 5], () => w.substring(0, n - 4)); // running → run
    tenta(w.endsWith('ly'), () => w.substring(0, n - 2));
    tenta(w.endsWith('er'), () => w.substring(0, n - 2));
    tenta(w.endsWith('est'), () => w.substring(0, n - 3));
    return r;
  }

  /// Nunca lança: o que não for texto vira nada.
  factory Dicionario.fromJson(Object? bruto) {
    if (bruto is! Map) return vazio;
    return Dicionario({
      for (final e in bruto.entries)
        if (e.value is String && (e.value as String).trim().isNotEmpty)
          normalizar('${e.key}'): (e.value as String).trim(),
    });
  }
}
