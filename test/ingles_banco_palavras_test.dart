// Banco de palavras do aluno (inglês): gravação compacta, mescla entre aparelhos, nota do treino,
// agenda FSRS e validação do que a pessoa adiciona.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/teimosas.dart';

const _c1 = CartaoSrs(estabilidade: 1.5, dificuldade: 5, ultimoDia: 100, proximoDia: 101, revisoes: 1);
const _c2 = CartaoSrs(estabilidade: 6, dificuldade: 5, ultimoDia: 104, proximoDia: 110, revisoes: 2);

void main() {
  group('codificar / decodificar', () {
    test('ida e volta sem perder nada', () {
      final b = const BancoPalavras()
          .com(const PalavraDoBanco(
              en: 'apple', pt: 'maçã', origem: OrigemPalavra.minha, criadaEm: 5, atualizadoEm: 9, exemplo: 'An apple.'))
          .com(const PalavraDoBanco(
              en: 'Monday', pt: 'segunda-feira', licaoId: 'a.b', cartao: _c2, vistasJogo: 3, errosJogo: 1, noJogo: false))
          .com(const PalavraDoBanco(en: 'gone', pt: 'ido', removida: true, atualizadoEm: 7))
          .comEmTreino(['Monday', 'apple'], 42);
      final volta = BancoPalavras.decodificar(b.codificar());
      expect(volta, b);
      expect(volta['monday']!.en, 'Monday');
      expect(volta.emTreino, ['monday', 'apple']);
      expect(volta.tamanho, 2, reason: 'a apagada não conta');
    });

    test('lixo vira o banco vazio (nunca lança)', () {
      for (final lixo in [null, '', '{', '[1,2]', '{"p": 3}', 'null', '{"p":[{"x":1}, 7, "a"]}']) {
        expect(BancoPalavras.decodificar(lixo), BancoPalavras.vazio, reason: '$lixo');
      }
      final meio = BancoPalavras.decodificar('{"p":[{"e":"ok","p":"ok"}, {"e":""}, 3], "t": [1, "ok"]}');
      expect(meio.palavras.keys, ['ok']);
      expect(meio.emTreino, ['ok']);
    });
  });

  group('mesclar', () {
    test('a edição mais nova vale; contadores no máximo; cartão revisado por último; em treino do lado mais novo', () {
      final local = const BancoPalavras(emTreino: ['apple'], emTreinoEm: 50).com(const PalavraDoBanco(
          en: 'apple', pt: 'maçã', atualizadoEm: 10, criadaEm: 3, cartao: _c2, vistasJogo: 5, errosJogo: 1));
      final nuvem = const BancoPalavras(emTreino: ['pear'], emTreinoEm: 60)
          .com(const PalavraDoBanco(
              en: 'apple', pt: 'maçã verde', atualizadoEm: 20, criadaEm: 1, cartao: _c1, vistasJogo: 2, errosJogo: 4, noJogo: false))
          .com(const PalavraDoBanco(en: 'pear', pt: 'pera', atualizadoEm: 1));
      final m = BancoPalavras.mesclar(local, nuvem);
      final a = m['apple']!;
      expect(a.pt, 'maçã verde');
      expect(a.noJogo, isFalse);
      expect(a.vistasJogo, 5);
      expect(a.errosJogo, 4);
      expect(a.cartao, _c2, reason: 'ultimoDia 104 > 100');
      expect(a.criadaEm, 1);
      expect(m['pear'], isNotNull);
      expect(m.emTreino, ['pear']);
      // simétrico no resultado
      expect(BancoPalavras.mesclar(nuvem, local)['apple']!.pt, 'maçã verde');
    });

    test('lápide mais nova apaga; edição mais nova que a lápide ressuscita', () {
      const viva = PalavraDoBanco(en: 'apple', pt: 'maçã', atualizadoEm: 10);
      final apagada = const BancoPalavras().com(viva.copyWith(removida: true, atualizadoEm: 20));
      expect(BancoPalavras.mesclar(const BancoPalavras().com(viva), apagada)['apple']!.removida, isTrue);
      final editada = const BancoPalavras().com(viva.copyWith(pt: 'maçãzinha', atualizadoEm: 30));
      expect(BancoPalavras.mesclar(editada, apagada)['apple']!.removida, isFalse);
    });

    test('empate no dia do cartão: vale o com mais revisões', () {
      const a = CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: 100, proximoDia: 101, revisoes: 1);
      const b = CartaoSrs(estabilidade: 3, dificuldade: 5, ultimoDia: 100, proximoDia: 103, revisoes: 3);
      final m = BancoPalavras.mesclar(
        const BancoPalavras().com(const PalavraDoBanco(en: 'x1', pt: 'a', cartao: a)),
        const BancoPalavras().com(const PalavraDoBanco(en: 'x1', pt: 'a', cartao: b)),
      );
      expect(m['x1']!.cartao, b);
    });
  });

  group('força, devidas e fracas', () {
    test('pela estabilidade do cartão', () {
      expect(BancoPalavras.forca(null, 100), ForcaPalavra.nova);
      expect(BancoPalavras.forca(const PalavraDoBanco(en: 'a', pt: ''), 100), ForcaPalavra.nova);
      expect(BancoPalavras.forca(const PalavraDoBanco(en: 'a', pt: '', cartao: _c1), 100), ForcaPalavra.fraca);
      expect(BancoPalavras.forca(const PalavraDoBanco(en: 'a', pt: '', cartao: _c2), 100), ForcaPalavra.boa);
      const firme = CartaoSrs(estabilidade: 30, dificuldade: 5, ultimoDia: 100, proximoDia: 130);
      expect(BancoPalavras.forca(const PalavraDoBanco(en: 'a', pt: '', cartao: firme), 100), ForcaPalavra.firme);
    });

    test('devidas (atrasadas primeiro) e fracas sem repetir as devidas', () {
      final b = const BancoPalavras()
          .com(const PalavraDoBanco(en: 'due', pt: '', cartao: _c1)) // vence 101
          .com(const PalavraDoBanco(en: 'later', pt: '', cartao: _c2)) // vence 110
          .com(const PalavraDoBanco(
              en: 'weak', pt: '', cartao: CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: 104, proximoDia: 106)))
          .com(const PalavraDoBanco(en: 'missed', pt: '', errosJogo: 3))
          .com(const PalavraDoBanco(en: 'off', pt: '', cartao: _c1, removida: true));
      expect(b.devidas(105).map((p) => p.en), ['due']);
      expect(b.devidas(111).map((p) => p.en), ['due', 'weak', 'later']);
      expect(b.fracas(105).map((p) => p.en), ['missed', 'weak']);
    });
  });

  group('nota do treino e agenda', () {
    test('a pior 1ª tentativa vale; sem lembrar de verdade, no máximo "hesitou"', () {
      expect(notaDoTreino([ResultadoRevisao.acertou, ResultadoRevisao.acertou]), ResultadoRevisao.acertou);
      expect(notaDoTreino([ResultadoRevisao.acertou, ResultadoRevisao.hesitou]), ResultadoRevisao.hesitou);
      expect(notaDoTreino([ResultadoRevisao.errou, ResultadoRevisao.acertou]), ResultadoRevisao.errou);
      expect(notaDoTreino([ResultadoRevisao.acertou], recordou: false), ResultadoRevisao.hesitou);
      expect(notaDoTreino([ResultadoRevisao.errou], recordou: false), ResultadoRevisao.errou);
    });

    test('palavra nova volta amanhã; revisão num dia depois avança; mesmo dia só muda se errou', () {
      final ag = AgendadorFsrs(fuzz: false);
      final p = agendar(const PalavraDoBanco(en: 'apple', pt: 'maçã'), ResultadoRevisao.acertou, 100, agendador: ag, agora: 7);
      expect(p.cartao!.proximoDia, 101);
      expect(p.atualizadoEm, 7);
      final mesmoDia = agendar(p, ResultadoRevisao.acertou, 100, agendador: ag);
      expect(mesmoDia.cartao, p.cartao);
      final errouHoje = agendar(p, ResultadoRevisao.errou, 100, agendador: ag);
      expect(errouHoje.cartao!.estabilidade, lessThan(p.cartao!.estabilidade));
      final depois = agendar(p, ResultadoRevisao.acertou, 101, agendador: ag);
      expect(depois.cartao!.proximoDia, greaterThan(102));
      expect(depois.cartao!.revisoes, 2);
    });

    test('errar uma palavra firme já revisada hoje é lapso, não cartão novo (histórico fica)', () {
      final ag = AgendadorFsrs(fuzz: false);
      const firme = CartaoSrs(estabilidade: 40, dificuldade: 4, ultimoDia: 200, proximoDia: 240, revisoes: 9, lapsos: 1);
      const p = PalavraDoBanco(en: 'apple', pt: 'maçã', cartao: firme);
      final errou = agendar(p, ResultadoRevisao.errou, 200, agendador: ag, agora: 9).cartao!;
      expect(errou.revisoes, 10);
      expect(errou.lapsos, 2);
      expect(errou.proximoDia, 201, reason: 'volta amanhã');
      expect(errou.ultimoDia, 200);
      expect(errou.estabilidade, lessThan(40));
      expect(errou.dificuldade, greaterThanOrEqualTo(4), reason: 'a dificuldade segue dali (não volta à de cartão novo)');
      // na mescla com o cartão do mesmo dia de outro aparelho (sem o erro), o lapso ganha
      final outro = BancoPalavras.vazio.com(p.copyWith(atualizadoEm: 1));
      final aqui = BancoPalavras.vazio.com(p.copyWith(cartao: errou, atualizadoEm: 9));
      expect(BancoPalavras.mesclar(outro, aqui)['apple']!.cartao, errou);
      expect(BancoPalavras.mesclar(aqui, outro)['apple']!.cartao, errou);
    });
  });

  group('validarPalavraNova', () {
    final banco = const BancoPalavras()
        .com(const PalavraDoBanco(en: 'apple', pt: 'maçã'))
        .com(const PalavraDoBanco(en: 'gone', pt: 'ido', removida: true));

    test('aceita, limpa e recusa com mensagem em português', () {
      expect(validarPalavraNova('pear', banco), (en: 'pear', erro: null));
      expect(validarPalavraNova('  Pear ', banco).en, 'Pear');
      expect(validarPalavraNova('café', banco), (en: 'cafe', erro: null));
      expect(validarPalavraNova('“hello”', banco), (en: 'hello', erro: null), reason: 'aspas curvas nas pontas saem');
      expect(validarPalavraNova('ice cream', banco).erro, 'Use só letras, sem espaço nem acento (até 14)');
      expect(validarPalavraNova('x', banco).erro, isNotNull);
      expect(validarPalavraNova('abcdefghijklmno', banco).erro, isNotNull, reason: '15 letras');
      expect(validarPalavraNova('abcdefghijklmn', banco).erro, isNull, reason: '14 letras');
      expect(validarPalavraNova('don’t', banco).en, "don't", reason: 'apóstrofo curvo vira reto');
      expect(validarPalavraNova('don’t', banco).erro, isNotNull);
      expect(validarPalavraNova('APPLE', banco).erro, 'Essa palavra já está no seu banco');
      expect(validarPalavraNova('gone', banco).erro, isNull, reason: 'a apagada pode voltar');
      expect(validarPalavraNova('   ', banco).erro, isNotNull);
    });
  });

  group('teimosas no banco', () {
    test('JSON antigo regrava byte a byte; os campos novos vão e voltam; negativos viram 0', () {
      const antigo =
          '{"p":[{"e":"apple","p":"maçã","o":"m","c":5,"u":9},{"e":"Monday","p":"segunda","v":3,"r":1,"j":0}],"t":["apple"],"te":42}';
      expect(BancoPalavras.decodificar(antigo).codificar(), antigo);
      const p = PalavraDoBanco(
        en: 'through',
        pt: 'através',
        cargaErro: 2.35,
        cargaVistas: 3.5,
        cargaDia: 20000,
        errosTotal: 7,
        ultimoErroDia: 19999,
        acertosSeguidos: 1,
        ultimoAcertoDia: 20000,
        foiTeimosa: true,
        dominadaEm: 19000,
        naoSugerirAte: 20014,
      );
      final b = BancoPalavras.vazio.com(p).comSugestao(const EstadoSugestao(
          ultimaMs: 99, ultimaDia: 20000, mostradasHoje: 2, adiadaAteDia: 20001, recusasSeguidas: 1));
      final volta = BancoPalavras.decodificar(b.codificar());
      expect(volta, b);
      expect(b.toJson()['s'], {'m': 99, 'd': 20000, 'n': 2, 'a': 20001, 'r': 1});
      final j = p.toJson();
      expect(j['ce'], 2.35);
      expect(j['ft'], 1);
      // 2 casas e nada de negativo
      final lixo = PalavraDoBanco.fromJson({'e': 'x', 'p': 'y', 'ce': -3, 'cv': 'abc', 'el': -2, 'ok': -1, 'ue': -5})!;
      expect([lixo.cargaErro, lixo.cargaVistas, lixo.errosTotal, lixo.acertosSeguidos, lixo.ultimoErroDia], [0, 0, 0, 0, 0]);
      expect(const PalavraDoBanco(en: 'x', pt: 'y', cargaErro: 1.23456).toJson()['ce'], 1.23);
      // a sugestão vazia não vai para o JSON; com/comEmTreino preservam a sugestão
      expect(BancoPalavras.vazio.toJson().containsKey('s'), isFalse);
      expect(b.com(const PalavraDoBanco(en: 'z', pt: 'z')).comEmTreino(['z'], 5).sugestao, b.sugestao);
    });

    test('mescla: a carga inteira do lado decaído por último (nunca soma); contadores pelo maior; s pelo maior m', () {
      const a = PalavraDoBanco(
          en: 'through', pt: 'a', cargaErro: 3, cargaVistas: 4, cargaDia: 100, errosTotal: 5, ultimoErroDia: 100,
          acertosSeguidos: 0, foiTeimosa: true, naoSugerirAte: 101);
      const b = PalavraDoBanco(
          en: 'through', pt: 'b', cargaErro: 1, cargaVistas: 6, cargaDia: 103, errosTotal: 3, ultimoErroDia: 98,
          acertosSeguidos: 1, ultimoAcertoDia: 103, dominadaEm: 50, naoSugerirAte: 110);
      final local = BancoPalavras.vazio.com(a).comSugestao(const EstadoSugestao(ultimaMs: 10, recusasSeguidas: 2));
      final nuvem = BancoPalavras.vazio.com(b).comSugestao(const EstadoSugestao(ultimaMs: 20, mostradasHoje: 1));
      final m = BancoPalavras.mesclar(local, nuvem)['through']!;
      expect((m.cargaErro, m.cargaVistas, m.cargaDia), (1.0, 6.0, 103), reason: 'o trio do maior cd');
      expect(m.errosTotal, 5);
      expect(m.ultimoErroDia, 100);
      expect((m.acertosSeguidos, m.ultimoAcertoDia), (1, 103), reason: 'do lado com o evento mais novo');
      expect(m.foiTeimosa, isTrue);
      expect(m.dominadaEm, 50);
      expect(m.naoSugerirAte, 110);
      expect(BancoPalavras.mesclar(local, nuvem).sugestao, nuvem.sugestao);
      expect(BancoPalavras.mesclar(nuvem, local).sugestao, nuvem.sugestao);
      // empate de dia: a maior carga
      final c = BancoPalavras.mesclar(
          BancoPalavras.vazio.com(a.copyWith(cargaDia: 103)), BancoPalavras.vazio.com(b))['through']!;
      expect(c.cargaErro, 3);
    });

    test('podado: some a entrada só de erro antigo; fica a treinada, a minha, a fora dos jogos, a teimosa, o foco', () {
      const hoje = 1000;
      const velha = PalavraDoBanco(en: 'old', pt: 'velho', cargaErro: .5, cargaVistas: 1, cargaDia: 800, errosTotal: 1, ultimoErroDia: 800);
      final b = BancoPalavras.vazio
          .com(velha)
          .com(velha.copyWith(en: 'trained', cartao: _c1))
          .com(velha.copyWith(en: 'mine', origem: OrigemPalavra.minha))
          .com(velha.copyWith(en: 'nogame', noJogo: false))
          .com(velha.copyWith(en: 'stubborn', foiTeimosa: true))
          .com(velha.copyWith(en: 'recent', ultimoErroDia: hoje - 10))
          .com(velha.copyWith(en: 'heavy', cargaErro: 5, cargaDia: hoje - 5))
          .com(velha.copyWith(en: 'focus'))
          .com(const PalavraDoBanco(en: 'edited', pt: 'editada', atualizadoEm: 5))
          .comEmTreino(['focus'], 1);
      final p = b.podado(hoje);
      expect(p.palavras.keys.toSet(), b.palavras.keys.toSet()..remove('old'));
      expect(p.emTreino, b.emTreino);
      expect(identical(p.podado(hoje), p), isTrue, reason: 'nada a podar = o mesmo banco');
    });

    test('podado: nunca as sem data de erro (de antes das teimosas, só parciais) nem as candidatas a fraca', () {
      const hoje = 1000;
      const velha = PalavraDoBanco(en: 'old', pt: 'velho', cargaErro: .5, cargaVistas: 1, cargaDia: 800, errosTotal: 1, ultimoErroDia: 800);
      final b = BancoPalavras.vazio
          .com(velha)
          // do round 1: só contadores dos jogos, sem carga nem data de erro
          .com(const PalavraDoBanco(en: 'legacy', pt: 'antiga', errosJogo: 1, vistasJogo: 3))
          // só erros parciais (f < 1): carga gravada, mas sem "último erro"
          .com(const PalavraDoBanco(en: 'partial', pt: 'parcial', cargaErro: .25, cargaVistas: .5, cargaDia: 800, errosJogo: 1))
          // erro antigo com data, mas sem carga gravada
          .com(velha.copyWith(en: 'nocarga', cargaErro: 0, cargaVistas: 0, cargaDia: 0))
          // fraca: sem cartão, 2+ erros nos jogos
          .com(velha.copyWith(en: 'weak', errosJogo: 2));
      final p = b.podado(hoje);
      expect(p.palavras.keys.toSet(), {'legacy', 'partial', 'nocarga', 'weak'});
      expect(p.fracas(hoje).map((x) => x.chave), ['weak']);
    });

    test('mescla depois de DOMINAR: a nuvem com ft de antes não traz a marca de volta; empate de dia fica com a carga cortada', () {
      const hoje = 500;
      // a nuvem: gravada hoje cedo, ainda teimosa (com uma evidência de hoje)
      const antes = PalavraDoBanco(
          en: 'through', pt: 'através', cargaErro: 2, cargaVistas: 3, cargaDia: hoje, errosTotal: 3,
          ultimoErroDia: hoje - 2, acertosSeguidos: 1, ultimoAcertoDia: hoje - 1, foiTeimosa: true);
      // o aparelho: dominou hoje (ft sai, carga a 30%)
      final depois = antes.copyWith(
          cargaErro: .6, ultimoAcertoDia: hoje, acertosSeguidos: 0, foiTeimosa: false, dominadaEm: hoje);
      for (final (l, n) in [(depois, antes), (antes, depois)]) {
        final m = BancoPalavras.mesclar(BancoPalavras.vazio.com(l), BancoPalavras.vazio.com(n))['through']!;
        expect(m.foiTeimosa, isFalse, reason: 'o ft da nuvem é de antes de dominar');
        expect(m.dominadaEm, hoje);
        expect(m.cargaErro, closeTo(.6, 1e-9), reason: 'mesmo cd: vale o lado que dominou');
        expect(ehTeimosa(m, hoje), isFalse);
      }
      // errou DEPOIS de dominar (no outro aparelho): a marca desse lado vale
      final errouDepois = depois.copyWith(ultimoErroDia: hoje + 3, cargaDia: hoje + 3, cargaErro: 2, foiTeimosa: true);
      final m2 = BancoPalavras.mesclar(BancoPalavras.vazio.com(depois), BancoPalavras.vazio.com(errouDepois))['through']!;
      expect(m2.foiTeimosa, isTrue);
      expect(m2.ultimoErroDia, hoje + 3);
    });

    test('a sugestão grava e volta com ms e dias de verdade (nada de 1 << 53, que no web vira 0)', () {
      const s = EstadoSugestao(
          ultimaMs: 1792000000000, ultimaDia: 20381, mostradasHoje: 2, adiadaAteDia: 20384, recusasSeguidas: 3);
      final volta = BancoPalavras.decodificar(BancoPalavras.vazio.comSugestao(s).codificar()).sugestao;
      expect(volta, s);
      expect(EstadoSugestao.fromJson({'m': -5, 'd': 1.5e3, 'n': 'x', 'a': '20384'}),
          const EstadoSugestao(ultimaDia: 1500, adiadaAteDia: 20384));
    });
  });
}
