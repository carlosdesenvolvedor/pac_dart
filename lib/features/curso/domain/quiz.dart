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

/// Um código curto o bastante para virar alternativa.
bool _cabeNaAlternativa(String c) => c.length <= 90 && '\n'.allMatches(c).length <= 2;

/// Os candidatos a pergunta (antes de embaralhar): os trechos curtos e com dica; menos de 4, todos.
List<Trecho> _candidatosDoQuiz(Licao licao) {
  final c = licao.trechos.where((t) => _cabeNaAlternativa(t.cod) && t.dicaPlana.isNotEmpty).toList();
  return c.length < 4 ? licao.trechos.toList() : c;
}

/// Quantas perguntas o quiz da lição tem, sem montar as alternativas (barato). O [gerarQuiz] só faz
/// menos quando faltam distratores.
int tamanhoDoQuiz(Licao licao, {int max = 10}) => min(max, _candidatosDoQuiz(licao).length);

/// Gera até [max] perguntas a partir dos exercícios da lição.
/// Enunciado = a dica (ou a saída) do trecho; alternativas = 4 códigos,
/// sendo 3 distratores de outros exercícios da mesma lição/trilha.
/// O [seed] deixa o quiz estável por lição.
List<PerguntaQuiz> gerarQuiz(Licao licao, List<String> poolTrilha, {int max = 10, required int seed}) {
  final rnd = Random(seed);

  // candidatos a pergunta: trechos curtos o bastante para virar alternativa
  final candidatos = _candidatosDoQuiz(licao);
  candidatos.shuffle(rnd);

  final distratoresBase = <String>{
    ...licao.trechos.map((t) => t.cod),
    ...poolTrilha.where(_cabeNaAlternativa),
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
