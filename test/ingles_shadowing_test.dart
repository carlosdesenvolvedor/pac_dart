import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/avaliacao_fala.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/shadowing.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';

const frase = 'Nice to meet you, Mike.'; // 5 palavras

AvaliacaoFala fala(String dito, {String f = frase}) => avaliarFala(f, [dito]);

final perfeita = fala('nice to meet you mike');
final quatroDeCinco = fala('nice to meet you'); // 80%
final tresDeCinco = fala('nice to meet'); // 60%
final quatroDeCincoOutra = fala('nice to meet mike'); // 80%, outra palavra faltando
final nada = fala('');

void main() {
  group('notaDoShadowing (D5)', () {
    final tabela = <String, (int, AvaliacaoFala?, bool, Rating)>{
      'perfeita na 1ª ⇒ Bom': (1, perfeita, false, Rating.good),
      'perfeita na 2ª ⇒ Difícil': (2, perfeita, false, Rating.hard),
      'perfeita na 3ª ⇒ Difícil': (3, perfeita, false, Rating.hard),
      '80% depois de 3 tentativas ⇒ Difícil': (3, quatroDeCinco, false, Rating.hard),
      '80% numa tentativa só ⇒ Difícil': (1, quatroDeCinco, false, Rating.hard),
      '60% ⇒ Errei': (3, tresDeCinco, false, Rating.again),
      'nenhuma palavra ⇒ Errei': (1, fala('banana banana'), false, Rating.again),
      'sem tentativa ⇒ Errei': (0, null, false, Rating.again),
      'desistiu sem tentar ⇒ Errei': (0, null, true, Rating.again),
      'desistiu depois de 80% ⇒ Errei (mostrou a frase)': (1, quatroDeCinco, true, Rating.again),
      'desistiu depois de perfeita (não acontece, mas não pode virar Bom) ⇒ Errei': (1, perfeita, true, Rating.again),
    };
    tabela.forEach((nome, c) {
      test(nome, () => expect(notaDoShadowing(tentativas: c.$1, melhor: c.$2, desistiu: c.$3), c.$4));
    });

    test('o limiar é 70% EXATO: 7 de 10 palavras ainda vale Difícil; 6 de 10 não', () {
      const f = 'one two three four five six seven eight nine ten';
      final sete = avaliarFala(f, ['one two three four five six seven']);
      final seis = avaliarFala(f, ['one two three four five six']);
      expect(sete.acertos / sete.palavras, limiarShadowing);
      expect(notaDoShadowing(tentativas: 3, melhor: sete), Rating.hard);
      expect(notaDoShadowing(tentativas: 3, melhor: seis), Rating.again);
    });

    test('NUNCA devolve Fácil, em nenhum caso', () {
      for (final t in [0, 1, 2, 3, 4]) {
        for (final m in [null, perfeita, quatroDeCinco, tresDeCinco, nada]) {
          for (final d in [true, false]) {
            expect(notaDoShadowing(tentativas: t, melhor: m, desistiu: d), isNot(Rating.easy));
          }
        }
      }
    });
  });

  group('SessaoShadowing', () {
    test('começa vazia: não encerrou, sem melhor, nota Errei', () {
      const s = SessaoShadowing();
      expect(s.encerrou, isFalse);
      expect(s.melhor, isNull);
      expect(s.notaSugerida(), Rating.again);
    });

    test('"não ouvi nada" NÃO é tentativa', () {
      final s = const SessaoShadowing().registrar(nada);
      expect(s.tentativas, isEmpty);
      expect(s.encerrou, isFalse);
    });

    test('perfeita encerra na hora', () {
      final s = const SessaoShadowing().registrar(perfeita);
      expect(s.encerrou, isTrue);
      expect(s.perfeita, isTrue);
      expect(s.notaSugerida(), Rating.good);
    });

    test('3 tentativas não perfeitas encerram; a 3ª é a última', () {
      var s = const SessaoShadowing();
      s = s.registrar(tresDeCinco);
      expect(s.encerrou, isFalse);
      s = s.registrar(tresDeCinco);
      expect(s.encerrou, isFalse);
      s = s.registrar(tresDeCinco);
      expect(s.encerrou, isTrue);
      expect(s.tentativas.length, maxTentativasShadowing);
      expect(maxTentativasShadowing, 3);
    });

    test('depois de encerrar nada entra', () {
      final s = const SessaoShadowing().registrar(perfeita);
      expect(s.registrar(tresDeCinco), same(s));
      var t = const SessaoShadowing();
      for (var i = 0; i < 3; i++) {
        t = t.registrar(tresDeCinco);
      }
      expect(t.registrar(perfeita).tentativas.length, 3);
    });

    test('a melhor é a de mais acertos; em empate, a primeira', () {
      var s = const SessaoShadowing().registrar(tresDeCinco).registrar(quatroDeCinco);
      expect(s.melhor, quatroDeCinco);
      s = const SessaoShadowing().registrar(quatroDeCinco).registrar(quatroDeCincoOutra);
      expect(s.melhor, same(s.tentativas.first));
      expect(s.melhor, quatroDeCinco);
    });

    test('a nota sai da MELHOR tentativa, não da última', () {
      final s = const SessaoShadowing().registrar(quatroDeCinco).registrar(tresDeCinco).registrar(fala('banana'));
      expect(s.notaSugerida(), Rating.hard);
    });

    test('perfeita na 2ª ⇒ Difícil (a 1ª errou)', () {
      final s = const SessaoShadowing().registrar(tresDeCinco).registrar(perfeita);
      expect(s.encerrou, isTrue);
      expect(s.notaSugerida(), Rating.hard);
    });

    test('"Mostrar a frase" ⇒ Errei, mesmo com boa tentativa', () {
      final s = const SessaoShadowing().registrar(quatroDeCinco);
      expect(s.notaSugerida(desistiu: true), Rating.again);
    });

    test('é imutável: registrar devolve outra sessão', () {
      const s = SessaoShadowing();
      final t = s.registrar(tresDeCinco);
      expect(s.tentativas, isEmpty);
      expect(t.tentativas.length, 1);
    });
  });

  group('integração com avaliarFala (a régua do dono)', () {
    test('contração dita por extenso, homófono e número valem', () {
      expect(fala('I am from Brazil', f: "I'm from Brazil.").perfeita, isTrue);
      expect(fala('I have to cats', f: 'I have two cats.').perfeita, isTrue);
      expect(fala('I have seven cats', f: 'I have 7 cats.').perfeita, isTrue);
    });

    test('palavra trocada: aponta a errada', () {
      expect(fala('nice to meet you mark').erradas, {4});
    });

    test('alt: do autor vale por inteiro', () {
      final a = avaliarFala("I'm Ana.", ['I am Anna'], alternativas: ['I am Ana.']);
      expect(a.perfeita, isTrue);
    });
  });

  group('comparacaoDoShadowing: a melhor tentativa no formato do cartão', () {
    test('sem tentativa ⇒ null', () {
      expect(comparacaoDoShadowing(frase, const SessaoShadowing(), sugerida: Rating.again), isNull);
    });

    test('a frase volta inteira, com as palavras certas/erradas marcadas e a pontuação sem marca', () {
      final s = const SessaoShadowing().registrar(fala('nice to meat you'));
      final c = comparacaoDoShadowing(frase, s, sugerida: Rating.hard)!;
      expect(c.esperada.map((x) => x.texto).join(), frase);
      expect([for (final x in c.esperada) if (x.acerto != null) '${x.texto}:${x.acerto}'],
          ['Nice:true', 'to:true', 'meet:true', 'you:true', 'Mike:false']);
      expect(c.esperada.where((x) => x.acerto == null).map((x) => x.texto).join(), '   , .');
      expect(c.sugerida, Rating.hard);
      expect(c.exata, isFalse);
      expect(c.acertadas, 4);
      expect(c.totalEsperadas, 5);
    });

    test('o que foi ouvido vem com as palavras que não são da frase marcadas', () {
      final s = const SessaoShadowing().registrar(fala('well nice to meet you mike'));
      final c = comparacaoDoShadowing(frase, s, sugerida: Rating.good)!;
      expect([for (final x in c.digitada) if (x.acerto != null) '${x.texto}:${x.acerto}'],
          ['well:false', 'nice:true', 'to:true', 'meet:true', 'you:true', 'mike:true']);
      expect(c.exata, isTrue);
    });

    test('cobertura e precisão', () {
      final s = const SessaoShadowing().registrar(fala('nice to meet banana'));
      final c = comparacaoDoShadowing(frase, s, sugerida: Rating.again)!;
      expect(c.cobertura, closeTo(3 / 5, 1e-9));
      expect(c.precisao, closeTo(3 / 4, 1e-9));
    });
  });

  group('SentidoCartao.shadowing', () {
    test('existe, tem id próprio e o pref lê de volta; id estranho volta nulo', () {
      expect(SentidoCartao.shadowing.id, 'shadowing');
      expect(SentidoCartao.porId('shadowing'), SentidoCartao.shadowing);
      expect(SentidoCartao.shadowing.rotulo, contains('Ouvir e repetir'));
      expect(SentidoCartao.porId('xyz'), isNull);
      expect({for (final s in SentidoCartao.values) s.id}.length, SentidoCartao.values.length);
    });
  });
}
