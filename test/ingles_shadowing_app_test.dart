// Teste de APP do shadowing (Fase 3, parte 2): o PacDartApp inteiro (Inglês) → um cartão em "Meus cartões" → Revisão →
// sentido "🗣 Ouvir e repetir" → fala (reconhecedor falso) → confere → nota → o agendador registra; ranking intacto.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cenario_cubit_test.dart' show TutorCenarioFalso;
import 'ingles_shadowing_ui_test.dart' show ReconhecedorFalso;

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

Future<void> _abrirApp(WidgetTester tester, TutorCenarioFalso tutor, _Ranking ranking) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, SessaoCartoesPage.prefSentido: SentidoCartao.shadowing.id});
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
  tearDown(() {
    Linguagem.atual = Linguagem.dart;
    SessaoCartoesPage.fabricaReconhecedor = ReconhecedorFala.navegador;
  });

  Future<(CursoBloc, RevisaoCubit, HabitoCubit, _Ranking)> prepararCartao(WidgetTester tester, ReconhecedorFalso rec) async {
    SessaoCartoesPage.fabricaReconhecedor = () => rec;
    final tutor = TutorCenarioFalso();
    final ranking = _Ranking();
    await _abrirApp(tester, tutor, ranking);
    final home = tester.element(find.byType(HomePage));
    final curso = home.read<CursoBloc>();
    final revisao = home.read<RevisaoCubit>();
    // um cartão em "Meus cartões", com o sentido inglês → português ligado (é de onde saem os cartões de virar)
    curso.add(const CartaoAdicionado(CartaoEscrito('Nice to meet you, Mike.', 'Prazer em te conhecer, Mike.')));
    await _anda(tester, 10);
    await tester.runAsync(() => revisao.mudarConfig(revisao.state.config.comReversos(['txt:$idCartoesAvulsos'], ligar: true)));
    await _anda(tester, 4);
    return (curso, revisao, home.read<HabitoCubit>(), ranking);
  }

  testWidgetsDesktop('Revisão → 🗣: ouve, erra uma palavra, acerta na 2ª, vira sugerindo Difícil, a nota vai ao agendador e ao hábito', (tester) async {
    final rec = ReconhecedorFalso();
    final (_, revisao, habito, ranking) = await prepararCartao(tester, rec);
    final habitoAntes = habito.state.habito;
    expect(revisao.state.cartoes, isEmpty);

    await _esperar(tester, find.text('Revisão'));
    await tester.tap(find.text('Revisão'));
    await _anda(tester, 12);
    expect(find.byKey(const Key('frente-shadowing')), findsOneWidget);
    expect(find.textContaining('Nice to meet'), findsNothing, reason: 'a frase não aparece antes de falar');

    await tester.tap(find.byKey(const Key('shadowing-falar')));
    await _anda(tester, 2);
    rec.escutas.last.falou(['nice to meet you']);
    await _anda(tester, 2);
    expect(find.byKey(const Key('verso-cartao')), findsNothing, reason: 'faltou "Mike": ainda tem tentativa');
    expect(find.textContaining('Restam 2 tentativas'), findsOneWidget);

    await tester.tap(find.byKey(const Key('shadowing-falar')));
    await _anda(tester, 2);
    rec.escutas.last.falou(['nice to meet you mike']);
    await _anda(tester, 4);
    expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
    expect(find.text('Nice to meet you, Mike.'), findsWidgets);
    expect(find.descendant(of: find.byKey(const Key('nota-dificil')), matching: find.textContaining('sugerida')), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.space); // aceita a sugestão
    await _anda(tester, 8);
    final chave = revisao.state.cartoes.keys.single;
    expect(chave.endsWith('~r'), isTrue, reason: 'é o cartão do sentido inverso');
    expect(revisao.state.cartoes[chave]!.estabilidade, greaterThan(1), reason: 'Difícil num cartão novo: a memória começa com mais de 1 dia de estabilidade');
    expect(habito.state.habito, isNot(habitoAntes), reason: 'a nota do cartão conta 1 exercício no hábito, como sempre');
    expect(ranking.somas, 0, reason: 'o shadowing não vai ao ranking');
  });

  testWidgetsDesktop('Revisão → 🗣 "Mostrar a frase": a nota Errei vai ao agendador', (tester) async {
    final rec = ReconhecedorFalso();
    final (_, revisao, _, _) = await prepararCartao(tester, rec);
    await _esperar(tester, find.text('Revisão'));
    await tester.tap(find.text('Revisão'));
    await _anda(tester, 12);
    await tester.tap(find.byKey(const Key('shadowing-mostrar')));
    await _anda(tester, 4);
    expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nota-errei')));
    await _anda(tester, 8);
    final chave = revisao.state.cartoes.keys.single;
    expect(revisao.state.cartoes[chave]!.estabilidade, lessThan(1), reason: 'Errei num cartão novo: a memória começa com menos de 1 dia (volta logo)');
  });

  testWidgetsDesktop('Revisão sem reconhecimento de voz: o cartão vira ditado e a nota segue valendo', (tester) async {
    final rec = ReconhecedorFalso(ok: false);
    final (_, revisao, _, _) = await prepararCartao(tester, rec);
    await _esperar(tester, find.text('Revisão'));
    await tester.tap(find.text('Revisão'));
    await _anda(tester, 12);
    expect(find.byKey(const Key('frente-audio')), findsOneWidget);
    expect(find.byKey(const Key('painel-shadowing')), findsNothing);
    expect(find.textContaining('Sem voz neste aparelho'), findsOneWidget);
    await tester.tap(find.text('Não sei'));
    await _anda(tester, 4);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _anda(tester, 8);
    expect(revisao.state.cartoes.length, 1);
  });
}
