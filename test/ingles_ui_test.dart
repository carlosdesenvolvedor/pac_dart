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
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
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
    {Linguagem? inicial, Map<String, Object> prefs = const {}, bool ensaio = false}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: ensaio, ...prefs});
  tester.view.physicalSize = const Size(1400, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: () => _RankingFake(),
      curriculoBuilder: (l) => l == Linguagem.ingles ? _LoaderEn() : CurriculoLoader(linguagem: l),
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    FraseView.carencia = Duration.zero;
  });
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('a escolha mostra os 3 cursos e a tecla 3 entra no inglês', (tester) async {
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

  testWidgets('a lição inteira: escada intercalada, prova, nota no mapa e frases na revisão', (tester) async {
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
    expect(revisao.state.cartoes.values.every((c) => c.caixa == 1 && c.proximoDia == revisao.hoje + 1), isTrue);
    expect(find.text('LIÇÃO CONCLUÍDA!'), findsOneWidget);
    // sem o ensaio (desligado neste teste) a âncora não foi armada: nada do gesto
    expect(find.textContaining('Junte o polegar'), findsNothing);
  });

  testWidgets('de memória: errar duas vezes revela a letra e a frase errada ganha cópia de correção', (tester) async {
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

  testWidgets('terminada a frase, ela fica na tela até o Enter (dá para ouvir)', (tester) async {
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

  testWidgets('👁 ligado: o inglês fica à vista em todas as frases, fica salvo e a lição termina', (tester) async {
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

  testWidgets('Revisão do dia: só a tradução, acerto sobe de caixa', (tester) async {
    final hoje = Revisao.dia(DateTime.now());
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
    expect(c.caixa, 3);
    expect(c.proximoDia, hoje + Revisao.intervalos[2]);
  });

  testWidgets('redimensionar a janela no meio da lição (painel do tutor entra/sai) não zera a fila', (tester) async {
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

  testWidgets('teste de nivelamento: acertou de memória, a trilha fica concluída e as frases vão pra caixa 3', (tester) async {
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
    expect(revisao.state.cartoes.values.every((c) => c.caixa == 3), isTrue);
  });

  testWidgets('nivelamento: passou no portão do A2, o A1 inteiro fica testado e a lição atual vai para o A2', (tester) async {
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
    testWidgets('aparece no começo, segura o teclado, anda sozinho, espera o Enter e a 1ª frase recebe o foco',
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

    testWidgets('a âncora volta na vitória abaixo do título (sem cobri-lo) e, ao repetir, sem "novas"',
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

    testWidgets('frase longa: a voz da próxima frase espera a anterior acabar (nada é cortado)', (tester) async {
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

    testWidgets('"áudio automático" desligado: o ensaio não fala sozinho, o 🔊 continua falando', (tester) async {
      final voz = _VozFake();
      await _montarEnsaio(tester, _trilhaEn.licoes.first, voz, audioAuto: false);
      await _avancaEnsaio(tester, const Duration(seconds: 25));
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
      expect(voz.falas, isEmpty);
      await tester.tap(find.byTooltip('ouvir').first);
      await tester.pump();
      expect(voz.falas, ["Hi, I'm Ana."]);
    });

    testWidgets('página sem gesto ainda (app recém-aberto): espera o "Começar o ensaio" antes de tocar', (tester) async {
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
      await _avancaEnsaio(tester, const Duration(seconds: 25));
      expect(voz.falas, ["Hi, I'm Ana."]);
      expect(find.text('Você já se viu dizendo isso.'), findsOneWidget);
      // agora o Enter começa a lição
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(comecou, 1);
    });

    testWidgets('Enter no meio do roteiro já começa a lição', (tester) async {
      await _abrirApp(tester, inicial: Linguagem.ingles, ensaio: true);
      await _esperar(tester, find.byType(EnsaioMental));
      await _avancaEnsaio(tester, const Duration(seconds: 2));
      await _enter(tester);
      expect(find.byType(EnsaioMental), findsNothing);
      expect(_fraseComFoco(tester), isTrue);
    });

    testWidgets('Esc pula o ensaio sem virar "não sei" na frase', (tester) async {
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

    testWidgets('"não mostrar mais" grava a pref, a próxima lição começa sem ensaio e o link religa', (tester) async {
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

    testWidgets('a lição muda com outra tela por cima: o ensaio abre por baixo sem roubar o teclado dela',
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

    testWidgets('celular estreito sem estouro e, fechado, não volta ao redimensionar', (tester) async {
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
}
