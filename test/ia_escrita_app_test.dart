// Teste de APP da escrita corrigida (Fase 5): o PacDartApp inteiro (Inglês) → Mapa → "Escrever" → texto → Corrigir
// → erros → "Salvar todos" → os cartões estão em "Meus cartões"; a cota gasta 1; ranking e hábito intactos.
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
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
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

import 'ia_escrita_cubit_test.dart' show TutorEscritaFalso, texto;

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

Future<void> _abrirApp(WidgetTester tester, TutorEscritaFalso tutor, _Ranking ranking) async {
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

  testWidgetsDesktop('Mapa → Escrever: corrige, salva os 2 erros como cartões (sem duplicar), gasta 1 uso, e o mesmo texto não gasta de novo', (tester) async {
    final tutor = TutorEscritaFalso();
    final ranking = _Ranking();
    await _abrirApp(tester, tutor, ranking);
    final home = tester.element(find.byType(HomePage));
    final curso = home.read<CursoBloc>();
    final revisao = home.read<RevisaoCubit>();
    final ia = home.read<IaCubit>();
    final habitoAntes = home.read<HabitoCubit>().state.habito;

    await tester.tap(find.text('Mapa'));
    await _anda(tester, 8);
    expect(find.byKey(const Key('escrever')), findsOneWidget);
    expect(find.text('Escrever e ser corrigido'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('escrever')));
    await tester.tap(find.byKey(const Key('escrever')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('campo-escrita')), findsOneWidget);
    expect(find.text('Restam 30 usos hoje'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('campo-escrita')), texto);
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('corrigir-escrita')));
    await tester.tap(find.byKey(const Key('corrigir-escrita')));
    await _anda(tester, 8);
    expect(find.byKey(const Key('resultado-escrita')), findsOneWidget);
    expect(find.byKey(const Key('erro-escrita-1')), findsOneWidget);
    expect(tutor.chamadas, 1);
    expect(ia.state.restantes, 29);
    expect(curso.state.trilhas.any((t) => t.textoId == idCartoesAvulsos), isFalse, reason: 'nada é salvo sozinho');

    await tester.ensureVisible(find.byKey(const Key('salvar-todos')));
    await tester.tap(find.byKey(const Key('salvar-todos')));
    for (var i = 0; i < 4; i++) {
      await _anda(tester, 8);
    }
    final meus = curso.state.trilhas.firstWhere((t) => t.textoId == idCartoesAvulsos);
    final frases = [for (final l in meus.licoes) ...l.trechos];
    expect(frases.map((t) => t.cod), ['Yesterday I went to the market.', 'I bought some cheese.']);
    expect(frases.map((t) => t.dica), ['Ontem eu fui ao mercado.', 'Eu comprei queijo.']);
    expect(revisao.state.config.reversoLigado('txt:$idCartoesAvulsos'), isTrue, reason: 'o 1º cartão liga o inglês → português');

    // salvar a mesma frase de novo não duplica
    curso.add(const CartaoAdicionado(CartaoEscrito('I bought some cheese.', 'Eu comprei queijo.')));
    await _anda(tester, 8);
    final depois = curso.state.trilhas.firstWhere((t) => t.textoId == idCartoesAvulsos);
    expect([for (final l in depois.licoes) ...l.trechos].length, 2);

    // o mesmo texto de novo: mostra o resultado e não gasta
    await tester.tap(find.byKey(const Key('corrigir-escrita')));
    await _anda(tester, 8);
    expect(tutor.chamadas, 1);
    expect(ia.state.restantes, 29);

    // a IA e a escrita não tocam no ranking nem no hábito
    expect(ranking.somas, 0);
    expect(home.read<HabitoCubit>().state.habito, habitoAntes);
  });
}
