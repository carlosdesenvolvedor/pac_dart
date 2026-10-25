// 🎓 A AULA DO PROFESSOR de uma lição do PAC·ENGLISH: o Prof. Beto aparece, mexendo a boca, e dá uma aula falada
// (voz pt-BR pronta, não IA) de 6 a 10 minutos, dividida em partes — a cena como historinha, cada frase, a regra
// ou o termo técnico, pronúncia, curiosidades, erros comuns, desafios e a recapitulação. Os exemplos em inglês
// ele diz em inglês; a lousa mostra o quadro, o exemplo e as figuras (a foto da cena ou emojis). Dart puro.

/// O nome do professor (um lugar só, para trocar fácil).
const nomeDoProfessor = 'Prof. Beto';

/// O `quem` do professor no elenco (o rosto) e nas vozes.
const quemProfessor = 'prof';

/// A figura da lousa que é a foto da cena da lição (e não emojis).
const figuraFoto = 'foto';

/// Uma fala da aula: o professor em português ([pt], com o [quadro] da lousa) ou um exemplo em inglês ([en],
/// com a tradução [tr] na lousa). [img] = a figura da lousa ([figuraFoto] ou emojis), [secao] = o nome da parte
/// que começa nesta fala, [pausa] = segundos de silêncio depois dela (o desafio: o aluno pensa e responde).
class FalaAula {
  final String pt, quadro, en, tr, img, secao;
  final int pausa;
  const FalaAula({
    this.pt = '',
    this.quadro = '',
    this.en = '',
    this.tr = '',
    this.img = '',
    this.secao = '',
    this.pausa = 0,
  });

  bool get ingles => en.isNotEmpty;

  /// O que a voz diz.
  String get texto => ingles ? en : pt;

  /// null = não é uma fala válida (sem texto, ou com os dois idiomas).
  static FalaAula? fromJson(Object? j) {
    if (j is! Map) return null;
    String s(String k) => j[k] is String ? (j[k] as String).trim() : '';
    final p = j['pausa'];
    final f = FalaAula(
      pt: s('pt'),
      quadro: s('quadro'),
      en: s('en'),
      tr: s('tr'),
      img: s('img'),
      secao: s('secao'),
      pausa: p is num ? p.round().clamp(0, 10) : 0,
    );
    if (f.pt.isEmpty == f.en.isEmpty) return null;
    return f;
  }
}

/// Uma parte da aula: o [nome] e a fala onde ela começa ([inicio]).
typedef SecaoAula = ({String nome, int inicio});

class AulaLicao {
  final String titulo;
  final List<FalaAula> falas;
  const AulaLicao({required this.titulo, required this.falas});

  /// Segundos aproximados a 1× (≈ 14 caracteres por segundo em português, 12 em inglês, + respiro e pausas).
  double get segundos => segundosDesde(0);

  /// Quanto falta a partir da fala [i] (inclusive), em segundos a 1×.
  double segundosDesde(int i) {
    var t = 0.0;
    for (var k = i.clamp(0, falas.length); k < falas.length; k++) {
      final f = falas[k];
      t += f.texto.length / (f.ingles ? 12 : 14) + .5 + f.pausa;
    }
    return t;
  }

  /// As partes da aula, na ordem. Sem nenhuma marcada: uma parte só, com o título da aula.
  List<SecaoAula> get secoes {
    final r = <SecaoAula>[
      for (var k = 0; k < falas.length; k++)
        if (falas[k].secao.isNotEmpty) (nome: falas[k].secao, inicio: k),
    ];
    if (r.isEmpty || r.first.inicio > 0) r.insert(0, (nome: r.isEmpty ? titulo : 'Começo', inicio: 0));
    return r;
  }

  /// Em que parte está a fala [i] (o índice em [secoes]).
  int secaoDe(int i) {
    final s = secoes;
    var r = 0;
    for (var k = 0; k < s.length; k++) {
      if (s[k].inicio <= i) r = k;
    }
    return r;
  }

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
  final k = _ultimaEscrita(falas, i);
  return k < 0 ? null : falas[k];
}

int _ultimaEscrita(List<FalaAula> falas, int i) {
  for (var k = i.clamp(-1, falas.length - 1); k >= 0; k--) {
    final f = falas[k];
    if (f.ingles || f.quadro.isNotEmpty) return k;
  }
  return -1;
}

/// A figura na lousa na fala [i]: a última [FalaAula.img] até [i] que não ficou para trás de uma escrita nova
/// (escrever outra coisa apaga a figura antiga; a fala que escreve e traz figura mostra as duas). '' = nenhuma.
String figuraAte(List<FalaAula> falas, int i) {
  final escrita = _ultimaEscrita(falas, i);
  for (var k = i.clamp(-1, falas.length - 1); k >= 0 && k >= escrita; k--) {
    if (falas[k].img.isNotEmpty) return falas[k].img;
  }
  return '';
}
