import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/habito/domain/lembrete.dart';

const _ligado = ConfigLembrete(ligado: true);

List<LembreteAgendado> _prox(DateTime agora, {ConfigLembrete config = _ligado, bool bateu = false, int? dias}) =>
    dias == null
        ? proximosLembretes(agora: agora, config: config, metaBatidaHoje: bateu)
        : proximosLembretes(agora: agora, config: config, metaBatidaHoje: bateu, dias: dias);

String _dia(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

void main() {
  group('ConfigLembrete', () {
    test('o padrão é DESLIGADO às 20:00', () {
      expect(ConfigLembrete.padrao.ligado, isFalse);
      expect(ConfigLembrete.padrao.hora, 20);
      expect(ConfigLembrete.padrao.minuto, 0);
      expect(ConfigLembrete.padrao.horario, '20:00');
    });

    test('horario tem sempre dois dígitos', () {
      expect(const ConfigLembrete(hora: 7, minuto: 5).horario, '07:05');
      expect(const ConfigLembrete(hora: 0, minuto: 0).horario, '00:00');
      expect(const ConfigLembrete(hora: 23, minuto: 59).horario, '23:59');
    });

    test('ida e volta pelo JSON', () {
      const c = ConfigLembrete(ligado: true, hora: 7, minuto: 45);
      expect(ConfigLembrete.fromJson(c.toJson()), c);
      expect(c.toJson()['v'], 1);
    });

    final estragados = <String, Object?>{
      'null': null,
      'texto': 'oi',
      'lista': [1, 2],
      'número': 3,
      'mapa vazio': <String, Object?>{},
      'ligado de outro tipo': {'ligado': 'sim', 'hora': 8, 'minuto': 0},
      'hora fora da faixa': {'ligado': true, 'hora': 25, 'minuto': 0},
      'hora negativa': {'ligado': true, 'hora': -1, 'minuto': 0},
      'minuto fora da faixa': {'ligado': true, 'hora': 8, 'minuto': 60},
      'hora de outro tipo': {'ligado': true, 'hora': '8', 'minuto': 30.5},
    };
    estragados.forEach((nome, json) {
      test('JSON estragado ($nome) nunca lança e volta ao padrão nos campos ruins', () {
        final c = ConfigLembrete.fromJson(json);
        expect(c.hora, inInclusiveRange(0, 23));
        expect(c.minuto, inInclusiveRange(0, 59));
      });
    });

    test('campos ruins caem no padrão, os bons ficam', () {
      expect(ConfigLembrete.fromJson({'ligado': true, 'hora': 25, 'minuto': 10}), const ConfigLembrete(ligado: true, hora: 20, minuto: 10));
      expect(ConfigLembrete.fromJson({'ligado': 'sim', 'hora': 8, 'minuto': 30}), const ConfigLembrete(ligado: false, hora: 8, minuto: 30));
    });

    test('copyWith troca só o que pediu', () {
      expect(ConfigLembrete.padrao.copyWith(ligado: true), const ConfigLembrete(ligado: true));
      expect(_ligado.copyWith(hora: 6, minuto: 15), const ConfigLembrete(ligado: true, hora: 6, minuto: 15));
    });
  });

  group('proximosLembretes (a regra)', () {
    test('desligado: nenhum lembrete, qualquer que seja o dia', () {
      expect(_prox(DateTime(2026, 10, 13, 10), config: ConfigLembrete.padrao), isEmpty);
      expect(_prox(DateTime(2026, 10, 13, 10), config: const ConfigLembrete(hora: 8), bateu: true), isEmpty);
    });

    test('ligado de manhã: 7 dias, hoje e os 6 seguintes, às 20:00, com ids estáveis por dia', () {
      final l = _prox(DateTime(2026, 10, 13, 10));
      expect(l.length, diasDeLembrete);
      expect(diasDeLembrete, 7);
      expect([for (final x in l) _dia(x.quando)],
          ['2026-10-13', '2026-10-14', '2026-10-15', '2026-10-16', '2026-10-17', '2026-10-18', '2026-10-19']);
      for (final x in l) {
        expect((x.quando.hour, x.quando.minute, x.quando.second), (20, 0, 0));
      }
      expect([for (final x in l) x.id], [for (var i = 0; i < 7; i++) idBaseLembrete + i]);
    });

    test('ligar DEPOIS do horário: hoje não entra (começa amanhã) e os ids seguem o dia', () {
      final l = _prox(DateTime(2026, 10, 13, 21, 0));
      expect(l.length, 6);
      expect(_dia(l.first.quando), '2026-10-14');
      expect(l.first.id, idBaseLembrete + 1);
    });

    test('no segundo exato do horário já passou; um segundo antes ainda vale', () {
      expect(_dia(_prox(DateTime(2026, 10, 13, 20, 0, 0)).first.quando), '2026-10-14');
      expect(_dia(_prox(DateTime(2026, 10, 13, 19, 59, 59)).first.quando), '2026-10-13');
    });

    test('meta de hoje batida: hoje sai, o resto fica', () {
      final l = _prox(DateTime(2026, 10, 13, 10), bateu: true);
      expect(l.length, 6);
      expect(_dia(l.first.quando), '2026-10-14');
      expect(l.map((x) => x.id), [for (var i = 1; i < 7; i++) idBaseLembrete + i]);
    });

    test('meta batida E horário já passado: continuam 6 (não é "5")', () {
      expect(_prox(DateTime(2026, 10, 13, 22), bateu: true).length, 6);
    });

    test('meta NÃO batida não afeta os dias seguintes', () {
      expect(_prox(DateTime(2026, 10, 13, 10)).length, 7);
      expect(_prox(DateTime(2026, 10, 13, 10), bateu: true).skip(0).every((x) => x.quando.isAfter(DateTime(2026, 10, 13, 20))), isTrue);
    });

    test('virada de mês, de ano e ano bissexto', () {
      expect([for (final x in _prox(DateTime(2028, 2, 27, 8))) _dia(x.quando)],
          ['2028-02-27', '2028-02-28', '2028-02-29', '2028-03-01', '2028-03-02', '2028-03-03', '2028-03-04']);
      expect([for (final x in _prox(DateTime(2026, 12, 30, 8))) _dia(x.quando)],
          ['2026-12-30', '2026-12-31', '2027-01-01', '2027-01-02', '2027-01-03', '2027-01-04', '2027-01-05']);
      expect([for (final x in _prox(DateTime(2027, 2, 27, 8))) _dia(x.quando)].take(3), ['2027-02-27', '2027-02-28', '2027-03-01']);
    });

    test('horário da madrugada (00:00) com a pessoa acordada às 23:30: o de hoje já passou, o de amanhã vale', () {
      final l = _prox(DateTime(2026, 10, 13, 23, 30), config: const ConfigLembrete(ligado: true, hora: 0, minuto: 0));
      expect(l.length, 6, reason: 'o 00:00 de hoje já passou: sobram os 6 dias seguintes');
      expect(l.first.quando, DateTime(2026, 10, 14, 0, 0));
    });

    test('o horário escolhido vale (07:30)', () {
      final l = _prox(DateTime(2026, 10, 13, 6), config: const ConfigLembrete(ligado: true, hora: 7, minuto: 30));
      expect(l.first.quando, DateTime(2026, 10, 13, 7, 30));
    });

    test('dias personalizado', () {
      expect(_prox(DateTime(2026, 10, 13, 10), dias: 3).length, 3);
      expect(_prox(DateTime(2026, 10, 13, 10), dias: 0), isEmpty);
    });

    test('todo lembrete é no FUTURO, em ordem e sem ids repetidos', () {
      for (final h in [0, 6, 12, 19, 20, 21, 23]) {
        final agora = DateTime(2026, 10, 13, h, 17);
        for (final bateu in [true, false]) {
          final l = _prox(agora, bateu: bateu);
          expect(l.every((x) => x.quando.isAfter(agora)), isTrue, reason: 'hora $h bateu $bateu');
          expect([...l.map((x) => x.quando)]..sort(), l.map((x) => x.quando).toList());
          expect(l.map((x) => x.id).toSet().length, l.length);
          expect(l.every((x) => x.id >= idBaseLembrete && x.id < idBaseLembrete + diasDeLembrete), isTrue);
        }
      }
    });
  });

  group('os textos do lembrete', () {
    test('acolhedores: sem número de dias, sem culpa e sem ameaça', () {
      expect(textosDoLembrete.length, greaterThanOrEqualTo(3));
      for (final (titulo, corpo) in textosDoLembrete) {
        final t = '$titulo $corpo'.toLowerCase();
        expect(titulo, isNotEmpty);
        expect(corpo, isNotEmpty);
        expect(RegExp(r'\d').hasMatch(t), isFalse, reason: 'sem número (a sequência de amanhã não se sabe hoje): $t');
        for (final ruim in ['perd', 'falh', 'culpa', 'vergonha', 'abandon', 'esquec', 'desistiu', 'última chance', 'urgente']) {
          expect(t.contains(ruim), isFalse, reason: '"$ruim" em: $t');
        }
      }
    });

    test('o mesmo dia sempre dá o mesmo texto; dias seguidos giram', () {
      final d = DateTime(2026, 10, 13, 20);
      expect(textoDoLembrete(d), textoDoLembrete(DateTime(2026, 10, 13, 7)));
      expect(textoDoLembrete(d), isNot(textoDoLembrete(DateTime(2026, 10, 14, 20))));
      final usados = {for (var i = 0; i < textosDoLembrete.length; i++) textoDoLembrete(DateTime(2026, 10, 13 + i))};
      expect(usados.length, textosDoLembrete.length);
    });

    test('cada lembrete agendado leva o texto do SEU dia', () {
      for (final x in _prox(DateTime(2026, 10, 13, 10))) {
        final (t, c) = textoDoLembrete(x.quando);
        expect((x.titulo, x.corpo), (t, c));
      }
    });
  });
}
