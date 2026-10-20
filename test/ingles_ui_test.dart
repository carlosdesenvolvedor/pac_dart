import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/linguagem/linguagem_cubit.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/escolha_linguagem_page.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/curso/presentation/widgets/victory_overlay.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario_repository.dart';
import 'package:pac_dart/features/ingles/data/tradutor.dart';
import 'package:pac_dart/features/ingles/domain/audio_usuario.dart';
import 'package:pac_dart/features/ingles/domain/config_srs.dart';
import 'package:pac_dart/features/ingles/presentation/baralhos_page.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/traducao_card.dart';
import 'package:pac_dart/features/ingles/data/dicionario_ingles.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthFake implements AuthRepository {
  static const _user = AppUser(uid: 'teste-uid', email: 'teste@pac.dart');
  @override
  Stream<AppUser?> get mudancas => Stream.value(_user);
  @override
  AppUser? get atual => _user;
  @override
  Future<void> entrar(String email, String senha) async {}
  @override
  Future<void> cadastrar(String email, String senha) async {}
  @override
  Future<void> redefinirSenha(String email) async {}
  @override
  Future<void> sair() async {}
}

class _RankingFake implements RankingRepository {
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

/// Placar que só conta quantas vezes foi chamado.
class _RankingContando extends _RankingFake {
  int somas = 0;
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async => somas++;
}

/// Tradutor de mentira para o "transforme um texto em lição".
class _TradutorApp implements Tradutor {
  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir}) async {
    for (var i = 1; i <= frases.length; i++) {
      aoProgredir?.call(i, frases.length);
    }
    return [for (final f in frases) 'Tradução de: $f'];
  }
}

const _frases = [
  Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: '', alvo: "I'm"),
  Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: ''),
  Trecho(cod: 'Where are you from?', dica: 'De onde você é?', out: '', literal: 'Onde você é de?'),
];

final _trilhaEn = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: const [
    Licao(
        nome: 'Olá!',
        emoji: '🙋',
        imagem: '🏨🙋',
        visualizacao: 'Você chega à recepção do hotel e a Ana sorri para você.',
        trechos: _frases),
    Licao(nome: 'Como vai?', emoji: '😊', trechos: [Trecho(cod: 'How are you?', dica: 'Como você está?', out: '')]),
  ],
);

final _trilhaA2 = Trilha(
  nivel: 'Dia a dia',
  emoji: '🌿',
  etapa: 'A2 · Dia a dia',
  licoes: const [
    Licao(nome: 'Ontem', emoji: '🕰️', trechos: [Trecho(cod: 'I was tired.', dica: 'Eu estava cansado.', out: '')]),
  ],
);

/// Voz de mentira: anota o que falou e, com [segura], só "acaba" de falar
/// quando o teste mandar ([acabar]) — como a fala de verdade no navegador.
class _VozFake extends VozIngles {
  bool liberado = true;
  bool segura = false;
  final falas = <String>[];
  final _pendentes = <Completer<void>>[];

  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add(frase);
    if (!segura) return Future.value();
    final c = Completer<void>();
    _pendentes.add(c);
    return c.future;
  }

  void acabar() {
    for (final c in _pendentes) {
      if (!c.isCompleted) c.complete();
    }
    _pendentes.clear();
  }

  @override
  Future<void> parar() async => acabar();

  @override
  bool get somLiberado => liberado;
}

/// O ensaio sozinho (sem o app), no relógio falso do teste.
Future<void> _montarEnsaio(WidgetTester tester, Licao licao, _VozFake voz,
    {bool audioAuto = true, VoidCallback? onComecar}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: EnsaioMental(
      licao: licao,
      voz: voz,
      onComecar: onComecar ?? () {},
      onPular: () {},
      naoMostrarMais: false,
      onNaoMostrarMais: (_) {},
      audioAuto: audioAuto,
    ),
  ));
  await tester.pump();
}

class _LoaderEn extends CurriculoLoader {
  _LoaderEn() : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => [_trilhaEn, _trilhaA2];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

/// Dá tempo REAL (prefs, assets) até [alvo] aparecer ou ~4 s passarem.
Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 20 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

/// [ensaio]: o ensaio mental antes da lição (desligado nos testes que não
/// são dele — pref `en_ensaio`).
Future<void> _abrirApp(WidgetTester tester,
    {Linguagem? inicial,
    Map<String, Object> prefs = const {},
    bool ensaio = false,
    Tradutor Function()? tradutor,
    RankingRepository Function()? ranking,
    AudioUsuarioRepository Function(AppUser user)? audio,
    CurriculoLoader Function()? loaderEn}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: ensaio, ...prefs});
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: ranking ?? () => _RankingFake(),
      tradutorBuilder: tradutor,
      audioBuilder: audio,
      curriculoBuilder: (l) => l == Linguagem.ingles ? (loaderEn?.call() ?? _LoaderEn()) : CurriculoLoader(linguagem: l),
      linguagemInicial: inicial,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
}

/// O relógio do HUD redesenha todo segundo: pumpAndSettle nunca assenta.
/// O app nasce dentro de `runAsync` (zona real): os listeners dos blocs e os
/// timers do palco só andam com tempo REAL passando entre os pumps.
Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Digita [texto] no campo invisível da frase.
Future<void> _digita(WidgetTester tester, String texto) async {
  // a frase da tela de cima (a Revisão abre por cima do palco)
  await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, texto);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  await tester.pump();
}

/// Terminada a frase, ela fica na tela (a voz repete) até o Enter.
Future<void> _enter(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await _anda(tester, 3);
}

/// O campo invisível da frase está com o foco (as teclas vão para ela)?
bool _fraseComFoco(WidgetTester tester) => tester
    .widget<TextField>(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last)
    .focusNode!
    .hasFocus;

/// Anda o relógio do ensaio (tickers) em passos de 500 ms.
Future<void> _avancaEnsaio(WidgetTester tester, Duration quanto) async {
  for (var t = Duration.zero; t < quanto; t += const Duration(milliseconds: 500)) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// O curso é testado como no COMPUTADOR (teclado físico: Enter, Tab, Esc; texto
/// que chega junto vale tecla a tecla). O que é do celular — microfone, teclado
/// virtual, botão "Seguir" — está nos testes `celular…` e em ingles_fala_test.
void testWidgetsDesktop(String descricao, WidgetTesterCallback corpo) =>
    testWidgets(descricao, corpo, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

/// Reconhecedor de voz de mentira para os testes de tela cheia.
class _RecFake extends ReconhecedorFala {
  int iniciadas = 0;
  void Function(List<String>)? _final;
  void Function()? _fim;

  @override
  bool get suportado => true;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    iniciadas++;
    _final = aoFinal;
    _fim = aoFim;
    return _SessaoFake();
  }

  /// A pessoa disse [frase]: o reconhecedor entrega e fecha.
  void dizer(String frase) {
    _final?.call([frase]);
    _fim?.call();
  }
}

class _SessaoFake implements SessaoFala {
  @override
  void parar() {}
  @override
  void cancelar() {}
}

/// Digita [texto] como o Gboard: a palavra em composição, uma letra a mais por vez.
Future<void> _compoe(WidgetTester tester, String palavra) async {
  final campo = find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last;
  await tester.showKeyboard(campo);
  for (var i = 1; i <= palavra.length; i++) {
    final t = palavra.substring(0, i);
    tester.testTextInput.updateEditingValue(TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length), composing: TextRange(start: 0, end: t.length)));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
    await tester.pump();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    FraseView.carencia = Duration.zero;
  });
  tearDown(() {
    Linguagem.atual = Linguagem.dart;
    AudioUsuario.limpar();
  });

  testWidgetsDesktop('a escolha mostra os 3 cursos e a tecla 3 entra no inglês', (tester) async {
    await _abrirApp(tester);
    expect(find.byType(EscolhaLinguagemPage), findsOneWidget);
    expect(find.text('Estudar Inglês'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
    await _esperar(tester, find.byType(PalcoIngles));
    expect(find.byType(PalcoIngles), findsOneWidget);
    expect(Linguagem.atual, Linguagem.ingles);
    expect(find.text('INGLÊS'), findsOneWidget);
    // a tradução em cima, a frase embaixo
    expect(find.text('Oi, eu sou a Ana.'), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getString(LinguagemCubit.chaveDe('teste-uid')), 'ingles');
  });

  testWidgetsDesktop('a lição inteira: escada intercalada, prova, nota no mapa e frases na revisão', (tester) async {
    await _abrirApp(tester, inicial: Linguagem.ingles);
    await _esperar(tester, find.byType(PalcoIngles));
    final ctx = tester.element(find.byType(HomePage));
    final typing = ctx.read<TypingBloc>();
    final curso = ctx.read<CursoBloc>();
    final revisao = ctx.read<RevisaoCubit>();

    final digitadas = <String>[];
    for (var i = 0; i < 40 && !curso.state.vitoria; i++) {
      final frase = typing.state.chars.join();
      digitadas.add(frase);
      await _digita(tester, frase);
      await _anda(tester, 3);
      await _enter(tester);
    }
    expect(curso.state.vitoria, isTrue,
        reason: '${digitadas.length}: ${digitadas.join(' | ')} / idx=${typing.state.idx} '
            'concluido=${typing.state.concluido} erros=${typing.state.errosPorPosicao}');
    // 3 frases × 5 degraus, sem correção
    expect(digitadas.length, 15);
    for (var i = 1; i < digitadas.length; i++) {
      // com 3 frases o fim da fila ainda consegue intercalar quase tudo
      if (i < 12) expect(digitadas[i], isNot(digitadas[i - 1]), reason: digitadas.join(' | '));
    }
    expect(curso.state.licaoConcluida(0, 0), isTrue);
    expect(curso.state.quizNotas['0:0'], 10);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    expect(revisao.state.cartoes.length, 3);
    expect(revisao.state.cartoes.values.every((c) => c.revisoes == 1 && c.proximoDia == revisao.hoje + 1), isTrue);
    // a prova de cada frase foi limpa: nota "bom" no histórico do Anki
    final historico = await tester.runAsync(() => LocalRevisaoRepository().carregarHistorico());
    expect(historico!.length, 3);
    expect(historico.every((e) => e.nota == 3 && e.dia == revisao.hoje), isTrue);
    expect(find.text('LIÇÃO CONCLUÍDA!'), findsOneWidget);
    // sem o ensaio (desligado neste teste) a âncora não foi armada: nada do gesto
    expect(find.textContaining('Junte o polegar'), findsNothing);
  });

  testWidgetsDesktop('de memória: errar duas vezes revela a letra e a frase errada ganha cópia de correção', (tester) async {
    await _abrirApp(tester, inicial: Linguagem.ingles);
    await _esperar(tester, find.byType(PalcoIngles));
    final ctx = tester.element(find.byType(HomePage));
    final typing = ctx.read<TypingBloc>();

    // as 3 cópias (D1) e chega no 1º degrau de memória (iniciais da frase A)
    for (var i = 0; i < 3; i++) {
      await _digita(tester, typing.state.chars.join());
      await _anda(tester, 3);
      await _enter(tester);
    }
    expect(find.textContaining('Iniciais'), findsOneWidget);
    final alvo = typing.state.chars.join();
    // 3 palavras quase inteiras erradas: "Hi" com 2 erros, "I'm" com 2, "Ana" com 2
    for (final ch in ['x', 'x', 'H', 'i', ',', ' ', 'z', 'z', 'I', "'", 'm', ' ', 'q', 'q', 'A', 'n', 'a', '.']) {
      await _digita(tester, ch);
    }
    expect(typing.state.concluido, isTrue);
    await _enter(tester);
    expect(typing.state.chars.join(), alvo);
    expect(find.textContaining('Correção'), findsOneWidget);
  });

  testWidgetsDesktop('terminada a frase, ela fica na tela até o Enter (dá para ouvir)', (tester) async {
    await _abrirApp(tester, inicial: Linguagem.ingles);
    await _esperar(tester, find.byType(PalcoIngles));
    final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
    final primeira = typing.state.chars.join();
    await _digita(tester, primeira);
    await _anda(tester, 3);
    // tempo real passando: nada de avançar sozinho
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 900)));
    await _anda(tester, 3);
    expect(typing.state.chars.join(), primeira);
    expect(typing.state.concluido, isTrue);
    expect(find.text('Enter segue →'), findsOneWidget);
    await _enter(tester);
    expect(typing.state.chars.join(), isNot(primeira));
    expect(typing.state.concluido, isFalse);
  });

  testWidgetsDesktop('👁 ligado: o inglês fica à vista em todas as frases, fica salvo e a lição termina', (tester) async {
    await _abrirApp(tester, inicial: Linguagem.ingles);
    await _esperar(tester, find.byType(PalcoIngles));
    final ctx = tester.element(find.byType(HomePage));
    final typing = ctx.read<TypingBloc>();
    final curso = ctx.read<CursoBloc>();
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await _anda(tester, 3);
    expect(find.byIcon(Icons.visibility_rounded), findsOneWidget);
    final p = await SharedPreferences.getInstance();
    expect(p.getBool('en_ver_frases'), isTrue);

    var degrausDeMemoria = 0;
    for (var i = 0; i < 40 && !curso.state.vitoria; i++) {
      final frase = typing.state.chars.join();
      final fv = tester.widget<FraseView>(find.byType(FraseView));
      expect(fv.mostrarTudo, isTrue);
      if (fv.modo.deMemoria) degrausDeMemoria++;
      // com a frase à vista toda digitação conta como cópia: sem correção
      await _digita(tester, frase);
      await _anda(tester, 3);
      await _enter(tester);
    }
    expect(curso.state.vitoria, isTrue);
    expect(degrausDeMemoria, 12); // D2–D5 das 3 frases, todos com a frase à vista
    // à vista não é de memória: a prova vale meio ponto
    expect(curso.state.quizNotas['0:0'], 5);
  });

  testWidgetsDesktop('Revisão do dia: só a tradução; acertar de memória alonga o intervalo (cartão do formato ANTIGO migra)', (tester) async {
    final hoje = Revisao.dia(DateTime.now());
    // um cartão no formato antigo (caixa de Leitner), vencido, e um que só vence daqui a 5 dias
    final cartoes = {
      Revisao.chave('Nice to meet you.'): const CartaoRevisao(caixa: 2, proximoDia: 0).codificar(),
      Revisao.chave('How are you?'): CartaoRevisao(caixa: 1, proximoDia: hoje + 5).codificar(),
    };
    await _abrirApp(tester, inicial: Linguagem.ingles, prefs: {'en_revisao': jsonEncode(cartoes)});
    await _esperar(tester, find.text('Revisão · 1'));
    expect(find.text('Revisão · 1'), findsOneWidget);

    final revisao = tester.element(find.byType(HomePage)).read<RevisaoCubit>();
    await tester.tap(find.text('Revisão · 1'));
    await _anda(tester, 8);
    expect(find.byType(SessaoMemoriaPage), findsOneWidget);
    expect(find.text('Prazer em te conhecer.'), findsOneWidget);
    await _digita(tester, 'Nice to meet you');
    await _anda(tester, 3);
    // o resultado vale ao avançar (dá tempo de "foi erro de digitação")
    await _enter(tester);
    final c = revisao.state.cartoes[Revisao.chave('Nice to meet you.')]!;
    expect(c.revisoes, 3, reason: 'a caixa 2 antiga contava 2 revisões; esta é a 3ª');
    expect(c.ultimoDia, hoje);
    expect(c.estabilidade, greaterThan(3), reason: 'acertou: a memória ficou mais estável que os 3 dias da caixa 2');
    expect(c.proximoDia, greaterThan(hoje + 3), reason: 'e volta bem mais tarde que antes');
    expect(c.lapsos, 0);
    // a outra frase não foi tocada
    expect(revisao.state.cartoes[Revisao.chave('How are you?')]!.proximoDia, hoje + 5);
    final historico = await tester.runAsync(() => LocalRevisaoRepository().carregarHistorico());
    expect(historico!.map((e) => (e.dia, e.nota)), [(hoje, 3)]);
  });

  testWidgetsDesktop('redimensionar a janela no meio da lição (painel do tutor entra/sai) não zera a fila', (tester) async {
    await _abrirApp(tester, inicial: Linguagem.ingles);
    await _esperar(tester, find.byType(PalcoIngles));
    final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
    for (var i = 0; i < 2; i++) {
      await _digita(tester, typing.state.chars.join());
      await _anda(tester, 3);
      await _enter(tester);
    }
    expect(find.textContaining('2 / '), findsOneWidget);
    // 1400 → 1000 px: o painel do Prof. Dash vira botão flutuante
    tester.view.physicalSize = const Size(1000, 2000);
    await _anda(tester, 3);
    expect(find.textContaining('2 / '), findsOneWidget);
    expect(typing.state.chars.join(), 'Where are you from?');
  });

  testWidgetsDesktop('teste de nivelamento: acertou de memória, a trilha fica concluída e as frases vão pra caixa 3', (tester) async {
    await _abrirApp(tester, inicial: Linguagem.ingles);
    await _esperar(tester, find.byType(PalcoIngles));
    final home = tester.element(find.byType(HomePage));
    final curso = home.read<CursoBloc>();
    final revisao = home.read<RevisaoCubit>();

    await tester.tap(find.text('Mapa'));
    await _anda(tester, 8);
    await tester.ensureVisible(find.text('Já sei esta trilha').first);
    await tester.tap(find.text('Já sei esta trilha').first);
    await _anda(tester, 8);
    expect(find.byType(SessaoMemoriaPage), findsOneWidget);
    // 4 frases na trilha de teste: digita cada uma que aparecer
    final porPt = {for (final l in _trilhaEn.licoes) for (final f in l.trechos) f.dica: f.cod};
    String? visivel() {
      // só na página da sessão (na transição o palco por trás ainda aparece)
      for (final k in porPt.keys) {
        if (find.descendant(of: find.byType(SessaoMemoriaPage), matching: find.text(k)).evaluate().isNotEmpty) return k;
      }
      return null;
    }

    final feitas = <String>{};
    for (var tentativa = 0; tentativa < 80 && find.textContaining('Passou!').evaluate().isEmpty; tentativa++) {
      final pt = visivel();
      if (pt != null && !feitas.contains(pt)) {
        feitas.add(pt);
        await _digita(tester, porPt[pt]!);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter); // terminada, só segue no Enter
      }
      // a página nasceu na zona falsa (o toque): o bloc dela anda com
      // microtarefas — alterna tempo real e falso
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(feitas.length, 4);
    expect(find.textContaining('Passou!'), findsOneWidget);
    expect(curso.state.licaoConcluida(0, 0), isTrue);
    expect(curso.state.licaoConcluida(0, 1), isTrue);
    expect(revisao.state.cartoes.length, 4);
    expect(revisao.state.cartoes.values.every((c) => c.proximoDia == revisao.hoje + 7 && c.revisoes == 1), isTrue,
        reason: 'frases de trilha testada voltam em 1 semana');
  });

  testWidgetsDesktop('nivelamento: passou no portão do A2, o A1 inteiro fica testado e a lição atual vai para o A2', (tester) async {
    await _abrirApp(tester, inicial: Linguagem.ingles);
    await _esperar(tester, find.byType(PalcoIngles));
    final home = tester.element(find.byType(HomePage));
    final curso = home.read<CursoBloc>();
    expect(find.textContaining('Já sabe algum inglês?'), findsOneWidget);

    await tester.tap(find.text('Nivelar →'));
    await _anda(tester, 8);
    expect(find.textContaining('portão do A2'), findsOneWidget);
    final porPt = {for (final l in _trilhaEn.licoes) for (final f in l.trechos) f.dica: f.cod};
    final feitas = <String>{};
    for (var i = 0; i < 80 && find.textContaining('liberado').evaluate().isEmpty; i++) {
      for (final k in porPt.keys) {
        final f = find.descendant(of: find.byType(SessaoMemoriaPage), matching: find.text(k));
        if (f.evaluate().isNotEmpty && feitas.add(k)) {
          await _digita(tester, porPt[k]!);
          await tester.pump(const Duration(milliseconds: 50));
          await tester.sendKeyEvent(LogicalKeyboardKey.enter); // terminada, só segue no Enter
        }
      }
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 400));
    }
    expect(find.textContaining('liberado'), findsOneWidget);
    await tester.tap(find.text('Continuar →'));
    await _anda(tester, 8);
    expect(curso.state.licaoConcluida(0, 0), isTrue);
    expect(curso.state.licaoConcluida(0, 1), isTrue);
    expect(curso.state.trilhaIdx, 1);
  });

  group('ensaio mental antes da lição', () {
    testWidgetsDesktop('aparece no começo, segura o teclado, anda sozinho, espera o Enter e a 1ª frase recebe o foco',
        (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true);
      await _esperar(tester, find.byType(EnsaioMental));
      expect(find.byType(EnsaioMental), findsOneWidget);
      expect(find.text('Lembre de uma conversa em que você se saiu bem.'), findsOneWidget);
      final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();

      // nada chega à frase enquanto o ensaio está aberto
      expect(_fraseComFoco(tester), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await _anda(tester, 2);
      expect(typing.state.idx, 0);
      expect(find.byType(EnsaioMental), findsOneWidget);

      // passo 2: a cena (visualização em tela cheia)
      await _avancaEnsaio(tester, const Duration(seconds: 9));
      expect(find.text('Você chega à recepção do hotel e a Ana sorri para você.'), findsWidgets);
      // passo 3: o ensaio do futuro, com a frase-chave (a que tem alvo)
      await _avancaEnsaio(tester, const Duration(seconds: 6));
      expect(find.text('Daqui a pouco, nessa cena, você vai dizer:'), findsOneWidget);
      expect(find.textContaining('Oi, eu sou a Ana.', findRichText: true), findsWidgets);
      // fim do roteiro: fica parado esperando o Enter
      await _avancaEnsaio(tester, const Duration(seconds: 12));
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
      expect(find.byType(EnsaioMental), findsOneWidget);

      await _enter(tester);
      expect(find.byType(EnsaioMental), findsNothing);
      expect(_fraseComFoco(tester), isTrue);
      final primeira = typing.state.chars.join();
      await _digita(tester, primeira);
      await _anda(tester, 3);
      expect(typing.state.concluido, isTrue);
    });

    testWidgetsDesktop('a âncora volta na vitória abaixo do título (sem cobri-lo) e, ao repetir, sem "novas"',
        (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true);
      await _esperar(tester, find.byType(EnsaioMental));
      // passa do pico da respiração (o sino da âncora) e pula o resto
      await _avancaEnsaio(tester, const Duration(seconds: 5));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _anda(tester, 3);
      final ctx = tester.element(find.byType(HomePage));
      final typing = ctx.read<TypingBloc>();
      final curso = ctx.read<CursoBloc>();

      Future<void> fazerLicao() async {
        for (var i = 0; i < 40 && !curso.state.vitoria; i++) {
          await _digita(tester, typing.state.chars.join());
          await _anda(tester, 3);
          await _enter(tester);
        }
        expect(curso.state.vitoria, isTrue);
      }

      await fazerLicao();
      final linha = find.text('👌 Junte o polegar e o indicador: você acabou de usar 3 frases novas em inglês.');
      expect(linha, findsOneWidget);
      // no fluxo do placar: abaixo do título, sem sobrepor, e os botões cabem no palco
      final titulo = tester.getRect(find.text('LIÇÃO CONCLUÍDA!'));
      expect(tester.getRect(linha).top, greaterThanOrEqualTo(titulo.bottom));
      expect(find.descendant(of: find.byType(VictoryOverlay), matching: linha), findsOneWidget);
      final palco = tester.getRect(find.byType(PalcoIngles));
      expect(tester.getRect(find.text('Repetir')).bottom, lessThanOrEqualTo(palco.bottom));

      // repetir: as mesmas frases já não são "novas"
      await tester.tap(find.text('Repetir'));
      await _anda(tester, 3);
      expect(curso.state.vitoria, isFalse);
      await fazerLicao();
      expect(find.text('👌 Junte o polegar e o indicador: você acabou de usar 3 frases em inglês.'), findsOneWidget);
    });

    testWidgetsDesktop('frase longa: a voz da próxima frase espera a anterior acabar (nada é cortado)', (tester) async {
      const longa = "I got an offer from another company, but I haven't accepted it yet.";
      const licao = Licao(nome: 'Proposta', emoji: '💼', trechos: [
        Trecho(cod: longa, dica: 'Recebi uma proposta de outra empresa, mas ainda não aceitei.', out: '', alvo: 'yet'),
        Trecho(cod: 'I need some time.', dica: 'Preciso de um tempo.', out: '', alvo: 'some time'),
      ]);
      // a conta já dá à frase longa (13 palavras, voz devagar) bem mais que o mínimo
      final segLonga = EnsaioMental.segDaFrase(longa, lenta: true);
      expect(segLonga, greaterThan(EnsaioMental.segRevelaIngles + 13 * .4));
      // frase curta fica o mínimo
      expect(EnsaioMental.segDaFrase('Hi there.', lenta: true), EnsaioMental.segFrase);
      expect(EnsaioMental.segDaFrase(longa, lenta: false), lessThan(segLonga));

      final voz = _VozFake()..segura = true;
      await _montarEnsaio(tester, licao, voz);
      // sem cena: respiração (8 s) e o futuro; a 1ª voz sai quando o inglês aparece
      await _avancaEnsaio(tester, const Duration(milliseconds: 9500));
      expect(voz.falas, [longa]);
      // a frase 2 só entraria depois do tempo dela — e a voz da 1ª ainda não acabou:
      // o relógio para e espera (a 2ª não corta a 1ª)
      await _avancaEnsaio(tester, Duration(milliseconds: (segLonga * 1000).round() + 4000));
      expect(voz.falas, [longa]);
      expect(find.text('Você já se viu dizendo isso.'), findsNothing);
      // a voz acabou: o roteiro segue e a 2ª frase fala
      voz.acabar();
      await tester.pump();
      await _avancaEnsaio(tester, const Duration(milliseconds: 1500));
      expect(voz.falas, [longa, 'I need some time.']);
      voz.acabar();
      await _avancaEnsaio(tester, const Duration(seconds: 4));
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
    });

    testWidgetsDesktop('o ensaio passa TODAS as frases da lição (não só 3) e o fim mostra todas', (tester) async {
      final licao = Licao(nome: 'Dez', emoji: '🔟', trechos: [
        for (var i = 1; i <= 10; i++) Trecho(cod: 'Phrase number $i.', dica: 'Frase número $i.', out: ''),
      ]);
      expect(EnsaioMental.frasesDoEnsaio(licao), hasLength(10));
      final voz = _VozFake();
      await _montarEnsaio(tester, licao, voz);
      await _avancaEnsaio(tester, const Duration(milliseconds: 9500));
      expect(find.text('frase 1 de 10'), findsOneWidget);
      await _avancaEnsaio(tester, const Duration(seconds: 50));
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
      expect(voz.falas, [for (var i = 1; i <= 10; i++) 'Phrase number $i.']);
      for (var i = 1; i <= 10; i++) {
        expect(find.textContaining('Frase número $i.', findRichText: true), findsOneWidget);
      }
    });

    testWidgetsDesktop('"áudio automático" desligado: o ensaio não fala sozinho, o 🔊 continua falando', (tester) async {
      final voz = _VozFake();
      await _montarEnsaio(tester, _trilhaEn.licoes.first, voz, audioAuto: false);
      await _avancaEnsaio(tester, const Duration(seconds: 30));
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
      expect(voz.falas, isEmpty);
      await tester.tap(find.byTooltip('ouvir').first);
      await tester.pump();
      expect(voz.falas, ["Hi, I'm Ana."]);
    });

    testWidgetsDesktop('página sem gesto ainda (app recém-aberto): espera o "Começar o ensaio" antes de tocar', (tester) async {
      final voz = _VozFake()..liberado = false;
      var comecou = 0;
      await _montarEnsaio(tester, _trilhaEn.licoes.first, voz, onComecar: () => comecou++);
      expect(find.text('Começar o ensaio  ↵'), findsOneWidget);
      // parado: o tempo passa e nada anda nem fala (o navegador deixaria mudo)
      await _avancaEnsaio(tester, const Duration(seconds: 20));
      expect(find.text('Começar o ensaio  ↵'), findsOneWidget);
      expect(find.text('Lembre de uma conversa em que você se saiu bem.'), findsNothing);
      expect(voz.falas, isEmpty);
      // o Enter é o gesto: começa o ENSAIO (não a lição)
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(comecou, 0);
      await _avancaEnsaio(tester, const Duration(seconds: 1));
      expect(find.text('Lembre de uma conversa em que você se saiu bem.'), findsOneWidget);
      await _avancaEnsaio(tester, const Duration(seconds: 30));
      expect(voz.falas, _frases.map((f) => f.cod).toList());
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
      // agora o Enter começa a lição
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(comecou, 1);
    });

    testWidgetsDesktop('Enter no meio do roteiro já começa a lição', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true);
      await _esperar(tester, find.byType(EnsaioMental));
      await _avancaEnsaio(tester, const Duration(seconds: 2));
      await _enter(tester);
      expect(find.byType(EnsaioMental), findsNothing);
      expect(_fraseComFoco(tester), isTrue);
    });

    testWidgetsDesktop('Esc pula o ensaio sem virar "não sei" na frase', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true);
      await _esperar(tester, find.byType(EnsaioMental));
      final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _anda(tester, 3);
      expect(find.byType(EnsaioMental), findsNothing);
      expect(_fraseComFoco(tester), isTrue);
      expect(typing.state.idx, 0);
      expect(typing.state.concluido, isFalse);
      expect(find.textContaining('0 / '), findsOneWidget);
    });

    testWidgetsDesktop('"não mostrar mais" grava a pref, a próxima lição começa sem ensaio e o link religa', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true);
      await _esperar(tester, find.byType(EnsaioMental));
      final curso = tester.element(find.byType(HomePage)).read<CursoBloc>();
      await tester.tap(find.text('não mostrar mais antes das lições'));
      await _anda(tester, 3);
      final p = await SharedPreferences.getInstance();
      expect(p.getBool(EnsaioMental.prefLigado), isFalse);
      await _enter(tester);
      expect(find.byType(EnsaioMental), findsNothing);

      curso.add(const LicaoSelecionada(1));
      await _anda(tester, 6);
      expect(curso.state.licaoIdx, 1);
      expect(find.byType(EnsaioMental), findsNothing);
      expect(_fraseComFoco(tester), isTrue);

      // o link do palco abre o ensaio sob demanda; desmarcar a caixinha religa
      await tester.tap(find.textContaining('desligado', findRichText: true));
      await _anda(tester, 3);
      expect(find.byType(EnsaioMental), findsOneWidget);
      await tester.tap(find.text('não mostrar mais antes das lições'));
      await _anda(tester, 3);
      expect(p.getBool(EnsaioMental.prefLigado), isTrue);
      await tester.tap(find.text('Pular · Esc'));
      await _anda(tester, 3);
      expect(find.byType(EnsaioMental), findsNothing);
      expect(_fraseComFoco(tester), isTrue);
    });

    testWidgetsDesktop('a lição muda com outra tela por cima: o ensaio abre por baixo sem roubar o teclado dela',
        (tester) async {
      final cartoes = {Revisao.chave('Nice to meet you.'): const CartaoRevisao(caixa: 2, proximoDia: 0).codificar()};
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true, prefs: {'en_revisao': jsonEncode(cartoes)});
      await _esperar(tester, find.byType(EnsaioMental));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _anda(tester, 3);
      final curso = tester.element(find.byType(HomePage)).read<CursoBloc>();

      await tester.tap(find.text('Revisão · 1'));
      await _anda(tester, 8);
      expect(find.byType(SessaoMemoriaPage), findsOneWidget);
      final campoRevisao = find.descendant(of: find.byType(SessaoMemoriaPage), matching: find.byType(TextField));
      expect(tester.widget<TextField>(campoRevisao.last).focusNode!.hasFocus, isTrue);

      curso.add(const LicaoSelecionada(1));
      await _anda(tester, 6);
      expect(curso.state.licaoIdx, 1);
      expect(find.byType(EnsaioMental, skipOffstage: false), findsOneWidget);
      expect(tester.widget<TextField>(campoRevisao.last).focusNode!.hasFocus, isTrue);

      // fechou a revisão: o teclado vai para o ensaio (Enter começa a lição)
      Navigator.of(tester.element(find.byType(SessaoMemoriaPage))).pop();
      // a transição da rota anda no relógio falso (a página nasceu de um toque)
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 400));
      }
      await _anda(tester, 3);
      expect(find.byType(SessaoMemoriaPage), findsNothing);
      expect(find.byType(EnsaioMental), findsOneWidget);
      await _enter(tester);
      expect(find.byType(EnsaioMental), findsNothing);
      expect(_fraseComFoco(tester), isTrue);
    });

    testWidgetsDesktop('celular estreito sem estouro e, fechado, não volta ao redimensionar', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true);
      await _esperar(tester, find.byType(EnsaioMental));
      // celular: 390 px
      tester.view.physicalSize = const Size(390, 800);
      await _anda(tester, 3);
      // o HUD de trás (fora desta frente) estoura com a fonte de teste, que é
      // mais larga: descarta esse aviso e cobra só o ensaio daqui em diante
      tester.takeException();
      for (final s in [3, 7, 8, 12]) {
        await _avancaEnsaio(tester, Duration(seconds: s));
        expect(tester.takeException(), isNull);
      }
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
      await tester.tap(find.text('Começar a lição  ↵'));
      await _anda(tester, 3);
      expect(find.byType(EnsaioMental), findsNothing);

      for (final tamanho in [const Size(1000, 2000), const Size(1400, 2000), const Size(390, 800)]) {
        tester.view.physicalSize = tamanho;
        await _anda(tester, 3);
        expect(find.byType(EnsaioMental), findsNothing);
      }
      expect(_fraseComFoco(tester), isTrue);
    });
  });

  group('no celular (Android)', () {
    // o celular é a plataforma padrão do flutter_test: sem variante
    setUp(() => FraseView.carencia = Duration.zero);

    testWidgets('a palavra em composição já anda no Pac-Man, o botão é "Seguir" e nada estoura em 430 px',
        (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles);
      tester.view.physicalSize = const Size(430, 2000);
      await _esperar(tester, find.byType(PalcoIngles));
      await _anda(tester, 3);
      final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
      final primeira = typing.state.chars.join();

      await _compoe(tester, primeira.substring(0, 2));
      expect(typing.state.idx, 2, reason: 'as letras em composição já foram comidas');

      // a pessoa apaga o que compôs e dita a frase inteira pelo 🎤 do teclado:
      // vale como resposta falada
      tester.testTextInput.updateEditingValue(const TextEditingValue());
      await tester.pump();
      await _digita(tester, primeira);
      await _anda(tester, 3);
      expect(typing.state.concluido, isTrue);
      expect(find.text('Seguir'), findsOneWidget);
      expect(find.text('Enter segue →'), findsNothing);
      await tester.tap(find.text('Seguir'));
      await _anda(tester, 3);
      expect(typing.state.chars.join(), isNot(primeira));
      expect(typing.state.concluido, isFalse);
    });

    testWidgets('de memória, falar errado conta como erro e a frase volta para correção', (tester) async {
      final rec = _RecFake();
      FraseView.fabricaReconhecedor = () => rec;
      addTearDown(() => FraseView.fabricaReconhecedor = ReconhecedorFala.navegador);
      await _abrirApp(tester, inicial: Linguagem.ingles);
      tester.view.physicalSize = const Size(430, 2000);
      await _esperar(tester, find.byType(PalcoIngles));
      final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
      // as 3 cópias da 1ª frase (D1) até o degrau das iniciais
      for (var i = 0; i < 3; i++) {
        await _digita(tester, typing.state.chars.join());
        await _anda(tester, 3);
        await tester.tap(find.text('Seguir'));
        await _anda(tester, 3);
      }
      expect(find.textContaining('Iniciais'), findsOneWidget);
      final alvo = typing.state.chars.join();

      await tester.tap(find.byIcon(Icons.mic_rounded));
      await _anda(tester, 2);
      expect(rec.iniciadas, 1);
      rec.dizer("hi I'm Mary"); // "Ana" não saiu (Anna valeria: o nome confere pelo som)
      await _anda(tester, 3);
      expect(typing.state.concluido, isFalse);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await _anda(tester, 2);
      rec.dizer("hi I'm Ana");
      await _anda(tester, 3);
      expect(typing.state.concluido, isTrue);
      expect(find.textContaining('Vamos corrigir'), findsOneWidget, reason: 'a tentativa errada pesa como tecla errada');
      await tester.tap(find.text('Seguir'));
      await _anda(tester, 3);
      expect(typing.state.chars.join(), alvo);
      expect(find.textContaining('Correção'), findsOneWidget);
    });

    testWidgets('o teclado sobe e a frase não fica escondida embaixo dele (a tela rola até ela)', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles);
      tester.view.physicalSize = const Size(430, 900);
      await _esperar(tester, find.byType(PalcoIngles));
      await _anda(tester, 3);
      final frase = find.byType(FraseView);
      // sem teclado a frase pode estar fora da janela (a página rola); leva até lá
      await tester.ensureVisible(frase);
      await _anda(tester, 3);
      // o teclado ocupa a parte de baixo
      tester.view.viewInsets = const FakeViewPadding(bottom: 480);
      addTearDown(tester.view.resetViewInsets);
      await _anda(tester, 12);
      final base = tester.getRect(find.byType(FraseView)).bottom;
      expect(base, lessThanOrEqualTo(900 - 480 + 1), reason: 'a frase fica acima do teclado');
      // e a tradução, que é o que se lê para digitar, continua à vista (o cartão encolhe)
      expect(tester.getRect(find.byType(TraducaoCard)).top, greaterThanOrEqualTo(0));
      expect(find.byType(TraducaoCard), findsOneWidget);
      expect(find.text('áudio automático'), findsNothing, reason: 'as caixinhas voltam quando o teclado fecha');
      tester.view.resetViewInsets();
      await _anda(tester, 4);
      expect(find.text('áudio automático'), findsOneWidget);
    });
  });

  group('lição feita de texto colado', () {
    /// Digita o que o palco pedir até a vitória (a lição inteira).
    Future<void> terminarLicao(WidgetTester tester) async {
      final ctx = tester.element(find.byType(HomePage));
      final typing = ctx.read<TypingBloc>();
      final curso = ctx.read<CursoBloc>();
      for (var i = 0; i < 60 && !curso.state.vitoria; i++) {
        await _digita(tester, typing.state.chars.join());
        await _anda(tester, 3);
        await _enter(tester);
      }
    }

    testWidgetsDesktop('mapa → cola o texto → traduz → corrige → cria e já cai na lição, sem pontuar no ranking', (tester) async {
      final placar = _RankingContando();
      await _abrirApp(tester, inicial: Linguagem.ingles, tradutor: () => _TradutorApp(), ranking: () => placar);
      await _esperar(tester, find.byType(PalcoIngles));
      final home = tester.element(find.byType(HomePage));
      final curso = home.read<CursoBloc>();
      expect(curso.state.trilhas.length, 2);

      await tester.tap(find.text('Mapa'));
      await _anda(tester, 8);
      expect(find.text('Meus textos'), findsNothing, reason: 'sem textos ainda, a faixa nem aparece');
      await tester.ensureVisible(find.byKey(const Key('novo-texto')));
      await tester.tap(find.byKey(const Key('novo-texto')));
      await _anda(tester, 8);

      await tester.enterText(find.byKey(const Key('titulo-texto')), 'Minha viagem');
      await tester.enterText(find.byKey(const Key('texto-colado')), 'We went to Rome. It was great!');
      await tester.pump();
      expect(find.text('2 frases · 1 lição'), findsOneWidget);
      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await _anda(tester, 6);
      expect(find.text('Tradução de: We went to Rome.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pt-0')), 'Fomos a Roma.');
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao-criar')));
      await _esperar(tester, find.text('Fomos a Roma.'));
      await _anda(tester, 6);

      // fechou a tela e o mapa: está no palco, na 1ª parte do texto novo
      expect(curso.state.trilha.propria, isTrue);
      expect(curso.state.trilha.nivel, 'Minha viagem');
      expect(curso.state.licao.id.startsWith('txt-'), isTrue);
      expect(find.byType(PalcoIngles), findsOneWidget);
      expect(find.text('Fomos a Roma.'), findsWidgets, reason: 'a tradução (corrigida) fica em cima');
      final p = await tester.runAsync(SharedPreferences.getInstance);
      expect(p!.getString('en_textos_teste-uid'), contains('Fomos a Roma.'));

      // digita a lição inteira: 2 frases × 5 degraus
      await terminarLicao(tester);
      expect(curso.state.vitoria, isTrue);
      expect(curso.state.concluidas, contains(curso.state.licao.id));
      expect(curso.state.progressoDoCurso, (3, 0), reason: 'texto próprio não conta no curso');
      expect(placar.somas, 0, reason: 'texto próprio não pontua no ranking');

      // as frases entram na revisão espaçada como as do curso
      final revisao = home.read<RevisaoCubit>();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(revisao.state.cartoes.length, 2);

      // no mapa: a faixa "Meus textos" no topo, a trilha dele e o botão de apagar
      await tester.pump();
      await tester.tap(find.text('Mapa'));
      await _anda(tester, 8);
      expect(find.text('MEUS TEXTOS'), findsOneWidget);
      expect(find.text('Minha viagem'), findsWidgets);
      expect(find.byTooltip('Apagar este texto'), findsOneWidget);
    });

    testWidgetsDesktop('controle: a lição do curso pontua no ranking (o teste acima só vale se isto vale)', (tester) async {
      final placar = _RankingContando();
      await _abrirApp(tester, inicial: Linguagem.ingles, ranking: () => placar);
      await _esperar(tester, find.byType(PalcoIngles));
      await terminarLicao(tester);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect(placar.somas, 1);
    });

    testWidgetsDesktop('texto salvo volta no próximo acesso e apagar tira a trilha (com confirmação)', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, prefs: {
        'en_textos_teste-uid': jsonEncode([
          {
            'id': 'k1',
            'titulo': 'Carta',
            'criadoEm': 5000,
            'frases': [
              {'en': 'Dear John.', 'pt': 'Caro John.'},
              {'en': 'I miss you.', 'pt': 'Sinto sua falta.'},
            ],
          }
        ]),
      });
      await _esperar(tester, find.byType(PalcoIngles));
      final home = tester.element(find.byType(HomePage));
      final curso = home.read<CursoBloc>();
      expect(curso.state.trilhas.map((t) => t.nivel), ['Primeiros Passos', 'Dia a dia', 'Carta']);
      expect(curso.state.trilha.propria, isFalse, reason: 'abre no curso, não no texto');

      await tester.tap(find.text('Mapa'));
      await _anda(tester, 8);
      await tester.ensureVisible(find.byTooltip('Apagar este texto'));
      await tester.tap(find.byTooltip('Apagar este texto'));
      await _anda(tester, 4);
      expect(find.text('Apagar "Carta"?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _anda(tester, 4);
      expect(curso.state.trilhas.length, 3);

      await tester.tap(find.byTooltip('Apagar este texto'));
      await _anda(tester, 4);
      await tester.tap(find.text('Apagar'));
      await _anda(tester, 6);
      expect(curso.state.trilhas.length, 2);
      final p = await tester.runAsync(SharedPreferences.getInstance);
      expect(jsonDecode(p!.getString('en_textos_teste-uid')!), isEmpty);
    });
  });

  group('Anki: cartões de inglês → português na revisão', () {
    // o baralho de teste não tem id de lição: o id do baralho cai no nome da trilha
    final reversos = ConfigSrs(reversos: {'tr:Primeiros Passos'}).codificar();

    /// Vira o cartão da vez e dá a nota [chave] (Key do botão).
    Future<void> avalia(WidgetTester tester, String chave) async {
      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await _anda(tester, 2);
      await tester.tap(find.byKey(Key(chave)));
      await _anda(tester, 3);
    }

    testWidgetsDesktop('digita os que vencem e DEPOIS vira os cartões novos; a nota cria o cartão no motor e vai ao histórico',
        (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, prefs: {'en_cartao_escrita': false, 'en_cartao_sentido': 'en-pt', 
        'en_srs_cfg': reversos,
        // um cartão digitado vencido (formato ANTIGO: migra) para abrir a 1ª sessão
        'en_revisao': jsonEncode({Revisao.chave('Nice to meet you.'): const CartaoRevisao(caixa: 2, proximoDia: 0).codificar()}),
      });
      await _esperar(tester, find.text('Revisão · 1'));
      final revisao = tester.element(find.byType(HomePage)).read<RevisaoCubit>();
      expect(revisao.state.config.reversoLigado('tr:Primeiros Passos'), isTrue, reason: 'os ajustes voltaram');

      await tester.tap(find.text('Revisão · 1'));
      await _anda(tester, 8);
      expect(find.byType(SessaoMemoriaPage), findsOneWidget);
      expect(find.byType(SessaoCartoesPage), findsNothing, reason: 'primeiro os digitados');
      await _digita(tester, 'Nice to meet you');
      await _anda(tester, 3);
      await _enter(tester);
      expect(find.textContaining('Continuar'), findsOneWidget);
      await tester.tap(find.textContaining('Continuar'));
      await _anda(tester, 8);

      // agora os cartões inglês → português: as 4 frases do baralho, todas novas
      expect(find.byType(SessaoCartoesPage), findsOneWidget);
      expect(find.text('Cartões · inglês → português'), findsOneWidget);
      expect(find.text('4 cartões · 4 novos'), findsOneWidget);
      expect(find.text('NOVO'), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsNothing, reason: 'o verso começa escondido');
      await avalia(tester, 'nota-facil'); // Hi, I'm Ana. (a 1ª)

      final chave = Revisao.chaveReversa(Revisao.chave("Hi, I'm Ana."));
      final c = revisao.state.cartoes[chave]!;
      expect(c.revisoes, 1);
      expect(c.proximoDia - revisao.hoje, greaterThan(10), reason: '"fácil" na 1ª vez já volta daqui a semanas');
      final historico = await tester.runAsync(() => LocalRevisaoRepository().carregarHistorico());
      expect(historico!.any((e) => e.chave == chave && e.nota == 4 && e.primeira), isTrue);
      // o cartão digitado continuou no motor dele (3ª revisão, na caixa migrada)
      expect(revisao.state.cartoes[Revisao.chave('Nice to meet you.')]!.revisoes, 3);
    });

    testWidgetsDesktop('sem nada digitado vencendo, "Revisão" vai direto aos cartões de virar; a cota de novos por dia vale',
        (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, prefs: {'en_cartao_escrita': false, 'en_cartao_sentido': 'en-pt', 'en_srs_cfg': ConfigSrs(novosPorDia: 2, reversos: {'tr:Primeiros Passos'}).codificar()});
      await _esperar(tester, find.text('Revisão'));
      final revisao = tester.element(find.byType(HomePage)).read<RevisaoCubit>();
      await tester.tap(find.text('Revisão'));
      await _anda(tester, 8);
      expect(find.byType(SessaoMemoriaPage), findsNothing);
      expect(find.byType(SessaoCartoesPage), findsOneWidget);
      expect(find.text('2 cartões · 2 novos'), findsOneWidget, reason: 'só 2 novos por dia');
      await avalia(tester, 'nota-bom');
      expect(revisao.introduzidasHoje, 1);
      await tester.tap(find.byTooltip('Voltar'));
      await _anda(tester, 24); // a transição de saída leva ~500 ms no relógio do teste

      // reabrir hoje: só falta 1 da cota
      await tester.tap(find.text('Revisão'));
      await _anda(tester, 8);
      expect(find.text('1 cartão · 1 novo'), findsOneWidget);
      await avalia(tester, 'nota-bom');
      await _anda(tester, 3);
      expect(find.text('Pronto!'), findsOneWidget);
      expect(revisao.introduzidasHoje, 2);
      await tester.tap(find.byKey(const Key('continuar-cartoes')));
      await _anda(tester, 24);

      // cota esgotada: não há mais nada
      await tester.tap(find.text('Revisão'));
      await _anda(tester, 12);
      expect(find.text('nenhuma frase vence hoje'), findsOneWidget);
    });

    testWidgetsDesktop('responder ESCREVENDO (o padrão): a tradução certa sugere Bom, o Espaço aceita e o cartão nasce no motor', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, prefs: {'en_srs_cfg': reversos, 'en_cartao_sentido': 'en-pt'}); // sem nível salvo: vale o padrão (Avançado)
      await _esperar(tester, find.text('Revisão'));
      final revisao = tester.element(find.byType(HomePage)).read<RevisaoCubit>();
      await tester.tap(find.text('Revisão'));
      await _anda(tester, 10);
      expect(find.byType(SessaoCartoesPage), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
      expect(find.byKey(const Key('mostrar-resposta')), findsNothing);

      // a 1ª frase do baralho: "Hi, I'm Ana." = "Oi, eu sou a Ana."
      await tester.enterText(find.byKey(const Key('resposta-escrita')), 'oi eu sou a ANA');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _anda(tester, 3);
      expect(find.text('Idêntica! ✅ 5 de 5 palavras.'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await _anda(tester, 4);

      final c = revisao.state.cartoes[Revisao.chaveReversa(Revisao.chave("Hi, I'm Ana."))]!;
      expect(c.revisoes, 1);
      expect(c.proximoDia - revisao.hoje, inInclusiveRange(2, 6), reason: '"Bom" na 1ª vez');
      final historico = await tester.runAsync(() => LocalRevisaoRepository().carregarHistorico());
      expect(historico!.any((e) => e.chave.endsWith('~r') && e.nota == 3 && e.primeira), isTrue);
    });

    testWidgetsDesktop('Mapa → "Baralhos e cartões": baralhos por etapa e "Estudar" só do baralho escolhido', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, prefs: {'en_cartao_escrita': false, 'en_cartao_sentido': 'en-pt', 
        'en_srs_cfg': ConfigSrs(reversos: {'tr:Primeiros Passos', 'tr:Dia a dia'}).codificar(),
      });
      await _esperar(tester, find.byType(PalcoIngles));
      await tester.tap(find.text('Mapa'));
      await _anda(tester, 8);
      await tester.ensureVisible(find.byKey(const Key('baralhos')));
      await tester.tap(find.byKey(const Key('baralhos')));
      await _anda(tester, 8);
      expect(find.byType(BaralhosPage), findsOneWidget);
      // o Mapa continua por baixo (tem as mesmas faixas): olha só a página dos baralhos
      Finder nela(String t) => find.descendant(of: find.byType(BaralhosPage), matching: find.text(t));
      expect(nela('A1 · FUNDAÇÃO'), findsOneWidget);
      expect(nela('A2 · DIA A DIA'), findsOneWidget);
      expect(nela('Primeiros Passos'), findsOneWidget);
      expect(nela('Dia a dia'), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('estudar-tr:Dia a dia')));
      await tester.tap(find.byKey(const Key('estudar-tr:Dia a dia')));
      await _anda(tester, 8);
      expect(find.byType(SessaoCartoesPage), findsOneWidget);
      expect(find.text('Cartões · Dia a dia'), findsOneWidget);
      expect(find.text('1 cartão · 1 novo'), findsOneWidget, reason: 'o baralho tem uma frase só');
      expect(find.text('I was tired.'), findsOneWidget);
    });
  });

  group('áudio do aluno nas telas do inglês', () {
    testWidgetsDesktop('sem nuvem nem repositório injetado o 🎧 nem aparece (nada muda para quem não usa)', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles);
      await _esperar(tester, find.byType(PalcoIngles));
      expect(AudioUsuario.disponivel, isFalse);
      expect(find.byKey(const Key('audio-da-frase')), findsNothing);
    });

    testWidgetsDesktop('com áudio disponível: o 🎧 aparece no palco e abre a folha; frase com áudio vem realçada', (tester) async {
      final repo = MemoriaAudioUsuarioRepository();
      await repo.salvar(AudioUsuario.chaveDe("Hi, I'm Ana."), ClipeAudio(Uint8List.fromList([...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WAVE'.codeUnits, ...List.filled(20, 0)]), 'audio/wav'));
      await _abrirApp(tester, inicial: Linguagem.ingles, audio: (_) => repo);
      await _esperar(tester, find.byType(PalcoIngles));
      await _esperar(tester, find.byKey(const Key('audio-da-frase')));
      expect(find.byKey(const Key('audio-da-frase')), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget, reason: 'a 1ª frase tem áudio do aluno');
      await tester.tap(find.byKey(const Key('audio-da-frase')));
      await _anda(tester, 8);
      expect(find.text('Seu áudio desta frase'), findsOneWidget);
      expect(find.byKey(const Key('info-audio')), findsOneWidget);
    });
  });

  group('palavras novas no fim da lição', () {
    // "nice" e "meet" são palavras novas da lição (as outras são de função ou nome); o dicionário de
    // teste entra no lugar do embutido
    const dic = Dicionario({
      'nice': 'legal, simpático',
      'meet': 'conhecer, encontrar',
      'where': 'onde',
      'from': 'de',
      'how': 'como',
    });
    const pt = {'nice': 'legal', 'meet': 'conhecer'};

    setUp(() => DicionarioIngles.usarParaTestes(dic));
    tearDown(() => DicionarioIngles.usarParaTestes(null));

    /// Deixa as animações do treino (troca de passo 320 ms) terminarem. O relógio do HUD não deixa o
    /// pumpAndSettle assentar.
    Future<void> passa(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      await _anda(tester, 2);
    }

    bool tem(String chave) => find.byKey(Key(chave)).evaluate().isNotEmpty;

    /// Faz a sessão de treino até o resumo: escolhe pela tradução, digita a palavra; no 🎧 (voz de
    /// verdade, não dá para saber o que falou) tenta uma e, se errar, aprende com a resposta.
    Future<void> treinar(WidgetTester tester) async {
      final ouvida = <String>[];
      for (var i = 0; i < 40 && !tem('treino-resumo'); i++) {
        if (tem('passo-conhecer')) {
          await tester.tap(find.byKey(const Key('treino-continuar')));
        } else if (tem('passo-escolha') || tem('passo-ouvir')) {
          final ouvir = tem('passo-ouvir');
          final alvo = ouvir
              ? (ouvida.isNotEmpty ? ouvida.last : 'nice')
              : pt[tester.widget<Text>(find.byKey(const Key('treino-prompt'))).data!]!;
          var opcao = find.descendant(of: find.byKey(Key(ouvir ? 'passo-ouvir' : 'passo-escolha')), matching: find.text(alvo));
          if (opcao.evaluate().isEmpty) opcao = find.byKey(const Key('treino-opcao-0'));
          await tester.tap(opcao.first);
          await passa(tester);
          final resposta = find.textContaining('Resposta: ');
          if (ouvir && resposta.evaluate().isNotEmpty) {
            ouvida.add(tester.widget<Text>(resposta).data!.split(' ')[1]);
          }
          await tester.tap(find.byKey(const Key('treino-continuar')));
        } else if (tem('passo-digitar')) {
          final traducao = tester.widget<Text>(find.byKey(const Key('treino-prompt'))).data!;
          final en = pt.entries.firstWhere((e) => e.value == traducao).key;
          await tester.enterText(find.byKey(const Key('treino-digitar')), en);
          await tester.pump();
          await tester.tap(find.byKey(const Key('treino-verificar')));
          await passa(tester);
          await tester.tap(find.byKey(const Key('treino-continuar')));
        }
        await passa(tester);
      }
      expect(find.text('Treino concluído!'), findsOneWidget);
    }

    Future<void> fazerLicao(WidgetTester tester, CursoBloc curso, TypingBloc typing) async {
      for (var i = 0; i < 40 && !curso.state.vitoria; i++) {
        await _digita(tester, typing.state.chars.join());
        await _anda(tester, 3);
        await _enter(tester);
      }
      expect(curso.state.vitoria, isTrue);
      await _anda(tester, 6);
    }

    testWidgetsDesktop('a vitória sugere treinar as 2+ palavras novas; treinar marca ✅ e o Enter segue', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, loaderEn: _LoaderEnComIds.new);
      await _esperar(tester, find.byType(PalcoIngles));
      final ctx = tester.element(find.byType(HomePage));
      final typing = ctx.read<TypingBloc>();
      final curso = ctx.read<CursoBloc>();
      final palavras = ctx.read<PalavrasCubit>();
      final revisao = ctx.read<RevisaoCubit>();
      // o índice das palavras fica pronto em segundo plano (initState do palco)
      for (var i = 0; i < 20 && palavras.state.indice == null; i++) {
        await _anda(tester, 2);
      }
      expect(palavras.state.indice, isNotNull);
      expect(find.byKey(const Key('vitoria-palavras')), findsNothing, reason: 'só no fim da lição');

      await fazerLicao(tester, curso, typing);
      final cartao = find.byKey(const Key('vitoria-palavras'));
      expect(find.descendant(of: find.byType(VictoryOverlay), matching: cartao), findsOneWidget);
      expect(find.text('🆕 2 palavras novas nesta lição'), findsOneWidget);
      expect(find.descendant(of: cartao, matching: find.text('nice')), findsOneWidget);
      expect(find.descendant(of: cartao, matching: find.text('conhecer')), findsOneWidget);
      // abaixo do título e os botões da vitória continuam cabendo no palco
      expect(tester.getRect(cartao).top, greaterThanOrEqualTo(tester.getRect(find.text('LIÇÃO CONCLUÍDA!')).bottom));
      // (o palco tem 20 de respiro e a vitória mais 20: o botão tem de estar na área visível dela, sem rolar)
      final palco = tester.getRect(find.byType(PalcoIngles));
      expect(tester.getRect(find.text('Repetir')).bottom, lessThanOrEqualTo(palco.bottom - 40));

      // 🎯 Treinar agora → a sessão abre por cima
      final cartoesFrases = revisao.state.cartoes.length;
      await tester.tap(find.byKey(const Key('treinar-palavras')));
      await passa(tester);
      expect(find.byType(TreinoPalavrasPage), findsOneWidget);
      await treinar(tester);
      await tester.tap(find.byKey(const Key('treino-concluir')));
      await passa(tester);
      expect(find.byType(TreinoPalavrasPage), findsNothing);
      // de volta à vitória: ✅, cartões das palavras no banco delas (as frases não mudaram)
      expect(find.byKey(const Key('palavras-treinadas')), findsOneWidget);
      expect(find.byKey(const Key('treinar-palavras')), findsNothing);
      expect(palavras.state.banco['nice']?.cartao, isNotNull);
      expect(palavras.state.banco['meet']?.cartao, isNotNull);
      expect(revisao.state.cartoes.length, cartoesFrases);
      // o Enter continua sendo da vitória: próxima lição
      await _enter(tester);
      await _anda(tester, 3);
      expect(curso.state.vitoria, isFalse);
      expect(curso.state.licaoIdx, 1);
    });

    testWidgetsDesktop('repetir a lição não mostra o cartão (as palavras já não são novas)', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, loaderEn: _LoaderEnComIds.new);
      await _esperar(tester, find.byType(PalcoIngles));
      final ctx = tester.element(find.byType(HomePage));
      final typing = ctx.read<TypingBloc>();
      final curso = ctx.read<CursoBloc>();
      await fazerLicao(tester, curso, typing);
      expect(find.byKey(const Key('vitoria-palavras')), findsOneWidget);
      await tester.tap(find.text('Repetir'));
      await _anda(tester, 3);
      expect(curso.state.vitoria, isFalse);
      await fazerLicao(tester, curso, typing);
      expect(find.text('LIÇÃO CONCLUÍDA!'), findsOneWidget);
      expect(find.byKey(const Key('vitoria-palavras')), findsNothing);
    });

    testWidgetsDesktop('com o ensaio (âncora) e o cartão juntos, "Repetir" ainda cabe no palco', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true, loaderEn: _LoaderEnComIds.new);
      await _esperar(tester, find.byType(EnsaioMental));
      await _avancaEnsaio(tester, const Duration(seconds: 5));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _anda(tester, 3);
      final ctx = tester.element(find.byType(HomePage));
      await fazerLicao(tester, ctx.read<CursoBloc>(), ctx.read<TypingBloc>());
      expect(find.textContaining('Junte o polegar'), findsOneWidget);
      expect(find.byKey(const Key('vitoria-palavras')), findsOneWidget);
      final palco = tester.getRect(find.byType(PalcoIngles));
      expect(tester.getRect(find.text('Repetir')).bottom, lessThanOrEqualTo(palco.bottom - 40));
    });

    /// Abre o app no curso com ids e espera o índice das palavras (e o rebuild do palco).
    Future<(CursoBloc, TypingBloc, PalavrasCubit)> abrir(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, loaderEn: _LoaderEnComIds.new, prefs: prefs);
      await _esperar(tester, find.byType(PalcoIngles));
      final ctx = tester.element(find.byType(HomePage));
      final palavras = ctx.read<PalavrasCubit>();
      for (var i = 0; i < 20 && (palavras.state.indice == null || !palavras.state.carregado); i++) {
        await _anda(tester, 2);
      }
      expect(palavras.state.indice, isNotNull);
      await _anda(tester, 2);
      return (ctx.read<CursoBloc>(), ctx.read<TypingBloc>(), palavras);
    }

    /// O passo atual é cópia (estreia ou correção)?
    bool ehCopia() =>
        find.text('Ouça e copie com atenção').evaluate().isNotEmpty ||
        find.textContaining('Corrija copiando').evaluate().isNotEmpty;

    /// Digita a frase atual com 2 teclas erradas no começo de "Nice" e de "meet" (as outras frases, certas).
    Future<void> digitaErrando(WidgetTester tester, TypingBloc typing) async {
      final alvo = typing.state.chars.join();
      if (alvo != 'Nice to meet you.') return _digita(tester, alvo);
      for (final ch in ['x', 'x', 'N', 'i', 'c', 'e', ' ', 't', 'o', ' ', 'z', 'z', 'm', 'e', 'e', 't', ' ', 'y', 'o', 'u', '.']) {
        if (typing.state.concluido) break;
        await _digita(tester, ch);
      }
    }

    group('🔥 teimosas', () {
      testWidgetsDesktop('errar a mesma palavra em 2 passos de memória anota; a vitória oferece treinar só elas; Agora não avisa',
          (tester) async {
        final (curso, typing, palavras) = await abrir(tester);
        var errados = 0;
        var viuAnotei = false;
        for (var i = 0; i < 60 && !curso.state.vitoria; i++) {
          final erra = errados < 2 && !ehCopia() && typing.state.chars.join() == 'Nice to meet you.';
          if (erra) {
            await digitaErrando(tester, typing);
            errados++;
          } else {
            await _digita(tester, typing.state.chars.join());
          }
          await _anda(tester, 3);
          if (erra && errados == 2) {
            // a 2ª vez: o aviso discreto aparece durante a lição (sem botão)
            expect(find.byKey(const Key('licao-anotei')), findsOneWidget);
            expect(find.textContaining('"nice" escapou de novo'), findsOneWidget);
            viuAnotei = true;
          } else if (erra) {
            expect(find.byKey(const Key('licao-anotei')), findsNothing, reason: '1 erro só não anota');
          }
          await _enter(tester);
        }
        expect(viuAnotei, isTrue);
        expect(curso.state.vitoria, isTrue);
        await _anda(tester, 6);
        // gravado uma vez no fim: as duas palavras erraram de vez 2x
        expect(palavras.state.banco['nice']?.errosTotal, 2);
        expect(palavras.state.banco['meet']?.errosTotal, 2);
        // a vitória: a oferta das teimosas + a linha compacta das palavras novas, e "Repetir" ainda cabe
        final oferta = find.byKey(const Key('cartao-teimosas'));
        expect(find.descendant(of: find.byType(VictoryOverlay), matching: oferta), findsOneWidget);
        expect(find.byKey(const Key('treinar-teimosas')), findsOneWidget);
        expect(find.text('🔥 Essas palavras te deram trabalho'), findsOneWidget);
        expect(find.byKey(const Key('palavras-novas-linha')), findsOneWidget);
        expect(find.byKey(const Key('treinar-palavras')), findsNothing, reason: 'compacto até tocar em "ver"');
        final palco = tester.getRect(find.byType(PalcoIngles));
        expect(tester.getRect(find.text('Repetir')).bottom, lessThanOrEqualTo(palco.bottom - 40));
        expect(palavras.state.banco.sugestao.mostradasHoje, 1);
        // "Agora não": avisa, recolhe e só pergunta amanhã
        await tester.tap(find.byKey(const Key('agora-nao')));
        await _anda(tester, 3);
        expect(find.text('Beleza! Pergunto de novo amanhã 😉'), findsOneWidget);
        expect(find.byKey(const Key('cartao-teimosas')), findsNothing);
        expect(palavras.state.banco.sugestao.recusasSeguidas, 1);
        // sem a oferta, o cartão das palavras novas volta inteiro (nada de linha compacta nem buraco)
        expect(find.byKey(const Key('palavras-novas-linha')), findsNothing);
        expect(find.byKey(const Key('treinar-palavras')), findsOneWidget);
        expect(tester.getRect(find.text('Repetir')).bottom,
            lessThanOrEqualTo(tester.getRect(find.byType(PalcoIngles)).bottom - 40));
        // o Enter continua sendo da vitória
        await _enter(tester);
        await _anda(tester, 3);
        expect(curso.state.licaoIdx, 1);
      });

      testWidgetsDesktop('erros na cópia e numa frase contestada ("foi erro de digitação") não gravam nada', (tester) async {
        final (curso, typing, palavras) = await abrir(tester);
        var contestou = false;
        for (var i = 0; i < 60 && !curso.state.vitoria; i++) {
          final nice = typing.state.chars.join() == 'Nice to meet you.';
          final copia = ehCopia();
          if (nice && (copia || !contestou)) {
            await digitaErrando(tester, typing);
          } else {
            await _digita(tester, typing.state.chars.join());
          }
          await _anda(tester, 3);
          if (nice && !copia && !contestou) {
            await tester.tap(find.text('foi erro de digitação'));
            await _anda(tester, 3);
            contestou = true;
          }
          await _enter(tester);
        }
        expect(contestou, isTrue);
        expect(curso.state.vitoria, isTrue);
        await _anda(tester, 6);
        expect(palavras.state.banco['nice'], isNull);
        expect(palavras.state.banco['meet'], isNull);
        expect(find.byKey(const Key('cartao-teimosas')), findsNothing);
        expect(find.byKey(const Key('licao-anotei')), findsNothing);
      });

      /// Faz a lição errando "Nice to meet you." nas 2 primeiras digitações de memória (vitória com a oferta).
      Future<void> fazerErrando(WidgetTester tester, CursoBloc curso, TypingBloc typing) async {
        var errados = 0;
        for (var i = 0; i < 60 && !curso.state.vitoria; i++) {
          final erra = errados < 2 && !ehCopia() && typing.state.chars.join() == 'Nice to meet you.';
          if (erra) {
            await digitaErrando(tester, typing);
            errados++;
          } else {
            await _digita(tester, typing.state.chars.join());
          }
          await _anda(tester, 3);
          await _enter(tester);
        }
        expect(curso.state.vitoria, isTrue);
        await _anda(tester, 6);
      }

      testWidgetsDesktop('largar a lição no meio (outra lição pelo mapa) grava o que já tropeçou, sem oferta',
          (tester) async {
        final (curso, typing, palavras) = await abrir(tester);
        var errou = false;
        for (var i = 0; i < 30 && !errou; i++) {
          errou = !ehCopia() && typing.state.chars.join() == 'Nice to meet you.';
          if (errou) {
            await digitaErrando(tester, typing);
          } else {
            await _digita(tester, typing.state.chars.join());
          }
          await _anda(tester, 3);
          await _enter(tester);
        }
        expect(errou, isTrue);
        expect(curso.state.vitoria, isFalse);
        expect(palavras.state.banco['nice'], isNull, reason: 'só no fim ou ao sair');
        curso.add(const LicaoSelecionada(1));
        await _anda(tester, 4);
        expect(curso.state.licaoIdx, 1);
        expect(palavras.state.banco['nice']?.errosTotal, 1);
        expect(palavras.state.banco['meet']?.errosTotal, 1);
        expect(palavras.state.banco.sugestao.mostradasHoje, 0);
        // sair do app depois não grava de novo
        await tester.pumpWidget(const SizedBox());
        expect(palavras.state.banco['nice']?.errosTotal, 1);
      });

      // (560: tela estreita — o título e o placar quebram —, sem a fonte de teste larga estourar os botões)
      testWidgetsDesktop('tela estreita: a vitória com a oferta mede o conteúdo: "Repetir" cabe, também com o "ver" aberto',
          (tester) async {
        final (curso, typing, _) = await abrir(tester);
        tester.view.physicalSize = const Size(560, 2600);
        await _anda(tester, 3);
        await fazerErrando(tester, curso, typing);
        expect(find.byKey(const Key('cartao-teimosas')), findsOneWidget);
        Rect palco() => tester.getRect(find.byType(PalcoIngles));
        expect(tester.getRect(find.text('Repetir')).bottom, lessThanOrEqualTo(palco().bottom - 40));
        await tester.tap(find.byKey(const Key('ver-palavras-novas')));
        await _anda(tester, 4);
        expect(find.byKey(const Key('treinar-palavras')), findsOneWidget);
        expect(tester.getRect(find.text('Repetir')).bottom, lessThanOrEqualTo(palco().bottom - 40));
      });

      testWidgetsDesktop('com o 👁 ligado (frase à vista) errar não grava nada', (tester) async {
        final (curso, typing, palavras) = await abrir(tester, prefs: {'en_ver_frases': true});
        for (var i = 0; i < 60 && !curso.state.vitoria; i++) {
          await digitaErrando(tester, typing);
          await _anda(tester, 3);
          expect(find.byKey(const Key('licao-anotei')), findsNothing);
          await _enter(tester);
        }
        expect(curso.state.vitoria, isTrue);
        await _anda(tester, 6);
        expect(palavras.state.banco['nice'], isNull);
        expect(palavras.state.banco['meet'], isNull);
        expect(find.byKey(const Key('cartao-teimosas')), findsNothing);
      });
    });

    group('🆕 conhecer as palavras antes da lição', () {
      testWidgetsDesktop('aparece no começo (só na lição nova), sem roubar o teclado: a 1ª tecla o dispensa e o Enter segue',
          (tester) async {
        final (curso, typing, _) = await abrir(tester);
        final cartao = find.byKey(const Key('antes-palavras'));
        expect(cartao, findsOneWidget);
        expect(find.text('🆕 Esta lição tem 2 palavras novas'), findsOneWidget);
        expect(find.descendant(of: cartao, matching: find.text('nice')), findsOneWidget);
        expect(find.descendant(of: cartao, matching: find.text('conhecer')), findsOneWidget);
        expect(find.byKey(const Key('treinar-antes')), findsOneWidget);
        expect(find.byKey(const Key('comecar-direto')), findsOneWidget);
        expect(_fraseComFoco(tester), isTrue);
        final alvo = typing.state.chars.join();
        await _digita(tester, alvo.substring(0, 1));
        await _anda(tester, 2);
        expect(cartao, findsNothing);
        await _digita(tester, alvo.substring(1));
        await _anda(tester, 3);
        await _enter(tester);
        expect(typing.state.chars.join(), isNot(alvo));
        expect(cartao, findsNothing, reason: 'uma vez por visita');
        // repetir a lição: as palavras já não são novas — nada de cartão
        await fazerLicao(tester, curso, typing);
        await tester.tap(find.text('Repetir'));
        await _anda(tester, 3);
        expect(curso.state.vitoria, isFalse);
        expect(cartao, findsNothing);
      });

      testWidgetsDesktop('"Começar direto" dispensa o cartão e a frase continua com o teclado', (tester) async {
        await abrir(tester);
        await tester.tap(find.byKey(const Key('comecar-direto')));
        await _anda(tester, 3);
        expect(find.byKey(const Key('antes-palavras')), findsNothing);
        expect(_fraseComFoco(tester), isTrue);
        // o pulo fica contado (3 seguidos e o cartão vira uma linha só)
        final prefs = await tester.runAsync(SharedPreferences.getInstance);
        expect(prefs!.getInt(PalcoIngles.prefPulosAntes), 1);
      });

      testWidgetsDesktop('⌘ Enter abre o "Conhecer antes" pelo teclado (o cartão mostra o atalho)', (tester) async {
        await abrir(tester);
        expect(find.descendant(of: find.byKey(const Key('atalho-antes')), matching: find.text('⌘ Enter')), findsOneWidget);
        expect(_fraseComFoco(tester), isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
        await passa(tester);
        expect(find.byType(TreinoPalavrasPage), findsOneWidget);
      });

      testWidgetsDesktop('pulado 3 vezes seguidas: vira uma linha só, que ainda abre o treino (e zera a conta)',
          (tester) async {
        await abrir(tester, prefs: {PalcoIngles.prefPulosAntes: 3});
        expect(find.byKey(const Key('antes-palavras')), findsOneWidget);
        expect(find.text('🆕 Esta lição tem 2 palavras novas'), findsNothing);
        expect(find.byKey(const Key('comecar-direto')), findsNothing);
        expect(find.textContaining('2 palavras novas nesta lição'), findsOneWidget);
        await tester.tap(find.byKey(const Key('treinar-antes')));
        await passa(tester);
        expect(find.byType(TreinoPalavrasPage), findsOneWidget);
        final prefs = await tester.runAsync(SharedPreferences.getInstance);
        expect(prefs!.getInt(PalcoIngles.prefPulosAntes), 0);
      });

      testWidgetsDesktop('na 1ª lição no celular (com o nivelamento em cima) o cartão já vem em uma linha', (tester) async {
        await abrir(tester);
        tester.view.physicalSize = const Size(390, 1600);
        await _anda(tester, 3);
        expect(find.byKey(const Key('antes-palavras')), findsOneWidget);
        expect(find.text('🆕 Esta lição tem 2 palavras novas'), findsNothing);
        expect(find.textContaining('2 palavras novas nesta lição'), findsOneWidget);
      });

      testWidgetsDesktop('"Conhecer antes" abre o treino; na volta a lição começa e a vitória diz "✅ Você já treinou"',
          (tester) async {
        final (curso, typing, palavras) = await abrir(tester);
        await tester.tap(find.byKey(const Key('treinar-antes')));
        await passa(tester);
        expect(find.byType(TreinoPalavrasPage), findsOneWidget);
        await treinar(tester);
        await tester.tap(find.byKey(const Key('treino-concluir')));
        await passa(tester);
        expect(find.byType(TreinoPalavrasPage), findsNothing);
        expect(palavras.state.banco['nice']?.cartao, isNotNull);
        // de volta: o cartão saiu, a lição começa do começo e com o teclado na frase
        expect(find.byKey(const Key('antes-palavras')), findsNothing);
        expect(_fraseComFoco(tester), isTrue);
        await fazerLicao(tester, curso, typing);
        final fim = find.byKey(const Key('vitoria-palavras'));
        expect(fim, findsOneWidget);
        expect(find.descendant(of: fim, matching: find.text('✅ Você já treinou essas palavras')), findsOneWidget);
        expect(find.byKey(const Key('revisar-palavras')), findsOneWidget);
        expect(find.byKey(const Key('treinar-palavras')), findsNothing);
        // "🔁 Revisar de novo" abre o treino outra vez
        await tester.tap(find.byKey(const Key('revisar-palavras')));
        await passa(tester);
        expect(find.byType(TreinoPalavrasPage), findsOneWidget);
      });
    });
  });
}

/// O curso de teste com ids estáveis nas lições (o índice das palavras novas só conhece lição com id).
class _LoaderEnComIds extends _LoaderEn {
  @override
  Future<List<Trilha>> carregar() async => [
        Trilha(
          nivel: 'Primeiros Passos',
          emoji: '👋',
          etapa: 'A1 · Fundação',
          licoes: const [
            Licao(nome: 'Olá!', emoji: '🙋', id: 'primeiros.ola', trechos: _frases),
            Licao(
                nome: 'Como vai?',
                emoji: '😊',
                id: 'primeiros.como-vai',
                trechos: [Trecho(cod: 'How are you?', dica: 'Como você está?', out: '')]),
          ],
        ),
      ];
}
