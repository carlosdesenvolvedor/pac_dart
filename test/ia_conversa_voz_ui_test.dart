import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/ia/domain/cenario.dart';
import 'package:pac_dart/features/ia/presentation/conversa_page.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ia/presentation/preferencias_conversa.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/boca.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/painel_shadowing.dart';
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

/// A voz que grava tudo, em ordem: as falas (com a velocidade pedida e a pref no momento) e o calarTudo.
class _Voz extends VozFake {
  final log = <String>[];
  final lentas = <bool?>[];
  final prefNaHora = <bool>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) {
    log.add('falar:$frase');
    lentas.add(lenta);
    prefNaHora.add(VozIngles.lentaPorPadrao);
    return super.falar(frase, lenta: lenta);
  }

  @override
  Future<void> calarTudo() async => log.add('calarTudo');
}

/// O reconhecedor falso que também anota o idioma e entra no mesmo log da voz.
class _Rec extends ReconhecedorFalso {
  final List<String> log;
  _Rec(this.log, {super.ok});
  final idiomas = <String>[];
  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    log.add('ouvir');
    idiomas.add(idioma);
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

  /// A conversa (atrás de uma tela "abrir", para dar para sair) com a voz e o microfone falsos.
  Future<void> montar(WidgetTester tester, IaCubit ia,
      {bool liberado = false, bool suportado = true, PalavrasCubit? palavras, bool abrir = true}) async {
    tester.view.physicalSize = const Size(900, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    voz = _Voz()..liberado = liberado;
    rec = _Rec(voz.log, ok: suportado);
    Widget app = MaterialApp(
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
    );
    app = BlocProvider.value(value: ia, child: app);
    if (palavras != null) app = BlocProvider.value(value: palavras, child: app);
    await tester.pumpWidget(app);
    if (abrir) {
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await anda(tester);
    }
  }

  final campo = find.byKey(const Key('campo-conversa'));
  final mic = find.byKey(const Key('microfone-conversa'));
  String textoDoCampo(WidgetTester tester) => tester.widget<TextField>(campo).controller!.text;

  Future<void> fala(WidgetTester tester, String texto) async {
    await tester.enterText(campo, texto);
    await tester.tap(find.byKey(const Key('enviar-conversa')));
    await anda(tester);
  }

  testWidgets('voz automática ligada: a fala nova é lida EXATAMENTE como está na bolha', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await fala(tester, 'I want a coffee');
    expect(find.text('Sure! What size would you like?'), findsOneWidget);
    expect(voz.log, ['falar:Sure! What size would you like?']);
    expect(voz.lentas, [null], reason: 'na velocidade da pref');
  });

  testWidgets('voz automática desligada (pref): nada é lido; o menu liga de novo e salva', (tester) async {
    SharedPreferences.setMockInitialValues({PreferenciasConversa.prefVozAuto: false});
    final ia = await criar(tester);
    await montar(tester, ia, liberado: true);
    await fala(tester, 'I want a coffee');
    expect(voz.log, isEmpty, reason: 'nem a abertura nem a resposta');
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    expect(find.text('Ler as falas em voz alta'), findsOneWidget);
    await tester.tap(find.byKey(const Key('alternar-voz')));
    await tester.pumpAndSettle();
    await anda(tester);
    expect(await tester.runAsync(PreferenciasConversa.vozAuto), isTrue);
    await fala(tester, 'A small one');
    expect(voz.log, ['falar:Sure! What size would you like?']);
  });

  testWidgets('com o microfone aberto a resposta NÃO é lida (o 🔊 da bolha continua lendo)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await tester.enterText(campo, 'I want a coffee');
    await tester.tap(mic);
    await tester.pump();
    expect(find.byKey(const Key('ouvindo-conversa')), findsOneWidget);
    await tester.tap(find.byKey(const Key('enviar-conversa')));
    await anda(tester);
    expect(find.text('Sure! What size would you like?'), findsOneWidget);
    expect(voz.log.where((l) => l.startsWith('falar')), isEmpty);
    await tester.tap(find.byKey(const Key('ouvir-fala-2')));
    await tester.pump();
    expect(voz.log.last, 'falar:Sure! What size would you like?');
    rec.escutas.last.falou(const []);
    await anda(tester);
  });

  testWidgets('🔊 lê na velocidade da pref e 🐢 devagar', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await tester.tap(find.byKey(const Key('ouvir-fala-0')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('ouvir-devagar-0')));
    await tester.pump();
    expect(voz.log, ['falar:Hi! What can I get for you?', 'falar:Hi! What can I get for you?']);
    expect(voz.lentas, [null, true]);
  });

  testWidgets('a abertura só é lida com o som liberado', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, liberado: true);
    expect(voz.log, ['falar:Hi! What can I get for you?']);
  });

  testWidgets('a abertura não é lida antes do 1º gesto (som preso)', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    expect(voz.log, isEmpty);
    expect(find.byKey(const Key('ouvir-fala-0')), findsOneWidget);
  });

  testWidgets('a velocidade da pref é lida ao abrir a conversa (sem passar pelo palco), antes da abertura', (tester) async {
    SharedPreferences.setMockInitialValues({VozIngles.prefLenta: false});
    VozIngles.lentaPorPadrao = true;
    final ia = await criar(tester);
    await montar(tester, ia, liberado: true);
    expect(voz.log, ['falar:Hi! What can I get for you?']);
    expect(voz.prefNaHora, [false]);
    expect(VozIngles.lentaPorPadrao, isFalse);
  });

  testWidgets('o avatar do topo mexe a boca com a fala do personagem, nunca com a voz da correção', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    // o cursor piscando também é animação: a fala vai com o campo sem foco
    await tester.enterText(campo, 'I want a coffee');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.tap(find.byKey(const Key('enviar-conversa')));
    await anda(tester);
    await tester.pump(const Duration(seconds: 5));
    final topo = find.descendant(of: find.byKey(const Key('avatar-conversa')), matching: find.byType(PersonagemFalante));
    expect(tester.widget<PersonagemFalante>(topo).frase, 'Sure! What size would you like?');
    expect(tester.hasRunningAnimations, isFalse);
    // a voz do "jeito certo" (o 🔊 da correção): ninguém mexe a boca
    VozIngles.falando.value = FalaEmCurso(
      frase: 'Can I have a coffee, please?',
      boca: TrilhaBoca.doTexto('Can I have a coffee, please?', segPorPalavra: .34),
      inicio: DateTime.now(),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isFalse);
    // a fala do personagem: o topo (e a bolha dela) mexem a boca
    VozIngles.falando.value = FalaEmCurso(
      frase: 'Sure! What size would you like?',
      boca: TrilhaBoca.doTexto('Sure! What size would you like?', segPorPalavra: .34),
      inicio: DateTime.now(),
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    VozIngles.falando.value = null;
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isFalse);
    // o 🔊 da correção lê o jeito certo e NÃO troca a fala que o topo acompanha
    await tester.tap(find.byKey(const Key('ouvir-correcao-1')));
    await tester.pump();
    expect(voz.log.last, 'falar:Can I have a coffee, please?');
    expect(tester.widget<PersonagemFalante>(topo).frase, 'Sure! What size would you like?');
  });

  testWidgets('🎤: cala o app ANTES de ouvir (en-US), mostra o parcial e o resultado vai para o CAMPO, sem enviar', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    expect(tester.getSemantics(mic.first).label, isNotNull);
    await tester.tap(mic);
    await tester.pump();
    expect(voz.log, ['calarTudo', 'ouvir']);
    expect(rec.idiomas, ['en-US']);
    expect(find.byKey(const Key('ouvindo-conversa')), findsOneWidget);
    expect(find.byKey(const Key('sugestoes-conversa')), findsNothing, reason: 'o painel toma o lugar das ideias');
    expect(find.byTooltip('Parar de ouvir'), findsOneWidget);
    rec.escutas.last.parcial('I want a');
    await tester.pump();
    expect(find.text('I want a'), findsOneWidget);
    expect(find.byKey(const Key('parcial-conversa')), findsOneWidget);
    rec.escutas.last.falou(['I want a coffee', 'I want coffee']);
    await anda(tester);
    expect(textoDoCampo(tester), 'I want a coffee');
    expect(tutor.chamadas, 0, reason: 'o microfone nunca envia sozinho');
    expect(find.byKey(const Key('recado-microfone')), findsOneWidget);
    expect(find.text('Confira o texto e toque em Enviar.'), findsOneWidget);
    expect(find.byKey(const Key('ouvindo-conversa')), findsNothing);
    expect(find.byTooltip('Falar em inglês'), findsOneWidget);
    // a pessoa confere e envia
    await tester.tap(find.byKey(const Key('enviar-conversa')));
    await anda(tester);
    expect(tutor.chamadas, 1);
    expect(find.byKey(const Key('recado-microfone')), findsNothing);
  });

  testWidgets('🎤 sem ouvir nada: a mensagem do shadowing aparece', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await tester.tap(mic);
    await tester.pump();
    rec.escutas.last.deuErro(ErroFala.naoOuviu);
    await anda(tester);
    expect(find.text(PainelShadowingState.textoDoErro(ErroFala.naoOuviu)), findsOneWidget);
    expect(textoDoCampo(tester), isEmpty);
  });

  testWidgets('sem reconhecimento de voz: nada de 🎤', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia, suportado: false);
    expect(campo, findsOneWidget);
    expect(mic, findsNothing);
  });

  testWidgets('"Parar" que nunca termina: solta sozinho em 2 s; o que chegar depois é ignorado', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await tester.tap(mic);
    await tester.pump();
    final e = rec.escutas.last;
    await tester.tap(mic);
    await tester.pump();
    expect(e.parada, isTrue);
    expect(find.byKey(const Key('ouvindo-conversa')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(e.cancelada, isTrue);
    expect(find.byKey(const Key('ouvindo-conversa')), findsNothing);
    expect(find.byTooltip('Falar em inglês'), findsOneWidget);
    e.falou(['late words']);
    await tester.pump();
    expect(textoDoCampo(tester), isEmpty);
  });

  testWidgets('sair da tela com o microfone aberto cancela a escuta', (tester) async {
    final ia = await criar(tester);
    await montar(tester, ia);
    await tester.tap(mic);
    await tester.pump();
    final e = rec.escutas.last;
    await tester.tap(find.byTooltip('Voltar'));
    await tester.pumpAndSettle();
    expect(find.text('abrir'), findsOneWidget);
    expect(e.cancelada, isTrue);
    expect(tester.takeException(), isNull);
  });

  group('microfone aberto quando a conversa acaba', () {
    testWidgets('⋮ › Terminar conversa com o 🎤 ouvindo: cancela a escuta, sem setState com a árvore travada', (tester) async {
      final ia = await criar(tester);
      await montar(tester, ia);
      await fala(tester, 'I want a coffee');
      await tester.tap(mic);
      await tester.pump();
      expect(find.byKey(const Key('ouvindo-conversa')), findsOneWidget);
      final e = rec.escutas.last;
      await tester.tap(find.byKey(const Key('menu-conversa')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('terminar-conversa')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
      expect(e.cancelada, isTrue);
      expect(mic, findsNothing);
    });

    testWidgets('a resposta com fim:true chega com o 🎤 ouvindo: o rodapé some sem erro', (tester) async {
      final ia = await criar(tester);
      await montar(tester, ia);
      await fala(tester, 'I want a coffee');
      tutor.respostas.add(respostaJson(precisa: false, fim: true, fala: 'Great, see you!'));
      await tester.enterText(campo, 'A small one');
      await tester.tap(mic);
      await tester.pump();
      final e = rec.escutas.last;
      await tester.tap(find.byKey(const Key('enviar-conversa')));
      await anda(tester);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
      expect(e.cancelada, isTrue);
    });
  });

  group('o recado do microfone na faixa', () {
    testWidgets('com a janela do 429 aberta, o aviso (com a contagem) fica na frente do "toque em Enviar"', (tester) async {
      final ia = await criar(tester);
      await montar(tester, ia);
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429));
      await fala(tester, 'I want a coffee');
      expect(find.byKey(const Key('cenario-limite')), findsOneWidget);
      await tester.enterText(campo, '');
      await tester.tap(mic);
      await tester.pump();
      rec.escutas.last.falou(['I want a coffee please']);
      await anda(tester);
      expect(textoDoCampo(tester), 'I want a coffee please');
      expect(find.byKey(const Key('cenario-limite')), findsOneWidget);
      expect(find.byKey(const Key('recado-microfone')), findsNothing);
    });

    testWidgets('mexeu no campo: o recado sai e as ideias (A1) voltam', (tester) async {
      final ia = await criar(tester);
      await montar(tester, ia);
      await tester.tap(mic);
      await tester.pump();
      rec.escutas.last.deuErro(ErroFala.naoOuviu);
      await anda(tester);
      expect(find.byKey(const Key('recado-microfone')), findsOneWidget);
      expect(find.byKey(const Key('sugestoes-conversa')), findsNothing);
      await tester.enterText(campo, 'A small');
      await tester.pump();
      expect(find.byKey(const Key('recado-microfone')), findsNothing);
      expect(find.byKey(const Key('sugestoes-conversa')), findsOneWidget);
    });

    testWidgets('um erro novo depois do ditado aparece no lugar do recado velho', (tester) async {
      final ia = await criar(tester);
      await montar(tester, ia);
      await tester.tap(mic);
      await tester.pump();
      rec.escutas.last.falou(['I want a coffee']);
      await anda(tester);
      expect(find.byKey(const Key('recado-microfone')), findsOneWidget);
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.semRede));
      // a resposta da fala falha (sem rede): o aviso dela vale mais que o "Confira o texto"
      final c = tester.widget<TextField>(campo).controller!;
      c.text = 'I want a coffee';
      await tester.pump();
      await tester.tap(find.byKey(const Key('enviar-conversa')));
      await anda(tester);
      expect(find.byKey(const Key('cenario-sem-rede')), findsOneWidget);
      expect(find.byKey(const Key('recado-microfone')), findsNothing);
    });
  });

  group('palavras novas no resumo', () {
    Future<PalavrasCubit> palavrasCubit(WidgetTester tester) async {
      final p = PalavrasCubit(repo: MemoriaPalavrasRepository(), carregarDicionario: () async => Dicionario.vazio);
      await tester.runAsync(p.carregar);
      addTearDown(() => tester.runAsync(p.close));
      return p;
    }

    Future<void> terminar(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('menu-conversa')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('terminar-conversa')));
      await tester.pumpAndSettle();
    }

    testWidgets('"Adicionar 1 às Minhas palavras" põe no banco; depois a palavra aparece como já sua', (tester) async {
      final ia = await criar(tester);
      final p = await palavrasCubit(tester);
      await montar(tester, ia, palavras: p);
      await fala(tester, 'I want a coffee');
      await terminar(tester);
      expect(find.byKey(const Key('resumo-palavras')), findsOneWidget);
      expect(find.text('size — tamanho'), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('adicionar-palavras')));
      expect(find.text('Adicionar 1 às Minhas palavras'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adicionar-palavras')));
      await tester.pump();
      expect(p.state.banco['size']?.pt, 'tamanho');
      expect(p.state.banco['size']?.exemplo, 'Sure! What size would you like?');
      expect(find.text('1 palavra entrou em Minhas palavras.'), findsOneWidget);
      expect(find.text('já está nas suas palavras'), findsOneWidget);
      expect(tester.widget<CheckboxListTile>(find.byKey(const Key('palavra-size'))).onChanged, isNull);
    });

    testWidgets('palavra que já está no banco: desmarcada e desligada', (tester) async {
      final ia = await criar(tester);
      final p = await palavrasCubit(tester);
      expect(p.adicionar('size', 'tamanho'), isNull);
      await montar(tester, ia, palavras: p);
      await fala(tester, 'I want a coffee');
      await terminar(tester);
      final tile = tester.widget<CheckboxListTile>(find.byKey(const Key('palavra-size')));
      expect(tile.value, isFalse);
      expect(tile.onChanged, isNull);
      expect(find.text('já está nas suas palavras'), findsOneWidget);
      expect(find.text('✓ Já estão nas suas palavras'), findsOneWidget);
      expect(find.textContaining('Adicionar 0'), findsNothing);
    });

    testWidgets('palavra desmarcada: o botão diz "Nenhuma palavra marcada" (nunca "Adicionar 0")', (tester) async {
      final ia = await criar(tester);
      final p = await palavrasCubit(tester);
      await montar(tester, ia, palavras: p);
      await fala(tester, 'I want a coffee');
      await terminar(tester);
      await tester.ensureVisible(find.byKey(const Key('palavra-size')));
      await tester.tap(find.byKey(const Key('palavra-size')));
      await tester.pump();
      expect(find.text('Nenhuma palavra marcada'), findsOneWidget);
      expect(tester.widget<OutlinedButton>(find.byKey(const Key('adicionar-palavras'))).onPressed, isNull);
    });

    testWidgets('expressões do modelo (check-in, go over) nem aparecem: só "luggage", e o Adicionar não mostra erro', (tester) async {
      final ia = await criar(tester);
      final p = await palavrasCubit(tester);
      await montar(tester, ia, palavras: p);
      final r = jsonDecode(respostaJson()) as Map<String, dynamic>;
      r['palavras'] = [
        {'en': 'check-in', 'pt': 'check-in'},
        {'en': 'go over', 'pt': 'revisar'},
        {'en': 'luggage', 'pt': 'bagagem'},
      ];
      tutor.respostas.add(jsonEncode(r));
      await fala(tester, 'I want a coffee');
      await terminar(tester);
      expect(find.byKey(const Key('palavra-luggage')), findsOneWidget);
      expect(find.byKey(const Key('palavra-check-in')), findsNothing);
      expect(find.byKey(const Key('palavra-go over')), findsNothing);
      await tester.ensureVisible(find.byKey(const Key('adicionar-palavras')));
      await tester.tap(find.byKey(const Key('adicionar-palavras')));
      await tester.pump();
      expect(p.state.banco['luggage'], isNotNull);
      expect(find.textContaining('Use só letras'), findsNothing);
      expect(find.textContaining('Escreva'), findsNothing);
    });
  });
}
