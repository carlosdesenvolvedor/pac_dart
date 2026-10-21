// O mini-player maior do 🎧 Ouvir: a imagem da frase (foto da cena + emoji do sentido), a tradução embaixo
// do inglês e os botões de mostrar/esconder cada uma, que mudam a altura da barra e valem também no
// "Tocando agora" (chip "Imagens"). Sem estouro em 360×640, 390 e 1400, claro e escuro.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/tocando_page.dart';

import 'ingles_ouvir_ui_test.dart' show montarOuvir;
import 'ingles_tocando_ui_test.dart' show mudar, tocando;

const _foto = 'assets/ingles/fotos/primeiro-contato.oi-tudo-bem.jpg';

OuvirState _comImagens({ConfigOuvir config = const ConfigOuvir()}) {
  final base = tocando(config: config);
  final fila = [
    for (final f in base.fila)
      Faixa(
        chave: f.chave,
        en: f.en == 'Nice to meet you.' ? 'Nice to meet you. It is a real pleasure to finally meet you in person.' : f.en,
        pt: f.pt == 'Prazer em te conhecer.'
            ? 'Prazer em te conhecer. É um prazer de verdade finalmente te conhecer pessoalmente.'
            : f.pt,
        quem: f.quem,
        licaoId: f.licaoId,
        licaoNome: f.licaoNome,
        licaoEmoji: f.licaoEmoji,
        trilhaNome: f.trilhaNome,
        etapa: f.etapa,
        itemIdx: f.itemIdx,
        primeiraDaLicao: f.primeiraDaLicao,
        segundos: f.segundos,
        imagem: '🤝😊',
        cena: '💻👋☀️',
        foto: _foto,
        fotoCredito: 'Fulano (CC BY)',
      ),
  ];
  return base.copyWith(fila: fila);
}

String? _texto(WidgetTester tester, String chave) => tester.widget<Text>(find.byKey(Key(chave))).data;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  testWidgets('mostra a tradução embaixo do inglês e a imagem da frase', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, _comImagens());
    expect(_texto(tester, 'mini-player-frase'), startsWith('Nice to meet you.'));
    expect(_texto(tester, 'mini-player-traducao'), startsWith('Prazer em te conhecer.'));
    expect(find.byKey(const Key('mini-player-imagem')), findsOneWidget);
    expect(find.byKey(const Key('imagem-faixa-selo')), findsOneWidget, reason: 'o emoji do sentido sobre a foto');
    expect(find.text('🤝😊'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('os botões da barra ligam/desligam tradução e imagens; sem as duas a barra fica mais baixa',
      (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, _comImagens());
    final alta = tester.getSize(find.byType(Scaffold).first).height;
    expect(alta, 844 - OuvirShell.alturaBarra(const ConfigOuvir(), cartao: false));

    await tester.tap(find.byKey(const Key('mini-player-traducao-alternar')));
    await tester.pump();
    await tester.pump();
    expect(m.ouvir.state.config.mostrarTraducao, isFalse);
    expect(find.byKey(const Key('mini-player-traducao')), findsNothing);
    expect(find.byKey(const Key('mini-player-imagem')), findsOneWidget);
    expect(tester.getSize(find.byType(Scaffold).first).height, alta, reason: 'com a imagem a barra segue alta');

    await tester.tap(find.byKey(const Key('mini-player-imagens-alternar')));
    await tester.pump();
    await tester.pump();
    expect(m.ouvir.state.config.mostrarImagens, isFalse);
    expect(find.byKey(const Key('mini-player-imagem')), findsNothing);
    final baixa = tester.getSize(find.byType(Scaffold).first).height;
    expect(baixa, greaterThan(alta), reason: 'a barra encolhe e o conteúdo ganha espaço');

    await tester.tap(find.byKey(const Key('mini-player-traducao-alternar')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('mini-player-traducao')), findsOneWidget);
    expect(m.ouvir.chamadas.where((c) => c == 'configurar'), hasLength(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('leitor de tela: os botões dizem se estão ligados', (tester) async {
    final sem = tester.ensureSemantics();
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(tester, m, _comImagens());
    expect(tester.getSemantics(find.byKey(const Key('mini-player-traducao-alternar'))),
        isSemantics(label: 'Tradução: ligada', isButton: true, hasToggledState: true, isToggled: true, hasTapAction: true));
    expect(tester.getSemantics(find.byKey(const Key('mini-player-imagens-alternar'))),
        isSemantics(label: 'Imagens: ligada', isButton: true, hasToggledState: true, isToggled: true, hasTapAction: true));
    sem.dispose();
  });

  testWidgets('"Português → inglês" esconde o inglês enquanto pensa e mostra a tradução', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844));
    await mudar(
        tester,
        m,
        _comImagens(config: const ConfigOuvir(modo: ModoOuvir.portuguesIngles, mostrarTraducao: false))
            .copyWith(fase: FaseOuvir.pense));
    expect(_texto(tester, 'mini-player-frase'), '…');
    expect(_texto(tester, 'mini-player-traducao'), startsWith('Prazer'));
  });

  for (final (nome, tamanho) in [('360×640', Size(360, 640)), ('390×844', Size(390, 844)), ('1400×900', Size(1400, 900))]) {
    for (final claro in [false, true]) {
      for (final cfg in const [
        ConfigOuvir(),
        ConfigOuvir(mostrarImagens: false),
        ConfigOuvir(mostrarTraducao: false),
        ConfigOuvir(mostrarImagens: false, mostrarTraducao: false),
      ]) {
        testWidgets('sem estouro em $nome ${claro ? 'claro' : 'escuro'} (tradução ${cfg.mostrarTraducao}, '
            'imagens ${cfg.mostrarImagens})', (tester) async {
          final m = await montarOuvir(tester, tamanho: tamanho, claro: claro);
          await mudar(tester, m, _comImagens(config: cfg).copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.semSom));
          await tester.pump(const Duration(milliseconds: 300));
          expect(find.byKey(const Key('mini-player')), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  testWidgets('"Tocando agora": imagem grande com crédito, chip "Imagens" esconde', (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 844), aoAbrir: abrirTocando);
    await mudar(tester, m, _comImagens());
    await tester.tap(find.byKey(const Key('abrir')));
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsOneWidget);
    expect(find.byKey(const Key('ouvir-imagem')), findsOneWidget);
    expect(find.text('foto: Fulano (CC BY)'), findsOneWidget);
    final selo = tester.getSize(find.descendant(of: find.byKey(const Key('ouvir-imagem')), matching: find.byKey(const Key('imagem-faixa-selo'))));
    expect(selo.width, lessThan(tester.getSize(find.byKey(const Key('ouvir-imagem'))).width / 2),
        reason: 'o selo abraça os emojis, não estica na foto');
    await tester.ensureVisible(find.byKey(const Key('chip-imagens')));
    await tester.tap(find.byKey(const Key('chip-imagens')));
    await tester.pump();
    await tester.pump();
    expect(m.ouvir.state.config.mostrarImagens, isFalse);
    expect(find.byKey(const Key('ouvir-imagem')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
