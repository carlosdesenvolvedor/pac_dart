import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/revisao_leve.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🌱 A revisão leve: cada frase vem com a ajuda que a memória dela pede, a errada volta mais fácil e a nota da
/// revisão espaçada é honesta (ajuda = tropeço).
class _VozFake extends VozIngles {
  final falou = <String>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) async => falou.add(frase);
  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

CartaoSrs _cartao(double estabilidade, {int revisoes = 3}) =>
    CartaoSrs(estabilidade: estabilidade, dificuldade: 5, ultimoDia: 0, proximoDia: 0, revisoes: revisoes);

/// No computador (o teclado de verdade; no celular a frase pede o botão "Teclado").
final _desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

const _nice = Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '');
const _cafe = Trecho(cod: 'I need some coffee.', dica: 'Preciso de um café.', out: '');
const _tarde = Trecho(cod: 'See you later.', dica: 'Até mais tarde.', out: '');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FraseView.carencia = Duration.zero;
  });

  group('a ajuda pela memória', () {
    test('força: sem cartão ou < 4 dias = fraca; ≥ 21 dias = forte; o resto, média', () {
      expect(forcaDe(null), ForcaDaFrase.fraca);
      expect(forcaDe(_cartao(2)), ForcaDaFrase.fraca);
      expect(forcaDe(_cartao(8)), ForcaDaFrase.media);
      expect(forcaDe(_cartao(30)), ForcaDaFrase.forte);
    });

    test('a fraca reaparece escrita (reencontro); a forte vem de memória ou com os tracinhos', () {
      expect(ajudaPelaMemoria(null, 'Nice to meet you.'), AjudaRevisao.reencontro);
      for (final cod in ['A b c.', 'See you later.', 'I need some coffee.', 'Where is it?']) {
        expect([AjudaRevisao.esqueleto, AjudaRevisao.memoria], contains(ajudaPelaMemoria(_cartao(40), cod)));
        expect([AjudaRevisao.montar, AjudaRevisao.iniciais, AjudaRevisao.ouvir],
            contains(ajudaPelaMemoria(_cartao(8), cod)));
        // sem som, nada de ouvir; frase curta demais, nada de montar
        expect(ajudaPelaMemoria(_cartao(8), cod, podeOuvir: false, podeMontar: false), AjudaRevisao.iniciais);
      }
    });

    test('a média varia entre as frases (não vem sempre do mesmo jeito)', () {
      final vistas = {
        for (var i = 0; i < 30; i++) ajudaPelaMemoria(_cartao(8, revisoes: i), 'Nice to meet you.'),
      };
      expect(vistas.length, greaterThanOrEqualTo(2));
    });

    test('nota honesta: de memória e tracinhos valem inteiro; com ajuda o acerto vira tropeço; copiar não dá nota', () {
      expect(notaComAjuda(ResultadoRevisao.acertou, AjudaRevisao.memoria), ResultadoRevisao.acertou);
      expect(notaComAjuda(ResultadoRevisao.acertou, AjudaRevisao.esqueleto), ResultadoRevisao.acertou);
      for (final a in [AjudaRevisao.iniciais, AjudaRevisao.montar, AjudaRevisao.ouvir]) {
        expect(notaComAjuda(ResultadoRevisao.acertou, a), ResultadoRevisao.hesitou, reason: a.name);
        expect(notaComAjuda(ResultadoRevisao.errou, a), ResultadoRevisao.errou, reason: a.name);
      }
      expect(notaComAjuda(ResultadoRevisao.acertou, AjudaRevisao.reencontro), isNull);
    });

    test('errou: a volta é um degrau mais fácil', () {
      expect(AjudaRevisao.memoria.maisFacil, AjudaRevisao.iniciais);
      expect(AjudaRevisao.esqueleto.maisFacil, AjudaRevisao.iniciais);
      expect(AjudaRevisao.iniciais.maisFacil, AjudaRevisao.montar);
      expect(AjudaRevisao.ouvir.maisFacil, AjudaRevisao.montar);
      expect(AjudaRevisao.montar.modo, ModoFrase.memoria, reason: 'os blocos ficam no lugar do texto');
      expect(AjudaRevisao.reencontro.modo, ModoFrase.ver);
    });
  });

  group('o plano da sessão', () {
    test('toda frase tem UMA volta que vale nota; a do reencontro vale na montagem, depois dele', () {
      final ajudas = [
        AjudaRevisao.reencontro, AjudaRevisao.memoria, AjudaRevisao.iniciais, AjudaRevisao.reencontro,
        AjudaRevisao.memoria, AjudaRevisao.memoria, AjudaRevisao.memoria,
      ];
      final plano = planoDaSessao(ajudas.length, (i) => ajudas[i]);
      for (var i = 0; i < ajudas.length; i++) {
        expect(plano.where((p) => p.indice == i && p.vale).length, 1, reason: 'frase $i');
      }
      for (final i in [0, 3]) {
        final r = plano.indexWhere((p) => p.indice == i && p.ajuda == AjudaRevisao.reencontro);
        final v = plano.indexWhere((p) => p.indice == i && p.vale);
        expect(plano[v].ajuda, AjudaRevisao.montar);
        expect(v, greaterThan(r + 1), reason: 'a volta não vem colada no reencontro');
      }
    });

    test('nunca 3 seguidos do mesmo jeito quando dá para misturar', () {
      final ajudas = [
        for (var i = 0; i < 6; i++) AjudaRevisao.memoria,
        for (var i = 0; i < 3; i++) AjudaRevisao.iniciais,
      ];
      final plano = planoDaSessao(ajudas.length, (i) => ajudas[i]);
      var seguidos = 1, maior = 1;
      for (var k = 1; k < plano.length; k++) {
        seguidos = plano[k].ajuda == plano[k - 1].ajuda ? seguidos + 1 : 1;
        if (seguidos > maior) maior = seguidos;
      }
      expect(maior, lessThanOrEqualTo(2));
    });
  });

  group('na tela (SessaoMemoriaPage com a ajuda)', () {
    Future<_VozFake> abrir(WidgetTester tester, List<Trecho> itens, AjudaRevisao Function(Trecho) ajudaDe,
        {List<ResultadoFrase>? notas}) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final voz = _VozFake();
      await tester.pumpWidget(MaterialApp(
        home: SessaoMemoriaPage(
          titulo: 'Revisão',
          subtitulo: 'teste',
          itens: itens,
          voz: voz,
          ajudaDe: ajudaDe,
          onResultado: notas?.add,
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
      return voz;
    }

    Future<void> digita(WidgetTester tester, String texto) async {
      await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, texto);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 60));
      }
    }

    Future<void> enter(WidgetTester tester) async {
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump(const Duration(milliseconds: 60));
    }

    testWidgets('a fraca: "Lembra dessa?", a frase à vista e falada; copiar não dá nota e ela volta para montar',
        (tester) async {
      final notas = <ResultadoFrase>[];
      final voz = await abrir(tester, const [_nice], (_) => AjudaRevisao.reencontro, notas: notas);
      expect(find.textContaining('Lembra dessa?'), findsOneWidget);
      expect(voz.falou, contains(_nice.cod), reason: 'o reencontro começa pela voz');
      expect(find.text('2 / 2'), findsNothing);
      expect(find.text('1 / 2'), findsOneWidget, reason: 'o reencontro e a volta de montar');
      await digita(tester, _nice.cod);
      if (find.textContaining('Daqui a pouco').evaluate().isEmpty) await enter(tester);
      expect(find.textContaining('Daqui a pouco ela volta para você montar'), findsOneWidget);
      expect(notas, isEmpty);
      await enter(tester);
      expect(find.textContaining('Monte a frase com os blocos'), findsOneWidget);
    }, variant: _desktop);

    testWidgets('a forte de memória: os botões de ajuda com nome; usar "mostrar uma palavra" vira tropeço',
        (tester) async {
      final notas = <ResultadoFrase>[];
      await abrir(tester, const [_cafe], (_) => AjudaRevisao.memoria, notas: notas);
      expect(find.byKey(const Key('revisao-leve-palavra')), findsOneWidget);
      expect(find.byKey(const Key('revisao-leve-ver')), findsOneWidget);
      await tester.tap(find.byKey(const Key('revisao-leve-palavra')));
      await tester.pump();
      await digita(tester, _cafe.cod);
      await enter(tester); // confere
      await enter(tester); // segue (a nota vai ao seguir)
      expect(notas.single.resultado, ResultadoRevisao.hesitou);
    }, variant: _desktop);

    testWidgets('com iniciais, acertar conta tropeço (a frase volta um pouco antes, sem zerar)', (tester) async {
      final notas = <ResultadoFrase>[];
      await abrir(tester, const [_tarde], (_) => AjudaRevisao.iniciais, notas: notas);
      expect(find.textContaining('só as iniciais'), findsOneWidget);
      await digita(tester, _tarde.cod);
      await enter(tester); // confere
      await enter(tester); // segue
      expect(notas.single.resultado, ResultadoRevisao.hesitou);
    }, variant: _desktop);

    testWidgets('ouvir: sem o português nem o inglês, só a voz; a frase toca sozinha', (tester) async {
      final voz = await abrir(tester, const [_tarde], (_) => AjudaRevisao.ouvir);
      expect(find.byKey(const Key('revisao-leve-ouvir')), findsOneWidget);
      expect(find.text(_tarde.dica), findsNothing);
      expect(voz.falou, contains(_tarde.cod));
    }, variant: _desktop);

    testWidgets('⌨️ 🎤 🧩 a escolha de como responder aparece na revisão leve (como na lição)', (tester) async {
      await abrir(tester, const [_cafe], (_) => AjudaRevisao.memoria);
      expect(find.byKey(const Key('entrada-montar')), findsOneWidget);
      expect(find.byKey(const Key('entrada-digitar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('entrada-montar')));
      await tester.pump(const Duration(milliseconds: 60));
      // montando, sem os botões de digitar ("mostrar uma palavra")
      expect(find.byKey(const Key('revisao-leve-palavra')), findsNothing);
    }, variant: _desktop);

    testWidgets('sem a ajuda (provas, nivelamento): tudo de memória, como sempre', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: SessaoMemoriaPage(titulo: 'Prova', subtitulo: 't', itens: const [_nice], voz: _VozFake()),
      ));
      await tester.pump();
      expect(find.textContaining('Digite em inglês, de memória'), findsOneWidget);
      expect(find.byKey(const Key('revisao-leve-palavra')), findsNothing);
      expect(find.byKey(const Key('entrada-montar')), findsNothing, reason: 'prova é prova: sem trocar para os blocos');
    }, variant: _desktop);
  });
}
