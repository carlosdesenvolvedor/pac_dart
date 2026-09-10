import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/progresso_turismo.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/minimapa.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dart Turismo — campeonato', () {
    test('10 pistas em dificuldade crescente, com números humanos', () {
      expect(pistasGt, hasLength(10));
      for (var i = 0; i < pistasGt.length; i++) {
        final p = pistasGt[i];
        expect(p.numero, i + 1);
        expect(p.tema, inInclusiveRange(1, 6));
        expect(p.tempoLimite, greaterThan(30));
        expect(p.tempoOuro, lessThan(p.tempoPrata));
        expect(p.tempoPrata, lessThan(p.tempoLimite));
        expect(p.vocabulario, isNotEmpty);
        // sempre dá pelo menos 2,8 s por portal na velocidade máxima
        expect(p.intervaloPortais / p.velMax, closeTo(2.8, 1e-9));
        // o ouro é alcançável: exige no máximo ~90% da velocidade máxima
        expect(p.distancia / p.tempoOuro, lessThanOrEqualTo(p.velMax * .92), reason: p.nome);
        if (i > 0) {
          expect(p.distancia, greaterThanOrEqualTo(pistasGt[i - 1].distancia));
          expect(p.velAlvo, greaterThan(pistasGt[i - 1].velAlvo));
          expect(p.curvaMax, greaterThanOrEqualTo(pistasGt[i - 1].curvaMax));
        }
      }
      expect(pistasGt.last.duasSaidas, isTrue);
      expect(pistasGt.first.duasSaidas, isFalse);
    });

    test('medalha por tempo: ouro ≤ 72%, prata ≤ 86%, bronze ≤ limite', () {
      final p = pistasGt.first;
      expect(p.medalha(p.tempoOuro), 3);
      expect(p.medalha(p.tempoPrata), 2);
      expect(p.medalha(p.tempoLimite), 1);
      expect(p.medalha(p.tempoLimite + 1), 0);
    });
  });

  group('TurismoEngine', () {
    test('pista gerada: largada reta, curvas no limite, portais sempre exigem trocar de faixa', () {
      final pista = pistasGt[9];
      final e = TurismoEngine(pista: pista, rnd: Random(1));
      for (var i = 0; i < 10; i++) {
        expect(e.segmentos[i].curva, 0);
      }
      expect(e.segmentos.every((s) => s.curva.abs() <= pista.curvaMax + 1e-9), isTrue);
      expect(e.segmentos.any((s) => s.curva.abs() > 1), isTrue, reason: 'pista sem curva');
      expect(e.portais.length, greaterThan(10));
      var faixaAnterior = TurismoEngine.faixaInicial;
      for (var i = 0; i < e.portais.length; i++) {
        final p = e.portais[i];
        expect(p.faixas, hasLength(2)); // duas saídas na pista 10
        expect(p.palavras, hasLength(2));
        expect(p.faixas.contains(faixaAnterior), isFalse, reason: 'portal $i não exige troca');
        expect(p.faixas.toSet(), hasLength(2));
        if (i > 0) expect(p.z - e.portais[i - 1].z, closeTo(pista.intervaloPortais, 1e-6));
        for (final w in p.palavras) {
          expect(pista.vocabulario, contains(w));
        }
        faixaAnterior = p.faixas.first;
      }
      expect(e.portais.last.z, lessThan(pista.distancia - 40));
    });

    test('mesma semente, mesma pista (os testes de tela dependem disso)', () {
      final a = TurismoEngine(pista: pistasGt[2], rnd: Random(7));
      final b = TurismoEngine(pista: pistasGt[2], rnd: Random(7));
      expect([for (final p in a.portais) p.palavras], [for (final p in b.portais) p.palavras]);
      expect([for (final s in a.segmentos) s.curva], [for (final s in b.segmentos) s.curva]);
    });

    test('digitar acelera; parar de digitar vai parando até ficar imóvel', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(2));
      e.tick(1);
      expect(e.posicao, 0); // parado: ninguém digitou
      final w = e.portalAtual!.palavras.first;
      expect(e.teclar(w[0]), TeclaGt.avancou);
      expect(e.velocidade, greaterThan(0));
      final v1 = e.velocidade;
      e.tick(.5);
      expect(e.posicao, greaterThan(0));
      expect(e.velocidade, lessThan(v1)); // o arrasto já freia
      final limite = pistasGt[0].tempoLimite.ceil() + 2;
      for (var i = 0; i < limite; i++) {
        e.tick(1);
      }
      expect(e.velocidade, 0);
      expect(e.tempoEsgotado, isTrue); // parado até o limite da pista 1 = tempo estourado
    });

    test('completar a palavra troca de faixa, pontua, dá boost — e o portal certo passa limpo', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4));
      final p = e.portalAtual!;
      final w = p.palavras.first;
      TeclaGt? ultimo;
      for (final ch in w.split('')) {
        ultimo = e.teclar(ch);
      }
      expect(ultimo, TeclaGt.completou);
      expect(e.faixa, p.faixas.first);
      expect(e.palavras, 1);
      expect(e.pontos, 3 + w.length);
      expect(e.boost, 1);
      expect(p.livre, isTrue);
      // atravessa o portal na velocidade máxima
      while (e.posicao < p.z + 1) {
        e.velocidade = e.velMax;
        e.tick(.1);
      }
      expect(p.passado, isTrue);
      expect(p.batido, isFalse);
      expect(e.colisoes, 0);
      expect(e.portalAtual, e.portais[1]);
    });

    test('digitada a palavra do portal, vem COMBUSTÍVEL: sempre há o que digitar', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4));
      final p1 = e.portais[0], p2 = e.portais[1];
      expect(e.palavraGas, isNull);
      for (final ch in p1.palavras.first.split('')) {
        e.teclar(ch);
      }
      expect(p1.livre, isTrue);
      expect(e.portalParaDigitar, isNull);
      final gas = e.palavraGas;
      expect(gas, isNotNull);
      final vAntes = e.velocidade;
      for (final ch in gas!.split('')) {
        expect(e.teclar(ch), isNot(TeclaGt.errou));
      }
      expect(e.velocidade, greaterThan(vAntes));
      expect(e.palavras, 2);
      expect(e.faixa, p1.faixas.first, reason: 'combustível não mexe na faixa');
      expect(e.palavraGas, isNotNull); // já vem outra
      expect(e.palavraGas, isNot(gas));
      // começa uma de combustível e cruza o portal 1: a pela metade continua
      e.teclar(e.palavraGas![0]);
      while (!p1.passado) {
        e.velocidade = e.velMax;
        e.tick(.1);
      }
      expect(p1.batido, isFalse);
      expect(e.portalParaDigitar, isNull, reason: 'combustível pela metade tem prioridade');
      final resto = e.palavraGas!.substring(1);
      for (final ch in resto.split('')) {
        expect(e.teclar(ch), isNot(TeclaGt.errou));
      }
      // acabou o combustível: o portal 2 assume a vez e não nasce outro gás
      expect(e.portalParaDigitar, p2);
      expect(e.palavraGas, isNull);
      expect(e.palavras, 3);
    });

    test('tráfego arranca perto do portal e anda na faixa dele; encostar é batida (30%, combo zera)', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4));
      final p = e.portalAtual!;
      expect(p.carros, hasLength(2)); // duas faixas bloqueadas
      expect(p.carros.every((c) => !p.faixas.contains(c.faixa)), isTrue);
      expect(e.trafegoAtivo, isEmpty);
      // sem digitar: fica na faixa do meio, que está bloqueada
      var antes = 0.0;
      var guarda = 0;
      while (e.colisoes == 0 && guarda++ < 400) {
        e.velocidade = e.velMax;
        antes = e.velocidade;
        e.tick(.1);
      }
      expect(e.colisoes, 1);
      final atingido = p.carros.firstWhere((c) => c.batido);
      expect(atingido.faixa, TurismoEngine.faixaInicial);
      expect(atingido.ativo, isTrue);
      expect(atingido.z, greaterThan(p.z + 2.6), reason: 'o carro arrancou antes de ser alcançado');
      expect(e.posicao, lessThan(p.z + 25), reason: 'a batida acontece logo depois do pórtico');
      expect(p.batido, isTrue);
      expect(e.velocidade, closeTo(antes * .3, antes * .05));
      expect(e.impacto, 1);
      expect(e.combo, 0);
      expect(e.portalAtual, e.portais[1]);
      // um carro só bate uma vez
      for (var i = 0; i < 20; i++) {
        e.velocidade = e.velMax;
        e.tick(.1);
      }
      expect(e.colisoes, 1);
    });

    test('jogador devagar na faixa errada também bate: o tráfego não foge (45% da sua velocidade)', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4));
      final p = e.portalAtual!;
      var guarda = 0;
      while (e.colisoes == 0 && guarda++ < 2000) {
        e.velocidade = 9; // bem abaixo dos 32% da máxima do tráfego
        e.tick(.05);
      }
      expect(e.colisoes, 1);
      final atingido = p.carros.firstWhere((c) => c.batido);
      expect(atingido.vel, lessThanOrEqualTo(9 * TurismoEngine.fracaoDoJogador + 1e-9));
      expect(e.posicao, lessThan(p.z + 30));
    });

    test('é a faixa VISUAL que decide a batida — trocar de faixa em cima da hora não salva', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4));
      final p = e.portalAtual!;
      final bloqueada = p.carros.first;
      // alvo já é a faixa livre, mas o carro ainda está fisicamente na bloqueada
      e.faixa = p.faixas.first;
      e.xAtual = (bloqueada.faixa - 1) * TurismoEngine.larguraFaixa;
      expect(e.faixaVisual, bloqueada.faixa);
      e.posicao = bloqueada.z - 1;
      e.velocidade = 5;
      e.tick(.01);
      expect(e.colisoes, 1);
      expect(bloqueada.batido, isTrue);
    });

    test('fichas de programação na faixa livre rendem moedas; em outra faixa, não', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4));
      final p = e.portalAtual!;
      expect(p.fichas, hasLength(3));
      expect(p.fichas.every((f) => f.faixa == p.faixas.first && fichasDart.contains(f.texto)), isTrue);
      for (final ch in p.palavras.first.split('')) {
        e.teclar(ch);
      }
      while (e.posicao < p.fichas.last.z + 5) {
        e.velocidade = e.velMax;
        e.tick(.05);
      }
      expect(e.fichasPegas, 3);
      expect(e.moedas, 3 * TurismoEngine.moedasPorFicha);
      expect(e.colisoes, 0);
      // outra corrida: na faixa errada... bate antes, e as fichas ficam lá
      final f = TurismoEngine(pista: pistasGt[0], rnd: Random(4));
      final q = f.portalAtual!;
      while (f.posicao < q.fichas.last.z + 5) {
        f.velocidade = f.velMax;
        f.tick(.05);
      }
      expect(f.fichasPegas, 0);
      expect(f.moedas, 0);
    });

    test('tecla errada derrapa 10% e zera o combo; letra que não começa palavra também é erro', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(5));
      e.velocidade = 10;
      final w = e.portalAtual!.palavras.first;
      final errada = w[0] == 'z' ? 'q' : 'z';
      expect(e.teclar(errada), TeclaGt.errou);
      expect(e.velocidade, closeTo(9, 1e-9));
      expect(e.erros, 1);
      e.teclar(w[0]);
      final errada2 = w.length > 1 && w[1] == 'z' ? 'q' : 'z';
      expect(e.teclar(errada2), TeclaGt.errou);
      expect(e.digitadas, 1); // a mira continua na palavra
    });

    test('chegar rápido dá ouro e bônus; estourar o tempo encerra sem medalha', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
      while (e.correndo) {
        final p = e.portalAtual;
        if (p != null && !p.livre) {
          for (final ch in p.palavras.first.split('')) {
            e.teclar(ch);
          }
        }
        e.velocidade = e.velMax;
        e.tick(.1);
      }
      expect(e.terminou, isTrue);
      expect(e.colisoes, 0);
      expect(e.medalha, 3);
      expect(e.pontosFinais, e.pontos + 200);
      expect(e.palavras, e.portais.length);
      expect(e.fichasPegas, e.portais.length * 3, reason: 'na faixa certa, pega todas as fichas');
      expect(e.moedas, e.fichasPegas * TurismoEngine.moedasPorFicha);
      expect(e.teclar('a'), TeclaGt.nada);

      final f = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
      for (var t = 0; t < pistasGt[0].tempoLimite.ceil() + 2; t++) {
        f.tick(1);
      }
      expect(f.tempoEsgotado, isTrue);
      expect(f.terminou, isFalse);
      expect(f.medalha, 0);
      expect(f.pontosFinais, f.pontos);
      expect(f.tempoRestante, 0);
    });

    test('duas saídas: a primeira letra escolhe a palavra (e a faixa)', () {
      final e = TurismoEngine(pista: pistasGt[6], rnd: Random(11));
      // acha um portal cujas palavras começam com letras diferentes
      final p = e.portais.firstWhere((p) => p.palavras[0][0] != p.palavras[1][0]);
      while (e.portalAtual != p) {
        e.portalAtual!.passado = true;
      }
      for (final ch in p.palavras[1].split('')) {
        e.teclar(ch);
      }
      expect(p.digitado, 1);
      expect(e.faixa, p.faixas[1]);
    });

    test('combo: 5 palavras seguidas valem x2, 10 valem x3', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(6));
      var pontosAntes = 0;
      for (var n = 1; n <= 10; n++) {
        final p = e.portalAtual!;
        final w = p.palavras.first;
        pontosAntes = e.pontos;
        for (final ch in w.split('')) {
          e.teclar(ch);
        }
        final mult = n >= 10 ? 3 : (n >= 5 ? 2 : 1);
        expect(e.pontos - pontosAntes, (3 + w.length) * mult, reason: 'palavra $n');
        expect(e.multiplicador, mult);
        while (!p.passado) {
          e.velocidade = e.velMax;
          e.tick(.1);
        }
      }
      expect(e.melhorCombo, 10);
      expect(e.colisoes, 0);
    });
  });

  group('TurismoEngine — modo SETAS', () {
    test('acelera com o pedal, freia, e nada de digitar', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4), modo: ModoControle.setas);
      expect(e.portalParaDigitar, isNull);
      expect(e.teclar('a'), TeclaGt.nada);
      e.pedais(.5, gas: true);
      expect(e.velocidade, greaterThan(0));
      final v = e.velocidade;
      e.pedais(.5, freio: true);
      expect(e.velocidade, lessThan(v));
      // pé embaixo por 4 s, sempre desviando pra faixa livre do portal
      for (var i = 0; i < 40; i++) {
        final p = e.portalAtual;
        if (p != null && !p.faixas.contains(e.faixa)) {
          // olha o retrovisor: só troca se a faixa alvo está sem tráfego perto
          final alvo = p.faixas.first;
          final perto = e.trafegoAtivo.any((c) => c.faixa == alvo && (c.z - e.posicao).abs() < 12);
          if (!perto) e.virar(alvo - e.faixa);
        }
        e.pedais(.1, gas: true);
        e.tick(.1);
      }
      expect(e.colisoes, 0);
      expect(e.velocidade, greaterThan(e.velMax * .7));
    });

    test('setas trocam de faixa na hora; passar limpo pelo portal pontua e sobe o combo', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4), modo: ModoControle.setas);
      final p = e.portalAtual!;
      final livre = p.faixas.first;
      e.virar(livre - e.faixa);
      expect(e.faixa, livre);
      while (!p.passado) {
        e.pedais(.05, gas: true);
        e.velocidade = e.velMax;
        e.tick(.05);
      }
      expect(e.colisoes, 0);
      expect(e.portaisLimpos, 1);
      expect(e.combo, 1);
      expect(e.pontos, greaterThanOrEqualTo(10));
      // limites: não sai da pista
      e.virar(-5);
      expect(e.faixa, 0);
      e.virar(9);
      expect(e.faixa, 2);
    });

    test('na faixa errada, o tráfego bate igual ao modo digitação', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(4), modo: ModoControle.setas);
      var guarda = 0;
      while (e.colisoes == 0 && guarda++ < 600) {
        e.velocidade = e.velMax;
        e.tick(.1);
      }
      expect(e.colisoes, 1);
      expect(e.portaisLimpos, 0);
    });
  });

  group('Minimapa — traçado', () {
    test('reta vai pro norte; curva pra direita dobra pra +x; um ponto por segmento + 1', () {
      final reta = tracadoDaPista([0, 0, 0], comprimento: 8);
      expect(reta.length, 4);
      expect(reta.last.dx, closeTo(0, 1e-9));
      expect(reta.last.dy, closeTo(24, 1e-9));
      final direita = tracadoDaPista(List.filled(40, 6.0), comprimento: 8);
      expect(direita[10].dx, greaterThan(0));
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
      final t = tracadoDaPista([for (final s in e.segmentos) s.curva]);
      expect(t.length, e.segmentos.length + 1);
    });
  });

  group('VoltaFantasma e estatísticas', () {
    test('o motor grava a volta a cada 0,25 s e o fantasma responde posição/tempo', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
      while (e.correndo) {
        final p = e.portalAtual;
        if (p != null && !p.livre) {
          for (final ch in p.palavras.first.split('')) {
            e.teclar(ch);
          }
        }
        e.velocidade = e.velMax;
        e.tick(.05);
      }
      expect(e.terminou, isTrue);
      final v = VoltaFantasma(e.tempoFinal!, e.gravacao);
      expect(v.n, greaterThan(e.tempoFinal! / VoltaFantasma.passo - 2));
      expect(v.posicaoEm(0), 0);
      expect(v.posicaoEm(1e9), closeTo(pistasGt[0].distancia, 3)); // o último tick passa da linha
      final meio = v.posicaoEm(e.tempoFinal! / 2);
      expect(v.tempoEm(meio), closeTo(e.tempoFinal! / 2, VoltaFantasma.passo));
      // ida e volta pelo texto salvo
      final de = VoltaFantasma.desserializar(v.serializar())!;
      expect(de.tempo, closeTo(v.tempo, .01));
      expect(de.n, v.n);
      expect(de.xEm(3), closeTo(v.xEm(3), .1));
      expect(VoltaFantasma.desserializar('lixo'), isNull);
      expect(VoltaFantasma.desserializar(null), isNull);
    });

    test('estatísticas somam corridas e os troféus abrem na hora certa', () {
      final e = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
      e.terminou = true;
      e.palavras = 12;
      e.fichasPegas = 30;
      e.melhorCombo = 11;
      e.posicao = 4000;
      var s = EstatisticasGt.vazio.somar(e);
      expect(s.corridas, 1);
      expect(s.chegadas, 1);
      expect(s.voltasLimpas, 1);
      expect(s.km, closeTo(4, 1e-9));
      expect(s.melhorCombo, 11);
      s = EstatisticasGt.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>).somar(e, bateuFantasma: true);
      expect(s.corridas, 2);
      expect(s.fantasmasBatidos, 1);
      const camp = EstadoCampeonato(medalhas: {1: 3});
      final ganhos = trofeusGt.where((t) => t.ganhou(s, camp)).map((t) => t.id).toSet();
      expect(ganhos, containsAll(['bandeirada', 'ouro', 'limpa', 'combo', 'fantasma']));
      expect(ganhos, isNot(contains('maratona')));
      expect(ganhos, isNot(contains('garagem')));
    });
  });

  group('ProgressoTurismo', () {
    test('guarda a melhor medalha/tempo e libera a próxima pista', () async {
      SharedPreferences.setMockInitialValues({});
      expect((await ProgressoTurismo.carregar()).pistaMax, 1);
      await ProgressoTurismo.registrar(pista: 1, medalha: 2, tempo: 50);
      var e = await ProgressoTurismo.carregar();
      expect(e.pistaMax, 2);
      expect(e.medalhaDe(1), 2);
      expect(e.tempoDe(1), 50);
      expect(e.liberada(2), isTrue);
      expect(e.liberada(3), isFalse);
      await ProgressoTurismo.registrar(pista: 1, medalha: 1, tempo: 60); // pior: não rebaixa
      e = await ProgressoTurismo.carregar();
      expect(e.medalhaDe(1), 2);
      expect(e.tempoDe(1), 50);
      await ProgressoTurismo.registrar(pista: 1, medalha: 3, tempo: 40);
      await ProgressoTurismo.registrar(pista: 2, medalha: 0, tempo: 99); // sem medalha não libera
      e = await ProgressoTurismo.carregar();
      expect(e.medalhaDe(1), 3);
      expect(e.ouros, 1);
      expect(e.pistaMax, 2);
      expect(e.tempoDe(2), 99);
    });
  });
}
