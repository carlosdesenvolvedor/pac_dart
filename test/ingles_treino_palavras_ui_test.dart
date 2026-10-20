// A sessão de treino de palavras de ponta a ponta: conhecer → escolher → pares → ouvir → digitar,
// pelo teclado e por toque, no celular (360×740) e no computador (1280×800). Errar mostra a resposta
// e o passo volta; o fim registra os cartões das PALAVRAS (sem mexer na revisão das frases) e o baú
// da unidade (ProjetoConcluido); "🎮 Jogar" devolve jogar=true; mais de 8 palavras viram lotes.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/dicionario_ingles.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/roteiro_treino.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/acoes_teimosas.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/cartao_teimosas.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/treino/passo_escolha.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/treino/resumo_treino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_cartoes_ui_test.dart' show LoaderTeste;

/// Voz de mentira: só anota o que falou.
class _VozFake extends VozIngles {
  final falas = <String>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) async => falas.add(frase);
  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

const _dic = Dicionario({
  'coffee': 'café',
  'morning': 'manhã',
  'tired': 'cansado',
  'window': 'janela',
  'ticket': 'passagem',
  'garden': 'jardim',
});

final _trilhas = [
  const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'No café', emoji: '☕', id: 't1.l1', trechos: [
      Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: ''),
      Trecho(cod: 'Good morning, I am tired.', dica: 'Bom dia, estou cansado.', out: ''),
    ]),
    Licao(nome: 'Viagem', emoji: '✈️', id: 't1.l2', trechos: [
      Trecho(cod: 'A window seat and a ticket.', dica: 'Um assento na janela e uma passagem.', out: ''),
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

final _agora = DateTime(2026, 10, 20, 9);

class _App {
  final PalavrasCubit palavras;
  final RevisaoCubit revisao;
  final CursoBloc curso;
  final _VozFake voz;
  _App(this.palavras, this.revisao, this.curso, this.voz);
}

/// O app mínimo: um botão que abre a sessão com [palavras] (e o cubit, a revisão e o curso por cima).
Future<_App> _montar(WidgetTester tester, Size tam, {List<PalavraNova>? palavras, String? chave}) async {
  SharedPreferences.setMockInitialValues({});
  DicionarioIngles.usarParaTestes(_dic);
  addTearDown(() => DicionarioIngles.usarParaTestes(null));
  tester.view.physicalSize = tam;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final cubit = PalavrasCubit(
    repo: MemoriaPalavrasRepository(),
    agora: () => _agora,
    agendador: AgendadorFsrs(fuzz: false),
    carregarDicionario: () async => _dic,
  );
  final revisao = RevisaoCubit(repo: LocalRevisaoRepository());
  final curso = CursoBloc(loader: LoaderTeste(_trilhas), progresso: LocalProgressoRepository(prefixo: 'en_'))
    ..add(const CursoIniciado());
  addTearDown(curso.close);
  addTearDown(cubit.close);
  addTearDown(revisao.close);
  await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
  await tester.runAsync(cubit.carregar);
  await tester.runAsync(() => cubit.prepararIndice(curso.state.trilhas));
  final voz = _VozFake();
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider.value(value: curso),
      BlocProvider.value(value: cubit),
      BlocProvider.value(value: revisao),
    ],
    child: MaterialApp(
      theme: Mixart.tema(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              key: const Key('abrir'),
              onPressed: () =>
                  abrirTreinoPalavras(context, palavras ?? _quatro, titulo: 'No café', chaveConclusao: chave, voz: voz),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  ));
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
  await tester.pumpAndSettle();
  return _App(cubit, revisao, curso, voz);
}

bool _tem(String chave) => find.byKey(Key(chave)).evaluate().isNotEmpty;

String _prompt(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('treino-prompt'))).data!;

/// A opção (0–3) cujo texto é [texto].
int _opcao(String texto) {
  for (var i = 0; i < 4; i++) {
    if (find.descendant(of: find.byKey(Key('treino-opcao-$i')), matching: find.text(texto)).evaluate().isNotEmpty) {
      return i;
    }
  }
  fail('opção "$texto" não está na tela');
}

/// A tecla (1–5 no inglês, A–E no português) que o ladrilho de pares com [texto] mostra no canto.
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

/// O voltar do sistema (botão/gesto do Android, swipe do iOS, voltar do navegador).
Future<void> _voltarDoSistema(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.pumpAndSettle();
}

/// Responde o passo da tela. [errar]: escolhe uma opção errada (escolha/ouvir) ou digita errado.
/// Devolve o tipo do passo ('conhecer', 'escolha', 'ouvir', 'pares', 'digitar') e a palavra.
Future<(String, String)> _responder(WidgetTester tester, Map<String, String> pt, _VozFake voz,
    {bool errar = false, bool porToque = false}) async {
  final en = {for (final e in pt.entries) e.value: e.key};
  if (_tem('passo-conhecer')) {
    final w = _prompt(tester);
    if (porToque) {
      await tester.tap(find.byKey(const Key('treino-continuar')));
      await tester.pumpAndSettle();
    } else {
      await _enter(tester);
    }
    return ('conhecer', w);
  }
  if (_tem('passo-escolha') || _tem('passo-ouvir')) {
    final ouvir = _tem('passo-ouvir');
    final palavra = ouvir ? voz.falas.last : _prompt(tester);
    final certa = _opcao(ouvir ? palavra : pt[palavra]!);
    final i = errar ? (certa + 1) % 4 : certa;
    if (porToque) {
      await tester.tap(find.byKey(Key('treino-opcao-$i')));
    } else {
      await tester.sendKeyEvent([
        LogicalKeyboardKey.digit1,
        LogicalKeyboardKey.digit2,
        LogicalKeyboardKey.digit3,
        LogicalKeyboardKey.digit4,
      ][i]);
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('treino-feedback')), findsOneWidget);
    if (porToque) {
      await tester.tap(find.byKey(const Key('treino-continuar')));
      await tester.pumpAndSettle();
    } else {
      await _enter(tester);
    }
    return (ouvir ? 'ouvir' : 'escolha', palavra);
  }
  if (_tem('passo-pares')) {
    final tab = find.byKey(const Key('passo-pares'));
    for (final e in pt.entries) {
      final ladoEn = find.descendant(of: tab, matching: find.text(e.key));
      if (ladoEn.evaluate().isEmpty) continue;
      if (porToque) {
        await tester.tap(ladoEn);
        await tester.pump();
        await tester.tap(find.descendant(of: tab, matching: find.text(e.value)));
      } else {
        // pelo teclado: o número do inglês e depois a letra do português
        await tester.sendKeyEvent(_teclaDoPar(tab, e.key));
        await tester.pump();
        await tester.sendKeyEvent(_teclaDoPar(tab, e.value));
      }
      await tester.pumpAndSettle();
    }
    expect(find.text('Todos os pares!'), findsOneWidget);
    await _enter(tester);
    return ('pares', '');
  }
  if (_tem('passo-digitar')) {
    final traducao = _prompt(tester);
    final palavra = en[traducao]!;
    await tester.enterText(find.byKey(const Key('treino-digitar')), errar ? 'xyz' : palavra);
    await tester.pump();
    if (porToque) {
      await tester.tap(find.byKey(const Key('treino-verificar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('treino-continuar')));
      await tester.pumpAndSettle();
    } else {
      await _enter(tester); // confere
      expect(find.byKey(const Key('treino-feedback')), findsOneWidget);
      await _enter(tester); // segue
    }
    return ('digitar', palavra);
  }
  fail('passo desconhecido na tela');
}

Map<String, String> _pt(List<PalavraNova> ps) => {for (final p in ps) p.en: p.pt};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  for (final (nome, tam, toque) in [
    ('celular 360×740, por toque', const Size(360, 740), true),
    ('computador 1280×800, pelo teclado', const Size(1280, 800), false),
  ]) {
    testWidgets('a sessão inteira ($nome): resumo, cartões das palavras, revisão intacta e o baú', (tester) async {
      final app = await _montar(tester, tam, chave: 'bau:tr:t1');
      final cartoesAntes = app.revisao.state.cartoes.length;
      await tester.tap(find.byKey(const Key('abrir')));
      await tester.pumpAndSettle();
      expect(find.byType(TreinoPalavrasPage), findsOneWidget);
      // a 1ª palavra fala sozinha
      expect(app.voz.falas, contains('coffee'));
      final tipos = <String>[];
      for (var i = 0; i < 60 && !_tem('treino-resumo'); i++) {
        final (tipo, _) = await _responder(tester, _pt(_quatro), app.voz, porToque: toque);
        tipos.add(tipo);
      }
      expect(find.text('Treino concluído!'), findsOneWidget);
      expect(find.text('4 de 4 palavras de primeira'), findsOneWidget);
      expect(tipos.where((t) => t == 'conhecer').length, 4);
      expect(tipos.where((t) => t == 'escolha').length, 4);
      expect(tipos.where((t) => t == 'pares').length, 1);
      expect(tipos.where((t) => t == 'ouvir').length, 2);
      expect(tipos.where((t) => t == 'digitar').length, 4);
      // o baú abre ao tocar (confete + fanfarra, uma vez só)
      await tester.tap(find.byKey(const Key('treino-bau')));
      await tester.pumpAndSettle();
      if (toque) {
        await tester.ensureVisible(find.byKey(const Key('treino-concluir')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('treino-concluir')));
      } else {
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      }
      await tester.pumpAndSettle();
      expect(find.byType(TreinoPalavrasPage), findsNothing);
      // cada palavra ganhou cartão no banco de palavras; a revisão das frases não mudou
      final banco = app.palavras.state.banco;
      for (final p in _quatro) {
        expect(banco[p.en]?.cartao, isNotNull, reason: p.en);
      }
      expect(banco.emTreino.toSet(), {'coffee', 'morning', 'tired', 'window'});
      expect(app.revisao.state.cartoes.length, cartoesAntes);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      expect(app.curso.state.projetosFeitos, contains('bau:tr:t1'));
    });
  }

  testWidgets('errar mostra "Resposta:" e o passo volta mais tarde; a palavra errada fica fraca', (tester) async {
    final app = await _montar(tester, const Size(1280, 800));
    await tester.tap(find.byKey(const Key('abrir')));
    await tester.pumpAndSettle();
    String? errada;
    final escolhas = <String>[];
    for (var i = 0; i < 70 && !_tem('treino-resumo'); i++) {
      final primeiraEscolha = errada == null && _tem('passo-escolha');
      if (primeiraEscolha) {
        errada = _prompt(tester);
        final certa = _opcao(_pt(_quatro)[errada]!);
        const teclas = [
          LogicalKeyboardKey.digit1,
          LogicalKeyboardKey.digit2,
          LogicalKeyboardKey.digit3,
          LogicalKeyboardKey.digit4,
        ];
        await tester.sendKeyEvent(teclas[(certa + 1) % 4]);
        await tester.pumpAndSettle();
        expect(find.textContaining('Resposta:'), findsOneWidget);
        expect(find.textContaining('$errada — ${_pt(_quatro)[errada]}'), findsOneWidget);
        expect(find.text('Ela volta daqui a pouco.'), findsOneWidget);
        await _enter(tester);
        escolhas.add(errada);
        continue;
      }
      final (tipo, palavra) = await _responder(tester, _pt(_quatro), app.voz);
      if (tipo == 'escolha') escolhas.add(palavra);
    }
    expect(find.text('Treino concluído!'), findsOneWidget);
    // 4 escolhas + a volta da errada
    expect(escolhas.length, 5);
    expect(escolhas.where((w) => w == errada).length, 2);
    expect(find.text('3 de 4 palavras de primeira'), findsOneWidget);
    await _enter(tester);
    final hoje = Revisao.dia(_agora);
    final banco = app.palavras.state.banco;
    expect(BancoPalavras.forca(banco[errada!], hoje), ForcaPalavra.fraca);
    final outra = _quatro.firstWhere((p) => p.en != errada).en;
    expect(BancoPalavras.forca(banco[outra], hoje), ForcaPalavra.boa);
  });

  testWidgets('digitar: Tab dá a letra (vale erro), Esc = não sei, um errinho = quase', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _VozFake();
    ResultadoTreino? r;
    final tres = [_p('coffee', 'café'), _p('morning', 'manhã'), _p('window', 'janela')];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => r = await Navigator.of(context).push<ResultadoTreino>(MaterialPageRoute(
              builder: (_) => TreinoPalavrasPage(palavras: tres, voz: voz, rnd: Random(3)))),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    final jeito = <String, String>{};
    for (var i = 0; i < 60 && !_tem('treino-resumo'); i++) {
      if (_tem('passo-digitar')) {
        final en = {for (final p in tres) p.pt: p.en}[_prompt(tester)]!;
        if (en == 'coffee' && !jeito.containsKey(en)) {
          // 1ª vez: a inicial aparece apagadinha; Tab dá a letra e marca a dica
          expect(find.descendant(of: find.byKey(const Key('passo-digitar')), matching: find.text('c')), findsOneWidget);
          await tester.showKeyboard(find.byKey(const Key('treino-digitar')));
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pump();
          expect(find.textContaining('Com dica'), findsOneWidget);
          await tester.enterText(find.byKey(const Key('treino-digitar')), 'coffee');
          await _enter(tester);
          expect(find.textContaining('Resposta: coffee'), findsOneWidget);
          jeito[en] = 'dica';
        } else if (en == 'morning' && !jeito.containsKey(en)) {
          await tester.enterText(find.byKey(const Key('treino-digitar')), 'mornin');
          await _enter(tester);
          expect(find.text('Quase! Um errinho de digitação'), findsOneWidget);
          jeito[en] = 'quase';
        } else if (en == 'window' && !jeito.containsKey(en)) {
          await tester.showKeyboard(find.byKey(const Key('treino-digitar')));
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.textContaining('Resposta: window'), findsOneWidget);
          jeito[en] = 'naoSei';
        } else {
          await tester.enterText(find.byKey(const Key('treino-digitar')), en);
          await _enter(tester);
        }
        await _enter(tester);
        continue;
      }
      await _responder(tester, _pt(tres), voz);
    }
    expect(find.text('Treino concluído!'), findsOneWidget);
    await _enter(tester);
    expect(r, isNotNull);
    expect(r!.notas['coffee'], ResultadoRevisao.errou);
    expect(r!.notas['morning'], ResultadoRevisao.hesitou);
    expect(r!.notas['window'], ResultadoRevisao.errou);
    expect(r!.jogar, isFalse);
  });

  testWidgets('mais de 8 palavras viram lotes; "🎮 Jogar com essas palavras" devolve jogar e X sai sem nada',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _VozFake();
    final dez = [
      for (final (en, pt) in [
        ('apple', 'maçã'), ('bread', 'pão'), ('cheese', 'queijo'), ('dinner', 'jantar'), ('egg', 'ovo'),
        ('fish', 'peixe'), ('grape', 'uva'), ('honey', 'mel'), ('juice', 'suco'), ('lemon', 'limão'),
      ])
        _p(en, pt),
    ];
    final resultados = <ResultadoTreino?>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => resultados.add(await Navigator.of(context).push<ResultadoTreino>(
              MaterialPageRoute(builder: (_) => TreinoPalavrasPage(palavras: dez, voz: voz, rnd: Random(5))))),
          child: const Text('abrir'),
        ),
      ),
    ));
    // X antes de terminar o 1º lote: nada a registrar
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('🎯 Treino de palavras · Lote 1 de 2'), findsOneWidget);
    await tester.tap(find.byKey(const Key('treino-fechar')));
    await tester.pumpAndSettle();
    expect(resultados, [null]);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 80 && !_tem('treino-resumo'); i++) {
      await _responder(tester, _pt(dez), voz, porToque: true);
    }
    expect(find.text('5 de 5 palavras de primeira'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('treino-proximas')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('treino-proximas')));
    await tester.pumpAndSettle();
    expect(find.text('🎯 Treino de palavras · Lote 2 de 2'), findsOneWidget);
    for (var i = 0; i < 80 && !_tem('treino-resumo'); i++) {
      await _responder(tester, _pt(dez), voz, porToque: true);
    }
    expect(find.byKey(const Key('treino-proximas')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('jogar-palavras')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('jogar-palavras')));
    await tester.pumpAndSettle();
    final r = resultados.last!;
    expect(r.jogar, isTrue);
    expect(r.notas.length, 10);
    expect(r.palavras.length, 10);
  });

  testWidgets('antes da lição ("🎯 Conhecer antes"): o resumo não oferece "🎮 Jogar" e diz "COMEÇAR A LIÇÃO →"',
      (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _VozFake();
    final duas = [_p('apple', 'maçã'), _p('bread', 'pão')];
    final resultados = <ResultadoTreino?>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => resultados.add(await Navigator.of(context).push<ResultadoTreino>(MaterialPageRoute(
              builder: (_) => TreinoPalavrasPage(palavras: duas, voz: voz, rnd: Random(5), antesDaLicao: true)))),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 60 && !_tem('treino-resumo'); i++) {
      await _responder(tester, _pt(duas), voz, porToque: true);
    }
    expect(find.byKey(const Key('treino-resumo')), findsOneWidget);
    expect(find.byKey(const Key('jogar-palavras')), findsNothing);
    expect(find.text('COMEÇAR A LIÇÃO →'), findsOneWidget);
    expect(find.text('CONTINUAR'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('treino-concluir')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('treino-concluir')));
    await tester.pumpAndSettle();
    expect(resultados.single!.jogar, isFalse);
    expect(resultados.single!.palavras.length, 2);
  });

  testWidgets('voltar do sistema: no meio do lote pergunta antes; no resumo registra tudo (cartões e baú)',
      (tester) async {
    final app = await _montar(tester, const Size(360, 740), chave: 'bau:tr:t1');
    await tester.tap(find.byKey(const Key('abrir')));
    await tester.pumpAndSettle();
    // antes de responder nada: sai direto, sem perguntar
    await _voltarDoSistema(tester);
    expect(find.byType(TreinoPalavrasPage), findsNothing);
    expect(find.byKey(const Key('treino-confirmar-saida')), findsNothing);

    await tester.tap(find.byKey(const Key('abrir')));
    await tester.pumpAndSettle();
    await _responder(tester, _pt(_quatro), app.voz, porToque: true);
    // já começou: o voltar (e o X) pergunta; "Continuar treinando" fica
    await _voltarDoSistema(tester);
    expect(find.byKey(const Key('treino-confirmar-saida')), findsOneWidget);
    expect(find.text('Sair do treino?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('treino-saida-continuar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('treino-confirmar-saida')), findsNothing);
    expect(find.byType(TreinoPalavrasPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('treino-fechar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('treino-confirmar-saida')), findsOneWidget);
    await tester.tap(find.byKey(const Key('treino-saida-continuar')));
    await tester.pumpAndSettle();
    // a barra de progresso fala com o leitor de tela
    final barra = tester.getSemantics(find.byType(TrilhaProgresso));
    expect(barra.label, 'Progresso do treino');
    expect(barra.value, endsWith('%'));
    expect(barra.value, isNot('0%'));

    for (var i = 0; i < 60 && !_tem('treino-resumo'); i++) {
      await _responder(tester, _pt(_quatro), app.voz, porToque: true);
    }
    expect(find.text('Treino concluído!'), findsOneWidget);
    // no celular não há Enter: a dica de teclado não aparece no resumo
    expect(find.text('Enter = continuar'), findsNothing);
    // o voltar no resumo = continuar: grava os cartões e o baú
    await _voltarDoSistema(tester);
    expect(find.byType(TreinoPalavrasPage), findsNothing);
    final banco = app.palavras.state.banco;
    for (final p in _quatro) {
      expect(banco[p.en]?.cartao, isNotNull, reason: p.en);
    }
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    expect(app.curso.state.projetosFeitos, contains('bau:tr:t1'));
  });

  testWidgets('sair no meio do 2º lote (confirmando) devolve o 1º lote, que já terminou', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _VozFake();
    final dez = [
      for (final (en, pt) in [
        ('apple', 'maçã'), ('bread', 'pão'), ('cheese', 'queijo'), ('dinner', 'jantar'), ('egg', 'ovo'),
        ('fish', 'peixe'), ('grape', 'uva'), ('honey', 'mel'), ('juice', 'suco'), ('lemon', 'limão'),
      ])
        _p(en, pt),
    ];
    final resultados = <ResultadoTreino?>[];
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async => resultados.add(await Navigator.of(context).push<ResultadoTreino>(
              MaterialPageRoute(builder: (_) => TreinoPalavrasPage(palavras: dez, voz: voz, rnd: Random(5))))),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 80 && !_tem('treino-resumo'); i++) {
      await _responder(tester, _pt(dez), voz);
    }
    // no computador a dica de teclado aparece no resumo
    expect(find.text('Enter = continuar'), findsOneWidget);
    await tester.tap(find.byKey(const Key('treino-proximas')));
    await tester.pumpAndSettle();
    // responde um passo do 2º lote e sai pelo voltar do sistema
    await _responder(tester, _pt(dez), voz);
    await _voltarDoSistema(tester);
    expect(find.byKey(const Key('treino-confirmar-saida')), findsOneWidget);
    await tester.tap(find.byKey(const Key('treino-saida-sair')));
    await tester.pumpAndSettle();
    expect(find.byType(TreinoPalavrasPage), findsNothing);
    final r = resultados.single!;
    expect(r.notas.length, 5);
    expect(r.jogar, isFalse);
  });

  testWidgets('resumo: tradução longa (60 letras) não estoura o chip a 360px', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const longa = 'uma tradução bem comprida escrita pelo aluno na própria pal';
    final ps = [
      PalavraNova(en: 'serendipity', pt: longa, ptCompleta: '', licaoId: 'minhas', exemplo: ''),
      PalavraNova(en: 'notwithstandingly', pt: longa, ptCompleta: longa, licaoId: 'minhas', exemplo: ''),
      _p('coffee', 'café'),
    ];
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ResumoTreino(
            resultado: ResultadoTreino(
              palavras: ps,
              notas: {for (final p in ps) p.chave: ResultadoRevisao.errou},
              passos: 10,
              pct: 50,
            ),
            onContinuar: () {},
            onDeNovo: () {},
          ),
        ),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    // a tradução curta dos botões (ptCompleta) entra no lugar da longa
    expect(find.text(' · volta logo'), findsNWidgets(3));
    expect(find.text('Enter = continuar'), findsNothing);
  });

  group('revanche das teimosas', () {
    testWidgets('resumo (360px): "Revanche concluída!", ⭐, selo DOMINADA e "📝 Virar lição"', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var licao = 0, jogar = 0;
      await tester.pumpWidget(MaterialApp(
        theme: Mixart.tema(),
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ResumoTreino(
              resultado: ResultadoTreino(
                palavras: _quatro.take(3).toList(),
                notas: const {
                  'coffee': ResultadoRevisao.acertou,
                  'morning': ResultadoRevisao.errou,
                  'tired': ResultadoRevisao.acertou,
                },
                passos: 9,
                pct: 70,
              ),
              revanche: true,
              dominadas: const ['tired'],
              acertos: const {'coffee': 1, 'morning': 0, 'tired': 0},
              onContinuar: () {},
              onDeNovo: () {},
              onJogar: () => jogar++,
              onLicao: () => licao++,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Revanche concluída!'), findsOneWidget);
      expect(find.text('2 de 3 de primeira 💪'), findsOneWidget);
      expect(find.byType(SeloDominada), findsOneWidget);
      expect(find.byKey(const Key('selo-dominada-tired')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('estrelas-coffee'))).data, '⭐☆');
      expect(tester.widget<Text>(find.byKey(const Key('estrelas-morning'))).data, '☆☆');
      expect(tester.widget<Text>(find.byKey(const Key('estrelas-tired'))).data, '⭐⭐');
      expect(find.textContaining('quase lá — volta amanhã pra fechar'), findsOneWidget);
      expect(find.text('🎮 Jogar com elas'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('treino-virar-licao')));
      await tester.tap(find.byKey(const Key('treino-virar-licao')));
      await tester.pumpAndSettle();
      expect(licao, 1);
      expect(jogar, 0);
    });

    testWidgets('de ponta a ponta: relembrar → ouvir → digitar ×2, DOMINADA no resumo e "Virar lição" cria o texto',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      DicionarioIngles.usarParaTestes(_dic);
      addTearDown(() => DicionarioIngles.usarParaTestes(null));
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final hoje = Revisao.dia(_agora);
      final cubit = PalavrasCubit(
        repo: MemoriaPalavrasRepository(BancoPalavras.vazio.com(PalavraDoBanco(
          en: 'tired',
          pt: 'cansado',
          licaoId: 't1.l1',
          cargaErro: 2,
          cargaVistas: 2,
          cargaDia: hoje - 1,
          errosTotal: 3,
          ultimoErroDia: hoje - 2,
          acertosSeguidos: 1,
          ultimoAcertoDia: hoje - 1,
          foiTeimosa: true,
        ))),
        agora: () => _agora,
        agendador: AgendadorFsrs(fuzz: false),
        carregarDicionario: () async => _dic,
      );
      final curso = CursoBloc(loader: LoaderTeste(_trilhas), progresso: LocalProgressoRepository(prefixo: 'en_'))
        ..add(const CursoIniciado());
      addTearDown(curso.close);
      addTearDown(cubit.close);
      await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
      await tester.runAsync(cubit.carregar);
      await tester.runAsync(() => cubit.prepararIndice(curso.state.trilhas));
      final voz = _VozFake();
      await tester.pumpWidget(MultiBlocProvider(
        providers: [BlocProvider.value(value: curso), BlocProvider.value(value: cubit)],
        child: MaterialApp(
          theme: Mixart.tema(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('abrir'),
                  onPressed: () => treinarTeimosas(context, ['tired', 'coffee'], voz: voz),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.byKey(const Key('abrir')));
      await tester.pumpAndSettle();
      expect(find.text('🎯 Treino de palavras · 🔥 Revanche das teimosas'), findsOneWidget);
      final pt = {'tired': 'cansado', 'coffee': 'café'};
      final tipos = <String>[];
      var guarda = 0;
      while (!_tem('treino-resumo') && guarda++ < 30) {
        if (_tem('passo-relembrar')) {
          expect(find.text('🔁 RELEMBRAR'), findsOneWidget);
          tipos.add('relembrar');
          await _enter(tester);
          continue;
        }
        if (_tem('passo-digitar')) {
          // sem a inicial apagadinha: nenhum quadradinho mostra letra antes de digitar
          expect(find.descendant(of: find.byKey(const Key('passo-digitar')), matching: find.text('c')), findsNothing);
        }
        tipos.add((await _responder(tester, pt, voz)).$1);
      }
      expect(tipos, ['relembrar', 'relembrar', 'ouvir', 'ouvir', 'digitar', 'digitar', 'digitar', 'digitar']);
      expect(find.text('Revanche concluída!'), findsOneWidget);
      expect(find.byKey(const Key('selo-dominada-tired')), findsOneWidget);
      final tired = cubit.state.banco['tired']!;
      expect(tired.dominadaEm, hoje, reason: 'registrado ao terminar a rodada');
      expect(tired.naoSugerirAte, hoje + 1);
      expect(cubit.state.banco['coffee']!.cartao, isNotNull);
      await tester.ensureVisible(find.byKey(const Key('treino-virar-licao')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('treino-virar-licao')));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('treino-resumo')), findsNothing);
      final texto = curso.state.trilhas.where((t) => t.nivel.startsWith('🔥 Teimosas')).toList();
      expect(texto, hasLength(1));
      expect(texto.single.licoes.single.trechos.map((t) => t.cod), containsAll(['Good morning, I am tired.', 'Coffee, please.']));
      expect(cubit.state.banco['tired']!.cartao!.revisoes, 1, reason: 'registrado uma vez só (não de novo no pop)');
    });
  });

  group('CartaoTeimosas', () {
    testWidgets('as chaves, "Agora não" avisa e recolhe; o 3º seguido deixa quieto uns dias', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cubit = PalavrasCubit(
        repo: MemoriaPalavrasRepository(),
        agora: () => _agora,
        carregarDicionario: () async => _dic,
      );
      addTearDown(cubit.close);
      await tester.runAsync(cubit.carregar);
      var treinar = 0, jogar = 0, licao = 0;
      Future<void> montar() async {
        await tester.pumpWidget(BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: Mixart.tema(),
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: CartaoTeimosas(
                  key: UniqueKey(),
                  palavras: const [('through', 'através', 6), ('enough', 'suficiente', 3), ('because', 'porque', 2)],
                  onTreinar: () => treinar++,
                  onJogar: () => jogar++,
                  onLicao: () => licao++,
                  onAgoraNao: cubit.adiar,
                ),
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();
      }

      await montar();
      expect(tester.takeException(), isNull);
      expect(find.text('🔥 Essas palavras te deram trabalho'), findsOneWidget);
      expect(find.text('6x'), findsOneWidget);
      expect(find.text('🎯 Treinar só elas (3)'), findsOneWidget);
      for (final k in ['cartao-teimosas', 'treinar-teimosas', 'jogar-teimosas', 'licao-teimosas', 'agora-nao']) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
      await tester.tap(find.byKey(const Key('treinar-teimosas')));
      await tester.tap(find.byKey(const Key('jogar-teimosas')));
      await tester.tap(find.byKey(const Key('licao-teimosas')));
      await tester.pump();
      expect((treinar, jogar, licao), (1, 1, 1));
      await tester.tap(find.byKey(const Key('agora-nao')));
      await tester.pumpAndSettle();
      expect(find.text('Beleza! Pergunto de novo amanhã 😉'), findsOneWidget);
      expect(find.byKey(const Key('cartao-teimosas')), findsNothing, reason: 'recolheu');
      await montar();
      await tester.tap(find.byKey(const Key('agora-nao')));
      await tester.pumpAndSettle();
      await montar();
      await tester.tap(find.byKey(const Key('agora-nao')));
      await tester.pumpAndSettle();
      expect(find.text('Ok, vou deixar quieto uns dias. Elas ficam em 📚 Minhas palavras'), findsOneWidget);
    });

    testWidgets('ChipAnotada, ListaTeimosas (botões só com callback) e a versão "de sempre"', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: Mixart.tema(),
        home: Scaffold(
          body: Column(children: [
            const ChipAnotada('through'),
            const ListaTeimosas(palavras: ['through', 'enough']),
            ListaTeimosas(palavras: const ['because'], onTreinar: () {}, onJogar: () {}),
            CartaoTeimosas(
                palavras: const [('though', 'embora', 2), ('juice', 'suco', 1)], daSessao: false, compacto: true, onTreinar: () {}),
          ]),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('1x'), findsNothing, reason: '"1x" não aparece (contradiz "teimosa")');
      expect(find.text('📝 "through" escapou de novo — anotei pro seu treino'), findsOneWidget);
      expect(find.byKey(const Key('licao-anotei')), findsOneWidget);
      expect(find.byKey(const Key('resumo-teimosas')), findsNWidgets(2));
      expect(find.textContaining('through · enough', findRichText: true), findsOneWidget);
      expect(find.text('🔥 Suas palavras teimosas'), findsOneWidget);
      expect(find.text('🔥 Você errou muitas vezes:'), findsNothing);
      expect(find.byKey(const Key('treinar-teimosas')), findsNWidgets(2), reason: 'a lista com callback + o cartão');
      expect(find.byKey(const Key('agora-nao')), findsNothing, reason: 'sem onAgoraNao');
    });
  });
}
