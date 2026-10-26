// Ponta a ponta no PacDartApp inteiro (inglês): concluir a lição → o cartão "🆕 palavras novas" na
// vitória → treinar → "🎮 Jogar com essas palavras" abre o Arcade com elas em foco → a Chuva derruba
// uma palavra da lição com a tradução embaixo → de volta ao mapa o nó da lição comemora e a folha
// oferece as palavras → uma palavra adicionada em "Minhas palavras" entra no vocabulário dos jogos.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/arcade/presentation/banco_arcade.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa/no_3d.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/ingles/data/dicionario_ingles.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/presentation/minhas_palavras_page.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';
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
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

/// O dicionário de teste: "tea" e "milk" são as palavras novas da lição; o resto são palavras de
/// função (nunca "novas", mas jogáveis) — 16 curtas da lição, sem precisar das listas de reserva.
const _dic = Dicionario({
  'tea': 'chá',
  'milk': 'leite',
  'with': 'com',
  'here': 'aqui',
  'how': 'como',
  'are': 'são, estão',
  'you': 'você',
  'what': 'o que',
  'was': 'era, estava (passado de be)',
  'that': 'aquilo, que',
  'they': 'eles, elas',
  'have': 'ter',
  'some': 'algum, alguns',
  'but': 'mas',
  'more': 'mais',
  'where': 'onde',
  'your': 'seu, sua',
  'them': 'eles (objeto)',
});

const _novas = {'tea': 'chá', 'milk': 'leite'};

/// As palavras (3 a 5 letras) que a lição traz para os jogos.
const _daLicao = {
  'tea', 'milk', 'with', 'here', 'how', 'are', 'you', 'what', 'was', 'that', 'they', 'have', 'some', 'but', 'more',
  'where', 'your', 'them',
};

class _LoaderEn extends CurriculoLoader {
  _LoaderEn() : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => const [
        Trilha(
          nivel: 'Na mesa',
          emoji: '🫖',
          etapa: 'A1 · Fundação',
          licoes: [
            Licao(nome: 'Chá da tarde', emoji: '🍵', id: 'mesa.cha', trechos: [
              Trecho(cod: 'Tea with milk, here.', dica: 'Chá com leite, aqui.', out: ''),
              Trecho(cod: 'How are you? What was that?', dica: 'Como vai você? O que foi aquilo?', out: ''),
              Trecho(cod: 'They have some, but you have more.', dica: 'Eles têm um pouco, mas você tem mais.', out: ''),
              Trecho(cod: 'Where is your tea? Here, with them.', dica: 'Cadê o seu chá? Aqui, com eles.', out: ''),
            ]),
            Licao(nome: 'De novo', emoji: '🔁', id: 'mesa.de-novo', trechos: [
              Trecho(cod: 'How are you?', dica: 'Como vai você?', out: ''),
            ]),
          ],
        ),
      ];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

/// O relógio do HUD redesenha todo segundo (pumpAndSettle nunca assenta) e o app nasce dentro de
/// `runAsync`: os blocs só andam com tempo real entre os pumps.
Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Deixa terminar as animações de uma vez (troca de passo do treino, rotas, folhas).
Future<void> _passa(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
  await _anda(tester, 2);
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 25 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

Future<void> _abrirApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, 'turismo_tutorial_digitacao': true});
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      palavrasBuilder: (_) => MemoriaPalavrasRepository(),
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

bool _tem(String chave) => find.byKey(Key(chave)).evaluate().isNotEmpty;

/// Faz as frases da lição (digita a frase inteira e Enter) até a vitória.
Future<void> _fazerLicao(WidgetTester tester, CursoBloc curso, TypingBloc typing) async {
  for (var i = 0; i < 40 && !curso.state.vitoria; i++) {
    // 🪜 a pausa entre as etapas da lição: continua
    if (find.byKey(const Key('etapa-continuar')).evaluate().isNotEmpty) {
      await tester.tap(find.byKey(const Key('etapa-continuar')));
      await _anda(tester, 3);
      continue;
    }
    await tester.enterText(
        find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, typing.state.chars.join());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
    await _anda(tester, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _anda(tester, 3);
  }
  expect(curso.state.vitoria, isTrue);
  await _anda(tester, 6);
}

/// A sessão de treino até o resumo, por toque: escolhe pela tradução, faz os pares, digita a palavra.
/// No 🎧 (voz de verdade: não dá para saber o que falou) tenta uma e, se errar, aprende com a resposta.
Future<void> _treinar(WidgetTester tester) async {
  final ouvida = <String>[];
  for (var i = 0; i < 60 && !_tem('treino-resumo'); i++) {
    if (_tem('passo-conhecer')) {
      await tester.tap(find.byKey(const Key('treino-continuar')));
    } else if (_tem('passo-escolha') || _tem('passo-ouvir')) {
      final ouvir = _tem('passo-ouvir');
      final alvo = ouvir
          ? (ouvida.isNotEmpty ? ouvida.last : _novas.keys.first)
          : _novas[tester.widget<Text>(find.byKey(const Key('treino-prompt'))).data!]!;
      var opcao = find.descendant(of: find.byKey(Key(ouvir ? 'passo-ouvir' : 'passo-escolha')), matching: find.text(alvo));
      if (opcao.evaluate().isEmpty) opcao = find.byKey(const Key('treino-opcao-0'));
      await tester.tap(opcao.first);
      await _passa(tester);
      final resposta = find.textContaining('Resposta: ');
      if (ouvir && resposta.evaluate().isNotEmpty) {
        ouvida.add(tester.widget<Text>(resposta.first).data!.split(' ')[1]);
      }
      await tester.tap(find.byKey(const Key('treino-continuar')));
    } else if (_tem('passo-pares')) {
      final tab = find.byKey(const Key('passo-pares'));
      for (final e in _novas.entries) {
        final ladoEn = find.descendant(of: tab, matching: find.text(e.key));
        if (ladoEn.evaluate().isEmpty) continue;
        await tester.tap(ladoEn.first);
        await tester.pump();
        await tester.tap(find.descendant(of: tab, matching: find.text(e.value)).first);
        await _passa(tester);
      }
      await tester.tap(find.byKey(const Key('treino-continuar')));
    } else if (_tem('passo-digitar')) {
      final traducao = tester.widget<Text>(find.byKey(const Key('treino-prompt'))).data!;
      final en = _novas.entries.firstWhere((e) => e.value == traducao).key;
      await tester.enterText(find.byKey(const Key('treino-digitar')), en);
      await tester.pump();
      await tester.tap(find.byKey(const Key('treino-verificar')));
      await _passa(tester);
      await tester.tap(find.byKey(const Key('treino-continuar')));
    }
    await _passa(tester);
  }
  expect(find.text('Treino concluído!'), findsOneWidget);
}

/// A palavra em cima do chip (um RichText com o texto inteiro).
Finder _rich(String texto) => find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == texto);

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    FraseView.carencia = Duration.zero;
    MapaPage.esquecerVistas();
    DicionarioIngles.usarParaTestes(_dic);
  });
  tearDown(() {
    Linguagem.atual = Linguagem.dart;
    DicionarioIngles.usarParaTestes(null);
  });

  testWidgetsDesktop('lição → treino → Arcade com as palavras (Chuva com tradução) → mapa comemora → Minhas palavras',
      (tester) async {
    await _abrirApp(tester);
    final ctx = tester.element(find.byType(HomePage));
    final curso = ctx.read<CursoBloc>();
    final typing = ctx.read<TypingBloc>();
    final palavras = ctx.read<PalavrasCubit>();
    final revisao = ctx.read<RevisaoCubit>();
    for (var i = 0; i < 20 && palavras.state.indice == null; i++) {
      await _anda(tester, 2);
    }
    expect(palavras.state.indice, isNotNull, reason: 'o palco monta o índice das palavras ao abrir');

    // abre o mapa uma vez antes da lição (a 1ª abertura da sessão nunca comemora) e volta
    await tester.tap(find.text('Mapa'));
    await _passa(tester);
    expect(find.byType(MapaPage), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is No3D && w.celebrar, skipOffstage: false), findsNothing);
    Navigator.of(tester.element(find.byType(MapaPage))).pop();
    await _passa(tester);
    expect(find.byType(MapaPage), findsNothing);

    // ── 1. a lição: na vitória, o cartão das 2 palavras novas
    await _fazerLicao(tester, curso, typing);
    final cartao = find.byKey(const Key('vitoria-palavras'));
    expect(cartao, findsOneWidget);
    expect(find.text('🆕 2 palavras novas nesta lição'), findsOneWidget);
    expect(find.descendant(of: cartao, matching: find.text('tea')), findsOneWidget);
    expect(find.descendant(of: cartao, matching: find.text('leite')), findsOneWidget);

    // ── 2. treinar: a sessão abre por cima; o resumo oferece "🎮 Jogar com essas palavras"
    final cartoesFrases = revisao.state.cartoes.length;
    await tester.tap(find.byKey(const Key('treinar-palavras')));
    await _passa(tester);
    expect(find.byType(TreinoPalavrasPage), findsOneWidget);
    await _treinar(tester);
    await tester.ensureVisible(find.byKey(const Key('jogar-palavras')));
    await _passa(tester);
    await tester.tap(find.byKey(const Key('jogar-palavras')));
    await _passa(tester);
    await _anda(tester, 4);
    expect(find.byType(TreinoPalavrasPage), findsNothing);
    // as duas viraram cartões no banco DELAS (a revisão das frases não mudou) e estão em foco
    expect(palavras.state.banco['tea']?.cartao, isNotNull);
    expect(palavras.state.banco['milk']?.cartao, isNotNull);
    expect(palavras.state.banco.emTreino, containsAll(['tea', 'milk']));
    expect(revisao.state.cartoes.length, cartoesFrases);

    // ── 3. o hub do Arcade abriu com elas em foco no cartão "Minhas palavras"
    expect(find.byType(ArcadePage), findsOneWidget);
    final hub = find.byKey(const Key('arcade-minhas-palavras'));
    expect(hub, findsOneWidget);
    expect(find.descendant(of: hub, matching: find.text('tea')), findsOneWidget);
    expect(find.descendant(of: hub, matching: find.text('milk')), findsOneWidget);
    expect(find.descendant(of: hub, matching: find.textContaining('das suas lições')), findsOneWidget);
    final hubCtx = tester.element(find.byType(ArcadePage));
    final v = BancoArcade.vocabulario(hubCtx);
    expect(v.emFoco('tea'), isTrue);
    expect(v.curtas.take(2).toSet(), {'tea', 'milk'}, reason: 'o foco vem primeiro');
    expect(v.curtas.toSet().difference(_daLicao), isEmpty, reason: 'nível 1 só com palavras da lição');
    expect(v.traducao('milk'), 'leite');

    // ── 4. a Chuva: cai uma palavra da lição, com a tradução embaixo
    Navigator.of(hubCtx).push(MaterialPageRoute<void>(builder: (_) => const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    final caindo = [for (final w in _daLicao) if (_rich(w).evaluate().isNotEmpty) w];
    expect(caindo, isNotEmpty, reason: 'uma palavra da lição está caindo');
    final w = caindo.first;
    final pt = v.traducao(w)!;
    expect(find.text(pt), findsWidgets);
    expect(tester.getTopLeft(find.text(pt).first).dy, greaterThan(tester.getTopLeft(_rich(w)).dy),
        reason: 'a tradução fica embaixo da palavra');
    expect(tester.takeException(), isNull);
    Navigator.of(tester.element(find.byType(ChuvaPage))).pop();
    await _passa(tester);
    expect(find.byType(ChuvaPage), findsNothing);
    Navigator.of(tester.element(find.byType(ArcadePage))).pop();
    await _passa(tester);
    expect(find.byType(ArcadePage), findsNothing);

    // de volta à vitória: ✅ treinadas; o Enter segue para a próxima lição
    expect(find.byKey(const Key('palavras-treinadas')), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _anda(tester, 4);
    expect(curso.state.vitoria, isFalse);
    expect(curso.state.concluidas, contains('mesa.cha'));

    // ── 5. o mapa: o nó da lição concluída comemora e a folha oferece as palavras
    await tester.tap(find.text('Mapa'));
    await _passa(tester);
    expect(find.byType(MapaPage), findsOneWidget);
    final comemora = find.byWidgetPredicate((w) => w is No3D && w.celebrar);
    expect(comemora, findsOneWidget);
    expect(tester.widget<No3D>(comemora).rotulo, 'Chá da tarde');
    await _anda(tester, 30);
    await tester.tap(comemora);
    await _passa(tester);
    expect(find.byKey(const Key('sheet-palavras')), findsOneWidget);
    expect(find.text('🆕 Treinar as palavras novas (2)'), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('sheet-palavras')))).pop();
    await _passa(tester);

    // ── 6. "Minhas palavras": adicionar "mango" põe a palavra no vocabulário dos jogos
    final card = find.byKey(const Key('palavras'), skipOffstage: false);
    expect(card, findsOneWidget);
    await tester.ensureVisible(card);
    await _passa(tester);
    await tester.tap(card);
    await _passa(tester);
    expect(find.byType(MinhasPalavrasPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('adicionar-palavra')));
    await _passa(tester);
    await tester.enterText(find.byKey(const Key('palavra-en')), 'mango');
    await tester.pump();
    await tester.enterText(find.byKey(const Key('palavra-pt')), 'manga');
    await tester.pump();
    await tester.tap(find.byKey(const Key('palavra-salvar')));
    await _passa(tester);
    expect(find.text('"mango" vai aparecer no Arcade 🎮'), findsOneWidget);
    expect(palavras.state.banco['mango']?.origem, OrigemPalavra.minha);
    final v2 = BancoArcade.vocabulario(tester.element(find.byType(MinhasPalavrasPage)));
    expect(v2.curtas, contains('mango'));
    expect(v2.traducao('mango'), 'manga');
    expect(v2.curtas, contains('tea'), reason: 'as da lição continuam');
    await _anda(tester, 10);
    expect(tester.takeException(), isNull);
  });
}
