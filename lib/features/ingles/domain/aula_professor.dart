// 🎓 A AULA DO PROFESSOR de uma lição do PAC·ENGLISH: o Prof. Beto aparece, mexendo a boca, e fala (voz pt-BR
// pronta, não IA) uma explicação curta, como uma historinha — a cena, o sentido das frases, a regra ou o termo
// técnico e um truque para lembrar. Os exemplos em inglês ele diz em inglês, e a lousa mostra. Dart puro.

/// O nome do professor (um lugar só, para trocar fácil).
const nomeDoProfessor = 'Prof. Beto';

/// O `quem` do professor no elenco (o rosto) e nas vozes.
const quemProfessor = 'prof';

/// Uma fala da aula: o professor em português ([pt], com o [quadro] da lousa) ou um exemplo em inglês ([en],
/// com a tradução [tr] na lousa).
class FalaAula {
  final String pt, quadro, en, tr;
  const FalaAula({this.pt = '', this.quadro = '', this.en = '', this.tr = ''});

  bool get ingles => en.isNotEmpty;

  /// O que a voz diz.
  String get texto => ingles ? en : pt;

  /// null = não é uma fala válida (sem texto, ou com os dois idiomas).
  static FalaAula? fromJson(Object? j) {
    if (j is! Map) return null;
    String s(String k) => j[k] is String ? (j[k] as String).trim() : '';
    final f = FalaAula(pt: s('pt'), quadro: s('quadro'), en: s('en'), tr: s('tr'));
    if (f.pt.isEmpty == f.en.isEmpty) return null;
    return f;
  }
}

class AulaLicao {
  final String titulo;
  final List<FalaAula> falas;
  const AulaLicao({required this.titulo, required this.falas});

  /// Segundos aproximados a 1× (≈ 14 caracteres por segundo em português, 12 em inglês, + respiro).
  double get segundos => falas.fold(0.0, (a, f) => a + f.texto.length / (f.ingles ? 12 : 14) + .5);

  static AulaLicao? fromJson(Object? j) {
    if (j is! Map) return null;
    final falas = [
      for (final f in (j['falas'] is List ? j['falas'] as List : const []))
        ?FalaAula.fromJson(f),
    ];
    if (falas.isEmpty) return null;
    final t = j['titulo'];
    return AulaLicao(titulo: t is String && t.trim().isNotEmpty ? t.trim() : 'Aula', falas: falas);
  }
}

/// As aulas de uma trilha (o arquivo `assets/ingles/aulas/<slug>.json`), por id da lição.
class AulasDaTrilha {
  final String trilha;
  final Map<String, AulaLicao> licoes;
  const AulasDaTrilha({required this.trilha, required this.licoes});

  /// Tolerante: aula estragada some (as outras ficam); nunca lança.
  static AulasDaTrilha fromJson(Object? j) {
    if (j is! Map) return const AulasDaTrilha(trilha: '', licoes: {});
    final ls = j['licoes'];
    return AulasDaTrilha(
      trilha: j['trilha'] is String ? j['trilha'] as String : '',
      licoes: {
        if (ls is Map)
          for (final e in ls.entries)
            if (e.key is String) e.key as String: ?AulaLicao.fromJson(e.value),
      },
    );
  }
}

/// A trilha de uma lição pelo id dela ("primeiro-contato.oi-tudo-bem" → "primeiro-contato").
String trilhaDaLicao(String licaoId) {
  final i = licaoId.indexOf('.');
  return i < 0 ? licaoId : licaoId.substring(0, i);
}

/// Até onde a lousa mostra: a última fala com algo escrito ([FalaAula.quadro] ou o exemplo em inglês) até [i]
/// (inclusive); null = a lousa ainda vazia.
FalaAula? lousaAte(List<FalaAula> falas, int i) {
  for (var k = i.clamp(-1, falas.length - 1); k >= 0; k--) {
    final f = falas[k];
    if (f.ingles || f.quadro.isNotEmpty) return f;
  }
  return null;
}
