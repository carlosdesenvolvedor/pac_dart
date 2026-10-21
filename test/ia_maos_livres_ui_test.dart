import 'dart:async';

import 'package:flutter/gestures.dart' show PointerDeviceKind, kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/ia/domain/cenario.dart';
import 'package:pac_dart/features/ia/presentation/conversa_page.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ia/presentation/maos_livres.dart';
import 'package:pac_dart/features/ia/presentation/preferencias_conversa.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/tutor/data/falha_ia.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/tutor_falso.dart';
import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria;
import 'ingles_cartoes_ui_test.dart' show VozFake;
import 'ingles_shadowing_ui_test.dart' show ReconhecedorFalso;

const _cafe = Cenario(
  id: 'cafe',
  titulo: 'Pedir um café',
  emoji: '☕',
  etapa: 'A1',
  quem: 'emma',
  nome: 'Emma',
  papel: 'atendente de uma cafeteria',
  objetivo: 'Peça uma bebida e pague.',
  abertura: 'Hi! What can I get for you?',
  aberturaPt: 'Oi! O que posso trazer?',
  dicas: ['A small latte, please.'],
  maxTurnos: 3,
);

/// A voz que grava tudo num log e, com [prender], só acaba quando o teste manda ([acabar]) — ou quando o
/// microfone cala o app (como a de verdade: o calarTudo corta a fala e o Future dela completa).
class _Voz extends VozFake {
  final log = <String>[];
  bool prender = false;
  Completer<void>? _fala;

  bool get falando => _fala != null && !_fala!.isCompleted;

  @override
  Future<void> falar(String frase, {bool? lenta}) {
    log.add('falar:$frase');
    super.falar(frase, lenta: lenta);
    if (!prender) return Future.value();
    acabar();
    final c = _fala = Completer<void>();
    return c.future;
  }

  void acabar() {
    final c = _fala;
    if (c != null && !c.isCompleted) c.complete();
  }

  @override
  Future<void> calarTudo() async {
    log.add('calarTudo');
    acabar();
  }

  @override
  Future<void> parar() async => acabar();
}

class _Rec extends ReconhecedorFalso {
  final List<String> log;
  _Rec(this.log, {super.ok});
  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    log.add('ouvir');
    return super.ouvir(idioma: idioma, aoParcial: aoParcial, aoFinal: aoFinal, aoErro: aoErro, aoFim: aoFim);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    VozIngles.lentaPorPadrao = true;
    VozIngles.falando.value = null;
  });

  late TutorConversaFalso tutor;
  late _Voz voz;
  late _Rec rec;

  Future<IaCubit> criar(WidgetTester tester) async {
    tutor = TutorConversaFalso();
    final ia = IaCubit(service: tutor, cotaRepo: CotaMemoria(), cache: CacheMemoria(), agora: () => DateTime(2026, 10, 13, 10));
    await tester.runAsync(ia.carregar);
    addTearDown(() => tester.runAsync(ia.close));
    return ia;
  }

  Future<void> anda(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  /// A conversa atrás de uma tela "abrir" (para dar para sair). [maos] = a pref do mãos-livres ligada.
  Future<void> montar(WidgetTester tester, IaCubit ia,
      {bool maos = true,
      bool suportado = true,
      bool liberado = false,
      bool prender = true,
      Size tamanho = const Size(900, 1000),
      Paleta? paleta}) async {
    if (maos) SharedPreferences.setMockInitialValues({PreferenciasConversa.prefMaosLivres: true});
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (paleta != null) {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = paleta;
    }
    voz = _Voz()
      ..liberado = liberado
      ..prender = prender;
    rec = _Rec(voz.log, ok: suportado);
    await tester.pumpWidget(BlocProvider.value(
      value: ia,
      child: MaterialApp(
        theme: Mixart.tema(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => ConversaPage(cenario: _cafe, nivel: 'A1', voz: voz, reconhecedor: rec))),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await anda(tester);
  }

  final campo = find.byKey(const Key('campo-conversa'));
  final mic = find.byKey(const Key('microfone-conversa'));
  final chip = find.byKey(const Key('chip-maos-livres'));
  final ouvindo = find.byKey(const Key('ouvindo-maos-livres'));
  final falandoK = find.byKey(const Key('personagem-falando'));
  String textoDoCampo(WidgetTester tester) => tester.widget<TextField>(campo).controller!.text;

  /// Segura o 🎤 (passa do toque curto), fala [texto] e solta; o navegador entrega o fim.
  Future<void> seguraEFala(WidgetTester tester, String texto) async {
    final g = await tester.startGesture(tester.getCenter(mic));
    await tester.pump(const Duration(milliseconds: 500));
    rec.escutas.last.parcial(texto.split(' ').first);
    await tester.pump();
    rec.escutas.last.falou([texto]); // o navegador fecha a frase: com o dedo no 🎤, reabre
    await tester.pump();
    await g.up();
    await tester.pump();
    rec.escutas.last.falou(const []);
    await anda(tester);
  }

  testWidgets('⋮ › 🙌 Mãos-livres liga (e salva), mostra o chip; desligar volta ao ditado de sempre', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, maos: false);
    expect(chip, findsNothing);
    expect(find.byTooltip('Falar em inglês'), findsOneWidget);
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    expect(find.text('🙌 Mãos-livres'), findsOneWidget);
    await tester.tap(find.byKey(const Key('alternar-maos-livres')));
    await tester.pumpAndSettle();
    await anda(tester);
    expect(await tester.runAsync(PreferenciasConversa.maosLivres), isTrue);
    expect(chip, findsOneWidget);
    expect(find.byTooltip('Falar em inglês'), findsNothing);
    expect(find.bySemanticsLabel('Segure para falar em inglês'), findsOneWidget);
    expect(find.byKey(const Key('faixa-maos-livres')), findsOneWidget);
    // desliga
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    expect(find.text('🙌 Desligar o mãos-livres'), findsOneWidget);
    await tester.tap(find.byKey(const Key('alternar-maos-livres')));
    await tester.pumpAndSettle();
    await anda(tester);
    expect(await tester.runAsync(PreferenciasConversa.maosLivres), isFalse);
    expect(chip, findsNothing);
    expect(find.byTooltip('Falar em inglês'), findsOneWidget);
  });

  testWidgets('ligar com o ditado aberto: o ditado desiste (nada vai ao campo)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, maos: false);
    await tester.tap(mic);
    await tester.pump();
    final e = rec.escutas.last;
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('alternar-maos-livres')));
    await tester.pumpAndSettle();
    expect(e.cancelada, isTrue);
    e.falou(['late words']);
    await anda(tester);
    expect(textoDoCampo(tester), isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('segurar e soltar envia sozinho; a voz lê a resposta; o 🎤 NÃO abre durante a fala; abre quando ela acaba',
      (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    expect(chip, findsOneWidget);
    expect(rec.escutas, isEmpty, reason: 'sem som liberado a abertura não é lida e nada abre sozinho');
    await seguraEFala(tester, 'I want a coffee');
    expect(tutor.chamadas, 1, reason: 'enviou sozinho');
    expect(tutor.perguntas.single, contains('I want a coffee'));
    expect(textoDoCampo(tester), isEmpty, reason: 'não passa pelo campo');
    expect(find.text('Sure! What size would you like?'), findsOneWidget);
    expect(voz.log.where((l) => l.startsWith('falar')), ['falar:Sure! What size would you like?']);
    // a voz soando: nenhum microfone aberto
    final antes = rec.escutas.length;
    await tester.pump(const Duration(seconds: 5));
    expect(rec.escutas.length, antes);
    expect(falandoK, findsOneWidget);
    expect(ouvindo, findsNothing);
    // a voz acabou: a vez abre sozinha, calando o app antes
    voz.acabar();
    await anda(tester);
    expect(rec.escutas.length, antes + 1);
    expect(voz.log.sublist(voz.log.length - 2), ['calarTudo', 'ouvir']);
    expect(ouvindo, findsOneWidget);
    expect(find.text('🎙️ ${ControladorMaosLivres.recadoSuaVez}'), findsOneWidget);
    expect(find.byKey(const Key('parar-maos-livres')), findsOneWidget);
    // a correção ganhou o 🔊 com texto
    expect(find.text('Ouvir o jeito certo'), findsOneWidget);
    // diz e o silêncio envia
    rec.escutas.last.falou(['A small one, please']);
    await tester.pump(const Duration(milliseconds: 1600));
    await anda(tester);
    expect(tutor.chamadas, 2);
  });

  testWidgets('a vez aberta sem nada dito: em 8 s fecha e mostra "Toque no 🎤 para falar"; o ⏹ fecha sem enviar', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, prender: false);
    await seguraEFala(tester, 'I want a coffee');
    expect(ouvindo, findsOneWidget, reason: 'sem prender a voz, a vez abre logo');
    final e = rec.escutas.last;
    await tester.pump(const Duration(seconds: 8));
    expect(e.cancelada, isTrue);
    expect(ouvindo, findsNothing);
    expect(find.text(ControladorMaosLivres.recadoToque), findsOneWidget);
    // um toque abre a vez de novo; o ⏹ fecha sem enviar
    await tester.tap(mic);
    await tester.pump();
    expect(ouvindo, findsOneWidget);
    rec.escutas.last.parcial('A small');
    await tester.pump();
    expect(find.byKey(const Key('parcial-conversa')), findsOneWidget);
    await tester.tap(find.byKey(const Key('parar-maos-livres')));
    await tester.pump();
    expect(rec.escutas.last.cancelada, isTrue);
    expect(ouvindo, findsNothing);
    await tester.pump(const Duration(seconds: 3));
    expect(tutor.chamadas, 1);
  });

  testWidgets('soltar sem dizer nada: "Não ouvi nada — tente de novo", nada é enviado', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    final g = await tester.startGesture(tester.getCenter(mic));
    await tester.pump(const Duration(milliseconds: 600));
    expect(ouvindo, findsOneWidget);
    expect(find.text('🎙️ Ouvindo… solte para enviar'), findsOneWidget);
    await g.up();
    await tester.pump();
    rec.escutas.last.falou(const []);
    await anda(tester);
    expect(find.text(ControladorMaosLivres.recadoNaoOuvi), findsOneWidget);
    expect(tutor.chamadas, 0);
  });

  testWidgets('pref ligada e som liberado: a abertura é lida e, quando acaba, a vez abre', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, liberado: true);
    expect(voz.log, ['falar:Hi! What can I get for you?']);
    expect(falandoK, findsOneWidget);
    voz.acabar();
    await anda(tester);
    expect(ouvindo, findsOneWidget);
    expect(find.byKey(const Key('ideias-maos-livres')), findsOneWidget, reason: 'A1: as ideias ficam à vista para ler em voz alta');
  });

  testWidgets('voz automática desligada: a vez abre logo que a resposta chega', (tester) async {
    SharedPreferences.setMockInitialValues({PreferenciasConversa.prefMaosLivres: true, PreferenciasConversa.prefVozAuto: false});
    final ia = await criar(tester);
    await montar(tester, ia, maos: false);
    expect(chip, findsOneWidget);
    await seguraEFala(tester, 'I want a coffee');
    expect(voz.log.where((l) => l.startsWith('falar')), isEmpty);
    expect(ouvindo, findsOneWidget);
  });

  testWidgets('🔊 "Ouvir o jeito certo": lê a frase corrigida e devolve a vez quando acaba', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, prender: false);
    await seguraEFala(tester, 'I want a coffee');
    expect(ouvindo, findsOneWidget);
    final e = rec.escutas.last;
    voz.prender = true;
    await tester.tap(find.byKey(const Key('ouvir-correcao-1')));
    await tester.pump();
    expect(e.cancelada, isTrue, reason: 'a vez aberta fecha: o microfone ouviria a voz');
    expect(voz.log.last, 'falar:Can I have a coffee, please?');
    expect(falandoK, findsOneWidget);
    final n = rec.escutas.length;
    voz.acabar();
    await anda(tester);
    expect(rec.escutas.length, n + 1);
    expect(ouvindo, findsOneWidget);
  });

  testWidgets('a fala falha: volta ao campo e o microfone não abre sozinho', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    tutor.respostas.add(const FalhaIa(TipoFalhaIa.semRede));
    final n0 = rec.escutas.length;
    await seguraEFala(tester, 'I want a coffee');
    expect(find.byKey(const Key('cenario-sem-rede')), findsOneWidget);
    expect(textoDoCampo(tester), 'I want a coffee');
    final n = rec.escutas.length;
    expect(n, greaterThan(n0));
    await tester.pump(const Duration(seconds: 10));
    expect(rec.escutas.length, n);
    expect(ouvindo, findsNothing);
    // o aluno segura de novo: o que disser vai (o campo fica como estava)
    await seguraEFala(tester, 'A coffee please');
    expect(tutor.chamadas, 2);
  });

  testWidgets('a conversa acaba (fim:true): a última fala é lida e o microfone não abre', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await seguraEFala(tester, 'I want a coffee');
    voz.acabar();
    await anda(tester);
    expect(ouvindo, findsOneWidget);
    // na vez aberta sozinha: diz, o silêncio envia, e a resposta encerra a conversa
    tutor.respostas.add(respostaJson(precisa: false, fim: true, fala: 'Great, see you!'));
    rec.escutas.last.falou(['A small one, please']);
    await tester.pump(const Duration(milliseconds: 1600));
    await anda(tester);
    await tester.pumpAndSettle();
    expect(tutor.chamadas, 2);
    expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
    expect(voz.log.last, 'falar:Great, see you!');
    final n = rec.escutas.length;
    voz.acabar();
    await anda(tester);
    expect(rec.escutas.length, n);
    expect(tester.takeException(), isNull);
  });

  testWidgets('⋮ › Terminar com a vez aberta: cancela a escuta, sem erro', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, prender: false);
    await seguraEFala(tester, 'I want a coffee');
    final e = rec.escutas.last;
    expect(ouvindo, findsOneWidget);
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('terminar-conversa')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
    expect(e.cancelada, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('voltar (pede confirmação) com a vez aberta: o microfone fecha já; sair cancela tudo', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await seguraEFala(tester, 'I want a coffee');
    voz.acabar();
    await anda(tester);
    final e = rec.escutas.last;
    expect(ouvindo, findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(e.cancelada, isTrue, reason: 'o diálogo por cima fecha o microfone');
    final n = rec.escutas.length;
    await tester.tap(find.byKey(const Key('sair-conversa-confirmar')));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
    expect(rec.escutas.length, n);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sair da página com a voz soando: depois dela nada abre', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, liberado: true);
    expect(falandoK, findsOneWidget);
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
    voz.acabar();
    await anda(tester);
    expect(rec.escutas, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sem reconhecimento de voz: o item fica desabilitado com o motivo; a pref ligada não quebra nada', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, suportado: false);
    expect(chip, findsNothing);
    expect(mic, findsNothing);
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    final item = tester.widget<PopupMenuItem<String>>(find.byKey(const Key('alternar-maos-livres')));
    expect(item.enabled, isFalse);
    expect(find.byKey(const Key('motivo-maos-livres')), findsOneWidget);
    await tester.tap(find.byKey(const Key('alternar-maos-livres')), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(chip, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('microfone bloqueado na 1ª escuta: o modo desliga, o recado explica e o menu mostra o motivo', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await tester.tap(mic);
    await tester.pump();
    rec.escutas.last.deuErro(ErroFala.semPermissao);
    await anda(tester);
    expect(chip, findsNothing);
    expect(find.byKey(const Key('recado-microfone')), findsOneWidget);
    expect(find.textContaining('O microfone está bloqueado'), findsOneWidget);
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    expect(tester.widget<PopupMenuItem<String>>(find.byKey(const Key('alternar-maos-livres'))).enabled, isFalse);
  });

  testWidgets('teclado: Tab chega no 🎤 e Espaço segura (apertou ouve, soltou envia)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await tester.tap(campo);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(rec.escutas, isEmpty);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump(const Duration(milliseconds: 500));
    expect(rec.escutas, hasLength(1), reason: 'o foco está no 🎤: Espaço abre o microfone');
    expect(find.text('🎙️ Ouvindo… solte para enviar'), findsOneWidget);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(rec.escutas, hasLength(1), reason: 'a repetição da tecla não faz nada');
    rec.escutas.last.falou(['I want a coffee']);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    rec.escutas.last.falou(const []);
    await anda(tester);
    expect(tutor.chamadas, 1);
    expect(tutor.perguntas.single, contains('I want a coffee'));
    expect(textoDoCampo(tester), isEmpty, reason: 'o Espaço não foi para o campo');
  });

  testWidgets('o botão direito do mouse no 🎤 não abre o microfone (o menu do navegador engoliria o soltar)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    final g = await tester.startGesture(tester.getCenter(mic), kind: PointerDeviceKind.mouse, buttons: kSecondaryMouseButton);
    await tester.pump(const Duration(milliseconds: 600));
    expect(rec.escutas, isEmpty);
    expect(ouvindo, findsNothing);
    await g.up();
    await tester.pump();
    // o botão principal segura normalmente
    final g2 = await tester.startGesture(tester.getCenter(mic), kind: PointerDeviceKind.mouse);
    await tester.pump(const Duration(milliseconds: 600));
    expect(rec.escutas, hasLength(1));
    await g2.up();
    await tester.pump();
    rec.escutas.last.falou(const []);
    await anda(tester);
  });

  testWidgets('na janela de descanso o 🎤 fica apagado e não grava (a fala se perderia)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    tutor.respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429));
    await seguraEFala(tester, 'I want a coffee');
    expect(find.byKey(const Key('cenario-limite')), findsOneWidget);
    expect(textoDoCampo(tester), 'I want a coffee');
    expect(find.bySemanticsLabel('Espere a IA liberar'), findsOneWidget);
    final n = rec.escutas.length;
    final g = await tester.startGesture(tester.getCenter(mic));
    await tester.pump(const Duration(milliseconds: 600));
    expect(rec.escutas.length, n);
    expect(ouvindo, findsNothing);
    await g.up();
    await anda(tester);
    expect(textoDoCampo(tester), 'I want a coffee');
    expect(tutor.chamadas, 1);
  });

  for (final tamanho in const [Size(360, 640), Size(1027, 768)]) {
    for (final paleta in [Paleta.flutterClaro, Paleta.mixart]) {
      final nome = '${tamanho.width.toInt()}×${tamanho.height.toInt()} (${paleta == Paleta.mixart ? 'escuro' : 'claro'})';
      testWidgets('$nome: ocioso, ouvindo com parcial, personagem falando e erro — sem estouro', (tester) async {
        final ia = await criar(tester);
        await montar(tester, ia, tamanho: tamanho, paleta: paleta);
        expect(tester.takeException(), isNull);
        expect(chip, findsOneWidget);
        expect(find.byKey(const Key('sugestoes-conversa')), findsOneWidget, reason: 'A1 ocioso: as ideias ao lado do chip');
        // segurando, com um parcial comprido
        final g = await tester.startGesture(tester.getCenter(mic));
        await tester.pump(const Duration(milliseconds: 500));
        rec.escutas.last.parcial('I would like a very large iced caramel latte with oat milk and an extra shot of espresso please');
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.byKey(const Key('faixa-maos-livres'))).height, lessThanOrEqualTo(72));
        rec.escutas.last.falou(['I want a coffee']);
        await tester.pump();
        await g.up();
        await tester.pump();
        rec.escutas.last.falou(const []);
        await anda(tester);
        expect(falandoK, findsOneWidget);
        expect(tester.takeException(), isNull);
        voz.acabar();
        await anda(tester);
        expect(ouvindo, findsOneWidget);
        expect(tester.takeException(), isNull);
        // um erro com a vez fechada
        await tester.tap(find.byKey(const Key('parar-maos-livres')));
        await tester.pump();
        tutor.respostas.add(const FalhaIa(TipoFalhaIa.semRede));
        await seguraEFala(tester, 'A small one');
        expect(find.byKey(const Key('cenario-sem-rede')), findsOneWidget);
        expect(tester.takeException(), isNull);
        expect(tester.getRect(campo).bottom, lessThanOrEqualTo(tamanho.height));
      });
    }
  }
}
