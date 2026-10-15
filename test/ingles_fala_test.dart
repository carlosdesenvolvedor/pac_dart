import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/presentation/bloc/typing_bloc.dart';
import 'package:pac_dart/features/ingles/data/reconhecedor_fala.dart';
import 'package:pac_dart/features/ingles/domain/avaliacao.dart';
import 'package:pac_dart/features/ingles/domain/avaliacao_fala.dart';
import 'package:pac_dart/features/ingles/domain/roteiro.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/frase_view.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/leitor_teclado.dart';

void main() {
  group('avaliarFala: o que foi falado contra a frase', () {
    test('caixa e pontuação não contam', () {
      final a = avaliarFala('Good morning, Mike!', ['good morning mike']);
      expect(a.perfeita, isTrue);
      expect(a.erradas, isEmpty);
    });

    test('palavra que não saiu: aponta qual (índice na frase) e conta quantas faltaram', () {
      final a = avaliarFala('Good morning, Mike!', ['good mike']);
      expect(a.perfeita, isFalse);
      expect(a.erradas, {1});
      expect(a.acertos, 2);
      expect(a.palavras, 3);
    });

    test('palavra trocada: a errada é a trocada, as outras seguem certas', () {
      final a = avaliarFala('Good morning, Mike!', ['good evening mike']);
      expect(a.erradas, {1});
      expect(a.aMais, ['evening']);
    });

    test('palavra a mais não reprova', () {
      final a = avaliarFala('Nice to meet you.', ['well nice to meet you']);
      expect(a.perfeita, isTrue);
      expect(a.aMais, ['well']);
    });

    test('contração e forma plena valem nos dois sentidos', () {
      expect(avaliarFala("I'm from Brazil.", ['I am from Brazil']).perfeita, isTrue);
      expect(avaliarFala('I am from Brazil.', ["I'm from Brazil"]).perfeita, isTrue);
      expect(avaliarFala("I don't know.", ['I do not know']).perfeita, isTrue);
      expect(avaliarFala('I do not know.', ["I don't know"]).perfeita, isTrue);
      expect(avaliarFala("I can't go.", ['I cannot go']).perfeita, isTrue);
      expect(avaliarFala("I can't go.", ['I can not go']).perfeita, isTrue);
    });

    test('contração com palavra errada ao lado: só a errada é apontada', () {
      final a = avaliarFala("I'm from Brazil.", ['I am from Chile']);
      expect(a.erradas, {2});
    });

    test('homófonos: a voz não distingue to/too/two', () {
      expect(avaliarFala('I have two cats.', ['I have to cats']).perfeita, isTrue);
      expect(avaliarFala('See you there.', ['see you their']).perfeita, isTrue);
    });

    test('número por extenso vale pelo algarismo e vice-versa', () {
      expect(avaliarFala('It is 7:30.', ['it is seven thirty']).perfeita, isTrue);
      expect(avaliarFala('It is seven thirty.', ['it is 7:30']).perfeita, isTrue);
      expect(avaliarFala('I am twenty-five.', ['I am 25']).perfeita, isTrue);
      expect(avaliarFala('I have 3 cats.', ['I have three cats']).perfeita, isTrue);
    });

    test("it's pode ser it is ou it has na fala", () {
      expect(avaliarFala("It's late.", ['it is late']).perfeita, isTrue);
    });

    test('uma letra de diferença só vale em palavra longa (o ouvido do reconhecedor)', () {
      expect(avaliarFala('Good morning.', ['good mornin']).perfeita, isTrue);
      expect(avaliarFala('He is tall.', ['she is tall']).erradas, {0});
      expect(avaliarFala('A cat.', ['a car']).erradas, {1});
    });

    test('a melhor das hipóteses do reconhecedor vence', () {
      final a = avaliarFala('Where are you from?', ['we are you from', 'where are you from', 'wear are you from']);
      expect(a.perfeita, isTrue);
    });

    test('forma declarada pelo autor (alt) vale por inteiro', () {
      final a = avaliarFala('See you tomorrow.', ['catch you tomorrow'], alternativas: ['Catch you tomorrow.']);
      expect(a.perfeita, isTrue);
      expect(a.palavrasOk.length, 3);
    });

    test('nada ouvido', () {
      final a = avaliarFala('Hello.', ['']);
      expect(a.nada, isTrue);
      expect(a.perfeita, isFalse);
      expect(avaliarFala('Hello.', const []).nada, isTrue);
    });

    test('dito fora de ordem não é a frase', () {
      final a = avaliarFala('How are you?', ['you are how']);
      expect(a.perfeita, isFalse);
    });

    test('índices batem com palavrasDe (hífen e apóstrofo dentro da palavra)', () {
      const frase = "My well-known friend can't come.";
      final a = avaliarFala(frase, ['my friend cannot come']);
      expect(a.palavras, palavrasDe(frase).length);
      expect(a.erradas, {1}); // "well-known"
    });
  });

  group('avaliarFala: nomes valem pelo som (o reconhecedor escreve "Anna" para "Ana")', () {
    test('Ana, Anna, Hannah, Anah e Ahna são a mesma Ana', () {
      for (final dito in ['hi anna good afternoon', 'hi hannah good afternoon', 'hi anah good afternoon', 'hi ahna good afternoon', 'hi ana good afternoon']) {
        expect(avaliarFala('Hi, Ana! Good afternoon!', [dito]).perfeita, isTrue, reason: dito);
      }
    });

    test('só a Ana: o nome sozinho conta como acerto daquela palavra', () {
      final a = avaliarFala('Hi, Ana! Good afternoon!', ['Anna']);
      expect(a.erradas, {0, 2, 3});
      expect(a.acertos, 1);
    });

    test('os nomes do curso com a grafia que o reconhecedor costuma dar', () {
      expect(avaliarFala('This is Sarah.', ['this is Sara']).perfeita, isTrue);
      expect(avaliarFala('Lucas is tired.', ['Lukas is tired']).perfeita, isTrue);
      expect(avaliarFala('I am Emma.', ['I am Ema']).perfeita, isTrue);
      expect(avaliarFala('This is Julia.', ['this is Julie']).perfeita, isTrue);
      expect(avaliarFala('Call Carlos.', ['call Karlos']).perfeita, isTrue);
      expect(avaliarFala('Ana is my friend.', ['Anna is my friend']).perfeita, isTrue, reason: 'nome no começo da frase');
    });

    test('outro nome continua errado (Ben não é Ken, Mike não é Mark)', () {
      expect(avaliarFala('Hi, Ben!', ['hi ken']).erradas, {1});
      expect(avaliarFala('Hi, Mike!', ['hi mark']).erradas, {1});
      expect(avaliarFala('Hi, Ana!', ['hi anne']).erradas, {1});
    });

    test('palavra comum (minúscula) continua exigindo a grafia', () {
      expect(avaliarFala('She is here.', ['she is hear']).perfeita, isTrue, reason: 'homófono');
      expect(avaliarFala('A banana.', ['a bannana']).erradas, isEmpty, reason: '±1 letra em palavra longa');
      expect(avaliarFala('The cat sat.', ['the cap sat']).erradas, {1});
      expect(avaliarFala('He is tall.', ['he is tal']).erradas, {2}, reason: 'sem som de nome em palavra comum');
    });

    test('"I" e as contrações dele não são nome', () {
      expect(avaliarFala("I'm Ana.", ['am Ana']).perfeita, isFalse);
      expect(avaliarFala('I like it.', ['a like it']).erradas, {0});
    });
  });

  group('somarErros', () {
    test('soma tecla e fala na mesma posição', () {
      expect(somarErros({3: 1}, {3: 1, 8: 2}), {3: 2, 8: 2});
      expect(somarErros({3: 1}, null), {3: 1});
    });
  });

  group('LeitorTeclado: o teclado do celular compõe a palavra enquanto se digita', () {
    late List<String> teclas;
    late List<String> ditados;
    late LeitorTeclado leitor;

    TextEditingValue compondo(String t, {int de = 0}) =>
        TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length), composing: TextRange(start: de, end: t.length));
    TextEditingValue fechado(String t) =>
        TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));

    setUp(() {
      teclas = [];
      ditados = [];
      leitor = LeitorTeclado(aoDigitar: teclas.add, aoDitar: ditados.add);
    });

    test('cada letra da palavra em composição chega na hora, não só no espaço', () {
      expect(leitor.ler(compondo('G')), isFalse);
      expect(leitor.ler(compondo('Go')), isFalse);
      expect(leitor.ler(compondo('Goo')), isFalse);
      expect(leitor.ler(compondo('Good')), isFalse);
      expect(teclas, ['G', 'o', 'o', 'd']);
    });

    test('o espaço que fecha a composição só traz o espaço (nada repete) e o campo pode esvaziar', () {
      for (final t in ['G', 'Go', 'Goo', 'Good']) {
        leitor.ler(compondo(t));
      }
      expect(leitor.ler(fechado('Good ')), isTrue);
      expect(teclas, ['G', 'o', 'o', 'd', ' ']);
    });

    test('campo esvaziado: a palavra seguinte começa do zero', () {
      leitor.ler(compondo('Hi'));
      leitor.ler(fechado('Hi '));
      leitor.ler(fechado('')); // o campo foi limpo
      leitor.ler(compondo('I'));
      expect(teclas, ['H', 'i', ' ', 'I']);
    });

    test('autocorreção no meio: só o que mudou volta como tecla', () {
      leitor.ler(compondo('dont'));
      leitor.ler(fechado("don't "));
      expect(teclas, ['d', 'o', 'n', 't', "'", 't', ' ']);
    });

    test('apagar dentro da composição não vira tecla', () {
      leitor.ler(compondo('Goox'));
      leitor.ler(compondo('Goo'));
      leitor.ler(compondo('Good'));
      expect(teclas, ['G', 'o', 'o', 'x', 'd']);
    });

    test('tecla morta sozinha espera a letra que vem (´ + a = á)', () {
      expect(leitor.ler(compondo('´')), isFalse);
      expect(teclas, isEmpty);
      expect(leitor.ler(fechado('á')), isTrue);
      expect(teclas, ['á']);
    });

    test("apóstrofo sozinho em composição espera; depois vale o par ('t)", () {
      leitor.ler(compondo("don"));
      leitor.ler(fechado("don'"));
      leitor.ler(fechado("don't"));
      expect(teclas.join(), "don't");
    });

    test('ditado em andamento (várias palavras na composição) espera o texto final', () {
      expect(leitor.ler(compondo('good morning')), isFalse);
      expect(leitor.ler(compondo('good morning my')), isFalse);
      expect(teclas, isEmpty);
      expect(ditados, isEmpty);
      expect(leitor.ler(fechado('Good morning Mike')), isTrue);
      expect(ditados, ['Good morning Mike']);
      expect(teclas, isEmpty);
    });

    test('várias palavras de uma vez (colar, sugestão em bloco) = frase ditada', () {
      expect(leitor.ler(fechado('nice to meet you ')), isTrue);
      expect(ditados, ['nice to meet you']);
    });

    test('uma palavra com espaço (swipe, sugestão da barra) continua sendo tecla a tecla', () {
      expect(leitor.ler(fechado('hello ')), isTrue);
      expect(teclas, ['h', 'e', 'l', 'l', 'o', ' ']);
      expect(ditados, isEmpty);
    });

    test('no computador (sem aoDitar) texto que chega junto continua valendo tecla a tecla', () {
      final t = <String>[];
      final desktop = LeitorTeclado(aoDigitar: t.add);
      desktop.ler(fechado('a b'));
      expect(t, ['a', ' ', 'b']);
    });

    test('quebra de linha e tab não entram na frase', () {
      leitor.ler(fechado('a\tb\n'));
      expect(teclas, ['a', 'b']);
    });

    test('esquecer: a palavra que o teclado segue compondo não vale na frase seguinte', () {
      leitor.ler(compondo('Mike'));
      leitor.esquecer('Mike');
      leitor.ler(compondo('MikeG'));
      expect(teclas, ['M', 'i', 'k', 'e', 'G']);
    });
  });

  group('FraseView no celular (teclado virtual e microfone)', () {
    setUp(() => FraseView.carencia = Duration.zero);
    tearDown(() => FraseView.carencia = const Duration(milliseconds: 350));

    // a plataforma é uma "variante" do teste (o Flutter confere que ela volta ao normal)
    void celular(String descricao, Future<void> Function(WidgetTester tester) corpo,
            {TargetPlatform plataforma = TargetPlatform.android}) =>
        testWidgets(descricao, corpo, variant: TargetPlatformVariant.only(plataforma));

    Future<({TypingBloc bloc, GlobalKey<FraseViewState> chave, _RecFake rec, List<bool> mic, List<String> ouviu})> montar(
      WidgetTester tester, {
      ModoFrase modo = ModoFrase.memoria,
      String frase = 'Good morning, Mike!',
      _RecFake? rec,
    }) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final bloc = TypingBloc()..add(TrechoCarregado(frase, tolerante: modo.deMemoria));
      addTearDown(bloc.close);
      final chave = GlobalKey<FraseViewState>();
      final r = rec ?? _RecFake();
      final mic = <bool>[];
      final ouviu = <String>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: bloc,
            child: SingleChildScrollView(
              child: FraseView(
                key: chave,
                modo: modo,
                reconhecedor: r,
                onAvancar: () {},
                onOuvir: ({required bool lenta}) => ouviu.add(lenta ? 'lenta' : 'normal'),
                onMicrofone: mic.add,
              ),
            ),
          ),
        ),
      ));
      await tester.pump();
      await tester.showKeyboard(find.byType(TextField));
      return (bloc: bloc, chave: chave, rec: r, mic: mic, ouviu: ouviu);
    }

    TextEditingValue compondo(String t) =>
        TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length), composing: TextRange(start: 0, end: t.length));

    celular('Gboard: o Pac-Man anda a cada letra da palavra em composição', (tester) async {
      final m = await montar(tester);
      tester.testTextInput.updateEditingValue(compondo('G'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(compondo('Go'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(compondo('Goo'));
      await tester.pump();
      tester.testTextInput.updateEditingValue(compondo('Good'));
      await tester.pump();
      expect(m.bloc.state.idx, 4, reason: 'as 4 letras já foram comidas, sem esperar o espaço');
      // o espaço fecha a palavra
      tester.testTextInput.updateEditingValue(const TextEditingValue(text: 'Good ', selection: TextSelection.collapsed(offset: 5)));
      await tester.pump();
      expect(m.bloc.state.idx, 5);
      expect(m.bloc.state.errosSessao, 0);
    });

    celular('Gboard: letra errada em composição conta erro na hora', (tester) async {
      final m = await montar(tester);
      tester.testTextInput.updateEditingValue(compondo('Gx'));
      await tester.pump();
      expect(m.bloc.state.errosSessao, 1);
      expect(m.bloc.state.idx, 1);
    });

    celular('ditado pelo 🎤 do teclado: frase certa vale como resposta falada, sem erro de tecla', (tester) async {
      final m = await montar(tester);
      tester.testTextInput.updateEditingValue(
          const TextEditingValue(text: 'good morning Mike', selection: TextSelection.collapsed(offset: 17)));
      await tester.pump();
      expect(m.bloc.state.concluido, isTrue);
      expect(m.bloc.state.errosSessao, 0);
      expect(m.chave.currentState!.errosDeFala, isEmpty);
    });

    celular('ditado com palavra errada: não conclui, mostra o que ouviu e conta o erro na palavra', (tester) async {
      final m = await montar(tester);
      tester.testTextInput.updateEditingValue(
          const TextEditingValue(text: 'good evening Mike', selection: TextSelection.collapsed(offset: 17)));
      await tester.pump();
      expect(m.bloc.state.concluido, isFalse);
      expect(m.bloc.state.errosSessao, 0, reason: 'não virou cascata de teclas erradas');
      expect(m.chave.currentState!.errosDeFala, {5: 1}); // "morning" começa na posição 5
      expect(find.textContaining('Ouvi:', findRichText: true), findsOneWidget);
      expect(find.textContaining('faltou 1 palavra', findRichText: true), findsOneWidget);
    });

    celular('a mesma palavra errada duas vezes é revelada (dica), como a letra errada duas vezes', (tester) async {
      final m = await montar(tester);
      for (var i = 0; i < 2; i++) {
        tester.testTextInput.updateEditingValue(
            TextEditingValue(text: 'good evening Mike${' ' * i}', selection: TextSelection.collapsed(offset: 17 + i)));
        await tester.pump();
      }
      expect(m.chave.currentState!.errosDeFala[5], 2);
      expect(m.chave.currentState!.reveladas, containsAll([5, 6, 7, 8, 9, 10, 11]));
    });

    celular('no computador, texto colado com espaços continua tecla a tecla (nada de resposta falada)', (tester) async {
      final m = await montar(tester);
      tester.testTextInput.updateEditingValue(
          const TextEditingValue(text: 'Gxod morning', selection: TextSelection.collapsed(offset: 12)));
      await tester.pump();
      expect(m.bloc.state.errosSessao, greaterThan(0));
      expect(m.chave.currentState!.errosDeFala, isEmpty);
      expect(find.byIcon(Icons.mic_rounded), findsNothing, reason: 'o microfone é do celular');
    }, plataforma: TargetPlatform.macOS);

    celular('🎤: ouve, mostra o parcial, confere e conclui; o app calou a voz ao abrir o microfone', (tester) async {
      final m = await montar(tester);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      expect(m.rec.iniciadas, 1);
      expect(m.mic, [true]);
      expect(m.chave.currentState!.ouvindo, isTrue);
      expect(find.textContaining('Ouvindo'), findsOneWidget);
      m.rec.parcial?.call('good morn');
      await tester.pump();
      expect(find.textContaining('good morn'), findsOneWidget);
      m.rec.terminar(['good morning mike']);
      await tester.pump();
      expect(m.bloc.state.concluido, isTrue);
      expect(m.mic, [true, false]);
      expect(m.chave.currentState!.ouvindo, isFalse);
    });

    celular('🎤: tocar de novo enquanto ouve pede o resultado (parar)', (tester) async {
      final m = await montar(tester);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();
      expect(m.rec.pararChamado, 1);
    });

    celular('🎤: fala errada mostra o que ouviu (palavra errada riscada) e deixa tentar de novo', (tester) async {
      final m = await montar(tester);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      m.rec.terminar(['good evening mike']);
      await tester.pump();
      expect(m.bloc.state.concluido, isFalse);
      expect(find.textContaining('Ouvi:', findRichText: true), findsOneWidget);
      expect(find.byIcon(Icons.mic_rounded), findsOneWidget, reason: 'volta o botão para tentar de novo');
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      expect(m.rec.iniciadas, 2);
      m.rec.terminar(['good morning mike']);
      await tester.pump();
      expect(m.bloc.state.concluido, isTrue);
      // a tentativa errada fica na nota (1 erro numa palavra longa ainda é tolerado)
      final av = avaliarDigitacao(m.bloc.state.chars.join(),
          errosPorPosicao: somarErros(m.bloc.state.errosPorPosicao, m.chave.currentState!.errosDeFala));
      expect(av.palavrasErradas, isEmpty);
    });

    celular('🎤: erros do reconhecedor viram um recado que diz o que fazer', (tester) async {
      final m = await montar(tester);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      m.rec.erro?.call(ErroFala.semPermissao);
      m.rec.fim?.call();
      await tester.pump();
      expect(find.textContaining('bloqueado'), findsOneWidget);
      expect(m.chave.currentState!.ouvindo, isFalse);
      expect(m.mic, [true, false]);
    });

    celular('🎤: navegador sem reconhecimento de voz explica e manda usar o 🎤 do teclado', (tester) async {
      final m = await montar(tester, rec: _RecFake(suportado: false));
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      expect(m.rec.iniciadas, 0);
      expect(find.textContaining('teclado'), findsWidgets);
      expect(m.mic, isEmpty);
    });

    celular('🎤: some quando a frase termina e a escuta aberta é cancelada ao desmontar', (tester) async {
      final m = await montar(tester);
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      expect(m.rec.cancelarChamado, 1);
    });

    celular('Enter/ok do teclado virtual: ouve uma vez (a ação e a tecla no mesmo toque não duplicam)', (tester) async {
      final m = await montar(tester);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(m.ouviu, hasLength(1));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(m.ouviu, hasLength(1), reason: 'a tecla veio logo depois da ação: é o mesmo toque');
    });

    celular('"não sei" na tela (celular não tem Esc): revela a frase', (tester) async {
      final m = await montar(tester);
      await tester.tap(find.text('não sei'));
      await tester.pump();
      expect(m.chave.currentState!.desistiu, isTrue);
      expect(m.chave.currentState!.reveladas, isNotEmpty);
    });

    celular('copiar com a frase à vista: falar a frase também completa', (tester) async {
      final m = await montar(tester, modo: ModoFrase.ver);
      expect(find.text('não sei'), findsNothing, reason: 'copiando, a frase já está à vista');
      await tester.tap(find.byIcon(Icons.mic_rounded));
      await tester.pump();
      m.rec.terminar(['Good morning Mike']);
      await tester.pump();
      expect(m.bloc.state.concluido, isTrue);
    });
  });
}

class _RecFake extends ReconhecedorFala {
  final bool _suportado;
  _RecFake({bool suportado = true}) : _suportado = suportado;

  int iniciadas = 0, pararChamado = 0, cancelarChamado = 0;
  void Function(String)? parcial;
  void Function(List<String>)? final_;
  void Function(ErroFala)? erro;
  void Function()? fim;

  @override
  bool get suportado => _suportado;

  @override
  SessaoFala ouvir({
    String idioma = 'en-US',
    required void Function(String texto) aoParcial,
    required void Function(List<String> hipoteses) aoFinal,
    required void Function(ErroFala erro) aoErro,
    required void Function() aoFim,
  }) {
    iniciadas++;
    parcial = aoParcial;
    final_ = aoFinal;
    erro = aoErro;
    fim = aoFim;
    return _SessaoFake(this);
  }

  /// O reconhecedor entrega o final e fecha, como o navegador faz.
  void terminar(List<String> hipoteses) {
    final_?.call(hipoteses);
    fim?.call();
  }
}

class _SessaoFake implements SessaoFala {
  final _RecFake rec;
  _SessaoFake(this.rec);
  @override
  void parar() => rec.pararChamado++;
  @override
  void cancelar() => rec.cancelarChamado++;
}
