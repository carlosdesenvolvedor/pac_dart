// Correções da revisão do desenho animado da história (English Turismo): Voltar no gate do "▶ Assistir"
// e no meio da cena (PopScope), fala sem `en` que não trava, quem sai fala primeiro e sai depois, o balão
// centrado em quem fala (rabicho certo), PT inteiro no celular com texto grande, contraste do chip, botões
// da barra sem estado de alternância falso e o aviso dos capítulos perdidos com os números certos.
// Só `pump(Duration)` (o relógio do player é um Ticker).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/som/sons.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/progresso_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/ator_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/balao_fala.dart';
import 'package:pac_dart/features/arcade/presentation/historia/elenco_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/galeria_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/player_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/roteiro_historia.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'historia_player_test.dart' show VozFake, abrirPelaRota, avancar, capitulo, montar, tela;

const _kimLonga = 'Update! A safe route has been shared with every team. Thank you, Team Star!';
const _kimLongaPt =
    'Atualização! Uma rota segura foi compartilhada com todas as equipes. Obrigada, Equipe Estrela!';

Map<String, dynamic> _cap(List<Map<String, dynamic>> falas, {List<Map<String, dynamic>>? elenco}) => {
      'pista': 1,
      'nivel': 'B1',
      'titulo': {'en': 'Review', 'pt': 'Revisão'},
      'resumo': 'Teste.',
      'palavras': [
        {'en': 'car', 'pt': 'carro'},
      ],
      'intro': [
        {
          'cenario': 'campina',
          'hora': 'dia',
          'clima': <String>[],
          'elenco': elenco ??
              [
                {'quem': 'voce', 'pos': 'esquerda'},
                {'quem': 'kim', 'pos': 'centro'},
                {'quem': 'max', 'pos': 'direita'},
              ],
          'objetos': <Object>[],
          'falas': falas,
        },
      ],
      'fim': [
        {
          'cenario': 'campina',
          'hora': 'tarde',
          'clima': <String>[],
          'elenco': [
            {'quem': 'voce', 'pos': 'esquerda'},
          ],
          'objetos': <Object>[],
          'falas': [
            {'quem': 'voce', 'en': 'Done.', 'pt': 'Pronto.'},
          ],
        },
      ],
      'gancho': {'en': 'Next?', 'pt': 'E agora?'},
    };

CapituloHistoria _capitulo(List<Map<String, dynamic>> falas, {bool estrito = true}) =>
    CapituloHistoria.fromJson(jsonDecode(jsonEncode(_cap(falas))) as Map<String, dynamic>, estrito: estrito);

Future<void> _montarCap(WidgetTester t, CapituloHistoria cap, {double textScale = 1}) async {
  await t.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: PlayerHistoria(capitulo: cap, parte: ParteDoCapitulo.intro, voz: VozFake()),
      ),
    ),
  ));
  await t.pump();
  await t.pump();
}

Future<bool> _ate(WidgetTester t, bool Function() achou, {double limite = 20}) async {
  for (var i = 0; i < limite * 20; i++) {
    if (achou()) return true;
    await t.pump(const Duration(milliseconds: 50));
    expect(t.takeException(), isNull);
  }
  return achou();
}

bool _mostra(String en) => find.text(en).evaluate().isNotEmpty;

/// O x (tela) da ponta do rabicho do balão.
double _pontaDoRabicho(WidgetTester t) {
  final balao = t.widget<BalaoFala>(find.byType(BalaoFala));
  final r = t.getRect(find.byKey(const Key('historia-balao')));
  return r.left + balao.alvoRabicho!.dx.clamp(10.0, r.width - 10);
}

/// O x (tela) da boca do ator [quem] (câmera incluída).
double _bocaNaTela(WidgetTester t, String quem) {
  final f = find.byKey(ValueKey('historia-ator-$quem'));
  final ator = t.widget<AtorHistoria>(f);
  final r = t.getRect(f);
  final larg = AtorHistoria.largura(ator.altura);
  final boca = AtorHistoria.boca(ator.altura).dx;
  return r.left + (ator.espelhado ? larg - boca : boca) * r.width / larg;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RoteiroHistoria.tocarSom = (_) {};
    VozIngles.falando.value = null;
  });
  tearDown(() {
    RoteiroHistoria.tocarSom = Sons.toca;
    VozIngles.falando.value = null;
  });

  group('Voltar do sistema', () {
    testWidgets('no gate do "▶ Assistir": sem exceção, voz parada e i1 gravado', (t) async {
      tela(t, const Size(1280, 720));
      final voz = VozFake()..liberado = false;
      final r = await abrirPelaRota(t, voz);
      expect(find.byKey(const Key('historia-assistir')), findsOneWidget);
      await t.binding.handlePopRoute();
      await avancar(t, .5);
      expect(t.takeException(), isNull);
      expect(r.fechou, isTrue);
      expect(r.fim, isNull);
      expect(voz.paradas, greaterThan(0));
      expect(await ProgressoHistoria.vistos(), contains('i1'));
    });

    testWidgets('desmontar no gate não lança no dispose', (t) async {
      tela(t, const Size(1280, 720));
      await montar(t, VozFake()..liberado = false);
      await t.pumpWidget(Container());
      expect(t.takeException(), isNull);
      expect(await ProgressoHistoria.vistos(), contains('i1'));
    });

    testWidgets('quem abriu a cena já lê o visto na volta e a voz para no pop (não só no dispose)', (t) async {
      tela(t, const Size(1280, 720));
      final voz = VozFake();
      Set<String>? lido;
      var paradasNaVolta = -1;
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await abrirCenaDaHistoria(context, capitulo: capitulo, parte: ParteDoCapitulo.fim, voz: voz);
                paradasNaVolta = voz.paradas;
                lido = await ProgressoHistoria.vistos();
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await avancar(t, 1.5);
      expect(find.byType(PlayerHistoria), findsOneWidget);
      await t.binding.handlePopRoute();
      await t.pump(const Duration(milliseconds: 1));
      expect(find.byType(PlayerHistoria), findsOneWidget, reason: 'ainda na transição de saída');
      expect(lido, contains('f1'), reason: 'o visto foi gravado no pop');
      expect(paradasNaVolta, greaterThan(0), reason: 'a voz parou antes de quem abriu continuar');
      await avancar(t, .5);
      expect(find.byType(PlayerHistoria), findsNothing);
      expect(t.takeException(), isNull);
    });
  });

  test('fala sem `en` (parse tolerante) não trava o roteiro em "falando"', () {
    final cap = _capitulo([
      {'quem': 'voce', 'en': 'Hi!', 'pt': 'Oi!'},
      {'quem': 'kim', 'pt': 'sem inglês'},
      {'quem': 'max', 'en': 'Go!', 'pt': 'Vai!', 'mudo': 'true'},
    ], estrito: false);
    final r = RoteiroHistoria(
      cenas: cap.intro,
      nivel: cap.nivel,
      voz: null,
      vozLigada: false,
      lenta: false,
      mostrarPt: true,
      reduzir: false,
    )..tocar();
    for (var i = 0; i < 600 && r.estado != EstadoRoteiro.cartaoFinal; i++) {
      r.tick(.05);
    }
    expect(r.estado, EstadoRoteiro.cartaoFinal);
    r.dispose();
  });

  group('quem sai fala primeiro', () {
    final falas = [
      {'quem': 'voce', 'en': 'Hi!', 'pt': 'Oi!'},
      {'quem': 'max', 'en': 'See you at the finish, rookie!', 'pt': 'Te vejo na chegada, novato!', 'acao': 'sai'},
      {'quem': 'voce', 'en': 'Wow.', 'pt': 'Uau.'},
    ];

    testWidgets('fica no palco com o balão e o rabicho; sai andando depois da leitura', (t) async {
      tela(t, const Size(1280, 720));
      await _montarCap(t, _capitulo(falas));
      expect(await _ate(t, () => _mostra('See you at the finish, rookie!')), isTrue);
      final max = find.byKey(const ValueKey('historia-ator-max'));
      expect(max, findsOneWidget, reason: 'falando, o Max ainda está no palco');
      expect(t.widget<BalaoFala>(find.byType(BalaoFala)).alvoRabicho, isNotNull);
      expect((_pontaDoRabicho(t) - _bocaNaTela(t, 'max')).abs(), lessThan(6));
      final xFalando = t.getRect(max).center.dx;
      // depois da leitura o balão fecha e ele sai andando
      expect(await _ate(t, () => !_mostra('See you at the finish, rookie!')), isTrue);
      expect(find.text('Wow.'), findsNothing, reason: 'a saída vem antes do próximo passo');
      await t.pump(const Duration(milliseconds: 300));
      expect(max, findsOneWidget);
      expect(t.getRect(max).center.dx, greaterThan(xFalando), reason: 'anda para a borda direita');
      expect(await _ate(t, () => _mostra('Wow.'), limite: 3), isTrue);
      expect(max, findsNothing, reason: 'saiu');
      await t.pumpWidget(Container());
    });

    test('roteiro: a saída conta depois da leitura e dura duracaoSaida', () {
      final cap = _capitulo(falas);
      final r = RoteiroHistoria(
        cenas: cap.intro,
        nivel: cap.nivel,
        voz: null,
        vozLigada: false,
        lenta: false,
        mostrarPt: true,
        reduzir: false,
      )..tocar();
      while (r.passo < 1) {
        r.tick(.05);
      }
      expect(r.duracaoEntrada, lessThan(.5), reason: 'o balão não espera a andança');
      while (r.tSaida == null) {
        expect(r.passo, 1);
        r.tick(.05);
      }
      expect(r.estado, EstadoRoteiro.lendo);
      var dt = 0.0;
      while (r.passo == 1) {
        r.tick(.05);
        dt += .05;
      }
      expect(dt, closeTo(RoteiroHistoria.duracaoSaida, .11));
      r.dispose();
    });
  });

  group('balão centrado em quem fala', () {
    for (final tam in [const Size(1280, 720), const Size(2560, 1080), const Size(360, 640)]) {
      testWidgets('${tam.width.toInt()}×${tam.height.toInt()}: rabicho na boca de quem está à esquerda e à direita',
          (t) async {
        tela(t, tam);
        await _montarCap(t, _capitulo([
          {'quem': 'voce', 'en': 'Hi!', 'pt': 'Oi!'},
          {'quem': 'max', 'en': 'Bye now!', 'pt': 'Tchau!'},
        ]));
        for (final (quem, en) in [('voce', 'Hi!'), ('max', 'Bye now!')]) {
          expect(await _ate(t, () => _mostra(en)), isTrue);
          await t.pump(const Duration(milliseconds: 700)); // a câmera assenta
          final boca = _bocaNaTela(t, quem);
          expect((_pontaDoRabicho(t) - boca).abs(), lessThan(6), reason: '$quem: a ponta do rabicho na boca');
          final r = t.getRect(find.byKey(const Key('historia-balao')));
          final presoNaBorda = r.left <= 9 || r.right >= tam.width - 9;
          if (!presoNaBorda) expect((r.center.dx - boca).abs(), lessThan(6), reason: '$quem: balão centrado');
        }
        await t.pumpWidget(Container());
      });
    }
  });

  testWidgets('360×640 com texto 1.6: o PT da fala mais longa cabe inteiro no balão', (t) async {
    tela(t, const Size(360, 640));
    await _montarCap(
      t,
      _capitulo([
        {'quem': 'kim', 'en': _kimLonga, 'pt': _kimLongaPt},
      ]),
      textScale: 1.6,
    );
    expect(await _ate(t, () => _mostra(_kimLongaPt)), isTrue);
    await t.tap(find.byKey(const Key('historia-avancar'))); // completa o texto
    await t.pump(const Duration(milliseconds: 300));
    final balao = t.getRect(find.byKey(const Key('historia-balao')));
    final pt = t.getRect(find.byKey(const Key('historia-balao-pt')));
    expect(balao.contains(pt.topLeft) && balao.contains(pt.bottomRight - const Offset(.01, .01)), isTrue,
        reason: 'PT $pt dentro do balão $balao');
    expect(balao.bottom, lessThan(t.getRect(find.byKey(const ValueKey('historia-ator-kim'))).top + 4),
        reason: 'o balão não cobre a cabeça');
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  test('chip do nome: o texto com mais contraste (≥ 4.4:1 em todo o elenco)', () {
    for (final quem in ['voce', 'mike', 'sarah', 'ana', 'ben', 'emma', 'lucas', 'julia', 'dra-lee', 'max', 'kim', 'narrador']) {
      final cor = ElencoTurismo.corDe(quem);
      final texto = BalaoFala.textoNoChip(cor);
      // a Kim (E84393) é a mais difícil: nenhum dos dois passa de 4.5; o escuro dá 4.45
      expect(BalaoFala.contraste(texto, cor), greaterThanOrEqualTo(4.4), reason: quem);
    }
    expect(BalaoFala.textoNoChip(const Color(0xFF7FB8E8)), isNot(Colors.white), reason: 'Dra. Lee: texto escuro');
  });

  // 🐢 deixou de ser liga/desliga: agora percorre as velocidades 1×/.85×/.7×/.5× (pedido do dono)
  testWidgets('barra: só PT e 🔊 têm estado de alternância', (t) async {
    tela(t, const Size(1280, 720));
    final h = t.ensureSemantics();
    await montar(t, VozFake());
    await avancar(t, 2.4);
    for (final k in ['historia-pausa', 'historia-repetir', 'historia-voltar', 'historia-proxima', 'historia-lenta']) {
      expect(t.getSemantics(find.byKey(Key(k))), isSemantics(isButton: true, hasToggledState: false), reason: k);
    }
    for (final k in ['historia-pt', 'historia-voz']) {
      expect(t.getSemantics(find.byKey(Key(k))), isSemantics(isButton: true, hasToggledState: true), reason: k);
    }
    final pausa = t.getSemantics(find.byKey(const Key('historia-pausa')));
    expect(pausa.label, 'Pausar (P)');
    expect(pausa.tooltip, isEmpty, reason: 'o tooltip não repete o rótulo');
    h.dispose();
    await t.pumpWidget(Container());
  });

  group('capítulos perdidos', () {
    test('texto com os números certos', () {
      expect(textoCapitulosPerdidos([10]), 'o capítulo 10');
      expect(textoCapitulosPerdidos([1, 2, 3, 4]), 'os capítulos 1 a 4');
      expect(textoCapitulosPerdidos([4, 7, 10]), 'os capítulos 4, 7 e 10');
      expect(textoCapitulosPerdidos([1, 2, 3, 7]), 'os capítulos 1 a 3 e 7');
      expect(textoCapitulosPerdidos([2, 3]), 'os capítulos 2 e 3');
    });

    testWidgets('quem só pulou o 10 lê "o capítulo 10"', (t) async {
      tela(t, const Size(1280, 720));
      final h = HistoriaTurismo(const TextoBilingue('The Golden Wheel', 'A Roda de Ouro'), [
        for (var k = 1; k <= 10; k++)
          CapituloHistoria.fromJson(jsonDecode(jsonEncode({..._cap(const []), 'pista': k})) as Map<String, dynamic>),
      ]);
      await t.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => abrirCapitulosPerdidos(context, historia: h, ate: 10, perdidos: const [10]),
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await t.tap(find.text('abrir'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('você ainda não viu o capítulo 10.'), findsOneWidget);
      await t.pumpWidget(Container());
    });
  });
}
