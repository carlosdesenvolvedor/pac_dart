import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/quiz.dart';

void main() {
  late List<Trilha> trilhas;

  setUpAll(() {
    final raw = File('assets/curriculo.json').readAsStringSync();
    trilhas = (jsonDecode(raw) as List)
        .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  List<String> pool(Trilha t) => t.licoes.expand((l) => l.trechos.map((tr) => tr.cod)).toList();

  test('gera até 10 perguntas com 4 alternativas e correta válida', () {
    final t = trilhas.first;
    final quiz = gerarQuiz(t.licoes.first, pool(t), seed: 1);
    expect(quiz.length, inInclusiveRange(4, 10));
    for (final p in quiz) {
      expect(p.alternativas.length, 4);
      expect(p.correta, inInclusiveRange(0, 3));
      expect(p.alternativas.toSet().length, 4); // sem alternativas repetidas
      expect(p.enunciado, isNotEmpty);
      expect(p.codigoCerto, p.alternativas[p.correta]);
    }
  });

  test('mesmo seed gera o mesmo quiz (estável por lição)', () {
    final t = trilhas[1];
    final a = gerarQuiz(t.licoes[2], pool(t), seed: 42);
    final b = gerarQuiz(t.licoes[2], pool(t), seed: 42);
    expect(a, b);
  });

  test('toda lição do currículo consegue gerar um quiz', () {
    for (var ti = 0; ti < trilhas.length; ti++) {
      final p = pool(trilhas[ti]);
      for (var li = 0; li < trilhas[ti].licoes.length; li++) {
        final quiz = gerarQuiz(trilhas[ti].licoes[li], p, seed: ti * 1000 + li);
        expect(quiz.length, greaterThanOrEqualTo(4),
            reason: 'lição ${trilhas[ti].nivel} / ${trilhas[ti].licoes[li].nome}');
      }
    }
  });
}
