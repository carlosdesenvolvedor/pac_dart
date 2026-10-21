// 🏁 RaliPage no "⚡ Treino do dia" (grupo C): sem tela de início (começa sozinho no Fácil), UMA fase só,
// sem oferta das teimosas, e o fim "FASE VENCIDA! ⚡" / "A CPU VENCEU…" com "Continuar o treino →" como
// botão principal, devolvendo ResultadoFaseTreino. A pausa → Sair devolve null. Fora do treino, nada muda.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/arcade/presentation/rali_page.dart';
import 'package:pac_dart/features/arcade/presentation/voz_jogo.dart';
import 'package:pac_dart/features/arcade/presentation/widgets/arcade_ui.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/palavras_repository.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/presentation/palavras_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Mudo implements FalanteDoJogo {
  @override
  bool get liberado => true;
  @override
  void falar(String palavra) {}
  @override
  void parar() {}
}

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
  'rice': 'arroz',
  'soup': 'sopa',
  'fish': 'peixe',
  'egg': 'ovo',
  'salt': 'sal',
  'sugar': 'açúcar',
  'lunch': 'almoço',
  'cheese': 'queijo',
});

final _trilhas = [
  const Trilha(nivel: 'T1', emoji: '🍽️', etapa: 'A1 · Fundação', licoes: [
    Licao(nome: 'Comida', emoji: '🍞', id: 't1.l1', trechos: [
      Trecho(cod: 'I want tea, milk, cake and bread.', dica: 'Quero chá, leite, bolo e pão.', out: ''),
      Trecho(cod: 'Apple juice, rice, soup and fish.', dica: 'Suco de maçã, arroz, sopa e peixe.', out: ''),
      Trecho(cod: 'Egg, salt, sugar, cheese, lunch.', dica: 'Ovo, sal, açúcar, queijo, almoço.', out: ''),
    ]),
  ]),
];

/// O que a RaliPage devolveu ao sair (e se saiu).
class _Saida {
  bool saiu = false;
  ResultadoFaseTreino? resultado;
}

/// Uma tela-base que empurra [pagina] (como o treino faz) e anota o que volta.
Widget _host(Widget pagina, _Saida saida, {CursoBloc? curso, PalavrasCubit? palavras}) {
  Widget w = MaterialApp(
    theme: Mixart.tema(),
    home: Builder(
      builder: (context) => Scaffold(
        body: Center(
          child: TextButton(
            onPressed: () async {
              final r = await Navigator.of(context)
                  .push<ResultadoFaseTreino>(MaterialPageRoute<ResultadoFaseTreino>(builder: (_) => pagina));
              saida
                ..saiu = true
                ..resultado = r;
            },
            child: const Text('abrir rali'),
          ),
        ),
      ),
    ),
  );
  if (palavras != null) w = BlocProvider.value(value: palavras, child: w);
  if (curso != null) w = BlocProvider<CursoBloc>.value(value: curso, child: w);
  return w;
}

Future<void> _abrir(WidgetTester tester) async {
  await tester.tap(find.text('abrir rali'));
  await tester.pump(); // a rota entra
  await tester.pump(); // o 1º frame da RaliPage agenda a largada (pós-frame)
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _largada(WidgetTester tester) async {
  await tester.pump(ContagemRegressiva.duracao + const Duration(milliseconds: 50));
  await tester.pump();
}

/// Digita no campo invisível, letra a letra (o texto só cresce; [buffer] guarda o que já foi).
class _Teclado {
  String buffer = '';
  Future<void> digitar(WidgetTester tester, String s) async {
    if (buffer.length + s.length > 180) {
      buffer = '';
      await tester.enterText(find.byType(TextField), '');
    }
    for (final ch in s.split('')) {
      buffer += ch;
      await tester.enterText(find.byType(TextField), buffer);
      await tester.pump();
    }
  }
}

String _alvo(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('rali-alvo'))).textSpan!.toPlainText();

/// Digita a fase inteira lendo a palavra da tela (com [erros] teclas erradas antes de cada uma) até o fim
/// do jogo aparecer.
Future<void> _vencerFase(WidgetTester tester, {String erros = ''}) async {
  final t = _Teclado();
  for (var i = 0; i < 30 && find.byType(FimDeJogo).evaluate().isEmpty; i++) {
    await t.digitar(tester, '$erros${_alvo(tester)}');
  }
  await tester.pump(const Duration(milliseconds: 900)); // o overlay entra
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  setUp(() {
    SharedPreferences.setMockInitialValues({'turismo_tutorial_digitacao': true});
    VozDoJogo.falanteDeTeste = () => _Mudo();
  });
  tearDown(() {
    VozDoJogo.falanteDeTeste = null;
    Linguagem.atual = Linguagem.dart;
  });

  void tela(WidgetTester tester, [Size s = const Size(1000, 1500)]) {
    tester.view.physicalSize = s;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  for (final l in [Linguagem.dart, Linguagem.ingles]) {
    testWidgets('${l.id}: treino começa sozinho no Fácil, uma fase só e "Continuar o treino →" devolve a vitória',
        (tester) async {
      Linguagem.atual = l;
      tela(tester);
      final saida = _Saida();
      await tester.pumpWidget(_host(const RaliPage(semente: 3, treino: true), saida));
      await _abrir(tester);

      expect(find.text('Escolha o rival:'), findsNothing, reason: 'sem tela de início');
      expect(find.byType(SeletorDificuldade), findsNothing);
      expect(find.byType(ContagemRegressiva), findsOneWidget, reason: 'a largada sai sozinha');
      await _largada(tester);
      expect(find.byKey(const Key('rali-alvo')), findsOneWidget);

      await _vencerFase(tester);
      expect(find.text('FASE 1 CONCLUÍDA!'), findsNothing, reason: 'uma fase só: nada de overlay da fase');
      expect(find.byType(FimDeJogo), findsOneWidget);
      expect(find.text('FASE VENCIDA! ⚡'), findsOneWidget);
      expect(find.textContaining('Fase relâmpago do treino: '), findsOneWidget);
      expect(find.text('Jogar de novo'), findsNothing);
      expect(find.text('Voltar ao Arcade'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Continuar o treino →'), findsOneWidget,
          reason: 'o botão principal, não o contornado');
      expect(find.widgetWithText(OutlinedButton, 'Continuar o treino →'), findsNothing);
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Continuar o treino →'));
      await tester.tap(find.text('Continuar o treino →'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RaliPage), findsNothing);
      expect(saida.saiu, isTrue);
      final r = saida.resultado!;
      expect(r.venceu, isTrue);
      expect(r.pontos, greaterThan(0));
      expect(r.palavras, greaterThan(0));
      expect(find.text('abrir rali'), findsOneWidget, reason: 'voltou só uma tela');
      await tester.pumpWidget(Container());
    });
  }

  testWidgets('treino: a CPU vence → "A CPU VENCEU…" e devolve venceu: false', (tester) async {
    tela(tester);
    final saida = _Saida();
    await tester.pumpWidget(_host(const RaliPage(semente: 3, treino: true), saida));
    await _abrir(tester);
    await _largada(tester);
    // ninguém digita: a CPU anda a cada ~6 s até o fim da pista
    for (var i = 0; i < 200 && find.byType(FimDeJogo).evaluate().isEmpty; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('A CPU VENCEU…'), findsOneWidget);
    expect(find.text('Fase relâmpago do treino: 0 palavras.'), findsOneWidget);
    expect(find.text('Jogar de novo'), findsNothing);
    await tester.ensureVisible(find.text('Continuar o treino →'));
    await tester.tap(find.text('Continuar o treino →'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(saida.saiu, isTrue);
    expect(saida.resultado!.venceu, isFalse);
    expect(saida.resultado!.palavras, 0);
    await tester.pumpWidget(Container());
  });

  testWidgets('treino: fase encerrada + voltar do sistema/navegador devolve o resultado (como o botão)',
      (tester) async {
    tela(tester);
    final saida = _Saida();
    await tester.pumpWidget(_host(const RaliPage(semente: 3, treino: true), saida));
    await _abrir(tester);
    await _largada(tester);
    await _vencerFase(tester);
    expect(find.text('FASE VENCIDA! ⚡'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RaliPage), findsNothing);
    expect(saida.saiu, isTrue);
    expect(saida.resultado, isNotNull, reason: 'a fase já foi jogada: nada de etapa pendente');
    expect(saida.resultado!.venceu, isTrue);
    expect(saida.resultado!.pontos, greaterThan(0));
    expect(find.text('abrir rali'), findsOneWidget, reason: 'voltou só uma tela');
    await tester.pumpWidget(Container());
  });

  testWidgets('treino: voltar do sistema no meio da corrida segue devolvendo null', (tester) async {
    tela(tester);
    final saida = _Saida();
    await tester.pumpWidget(_host(const RaliPage(semente: 3, treino: true), saida));
    await _abrir(tester);
    await _largada(tester);
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RaliPage), findsNothing);
    expect(saida.saiu, isTrue);
    expect(saida.resultado, isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('treino: pausa → Sair do jogo devolve null (a etapa fica pendente)', (tester) async {
    tela(tester);
    final saida = _Saida();
    await tester.pumpWidget(_host(const RaliPage(semente: 3, treino: true), saida));
    await _abrir(tester);
    await _largada(tester);
    await tester.tap(find.byTooltip('Pausar (Esc)'));
    await tester.pump();
    await tester.tap(find.text('Sair do jogo'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(RaliPage), findsNothing);
    expect(saida.saiu, isTrue);
    expect(saida.resultado, isNull);
    await tester.pumpWidget(Container());
  });

  testWidgets('inglês com o banco: no treino, nenhuma oferta das teimosas mesmo com tropeços', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tela(tester, const Size(900, 1600));
    final curso = _CursoFake(CursoState(
      status: CursoStatus.pronto,
      trilhas: _trilhas,
      linguagem: Linguagem.ingles,
      concluidas: const {'t1.l1'},
    ));
    final cubit = PalavrasCubit(repo: MemoriaPalavrasRepository(), carregarDicionario: () async => _dic);
    await tester.runAsync(() async {
      await cubit.carregar();
      await cubit.prepararIndice(_trilhas);
    });
    // três teimosas "de sempre" (a política de oferta deixaria mostrar)
    cubit.registrarErros([
      for (final w in ['cake', 'bread', 'apple'])
        for (var i = 0; i < 2; i++) EvidenciaPalavra(chave: w, peso: 1, falha: 1, fonte: FonteErro.licao),
    ]);
    expect(cubit.quantasTeimosas, 3);
    final mostradas = cubit.state.banco.sugestao.mostradasHoje;

    final saida = _Saida();
    await tester.pumpWidget(_host(const RaliPage(semente: 3, treino: true), saida, curso: curso, palavras: cubit));
    await _abrir(tester);
    await _largada(tester);
    await _vencerFase(tester, erros: '##'); // cada palavra com 2 teclas erradas: todas escapam
    expect(find.text('FASE VENCIDA! ⚡'), findsOneWidget);
    expect(find.byKey(const Key('rali-teimosas')), findsNothing, reason: 'sem o painel entre as fases');
    expect(find.byKey(const Key('cartao-teimosas')), findsNothing, reason: 'sem a oferta do fim');
    expect(find.byKey(const Key('fim-revanche')), findsNothing);
    expect(cubit.state.banco.sugestao.mostradasHoje, mostradas, reason: 'a cota de ofertas não gasta');
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Continuar o treino →'));
    await tester.tap(find.text('Continuar o treino →'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(saida.resultado!.venceu, isTrue);
    await tester.pumpWidget(Container());
    await tester.runAsync(() async {
      await cubit.gravacoes;
      await cubit.close();
      await curso.close();
    });
  });

  testWidgets('fora do treino: RaliPage() ainda abre na tela de início', (tester) async {
    tela(tester);
    await tester.pumpWidget(MaterialApp(theme: Mixart.tema(), home: const RaliPage(semente: 3)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Escolha o rival:'), findsOneWidget);
    expect(find.byType(SeletorDificuldade), findsOneWidget);
    expect(find.byType(ContagemRegressiva), findsNothing, reason: 'não larga sozinho');
    await tester.pumpWidget(Container());
  });

  testWidgets('FimDeJogo: os padrões de sempre ("Jogar de novo" cheio + "Voltar ao Arcade" contornado)',
      (tester) async {
    tela(tester);
    var deNovo = 0, sair = 0;
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: Scaffold(
        body: Stack(children: [
          FimDeJogo(
            emoji: '🏆',
            titulo: 'FIM DA CAMPANHA!',
            subtitulo: 'x',
            pontos: 10,
            novoRecorde: false,
            stats: const [],
            onDeNovo: () => deNovo++,
            onSair: () => sair++,
          ),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.widgetWithText(FilledButton, 'Jogar de novo'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Voltar ao Arcade'), findsOneWidget);
    await tester.tap(find.text('Jogar de novo'));
    await tester.tap(find.text('Voltar ao Arcade'));
    expect((deNovo, sair), (1, 1));

    // sem o "de novo": o sair vira o botão cheio, com o texto pedido
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: Scaffold(
        body: Stack(children: [
          FimDeJogo(
            emoji: '🏆',
            titulo: 'FASE VENCIDA! ⚡',
            subtitulo: 'x',
            pontos: 10,
            novoRecorde: false,
            stats: const [],
            onDeNovo: () => deNovo++,
            onSair: () => sair++,
            mostrarDeNovo: false,
            rotuloSair: 'Continuar o treino →',
          ),
        ]),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('Jogar de novo'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Continuar o treino →'), findsOneWidget);
    await tester.tap(find.text('Continuar o treino →'));
    expect((deNovo, sair), (1, 2));
  });

  // (no inglês: no Dart, a linha "a seguir" do Rali já estoura 18 px em 360 — antes do treino, fora do escopo)
  testWidgets('treino em celular 360 (inglês): o fim cabe sem estouro', (tester) async {
    Linguagem.atual = Linguagem.ingles;
    tela(tester, const Size(360, 800));
    final saida = _Saida();
    await tester.pumpWidget(_host(const RaliPage(semente: 3, treino: true), saida));
    await _abrir(tester);
    await _largada(tester);
    await _vencerFase(tester);
    expect(find.text('FASE VENCIDA! ⚡'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(Container());
  });
}
