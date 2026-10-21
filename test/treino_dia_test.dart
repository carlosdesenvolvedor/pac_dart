import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/treino_dia/domain/montar_plano.dart';
import 'package:pac_dart/features/treino_dia/domain/plano_treino.dart';

/// "⚡ Treino do dia" — o domínio puro (plano FASE-9 §5 e §5.1).
const _dia = 20000;
const _ms = 1700000000000;

PlanoTreino _plano(List<BlocoTreino> blocos,
        {String curso = 'ingles', int dia = _dia, bool incompleto = false, bool bonus = false, int ms = _ms}) =>
    PlanoTreino(
      dia: dia,
      curso: curso,
      blocos: blocos,
      curto: PlanoTreino.curtoDe(blocos),
      incompleto: incompleto,
      bonus: bonus,
      editadoEm: ms,
    );

const _rev = BlocoTreino(id: 'revisao', tipo: TipoBloco.revisao, qtd: 8, qtd2: 4, minutos: 5);
const _pal = BlocoTreino(id: 'palavras', tipo: TipoBloco.palavras, qtd: 6, minutos: 2);
const _ouv = BlocoTreino(id: 'ouvir', tipo: TipoBloco.ouvir, qtd: 6);
const _rali = BlocoTreino(id: 'rali', tipo: TipoBloco.rali, minutos: 2);
BlocoTreino _quiz(int t, int l) => BlocoTreino(id: 'quiz:$t:$l', tipo: TipoBloco.quiz, qtd: 10, minutos: 4, t: t, l: l);

PlanoTreino _ingles() => _plano(const [_rev, _pal, _ouv, _rali]);

/// Marca vários blocos de uma vez.
PlanoTreino _com(PlanoTreino p, Map<String, (EstadoBloco, int, bool)> marcas) {
  for (final MapEntry(key: id, value: (e, r, z)) in marcas.entries) {
    p = p.marcar(id, e, resultado: r, vazio: z, agoraMs: p.editadoEm + 1);
  }
  return p;
}

const _f = EstadoBloco.feito, _p = EstadoBloco.pulado;

List<String> _ids(PlanoTreino p) => [for (final b in p.blocos) b.id];

void main() {
  group('montarPlano', () {
    PlanoTreino montar(FontesTreino f, [String curso = 'ingles']) =>
        montarPlano(f, dia: _dia, curso: curso, agoraMs: _ms);

    test('inglês completo → 4 etapas na ordem, com os limites', () {
      final p = montar(const FontesTreino(
        ingles: true,
        frasesDevidas: 12,
        cartoes: 9,
        teimosas: 9,
        palavrasDevidas: 3,
        palavrasFracas: 20,
        temOuvir: true,
      ));
      expect(_ids(p), ['revisao', 'palavras', 'ouvir', 'rali']);
      final rev = p.blocos[0];
      expect((rev.qtd, rev.qtd2, rev.minutos), (8, 4, 4), reason: '(8*25 + 4*10)/60 = 4 min');
      expect(p.blocos[1].qtd, 6, reason: 'teimosas (9) limitadas a 6');
      expect((p.blocos[2].qtd, p.blocos[2].minutos), (6, 1));
      expect(p.blocos[3].minutos, 2);
      expect(p.curto, isFalse);
      expect(p.incompleto, isFalse);
      expect((p.dia, p.curso, p.editadoEm), (_dia, 'ingles', _ms));
      expect(p.minutos, rev.minutos + 2 + 1 + 2);
    });

    test('só cartões invertidos → revisao com qtd 0 e qtd2 n', () {
      final p = montar(const FontesTreino(ingles: true, cartoes: 3, temOuvir: true));
      expect(_ids(p), ['revisao', 'ouvir', 'rali']);
      expect((p.blocos[0].qtd, p.blocos[0].qtd2, p.blocos[0].minutos), (0, 3, 1));
    });

    test('sem teimosas mas com palavras devidas → palavras (a 1ª fonte não vazia)', () {
      final p = montar(const FontesTreino(ingles: true, palavrasDevidas: 4, palavrasFracas: 30));
      expect(_ids(p), ['palavras', 'rali']);
      expect(p.blocos[0].qtd, 4);
      final so = montar(const FontesTreino(ingles: true, palavrasFracas: 30));
      expect(so.blocos[0].qtd, 6, reason: 'fracas também respeitam o limite');
    });

    test('inglês novo (nada estudado) → [ouvir, rali], curto', () {
      final p = montar(const FontesTreino(ingles: true, temOuvir: true));
      expect(_ids(p), ['ouvir', 'rali']);
      expect(p.curto, isTrue);
    });

    test('sem OuvirCubit → nenhuma etapa de ouvir', () {
      final p = montar(const FontesTreino(ingles: true, frasesDevidas: 2));
      expect(_ids(p), ['revisao', 'rali']);
    });

    test('Dart com 3 candidatas → [quiz, quiz, rali]', () {
      final p = montar(const FontesTreino(quizes: [(0, 3), (1, 0), (0, 1)]), 'dart');
      expect(_ids(p), ['quiz:0:3', 'quiz:1:0', 'rali']);
      final q = p.blocos.first;
      expect((q.t, q.l, q.qtd, q.minutos), (0, 3, 10, 4));
      expect(p.curto, isFalse);
    });

    test('Dart novo → [rali], curto (e nunca um ouvir, mesmo com temOuvir)', () {
      final p = montar(const FontesTreino(temOuvir: true, frasesDevidas: 5), 'dart');
      expect(_ids(p), ['rali']);
      expect(p.curto, isTrue);
    });

    test('fontes incompletas → plano incompleto', () {
      expect(montar(const FontesTreino(ingles: true, incompleta: true)).incompleto, isTrue);
    });
  });

  group('completarPlano', () {
    test('incompleto [ouvir, rali] + frases vencendo → [revisao, ouvir, rali], curto e incompleto limpos', () {
      final p = montarPlano(const FontesTreino(ingles: true, temOuvir: true, incompleta: true),
          dia: _dia, curso: 'ingles', agoraMs: _ms);
      expect((p.curto, p.incompleto), (true, true));
      final novo = completarPlano(p, const FontesTreino(ingles: true, temOuvir: true, frasesDevidas: 3),
          agoraMs: _ms + 5);
      expect(_ids(novo), ['revisao', 'ouvir', 'rali']);
      expect((novo.curto, novo.incompleto, novo.editadoEm), (false, false, _ms + 5));
    });

    test('fontes ainda incompletas: entra o que já há, e o plano segue incompleto', () {
      final p = _plano(const [_ouv, _rali], incompleto: true);
      final novo = completarPlano(p, const FontesTreino(ingles: true, palavrasFracas: 2, incompleta: true), agoraMs: _ms);
      expect(_ids(novo), ['palavras', 'ouvir', 'rali']);
      expect(novo.incompleto, isTrue);
    });

    test('etapas passivas já resolvidas mantêm o estado', () {
      final p = _com(_plano(const [_ouv, _rali], incompleto: true), {'ouvir': (_f, 6, false)});
      final novo = completarPlano(p, const FontesTreino(ingles: true, frasesDevidas: 3, teimosas: 2), agoraMs: _ms);
      expect(_ids(novo), ['revisao', 'palavras', 'ouvir', 'rali']);
      expect(novo.blocos[2].estado, EstadoBloco.feito);
      expect(novo.blocos[2].resultado, 6);
      expect(novo.proximo!.id, 'revisao');
    });

    test('nada muda quando uma etapa ativa já foi resolvida', () {
      final p = _com(_plano(const [_pal, _ouv, _rali], incompleto: true), {'palavras': (_p, 0, false)});
      final novo = completarPlano(p, const FontesTreino(ingles: true, frasesDevidas: 3), agoraMs: _ms + 9);
      expect(novo, same(p));
    });

    test('nada novo e já completo → o mesmo plano (não regrava)', () {
      final p = _ingles();
      expect(completarPlano(p, const FontesTreino(ingles: true, frasesDevidas: 1, teimosas: 1), agoraMs: _ms + 1),
          same(p));
    });

    test('curto já concluído + fontes que cresceram depois (lição nova) → o mesmo plano: segue feito', () {
      final p = _com(montarPlano(const FontesTreino(ingles: true, temOuvir: true), dia: _dia, curso: 'ingles', agoraMs: _ms),
          {'ouvir': (_p, 0, false), 'rali': (_f, 50, false)});
      expect((p.curto, p.concluido, p.situacao), (true, true, SituacaoTreino.concluido));
      const cresceu = FontesTreino(ingles: true, temOuvir: true, frasesDevidas: 4, palavrasFracas: 3);
      expect(completarPlano(p, cresceu, agoraMs: _ms + 9), same(p));
      expect(p.completar(const [_rev, _pal], fontesCompletas: true, agoraMs: _ms + 9), same(p));
      expect(p.merecebonus, isFalse);
    });

    test('Dart: quizzes novos só até o limite de 2', () {
      final p = _plano([_quiz(0, 0), _rali], curso: 'dart', incompleto: true);
      final novo = completarPlano(p, const FontesTreino(quizes: [(0, 0), (1, 1), (2, 2)]), agoraMs: _ms);
      expect(_ids(novo), ['quiz:1:1', 'quiz:0:0', 'rali']);
    });
  });

  group('escolherQuizes', () {
    test('sem nota primeiro, depois a menor nota; respeita temQuiz e max', () {
      final notas = {(0, 0): 9, (0, 1): 4, (0, 2): null, (1, 0): 7, (1, 1): 4};
      final r = escolherQuizes(
        concluidas: notas.keys.toList(),
        nota: (t, l) => notas[(t, l)],
        temQuiz: (t, l) => (t, l) != (1, 0),
        dia: _dia,
        max: 4,
      );
      expect(r.first, (0, 2), reason: 'nunca fez o quiz');
      expect(r.sublist(1, 3).toSet(), {(0, 1), (1, 1)}, reason: 'as notas 4, em ordem do dia');
      expect(r.last, (0, 0), reason: '(1,0) não tem quiz; resta a nota 9');
      expect(escolherQuizes(concluidas: notas.keys.toList(), nota: (t, l) => notas[(t, l)], temQuiz: (_, _) => true, dia: _dia),
          hasLength(2), reason: 'max padrão = 2');
    });

    test('temQuiz só é chamado até achar max (é caro)', () {
      final concluidas = [for (var l = 0; l < 30; l++) (0, l)];
      final chamadas = <(int, int)>[];
      final r = escolherQuizes(
        concluidas: concluidas,
        nota: (t, l) => l, // a lição 0 tem a menor nota
        temQuiz: (t, l) {
          chamadas.add((t, l));
          return l != 1;
        },
        dia: _dia,
      );
      expect(r, [(0, 0), (0, 2)]);
      expect(chamadas, [(0, 0), (0, 1), (0, 2)]);
    });

    test('a nota vem do callback por (t,l) — nunca de chaves de texto', () {
      final pedidas = <(int, int)>[];
      escolherQuizes(
        concluidas: const [(2, 5), (3, 1)],
        nota: (t, l) {
          pedidas.add((t, l));
          return null;
        },
        temQuiz: (_, _) => true,
        dia: _dia,
      );
      expect(pedidas.toSet(), {(2, 5), (3, 1)});
    });

    test('os empates giram com o dia (e cada dia é estável)', () {
      final concluidas = [for (var l = 0; l < 8; l++) (0, l)];
      List<(int, int)> doDia(int d) =>
          escolherQuizes(concluidas: concluidas, nota: (_, _) => null, temQuiz: (_, _) => true, dia: d, max: 8);
      expect(doDia(_dia), doDia(_dia));
      final ordens = {for (var d = 0; d < 7; d++) doDia(_dia + d).toString()};
      expect(ordens.length, greaterThan(3), reason: 'a semana não repete sempre as mesmas lições');
      expect(doDia(_dia).toSet(), concluidas.toSet());
    });

    test('com a nota relativa (‰), um 6/6 perfeito fica depois de um 7/8', () {
      // o lerFontes passa acertos em ‰ do tamanho do quiz: 6/6 → 1000, 7/8 → 875, 4/10 → 400
      final permil = {(0, 0): 1000, (0, 1): 875, (0, 2): 400};
      expect(
          escolherQuizes(
              concluidas: permil.keys.toList(), nota: (t, l) => permil[(t, l)], temQuiz: (_, _) => true, dia: _dia, max: 3),
          [(0, 2), (0, 1), (0, 0)]);
    });

    test('lista vazia, max 0 e repetidas', () {
      expect(escolherQuizes(concluidas: const [], nota: (_, _) => null, temQuiz: (_, _) => true, dia: 1), isEmpty);
      expect(escolherQuizes(concluidas: const [(0, 0)], nota: (_, _) => null, temQuiz: (_, _) => true, dia: 1, max: 0),
          isEmpty);
      expect(
          escolherQuizes(
              concluidas: const [(0, 0), (0, 0), (0, 1)], nota: (_, _) => null, temQuiz: (_, _) => true, dia: 1, max: 5),
          hasLength(2));
    });
  });

  group('marcar, proximo, situacao, concluido', () {
    test('o caminho de um treino', () {
      var p = _ingles();
      expect(p.situacao, SituacaoTreino.pendente);
      expect(p.proximo!.id, 'revisao');
      expect((p.resolvidos, p.feitos, p.concluido), (0, 0, false));

      p = p.marcar('revisao', _f, resultado: 7, agoraMs: _ms + 1);
      expect(p.situacao, SituacaoTreino.emAndamento);
      expect(p.proximo!.id, 'palavras');
      expect(p.blocos.first.resultado, 7);
      expect(p.editadoEm, _ms + 1);
      expect(p.algumAtivoResolvido, isTrue);

      p = p.marcar('palavras', _p, agoraMs: _ms + 2);
      p = p.marcar('ouvir', _f, resultado: 6, agoraMs: _ms + 3);
      expect(p.proximo!.id, 'rali');
      p = p.marcar('rali', _f, resultado: 120, agoraMs: _ms + 4);
      expect(p.concluido, isTrue);
      expect(p.situacao, SituacaoTreino.concluido);
      expect(p.proximo, isNull);
      expect((p.resolvidos, p.feitos), (4, 3));
    });

    test('vazio: feito mas não conta em feitos', () {
      final p = _ingles().marcar('revisao', _f, resultado: 0, vazio: true, agoraMs: _ms);
      expect(p.blocos.first.resolvido, isTrue);
      expect(p.blocos.first.vazio, isTrue);
      expect(p.feitos, 0);
    });

    test('voltar a pendente (ouvir de novo) e quiz com total', () {
      var p = _plano([_quiz(0, 1), _rali], curso: 'dart');
      p = p.marcar('quiz:0:1', _f, resultado: 7, total: 10, agoraMs: _ms);
      expect((p.blocos.first.resultado, p.blocos.first.total), (7, 10));
      p = p.marcar('quiz:0:1', EstadoBloco.pendente, agoraMs: _ms);
      expect(p.blocos.first.estado, EstadoBloco.pendente);
    });

    test('id desconhecido ou nada a mudar → o mesmo plano', () {
      final p = _ingles();
      expect(p.marcar('nada', _f, agoraMs: _ms + 1), same(p));
      expect(p.marcar('rali', EstadoBloco.pendente, agoraMs: _ms + 1), same(p));
    });

    test('plano sem blocos nunca está concluído', () {
      expect(_plano(const []).concluido, isFalse);
      expect(_plano(const []).situacao, SituacaoTreino.pendente);
    });
  });

  group('merecebonus', () {
    test('tudo pulado → não; bônus já passado → não', () {
      final pulado = _com(_ingles(), {for (final id in ['revisao', 'palavras', 'ouvir', 'rali']) id: (_p, 0, false)});
      expect(pulado.concluido, isTrue);
      expect(pulado.merecebonus, isFalse);
      final ok = _com(_ingles(), {
        'revisao': (_f, 3, false),
        'palavras': (_f, 6, false),
        'ouvir': (_p, 0, false),
        'rali': (_p, 0, false),
      });
      expect(ok.merecebonus, isTrue);
      expect(ok.comBonus(agoraMs: _ms).merecebonus, isFalse);
      expect(ok.comBonus(agoraMs: _ms).bonus, isTrue);
    });

    test('inglês 2 de 4 com revisão feita (3) → sim', () {
      final p = _com(_ingles(), {
        'revisao': (_f, 3, false),
        'palavras': (_p, 0, false),
        'ouvir': (_f, 6, false),
        'rali': (_p, 0, false),
      });
      expect(p.feitos, 2);
      expect(p.merecebonus, isTrue);
    });

    test('ainda não concluído → não', () {
      final p = _com(_ingles(), {'revisao': (_f, 3, false), 'palavras': (_f, 3, false)});
      expect(p.merecebonus, isFalse);
    });

    test('(a) Dart novo [rali], rali feito (fase perdida) → não (curto)', () {
      final p = _com(_plano(const [_rali], curso: 'dart'), {'rali': (_f, 0, false)});
      expect(p.curto, isTrue);
      expect(p.merecebonus, isFalse);
    });

    test('(b) inglês: revisão e palavras vazias, ouvir e rali pulados → não', () {
      final p = _com(_ingles(), {
        'revisao': (_f, 0, true),
        'palavras': (_f, 0, true),
        'ouvir': (_p, 0, false),
        'rali': (_p, 0, false),
      });
      expect(p.merecebonus, isFalse);
    });

    test('(c) inglês: ouvir + rali feitos, revisão e palavras puladas → não', () {
      final p = _com(_ingles(), {
        'revisao': (_p, 0, false),
        'palavras': (_p, 0, false),
        'ouvir': (_f, 6, false),
        'rali': (_f, 300, false),
      });
      expect(p.feitos, 2);
      expect(p.merecebonus, isFalse);
    });

    test('etapa ativa feita com resultado 0 → não', () {
      final p = _com(_ingles(), {
        'revisao': (_f, 0, false),
        'palavras': (_p, 0, false),
        'ouvir': (_f, 6, false),
        'rali': (_f, 10, false),
      });
      expect(p.merecebonus, isFalse);
    });

    test('incompleto → não', () {
      final p = _com(_plano(const [_rev, _pal, _rali], incompleto: true), {
        'revisao': (_f, 3, false),
        'palavras': (_f, 3, false),
        'rali': (_f, 10, false),
      });
      expect(p.merecebonus, isFalse);
    });

    test('Dart [quiz, quiz, rali] com um quiz feito (7/10) e o rali feito → sim', () {
      var p = _plano([_quiz(0, 1), _quiz(1, 2), _rali], curso: 'dart');
      p = p.marcar('quiz:0:1', _f, resultado: 7, total: 10, agoraMs: _ms);
      p = p.marcar('quiz:1:2', _p, agoraMs: _ms);
      p = p.marcar('rali', _f, resultado: 0, agoraMs: _ms);
      expect(p.merecebonus, isTrue);
    });
  });

  group('anotarOuvir / anotarFoco', () {
    test('sem repetidas, sem vazias, e com teto', () {
      var p = _ingles().anotarOuvir(['a', 'b', 'a', ''], agoraMs: _ms + 1);
      expect(p.ouvirChaves, ['a', 'b']);
      expect(p.editadoEm, _ms + 1);
      p = p.anotarOuvir([for (var i = 0; i < 10; i++) 'x$i'], agoraMs: _ms + 2);
      expect(p.ouvirChaves, ['a', 'b', 'x0', 'x1', 'x2', 'x3']);
      expect(p.anotarOuvir(['a'], agoraMs: _ms + 3), same(p), reason: 'nada novo: o mesmo plano');

      var f = _ingles().anotarFoco([for (var i = 0; i < 20; i++) 'w${i % 15}'], agoraMs: _ms);
      expect(f.palavrasFoco, hasLength(12));
      expect(f.palavrasFoco.first, 'w0');
      f = f.anotarFoco(['w0', 'nova'], agoraMs: _ms);
      expect(f.palavrasFoco, hasLength(12), reason: 'cheio: a nova não entra');
    });
  });

  group('JSON', () {
    test('ida e volta; padrões dos blocos ficam de fora; as chaves de cima estão SEMPRE lá', () {
      final p = _com(_ingles(), {'revisao': (_f, 0, true), 'palavras': (_p, 0, false)})
          .anotarOuvir(['f1'], agoraMs: _ms)
          .anotarFoco(['cat'], agoraMs: _ms);
      final j = jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>;
      expect(j.keys.toSet(), {'v', 'd', 'c', 'b', 'o', 'f', 'k', 'p', 'x', 'm'});
      expect((j['k'], j['p'], j['x']), (false, false, false));
      final blocos = (j['b'] as List).cast<Map<String, dynamic>>();
      expect(blocos.first, {'i': 'revisao', 'y': 'revisao', 'e': 'feito', 'q': 8, 'q2': 4, 'm': 5, 'z': true});
      expect(blocos.last, {'i': 'rali', 'y': 'rali', 'm': 2});
      expect(blocos[2], {'i': 'ouvir', 'y': 'ouvir', 'q': 6});
      expect(PlanoTreino.fromJson(j), p);
      expect(PlanoTreino.fromJson(j)!.blocos.first.vazio, isTrue);

      final dart = _com(_plano([_quiz(0, 1), _rali], curso: 'dart', bonus: true, incompleto: true), {});
      final dj = jsonDecode(jsonEncode(dart.marcar('quiz:0:1', _f, resultado: 7, total: 10, agoraMs: _ms).toJson()));
      expect((dj['b'] as List).first, {'i': 'quiz:0:1', 'y': 'quiz', 'e': 'feito', 'q': 10, 'm': 4, 'r': 7, 'n': 10, 't': 0, 'l': 1});
      expect(PlanoTreino.fromJson(dj)!.blocos.first.total, 10);
      expect((dj['k'], dj['p'], dj['x']), (false, true, true));
    });

    test('um mapa vindo do Firestore (Map<dynamic, dynamic>) também serve', () {
      final j = <dynamic, dynamic>{
        'v': 1,
        'd': _dia,
        'c': 'csharp',
        'b': <dynamic>[
          <dynamic, dynamic>{'i': 'rali', 'y': 'rali', 'm': 2.0}
        ],
        'o': <dynamic>[],
        'f': <dynamic>[],
        'k': true,
        'p': false,
        'x': false,
        'm': _ms,
      };
      final p = PlanoTreino.fromJson(j)!;
      expect(p.blocos.single.minutos, 2);
      expect(p.curto, isTrue);
    });

    test('nenhuma etapa aproveitável (lixo, só tipos novos, lista vazia) → null: monta um plano novo', () {
      for (final b in <Object?>[
        <Object?>[],
        [
          {'i': 'x', 'y': 'novoTipo'},
          'lixo',
        ],
        [
          {'i': 'jogo', 'y': 'turismo'},
          {'y': 'rali'},
        ],
      ]) {
        expect(PlanoTreino.fromJson({'v': 1, 'd': _dia, 'c': 'ingles', 'b': b, 'k': false}), isNull, reason: '$b');
      }
      // uma que se aproveite já basta
      expect(
          PlanoTreino.fromJson({
            'v': 1,
            'd': _dia,
            'c': 'ingles',
            'b': [
              {'i': 'x', 'y': 'novoTipo'},
              {'i': 'rali', 'y': 'rali'},
            ],
          })!
              .blocos
              .single
              .id,
          'rali');
    });

    test('lixo, v:2 e tipo desconhecido não lançam', () {
      for (final lixo in <Object?>[null, 1, 'x', <Object?>[], <String, Object?>{}, {'v': 2, 'd': 1, 'c': 'dart', 'b': []}]) {
        expect(PlanoTreino.fromJson(lixo), isNull, reason: '$lixo');
      }
      expect(PlanoTreino.fromJson({'v': 1, 'c': 'dart', 'b': []}), isNull, reason: 'sem dia');
      expect(PlanoTreino.fromJson({'v': 1, 'd': 3, 'c': 'dart', 'b': 'x'}), isNull, reason: 'blocos não é lista');

      final p = PlanoTreino.fromJson({
        'v': 1,
        'd': 3,
        'c': 'ingles',
        'b': [
          {'i': 'jogo', 'y': 'turismo'},
          {'i': 'rali', 'y': 'rali', 'e': 'quebrado', 'q': 'x', 'r': -5},
          {'y': 'ouvir'},
          'lixo',
          {'i': 'rali', 'y': 'rali', 'e': 'feito'},
        ],
        'o': ['a', 3, null, 'a'],
        'f': 'nada',
        'k': 'sim',
        'm': 'ontem',
      })!;
      expect(_ids(p), ['rali'], reason: 'tipo desconhecido, sem id e repetido caem fora');
      expect(p.blocos.single.estado, EstadoBloco.pendente);
      expect((p.blocos.single.qtd, p.blocos.single.resultado), (0, 0));
      expect(p.ouvirChaves, ['a']);
      expect(p.palavrasFoco, isEmpty);
      expect((p.curto, p.bonus, p.editadoEm), (false, false, 0));
    });

    test('BlocoTreino.fromJson sozinho', () {
      expect(BlocoTreino.fromJson(null), isNull);
      expect(BlocoTreino.fromJson({'i': 'x', 'y': 'nada'}), isNull);
      expect(BlocoTreino.fromJson(_quiz(2, 3).toJson()), _quiz(2, 3));
    });
  });

  group('mesclar', () {
    void comutativa(PlanoTreino? a, PlanoTreino? b, void Function(PlanoTreino? r) confere) {
      final ab = PlanoTreino.mesclar(a, b), ba = PlanoTreino.mesclar(b, a);
      expect(ab, ba, reason: 'comutativa');
      confere(ab);
    }

    test('lados nulos', () {
      final p = _ingles();
      expect(PlanoTreino.mesclar(null, null), isNull);
      expect(PlanoTreino.mesclar(p, null), p);
      expect(PlanoTreino.mesclar(null, p), p);
      expect(PlanoTreino.mesclar(p, p), p, reason: 'idempotente');
    });

    test('dia mais novo vence', () {
      final ontem = _com(_plano(const [_rev, _rali], dia: _dia - 1, ms: _ms + 999), {'revisao': (_f, 3, false)});
      final hoje = _ingles();
      comutativa(ontem, hoje, (r) => expect(r, hoje));
    });

    test('cursos diferentes → a', () {
      final a = _ingles(), b = _plano(const [_rali], curso: 'dart');
      expect(PlanoTreino.mesclar(a, b), a);
      expect(PlanoTreino.mesclar(b, a), b);
    });

    test('mesmo dia: união das etapas — feito > pulado > pendente, maior resultado, vazio de quem venceu', () {
      final a = _com(_ingles(), {
        'revisao': (_f, 3, false),
        'palavras': (_p, 0, false),
      }).anotarOuvir(['f1', 'f2'], agoraMs: _ms + 10);
      final b = _com(_ingles(), {
        'revisao': (_f, 5, false),
        'palavras': (_f, 0, true),
        'ouvir': (_p, 0, false),
      }).anotarOuvir(['f2', 'f3'], agoraMs: _ms + 5).anotarFoco(['cat'], agoraMs: _ms + 5);
      comutativa(a, b, (r) {
        final porId = {for (final x in r!.blocos) x.id: x};
        expect(_ids(r), ['revisao', 'palavras', 'ouvir', 'rali']);
        expect((porId['revisao']!.estado, porId['revisao']!.resultado), (_f, 5));
        expect(porId['palavras']!.estado, _f, reason: 'feito vence pulado');
        expect(porId['palavras']!.vazio, isTrue, reason: 'o vazio vem do lado cujo estado venceu');
        expect(porId['ouvir']!.estado, _p, reason: 'pulado vence pendente');
        expect(porId['rali']!.estado, EstadoBloco.pendente);
        expect(r.ouvirChaves.toSet(), {'f1', 'f2', 'f3'});
        expect(r.palavrasFoco, ['cat']);
        expect(r.editadoEm, greaterThanOrEqualTo(_ms + 10));
      });
    });

    test('mesmo estado: só fica vazio se os dois forem', () {
      final a = _com(_ingles(), {'revisao': (_f, 0, true)});
      final b = _com(_ingles(), {'revisao': (_f, 4, false)});
      comutativa(a, b, (r) => expect((r!.blocos.first.vazio, r.blocos.first.resultado), (false, 4)));
    });

    test('bonus OU, incompleto E', () {
      final a = _plano(const [_rev, _rali], bonus: true, incompleto: true);
      final b = _plano(const [_rev, _rali], ms: _ms + 1);
      comutativa(a, b, (r) => expect((r!.bonus, r.incompleto), (true, false)));
      final c = _plano(const [_rev, _rali], incompleto: true, ms: _ms + 1);
      comutativa(a, c, (r) => expect(r!.incompleto, isTrue));
    });

    test('etapas só do outro lado (um completar lá) entram se a base não resolveu ativa nenhuma', () {
      // aparelho A: montou incompleto e já ouviu; aparelho B: completou o plano com a revisão
      final a = _com(_plano(const [_ouv, _rali], incompleto: true), {'ouvir': (_f, 6, false)});
      final b = completarPlano(_plano(const [_ouv, _rali], incompleto: true),
          const FontesTreino(ingles: true, temOuvir: true, frasesDevidas: 3), agoraMs: _ms + 50);
      comutativa(a, b, (r) {
        expect(_ids(r!), ['revisao', 'ouvir', 'rali']);
        expect(r.blocos[1].estado, _f);
        expect(r.curto, isFalse, reason: 'recalculado');
        expect(r.incompleto, isFalse);
      });
    });

    test('a base já resolveu uma ativa: as etapas só do outro lado ficam de fora', () {
      final a = _com(_plano(const [_pal, _rali]), {'palavras': (_f, 4, false)});
      final b = _plano(const [_rev, _pal, _rali], ms: _ms + 100);
      comutativa(a, b, (r) => expect(_ids(r!), ['palavras', 'rali']));
    });

    test('empate em tudo menos o conteúdo ainda é comutativa', () {
      final a = _plano(const [_rev, _rali]);
      final b = _plano(const [_pal, _rali]);
      comutativa(a, b, (r) => expect(r, isNotNull));
    });
  });
}
