// Teste de APP do lembrete diário (Fase 1B): o PacDartApp inteiro (Inglês) com um agendador falso "disponível":
// liga o lembrete pela folha "Sua sequência" → permissão → 7 dias agendados → bater a meta tira hoje → ranking/hábito intactos.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/data/lembrete_repository.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/habito/presentation/lembrete_cubit.dart';
import 'package:pac_dart/features/habito/presentation/widgets/chip_sequencia.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cenario_cubit_test.dart' show TutorCenarioFalso;
import 'lembrete_cubit_test.dart' show AgendadorFalso;

class _AuthFake implements AuthRepository {
  static const _user = AppUser(uid: 'teste-uid', email: 'teste@pac.dart');
  @override
  Stream<AppUser?> get mudancas => Stream.value(_user);
  @override
  AppUser? get atual => _user;
  @override
  Future<void> entrar(String email, String senha) async {}
  @override
  Future<void> cadastrar(String email, String senha) async {}
  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async {}
}

class _Ranking implements RankingRepository {
  int somas = 0;
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async => somas++;
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

final _trilhaEn = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: const [
    Licao(nome: 'Olá!', emoji: '🙋', trechos: [Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: '')]),
  ],
);

class _LoaderEn extends CurriculoLoader {
  _LoaderEn() : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => [_trilhaEn];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 25 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

Future<void> _abrirApp(WidgetTester tester, TutorCenarioFalso tutor, _Ranking ranking, AgendadorFalso agendador,
    {DateTime Function()? agora, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, ...prefs});
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: () => ranking,
      habitoBuilder: (u) => LocalHabitoRepository(uid: u.uid),
      habitoAgora: agora,
      lembreteBuilder: (u) => LocalLembreteRepository(uid: u.uid),
      agendadorBuilder: () => agendador,
      tutorBuilder: () => tutor,
      iaCotaBuilder: (u) => LocalCotaRepository(uid: u.uid),
      curriculoBuilder: (l) => _LoaderEn(),
      linguagemInicial: Linguagem.ingles,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, find.byType(PalcoIngles));
  await _anda(tester, 3);
  await tester.runAsync(() => tester.element(find.byType(HomePage)).read<IaCubit>().carregar());
}

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgetsDesktop('chip → folha → liga o lembrete (permissão) → 7 dias; bater a meta tira hoje; nada de ranking', (tester) async {
    final ranking = _Ranking();
    final ag = AgendadorFalso();
    var agora = DateTime(2026, 10, 13, 10);
    await _abrirApp(tester, TutorCenarioFalso(), ranking, ag, agora: () => agora);
    final home = tester.element(find.byType(HomePage));
    final habito = home.read<HabitoCubit>();
    final lembrete = home.read<LembreteCubit>();
    await tester.runAsync(lembrete.carregar);
    await _anda(tester, 4);
    expect(lembrete.state.disponivel, isTrue);
    expect(lembrete.state.config.ligado, isFalse);
    expect(ag.permissoes, 0, reason: 'abrir o app não pede permissão');
    expect(ag.ultima, isEmpty, reason: 'desligado: nada agendado');

    // a folha "Sua sequência" (toque no chip do cabeçalho)
    await tester.tap(find.byType(ChipSequencia));
    await _anda(tester, 8);
    expect(find.byKey(const Key('sequencia-sheet')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('lembrete-switch')));
    await tester.tap(find.byKey(const Key('lembrete-switch')));
    await _anda(tester, 8);
    expect(ag.permissoes, 1);
    expect(tester.widget<Switch>(find.byKey(const Key('lembrete-switch'))).value, isTrue);
    expect(find.text('Todo dia às 20:00 — só se a meta do dia ainda não foi batida.'), findsOneWidget);
    expect(ag.ultima.length, 7);
    expect(ag.ultima.first.quando, DateTime(2026, 10, 13, 20));

    // um exercício que não bate a meta não reagenda
    final n = ag.listas.length;
    habito.praticou(5);
    await _anda(tester, 4);
    expect(ag.listas.length, n);

    // bater a meta de hoje (20) tira o lembrete de HOJE e deixa os outros 6
    habito.praticou(15);
    await _anda(tester, 6);
    expect(ag.ultima.length, 6);
    expect(ag.ultima.first.quando, DateTime(2026, 10, 14, 20));

    // virou o dia: o lembrete de hoje volta a valer
    agora = DateTime(2026, 10, 14, 9);
    habito.praticou(1);
    await _anda(tester, 6);
    expect(ag.ultima.length, 7);
    expect(ag.ultima.first.quando, DateTime(2026, 10, 14, 20));

    expect(ranking.somas, 0, reason: 'o lembrete e o hábito não vão ao ranking');
  });

  testWidgetsDesktop('sem suporte (web/desktop): a folha só explica e nada é agendado', (tester) async {
    final ag = AgendadorFalso(disponivel: false);
    await _abrirApp(tester, TutorCenarioFalso(), _Ranking(), ag);
    await tester.tap(find.byType(ChipSequencia));
    await _anda(tester, 8);
    await tester.ensureVisible(find.byKey(const Key('lembrete-indisponivel')));
    expect(find.byKey(const Key('lembrete-indisponivel')), findsOneWidget);
    expect(find.byKey(const Key('lembrete-switch')), findsNothing);
    expect(ag.eventos, isEmpty);
  });

  testWidgetsDesktop('abrir o app com o lembrete ligado de antes: RENOVA os 7 dias sem precisar abrir a folha', (tester) async {
    final ag = AgendadorFalso();
    await _abrirApp(tester, TutorCenarioFalso(), _Ranking(), ag,
        agora: () => DateTime(2026, 10, 13, 10),
        prefs: {'lembrete_v1:teste-uid': '{"v":1,"ligado":true,"hora":19,"minuto":30}'});
    await _anda(tester, 8);
    // (nenhum toque no chip, nenhum `read<LembreteCubit>`: o cubit tem de ter nascido sozinho)
    expect(ag.listas, isNotEmpty, reason: 'o lembrete não pode ser preguiçoso: nasce na abertura do app');
    expect(ag.ultima.length, 7);
    expect(ag.ultima.first.quando, DateTime(2026, 10, 13, 19, 30));
    expect(ag.permissoes, 0);
  });
}
