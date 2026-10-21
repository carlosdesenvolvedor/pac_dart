// O mini-player do 🎧 Ouvir, dentro de `MaterialApp(builder: OuvirShell.envolver)`: fica entre as telas
// (rotas empurradas), some com o "Tocando agora" aberto e com o teclado aberto, ✕ fecha a sessão, tocar
// nele abre o "Tocando agora", o conteúdo encolhe (não fica coberto) e sem OuvirCubit nada disso existe.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/mini_player.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/tocando_page.dart';

import 'ingles_ouvir_ui_test.dart' show MontagemOuvir, montarOuvir;
import 'ingles_tocando_ui_test.dart' show mudar, tocando;

final _mini = find.byKey(const Key('mini-player'));

Future<void> _empurrar(WidgetTester tester, MontagemOuvir m, String texto) async {
  m.nav.chave.currentState!.push(MaterialPageRoute<void>(
    builder: (_) => Scaffold(body: Center(child: Text(texto))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  testWidgets('parado não aparece; tocando aparece e fica entre as telas', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    expect(find.byType(OuvirShell), findsOneWidget);
    expect(_mini, findsNothing);
    await mudar(tester, m, tocando());
    expect(_mini, findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('mini-player-frase'))).data, 'Nice to meet you.');
    expect(tester.widget<Text>(find.byKey(const Key('mini-player-linha2'))).data, 'Oi, tudo bem? · 3/7');
    await _empurrar(tester, m, 'tela 2');
    expect(find.text('tela 2'), findsOneWidget);
    expect(_mini, findsOneWidget);
    await _empurrar(tester, m, 'tela 3');
    expect(_mini, findsOneWidget);
    m.nav.chave.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_mini, findsOneWidget);
  });

  testWidgets('o conteúdo encolhe para a barra caber (139 px no celular, com imagem e tradução)', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    final antes = tester.getSize(find.byType(Scaffold).first).height;
    expect(antes, 844);
    await mudar(tester, m, tocando());
    expect(OuvirShell.alturaBarra(const ConfigOuvir(), cartao: false), 139);
    expect(tester.getSize(find.byType(Scaffold).first).height, 844 - 139);
    expect(tester.getRect(_mini).bottom, 844);
  });

  testWidgets('no computador vira um cartão de 860 px centralizado', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(1400, 900));
    await mudar(tester, m, tocando());
    final r = tester.getRect(_mini);
    expect(r.width, closeTo(860, 2), reason: "860 px menos a borda de 1 px");
    expect(r.center.dx, 700);
    expect(find.byKey(const Key('mini-player-anterior')), findsOneWidget);
  });

  testWidgets('tocar na barra abre o "Tocando agora" e ela some; voltando, reaparece', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, tocando());
    await tester.tap(find.byKey(const Key('mini-player-frase')));
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsOneWidget);
    expect(m.ouvir.state.telaCheia, isTrue);
    expect(_mini, findsNothing);
    m.nav.chave.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_mini, findsOneWidget);
  });

  testWidgets('some com o teclado aberto', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, tocando());
    expect(_mini, findsOneWidget);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    expect(_mini, findsNothing);
    tester.view.resetViewInsets();
    await tester.pump();
    expect(_mini, findsOneWidget);
  });

  testWidgets('⏯ ⏭ chamam o player; ✕ fecha a sessão e a barra some', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, tocando());
    expect(find.byKey(const Key('mini-player-anterior')), findsNothing, reason: 'a 390 px só ⏯ ⏭ ✕');
    await tester.tap(find.byKey(const Key('mini-player-play')));
    await tester.tap(find.byKey(const Key('mini-player-proxima')));
    await tester.tap(find.byKey(const Key('mini-player-fechar')));
    await tester.pump();
    await tester.pump();
    expect(m.ouvir.chamadas, ['alternar', 'proxima', 'fechar']);
    expect(m.ouvir.state.status, StatusOuvir.parado);
    expect(_mini, findsNothing);
  });

  testWidgets('pausa por outra fala e fim aparecem na segunda linha', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(360, 740));
    await mudar(tester, m, tocando().copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.outraFala));
    expect(tester.widget<Text>(find.byKey(const Key('mini-player-linha2'))).data, 'Pausado — outra fala começou');
    await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.acabou, semMotivo: true));
    expect(tester.widget<Text>(find.byKey(const Key('mini-player-linha2'))).data, 'Fim de «Teste» 🎉');
    // ⏯ no fim toca de novo do começo
    await tester.tap(find.byKey(const Key('mini-player-play')));
    await tester.pump();
    expect(m.ouvir.chamadas.last, 'tocar');
    expect(m.ouvir.tocou!.inicio, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leitor de tela: os botões da barra têm rótulo E ação de toque', (tester) async {
    final sem = tester.ensureSemantics();
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, tocando());
    for (final (k, rotulo) in [
      ('mini-player-play', 'Pausar'),
      ('mini-player-proxima', 'Próxima frase'),
      ('mini-player-fechar', 'Fechar player'),
    ]) {
      expect(tester.getSemantics(find.byKey(Key(k))),
          isSemantics(label: rotulo, isButton: true, hasTapAction: true), reason: k);
    }
    tester.semantics.tap(find.semantics.byLabel('Pausar'));
    await tester.pump();
    expect(m.ouvir.chamadas, ['alternar']);
    sem.dispose();
  });

  testWidgets('com folha aberta a barra escurece e não abre o player por cima dela', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, tocando());
    final escuro = find.byKey(const Key('mini-player-escurecido'));
    expect(escuro, findsNothing);
    unawaited(showModalBottomSheet<void>(
      context: tester.element(find.byKey(const Key('abrir'))),
      builder: (_) => const SizedBox(height: 200, child: Center(child: Text('folha'))),
    ));
    await tester.pumpAndSettle();
    expect(escuro, findsOneWidget);
    await tester.tap(find.byKey(const Key('mini-player-frase')), warnIfMissed: false);
    await tester.tap(find.byKey(const Key('mini-player-fechar')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsNothing);
    expect(m.ouvir.chamadas, isEmpty);
    expect(find.text('folha'), findsOneWidget);
    // nem pela função (teclado, outro atalho)
    unawaited(abrirTocando(tester.element(find.byKey(const Key('abrir')))));
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsNothing);

    m.nav.chave.currentState!.pop();
    await tester.pumpAndSettle();
    expect(escuro, findsNothing);
    await tester.tap(find.byKey(const Key('mini-player-frase')));
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsOneWidget);
  });

  testWidgets('no Arcade (rota "arcade") a barra some e o player pausa; na volta ela reaparece', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, tocando());
    unawaited(m.nav.chave.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Center(child: Text('arcade'))),
      settings: const RouteSettings(name: rotaArcade),
    )));
    await tester.pumpAndSettle();
    expect(_mini, findsNothing);
    expect(m.ouvir.chamadas, ['pausar']);
    expect(tester.getSize(find.text('arcade').first), isNotNull);
    expect(tester.getSize(find.byType(Scaffold).last).height, 844, reason: 'o jogo tem a janela inteira');
    m.nav.chave.currentState!.pop();
    await tester.pumpAndSettle();
    expect(_mini, findsOneWidget);
    expect(m.ouvir.state.status, StatusOuvir.pausado);
  });

  testWidgets('o hub tem "Tocando agora" (caminho para o player sem o mini-player) só com o player ligado',
      (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await tester.tap(find.byKey(const Key('abrir')));
    await tester.pumpAndSettle();
    final cartao = find.byKey(const Key('ouvir-tocando-agora'));
    expect(cartao, findsNothing);
    await mudar(tester, m, tocando());
    expect(cartao, findsOneWidget);
    expect(find.text('Tocando agora: «Teste»'), findsOneWidget);
    expect(find.text('Nice to meet you.'), findsWidgets);
    await tester.tap(cartao);
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsOneWidget);
    m.nav.chave.currentState!.pop();
    await tester.pumpAndSettle();
    await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.usuario));
    expect(find.text('Pausado: «Teste»'), findsOneWidget);
  });

  testWidgets('sem OuvirCubit (curso de Dart) não há moldura nem barra', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (c, child) => OuvirShell.envolver(c, child!),
      home: const Scaffold(body: Text('dart')),
    ));
    expect(find.text('dart'), findsOneWidget);
    expect(find.byType(OuvirShell), findsNothing);
    expect(find.byType(MiniPlayer), findsNothing);
  });

  for (final claro in [false, true]) {
    for (final largura in [360.0, 390.0, 1400.0]) {
      testWidgets('nada estoura — ${largura.toInt()} px ${claro ? 'claro' : 'escuro'}', (tester) async {
        final m = await montarOuvir(tester, tamanho: Size(largura, 800), claro: claro);
        await mudar(tester, m, tocando().copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.semSom));
        expect(_mini, findsOneWidget);
        expect(tester.getSize(find.byKey(const Key('mini-player-fechar'))).width, 48);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
