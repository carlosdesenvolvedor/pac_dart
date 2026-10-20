// Arcade no inglês, na tela: as palavras das lições caem/correm com a tradução embaixo (Chuva, Rali,
// Turismo), o hub ganha o cartão "Minhas palavras", nada vaza no celular — e o Dart segue igual.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/tiro_engine.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/arcade/presentation/banco_arcade.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
import 'package:pac_dart/features/arcade/presentation/turismo_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/legenda_traducao.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CursoFake extends CursoBloc {
  _CursoFake(CursoState s) : super(loader: CurriculoLoader(), progresso: LocalProgressoRepository()) {
    emit(s);
  }
}

const _dic = Dicionario({
  'want': 'querer',
  'tea': 'chá',
  'milk': 'leite',
  'cake': 'bolo',
  'bread': 'pão',
  'apple': 'maçã',
  'juice': 'suco',
  'rice': 'arroz',
  'soup': 'sopa',
  'fish': 'peixe',
  'egg': 'ovo',
  'salt': 'sal',
  'sugar': 'açúcar',
  'lunch': 'almoço',
  'cheese': 'queijo',
});

final _trilhas = [
  const Trilha(nivel: 'T1', emoji: '🍽️', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Comida', emoji: '🍞', id: 't1.l1', trechos: [
      Trecho(cod: 'I want tea, milk, cake and bread.', dica: 'Quero chá, leite, bolo e pão.', out: ''),
      Trecho(cod: 'Apple juice, rice, soup and fish.', dica: 'Suco de maçã, arroz, sopa e peixe.', out: ''),
      Trecho(cod: 'Egg, salt, sugar, cheese, lunch.', dica: 'Ovo, sal, açúcar, queijo, almoço.', out: ''),
    ]),
  ]),
];

final _lesson = {'tea', 'milk', 'cake', 'bread', 'apple', 'juice', 'rice', 'soup', 'fish', 'egg', 'salt', 'sugar', 'lunch', 'want'};

/// O curso de inglês (com a lição concluída) e o cubit com o índice pronto.
Future<(CursoBloc, PalavrasCubit)> _providers(WidgetTester tester) async {
  final curso = _CursoFake(CursoState(
    status: CursoStatus.pronto,
    trilhas: _trilhas,
    linguagem: Linguagem.ingles,
    concluidas: const {'t1.l1'},
  ));
  final cubit = PalavrasCubit(repo: MemoriaPalavrasRepository(), carregarDicionario: () async => _dic);
  await tester.runAsync(() async {
    await cubit.carregar();
    await cubit.prepararIndice(_trilhas);
  });
  return (curso, cubit);
}

Widget _app(Widget home, {CursoBloc? curso, PalavrasCubit? palavras}) {
  Widget w = MaterialApp(theme: Mixart.tema(), home: home);
  if (palavras != null) w = BlocProvider.value(value: palavras, child: w);
  if (curso != null) w = BlocProvider.value(value: curso, child: w);
  return w;
}

Future<void> _fechar(WidgetTester tester, CursoBloc curso, PalavrasCubit cubit) async {
  await tester.pumpWidget(Container());
  await tester.runAsync(() async {
    await cubit.gravacoes;
    await cubit.close();
    await curso.close();
  });
}

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

Finder _rich(String texto) => find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText() == texto);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true}));
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('Chuva no inglês: a palavra da lição cai com a tradução embaixo; chão = erro no banco', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    final v = cubit.vocabularioJogo(curso.state)!;
    expect(v.curtas.toSet().difference(_lesson), isEmpty, reason: 'nível 1 só com palavras da lição');

    await tester.pumpWidget(_app(const ChuvaPage(semente: 5), curso: curso, palavras: cubit));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60));

    final replica = TiroEngine(rnd: Random(5), curtas: v.curtas, medias: v.medias, longas: v.longas)..tick(0.06);
    final caindo = replica.ativas.first.texto;
    expect(_lesson, contains(caindo));
    expect(_rich(caindo), findsOneWidget);
    expect(find.text(v.traducao(caindo)!), findsOneWidget);
    // a tradução fica EMBAIXO do chip da palavra
    expect(tester.getTopLeft(find.text(v.traducao(caindo)!)).dy, greaterThan(tester.getTopLeft(_rich(caindo)).dy));
    expect(tester.takeException(), isNull);

    // a palavra despenca até o chão sem ninguém digitar: vira erro dela no banco (ao sair)
    // velocidade 0,055/s: ~18 s até o chão
    for (var i = 0; i < 220; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await _fechar(tester, curso, cubit);
    expect(cubit.state.banco[caindo]?.errosJogo ?? 0, greaterThanOrEqualTo(1));
  });

  testWidgets('Rali no inglês: a tradução embaixo da PALAVRA 1 e dos "a seguir"; errar conta no banco',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    final v = cubit.vocabularioJogo(curso.state)!;

    await tester.pumpWidget(_app(const RaliPage(semente: 3), curso: curso, palavras: cubit));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);

    final fila = BancoArcade.baralhoDoVocabulario(v, Random(3));
    final palavra = fila[0];
    expect(find.text('PALAVRA 1'), findsOneWidget);
    expect(_rich(palavra), findsOneWidget);
    expect(find.text(v.traducao(palavra)!), findsWidgets);
    expect(tester.getTopLeft(find.text(v.traducao(palavra)!).first).dy, greaterThan(tester.getTopLeft(_rich(palavra)).dy));
    expect(find.text(v.traducao(fila[1])!), findsWidgets, reason: 'a seguir com tradução');

    // uma tecla errada e depois a palavra certa
    await tester.enterText(find.byType(TextField), '#');
    await tester.pump();
    var texto = '#';
    for (final ch in palavra.split('')) {
      texto += ch;
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump();
    }
    expect(find.text('PALAVRA 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
    final p = cubit.state.banco[palavra]!;
    expect(p.errosJogo, 1);
    expect(p.vistasJogo, 1);
  });

  testWidgets('Rali modo memória: a tradução grande, a palavra escondida e a revisão vai para o FSRS',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    final v = cubit.vocabularioJogo(curso.state)!;

    await tester.pumpWidget(_app(const RaliPage(semente: 3), curso: curso, palavras: cubit));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rali-memoria')));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);

    final palavra = BancoArcade.baralhoDoVocabulario(v, Random(3)).firstWhere((w) => v.traducao(w) != null);
    expect(find.text('PALAVRA 1 · 🧠 DE MEMÓRIA'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('rali-memoria-pt'))).data, v.traducao(palavra));
    expect(_rich(palavra), findsNothing, reason: 'a palavra fica escondida');
    expect(_rich('${palavra[0]}${'_' * (palavra.length - 1)}'), findsOneWidget, reason: 'só a 1ª letra');

    var texto = '';
    for (final ch in palavra.split('')) {
      texto += ch;
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump();
    }
    expect(find.text('PALAVRA 2 · 🧠 DE MEMÓRIA'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
    expect(cubit.state.banco[palavra]?.cartao, isNotNull, reason: 'lembrou sem erro: virou revisão (FSRS)');
    expect(cubit.state.banco[palavra]?.vistasJogo ?? 0, 0, reason: 'no modo memória não conta como exposição');
  });

  testWidgets('Rali modo memória travado: 3 erros na letra a revelam, Tab revela a próxima; a revisão vira "errou"',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    final v = cubit.vocabularioJogo(curso.state)!;

    await tester.pumpWidget(_app(const RaliPage(semente: 3), curso: curso, palavras: cubit));
    await tester.pump();
    await tester.tap(find.byKey(const Key('rali-memoria')));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    expect(find.textContaining('Tab mostra a letra'), findsOneWidget, reason: 'o rodapé ensina a saída');

    final fila = [for (final w in BancoArcade.baralhoDoVocabulario(v, Random(3))) if (v.traducao(w) != null) w];
    final palavra = fila[0];
    expect(palavra.length, greaterThanOrEqualTo(3));
    // 1ª letra certa, depois 3 erros na 2ª: ela aparece
    var texto = palavra[0];
    await tester.enterText(find.byType(TextField), texto);
    await tester.pump();
    for (var i = 0; i < 2; i++) {
      texto += '#';
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump();
    }
    expect(_rich('${palavra[0]}${'_' * (palavra.length - 1)}'), findsOneWidget, reason: '2 erros: ainda escondida');
    texto += '#';
    await tester.enterText(find.byType(TextField), texto);
    await tester.pump();
    expect(_rich('${palavra.substring(0, 2)}${'_' * (palavra.length - 2)}'), findsOneWidget,
        reason: '3 erros na mesma letra: ela aparece');
    for (final ch in palavra.substring(1).split('')) {
      texto += ch;
      await tester.enterText(find.byType(TextField), texto);
      await tester.pump();
    }
    expect(find.text('PALAVRA 2 · 🧠 DE MEMÓRIA'), findsOneWidget);

    // Tab: revela a próxima letra escondida (a 1ª já aparece) e conta erro
    final segunda = fila[1 % fila.length];
    final erros = find.descendant(of: find.byType(ChipPlacar), matching: find.text('4'));
    expect(erros, findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_rich('${segunda.substring(0, 2)}${'_' * (segunda.length - 2)}'), findsOneWidget, reason: 'Tab revelou');
    expect(find.text('4'), findsWidgets, reason: 'Tab conta como erro (3 + 1)');
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);

    final hoje = cubit.state.hoje;
    final c = cubit.state.banco[palavra]!.cartao!;
    final errou = agendar(PalavraDoBanco(en: palavra, pt: 'x'), ResultadoRevisao.errou, hoje).cartao!;
    final hesitou = agendar(PalavraDoBanco(en: palavra, pt: 'x'), ResultadoRevisao.hesitou, hoje).cartao!;
    expect(c.estabilidade, closeTo(errou.estabilidade, 1e-9), reason: 'com letra revelada a revisão é "errou"');
    expect(c.estabilidade, isNot(closeTo(hesitou.estabilidade, 1e-9)));
  });

  testWidgets('hub: o "Treinar" sem nada vencendo nunca treina palavra de função nem enchimento', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    // aluno novo: nenhuma lição concluída, banco vazio → o vocabulário é só enchimento (the, and, you…)
    final novo = _CursoFake(CursoState(
      status: CursoStatus.pronto,
      trilhas: _trilhas,
      linguagem: Linguagem.ingles,
    ));
    final cubitNovo = PalavrasCubit(repo: MemoriaPalavrasRepository(), carregarDicionario: () async => _dic);
    await tester.runAsync(() async {
      await cubitNovo.carregar();
      await cubitNovo.prepararIndice(_trilhas);
    });
    final todasNovo = cubitNovo.vocabularioJogo(novo.state)!.todas;
    expect(todasNovo.where((w) => stopwordsEn.contains(w.toLowerCase())), isNotEmpty,
        reason: 'o enchimento dos jogos tem palavras de função (${todasNovo.take(14).join(', ')})');
    expect(treinoSemDevidas(cubitNovo, novo.state), isEmpty);
    await tester.runAsync(() async {
      await cubitNovo.close();
      await novo.close();
    });

    // com a lição concluída: só as palavras dela (sem stopwords), até 8
    final (curso, cubit) = await _providers(tester);
    final sessao = treinoSemDevidas(cubit, curso.state);
    expect(sessao, isNotEmpty);
    expect(sessao.length, lessThanOrEqualTo(8));
    for (final p in sessao) {
      expect(stopwordsEn, isNot(contains(p.en.toLowerCase())), reason: p.en);
      expect(_lesson, contains(p.en.toLowerCase()), reason: p.en);
    }
    await _fechar(tester, curso, cubit);
  });

  testWidgets('hub: "+ 1 palavra sua" quando a pessoa adicionou uma palavra', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    expect(cubit.adicionar('kettle', 'chaleira'), isNull);
    await tester.pumpWidget(_app(const ArcadePage(), curso: curso, palavras: cubit));
    await tester.pump();
    expect(find.textContaining('+ 1 palavra sua'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('Turismo no inglês: a palavra do portal (das lições) com a tradução no HUD', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    final v = cubit.vocabularioJogo(curso.state)!;

    await tester.pumpWidget(_app(const TurismoPage(semente: 3, pistaInicial: 1), curso: curso, palavras: cubit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 40));

    final p = pistasGt[0];
    final replica = TurismoEngine(pista: p, rnd: Random(3), vocabulario: p.vocabularioCom(v), traducoes: v.traducoes);
    final palavra = replica.portais.first.palavras.first;
    expect(_lesson, contains(palavra));
    expect(find.text(palavra, findRichText: true), findsWidgets);
    expect(find.text(v.traducao(palavra)!), findsOneWidget);
    expect(find.textContaining('🏆 CAMPEÃO'), findsNothing);
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('Turismo no inglês, celular 360: duas palavras compridas + traduções não vazam', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    // sem o curso: a reserva fixa (com as longas: responsibility, communication…)
    for (final pista in [7, 10]) {
      await tester.pumpWidget(_app(TurismoPage(semente: 1, pistaInicial: pista)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await _largada(tester);
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 40));
      }
      expect(find.byType(LegendaTraducao), findsWidgets);
      expect(tester.takeException(), isNull, reason: 'pista $pista');
      await tester.pumpWidget(Container());
    }
  });

  testWidgets('sem o curso (arcade solto) os jogos do inglês abrem com a reserva traduzida', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60));
    final replica = TiroEngine(rnd: Random(5), curtas: palavrasCurtasEn, medias: palavrasMediasEn, longas: palavrasLongasEn)
      ..tick(0.06);
    final caindo = replica.ativas.first.texto;
    expect(_rich(caindo), findsOneWidget);
    expect(find.text(traducoesEn[caindo.toLowerCase()]!), findsOneWidget);
    await tester.pumpWidget(Container());

    await tester.pumpWidget(_app(const RaliPage(semente: 3)));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);
    expect(find.text('PALAVRA 1'), findsOneWidget);
    expect(find.byType(LegendaTraducao), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('hub do inglês: cartão "Minhas palavras" no lugar da Lógica Animada e 3 jogos', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    await tester.pumpWidget(_app(const ArcadePage(), curso: curso, palavras: cubit));
    await tester.pump();

    expect(find.byKey(const Key('arcade-minhas-palavras')), findsOneWidget);
    expect(find.text('Jogar'), findsNWidgets(3));
    expect(find.text('Lógica Animada'), findsNothing);
    expect(find.textContaining('das suas lições'), findsWidgets);
    expect(find.text('🎯 Treinar'), findsOneWidget, reason: 'nada vence hoje: treina as do momento');
    expect(find.text('Gerenciar'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);

    // sem o cubit (arcade solto) o cartão não aparece
    await tester.pumpWidget(_app(const ArcadePage()));
    await tester.pump();
    expect(find.byKey(const Key('arcade-minhas-palavras')), findsNothing);
    expect(find.text('Jogar'), findsNWidgets(3));
    await tester.pumpWidget(Container());
  });

  testWidgets('Dart: Chuva sem legenda e hub sem o cartão das palavras', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    expect(Linguagem.atual, Linguagem.dart);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    await tester.pump(const Duration(milliseconds: 60));
    final caindo = (TiroEngine(rnd: Random(5))..tick(0.06)).ativas.first.texto;
    expect(_rich(caindo), findsOneWidget);
    expect(find.byType(LegendaTraducao), findsNothing);
    await tester.pumpWidget(Container());

    expect(VocabularioJogo.deListas(vocabularioDe()).traducoes, isEmpty);
    await tester.pumpWidget(_app(const ArcadePage()));
    await tester.pump();
    expect(find.byKey(const Key('arcade-minhas-palavras')), findsNothing);
    expect(find.text('Lógica Animada'), findsOneWidget);
    await tester.pumpWidget(Container());
  });
}
