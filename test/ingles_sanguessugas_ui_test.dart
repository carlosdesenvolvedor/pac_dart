import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ia/presentation/ia_cubit.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/subida_nivel.dart';
import 'package:pac_dart/features/ingles/presentation/baralhos_page.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sanguessugas_page.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ia_cenario_cubit_test.dart' show TutorCenarioFalso;
import 'ia_cubit_test.dart' show CacheMemoria, CotaMemoria;
import 'ingles_baralhos_test.dart' show ConfigMemoria, RepoMemoria, f1, f2, f3, f4, trilhasDeTeste;
import 'ingles_cartoes_ui_test.dart' show LoaderTeste;

class _Voz extends VozIngles {
  final falas = <String>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add(frase);
    return Future.value();
  }

  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => true;
}

CartaoSrs _c({int lapsos = 0, bool suspenso = false}) =>
    CartaoSrs(estabilidade: 5, dificuldade: 5, ultimoDia: 100, proximoDia: 9999, revisoes: 20, lapsos: lapsos, suspenso: suspenso);

String _k(Trecho f) => RevisaoCubit.chaveDe(f);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // o curso de teste + 2 frases que dividem palavras com as do cartão (para "Outra frase")
  List<Trilha> trilhas() => [
        ...trilhasDeTeste(),
        const Trilha(nivel: 'Extra', emoji: '➕', etapa: 'A1 · Fundação', licoes: [
          Licao(id: 'extra.a', nome: 'A', emoji: '1', trechos: [
            Trecho(cod: 'Nice weather today.', dica: 'Tempo bom hoje.', out: ''),
            Trecho(cod: 'I meet her daily.', dica: 'Eu a encontro todo dia.', out: ''),
            Trecho(cod: 'I am used to it.', dica: 'Estou acostumado.', out: '', literal: 'Eu sou usado a isso.', conceito: 'used to + algo = estar acostumado'),
          ]),
        ]),
      ];

  late RevisaoCubit revisao;
  late TutorCenarioFalso tutor;

  Future<void> montar(WidgetTester tester, Widget tela, Map<String, CartaoSrs> cartoes, {bool comIa = true, Size tamanho = const Size(1000, 2600)}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    revisao = RevisaoCubit(repo: RepoMemoria(cartoes), configRepo: ConfigMemoria(), agendador: AgendadorFsrs(fuzz: false));
    final curso = CursoBloc(loader: LoaderTeste(trilhas()), progresso: LocalProgressoRepository(prefixo: 'en_'))..add(const CursoIniciado());
    tutor = TutorCenarioFalso();
    final ia = IaCubit(service: tutor, cotaRepo: CotaMemoria(), cache: CacheMemoria(), agora: () => DateTime(2026, 10, 13, 10));
    addTearDown(curso.close);
    addTearDown(revisao.close);
    addTearDown(ia.close);
    await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.runAsync(ia.carregar);
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: MultiBlocProvider(
        providers: [BlocProvider.value(value: curso), BlocProvider.value(value: revisao), if (comIa) BlocProvider.value(value: ia)],
        child: tela,
      ),
    ));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pump();
  }

  Future<void> anda(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  group('a tela das sanguessugas', () {
    testWidgets('sem nenhuma: mensagem de parabéns, sem lista', (tester) async {
      await montar(tester, const SanguessugasPage(), {_k(f1): _c(lapsos: 7)});
      expect(find.byKey(const Key('sem-sanguessugas')), findsOneWidget);
      expect(find.byKey(const Key('sanguessuga-frase')), findsNothing);
    });

    testWidgets('lista os cartões com 8+ erros, do pior para o melhor, com o sentido e os erros', (tester) async {
      await montar(tester, const SanguessugasPage(), {
        _k(f1): _c(lapsos: 9),
        RevisaoCubit.chaveReversaDe(f2): _c(lapsos: 12),
        _k(f3): _c(lapsos: 7),
        _k(f4): _c(lapsos: 20, suspenso: true),
      });
      final frases = [for (final e in find.byKey(const Key('sanguessuga-frase')).evaluate()) (e.widget as Text).data];
      expect(frases, ['How are you?', 'Nice to meet you.']);
      expect(find.text('🩸 errou 12 vezes'), findsOneWidget);
      expect(find.text('🩸 errou 9 vezes'), findsOneWidget);
      expect(find.text('🔄 cartão de virar'), findsOneWidget);
      expect(find.text('⌨️ digitar de memória'), findsOneWidget);
      expect(find.text('Como vai?'), findsOneWidget);
    });

    testWidgets('"Outra frase" mostra frases do curso com a mesma palavra rara; de novo esconde', (tester) async {
      await montar(tester, const SanguessugasPage(), {_k(f1): _c(lapsos: 9)});
      expect(find.byKey(const Key('exemplos-sanguessuga')), findsNothing);
      await tester.tap(find.byKey(const Key('outra-frase')));
      await tester.pump();
      expect(find.byKey(const Key('exemplos-sanguessuga')), findsOneWidget);
      expect(find.text('I meet her daily.'), findsOneWidget, reason: '"meet" é a palavra em comum');
      expect(find.text('Outras frases com "meet"'), findsOneWidget);
      expect(find.text('Nice weather today.'), findsNothing, reason: '"nice" é mais comum que "meet"? as duas aparecem 1x; vale a ordem alfabética (meet)');
      await tester.tap(find.byKey(const Key('outra-frase')));
      await tester.pump();
      expect(find.byKey(const Key('exemplos-sanguessuga')), findsNothing);
    });

    testWidgets('sem outra frase com a palavra: mensagem honesta', (tester) async {
      await montar(tester, const SanguessugasPage(), {_k(f4): _c(lapsos: 9)});
      await tester.tap(find.byKey(const Key('outra-frase')));
      await tester.pump();
      expect(find.textContaining('Não achei outra frase'), findsOneWidget);
    });

    testWidgets('Suspender tira o cartão da lista, avisa e "Desfazer" traz de volta', (tester) async {
      await montar(tester, const SanguessugasPage(), {_k(f1): _c(lapsos: 9)});
      await tester.tap(find.byKey(const Key('suspender-sanguessuga')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(revisao.state.cartoes[_k(f1)]!.suspenso, isTrue);
      expect(find.byKey(const Key('sem-sanguessugas')), findsOneWidget);
      expect(find.textContaining('Suspensa'), findsOneWidget);
      await tester.tap(find.byKey(const Key('desfazer-suspensao')));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
      expect(revisao.state.cartoes[_k(f1)]!.suspenso, isFalse);
      expect(find.byKey(const Key('sanguessuga-frase')), findsOneWidget);
    });

    testWidgets('mostra o "ao pé da letra" e a explicação que a própria frase já tem', (tester) async {
      final usada = trilhas().last.licoes.first.trechos.firstWhere((t) => t.cod == 'I am used to it.');
      await montar(tester, const SanguessugasPage(), {_k(usada): _c(lapsos: 10)});
      expect(find.text('ao pé da letra: Eu sou usado a isso.'), findsOneWidget);
      expect(find.text('💡 used to + algo = estar acostumado'), findsOneWidget);
    });

    testWidgets('ouvir fala a frase', (tester) async {
      final voz = _Voz();
      await montar(tester, SanguessugasPage(voz: voz), {_k(f1): _c(lapsos: 9)});
      await tester.tap(find.byTooltip('Ouvir'));
      await tester.pump();
      expect(voz.falas, ['Nice to meet you.']);
    });

    testWidgets('"Dica de memória": o Prof. Dash responde, gasta 1 uso e o pedido leva a frase e os erros', (tester) async {
      await montar(tester, const SanguessugasPage(), {_k(f1): _c(lapsos: 9)});
      expect(find.byKey(const Key('dica-de-memoria')), findsOneWidget);
      expect(find.text('Dica de memória'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dica-de-memoria')));
      await anda(tester);
      expect(find.byKey(const Key('explicacao-ia')), findsOneWidget);
      expect(tutor.contextos.single, contains('dica de memória'));
      expect(tutor.contextos.single, contains('Nice to meet you.'));
      expect(tutor.contextos.single, contains('9 erros'));
      expect(tutor.perguntas.single, contains('UMA dica de memória'));
      expect(tutor.chamadas, 1);
    });

    testWidgets('sem IA na árvore a dica de memória não existe (o resto funciona)', (tester) async {
      await montar(tester, const SanguessugasPage(), {_k(f1): _c(lapsos: 9)}, comIa: false);
      expect(find.byKey(const Key('dica-de-memoria')), findsNothing);
      expect(find.byKey(const Key('outra-frase')), findsOneWidget);
    });

    testWidgets('360 px e tema claro: sem estouro, com os exemplos abertos', (tester) async {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await montar(tester, const SanguessugasPage(), {_k(f1): _c(lapsos: 9), _k(f2): _c(lapsos: 10)}, tamanho: const Size(360, 740));
      await tester.tap(find.byKey(const Key('outra-frase')).first);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('o card nos Baralhos', () {
    testWidgets('some sem sanguessugas; com elas mostra a quantidade e abre a tela', (tester) async {
      await montar(tester, const BaralhosPage(), {_k(f1): _c(lapsos: 3)});
      expect(find.byKey(const Key('sanguessugas')), findsNothing);

      await montar(tester, const BaralhosPage(), {_k(f1): _c(lapsos: 9), _k(f2): _c(lapsos: 8), _k(f3): _c(lapsos: 2)});
      expect(find.text('2 sanguessugas'), findsOneWidget);
      await tester.tap(find.byKey(const Key('sanguessugas')));
      await tester.pumpAndSettle();
      expect(find.byType(SanguessugasPage), findsOneWidget);
      expect(find.byKey(const Key('sanguessuga-frase')), findsNWidgets(2));
    });

    testWidgets('no singular: "1 sanguessuga"', (tester) async {
      await montar(tester, const BaralhosPage(), {_k(f1): _c(lapsos: 8)});
      expect(find.text('1 sanguessuga'), findsOneWidget);
    });
  });

  group('sugestão de nível na revisão de cartões', () {
    final avancado = NivelResposta.avancado;

    Future<void> abrir(WidgetTester tester, {required NivelResposta nivel, required SerieDeNivel serie, List<Trecho> itens = const [f1, f2, f3]}) async {
      SharedPreferences.setMockInitialValues({
        SessaoCartoesPage.prefNivel: nivel.id,
        SessaoCartoesPage.prefSentido: SentidoCartao.enPt.id,
        SessaoCartoesPage.prefSerie: serie.codificar(),
      });
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        theme: Mixart.tema(),
        home: SessaoCartoesPage(
          titulo: 'c',
          subtitulo: 's',
          itens: itens,
          voz: _Voz(),
          chaveDe: RevisaoCubit.chaveReversaDe,
          previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
          onNota: (f, n) {},
        ),
      ));
      await tester.pumpAndSettle();
    }

    Future<void> errarNoAvancado(WidgetTester tester) async {
      await tester.tap(find.text('Não sei'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('nota-errei')));
      await tester.pump();
    }

    SerieDeNivel serieCom(NivelResposta n, List<bool> l) => SerieDeNivel({n: l});

    testWidgets('descer: o 4º erro nas últimas 8 mostra o convite (sem culpa) e NÃO troca sozinho', (tester) async {
      await abrir(tester, nivel: avancado, serie: serieCom(avancado, [true, true, true, true, false, false, false]));
      expect(find.byKey(const Key('sugestao-nivel')), findsNothing);
      await errarNoAvancado(tester);
      expect(find.byKey(const Key('sugestao-nivel')), findsOneWidget);
      expect(find.textContaining('Está pesado?'), findsOneWidget);
      expect(find.textContaining('voltar ao Médio'), findsOneWidget);
      expect(find.text('Voltar para Médio'), findsOneWidget);
      // o nível continua o mesmo até a pessoa aceitar
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
    });

    testWidgets('aceitar: o nível muda, é guardado, o convite some e a contagem do degrau antigo recomeça', (tester) async {
      await abrir(tester, nivel: avancado, serie: serieCom(avancado, [true, true, true, true, false, false, false]));
      await errarNoAvancado(tester);
      await tester.tap(find.byKey(const Key('aceitar-sugestao-nivel')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sugestao-nivel')), findsNothing);
      expect(find.byKey(const Key('lacunas')), findsOneWidget, reason: 'agora é o Médio');
      final p = await SharedPreferences.getInstance();
      expect(p.getString(SessaoCartoesPage.prefNivel), 'medio');
      expect(SerieDeNivel.decodificar(p.getString(SessaoCartoesPage.prefSerie)).porNivel.containsKey(avancado), isFalse);
    });

    testWidgets('"Agora não": o convite some e só volta depois de outra série inteira', (tester) async {
      await abrir(tester, nivel: avancado, serie: serieCom(avancado, [true, true, true, true, false, false, false]));
      await errarNoAvancado(tester);
      await tester.tap(find.byKey(const Key('dispensar-sugestao-nivel')));
      await tester.pump();
      expect(find.byKey(const Key('sugestao-nivel')), findsNothing);
      final p = await SharedPreferences.getInstance();
      expect(SerieDeNivel.decodificar(p.getString(SessaoCartoesPage.prefSerie)).porNivel.containsKey(avancado), isFalse);
      // o próximo erro não reabre o convite: a contagem recomeçou
      await errarNoAvancado(tester);
      expect(find.byKey(const Key('sugestao-nivel')), findsNothing);
    });

    testWidgets('subir: 10 acertos seguidos no Médio convidam para o Avançado', (tester) async {
      const t = Trecho(cod: 'Thanks.', dica: 'Obrigado.', out: '');
      await abrir(tester, nivel: NivelResposta.medio, serie: serieCom(NivelResposta.medio, List.filled(9, true)), itens: const [t, t]);
      expect(find.byKey(const Key('sugestao-nivel')), findsNothing);
      await tester.enterText(find.byKey(const Key('lacuna-0')), 'Obrigado');
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('nota-bom')));
      await tester.pump();
      expect(find.byKey(const Key('sugestao-nivel')), findsOneWidget);
      expect(find.textContaining('10 acertos seguidos no Médio'), findsOneWidget);
      expect(find.text('Subir para Avançado'), findsOneWidget);
    });

    testWidgets('"Só virar" não entra na escada: nenhum convite, nenhuma série guardada', (tester) async {
      await abrir(tester, nivel: NivelResposta.livre, serie: const SerieDeNivel());
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(const Key('mostrar-resposta')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('nota-errei')));
        await tester.pump();
      }
      expect(find.byKey(const Key('sugestao-nivel')), findsNothing);
      final p = await SharedPreferences.getInstance();
      expect(SerieDeNivel.decodificar(p.getString(SessaoCartoesPage.prefSerie)).porNivel, isEmpty);
    });

    testWidgets('o "DE NOVO" depois de errar NÃO entra na série (só a 1ª nota de cada cartão)', (tester) async {
      await abrir(tester, nivel: avancado, serie: const SerieDeNivel(), itens: const [f1]);
      await errarNoAvancado(tester); // f1 errada: volta como "DE NOVO"
      await errarNoAvancado(tester); // repetição errada: não conta de novo
      final p = await SharedPreferences.getInstance();
      expect(SerieDeNivel.decodificar(p.getString(SessaoCartoesPage.prefSerie)).porNivel[avancado], [false]);
    });

    testWidgets('em 360 px o convite cabe, com os botões', (tester) async {
      await abrir(tester, nivel: avancado, serie: serieCom(avancado, [true, true, true, true, false, false, false]));
      tester.view.physicalSize = const Size(360, 800);
      await errarNoAvancado(tester);
      expect(find.byKey(const Key('sugestao-nivel')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
