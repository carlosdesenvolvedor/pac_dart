// Testes de APP do "⚡ Treino do dia" (FASE-9, grupo E): o PacDartApp inteiro, com o plano de cada curso
// guardado no aparelho (`LocalTreinoDiaRepository`) e o relógio do hábito controlado pelo teste.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/linguagem/linguagem_cubit.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/quiz.dart';
import 'package:pac_dart/features/curso/presentation/fluxo_licao.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/quiz_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/treino_dia/data/treino_dia_repository.dart';
import 'package:pac_dart/features/treino_dia/domain/plano_treino.dart';
import 'package:pac_dart/features/treino_dia/presentation/treino_dia_cubit.dart';
import 'package:pac_dart/features/treino_dia/presentation/treino_dia_page.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _uid = 'teste-uid';

class _AuthFake implements AuthRepository {
  static const _user = AppUser(uid: _uid, email: 'teste@pac.dart');
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
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}
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
    Licao(nome: 'Olá!', emoji: '🙋', id: 'pp.ola', trechos: [
      Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: ''),
      Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: ''),
    ]),
    Licao(nome: 'Como vai?', emoji: '😊', id: 'pp.como-vai', trechos: [
      Trecho(cod: 'How are you?', dica: 'Como você está?', out: ''),
    ]),
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

final _trilhaDart = Trilha(
  nivel: 'Fundamentos',
  emoji: '🌱',
  licoes: const [
    Licao(nome: 'Variáveis', emoji: '🅰', trechos: [Trecho(cod: 'var a = 1;', dica: 'digite', out: 'ok')]),
    Licao(nome: 'Funções', emoji: '🅵', trechos: [Trecho(cod: 'void f() {}', dica: 'digite', out: 'ok')]),
  ],
);

class _LoaderDart extends CurriculoLoader {
  _LoaderDart() : super(linguagem: Linguagem.dart);
  @override
  Future<List<Trilha>> carregar() async => [_trilhaDart];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

/// Um currículo qualquer para [linguagem] (Dart ou C#), sem asset.
class _LoaderDe extends CurriculoLoader {
  _LoaderDe(Linguagem l, this.trilhas) : super(linguagem: l);
  final List<Trilha> trilhas;
  @override
  Future<List<Trilha>> carregar() async => trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

Trecho _tr(String cod, String dica) => Trecho(cod: cod, dica: dica, out: 'ok');

/// Lições com trechos o bastante para gerar quiz (≥ 4 códigos distintos: 1 certo + 3 distratores).
final _trilhaComQuiz = Trilha(
  nivel: 'Fundamentos',
  emoji: '🌱',
  licoes: [
    Licao(nome: 'Variáveis', emoji: '🅰', trechos: [
      _tr('var a = 1;', 'cria a valendo 1'),
      _tr('final b = 2;', 'cria b fixo em 2'),
      _tr('const c = 3;', 'cria a constante c'),
      _tr('int d = 4;', 'cria d inteiro'),
    ]),
    Licao(nome: 'Funções', emoji: '🅵', trechos: [
      _tr('void f() {}', 'declara f sem retorno'),
      _tr('int g() => 1;', 'g devolve 1'),
      _tr('f();', 'chama f'),
      _tr('print(g());', 'mostra o valor de g'),
    ]),
    Licao(nome: 'Listas', emoji: '📦', trechos: [
      _tr("var l = [1, 2];", 'cria uma lista'),
      _tr('l.add(3);', 'põe 3 no fim'),
      _tr('l.removeAt(0);', 'tira o primeiro'),
      _tr('print(l.length);', 'mostra o tamanho'),
    ]),
  ],
);

/// O relógio do app (hábito e treino): o teste vira o dia quando quiser.
class _Relogio {
  DateTime t = DateTime(2026, 10, 21, 10);
  DateTime call() => t;
}

Future<void> _esperar(WidgetTester tester, Finder alvo, {int vezes = 40}) async {
  for (var i = 0; i < vezes && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

Future<void> _abrirApp(WidgetTester tester, _Relogio relogio,
    {required Linguagem inicial,
    Map<String, Object> prefs = const {},
    Size tela = const Size(1400, 2000),
    Map<Linguagem, List<Trilha>> curriculos = const {}}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, ...prefs});
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      palavrasBuilder: (_) => MemoriaPalavrasRepository(),
      setlistsBuilder: (_) => MemoriaSetlistsRepository(),
      rankingBuilder: () => _Ranking(),
      habitoBuilder: (_) => LocalHabitoRepository(),
      habitoAgora: relogio.call,
      treinoDiaBuilder: (u, l) => LocalTreinoDiaRepository(uid: u.uid, curso: l.id),
      curriculoBuilder: (l) => curriculos[l] != null
          ? _LoaderDe(l, curriculos[l]!)
          : l == Linguagem.ingles
              ? _LoaderEn()
              : _LoaderDart(),
      linguagemInicial: inicial,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, find.byKey(const Key('treino-dia-hud')));
}

void testWidgetsDesktop(String descricao, WidgetTesterCallback corpo) =>
    testWidgets(descricao, corpo, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

final _hud = find.byKey(const Key('treino-dia-hud'));

/// O rótulo do botão do HUD ("Treino", "Treino 1/2", "Treino ✓").
String _rotuloHud(WidgetTester tester) =>
    tester.widget<Text>(find.descendant(of: _hud, matching: find.byType(Text))).data!;

/// Espera o rótulo do HUD virar [rotulo] (o plano do curso carrega do aparelho logo depois de abrir).
Future<void> _esperarRotulo(WidgetTester tester, String rotulo) async {
  for (var i = 0; i < 40 && (_hud.evaluate().isEmpty || _rotuloHud(tester) != rotulo); i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(_rotuloHud(tester), rotulo);
}

/// Deixa a transição de rota (empurrar ou voltar) terminar: no macOS ela desliza ~400 ms.
Future<void> _transicao(WidgetTester tester) async {
  await _anda(tester, 2);
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

TreinoDiaCubit _treino(WidgetTester tester) =>
    tester.element(find.byType(HomePage, skipOffstage: false)).read<TreinoDiaCubit>();

HabitoCubit _habito(WidgetTester tester) =>
    tester.element(find.byType(HomePage, skipOffstage: false)).read<HabitoCubit>();

/// Abre o treino pelo HUD e espera o hub (ou a tela final) aparecer.
Future<void> _abrirTreino(WidgetTester tester) async {
  await tester.tap(_hud);
  await _transicao(tester);
  expect(find.byKey(const Key('treino-dia-pagina')), findsOneWidget);
  // o hub (`treino-dia-lista`) ou, com o plano já completo, a tela final
  await _esperar(
      tester,
      find.byWidgetPredicate(
          (w) => w.key == const Key('treino-dia-lista') || w.key == const Key('treino-dia-fim')));
  expect(find.byKey(const Key('treino-dia-montando')), findsNothing);
}

/// "Pular esta etapa" até o plano acabar.
Future<void> _pularTudo(WidgetTester tester) async {
  for (var i = 0; i < 8 && find.byKey(const Key('treino-dia-fim')).evaluate().isEmpty; i++) {
    final pular = find.byKey(const Key('treino-dia-pular'));
    await tester.ensureVisible(pular);
    await tester.tap(pular);
    await _anda(tester, 2);
  }
  expect(find.byKey(const Key('treino-dia-fim')), findsOneWidget);
}

Future<void> _fecharTreino(WidgetTester tester) async {
  final fechar = find.byKey(const Key('treino-dia-fechar'));
  await tester.ensureVisible(fechar);
  await tester.tap(fechar);
  await _transicao(tester);
  expect(find.byType(TreinoDiaPage), findsNothing);
}

/// Troca de curso como o seletor faz (o LinguagemCubit da conta).
Future<void> _trocarCurso(WidgetTester tester, Linguagem l) async {
  await tester.runAsync(() => tester.element(find.byType(HomePage)).read<LinguagemCubit>().escolher(l));
  await _anda(tester, 4);
  await _esperar(tester, _hud);
}

/// Um plano gravado no aparelho, como o `LocalTreinoDiaRepository` guardaria.
MapEntry<String, Object> _planoGravado(String curso, PlanoTreino p) =>
    MapEntry(LocalTreinoDiaRepository(uid: _uid, curso: curso).chave, jsonEncode(p.toJson()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  final hoje = diaDe(DateTime(2026, 10, 21, 10));

  testWidgetsDesktop('inglês: "Treino" no HUD → monta, pula tudo → fim; HUD "Treino ✓"; meia-noite → "Treino"',
      (tester) async {
    final relogio = _Relogio();
    await _abrirApp(tester, relogio, inicial: Linguagem.ingles);
    await _esperarRotulo(tester, 'Treino');

    await _abrirTreino(tester);
    // aluno novo: sem revisão nem palavras, o plano é 🎧 Ouvir + 🏁 Rali (curto)
    final plano = _treino(tester).planoDeHoje!;
    expect(plano.curso, 'ingles');
    expect([for (final b in plano.blocos) b.tipo], [TipoBloco.ouvir, TipoBloco.rali]);
    expect(find.byKey(const Key('treino-dia-curto')), findsOneWidget);

    await _pularTudo(tester);
    expect(find.text('Hoje foi só uma passada'), findsOneWidget);
    await _fecharTreino(tester);
    await _esperarRotulo(tester, 'Treino ✓');
    expect(_habito(tester).state.habito.unidadesHoje, 0, reason: 'pular não dá bônus nem unidades');

    // passa da meia-noite: o relógio do HUD (1 s) relê o plano de hoje, que ainda não existe
    // (o relógio do Hud nasceu dentro do runAsync da abertura: é um Timer de verdade, então espera 1 s real)
    relogio.t = DateTime(2026, 10, 22, 0, 1);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1200)));
    await tester.pump();
    expect(_rotuloHud(tester), 'Treino');
    expect(_treino(tester).planoDeHoje, isNull, reason: 'o plano guardado é de ontem');
  });

  testWidgetsDesktop('Dart: o plano tem 🏁 Rali e nenhum 🎧 Ouvir; o cartão do mapa abre o treino', (tester) async {
    final relogio = _Relogio();
    await _abrirApp(tester, relogio, inicial: Linguagem.dart);
    await _esperarRotulo(tester, 'Treino');

    await _abrirTreino(tester);
    final plano = _treino(tester).planoDeHoje!;
    expect(plano.curso, 'dart');
    expect(plano.blocos.any((b) => b.tipo == TipoBloco.rali), isTrue);
    expect(plano.blocos.any((b) => b.tipo == TipoBloco.ouvir), isFalse);
    expect(find.byKey(const Key('treino-dia-bloco-rali')), findsOneWidget);
    expect(find.byKey(const Key('treino-dia-bloco-ouvir')), findsNothing);

    // fecha pelo X e entra pelo mapa
    await tester.tap(find.byTooltip('Fechar o treino'));
    await _transicao(tester);
    await tester.tap(find.text('Mapa'));
    await _transicao(tester);
    await _esperar(tester, find.byType(MapaPage));
    final cartao = find.byKey(const Key('treino-dia-cartao-mapa'));
    await _esperar(tester, cartao);
    expect(cartao, findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('treino-dia-cartao-mapa-sub'))).data,
        '~10 min com o que você precisa revisar hoje');
    await tester.ensureVisible(cartao);
    await tester.tap(cartao);
    await _transicao(tester);
    expect(find.byType(TreinoDiaPage), findsOneWidget);
  });

  testWidgetsDesktop('o cartão do mapa existe no inglês e segue o andamento ("Continuar · 1 de 2 etapas")',
      (tester) async {
    final relogio = _Relogio();
    await _abrirApp(tester, relogio, inicial: Linguagem.ingles);
    await _abrirTreino(tester);
    final pular = find.byKey(const Key('treino-dia-pular'));
    await tester.ensureVisible(pular);
    await tester.tap(pular);
    await _anda(tester, 2);
    await tester.tap(find.byTooltip('Fechar o treino'));
    await _transicao(tester);
    await _esperarRotulo(tester, 'Treino 1/2');

    await tester.tap(find.text('Mapa'));
    await _transicao(tester);
    final cartao = find.byKey(const Key('treino-dia-cartao-mapa'));
    await _esperar(tester, cartao);
    expect(cartao, findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('treino-dia-cartao-mapa-sub'))).data,
        'Continuar · 1 de 2 etapas');

    // o mapa fica aberto e passa da meia-noite: o cartão vira junto com o HUD, sem o cubit emitir
    // (o tique do cartão nasceu fora do runAsync: é um Timer de mentira, anda com o pump)
    relogio.t = DateTime(2026, 10, 22, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<Text>(find.byKey(const Key('treino-dia-cartao-mapa-sub'))).data,
        '~10 min com o que você precisa revisar hoje');
  });

  testWidgetsDesktop('trocar de curso: cada curso guarda o próprio plano', (tester) async {
    final relogio = _Relogio();
    await _abrirApp(tester, relogio, inicial: Linguagem.ingles);
    await _abrirTreino(tester);
    final pular = find.byKey(const Key('treino-dia-pular'));
    await tester.ensureVisible(pular);
    await tester.tap(pular);
    await _anda(tester, 2);
    await tester.tap(find.byTooltip('Fechar o treino'));
    await _transicao(tester);
    await _esperarRotulo(tester, 'Treino 1/2');

    await _trocarCurso(tester, Linguagem.dart);
    await _esperarRotulo(tester, 'Treino');
    expect(_treino(tester).curso, 'dart');
    expect(_treino(tester).planoDeHoje, isNull, reason: 'o Dart ainda não montou o dele');

    await _trocarCurso(tester, Linguagem.ingles);
    await _esperarRotulo(tester, 'Treino 1/2');
    expect(_treino(tester).curso, 'ingles');
  });

  testWidgetsDesktop('bônus 1× por conta: inglês completo dá +3; o Dart completo no mesmo dia dá +0 e avisa',
      (tester) async {
    final relogio = _Relogio();
    // os dois planos de hoje já com 2 etapas ativas feitas; falta só o 🏁 Rali (pulado pelo teste)
    final en = PlanoTreino(dia: hoje, curso: 'ingles', blocos: const [
      BlocoTreino(id: 'revisao', tipo: TipoBloco.revisao, estado: EstadoBloco.feito, qtd: 3, resultado: 3),
      BlocoTreino(id: 'palavras', tipo: TipoBloco.palavras, estado: EstadoBloco.feito, qtd: 4, resultado: 4),
      BlocoTreino(id: 'rali', tipo: TipoBloco.rali, minutos: 2),
    ]);
    final dart = PlanoTreino(dia: hoje, curso: 'dart', blocos: const [
      BlocoTreino(id: 'quiz:0:0', tipo: TipoBloco.quiz, estado: EstadoBloco.feito, qtd: 10, minutos: 4, resultado: 7, total: 10, t: 0, l: 0),
      BlocoTreino(id: 'quiz:0:1', tipo: TipoBloco.quiz, estado: EstadoBloco.feito, qtd: 10, minutos: 4, resultado: 9, total: 10, t: 0, l: 1),
      BlocoTreino(id: 'rali', tipo: TipoBloco.rali, minutos: 2),
    ]);
    await _abrirApp(tester, relogio,
        inicial: Linguagem.ingles, prefs: Map.fromEntries([_planoGravado('ingles', en), _planoGravado('dart', dart)]));
    await _esperarRotulo(tester, 'Treino 2/3');

    await _abrirTreino(tester);
    await _pularTudo(tester);
    expect(find.text('Treino do dia completo! ⚡'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('treino-dia-bonus'))).data, '+3 na meta pelo treino completo ⚡');
    expect(_habito(tester).state.habito.unidadesHoje, 3);
    await _fecharTreino(tester);
    await _esperarRotulo(tester, 'Treino ✓');

    await _trocarCurso(tester, Linguagem.dart);
    await _esperarRotulo(tester, 'Treino 2/3');
    await _abrirTreino(tester);
    expect(find.text('Quiz · Variáveis'), findsOneWidget);
    await _pularTudo(tester);
    expect(find.text('Treino do dia completo! ⚡'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('treino-dia-bonus'))).data, 'Bônus do treino já ganho hoje ✓');
    expect(_habito(tester).state.habito.unidadesHoje, 3, reason: 'o bônus é 1× por conta por dia');
    expect(_treino(tester).planoDeHoje!.bonus, isTrue, reason: 'o plano passou pelo bônus (não tenta de novo)');
    await _fecharTreino(tester);
    await _esperarRotulo(tester, 'Treino ✓');
  });

  for (final l in [Linguagem.dart, Linguagem.csharp]) {
    testWidgetsDesktop('${l.id}: lições concluídas → 🧩 quiz + 🧩 quiz + 🏁 Rali; o 1º quiz respondido → "Treino 1/3"',
        (tester) async {
      final relogio = _Relogio();
      final pre = l.prefixoProgresso;
      // as 3 lições concluídas; a 3ª nunca fez quiz, a 2ª tem a pior nota → [quiz:0:2, quiz:0:1, rali]
      await _abrirApp(tester, relogio,
          inicial: l,
          curriculos: {l: [_trilhaComQuiz]},
          prefs: {
            '${pre}concluidas': ['0:0', '0:1', '0:2', 'proj:0:0'],
            '${pre}quiz_notas': ['0:0=90', '0:1=40'],
          });
      await _esperarRotulo(tester, 'Treino');

      await _abrirTreino(tester);
      final plano = _treino(tester).planoDeHoje!;
      expect(plano.curso, l.id);
      expect([for (final b in plano.blocos) b.id], ['quiz:0:2', 'quiz:0:1', 'rali']);
      expect(plano.curto, isFalse);
      expect(plano.incompleto, isFalse);
      expect(find.byKey(const Key('treino-dia-curto')), findsNothing);
      expect(find.text('Quiz · Listas'), findsOneWidget);
      expect(find.text('Quiz · Funções'), findsOneWidget);
      expect(find.text('1 fase digitando código · ~2 min'), findsOneWidget);

      // ▶ Começar → o quiz da lição "Listas", fora da sequência, com a semente do dia
      await tester.tap(find.byKey(const Key('treino-dia-comecar')));
      await _transicao(tester);
      final q = tester.widget<QuizPage>(find.byType(QuizPage));
      expect((q.trilhaIdx, q.licaoIdx, q.emSequencia, q.rotuloFim), (0, 2, false, 'Continuar o treino →'));
      expect(q.semente, sementeQuiz(0, 2) ^ (hoje * 7919));
      expect(find.text('Pular quiz'), findsNothing);

      // responde tudo de verdade (cada resposta conta no hábito) e volta pelo botão principal
      final perguntas = gerarQuiz(_trilhaComQuiz.licoes[2], poolDaTrilha(_trilhaComQuiz), seed: q.semente!);
      for (final p in perguntas) {
        await tester.tap(find.text(String.fromCharCode(65 + p.correta)));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
      }
      await _anda(tester, 2);
      final continuar = find.text('Continuar o treino →');
      await tester.ensureVisible(continuar);
      await tester.tap(continuar);
      await _transicao(tester);
      expect(find.byType(QuizPage), findsNothing);
      final depois = _treino(tester).planoDeHoje!;
      expect(depois.blocos.first.estado, EstadoBloco.feito);
      expect((depois.blocos.first.resultado, depois.blocos.first.total), (perguntas.length, perguntas.length));
      expect(_habito(tester).state.habito.unidadesHoje, perguntas.length);
      expect(find.text('▶ Continuar · 🧩 Quiz'), findsOneWidget);

      await tester.tap(find.byTooltip('Fechar o treino'));
      await _transicao(tester);
      await _esperarRotulo(tester, 'Treino 1/3');
      expect(tester.takeException(), isNull);
    });
  }

  for (final largura in [360.0, 390.0]) {
    testWidgetsDesktop('celular (${largura.toInt()} px): a pílula do treino cabe no HUD e abre o treino', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.ingles, tela: Size(largura, 800));
      await _esperarRotulo(tester, 'Treino');
      expect(tester.takeException(), isNull, reason: 'sem estouro no HUD');
      // no celular o HUD rola junto com o palco, e o palco pede uma rolagem animada até a frase
      // (`zona_visivel.dart`) que no relógio falso do teste não anda — enquanto ela vive, a lista ignora
      // toques. Um jumpTo encerra essa rolagem; então a pílula vai para o meio da tela e recebe o toque.
      final lista = tester.state<ScrollableState>(find.byType(Scrollable).first).position;
      lista.jumpTo(lista.pixels);
      await Scrollable.ensureVisible(tester.element(_hud), alignment: .5);
      await tester.pump(const Duration(milliseconds: 100));
      await _abrirTreino(tester);
      expect(tester.takeException(), isNull, reason: 'sem estouro no hub');
    });
  }
}
