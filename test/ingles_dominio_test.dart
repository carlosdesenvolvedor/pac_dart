import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/alternativas.dart';
import 'package:pac_dart/features/ingles/domain/avaliacao.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';

/// Roda a lição inteira respondendo [resposta] em cada digitação de memória.
List<PassoFila> simular(FilaLicao fila, ResultadoRevisao Function(PassoFila p) resposta) {
  final passos = <PassoFila>[];
  while (!fila.terminou && passos.length < 500) {
    final p = fila.atual!;
    passos.add(p);
    fila.registrar(p.modo.deMemoria ? resposta(p) : null);
  }
  return passos;
}

void main() {
  group('FilaLicao — escada intercalada', () {
    test('com tudo certo, cada frase sobe D1→D5 (5 digitações) e o começo bate com a simulação do dossiê', () {
      final fila = FilaLicao(10);
      final passos = simular(fila, (_) => ResultadoRevisao.acertou);
      expect(passos.length, 50);
      expect(passos.take(18).join(' '), 'A1 B1 C1 D1 A2 B2 C2 D2 E1 F1 A3 B3 C3 E2 D3 F2 G1 H1');
      for (var f = 0; f < 10; f++) {
        expect(passos.where((p) => p.frase == f).map((p) => p.degrau).toList(), Degrau.values);
      }
      expect(fila.nota, 10);
    });

    test('a mesma frase nunca vem duas vezes seguidas (fora a cópia de correção)', () {
      for (final n in [6, 8, 10, 12]) {
        final passos = simular(FilaLicao(n, semente: n), (_) => ResultadoRevisao.acertou);
        for (var i = 1; i < passos.length; i++) {
          if (passos[i].correcao) continue;
          expect(passos[i].frase == passos[i - 1].frase, isFalse,
              reason: 'n=$n passo $i: ${passos.join(' ')}');
        }
      }
    });

    test('respeita os lags mínimos: D2 depois de 3 outras, D3 de 5, D4 de 7 (no fim da lição eles encolhem)', () {
      final passos = simular(FilaLicao(10), (_) => ResultadoRevisao.acertou);
      int pos(int f, Degrau d) => passos.indexWhere((p) => p.frase == f && p.degrau == d);
      for (var f = 0; f < 6; f++) {
        expect(pos(f, Degrau.iniciais) - pos(f, Degrau.conhecer), greaterThanOrEqualTo(4));
        expect(pos(f, Degrau.esqueleto) - pos(f, Degrau.iniciais), greaterThanOrEqualTo(6));
        expect(pos(f, Degrau.memoria) - pos(f, Degrau.esqueleto), greaterThanOrEqualTo(8));
      }
    });

    test('erro de memória → cópia de correção na hora e a frase desce um degrau', () {
      final fila = FilaLicao(6);
      var errouUmaVez = false;
      final passos = simular(fila, (p) {
        if (p.frase == 0 && p.degrau == Degrau.memoria && !errouUmaVez) {
          errouUmaVez = true;
          return ResultadoRevisao.errou;
        }
        return ResultadoRevisao.acertou;
      });
      final i = passos.indexWhere((p) => p.frase == 0 && p.degrau == Degrau.memoria);
      expect(passos[i + 1].correcao, isTrue);
      expect(passos[i + 1].frase, 0);
      expect(passos[i + 1].modo, ModoFrase.ver);
      // depois volta no esqueleto e sobe de novo até a prova
      final depois = passos.skip(i + 2).where((p) => p.frase == 0).map((p) => p.degrau).toList();
      expect(depois, [Degrau.esqueleto, Degrau.memoria, Degrau.prova]);
    });

    test('teto de digitações por frase no dia: errando sempre, a lição termina', () {
      final fila = FilaLicao(4);
      final passos = simular(fila, (_) => ResultadoRevisao.errou);
      expect(fila.terminou, isTrue);
      for (var f = 0; f < 4; f++) {
        expect(passos.where((p) => p.frase == f).length, lessThanOrEqualTo(FilaLicao.teto));
      }
      expect(fila.dificeis.length, 4);
      expect(fila.nota, 0);
    });

    test('nota da lição sai da 1ª prova de cada frase', () {
      final fila = FilaLicao(4);
      simular(fila, (p) => p.degrau == Degrau.prova && p.frase < 2 ? ResultadoRevisao.hesitou : ResultadoRevisao.acertou);
      expect(fila.nota, 8); // 2 limpas + 2 com tropeço = 3/4
    });
  });

  group('máscara da frase', () {
    String desenha(String f, ModoFrase m) {
      final ms = mascaraDaFrase(f, m);
      return [
        for (var i = 0; i < f.length; i++)
          switch (ms[i]) { Mostra.letra => f[i], Mostra.tracinho => '_', Mostra.nada => ' ' }
      ].join();
    }

    test('iniciais, esqueleto e memória', () {
      const f = "I'd like a glass of water, please.";
      expect(desenha(f, ModoFrase.pistas), "I'_ l___ a g____ o_ w____, p_____.");
      expect(desenha(f, ModoFrase.esqueleto), "_'_ ____ _ _____ __ _____, ______.");
      expect(desenha(f, ModoFrase.memoria).trim(), '');
      expect(desenha(f, ModoFrase.ver), f);
    });
  });

  group('avaliação por palavra', () {
    const f = 'I want to drink some water.';

    test('limpa = acertou; 1 tecla errada numa palavra longa = tropeço', () {
      expect(avaliarDigitacao(f, errosPorPosicao: {}).resultado, ResultadoRevisao.acertou);
      // "drink" começa no índice 10
      final d = avaliarDigitacao(f, errosPorPosicao: {11: 1});
      expect(d.palavrasOk, 6);
      expect(d.resultado, ResultadoRevisao.acertou);
      final d2 = avaliarDigitacao(f, errosPorPosicao: {11: 2});
      expect(d2.palavrasErradas, {3});
      expect(d2.resultado, ResultadoRevisao.hesitou);
    });

    test('palavra curta não tolera erro; muitas palavras erradas = errou', () {
      expect(avaliarDigitacao(f, errosPorPosicao: {7: 1}).resultado, ResultadoRevisao.hesitou); // "to"
      final d = avaliarDigitacao(f, errosPorPosicao: {0: 1, 2: 2, 7: 1});
      expect(d.resultado, ResultadoRevisao.errou);
    });

    test('dica rebaixa; desistir é errou; erro em espaço não conta', () {
      expect(avaliarDigitacao(f, errosPorPosicao: {}, reveladas: {10}).resultado, ResultadoRevisao.hesitou);
      expect(avaliarDigitacao(f, errosPorPosicao: {}, desistiu: true).resultado, ResultadoRevisao.errou);
      expect(avaliarDigitacao(f, errosPorPosicao: {1: 3}).resultado, ResultadoRevisao.acertou);
    });
  });

  group('revisão espaçada (Leitner)', () {
    test('acertou sobe de caixa, hesitou fica, errou desce duas', () {
      const c = CartaoRevisao(caixa: 3, proximoDia: 100);
      expect(Revisao.avaliar(c, ResultadoRevisao.acertou, 100), CartaoRevisao(caixa: 4, proximoDia: 100 + Revisao.intervalos[3]));
      expect(Revisao.avaliar(c, ResultadoRevisao.hesitou, 100).caixa, 3);
      final caiu = Revisao.avaliar(c, ResultadoRevisao.errou, 100);
      expect(caiu.caixa, 1);
      expect(caiu.lapsos, 1);
      expect(caiu.proximoDia, 101);
    });

    test('frase nova volta amanhã; devidas vêm das mais atrasadas', () {
      expect(Revisao.novo(50).proximoDia, 51);
      final cartoes = {
        'a': const CartaoRevisao(caixa: 2, proximoDia: 10),
        'b': const CartaoRevisao(caixa: 1, proximoDia: 8),
        'c': const CartaoRevisao(caixa: 1, proximoDia: 12),
      };
      expect(Revisao.devidas(cartoes, 10), ['b', 'a']);
    });

    test('cartão ida e volta pela string compacta', () {
      const c = CartaoRevisao(caixa: 5, proximoDia: 20123, lapsos: 2);
      expect(CartaoRevisao.decodificar(c.codificar()), c);
      expect(CartaoRevisao.decodificar('lixo'), isNull);
    });

    test('chave da frase é estável e distingue frases', () {
      expect(Revisao.chave("I'm fine."), Revisao.chave("I'm fine."));
      expect(Revisao.chave("I'm fine."), isNot(Revisao.chave("I'm fine!")));
    });
  });

  group('alternativas automáticas (contrações)', () {
    test('contraída ↔ plena, nos dois sentidos e combinadas', () {
      expect(alternativasDe("I'm fine."), ['I am fine.']);
      expect(alternativasDe("Don't worry, I'll call you."),
          containsAll(["Do not worry, I'll call you.", "Don't worry, I will call you.", 'Do not worry, I will call you.']));
      expect(alternativasDe('I cannot go.'), ["I can't go."]);
      expect(alternativasDe('We are late.'), ["We're late."]);
    });

    test("ambíguas ('s, 'd) e have de posse não são automáticas; declaradas vêm primeiro", () {
      expect(alternativasDe("It's late."), isEmpty);
      expect(alternativasDe("I'd like a coffee."), isEmpty);
      expect(alternativasDe('I have a car.'), isEmpty);
      expect(alternativasDe("I'd like a coffee.", declaradas: ['I would like a coffee.']), ['I would like a coffee.']);
    });
  });
}

