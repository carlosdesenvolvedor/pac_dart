// O baralho por fase do Arcade do inglês (BaralhoFases): cada fase traz palavras NOVAS (o vocabulário
// inteiro roda antes de alguma voltar), cada fase traz MAIS palavras, e algumas voltam de propósito pra
// revisar 🔁 — as que caíram, as erradas e as lentas da partida, e um par das difíceis do banco na 1ª
// fase. Mais: a fase 1 do Rali igual ao baralho antigo, o reenfileirar da Chuva/Turismo, o cronômetro
// por palavra e a cola com o banco (dificeisDoBanco e as lentas no PlacarPalavras.enviar).
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/domain/baralho_fases.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/banco_arcade.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/linha_fase.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _en = VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn);

/// [n] palavras distintas com iniciais variadas: 'apple0', 'banana1', … (a inicial roda pelo alfabeto).
List<String> _pool(int n) => [for (var i = 0; i < n; i++) '${String.fromCharCode(97 + i % 26)}w$i'];

/// Registra todas as cartas do baralho limpas (sem tempo).
void _jogarLimpo(BaralhoFases b, DeckFase d) {
  for (final w in d.palavras) {
    b.registrar(w);
  }
}

/// Nenhuma palavra igual à anterior.
bool _semVizinhasIguais(List<String> ws) {
  for (var i = 1; i < ws.length; i++) {
    if (ws[i] == ws[i - 1]) return false;
  }
  return true;
}

/// Nenhuma revisão encostada em outra.
bool _revisoesEspacadas(DeckFase d) {
  for (var i = 1; i < d.cartas.length; i++) {
    if (d.cartas[i].revisao && d.cartas[i - 1].revisao && d.cartas[i].origem != OrigemCarta.foco) return false;
  }
  return true;
}

void main() {
  group('a fase 1 do Rali = o baralho antigo', () {
    test('sem foco, com foco e com o filtro do modo memória, sementes 0–20', () {
      final focoV = VocabularioJogo(
        curtas: _en.curtas,
        medias: _en.medias,
        longas: _en.longas,
        traducoes: traducoesEn,
        foco: {_en.medias[3], _en.curtas[7], 'fora-do-pool'},
      );
      // tradução só em parte das palavras (o filtro do memória corta as outras)
      final parcial = VocabularioJogo(
        curtas: _en.curtas,
        medias: _en.medias,
        longas: _en.longas,
        traducoes: {for (final w in [..._en.curtas, ..._en.medias].where((w) => w.length.isEven)) w: 'x'},
      );
      for (var s = 0; s <= 20; s++) {
        for (final v in [_en, focoV]) {
          final d = BaralhoFases(rnd: Random(s))
              .abrirFase(fase: 1, pool: BaralhoFases.poolRali(v, comLongas: false), tamanho: 12, foco: v.foco);
          expect(d.palavras, BancoArcade.baralhoDoVocabulario(v, Random(s)).take(12).toList(), reason: 'semente $s');
        }
        bool aceita(String w) => parcial.traducao(w) != null;
        final d = BaralhoFases(rnd: Random(s)).abrirFase(
            fase: 1, pool: BaralhoFases.poolRali(parcial, comLongas: false), tamanho: 12, aceita: aceita);
        expect(d.palavras, BancoArcade.baralhoDoVocabulario(parcial, Random(s)).where(aceita).take(12).toList(),
            reason: 'memória, semente $s');
        expect(d.palavras.every(aceita), isTrue);
      }
    });

    test('a fase 1 sai toda nova; o foco vem primeiro e marcado', () {
      final b = BaralhoFases(rnd: Random(4));
      final d = b.abrirFase(fase: 1, pool: _pool(30), tamanho: 12, foco: {'cw2', 'hw7'});
      expect(d.cartas.take(2).map((c) => c.palavra).toSet(), {'cw2', 'hw7'});
      expect(d.cartas.take(2).every((c) => c.origem == OrigemCarta.foco && c.revisao), isTrue);
      expect(d.cartas.skip(2).every((c) => c.origem == OrigemCarta.nova && !c.revisao), isTrue);
      expect(d.distintas, 12);
      expect(b.deck, same(d));
    });
  });

  group('tamanhos', () {
    test('Rali 12, 14, 16 … até 20; Chuva 8, 10, 12 … até 16', () {
      expect([for (var f = 1; f <= 7; f++) BaralhoFases.tamanhoRali(f)], [12, 14, 16, 18, 20, 20, 20]);
      expect([for (var n = 1; n <= 6; n++) BaralhoFases.tamanhoChuva(n)], [8, 10, 12, 14, 16, 16]);
    });

    test('pools: Rali com/sem longas, Chuva por nível', () {
      const v = VocabularioJogo(curtas: ['cat'], medias: ['planet'], longas: ['beautiful']);
      expect(BaralhoFases.poolRali(v, comLongas: false), ['cat', 'planet']);
      expect(BaralhoFases.poolRali(v, comLongas: true), ['cat', 'planet', 'beautiful']);
      expect(BaralhoFases.poolChuva(v, 1), ['cat']);
      expect(BaralhoFases.poolChuva(v, 2), ['cat', 'planet']);
      expect(BaralhoFases.poolChuva(v, 5), ['cat', 'planet', 'beautiful']);
    });

    test('o baralho cresce fase a fase e cada fase traz palavras novas', () {
      final b = BaralhoFases(rnd: Random(9));
      final pool = _pool(120);
      final vistas = <String>{};
      var antes = 0;
      for (var f = 1; f <= 5; f++) {
        final d = b.abrirFase(fase: f, pool: pool, tamanho: BaralhoFases.tamanhoRali(f));
        expect(d.cartas.length, greaterThan(antes), reason: 'fase $f');
        antes = d.cartas.length;
        expect(d.palavras.where(vistas.contains), isEmpty, reason: 'fase $f: nada repetido sem motivo');
        expect(d.novas, d.cartas.length);
        vistas.addAll(d.palavras);
        _jogarLimpo(b, d);
      }
    });
  });

  group('revisão: as que escaparam voltam', () {
    test('caiu e errou voltam na fase 2, espaçadas, com a 1ª carta nova', () {
      final b = BaralhoFases(rnd: Random(1));
      final pool = _pool(60);
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 12);
      final w = d1.palavras;
      for (var i = 0; i < w.length; i++) {
        switch (i) {
          case 2:
            b.registrar(w[i], erros: 1);
          case 5:
            b.registrar(w[i], erros: 3);
          case 7:
            b.registrar(w[i], erros: 2);
          case 9:
            b.registrar(w[i], perdeu: true);
          default:
            b.registrar(w[i]);
        }
      }
      expect(b.pendentes(), [w[9], w[5], w[7], w[2]], reason: 'caiu, depois mais erros primeiro');

      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 14);
      expect(d2.cartas.length, 14);
      final rev = [for (final c in d2.cartas) if (c.revisao) c];
      expect(rev.map((c) => c.palavra), [w[9], w[5], w[7], w[2]]);
      expect(rev.every((c) => c.origem == OrigemCarta.errou), isTrue);
      expect(d2.cartas.first.origem, OrigemCarta.nova);
      expect(_revisoesEspacadas(d2), isTrue);
      expect([for (var i = 0; i < 8; i++) d2.cartas[i].revisao], [false, true, false, true, false, true, false, true],
          reason: 'as revisões vêm cedo, intercaladas');
      expect(d2.novas, 10);
      expect(d2.palavras.where((p) => !d2.ehRevisao(p)).where(w.contains), isEmpty,
          reason: 'as outras são todas novas');
      expect(d2.resumo(), '14 palavras · 10 novas · 4 pra revisar 🔁');
      expect(d2.ehRevisao(w[5]), isTrue);
      expect(d2.ehRevisao(d2.palavras.first), isFalse);

      // limpa (e sem ser lenta) uma vez: sai da revisão
      _jogarLimpo(b, d2);
      final d3 = b.abrirFase(fase: 3, pool: pool, tamanho: 16);
      expect(d3.revisar, 0);
      expect(d3.resumo(), '16 palavras · 16 novas');
    });

    test('o teto: ~35% (mínimo 1 se houver candidata, máximo metade)', () {
      int revisoes(int tamanho, int erradas) {
        final b = BaralhoFases(rnd: Random(2));
        final pool = _pool(80);
        final d = b.abrirFase(fase: 1, pool: pool, tamanho: 40);
        for (var i = 0; i < d.palavras.length; i++) {
          b.registrar(d.palavras[i], erros: i < erradas ? 1 : 0);
        }
        final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: tamanho);
        expect(d2.cartas.length, tamanho);
        expect(_revisoesEspacadas(d2), isTrue);
        return d2.revisar;
      }

      expect(revisoes(12, 20), 4);
      expect(revisoes(14, 20), 5);
      expect(revisoes(20, 20), 7);
      expect(revisoes(12, 1), 1);
      expect(revisoes(2, 5), 1);
      expect(revisoes(3, 5), 1);
      expect(revisoes(1, 5), 0, reason: 'uma carta só: nada a revisar');
      for (var t = 1; t <= 30; t++) {
        expect(revisoes(t, 40), lessThanOrEqualTo(t ~/ 2), reason: 'tamanho $t');
      }
    });

    test('a ordem: caiu > errou > lenta > difícil do banco', () {
      final pool = _pool(50);
      final b = BaralhoFases(rnd: Random(3), dificeis: ['zw25', 'yw24']);
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 16);
      // as difíceis do banco vêm na fase 1 (são as únicas revisões)
      expect([for (final c in d1.cartas) if (c.revisao) c.palavra], ['zw25', 'yw24']);
      final outras = [for (final w in d1.palavras) if (!d1.ehRevisao(w)) w];
      for (final w in outras.take(10)) {
        b.registrar(w, msPorLetra: 200);
      }
      final lenta = outras[10], errou = outras[11], caiu = outras[12];
      b.registrar(lenta, msPorLetra: 400);
      b.registrar(errou, erros: 1, msPorLetra: 200);
      b.registrar(caiu, perdeu: true);
      expect(b.mediana, 200);

      final b2 = BaralhoFases(rnd: Random(3), dificeis: ['zw25']);
      b2.abrirFase(fase: 1, pool: pool, tamanho: 16);
      for (final w in outras.take(10)) {
        b2.registrar(w, msPorLetra: 200);
      }
      b2.registrar(lenta, msPorLetra: 400);
      b2.registrar(errou, erros: 1, msPorLetra: 200);
      b2.registrar(caiu, perdeu: true);
      final d2 = b2.abrirFase(fase: 2, pool: pool, tamanho: 20);
      final rev = [for (final c in d2.cartas) if (c.revisao) c];
      expect(rev.map((c) => (c.palavra, c.origem)), [
        (caiu, OrigemCarta.errou),
        (errou, OrigemCarta.errou),
        (lenta, OrigemCarta.lenta),
        ('zw25', OrigemCarta.dificil),
      ]);
      expect(b2.pendentes(), [caiu, errou, lenta]);
    });

    test('com o teto apertado, as que caíram ganham das erradas e das lentas', () {
      final pool = _pool(40);
      final b = BaralhoFases(rnd: Random(5), dificeis: ['zw25']);
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 20);
      final ws = [for (final w in d1.palavras) if (!d1.ehRevisao(w)) w];
      for (final w in ws.take(12)) {
        b.registrar(w, msPorLetra: 100);
      }
      b.registrar(ws[12], erros: 1);
      b.registrar(ws[13], perdeu: true);
      b.registrar(ws[14], msPorLetra: 900);
      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 4); // teto 1
      expect([for (final c in d2.cartas) if (c.revisao) c.palavra], [ws[13]]);
    });
  });

  group('rodízio do vocabulário', () {
    test('as novas cobrem o pool inteiro antes de alguma voltar (e volta a menos recente)', () {
      final pool = _pool(40);
      final b = BaralhoFases(rnd: Random(6));
      final ordemVistas = <String>[];
      final vistas = <String>{};
      for (var f = 1; f <= 3; f++) {
        final d = b.abrirFase(fase: f, pool: pool, tamanho: BaralhoFases.tamanhoRali(f));
        for (final c in d.cartas) {
          if (c.origem == OrigemCarta.deNovo) {
            expect(vistas.length, 40, reason: 'fase $f: "de novo" só depois de ver todas');
          } else {
            expect(vistas.contains(c.palavra), isFalse);
          }
          if (vistas.add(c.palavra)) ordemVistas.add(c.palavra);
          b.registrar(c.palavra);
        }
      }
      expect(vistas.length, 40);
      final d4 = b.abrirFase(fase: 4, pool: pool, tamanho: 18);
      expect(d4.novas, 0);
      expect(d4.resumo(), '18 palavras · todas já vistas');
      // as 12 da fase 1 (a fase 3 completou com 2 delas) — as menos recentes primeiro
      expect(d4.palavras.take(10), ordemVistas.sublist(2, 12));
    });

    test('as longas entram já na fase 3 do Rali (sorteadas no meio das que faltam)', () {
      var comLonga = 0;
      for (var s = 0; s <= 20; s++) {
        final b = BaralhoFases(rnd: Random(s));
        for (var f = 1; f <= 2; f++) {
          _jogarLimpo(b, b.abrirFase(fase: f, pool: BaralhoFases.poolRali(_en, comLongas: false), tamanho: 12));
        }
        final d3 = b.abrirFase(fase: 3, pool: BaralhoFases.poolRali(_en, comLongas: true), tamanho: 16);
        if (d3.palavras.any(_en.longas.contains)) comLonga++;
        expect(d3.novas, 16, reason: 'semente $s');
      }
      expect(comLonga, greaterThanOrEqualTo(18));
    });

    test('a Chuva: nível 2 já traz médias', () {
      final b = BaralhoFases(rnd: Random(7), reenfileirarNaFase: true);
      _jogarLimpo(b, b.abrirFase(fase: 1, pool: BaralhoFases.poolChuva(_en, 1), tamanho: 8));
      var medias = 0;
      for (var n = 2; n <= 4; n++) {
        final d = b.abrirFase(fase: n, pool: BaralhoFases.poolChuva(_en, 2), tamanho: BaralhoFases.tamanhoChuva(n));
        medias += d.palavras.where(_en.medias.contains).length;
        _jogarLimpo(b, d);
      }
      expect(medias, greaterThan(5));
    });
  });

  group('pool pequeno e casos degenerados', () {
    test('8 palavras e 12 cartas: 12, sem duas iguais seguidas, fase após fase', () {
      final pool = _pool(8);
      final b = BaralhoFases(rnd: Random(8));
      for (var f = 1; f <= 6; f++) {
        final d = b.abrirFase(fase: f, pool: pool, tamanho: 12);
        expect(d.cartas.length, 12);
        expect(d.distintas, 8);
        expect(_semVizinhasIguais(d.palavras), isTrue, reason: 'fase $f: ${d.palavras}');
        for (var i = 0; i < d.palavras.length; i++) {
          b.registrar(d.palavras[i], erros: i == 3 ? 2 : 0);
        }
      }
    });

    test('2 palavras: alternam; 1 palavra: repete; tamanho 1 também serve', () {
      final b = BaralhoFases(rnd: Random(0));
      final d = b.abrirFase(fase: 1, pool: ['cat', 'dog'], tamanho: 7);
      expect(d.cartas.length, 7);
      expect(_semVizinhasIguais(d.palavras), isTrue);
      final um = BaralhoFases(rnd: Random(0)).abrirFase(fase: 1, pool: ['cat'], tamanho: 3);
      expect(um.palavras, ['cat', 'cat', 'cat']);
      expect(um.resumo(), '3 palavras · 1 nova');
      final t1 = BaralhoFases(rnd: Random(0)).abrirFase(fase: 1, pool: _pool(10), tamanho: 1);
      expect(t1.cartas.length, 1);
      expect(t1.resumo(), '1 palavra · 1 nova');
    });

    test('pool repetido conta uma vez; pool vazio e tamanho < 1 dão erro', () {
      final b = BaralhoFases(rnd: Random(0));
      final d = b.abrirFase(fase: 1, pool: ['cat', 'cat', 'dog', 'dog', 'sun'], tamanho: 3);
      expect(d.palavras.toSet(), {'cat', 'dog', 'sun'});
      expect(() => b.abrirFase(fase: 2, pool: const [], tamanho: 3), throwsArgumentError);
      expect(() => b.abrirFase(fase: 2, pool: ['cat'], tamanho: 0), throwsArgumentError);
      expect(() => DeckFase(1, const []), throwsArgumentError);
    });

    test('o filtro que cortaria tudo é ignorado', () {
      final d = BaralhoFases(rnd: Random(0)).abrirFase(fase: 1, pool: _pool(5), tamanho: 5, aceita: (_) => false);
      expect(d.cartas.length, 5);
    });

    test('tirar antes de abrir uma fase é erro', () {
      expect(() => BaralhoFases(rnd: Random(0)).proxima(), throwsStateError);
    });
  });

  group('lentas', () {
    test('> 1,6 × a mediana com 8+ amostras; deixa de ser lenta depois de uma rápida', () {
      final pool = _pool(40);
      final b = BaralhoFases(rnd: Random(10));
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 12);
      final w = d1.palavras;
      for (final x in w.take(10)) {
        b.registrar(x, msPorLetra: 200);
      }
      b.registrar(w[10], msPorLetra: 400);
      b.registrar(w[11], msPorLetra: 300);
      expect(b.mediana, 200);
      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 14);
      expect([for (final c in d2.cartas) if (c.revisao) (c.palavra, c.origem)], [(w[10], OrigemCarta.lenta)]);
      expect(b.pendentes(), [w[10]]);

      b.registrar(w[10], msPorLetra: 210);
      final d3 = b.abrirFase(fase: 3, pool: pool, tamanho: 16);
      expect(d3.ehRevisao(w[10]), isFalse);
    });

    test('com menos de 8 amostras nada é lento', () {
      final pool = _pool(40);
      final b = BaralhoFases(rnd: Random(11));
      final w = b.abrirFase(fase: 1, pool: pool, tamanho: 12).palavras;
      for (final x in w.take(6)) {
        b.registrar(x, msPorLetra: 100);
      }
      b.registrar(w[6], msPorLetra: 3000);
      expect(b.mediana, isNull);
      expect(b.abrirFase(fase: 2, pool: pool, tamanho: 14).revisar, 0);
      expect(b.tirarLentasParaBanco(), isEmpty);
    });

    test('as amostras ficam entre 20 e 5000 ms por letra; a caída não conta tempo', () {
      final b = BaralhoFases(rnd: Random(0));
      b.abrirFase(fase: 1, pool: _pool(20), tamanho: 12);
      for (var i = 0; i < 4; i++) {
        b.registrar('aw0', msPorLetra: 1);
        b.registrar('bw1', msPorLetra: 99999);
      }
      b.registrar('cw2', perdeu: true, msPorLetra: 10);
      expect(b.mediana, (20 + 5000) / 2);
    });

    test('tirarLentasParaBanco: 2+ vezes > 2 × a mediana, uma vez só por partida', () {
      final b = BaralhoFases(rnd: Random(0));
      b.abrirFase(fase: 1, pool: _pool(20), tamanho: 12);
      for (var i = 0; i < 10; i++) {
        b.registrar('aw0', msPorLetra: 200);
      }
      b.registrar('bw1', msPorLetra: 450);
      b.registrar('bw1', msPorLetra: 500);
      b.registrar('cw2', msPorLetra: 450); // só uma vez
      b.registrar('dw3', msPorLetra: 350);
      b.registrar('dw3', msPorLetra: 380); // lenta, mas não MUITO lenta
      expect(b.tirarLentasParaBanco(), {'bw1'});
      expect(b.tirarLentasParaBanco(), isEmpty);
    });
  });

  group('difíceis do banco', () {
    test('no máximo 2 por baralho, só as do pool, espaçadas; vistas deixam de ser difíceis', () {
      final pool = _pool(40);
      final b = BaralhoFases(rnd: Random(12), dificeis: ['fora', 'kw10', 'mw12', 'ow14', 'kw10']);
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 12);
      expect([for (final c in d1.cartas) if (c.origem == OrigemCarta.dificil) c.palavra], ['kw10', 'mw12']);
      expect(d1.palavras, isNot(contains('fora')));
      expect(d1.cartas.first.revisao, isFalse);
      expect(_revisoesEspacadas(d1), isTrue);
      expect(d1.resumo(), '12 palavras · 10 novas · 2 pra revisar 🔁');
      _jogarLimpo(b, d1);
      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 14);
      expect([for (final c in d2.cartas) if (c.origem == OrigemCarta.dificil) c.palavra],
          d1.palavras.contains('ow14') ? isEmpty : ['ow14'], reason: 'a 3ª difícil, se ainda não saiu');
      expect(d2.palavras.where((w) => w == 'kw10' || w == 'mw12'), isEmpty);
    });
  });

  group('foco', () {
    test('vem primeiro, fura o teto e fica na frente até sair; foco novo recomeça', () {
      final pool = _pool(40);
      final b = BaralhoFases(rnd: Random(13));
      final foco = {'aw0', 'bw1', 'cw2', 'dw3', 'ew4', 'fw5'};
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 12, foco: foco);
      expect(d1.palavras.take(6).toSet(), foco);
      expect(d1.cartas.take(6).every((c) => c.origem == OrigemCarta.foco), isTrue);
      // erradas: o foco (6) já passou do teto (4), então nenhuma outra revisão
      for (final w in d1.palavras.skip(6)) {
        b.registrar(w, erros: 1);
      }
      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 12, foco: foco);
      expect(d2.palavras.take(6).toSet(), foco, reason: 'ainda não saíram');
      expect(d2.cartas.where((c) => c.origem == OrigemCarta.errou), isEmpty);
      for (final w in ['aw0', 'bw1', 'cw2', 'dw3', 'ew4']) {
        b.registrar(w);
      }
      final d3 = b.abrirFase(fase: 3, pool: pool, tamanho: 12, foco: foco);
      expect(d3.cartas.first, isA<CartaFase>().having((c) => c.palavra, 'palavra', 'fw5'));
      expect(d3.cartas.where((c) => c.origem == OrigemCarta.foco).length, 1);
      // foco novo
      final d4 = b.abrirFase(fase: 4, pool: pool, tamanho: 12, foco: {'zw25'});
      expect(d4.palavras.first, 'zw25');
      // volta o foco antigo: recomeça (as vistas voltam pra frente)
      final d5 = b.abrirFase(fase: 5, pool: pool, tamanho: 12, foco: foco);
      expect(d5.palavras.take(6).toSet(), foco);
    });
  });

  group('proxima (Chuva e Turismo)', () {
    test('segue o baralho; evitar e outra inicial; a pulada continua a próxima', () {
      final b = BaralhoFases(rnd: Random(14), reenfileirarNaFase: true);
      final d = b.abrirFase(fase: 1, pool: _pool(30), tamanho: 10);
      final p = d.palavras;
      expect(b.proxima().palavra, p[0]);
      expect(b.proxima(evitar: {p[1]}).palavra, p[2]);
      expect(b.proxima().palavra, p[1], reason: 'a pulada ficou na vez');
      final c = b.proxima(outraInicialQue: p[3]);
      expect(c.palavra[0], isNot(p[3][0]));
      expect(c.origem, OrigemCarta.nova);
    });

    test('impossível relaxa: primeiro o evitar, depois a inicial', () {
      final b = BaralhoFases(rnd: Random(0));
      b.abrirFase(fase: 1, pool: ['cat', 'cow'], tamanho: 2);
      final c = b.proxima(evitar: {'cat', 'cow'}, outraInicialQue: 'car');
      expect(['cat', 'cow'], contains(c.palavra));
      final b2 = BaralhoFases(rnd: Random(0));
      b2.abrirFase(fase: 1, pool: ['cat', 'dog'], tamanho: 2);
      expect(b2.proxima(evitar: {'dog'}, outraInicialQue: 'cow').palavra, 'dog',
          reason: 'o evitar cai primeiro, a inicial fica');
    });

    test('1000 tiradas depois do baralho: nunca vazio, nunca a mesma em seguida, novas antes das "de novo"', () {
      final pool = _pool(25);
      final b = BaralhoFases(rnd: Random(15), reenfileirarNaFase: true);
      b.abrirFase(fase: 1, pool: pool, tamanho: 8);
      final tiradas = <CartaFase>[];
      String? ant;
      for (var i = 0; i < 1000; i++) {
        final c = b.proxima(evitar: ant == null ? const {} : {ant});
        tiradas.add(c);
        ant = c.palavra;
        b.registrar(c.palavra, erros: i % 17 == 0 ? 2 : 0);
      }
      expect(_semVizinhasIguais([for (final c in tiradas) c.palavra]), isTrue);
      expect(tiradas.take(25).map((c) => c.palavra).toSet().length, greaterThanOrEqualTo(22),
          reason: 'o pool roda antes de repetir');
      final primeiraDeNovo = tiradas.indexWhere((c) => c.origem == OrigemCarta.deNovo);
      expect(tiradas.take(primeiraDeNovo).where((c) => c.origem == OrigemCarta.nova).length, greaterThanOrEqualTo(20));
    });

    test('o estender não repete as que já saíram nesta fase (portais do Turismo)', () {
      final pool = _pool(30);
      final b = BaralhoFases(rnd: Random(16), reenfileirarNaFase: true);
      final d = b.abrirFase(fase: 1, pool: pool, tamanho: 6);
      for (var i = 0; i < 6; i++) {
        b.proxima(); // os 6 portais, antes de qualquer um ser passado
      }
      final gas = [for (var i = 0; i < 10; i++) b.proxima().palavra];
      expect(gas.where(d.palavras.contains), isEmpty);
      expect(gas.toSet().length, 10);
    });
  });

  group('reenfileirar na fase', () {
    test('a que caiu volta 3–5 tiradas depois como errou, no máximo 2 vezes por fase', () {
      for (var s = 0; s < 10; s++) {
        final b = BaralhoFases(rnd: Random(s), reenfileirarNaFase: true);
        b.abrirFase(fase: 1, pool: _pool(40), tamanho: 16);
        final alvo = b.proxima().palavra;
        b.proxima();
        var voltas = 0;
        b.registrar(alvo, perdeu: true);
        var desde = 0;
        for (var i = 0; i < 25; i++) {
          final c = b.proxima();
          desde++;
          if (c.palavra == alvo) {
            expect(c.origem, OrigemCarta.errou);
            expect(c.revisao, isTrue);
            expect(desde, inInclusiveRange(BaralhoFases.atrasoMin, BaralhoFases.atrasoMax),
                reason: 'semente $s');
            voltas++;
            desde = 0;
            b.registrar(alvo, erros: 2);
          }
        }
        expect(voltas, BaralhoFases.maxReenfileirarPorFase, reason: 'semente $s');
      }
    });

    test('1 erro não reenfileira; outra fase zera a conta', () {
      final b = BaralhoFases(rnd: Random(1), reenfileirarNaFase: true);
      final pool = _pool(60);
      b.abrirFase(fase: 1, pool: pool, tamanho: 10);
      final w = b.proxima().palavra;
      b.registrar(w, erros: 1);
      final depois = [for (var i = 0; i < 12; i++) b.proxima().palavra];
      expect(depois, isNot(contains(w)));
      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 10);
      expect(d2.ehRevisao(w), isTrue, reason: 'mas volta como revisão na fase seguinte');
    });

    test('no Rali (sem reenfileirar) não volta na mesma fase', () {
      final b = BaralhoFases(rnd: Random(1));
      b.abrirFase(fase: 1, pool: _pool(60), tamanho: 20);
      final w = b.proxima().palavra;
      b.registrar(w, perdeu: true);
      expect([for (var i = 0; i < 15; i++) b.proxima().palavra], isNot(contains(w)));
    });
  });

  group('estender, nível com palavras na tela, alcance do Rali e 2ª saída do Turismo', () {
    test('estender com o pool todo já usado: roda pela menos recente e respeita evitar e inicial', () {
      // (no dart2js o `1 << 62` da sentinela dava 0: só alternava pool[0]/pool[1] e ignorava o evitar)
      final pool = ['big', 'dog', 'map', 'red', 'sun', 'cat'];
      final b = BaralhoFases(rnd: Random(3), reenfileirarNaFase: true);
      final d = b.abrirFase(fase: 1, pool: pool, tamanho: 6);
      for (final w in d.palavras) {
        expect(b.proxima().palavra, w);
        b.registrar(w);
      }
      final depois = [for (var i = 0; i < 12; i++) b.proxima().palavra];
      expect(depois.take(6).toSet(), pool.toSet(), reason: 'as 6 rodam antes de alguma repetir: $depois');
      expect(depois.sublist(6), depois.take(6).toList(), reason: 'a menos recente primeiro');
      for (var i = 0; i < 30; i++) {
        final evitar = {pool[i % 6], pool[(i + 1) % 6]};
        final c = b.proxima(evitar: evitar, outraInicialQue: pool[(i + 2) % 6]);
        expect(evitar, isNot(contains(c.palavra)));
        expect(c.palavra[0], isNot(pool[(i + 2) % 6][0]));
        expect(c.origem, OrigemCarta.deNovo);
      }
    });

    test('emJogo: as que ainda caem do nível anterior não entram como novas do nível seguinte', () {
      final v = VocabularioJogo(
        curtas: [for (var i = 0; i < 30; i++) 'c$i'],
        medias: [for (var i = 0; i < 30; i++) 'medio$i'],
        longas: const <String>[],
      );
      final b = BaralhoFases(rnd: Random(1), reenfileirarNaFase: true);
      final d1 = b.abrirFase(fase: 1, pool: BaralhoFases.poolChuva(v, 1), tamanho: 8);
      // nasceram 8, 5 explodiram e 3 ainda caem quando o nível sobe
      final saidas = [for (var i = 0; i < 8; i++) b.proxima().palavra];
      expect(saidas, d1.palavras);
      for (final w in saidas.take(5)) {
        b.registrar(w);
      }
      final naTela = saidas.skip(5).toSet();
      final d2 = b.abrirFase(fase: 2, pool: BaralhoFases.poolChuva(v, 2), tamanho: 10, emJogo: naTela);
      expect(d2.palavras.toSet().intersection(naTela), isEmpty, reason: '$d2');
      expect(d2.novas, 10);
      expect(d2.resumo(), '10 palavras · 10 novas');
      // explodem já no nível 2: não renascem como "nova" segundos depois
      for (final w in naTela) {
        b.registrar(w);
      }
      final nivel2 = [for (var i = 0; i < 10; i++) b.proxima(evitar: const {}).palavra];
      expect(nivel2.toSet().intersection(naTela), isEmpty);
      expect(nivel2.toSet().intersection(saidas.toSet()), isEmpty);
    });

    test('alcance (Rali): ~35% das cartas que a pessoa digita, espalhadas por esse trecho', () {
      final pool = _pool(80);
      final b = BaralhoFases(rnd: Random(4));
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 12, alcance: BaralhoFases.alcanceRali(1));
      expect(d1.resumo(), 'até 12 palavras · 12 novas', reason: 'a fase pode fechar antes do fim');
      for (var i = 0; i < 8; i++) {
        b.registrar(d1.palavras[i], erros: i < 5 ? 1 : 0);
      }
      final alcance = BaralhoFases.alcanceRali(2);
      expect(alcance, 10);
      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 14, alcance: alcance);
      expect(d2.revisar, 4, reason: '5 candidatas, teto round(.35 × 10) = 4');
      expect(d2.resumo(), 'até 14 palavras · 10 novas · 4 pra revisar 🔁');
      final pos = [for (var i = 0; i < d2.cartas.length; i++) if (d2.cartas[i].revisao) i];
      expect(pos, [2, 4, 6, 8], reason: 'dentro das 10 primeiras, nunca a 1ª, nunca seguidas');
      expect(_revisoesEspacadas(d2), isTrue);
      // uma revisão só: no meio do trecho, não colada na largada
      final b2 = BaralhoFases(rnd: Random(4));
      final e1 = b2.abrirFase(fase: 1, pool: pool, tamanho: 12, alcance: 8);
      b2.registrar(e1.palavras.first, erros: 2);
      final e2 = b2.abrirFase(fase: 2, pool: pool, tamanho: 14, alcance: 10);
      expect([for (var i = 0; i < 14; i++) if (e2.cartas[i].revisao) i], [5]);
      // sem alcance: o de sempre (1 nova / 1 revisão na frente)
      final b3 = BaralhoFases(rnd: Random(4));
      final f1 = b3.abrirFase(fase: 1, pool: pool, tamanho: 12);
      b3.registrar(f1.palavras.first, erros: 2);
      final f2 = b3.abrirFase(fase: 2, pool: pool, tamanho: 14);
      expect([for (var i = 0; i < 14; i++) if (f2.cartas[i].revisao) i], [1]);
      expect(f2.resumo(), '14 palavras · 13 novas · 1 pra revisar 🔁');
    });

    test('proximaExtra (2ª saída): fora da fila, sem repetir as que ainda vão sair, outra inicial', () {
      final pool = _pool(60);
      final b = BaralhoFases(rnd: Random(8), reenfileirarNaFase: true);
      final d = b.abrirFase(fase: 1, pool: pool, tamanho: 10);
      final saidas = <String>[];
      for (var i = 0; i < 10; i++) {
        final c1 = b.proxima();
        expect(c1.palavra, d.palavras[i], reason: 'a fila segue na ordem');
        final c2 = b.proximaExtra(outraInicialQue: c1.palavra);
        expect(d.palavras, isNot(contains(c2.palavra)), reason: 'de fora do baralho da fase');
        expect(c2.palavra[0], isNot(c1.palavra[0]));
        expect(c2.revisao, isFalse);
        saidas.addAll([c1.palavra, c2.palavra]);
      }
      expect(saidas.toSet(), hasLength(20), reason: 'nenhuma palavra em dois portais');
      // pool pequeno (tudo na fila): cai no proxima, mas a inicial continua valendo
      final b2 = BaralhoFases(rnd: Random(0));
      b2.abrirFase(fase: 1, pool: ['cat', 'dog', 'cow'], tamanho: 3);
      final c = b2.proximaExtra(outraInicialQue: 'car');
      expect(c.palavra, 'dog');
    });

    test('devolver: a revisão pulada (a outra saída) volta 3–5 tiradas depois, no máximo 2 vezes', () {
      final pool = _pool(60);
      final b = BaralhoFases(rnd: Random(9), reenfileirarNaFase: true);
      final d1 = b.abrirFase(fase: 1, pool: pool, tamanho: 6);
      final w = d1.palavras.first;
      b.registrar(w, erros: 1);
      final d2 = b.abrirFase(fase: 2, pool: pool, tamanho: 8);
      expect(d2.ehRevisao(w), isTrue);
      for (var i = 0; i < 8; i++) {
        b.proxima(); // os portais
      }
      b.devolver(w); // escolheu a outra saída
      var tiradas = 0;
      CartaFase? c;
      while (tiradas < 8) {
        c = b.proxima();
        tiradas++;
        if (c.palavra == w) break;
      }
      expect(c!.palavra, w);
      expect(c.revisao, isTrue);
      expect(tiradas, inInclusiveRange(BaralhoFases.atrasoMin, BaralhoFases.atrasoMax));
      b.devolver(w);
      b.devolver(w); // já na fila: não duplica
      final voltas = [for (var i = 0; i < 12; i++) b.proxima().palavra].where((x) => x == w).length;
      expect(voltas, 1);
      b.devolver(w); // a 3ª na fase: não volta mais
      expect([for (var i = 0; i < 12; i++) b.proxima().palavra], isNot(contains(w)));
      // pular não conta como vista: continua candidata na fase seguinte
      final d3 = b.abrirFase(fase: 3, pool: pool, tamanho: 8);
      expect(d3.ehRevisao(w), isTrue);
    });
  });

  test('determinismo: mesma semente e mesmas chamadas = mesmos baralhos', () {
    List<Object> rodar() {
      final pool = _pool(50);
      final b = BaralhoFases(rnd: Random(77), dificeis: ['bw1', 'cw2'], reenfileirarNaFase: true);
      final saida = <Object>[];
      for (var f = 1; f <= 4; f++) {
        final d = b.abrirFase(fase: f, pool: pool.take(20 + 10 * f).toList(), tamanho: BaralhoFases.tamanhoChuva(f));
        saida.add(d.cartas.map((c) => '$c').join(','));
        for (var i = 0; i < 12; i++) {
          final c = b.proxima();
          saida.add('$c');
          b.registrar(c.palavra, erros: i % 4 == 0 ? 2 : 0, perdeu: i % 7 == 0, msPorLetra: 100.0 + (i * 37) % 300);
        }
      }
      saida.add(b.pendentes().join(','));
      return saida;
    }

    expect(rodar(), rodar());
  });

  test('resumo: plural, singular e sem revisão', () {
    DeckFase deck(List<OrigemCarta> os) =>
        DeckFase(1, [for (var i = 0; i < os.length; i++) CartaFase('w$i', os[i])]);
    expect(
        deck([...List.filled(9, OrigemCarta.nova), ...List.filled(5, OrigemCarta.errou)]).resumo(),
        '14 palavras · 9 novas · 5 pra revisar 🔁');
    expect(deck(List.filled(12, OrigemCarta.nova)).resumo(), '12 palavras · 12 novas');
    expect(deck([...List.filled(8, OrigemCarta.deNovo), ...List.filled(4, OrigemCarta.lenta)]).resumo(),
        '12 palavras · 4 pra revisar 🔁');
    expect(deck(List.filled(12, OrigemCarta.deNovo)).resumo(), '12 palavras · todas já vistas');
    expect(deck([OrigemCarta.nova, OrigemCarta.dificil]).resumo(), '2 palavras · 1 nova · 1 pra revisar 🔁');
    expect(deck([OrigemCarta.foco]).resumo(), '1 palavra · 1 pra revisar 🔁');
    expect(OrigemCarta.values.where((o) => o.revisao),
        [OrigemCarta.foco, OrigemCarta.errou, OrigemCarta.lenta, OrigemCarta.dificil]);
  });

  group('CronometroPalavra', () {
    test('sem as pausas; null se nunca começou; divide por letras − 1', () {
      var agora = 1000;
      final c = CronometroPalavra(agoraMs: () => agora);
      expect(c.msPorLetra('house'), isNull);
      expect(c.rodando, isFalse);
      c.iniciar();
      expect(c.rodando, isTrue);
      agora += 300;
      c.iniciar(); // já contando: nada
      agora += 100;
      c.pausar();
      agora += 5000; // pausa não conta
      c.pausar();
      expect(c.rodando, isTrue);
      c.retomar();
      agora += 400;
      expect(c.msPorLetra('house'), 800 / 4);
      expect(c.rodando, isFalse);
      expect(c.msPorLetra('house'), isNull, reason: 'zerou');
      c.iniciar();
      agora += 50;
      expect(c.msPorLetra('a'), 50, reason: 'uma letra: divide por 1');
      c.iniciar();
      agora += 50;
      c.zerar();
      expect(c.msPorLetra('ab'), isNull);
      c.retomar(); // parado: nada
      expect(c.rodando, isFalse);
    });
  });

  group('cola com o banco', () {
    testWidgets('dificeisDoBanco: teimosas primeiro, só as do pool; lentas no enviar mexem pouco na carga',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      const dic = Dicionario({
        'tea': 'chá', 'milk': 'leite', 'cake': 'bolo', 'bread': 'pão', 'apple': 'maçã', 'juice': 'suco',
        'rice': 'arroz', 'soup': 'sopa', 'fish': 'peixe', 'cheese': 'queijo', 'lunch': 'almoço',
      });
      final trilhas = [
        const Trilha(nivel: 'T1', emoji: '🍽️', etapa: 'A1', licoes: [
          Licao(nome: 'Comida', emoji: '🍞', id: 't1.l1', trechos: [
            Trecho(cod: 'Tea, milk, cake and bread.', dica: 'Chá, leite, bolo e pão.', out: ''),
            Trecho(cod: 'Apple juice, rice, soup and fish.', dica: 'Suco de maçã, arroz, sopa e peixe.', out: ''),
            Trecho(cod: 'Cheese for lunch.', dica: 'Queijo no almoço.', out: ''),
          ]),
        ]),
      ];
      final cubit = PalavrasCubit(repo: MemoriaPalavrasRepository(), carregarDicionario: () async => dic);
      await tester.runAsync(() async {
        await cubit.carregar();
        await cubit.prepararIndice(trilhas);
      });
      // teimosas: cake e bread (erradas de vez 2x numa lição); fish errada 3x nos jogos (fraca)
      cubit.registrarErros([
        for (final w in ['cake', 'bread'])
          for (var i = 0; i < 2; i++) EvidenciaPalavra(chave: w, peso: 1, falha: 1, fonte: FonteErro.licao),
      ]);
      cubit.registrarJogo({'fish': (0, 3)}, falhas: {'fish': 0});
      cubit.registrarJogo({'soup': (0, 1)}, falhas: {'soup': 0}); // 1 erro só: não é fraca
      expect(BancoArcade.dificeisDoBanco(null, _en), isEmpty);
      const v = VocabularioJogo(
        curtas: ['Fish', 'tea', 'soup', 'Cake', 'cake'],
        medias: ['cheese'],
        longas: ['strawberry'],
      );
      final ds = BancoArcade.dificeisDoBanco(cubit, v);
      expect(ds.toSet(), {'Cake', 'Fish'}, reason: 'bread fora do pool; cake uma vez só');
      expect(ds.first, 'Cake', reason: 'teimosa antes de fraca');
      expect(BancoArcade.dificeisDoBanco(cubit, v, max: 1), ['Cake']);

      // lentas: só um empurrãozinho na carga, sem mexer nos erros e sem criar palavra
      final cargaAntes = cubit.state.banco['soup']!.cargaErro;
      final errosAntes = cubit.state.banco['soup']!.errosJogo;
      PlacarPalavras()
        ..viu('soup')
        ..viu('milk')
        ..enviar(cubit, fonte: FonteErro.chuva, lentas: {'soup', 'milk'});
      final p = cubit.state.banco['soup']!;
      expect(p.errosJogo, errosAntes);
      expect(p.cargaErro - cargaAntes, closeTo(.5 * BaralhoFases.falhaLenta, .02));
      expect(cubit.state.banco['milk'], isNull, reason: 'lenta sozinha não cria palavra no banco');

      // sem lentas e sem tropeços: o caminho de sempre (erros/2)
      final antesFish = cubit.state.banco['fish']!.cargaErro;
      PlacarPalavras()
        ..viu('fish')
        ..errou('fish')
        ..enviar(cubit, lentas: {'tea'});
      expect(cubit.state.banco['fish']!.cargaErro, greaterThan(antesFish + .2));

      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await cubit.gravacoes;
        await cubit.close();
      });
    });
  });

  group('widgets', () {
    testWidgets('LinhaFase e MarcaRevisao em 360px, claro e escuro', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      for (final b in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(MediaQuery(
          data: MediaQueryData(size: const Size(360, 640), platformBrightness: b),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(children: [
              LinhaFase.naContagem('Fase 12 · 20 palavras · 13 novas · 7 pra revisar 🔁 — e um texto bem comprido'),
              const Positioned(top: 10, left: 10, child: MarcaRevisao(rotulo: 'REVISÃO')),
              const Positioned(top: 40, left: 10, child: MarcaRevisao()),
            ]),
          ),
        ));
        expect(tester.takeException(), isNull);
        expect(find.byKey(const Key('fase-intro')), findsOneWidget);
        expect(find.text('REVISÃO'), findsOneWidget);
        expect(find.text('🔁'), findsNWidgets(2));
        expect(tester.getSize(find.byKey(const Key('fase-intro'))).width, lessThanOrEqualTo(340));
      }
    });
  });

  tearDown(() => Linguagem.atual = Linguagem.dart);
}
