// "⚡ Treino do dia" — as costuras do inglês (grupo B): a seleção pura da Revisão do dia com limites
// (`itensDaRevisao`), `abrirRevisao(modoTreino:)` devolvendo como terminou (`FimDaRevisao`), as sessões de
// memória e de cartões sem a oferta das teimosas (`semOferta`), o treino de palavras sem saídas
// (`abrirTreinoPalavras(modoTreino:)`) e a revanche das teimosas sem `aceitar` (`treinarTeimosas(modoTreino:)`).
// As chamadas de sempre (sem os parâmetros novos) continuam iguais.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/ingles/data/dicionario_ingles.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart';
import 'package:pac_dart/features/ingles/domain/config_srs.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/roteiro_treino.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/acoes_teimosas.dart';
import 'package:pac_dart/features/ingles/presentation/fixacao.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/treino/passo_escolha.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_baralhos_test.dart' show ConfigMemoria, RepoMemoria;
import 'ingles_cartoes_ui_test.dart' show LoaderTeste;

class _VozFake extends VozIngles {
  final falas = <String>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) async => falas.add(frase);
  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

/// Conta as rotas empurradas (para "nada foi aberto").
class _Contador extends NavigatorObserver {
  int empurradas = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => empurradas++;
}

final _agora = DateTime(2026, 10, 20, 9);
final _hoje = Revisao.dia(_agora);

// ---------- a Revisão do dia ----------

/// Trilha "ta": 12 frases (baralho `tr:ta`); trilha "tb": 3 frases (baralho `tr:tb`).
final _fa = [
  for (var i = 1; i <= 12; i++) Trecho(cod: 'Sentence number $i.', dica: 'Frase número $i.', out: ''),
];
const _fb = [
  Trecho(cod: 'Good morning.', dica: 'Bom dia.', out: ''),
  Trecho(cod: 'Thank you.', dica: 'Obrigado.', out: ''),
  Trecho(cod: 'See you later.', dica: 'Até mais tarde.', out: ''),
];
final _trilhasRev = [
  Trilha(nivel: 'TA', emoji: '1', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Frases', emoji: '🔢', id: 'ta.l1', trechos: _fa),
  ]),
  const Trilha(nivel: 'TB', emoji: '2', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Cumprimentos', emoji: '👋', id: 'tb.l1', trechos: _fb),
  ]),
];

/// Um cartão que venceu ontem.
CartaoSrs _vencido([int atraso = 1]) =>
    CartaoSrs(estabilidade: 2, dificuldade: 5, ultimoDia: _hoje - 3, proximoDia: _hoje - atraso);

/// Os cartões: [diretas] de memória vencidas e [reversas] (inglês → português) vencidas.
Map<String, CartaoSrs> _cartoes({Iterable<Trecho> diretas = const [], Iterable<Trecho> reversas = const []}) => {
      for (final (i, f) in diretas.indexed) RevisaoCubit.chaveDe(f): _vencido(1 + i % 3),
      for (final f in reversas) RevisaoCubit.chaveReversaDe(f): _vencido(),
    };

Future<RevisaoCubit> _revisao(Map<String, CartaoSrs> cartoes, {ConfigSrs config = ConfigSrs.padrao}) async {
  final c = RevisaoCubit(
    repo: RepoMemoria(cartoes),
    configRepo: ConfigMemoria(config),
    agendador: AgendadorFsrs(fuzz: false),
    agora: () => _agora,
  );
  if (!c.state.carregado) await c.stream.firstWhere((s) => s.carregado);
  return c;
}

class _AppRevisao {
  final RevisaoCubit revisao;
  final HabitoCubit habito;
  final _Contador nav;
  final List<FimDaRevisao> fins;
  _AppRevisao(this.revisao, this.habito, this.nav, this.fins);
}

/// O app mínimo: um botão que chama [abrir] com o contexto (curso, revisão e hábito por cima).
Future<_AppRevisao> _montarRevisao(WidgetTester tester, Map<String, CartaoSrs> cartoes,
    {ConfigSrs config = ConfigSrs.padrao, required Future<FimDaRevisao> Function(BuildContext) abrir}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1200, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final revisao = (await tester.runAsync(() => _revisao(cartoes, config: config)))!;
  final habito = HabitoCubit(repo: LocalHabitoRepository(), agora: () => _agora);
  final curso = CursoBloc(loader: LoaderTeste(_trilhasRev), progresso: LocalProgressoRepository(prefixo: 'en_'))
    ..add(const CursoIniciado());
  addTearDown(curso.close);
  addTearDown(revisao.close);
  addTearDown(habito.close);
  await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
  await tester.runAsync(habito.carregar);
  final nav = _Contador();
  final fins = <FimDaRevisao>[];
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider.value(value: curso),
      BlocProvider.value(value: revisao),
      BlocProvider.value(value: habito),
    ],
    child: MaterialApp(
      theme: Mixart.tema(),
      navigatorObservers: [nav],
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('abrir'),
              onPressed: () async => fins.add(await abrir(context)),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  nav.empurradas = 0;
  return _AppRevisao(revisao, habito, nav, fins);
}

Future<void> _passa(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

bool _temTexto(String texto) => find.textContaining(texto).evaluate().isNotEmpty;

Future<void> _digitaFrase(WidgetTester tester, String texto) async {
  await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, texto);
  await tester.pump();
}

/// A frase da vez na sessão de memória (a tradução está na tela: acha a frase pela dica).
Trecho _fraseDaVez(List<Trecho> frases) => frases.firstWhere((f) => _temTexto(f.dica));

// ---------- 🔥 teimosas nas sessões ----------

const _dicTeimosas = Dicionario({
  'nice': 'legal, simpático',
  'meet': 'conhecer, encontrar',
  'coffee': 'café',
});

const _nice = Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '');

final _trilhasTeimosas = [
  const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'L1', emoji: '👋', id: 't1.l1', trechos: [
      _nice,
      Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: ''),
    ]),
  ]),
];

/// O cubit de verdade, contando as gravações de erros (tem de ser UMA por sessão).
class _CubitContando extends PalavrasCubit {
  int chamadas = 0;
  _CubitContando()
      : super(
          repo: MemoriaPalavrasRepository(),
          agora: () => DateTime(2026, 10, 20, 9),
          agendador: AgendadorFsrs(fuzz: false),
          carregarDicionario: () async => _dicTeimosas,
        );

  @override
  List<String> registrarErros(List<EvidenciaPalavra> evs) {
    chamadas++;
    return super.registrarErros(evs);
  }
}

// ---------- treino de palavras ----------

const _dicPalavras = Dicionario({
  'coffee': 'café',
  'morning': 'manhã',
  'tired': 'cansado',
  'window': 'janela',
});

final _trilhasPalavras = [
  const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'No café', emoji: '☕', id: 't1.l1', trechos: [
      Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: ''),
      Trecho(cod: 'Good morning, I am tired.', dica: 'Bom dia, estou cansado.', out: ''),
    ]),
  ]),
];

PalavraNova _p(String en, String pt, [String exemplo = '']) =>
    PalavraNova(en: en, pt: pt, ptCompleta: pt, licaoId: 't1.l1', exemplo: exemplo);

final _quatro = [
  _p('coffee', 'café', 'Coffee, please.'),
  _p('morning', 'manhã', 'Good morning, I am tired.'),
  _p('tired', 'cansado', 'Good morning, I am tired.'),
  _p('window', 'janela'),
];

Map<String, String> _pt(List<PalavraNova> ps) => {for (final p in ps) p.en: p.pt};

bool _tem(String chave) => find.byKey(Key(chave)).evaluate().isNotEmpty;

String _prompt(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('treino-prompt'))).data!;

int _opcao(String texto) {
  for (var i = 0; i < 4; i++) {
    if (find.descendant(of: find.byKey(Key('treino-opcao-$i')), matching: find.text(texto)).evaluate().isNotEmpty) {
      return i;
    }
  }
  fail('opção "$texto" não está na tela');
}

LogicalKeyboardKey _teclaDoPar(Finder tab, String texto) {
  final ladrilho = find.ancestor(
      of: find.descendant(of: tab, matching: find.text(texto)), matching: find.byType(Ladrilho3D));
  final rotulo = find.descendant(
      of: ladrilho,
      matching: find.byWidgetPredicate((w) => w is Text && RegExp(r'^[1-5A-E]$').hasMatch(w.data ?? '')));
  final t = (rotulo.evaluate().single.widget as Text).data!;
  return const {
    '1': LogicalKeyboardKey.digit1,
    '2': LogicalKeyboardKey.digit2,
    '3': LogicalKeyboardKey.digit3,
    '4': LogicalKeyboardKey.digit4,
    '5': LogicalKeyboardKey.digit5,
    'A': LogicalKeyboardKey.keyA,
    'B': LogicalKeyboardKey.keyB,
    'C': LogicalKeyboardKey.keyC,
    'D': LogicalKeyboardKey.keyD,
    'E': LogicalKeyboardKey.keyE,
  }[t]!;
}

Future<void> _enter(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

/// O botão "CONTINUAR" de cada passo / da barra de retorno (key `treino-continuar`) continua "CONTINUAR".
void _continuarDoPassoIntacto() {
  final f = find.byKey(const Key('treino-continuar'));
  if (f.evaluate().isEmpty) return;
  expect(find.descendant(of: f, matching: find.text('CONTINUAR')), findsWidgets);
  expect(find.descendant(of: f, matching: find.text('CONTINUAR O TREINO →')), findsNothing);
}

/// Responde o passo da tela pelo teclado (como no `ingles_treino_palavras_ui_test`) e confere, no caminho,
/// que o botão de cada passo continua "CONTINUAR". Devolve o tipo do passo.
Future<String> _responder(WidgetTester tester, Map<String, String> pt, _VozFake voz) async {
  final en = {for (final e in pt.entries) e.value: e.key};
  if (_tem('passo-relembrar')) {
    _continuarDoPassoIntacto();
    await _enter(tester);
    return 'relembrar';
  }
  if (_tem('passo-conhecer')) {
    _continuarDoPassoIntacto();
    await _enter(tester);
    return 'conhecer';
  }
  if (_tem('passo-escolha') || _tem('passo-ouvir')) {
    final ouvir = _tem('passo-ouvir');
    final palavra = ouvir ? voz.falas.last : _prompt(tester);
    final i = _opcao(ouvir ? palavra : pt[palavra]!);
    await tester.sendKeyEvent([
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ][i]);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('treino-feedback')), findsOneWidget);
    _continuarDoPassoIntacto();
    await _enter(tester);
    return ouvir ? 'ouvir' : 'escolha';
  }
  if (_tem('passo-pares')) {
    final tab = find.byKey(const Key('passo-pares'));
    for (final e in pt.entries) {
      if (find.descendant(of: tab, matching: find.text(e.key)).evaluate().isEmpty) continue;
      await tester.sendKeyEvent(_teclaDoPar(tab, e.key));
      await tester.pump();
      await tester.sendKeyEvent(_teclaDoPar(tab, e.value));
      await tester.pumpAndSettle();
    }
    await _enter(tester);
    return 'pares';
  }
  if (_tem('passo-digitar')) {
    final palavra = en[_prompt(tester)]!;
    await tester.enterText(find.byKey(const Key('treino-digitar')), palavra);
    await tester.pump();
    await _enter(tester); // confere
    expect(find.byKey(const Key('treino-feedback')), findsOneWidget);
    _continuarDoPassoIntacto();
    await _enter(tester); // segue
    return 'digitar';
  }
  fail('passo desconhecido na tela');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FraseView.carencia = Duration.zero;
  });

  group('itensDaRevisao (a seleção pura)', () {
    test('12 frases vencidas de memória → 8 com limiteFrases: 8 (as que vencem primeiro)', () async {
      final r = await _revisao(_cartoes(diretas: _fa));
      addTearDown(r.close);
      final todas = itensDaRevisao(r, _trilhasRev);
      expect(todas.diretas, hasLength(12));
      final oito = itensDaRevisao(r, _trilhasRev, limiteFrases: 8);
      expect(oito.diretas, hasLength(8));
      expect(oito.diretas, todas.diretas.take(8).toList(), reason: 'a mesma ordem, só cortada');
      expect(oito.invertidas, isEmpty);
      expect(oito.total, 8);
      expect(oito.vazio, isFalse);
    });

    test('cartões: os vencidos primeiro e depois os novos, cortados em 4; novas = só as que couberam', () async {
      // 2 cartões inglês → português vencidos (da "ta") + o baralho "tb" ligado: 3 novos
      final r = await _revisao(_cartoes(reversas: _fa.take(2)), config: const ConfigSrs(reversos: {'tr:tb'}));
      addTearDown(r.close);
      final todas = itensDaRevisao(r, _trilhasRev);
      expect(todas.diretas, isEmpty);
      expect(todas.invertidas, [..._fa.take(2), ..._fb]);
      expect(todas.novas, _fb);
      final quatro = itensDaRevisao(r, _trilhasRev, limiteCartoes: 4);
      expect(quatro.invertidas, [..._fa.take(2), ..._fb.take(2)]);
      expect(quatro.novas, _fb.take(2).toList());
      expect(quatro.total, 4);
      // limite menor que os vencidos: nenhuma nova cabe
      final um = itensDaRevisao(r, _trilhasRev, limiteCartoes: 1);
      expect(um.invertidas, [_fa.first]);
      expect(um.novas, isEmpty);
      // ler a seleção não gasta a cota de novos
      expect(r.vagasDeNovos, ConfigSrs.padrao.novosPorDia);
    });

    test('baralho: só o que é daquele baralho', () async {
      final r = await _revisao(_cartoes(diretas: _fa, reversas: _fa.take(2)),
          config: const ConfigSrs(reversos: {'tr:tb'}));
      addTearDown(r.close);
      final ta = itensDaRevisao(r, _trilhasRev, baralho: 'tr:ta');
      expect(ta.diretas, hasLength(12));
      expect(ta.invertidas, _fa.take(2).toList());
      expect(ta.novas, isEmpty);
      final tb = itensDaRevisao(r, _trilhasRev, baralho: 'tr:tb');
      expect(tb.diretas, isEmpty);
      expect(tb.invertidas, _fb);
      expect(tb.novas, _fb);
    });

    test('sem limites é a seleção de antes (a mesma conta que o abrirRevisao fazia)', () async {
      final r = await _revisao(_cartoes(diretas: _fa.skip(3), reversas: _fa.take(2)),
          config: const ConfigSrs(reversos: {'tr:tb'}));
      addTearDown(r.close);
      final indice = IndiceBaralhos.de(_trilhasRev);
      final devidas = r.devidas();
      final diretas = [
        for (final k in devidas)
          if (!Revisao.ehReversa(k) && indice.porChave[k] != null) indice.porChave[k]!,
      ];
      final invertidasDevidas = [
        for (final k in devidas)
          if (Revisao.ehReversa(k) && indice.porChave[Revisao.baseDe(k)] != null) indice.porChave[Revisao.baseDe(k)]!,
      ];
      final novas = r.novasReversas(indice.frasesDosLigados(r.state.config.reversos));
      final itens = itensDaRevisao(r, _trilhasRev);
      expect(itens.diretas, diretas);
      expect(itens.invertidas, [...invertidasDevidas, ...novas]);
      expect(itens.novas, novas);
      // nada vencendo e nada ligado: vazio
      final nada = await _revisao(const {});
      addTearDown(nada.close);
      expect(itensDaRevisao(nada, _trilhasRev).vazio, isTrue);
    });
  });

  group('abrirRevisao', () {
    testWidgets('modoTreino sem nada para revisar: não abre nada e devolve terminou', (tester) async {
      final app = await _montarRevisao(tester, const {},
          abrir: (c) => abrirRevisao(c, limiteFrases: 8, limiteCartoes: 4, modoTreino: true));
      await tester.tap(find.byKey(const Key('abrir')));
      await _passa(tester);
      expect(app.nav.empurradas, 0);
      expect(find.byType(SessaoMemoriaPage), findsNothing);
      final fim = app.fins.single;
      expect(fim.terminou, isTrue);
      expect(fim.respondidas, 0);
      expect(fim.revisadas, isEmpty);
    });

    testWidgets('sem modoTreino e sem nada: continua abrindo a sessão vazia ("nenhuma frase vence hoje")',
        (tester) async {
      final app = await _montarRevisao(tester, const {}, abrir: (c) => abrirRevisao(c));
      await tester.tap(find.byKey(const Key('abrir')));
      await _passa(tester, 10);
      expect(app.nav.empurradas, 1);
      expect(find.text('Revisão do dia'), findsOneWidget);
      expect(find.text('nenhuma frase vence hoje'), findsOneWidget);
      expect(tester.widget<SessaoMemoriaPage>(find.byType(SessaoMemoriaPage)).semOferta, isFalse);
      await tester.tap(find.text('Continuar →'));
      await _passa(tester, 10);
      expect(app.fins.single.terminou, isTrue);
    });

    testWidgets('3 frases vencidas: a memória até o fim → respondidas 3, terminou, revisadas na ordem e hábito +3',
        (tester) async {
      final app = await _montarRevisao(tester, _cartoes(diretas: _fb),
          abrir: (c) => abrirRevisao(c, limiteFrases: 8, limiteCartoes: 4, modoTreino: true));
      final antes = app.habito.state.habito.feitasHoje(_agora);
      await tester.tap(find.byKey(const Key('abrir')));
      await _passa(tester, 10);
      expect(find.byType(SessaoMemoriaPage), findsOneWidget);
      expect(find.text('Revisão do dia'), findsOneWidget);
      expect(tester.widget<SessaoMemoriaPage>(find.byType(SessaoMemoriaPage)).semOferta, isTrue);
      final ordem = <Trecho>[];
      for (var i = 0; i < 3; i++) {
        final f = _fraseDaVez(_fb);
        ordem.add(f);
        await _digitaFrase(tester, f.cod);
        await _passa(tester, 3);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _passa(tester, 3);
      }
      expect(find.text('Pronto!'), findsOneWidget);
      await tester.tap(find.text('Continuar →'));
      await _passa(tester, 10);
      expect(find.byType(SessaoMemoriaPage), findsNothing);
      expect(app.nav.empurradas, 1, reason: 'sem cartões: só a memória');
      final fim = app.fins.single;
      expect(fim.respondidas, 3);
      expect(fim.terminou, isTrue);
      expect(fim.revisadas, ordem);
      expect(app.habito.state.habito.feitasHoje(_agora) - antes, 3);
      // a revisão foi registrada (as 3 frases andaram)
      for (final f in _fb) {
        expect(app.revisao.state.cartoes[RevisaoCubit.chaveDe(f)]!.proximoDia, greaterThan(_hoje), reason: f.cod);
      }
    });

    testWidgets('sair com o X no meio → terminou: false (o que foi respondido conta)', (tester) async {
      final app = await _montarRevisao(tester, _cartoes(diretas: _fb),
          abrir: (c) => abrirRevisao(c, limiteFrases: 8, limiteCartoes: 4, modoTreino: true));
      await tester.tap(find.byKey(const Key('abrir')));
      await _passa(tester, 10);
      final f = _fraseDaVez(_fb);
      await _digitaFrase(tester, f.cod);
      await _passa(tester, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await _passa(tester, 3);
      await tester.tap(find.byTooltip('Voltar'));
      await _passa(tester, 10);
      expect(find.byType(SessaoMemoriaPage), findsNothing);
      final fim = app.fins.single;
      expect(fim.terminou, isFalse);
      expect(fim.respondidas, 1);
      expect(fim.revisadas, [f]);
    });

    testWidgets('modoTreino só com cartões: vai direto a eles, cortados no limite, sem oferta; sair → terminou false',
        (tester) async {
      final app = await _montarRevisao(tester, const {},
          config: const ConfigSrs(reversos: {'tr:tb'}),
          abrir: (c) => abrirRevisao(c, limiteFrases: 8, limiteCartoes: 2, modoTreino: true));
      await tester.tap(find.byKey(const Key('abrir')));
      await tester.pumpAndSettle();
      expect(find.byType(SessaoMemoriaPage), findsNothing);
      expect(find.byType(SessaoCartoesPage), findsOneWidget);
      expect(find.text('2 cartões · 2 novos'), findsOneWidget);
      expect(tester.widget<SessaoCartoesPage>(find.byType(SessaoCartoesPage)).semOferta, isTrue);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      final fim = app.fins.single;
      expect(fim.terminou, isFalse);
      expect(fim.respondidas, 0);
      expect(app.revisao.introduzidasHoje, 0);
    });
  });

  group('semOferta: os tropeços aparecem, a oferta não (e a cota não é gasta)', () {
    Future<_CubitContando> cubitPronto(WidgetTester tester) async {
      final c = _CubitContando();
      await tester.runAsync(() async {
        await c.carregar();
        await c.prepararIndice(_trilhasTeimosas);
      });
      expect(c.state.indice, isNotNull);
      return c;
    }

    Future<void> digita(WidgetTester tester, String ch) async {
      await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, ch);
      await tester.pump();
    }

    /// "Nice to meet you." com 2 teclas erradas no começo de "Nice" e de "meet".
    Future<void> errando(WidgetTester tester) async {
      for (final ch in ['x', 'x', 'N', 'i', 'c', 'e', ' ', 't', 'o', ' ', 'z', 'z', 'm', 'e', 'e', 't', ' ', 'y', 'o', 'u', '.']) {
        if (_temTexto('Enter segue')) break;
        await digita(tester, ch);
      }
    }

    for (final semOferta in [false, true]) {
      testWidgets('SessaoMemoriaPage (semOferta: $semOferta)', (tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final c = await cubitPronto(tester);
        await tester.pumpWidget(BlocProvider<PalavrasCubit>.value(
          value: c,
          child: MaterialApp(
            home: SessaoMemoriaPage(
              titulo: 'Revisão',
              subtitulo: 'teste',
              itens: const [_nice],
              voz: _VozFake(),
              semOferta: semOferta,
            ),
          ),
        ));
        await _passa(tester, 4);
        // erra de memória duas vezes (a 1ª e a volta): sem semOferta, isso já dá a oferta
        var errou = 0;
        for (var i = 0; i < 20 && !_temTexto('Pronto!'); i++) {
          if (_temTexto('de memória') && errou < 2) {
            await errando(tester);
            errou++;
          } else {
            await digita(tester, _nice.cod);
          }
          await _passa(tester, 4);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await _passa(tester, 4);
        }
        expect(find.text('Pronto!'), findsOneWidget);
        expect(c.chamadas, 1, reason: 'a evidência é gravada do mesmo jeito');
        expect(c.state.banco['meet']?.errosTotal, greaterThan(0));
        final resumo = find.byKey(const Key('resumo-teimosas'));
        expect(resumo, findsOneWidget);
        expect(find.descendant(of: resumo, matching: find.textContaining('meet')), findsOneWidget);
        expect(find.byKey(const Key('treinar-teimosas')), semOferta ? findsNothing : findsOneWidget);
        expect(find.byKey(const Key('jogar-teimosas')), semOferta ? findsNothing : findsOneWidget);
        expect(c.state.banco.sugestao.mostradasHoje, semOferta ? 0 : 1);
        await tester.pumpWidget(const SizedBox());
        expect(c.chamadas, 1);
        await c.close();
      });

      testWidgets('SessaoCartoesPage (semOferta: $semOferta)', (tester) async {
        final c = await cubitPronto(tester);
        // 3 teimosas no banco: um erro na sessão já basta para a oferta
        c.registrarErros([
          for (final k in ['nice', 'meet', 'coffee']) ...[
            EvidenciaPalavra(chave: k, peso: 1, falha: 1, fonte: FonteErro.licao),
            EvidenciaPalavra(chave: k, peso: 1, falha: 1, fonte: FonteErro.licao),
          ],
        ]);
        c.chamadas = 0;
        SharedPreferences.setMockInitialValues({
          SessaoCartoesPage.prefNivel: NivelResposta.avancado.id,
          SessaoCartoesPage.prefSentido: SentidoCartao.ptEn.id,
        });
        tester.view.physicalSize = const Size(900, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(BlocProvider<PalavrasCubit>.value(
          value: c,
          child: MaterialApp(
            home: SessaoCartoesPage(
              titulo: 'Cartões',
              subtitulo: 'teste',
              itens: const [_nice],
              voz: _VozFake(),
              chaveDe: RevisaoCubit.chaveReversaDe,
              previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
              onNota: (_, _) {},
              aleatorio: Random(7),
              semOferta: semOferta,
            ),
          ),
        ));
        await tester.pumpAndSettle();
        Future<void> escreve(String texto) async {
          await tester.enterText(find.byKey(const Key('resposta-escrita')), texto);
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pump();
        }

        await escreve('nice to see you');
        await tester.tap(find.byKey(const Key('nota-errei')));
        await tester.pumpAndSettle();
        for (var i = 0; i < 4 && find.byKey(const Key('continuar-cartoes')).evaluate().isEmpty; i++) {
          if (find.byKey(const Key('resposta-escrita')).evaluate().isNotEmpty) {
            await escreve(_nice.cod);
          } else if (find.byKey(const Key('mostrar-resposta')).evaluate().isNotEmpty) {
            await tester.tap(find.byKey(const Key('mostrar-resposta')));
          }
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('nota-bom')));
          await tester.pumpAndSettle();
        }
        expect(find.byKey(const Key('continuar-cartoes')), findsOneWidget);
        expect(c.chamadas, 1, reason: 'a evidência é gravada do mesmo jeito');
        expect(find.byKey(const Key('resumo-teimosas')), findsOneWidget);
        expect(find.byKey(const Key('treinar-teimosas')), semOferta ? findsNothing : findsOneWidget);
        expect(c.state.banco.sugestao.mostradasHoje, semOferta ? 0 : 1);
        await tester.pumpWidget(const SizedBox());
        await c.close();
      });
    }
  });

  group('treino de palavras', () {
    Future<(PalavrasCubit, HabitoCubit, _Contador, _VozFake)> montar(
        WidgetTester tester, Future<ResultadoTreino?> Function(BuildContext, _VozFake) abrir, List<ResultadoTreino?> rs,
        {BancoPalavras? banco}) async {
      SharedPreferences.setMockInitialValues({});
      DicionarioIngles.usarParaTestes(_dicPalavras);
      addTearDown(() => DicionarioIngles.usarParaTestes(null));
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = PalavrasCubit(
        repo: banco == null ? MemoriaPalavrasRepository() : MemoriaPalavrasRepository(banco),
        agora: () => _agora,
        agendador: AgendadorFsrs(fuzz: false),
        carregarDicionario: () async => _dicPalavras,
      );
      final habito = HabitoCubit(repo: LocalHabitoRepository(), agora: () => _agora);
      final curso = CursoBloc(loader: LoaderTeste(_trilhasPalavras), progresso: LocalProgressoRepository(prefixo: 'en_'))
        ..add(const CursoIniciado());
      addTearDown(curso.close);
      addTearDown(cubit.close);
      addTearDown(habito.close);
      await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
      await tester.runAsync(cubit.carregar);
      await tester.runAsync(() => cubit.prepararIndice(curso.state.trilhas));
      await tester.runAsync(habito.carregar);
      final voz = _VozFake();
      final nav = _Contador();
      await tester.pumpWidget(MultiBlocProvider(
        providers: [
          BlocProvider.value(value: curso),
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: habito),
        ],
        child: MaterialApp(
          theme: Mixart.tema(),
          navigatorObservers: [nav],
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('abrir'),
                  onPressed: () async => rs.add(await abrir(context, voz)),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpAndSettle();
      nav.empurradas = 0;
      return (cubit, habito, nav, voz);
    }

    for (final modoTreino in [true, false]) {
      testWidgets('abrirTreinoPalavras(modoTreino: $modoTreino): o resumo, o rótulo e a volta', (tester) async {
        final rs = <ResultadoTreino?>[];
        final (cubit, habito, nav, voz) = await montar(
            tester,
            (c, voz) => abrirTreinoPalavras(c, _quatro,
                titulo: modoTreino ? '🔤 Palavras do dia' : 'No café', voz: voz, modoTreino: modoTreino),
            rs);
        final antes = habito.state.habito.feitasHoje(_agora);
        await tester.tap(find.byKey(const Key('abrir')));
        await tester.pumpAndSettle();
        expect(find.byType(TreinoPalavrasPage), findsOneWidget);
        final pagina = tester.widget<TreinoPalavrasPage>(find.byType(TreinoPalavrasPage));
        expect(pagina.semSaidas, modoTreino);
        expect(pagina.rotuloContinuar, modoTreino ? 'CONTINUAR O TREINO →' : isNull);
        for (var i = 0; i < 60 && !_tem('treino-resumo'); i++) {
          await _responder(tester, _pt(_quatro), voz);
        }
        expect(find.text('Treino concluído!'), findsOneWidget);
        final concluir = find.byKey(const Key('treino-concluir'));
        if (modoTreino) {
          expect(find.byKey(const Key('jogar-palavras')), findsNothing);
          expect(find.byKey(const Key('treino-virar-licao')), findsNothing);
          expect(find.descendant(of: concluir, matching: find.text('CONTINUAR O TREINO →')), findsOneWidget);
        } else {
          expect(find.byKey(const Key('jogar-palavras')), findsOneWidget, reason: 'o de sempre: Jogar oferecido');
          expect(find.descendant(of: concluir, matching: find.text('CONTINUAR')), findsOneWidget);
          expect(find.text('CONTINUAR O TREINO →'), findsNothing);
        }
        await _enter(tester);
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
        await tester.pumpAndSettle();
        expect(find.byType(TreinoPalavrasPage), findsNothing);
        expect(find.byType(ArcadePage), findsNothing);
        expect(nav.empurradas, 1, reason: 'só a sessão; nada aberto depois');
        final r = rs.single;
        expect(r, isNotNull);
        expect(r!.jogar, isFalse);
        expect(r.licao, isFalse);
        expect(r.palavras.map((p) => p.en).toSet(), {'coffee', 'morning', 'tired', 'window'});
        // o registro de sempre: cartões das palavras e os exercícios no hábito
        for (final p in _quatro) {
          expect(cubit.state.banco[p.en]?.cartao, isNotNull, reason: p.en);
        }
        expect(habito.state.habito.feitasHoje(_agora) - antes, r.passos);
        expect(r.passos, greaterThan(0));
      });
    }

    testWidgets('abrirTreinoPalavras com a lista vazia devolve null sem abrir nada', (tester) async {
      final rs = <ResultadoTreino?>[];
      final (_, _, nav, _) =
          await montar(tester, (c, voz) => abrirTreinoPalavras(c, const [], voz: voz, modoTreino: true), rs);
      await tester.tap(find.byKey(const Key('abrir')));
      await tester.pumpAndSettle();
      expect(nav.empurradas, 0);
      expect(rs, [null]);
    });

    /// "tired" teimosa (já foi), com um "Agora não" antes: `recusasSeguidas` = 1.
    BancoPalavras bancoComTeimosa() => BancoPalavras.vazio.com(PalavraDoBanco(
          en: 'tired',
          pt: 'cansado',
          licaoId: 't1.l1',
          cargaErro: 2,
          cargaVistas: 2,
          cargaDia: _hoje - 1,
          errosTotal: 3,
          ultimoErroDia: _hoje - 2,
          acertosSeguidos: 1,
          ultimoAcertoDia: _hoje - 1,
          foiTeimosa: true,
        ));

    for (final modoTreino in [true, false]) {
      testWidgets('treinarTeimosas(modoTreino: $modoTreino): devolve o resultado; aceitar só fora do treino',
          (tester) async {
        final rs = <ResultadoTreino?>[];
        final (cubit, _, nav, voz) = await montar(
            tester, (c, voz) => treinarTeimosas(c, ['tired', 'coffee'], voz: voz, modoTreino: modoTreino), rs,
            banco: bancoComTeimosa());
        cubit.adiar();
        final recusas = cubit.state.banco.sugestao.recusasSeguidas;
        expect(recusas, 1);
        final sugestaoAntes = cubit.state.banco.sugestao;
        await tester.tap(find.byKey(const Key('abrir')));
        await tester.pumpAndSettle();
        expect(find.text('🎯 Treino de palavras · 🔥 Revanche das teimosas'), findsOneWidget);
        if (modoTreino) {
          expect(cubit.state.banco.sugestao, sugestaoAntes, reason: 'não é resposta a uma oferta: nada de aceitar');
        } else {
          expect(cubit.state.banco.sugestao.recusasSeguidas, 0, reason: 'o de sempre: aceitar zera as recusas');
        }
        for (var i = 0; i < 30 && !_tem('treino-resumo'); i++) {
          await _responder(tester, const {'tired': 'cansado', 'coffee': 'café'}, voz);
        }
        expect(find.text('Revanche concluída!'), findsOneWidget);
        expect(find.byKey(const Key('treino-virar-licao')), modoTreino ? findsNothing : findsOneWidget);
        expect(find.byKey(const Key('jogar-palavras')), modoTreino ? findsNothing : findsOneWidget);
        await _enter(tester);
        await tester.pumpAndSettle();
        expect(find.byType(TreinoPalavrasPage), findsNothing);
        expect(nav.empurradas, 1);
        final r = rs.single;
        expect(r, isNotNull);
        expect(r!.palavras.map((p) => p.en).toSet(), {'tired', 'coffee'});
        if (modoTreino) expect(cubit.state.banco.sugestao.recusasSeguidas, 1);
      });
    }

    testWidgets('treinarTeimosas só com palavras sem tradução devolve null sem abrir nada', (tester) async {
      final rs = <ResultadoTreino?>[];
      final (_, _, nav, _) = await montar(
          tester, (c, voz) => treinarTeimosas(c, ['zzqx'], voz: voz, modoTreino: true), rs);
      await tester.tap(find.byKey(const Key('abrir')));
      await tester.pumpAndSettle();
      expect(nav.empurradas, 0);
      expect(rs, [null]);
    });
  });
}
