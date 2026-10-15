// Teste de APP da leitura: o PacDartApp inteiro (Inglês) → Mapa → "Ler" → texto → toque numa palavra →
// "Guardar cartão de lacuna" → o cartão está em "Meus cartões" e na revisão vira uma lacuna só.
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
import 'package:pac_dart/features/ingles/data/tradutor.dart';

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

class _TradutorFalso implements Tradutor {
  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir}) async =>
      [for (final f in frases) f == 'sister' ? 'irmã' : 'tradução de $f'];
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
      tradutorBuilder: () => _TradutorFalso(),
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

  testWidgetsDesktop('Mapa → Ler → "Minha manhã" → toca em "sister" → guarda → cartão em "Meus cartões" → na revisão é uma lacuna só', (tester) async {
    final tutor = TutorCenarioFalso();
    final ranking = _Ranking();
    await _abrirApp(tester, tutor, ranking);
    final home = tester.element(find.byType(HomePage));
    final curso = home.read<CursoBloc>();
    final revisao = home.read<RevisaoCubit>();

    await tester.tap(find.text('Mapa'));
    await _anda(tester, 8);
    expect(find.byKey(const Key('ler')), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('ler')));
    await tester.tap(find.byKey(const Key('ler')));
    await _anda(tester, 4);
    await _esperar(tester, find.byKey(const Key('leitura-manha'))); // lê assets/ingles/leituras.json (I/O real)
    await _anda(tester, 3);
    expect(find.text('Minha manhã'), findsOneWidget);
    await tester.tap(find.byKey(const Key('leitura-manha')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('dica-leitura')), findsOneWidget);

    // toca numa palavra da 3ª frase: "Then I have breakfast with my sister."
    await tester.ensureVisible(find.byKey(const Key('palavra-sister')));
    await tester.tap(find.byKey(const Key('palavra-sister')));
    await _anda(tester, 8);
    expect(find.byKey(const Key('folha-palavra')), findsOneWidget);
    expect(find.text('Depois tomo café da manhã com minha irmã.'), findsOneWidget, reason: 'a frase inteira, traduzida');
    expect(tester.widget<Text>(find.byKey(const Key('traducao-palavra'))).data, 'irmã');
    await tester.tap(find.byKey(const Key('guardar-lacuna')));
    await _anda(tester, 12);
    expect(find.text('✓ Cartão guardado em "Meus cartões"'), findsOneWidget);

    final meus = curso.state.trilhas.firstWhere((t) => t.textoId == idCartoesAvulsos);
    final t = meus.licoes.first.trechos.single;
    expect((t.cod, t.alvo, t.alvoPt), ('Then I have breakfast with my sister.', 'sister', 'irmã'));
    expect(revisao.state.config.reversoLigado('txt:$idCartoesAvulsos'), isTrue);
    expect(ranking.somas, 0, reason: 'ler e guardar palavras não vai ao ranking');
    expect(tutor.chamadas, 0, reason: 'nada de IA nem de cota nesta fase');

    // a leitura é um texto da própria pessoa? NÃO: "Meus cartões" não vira texto para ler
    await tester.tapAt(const Offset(20, 20)); // fecha a folha
    await _anda(tester, 16);
    expect(find.byKey(const Key('folha-palavra')), findsNothing);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop(); // da leitura para a lista
    await _anda(tester, 12);
    expect(find.text('SEUS TEXTOS'), findsNothing, reason: '"Meus cartões" não vira texto para ler');
    nav.popUntil((r) => r.isFirst); // volta ao palco
    await _anda(tester, 14);
    await _esperar(tester, find.text('Revisão'));
    await tester.tap(find.text('Revisão'));
    await _anda(tester, 12);
    expect(find.byKey(const Key('lacunas')), findsOneWidget);
    expect(find.text('Depois tomo café da manhã com minha irmã.'), findsOneWidget);
    expect(find.byKey(const Key('lacuna-0')), findsOneWidget);
    expect(find.byKey(const Key('lacuna-1')), findsNothing);
  });
}
