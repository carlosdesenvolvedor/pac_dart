// "📚 Palavras: …" no hub do Arcade (inglês) e a tela "Lições das palavras": escolher as lições de onde
// vêm as palavras dos jogos, o total ao vivo, o Automático, o "incluir minhas palavras", o aviso de
// poucas palavras — e os jogos pegando a escolha na hora.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/domain/palavras_ingles.dart';
import 'package:pac_dart/features/arcade/presentation/arcade_page.dart';
import 'package:pac_dart/features/arcade/presentation/banco_arcade.dart';
import 'package:pac_dart/features/arcade/presentation/escolher_licoes_page.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _CursoFake extends CursoBloc {
  _CursoFake(CursoState s) : super(loader: CurriculoLoader(), progresso: LocalProgressoRepository()) {
    emit(s);
  }
}

const _dic = Dicionario({
  'want': 'querer',
  'tea': 'chá',
  'milk': 'leite',
  'cake': 'bolo',
  'bread': 'pão',
  'apple': 'maçã',
  'juice': 'suco',
  'breakfast': 'café da manhã',
  'chocolate': 'chocolate',
  'strawberries': 'morangos',
  'dessert': 'sobremesa',
  'vegetables': 'legumes',
  'cheese': 'queijo',
  'tomatoes': 'tomates',
  'good': 'bom',
  'morning': 'manhã',
  'street': 'rua',
  'hospital': 'hospital',
  'airport': 'aeroporto',
});

const _trilhas = [
  Trilha(nivel: 'Comida', emoji: '🍞', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Café da manhã', emoji: '☕', id: 'a.l1', trechos: [
      Trecho(cod: 'I want tea, milk, cake and bread.', dica: 'Quero chá, leite, bolo e pão.', out: ''),
      Trecho(cod: 'Apple juice and breakfast.', dica: 'Suco de maçã e café da manhã.', out: ''),
    ]),
    Licao(nome: 'Sobremesa', emoji: '🍫', id: 'a.l2', trechos: [
      Trecho(cod: 'Chocolate and strawberries for dessert.', dica: 'Chocolate e morangos de sobremesa.', out: ''),
      Trecho(cod: 'Vegetables, cheese and tomatoes.', dica: 'Legumes, queijo e tomates.', out: ''),
    ]),
  ]),
  Trilha(nivel: 'Cidade', emoji: '🏙️', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Bom dia', emoji: '🌅', id: 'b.l1', trechos: [
      Trecho(cod: 'Good morning.', dica: 'Bom dia.', out: ''),
    ]),
    Licao(nome: 'Na rua', emoji: '🚶', id: 'b.l2', trechos: [
      Trecho(cod: 'The street and the hospital.', dica: 'A rua e o hospital.', out: ''),
    ]),
  ]),
  Trilha(nivel: 'Viagem', emoji: '✈️', etapa: 'A2 · Dia a dia', licoes: [
    Licao(nome: 'Aeroporto', emoji: '🛫', id: 'c.l1', trechos: [
      Trecho(cod: 'The airport.', dica: 'O aeroporto.', out: ''),
    ]),
  ]),
];

const _daUnidadeA = {
  'want', 'tea', 'milk', 'cake', 'bread', 'apple', 'juice', 'breakfast', //
  'chocolate', 'strawberries', 'dessert', 'vegetables', 'cheese', 'tomatoes',
};

Future<(CursoBloc, PalavrasCubit, MemoriaPalavrasRepository)> _providers(WidgetTester tester) async {
  final curso = _CursoFake(const CursoState(
    status: CursoStatus.pronto,
    trilhas: _trilhas,
    linguagem: Linguagem.ingles,
    concluidas: {'a.l1', 'a.l2'},
    trilhaIdx: 1,
  ));
  final repo = MemoriaPalavrasRepository();
  final cubit = PalavrasCubit(repo: repo, carregarDicionario: () async => _dic);
  await tester.runAsync(() async {
    await cubit.carregar();
    await cubit.prepararIndice(_trilhas);
  });
  return (curso, cubit, repo);
}

Widget _app(Widget home, CursoBloc curso, PalavrasCubit palavras) => BlocProvider.value(
      value: curso,
      child: BlocProvider.value(value: palavras, child: MaterialApp(theme: Mixart.tema(), home: home)),
    );

Future<void> _assentar(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pump();
  await tester.tap(f);
  await tester.pump();
}

String _total(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('licoes-total'))).data!;

Future<void> _fechar(WidgetTester tester, CursoBloc curso, PalavrasCubit cubit) async {
  await tester.pumpWidget(Container());
  await tester.runAsync(() async {
    await cubit.gravacoes;
    await cubit.close();
    await curso.close();
  });
}

void _tela(WidgetTester tester, Size s) {
  tester.view.physicalSize = s;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Linguagem.atual = Linguagem.dart);

  testWidgets('hub → escolher uma unidade, total ao vivo, Automático volta, salvar → jogos usam a escolha',
      (tester) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(tester, const Size(1000, 2000));
    final (curso, cubit, repo) = await _providers(tester);
    expect(cubit.adicionar('kettle', 'chaleira'), isNull);
    await tester.pumpWidget(_app(const ArcadePage(), curso, cubit));
    await tester.pump();

    final botao = find.byKey(const Key('arcade-escolher-licoes'));
    expect(botao, findsOneWidget);
    expect(find.descendant(of: botao, matching: find.text('📚 Palavras: Automático')), findsOneWidget);

    await _tocar(tester, botao);
    await _assentar(tester);
    expect(find.byType(EscolherLicoesPage), findsOneWidget);
    expect(_total(tester), '✨ Automático');
    expect(find.byKey(const Key('licoes-aviso-automatico')), findsOneWidget);
    // as unidades liberadas aparecem por etapa; a inteira trancada fica de fora
    expect(find.text('A1 · FUNDAÇÃO'), findsOneWidget);
    expect(find.textContaining('Viagem'), findsNothing);
    expect(find.textContaining('Mais 1 unidade abre'), findsOneWidget);

    // marcar a unidade inteira: o total conta as palavras das duas lições
    await _tocar(tester, find.byKey(const Key('unidade-tr:a')));
    expect(_total(tester), '2 lições · 14 palavras + 1 sua');
    expect(find.byKey(const Key('licoes-aviso-automatico')), findsNothing);

    // Automático desfaz
    await _tocar(tester, find.byKey(const Key('licoes-automatico')));
    expect(_total(tester), '✨ Automático');

    // de novo, sem as minhas palavras, e salvar
    await _tocar(tester, find.byKey(const Key('unidade-tr:a')));
    await _tocar(tester, find.byKey(const Key('licoes-incluir-minhas')));
    expect(_total(tester), '2 lições · 14 palavras');
    await _tocar(tester, find.byKey(const Key('licoes-salvar')));
    await _assentar(tester);
    expect(find.byType(EscolherLicoesPage), findsNothing);

    expect(cubit.licoesDoJogo, {'a.l1', 'a.l2'});
    expect(cubit.minhasNoJogo, isFalse);
    await tester.runAsync(() => cubit.gravacoes);
    expect(repo.banco.licoesJogo, ['a.l1', 'a.l2']);

    // o hub mostra a escolha
    expect(find.descendant(of: botao, matching: find.text('📚 Palavras: 2 lições')), findsOneWidget);
    expect(find.textContaining('de 2 lições escolhidas'), findsOneWidget);

    // o que os jogos pegam ao abrir (Chuva, Rali e Turismo chamam o BancoArcade.vocabulario no initState)
    final v = BancoArcade.vocabulario(tester.element(find.byType(ArcadePage)));
    final reserva = {...palavrasCurtasEn, ...palavrasMediasEn, ...palavrasLongasEn};
    for (final w in v.todas) {
      expect(_daUnidadeA.contains(w.toLowerCase()) || reserva.contains(w), isTrue, reason: 'fora da escolha: $w');
    }
    expect(v.todas, containsAll(['tea', 'chocolate', 'strawberries']));
    expect(v.todas, isNot(contains('kettle')), reason: '"incluir minhas palavras" desligado');
    expect(v.todas, isNot(contains('morning')));
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('lição com poucas palavras avisa; trancada não marca; Todas as concluídas e Limpar', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(tester, const Size(360, 800));
    final (curso, cubit, _) = await _providers(tester);
    await tester.pumpWidget(_app(const EscolherLicoesPage(), curso, cubit));
    await _assentar(tester);

    // a unidade da lição atual abre sozinha
    final atual = find.byKey(const Key('licao-b.l1'));
    await tester.scrollUntilVisible(atual, 150,
        scrollable: find.descendant(of: find.byKey(const Key('licoes-lista')), matching: find.byType(Scrollable)).first);
    expect(atual, findsOneWidget);
    expect(find.text('lição atual'), findsOneWidget);
    await _tocar(tester, atual);
    expect(_total(tester), '1 lição · 2 palavras');
    expect(tester.widget<Text>(find.byKey(const Key('licoes-aviso'))).data, contains('Poucas palavras'));

    // a trancada não marca
    final trancada = find.byKey(const Key('licao-b.l2'));
    await _tocar(tester, trancada);
    expect(_total(tester), '1 lição · 2 palavras');
    expect(find.text('🔒 ainda não chegou aqui'), findsOneWidget);

    await _tocar(tester, find.byKey(const Key('licoes-todas-concluidas')));
    expect(_total(tester), '2 lições · 14 palavras');

    await _tocar(tester, find.byKey(const Key('licoes-limpar')));
    expect(_total(tester), '0 lições · 0 palavras');
    expect(tester.widget<Text>(find.byKey(const Key('licoes-aviso'))).data, contains('Marque pelo menos 1 lição'));
    await _tocar(tester, find.byKey(const Key('licoes-salvar')));
    expect(cubit.licoesDoJogo, isNull, reason: 'escolha vazia não salva');
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('voltar com mudança pergunta; Descartar não grava', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(tester, const Size(800, 1000));
    final (curso, cubit, _) = await _providers(tester);
    await tester.pumpWidget(_app(
      Builder(
        builder: (c) => Scaffold(
          body: TextButton(onPressed: () => abrirEscolherLicoes(c), child: const Text('abrir')),
        ),
      ),
      curso,
      cubit,
    ));
    await tester.tap(find.text('abrir'));
    await _assentar(tester);
    await _tocar(tester, find.byKey(const Key('unidade-tr:a')));
    await _tocar(tester, find.byKey(const Key('licoes-voltar')));
    await _assentar(tester);
    expect(find.text('Salvar a escolha?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('licoes-descartar')));
    await _assentar(tester);
    expect(find.byType(EscolherLicoesPage), findsNothing);
    expect(cubit.licoesDoJogo, isNull);

    // sem mudança, volta direto
    await tester.tap(find.text('abrir'));
    await _assentar(tester);
    await _tocar(tester, find.byKey(const Key('licoes-voltar')));
    await _assentar(tester);
    expect(find.byType(EscolherLicoesPage), findsNothing);
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('sem nada marcado, o voltar avisa e "Continuar escolhendo" fica na tela', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(tester, const Size(800, 1000));
    final (curso, cubit, _) = await _providers(tester);
    cubit.escolherLicoesDoJogo(['a.l1']);
    await tester.pumpWidget(_app(
      Builder(
        builder: (c) => Scaffold(
          body: TextButton(onPressed: () => abrirEscolherLicoes(c), child: const Text('abrir')),
        ),
      ),
      curso,
      cubit,
    ));
    await tester.tap(find.text('abrir'));
    await _assentar(tester);
    await _tocar(tester, find.byKey(const Key('licoes-limpar')));
    await _tocar(tester, find.byKey(const Key('licoes-voltar')));
    await _assentar(tester);
    expect(find.text('Nenhuma lição marcada'), findsOneWidget);
    expect(find.text('Salvar a escolha?'), findsNothing);
    expect(find.byKey(const Key('licoes-salvar-dialogo')), findsNothing);
    await tester.tap(find.byKey(const Key('licoes-continuar')));
    await _assentar(tester);
    expect(find.byType(EscolherLicoesPage), findsOneWidget);
    expect(_total(tester), '0 lições · 0 palavras', reason: 'o rascunho continua');

    // com a escolha válida, o diálogo pergunta se salva e também deixa continuar
    await _tocar(tester, find.byKey(const Key('unidade-tr:a')));
    await _tocar(tester, find.byKey(const Key('licoes-voltar')));
    await _assentar(tester);
    expect(find.text('Salvar a escolha?'), findsOneWidget);
    expect(find.byKey(const Key('licoes-continuar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('licoes-salvar-dialogo')));
    await _assentar(tester);
    expect(find.byType(EscolherLicoesPage), findsNothing);
    expect(cubit.licoesDoJogo, {'a.l1', 'a.l2'});
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('lição que não existe mais: não conta, não deixa salvar sozinha e sai ao salvar', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(tester, const Size(800, 1000));
    final (curso, cubit, _) = await _providers(tester);
    // 'txt-apagado' (texto colado que a pessoa apagou) e 'c.l1' (unidade ainda trancada)
    cubit.escolherLicoesDoJogo(['txt-apagado', 'c.l1']);
    await tester.pumpWidget(_app(const EscolherLicoesPage(), curso, cubit));
    await _assentar(tester);
    expect(_total(tester), '0 lições · 0 palavras');
    expect(tester.widget<Text>(find.byKey(const Key('licoes-aviso'))).data, contains('Marque pelo menos 1 lição'));
    await _tocar(tester, find.byKey(const Key('licoes-salvar')));
    expect(cubit.licoesDoJogo, {'txt-apagado', 'c.l1'}, reason: 'Salvar fica desligado só com fantasma');

    await _tocar(tester, find.byKey(const Key('unidade-tr:a')));
    expect(_total(tester), startsWith('2 lições'));
    await _tocar(tester, find.byKey(const Key('licoes-salvar')));
    await _assentar(tester);
    expect(cubit.licoesDoJogo, {'a.l1', 'a.l2', 'c.l1'}, reason: 'a fantasma sai; a da unidade trancada fica');
    expect(tester.takeException(), isNull);
    await _fechar(tester, curso, cubit);
  });

  testWidgets('teclado: Tab chega na unidade e Espaço marca', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    _tela(tester, const Size(1280, 900));
    final (curso, cubit, _) = await _providers(tester);
    await tester.pumpWidget(_app(const EscolherLicoesPage(), curso, cubit));
    await _assentar(tester);
    bool focoNaCaixa() {
      final ctx = FocusManager.instance.primaryFocus?.context;
      if (ctx == null) return false;
      var achou = false;
      ctx.visitAncestorElements((e) {
        if (e.widget.key == const Key('unidade-tr:a')) achou = true;
        return !achou;
      });
      return achou;
    }

    for (var i = 0; i < 30 && !focoNaCaixa(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(focoNaCaixa(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(_total(tester), startsWith('2 lições'));
    await _fechar(tester, curso, cubit);
  });

  testWidgets('Dart: o hub não tem a escolha de lições', (tester) async {
    Linguagem.atual = Linguagem.dart;
    _tela(tester, const Size(1000, 2000));
    await tester.pumpWidget(MaterialApp(theme: Mixart.tema(), home: const ArcadePage()));
    await tester.pump();
    expect(find.byKey(const Key('arcade-escolher-licoes')), findsNothing);
  });
}
