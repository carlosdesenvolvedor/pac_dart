// Testes de APP do hábito diário: o PacDartApp inteiro (como em ingles_ui_test), com o hábito
// guardado no aparelho e um relógio que o teste controla.
import 'dart:convert';

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
import 'package:pac_dart/features/habito/domain/habito.dart';
import 'package:pac_dart/features/habito/presentation/habito_cubit.dart';
import 'package:pac_dart/features/habito/presentation/widgets/chip_sequencia.dart';
import 'package:pac_dart/features/ingles/data/revisao_repository.dart';
import 'package:pac_dart/features/ingles/domain/config_srs.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/main.dart';
import 'package:pac_dart/features/ingles/presentation/fixacao.dart' show RevisaoLeve;
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

class _RankingContando implements RankingRepository {
  int somas = 0;
  final enviados = <Map<String, int>>[];
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {
    somas++;
    enviados.add(deltas);
  }
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
    Licao(nome: 'Olá!', emoji: '🙋', imagem: '🏨🙋', visualizacao: 'Você chega à recepção do hotel.', trechos: _frases),
    Licao(nome: 'Como vai?', emoji: '😊', trechos: [Trecho(cod: 'How are you?', dica: 'Como você está?', out: '')]),
  ],
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

final _trilhaDart = Trilha(
  nivel: 'Fundamentos',
  emoji: '🌱',
  licoes: const [
    Licao(nome: 'Variáveis', emoji: '🅰', trechos: [
      Trecho(cod: 'var a = 1;', dica: 'digite', out: 'ok'),
      Trecho(cod: 'var b = 2;', dica: 'digite', out: 'ok'),
      Trecho(cod: 'var c = 3;', dica: 'digite', out: 'ok'),
    ]),
  ],
);

class _LoaderDart extends CurriculoLoader {
  _LoaderDart() : super(linguagem: Linguagem.dart);
  @override
  Future<List<Trilha>> carregar() async => [_trilhaDart];
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

/// O relógio do app: o teste vira o dia quando quiser.
class _Relogio {
  DateTime t = DateTime(2026, 10, 12, 10);
  DateTime call() => t;
  void dias(int n) => t = DateTime(t.year, t.month, t.day + n, 10);
}

Future<void> _esperar(WidgetTester tester, Finder alvo) async {
  for (var i = 0; i < 20 && alvo.evaluate().isEmpty; i++) {
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
Future<void> _abrirApp(WidgetTester tester, _Relogio relogio,
    {Linguagem? inicial,
    Map<String, Object> prefs = const {},
    bool limpar = true,
    RankingRepository Function()? ranking,
    Size tela = const Size(1400, 2000)}) async {
  if (limpar) SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: false, ...prefs});
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.runAsync(() async {
    await tester.pumpWidget(PacDartApp(
      authCubitOverride: AuthCubit(_AuthFake()),
      progressoPorLinguagem: (_, l) => LocalProgressoRepository(prefixo: l.prefixoProgresso),
      revisaoBuilder: (_) => LocalRevisaoRepository(),
      rankingBuilder: ranking ?? () => _RankingContando(),
      habitoBuilder: (_) => LocalHabitoRepository(),
      habitoAgora: relogio.call,
      curriculoBuilder: (l) => l == Linguagem.ingles ? _LoaderEn() : _LoaderDart(),
      linguagemInicial: inicial,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await tester.pump();
  });
}

Future<void> _digita(WidgetTester tester, String texto) async {
  await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, texto);
  await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 5)));
  await tester.pump();
}

Future<void> _enter(WidgetTester tester) async {
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await _anda(tester, 3);
}

/// Digita a frase da vez inteira e confirma com Enter (um passo da escada).
Future<void> _passo(WidgetTester tester, TypingBloc typing) async {
  await _digita(tester, typing.state.chars.join());
  await _anda(tester, 3);
  await _enter(tester);
}

void testWidgetsDesktop(String descricao, WidgetTesterCallback corpo) =>
    testWidgets(descricao, corpo, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

HabitoCubit _habito(WidgetTester tester) =>
    tester.element(find.byType(HomePage, skipOffstage: false)).read<HabitoCubit>();

void main() {
  // estes testes cobrem a revisão 100% de memória (o caminho das provas); a revisão leve tem os dela
  // (test/ingles_revisao_leve_test.dart)
  setUpAll(() => RevisaoLeve.ligada = false);
  tearDownAll(() => RevisaoLeve.ligada = true);
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => FraseView.carencia = Duration.zero);
  tearDown(() => Linguagem.atual = Linguagem.dart);

  int dia(int depois) => diaDe(DateTime(2026, 10, 12 + depois));

  /// Prefs com uma sequência de [seq] dias cuja última meta foi há [ultima] dias.
  Map<String, Object> habitoGravado(int seq, {int ultima = 1, int frz = 0, int meta = 20}) => {
        'habito_v1': jsonEncode(Habito(
          meta: meta,
          dia: dia(-ultima),
          sequencia: seq,
          melhor: seq,
          ultimoDiaMeta: dia(-ultima),
          congelamentos: frz,
          historico: [for (var i = 0; i < seq; i++) dia(-ultima - i)]..sort(),
        ).toJson()),
      };

  group('inglês', () {
    testWidgetsDesktop('digitar uma frase da lição sobe o chip e o anel', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.ingles);
      await _esperar(tester, find.byType(PalcoIngles));
      await _anda(tester, 4);
      final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, 'Comece hoje');

      await _passo(tester, typing);
      expect(_habito(tester).state.habito.unidadesHoje, 1);
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, '1/20');
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, closeTo(.05, 1e-9));

      await _passo(tester, typing);
      expect(_habito(tester).state.habito.unidadesHoje, 2);
    });

    testWidgetsDesktop('errar de memória: a cópia de correção NÃO conta, o passo que errou conta', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.ingles);
      await _esperar(tester, find.byType(PalcoIngles));
      final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();

      for (var i = 0; i < 3; i++) {
        await _passo(tester, typing); // as 3 cópias
      }
      expect(_habito(tester).state.habito.unidadesHoje, 3);
      expect(find.textContaining('Iniciais'), findsOneWidget);
      for (final ch in ['x', 'x', 'H', 'i', ',', ' ', 'z', 'z', 'I', "'", 'm', ' ', 'q', 'q', 'A', 'n', 'a', '.']) {
        await _digita(tester, ch);
      }
      await _enter(tester);
      expect(_habito(tester).state.habito.unidadesHoje, 4, reason: 'a tentativa errada foi um exercício');
      expect(find.textContaining('Correção'), findsOneWidget);

      await _passo(tester, typing); // a cópia de correção
      expect(_habito(tester).state.habito.unidadesHoje, 4, reason: 'repetir o erro não é exercício novo');
    });

    testWidgetsDesktop('a lição inteira (15 passos) vira 15 exercícios, bate o "Leve" e avisa uma vez', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.ingles, prefs: habitoGravado(3, ultima: 1, meta: 10));
      await _esperar(tester, find.byType(PalcoIngles));
      await _anda(tester, 4);
      final home = tester.element(find.byType(HomePage));
      final typing = home.read<TypingBloc>();
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, '3', reason: 'sequência de ontem viva');

      var avisos = 0;
      for (var i = 0; i < 15; i++) {
        await _passo(tester, typing);
        if (find.byKey(const Key('aviso-meta-batida')).evaluate().isNotEmpty) avisos++;
        if (i == 8) {
          expect(_habito(tester).state.habito.sequencia, 3, reason: '9 de 10: ainda não');
          expect(find.byKey(const Key('aviso-meta-batida')), findsNothing);
        }
        if (i == 9) {
          expect(_habito(tester).state.habito.sequencia, 4);
          expect(find.text('Meta de hoje batida! 🔥 4 dias'), findsOneWidget);
        }
      }
      expect(avisos, greaterThan(0));
      final h = _habito(tester).state.habito;
      expect(h.unidadesHoje, 15);
      expect(h.sequencia, 4);
      expect(_habito(tester).state.metasBatidas, 1, reason: 'um aviso por dia');
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, '4');
    });

    testWidgetsDesktop('revisão: digitada conta 1; cartão conta a 1ª nota e o "DE NOVO" não', (tester) async {
      final relogio = _Relogio();
      final reversos = ConfigSrs(reversos: {'tr:Primeiros Passos'}).codificar();
      await _abrirApp(tester, relogio, inicial: Linguagem.ingles, prefs: {
        'en_cartao_escrita': false,
        'en_cartao_sentido': 'en-pt',
        'en_srs_cfg': reversos,
        // um cartão digitado vencido (formato antigo) para abrir a 1ª sessão
        'en_revisao': jsonEncode({Revisao.chave('Nice to meet you.'): const CartaoRevisao(caixa: 2, proximoDia: 0).codificar()}),
      });
      await _esperar(tester, find.text('Revisão · 1'));
      await tester.tap(find.text('Revisão · 1'));
      await _anda(tester, 8);
      await _digita(tester, 'Nice to meet you');
      await _anda(tester, 3);
      await _enter(tester);
      expect(_habito(tester).state.habito.unidadesHoje, 1, reason: 'a frase digitada na revisão');
      await tester.tap(find.textContaining('Continuar'));
      await _anda(tester, 8);

      Future<void> nota(String chave) async {
        await tester.tap(find.byKey(const Key('mostrar-resposta')));
        await _anda(tester, 2);
        await tester.tap(find.byKey(Key(chave)));
        await _anda(tester, 3);
      }

      // 1º cartão: "Errei" (conta 1) e ele volta mais tarde como "DE NOVO"
      await nota('nota-errei');
      expect(_habito(tester).state.habito.unidadesHoje, 2);
      var vistos = 1;
      var repeticoes = 0;
      while (find.byKey(const Key('mostrar-resposta')).evaluate().isNotEmpty && vistos < 12) {
        final repeticao = find.text('DE NOVO').evaluate().isNotEmpty;
        final antes = _habito(tester).state.habito.unidadesHoje;
        await nota('nota-bom');
        final depois = _habito(tester).state.habito.unidadesHoje;
        if (repeticao) {
          repeticoes++;
          expect(depois, antes, reason: '"DE NOVO" não é exercício');
        } else {
          expect(depois, antes + 1, reason: 'a 1ª nota de cada cartão conta');
        }
        vistos++;
      }
      expect(repeticoes, 1, reason: 'o cartão errado voltou uma vez');
      expect(_habito(tester).state.habito.unidadesHoje, 1 + 4, reason: '1 digitada + 4 cartões do baralho');
    });
  });

  group('Dart e a conta inteira', () {
    testWidgetsDesktop('digitar um trecho de Dart sobe o chip; trocar de curso NÃO zera (uma sequência só)', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.dart);
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      expect(_habito(tester).state.habito.unidadesHoje, 0);

      await tester.enterText(find.byType(TextField).last, 'var a = 1;');
      await _anda(tester, 4);
      expect(_habito(tester).state.habito.unidadesHoje, 1);
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, '1/20');

      // troca para o inglês: o hábito é o mesmo (provido acima dos cursos)
      final antes = _habito(tester);
      await tester.tap(find.textContaining('DART & FLUTTER'));
      await _anda(tester, 6);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await _esperar(tester, find.byType(PalcoIngles));
      await _anda(tester, 4);
      expect(identical(_habito(tester), antes), isTrue, reason: 'mesmo HabitoCubit depois de trocar de curso');
      expect(_habito(tester).state.habito.unidadesHoje, 1);

      final typing = tester.element(find.byType(HomePage)).read<TypingBloc>();
      await _passo(tester, typing);
      expect(_habito(tester).state.habito.unidadesHoje, 2, reason: 'Dart + Inglês somam');
    });

    testWidgetsDesktop('o hábito não vai ao ranking: terminar a lição publica pontos, nunca sequência/meta', (tester) async {
      final relogio = _Relogio();
      final ranking = _RankingContando();
      await _abrirApp(tester, relogio, inicial: Linguagem.dart, ranking: () => ranking, prefs: habitoGravado(3, ultima: 1, meta: 10));
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      final bloc = tester.element(find.byType(HomePage)).read<CursoBloc>();
      for (final cod in ['var a = 1;', 'var b = 2;', 'var c = 3;']) {
        await tester.enterText(find.byType(TextField).last, cod);
        await _anda(tester, 4);
        bloc.add(const TrechoAvancado());
        await _anda(tester, 4);
      }
      expect(bloc.state.vitoria, isTrue);
      expect(ranking.enviados, isNotEmpty, reason: 'a lição foi publicada (o teste só vale se isto vale)');
      final chaves = ranking.enviados.expand((d) => d.keys).toSet();
      expect(chaves.where((k) => RegExp('habito|sequencia|seq|meta|frz|congel', caseSensitive: false).hasMatch(k)), isEmpty,
          reason: 'chaves enviadas: $chaves');
      expect(_habito(tester).state.habito.unidadesHoje, 3, reason: 'a lição são 3 exercícios, não mais');
    });
  });

  group('persistência e virada do dia', () {
    testWidgetsDesktop('fechar e reabrir o app mantém sequência, meta e progresso do dia', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.dart, prefs: habitoGravado(5, ultima: 1, frz: 1, meta: 40));
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      await tester.enterText(find.byType(TextField).last, 'var a = 1;');
      await _anda(tester, 6);
      expect(_habito(tester).state.habito.unidadesHoje, 1);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

      // fecha o app
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      // reabre com as mesmas prefs
      await _abrirApp(tester, relogio, inicial: Linguagem.dart, limpar: false);
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      final h = _habito(tester).state.habito;
      expect(h.meta, 40);
      expect(h.sequencia, 5);
      expect(h.congelamentos, 1);
      expect(h.unidadesHoje, 1);
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, '5');
    });

    testWidgetsDesktop('um dia perdido com congelamento mantém a sequência; sem congelamento o chip convida a recomeçar', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.dart, prefs: habitoGravado(9, ultima: 2, frz: 1));
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, '9');

      await tester.pumpWidget(const SizedBox()); // fecha o primeiro app antes de abrir o outro
      await tester.pump();
      await _abrirApp(tester, relogio, inicial: Linguagem.dart, prefs: habitoGravado(9, ultima: 2, frz: 0));
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, 'Comece hoje');
    });

    testWidgetsDesktop('virar o dia com o app aberto zera o anel e o próximo dia soma na sequência', (tester) async {
      final relogio = _Relogio();
      await _abrirApp(tester, relogio, inicial: Linguagem.dart, prefs: habitoGravado(2, ultima: 1, meta: 10));
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      _habito(tester).praticou(10);
      await _anda(tester, 3);
      expect(_habito(tester).state.habito.sequencia, 3);
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, 1);

      relogio.dias(1);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 1100))); // o relógio do HUD
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<AnelDaMeta>(find.byType(AnelDaMeta)).progresso, 0, reason: 'dia novo, nada feito ainda');
      expect(tester.widget<Text>(find.byKey(const Key('chip-sequencia-rotulo'))).data, '3', reason: 'ontem bateu: ainda dá tempo hoje');

      _habito(tester).praticou(10);
      await _anda(tester, 3);
      expect(_habito(tester).state.habito.sequencia, 4);
    });

    testWidgetsDesktop('celular de 390 px: o cabeçalho com o chip não estoura', (tester) async {
      final relogio = _Relogio();
      final original = FlutterError.onError;
      final detalhes = <FlutterErrorDetails>[];
      FlutterError.onError = detalhes.add;
      addTearDown(() => FlutterError.onError = original);
      await _abrirApp(tester, relogio, inicial: Linguagem.dart, prefs: habitoGravado(12, ultima: 0, frz: 2), tela: const Size(390, 900));
      await _esperar(tester, find.byType(HomePage));
      await _anda(tester, 4);
      expect(find.byKey(const Key('chip-sequencia')), findsOneWidget);
      tester.takeException();
      // (a barra de progresso do palco, em home_page.dart, estoura 1,8 px nesta largura com a fonte de teste:
      // problema antigo e que não é do hábito — aqui só importa que NADA do hábito estoure)
      expect(detalhes.where((d) => d.toString().contains('features/habito')), isEmpty);
    });
  });
}
