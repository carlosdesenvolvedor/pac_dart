// "📝 Virar lição" das teimosas: frases do curso que cobrem todas as palavras (a que tem 2 ganha), de
// lições concluídas e curtas primeiro, nunca as de [evitar], no máximo 8 (uma lição), com alvo/alvoPt, o
// exemplo de reserva para a palavra sem frase e null com menos de 2 frases.
import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/ingles/domain/licao_de_palavras.dart';

const _tres = 'We go through it because it is enough.';

final _trilhas = [
  const Trilha(nivel: 'T1', emoji: '1', etapa: 'A1', licoes: [
    Licao(nome: 'L1', emoji: '1', id: 'l1', trechos: [
      Trecho(cod: 'I walked through the park.', dica: 'Eu andei pelo parque.', out: ''),
      Trecho(cod: 'Is it enough for you?', dica: 'É <b>suficiente</b> para você?', out: ''),
      Trecho(cod: _tres, dica: 'Passamos por isso porque é suficiente.', out: ''),
      Trecho(cod: 'Through it.', dica: 'Através disso.', out: ''),
      Trecho(cod: 'Enough is enough, and I am not doing this again because of you.', dica: 'Chega.', out: ''),
      Trecho(cod: 'This is enough food.', dica: '', out: ''),
    ]),
  ]),
  const Trilha(nivel: 'T2', emoji: '2', etapa: 'A1', licoes: [
    Licao(nome: 'L2', emoji: '2', id: 'l2', trechos: [
      Trecho(cod: 'She ran through the tunnel.', dica: 'Ela correu pelo túnel.', out: ''),
      Trecho(cod: 'Because I can.', dica: 'Porque eu posso.', out: ''),
      Trecho(cod: 'He did it because he was tired.', dica: 'Ele fez porque estava cansado.', out: ''),
    ]),
  ]),
  const Trilha(nivel: 'Meu texto', emoji: '📝', etapa: 'Meus textos', textoId: 'x', licoes: [
    Licao(nome: 'P1', emoji: '📝', id: 'txt-x-1', trechos: [
      Trecho(cod: 'Enough said, my friend.', dica: 'Chega, meu amigo.', out: ''),
    ]),
  ]),
];

String? _traducao(String k) => const {'through': 'através', 'enough': 'suficiente', 'because': 'porque'}[k];

void main() {
  final agora = DateTime(2026, 10, 20, 9);

  test('cobre todas as palavras; a frase com várias palavras-alvo ganha; título e sem sequência', () {
    final t = textoDePalavras(['through', 'because', 'enough'], _trilhas,
        concluidas: {'l1'}, traducao: _traducao, agora: agora, max: 3)!;
    expect(t.frases.first.en, _tres, reason: 'cobre as 3 de uma vez');
    expect(t.titulo, '🔥 Teimosas · 20/10');
    expect(t.sequencial, isFalse);
    expect(t.frases.map((f) => f.en), isNot(contains('Through it.')), reason: 'menos de 3 palavras');
    expect(t.frases.map((f) => f.en), isNot(contains('Enough said, my friend.')), reason: 'texto próprio fica de fora');
    expect(t.frases.map((f) => f.en), isNot(contains('This is enough food.')), reason: 'sem tradução');
    expect(t.frases.every((f) => f.en.length <= 70), isTrue);
  });

  test('evitar (a frase do erro) → contexto novo; lição concluída e frase curta primeiro', () {
    final t = textoDePalavras(['through', 'because', 'enough'], _trilhas,
        concluidas: {'l1'}, traducao: _traducao, evitar: {_tres.toUpperCase()}, agora: agora)!;
    final ens = t.frases.map((f) => f.en).toList();
    expect(ens, isNot(contains(_tres)));
    expect(ens.indexOf('I walked through the park.'), lessThan(ens.indexOf('She ran through the tunnel.')),
        reason: 'concluída antes');
    expect(ens.indexOf('Because I can.'), lessThan(ens.indexOf('He did it because he was tired.')), reason: 'mais curta antes');
    for (final w in ['through', 'because', 'enough']) {
      expect(t.frases.any((f) => f.alvo.toLowerCase() == w), isTrue, reason: w);
    }
    expect(ens.toSet(), hasLength(ens.length), reason: 'sem frase repetida');
  });

  test('alvo como está escrito na frase e alvoPt achado na tradução', () {
    final t = textoDePalavras(['enough', 'through'], _trilhas,
        concluidas: {'l1'}, traducao: _traducao, evitar: {_tres}, agora: agora)!;
    final enough = t.frases.firstWhere((f) => f.en == 'Is it enough for you?');
    expect(enough.alvo, 'enough');
    expect(enough.alvoPt, 'suficiente');
    expect(enough.pt, 'É suficiente para você?', reason: 'a dica sem marcação');
    final through = t.frases.firstWhere((f) => f.en == 'I walked through the park.');
    expect(through.alvo, 'through');
    expect(through.alvoPt, '', reason: '"através" não está na tradução');
  });

  test('no máximo 8 frases (uma lição só)', () {
    final muitas = [
      Trilha(nivel: 'T', emoji: 't', etapa: 'A1', licoes: [
        Licao(nome: 'L', emoji: 'l', id: 'lm', trechos: [
          for (var i = 0; i < 20; i++) Trecho(cod: 'I read book number ${'abcdefghijklmnopqrst'[i]} today.', dica: 'Eu li.', out: ''),
        ]),
      ]),
    ];
    final t = textoDePalavras(['book', 'read', 'today'], muitas, agora: agora)!;
    expect(t.frases, hasLength(8));
    expect(t.comoTrilha().licoes, hasLength(1));
  });

  test('palavra sem frase no curso usa o exemplo de reserva; menos de 2 frases → null', () {
    final t = textoDePalavras(['quiet', 'enough'], _trilhas,
        concluidas: {'l1'},
        exemploExtra: (k) => k == 'quiet' ? (frase: 'Be quiet, please.', traducao: 'Fique quieto, por favor.') : null,
        agora: agora)!;
    final quiet = t.frases.firstWhere((f) => f.en == 'Be quiet, please.');
    expect(quiet.alvo, 'quiet');
    expect(textoDePalavras(['quiet'], _trilhas, agora: agora), isNull);
    expect(textoDePalavras(['tunnel'], _trilhas, agora: agora), isNull, reason: 'só 1 frase');
    expect(textoDePalavras(const [], _trilhas, agora: agora), isNull);
  });

  test('chaveDe casa a forma flexionada com a chave ("walked" → walk)', () {
    final t = textoDePalavras(['walk', 'run'], _trilhas,
        chaveDe: (w) => const {'walked': 'walk', 'ran': 'run'}[w.toLowerCase()] ?? w.toLowerCase(), agora: agora)!;
    expect(t.frases.map((f) => f.alvo), containsAll(['walked', 'ran']));
  });
}
