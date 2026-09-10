import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:flutter/services.dart';
import 'package:pac_dart/features/arcade/domain/banco_desafios.dart';
import 'package:pac_dart/features/arcade/domain/baralho.dart';
import 'package:pac_dart/features/arcade/domain/desafio.dart';
import 'package:pac_dart/features/arcade/domain/palavras_dart.dart';
import 'package:pac_dart/features/arcade/domain/tiro_engine.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/arcade/presentation/caca_bug_page.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/corrida_page.dart';
import 'package:pac_dart/features/arcade/domain/gerador_missoes.dart';
import 'package:pac_dart/features/arcade/presentation/futebol_page.dart';
import 'package:pac_dart/features/arcade/presentation/missao_page.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
import 'package:pac_dart/features/arcade/presentation/turismo_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/minimapa.dart';
import 'package:pac_dart/features/arcade/data/engenheiro_gt.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/campo_teclas.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/widgets/code_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/ranking/presentation/ranking_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RepoFake implements RankingRepository {
  final Map<String, int> doc = {};
  final Map<String, int> recordes = {};

  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {
    deltas.forEach((k, v) => doc[k] = (doc[k] ?? 0) + v);
  }

  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async {
    if (pontos <= (recordes[jogo] ?? 0)) return false;
    recordes[jogo] = pontos;
    return true;
  }

  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

Widget _app(RankingCubit cubit, Widget home) => BlocProvider.value(
      value: cubit,
      child: MaterialApp(theme: Mixart.tema(), home: home),
    );

/// Espera a largada 3-2-1 terminar (os relógios só ligam depois dela).
Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  SharedPreferences.setMockInitialValues({});

  testWidgets('hub do Arcade mostra os seis joguinhos', (tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const ArcadePage()));
    await tester.pump();

    expect(find.text('🎮 Arcade Dart'), findsOneWidget);
    expect(find.text('Dart Turismo'), findsOneWidget);
    expect(find.text('Chuva de Código'), findsOneWidget);
    expect(find.text('Rali de Digitação'), findsOneWidget);
    expect(find.text('Corrida do Código'), findsOneWidget);
    expect(find.text('Gol de Dart'), findsOneWidget);
    expect(find.text('Caça-Bug'), findsOneWidget);
    expect(find.text('Jogar'), findsNWidgets(6));
    // seletor de personagem: Pac e Dash
    expect(find.text('Pac'), findsOneWidget);
    expect(find.text('Dash'), findsOneWidget);
    // e o cartão de destaque das missões
    expect(find.text('Lógica Animada'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Chuva de Código: digitar a palavra que cai destrói e pontua',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _RepoFake();
    final cubit = RankingCubit(repo: repo, uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const ChuvaPage(semente: 5)));
    await tester.pump();
    // durante a largada 3-2-1 nada cai
    expect(find.text('VAI!'), findsNothing);
    await tester.pump(const Duration(milliseconds: 2000));
    expect(find.text('VAI!'), findsOneWidget);
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60)); // 1º tick → spawn

    // a mesma semente revela qual palavra nasceu (e se é dourada)
    final replica = TiroEngine(rnd: Random(5))..tick(0.06);
    final caindo = replica.ativas.first;
    // só o chip da palavra (RichText) — o TextField oculto guarda o digitado
    final chip = find.byWidgetPredicate(
        (w) => w is RichText && w.text.toPlainText() == caindo.texto);
    expect(chip, findsOneWidget);

    // digita a palavra inteira — cada letra é um tiro
    var texto = '';
    for (final ch in caindo.texto.split('')) {
      texto += ch;
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump(const Duration(milliseconds: 30));
    }

    // destruída: sai da arena e os pontos entram no placar
    expect(chip, findsNothing);
    final ganho = (10 + caindo.texto.length) * (caindo.ouro ? 4 : 1);
    expect(find.text('$ganho'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Rali: digitar a palavra sem erro dá turbo e chama a próxima',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const RaliPage(semente: 3)));
    await tester.pump();

    await tester.tap(find.text('Fácil'));
    await tester.pump();
    expect(find.text('VOCÊ'), findsOneWidget);
    await _largada(tester);

    final palavra = baralhoRali(Random(3))[0];
    var texto = '';
    for (final ch in palavra.split('')) {
      texto += ch;
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump();
    }

    expect(find.text('🔥 Palavra perfeita — TURBO!'), findsOneWidget);
    expect(find.text('PALAVRA 2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Gol de Dart: 5 gols passam de fase; parar guarda 130 pts no ranking',
      (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _RepoFake();
    final cubit = RankingCubit(repo: repo, uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const FutebolPage(semente: 42)));
    await tester.pump();

    // a mesma semente reproduz o sorteio da tela (fase 1 = só nível 1)
    final fila = BaralhoDesafios(
            rnd: Random(42), tipo: TipoDesafio.sintaxe, banco: bancoDesafios)
        .sortear(5, 1);
    expect(fila.every((d) => d.nivel == 1), isTrue);

    for (var i = 0; i < 5; i++) {
      final certa = fila[i].opcoes[fila[i].certa];
      final alvo = find.text(certa, findRichText: true).last;
      await tester.ensureVisible(alvo);
      await tester.pump();
      await tester.tap(alvo);
      await tester.pump();
      expect(find.textContaining('GOOOOL'), findsOneWidget, reason: 'cobrança ${i + 1}');
      // espera a animação e o avanço para a próxima cobrança (ou o fim)
      await tester.pump(const Duration(milliseconds: 2100));
      await tester.pump();
    }

    // 3+ gols passam de fase: overlay com dica de Dart e pontos acumulados
    await tester.pump();
    expect(find.text('FASE 1 CONCLUÍDA!'), findsOneWidget);
    expect(find.textContaining('Dica Dart'), findsOneWidget);

    // parar entrega o total pro ranking (5 gols x20 + 30 da série perfeita)
    await tester.tap(find.text('Parar e guardar pontos'));
    await tester.pump();
    await tester.pump();
    expect(find.text('+130 pts'), findsOneWidget);
    expect(find.textContaining('NOVO RECORDE'), findsOneWidget);
    expect(repo.doc['arcadePontos'], 130);
    expect(repo.doc['pontos'], 130);
    expect(repo.recordes['futebol'], 130);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Lógica Animada: prever → ajuda misteriosa → digitar → animar → vencer',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _RepoFake();
    final cubit = RankingCubit(repo: repo, uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(
      cubit,
      const MissaoPage(
          trilhaIdx: 0, trilhaNome: 'Fundamentos', trilhaEmoji: '🌱', indiceInicial: 0),
    ));
    await tester.pump();
    await tester.pump();

    // ATO 1: a missão 0 da trilha 0 é determinística
    final missao = missaoPara(0, 0);
    expect(find.text('ATO 1 · PREVEJA'), findsOneWidget);
    expect(find.text(missao.pergunta), findsOneWidget);

    // 🔮 pede uma ajuda misteriosa (custa 5 pts)
    await tester.tap(find.textContaining('Ajuda misteriosa'));
    await tester.pump();
    expect(find.text('🔮 Ajuda Misteriosa'), findsOneWidget);
    expect(find.text(missao.dicas.first), findsOneWidget);
    await tester.tap(find.text('Entendi'));
    await tester.pump();

    // responde a previsão certa
    final alvo = find.text(missao.opcoes[missao.certa], findRichText: true).last;
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await tester.pump();
    expect(find.textContaining('Previsão certeira'), findsOneWidget);

    // ATO 2: digita o código inteiro (digitação perfeita via motor)
    await tester.tap(find.text('Digitar pra destravar →'));
    await tester.pump();
    final bloc = BlocProvider.of<TypingBloc>(tester.element(find.byType(CodeView)));
    var guarda = 0;
    while (!bloc.state.concluido && guarda++ < 400) {
      bloc.add(TeclaDigitada(bloc.state.chars[bloc.state.idx]));
      await tester.pump();
    }
    expect(bloc.state.concluido, isTrue);
    await tester.pump();

    // ATO 3: a animação roda passo a passo até a vitória
    for (var i = 0; i <= missao.passos.length + 1; i++) {
      await tester.pump(const Duration(milliseconds: 1250));
    }
    expect(find.text('MISSÃO CUMPRIDA!'), findsOneWidget);

    // pontos: base 30 + 15 da previsão - 5 da ajuda = 40
    expect(find.text('+40'), findsOneWidget);
    expect(repo.doc['pontos'], 40);
    expect(repo.doc['missoes'], 1);

    // o progresso da trilha avançou para a missão 2
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('missao_t0'), 1);

    // e dá pra emendar a próxima
    await tester.tap(find.text('Próxima missão →'));
    await tester.pump();
    expect(find.text('ATO 1 · PREVEJA'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('CampoTeclas devolve o foco sozinho (clique em botão não mata o teclado)',
      (tester) async {
    final outro = FocusNode();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          Focus(focusNode: outro, child: const SizedBox(width: 10, height: 10)),
          CampoTeclas(onChar: (_) {}),
        ]),
      ),
    ));
    await tester.pump();

    outro.requestFocus(); // um botão roubou o foco…
    await tester.pump();
    await tester.pump();
    expect(outro.hasFocus, isFalse); // …e o campo pegou de volta

    await tester.pumpWidget(Container());
    outro.dispose();
  });

  testWidgets('Corrida: escolhe o rival, responde certo e acelera', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const CorridaPage(semente: 9)));
    await tester.pump();

    expect(find.text('Escolha o rival:'), findsOneWidget);
    await tester.tap(find.text('Fácil'));
    await tester.pump();

    expect(find.text('VOCÊ'), findsOneWidget);
    expect(find.text('CPU'), findsOneWidget);
    await _largada(tester);

    final primeiro = BaralhoDesafios(
            rnd: Random(9), tipo: TipoDesafio.logica, banco: bancoDesafios)
        .proximo(1);
    final certa = primeiro.opcoes[primeiro.certa];
    final alvo = find.text(certa, findRichText: true).last;
    await tester.ensureVisible(alvo);
    await tester.pump();
    await tester.tap(alvo);
    await tester.pump();

    // resposta certa (na hora = turbo) acelera o carrinho
    expect(find.text('🔥 TURBO! Passo dobrado!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Esc pausa a Corrida (CPU congela) e Esc de novo retoma', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const CorridaPage(semente: 9)));
    await tester.pump();
    await tester.tap(find.text('Difícil')); // CPU anda a cada 3s, pista de 8
    await tester.pump();
    await _largada(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsOneWidget);

    // 60s pausado, frame a frame: a CPU não anda um milímetro
    // (no flutter_test um AnimationController gasta 2 frames por ciclo — o
    // 1º tick só marca o início — então 20 frames de 3s dariam 8+ passos)
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 3));
    }
    expect(find.text('A CPU VENCEU…'), findsNothing);
    expect(find.text('PAUSADO'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsNothing);

    // destravada, a CPU cruza a chegada sozinha (8 passos x 3s)
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(seconds: 3));
    }
    await tester.pump();
    expect(find.text('A CPU VENCEU…'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Caça-Bug: clicar na linha defeituosa esmaga o bug', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const CacaBugPage(semente: 7)));
    await tester.pump();

    final rodadas = BaralhoBugs(rnd: Random(7), banco: bancoBugs).sortear(8, 1);
    final bug = rodadas.first;
    expect(find.textContaining('Missão: ${bug.missao}'), findsOneWidget);

    await tester.tap(find.text(bug.linhas[bug.linhaComBug], findRichText: true).first);
    await tester.pump();
    expect(find.textContaining('Bug esmagado!'), findsOneWidget);
    expect(find.textContaining('🐞 +'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Dart Turismo: campeonato mostra as 10 pistas e só a primeira liberada', (tester) async {
    tester.view.physicalSize = const Size(1000, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const TurismoPage()));
    await tester.pump();
    await tester.pump();

    expect(find.text('🏎️ Dart Turismo'), findsOneWidget);
    expect(find.text('Autódromo da Campina'), findsOneWidget);
    expect(find.text('Grande Final Sideral'), findsOneWidget);
    expect(find.text('Correr'), findsOneWidget);
    expect(find.textContaining('vença a pista'), findsNWidgets(9));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Dart Turismo: modo SETAS — sem campo de texto, ↑ acelera e ← troca de faixa', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'turismo_modo': true, 'turismo_tutorial_setas': true});

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20)); // prefs (modo) carregadas
    expect(find.textContaining('segure ↑ pra acelerar'), findsOneWidget); // contagem 3-2-1
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 40));

    expect(find.byType(TextField), findsNothing);
    expect(find.textContaining('FAIXA LIVRE'), findsOneWidget);
    expect(find.text('▲ GÁS'), findsOneWidget);
    expect(find.textContaining('sua faixa: ⬆ MEIO'), findsOneWidget);

    // ↑ segurado: o carro anda
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(find.text('0.00 km'), findsNothing);

    // ← troca pra faixa da esquerda na hora
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.textContaining('sua faixa: ⬅ ESQUERDA'), findsOneWidget);

    // C gira a câmera (botão 🎥 do HUD acompanha)
    expect(find.textContaining('🎥 Perseguição'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.pump();
    expect(find.textContaining('🎥 Capô'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
  });

  testWidgets('Dart Turismo: fim da corrida chama a engenheira de pista (rádio da equipe)', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'turismo_modo': true, 'turismo_tutorial_setas': true});

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, TurismoPage(semente: 3, pistaInicial: 1, engenheiro: _EngenheiraFake())));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    // parado na largada até o relógio da pista 1 estourar (passos de 100 ms)
    final passos = (pistasGt[0].tempoLimite * 10).ceil() + 5;
    for (var i = 0; i < passos; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('⏱ TEMPO ESGOTADO'), findsOneWidget);
    expect(find.textContaining('RÁDIO DA EQUIPE'), findsOneWidget);
    await tester.pump(); // o Future do debrief resolve
    expect(find.text('Rádio: bela volta, piloto!'), findsOneWidget);
    // 📊 a corrida entrou nas estatísticas (mesmo sem chegar)
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('turismo_stats'), contains('"corridas":1'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('Dart Turismo: a 1ª corrida abre o tutorial; Enter larga e ele não volta', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.textContaining('COMO JOGAR'), findsOneWidget);
    expect(find.text('1 · A palavra é o volante'), findsOneWidget);
    expect(find.textContaining('digite pra acelerar'), findsNothing); // a contagem espera o tutorial
    expect(find.byType(Minimapa), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.textContaining('COMO JOGAR'), findsNothing);
    expect(find.textContaining('digite pra acelerar'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 30));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('turismo_tutorial_digitacao'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('Dart Turismo: campeonato — o seletor ⌨️/🎮 salva o modo', (tester) async {
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const TurismoPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('COMO DIRIGIR'), findsOneWidget);
    await tester.tap(find.text('🎮 Setas'));
    await tester.pump(const Duration(milliseconds: 50));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('turismo_modo'), isTrue);
    await tester.pumpWidget(Container());
  });

  testWidgets('Dart Turismo: largada, digitar a palavra do portal muda de faixa e pontua', (tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});

    SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true});
    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const TurismoPage(semente: 3, pistaInicial: 1)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20)); // prefs carregadas → largada
    expect(find.textContaining('digite pra acelerar'), findsOneWidget); // contagem 3-2-1
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 40));

    // a mesma semente reproduz a pista: a 1ª palavra e a faixa dela
    final replica = TurismoEngine(pista: pistasGt[0], rnd: Random(3));
    final portal = replica.portais.first;
    final palavra = portal.palavras.first;
    expect(find.text(palavra, findRichText: true), findsWidgets);

    var texto = '';
    for (final ch in palavra.split('')) {
      texto += ch;
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump(const Duration(milliseconds: 30));
    }
    // palavra completa: chip PALAVRAS = 1 e a placa marca ✓
    expect(find.text('1'), findsWidgets);
    expect(find.textContaining('✓', findRichText: true), findsWidgets);
    // as teclas deram gás: 2 s depois (frame a frame) o carro já andou uns metros
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    expect(find.text('0.00 km'), findsNothing);
    expect(tester.takeException(), isNull);

    // Esc pausa (o ronco do motor para) e retoma
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsNothing);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });
}

/// A engenheira de pista de mentira: responde na hora, sem rede.
class _EngenheiraFake extends EngenheiroGt {
  @override
  Future<String> debrief(TelemetriaGt t) async => 'Rádio: bela volta, piloto!';
}
