import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_shadowing_ui_test.dart' show ReconhecedorFalso;

class _Voz extends VozIngles {
  final falas = <String>[];
  int paradas = 0;
  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add(frase);
    return Future.value();
  }

  @override
  Future<void> parar() async => paradas++;
  @override
  bool get somLiberado => true;
}

const _a = Trecho(cod: 'Nice to meet you, Mike.', dica: 'Prazer em te conhecer, Mike.', out: '');
const _b = Trecho(cod: 'How are you?', dica: 'Como vai?', out: '');
const _semTraducao = Trecho(cod: 'See you tomorrow.', dica: '', out: '');
const _lacuna = Trecho(cod: 'Then I have breakfast with my sister.', dica: 'Depois tomo café da manhã com minha irmã.', out: '', alvo: 'breakfast');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  final notas = <(String, Rating)>[];
  late ReconhecedorFalso rec;
  late _Voz voz;

  Future<void> abrir(WidgetTester tester,
      {List<Trecho> itens = const [_a, _b],
      SentidoCartao sentido = SentidoCartao.shadowing,
      NivelResposta nivel = NivelResposta.avancado,
      bool Function(Trecho)? lacunaDaLeitura,
      Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues({
      SessaoCartoesPage.prefNivel: nivel.id,
      SessaoCartoesPage.prefSentido: sentido.id,
      ...prefs,
    });
    notas.clear();
    tester.view.physicalSize = const Size(900, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    voz = _Voz();
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<bool>(
            builder: (_) => SessaoCartoesPage(
              titulo: 'Cartões',
              subtitulo: 'teste',
              itens: itens,
              voz: voz,
              reconhecedor: rec,
              lacunaDaLeitura: lacunaDaLeitura,
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
  }

  /// Toca em Falar e entrega o que o reconhecedor "ouviu".
  Future<void> fala(WidgetTester tester, String dito) async {
    await tester.tap(find.byKey(const Key('shadowing-falar')));
    await tester.pump();
    rec.escutas.last.falou([dito]);
    await tester.pump();
  }


  setUp(() => rec = ReconhecedorFalso());

  group('a frente do cartão', () {
    testWidgets('só o áudio: nenhum texto da frase nem da tradução, o áudio toca sozinho e o painel está lá', (tester) async {
      await abrir(tester);
      expect(find.byKey(const Key('frente-shadowing')), findsOneWidget);
      expect(find.text('🗣 Ouça e repita'), findsOneWidget);
      expect(find.byKey(const Key('frente-cartao')), findsNothing);
      expect(find.byKey(const Key('frente-audio')), findsNothing);
      expect(find.textContaining('Nice to meet'), findsNothing);
      expect(find.textContaining('Prazer'), findsNothing);
      expect(find.text('ÁUDIO'), findsOneWidget);
      expect(find.textContaining('Ouça e repita a frase falando'), findsOneWidget);
      expect(voz.falas, ['Nice to meet you, Mike.']);
      expect(find.byKey(const Key('painel-shadowing')), findsOneWidget);
      expect(find.byKey(const Key('ouvir-cartao')), findsOneWidget);
      expect(rec.escutas, isEmpty, reason: 'o microfone só abre por um toque');
    });

    testWidgets('sem nível: o seletor de nível some, o de sentido continua', (tester) async {
      await abrir(tester);
      expect(find.byKey(const Key('nivel-avancado')), findsNothing);
      expect(find.byKey(const Key('nivel-facil')), findsNothing);
      expect(find.byKey(const Key('sentido-shadowing')), findsOneWidget);
      expect(find.text('🗣 Ouvir e repetir'), findsOneWidget);
    });

    testWidgets('trocar do ditado para o shadowing e de volta pelo seletor', (tester) async {
      await abrir(tester, sentido: SentidoCartao.audio);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.byKey(const Key('nivel-avancado')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sentido-shadowing')));
      await tester.pump();
      expect(find.byKey(const Key('frente-shadowing')), findsOneWidget);
      expect(find.byKey(const Key('nivel-avancado')), findsNothing);
      expect(voz.falas.length, 2, reason: 'o áudio toca ao entrar no shadowing');
      await tester.tap(find.byKey(const Key('sentido-audio')));
      await tester.pump();
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.byKey(const Key('nivel-avancado')), findsOneWidget);
    });

    testWidgets('funciona com frase sem tradução cadastrada', (tester) async {
      await abrir(tester, itens: const [_semTraducao]);
      expect(find.byKey(const Key('frente-shadowing')), findsOneWidget);
      await fala(tester, 'see you tomorrow');
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
    });

    testWidgets('"Misturado" nunca sorteia o shadowing (nem com o reconhecedor funcionando)', (tester) async {
      // 12 cartões: com o sorteio do lado em cada um, se o shadowing entrasse no sorteio apareceria em algum
      final itens = [for (var i = 0; i < 12; i++) Trecho(cod: 'Phrase number $i here.', dica: 'Frase $i.', out: '')];
      await abrir(tester, sentido: SentidoCartao.misto, itens: itens);
      for (var i = 0; i < 12; i++) {
        expect(find.byKey(const Key('frente-shadowing')), findsNothing, reason: 'cartão $i');
        expect(find.byKey(const Key('painel-shadowing')), findsNothing, reason: 'cartão $i');
        final mostrar = find.byKey(const Key('mostrar-resposta'));
        final naoSei = find.text('Não sei');
        await tester.tap(mostrar.evaluate().isNotEmpty ? mostrar : naoSei);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
      }
    });

    testWidgets('cartão de lacuna da leitura no shadowing: é a frase INTEIRA, sem lacuna', (tester) async {
      await abrir(tester, itens: const [_lacuna], lacunaDaLeitura: (_) => true);
      expect(find.byKey(const Key('frente-shadowing')), findsOneWidget);
      expect(find.byKey(const Key('painel-shadowing')), findsOneWidget);
      await fala(tester, 'then i have breakfast with my sister');
      expect(find.text('Você falou a frase inteira! ✅ 7 de 7 palavras.'), findsOneWidget);
    });
  });

  group('falar e virar', () {
    testWidgets('perfeita na 1ª: vira na hora, a frase e a tradução aparecem, sugere Bom, e Espaço aceita', (tester) async {
      await abrir(tester);
      await fala(tester, 'nice to meet you mike');
      expect(find.byKey(const Key('painel-shadowing')), findsNothing);
      expect(find.byKey(const Key('frente-shadowing')), findsNothing);
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
      expect(find.text('Prazer em te conhecer, Mike.'), findsOneWidget);
      expect(find.text('O QUE EU OUVI'), findsOneWidget);
      expect(find.text('Você falou a frase inteira! ✅ 5 de 5 palavras.'), findsOneWidget);
      expect(find.byKey(const Key('nota-bom')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('nota-bom')), matching: find.textContaining('sugerida')), findsOneWidget);
      expect(find.byKey(const Key('por-que-0-2')), findsNothing);
      expect(find.text('💡 Por quê?'), findsNothing, reason: 'não há "Por quê?" na fala');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.good)]);
      // o próximo cartão é shadowing de novo, com as 3 tentativas
      expect(find.byKey(const Key('frente-shadowing')), findsOneWidget);
      expect(find.textContaining('3 tentativas'), findsOneWidget);
    });

    testWidgets('perfeita só na 2ª tentativa: sugere Difícil', (tester) async {
      await abrir(tester);
      await fala(tester, 'nice to meet you');
      expect(find.byKey(const Key('verso-cartao')), findsNothing, reason: 'a frase continua escondida');
      expect(find.byKey(const Key('painel-shadowing')), findsOneWidget);
      expect(find.textContaining('Restam 2 tentativas'), findsOneWidget);
      await fala(tester, 'nice to meet you mike');
      expect(find.descendant(of: find.byKey(const Key('nota-dificil')), matching: find.textContaining('sugerida')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.hard)]);
    });

    testWidgets('3 tentativas com 60%: vira sugerindo Errei, marca as palavras e mostra o que ouviu', (tester) async {
      await abrir(tester);
      for (var i = 0; i < 3; i++) {
        await fala(tester, 'nice to meet');
      }
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
      expect(find.text('Você falou 3 de 5 palavras · sugestão: Errei'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('nota-errei')), matching: find.textContaining('sugerida')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.again)]);
    });

    testWidgets('3 tentativas com 80%: vira sugerindo Difícil', (tester) async {
      await abrir(tester);
      for (var i = 0; i < 3; i++) {
        await fala(tester, 'nice to meet you');
      }
      expect(find.text('Você falou 4 de 5 palavras · sugestão: Difícil'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.hard)]);
    });

    testWidgets('"Mostrar a frase": vira sugerindo Errei mesmo com uma tentativa boa', (tester) async {
      await abrir(tester);
      await fala(tester, 'nice to meet you');
      await tester.tap(find.byKey(const Key('shadowing-mostrar')));
      await tester.pump();
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.again)]);
    });

    testWidgets('"Mostrar a frase" sem ter falado nada: vira, sem comparação, sugerindo Errei', (tester) async {
      await abrir(tester);
      await tester.tap(find.byKey(const Key('shadowing-mostrar')));
      await tester.pump();
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
      expect(find.text('Nice to meet you, Mike.'), findsOneWidget);
      expect(find.byKey(const Key('resumo-comparacao')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.again)]);
    });

    testWidgets('"não ouvi nada" não gasta tentativa e não vira', (tester) async {
      await abrir(tester);
      await fala(tester, '');
      expect(find.byKey(const Key('painel-shadowing')), findsOneWidget);
      expect(find.textContaining('3 tentativas'), findsOneWidget);
      expect(find.byKey(const Key('verso-cartao')), findsNothing);
    });

    testWidgets('errou e voltou ("DE NOVO"): o cartão é shadowing de novo, com as 3 tentativas zeradas', (tester) async {
      await abrir(tester);
      await tester.tap(find.byKey(const Key('shadowing-mostrar')));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas.length, 1);
      await tester.tap(find.byKey(const Key('shadowing-mostrar'))); // o 2º cartão (How are you?)
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      // a primeira volta (DE NOVO): shadowing outra vez, sem tentativas gastas
      expect(find.text('DE NOVO'), findsOneWidget);
      expect(find.byKey(const Key('frente-shadowing')), findsOneWidget);
      expect(find.textContaining('3 tentativas'), findsOneWidget);
      expect(find.textContaining('Você errou: ouça e repita'), findsOneWidget);
    });
  });

  group('teclas e voz do app', () {
    testWidgets('Espaço abre o microfone; de novo, para; Enter NÃO vira o cartão', (tester) async {
      await abrir(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const Key('frente-shadowing')), findsOneWidget, reason: 'Enter não pula a fala');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(rec.escutas.length, 1);
      expect(find.byKey(const Key('shadowing-ouvindo')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(rec.escutas.single.parada, isTrue);
    });

    testWidgets('R ouve de novo (e vale no shadowing)', (tester) async {
      await abrir(tester);
      final antes = voz.falas.length;
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(voz.falas.length, antes + 1);
    });

    testWidgets('o app se cala quando o microfone abre', (tester) async {
      await abrir(tester);
      final antes = voz.paradas;
      await tester.tap(find.byKey(const Key('shadowing-falar')));
      await tester.pump();
      expect(voz.paradas, greaterThan(antes));
    });

    testWidgets('sair da tela com o microfone aberto cancela a escuta', (tester) async {
      await abrir(tester);
      await tester.tap(find.byKey(const Key('shadowing-falar')));
      await tester.pump();
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(rec.escutas.single.cancelada, isTrue);
    });

    testWidgets('trocar o cartão com o microfone aberto cancela a escuta velha', (tester) async {
      await abrir(tester);
      await tester.tap(find.byKey(const Key('shadowing-falar')));
      await tester.pump();
      // o seletor de sentido muda para o ditado: o painel sai da tela
      await tester.tap(find.byKey(const Key('sentido-audio')));
      await tester.pump();
      expect(rec.escutas.single.cancelada, isTrue);
      expect(find.byKey(const Key('painel-shadowing')), findsNothing);
    });
  });

  group('sem voz, o cartão vira ditado e a revisão segue', () {
    testWidgets('reconhecedor sem suporte: ditado com o nível escolhido e o aviso', (tester) async {
      rec = ReconhecedorFalso(ok: false);
      await abrir(tester);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.byKey(const Key('frente-shadowing')), findsNothing);
      expect(find.byKey(const Key('painel-shadowing')), findsNothing);
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget, reason: 'ditado Avançado: o campo de escrita');
      expect(find.byKey(const Key('nivel-avancado')), findsOneWidget);
      expect(find.textContaining('Sem voz neste aparelho, hoje é ditado'), findsOneWidget);
      // dá para responder o ditado e seguir
      await tester.enterText(find.byKey(const Key('resposta-escrita')), 'nice to meet you mike');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.good)]);
    });

    testWidgets('permissão negada na hora de falar: o cartão atual vira ditado, sem travar', (tester) async {
      await abrir(tester);
      await tester.tap(find.byKey(const Key('shadowing-falar')));
      await tester.pump();
      rec.escutas.single.deuErro(ErroFala.semPermissao);
      await tester.pump();
      expect(find.byKey(const Key('painel-shadowing')), findsNothing);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
      expect(find.textContaining('Sem voz neste aparelho'), findsOneWidget);
      await tester.tap(find.text('Não sei'));
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you, Mike.', Rating.again)]);
      // o próximo cartão segue como ditado (a voz não vai voltar na mesma sessão)
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
    });
  });

  group('o que o shadowing NÃO mexe', () {
    testWidgets('a série de nível não anda (nem as notas de shadowing entram nela)', (tester) async {
      await abrir(tester, itens: const [_a, _b, _a]);
      for (var i = 0; i < 2; i++) {
        await fala(tester, i == 0 ? 'nice to meet you mike' : 'how are you');
        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pump();
      }
      expect(notas.length, 2);
      final p = await SharedPreferences.getInstance();
      expect(p.getString(SessaoCartoesPage.prefSerie), isNull, reason: 'a série só guarda quem responde escrevendo');
    });

    testWidgets('o sentido escolhido fica guardado como "shadowing"', (tester) async {
      await abrir(tester, sentido: SentidoCartao.audio);
      await tester.tap(find.byKey(const Key('sentido-shadowing')));
      await tester.pumpAndSettle();
      final p = await SharedPreferences.getInstance();
      expect(p.getString(SessaoCartoesPage.prefSentido), 'shadowing');
    });

    testWidgets('sem estouro a 360 px, tema claro, com o resultado de uma tentativa', (tester) async {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await abrir(tester);
      tester.view.physicalSize = const Size(360, 740);
      await tester.pump();
      await fala(tester, 'nice to meet you');
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('shadowing-resultado')), findsOneWidget);
    });
  });
}
