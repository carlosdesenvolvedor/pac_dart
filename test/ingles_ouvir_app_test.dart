// Ponta a ponta no PacDartApp inteiro (inglês) do "🎧 Ouvir" (Fase 8): HUD 🎧 → "Do começo" → o mini-player
// aparece e fica embaixo de todas as rotas (abre e fecha o Mapa) → ➕ na folha da lição põe em "Minha setlist"
// (snackbar; o hub mostra a setlist com 1 item) → o ➕ do palco existe e põe a frase → a saída devolve
// "cortada" (outra fala começou): o player pausa e o "Tocando agora" mostra o aviso → ✕ fecha.
// E no curso de Dart nada disso existe (sem botão no HUD, sem mini-player, sem OuvirShell).
import 'dart:async';

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
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/setlists_repository.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/setlists_cubit.dart';
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
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

/// A saída de áudio falsa: cada fala/silêncio fica PENDENTE até o teste decidir (o player fica "tocando"
/// parado na frase, sem som e sem relógio de verdade). `parar()` corta tudo o que está pendente.
/// A duração longa deixa o vigia de cada passo (segundos × 2,5 + 3 s) bem longe dos pumps do teste.
class _SaidaFake implements SaidaDeAudio {
  final pendentes = <({String tipo, String texto, Completer<FimDaFala> fim})>[];
  final faladas = <String>[];
  var paradas = 0;

  Future<FimDaFala> _pendente(String tipo, String texto) {
    final c = Completer<FimDaFala>();
    pendentes.add((tipo: tipo, texto: texto, fim: c));
    return c.future;
  }

  @override
  Future<FimDaFala> en(String texto, {required double fator}) {
    faladas.add(texto);
    return _pendente('en', texto);
  }

  @override
  Future<FimDaFala> pt(String texto, {required double fator}) => _pendente('pt', texto);

  @override
  Future<FimDaFala> silencio(Duration d) => _pendente('silencio', '');

  @override
  void parar() {
    paradas++;
    for (final p in pendentes) {
      if (!p.fim.isCompleted) p.fim.complete(FimDaFala.cortada);
    }
    pendentes.clear();
  }

  /// Outra fala do app cortou a frase do player (sem o player ter pedido).
  void cortarDeFora() {
    final vivas = [for (final p in pendentes) if (!p.fim.isCompleted) p];
    expect(vivas, isNotEmpty, reason: 'o player está esperando uma fala');
    vivas.last.fim.complete(FimDaFala.cortada);
    pendentes.remove(vivas.last);
  }

  @override
  void preaquecer(String texto) {}

  @override
  bool get somLiberado => true;

  @override
  double duracaoDe(String en) => 600;

  @override
  bool temGravacao(String en) => true;
}

/// Um currículo pequeno: 1 unidade, 2 lições, 5 frases.
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
              Trecho(id: 'f-000001', quem: 'mike', cod: 'Tea with milk, please.', dica: 'Chá com leite, por favor.', out: ''),
              Trecho(id: 'f-000002', quem: 'ana', cod: 'Here you are.', dica: 'Aqui está.', out: ''),
              Trecho(id: 'f-000003', quem: 'mike', cod: 'Thank you so much.', dica: 'Muito obrigado.', out: ''),
            ]),
            Licao(nome: 'De novo', emoji: '🔁', id: 'mesa.de-novo', trechos: [
              Trecho(id: 'f-000004', quem: 'ana', cod: 'How are you?', dica: 'Como vai você?', out: ''),
              Trecho(id: 'f-000005', quem: 'mike', cod: 'Fine, thanks.', dica: 'Bem, obrigado.', out: ''),
            ]),
          ],
        ),
      ];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

class _LoaderDart extends CurriculoLoader {
  _LoaderDart() : super(linguagem: Linguagem.dart);
  @override
  Future<List<Trilha>> carregar() async => const [
        Trilha(
          nivel: 'Fundamentos',
          emoji: '🎯',
          licoes: [
            Licao(nome: 'Variáveis', emoji: '📦', trechos: [
              Trecho(cod: "var nome = 'Ana';", dica: 'Declare uma variável.', out: ''),
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

/// Deixa terminar as animações de uma vez (rotas, folhas, snackbar).
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

Future<void> _abrirApp(WidgetTester tester, {required Linguagem linguagem, _SaidaFake? saida, Size? tela}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false});
  tester.view.physicalSize = tela ?? const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      palavrasBuilder: (_) => MemoriaPalavrasRepository(),
      setlistsBuilder: (_) => MemoriaSetlistsRepository(),
      saidaOuvirBuilder: () => saida ?? _SaidaFake(),
      rankingBuilder: () => _Ranking(),
      habitoBuilder: (u) => LocalHabitoRepository(uid: u.uid),
      curriculoBuilder: (l) => l == Linguagem.ingles ? _LoaderEn() : _LoaderDart(),
      linguagemInicial: linguagem,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, linguagem == Linguagem.ingles ? find.byType(PalcoIngles) : find.text('SCORE'));
  await _anda(tester, 4);
}

Finder _k(String chave) => find.byKey(Key(chave));
bool _tem(String chave) => _k(chave).evaluate().isNotEmpty;

Future<void> _tocar(WidgetTester tester, String chave) async {
  final alvo = _k(chave);
  expect(alvo, findsOneWidget, reason: chave);
  await tester.ensureVisible(alvo);
  await _passa(tester);
  await tester.tap(alvo);
  await _passa(tester);
}

/// Volta para o palco (fecha as rotas que estiverem por cima).
Future<void> _voltarAoPalco(WidgetTester tester) async {
  // com rotas por cima o palco fica "offstage": acha mesmo assim
  final nav = Navigator.of(tester.element(find.byType(HomePage, skipOffstage: false)));
  nav.popUntil((r) => r.isFirst);
  await _passa(tester);
}

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    FraseView.carencia = Duration.zero;
    MapaPage.esquecerVistas();
  });
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgetsDesktop('🎧 Ouvir: HUD → Do começo → mini-player nas rotas → ➕ na setlist → outra fala pausa',
      (tester) async {
    final saida = _SaidaFake();
    await _abrirApp(tester, linguagem: Linguagem.ingles, saida: saida);
    final ctx = tester.element(find.byType(HomePage));
    final ouvir = OuvirCubit.de(ctx);
    final setlists = SetlistsCubit.de(ctx);
    expect(ouvir, isNotNull, reason: 'o inglês tem o player');
    expect(setlists, isNotNull, reason: 'o inglês tem as setlists');
    expect(find.byType(OuvirShell), findsOneWidget, reason: 'a moldura do mini-player fica no MaterialApp.builder');
    expect(_tem('mini-player'), isFalse, reason: 'nunca toca sozinho: parado não mostra a barra');
    expect(ouvir!.state.status, StatusOuvir.parado);

    // ── 1. HUD 🎧 → hub → "Do começo": começa pela 1ª frase do curso e o mini-player aparece
    await _tocar(tester, 'ouvir-hud');
    expect(_tem('ouvir-curso-inicio'), isTrue, reason: 'o hub "🎧 Ouvir" abriu');
    await _tocar(tester, 'ouvir-curso-inicio');
    await _anda(tester, 4);
    expect(ouvir.state.ativo, isTrue);
    expect(ouvir.state.fonte?.id, 'curso');
    expect(ouvir.state.fila.length, 5, reason: 'o curso inteiro: 5 frases');
    expect(ouvir.state.indice, 0);
    expect(saida.faladas, isNotEmpty);
    expect(saida.faladas.first, 'Tea with milk, please.');
    // se o "Tocando agora" abriu por cima, minimiza
    if (!_tem('mini-player') && _tem('ouvir-play')) {
      Navigator.of(tester.element(_k('ouvir-play'))).pop();
      await _passa(tester);
    }
    await _voltarAoPalco(tester);
    expect(_k('mini-player'), findsOneWidget, reason: 'tocando: a barra fica embaixo do palco');

    // ── 2. abre e fecha o Mapa: a barra continua (ela fica acima do Navigator)
    await tester.tap(find.text('Mapa'));
    await _passa(tester);
    expect(find.byType(MapaPage), findsOneWidget);
    expect(_k('mini-player'), findsOneWidget, reason: 'a barra sobrevive à troca de rota');
    expect(_k('ouvir-cartao-mapa'), findsOneWidget, reason: 'o cartão "🎧 Ouvir" do mapa');

    // ── 3. a folha da lição: ➕ "Pôr na setlist" → snackbar e "Minha setlist" com a lição
    final mapaCtx = tester.element(find.byType(MapaPage));
    final st = mapaCtx.read<CursoBloc>().state;
    mostrarOpcoesLicao(mapaCtx, st, 0, 0, null);
    await _passa(tester);
    expect(_k('ouvir-licao-tocar'), findsOneWidget);
    expect(_k('ouvir-licao-daqui'), findsOneWidget);
    expect(_k('ouvir-licao-frases'), findsOneWidget);
    await _tocar(tester, 'ouvir-licao-add');
    await _anda(tester, 4);
    expect(_k('ouvir-licao-add'), findsNothing, reason: 'a folha fecha antes do snackbar');
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.descendant(of: find.byType(SnackBar), matching: find.textContaining('Minha setlist')), findsOneWidget);
    final visiveis = setlists!.state.visiveis;
    expect(visiveis.length, 1);
    expect(visiveis.single.nome, 'Minha setlist');
    expect(visiveis.single.itens.length, 1);
    expect(visiveis.single.itens.single.tipo, TipoItem.licao);
    expect(visiveis.single.itens.single.ref, 'mesa.cha');
    expect(_k('mini-player'), findsOneWidget);

    // o cartão do mapa abre o hub, que mostra a setlist
    ScaffoldMessenger.of(mapaCtx).hideCurrentSnackBar();
    await _passa(tester);
    await _tocar(tester, 'ouvir-cartao-mapa');
    expect(_k('setlist-${visiveis.single.id}'), findsOneWidget, reason: 'o hub lista "Minha setlist"');
    expect(find.textContaining('Minha setlist'), findsWidgets);
    expect(_k('mini-player'), findsOneWidget);

    // ── 4. de volta ao palco: o ➕ da frase existe e põe a frase na mesma setlist
    await _voltarAoPalco(tester);
    expect(find.byType(MapaPage), findsNothing);
    expect(_k('mini-player'), findsOneWidget, reason: 'a barra continua depois de fechar o mapa');
    expect(_k('botao-setlist'), findsOneWidget);
    await _tocar(tester, 'botao-setlist');
    await _anda(tester, 4);
    final itens = setlists.state.visiveis.single.itens;
    expect(itens.length, 2);
    expect(itens.last.tipo, TipoItem.frase);
    ScaffoldMessenger.of(tester.element(find.byType(HomePage))).hideCurrentSnackBar();
    await _passa(tester);

    // ── 5. outra fala cortou a frase do player: pausa (não pula, não volta sozinho) e o aviso aparece
    final antes = ouvir.state.indice;
    saida.cortarDeFora();
    await _anda(tester, 4);
    expect(ouvir.state.status, StatusOuvir.pausado);
    expect(ouvir.state.motivo, MotivoPausa.outraFala);
    expect(ouvir.state.indice, antes, reason: 'cortada não avança');
    expect(_k('mini-player'), findsOneWidget, reason: 'pausado continua com a barra');
    await _tocar(tester, 'mini-player');
    expect(_k('ouvir-banner-outra-fala'), findsOneWidget, reason: 'o "Tocando agora" avisa que outra fala começou');
    expect(_k('mini-player'), findsNothing, reason: 'com o "Tocando agora" aberto a barra some');
    Navigator.of(tester.element(_k('ouvir-banner-outra-fala'))).pop();
    await _passa(tester);
    expect(_k('mini-player'), findsOneWidget);

    // ✕ fecha a sessão: a barra some
    await _tocar(tester, 'mini-player-fechar');
    expect(ouvir.state.status, StatusOuvir.parado);
    expect(_k('mini-player'), findsNothing);
    expect(tester.takeException(), isNull);

    // deixa vencer os relógios pendentes (vigia do passo, gravação das setlists, snackbar)
    await tester.pump(const Duration(minutes: 30));
    await tester.pump();
  });

  testWidgetsDesktop('🎧 Ouvir: o cartão do mapa e o HUD cabem no celular (390 px), sem estouro', (tester) async {
    await _abrirApp(tester, linguagem: Linguagem.ingles, tela: const Size(390, 844));
    expect(_k('ouvir-hud'), findsOneWidget);
    expect(tester.takeException(), isNull);
    // no celular o HUD rola junto com o palco: abre o mapa direto pelo Navigator
    Navigator.of(tester.element(find.byType(HomePage)))
        .push(MaterialPageRoute<void>(builder: (_) => const MapaPage()));
    await _passa(tester);
    final cartao = find.byKey(const Key('ouvir-cartao-mapa'), skipOffstage: false);
    expect(cartao, findsOneWidget);
    await tester.ensureVisible(cartao);
    await _passa(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgetsDesktop('curso de Dart: sem 🎧 no HUD, sem mini-player e sem OuvirShell', (tester) async {
    await _abrirApp(tester, linguagem: Linguagem.dart);
    final ctx = tester.element(find.byType(HomePage));
    expect(OuvirCubit.de(ctx), isNull);
    expect(SetlistsCubit.de(ctx), isNull);
    expect(NavegadorOuvir.de(ctx), isNull);
    expect(_k('ouvir-hud'), findsNothing);
    expect(find.byType(OuvirShell), findsNothing);
    expect(_k('mini-player'), findsNothing);
    expect(find.byType(BotaoPorNaSetlist), findsNothing);

    await tester.tap(find.text('Mapa'));
    await _passa(tester);
    expect(find.byType(MapaPage), findsOneWidget);
    expect(_k('ouvir-cartao-mapa'), findsNothing);
    expect(_k('mini-player'), findsNothing);
    final mapaCtx = tester.element(find.byType(MapaPage));
    mostrarOpcoesLicao(mapaCtx, mapaCtx.read<CursoBloc>().state, 0, 0, null);
    await _passa(tester);
    expect(_k('ouvir-licao-tocar'), findsNothing);
    expect(_k('ouvir-licao-add'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
