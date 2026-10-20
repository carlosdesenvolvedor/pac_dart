// Onde mora o banco de palavras do inglês: no aparelho (en_palavras_{uid}) e na nuvem
// (users/{uid}/palavras/v1, campo b), com mescla e falhas da nuvem engolidas.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Um Firestore sem rede (ou com a regra ainda não publicada): qualquer acesso falha.
class _FirestoreSemRede extends FakeFirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw Exception('sem rede');
}

BancoPalavras _banco(Map<String, String> palavras, {int u = 1}) {
  var b = BancoPalavras.vazio;
  for (final e in palavras.entries) {
    b = b.com(PalavraDoBanco(en: e.key, pt: e.value, origem: OrigemPalavra.minha, atualizadoEm: u));
  }
  return b;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalPalavrasRepository', () {
    test('vazio, ida e volta, na chave en_palavras_{uid}; dono diferente não vê', () async {
      final repo = LocalPalavrasRepository('ana');
      expect(await repo.carregar(), BancoPalavras.vazio);
      await repo.salvar(_banco({'apple': 'maçã'}));
      expect((await LocalPalavrasRepository('ana').carregar())['apple']!.pt, 'maçã');
      expect(await LocalPalavrasRepository('beto').carregar(), BancoPalavras.vazio);
      final p = await SharedPreferences.getInstance();
      expect(p.getString('en_palavras_ana'), isNotNull);
    });

    test('lixo gravado vira vazio', () async {
      SharedPreferences.setMockInitialValues({'en_palavras_u1': '{quebrado'});
      expect(await LocalPalavrasRepository('u1').carregar(), BancoPalavras.vazio);
    });
  });

  group('FirestorePalavrasRepository', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());
    DocumentReference<Map<String, dynamic>> doc(String uid) => db.collection('users').doc(uid).collection('palavras').doc('v1');

    test('salva no aparelho primeiro e na nuvem, no doc users/{uid}/palavras/v1 (campo b)', () async {
      final repo = FirestorePalavrasRepository('u1', db: db);
      await repo.salvar(_banco({'apple': 'maçã'}));
      final nuvem = (await doc('u1').get()).data()!;
      expect(nuvem.keys, ['b']);
      expect(BancoPalavras.decodificar(nuvem['b'])['apple']!.pt, 'maçã');
      expect((await LocalPalavrasRepository('u1').carregar())['apple'], isNotNull);
      // outro aparelho (aparelho vazio) recebe da nuvem
      SharedPreferences.setMockInitialValues({});
      expect((await FirestorePalavrasRepository('u1', db: db).carregar())['apple']!.pt, 'maçã');
      expect((await LocalPalavrasRepository('u1').carregar())['apple'], isNotNull, reason: 'a cópia local desce');
    });

    test('carregar mescla aparelho × nuvem e iguala os dois lados', () async {
      await LocalPalavrasRepository('u1').salvar(_banco({'apple': 'maçã', 'pear': 'pera'}, u: 5));
      await doc('u1').set({'b': _banco({'apple': 'maçã verde', 'kiwi': 'kiwi'}, u: 9).codificar()});
      final junto = await FirestorePalavrasRepository('u1', db: db).carregar();
      expect(junto['apple']!.pt, 'maçã verde');
      expect(junto.palavras.keys.toSet(), {'apple', 'pear', 'kiwi'});
      expect(BancoPalavras.decodificar((await doc('u1').get()).data()!['b']), junto);
      expect(await LocalPalavrasRepository('u1').carregar(), junto);
    });

    test('salvar JUNTA com a nuvem: dois aparelhos abertos não apagam os cartões/lápides um do outro', () async {
      final celular = FirestorePalavrasRepository('u1', db: db, local: MemoriaPalavrasRepository());
      final webLocal = MemoriaPalavrasRepository();
      final web = FirestorePalavrasRepository('u1', db: db, local: webLocal);
      await celular.salvar(_banco({'apple': 'maçã'}, u: 1));
      final carregadoNaWeb = await web.carregar(); // a web abre agora (só a apple)
      // o celular treina: apple ganha cartão, e a pear entra e é apagada (lápide)
      const cartao = CartaoSrs(estabilidade: 3, dificuldade: 5, ultimoDia: 100, proximoDia: 103);
      var noCelular = await celular.carregar();
      noCelular = noCelular
          .com(noCelular['apple']!.copyWith(cartao: cartao, atualizadoEm: 5))
          .com(const PalavraDoBanco(en: 'pear', pt: 'pera', removida: true, atualizadoEm: 6));
      await celular.salvar(noCelular);
      // a web (com o banco velho na memória) adiciona uma palavra e grava
      await web.salvar(carregadoNaWeb.com(const PalavraDoBanco(en: 'kiwi', pt: 'kiwi', atualizadoEm: 7)));
      final nuvem = BancoPalavras.decodificar((await doc('u1').get()).data()!['b']);
      expect(nuvem['apple']!.cartao, cartao, reason: 'o cartão do celular não some');
      expect(nuvem['pear']!.removida, isTrue, reason: 'a lápide também não');
      expect(nuvem['kiwi']!.pt, 'kiwi');
      expect(webLocal.banco, nuvem, reason: 'o aparelho fica com a mescla');
      // gravar de novo o mesmo estado é inofensivo
      await web.salvar(nuvem);
      expect(BancoPalavras.decodificar((await doc('u1').get()).data()!['b']), nuvem);
    });

    test('nuvem fora do ar (ou regra ausente): carrega e salva no aparelho, sem lançar', () async {
      final repo = FirestorePalavrasRepository('u1', db: _FirestoreSemRede());
      await repo.salvar(_banco({'apple': 'maçã'}));
      expect((await repo.carregar())['apple']!.pt, 'maçã');
    });

    test('doc quebrado na nuvem não derruba: vale o aparelho', () async {
      await LocalPalavrasRepository('u1').salvar(_banco({'apple': 'maçã'}));
      await doc('u1').set({'b': '{lixo'});
      expect((await FirestorePalavrasRepository('u1', db: db).carregar())['apple']!.pt, 'maçã');
    });
  });

  test('apagarDadosDoUsuario leva users/{uid}/palavras (e os textos) junto; o outro usuário fica', () async {
    final db = FakeFirebaseFirestore();
    for (final uid in ['u1', 'u2']) {
      await db.collection('users').doc(uid).set({'concluidas': []});
      await FirestorePalavrasRepository(uid, db: db).salvar(_banco({'apple': 'maçã'}));
      await db.collection('users').doc(uid).collection('textos').doc('k1').set({'t': 'x'});
    }
    await apagarDadosDoUsuario(db, 'u1');
    expect((await db.collection('users').doc('u1').collection('palavras').get()).docs, isEmpty);
    expect((await db.collection('users').doc('u1').collection('textos').get()).docs, isEmpty);
    expect((await db.collection('users').doc('u2').collection('palavras').get()).docs, hasLength(1));
    expect((await db.collection('users').doc('u2').collection('textos').get()).docs, hasLength(1));
  });
}
