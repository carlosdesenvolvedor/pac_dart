// Testes de APP do "Por quê?": o PacDartApp inteiro (curso de Inglês), com cota e cache no aparelho,
// um Prof. Dash falso e um relógio que o teste controla.
import 'dart:convert';

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
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/domain/habito.dart' show diaDe;
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:pac_dart/features/ia/domain/explicacao.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cubit_test.dart' show TutorFalso;

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

const _frases = [
  Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: '', alvo: "I'm"),
  Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: ''),
  Trecho(cod: 'Where are you from?', dica: 'De onde você é?', out: '', literal: 'Onde você é de?'),
];

final _trilhaEn = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: const [Licao(nome: 'Olá!', emoji: '🙋', trechos: _frases)],
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

class _Relogio {
  DateTime t = DateTime(2026, 10, 13, 10);
  DateTime call() => t;
  void dias(int n) => t = DateTime(t.year, t.month, t.day + n, 10);
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 20 && alvo.evaluate().isEmpty; i++) {
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

Future<void> _abrirApp(WidgetTester tester, _Relogio relogio, TutorFalso tutor, _Ranking ranking,
    {Map<String, Object> prefs = const {}, bool limpar = true}) async {
  if (limpar) SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, ...prefs});
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
      iaAgora: relogio.call,
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
  // a cota vem do aparelho (I/O de verdade): espera ela chegar
  await tester.runAsync(() => tester.element(find.byType(HomePage)).read<IaCubit>().carregar());
  await tester.pump();
}

Future<void> _digita(WidgetTester tester, String texto) async {
  await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, texto);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  await tester.pump();
}

Future<void> _enter(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await _anda(tester, 3);
}

Future<void> _passo(WidgetTester tester, TypingBloc typing) async {
  await _digita(tester, typing.state.chars.join());
  await _anda(tester, 3);
  await _enter(tester);
}

/// Chega ao 1º passo de memória ("Iniciais") e o erra de propósito: 3 palavras com 2 teclas erradas cada.
Future<void> _erraDeMemoria(WidgetTester tester) async {
  final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
  for (var i = 0; i < 3; i++) {
    await _passo(tester, typing); // as 3 cópias
  }
  expect(find.textContaining('Iniciais'), findsOneWidget);
  for (final ch in ['x', 'x', 'H', 'i', ',', ' ', 'z', 'z', 'I', "'", 'm', ' ', 'q', 'q', 'A', 'n', 'a', '.']) {
    await _digita(tester, ch);
  }
  expect(typing.state.concluido, isTrue);
}

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

IaCubit _ia(WidgetTester tester) => tester.element(find.byType(HomePage, skipOffstage: false)).read<IaCubit>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  late TutorFalso tutor;
  late _Ranking ranking;
  late _Relogio relogio;
  setUp(() {
    tutor = TutorFalso();
    ranking = _Ranking();
    relogio = _Relogio();
  });

  testWidgetsDesktop('errou de memória: "Por quê?" explica as palavras certas, gasta 1 e não mexe em nota nem ranking', (tester) async {
    await _abrirApp(tester, relogio, tutor, ranking);
    final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
    // nas 3 cópias (sem nota) o botão não existe
    expect(find.byKey(const Key('por-que')), findsNothing);
    await _passo(tester, typing);
    expect(find.byKey(const Key('por-que')), findsNothing, reason: 'cópia não gera nota nem erro');

    await _passo(tester, typing);
    await _passo(tester, typing);
    for (final ch in ['x', 'x', 'H', 'i', ',', ' ', 'z', 'z', 'I', "'", 'm', ' ', 'q', 'q', 'A', 'n', 'a', '.']) {
      await _digita(tester, ch);
    }
    expect(find.byKey(const Key('por-que')), findsOneWidget, reason: 'errou de memória');

    final cartoesAntes = tester.element(find.byType(HomePage)).read<RevisaoCubit>().state.cartoes;
    await tester.tap(find.byKey(const Key('por-que')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
    expect(tutor.chamadas, 1);
    final ctx = tutor.contextos.single;
    expect(ctx, contains("Hi, I'm Ana."));
    expect(ctx, contains('Oi, eu sou a Ana.'));
    expect(ctx, contains('Palavras em que o aluno errou'));
    expect(_ia(tester).state.restantes, 29);

    // a IA só explica: nada de nota, cartão ou ranking
    expect(tester.element(find.byType(HomePage)).read<RevisaoCubit>().state.cartoes, cartoesAntes);
    expect(ranking.somas, 0);

    // segue o estudo normalmente: a cópia de correção não pede explicação
    await _enter(tester);
    expect(find.textContaining('Correção'), findsOneWidget);
    expect(find.byKey(const Key('por-que')), findsNothing);
  });

  testWidgetsDesktop('o MESMO erro depois (e depois de fechar e reabrir o app) vem do cache: não chama a IA nem gasta cota', (tester) async {
    await _abrirApp(tester, relogio, tutor, ranking);
    await _erraDeMemoria(tester);
    await tester.tap(find.byKey(const Key('por-que')));
    await _anda(tester, 6);
    expect(tutor.chamadas, 1);
    expect(_ia(tester).state.restantes, 29);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 80)));

    // fecha e reabre o app (as mesmas prefs)
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    await _abrirApp(tester, relogio, tutor, ranking, limpar: false);
    expect(_ia(tester).state.restantes, 29, reason: 'a cota gasta voltou do aparelho');
    await _erraDeMemoria(tester);
    await tester.tap(find.byKey(const Key('por-que')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
    expect(tutor.chamadas, 1, reason: 'mesma frase, mesmos erros: veio do cache');
    expect(_ia(tester).state.restantes, 29);
  });

  testWidgetsDesktop('cota esgotada: mensagem gentil; o estudo segue; no dia seguinte a cota volta', (tester) async {
    final hoje = diaDe(relogio.t);
    await _abrirApp(tester, relogio, tutor, ranking, prefs: {'ia_cota_v1:teste-uid': jsonEncode(CotaIa(dia: hoje, usos: 30).toJson())});
    await _anda(tester, 4);
    expect(_ia(tester).state.restantes, 0);
    await _erraDeMemoria(tester);
    await tester.tap(find.byKey(const Key('por-que')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('sem-cota')), findsOneWidget);
    expect(find.textContaining('descansou'), findsOneWidget);
    expect(tutor.chamadas, 0);
    // o estudo não é bloqueado: Enter segue para a correção
    await _enter(tester);
    expect(find.textContaining('Correção'), findsOneWidget);

    // amanhã a cota volta (o app inteiro, com o relógio do teste)
    relogio.dias(1);
    final r = await tester.runAsync(() => _ia(tester).explicar(
        const PedidoExplicacao(frase: 'Nice to meet you.', traducao: 'Prazer.', palavrasErradas: ['meet'])));
    expect(r!.status, StatusIa.ok);
    expect(tutor.chamadas, 1, reason: 'dia novo: a IA volta a ser chamada');
    expect(_ia(tester).state.restantes, 29);
  });

  testWidgetsDesktop('revisão digitada: errou ⇒ "Por quê?"; acertou ⇒ nada', (tester) async {
    await _abrirApp(tester, relogio, tutor, ranking, prefs: {
      'en_revisao': jsonEncode({
        Revisao.chave('Nice to meet you.'): const CartaoRevisao(caixa: 2, proximoDia: 0).codificar(),
      }),
    });
    await _esperar(tester, find.text('Revisão · 1'));
    await tester.tap(find.text('Revisão · 1'));
    await _anda(tester, 8);
    expect(find.byType(SessaoMemoriaPage), findsOneWidget);
    // errou: 3 palavras com 2 teclas erradas cada
    for (final ch in ['x', 'x', 'N', 'i', 'c', 'e', ' ', 'z', 'z', 't', 'o', ' ', 'q', 'q', 'm', 'e', 'e', 't', ' ', 'y', 'y', 'o', 'u', '.']) {
      await _digita(tester, ch);
    }
    expect(find.byKey(const Key('por-que')), findsOneWidget);
    await tester.tap(find.byKey(const Key('por-que')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
    expect(tutor.contextos.single, contains('revisão'));
    expect(tutor.contextos.single, contains('Nice to meet you.'));
  });

  testWidgetsDesktop('revisão digitada acertada: sem botão', (tester) async {
    await _abrirApp(tester, relogio, tutor, ranking, prefs: {
      'en_revisao': jsonEncode({
        Revisao.chave('Nice to meet you.'): const CartaoRevisao(caixa: 2, proximoDia: 0).codificar(),
      }),
    });
    await _esperar(tester, find.text('Revisão · 1'));
    await tester.tap(find.text('Revisão · 1'));
    await _anda(tester, 8);
    await _digita(tester, 'Nice to meet you.');
    await _anda(tester, 3);
    expect(find.byKey(const Key('por-que')), findsNothing);
    expect(tutor.chamadas, 0);
  });

  testWidgetsDesktop('o serviço falha: a mensagem aparece e NÃO gasta cota', (tester) async {
    tutor.erro = Exception('429 RESOURCE_EXHAUSTED');
    await _abrirApp(tester, relogio, tutor, ranking);
    await _erraDeMemoria(tester);
    await tester.tap(find.byKey(const Key('por-que')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('ia-falhou')), findsOneWidget);
    expect(_ia(tester).state.restantes, 30);
    tutor.erro = null;
    await tester.tap(find.byKey(const Key('por-que')));
    await _anda(tester, 6);
    expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
    expect(_ia(tester).state.restantes, 29);
  });
}
