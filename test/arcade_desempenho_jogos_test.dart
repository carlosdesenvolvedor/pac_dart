import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/presentation/chuva_page.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/avatares.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guarda de desempenho dos jogos do Arcade (22/out, 2ª passada). Só no curso de inglês:
/// - Chuva: o quadro reconstrói só a arena (o cabeçalho só quando o placar muda) e a rota não é
///   regravada a cada quadro; os tiros reaproveitam as tintas;
/// - Pac (Chuva, Rali…): o gradiente da esfera não nasce de novo a cada quadro da mastigada;
/// - Rali (pista): o relayout do LayoutBuilder da pista não regrava a cena inteira.
/// No Dart e no C# o caminho é o de antes (as mesmas contagens), e os desenhos mudados saem idênticos
/// em pixels nos dois caminhos.
///
/// Medidas de 120 quadros (900×1000, semente 5; Rali no Fácil, semente 3):
///   Chuva Dart:   builds 18.973 · cabeçalho 129 · paints 18.724 · gradientes do Pac 120 · Paint dos tiros 388
///   Chuva inglês antes: builds 22.094 · cabeçalho 129 · paints 21.540 · gradientes 120 · Paint dos tiros 388
///   Chuva inglês agora: builds  4.427 · cabeçalho   9 · paints  5.589 · gradientes   0 · Paint dos tiros 100
///   Rali  inglês antes: paints 5.816 · gradientes 120 → agora: paints 3.416 · gradientes 0
class _Medida {
  int quadros = 0, builds = 0, buildsCabecalho = 0, paints = 0, shadersPac = 0, tintasTiros = 0, teclas = 0;

  /// Quadros em que algo fora da arena e do Pac (a rota, o cabeçalho, o rodapé) foi regravado.
  int quadrosComRota = 0;
  bool _rotaNoQuadro = false;
  @override
  String toString() => 'quadros=$quadros teclas=$teclas builds=$builds cabecalho=$buildsCabecalho paints=$paints '
      'quadrosComRota=$quadrosComRota shadersPac=$shadersPac tintasTiros=$tintasTiros';
}

Widget _app(Widget home) => MaterialApp(theme: Mixart.tema(), home: home);

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

/// As palavras caindo agora (o chip é um Text.rich de 3 pedaços).
List<String> _palavrasNaTela() => [
      for (final e in find
          .byWidgetPredicate((w) =>
              w is RichText &&
              w.text is TextSpan &&
              (w.text as TextSpan).children?.length == 1 &&
              ((w.text as TextSpan).children!.single as TextSpan).children?.length == 3)
          .evaluate())
        (e.widget as RichText).text.toPlainText(),
    ];

/// A camada da arena (o RepaintBoundary logo acima do Tremor).
RenderObject _camadaArena(WidgetTester tester) {
  RenderObject? r = tester.renderObject(find.byType(Tremor));
  while (r != null && !r.isRepaintBoundary) {
    r = r.parent;
  }
  return r!;
}

/// 120 quadros da Chuva em [l], digitando uma letra a cada 8 quadros (tiros no ar).
Future<_Medida> _chuva(WidgetTester tester, Linguagem l) async {
  Linguagem.atual = l;
  tester.view.physicalSize = const Size(900, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
  await tester.pump();
  await _largada(tester);
  for (var i = 0; i < 150; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }

  final m = _Medida();
  final arena = _camadaArena(tester);
  final pac = tester.renderObject(find.byType(Pac3D));
  final shaders0 = debugShadersPac3D, tintas0 = debugTintasTirosChuva;
  debugOnRebuildDirtyWidget = (e, _) {
    m.builds++;
    if (e.widget is CabecalhoJogo) m.buildsCabecalho++;
  };
  debugOnProfilePaint = (r) {
    m.paints++;
    // sobe até a camada: quem não está sob a arena nem sob o Pac é da rota
    RenderObject? p = r;
    while (p != null && p != arena && p != pac) {
      p = p.parent;
    }
    if (p == null) m._rotaNoQuadro = true;
  };
  try {
    var digitado = '';
    String? alvo;
    var k = 0;
    for (var i = 0; i < 120; i++) {
      if (i % 8 == 0) {
        if (alvo == null || k >= alvo.length) {
          final ps = _palavrasNaTela();
          alvo = ps.isEmpty ? null : ps.first;
          k = 0;
        }
        if (alvo != null) {
          digitado += alvo[k++];
          m.teclas++;
          await tester.enterText(find.byType(TextField), digitado);
        }
      }
      await tester.pump(const Duration(milliseconds: 16));
      m.quadros++;
      if (m._rotaNoQuadro) m.quadrosComRota++;
      m._rotaNoQuadro = false;
    }
  } finally {
    debugOnRebuildDirtyWidget = null;
    debugOnProfilePaint = null;
  }
  m.shadersPac = debugShadersPac3D - shaders0;
  m.tintasTiros = debugTintasTirosChuva - tintas0;
  return m;
}

/// 120 quadros do Rali em [l] (Fácil, ninguém digita: o Pac mastiga e a carga da CPU enche).
Future<_Medida> _rali(WidgetTester tester, Linguagem l) async {
  Linguagem.atual = l;
  tester.view.physicalSize = const Size(900, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(_app(const RaliPage(semente: 3)));
  await tester.pump();
  await tester.tap(find.text('Fácil'));
  await tester.pump();
  await _largada(tester);
  final m = _Medida();
  final shaders0 = debugShadersPac3D;
  debugOnProfilePaint = (_) => m.paints++;
  try {
    for (var i = 0; i < 120; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      m.quadros++;
    }
  } finally {
    debugOnProfilePaint = null;
  }
  m.shadersPac = debugShadersPac3D - shaders0;
  return m;
}

/// Os bytes RGBA de [finder] (um RepaintBoundary) renderizado.
Future<Uint8List> _pixels(WidgetTester tester, Finder finder) async {
  final rb = tester.renderObject<RenderRepaintBoundary>(finder);
  return (await tester.runAsync(() async {
    final img = await rb.toImage();
    final bytes = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    return bytes!.buffer.asUint8List();
  }))!;
}

class _Tela extends StatelessWidget {
  final Widget child;
  const _Tela(this.child);
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RepaintBoundary(key: const Key('foto'), child: child)),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('Chuva no inglês: o quadro não refaz a página — cabeçalho só com placar novo, rota parada',
      (tester) async {
    final m = await _chuva(tester, Linguagem.ingles);
    expect(m.teclas, greaterThan(5), reason: 'digitou (tiros no ar)');
    // o cabeçalho só reconstrói quando o placar muda (teclas, nível, vidas), nunca a cada quadro
    expect(m.buildsCabecalho, lessThanOrEqualTo(m.teclas + 3), reason: '$m');
    // a rota (cabeçalho, rodapé, Scaffold) só é regravada quando o placar muda, não a cada quadro
    expect(m.quadrosComRota, lessThanOrEqualTo(m.teclas + 3), reason: '$m');
    // antes: ~184 builds e ~180 paints por quadro
    expect(m.builds / m.quadros, lessThan(60), reason: '$m');
    expect(m.paints / m.quadros, lessThan(70), reason: '$m');
    // o gradiente do Pac já estava guardado; as tintas dos tiros, no máximo uma vez
    expect(m.shadersPac, 0, reason: '$m');
    expect(m.tintasTiros, greaterThan(0), reason: 'houve tiros: $m');
    await tester.pumpWidget(Container());
  });

  testWidgets('Chuva no Dart (e C#): o mesmo caminho de antes — página inteira por quadro', (tester) async {
    final m = await _chuva(tester, Linguagem.dart);
    // como antes: o cabeçalho reconstrói em todo quadro (e a cada tecla), o Pac cria um gradiente por
    // quadro e cada tiro pintado cria 4 Paint
    expect(m.buildsCabecalho, greaterThanOrEqualTo(m.quadros), reason: '$m');
    expect(m.quadrosComRota, m.quadros, reason: '$m');
    expect(m.shadersPac, m.quadros, reason: '$m');
    expect(m.tintasTiros % 4, 0, reason: '$m');
    expect(m.tintasTiros, greaterThan(0), reason: '$m');
    await tester.pumpWidget(Container());
  });

  testWidgets('Chuva no inglês: placar e vidas seguem atualizando (palavra que cai tira vida)', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_app(const ChuvaPage(semente: 5)));
    await tester.pump();
    await _largada(tester);
    String vidas() => tester.widget<ChipPlacar>(find.byWidgetPredicate((w) => w is ChipPlacar && w.k == 'VIDAS')).v;
    expect(vidas(), '❤️❤️❤️');
    for (var i = 0; i < 600 && vidas() == '❤️❤️❤️'; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(vidas(), '❤️❤️·');
    // ninguém digita: o fim de jogo chega e o relógio para
    for (var i = 0; i < 1200 && find.byType(FimDeJogo).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(FimDeJogo), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('Chuva: a arena ocupa todo o espaço dela, no inglês (tamanho fixado) e no Dart', (tester) async {
    // o SizedBox.expand do inglês não muda a medida: a arena já ocupava todo o Expanded (menos o padding)
    for (final l in [Linguagem.ingles, Linguagem.dart]) {
      Linguagem.atual = l;
      for (final tela in const [Size(900, 1000), Size(390, 800), Size(1400, 900)]) {
        tester.view.physicalSize = tela;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(_app(ChuvaPage(key: UniqueKey(), semente: 5)));
        await tester.pump();
        final espaco =
            tester.getRect(find.ancestor(of: find.byType(Tremor), matching: find.byType(Expanded)).first);
        final esperado = Rect.fromLTRB(espaco.left + 20, espaco.top, espaco.right - 20, espaco.bottom - 8);
        expect(tester.getRect(find.byType(Tremor)), esperado, reason: '${l.name} $tela');
        await tester.pumpWidget(Container());
      }
    }
    tester.view.reset();
  });

  testWidgets('Rali no inglês: o Pac não cria gradiente por quadro e a pista não é regravada', (tester) async {
    final ingles = await _rali(tester, Linguagem.ingles);
    await tester.pumpWidget(Container());
    final dart = await _rali(tester, Linguagem.dart);
    await tester.pumpWidget(Container());
    expect(ingles.shadersPac, 0, reason: '$ingles');
    // Dart como antes: um gradiente por quadro
    expect(dart.shadersPac, dart.quadros, reason: '$dart');
    // antes ~48 paints por quadro no inglês (a pista regravada); agora a cena fica na camada
    expect(ingles.paints / ingles.quadros, lessThan(32), reason: '$ingles');
    expect(dart.paints / dart.quadros, greaterThan(40), reason: '$dart');
  });

  testWidgets('pixels: Pac, tiros e pista saem idênticos no inglês e no Dart', (tester) async {
    Future<Uint8List> foto(Linguagem l, Widget w) async {
      Linguagem.atual = l;
      await tester.pumpWidget(_Tela(KeyedSubtree(key: UniqueKey(), child: w)));
      await tester.pump();
      final px = await _pixels(tester, find.byKey(const Key('foto')));
      expect(px.any((b) => b != 0), isTrue, reason: 'a foto tem desenho');
      return px;
    }

    // o Pac parado (boca semiaberta) em dois tamanhos
    for (final t in const [46.0, 64.0]) {
      expect(await foto(Linguagem.ingles, Pac3D(tamanho: t, animado: false)),
          await foto(Linguagem.dart, Pac3D(tamanho: t, animado: false)),
          reason: 'Pac $t');
    }

    // tiros em vários pontos do voo
    final tiros = [
      (const Offset(200, 380), const Offset(60, 30), 0.0),
      (const Offset(200, 380), const Offset(320, 60), .1),
      (const Offset(200, 380), const Offset(90, 120), .5),
      (const Offset(200, 380), const Offset(380, 20), .93),
    ];
    Widget pintura(bool guardar) => CustomPaint(
          size: const Size(400, 400),
          painter: ChuvaPage.pintorDeTiros(tiros, Mixart.brand, guardarTintas: guardar),
        );
    expect(await foto(Linguagem.dart, pintura(true)), await foto(Linguagem.dart, pintura(false)));

    // a pista do Rali (com a camada nova no inglês), fases com adereços diferentes
    for (final fase in const [1, 3, 6]) {
      Widget pista() => SizedBox(
            width: 700,
            child: PistaPro(posJogador: 4, posCpu: 2, pista: 12, fase: fase),
          );
      expect(await foto(Linguagem.ingles, pista()), await foto(Linguagem.dart, pista()), reason: 'fase $fase');
    }
    await tester.pumpWidget(Container());
  });
}
