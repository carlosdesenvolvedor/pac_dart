// 📖 English Turismo + história (grupo E): o campeonato de 30 pistas em 3 temporadas, a pista 11 liberada
// para quem já fechou a 10, a abertura do capítulo antes da corrida (uma vez, um player só, o teclado volta
// para a corrida), o 📖 do cartão, a galeria, a chegada 1,2 s depois do resultado (com tudo já gravado e
// cancelável), "📖 Auto" desligado, o aviso de capítulos perdidos, e o comportamento antigo sem opt-in e no
// Dart. Só `pump(Duration)`: o player tem um Ticker.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/data/engenheiro_gt.dart';
import 'package:pac_dart/features/arcade/data/historia_turismo_repo.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/domain/progresso_historia.dart';
import 'package:pac_dart/features/arcade/domain/turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/galeria_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/player_historia.dart';
import 'package:pac_dart/features/arcade/presentation/turismo_page.dart';
import 'package:pac_dart/features/arcade/presentation/voz_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ranking/data/ranking_repository.dart';
import 'package:pac_dart/features/ranking/domain/jogador_ranking.dart';
import 'package:pac_dart/features/ranking/presentation/ranking_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voz dos desenhos (o jeito do `VozFake` de `ingles_cartoes_ui_test.dart`): guarda e termina na hora.
class _VozFake extends VozIngles {
  final falas = <String>[];

  @override
  Future<FimDaFala> falarNoPlayer(String frase, {required double fator, PerfilVoz? perfil}) {
    falas.add(frase);
    return Future.value(FimDaFala.acabou);
  }

  @override
  Future<void> falar(String frase, {bool? lenta}) => Future.value();

  @override
  Future<void> parar() async {}

  @override
  bool get somLiberado => true;
}

/// A voz das palavras da corrida (muda nos testes).
class _Fala implements FalanteDoJogo {
  @override
  bool get liberado => true;
  @override
  void falar(String palavra) {}
  @override
  void parar() {}
}

/// A engenheira de bolso, sem rede.
class _Engenheira extends EngenheiroGt {
  @override
  Future<String> debrief(TelemetriaGt t) async => 'Boa corrida!';
}

/// O ranking sem rede: a escrita no Firestore fica pendente (offline, sem confirmação do servidor).
class _RankingTravado implements RankingRepository {
  final _pendente = Completer<void>();
  var chamadas = 0;

  void soltar() {
    if (!_pendente.isCompleted) _pendente.complete();
  }

  @override
  Future<void> somar(String uid, String apelido, Map<String, int> deltas) {
    chamadas++;
    return _pendente.future;
  }

  @override
  Future<bool> salvarRecordeArcade(String uid, String apelido, String jogo, int pontos) async => false;

  @override
  Future<List<JogadorRanking>> top({int limite = 100}) async => const [];
}

/// Um capítulo mínimo e válido: abertura e chegada com uma fala cada.
Map<String, dynamic> _cap(int pista, String titulo, {bool gancho = true}) => {
      'pista': pista,
      'nivel': pista <= 10 ? 'A1' : 'A2',
      'titulo': {'en': titulo, 'pt': 'Capítulo $pista'},
      'resumo': 'Resumo de teste do capítulo $pista da história.',
      'palavras': [
        {'en': 'car', 'pt': 'carro'},
        {'en': 'team', 'pt': 'equipe'},
        {'en': 'fast', 'pt': 'rápido'},
      ],
      'intro': [
        {
          'cenario': 'campina',
          'hora': 'dia',
          'elenco': [
            {'quem': 'voce', 'pos': 'esquerda'},
            {'quem': 'mike', 'pos': 'direita'},
          ],
          'falas': [
            {'quem': 'mike', 'en': 'Intro $pista begins.', 'pt': 'A abertura $pista começa.'},
          ],
        },
      ],
      'fim': [
        {
          'cenario': 'campina',
          'hora': 'tarde',
          'elenco': [
            {'quem': 'voce', 'pos': 'esquerda'},
            {'quem': 'ben', 'pos': 'direita'},
          ],
          'falas': [
            {'quem': 'ben', 'en': 'Arrival $pista is here.', 'pt': 'A chegada $pista chegou.'},
          ],
        },
      ],
      if (gancho) 'gancho': {'en': 'Who is the driver in black $pista?', 'pt': 'Quem é o piloto de preto $pista?'},
    };

const _titulo = {'en': 'The Golden Wheel', 'pt': 'A Roda de Ouro'};

/// As 3 partes (a: 1 e 2; b: 11; c: vazia) como os JSON do app.
final _partes = <Map<String, dynamic>>[
  {'versao': 2, 'parte': 'a', 'titulo': _titulo, 'capitulos': [_cap(1, 'Hello, Racer!'), _cap(2, 'The Driver in Black')]},
  {'versao': 2, 'parte': 'b', 'titulo': _titulo, 'capitulos': [_cap(11, 'An Old Map')]},
  {'versao': 2, 'parte': 'c', 'titulo': _titulo, 'capitulos': <Map<String, dynamic>>[]},
];

final _historia = HistoriaTurismo.dasPartes(_partes);

Widget _app(Widget home) => MaterialApp(theme: Mixart.tema(), home: home);

void _tela(WidgetTester t, [Size s = const Size(1000, 1400)]) {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<void> _pumps(WidgetTester t, int n, [int ms = 50]) async {
  for (var i = 0; i < n; i++) {
    await t.pump(Duration(milliseconds: ms));
  }
}

/// Rola a lista do campeonato até [f]: se ele ainda não foi construído, procura para cima e depois para
/// baixo; já construído (fora da tela), `ensureVisible`.
Future<void> _ver(WidgetTester t, Finder f) async {
  final lista = find.byType(Scrollable).first;
  for (final passo in [-300.0, 300.0]) {
    if (f.evaluate().isNotEmpty) break;
    try {
      await t.scrollUntilVisible(f, passo, scrollable: lista, maxScrolls: 40);
    } on StateError {
      // não estava nessa direção
    } on TestFailure {
      // idem
    }
  }
  await t.ensureVisible(f);
  await t.pump();
}

Future<void> _abrirCampeonato(WidgetTester t, Widget pagina) async {
  await t.pumpWidget(_app(pagina));
  await t.pump();
  await _pumps(t, 4, 20); // prefs, campeonato, vistos
}

/// O botão "Correr"/"Correr de novo" do cartão da pista [nome] (rolando até ele).
Future<Finder> _correrDe(WidgetTester t, String nome) async {
  await _ver(t, find.text(nome));
  final cartao = find.ancestor(of: find.text(nome), matching: find.byType(Opacity)).first;
  final botao = find.descendant(of: cartao, matching: find.byType(FilledButton));
  await t.ensureVisible(botao);
  await t.pump();
  return botao;
}

Future<void> _tocarCorrer(WidgetTester t, String nome) async {
  await t.tap(await _correrDe(t, nome));
  await t.pump();
  await _pumps(t, 6, 20);
}

Future<void> _largada(WidgetTester t) async {
  await t.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await t.pump();
}

/// Fecha o player com Esc (o player pega o foco depois de ler as prefs).
Future<void> _pularCena(WidgetTester t) async {
  await _pumps(t, 4, 50);
  await t.sendKeyEvent(LogicalKeyboardKey.escape);
  await t.pump();
  await _pumps(t, 8, 50); // a rota fecha (260 ms) e a corrida monta
}

/// O trecho já digitado da palavra do portal: o 1º pedaço de texto do `Text.rich` (digitado · letra da vez
/// · resto).
String? _digitado(InlineSpan span) {
  String? primeiro;
  span.visitChildren((s) {
    if (s is TextSpan && s.text != null) {
      primeiro = s.text;
      return false;
    }
    return true;
  });
  return primeiro;
}

const _setas = ['⬅ ESQUERDA', '⬆ MEIO', '➡ DIREITA'];

/// Modo setas: segura ↑ e vai para a faixa livre do portal da vez até a bandeirada.
Future<void> _correrAteOFim(WidgetTester t) async {
  await t.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
  for (var i = 0; i < 4000; i++) {
    if (find.text('🎧 RÁDIO DA EQUIPE · ENGENHEIRA DE PISTA').evaluate().isNotEmpty) break;
    final livre = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('FAIXA LIVRE'));
    final minha = find.byWidgetPredicate((w) => w is Text && (w.data ?? '').startsWith('sua faixa: '));
    if (livre.evaluate().isNotEmpty && minha.evaluate().isNotEmpty) {
      final texto = t.widget<Text>(livre).data!;
      final livres = [for (var k = 0; k < 3; k++) if (texto.contains(_setas[k])) k];
      final sua = t.widget<Text>(minha).data!;
      final atual = [for (var k = 0; k < 3; k++) if (sua.contains(_setas[k])) k].firstOrNull;
      if (atual != null && livres.isNotEmpty && !livres.contains(atual)) {
        final alvo = livres.reduce((a, b) => (a - atual).abs() <= (b - atual).abs() ? a : b);
        await t.sendKeyEvent(alvo < atual ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight);
      }
    }
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
  await t.pump();
  expect(find.text('🎧 RÁDIO DA EQUIPE · ENGENHEIRA DE PISTA'), findsOneWidget, reason: 'a corrida terminou');
}

/// O que falta digitar de uma palavra na tela (a letra da vez + o resto); null se ela não está lá.
String? _falta(WidgetTester t, Key chave) {
  final f = find.descendant(of: find.byKey(chave), matching: find.byType(RichText));
  final alvo = f.evaluate().isEmpty ? find.byKey(chave) : f;
  if (alvo.evaluate().isEmpty) return null;
  final w = t.widget(alvo.first);
  final span = w is RichText ? w.text : null;
  if (span == null) return null;
  final pedacos = <String>[];
  span.visitChildren((s) {
    if (s is TextSpan && s.text != null) pedacos.add(s.text!);
    return true;
  });
  return pedacos.length < 2 ? null : pedacos.skip(1).join();
}

/// Digitando: digita a palavra do portal (ou a de combustível) que estiver na tela até a bandeirada. O
/// texto vai pelo cliente de texto CONECTADO (`testTextInput`), então isto também prova que o campo da
/// corrida tem o foco.
Future<void> _digitarAteOFim(WidgetTester t) async {
  var texto = '';
  for (var i = 0; i < 3000; i++) {
    if (find.text('🎧 RÁDIO DA EQUIPE · ENGENHEIRA DE PISTA').evaluate().isNotEmpty) break;
    final falta = _falta(t, const Key('turismo-palavra-0')) ?? _falta(t, const Key('turismo-gas'));
    if (falta != null && falta.isNotEmpty) {
      if (texto.length > 150) {
        texto = '';
        t.testTextInput.enterText('');
        await t.pump();
      }
      texto += falta;
      t.testTextInput.enterText(texto);
    }
    await t.pump(const Duration(milliseconds: 100));
  }
  expect(find.text('🎧 RÁDIO DA EQUIPE · ENGENHEIRA DE PISTA'), findsOneWidget, reason: 'a corrida terminou');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  late _VozFake voz;

  setUp(() {
    SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true, 'turismo_tutorial_setas': true});
    VozDoJogo.falanteDeTeste = () => _Fala();
    voz = _VozFake();
    HistoriaTurismoRepo.limparCache();
  });
  tearDown(() {
    VozDoJogo.falanteDeTeste = null;
    Linguagem.atual = Linguagem.dart;
    HistoriaTurismoRepo.limparCache();
  });

  TurismoPage pagina({bool historia = true, bool carregar = false}) => TurismoPage(
        semente: 3,
        historia: historia ? _historia : null,
        carregarHistoria: carregar,
        vozHistoria: voz,
        engenheiro: _Engenheira(),
      );

  test('a fixture é válida no parse estrito (3 capítulos)', () {
    expect(_historia.capitulos.map((c) => c.pista), [1, 2, 11]);
  });

  testWidgets('inglês: MEDALHAS 0/30, 3 temporadas, troféus extras e a linha 📖 nos cartões liberados', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    await _abrirCampeonato(t, pagina());
    expect(find.text('0/30'), findsOneWidget, reason: 'MEDALHAS x/30');
    expect(find.textContaining('Campeonato de 30 pistas'), findsOneWidget);
    expect(find.textContaining('próximo capítulo'), findsOneWidget);
    expect(find.text('TROFÉUS · 0/15'), findsOneWidget, reason: '12 de sempre + 🌍 🏆 📖');
    expect(find.byKey(const Key('turismo-historia')), findsOneWidget);
    expect(find.text('📖 Auto'), findsOneWidget);
    for (final h in ['WORD GRAND TOUR (1–10)', 'WORLD TOUR (11–20)', 'LEGENDS (21–30)']) {
      await _ver(t, find.text(h));
      expect(find.text(h), findsOneWidget);
    }
    await _ver(t, find.text('Grande Final das Lendas'));
    expect(find.text('🔒 vença a pista 29 pra liberar'), findsOneWidget);
    // o capítulo só no cartão liberado (pista 1), sem repetir o nome da pista
    await _ver(t, find.text('Autódromo da Campina'));
    expect(find.text('📖 Chapter 1 · Hello, Racer!'), findsOneWidget);
    expect(find.text('📖 Chapter 2 · The Driver in Black'), findsNothing, reason: 'pista 2 trancada');
    expect(find.byKey(const Key('turismo-capitulo-1')), findsOneWidget);
    // a 2ª temporada recolhe no cabeçalho
    await _ver(t, find.text('WORLD TOUR (11–20)'));
    await t.tap(find.text('WORLD TOUR (11–20)'));
    await t.pump();
    expect(find.text('Pôr do Sol na Campina'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('Dart: MEDALHAS 0/10, sem temporadas e sem 📖 (mesmo com a história passada)', (t) async {
    _tela(t);
    await _abrirCampeonato(t, pagina(carregar: true));
    expect(find.text('0/10'), findsOneWidget);
    expect(find.text('TROFÉUS · 0/12'), findsOneWidget);
    expect(find.textContaining('WORD GRAND TOUR'), findsNothing);
    expect(find.byKey(const Key('turismo-historia')), findsNothing);
    expect(find.textContaining('📖 Chapter'), findsNothing);
    expect(find.text('Pôr do Sol na Campina'), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('quem fechou a 10 (pista_max 10 + tempo_10) encontra a 11 com "Correr" (e a tela rola até ela)',
      (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    SharedPreferences.setMockInitialValues({
      'turismo_tutorial_digitacao': true,
      'turismo_pista_max': 10,
      'turismo_tempo_10': 140.0,
      'turismo_medalha_10': 0,
    });
    await _abrirCampeonato(t, pagina());
    await _pumps(t, 10, 50); // a rolagem até o cartão da pista mais longe
    final rect = t.getRect(find.text('Pôr do Sol na Campina'));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.bottom, lessThanOrEqualTo(1400), reason: 'rolou até o cartão da 11');
    final cartao = find.ancestor(of: find.text('Pôr do Sol na Campina'), matching: find.byType(Opacity)).first;
    expect(find.descendant(of: cartao, matching: find.text('Correr')), findsOneWidget);
    expect(find.descendant(of: cartao, matching: find.text('📖 Chapter 11 · An Old Map')), findsOneWidget);
    expect(find.text('🔒 vença a pista 11 pra liberar'), findsOneWidget, reason: 'a 12 continua trancada');
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  for (final tam in [const Size(390, 844), const Size(1280, 720)]) {
    testWidgets('${tam.width.toInt()}×${tam.height.toInt()}: ao abrir, rola até o cartão da pista mais longe (D20)',
        (t) async {
      Linguagem.atual = Linguagem.ingles;
      _tela(t, tam);
      SharedPreferences.setMockInitialValues({
        'turismo_tutorial_digitacao': true,
        'turismo_pista_max': 10,
        'turismo_tempo_10': 140.0,
        'turismo_medalha_10': 0,
      });
      await _abrirCampeonato(t, pagina());
      await _pumps(t, 12, 50);
      final rect = t.getRect(find.text('Pôr do Sol na Campina'));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(tam.height), reason: 'rolou até o cartão da 11');
      expect(t.takeException(), isNull);
      await t.pumpWidget(Container());
    });
  }

  testWidgets('"Correr" abre a abertura; Esc → contagem e a 1ª letra chega ao motor; 2ª vez não abre', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    await _abrirCampeonato(t, pagina());
    await _tocarCorrer(t, 'Autódromo da Campina');
    expect(find.byType(PlayerHistoria), findsOneWidget);
    expect(find.byType(ContagemRegressiva), findsNothing, reason: 'a corrida só monta depois da cena');
    await _pumps(t, 80, 50); // o cartão do título (1,8 s) e a 1ª fala
    expect(voz.falas, contains('Intro 1 begins.'));

    await _pularCena(t);
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.byType(ContagemRegressiva), findsOneWidget);
    expect((await ProgressoHistoria.vistos()), contains('i1'));

    // o teclado volta para a corrida: o campo de teclas novo tem o foco e a 1ª letra chega ao motor
    await _largada(t);
    await t.pump(const Duration(milliseconds: 40));
    final campo = t.widget<EditableText>(find.byType(EditableText));
    expect(campo.focusNode.hasFocus, isTrue, reason: 'o foco voltou para o campo da corrida');
    final palavra = find.descendant(of: find.byKey(const Key('turismo-palavra-0')), matching: find.byType(RichText));
    final w = t.widget<RichText>(palavra).text.toPlainText();
    t.testTextInput.enterText(w[0]);
    await t.pump();
    expect(_digitado(t.widget<RichText>(palavra).text), w[0], reason: 'a 1ª letra entrou no portal');

    // sai e corre de novo: a abertura já foi vista
    await t.tap(find.byTooltip('Pausar (Esc)'));
    await t.pump();
    await t.tap(find.text('Sair do jogo'));
    await t.pump();
    await _pumps(t, 4, 20);
    await _tocarCorrer(t, 'Autódromo da Campina');
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.byType(ContagemRegressiva), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('toque duplo em "Correr" abre UM player só', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    await _abrirCampeonato(t, pagina());
    final ponto = t.getCenter(await _correrDe(t, 'Autódromo da Campina'));
    await t.tapAt(ponto);
    await t.tapAt(ponto);
    await t.pump();
    await _pumps(t, 10, 20);
    expect(find.byType(PlayerHistoria), findsOneWidget);
    await _pularCena(t);
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.byType(ContagemRegressiva), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('o 📖 do cartão reabre a abertura (sem correr) e "📖 História" abre a galeria', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    SharedPreferences.setMockInitialValues({
      'turismo_tutorial_digitacao': true,
      ProgressoHistoria.chaveVistos: ['i1'],
    });
    await _abrirCampeonato(t, pagina());
    final cap1 = find.byKey(const Key('turismo-capitulo-1'));
    await _ver(t, cap1);
    await t.tap(cap1);
    await t.pump();
    await _pumps(t, 6, 20);
    expect(find.byType(PlayerHistoria), findsOneWidget, reason: 'mesmo já vista, o botão reabre');
    await _pularCena(t);
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.byType(ContagemRegressiva), findsNothing, reason: 'o 📖 do cartão não corre');
    expect(find.byType(ListView), findsOneWidget, reason: 'de volta ao campeonato (a corrida não tem lista)');

    final galeria = find.byKey(const Key('turismo-historia'));
    await _ver(t, galeria);
    await t.tap(galeria);
    await t.pump();
    await _pumps(t, 8, 50);
    expect(find.byType(GaleriaHistoriaPage), findsOneWidget);
    expect(find.byKey(const Key('galeria-capitulo-1')), findsOneWidget);
    expect(find.text('🔒 chegue à pista 2'), findsOneWidget);
    await t.pageBack();
    await t.pump();
    await t.pump(const Duration(seconds: 1)); // a transição de volta da rota
    await _pumps(t, 8, 50);
    expect(find.byType(GaleriaHistoriaPage), findsNothing);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('chegada: o overlay primeiro, tudo gravado, e o player 1,2 s depois; "Rever final" depois', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t, const Size(800, 1100));
    SharedPreferences.setMockInitialValues({
      'turismo_modo': true,
      'turismo_tutorial_setas': true,
      ProgressoHistoria.chaveVistos: ['i1'],
    });
    await _abrirCampeonato(t, pagina());
    await _tocarCorrer(t, 'Autódromo da Campina');
    expect(find.byType(PlayerHistoria), findsNothing, reason: 'a abertura 1 já foi vista');
    await _largada(t);
    await _correrAteOFim(t);

    // o resultado aparece primeiro, com o gancho e o botão da chegada; o player ainda não
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.text('📖 To be continued: Who is the driver in black 1?'), findsOneWidget);
    expect(find.text('📖 Continue a história'), findsOneWidget);
    // e tudo já foi gravado ANTES da cena: registro, estatísticas e moedas
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getDouble('turismo_tempo_1'), isNotNull);
    expect(prefs.getString('turismo_stats'), isNotNull);
    expect(prefs.getInt('turismo_pista_max'), 2);
    final moedas = find.textContaining('🪙 +');
    final ganhas = int.parse(t.widget<Text>(moedas.first).data!.split('+').last);
    if (ganhas > 0) expect(prefs.getInt('turismo_moedas'), ganhas);

    await t.pump(const Duration(milliseconds: 1100));
    expect(find.byType(PlayerHistoria), findsNothing, reason: 'antes de 1,2 s, nada');
    await t.pump(const Duration(milliseconds: 200));
    await t.pump();
    await _pumps(t, 6, 50);
    final player = t.widget<PlayerHistoria>(find.byType(PlayerHistoria));
    expect(player.parte, ParteDoCapitulo.fim);
    expect(player.capitulo.pista, 1);
    expect(player.creditos, isFalse);
    await _pularCena(t);
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(await ProgressoHistoria.vistos(), contains('f1'));
    expect(find.text('📖 Rever final'), findsOneWidget);
    // de novo pelo botão
    await t.tap(find.byKey(const Key('turismo-continuar-historia')));
    await t.pump();
    await _pumps(t, 6, 50);
    expect(find.byType(PlayerHistoria), findsOneWidget);
    await _pularCena(t);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('digitando: a chegada pega o teclado (Esc fecha) e "Próxima pista" abre a abertura 2', (t) async {
    Linguagem.atual = Linguagem.ingles;
    // 1000 px: a 800 px o cabeçalho da corrida (CabecalhoJogo com 🎥/⏸) já vaza 39 px no inglês digitando
    _tela(t);
    SharedPreferences.setMockInitialValues({
      'turismo_tutorial_digitacao': true,
      ProgressoHistoria.chaveVistos: ['i1'],
    });
    await _abrirCampeonato(t, pagina());
    await _tocarCorrer(t, 'Autódromo da Campina');
    await _largada(t);
    await _digitarAteOFim(t);
    await t.pump(const Duration(milliseconds: 1300));
    await _pumps(t, 6, 50);
    expect(t.widget<PlayerHistoria>(find.byType(PlayerHistoria)).parte, ParteDoCapitulo.fim);
    // o campo invisível da corrida (ainda na árvore, sob o overlay) não rouba o teclado do desenho
    await _pularCena(t);
    expect(find.byType(PlayerHistoria), findsNothing, reason: 'o Esc chegou ao player');

    // "Próxima pista" (do overlay, com o campo da corrida ainda lá): a abertura 2, e o Esc dela também vale
    final proxima = find.text('Próxima pista →');
    await t.ensureVisible(proxima);
    await t.tap(proxima);
    await t.pump();
    await _pumps(t, 6, 50);
    expect(t.widget<PlayerHistoria>(find.byType(PlayerHistoria)).capitulo.pista, 2);
    await _pularCena(t);
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.byType(ContagemRegressiva), findsOneWidget);
    await _largada(t);
    await t.pump(const Duration(milliseconds: 40));
    expect(t.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus, isTrue,
        reason: 'o campo novo da corrida 2 pegou o foco');
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('chegada: "Campeonato" antes de 1,2 s cancela a cena', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t, const Size(800, 1100));
    SharedPreferences.setMockInitialValues({
      'turismo_modo': true,
      'turismo_tutorial_setas': true,
      ProgressoHistoria.chaveVistos: ['i1'],
    });
    await _abrirCampeonato(t, pagina());
    await _tocarCorrer(t, 'Autódromo da Campina');
    await _largada(t);
    await _correrAteOFim(t);
    await t.pump(const Duration(milliseconds: 500));
    final sair = find.widgetWithText(OutlinedButton, 'Campeonato');
    await t.ensureVisible(sair);
    await t.tap(sair);
    await t.pump();
    await _pumps(t, 40, 50);
    expect(find.byType(PlayerHistoria), findsNothing, reason: 'o timer foi cancelado');
    expect(find.byType(ListView), findsOneWidget, reason: 'de volta ao campeonato (a corrida não tem lista)');
    expect(await ProgressoHistoria.vistos(), isNot(contains('f1')));
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('chegada: outra rota por cima (o treino das teimosas, um diálogo) antes de 1,2 s → nada abre', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t, const Size(800, 1100));
    SharedPreferences.setMockInitialValues({
      'turismo_modo': true,
      'turismo_tutorial_setas': true,
      ProgressoHistoria.chaveVistos: ['i1'],
    });
    await _abrirCampeonato(t, pagina());
    await _tocarCorrer(t, 'Autódromo da Campina');
    await _largada(t);
    await _correrAteOFim(t);
    await t.pump(const Duration(milliseconds: 300));
    Navigator.of(t.element(find.byType(TurismoPage))).push(MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('outra tela')),
        ));
    await t.pump();
    await _pumps(t, 40, 50);
    expect(find.byType(PlayerHistoria), findsNothing, reason: 'a chegada não abre por cima de outra rota');
    expect(find.text('outra tela'), findsOneWidget);
    expect(await ProgressoHistoria.vistos(), isNot(contains('f1')));
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('chegada: o ranking (rede) travado não segura a cena nem os troféus', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t, const Size(800, 1100));
    SharedPreferences.setMockInitialValues({
      'turismo_modo': true,
      'turismo_tutorial_setas': true,
      ProgressoHistoria.chaveVistos: ['i1'],
    });
    final repo = _RankingTravado();
    final cubit = RankingCubit(repo: repo, uid: 'u1', apelido: 'carlos');
    await t.pumpWidget(BlocProvider.value(value: cubit, child: _app(pagina())));
    await t.pump();
    await _pumps(t, 4, 20);
    await _tocarCorrer(t, 'Autódromo da Campina');
    await _largada(t);
    await _correrAteOFim(t);
    await _pumps(t, 2, 20);
    expect(repo.chamadas, 1, reason: 'o ranking foi chamado (e ficou sem resposta)');
    expect(find.text('🏆 TROFÉU NOVO'), findsWidgets, reason: 'os troféus da 1ª corrida aparecem mesmo assim');
    await t.pump(const Duration(milliseconds: 1300));
    await _pumps(t, 6, 50);
    expect(t.widget<PlayerHistoria>(find.byType(PlayerHistoria)).parte, ParteDoCapitulo.fim);
    await _pularCena(t);
    repo.soltar();
    await t.pump();
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
    await cubit.close();
  });

  testWidgets('"📖 Manual": nada abre sozinho (nem abertura, nem chegada); o botão ainda abre', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t, const Size(800, 1100));
    SharedPreferences.setMockInitialValues({
      'turismo_modo': true,
      'turismo_tutorial_setas': true,
      ProgressoHistoria.chaveAuto: false,
    });
    await _abrirCampeonato(t, pagina());
    expect(find.text('📖 Manual'), findsOneWidget);
    await _tocarCorrer(t, 'Autódromo da Campina');
    expect(find.byType(PlayerHistoria), findsNothing);
    expect(find.byType(ContagemRegressiva), findsOneWidget);
    await _largada(t);
    await _correrAteOFim(t);
    await _pumps(t, 40, 50);
    expect(find.byType(PlayerHistoria), findsNothing);
    await t.tap(find.byKey(const Key('turismo-continuar-historia')));
    await t.pump();
    await _pumps(t, 6, 50);
    expect(find.byType(PlayerHistoria), findsOneWidget);
    await _pularCena(t);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('celular 360: campeonato com temporadas e o overlay de fim com a história, sem vazar', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t, const Size(360, 780));
    SharedPreferences.setMockInitialValues({
      'turismo_modo': true,
      'turismo_tutorial_setas': true,
      'turismo_pista_max': 11,
      'turismo_tempo_10': 140.0,
      ProgressoHistoria.chaveVistos: ['i1'],
      ProgressoHistoria.chavePerdidos: true,
    });
    await _abrirCampeonato(t, pagina());
    await _pumps(t, 10, 50);
    await _ver(t, find.text('Pôr do Sol na Campina'));
    expect(find.byKey(const Key('turismo-capitulo-11')), findsOneWidget);
    expect(t.takeException(), isNull);
    await _tocarCorrer(t, 'Autódromo da Campina');
    await _largada(t);
    await _correrAteOFim(t);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('turismo-continuar-historia')), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pump(const Duration(milliseconds: 1000));
    await _pumps(t, 6, 50);
    expect(find.byType(PlayerHistoria), findsOneWidget);
    await _pularCena(t);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('"📖 Auto" alterna e fica salvo', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    await _abrirCampeonato(t, pagina());
    await t.tap(find.byKey(const Key('turismo-historia-auto')));
    await t.pump();
    expect(find.text('📖 Manual'), findsOneWidget);
    expect(await ProgressoHistoria.auto(), isFalse);
    await t.pumpWidget(Container());
  });

  testWidgets('aviso de capítulos perdidos ao correr a 11 sem ter visto 1–10 (uma vez só)', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    SharedPreferences.setMockInitialValues({
      'turismo_tutorial_digitacao': true,
      'turismo_pista_max': 11,
      'turismo_tempo_10': 140.0,
    });
    await _abrirCampeonato(t, pagina());
    await _tocarCorrer(t, 'Pôr do Sol na Campina');
    expect(find.text('📖 Capítulos perdidos'), findsOneWidget);
    expect(find.byType(PlayerHistoria), findsNothing);
    await t.tap(find.byKey(const Key('perdidos-seguir')));
    await t.pump();
    await _pumps(t, 8, 50);
    expect(find.byType(PlayerHistoria), findsOneWidget, reason: '"Seguir": a abertura da 11');
    expect(t.widget<PlayerHistoria>(find.byType(PlayerHistoria)).capitulo.pista, 11);
    await _pularCena(t);
    expect(find.byType(ContagemRegressiva), findsOneWidget);
    await _largada(t);

    // de volta ao campeonato: a pista 2 (abertura ainda não vista, 1 também não) não avisa de novo
    await t.tap(find.byTooltip('Pausar (Esc)'));
    await t.pump();
    await t.tap(find.text('Sair do jogo'));
    await t.pump();
    await _pumps(t, 4, 20);
    await _tocarCorrer(t, 'Circuito do Deserto');
    expect(find.text('📖 Capítulos perdidos'), findsNothing, reason: 'o aviso é uma vez só');
    expect(find.byType(PlayerHistoria), findsOneWidget);
    await _pularCena(t);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  testWidgets('capítulos perdidos → "Ver do começo" abre a galeria e não corre', (t) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(t);
    SharedPreferences.setMockInitialValues({
      'turismo_tutorial_digitacao': true,
      'turismo_pista_max': 2,
    });
    await _abrirCampeonato(t, pagina());
    await _tocarCorrer(t, 'Circuito do Deserto');
    await t.tap(find.byKey(const Key('perdidos-comeco')));
    await t.pump();
    await _pumps(t, 8, 50);
    expect(find.byType(GaleriaHistoriaPage), findsOneWidget);
    expect(find.byType(PlayerHistoria), findsNothing);
    await t.pageBack();
    await t.pump();
    await t.pump(const Duration(seconds: 1));
    expect(find.byType(GaleriaHistoriaPage), findsNothing);
    expect(find.byType(ContagemRegressiva), findsNothing);
    expect(find.byType(ListView), findsOneWidget, reason: 'de volta ao campeonato (a corrida não tem lista)');
    expect(await ProgressoHistoria.perdidosAvisado(), isTrue);
    expect(t.takeException(), isNull);
    await t.pumpWidget(Container());
  });

  group('carregamento dos JSON (canal de assets falso)', () {
    late List<String> pedidos;

    void servirAssets(WidgetTester t) {
      pedidos = [];
      t.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (msg) async {
        final chave = utf8.decode(msg!.buffer.asUint8List(msg.offsetInBytes, msg.lengthInBytes));
        final i = HistoriaTurismoRepo.arquivos.indexOf(chave);
        if (i >= 0) {
          pedidos.add(chave);
          return ByteData.sublistView(utf8.encode(jsonEncode(_partes[i])));
        }
        return null;
      });
      addTearDown(() => t.binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', null));
    }

    testWidgets('inglês com carregarHistoria: lê os 3 JSON e os cartões ganham o 📖', (t) async {
      Linguagem.atual = Linguagem.ingles;
      _tela(t);
      servirAssets(t);
      await _abrirCampeonato(t, pagina(historia: false, carregar: true));
      await _pumps(t, 6, 20);
      expect(pedidos, HistoriaTurismoRepo.arquivos);
      expect(find.byKey(const Key('turismo-historia')), findsOneWidget, reason: 'a galeria aparece quando a história chega');
      await _ver(t, find.text('Autódromo da Campina'));
      expect(find.text('📖 Chapter 1 · Hello, Racer!'), findsOneWidget);
      await t.pumpWidget(Container());
    });

    testWidgets('Dart com carregarHistoria: true não carrega nada', (t) async {
      _tela(t);
      servirAssets(t);
      await _abrirCampeonato(t, pagina(historia: false, carregar: true));
      await _pumps(t, 6, 20);
      expect(pedidos, isEmpty);
      await _tocarCorrer(t, 'Autódromo da Campina');
      expect(find.byType(PlayerHistoria), findsNothing);
      expect(find.byType(ContagemRegressiva), findsOneWidget);
      expect(pedidos, isEmpty);
      await t.pumpWidget(Container());
    });

    testWidgets('inglês sem opt-in (sem história e carregarHistoria:false): o comportamento de antes', (t) async {
      Linguagem.atual = Linguagem.ingles;
      _tela(t);
      servirAssets(t);
      await _abrirCampeonato(t, pagina(historia: false));
      await _pumps(t, 6, 20);
      expect(pedidos, isEmpty);
      expect(find.byKey(const Key('turismo-historia')), findsNothing);
      expect(find.byKey(const Key('turismo-historia-auto')), findsNothing);
      expect(find.textContaining('📖 Chapter'), findsNothing);
      expect(find.text('0/30'), findsOneWidget, reason: 'as 30 pistas valem no inglês, com ou sem história');
      await _tocarCorrer(t, 'Autódromo da Campina');
      expect(find.byType(PlayerHistoria), findsNothing);
      expect(find.byType(ContagemRegressiva), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(Container());
    });
  });

  test('pistasTurismo: a página usa 30 no inglês e as 10 de sempre no Dart', () {
    expect(pistasTurismo(ingles: true), hasLength(30));
    expect(identical(pistasTurismo(ingles: false), pistasGt), isTrue);
  });
}
