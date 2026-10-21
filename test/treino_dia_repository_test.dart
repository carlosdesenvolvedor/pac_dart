import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/treino_dia/data/treino_dia_repository.dart';
import 'package:pac_dart/features/treino_dia/domain/plano_treino.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dia = 20000;

PlanoTreino _plano({
  String curso = 'ingles',
  int dia = _dia,
  bool bonus = false,
  bool curto = false,
  int ms = 1000,
  EstadoBloco rali = EstadoBloco.pendente,
}) =>
    PlanoTreino(
      dia: dia,
      curso: curso,
      blocos: [
        if (!curto) const BlocoTreino(id: 'revisao', tipo: TipoBloco.revisao, qtd: 3),
        BlocoTreino(id: 'rali', tipo: TipoBloco.rali, minutos: 2, estado: rali),
      ],
      curto: curto,
      bonus: bonus,
      editadoEm: ms,
    );

/// Um Firestore sem rede: qualquer acesso falha (cópia do `habito_repository_test`).
class _FirestoreSemRede extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw Exception('sem rede');
}

/// Um Firestore que nunca responde (rede ruim / offline): `get` e `update` ficam pendentes para sempre.
class _FirestoreTravado extends FakeFirebaseFirestore {
  int escritas = 0;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => _ColecaoTravada(this);
}

// ignore: subtype_of_sealed_class
class _ColecaoTravada extends Fake implements CollectionReference<Map<String, dynamic>> {
  final _FirestoreTravado db;
  _ColecaoTravada(this.db);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _DocTravado(db);
}

// ignore: subtype_of_sealed_class
class _DocTravado extends Fake implements DocumentReference<Map<String, dynamic>> {
  final _FirestoreTravado db;
  _DocTravado(this.db);
  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([GetOptions? options]) =>
      Completer<DocumentSnapshot<Map<String, dynamic>>>().future;
  @override
  Future<void> update(Map<Object, Object?> data) {
    db.escritas++;
    return Completer<void>().future;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalTreinoDiaRepository', () {
    test('sem nada gravado → null', () async {
      expect(await LocalTreinoDiaRepository(curso: 'dart').carregar(), isNull);
    });

    test('ida e volta, na chave treino_dia_v1:{uid}:{curso}', () async {
      final p = _plano();
      await LocalTreinoDiaRepository(uid: 'ana', curso: 'ingles').salvar(p);
      expect(await LocalTreinoDiaRepository(uid: 'ana', curso: 'ingles').carregar(), p);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('treino_dia_v1:ana:ingles'), isNotNull);
      expect(LocalTreinoDiaRepository(curso: 'dart').chave, 'treino_dia_v1:dart');
    });

    test('dois cursos e duas contas não se misturam', () async {
      final ingles = _plano();
      final dart = _plano(curso: 'dart', curto: true);
      await LocalTreinoDiaRepository(uid: 'ana', curso: 'ingles').salvar(ingles);
      await LocalTreinoDiaRepository(uid: 'ana', curso: 'dart').salvar(dart);
      expect(await LocalTreinoDiaRepository(uid: 'ana', curso: 'ingles').carregar(), ingles);
      expect(await LocalTreinoDiaRepository(uid: 'ana', curso: 'dart').carregar(), dart);
      expect(await LocalTreinoDiaRepository(uid: 'beto', curso: 'ingles').carregar(), isNull);
      expect(await LocalTreinoDiaRepository(uid: 'ana', curso: 'csharp').carregar(), isNull);
    });

    test('pref corrompida → null, sem lançar', () async {
      for (final lixo in ['{não é json', '[1,2,3]', '"texto"', '', 'null', '{"v":2,"d":1,"c":"dart","b":[]}']) {
        SharedPreferences.setMockInitialValues({'treino_dia_v1:dart': lixo});
        expect(await LocalTreinoDiaRepository(curso: 'dart').carregar(), isNull, reason: lixo);
      }
    });
  });

  group('MemoriaTreinoDiaRepository', () {
    test('guarda o último e conta as gravações', () async {
      final repo = MemoriaTreinoDiaRepository(_plano());
      expect(await repo.carregar(), _plano());
      await repo.salvar(_plano(bonus: true));
      expect(repo.gravacoes, 1);
      expect((await repo.carregar())!.bonus, isTrue);
      expect(await MemoriaTreinoDiaRepository().carregar(), isNull);
    });
  });

  group('FirestoreTreinoDiaRepository', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    FirestoreTreinoDiaRepository repo(Linguagem l, [String uid = 'u1']) =>
        FirestoreTreinoDiaRepository(uid, linguagem: l, db: db);

    Future<Map<String, dynamic>> doc([String uid = 'u1']) async =>
        (await db.collection('users').doc(uid).get()).data() ?? {};

    /// `salvar` não espera a nuvem: aqui espera, para ler o documento depois.
    Future<void> salvarJa(FirestoreTreinoDiaRepository r, PlanoTreino p) async {
      await r.salvar(p);
      await r.envios;
    }

    test('o campo de cada curso: treino_dia / cs_treino_dia / en_treino_dia', () async {
      expect(repo(Linguagem.dart).campo, 'treino_dia');
      expect(repo(Linguagem.csharp).campo, 'cs_treino_dia');
      expect(repo(Linguagem.ingles).campo, 'en_treino_dia');
      await salvarJa(repo(Linguagem.ingles), _plano());
      await salvarJa(repo(Linguagem.csharp), _plano(curso: 'csharp', curto: true));
      await salvarJa(repo(Linguagem.dart), _plano(curso: 'dart', curto: true));
      final d = await doc();
      expect(PlanoTreino.fromJson(d['en_treino_dia']), _plano());
      expect(PlanoTreino.fromJson(d['cs_treino_dia']), _plano(curso: 'csharp', curto: true));
      expect(PlanoTreino.fromJson(d['treino_dia']), _plano(curso: 'dart', curto: true));
    });

    test('não apaga habito, concluidas nem en_concluidas', () async {
      await db.collection('users').doc('u1').set({
        'habito': {'v': 1, 'seq': 4},
        'concluidas': ['0:0', '0:1'],
        'en_concluidas': ['0:0'],
        'quizNotas': {'0:0': 9},
      });
      await salvarJa(repo(Linguagem.ingles), _plano());
      final d = await doc();
      expect(d['habito'], {'v': 1, 'seq': 4});
      expect(d['concluidas'], ['0:0', '0:1']);
      expect(d['en_concluidas'], ['0:0']);
      expect(d['quizNotas'], {'0:0': 9});
      expect(d['en_treino_dia'], isA<Map>());
    });

    test('conta sem documento: salvar cria; carregar sem nada → null e nada é escrito', () async {
      expect(await repo(Linguagem.dart, 'novo').carregar(), isNull);
      expect((await db.collection('users').doc('novo').get()).exists, isFalse);
      await salvarJa(repo(Linguagem.dart, 'u9'), _plano(curso: 'dart'));
      expect(PlanoTreino.fromJson((await doc('u9'))['treino_dia']), _plano(curso: 'dart'));
    });

    test('sem chaves velhas: o plano de D+1 não herda bonus/curto do de D (o campo é trocado inteiro)', () async {
      final r = repo(Linguagem.ingles);
      await salvarJa(r, _plano(bonus: true, curto: true));
      expect((await doc())['en_treino_dia']['x'], isTrue);
      await salvarJa(r, _plano(dia: _dia + 1, bonus: false, curto: false, ms: 2000));
      SharedPreferences.setMockInitialValues({}); // outro aparelho: só a nuvem
      final lido = await repo(Linguagem.ingles).carregar();
      expect(lido!.dia, _dia + 1);
      expect(lido.bonus, isFalse);
      expect(lido.curto, isFalse);
      expect((await doc())['en_treino_dia']['x'], isFalse);
    });

    test('ida e volta pela nuvem (aparelho novo) e a cópia desce para o aparelho', () async {
      await salvarJa(repo(Linguagem.ingles), _plano());
      SharedPreferences.setMockInitialValues({});
      expect(await repo(Linguagem.ingles).carregar(), _plano());
      expect(await LocalTreinoDiaRepository(uid: 'u1', curso: 'ingles').carregar(), _plano());
    });

    test('aparelho e nuvem se mesclam ao carregar, e os dois lados ficam iguais', () async {
      // nuvem: revisão feita; aparelho: rali pulado (outro aparelho, offline)
      final nuvem = _plano(ms: 5000).marcar('revisao', EstadoBloco.feito, resultado: 3, agoraMs: 5000);
      await db.collection('users').doc('u1').set({'en_treino_dia': nuvem.toJson(), 'recorde': 7});
      await LocalTreinoDiaRepository(uid: 'u1', curso: 'ingles').salvar(_plano(rali: EstadoBloco.pulado, ms: 6000));
      final r = repo(Linguagem.ingles);
      final junto = (await r.carregar())!;
      await r.envios;
      expect(junto.blocos.map((b) => b.estado), [EstadoBloco.feito, EstadoBloco.pulado]);
      expect(junto.concluido, isTrue);
      expect(PlanoTreino.fromJson((await doc())['en_treino_dia']), junto);
      expect(await LocalTreinoDiaRepository(uid: 'u1', curso: 'ingles').carregar(), junto);
      expect((await doc())['recorde'], 7);
    });

    test('campo estragado na nuvem: vale o do aparelho', () async {
      await db.collection('users').doc('u1').set({'en_treino_dia': 'lixo'});
      await LocalTreinoDiaRepository(uid: 'u1', curso: 'ingles').salvar(_plano());
      expect(await repo(Linguagem.ingles).carregar(), _plano());
    });

    test('sem rede: salvar guarda no aparelho e engole o erro da nuvem; carregar devolve o do aparelho', () async {
      final semRede = FirestoreTreinoDiaRepository('u1', linguagem: Linguagem.dart, db: _FirestoreSemRede());
      await semRede.salvar(_plano(curso: 'dart'));
      await semRede.envios;
      expect(await LocalTreinoDiaRepository(uid: 'u1', curso: 'dart').carregar(), _plano(curso: 'dart'));
      expect(await semRede.carregar(), _plano(curso: 'dart'));
    });

    test('nuvem que nunca confirma (offline): salvar termina com o aparelho; o mais novo chega ao aparelho', () async {
      final travado = _FirestoreTravado();
      final r = FirestoreTreinoDiaRepository('u1', linguagem: Linguagem.ingles, db: travado);
      final local = LocalTreinoDiaRepository(uid: 'u1', curso: 'ingles');
      await r.salvar(_plano()).timeout(const Duration(seconds: 2));
      final feito = _plano(ms: 2000).marcar('revisao', EstadoBloco.feito, resultado: 3, agoraMs: 2000);
      await r.salvar(feito).timeout(const Duration(seconds: 2));
      await r.salvar(feito.comBonus(agoraMs: 3000)).timeout(const Duration(seconds: 2));
      expect(await local.carregar(), feito.comBonus(agoraMs: 3000));
      expect(travado.escritas, 1, reason: 'uma escrita pendente na nuvem; o resto espera ela (só a mais nova)');
    });

    testWidgets('leitura da nuvem que nunca responde: depois de ${FirestoreTreinoDiaRepository.prazoLeitura.inSeconds} s vale o do aparelho',
        (tester) async {
      await LocalTreinoDiaRepository(uid: 'u1', curso: 'ingles').salvar(_plano());
      final r = FirestoreTreinoDiaRepository('u1', linguagem: Linguagem.ingles, db: _FirestoreTravado());
      PlanoTreino? lido;
      var pronto = false;
      unawaited(r.carregar().then((p) {
        lido = p;
        pronto = true;
      }));
      await tester.pump(const Duration(seconds: 9));
      expect(pronto, isFalse);
      await tester.pump(const Duration(seconds: 2));
      expect(pronto, isTrue);
      expect(lido, _plano());
    });
  });
}
