// 🎬 A cena da historinha no lugar do rosto, na lição de inglês de verdade (o PalcoIngles com o CursoBloc e o
// TypingBloc): a 1ª frase já com a cena, avançar leva à âncora da frase nova, a chave "🎬 Cena / 🙂 Rosto" troca
// e salva sem tirar o foco da frase, trilha própria fica com o rosto, a autoral que demora (400 ms) e o índice
// fora do ar caem na automática, os tamanhos no celular (com e sem teclado) e no computador, e o ensaio na frente.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/ingles/data/historias_licoes_repo.dart';
import 'package:pac_dart/features/ingles/data/preferencia_cena_licao.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historias_licoes.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart' show chaveDaFrase;
import 'package:pac_dart/features/ingles/presentation/palco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/cena_da_frase.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/ensaio_mental.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/traducao_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Os arquivos de verdade (assets/), lidos do disco: [faltando] falha, [presos] nunca respondem.
class _Disco extends CachingAssetBundle {
  _Disco({this.faltando = const {}, this.presos = const {}});
  final Set<String> faltando, presos;

  @override
  Future<ByteData> load(String key) async {
    if (presos.contains(key)) return Completer<ByteData>().future;
    if (faltando.contains(key)) throw StateError('asset $key ausente');
    return ByteData.sublistView(File(key).readAsBytesSync());
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final b = await load(key);
    return utf8.decode(b.buffer.asUint8List(b.offsetInBytes, b.lengthInBytes));
  }
}

final _curriculo = (jsonDecode(File('assets/ingles/curriculo.json').readAsStringSync()) as List)
    .map((e) => Trilha.fromJson(e as Map<String, dynamic>))
    .toList();

/// A 1ª trilha do curso (primeiro-contato, com história autoral) e um texto colado (trilha própria).
final _trilhas = [
  _curriculo.first,
  const Trilha(nivel: 'Minha viagem', emoji: '📝', textoId: 't1', licoes: [
    Licao(nome: 'Parte 1', emoji: '📝', id: 'minha-viagem.parte-1', trechos: [
      Trecho(id: 'f-p1', quem: 'voce', cod: 'We went to Rome.', dica: 'Fomos a Roma.', out: ''),
      Trecho(id: 'f-p2', quem: 'voce', cod: 'It was great!', dica: 'Foi ótimo!', out: ''),
    ]),
  ]),
];

class _Loader extends CurriculoLoader {
  _Loader() : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => _trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

class _VozFake extends VozIngles {
  final falas = <String>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) async => falas.add(frase);
  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

const _timeout = Duration(seconds: 2);

/// O palco como o `HomePage` o monta (ListView com respiro de 20 e no máximo 980 de largura).
Future<CursoBloc> _abrir(
  WidgetTester tester, {
  Size tela = const Size(1280, 900),
  _Disco? bundle,
  Map<String, Object> prefs = const {},
  bool ensaio = false,
}) async {
  SharedPreferences.setMockInitialValues({EnsaioMental.prefLigado: ensaio, ...prefs});
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final historias = HistoriasLicoes(_trilhas, bundle: bundle ?? _Disco(), timeout: _timeout);
  final curso = CursoBloc(loader: _Loader(), progresso: LocalProgressoRepository(prefixo: 'en_teste_'));
  addTearDown(curso.close);
  curso.add(const CursoIniciado());
  await tester.pumpWidget(MultiBlocProvider(
    providers: [
      BlocProvider<CursoBloc>.value(value: curso),
      BlocProvider<TypingBloc>(create: (_) => TypingBloc()),
    ],
    child: MaterialApp(
      theme: Mixart.tema(),
      home: Scaffold(
        body: BlocBuilder<CursoBloc, CursoState>(
          builder: (context, st) => st.status != CursoStatus.pronto
              ? const SizedBox.shrink()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: ListView(padding: const EdgeInsets.all(20), children: [
                      PalcoIngles(curso: st, voz: _VozFake(), historias: historias),
                    ]),
                  ),
                ),
        ),
      ),
    ),
  ));
  await _anda(tester);
  return curso;
}

/// Deixa as futures (prefs, bundle) e os blocs andarem.
Future<void> _anda(WidgetTester tester, [int vezes = 6]) async {
  for (var i = 0; i < vezes; i++) {
    await tester.pump(const Duration(milliseconds: 30));
  }
}

/// Deixa a ação da cena acabar e as esperas vencerem (o relógio da cena para sozinho).
Future<void> _assenta(WidgetTester tester) async {
  for (var i = 0; i < 50; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Digita a frase do passo e dá Enter (o próximo passo da escada).
Future<void> _proximaFrase(WidgetTester tester) async {
  final typing = tester.element(find.byType(PalcoIngles)).read<TypingBloc>();
  await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last,
      typing.state.chars.join());
  await _anda(tester, 3);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await _anda(tester, 3);
}

CenaDaFrase _cena(WidgetTester tester) => tester.widget<CenaDaFrase>(find.byType(CenaDaFrase));

/// A âncora da frase que o palco mostra agora (pelo CursoBloc).
(int, int)? _ancoraAtual(WidgetTester tester, CursoBloc curso) {
  final t = curso.state.licao.trechos[curso.state.trechoIdx];
  return _cena(tester).historia.ancoras[chaveDaFrase(t)];
}

final _cenaKey = find.byKey(const Key('cena-da-frase'));
final _rostoKey = find.byKey(const Key('rosto-da-frase'));
final _chave = find.byKey(const Key('alternar-cena'));

void testWidgetsDesktop(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
void testWidgetsCelular(String d, WidgetTesterCallback c) =>
    testWidgets(d, c, variant: TargetPlatformVariant.only(TargetPlatform.android));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    PreferenciaCenaLicao.padrao = true;
    FraseView.carencia = Duration.zero;
    HistoriasLicoesRepo.limparCache();
    Linguagem.atual = Linguagem.ingles;
  });
  tearDown(() {
    PreferenciaCenaLicao.padrao = false;
    Linguagem.atual = Linguagem.dart;
    VozIngles.falando.value = null;
  });

  testWidgetsDesktop('a 1ª frase já mostra a cena (autoral); avançar leva à âncora da frase nova', (tester) async {
    final curso = await _abrir(tester);
    await _assenta(tester);
    expect(_cenaKey, findsOneWidget);
    expect(_rostoKey, findsNothing, reason: 'a cena no lugar do rosto');
    expect(_cena(tester).historia.autoral, isTrue, reason: 'a autoral chegou dentro dos 400 ms');
    expect((_cena(tester).ancora), _ancoraAtual(tester, curso));
    expect(_chave, findsOneWidget);
    expect(find.text('🎬 Cena'), findsOneWidget);

    final vistas = <int>{};
    for (var i = 0; i < 8; i++) {
      final antes = curso.state.trechoIdx;
      await _proximaFrase(tester);
      await _assenta(tester);
      vistas.add(curso.state.trechoIdx);
      expect(_cena(tester).ancora, _ancoraAtual(tester, curso),
          reason: 'passo ${i + 2}: frase ${curso.state.trechoIdx} (antes $antes)');
      expect(_rostoKey, findsNothing);
    }
    expect(vistas.length, greaterThan(2), reason: 'a escada passou por várias frases');
    await _assenta(tester);
  });

  testWidgetsDesktop('a chave troca para o rosto, salva e o teclado continua na frase; e volta', (tester) async {
    await _abrir(tester);
    await _assenta(tester);
    final focoAntes = FocusManager.instance.primaryFocus;
    expect(focoAntes, isNotNull);
    await tester.tap(_chave);
    await _anda(tester);
    expect(_cenaKey, findsNothing);
    expect(_rostoKey, findsOneWidget);
    expect(find.text('🙂 Rosto'), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool(PreferenciaCenaLicao.chave), isFalse);
    expect(FocusManager.instance.primaryFocus, same(focoAntes), reason: 'o foco fica na frase');
    await tester.tap(_chave);
    await _assenta(tester);
    expect(_cenaKey, findsOneWidget);
    expect((await SharedPreferences.getInstance()).getBool(PreferenciaCenaLicao.chave), isTrue);
    expect(FocusManager.instance.primaryFocus, same(focoAntes));
  });

  testWidgetsDesktop('pref desligada: o rosto de sempre (e a chave para ligar)', (tester) async {
    await _abrir(tester, prefs: {PreferenciaCenaLicao.chave: false});
    await _assenta(tester);
    expect(_cenaKey, findsNothing);
    expect(_rostoKey, findsOneWidget);
    expect(find.text('🙂 Rosto'), findsOneWidget);
  });

  testWidgetsDesktop('lição de texto colado (trilha própria): o rosto, sem a chave', (tester) async {
    final curso = await _abrir(tester);
    curso.add(const TrilhaSelecionada(1));
    await _assenta(tester);
    expect(curso.state.licao.id, 'minha-viagem.parte-1');
    expect(_cenaKey, findsNothing);
    expect(_rostoKey, findsOneWidget);
    expect(_chave, findsNothing);
  });

  testWidgetsDesktop('a autoral que não chega: o rosto até 400 ms, depois a automática (nunca em branco)',
      (tester) async {
    await _abrir(tester, bundle: _Disco(presos: {'${HistoriasLicoesRepo.pasta}primeiro-contato.json'}));
    expect(_cenaKey, findsNothing);
    expect(_rostoKey, findsOneWidget, reason: 'esperando a autoral: o rosto');
    await tester.pump(const Duration(milliseconds: 200));
    expect(_rostoKey, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 250));
    await _anda(tester);
    expect(_cenaKey, findsOneWidget, reason: 'venceu a espera: a automática');
    expect(_cena(tester).historia.autoral, isFalse);
    // o timeout do arquivo preso vence (e não fica Timer pendurado)
    await tester.pump(_timeout);
    await _assenta(tester);
  });

  testWidgetsDesktop('índice fora do ar: a automática', (tester) async {
    await _abrir(tester, bundle: _Disco(faltando: {HistoriasLicoesRepo.indice}));
    await _assenta(tester);
    expect(_cenaKey, findsOneWidget);
    expect(_cena(tester).historia.autoral, isFalse);
  });

  testWidgetsDesktop('o ensaio mental na frente: a cena parada; ao fechar, ela anda', (tester) async {
    await _abrir(tester, ensaio: true);
    await _anda(tester);
    expect(find.byType(EnsaioMental), findsOneWidget);
    await _assenta(tester);
    expect(_cenaKey, findsOneWidget);
    expect(_cena(tester).ativo, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _anda(tester);
    expect(find.byType(EnsaioMental), findsNothing);
    expect(_cena(tester).ativo, isTrue);
    await _assenta(tester);
  });

  testWidgetsDesktop('computador 1280×720: a caixa 288×162 ao lado da tradução', (tester) async {
    await _abrir(tester, tela: const Size(1280, 720));
    await _assenta(tester);
    expect(tester.getSize(_cenaKey), const Size(288, 162));
    final caixa = tester.getRect(_cenaKey);
    final traducao = tester.getRect(find.byType(TraducaoCard));
    expect(caixa.left, lessThan(traducao.left + 40), reason: 'à esquerda, dentro do cartão');
    expect(caixa.top, lessThan(traducao.top + 30));
  });

  testWidgetsCelular('celular 390×844: faixa 274×137 no topo do cartão; com o teclado (sobram 544 px), o rosto',
      (tester) async {
    await _abrir(tester, tela: const Size(390, 844));
    await _assenta(tester);
    expect(tester.getSize(_cenaKey), const Size(274, 137));
    final cartao = tester.getRect(find.byType(TraducaoCard));
    expect(tester.getRect(_cenaKey).top, lessThan(cartao.top + 20), reason: 'a faixa abre o cartão');
    expect(tester.getRect(find.byType(FraseView)).top, greaterThan(tester.getRect(_cenaKey).bottom));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await _assenta(tester);
    expect(_cenaKey, findsNothing, reason: 'a zona com a faixa não caberia acima do teclado');
    expect(tester.getSize(_rostoKey), const Size(48 + 12, 48), reason: 'o rosto compacto de sempre');
    tester.view.resetViewInsets();
    await _assenta(tester);
    expect(tester.getSize(_cenaKey), const Size(274, 137));
  });

  testWidgetsCelular('celular 430×932: com o teclado ainda sobra tela (632 px): a faixa baixa e a zona cabe',
      (tester) async {
    await _abrir(tester, tela: const Size(430, 932));
    await _assenta(tester);
    expect(tester.getSize(_cenaKey), const Size(314, 150));
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetViewInsets);
    await _assenta(tester);
    expect(tester.getSize(_cenaKey), const Size(314, 96));
    expect(find.text('áudio automático'), findsNothing, reason: 'compacto: as caixinhas (e a chave) somem');
    expect(_chave, findsNothing);
    // o cartão (com a faixa), a frase, o selo e a barra cabem nos 632 px de cima
    final altura = tester.getRect(find.byType(FraseView)).bottom - tester.getRect(find.byType(TraducaoCard)).top + 90;
    expect(altura, lessThanOrEqualTo(932 - 300));
    tester.view.resetViewInsets();
    await _assenta(tester);
    expect(tester.getSize(_cenaKey), const Size(314, 150));
  });

  testWidgetsCelular('celular 360×640: faixa 244×122; com o teclado numa tela baixa, o rosto pequeno', (tester) async {
    await _abrir(tester, tela: const Size(360, 640));
    await _assenta(tester);
    expect(tester.getSize(_cenaKey), const Size(244, 122));
    tester.view.viewInsets = const FakeViewPadding(bottom: 270);
    addTearDown(tester.view.resetViewInsets);
    await _assenta(tester);
    expect(_cenaKey, findsNothing);
    expect(_rostoKey, findsOneWidget);
    expect(tester.getSize(_rostoKey), const Size(48 + 12, 48), reason: 'o rosto compacto de sempre');
    tester.view.resetViewInsets();
    await _assenta(tester);
    expect(_cenaKey, findsOneWidget);
  });
}
