import 'package:equatable/equatable.dart';

/// Um cenário da "💬 Conversa com IA": um personagem do palco ([quem]/[nome]) faz o outro papel
/// (atendente, recrutadora…) e a pessoa conversa em inglês, digitando ou falando; o Prof. Dash corrige
/// cada fala dela. Dart puro; os dados vêm de `assets/ingles/cenarios.json`.
class Cenario extends Equatable {
  final String id, titulo, emoji;

  /// A etapa do curso (A1, A2, B1, B2, C1): agrupa a lista e mostra "acima do seu nível" (o nível da
  /// conversa é o do aluno, não este).
  final String etapa;

  /// O papel do personagem, em português ("atendente de uma cafeteria em Chicago").
  final String papel;

  /// O que a pessoa precisa conseguir, em português ("peça um café e pague").
  final String objetivo;

  /// A 1ª fala do personagem (em inglês) e a tradução dela.
  final String abertura, aberturaPt;

  /// Frases úteis (em inglês) para quem travar.
  final List<String> dicas;

  /// Quantas falas da pessoa a conversa tem.
  final int maxTurnos;

  /// O personagem do palco que faz o papel: id do elenco ('emma', 'dra-lee') ou um papel genérico
  /// ('agente'); '' = sem rosto (🐦 Prof. Dash).
  final String quem;

  /// O nome na tela ('Emma'); '' → [nomeDoPersonagem] de [quem].
  final String nome;

  const Cenario({
    required this.id,
    required this.titulo,
    required this.emoji,
    required this.etapa,
    required this.papel,
    required this.objetivo,
    required this.abertura,
    this.aberturaPt = '',
    this.dicas = const [],
    this.maxTurnos = 6,
    this.quem = '',
    this.nome = '',
  });

  /// [nome], senão [nomeDoPersonagem] de [quem], senão 'Prof. Dash'.
  String get nomePersonagem {
    if (nome.isNotEmpty) return nome;
    final n = nomeDoPersonagem(quem);
    return n.isEmpty ? 'Prof. Dash' : n;
  }

  /// Nunca lança: cenário sem os campos essenciais é descartado (null).
  static Cenario? fromJson(Object? j) {
    if (j is! Map) return null;
    String s(String k) => j[k] is String ? (j[k] as String).trim() : '';
    final id = s('id'), titulo = s('titulo'), abertura = s('abertura');
    if (id.isEmpty || titulo.isEmpty || abertura.isEmpty || s('papel').isEmpty || s('objetivo').isEmpty) return null;
    final turnos = j['maxTurnos'];
    return Cenario(
      id: id,
      titulo: titulo,
      emoji: s('emoji').isEmpty ? '💬' : s('emoji'),
      etapa: s('etapa').isEmpty ? 'A1' : s('etapa'),
      papel: s('papel'),
      objetivo: s('objetivo'),
      abertura: abertura,
      aberturaPt: s('aberturaPt'),
      dicas: [
        if (j['dicas'] is List)
          for (final d in j['dicas'] as List)
            if (d is String && d.trim().isNotEmpty) d.trim(),
      ],
      maxTurnos: turnos is int && turnos >= 2 && turnos <= 12 ? turnos : 6,
      quem: s('quem'),
      nome: s('nome'),
    );
  }

  @override
  List<Object?> get props => [id, titulo, emoji, etapa, papel, objetivo, abertura, aberturaPt, dicas, maxTurnos, quem, nome];
}

/// 'dra-lee' → 'Dra. Lee'; 'agente' → 'Agente'; 'emma' → 'Emma'; '' → ''. (Cópia da regra privada
/// `_nomeDeQuem` de traducao_card.dart.)
String nomeDoPersonagem(String quem) {
  if (quem.isEmpty) return '';
  if (quem == 'voce') return 'Você';
  if (quem == 'dra-lee') return 'Dra. Lee';
  final limpo = quem.replaceAll('-', ' ');
  return limpo[0].toUpperCase() + limpo.substring(1);
}

/// A lista de cenários do JSON (itens inválidos e ids repetidos são ignorados).
List<Cenario> cenariosDeJson(Object? bruto) {
  final vistos = <String>{};
  final r = <Cenario>[];
  if (bruto is! List) return r;
  for (final j in bruto) {
    final c = Cenario.fromJson(j);
    if (c != null && vistos.add(c.id)) r.add(c);
  }
  return r;
}
