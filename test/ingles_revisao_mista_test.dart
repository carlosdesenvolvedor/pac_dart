import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/revisao_mista.dart';
import 'package:shared_preferences/shared_preferences.dart';

Licao _licao(String id, int n, {int palavras = 4}) => Licao(
      nome: id,
      emoji: '📘',
      id: id,
      trechos: [
        for (var i = 0; i < n; i++)
          Trecho(cod: '${List.filled(palavras - 1, 'word').join(' ')} $id$i.', dica: 'frase $id $i', out: ''),
      ],
    );

void main() {
  group('montarRevisaoMista', () {
    final licoes = [for (var i = 0; i < 20; i++) _licao('l$i', 8)];

    test('10 exercícios, de 10 lições diferentes, sem frase repetida', () {
      final ex = montarRevisaoMista(licoes, rnd: Random(1));
      expect(ex, hasLength(exerciciosDaRevisaoMista));
      expect(ex.map((e) => e.licao.id).toSet(), hasLength(10));
      expect(ex.map((e) => e.trecho.cod).toSet(), hasLength(10));
    });

    test('mistura os 4 tipos nas cotas 3·3·2·2', () {
      final ex = montarRevisaoMista(licoes, rnd: Random(2));
      int n(TipoExercicio t) => ex.where((e) => e.tipo == t).length;
      expect(n(TipoExercicio.escrever), 3);
      expect(n(TipoExercicio.blocos), 3);
      expect(n(TipoExercicio.escutar), 2);
      expect(n(TipoExercicio.falar), 2);
    });

    test('sem escutar e sem falar, só escrever e blocos', () {
      final ex = montarRevisaoMista(licoes, podeEscutar: false, podeFalar: false, rnd: Random(3));
      expect(ex, hasLength(10));
      expect(ex.map((e) => e.tipo).toSet(), {TipoExercicio.escrever, TipoExercicio.blocos});
    });

    test('poucas lições: repete lição, mas nunca a frase; pouca frase = sessão menor', () {
      final duas = [_licao('a', 3), _licao('b', 2)];
      final ex = montarRevisaoMista(duas, rnd: Random(4));
      expect(ex, hasLength(5));
      expect(ex.map((e) => e.trecho.cod).toSet(), hasLength(5));
      expect(montarRevisaoMista(const [], rnd: Random(4)), isEmpty);
    });

    test('frase de 1–2 palavras nunca vira blocos', () {
      final curtas = [for (var i = 0; i < 12; i++) _licao('c$i', 2, palavras: 2)];
      for (var s = 0; s < 20; s++) {
        final ex = montarRevisaoMista(curtas, rnd: Random(s));
        expect(ex.where((e) => e.tipo == TipoExercicio.blocos), isEmpty);
      }
    });

    test('o peso puxa as frases fracas', () {
      final fraca = licoes.first.trechos.first;
      var saiu = 0;
      for (var s = 0; s < 200; s++) {
        final ex = montarRevisaoMista(licoes, peso: (f) => f == fraca ? 20 : 1, rnd: Random(s));
        if (ex.any((e) => e.trecho == fraca)) saiu++;
      }
      // sem peso ela sairia ~6% das vezes (10 de 160 frases)
      expect(saiu, greaterThan(80));
    });

    test('nunca o mesmo tipo três vezes seguidas quando dá para evitar', () {
      for (var s = 0; s < 50; s++) {
        final ex = montarRevisaoMista(licoes, rnd: Random(s));
        for (var i = 2; i < ex.length; i++) {
          final trinca = ex[i].tipo == ex[i - 1].tipo && ex[i].tipo == ex[i - 2].tipo;
          final resto = ex.skip(i + 1).any((e) => e.tipo != ex[i].tipo);
          expect(trinca && resto, isFalse, reason: 'semente $s: $ex');
        }
      }
    });
  });

  test('cotasDosTipos soma sempre o total', () {
    for (var total = 1; total <= 12; total++) {
      for (final disp in [
        TipoExercicio.values.toSet(),
        {TipoExercicio.escrever, TipoExercicio.blocos, TipoExercicio.escutar},
        {TipoExercicio.escrever, TipoExercicio.blocos},
      ]) {
        expect(cotasDosTipos(disp, total).values.fold<int>(0, (a, b) => a + b), total);
      }
    }
  });

  test('semOTipo troca só dali para frente, por escrever/blocos', () {
    final l = _licao('x', 4);
    final lista = [
      ExercicioMisto(l.trechos[0], l, TipoExercicio.escutar),
      ExercicioMisto(l.trechos[1], l, TipoExercicio.falar),
      ExercicioMisto(l.trechos[2], l, TipoExercicio.escutar),
      ExercicioMisto(l.trechos[3], l, TipoExercicio.escutar),
    ];
    final nova = semOTipo(lista, TipoExercicio.escutar, desde: 1);
    expect(nova[0].tipo, TipoExercicio.escutar);
    expect(nova[1].tipo, TipoExercicio.falar);
    expect(nova.skip(2).map((e) => e.tipo), everyElement(isIn([TipoExercicio.escrever, TipoExercicio.blocos])));
    expect({nova[2].tipo, nova[3].tipo}, hasLength(2), reason: 'alterna os dois');
  });

  test('não posso escutar/falar vale uma hora', () async {
    SharedPreferences.setMockInitialValues({});
    final agora = DateTime(2026, 10, 24, 12);
    await PrefsRevisaoMista.desligar(TipoExercicio.escutar, agora: agora);
    var p = await PrefsRevisaoMista.carregar(agora: agora.add(const Duration(minutes: 30)));
    expect(p.semAudio, isNotNull);
    expect(p.semFala, isNull);
    p = await PrefsRevisaoMista.carregar(agora: agora.add(const Duration(minutes: 61)));
    expect(p.semAudio, isNull);
  });
}
