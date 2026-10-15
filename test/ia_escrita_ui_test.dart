import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/mapa_page.dart';
import 'package:pac_dart/features/ia/presentation/escrita_page.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/textos_repository.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria;
import 'ia_escrita_cubit_test.dart' show TutorEscritaFalso, texto;
import 'ingles_baralhos_test.dart' show RepoMemoria;
import 'ingles_cartoes_ui_test.dart' show LoaderTeste;

final _trilha = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: const [
    Licao(nome: 'Olá!', emoji: '🙋', trechos: [Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: '')]),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late TutorEscritaFalso tutor;
  late CursoBloc curso;

  Future<IaCubit> criar(WidgetTester tester) async {
    tutor = TutorEscritaFalso();
    final ia = IaCubit(service: tutor, cotaRepo: CotaMemoria(), cache: CacheMemoria(), agora: () => DateTime(2026, 10, 13, 10));
    await tester.runAsync(ia.carregar);
    addTearDown(() => tester.runAsync(ia.close));
    return ia;
  }

  Future<void> anda(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  Future<void> montar(WidgetTester tester, {IaCubit? ia, Size tamanho = const Size(900, 1200)}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    curso = CursoBloc(loader: LoaderTeste([_trilha]), progresso: LocalProgressoRepository(prefixo: 'en_'), textos: LocalTextosRepository('u1'))..add(const CursoIniciado());
    final revisao = RevisaoCubit(repo: RepoMemoria());
    addTearDown(() => tester.runAsync(curso.close));
    addTearDown(() => tester.runAsync(revisao.close));
    await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto).timeout(const Duration(seconds: 5)));
    Widget app = MultiBlocProvider(
      providers: [BlocProvider.value(value: curso), BlocProvider.value(value: revisao)],
      child: MaterialApp(theme: Mixart.tema(), home: const EscritaPage()),
    );
    if (ia != null) app = BlocProvider.value(value: ia, child: app);
    await tester.pumpWidget(app);
    await tester.pump();
  }

  Future<void> escreve(WidgetTester tester, String t) async {
    await tester.enterText(find.byKey(const Key('campo-escrita')), t);
    await tester.pump();
  }

  Future<void> corrige(WidgetTester tester, String t) async {
    await escreve(tester, t);
    await tester.ensureVisible(find.byKey(const Key('corrigir-escrita')));
    await tester.tap(find.byKey(const Key('corrigir-escrita')));
    await anda(tester);
  }

  List<String> cartoesSalvos() {
    final meus = curso.state.trilhas.where((t) => t.textoId == idCartoesAvulsos);
    return [for (final t in meus) for (final l in t.licoes) for (final x in l.trechos) x.cod];
  }

  group('o card no Mapa', () {
    Future<void> mapa(WidgetTester tester, {IaCubit? ia}) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      curso = CursoBloc(loader: LoaderTeste([_trilha]), progresso: LocalProgressoRepository(prefixo: 'en_'), textos: LocalTextosRepository('u1'))
        ..add(const CursoIniciado());
      final revisao = RevisaoCubit(repo: RepoMemoria());
      addTearDown(() => tester.runAsync(curso.close));
      addTearDown(() => tester.runAsync(revisao.close));
      await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto).timeout(const Duration(seconds: 5)));
      Widget app = MultiBlocProvider(
        providers: [BlocProvider.value(value: curso), BlocProvider.value(value: revisao)],
        child: MaterialApp(theme: Mixart.tema(), home: const MapaPage()),
      );
      if (ia != null) app = BlocProvider.value(value: ia, child: app);
      await tester.pumpWidget(app);
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets('com a IA: o card "Escrever e ser corrigido" aparece e abre a tela', (tester) async {
      final ia = await criar(tester);
      await mapa(tester, ia: ia);
      expect(find.byKey(const Key('escrever')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('escrever')));
      await tester.tap(find.byKey(const Key('escrever')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('campo-escrita')), findsOneWidget);
    });

    testWidgets('sem a IA na árvore: o card some', (tester) async {
      await mapa(tester);
      expect(find.byKey(const Key('baralhos')), findsWidgets, reason: 'o Mapa em si abriu');
      expect(find.byKey(const Key('escrever')), findsNothing);
    });
  });

  testWidgets('abre com a explicação, o saldo do dia, os temas e sem nenhum resultado; sem gastar nada', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    expect(find.text('Escrever'), findsOneWidget);
    expect(find.textContaining('Não tem nota'), findsOneWidget);
    expect(find.text('Restam 30 usos hoje'), findsOneWidget);
    expect(find.byType(ActionChip), findsNWidgets(6));
    expect(find.byKey(const Key('resultado-escrita')), findsNothing);
    expect(tutor.chamadas, 0);
  });

  testWidgets('sem IaCubit na árvore não há tela de escrita', (tester) async {
    await montar(tester);
    expect(find.byKey(const Key('campo-escrita')), findsNothing);
  });

  testWidgets('tocar num tema preenche o campo (e o 2º tema vai numa nova linha)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    await tester.tap(find.byKey(const Key('tema-escrita-0')));
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(const Key('campo-escrita'))).controller!.text, 'Today I ');
    await tester.tap(find.byKey(const Key('tema-escrita-5')));
    await tester.pump();
    expect(tester.widget<TextField>(find.byKey(const Key('campo-escrita'))).controller!.text, 'Today I\nYesterday I ');
  });

  testWidgets('o contador de frases e o aviso de corte acompanham o que se escreve', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    String contador() => tester.widget<Text>(find.byKey(const Key('escrita-contador'))).data!;
    expect(contador(), contains('Até 3 frases'));
    await escreve(tester, 'Hi. I like tea.');
    expect(contador(), '2 de 3 frases');
    await escreve(tester, 'One. Two. Three. Four.');
    expect(contador(), contains('só as 3 primeiras'));
    await escreve(tester, '${'a' * 400}.');
    expect(contador(), contains('cortada em 300'));
  });

  testWidgets('texto vazio: mensagem e a IA não é chamada', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    await tester.tap(find.byKey(const Key('corrigir-escrita')));
    await anda(tester);
    expect(find.byKey(const Key('escrita-sem-texto')), findsOneWidget);
    expect(tutor.chamadas, 0);
    expect(ia.state.restantes, 30);
  });

  testWidgets('corrigir: texto corrigido, elogio e um bloco por erro (riscada, certa, tradução, porquê); gastou 1; sem nota', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    await corrige(tester, texto);
    expect(find.byKey(const Key('resultado-escrita')), findsOneWidget);
    expect(find.text('Yesterday I went to the market. I bought some cheese.'), findsOneWidget);
    expect(find.textContaining('Boa ordem!'), findsOneWidget);
    expect(find.byKey(const Key('erro-escrita-0')), findsOneWidget);
    expect(find.byKey(const Key('erro-escrita-1')), findsOneWidget);
    expect(find.text('Yesterday I go to the market.'), findsOneWidget); // a riscada (a do campo está no TextField)
    expect(find.text('Ontem eu fui ao mercado.'), findsOneWidget);
    expect(find.text('Restam 29 usos hoje'), findsOneWidget);
    expect(find.textContaining('nota:'), findsNothing);
    expect(find.textContaining('pontos'), findsNothing);
    expect(find.byKey(const Key('salvar-todos')), findsOneWidget);
  });

  testWidgets('salvar um erro: vira cartão em "Meus cartões"; salvar de novo não duplica', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    await corrige(tester, texto);
    expect(cartoesSalvos(), isEmpty);
    await tester.ensureVisible(find.byKey(const Key('salvar-erro-0')));
    await tester.tap(find.byKey(const Key('salvar-erro-0')));
    await anda(tester);
    await anda(tester);
    expect(cartoesSalvos(), ['Yesterday I went to the market.']);
    expect(find.text('✓ Salvo'), findsOneWidget);
    // o botão do salvo está desligado; salvar o mesmo cartão de novo pelo bloc também não duplica
    expect(tester.widget<OutlinedButton>(find.byKey(const Key('salvar-erro-0'))).onPressed, isNull);
    curso.add(const CartaoAdicionado(CartaoEscrito('Yesterday I went to the market.', 'Ontem eu fui ao mercado.')));
    await anda(tester);
    expect(cartoesSalvos(), ['Yesterday I went to the market.']);
    // "Salvar todos" agora só tem 1 a salvar
    expect(find.text('Salvar todos (1)'), findsOneWidget);
  });

  testWidgets('"Salvar todos": os 2 viram cartão, e o botão passa a "Todos salvos"', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    await corrige(tester, texto);
    expect(find.text('Salvar todos (2)'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('salvar-todos')));
    await tester.tap(find.byKey(const Key('salvar-todos')));
    for (var i = 0; i < 4; i++) {
      await anda(tester);
    }
    expect(cartoesSalvos(), ['Yesterday I went to the market.', 'I bought some cheese.']);
    expect(find.text('✓ Todos salvos'), findsOneWidget);
    expect(find.text('✓ Salvo'), findsNWidgets(2));
  });

  testWidgets('erro cujo cartão foi recusado aparece, mas sem botão de salvar', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    tutor.resposta = '{"corrigido":"x","erros":[{"sua":"Yesterday I go to the market.","melhor":"Yesterday I went to the market.","pt":"","porque":"Passado."}]}';
    await corrige(tester, texto);
    expect(find.byKey(const Key('erro-escrita-0')), findsOneWidget);
    expect(find.byKey(const Key('salvar-erro-0')), findsNothing);
    expect(find.byKey(const Key('salvar-todos')), findsNothing);
  });

  testWidgets('sem erros: "Sem erros desta vez!" e nada para salvar', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    tutor.resposta = '{"em_ingles":true,"corrigido":"I like tea.","elogio":"Perfeito!","erros":[]}';
    await corrige(tester, 'I like tea.');
    expect(find.byKey(const Key('escrita-sem-erros')), findsOneWidget);
    expect(find.byKey(const Key('salvar-todos')), findsNothing);
    expect(find.textContaining('Salvar como cartão'), findsNothing);
  });

  testWidgets('JSON ruim: mostra o texto como veio e nenhum botão de cartão', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    tutor.resposta = 'Desculpe, não consegui.';
    await corrige(tester, texto);
    expect(find.byKey(const Key('escrita-crua')), findsOneWidget);
    expect(find.text('Desculpe, não consegui.'), findsOneWidget);
    expect(find.byKey(const Key('salvar-todos')), findsNothing);
    expect(find.textContaining('Salvar como cartão'), findsNothing);
  });

  testWidgets('texto que não está em inglês: aviso amigável', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    tutor.resposta = '{"em_ingles":false}';
    await corrige(tester, 'Eu fui ao mercado ontem.');
    expect(find.byKey(const Key('escrita-nao-ingles')), findsOneWidget);
    expect(find.textContaining('Salvar'), findsNothing);
  });

  testWidgets('falha de rede: aviso, o texto continua no campo e não gastou', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    tutor.erro = Exception('sem rede');
    await corrige(tester, texto);
    expect(find.byKey(const Key('escrita-falhou')), findsOneWidget);
    expect(tester.widget<TextField>(find.byKey(const Key('campo-escrita'))).controller!.text, texto);
    expect(find.text('Restam 30 usos hoje'), findsOneWidget);
    tutor.erro = null;
    await tester.tap(find.byKey(const Key('corrigir-escrita')));
    await anda(tester);
    expect(find.byKey(const Key('escrita-falhou')), findsNothing);
    expect(find.byKey(const Key('resultado-escrita')), findsOneWidget);
  });

  testWidgets('sem cota: mensagem gentil, o texto fica e nada trava', (tester) async {
    tutor = TutorEscritaFalso();
    final ia = IaCubit(service: tutor, cotaRepo: CotaMemoria(), cache: CacheMemoria(), limite: 0, agora: () => DateTime(2026, 10, 13, 10));
    await tester.runAsync(ia.carregar);
    addTearDown(() => tester.runAsync(ia.close));
    await montar(tester, ia: ia);
    await corrige(tester, texto);
    expect(find.byKey(const Key('escrita-sem-cota')), findsOneWidget);
    expect(find.textContaining('descansou'), findsOneWidget);
    expect(tutor.chamadas, 0);
    expect(tester.widget<TextField>(find.byKey(const Key('campo-escrita'))).controller!.text, texto);
  });

  testWidgets('"Escrever outro texto" limpa o campo e o resultado', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    await corrige(tester, texto);
    await tester.ensureVisible(find.byKey(const Key('escrever-outro')));
    await tester.tap(find.byKey(const Key('escrever-outro')));
    await tester.pump();
    expect(find.byKey(const Key('resultado-escrita')), findsNothing);
    expect(tester.widget<TextField>(find.byKey(const Key('campo-escrita'))).controller!.text, isEmpty);
  });

  testWidgets('o campo nunca é desligado nem ganha foco sozinho (armadilha do teclado na web)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia: ia);
    final campo = find.byKey(const Key('campo-escrita'));
    expect(tester.widget<TextField>(campo).autofocus, isFalse);
    tutor.segura = Completer<void>();
    await escreve(tester, texto);
    await tester.tap(find.byKey(const Key('corrigir-escrita')));
    await tester.pump();
    expect(find.byKey(const Key('escrita-corrigindo')), findsOneWidget);
    // esperando a IA: o campo segue ligado e editável; só o botão fica desligado
    expect(tester.widget<TextField>(campo).enabled, isNull);
    expect(tester.widget<TextField>(campo).readOnly, isFalse);
    expect(tester.widget<FilledButton>(find.byKey(const Key('corrigir-escrita'))).onPressed, isNull);
    tutor.segura!.complete();
    await anda(tester);
    expect(tester.widget<TextField>(campo).readOnly, isFalse);
  });

  for (final tamanho in const [Size(360, 740), Size(390, 844), Size(1027, 800)]) {
    testWidgets('sem estouro em ${tamanho.width.toInt()} px (resultado completo, tema claro)', (tester) async {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      final ia = await criar(tester);
      await montar(tester, ia: ia, tamanho: tamanho);
      await corrige(tester, texto);
      expect(find.byKey(const Key('resultado-escrita')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
