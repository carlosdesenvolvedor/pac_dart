// Regras puras do mapa estilo Duolingo: estrelas, fronteira, estado do nó, seno, baú, personagem.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/mapa_regras.dart';

Trilha _t(String slug, int n, {String textoId = '', List<String> quem = const []}) => Trilha(
      nivel: slug,
      emoji: '⭐',
      etapa: 'A1 · Fundação',
      textoId: textoId,
      licoes: [
        for (var l = 0; l < n; l++)
          Licao(nome: '$slug $l', emoji: '📘', id: textoId.isEmpty ? '$slug.l$l' : 'txt:$textoId:$l', trechos: [
            for (final q in quem) Trecho(cod: 'Hi.', dica: 'Oi.', out: '', quem: q),
          ]),
      ],
    );

void main() {
  test('estrelas: sem nota/4 → 0, 5–6 → 1, 7–8 → 2, 9–10 → 3', () {
    expect(estrelasDaNota(null), 0);
    expect(estrelasDaNota(0), 0);
    expect(estrelasDaNota(4), 0);
    expect(estrelasDaNota(5), 1);
    expect(estrelasDaNota(6), 1);
    expect(estrelasDaNota(7), 2);
    expect(estrelasDaNota(8), 2);
    expect(estrelasDaNota(9), 3);
    expect(estrelasDaNota(10), 3);
  });

  group('fronteira', () {
    final trilhas = [_t('a', 2), _t('meu', 3, textoId: 'k1'), _t('b', 2)];

    test('é a primeira lição não feita na ordem do curso; nada feito → (0, 0)', () {
      expect(fronteira(trilhas, {}), (0, 0));
      expect(fronteira(trilhas, {'a.l0'}), (0, 1));
    });

    test('pula as trilhas próprias (textos colados), feitas ou não', () {
      expect(fronteira(trilhas, {'a.l0', 'a.l1'}), (2, 0));
    });

    test('teste de nivelamento (TrilhaTestada marca a trilha inteira): a fronteira passa por cima', () {
      // o bloc grava todas as chaves da trilha testada em concluidas
      expect(fronteira(trilhas, {'a.l0', 'a.l1', 'b.l0', 'b.l1'}), isNull, reason: 'curso inteiro feito');
      expect(fronteira([_t('a', 2), _t('b', 2), _t('c', 1)], {'b.l0', 'b.l1'}), (0, 0),
          reason: 'testar a trilha 2 não pula a 1');
    });

    test('lição sem id usa "t:l" (a mesma chave do CursoState)', () {
      final semId = [
        const Trilha(nivel: 'x', emoji: 'x', licoes: [Licao(nome: 'l0', emoji: 'x', trechos: []), Licao(nome: 'l1', emoji: 'x', trechos: [])]),
      ];
      expect(fronteira(semId, {'0:0'}), (0, 1));
      expect(chaveDaLicao(semId, 0, 1), '0:1');
    });
  });

  group('estado do nó', () {
    test('feita > atual > trancada (só depois do alcance) > disponível', () {
      const alcance = (1, 2);
      EstadoNo e(int t, int l, {bool feita = false, bool atual = false, bool propria = false}) =>
          estadoDoNo(feita: feita, atual: atual, pos: (t, l), alcance: alcance, propria: propria);
      expect(e(3, 0, feita: true, atual: true), EstadoNo.feita);
      expect(e(3, 0, atual: true), EstadoNo.atual);
      expect(e(1, 2), EstadoNo.disponivel, reason: 'a própria fronteira não está trancada');
      expect(e(1, 1), EstadoNo.disponivel);
      expect(e(0, 9), EstadoNo.disponivel);
      expect(e(1, 3), EstadoNo.trancada);
      expect(e(2, 0), EstadoNo.trancada);
      expect(e(5, 0, propria: true), EstadoNo.disponivel, reason: 'texto próprio nunca tranca');
      expect(estadoDoNo(feita: false, atual: false, pos: (9, 9), alcance: null), EstadoNo.disponivel,
          reason: 'curso inteiro feito: nada trancado');
    });

    test('alcance: a fronteira, ou a lição atual quando a pessoa pulou para a frente', () {
      final trilhas = [_t('a', 2), _t('b', 2), _t('c', 2), _t('meu', 1, textoId: 'k')];
      expect(alcanceDoMapa(trilhas, {'a.l0'}, (0, 1)), (0, 1));
      expect(alcanceDoMapa(trilhas, {'a.l0'}, (2, 1)), (2, 1), reason: 'pulou pelo menu: até ali fica aberto');
      expect(alcanceDoMapa(trilhas, {'a.l0'}, (0, 0)), (0, 1), reason: 'voltou para revisar: a fronteira vale');
      expect(alcanceDoMapa(trilhas, {'a.l0'}, (3, 0)), (0, 1), reason: 'estar num texto próprio não abre o curso');
    });
  });

  group('seno', () {
    test('período 8: centro, meio, borda, meio, centro, meio, outra borda, meio', () {
      expect([for (var i = 0; i < 8; i++) offsetSenoidal(i)], [0, .5, 1, .5, 0, -.5, -1, -.5]);
      for (var i = 0; i < 24; i++) {
        expect(offsetSenoidal(i), offsetSenoidal(i + 8));
      }
    });

    test('amplitude: num celular de 360 (faixa de 304) passa de 80 px; largo até 120', () {
      expect(amplitudeDuolingo(304), greaterThanOrEqualTo(80));
      expect(amplitudeDuolingo(360), greaterThanOrEqualTo(80));
      expect(amplitudeDuolingo(724), 120);
      expect(amplitudeDuolingo(0), 0);
    });

    test('os centros dos nós ficam dentro de [32, w−32] para w = 304 / 360 / 724', () {
      for (final w in [304.0, 360.0, 724.0]) {
        final a = amplitudeDuolingo(w);
        for (var i = 0; i < 8; i++) {
          final x = w / 2 + offsetSenoidal(i) * a;
          expect(x, inInclusiveRange(32, w - 32), reason: 'w=$w i=$i');
        }
      }
    });

    test('índice contínuo entre as unidades: cada uma ocupa lições + 1 (o baú); próprias = −1', () {
      final trilhas = [_t('a', 3), _t('meu', 2, textoId: 'k'), _t('b', 4), _t('c', 1)];
      expect(iniciosDoSeno(trilhas), [0, -1, 4, 9]);
      expect(numeroDaUnidade(trilhas, 0), 1);
      expect(numeroDaUnidade(trilhas, 1), 0);
      expect(numeroDaUnidade(trilhas, 2), 2);
      expect(numeroDaUnidade(trilhas, 3), 3);
    });
  });

  group('baú', () {
    test('trancado até a última lição, pronto, aberto depois de bau:<baralhoId>', () {
      expect(chaveDoBau('tr:a'), 'bau:tr:a');
      expect(estadoDoBau(completa: false, projetosFeitos: {}, baralhoId: 'tr:a'), EstadoBau.trancado);
      expect(estadoDoBau(completa: true, projetosFeitos: {}, baralhoId: 'tr:a'), EstadoBau.pronto);
      expect(bauPronto(completa: true, projetosFeitos: {}, baralhoId: 'tr:a'), isTrue);
      expect(estadoDoBau(completa: true, projetosFeitos: {'bau:tr:a'}, baralhoId: 'tr:a'), EstadoBau.aberto);
      expect(bauPronto(completa: true, projetosFeitos: {'bau:tr:a'}, baralhoId: 'tr:a'), isFalse);
      expect(bauAberto({'bau:tr:b'}, 'tr:a'), isFalse);
    });

    test('só trilhas do curso com 4+ palavras novas ganham baú', () {
      expect(temBau(_t('a', 2), 4), isTrue);
      expect(temBau(_t('a', 2), 3), isFalse);
      expect(temBau(_t('meu', 2, textoId: 'k'), 12), isFalse);
      expect(_t('a', 2).baralhoId, 'tr:a');
    });

    test('só um baú pronto balança: o último até a trilha atual, senão o primeiro depois dela', () {
      expect(bauQueBalanca(const [], 3), isNull);
      expect(bauQueBalanca(const [0, 1, 2, 5], 3), 2, reason: 'o mais recente antes de onde a pessoa está');
      expect(bauQueBalanca(const [3], 3), 3, reason: 'a trilha atual conta como "até"');
      expect(bauQueBalanca(const [7, 5, 9], 3), 5, reason: 'nada antes: o primeiro depois');
      expect(bauQueBalanca(const [2, 0, 1], 9), 2, reason: 'a ordem da lista não importa');
    });
  });

  test('personagem da trilha: quem mais fala, sem "voce"; ninguém → null', () {
    expect(personagemDaTrilha(_t('a', 2, quem: ['voce', 'voce', 'voce', 'mike', 'sarah', 'sarah'])), 'sarah');
    expect(personagemDaTrilha(_t('a', 1, quem: ['mike', 'sarah'])), 'mike', reason: 'empate: quem falou primeiro');
    expect(personagemDaTrilha(_t('a', 1, quem: ['voce', ''])), isNull);
  });
}
