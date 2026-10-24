// 🎓 Teste de APP da aula do professor: o PacDartApp inteiro com uma lição que tem aula. Na 1ª visita a aula abre
// sozinha antes da lição; fechada, a lição segue e o link "🎓 aula do Prof. Beto" fica no cartão; reabrir o app não
// abre de novo (já vista), e com "abrir sozinha" desligado também não.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/ingles/data/aulas_repo.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/aula_professor.dart';
import 'package:pac_dart/features/ingles/presentation/aula_professor_page.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final enviados = <Map<String, int>>[];
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async => enviados.add(deltas);
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

const _frases = [
  Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: ''),
  Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: ''),
  Trecho(cod: 'Where are you from?', dica: 'De onde você é?', out: ''),
];

final _trilhaEn = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: const [Licao(nome: 'Olá!', emoji: '🙋', id: 'primeiros-passos.ola', trechos: _frases)],
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

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 25 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// [limpar]: false reaproveita o que já está nas prefs (simula fechar e reabrir o app).
Future<void> _abrirApp(WidgetTester tester, {Map<String, Object> prefs = const {}, bool limpar = true, Size tela = const Size(1400, 2000)}) async {
  if (limpar) SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, ...prefs});
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: () => _Ranking(),
      habitoBuilder: (u) => LocalHabitoRepository(uid: u.uid),
      curriculoBuilder: (l) => _LoaderEn(),
      linguagemInicial: Linguagem.ingles,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, find.byType(PalcoIngles));
  await _anda(tester, 4);
}

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

const _aula = AulaLicao(titulo: 'Dizer oi', falas: [
  FalaAula(pt: 'Hoje você conhece a Ana.'),
  FalaAula(en: "Hi, I'm Ana.", tr: 'Oi, eu sou a Ana.'),
  FalaAula(pt: 'Agora é com você.'),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() {
    FraseView.carencia = Duration.zero;
    PalcoIngles.aulaSozinha = true;
    AulasRepo.fixas = {'primeiros-passos.ola': _aula};
  });
  tearDown(() {
    Linguagem.atual = Linguagem.dart;
    PalcoIngles.aulaSozinha = false;
    AulasRepo.fixas = null;
  });

  Future<void> fecharAula(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('aula-sair')));
    await _anda(tester, 10);
  }

  testWidgetsDesktop('1ª visita: a aula abre sozinha; fechada, a lição segue e o link fica; reabrir não abre de novo',
      (tester) async {
    await _abrirApp(tester);
    await _esperar(tester, find.byType(AulaProfessorPage));
    expect(find.byType(AulaProfessorPage), findsOneWidget);
    expect(find.text('🎓 Dizer oi'), findsOneWidget);
    expect(find.text('Começar a lição →'), findsOneWidget);
    await fecharAula(tester);
    expect(find.byType(AulaProfessorPage), findsNothing);
    expect(find.byKey(const Key('licao-aula')), findsOneWidget);
    // o link reabre (agora "Praticar")
    await tester.ensureVisible(find.byKey(const Key('licao-aula')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('licao-aula')));
    await _esperar(tester, find.byType(AulaProfessorPage));
    expect(find.text('Praticar a lição →'), findsOneWidget);
    await fecharAula(tester);
    expect(await PrefsAula.jaViu('primeiros-passos.ola'), isTrue);

    // fechar e reabrir o app: já vista, não abre sozinha
    await tester.pumpWidget(const SizedBox());
    await _anda(tester, 4);
    await _abrirApp(tester, limpar: false);
    await _anda(tester, 10);
    expect(find.byType(AulaProfessorPage), findsNothing);
  });

  testWidgetsDesktop('"abrir sozinha" desligado: a lição começa direto, com o link', (tester) async {
    await _abrirApp(tester, prefs: {PrefsAula.chaveAuto: false});
    await _anda(tester, 10);
    expect(find.byType(AulaProfessorPage), findsNothing);
    expect(find.byKey(const Key('licao-aula')), findsOneWidget);
  });

  testWidgetsDesktop('lição sem aula: nada abre e não há link', (tester) async {
    AulasRepo.fixas = {};
    await _abrirApp(tester);
    await _anda(tester, 10);
    expect(find.byType(AulaProfessorPage), findsNothing);
    expect(find.byKey(const Key('licao-aula')), findsNothing);
  });
}
