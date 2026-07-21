import 'dart:math';

import 'package:equatable/equatable.dart';

import 'curriculo.dart';

class PerguntaQuiz extends Equatable {
  final String enunciado;
  final List<String> alternativas; // 4 códigos
  final int correta; // índice da certa

  const PerguntaQuiz({required this.enunciado, required this.alternativas, required this.correta});

  String get codigoCerto => alternativas[correta];

  @override
  List<Object?> get props => [enunciado, alternativas, correta];
}

/// Gera até [max] perguntas a partir dos exercícios da lição.
/// Enunciado = a dica (ou a saída) do trecho; alternativas = 4 códigos,
/// sendo 3 distratores de outros exercícios da mesma lição/trilha.
/// O [seed] deixa o quiz estável por lição.
List<PerguntaQuiz> gerarQuiz(Licao licao, List<String> poolTrilha, {int max = 10, required int seed}) {
  final rnd = Random(seed);

  // candidatos a pergunta: trechos curtos o bastante para virar alternativa
  bool curto(String c) => c.length <= 90 && '\n'.allMatches(c).length <= 2;
  var candidatos = licao.trechos.where((t) => curto(t.cod) && t.dicaPlana.isNotEmpty).toList();
  if (candidatos.length < 4) candidatos = licao.trechos.toList();
  candidatos.shuffle(rnd);

  final distratoresBase = <String>{
    ...licao.trechos.map((t) => t.cod),
    ...poolTrilha.where(curto),
  };

  final perguntas = <PerguntaQuiz>[];
  for (final t in candidatos.take(max)) {
    final distratores = distratoresBase.where((c) => c != t.cod).toList()..shuffle(rnd);
    if (distratores.length < 3) break;
    final alternativas = [t.cod, ...distratores.take(3)]..shuffle(rnd);
    final enunciado = t.dicaPlana.isNotEmpty
        ? 'Qual código faz isto: "${t.dicaPlana}"'
        : 'Qual código produz: ${t.out}';
    perguntas.add(PerguntaQuiz(
      enunciado: enunciado,
      alternativas: alternativas,
      correta: alternativas.indexOf(t.cod),
    ));
  }
  return perguntas;
}
