import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:shared_preferences/shared_preferences.dart';

Habito feito(int dias) {
  var h = Habito.vazio;
  for (var i = 0; i < dias; i++) {
    h = h.registrar(20, DateTime(2026, 10, 12 + i, 10));
  }
  return h;
}

/// Um Firestore sem rede: qualquer acesso falha.
class _FirestoreSemRede extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw Exception('sem rede');
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalHabitoRepository', () {
    test('sem nada gravado: o padrão', () async {
      expect(await LocalHabitoRepository().carregar(), Habito.vazio);
    });

    test('ida e volta, na chave habito_v1', () async {
      final repo = LocalHabitoRepository();
      await repo.salvar(feito(9));
      expect(await LocalHabitoRepository().carregar(), feito(9));
      final p = await SharedPreferences.getInstance();
      expect(p.getString('habito_v1'), isNotNull);
    });

    test('JSON corrompido volta ao padrão, sem lançar', () async {
      for (final lixo in ['{não é json', '[1,2,3]', '"texto"', '', 'null']) {
        SharedPreferences.setMockInitialValues({'habito_v1': lixo});
        expect(await LocalHabitoRepository().carregar(), Habito.vazio, reason: lixo);
      }
    });

    test('dono diferente, chave diferente (duas contas no mesmo aparelho não se misturam)', () async {
      await LocalHabitoRepository(uid: 'ana').salvar(feito(3));
      expect(await LocalHabitoRepository(uid: 'beto').carregar(), Habito.vazio);
      expect((await LocalHabitoRepository(uid: 'ana').carregar()).sequencia, 3);
    });
  });

  group('FirestoreHabitoRepository', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    FirestoreHabitoRepository repo([String uid = 'u1']) => FirestoreHabitoRepository(uid, db: db);

    test('documento sem `habito` (conta antiga) → padrão, e nada é escrito', () async {
      await db.collection('users').doc('u1').set({'concluidas': ['0:0']});
      expect(await repo().carregar(), Habito.vazio);
      expect((await db.collection('users').doc('u1').get()).data(), {'concluidas': ['0:0']});
    });

    test('conta que nem tem documento ainda → padrão', () async {
      expect(await repo().carregar(), Habito.vazio);
    });

    test('salvar grava o mapa em users/{uid}.habito SEM apagar os outros campos', () async {
      await db.collection('users').doc('u1').set({
        'concluidas': ['0:0', '0:1'],
        'recorde': 77,
        'quizNotas': {'0:0': 9},
      });
      await repo().salvar(feito(4));
      final dados = (await db.collection('users').doc('u1').get()).data()!;
      expect(dados['concluidas'], ['0:0', '0:1']);
      expect(dados['recorde'], 77);
      expect(dados['quizNotas'], {'0:0': 9});
      expect(dados['habito'], isA<Map>());
      expect((dados['habito'] as Map)['seq'], 4);
      expect(Habito.fromJson(dados['habito']), feito(4));
    });

    test('salvar duas vezes não duplica nem corrompe', () async {
      await repo().salvar(feito(2));
      await repo().salvar(feito(5));
      expect(await repo().carregar(), feito(5));
    });

    test('ida e volta pela nuvem (aparelho novo, sem cópia local)', () async {
      await repo().salvar(feito(6));
      SharedPreferences.setMockInitialValues({}); // outro aparelho
      expect(await repo().carregar(), feito(6));
    });

    test('carregar desce a nuvem para o aparelho quando a nuvem está adiantada', () async {
      await db.collection('users').doc('u1').set({'habito': feito(8).toJson()});
      expect(await repo().carregar(), feito(8));
      expect(await LocalHabitoRepository(uid: 'u1').carregar(), feito(8));
    });

    test('estudou offline (aparelho adiantado): carregar mescla e sobe para a nuvem', () async {
      await db.collection('users').doc('u1').set({'recorde': 1, 'habito': feito(2).toJson()});
      await LocalHabitoRepository(uid: 'u1').salvar(feito(5));
      final h = await repo().carregar();
      expect(h.sequencia, 5);
      expect(Habito.fromJson((await db.collection('users').doc('u1').get()).data()!['habito']).sequencia, 5);
      expect((await db.collection('users').doc('u1').get()).data()!['recorde'], 1);
    });

    test('dois aparelhos: o atrasado não derruba o adiantado, em qualquer ordem', () async {
      await db.collection('users').doc('u1').set({'habito': feito(7).toJson()});
      await LocalHabitoRepository(uid: 'u1').salvar(feito(3));
      expect((await repo().carregar()).sequencia, 7);
      expect((await repo().carregar()).sequencia, 7, reason: 'idempotente');
    });

    test('campo `habito` estragado na nuvem não lança: vale o do aparelho', () async {
      await db.collection('users').doc('u1').set({'habito': 'lixo'});
      await LocalHabitoRepository(uid: 'u1').salvar(feito(3));
      expect((await repo().carregar()).sequencia, 3);
    });

    test('cada usuário no seu documento', () async {
      await repo('u1').salvar(feito(3));
      await repo('u2').salvar(feito(9));
      SharedPreferences.setMockInitialValues({});
      expect((await repo('u1').carregar()).sequencia, 3);
      expect((await repo('u2').carregar()).sequencia, 9);
    });

    test('sem rede: salvar guarda no aparelho e avisa o erro; carregar devolve o do aparelho', () async {
      final semRede = FirestoreHabitoRepository('u1', db: _FirestoreSemRede());
      await expectLater(semRede.salvar(feito(2)), throwsException);
      expect((await LocalHabitoRepository(uid: 'u1').carregar()).sequencia, 2);
      expect((await semRede.carregar()).sequencia, 2);
    });
  });

  group('exclusão de conta', () {
    test('apagarDadosDoUsuario leva o hábito junto (é um campo de users/{uid})', () async {
      final db = FakeFirebaseFirestore();
      for (final uid in ['u1', 'u2']) {
        await db.collection('users').doc(uid).set({'concluidas': []});
        await FirestoreHabitoRepository(uid, db: db).salvar(feito(5));
      }
      expect((await db.collection('users').doc('u1').get()).data()!['habito'], isNotNull);
      await apagarDadosDoUsuario(db, 'u1');
      expect((await db.collection('users').doc('u1').get()).exists, isFalse);
      // o outro usuário fica intacto
      expect((await db.collection('users').doc('u2').get()).data()!['habito'], isNotNull);
    });
  });
}
