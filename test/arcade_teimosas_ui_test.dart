// "🔥 Palavras teimosas" no Arcade do inglês, na tela: o aviso "escapou 2x" na Chuva, o painel entre as
// fases do Rali, a oferta do fim de jogo com a "⚡ Revanche no jogo", a linha do hub — e nada disso no
// Dart, no C# ou sem o banco de palavras (arcade solto).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/palavras_csharp.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/domain/vocabulario_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/arcade/presentation/banco_arcade.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/aviso_arcade.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/painel_tropecos.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';
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

/// Três teimosas "de sempre" (erradas de vez duas vezes numa lição).
void _semearTeimosas(PalavrasCubit c) {
  c.registrarErros([
    for (final w in ['cake', 'bread', 'apple'])
      for (var i = 0; i < 2; i++) EvidenciaPalavra(chave: w, peso: 1, falha: 1, fonte: FonteErro.licao),
  ]);
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

/// Digita no campo invisível dos jogos (o texto só cresce; [buffer] guarda o que já foi).
class _Teclado {
  String buffer = '';
  Future<void> digitar(WidgetTester tester, String s) async {
    if (buffer.length + s.length > 180) {
      buffer = '';
      await tester.enterText(find.byType(TextField), '');
    }
    buffer += s;
    await tester.enterText(find.byType(TextField), buffer);
    await tester.pump();
  }
}

/// Rali: cada palavra da fila com 2 teclas erradas antes, até a fase acabar (a CPU não anda sem o
/// relógio correr). Sem [fila], lê a palavra da vez na tela (Key('rali-alvo') — no inglês o baralho da
/// fase pode trazer as teimosas do banco). Devolve as palavras digitadas.
Future<List<String>> _faseComTropecos(WidgetTester tester, [List<String>? fila]) async {
  final teclado = _Teclado();
  final feitas = <String>[];
  for (var i = 0; i < 24 && find.text('FASE 1 CONCLUÍDA!').evaluate().isEmpty; i++) {
    final w = fila != null
        ? fila[i % fila.length]
        : tester.widget<Text>(find.byKey(const Key('rali-alvo'))).textSpan!.toPlainText();
    await teclado.digitar(tester, '##$w');
    feitas.add(w);
  }
  return feitas;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true}));
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('Rali no inglês: palavras que escaparam abrem o painel entre as fases (e o foco segue com elas)',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    _semearTeimosas(cubit);
    expect(cubit.quantasTeimosas, 3);

    await tester.pumpWidget(_app(const RaliPage(semente: 3), curso: curso, palavras: cubit));
    await tester.pump();
    await tester.tap(find.text('Fácil'));
    await tester.pump();
    await _largada(tester);

    final feitas = await _faseComTropecos(tester);
    expect(find.text('FASE 1 CONCLUÍDA!'), findsOneWidget);
    expect(find.byKey(const Key('rali-teimosas')), findsOneWidget);
    expect(find.text('🔥 Essas palavras escaparam nesta partida'), findsOneWidget);
    // todas escaparam igual (2 erros cada): o painel mostra as 6 primeiras em ordem alfabética
    final treinavel = ([...feitas.where((w) => cubit.chaveDeTreino(w) != null)]..sort()).first;
    expect(find.descendant(of: find.byKey(const Key('rali-teimosas')), matching: find.text(treinavel)), findsOneWidget);
    expect(cubit.state.banco.sugestao.mostradasHoje, 1, reason: 'a oferta conta como mostrada');
    expect(tester.takeException(), isNull);

    // "⚡ Próxima fase com elas": as palavras em foco e a fase 2 começa
    await tester.ensureVisible(find.byKey(const Key('rali-proxima-com-elas')));
    await tester.tap(find.byKey(const Key('rali-proxima-com-elas')));
    await tester.pump();
    expect(find.text('FASE 1 CONCLUÍDA!'), findsNothing);
    expect(cubit.vocabularioJogo(curso.state)!.foco, isNotEmpty);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('Chuva no inglês: na 2ª escapada da mesma palavra, o aviso "escapou 2x" no topo', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    final todas = cubit.vocabularioJogo(curso.state)!.todas.toSet();

    await tester.pumpWidget(_app(const ChuvaPage(semente: 5), curso: curso, palavras: cubit));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);

    final teclado = _Teclado();
    String? alvo;
    var escapadas = 0;
    for (var i = 0; i < 3000 && escapadas < 2; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      // as palavras na tela, da mais baixa para a mais alta (a mira trava na mais baixa da letra)
      final naTela = [
        for (final e in find.byWidgetPredicate((w) => w is RichText && todas.contains(w.text.toPlainText())).evaluate())
          ((e.widget as RichText).text.toPlainText(), tester.getTopLeft(find.byWidget(e.widget)).dy),
      ]..sort((a, b) => b.$2.compareTo(a.$2));
      for (final (w, _) in naTela) {
        alvo ??= w;
        if (w == alvo && escapadas < 2) {
          // 3 teclas erradas na palavra travada: escapou de vez (falha 1)
          await teclado.digitar(tester, '${w[0]}###${w.substring(1)}');
          escapadas++;
          if (escapadas == 2) break;
        } else {
          await teclado.digitar(tester, w);
        }
      }
    }
    expect(escapadas, 2, reason: 'a palavra "$alvo" voltou a cair');
    expect(find.text('💡 "$alvo" escapou 2x — anotei pra revanche'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // a pausa lista o que foi anotado
    await tester.tap(find.byTooltip('Pausar (Esc)'));
    await tester.pump();
    expect(find.byKey(const Key('pausa-anotadas')), findsOneWidget);
    expect(find.textContaining('📝 Anotadas nesta partida: $alvo ×2'), findsOneWidget);
    await _fechar(tester, curso, cubit);
    final chave = cubit.chaveDeTreino(alvo!);
    if (chave != null) {
      expect(cubit.state.banco[chave]?.cargaErro ?? 0, greaterThan(0), reason: 'a falha foi para o banco ao sair');
    }
  });

  testWidgets('Chuva no inglês: o fim de jogo oferece as teimosas e "⚡ Revanche no jogo"', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);
    _semearTeimosas(cubit);

    await tester.pumpWidget(_app(const ChuvaPage(semente: 5), curso: curso, palavras: cubit));
    await tester.pump(const Duration(milliseconds: 2000));
    await _largada(tester);
    // ninguém digita: três palavras chegam ao chão
    for (var i = 0; i < 1200 && find.byType(FimDeJogo).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FimDeJogo), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.byKey(const Key('cartao-teimosas')), findsOneWidget);
    expect(find.byKey(const Key('treinar-teimosas')), findsOneWidget);
    expect(find.byKey(const Key('fim-revanche')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.byKey(const Key('fim-revanche')));
    await tester.tap(find.byKey(const Key('fim-revanche')));
    await tester.pump();
    expect(find.byType(FimDeJogo), findsNothing);
    expect(find.byType(ContagemRegressiva), findsOneWidget, reason: 'outra partida');
    expect(cubit.vocabularioJogo(curso.state)!.foco, isNotEmpty, reason: 'as teimosas em foco');
    await _fechar(tester, curso, cubit);
  });

  testWidgets('hub do inglês: a linha das teimosas abre a revanche', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (curso, cubit) = await _providers(tester);

    await tester.pumpWidget(_app(const ArcadePage(), curso: curso, palavras: cubit));
    await tester.pump();
    expect(find.byKey(const Key('arcade-teimosas')), findsNothing, reason: 'sem teimosas, sem linha');
    _semearTeimosas(cubit);
    await tester.pump(Duration.zero);
    expect(find.byKey(const Key('arcade-teimosas')), findsOneWidget);
    expect(find.textContaining('3 teimosas · a mais teimosa: '), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('arcade-treinar-teimosas')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(TreinoPalavrasPage), findsOneWidget);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('Dart, C# e o inglês sem o banco: Rali sem painel, pausa sem anotadas', (tester) async {
    tester.view.physicalSize = const Size(900, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final l in [Linguagem.dart, Linguagem.csharp, Linguagem.ingles]) {
      Linguagem.atual = l;
      await tester.pumpWidget(_app(const RaliPage(semente: 3)));
      await tester.pump();
      await tester.tap(find.text('Fácil'));
      await tester.pump();
      await _largada(tester);
      await tester.tap(find.byTooltip('Pausar (Esc)'));
      await tester.pump();
      expect(find.byType(PausaOverlay), findsOneWidget);
      expect(find.byKey(const Key('pausa-anotadas')), findsNothing, reason: '$l');
      await tester.tap(find.text('Continuar'));
      await tester.pump();

      final fila = l == Linguagem.ingles
          ? BancoArcade.baralhoDoVocabulario(
              VocabularioJogo.deListas(vocabularioDe(Linguagem.ingles), traducoes: traducoesEn), Random(3))
          : baralhoRaliDe(Random(3), linguagem: l);
      await _faseComTropecos(tester, fila);
      expect(find.text('FASE 1 CONCLUÍDA!'), findsOneWidget, reason: '$l');
      expect(find.byKey(const Key('rali-teimosas')), findsNothing, reason: '$l');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(Container());
    }
  });

  testWidgets('paleta clara: anotadas e aviso legíveis no fundo escuro; painel no singular',
      (tester) async {
    final antes = Mixart.atual;
    Mixart.atual = Paleta.flutterClaro;
    addTearDown(() => Mixart.atual = antes);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Color corDe(Finder f) => tester.widget<Text>(f).style!.color!;
    double luz(Color c) => c.computeLuminance();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          ListView(children: [
            PainelTropecos(palavras: const [('through', 'através', 2)], onTreinar: () {}, onFocar: () {}),
            const LinhaAnotadas('📝 Anotadas nesta partida: through ×2'),
          ]),
          const AvisoArcade('💡 "neighborhood" escapou 2x — anotei pra revanche', direita: 136),
        ]),
      ),
    ));
    await tester.pump();
    expect(find.text('🔥 Essa palavra escapou nesta partida'), findsOneWidget);
    expect(find.text('⚡ Próxima fase com ela'), findsOneWidget);
    expect(luz(corDe(find.text('📝 Anotadas nesta partida: through ×2'))), greaterThan(.6),
        reason: 'a pausa é sempre quase preta: texto claro também na paleta clara');
    final aviso = find.text('💡 "neighborhood" escapou 2x — anotei pra revanche');
    expect(luz(corDe(aviso)), greaterThan(.5), reason: 'o aviso tem fundo escuro fixo');
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PainelTropecos(
            palavras: const [('through', 'através', 2), ('enough', null, 1)], onTreinar: () {}, onFocar: () {}),
      ),
    ));
    expect(find.text('🔥 Essas palavras escaparam nesta partida'), findsOneWidget);
    expect(find.text('⚡ Próxima fase com elas'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(seconds: 4));
  });
}
