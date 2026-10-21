import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/habito/domain/habito.dart' show diaDe;
import 'package:pac_dart/features/ia/domain/cenario.dart';
import 'package:pac_dart/features/ia/domain/cota_ia.dart';
import 'package:pac_dart/features/ia/presentation/cenarios_page.dart';
import 'package:pac_dart/features/ia/presentation/conversa_page.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ia/presentation/preferencias_conversa.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/elenco_ingles.dart';
import 'package:pac_dart/features/tutor/data/falha_ia.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/tutor_falso.dart';
import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria;
import 'ingles_cartoes_ui_test.dart' show VozFake;

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
  dicas: ['A small latte, please.', 'How much is it?'],
  maxTurnos: 3,
);

/// Os 13 cenários de verdade (lidos do asset fora do relógio falso).
List<Cenario> _todos() => cenariosDeJson(jsonDecode(File('assets/ingles/cenarios.json').readAsStringSync()));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late TutorConversaFalso tutor;
  late CotaMemoria cotaRepo;
  late DateTime agora;

  Future<IaCubit> criar(WidgetTester tester, {CotaMemoria? cota}) async {
    tutor = TutorConversaFalso();
    cotaRepo = cota ?? CotaMemoria();
    agora = DateTime(2026, 10, 13, 10);
    final ia = IaCubit(service: tutor, cotaRepo: cotaRepo, cache: CacheMemoria(), agora: () => agora);
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

  Future<void> montar(WidgetTester tester, Widget tela, {IaCubit? ia, Size tamanho = const Size(900, 1000), Paleta? paleta}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    if (paleta != null) {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = paleta;
    }
    Widget app = MaterialApp(theme: Mixart.tema(), home: tela);
    if (ia != null) app = BlocProvider.value(value: ia, child: app);
    await tester.pumpWidget(app);
    await anda(tester);
  }

  ConversaPage pagina(Cenario c, {String nivel = 'A1'}) => ConversaPage(cenario: c, nivel: nivel, voz: VozFake()..liberado = false);

  final campo = find.byKey(const Key('campo-conversa'));
  TextEditingController controle(WidgetTester tester) => tester.widget<TextField>(campo).controller!;

  Future<void> fala(WidgetTester tester, String texto) async {
    await tester.enterText(campo, texto);
    await tester.tap(find.byKey(const Key('enviar-conversa')));
    await anda(tester);
  }

  Future<void> terminar(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('menu-conversa')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('terminar-conversa')));
    await tester.pumpAndSettle();
  }

  group('a lista de situações', () {
    testWidgets('as 13 situações por etapa, o saldo, o nível escolhido (salvo) e o selo "acima do seu nível"', (tester) async {
      final ia = await criar(tester);
      final todos = _todos();
      expect(todos.length, 13);
      await montar(tester, CenariosPage(carregador: () async => todos), ia: ia, tamanho: const Size(900, 4000));
      expect(find.text('Conversa com IA'), findsOneWidget);
      expect(find.text('Restam 30 usos hoje · cada fala usa 1'), findsOneWidget);
      for (final c in todos) {
        expect(find.byKey(Key('cenario-${c.id}')), findsOneWidget);
      }
      // A1 → C1, na ordem
      double y(String id) => tester.getTopLeft(find.byKey(Key('cenario-$id'))).dy;
      expect(y('cafe'), lessThan(y('hotel')));
      expect(y('hotel'), lessThan(y('entrevista')));
      expect(y('entrevista'), lessThan(y('daily')));
      expect(y('daily'), lessThan(y('negociacao')));
      expect(find.text('com Emma · ${todos.first.objetivo}'), findsOneWidget);
      expect(find.byType(RostoPersonagem), findsNWidgets(13));
      // sem curso na árvore: automático = A1
      expect(find.text('Automático (A1)'), findsOneWidget);
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('nivel-conversa-auto'))).selected, isTrue);
      expect(find.byKey(const Key('acima-cafe')), findsNothing);
      expect(find.byKey(const Key('acima-entrevista')), findsOneWidget);
      expect(find.byKey(const Key('acima-negociacao')), findsOneWidget);

      await tester.tap(find.byKey(const Key('nivel-conversa-B1')));
      await anda(tester);
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('nivel-conversa-B1'))).selected, isTrue);
      expect(find.byKey(const Key('acima-entrevista')), findsNothing);
      expect(find.byKey(const Key('acima-negociacao')), findsOneWidget);
      expect(await tester.runAsync(PreferenciasConversa.nivel), 'B1');

      // a conversa abre no nível escolhido
      await tester.tap(find.byKey(const Key('cenario-hotel')));
      await anda(tester);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('objetivo-cenario')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('conversa-restantes'))).data, contains('B1'));
      expect(tutor.chamadas, 0);
    });

    testWidgets('o nível salvo volta ao abrir a lista; "Automático" apaga a escolha', (tester) async {
      SharedPreferences.setMockInitialValues({PreferenciasConversa.prefNivel: 'C1'});
      final ia = await criar(tester);
      await montar(tester, CenariosPage(carregador: () async => _todos()), ia: ia, tamanho: const Size(900, 4000));
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('nivel-conversa-C1'))).selected, isTrue);
      expect(find.byKey(const Key('acima-negociacao')), findsNothing);
      await tester.tap(find.byKey(const Key('nivel-conversa-auto')));
      await anda(tester);
      expect(await tester.runAsync(PreferenciasConversa.nivel), '');
      expect(find.byKey(const Key('acima-negociacao')), findsOneWidget);
    });

    testWidgets('lista vazia: mensagem amigável; com 1 uso: "Resta 1 uso hoje"', (tester) async {
      final ia = await criar(tester, cota: CotaMemoria(CotaIa(dia: diaDe(DateTime(2026, 10, 13)), usos: 29)));
      await montar(tester, CenariosPage(carregador: () async => const []), ia: ia);
      expect(find.textContaining('Não encontrei os cenários'), findsOneWidget);
      expect(find.text('Resta 1 uso hoje · cada fala usa 1'), findsOneWidget);
    });

    for (final largura in [360.0, 390.0, 1400.0]) {
      for (final paleta in [Paleta.flutterClaro, Paleta.mixart]) {
        testWidgets('lista em ${largura.toInt()} px (${paleta == Paleta.mixart ? 'escuro' : 'claro'}): sem estouro', (tester) async {
          final ia = await criar(tester);
          await montar(tester, CenariosPage(carregador: () async => _todos()), ia: ia, tamanho: Size(largura, 800), paleta: paleta);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('a conversa', () {
    testWidgets('abre com o rosto da Emma, o nome, o objetivo, o aviso de dados e a tradução em A1; nada gasto', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      expect(find.byType(PersonagemFalante), findsNWidgets(2), reason: 'o topo e a bolha da abertura');
      expect(find.text('Emma'), findsOneWidget);
      expect(find.text('🎯 Peça uma bebida e pague.'), findsOneWidget);
      expect(find.byKey(const Key('aviso-dados')), findsOneWidget);
      expect(find.text('Hi! What can I get for you?'), findsOneWidget);
      expect(find.text('Oi! O que posso trazer?'), findsOneWidget);
      expect(find.byKey(const Key('ver-traducao-0')), findsNothing);
      expect(find.byKey(const Key('bolha-dash')), findsOneWidget);
      expect(find.byKey(const Key('bolha-aluno')), findsNothing);
      expect(tester.widget<Text>(find.byKey(const Key('conversa-restantes'))).data, 'com Emma · A1 · restam 30 usos hoje');
      expect(tutor.chamadas, 0, reason: 'a abertura é fixa e não gasta');
    });

    testWidgets('em B1 a tradução começa escondida: "Ver tradução" abre só aquela bolha; o botão do topo liga todas', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe, nivel: 'B1'), ia: ia);
      expect(find.text('Oi! O que posso trazer?'), findsNothing);
      await tester.tap(find.byKey(const Key('ver-traducao-0')));
      await tester.pump();
      expect(find.text('Oi! O que posso trazer?'), findsOneWidget);
      await fala(tester, 'I want a coffee');
      expect(find.text('Claro! Qual tamanho você quer?'), findsNothing);
      expect(find.byKey(const Key('ver-traducao-2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('alternar-traducao')));
      await tester.pump();
      expect(find.text('Claro! Qual tamanho você quer?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('alternar-traducao')));
      await tester.pump();
      expect(find.text('Claro! Qual tamanho você quer?'), findsNothing);
    });

    testWidgets('sem IaCubit na árvore, não há conversa', (tester) async {
      await montar(tester, pagina(_cafe));
      expect(campo, findsNothing);
    });

    testWidgets('fala errada: ✏️ com o jeito certo, o porquê (sem markdown cru) e a 💡; fala certa: ✅', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      tutor.respostas.addAll([respostaJson(), respostaJson(precisa: false, fala: 'Great! Anything else?')]);
      await fala(tester, 'I want a coffee');
      expect(find.byKey(const Key('bolha-aluno')), findsOneWidget);
      expect(find.byKey(const Key('correcao-1')), findsOneWidget);
      expect(find.text('Can I have a coffee, please?'), findsOneWidget);
      expect(find.text('Posso pedir um café, por favor?'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
      expect(find.textContaining('💡 Em pedidos', findRichText: true), findsOneWidget);
      expect(find.byKey(const Key('ouvir-correcao-1')), findsOneWidget);
      expect(find.byKey(const Key('fala-certa-1')), findsNothing);
      expect(find.text('Sure! What size would you like?'), findsOneWidget);
      expect(controle(tester).text, isEmpty);
      expect(tester.widget<Text>(find.byKey(const Key('conversa-restantes'))).data, contains('restam 29 usos'));
      await fala(tester, 'A small one, please.');
      expect(find.byKey(const Key('fala-certa-3')), findsOneWidget);
      expect(find.byKey(const Key('correcao-3')), findsNothing);
    });

    testWidgets('A1: as ideias ficam à vista (dicas antes da 1ª resposta, depois as do modelo) e tocar só preenche o campo', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      expect(find.byKey(const Key('sugestoes-conversa')), findsOneWidget);
      expect(find.byKey(const Key('mostrar-sugestoes')), findsNothing);
      await tester.tap(find.byKey(const Key('sugestao-1')));
      await tester.pump();
      expect(controle(tester).text, 'How much is it?');
      expect(tutor.chamadas, 0);
      await fala(tester, 'I want a coffee');
      expect(find.descendant(of: find.byKey(const Key('sugestao-0')), matching: find.text('Small, please.')), findsOneWidget);
      await tester.tap(find.byKey(const Key('sugestao-0')));
      await tester.pump();
      expect(controle(tester).text, 'Small, please.');
      expect(tutor.chamadas, 1);
    });

    testWidgets('B1: as ideias ficam atrás de "💡 Ideias de resposta"', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe, nivel: 'B1'), ia: ia);
      expect(find.byKey(const Key('mostrar-sugestoes')), findsOneWidget);
      expect(find.byKey(const Key('sugestao-0')), findsNothing);
      await tester.tap(find.byKey(const Key('mostrar-sugestoes')));
      await tester.pump();
      expect(find.byKey(const Key('sugestao-0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('mostrar-sugestoes')));
      await tester.pump();
      expect(find.byKey(const Key('sugestao-0')), findsNothing);
    });

    testWidgets('esperando a resposta o campo continua ligado, editável e com o foco; o envio é que espera', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      tutor.segura = Completer<void>();
      await tester.tap(campo);
      await tester.enterText(campo, 'One');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('dash-digitando')), findsOneWidget);
      expect(find.text('Emma está digitando…'), findsOneWidget);
      expect(tester.widget<TextField>(campo).enabled, isNot(false));
      expect(tester.widget<TextField>(campo).readOnly, isFalse);
      expect(tester.widget<TextField>(campo).focusNode!.hasFocus, isTrue);
      await tester.enterText(campo, 'Two');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 50));
      expect(controle(tester).text, 'Two');
      expect(tutor.chamadas, 1);
      tutor.segura!.complete();
      await anda(tester);
      expect(tester.widget<TextField>(campo).focusNode!.hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await anda(tester);
      expect(find.text('Two'), findsOneWidget);
      expect(tutor.chamadas, 2);
    });

    testWidgets('Enter no campo envia', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      await tester.enterText(campo, 'A latte, please.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await anda(tester);
      expect(find.text('A latte, please.'), findsOneWidget);
      expect(tutor.chamadas, 1);
    });

    testWidgets('429: contagem pelo relógio do cubit, só o Enviar desliga, o Enter na janela não faz nada; passou, volta', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.limite, status: 429));
      await tester.tap(campo);
      await fala(tester, 'I want a coffee');
      final aviso = find.byKey(const Key('cenario-limite'));
      expect(aviso, findsOneWidget);
      expect(find.textContaining('Tente de novo em 20 s'), findsOneWidget);
      expect(controle(tester).text, 'I want a coffee', reason: 'a fala voltou para o campo');
      expect(tester.widget<IconButton>(find.byKey(const Key('enviar-conversa'))).onPressed, isNull);
      expect(tester.widget<TextField>(campo).enabled, isNot(false));
      expect(tester.widget<TextField>(campo).focusNode!.hasFocus, isTrue);
      // Enter na janela: nada sai, nada some
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await anda(tester);
      expect(controle(tester).text, 'I want a coffee');
      expect(tutor.chamadas, 1);
      // o relógio do cubit anda: a contagem acompanha
      agora = agora.add(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      expect(find.textContaining('Tente de novo em 14 s'), findsOneWidget);
      agora = agora.add(const Duration(seconds: 15));
      await tester.pump(const Duration(seconds: 1));
      expect(aviso, findsNothing);
      expect(tester.widget<IconButton>(find.byKey(const Key('enviar-conversa'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('enviar-conversa')));
      await anda(tester);
      expect(tutor.chamadas, 2);
      expect(find.byKey(const Key('correcao-1')), findsOneWidget);
    });

    for (final (falha, chave, trecho) in [
      (const FalhaIa(TipoFalhaIa.limiteDiario, status: 429), 'cenario-limite-dia', 'Volte amanhã'),
      (const FalhaIa(TipoFalhaIa.limitePessoal, status: 429), 'cenario-limite-pessoal', 'suas falas de conversa de hoje'),
      (const FalhaIa(TipoFalhaIa.semRede), 'cenario-sem-rede', 'Sem internet agora'),
      (const FalhaIa(TipoFalhaIa.ocupado, status: 503), 'cenario-ocupado', 'sobrecarregada'),
      (const FalhaIa(TipoFalhaIa.credencial, status: 403), 'cenario-indisponivel', 'indisponível'),
      (const FalhaIa(TipoFalhaIa.recusada), 'cenario-recusada', 'de outro jeito'),
      (Exception('boom'), 'cenario-falhou', 'não gastou seu limite'),
    ]) {
      testWidgets('aviso $chave: a fala volta ao campo e nada é gasto', (tester) async {
        final ia = await criar(tester);
        await montar(tester, pagina(_cafe), ia: ia);
        tutor.respostas.add(falha);
        await fala(tester, 'A latte, please.');
        expect(find.byKey(Key(chave)), findsOneWidget);
        expect(find.textContaining(trecho), findsOneWidget);
        expect(controle(tester).text, 'A latte, please.');
        expect(find.byKey(const Key('bolha-aluno')), findsNothing);
        expect(find.byKey(const Key('sugestoes-conversa')), findsNothing, reason: 'o aviso toma o lugar das ideias');
        expect(ia.state.restantes, 30);
      });
    }

    testWidgets('limite do dia na 1ª fala: o aviso não manda terminar (não há resumo); depois de uma fala, manda', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.limiteDiario, status: 429));
      await fala(tester, 'I want a coffee');
      expect(find.byKey(const Key('cenario-limite-dia')), findsOneWidget);
      expect(find.textContaining('O resumo continua funcionando'), findsNothing);
      // o ⋮ › Terminar fica desligado E com cara de desligado
      await tester.tap(find.byKey(const Key('menu-conversa')));
      await tester.pumpAndSettle();
      expect(tester.widget<PopupMenuItem<String>>(find.byKey(const Key('terminar-conversa'))).enabled, isFalse);
      expect(tester.widget<Text>(find.text('Terminar conversa')).style!.color, Mixart.textFaint);
      await tester.tapAt(const Offset(5, 990));
      await tester.pumpAndSettle();

      // outra conversa: a 1ª fala responde; a 2ª bate no limite do dia → aí o resumo existe
      final ia2 = await criar(tester);
      await tester.pumpWidget(const SizedBox());
      await montar(tester, pagina(_cafe), ia: ia2);
      await fala(tester, 'I want a coffee');
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.limiteDiario, status: 429));
      await fala(tester, 'Two');
      expect(find.byKey(const Key('cenario-limite-dia')), findsOneWidget);
      expect(find.textContaining('O resumo continua funcionando'), findsOneWidget);
      await tester.tap(find.byKey(const Key('menu-conversa')));
      await tester.pumpAndSettle();
      expect(tester.widget<PopupMenuItem<String>>(find.byKey(const Key('terminar-conversa'))).enabled, isTrue);
      expect(tester.widget<Text>(find.text('Terminar conversa')).style!.color, Mixart.text);
      await tester.tap(find.byKey(const Key('terminar-conversa')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
    });

    testWidgets('limite do dia: sem contagem na tela, a página não fica redesenhando a cada segundo', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      tutor.respostas.add(const FalhaIa(TipoFalhaIa.limiteDiario, status: 429));
      await fala(tester, 'I want a coffee');
      expect(find.byKey(const Key('cenario-limite-dia')), findsOneWidget);
      var builds = 0;
      final antes = debugOnRebuildDirtyWidget;
      debugOnRebuildDirtyWidget = (e, _) {
        if (e.widget.runtimeType.toString() == '_Conversa') builds++;
      };
      addTearDown(() => debugOnRebuildDirtyWidget = antes);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      debugOnRebuildDirtyWidget = antes;
      expect(builds, 0);
    });

    testWidgets('sem cota no meio: aviso, fala guardada; "Terminar conversa" ainda faz o resumo (sem IA)', (tester) async {
      final ia = await criar(tester, cota: CotaMemoria(CotaIa(dia: diaDe(DateTime(2026, 10, 13)), usos: 29)));
      await montar(tester, pagina(_cafe), ia: ia);
      await fala(tester, 'I want a coffee');
      expect(find.text('Sure! What size would you like?'), findsOneWidget);
      await fala(tester, 'Two');
      expect(find.byKey(const Key('cenario-sem-cota')), findsOneWidget);
      expect(controle(tester).text, 'Two');
      expect(tutor.chamadas, 1);
      await terminar(tester);
      expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
      expect(tutor.chamadas, 1);
    });

    testWidgets('"Terminar conversa" (⋮) mostra o resumo local: números e correções; a cota não muda; o rodapé some', (tester) async {
      final ia = await criar(tester);
      await montar(tester, pagina(_cafe), ia: ia);
      // antes de falar, o "Terminar" está desligado
      await tester.tap(find.byKey(const Key('menu-conversa')));
      await tester.pumpAndSettle();
      expect(tester.widget<PopupMenuItem<String>>(find.byKey(const Key('terminar-conversa'))).enabled, isFalse);
      await tester.tapAt(const Offset(5, 500));
      await tester.pumpAndSettle();
      tutor.respostas.addAll([respostaJson(), respostaJson(precisa: false)]);
      await fala(tester, 'I want a coffee');
      await fala(tester, 'A small one, please.');
      final antes = ia.state.restantes;
      await terminar(tester);
      expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('resumo-numeros'))).data,
          'Você falou 2 vezes em inglês · 1 certinha de primeira · 1 correção');
      expect(find.text('🐦 Fim da conversa com Emma!'), findsOneWidget);
      expect(find.byKey(const Key('resumo-correcao-0')), findsOneWidget);
      expect(find.byKey(const Key('resumo-palavras')), findsNothing, reason: 'sem PalavrasCubit na árvore');
      expect(campo, findsNothing);
      expect(ia.state.restantes, antes);
      expect(tutor.chamadas, 2);
    });

    testWidgets('voltar pela seta da tela depois de falar pede confirmação; sem falar, sai direto', (tester) async {
      final ia = await criar(tester);
      await montar(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => pagina(_cafe))),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
        ia: ia,
      );
      // sem falar: sai direto
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('abrir'), findsOneWidget);
      expect(find.text('Sair da conversa?'), findsNothing);
      // depois de falar: confirma
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      await fala(tester, 'I want a coffee');
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(find.text('Sair da conversa?'), findsOneWidget);
      await tester.tap(find.text('Continuar conversando'));
      await tester.pumpAndSettle();
      expect(campo, findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sair-conversa-confirmar')));
      await tester.pumpAndSettle();
      expect(campo, findsNothing);
      expect(find.text('abrir'), findsOneWidget);
    });

    for (final largura in [360.0, 390.0, 1400.0]) {
      for (final paleta in [Paleta.flutterClaro, Paleta.mixart]) {
        testWidgets('conversa com resumo em ${largura.toInt()} px (${paleta == Paleta.mixart ? 'escuro' : 'claro'}): sem estouro', (tester) async {
          final ia = await criar(tester);
          await montar(tester, pagina(_cafe), ia: ia, tamanho: Size(largura, 740), paleta: paleta);
          expect(tester.takeException(), isNull);
          await fala(tester, 'I want a coffee');
          expect(tester.takeException(), isNull);
          await terminar(tester);
          expect(find.byKey(const Key('resumo-conversa')), findsOneWidget);
          await tester.scrollUntilVisible(find.byKey(const Key('outras-situacoes')), 200, scrollable: find.byType(Scrollable).first);
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final paleta in [Paleta.flutterClaro, Paleta.mixart]) {
      testWidgets('360×640 com o teclado aberto (${paleta == Paleta.mixart ? 'escuro' : 'claro'}): cena longa, 3 ideias de 120 letras e o aviso',
          (tester) async {
        final negociacao = _todos().firstWhere((c) => c.id == 'negociacao');
        final ia = await criar(tester);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await montar(tester, pagina(negociacao, nivel: 'A2'), ia: ia, tamanho: const Size(360, 640), paleta: paleta);
        final longa = 'Thank you so much for the offer, I am really excited about this remote role and the team ${'x' * 40}'.substring(0, 120);
        final r = jsonDecode(respostaJson(fala: 'Of course. The base salary is in the offer letter. What would you like to discuss first?'))
            as Map<String, dynamic>;
        r['sugestoes'] = [for (final l in ['A', 'B', 'C']) longa.replaceRange(0, 1, l)];
        tutor.respostas.add(jsonEncode(r));
        await fala(tester, 'I want more money');
        expect(tester.takeException(), isNull);
        await tester.pump(const Duration(milliseconds: 400));
        final ultima = find.byKey(const Key('bolha-dash')).last;
        final ideias = find.byKey(const Key('sugestoes-conversa'));
        expect(ideias, findsOneWidget);
        expect(find.byKey(const Key('sugestao-0')), findsOneWidget); // as outras rolam de lado
        expect(tester.getRect(ultima).bottom, lessThanOrEqualTo(tester.getRect(ideias).top + 0.5));
        expect(tester.getRect(ideias).height, lessThanOrEqualTo(44));
        // o subtítulo fica numa linha só (cortado com reticências)
        expect(tester.getSize(find.byKey(const Key('conversa-restantes'))).height, lessThan(20));
        expect(tester.getRect(campo).bottom, lessThanOrEqualTo(640 - 300));

        // agora o aviso no lugar das ideias
        tutor.respostas.add(const FalhaIa(TipoFalhaIa.semRede));
        await fala(tester, 'I would like a higher salary');
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull);
        final aviso = find.byKey(const Key('cenario-sem-rede'));
        expect(aviso, findsOneWidget);
        expect(tester.getRect(find.byKey(const Key('bolha-dash')).last).bottom, lessThanOrEqualTo(tester.getRect(aviso).top + 0.5));
      });
    }
  });
}
