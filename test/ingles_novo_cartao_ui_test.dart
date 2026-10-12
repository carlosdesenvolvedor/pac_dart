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
import 'package:pac_dart/features/ingles/data/audio_usuario.dart';
import 'package:pac_dart/features/ingles/data/audio_usuario_repository.dart';
import 'package:pac_dart/features/ingles/data/textos_repository.dart';
import 'package:pac_dart/features/ingles/data/tradutor.dart';
import 'package:pac_dart/features/ingles/domain/audio_usuario.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';
import 'package:pac_dart/features/ingles/presentation/baralhos_page.dart';
import 'package:pac_dart/features/ingles/presentation/exportar_anki_dialog.dart';
import 'package:pac_dart/features/ingles/presentation/importar_cartoes_page.dart';
import 'package:pac_dart/features/ingles/presentation/novo_cartao_page.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/audio_da_frase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ingles_baralhos_test.dart' show ConfigMemoria, RepoMemoria, trilhasDeTeste;

/// Os textos do aluno só na memória (os futuros se resolvem sem relógio real).
class TextosMemoria implements TextosRepository {
  final List<TextoSalvo> lista = [];
  @override
  Future<List<TextoSalvo>> carregar() async => [...lista];
  @override
  Future<void> salvar(TextoSalvo t) async {
    lista
      ..removeWhere((x) => x.id == t.id)
      ..add(t);
  }

  @override
  Future<void> apagar(String id) async => lista.removeWhere((x) => x.id == id);
}

class _Tradutor implements Tradutor {
  bool falha = false;
  final recebidas = <String>[];
  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int, int)? aoProgredir}) async {
    if (falha) throw const TraducaoFalhou('O tradutor grátis chegou ao limite de hoje.', cota: true);
    recebidas.addAll(frases);
    return [for (final f in frases) 'PT: $f'];
  }
}

class _AudioQueFalha extends MemoriaAudioUsuarioRepository {
  @override
  Future<void> salvar(String chave, ClipeAudio clipe) async => throw Exception('sem rede');
}

Uint8List _mp3([int n = 2048]) => Uint8List(n)..setRange(0, 3, 'ID3'.codeUnits);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AudioUsuario.limpar();
  });
  tearDown(AudioUsuario.limpar);

  const curso = [
    Trilha(nivel: 'Primeiros', emoji: '👋', etapa: 'A1 · Fundação', licoes: [
      Licao(id: 'primeiros.um', nome: 'Um', emoji: '1', trechos: [Trecho(cod: 'Hi.', dica: 'Oi.', out: '')]),
    ]),
  ];

  /// O app mínimo: CursoBloc (com textos na memória), RevisaoCubit e uma tela com um botão que abre [destino].
  Future<({CursoBloc curso, RevisaoCubit revisao, TextosMemoria textos, List<Object?> saidas})> montar(
    WidgetTester tester,
    Widget Function() destino, {
    List<Trilha> trilhas = curso,
  }) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final textos = TextosMemoria();
    final bloc = CursoBloc(
      loader: _Loader(trilhas),
      progresso: LocalProgressoRepository(prefixo: 'en_'),
      textos: textos,
    )..add(const CursoIniciado());
    final revisao = RevisaoCubit(repo: RepoMemoria(), configRepo: ConfigMemoria(), agendador: AgendadorFsrs(fuzz: false));
    addTearDown(bloc.close);
    addTearDown(revisao.close);
    await tester.runAsync(() => bloc.stream.firstWhere((s) => s.status == CursoStatus.pronto));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    final saidas = <Object?>[];
    await tester.pumpWidget(MultiBlocProvider(
      providers: [BlocProvider.value(value: bloc), BlocProvider.value(value: revisao)],
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => saidas.add(await Navigator.of(context).push<Object?>(MaterialPageRoute(builder: (_) => destino()))),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return (curso: bloc, revisao: revisao, textos: textos, saidas: saidas);
  }

  /// Deixa o que depende de futuros reais (o bloc que grava e emite) andar.
  Future<void> anda(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 15)));
      await tester.pump(const Duration(milliseconds: 30));
    }
  }

  group('NovoCartaoPage', () {
    SeletorAudio escolhe(Uint8List bytes, [String nome = 'meu.mp3']) => () async => (nome: nome, bytes: bytes);

    testWidgets('a tela explica frente/verso; sem onde guardar áudio, não oferece áudio', (tester) async {
      await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor()));
      expect(find.text('Novo cartão'), findsOneWidget);
      expect(find.text('FRENTE · INGLÊS'), findsOneWidget);
      expect(find.text('VERSO · PORTUGUÊS'), findsOneWidget);
      expect(find.byKey(const Key('audio-novo')), findsNothing);
    });

    testWidgets('validações: tudo vazio, só a frente, frente sem letra', (tester) async {
      await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor()));
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await tester.pump();
      expect(find.textContaining('frente em inglês'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('frente-novo')), 'I am hungry.');
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await tester.pump();
      expect(find.textContaining('Escreva o verso'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('frente-novo')), '!!! 123');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'algo');
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await tester.pump();
      expect(find.textContaining('frente em inglês'), findsOneWidget);
    });

    testWidgets('"Traduzir para mim" preenche o verso; sem frente pede a frente; falha mostra o motivo e deixa escrever à mão', (tester) async {
      final t = _Tradutor();
      await montar(tester, () => NovoCartaoPage(tradutor: t));
      await tester.tap(find.byKey(const Key('traduzir-novo')));
      await tester.pump();
      expect(find.textContaining('frente em inglês'), findsOneWidget);
      expect(t.recebidas, isEmpty);

      await tester.enterText(find.byKey(const Key('frente-novo')), 'I would like a coffee, please.');
      await tester.tap(find.byKey(const Key('traduzir-novo')));
      await tester.pumpAndSettle();
      expect(t.recebidas, ['I would like a coffee, please.']);
      expect(tester.widget<TextField>(find.byKey(const Key('verso-novo'))).controller!.text, 'PT: I would like a coffee, please.');

      // a tradução é editável e a falha não apaga o que está escrito
      await tester.enterText(find.byKey(const Key('verso-novo')), 'Eu queria um café.');
      t.falha = true;
      await tester.tap(find.byKey(const Key('traduzir-novo')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('erro-novo')), findsOneWidget);
      expect(find.textContaining('limite de hoje'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('verso-novo'))).controller!.text, 'Eu queria um café.');
    });

    testWidgets('criar: entra em "Meus cartões", limpa os campos, liga o inglês → português só na 1ª vez e deixa criar outro', (tester) async {
      final app = await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor()));
      await tester.enterText(find.byKey(const Key('frente-novo')), 'I am hungry.');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'Estou com fome.');
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await anda(tester);
      expect(find.text('Cartão criado! "Meus cartões" tem 1 cartão.'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('frente-novo'))).controller!.text, isEmpty);
      expect(tester.widget<TextField>(find.byKey(const Key('verso-novo'))).controller!.text, isEmpty);
      final trilha = app.curso.state.trilhas.last;
      expect(trilha.textoId, idCartoesAvulsos);
      expect(trilha.licoes.single.trechos.single.cod, 'I am hungry.');
      expect(trilha.licoes.single.trechos.single.dica, 'Estou com fome.');
      expect(app.revisao.state.config.reversoLigado('txt:$idCartoesAvulsos'), isTrue, reason: 'o 1º cartão liga o virar');
      expect(app.textos.lista.single.frases.single.en, 'I am hungry.');

      // a pessoa desliga nos Baralhos; o 2º cartão NÃO religa
      await app.revisao.mudarConfig(app.revisao.state.config.comReversos(['txt:$idCartoesAvulsos'], ligar: false));
      await tester.enterText(find.byKey(const Key('frente-novo')), 'I am tired.');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'Estou cansado.');
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await anda(tester);
      expect(find.text('Cartão criado! "Meus cartões" tem 2 cartões.'), findsOneWidget);
      expect(app.revisao.state.config.reversoLigado('txt:$idCartoesAvulsos'), isFalse);
    });

    testWidgets('frente repetida só troca o verso; letras acentuadas da frente viram simples e a tela avisa', (tester) async {
      final app = await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor()));
      Future<void> cria(String f, String v) async {
        await tester.enterText(find.byKey(const Key('frente-novo')), f);
        await tester.enterText(find.byKey(const Key('verso-novo')), v);
        await tester.tap(find.byKey(const Key('criar-cartao')));
        await anda(tester);
      }

      await cria('Café, please.', 'Um café, por favor.');
      expect(find.byKey(const Key('aviso-novo')), findsOneWidget);
      expect(find.textContaining('letras acentuadas'), findsOneWidget);
      expect(app.curso.state.trilhas.last.licoes.single.trechos.single.cod, 'Cafe, please.');
      await cria('cafe, PLEASE.', 'Um cafezinho, por favor.');
      final t = app.curso.state.trilhas.last.licoes.single.trechos;
      expect(t.length, 1, reason: 'a mesma frente não vira dois cartões');
      expect(t.single.dica, 'Um cafezinho, por favor.');
    });

    testWidgets('Concluir e a seta de voltar devolvem quantos cartões foram criados', (tester) async {
      final app = await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor()));
      expect(find.byKey(const Key('concluir-novo')), findsNothing);
      await tester.enterText(find.byKey(const Key('frente-novo')), 'One.');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'Um.');
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await anda(tester);
      await tester.enterText(find.byKey(const Key('frente-novo')), 'Two.');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'Dois.');
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await anda(tester);
      await tester.tap(find.byKey(const Key('concluir-novo')));
      await tester.pumpAndSettle();
      expect(app.saidas, [2]);
    });

    testWidgets('sair sem criar nada devolve 0', (tester) async {
      final app = await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor()));
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(app.saidas, [0]);
    });

    testWidgets('com áudio disponível: escolher um arquivo mostra o nome e o formato; criar anexa o áudio à frente', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor(), seletor: escolhe(_mp3(3072), 'minha-voz.mp3')));
      await tester.enterText(find.byKey(const Key('frente-novo')), 'I am hungry.');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'Estou com fome.');
      await tester.tap(find.byKey(const Key('audio-novo')));
      await tester.pump();
      expect(find.byKey(const Key('audio-escolhido')), findsOneWidget);
      expect(find.text('minha-voz.mp3 · MP3 · 3 KB'), findsOneWidget);

      await tester.tap(find.byKey(const Key('criar-cartao')));
      await anda(tester);
      expect(AudioUsuario.tem('I am hungry.'), isTrue);
      expect(AudioUsuario.infoDe('I am hungry.')!.mime, 'audio/mpeg');
      expect(find.byKey(const Key('audio-escolhido')), findsNothing, reason: 'o próximo cartão começa sem áudio');
      expect(find.byKey(const Key('audio-novo')), findsOneWidget);
    });

    testWidgets('o áudio vai para a frente JÁ ajustada (a que se digita)', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor(), seletor: escolhe(_mp3())));
      await tester.enterText(find.byKey(const Key('frente-novo')), 'It’s a café.');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'É um café.');
      await tester.tap(find.byKey(const Key('audio-novo')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await anda(tester);
      expect(AudioUsuario.tem("It's a cafe."), isTrue);
    });

    testWidgets('arquivo que não é áudio: mostra o motivo e não aparece como escolhido; dá para tirar o escolhido', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      var vez = 0;
      await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor(), seletor: () async {
            vez++;
            return vez == 1 ? (nome: 'foto.mp3', bytes: Uint8List.fromList('not audio, just some text bytes'.codeUnits)) : (nome: 'ok.mp3', bytes: _mp3());
          }));
      await tester.tap(find.byKey(const Key('audio-novo')));
      await tester.pump();
      expect(find.textContaining('não parece um arquivo de áudio'), findsOneWidget);
      expect(find.byKey(const Key('audio-escolhido')), findsNothing);
      await tester.tap(find.byKey(const Key('audio-novo')));
      await tester.pump();
      expect(find.byKey(const Key('audio-escolhido')), findsOneWidget);
      expect(find.byKey(const Key('erro-novo')), findsNothing, reason: 'escolher de novo limpa o erro');
      await tester.tap(find.byKey(const Key('tirar-audio-novo')));
      await tester.pump();
      expect(find.byKey(const Key('audio-escolhido')), findsNothing);
      expect(find.byKey(const Key('audio-novo')), findsOneWidget);
    });

    testWidgets('o áudio não ficou guardado (nuvem falhou): o cartão É criado e a tela avisa só do áudio', (tester) async {
      await AudioUsuario.iniciar(_AudioQueFalha());
      final app = await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor(), seletor: escolhe(_mp3())));
      await tester.enterText(find.byKey(const Key('frente-novo')), 'I am hungry.');
      await tester.enterText(find.byKey(const Key('verso-novo')), 'Estou com fome.');
      await tester.tap(find.byKey(const Key('audio-novo')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('criar-cartao')));
      await anda(tester);
      expect(app.curso.state.trilhas.last.licoes.single.trechos.length, 1);
      expect(find.text('Cartão criado! "Meus cartões" tem 1 cartão.'), findsOneWidget);
      expect(find.textContaining('o áudio não ficou guardado'), findsOneWidget);
      expect(AudioUsuario.tem('I am hungry.'), isFalse);
    });

    testWidgets('celular estreito: sem estourar', (tester) async {
      await AudioUsuario.iniciar(MemoriaAudioUsuarioRepository());
      await montar(tester, () => NovoCartaoPage(tradutor: _Tradutor(), seletor: escolhe(_mp3(), 'um-arquivo-com-um-nome-bem-comprido-mesmo.mp3')));
      tester.view.physicalSize = const Size(360, 800);
      await tester.pump();
      await tester.tap(find.byKey(const Key('audio-novo')));
      await tester.pump();
      final e = tester.takeException();
      expect(e, isNull, reason: '$e');
    });
  });

  group('ImportarCartoesPage', () {
    testWidgets('mostra quantos cartões entendeu, o que ignorou, uma prévia e os avisos', (tester) async {
      await montar(tester, () => const ImportarCartoesPage());
      expect(tester.widget<FilledButton>(find.byKey(const Key('botao-importar'))).onPressed, isNull);
      await tester.enterText(find.byKey(const Key('texto-importar')),
          'Café ; Coffee\nI am hungry ; Estou com fome\nsem separador\nWhere is it? | Onde fica?\nOne ; Um\nTwo ; Dois');
      await tester.pump();
      expect(find.text('5 cartões prontos · 1 linha ignorada'), findsOneWidget);
      expect(find.text('Cafe  →  Coffee'), findsOneWidget);
      expect(find.text('… e mais 2'), findsOneWidget);
      expect(find.textContaining('letras acentuadas'), findsOneWidget);
      expect(find.text('Importar 5 cartões'), findsOneWidget);
    });

    testWidgets('nada reconhecido: explica o formato e não deixa importar', (tester) async {
      await montar(tester, () => const ImportarCartoesPage());
      await tester.enterText(find.byKey(const Key('texto-importar')), 'só texto solto, sem separador nenhum');
      await tester.pump();
      expect(find.byKey(const Key('vazio-importar')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('botao-importar'))).onPressed, isNull);
      expect(find.byKey(const Key('contagem-importar')), findsNothing);
    });

    testWidgets('importar devolve o baralho com o nome dado (ou o padrão)', (tester) async {
      var app = await montar(tester, () => const ImportarCartoesPage(textoInicial: 'A ; um\nB ; dois'));
      expect(find.text('2 cartões prontos'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('titulo-importar')), 'Viagem');
      await tester.tap(find.byKey(const Key('botao-importar')));
      await tester.pumpAndSettle();
      var t = app.saidas.single as TextoSalvo;
      expect((t.titulo, t.frases.length, t.sequencial), ('Viagem', 2, false));

      await tester.pumpWidget(const SizedBox());
      app = await montar(tester, () => const ImportarCartoesPage(textoInicial: 'A ; um'));
      await tester.tap(find.byKey(const Key('botao-importar')));
      await tester.pumpAndSettle();
      t = app.saidas.single as TextoSalvo;
      expect(t.titulo, 'Cartões importados');
      expect(find.text('1 cartão pronto'), findsNothing, reason: 'a tela já fechou');
    });

    testWidgets('carregar de um arquivo preenche a caixa; o seletor que quebra vira recado', (tester) async {
      await montar(tester, () => ImportarCartoesPage(seletor: () async => '#separator:tab\nHello\tOlá\nBye\tTchau'));
      await tester.tap(find.byKey(const Key('arquivo-importar')));
      await tester.pump();
      expect(find.text('2 cartões prontos'), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const Key('texto-importar'))).controller!.text, contains('Hello'));

      await tester.pumpWidget(const SizedBox());
      await montar(tester, () => ImportarCartoesPage(seletor: () async => throw Exception('permissão')));
      await tester.tap(find.byKey(const Key('arquivo-importar')));
      await tester.pump();
      expect(find.textContaining('Não consegui abrir o arquivo'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());
      await montar(tester, () => ImportarCartoesPage(seletor: () async => null));
      await tester.tap(find.byKey(const Key('arquivo-importar')));
      await tester.pump();
      expect(find.byKey(const Key('contagem-importar')), findsNothing, reason: 'cancelou: nada muda');
    });

    testWidgets('lista acima do máximo: corta e avisa', (tester) async {
      final lista = [for (var i = 0; i < 520; i++) 'Sentence ${i.toRadixString(36)} abc ; Frase $i'].join('\n');
      await montar(tester, () => ImportarCartoesPage(textoInicial: lista));
      expect(find.text('500 cartões prontos'), findsOneWidget);
      expect(find.textContaining('passou de 500 cartões'), findsOneWidget);
    });
  });

  group('exportar para o Anki', () {
    String? copiado;
    setUp(() {
      copiado = null;
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copiado = (call.arguments as Map)['text'] as String?;
        return null;
      });
    });
    tearDown(() => TestWidgetsFlutterBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    Future<void> abrir(WidgetTester tester, {List<EntradaHistorico> historico = const []}) async {
      final indice = IndiceBaralhos.de(trilhasDeTeste());
      await montar(tester, () => Builder(builder: (context) => Scaffold(body: Center(
            child: TextButton(onPressed: () => mostrarExportarAnki(context, indice: indice, historico: historico), child: const Text('exportar')),
          ))));
      await tester.tap(find.text('exportar'));
      await tester.pumpAndSettle();
    }

    testWidgets('mostra quantos cartões e a prévia do arquivo; copiar põe o texto na área de transferência', (tester) async {
      await abrir(tester);
      expect(find.text('Exportar para o Anki'), findsOneWidget);
      expect(find.text('5 cartões'), findsOneWidget, reason: 'f1, f2, f3, f4 e a frase do texto (f2 repete e sai uma vez)');
      expect(find.textContaining('#separator:tab'), findsOneWidget);
      expect(find.byKey(const Key('baixar-exportar')), findsNothing, reason: 'baixar arquivo só no navegador');
      await tester.tap(find.byKey(const Key('copiar-exportar')));
      await tester.pump();
      expect(copiado, startsWith('#separator:tab\n#html:false\n#tags column:3\n'));
      expect(copiado, contains('Nice to meet you.\tPrazer em te conhecer.\t'));
      expect(find.textContaining('Texto copiado'), findsOneWidget);
    });

    testWidgets('escopo "só os meus" e "português na frente" mudam a contagem e o texto', (tester) async {
      await abrir(tester);
      await tester.tap(find.byKey(const Key('escopo-meus')));
      await tester.pump();
      expect(find.text('1 cartão'), findsOneWidget);
      await tester.tap(find.byKey(const Key('inverter-exportar')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('copiar-exportar')));
      await tester.pump();
      expect(copiado!.trim().split('\n').last, startsWith('Eu amo Roma.\tI love Rome.\t'));
    });

    testWidgets('histórico em CSV: usa a frase em inglês; sem histórico o botão fica desligado', (tester) async {
      await abrir(tester);
      expect(tester.widget<OutlinedButton>(find.byKey(const Key('copiar-historico'))).onPressed, isNull);
      await tester.pumpWidget(const SizedBox());
      final chave = RevisaoCubit.chaveDe(const Trecho(cod: 'Nice to meet you.', dica: '', out: ''));
      await abrir(tester, historico: [EntradaHistorico(20738, chave, 3), EntradaHistorico(20738, '$chave~r', 4, primeira: true)]);
      await tester.ensureVisible(find.byKey(const Key('copiar-historico')));
      await tester.tap(find.byKey(const Key('copiar-historico')));
      await tester.pump();
      final linhas = copiado!.trim().split('\n');
      expect(linhas.first, 'data,sentido,frase,nota,primeira_vez');
      expect(linhas[1], '2026-10-12,portugues-ingles,Nice to meet you.,3,0');
      expect(linhas[2], '2026-10-12,ingles-portugues,Nice to meet you.,4,1');
    });

    testWidgets('sem baralhos: nada a copiar', (tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) => TextButton(
              onPressed: () => mostrarExportarAnki(context, indice: IndiceBaralhos.de(const []), historico: const []),
              child: const Text('exportar'),
            )),
      ));
      await tester.tap(find.text('exportar'));
      await tester.pumpAndSettle();
      expect(find.text('0 cartões'), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('copiar-exportar'))).onPressed, isNull);
    });
  });

  group('entradas nos Baralhos', () {
    Future<({CursoBloc curso, RevisaoCubit revisao})> baralhos(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final revisao = RevisaoCubit(repo: RepoMemoria(), configRepo: ConfigMemoria(), agendador: AgendadorFsrs(fuzz: false));
      final bloc = CursoBloc(loader: _Loader(curso), progresso: LocalProgressoRepository(prefixo: 'en_'), textos: TextosMemoria())
        ..add(const CursoIniciado());
      addTearDown(bloc.close);
      addTearDown(revisao.close);
      await tester.runAsync(() => bloc.stream.firstWhere((s) => s.status == CursoStatus.pronto));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pumpWidget(MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: bloc),
            BlocProvider.value(value: revisao),
            RepositoryProvider<Tradutor>.value(value: _Tradutor()),
          ],
          child: const BaralhosPage(),
        ),
      ));
      await tester.pump();
      return (curso: bloc, revisao: revisao);
    }

    testWidgets('os três botões existem e abrem Novo cartão, Importar lista e Exportar', (tester) async {
      await baralhos(tester);
      await tester.tap(find.byKey(const Key('novo-cartao')));
      await tester.pumpAndSettle();
      expect(find.byType(NovoCartaoPage), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('importar-cartoes')));
      await tester.pumpAndSettle();
      expect(find.byType(ImportarCartoesPage), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('exportar-anki')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('copiar-exportar')), findsOneWidget, reason: 'o diálogo abriu (o botão e o título têm o mesmo texto)');
    });

    testWidgets('importar uma lista: o baralho aparece em "Meus textos", com o inglês → português já ligado, sem sair dos Baralhos', (tester) async {
      final app = await baralhos(tester);
      expect(find.text('MEUS TEXTOS'), findsNothing);
      await tester.tap(find.byKey(const Key('importar-cartoes')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('titulo-importar')), 'Viagem');
      await tester.enterText(find.byKey(const Key('texto-importar')), 'I am hungry ; Estou com fome\nWhere is it? ; Onde fica?');
      await tester.pump();
      await tester.tap(find.byKey(const Key('botao-importar')));
      await tester.pumpAndSettle();
      await anda(tester);

      expect(find.byType(BaralhosPage), findsOneWidget);
      expect(find.byType(ImportarCartoesPage), findsNothing);
      expect(find.text('MEUS TEXTOS'), findsOneWidget);
      expect(find.text('Viagem'), findsOneWidget);
      final trilha = app.curso.state.trilhas.last;
      expect(trilha.propria, isTrue);
      expect(trilha.nivel, 'Viagem');
      expect(app.curso.state.trilhaIdx, 0, reason: 'a seleção não foi para o texto novo');
      expect(app.revisao.state.config.reversoLigado(trilha.baralhoId), isTrue);
      expect(find.text('inglês → português ligado · 2 novos'), findsOneWidget);
    });
  });
}

class _Loader extends CurriculoLoader {
  final List<Trilha> trilhas;
  _Loader(this.trilhas) : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}
