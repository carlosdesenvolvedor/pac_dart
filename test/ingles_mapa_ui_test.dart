// O mapa estilo Duolingo do PAC·ENGLISH: faixa "UNIDADE N", balão COMEÇAR, 3 estrelas, nó trancado (só
// na aparência) com o teste da unidade, as palavras novas da lição, o baú do fim da unidade, "Minhas
// palavras", a rolagem até a lição atual + "Onde parei", celular (360) e desktop (1280).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/mapa_regras.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa/bau_trilha.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa/banner_unidade.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa/no_3d.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/minhas_palavras_page.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/domain/roteiro_treino.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';

// ───────────────────────── o "curso" de teste ─────────────────────────

/// Progresso só na memória (o mapa lê concluídas, notas e conquistas).
class ProgressoMemoria implements ProgressoRepository {
  final Set<String> feitas;
  final Map<String, int> notas;
  final Set<String> projetos;
  (int, int) pos;
  ProgressoMemoria({Set<String>? feitas, Map<String, int>? notas, Set<String>? projetos, this.pos = (0, 0)})
      : feitas = feitas ?? {},
        notas = notas ?? {},
        projetos = projetos ?? {};

  @override
  Future<Set<String>> concluidas() async => {...feitas};
  @override
  Future<void> marcarConcluida(String chave) async => feitas.add(chave);
  @override
  Future<(int, int)> posicao() async => pos;
  @override
  Future<void> salvarPosicao(int trilha, int licao) async => pos = (trilha, licao);
  @override
  Future<Map<String, int>> quizNotas() async => {...notas};
  @override
  Future<void> salvarQuizNota(String chave, int acertos) async => notas[chave] = acertos;
  @override
  Future<Set<String>> projetosFeitos() async => {...projetos};
  @override
  Future<void> marcarProjetoFeito(String chave) async => projetos.add(chave);
  @override
  Future<int> recorde() async => 0;
  @override
  Future<void> salvarRecorde(int score) async {}
}

class LoaderMapa extends CurriculoLoader {
  final List<Trilha> trilhas;
  LoaderMapa(this.trilhas) : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

const _vocab = [
  ('apple', 'maçã'), ('bread', 'pão'), ('cheese', 'queijo'), ('coffee', 'café'), ('water', 'água'),
  ('house', 'casa'), ('garden', 'jardim'), ('window', 'janela'), ('door', 'porta'), ('table', 'mesa'),
  ('chair', 'cadeira'), ('kitchen', 'cozinha'), ('street', 'rua'), ('city', 'cidade'), ('train', 'trem'),
  ('ticket', 'bilhete'), ('airport', 'aeroporto'), ('hotel', 'hotel'), ('beach', 'praia'), ('mountain', 'montanha'),
  ('river', 'rio'), ('forest', 'floresta'), ('friend', 'amigo'), ('teacher', 'professor'), ('doctor', 'médico'),
  ('market', 'mercado'), ('money', 'dinheiro'), ('morning', 'manhã'), ('evening', 'noitinha'), ('weekend', 'fim de semana'),
  ('office', 'escritório'), ('meeting', 'reunião'), ('computer', 'computador'), ('keyboard', 'teclado'), ('screen', 'tela'),
  ('phone', 'telefone'), ('letter', 'carta'), ('music', 'música'), ('movie', 'filme'), ('book', 'livro'),
  ('pencil', 'lápis'), ('paper', 'papel'), ('school', 'escola'), ('student', 'aluno'), ('lesson', 'aula'),
  ('dinner', 'jantar'), ('lunch', 'almoço'), ('breakfast', 'café da manhã'), ('orange', 'laranja'), ('banana', 'banana'),
  ('sugar', 'açúcar'), ('salt', 'sal'), ('butter', 'manteiga'), ('egg', 'ovo'), ('chicken', 'frango'),
  ('fish', 'peixe'), ('rice', 'arroz'), ('soup', 'sopa'), ('juice', 'suco'), ('milk', 'leite'),
  ('jacket', 'jaqueta'), ('shirt', 'camisa'), ('shoes', 'sapatos'), ('hat', 'chapéu'), ('bag', 'bolsa'),
  ('island', 'ilha'), ('bridge', 'ponte'), ('castle', 'castelo'), ('museum', 'museu'), ('church', 'igreja'),
];

final dicMapa = Dicionario({for (final (en, pt) in _vocab) en: pt});

const _nomesLicoes = [
  ('Oi, tudo bem?', '👋'), ('No café', '☕'), ('Pedindo comida', '🍽️'), ('Na cidade', '🏙️'), ('De trem', '🚆'),
  ('No hotel', '🏨'), ('Na praia', '🏖️'), ('Amigos novos', '🤝'), ('No escritório', '💼'), ('Reunião rápida', '📅'),
  ('Música e filmes', '🎬'), ('Na escola', '🏫'), ('Jantar em casa', '🍲'), ('Café da manhã', '🥐'), ('Compras', '🛍️'),
  ('Roupas', '👕'), ('Passeio', '🗺️'), ('No museu', '🏛️'), ('Fim de semana', '🌞'), ('Revisão', '🔁'),
];

/// Monta [unidades] trilhas (etapa, nome, emoji, lições, quem fala), 3 palavras novas por lição.
List<Trilha> cursoDeTeste([
  List<(String, String, String, int, String)> unidades = const [
    ('A1 · Fundação', 'Primeiros Passos', '👋', 5, 'mike'),
    ('A1 · Fundação', 'Comida e bebida', '🍕', 6, 'sarah'),
    ('A2 · Dia a dia', 'Viagens', '✈️', 4, 'ana'),
    ('A2 · Dia a dia', 'Trabalho', '💼', 4, 'ben'),
  ],
]) {
  var w = 0, n = 0;
  final r = <Trilha>[];
  for (var u = 0; u < unidades.length; u++) {
    final (etapa, nome, emoji, licoes, quem) = unidades[u];
    r.add(Trilha(
      nivel: nome,
      emoji: emoji,
      etapa: etapa,
      descricao: 'Unidade de teste $nome.',
      licoes: [
        for (var l = 0; l < licoes; l++)
          () {
            final (a, pa) = _vocab[w++ % _vocab.length];
            final (b, pb) = _vocab[w++ % _vocab.length];
            final (c, pc) = _vocab[w++ % _vocab.length];
            final (ln, le) = _nomesLicoes[n++ % _nomesLicoes.length];
            return Licao(
              id: 'u${u + 1}.l$l',
              nome: ln,
              emoji: le,
              resumo: 'Resumo da lição $ln.',
              trechos: [
                Trecho(cod: 'The $a and the $b.', dica: 'O $pa e o $pb.', out: '', quem: quem),
                Trecho(cod: 'Look at the $c.', dica: 'Olhe o $pc.', out: '', quem: 'voce'),
              ],
            );
          }(),
      ],
    ));
  }
  return r;
}

/// Um mapa montado: o bloc do curso, o cubit das palavras e o progresso.
class MapaMontado {
  final CursoBloc curso;
  final PalavrasCubit palavras;
  final ProgressoMemoria progresso;
  final GlobalKey<NavigatorState> nav;
  MapaMontado(this.curso, this.palavras, this.progresso, this.nav);
}

/// Abre o MapaPage (empurrado sobre uma tela vazia) com [trilhas] e o [progresso].
Future<MapaMontado> montarMapa(
  WidgetTester tester, {
  required List<Trilha> trilhas,
  required ProgressoMemoria progresso,
  Size tamanho = const Size(360, 800),
  ThemeData? tema,
  Widget Function(Widget app)? envolver,
}) async {
  tester.view.physicalSize = tamanho;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  Linguagem.atual = Linguagem.ingles;
  addTearDown(() => Linguagem.atual = Linguagem.dart);
  final curso = CursoBloc(loader: LoaderMapa(trilhas), progresso: progresso)..add(const CursoIniciado());
  final palavras = PalavrasCubit(
    repo: MemoriaPalavrasRepository(),
    agora: () => DateTime(2026, 10, 20, 9),
    agendador: AgendadorFsrs(fuzz: false),
    carregarDicionario: () async => dicMapa,
  );
  addTearDown(() => tester.runAsync(curso.close));
  addTearDown(() => tester.runAsync(palavras.close));
  await tester.runAsync(
      () => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto).timeout(const Duration(seconds: 5)));
  await tester.runAsync(() => palavras.prepararIndice(curso.state.trilhas));
  final nav = GlobalKey<NavigatorState>();
  final Widget app = MultiBlocProvider(
    providers: [BlocProvider.value(value: curso), BlocProvider.value(value: palavras)],
    child: MaterialApp(
      navigatorKey: nav,
      theme: tema ?? Mixart.tema(),
      home: const Scaffold(body: SizedBox.expand()),
    ),
  );
  await tester.pumpWidget(envolver == null ? app : envolver(app));
  nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const MapaPage()));
  await _anda(tester, 4);
  // a rolagem até a lição atual (450 ms) e o "Onde parei"
  await _anda(tester, 4, const Duration(milliseconds: 150));
  return MapaMontado(curso, palavras, progresso, nav);
}

Future<void> _anda(WidgetTester tester, [int vezes = 6, Duration passo = const Duration(milliseconds: 60)]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.pump(passo);
  }
}

/// Progresso da "foto": unidade 1 inteira (com notas), 2 lições da unidade 2; atual = unidade 2, lição 3.
ProgressoMemoria progressoMeio() => ProgressoMemoria(
      feitas: {'u1.l0', 'u1.l1', 'u1.l2', 'u1.l3', 'u1.l4', 'u2.l0', 'u2.l1'},
      notas: {'u1.l0': 10, 'u1.l1': 9, 'u1.l2': 7, 'u1.l3': 8, 'u1.l4': 6, 'u2.l0': 9, 'u2.l1': 5},
      pos: (1, 2),
    );

Finder _noNoEstado(EstadoNo e) => find.byWidgetPredicate((w) => w is No3D && w.estado == e, skipOffstage: false);
Finder _estrelas(int n) => find.byWidgetPredicate((w) => w is EstrelasArco && w.estrelas == n, skipOffstage: false);
Finder _bau(EstadoBau e) => find.byWidgetPredicate((w) => w is BauTrilha && w.estado == e, skipOffstage: false);

/// Rola até [f] ficar no meio da tela (a barra de cima é fixa).
Future<void> _mostrar(WidgetTester tester, Finder f) async {
  Scrollable.ensureVisible(tester.element(f), alignment: .5);
  await _anda(tester, 3);
}

/// O retângulo de [f] está dentro da tela?
bool _naTela(WidgetTester tester, Finder f) {
  final r = tester.getRect(f);
  final tela = tester.view.physicalSize / tester.view.devicePixelRatio;
  return r.top >= 0 && r.bottom <= tela.height;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(MapaPage.esquecerVistas);

  testWidgets('celular: "UNIDADE 1", o balão COMEÇAR pratica a lição atual e fecha o mapa', (tester) async {
    final m = await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    expect(find.text('UNIDADE 1 · A1', skipOffstage: false), findsOneWidget);
    expect(find.text('UNIDADE 3 · A2', skipOffstage: false), findsOneWidget);
    expect(find.byType(BannerUnidade, skipOffstage: false), findsNWidgets(4));
    expect(find.byKey(const Key('mapa-comecar')), findsOneWidget);
    expect(find.text('COMEÇAR'), findsOneWidget);
    expect(m.curso.state.trilhaIdx, 1);
    expect(m.curso.state.licaoIdx, 2);
    await _mostrar(tester, find.byKey(const Key('mapa-comecar')));
    await tester.tap(find.byKey(const Key('mapa-comecar')));
    await _anda(tester, 10);
    expect(find.byType(MapaPage), findsNothing, reason: 'praticar fecha o mapa e cai na lição');
    expect((m.curso.state.trilhaIdx, m.curso.state.licaoIdx), (1, 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('nota 9 = 3 estrelas cheias; 7 = 2; 5 = 1', (tester) async {
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    expect(_estrelas(3), findsNWidgets(3), reason: 'u1.l0 (10), u1.l1 (9) e u2.l0 (9)');
    expect(_estrelas(2), findsNWidgets(2), reason: 'u1.l2 (7) e u1.l3 (8)');
    expect(_estrelas(1), findsNWidgets(2), reason: 'u1.l4 (6) e u2.l1 (5)');
  });

  testWidgets('depois de onde a pessoa chegou o nó parece trancado (🔒) e a folha oferece o teste da unidade',
      (tester) async {
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    expect(_noNoEstado(EstadoNo.trancada), findsNWidgets(3 + 4 + 4), reason: 'u2.l3–l5, u3 e u4');
    expect(find.text('🔒', skipOffstage: false), findsWidgets);
    final trancado = _noNoEstado(EstadoNo.trancada).first;
    await _mostrar(tester, trancado);
    await tester.tap(trancado);
    await _anda(tester, 8);
    expect(find.byKey(const Key('sheet-trancada')), findsOneWidget);
    expect(find.text('Praticar lição'), findsOneWidget, reason: 'nada fica bloqueado de verdade');
    await tester.tap(find.byKey(const Key('sheet-teste-unidade')));
    await _anda(tester, 10);
    expect(find.byType(SessaoMemoriaPage), findsOneWidget);
  });

  testWidgets('a folha da lição: "🆕 Treinar as palavras novas" abre a sessão de treino', (tester) async {
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    final atual = _noNoEstado(EstadoNo.atual);
    expect(atual, findsOneWidget);
    expect(find.text('🆕 3', skipOffstage: false), findsWidgets, reason: 'as lições não feitas mostram quantas palavras novas trazem');
    await _mostrar(tester, atual);
    await tester.tap(atual);
    await _anda(tester, 8);
    expect(find.byKey(const Key('sheet-palavras')), findsOneWidget);
    expect(find.text('🆕 Treinar as palavras novas (3)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('sheet-palavras')));
    await _anda(tester, 10);
    expect(find.byType(TreinoPalavrasPage), findsOneWidget);
    expect(tester.widget<TreinoPalavrasPage>(find.byType(TreinoPalavrasPage)).palavras.map((p) => p.en),
        ['forest', 'friend', 'teacher'], reason: 'as 3 palavras novas de "Amigos novos"');
    // sai da sessão sem terminar: nada é registrado
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await _anda(tester, 10);
    expect(find.byType(TreinoPalavrasPage), findsNothing);
    expect(find.byType(MapaPage), findsOneWidget);
  });

  testWidgets('unidade completa = baú pronto; abrir mostra as palavras e "Treinar" leva à sessão do baú',
      (tester) async {
    final m = await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    expect(_bau(EstadoBau.pronto), findsOneWidget, reason: 'unidade 1 inteira feita');
    expect(_bau(EstadoBau.trancado), findsNWidgets(3));
    await _mostrar(tester, _bau(EstadoBau.pronto));
    await tester.tap(_bau(EstadoBau.pronto));
    await _anda(tester, 30);
    expect(find.text('Unidade dominada!'), findsOneWidget);
    expect(find.text('apple'), findsWidgets, reason: 'as palavras da unidade em leque');
    await tester.tap(find.byKey(const Key('bau-treinar')));
    await _anda(tester, 10);
    final treino = find.byType(TreinoPalavrasPage);
    expect(treino, findsOneWidget);
    final palavras = tester.widget<TreinoPalavrasPage>(treino).palavras;
    expect(palavras.length, 8, reason: 'a sessão leva até 8 das 12 palavras da unidade');
    // termina a sessão: o baú fica aberto (bau:<baralhoId> nas conquistas)
    tester.state<NavigatorState>(find.byType(Navigator).first).pop(
        ResultadoTreino(palavras: palavras, notas: const {}, passos: 0, pct: 100));
    await _anda(tester, 10);
    expect(m.curso.state.trilhas.first.baralhoId, 'tr:u1');
    expect(m.curso.state.projetosFeitos, contains('bau:tr:u1'));
    expect(_bau(EstadoBau.aberto), findsOneWidget);
    expect(_bau(EstadoBau.pronto), findsNothing);
  });

  testWidgets('baú já aberto (bau:<baralhoId> nas conquistas) aparece aberto', (tester) async {
    final p = progressoMeio()..projetos.add(chaveDoBau('tr:u1'));
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: p);
    expect(_bau(EstadoBau.aberto), findsOneWidget);
    expect(_bau(EstadoBau.pronto), findsNothing);
  });

  testWidgets('o card "Minhas palavras" abre a página do banco', (tester) async {
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    expect(find.byKey(const Key('palavras'), skipOffstage: false), findsOneWidget);
    await _mostrar(tester, find.byKey(const Key('palavras'), skipOffstage: false));
    await tester.tap(find.byKey(const Key('palavras')));
    await _anda(tester, 10);
    expect(find.byType(MinhasPalavrasPage), findsOneWidget);
  });

  testWidgets('progresso na trilha 4: o nó atual aparece ao abrir e "Onde parei" volta para ele', (tester) async {
    final p = ProgressoMemoria(
      feitas: {
        for (var l = 0; l < 5; l++) 'u1.l$l',
        for (var l = 0; l < 6; l++) 'u2.l$l',
        for (var l = 0; l < 4; l++) 'u3.l$l',
        'u4.l0',
      },
      pos: (3, 1),
    );
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: p);
    final atual = _noNoEstado(EstadoNo.atual);
    expect(atual, findsOneWidget);
    expect(_naTela(tester, atual), isTrue, reason: 'rolou sozinho até a lição atual');
    expect(find.byKey(const Key('mapa-onde-parei')), findsNothing);

    // volta para o topo: o nó sai da tela e aparece o "📍 Onde parei"
    final rolavel = tester.state<ScrollableState>(find.byType(Scrollable).first);
    rolavel.position.jumpTo(0);
    await _anda(tester, 3);
    expect(_naTela(tester, atual), isFalse);
    expect(find.byKey(const Key('mapa-onde-parei')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mapa-onde-parei')));
    await _anda(tester, 12);
    expect(_naTela(tester, atual), isTrue);
    expect(find.byKey(const Key('mapa-onde-parei')), findsNothing);
  });

  testWidgets('sem rolagem automática (MapaPage.rolarAoAbrir = false) o mapa abre no topo', (tester) async {
    MapaPage.rolarAoAbrir = false;
    addTearDown(() => MapaPage.rolarAoAbrir = true);
    final p = ProgressoMemoria(feitas: {for (var l = 0; l < 5; l++) 'u1.l$l', for (var l = 0; l < 6; l++) 'u2.l$l'});
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: p);
    expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.pixels, 0);
  });

  testWidgets('celular estreito (360): os nomes das lições são Text que dá para tocar, sem estouro', (tester) async {
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    expect(tester.takeException(), isNull);
    expect(find.text('No café', skipOffstage: false), findsOneWidget);
    expect(find.text('✈️ Viagens', skipOffstage: false), findsOneWidget);
    // tocar no nome abre a folha da lição
    await _mostrar(tester, find.text('No café', skipOffstage: false));
    await tester.tap(find.text('No café'));
    await _anda(tester, 8);
    expect(find.text('Praticar de novo'), findsOneWidget, reason: 'No café já foi feita');
  });

  testWidgets('desktop (1280×900): rótulos ao lado dos nós, sem estouro, o seno serpenteia', (tester) async {
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio(), tamanho: const Size(1280, 900));
    expect(tester.takeException(), isNull);
    expect(find.text('UNIDADE 2 · A1', skipOffstage: false), findsOneWidget);
    final xs = <double>{
      for (final e in find.byType(No3D).evaluate()) tester.getCenter(find.byWidget(e.widget)).dx.roundToDouble(),
    };
    expect(xs.length, greaterThanOrEqualTo(4), reason: 'os nós estão em várias colunas (seno), não numa linha');
    // o nome fica ao lado do nó (mesma altura), não embaixo
    await _mostrar(tester, find.text('No café', skipOffstage: false));
    final no = tester.getCenter(find.byWidgetPredicate((w) => w is No3D && w.rotulo == 'No café'));
    final nome = tester.getCenter(find.text('No café'));
    expect((nome.dy - no.dy).abs(), lessThan(12));
  });

  testWidgets('pumpAndSettle termina com uma página por cima do mapa (só animações de uma vez)', (tester) async {
    final m = await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    m.nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('por cima'))));
    await tester.pumpAndSettle();
    expect(find.text('por cima'), findsOneWidget);
  });

  testWidgets('volta ao mapa depois de concluir uma lição: o nó novo comemora (pop + confete), sem travar',
      (tester) async {
    final m = await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    // fecha o mapa, conclui a lição atual e abre de novo
    m.nav.currentState!.pop();
    await _anda(tester, 8);
    m.curso.add(const LicaoFinalizada());
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    m.nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const MapaPage()));
    await _anda(tester, 6);
    final comemora = find.byWidgetPredicate((w) => w is No3D && w.celebrar);
    expect(comemora, findsOneWidget);
    expect(tester.widget<No3D>(comemora).rotulo, 'Amigos novos');
    await _anda(tester, 30);
    expect(tester.takeException(), isNull);
  });

  testWidgets('outra conta na mesma sessão (outro CursoBloc) não herda as lições vistas: nada de comemoração',
      (tester) async {
    // conta A abre o mapa
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    // conta B (bloc novo) já fez mais lições — a primeira abertura dela não comemora nada
    final b = ProgressoMemoria(
      feitas: {...progressoMeio().feitas, 'u2.l2', 'u2.l3'},
      pos: (1, 4),
    );
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: b);
    expect(find.byWidgetPredicate((w) => w is No3D && w.celebrar, skipOffstage: false), findsNothing);
    await _anda(tester, 10);
    expect(tester.takeException(), isNull);
  });

  testWidgets('baú trancado com 1 lição faltando: "Termine a última lição" (sem "as 1 lições")', (tester) async {
    final p = ProgressoMemoria(
      feitas: {for (var l = 0; l < 5; l++) 'u1.l$l', for (var l = 0; l < 5; l++) 'u2.l$l'},
      pos: (1, 5),
    );
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: p);
    final trancado = _bau(EstadoBau.trancado).first;
    await _mostrar(tester, trancado);
    await tester.tap(trancado);
    await _anda(tester, 4);
    expect(find.text('🔒 Termine a última lição para abrir o baú.'), findsOneWidget);
    expect(find.textContaining('as 1 lições'), findsNothing);
  });

  testWidgets('dois baús prontos: só UM balança (o mais perto de onde a pessoa está), o outro fica parado',
      (tester) async {
    final p = ProgressoMemoria(
      feitas: {for (var l = 0; l < 5; l++) 'u1.l$l', for (var l = 0; l < 6; l++) 'u2.l$l'},
      pos: (2, 0),
    );
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: p);
    expect(_bau(EstadoBau.pronto), findsNWidgets(2));
    final balancando =
        find.byWidgetPredicate((w) => w is BauTrilha && w.estado == EstadoBau.pronto && w.balancar, skipOffstage: false);
    expect(balancando, findsOneWidget);
    expect(tester.widget<BauTrilha>(balancando).palavras, 12, reason: 'o da unidade 2 (6 lições × 3 → 12 no baú)');
  });

  testWidgets('teclado: Tab alcança os nós, o COMEÇAR, o baú e o guia; Enter abre', (tester) async {
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio(), tamanho: const Size(1280, 900));
    FocusNode focoDe(Finder f) =>
        Focus.of(tester.element(find.descendant(of: f, matching: find.byType(GestureDetector, skipOffstage: false), matchRoot: true).first));
    for (final f in [
      _noNoEstado(EstadoNo.atual),
      find.byKey(const Key('mapa-comecar')),
      _bau(EstadoBau.pronto),
      find.byKey(const Key('mapa-guia'), skipOffstage: false).first,
    ]) {
      expect(focoDe(f).canRequestFocus, isTrue, reason: '$f entra na ordem do Tab');
    }
    // Enter no nó atual abre a folha da lição
    final atual = _noNoEstado(EstadoNo.atual);
    await _mostrar(tester, atual);
    focoDe(atual).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await _anda(tester, 8);
    expect(find.byKey(const Key('sheet-palavras')), findsOneWidget);
    Navigator.of(tester.element(find.byKey(const Key('sheet-palavras')))).pop();
    await _anda(tester, 8);
    // Espaço no baú pronto abre o baú
    final bau = _bau(EstadoBau.pronto);
    await _mostrar(tester, bau);
    focoDe(bau).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await _anda(tester, 30);
    expect(find.text('Unidade dominada!'), findsOneWidget);
  });

  testWidgets('leitor de tela: o nó diz o estado e as estrelas', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    final cafe = tester.widget<No3D>(find.byWidgetPredicate((w) => w is No3D && w.rotulo == 'No café', skipOffstage: false));
    expect(cafe.rotuloLido, 'No café, concluída, 3 de 3 estrelas');
    final atual = tester.widget<No3D>(_noNoEstado(EstadoNo.atual));
    expect(atual.rotuloLido, 'Amigos novos, lição atual, 3 palavras novas');
    expect(tester.widget<No3D>(_noNoEstado(EstadoNo.trancada).first).rotuloLido, contains('mais adiante, trancada'));
    await _mostrar(tester, _noNoEstado(EstadoNo.atual));
    expect(find.bySemanticsLabel('Amigos novos, lição atual, 3 palavras novas'), findsOneWidget);
    expect(
      tester.getSemantics(_noNoEstado(EstadoNo.atual)),
      matchesSemantics(label: 'Amigos novos, lição atual, 3 palavras novas', isButton: true, isSelected: true,
          hasSelectedState: true, isFocusable: true, hasTapAction: true, hasFocusAction: true),
    );
    semantica.dispose();
  });

  testWidgets('o cartão "Minhas palavras" se atualiza quando o banco muda (sem depender do mapa)', (tester) async {
    final m = await montarMapa(tester, trilhas: cursoDeTeste(), progresso: progressoMeio());
    expect(find.textContaining('21 palavras', skipOffstage: false), findsOneWidget,
        reason: '7 lições feitas × 3 palavras novas');
    expect(m.palavras.adicionar('zebra', 'zebra'), isNull);
    await _anda(tester, 2);
    expect(find.textContaining('22 palavras', skipOffstage: false), findsOneWidget);
  });
}
