// 🐢 velocidades da voz da história (1×, .85×, .7×, .5×) e voltar quantas falas quiser (⏮, bolinhas,
// ⏭), pedido do dono depois da 1ª versão. Só `pump(Duration)` (o relógio do player é um Ticker).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/progresso_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/player_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'historia_player_test.dart' show avancar, capitulo, tela;

/// Guarda também o `fator` que o player pediu.
class _VozComFator extends VozIngles {
  final falas = <(String, double)>[];

  @override
  Future<FimDaFala> falarNoPlayer(String frase, {required double fator, PerfilVoz? perfil}) {
    falas.add((frase, fator));
    return Future.value(FimDaFala.acabou);
  }

  @override
  Future<void> parar() async {}

  @override
  bool get somLiberado => true;
}

RoteiroHistoria _roteiro(VozIngles voz, {double? velocidade}) => RoteiroHistoria(
      cenas: capitulo.parte(ParteDoCapitulo.intro),
      nivel: capitulo.nivel,
      voz: voz,
      vozLigada: true,
      lenta: false,
      velocidade: velocidade,
      mostrarPt: true,
      reduzir: false,
    );

/// Roda o relógio do roteiro (sem widget) por [s] segundos.
void _rodar(RoteiroHistoria r, double s) {
  for (var t = 0.0; t < s; t += .05) {
    r.tick(.05);
  }
}

Future<void> _montar(WidgetTester t, VozIngles voz) async {
  await t.pumpWidget(MaterialApp(
    home: PlayerHistoria(capitulo: capitulo, parte: ParteDoCapitulo.intro, voz: voz),
  ));
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('velocidade', () {
    test('o 🐢 percorre 1 → .85 → .7 → .5 → 1 e a voz recebe o fator', () {
      final voz = _VozComFator();
      final r = _roteiro(voz)..tocar();
      expect(r.velocidade, 1.0);
      final vistas = <double>[];
      for (var i = 0; i < 4; i++) {
        r.alternarLenta();
        vistas.add(r.velocidade);
      }
      expect(vistas, [.85, .7, .5, 1.0]);
      r
        ..alternarLenta()
        ..alternarLenta()
        ..alternarLenta(); // .5
      r.repetir();
      _rodar(r, 3);
      expect(voz.falas.last.$2, .5);
      r.dispose();
    });

    test('mais devagar, a máquina de escrever também anda mais devagar', () {
      final normal = _roteiro(_VozComFator())..tocar();
      final lenta = _roteiro(_VozComFator(), velocidade: .5)..tocar();
      expect(lenta.letrasPorSegundo, closeTo(normal.letrasPorSegundo * .5, 1e-9));
      normal.dispose();
      lenta.dispose();
    });

    test('pref: sem nada salvo é 1×; a 🐢 antiga ligada vira .85×; salva e lê de volta', () async {
      expect(await ProgressoHistoria.velocidade(), 1.0);
      SharedPreferences.setMockInitialValues({ProgressoHistoria.chaveLenta: true});
      expect(await ProgressoHistoria.velocidade(), .85);
      await ProgressoHistoria.salvarVelocidade(.5);
      expect(await ProgressoHistoria.velocidade(), .5);
      await ProgressoHistoria.salvarVelocidade(.66);
      expect(await ProgressoHistoria.velocidade(), .7, reason: 'fora da lista → a mais perto');
    });

    test('a voz da história (com perfil) desce até .5×; o resto do app mantém o piso de sempre', () async {
      final pedidos = <double>[];
      final voz = VozIngles(falarComPerfil: (frase, v, perfil) async => pedidos.add(v));
      await voz.falarNoPlayer('Hello.', fator: .5, perfil: const PerfilVoz(tom: 1, variante: 0));
      expect(pedidos.single, closeTo(VozIngles.velocidadeNormal * .5, 1e-9));
    });
  });

  group('voltar', () {
    test('⏮ volta uma fala por vez, quantas vezes quiser (pula os passos mudos)', () {
      final r = _roteiro(_VozComFator())..tocar();
      // vai até a 4ª fala com texto ("Call me later!")
      r.irParaFala(3);
      expect(r.falaAtual?.en, 'Call me later!');
      r.voltar();
      expect(r.falaAtual?.en, 'I can hear you.');
      r.voltar();
      expect(r.falaAtual?.en, 'Type the word.', reason: 'pula o passo mudo do Mike');
      r.voltar();
      expect(r.falaAtual?.en, 'Hello, team!');
      r.voltar();
      expect((r.cena, r.passo), (0, 0), reason: 'na 1ª fala, recomeça');
      r.dispose();
    });

    test('no cartão final, ⏮ volta para a última fala; ⏭ vai para a próxima', () {
      final r = _roteiro(_VozComFator())..tocar();
      r.irParaFala(4);
      r.proximaFala();
      expect(r.estado, EstadoRoteiro.cartaoFinal);
      r.voltar();
      expect(r.falaAtual?.en, 'The race begins.');
      r.irParaFala(0);
      r.proximaFala();
      expect(r.falaAtual?.en, 'Type the word.');
      r.dispose();
    });

    testWidgets('barra: ⏮ e ← voltam; tocar nas bolinhas vai até a fala; 🐢 mostra a velocidade', (t) async {
      tela(t, const Size(1280, 720));
      final voz = _VozComFator();
      await _montar(t, voz);
      await avancar(t, 2.4);
      // vai até a última fala tocando na última bolinha
      final bolinhas = t.getRect(find.byKey(const Key('historia-bolinhas')));
      await t.tapAt(Offset(bolinhas.right - 10, bolinhas.center.dy));
      await avancar(t, 1.5);
      expect(find.text('The race begins.'), findsOneWidget);
      await t.tap(find.byKey(const Key('historia-voltar')));
      await avancar(t, 1.2);
      expect(find.text('Call me later!'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await avancar(t, 1.2);
      expect(find.text('I can hear you.'), findsOneWidget);
      expect(find.text('🐢1×'), findsOneWidget);
      await t.tap(find.byKey(const Key('historia-lenta')));
      await t.pump();
      expect(find.text('🐢.85×'), findsOneWidget);
      expect(await ProgressoHistoria.velocidade(), .85);
      await t.pumpWidget(Container());
    });

    testWidgets('celular 360: a barra cabe (sem ⏭, o resto inteiro)', (t) async {
      tela(t, const Size(360, 640));
      await _montar(t, _VozComFator());
      await avancar(t, 2.4);
      expect(t.takeException(), isNull);
      for (final k in ['historia-pausa', 'historia-pt', 'historia-voz', 'historia-lenta', 'historia-voltar', 'historia-repetir', 'historia-pular']) {
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
      expect(find.byKey(const Key('historia-proxima')), findsNothing);
      await t.pumpWidget(Container());
    });
  });
}
