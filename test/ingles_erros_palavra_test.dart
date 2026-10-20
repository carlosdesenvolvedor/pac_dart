// "Palavras teimosas" — a captura: uma evidência por palavra de cada frase de memória (pelo texto que
// VALEU), erros crus por palavra (1 → 0,5/0,3; 2+ ou revelada → 1), o Esc só na palavra do cursor, o peso
// de Montar/Falar e os cartões conferidos palavra a palavra.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/ingles/domain/comparar_resposta.dart';
import 'package:pac_dart/features/ingles/domain/dicionario.dart';
import 'package:pac_dart/features/ingles/domain/entrada_resposta.dart';
import 'package:pac_dart/features/ingles/domain/erros_palavra.dart';
import 'package:pac_dart/features/ingles/domain/palavras_novas.dart';
import 'package:pac_dart/features/ingles/domain/srs.dart';

/// Uma chave de teste parecida com a do cubit: sem curtas, apóstrofo, dígito nem palavras de função.
String? _chave(String w) {
  final k = Dicionario.normalizar(w);
  if (k.length < 3 || k.contains("'") || RegExp('[0-9]').hasMatch(k) || stopwordsEn.contains(k)) return null;
  return k;
}

Map<String, double> _falhas(List<EvidenciaPalavra> evs) => {for (final e in evs) e.chave: e.falha};

void main() {
  test('o texto ACEITO manda: "I am tired" (alternativa de "I\'m tired") acha "tired" no lugar certo', () {
    const aceita = 'I am tired.';
    final i = aceita.indexOf('tired');
    final evs = evidenciasDaFrase(aceita, teclas: {i + 1: 1}, fonte: FonteErro.licao, chaveDe: _chave);
    expect(evs.map((e) => e.chave), ['tired'], reason: 'I e am são palavras de função');
    expect(evs.single.falha, .5, reason: '1 erro numa palavra de 5 letras');
    expect(evs.single.peso, 1.0);
  });

  test('erros crus por palavra: 1 → 0,5 (5+ letras) ou 0,3; 2 → 1; letra revelada → 1; limpa → 0', () {
    const f = 'Good morning, your book.';
    final good = f.indexOf('Good'), morning = f.indexOf('morning'), book = f.indexOf('book');
    var evs = evidenciasDaFrase(f, teclas: {good: 1, morning + 2: 1}, fonte: FonteErro.licao, chaveDe: _chave);
    expect(_falhas(evs), {'good': .3, 'morning': .5, 'book': 0.0});
    evs = evidenciasDaFrase(f, teclas: {morning: 1, morning + 3: 1}, fonte: FonteErro.licao, chaveDe: _chave);
    expect(_falhas(evs)['morning'], 1.0, reason: '2 erros (sem a tolerância da nota)');
    evs = evidenciasDaFrase(f, reveladas: {book + 1}, fonte: FonteErro.licao, chaveDe: _chave);
    expect(_falhas(evs)['book'], 1.0, reason: 'Tab revelou uma letra');
    expect(_falhas(evs)['morning'], 0.0);
    // erro em espaço/pontuação não conta
    evs = evidenciasDaFrase(f, teclas: {f.indexOf(','): 3}, fonte: FonteErro.licao, chaveDe: _chave);
    expect(_falhas(evs).values.every((v) => v == 0), isTrue);
  });

  test('uma evidência por palavra: a mesma palavra duas vezes conta uma (a pior)', () {
    const f = 'Coffee, coffee, coffee!';
    final evs = evidenciasDaFrase(f, teclas: {0: 1, 8: 2}, fonte: FonteErro.revisao, chaveDe: _chave);
    expect(evs, hasLength(1));
    expect(evs.single.falha, 1.0);
    expect(evs.single.fonte, FonteErro.revisao);
  });

  test('Esc ("não sei"): só a palavra do cursor leva 1; as seguintes não dão evidência; Tab antes vale', () {
    const f = 'Good morning, I am tired today.';
    final cursor = f.indexOf('morning') + 3; // digitou "Good mor" e desistiu
    final reveladas = {for (var i = cursor; i < f.length; i++) i, 1}; // + um Tab no "Good"
    final evs = evidenciasDaFrase(f, reveladas: reveladas, desistiu: true, fonte: FonteErro.licao, chaveDe: _chave);
    expect(_falhas(evs), {'good': 1.0, 'morning': 1.0}, reason: 'tired e today ficam sem evidência');
    // cursor no espaço antes de uma palavra: ela é a do cursor
    final antes = f.indexOf(' tired');
    final evs2 = evidenciasDaFrase(f,
        reveladas: {for (var i = antes; i < f.length; i++) i}, desistiu: true, fonte: FonteErro.licao, chaveDe: _chave);
    expect(_falhas(evs2), {'good': 0.0, 'morning': 0.0, 'tired': 1.0});
  });

  test('falar e montar (errosDeFala na 1ª letra): falha 1 com peso ×0,4 / ×0,6; cartão não multiplica', () {
    const f = 'Coffee, please.';
    final falar = evidenciasDaFrase(f, extras: {0: 1}, entrada: EntradaResposta.falar, fonte: FonteErro.licao, chaveDe: _chave);
    expect(falar.first.chave, 'coffee');
    expect(falar.first.falha, 1.0);
    expect(falar.first.peso, closeTo(.4, 1e-9));
    expect(falar.last.falha, 0.0, reason: 'please saiu limpa');
    final montar =
        evidenciasDaFrase(f, extras: {0: 1}, entrada: EntradaResposta.montar, fonte: FonteErro.revisao, chaveDe: _chave);
    expect(montar.first.peso, closeTo(.6, 1e-9));
    expect(pesoDaFonte(FonteErro.cartao, entrada: EntradaResposta.falar), 1.0);
    expect(pesoDaFonte(FonteErro.treino), .7);
    expect(pesoDaFonte(FonteErro.chuva), .5);
    expect(pesoDaFonte(FonteErro.rali), .5);
    expect(pesoDaFonte(FonteErro.turismo), .3);
  });

  test('filtros via chaveDe: palavras de função, curtas, com apóstrofo e nomes (null) não geram evidência', () {
    const f = "I'm with Mike at the old cafe.";
    String? chave(String w) => w == 'Mike' ? null : _chave(w);
    final evs = evidenciasDaFrase(f, teclas: {for (var i = 0; i < f.length; i++) i: 2}, fonte: FonteErro.licao, chaveDe: chave);
    expect(evs.map((e) => e.chave), ['old', 'cafe']);
    expect(evs.every((e) => e.errou), isTrue);
  });

  test('cartão PT→EN conferido: acerto true → 0, false → 1, null (palavra à vista do Médio) → nada', () {
    final c = compararResposta('I am really tired today', 'I am tired today');
    final evs = evidenciasDaComparacao(c, fonte: FonteErro.cartao, chaveDe: _chave);
    expect(_falhas(evs), {'really': 1.0, 'tired': 0.0, 'today': 0.0});
    expect(evs.first.peso, 1.0);
    // o Médio deixa "tired" à vista: acerto null
    const medio = ComparacaoResposta(
      esperada: [Segmento('really', false), Segmento(' '), Segmento('tired', null), Segmento(' '), Segmento('today', true)],
      digitada: [],
      cobertura: .5,
      precisao: 1,
      exata: false,
      sugerida: Rating.hard,
    );
    expect(_falhas(evidenciasDaComparacao(medio, fonte: FonteErro.cartao, chaveDe: _chave)), {'really': 1.0, 'today': 0.0});
  });
}
