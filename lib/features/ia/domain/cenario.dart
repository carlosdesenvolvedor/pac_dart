import 'package:equatable/equatable.dart';

/// Um cenário de conversa: o Prof. Dash faz o outro papel (atendente, recrutador…) e a pessoa
/// conversa em inglês, por texto. Dart puro; os dados vêm de `assets/ingles/cenarios.json`.
class Cenario extends Equatable {
  final String id, titulo, emoji;

  /// A etapa do curso (A1, A2, B1, B2, C1): decide o nível do inglês do Dash.
  final String etapa;

  /// Quem o Dash faz, em português ("atendente de uma cafeteria em Chicago").
  final String papel;

  /// O que a pessoa precisa conseguir, em português ("peça um café e pague").
  final String objetivo;

  /// A 1ª fala do Dash (em inglês) e a tradução dela.
  final String abertura, aberturaPt;

  /// Frases úteis (em inglês) para quem travar.
  final List<String> dicas;

  /// Quantas falas da pessoa a conversa tem.
  final int maxTurnos;

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
  });

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
    );
  }

  @override
  List<Object?> get props => [id, titulo, emoji, etapa, papel, objetivo, abertura, aberturaPt, dicas, maxTurnos];
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
