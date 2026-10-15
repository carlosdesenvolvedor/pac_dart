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
import 'package:pac_dart/features/ingles/domain/limpar_traducao.dart';
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

    int pal(String f) => RegExp(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*").allMatches(f).length;

    test('o limite do texto colado é 12 palavras por exercício (o do curso, 25, é outro)', () {
      expect(maxPalavrasDoTextoColado, 12);
      expect(maxPalavrasPorFrase, 25);
    });

    test('frase de até 12 palavras fica inteira, mesmo com vírgula', () {
      expect(_frases('When I got home, I made some tea and read a book.'), ['When I got home, I made some tea and read a book.']);
      expect(_frases('One two three four five six seven eight nine ten eleven twelve.').length, 1);
    });

    test('corta antes de "and": o texto de 16 palavras vira dois exercícios curtos', () {
      expect(_frases('Yesterday I went to the big market near my house and bought some fresh cheese for dinner.'), [
        'Yesterday I went to the big market near my house',
        'and bought some fresh cheese for dinner.',
      ]);
    });

    test('corta antes de because, but, when, which, who, if, after… (e sem ligar para maiúscula)', () {
      for (final c in ['because', 'but', 'when', 'which', 'who', 'if', 'after', 'before', 'until', 'since', 'although', 'where', 'or', 'then']) {
        final f = 'The little brown dog likes to run around the park $c the sun goes down every evening.';
        final r = _frases(f);
        expect(r.length, 2, reason: c);
        expect(r.last.startsWith(c), isTrue, reason: '$c: ${r.last}');
        expect(r.join(' '), f);
      }
    });

    test('prefere a vírgula/ponto e vírgula a cortar antes de uma conjunção', () {
      // o corte da vírgula (10 + 10) vale mais que o "and" (16 + 4), mesmo havendo os dois
      final r = _frases('Every morning before school my brother walks to the park, he plays football with his friends and returns home late.');
      expect(r, ['Every morning before school my brother walks to the park,', 'he plays football with his friends and returns home late.']);
    });

    test('nenhum pedaço fica com menos de 3 palavras ("However," sozinho não é exercício)', () {
      // a única vírgula deixa "However," (1 palavra) sozinho: não corta (15 palavras cabem na folga de 1,5×)
      const f = 'However, everybody remembers those wonderful sunny holidays spent near beautiful distant snowy mountains during childhood.';
      expect(pal(f), 15);
      expect(_frases(f), [f]);
      // e quando corta, nenhum pedaço fica com menos de 3 palavras
      for (final p in _frases('However, the old teacher who lived near the river decided to walk home after the long meeting ended.')) {
        expect(pal(p), greaterThanOrEqualTo(3), reason: p);
      }
    });

    test('frase um pouco acima de 12, sem onde cortar, fica inteira (até 1,5×)', () {
      final f = 'Everybody remembers those wonderful sunny holidays spent near beautiful distant snowy mountains during childhood forever.';
      expect(pal(f), greaterThan(12));
      expect(_frases(f), [f]);
      final sem = [for (var i = 0; i < 18; i++) 'w${String.fromCharCode(97 + i ~/ 26)}${String.fromCharCode(97 + i % 26)}'].join(' ');
      expect(_frases('$sem.'), ['$sem.']);
    });

    test('texto de estudo de verdade (Jack Hannaford): sai igual ao "texto linha a linha" de um professor', () {
      const texto = 'In those days, there also lived an old soldier called Jack Hannaford. His coat was old and he was poor, '
          'but nobody thought that Jack Hannaford was stupid. He was sly like a fox. When he left the army, he walked all '
          'around the country, looking for ways to play his tricks. After he had traveled for some time, he came across '
          'the farm belonging to the pair. He knocked on the door of the house, and a moment later, the wife answered. '
          'She looked him up and down, quite astonished, because few strangers were able to make the difficult journey '
          'to their home. “Where did you come from?” she asked.';
      expect(_frases(texto), [
        'In those days, there also lived an old soldier called Jack Hannaford.',
        'His coat was old and he was poor,',
        'but nobody thought that Jack Hannaford was stupid.',
        'He was sly like a fox.',
        'When he left the army,',
        'he walked all around the country,',
        'looking for ways to play his tricks.',
        'After he had traveled for some time,',
        'he came across the farm belonging to the pair.',
        'He knocked on the door of the house,',
        'and a moment later, the wife answered.',
        'She looked him up and down, quite astonished,',
        'because few strangers were able to make the difficult journey to their home.',
        '"Where did you come from?" she asked.',
      ]);
    });

    test('cada pedaço é um trecho com sentido: nunca começa no meio de uma ideia nem sobra "trecho solto" de 1–2 palavras', () {
      const texto = 'When he left the army, he walked all around the country, looking for ways to play his tricks. '
          'She looked him up and down, quite astonished, because few strangers were able to make the difficult journey to their home.';
      for (final f in _frases(texto)) {
        expect(pal(f), greaterThanOrEqualTo(5), reason: f);
      }
      // "quite astonished," (2 palavras) gruda na frase de antes em vez de virar exercício sozinho
      expect(_frases(texto), contains('She looked him up and down, quite astonished,'));
      expect(_frases(texto).any((f) => f.trim().toLowerCase() == 'quite astonished,'), isFalse);
    });

    test('frase de EXATAMENTE 12 palavras fica inteira, mesmo havendo um bom corte no meio (5 + 7)', () {
      const f = 'My sister lives in London, and my brother lives in Paris now.';
      expect(pal(f), 12);
      expect(_frases(f), [f]);
      // com 13 palavras já corta
      const g = 'My sister lives in London, and my brother lives in Paris right now.';
      expect(pal(g), 13);
      expect(_frases(g), ['My sister lives in London,', 'and my brother lives in Paris right now.']);
    });

    test('quando vírgula e conjunção competem, a vírgula (corte natural) ganha mesmo que o "while" desse pedaços mais iguais', () {
      expect(
        _frases('Every evening my grandfather reads the newspaper, he drinks tea while my grandmother cooks dinner.'),
        ['Every evening my grandfather reads the newspaper,', 'he drinks tea while my grandmother cooks dinner.'],
      );
    });

    test('ponto e vírgula e dois-pontos também são cortes naturais (sem nenhuma vírgula na frase)', () {
      expect(_frases('The storm was very strong that night; nobody in the small village slept at all until morning came.'), [
        'The storm was very strong that night;',
        'nobody in the small village slept at all until morning came.',
      ]);
      expect(_frases('He had only one rule for his students: always read the whole question before writing anything down.'), [
        'He had only one rule for his students:',
        'always read the whole question before writing anything down.',
      ]);
    });

    test('frase pouco acima do limite não vira pedaço minúsculo: "Last summer my family" não existe', () {
      // 14 e 15 palavras: o único corte possível deixaria 4 ou 3 palavras de um lado ⇒ fica inteira
      const a = 'Last summer my family and I travelled to a small town on the coast.';
      const b = 'While my mother and my sister set the table under the trees in the garden.';
      expect(pal(a), 14);
      expect(pal(b), 15);
      expect(_frases(a), [a]);
      expect(_frases(b), [b]);
    });

    test('mas se os dois lados ficam com 5 palavras ou mais, corta (14 palavras, "and" no meio)', () {
      const f = 'Last summer my whole family travelled to a small town and rented an old house.';
      expect(pal(f), 15);
      expect(_frases(f), ['Last summer my whole family travelled to a small town', 'and rented an old house.']);
    });

    test('frase MUITO comprida (mais de 18 palavras) sem onde cortar é partida entre palavras, perto do meio', () {
      // palavras diferentes (frases idênticas seriam deduplicadas)
      final sem = [for (var i = 0; i < 40; i++) 'w${String.fromCharCode(97 + i ~/ 26)}${String.fromCharCode(97 + i % 26)}'].join(' ');
      final r = _frases('$sem.');
      expect(r.length, greaterThan(2));
      for (final f in r) {
        expect(pal(f), lessThanOrEqualTo(maxPalavrasDoTextoColado), reason: f);
        expect(pal(f), greaterThanOrEqualTo(3), reason: f);
      }
      expect(r.join(' '), '$sem.');
    });

    test('depois de cortar, nenhum pedaço passa do limite quando há onde cortar, e nada se perde', () {
      const t = 'Yesterday I went to the big market near my house and bought some fresh cheese for dinner. '
          'When the storm finally reached the small village on the coast, the fishermen had already pulled their boats onto the beach; '
          'the children, who had been playing near the harbor all afternoon, ran home. '
          'My sister works in a hospital because she wants to help people who are sick.';
      final r = dividirEmFrases(t);
      expect(r.frases.length, greaterThan(4));
      for (final f in r.frases) {
        expect(pal(f), lessThanOrEqualTo(maxPalavrasDoTextoColado + 1), reason: f);
        expect(RegExp(r'^[\x20-\x7E]+$').hasMatch(f), isTrue, reason: f);
      }
      expect(r.frases.join(' '), t);
    });

    test('conta quantas frases foram partidas (para a tela avisar)', () {
      expect(dividirEmFrases('I like tea. She lives in London.').partidas, 0);
      expect(
          dividirEmFrases('Yesterday I went to the big market near my house and bought some fresh cheese for dinner. I like tea.').partidas,
          1);
      expect(dividirEmFrases('').partidas, 0);
    });

    test('o limite pode ser trocado (maxPalavras)', () {
      const f = 'Yesterday I went to the big market near my house and bought some fresh cheese for dinner.';
      expect(dividirEmFrases(f, maxPalavras: 25).frases, [f]);
      // com 8: corta antes do "and" (10 + 7); o pedaço de 10 cabe na folga de 1,5× e fica inteiro
      expect(dividirEmFrases(f, maxPalavras: 8).frases.length, 2);
      expect(dividirEmFrases(f, maxPalavras: 5).frases.length, greaterThan(2));
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

  group('limparTraducao', () {
    final tabela = <String, String>{
      '<g id="1">mas ninguém achava </g>que Jack Hannaford era estúpido.': 'mas ninguém achava que Jack Hannaford era estúpido.',
      'Ele <x id="2"/>foi <bx id="3"/>embora<ex id="3"/>.': 'Ele foi embora.',
      '<g id="1"><g id="2">Olá</g>, mundo</g>': 'Olá, mundo',
      'um<br/>dois e <b>três</b>': 'um dois e três',
      // as marcas também chegam ESCAPADAS (&lt;…&gt;), e até escapadas duas vezes
      '&lt;g id=&quot;1&quot;&gt;mas&lt;/g&gt; sim': 'mas sim',
      '&amp;lt;g id=&amp;quot;1&amp;quot;&amp;gt;mas&amp;lt;/g&amp;gt; sim': 'mas sim',
      // entidades e espaços de sempre
      'Ele disse &quot;n&#227;o&quot;  &amp; foi.': 'Ele disse "não" & foi.',
      'a&nbsp;b': 'a b',
      '  muitos    espaços\n e linha  ': 'muitos espaços e linha',
      // o que NÃO é marca fica como está
      '3 < 5 e 7 > 2': '3 < 5 e 7 > 2',
      'eu <3 você': 'eu <3 você',
      'eu <3 você e 7 > 2': 'eu <3 você e 7 > 2', // o `>` lá na frente não pode transformar "<3 …" em marca
      'a<b': 'a<b',
      'Frase normal, sem nada.': 'Frase normal, sem nada.',
      '': '',
      '<g id="1"></g>': '',
    };
    tabela.forEach((entrada, esperado) {
      test('"${entrada.replaceAll('\n', '\\n')}"', () => expect(limparTraducao(entrada), esperado));
    });

    test('é idempotente (limpar de novo não muda nada)', () {
      for (final e in tabela.keys) {
        final uma = limparTraducao(e);
        expect(limparTraducao(uma), uma, reason: e);
      }
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

    test('texto salvo ANTES da correção, com marca do MyMemory na tradução, volta limpo (sem refazer a lição)', () {
      final t = TextoSalvo.fromJson({
        'id': 'jack',
        'titulo': 'Jack',
        'criadoEm': 1000,
        'frases': [
          {'en': 'but nobody thought that Jack Hannaford was stupid.', 'pt': '<g id="1">mas ninguém achava </g>que Jack Hannaford era estúpido.'},
          {'en': 'He was sly like a fox.', 'pt': 'Ele era astuto como uma raposa.'},
          {'en': 'Then I have breakfast with my sister.', 'pt': 'Depois tomo <x id="3"/>café com minha irmã.', 'alvo': 'breakfast', 'alvoPt': '<g id="2">café</g>'},
        ],
      })!;
      expect(t.frases[0].pt, 'mas ninguém achava que Jack Hannaford era estúpido.');
      expect(t.frases[1].pt, 'Ele era astuto como uma raposa.');
      expect(t.frases[2].pt, 'Depois tomo café com minha irmã.');
      expect(t.frases[2].alvoPt, 'café');
      expect(t.comoTrilha().licoes.first.trechos.first.dica, 'mas ninguém achava que Jack Hannaford era estúpido.');
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

    test('tira as marcas de formatação do MyMemory (<g id="1">…</g>): o caso real do "Jack Hannaford"', () async {
      final t = TradutorMyMemory(
          client: MockClient((_) async => _json(_ok('<g id="1">mas ninguém achava </g>que Jack Hannaford era estúpido.'))));
      expect(await t.traduzir(['but nobody thought that Jack Hannaford was stupid.']),
          ['mas ninguém achava que Jack Hannaford era estúpido.']);
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

    testWidgets('frase comprida é dividida em pedaços curtos, a tela avisa e a tradução recebe os pedaços', (tester) async {
      final fake = _TradutorFalso();
      await abrir(tester, fake);
      await tester.enterText(find.byKey(const Key('texto-colado')),
          'Yesterday I went to the big market near my house and bought some fresh cheese for dinner. I like tea.');
      await tester.pump();
      expect(find.text('3 frases · 1 lição'), findsOneWidget, reason: 'a de 16 palavras virou 2 pedaços + "I like tea."');
      expect(find.byKey(const Key('aviso-divididas')), findsOneWidget);
      expect(find.textContaining('1 frase comprida foi dividida em pedaços curtos'), findsOneWidget);
      await tester.tap(find.byKey(const Key('botao-traduzir')));
      await tester.pumpAndSettle();
      expect(fake.recebidas, [
        'Yesterday I went to the big market near my house',
        'and bought some fresh cheese for dinner.',
        'I like tea.',
      ]);
    });

    testWidgets('texto de frases curtas: nenhum aviso de divisão', (tester) async {
      await abrir(tester, _TradutorFalso());
      await tester.enterText(find.byKey(const Key('texto-colado')), 'I like tea. She lives in London.');
      await tester.pump();
      expect(find.byKey(const Key('aviso-divididas')), findsNothing);
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
