// Player do desenho animado da história do English Turismo (grupo C1): balão, PT, toque, voz com o perfil
// de cada personagem, passo mudo, falas remotas, Esc/Voltar, cartões finais, créditos, lip-sync, reduzir
// animações e tamanhos de tela. Só `pump(Duration)` (nada de pumpAndSettle: o relógio do player é um Ticker).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/som/sons.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/progresso_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/ator_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/balao_fala.dart';
import 'package:pac_dart/features/arcade/presentation/historia/creditos_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/player_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/props_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voz de teste (o mesmo jeito do `VozFake` de `ingles_cartoes_ui_test.dart`): guarda o que o player
/// mandou falar, com o perfil, e termina na hora.
class VozFake extends VozIngles {
  bool liberado = true;
  final falas = <(String, PerfilVoz?)>[];
  int paradas = 0;

  @override
  Future<FimDaFala> falarNoPlayer(String frase, {required double fator, PerfilVoz? perfil}) {
    falas.add((frase, perfil));
    return Future.value(FimDaFala.acabou);
  }

  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add((frase, null));
    return Future.value();
  }

  @override
  Future<void> parar() async => paradas++;

  @override
  bool get somLiberado => liberado;
}

const _capituloJson = '''
{
  "pista": 1,
  "nivel": "A1",
  "titulo": {"en": "Hello, Racer!", "pt": "Olá, piloto!"},
  "resumo": "Você chega, conhece o time e vira o piloto da equipe de fim de semana.",
  "palavras": [
    {"en": "car", "pt": "carro"},
    {"en": "team", "pt": "equipe"},
    {"en": "fast", "pt": "rápido"}
  ],
  "intro": [
    {
      "cenario": "campina", "hora": "dia", "clima": [],
      "elenco": [
        {"quem": "voce", "pos": "esquerda", "emocao": "feliz"},
        {"quem": "mike", "pos": "direita"}
      ],
      "objetos": [],
      "falas": [
        {"quem": "voce", "en": "Hello, team!", "pt": "Olá, equipe!", "acao": "acena"},
        {"quem": "mike", "mudo": true, "acao": "pula"},
        {"quem": "mike", "en": "Type the word.", "pt": "Digite a palavra.", "camera": "medio"}
      ]
    },
    {
      "cenario": "vale", "hora": "amanhecer", "clima": ["neblina"],
      "elenco": [
        {"quem": "voce", "pos": "centro", "segura": "radio"},
        {"quem": "ana", "pos": "direita", "segura": "celular"},
        {"quem": "mike", "remoto": "radio"},
        {"quem": "sarah", "remoto": "celular"}
      ],
      "objetos": [],
      "falas": [
        {"quem": "mike", "en": "I can hear you.", "pt": "Eu consigo te ouvir."},
        {"quem": "sarah", "en": "Call me later!", "pt": "Me liga depois!"},
        {"quem": "narrador", "en": "The race begins.", "pt": "A corrida começa."}
      ]
    }
  ],
  "fim": [
    {
      "cenario": "campina", "hora": "tarde", "clima": [],
      "elenco": [
        {"quem": "voce", "pos": "esquerda", "emocao": "radiante"},
        {"quem": "ben", "pos": "direita"}
      ],
      "objetos": [],
      "falas": [
        {"quem": "ben", "en": "You did it!", "pt": "Você conseguiu!", "acao": "palmas", "efeito": "confete"},
        {"quem": "voce", "en": "Thank you!", "pt": "Obrigado!", "acao": "comemora"}
      ]
    }
  ],
  "gancho": {"en": "But who is the driver in black?", "pt": "Mas quem é o piloto de preto?"}
}
''';

final capitulo = CapituloHistoria.fromJson(jsonDecode(_capituloJson) as Map<String, dynamic>);

/// As falas com texto da abertura, na ordem.
const _enIntro = ['Hello, team!', 'Type the word.', 'I can hear you.', 'Call me later!', 'The race begins.'];
const _quemIntro = ['voce', 'mike', 'mike', 'sarah', 'narrador'];

Future<void> avancar(WidgetTester t, double segundos, {int passoMs = 50}) async {
  final n = (segundos * 1000 / passoMs).ceil();
  for (var i = 0; i < n; i++) {
    await t.pump(Duration(milliseconds: passoMs));
  }
}

/// Bomba até [achou] (ou [limite] segundos), conferindo que nenhuma exceção (overflow incluído) apareceu.
Future<bool> ate(WidgetTester t, bool Function() achou, {double limite = 40, int passoMs = 50}) async {
  final n = (limite * 1000 / passoMs).ceil();
  for (var i = 0; i < n; i++) {
    if (achou()) return true;
    await t.pump(Duration(milliseconds: passoMs));
    expect(t.takeException(), isNull);
  }
  return achou();
}

bool temCartaoFinal() => find.byKey(const Key('historia-cartao-final')).evaluate().isNotEmpty;

void tela(WidgetTester t, Size s) {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// O app de teste: um botão que abre a cena pela rota de verdade e guarda o resultado.
class Resultado {
  bool fechou = false;
  FimDoPlayer? fim;
}

Future<Resultado> abrirPelaRota(
  WidgetTester t,
  VozFake voz, {
  ParteDoCapitulo parte = ParteDoCapitulo.intro,
  bool creditos = false,
  CapituloHistoria? cap,
}) async {
  final r = Resultado();
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              r.fim = await abrirCenaDaHistoria(context, capitulo: cap ?? capitulo, parte: parte, voz: voz, creditos: creditos);
              r.fechou = true;
            },
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  ));
  await t.tap(find.text('abrir'));
  await t.pump();
  await avancar(t, .4); // transição + prefs
  return r;
}

Future<void> montar(WidgetTester t, VozFake voz,
    {ParteDoCapitulo parte = ParteDoCapitulo.intro, bool creditos = false, double textScale = 1, bool reduzir = false}) async {
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: reduzir,
        ),
        child: PlayerHistoria(capitulo: capitulo, parte: parte, voz: voz, creditos: creditos),
      ),
    ),
  ));
  await t.pump();
  await t.pump();
}

Future<Set<String>> vistos() async => ProgressoHistoria.vistos();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  final sons = <Som>[];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    sons.clear();
    RoteiroHistoria.tocarSom = sons.add;
    VozIngles.falando.value = null;
  });
  tearDown(() {
    RoteiroHistoria.tocarSom = Sons.toca;
    VozIngles.falando.value = null;
  });

  testWidgets('o 1º balão mostra o inglês depois do cartão de título', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    // cartão de título
    expect(find.text('CHAPTER 1'), findsOneWidget);
    expect(find.byKey(const Key('historia-balao')), findsNothing);
    await avancar(t, 2.4);
    expect(find.byKey(const Key('historia-balao')), findsOneWidget);
    expect(find.text('Hello, team!'), findsOneWidget);
    final balao = t.widget<BalaoFala>(find.byType(BalaoFala));
    expect(balao.nome, 'Você');
    expect(balao.via, isNull);
    expect(balao.alvoRabicho, isNotNull, reason: 'o rabicho aponta para quem fala');
    expect(sons, contains(Som.tique), reason: 'balão novo faz tique');
    await t.pumpWidget(Container());
  });

  testWidgets('o PT aparece quando o inglês termina; T e o chip PT escondem e a escolha fica salva', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    await avancar(t, 2.35);
    // digitando: o PT ainda está transparente
    final pt = find.byKey(const Key('historia-balao-pt'));
    expect(pt, findsOneWidget);
    AnimatedOpacity opacidade() => t.widget<AnimatedOpacity>(find.ancestor(of: pt, matching: find.byType(AnimatedOpacity)));
    expect(opacidade().opacity, 0);
    await avancar(t, .8);
    expect(opacidade().opacity, 1);
    expect(find.text('Olá, equipe!'), findsOneWidget);

    await t.sendKeyEvent(LogicalKeyboardKey.keyT);
    await t.pump();
    expect(find.text('Olá, equipe!'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(ProgressoHistoria.chaveTraducao), isFalse);

    await t.tap(find.byKey(const Key('historia-pt')));
    await t.pump();
    expect(find.text('Olá, equipe!'), findsOneWidget);
    expect(prefs.getBool(ProgressoHistoria.chaveTraducao), isTrue);

    // um player novo já abre sem PT quando a escolha foi esconder
    await prefs.setBool(ProgressoHistoria.chaveTraducao, false);
    await t.pumpWidget(Container());
    await montar(t, VozFake());
    await avancar(t, 3.2);
    expect(find.text('Hello, team!'), findsOneWidget);
    expect(find.byKey(const Key('historia-balao-pt')), findsNothing);
    await t.pumpWidget(Container());
  });

  testWidgets('toque completa o texto e, completo, avança (o passo mudo não chama a voz)', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    await avancar(t, 2.5);
    final pt = find.byKey(const Key('historia-balao-pt'));
    double opacidade() => t.widget<AnimatedOpacity>(find.ancestor(of: pt, matching: find.byType(AnimatedOpacity))).opacity;
    expect(opacidade(), 0);
    await t.tap(find.byKey(const Key('historia-avancar')));
    await t.pump();
    expect(opacidade(), 1, reason: 'o 1º toque completa o texto');
    expect(find.text('Hello, team!'), findsOneWidget);

    await t.tap(find.byKey(const Key('historia-avancar')));
    await t.pump();
    expect(find.byKey(const Key('historia-balao')), findsNothing, reason: 'o 2º toque vai ao passo mudo');
    expect(voz.paradas, greaterThan(0), reason: 'avançar no toque corta a voz');
    expect(sons, contains(Som.blip), reason: 'o pula do passo mudo faz blip');
    final antes = voz.falas.length;
    await avancar(t, .6);
    expect(voz.falas.length, antes, reason: 'passo mudo não fala');
    expect(await ate(t, () => find.text('Type the word.').evaluate().isNotEmpty, limite: 1.5), isTrue);
    expect(voz.falas.length, antes + 1);
    await t.pumpWidget(Container());
  });

  testWidgets('a voz recebe os EN na ordem, cada um com o PerfilVoz do personagem', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    expect(await ate(t, temCartaoFinal), isTrue);
    expect(voz.falas.map((f) => f.$1).toList(), _enIntro);
    for (var i = 0; i < _enIntro.length; i++) {
      expect(voz.falas[i].$2, ElencoTurismo.perfilDeVoz(_quemIntro[i]), reason: _quemIntro[i]);
    }
    await t.pumpWidget(Container());
  });

  testWidgets('falas remotas: rádio com balão tracejado e celular com o rostinho de quem fala', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    expect(await ate(t, () => find.text('I can hear you.').evaluate().isNotEmpty), isTrue);
    var balao = t.widget<BalaoFala>(find.byType(BalaoFala));
    expect(balao.via, ViaRemota.radio);
    expect(balao.nome, 'Mike');
    expect(balao.alvoRabicho, isNotNull, reason: 'o balão sai do rádio de quem segura');
    // o rostinho da Sarah já está no celular da Ana (mesmo calada)
    final celular = find.byKey(const ValueKey('historia-celular-sarah'));
    expect(celular, findsOneWidget);
    expect((t.widget<CustomPaint>(celular).painter! as PropPainter).rosto, ElencoTurismo.de('sarah'));

    expect(await ate(t, () => find.text('Call me later!').evaluate().isNotEmpty), isTrue);
    balao = t.widget<BalaoFala>(find.byType(BalaoFala));
    expect(balao.via, ViaRemota.celular);
    expect(balao.nome, 'Sarah');
    // falando no celular: a boca do rostinho mexe (sem voz anunciada, pela trilha do texto)
    await avancar(t, .15);
    final p = t.widget<CustomPaint>(celular).painter! as PropPainter;
    expect(p.rosto, ElencoTurismo.de('sarah'));

    expect(await ate(t, () => find.byKey(const Key('historia-legenda')).evaluate().isNotEmpty), isTrue);
    expect(find.text('The race begins.'), findsOneWidget);
    expect(find.byType(BalaoFala), findsNothing, reason: 'o narrador usa a legenda');
    await t.pumpWidget(Container());
  });

  testWidgets('Esc → pulado e a abertura fica vista (i1)', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    final r = await abrirPelaRota(t, voz);
    expect(find.byType(PlayerHistoria), findsOneWidget);
    await avancar(t, 2.6);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await avancar(t, .5);
    expect(r.fechou, isTrue);
    expect(r.fim, FimDoPlayer.pulado);
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(await vistos(), contains('i1'));
    expect(await vistos(), isNot(contains('c1')));
  });

  testWidgets('o botão Pular ⏭ também pula', (t) async {
    tela(t, const Size(1280, 720));
    final r = await abrirPelaRota(t, VozFake());
    await t.tap(find.byKey(const Key('historia-pular')));
    await avancar(t, .5);
    expect(r.fim, FimDoPlayer.pulado);
    expect(await vistos(), contains('i1'));
  });

  testWidgets('Voltar do sistema → null e a abertura fica vista', (t) async {
    tela(t, const Size(1280, 720));
    final r = await abrirPelaRota(t, VozFake());
    await avancar(t, 1);
    final nav = t.state<NavigatorState>(find.byType(Navigator));
    nav.pop();
    await avancar(t, .5);
    expect(r.fechou, isTrue);
    expect(r.fim, isNull);
    await t.pump();
    expect(await vistos(), contains('i1'));
  });

  testWidgets('fim da abertura: cartão "Words from the story" + 🏁 Race! (Enter)', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    final r = await abrirPelaRota(t, voz);
    expect(await ate(t, temCartaoFinal), isTrue);
    expect(find.text('🔑 Words from the story'), findsOneWidget);
    for (final p in capitulo.palavras) {
      expect(find.byKey(Key('historia-palavra-${p.en}')), findsOneWidget);
      expect(find.text(p.pt), findsOneWidget);
    }
    expect(sons.last, Som.blip, reason: 'cartão final faz blip');
    // tocar numa palavra fala a palavra
    await t.tap(find.byKey(const Key('historia-palavra-team')));
    await t.pump();
    expect(voz.falas.last.$1, 'team');
    expect(find.byKey(const Key('historia-correr')), findsOneWidget);
    // relógio parado no cartão (depois do respingo do toque)
    await avancar(t, 1.5);
    expect(t.binding.hasScheduledFrame, isFalse);
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await avancar(t, .5);
    expect(r.fim, FimDoPlayer.assistido);
    final v = await vistos();
    expect(v, contains('i1'));
    expect(v, isNot(contains('c1')), reason: 'c1 é só da chegada');
  });

  testWidgets('chegada assistida: mostra o gancho e grava f1 + c1', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    final r = await abrirPelaRota(t, voz, parte: ParteDoCapitulo.fim);
    expect(await ate(t, temCartaoFinal), isTrue);
    expect(find.text('To be continued…'), findsOneWidget);
    expect(find.text('📖 But who is the driver in black?'), findsOneWidget);
    expect(find.text('Mas quem é o piloto de preto?'), findsOneWidget);
    expect(find.text('Próximo capítulo na pista 2'), findsOneWidget);
    expect(sons, contains(Som.fase), reason: 'confete/comemora fazem "fase"');
    await t.pump();
    expect(await vistos(), containsAll(['f1', 'c1']));
    await t.tap(find.byKey(const Key('historia-continuar')));
    await avancar(t, .5);
    expect(r.fim, FimDoPlayer.assistido);
  });

  testWidgets('chegada pulada: f1 sem c1', (t) async {
    tela(t, const Size(1280, 720));
    final r = await abrirPelaRota(t, VozFake(), parte: ParteDoCapitulo.fim);
    await avancar(t, 2.6);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await avancar(t, .5);
    expect(r.fim, FimDoPlayer.pulado);
    final v = await vistos();
    expect(v, contains('f1'));
    expect(v, isNot(contains('c1')));
  });

  testWidgets('creditos: true mostra THE END com fanfarra e conclui assistido', (t) async {
    tela(t, const Size(1280, 720));
    final r = await abrirPelaRota(t, VozFake(), parte: ParteDoCapitulo.fim, creditos: true);
    expect(await ate(t, () => find.text('THE END').evaluate().isNotEmpty), isTrue);
    expect(sons, contains(Som.fanfarra));
    expect(find.byKey(const Key('historia-pular')), findsNothing, reason: 'nos créditos a barra some');
    await avancar(t, 19); // a rolagem dos créditos acaba (sem laço infinito)
    expect(t.binding.hasScheduledFrame, isFalse);
    await t.tap(find.byKey(const Key('historia-concluir')));
    await avancar(t, .5);
    expect(r.fim, FimDoPlayer.assistido);
    expect(await vistos(), containsAll(['f1', 'c1']));
  });

  testWidgets('créditos: os rostos do elenco ficam numa coluna só (mesmo x), centrada como bloco', (t) async {
    for (final (s, escala) in [(const Size(1280, 720), 1.0), (const Size(360, 640), 1.6)]) {
      tela(t, s);
      await t.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: s, textScaler: TextScaler.linear(escala)),
          child: Material(child: CreditosHistoria(onFim: () {}, reduzir: true)),
        ),
      ));
      await t.pump();
      expect(t.takeException(), isNull);
      final coluna = find.byKey(const Key('historia-creditos-elenco'));
      final rostos = find.descendant(of: coluna, matching: find.byType(RostoPersonagem));
      final xs = {for (var i = 0; i < rostos.evaluate().length; i++) t.getTopLeft(rostos.at(i)).dx};
      expect(rostos, findsWidgets);
      expect(xs, hasLength(1), reason: 'sem zigue-zague em ${s.width}');
      final r = t.getRect(coluna);
      expect((r.center.dx - s.width / 2).abs(), lessThan(1), reason: 'o bloco fica no meio');
      await t.pumpWidget(Container());
    }
  });

  testWidgets('lip-sync: o falante segue a boca da voz; quem escuta fica com a boca parada', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    await avancar(t, 2.4);
    expect(find.text('Hello, team!'), findsOneWidget);
    VozIngles.falando.value = FalaEmCurso(
      frase: 'Hello, team!',
      boca: TrilhaBoca.compacta('0D 500X'),
      inicio: DateTime.now(),
    );
    await t.pump();
    final voce = t.widget<AtorHistoria>(find.byKey(const ValueKey('historia-ator-voce')));
    final mike = t.widget<AtorHistoria>(find.byKey(const ValueKey('historia-ator-mike')));
    expect(voce.visema, Visema.d);
    expect(mike.visema, Visema.x);
    expect(voce.pose.falando, isTrue);
    // a voz de outra frase não mexe a boca dele pela voz
    VozIngles.falando.value = FalaEmCurso(frase: 'Outra frase.', boca: TrilhaBoca.compacta('0D 500X'), inicio: DateTime.now());
    await t.pump();
    expect(t.widget<AtorHistoria>(find.byKey(const ValueKey('historia-ator-mike'))).visema, Visema.x);
    VozIngles.falando.value = null;
    await t.pumpWidget(Container());
  });

  testWidgets('pausa (P) congela o relógio e o balão; P de novo continua e fala de novo', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    await avancar(t, 2.4);
    await t.sendKeyEvent(LogicalKeyboardKey.keyP);
    await t.pump();
    expect(find.text('⏸ Pausado'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 100));
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'em pausa o relógio para');
    await t.pump(const Duration(seconds: 10));
    expect(find.text('Hello, team!'), findsOneWidget, reason: 'continua no mesmo passo');
    await t.tap(find.byKey(const Key('historia-pausa')));
    await t.pump();
    expect(find.text('⏸ Pausado'), findsNothing);
    expect(await ate(t, () => find.text('Type the word.').evaluate().isNotEmpty), isTrue);
    await t.pumpWidget(Container());
  });

  testWidgets('sem gesto do navegador: "▶ Assistir" antes de começar', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake()..liberado = false;
    await montar(t, voz);
    expect(find.byKey(const Key('historia-assistir')), findsOneWidget);
    await avancar(t, 3);
    expect(voz.falas, isEmpty);
    expect(t.binding.hasScheduledFrame, isFalse, reason: 'parado no gate, sem relógio');
    await t.tap(find.byKey(const Key('historia-assistir')));
    await t.pump();
    expect(find.byKey(const Key('historia-assistir')), findsNothing);
    expect(await ate(t, () => voz.falas.isNotEmpty), isTrue);
    expect(voz.falas.first.$1, 'Hello, team!');
    await t.pumpWidget(Container());
  });

  testWidgets('voz desligada (V): ninguém fala e o desenho segue sozinho', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz);
    await t.sendKeyEvent(LogicalKeyboardKey.keyV);
    await t.pump();
    expect((await SharedPreferences.getInstance()).getBool(ProgressoHistoria.chaveVoz), isFalse);
    expect(await ate(t, temCartaoFinal), isTrue);
    expect(voz.falas, isEmpty);
    await t.pumpWidget(Container());
  });

  testWidgets('reduzir animações: chega ao fim e não fica quadro pendente', (t) async {
    tela(t, const Size(1280, 720));
    final voz = VozFake();
    await montar(t, voz, reduzir: true);
    expect(await ate(t, temCartaoFinal, passoMs: 100), isTrue);
    expect(voz.falas.map((f) => f.$1).toList(), _enIntro);
    await t.pump(const Duration(milliseconds: 200));
    expect(t.binding.hasScheduledFrame, isFalse);
    await t.pumpWidget(Container());
  });

  testWidgets('turismo_tremor desligado também reduz (máquina de escrever instantânea)', (t) async {
    SharedPreferences.setMockInitialValues({'turismo_tremor': false});
    tela(t, const Size(1280, 720));
    await montar(t, VozFake());
    await avancar(t, 1.3);
    expect(find.text('Hello, team!'), findsOneWidget);
    final pt = find.byKey(const Key('historia-balao-pt'));
    expect(t.widget<AnimatedOpacity>(find.ancestor(of: pt, matching: find.byType(AnimatedOpacity))).opacity, 1);
    await t.pumpWidget(Container());
  });

  for (final (nome, tam, escala) in [
    ('360×640 com texto 1.6', const Size(360, 640), 1.6),
    ('390×844', const Size(390, 844), 1.0),
    ('1000×1400', const Size(1000, 1400), 1.0),
    ('2560×1080', const Size(2560, 1080), 1.0),
  ]) {
    testWidgets('$nome: abertura e chegada inteiras sem exceção nem overflow', (t) async {
      tela(t, tam);
      for (final parte in ParteDoCapitulo.values) {
        await montar(t, VozFake(), parte: parte, textScale: escala);
        expect(await ate(t, temCartaoFinal), isTrue);
        expect(t.takeException(), isNull);
        await t.pumpWidget(Container());
      }
    });
  }

  testWidgets('desmontar no meio da fala não deixa timer pendente', (t) async {
    tela(t, const Size(1280, 720));
    await montar(t, VozFake());
    await avancar(t, 2.5);
    await t.pumpWidget(Container());
    await montar(t, VozFake(), reduzir: true);
    await avancar(t, 1.5);
    await t.pumpWidget(Container());
  });
}
