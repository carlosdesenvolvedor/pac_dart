// "Palavras teimosas" — o modelo: carga de erro com meia-vida de 14 dias, a pontuação (a tabela de
// sanidade do plano), lapsos e dificuldade do cartão, o ranking, a sequência de acertos (1 por dia; erro
// zera), DOMINADA (2 dias diferentes depois do último erro), jogo sem crédito limpo e a política de oferta.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/banco_palavras.dart';
import 'package:pac_dart/features/ingles/domain/entrada_resposta.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';
import 'package:pac_dart/features/ingles/domain/teimosas.dart';

const _h = 20000;
const _p0 = PalavraDoBanco(en: 'through', pt: 'através');

EvidenciaPalavra _ev(double f, {FonteErro fonte = FonteErro.licao, double? peso, String chave = 'through'}) =>
    EvidenciaPalavra(chave: chave, peso: peso ?? pesoDaFonte(fonte), falha: f, fonte: fonte);

PalavraDoBanco _aplica(PalavraDoBanco p, List<EvidenciaPalavra> evs, [int dia = _h]) => aplicarEvidencias(p, evs, dia).$1;

void main() {
  group('a tabela de sanidade', () {
    test('1 escorregão: E = 1 → não', () {
      final p = _aplica(_p0, [_ev(1)]);
      expect(p.cargaErro, 1);
      expect(p.errosTotal, 1);
      expect(p.ultimoErroDia, _h);
      expect(ehTeimosa(p, _h), isFalse);
      expect(p.foiTeimosa, isFalse);
    });

    test('2 erros em 2 vistas: E 2, taxa 0,575, pontuação 1,15 → SIM (e fica marcada)', () {
      final p = _aplica(_p0, [_ev(1), _ev(1)]);
      expect(cargaEm(p, _h), 2);
      expect(taxaDeErro(p, _h), closeTo(.575, 1e-9));
      expect(pontuacaoTeimosa(p, _h), closeTo(1.15, 1e-9));
      expect(ehTeimosa(p, _h), isTrue);
      expect(p.foiTeimosa, isTrue);
      expect(p.errosTotal, 2);
    });

    test('2 erros em 10 vistas: pontuação 0,38 → não', () {
      final p = _aplica(_p0, [_ev(1), _ev(1), for (var i = 0; i < 8; i++) _ev(0)]);
      expect(pontuacaoTeimosa(p, _h), closeTo(.383, .001));
      expect(ehTeimosa(p, _h), isFalse);
    });

    // o MODELO, com uma evidência por ocorrência; o caminho de verdade (uma partida = uma evidência com teto
    // dos dois lados) está em ingles_palavras_cubit_test ("Chuva pelo registrarJogo")
    test('4 quedas na Chuva em 6 vistas: E 2, N 3, pontuação 0,92 → SIM', () {
      final p = _aplica(_p0, [
        for (var i = 0; i < 4; i++) _ev(1, fonte: FonteErro.chuva),
        for (var i = 0; i < 2; i++) _ev(0, fonte: FonteErro.chuva),
      ]);
      expect(p.cargaErro, closeTo(2, 1e-9));
      expect(p.cargaVistas, closeTo(3, 1e-9));
      expect(pontuacaoTeimosa(p, _h), closeTo(.92, 1e-9));
      expect(ehTeimosa(p, _h), isTrue);
      expect(p.errosTotal, 0, reason: 'erro de jogo não entra no "errou Nx"');
    });

    test('3 erros só na fala: E 1,2 → não', () {
      final p = _aplica(_p0, [for (var i = 0; i < 3; i++) _ev(1, peso: pesoDaFonte(FonteErro.licao, entrada: _falar))]);
      expect(p.cargaErro, closeTo(1.2, 1e-9));
      expect(ehTeimosa(p, _h), isFalse);
    });

    test('14 dias sem erro: a carga cai pela metade (e decai antes de somar)', () {
      final p = _aplica(_p0, [_ev(1), _ev(1)]);
      expect(cargaEm(p, _h + 14), closeTo(1, 1e-9));
      expect(vistasEm(p, _h + 14), closeTo(1, 1e-9));
      expect(ehTeimosa(p, _h + 14), isFalse);
      final depois = _aplica(p, [_ev(1)], _h + 14);
      expect(depois.cargaErro, closeTo(2, 1e-9));
      expect(depois.cargaDia, _h + 14);
      expect(fatorDecaimento(28), closeTo(.25, 1e-9));
    });
  });

  test('2 lapsos no cartão já marcam; dificuldade ≥ 7 soma 0,5', () {
    const lapsos = PalavraDoBanco(
        en: 'enough', pt: 'suficiente', cartao: CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: 1, proximoDia: 2, lapsos: 2));
    expect(ehTeimosa(lapsos, _h), isTrue);
    expect(pontuacaoTeimosa(lapsos, _h), closeTo(.8, 1e-9));
    final base = _aplica(_p0, [_ev(1)]);
    final dificil = base.copyWith(cartao: const CartaoSrs(estabilidade: 1, dificuldade: 7.5, ultimoDia: 1, proximoDia: 2));
    expect(pontuacaoTeimosa(dificil, _h) - pontuacaoTeimosa(base, _h), closeTo(.5, 1e-9));
    expect(ehTeimosa(lapsos.copyWith(removida: true), _h), isFalse, reason: 'apagada nunca é teimosa');
  });

  test('ranking: mais teimosa primeiro, empate pelo erro mais recente, adiadas ("Já sei") de fora', () {
    PalavraDoBanco t(String en, int erros, int ue, {int ni = 0}) => PalavraDoBanco(
          en: en,
          pt: en,
          cargaErro: erros.toDouble(),
          cargaVistas: erros.toDouble(),
          cargaDia: _h,
          ultimoErroDia: ue,
          naoSugerirAte: ni,
        );
    final banco = BancoPalavras.vazio
        .com(t('because', 2, _h - 3))
        .com(t('through', 4, _h - 1))
        .com(t('enough', 2, _h - 1))
        .com(t('though', 5, _h, ni: _h + 3))
        .com(t('fine', 1, _h));
    final r = palavrasTeimosas(banco, _h);
    expect(r.map((p) => p.en), ['through', 'enough', 'because']);
    expect(palavrasTeimosas(banco, _h, max: 1).map((p) => p.en), ['through']);
    expect(palavrasTeimosas(banco, _h + 3).map((p) => p.en).first, 'though', reason: 'o adiamento acabou');
    expect(palavrasTeimosas(banco, _h, extras: ['fine']).map((p) => p.en), contains('fine'),
        reason: 'a sanguessuga dá +1 só na conta');
    expect(banco['fine']!.cargaErro, 1, reason: 'nada gravado');
  });

  group('sequência de acertos e DOMINADA', () {
    final teimosa = _aplica(_p0, [_ev(1), _ev(1)]); // ue = _h, ft

    test('acerto limpo: no máximo 1 por dia; um erro zera', () {
      var p = _aplica(teimosa, [_ev(0)], _h + 1);
      expect(p.acertosSeguidos, 1);
      expect(p.ultimoAcertoDia, _h + 1);
      p = _aplica(p, [_ev(0), _ev(0, fonte: FonteErro.cartao)], _h + 1);
      expect(p.acertosSeguidos, 1, reason: 'o mesmo dia não conta duas vezes');
      p = _aplica(p, [_ev(.5)], _h + 1);
      expect(p.acertosSeguidos, 1, reason: 'meio erro não zera nem soma');
      p = _aplica(p, [_ev(1)], _h + 2);
      expect(p.acertosSeguidos, 0);
      expect(p.ultimoErroDia, _h + 2);
    });

    test('palavra leve (E < 0,5, nunca teimosa) não conta acertos', () {
      final leve = _aplica(_p0, [_ev(.3)]);
      expect(_aplica(leve, [_ev(0)], _h + 1).acertosSeguidos, 0);
    });

    test('jogo nunca dá crédito limpo (é cópia)', () {
      final p = _aplica(teimosa, [_ev(0, fonte: FonteErro.rali), _ev(0, fonte: FonteErro.turismo)], _h + 1);
      expect(p.acertosSeguidos, 0);
    });

    test('DOMINADA: 2 acertos limpos em dias diferentes depois do último erro', () {
      var (p, dom) = aplicarEvidencias(teimosa, [_ev(0, fonte: FonteErro.treino)], _h + 1);
      expect(dom, isFalse);
      expect(p.acertosSeguidos, 1);
      (p, dom) = aplicarEvidencias(p, [_ev(0)], _h + 1);
      expect(dom, isFalse, reason: 'mesmo dia');
      (p, dom) = aplicarEvidencias(p, [_ev(0, fonte: FonteErro.revisao)], _h + 2);
      expect(dom, isTrue);
      expect(p.dominadaEm, _h + 2);
      expect(p.foiTeimosa, isFalse);
      expect(p.acertosSeguidos, 0);
      expect(p.cargaErro, closeTo(cargaEm(teimosa, _h + 2) * .3, 1e-9));
      expect(ehTeimosa(p, _h + 2), isFalse);
    });

    test('DOMINADA com lapsos no cartão sai da lista e não volta (nem é dominada de novo) sem um erro novo', () {
      const cartao = CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: 1, proximoDia: 2, lapsos: 3);
      var (p, dom) = aplicarEvidencias(_p0.copyWith(cartao: cartao), [_ev(1)], _h);
      expect(p.foiTeimosa, isTrue);
      (p, _) = aplicarEvidencias(p, [_ev(0, fonte: FonteErro.treino)], _h + 1);
      (p, dom) = aplicarEvidencias(p, [_ev(0, fonte: FonteErro.revisao)], _h + 2);
      expect(dom, isTrue);
      expect(p.cartao!.lapsos, 3, reason: 'os lapsos do FSRS nunca descem');
      expect(ehTeimosa(p, _h + 2), isFalse);
      expect(palavrasTeimosas(BancoPalavras.vazio.com(p), _h + 2), isEmpty, reason: 'nada de 🔥 e 🏆 ao mesmo tempo');
      expect(ehTeimosa(p, _h + 2, extra: 1), isFalse, reason: 'nem com a sanguessuga');
      // acertos (e jogo) depois: nem volta a marca nem uma 2ª DOMINADA
      for (var d = 3; d <= 6; d++) {
        (p, dom) = aplicarEvidencias(p, [_ev(0), _ev(0, fonte: FonteErro.chuva)], _h + d);
        expect(dom, isFalse, reason: 'dia +$d');
        expect(p.foiTeimosa, isFalse, reason: 'dia +$d');
      }
      expect(p.dominadaEm, _h + 2);
      // um erro de verdade DEPOIS de dominar: ela volta
      (p, _) = aplicarEvidencias(p, [_ev(1)], _h + 7);
      expect(ehTeimosa(p, _h + 7), isTrue);
      expect(p.foiTeimosa, isTrue);
    });
  });

  test('vezesDe: conta os lapsos do cartão (quem já tinha cartão antes das teimosas não vira "1x")', () {
    const cartao = CartaoSrs(estabilidade: 1, dificuldade: 5, ultimoDia: 1, proximoDia: 2, lapsos: 3);
    expect(vezesDe(_p0), 1);
    expect(vezesDe(_p0.copyWith(cartao: cartao)), 3);
    expect(vezesDe(_p0.copyWith(cartao: cartao, errosTotal: 5)), 5);
    expect(vezesDe(_p0.copyWith(errosJogo: 4)), 4);
  });

  group('a política de oferta', () {
    const ms = 1000000000;
    const min = 60 * 1000;

    test('intervalo de 20 minutos (menos no fim da revisão) e no máximo 3 por dia', () {
      var e = EstadoSugestao.vazio;
      expect(podeOferecer(e, _h, ms, LocalSugestao.fimDeLicao), isTrue);
      e = sugestaoMostrada(e, _h, ms);
      expect(e.mostradasHoje, 1);
      expect(podeOferecer(e, _h, ms + 19 * min, LocalSugestao.fimDeJogo), isFalse);
      expect(podeOferecer(e, _h, ms + 19 * min, LocalSugestao.fimDeRevisao), isTrue);
      expect(podeOferecer(e, _h, ms + 21 * min, LocalSugestao.entreFases), isTrue);
      e = sugestaoMostrada(sugestaoMostrada(e, _h, ms + 30 * min), _h, ms + 60 * min);
      expect(e.mostradasHoje, 3);
      expect(podeOferecer(e, _h, ms + 120 * min, LocalSugestao.fimDeRevisao), isFalse, reason: '3 hoje');
      expect(podeOferecer(e, _h + 1, ms + 24 * 60 * min, LocalSugestao.fimDeLicao), isTrue, reason: 'outro dia');
      expect(sugestaoMostrada(e, _h + 1, ms + 24 * 60 * min).mostradasHoje, 1);
    });

    test('"Agora não" → amanhã; o 3º seguido → 3 dias; aceitar zera', () {
      var e = sugestaoAdiada(EstadoSugestao.vazio, _h);
      expect(e.adiadaAteDia, _h + 1);
      expect(podeOferecer(e, _h, ms, LocalSugestao.fimDeRevisao), isFalse);
      expect(podeOferecer(e, _h + 1, ms, LocalSugestao.fimDeRevisao), isTrue);
      e = sugestaoAdiada(e, _h + 1);
      e = sugestaoAdiada(e, _h + 2);
      expect(e.recusasSeguidas, 3);
      expect(e.adiadaAteDia, _h + 5);
      e = sugestaoAceita(e);
      expect(e.recusasSeguidas, 0);
      expect(sugestaoAdiada(e, _h + 6).adiadaAteDia, _h + 7);
    });

    test('o mínimo: 2+ da sessão com soma ≥ 1,5, ou 3+ de sempre e um erro de verdade na sessão', () {
      PalavraDoBanco g(String en) => PalavraDoBanco(en: en, pt: 'pt-$en', errosTotal: 4);
      final globais = [g('because'), g('enough'), g('though')];
      final s = montarSugestao(daSessao: {'through': 2.0, 'quiet': 1.5, 'fine': .3}, globais: globais)!;
      expect(s.daSessao, isTrue);
      expect(s.palavras, ['through', 'quiet', 'because', 'enough', 'though'], reason: 'as da sessão primeiro');
      expect(s.vezes['because'], 4);
      expect(s.itens[2], ('because', 'pt-because', 4));
      expect(montarSugestao(daSessao: {'through': 2.0}, globais: globais.take(2).toList()), isNull);
      final g3 = montarSugestao(daSessao: {'fine': 1.0}, globais: globais)!;
      expect(g3.daSessao, isFalse);
      expect(g3.palavras.first, 'fine');
      expect(montarSugestao(daSessao: {'fine': .5}, globais: globais), isNull, reason: 'sem erro de verdade na sessão');
      expect(montarSugestao(daSessao: {}, globais: globais), isNull);
      final muitas = montarSugestao(daSessao: {for (var i = 0; i < 12; i++) 'w$i': 2.0 + i}, globais: globais)!;
      expect(muitas.palavras, hasLength(8));
      expect(muitas.palavras.first, 'w11');
    });
  });

  test('nada de shift de 32+ no inglês (no web, dart2js, `1 << 53` vale 0)', () {
    final shift = RegExp(r'<<\s*(3[2-9]|[4-9]\d|\d{3,})\b');
    final ruins = <String>[];
    for (final f in Directory('lib/features/ingles').listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final linhas = f.readAsLinesSync();
      for (var i = 0; i < linhas.length; i++) {
        if (shift.hasMatch(linhas[i]) && !linhas[i].trimLeft().startsWith('//')) ruins.add('${f.path}:${i + 1}');
      }
    }
    expect(ruins, isEmpty);
  });
}

const _falar = EntradaResposta.falar;
