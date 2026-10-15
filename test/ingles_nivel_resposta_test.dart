import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/comparar_resposta.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';

void main() {
  group('níveis e sentidos', () {
    test('o id guardado volta ao mesmo nível/sentido; id desconhecido ou vazio dá null', () {
      for (final n in NivelResposta.values) {
        expect(NivelResposta.porId(n.id), n);
      }
      for (final s in SentidoCartao.values) {
        expect(SentidoCartao.porId(s.id), s);
      }
      expect(NivelResposta.porId('dificil'), isNull);
      expect(NivelResposta.porId(null), isNull);
      expect(SentidoCartao.porId('x'), isNull);
    });

    test('só Médio e Avançado escrevem; Fácil monta e Só virar apenas olha', () {
      expect([for (final n in NivelResposta.values) if (n.escreve) n], [NivelResposta.medio, NivelResposta.avancado]);
    });
  });

  group('apóstrofo (inglês)', () {
    test("don't, I'm e d'água são UMA palavra; com ou sem apóstrofo (e com o curvo) é a mesma palavra", () {
      final c = compararResposta("I don't know.", 'i dont know');
      expect(c.exata, isTrue);
      expect(c.totalEsperadas, 3);
      expect(compararResposta("I'm tired", 'I’m tired').exata, isTrue);
      expect(compararResposta("I'm tired", 'I am tired').exata, isFalse, reason: 'I am ≠ I\'m: são duas palavras');
      expect(partirFrase("I don't know.").where((p) => p.palavra).map((p) => p.texto), ['I', "don't", 'know']);
      expect(palavrasIguais("don't", 'DONT'), isTrue);
    });
  });

  group('partirFrase', () {
    test('juntar as partes devolve a frase inteira, com pontuação e espaços como vieram', () {
      for (final f in ['Prazer em te conhecer.', '¿Cómo estás? — bien, gracias!', '  ', '', 'a', '...oi...']) {
        expect(partirFrase(f).map((p) => p.texto).join(), f);
      }
      expect(partirFrase('Como vai você?').where((p) => p.palavra).length, 3);
      expect(partirFrase('...').any((p) => p.palavra), isFalse);
    });
  });

  group('Médio: lacunas', () {
    test('quantas palavras escondem: um pouco mais da metade, sempre sobra uma à vista (se houver mais de uma)', () {
      expect([for (final n in [0, 1, 2, 3, 4, 5, 6, 8, 10, 20]) quantasEscondidas(n)], [0, 1, 1, 2, 2, 3, 3, 4, 6, 11]);
      for (var n = 2; n < 40; n++) {
        expect(quantasEscondidas(n), inInclusiveRange(1, n - 1));
      }
    });

    test('esconde a quantia certa, só palavras (nunca pontuação), e a mesma semente dá a mesma escolha', () {
      final partes = partirFrase('Eu gosto muito de café, mas não de chá.');
      final a = esconderPalavras(partes, Random(3)), b = esconderPalavras(partes, Random(3));
      expect(a, b);
      expect(contarLacunas(a), quantasEscondidas(9));
      expect(a.where((p) => p.escondida).every((p) => p.palavra), isTrue);
      expect(a.map((p) => p.texto).join(), 'Eu gosto muito de café, mas não de chá.', reason: 'o texto não muda, só a marca');
      // sementes diferentes variam a escolha
      final variadas = {for (var s = 0; s < 30; s++) esconderPalavras(partes, Random(s)).where((p) => p.escondida).map((p) => p.texto).join('|')};
      expect(variadas.length, greaterThan(1));
    });

    test('as palavras compridas são escondidas antes das curtas (carregam o sentido)', () {
      final partes = partirFrase('Eu vi o elefante gigante');
      for (var s = 0; s < 20; s++) {
        final ocultas = esconderPalavras(partes, Random(s)).where((p) => p.escondida).map((p) => p.texto).toSet();
        expect(ocultas, containsAll(['elefante', 'gigante']), reason: 'semente $s: $ocultas');
        expect(ocultas.length, 3, reason: 'o 3º é uma das curtas, sorteada');
      }
    });

    test('frase de uma palavra esconde a única; sem palavra não há lacuna', () {
      expect(contarLacunas(esconderPalavras(partirFrase('Olá!'), Random(1))), 1);
      expect(contarLacunas(esconderPalavras(partirFrase('...'), Random(1))), 0);
    });

    final partes = [
      const ParteFrase('Eu', palavra: true),
      const ParteFrase(' '),
      const ParteFrase('gosto', palavra: true, escondida: true),
      const ParteFrase(' '),
      const ParteFrase('muito', palavra: true),
      const ParteFrase(' '),
      const ParteFrase('café', palavra: true, escondida: true),
      const ParteFrase(' '),
      const ParteFrase('quente', palavra: true, escondida: true),
      const ParteFrase('.'),
    ];

    test('todas as lacunas certas: exata, sugere Bom; maiúscula, acento e errinho de digitação perdoados', () {
      final c = conferirLacunas(partes, ['GOSTO', 'cafe', 'quenyte']);
      expect(c.exata, isTrue);
      expect(c.sugerida, Rating.good);
      expect(c.acertadas, 3);
      expect(c.totalEsperadas, 3, reason: 'só as lacunas contam; as palavras à vista não');
    });

    test('2 de 3 certas sugere Difícil; 1 de 3 sugere Errei; vazia conta como errada', () {
      final dois = conferirLacunas(partes, ['gosto', 'café', 'frio']);
      expect((dois.acertadas, dois.sugerida, dois.exata), (2, Rating.hard, false));
      final um = conferirLacunas(partes, ['gosto', '', 'frio']);
      expect((um.acertadas, um.sugerida), (1, Rating.again));
      expect(um.digitada.map((s) => s.texto).join(), 'Eu gosto muito ___ frio.');
      expect(conferirLacunas(partes, const []).sugerida, Rating.again);
    });

    test('mostra a frase completa dos dois lados: o que a pessoa escreveu e a resposta certa, as à vista sem marca', () {
      final c = conferirLacunas(partes, ['gosto', 'chá', 'quente']);
      expect(c.esperada.map((s) => s.texto).join(), 'Eu gosto muito café quente.');
      expect(c.digitada.map((s) => s.texto).join(), 'Eu gosto muito chá quente.');
      expect(c.esperada.firstWhere((s) => s.texto == 'Eu').acerto, isNull);
      expect(c.esperada.firstWhere((s) => s.texto == 'café').acerto, isFalse);
      expect(c.digitada.firstWhere((s) => s.texto == 'chá').acerto, isFalse);
    });
  });

  group('Fácil: blocos', () {
    List<String> textos(List<Bloco> b) => [for (final x in b) x.texto];

    test('traz todas as palavras da resposta + enfeites que NÃO estão nela, embaralhados, com ids em sequência', () {
      final b = montarBlocos('Prazer em te conhecer.', apoio: const ['Como vai você?', 'Eu estava cansado'], aleatorio: Random(5));
      final certas = b.where((x) => !x.distrator).map((x) => x.texto).toList()..sort();
      expect(certas, ['Prazer', 'conhecer', 'em', 'te']);
      expect(b.where((x) => x.distrator).length, quantosDistratores(4));
      expect([for (final x in b) x.id], [for (var i = 0; i < b.length; i++) i]);
      final nas = {'prazer', 'em', 'te', 'conhecer'};
      expect(b.where((x) => x.distrator).every((x) => !nas.contains(normalizarPalavra(x.texto))), isTrue);
      expect(textos(b), isNot(['Prazer', 'em', 'te', 'conhecer']), reason: 'embaralhado (semente 5)');
    });

    test('mesma semente, mesmos blocos; semente diferente embaralha de outro jeito', () {
      List<String> com(int s) => textos(montarBlocos('Eu gosto muito de café quente', apoio: const ['Ele mora longe daqui hoje'], aleatorio: Random(s)));
      expect(com(2), com(2));
      expect({for (var s = 0; s < 20; s++) com(s).join(' ')}.length, greaterThan(5));
    });

    test('enfeite nunca repete palavra da resposta (nem com acento/maiúscula diferente), nem repete entre si', () {
      for (var s = 0; s < 40; s++) {
        final b = montarBlocos('Eu estava cansado.', apoio: const ['EU ESTAVA ÓTIMO e cansada', 'Estava lá', 'cansado demais'], aleatorio: Random(s));
        final enf = [for (final x in b) if (x.distrator) normalizarPalavra(x.texto)];
        expect(enf.toSet().length, enf.length, reason: 'semente $s: $enf');
        for (final e in enf) {
          expect(['eu', 'estava', 'cansado'], isNot(contains(e)), reason: 'semente $s');
        }
      }
    });

    test('palavra repetida na resposta vira dois blocos', () {
      final b = montarBlocos('the cat and the dog', apoio: const [], reserva: palavrasDeReservaEn, aleatorio: Random(1));
      expect(b.where((x) => !x.distrator && x.texto == 'the').length, 2);
    });

    test('faltando frases de apoio, completa com o curso (extra) e depois com a reserva do idioma', () {
      final sozExtra = montarBlocos('Prazer em te conhecer', apoio: const [], extra: const ['Como vai'], aleatorio: Random(1));
      expect(sozExtra.where((x) => x.distrator).map((x) => x.texto).toSet(), {'Como', 'vai'});
      final reservaPt = montarBlocos('Prazer em te conhecer', apoio: const [], aleatorio: Random(1));
      expect(reservaPt.where((x) => x.distrator).every((x) => palavrasDeReservaPt.contains(x.texto)), isTrue);
      final reservaEn = montarBlocos('Nice to meet you', apoio: const [], reserva: palavrasDeReservaEn, aleatorio: Random(1));
      expect(reservaEn.where((x) => x.distrator).length, 2);
      expect(reservaEn.where((x) => x.distrator).every((x) => palavrasDeReservaEn.contains(x.texto)), isTrue);
    });

    test('o apoio da sessão vem antes do extra e da reserva', () {
      final b = montarBlocos('Prazer em te conhecer', apoio: const ['Como vai'], extra: const ['Até amanhã cedo'], aleatorio: Random(9));
      expect(b.where((x) => x.distrator).map((x) => x.texto).toSet(), {'Como', 'vai'});
    });

    test('quantidade de enfeites: de 2 a 5, perto de metade', () {
      expect([for (final n in [1, 2, 4, 6, 8, 10, 14, 30]) quantosDistratores(n)], [2, 2, 2, 3, 4, 5, 5, 5]);
    });

    test('frase sem palavra não gera bloco', () {
      expect(montarBlocos('...', apoio: const ['oi'], aleatorio: Random(1)), isEmpty);
      expect(montarBlocos('', apoio: const [], aleatorio: Random(1)), isEmpty);
    });

    test('montar certo, na ordem: exata e sugere Bom', () {
      final b = [const Bloco(0, 'Prazer'), const Bloco(1, 'em'), const Bloco(2, 'te'), const Bloco(3, 'conhecer')];
      final c = conferirBlocos('Prazer em te conhecer.', b);
      expect((c.exata, c.sugerida, c.acertadas, c.totalEsperadas), (true, Rating.good, 4, 4));
    });

    test('as palavras certas em outra ordem não são exatas: sugere Difícil (e nunca Bom)', () {
      final b = [const Bloco(1, 'em'), const Bloco(0, 'Prazer'), const Bloco(2, 'te'), const Bloco(3, 'conhecer')];
      final c = conferirBlocos('Prazer em te conhecer.', b);
      expect((c.exata, c.sugerida), (false, Rating.hard));
      expect(c.cobertura, 1);
    });

    test('faltou palavra ou entrou enfeite: Difícil se ficou quase, Errei se não', () {
      // 4 das 5 certas, sem enfeite: cobre 80% → Errei (menos de 85%)
      final falta = conferirBlocos('Eu gosto muito de café', [const Bloco(0, 'Eu'), const Bloco(1, 'gosto'), const Bloco(2, 'muito'), const Bloco(3, 'café')]);
      expect(falta.sugerida, Rating.again);
      // 6 das 6 certas + 1 enfeite: cobre 100% mas precisão 6/7 = 86% → Difícil
      const certas = ['Eu', 'gosto', 'muito', 'de', 'café', 'quente'];
      final sobra = conferirBlocos('Eu gosto muito de café quente', [for (var i = 0; i < 6; i++) Bloco(i, certas[i]), const Bloco(6, 'ontem', distrator: true)]);
      expect((sobra.exata, sobra.sugerida), (false, Rating.hard));
      // metade e metade
      final metade = conferirBlocos('Eu gosto muito', [const Bloco(0, 'Eu'), const Bloco(1, 'ontem', distrator: true), const Bloco(2, 'casa', distrator: true)]);
      expect(metade.sugerida, Rating.again);
    });

    test('nada montado: Errei', () {
      expect(conferirBlocos('Prazer em te conhecer', const []).sugerida, Rating.again);
    });
  });
}
