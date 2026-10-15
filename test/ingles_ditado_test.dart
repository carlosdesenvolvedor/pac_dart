import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Voz extends VozIngles {
  final falas = <String>[];
  final lentas = <bool?>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add(frase);
    lentas.add(lenta);
    return Future.value();
  }

  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

const _a = Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '');
const _b = Trecho(cod: 'How are you?', dica: 'Como vai?', out: '');
const _semTraducao = Trecho(cod: 'See you tomorrow.', dica: '', out: '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  final notas = <(String, Rating)>[];

  Future<_Voz> abrir(WidgetTester tester,
      {List<Trecho> itens = const [_a, _b],
      NivelResposta nivel = NivelResposta.avancado,
      SentidoCartao sentido = SentidoCartao.audio}) async {
    SharedPreferences.setMockInitialValues({
      SessaoCartoesPage.prefNivel: nivel.id,
      SessaoCartoesPage.prefSentido: sentido.id,
    });
    notas.clear();
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final voz = _Voz();
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(
            builder: (_) => SessaoCartoesPage(
              titulo: 'Cartões',
              subtitulo: 'teste',
              itens: itens,
              voz: voz,
              chaveDe: RevisaoCubit.chaveReversaDe,
              previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
              onNota: (f, n) => notas.add((f.cod, n)),
            ),
          )),
          child: const Text('abrir'),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return voz;
  }

  group('o sentido "Áudio → escrever"', () {
    test('existe, tem id próprio e os ids antigos continuam valendo', () {
      expect(SentidoCartao.porId('audio'), SentidoCartao.audio);
      expect(SentidoCartao.audio.rotulo, contains('Áudio'));
      expect(SentidoCartao.porId('en-pt'), SentidoCartao.enPt);
      expect(SentidoCartao.porId('pt-en'), SentidoCartao.ptEn);
      expect(SentidoCartao.porId('misto'), SentidoCartao.misto);
    });

    testWidgets('a frente é SÓ o áudio: nenhum texto da frase, e ele toca sozinho', (tester) async {
      final voz = await abrir(tester);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.byKey(const Key('frente-cartao')), findsNothing);
      expect(find.text('Nice to meet you.'), findsNothing, reason: 'o inglês não pode aparecer (é o ditado)');
      expect(find.text('Prazer em te conhecer.'), findsNothing);
      expect(find.text('ÁUDIO'), findsOneWidget);
      expect(find.textContaining('Ouça e escreva em inglês'), findsOneWidget);
      expect(voz.falas, ['Nice to meet you.']);
      expect(find.byKey(const Key('ouvir-cartao')), findsOneWidget);
      await tester.tap(find.byKey(const Key('ouvir-cartao')));
      await tester.pump();
      expect(voz.falas.length, 2, reason: 'dá para ouvir de novo');
      expect(voz.lentas.last, isFalse);
      await tester.tap(find.byTooltip('Ouvir devagar'));
      await tester.pump();
      expect(voz.lentas.last, isTrue);
    });

    testWidgets('escrever o que ouviu: confere por palavra, sugere Bom e depois de virar mostra o inglês e a tradução', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byKey(const Key('resposta-escrita')), 'nice to meet you');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Idêntica! ✅ 4 de 4 palavras.'), findsOneWidget);
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
      expect(find.byKey(const Key('frente-audio')), findsNothing, reason: 'virou: a frente deixa de esconder');
      expect(find.text('Prazer em te conhecer.'), findsOneWidget, reason: 'a tradução aparece junto da resposta');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.good)]);
      // o próximo cartão volta a ser só áudio
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
    });

    testWidgets('ouviu errado: a nota sugerida cai e o verso marca as palavras', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byKey(const Key('resposta-escrita')), 'nice to see you');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.byKey(const Key('resumo-comparacao')), findsOneWidget);
      expect(find.textContaining('Você acertou 3 de 4 palavras'), findsOneWidget);
    });

    testWidgets('"Não sei" vira o cartão sugerindo Errei', (tester) async {
      await abrir(tester);
      await tester.tap(find.text('Não sei'));
      await tester.pump();
      expect(find.text('Nice to meet you.'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.again)]);
    });

    testWidgets('funciona com frase sem tradução cadastrada (o ditado não precisa dela)', (tester) async {
      final voz = await abrir(tester, itens: const [_semTraducao]);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(voz.falas, ['See you tomorrow.']);
      await tester.enterText(find.byKey(const Key('resposta-escrita')), 'see you tomorrow');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('Idêntica! ✅ 3 de 3 palavras.'), findsOneWidget);
    });

    testWidgets('nível "Só virar": a tecla R ouve de novo e virar mostra a frase', (tester) async {
      final voz = await abrir(tester, nivel: NivelResposta.livre);
      expect(find.byKey(const Key('mostrar-resposta')), findsOneWidget);
      expect(find.text('Nice to meet you.'), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(voz.falas.length, 2);
      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      expect(find.text('Nice to meet you.'), findsOneWidget);
    });

    testWidgets('nível Médio: lacunas na frase em inglês, sem a frente de texto', (tester) async {
      await abrir(tester, nivel: NivelResposta.medio);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.textContaining('Ouça e complete a frase em inglês'), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsNothing);
    });

    testWidgets('nível Fácil: blocos de palavras em INGLÊS', (tester) async {
      await abrir(tester, nivel: NivelResposta.facil);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.textContaining('Ouça e monte em inglês'), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsNothing);
    });

    testWidgets('escolher o sentido no cartão troca para o ditado, toca o áudio e guarda a preferência', (tester) async {
      final voz = await abrir(tester, sentido: SentidoCartao.ptEn);
      expect(find.byKey(const Key('frente-cartao')), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsOneWidget);
      expect(voz.falas, isEmpty, reason: 'com o português na frente o áudio não toca sozinho');
      await tester.tap(find.byKey(const Key('sentido-audio')));
      await tester.pump();
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsNothing);
      expect(voz.falas, ['Nice to meet you.']);
      final p = await SharedPreferences.getInstance();
      expect(p.getString(SessaoCartoesPage.prefSentido), 'audio');
    });

    testWidgets('"Misturado" NUNCA vira ditado (continua EN/PT)', (tester) async {
      await abrir(tester, sentido: SentidoCartao.misto);
      for (var i = 0; i < 2; i++) {
        expect(find.byKey(const Key('frente-audio')), findsNothing);
        await tester.tap(find.text('Não sei'));
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
      }
    });

    testWidgets('celular estreito (360 px) sem estouro, com os 4 sentidos na tela', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      await abrir(tester);
      tester.view.physicalSize = const Size(360, 740);
      await tester.pump();
      expect(find.byKey(const Key('sentido-audio')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
