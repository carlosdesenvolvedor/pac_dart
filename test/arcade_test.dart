import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/banco_desafios.dart';
import 'package:pac_dart/features/arcade/domain/caca_bug_engine.dart';
import 'package:pac_dart/features/arcade/domain/corrida_engine.dart';
import 'package:pac_dart/features/arcade/domain/desafio.dart';
import 'package:pac_dart/features/arcade/domain/dicas_dart.dart';
import 'package:pac_dart/features/arcade/domain/digitar_palavra.dart';
import 'package:pac_dart/features/arcade/domain/futebol_engine.dart';
import 'package:pac_dart/features/arcade/domain/palavras_dart.dart';
import 'package:pac_dart/features/arcade/domain/tiro_engine.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/cenario.dart';

void main() {
  group('banco de desafios', () {
    test('todo desafio é jogável: 3 opções únicas, certa válida, textos e nível', () {
      for (final d in bancoDesafios) {
        expect(d.opcoes, hasLength(3), reason: d.pergunta);
        expect(d.opcoes.toSet(), hasLength(3), reason: 'opções repetidas: ${d.pergunta}');
        expect(d.certa, inInclusiveRange(0, d.opcoes.length - 1));
        expect(d.pergunta, isNotEmpty);
        expect(d.explica, isNotEmpty);
        expect(d.nivel, inInclusiveRange(1, 3));
      }
    });

    test('há material de sobra nos dois baralhos', () {
      expect(bancoDesafios.where((d) => d.tipo == TipoDesafio.logica).length,
          greaterThanOrEqualTo(20));
      expect(bancoDesafios.where((d) => d.tipo == TipoDesafio.sintaxe).length,
          greaterThanOrEqualTo(20));
    });

    test('todo bug é caçável: linha válida, trecho e explicação', () {
      for (final b in bancoBugs) {
        expect(b.linhas.length, greaterThanOrEqualTo(2), reason: b.missao);
        expect(b.linhaComBug, inInclusiveRange(0, b.linhas.length - 1));
        expect(b.missao, isNotEmpty);
        expect(b.explica, isNotEmpty);
        expect(b.nivel, inInclusiveRange(1, 3));
      }
      expect(bancoBugs.length, greaterThanOrEqualTo(12));
    });

    test('embaralhado muda a ordem mas preserva a resposta certa', () {
      final rnd = Random(3);
      for (final d in bancoDesafios) {
        final e = d.embaralhado(rnd);
        expect(e.opcoes.toSet(), d.opcoes.toSet());
        expect(e.opcoes[e.certa], d.opcoes[d.certa]);
      }
    });

    test('sortearDesafios respeita tipo, quantidade e a escadinha de nível', () {
      final fila = sortearDesafios(
          tipo: TipoDesafio.logica, quantidade: 12, rnd: Random(1), banco: bancoDesafios);
      expect(fila, hasLength(12));
      expect(fila.every((d) => d.tipo == TipoDesafio.logica), isTrue);
      for (var i = 1; i < fila.length; i++) {
        expect(fila[i].nivel, greaterThanOrEqualTo(fila[i - 1].nivel));
      }
      // pedir mais que o banco recicla o baralho em vez de quebrar
      final grande = sortearDesafios(
          tipo: TipoDesafio.sintaxe, quantidade: 80, rnd: Random(1), banco: bancoDesafios);
      expect(grande, hasLength(80));
    });
  });

  group('CorridaEngine', () {
    test('acertos avançam (turbo dobra), erros dão passo ao rival', () {
      final e = CorridaEngine(pista: 8, dificuldade: Dificuldade.normal);
      e.responder(certa: true, turbo: false);
      expect(e.posJogador, 1);
      e.responder(certa: true, turbo: true);
      expect(e.posJogador, 3);
      e.responder(certa: false, turbo: false);
      expect(e.posJogador, 3);
      expect(e.posCpu, 1);
      expect(e.acertos, 2);
      expect(e.turbos, 1);
      expect(e.erros, 1);
    });

    test('jogador cruza a linha e vence; nada muda depois do fim', () {
      final e = CorridaEngine(pista: 3, dificuldade: Dificuldade.facil);
      e.responder(certa: true, turbo: true); // 2
      e.responder(certa: true, turbo: true); // 4 → clamp 3
      expect(e.terminou, isTrue);
      expect(e.venceu, isTrue);
      e.tickCpu();
      e.responder(certa: true, turbo: false);
      expect(e.posCpu, 0);
      expect(e.posJogador, 3);
    });

    test('a CPU também sabe vencer', () {
      final e = CorridaEngine(pista: 2, dificuldade: Dificuldade.dificil);
      e.tickCpu();
      e.tickCpu();
      expect(e.terminou, isTrue);
      expect(e.venceu, isFalse);
    });

    test('pontos usam o multiplicador da dificuldade', () {
      final e = CorridaEngine(pista: 2, dificuldade: Dificuldade.dificil);
      e.responder(certa: true, turbo: true); // vence com 1 acerto turbo
      expect(e.venceu, isTrue);
      // (15 do acerto + 5 do turbo + 50 da vitória) x2
      expect(e.pontos, 140);
    });
  });

  group('FutebolEngine', () {
    test('gol conta, defesa conta, e a série acaba em 5', () {
      final e = FutebolEngine();
      expect(e.chutar(certa: true), Chute.gol);
      expect(e.chutar(certa: false), Chute.defesa);
      e.chutar(certa: true);
      e.chutar(certa: true);
      e.chutar(certa: false);
      expect(e.terminou, isTrue);
      expect(e.gols, 3);
      expect(e.defesas, 2);
      expect(e.pontos, 60);
      expect(e.chutar(certa: true), Chute.defesa); // depois do fim, nada muda
      expect(e.gols, 3);
    });

    test('série perfeita ganha o bônus', () {
      final e = FutebolEngine();
      for (var i = 0; i < 5; i++) {
        e.chutar(certa: true);
      }
      expect(e.perfeito, isTrue);
      expect(e.pontos, 130); // 5x20 + 30
    });
  });

  group('CacaBugEngine', () {
    final rodadas = sortearBugs(quantidade: 3, rnd: Random(5), banco: bancoBugs);

    test('acertar soma 10 + segundos restantes; errar só avança', () {
      final e = CacaBugEngine(rodadas: rodadas);
      final bug = e.atual.linhaComBug;
      expect(e.escolher(bug, 8), isTrue);
      expect(e.pontos, 18);
      expect(e.acertos, 1);

      final linhaSa = (e.atual.linhaComBug + 1) % e.atual.linhas.length;
      expect(e.escolher(linhaSa, 9), isFalse);
      expect(e.pontos, 18);
      expect(e.rodada, 2);
    });

    test('tempo estourado passa a rodada e o jogo termina no fim da fila', () {
      final e = CacaBugEngine(rodadas: rodadas);
      e.estourouTempo();
      e.estourouTempo();
      e.escolher(e.atual.linhaComBug, 2);
      expect(e.terminou, isTrue);
      expect(e.pontos, 12);
      e.estourouTempo(); // não explode depois do fim
      expect(e.rodada, 3);
    });

    test('tempo da rodada aperta com o nível', () {
      for (final b in bancoBugs) {
        final e = CacaBugEngine(rodadas: [b]);
        expect(e.tempoRodada.inSeconds, inInclusiveRange(6, 14));
      }
    });
  });

  group('vocabulário dos jogos de digitação', () {
    test('tamanhos por nível, só letras [A-Za-z], sem repetidas', () {
      for (final p in palavrasCurtas) {
        expect(p.length, inInclusiveRange(3, 5), reason: p);
      }
      for (final p in palavrasMedias) {
        expect(p.length, inInclusiveRange(6, 8), reason: p);
      }
      for (final p in palavrasLongas) {
        expect(p.length, greaterThanOrEqualTo(9), reason: p);
      }
      final todas = [...palavrasCurtas, ...palavrasMedias, ...palavrasLongas];
      expect(todas.toSet().length, todas.length, reason: 'palavra duplicada');
      for (final p in todas) {
        expect(RegExp(r'^[A-Za-z]+$').hasMatch(p), isTrue, reason: p);
      }
      expect(baralhoRali(Random(1)).toSet(), {...palavrasCurtas, ...palavrasMedias});
      // fase 3+: os chefões compridos entram no baralho
      expect(baralhoRali(Random(2), comLongas: true).toSet().containsAll(palavrasLongas),
          isTrue);
    });
  });

  group('fases: cenários e dicas', () {
    test('cenários ciclam de 6 em 6, com nome e emoji', () {
      expect({for (var f = 1; f <= 6; f++) nomeDaFase(f)}.length, 6);
      expect(nomeDaFase(1), nomeDaFase(7));
      expect(emojiDaFase(3), isNotEmpty);
    });

    test('dica da fase cicla o baralho de dicas', () {
      expect(dicaDaFase(1), dicasDart.first);
      expect(dicaDaFase(dicasDart.length + 1), dicasDart.first);
      expect(dicasDart.length, greaterThanOrEqualTo(15));
    });
  });

  group('ProgressoPalavra', () {
    test('anda letra a letra; errada conta erro e não anda', () {
      final p = ProgressoPalavra()..carregar('var');
      expect(p.teclar('v'), isTrue);
      expect(p.teclar('x'), isFalse);
      expect(p.errosPalavra, 1);
      expect(p.idx, 1);
      expect(p.teclar('a'), isTrue);
      expect(p.teclar('r'), isTrue);
      expect(p.completa, isTrue);
      expect(p.teclar('!'), isFalse); // depois de completa, ignora
    });
  });

  group('TiroEngine (Chuva de Código)', () {
    test('spawna no primeiro tick e a palavra cai com o tempo', () {
      final e = TiroEngine(rnd: Random(1));
      e.tick(0.01);
      expect(e.ativas, hasLength(1));
      final y0 = e.ativas.first.y;
      e.tick(1);
      expect(e.ativas.first.y, greaterThan(y0));
    });

    test('a mira trava na palavra MAIS BAIXA que começa com a letra', () {
      final e = TiroEngine(rnd: Random(1));
      e.ativas.addAll([
        PalavraCaindo(id: 1, texto: 'var', x: .2, y: .2),
        PalavraCaindo(id: 2, texto: 'void', x: .6, y: .7),
      ]);
      final (r, p) = e.teclar('v');
      expect(r, TiroResultado.avancou);
      expect(p!.id, 2); // a mais urgente
      expect(e.alvoId, 2);
      expect(p.digitadas, 1);
    });

    test('letra sem palavra na tela conta erro e não trava nada', () {
      final e = TiroEngine(rnd: Random(1));
      e.ativas.add(PalavraCaindo(id: 1, texto: 'var', x: .5, y: .5));
      final (r, p) = e.teclar('z');
      expect(r, TiroResultado.errou);
      expect(p, isNull);
      expect(e.erros, 1);
      expect(e.alvoId, isNull);
    });

    test('errar no meio mantém a mira travada e a palavra parada', () {
      final e = TiroEngine(rnd: Random(1));
      e.ativas.add(PalavraCaindo(id: 1, texto: 'var', x: .5, y: .5));
      e.teclar('v');
      final (r, p) = e.teclar('x');
      expect(r, TiroResultado.errou);
      expect(p!.id, 1);
      expect(e.alvoId, 1);
      expect(p.digitadas, 1);
    });

    test('completar destrói, pontua (ouro 4x) e libera a mira', () {
      final e = TiroEngine(rnd: Random(1));
      e.ativas.add(PalavraCaindo(id: 1, texto: 'var', x: .5, y: .5, ouro: true));
      e.teclar('v');
      e.teclar('a');
      final (r, _) = e.teclar('r');
      expect(r, TiroResultado.destruiu);
      expect(e.pontos, (10 + 3) * 4);
      expect(e.destruidas, 1);
      expect(e.ativas, isEmpty);
      expect(e.alvoId, isNull);
    });

    test('palavra no chão custa vida; três quedas encerram o jogo', () {
      final e = TiroEngine(rnd: Random(1));
      for (var i = 0; i < 3; i++) {
        e.ativas.add(PalavraCaindo(id: 50 + i, texto: 'xyz', x: .5, y: .99));
        e.tick(0.5);
        expect(e.vidas, 2 - i);
      }
      expect(e.fim, isTrue);
      final antes = e.pontos;
      e.tick(1); // depois do fim, nada mexe
      expect(e.teclar('v').$1, TiroResultado.nada);
      expect(e.pontos, antes);
    });

    test('nível sobe a cada 8 destruídas — e o jogo acelera', () {
      final e = TiroEngine(rnd: Random(1));
      final v0 = e.velocidade;
      final s0 = e.intervaloSpawn;
      for (var i = 0; i < 8; i++) {
        e.ativas.add(PalavraCaindo(id: 100 + i, texto: 'var', x: .5, y: .5));
        e.teclar('v');
        e.teclar('a');
        e.teclar('r');
      }
      expect(e.destruidas, 8);
      expect(e.nivel, 2);
      expect(e.velocidade, greaterThan(v0));
      expect(e.intervaloSpawn, lessThan(s0));
    });
  });
}
