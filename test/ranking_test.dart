import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/ranking/presentation/ranking_cubit.dart';
import 'package:pac_dart/features/ranking/presentation/ranking_page.dart';

/// Repositório de mentira que anota as chamadas (para testar o cubit).
class _RepoFake implements RankingRepository {
  final Map<String, int> doc = {};
  final Map<String, int> recordes = {};
  List<JogadorRanking> respostaTop = [];
  bool falha = false;
  int chamadasSomar = 0;
  Map<String, int>? ultimoDelta;

  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {
    if (falha) throw Exception('offline');
    chamadasSomar++;
    ultimoDelta = deltas;
    deltas.forEach((k, v) => doc[k] = (doc[k] ?? 0) + v);
  }

  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async {
    if (falha) throw Exception('offline');
    if (pontos <= (recordes[jogo] ?? 0)) return false;
    recordes[jogo] = pontos;
    return true;
  }

  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async {
    if (falha) throw Exception('offline');
    return respostaTop;
  }
}

void main() {
  group('FirestoreRankingRepository', () {
    late FakeFirebaseFirestore db;
    late FirestoreRankingRepository repo;

    setUp(() {
      db = FakeFirebaseFirestore();
      repo = FirestoreRankingRepository(db: db);
    });

    test('somar cria o doc com apelido e acumula em chamadas seguidas', () async {
      await repo.somar('u1', 'carlos', {'pontos': 100, 'teclas': 80, 'erros': 5});
      await repo.somar('u1', 'carlos', {'pontos': 50, 'licoes': 1});
      final d = (await db.collection('ranking').doc('u1').get()).data()!;
      expect(d['apelido'], 'carlos');
      expect(d['pontos'], 150);
      expect(d['teclas'], 80);
      expect(d['licoes'], 1);
    });

    test('salvarRecordeArcade guarda só o melhor e diz quando é recorde', () async {
      expect(await repo.salvarRecordeArcade('u1', 'carlos', 'corrida', 120), isTrue);
      expect(await repo.salvarRecordeArcade('u1', 'carlos', 'corrida', 90), isFalse);
      expect(await repo.salvarRecordeArcade('u1', 'carlos', 'corrida', 200), isTrue);
      expect(await repo.salvarRecordeArcade('u1', 'carlos', 'futebol', 60), isTrue);
      final d = (await db.collection('ranking').doc('u1').get()).data()!;
      expect(d['arcade'], {'corrida': 200, 'futebol': 60});
    });

    test('top vem ordenado por pontos, do maior pro menor', () async {
      await repo.somar('u1', 'ana', {'pontos': 50});
      await repo.somar('u2', 'bia', {'pontos': 300});
      await repo.somar('u3', 'caio', {'pontos': 120});
      final top = await repo.top();
      expect(top.map((j) => j.apelido).toList(), ['bia', 'caio', 'ana']);
      expect(top.first.pontos, 300);
    });
  });

  group('JogadorRanking / ordenarRanking', () {
    test('precisão é calculada do volume (e 100 sem volume)', () {
      const zerado = JogadorRanking(uid: 'a', apelido: 'a');
      expect(zerado.precisao, 100);
      const j = JogadorRanking(uid: 'b', apelido: 'b', teclas: 90, erros: 10);
      expect(j.precisao, 90);
      expect(j.volume, 100);
    });

    test('deDados aguenta doc pela metade', () {
      final j = JogadorRanking.deDados('x', {'apelido': 'zé', 'pontos': 7});
      expect(j.pontos, 7);
      expect(j.teclas, 0);
      expect(j.arcadeRecordes, isEmpty);
      expect(j.recordeDoJogo('corrida'), 0);
    });

    test('critério precisão manda quem não tem volume mínimo pro fim', () {
      const veterano =
          JogadorRanking(uid: 'v', apelido: 'vet', teclas: 900, erros: 100, pontos: 500);
      const novato =
          JogadorRanking(uid: 'n', apelido: 'nov', teclas: 10, erros: 0, pontos: 10);
      final ordem = ordenarRanking([novato, veterano], CriterioRanking.precisao);
      // novato tem 100% mas só 10 toques: fica atrás de quem já provou
      expect(ordem.map((j) => j.uid).toList(), ['v', 'n']);
    });

    test('critério geral ordena por pontos', () {
      const a = JogadorRanking(uid: 'a', apelido: 'a', pontos: 10);
      const b = JogadorRanking(uid: 'b', apelido: 'b', pontos: 90);
      expect(ordenarRanking([a, b], CriterioRanking.pontos).first.uid, 'b');
    });
  });

  group('RankingCubit', () {
    late _RepoFake repo;
    late RankingCubit cubit;

    setUp(() {
      repo = _RepoFake();
      cubit = RankingCubit(repo: repo, uid: 'u1', apelido: 'carlos');
    });

    tearDown(() => cubit.close());

    test('licaoConcluida manda só o DELTA desde o último envio', () async {
      await cubit.licaoConcluida(
          const TypingState(score: 100, acertosSessao: 80, errosSessao: 5));
      expect(repo.ultimoDelta, {'pontos': 100, 'teclas': 80, 'erros': 5, 'licoes': 1});

      // a sessão continua acumulando; a segunda lição manda a diferença
      await cubit.licaoConcluida(
          const TypingState(score: 250, acertosSessao: 180, errosSessao: 7));
      expect(repo.ultimoDelta, {'pontos': 150, 'teclas': 100, 'erros': 2, 'licoes': 1});
      expect(repo.doc['pontos'], 250);
      expect(repo.doc['licoes'], 2);
    });

    test('sessão zerada não gera delta negativo', () async {
      await cubit.licaoConcluida(
          const TypingState(score: 100, acertosSessao: 80, errosSessao: 5));
      // contadores voltaram (SessaoZerada): a régua recomeça do zero
      await cubit.licaoConcluida(
          const TypingState(score: 30, acertosSessao: 20, errosSessao: 1));
      expect(repo.ultimoDelta, {'pontos': 30, 'teclas': 20, 'erros': 1, 'licoes': 1});
    });

    test('projetoConcluido manda os números inteiros da tela', () async {
      await cubit.projetoConcluido(
          const TypingState(score: 400, acertosSessao: 350, errosSessao: 12));
      expect(repo.ultimoDelta,
          {'pontos': 400, 'teclas': 350, 'erros': 12, 'projetos': 1});
    });

    test('quiz vale 10 pontos por acerto', () async {
      await cubit.quizRespondido(8, 10);
      expect(repo.ultimoDelta, {'pontos': 80, 'quizAcertos': 8});
    });

    test('arcadeJogado soma pontos e avisa recorde', () async {
      expect(await cubit.arcadeJogado('corrida', 120), isTrue);
      expect(repo.doc['pontos'], 120);
      expect(repo.doc['arcadePontos'], 120);
      expect(await cubit.arcadeJogado('corrida', 90), isFalse); // não bateu
      expect(repo.recordes['corrida'], 120);
    });

    test('escrita que falha fica pendente e entra no próximo envio', () async {
      repo.falha = true;
      await cubit.quizRespondido(5, 10); // perdeu a rede
      expect(repo.doc, isEmpty);

      repo.falha = false;
      await cubit.quizRespondido(3, 10); // voltou: manda o atrasado junto
      expect(repo.doc['pontos'], 80);
      expect(repo.doc['quizAcertos'], 8);
    });

    test('carregarTop emite pronto com a lista (e erro sem rede)', () async {
      repo.respostaTop = const [JogadorRanking(uid: 'u1', apelido: 'carlos', pontos: 9)];
      await cubit.carregarTop();
      expect(cubit.state.status, RankingStatus.pronto);
      expect(cubit.state.jogadores, hasLength(1));
      expect(cubit.state.meu('u1')?.pontos, 9);

      repo.falha = true;
      await cubit.carregarTop();
      expect(cubit.state.status, RankingStatus.erro);
    });
  });

  group('RankingPage', () {
    testWidgets('mostra pódio com medalhas, destaque VOCÊ e troca de critério',
        (tester) async {
      Mixart.usarGoogleFonts = false;
      // viewport alta: o ListView é preguiçoso e o rodapé fica fora da janela
      tester.view.physicalSize = const Size(900, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = _RepoFake()
        ..respostaTop = const [
          JogadorRanking(
              uid: 'u1', apelido: 'ana', pontos: 900, teclas: 800, erros: 40),
          JogadorRanking(
              uid: 'u2', apelido: 'carlos', pontos: 500, teclas: 450, erros: 10),
          JogadorRanking(uid: 'u3', apelido: 'bia', pontos: 100, teclas: 50, erros: 0),
        ];
      final cubit = RankingCubit(repo: repo, uid: 'u2', apelido: 'carlos');

      await tester.pumpWidget(BlocProvider.value(
        value: cubit,
        child: MaterialApp(theme: Mixart.tema(), home: const RankingPage()),
      ));
      await tester.pump();
      await tester.pump();

      expect(find.text('🏆 Ranking dos Jogadores'), findsOneWidget);
      expect(find.text('🥇'), findsWidgets);
      expect(find.text('VOCÊ'), findsOneWidget); // u2 é o dono da sessão
      expect(find.text('ana'), findsWidgets); // 1º lugar no pódio e na lista

      // critério precisão: bia (50 toques) desce pro fim mesmo com 100%
      await tester.tap(find.text('🎯 Precisão'));
      await tester.pump();
      expect(find.textContaining('300+ toques'), findsOneWidget);

      await tester.runAsync(() => cubit.close());
    });
  });
}
