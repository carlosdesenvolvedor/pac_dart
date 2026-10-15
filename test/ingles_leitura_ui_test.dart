import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/ingles/data/textos_repository.dart';
import 'package:pac_dart/features/ingles/data/tradutor.dart';
import 'package:pac_dart/features/ingles/data/voz_ingles.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/domain/leitura.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';
import 'package:pac_dart/features/ingles/presentation/leitura_page.dart';
import 'package:pac_dart/features/ingles/presentation/leituras_page.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/sessao_cartoes_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_baralhos_test.dart' show ConfigMemoria, RepoMemoria;
import 'ingles_cartoes_ui_test.dart' show LoaderTeste;

class _Tradutor implements Tradutor {
  final chamadas = <String>[];
  Object? erro;
  Completer<void>? segura;
  final Map<String, String> tabela = const {'sister': 'irmã', 'breakfast': 'café da manhã'};
  _Tradutor();

  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir}) async {
    chamadas.addAll(frases);
    await segura?.future;
    if (erro != null) throw erro!;
    return [for (final f in frases) tabela[f] ?? 'tradução de $f'];
  }
}

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

const _leitura = Leitura(id: 'manha', titulo: 'Minha manhã', etapa: 'A1', frases: [
  FraseDoTexto('Then I have breakfast with my sister.', 'Depois tomo café da manhã com minha irmã.'),
  FraseDoTexto('The bus is always full.', 'O ônibus está sempre cheio.'),
  FraseDoTexto('Sem tradução aqui.', ''),
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() => SharedPreferences.setMockInitialValues({}));

  late CursoBloc curso;
  late RevisaoCubit revisao;
  late _Tradutor tradutor;
  late _Voz voz;

  Future<void> montar(WidgetTester tester, Widget Function() tela, {Size tamanho = const Size(1000, 1800), List<Trilha>? trilhas}) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tradutor = _Tradutor();
    voz = _Voz();
    revisao = RevisaoCubit(repo: RepoMemoria(), configRepo: ConfigMemoria(), agendador: AgendadorFsrs(fuzz: false));
    curso = CursoBloc(
      loader: LoaderTeste(trilhas ?? [const Trilha(nivel: 'Curso', emoji: '1', etapa: 'A1 · Fundação', licoes: [Licao(id: 'c.a', nome: 'A', emoji: '1', trechos: [Trecho(cod: 'Hello.', dica: 'Olá.', out: '')])])]),
      progresso: LocalProgressoRepository(prefixo: 'en_'),
      textos: LocalTextosRepository('u1'),
    )..add(const CursoIniciado());
    addTearDown(curso.close);
    addTearDown(revisao.close);
    await tester.runAsync(() => curso.stream.firstWhere((s) => s.status == CursoStatus.pronto));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      home: MultiBlocProvider(
        providers: [BlocProvider.value(value: curso), BlocProvider.value(value: revisao)],
        child: tela(),
      ),
    ));
    await tester.pump();
  }

  Future<void> anda(WidgetTester tester, [int n = 6]) async {
    for (var i = 0; i < n; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 40));
    }
  }

  Widget leitura() => LeituraPage(leitura: _leitura, tradutor: tradutor, voz: voz);

  Future<void> toca(WidgetTester tester, String palavra, {int indice = 0}) async {
    await tester.tap(find.byKey(Key('palavra-$palavra')).at(indice));
    await anda(tester);
  }

  /// Os cartões em "Meus cartões" (cod → (pt, alvo, alvoPt)).
  Map<String, (String, String, String)> cartoes() => {
        for (final t in curso.state.trilhas.where((t) => t.textoId == idCartoesAvulsos))
          for (final l in t.licoes)
            for (final x in l.trechos) x.cod: (x.dicaPlana, x.alvo, x.alvoPt),
      };

  group('a leitura', () {
    testWidgets('mostra cada frase com as palavras tocáveis e a dica de uso', (tester) async {
      await montar(tester, leitura);
      expect(find.text('Minha manhã'), findsOneWidget);
      expect(find.byKey(const Key('dica-leitura')), findsOneWidget);
      expect(find.byKey(const Key('frase-leitura')), findsNWidgets(3));
      expect(find.byKey(const Key('palavra-breakfast')), findsOneWidget);
      expect(find.byKey(const Key('palavra-bus')), findsOneWidget);
    });

    testWidgets('a mesma palavra duas vezes na frase não dá chave repetida; as duas tocam e destacam as duas', (tester) async {
      await montar(tester, () => LeituraPage(
            leitura: const Leitura(id: 'x', titulo: 'X', etapa: 'A1', frases: [FraseDoTexto('Go home, go now.', 'Vá para casa, vá agora.')]),
            tradutor: tradutor,
            voz: voz,
          ));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('palavra-go')), findsOneWidget);
      expect(find.byKey(const Key('palavra-go#2')), findsOneWidget);
      await tester.tap(find.byKey(const Key('palavra-go#2')));
      await anda(tester);
      final partes = (tester.widget<Text>(find.byKey(const Key('frase-da-folha'))).textSpan! as TextSpan).children!.cast<TextSpan>();
      expect(partes.where((p) => p.style?.fontWeight == FontWeight.w800).map((p) => p.text).toList(), ['Go', 'go']);
    });

    testWidgets('tocar numa palavra abre a folha com a palavra, a FRASE INTEIRA (palavra destacada) e a tradução da frase', (tester) async {
      await montar(tester, leitura);
      await toca(tester, 'breakfast');
      expect(find.byKey(const Key('folha-palavra')), findsOneWidget);
      expect(find.byKey(const Key('palavra-tocada')), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('palavra-tocada'))).data, 'breakfast');
      expect(tester.widget<Text>(find.byKey(const Key('frase-da-folha'))).textSpan!.toPlainText(), 'Then I have breakfast with my sister.');
      expect(find.text('Depois tomo café da manhã com minha irmã.'), findsOneWidget);
      expect(find.byKey(const Key('aviso-sentido')), findsOneWidget);
      expect(find.textContaining('mudar de sentido'), findsOneWidget);
      // a palavra da frase fica em destaque (cor e fundo diferentes das outras)
      final partes = (tester.widget<Text>(find.byKey(const Key('frase-da-folha'))).textSpan! as TextSpan).children!.cast<TextSpan>();
      final destacadas = partes.where((p) => p.style?.fontWeight == FontWeight.w800).map((p) => p.text).toList();
      expect(destacadas, ['breakfast']);
    });

    testWidgets('traduz a palavra (minúscula) com o tradutor e mostra "Traduzindo…" enquanto espera', (tester) async {
      await montar(tester, leitura);
      tradutor.segura = Completer<void>();
      await tester.tap(find.byKey(const Key('palavra-sister')));
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Traduzindo…'), findsOneWidget);
      tradutor.segura!.complete();
      await anda(tester);
      expect(tradutor.chamadas, ['sister']);
      expect(tester.widget<Text>(find.byKey(const Key('traducao-palavra'))).data, 'irmã');
    });

    testWidgets('a palavra de começo de frase vai ao tradutor em minúscula (a mesma palavra, o mesmo cache)', (tester) async {
      await montar(tester, leitura);
      await toca(tester, 'then');
      expect(tradutor.chamadas, ['then']);
      expect(tester.widget<Text>(find.byKey(const Key('palavra-tocada'))).data, 'Then', reason: 'na tela, como está na frase');
    });

    testWidgets('falha do tradutor (cota/rede): mensagem, MAS ainda dá para guardar o cartão (a pista é a frase)', (tester) async {
      await montar(tester, leitura);
      tradutor.erro = const TraducaoFalhou('A tradução gratuita acabou por hoje.', cota: true);
      await toca(tester, 'sister');
      expect(find.byKey(const Key('traducao-falhou')), findsOneWidget);
      expect(find.text('A tradução gratuita acabou por hoje.'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guardar-lacuna')));
      await anda(tester, 12);
      expect(cartoes()['Then I have breakfast with my sister.'], ('Depois tomo café da manhã com minha irmã.', 'sister', ''));
    });

    testWidgets('guardar: cria o cartão com a frase, a tradução da frase e a palavra-alvo (e o pedaço da tradução, se achou)', (tester) async {
      await montar(tester, leitura);
      await toca(tester, 'sister');
      expect(find.text('Guardar cartão de lacuna'), findsOneWidget);
      expect(find.textContaining('esconde só "sister"'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guardar-lacuna')));
      await anda(tester, 12);
      expect(cartoes(), {'Then I have breakfast with my sister.': ('Depois tomo café da manhã com minha irmã.', 'sister', 'irmã')});
      expect(find.text('✓ Cartão guardado em "Meus cartões"'), findsOneWidget);
      expect(revisao.state.config.reversoLigado('txt:$idCartoesAvulsos'), isTrue, reason: 'o 1º cartão liga o inglês → português');
    });

    testWidgets('palavra guardada fica sublinhada na leitura; fechar a folha e tocar de novo mostra que já está guardada', (tester) async {
      await montar(tester, leitura);
      TextDecoration? sublinhado(String p) =>
          tester.widget<Text>(find.descendant(of: find.byKey(Key('palavra-$p')), matching: find.byType(Text))).style!.decoration;
      expect(sublinhado('sister'), isNull);
      await toca(tester, 'sister');
      await tester.tap(find.byKey(const Key('guardar-lacuna')));
      await anda(tester, 12);
      await tester.tapAt(const Offset(20, 20)); // fecha a folha
      await tester.pumpAndSettle();
      expect(sublinhado('sister'), TextDecoration.underline);
      expect(sublinhado('breakfast'), isNull);
      await toca(tester, 'sister');
      final b = tester.widget<FilledButton>(find.byKey(const Key('guardar-lacuna')));
      expect(b.onPressed, isNull, reason: 'já guardada');
      expect(find.text('✓ Cartão guardado em "Meus cartões"'), findsOneWidget);
    });

    testWidgets('outra palavra da MESMA frase troca a palavra do cartão (não duplica)', (tester) async {
      await montar(tester, leitura);
      await toca(tester, 'sister');
      await tester.tap(find.byKey(const Key('guardar-lacuna')));
      await anda(tester, 12);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
      await toca(tester, 'breakfast');
      expect(find.text('Trocar a palavra do cartão ("sister" → "breakfast")'), findsOneWidget);
      await tester.tap(find.byKey(const Key('guardar-lacuna')));
      await anda(tester, 12);
      expect(cartoes().length, 1);
      expect(cartoes().values.single.$2, 'breakfast');
      expect(cartoes().values.single.$3, '', reason: '"café da manhã" tem várias palavras: o pedaço da tradução não é marcado');
    });

    testWidgets('frase sem tradução: não dá para guardar (o cartão não teria pista), e avisa por quê', (tester) async {
      await montar(tester, leitura);
      await toca(tester, 'aqui');
      expect(find.byKey(const Key('sem-cartao')), findsOneWidget);
      expect(find.textContaining('não tem tradução'), findsOneWidget);
      expect(find.byKey(const Key('guardar-lacuna')), findsNothing);
      expect(cartoes(), isEmpty);
    });

    testWidgets('ouvir a palavra e ouvir a frase', (tester) async {
      await montar(tester, leitura);
      await toca(tester, 'bus');
      await tester.tap(find.byTooltip('Ouvir a palavra'));
      await tester.tap(find.byTooltip('Ouvir a frase'));
      await tester.pump();
      expect(voz.falas, ['bus', 'The bus is always full.']);
    });

    testWidgets('celular de 360 px e tema claro: leitura e folha sem estouro', (tester) async {
      final antes = Mixart.atual;
      addTearDown(() => Mixart.atual = antes);
      Mixart.atual = Paleta.flutterClaro;
      await montar(tester, leitura, tamanho: const Size(360, 740));
      await toca(tester, 'breakfast');
      expect(find.byKey(const Key('folha-palavra')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('a lista de leituras', () {
    final graduadas = [
      const Leitura(id: 'b', titulo: 'Texto B1', etapa: 'B1', frases: [FraseDoTexto('Hello there.', 'Olá.')]),
      const Leitura(id: 'a', titulo: 'Texto A1', etapa: 'A1', frases: [FraseDoTexto('Hello there.', 'Olá.'), FraseDoTexto('Bye.', 'Tchau.')]),
    ];

    testWidgets('mostra os "seus textos" primeiro e os graduados por etapa, e abre a leitura', (tester) async {
      final meu = TextoSalvo(id: 'abc', titulo: 'Minha viagem', criadoEm: DateTime(2026), frases: const [FraseDoTexto('I love Rome.', 'Eu amo Roma.')]);
      await montar(tester, () => LeiturasPage(carregador: () async => graduadas, tradutor: tradutor, voz: voz), trilhas: [meu.comoTrilha()]);
      await anda(tester);
      expect(find.text('SEUS TEXTOS'), findsOneWidget);
      expect(find.text('Minha viagem'), findsOneWidget);
      expect(find.text('A1'), findsOneWidget);
      expect(find.text('B1'), findsOneWidget);
      expect(tester.getTopLeft(find.byKey(const Key('leitura-abc'))).dy, lessThan(tester.getTopLeft(find.byKey(const Key('leitura-a'))).dy));
      expect(tester.getTopLeft(find.byKey(const Key('leitura-a'))).dy, lessThan(tester.getTopLeft(find.byKey(const Key('leitura-b'))).dy));
      expect(find.text('2 frases'), findsOneWidget);
      expect(find.text('1 frase'), findsNWidgets(2));
      await tester.tap(find.byKey(const Key('leitura-a')));
      await tester.pumpAndSettle();
      expect(find.text('Texto A1'), findsWidgets);
      expect(find.byKey(const Key('dica-leitura')), findsOneWidget);
    });

    testWidgets('"Meus cartões" não aparece como texto para ler; lista vazia tem mensagem', (tester) async {
      final cartoes = TextoSalvo(id: idCartoesAvulsos, titulo: tituloCartoesAvulsos, criadoEm: DateTime(2026), frases: const [FraseDoTexto('Hi.', 'Oi.')], sequencial: true);
      await montar(tester, () => LeiturasPage(carregador: () async => const [], tradutor: tradutor), trilhas: [cartoes.comoTrilha()]);
      await anda(tester);
      expect(find.text('SEUS TEXTOS'), findsNothing);
      expect(find.textContaining('Não encontrei textos'), findsOneWidget);
    });
  });

  group('o cartão de lacuna na revisão', () {
    const frase = Trecho(
      cod: 'Then I have breakfast with my sister.',
      dica: 'Depois tomo café da manhã com minha irmã.',
      out: '',
      alvo: 'sister',
      alvoPt: 'irmã',
    );

    /// [leitura]: a revisão diz que as frases com alvo são lacunas da leitura (como faz a de verdade para "Meus cartões").
    Future<void> abrir(WidgetTester tester, {NivelResposta nivel = NivelResposta.avancado, SentidoCartao sentido = SentidoCartao.enPt, List<Trecho> itens = const [frase], bool leitura = true}) async {
      SharedPreferences.setMockInitialValues({SessaoCartoesPage.prefNivel: nivel.id, SessaoCartoesPage.prefSentido: sentido.id});
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
          lacunaDaLeitura: leitura ? (f) => f.alvo.isNotEmpty : null,
          chaveDe: RevisaoCubit.chaveReversaDe,
          previsao: (_) => const {Rating.again: 1, Rating.hard: 2, Rating.good: 6, Rating.easy: 21},
          onNota: (f, n) {},
        ),
      ));
      await tester.pumpAndSettle();
    }

    for (final n in [NivelResposta.facil, NivelResposta.medio, NivelResposta.avancado]) {
      testWidgets('nível ${n.rotulo}, sentido EN → PT: vira PT → EN com SÓ a palavra guardada em lacuna', (tester) async {
        await abrir(tester, nivel: n);
        expect(find.text('Depois tomo café da manhã com minha irmã.'), findsOneWidget, reason: 'a frente é a tradução da frase');
        expect(find.text('PORTUGUÊS'), findsOneWidget);
        expect(find.byKey(const Key('lacunas')), findsOneWidget);
        expect(find.byKey(const Key('lacuna-0')), findsOneWidget);
        expect(find.byKey(const Key('lacuna-1')), findsNothing, reason: 'uma lacuna só');
        expect(find.byKey(const Key('resposta-escrita')), findsNothing);
        expect(find.textContaining('palavra que falta'), findsOneWidget);
        // as outras palavras do inglês estão à vista
        for (final p in ['Then', 'I', 'have', 'breakfast', 'with', 'my']) {
          expect(find.text(p), findsWidgets, reason: p);
        }
      });
    }

    testWidgets('acertar a palavra sugere Bom; errar sugere Errei', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byKey(const Key('lacuna-0')), 'Sister');
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.text('Todas as lacunas certas! ✅'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('nota-bom')), matching: find.textContaining('sugerida')), findsOneWidget);
    });

    testWidgets('errar a palavra mostra "Você acertou 0 de 1 lacunas" e a frase certa', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byKey(const Key('lacuna-0')), 'brother');
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      expect(find.textContaining('Você acertou 0 de 1 lacunas'), findsOneWidget);
      expect(find.descendant(of: find.byKey(const Key('nota-errei')), matching: find.textContaining('sugerida')), findsOneWidget);
      expect(find.byKey(const Key('verso-cartao')), findsOneWidget);
    });

    testWidgets('"Só virar" continua sendo só virar (autoavaliação), sem lacuna', (tester) async {
      await abrir(tester, nivel: NivelResposta.livre);
      expect(find.byKey(const Key('mostrar-resposta')), findsOneWidget);
      expect(find.byKey(const Key('lacunas')), findsNothing);
    });

    testWidgets('palavra-alvo que não está na frase: volta ao sorteio de sempre (sem quebrar)', (tester) async {
      const torta = Trecho(cod: 'I like tea very much.', dica: 'Gosto muito de chá.', out: '', alvo: 'coffee');
      await abrir(tester, nivel: NivelResposta.medio, itens: const [torta]);
      expect(find.byKey(const Key('lacunas')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a lacuna da leitura NÃO entra na série de níveis (não mexe nas sugestões)', (tester) async {
      await abrir(tester);
      await tester.enterText(find.byKey(const Key('lacuna-0')), 'sister');
      await tester.tap(find.byKey(const Key('conferir-resposta')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('nota-bom')));
      await tester.pump();
      final p = await SharedPreferences.getInstance();
      expect(p.getString(SessaoCartoesPage.prefSerie) ?? '{}', '{}');
    });

    testWidgets('REGRESSÃO: frase do CURSO com `alvo` (o destaque da lição) NÃO vira lacuna da leitura', (tester) async {
      // quem abre a revisão não a marca como lacuna da leitura → continua um cartão comum
      await abrir(tester, leitura: false);
      expect(find.text('Then I have breakfast with my sister.'), findsOneWidget, reason: 'o inglês na frente, como sempre');
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
      expect(find.byKey(const Key('lacunas')), findsNothing);
    });

    testWidgets('frase comum (sem alvo) continua como sempre', (tester) async {
      await abrir(tester, itens: const [Trecho(cod: 'Nice to meet you.', dica: 'Prazer.', out: '')]);
      expect(find.text('Nice to meet you.'), findsOneWidget);
      expect(find.byKey(const Key('resposta-escrita')), findsOneWidget);
    });

    testWidgets('no ditado a lacuna da leitura não muda nada: só o áudio na frente', (tester) async {
      await abrir(tester, sentido: SentidoCartao.audio);
      expect(find.byKey(const Key('frente-audio')), findsOneWidget);
      expect(find.text('Depois tomo café da manhã com minha irmã.'), findsNothing);
    });

    testWidgets('360 px: a lacuna cabe', (tester) async {
      await abrir(tester);
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
