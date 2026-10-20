// "📚 Minhas palavras" e a folha "➕ Adicionar palavra": dicionário preenche a tradução, erros ao vivo,
// tradutor (que acerta e que falha), colar lista, 🎮 nos jogos, remover, revisar só as vencidas, as
// palavras da leitura e nada estourando a 360.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/data/tradutor.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/minhas_palavras_page.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/treino_palavras_page.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/adicionar_palavra_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class _Tradutor implements Tradutor {
  final String? resposta;
  _Tradutor([this.resposta]);
  final pedidos = <String>[];

  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir}) async {
    pedidos.addAll(frases);
    final r = resposta;
    if (r == null) throw const TraducaoFalhou('Sem rede');
    return [for (final _ in frases) r];
  }
}

const _dic = Dicionario({
  'coffee': 'café',
  'morning': 'manhã',
  'tired': 'cansado',
  'please': 'por favor',
  'apple': 'maçã',
  'book': 'livro',
  'happy': 'feliz',
  'garden': 'jardim',
  'the': 'o, a',
  'i': 'eu',
  'am': 'sou, estou',
  'good': 'bom',
  'is': 'é, está',
});

List<Trilha> _trilhas() => [
      const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1 · Fundação', licoes: [
        Licao(nome: 'No café', emoji: '☕', id: 't1.l1', trechos: [
          Trecho(cod: 'Coffee, please.', dica: 'Café, por favor.', out: ''),
          Trecho(cod: 'Good morning, I am tired.', dica: 'Bom dia, estou cansado.', out: ''),
        ]),
      ]),
      const Trilha(nivel: 'Meus cartões', emoji: '📝', etapa: 'Meus textos', textoId: 'cartoes', licoes: [
        Licao(nome: 'Parte 1', emoji: '📝', id: 'txt-cartoes-1', trechos: [
          Trecho(cod: 'The garden is lovely.', dica: 'O jardim é lindo.', out: '', alvo: 'garden', alvoPt: 'jardim'),
        ]),
      ]),
    ];

final _agora = DateTime(2026, 10, 20, 9);
final _hoje = Revisao.dia(_agora);

CartaoSrs _cartao({required int proximo}) =>
    CartaoSrs(estabilidade: 3, dificuldade: 5, ultimoDia: _hoje - 3, proximoDia: proximo, revisoes: 2);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  late PalavrasCubit cubit;
  late _Voz voz;

  Future<void> montar(
    WidgetTester tester, {
    BancoPalavras banco = BancoPalavras.vazio,
    Tradutor? tradutor,
    Size tamanho = const Size(1000, 1600),
    VoidCallback? aoJogar,
  }) async {
    SharedPreferences.setMockInitialValues({
      'en_concluidas': ['t1.l1']
    });
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    voz = _Voz();
    cubit = PalavrasCubit(
      repo: MemoriaPalavrasRepository(banco),
      agora: () => _agora,
      agendador: AgendadorFsrs(fuzz: false),
      carregarDicionario: () async => _dic,
    );
    final curso = CursoBloc(loader: LoaderTeste(_trilhas()), progresso: LocalProgressoRepository(prefixo: 'en_'))
      ..add(const CursoIniciado());
    addTearDown(curso.close);
    addTearDown(cubit.close);
    await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
    await tester.runAsync(cubit.carregar);
    await tester.pumpWidget(RepositoryProvider<Tradutor>.value(
      value: tradutor ?? _Tradutor('?'),
      child: MultiBlocProvider(
        providers: [BlocProvider.value(value: curso), BlocProvider.value(value: cubit)],
        child: MaterialApp(
          theme: Mixart.tema(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  key: const Key('abrir'),
                  onPressed: () => abrirMinhasPalavras(context),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.byKey(const Key('abrir')));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
    // a página usa a voz do app; os testes trocam pela falsa abrindo a página direto quando precisam ouvir
  }

  Future<void> abrirFolha(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('adicionar-palavra')));
    await tester.pumpAndSettle();
  }

  group('a página', () {
    testWidgets('lista as palavras das lições concluídas e as da leitura, com contagem', (tester) async {
      await montar(tester);
      expect(find.byType(MinhasPalavrasPage), findsOneWidget);
      expect(find.byKey(const Key('palavra-en-coffee')), findsOneWidget);
      expect(find.byKey(const Key('palavra-en-tired')), findsOneWidget);
      expect(find.text('Lição: No café'), findsWidgets);
      expect(find.byKey(const Key('palavra-en-garden')), findsOneWidget);
      final contagem = tester.widget<Text>(find.byKey(const Key('palavras-contagem'))).data!;
      expect(contagem, contains('para revisar hoje'));
      expect(contagem, contains('nos jogos'));
    });

    testWidgets('"Da leitura" lista a palavra guardada em Meus cartões (só ela)', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('filtro-leitura')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('palavra-en-garden')), findsOneWidget);
      expect(find.byKey(const Key('origem-garden')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('origem-garden'))).data, 'Leitura');
      expect(find.byKey(const Key('palavra-en-coffee')), findsNothing);
      expect(cubit.state.banco['garden'], isNull, reason: 'só entra no banco quando a pessoa mexe nela');
    });

    testWidgets('a busca acha por inglês e por português (sem acento)', (tester) async {
      await montar(tester);
      await tester.enterText(find.byKey(const Key('busca-palavras')), 'cafe');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('palavra-en-coffee')), findsOneWidget);
      expect(find.byKey(const Key('palavra-en-tired')), findsNothing);
    });

    testWidgets('tirar dos jogos (🎮) grava noJogo = false; tocar de novo volta', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('jogo-coffee')));
      await tester.pumpAndSettle();
      expect(cubit.state.banco['coffee']!.noJogo, isFalse);
      await tester.tap(find.byKey(const Key('filtro-foraDosJogos')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('palavra-en-coffee')), findsOneWidget);
      await tester.tap(find.byKey(const Key('jogo-coffee')));
      await tester.pumpAndSettle();
      expect(cubit.state.banco['coffee']!.noJogo, isTrue);
    });

    testWidgets('a palavra da leitura entra no banco ao sair dos jogos ou ao editar', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('jogo-garden')));
      await tester.pumpAndSettle();
      final g = cubit.state.banco['garden']!;
      expect(g.origem, OrigemPalavra.leitura);
      expect(g.noJogo, isFalse);
      expect(g.pt, 'jardim');
    });

    testWidgets('editar a tradução de uma palavra de lição', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('menu-tired')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('editar-palavra')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('editar-pt')), 'exausto');
      await tester.tap(find.byKey(const Key('editar-salvar')));
      await tester.pumpAndSettle();
      expect(cubit.state.banco['tired']!.pt, 'exausto');
      expect(find.text('exausto'), findsOneWidget);
    });

    testWidgets('🔊 fala a palavra', (tester) async {
      SharedPreferences.setMockInitialValues({'en_concluidas': ['t1.l1']});
      await montar(tester);
      // reabre a página com a voz falsa
      final nav = Navigator.of(tester.element(find.byType(MinhasPalavrasPage)));
      nav.push(MaterialPageRoute<void>(builder: (_) => MinhasPalavrasPage(voz: voz)));
      await tester.pumpAndSettle();
      final linha = find.byKey(const ValueKey('palavra-coffee')).last;
      await tester.tap(find.descendant(of: linha, matching: find.byTooltip('Ouvir')));
      await tester.pump();
      expect(voz.falas, ['coffee']);
    });

    testWidgets('"Revisar agora" abre o treino só com as palavras vencidas', (tester) async {
      await montar(tester,
          banco: BancoPalavras.vazio
              .com(PalavraDoBanco(en: 'tired', pt: 'cansado', atualizadoEm: 1, cartao: _cartao(proximo: _hoje - 1)))
              .com(PalavraDoBanco(en: 'morning', pt: 'manhã', atualizadoEm: 1, cartao: _cartao(proximo: _hoje + 5)))
              .com(PalavraDoBanco(en: 'please', pt: 'por favor', atualizadoEm: 1, cartao: _cartao(proximo: _hoje))));
      expect(find.text('🎯 Revisar agora (2)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('revisar-palavras')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final pagina = tester.widget<TreinoPalavrasPage>(find.byType(TreinoPalavrasPage));
      expect([for (final p in pagina.palavras) p.en]..sort(), ['please', 'tired']);
    });

    testWidgets('"Jogar com elas" põe as palavras visíveis (que podem jogar) em foco', (tester) async {
      var abriu = 0;
      await montar(tester);
      final nav = Navigator.of(tester.element(find.byType(MinhasPalavrasPage)));
      nav.push(MaterialPageRoute<void>(builder: (_) => MinhasPalavrasPage(aoJogar: () => abriu++)));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('busca-palavras')).last, 'coffee');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('jogar-com-palavras')).last);
      await tester.pumpAndSettle();
      expect(abriu, 1);
      expect(cubit.state.banco.emTreino, ['coffee']);
    });
  });

  group('adicionar', () {
    testWidgets('"apple" preenche "maçã" do dicionário e aparece em Minhas com 🎮 ligado', (tester) async {
      await montar(tester);
      await abrirFolha(tester);
      await tester.enterText(find.byKey(const Key('palavra-en')), 'apple');
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const Key('palavra-pt'))).controller!.text, 'maçã');
      expect(find.byKey(const Key('palavra-origem-pt')), findsOneWidget);
      await tester.tap(find.byKey(const Key('palavra-salvar')));
      await tester.pumpAndSettle();
      expect(find.text('"apple" vai aparecer no Arcade 🎮'), findsOneWidget);
      final p = cubit.state.banco['apple']!;
      expect(p.origem, OrigemPalavra.minha);
      expect(p.noJogo, isTrue);
      await tester.tap(find.byKey(const Key('filtro-minhas')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('palavra-en-apple')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('origem-apple'))).data, 'Minha');
      final jogo = find.byKey(const Key('jogo-apple'));
      expect(find.descendant(of: jogo, matching: find.byWidgetPredicate((w) => w is Opacity && w.opacity == 1)), findsOneWidget);
    });

    testWidgets('"ice cream" mostra o erro "Use só letras" e não deixa salvar', (tester) async {
      await montar(tester);
      await abrirFolha(tester);
      await tester.enterText(find.byKey(const Key('palavra-en')), 'ice cream');
      await tester.pump();
      expect(find.textContaining('Use só letras'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('palavra-pt')), 'sorvete');
      await tester.pump();
      await tester.tap(find.byKey(const Key('palavra-salvar')));
      await tester.pumpAndSettle();
      expect(cubit.state.banco.tamanho, 0);
    });

    testWidgets('palavra repetida avisa que já está no banco', (tester) async {
      await montar(tester, banco: BancoPalavras.vazio.com(const PalavraDoBanco(en: 'book', pt: 'livro', origem: OrigemPalavra.minha)));
      await abrirFolha(tester);
      await tester.enterText(find.byKey(const Key('palavra-en')), 'Book');
      await tester.pump();
      expect(find.text('Essa palavra já está no seu banco'), findsOneWidget);
    });

    testWidgets('palavra fora do dicionário: ✨ Traduzir preenche com o tradutor', (tester) async {
      final t = _Tradutor('abacate');
      await montar(tester, tradutor: t);
      await abrirFolha(tester);
      await tester.enterText(find.byKey(const Key('palavra-en')), 'avocado');
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const Key('palavra-pt'))).controller!.text, isEmpty);
      await tester.tap(find.byKey(const Key('palavra-traduzir')));
      await tester.pumpAndSettle();
      expect(t.pedidos, ['avocado']);
      expect(tester.widget<TextField>(find.byKey(const Key('palavra-pt'))).controller!.text, 'abacate');
      await tester.tap(find.byKey(const Key('palavra-salvar')));
      await tester.pumpAndSettle();
      expect(cubit.state.banco['avocado']!.pt, 'abacate');
    });

    testWidgets('tradutor que falha mostra o aviso e deixa escrever', (tester) async {
      await montar(tester, tradutor: _Tradutor());
      await abrirFolha(tester);
      await tester.enterText(find.byKey(const Key('palavra-en')), 'avocado');
      await tester.pump();
      await tester.tap(find.byKey(const Key('palavra-traduzir')));
      await tester.pumpAndSettle();
      expect(find.text('Não deu para traduzir agora — escreva você'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('palavra-pt')), 'abacate');
      await tester.pump();
      await tester.tap(find.byKey(const Key('palavra-salvar')));
      await tester.pumpAndSettle();
      expect(cubit.state.banco['avocado']!.pt, 'abacate');
    });

    testWidgets('colar 4 linhas: entram 3 e o relatório aponta 1', (tester) async {
      await montar(tester);
      await abrirFolha(tester);
      await tester.tap(find.byKey(const Key('palavra-colar')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('palavra-lista')), 'apple = maçã\nbook - livro\nice cream = sorvete\nhappy');
      await tester.pump();
      await tester.tap(find.byKey(const Key('palavra-salvar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('palavra-relatorio')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('palavra-resumo'))).data, '3 palavras adicionadas · 1 com problema');
      expect(cubit.state.banco['apple']!.pt, 'maçã');
      expect(cubit.state.banco['book']!.pt, 'livro');
      expect(cubit.state.banco['happy']!.pt, 'feliz', reason: 'sem tradução, vale a do dicionário');
      expect(cubit.state.banco['ice cream'], isNull);
      await tester.tap(find.byKey(const Key('palavra-pronto')));
      await tester.pumpAndSettle();
      expect(find.textContaining('3 palavras novas'), findsOneWidget);
    });

    testWidgets('remover uma palavra minha', (tester) async {
      await montar(tester, banco: BancoPalavras.vazio.com(const PalavraDoBanco(en: 'book', pt: 'livro', origem: OrigemPalavra.minha, atualizadoEm: 1)));
      expect(find.byKey(const Key('palavra-en-book')), findsOneWidget);
      await tester.tap(find.byKey(const Key('menu-book')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('remover-palavra')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('palavra-en-book')), findsNothing);
      expect(cubit.state.banco['book']!.removida, isTrue);
    });

    testWidgets('palavra de lição não tem "Remover"', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('menu-coffee')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('editar-palavra')), findsOneWidget);
      expect(find.byKey(const Key('remover-palavra')), findsNothing);
    });
  });

  group('tamanhos', () {
    for (final tam in const [Size(360, 740), Size(1280, 800)]) {
      testWidgets('nada estoura em ${tam.width.toInt()}x${tam.height.toInt()} (página e folha)', (tester) async {
        await montar(tester,
            tamanho: tam,
            banco: BancoPalavras.vazio
                .com(PalavraDoBanco(en: 'tired', pt: 'cansado, exausto, sem forças', atualizadoEm: 1, cartao: _cartao(proximo: _hoje)))
                .com(const PalavraDoBanco(en: 'extraordinarily', pt: 'extraordinariamente', origem: OrigemPalavra.minha, atualizadoEm: 2)));
        expect(tester.takeException(), isNull);
        await abrirFolha(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const Key('palavra-colar')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byKey(const Key('palavra-lista')), 'apple = maçã\nice cream = sorvete');
        await tester.pump();
        await tester.tap(find.byKey(const Key('palavra-salvar')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  test('lerListaColada aceita =, " - ", tab, ; e linha sem tradução; pula linhas vazias', () {
    final r = lerListaColada('apple = maçã\n\nbook - livro\nhappy\tfeliz\n• run; correr\nlonely');
    expect([for (final l in r) (l.linha, l.en, l.pt)], [
      (1, 'apple', 'maçã'),
      (3, 'book', 'livro'),
      (4, 'happy', 'feliz'),
      (5, 'run', 'correr'),
      (6, 'lonely', ''),
    ]);
  });

  group('teimosas', () {
    BancoPalavras banco() => BancoPalavras.vazio
        .com(PalavraDoBanco(
          en: 'tired',
          pt: 'cansado',
          licaoId: 't1.l1',
          cargaErro: 2,
          cargaVistas: 2,
          cargaDia: _hoje,
          errosTotal: 5,
          ultimoErroDia: _hoje - 2,
          atualizadoEm: 3,
        ))
        .com(PalavraDoBanco(en: 'apple', pt: 'maçã', origem: OrigemPalavra.minha, dominadaEm: _hoje - 1, atualizadoEm: 2));

    testWidgets('seção "As que você mais erra", 🔥 e "errou Nx", filtro, treinar, "Já sei essa" e prateleira',
        (tester) async {
      await montar(tester, banco: banco());
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('secao-teimosas')), findsOneWidget);
      expect(find.text('🔥 As que você mais erra'), findsOneWidget);
      expect(find.text('🎯 Treinar as teimosas (1)'), findsOneWidget);
      expect(find.textContaining('🏆 Dominadas: 1', findRichText: true), findsOneWidget);
      expect(find.byKey(const Key('chamas-tired')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('erros-tired'))).data, 'errou 5x · há 2 dias');
      expect(find.byKey(const Key('chamas-coffee')), findsNothing);
      // filtro
      expect(find.text('Teimosas (1)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('filtro-teimosas')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('palavra-en-tired')), findsOneWidget);
      expect(find.byKey(const Key('palavra-en-coffee')), findsNothing);
      // treinar abre a revanche
      await tester.tap(find.byKey(const Key('treinar-teimosas-banco')));
      await tester.pumpAndSettle();
      expect(find.byType(TreinoPalavrasPage), findsOneWidget);
      expect(find.text('🎯 Treino de palavras · 🔥 Revanche das teimosas'), findsOneWidget);
      expect(find.byKey(const Key('passo-relembrar')), findsOneWidget);
      await tester.tap(find.byKey(const Key('treino-fechar')));
      await tester.pumpAndSettle();
      expect(find.byType(TreinoPalavrasPage), findsNothing);
      expect(cubit.state.banco.sugestao.recusasSeguidas, 0);
      // "Já sei essa"
      await tester.tap(find.byKey(const Key('menu-tired')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ja-sei-palavra')));
      await tester.pumpAndSettle();
      expect(cubit.state.banco['tired']!.naoSugerirAte, _hoje + 14);
      expect(find.byKey(const Key('teimosas-vazio')), findsOneWidget);
      expect(find.text('Nenhuma teimosa por aqui 🎉 — erre à vontade, eu anoto.'), findsOneWidget);
      expect(find.text('🔥 As que você mais erra'), findsNothing);
      expect(find.byKey(const Key('secao-teimosas')), findsOneWidget, reason: 'a prateleira de dominadas fica');
    });

    testWidgets('sem teimosas nem dominadas: nada de seção nem de filtro (e nada estoura a 360)', (tester) async {
      await montar(tester, tamanho: const Size(360, 740));
      expect(find.byKey(const Key('secao-teimosas')), findsNothing);
      expect(find.byKey(const Key('filtro-teimosas')), findsNothing);
    });

    testWidgets('o "Nx" dos chips: lapsos do cartão contam; "1x" não aparece', (tester) async {
      final b = banco()
          // só lapsos (de antes das teimosas): errosTotal 0, mas 2 lapsos → "2x"
          .com(const PalavraDoBanco(
              en: 'enough',
              pt: 'suficiente',
              cartao: CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: 1, proximoDia: 99999, lapsos: 2),
              atualizadoEm: 4))
          // carga de verdade com um erro só contado → sem badge
          .com(PalavraDoBanco(
              en: 'because', pt: 'porque', cargaErro: 2, cargaVistas: 2, cargaDia: _hoje, errosTotal: 1, ultimoErroDia: _hoje));
      await montar(tester, banco: b);
      expect(tester.takeException(), isNull);
      expect(find.text('5x'), findsOneWidget, reason: 'tired');
      expect(find.text('2x'), findsOneWidget, reason: 'enough, pelos lapsos');
      expect(find.text('1x'), findsNothing);
    });

    testWidgets('com teimosas a 360: nada estoura', (tester) async {
      await montar(tester, tamanho: const Size(360, 740), banco: banco());
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('secao-teimosas')), findsOneWidget);
    });
  });
}
