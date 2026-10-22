// English Turismo com 30 pistas: as 10 de sempre (idênticas, mesmo RNG) + 20 extras só do inglês
// (tabela 3.2 do plano). O Dart e o C# continuam com as 10.
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';

/// A mesma pista com outra fração de retas (o resto igual).
PistaGt _comRetas(PistaGt p, double retas) => PistaGt(
      numero: p.numero,
      nome: p.nome,
      dificuldade: p.dificuldade,
      tema: p.tema,
      distancia: p.distancia,
      velAlvo: p.velAlvo,
      tempoPorPortal: p.tempoPorPortal,
      curvaMax: p.curvaMax,
      nivelPalavras: p.nivelPalavras,
      duasSaidas: p.duasSaidas,
      musica: p.musica,
      tituloMusica: p.tituloMusica,
      retas: retas,
    );

/// Fração de segmentos sem curva depois da largada reta (os 10 primeiros são sempre retos).
double _fracaoRetos(TurismoEngine e) {
  final s = e.segmentos.skip(10).toList();
  return s.where((x) => x.curva == 0).length / s.length;
}

void main() {
  const lista = pistasGtIngles;
  const rotulosExtras = {'Lendário II', 'Mítico', 'Sprint Mítico', 'Mítico II', 'Lenda Viva', 'Sprint Lenda'};

  group('pistasGtIngles: invariantes da tabela 3.2', () {
    test('30 pistas, números contíguos, nomes únicos; Dart/C# continuam com as 10', () {
      expect(lista, hasLength(30));
      for (var i = 0; i < lista.length; i++) {
        expect(lista[i].numero, i + 1, reason: 'o _fimDaCorrida indexa lista[pista.numero]');
      }
      expect(lista.map((p) => p.nome).toSet(), hasLength(30));
      expect(pistasClassicas, 10);
      expect(pistasGt, hasLength(pistasClassicas));
      expect(pistasGtExtrasIngles, hasLength(20));
      expect(pistasSprintIngles, {17, 27});
    });

    test('pistasTurismo: inglês = as 30; Dart/C# = exatamente pistasGt', () {
      expect(identical(pistasTurismo(ingles: false), pistasGt), isTrue);
      expect(identical(pistasTurismo(ingles: true), pistasGtIngles), isTrue);
      expect(pistasTurismo(ingles: true), hasLength(30));
    });

    test('as 10 primeiras são os MESMOS objetos de pistasGt (consts canonicalizadas), todas com retas .12', () {
      for (var i = 0; i < pistasClassicas; i++) {
        expect(identical(lista[i], pistasGt[i]), isTrue, reason: pistasGt[i].nome);
        expect(pistasGt[i].retas, .12, reason: pistasGt[i].nome);
      }
      expect(listEquals(lista.sublist(0, pistasClassicas), pistasGt), isTrue);
    });

    test('temas: 1..6 nas clássicas e tema == numero - 4 nas extras (7..26), sem repetição', () {
      for (final p in pistasGt) {
        expect(p.tema, inInclusiveRange(1, 6), reason: p.nome);
      }
      final extras = [for (final p in pistasGtExtrasIngles) p.tema];
      for (final p in pistasGtExtrasIngles) {
        expect(p.tema, p.numero - 4, reason: p.nome);
      }
      expect(extras.toSet(), hasLength(20));
      expect(extras.toSet(), {for (var t = 7; t <= 26; t++) t});
    });

    test('fora das sprints a distância sobe sempre e as vagas de palavras nunca diminuem', () {
      final seq = [for (var n = 10; n <= 30; n++) if (!pistasSprintIngles.contains(n)) lista[n - 1]];
      expect(seq, hasLength(19));
      for (var k = 1; k < seq.length; k++) {
        final a = seq[k - 1], b = seq[k];
        expect(b.distancia, greaterThan(a.distancia), reason: '${a.numero} → ${b.numero}');
        expect(TurismoEngine.vagasDePalavras(b), greaterThanOrEqualTo(TurismoEngine.vagasDePalavras(a)),
            reason: '${a.numero} → ${b.numero}');
      }
    });

    test('sprints: curtas (≤ 10 km) e com curva máxima 6', () {
      for (final n in pistasSprintIngles) {
        final p = lista[n - 1];
        expect(p.distancia, lessThanOrEqualTo(10000), reason: p.nome);
        expect(p.curvaMax, 6, reason: p.nome);
        expect(p.dificuldade, startsWith('Sprint'), reason: p.nome);
      }
    });

    test('velAlvo nunca diminui de 1 a 30 (sprints incluídas)', () {
      for (var i = 1; i < lista.length; i++) {
        expect(lista[i].velAlvo, greaterThanOrEqualTo(lista[i - 1].velAlvo), reason: lista[i].nome);
      }
    });

    test('limites de curva/retas, ouro alcançável e 2,8 s por portal na velocidade máxima', () {
      for (final p in lista) {
        expect(p.curvaMax, lessThanOrEqualTo(6), reason: p.nome);
        expect(p.retas, inInclusiveRange(0, .5), reason: p.nome);
        expect(p.distancia / p.tempoOuro, lessThanOrEqualTo(p.velMax * .92), reason: p.nome);
        expect(p.intervaloPortais / p.velMax, closeTo(2.8, 1e-9), reason: p.nome);
      }
    });

    test('extras: nível 3, duas saídas e rótulos crescentes depois de "Lendário"', () {
      for (final p in pistasGtExtrasIngles) {
        expect(p.nivelPalavras, 3, reason: p.nome);
        expect(p.duasSaidas, isTrue, reason: p.nome);
        expect(rotulosExtras, contains(p.dificuldade), reason: p.nome);
      }
    });

    test('música: um dos 10 arquivos, com o mesmo título da pista clássica que usa o arquivo', () {
      final titulos = {for (final p in pistasGt) p.musica: p.tituloMusica};
      expect(titulos, hasLength(10));
      for (final p in pistasGtExtrasIngles) {
        expect(titulos.keys, contains(p.musica), reason: p.nome);
        expect(p.tituloMusica, titulos[p.musica], reason: p.nome);
      }
    });

    test('portais/vagas e velocidade máxima batem com a tabela 3.2', () {
      // (número, portais, vagas, km/h máx. arredondada)
      const tabela = [
        (11, 64, 128, 241), (12, 65, 130, 243), (13, 66, 132, 243), (14, 67, 134, 245), (15, 67, 134, 245),
        (16, 68, 136, 247), (17, 46, 92, 247), (18, 70, 140, 249), (19, 70, 140, 249), (20, 71, 142, 251),
        (21, 72, 144, 251), (22, 72, 144, 253), (23, 73, 146, 253), (24, 74, 148, 255), (25, 75, 150, 255),
        (26, 75, 150, 257), (27, 47, 94, 257), (28, 77, 154, 259), (29, 78, 156, 259), (30, 78, 156, 261),
      ];
      for (final (n, portais, vagas, kmh) in tabela) {
        final p = lista[n - 1];
        expect(TurismoEngine.portaisDaPista(p), portais, reason: p.nome);
        expect(TurismoEngine.vagasDePalavras(p), vagas, reason: p.nome);
        expect(p.velMaxKmh.round(), kmh, reason: p.nome);
      }
      // a 10 continua como era
      expect(TurismoEngine.portaisDaPista(pistasGt.last), 63);
      expect(TurismoEngine.vagasDePalavras(pistasGt.last), 126);
    });
  });

  group('TurismoEngine com as 30 pistas', () {
    test('constrói todas com as sementes 3/7/42; portais.length == portaisDaPista; pista cobre a distância', () {
      for (final p in lista) {
        for (final semente in const [3, 7, 42]) {
          final e = TurismoEngine(pista: p, rnd: Random(semente));
          expect(e.portais.length, TurismoEngine.portaisDaPista(p), reason: '${p.nome} semente $semente');
          expect(e.segmentos.length * TurismoEngine.comprimentoSegmento, greaterThanOrEqualTo(p.distancia),
              reason: p.nome);
          for (final s in e.segmentos) {
            expect(s.curva.abs(), lessThanOrEqualTo(p.curvaMax + 1e-9), reason: p.nome);
          }
          for (final portal in e.portais) {
            expect(portal.palavras, hasLength(p.duasSaidas ? 2 : 1), reason: p.nome);
          }
        }
      }
    });

    test('as extras também rodam com as palavras do inglês injetadas (iniciais diferentes nas duas saídas)', () {
      final v = VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn);
      for (final p in pistasGtExtrasIngles) {
        final palavras = p.vocabularioCom(v);
        final e = TurismoEngine(
            pista: p, rnd: Random(42), vocabulario: palavras, traducoes: v.traducoes, semLimiteDeTempo: true);
        expect(e.portais.length, TurismoEngine.portaisDaPista(p), reason: p.nome);
        for (final portal in e.portais) {
          for (final w in portal.palavras) {
            expect(palavras, contains(w), reason: p.nome);
          }
          expect(portal.palavras[0][0].toLowerCase(), isNot(portal.palavras[1][0].toLowerCase()), reason: p.nome);
        }
      }
    });

    test('retas muda a fração de trechos retos (sem retas ≈ só as junções; .45 bem mais retas)', () {
      final base = pistasGtExtrasIngles.first;
      for (final semente in const [3, 7, 42]) {
        final zero = _fracaoRetos(TurismoEngine(pista: _comRetas(base, 0), rnd: Random(semente)));
        final muitas = _fracaoRetos(TurismoEngine(pista: _comRetas(base, .45), rnd: Random(semente)));
        expect(muitas, greaterThan(zero + .15), reason: 'semente $semente: $zero vs $muitas');
      }
      // na média de várias sementes, a Ponte (.45) tem mais reta que o Cânion (.05)
      double media(PistaGt p) {
        var soma = 0.0;
        for (var s = 0; s < 20; s++) {
          soma += _fracaoRetos(TurismoEngine(pista: p, rnd: Random(s)));
        }
        return soma / 20;
      }

      expect(media(lista[15]), greaterThan(media(lista[16])), reason: 'Ponte sobre o Mar × Cânion Vermelho');
    });

    test('retas .12 explícito = o default: mesma pista e mesmos portais para a mesma semente', () {
      for (final p in pistasGt) {
        final a = TurismoEngine(pista: p, rnd: Random(9));
        final b = TurismoEngine(pista: _comRetas(p, .12), rnd: Random(9));
        expect([for (final s in b.segmentos) s.curva], [for (final s in a.segmentos) s.curva], reason: p.nome);
        expect([for (final x in b.portais) x.palavras], [for (final x in a.portais) x.palavras], reason: p.nome);
      }
    });
  });
}
