import 'package:flutter_test/flutter_test.dart';
import 'package:pac_dart/features/curso/domain/curriculo.dart';
import 'package:pac_dart/features/curso/domain/mapa_regras.dart';
import 'package:pac_dart/features/ia/domain/nivel_conversa.dart';

Licao _l(String id) => Licao(nome: id, emoji: '•', id: id, trechos: const []);

Trilha _t(String slug, String etapa, {int licoes = 2, String textoId = ''}) => Trilha(
      nivel: slug,
      emoji: '•',
      etapa: etapa,
      textoId: textoId,
      licoes: [for (var i = 0; i < licoes; i++) _l('$slug.l$i')],
    );

/// A1 → A2 → DEV → C1, com uma trilha própria no meio (textos colados) e uma no fim.
final _curso = [
  _t('oi', 'A1 · Fundação'),
  _t('dia', 'A2 · Dia a dia'),
  _t('meu-texto', '', textoId: 'abc'),
  _t('dev', 'DEV · Inglês profissional de dev'),
  _t('dominio', 'C1 · Domínio'),
  _t('outro-texto', 'B1 · Independência', textoId: 'xyz'),
];

/// Todas as chaves das trilhas [ts] (as lições de cada uma).
Set<String> _feitas(List<int> ts) => {
      for (final t in ts)
        for (var l = 0; l < _curso[t].licoes.length; l++) chaveDaLicao(_curso, t, l),
    };

void main() {
  test('codigoDoNivel', () {
    final casos = {
      'A1 · Fundação': 'A1',
      'A2 · Dia a dia': 'A2',
      'B1 · Independência': 'B1',
      'B2 — x': 'B2',
      'C1 · Domínio': 'C1',
      'DEV · y': 'B2',
      'dev': 'B2',
      'C2 Proficiência': 'C1',
      'c1': 'C1',
      'A1': 'A1',
      '': '',
      'Iniciante': '',
      'xyz': '',
      'A12': '',
      'D1': '',
    };
    for (final e in casos.entries) {
      expect(codigoDoNivel(e.key), e.value, reason: e.key);
    }
  });

  test('ordemDoNivel', () {
    expect([for (final n in niveisConversa) ordemDoNivel(n)], [0, 1, 2, 3, 4]);
    expect(ordemDoNivel(''), 0);
    expect(ordemDoNivel('Z9'), 0);
  });

  group('nivelDoAluno (a fronteira)', () {
    test('sem progresso → o nível da primeira unidade', () {
      expect(nivelDoAluno(trilhas: _curso, concluidas: const {}), 'A1');
    });

    test('a unidade da fronteira vence', () {
      expect(nivelDoAluno(trilhas: _curso, concluidas: _feitas([0])), 'A2');
      expect(nivelDoAluno(trilhas: _curso, concluidas: {..._feitas([0]), chaveDaLicao(_curso, 1, 0)}), 'A2');
    });

    test('uma lição feita numa unidade DEV/C1 com a fronteira no A2 → A2', () {
      final c = {..._feitas([0]), chaveDaLicao(_curso, 3, 0), chaveDaLicao(_curso, 4, 1)};
      expect(nivelDoAluno(trilhas: _curso, concluidas: c), 'A2');
    });

    test('unidades passadas no nivelamento movem a fronteira (e a trilha própria é pulada)', () {
      expect(nivelDoAluno(trilhas: _curso, concluidas: _feitas([0, 1])), 'B2', reason: 'DEV conta como B2');
      expect(nivelDoAluno(trilhas: _curso, concluidas: _feitas([0, 1, 3])), 'C1');
    });

    test('curso inteiro feito → o nível da última unidade não própria', () {
      expect(nivelDoAluno(trilhas: _curso, concluidas: _feitas([0, 1, 3, 4])), 'C1');
    });

    test('DEV DEPOIS do C1 (o currículo real): quem terminou o C1 continua C1, não cai para B2', () {
      final real = [
        _t('oi', 'A1 · Fundação'),
        _t('dia', 'A2 · Dia a dia'),
        _t('dominio', 'C1 · Domínio'),
        _t('meu-texto', '', textoId: 'abc'),
        _t('dev', 'DEV · Inglês profissional de dev'),
      ];
      Set<String> feitas(List<int> ts) => {
            for (final t in ts)
              for (var l = 0; l < real[t].licoes.length; l++) chaveDaLicao(real, t, l),
          };
      expect(nivelDoAluno(trilhas: real, concluidas: feitas([0, 1])), 'C1', reason: 'fronteira no C1');
      expect(nivelDoAluno(trilhas: real, concluidas: feitas([0, 1, 2])), 'C1', reason: 'fronteira no DEV');
      expect(nivelDoAluno(trilhas: real, concluidas: feitas([0, 1, 2, 4])), 'C1', reason: 'curso inteiro feito');
      // e uma lição do C1 feita ADIANTE com a fronteira no A2 continua não subindo
      expect(nivelDoAluno(trilhas: real, concluidas: {...feitas([0]), chaveDaLicao(real, 2, 0)}), 'A2');
    });

    test('vazio ou etapa desconhecida → A1', () {
      expect(nivelDoAluno(trilhas: const [], concluidas: const {}), 'A1');
      expect(nivelDoAluno(trilhas: [_t('x', 'Iniciante')], concluidas: const {}), 'A1');
      expect(nivelDoAluno(trilhas: [_t('so-texto', 'B2', textoId: 't')], concluidas: const {}), 'A1');
    });
  });

  test('nivelDaConversa: uma escolha válida vence; inválida é ignorada', () {
    expect(nivelDaConversa(aluno: 'A2'), 'A2');
    expect(nivelDaConversa(aluno: 'A2', escolhido: 'B2'), 'B2');
    expect(nivelDaConversa(aluno: 'A2', escolhido: 'c1'), 'C1');
    expect(nivelDaConversa(aluno: 'A2', escolhido: 'Z9'), 'A2');
    expect(nivelDaConversa(aluno: 'A2', escolhido: 'C2'), 'A2');
    expect(nivelDaConversa(aluno: ''), 'A1');
    expect(nivelDaConversa(aluno: 'lixo', escolhido: ''), 'A1');
    expect(nivelDaConversa(aluno: 'B1 · Independência'), 'B1');
  });

  test('acimaDoNivel', () {
    expect(acimaDoNivel('B1', 'A2'), isTrue);
    expect(acimaDoNivel('C1 · Domínio', 'B2'), isTrue);
    expect(acimaDoNivel('A2', 'A2'), isFalse);
    expect(acimaDoNivel('A1', 'B2'), isFalse);
    expect(acimaDoNivel('', 'A1'), isFalse);
  });

  test('nivelIniciante', () {
    expect([for (final n in niveisConversa) nivelIniciante(n)], [true, true, false, false, false]);
    expect(nivelIniciante(''), isFalse);
  });

  test('vocabularioParaPrompt: sem repetir, só letras/apóstrofo/hífen, 2 a 24, até o máximo', () {
    expect(
      vocabularioParaPrompt(['Coffee', 'coffee', ' size ', 'a', "don't", 'check-in', 'café', 'two words', '42', '--', 'x' * 25, 'y' * 24]),
      ['coffee', 'size', "don't", 'check-in', 'y' * 24],
    );
    expect(vocabularioParaPrompt([for (var i = 0; i < 40; i++) 'w${String.fromCharCode(97 + i % 26)}${'z' * (i ~/ 26)}']).length, 30);
    expect(vocabularioParaPrompt(['aa', 'bb', 'cc'], max: 2), ['aa', 'bb']);
    expect(vocabularioParaPrompt(const []), isEmpty);
  });
}
