// 📺❓ No fim da historinha da lição, a pergunta OPCIONAL de compreensão: aparece quando a fila acaba,
// responde na hora (certa/errada), o 🔊 fala na saída do player, "Pular"/Esc fecha, "Ver de novo" toca de
// novo, e nada disso mexe no progresso. Lição com menos de 3 frases: só o véu do fim, como antes.
// (O app, o fake de áudio e o currículo pequeno são os do ingles_assistir_licao_test.)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
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
import 'package:pac_dart/features/ingles/domain/assistir/pergunta_compreensao.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/assistir_licao_page.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/tocando_page.dart' show nomeDeQuem;
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
  final pendentes = <({String tipo, String texto, Completer<FimDaFala> fim, DateTime inicio})>[];
  final faladas = <String>[];
  var paradas = 0;

  Future<FimDaFala> _pendente(String tipo, String texto) {
    final c = Completer<FimDaFala>();
    pendentes.add((tipo: tipo, texto: texto, fim: c, inicio: DateTime.now()));
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

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

/// O player da tela do 📺 (o próprio, não o do Ouvir).
OuvirCubit _player(WidgetTester tester) => tester.widget<AssistirLicaoPage>(find.byType(AssistirLicaoPage)).cubit;

/// Deixa cada fala/silêncio pendente terminar até a historinha acabar.
///
/// O player da tela é o `OuvirCubit` de verdade, com o relógio de verdade (`DateTime.now`): uma fala em inglês
/// que "acaba" em menos de [OuvirCubit.instantanea] conta como som que não saiu, e 3 seguidas pausam com
/// `MotivoPausa.semSom`. Por isso a fala falsa só termina depois de durar esse mínimo em tempo real, como uma
/// voz de verdade (sem isso, numa máquina rápida as 3 falas acabavam em ~30 ms e o player pausava no meio).
Future<void> _ateOFim(WidgetTester tester, _SaidaFake saida) async {
  final cubit = _player(tester);
  final duracaoMinima = OuvirCubit.instantanea + const Duration(milliseconds: 50);
  for (var i = 0; i < 80 && cubit.state.status != StatusOuvir.acabou; i++) {
    final falas = [for (final p in saida.pendentes) if (p.tipo == 'en' && !p.fim.isCompleted) p];
    if (falas.isNotEmpty) {
      final falta = duracaoMinima - DateTime.now().difference(falas.first.inicio);
      if (falta > Duration.zero) await tester.runAsync(() => Future<void>.delayed(falta));
    }
    for (final p in [...saida.pendentes]) {
      if (!p.fim.isCompleted) p.fim.complete(FimDaFala.acabou);
    }
    saida.pendentes.clear();
    await _anda(tester, 1);
  }
  expect(cubit.state.status, StatusOuvir.acabou, reason: 'motivo da pausa: ${cubit.state.motivo}');
  await _passa(tester);
}

/// Uma "foto" do que está gravado nas prefs (para ver que a pergunta não grava nada).
Future<Map<String, Object?>> _prefs(WidgetTester tester) async {
  final p = (await tester.runAsync(SharedPreferences.getInstance))!;
  return {for (final k in p.getKeys()) k: p.get(k)};
}

Future<void> _tecla(WidgetTester tester, LogicalKeyboardKey k) async {
  await tester.sendKeyEvent(k);
  await _passa(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    FraseView.carencia = Duration.zero;
    MapaPage.esquecerVistas();
  });
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgetsDesktop('📺❓ no fim: a pergunta aparece, responde certo/errado, 🔊 fala, pular fecha, sem progresso',
      (tester) async {
    final saida = _SaidaFake();
    await _abrirApp(tester, linguagem: Linguagem.ingles, saida: saida);
    final ctx = tester.element(find.byType(HomePage));
    final curso = ctx.read<CursoBloc>();
    final concluidasAntes = curso.state.concluidas.length;

    await _tocar(tester, 'licao-assistir');
    await _anda(tester, 4);
    expect(find.byType(AssistirLicaoPage), findsOneWidget);
    expect(_k('assistir-pergunta'), findsNothing, reason: 'nada de pergunta enquanto a historinha toca');

    // ── chega ao fim: a pergunta aparece por cima do palco
    await _ateOFim(tester, saida);
    expect(_k('assistir-pergunta'), findsOneWidget);
    final cubit = _player(tester);
    final p = perguntaDaLicao('mesa.cha', cubit.state.fila, nomeDe: nomeDeQuem)!;
    expect(find.text(p.enunciado), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      expect(find.descendant(of: _k('assistir-pergunta-opcao-$i'), matching: find.text(p.opcoes[i])), findsOneWidget);
      expect(tester.getSize(_k('assistir-pergunta-opcao-$i')).height, greaterThanOrEqualTo(48));
    }
    expect(tester.getSize(_k('assistir-pergunta-pular')).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(_k('assistir-pergunta-ouvir')).height, greaterThanOrEqualTo(48));
    final prefsAntes = await _prefs(tester);

    // 🔊 fala a frase na saída do player
    saida.faladas.clear();
    await _tocar(tester, 'assistir-pergunta-ouvir');
    expect(saida.faladas, [p.frase]);

    // ── responde ERRADO: a errada marcada e a certa mostrada
    final errada = (p.certa + 1) % 3;
    await _tocar(tester, 'assistir-pergunta-opcao-$errada');
    expect(find.text('❌ Quase! A certa é «${p.opcoes[p.certa]}».'), findsOneWidget);
    expect(find.bySemanticsLabel('Opção ${errada + 1}: ${p.opcoes[errada]}, errada'), findsOneWidget);
    expect(find.bySemanticsLabel('Opção ${p.certa + 1}: ${p.opcoes[p.certa]}, certa'), findsOneWidget);
    expect(_k('assistir-pergunta-pular'), findsNothing);
    expect(_k('assistir-pergunta-de-novo'), findsOneWidget);
    expect(_k('assistir-pergunta-voltar'), findsOneWidget);
    // a resposta não muda depois de escolhida
    await _tecla(tester, LogicalKeyboardKey.digit1);
    expect(find.text('❌ Quase! A certa é «${p.opcoes[p.certa]}».'), findsOneWidget);

    // ── "Ver de novo": fecha e toca a historinha de novo
    await _tocar(tester, 'assistir-pergunta-de-novo');
    await _anda(tester, 2);
    expect(_k('assistir-pergunta'), findsNothing);
    expect(cubit.state.status, StatusOuvir.tocando);

    // ── de novo no fim: a mesma pergunta, sem resposta; o teclado (1/2/3) responde CERTO
    await _ateOFim(tester, saida);
    expect(_k('assistir-pergunta'), findsOneWidget);
    expect(find.text(p.enunciado), findsOneWidget);
    expect(_k('assistir-pergunta-pular'), findsOneWidget, reason: 'a resposta anterior não fica');
    await _tecla(tester, [LogicalKeyboardKey.digit1, LogicalKeyboardKey.digit2, LogicalKeyboardKey.digit3][p.certa]);
    expect(find.text('✅ Isso!'), findsOneWidget);
    expect(find.bySemanticsLabel('Opção ${p.certa + 1}: ${p.opcoes[p.certa]}, certa'), findsOneWidget);

    // Esc fecha a pergunta (não a tela): fica o véu "▶ de novo"
    await _tecla(tester, LogicalKeyboardKey.escape);
    expect(_k('assistir-pergunta'), findsNothing);
    expect(find.byType(AssistirLicaoPage), findsOneWidget);
    expect(_k('assistir-fim'), findsOneWidget);

    // ── ▶ de novo pela barra, fim de novo, "Pular" fecha
    await _tocar(tester, 'assistir-licao-play');
    await _ateOFim(tester, saida);
    expect(_k('assistir-pergunta'), findsOneWidget);
    await _tocar(tester, 'assistir-pergunta-pular');
    expect(_k('assistir-pergunta'), findsNothing);
    expect(_k('assistir-fim'), findsOneWidget);
    expect(find.text('🏁 Fim da historinha'), findsOneWidget);

    // nada gravado: nem lição concluída nem prefs
    expect(curso.state.concluidas.length, concluidasAntes, reason: 'a pergunta não marca progresso');
    expect(await _prefs(tester), prefsAntes, reason: 'responder não grava nada');

    // Esc sem a pergunta volta para a lição, como antes
    await _tecla(tester, LogicalKeyboardKey.escape);
    await _anda(tester, 4);
    expect(find.byType(AssistirLicaoPage), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgetsDesktop('📺❓ "Voltar para a lição" depois de responder fecha a tela', (tester) async {
    final saida = _SaidaFake();
    await _abrirApp(tester, linguagem: Linguagem.ingles, saida: saida);
    await _tocar(tester, 'licao-assistir');
    await _anda(tester, 4);
    await _ateOFim(tester, saida);
    await _tecla(tester, LogicalKeyboardKey.digit2);
    expect(_k('assistir-pergunta-resultado'), findsOneWidget);
    await _tocar(tester, 'assistir-pergunta-voltar');
    await _anda(tester, 4);
    expect(find.byType(AssistirLicaoPage), findsNothing);
    expect(find.byType(PalcoIngles), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgetsDesktop('📺❓ lição com menos de 3 frases: no fim só o véu, sem pergunta', (tester) async {
    final saida = _SaidaFake();
    await _abrirApp(tester, linguagem: Linguagem.ingles, saida: saida);
    await tester.tap(find.text('Mapa'));
    await _passa(tester);
    final mapaCtx = tester.element(find.byType(MapaPage));
    mostrarOpcoesLicao(mapaCtx, mapaCtx.read<CursoBloc>().state, 0, 1, null);
    await _passa(tester);
    await _tocar(tester, 'sheet-assistir');
    await _anda(tester, 4);
    expect(find.text('📺 De novo'), findsOneWidget);
    await _ateOFim(tester, saida);
    expect(_k('assistir-pergunta'), findsNothing);
    expect(_k('assistir-fim'), findsOneWidget);
    expect(find.text('🏁 Fim da historinha'), findsOneWidget);
    await _tocar(tester, 'assistir-licao-fechar');
    expect(tester.takeException(), isNull);
  });
}
