// O banco de setlists do "🎧 Ouvir": itens (refs + retrato), operações imutáveis, limites, JSON curto
// tolerante e a mescla aparelho × nuvem (a edição mais nova ganha; no empate, a lápide).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';

const _f1 = Trecho(cod: 'Hi! How are you?', dica: 'Oi! Tudo <b>bem</b>?', out: '', id: 'f-1a', quem: 'mike');
const _f2 = Trecho(cod: "I'm fine, thanks.", dica: 'Tô bem, valeu.', out: '', id: 'f-2b', quem: 'voce');
const _f3 = Trecho(cod: 'Nice to meet you.', dica: 'Prazer.', out: '', id: 'f-3c', quem: 'mike');
const _licao = Licao(nome: 'Oi, tudo bem?', emoji: '👋', id: 'primeiro-contato.oi-tudo-bem', trechos: [_f1, _f2, _f3]);
const _trilha = Trilha(nivel: 'Primeiro contato', emoji: '🤝', etapa: 'A1 · Fundação', licoes: [_licao]);

ItemSetlist _item(String id, {String ref = 'x', TipoItem tipo = TipoItem.licao, int c = 1}) =>
    ItemSetlist(id: id, tipo: tipo, ref: ref, rotulo: ref, criadoEm: c);

/// Um banco com uma setlist e os itens dados (em ordem).
(BancoSetlists, String) _com(List<ItemSetlist> itens, {int agora = 100}) {
  var (b, id) = const BancoSetlists().criar('Ônibus', agora: agora);
  for (final i in itens) {
    b = b.adicionar(id, i, agora: agora).$1;
  }
  return (b, id);
}

void main() {
  group('ItemSetlist', () {
    test('codigoEtapa: o código antes do "·"', () {
      expect(ItemSetlist.codigoEtapa('A1 · Fundação'), 'A1');
      expect(ItemSetlist.codigoEtapa('DEV · Inglês para devs'), 'DEV');
      expect(ItemSetlist.codigoEtapa('B2'), 'B2');
      expect(ItemSetlist.codigoEtapa(''), '');
    });

    test('fábricas: refs, rótulos e o retrato da frase', () {
      final f = ItemSetlist.daFrase(_f1, licao: _licao);
      expect(f.tipo, TipoItem.frase);
      expect(f.ref, 'f-1a');
      expect(f.licaoId, _licao.id);
      expect(f.en, 'Hi! How are you?');
      expect(f.pt, 'Oi! Tudo bem?', reason: 'sem as tags');
      expect(f.rotulo, '“Hi! How are you?”');
      expect(f.id, startsWith('i'));

      final t = ItemSetlist.daTexto(en: 'See you later.', pt: 'Até mais.');
      expect(t.tipo, TipoItem.frase);
      expect(t.ref, Revisao.chave('See you later.'));
      expect(t.en, 'See you later.');

      expect(ItemSetlist.daLicao(_licao).ref, _licao.id);
      expect(ItemSetlist.daTrilha(_trilha).ref, 'tr:primeiro-contato');
      expect(ItemSetlist.daTrilha(_trilha).rotulo, 'Unidade: Primeiro contato');
      final e = ItemSetlist.daEtapa('A1 · Fundação');
      expect((e.tipo, e.ref, e.rotulo), (TipoItem.etapa, 'A1', 'Etapa A1'));
      final c = ItemSetlist.doCurso();
      expect((c.tipo, c.ref, c.rotulo), (TipoItem.curso, '', 'Curso inteiro'));
      expect(ItemSetlist.daLicao(_licao).id, isNot(ItemSetlist.daLicao(_licao).id), reason: 'ids novos');
    });

    test('doTrecho: 1 frase → frase; todas → lição; senão → trecho, na ordem da lição', () {
      expect(ItemSetlist.doTrecho(_licao, [_f2]).tipo, TipoItem.frase);
      expect(ItemSetlist.doTrecho(_licao, [_f2]).ref, 'f-2b');
      expect(ItemSetlist.doTrecho(_licao, [_f3, _f1, _f2]).tipo, TipoItem.licao);
      final t = ItemSetlist.doTrecho(_licao, [_f3, _f1, _f3]);
      expect(t.tipo, TipoItem.trecho);
      expect(t.ref, _licao.id);
      expect(t.licaoId, _licao.id);
      expect(t.chaves, ['f-1a', 'f-3c'], reason: 'ordem da lição, sem repetir');
      expect(t.rotulo, 'Oi, tudo bem? · 2 frases');
      expect(ItemSetlist.doTrecho(_licao, const []).tipo, TipoItem.licao, reason: 'nada escolhido → a lição');
      const fora = Trecho(cod: 'Other.', dica: '', out: '', id: 'f-zz');
      expect(ItemSetlist.doTrecho(_licao, [fora, _f1]).tipo, TipoItem.frase, reason: 'a de fora é ignorada');
    });

    test('assinatura: tipo|ref|chaves', () {
      expect(ItemSetlist.daFrase(_f1).assinatura, ItemSetlist.daFrase(_f1, licao: _licao).assinatura);
      expect(ItemSetlist.doTrecho(_licao, [_f1, _f3]).assinatura, 'trecho|${_licao.id}|f-1a,f-3c');
    });

    test('JSON curto e sem os vazios; ida e volta', () {
      final f = ItemSetlist.daFrase(_f3, licao: _licao);
      final j = f.toJson();
      expect(j.keys.toSet(), {'i', 't', 'r', 'l', 'n', 'en', 'pt', 'c'});
      expect(ItemSetlist.fromJson(jsonDecode(jsonEncode(j)) as Map<String, dynamic>), f);
      final c = ItemSetlist.doCurso();
      expect(c.toJson().keys.toSet(), {'i', 't', 'n', 'c'}, reason: 'ref vazia fica de fora');
      expect(ItemSetlist.fromJson(c.toJson()), c);
      final t = ItemSetlist.doTrecho(_licao, [_f1, _f2]);
      expect(t.toJson()['k'], ['f-1a', 'f-2b']);
      expect(ItemSetlist.fromJson(jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>), t);
    });

    test('fromJson: tipo desconhecido ou sem id lança (o banco descarta)', () {
      expect(() => ItemSetlist.fromJson({'i': 'a', 't': 'podcast', 'c': 1}), throwsFormatException);
      expect(() => ItemSetlist.fromJson({'t': 'licao'}), throwsFormatException);
      // campos de tipo errado não derrubam
      final i = ItemSetlist.fromJson({'i': 'a', 't': 'licao', 'r': 7, 'k': 'x', 'c': '12'});
      expect(i.ref, '');
      expect(i.chaves, isEmpty);
      expect(i.criadoEm, 12);
    });
  });

  group('BancoSetlists — operações', () {
    test('criar: id novo, nome aparado (vazio → "Minha setlist"), vira a última usada', () {
      final (b, id) = const BancoSetlists().criar('  Ônibus ', emoji: '🚌', agora: 5);
      expect(id, startsWith('s'));
      expect(b.porId[id]!.nome, 'Ônibus');
      expect(b.porId[id]!.emoji, '🚌');
      expect((b.porId[id]!.criadoEm, b.porId[id]!.editadoEm), (5, 5));
      expect(b.ultimaUsada, id);
      final (b2, id2) = b.criar('', agora: 6);
      expect(b2.porId[id2]!.nome, 'Minha setlist');
      expect(b2.visiveis.map((s) => s.id), [id2, id], reason: 'a mais nova primeiro');
    });

    test('criar além do limite não cria', () {
      var b = const BancoSetlists();
      for (var i = 0; i < BancoSetlists.maxSetlists; i++) {
        b = b.criar('s$i', agora: i).$1;
      }
      final (depois, id) = b.criar('mais uma', agora: 999);
      expect(id, '');
      expect(identical(depois, b), isTrue);
    });

    test('renomear e apagar (lápide sem itens; a última usada se solta)', () {
      var (b, id) = _com([_item('a')]);
      b = b.renomear(id, 'Academia', emoji: '🏋️', agora: 200);
      expect((b.porId[id]!.nome, b.porId[id]!.emoji, b.porId[id]!.editadoEm), ('Academia', '🏋️', 200));
      expect(identical(b.renomear(id, '  ', agora: 300), b), isTrue, reason: 'nome vazio não muda nada');
      b = b.apagar(id, agora: 400);
      expect(b.porId[id]!.apagada, isTrue);
      expect(b.porId[id]!.itens, isEmpty);
      expect(b.porId[id]!.editadoEm, 400);
      expect(b.visiveis, isEmpty);
      expect(b.ultimaUsada, '');
      expect(identical(b.renomear(id, 'x', agora: 500), b), isTrue, reason: 'apagada não volta por renomear');
    });

    test('adicionar: repetido → jaEstava; no limite de itens → cheia; setlist inexistente → cheia', () {
      var (b, id) = _com([]);
      final (b1, r1) = b.adicionar(id, ItemSetlist.daLicao(_licao), agora: 150);
      expect(r1, ResultadoAdicao.adicionado);
      expect(b1.porId[id]!.itens, hasLength(1));
      expect(b1.porId[id]!.editadoEm, 150);
      final (b2, r2) = b1.adicionar(id, ItemSetlist.daLicao(_licao), agora: 160);
      expect(r2, ResultadoAdicao.jaEstava, reason: 'mesma assinatura, outro id');
      expect(b2.porId[id]!.itens, hasLength(1));
      expect(b.adicionar('nao-existe', _item('z'), agora: 1).$2, ResultadoAdicao.cheia);

      b = b1;
      for (var i = 1; i < BancoSetlists.maxItens; i++) {
        b = b.adicionar(id, _item('i$i', ref: 'r$i'), agora: 170).$1;
      }
      expect(b.porId[id]!.itens, hasLength(BancoSetlists.maxItens));
      final (b3, r3) = b.adicionar(id, _item('extra', ref: 'extra'), agora: 180);
      expect(r3, ResultadoAdicao.cheia);
      expect(identical(b3, b), isTrue);
    });

    test('adicionar: o limite de bytes do documento → cheia', () {
      var (b, id) = _com([]);
      final grande = 'x' * 9000;
      ResultadoAdicao? r;
      for (var i = 0; i < 200 && r != ResultadoAdicao.cheia; i++) {
        final (nb, ri) = b.adicionar(
            id, ItemSetlist(id: 'i$i', tipo: TipoItem.frase, ref: 'k$i', rotulo: grande, en: grande, criadoEm: 1),
            agora: 1);
        b = nb;
        r = ri;
      }
      expect(r, ResultadoAdicao.cheia);
      expect(utf8.encode(b.toJsonString(agora: 1)).length, lessThanOrEqualTo(BancoSetlists.maxBytes));
    });

    test('adicionar ou já estar marca a última usada', () {
      var (b, a) = _com([_item('x1', ref: 'r1')]);
      final (b2, outra) = b.criar('Outra', agora: 101);
      expect(b2.ultimaUsada, outra);
      final (b3, r) = b2.adicionar(a, _item('x2', ref: 'r1'), agora: 102);
      expect(r, ResultadoAdicao.jaEstava);
      expect(b3.ultimaUsada, a);
      expect(b3.porId[a]!.editadoEm, 100, reason: 'já estar não é edição');
    });

    test('remover, restaurar (desfazer) e mover', () {
      var (b, id) = _com([_item('a', ref: 'A'), _item('b', ref: 'B'), _item('c', ref: 'C')]);
      List<String> ids(BancoSetlists x) => [for (final i in x.porId[id]!.itens) i.id];
      final b2 = b.remover(id, 'b', agora: 200);
      expect(ids(b2), ['a', 'c']);
      expect(b2.porId[id]!.editadoEm, 200);
      expect(identical(b2.remover(id, 'nada', agora: 201), b2), isTrue);
      final b3 = b2.restaurar(id, _item('b', ref: 'B'), 1, agora: 210);
      expect(ids(b3), ['a', 'b', 'c']);
      expect(identical(b3.restaurar(id, _item('b', ref: 'B'), 1, agora: 220), b3), isTrue, reason: 'já está');
      expect(ids(b2.restaurar(id, _item('b', ref: 'B'), 99, agora: 230)), ['a', 'c', 'b'], reason: 'índice limitado');

      expect(ids(b3.mover(id, 0, 2, agora: 300)), ['b', 'c', 'a']);
      expect(ids(b3.mover(id, 2, 0, agora: 300)), ['c', 'a', 'b']);
      expect(ids(b3.mover(id, 1, 9, agora: 300)), ['a', 'c', 'b']);
      expect(b3.mover(id, 0, 2, agora: 300).porId[id]!.editadoEm, 300);
      expect(identical(b3.mover(id, 1, 1, agora: 300), b3), isTrue);
      expect(identical(b3.mover(id, 7, 0, agora: 300), b3), isTrue);
    });

    test('usar só troca a última usada (não edita)', () {
      var (b, a) = _com([]);
      final (b2, outra) = b.criar('Outra', agora: 300);
      final b3 = b2.usar(a);
      expect(b3.ultimaUsada, a);
      expect(b3.porId, b2.porId);
      expect(identical(b3.usar('nao-existe'), b3), isTrue);
      expect(outra, isNotEmpty);
    });

    test('frasesAprox: conta exata nos itens pequenos, média nos grandes', () {
      final (b, id) = _com([
        ItemSetlist.daFrase(_f1),
        ItemSetlist.doTrecho(_licao, [_f1, _f2]),
        ItemSetlist.daLicao(_licao),
      ]);
      expect(b.porId[id]!.frasesAprox, 1 + 2 + 9);
    });
  });

  group('BancoSetlists — JSON', () {
    test('ida e volta com as chaves curtas; padrões ficam de fora; lápide grava i:[]', () {
      var (b, id) = _com([ItemSetlist.daFrase(_f1, licao: _licao), ItemSetlist.doTrecho(_licao, [_f1, _f3])]);
      final (b2, id2) = b.criar('Lixo', emoji: '🗑', agora: 120);
      b = b2.apagar(id2, agora: 130).usar(id);
      final txt = b.toJsonString(agora: 140);
      final j = jsonDecode(txt) as Map<String, dynamic>;
      expect(j['v'], 1);
      expect(j['u'], id);
      final s = (j['s'] as Map)[id] as Map;
      expect(s.keys.toSet(), {'n', 'c', 'm', 'i'}, reason: 'emoji 🎧 e x:false não vão');
      final lapide = (j['s'] as Map)[id2] as Map;
      expect(lapide['x'], true);
      expect(lapide['i'], isEmpty);
      final volta = BancoSetlists.fromJsonString(txt);
      expect(volta, b);
      expect(volta.porId[id]!.emoji, '🎧');
    });

    test('estragado ou desconhecido: banco vazio ou o item fora, nunca lança', () {
      for (final lixo in [null, '', '{quebrado', '[]', '42', '"x"', '{"s":7}']) {
        expect(BancoSetlists.fromJsonString(lixo), const BancoSetlists(), reason: '$lixo');
      }
      final txt = jsonEncode({
        'v': 9,
        'u': 's1',
        's': {
          's1': {
            'n': 'Boa',
            'c': 1,
            'm': 2,
            'i': [
              {'i': 'a', 't': 'licao', 'r': 'l1', 'c': 1},
              {'i': 'b', 't': 'podcast', 'r': 'x', 'c': 1},
              'lixo',
              {'t': 'frase'},
            ],
          },
          's2': 'não é mapa',
          '': {'n': 'sem id'},
        },
      });
      final b = BancoSetlists.fromJsonString(txt);
      expect(b.porId.keys, ['s1']);
      expect(b.porId['s1']!.itens.map((i) => i.id), ['a']);
      expect(b.ultimaUsada, 's1');
    });

    test('lápides com mais de 90 dias somem ao gravar; as novas ficam', () {
      const dia = Duration.millisecondsPerDay;
      const agora = 1000 * dia;
      var b = const BancoSetlists();
      final (b1, velha) = b.criar('Velha', agora: agora - 200 * dia);
      final (b2, nova) = b1.criar('Nova', agora: agora - 200 * dia);
      final (b3, viva) = b2.criar('Viva', agora: agora - 200 * dia);
      b = b3.apagar(velha, agora: agora - 91 * dia).apagar(nova, agora: agora - 89 * dia);
      final volta = BancoSetlists.fromJsonString(b.toJsonString(agora: agora));
      expect(volta.porId.keys.toSet(), {nova, viva});
      expect(volta.porId[nova]!.apagada, isTrue);
      expect(volta.porId[viva]!.apagada, isFalse, reason: 'setlist viva nunca é podada, por mais velha');
      expect(volta.podadoAte, agora - 91 * dia, reason: 'a marca da poda = a lápide podada mais nova');
      expect(jsonDecode(b.toJsonString(agora: agora))['p'], agora - 91 * dia);
      // sem poda nenhuma, a marca fica de fora do JSON (e a que já existia segue)
      expect(jsonDecode(volta.toJsonString(agora: agora)).containsKey('p'), isTrue);
      expect(jsonDecode(const BancoSetlists().toJsonString()).containsKey('p'), isFalse);
    });
  });

  group('BancoSetlists.mesclar', () {
    Setlist s(String id, int m, {bool x = false, String nome = 'n'}) =>
        Setlist(id: id, nome: nome, criadoEm: 1, editadoEm: m, apagada: x);
    BancoSetlists banco(List<Setlist> l, {String u = ''}) => BancoSetlists(porId: {for (final x in l) x.id: x}, ultimaUsada: u);

    test('a edição mais nova ganha, de qualquer lado; o que só existe de um lado fica', () {
      final r = BancoSetlists.mesclar(
        banco([s('a', 5, nome: 'local'), s('b', 3, nome: 'local'), s('so-local', 1)]),
        banco([s('a', 4, nome: 'nuvem'), s('b', 9, nome: 'nuvem'), s('so-nuvem', 1)]),
      );
      expect(r.porId['a']!.nome, 'local');
      expect(r.porId['b']!.nome, 'nuvem');
      expect(r.porId.keys.toSet(), {'a', 'b', 'so-local', 'so-nuvem'});
    });

    test('empate: a lápide ganha (dos dois lados)', () {
      expect(BancoSetlists.mesclar(banco([s('a', 5, x: true)]), banco([s('a', 5)])).porId['a']!.apagada, isTrue);
      expect(BancoSetlists.mesclar(banco([s('a', 5)]), banco([s('a', 5, x: true)])).porId['a']!.apagada, isTrue);
    });

    test('uma edição mais nova vence uma lápide velha (e vice-versa)', () {
      expect(BancoSetlists.mesclar(banco([s('a', 9)]), banco([s('a', 5, x: true)])).porId['a']!.apagada, isFalse);
      expect(BancoSetlists.mesclar(banco([s('a', 5)]), banco([s('a', 9, x: true)])).porId['a']!.apagada, isTrue);
    });

    test('ultimaUsada vem do aparelho; aparelho novo herda a da nuvem; apagada vira ""', () {
      expect(BancoSetlists.mesclar(banco([s('a', 1), s('b', 1)], u: 'a'), banco([s('b', 1)], u: 'b')).ultimaUsada, 'a');
      expect(BancoSetlists.mesclar(banco([]), banco([s('b', 1)], u: 'b')).ultimaUsada, 'b');
      expect(BancoSetlists.mesclar(banco([s('a', 1)], u: 'a'), banco([s('a', 2, x: true)])).ultimaUsada, '');
    });

    test('lápide podada não ressuscita: o aparelho parado há meses não traz de volta a setlist apagada', () {
      const dia = Duration.millisecondsPerDay;
      const agora = 1000 * dia;
      // o celular apagou a X (dia 800) e, passados os 90 dias, a lápide saiu da nuvem
      final nuvem = BancoSetlists.fromJsonString(
        banco([s('x', 800 * dia, x: true), s('y', 100 * dia)]).toJsonString(agora: agora),
      );
      expect(nuvem.porId.keys, ['y']);
      // o notebook não abria o app desde antes: ainda tem a X viva (e uma Z editada depois da poda, que fica)
      final notebook = banco([s('x', 700 * dia), s('y', 100 * dia), s('z', 850 * dia)], u: 'x');
      final r = BancoSetlists.mesclar(notebook, nuvem);
      expect(r.porId.keys.toSet(), {'y', 'z'});
      expect(r.ultimaUsada, '', reason: 'a última usada ficou de fora');
      expect(r.podadoAte, 800 * dia, reason: 'a marca segue no banco junto');
      // dos dois lados, e sem marca nada muda
      expect(BancoSetlists.mesclar(nuvem, notebook).porId.keys.toSet(), {'y', 'z'});
      expect(BancoSetlists.mesclar(notebook, banco([])).porId.keys.toSet(), {'x', 'y', 'z'});
    });

    test('mesclar com ele mesmo não muda nada', () {
      final (b, _) = _com([_item('a')]);
      expect(BancoSetlists.mesclar(b, b), b);
    });
  });

  test('chaveDaFrase das fábricas bate com a da revisão', () {
    const semId = Trecho(cod: 'From my text.', dica: 'Do meu texto.', out: '');
    expect(ItemSetlist.daFrase(semId).ref, chaveDaFrase(semId));
    expect(ItemSetlist.daFrase(semId).ref, ItemSetlist.daTexto(en: 'From my text.', pt: '').ref);
  });
}
