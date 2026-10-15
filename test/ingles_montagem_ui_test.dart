// A tela do modo Montar (Fase 7): os blocos, tocar/soltar, Conferir certo/errado, as marcas e o seletor de modos.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/core/theme/mixart.dart';
import 'package:pac_dart/features/ingles/domain/entrada_resposta.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/montagem_frase.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/pastilha.dart';
import 'package:pac_dart/features/ingles/presentation/widgets/seletor_entrada.dart';

const _frase = 'I like cats.';
const _apoio = ['The dog runs fast', 'Open the door now'];
const _verde = Color(0xFF4CD08A);

class _Chamadas {
  final erros = <Map<int, int>>[];
  int certas = 0, naoSei = 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Mixart.usarGoogleFonts = false;

  Future<_Chamadas> abrir(
    WidgetTester tester, {
    String frase = _frase,
    int semente = 3,
    bool podeNaoSei = true,
    Size tamanho = const Size(390, 844),
    double fonte = 1,
  }) async {
    tester.view.physicalSize = tamanho;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _Chamadas();
    await tester.pumpWidget(MaterialApp(
      theme: Mixart.tema(),
      builder: (context, filho) =>
          MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fonte)), child: filho!),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MontagemFrase(
            frase: frase,
            apoio: _apoio,
            semente: semente,
            podeNaoSei: podeNaoSei,
            onErrou: c.erros.add,
            onCerta: () => c.certas++,
            onNaoSei: () => c.naoSei++,
          ),
        ),
      ),
    ));
    return c;
  }

  MontagemFraseState estado(WidgetTester t) => t.state<MontagemFraseState>(find.byType(MontagemFrase));

  /// O id do bloco certo (não enfeite) com [texto]; [vez] distingue repetidos.
  int idDe(WidgetTester t, String texto, {int vez = 0}) =>
      estado(t).blocos.where((b) => !b.distrator && b.texto == texto).elementAt(vez).id;

  Future<void> tocar(WidgetTester t, String texto, {int vez = 0}) async {
    final bloco = find.byKey(Key('bloco-${idDe(t, texto, vez: vez)}'));
    await t.ensureVisible(bloco);
    await t.pump();
    await t.tap(bloco);
    await t.pump();
  }

  Future<void> montar(WidgetTester t, List<String> palavras) async {
    for (final p in palavras) {
      await tocar(t, p);
    }
  }

  /// Os textos das pastilhas que estão na frase montada, na ordem.
  List<String> naFrase(WidgetTester t) => [
        for (final p in t.widgetList<Pastilha>(find.descendant(of: find.byKey(const Key('montagem-frase')), matching: find.byType(Pastilha))))
          p.texto
      ];

  MarcaPastilha marcaDe(WidgetTester t, String texto) => t
      .widgetList<Pastilha>(find.descendant(of: find.byKey(const Key('montagem-frase')), matching: find.byType(Pastilha)))
      .firstWhere((p) => p.texto == texto)
      .marca;

  Color? bordaDe(WidgetTester t, Key chave) {
    final m = t.widget<Material>(find.descendant(of: find.byKey(chave), matching: find.byType(Material)).first);
    return (m.shape as RoundedRectangleBorder).side.color;
  }

  final conferir = find.byKey(const Key('montagem-conferir'));
  final erro = find.byKey(const Key('montagem-erro'));
  final naoSei = find.byKey(const Key('montagem-nao-sei'));

  group('os blocos', () {
    testWidgets('as palavras da frase + 2 a 5 de enfeite, e a caixa convida a tocar', (tester) async {
      await abrir(tester);
      final b = estado(tester).blocos;
      expect(b.where((x) => !x.distrator).map((x) => x.texto).toSet(), {'I', 'like', 'cats'});
      expect(b.where((x) => x.distrator).length, inInclusiveRange(2, 5));
      for (final x in b) {
        expect(find.byKey(Key('bloco-${x.id}')), findsOneWidget);
      }
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget);
    });

    testWidgets('mesma semente = mesmos blocos na mesma ordem, mesmo reconstruindo a tela', (tester) async {
      await abrir(tester, semente: 9);
      final a = estado(tester).blocos.map((x) => x.texto).toList();
      await abrir(tester, semente: 9);
      expect(estado(tester).blocos.map((x) => x.texto).toList(), a);
    });

    testWidgets('tocar põe o bloco na frase (e deixa o buraco no banco); tocar de novo solta', (tester) async {
      await abrir(tester);
      final id = idDe(tester, 'like');
      await tocar(tester, 'like');
      expect(find.byKey(Key('escolhido-$id')), findsOneWidget);
      expect(find.textContaining('Toque nos blocos abaixo'), findsNothing);
      // o bloco do banco virou buraco: tocar nele de novo não repete a palavra
      await tester.tap(find.byKey(Key('bloco-$id')), warnIfMissed: false);
      await tester.pump();
      expect(naFrase(tester), ['like']);
      await tester.tap(find.byKey(Key('escolhido-$id')));
      await tester.pump();
      expect(naFrase(tester), isEmpty);
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget);
    });

    testWidgets('soltar um bloco do MEIO mantém os outros na ordem; ele volta pelo fim', (tester) async {
      await abrir(tester);
      await montar(tester, ['I', 'like', 'cats']);
      expect(naFrase(tester), ['I', 'like', 'cats']);
      await tester.tap(find.byKey(Key('escolhido-${idDe(tester, 'like')}')));
      await tester.pump();
      expect(naFrase(tester), ['I', 'cats']);
      await tocar(tester, 'like');
      expect(naFrase(tester), ['I', 'cats', 'like']);
    });

    testWidgets('palavras repetidas na frase: cada bloco "very" é tocado uma vez', (tester) async {
      await abrir(tester, frase: 'It is very very good.');
      expect(estado(tester).blocos.where((b) => !b.distrator && b.texto == 'very').length, 2);
      await tocar(tester, 'very', vez: 0);
      await tocar(tester, 'very', vez: 1);
      expect(naFrase(tester), ['very', 'very']);
    });
  });

  group('Conferir', () {
    testWidgets('sem nenhum bloco o botão está desligado e nada acontece', (tester) async {
      final c = await abrir(tester);
      await tester.tap(conferir, warnIfMissed: false);
      await tester.pump();
      expect(c.certas, 0);
      expect(c.erros, isEmpty);
      expect(erro, findsNothing);
      estado(tester).conferir(); // pelo teclado (Enter) também não
      await tester.pump();
      expect(c.certas, 0);
      expect(c.erros, isEmpty);
    });

    testWidgets('frase certa: conclui uma vez, pastilhas verdes, sem botões e sem mexer mais', (tester) async {
      final c = await abrir(tester);
      await montar(tester, ['I', 'like', 'cats']);
      await tester.tap(conferir);
      await tester.pump();
      expect(c.certas, 1);
      expect(c.erros, isEmpty);
      expect(erro, findsNothing);
      for (final p in ['I', 'like', 'cats']) {
        expect(marcaDe(tester, p), MarcaPastilha.certa);
      }
      expect(bordaDe(tester, Key('escolhido-${idDe(tester, 'I')}')), _verde);
      expect(conferir, findsNothing);
      expect(naoSei, findsNothing);
      // tocar numa pastilha depois de concluir não solta
      await tester.tap(find.byKey(Key('escolhido-${idDe(tester, 'cats')}')), warnIfMissed: false);
      await tester.pump();
      expect(naFrase(tester), ['I', 'like', 'cats']);
      estado(tester).conferir(); // um 2º Enter não conclui outra vez
      expect(c.certas, 1);
    });

    testWidgets('palavra errada: 1 erro na posição dela, pastilha vermelha, recado e dá para ajustar', (tester) async {
      final c = await abrir(tester);
      final enfeite = estado(tester).blocos.firstWhere((b) => b.distrator);
      await montar(tester, ['I', 'like']);
      await tester.tap(find.byKey(Key('bloco-${enfeite.id}')));
      await tester.pump();
      await tester.tap(conferir);
      await tester.pump();
      expect(c.certas, 0);
      expect(c.erros, [
        {7: 1}
      ]);
      expect(erro, findsOneWidget);
      expect(marcaDe(tester, 'I'), MarcaPastilha.certa);
      expect(marcaDe(tester, 'like'), MarcaPastilha.certa);
      expect(marcaDe(tester, enfeite.texto), MarcaPastilha.errada);
      expect(bordaDe(tester, Key('escolhido-${enfeite.id}')), Mixart.danger);
      // tira o errado e põe o certo: as marcas e o recado somem, e agora fecha
      await tester.tap(find.byKey(Key('escolhido-${enfeite.id}')));
      await tester.pump();
      expect(erro, findsNothing);
      expect(marcaDe(tester, 'I'), MarcaPastilha.nenhuma);
      await tocar(tester, 'cats');
      await tester.tap(conferir);
      await tester.pump();
      expect(c.certas, 1);
      expect(c.erros.length, 1, reason: 'a 2ª conferência estava certa: não soma erro');
    });

    testWidgets('errar a mesma palavra 3× soma 3 erros (cada Conferir errado conta)', (tester) async {
      final c = await abrir(tester);
      final enfeite = estado(tester).blocos.firstWhere((b) => b.distrator);
      await montar(tester, ['I', 'like']);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('bloco-${enfeite.id}')), warnIfMissed: false);
        await tester.pump();
        await tester.tap(conferir);
        await tester.pump();
        await tester.tap(find.byKey(Key('escolhido-${enfeite.id}')));
        await tester.pump();
      }
      expect(c.erros, [
        {7: 1},
        {7: 1},
        {7: 1}
      ]);
    });

    testWidgets('palavras certas em outra ordem não passam: há erro e pastilhas vermelhas', (tester) async {
      final c = await abrir(tester);
      await montar(tester, ['cats', 'like', 'I']);
      await tester.tap(conferir);
      await tester.pump();
      expect(c.certas, 0);
      expect(c.erros, hasLength(1));
      expect(c.erros.single, isNotEmpty);
      expect(erro, findsOneWidget);
    });

    testWidgets('enfeite sobrando no fim: não passa, mas não soma erro (só o enfeite fica vermelho)', (tester) async {
      final c = await abrir(tester);
      final enfeite = estado(tester).blocos.firstWhere((b) => b.distrator);
      await montar(tester, ['I', 'like', 'cats']);
      await tester.tap(find.byKey(Key('bloco-${enfeite.id}')));
      await tester.pump();
      await tester.tap(conferir);
      await tester.pump();
      expect(c.certas, 0);
      expect(c.erros, [<int, int>{}]);
      expect(marcaDe(tester, enfeite.texto), MarcaPastilha.errada);
    });

    testWidgets('faltou palavra: cada uma que faltou é erro', (tester) async {
      final c = await abrir(tester);
      await montar(tester, ['I', 'like']);
      await tester.tap(conferir);
      await tester.pump();
      expect(c.erros, [
        {7: 1}
      ]);
      expect(erro, findsOneWidget);
    });
  });

  group('não sei, troca de frase e frase sem palavras', () {
    testWidgets('"não sei" avisa e some quando não vale (cópia)', (tester) async {
      final c = await abrir(tester);
      await tester.tap(naoSei);
      await tester.pump();
      expect(c.naoSei, 1);
      await abrir(tester, podeNaoSei: false);
      expect(naoSei, findsNothing);
      expect(conferir, findsOneWidget);
    });

    testWidgets('limpar() recomeça a montagem (o "não sei" revelou a frase)', (tester) async {
      await abrir(tester);
      await montar(tester, ['I', 'like']);
      estado(tester).limpar();
      await tester.pump();
      expect(naFrase(tester), isEmpty);
      expect(find.textContaining('Toque nos blocos abaixo'), findsOneWidget);
    });

    testWidgets('frase nova (passo seguinte): blocos novos e a montagem zerada', (tester) async {
      await abrir(tester);
      await montar(tester, ['I', 'like']);
      await tester.pumpWidget(MaterialApp(
        theme: Mixart.tema(),
        home: Scaffold(
          body: MontagemFrase(frase: 'We go home.', apoio: _apoio, semente: 4, onErrou: (_) {}, onCerta: () {}, onNaoSei: () {}),
        ),
      ));
      expect(naFrase(tester), isEmpty);
      expect(estado(tester).blocos.where((b) => !b.distrator).map((b) => b.texto).toSet(), {'We', 'go', 'home'});
    });

    testWidgets('frase sem palavra nenhuma: não há o que montar e dá para continuar', (tester) async {
      final c = await abrir(tester, frase: '...');
      expect(find.textContaining('não tem palavras'), findsOneWidget);
      await tester.tap(find.byKey(const Key('montagem-continuar')));
      await tester.pump();
      expect(c.certas, 1);
    });
  });

  group('sem estouro', () {
    const longa = 'She is going to the market with her sister and their little brother to buy fresh bread cheese milk and some '
        'sweet red apples for the big party tonight.';
    for (final tamanho in const [Size(360, 740), Size(390, 844), Size(1027, 800)]) {
      for (final claro in [false, true]) {
        testWidgets('${tamanho.width.toInt()} px, ${claro ? 'tema claro' : 'tema escuro'}, fonte grande, 25+ palavras', (tester) async {
          final antes = Mixart.atual;
          addTearDown(() => Mixart.atual = antes);
          if (claro) Mixart.atual = Paleta.flutterClaro;
          await abrir(tester, frase: longa, tamanho: tamanho, fonte: 1.3);
          await montar(tester, longa.replaceAll('.', '').split(' ').take(12).toList());
          await tester.ensureVisible(conferir);
          await tester.pump();
          await tester.tap(conferir);
          await tester.pump();
          expect(erro, findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('SeletorEntrada', () {
    Future<List<EntradaResposta>> abrirSeletor(
      WidgetTester tester, {
      EntradaResposta entrada = EntradaResposta.digitar,
      bool falar = true,
      Size tamanho = const Size(390, 844),
      double fonte = 1,
    }) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final mudou = <EntradaResposta>[];
      await tester.pumpWidget(MaterialApp(
        theme: Mixart.tema(),
        builder: (context, filho) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(fonte)), child: filho!),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: SeletorEntrada(entrada: entrada, falarDisponivel: falar, onMudar: mudou.add),
          ),
        ),
      ));
      return mudou;
    }

    testWidgets('três pílulas; tocar em cada uma avisa o modo', (tester) async {
      final mudou = await abrirSeletor(tester);
      for (final e in EntradaResposta.values) {
        expect(find.byKey(Key('entrada-${e.id}')), findsOneWidget);
        expect(find.text('${e.emoji} ${e.rotulo}'), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('entrada-montar')));
      await tester.tap(find.byKey(const Key('entrada-falar')));
      await tester.tap(find.byKey(const Key('entrada-digitar')));
      expect(mudou, [EntradaResposta.montar, EntradaResposta.falar, EntradaResposta.digitar]);
    });

    testWidgets('sem reconhecimento de voz o Falar some e sobram Digitar e Montar', (tester) async {
      await abrirSeletor(tester, falar: false);
      expect(find.byKey(const Key('entrada-falar')), findsNothing);
      expect(find.byKey(const Key('entrada-digitar')), findsOneWidget);
      expect(find.byKey(const Key('entrada-montar')), findsOneWidget);
    });

    testWidgets('a pílula do modo atual é a destacada (só uma)', (tester) async {
      for (final e in EntradaResposta.values) {
        await abrirSeletor(tester, entrada: e);
        final marcadas = [
          for (final o in EntradaResposta.values)
            if (tester.widget<Material>(find.ancestor(of: find.byKey(Key('entrada-${o.id}')), matching: find.byType(Material)).first).color ==
                Mixart.brand)
              o
        ];
        expect(marcadas, [e]);
      }
    });

    for (final tamanho in const [Size(320, 640), Size(360, 740), Size(1027, 800)]) {
      for (final claro in [false, true]) {
        testWidgets('${tamanho.width.toInt()} px, ${claro ? 'tema claro' : 'tema escuro'}, fonte grande: sem estouro', (tester) async {
          final antes = Mixart.atual;
          addTearDown(() => Mixart.atual = antes);
          if (claro) Mixart.atual = Paleta.flutterClaro;
          await abrirSeletor(tester, tamanho: tamanho, fonte: 1.5);
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byType(SeletorEntrada)).width, lessThanOrEqualTo(tamanho.width));
        });
      }
    }
  });
}
