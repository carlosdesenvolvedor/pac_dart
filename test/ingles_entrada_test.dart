import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/entrada_resposta.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EntradaResposta', () {
    test('o padrão é digitar (o diferencial do app)', () {
      expect(EntradaResposta.padrao, EntradaResposta.digitar);
    });

    test('ids e rótulos únicos e estáveis (ficam guardados no aparelho)', () {
      expect(EntradaResposta.values.map((e) => e.id), ['digitar', 'falar', 'montar']);
      expect(EntradaResposta.values.map((e) => e.rotulo), ['Digitar', 'Falar', 'Montar']);
      expect({for (final e in EntradaResposta.values) e.id}.length, 3);
      expect(EntradaResposta.values.every((e) => e.emoji.isNotEmpty), isTrue);
    });

    test('porId: ida e volta; desconhecido, vazio, nulo e de outro tipo ⇒ null', () {
      for (final e in EntradaResposta.values) {
        expect(EntradaResposta.porId(e.id), e);
      }
      for (final ruim in [null, '', 'xyz', 'Digitar', ' digitar', 3, true, <String>['montar'], {'id': 'montar'}]) {
        expect(EntradaResposta.porId(ruim), isNull, reason: '$ruim');
      }
    });
  });

  group('notaDaEntrada (D2: montar certo na PROVA conta meio ponto)', () {
    // (entrada, degrau, nota que veio) → nota que vale
    final tabela = <(EntradaResposta, Degrau, ResultadoRevisao), ResultadoRevisao>{
      // montar na prova: acertou vira tropeçou; tropeçou e errou ficam
      (EntradaResposta.montar, Degrau.prova, ResultadoRevisao.acertou): ResultadoRevisao.hesitou,
      (EntradaResposta.montar, Degrau.prova, ResultadoRevisao.hesitou): ResultadoRevisao.hesitou,
      (EntradaResposta.montar, Degrau.prova, ResultadoRevisao.errou): ResultadoRevisao.errou,
      // montar nos outros degraus: sem mudança
      (EntradaResposta.montar, Degrau.conhecer, ResultadoRevisao.acertou): ResultadoRevisao.acertou,
      (EntradaResposta.montar, Degrau.iniciais, ResultadoRevisao.acertou): ResultadoRevisao.acertou,
      (EntradaResposta.montar, Degrau.esqueleto, ResultadoRevisao.acertou): ResultadoRevisao.acertou,
      (EntradaResposta.montar, Degrau.memoria, ResultadoRevisao.acertou): ResultadoRevisao.acertou,
      (EntradaResposta.montar, Degrau.memoria, ResultadoRevisao.errou): ResultadoRevisao.errou,
      // digitar e falar valem inteiro, até na prova
      (EntradaResposta.digitar, Degrau.prova, ResultadoRevisao.acertou): ResultadoRevisao.acertou,
      (EntradaResposta.falar, Degrau.prova, ResultadoRevisao.acertou): ResultadoRevisao.acertou,
      (EntradaResposta.digitar, Degrau.prova, ResultadoRevisao.errou): ResultadoRevisao.errou,
      (EntradaResposta.falar, Degrau.memoria, ResultadoRevisao.hesitou): ResultadoRevisao.hesitou,
    };
    tabela.forEach((caso, esperado) {
      test('${caso.$1.id} · ${caso.$2.name} · ${caso.$3.name} ⇒ ${esperado.name}', () {
        expect(notaDaEntrada(caso.$3, entrada: caso.$1, degrau: caso.$2), esperado);
      });
    });

    test('NUNCA melhora uma nota, em nenhuma combinação', () {
      int pontos(ResultadoRevisao r) => switch (r) {
            ResultadoRevisao.errou => 0,
            ResultadoRevisao.hesitou => 1,
            ResultadoRevisao.acertou => 2,
          };
      for (final e in EntradaResposta.values) {
        for (final d in Degrau.values) {
          for (final r in ResultadoRevisao.values) {
            expect(pontos(notaDaEntrada(r, entrada: e, degrau: d)), lessThanOrEqualTo(pontos(r)), reason: '$e $d $r');
          }
        }
      }
    });
  });

  group('PrefsEntrada', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('sem nada guardado: digitar', () async {
      expect(await PrefsEntrada.carregar(), EntradaResposta.digitar);
    });

    test('ida e volta', () async {
      for (final e in EntradaResposta.values) {
        await PrefsEntrada.salvar(e);
        expect(await PrefsEntrada.carregar(), e);
      }
      final p = await SharedPreferences.getInstance();
      expect(p.getString('en_entrada'), 'montar');
    });

    test('valor estragado ou de outro tipo cai no padrão, sem lançar', () async {
      for (final ruim in <Object>['xyz', '', 7, true, 1.5, ['montar']]) {
        SharedPreferences.setMockInitialValues({'en_entrada': ruim});
        expect(await PrefsEntrada.carregar(), EntradaResposta.digitar, reason: '$ruim');
      }
    });
  });
}
