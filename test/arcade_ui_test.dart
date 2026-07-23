import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/banco_desafios.dart';
import 'package:pac_dart/features/arcade/domain/desafio.dart';
import 'package:pac_dart/features/arcade/domain/palavras_dart.dart';
import 'package:pac_dart/features/arcade/domain/tiro_engine.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/corrida_page.dart';
import 'package:pac_dart/features/arcade/domain/gerador_missoes.dart';
import 'package:pac_dart/features/arcade/presentation/futebol_page.dart';
import 'package:pac_dart/features/arcade/presentation/missao_page.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  SharedPreferences.setMockInitialValues({});

  testWidgets('hub do Arcade mostra os cinco joguinhos', (tester) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const ArcadePage()));
    await tester.pump();

    expect(find.text('🎮 Arcade Dart'), findsOneWidget);
    expect(find.text('Chuva de Código'), findsOneWidget);
    expect(find.text('Rali de Digitação'), findsOneWidget);
    expect(find.text('Corrida do Código'), findsOneWidget);
    expect(find.text('Gol de Dart'), findsOneWidget);
    expect(find.text('Caça-Bug'), findsOneWidget);
    expect(find.text('Jogar'), findsNWidgets(5));
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

    // a mesma semente reproduz o sorteio da tela
    final fila = sortearDesafios(
        tipo: TipoDesafio.sintaxe, quantidade: 5, rnd: Random(42), banco: bancoDesafios);

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

    final fila = sortearDesafios(
        tipo: TipoDesafio.logica, quantidade: 40, rnd: Random(9), banco: bancoDesafios);
    final certa = fila[0].opcoes[fila[0].certa];
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
}
