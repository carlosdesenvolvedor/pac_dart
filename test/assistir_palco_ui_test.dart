// 📺 O PalcoAssistir com um OuvirCubit de verdade (saída de áudio falsa): o balão com o inglês, o chip
// "Tradução", o lip-sync pela `VozIngles.falando`, bolinhas, tocar no palco, os véus (⏸, 🌙, 🏁), sem desenho,
// a espera da autoral, o selo ✨, nenhum véu preto ao repetir (D18), minimizar e reabrir no meio do vão,
// GlobalKey na troca de layout e no ⛶, o Ticker pelo TickerMode, as molduras da videochamada (390×844 e
// 2560×1080) e 4 telas com texto 1,6× sem exceção; pausado não agenda quadro; nada de timer pendurado; o balão
// compacto sem PT da chamada no celular deitado (sem cobrir cabeça) e o relógio parado com o palco rolado para fora.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/historia_turismo.dart';
import 'package:pac_dart/features/arcade/presentation/historia/ator_historia.dart';
import 'package:pac_dart/features/arcade/presentation/historia/palco_historia.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historia_licao.dart';
import 'package:pac_dart/features/ingles/domain/assistir/historias_licoes.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/domain/config_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/fila_ouvir.dart';
import 'package:pac_dart/features/ingles/domain/saida_audio.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/assistir/palco_assistir.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/ouvir/ouvir_state.dart';

import 'assistir_compasso_test.dart';

/// Saída falsa (no molde da do `ingles_ouvir_cubit_test`): cada fala fica pendente; [parar] corta com `cortada`.
class _Saida implements SaidaDeAudio {
  final chamadas = <String>[];
  final _pendentes = <Completer<FimDaFala>>[];

  Future<FimDaFala> _nova(String c) {
    chamadas.add(c);
    final x = Completer<FimDaFala>();
    _pendentes.add(x);
    return x.future;
  }

  @override
  Future<FimDaFala> en(String texto, {required double fator}) => _nova('en:$texto');

  @override
  Future<FimDaFala> pt(String texto, {required double fator}) => _nova('pt:$texto');

  @override
  Future<FimDaFala> silencio(Duration d) => _nova('sil:${d.inMilliseconds}');

  @override
  void parar() {
    for (final p in _pendentes) {
      if (!p.isCompleted) p.complete(FimDaFala.cortada);
    }
    _pendentes.clear();
  }

  @override
  void preaquecer(String texto) {}

  @override
  bool get somLiberado => true;

  @override
  double duracaoDe(String en) => 2;

  @override
  bool temGravacao(String en) => true;
}

/// O OuvirCubit de verdade (alternar, irPara, tocar), com o vigia que nunca dispara (sem Timer) e um
/// [emitir] para pôr o estado exato que o teste quer.
class _Cubit extends OuvirCubit {
  _Cubit(_Saida saida) : super(saida: saida, esperar: (_) => Completer<void>().future);

  void emitir(OuvirState s) => emit(s);
}

/// As historinhas fixas da fixture (a "autoral" pode estar "carregando").
class _Historias extends HistoriasLicoes {
  _Historias(super.trilhas, this.mapa);

  final Map<String, HistoriaLicao> mapa;
  bool carregandoAgora = false;

  @override
  HistoriaLicao? para(Faixa f) => mapa[f.licaoId];

  @override
  bool carregando(String licaoId) => carregandoAgora;
}

/// Uma lição de chamada com 5 pessoas (a Ana ainda fora da chamada).
const _licaoChamada = Licao(id: 'trilha-a.licao-3', nome: 'A daily', emoji: '💻', trechos: [
  Trecho(id: 'f-c0', quem: 'voce', cod: 'Good morning, team!', dica: 'Bom dia, time!', out: ''),
  Trecho(id: 'f-c1', quem: 'mike', cod: 'Morning!', dica: 'Bom dia!', out: ''),
  Trecho(id: 'f-c2', quem: 'sarah', cod: 'Hi there!', dica: 'Oi!', out: ''),
  Trecho(id: 'f-c3', quem: 'ben', cod: 'Hello!', dica: 'Olá!', out: ''),
]);

HistoriaLicao _historiaChamada() => HistoriaLicao.daLicao(
      _licaoChamada,
      [
        CenaHistoria(
          cenario: CenarioHistoria.videochamada,
          hora: HoraHistoria.dia,
          elenco: const [
            AtorEmCena(quem: 'voce', pos: PosicaoPalco.esquerda),
            AtorEmCena(quem: 'mike', pos: PosicaoPalco.centroEsquerda),
            AtorEmCena(quem: 'sarah', pos: PosicaoPalco.centro),
            AtorEmCena(quem: 'ben', pos: PosicaoPalco.centroDireita),
            AtorEmCena(quem: 'ana', pos: PosicaoPalco.direita, visivel: false),
          ],
          falas: [
            for (final t in _licaoChamada.trechos)
              FalaHistoria(quem: t.quem, en: t.cod, pt: t.dicaPlana, acao: AcaoAtor.acena),
          ],
        ),
      ],
      nivel: NivelIngles.a1,
      autoral: false,
    );

const _trilhas = [
  Trilha(nivel: 'Trilha A', emoji: '🧪', etapa: etapaFixture, licoes: [licaoA, licaoB, _licaoChamada]),
];

class _Montagem {
  _Montagem() : saida = _Saida() {
    cubit = _Cubit(saida);
    historias = _Historias(_trilhas, {licaoA.id: historiaA(), licaoB.id: historiaB(), _licaoChamada.id: _historiaChamada()});
  }

  final _Saida saida;
  late final _Cubit cubit;
  late final _Historias historias;
  final chave = GlobalKey();
  int telaCheia = 0;

  Widget palco({bool grande = false}) => PalcoAssistir(
        key: chave,
        cubit: cubit,
        trilhas: _trilhas,
        historias: historias,
        grande: grande,
        onTelaCheia: () => telaCheia++,
      );
}

Future<_Montagem> _montar(
  WidgetTester tester, {
  OuvirState? estado,
  Size tela = const Size(1000, 800),
  Size? tamanho,
  bool grande = false,
  double escala = 1,
  _Montagem? m,
}) async {
  tester.view.physicalSize = tela;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final mt = m ?? _Montagem();
  if (m == null) addTearDown(mt.cubit.close);
  mt.cubit.emitir(estado ?? tocandoEm());
  final w = tamanho?.width ?? (tela.width < 720 ? tela.width : 720.0);
  final h = tamanho?.height ?? (w * .56).clamp(200.0, 380.0);
  await tester.pumpWidget(MaterialApp(
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(escala)),
      child: child!,
    ),
    home: Scaffold(body: Center(child: SizedBox(width: w, height: h, child: mt.palco(grande: grande)))),
  ));
  await tester.pump();
  return mt;
}

/// Anda [ms] em quadros de 16 ms (o Ticker conta no máximo .1 s por quadro, como o do Turismo).
Future<void> _andar(WidgetTester tester, int ms) async {
  for (var t = 0; t < ms; t += 16) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

/// O cubit entrega o estado num microtask: o 1º pump o recebe, o 2º desenha.
Future<void> _mudar(WidgetTester tester, _Montagem m, OuvirState s) async {
  m.cubit.emitir(s);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

PalcoHistoria _palcoHistoria(WidgetTester tester) =>
    tester.widget<PalcoHistoria>(find.byType(PalcoHistoria, skipOffstage: false));

String _textoRico(WidgetTester tester, String chave) =>
    tester.widget<RichText>(find.descendant(of: find.byKey(Key(chave)), matching: find.byType(RichText))).text.toPlainText();

/// Um `ColoredBox` preto (o véu do corte) dentro do palco.
Finder _veuPreto() => find.descendant(
      of: find.byType(PalcoHistoria),
      matching: find.byWidgetPredicate((w) =>
          w is ColoredBox && w.color.r == 0 && w.color.g == 0 && w.color.b == 0 && w.color.a > 0),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  tearDown(() => VozIngles.falando.value = null);

  testWidgets('o 1º estado vem no initState (P10): o balão com o inglês e o PT; o chip "Tradução" esconde o PT',
      (tester) async {
    final m = await _montar(tester);
    expect(find.byKey(const Key('assistir-palco')), findsOneWidget);
    expect(find.byType(PalcoHistoria), findsOneWidget);
    expect(find.byKey(const Key('historia-balao')), findsOneWidget);
    await _andar(tester, 2000); // a máquina de escrever (sem voz: pelo nível)
    expect(_textoRico(tester, 'historia-balao-en'), contains('Good morning, Mike!'));
    expect(find.byKey(const Key('historia-balao-pt')), findsOneWidget);
    expect(find.textContaining('☀️👋'), findsOneWidget, reason: 'o emoji da frase no chip do nome');
    m.cubit.configurar(m.cubit.state.config.copyWith(mostrarTraducao: false));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const Key('historia-balao-pt')), findsNothing);
    expect(m.saida.chamadas, isEmpty, reason: 'o palco não tem voz própria (D2)');
  });

  testWidgets('palco baixo (celular, texto 1,6×): o balão cresce por cima dos atores e não corta o EN nem o PT',
      (tester) async {
    await _montar(tester, tela: const Size(390, 700), tamanho: const Size(358, 220), escala: 1.6);
    await _andar(tester, 2500);
    expect(tester.takeException(), isNull);
    final palco = tester.getRect(find.byType(PalcoHistoria));
    final balao = tester.getRect(find.byKey(const Key('historia-balao')));
    final pt = tester.getRect(find.byKey(const Key('historia-balao-pt')));
    expect(palco.contains(balao.topLeft) && balao.bottom <= palco.bottom, isTrue, reason: '$balao em $palco');
    expect(pt.bottom, lessThanOrEqualTo(balao.bottom + .5), reason: 'o PT dentro do balão (sem corte): $pt / $balao');
    expect(_palcoHistoria(tester).balaoSemCorte, isTrue);
  });

  testWidgets('lip-sync pela VozIngles.falando: o falante com a boca da voz, o ouvinte de boca fechada', (tester) async {
    await _montar(tester);
    VozIngles.falando.value = FalaEmCurso(
      frase: 'Good morning, Mike!',
      boca: TrilhaBoca.compacta('0D 500X'),
      inicio: DateTime.now(),
    );
    await tester.pump(const Duration(milliseconds: 16));
    final voce = tester.widget<AtorHistoria>(find.byKey(const ValueKey('historia-ator-voce')));
    final mike = tester.widget<AtorHistoria>(find.byKey(const ValueKey('historia-ator-mike')));
    expect(voce.visema, Visema.d);
    expect(mike.visema, Visema.x);
  });

  testWidgets('bolinhas = as frases da lição; tocar numa vai para ela; tocar no palco alterna', (tester) async {
    final m = await _montar(tester);
    final bolinhas = find.descendant(of: find.byKey(const Key('assistir-bolinhas')), matching: find.byType(InkResponse));
    expect(bolinhas, findsNWidgets(5), reason: 'a lição A tem 5 frases');
    await tester.tap(find.byKey(const Key('assistir-bolinha-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(m.cubit.state.indice, 3);
    expect(_palcoHistoria(tester).roteiro.cena, 1);
    expect(m.cubit.state.status, StatusOuvir.tocando);
    await tester.tapAt(tester.getCenter(find.byType(PalcoHistoria)));
    await tester.pump();
    expect(m.cubit.state.status, StatusOuvir.pausado);
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const Key('assistir-pausado')), findsOneWidget);
    await tester.tap(find.byKey(const Key('assistir-pausado')));
    await tester.pump();
    expect(m.cubit.state.status, StatusOuvir.tocando);
    // o ⛶
    await tester.tap(find.byKey(const Key('assistir-tela-cheia')));
    expect(m.telaCheia, 1);
  });

  testWidgets('véus: ⏸ pausado, 🌙 timer, 🏁 fim (▶ de novo toca do começo)', (tester) async {
    final m = await _montar(tester, estado: tocandoEm(indice: 2));
    await _mudar(tester, m, m.cubit.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.usuario));
    expect(find.byKey(const Key('assistir-pausado')), findsOneWidget);
    expect(find.text('⏸ Pausado: toque para continuar'), findsOneWidget);
    await _mudar(tester, m, m.cubit.state.copyWith(motivo: MotivoPausa.timer));
    expect(find.byKey(const Key('assistir-timer')), findsOneWidget);
    expect(find.byKey(const Key('assistir-pausado')), findsNothing);
    await _mudar(tester, m, m.cubit.state.copyWith(status: StatusOuvir.acabou, semMotivo: true));
    expect(find.byKey(const Key('assistir-fim')), findsOneWidget);
    await tester.tap(find.byKey(const Key('assistir-fim')));
    await tester.pump();
    expect(m.cubit.state.status, StatusOuvir.tocando);
    expect(m.cubit.state.indice, 0);
  });

  testWidgets('pausado: o Ticker para (nenhum quadro agendado); nada de timer pendurado no fim', (tester) async {
    final m = await _montar(tester);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue, reason: 'tocando, o desenho anda');
    await _mudar(tester, m, m.cubit.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.usuario));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.hasScheduledFrame, isFalse);
    final t = _palcoHistoria(tester).roteiro.tPasso;
    await tester.pump(const Duration(seconds: 1));
    expect(_palcoHistoria(tester).roteiro.tPasso, t);
    await tester.pumpWidget(Container());
    await tester.pump();
  });

  testWidgets('sem desenho (frase órfã) e a espera da autoral (até 400 ms com a foto)', (tester) async {
    final m = await _montar(tester, estado: tocandoEm(fila: [faixaOrfa, ...filaAB()]));
    expect(find.byKey(const Key('assistir-sem-desenho')), findsOneWidget);
    expect(find.text('Sem desenho para esta frase (ela não é de uma lição do curso)'), findsOneWidget);
    expect(find.byType(PalcoHistoria), findsNothing);
    await _mudar(tester, m, m.cubit.state.copyWith(indice: 1));
    expect(find.byKey(const Key('assistir-sem-desenho')), findsNothing);
    expect(find.byType(PalcoHistoria), findsOneWidget);

    final m2 = _Montagem()..historias.carregandoAgora = true;
    addTearDown(m2.cubit.close);
    await tester.pumpWidget(Container());
    await _montar(tester, m: m2);
    expect(find.byKey(const Key('assistir-carregando')), findsOneWidget);
    expect(find.byType(PalcoHistoria), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('assistir-carregando')), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byKey(const Key('assistir-carregando')), findsNothing);
    expect(find.byType(PalcoHistoria), findsOneWidget);
  });

  testWidgets('o selo "✨ história especial" só na autoral (D21)', (tester) async {
    final m = await _montar(tester);
    expect(find.byKey(const Key('assistir-titulo')), findsOneWidget);
    expect(find.byKey(const Key('assistir-especial')), findsOneWidget);
    expect(find.textContaining('A primeira chamada'), findsOneWidget);
    await _mudar(tester, m, tocandoEm(fila: [for (var k = 0; k < 4; k++) faixaDe(_licaoChamada, k)]));
    expect(find.byKey(const Key('assistir-especial')), findsNothing);
    expect(find.textContaining('A daily'), findsOneWidget);
  });

  testWidgets('D18: repetir a 1ª frase (e a 1ª da cena 1) 3 vezes não põe véu preto', (tester) async {
    for (final indice in [0, 3]) {
      final m = await _montar(tester, estado: tocandoEm(indice: indice, config: const ConfigOuvir(repeticoes: 3)));
      for (final e in estadosDaFaixa(m.cubit.state, indice)) {
        await _mudar(tester, m, e);
        expect(_veuPreto(), findsNothing);
        await tester.pump(const Duration(milliseconds: 120));
        expect(_veuPreto(), findsNothing);
      }
      await tester.pumpWidget(Container());
    }
  });

  testWidgets('minimizar e reabrir no meio de um vão: o mesmo passo, sem exceção', (tester) async {
    final m = await _montar(tester, estado: tocandoEm(indice: 2, config: const ConfigOuvir(pausa: PausaOuvir.longa)));
    final estados = estadosDaFaixa(m.cubit.state, 2);
    await _mudar(tester, m, estados[0]);
    await _mudar(tester, m, estados[1]);
    await _andar(tester, 500);
    final r = _palcoHistoria(tester).roteiro;
    final passo = (r.cena, r.passo);
    expect(passo, (0, 4));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('mini-player'))));
    await tester.pump();
    await _montar(tester, m: m, estado: m.cubit.state);
    final r2 = _palcoHistoria(tester).roteiro;
    expect(identical(r, r2), isFalse, reason: 'um seguidor novo');
    expect((r2.cena, r2.passo), passo);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GlobalKey: trocar 1400 → 800 px e entrar/sair do ⛶ mantém o mesmo State', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final m = _Montagem();
    addTearDown(m.cubit.close);
    m.cubit.emitir(tocandoEm());
    var grande = false;
    late StateSetter mudar;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(builder: (context, setState) {
          mudar = setState;
          final palco = m.palco(grande: grande);
          if (grande) return SizedBox.expand(child: palco);
          return LayoutBuilder(builder: (context, c) {
            if (c.maxWidth >= 900) {
              return Row(children: [SizedBox(width: 520, height: 300, child: palco), const Expanded(child: SizedBox())]);
            }
            return Column(children: [SizedBox(width: c.maxWidth, height: 300, child: palco), const Expanded(child: SizedBox())]);
          });
        }),
      ),
    ));
    await tester.pump();
    final estado = tester.state(find.byType(PalcoAssistir));
    tester.view.physicalSize = const Size(800, 900);
    await tester.pump();
    expect(identical(tester.state(find.byType(PalcoAssistir)), estado), isTrue);
    mudar(() => grande = true);
    await tester.pump();
    expect(identical(tester.state(find.byType(PalcoAssistir)), estado), isTrue);
    mudar(() => grande = false);
    await tester.pump();
    expect(identical(tester.state(find.byType(PalcoAssistir)), estado), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Ticker pelo TickerMode (P7): com uma folha por cima anda; com uma rota opaca por cima, para',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final m = _Montagem();
    addTearDown(m.cubit.close);
    m.cubit.emitir(tocandoEm());
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: Scaffold(body: Center(child: SizedBox(width: 640, height: 360, child: m.palco()))),
    ));
    await tester.pump();
    unawaited(showModalBottomSheet<void>(
        context: nav.currentContext!, builder: (_) => const SizedBox(height: 120, child: Text('Pôr na setlist'))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final t0 = _palcoHistoria(tester).roteiro.tPasso;
    await tester.pump(const Duration(milliseconds: 300));
    expect(_palcoHistoria(tester).roteiro.tPasso, greaterThan(t0), reason: 'a folha deixa o palco à vista');
    nav.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 400));
    unawaited(nav.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('outra')))));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    final t1 = _palcoHistoria(tester).roteiro.tPasso;
    await tester.pump(const Duration(milliseconds: 500));
    expect(_palcoHistoria(tester).roteiro.tPasso, t1, reason: 'coberto por uma rota opaca, o Ticker cala');
  });

  for (final tela in const [Size(390, 844), Size(2560, 1080)]) {
    testWidgets('videochamada ${tela.width.toInt()}×${tela.height.toInt()}: molduras sem encostar, com a cabeça e a '
        'folga, a apagada de quem não entrou', (tester) async {
      await _montar(
        tester,
        tela: tela,
        tamanho: tela,
        grande: true,
        estado: tocandoEm(fila: [for (var k = 0; k < 4; k++) faixaDe(_licaoChamada, k)]),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      final molduras = <String, Rect>{
        for (final q in ['voce', 'mike', 'sarah', 'ben', 'ana'])
          q: tester.getRect(find.byKey(ValueKey('historia-moldura-$q'))),
      };
      final nomes = molduras.keys.toList();
      for (var i = 0; i < nomes.length; i++) {
        for (var j = i + 1; j < nomes.length; j++) {
          expect(molduras[nomes[i]]!.overlaps(molduras[nomes[j]]!), isFalse,
              reason: '${nomes[i]} × ${nomes[j]}: ${molduras[nomes[i]]} ${molduras[nomes[j]]}');
        }
      }
      for (final q in ['voce', 'mike', 'sarah', 'ben']) {
        final ator = tester.getRect(find.byKey(ValueKey('historia-ator-$q')));
        final m = molduras[q]!;
        expect(m.top, lessThanOrEqualTo(ator.top - .15 * ator.height + .5), reason: '$q: folga acima da cabeça');
        expect(m.left, lessThanOrEqualTo(ator.left + .5), reason: '$q: $m $ator');
        expect(m.right, greaterThanOrEqualTo(ator.right - .5), reason: '$q: $m $ator');
        expect(m.bottom, lessThan(ator.bottom), reason: '$q: recorte na cintura');
        expect(m.top, greaterThanOrEqualTo(0));
      }
      expect(find.byKey(const ValueKey('historia-ator-ana')), findsNothing, reason: 'a Ana ainda não entrou');
    });
  }

  for (final tela in const [Size(360, 640), Size(390, 844), Size(1400, 900), Size(2560, 1080)]) {
    testWidgets('${tela.width.toInt()}×${tela.height.toInt()} com texto 1,6×: sem exceção (normal e ⛶)', (tester) async {
      for (final grande in [false, true]) {
        final m = await _montar(
          tester,
          tela: tela,
          tamanho: grande ? tela : null,
          grande: grande,
          escala: 1.6,
          estado: tocandoEm(config: const ConfigOuvir(pausa: PausaOuvir.eco)),
        );
        await tester.pump(const Duration(seconds: 3));
        expect(tester.takeException(), isNull);
        for (final e in estadosDaFaixa(m.cubit.state, 0)) {
          await _mudar(tester, m, e);
          await tester.pump(const Duration(milliseconds: 600));
          expect(tester.takeException(), isNull);
        }
        await _mudar(tester, m, m.cubit.state.copyWith(status: StatusOuvir.pausado, motivo: MotivoPausa.timer));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(Container());
      }
    });
  }

  testWidgets('alvos de toque: bolinhas ≥ 24×40 e o ⛶ ≥ 48×40; o toque no desenho não vira botão sem nome',
      (tester) async {
    final h = tester.ensureSemantics();
    await _montar(tester);
    for (var j = 0; j < 5; j++) {
      final s = tester.getSize(find.byKey(Key('assistir-bolinha-$j')));
      expect(s.width, greaterThanOrEqualTo(24), reason: 'bolinha $j: $s');
      expect(s.height, greaterThanOrEqualTo(40), reason: 'bolinha $j: $s');
    }
    final telaCheia = tester.getSize(find.byKey(const Key('assistir-tela-cheia')));
    expect(telaCheia.width, greaterThanOrEqualTo(48));
    expect(telaCheia.height, greaterThanOrEqualTo(40));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    h.dispose();
  });

  testWidgets('bolinhas que não cabem com alvo de toque viram "k/N" com ◀ ▶', (tester) async {
    final m = await _montar(tester, tela: const Size(390, 700), tamanho: const Size(300, 220), estado: tocandoEm(indice: 1));
    expect(find.byKey(const Key('assistir-bolinhas')), findsNothing);
    expect(find.byKey(const Key('assistir-bolinhas-compacto')), findsOneWidget);
    expect(find.text('2/5'), findsOneWidget);
    await tester.tap(find.byKey(const Key('assistir-bolinha-depois')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(m.cubit.state.indice, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('videochamada numa fila (palco do celular): as molduras dividem a largura por igual', (tester) async {
    await _montar(
      tester,
      tela: const Size(390, 844),
      tamanho: const Size(358, 279),
      estado: tocandoEm(fila: [for (var k = 0; k < 4; k++) faixaDe(_licaoChamada, k)]),
    );
    await tester.pump(const Duration(milliseconds: 100));
    final palco = tester.getRect(find.byType(PalcoHistoria));
    final cs = [
      for (final q in ['voce', 'mike', 'sarah', 'ben', 'ana'])
        tester.getRect(find.byKey(ValueKey('historia-moldura-$q'))).center.dx - palco.left,
    ];
    for (var i = 0; i < cs.length; i++) {
      expect(cs[i], closeTo(palco.width * (i + .5) / cs.length, 1), reason: 'moldura $i: $cs');
    }
    final w = tester.getSize(find.byKey(const ValueKey('historia-moldura-mike'))).width;
    expect(w, greaterThan(62), reason: 'sem o vão do meio, a moldura cresce');
  });

  testWidgets('videochamada em 2 filas (⛶ em pé): quem fala na fila de trás tem o balão logo acima da moldura',
      (tester) async {
    await _montar(
      tester,
      tela: const Size(390, 844),
      tamanho: const Size(390, 844),
      grande: true,
      estado: tocandoEm(indice: 1, fila: [for (var k = 0; k < 4; k++) faixaDe(_licaoChamada, k)]),
    );
    await _andar(tester, 1500);
    final balao = tester.getRect(find.byKey(const Key('historia-balao')));
    final mike = tester.getRect(find.byKey(const ValueKey('historia-moldura-mike')));
    expect(balao.bottom, lessThanOrEqualTo(mike.top), reason: '$balao / $mike');
    expect(mike.top - balao.bottom, lessThan(24), reason: 'o balão encostado em quem fala: $balao / $mike');
  });

  testWidgets('videochamada no celular deitado (palco da página 640×210): o balão não cobre cabeça; perde o PT '
      '(a página o mostra) e vira 1 linha; no ⛶ e em 1280×720 o PT fica', (tester) async {
    final fila = [for (var k = 0; k < 4; k++) faixaDe(_licaoChamada, k)];
    for (final (tela, tamanho, grande, comPt) in const [
      (Size(844, 390), Size(640, 210), false, false),
      (Size(844, 390), Size(844, 390), true, true),
      (Size(1280, 720), Size(720, 403), false, true),
    ]) {
      for (final indice in [0, 1, 2]) {
        await _montar(tester, tela: tela, tamanho: tamanho, grande: grande, estado: tocandoEm(indice: indice, fila: fila));
        await _andar(tester, 2500);
        expect(tester.takeException(), isNull);
        final onde = '$tamanho${grande ? ' ⛶' : ''} fala $indice';
        final balao = tester.getRect(find.byKey(const Key('historia-balao')));
        expect(find.byKey(const Key('historia-balao-pt')), comPt ? findsOneWidget : findsNothing, reason: onde);
        if (!comPt) {
          expect(balao.height, lessThan(60), reason: '$onde: o balão de uma linha ($balao)');
          for (final q in ['voce', 'mike', 'sarah', 'ben']) {
            final a = tester.getRect(find.byKey(ValueKey('historia-ator-$q')));
            final cabeca = Rect.fromLTRB(a.left, a.top, a.right, a.top + a.height * .3);
            expect(cabeca.overlaps(balao), isFalse, reason: '$onde: o balão $balao cobre a cabeça de $q $cabeca');
          }
        }
        await tester.pumpWidget(Container());
      }
    }
  });

  testWidgets('rolado para fora da página o relógio do palco para; de volta à vista, anda', (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final m = _Montagem();
    addTearDown(m.cubit.close);
    m.cubit.emitir(tocandoEm());
    final rolagem = ScrollController();
    addTearDown(rolagem.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: rolagem,
          child: Column(children: [
            SizedBox(width: 640, height: 360, child: m.palco()),
            const SizedBox(height: 2000),
          ]),
        ),
      ),
    ));
    await tester.pump();
    final t0 = _palcoHistoria(tester).roteiro.tPasso;
    await tester.pump(const Duration(milliseconds: 300));
    expect(_palcoHistoria(tester).roteiro.tPasso, greaterThan(t0), reason: 'à vista, o desenho anda');
    rolagem.jumpTo(1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final t1 = _palcoHistoria(tester).roteiro.tPasso;
    await tester.pump(const Duration(milliseconds: 500));
    expect(_palcoHistoria(tester).roteiro.tPasso, t1, reason: 'rolado para fora, o Ticker para');
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'nenhum quadro agendado fora da tela');
    rolagem.jumpTo(200); // um pedaço do palco volta à vista
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final t2 = _palcoHistoria(tester).roteiro.tPasso;
    await tester.pump(const Duration(milliseconds: 300));
    expect(_palcoHistoria(tester).roteiro.tPasso, greaterThan(t2), reason: 'de volta à vista, anda de novo');
    expect(tester.takeException(), isNull);
  });

  testWidgets('videochamada com câmera "medio"/"close": o zoom nunca corta uma moldura na borda do palco',
      (tester) async {
    for (final cam in [CameraHistoria.medio, CameraHistoria.close]) {
      final m = _Montagem();
      addTearDown(m.cubit.close);
      final base = _historiaChamada();
      final cena = base.cenas.single;
      m.historias.mapa[_licaoChamada.id] = HistoriaLicao.daLicao(
        _licaoChamada,
        [
          CenaHistoria(
            cenario: cena.cenario,
            hora: cena.hora,
            elenco: cena.elenco,
            falas: [
              for (final t in _licaoChamada.trechos)
                FalaHistoria(quem: t.quem, en: t.cod, pt: t.dicaPlana, acao: AcaoAtor.acena, camera: cam),
            ],
          ),
        ],
        nivel: NivelIngles.a1,
        autoral: false,
      );
      await _montar(tester, m: m, estado: tocandoEm(fila: [for (var k = 0; k < 4; k++) faixaDe(_licaoChamada, k)]));
      await _andar(tester, 1200);
      expect(tester.takeException(), isNull);
      final palco = tester.getRect(find.byType(PalcoHistoria));
      for (final q in ['voce', 'mike', 'sarah', 'ben', 'ana']) {
        final r = tester.getRect(find.byKey(ValueKey('historia-moldura-$q')));
        expect(r.left, greaterThanOrEqualTo(palco.left - .5), reason: '$cam $q: $r em $palco');
        expect(r.right, lessThanOrEqualTo(palco.right + .5), reason: '$cam $q: $r em $palco');
      }
      await tester.pumpWidget(Container());
    }
  });
}
