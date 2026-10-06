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
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
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
    Licao(nome: 'Olá!', emoji: '🙋', trechos: _frases),
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

Future<void> _abrirApp(WidgetTester tester, {Linguagem? inicial, Map<String, Object> prefs = const {}}) async {
  SharedPreferences.setMockInitialValues(prefs);
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    FraseView.carencia = Duration.zero;
    PalcoIngles.esperaFeedback = const Duration(milliseconds: 40);
    PalcoIngles.esperaCopia = const Duration(milliseconds: 20);
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
    }
    expect(find.textContaining('Iniciais'), findsOneWidget);
    final alvo = typing.state.chars.join();
    // 3 palavras quase inteiras erradas: "Hi" com 2 erros, "I'm" com 2, "Ana" com 2
    for (final ch in ['x', 'x', 'H', 'i', ',', ' ', 'z', 'z', 'I', "'", 'm', ' ', 'q', 'q', 'A', 'n', 'a', '.']) {
      await _digita(tester, ch);
    }
    expect(typing.state.concluido, isTrue);
    await _anda(tester, 3);
    expect(typing.state.chars.join(), alvo);
    expect(find.textContaining('Correção'), findsOneWidget);
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
    await tester.pump(const Duration(milliseconds: 2600));
    await _anda(tester, 2);
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
      }
      // a página nasceu na zona falsa (o toque): o timer do feedback é falso,
      // mas o bloc dela anda com microtarefas — alterna os dois
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
        if (f.evaluate().isNotEmpty && feitas.add(k)) await _digita(tester, porPt[k]!);
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
}

