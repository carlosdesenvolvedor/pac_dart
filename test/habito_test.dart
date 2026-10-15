import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';

/// 12/out/2026 é o "hoje" dos testes (a hora muda de caso para caso).
DateTime em(int diasDepois, {int h = 10, int min = 0}) => DateTime(2026, 10, 12 + diasDepois, h, min);

int dia(int diasDepois) => diaDe(em(diasDepois));

/// Um hábito com a última meta batida em [ultima] (relativa a hoje) e [seq] de sequência.
Habito comSequencia(int seq, {required int ultima, int frz = 0, int meta = 20, int unidades = 0, int? diaAtual}) => Habito(
      meta: meta,
      dia: diaAtual ?? dia(ultima),
      unidadesHoje: unidades,
      sequencia: seq,
      melhor: seq,
      ultimoDiaMeta: dia(ultima),
      congelamentos: frz,
      historico: [dia(ultima)],
    );

void main() {
  group('diaDe', () {
    test('é a mesma conta de Revisao.dia (virada de mês, de ano, bissexto e horário de verão)', () {
      final datas = [
        DateTime(2026, 10, 12, 0, 0),
        DateTime(2026, 10, 12, 23, 59, 59),
        DateTime(2024, 2, 28, 23, 59),
        DateTime(2024, 2, 29, 0, 1),
        DateTime(2024, 3, 1),
        DateTime(2025, 12, 31, 23, 59),
        DateTime(2026, 1, 1),
        DateTime(2026, 3, 8, 2, 30), // virada do horário de verão nos EUA
        DateTime(2026, 11, 1, 1, 30), // ...e a volta
        DateTime(2026, 3, 29, 1, 30), // Europa
        DateTime(2000, 2, 29),
        DateTime(1999, 12, 31),
      ];
      for (final d in datas) {
        expect(diaDe(d), Revisao.dia(d), reason: '$d');
      }
    });

    test('dias seguidos diferem de 1, inclusive na virada do ano e no 29 de fevereiro', () {
      expect(diaDe(DateTime(2026, 1, 1)) - diaDe(DateTime(2025, 12, 31)), 1);
      expect(diaDe(DateTime(2024, 3, 1)) - diaDe(DateTime(2024, 2, 29)), 1);
      expect(diaDe(DateTime(2024, 2, 29)) - diaDe(DateTime(2024, 2, 28)), 1);
      expect(diaDe(DateTime(2025, 3, 1)) - diaDe(DateTime(2025, 2, 28)), 1);
      expect(diaDe(DateTime(2026, 3, 9)) - diaDe(DateTime(2026, 3, 8)), 1);
    });

    test('23:59 e 00:01 são dias diferentes; qualquer hora do mesmo dia é o mesmo', () {
      expect(diaDe(em(0, h: 23, min: 59)) + 1, diaDe(em(1, h: 0, min: 1)));
      expect(diaDe(em(0, h: 0, min: 0)), diaDe(em(0, h: 23, min: 59)));
    });
  });

  group('registrar — a meta do dia', () {
    test('primeiro uso: abaixo da meta só soma; ao alcançá-la a sequência vira 1', () {
      var h = Habito.vazio;
      expect(h.meta, 20);
      h = h.registrar(19, em(0));
      expect(h.unidadesHoje, 19);
      expect(h.sequencia, 0);
      expect(h.ultimoDiaMeta, isNull);
      expect(h.historico, isEmpty);
      h = h.registrar(1, em(0));
      expect(h.unidadesHoje, 20);
      expect(h.sequencia, 1);
      expect(h.melhor, 1);
      expect(h.ultimoDiaMeta, dia(0));
      expect(h.historico, [dia(0)]);
    });

    test('a meta vale com ">=" (exatamente 20 de 20 já conta)', () {
      expect(Habito.vazio.registrar(20, em(0)).sequencia, 1);
      expect(Habito.vazio.registrar(19, em(0)).sequencia, 0);
    });

    test('meta batida duas vezes no mesmo dia conta uma só', () {
      var h = Habito.vazio.registrar(20, em(0));
      h = h.registrar(5, em(0, h: 18));
      h = h.registrar(30, em(0, h: 22));
      expect(h.sequencia, 1);
      expect(h.historico, [dia(0)]);
      expect(h.unidadesHoje, 55);
      expect(h.congelamentos, 0);
    });

    test('unidades < 1 são ignoradas', () {
      expect(Habito.vazio.registrar(0, em(0)), Habito.vazio);
      expect(Habito.vazio.registrar(-3, em(0)), Habito.vazio);
    });

    test('bater a meta às 23:59 e estudar às 00:01 são dias diferentes: sequência +1', () {
      var h = Habito.vazio.registrar(20, em(0, h: 23, min: 59));
      expect(h.sequencia, 1);
      h = h.registrar(1, em(1, h: 0, min: 1));
      expect(h.sequencia, 1, reason: '1 exercício do dia novo ainda não bate a meta');
      expect(h.unidadesHoje, 1, reason: 'o contador zerou na virada');
      h = h.registrar(19, em(1, h: 0, min: 5));
      expect(h.sequencia, 2);
      expect(h.historico, [dia(0), dia(1)]);
    });

    test('dias seguidos somam; o melhor acompanha', () {
      var h = Habito.vazio;
      for (var i = 0; i < 5; i++) {
        h = h.registrar(20, em(i));
      }
      expect((h.sequencia, h.melhor), (5, 5));
    });

    test('a virada do dia zera as unidades sem meta batida', () {
      var h = Habito.vazio.registrar(15, em(0));
      h = h.registrar(3, em(1));
      expect(h.unidadesHoje, 3, reason: 'os 15 de ontem não valem hoje');
      expect(h.sequencia, 0);
    });

    test('virada de ano e ano bissexto não quebram a sequência', () {
      var h = Habito.vazio;
      for (final d in [DateTime(2025, 12, 30), DateTime(2025, 12, 31), DateTime(2026, 1, 1)]) {
        h = h.registrar(20, d);
      }
      expect(h.sequencia, 3);
      h = Habito.vazio;
      for (final d in [DateTime(2024, 2, 28), DateTime(2024, 2, 29), DateTime(2024, 3, 1)]) {
        h = h.registrar(20, d);
      }
      expect(h.sequencia, 3);
    });

    test('horário de verão (dia de 23 ou 25 horas) não perde o dia', () {
      var h = Habito.vazio;
      for (final d in [DateTime(2026, 3, 7, 23, 50), DateTime(2026, 3, 8, 0, 10), DateTime(2026, 3, 9, 0, 10)]) {
        h = h.registrar(20, d);
      }
      expect(h.sequencia, 3);
    });
  });

  group('registrar — dias perdidos e congelamento', () {
    test('1 dia perdido COM congelamento: mantém a sequência, gasta 1 e anota o dia', () {
      final h = comSequencia(5, ultima: -2, frz: 1).registrar(20, em(0));
      expect(h.sequencia, 6);
      expect(h.congelamentos, 0);
      expect(h.congelados, [dia(-1)]);
      expect(h.historico, [dia(-2), dia(0)]);
    });

    test('1 dia perdido SEM congelamento: recomeça em 1', () {
      final h = comSequencia(5, ultima: -2, frz: 0).registrar(20, em(0));
      expect(h.sequencia, 1);
      expect(h.melhor, 5, reason: 'o melhor não cai');
      expect(h.congelados, isEmpty);
    });

    test('recomeçar NÃO gasta os congelamentos guardados', () {
      // 3 dias perdidos com só 2 congelamentos: a sequência acaba, e os 2 continuam lá
      final h = comSequencia(9, ultima: -4, frz: 2).registrar(20, em(0));
      expect(h.sequencia, 1);
      expect(h.congelamentos, 2);
      expect(h.congelados, isEmpty);
    });

    test('2 dias perdidos com 2 congelamentos: cobre os dois', () {
      final h = comSequencia(9, ultima: -3, frz: 2).registrar(20, em(0));
      expect(h.sequencia, 10);
      expect(h.congelamentos, 0);
      expect(h.congelados, [dia(-2), dia(-1)]);
    });

    test('ganha 1 congelamento a cada 7 dias (7, 14…) e nunca passa de 2', () {
      var h = Habito.vazio;
      final guardados = <int>[];
      for (var i = 0; i < 28; i++) {
        h = h.registrar(20, em(i));
        guardados.add(h.congelamentos);
      }
      expect(guardados[5], 0, reason: 'dia 6');
      expect(guardados[6], 1, reason: 'dia 7');
      expect(guardados[12], 1, reason: 'dia 13');
      expect(guardados[13], 2, reason: 'dia 14');
      expect(guardados[20], 2, reason: 'dia 21: já tinha 2');
      expect(guardados[27], 2);
      expect(h.sequencia, 28);
    });

    test('gastar um congelamento e chegar ao múltiplo de 7 no mesmo dia: gasta e ganha', () {
      // 6 dias de sequência, 1 dia perdido, 1 congelamento: hoje vira 7 → gasta 1 e ganha 1
      final h = comSequencia(6, ultima: -2, frz: 1).registrar(20, em(0));
      expect(h.sequencia, 7);
      expect(h.congelamentos, 1);
    });

    test('recomeçar em 1 não ganha congelamento', () {
      expect(comSequencia(6, ultima: -5, frz: 0).registrar(20, em(0)).congelamentos, 0);
    });

    test('histórico e congelados guardam só os últimos 60 dias', () {
      var h = Habito.vazio;
      for (var i = 0; i < 80; i++) {
        h = h.registrar(20, em(i));
      }
      expect(h.historico.length, 60);
      expect(h.historico.last, dia(79));
      expect(h.historico.first, dia(20));
      expect(h.historico, orderedEquals([...h.historico]..sort()));
    });
  });

  group('relógio que volta atrás é ignorado', () {
    test('estudar "ontem" depois de hoje conta como hoje, sem desfazer nada', () {
      var h = Habito.vazio.registrar(10, em(0));
      h = h.registrar(10, em(-1));
      expect(h.dia, dia(0));
      expect(h.sequencia, 1);
      expect(h.unidadesHoje, 20, reason: 'as unidades somam no dia que vale');
      expect(h.historico, [dia(0)]);
    });

    test('depois de uma meta batida, voltar o relógio não dá sequência dupla nem apaga a visível', () {
      var h = Habito.vazio.registrar(20, em(0));
      h = h.registrar(20, em(-3));
      expect(h.sequencia, 1);
      expect(h.historico, [dia(0)]);
      expect(h.sequenciaVisivel(em(-3)), 1);
      expect(h.progressoHoje(em(-3)), 1);
    });

    test('um documento com a última meta no futuro do "dia" não gera dias perdidos negativos', () {
      final h = Habito.fromJson({'v': 1, 'dia': dia(0), 'ult': dia(5), 'seq': 4, 'frz': 1});
      expect(h.dia, dia(5));
      final depois = h.registrar(20, em(0));
      expect(depois.sequencia, 4, reason: 'mesmo dia lógico da última meta: não conta de novo');
      expect(depois.congelamentos, 1);
    });
  });

  group('mudarMeta', () {
    test('só aceita 10, 20 e 40', () {
      final h = Habito.vazio;
      expect(h.mudarMeta(10, em(0)).meta, 10);
      expect(h.mudarMeta(40, em(0)).meta, 40);
      expect(h.mudarMeta(15, em(0)), h);
      expect(h.mudarMeta(0, em(0)), h);
    });

    test('baixar a meta depois de já ter feito os exercícios bate a meta de hoje', () {
      var h = Habito.vazio.registrar(12, em(0));
      expect(h.sequencia, 0);
      h = h.mudarMeta(10, em(0));
      expect(h.meta, 10);
      expect(h.sequencia, 1);
      expect(h.ultimoDiaMeta, dia(0));
      expect(h.historico, [dia(0)]);
    });

    test('subir a meta depois de bater não desfaz a de hoje', () {
      var h = Habito.vazio.registrar(20, em(0));
      h = h.mudarMeta(40, em(0));
      expect(h.sequencia, 1);
      expect(h.bateuHoje(em(0)), isTrue);
      expect(h.registrar(1, em(0)).sequencia, 1);
    });

    test('mudar a meta com o dia virado começa o dia novo do zero', () {
      var h = Habito.vazio.registrar(15, em(0));
      h = h.mudarMeta(10, em(1));
      expect(h.unidadesHoje, 0);
      expect(h.sequencia, 0);
    });

    test('trocar a meta é o mesmo que ela ter sido essa o dia todo (mesma regra do passo 4)', () {
      final h = comSequencia(3, ultima: -1, unidades: 0, diaAtual: dia(0)).registrar(10, em(0)).mudarMeta(10, em(0));
      expect(h.sequencia, 4);
    });
  });

  group('o que o chip mostra', () {
    test('sem nunca ter batido: 0, sem risco, sem progresso', () {
      final h = Habito.vazio;
      expect(h.sequenciaVisivel(em(0)), 0);
      expect(h.emRisco(em(0)), isFalse);
      expect(h.progressoHoje(em(0)), 0);
    });

    test('sequenciaVisivel antes de estudar hoje (tabela)', () {
      // (dias desde a última meta, congelamentos) → sequência visível
      final casos = <(int, int, int)>[
        (0, 0, 7), // bateu hoje
        (1, 0, 7), // bateu ontem: ainda dá tempo hoje
        (2, 0, 0), // 1 dia perdido, sem congelamento: acabou
        (2, 1, 7), // 1 perdido e 1 congelamento: viva
        (3, 1, 0), // 2 perdidos, 1 congelamento: acabou
        (3, 2, 7),
        (4, 2, 0), // 3 perdidos, 2 congelamentos: acabou (não mostra número velho)
      ];
      for (final (atras, frz, esperado) in casos) {
        final h = comSequencia(7, ultima: -atras, frz: frz);
        expect(h.sequenciaVisivel(em(0)), esperado, reason: '$atras dia(s) atrás, $frz congelamento(s)');
      }
    });

    test('emRisco: sequência viva e hoje sem meta', () {
      expect(comSequencia(3, ultima: -1).emRisco(em(0)), isTrue);
      expect(comSequencia(3, ultima: 0).emRisco(em(0)), isFalse, reason: 'já bateu hoje');
      expect(comSequencia(3, ultima: -2).emRisco(em(0)), isFalse, reason: 'a sequência acabou');
      expect(comSequencia(3, ultima: -2, frz: 1).emRisco(em(0)), isTrue, reason: 'congelamento ainda segura');
    });

    test('progressoHoje: fração limitada a 1 e zero quando o dia virou', () {
      final h = Habito.vazio.registrar(5, em(0));
      expect(h.progressoHoje(em(0)), .25);
      expect(h.registrar(100, em(0)).progressoHoje(em(0)), 1);
      expect(h.progressoHoje(em(1)), 0, reason: 'dia virou e nada foi feito ainda');
      expect(h.feitasHoje(em(1)), 0);
      expect(h.feitasHoje(em(0)), 5);
    });

    test('estadoDe: feito, congelado e perdido', () {
      final h = comSequencia(5, ultima: -2, frz: 1).registrar(20, em(0));
      expect(h.estadoDe(dia(0)), EstadoDoDia.feito);
      expect(h.estadoDe(dia(-1)), EstadoDoDia.congelado);
      expect(h.estadoDe(dia(-5)), EstadoDoDia.perdido);
    });
  });

  group('mesclar (aparelho × nuvem)', () {
    final adiantado = Habito.vazio.registrar(20, em(0)).registrar(20, em(1)).registrar(20, em(2)); // seq 3
    final atrasado = Habito.vazio.registrar(20, em(0)); // seq 1

    test('vence quem bateu a meta mais recentemente, em qualquer ordem', () {
      expect(Habito.mesclar(adiantado, atrasado).sequencia, 3);
      expect(Habito.mesclar(atrasado, adiantado).sequencia, 3);
      expect(Habito.mesclar(adiantado, atrasado), Habito.mesclar(atrasado, adiantado));
    });

    test('quem nunca bateu perde de qualquer data', () {
      final nunca = Habito.vazio.registrar(19, em(5));
      expect(Habito.mesclar(nunca, atrasado).sequencia, 1);
      expect(Habito.mesclar(atrasado, nunca).sequencia, 1);
    });

    test('empate na última meta: o dia e depois os exercícios feitos desempatam', () {
      final a = adiantado.registrar(3, em(3)); // dia novo, 3 exercícios
      final b = adiantado.registrar(7, em(3));
      expect(Habito.mesclar(a, b).unidadesHoje, 7);
      expect(Habito.mesclar(b, a).unidadesHoje, 7);
      final c = adiantado; // ainda no dia 2
      expect(Habito.mesclar(a, c).dia, dia(3));
      expect(Habito.mesclar(c, a).dia, dia(3));
    });

    test('o melhor é o maior dos dois e os históricos se unem', () {
      final velho = comSequencia(30, ultima: -20).copyWith(sequencia: 2, historico: [dia(-30), dia(-29)]);
      final novo = Habito.vazio.registrar(20, em(0));
      final m = Habito.mesclar(velho, novo);
      expect(m.sequencia, 1);
      expect(m.melhor, 30);
      expect(m.historico, [dia(-30), dia(-29), dia(0)]);
    });

    test('é comutativa e idempotente (várias combinações)', () {
      final amostras = <Habito>[
        Habito.vazio,
        atrasado,
        adiantado,
        adiantado.registrar(4, em(3)),
        adiantado.mudarMeta(40, em(2)),
        comSequencia(9, ultima: -2, frz: 2),
        comSequencia(9, ultima: -2, frz: 1),
        comSequencia(4, ultima: 0).copyWith(congelados: [dia(-3)]),
      ];
      for (final a in amostras) {
        expect(Habito.mesclar(a, a), a);
        for (final b in amostras) {
          expect(Habito.mesclar(a, b), Habito.mesclar(b, a));
        }
      }
    });

    test('a meta é a do vencedor', () {
      final a = adiantado.mudarMeta(40, em(2));
      expect(Habito.mesclar(a, atrasado).meta, 40);
      expect(Habito.mesclar(atrasado, a).meta, 40);
    });
  });

  group('JSON', () {
    test('ida e volta preserva tudo', () {
      var h = Habito.vazio;
      for (var i = 0; i < 9; i++) {
        h = h.registrar(20, em(i));
      }
      h = comSequencia(5, ultima: -2, frz: 1).registrar(20, em(0)).mudarMeta(40, em(0));
      final volta = Habito.fromJson(h.toJson());
      expect(volta, h);
      expect(h.toJson()['v'], 1);
    });

    test('formato: v, meta, dia, un, seq, melhor, ult, frz, hist, gel', () {
      expect(Habito.vazio.toJson().keys, ['v', 'meta', 'dia', 'un', 'seq', 'melhor', 'ult', 'frz', 'hist', 'gel']);
    });

    test('lixo nunca lança: volta ao padrão', () {
      for (final lixo in <Object?>[null, 42, 'texto', <Object?>[], <String, Object?>{}, {'meta': 'x'}]) {
        expect(Habito.fromJson(lixo), Habito.vazio, reason: '$lixo');
      }
    });

    test('campo ausente, de tipo errado ou impossível vira o padrão só naquele campo', () {
      final h = Habito.fromJson({
        'v': 1,
        'meta': 15, // não permitida
        'dia': 'ontem',
        'un': -4,
        'seq': 3.9,
        'melhor': 1, // menor que a sequência: corrige
        'ult': 100,
        'frz': 9, // passa do máximo
        'hist': [100, 'x', null, 99, 100, -5, 98.0],
        'gel': 'nada',
      });
      expect(h.meta, 20);
      expect(h.dia, 100, reason: 'nunca antes da última meta');
      expect(h.unidadesHoje, 0);
      expect(h.sequencia, 3);
      expect(h.melhor, 3);
      expect(h.ultimoDiaMeta, 100);
      expect(h.congelamentos, 2);
      expect(h.historico, [98, 99, 100]);
      expect(h.congelados, isEmpty);
    });

    test('um mapa vindo do Firestore (Map<dynamic, dynamic>) também serve', () {
      final h = Habito.fromJson(<dynamic, dynamic>{'meta': 40, 'seq': 2, 'ult': 10, 'dia': 10, 'melhor': 5});
      expect((h.meta, h.sequencia, h.melhor), (40, 2, 5));
    });
  });
}
