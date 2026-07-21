import 'package:equatable/equatable.dart';

/// Trilha → Lição → Trecho (um exercício de digitação).
class Trilha extends Equatable {
  final String nivel;
  final String emoji;

  /// Frase curta descrevendo o que a trilha ensina (pode ser vazia).
  final String descricao;
  final List<Licao> licoes;

  const Trilha({
    required this.nivel,
    required this.emoji,
    this.descricao = '',
    required this.licoes,
  });

  factory Trilha.fromJson(Map<String, dynamic> j) => Trilha(
        nivel: j['nivel'] as String,
        emoji: j['emoji'] as String,
        descricao: (j['descricao'] ?? '') as String,
        licoes: (j['licoes'] as List).map((e) => Licao.fromJson(e as Map<String, dynamic>)).toList(),
      );

  @override
  List<Object?> get props => [nivel, emoji, descricao, licoes];
}

class Licao extends Equatable {
  final String nome;
  final String emoji;

  /// Visão geral do que a lição ensina (pode ser vazia).
  final String resumo;
  final List<Trecho> trechos;

  const Licao({
    required this.nome,
    required this.emoji,
    this.resumo = '',
    required this.trechos,
  });

  factory Licao.fromJson(Map<String, dynamic> j) => Licao(
        nome: j['nome'] as String,
        emoji: j['emoji'] as String,
        resumo: (j['resumo'] ?? '') as String,
        trechos: (j['trechos'] as List).map((e) => Trecho.fromJson(e as Map<String, dynamic>)).toList(),
      );

  @override
  List<Object?> get props => [nome, emoji, resumo, trechos];
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
