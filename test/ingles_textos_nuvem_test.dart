// Os dublês de rede lenta/caída abaixo implementam as referências do Firestore (classes "seladas" só para o
// analisador; o Dart deixa, e é o jeito de simular a rede sem emulador).
// ignore_for_file: subtype_of_sealed_class
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/ingles/data/textos_repository.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Os textos que o aluno cola ou escreve seguem a conta para qualquer aparelho (`users/{uid}/textos`).
/// Cada "aparelho" tem o próprio armazenamento local; a nuvem (o Firestore falso) é uma só.
void main() {
  TextoSalvo texto(String id, {int ms = 1000, int n = 2, bool seq = false}) => TextoSalvo(
        id: id,
        titulo: 'Texto $id',
        criadoEm: DateTime.fromMillisecondsSinceEpoch(ms),
        frases: [for (var i = 1; i <= n; i++) FraseDoTexto('Line $i of $id.', 'Linha $i de $id.')],
        sequencial: seq,
      );

  late FakeFirebaseFirestore nuvem;
  late _Aparelho a, b;
  setUp(() {
    nuvem = FakeFirebaseFirestore();
    a = _Aparelho();
    b = _Aparelho();
  });

  FirestoreTextosRepository repo({String uid = 'u1', FirebaseFirestore? db, Duration espera = const Duration(seconds: 5)}) =>
      FirestoreTextosRepository(uid, db: db ?? nuvem, espera: espera);

  Future<List<String>> ids(_Aparelho ap, FirestoreTextosRepository r) async => [for (final t in await ap.usar(r.carregar)) t.id];

  Future<bool> naNuvem(String id, {String uid = 'u1'}) async => (await nuvem.doc('users/$uid/textos/$id').get()).exists;

  group('o texto de um aparelho aparece nos outros da mesma conta', () {
    test('salvar sobe para a nuvem e outro aparelho enxerga o texto inteiro', () async {
      final ra = repo(), rb = repo();
      await a.usar(() => ra.salvar(texto('k1', n: 3)));
      await a.usar(() => ra.enviado);

      expect(await naNuvem('k1'), isTrue);
      final vistos = await b.usar(rb.carregar);
      expect(vistos, [texto('k1', n: 3)], reason: 'título, data e frases chegam iguais');
    });

    test('a lista vem do mais novo para o mais antigo', () async {
      final ra = repo(), rb = repo();
      await a.usar(() => ra.salvar(texto('velho', ms: 1000)));
      await a.usar(() => ra.salvar(texto('novo', ms: 3000)));
      await a.usar(() => ra.salvar(texto('meio', ms: 2000)));
      await a.usar(() => ra.enviado);
      expect(await ids(b, rb), ['novo', 'meio', 'velho']);
    });

    test('cada conta vê só os seus textos', () async {
      final ra = repo();
      await a.usar(() => ra.salvar(texto('k1')));
      await a.usar(() => ra.enviado);
      expect(await ids(b, repo(uid: 'u2')), isEmpty);
    });

    test('regravar o mesmo id muda o texto nos dois lados (não duplica)', () async {
      final ra = repo(), rb = repo();
      await a.usar(() => ra.salvar(texto('k1', n: 2)));
      await a.usar(() => ra.enviado);
      expect(await ids(b, rb), ['k1']);
      await a.usar(() => ra.salvar(texto('k1', n: 5)));
      await a.usar(() => ra.enviado);
      final vistos = await b.usar(rb.carregar);
      expect(vistos.map((t) => t.frases.length), [5]);
    });

    test('apagar num aparelho tira o texto dos outros e ele não volta', () async {
      final ra = repo(), rb = repo();
      await a.usar(() => ra.salvar(texto('k1')));
      await a.usar(() => ra.salvar(texto('k2', ms: 2000)));
      await a.usar(() => ra.enviado);
      expect(await ids(b, rb), ['k2', 'k1']); // o aparelho B já tem os dois guardados

      await a.usar(() => ra.apagar('k1'));
      await a.usar(() => ra.enviado);
      expect(await naNuvem('k1'), isFalse);

      expect(await ids(b, rb), ['k2'], reason: 'o B também esquece, mesmo com cópia local');
      expect(await ids(b, rb), ['k2'], reason: 'e na leitura seguinte continua fora');
    });
  });

  group('textos criados ANTES da nuvem existir (só no aparelho)', () {
    test('sobem na primeira abertura e passam a aparecer em outro aparelho', () async {
      await a.usar(() => LocalTextosRepository('u1').salvar(texto('antigo', ms: 500)));
      final ra = repo(), rb = repo();

      expect(await ids(a, ra), ['antigo'], reason: 'nada some no aparelho de origem');
      expect(await naNuvem('antigo'), isTrue);
      expect(await ids(b, rb), ['antigo']);
    });

    test('o que só existe no aparelho se junta ao que só existe na nuvem', () async {
      await nuvem.doc('users/u1/textos/da-nuvem').set(texto('da-nuvem', ms: 2000).toJson());
      await a.usar(() => LocalTextosRepository('u1').salvar(texto('do-aparelho', ms: 1000)));

      expect(await ids(a, repo()), ['da-nuvem', 'do-aparelho']);
      expect(await naNuvem('do-aparelho'), isTrue);
    });

    test('depois de migrado, o texto apagado em outro aparelho NÃO ressuscita', () async {
      await a.usar(() => LocalTextosRepository('u1').salvar(texto('x')));
      final ra = repo(), rb = repo();
      expect(await ids(a, ra), ['x']); // migra
      expect(await ids(b, rb), ['x']);
      await b.usar(() => rb.apagar('x'));
      await b.usar(() => rb.enviado);

      expect(await ids(a, ra), isEmpty, reason: 'a cópia antiga do A não pode subir de novo');
      expect(await naNuvem('x'), isFalse);
    });

    test('"Meus cartões" (id fixo) dos dois lados vira a união das frases', () async {
      TextoSalvo cartoes(List<String> en) => TextoSalvo(
            id: 'cartoes',
            titulo: 'Meus cartões',
            criadoEm: DateTime.fromMillisecondsSinceEpoch(1),
            frases: [for (final e in en) FraseDoTexto(e, 'pt $e')],
            sequencial: true,
          );
      await nuvem.doc('users/u1/textos/cartoes').set(cartoes(['One.', 'Two.']).toJson());
      await a.usar(() => LocalTextosRepository('u1').salvar(cartoes(['two.', 'Three.'])));

      final vistos = await ids(a, repo());
      expect(vistos, ['cartoes']);
      final doc = (await nuvem.doc('users/u1/textos/cartoes').get()).data()!;
      expect([for (final f in doc['frases'] as List) (f as Map)['en']], ['One.', 'Two.', 'Three.'],
          reason: 'sem duplicar "Two." (maiúscula não conta) e sem perder a "Three."');
    });
  });

  group('sem rede, ou com a nuvem lenta', () {
    test('sem a nuvem, abrir mostra os textos do aparelho', () async {
      final ra = repo(), semRede = repo(db: _SemRede());
      await a.usar(() => ra.salvar(texto('k1')));
      await a.usar(() => ra.enviado);
      expect(await ids(a, semRede), ['k1']);
    });

    test('salvar sem rede vale no aparelho, fica pendente e sobe quando a nuvem volta', () async {
      final semRede = repo(db: _SemRede());
      await a.usar(() => semRede.salvar(texto('k1')));
      await a.usar(() => semRede.enviado);
      expect(await naNuvem('k1'), isFalse);
      expect(await ids(a, semRede), ['k1'], reason: 'o texto não se perde nem some da lista');

      // a rede volta (o app foi reaberto: outra instância, o mesmo aparelho)
      expect(await ids(a, repo()), ['k1']);
      expect(await naNuvem('k1'), isTrue);
      expect(await ids(b, repo()), ['k1']);
    });

    test('salvar sem rede DEPOIS de já ter aberto com a nuvem também sobe quando ela volta', () async {
      final ra = repo();
      expect(await ids(a, ra), isEmpty); // abriu online: este aparelho já está migrado
      final semRede = repo(db: _SemRede());
      await a.usar(() => semRede.salvar(texto('k1')));
      await a.usar(() => semRede.enviado);
      expect(await naNuvem('k1'), isFalse);

      expect(await ids(a, repo()), ['k1'], reason: 'pendente é pendente: não é "apagado em outro aparelho"');
      expect(await naNuvem('k1'), isTrue);
    });

    test('um texto salvo enquanto a lista ainda está sendo lida não se perde (nem se a gravação falhar)', () async {
      SharedPreferences.setMockInitialValues({});
      final porta = _Porta(nuvem)..gravacaoFalha = true;
      final r = repo(db: porta);
      final lendo = r.carregar(); // fica parado na leitura da nuvem
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await r.salvar(texto('novo')); // criado nesse meio-tempo; a gravação na nuvem falha
      await r.enviado;
      porta.aberta.complete();
      await lendo;

      expect(await repo().carregar().then((l) => [for (final t in l) t.id]), ['novo'], reason: 'o espelho não pode ser atropelado pela leitura antiga');
      expect(await naNuvem('novo'), isTrue, reason: 'e a pendência ainda sobe depois');
    });

    test('apagar sem rede também fica pendente e vale quando a nuvem volta', () async {
      await a.usar(() => repo().salvar(texto('k1')));
      await a.usar(() => repo().enviado);
      final semRede = repo(db: _SemRede());
      await a.usar(() => semRede.apagar('k1'));
      await a.usar(() => semRede.enviado);
      expect(await naNuvem('k1'), isTrue, reason: 'ainda não deu para apagar lá');
      expect(await ids(a, semRede), isEmpty);

      expect(await ids(a, repo()), isEmpty, reason: 'a nuvem não pode devolver o que foi apagado aqui');
      expect(await naNuvem('k1'), isFalse);
    });

    test('o que veio da nuvem fica guardado no aparelho para quando faltar rede', () async {
      await a.usar(() => repo().salvar(texto('k1')));
      await a.usar(() => repo().enviado);
      expect(await ids(b, repo()), ['k1']);
      expect(await ids(b, repo(db: _SemRede())), ['k1'], reason: 'o B nunca criou o k1: ele só pode vir do espelho');
    });

    test('nuvem travada não prende quem salva (vale o aparelho na hora) nem quem abre', () async {
      final lenta = repo(db: _Travada(), espera: const Duration(milliseconds: 600));
      // a espera da rede é de 600 ms: salvar tem de voltar bem antes disso, sem esperar a nuvem
      await a.usar(() => lenta.salvar(texto('k1'))).timeout(const Duration(milliseconds: 300));
      expect(await a.usar(lenta.carregar).timeout(const Duration(seconds: 3)), [texto('k1')]);
      await a.usar(() => lenta.enviado);

      expect(await ids(a, repo()), ['k1'], reason: 'o que ficou pendente sobe depois');
      expect(await naNuvem('k1'), isTrue);
    });

    test('texto grande demais para um documento do Firestore fica só no aparelho, sem sumir', () async {
      final ra = repo();
      final enorme = TextoSalvo(
        id: 'gigante',
        titulo: 'Gigante',
        criadoEm: DateTime.fromMillisecondsSinceEpoch(1),
        frases: [FraseDoTexto('x' * 950000, 'y')],
      );
      await a.usar(() => ra.salvar(enorme));
      await a.usar(() => ra.enviado);
      expect(await naNuvem('gigante'), isFalse);
      expect(await ids(a, ra), ['gigante']);
      expect(await ids(a, ra), ['gigante'], reason: 'nem depois de migrado a nuvem o apaga do aparelho');
    });

    test('documento quebrado na nuvem é ignorado, os outros chegam', () async {
      await nuvem.doc('users/u1/textos/quebrado').set({'id': 'quebrado'});
      await nuvem.doc('users/u1/textos/bom').set(texto('bom').toJson());
      expect(await ids(a, repo()), ['bom']);
    });
  });

  group('na tela: o outro aparelho recebe a trilha "Meus textos"', () {
    final curso = [
      Trilha(
        nivel: 'Primeiros Passos',
        emoji: '👋',
        etapa: 'A1 · Fundação',
        licoes: const [Licao(id: 'a1.um', nome: 'Um', emoji: '1', trechos: [Trecho(cod: 'Hi.', dica: 'Oi.', out: '')])],
      ),
    ];

    Future<CursoBloc> abrir(_Aparelho ap, FirestoreTextosRepository r) => ap.usar(() async {
          final bloc = CursoBloc(loader: _LoaderTeste(curso), progresso: LocalProgressoRepository(prefixo: 'en_'), textos: r);
          bloc.add(const CursoIniciado());
          await bloc.stream.firstWhere((s) => s.status == CursoStatus.pronto);
          return bloc;
        });

    test('texto criado no celular aparece no computador; apagado lá, some daqui', () async {
      final rc = repo(), rpc = repo();
      final celular = await abrir(a, rc);
      await a.usar(() async {
        celular.add(TextoCriado(texto('meu', n: 4)));
        await celular.stream.firstWhere((s) => s.trilhas.length == 2);
        await rc.enviado;
      });

      final pc = await abrir(b, rpc);
      expect(pc.state.trilhas.map((t) => t.textoId), ['', 'meu']);
      expect(pc.state.trilhas.last.licoes.first.trechos.length, 4);

      await b.usar(() async {
        pc.add(const TextoApagado('meu'));
        await pc.stream.firstWhere((s) => s.trilhas.length == 1);
        await rpc.enviado;
      });
      final celularDeNovo = await abrir(a, repo());
      expect(celularDeNovo.state.trilhas.map((t) => t.textoId), [''], reason: 'o celular reabre sem o texto apagado no computador');

      for (final c in [celular, pc, celularDeNovo]) {
        await c.close();
      }
    });
  });
}

/// Um aparelho: o armazenamento local dele (shared_preferences) fica guardado entre os usos.
class _Aparelho {
  Map<String, Object> _guardado = {};

  Future<T> usar<T>(FutureOr<T> Function() f) async {
    SharedPreferences.setMockInitialValues(Map.of(_guardado));
    final r = await f();
    final p = await SharedPreferences.getInstance();
    _guardado = {for (final k in p.getKeys()) k: p.get(k)!};
    return r;
  }
}

/// Sem rede: tudo que toca na nuvem lança.
class _SemRede extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => throw StateError('sem rede');
}

/// A nuvem de verdade (a falsa) responde, mas a LEITURA da coleção espera [aberta]; e a gravação pode falhar.
class _Porta extends Fake implements FirebaseFirestore {
  final FirebaseFirestore real;
  final Completer<void> aberta = Completer<void>();
  bool gravacaoFalha = false;
  _Porta(this.real);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => _ColPorta(real.collection(collectionPath), this);
}

class _ColPorta extends Fake implements CollectionReference<Map<String, dynamic>> {
  final CollectionReference<Map<String, dynamic>> real;
  final _Porta porta;
  _ColPorta(this.real, this.porta);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _DocPorta(real.doc(path), porta);

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    await porta.aberta.future;
    return real.get(options);
  }
}

class _DocPorta extends Fake implements DocumentReference<Map<String, dynamic>> {
  final DocumentReference<Map<String, dynamic>> real;
  final _Porta porta;
  _DocPorta(this.real, this.porta);

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => _ColPorta(real.collection(collectionPath), porta);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) =>
      porta.gravacaoFalha ? Future.error(StateError('sem rede')) : real.set(data, options);

  @override
  Future<void> delete() => porta.gravacaoFalha ? Future.error(StateError('sem rede')) : real.delete();
}

/// A rede "pendura": nenhuma leitura nem gravação termina.
class _Travada extends Fake implements FirebaseFirestore {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => _ColTravada();
}

class _ColTravada extends Fake implements CollectionReference<Map<String, dynamic>> {
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => _DocTravado();

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) => Completer<QuerySnapshot<Map<String, dynamic>>>().future;
}

class _DocTravado extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) => _ColTravada();

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) => Completer<void>().future;

  @override
  Future<void> delete() => Completer<void>().future;
}

class _LoaderTeste extends CurriculoLoader {
  final List<Trilha> trilhas;
  _LoaderTeste(this.trilhas) : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}
