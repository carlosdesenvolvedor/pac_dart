// 📺 na lição: "Assistir a historinha" no começo da lição e na folha do mapa abre o desenho com um player
// PRÓPRIO — a fila do 🎧 Ouvir não muda (só pausa se tocava), o progresso não muda, e ao fechar a lição volta.
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
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/assistir_licao_page.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
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
      curriculoBuilder: (_) => _LoaderEn(),
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

  testWidgetsDesktop('📺 na lição: player próprio, a fila do Ouvir só pausa, o progresso não muda', (tester) async {
    final saida = _SaidaFake();
    await _abrirApp(tester, linguagem: Linguagem.ingles, saida: saida);
    final ctx = tester.element(find.byType(HomePage));
    final ouvir = OuvirCubit.de(ctx)!;
    final curso = ctx.read<CursoBloc>();

    // o 🎧 Ouvir tocando o curso inteiro (5 frases)
    await _tocar(tester, 'ouvir-hud');
    await _tocar(tester, 'ouvir-curso-inicio');
    await _anda(tester, 4);
    await _voltarAoPalco(tester);
    expect(ouvir.state.status, StatusOuvir.tocando);
    expect(ouvir.state.fila.length, 5);

    // ── o link no começo da lição abre o desenho
    expect(_k('licao-assistir'), findsOneWidget, reason: 'a lição do curso tem historinha');
    final concluidasAntes = curso.state.concluidas.length;
    saida.faladas.clear();
    await _tocar(tester, 'licao-assistir');
    await _anda(tester, 4);
    expect(find.byType(AssistirLicaoPage), findsOneWidget);
    expect(_k('assistir-palco'), findsOneWidget, reason: 'o palco do 📺 dentro da tela da lição');
    expect(ouvir.state.status, StatusOuvir.pausado, reason: 'o Ouvir pausa (não troca de fila)');
    expect(ouvir.state.fonte?.id, 'curso');
    expect(ouvir.state.fila.length, 5, reason: 'a fila do Ouvir continua a do curso');
    expect(saida.faladas, isNotEmpty);
    expect(saida.faladas.first, 'Tea with milk, please.', reason: 'o player próprio toca a 1ª frase da lição');
    expect(find.text('Frase 1 de 3'), findsOneWidget, reason: 'só as 3 frases da lição');

    // ⏭ anda no player próprio, não no do Ouvir
    await _tocar(tester, 'assistir-licao-proxima');
    await _anda(tester, 4);
    expect(find.text('Frase 2 de 3'), findsOneWidget);
    expect(ouvir.state.indice, 0);

    // ✕ volta para a lição: o player próprio cala e o progresso não mudou
    final paradas = saida.paradas;
    await _tocar(tester, 'assistir-licao-fechar');
    await _anda(tester, 4);
    expect(find.byType(AssistirLicaoPage), findsNothing);
    expect(find.byType(PalcoIngles), findsOneWidget);
    expect(saida.paradas, greaterThan(paradas), reason: 'fechar cala o player da lição');
    expect(curso.state.concluidas.length, concluidasAntes, reason: 'assistir não marca progresso');
    expect(ouvir.state.status, StatusOuvir.pausado, reason: 'o Ouvir não volta sozinho');
    expect(tester.takeException(), isNull);
  });

  testWidgetsDesktop('📺 na folha da lição do mapa: "Assistir a historinha" abre o desenho', (tester) async {
    await _abrirApp(tester, linguagem: Linguagem.ingles);
    await tester.tap(find.text('Mapa'));
    await _passa(tester);
    final mapaCtx = tester.element(find.byType(MapaPage));
    mostrarOpcoesLicao(mapaCtx, mapaCtx.read<CursoBloc>().state, 0, 1, null);
    await _passa(tester);
    expect(_k('sheet-assistir'), findsOneWidget);
    await _tocar(tester, 'sheet-assistir');
    await _anda(tester, 4);
    expect(_k('sheet-assistir'), findsNothing, reason: 'a folha fecha antes');
    expect(find.byType(AssistirLicaoPage), findsOneWidget);
    expect(find.text('📺 De novo'), findsOneWidget);
    expect(find.text('Frase 1 de 2'), findsOneWidget);
    expect(OuvirCubit.de(mapaCtx)!.state.status, StatusOuvir.parado, reason: 'o Ouvir nem começou');
    await _tocar(tester, 'assistir-licao-fechar');
    expect(find.byType(AssistirLicaoPage), findsNothing);
    expect(find.byType(MapaPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
