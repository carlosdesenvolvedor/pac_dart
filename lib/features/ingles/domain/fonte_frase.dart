/// Atribuição de uma frase que veio do Tatoeba (tatoeba.org, CC BY 2.0 FR).
class FonteFrase {
  final int enId;
  final String enAutor;

  /// Tradução também do Tatoeba (null = a tradução é do curso).
  final int? ptId;
  final String? ptAutor;

  /// O inglês ou a tradução foram adaptados por nós (nome trocado etc.).
  final bool adaptada;

  const FonteFrase({required this.enId, required this.enAutor, this.ptId, this.ptAutor, this.adaptada = false});

  static const licenca = 'CC BY 2.0 FR';
  static const urlLicenca = 'https://creativecommons.org/licenses/by/2.0/fr/';

  /// Lê `tatoeba:idEN:autorEN:idPT:autorPT:0|1` (PT "-" = tradução do curso).
  static FonteFrase? ler(String src) {
    final p = src.split(':');
    if (p.length < 3 || p[0] != 'tatoeba') return null;
    final en = int.tryParse(p[1]);
    if (en == null || p[2].isEmpty) return null;
    final pt = p.length > 3 ? int.tryParse(p[3]) : null;
    return FonteFrase(
      enId: en,
      enAutor: p[2],
      ptId: pt,
      ptAutor: pt != null && p.length > 4 && p[4] != '-' ? p[4] : null,
      adaptada: p.length > 5 && p[5] == '1',
    );
  }

  String get url => 'https://tatoeba.org/pt-br/sentences/show/$enId';

  /// "Tatoeba nº 1276 · CK · adaptada · CC BY 2.0 FR".
  String get rotulo => [
        'Tatoeba nº $enId · $enAutor',
        if (adaptada) 'adaptada',
        if (ptAutor != null) 'tradução de $ptAutor',
        licenca,
      ].join(' · ');
}
