// Dart Turismo no inglês: as palavras das lições entram na pista (injetadas no motor), as duas
// saídas nunca começam com a mesma letra, as fichas viram fichasIngles — e o Dart, sem injeção,
// continua sorteando EXATAMENTE a mesma pista de antes.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';

/// Réplica do sorteio ORIGINAL (antes da injeção): curvas da pista e, por portal, faixas, palavras e
/// fichas. Se o motor mudar a ordem das chamadas ao Random no caminho do Dart, isto denuncia.
({List<double> curvas, List<(List<int>, List<String>, List<String>)> portais}) _replica(PistaGt pista, int semente) {
  final rnd = Random(semente);
  const seg = TurismoEngine.comprimentoSegmento;
  final total = (pista.distancia / seg).ceil() + 40;
  final curvas = List<double>.filled(total, 0);
  double suave(double t) => t * t * (3 - 2 * t);
  var i = 10;
  var sentido = rnd.nextBool() ? 1.0 : -1.0;
  while (i < total) {
    final reta = rnd.nextDouble() < .12;
    final alvo = reta ? 0.0 : sentido * pista.curvaMax * (.5 + .5 * rnd.nextDouble());
    if (!reta && rnd.nextDouble() < .8) sentido = -sentido;
    final entrada = 4 + rnd.nextInt(5);
    final manter = 5 + rnd.nextInt(9);
    final saida = 4 + rnd.nextInt(5);
    for (var k = 0; k < entrada && i < total; k++, i++) {
      curvas[i] = alvo * suave(k / entrada);
    }
    for (var k = 0; k < manter && i < total; k++, i++) {
      curvas[i] = alvo;
    }
    for (var k = 0; k < saida && i < total; k++, i++) {
      curvas[i] = alvo * (1 - suave(k / saida));
    }
  }
  final usadas = <String>[];
  String sorteia() {
    final pool = pista.vocabulario;
    for (var t = 0; t < 40; t++) {
      final p = pool[rnd.nextInt(pool.length)];
      if (!usadas.contains(p)) {
        usadas.add(p);
        if (usadas.length > 8) usadas.removeAt(0);
        return p;
      }
    }
    return pool[rnd.nextInt(pool.length)];
  }

  final portais = <(List<int>, List<String>, List<String>)>[];
  var anterior = TurismoEngine.faixaInicial;
  final intervalo = pista.intervaloPortais;
  for (var z = intervalo; z < pista.distancia - 40; z += intervalo) {
    final candidatas = [0, 1, 2]..remove(anterior);
    candidatas.shuffle(rnd);
    final faixas = pista.duasSaidas ? [candidatas[0], candidatas[1]] : [candidatas[0]];
    final palavras = [for (final _ in faixas) sorteia()];
    final fichas = [for (var k = 0; k < 3; k++) fichasDart[rnd.nextInt(fichasDart.length)]];
    portais.add((faixas, palavras, fichas));
    anterior = faixas.first;
  }
  return (curvas: curvas, portais: portais);
}

/// Um vocabulário "de lições" com bastante coisa começando pela mesma letra (o pior caso).
final _vocab = VocabularioJogo(
  curtas: const ['seat', 'sun', 'sky', 'song', 'tree', 'tea', 'map', 'milk', 'boat', 'book', 'rain', 'road'],
  medias: const ['sister', 'summer', 'silver', 'school', 'teacher', 'mother', 'bridge', 'garden', 'kitchen', 'window'],
  longas: const ['something', 'sometimes', 'restaurant', 'beautiful', 'yesterday', 'important', 'different', 'afternoon'],
  traducoes: const {'seat': 'assento', 'something': 'algo'},
);

void main() {
  tearDown(() => Linguagem.atual = Linguagem.dart);

  test('vocabularioCom(fixo) é igual ao getter em todas as pistas (Dart, C# e inglês)', () {
    for (final l in Linguagem.values) {
      Linguagem.atual = l;
      for (final p in pistasGt) {
        expect(p.vocabularioCom(VocabularioJogo.deListas(vocabularioDe())), p.vocabulario, reason: '${l.id} ${p.nome}');
      }
    }
    Linguagem.atual = Linguagem.dart;
    // nível 1 devolve a MESMA lista (sem cópia), como antes
    expect(identical(pistasGt.first.vocabulario, vocabularioDe().curtas), isTrue);
  });

  test('sem injeção (Dart): a pista é idêntica ao sorteio original com a mesma semente', () {
    for (final p in pistasGt) {
      for (final semente in [3, 7, 42]) {
        final e = TurismoEngine(pista: p, rnd: Random(semente));
        final r = _replica(p, semente);
        expect([for (final s in e.segmentos) s.curva], r.curvas, reason: p.nome);
        expect(e.portais.length, r.portais.length, reason: p.nome);
        for (var k = 0; k < e.portais.length; k++) {
          final (faixas, palavras, fichas) = r.portais[k];
          expect(e.portais[k].faixas, faixas, reason: '${p.nome} portal $k');
          expect(e.portais[k].palavras, palavras, reason: '${p.nome} portal $k');
          expect([for (final f in e.portais[k].fichas) f.texto], fichas, reason: '${p.nome} portal $k');
        }
        expect(e.vocabulario, isNull);
        expect(e.traducao(e.portais.first.palavras.first), isNull, reason: 'Dart não traduz');
      }
    }
  });

  test('com palavras injetadas, todo portal (e o combustível) usa só elas, e as fichas são fichasIngles', () {
    for (final p in pistasGt) {
      final lista = p.vocabularioCom(_vocab);
      final e = TurismoEngine(pista: p, rnd: Random(11), vocabulario: lista, traducoes: _vocab.traducoes);
      for (final portal in e.portais) {
        for (final w in portal.palavras) {
          expect(lista, contains(w), reason: p.nome);
        }
        for (final f in portal.fichas) {
          expect(fichasIngles, contains(f.texto));
        }
      }
      // portal já digitado: entra a palavra de combustível — também da lista
      e.portais.first.digitado = 0;
      e.teclar('#');
      expect(e.palavraGas, isNotNull);
      expect(lista, contains(e.palavraGas), reason: p.nome);
    }
    final e = TurismoEngine(pista: pistasGt.first, rnd: Random(1), vocabulario: _vocab.curtas, traducoes: _vocab.traducoes);
    expect(e.traducao('seat'), 'assento');
    expect(e.traducao('Seat'), 'assento', reason: 'cai para minúsculas');
    expect(e.traducao('sun'), isNull);
    // lista vazia = sem injeção
    expect(TurismoEngine(pista: pistasGt.first, rnd: Random(1), vocabulario: const []).vocabulario, isNull);
  });

  test('pistas 7–10 (duas saídas) com palavras injetadas: iniciais sempre diferentes em 200 sementes', () {
    for (final p in pistasGt.sublist(6)) {
      expect(p.duasSaidas, isTrue);
      final lista = p.vocabularioCom(_vocab);
      for (var semente = 0; semente < 200; semente++) {
        final e = TurismoEngine(pista: p, rnd: Random(semente), vocabulario: lista);
        for (final portal in e.portais) {
          expect(portal.palavras, hasLength(2));
          expect(portal.palavras[0][0].toLowerCase(), isNot(portal.palavras[1][0].toLowerCase()),
              reason: '${p.nome} semente $semente: ${portal.palavras}');
        }
      }
    }
  });

  test('a lista de reserva do inglês também funciona injetada (cada palavra com tradução)', () {
    final v = VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn);
    for (final p in pistasGt) {
      final e = TurismoEngine(pista: p, rnd: Random(5), vocabulario: p.vocabularioCom(v), traducoes: v.traducoes);
      for (final portal in e.portais) {
        for (final w in portal.palavras) {
          expect(e.traducao(w), isNotNull, reason: w);
        }
      }
    }
  });
}
