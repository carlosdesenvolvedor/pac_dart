// "Tocando agora" do 🎧 Ouvir: o chip da fase segue o estado, os controles chamam o player, os chips mudam
// a config, os avisos (outra fala, sem som, timer, fim), duas colunas a 1400 px, "A seguir", "Praticar esta
// lição", Português → inglês escondendo o inglês, e o teclado só com a tela no topo.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/tocando_page.dart';

import 'ingles_ouvir_ui_test.dart' show MontagemOuvir, montarOuvir, trilhasOuvir;

/// O curso de teste resolvido (7 frases, 3 lições; 2 s cada).
List<Faixa> faixasDoCurso() => resolverFila(IndiceOuvir.de(trilhasOuvir()), [ItemSetlist.doCurso()],
        duracaoDe: (_) => 2, temGravacao: (_) => false)
    .faixas;

OuvirState tocando({int indice = 2, FaseOuvir fase = FaseOuvir.ouvindo, int vez = 1, int de = 1, ConfigOuvir config = const ConfigOuvir()}) =>
    OuvirState(
      status: StatusOuvir.tocando,
      fonte: const FonteOuvir('avulso', 'Teste'),
      fila: faixasDoCurso(),
      indice: indice,
      fase: fase,
      vez: vez,
      de: de,
      config: config,
    );

Future<MontagemOuvir> abrirTocandoAgora(WidgetTester tester,
    {Size tamanho = const Size(1000, 1600), bool claro = false, OuvirState? estado}) async {
  final m = await montarOuvir(tester, tamanho: tamanho, claro: claro, aoAbrir: abrirTocando);
  await mudar(tester, m, estado ?? tocando());
  await tester.tap(find.byKey(const Key('abrir')));
  await tester.pumpAndSettle();
  expect(find.byType(TocandoPage), findsOneWidget);
  return m;
}

/// O cubit entrega o estado num microtask: o primeiro pump só o recebe, o segundo desenha.
Future<void> mudar(WidgetTester tester, MontagemOuvir m, OuvirState s) async {
  m.ouvir.emitir(s);
  await tester.pump();
  await tester.pump();
}

String _texto(WidgetTester tester, String chave) => tester.widget<Text>(find.byKey(Key(chave))).data!;

String _textoFase(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('ouvir-fase')), matching: find.byType(Text)))
    .data!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  testWidgets('mostra a frase, a tradução, onde está, o progresso; o chip da fase segue o estado', (tester) async {
    final m = await abrirTocandoAgora(tester, estado: tocando(vez: 1, de: 2));
    expect(m.ouvir.state.telaCheia, isTrue, reason: 'o mini-player some com a tela cheia');
    expect(find.byKey(const Key('mini-player')), findsNothing);
    expect(_texto(tester, 'ouvir-fonte'), 'Teste');
    expect(_texto(tester, 'ouvir-posicao'), 'Lição 1 de 3 · Frase 3 de 3');
    expect(_texto(tester, 'ouvir-en'), 'Nice to meet you.');
    expect(_texto(tester, 'ouvir-pt'), 'Prazer em te conhecer.');
    expect(_texto(tester, 'ouvir-trilha'), 'A1 › Primeiro contato › Oi, tudo bem?');
    expect(_texto(tester, 'ouvir-progresso'), 'Frase 3 de 7 · faltam ~10 s');
    expect(find.text('Mike'), findsOneWidget);
    expect(_textoFase(tester), '🔊 Ouça (1/2)');

    await mudar(tester, m, m.ouvir.state.copyWith(fase: FaseOuvir.suaVez));
    expect(_textoFase(tester), '🗣️ Sua vez — repita em voz alta');
    await mudar(tester, m, m.ouvir.state.copyWith(indice: 3, fase: FaseOuvir.ouvindo, de: 1));
    expect(_textoFase(tester), '🔊 Ouça');
    expect(_texto(tester, 'ouvir-posicao'), 'Lição 2 de 3 · Frase 1 de 2');
    expect(_texto(tester, 'ouvir-en'), 'A coffee, please.');

    // fechar a tela devolve o mini-player
    await tester.tap(find.byKey(const Key('ouvir-minimizar')));
    await tester.pumpAndSettle();
    expect(m.ouvir.state.telaCheia, isFalse);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
  });

  testWidgets('os controles chamam o player', (tester) async {
    final m = await abrirTocandoAgora(tester);
    for (final k in ['ouvir-licao-anterior', 'ouvir-anterior', 'ouvir-play', 'ouvir-proxima', 'ouvir-proxima-licao', 'ouvir-repetir']) {
      await tester.tap(find.byKey(Key(k)));
      await tester.pump();
    }
    expect(m.ouvir.chamadas, ['licaoAnterior', 'anterior', 'alternar', 'proxima', 'proximaLicao', 'repetirAtual']);
    expect(find.byTooltip('Pausar'), findsOneWidget);
    await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.usuario));
    expect(find.byTooltip('Tocar'), findsOneWidget);
  });

  testWidgets('os chips mudam a config (e o timer)', (tester) async {
    final m = await abrirTocandoAgora(tester);
    Future<void> toque(String k) async {
      await tester.ensureVisible(find.byKey(Key(k)));
      await tester.tap(find.byKey(Key(k)));
      await tester.pump();
    }

    await toque('chip-velocidade');
    expect(m.ouvir.state.config.velocidade, 1.15);
    expect(find.text('Velocidade 1,15×'), findsOneWidget);
    await toque('chip-velocidade');
    expect(find.text('Velocidade 0,75×'), findsOneWidget);
    await toque('chip-modo');
    expect(m.ouvir.state.config.modo, ModoOuvir.inglesPortugues);
    expect(find.text('Inglês → português'), findsOneWidget);
    expect(find.text('Com a tela apagada, o português pode não tocar. Use «Só inglês».'), findsOneWidget);
    await toque('chip-repetir');
    expect(m.ouvir.state.config.repeticoes, 2);
    await toque('chip-devagar');
    expect(m.ouvir.state.config.segundaDevagar, isTrue);
    await toque('chip-pausa');
    expect(m.ouvir.state.config.pausa, PausaOuvir.longa);
    expect(find.text('Pausa: Longa'), findsOneWidget);
    await toque('chip-traducao');
    expect(m.ouvir.state.config.mostrarTraducao, isFalse);
    expect(find.byKey(const Key('ouvir-pt')), findsNothing);
    await toque('chip-repetir-tudo');
    expect(m.ouvir.state.config.repetirTudo, isTrue);
    await toque('chip-desligar');
    expect(m.ouvir.state.desligar, DesligarEm.min15);
    expect(find.text('⏾ Desligar: 15 min'), findsOneWidget);
  });

  testWidgets('os avisos: outra fala, sem som, timer e fim (com "Tocar de novo")', (tester) async {
    final m = await abrirTocandoAgora(tester);
    expect(find.byKey(const Key('ouvir-banner-outra-fala')), findsNothing);
    await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.outraFala));
    expect(find.byKey(const Key('ouvir-banner-outra-fala')), findsOneWidget);
    expect(find.text('Pausado: outra fala começou. ▶ para continuar.'), findsOneWidget);
    await mudar(tester, m, m.ouvir.state.copyWith(motivo: MotivoPausa.semSom));
    expect(find.byKey(const Key('ouvir-banner-sem-som')), findsOneWidget);
    await mudar(tester, m, m.ouvir.state.copyWith(motivo: MotivoPausa.timer));
    expect(find.text('Timer acabou — até amanhã! 🌙'), findsOneWidget);
    await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.acabou, semMotivo: true, ouvidas: 7, indice: 6));
    expect(find.byKey(const Key('ouvir-banner-fim')), findsOneWidget);
    expect(find.text('Fim de «Teste» 🎉 Você ouviu 7 frases.'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('ouvir-tocar-de-novo')));
    await tester.tap(find.byKey(const Key('ouvir-tocar-de-novo')));
    await tester.pump();
    expect(m.ouvir.chamadas.last, 'tocar');
    expect(m.ouvir.tocou!.inicio, 0);
    expect(find.byKey(const Key('ouvir-banner-fim')), findsNothing);
    // pausa do próprio aluno não tem aviso
    await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.usuario));
    expect(textoDoAviso(m.ouvir.state), isNull);
  });

  testWidgets('1400 px: duas colunas com "A seguir" à direita; 390 px: uma coluna, "A seguir" recolhível', (tester) async {
    final m = await abrirTocandoAgora(tester, tamanho: const Size(1400, 900));
    expect(find.byKey(const Key('ouvir-duas-colunas')), findsOneWidget);
    expect(find.byKey(const Key('a-seguir-3')), findsOneWidget);
    await tester.tap(find.byKey(const Key('a-seguir-5')));
    await tester.pump();
    expect(m.ouvir.chamadas.last, 'irPara:5');

    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ouvir-duas-colunas')), findsNothing);
    expect(find.byKey(const Key('a-seguir-3')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('ouvir-a-seguir')));
    await tester.tap(find.byKey(const Key('ouvir-a-seguir')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('a-seguir-3')), findsOneWidget);
    expect(find.byKey(const Key('a-seguir-6')), findsOneWidget);
  });

  testWidgets('teclado: espaço, ←, →, R; nada com outra tela por cima; Esc minimiza', (tester) async {
    final m = await abrirTocandoAgora(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    expect(m.ouvir.chamadas, ['alternar', 'proxima', 'anterior', 'repetirAtual']);

    unawaitedPush(m);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(m.ouvir.chamadas.length, 4, reason: 'o "Tocando agora" não está no topo');
    m.nav.chave.currentState!.pop();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsNothing);
    expect(m.ouvir.state.telaCheia, isFalse);
  });

  testWidgets('teclado: com o foco num chip (Tab), espaço ativa o chip e ←/→ não pulam frase', (tester) async {
    final m = await abrirTocandoAgora(tester);
    bool noChip() {
      final c = FocusManager.instance.primaryFocus?.context;
      if (c == null) return false;
      var achou = false;
      c.visitAncestorElements((e) {
        if (e.widget.key == const Key('chip-velocidade')) achou = true;
        return !achou;
      });
      return achou;
    }

    for (var i = 0; i < 60 && !noChip(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(noChip(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(m.ouvir.chamadas, ['configurar'], reason: 'o espaço ativou o chip, não o tocar/pausar');
    expect(m.ouvir.state.config.velocidade, 1.15);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    expect(m.ouvir.chamadas, ['configurar']);
    // Esc minimiza de qualquer lugar
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(TocandoPage), findsNothing);
  });

  testWidgets('leitor de tela: só os chips de liga/desliga são interruptores; os outros dizem o próximo valor',
      (tester) async {
    final sem = tester.ensureSemantics();
    await abrirTocandoAgora(tester);
    SemanticsNode no(String k) => tester.getSemantics(find.byKey(Key(k)));
    expect(no('chip-velocidade'), isSemantics(hasToggledState: false, onTapHint: 'mudar para 1,15×'));
    expect(no('chip-modo'), isSemantics(hasToggledState: false, onTapHint: 'mudar para Inglês → português'));
    expect(no('chip-repetir'), isSemantics(hasToggledState: false, onTapHint: 'mudar para 2×'));
    expect(no('chip-pausa'), isSemantics(hasToggledState: false, onTapHint: 'mudar para Longa'));
    expect(no('chip-desligar'), isSemantics(hasToggledState: false, onTapHint: 'mudar para 15 min'));
    expect(no('chip-devagar'), isSemantics(hasToggledState: true, isToggled: false));
    expect(no('chip-traducao'), isSemantics(hasToggledState: true, isToggled: true));
    expect(no('chip-repetir-tudo'), isSemantics(hasToggledState: true, isToggled: false));
    sem.dispose();
  });

  testWidgets('"Praticar esta lição" pausa, seleciona a lição e volta ao palco', (tester) async {
    final m = await abrirTocandoAgora(tester, estado: tocando(indice: 5));
    await tester.ensureVisible(find.byKey(const Key('ouvir-praticar')));
    await tester.tap(find.byKey(const Key('ouvir-praticar')));
    await tester.pumpAndSettle();
    expect(m.ouvir.chamadas, ['pausar']);
    expect(m.curso.state.trilhaIdx, 1);
    expect(m.curso.state.licaoIdx, 0);
    expect(find.byType(TocandoPage), findsNothing);
  });

  testWidgets('"Pôr esta frase na setlist" põe a frase atual (em "Minha setlist")', (tester) async {
    final m = await abrirTocandoAgora(tester);
    await tester.ensureVisible(find.byKey(const Key('ouvir-por-frase')));
    await tester.tap(find.byKey(const Key('ouvir-por-frase')));
    await tester.pumpAndSettle();
    final item = m.setlists.state.visiveis.single.itens.single;
    expect(item.tipo, TipoItem.frase);
    expect(item.ref, 'f-3');
    expect(find.text('Adicionado a «Minha setlist».'), findsOneWidget);
  });

  testWidgets('Português → inglês: o inglês fica escondido enquanto a pessoa pensa', (tester) async {
    const pi = ConfigOuvir(modo: ModoOuvir.portuguesIngles, mostrarTraducao: false);
    final m = await abrirTocandoAgora(tester, estado: tocando(fase: FaseOuvir.pense, config: pi));
    expect(_texto(tester, 'ouvir-en'), '…');
    expect(_texto(tester, 'ouvir-pt'), 'Prazer em te conhecer.', reason: 'o português é a pergunta');
    await mudar(tester, m, m.ouvir.state.copyWith(fase: FaseOuvir.ouvindo));
    expect(_texto(tester, 'ouvir-en'), 'Nice to meet you.');
  });

  group('nada estoura', () {
    for (final largura in [360.0, 390.0, 1400.0]) {
      for (final claro in [false, true]) {
        testWidgets('${largura.toInt()} px ${claro ? 'claro' : 'escuro'}, com aviso, chips e A seguir aberto', (tester) async {
          const cfg = ConfigOuvir(modo: ModoOuvir.portuguesIngles, velocidade: 1.15, repeticoes: 3, pausa: PausaOuvir.eco);
          final m = await abrirTocandoAgora(tester,
              tamanho: Size(largura, 800), claro: claro, estado: tocando(fase: FaseOuvir.suaVez, vez: 2, de: 3, config: cfg));
          await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.outraFala));
          if (largura < 900) {
            await tester.ensureVisible(find.byKey(const Key('ouvir-a-seguir')));
            await tester.tap(find.byKey(const Key('ouvir-a-seguir')));
            await tester.pumpAndSettle();
          }
          await mudar(tester, m, m.ouvir.state.copyWith(status: StatusOuvir.acabou, semMotivo: true, ouvidas: 1234));
          expect(tester.takeException(), isNull);
          // os cinco controles + ↺ cabem numa linha de 48 px
          final play = tester.getRect(find.byKey(const Key('ouvir-play')));
          final repetir = tester.getRect(find.byKey(const Key('ouvir-repetir')));
          expect(repetir.top, lessThan(play.bottom));
          expect(tester.getSize(find.byKey(const Key('ouvir-proxima'))).height, greaterThanOrEqualTo(48));
        });
      }
    }
  });
}

/// Põe outra tela por cima do "Tocando agora" (pelo Navigator do app).
void unawaitedPush(MontagemOuvir m) {
  m.nav.chave.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('por cima'))));
}
