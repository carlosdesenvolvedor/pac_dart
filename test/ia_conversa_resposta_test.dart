import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ia/domain/cenario.dart';
import 'package:pac_dart/features/ia/domain/conversa_resposta.dart';
import 'package:pac_dart/features/ia/domain/sessao_cenario.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';

import 'helpers/tutor_falso.dart' show respostaJson;

/// O modelo do plano (§11): uma resposta completa.
Map<String, Object?> _modelo({
  Object? correcao,
  Object? fala = 'Sure! What size would you like?',
  Object? sugestoes,
  Object? palavras,
  Object? fim = false,
}) =>
    {
      'correcao': correcao ??
          {
            'precisa': true,
            'melhor': 'Can I have a coffee, please?',
            'pt': 'Posso pedir um café, por favor?',
            'porque': '*I want* soa **seco** num pedido; *Can I have* é o jeito educado.',
            'dica': 'Em pedidos, prefira Can I have / I\'d like.',
          },
      'fala': fala,
      'traducao': 'Claro! Qual tamanho você quer?',
      'sugestoes': sugestoes ?? ['Small, please.', 'A large one, please.'],
      'palavras': palavras ??
          [
            {'en': 'size', 'pt': 'tamanho'},
          ],
      'fim': fim,
    };

RespostaTurno? _ler(Object bruto, {String enviada = 'I want a coffee', List<String> trechos = const []}) =>
    RespostaTurno.interpretar(bruto is String ? bruto : jsonEncode(bruto), falaEnviada: enviada, trechos: trechos);

const _cafe = Cenario(
  id: 'cafe',
  titulo: 'Pedir um café',
  emoji: '☕',
  etapa: 'A1',
  papel: 'atendente',
  objetivo: 'Peça uma bebida.',
  abertura: 'Hi! What can I get for you?',
  maxTurnos: 6,
  quem: 'emma',
  nome: 'Emma',
);

void main() {
  group('RespostaTurno.interpretar: onde está o JSON', () {
    test('JSON limpo: tudo no lugar', () {
      final r = _ler(_modelo())!;
      expect(r.estruturada, isTrue);
      expect(r.fala, 'Sure! What size would you like?');
      expect(r.traducao, 'Claro! Qual tamanho você quer?');
      expect(r.correcao!.precisa, isTrue);
      expect(r.correcao!.melhor, 'Can I have a coffee, please?');
      expect(r.correcao!.pt, 'Posso pedir um café, por favor?');
      expect(r.correcao!.porque, contains('**seco**'), reason: 'o porquê guarda o mini-markdown do comNegrito');
      expect(r.correcao!.dica, startsWith('Em pedidos'));
      expect(r.correcao!.comDadosPessoais, isFalse);
      expect(r.sugestoes, ['Small, please.', 'A large one, please.']);
      expect(r.palavras, const [PalavraSugerida('size', 'tamanho')]);
      expect(r.fim, isFalse);
    });

    test('o modelo dos testes (respostaJson) passa inteiro, e "size" passa na regra de palavra', () {
      final r = _ler(respostaJson())!;
      expect(r.correcao!.precisa, isTrue);
      expect(r.correcao!.cartao!.en, 'Can I have a coffee, please?');
      expect(r.palavras, const [PalavraSugerida('size', 'tamanho')]);
      expect(r.sugestoes.length, 2);
      expect(_ler(respostaJson(precisa: false))!.correcao, const CorrecaoTurno(precisa: false));
      expect(_ler(respostaJson(fim: true, fala: 'Bye!'))!.fim, isTrue);
    });

    test('dentro de ```json com texto em volta', () {
      final r = _ler('Claro!\n```json\n${jsonEncode(_modelo())}\n```\nBoa sorte!')!;
      expect(r.estruturada, isTrue);
      expect(r.fala, 'Sure! What size would you like?');
      expect(r.correcao!.precisa, isTrue);
    });

    test('truncado (MAX_TOKENS) depois da fala: salva a fala, sem correção', () {
      final inteiro = jsonEncode({'fala': 'Sure! What "size" do you want?', 'traducao': 'Claro', 'correcao': {'precisa': true}});
      expect(inteiro, contains(r'\"size\"'));
      final r = _ler(inteiro.substring(0, inteiro.length - 25))!;
      expect(r.fala, 'Sure! What "size" do you want?', reason: 'as aspas escapadas voltam');
      expect(r.correcao, isNull);
      expect(r.estruturada, isFalse);
    });

    test('truncado ANTES da fala → null', () {
      expect(_ler('{"correcao":{"precisa":true,"melhor":"Can I'), isNull);
      expect(_ler('{"correcao":{"precisa":false},"fala":"Sure, wha'), isNull, reason: 'a fala não fechou');
    });

    test('texto puro (sem JSON) → só a fala, sem estrutura', () {
      final r = _ler('  Sure! What size?  ')!;
      expect(r, RespostaTurno.simples('Sure! What size?'));
      expect(r.estruturada, isFalse);
      expect(r.correcao, isNull);
      expect(_ler('Sure {small} or large?')!.fala, 'Sure {small} or large?', reason: 'uma chave solta não é JSON');
    });

    test('vazio → null; JSON válido com "fala" vazia, sem fala ou com tipo errado → null', () {
      for (final b in <Object>['', '   ', '```json\n```', _modelo(fala: ''), _modelo(fala: '   '), _modelo(fala: 42), {'traducao': 'x'}, '[1, 2]']) {
        expect(_ler(b), isNull, reason: '$b');
      }
    });

    test('quebra de linha/tab CRUA dentro das strings (JSON no prompt) não perde a correção nem a fala', () {
      // o jsonDecode recusa caractere de controle dentro de string ("Control character in string")
      final noPorque = jsonEncode(_modelo()).replaceFirst('soa', 'soa\n').replaceFirst('Em pedidos,', 'Em pedidos,\t');
      expect(noPorque, contains('\n'));
      final r = _ler(noPorque)!;
      expect(r.estruturada, isTrue);
      expect(r.correcao!.precisa, isTrue);
      expect(r.correcao!.porque, contains('soa **seco**'));
      expect(r.correcao!.porque, isNot(contains('\n')));
      expect(r.sugestoes, isNotEmpty);
      expect(r.palavras, const [PalavraSugerida('size', 'tamanho')]);

      final naFala = jsonEncode(_modelo()).replaceFirst('Sure! What', 'Sure!\nWhat');
      final f = _ler(naFala)!;
      expect(f.fala, 'Sure! What size would you like?');
      expect(f.correcao!.precisa, isTrue);

      // truncado com a quebra crua na fala: o salvamento da fala também tolera
      final cortado = '{"correcao":{"precisa":false},"fala":"Sure!\nWhat size?","tradu';
      expect(_ler(cortado), RespostaTurno.simples('Sure! What size?'));
    });

    test('cerca ```json truncada cedo é JSON quebrado (null), não fala', () {
      for (final b in ['```json\n{"cor', '```json\n{', '```json', '```JSON\n  {"corr', '```\n{"fa']) {
        expect(_ler(b), isNull, reason: b);
      }
      expect(_ler('```\nSure! What size?\n```'), isNull, reason: 'texto todo dentro da cerca continua como antes');
      expect(_ler('```json\n{"fala":"Sure!","tradu')!.fala, 'Sure!', reason: 'a fala inteira ainda é salva');
    });

    test('fala só de emoji/markdown também é vazia → null', () {
      expect(_ler(_modelo(fala: '😀 ** ``` code ```')), isNull);
    });
  });

  group('a correção', () {
    test('precisa sem "melhor" → certinho', () {
      final r = _ler(_modelo(correcao: {'precisa': true, 'porque': 'x'}))!;
      expect(r.correcao, const CorrecaoTurno(precisa: false));
    });

    test('"melhor" igual à fala enviada (tirando maiúsculas, pontuação e espaços) → certinho', () {
      final r = _ler(_modelo(correcao: {'precisa': true, 'melhor': 'Can I have a coffee, please?'}), enviada: 'can i have a coffee please')!;
      expect(r.correcao!.precisa, isFalse);
      expect(_ler(_modelo(correcao: {'precisa': true, 'melhor': '  I want   a coffee. '}))!.correcao!.precisa, isFalse);
    });

    test('precisa=false ou tipo errado → certinho; correção que não é objeto → sem correção', () {
      expect(_ler(_modelo(correcao: {'precisa': false, 'melhor': 'x y'}))!.correcao, const CorrecaoTurno(precisa: false));
      expect(_ler(_modelo(correcao: {'precisa': 'true', 'melhor': 'x y'}))!.correcao!.precisa, isFalse);
      expect(_ler(_modelo(correcao: 'errado'))!.correcao, isNull);
      expect(_ler(_modelo(correcao: ['x']))!.correcao, isNull);
    });

    test('máscara: corrigir só o marcador não é correção (compara com o que foi ENVIADO)', () {
      final r = _ler(
        _modelo(correcao: {'precisa': true, 'melhor': 'My number is [número].', 'pt': 'Meu número é [número].'}),
        enviada: 'My number is [número]',
        trechos: ['+1 305 555 0199'],
      )!;
      expect(r.correcao!.precisa, isFalse);
    });

    test('máscara: correção de verdade volta com o dado original, marcada, e não vira cartão', () {
      final r = _ler(
        _modelo(correcao: {'precisa': true, 'melhor': 'My phone number is [número].', 'pt': 'Meu telefone é [número].', 'porque': 'p'}),
        enviada: 'My number is [número]',
        trechos: ['+1 305 555 0199'],
      )!;
      final c = r.correcao!;
      expect(c.precisa, isTrue);
      expect(c.melhor, 'My phone number is +1 305 555 0199.');
      expect(c.pt, 'Meu telefone é +1 305 555 0199.');
      expect(c.melhor, isNot(contains('[número]')));
      expect(c.comDadosPessoais, isTrue);
      expect(c.cartao, isNull);
    });

    test('marcador TRADUZIDO pelo modelo ([number], [phone number]) também não vira cartão', () {
      for (final melhor in ['Call me at [number].', 'Call me at [phone number].', 'Write to [e-mail].']) {
        final c = _ler(
          _modelo(correcao: {'precisa': true, 'melhor': melhor, 'pt': 'Me ligue nesse número.'}),
          enviada: 'Call me in [número]',
          trechos: ['+1 305 555 0199'],
        )!
            .correcao!;
        expect(c.precisa, isTrue, reason: melhor);
        expect(c.comDadosPessoais, isTrue, reason: melhor);
        expect(c.cartao, isNull, reason: melhor);
      }
      final pt = _ler(_modelo(correcao: {'precisa': true, 'melhor': 'Call me, please.', 'pt': 'Me ligue no [número de telefone].'}))!.correcao!;
      expect(pt.cartao, isNull, reason: 'marcador só no pt');
    });

    test('contração: só o apóstrofo de diferença não é correção', () {
      for (final (enviada, melhor) in [('i dont know', "I don't know."), ('Im fine', 'I’m fine.'), ("it's ok", 'Its ok')]) {
        final c = _ler(_modelo(correcao: {'precisa': true, 'melhor': melhor, 'pt': 'x'}), enviada: enviada)!.correcao!;
        expect(c.precisa, isFalse, reason: '$enviada → $melhor');
      }
      // de propósito (o prompt manda não corrigir contrações): "were" x "we're" também passa como certinho
      expect(_ler(_modelo(correcao: {'precisa': true, 'melhor': "We're late.", 'pt': 'x'}), enviada: 'were late')!.correcao!.precisa, isFalse);
      // erro de verdade continua sendo correção
      expect(_ler(_modelo(correcao: {'precisa': true, 'melhor': "I don't know.", 'pt': 'x'}), enviada: 'i no know')!.correcao!.precisa, isTrue);
    });

    test('marcador sem original sobrando fica (e a correção continua marcada)', () {
      final c = _ler(_modelo(correcao: {'precisa': true, 'melhor': 'Write to [email].', 'pt': 'x'}), enviada: 'Write me')!.correcao!;
      expect(c.melhor, 'Write to [email].');
      expect(c.comDadosPessoais, isTrue);
    });

    test('cartao passa pelo prepararCartao', () {
      const boa = CorrecaoTurno(precisa: true, melhor: 'I’m fine, thanks.', pt: 'Estou bem.');
      expect(boa.cartao, prepararCartao('I’m fine, thanks.', 'Estou bem.').cartao);
      expect(boa.cartao!.en, "I'm fine, thanks.");
      expect(const CorrecaoTurno(precisa: true, melhor: 'Good phrase.', pt: '').cartao, isNull, reason: 'sem tradução');
      expect(const CorrecaoTurno(precisa: false, melhor: 'Good phrase.', pt: 'Boa.').cartao, isNull, reason: 'certinho não vira cartão');
    });

    test('limites: porque, dica e melhor', () {
      final c = _ler(_modelo(correcao: {
        'precisa': true,
        'melhor': 'Can I have it? ${'word ' * 80}',
        'pt': 'x',
        'porque': 'Porque sim. ${'muito ' * 60}',
        'dica': 'Dica ${'longa ' * 50}',
      }))!
          .correcao!;
      expect(c.porque.length, lessThanOrEqualTo(CorrecaoTurno.maxPorque));
      expect(c.porque, 'Porque sim.');
      expect(c.dica.length, lessThanOrEqualTo(CorrecaoTurno.maxDica));
      expect(c.dica, endsWith('…'));
      expect(c.melhor.length, lessThanOrEqualTo(CorrecaoTurno.maxMelhor));
    });
  });

  group('limites e filtros', () {
    test('fala de mais de 300 letras é cortada no fim de uma frase', () {
      final longa = '${'This is a sentence. ' * 20}And one more without end';
      final r = _ler(_modelo(fala: longa))!;
      expect(r.fala.length, lessThanOrEqualTo(RespostaTurno.maxFala));
      expect(r.fala, endsWith('sentence.'));
      final semPonto = _ler(_modelo(fala: 'word ' * 100))!.fala;
      expect(semPonto.length, lessThanOrEqualTo(RespostaTurno.maxFala));
      expect(semPonto, endsWith('…'));
    });

    test('sugestões: até 3, sem vazias, longas, repetidas (sem caixa) ou iguais à fala', () {
      final r = _ler(_modelo(sugestoes: [
        'Sure! What size would you like?',
        '',
        42,
        'Small, please.',
        'small, PLEASE.',
        'x' * 121,
        'A large one.',
        'Medium.',
        'To go.',
      ]))!;
      expect(r.sugestoes, ['Small, please.', 'A large one.', 'Medium.']);
      expect(_ler(_modelo(sugestoes: 'não é lista'))!.sugestoes, isEmpty);
    });

    test('palavras: só palavras soltas (a regra do validarPalavraNova), sem básicas, sem repetir, até 3', () {
      final r = _ler(_modelo(palavras: [
        {'en': 'check-in', 'pt': 'check-in'},
        {'en': 'go over', 'pt': 'revisar'},
        {'en': "I'd", 'pt': 'eu gostaria'},
        {'en': 'return ticket', 'pt': 'passagem de volta'},
        {'en': 'café', 'pt': 'café'},
        {'en': 'abcdefghijklmno', 'pt': '15 letras'},
        {'en': 'the', 'pt': 'o'},
        {'en': 'Luggage ', 'pt': 'bagagem'},
        {'en': 'luggage', 'pt': 'bagagem de novo'},
        {'en': 'size', 'pt': ''},
        {'en': 'receipt', 'pt': 'x' * 61},
        {'en': 'purpose', 'pt': 'motivo'},
        'lixo',
        {'en': 42, 'pt': 'número'},
        {'en': 'downtown', 'pt': 'centro'},
        {'en': 'passport', 'pt': 'passaporte'},
      ]))!;
      expect(r.palavras, const [
        PalavraSugerida('luggage', 'bagagem'),
        PalavraSugerida('purpose', 'motivo'),
        PalavraSugerida('downtown', 'centro'),
      ]);
      for (final p in r.palavras) {
        expect(validarPalavraNova(p.en, BancoPalavras.vazio).erro, isNull, reason: p.en);
      }
    });

    test('fim: só o booleano true conta', () {
      expect(_ler(_modelo(fim: true))!.fim, isTrue);
      expect(_ler(_modelo(fim: 'true'))!.fim, isFalse);
      expect(_ler(_modelo(fim: 1))!.fim, isFalse);
    });

    test('tipos errados são ignorados sem lançar', () {
      final r = _ler({'fala': 'Hi there.', 'traducao': 3, 'correcao': null, 'sugestoes': {'a': 1}, 'palavras': 'x', 'fim': null})!;
      expect(r, const RespostaTurno(fala: 'Hi there.'));
    });
  });

  group('limparFala', () {
    test('tira bloco de código SEM pôr texto em português no lugar', () {
      final f = limparFala('Sure! ```dart\nprint(1);\n``` What else?');
      expect(f, 'Sure! What else?');
      expect(f, isNot(contains('código')));
      expect(f, isNot(contains('Dá uma olhada')));
    });

    test('tira emoji, *, _, #, crases e aspas em volta; junta os espaços', () {
      expect(limparFala('Hi 😀! **Great** `choice`'), 'Hi ! Great choice');
      expect(limparFala('# _Welcome_   back ☕'), 'Welcome back');
      expect(limparFala('"Sure, here you go."'), 'Sure, here you go.');
      expect(limparFala('“Sure.”'), 'Sure.');
      expect(limparFala('He said "hi" to me.'), 'He said "hi" to me.', reason: 'aspas do meio ficam');
      expect(limparFala('   '), '');
    });
  });

  group('esquemaTurno e formatoTurnoTexto', () {
    const chaves = ['correcao', 'fala', 'traducao', 'sugestoes', 'palavras', 'fim'];

    test('o esquema exige correcao/fala/traducao/fim, com correcao primeiro na ordem', () {
      expect(esquemaTurno['type'], 'OBJECT');
      expect((esquemaTurno['properties'] as Map).keys, containsAll(chaves));
      expect(esquemaTurno['required'], ['correcao', 'fala', 'traducao', 'fim']);
      expect(esquemaTurno['propertyOrdering'], chaves);
      final correcao = (esquemaTurno['properties'] as Map)['correcao'] as Map;
      expect(correcao['required'], ['precisa']);
      expect((correcao['properties'] as Map).keys, ['precisa', 'melhor', 'pt', 'porque', 'dica']);
      final palavras = ((esquemaTurno['properties'] as Map)['palavras'] as Map)['items'] as Map;
      expect(palavras['required'], ['en', 'pt']);
    });

    test('o formato em texto cita todas as chaves e é ele mesmo um JSON quase válido', () {
      for (final k in [...chaves, 'precisa', 'melhor', 'pt', 'porque', 'dica', 'en']) {
        expect(formatoTurnoTexto, contains('"$k"'), reason: k);
      }
      expect(formatoTurnoTexto, startsWith('Devolva SOMENTE um JSON válido'));
    });
  });

  group('ResumoConversa.de (local, 0 usos)', () {
    const errada = CorrecaoTurno(precisa: true, melhor: 'Can I have a coffee, please?', pt: 'Posso pedir um café?');
    const certa = CorrecaoTurno(precisa: false);

    test('conta falas e certinhas, lista as correções em ordem, junta as palavras (com o exemplo) e ignora a fala sem resposta', () {
      var s = SessaoCenario.nova(_cafe)
          .aluno('I want coffee')
          .responder(const RespostaTurno(fala: 'Sure! What size?', correcao: errada, palavras: [
            PalavraSugerida('size', 'tamanho'),
          ]))
          .aluno('Small, please.')
          .responder(const RespostaTurno(fala: 'Anything else? A muffin?', correcao: certa, palavras: [
            PalavraSugerida('Size', 'tamanho'),
            PalavraSugerida('muffin', 'bolinho'),
          ]))
          .aluno('No thank')
          .responder(const RespostaTurno(
            fala: 'Ok.',
            correcao: CorrecaoTurno(precisa: true, melhor: 'No, thanks.', pt: 'Não, obrigado.'),
          ))
          .aluno('Bye')
          .dash('Bye!') // sem estrutura: não conta como certa nem errada
          .aluno('sem resposta');
      expect(s.esperandoDash, isTrue);
      final r = ResumoConversa.de(s);
      expect(r.falas, 4, reason: 'a fala sem resposta não conta');
      expect(r.certas, 1);
      expect(r.correcoes, const [
        ItemCorrecao('I want coffee', errada),
        ItemCorrecao('No thank', CorrecaoTurno(precisa: true, melhor: 'No, thanks.', pt: 'Não, obrigado.')),
      ]);
      expect(r.palavras, const [PalavraSugerida('size', 'tamanho'), PalavraSugerida('muffin', 'bolinho')]);
      expect(r.exemplos, ['Sure! What size?', 'Anything else? A muffin?']);
      s = s.semUltimaFala();
      expect(ResumoConversa.de(s), r);
    });

    test('no máximo 8 palavras, com os exemplos alinhados', () {
      var s = SessaoCenario.nova(_cafe.copiaCom(maxTurnos: 12));
      for (var i = 0; i < 5; i++) {
        final c = String.fromCharCode(97 + i);
        s = s.aluno('fala $i').responder(RespostaTurno(fala: 'Resposta $i: palavra${c}a, palavra${c}b.', palavras: [
          PalavraSugerida('palavra${String.fromCharCode(97 + i)}a', 'a'),
          PalavraSugerida('palavra${String.fromCharCode(97 + i)}b', 'b'),
        ]));
      }
      final r = ResumoConversa.de(s);
      expect(r.palavras.length, ResumoConversa.maxPalavras);
      expect(r.exemplos.length, r.palavras.length);
      expect(r.exemplos.last, 'Resposta 3: palavrada, palavradb.');
    });

    test('palavra que não está na fala (lema ou do aluno): sem exemplo; uma forma dela ("order" em "ordered") vale', () {
      final s = SessaoCenario.nova(_cafe).aluno('I want coffee').responder(const RespostaTurno(fala: 'I ordered it. Ready soon!', palavras: [
        PalavraSugerida('order', 'pedir'),
        PalavraSugerida('coffee', 'café'),
        PalavraSugerida('ready', 'pronto'),
      ]));
      final r = ResumoConversa.de(s);
      expect(r.palavras.map((p) => p.en), ['order', 'coffee', 'ready']);
      expect(r.exemplos, ['I ordered it. Ready soon!', '', 'I ordered it. Ready soon!']);
    });

    test('conversa só com a abertura: tudo zero', () {
      expect(ResumoConversa.de(SessaoCenario.nova(_cafe)), const ResumoConversa(falas: 0, certas: 0));
    });
  });
}

extension on Cenario {
  Cenario copiaCom({required int maxTurnos}) => Cenario(
        id: id,
        titulo: titulo,
        emoji: emoji,
        etapa: etapa,
        papel: papel,
        objetivo: objetivo,
        abertura: abertura,
        maxTurnos: maxTurnos,
        quem: quem,
        nome: nome,
      );
}
