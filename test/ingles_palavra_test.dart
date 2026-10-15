// Toque na palavra (inglês): o pé da letra do dicionário do app + o sentido no contexto (Prof. Dash, cota e
// cache próprios). E, em Falar/Montar, a frase em inglês coberta até ser respondida.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/ia/data/cache_explicacoes.dart';
import 'package:pac_dart/features/ia/data/cota_repository.dart';
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:pac_dart/features/ia/domain/explicacao.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/dicionario_ingles.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/entrada_resposta.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/tutor/data/tutor_service.dart';

const _frase = "He's an engineer in Chicago.";

const _dic = Dicionario({
  "he's": 'ele é, ele está (he is / he has)',
  'an': 'um, uma (antes de vogal)',
  'engineer': 'engenheiro',
  'in': 'em, dentro de',
  'chicago': 'Chicago (cidade)',
  'cat': 'gato',
  'make': 'fazer',
  'run': 'correr',
  'mike': 'Mike (nome)',
});

class _Tutor implements TutorService {
  final List<String> perguntas = [];
  String resposta = '**engineer** → "engenheiro" (a profissão dele)';
  bool falhar = false;

  @override
  Stream<String> perguntar({required String contexto, required String historico, required String pergunta}) async* {
    perguntas.add('$contexto\n$pergunta');
    if (falhar) throw Exception('sem rede');
    yield resposta;
  }
}

class _CotaMem implements CotaRepository {
  CotaIa c = CotaIa.vazia;
  @override
  Future<CotaIa> carregar() async => c;
  @override
  Future<void> salvar(CotaIa cota) async => c = cota;
}

class _CacheMem implements CacheExplicacoes {
  final m = <String, String>{};
  @override
  Future<String?> ler(String chave) async => m[chave];
  @override
  Future<void> gravar(String chave, String texto) async => m[chave] = texto;
}

class _SemVoz extends ReconhecedorFala {
  @override
  bool get suportado => true;
  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  group('Dicionario', () {
    test('acha a forma exata, sem caixa e com apóstrofo curvo', () {
      expect(_dic.literal('Engineer'), 'engenheiro');
      expect(_dic.literal('He’s'), 'ele é, ele está (he is / he has)');
      expect(_dic.literal('Chicago.'), 'Chicago (cidade)');
    });

    test('formas flexionadas caem na base e dizem de onde vieram', () {
      expect(_dic.literal('cats'), 'gato (de cat)');
      expect(_dic.literal('making'), 'fazer (de make)');
      expect(_dic.literal('running'), 'correr (de run)');
      expect(_dic.literal("Mike's"), contains('Mike (nome)'));
      expect(_dic.literal('xyzzy'), isNull);
    });

    test('o dicionário do app cobre todas as palavras do curso', () {
      final dic = Dicionario.fromJson(jsonDecode(File('assets/ingles/dicionario.json').readAsStringSync()));
      final re = RegExp(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*");
      final faltam = <String>{};
      for (final t in jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List) {
        for (final l in (t as Map)['licoes'] as List) {
          for (final tr in ((l as Map)['trechos'] as List? ?? const [])) {
            for (final m in re.allMatches((tr as Map)['cod'] as String)) {
              final w = m.group(0)!;
              if (RegExp(r'^\d+$').hasMatch(w)) continue;
              if (dic.literal(w) == null) faltam.add(w);
            }
          }
        }
      }
      expect(faltam, isEmpty);
    });
  });

  group('PedidoPalavra', () {
    test('a mesma palavra em outra posição ou frase é outra chave', () {
      const a = PedidoPalavra(palavra: 'in', frase: _frase, indice: 3);
      expect(a.chave, const PedidoPalavra(palavra: 'In', frase: _frase, indice: 3).chave);
      expect(a.chave, isNot(const PedidoPalavra(palavra: 'in', frase: _frase, indice: 2).chave));
      expect(a.chave, isNot(const PedidoPalavra(palavra: 'in', frase: 'I live in Rio.', indice: 3).chave));
    });

    test('sem pé da letra no dicionário, pede que a IA dê também', () {
      const sem = PedidoPalavra(palavra: 'zork', frase: 'A zork.', traducao: 'Um zork.');
      const com = PedidoPalavra(palavra: 'an', frase: _frase, literal: 'um, uma');
      expect(sem.montar().pergunta, contains('Ao pé da letra'));
      expect(com.montar().pergunta, isNot(contains('Ao pé da letra')));
      expect(com.montar().contexto, contains('um, uma'));
    });
  });

  group('FraseView — toque na palavra', () {
    setUp(() {
      FraseView.carencia = Duration.zero;
      DicionarioIngles.usarParaTestes(_dic);
    });
    tearDown(() {
      FraseView.carencia = const Duration(milliseconds: 350);
      DicionarioIngles.usarParaTestes(null);
    });

    Future<(TypingBloc, _Tutor, IaPalavrasCubit)> abrir(
      WidgetTester tester, {
      ModoFrase modo = ModoFrase.ver,
      EntradaResposta entrada = EntradaResposta.digitar,
      bool mostrarTudo = false,
      String alvo = '',
      String alvoPt = '',
    }) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, (_) async => null);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.textInput, null));
      final bloc = TypingBloc()..add(const TrechoCarregado(_frase, tolerante: true));
      addTearDown(() => tester.runAsync(bloc.close));
      final tutor = _Tutor();
      final ia = IaPalavrasCubit(service: tutor, cotaRepo: _CotaMem(), cache: _CacheMem());
      addTearDown(() => tester.runAsync(ia.close));
      final foco = FocusNode();
      addTearDown(foco.dispose);
      await tester.pumpWidget(MaterialApp(
        theme: Mixart.tema(),
        home: Scaffold(
          body: MultiBlocProvider(
            providers: [BlocProvider.value(value: bloc), BlocProvider<IaPalavrasCubit>.value(value: ia)],
            child: FraseView(
              modo: modo,
              focusNode: foco,
              reconhecedor: _SemVoz(),
              entrada: entrada,
              mostrarTudo: mostrarTudo,
              alvo: alvo,
              alvoPt: alvoPt,
              traducao: 'Ele é engenheiro em Chicago.',
              onAvancar: () {},
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.pump();
      return (bloc, tutor, ia);
    }

    FraseViewState fv(WidgetTester t) => t.state<FraseViewState>(find.byType(FraseView));

    Future<void> tocarPalavra(WidgetTester t, int i) async {
      final r = fv(t).caixaDaPalavra(i);
      expect(r, isNotNull, reason: 'a palavra $i devia estar à vista');
      await t.tapAt(r!.center);
      await t.pump();
      await t.pump();
      await t.pump();
    }

    String fraseNaTela(WidgetTester t) => t
        .widgetList<RichText>(find.descendant(of: find.byType(FraseView), matching: find.byType(RichText)))
        .map((r) => r.text.toPlainText())
        .firstWhere((s) => s.length == _frase.length);

    testWidgets('tocar numa palavra mostra o pé da letra e o sentido no contexto', (t) async {
      final (_, tutor, _) = await abrir(t);
      await tocarPalavra(t, 2); // engineer
      expect(find.byKey(const Key('balao-palavra')), findsOneWidget);
      expect(find.text('engineer'), findsOneWidget);
      expect(find.text('engenheiro'), findsOneWidget);
      expect(find.byKey(const Key('sentido-palavra')), findsOneWidget);
      expect(tutor.perguntas.single, contains('Palavra tocada: "engineer" (a 3ª palavra da frase)'));
      expect(tutor.perguntas.single, contains('Tradução da frase: Ele é engenheiro em Chicago.'));

      // a mesma palavra de novo: vem do cache, sem outra chamada
      await t.tap(find.byKey(const Key('fechar-balao-palavra')));
      await t.pump();
      expect(find.byKey(const Key('balao-palavra')), findsNothing);
      await tocarPalavra(t, 2);
      expect(find.byKey(const Key('sentido-palavra')), findsOneWidget);
      expect(tutor.perguntas, hasLength(1));
    });

    testWidgets('palavra do trecho da lição: o contexto é a tradução do trecho, sem gastar consulta', (t) async {
      final (_, tutor, _) = await abrir(t, alvo: "He's an engineer", alvoPt: 'Ele é engenheiro');
      await tocarPalavra(t, 0);
      expect(find.byKey(const Key('alvo-palavra')), findsOneWidget);
      expect(tutor.perguntas, isEmpty);
    });

    testWidgets('Esc fecha o balão sem virar "não sei"', (t) async {
      await abrir(t, modo: ModoFrase.pistas);
      // nas pistas só as iniciais estão à vista: nenhuma palavra inteira para tocar ainda
      expect(fv(t).caixaDaPalavra(0), isNull);
      for (final c in "He's ".split('')) {
        await t.enterText(find.byType(TextField), c);
        await t.pump();
      }
      await t.pump();
      await tocarPalavra(t, 0); // He's já digitada
      expect(find.byKey(const Key('balao-palavra')), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(find.byKey(const Key('balao-palavra')), findsNothing);
      expect(fv(t).desistiu, isFalse);
    });

    testWidgets('de memória, palavra escondida não abre o balão', (t) async {
      await abrir(t, modo: ModoFrase.memoria);
      for (var i = 0; i < 5; i++) {
        expect(fv(t).caixaDaPalavra(i), isNull);
      }
    });

    testWidgets('IA fora do ar: mostra o pé da letra e deixa tentar de novo', (t) async {
      final (_, tutor, _) = await abrir(t);
      tutor.falhar = true;
      await tocarPalavra(t, 4); // Chicago
      expect(find.text('Chicago (cidade)'), findsOneWidget);
      expect(find.byKey(const Key('tentar-sentido-de-novo')), findsOneWidget);
      tutor.falhar = false;
      await t.tap(find.byKey(const Key('tentar-sentido-de-novo')));
      await t.pump();
      await t.pump();
      expect(find.byKey(const Key('sentido-palavra')), findsOneWidget);
    });

    testWidgets('Montar e Falar cobrem a frase até ser respondida; Digitar e o 👁 mostram', (t) async {
      await abrir(t, entrada: EntradaResposta.montar);
      expect(fraseNaTela(t), "__'_ __ ________ __ _______.");
      expect(fv(t).caixaDaPalavra(2), isNull);
      // "não sei" revela (até na cópia, onde ela é o único jeito de ver)
      fv(t).naoSei();
      await t.pump();
      expect(fraseNaTela(t), _frase);
    });

    testWidgets('Falar também cobre', (t) async {
      await abrir(t, entrada: EntradaResposta.falar);
      expect(fraseNaTela(t), isNot(contains('engineer')));
    });

    testWidgets('com o 👁 ligado, Montar mostra a frase', (t) async {
      await abrir(t, entrada: EntradaResposta.montar, mostrarTudo: true);
      expect(fraseNaTela(t), _frase);
    });

    testWidgets('Digitar na cópia continua mostrando a frase', (t) async {
      await abrir(t);
      expect(fraseNaTela(t), _frase);
    });
  });
}
