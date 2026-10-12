import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pac_dart/core/linguagem/linguagem.dart';
import 'package:pac_dart/features/curso/data/curriculo_loader.dart';
import 'package:pac_dart/features/curso/data/progresso_repository.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/presentation/bloc/curso_bloc.dart';
import 'package:pac_dart/features/dartpad/mapa_rodavel.dart';
import 'package:pac_dart/features/ingles/data/textos_repository.dart';
import 'package:pac_dart/features/ingles/data/tradutor.dart';
import 'package:pac_dart/features/ingles/domain/texto_para_frases.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';
import 'package:pac_dart/features/ingles/presentation/fixacao.dart';
import 'package:pac_dart/features/ingles/presentation/texto_para_licao_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<String> _frases(String t) => dividirEmFrases(t).frases;

http.Response _json(Object corpo, [int status = 200]) =>
    http.Response.bytes(utf8.encode(jsonEncode(corpo)), status, headers: {'content-type': 'application/json'});

Map<String, Object> _ok(String pt) => {
      'responseData': {'translatedText': pt, 'match': 0.85},
      'responseStatus': 200,
      'quotaFinished': false,
    };

void main() {
  group('dividirEmFrases', () {
    test('separa em frases e mantém a pontuação', () {
      expect(_frases('I like tea. Do you like coffee? Yes! I do.'), [
        'I like tea.',
        'Do you like coffee?',
        'Yes!',
        'I do.',
      ]);
    });

    test('não parte abreviações, iniciais nem decimais', () {
      expect(_frases('Mr. Smith paid 3.50 dollars. J. K. Rowling wrote it, e.g. in 1997. Then she left.'), [
        'Mr. Smith paid 3.50 dollars.',
        'J. K. Rowling wrote it, e.g. in 1997.',
        'Then she left.',
      ]);
    });

    test('"I." e "A." no fim fecham a frase', () {
      expect(_frases('So do I. Plan A. Then go.'), ['So do I.', 'Plan A.', 'Then go.']);
    });

    test('fala entre aspas: o "ele disse" fica junto, a próxima fala começa outra frase', () {
      expect(_frases('"Stop!" he yelled. "Go away." Then he left.'), [
        '"Stop!" he yelled.',
        '"Go away."',
        'Then he left.',
      ]);
    });

    test('linha quebrada no meio da frase (texto de PDF) é juntada; linha em branco separa', () {
      expect(_frases('The quick brown fox\njumps over the lazy dog.\n\nA new paragraph starts here.'), [
        'The quick brown fox jumps over the lazy dog.',
        'A new paragraph starts here.',
      ]);
    });

    test('uma frase por linha, sem ponto, continua uma por linha; marcadores de lista saem', () {
      expect(_frases('- Apples\n- Oranges\n1. Bananas'), ['Apples', 'Oranges', 'Bananas']);
      expect(_frases('Good morning\nHow are you\nFine'), ['Good morning', 'How are you', 'Fine']);
    });

    test('tira repetidas (sem ligar para maiúscula) e o que não tem letra', () {
      expect(_frases('Hello there. HELLO THERE.\n***\n12345.\nBye.'), ['Hello there.', 'Bye.']);
    });

    test('simplifica o que o teclado não escreve e avisa', () {
      final r = dividirEmFrases('She said, “It’s a café — really…” See https://exemplo.com now. 😀');
      expect(r.simplificou, isTrue);
      expect(r.frases, ['She said, "It\'s a cafe - really..."', 'See now.']);
      // tudo o que sobra se digita
      for (final f in r.frases) {
        expect(RegExp(r'^[\x20-\x7E]+$').hasMatch(f), isTrue, reason: f);
      }
    });

    test('texto já simples não "simplificou"', () {
      expect(dividirEmFrases('Plain text. Nothing odd.').simplificou, isFalse);
    });

    test('intervalo com travessão vira hífen', () {
      expect(_frases('He lived 1990–2000 in Rome.'), ['He lived 1990-2000 in Rome.']);
    });

    test('frase comprida é cortada no ponto e vírgula / vírgula mais equilibrado', () {
      const longa = 'When the storm finally reached the small village on the coast, the fishermen had already pulled '
          'their boats onto the beach; the children, who had been playing near the harbor all afternoon, ran home.';
      final r = _frases(longa);
      expect(r.length, greaterThan(1));
      for (final f in r) {
        expect(RegExp(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*").allMatches(f).length, lessThanOrEqualTo(maxPalavrasPorFrase),
            reason: f);
      }
      expect(r.join(' '), longa);
    });

    test('frase comprida sem onde cortar fica inteira', () {
      final sem = List.filled(40, 'word').join(' ');
      expect(_frases('$sem.'), ['$sem.']);
    });

    test('corta no limite e conta o total', () {
      final texto = [for (var i = 0; i < 12; i++) 'Sentence number ${String.fromCharCode(97 + i)} here.'].join(' ');
      final r = dividirEmFrases(texto, maxFrases: 5);
      expect(r.frases.length, 5);
      expect(r.cortado, isTrue);
      expect(r.total, 12);
    });

    test('texto vazio ou só símbolos não dá frase', () {
      expect(dividirEmFrases('   \n\n ').frases, isEmpty);
      expect(dividirEmFrases('🙂🙂 ... 123').frases, isEmpty);
    });
  });

  group('repartirEmLicoes', () {
    test('equilibra: 17 → 6+6+5, 9 → 5+4, 8 → 8, 0 → nada', () {
      List<int> tam(int n) => repartirEmLicoes(List.generate(n, (i) => i)).map((l) => l.length).toList();
      expect(tam(17), [6, 6, 5]);
      expect(tam(9), [5, 4]);
      expect(tam(8), [8]);
      expect(tam(1), [1]);
      expect(tam(0), isEmpty);
    });
  });

  test('título automático: as 5 primeiras palavras da 1ª frase', () {
    expect(tituloDaPrimeiraFrase(["it's a long way to Tipperary, my friend."]), "It's a long way to");
    expect(tituloDaPrimeiraFrase(['Hello!']), 'Hello');
    expect(tituloDaPrimeiraFrase(const []), 'Meu texto');
  });

  group('TextoSalvo', () {
    final texto = TextoSalvo(
      id: 'abc',
      titulo: 'Minha viagem',
      criadoEm: DateTime.fromMillisecondsSinceEpoch(1000),
      frases: [for (var i = 1; i <= 10; i++) FraseDoTexto('Sentence $i.', 'Frase $i.')],
    );

    test('vira uma trilha própria com lições "Parte N" e ids estáveis', () {
      final t = texto.comoTrilha();
      expect(t.propria, isTrue);
      expect(t.nivel, 'Minha viagem');
      expect(t.etapa, TextoSalvo.etapa);
      expect(t.licoes.map((l) => l.nome), ['Parte 1', 'Parte 2']);
      expect(t.licoes.map((l) => l.id), ['txt-abc-1', 'txt-abc-2']);
      expect(t.licoes.map((l) => l.trechos.length), [5, 5]);
      expect(t.licoes.first.trechos.first.cod, 'Sentence 1.');
      expect(t.licoes.first.trechos.first.dica, 'Frase 1.');
      expect(t.licoes.first.trechos.first.audio, isEmpty); // sem gravação: voz sintética
    });

    test('ida e volta em JSON; registro quebrado vira null', () {
      expect(TextoSalvo.fromJson(jsonDecode(jsonEncode(texto.toJson()))), texto);
      expect(TextoSalvo.fromJson({'id': 'x'}), isNull);
      expect(TextoSalvo.fromJson('lixo'), isNull);
      expect(TextoSalvo.fromJson({'id': 'x', 'titulo': 't', 'frases': []}), isNull);
    });
  });

  group('TradutorMyMemory', () {
    test('traduz na ordem, em paralelo, e avisa o progresso', () async {
      final progresso = <int>[];
      final t = TradutorMyMemory(
        client: MockClient((r) async {
          final q = r.url.queryParameters['q']!;
          expect(r.url.host, 'api.mymemory.translated.net');
          expect(r.url.queryParameters['langpair'], 'en|pt-BR');
          // quanto mais curta, mais rápida: se a ordem não fosse guardada, embaralharia
          await Future<void>.delayed(Duration(milliseconds: 40 - q.length));
          return _json(_ok('PT:$q'));
        }),
      );
      final r = await t.traduzir(['aaaa', 'bb', 'c', 'dddd', 'ee'], aoProgredir: (f, total) {
        expect(total, 5);
        progresso.add(f);
      });
      expect(r, ['PT:aaaa', 'PT:bb', 'PT:c', 'PT:dddd', 'PT:ee']);
      expect(progresso, [1, 2, 3, 4, 5]);
    });

    test('decodifica entidades HTML e arruma espaços', () async {
      final t = TradutorMyMemory(client: MockClient((_) async => _json(_ok('Ele disse &quot;n&#227;o&quot;  &amp; foi.'))));
      expect(await t.traduzir(['x']), ['Ele disse "não" & foi.']);
    });

    test('o aviso de cota NUNCA vira tradução: falha com o tempo de espera e guarda o que já foi', () async {
      var chamadas = 0;
      var cota = false;
      final t = TradutorMyMemory(
        simultaneas: 1,
        client: MockClient((r) async {
          chamadas++;
          final q = r.url.queryParameters['q']!;
          if (cota && q == 'segunda') {
            return _json({
              'responseData': {
                'translatedText': 'MYMEMORY WARNING: YOU USED ALL AVAILABLE FREE TRANSLATIONS FOR TODAY. '
                    'NEXT AVAILABLE IN  05 HOURS 54 MINUTES 31 SECONDS VISIT https://mymemory.translated.net'
              },
              'responseStatus': 429,
              'quotaFinished': true,
            });
          }
          return _json(_ok('PT:$q'));
        }),
      );
      cota = true;
      Object? erro;
      try {
        await t.traduzir(['primeira', 'segunda', 'terceira']);
      } catch (e) {
        erro = e;
      }
      expect(erro, isA<TraducaoFalhou>());
      expect((erro as TraducaoFalhou).cota, isTrue);
      expect(erro.mensagem, contains('limite de hoje'));
      expect(erro.mensagem, contains('5 h 54 min'));
      expect(erro.mensagem, isNot(contains('MYMEMORY')));
      final antes = chamadas;

      // amanhã: a "primeira" já está guardada, só faltam as outras
      cota = false;
      final r = await t.traduzir(['primeira', 'segunda', 'terceira']);
      expect(r, ['PT:primeira', 'PT:segunda', 'PT:terceira']);
      expect(chamadas - antes, 2);
    });

    test('HTTP 429 também é cota', () async {
      final t = TradutorMyMemory(client: MockClient((_) async => http.Response('Too many', 429)));
      await expectLater(t.traduzir(['x']), throwsA(isA<TraducaoFalhou>().having((e) => e.cota, 'cota', isTrue)));
    });

    test('sem rede: tenta duas vezes e desiste com recado em português', () async {
      var chamadas = 0;
      final t = TradutorMyMemory(
        simultaneas: 1,
        client: MockClient((_) async {
          chamadas++;
          throw http.ClientException('sem rede');
        }),
      );
      await expectLater(
          t.traduzir(['x']), throwsA(isA<TraducaoFalhou>().having((e) => e.mensagem, 'mensagem', contains('internet'))));
      expect(chamadas, 2);
    });

    test('resposta vazia ou quebrada falha em vez de gravar lixo', () async {
      for (final corpo in [_json(_ok('   ')), http.Response('<html>oops</html>', 200)]) {
        final t = TradutorMyMemory(client: MockClient((_) async => corpo));
        await expectLater(t.traduzir(['x']), throwsA(isA<TraducaoFalhou>()));
      }
    });

    test('frase enorme vai em pedaços de até 400 caracteres e volta inteira', () async {
      final tamanhos = <int>[];
      final t = TradutorMyMemory(
        client: MockClient((r) async {
          final q = r.url.queryParameters['q']!;
          tamanhos.add(q.length);
          return _json(_ok(q.toUpperCase()));
        }),
      );
      final enorme = List.filled(150, 'palavra').join(' ');
      final r = await t.traduzir([enorme]);
      expect(tamanhos.length, greaterThan(1));
      expect(tamanhos.every((n) => n <= 400), isTrue);
      expect(r.single, enorme.toUpperCase());
    });
  });

  group('LocalTextosRepository', () {
    TextoSalvo texto(String id, int ms) => TextoSalvo(
          id: id,
          titulo: 'T $id',
          criadoEm: DateTime.fromMillisecondsSinceEpoch(ms),
          frases: [FraseDoTexto('Hi $id.', 'Oi $id.')],
        );

    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('guarda, lista do mais novo ao mais antigo, regrava o mesmo id e apaga', () async {
      final repo = LocalTextosRepository('u1');
      expect(await repo.carregar(), isEmpty);
      await repo.salvar(texto('a', 1000));
      await repo.salvar(texto('b', 3000));
      await repo.salvar(texto('c', 2000));
      expect((await repo.carregar()).map((t) => t.id), ['b', 'c', 'a']);
      await repo.salvar(TextoSalvo(id: 'a', titulo: 'Novo título', criadoEm: DateTime.fromMillisecondsSinceEpoch(1000), frases: texto('a', 0).frases));
      expect((await repo.carregar()).firstWhere((t) => t.id == 'a').titulo, 'Novo título');
      await repo.apagar('c');
      expect((await repo.carregar()).map((t) => t.id), ['b', 'a']);
    });

    test('cada conta tem os seus textos', () async {
      await LocalTextosRepository('u1').salvar(texto('a', 1));
      expect(await LocalTextosRepository('u2').carregar(), isEmpty);
      expect((await LocalTextosRepository('u1').carregar()).length, 1);
    });

    test('dado quebrado no armazenamento não derruba: só vem vazio', () async {
      SharedPreferences.setMockInitialValues({'en_textos_u1': '{{{ não é json'});
      expect(await LocalTextosRepository('u1').carregar(), isEmpty);
      SharedPreferences.setMockInitialValues({'en_textos_u1': '{"a":1}'});
      expect(await LocalTextosRepository('u1').carregar(), isEmpty);
    });
  });

  group('CursoBloc com textos colados', () {
    final curso = [
      Trilha(
        nivel: 'Primeiros Passos',
        emoji: '👋',
        etapa: 'A1 · Fundação',
        licoes: const [
          Licao(id: 'a1.um', nome: 'Um', emoji: '1', trechos: [Trecho(cod: 'Hi.', dica: 'Oi.', out: '')]),
          Licao(id: 'a1.dois', nome: 'Dois', emoji: '2', trechos: [Trecho(cod: 'Bye.', dica: 'Tchau.', out: '')]),
        ],
      ),
    ];
    TextoSalvo texto(String id, int ms, [int n = 10]) => TextoSalvo(
          id: id,
          titulo: 'Texto $id',
          criadoEm: DateTime.fromMillisecondsSinceEpoch(ms),
          frases: [for (var i = 1; i <= n; i++) FraseDoTexto('Line $i of $id.', 'Linha $i de $id.')],
        );

    Future<CursoBloc> abrir(TextosRepository repo) async {
      final bloc = CursoBloc(loader: _LoaderTeste(curso), progresso: LocalProgressoRepository(prefixo: 'en_'), textos: repo);
      bloc.add(const CursoIniciado());
      await bloc.stream.firstWhere((s) => s.status == CursoStatus.pronto);
      return bloc;
    }

    test('textos salvos entram depois do curso, o mais novo primeiro, e o curso segue sendo o ponto de partida', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalTextosRepository('u');
      await repo.salvar(texto('velho', 1000));
      await repo.salvar(texto('novo', 2000));
      final bloc = await abrir(repo);
      final st = bloc.state;
      expect(st.trilhas.map((t) => t.nivel), ['Primeiros Passos', 'Texto novo', 'Texto velho']);
      expect(st.trilhas.map((t) => t.propria), [false, true, true]);
      expect(st.trilhaIdx, 0);
      expect(st.progressoDoCurso, (2, 0));
      await bloc.close();
    });

    test('TextoCriado guarda, cria a trilha logo depois do curso e cai na 1ª lição dela', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalTextosRepository('u');
      await repo.salvar(texto('antigo', 1000));
      final bloc = await abrir(repo);
      bloc.add(TextoCriado(texto('novo', 2000)));
      final st = await bloc.stream.firstWhere((s) => s.trilhas.length == 3);
      expect(st.trilhas.map((t) => t.textoId), ['', 'novo', 'antigo']);
      expect(st.trilhaIdx, 1);
      expect(st.licaoIdx, 0);
      expect(st.trilha.nivel, 'Texto novo');
      expect(st.licao.id, 'txt-novo-1');
      expect((await repo.carregar()).map((t) => t.id), ['novo', 'antigo']);
      await bloc.close();
    });

    test('terminar a última parte do texto leva de volta ao curso (1ª lição pendente), não ao texto seguinte', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = await abrir(LocalTextosRepository('u'));
      bloc.add(TextoCriado(texto('a', 1000, 4)));
      bloc.add(TextoCriado(texto('b', 2000, 4)));
      await bloc.stream.firstWhere((s) => s.trilhas.length == 3 && s.trilha.textoId == 'b');
      bloc.add(const ProximaLicaoPedida());
      final st = await bloc.stream.firstWhere((s) => !s.trilha.propria);
      expect(st.licao.id, 'a1.um');
      await bloc.close();
    });

    test('concluir lição de texto não entra na conta do curso nem nas estrelas', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = await abrir(LocalTextosRepository('u'));
      bloc.add(TextoCriado(texto('a', 1000, 4)));
      await bloc.stream.firstWhere((s) => s.trilha.propria);
      bloc.add(const LicaoFinalizada());
      final st = await bloc.stream.firstWhere((s) => s.vitoria);
      expect(st.concluidas, {'txt-a-1'});
      expect(st.progressoDoCurso, (2, 0));
      await bloc.close();
    });

    test('TextoApagado tira a trilha, guarda a mudança e, se estava nela, volta ao curso', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = LocalTextosRepository('u');
      final bloc = await abrir(repo);
      bloc.add(TextoCriado(texto('a', 1000, 4)));
      await bloc.stream.firstWhere((s) => s.trilha.propria);
      bloc.add(const TextoApagado('a'));
      final st = await bloc.stream.firstWhere((s) => s.trilhas.length == 1);
      expect(st.trilhaIdx, 0);
      expect(st.licao.id, 'a1.um');
      expect(await repo.carregar(), isEmpty);
      await bloc.close();
    });

    test('apagar um texto ANTES do atual mantém a seleção no mesmo texto', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = await abrir(LocalTextosRepository('u'));
      bloc.add(TextoCriado(texto('a', 1000, 4)));
      bloc.add(TextoCriado(texto('b', 2000, 4)));
      await bloc.stream.firstWhere((s) => s.trilhas.length == 3 && s.trilha.textoId == 'b');
      bloc.add(const TrilhaSelecionada(2)); // o texto "a"
      await bloc.stream.firstWhere((s) => s.trilhaIdx == 2);
      bloc.add(const TextoApagado('b'));
      final st = await bloc.stream.firstWhere((s) => s.trilhas.length == 2);
      expect(st.trilha.textoId, 'a');
      await bloc.close();
    });

    test('o nivelamento não trata "Meus textos" como um nível do curso', () {
      final trilhas = [...curso, texto('a', 1).comoTrilha()];
      expect(etapasDoCurso(trilhas), ['A1 · Fundação']);
    });
  });

  group('TextoParaLicaoPage', () {
    Future<_Saida> abrir(WidgetTester tester, Tradutor tradutor, {String texto = ''}) async {
      tester.view.physicalSize = const Size(1000, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final saida = _Saida();
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              saida.valor = await Navigator.of(context).push<TextoSalvo>(
                MaterialPageRoute(builder: (_) => TextoParaLicaoPage(tradutor: tradutor, textoInicial: texto)),
              );
            },
            child: const Text('abrir'),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return saida;
    }

    testWidgets('cola, vê a contagem, traduz, corrige uma tradução, tira uma frase e cria', (tester) async {
      final fake = _TradutorFalso();
      final saida = await abrir(tester, fake);
      expect(find.byKey(const Key('botao-traduzir')), findsOneWidget);
      expect(tester.widget<FilledButton>(find.byKey(const Key('botao-traduzir'))).onPressed, isNull);

      await tester.enterText(find.byKey(const Key('titulo-texto')), 'Minha viagem');
      await tester.enterText(
          find.byKey(const Key('texto-colado')), 'I went to Rome. It was “great”! We ate pizza. Then we came home.');
      await tester.pump();
      expect(find.text('4 frases · 1 lição'), findsOneWidget);
      expect(find.textContaining('Troquei aspas curvas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pumpAndSettle();
      expect(fake.recebidas, ['I went to Rome.', 'It was "great"!', 'We ate pizza.', 'Then we came home.']);

      // revisão: o inglês e a tradução automática, editável
      expect(find.text('We ate pizza.'), findsOneWidget);
      expect(find.text('PT: We ate pizza.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('pt-2')), 'Comemos pizza.');
      // tira a 2ª frase
      await tester.tap(find.byTooltip('Tirar esta frase').at(1));
      await tester.pumpAndSettle();
      expect(find.text('It was "great"!'), findsNothing);
      expect(find.text('Criar 1 lição · 3 frases'), findsOneWidget);

      await tester.tap(find.byKey(const Key('botao-criar')));
      await tester.pumpAndSettle();
      final t = saida.valor!;
      expect(t.titulo, 'Minha viagem');
      expect(t.frases, const [
        FraseDoTexto('I went to Rome.', 'PT: I went to Rome.'),
        FraseDoTexto('We ate pizza.', 'Comemos pizza.'),
        FraseDoTexto('Then we came home.', 'PT: Then we came home.'),
      ]);
      expect(t.id, isNotEmpty);
    });

    testWidgets('sem título, usa o começo do texto', (tester) async {
      final saida = await abrir(tester, _TradutorFalso(), texto: 'Good morning my dear friends. How are you today?');
      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('botao-criar')));
      await tester.pumpAndSettle();
      expect(saida.valor!.titulo, 'Good morning my dear friends');
    });

    testWidgets('tradução apagada de uma frase trava o "Criar"', (tester) async {
      await abrir(tester, _TradutorFalso(), texto: 'One. Two.');
      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('pt-0')), '   ');
      await tester.pump();
      expect(tester.widget<FilledButton>(find.byKey(const Key('botao-criar'))).onPressed, isNull);
    });

    testWidgets('falha na tradução: mostra o recado, mantém o texto e deixa tentar de novo', (tester) async {
      final fake = _TradutorFalso()..falhas = 1;
      await abrir(tester, fake, texto: 'One. Two.');
      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('erro-traducao')), findsOneWidget);
      expect(find.textContaining('limite de hoje'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(find.text('One. Two.'), findsOneWidget); // o texto colado continua lá

      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('botao-criar')), findsOneWidget);
    });

    testWidgets('"Editar o texto" volta à colagem sem perder nada', (tester) async {
      await abrir(tester, _TradutorFalso(), texto: 'One. Two.');
      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('← Editar o texto'));
      await tester.pumpAndSettle();
      expect(find.text('One. Two.'), findsOneWidget);
      expect(find.byKey(const Key('contagem')), findsOneWidget);
    });

    testWidgets('mostra o andamento enquanto traduz', (tester) async {
      final fake = _TradutorFalso()..segurar = Completer<void>();
      await abrir(tester, fake, texto: 'One. Two. Three.');
      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pump();
      expect(find.text('Traduzindo…'), findsOneWidget);
      expect(find.text('0 de 3 frases'), findsOneWidget);
      fake.segurar!.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('botao-criar')), findsOneWidget);
    });
  });
}

/// O que a tela devolveu ao fechar.
class _Saida {
  TextoSalvo? valor;
}

class _TradutorFalso implements Tradutor {
  final recebidas = <String>[];

  /// As N primeiras chamadas falham com "limite de hoje".
  int falhas = 0;

  /// Espera este completer antes de traduzir (para ver o andamento).
  Completer<void>? segurar;

  @override
  Future<List<String>> traduzir(List<String> frases, {void Function(int feitas, int total)? aoProgredir}) async {
    if (falhas > 0) {
      falhas--;
      throw const TraducaoFalhou('O tradutor grátis chegou ao limite de hoje.', cota: true);
    }
    await segurar?.future;
    recebidas
      ..clear()
      ..addAll(frases);
    for (var i = 1; i <= frases.length; i++) {
      aoProgredir?.call(i, frases.length);
    }
    return [for (final f in frases) 'PT: $f'];
  }
}

class _LoaderTeste extends CurriculoLoader {
  final List<Trilha> trilhas;
  _LoaderTeste(this.trilhas) : super(linguagem: Linguagem.ingles);
  @override
  Future<List<Trilha>> carregar() async => trilhas;
  @override
  Future<List<Projeto>> carregarMaster() async => const [];
  @override
  Future<MapaRodavel> carregarRodaveis() async => MapaRodavel.vazio;
}
