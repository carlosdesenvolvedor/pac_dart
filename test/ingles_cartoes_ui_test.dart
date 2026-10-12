import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart';
import 'package:pac_dart/features/ingles/domain/config_srs.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/baralhos_page.dart';
import 'package:pac_dart/features/ingles/presentation/navegador_cartoes_page.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_baralhos_test.dart' show ConfigMemoria, RepoMemoria, f1, f2, f3, trilhasDeTeste;

class VozFake extends VozIngles {
  bool liberado = true;
  final falas = <String>[];
  @override
  Future<void> falar(String frase, {bool? lenta}) {
    falas.add(frase);
    return Future.value();
  }

  @override
  Future<void> parar() async {}
  @override
  bool get somLiberado => liberado;
}

class LoaderTeste extends CurriculoLoader {
  final List<Trilha> trilhas;
  LoaderTeste(this.trilhas) : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}

const _fl = Trecho(
  cod: 'Nice to meet you.',
  dica: 'Prazer em te conhecer.',
  out: '',
  literal: 'Agradável conhecer você.',
  conceito: 'Fórmula ao ser apresentado.',
);

void main() {
  final fsrs = AgendadorFsrs(fuzz: false);
  final hoje = Revisao.dia(DateTime.now());
  String k(Trecho f) => RevisaoCubit.chaveDe(f);

  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('SessaoCartoesPage (inglês na frente, tradução no verso)', () {
    final notas = <(String, Rating)>[];
    List<ResultadoCartao>? fim;
    bool? saiu;

    Future<VozFake> abrir(WidgetTester tester,
        {List<Trecho> itens = const [f1, f2],
        Set<String> novas = const {},
        VozFake? voz,
        Widget Function(BuildContext, Trecho)? extra,
        bool escrita = false,
        Map<String, Object> prefs = const {}}) async {
      // os testes do "só virar" desligam a escrita (o padrão do app é ligada)
      SharedPreferences.setMockInitialValues({SessaoCartoesPage.prefEscrita: escrita, ...prefs});
      notas.clear();
      fim = null;
      saiu = null;
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final v = voz ?? VozFake();
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saiu = await Navigator.of(context).push<bool>(MaterialPageRoute(
                builder: (_) => SessaoCartoesPage(
                  titulo: 'Cartões',
                  subtitulo: 'teste',
                  itens: itens,
                  novas: novas,
                  voz: v,
                  chaveDe: RevisaoCubit.chaveReversaDe,
                  previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
                  onNota: (f, n) => notas.add((f.cod, n)),
                  onFim: (r) => fim = r,
                  acaoExtra: extra,
                ),
              ));
            },
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return v;
    }

    testWidgets('a frente mostra só o inglês e fala sozinha; "Mostrar resposta" vira e mostra a tradução, o ao pé da letra e a nota', (tester) async {
      final voz = await abrir(tester, itens: const [_fl]);
      expect(find.byKey(const Key('frente-cartao')), findsOneWidget);
      expect(find.text('Nice to meet you.'), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsNothing, reason: 'o verso fica escondido');
      expect(find.byKey(const Key('nota-bom')), findsNothing);
      expect(find.text('REVISÃO'), findsOneWidget);
      expect(voz.falas, ['Nice to meet you.']);

      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      expect(find.text('Prazer em te conhecer.'), findsOneWidget);
      expect(find.textContaining('Agradável conhecer você.'), findsOneWidget);
      expect(find.textContaining('Fórmula ao ser apresentado.'), findsOneWidget);
      expect(find.byKey(const Key('mostrar-resposta')), findsNothing);
      expect(voz.falas.length, 1, reason: 'virar não fala de novo');
    });

    testWidgets('os 4 botões mostram o tempo até o cartão voltar', (tester) async {
      await abrir(tester);
      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      for (final (chave, rotulo, intervalo) in [
        ('nota-errei', '1 · Errei', '1 dia'),
        ('nota-dificil', '2 · Difícil', '2 dias'),
        ('nota-bom', '3 · Bom', '6 dias'),
        ('nota-facil', '4 · Fácil', '3 sem'),
      ]) {
        final b = find.byKey(Key(chave));
        expect(b, findsOneWidget, reason: chave);
        expect(find.descendant(of: b, matching: find.text(rotulo)), findsOneWidget);
        expect(find.descendant(of: b, matching: find.text(intervalo)), findsOneWidget);
      }
    });

    testWidgets('cartão novo ganha a etiqueta NOVO', (tester) async {
      await abrir(tester, novas: {RevisaoCubit.chaveReversaDe(f1)});
      expect(find.text('NOVO'), findsOneWidget);
      expect(find.text('REVISÃO'), findsNothing);
    });

    testWidgets('avaliar manda a 1ª nota, passa ao próximo (que fala) e, no fim, mostra o resumo e Continuar devolve true', (tester) async {
      final voz = await abrir(tester);
      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('nota-bom')));
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.good)]);
      expect(find.text('How are you?'), findsOneWidget, reason: 'o próximo cartão, já virado para a frente');
      expect(find.text('Como vai?'), findsNothing);
      expect(voz.falas, ['Nice to meet you.', 'How are you?']);

      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('nota-facil')));
      await tester.pumpAndSettle();
      expect(find.text('Pronto!'), findsOneWidget);
      expect(fim!.map((r) => (r.frase.cod, r.nota)), [('Nice to meet you.', Rating.good), ('How are you?', Rating.easy)]);
      await tester.tap(find.byKey(const Key('continuar-cartoes')));
      await tester.pumpAndSettle();
      expect(saiu, isTrue);
    });

    testWidgets('"Errei" volta o cartão mais tarde SEM contar de novo; "Ainda não" repete até 2 voltas', (tester) async {
      await abrir(tester);
      Future<void> avalia(String chave) async {
        await tester.tap(find.byKey(const Key('mostrar-resposta')));
        await tester.pump();
        await tester.tap(find.byKey(Key(chave)));
        await tester.pump();
      }

      await avalia('nota-errei'); // f1 errada → volta no fim
      expect(find.text('How are you?'), findsOneWidget);
      await avalia('nota-bom'); // f2
      expect(find.text('DE NOVO'), findsOneWidget);
      expect(find.text('Nice to meet you.'), findsOneWidget);
      // na repetição são 2 botões e não há previsão de intervalo
      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      expect(find.byKey(const Key('nota-dificil')), findsNothing);
      expect(find.byKey(const Key('nota-facil')), findsNothing);
      expect(find.text('1 · Ainda não'), findsOneWidget);
      await tester.tap(find.byKey(const Key('nota-errei')));
      await tester.pump();
      expect(find.text('DE NOVO'), findsOneWidget, reason: '2ª volta');
      await avalia('nota-errei'); // 3ª vez errada: o limite de voltas já foi
      await tester.pumpAndSettle();
      expect(find.text('Pronto!'), findsOneWidget);
      expect(notas, [('Nice to meet you.', Rating.again), ('How are you?', Rating.good)],
          reason: 'só a 1ª nota de cada frase vai para o agendador');
      expect(fim!.length, 2);
    });

    testWidgets('teclado: Espaço vira, 3 e Espaço avaliam "Bom", 1 "Errei", 2 e 4 não valem na repetição, R ouve', (tester) async {
      final voz = await abrir(tester, itens: const [f1, f2, f3]);
      await tester.sendKeyEvent(LogicalKeyboardKey.space); // vira
      await tester.pump();
      expect(find.text('Prazer em te conhecer.'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1); // errei
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      expect(voz.falas.last, 'How are you?');
      expect(voz.falas.length, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4); // ainda não virou: ignorado
      await tester.pump();
      expect(notas.length, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter); // vira
      await tester.sendKeyEvent(LogicalKeyboardKey.space); // bom
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space); // vira
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2); // difícil
      await tester.pump();
      expect(notas.map((n) => n.$2), [Rating.again, Rating.good, Rating.hard]);
      // agora é a repetição de f1: 2 e 4 não valem; 3 = lembrei
      expect(find.text('DE NOVO'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.pump();
      expect(find.text('DE NOVO'), findsOneWidget, reason: '2 e 4 ignorados na repetição');
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pumpAndSettle();
      expect(find.text('Pronto!'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(saiu, isTrue);
    });

    testWidgets('"áudio automático" desligado: não fala sozinho, mas o 🔊 fala', (tester) async {
      final voz = await abrir(tester, prefs: {'en_audio_auto': false});
      expect(voz.falas, isEmpty);
      await tester.tap(find.byKey(const Key('ouvir-cartao')));
      expect(voz.falas, ['Nice to meet you.']);
    });

    testWidgets('página sem gesto ainda (som não liberado): não fala sozinha', (tester) async {
      final voz = VozFake()..liberado = false;
      await abrir(tester, voz: voz);
      expect(voz.falas, isEmpty);
    });

    testWidgets('sem cartões: "Nada para revisar" e Continuar; a seta de voltar devolve false', (tester) async {
      await abrir(tester, itens: const []);
      expect(find.text('Nada para revisar agora 🎉'), findsOneWidget);
      await tester.tap(find.byKey(const Key('continuar-cartoes')));
      await tester.pumpAndSettle();
      expect(saiu, isTrue);

      await abrir(tester);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      expect(saiu, isFalse);
      expect(notas, isEmpty);
    });

    testWidgets('a ação extra (áudio do aluno) aparece ao lado do 🔊', (tester) async {
      await abrir(tester, extra: (context, f) => Text('EXTRA ${f.cod}'));
      expect(find.text('EXTRA Nice to meet you.'), findsOneWidget);
    });

    testWidgets('celular estreito: os 4 botões cabem em 2 colunas, sem estourar', (tester) async {
      await abrir(tester);
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      expect(tester.takeException(), isNull);
      final a = tester.getRect(find.byKey(const Key('nota-errei'))), b = tester.getRect(find.byKey(const Key('nota-bom')));
      expect(a.top, lessThan(b.top), reason: 'a 2ª linha começa no Bom');
      expect(tester.getRect(find.byKey(const Key('nota-facil'))).right, lessThanOrEqualTo(360));
    });

    // ------------------------------------------------------------------ responder escrevendo
    Future<void> escreve(WidgetTester tester, String texto) async {
      await tester.enterText(find.byKey(const Key('resposta-escrita')), texto);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }

    String plano(WidgetTester tester, String chave) => tester.widget<Text>(find.byKey(Key(chave))).textSpan!.toPlainText();

    List<TextSpan> palavras(WidgetTester tester, String chave) =>
        (tester.widget<Text>(find.byKey(Key(chave))).textSpan! as TextSpan).children!.cast<TextSpan>();

    bool sugerida(WidgetTester tester, String chave) =>
        find.descendant(of: find.byKey(Key(chave)), matching: find.textContaining('sugerida')).evaluate().isNotEmpty;

    testWidgets('por padrão pede a resposta ESCRITA: campo, Conferir e Não sei no lugar de "Mostrar resposta"', (tester) async {
      await abrir(tester, escrita: true);
      await tester.pump();
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
      expect(find.byKey(const Key('conferir-resposta')), findsOneWidget);
      expect(find.byKey(const Key('nao-sei-cartao')), findsOneWidget);
      expect(find.byKey(const Key('mostrar-resposta')), findsNothing);
      expect(tester.widget<Switch>(find.byKey(const Key('alternar-escrita'))).value, isTrue);
      expect(find.text('Leia o inglês e escreva a tradução em português'), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsNothing, reason: 'o verso fica escondido até conferir');
      expect(tester.widget<TextField>(find.byKey(const Key('resposta-escrita'))).focusNode!.hasFocus, isTrue,
          reason: 'o cursor já cai no campo');
    });

    testWidgets('resposta certa (sem maiúscula nem pontuação): "Idêntica!", sugere Bom e o Espaço aceita a sugestão', (tester) async {
      await abrir(tester, escrita: true);
      await tester.pump();
      await escreve(tester, 'prazer em te CONHECER');
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
      expect(find.byKey(const Key('sua-resposta')), findsOneWidget);
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
      expect(find.text('Idêntica! ✅ 4 de 4 palavras.'), findsOneWidget);
      expect(sugerida(tester, 'nota-bom'), isTrue);
      expect(sugerida(tester, 'nota-errei'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.good)]);
      expect(find.text('How are you?'), findsOneWidget, reason: 'o próximo cartão');
    });

    testWidgets('resposta parcial: conta as palavras, sugere Difícil e o Espaço registra Difícil', (tester) async {
      await abrir(tester, escrita: true);
      await tester.pump();
      await escreve(tester, 'prazer em conhecer');
      expect(find.text('Você acertou 3 de 4 palavras · sugestão: Difícil'), findsOneWidget);
      expect(sugerida(tester, 'nota-dificil'), isTrue);
      expect(sugerida(tester, 'nota-bom'), isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.hard)]);
    });

    testWidgets('resposta errada sugere Errei, mas a pessoa manda: a tecla 3 vale "Bom" (tradução livre)', (tester) async {
      await abrir(tester, escrita: true);
      await tester.pump();
      await escreve(tester, 'muito prazer em encontrar você');
      expect(find.textContaining('sugestão: Errei'), findsOneWidget);
      expect(sugerida(tester, 'nota-errei'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.good)]);
    });

    testWidgets('"Conferir" pelo botão; vazio e "Não sei" só mostram a resposta e sugerem Errei, sem comparação', (tester) async {
      await abrir(tester, escrita: true, itens: const [f1, f2, f3]);
      await tester.pump();
      await tester.enterText(find.byKey(const Key('resposta-escrita')), 'prazer em te conhecer');
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.byKey(const Key('sua-resposta')), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      await tester.tap(find.byKey(const Key('conferir-resposta'))); // vazio
      await tester.pump();
      expect(find.byKey(const Key('sua-resposta')), findsNothing);
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
      expect(sugerida(tester, 'nota-errei'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();

      await tester.tap(find.byKey(const Key('nao-sei-cartao')));
      await tester.pump();
      expect(find.byKey(const Key('sua-resposta')), findsNothing);
      expect(sugerida(tester, 'nota-errei'), isTrue);
      expect(notas.map((n) => n.$2), [Rating.good, Rating.again]);
    });

    testWidgets('escrevendo, as teclas são do campo: espaço, números e R não avaliam, não viram o cartão nem ouvem', (tester) async {
      final voz = await abrir(tester, escrita: true);
      await tester.pump();
      await tester.tap(find.byKey(const Key('resposta-escrita')));
      await tester.pump();
      final falasAntes = voz.falas.length;
      for (final k in [LogicalKeyboardKey.space, LogicalKeyboardKey.digit3, LogicalKeyboardKey.digit1, LogicalKeyboardKey.keyR]) {
        await tester.sendKeyEvent(k);
      }
      await tester.pump();
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget, reason: 'continua escrevendo');
      expect(notas, isEmpty);
      expect(voz.falas.length, falasAntes, reason: 'o R não é "ouvir" enquanto se escreve');
    });

    testWidgets('as palavras ficam marcadas: certas em verde, a sobra em vermelho, as que faltaram sublinhadas', (tester) async {
      await abrir(tester, escrita: true);
      await tester.pump();
      await escreve(tester, 'prazer te demais');
      final sua = palavras(tester, 'sua-resposta');
      Color? cor(List<TextSpan> l, String t) => l.firstWhere((s) => s.text == t).style?.color;
      expect(cor(sua, 'prazer'), const Color(0xFF4CD08A));
      expect(cor(sua, 'te'), const Color(0xFF4CD08A));
      expect(cor(sua, 'demais'), Mixart.danger, reason: 'palavra que não está na resposta');
      final verso = palavras(tester, 'verso-cartao');
      TextSpan palavra(String t) => verso.firstWhere((s) => s.text == t);
      expect(palavra('em').style!.decoration, TextDecoration.underline, reason: 'faltou');
      expect(palavra('conhecer').style!.decoration, TextDecoration.underline);
      expect(palavra('Prazer').style!.decoration, isNull);
      expect(plano(tester, 'verso-cartao'), 'Prazer em te conhecer.', reason: 'a pontuação e a grafia originais ficam');
    });

    testWidgets('o próximo cartão volta com o campo vazio e focado; a repetição do "Errei" também pede a escrita', (tester) async {
      await abrir(tester, escrita: true);
      await tester.pump();
      await escreve(tester, 'banana');
      await tester.sendKeyEvent(LogicalKeyboardKey.space); // aceita a sugestão: Errei
      await tester.pump();
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.again)]);
      expect(find.text('How are you?'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('resposta-escrita'))).controller!.text, isEmpty);
      expect(tester.widget<TextField>(find.byKey(const Key('resposta-escrita'))).focusNode!.hasFocus, isTrue);

      await escreve(tester, 'como vai');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.pump();
      // a repetição de f1
      expect(find.text('DE NOVO'), findsOneWidget);
      expect(find.text('Você errou: escreva de novo ou vire e confira'), findsOneWidget);
      await escreve(tester, 'prazer em te conhecer');
      expect(find.byKey(const Key('nota-dificil')), findsNothing, reason: 'na repetição são 2 botões');
      expect(sugerida(tester, 'nota-bom'), isTrue, reason: 'acertou: "Lembrei" vem sugerido');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Pronto!'), findsOneWidget);
      expect(notas.length, 2, reason: 'a repetição não conta de novo');
    });

    testWidgets('a chave "Responder escrevendo" desliga (volta o "Mostrar resposta"), religa e FICA SALVA', (tester) async {
      await abrir(tester, escrita: true);
      await tester.pump();
      await tester.tap(find.byKey(const Key('alternar-escrita')));
      await tester.pump();
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
      expect(find.byKey(const Key('mostrar-resposta')), findsOneWidget);
      expect(find.text('Leia o inglês e tente lembrar o sentido'), findsOneWidget);
      var p = await tester.runAsync(SharedPreferences.getInstance);
      expect(p!.getBool(SessaoCartoesPage.prefEscrita), isFalse);
      // sem escrita, o Espaço volta a virar e a avaliar "Bom"
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.byKey(const Key('nota-bom')), findsOneWidget);
      expect(sugerida(tester, 'nota-bom'), isFalse, reason: 'sem resposta escrita não há sugestão');

      await tester.tap(find.byKey(const Key('alternar-escrita')), warnIfMissed: false);
      await tester.pump();
      p = await tester.runAsync(SharedPreferences.getInstance);
      expect(p!.getBool(SessaoCartoesPage.prefEscrita), isTrue);
    });

    testWidgets('preferência salva desligada: abre direto no "Mostrar resposta"', (tester) async {
      await abrir(tester, escrita: false);
      await tester.pump();
      expect(find.byKey(const Key('mostrar-resposta')), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
      expect(tester.widget<Switch>(find.byKey(const Key('alternar-escrita'))).value, isFalse);
    });

    testWidgets('celular estreito no modo de escrita: sem estourar', (tester) async {
      await abrir(tester, escrita: true);
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      await escreve(tester, 'prazer em conhecer');
      final e = tester.takeException();
      expect(e, isNull, reason: '$e');
      expect(tester.getRect(find.byKey(const Key('nota-facil'))).right, lessThanOrEqualTo(360));
    });
  });

  group('BaralhosPage', () {
    Future<(RevisaoCubit, ConfigMemoria, RepoMemoria)> montar(
      WidgetTester tester, {
      Map<String, CartaoSrs> cartoes = const {},
      ConfigSrs config = ConfigSrs.padrao,
      List<EntradaHistorico> historico = const [],
    }) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = RepoMemoria(cartoes)..historico.addAll(historico);
      final cfg = ConfigMemoria(config);
      final revisao = RevisaoCubit(repo: repo, configRepo: cfg, agendador: fsrs);
      final curso = CursoBloc(loader: LoaderTeste(trilhasDeTeste()), progresso: LocalProgressoRepository(prefixo: 'en_'))
        ..add(const CursoIniciado());
      addTearDown(curso.close);
      addTearDown(revisao.close);
      await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [BlocProvider.value(value: curso), BlocProvider.value(value: revisao)],
          child: const BaralhosPage(),
        ),
      ));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
      return (revisao, cfg, repo);
    }

    String texto(WidgetTester tester, Key k) => tester.widget<Text>(find.byKey(k)).data ?? '';

    testWidgets('resumo do dia, os baralhos por grupo ("Meus textos" primeiro) e as contagens', (tester) async {
      await montar(tester, cartoes: {k(f1): fsrs.novo(hoje - 3), k(f2): fsrs.novo(hoje - 3), k(f3): fsrs.novo(hoje + 0)});
      expect(texto(tester, const Key('a-revisar-hoje')), '2');
      expect(find.text('cartões para revisar hoje'), findsOneWidget);
      expect(find.text('Baralhos'), findsOneWidget);
      // ordem dos grupos: Meus textos, A1, A2
      final y = {for (final g in ['MEUS TEXTOS', 'A1 · FUNDAÇÃO', 'A2 · DIA A DIA']) g: tester.getTopLeft(find.text(g)).dy};
      expect(y['MEUS TEXTOS'], lessThan(y['A1 · FUNDAÇÃO']!));
      expect(y['A1 · FUNDAÇÃO'], lessThan(y['A2 · DIA A DIA']!));
      expect(find.text('Primeiro contato'), findsOneWidget);
      expect(find.text('Minha viagem'), findsOneWidget);
      expect(find.byKey(const Key('devidas-tr:primeiro-contato')), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('devidas-tr:primeiro-contato')), matching: find.text('2 a revisar')), findsOneWidget);
      expect(find.byKey(const Key('devidas-txt:abc')), findsNothing);
      expect(find.text('2 de 2 frases aprendidas · 0 maduros'), findsOneWidget);
    });

    testWidgets('previsão de 14 dias e a retenção real', (tester) async {
      await montar(
        tester,
        cartoes: {
          k(f1): fsrs.novo(hoje - 3), // vence → hoje
          k(f2): CartaoSrs(estabilidade: 9, dificuldade: 5, ultimoDia: hoje, proximoDia: hoje + 5),
        },
        historico: [
          for (var i = 0; i < 4; i++) EntradaHistorico(hoje, 'x$i', 3),
          EntradaHistorico(hoje, 'x4', 1),
          EntradaHistorico(hoje - 1, 'n', 3, primeira: true),
        ],
      );
      expect(texto(tester, const Key('carga-0')), '1');
      expect(texto(tester, const Key('carga-5')), '1');
      expect(texto(tester, const Key('carga-3')), '');
      expect(find.text('Retenção real: 80%'), findsOneWidget, reason: '4 de 5 lembradas; a 1ª vez fica de fora');
      expect(texto(tester, const Key('atividade-13')), '5', reason: 'hoje: 5 revisões');
      expect(texto(tester, const Key('atividade-12')), '1', reason: 'ontem: uma revisão (a 1ª vez de um cartão conta como atividade)');
      expect(texto(tester, const Key('atividade-11')), '');
    }, skip: false);

    testWidgets('poucas revisões: não inventa uma retenção', (tester) async {
      await montar(tester, historico: [EntradaHistorico(hoje, 'a', 3)]);
      expect(find.text('Retenção real: ainda poucas revisões'), findsOneWidget);
    });

    testWidgets('o interruptor liga o inglês → português do baralho, guarda e mostra os novos do dia', (tester) async {
      final (revisao, cfg, _) = await montar(tester);
      expect(find.byKey(const Key('novos-hoje')), findsNothing);
      expect(tester.widget<FilledButton>(find.byKey(const Key('estudar-tudo'))).onPressed, isNull, reason: 'nada vence nem é novo');
      await tester.tap(find.byKey(const Key('inverter-tr:primeiro-contato')));
      await tester.pump();
      expect(revisao.state.config.reversoLigado('tr:primeiro-contato'), isTrue);
      expect(cfg.atual.reversos, {'tr:primeiro-contato'});
      expect(texto(tester, const Key('novos-hoje')), '+ 2 cartões novos de inglês → português na cota de hoje');
      expect(find.text('inglês → português ligado · 2 novos'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('estudar-tudo'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('inverter-tr:primeiro-contato')));
      await tester.pump();
      expect(revisao.state.config.reversos, isEmpty);
      expect(find.byKey(const Key('novos-hoje')), findsNothing);
    });

    testWidgets('a cota de novos por dia limita o que é anunciado', (tester) async {
      await montar(tester, config: const ConfigSrs(novosPorDia: 1, reversos: {'tr:primeiro-contato'}));
      expect(texto(tester, const Key('novos-hoje')), '+ 1 cartão novo de inglês → português na cota de hoje');
    });

    testWidgets('ligar/desligar o grupo inteiro de uma vez', (tester) async {
      final (revisao, _, _) = await montar(tester);
      await tester.tap(find.byKey(const Key('inverter-grupo-A2 · Dia a dia')));
      await tester.pump();
      expect(revisao.state.config.reversos, {'tr:dia-a-dia'});
      expect(find.text('Desligar inglês → português'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inverter-grupo-A2 · Dia a dia')));
      await tester.pump();
      expect(revisao.state.config.reversos, isEmpty);
    });

    testWidgets('ajustes: limite de revisões, novos por dia e retenção', (tester) async {
      final (revisao, cfg, _) = await montar(tester);
      await tester.tap(find.byKey(const Key('ajustes-baralhos')));
      await tester.pumpAndSettle();
      expect(find.text('Ajustes da revisão'), findsOneWidget);
      await tester.tap(find.byKey(const Key('limite-20')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('novos-5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('retencao-95%')));
      await tester.pump();
      expect(revisao.state.config.limiteRevisoes, 20);
      expect(revisao.state.config.novosPorDia, 5);
      expect(revisao.state.config.retencao, .95);
      expect(cfg.atual, revisao.state.config);
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('limite-20'))).selected, isTrue);
      expect(tester.widget<ChoiceChip>(find.byKey(const Key('limite-80'))).selected, isFalse);
    });

    testWidgets('mais cartões vencendo que o limite: avisa que o resto fica para amanhã', (tester) async {
      await montar(tester,
          cartoes: {k(f1): fsrs.novo(hoje - 3), k(f2): fsrs.novo(hoje - 3), k(f3): fsrs.novo(hoje - 3)},
          config: const ConfigSrs(limiteRevisoes: 2));
      expect(texto(tester, const Key('a-revisar-hoje')), '3');
      expect(find.textContaining('Vão ser 2 hoje'), findsOneWidget);
    });

    testWidgets('"Cartões" abre o navegador do baralho', (tester) async {
      await montar(tester);
      await tester.tap(find.byKey(const Key('cartoes-tr:primeiro-contato')));
      await tester.pumpAndSettle();
      expect(find.byType(NavegadorCartoesPage), findsOneWidget);
      expect(find.text('Nice to meet you.'), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsOneWidget);
    });

    testWidgets('conta sem curso carregado ou sem baralhos não quebra', (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final revisao = RevisaoCubit(repo: RepoMemoria(), agendador: fsrs);
      final curso = CursoBloc(loader: LoaderTeste(const []), progresso: LocalProgressoRepository(prefixo: 'en_'));
      addTearDown(curso.close);
      addTearDown(revisao.close);
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [BlocProvider.value(value: curso), BlocProvider.value(value: revisao)],
          child: const BaralhosPage(),
        ),
      ));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Ainda não há baralhos.'), findsOneWidget);
    });
  });

  group('NavegadorCartoesPage', () {
    Future<(RevisaoCubit, RepoMemoria, VozFake)> montar(WidgetTester tester, Map<String, CartaoSrs> cartoes,
        {ConfigSrs config = ConfigSrs.padrao}) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final repo = RepoMemoria(cartoes);
      final revisao = RevisaoCubit(repo: repo, configRepo: ConfigMemoria(config), agendador: fsrs);
      addTearDown(revisao.close);
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      final voz = VozFake();
      final baralho = IndiceBaralhos.de(trilhasDeTeste()).baralho('tr:dia-a-dia')!;
      await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(value: revisao, child: NavegadorCartoesPage(baralho: baralho, voz: voz)),
      ));
      await tester.pump();
      return (revisao, repo, voz);
    }

    testWidgets('lista as frases do baralho com a situação dos dois sentidos', (tester) async {
      await montar(
        tester,
        {
          k(f3): fsrs.novo(hoje - 1), // digitar: vence hoje
          RevisaoCubit.chaveReversaDe(f3): CartaoSrs(estabilidade: 30, dificuldade: 5, ultimoDia: hoje, proximoDia: hoje + 30, revisoes: 4),
        },
        config: const ConfigSrs(reversos: {'tr:dia-a-dia'}),
      );
      expect(find.text('3 de 3 cartões'), findsOneWidget);
      expect(find.text('I was tired.'), findsOneWidget);
      expect(find.text('Eu estava cansado.'), findsOneWidget);
      expect(find.textContaining('digitar · vence hoje'), findsOneWidget);
      expect(find.textContaining('virar · em 4 sem · memória 30 d'), findsOneWidget);
      expect(find.textContaining('digitar · ainda não'), findsNWidgets(2), reason: 'f2 e f4 ainda não são cartão');
      expect(find.textContaining('virar · novo'), findsNWidgets(2), reason: 'o sentido está ligado: ainda novos');
    });

    testWidgets('sem o sentido invertido ligado e sem cartão, só aparece o "digitar"', (tester) async {
      await montar(tester, {});
      expect(find.textContaining('virar ·'), findsNothing);
    });

    testWidgets('a busca filtra pelo inglês e pela tradução', (tester) async {
      await montar(tester, {});
      await tester.enterText(find.byKey(const Key('busca-cartoes')), 'tomorrow');
      await tester.pump();
      expect(find.text('See you tomorrow.'), findsOneWidget);
      expect(find.text('I was tired.'), findsNothing);
      expect(find.text('1 de 3 cartões'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('busca-cartoes')), 'COMO VAI');
      await tester.pump();
      expect(find.text('How are you?'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('busca-cartoes')), 'zzz');
      await tester.pump();
      expect(find.text('Nenhum cartão encontrado.'), findsOneWidget);
    });

    testWidgets('suspender, reativar e enterrar pelo menu do cartão', (tester) async {
      final (revisao, repo, _) = await montar(tester, {k(f3): fsrs.novo(hoje - 1)});
      Future<void> menu(String item) async {
        await tester.tap(find.byKey(const ValueKey('menu-I was tired.')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(item));
        await tester.pumpAndSettle();
      }

      await menu('⏸ Suspender (digitar)');
      expect(revisao.state.cartoes[k(f3)]!.suspenso, isTrue);
      expect(repo.cartoes[k(f3)]!.suspenso, isTrue);
      expect(find.textContaining('digitar · suspenso'), findsOneWidget);
      expect(revisao.devidas(), isEmpty);

      await menu('▶️ Reativar (digitar)');
      expect(revisao.state.cartoes[k(f3)]!.suspenso, isFalse);
      expect(find.textContaining('digitar · vence hoje'), findsOneWidget);

      await menu('🌙 Enterrar até amanhã (digitar)');
      expect(find.textContaining('digitar · enterrado até amanhã'), findsOneWidget);
      expect(revisao.devidas(), isEmpty);
    });

    testWidgets('ouvir toca a frase; frase sem cartão não oferece suspender', (tester) async {
      final (_, _, voz) = await montar(tester, {});
      await tester.tap(find.byKey(const ValueKey('menu-I was tired.')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Suspender'), findsNothing);
      await tester.tap(find.text('🔊 Ouvir'));
      await tester.pumpAndSettle();
      expect(voz.falas, ['I was tired.']);
    });
  });
}
