import 'package:equatable/equatable.dart';

/// Trilha → Lição → Trecho (um exercício de digitação).
class Trilha extends Equatable {
  final String nivel;
  final String emoji;

  /// Frase curta descrevendo o que a trilha ensina (pode ser vazia).
  final String descricao;
  final List<Licao> licoes;

  /// Projetos "Mão na Massa" ao fim do módulo (programas completos).
  final List<Projeto> projetos;

  const Trilha({
    required this.nivel,
    required this.emoji,
    this.descricao = '',
    required this.licoes,
    this.projetos = const [],
  });

  /// Trilha especial só de projetos (ex.: "Teste Master").
  bool get soProjetos => licoes.isEmpty && projetos.isNotEmpty;
  bool get temProjetos => projetos.isNotEmpty;

  factory Trilha.fromJson(Map<String, dynamic> j) => Trilha(
        nivel: j['nivel'] as String,
        emoji: j['emoji'] as String,
        descricao: (j['descricao'] ?? '') as String,
        licoes: ((j['licoes'] ?? const []) as List)
            .map((e) => Licao.fromJson(e as Map<String, dynamic>))
            .toList(),
        projetos: ((j['projetos'] ?? const []) as List)
            .map((e) => Projeto.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  List<Object?> get props => [nivel, emoji, descricao, licoes, projetos];
}

/// Um projeto/app completo que a pessoa digita ("Mão na Massa" / Teste Master).
class Projeto extends Equatable {
  final String nome;
  final String emoji;
  final String descricao;
  final String cod;
  final String out;
  final bool flutter;

  const Projeto({
    required this.nome,
    required this.emoji,
    required this.descricao,
    required this.cod,
    required this.out,
    this.flutter = false,
  });

  factory Projeto.fromJson(Map<String, dynamic> j) => Projeto(
        nome: j['nome'] as String,
        emoji: (j['emoji'] ?? '🛠️') as String,
        descricao: (j['descricao'] ?? '') as String,
        cod: j['cod'] as String,
        out: (j['out'] ?? '') as String,
        flutter: (j['flutter'] ?? false) as bool,
      );

  /// Converte para um Trecho, para reusar o motor de digitação.
  Trecho get comoTrecho => Trecho(cod: cod, dica: descricao, out: out);

  @override
  List<Object?> get props => [nome, emoji, descricao, cod, out, flutter];
}

/// Um bloco da teoria ("Nivelamento") de uma lição.
class BlocoTeoria extends Equatable {
  /// h (subtítulo), p (parágrafo), code (código), tip (dica), warn (cuidado).
  final String tipo;
  final String conteudo;

  const BlocoTeoria({required this.tipo, required this.conteudo});

  factory BlocoTeoria.fromJson(Map<String, dynamic> j) =>
      BlocoTeoria(tipo: (j['t'] ?? 'p') as String, conteudo: (j['c'] ?? '') as String);

  @override
  List<Object?> get props => [tipo, conteudo];
}

class Licao extends Equatable {
  final String nome;
  final String emoji;

  /// Visão geral do que a lição ensina (pode ser vazia).
  final String resumo;

  /// Teoria em blocos, lida antes de praticar (pode ser vazia).
  final List<BlocoTeoria> teoria;
  final List<Trecho> trechos;

  const Licao({
    required this.nome,
    required this.emoji,
    this.resumo = '',
    this.teoria = const [],
    required this.trechos,
  });

  bool get temTeoria => teoria.isNotEmpty;

  factory Licao.fromJson(Map<String, dynamic> j) => Licao(
        nome: j['nome'] as String,
        emoji: j['emoji'] as String,
        resumo: (j['resumo'] ?? '') as String,
        teoria: ((j['teoria'] ?? const []) as List)
            .map((e) => BlocoTeoria.fromJson(e as Map<String, dynamic>))
            .toList(),
        trechos: (j['trechos'] as List).map((e) => Trecho.fromJson(e as Map<String, dynamic>)).toList(),
      );

  @override
  List<Object?> get props => [nome, emoji, resumo, teoria, trechos];
}

class Trecho extends Equatable {
  /// Código a digitar (com \n reais e indentação de 2 espaços).
  final String cod;

  /// Dica curta; pode conter marcação <b>…</b>.
  final String dica;

  /// Saída esperada mostrada no console ao "compilar".
  final String out;

  /// Explicação aprofundada opcional ("Entenda melhor").
  final String conceito;

  const Trecho({required this.cod, required this.dica, required this.out, this.conceito = ''});

  factory Trecho.fromJson(Map<String, dynamic> j) => Trecho(
        cod: j['cod'] as String,
        dica: (j['dica'] ?? '') as String,
        out: (j['out'] ?? '') as String,
        conceito: (j['conceito'] ?? '') as String,
      );

  /// Remove a marcação <b>/<code> de um texto (para TTS e cartões).
  static String semTags(String s) =>
      s.replaceAll(RegExp(r'</?b>'), '').replaceAll(RegExp(r'</?code>'), '');

  /// Dica sem a marcação, para TTS e cartões.
  String get dicaPlana => semTags(dica);

  bool get temConceito => conceito.isNotEmpty;

  @override
  List<Object?> get props => [cod, dica, out, conceito];
}
