import 'dart:math';

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
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/presentation/baralhos_page.dart';
import 'package:pac_dart/features/ingles/presentation/navegador_cartoes_page.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_baralhos_test.dart' show ConfigMemoria, RepoMemoria, f1, f2, f3, f4, trilhasDeTeste;

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
        NivelResposta nivel = NivelResposta.livre,
        SentidoCartao sentido = SentidoCartao.enPt,
        Random? aleatorio,
        List<Trecho> apoio = const [],
        Map<String, Object> prefs = const {},
        Map<String, Object>? prefsExatas}) async {
      // por padrão: inglês na frente e "só virar" (o app abre no Avançado e misturando os lados)
      SharedPreferences.setMockInitialValues(prefsExatas ??
          {
            SessaoCartoesPage.prefNivel: nivel.id,
            SessaoCartoesPage.prefSentido: sentido.id,
            ...prefs,
          });
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
                  apoio: apoio,
                  aleatorio: aleatorio ?? Random(7),
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

    String plano(WidgetTester tester, String chave) {
      final t = tester.widget<Text>(find.byKey(Key(chave)));
      return t.data ?? t.textSpan!.toPlainText();
    }

    List<TextSpan> palavras(WidgetTester tester, String chave) =>
        (tester.widget<Text>(find.byKey(Key(chave))).textSpan! as TextSpan).children!.cast<TextSpan>();

    bool sugerida(WidgetTester tester, String chave) =>
        find.descendant(of: find.byKey(Key(chave)), matching: find.textContaining('sugerida')).evaluate().isNotEmpty;

    testWidgets('no Avançado pede a resposta ESCRITA: campo, Conferir e Não sei no lugar de "Mostrar resposta"', (tester) async {
      await abrir(tester, nivel: NivelResposta.avancado);
      await tester.pump();
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
      expect(find.byKey(const Key('conferir-resposta')), findsOneWidget);
      expect(find.byKey(const Key('nao-sei-cartao')), findsOneWidget);
      expect(find.byKey(const Key('mostrar-resposta')), findsNothing);
      expect(find.text('Leia o inglês e escreva em português'), findsOneWidget);
      expect(find.text('Prazer em te conhecer.'), findsNothing, reason: 'o verso fica escondido até conferir');
      expect(tester.widget<TextField>(find.byKey(const Key('resposta-escrita'))).focusNode!.hasFocus, isTrue,
          reason: 'o cursor já cai no campo');
    });

    testWidgets('resposta certa (sem maiúscula nem pontuação): "Idêntica!", sugere Bom e o Espaço aceita a sugestão', (tester) async {
      await abrir(tester, nivel: NivelResposta.avancado);
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
      await abrir(tester, nivel: NivelResposta.avancado);
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
      await abrir(tester, nivel: NivelResposta.avancado);
      await tester.pump();
      await escreve(tester, 'muito prazer em encontrar você');
      expect(find.textContaining('sugestão: Errei'), findsOneWidget);
      expect(sugerida(tester, 'nota-errei'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.pump();
      expect(notas, [('Nice to meet you.', Rating.good)]);
    });

    testWidgets('"Conferir" pelo botão; vazio e "Não sei" só mostram a resposta e sugerem Errei, sem comparação', (tester) async {
      await abrir(tester, nivel: NivelResposta.avancado, itens: const [f1, f2, f3]);
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
      final voz = await abrir(tester, nivel: NivelResposta.avancado);
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
      await abrir(tester, nivel: NivelResposta.avancado);
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
      await abrir(tester, nivel: NivelResposta.avancado);
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
      expect(find.text('Você errou: leia o inglês e escreva em português'), findsOneWidget);
      await escreve(tester, 'prazer em te conhecer');
      expect(find.byKey(const Key('nota-dificil')), findsNothing, reason: 'na repetição são 2 botões');
      expect(sugerida(tester, 'nota-bom'), isTrue, reason: 'acertou: "Lembrei" vem sugerido');
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(find.text('Pronto!'), findsOneWidget);
      expect(notas.length, 2, reason: 'a repetição não conta de novo');
    });

    testWidgets('o seletor de nível troca o cartão na hora (Só virar ↔ Avançado) e FICA SALVO', (tester) async {
      await abrir(tester, nivel: NivelResposta.avancado);
      await tester.pump();
      await tester.tap(find.byKey(const Key('nivel-livre')));
      await tester.pump();
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
      expect(find.byKey(const Key('mostrar-resposta')), findsOneWidget);
      expect(find.text('Leia o inglês e tente lembrar o português'), findsOneWidget);
      var p = await tester.runAsync(SharedPreferences.getInstance);
      expect(p!.getString(SessaoCartoesPage.prefNivel), 'livre');
      // sem escrita, o Espaço volta a virar e a avaliar "Bom"
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.byKey(const Key('nota-bom')), findsOneWidget);
      expect(sugerida(tester, 'nota-bom'), isFalse, reason: 'sem resposta não há sugestão');

      await tester.tap(find.byKey(const Key('nivel-avancado')), warnIfMissed: false);
      await tester.pump();
      p = await tester.runAsync(SharedPreferences.getInstance);
      expect(p!.getString(SessaoCartoesPage.prefNivel), 'avancado');
    });

    testWidgets('nível salvo como Só virar abre direto no "Mostrar resposta"', (tester) async {
      await abrir(tester, nivel: NivelResposta.livre);
      await tester.pump();
      expect(find.byKey(const Key('mostrar-resposta')), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
    });

    testWidgets('preferência de antes dos níveis (escrever = não) vira Só virar; sem nada salvo abre no Avançado', (tester) async {
      await abrir(tester, prefsExatas: {SessaoCartoesPage.prefSentido: 'en-pt', SessaoCartoesPage.prefEscrita: false});
      expect(find.byKey(const Key('mostrar-resposta')), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await tester.pumpAndSettle();
      await abrir(tester, prefsExatas: {SessaoCartoesPage.prefSentido: 'en-pt'});
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
    });

    // ------------------------------------------------------------------ níveis (Fácil e Médio) e sentidos
    const longa = Trecho(cod: 'I like coffee very much.', dica: 'Eu gosto muito de café.', out: '');
    const contracao = Trecho(cod: "I don't know.", dica: 'Eu não sei.', out: '');

    /// Os blocos do banco do nível Fácil: posição → palavra.
    Map<int, String> banco(WidgetTester tester) {
      final r = <int, String>{};
      for (var i = 0; i < 40; i++) {
        final f = find.byKey(Key('bloco-$i'));
        if (f.evaluate().isEmpty) continue;
        r[i] = tester.widget<Text>(find.descendant(of: f, matching: find.byType(Text))).data!;
      }
      return r;
    }

    /// Toca nos blocos [palavras], nessa ordem (cada bloco só uma vez).
    Future<void> montar(WidgetTester tester, List<String> palavras) async {
      final usados = <int>{};
      for (final p in palavras) {
        final id = banco(tester).entries.firstWhere((e) => e.value == p && !usados.contains(e.key)).key;
        usados.add(id);
        await tester.tap(find.byKey(Key('bloco-$id')));
        await tester.pump();
      }
    }

    int montados(WidgetTester tester) =>
        find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('escolhido-')).evaluate().length;

    Finder lacunasDaTela() =>
        find.byWidgetPredicate((w) => w is TextField && w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('lacuna-'));

    /// As palavras à vista da frase do Médio (o resto são as lacunas).
    List<String> aVista(WidgetTester tester) => [
          for (final t in find.descendant(of: find.byKey(const Key('lacunas')), matching: find.byType(Text)).evaluate())
            (t.widget as Text).data!,
        ];

    testWidgets('Fácil: monta a frase com blocos; os de enfeite vêm das outras frases e NÃO fazem parte da resposta', (tester) async {
      await abrir(tester, nivel: NivelResposta.facil, itens: const [f1, f2]);
      await tester.pump();
      expect(find.byKey(const Key('montagem')), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
      expect(find.byKey(const Key('mostrar-resposta')), findsNothing);
      expect(find.text('Monte a frase em português com os blocos'), findsOneWidget);
      expect(find.text('Nice to meet you.'), findsOneWidget, reason: 'a frente continua sendo o inglês');
      expect(find.text('Prazer em te conhecer.'), findsNothing, reason: 'a resposta fica escondida');

      final blocos = banco(tester).values.toList();
      const certas = ['Prazer', 'em', 'te', 'conhecer'];
      expect(blocos.length, certas.length + quantosDistratores(4));
      final enfeites = [...blocos];
      for (final c in certas) {
        enfeites.remove(c);
      }
      expect(enfeites..sort(), ['Como', 'vai'], reason: 'o único apoio é a outra frase da sessão, em português');

      expect(tester.widget<FilledButton>(find.byKey(const Key('conferir-resposta'))).onPressed, isNull, reason: 'nada montado: não confere');
      await montar(tester, certas);
      expect(montados(tester), 4);
      expect(tester.widget<FilledButton>(find.byKey(const Key('conferir-resposta'))).onPressed, isNotNull);
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.text('Frase montada certinha! ✅'), findsOneWidget);
      expect(plano(tester, 'sua-resposta'), 'Prazer em te conhecer');
      expect(plano(tester, 'verso-cartao'), 'Prazer em te conhecer.');
      expect(sugerida(tester, 'nota-bom'), isTrue);
      expect(find.byKey(const Key('montagem')), findsNothing);
    });

    testWidgets('Fácil: tocar num bloco da frase o devolve ao banco; Backspace tira o último; Enter confere', (tester) async {
      await abrir(tester, nivel: NivelResposta.facil, itens: const [f1, f2]);
      await tester.pump();
      await montar(tester, ['em', 'te']);
      expect(montados(tester), 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(montados(tester), 1, reason: 'Backspace tirou o "te"');
      final idEm = banco(tester).entries.firstWhere((e) => e.value == 'em').key;
      await tester.tap(find.byKey(Key('escolhido-$idEm')));
      await tester.pump();
      expect(montados(tester), 0);
      expect(find.text('Toque nos blocos abaixo para montar a frase'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const Key('nota-bom')), findsNothing, reason: 'Enter sem nada montado não vira');
      // o bloco devolvido pode ser pego de novo; o Espaço não vira (só os níveis sem resposta usam o Espaço)
      await montar(tester, ['em']);
      expect(montados(tester), 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(find.byKey(const Key('nota-bom')), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(find.byKey(const Key('nota-bom')), findsOneWidget, reason: 'Enter conferiu');
    });

    testWidgets('Fácil: palavras certas em outra ordem → "outra ordem" e sugere Difícil; faltando palavra → Errei', (tester) async {
      await abrir(tester, nivel: NivelResposta.facil, itens: const [f1, f2]);
      await tester.pump();
      await montar(tester, ['em', 'Prazer', 'te', 'conhecer']);
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.text('Todas as palavras, mas em outra ordem · sugestão: Difícil'), findsOneWidget);
      expect(sugerida(tester, 'nota-dificil'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pump();
      await tester.pump();
      // 2º cartão: um bloco certo e um de enfeite
      expect(find.text('How are you?'), findsOneWidget);
      await montar(tester, ['Como', 'Eu'].where((p) => banco(tester).containsValue(p)).toList());
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(sugerida(tester, 'nota-errei'), isTrue);
      expect(find.textContaining('· sugestão: Errei'), findsOneWidget);
    });

    testWidgets('Fácil: sem outras frases na sessão, os enfeites vêm do apoio do curso (e só depois da reserva)', (tester) async {
      await abrir(tester, nivel: NivelResposta.facil, itens: const [f1], apoio: const [f2, f3, f4]);
      await tester.pump();
      const doApoio = {'Como', 'vai', 'Eu', 'estava', 'cansado', 'Até', 'amanhã'};
      final enfeites = banco(tester).values.where((w) => !['Prazer', 'em', 'te', 'conhecer'].contains(w)).toList();
      expect(enfeites.length, 2);
      expect(enfeites.every(doApoio.contains), isTrue, reason: '$enfeites');
    });

    testWidgets('Fácil: "Não sei" mostra a resposta e sugere Errei', (tester) async {
      await abrir(tester, nivel: NivelResposta.facil, itens: const [f1]);
      await tester.pump();
      await tester.tap(find.byKey(const Key('nao-sei-cartao')));
      await tester.pump();
      expect(find.text('Prazer em te conhecer.'), findsOneWidget);
      expect(find.byKey(const Key('sua-resposta')), findsNothing);
      expect(sugerida(tester, 'nota-errei'), isTrue);
    });

    testWidgets('Médio: palavras à vista + um campo para cada lacuna; preencher tudo certo sugere Bom', (tester) async {
      await abrir(tester, nivel: NivelResposta.medio, itens: const [f1]);
      await tester.pump();
      expect(find.text('Complete a frase em português'), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
      expect(lacunasDaTela(), findsNWidgets(quantasEscondidas(4)));
      final visiveis = aVista(tester);
      expect(visiveis.length, 4 - quantasEscondidas(4) + 1, reason: 'as palavras à vista + o ponto final');
      expect(find.text('Prazer em te conhecer.'), findsNothing);
      const frase = ['Prazer', 'em', 'te', 'conhecer'];
      final faltam = frase.where((p) => !visiveis.any((v) => v.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '') == p)).toList();
      expect(faltam.length, quantasEscondidas(4));
      for (var n = 0; n < faltam.length; n++) {
        await tester.enterText(find.byKey(Key('lacuna-$n')), faltam[n]);
      }
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.text('Todas as lacunas certas! ✅'), findsOneWidget);
      expect(plano(tester, 'sua-resposta'), 'Prazer em te conhecer.');
      expect(sugerida(tester, 'nota-bom'), isTrue);
    });

    testWidgets('Médio: 2 de 3 lacunas certas sugere Difícil e conta "lacunas"; espaço pula para a próxima lacuna', (tester) async {
      await abrir(tester, nivel: NivelResposta.medio, itens: const [longa], sentido: SentidoCartao.ptEn);
      await tester.pump();
      expect(lacunasDaTela(), findsNWidgets(3));
      final ocultas = ['I', 'like', 'coffee', 'very', 'much'].where((p) => !aVista(tester).any((v) => v.replaceAll(RegExp(r'[^\p{L}]', unicode: true), '') == p)).toList();
      expect(ocultas.length, 3);
      // espaço no fim do que digitou = "terminei": a palavra fica sem o espaço e o cursor vai para a próxima
      await tester.enterText(find.byKey(const Key('lacuna-0')), '${ocultas[0]} ');
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const Key('lacuna-0'))).controller!.text, ocultas[0]);
      expect(tester.widget<TextField>(find.byKey(const Key('lacuna-1'))).focusNode!.hasFocus, isTrue);
      await tester.enterText(find.byKey(const Key('lacuna-1')), ocultas[1]);
      await tester.enterText(find.byKey(const Key('lacuna-2')), 'banana');
      await tester.testTextInput.receiveAction(TextInputAction.done); // Enter na última lacuna confere
      await tester.pump();
      expect(find.text('Você acertou 2 de 3 lacunas · sugestão: Difícil'), findsOneWidget);
      expect(sugerida(tester, 'nota-dificil'), isTrue);
    });

    testWidgets('Médio: Conferir sem escrever nada vira a resposta e sugere Errei', (tester) async {
      await abrir(tester, nivel: NivelResposta.medio, itens: const [f1]);
      await tester.pump();
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.text('Prazer em te conhecer.'), findsOneWidget);
      expect(sugerida(tester, 'nota-errei'), isTrue);
    });

    testWidgets('português → inglês: a frente é o português, o inglês só aparece (e fala) depois de conferir; R não entrega antes', (tester) async {
      final voz = await abrir(tester, nivel: NivelResposta.avancado, sentido: SentidoCartao.ptEn, itens: const [f1]);
      await tester.pump();
      expect(find.text('PORTUGUÊS'), findsOneWidget);
      expect(plano(tester, 'frente-cartao'), 'Prazer em te conhecer.');
      expect(find.text('Nice to meet you.'), findsNothing);
      expect(find.text('Leia o português e escreva em inglês'), findsOneWidget);
      expect(find.text('Escreva aqui a frase em inglês…'), findsOneWidget);
      expect(find.byKey(const Key('ouvir-cartao')), findsNothing, reason: 'o áudio é em inglês: entregaria a resposta');
      expect(voz.falas, isEmpty, reason: 'não fala sozinho antes de responder');
      // R com o campo sem foco de texto não pode tocar o inglês antes da hora
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      expect(voz.falas, isEmpty);

      await escreve(tester, 'nice to MEET you');
      expect(find.text('Idêntica! ✅ 4 de 4 palavras.'), findsOneWidget);
      expect(find.text('INGLÊS'), findsOneWidget);
      expect(plano(tester, 'verso-cartao'), 'Nice to meet you.');
      expect(find.byKey(const Key('ouvir-cartao')), findsOneWidget);
      expect(voz.falas, ['Nice to meet you.'], reason: 'fala o inglês quando a resposta aparece');
    });

    testWidgets('português → inglês no Só virar: a tecla R não toca o inglês antes de virar (entregaria a resposta); depois toca', (tester) async {
      final voz = await abrir(tester, nivel: NivelResposta.livre, sentido: SentidoCartao.ptEn, itens: const [f1]);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(voz.falas, isEmpty);
      await tester.sendKeyEvent(LogicalKeyboardKey.space); // vira
      await tester.pump();
      expect(voz.falas, ['Nice to meet you.'], reason: 'ao virar, fala o inglês sozinho');
      await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
      await tester.pump();
      expect(voz.falas, ['Nice to meet you.', 'Nice to meet you.']);
    });

    testWidgets('português → inglês: don\'t e dont, I\'m e I’m são a mesma palavra', (tester) async {
      await abrir(tester, nivel: NivelResposta.avancado, sentido: SentidoCartao.ptEn, itens: const [contracao]);
      await tester.pump();
      await escreve(tester, 'i dont know');
      expect(find.text('Idêntica! ✅ 3 de 3 palavras.'), findsOneWidget);
    });

    testWidgets('português → inglês no Fácil: blocos em inglês, enfeites em inglês (reserva do idioma)', (tester) async {
      await abrir(tester, nivel: NivelResposta.facil, sentido: SentidoCartao.ptEn, itens: const [f1]);
      await tester.pump();
      expect(find.text('Monte a frase em inglês com os blocos'), findsOneWidget);
      final blocos = banco(tester).values.toList();
      const certas = ['Nice', 'to', 'meet', 'you'];
      final enfeites = [...blocos];
      for (final c in certas) {
        enfeites.remove(c);
      }
      expect(enfeites.length, 2);
      expect(enfeites.every(palavrasDeReservaEn.contains), isTrue, reason: '$enfeites');
      await montar(tester, certas);
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.text('Frase montada certinha! ✅'), findsOneWidget);
      expect(plano(tester, 'verso-cartao'), 'Nice to meet you.');
    });

    testWidgets('o seletor de sentido muda a frente do cartão na hora, fica salvo e, depois de virar, só vale para o próximo', (tester) async {
      final voz = await abrir(tester, itens: const [f1, f2]);
      await tester.pump();
      expect(find.text('INGLÊS'), findsOneWidget);
      expect(plano(tester, 'frente-cartao'), 'Nice to meet you.');
      expect(voz.falas, ['Nice to meet you.']);
      await tester.tap(find.byKey(const Key('sentido-pt-en')));
      await tester.pump();
      expect(find.text('PORTUGUÊS'), findsOneWidget);
      expect(plano(tester, 'frente-cartao'), 'Prazer em te conhecer.');
      expect(find.byKey(const Key('ouvir-cartao')), findsNothing);
      final p = await tester.runAsync(SharedPreferences.getInstance);
      expect(p!.getString(SessaoCartoesPage.prefSentido), 'pt-en');

      await tester.tap(find.byKey(const Key('mostrar-resposta')));
      await tester.pump();
      expect(plano(tester, 'verso-cartao'), 'Nice to meet you.');
      await tester.tap(find.byKey(const Key('sentido-en-pt')));
      await tester.pump();
      expect(plano(tester, 'verso-cartao'), 'Nice to meet you.', reason: 'o cartão virado não troca de lado no meio da avaliação');
      expect(plano(tester, 'frente-cartao'), 'Prazer em te conhecer.');
      await tester.tap(find.byKey(const Key('nota-bom')));
      await tester.pump();
      await tester.pump();
      expect(plano(tester, 'frente-cartao'), 'How are you?', reason: 'o próximo já vem inglês → português');
    });

    testWidgets('trocar o nível no meio do cartão refaz a resposta (descarta o que estava escrito)', (tester) async {
      await abrir(tester, nivel: NivelResposta.avancado, itens: const [f1, f2]);
      await tester.pump();
      await tester.enterText(find.byKey(const Key('resposta-escrita')), 'prazer');
      await tester.tap(find.byKey(const Key('nivel-facil')));
      await tester.pump();
      expect(find.byKey(const Key('montagem')), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsNothing);
      await tester.tap(find.byKey(const Key('nivel-medio')));
      await tester.pump();
      expect(lacunasDaTela(), findsNWidgets(quantasEscondidas(4)));
      await tester.tap(find.byKey(const Key('nivel-avancado')));
      await tester.pump();
      expect(tester.widget<TextField>(find.byKey(const Key('resposta-escrita'))).controller!.text, isEmpty);
      final p = await tester.runAsync(SharedPreferences.getInstance);
      expect(p!.getString(SessaoCartoesPage.prefNivel), 'avancado');
    });

    testWidgets('misturado: os lados se alternam entre os cartões; o "Errei" volta do mesmo lado', (tester) async {
      final itens = [for (var i = 1; i <= 14; i++) Trecho(cod: 'Phrase number $i', dica: 'Frase numero $i', out: '')];
      await abrir(tester, itens: itens, sentido: SentidoCartao.misto);
      await tester.pump();
      final lados = <bool>[]; // true = português na frente
      var errou = false;
      for (var c = 0; c < 14; c++) {
        final ptEn = plano(tester, 'frente-cartao').startsWith('Frase');
        lados.add(ptEn);
        await tester.tap(find.byKey(const Key('mostrar-resposta')));
        await tester.pump();
        if (c == 0) {
          errou = true;
          await tester.tap(find.byKey(const Key('nota-errei')));
        } else {
          await tester.tap(find.byKey(const Key('nota-bom')));
        }
        await tester.pump();
        await tester.pump();
        if (find.text('DE NOVO').evaluate().isNotEmpty) {
          expect(plano(tester, 'frente-cartao').startsWith('Frase'), ptEn,
              reason: 'o cartão que volta depois do Errei mantém o lado');
        }
      }
      expect(errou, isTrue);
      expect(lados.contains(true), isTrue, reason: '$lados');
      expect(lados.contains(false), isTrue, reason: '$lados');
    });

    testWidgets('nível e sentido salvos: abre direto no Médio em português → inglês', (tester) async {
      await abrir(tester, nivel: NivelResposta.medio, sentido: SentidoCartao.ptEn, itens: const [f1]);
      await tester.pump();
      expect(find.text('Complete a frase em inglês'), findsOneWidget);
      expect(find.text('PORTUGUÊS'), findsOneWidget);
      expect(find.byKey(const Key('lacunas')), findsOneWidget);
    });

    testWidgets('celular estreito no Fácil e no Médio: sem estourar', (tester) async {
      for (final n in [NivelResposta.facil, NivelResposta.medio]) {
        await abrir(tester, nivel: n, itens: const [longa], sentido: SentidoCartao.ptEn);
        tester.view.physicalSize = const Size(360, 800);
        await tester.pump();
        final e = tester.takeException();
        expect(e, isNull, reason: '$n: $e');
        expect(tester.getRect(find.byKey(const Key('conferir-resposta'))).right, lessThanOrEqualTo(360));
        await tester.tap(find.byTooltip('Voltar'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('celular estreito no modo de escrita: sem estourar', (tester) async {
      await abrir(tester, nivel: NivelResposta.avancado);
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
