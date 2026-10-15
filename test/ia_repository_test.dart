import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/ia/data/cache_explicacoes.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FirestoreSemRede extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw Exception('sem rede');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalCotaRepository', () {
    test('vazio, ida e volta e dono diferente', () async {
      expect(await LocalCotaRepository().carregar(), CotaIa.vazia);
      await LocalCotaRepository(uid: 'ana').salvar(const CotaIa(dia: 5, usos: 3));
      expect(await LocalCotaRepository(uid: 'ana').carregar(), const CotaIa(dia: 5, usos: 3));
      expect(await LocalCotaRepository(uid: 'beto').carregar(), CotaIa.vazia);
    });

    test('JSON corrompido vira cota vazia, sem lançar', () async {
      for (final lixo in ['{x', '[1]', '"t"', '']) {
        SharedPreferences.setMockInitialValues({'ia_cota_v1': lixo});
        expect(await LocalCotaRepository().carregar(), CotaIa.vazia, reason: lixo);
      }
    });
  });

  group('FirestoreCotaRepository', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());
    FirestoreCotaRepository repo([String uid = 'u1']) => FirestoreCotaRepository(uid, db: db);

    test('sem o campo (conta antiga): cota vazia e nada é escrito', () async {
      await db.collection('users').doc('u1').set({'concluidas': ['0:0']});
      expect(await repo().carregar(), CotaIa.vazia);
      expect((await db.collection('users').doc('u1').get()).data(), {'concluidas': ['0:0']});
    });

    test('salvar grava `ia_cota` SEM apagar os outros campos', () async {
      await db.collection('users').doc('u1').set({'concluidas': ['0:0'], 'recorde': 9, 'habito': {'seq': 3}});
      await repo().salvar(const CotaIa(dia: 7, usos: 4));
      final d = (await db.collection('users').doc('u1').get()).data()!;
      expect(d['concluidas'], ['0:0']);
      expect(d['recorde'], 9);
      expect(d['habito'], {'seq': 3});
      expect(CotaIa.fromJson(d['ia_cota']), const CotaIa(dia: 7, usos: 4));
    });

    test('outro aparelho vê a cota gasta; a mais gasta vence (não dá para "fugir" para a nuvem velha)', () async {
      await db.collection('users').doc('u1').set({'ia_cota': const CotaIa(dia: 7, usos: 12).toJson()});
      await LocalCotaRepository(uid: 'u1').salvar(const CotaIa(dia: 7, usos: 5));
      expect((await repo().carregar()).usos, 12);
      SharedPreferences.setMockInitialValues({});
      expect((await repo().carregar()).usos, 12);
    });

    test('estudou offline: carregar sobe o maior uso para a nuvem', () async {
      await db.collection('users').doc('u1').set({'ia_cota': const CotaIa(dia: 7, usos: 2).toJson()});
      await LocalCotaRepository(uid: 'u1').salvar(const CotaIa(dia: 7, usos: 9));
      expect((await repo().carregar()).usos, 9);
      expect(CotaIa.fromJson((await db.collection('users').doc('u1').get()).data()!['ia_cota']).usos, 9);
    });

    test('sem rede: salvar guarda no aparelho e avisa; carregar devolve o do aparelho', () async {
      final sr = FirestoreCotaRepository('u1', db: _FirestoreSemRede());
      await expectLater(sr.salvar(const CotaIa(dia: 7, usos: 3)), throwsException);
      expect((await sr.carregar()).usos, 3);
    });

    test('a exclusão da conta apaga a cota junto (é um campo de users/{uid})', () async {
      await db.collection('users').doc('u1').set({'concluidas': []});
      await repo().salvar(const CotaIa(dia: 7, usos: 3));
      await apagarDadosDoUsuario(db, 'u1');
      expect((await db.collection('users').doc('u1').get()).exists, isFalse);
    });
  });

  group('CacheExplicacoesLocal', () {
    test('lê o que gravou; chave desconhecida é null; por conta', () async {
      final c = CacheExplicacoesLocal(uid: 'ana');
      expect(await c.ler('k'), isNull);
      await c.gravar('k', 'texto');
      expect(await c.ler('k'), 'texto');
      expect(await CacheExplicacoesLocal(uid: 'beto').ler('k'), isNull);
    });

    test('texto vazio não é guardado', () async {
      final c = CacheExplicacoesLocal();
      await c.gravar('k', '');
      expect(await c.ler('k'), isNull);
    });

    test('guarda no máximo 100: a MAIS ANTIGA sai (e reler/regravar renova)', () async {
      final c = CacheExplicacoesLocal();
      for (var i = 0; i < 100; i++) {
        await c.gravar('k$i', 't$i');
      }
      await c.gravar('k0', 'novo0'); // renova a mais antiga
      await c.gravar('k100', 't100'); // estoura: sai a k1, não a k0
      expect(await c.ler('k0'), 'novo0');
      expect(await c.ler('k1'), isNull);
      expect(await c.ler('k2'), 't2');
      expect(await c.ler('k100'), 't100');
    });

    test('cache corrompido vira vazio e continua funcionando', () async {
      for (final lixo in ['{x', '[1]', '"t"', '{"itens":3,"ordem":"a"}']) {
        SharedPreferences.setMockInitialValues({'ia_cache_v1': lixo});
        final c = CacheExplicacoesLocal();
        expect(await c.ler('k'), isNull, reason: lixo);
        await c.gravar('k', 'ok');
        expect(await c.ler('k'), 'ok', reason: lixo);
      }
    });
  });
}
