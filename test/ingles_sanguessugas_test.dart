import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/baralhos.dart';
import 'package:pac_dart/features/ingles/domain/nivel_resposta.dart';
import 'package:pac_dart/features/ingles/domain/revisao.dart';
import 'package:pac_dart/features/ingles/domain/sanguessugas.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/subida_nivel.dart';
import 'package:pac_dart/features/ingles/presentation/revisao_cubit.dart';

import 'ingles_baralhos_test.dart' show f1, f2, f3, f4, trilhasDeTeste;

CartaoSrs cartao({int lapsos = 0, bool suspenso = false}) => CartaoSrs(
      estabilidade: 5,
      dificuldade: 5,
      ultimoDia: 100,
      proximoDia: 105,
      revisoes: 20,
      lapsos: lapsos,
      suspenso: suspenso,
    );

Trecho t(String cod, [String pt = 'x']) => Trecho(cod: cod, dica: pt, out: '');

void main() {
  group('sanguessugasDe', () {
    final indice = IndiceBaralhos.de(trilhasDeTeste());
    String k(Trecho f) => RevisaoCubit.chaveDe(f);

    test('o limite é 8 lapsos (7 não, 8 sim)', () {
      expect(limiteSanguessuga, 8);
      expect(sanguessugasDe({k(f1): cartao(lapsos: 7)}, indice), isEmpty);
      expect(sanguessugasDe({k(f1): cartao(lapsos: 8)}, indice).length, 1);
      expect(sanguessugasDe({k(f1): cartao(lapsos: 7)}, indice, limite: 3).length, 1, reason: 'o limite é parâmetro');
    });

    test('suspensos saem (a pessoa já resolveu) e frases que não estão mais no curso também', () {
      final r = sanguessugasDe({
        k(f1): cartao(lapsos: 10, suspenso: true),
        k(f2): cartao(lapsos: 9),
        Revisao.chave('Frase que saiu do curso.'): cartao(lapsos: 30),
      }, indice);
      expect(r.map((s) => s.frase.cod), ['How are you?']);
    });

    test('o cartão de virar (inglês → português) é identificado e aponta para a frase certa', () {
      final r = sanguessugasDe({RevisaoCubit.chaveReversaDe(f3): cartao(lapsos: 8)}, indice);
      expect(r.single.reverso, isTrue);
      expect(r.single.frase.cod, 'I was tired.');
      expect(r.single.lapsos, 8);
      expect(sanguessugasDe({k(f3): cartao(lapsos: 8)}, indice).single.reverso, isFalse);
    });

    test('ordem: quem mais erra primeiro; empate pela chave (estável)', () {
      final cartoes = {k(f1): cartao(lapsos: 9), k(f2): cartao(lapsos: 12), k(f3): cartao(lapsos: 9), k(f4): cartao(lapsos: 8)};
      final r = sanguessugasDe(cartoes, indice);
      expect(r.map((s) => s.lapsos), [12, 9, 9, 8]);
      expect(r.first.frase.cod, 'How are you?');
      final inverso = sanguessugasDe({for (final e in cartoes.entries.toList().reversed) e.key: e.value}, indice);
      expect(inverso.map((s) => s.chave), r.map((s) => s.chave));
    });

    test('sem cartões, nada', () => expect(sanguessugasDe({}, indice), isEmpty));
  });

  group('palavrasChave e exemplosParecidos', () {
    test('palavrasChave: 4+ letras, minúsculas, sem as comuns', () {
      expect(palavrasChave("I don't know where the Hotel is."), ["don't", 'know', 'hotel']);
      expect(palavrasChave('See you!'), isEmpty);
    });

    final todas = [
      t('I need a ticket for the train.'),
      t('The train leaves at noon.'),
      t('Is this train going to Boston?'),
      t('Please buy a ticket.'),
      t('Nice weather today.'),
    ];

    test('escolhe a palavra MAIS RARA e traz outras frases com ela (curtas primeiro)', () {
      // "ticket" aparece em 2 outras frases; "train" em 3: a ponte é "ticket"
      final f = t('Where can I buy a ticket for the train?');
      final r = exemplosParecidos(f, todas);
      expect(r.map((e) => e.cod), ['Please buy a ticket.', 'I need a ticket for the train.']);
      expect(palavraPonte(f, todas), isNot('train'));
    });

    test('nunca devolve a própria frase (nem a mesma com outra caixa) e respeita o máximo', () {
      final f = t('The train leaves at noon.');
      final r = exemplosParecidos(f, [...todas, t('the TRAIN leaves at noon.')], max: 1);
      expect(r.length, 1);
      expect(r.single.cod, isNot(contains('leaves')));
    });

    test('sem outra frase com as palavras: lista vazia; frase só de palavras comuns: vazia', () {
      expect(exemplosParecidos(t('Zebra crossing ahead.'), todas), isEmpty);
      expect(exemplosParecidos(t('See you.'), todas), isEmpty);
      expect(palavraPonte(t('Zebra crossing ahead.'), todas), isNull);
    });

    test('frases repetidas na lista contam uma vez', () {
      final r = exemplosParecidos(t('A ticket, please.'), [t('Buy a ticket.'), t('buy a TICKET.'), t('Buy a ticket.')]);
      expect(r.length, 1);
    });
  });

  group('SerieDeNivel', () {
    SerieDeNivel com(NivelResposta n, List<Rating> notas) => notas.fold(const SerieDeNivel(), (s, r) => s.registrar(n, r));
    const m = NivelResposta.medio;

    test('10 acertos seguidos no Médio sugerem o Avançado (9 não)', () {
      expect(com(m, List.filled(9, Rating.good)).sugestao(m), isNull);
      expect(com(m, List.filled(10, Rating.good)).sugestao(m), NivelResposta.avancado);
      expect(com(m, [...List.filled(5, Rating.easy), ...List.filled(5, Rating.good)]).sugestao(m), NivelResposta.avancado, reason: '"Fácil" também é acerto');
    });

    test('um erro no meio quebra a série (e só 10 seguidos DEPOIS voltam a sugerir)', () {
      final s = com(m, [...List.filled(9, Rating.good), Rating.again]);
      expect(s.sugestao(m), isNull);
      expect(com(m, [...List.filled(9, Rating.good), Rating.again, ...List.filled(10, Rating.good)]).sugestao(m), NivelResposta.avancado);
    });

    test('"Difícil" não conta para nada nem quebra a série', () {
      final s = com(m, [...List.filled(5, Rating.good), Rating.hard, Rating.hard, ...List.filled(5, Rating.good)]);
      expect(s.porNivel[m]!.length, 10);
      expect(s.sugestao(m), NivelResposta.avancado);
    });

    test('Fácil sobe para o Médio; Avançado nunca sobe; "Só virar" fica fora da escada', () {
      expect(com(NivelResposta.facil, List.filled(10, Rating.good)).sugestao(NivelResposta.facil), NivelResposta.medio);
      expect(com(NivelResposta.avancado, List.filled(10, Rating.good)).sugestao(NivelResposta.avancado), isNull);
      final livre = com(NivelResposta.livre, List.filled(10, Rating.good));
      expect(livre.porNivel, isEmpty);
      expect(livre.sugestao(NivelResposta.livre), isNull);
    });

    test('4 erros nas últimas 8 sugerem descer (3 não); Fácil nunca desce', () {
      List<Rating> mistura(int erros) => [for (var i = 0; i < 8; i++) i < erros ? Rating.again : Rating.good];
      expect(com(NivelResposta.avancado, mistura(4)).sugestao(NivelResposta.avancado), NivelResposta.medio);
      expect(com(NivelResposta.avancado, mistura(3)).sugestao(NivelResposta.avancado), isNull);
      expect(com(m, mistura(4)).sugestao(m), NivelResposta.facil);
      expect(com(NivelResposta.facil, mistura(8)).sugestao(NivelResposta.facil), isNull);
    });

    test('só vale a janela das ÚLTIMAS 8: erros antigos já saíram', () {
      final s = com(NivelResposta.avancado, [...List.filled(4, Rating.again), ...List.filled(8, Rating.good)]);
      expect(s.sugestao(NivelResposta.avancado), isNull);
    });

    test('guarda só as últimas 10 por degrau; degraus são independentes; limpar zera só o degrau', () {
      var s = com(m, List.filled(15, Rating.good));
      expect(s.porNivel[m]!.length, 10);
      s = s.registrar(NivelResposta.facil, Rating.again);
      expect(s.porNivel.keys.toSet(), {m, NivelResposta.facil});
      final l = s.limpar(m);
      expect(l.porNivel.containsKey(m), isFalse);
      expect(l.porNivel[NivelResposta.facil], [false]);
      expect(l.sugestao(m), isNull);
    });

    test('JSON: ida e volta e lixo nunca lança', () {
      final s = com(m, [Rating.good, Rating.again, Rating.easy]);
      expect(SerieDeNivel.decodificar(s.codificar()).porNivel, s.porNivel);
      for (final lixo in [null, '', '{x', '[1]', '"t"', '{"medio":"x"}', '{"nada":[1]}', '{"livre":[1,1]}', '{"medio":[1,7,"a",0]}']) {
        final r = SerieDeNivel.decodificar(lixo);
        expect(r.porNivel.keys.every(SerieDeNivel.escada.contains), isTrue, reason: '$lixo');
      }
      expect(SerieDeNivel.decodificar('{"medio":[1,7,"a",0]}').porNivel[m], [true, false]);
    });
  });
}
