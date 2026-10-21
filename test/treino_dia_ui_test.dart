// "⚡ Treino do dia" (FASE-9, grupo D): a TreinoDiaPage com os providers de verdade (CursoBloc, revisão,
// palavras, hábito, o player do Ouvir de mentira) — monta e lista as etapas, abre cada uma e anota como
// voltou, retoma no mesmo ponto, espera o plano salvo e as fontes lentas ("Está demorando um pouco…"),
// "Pular esta etapa", o painel do 🎧 Ouvir (alvo em faixas, ✕ por fora, reatar ao voltar, sem
// mini-player), o resumo final com o bônus 1× por dia, a dica do treino curto e nada estourando a
// 360/390/1400 px no claro e no escuro.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/fluxo_licao.dart';
import 'package:pac_dart/features/curso/presentation/pages/quiz_page.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/setlists_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/treino_dia/data/treino_dia_repository.dart';
import 'package:pac_dart/features/treino_dia/domain/plano_treino.dart';
import 'package:pac_dart/features/treino_dia/presentation/treino_dia_acoes.dart';
import 'package:pac_dart/features/treino_dia/presentation/treino_dia_cubit.dart';
import 'package:pac_dart/features/treino_dia/presentation/treino_dia_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_baralhos_test.dart' show RepoMemoria;
import 'ingles_ouvir_ui_test.dart' show OuvirFake;
import 'treino_dia_blocos_test.dart'
    show CursoFixo, RepoTravado, banco, cartaoVencido, devida, dicTeste, estadoEn;

final _agora = DateTime(2026, 10, 21, 10);
final _hoje = diaDe(_agora);

class _HabitoMemoria implements HabitoRepository {
  Habito h;
  _HabitoMemoria([this.h = const Habito()]);
  @override
  Future<Habito> carregar() async => h;
  @override
  Future<void> salvar(Habito habito) async => h = habito;
}

/// O plano salvo só chega quando [liberar] é chamado.
class _RepoLento extends MemoriaTreinoDiaRepository {
  final _c = Completer<void>();
  _RepoLento(super.inicial);
  void liberar() => _c.complete();
  @override
  Future<PlanoTreino?> carregar() async {
    await _c.future;
    return super.carregar();
  }
}

// ── os planos ─────────────────────────────────────────────────────────────

const _revisao = BlocoTreino(id: 'revisao', tipo: TipoBloco.revisao, qtd: 3, minutos: 2);
const _palavras = BlocoTreino(id: 'palavras', tipo: TipoBloco.palavras, qtd: 2, minutos: 2);
const _ouvir = BlocoTreino(id: 'ouvir', tipo: TipoBloco.ouvir, qtd: 6);
const _rali = BlocoTreino(id: 'rali', tipo: TipoBloco.rali, minutos: 2);
const _quiz = BlocoTreino(id: 'quiz:0:0', tipo: TipoBloco.quiz, qtd: 10, minutos: 4, t: 0, l: 0);

PlanoTreino _plano(List<BlocoTreino> blocos, {String curso = 'ingles', bool curto = false}) =>
    PlanoTreino(dia: _hoje, curso: curso, blocos: blocos, curto: curto, editadoEm: 1);

final _en4 = _plano(const [_revisao, _palavras, _ouvir, _rali]);

// ── Dart: uma lição com quiz ──────────────────────────────────────────────

Trecho _tr(String cod, String dica) => Trecho(cod: cod, dica: dica, out: 'ok');

final _licaoDart = Licao(nome: 'Listas', emoji: '📦', id: 'd.listas', trechos: [
  _tr("if (lista.isNotEmpty) {\n  print(lista.first);\n}", 'evita mexer numa lista vazia'),
  _tr("for (var i = 0; i < 3; i++) {\n  print(i);\n}", 'repete três vezes'),
  _tr("var nomes = ['Ana', 'Léo'];", 'cria uma lista de nomes'),
  _tr("nomes.add('Rui');", 'põe um nome no fim'),
  _tr('nomes.removeAt(0);', 'tira o primeiro'),
]);

CursoState _estadoDart() => CursoState(
      status: CursoStatus.pronto,
      linguagem: Linguagem.dart,
      trilhas: [Trilha(nivel: 'Listas', emoji: '📦', licoes: [_licaoDart])],
      concluidas: const {'d.listas'},
    );

// ── a montagem ────────────────────────────────────────────────────────────

class _M {
  final CursoBloc curso;
  final TreinoDiaCubit treino;
  final MemoriaTreinoDiaRepository repo;
  final HabitoCubit habito;
  final _HabitoMemoria habitoRepo;
  final OuvirFake? ouvir;
  final GlobalKey<NavigatorState> nav;
  _M(this.curso, this.treino, this.repo, this.habito, this.habitoRepo, this.ouvir, this.nav);
}

Future<_M> _montar(
  WidgetTester tester, {
  CursoState? st,
  PlanoTreino? plano,
  MemoriaTreinoDiaRepository? repo,
  RevisaoRepository? revisao,
  BancoPalavras palavras = const BancoPalavras(),
  bool comOuvir = false,
  Habito habito = const Habito(),
  Size tamanho = const Size(1000, 1600),
  Paleta paleta = Paleta.mixart,
}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Mixart.atual = paleta;
  addTearDown(() => Mixart.atual = Paleta.mixart);
  final estado = st ?? estadoEn();
  final ingles = estado.ehIngles;
  Linguagem.atual = ingles ? Linguagem.ingles : Linguagem.dart;

  final curso = CursoFixo(estado);
  final r = repo ?? MemoriaTreinoDiaRepository(plano);
  final treino = TreinoDiaCubit(repo: r, curso: ingles ? 'ingles' : 'dart', agora: () => _agora);
  final habitoRepo = _HabitoMemoria(habito);
  final hab = HabitoCubit(repo: habitoRepo, agora: () => _agora);
  final rev = ingles ? RevisaoCubit(repo: revisao ?? RepoMemoria(), agora: () => _agora) : null;
  final pal = ingles
      ? PalavrasCubit(repo: MemoriaPalavrasRepository(palavras), agora: () => _agora, carregarDicionario: () async => dicTeste)
      : null;
  final ouvir = comOuvir ? OuvirFake() : null;
  final setlists = comOuvir
      ? SetlistsCubit(repo: MemoriaSetlistsRepository(), agora: () => 1760000000000, folga: Duration.zero)
      : null;
  addTearDown(() async {
    await treino.close();
    await hab.close();
    await rev?.close();
    await pal?.close();
    await ouvir?.close();
    await setlists?.close();
    await curso.close();
  });
  final nav = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<CursoBloc>.value(value: curso),
      BlocProvider<TreinoDiaCubit>.value(value: treino),
      BlocProvider<HabitoCubit>.value(value: hab),
      if (rev != null) BlocProvider<RevisaoCubit>.value(value: rev),
      if (pal != null) BlocProvider<PalavrasCubit>.value(value: pal),
      if (ouvir != null) BlocProvider<OuvirCubit>.value(value: ouvir),
      if (setlists != null) BlocProvider<SetlistsCubit>.value(value: setlists),
    ],
    child: MaterialApp(
      theme: Mixart.tema(),
      navigatorKey: nav,
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: Mixart.bg,
          body: Center(
            child: TextButton(
              key: const Key('abrir'),
              onPressed: () => abrirTreinoDoDia(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  ));
  await _anda(tester);
  return _M(curso, treino, r, hab, habitoRepo, ouvir, nav);
}

/// Alguns quadros (a página tem animação sem fim: o spinner, o confete) — nada de pumpAndSettle.
Future<void> _anda(WidgetTester tester, [int n = 6]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('abrir')));
  await _anda(tester, 10);
}

Future<void> _fecharPagina(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Fechar o treino'));
  await _anda(tester);
  expect(find.byType(TreinoDiaPage), findsNothing);
}

Future<void> _tocar(WidgetTester tester, String chave) async {
  await tester.ensureVisible(find.byKey(Key(chave)));
  await tester.pump();
  await tester.tap(find.byKey(Key(chave)));
  await _anda(tester);
}

String _selo(WidgetTester tester, String id) =>
    tester.widget<Text>(find.descendant(of: find.byKey(Key('treino-dia-selo-$id')), matching: find.byType(Text))).data!;

String _botao(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('treino-dia-comecar')), matching: find.byType(Text)).first)
    .data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('sem plano de hoje: monta com as fontes e lista as etapas na ordem, com os subtítulos', (tester) async {
    final sem = tester.ensureSemantics();
    final m = await _montar(
      tester,
      st: estadoEn(concluidas: {'en.cores'}),
      revisao: RepoMemoria({'c1': cartaoVencido(), 'c2': cartaoVencido(), 'h1': cartaoVencido()}),
      palavras: banco([devida('house', 'casa'), devida('kitchen', 'cozinha')]),
      comOuvir: true,
    );
    await _abrir(tester);
    expect(find.byKey(const Key('treino-dia-pagina')), findsOneWidget);
    expect(m.treino.state.plano!.blocos.map((b) => b.id), ['revisao', 'palavras', 'ouvir', 'rali']);
    expect(m.treino.state.plano!.dia, _hoje);
    final ys = [
      for (final id in ['revisao', 'palavras', 'ouvir', 'rali'])
        tester.getTopLeft(find.byKey(Key('treino-dia-bloco-$id'))).dy,
    ];
    expect([...ys]..sort(), ys, reason: 'na ordem do plano');
    expect(find.text('Revisão do dia'), findsOneWidget);
    expect(find.text('3 frases de memória · ~2 min'), findsOneWidget);
    expect(find.text('até 2 palavras · ~2 min'), findsOneWidget);
    expect(find.text('6 frases para ouvir · ~1 min'), findsOneWidget);
    expect(find.text('1 fase com as suas palavras · ~2 min'), findsOneWidget);
    expect(find.text('~7 min · 4 etapas · qua, 21 out'), findsOneWidget);
    expect(_selo(tester, 'revisao'), '▶ Agora');
    expect(_selo(tester, 'palavras'), 'Depois');
    expect(_botao(tester), '▶ Começar');
    expect(find.byKey(const Key('treino-dia-progresso')), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 1 de 4: Revisão do dia, agora'), findsOneWidget);
    expect(find.bySemanticsLabel('Etapa 4 de 4: Rali relâmpago, pendente'), findsOneWidget);
    sem.dispose();
    expect(find.byKey(const Key('treino-dia-curto')), findsNothing);
  });

  testWidgets('"Começar" abre a Revisão do dia; sair no meio deixa a etapa pendente', (tester) async {
    final m = await _montar(tester,
        plano: _en4, revisao: RepoMemoria({'c1': cartaoVencido(), 'c2': cartaoVencido(), 'h1': cartaoVencido()}));
    await _abrir(tester);
    await _tocar(tester, 'treino-dia-comecar');
    expect(find.byType(SessaoMemoriaPage), findsOneWidget, reason: 'a sessão de memória');
    expect(find.text('3 frases de lições anteriores, de memória'), findsOneWidget);
    m.nav.currentState!.pop();
    await _anda(tester);
    expect(find.byType(TreinoDiaPage), findsOneWidget);
    expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pendente);
    expect(_selo(tester, 'revisao'), '▶ Agora');
    expect(_botao(tester), '▶ Começar');
  });

  testWidgets('revisão sem nada vencendo quando começa: feita "em dia" (vazia) e o botão aponta a próxima',
      (tester) async {
    final m = await _montar(tester, plano: _en4);
    await _abrir(tester);
    await _tocar(tester, 'treino-dia-comecar');
    expect(find.text('Revisão do dia'), findsOneWidget, reason: 'nenhuma rota empurrada: o hub continua');
    final b = m.treino.state.plano!.blocos.first;
    expect((b.estado, b.vazio, b.resultado), (EstadoBloco.feito, true, 0));
    expect(find.text('✓ Nada vencendo agora — você já está em dia. Próximo: 🔥 Palavras'), findsOneWidget);
    expect(_selo(tester, 'revisao'), '✓ Feito · em dia');
    expect(_botao(tester), '▶ Continuar · 🔥 Palavras');
  });

  testWidgets('fechar no meio e abrir de novo retoma na mesma etapa', (tester) async {
    final m = await _montar(tester,
        plano: _plano([_revisao.copyWith(estado: EstadoBloco.feito, resultado: 3), _palavras, _ouvir, _rali]));
    await _abrir(tester);
    expect(_selo(tester, 'revisao'), '✓ Feito · 3 revisadas');
    expect(_selo(tester, 'palavras'), '▶ Agora');
    expect(_botao(tester), '▶ Continuar · 🔥 Palavras');
    await _fecharPagina(tester);
    await _abrir(tester);
    expect(_selo(tester, 'palavras'), '▶ Agora');
    expect(_botao(tester), '▶ Continuar · 🔥 Palavras');
    expect(m.repo.gravacoes, 0, reason: 'retomar não monta nem grava nada');
  });

  testWidgets('o plano salvo demora: "Montando…" e depois retoma o 2/4 (sem montar outro)', (tester) async {
    final salvo = _plano([
      _revisao.copyWith(estado: EstadoBloco.feito, resultado: 3),
      _palavras.copyWith(estado: EstadoBloco.pulado),
      _ouvir,
      _rali,
    ]);
    final repo = _RepoLento(salvo);
    final m = await _montar(tester, repo: repo, revisao: RepoMemoria({'c1': cartaoVencido()}));
    await _abrir(tester);
    expect(find.byKey(const Key('treino-dia-montando')), findsOneWidget);
    expect(find.text('Montando seu treino…'), findsOneWidget);
    expect(m.treino.state.carregado, isFalse);
    repo.liberar();
    await _anda(tester);
    expect(find.byKey(const Key('treino-dia-montando')), findsNothing);
    expect(m.treino.state.plano, salvo);
    expect(repo.gravacoes, 0, reason: 'nunca chamou iniciar');
    expect(_botao(tester), '▶ Continuar · 🎧 Ouvir');
  });

  testWidgets('fontes lentas: aos 8 s "Está demorando…"; "Começar assim mesmo" monta incompleto; depois a revisão entra',
      (tester) async {
    final revisao = RepoTravado({'c1': cartaoVencido(), 'c2': cartaoVencido()});
    final m = await _montar(tester, revisao: revisao);
    await _abrir(tester);
    expect(find.byKey(const Key('treino-dia-montando')), findsOneWidget);
    expect(find.text('Está demorando um pouco…'), findsNothing);
    await tester.pump(TreinoDiaPage.demora);
    await tester.pump();
    expect(find.text('Está demorando um pouco…'), findsOneWidget);
    expect(find.byKey(const Key('treino-dia-tentar')), findsOneWidget);
    expect(find.byKey(const Key('treino-dia-comecar-assim')), findsOneWidget);
    // "Tentar de novo" volta a esperar (mais 8 s)
    await tester.tap(find.byKey(const Key('treino-dia-tentar')));
    await tester.pump();
    expect(find.text('Está demorando um pouco…'), findsNothing);
    await tester.pump(TreinoDiaPage.demora);
    await tester.pump();
    expect(find.text('Está demorando um pouco…'), findsOneWidget);
    await tester.tap(find.byKey(const Key('treino-dia-comecar-assim')));
    await _anda(tester);
    final p = m.treino.state.plano!;
    expect(p.incompleto, isTrue);
    expect(p.blocos.map((b) => b.id), isNot(contains('revisao')));
    expect(find.byKey(const Key('treino-dia-bloco-rali')), findsOneWidget);
    // a revisão chega; ao abrir de novo, ela entra na frente
    revisao.liberar();
    await _anda(tester);
    await _fecharPagina(tester);
    await _abrir(tester);
    final depois = m.treino.state.plano!;
    expect(depois.blocos.first.id, 'revisao');
    expect(depois.incompleto, isFalse);
    expect(find.byKey(const Key('treino-dia-bloco-revisao')), findsOneWidget);
  });

  testWidgets('"Pular esta etapa" marca pulada; pular tudo → "Hoje foi só uma passada", sem bônus', (tester) async {
    final m = await _montar(tester, plano: _plano(const [_ouvir, _rali], curto: true));
    await _abrir(tester);
    expect(find.byKey(const Key('treino-dia-curto')), findsOneWidget);
    expect(find.textContaining('o treino de hoje é curto'), findsOneWidget);
    await _tocar(tester, 'treino-dia-pular');
    expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pulado);
    expect(_selo(tester, 'ouvir'), '⏭ Pulado');
    expect(find.text('⏭ Etapa pulada. Próximo: 🏁 Rali'), findsOneWidget);
    await _tocar(tester, 'treino-dia-pular');
    expect(find.byKey(const Key('treino-dia-fim')), findsOneWidget);
    expect(find.text('Hoje foi só uma passada'), findsOneWidget);
    expect(find.byKey(const Key('treino-dia-bonus')), findsNothing);
    expect(m.habito.state.habito.unidadesHoje, 0);
  });

  group('Dart: quiz + rali', () {
    Future<_M> abrirDart(WidgetTester tester, {PlanoTreino? plano, Habito habito = const Habito()}) async {
      final m = await _montar(tester,
          st: _estadoDart(), plano: plano ?? _plano(const [_quiz, _rali], curso: 'dart'), habito: habito);
      await _abrir(tester);
      return m;
    }

    Future<void> jogarRali(WidgetTester tester, _M m, {int pontos = 120}) async {
      await _tocar(tester, 'treino-dia-comecar');
      final rali = tester.widget<RaliPage>(find.byType(RaliPage));
      expect(rali.treino, isTrue);
      m.nav.currentState!.pop(ResultadoFaseTreino(venceu: true, pontos: pontos, palavras: 9));
      await _anda(tester);
    }

    testWidgets('o quiz abre fora da sequência, com a semente do dia; o fim anota acertos/total', (tester) async {
      final m = await abrirDart(tester);
      expect(find.text('Quiz · Listas'), findsOneWidget);
      expect(find.text('até 10 perguntas · ~4 min'), findsOneWidget);
      expect(find.text('1 fase digitando código · ~2 min'), findsOneWidget);
      await _tocar(tester, 'treino-dia-comecar');
      final q = tester.widget<QuizPage>(find.byType(QuizPage));
      expect(q.emSequencia, isFalse);
      expect(q.rotuloFim, 'Continuar o treino →');
      expect(q.semente, sementeQuiz(0, 0) ^ (_hoje * 7919));
      // voltar sem terminar: pendente
      m.nav.currentState!.pop();
      await _anda(tester);
      expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pendente);
      await _tocar(tester, 'treino-dia-comecar');
      tester.widget<QuizPage>(find.byType(QuizPage)).onTerminou!(7, 10);
      m.nav.currentState!.pop(true);
      await _anda(tester);
      expect(_selo(tester, 'quiz:0:0'), '✓ Feito · 7/10');
      expect(find.text('✓ Quiz feito! Próximo: 🏁 Rali'), findsOneWidget);
      expect(_botao(tester), '▶ Continuar · 🏁 Rali');
    });

    testWidgets('o rali abre a RaliPage do treino; completo dá +3 uma vez, e reabrir mostra o fim', (tester) async {
      final m = await abrirDart(tester,
          plano: _plano([_quiz.copyWith(estado: EstadoBloco.feito, resultado: 7, total: 10), _rali], curso: 'dart'));
      await jogarRali(tester, m);
      expect(find.byKey(const Key('treino-dia-fim')), findsOneWidget);
      expect(find.text('Treino do dia completo! ⚡'), findsOneWidget);
      expect(find.text('🧩 7/10'), findsOneWidget);
      expect(find.text('🏁 120 pts'), findsOneWidget);
      expect(find.text('+3 na meta pelo treino completo ⚡'), findsOneWidget);
      expect(m.habito.state.habito.unidadesHoje, bonusTreino);
      expect(m.habito.state.habito.bonusTreinoDia, _hoje);
      expect(find.text('Meta de hoje: 3/${m.habito.state.habito.meta}'), findsOneWidget);
      expect(m.treino.state.plano!.bonus, isTrue);
      await tester.tap(find.byKey(const Key('treino-dia-fechar')));
      await _anda(tester);
      expect(find.byType(TreinoDiaPage), findsNothing);
      await _abrir(tester);
      expect(find.byKey(const Key('treino-dia-fim')), findsOneWidget);
      expect(find.text('Volte amanhã para um treino novo 🌅'), findsOneWidget);
      expect(find.text('Bônus do treino já ganho hoje ✓'), findsOneWidget);
      expect(m.habito.state.habito.unidadesHoje, bonusTreino, reason: 'reabrir não dá de novo');
      // "Continuar minha lição" volta à 1ª tela
      await tester.tap(find.byKey(const Key('treino-dia-ir-licao')));
      await _anda(tester);
      expect(find.byKey(const Key('abrir')), findsOneWidget);
    });

    testWidgets('bônus já ganho hoje em outro curso: "já ganho hoje ✓" e +0', (tester) async {
      final m = await abrirDart(tester,
          plano: _plano([_quiz.copyWith(estado: EstadoBloco.feito, resultado: 7, total: 10), _rali], curso: 'dart'),
          habito: Habito(dia: _hoje, unidadesHoje: 4, bonusTreinoDia: _hoje));
      await jogarRali(tester, m);
      expect(find.byKey(const Key('treino-dia-fim')), findsOneWidget);
      expect(find.text('Bônus do treino já ganho hoje ✓'), findsOneWidget);
      expect(find.text('+3 na meta pelo treino completo ⚡'), findsNothing);
      expect(m.habito.state.habito.unidadesHoje, 4);
    });

    testWidgets('só etapas passivas feitas: completo, mas sem linha de bônus e +0', (tester) async {
      final m = await abrirDart(tester,
          plano: _plano([_quiz.copyWith(estado: EstadoBloco.pulado), _rali], curso: 'dart'));
      await jogarRali(tester, m, pontos: 0);
      expect(find.text('Treino do dia completo! ⚡'), findsOneWidget);
      expect(find.text('🏁 jogou'), findsOneWidget);
      expect(find.byKey(const Key('treino-dia-bonus')), findsNothing);
      expect(m.habito.state.habito.unidadesHoje, 0);
    });
  });

  testWidgets('Palavras por cima do hub: "treino-fechar" é só o da sessão de palavras', (tester) async {
    final m = await _montar(tester,
        plano: _plano(const [_palavras, _rali]), palavras: banco([devida('house', 'casa'), devida('kitchen', 'cozinha')]));
    await _abrir(tester);
    await _tocar(tester, 'treino-dia-comecar');
    expect(find.byType(TreinoPalavrasPage), findsOneWidget);
    expect(find.textContaining('Palavras do dia'), findsWidgets);
    expect(find.byKey(const Key('treino-fechar')), findsOneWidget);
    expect(find.byKey(const Key('treino-dia-comecar')), findsNothing, reason: 'o hub está por baixo');
    expect(find.byKey(const Key('treino-dia-comecar'), skipOffstage: false), findsOneWidget);
    m.nav.currentState!.pop();
    await _anda(tester);
    expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pendente);
  });

  group('🎧 Ouvir', () {
    // "Cores" (8 frases) concluída: o trecho é UM item com as 6 primeiras → 6 faixas
    Future<_M> abrirOuvir(WidgetTester tester) async {
      final m = await _montar(tester,
          // (não curto: um plano curto ganharia a etapa 🔥 Palavras das palavras da lição concluída)
          st: estadoEn(concluidas: {'en.cores'}, l: 1), plano: _plano(const [_ouvir, _rali]), comOuvir: true);
      await _abrir(tester);
      return m;
    }

    void ouviu(OuvirFake o, int k) => o.emitir(o.state.copyWith(indice: k.clamp(0, o.state.fila.length - 1), ouvidas: k));

    testWidgets('toca as frases da última lição; alvo em faixas; feito ao ouvir todas; sem mini-player', (tester) async {
      final m = await abrirOuvir(tester);
      final o = m.ouvir!;
      await _tocar(tester, 'treino-dia-comecar');
      expect(find.byKey(const Key('treino-dia-ouvir')), findsOneWidget);
      expect(o.tocou!.fonte.titulo, tituloOuvirTreino);
      expect(o.state.fila, hasLength(6));
      expect(find.text('Frase 1 de 6'), findsOneWidget);
      expect(find.text('The color number 1 is blue.'), findsOneWidget);
      expect(o.state.telaCheia, isTrue, reason: 'o mini-player some com o painel aberto');
      ouviu(o, 1);
      await _anda(tester);
      expect(find.text('Frase 2 de 6'), findsOneWidget);
      expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pendente, reason: '1 de 6 não basta');
      ouviu(o, 6);
      await _anda(tester);
      expect(find.byKey(const Key('treino-dia-ouvir')), findsNothing);
      final b = m.treino.state.plano!.blocos.first;
      expect((b.estado, b.resultado), (EstadoBloco.feito, 6));
      expect(o.chamadas, contains('fechar'));
      expect(o.state.telaCheia, isFalse);
      expect(_selo(tester, 'ouvir'), '✓ Feito · 6 frases ouvidas');
    });

    testWidgets('✕ por fora depois de 3 de 6: vale (metade)', (tester) async {
      final m = await abrirOuvir(tester);
      final o = m.ouvir!;
      await _tocar(tester, 'treino-dia-comecar');
      ouviu(o, 3);
      await _anda(tester);
      o.fechar();
      await _anda(tester);
      final b = m.treino.state.plano!.blocos.first;
      expect((b.estado, b.resultado), (EstadoBloco.feito, 3));
    });

    testWidgets('✕ por fora depois de 2 de 6: volta a pendente com "Ouvir de novo"', (tester) async {
      final m = await abrirOuvir(tester);
      final o = m.ouvir!;
      await _tocar(tester, 'treino-dia-comecar');
      ouviu(o, 2);
      await _anda(tester);
      o.fechar();
      await _anda(tester);
      expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pendente);
      expect(find.byKey(const Key('treino-dia-ouvir')), findsNothing);
      expect(_botao(tester), '▶ Ouvir de novo');
      expect(o.state.telaCheia, isFalse);
    });

    testWidgets('sair no meio e voltar reata a sessão (sem tocar de novo); se acabou, a etapa fica feita',
        (tester) async {
      final m = await abrirOuvir(tester);
      final o = m.ouvir!;
      await _tocar(tester, 'treino-dia-comecar');
      ouviu(o, 2);
      await _anda(tester);
      await _fecharPagina(tester);
      expect(o.state.telaCheia, isFalse, reason: 'o mini-player volta');
      expect(o.state.ativo, isTrue, reason: 'o player segue tocando');
      await _abrir(tester);
      expect(find.byKey(const Key('treino-dia-ouvir')), findsOneWidget);
      expect(find.text('Frase 3 de 6'), findsOneWidget);
      expect(o.chamadas.where((c) => c == 'tocar'), hasLength(1));
      await _fecharPagina(tester);
      // a fila acabou com a página fechada
      o.emitir(o.state.copyWith(status: StatusOuvir.acabou, ouvidas: 6));
      await _anda(tester);
      await _abrir(tester);
      final b = m.treino.state.plano!.blocos.first;
      expect((b.estado, b.resultado), (EstadoBloco.feito, 6));
      expect(o.state.ativo, isFalse, reason: 'a sessão do treino foi fechada');
    });

    testWidgets('com o curso tocando: fecha a sessão dele (guarda a posição) antes de tocar o treino', (tester) async {
      final m = await abrirOuvir(tester);
      final o = m.ouvir!;
      o.emitir(const OuvirState(
        status: StatusOuvir.tocando,
        fonte: FonteOuvir('curso', 'Curso inteiro'),
        fila: [Faixa(chave: 'h1', en: 'My house is big.')],
      ));
      await _anda(tester);
      await _tocar(tester, 'treino-dia-comecar');
      expect(o.chamadas.take(2), ['fechar', 'tocar']);
      expect(o.state.fonte!.titulo, tituloOuvirTreino);
    });

    testWidgets('"Pular" no painel pula a etapa e fecha a sessão', (tester) async {
      final m = await abrirOuvir(tester);
      final o = m.ouvir!;
      await _tocar(tester, 'treino-dia-comecar');
      await _tocar(tester, 'treino-dia-ouvir-pular');
      expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pulado);
      expect(o.state.ativo, isFalse);
      expect(find.byKey(const Key('treino-dia-ouvir')), findsNothing);
    });

    testWidgets('a sessão do treino de outro dia (app aberto na virada) não vale nem é reatada', (tester) async {
      final m = await _montar(tester,
          st: estadoEn(concluidas: {'en.cores'}, l: 1), plano: _plano(const [_ouvir, _rali]), comOuvir: true);
      final o = m.ouvir!;
      // a de ontem: mesmo título, acabou e ficou no player (ninguém tocou no ✕ do mini-player)
      const ontem = OuvirState(
        status: StatusOuvir.acabou,
        fonte: FonteOuvir('avulso', tituloOuvirTreino),
        fila: [Faixa(chave: 'y1', en: 'Yesterday was sunny.')],
        ouvidas: 1,
      );
      o.emitir(ontem);
      await _anda(tester);
      await _abrir(tester);
      expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pendente, reason: 'nada ouvido hoje');
      expect(find.byKey(const Key('treino-dia-ouvir')), findsNothing);
      expect(o.chamadas, isNot(contains('fechar')));

      // tocando (ontem, no meio): "Começar" fecha a de ontem e toca a de hoje do começo
      o.emitir(ontem.copyWith(status: StatusOuvir.tocando));
      await _anda(tester);
      await _tocar(tester, 'treino-dia-comecar');
      expect(o.chamadas.take(2), ['fechar', 'tocar']);
      expect(o.state.fila, hasLength(6));
      expect(find.text('Frase 1 de 6'), findsOneWidget);
      expect(m.treino.state.plano!.blocos.first.estado, EstadoBloco.pendente);
    });
  });

  group('revisão de UX', () {
    testWidgets('curto já concluído + lição nova com quiz: reabrir segue no fim "Volte amanhã", sem etapa nova',
        (tester) async {
      final feito = _plano([_rali.copyWith(estado: EstadoBloco.feito, resultado: 80)], curso: 'dart', curto: true);
      expect(feito.concluido, isTrue);
      final m = await _montar(tester, st: _estadoDart(), plano: feito);
      await _abrir(tester);
      await _anda(tester, 20); // tempo de sobra para as fontes (o quiz da lição) chegarem
      expect(find.byKey(const Key('treino-dia-fim')), findsOneWidget);
      expect(find.text('Volte amanhã para um treino novo 🌅'), findsOneWidget);
      expect(m.treino.state.plano, same(feito), reason: 'nada de 🧩 Quiz entrando na frente');
      expect(m.treino.situacao, SituacaoTreino.concluido);
      expect(m.repo.gravacoes, 0);
    });

    testWidgets('controle: curto ainda pendente + lição nova com quiz → o quiz entra na frente', (tester) async {
      final m = await _montar(tester, st: _estadoDart(), plano: _plano(const [_rali], curso: 'dart', curto: true));
      await _abrir(tester);
      await _anda(tester, 20);
      expect(m.treino.state.plano!.blocos.map((b) => b.id), ['quiz:0:0', 'rali']);
      expect(find.byKey(const Key('treino-dia-bloco-quiz:0:0')), findsOneWidget);
    });

    testWidgets('leitor de tela: o cartão atual fala título/subtítulo/estado UMA vez; o "Pular" é um nó à parte',
        (tester) async {
      final sem = tester.ensureSemantics();
      await _montar(tester, plano: _en4);
      await _abrir(tester);
      final atual = tester.getSemantics(find.byKey(const Key('treino-dia-bloco-revisao')));
      expect(atual.label, 'Revisão do dia. 3 frases de memória · ~2 min. Agora');
      expect(find.bySemanticsLabel('Pular esta etapa'), findsOneWidget);
      final depois = tester.getSemantics(find.byKey(const Key('treino-dia-bloco-rali')));
      expect(depois.label, 'Rali relâmpago. 1 fase com as suas palavras · ~2 min. Depois');
      sem.dispose();
    });

    testWidgets('plano salvo lento: "Começar assim mesmo" responde na hora ("Começando…") e monta quando chega',
        (tester) async {
      final sem = tester.ensureSemantics();
      final repo = _RepoLento(null);
      final m = await _montar(tester, repo: repo);
      await _abrir(tester);
      await tester.pump(TreinoDiaPage.demora);
      await tester.pump();
      expect(tester.getSemantics(find.byKey(const Key('treino-dia-demorando'))), isSemantics(isLiveRegion: true));
      await tester.tap(find.byKey(const Key('treino-dia-comecar-assim')));
      await tester.pump();
      expect(find.byKey(const Key('treino-dia-comecando')), findsOneWidget);
      expect(tester.getSemantics(find.byKey(const Key('treino-dia-comecando'))), isSemantics(isLiveRegion: true));
      expect(find.byKey(const Key('treino-dia-comecar-assim')), findsNothing, reason: 'nada de tocar de novo');
      expect(find.byKey(const Key('treino-dia-tentar')), findsNothing);
      repo.liberar();
      await _anda(tester);
      expect(find.byKey(const Key('treino-dia-montando')), findsNothing);
      expect(m.treino.planoDeHoje, isNotNull);
      expect(find.byKey(const Key('treino-dia-comecar')), findsOneWidget);
      sem.dispose();
    });

    testWidgets('o aviso do painel do Ouvir (som parou) é anunciado ao leitor de tela', (tester) async {
      final sem = tester.ensureSemantics();
      final m = await _montar(tester,
          st: estadoEn(concluidas: {'en.cores'}, l: 1), plano: _plano(const [_ouvir, _rali]), comOuvir: true);
      await _abrir(tester);
      await _tocar(tester, 'treino-dia-comecar');
      m.ouvir!.emitir(m.ouvir!.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.semSom));
      await _anda(tester);
      expect(tester.getSemantics(find.text('Não consegui tocar o som. Toque ▶ ou pule esta etapa.')),
          isSemantics(isLiveRegion: true));
      sem.dispose();
    });
  });

  group('sem estourar', () {
    for (final tamanho in const [Size(360, 740), Size(390, 844), Size(1400, 900)]) {
      for (final paleta in const [Paleta.flutterClaro, Paleta.mixart]) {
        final nome = '${tamanho.width.toInt()} px, ${paleta == Paleta.flutterClaro ? 'claro' : 'escuro'}';
        testWidgets('hub, painel do Ouvir e fim — $nome', (tester) async {
          final m = await _montar(tester,
              st: estadoEn(concluidas: {'en.cores'}, l: 1),
              plano: _plano([_revisao.copyWith(estado: EstadoBloco.feito, resultado: 8), _palavras, _ouvir, _rali]),
              comOuvir: true,
              tamanho: tamanho,
              paleta: paleta);
          await _abrir(tester);
          expect(tester.takeException(), isNull);
          await _tocar(tester, 'treino-dia-pular');
          await _tocar(tester, 'treino-dia-comecar'); // o Ouvir
          expect(find.byKey(const Key('treino-dia-ouvir')), findsOneWidget);
          expect(tester.takeException(), isNull);
          m.ouvir!.emitir(m.ouvir!.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.semSom));
          await _anda(tester);
          expect(find.text('Não consegui tocar o som. Toque ▶ ou pule esta etapa.'), findsOneWidget);
          expect(tester.takeException(), isNull);
          await _tocar(tester, 'treino-dia-ouvir-pular');
          await _tocar(tester, 'treino-dia-pular');
          expect(find.byKey(const Key('treino-dia-fim')), findsOneWidget);
          await _anda(tester, 30);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
