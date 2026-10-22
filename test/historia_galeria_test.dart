// Galeria da história (grupo C1): travas por pistaMax, "▶ Chegada" só com a chegada liberada, "📜 Resumo
// até aqui", o aviso de capítulos perdidos (cada escolha) e o visual estático nas paletas Mixart e clara.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/galeria_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/player_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VozFake extends VozIngles {
  final falas = <String>[];

  @override
  Future<FimDaFala> falarNoPlayer(String frase, {required double fator, PerfilVoz? perfil}) {
    falas.add(frase);
    return Future.value(FimDaFala.acabou);
  }

  @override
  Future<void> parar() async {}

  @override
  bool get somLiberado => true;
}

CapituloHistoria _cap(int n) => CapituloHistoria.fromJson(jsonDecode('''
{
  "pista": $n,
  "nivel": "A1",
  "titulo": {"en": "Title $n", "pt": "Título $n"},
  "resumo": "Resumo do capítulo $n: a equipe corre e aprende palavras novas.",
  "palavras": [{"en": "car", "pt": "carro"}, {"en": "team", "pt": "equipe"}, {"en": "fast", "pt": "rápido"}],
  "intro": [{
    "cenario": "campina", "hora": "dia",
    "elenco": [{"quem": "voce", "pos": "esquerda"}, {"quem": "mike", "pos": "direita"}],
    "falas": [{"quem": "mike", "en": "Chapter $n starts.", "pt": "O capítulo $n começa."}]
  }],
  "fim": [{
    "cenario": "campina", "hora": "tarde",
    "elenco": [{"quem": "voce", "pos": "esquerda"}],
    "falas": [{"quem": "voce", "en": "Chapter $n ends.", "pt": "O capítulo $n acaba."}]
  }],
  "gancho": {"en": "What comes after $n?", "pt": "O que vem depois do $n?"}
}
''') as Map<String, dynamic>);

final historia = HistoriaTurismo(
  const TextoBilingue('The Golden Wheel', 'A Roda de Ouro'),
  [for (var n = 1; n <= 4; n++) _cap(n)],
);

void tela(WidgetTester t, Size s) {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> esperar(WidgetTester t, double s) async {
  for (var i = 0; i < (s * 20).ceil(); i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<VozFake> abrirGaleria(WidgetTester t, {int pistaMax = 2, Set<int> chegadas = const {1}}) async {
  final voz = VozFake();
  await t.pumpWidget(MaterialApp(
    home: GaleriaHistoriaPage(historia: historia, pistaMax: pistaMax, chegadas: chegadas, voz: voz),
  ));
  await t.pump();
  return voz;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RoteiroHistoria.tocarSom = (_) {};
  });

  testWidgets('travas por pistaMax e "▶ Chegada" só com a chegada liberada', (t) async {
    tela(t, const Size(1280, 900));
    await abrirGaleria(t);
    expect(find.text('Title 1'), findsOneWidget);
    expect(find.text('Title 4'), findsOneWidget);
    expect(find.byKey(const Key('galeria-abertura-1')), findsOneWidget);
    expect(find.byKey(const Key('galeria-abertura-2')), findsOneWidget);
    expect(find.byKey(const Key('galeria-abertura-3')), findsNothing);
    expect(find.text('🔒 chegue à pista 3'), findsOneWidget);
    expect(find.text('🔒 chegue à pista 4'), findsOneWidget);
    expect(find.byKey(const Key('galeria-chegada-1')), findsOneWidget);
    expect(find.byKey(const Key('galeria-chegada-2')), findsNothing);
    expect(find.text('2 de 4 capítulos liberados'), findsOneWidget);
    // estático: nada agendado
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('"▶ Abertura" abre o player do capítulo e Esc volta para a galeria', (t) async {
    tela(t, const Size(1280, 900));
    final voz = await abrirGaleria(t);
    await t.tap(find.byKey(const Key('galeria-abertura-2')));
    await esperar(t, 3.2);
    expect(find.byType(PlayerHistoria), findsOneWidget);
    expect(voz.falas, contains('Chapter 2 starts.'));
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await esperar(t, .6);
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.byKey(const Key('galeria-abertura-2')), findsOneWidget);
    await esperar(t, .5);
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('"▶ Chegada" abre a chegada', (t) async {
    tela(t, const Size(1280, 900));
    final voz = await abrirGaleria(t);
    await t.tap(find.byKey(const Key('galeria-chegada-1')));
    await esperar(t, 3.2);
    expect(voz.falas, contains('Chapter 1 ends.'));
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await esperar(t, .6);
    expect(find.byType(PlayerHistoria), findsNothing);
  });

  testWidgets('"📜 Resumo até aqui" lista só os capítulos liberados', (t) async {
    tela(t, const Size(1280, 900));
    await abrirGaleria(t, pistaMax: 2, chegadas: {1});
    await t.tap(find.byKey(const Key('galeria-resumo')));
    await esperar(t, .6);
    expect(find.byKey(const Key('historia-resumo')), findsOneWidget);
    expect(find.textContaining('Resumo do capítulo 1'), findsOneWidget);
    expect(find.textContaining('Resumo do capítulo 2'), findsOneWidget);
    expect(find.textContaining('Resumo do capítulo 3'), findsNothing);
    // gancho só de quem já chegou
    expect(find.text('➜ O que vem depois do 1?'), findsOneWidget);
    expect(find.text('➜ O que vem depois do 2?'), findsNothing);
    expect(t.binding.hasScheduledFrame, isFalse);
  });

  group('abrirCapitulosPerdidos', () {
    Future<(EscolhaPerdidos?, bool) Function()> host(WidgetTester t) async {
      EscolhaPerdidos? escolha;
      var voltou = false;
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  escolha = await abrirCapitulosPerdidos(context, historia: historia, ate: 3);
                  voltou = true;
                },
                child: const Text('correr'),
              ),
            ),
          ),
        ),
      ));
      await t.tap(find.text('correr'));
      await esperar(t, .4);
      return () => (escolha, voltou);
    }

    testWidgets('▶ Ver do começo', (t) async {
      final r = await host(t);
      expect(find.text('📖 Capítulos perdidos'), findsOneWidget);
      expect(find.textContaining('os capítulos 1 a 3'), findsOneWidget);
      await t.tap(find.byKey(const Key('perdidos-comeco')));
      await esperar(t, .4);
      expect(r(), (EscolhaPerdidos.doComeco, true));
    });

    testWidgets('📜 Ler o resumo → mostra os resumos 1..3 e devolve resumo', (t) async {
      final r = await host(t);
      await t.tap(find.byKey(const Key('perdidos-resumo')));
      await esperar(t, .2);
      expect(find.textContaining('Resumo do capítulo 1'), findsOneWidget);
      expect(find.textContaining('Resumo do capítulo 3'), findsOneWidget);
      expect(find.textContaining('Resumo do capítulo 4'), findsNothing);
      expect(r().$2, isFalse);
      await t.tap(find.byKey(const Key('perdidos-resumo-ok')));
      await esperar(t, .4);
      expect(r(), (EscolhaPerdidos.resumo, true));
    });

    testWidgets('Seguir ▶', (t) async {
      final r = await host(t);
      await t.tap(find.byKey(const Key('perdidos-seguir')));
      await esperar(t, .4);
      expect(r(), (EscolhaPerdidos.seguir, true));
      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('fechar por fora → null', (t) async {
      tela(t, const Size(800, 600));
      final r = await host(t);
      await t.tapAt(const Offset(5, 5));
      await esperar(t, .4);
      expect(r(), (null, true));
    });
  });

  for (final paleta in [Paleta.mixart, Paleta.flutterClaro]) {
    for (final (tam, escala) in [(const Size(360, 640), 1.6), (const Size(1280, 720), 1.0), (const Size(2560, 1080), 1.0)]) {
      testWidgets('paleta ${paleta.nome} em ${tam.width.toInt()}×${tam.height.toInt()} (texto $escala) sem overflow',
          (t) async {
        final antes = Mixart.atual;
        Mixart.atual = paleta;
        addTearDown(() => Mixart.atual = antes);
        tela(t, tam);
        await t.pumpWidget(MaterialApp(
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(escala)),
              child: GaleriaHistoriaPage(historia: historia, pistaMax: 4, chegadas: const {1, 2, 3, 4}, voz: VozFake()),
            ),
          ),
        ));
        await t.pump();
        expect(t.takeException(), isNull);
        await t.tap(find.byKey(const Key('galeria-resumo')));
        await esperar(t, .6);
        expect(t.takeException(), isNull);
        expect(t.binding.hasScheduledFrame, isFalse);
      });
    }
  }
}
