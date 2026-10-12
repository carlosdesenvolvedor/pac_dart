import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/auth/data/exclusao_de_conta.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Meia-noite local de um dia qualquer (o relógio dos testes).
DateTime _em(int diasDepoisDe20000) => DateTime(2026, 10, 12).add(Duration(days: diasDepoisDe20000));

/// Espera o que ficou "solto" (gravações em segundo plano) terminar.
Future<void> _assenta() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

class _RepoMemoria implements RevisaoRepository {
  Map<String, CartaoSrs> cartoes;
  final historico = <EntradaHistorico>[];
  bool quebrado = false;
  _RepoMemoria([Map<String, CartaoSrs>? iniciais]) : cartoes = {...?iniciais};

  @override
  Future<Map<String, CartaoSrs>> carregar() async {
    if (quebrado) throw Exception('sem rede');
    return {...cartoes};
  }

  @override
  Future<void> salvar(Map<String, CartaoSrs> novos) async {
    if (quebrado) throw Exception('sem rede');
    cartoes = {...cartoes, ...novos};
  }

  @override
  Future<void> registrarHistorico(List<EntradaHistorico> entradas) async {
    if (quebrado) throw Exception('sem rede');
    historico.addAll(entradas);
  }

  @override
  Future<List<EntradaHistorico>> carregarHistorico({int? desdeDia}) async =>
      [for (final e in historico) if (desdeDia == null || e.dia >= desdeDia) e];
}

void main() {
  final fsrs = AgendadorFsrs(fuzz: false);

  group('CartaoSrs', () {
    test('ida e volta; lixo e valores impossíveis viram null', () {
      final c = fsrs.avaliar(fsrs.novo(100), Rating.good, 101);
      expect(CartaoSrs.decodificar(c.codificar()), c);
      for (final ruim in ['lixo', '', 'f|1|2', 'f|a|2|3|4|5|6', 'f|1|2|-3|4|5|6', 'f|1|2|0|4|5|6', 'f|1|2|NaN|4|5|6', null]) {
        expect(CartaoSrs.decodificar(ruim), isNull, reason: '$ruim');
      }
    });

    test('lê o formato ANTIGO (caixa de Leitner) e converte mantendo o dia da próxima revisão', () {
      final c = CartaoSrs.decodificar(const CartaoRevisao(caixa: 3, proximoDia: 100, lapsos: 2).codificar())!;
      expect(c.proximoDia, 100, reason: 'a agenda de quem já estudava não muda');
      expect(c.estabilidade, 7, reason: 'o intervalo da caixa 3');
      expect(c.ultimoDia, 93);
      expect(c.revisoes, 3);
      expect(c.lapsos, 2);
      expect(c.dificuldade, AgendadorFsrs.dificuldadeInicial);
      // caixa fora da faixa não quebra
      expect(CartaoSrs.decodificar('99|50|0')!.estabilidade, 180);
      expect(CartaoSrs.decodificar('0|50|0')!.estabilidade, 1);
    });

    test('madura = memória de 3 semanas ou mais', () {
      CartaoSrs com(double s) => CartaoSrs(estabilidade: s, dificuldade: 5, ultimoDia: 0, proximoDia: 1);
      expect(com(20.9).madura, isFalse);
      expect(com(21).madura, isTrue);
    });
  });

  group('AgendadorFsrs (sem fuzz)', () {
    test('a dificuldade inicial é a de uma frase nova com nota "bom"', () {
      expect(fsrs.novo(100).dificuldade, AgendadorFsrs.dificuldadeInicial);
    });

    test('a 1ª revisão volta AMANHÃ com qualquer nota (o sono entre as sessões)', () {
      for (final n in Rating.values) {
        final c = fsrs.novo(500, nota: n);
        expect(c.proximoDia, 501, reason: '$n');
        expect(c.ultimoDia, 500);
        expect(c.revisoes, 1);
        expect(c.lapsos, 0, reason: 'errar na primeira vez não é "lapso"');
      }
    });

    test('a nota da 1ª vez pesa na memória: errei < difícil < bom < fácil (e a dificuldade faz o inverso)', () {
      final c = {for (final n in Rating.values) n: fsrs.novo(0, nota: n)};
      expect(c[Rating.again]!.estabilidade, lessThan(c[Rating.hard]!.estabilidade));
      expect(c[Rating.hard]!.estabilidade, lessThan(c[Rating.good]!.estabilidade));
      expect(c[Rating.good]!.estabilidade, lessThan(c[Rating.easy]!.estabilidade));
      expect(c[Rating.again]!.dificuldade, greaterThan(c[Rating.hard]!.dificuldade));
      expect(c[Rating.hard]!.dificuldade, greaterThan(c[Rating.good]!.dificuldade));
      expect(c[Rating.good]!.dificuldade, greaterThan(c[Rating.easy]!.dificuldade));
    });

    test('acertos nas datas marcadas: o intervalo só cresce, até o teto de 1 ano', () {
      var c = fsrs.novo(0);
      var dia = c.proximoDia;
      var anterior = 0;
      for (var i = 0; i < 12; i++) {
        c = fsrs.avaliar(c, Rating.good, dia);
        final intervalo = c.proximoDia - dia;
        expect(intervalo, greaterThanOrEqualTo(anterior), reason: 'revisão ${i + 1}');
        expect(intervalo, lessThanOrEqualTo(AgendadorFsrs.intervaloMaximo));
        expect(c.revisoes, i + 2);
        expect(c.ultimoDia, dia);
        anterior = intervalo;
        dia = c.proximoDia;
      }
      expect(anterior, AgendadorFsrs.intervaloMaximo, reason: 'depois de muitos acertos bate no teto');
    });

    test('ritmo do 90%: o 1º ciclo de acertos é 1 → ~6 → ~3 semanas → ~2 meses', () {
      var c = fsrs.novo(0);
      var dia = c.proximoDia;
      final intervalos = <int>[dia];
      for (var i = 0; i < 3; i++) {
        c = fsrs.avaliar(c, Rating.good, dia);
        intervalos.add(c.proximoDia - dia);
        dia = c.proximoDia;
      }
      expect(intervalos[0], 1);
      expect(intervalos[1], inInclusiveRange(4, 9));
      expect(intervalos[2], inInclusiveRange(14, 32));
      expect(intervalos[3], inInclusiveRange(40, 100));
    });

    test('errar encurta bem o intervalo, conta lapso e baixa a estabilidade; difícil < bom < fácil', () {
      var c = fsrs.novo(0);
      var dia = c.proximoDia;
      for (var i = 0; i < 3; i++) {
        c = fsrs.avaliar(c, Rating.good, dia);
        dia = c.proximoDia;
      }
      final r = {for (final n in Rating.values) n: fsrs.avaliar(c, n, dia)};
      int volta(Rating n) => r[n]!.proximoDia - dia;
      expect(volta(Rating.again), lessThan(volta(Rating.hard)));
      expect(volta(Rating.hard), lessThan(volta(Rating.good)));
      expect(volta(Rating.good), lessThan(volta(Rating.easy)));
      expect(volta(Rating.again), lessThan(volta(Rating.good) / 4));
      expect(volta(Rating.again), greaterThanOrEqualTo(1));
      expect(r[Rating.again]!.estabilidade, lessThan(c.estabilidade));
      expect(r[Rating.again]!.lapsos, c.lapsos + 1);
      expect(r[Rating.good]!.lapsos, c.lapsos);
      expect(r[Rating.again]!.dificuldade, greaterThan(c.dificuldade));
    });

    test('revisar adiantado, no próprio dia ou atrasado nunca quebra e sempre agenda pelo menos amanhã', () {
      final c = fsrs.avaliar(fsrs.novo(0), Rating.good, 1); // volta no dia 7
      for (final hoje in [1, 3, c.proximoDia, c.proximoDia + 40, 0]) {
        for (final n in Rating.values) {
          final novo = fsrs.avaliar(c, n, hoje);
          expect(novo.proximoDia, greaterThan(hoje), reason: 'hoje=$hoje $n');
          expect(novo.estabilidade, greaterThan(0));
          expect(novo.dificuldade, inInclusiveRange(1, 10));
        }
      }
    });

    test('nivelamento: entra como "fácil" e volta em exatamente 1 semana', () {
      final t = fsrs.testada(300);
      expect(t.proximoDia, 307);
      expect(t.ultimoDia, 300);
      expect(t.estabilidade, greaterThan(fsrs.novo(300).estabilidade));
    });

    test('retrievabilidade: 100% no dia, cai com o tempo e fica perto de 90% no dia marcado', () {
      var c = fsrs.novo(0);
      var dia = c.proximoDia;
      for (var i = 0; i < 3; i++) {
        c = fsrs.avaliar(c, Rating.good, dia);
        dia = c.proximoDia;
      }
      expect(fsrs.retrievabilidade(c, c.ultimoDia), closeTo(1, 1e-9));
      var antes = 1.0;
      for (final t in [1, 5, 20, 60, 200]) {
        final r = fsrs.retrievabilidade(c, c.ultimoDia + t);
        expect(r, lessThan(antes));
        antes = r;
      }
      expect(fsrs.retrievabilidade(c, c.proximoDia), inInclusiveRange(.88, .92));
    });

    test('retenção maior pede revisões mais frequentes', () {
      int ate(double retencao) {
        final a = AgendadorFsrs(retencao: retencao, fuzz: false);
        var c = a.novo(0);
        return a.avaliar(c, Rating.good, c.proximoDia).proximoDia - c.proximoDia;
      }

      expect(ate(.95), lessThan(ate(.90)));
      expect(ate(.90), lessThan(ate(.85)));
    });

    test('com fuzz os intervalos variam um pouco mas respeitam 1 dia e o teto', () {
      final a = AgendadorFsrs();
      var c = a.novo(0);
      var dia = c.proximoDia;
      for (var i = 0; i < 20; i++) {
        c = a.avaliar(c, Rating.good, dia);
        expect(c.proximoDia - dia, inInclusiveRange(1, AgendadorFsrs.intervaloMaximo));
        dia = c.proximoDia;
      }
    });

    test('devidas: só as que venceram, as com MENOS chance de lembrar primeiro, no máximo [limite]', () {
      CartaoSrs c(double s, int ult, int prox) =>
          CartaoSrs(estabilidade: s, dificuldade: 5, ultimoDia: ult, proximoDia: prox);
      final cartoes = {
        'futura': c(10, 100, 120),
        'forte': c(100, 0, 100), // venceu, mas a memória é boa
        'fraca': c(2, 95, 100), // venceu e a memória é fraca
        'atrasada': c(2, 60, 62), // a mais atrasada
        'b': c(5, 90, 100),
        'a': c(5, 90, 100), // empata com 'b' → pela chave
      };
      expect(fsrs.devidas(cartoes, 100), ['atrasada', 'fraca', 'a', 'b', 'forte']);
      expect(fsrs.devidas(cartoes, 100, limite: 2), ['atrasada', 'fraca']);
      expect(fsrs.devidas(cartoes, 10), isEmpty);
    });

    test('a nota do Anki sai do resultado da digitação', () {
      expect(notaDoResultado(ResultadoRevisao.errou), Rating.again);
      expect(notaDoResultado(ResultadoRevisao.hesitou), Rating.hard);
      expect(notaDoResultado(ResultadoRevisao.acertou), Rating.good);
      expect(notaDoResultado(ResultadoRevisao.acertou, facil: true), Rating.easy);
    });
  });

  test('EntradaHistorico: ida e volta (com e sem a marca de 1ª vez) e rejeita lixo', () {
    const e = EntradaHistorico(20000, 'k3j9x2a', 3);
    expect(EntradaHistorico.decodificar(e.codificar()), e);
    expect(e.codificar(), '20000|k3j9x2a|3', reason: 'o formato antigo continua igual');
    const n = EntradaHistorico(20000, 'k3j9x2a', 3, primeira: true);
    expect(n.codificar(), '20000|k3j9x2a|3|n');
    expect(EntradaHistorico.decodificar(n.codificar()), n);
    for (final ruim in ['', 'a|b', '1|k|9', '1||3', 'x|k|3', '1|k|0', '1|k|3|x', '1|k|3|n|n', null]) {
      expect(EntradaHistorico.decodificar(ruim), isNull, reason: '$ruim');
    }
  });

  group('RevisaoCubit', () {
    const f1 = Trecho(cod: 'Nice to meet you.', dica: 'Prazer.', out: '');
    const f2 = Trecho(cod: 'How are you?', dica: 'Como vai?', out: '');
    final k1 = RevisaoCubit.chaveDe(f1), k2 = RevisaoCubit.chaveDe(f2);
    final hoje = Revisao.dia(_em(0));

    RevisaoCubit cubit(_RepoMemoria repo, {int dias = 0}) =>
        RevisaoCubit(repo: repo, agendador: fsrs, agora: () => _em(dias));

    test('aprender: cada frase vira cartão que volta amanhã, com a nota da prova, e vai ao histórico', () async {
      final repo = _RepoMemoria();
      final c = cubit(repo);
      await _assenta();
      await c.aprender(const [f1, f2], notas: {k1: ResultadoRevisao.errou});
      expect(c.state.cartoes[k1], fsrs.novo(hoje, nota: Rating.again));
      expect(c.state.cartoes[k2], fsrs.novo(hoje));
      expect(c.state.cartoes.values.every((x) => x.proximoDia == hoje + 1), isTrue);
      expect(repo.cartoes, c.state.cartoes);
      expect(repo.historico,
          [EntradaHistorico(hoje, k1, 1, primeira: true), EntradaHistorico(hoje, k2, 3, primeira: true)]);
    });

    test('aprender não mexe em quem já é cartão (segue no ritmo dele) nem repete a mesma frase', () async {
      final existente = fsrs.avaliar(fsrs.novo(hoje - 10), Rating.good, hoje - 9);
      final repo = _RepoMemoria({k1: existente});
      final c = cubit(repo);
      await _assenta();
      await c.aprender(const [f1, f2, f2]);
      expect(c.state.cartoes[k1], existente);
      expect(repo.historico.map((e) => e.chave), [k2], reason: 'só a frase nova entra no histórico, uma vez');
    });

    test('testadas: entram como "fáceis" e voltam em 1 semana; as que já eram cartão ficam', () async {
      final existente = fsrs.novo(hoje - 3);
      final repo = _RepoMemoria({k1: existente});
      final c = cubit(repo);
      await _assenta();
      await c.testadas(const [f1, f2]);
      expect(c.state.cartoes[k1], existente);
      expect(c.state.cartoes[k2]!.proximoDia, hoje + 7);
      expect(repo.historico, [EntradaHistorico(hoje, k2, 4, primeira: true)]);
    });

    test('registrar: a nota vai para o FSRS, o cartão anda e a revisão entra no histórico', () async {
      final inicial = fsrs.novo(hoje - 1); // vence hoje
      final repo = _RepoMemoria({k1: inicial});
      final c = cubit(repo);
      await _assenta();
      expect(c.state.quantasDevidas(hoje), 1);
      await c.registrar(f1, ResultadoRevisao.acertou);
      final depois = c.state.cartoes[k1]!;
      expect(depois, fsrs.avaliar(inicial, Rating.good, hoje));
      expect(depois.revisoes, 2);
      expect(depois.proximoDia, greaterThan(hoje + 1));
      expect(c.state.quantasDevidas(hoje), 0);
      expect(repo.historico.single, EntradaHistorico(hoje, k1, 3));

      await c.registrar(f1, ResultadoRevisao.errou);
      expect(c.state.cartoes[k1]!.lapsos, 1);
      expect(repo.historico.last.nota, 1);
    });

    test('registrar uma frase que ainda não era cartão cria o cartão', () async {
      final repo = _RepoMemoria();
      final c = cubit(repo);
      await _assenta();
      await c.registrar(f2, ResultadoRevisao.hesitou);
      expect(c.state.cartoes[k2], fsrs.novo(hoje, nota: Rating.hard));
      expect(repo.historico.single, EntradaHistorico(hoje, k2, 2, primeira: true));
    });

    test('devidas() usa o relógio do cubit e o limite', () async {
      final repo = _RepoMemoria({k1: fsrs.novo(hoje - 5), k2: fsrs.novo(hoje + 3)});
      final c = cubit(repo);
      await _assenta();
      expect(c.devidas(), [k1]);
      final daqui30 = cubit(repo, dias: 30);
      await _assenta();
      expect(daqui30.devidas().toSet(), {k1, k2});
      expect(daqui30.devidas(limite: 1).length, 1);
    });

    test('sem rede: a tela segue (estado local atualizado) e nada lança', () async {
      final repo = _RepoMemoria()..quebrado = true;
      final c = cubit(repo);
      await _assenta();
      expect(c.state.carregado, isTrue);
      await c.aprender(const [f1]);
      await c.registrar(f1, ResultadoRevisao.acertou);
      expect(c.state.cartoes[k1]!.revisoes, 2);
    });

    test('o que entrou enquanto carregava prevalece sobre o que veio da nuvem', () async {
      final repo = _RepoMemoria({k1: fsrs.novo(hoje - 20)});
      final c = cubit(repo);
      await c.aprender(const [f2]); // antes de o carregamento terminar
      await _assenta();
      expect(c.state.cartoes.keys, containsAll([k1, k2]));
    });
  });

  group('LocalRevisaoRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('guarda e devolve; regravar a mesma chave troca só ela', () async {
      final repo = LocalRevisaoRepository();
      expect(await repo.carregar(), isEmpty);
      await repo.salvar({'a': fsrs.novo(10), 'b': fsrs.novo(11)});
      await repo.salvar({'a': fsrs.novo(12)});
      final r = await LocalRevisaoRepository().carregar();
      expect(r['a'], fsrs.novo(12));
      expect(r['b'], fsrs.novo(11));
    });

    test('lê o mapa ANTIGO (en_revisao) já convertido; o motor novo (en_srs) prevalece', () async {
      SharedPreferences.setMockInitialValues({
        'en_revisao': jsonEncode({
          'velha': const CartaoRevisao(caixa: 4, proximoDia: 200, lapsos: 1).codificar(),
          'dupla': const CartaoRevisao(caixa: 1, proximoDia: 5).codificar(),
        }),
        'en_srs': jsonEncode({'dupla': fsrs.novo(300).codificar()}),
      });
      final r = await LocalRevisaoRepository().carregar();
      expect(r['velha']!.proximoDia, 200);
      expect(r['velha']!.estabilidade, 16);
      expect(r['dupla'], fsrs.novo(300));
    });

    test('armazenamento corrompido vira lista vazia, não erro', () async {
      SharedPreferences.setMockInitialValues({'en_srs': '{{{', 'en_revisao': '[1,2]', 'en_srs_log': 'x'});
      final repo = LocalRevisaoRepository();
      expect(await repo.carregar(), isEmpty);
      expect(await repo.carregarHistorico(), isEmpty);
    });

    test('histórico: em ordem, filtra por dia e guarda só as últimas $LocalRevisaoRepository.maxHistorico', () async {
      final repo = LocalRevisaoRepository();
      await repo.registrarHistorico(const [EntradaHistorico(30, 'b', 3), EntradaHistorico(10, 'a', 1)]);
      expect((await repo.carregarHistorico()).map((e) => e.dia), [10, 30]);
      expect((await repo.carregarHistorico(desdeDia: 20)).map((e) => e.dia), [30]);
      await repo.registrarHistorico([for (var i = 0; i < LocalRevisaoRepository.maxHistorico + 50; i++) EntradaHistorico(100 + i, 'k', 3)]);
      final todas = await repo.carregarHistorico();
      expect(todas.length, LocalRevisaoRepository.maxHistorico);
      expect(todas.last.dia, 100 + LocalRevisaoRepository.maxHistorico + 49, reason: 'ficam as mais novas');
    });
  });

  group('FirestoreRevisaoRepository (blocos em users/{uid}/srs)', () {
    late FakeFirebaseFirestore db;
    late FirestoreRevisaoRepository repo;
    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreRevisaoRepository('u1', db: db);
    });

    Future<Map<String, Map<String, dynamic>>> blocos() async {
      final s = await db.collection('users').doc('u1').collection('srs').get();
      return {for (final d in s.docs) d.id: d.data()};
    }

    test('o bloco é função só da chave: estável, sempre b00…b15', () {
      for (var i = 0; i < 500; i++) {
        final id = FirestoreRevisaoRepository.idDoBloco(Revisao.chave('frase $i'));
        expect(RegExp(r'^b(0\d|1[0-5])$').hasMatch(id), isTrue, reason: id);
        expect(id, FirestoreRevisaoRepository.idDoBloco(Revisao.chave('frase $i')));
      }
    });

    test('o bloco de frases conhecidas é FIXO (mesmo resultado na VM, no Chrome e no celular; mudar quebra os dados gravados)', () {
      const esperado = {
        'Nice to meet you.': ('i1cy7sgips', 'b15'),
        'How are you?': ('7yuj1r19ji', 'b02'),
        "I'm fine.": ('zhqkf518me', 'b05'),
        'Where are you from?': ('wp1gdram2p', 'b11'),
        'Good morning, Mike!': ('8bft0khkqy', 'b13'),
        "She doesn't like coffee.": ('naoed3gw2', 'b07'),
      };
      esperado.forEach((frase, par) {
        expect(Revisao.chave(frase), par.$1, reason: frase);
        expect(FirestoreRevisaoRepository.idDoBloco(par.$1), par.$2, reason: frase);
      });
      expect(FirestoreRevisaoRepository.idDoBloco('zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz'), 'b08', reason: 'chave longa');
      expect(FirestoreRevisaoRepository.idDoBloco('f-7c1e2a'), 'b00', reason: 'id opaco do conteúdo');
    });

    test('salvar reparte pelos blocos; carregar junta tudo; regravar não apaga os vizinhos do bloco', () async {
      final cartoes = {for (var i = 0; i < 60; i++) Revisao.chave('frase $i'): fsrs.novo(i)};
      await repo.salvar(cartoes);
      final b = await blocos();
      expect(b.keys.every((id) => id.startsWith('b')), isTrue);
      expect(b.length, greaterThan(8), reason: '60 chaves se espalham por vários blocos');
      expect(b.length, lessThanOrEqualTo(FirestoreRevisaoRepository.blocos));
      expect(await repo.carregar(), cartoes);

      // regrava UMA chave: as outras (inclusive do mesmo bloco) ficam
      final k = cartoes.keys.first;
      final novo = fsrs.avaliar(cartoes[k]!, Rating.good, cartoes[k]!.proximoDia);
      await repo.salvar({k: novo});
      expect(await FirestoreRevisaoRepository('u1', db: db).carregar(), {...cartoes, k: novo});
    });

    test('salvar vazio não escreve nada', () async {
      await repo.salvar({});
      expect(await blocos(), isEmpty);
    });

    test('MIGRAÇÃO: o mapa antigo de Leitner vira cartões em blocos; o antigo fica; o resto do doc não é tocado', () async {
      await db.collection('users').doc('u1').set({
        'concluidas': ['a', 'b'],
        'en_revisao': {
          'k1': const CartaoRevisao(caixa: 2, proximoDia: 150, lapsos: 1).codificar(),
          'k2': const CartaoRevisao(caixa: 5, proximoDia: 160).codificar(),
        },
      });
      final r = await repo.carregar();
      expect(r.keys, {'k1', 'k2'});
      expect(r['k1']!.proximoDia, 150);
      expect(r['k2']!.estabilidade, 35);
      await _assenta();

      final b = await blocos();
      expect(b.containsKey('_meta'), isTrue);
      final gravados = <String, dynamic>{for (final e in b.entries) if (e.key != '_meta') ...(e.value['c'] as Map).cast()};
      expect(gravados.keys, {'k1', 'k2'});

      final doc = (await db.collection('users').doc('u1').get()).data()!;
      expect(doc['concluidas'], ['a', 'b']);
      expect((doc['en_revisao'] as Map).keys, {'k1', 'k2'}, reason: 'o mapa antigo continua lá (dá para voltar)');

      // 2ª abertura (outro aparelho): lê os blocos, sem depender do mapa antigo
      await db.collection('users').doc('u1').update({'en_revisao': {'k1': 'lixo'}});
      final de2 = await FirestoreRevisaoRepository('u1', db: db).carregar();
      expect(de2, r);
    });

    test('depois de migrar, o que foi revisado no motor novo prevalece sobre o mapa antigo', () async {
      await db.collection('users').doc('u1').set({
        'en_revisao': {'k1': const CartaoRevisao(caixa: 1, proximoDia: 10).codificar()},
      });
      await repo.carregar();
      await _assenta();
      final revisado = fsrs.avaliar(fsrs.novo(9), Rating.good, 10);
      await repo.salvar({'k1': revisado});
      expect((await FirestoreRevisaoRepository('u1', db: db).carregar())['k1'], revisado);
    });

    test('blocos gravados SEM o _meta (offline) + mapa antigo: junta os dois, o novo vence, e conclui a migração', () async {
      await db.collection('users').doc('u1').set({
        'en_revisao': {
          'velha': const CartaoRevisao(caixa: 3, proximoDia: 77).codificar(),
          'nova': const CartaoRevisao(caixa: 1, proximoDia: 5).codificar(),
        },
      });
      final nova = fsrs.novo(500);
      await repo.salvar({'nova': nova}); // criou um bloco antes de a migração rodar
      final r = await FirestoreRevisaoRepository('u1', db: db).carregar();
      await _assenta();
      expect(r['velha']!.proximoDia, 77, reason: 'o cartão antigo NÃO se perde');
      expect(r['nova'], nova);
      expect((await blocos()).containsKey('_meta'), isTrue);
    });

    test('conta nova (sem mapa antigo): marca como migrada e nada se perde depois', () async {
      expect(await repo.carregar(), isEmpty);
      await _assenta();
      expect((await blocos()).keys, ['_meta']);
      await repo.salvar({'k': fsrs.novo(1)});
      expect((await FirestoreRevisaoRepository('u1', db: db).carregar()).keys, ['k']);
    });

    test('quebra na migração (offline) não derruba o carregamento: devolve o convertido', () async {
      // dado inválido no mapa antigo é ignorado, o válido entra
      await db.collection('users').doc('u1').set({
        'en_revisao': {'ok': const CartaoRevisao(caixa: 2, proximoDia: 9).codificar(), 'ruim': 'lixo', 'nulo': null},
      });
      expect((await repo.carregar()).keys, ['ok']);
    });

    test('histórico: um documento por mês, sem duplicar a mesma revisão, filtrável por dia', () async {
      final d1 = Revisao.dia(DateTime(2026, 9, 30)), d2 = Revisao.dia(DateTime(2026, 10, 1));
      await repo.registrarHistorico([EntradaHistorico(d1, 'a', 3), EntradaHistorico(d2, 'a', 1), EntradaHistorico(d2, 'b', 4)]);
      await repo.registrarHistorico([EntradaHistorico(d2, 'b', 4)]); // repetida: não duplica
      final meses = await db.collection('users').doc('u1').collection('srs_log').get();
      expect(meses.docs.map((d) => d.id).toSet(), {'2026-09', '2026-10'});
      final todas = await repo.carregarHistorico();
      expect(todas.length, 3);
      expect(todas.map((e) => e.dia), [d1, d2, d2]);
      expect((await repo.carregarHistorico(desdeDia: d2)).length, 2);
    });

    test('ESCALA: 12 mil cartões ficam em 16 blocos equilibrados, cada um bem abaixo de 1 MiB', () {
      const total = 12000;
      final tamanhos = <String, int>{};
      final contagem = <String, int>{};
      for (var i = 0; i < total; i++) {
        final k = Revisao.chave('Frase de teste número $i, com texto qualquer.');
        final v = fsrs.avaliar(fsrs.novo(i % 400), Rating.good, 1000 + i % 90).codificar();
        final id = FirestoreRevisaoRepository.idDoBloco(k);
        // aproximação do tamanho no Firestore: nome do campo + valor (cada um com 1 byte extra)
        tamanhos[id] = (tamanhos[id] ?? 0) + k.length + 1 + v.length + 1;
        contagem[id] = (contagem[id] ?? 0) + 1;
      }
      expect(contagem.length, FirestoreRevisaoRepository.blocos);
      final maior = contagem.values.reduce((a, b) => a > b ? a : b), menor = contagem.values.reduce((a, b) => a < b ? a : b);
      expect(maior / menor, lessThan(1.35), reason: 'blocos equilibrados: $contagem');
      expect(tamanhos.values.reduce((a, b) => a > b ? a : b), lessThan(100 * 1024), reason: 'cada bloco < 100 KB');
    });
  });

  group('exclusão de conta', () {
    test('leva junto os blocos, o histórico e o ranking — e só os do usuário', () async {
      final db = FakeFirebaseFirestore();
      for (final uid in ['u1', 'u2']) {
        await db.collection('users').doc(uid).set({'concluidas': ['x']});
        await db.collection('ranking').doc(uid).set({'pontos': 1});
        final repo = FirestoreRevisaoRepository(uid, db: db);
        await repo.salvar({for (var i = 0; i < 40; i++) Revisao.chave('$uid $i'): AgendadorFsrs(fuzz: false).novo(i)});
        await repo.registrarHistorico([EntradaHistorico(20000, 'k', 3), EntradaHistorico(20100, 'k', 3)]);
      }
      await apagarDadosDoUsuario(db, 'u1');

      expect((await db.collection('users').doc('u1').get()).exists, isFalse);
      expect((await db.collection('ranking').doc('u1').get()).exists, isFalse);
      expect((await db.collection('users').doc('u1').collection('srs').get()).docs, isEmpty);
      expect((await db.collection('users').doc('u1').collection('srs_log').get()).docs, isEmpty);

      // o outro usuário fica intacto
      expect((await db.collection('users').doc('u2').get()).exists, isTrue);
      expect((await db.collection('ranking').doc('u2').get()).exists, isTrue);
      expect((await FirestoreRevisaoRepository('u2', db: db).carregar()).length, 40);
      expect((await FirestoreRevisaoRepository('u2', db: db).carregarHistorico()).length, 2);
    });
  });
}
