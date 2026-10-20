// O roteiro da sessão de treino de palavras: ordem e contagem dos passos, opções sem repetir, reserva
// quando faltam palavras, o passo errado que volta (até 2 vezes), a nota de cada palavra e o teto de 8.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/domain/roteiro_treino.dart';

PalavraNova _p(String en, String pt) => PalavraNova(en: en, pt: pt, ptCompleta: pt, licaoId: 'l1');

final _seis = [
  _p('coffee', 'café'),
  _p('morning', 'manhã'),
  _p('tired', 'cansado'),
  _p('table', 'mesa'),
  _p('window', 'janela'),
  _p('bread', 'pão'),
];

/// Responde tudo certo (digitando a palavra exata) até o fim.
void _tudoCerto(RoteiroTreino r) {
  while (!r.terminou) {
    final p = r.atual!;
    switch (p.tipo) {
      case TipoPasso.conhecer:
      case TipoPasso.relembrar:
        break;
      case TipoPasso.escolherPt:
      case TipoPasso.ouvirEscolher:
        r.responder(ResultadoRevisao.acertou);
      case TipoPasso.pares:
        for (final i in p.esquerda) {
          r.acertouPar(i);
        }
        r.terminouPares();
      case TipoPasso.digitar:
        r.responder(notaDigitada(r.itens[p.item].en, r.itens[p.item].en));
    }
    r.avancar();
  }
}

void main() {
  test('ordem e contagem: conhecer → escolher → pares → ouvir (metade) → digitar', () {
    final r = montarRoteiroTreino(_seis, rnd: Random(1));
    final tipos = r.passos.map((p) => p.tipo).toList();
    expect(tipos.where((t) => t == TipoPasso.conhecer).length, 6);
    expect(tipos.where((t) => t == TipoPasso.escolherPt).length, 6);
    expect(tipos.where((t) => t == TipoPasso.pares).length, 1);
    expect(tipos.where((t) => t == TipoPasso.ouvirEscolher).length, 3);
    expect(tipos.where((t) => t == TipoPasso.digitar).length, 6);
    // em blocos, nessa ordem
    final ordem = <TipoPasso>[];
    for (final t in tipos) {
      if (ordem.isEmpty || ordem.last != t) ordem.add(t);
    }
    expect(ordem, TipoPasso.values.where((t) => t != TipoPasso.relembrar), reason: 'relembrar é só da revanche');
    // conhecer na ordem da lição; cada palavra é digitada uma vez
    expect([for (final p in r.passos.take(6)) p.item], [0, 1, 2, 3, 4, 5]);
    expect({for (final p in r.passos.where((p) => p.tipo == TipoPasso.digitar)) p.item}, {0, 1, 2, 3, 4, 5});
    // pares: até 5, as mesmas palavras nas duas colunas
    final pares = r.passos.firstWhere((p) => p.tipo == TipoPasso.pares);
    expect(pares.esquerda.length, 5);
    expect(pares.esquerda.toSet(), pares.direita.toSet());
  });

  test('cada escolha tem 4 opções diferentes e a certa está entre elas', () {
    final r = montarRoteiroTreino(_seis, rnd: Random(1));
    for (final p in r.passos.where((p) => p.deEscolha)) {
      expect(p.opcoes.length, 4, reason: '$p');
      expect(p.opcoes.map((o) => o.toLowerCase()).toSet().length, 4, reason: '${p.opcoes}');
      final item = r.itens[p.item];
      expect(p.opcoes[p.correta], p.tipo == TipoPasso.escolherPt ? item.pt : item.en);
      expect(p.opcoes.where((o) => o == (p.tipo == TipoPasso.escolherPt ? item.pt : item.en)).length, 1);
    }
  });

  test('com menos de 4 palavras as opções vêm da reserva e, sem ela, da lista fixa', () {
    final duas = [_p('coffee', 'café'), _p('house', 'casa')];
    final comReserva = montarRoteiroTreino(duas,
        reserva: [_p('table', 'mesa'), _p('window', 'janela'), _p('coffee', 'café')], rnd: Random(1));
    final e = comReserva.passos.firstWhere((p) => p.tipo == TipoPasso.escolherPt);
    expect(e.opcoes.length, 4);
    expect(e.opcoes.toSet().length, 4);
    final semReserva = montarRoteiroTreino(duas, rnd: Random(1));
    for (final p in semReserva.passos.where((p) => p.deEscolha)) {
      expect(p.opcoes.length, 4);
      expect(p.opcoes.toSet().length, 4);
      // "home" também é "casa": nunca vira opção errada de "house"
      if (semReserva.itens[p.item].en == 'house') {
        expect(p.opcoes, isNot(contains('home')));
        expect(p.opcoes.where((o) => o == 'casa').length, lessThanOrEqualTo(1));
      }
    }
    // com 2 palavras não há tabuleiro de pares; ouvir = 1
    expect(semReserva.passos.where((p) => p.tipo == TipoPasso.pares), isEmpty);
    expect(semReserva.passos.where((p) => p.tipo == TipoPasso.ouvirEscolher).length, 1);
  });

  test('o passo errado volta 3 passos depois, no máximo 2 vezes', () {
    final r = montarRoteiroTreino(_seis, rnd: Random(1));
    while (r.atual!.tipo != TipoPasso.escolherPt) {
      r.avancar();
    }
    final total = r.passos.length;
    final item = r.atual!.item;
    final onde = r.indice;
    r.responder(ResultadoRevisao.errou);
    expect(r.passos.length, total + 1);
    final volta = r.passos[onde + 1 + RoteiroTreino.distanciaVolta];
    expect(volta.tipo, TipoPasso.escolherPt);
    expect(volta.item, item);
    expect(volta.vez, 1);
    expect(volta.opcoes.toSet(), r.passos[onde].opcoes.toSet());
    // erra de novo nas voltas: volta só mais uma vez
    var voltas = 0;
    r.avancar();
    while (!r.terminou) {
      final p = r.atual!;
      if (p.tipo == TipoPasso.escolherPt && p.item == item) {
        voltas++;
        r.responder(ResultadoRevisao.errou);
      }
      r.avancar();
    }
    expect(voltas, 2);
    expect(r.passos.where((p) => p.tipo == TipoPasso.escolherPt && p.item == item).length, 3);
  });

  test('a barra de progresso não anda para trás quando um passo volta', () {
    final r = montarRoteiroTreino(_seis, rnd: Random(1));
    for (var i = 0; i < 6; i++) {
      r.avancar();
    }
    final antes = r.progresso;
    r.responder(ResultadoRevisao.errou);
    expect(r.progresso, antes);
    r.avancar();
    expect(r.progresso, greaterThan(antes));
  });

  test('notas: digitar certinho = acertou; um errinho em 5+ letras = hesitou; dica/não sei/errado = errou', () {
    expect(notaDigitada('coffee', 'coffee'), ResultadoRevisao.acertou);
    expect(notaDigitada(' Monday ', 'Monday'), ResultadoRevisao.acertou);
    expect(notaDigitada('monday', 'Monday'), ResultadoRevisao.acertou);
    expect(notaDigitada('cofee', 'coffee'), ResultadoRevisao.hesitou);
    expect(notaDigitada('tyred', 'tired'), ResultadoRevisao.hesitou);
    expect(notaDigitada('bred', 'bread'), ResultadoRevisao.errou, reason: 'faltou letra numa de 4: sem folga');
    expect(notaDigitada('cat', 'car'), ResultadoRevisao.errou, reason: 'palavra curta não tem folga');
    expect(notaDigitada('coffee', 'coffee', dica: true), ResultadoRevisao.errou);
    expect(notaDigitada('', 'coffee', naoSei: true), ResultadoRevisao.errou);
    expect(notaDigitada('', 'coffee'), ResultadoRevisao.errou);
    expect(notaDigitada('table', 'coffee'), ResultadoRevisao.errou);
  });

  test('a nota da palavra é a pior 1ª tentativa; reconhecer sem digitar fica no máximo em hesitou', () {
    // tudo certo: todas acertou, 100% de primeira
    final certo = montarRoteiroTreino(_seis, rnd: Random(1));
    _tudoCerto(certo);
    final rc = certo.resultado();
    expect(rc.notas.length, 6);
    expect(rc.notas.values.every((n) => n == ResultadoRevisao.acertou), isTrue);
    expect(rc.pct, 100);
    expect(rc.dePrimeira, 6);
    expect(rc.paraRegistrar.length, 6);
    expect(rc.passos, 6 + 1 + 3 + 6, reason: 'escolher + pares + ouvir + digitar');

    // errar a escolha de uma palavra: ela fica "errou" mesmo digitando certo depois
    final r = montarRoteiroTreino(_seis, rnd: Random(1));
    int? errada;
    while (!r.terminou) {
      final p = r.atual!;
      switch (p.tipo) {
        case TipoPasso.conhecer:
        case TipoPasso.relembrar:
          break;
        case TipoPasso.escolherPt:
          if (errada == null && p.vez == 0) {
            errada = p.item;
            r.responder(ResultadoRevisao.errou);
          } else {
            r.responder(ResultadoRevisao.acertou);
          }
        case TipoPasso.ouvirEscolher:
          r.responder(ResultadoRevisao.acertou);
        case TipoPasso.pares:
          for (final i in p.esquerda) {
            r.acertouPar(i);
          }
          r.terminouPares();
        case TipoPasso.digitar:
          final en = r.itens[p.item].en;
          // um errinho de digitação em "morning" (7 letras)
          r.responder(notaDigitada(en == 'morning' ? 'mornin' : en, en));
      }
      r.avancar();
    }
    final notas = r.resultado().notas;
    expect(notas[r.itens[errada!].chave], ResultadoRevisao.errou);
    expect(notas['morning'], errada == 1 ? ResultadoRevisao.errou : ResultadoRevisao.hesitou);
    expect(notas.values.where((n) => n == ResultadoRevisao.acertou).length, errada == 1 ? 5 : 4);

    // pares: errar parte da palavra tocada primeiro
    final rp = montarRoteiroTreino(_seis, rnd: Random(1));
    while (rp.atual!.tipo != TipoPasso.pares) {
      rp.avancar();
    }
    final tab = rp.atual!;
    rp.errouPar(tab.esquerda.first);
    rp.errouPar(tab.esquerda.first); // a 2ª vez não conta de novo
    for (final i in tab.esquerda) {
      rp.acertouPar(i);
    }
    final np = rp.resultado().notas;
    expect(np[rp.itens[tab.esquerda.first].chave], ResultadoRevisao.errou);
    // sem passo de digitar, acertar o par vale no máximo "hesitou"
    expect(np[rp.itens[tab.esquerda[1]].chave], ResultadoRevisao.hesitou);
  });

  test('no máximo 8 palavras por sessão, sem repetir; lotes do mesmo tamanho', () {
    final doze = [for (var i = 0; i < 12; i++) _p('word${String.fromCharCode(97 + i)}', 'palavra $i')];
    final r = montarRoteiroTreino([...doze, doze.first], rnd: Random(1));
    expect(r.itens.length, 8);
    expect(r.passos.where((p) => p.tipo == TipoPasso.conhecer).length, 8);
    expect(r.passos.where((p) => p.tipo == TipoPasso.ouvirEscolher).length, 4);
    final lotes = lotesDeTreino([...doze, doze.first]);
    expect(lotes.map((l) => l.length), [6, 6]);
    expect(lotesDeTreino(_seis).map((l) => l.length), [6]);
    expect(lotesDeTreino([...doze, _p('extra', 'x'), _p('more', 'y'), _p('again', 'z'), _p('other', 'w')])
        .map((l) => l.length), [8, 8]);
    expect(lotesDeTreino(const []), isEmpty);
  });

  test('determinístico com a mesma semente', () {
    String roteiro(int semente) =>
        montarRoteiroTreino(_seis, rnd: Random(semente)).passos.map((p) => '$p${p.opcoes}${p.esquerda}').join(';');
    expect(roteiro(1), roteiro(1));
    expect(roteiro(1), isNot(roteiro(2)));
  });

  test('juntar rodadas: a pior nota vale e os passos somam', () {
    const a = ResultadoTreino(
        palavras: [PalavraNova(en: 'coffee', pt: 'café')],
        notas: {'coffee': ResultadoRevisao.acertou},
        passos: 4,
        pct: 100);
    const b = ResultadoTreino(
        palavras: [PalavraNova(en: 'coffee', pt: 'café'), PalavraNova(en: 'tea', pt: 'chá')],
        notas: {'coffee': ResultadoRevisao.errou, 'tea': ResultadoRevisao.acertou},
        passos: 4,
        pct: 50,
        jogar: true);
    final j = a.juntar(b);
    expect(j.notas, {'coffee': ResultadoRevisao.errou, 'tea': ResultadoRevisao.acertou});
    expect(j.palavras.length, 2);
    expect(j.passos, 8);
    expect(j.pct, 75);
    expect(j.jogar, isTrue);
  });

  test('revanche: sem conhecer; relembrar → ouvir (todas) → digitar sem dica → digitar de novo no fim', () {
    final tres = _seis.take(3).toList();
    final r = montarRoteiroTreino(tres, rnd: Random(3), revanche: true);
    final tipos = r.passos.map((p) => p.tipo).toList();
    expect(tipos, isNot(contains(TipoPasso.conhecer)));
    expect(tipos, isNot(contains(TipoPasso.escolherPt)));
    expect(tipos, isNot(contains(TipoPasso.pares)));
    expect(tipos.take(3), everyElement(TipoPasso.relembrar));
    expect([for (final p in r.passos.take(3)) p.item], [0, 1, 2]);
    expect(tipos.skip(3).take(3), everyElement(TipoPasso.ouvirEscolher));
    expect(tipos.skip(6), everyElement(TipoPasso.digitar));
    expect(tipos.skip(6), hasLength(6), reason: 'duas rodadas de digitar');
    final digitar = r.passos.where((p) => p.tipo == TipoPasso.digitar).toList();
    expect(digitar.every((p) => p.semDica), isTrue, reason: 'sem a inicial apagadinha');
    expect({for (final p in digitar.take(3)) p.item}, {0, 1, 2});
    expect({for (final p in digitar.skip(3)) p.item}, {0, 1, 2});
    expect(r.passos.first.avaliado, isFalse, reason: 'relembrar não vale nota');
    // tudo certo: cada palavra "acertou" (lembrou digitando)
    _tudoCerto(r);
    final res = r.resultado();
    expect(res.notas.values, everyElement(ResultadoRevisao.acertou));
    expect(res.passos, 3 + 6);
    // errar a 2ª rodada de digitar de uma palavra conta: a pior 1ª tentativa
    final r2 = montarRoteiroTreino(tres, rnd: Random(3), revanche: true);
    var digitadas = 0;
    while (!r2.terminou) {
      final p = r2.atual!;
      if (p.tipo == TipoPasso.ouvirEscolher) r2.responder(ResultadoRevisao.acertou);
      if (p.tipo == TipoPasso.digitar) {
        digitadas++;
        final en = r2.itens[p.item].en;
        r2.responder(digitadas == 4 ? ResultadoRevisao.errou : notaDigitada(en, en));
      }
      r2.avancar();
    }
    expect(r2.resultado().notas.values.where((n) => n == ResultadoRevisao.errou), hasLength(1));
    // o passo que volta continua sem dica
    expect(r2.passos.where((p) => p.vez > 0).every((p) => p.semDica), isTrue);
  });
}
