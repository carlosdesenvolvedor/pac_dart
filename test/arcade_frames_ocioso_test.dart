import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/personagem.dart';
import 'package:pac_dart/features/arcade/presentation/corrida_page.dart';
import 'package:pac_dart/features/arcade/presentation/missao_page.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/avatares.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/campo_teclas.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/ranking/presentation/ranking_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// No navegador (CanvasKit) cada frame redesenha a tela inteira: o que fica
/// parado na tela (menu, pausa, fim, cena esperando) não pode pedir frame.
class _RepoFake implements RankingRepository {
  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) async {}

  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => false;

  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

Widget _app(RankingCubit cubit, Widget home) => BlocProvider.value(
      value: cubit,
      child: MaterialApp(theme: Mixart.tema(), home: home),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  SharedPreferences.setMockInitialValues({});

  testWidgets('Pac3D parado (animado: false) não pede frame; mastigando pede', (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: AvatarPersonagem(tamanho: 40, personagem: Personagem.pac, animado: false)),
    ));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // volta a mastigar…
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: AvatarPersonagem(tamanho: 40, personagem: Personagem.pac)),
    ));
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    // …e para de novo (boca semiaberta, nada agendado)
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: AvatarPersonagem(tamanho: 40, personagem: Personagem.pac, animado: false)),
    ));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);

    // TickerMode desligado também congela o Pac mastigando
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: TickerMode(
        enabled: false,
        child: Center(child: AvatarPersonagem(tamanho: 40, personagem: Personagem.pac)),
      ),
    ));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('CampoTeclas: o campo invisível não pisca cursor', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: CampoTeclas(onChar: (_) {}))));
    await tester.pump();
    expect(tester.widget<EditableText>(find.byType(EditableText)).showCursor, isFalse);
  });

  testWidgets('Lógica Animada: prevendo, a cena fica parada (pumpAndSettle termina)', (tester) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(
      cubit,
      const MissaoPage(trilhaIdx: 0, trilhaNome: 'Fundamentos', trilhaEmoji: '🌱', indiceInicial: 0),
    ));
    await tester.pump();
    await tester.pump();
    expect(find.text('ATO 1 · PREVEJA'), findsOneWidget);
    // com o Pac mastigando sem parar, isto estourava o tempo
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });

  testWidgets('Corrida pausada: nada embaixo da pausa pede frame', (tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final cubit = RankingCubit(repo: _RepoFake(), uid: 'u1', apelido: 'carlos');
    await tester.pumpWidget(_app(cubit, const CorridaPage(semente: 9)));
    await tester.pump();
    await tester.tap(find.text('Difícil'));
    await tester.pump();
    await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
    await tester.pump();

    // correndo: o Pac mastiga e o relógio da CPU anda
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('PAUSADO'), findsOneWidget);
    // deixa as animações de uma vez só (entrada do overlay) terminarem
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    expect(tester.binding.hasScheduledFrame, isFalse);

    // retomou: tudo volta a andar
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('PAUSADO'), findsNothing);
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(Container());
    await tester.runAsync(cubit.close);
  });
}
