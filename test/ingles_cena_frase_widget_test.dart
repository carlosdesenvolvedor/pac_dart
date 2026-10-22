// 🎬 O widget da cena da frase: o palco do 📺 sem balão (o EN não aparece), sem foco, o relógio só com algo para
// animar (a ação do passo ou a voz DESTA frase), parado com o ensaio na frente, "reduzir" no estado final. E o
// `semBalao` do PalcoHistoria: só a lição liga (o Turismo e o 📺 seguem com o balão).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart' show TextoBilingue;
import 'package:pac_dart/features/arcade/presentation/historia/palco_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_visivel.dart' show CabecalhoPalco;
import 'package:pac_dart/features/arcade/presentation/historia/balao_fala.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/assistir/encenador_licao.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart' show chaveDaFrase;
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/cena_da_frase.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/roteiro_da_frase.dart';

final _trilhas = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
    .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
    .toList();

final _licao = _trilhas.expand((t) => t.licoes).firstWhere((l) => l.id == 'primeiro-contato.oi-tudo-bem');
final HistoriaLicao _h = EncenadorLicao.encenar(_licao, etapa: 'A1 · Fundação');

(int, int) _ancora(int i) => _h.ancoras[chaveDaFrase(_licao.trechos[i])]!;

FalaEmCurso _fc(String frase) =>
    FalaEmCurso(frase: frase, boca: TrilhaBoca.compacta('0D 500X'), inicio: DateTime.now());

Future<void> _montar(WidgetTester tester, {(int, int)? ancora, bool ativo = true, bool reduzir = false}) async {
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: const Size(800, 600), disableAnimations: reduzir),
      child: Scaffold(
        body: Center(
          child: CenaDaFrase(historia: _h, ancora: ancora ?? _ancora(1), tamanho: const Size(320, 180), ativo: ativo),
        ),
      ),
    ),
  ));
}

/// Anda até a ação do passo acabar (o relógio para sozinho).
Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 80 && SchedulerBinding.instance.transientCallbackCount > 0; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

RoteiroDaFrase _roteiro(WidgetTester tester) =>
    tester.widget<PalcoHistoria>(find.byType(PalcoHistoria)).roteiro as RoteiroDaFrase;

void main() {
  Mixart.usarGoogleFonts = false;
  tearDown(() => VozIngles.falando.value = null);

  testWidgets('o palco do 📺 sem balão, no tamanho pedido, e sem o EN da frase na tela', (tester) async {
    await _montar(tester);
    expect(find.byKey(const Key('cena-da-frase')), findsOneWidget);
    expect(find.byType(PalcoHistoria), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('cena-da-frase'))), const Size(320, 180));
    expect(tester.widget<PalcoHistoria>(find.byType(PalcoHistoria)).semBalao, isTrue);
    expect(find.byType(BalaoFala), findsNothing);
    expect(find.byKey(const Key('historia-legenda')), findsNothing);
    for (final t in _licao.trechos) {
      expect(find.textContaining(t.cod), findsNothing, reason: 'o EN não pode aparecer: "${t.cod}"');
    }
    expect((_roteiro(tester).cena, _roteiro(tester).passo), _ancora(1));
  });

  testWidgets('o relógio anda com a ação e para sozinho; a voz DESTA frase o liga, a de outra não', (tester) async {
    await _montar(tester);
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0), reason: 'a ação do passo anima');
    await _assentar(tester);
    expect(SchedulerBinding.instance.transientCallbackCount, 0, reason: 'acabou a ação: nenhum quadro');
    expect(tester.binding.hasScheduledFrame, isFalse);

    VozIngles.falando.value = _fc(_licao.trechos[3].cod);
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, 0, reason: 'outra frase não mexe a boca');

    VozIngles.falando.value = _fc(_licao.trechos[1].cod);
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0), reason: 'a boca mexe com a voz');
    await tester.pump(const Duration(milliseconds: 100));

    VozIngles.falando.value = null;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(SchedulerBinding.instance.transientCallbackCount, 0, reason: 'a voz parou: a boca fecha e o relógio para');
  });

  testWidgets('trocar de frase salta para a âncora nova (e a ação anima de novo)', (tester) async {
    await _montar(tester, ancora: _ancora(4));
    await _assentar(tester);
    await _montar(tester, ancora: _ancora(0));
    expect((_roteiro(tester).cena, _roteiro(tester).passo), _ancora(0));
    expect(_roteiro(tester).tPasso, 0);
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
    await _assentar(tester);
  });

  testWidgets('ativo: false (o ensaio na frente): parado, nem com a voz da frase', (tester) async {
    await _montar(tester, ativo: false);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    VozIngles.falando.value = _fc(_licao.trechos[1].cod);
    await tester.pump();
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    // o ensaio fechou: a ação anima
    VozIngles.falando.value = null;
    await _montar(tester, ativo: true);
    expect(SchedulerBinding.instance.transientCallbackCount, greaterThan(0));
    await _assentar(tester);
  });

  testWidgets('reduzir animações: o estado final já no 1º quadro, sem relógio', (tester) async {
    await _montar(tester, reduzir: true);
    final r = _roteiro(tester);
    expect(r.animando, isFalse);
    expect(r.tPasso, r.animacao);
    expect(SchedulerBinding.instance.transientCallbackCount, 0);
    expect(tester.widget<PalcoHistoria>(find.byType(PalcoHistoria)).reduzir, isTrue);
  });

  testWidgets('não pega o foco nem o toque (a frase continua com o teclado)', (tester) async {
    final foco = FocusNode();
    addTearDown(foco.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Column(children: [
          CenaDaFrase(historia: _h, ancora: _ancora(1), tamanho: const Size(320, 180)),
          TextField(focusNode: foco, autofocus: true),
        ]),
      ),
    ));
    await tester.pump();
    expect(foco.hasFocus, isTrue);
    await tester.tap(find.byKey(const Key('cena-da-frase')), warnIfMissed: false);
    await tester.pump();
    expect(foco.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focado = FocusManager.instance.primaryFocus?.context;
    expect(
        focado == null || find.descendant(of: find.byKey(const Key('cena-da-frase')), matching: find.byWidget(focado.widget)).evaluate().isEmpty,
        isTrue,
        reason: 'nada dentro da cena entra no Tab');
    await _assentar(tester);
  });

  testWidgets('PalcoHistoria: com o padrão (Turismo/📺) o balão aparece; com semBalao, não', (tester) async {
    final r = RoteiroDaFrase()..irPara(_h, _ancora(1));
    Future<void> palco({required bool semBalao}) => tester.pumpWidget(MaterialApp(
          home: Center(
            child: SizedBox(
              width: 640,
              height: 360,
              child: PalcoHistoria(
                roteiro: r,
                relogio: 0,
                cabecalho: CabecalhoPalco(sobretitulo: '🎬', titulo: TextoBilingue('t', 't'), rotuloSemantico: 'x'),
                semBalao: semBalao,
              ),
            ),
          ),
        ));
    await palco(semBalao: false);
    expect(find.byType(BalaoFala), findsOneWidget);
    await palco(semBalao: true);
    expect(find.byType(BalaoFala), findsNothing);
  });
}
