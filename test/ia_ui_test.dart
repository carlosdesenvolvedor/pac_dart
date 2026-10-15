import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/habito/domain/habito.dart' show diaDe;
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:pac_dart/features/ia/domain/explicacao.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ia/presentation/widgets/botao_por_que.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria, TutorFalso;

class _Voz extends VozIngles {
  @override
  Future<void> falar(String frase, {bool? lenta}) => Future.value();
  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

const _pedido = PedidoExplicacao(
  frase: "Hi, I'm Ana.",
  traducao: 'Oi, eu sou a Ana.',
  resposta: 'hi am ana',
  palavrasErradas: ["I'm"],
);

const _frase = Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late TutorFalso tutor;
  late CotaMemoria cotaRepo;

  Future<IaCubit> criar(WidgetTester tester) async {
    tutor = TutorFalso();
    cotaRepo = CotaMemoria();
    final c = IaCubit(service: tutor, cotaRepo: cotaRepo, cache: CacheMemoria(), agora: () => DateTime(2026, 10, 13, 10));
    await tester.runAsync(c.carregar);
    addTearDown(() => tester.runAsync(c.close));
    return c;
  }

  Future<void> montar(WidgetTester tester, Widget filho, {IaCubit? ia, Size tela = const Size(900, 1000)}) async {
    tester.view.physicalSize = tela;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app = MaterialApp(theme: Mixart.tema(), home: Scaffold(body: SingleChildScrollView(child: Padding(padding: const EdgeInsets.all(16), child: filho))));
    if (ia != null) app = BlocProvider.value(value: ia, child: app);
    await tester.pumpWidget(app);
    await tester.pump();
  }

  /// O serviço roda em microtarefas: dá alguns quadros para o resultado chegar.
  Future<void> anda(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  group('BotaoPorQue', () {
    testWidgets('sem IaCubit na árvore (testes antigos) não existe', (tester) async {
      await montar(tester, const BotaoPorQue(pedido: _pedido));
      expect(find.byKey(const Key('por-que')), findsNothing);
    });

    testWidgets('pedido sem nada a explicar não mostra o botão', (tester) async {
      final ia = await criar(tester);
      await montar(tester, const BotaoPorQue(pedido: PedidoExplicacao(frase: 'a', traducao: 'b')), ia: ia);
      expect(find.byKey(const Key('por-que')), findsNothing);
    });

    testWidgets('toca → "pensando…" → o cartão do Prof. Dash com negrito, e o botão some; gasta 1', (tester) async {
      final ia = await criar(tester);
      tutor.segura = Completer<void>();
      await montar(tester, const BotaoPorQue(pedido: _pedido), ia: ia);
      expect(find.text('Por quê?'), findsOneWidget);
      expect(find.byKey(const Key('ia-restantes')), findsOneWidget);
      expect(find.text('restam 30 usos hoje'), findsOneWidget);
      await tester.tap(find.byKey(const Key('por-que')));
      await tester.pump();
      expect(find.text('O Prof. Dash está pensando…'), findsOneWidget);
      tutor.segura!.complete();
      await anda(tester);
      expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
      expect(find.byKey(const Key('por-que')), findsNothing);
      expect(find.textContaining('contração'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing, reason: 'o negrito vira estilo, sem os asteriscos');
      expect(ia.state.restantes, 29);
    });

    testWidgets('sem cota: mensagem acolhedora, sem botão e sem chamar a IA', (tester) async {
      final ia = await criar(tester);
      cotaRepo.guardada = CotaIa(dia: diaDe(DateTime(2026, 10, 13)), usos: 30);
      final ia2 = IaCubit(service: tutor, cotaRepo: cotaRepo, cache: CacheMemoria(), agora: () => DateTime(2026, 10, 13, 10));
      await tester.runAsync(ia2.carregar);
      addTearDown(() => tester.runAsync(ia2.close));
      await montar(tester, const BotaoPorQue(pedido: _pedido), ia: ia2);
      await tester.tap(find.byKey(const Key('por-que')));
      await anda(tester);
      expect(find.byKey(const Key('sem-cota')), findsOneWidget);
      expect(find.textContaining('descansou'), findsOneWidget);
      expect(find.textContaining('amanhã tem mais'), findsOneWidget);
      expect(find.textContaining('segue estudando'), findsOneWidget);
      expect(find.byKey(const Key('por-que')), findsNothing);
      expect(tutor.chamadas, 0);
      expect(ia.state.restantes, 30);
    });

    testWidgets('falha: avisa que NÃO gastou o limite, oferece "Tentar de novo" e depois funciona', (tester) async {
      final ia = await criar(tester);
      tutor.erro = Exception('sem rede');
      await montar(tester, const BotaoPorQue(pedido: _pedido), ia: ia);
      await tester.tap(find.byKey(const Key('por-que')));
      await anda(tester);
      expect(find.byKey(const Key('ia-falhou')), findsOneWidget);
      expect(find.textContaining('não gastou seu limite'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(ia.state.restantes, 30);
      tutor.erro = null;
      await tester.tap(find.byKey(const Key('por-que')));
      await anda(tester);
      expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
      expect(ia.state.restantes, 29);
    });

    testWidgets('360 px e tema claro: sem estouro', (tester) async {
      final ia = await criar(tester);
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      tutor.pedacos = ['Texto bem comprido ' * 30];
      await montar(tester, const BotaoPorQue(pedido: _pedido), ia: ia, tela: const Size(360, 740));
      await tester.tap(find.byKey(const Key('por-que')));
      await anda(tester);
      expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('comNegrito: **negrito**, *itálico* e `código`, o resto como veio', () {
      final t = comNegrito('a **b** c `d` e', const TextStyle());
      final textos = [for (final s in t.children!.cast<TextSpan>()) s.text];
      expect(textos, ['a ', 'b', ' c ', 'd', ' e']);
      expect(t.toPlainText(), 'a b c d e');
      final i = comNegrito('de *I am* e **I\'m**', const TextStyle());
      expect(i.toPlainText(), "de I am e I'm");
      final filhos = i.children!.cast<TextSpan>();
      expect(filhos[1].style!.fontStyle, FontStyle.italic);
      expect(filhos[3].style!.fontWeight, FontWeight.w800);
      expect(comNegrito('2 * 3 = 6', const TextStyle()).toPlainText(), '2 * 3 = 6', reason: 'asterisco solto não vira estilo');
    });
  });

  group('no cartão de revisão', () {
    final notas = <(String, Rating)>[];

    Future<void> abrir(WidgetTester tester, {IaCubit? ia, NivelResposta nivel = NivelResposta.avancado, SentidoCartao sentido = SentidoCartao.ptEn}) async {
      SharedPreferences.setMockInitialValues({SessaoCartoesPage.prefNivel: nivel.id, SessaoCartoesPage.prefSentido: sentido.id});
      notas.clear();
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget app = MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(
              builder: (_) => SessaoCartoesPage(
                titulo: 'Cartões',
                subtitulo: 'teste',
                itens: const [_frase],
                voz: _Voz(),
                chaveDe: RevisaoCubit.chaveReversaDe,
                previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
                onNota: (f, n) => notas.add((f.cod, n)),
              ),
            )),
            child: const Text('abrir'),
          ),
        ),
      );
      if (ia != null) app = BlocProvider.value(value: ia, child: app);
      await tester.pumpWidget(app);
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    Future<void> responde(WidgetTester tester, String texto) async {
      await tester.enterText(find.byKey(const Key('resposta-escrita')), texto);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    testWidgets('respondeu errado: aparece "Por quê?", e o pedido leva a resposta, a frase e o nível', (tester) async {
      final ia = await criar(tester);
      await abrir(tester, ia: ia);
      await responde(tester, 'nice to see you');
      expect(find.byKey(const Key('por-que')), findsOneWidget);
      await tester.tap(find.byKey(const Key('por-que')));
      await anda(tester);
      expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
      final ctx = tutor.contextos.single;
      expect(ctx, contains('Nice to meet you.'));
      expect(ctx, contains('Prazer em te conhecer.'));
      expect(ctx, contains('"nice to see you"'));
      expect(ctx, contains('PT → EN'));
      expect(ctx, contains('Avançado'));
      expect(ctx, contains('meet'), reason: 'a palavra que faltou');
      expect(notas, isEmpty, reason: 'a IA não dá nota');
    });

    testWidgets('respondeu IDÊNTICO: sem botão', (tester) async {
      final ia = await criar(tester);
      await abrir(tester, ia: ia);
      await responde(tester, 'nice to meet you');
      expect(find.text('Idêntica! ✅ 4 de 4 palavras.'), findsOneWidget);
      expect(find.byKey(const Key('por-que')), findsNothing);
    });

    testWidgets('"Não sei" (não respondeu nada): sem botão; sem IaCubit: sem botão', (tester) async {
      final ia = await criar(tester);
      await abrir(tester, ia: ia);
      await tester.tap(find.text('Não sei'));
      await tester.pump();
      expect(find.byKey(const Key('por-que')), findsNothing);

      await abrir(tester); // sem IaCubit
      await responde(tester, 'nice to see you');
      expect(find.byKey(const Key('resumo-comparacao')), findsOneWidget);
      expect(find.byKey(const Key('por-que')), findsNothing);
    });

    testWidgets('no ditado o pedido diz que foi ditado; o botão volta a zero no cartão seguinte', (tester) async {
      final ia = await criar(tester);
      await abrir(tester, ia: ia, sentido: SentidoCartao.audio);
      await responde(tester, 'nice to see you');
      await tester.tap(find.byKey(const Key('por-que')));
      await anda(tester);
      expect(tutor.contextos.single, contains('ditado'));
    });

    testWidgets('a explicação de um cartão não "vaza" para o próximo (estado novo por cartão)', (tester) async {
      final ia = await criar(tester);
      SharedPreferences.setMockInitialValues({SessaoCartoesPage.prefNivel: 'avancado', SessaoCartoesPage.prefSentido: 'pt-en'});
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider.value(
        value: ia,
        child: MaterialApp(
          home: SessaoCartoesPage(
            titulo: 'c',
            subtitulo: 's',
            itens: const [_frase, Trecho(cod: 'How are you?', dica: 'Como vai?', out: '')],
            voz: _Voz(),
            chaveDe: RevisaoCubit.chaveReversaDe,
            previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
            onNota: (f, n) {},
            aleatorio: null,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await responde(tester, 'zzz');
      await tester.tap(find.byKey(const Key('por-que')));
      await anda(tester);
      expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const Key('explicacao-ia')), findsNothing);
    });
  });
}
