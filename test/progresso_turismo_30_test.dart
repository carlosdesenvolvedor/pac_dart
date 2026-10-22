// English Turismo com 30 pistas: ninguém perde progresso (desbloqueio CALCULADO, nada regravado) e os
// troféus de sempre abrem no mesmo ponto (só as 10 clássicas contam); os 3 extras são só do inglês.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/progresso_historia.dart';
import 'package:pac_dart/features/arcade/domain/progresso_turismo.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _ingles = 30;

Set<String> _ganhos(EstadoCampeonato c, {required bool ingles, EstatisticasGt s = EstatisticasGt.vazio}) =>
    trofeusDoTurismo(ingles: ingles).where((t) => t.ganhou(s, c)).map((t) => t.id).toSet();

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('carregar: desbloqueio calculado das pistas 11–30', () {
    test('pista_max preso em 10 + tempo da 10 → a 11 aparece liberada no inglês (sem regravar nada)', () async {
      SharedPreferences.setMockInitialValues({'turismo_pista_max': 10, 'turismo_tempo_10': 300.0});
      final e = await ProgressoTurismo.carregar(totalPistas: _ingles);
      expect(e.pistaMax, 11);
      expect(e.liberada(11), isTrue);
      expect(e.liberada(12), isFalse);
      expect(e.totalPistas, _ingles);
      final p = await SharedPreferences.getInstance();
      expect(p.getInt('turismo_pista_max'), 10, reason: 'carregar não grava nada');
    });

    test('o Dart (10 pistas) continua vendo 10, com os mesmos dados', () async {
      SharedPreferences.setMockInitialValues({'turismo_pista_max': 10, 'turismo_tempo_10': 300.0, 'turismo_medalha_10': 2});
      final e = await ProgressoTurismo.carregar();
      expect(e.pistaMax, 10);
      expect(e.totalPistas, pistasClassicas);
      expect(e.medalhaDe(10), 2);
    });

    test('medalha na 10 (sem tempo gravado) também libera a 11', () async {
      SharedPreferences.setMockInitialValues({'turismo_pista_max': 10, 'turismo_medalha_10': 1});
      expect((await ProgressoTurismo.carregar(totalPistas: _ingles)).pistaMax, 11);
    });

    test('sem tempo nem medalha na 10, a 11 segue trancada; pista_max baixo não é empurrado à toa', () async {
      SharedPreferences.setMockInitialValues({'turismo_pista_max': 10, 'turismo_tempo_9': 200.0});
      expect((await ProgressoTurismo.carregar(totalPistas: _ingles)).pistaMax, 10);
      SharedPreferences.setMockInitialValues({'turismo_pista_max': 4, 'turismo_tempo_3': 200.0});
      expect((await ProgressoTurismo.carregar(totalPistas: _ingles)).pistaMax, 4);
      SharedPreferences.setMockInitialValues({});
      expect((await ProgressoTurismo.carregar(totalPistas: _ingles)).pistaMax, 1);
    });

    test('o maior n com chegada manda; teto 30; medalhas e tempos de 11–30 são lidos', () async {
      SharedPreferences.setMockInitialValues({
        'turismo_pista_max': 10,
        'turismo_tempo_10': 300.0,
        'turismo_tempo_14': 320.0,
        'turismo_medalha_14': 3,
        'turismo_tempo_29': 400.0,
      });
      var e = await ProgressoTurismo.carregar(totalPistas: _ingles);
      expect(e.pistaMax, 30, reason: 'chegou ao fim da 29: libera a 30 (o teto)');
      expect(e.medalhaDe(14), 3);
      expect(e.tempoDe(29), 400.0);
      SharedPreferences.setMockInitialValues({'turismo_pista_max': 10, 'turismo_tempo_14': 320.0});
      e = await ProgressoTurismo.carregar(totalPistas: _ingles);
      expect(e.pistaMax, 15);
      // o Dart ignora 11–30 por completo
      e = await ProgressoTurismo.carregar();
      expect(e.pistaMax, 10);
      expect(e.tempoDe(14), isNull);
    });
  });

  group('registrar no inglês (30 pistas)', () {
    test('chegar libera a próxima até a 30, e o Dart nunca rebaixa o pista_max', () async {
      SharedPreferences.setMockInitialValues({'turismo_pista_max': 10, 'turismo_tempo_10': 300.0});
      for (var n = 11; n <= 30; n++) {
        await ProgressoTurismo.registrar(pista: n, medalha: 0, tempo: 300.0 + n, totalPistas: _ingles, chegarLibera: true);
        final e = await ProgressoTurismo.carregar(totalPistas: _ingles);
        expect(e.pistaMax, (n + 1).clamp(1, 30), reason: 'depois da $n');
        expect(e.tempoDe(n), 300.0 + n);
      }
      final p = await SharedPreferences.getInstance();
      expect(p.getInt('turismo_pista_max'), 30);
      // uma corrida do Dart depois disso não rebaixa nada
      await ProgressoTurismo.registrar(pista: 3, medalha: 2, tempo: 50);
      expect(p.getInt('turismo_pista_max'), 30);
      expect((await ProgressoTurismo.carregar()).pistaMax, 10);
      expect((await ProgressoTurismo.carregar(totalPistas: _ingles)).pistaMax, 30);
    });

    test('medalha melhor substitui, pior não rebaixa (pista extra)', () async {
      await ProgressoTurismo.registrar(pista: 22, medalha: 2, tempo: 90, totalPistas: _ingles, chegarLibera: true);
      await ProgressoTurismo.registrar(pista: 22, medalha: 1, tempo: 95, totalPistas: _ingles, chegarLibera: true);
      final e = await ProgressoTurismo.carregar(totalPistas: _ingles);
      expect(e.medalhaDe(22), 2);
      expect(e.tempoDe(22), 90);
    });
  });

  group('EstadoCampeonato: contagens por faixa', () {
    test('medalhasClassicas/ourosClassicos só 1–10; medalhasEntre inclusivo', () {
      final c = EstadoCampeonato(totalPistas: 30, medalhas: {
        for (var n = 1; n <= 30; n++) n: n.isEven ? 3 : 1,
      });
      expect(c.totalMedalhas, 30);
      expect(c.medalhasClassicas, 10);
      expect(c.ourosClassicos, 5);
      expect(c.ouros, 15);
      expect(c.medalhasEntre(11, 20), 10);
      expect(c.medalhasEntre(20, 20), 1);
      expect(c.medalhasEntre(31, 40), 0);
      expect(const EstadoCampeonato().totalPistas, pistasClassicas);
      expect(const EstadoCampeonato().historiaCompleta, isFalse);
    });

    test('medalha 0 gravada no mapa não conta', () {
      const c = EstadoCampeonato(medalhas: {1: 0, 2: 1, 12: 0});
      expect(c.medalhasClassicas, 1);
      expect(c.medalhasEntre(11, 20), 0);
    });
  });

  group('troféus', () {
    test('Dart/C# = os 12 de sempre; inglês = os 12 + volta-mundo, lenda e historia', () {
      expect(identical(trofeusDoTurismo(ingles: false), trofeusGt), isTrue);
      final ids = trofeusDoTurismo(ingles: true).map((t) => t.id).toList();
      expect(ids, [...trofeusGt.map((t) => t.id), 'volta-mundo', 'lenda', 'historia']);
      expect(ids.toSet(), hasLength(ids.length), reason: 'ids únicos');
    });

    test('campeão/dourado só com as 10 clássicas (medalha nas extras não adianta)', () {
      final soExtras = EstadoCampeonato(totalPistas: 30, medalhas: {for (var n = 11; n <= 30; n++) n: 3});
      final g = _ganhos(soExtras, ingles: true);
      expect(g, isNot(contains('campeao')));
      expect(g, isNot(contains('dourado')));
      expect(g, contains('volta-mundo'));
      expect(g, isNot(contains('lenda')));
      final quaseClassicas = EstadoCampeonato(totalPistas: 30, medalhas: {
        for (var n = 1; n <= 9; n++) n: 3,
        for (var n = 11; n <= 30; n++) n: 3,
      });
      expect(_ganhos(quaseClassicas, ingles: true), isNot(contains('campeao')));
      final classicas = EstadoCampeonato(medalhas: {for (var n = 1; n <= 10; n++) n: 3});
      expect(_ganhos(classicas, ingles: false), containsAll(['campeao', 'dourado']));
      expect(_ganhos(classicas, ingles: true), containsAll(['campeao', 'dourado']));
    });

    test('nenhum troféu antigo some com as 10 medalhas (com e sem as extras)', () {
      final dez = EstadoCampeonato(medalhas: {for (var n = 1; n <= 10; n++) n: 3});
      final antes = _ganhos(dez, ingles: false);
      expect(antes, containsAll(['ouro', 'metade', 'campeao', 'dourado']));
      final trinta = EstadoCampeonato(totalPistas: 30, medalhas: {for (var n = 1; n <= 30; n++) n: 3});
      expect(_ganhos(trinta, ingles: false), antes);
      expect(_ganhos(trinta, ingles: true), containsAll(antes));
    });

    test('volta-mundo pede as 10 de 11–20; lenda pede as 30', () {
      final faltaUma = EstadoCampeonato(totalPistas: 30, medalhas: {for (var n = 11; n <= 19; n++) n: 1});
      expect(_ganhos(faltaUma, ingles: true), isNot(contains('volta-mundo')));
      final vinteNove = EstadoCampeonato(totalPistas: 30, medalhas: {for (var n = 1; n <= 29; n++) n: 1});
      expect(_ganhos(vinteNove, ingles: true), containsAll(['campeao', 'volta-mundo']));
      expect(_ganhos(vinteNove, ingles: true), isNot(contains('lenda')));
      final trinta = EstadoCampeonato(totalPistas: 30, medalhas: {for (var n = 1; n <= 30; n++) n: 1});
      expect(_ganhos(trinta, ingles: true), contains('lenda'));
      expect(_ganhos(trinta, ingles: false), isNot(contains('lenda')), reason: 'extras só no inglês');
    });

    test('📖 historia só com c30 (assistido até o fim) — f30 (pulado) não conta', () async {
      await ProgressoHistoria.marcarVisto(30, ParteDoCapitulo.fim); // pulou
      var e = await ProgressoTurismo.carregar(totalPistas: _ingles);
      expect(e.historiaCompleta, isFalse);
      expect(_ganhos(e, ingles: true), isNot(contains('historia')));
      await ProgressoHistoria.marcarVisto(29, ParteDoCapitulo.fim, assistido: true); // outro capítulo
      e = await ProgressoTurismo.carregar(totalPistas: _ingles);
      expect(e.historiaCompleta, isFalse);
      await ProgressoHistoria.marcarVisto(30, ParteDoCapitulo.fim, assistido: true);
      e = await ProgressoTurismo.carregar(totalPistas: _ingles);
      expect(e.historiaCompleta, isTrue);
      expect(_ganhos(e, ingles: true), contains('historia'));
      expect(_ganhos(e, ingles: false), isNot(contains('historia')), reason: 'Dart/C# não têm o 📖');
    });
  });
}
