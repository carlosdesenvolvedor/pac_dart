// Onde moram as setlists do "🎧 Ouvir": no aparelho (en_setlists_{uid}) e na nuvem
// (users/{uid}/setlists/v1, campo b), com mescla e falhas da nuvem engolidas.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Um Firestore sem rede (ou com a regra ainda não publicada): qualquer acesso falha.
class _FirestoreSemRede extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw Exception('sem rede');
}

ItemSetlist _item(String id, String ref) => ItemSetlist(id: id, tipo: TipoItem.licao, ref: ref, rotulo: ref, criadoEm: 1);

/// Um banco com setlists de nome → editadoEm.
BancoSetlists _banco(Map<String, int> setlists, {String u = ''}) => BancoSetlists(porId: {
      for (final e in setlists.entries)
        e.key: Setlist(id: e.key, nome: e.key, criadoEm: 1, editadoEm: e.value, itens: [_item('i-${e.key}', 'l.${e.key}')]),
    }, ultimaUsada: u);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('MemoriaSetlistsRepository: ida e volta e conta as gravações', () async {
    final repo = MemoriaSetlistsRepository();
    expect(await repo.carregar(), const BancoSetlists());
    await repo.salvar(_banco({'a': 1}));
    expect(await repo.carregar(), _banco({'a': 1}));
    expect(repo.salvos, 1);
    expect(await MemoriaSetlistsRepository(_banco({'b': 2})).carregar(), _banco({'b': 2}));
  });

  group('LocalSetlistsRepository', () {
    test('vazio, ida e volta, na chave en_setlists_{uid}; dono diferente não vê', () async {
      final repo = LocalSetlistsRepository('ana');
      expect(await repo.carregar(), const BancoSetlists());
      await repo.salvar(_banco({'onibus': 5}, u: 'onibus'));
      expect(await LocalSetlistsRepository('ana').carregar(), _banco({'onibus': 5}, u: 'onibus'));
      expect(await LocalSetlistsRepository('beto').carregar(), const BancoSetlists());
      final p = await SharedPreferences.getInstance();
      expect(p.getString('en_setlists_ana'), isNotNull);
    });

    test('lixo gravado vira vazio', () async {
      SharedPreferences.setMockInitialValues({'en_setlists_u1': '{quebrado'});
      expect(await LocalSetlistsRepository('u1').carregar(), const BancoSetlists());
    });
  });

  group('FirestoreSetlistsRepository', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());
    DocumentReference<Map<String, dynamic>> doc(String uid) => db.collection('users').doc(uid).collection('setlists').doc('v1');
    BancoSetlists naNuvem(Map<String, dynamic>? d) => BancoSetlists.fromJsonString(d?['b'] as String?);

    test('salva no aparelho primeiro e na nuvem, no doc users/{uid}/setlists/v1 (campo b)', () async {
      final repo = FirestoreSetlistsRepository('u1', db: db);
      await repo.salvar(_banco({'a': 1}));
      final nuvem = (await doc('u1').get()).data()!;
      expect(nuvem.keys, ['b']);
      expect(naNuvem(nuvem).porId.keys, ['a']);
      expect((await LocalSetlistsRepository('u1').carregar()).porId.keys, ['a']);
      // outro aparelho (vazio) recebe da nuvem, e a cópia local desce
      SharedPreferences.setMockInitialValues({});
      expect((await FirestoreSetlistsRepository('u1', db: db).carregar()).porId.keys, ['a']);
      expect((await LocalSetlistsRepository('u1').carregar()).porId.keys, ['a'], reason: 'a cópia local desce');
    });

    test('carregar mescla aparelho × nuvem e iguala os dois lados', () async {
      await LocalSetlistsRepository('u1').salvar(_banco({'a': 5, 'so-aqui': 1}, u: 'so-aqui'));
      await doc('u1').set({'b': BancoSetlists(porId: {
        ..._banco({'so-la': 1}).porId,
        'a': const Setlist(id: 'a', nome: 'nuvem mais nova', criadoEm: 1, editadoEm: 9),
      }).toJsonString()});
      final junto = await FirestoreSetlistsRepository('u1', db: db).carregar();
      expect(junto.porId.keys.toSet(), {'a', 'so-aqui', 'so-la'});
      expect(junto.porId['a']!.nome, 'nuvem mais nova');
      expect(junto.ultimaUsada, 'so-aqui');
      expect(naNuvem((await doc('u1').get()).data()).porId, junto.porId);
      expect(await LocalSetlistsRepository('u1').carregar(), junto);
    });

    test('salvar JUNTA com a nuvem: dois aparelhos não apagam as setlists/lápides um do outro', () async {
      final celular = FirestoreSetlistsRepository('u1', db: db, local: MemoriaSetlistsRepository());
      final webLocal = MemoriaSetlistsRepository();
      final web = FirestoreSetlistsRepository('u1', db: db, local: webLocal);
      await celular.salvar(_banco({'a': 1, 'b': 1}));
      final naWeb = await web.carregar(); // a web abre agora (a e b)
      // o celular apaga a b e cria a c
      var noCelular = await celular.carregar();
      // (relógio de verdade: lápide com data antiga seria podada ao gravar)
      noCelular = noCelular.apagar('b', agora: DateTime.now().millisecondsSinceEpoch);
      noCelular = BancoSetlists(porId: {...noCelular.porId, ..._banco({'c': 6}).porId});
      await celular.salvar(noCelular);
      // a web (com o banco velho na memória) cria a d e grava
      await web.salvar(BancoSetlists(porId: {...naWeb.porId, ..._banco({'d': 7}).porId}));
      final nuvem = naNuvem((await doc('u1').get()).data());
      expect(nuvem.porId.keys.toSet(), {'a', 'b', 'c', 'd'});
      expect(nuvem.porId['b']!.apagada, isTrue, reason: 'a lápide do celular não some');
      expect(webLocal.banco.porId, nuvem.porId, reason: 'o aparelho fica com a mescla');
    });

    test('nuvem fora do ar (ou regra ausente): carrega e salva no aparelho, sem lançar', () async {
      final repo = FirestoreSetlistsRepository('u1', db: _FirestoreSemRede());
      await repo.salvar(_banco({'a': 1}));
      expect((await repo.carregar()).porId.keys, ['a']);
    });

    test('doc quebrado na nuvem não derruba: vale o aparelho', () async {
      await LocalSetlistsRepository('u1').salvar(_banco({'a': 1}));
      await doc('u1').set({'b': '{lixo'});
      expect((await FirestoreSetlistsRepository('u1', db: db).carregar()).porId.keys, ['a']);
    });
  });

  test('apagarDadosDoUsuario leva users/{uid}/setlists junto; o outro usuário fica', () async {
    final db = FakeFirebaseFirestore();
    for (final uid in ['u1', 'u2']) {
      await db.collection('users').doc(uid).set({'concluidas': []});
      await FirestoreSetlistsRepository(uid, db: db, local: MemoriaSetlistsRepository()).salvar(_banco({'a': 1}));
    }
    await apagarDadosDoUsuario(db, 'u1');
    expect((await db.collection('users').doc('u1').collection('setlists').get()).docs, isEmpty);
    expect((await db.collection('users').doc('u2').collection('setlists').get()).docs, hasLength(1));
  });
}
