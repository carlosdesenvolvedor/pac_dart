import 'dart:async';

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
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cenario_cubit_test.dart' show TutorCenarioFalso;
import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria;

const _cafe = Cenario(
  id: 'cafe',
  titulo: 'Pedir um café',
  emoji: '☕',
  etapa: 'A1',
  papel: 'atendente de uma cafeteria',
  objetivo: 'Peça uma bebida e pague.',
  abertura: 'Hi! What can I get for you?',
  aberturaPt: 'Oi! O que posso trazer?',
  dicas: ['A small latte, please.', 'How much is it?'],
  maxTurnos: 2,
);
const _hotel = Cenario(
  id: 'hotel',
  titulo: 'Check-in no hotel',
  emoji: '🏨',
  etapa: 'A2',
  papel: 'recepcionista',
  objetivo: 'Faça o check-in.',
  abertura: 'Good evening!',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late TutorCenarioFalso tutor;
  late CotaMemoria cotaRepo;

  Future<IaCubit> criar(WidgetTester tester) async {
    tutor = TutorCenarioFalso();
    cotaRepo = CotaMemoria();
    final ia = IaCubit(service: tutor, cotaRepo: cotaRepo, cache: CacheMemoria(), agora: () => DateTime(2026, 10, 13, 10));
    await tester.runAsync(ia.carregar);
    addTearDown(() => tester.runAsync(ia.close));
    return ia;
  }

  Future<void> anda(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  Future<void> montar(WidgetTester tester, Widget tela, {IaCubit? ia, Size tamanho = const Size(900, 1000)}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget app = MaterialApp(theme: Mixart.tema(), home: tela);
    if (ia != null) app = BlocProvider.value(value: ia, child: app);
    await tester.pumpWidget(app);
    await tester.pump();
  }

  Future<void> fala(WidgetTester tester, String texto) async {
    await tester.enterText(find.byKey(const Key('campo-conversa')), texto);
    await tester.tap(find.byKey(const Key('enviar-conversa')));
    await anda(tester);
  }

  group('a lista de cenários', () {
    testWidgets('mostra os cenários por etapa, o saldo do dia e abre a conversa', (tester) async {
      final ia = await criar(tester);
      await montar(tester, CenariosPage(carregador: () async => [_hotel, _cafe]), ia: ia);
      await anda(tester);
      expect(find.text('Conversar'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
      expect(find.text('A2'), findsOneWidget);
      expect(find.text('Restam 30 usos hoje'), findsOneWidget);
      expect(find.text('Pedir um café'), findsOneWidget);
      expect(find.text('Peça uma bebida e pague.'), findsOneWidget);
      // A1 vem antes de A2
      expect(tester.getTopLeft(find.byKey(const Key('cenario-cafe'))).dy, lessThan(tester.getTopLeft(find.byKey(const Key('cenario-hotel'))).dy));
      await tester.tap(find.byKey(const Key('cenario-cafe')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('objetivo-cenario')), findsOneWidget);
    });

    testWidgets('lista vazia: mensagem amigável', (tester) async {
      final ia = await criar(tester);
      await montar(tester, CenariosPage(carregador: () async => const []), ia: ia);
      await anda(tester);
      expect(find.textContaining('Não encontrei os cenários'), findsOneWidget);
    });

    testWidgets('360 px e tema claro: sem estouro', (tester) async {
      final ia = await criar(tester);
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await montar(tester, CenariosPage(carregador: () async => [_hotel, _cafe]), ia: ia, tamanho: const Size(360, 740));
      await anda(tester);
      expect(tester.takeException(), isNull);
    });
  });

  group('a conversa', () {
    testWidgets('abre com o objetivo, a abertura do Dash e a tradução; ainda sem "Terminar"', (tester) async {
      final ia = await criar(tester);
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      expect(find.text('🎯 Peça uma bebida e pague.'), findsOneWidget);
      expect(find.text('Hi! What can I get for you?'), findsOneWidget);
      expect(find.text('Oi! O que posso trazer?'), findsOneWidget);
      expect(find.byKey(const Key('bolha-dash')), findsOneWidget);
      expect(find.byKey(const Key('bolha-aluno')), findsNothing);
      expect(find.byKey(const Key('terminar-conversa')), findsNothing, reason: 'nada para avaliar ainda');
      expect(find.textContaining('só corrige no fim'), findsOneWidget);
      expect(tutor.chamadas, 0, reason: 'a abertura é fixa e não gasta');
    });

    testWidgets('sem IaCubit na árvore, não há conversa', (tester) async {
      await montar(tester, const ConversaPage(cenario: _cafe));
      expect(find.byKey(const Key('campo-conversa')), findsNothing);
    });

    testWidgets('falar: aparece a bolha da pessoa e a do Dash; o campo limpa; o saldo desce', (tester) async {
      final ia = await criar(tester);
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      await fala(tester, 'I want a coffee.');
      expect(find.byKey(const Key('bolha-aluno')), findsOneWidget);
      expect(find.text('I want a coffee.'), findsOneWidget);
      expect(find.text('Sure! What size?'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('campo-conversa'))).controller!.text, isEmpty);
      expect(find.text('A1 · restam 29 usos hoje'), findsOneWidget);
      expect(find.byKey(const Key('terminar-conversa')), findsOneWidget);
      expect(find.textContaining('corrig'), findsWidgets);
      // o Dash NÃO corrige no meio: nenhuma correção na tela antes do fim
      expect(find.byKey(const Key('correcao-cenario')), findsNothing);
      expect(find.byKey(const Key('feedback-cenario')), findsNothing);
    });

    testWidgets('esperando o Dash o campo continua ligado, editável e com o foco (mexer nele no meio do Enter dá erro na web); o envio é que espera', (tester) async {
      final ia = await criar(tester);
      tutor.segura = Completer<void>();
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      final campo = find.byKey(const Key('campo-conversa'));
      await tester.tap(campo);
      await tester.enterText(campo, 'One');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byKey(const Key('dash-digitando')), findsOneWidget);
      expect(tester.widget<TextField>(campo).enabled, isNot(false));
      expect(tester.widget<TextField>(campo).readOnly, isFalse);
      expect(tester.widget<TextField>(campo).focusNode!.hasFocus, isTrue);
      // a pessoa já pode ir escrevendo a próxima; mandar de novo enquanto espera não envia nem apaga o texto
      await tester.enterText(campo, 'Two');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.widget<TextField>(campo).controller!.text, 'Two');
      expect(tutor.chamadas, 1);
      tutor.segura!.complete();
      await anda(tester);
      expect(tester.widget<TextField>(campo).focusNode!.hasFocus, isTrue);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await anda(tester);
      expect(find.text('Two'), findsOneWidget);
      expect(tutor.chamadas, 2);
    });

    testWidgets('Enter no campo também envia', (tester) async {
      final ia = await criar(tester);
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      await tester.enterText(find.byKey(const Key('campo-conversa')), 'A latte, please.');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await anda(tester);
      expect(find.text('A latte, please.'), findsOneWidget);
      expect(tutor.chamadas, 1);
    });

    testWidgets('as frases úteis aparecem sob demanda e tocar numa preenche o campo (sem enviar)', (tester) async {
      final ia = await criar(tester);
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      expect(find.text('How much is it?'), findsNothing);
      await tester.tap(find.byKey(const Key('dicas-cenario')));
      await tester.pump();
      await tester.tap(find.text('How much is it?'));
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const Key('campo-conversa'))).controller!.text, 'How much is it?');
      expect(tutor.chamadas, 0);
    });

    testWidgets('todas as falas: o campo some, aparece o aviso e "Terminar e ver feedback"', (tester) async {
      final ia = await criar(tester);
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      await fala(tester, 'One');
      await fala(tester, 'Two');
      expect(find.byKey(const Key('conversa-encerrada')), findsOneWidget);
      expect(find.byKey(const Key('campo-conversa')), findsNothing);
      expect(find.byKey(const Key('terminar-conversa')), findsOneWidget);
    });

    testWidgets('terminar mostra o feedback: o que foi bem, a correção explicada e 3 frases com "Salvar como cartão"', (tester) async {
      final ia = await criar(tester);
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      await fala(tester, 'I want coffee');
      await tester.tap(find.byKey(const Key('terminar-conversa')));
      await anda(tester);
      expect(find.byKey(const Key('feedback-cenario')), findsOneWidget);
      expect(find.text('✅ Educado.'), findsOneWidget);
      expect(find.byKey(const Key('correcao-cenario')), findsOneWidget);
      expect(find.text('Can I have a coffee?'), findsOneWidget);
      expect(find.textContaining('**'), findsNothing);
      for (var i = 0; i < 3; i++) {
        expect(find.byKey(Key('salvar-cartao-$i')), findsOneWidget);
      }
      expect(find.text('A small latte, please.'), findsOneWidget);
      expect(find.byKey(const Key('campo-conversa')), findsNothing, reason: 'acabou');
      expect(find.byKey(const Key('terminar-conversa')), findsNothing);
    });

    testWidgets('feedback com JSON estragado mostra o texto como veio, sem botões de cartão', (tester) async {
      final ia = await criar(tester);
      tutor.feedback = 'Você foi bem, mas sem JSON.';
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      await fala(tester, 'Hello');
      await tester.tap(find.byKey(const Key('terminar-conversa')));
      await anda(tester);
      expect(find.byKey(const Key('feedback-cru')), findsOneWidget);
      expect(find.text('Você foi bem, mas sem JSON.'), findsOneWidget);
      expect(find.byKey(const Key('salvar-cartao-0')), findsNothing);
    });

    testWidgets('falha: a mensagem aparece, NÃO gasta e a fala volta para o campo', (tester) async {
      final ia = await criar(tester);
      tutor.erro = Exception('sem rede');
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      await fala(tester, 'A latte, please.');
      expect(find.byKey(const Key('cenario-falhou')), findsOneWidget);
      expect(find.textContaining('não gastou seu limite'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('campo-conversa'))).controller!.text, 'A latte, please.');
      expect(find.byKey(const Key('bolha-aluno')), findsNothing);
      expect(ia.state.restantes, 30);
    });

    testWidgets('sem cota no meio: mensagem gentil, fala guardada no campo e, ao terminar, o resumo local (sem IA)', (tester) async {
      tutor = TutorCenarioFalso();
      cotaRepo = CotaMemoria(CotaIa(dia: diaDe(DateTime(2026, 10, 13)), usos: 29)); // só resta 1 uso
      final ia = IaCubit(service: tutor, cotaRepo: cotaRepo, cache: CacheMemoria(), agora: () => DateTime(2026, 10, 13, 10));
      await tester.runAsync(ia.carregar);
      addTearDown(() => tester.runAsync(ia.close));
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia);
      await fala(tester, 'One');
      expect(find.text('Sure! What size?'), findsOneWidget);
      await fala(tester, 'Two');
      expect(find.byKey(const Key('cenario-sem-cota')), findsOneWidget);
      expect(find.textContaining('descansou'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('campo-conversa'))).controller!.text, 'Two');
      expect(tutor.chamadas, 1);
      await tester.tap(find.byKey(const Key('terminar-conversa')));
      await anda(tester);
      expect(find.byKey(const Key('feedback-local')), findsOneWidget);
      expect(find.textContaining('Você falou 1 vez'), findsOneWidget);
      expect(find.byKey(const Key('feedback-cenario')), findsNothing);
      expect(find.byKey(const Key('cenario-sem-cota')), findsNothing, reason: 'o resumo local substitui o aviso');
      expect(tutor.chamadas, 1);
    });

    testWidgets('360 px e tema claro, com feedback aberto: sem estouro', (tester) async {
      final ia = await criar(tester);
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await montar(tester, const ConversaPage(cenario: _cafe), ia: ia, tamanho: const Size(360, 740));
      await fala(tester, 'I want coffee');
      await tester.tap(find.byKey(const Key('terminar-conversa')));
      await anda(tester);
      expect(find.byKey(const Key('feedback-cenario')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
