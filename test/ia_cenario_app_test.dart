// Teste de APP dos cenários guiados: o PacDartApp inteiro (Inglês) → Mapa → "Conversar" → cenário
// → conversa → feedback → "Salvar como cartão" → o cartão está no baralho "Meus cartões".
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
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cenario_cubit_test.dart' show TutorCenarioFalso;

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
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
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
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgetsDesktop('Mapa → Conversar → café: conversa, feedback e frase salva como cartão (sem duplicar), com a cota gasta', (tester) async {
    final tutor = TutorCenarioFalso();
    final ranking = _Ranking();
    await _abrirApp(tester, tutor, ranking);
    final home = tester.element(find.byType(HomePage));
    final curso = home.read<CursoBloc>();
    final revisao = home.read<RevisaoCubit>();
    final ia = home.read<IaCubit>();

    await tester.tap(find.text('Mapa'));
    await _anda(tester, 8);
    expect(find.byKey(const Key('conversar')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('conversar')));
    await tester.tap(find.byKey(const Key('conversar')));
    await _anda(tester, 4);
    await _esperar(tester, find.byKey(const Key('cenario-cafe'))); // lê assets/ingles/cenarios.json (I/O real)
    await _anda(tester, 3);
    expect(find.text('Pedir um café'), findsOneWidget);
    expect(find.text('Restam 30 usos hoje'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cenario-cafe')));
    await _anda(tester, 8);
    expect(find.text('Hi! Welcome to Sunny Beans. What can I get for you?'), findsOneWidget);

    for (final f in ['I want a coffee.', 'A small one.', 'Thank you.']) {
      await tester.enterText(find.byKey(const Key('campo-conversa')), f);
      await tester.tap(find.byKey(const Key('enviar-conversa')));
      await _anda(tester, 6);
      expect(find.text(f), findsOneWidget);
    }
    expect(tutor.chamadas, 3);
    expect(ia.state.restantes, 27);
    expect(find.byKey(const Key('feedback-cenario')), findsNothing, reason: 'sem correção no meio da conversa');

    await tester.tap(find.byKey(const Key('terminar-conversa')));
    await _anda(tester, 8);
    expect(find.byKey(const Key('feedback-cenario')), findsOneWidget);
    expect(ia.state.restantes, 26);

    // salva a 1ª frase como cartão
    expect(curso.state.trilhas.any((t) => t.textoId == idCartoesAvulsos), isFalse);
    await tester.ensureVisible(find.byKey(const Key('salvar-cartao-0')));
    await tester.tap(find.byKey(const Key('salvar-cartao-0')));
    await _anda(tester, 10);
    expect(find.text('✓ Salvo'), findsOneWidget);
    final meus = curso.state.trilhas.firstWhere((t) => t.textoId == idCartoesAvulsos);
    final frases = [for (final l in meus.licoes) ...l.trechos];
    expect(frases.map((t) => t.cod), ['A small latte, please.']);
    expect(frases.single.dica, 'Um latte pequeno, por favor.');
    expect(revisao.state.config.reversoLigado('txt:$idCartoesAvulsos'), isTrue, reason: 'o 1º cartão liga o inglês → português');

    // segunda frase: entra no mesmo baralho; a mesma frase de novo NÃO duplica
    await tester.ensureVisible(find.byKey(const Key('salvar-cartao-1')));
    await tester.tap(find.byKey(const Key('salvar-cartao-1')));
    await _anda(tester, 10);
    curso.add(CartaoAdicionado(const CartaoEscrito('A small latte, please.', 'Um latte pequeno, por favor.')));
    await _anda(tester, 8);
    final depois = curso.state.trilhas.firstWhere((t) => t.textoId == idCartoesAvulsos);
    expect([for (final l in depois.licoes) ...l.trechos].map((t) => t.cod), ['A small latte, please.', 'How much is it?']);

    // a IA e a conversa não tocam no ranking nem criam cartão de revisão por conta própria
    expect(ranking.somas, 0);
  });
}
