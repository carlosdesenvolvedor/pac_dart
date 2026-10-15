// Teste de APP dos modos de resposta (Fase 7): o PacDartApp inteiro, com a lição de inglês sendo respondida
// digitando, montando e (no celular) sem abrir o teclado. A escolha é lembrada e a prova montada vale meio ponto.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/auth/data/auth_repository.dart';
import 'package:pac_dart/features/auth/domain/app_user.dart';
import 'package:pac_dart/features/auth/presentation/auth_cubit.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/curso/presentation/pages/home_page.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/habito/data/habito_repository.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/entrada_resposta.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/montagem_frase.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/seletor_entrada.dart';
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

class _Ranking implements RankingRepository {
  final enviados = <Map<String, int>>[];
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async => enviados.add(deltas);
  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => true;
  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

const _frases = [
  Trecho(cod: "Hi, I'm Ana.", dica: 'Oi, eu sou a Ana.', out: ''),
  Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: ''),
  Trecho(cod: 'Where are you from?', dica: 'De onde você é?', out: ''),
];

final _trilhaEn = Trilha(
  nivel: 'Primeiros Passos',
  emoji: '👋',
  etapa: 'A1 · Fundação',
  licoes: const [Licao(nome: 'Olá!', emoji: '🙋', trechos: _frases)],
);

class _LoaderEn extends CurriculoLoader {
  _LoaderEn() : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => [_trilhaEn];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 25 && alvo.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pump();
  }
}

Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// [limpar]: false reaproveita o que já está nas prefs (simula fechar e reabrir o app).
Future<void> _abrirApp(WidgetTester tester, {Map<String, Object> prefs = const {}, bool limpar = true, Size tela = const Size(1400, 2000)}) async {
  if (limpar) SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, ...prefs});
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: () => _Ranking(),
      habitoBuilder: (u) => LocalHabitoRepository(uid: u.uid),
      curriculoBuilder: (l) => _LoaderEn(),
      linguagemInicial: Linguagem.ingles,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
  await _esperar(tester, find.byType(PalcoIngles));
  await _anda(tester, 4);
}

TypingBloc _typing(WidgetTester t) => t.element(find.byType(HomePage)).read<TypingBloc>();
CursoBloc _curso(WidgetTester t) => t.element(find.byType(HomePage)).read<CursoBloc>();
HabitoCubit _habito(WidgetTester t) => t.element(find.byType(HomePage)).read<HabitoCubit>();
FraseViewState _fv(WidgetTester t) => t.state<FraseViewState>(find.byType(FraseView));
MontagemFraseState _montagem(WidgetTester t) => t.state<MontagemFraseState>(find.byType(MontagemFrase));

Future<void> _enter(WidgetTester t) async {
  await t.sendKeyEvent(LogicalKeyboardKey.enter);
  await _anda(t, 3);
}

Future<void> _digitaFrase(WidgetTester t) async {
  await t.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, _typing(t).state.chars.join());
  await _anda(t, 3);
}

/// Um passo digitando: a frase inteira e Enter.
Future<void> _passoDigitando(WidgetTester t) async {
  await _digitaFrase(t);
  await _enter(t);
}

Future<void> _escolher(WidgetTester t, EntradaResposta e) async {
  await t.ensureVisible(find.byKey(Key('entrada-${e.id}')));
  await t.pump();
  await t.tap(find.byKey(Key('entrada-${e.id}')));
  await _anda(t, 12); // dá tempo da rolagem que traz a zona de digitação à vista (celular)
}

/// Toca, na ordem, os blocos das palavras da frase da vez. [trocarUltima]: no lugar da última palavra põe um
/// bloco de enfeite (um Conferir que vai errar).
Future<void> _montarFrase(WidgetTester t, {bool trocarUltima = false}) async {
  final frase = _typing(t).state.chars.join();
  final palavras = [for (final p in partirFrase(frase)) if (p.palavra) p.texto];
  final m = _montagem(t);
  final usados = <int>{};
  Future<void> toca(int id) async {
    usados.add(id);
    final f = find.byKey(Key('bloco-$id'));
    await t.ensureVisible(f);
    await t.pump();
    await t.tap(f);
    await t.pump();
  }

  for (var i = 0; i < palavras.length; i++) {
    if (trocarUltima && i == palavras.length - 1) {
      await toca(m.blocos.firstWhere((b) => b.distrator).id);
      break;
    }
    await toca(m.blocos.firstWhere((b) => !b.distrator && b.texto == palavras[i] && !usados.contains(b.id)).id);
  }
}

Future<void> _conferir(WidgetTester t) async {
  final f = find.byKey(const Key('montagem-conferir'));
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  await _anda(t, 3);
}

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
void testWidgetsCelular(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  group('Digitar (o padrão)', () {
    testWidgetsDesktop('a lição nasce em Digitar, com a barra de modos, e digitar avança e conta 1 no hábito', (tester) async {
      await _abrirApp(tester);
      expect(find.byType(SeletorEntrada), findsOneWidget);
      expect(find.byType(MontagemFrase), findsNothing);
      expect(_habito(tester).state.habito.unidadesHoje, 0);
      final primeira = _typing(tester).state.chars.join();
      await _passoDigitando(tester);
      expect(_habito(tester).state.habito.unidadesHoje, 1);
      expect(_typing(tester).state.chars.join(), isNot(primeira), reason: 'seguiu para a próxima frase');
      expect(find.byType(MontagemFrase), findsNothing);
    });
  });

  group('Montar', () {
    testWidgetsDesktop('montar a frase certa conclui o passo, Enter avança e conta 1; o modo vale no passo seguinte', (tester) async {
      await _abrirApp(tester);
      await _escolher(tester, EntradaResposta.montar);
      expect(find.byType(MontagemFrase), findsOneWidget);
      final primeira = _typing(tester).state.chars.join();
      await _montarFrase(tester);
      await _conferir(tester);
      expect(_typing(tester).state.concluido, isTrue);
      expect(find.textContaining('Feita'), findsOneWidget, reason: 'a cópia (D1) não gera nota: selo de "feita"');
      expect(_habito(tester).state.habito.unidadesHoje, 0, reason: 'só conta ao seguir');
      await _enter(tester);
      expect(_habito(tester).state.habito.unidadesHoje, 1);
      expect(_typing(tester).state.chars.join(), isNot(primeira));
      expect(find.byType(MontagemFrase), findsOneWidget, reason: 'a escolha segue valendo');
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget, reason: 'blocos novos, montagem zerada');
    });

    testWidgetsDesktop('a escolha é lembrada: fica salva e o app reaberto já nasce em Montar', (tester) async {
      await _abrirApp(tester);
      await _escolher(tester, EntradaResposta.montar);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      expect((await SharedPreferences.getInstance()).getString('en_entrada'), 'montar');
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await _abrirApp(tester, limpar: false);
      await _esperar(tester, find.byType(MontagemFrase));
      expect(find.byType(MontagemFrase), findsOneWidget);
    });

    testWidgetsDesktop('preferência estragada cai em Digitar sem quebrar', (tester) async {
      await _abrirApp(tester, prefs: {'en_entrada': 'xyz'});
      expect(find.byType(SeletorEntrada), findsOneWidget);
      expect(find.byType(MontagemFrase), findsNothing);
    });

    testWidgetsDesktop('trocar de modo no meio do passo: os blocos somem e digitar volta a funcionar', (tester) async {
      await _abrirApp(tester);
      await _escolher(tester, EntradaResposta.montar);
      await _montarFrase(tester);
      await _escolher(tester, EntradaResposta.digitar);
      expect(find.byType(MontagemFrase), findsNothing);
      await _passoDigitando(tester);
      expect(_habito(tester).state.habito.unidadesHoje, 1);
    });
  });

  group('a nota do Montar na prova', () {
    /// Anda a lição digitando até a Prova e devolve quantos passos fez. [aoChegarNaProva] roda em cada passo de prova.
    Future<void> andarLicao(WidgetTester t, Future<void> Function() aoChegarNaProva) async {
      for (var i = 0; i < 40 && !_curso(t).state.vitoria; i++) {
        if (find.textContaining('Prova da lição').evaluate().isNotEmpty) {
          await aoChegarNaProva();
        } else {
          await _passoDigitando(t);
        }
      }
      await _anda(t, 4);
    }

    testWidgetsDesktop('as 3 provas montadas certas valem meio ponto: nota 5 de 10 (digitadas valeriam 10)', (tester) async {
      await _abrirApp(tester);
      var selos = 0;
      await andarLicao(tester, () async {
        await _escolher(tester, EntradaResposta.montar);
        await _montarFrase(tester);
        await _conferir(tester);
        expect(find.textContaining('Na prova, montar vale meio ponto'), findsOneWidget);
        expect(find.text('foi erro de digitação'), findsNothing, reason: 'meio ponto por montar não se contesta');
        expect(find.byKey(const Key('por-que')), findsNothing);
        selos++;
        await _enter(tester);
      });
      expect(selos, 3);
      expect(_curso(tester).state.vitoria, isTrue);
      expect(_curso(tester).state.quizNotas.values, [5]);
    });

    testWidgetsDesktop('as mesmas provas digitadas valem inteiro: nota 10', (tester) async {
      await _abrirApp(tester);
      await andarLicao(tester, () => _passoDigitando(tester));
      expect(_curso(tester).state.vitoria, isTrue);
      expect(_curso(tester).state.quizNotas.values, [10]);
    });

    testWidgetsDesktop('montar certo FORA da prova vale inteiro ("Montou certinho") e a prova digitada segue valendo 10', (tester) async {
      await _abrirApp(tester);
      var montouMemoria = 0;
      for (var i = 0; i < 40 && !_curso(tester).state.vitoria; i++) {
        final deMemoria = find.textContaining('Só com a tradução').evaluate().isNotEmpty;
        if (deMemoria && montouMemoria == 0) {
          await _escolher(tester, EntradaResposta.montar);
          await _montarFrase(tester);
          await _conferir(tester);
          expect(find.textContaining('Montou certinho'), findsOneWidget);
          montouMemoria++;
          await _enter(tester);
          await _escolher(tester, EntradaResposta.digitar);
        } else {
          await _passoDigitando(tester);
        }
      }
      expect(montouMemoria, 1);
      expect(_curso(tester).state.quizNotas.values, [10], reason: 'um montar de memória certo não derruba a nota da lição');
    });

    testWidgetsDesktop('montar ERRADO duas vezes na prova: errou, o Prof. Dash explica e vem a cópia de correção', (tester) async {
      await _abrirApp(tester);
      for (var i = 0; i < 40 && find.textContaining('Prova da lição').evaluate().isEmpty; i++) {
        await _passoDigitando(tester);
      }
      await _escolher(tester, EntradaResposta.montar);
      await _montarFrase(tester, trocarUltima: true);
      await _conferir(tester);
      expect(find.byKey(const Key('montagem-erro')), findsOneWidget);
      expect(_fv(tester).errosDeFala.values.fold<int>(0, (a, b) => a + b), 1);
      // tira o enfeite, põe o enfeite de novo e erra outra vez
      final m = _montagem(tester);
      final enfeite = m.blocos.firstWhere((b) => b.distrator);
      await tester.tap(find.byKey(Key('escolhido-${enfeite.id}')));
      await tester.pump();
      await tester.tap(find.byKey(Key('bloco-${enfeite.id}')));
      await tester.pump();
      await _conferir(tester);
      expect(_fv(tester).errosDeFala.values.fold<int>(0, (a, b) => a + b), 2);
      // agora acerta
      await tester.tap(find.byKey(Key('escolhido-${enfeite.id}')));
      await tester.pump();
      final frase = _typing(tester).state.chars.join();
      final ultima = [for (final p in partirFrase(frase)) if (p.palavra) p.texto].last;
      final bloco = m.blocos.firstWhere((b) => !b.distrator && b.texto == ultima);
      await tester.tap(find.byKey(Key('bloco-${bloco.id}')));
      await tester.pump();
      await _conferir(tester);
      expect(_typing(tester).state.concluido, isTrue);
      expect(find.textContaining('Vamos corrigir'), findsOneWidget);
      await _enter(tester);
      expect(find.textContaining('Correção'), findsWidgets);
    });
  });

  group('no celular', () {
    testWidgetsCelular('Montar não abre o teclado; voltar a Digitar abre', (tester) async {
      await _abrirApp(tester, tela: const Size(400, 900));
      final canal = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (call) async {
        canal.add(call.method);
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, null));

      // Digitar no celular: o botão Teclado está lá e abre o teclado
      expect(find.byKey(const Key('abrir-teclado')), findsOneWidget);
      await _escolher(tester, EntradaResposta.montar);
      expect(find.byType(MontagemFrase), findsOneWidget);
      expect(find.byKey(const Key('abrir-teclado')), findsNothing);
      canal.clear();

      await _montarFrase(tester);
      await _conferir(tester);
      expect(_typing(tester).state.concluido, isTrue);
      // avança (toque no botão do selo) e monta a próxima: nenhuma conexão de teclado em momento algum
      await tester.tap(find.text('Seguir'));
      await _anda(tester, 4);
      expect(find.byType(MontagemFrase), findsOneWidget);
      await _montarFrase(tester);
      expect(canal.where((c) => c == 'TextInput.show' || c == 'TextInput.setClient'), isEmpty,
          reason: 'Montar não pede o teclado: $canal');

      await _escolher(tester, EntradaResposta.digitar);
      await _anda(tester, 3);
      expect(canal, contains('TextInput.show'));
      expect(find.byKey(const Key('abrir-teclado')), findsOneWidget);
    });

    testWidgetsCelular('Falar não aparece sem reconhecimento de voz no aparelho (a barra fica com Digitar e Montar)', (tester) async {
      await _abrirApp(tester, tela: const Size(400, 900));
      expect(find.byKey(const Key('entrada-digitar')), findsOneWidget);
      expect(find.byKey(const Key('entrada-montar')), findsOneWidget);
      expect(find.byKey(const Key('entrada-falar')), findsNothing, reason: 'o reconhecedor da VM de teste não é suportado');
    });

    testWidgetsCelular('preferência "falar" num aparelho sem voz vale Digitar (o teclado segue disponível)', (tester) async {
      await _abrirApp(tester, prefs: {'en_entrada': 'falar'}, tela: const Size(400, 900));
      expect(_fv(tester).entradaAtiva, EntradaResposta.digitar);
      expect(find.byKey(const Key('abrir-teclado')), findsOneWidget);
    });
  });
}
