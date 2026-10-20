// Os tropeços de uma partida (teimosas no Arcade do inglês): quando vale o aviso "escapou 2x", o limite
// de avisos por partida, o resumo que vai para o banco — e a contabilidade do Turismo (sem sorteio).
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/tropecos.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';

void main() {
  group('TropecosDoJogo', () {
    test('o aviso sai com soma ≥ 1,5 em 2+ ocorrências — e uma vez só', () {
      final t = TropecosDoJogo(agoraMs: () => 0);
      t.falha('through', 1);
      expect(t.aviso('through'), isNull, reason: '1 ocorrência (soma 1)');
      t.falha('through', .5);
      expect(t.aviso('through'), 'through', reason: 'soma 1,5 em 2 ocorrências');
      t.falha('through', 1);
      expect(t.aviso('through'), isNull, reason: 'já avisada nesta partida');

      final u = TropecosDoJogo(agoraMs: () => 0);
      u
        ..falha('enough', .5)
        ..falha('enough', .5);
      expect(u.aviso('enough'), isNull, reason: '2 ocorrências mas soma 1');
      u.falha('enough', .5);
      expect(u.aviso('enough'), 'enough');

      final v = TropecosDoJogo(agoraMs: () => 0)..falha('because', 2);
      expect(v.aviso('because'), isNull, reason: 'uma ocorrência só vale até 1');
      v.falha('because', 0);
      expect(v.aviso('because'), isNull, reason: 'ocorrência limpa não conta');
      expect(v.vezes('because'), 1);
    });

    test('no máximo 2 avisos por partida, 30 s entre eles; pode:false segura', () {
      var agora = 0;
      final t = TropecosDoJogo(agoraMs: () => agora);
      for (final w in ['a1', 'b2', 'c3']) {
        t
          ..falha(w, 1)
          ..falha(w, 1);
      }
      expect(t.aviso('a1', pode: false), isNull, reason: 'largada/pausa');
      expect(t.aviso('a1'), 'a1');
      agora = 10000;
      expect(t.aviso('b2'), isNull, reason: 'só 10 s depois do último');
      agora = 30000;
      expect(t.aviso('b2'), 'b2');
      agora = 120000;
      expect(t.aviso('c3'), isNull, reason: 'já foram 2 nesta partida');
    });

    test('stats, falhas (teto 1) e difíceis em ordem', () {
      final t = TropecosDoJogo(agoraMs: () => 0)
        ..vista('apple')
        ..vista('apple')
        ..falha('apple', .34)
        ..falha('bread', 1)
        ..falha('bread', 1)
        ..falha('cake', .5)
        ..falha('milk', .5)
        ..falha('milk', .5);
      expect(t.stats, {'apple': (2, 1), 'bread': (0, 2), 'cake': (0, 1), 'milk': (0, 2)});
      expect(t.falhas, {'apple': closeTo(.34, 1e-9), 'bread': 1.0, 'cake': .5, 'milk': 1.0});
      expect(t.somas['bread'], 2.0, reason: 'a soma da sessão não tem teto (a oferta compara com 1,5)');
      expect(t.dificeis(), ['bread', 'milk']);
      expect(t.dificeis(min: .3), ['bread', 'milk', 'cake', 'apple']);
      expect(t.vezes('bread'), 2);
      expect(t.vezes('fish'), 0);
      expect(TropecosDoJogo().vazio, isTrue);
    });
  });

  group('TurismoEngine.perdas', () {
    final v = VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles));
    final pista = pistasGt[0];
    TurismoEngine motor() => TurismoEngine(pista: pista, rnd: Random(3), vocabulario: pista.vocabularioCom(v));

    test('tecla errada na palavra travada: +0,34 quando a tentativa termina', () {
      final e = motor();
      final w = e.portais.first.palavras.first;
      expect(e.teclar(w[0]), TeclaGt.avancou);
      expect(e.teclar('#'), TeclaGt.errou);
      expect(e.perdas, isEmpty, reason: 'só conta quando a tentativa acaba');
      for (final ch in w.substring(1).split('')) {
        e.teclar(ch);
      }
      expect(e.portais.first.livre, isTrue);
      expect(e.perdas[w], closeTo(.34, 1e-9));
      expect(e.ultimaPerdida, w);
    });

    test('portal perdido com a palavra travada vale 1; sem travar, nada', () {
      final e = motor();
      final p0 = e.portais.first;
      final w = p0.palavras.first;
      e.teclar(w[0]);
      while (!p0.passado) {
        e.velocidade = e.velMax;
        e.tick(.05);
      }
      expect(e.perdas, {w: 1.0});

      final f = motor();
      while (!f.portais.first.passado) {
        f.velocidade = f.velMax;
        f.tick(.05);
      }
      expect(f.perdas, isEmpty, reason: 'portal perdido sem palavra travada não acusa ninguém');
    });

    test('a contabilidade não mexe no sorteio: a mesma semente faz a mesma pista e as mesmas palavras', () {
      final a = motor(), b = motor();
      final w = a.portais.first.palavras.first;
      a
        ..teclar(w[0])
        ..teclar('#');
      expect([for (final p in a.portais) p.palavras], [for (final p in b.portais) p.palavras]);
      expect([for (final s in a.segmentos) s.curva], [for (final s in b.segmentos) s.curva]);
    });
  });
}
