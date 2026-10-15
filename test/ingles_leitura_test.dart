import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/cartoes_texto.dart';
import 'package:pac_dart/features/ingles/domain/leitura.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/texto_salvo.dart';

void main() {
  group('os textos graduados do JSON', () {
    final lista = leiturasDeJson(jsonDecode(File('assets/ingles/leituras.json').readAsStringSync()));
    final ascii = RegExp(r"^[\x20-\x7E]+$");

    test('são 6, com ids únicos, nas etapas A1 a B2 e em ordem crescente de dificuldade', () {
      expect(lista.length, 6);
      expect(lista.map((l) => l.id).toSet().length, 6);
      expect(lista.map((l) => l.etapa).toSet(), {'A1', 'A2', 'B1', 'B2'});
      final ordem = ['A1', 'A2', 'B1', 'B2'];
      final idx = lista.map((l) => ordem.indexOf(l.etapa)).toList();
      expect(idx, [...idx]..sort(), reason: 'do mais fácil ao mais difícil');
    });

    test('todas as frases têm inglês digitável (ASCII) e tradução, e o texto é curto', () {
      for (final l in lista) {
        expect(l.frases.length, inInclusiveRange(5, 10), reason: l.id);
        expect(l.propria, isFalse);
        for (final f in l.frases) {
          expect(ascii.hasMatch(f.en), isTrue, reason: '${l.id}: ${f.en}');
          expect(f.pt.trim().length, greaterThan(8), reason: '${l.id}: ${f.en}');
          expect(f.en.length, lessThanOrEqualTo(110), reason: f.en);
          expect(f.alvo, isEmpty);
        }
      }
    });
  });

  group('Leitura.fromJson / leiturasDeJson', () {
    test('lixo nunca lança', () {
      for (final lixo in <Object?>[null, 3, 'x', [], {}, {'id': 'a'}, {'id': 'a', 'titulo': 't', 'frases': []}, {'id': '', 'titulo': 't', 'frases': [{'en': 'a', 'pt': 'b'}]}]) {
        expect(Leitura.fromJson(lixo), isNull, reason: '$lixo');
      }
      expect(leiturasDeJson('x'), isEmpty);
    });

    test('etapa padrão A1; itens inválidos e ids repetidos saem', () {
      final l = leiturasDeJson([
        {'id': 'a', 'titulo': 'A', 'frases': [{'en': 'Hi there.', 'pt': 'Oi.'}]},
        {'id': 'a', 'titulo': 'A de novo', 'frases': [{'en': 'Hi.', 'pt': 'Oi.'}]},
        {'id': 'b', 'titulo': 'B', 'etapa': 'B2', 'frases': [{'en': 'Hello.', 'pt': 'Olá.'}, 'lixo']},
      ]);
      expect(l.map((e) => e.id), ['a', 'b']);
      expect(l[0].etapa, 'A1');
      expect(l[1].etapa, 'B2');
      expect(l[1].frases.length, 1);
    });
  });

  group('Leitura.deTrilha (os "Meus textos")', () {
    final texto = TextoSalvo(
      id: 'abc',
      titulo: 'Minha viagem',
      criadoEm: DateTime(2026, 10, 1),
      frases: const [FraseDoTexto('I love Rome.', 'Eu amo Roma.'), FraseDoTexto('It is big.', 'Ela é grande.')],
    );

    test('a trilha de um texto colado vira leitura com as frases e as traduções', () {
      final l = Leitura.deTrilha(texto.comoTrilha())!;
      expect(l.propria, isTrue);
      expect(l.titulo, 'Minha viagem');
      expect(l.etapa, 'Meus textos');
      expect(l.frases.map((f) => (f.en, f.pt)), [('I love Rome.', 'Eu amo Roma.'), ('It is big.', 'Ela é grande.')]);
    });

    test('a lista "Meus cartões" e as trilhas do curso NÃO são leitura', () {
      final cartoes = TextoSalvo(id: idCartoesAvulsos, titulo: tituloCartoesAvulsos, criadoEm: DateTime(2026), frases: const [FraseDoTexto('Hi.', 'Oi.')], sequencial: true);
      expect(Leitura.deTrilha(cartoes.comoTrilha()), isNull);
      expect(Leitura.deTrilha(const Trilha(nivel: 'Curso', emoji: '1', licoes: [Licao(nome: 'a', emoji: '1', trechos: [Trecho(cod: 'Hi.', dica: 'Oi.', out: '')])])), isNull);
    });
  });

  group('alvoNaTraducao', () {
    test('acha a palavra traduzida na frase em português (sem ligar para caixa), inteira', () {
      const pt = 'Depois tomo café da manhã com minha irmã.';
      expect(alvoNaTraducao(pt, 'irmã'), 'irmã');
      expect(alvoNaTraducao(pt, 'Irmã'), 'irmã', reason: 'devolve como está na frase');
      expect(alvoNaTraducao(pt, 'tomo'), 'tomo');
    });

    test('não acha pedaço de palavra, tradução de várias palavras ou vazia: "" (nada é marcado)', () {
      const pt = 'Depois tomo café da manhã com minha irmã.';
      expect(alvoNaTraducao(pt, 'irm'), '');
      expect(alvoNaTraducao(pt, 'café da manhã'), '');
      expect(alvoNaTraducao(pt, ''), '');
      expect(alvoNaTraducao(pt, '  '), '');
      expect(alvoNaTraducao(pt, 'ônibus'), '');
      expect(alvoNaTraducao('A irmã e a mãe.', 'mã'), '', reason: 'meio de palavra não vale');
    });

    test('caracteres especiais da tradução não quebram a busca', () {
      expect(alvoNaTraducao('Custa (R\$ 5) hoje.', 'R\$'), 'R\$', reason: 'o cifrão é literal, não regex');
      expect(alvoNaTraducao('Ele disse: sim.', '.*'), '');
    });
  });

  group('cartaoDeLacuna', () {
    const frase = FraseDoTexto('Then I have breakfast with my sister.', 'Depois tomo café da manhã com minha irmã.');

    test('guarda a frase inteira, a tradução como pista e a palavra no jeito que está na frase', () {
      final c = cartaoDeLacuna(frase, 'Sister', traducaoDaPalavra: 'irmã')!;
      expect(c.en, frase.en);
      expect(c.pt, frase.pt);
      expect(c.alvo, 'sister');
      expect(c.alvoPt, 'irmã');
    });

    test('sem a tradução da palavra (falhou ou ainda não veio), o cartão sai sem alvoPt', () {
      final c = cartaoDeLacuna(frase, 'sister')!;
      expect(c.alvo, 'sister');
      expect(c.alvoPt, '');
    });

    test('palavra com aposto: a grafia da frase é mantida (I\'m)', () {
      const f = FraseDoTexto("Hi, I'm Ana.", 'Oi, eu sou a Ana.');
      expect(cartaoDeLacuna(f, "i'm")!.alvo, "I'm");
    });

    test('frase sem tradução, palavra vazia ou que não está na frase: sem cartão', () {
      expect(cartaoDeLacuna(const FraseDoTexto('Hello world.', ''), 'world'), isNull);
      expect(cartaoDeLacuna(const FraseDoTexto('Hello world.', '   '), 'world'), isNull);
      expect(cartaoDeLacuna(frase, ''), isNull);
      expect(cartaoDeLacuna(frase, 'banana'), isNull);
      expect(cartaoDeLacuna(frase, 'sis'), isNull, reason: 'pedaço de palavra não vale');
    });
  });

  group('o alvo viaja com a frase (e o formato antigo continua valendo)', () {
    test('FraseDoTexto: registro antigo (sem alvo) lê normalmente; com alvo faz ida e volta', () {
      final antigo = FraseDoTexto.fromJson({'en': 'Hi.', 'pt': 'Oi.'})!;
      expect((antigo.alvo, antigo.alvoPt), ('', ''));
      const novo = FraseDoTexto('See you soon.', 'Até logo.', alvo: 'soon', alvoPt: 'logo');
      expect(FraseDoTexto.fromJson(novo.toJson()), novo);
      expect(const FraseDoTexto('Hi.', 'Oi.').toJson().keys, ['en', 'pt'], reason: 'sem alvo, o JSON é o mesmo de sempre');
      expect(FraseDoTexto.fromJson({'en': 'Hi.', 'pt': 'Oi.', 'alvo': 3})!.alvo, '', reason: 'tipo errado vira vazio');
    });

    test('TextoSalvo.comoTrilha passa o alvo para o Trecho (o inglês fica sublinhado na digitação)', () {
      final t = TextoSalvo(
        id: 'cartoes',
        titulo: 'Meus cartões',
        criadoEm: DateTime(2026),
        frases: const [FraseDoTexto('See you soon.', 'Até logo.', alvo: 'soon', alvoPt: 'logo'), FraseDoTexto('Hi.', 'Oi.')],
        sequencial: true,
      );
      final trechos = [for (final l in t.comoTrilha().licoes) ...l.trechos];
      expect((trechos[0].alvo, trechos[0].alvoPt), ('soon', 'logo'));
      expect((trechos[1].alvo, trechos[1].alvoPt), ('', ''));
      // e o JSON do texto inteiro volta igual
      expect(TextoSalvo.fromJson(t.toJson()), t);
    });

    test('CartaoEscrito: o alvo entra na igualdade e vai para a frase', () {
      expect(const CartaoEscrito('a', 'b', alvo: 'x'), isNot(const CartaoEscrito('a', 'b')));
      expect(const CartaoEscrito('a', 'b', alvo: 'x', alvoPt: 'y').comoFrase, const FraseDoTexto('a', 'b', alvo: 'x', alvoPt: 'y'));
    });
  });

  group('lacunaUnica', () {
    test('esconde só a palavra-alvo, sem ligar para a caixa', () {
      final r = lacunaUnica(partirFrase('Then I have breakfast with my sister.'), 'Breakfast')!;
      expect(contarLacunas(r), 1);
      expect(r.where((p) => p.escondida).single.texto, 'breakfast');
    });

    test('todas as vezes que a palavra aparece', () {
      final r = lacunaUnica(partirFrase('Go, go, go now!'), 'go')!;
      expect(contarLacunas(r), 3);
    });

    test('palavra que não está (ou pedaço de palavra) e alvo vazio: null (vale o sorteio de sempre)', () {
      expect(lacunaUnica(partirFrase('I like tea.'), 'coffee'), isNull);
      expect(lacunaUnica(partirFrase('I like tea.'), 'tea'), isNotNull);
      expect(lacunaUnica(partirFrase('I like tea.'), 'te'), isNull);
      expect(lacunaUnica(partirFrase('I like tea.'), ''), isNull);
      expect(lacunaUnica(partirFrase('I like tea.'), '   '), isNull);
    });
  });
}
