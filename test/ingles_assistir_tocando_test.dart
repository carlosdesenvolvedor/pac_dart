// 📺 "Escutar assistindo" na interface do 🎧 Ouvir (grupo E do plano das historinhas): o botão 📺 do
// "Tocando agora" (só com faixa de lição; fora do bloco da foto), o palco no lugar da foto (sem o rosto do
// topo), a pref lembrada e lida de forma síncrona (o player aberto pelo mini-player já nasce no desenho),
// o padrão desligado = o layout de hoje, o selo "novo", o ⛶ (Esc sai da tela cheia; o 2º Esc minimiza),
// o teclado, a troca de largura sem perder o palco (GlobalKey), `abrirTocando(assistir:)`, as portas da
// playlist (cartão do curso, 📺 em cada setlist e na página da setlist), a faixa órfã e 360/390/1400 px.
//
// O palco em si é do grupo C (`PalcoAssistir`): aqui só se confere que ele está (ou não) no lugar certo.
// Como o palco de verdade tem um Ticker enquanto o player toca, os testes com ele na tela andam com
// `pump(duração)` em vez de `pumpAndSettle`.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/preferencia_assistir.dart';
import 'package:pac_dart/features/ingles/data/preferencias_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/setlist.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/palco_assistir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/mini_player.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_acoes.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_page.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/setlist_page.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/tocando_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_ouvir_ui_test.dart' show MontagemOuvir, bancoComSetlist, montarOuvir;
import 'ingles_tocando_ui_test.dart' show mudar, tocando;

/// As faixas do curso de teste com o emoji do sentido (a foto da cena aparece no layout de hoje).
List<Faixa> _comEmoji(List<Faixa> fila) => [
      for (final f in fila)
        Faixa(
          chave: f.chave,
          en: f.en,
          pt: f.pt,
          quem: f.quem,
          licaoId: f.licaoId,
          licaoNome: f.licaoNome,
          licaoEmoji: f.licaoEmoji,
          trilhaNome: f.trilhaNome,
          etapa: f.etapa,
          itemIdx: f.itemIdx,
          primeiraDaLicao: f.primeiraDaLicao,
          segundos: f.segundos,
          imagem: '🙂',
        ),
    ];

/// Tocando a 3ª frase do curso ("Nice to meet you.", do Mike), com imagem.
OuvirState _estado({int indice = 2, ConfigOuvir config = const ConfigOuvir(), StatusOuvir? status}) {
  final base = tocando(indice: indice, config: config);
  return base.copyWith(fila: _comEmoji(base.fila), status: status);
}

/// Uma frase órfã (texto do aluno, sem lição do curso) na frente do curso.
OuvirState _comOrfa() {
  final base = _estado();
  return base.copyWith(
    indice: 0,
    fila: [
      const Faixa(chave: 'txt-1', en: 'The garden is lovely.', pt: 'O jardim é lindo.', imagem: '🌷', segundos: 2),
      ...base.fila,
    ],
  );
}

/// Anda o relógio o bastante para a rota entrar/sair (sem esperar o palco "assentar": ele tem Ticker).
Future<void> _andar(WidgetTester tester, {int vezes = 8}) async {
  for (var i = 0; i < vezes; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Monta o app de teste e abre o "Tocando agora" pelo botão `abrir` ([aoAbrir]; padrão `abrirTocando`).
Future<MontagemOuvir> _abrir(
  WidgetTester tester, {
  Size tamanho = const Size(390, 900),
  OuvirState? estado,
  bool prefLigada = false,
  Future<void> Function(BuildContext c)? aoAbrir,
  PreferenciasOuvir? prefs,
}) async {
  final m = await montarOuvir(tester, tamanho: tamanho, aoAbrir: aoAbrir ?? abrirTocando, prefs: prefs);
  await tester.pump();
  if (prefLigada) await PreferenciaAssistir.salvar(true);
  await mudar(tester, m, estado ?? _estado());
  await tester.tap(find.byKey(const Key('abrir')));
  await _andar(tester);
  expect(find.byType(TocandoPage), findsOneWidget);
  return m;
}

/// Os rostos do "Tocando agora" fora do palco (o palco pode desenhar os dele).
int _rostosForaDoPalco() =>
    find.byType(RostoDaFaixa).evaluate().length -
    find.descendant(of: find.byType(PalcoAssistir), matching: find.byType(RostoDaFaixa)).evaluate().length;

/// O ⛶ do palco: o botão do grupo C, quando existe; senão o callback que o "Tocando agora" passou.
Future<void> _telaCheia(WidgetTester tester) async {
  final botao = find.byKey(const Key('assistir-tela-cheia'));
  if (botao.evaluate().isNotEmpty) {
    await tester.tap(botao);
  } else {
    final palco = tester.widget<PalcoAssistir>(find.byType(PalcoAssistir));
    expect(palco.onTelaCheia, isNotNull, reason: 'o "Tocando agora" liga o ⛶');
    palco.onTelaCheia!();
  }
  await _andar(tester, vezes: 2);
}

/// Quantos [chave] há na árvore, contando o quadro "offstage" do começo da transição.
int _noPrimeiroQuadro(String chave) => find.byKey(Key(chave), skipOffstage: false).evaluate().length;

double _tamanhoEn(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('ouvir-en'))).style!.fontSize!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(PreferenciaAssistir.reiniciar);
  tearDown(PreferenciaAssistir.reiniciar);

  testWidgets('padrão desligado = o layout de hoje: a foto, o rosto e o botão 📺 com o selo "novo"', (tester) async {
    await _abrir(tester);
    expect(find.byKey(const Key('ouvir-imagem')), findsOneWidget);
    expect(find.byKey(const Key('assistir-palco')), findsNothing);
    expect(find.byType(PalcoAssistir), findsNothing);
    expect(_rostosForaDoPalco(), 1);
    expect(_tamanhoEn(tester), 26);
    expect(find.byKey(const Key('ouvir-assistir')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('ouvir-assistir')), matching: find.text('📺 Assistir')),
        findsOneWidget);
    expect(find.byKey(const Key('ouvir-assistir-novo')), findsOneWidget, reason: 'o selo até o 1º uso');
    expect(find.byKey(const Key('assistir-sem-desenho')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('o 📺 só aparece com faixa de lição do curso', (tester) async {
    final m = await _abrir(tester, estado: _comOrfa());
    expect(find.byKey(const Key('ouvir-assistir')), findsNothing, reason: 'frase do aluno: sem desenho');
    expect(find.byKey(const Key('ouvir-imagem')), findsOneWidget);
    await mudar(tester, m, m.ouvir.state.copyWith(indice: 1));
    expect(find.byKey(const Key('ouvir-assistir')), findsOneWidget);
  });

  testWidgets('ligar troca a foto pelo palco, some o rosto, o selo sai e a pref fica gravada', (tester) async {
    final sem = tester.ensureSemantics();
    await _abrir(tester);
    expect(tester.getSemantics(find.byKey(const Key('ouvir-assistir'))),
        isSemantics(isButton: true, hasToggledState: true, isToggled: false, label: 'Assistir como desenho animado'));

    await tester.tap(find.byKey(const Key('ouvir-assistir')));
    await _andar(tester, vezes: 2);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    expect(find.byType(PalcoAssistir), findsOneWidget);
    expect(find.byKey(const Key('ouvir-imagem')), findsNothing);
    expect(_rostosForaDoPalco(), 0, reason: 'o palco já mostra quem fala');
    expect(find.byKey(const Key('ouvir-en')), findsOneWidget, reason: 'o inglês continua, menor');
    expect(_tamanhoEn(tester), 22);
    expect(find.descendant(of: find.byKey(const Key('ouvir-assistir')), matching: find.text('🖼️ Foto')), findsOneWidget);
    expect(find.byKey(const Key('ouvir-assistir-novo')), findsNothing);
    expect(tester.getSemantics(find.byKey(const Key('ouvir-assistir'))),
        isSemantics(isButton: true, hasToggledState: true, isToggled: true));
    expect(PreferenciaAssistir.valor.value, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(PreferenciaAssistir.chave), isTrue);
    expect(prefs.getBool(PreferenciaAssistir.chaveNovidade), isTrue);

    // desligar volta a foto e grava
    await tester.tap(find.byKey(const Key('ouvir-assistir')));
    await _andar(tester, vezes: 2);
    expect(find.byKey(const Key('ouvir-imagem')), findsOneWidget);
    expect(find.byType(PalcoAssistir), findsNothing);
    expect(_rostosForaDoPalco(), 1);
    expect(prefs.getBool(PreferenciaAssistir.chave), isFalse);
    expect(tester.takeException(), isNull);
    sem.dispose();
  });

  testWidgets('a pref persiste: minimizar mostra o mini-player e reabrir já nasce no desenho (1º pump)',
      (tester) async {
    final m = await _abrir(tester);
    await tester.tap(find.byKey(const Key('ouvir-assistir')));
    await _andar(tester, vezes: 2);
    await tester.tap(find.byKey(const Key('ouvir-minimizar')));
    await _andar(tester);
    expect(find.byType(TocandoPage), findsNothing);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    expect(m.ouvir.state.telaCheia, isFalse);

    await tester.tap(find.byKey(const Key('mini-player-abrir')));
    await tester.pump();
    // o 1º quadro da rota nova ainda está "offstage" (o HeroController mede a transição): já tem o palco
    expect(find.byType(TocandoPage, skipOffstage: false), findsOneWidget);
    expect(_noPrimeiroQuadro('assistir-palco'), 1, reason: 'a pref é lida de forma síncrona');
    expect(_noPrimeiroQuadro('ouvir-imagem'), 0, reason: 'sem piscar foto → palco');
    await _andar(tester);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    expect(find.byKey(const Key('ouvir-assistir-novo')), findsNothing);

    // e um TocandoPage() novo, montado direto, também
    await tester.tap(find.byKey(const Key('ouvir-minimizar')));
    await _andar(tester);
    m.nav.chave.currentState!.push(MaterialPageRoute<void>(builder: (_) => const TocandoPage()));
    await tester.pump();
    expect(_noPrimeiroQuadro('assistir-palco'), 1);
    expect(_noPrimeiroQuadro('ouvir-imagem'), 0);
    await _andar(tester);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
  });

  testWidgets('com "Imagens" desligado (e sem foto) o 📺 continua: botão visível e palco no lugar', (tester) async {
    await _abrir(tester,
        prefLigada: true, estado: tocando(config: const ConfigOuvir(mostrarImagens: false)));
    expect(find.byKey(const Key('ouvir-imagem')), findsNothing);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    expect(find.byKey(const Key('ouvir-assistir')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('faixa órfã com o 📺 ligado: a foto e o aviso "sem desenho"; o botão fica para desligar',
      (tester) async {
    final m = await _abrir(tester, prefLigada: true, estado: _comOrfa());
    expect(find.byKey(const Key('assistir-sem-desenho')), findsOneWidget);
    expect(find.text('Sem desenho para esta frase (ela não é de uma lição do curso)'), findsOneWidget);
    expect(find.byKey(const Key('ouvir-imagem')), findsOneWidget);
    expect(find.byType(PalcoAssistir), findsNothing);
    expect(find.byKey(const Key('ouvir-assistir')), findsOneWidget);
    // a próxima faixa é de lição: o palco volta
    await mudar(tester, m, m.ouvir.state.copyWith(indice: 1));
    expect(find.byKey(const Key('assistir-sem-desenho')), findsNothing);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('⛶: entra e sai (Esc sai da tela cheia; o 2º Esc minimiza); a barra compacta chama o player',
      (tester) async {
    final m = await _abrir(tester, prefLigada: true, tamanho: const Size(1280, 720));
    final estadoDoPalco = tester.state(find.byType(PalcoAssistir));
    await _telaCheia(tester);
    expect(find.byKey(const Key('assistir-tela-cheia-layout')), findsOneWidget);
    expect(find.byKey(const Key('assistir-barra')), findsOneWidget);
    expect(find.byKey(const Key('ouvir-minimizar')), findsNothing);
    expect(find.byKey(const Key('ouvir-en')), findsNothing);
    expect(tester.widget<PalcoAssistir>(find.byType(PalcoAssistir)).grande, isTrue);
    expect(identical(tester.state(find.byType(PalcoAssistir)), estadoDoPalco), isTrue,
        reason: 'o ⛶ não recria o palco (GlobalKey)');
    for (final k in ['assistir-anterior', 'assistir-play', 'assistir-proxima', 'assistir-proxima-licao']) {
      await tester.tap(find.byKey(Key(k)));
      await tester.pump();
    }
    expect(m.ouvir.chamadas, ['anterior', 'alternar', 'proxima', 'proximaLicao']);
    await tester.tap(find.byKey(const Key('chip-velocidade')));
    await tester.pump();
    expect(m.ouvir.state.config.velocidade, 1.15, reason: 'os chips do Ouvir valem na tela cheia');

    // Esc: só sai da tela cheia
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _andar(tester, vezes: 2);
    expect(find.byType(TocandoPage), findsOneWidget);
    expect(find.byKey(const Key('assistir-tela-cheia-layout')), findsNothing);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    expect(identical(tester.state(find.byType(PalcoAssistir)), estadoDoPalco), isTrue);

    // o botão de sair da barra também
    await _telaCheia(tester);
    await tester.tap(find.byKey(const Key('assistir-sair-tela-cheia')));
    await _andar(tester, vezes: 2);
    expect(find.byKey(const Key('assistir-tela-cheia-layout')), findsNothing);

    // o voltar do sistema na tela cheia também só sai dela
    await _telaCheia(tester);
    await m.nav.chave.currentState!.maybePop();
    await _andar(tester, vezes: 2);
    expect(find.byType(TocandoPage), findsOneWidget);
    expect(find.byKey(const Key('assistir-tela-cheia-layout')), findsNothing);

    // fora da tela cheia, o Esc minimiza como sempre
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _andar(tester);
    expect(find.byType(TocandoPage), findsNothing);
    expect(find.byKey(const Key('mini-player')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('teclado com o 📺 ligado: espaço, ←, →, R continuam (na página e no ⛶)', (tester) async {
    final m = await _abrir(tester);
    await tester.tap(find.byKey(const Key('ouvir-assistir')));
    await _andar(tester, vezes: 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    expect(m.ouvir.chamadas, ['alternar', 'proxima', 'anterior', 'repetirAtual']);
    await _telaCheia(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(m.ouvir.chamadas, ['alternar', 'proxima', 'anterior', 'repetirAtual', 'alternar', 'proxima']);
  });

  testWidgets('trocar 1400 → 800 px e entrar/sair do ⛶ não recria o palco', (tester) async {
    await _abrir(tester, prefLigada: true, tamanho: const Size(1400, 900));
    expect(find.byKey(const Key('ouvir-duas-colunas')), findsOneWidget);
    expect(_tamanhoEn(tester), 26);
    final estado = tester.state(find.byType(PalcoAssistir));
    final tamanhoLargo = tester.getSize(find.byType(PalcoAssistir));
    expect(tamanhoLargo.height, inInclusiveRange(260, 520));
    tester.view.physicalSize = const Size(800, 900);
    await _andar(tester, vezes: 2);
    expect(find.byKey(const Key('ouvir-duas-colunas')), findsNothing);
    expect(identical(tester.state(find.byType(PalcoAssistir)), estado), isTrue);
    final tamanhoEstreito = tester.getSize(find.byType(PalcoAssistir));
    expect(tamanhoEstreito.width, lessThanOrEqualTo(720));
    expect(tamanhoEstreito.height, inInclusiveRange(200, 380));
    await _telaCheia(tester);
    expect(identical(tester.state(find.byType(PalcoAssistir)), estado), isTrue);
    tester.view.physicalSize = const Size(1400, 900);
    await _andar(tester, vezes: 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _andar(tester, vezes: 2);
    expect(identical(tester.state(find.byType(PalcoAssistir)), estado), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abrirTocando(assistir:) manda mais que a pref', (tester) async {
    await _abrir(tester, aoAbrir: (c) => abrirTocando(c, assistir: true));
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    expect(PreferenciaAssistir.valor.value, isFalse, reason: 'abrir assistindo não muda a pref sozinho');
  });

  testWidgets('abrirTocando(assistir: false) abre na foto mesmo com a pref ligada', (tester) async {
    await _abrir(tester, prefLigada: true, aoAbrir: (c) => abrirTocando(c, assistir: false));
    expect(find.byKey(const Key('ouvir-imagem')), findsOneWidget);
    expect(find.byType(PalcoAssistir), findsNothing);
  });

  testWidgets('um 📺 da playlist com o player já aberto (telaCheia) não perde o pedido', (tester) async {
    final m = await _abrir(tester);
    expect(m.ouvir.state.telaCheia, isTrue);
    expect(find.byKey(const Key('ouvir-imagem')), findsOneWidget);
    final contexto = tester.element(find.byType(TocandoPage));
    final s = bancoComSetlist().porId['s1']!;
    // a setlist resolve contra o curso do teste; o abrirTocando volta cedo (já aberto)
    await assistirSetlist(contexto, s);
    await _andar(tester, vezes: 2);
    expect(m.ouvir.tocou!.fonte.id, 'setlist:s1');
    expect(find.byType(TocandoPage), findsOneWidget, reason: 'não empilha outro player');
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget, reason: 'o player aberto segue a pref');
    expect(PreferenciaAssistir.valor.value, isTrue);
  });

  testWidgets('o pedido feito com telaCheia true (sem player na tela) vale para o próximo "Tocando agora"',
      (tester) async {
    final m = await montarOuvir(tester, tamanho: const Size(390, 900));
    await tester.pump();
    await mudar(tester, m, _estado().copyWith(telaCheia: true));
    final contexto = tester.element(find.byKey(const Key('abrir')));
    await assistirCurso(contexto, inicio: 3);
    await _andar(tester, vezes: 2);
    expect(m.ouvir.tocou!.inicio, 3);
    expect(find.byType(TocandoPage), findsNothing, reason: 'o abrirTocando volta cedo com telaCheia true');
    expect(PreferenciaAssistir.valor.value, isTrue);
    await mudar(tester, m, m.ouvir.state.copyWith(telaCheia: false));
    m.nav.chave.currentState!.push(MaterialPageRoute<void>(builder: (_) => const TocandoPage()));
    await tester.pump();
    expect(_noPrimeiroQuadro('assistir-palco'), 1);
    await _andar(tester);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
  });

  group('as portas da playlist', () {
    Future<MontagemOuvir> hub(WidgetTester tester, {PreferenciasOuvir? prefs}) async {
      final m = await montarOuvir(tester, banco: bancoComSetlist(), prefs: prefs);
      await tester.pump();
      await tester.tap(find.byKey(const Key('abrir')));
      await _andar(tester);
      expect(find.byType(OuvirPage), findsOneWidget);
      return m;
    }

    testWidgets('o cartão "📺 Escutar assistindo": "Da minha lição atual" toca como o botão do curso e abre assistindo',
        (tester) async {
      final m = await montarOuvir(tester, banco: bancoComSetlist());
      // a lição atual do palco: "No aeroporto" (trilha 1, lição 0) → faixa 5 do curso
      m.curso.add(const TrilhaSelecionada(1));
      m.curso.add(const LicaoSelecionada(0));
      await tester.pump();
      await tester.tap(find.byKey(const Key('abrir')));
      await _andar(tester);
      expect(find.byKey(const Key('ouvir-assistir-cartao')), findsOneWidget);
      expect(find.text('As frases da lição viram desenho animado: cada personagem fala a sua frase'), findsOneWidget);
      expect(find.byKey(const Key('ouvir-assistir-continuar')), findsNothing, reason: 'nada ouvido ainda');
      await tester.tap(find.byKey(const Key('ouvir-curso-atual')));
      await _andar(tester, vezes: 2);
      final doCurso = m.ouvir.tocou!;
      expect(find.byType(TocandoPage), findsNothing, reason: 'o ▶ de sempre não abre o player');

      await tester.ensureVisible(find.byKey(const Key('ouvir-assistir-curso')));
      await tester.tap(find.byKey(const Key('ouvir-assistir-curso')));
      await _andar(tester);
      expect(m.ouvir.tocou!.fonte, doCurso.fonte);
      expect(m.ouvir.tocou!.inicio, doCurso.inicio);
      expect(m.ouvir.tocou!.inicio, 5);
      expect(find.byType(TocandoPage), findsOneWidget);
      expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
      expect(PreferenciaAssistir.valor.value, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('"Continuar" do 📺 usa o mesmo índice do "Continuar" do curso', (tester) async {
      final prefs = PreferenciasOuvirMemoria()..posicoes['curso'] = (i: 3, chave: 'f-4');
      final m = await hub(tester, prefs: prefs);
      expect(find.byKey(const Key('ouvir-assistir-continuar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ouvir-curso-continuar')));
      await _andar(tester, vezes: 2);
      expect(m.ouvir.tocou!.inicio, 3);
      m.ouvir.tocou = null;
      await tester.ensureVisible(find.byKey(const Key('ouvir-assistir-continuar')));
      await tester.tap(find.byKey(const Key('ouvir-assistir-continuar')));
      await _andar(tester);
      expect(m.ouvir.tocou!.fonte.id, 'curso');
      expect(m.ouvir.tocou!.inicio, 3);
      expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    });

    testWidgets('📺 no cartão da setlist toca a setlist e abre assistindo', (tester) async {
      final m = await hub(tester);
      final botao = find.byKey(const Key('setlist-assistir-s1'));
      await tester.ensureVisible(botao);
      expect(tester.widget<IconButton>(botao).tooltip, 'Escutar assistindo');
      await tester.tap(botao);
      await _andar(tester);
      expect(m.ouvir.chamadas, contains('tocar'));
      expect(m.ouvir.tocou!.fonte, const FonteOuvir('setlist:s1', 'Ônibus'));
      expect(m.ouvir.tocou!.fila.length, 4);
      expect(m.ouvir.tocou!.inicio, 0);
      expect(find.byType(TocandoPage), findsOneWidget);
      expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    });

    testWidgets('"📺 Assistir" na página da setlist toca e abre assistindo', (tester) async {
      final m = await hub(tester);
      await tester.ensureVisible(find.byKey(const Key('setlist-s1')));
      await tester.tap(find.byKey(const Key('setlist-s1')));
      await _andar(tester);
      expect(find.byType(SetlistPage), findsOneWidget);
      expect(find.byKey(const Key('setlist-tocar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('setlist-assistir')));
      await _andar(tester);
      expect(m.ouvir.tocou!.fonte.id, 'setlist:s1');
      expect(find.byType(TocandoPage), findsOneWidget);
      expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('setlist vazia: os dois 📺 desabilitados', (tester) async {
      await montarOuvir(tester,
          banco: const BancoSetlists(porId: {'v': Setlist(id: 'v', nome: 'Vazia', criadoEm: 1, editadoEm: 1)}));
      await tester.tap(find.byKey(const Key('abrir')));
      await _andar(tester);
      expect(tester.widget<IconButton>(find.byKey(const Key('setlist-assistir-v'))).onPressed, isNull);
      await tester.tap(find.byKey(const Key('setlist-v')));
      await _andar(tester);
      expect(tester.widget<OutlinedButton>(find.byKey(const Key('setlist-assistir'))).onPressed, isNull);
    });
  });

  group('sem estouro', () {
    for (final (w, h) in [(360.0, 640.0), (390.0, 844.0), (1400.0, 900.0)]) {
      testWidgets('${w.toInt()}×${h.toInt()} com o 📺 ligado, na página e no ⛶, com a fonte grande', (tester) async {
        await _abrir(tester, prefLigada: true, tamanho: Size(w, h));
        tester.platformDispatcher.textScaleFactorTestValue = 1.6;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _andar(tester, vezes: 2);
        expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _telaCheia(tester);
        expect(find.byKey(const Key('assistir-barra')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('844×390 (celular deitado) no ⛶', (tester) async {
      await _abrir(tester, prefLigada: true, tamanho: const Size(844, 390));
      await _telaCheia(tester);
      expect(tester.getSize(find.byType(PalcoAssistir)).height, greaterThan(150));
      expect(tester.takeException(), isNull);
    });

    testWidgets('844×390 na página: o palco e o ⛶ dele cabem na tela; no ⛶ um só "sair" e a barra numa linha',
        (tester) async {
      await _abrir(tester, prefLigada: true, tamanho: const Size(844, 390));
      final palco = tester.getRect(find.byType(PalcoAssistir));
      expect(palco.bottom, lessThanOrEqualTo(390), reason: 'o palco inteiro na altura visível: $palco');
      expect(tester.getRect(find.byKey(const Key('assistir-tela-cheia'))).bottom, lessThanOrEqualTo(390));
      await _telaCheia(tester);
      expect(find.byKey(const Key('assistir-tela-cheia-layout')), findsOneWidget);
      expect(find.byKey(const Key('assistir-tela-cheia')), findsNothing, reason: 'a saída é a da barra');
      expect(find.byKey(const Key('assistir-sair-tela-cheia')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('assistir-barra'))).height, lessThan(64), reason: 'uma linha só');
      await tester.tap(find.byKey(const Key('chip-velocidade')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('o hub com o cartão do 📺 e o 📺 das setlists em 360 px', (tester) async {
      await montarOuvir(tester, banco: bancoComSetlist(), tamanho: const Size(360, 640));
      await tester.tap(find.byKey(const Key('abrir')));
      await _andar(tester);
      await tester.ensureVisible(find.byKey(const Key('ouvir-assistir-cartao')));
      await _andar(tester, vezes: 2);
      await tester.ensureVisible(find.byKey(const Key('setlist-assistir-s1')));
      await _andar(tester, vezes: 2);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const Key('setlist-s1')));
      await _andar(tester);
      expect(find.byKey(const Key('setlist-assistir')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
