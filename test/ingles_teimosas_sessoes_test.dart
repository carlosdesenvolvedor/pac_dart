// "🔥 Palavras teimosas" nas revisões: a sessão de memória (Revisão do dia) e a de cartões gravam as
// palavras que tropeçaram (uma vez, no fim) e o resumo mostra "Você tropeçou em: …" — os botões só quando
// a oferta pode aparecer. Nivelamento, EN → PT e "Só virar" não gravam nada.
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_memoria_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _VozFake extends VozIngles {
  @override
  Future<void> falar(String frase, {bool? lenta}) => Future.value();
  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

/// O cubit de verdade, contando as gravações de erros (tem de ser UMA por sessão).
class _CubitContando extends PalavrasCubit {
  int chamadas = 0;
  _CubitContando()
      : super(
          repo: MemoriaPalavrasRepository(),
          agora: () => DateTime(2026, 10, 20, 9),
          agendador: AgendadorFsrs(fuzz: false),
          carregarDicionario: () async => _dic,
        );

  @override
  List<String> registrarErros(List<EvidenciaPalavra> evs) {
    chamadas++;
    return super.registrarErros(evs);
  }
}

const _dic = Dicionario({
  'nice': 'legal, simpático',
  'meet': 'conhecer, encontrar',
  'coffee': 'café',
});

const _nice = Trecho(cod: 'Nice to meet you.', dica: 'Prazer em te conhecer.', out: '');

final _trilhas = [
  const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'L1', emoji: '👋', id: 't1.l1', trechos: [
      _nice,
      Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: ''),
    ]),
  ]),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FraseView.carencia = Duration.zero;
  });

  Future<_CubitContando> cubitPronto(WidgetTester tester) async {
    final c = _CubitContando();
    await tester.runAsync(() async {
      await c.carregar();
      await c.prepararIndice(_trilhas);
    });
    expect(c.state.indice, isNotNull);
    return c;
  }

  Future<void> passa(WidgetTester tester, [int vezes = 4]) async {
    for (var i = 0; i < vezes; i++) {
      await tester.pump(const Duration(milliseconds: 60));
    }
  }

  group('SessaoMemoriaPage (Revisão do dia)', () {
    Future<void> abrir(WidgetTester tester, PalavrasCubit c, {bool reaprender = true}) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider<PalavrasCubit>.value(
        value: c,
        child: MaterialApp(
          home: SessaoMemoriaPage(
            titulo: 'Revisão',
            subtitulo: 'teste',
            itens: const [_nice],
            reaprender: reaprender,
            voz: _VozFake(),
          ),
        ),
      ));
      await passa(tester);
    }

    Future<void> digita(WidgetTester tester, String ch) async {
      await tester.enterText(find.descendant(of: find.byType(FraseView), matching: find.byType(TextField)).last, ch);
      await tester.pump();
    }

    bool tem(String texto) => find.textContaining(texto).evaluate().isNotEmpty;

    /// "Nice to meet you." com 2 teclas erradas no começo de "Nice" e de "meet".
    Future<void> errando(WidgetTester tester) async {
      for (final ch in ['x', 'x', 'N', 'i', 'c', 'e', ' ', 't', 'o', ' ', 'z', 'z', 'm', 'e', 'e', 't', ' ', 'y', 'o', 'u', '.']) {
        if (tem('Enter segue')) break;
        await digita(tester, ch);
      }
    }

    /// Faz a sessão até o resumo; erra nas primeiras [erros] digitações de memória (não nas cópias).
    Future<void> fazer(WidgetTester tester, {int erros = 1}) async {
      var errou = 0;
      for (var i = 0; i < 20 && !tem('Pronto!'); i++) {
        final memoria = tem('de memória');
        if (memoria && errou < erros) {
          await errando(tester);
          errou++;
        } else {
          await digita(tester, _nice.cod);
        }
        await passa(tester);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await passa(tester);
      }
      expect(find.text('Pronto!'), findsOneWidget);
    }

    testWidgets('errar de memória: grava uma vez no fim e o resumo mostra "Você tropeçou em" (sem botões: abaixo do mínimo)',
        (tester) async {
      final c = await cubitPronto(tester);
      await abrir(tester, c);
      await fazer(tester, erros: 1);
      expect(c.chamadas, 1);
      expect(c.state.banco['nice']?.errosTotal, 1);
      expect(c.state.banco['meet']?.errosTotal, 1);
      final resumo = find.byKey(const Key('resumo-teimosas'));
      expect(resumo, findsOneWidget);
      expect(find.descendant(of: resumo, matching: find.textContaining('meet')), findsOneWidget);
      expect(find.byKey(const Key('treinar-teimosas')), findsNothing);
      // sair não grava de novo
      await tester.pumpWidget(const SizedBox());
      expect(c.chamadas, 1);
      await c.close();
    });

    testWidgets('errar a mesma frase de novo na volta: o resumo oferece treinar e jogar com elas', (tester) async {
      final c = await cubitPronto(tester);
      await abrir(tester, c);
      await fazer(tester, erros: 2);
      expect(c.chamadas, 1);
      expect(find.byKey(const Key('resumo-teimosas')), findsOneWidget);
      expect(find.byKey(const Key('treinar-teimosas')), findsOneWidget);
      expect(find.byKey(const Key('jogar-teimosas')), findsOneWidget);
      expect(c.state.banco.sugestao.mostradasHoje, 1);
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });

    testWidgets('nivelamento (reaprender: false) não grava nada', (tester) async {
      final c = await cubitPronto(tester);
      await abrir(tester, c, reaprender: false);
      await fazer(tester, erros: 1);
      expect(c.chamadas, 0);
      expect(c.state.banco['nice'], isNull);
      expect(c.state.banco['meet'], isNull);
      expect(find.byKey(const Key('resumo-teimosas')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      expect(c.chamadas, 0);
      await c.close();
    });

    /// "nice" já errou hoje (pesa): uma resposta limpa depois disso dá +1 na sequência de acertos.
    Future<_CubitContando> comNiceErrada(WidgetTester tester) async {
      final c = await cubitPronto(tester);
      c.registrarErros(const [EvidenciaPalavra(chave: 'nice', peso: 1, falha: 1, fonte: FonteErro.licao)]);
      expect(c.state.banco['nice']?.acertosSeguidos, 0);
      return c;
    }

    testWidgets('acertar de memória sem ajuda conta como acerto limpo da palavra', (tester) async {
      final c = await comNiceErrada(tester);
      await abrir(tester, c);
      await fazer(tester, erros: 0);
      expect(c.state.banco['nice']?.acertosSeguidos, 1);
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });

    testWidgets('ouvir a frase antes de responder: as palavras certas não ganham crédito de acerto', (tester) async {
      final c = await comNiceErrada(tester);
      await abrir(tester, c);
      await tester.tap(find.byTooltip('Ouvir em inglês'));
      await passa(tester);
      await fazer(tester, erros: 0);
      final nice = c.state.banco['nice']!;
      expect(nice.acertosSeguidos, 0, reason: 'a resposta estava audível');
      expect(nice.errosTotal, 1, reason: 'também não é erro');
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });

    testWidgets('sair no meio grava o que já foi respondido (uma vez)', (tester) async {
      final c = await cubitPronto(tester);
      await abrir(tester, c);
      await errando(tester);
      await passa(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await passa(tester);
      expect(c.chamadas, 0, reason: 'só no fim ou ao sair');
      await tester.pumpWidget(const SizedBox());
      expect(c.chamadas, 1);
      expect(c.state.banco['meet']?.errosTotal, 1);
      await c.close();
    });
  });

  group('SessaoCartoesPage', () {
    Future<void> abrir(WidgetTester tester, PalavrasCubit c, {required NivelResposta nivel, required SentidoCartao sentido}) async {
      SharedPreferences.setMockInitialValues({
        SessaoCartoesPage.prefNivel: nivel.id,
        SessaoCartoesPage.prefSentido: sentido.id,
      });
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(BlocProvider<PalavrasCubit>.value(
        value: c,
        child: MaterialApp(
          home: SessaoCartoesPage(
            titulo: 'Cartões',
            subtitulo: 'teste',
            itens: const [_nice],
            voz: _VozFake(),
            chaveDe: RevisaoCubit.chaveReversaDe,
            previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
            onNota: (_, _) {},
            aleatorio: Random(7),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> escreve(WidgetTester tester, String texto) async {
      await tester.enterText(find.byKey(const Key('resposta-escrita')), texto);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    /// Dá a nota "Errei" e anda até o fim (a frase errada volta uma vez como repetição: "Lembrei").
    Future<void> errei(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('nota-errei')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 4 && find.byKey(const Key('continuar-cartoes')).evaluate().isEmpty; i++) {
        if (find.byKey(const Key('resposta-escrita')).evaluate().isNotEmpty) {
          await escreve(tester, _nice.cod);
        } else if (find.byKey(const Key('mostrar-resposta')).evaluate().isNotEmpty) {
          await tester.tap(find.byKey(const Key('mostrar-resposta')));
        }
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('nota-bom')));
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('continuar-cartoes')), findsOneWidget);
    }

    testWidgets('PT → EN escrito: a palavra errada é gravada (só ela) e aparece no resumo', (tester) async {
      final c = await cubitPronto(tester);
      await abrir(tester, c, nivel: NivelResposta.avancado, sentido: SentidoCartao.ptEn);
      await escreve(tester, 'nice to see you');
      await errei(tester);
      expect(c.chamadas, 1);
      expect(c.state.banco['meet']?.errosTotal, 1);
      expect(c.state.banco['nice'], isNull, reason: 'acertou: não entra no banco por causa disso');
      final resumo = find.byKey(const Key('resumo-teimosas'));
      expect(resumo, findsOneWidget);
      expect(find.descendant(of: resumo, matching: find.textContaining('meet')), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      expect(c.chamadas, 1);
      await c.close();
    });

    /// 3 teimosas no banco: um erro na sessão já basta para a oferta (a regra global).
    Future<_CubitContando> comTeimosas(WidgetTester tester) async {
      final c = await cubitPronto(tester);
      c.registrarErros([
        for (final k in ['nice', 'meet', 'coffee']) ...[
          EvidenciaPalavra(chave: k, peso: 1, falha: 1, fonte: FonteErro.licao),
          EvidenciaPalavra(chave: k, peso: 1, falha: 1, fonte: FonteErro.licao),
        ],
      ]);
      expect(c.quantasTeimosas, greaterThanOrEqualTo(3));
      c.chamadas = 0;
      return c;
    }

    testWidgets('com 3 teimosas, errar uma palavra: o fim oferece treinar só elas', (tester) async {
      final c = await comTeimosas(tester);
      await abrir(tester, c, nivel: NivelResposta.avancado, sentido: SentidoCartao.ptEn);
      await escreve(tester, 'nice to see you');
      await errei(tester);
      expect(find.byKey(const Key('treinar-teimosas')), findsOneWidget);
      expect(c.state.banco.sugestao.mostradasHoje, 1);
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });

    testWidgets('Revisão do dia = memória + cartões: com a oferta recém-mostrada, os cartões não oferecem de novo',
        (tester) async {
      final c = await comTeimosas(tester);
      // a sessão de memória que veio antes acabou de oferecer
      c.marcarMostrada();
      await abrir(tester, c, nivel: NivelResposta.avancado, sentido: SentidoCartao.ptEn);
      await escreve(tester, 'nice to see you');
      await errei(tester);
      expect(c.chamadas, 1, reason: 'as palavras continuam gravadas');
      expect(find.byKey(const Key('resumo-teimosas')), findsOneWidget);
      expect(find.byKey(const Key('treinar-teimosas')), findsNothing);
      expect(c.state.banco.sugestao.mostradasHoje, 1, reason: 'uma oferta só por revisão');
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });

    testWidgets('EN → PT não grava nada (a resposta é o português)', (tester) async {
      final c = await cubitPronto(tester);
      await abrir(tester, c, nivel: NivelResposta.avancado, sentido: SentidoCartao.enPt);
      await escreve(tester, 'prazer em ver');
      await errei(tester);
      expect(c.state.banco.palavras, isEmpty);
      expect(find.byKey(const Key('resumo-teimosas')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });

    testWidgets('"Só virar" (PT → EN, sem resposta escrita) não grava nada', (tester) async {
      final c = await cubitPronto(tester);
      await abrir(tester, c, nivel: NivelResposta.livre, sentido: SentidoCartao.ptEn);
      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pumpAndSettle();
      await errei(tester);
      expect(c.state.banco.palavras, isEmpty);
      expect(find.byKey(const Key('resumo-teimosas')), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await c.close();
    });
  });
}
